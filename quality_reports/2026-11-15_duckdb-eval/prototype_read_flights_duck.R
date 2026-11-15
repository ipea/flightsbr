# prototype.R -- read_flights_duck(): ANAC CSV -> local Parquet cache -> eager data.table or lazy duckdb tbl
# Route: duckdb SQL (via DBI) for the conversion + dplyr::tbl()/dbplyr for the lazy result.
# Assumes flightsbr internals are loaded (pkgload::load_all or inside the package namespace):
#   get_flights_files_available(), check_input_date_format(), check_date(), generate_all_months()

.fb <- new.env(parent = emptyenv())

# ---- connection ownership ---------------------------------------------------------------
# One package-level in-memory duckdb connection, created lazily and reused for the whole session.
# Lazy tbls hold a reference to it, so it stays alive as long as either does.
flights_con <- function() {
  if (!is.null(.fb$con) && DBI::dbIsValid(.fb$con)) return(.fb$con)
  con <- DBI::dbConnect(duckdb::duckdb())            # in-memory; only reads/writes parquet files
  nth <- max(1L, min(getOption("flightsbr.threads", 2L), parallel::detectCores()))
  DBI::dbExecute(con, sprintf("SET threads TO %d", nth))
  DBI::dbExecute(con, "SET preserve_insertion_order = false")
  .fb$con <- con
  reg.finalizer(.fb, function(e) try(DBI::dbDisconnect(e$con, shutdown = TRUE), silent = TRUE), onexit = TRUE)
  con
}
# frees every file handle (needed before deleting the cache dir on Windows)
flights_disconnect <- function() {
  if (!is.null(.fb$con)) try(DBI::dbDisconnect(.fb$con, shutdown = TRUE), silent = TRUE)
  .fb$con <- NULL
  invisible(TRUE)
}

sql_str <- function(x) paste0("'", gsub("'", "''", x, fixed = TRUE), "'")   # SQL string literal
sql_id  <- function(x) paste0('"', gsub('"', '""', x, fixed = TRUE), '"')   # SQL identifier

# ---- URL / download ---------------------------------------------------------------------
# NOTE: get_flights_files_available() currently returns RELATIVE hrefs
# ("/anac/pt-br/.../basica2000-01.zip"); GETting that returns an HTML page, not a zip.
# The real file is <host><href>/@@download/file.
flights_zip_url <- function(u) {
  if (!grepl("^https?://", u)) u <- paste0("https://www.gov.br", u)
  if (!grepl("@@download", u, fixed = TRUE)) u <- paste0(u, "/@@download/file")
  u
}
is_zip_file <- function(p) file.exists(p) && file.size(p) > 0 &&
  identical(readBin(p, "raw", 2), as.raw(c(0x50, 0x4b)))
flights_get_zip <- function(url, zip_dir) {
  dest <- file.path(zip_dir, basename(url))
  if (is_zip_file(dest)) return(dest)
  dir.create(zip_dir, recursive = TRUE, showWarnings = FALSE)
  part <- paste0(dest, ".part.", paste(sample(letters, 8), collapse = ""))
  on.exit(unlink(part), add = TRUE)
  httr2::request(flights_zip_url(url)) |>
    httr2::req_user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36") |>
    httr2::req_headers(Accept = "application/zip, application/octet-stream, */*",
                       `Accept-Encoding` = "identity") |>
    httr2::req_retry(max_tries = 4) |> httr2::req_perform(path = part)
  if (!is_zip_file(part)) stop("ANAC did not return a zip for ", url)
  file.copy(part, dest, overwrite = TRUE)
  dest
}

# ---- cache layout -----------------------------------------------------------------------
# <cache_dir>/flights/type=<type>/year=<yyyy>/<type><yyyy>-<mm>.parquet   (one file per month)
flights_parquet_path <- function(cache_dir, type, date) {
  y <- date %/% 100L; m <- date %% 100L
  file.path(cache_dir, "flights", paste0("type=", type), paste0("year=", y),
            sprintf("%s%d-%02d.parquet", type, y, m))
}
SCHEMA_VERSION <- "1"   # bump when cleaning / typing rules change => forces re-conversion

is_parquet_file <- function(p) file.exists(p) && file.size(p) > 12
parquet_meta <- function(con, path) {
  r <- DBI::dbGetQuery(con, sprintf(
    "SELECT key::VARCHAR AS key, value::VARCHAR AS value FROM parquet_kv_metadata(%s)", sql_str(path)))
  stats::setNames(as.list(r$value), r$key)
}
flights_cache_ok <- function(con, path) {
  if (!is_parquet_file(path)) return(FALSE)
  m <- try(parquet_meta(con, path), silent = TRUE)
  !inherits(m, "try-error") && identical(m$flightsbr_schema_version, SCHEMA_VERSION)
}
# Staleness vs. ANAC republishing: HEAD the zip, compare validators stored in the parquet KV metadata.
flights_remote_stamp <- function(url) {
  r <- try(httr2::request(flights_zip_url(url)) |>
    httr2::req_user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36") |>
    httr2::req_method("HEAD") |> httr2::req_perform(), silent = TRUE)
  if (inherits(r, "try-error")) return(NULL)
  # strip quotes/backslashes: they come back escaped (\x22) from parquet KV metadata
  list(etag = gsub("[^A-Za-z0-9+/=:._-]", "", httr2::resp_header(r, "etag", "")),
       last_modified = httr2::resp_header(r, "last-modified", ""),
       length = httr2::resp_header(r, "content-length", ""))
}
flights_cache_stale <- function(con, path, url) {
  m <- parquet_meta(con, path); s <- flights_remote_stamp(url)
  if (is.null(s)) return(FALSE)                         # offline: keep what we have
  # ANAC's HEAD gives a stable ETag + Content-Length (no Last-Modified); compare both.
  !identical(m$flightsbr_zip_length, s$length) ||
    (nzchar(s$etag) && !identical(m$flightsbr_etag, s$etag))
}

# ---- CSV -> Parquet (one-time conversion; all heavy lifting inside duckdb) -----------------
NUMERIC_RE <- "NR_|nr_|qt_|comprimento_|largura_"       # same rule as convert_to_numeric()
# duckdb's built-in 'latin-1' decoder is strict: it rejects bytes 0x80-0x9F (cp1252 characters such as
# 0x8A = "S-caron" occur in ANAC files, e.g. basica2002-02). The 'encodings' extension (cp1252 etc.) is
# NOT available for this duckdb build (HTTP 404), so we fall back to an R-side CP1252 -> UTF-8 recode.
recode_cp1252_to_utf8 <- function(src, dst, chunk = 200000L) {
  zin <- file(src, "rb"); zout <- file(dst, "wb"); on.exit({close(zin); close(zout)})
  repeat {
    l <- readLines(zin, n = chunk, warn = FALSE)
    if (!length(l)) break
    writeLines(iconv(l, "CP1252", "UTF-8", sub = "?"), zout, useBytes = TRUE)
  }
  invisible(dst)
}
# escape (a single backslash in SQL): ANAC rows such as  "LINEAS AEREAS SURAMERICANAS \"LAS\""  use backslash-escaped
# quotes. Without it duckdb either errors (strict) or silently drops the inner quotes. NEVER use ignore_errors=true:
# it silently DROPS the offending rows (94656 -> 91961 rows on basica2014-07).
csv_source_sql <- function(csv, utf8 = FALSE) {
  sprintf(paste0("read_csv(%s, delim=';', quote='\"', escape='\\', header=true, all_varchar=true, %s",
                 "strict_mode=false, null_padding=true)"),
          sql_str(csv), if (utf8) "" else "encoding='latin-1', ")
}
csv_to_parquet <- function(con, csv, out, url, zip_path, stamp = NULL) {
  kv <- c(flightsbr_schema_version = SCHEMA_VERSION, flightsbr_source_url = url,
          flightsbr_zip_length = as.character(file.size(zip_path)),
          flightsbr_etag = if (!is.null(stamp$etag)) stamp$etag else "",
          flightsbr_converted_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
  kvsql <- paste0("{", paste(sprintf("%s: %s", sql_id(names(kv)), sql_str(kv)), collapse = ", "), "}")
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  part <- paste0(out, ".part.", paste(sample(letters, 6), collapse = ""))
  on.exit(unlink(part), add = TRUE)

  do_copy <- function(src) {
    raw <- DBI::dbGetQuery(con, paste("SELECT column_name FROM (DESCRIBE SELECT * FROM", src, ")"))$column_name
    clean <- janitor::make_clean_names(raw)
    is_num <- grepl(NUMERIC_RE, clean) & clean != "nr_singular"
    exprs <- ifelse(is_num,
      sprintf("TRY_CAST(replace(%s, ',', '.') AS DOUBLE) AS %s", sql_id(raw), sql_id(clean)),
      sprintf("%s AS %s", sql_id(raw), sql_id(clean)))
    DBI::dbExecute(con, sprintf(
      "COPY (SELECT %s FROM %s) TO %s (FORMAT parquet, COMPRESSION zstd, ROW_GROUP_SIZE 122880, KV_METADATA %s)",
      paste(exprs, collapse = ", "), src, sql_str(part), kvsql))
  }
  res <- tryCatch(do_copy(csv_source_sql(csv)), error = function(e) e)
  if (inherits(res, "error")) {
    if (!grepl("not latin-1|Invalid unicode|invalid UTF", conditionMessage(res))) stop(res)
    utf8csv <- paste0(csv, ".utf8")
    on.exit(unlink(utf8csv), add = TRUE)
    recode_cp1252_to_utf8(csv, utf8csv)
    do_copy(csv_source_sql(utf8csv, utf8 = TRUE))
  }
  # Windows: rename onto an existing file fails if it is held open by a running query
  if (!file.rename(part, out)) {
    file.copy(part, out, overwrite = TRUE) || stop("cannot replace ", out, " (file locked?)")
  }
  invisible(out)
}

# ---- the user-facing function -----------------------------------------------------------
read_flights_duck <- function(date = NULL, type = "basica", showProgress = FALSE, select = NULL,
                              cache = TRUE, collect = TRUE,
                              cache_dir = tools::R_user_dir("flightsbr", "cache"),
                              zip_dir = file.path(cache_dir, "zips"), keep_zips = TRUE,
                              check_updates = FALSE) {
  requested_type <- match.arg(type, c("basica", "combinada"))
  check_input_date_format(date)
  files <- get_flights_files_available(cache = cache)
  if (is.null(files)) return(invisible(NULL))
  files <- as.data.frame(files)                          # base subsetting: avoid data.table column scoping
  files <- files[files$type == requested_type, , drop = FALSE]
  if (is.null(date)) date <- max(files$date)
  check_date(date = date, files$date)
  if (all(nchar(date) == 4L)) date <- generate_all_months(date)
  requested_dates <- date
  files <- files[files$date %in% requested_dates, , drop = FALSE]
  files <- files[order(files$date), , drop = FALSE]

  con <- flights_con()
  paths <- flights_parquet_path(cache_dir, requested_type, files$date)

  for (i in seq_len(nrow(files))) {
    ok <- cache && flights_cache_ok(con, paths[i]) &&
      !(check_updates && flights_cache_stale(con, paths[i], files$url[i]))
    if (ok) next
    zip <- flights_get_zip(files$url[i], zip_dir)
    exdir <- tempfile("flightsbr_csv_"); dir.create(exdir)
    csv <- utils::unzip(zip, exdir = exdir)[1]
    stamp <- flights_remote_stamp(files$url[i])
    tryCatch(csv_to_parquet(con, csv, paths[i], files$url[i], zip, stamp),
             finally = { unlink(exdir, recursive = TRUE); if (!keep_zips) unlink(zip) })
  }

  # ---- result ----
  file_list <- paste0("[", paste(sql_str(paths), collapse = ", "), "]")
  cols <- if (is.null(select)) "*" else paste(sql_id(select), collapse = ", ")
  qry <- sprintf("SELECT %s FROM read_parquet(%s, union_by_name = true, hive_partitioning = false)", cols, file_list)
  if (!collect) return(dplyr::tbl(con, dplyr::sql(qry)))         # lazy
  data.table::setDT(DBI::dbGetQuery(con, qry))                  # eager, same class as read_flights() (no copy)
}
