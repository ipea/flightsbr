#' Check whether date input is acceptable
#' @param date Numeric. Either a 6-digit date in the format `yyyymm` or a 4-digit
#'             date input `yyyy` .
#' @param all_dates Numeric vector created with the get_all_dates_available() function.
#'
#' @return Check messages.
#' @export
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#'
#' # get all dates available
#' all_dates <- get_all_dates_available()
#'
#' # check dates
#' a <- check_date(200011, all_dates)
#'}}
check_date <- function(date, all_dates) {

  first_date <- min(all_dates)
  last_date <- max(all_dates)

  for(d in date){
    available <- if (nchar(d) == 6) {
      d %in% all_dates
    } else {
      d %in% unique(substr(all_dates, 1, 4))
    }

    if (!available) {
      # name the read_*() function that called check_date() in the error
      cli::cli_abort(
        "The data is currently only available for dates between {first_date} and {last_date}.",
        call = rlang::caller_env()
      )
    }
  }
}



#' Generate all months with `yyyymm` format for a given year
#'
#' @param date Numeric. 4-digit date in the format `yyyy`. The function also
#'        takes multiple years.
#' @return Vector or strings.
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate all months in 2000
#' a <- check_date(2000)
#'
#' b <- check_date(c(2000, 2005))
#'}}
generate_all_months <- function(date) {

  # check
  if (any(nchar(date)!=4)) {
    cli::cli_abort("{.arg date} must be 4-digit in the format {.code yyyy}.")
  }

  get_all_months <- function(yyyy){
    jan <- as.numeric(paste0(yyyy, '01'))
    dec <- as.numeric(paste0(yyyy, '12'))
    allmonths <- jan:dec
    return(allmonths)
  }

  all_dates <- lapply(X=date, FUN = get_all_months)
  all_dates <- unlist(all_dates)
  return(all_dates)

}


#' Expand requested years into the months available on ANAC
#'
#' @param date Numeric. Requested dates, either all `yyyymm` or all `yyyy`
#'        (already checked with [check_date()]).
#' @param all_dates Numeric vector of `yyyymm` dates available on ANAC.
#'
#' @return Numeric vector of `yyyymm` dates. `yyyymm` input is returned
#'         unchanged; `yyyy` input is expanded to the months of those years
#'         that are available, with a message listing the missing months.
#' @keywords internal
available_months <- function(date, all_dates) {

  if (!all(nchar(date) == 4)) {
    return(date)
  }

  requested <- generate_all_months(date)
  available <- requested[requested %in% all_dates]
  missing <- setdiff(requested, available)

  if (length(missing) > 0) {
    cli::cli_inform(
      "Data for these months is not available on ANAC and was skipped: {missing}"
    )
  }

  return(available)
}




#' Directory where flightsbr caches downloaded files
#'
#' The folder set with [set_flightsbr_cache_dir()], or by default
#' `tools::R_user_dir("flightsbr", which = "cache")`, so cached files persist
#' across R sessions. See [get_flightsbr_cache_dir()].
#'
#' @param create Logical. Whether to create the directory if it does not
#'        exist. Defaults to `TRUE`.
#'
#' @return The path to the cache directory.
#'
#' @keywords internal
flightsbr_cache_dir <- function(create = TRUE) {

  cache_dir <- get_flightsbr_cache_dir()

  if (isTRUE(create)) fs::dir_create(cache_dir)
  return(fs::path(cache_dir))
}



#' Get the size of remote files with HEAD requests
#'
#' @param file_url Character vector of urls.
#' @param timeout Numeric. Seconds to wait for each HEAD request.
#'
#' @return A numeric vector with the remote `Content-Length` of each file.
#'         `NA` when the request failed, the server sent no size, or the
#'         server answered with an HTML page (ANAC's error / rate-limit page).
#'
#' @keywords internal
remote_sizes <- function(file_url, timeout = 30) { # nocov start

  if (length(file_url) == 0) return(numeric(0))

  reqs <- lapply(file_url, function(url) {
    anac_request(url) |>
      httr2::req_method("HEAD") |>
      httr2::req_retry(max_tries = 1) |>
      httr2::req_timeout(timeout)
  })

  resps <- tryCatch(
    httr2::req_perform_parallel(reqs, on_error = "continue",
                                progress = FALSE, max_active = 4),
    error = function(e) vector("list", length(reqs))
  )

  vapply(resps, function(r) {
    if (!inherits(r, "httr2_response")) return(NA_real_)

    type <- tryCatch(httr2::resp_content_type(r), error = \(e) NA_character_)
    if (isTRUE(type == "text/html")) return(NA_real_)

    h <- httr2::resp_header(r, "content-length")
    if (is.null(h)) return(NA_real_)
    suppressWarnings(as.numeric(h))
  }, numeric(1))
} # nocov end



#' Download files from urls, reusing cached copies
#'
#' Downloads each file to a temporary `.part` file and only moves it to
#' `dest_file` once the download succeeded and the content is not an HTML
#' page. A failed or blocked request therefore never leaves a file at
#' `dest_file`, so later calls with `cache = TRUE` cannot read an error page as
#' data.
#'
#' With `cache = TRUE`, a file already at `dest_file` is reused unless the
#' ANAC server reports a different size for it (checked with a HEAD request).
#' If the size can't be checked (no connection, no size header, or ANAC
#' answers with a web page), the cached file is reused.
#'
#' @param file_url String. A url passed from above.
#' @param showProgress Logical, passed from above.
#' @param dest_file String. Local path(s) where the file(s) are saved, one per
#'        `file_url`. Defaults to the flightsbr cache directory (see
#'        [get_flightsbr_cache_dir()]) plus `basename(file_url)`.
#' @param cache Logical, passed from above. If `FALSE`, existing files at
#'        `dest_file` are deleted and downloaded again.
#'
#' @return `TRUE` (invisibly) if every file is available locally, otherwise
#'         `NULL` (invisibly) with a message.
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' file_url <- get_flights_url(type='basica', date=200011)
#'
#' # download data
#' download_flightsbr_file(file_url=file_url,
#'                         showProgress=TRUE,
#'                         dest_file = tempfile(fileext = ".zip")
#'                        )
#'}}
download_flightsbr_file <- function(file_url = parent.frame()$file_url,
                                    showProgress = parent.frame()$showProgress,
                                    dest_file = fs::path(flightsbr_cache_dir(), basename(file_url)),
                                    cache = cache) { # nocov start

  if (length(dest_file) != length(file_url)) {
    cli::cli_abort("{.arg dest_file} must have the same length as {.arg file_url}.")
  }

  dest_file <- as.character(dest_file)

  # two requests writing to the same path would collide
  keep <- !duplicated(dest_file)
  file_url <- file_url[keep]
  dest_file <- dest_file[keep]

  if (isFALSE(cache)) {
    unlink(dest_file)

  } else {
    # re-download a cached file only if ANAC reports a different size; keep
    # it when the size can't be checked (e.g. offline)
    cached <- which(file.exists(dest_file))
    if (length(cached) > 0) {
      remote_size <- remote_sizes(file_url[cached])
      local_size <- file.info(dest_file[cached])$size
      outdated <- cached[!is.na(remote_size) & remote_size != local_size]
      unlink(dest_file[outdated])

      n_reused <- length(cached) - length(outdated)
      if (isTRUE(showProgress) && n_reused > 0) {
        n_download <- length(file_url) - n_reused
        cli::cli_inform("Using {n_reused} cached file{?s}; downloading {n_download}.")
      }
    }
  }

  blocked <- character(0)

  # one download pass plus one retry pass for files that failed
  for (pass in 1:2) {

    todo <- !file.exists(dest_file)
    if (!any(todo)) {
      return(invisible(TRUE))
    }

    part_file <- vapply(
      dest_file[todo],
      \(d) tempfile(pattern = paste0(basename(d), "_"), tmpdir = dirname(d),
                    fileext = ".part"),
      character(1),
      USE.NAMES = FALSE
    )

    reqs <- lapply(file_url[todo], anac_request)

    responses <- httr2::req_perform_parallel(
      reqs,
      paths = part_file,
      on_error = "continue",
      progress = showProgress,
      max_active = 4
    )

    ok <- vapply(responses, inherits, logical(1), what = "httr2_response")

    # ANAC answers scripted bursts with an HTML page and HTTP status 200
    html <- vapply(seq_along(responses), \(i) {
      ok[i] && is_html_response(responses[[i]], part_file[i])
    }, logical(1))

    blocked <- unique(c(blocked, file_url[todo][html]))
    ok <- ok & !html

    renamed <- file.rename(part_file[ok], dest_file[todo][ok])
    unlink(part_file[file.exists(part_file)])

    # a file that could not be moved into place (e.g. locked on Windows) is
    # not available
    if (!all(renamed)) {
      unlink(dest_file[todo][ok][!renamed])
    }
  }

  if (all(file.exists(dest_file))) {
    return(invisible(TRUE))
  }

  if (length(blocked) > 0) {
    cli::cli_inform(paste(
      "The ANAC data server refused the request (it returned a web page",
      "instead of the data file). Please wait a few minutes and try again."
    ))
  } else {
    cli::cli_inform("Problem connecting to ANAC data server. Please try it again.")
  }
  invisible(NULL)
} # nocov end


#' Build an httr2 request for an ANAC data file
#'
#' @param url String. File url.
#'
#' @return An `httr2_request`.
#' @keywords internal
anac_request <- function(url) { # nocov start
  httr2::request(url) |>
    httr2::req_user_agent(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    ) |>
    httr2::req_headers(
      Accept = "application/zip, application/octet-stream, text/csv, */*",
      `Accept-Encoding` = "identity"
    ) |>
    httr2::req_retry(max_tries = 3)
} # nocov end


#' Check whether a downloaded response is an HTML page instead of a data file
#'
#' @param resp An `httr2_response`.
#' @param path String. Local file where the response body was written.
#'
#' @return Logical.
#' @keywords internal
is_html_response <- function(resp, path) {

  type <- tryCatch(httr2::resp_content_type(resp), error = \(e) NA_character_)
  if (isTRUE(type == "text/html")) {
    return(TRUE)
  }

  starts_like_html(path)
}


#' Check whether a local file starts like an HTML document
#'
#' @param path String. Local file path.
#'
#' @return Logical. `FALSE` for missing or empty files.
#' @keywords internal
starts_like_html <- function(path) {

  if (!file.exists(path) || isTRUE(file.info(path)$size == 0)) {
    return(FALSE)
  }

  # work on raw bytes: data files may be Latin-1, which is not valid UTF-8
  bytes <- readBin(path, what = "raw", n = 512L)

  # skip a UTF-8 byte order mark, whitespace and NUL bytes
  if (length(bytes) >= 3 && identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) {
    bytes <- bytes[-(1:3)]
  }
  bytes <- bytes[!bytes %in% as.raw(c(0x00, 0x09, 0x0a, 0x0d, 0x20))]

  length(bytes) > 0 && bytes[1] == charToRaw("<")
}



#' Convert latitude and longitude columns to numeric
#'
#' Coordinates are written in degrees, minutes and seconds (e.g.
#' `30\u00b050'39,8"S`). Some files use a decimal comma in the seconds, which
#' `parzer` can't read, so commas are replaced with dots first.
#'
#' @param df A data.table internal to the `read_airports()` function.
#'
#' @return A `"data.table" "data.frame"` object, modified by reference.
#'
#' @keywords internal
latlon_to_numeric <- function(df){

  # check if df has lat lon colnames
  if(!'latitude' %in% names(df)){
    cli::cli_abort("Column {.field latitude} is missing from original ANAC data.", call = NULL)
  }
  if(!'longitude' %in% names(df)){
    cli::cli_abort("Column {.field longitude} is missing from original ANAC data.", call = NULL)
  }

  # ref
  # https://semba-blog.netlify.app/02/25/2020/geographical-coordinates-conversion-made-easy-with-parzer-package-in-r/

  suppressWarnings({
    df[, latitude := parzer::parse_lat(gsub(",", ".", latitude, fixed = TRUE)) ]
    df[, longitude := parzer::parse_lon(gsub(",", ".", longitude, fixed = TRUE)) ]
  })

  return(df)
}


#' Convert altitude column to numeric
#'
#' Altitudes are written like `"512,3 m"`. A value with no digit before the
#' decimal comma (`",0"`) is how ANAC marks a missing altitude, so it becomes
#' `NA`.
#'
#' @param df A data.table internal to the `read_airports()` function.
#'
#' @return A `"data.table" "data.frame"` object, modified by reference.
#'
#' @keywords internal
altitude_to_numeric <- function(df){

  if(!'altitude' %in% names(df)){
    cli::cli_abort("Column {.field altitude} is missing from original ANAC data.", call = NULL)
  }

  alt <- trimws(gsub(" m", "", df$altitude, fixed = TRUE))
  alt[grepl("^,", alt)] <- NA
  alt <- suppressWarnings(as.numeric(gsub(",", ".", alt, fixed = TRUE)))

  df[, altitude := alt ]

  return(df)
}


#' Convert numeric-like columns to numeric
#'
#' Candidate columns are those named like `nr_*`, `qt_*`, `comprimento_*`,
#' `largura_*`, `latgeopoint` and `longeopoint`, except identifiers that must
#' keep their leading zeros (e.g. flight numbers and serial numbers). A
#' candidate column is converted only if every non-missing value can be read
#' as a number. Otherwise it is left as character, so codes such as airport
#' or airline identifiers are never turned into `NA`. A message lists the
#' columns that were left as character because of a few stray values.
#'
#' Values with a decimal comma (`"1.500.000,00"`) have their thousands dots
#' removed; values without a comma are read as they are (`"360.0"`).
#'
#' @param dt A data.table with clean (lower case) column names. Modified by
#'        reference.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
convert_to_numeric <- function(dt) {

  candidates <- grep(
    "^(nr|qt|comprimento|largura)_|^(lat|lon)geopoint$",
    names(dt),
    value = TRUE
  )
  candidates <- setdiff(candidates, id_columns)
  candidates <- candidates[vapply(dt[, candidates, with = FALSE], is.character, logical(1))]

  kept_as_character <- character(0)

  for (col in candidates) {

    x <- dt[[col]]
    x[trimws(x) %in% na_tokens] <- NA_character_

    # maximum takeoff weight is an integer number of kg, sometimes written
    # with units or thousands separators ("5 490", "5670kg", "2.850")
    if (col == "nr_pmd") {
      x <- gsub("[^0-9]", "", x)
      x[!nzchar(x)] <- NA_character_
    }

    num <- parse_number_br(x)

    bad <- is.na(num) & !is.na(x)
    if (any(bad)) {
      # only report columns that are mostly numbers with a few stray values;
      # columns of codes (e.g. airport codes) are text and stay character
      # silently
      if (mean(bad[!is.na(x)]) > 0.1) {
        next
      }
      kept_as_character <- c(
        kept_as_character,
        sprintf("%s (%d values such as %s)",
                col, sum(bad),
                paste0('"', utils::head(unique(x[bad]), 2), '"', collapse = ", "))
      )
      next
    }

    data.table::set(dt, j = col, value = num)
  }

  if (length(kept_as_character) > 0) {
    # the descriptions hold raw ANAC values, so they are substituted into the
    # message, never pasted into the cli template (which would evaluate {})
    cli::cli_inform(
      "These columns were kept as character because some values are not numbers: {kept_as_character}"
    )
  }

  return(invisible(TRUE))
}


#' Parse numbers written in Brazilian or international format
#'
#' @param x Character vector.
#'
#' @return Numeric vector. Values with a decimal comma have their thousands
#'         dots removed first; values without a comma are parsed as they are.
#' @keywords internal
parse_number_br <- function(x) {
  x <- trimws(x)
  has_comma <- grepl(",", x, fixed = TRUE)
  x[has_comma] <- sub(",", ".", gsub(".", "", x[has_comma], fixed = TRUE), fixed = TRUE)
  suppressWarnings(as.numeric(x))
}


# columns named like numbers that are identifiers and must stay character
id_columns <- c("nr_voo", "nr_voo_numero", "nr_chave", "nr_singular",
                "nr_serie", "nr_cert_matricula")

# values ANAC uses for missing data
na_tokens <- c("", "null", "NULL", "NA", "N/A", "-", "XXXX", "....")









#' Check whether the format of the date input is acceptable
#' @param date Vector. Either a 6-digit date in the format `yyyymm` or a 4-digit
#'             date input `yyyy` .
#'
#' @return Check messages.
#' @export
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#'
#' # get all dates available
#' all_dates <- get_all_dates_available()
#'
#' # check dates
#' a <- check_date(200011, all_dates)
#'}}
check_input_date_format <- function(date = parent.frame()$date) {

  # are all dates yyyy
  yyyy <- (all(nchar(date)==4))

  # are all dates yyyymm
  yyyymm <- (all(nchar(date)==6))

  if(yyyy + yyyymm == 0){
    # name the read_*() function that called check_input_date_format() in the error
    cli::cli_abort(
      "{.arg date} must be consistently either a 6-digit {.code yyyymm} OR a 4-digit {.code yyyy}.",
      call = rlang::caller_env()
    )
  }
}


