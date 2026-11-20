#' Retrieve all dates available for airfares data from ANAC website
#'
#' @param dom Logical. Defaults to `TRUE` download airfares of domestic
#'                 flights. If `FALSE`, the function downloads airfares of
#'                 international flights.
#' @template cache
#'
#' @return Numeric vector.
#' @export
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # check dates
#' a <- get_airfares_dates_available(dom = TRUE)
#'}}
get_airfares_dates_available <- function(dom, cache = TRUE) { # nocov start

  files <- get_airfares_files_available(dom = dom, cache = cache)

  if (is.null(files)) {
    return(invisible(NULL))
  }

  return(sort(unique(as.numeric(files$date))))
} # nocov end


#' Retrieve the airfare files available on the ANAC website
#'
#' Scrapes ANAC's directory listing (one request per year folder) and keeps
#' one file per month. The result is cached for the R session. If some year
#' folders could not be read, the result has an attribute `failed_years` with
#' those years.
#'
#' @inheritParams get_airfares_dates_available
#'
#' @return A data.table with columns `date` (numeric, `yyyymm`) and `url`, or
#'         `NULL` if ANAC could not be reached.
#' @keywords internal
get_airfares_files_available <- function(dom, cache = TRUE) { # nocov start

  # one HTTP request per year folder (~25), so cache the listing for the
  # session
  cache_file <- fs::path(
    fs::path_temp(),
    paste0(
      "flightsbr_airfares_files_",
      if (isTRUE(dom)) "domestic" else "international",
      ".rds"
    )
  )

  if (isFALSE(cache) && file.exists(cache_file)) {
    unlink(cache_file)
  }

  if (isTRUE(cache) && file.exists(cache_file)) {
    return(readRDS(cache_file))
  }

  base_url <- if (isTRUE(dom)) {
    "https://sas.anac.gov.br/sas/tarifadomestica/"
  } else {
    "https://sas.anac.gov.br/sas/tarifainternacional/"
  }

  # read main page
  href <- read_anac_listing(base_url)

  if (is.null(href)) {
    cli::cli_inform("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  # links to year folders
  folder <- if (isTRUE(dom)) "/tarifadomestica/" else "/tarifainternacional/"
  years <- unique(sub(
    paste0(".*", folder, "([0-9]{4})/?$"), "\\1",
    href[grepl(paste0(folder, "[0-9]{4}/?$"), href)]
  ))

  # links to data files, one request per year folder. NULL means the folder
  # could not be read
  href_by_year <- lapply(paste0(base_url, years, "/"), read_anac_listing)
  failed_years <- years[vapply(href_by_year, is.null, logical(1))]

  if (length(failed_years) == length(years)) {
    cli::cli_inform("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  if (length(failed_years) > 0) {
    n_failed <- length(failed_years)
    n_years <- length(years)
    cli::cli_inform(paste(
      "Could not reach {n_failed} of {n_years} year{?s} on the ANAC data server;",
      "the list of available dates may be incomplete. Please try it again."
    ))
  }

  files <- airfare_files_from_hrefs(unlist(href_by_year), dom = dom)
  files[, url := rvest::url_absolute(url, base_url)]

  if (nrow(files) == 0) {
    cli::cli_inform("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  data.table::setattr(files, "failed_years", failed_years)
  saveRDS(files, cache_file)

  return(files)
} # nocov end


#' Read the links of an ANAC directory listing page
#'
#' @param url String. Url of an ANAC directory listing.
#'
#' @return A character vector of hrefs, or `NULL` if the page could not be
#'         read or is not a directory listing (e.g. a page blocking the
#'         request).
#' @keywords internal
read_anac_listing <- function(url) { # nocov start

  # ANAC's server intermittently drops requests when many are made in a row,
  # so each request gets a timeout and retries
  resp <- try(
    httr2::request(url) |>
      httr2::req_user_agent(
        "Mozilla/5.0 (compatible; flightsbr; +https://github.com/ipea/flightsbr)"
      ) |>
      httr2::req_headers(
        Accept = paste0(
          "text/html,application/xhtml+xml,application/xml;",
          "q=0.9,*/*;q=0.8"
        ),
        `Accept-Language` = "pt-BR,pt;q=0.9,en;q=0.8"
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_retry(max_tries = 4, retry_on_failure = TRUE) |>
      httr2::req_perform(),
    silent = TRUE
  )

  if (inherits(resp, "try-error")) {
    return(NULL)
  }

  h <- httr2::resp_body_html(resp)

  # a real IIS directory listing always links back to its parent folder; a
  # page blocking the request does not
  if (!grepl("To Parent Directory", rvest::html_text2(h), fixed = TRUE)) {
    return(NULL)
  }

  rvest::html_attr(rvest::html_elements(h, "a"), "href")
} # nocov end


#' Pick one airfare file per month from the hrefs of ANAC's listings
#'
#' ANAC's folders contain duplicates and stray files (re-uploads named
#' `yyyymm (1).csv`, `.CSV.csv` copies, the same month in two year folders,
#' `.txt` and `.csv` versions). This keeps files that follow the naming
#' convention and, for each month, prefers the file in the folder of its own
#' year, then a `.csv` over a `.txt`, then a name without `(1)`.
#'
#' @param href Character vector of hrefs (relative or absolute).
#' @inheritParams get_airfares_dates_available
#'
#' @return A data.table with columns `date` (numeric) and `url` (the href).
#' @keywords internal
airfare_files_from_hrefs <- function(href, dom) {

  href <- unique(href[!is.na(href)])
  file_name <- utils::URLdecode(basename(href))

  if (isTRUE(dom)) {
    pattern <- "^([0-9]{6})( \\(1\\))?[.]csv$"
    ok <- grepl(pattern, file_name, ignore.case = TRUE)
    date <- sub(pattern, "\\1", file_name[ok], ignore.case = TRUE)
  } else {
    pattern <- "^internacional_([0-9]{4})-([0-9]{2})[.](csv|txt)$"
    ok <- grepl(pattern, file_name, ignore.case = TRUE)
    date <- sub(pattern, "\\1\\2", file_name[ok], ignore.case = TRUE)
  }

  href <- href[ok]
  file_name <- file_name[ok]

  files <- data.table::data.table(
    date = as.numeric(date),
    url = href,
    own_folder = basename(dirname(href)) == substr(date, 1, 4),
    is_csv = grepl("[.]csv$", file_name, ignore.case = TRUE),
    is_copy = grepl("(1)", file_name, fixed = TRUE)
  )

  data.table::setorderv(
    files,
    c("date", "own_folder", "is_csv", "is_copy"),
    order = c(1L, -1L, -1L, 1L)
  )
  files <- unique(files, by = "date")

  return(files[, c("date", "url"), with = FALSE])
}


#' Download and read ANAC air fares data
#'
#' @param file_urls String. A url passed from above.
#' @template showProgress
#' @template cache
#'
#' @return A `"data.table" "data.frame"` object with harmonized column
#'         names, or `NULL` if the download failed.
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' files <- get_airfares_files_available(dom = TRUE)
#'
#' a <- download_airfares_data(file_urls = files$url[1], showProgress = TRUE)
#'}}
download_airfares_data <- function(file_urls = parent.frame()$file_urls,
                                   showProgress = parent.frame()$showProgress,
                                   cache = parent.frame()$cache
                                   ){ # nocov start

  # the year folder is part of the name: the same file name can sit in two
  # year folders
  file_name <- utils::URLdecode(basename(file_urls))
  file_name <- paste0(basename(dirname(file_urls)), "_", gsub(" ", "_", file_name))
  temp_local_file <- fs::path(flightsbr_cache_dir(), file_name)

  # download files that are not cached yet
  check_download <- download_flightsbr_file(file_url = file_urls,
                                            showProgress = showProgress,
                                            dest_file = temp_local_file,
                                            cache = cache)
  if (is.null(check_download)) { return(invisible(NULL)) }

  dt <- pbapply::pblapply(X = temp_local_file,
                          FUN = read_airfare_file,
                          showProgress = showProgress)

  dt <- data.table::rbindlist(dt, use.names = TRUE, fill = TRUE)

  return(dt)
} # nocov end


#' Read one airfare file and harmonize its column names
#'
#' @param path String. Local file path.
#' @template showProgress
#'
#' @return A data.table with ANAC's current column names.
#' @keywords internal
read_airfare_file <- function(path, showProgress = FALSE) {

  dt <- data.table::fread(path,
                          showProgress = showProgress,
                          encoding = detect_header_encoding(path),
                          colClasses = 'character',
                          sep = ';')

  harmonize_airfare_names(dt, file_name = basename(path))

  return(dt)
}


#' Detect whether a file's header line is UTF-8 or Latin-1
#'
#' @param path String. Local file path.
#'
#' @return `"UTF-8"` or `"Latin-1"`.
#' @keywords internal
detect_header_encoding <- function(path) {

  bytes <- readBin(path, what = "raw", n = 4096L)
  bytes <- bytes[bytes != as.raw(0)]

  newline <- which(bytes == as.raw(10))[1]
  if (!is.na(newline)) {
    bytes <- bytes[seq_len(newline - 1)]
  }

  if (validUTF8(rawToChar(bytes))) "UTF-8" else "Latin-1"
}


#' Rename airfare columns to ANAC's current names
#'
#' ANAC has used five different headers for the same columns over the years.
#' Every version is mapped to the names ANAC uses in its current files (see
#' `airfare_col_map`), so files from different periods bind into the same
#' columns. A leading row-index column (empty header) is dropped.
#'
#' @param dt A data.table read from an airfare file. Modified by reference.
#' @param file_name String. File name, used in error messages.
#'
#' @return `dt`, invisibly.
#' @keywords internal
harmonize_airfare_names <- function(dt, file_name = "") {

  data.table::setnames(dt, janitor::make_clean_names(names(dt)))

  # some files start with an unnamed row-index column
  if (names(dt)[1] %in% c("v1", "x")) {
    dt[, (names(dt)[1]) := NULL]
  }

  new_names <- airfare_col_map[names(dt)]

  if (anyNA(new_names)) {
    unexpected <- names(dt)[is.na(new_names)]
    cli::cli_abort(
      c("ANAC file {.file {file_name}} has {length(unexpected)} unexpected column{?s}: {.field {unexpected}}.",
        "i" = "Please report this at {.url https://github.com/ipea/flightsbr/issues}"),
      call = NULL
    )
  }

  data.table::setnames(dt, unname(new_names))

  return(invisible(dt))
}


#' Map airfare column names to ANAC's current names
#'
#' @param x Character vector of column names (raw or clean).
#'
#' @return Character vector of current names, `NA` where a name is unknown.
#' @keywords internal
airfare_canonical_names <- function(x) {
  unname(airfare_col_map[janitor::make_clean_names(x)])
}


# clean (janitor) column names used by ANAC over time -> current names
airfare_col_map <- c(
  # current names
  nr_ano_referencia = "nr_ano_referencia",
  nr_mes_referencia = "nr_mes_referencia",
  sg_empresa_icao = "sg_empresa_icao",
  sg_icao_origem = "sg_icao_origem",
  sg_icao_destino = "sg_icao_destino",
  sg_icao_retorno = "sg_icao_retorno",
  cd_classe_ida = "cd_classe_ida",
  cd_classe_volta = "cd_classe_volta",
  nr_tarifa = "nr_tarifa",
  nr_assentos = "nr_assentos",
  # year
  ano = "nr_ano_referencia",
  ano_de_referencia = "nr_ano_referencia",
  # month
  mes = "nr_mes_referencia",
  mes_de_referencia = "nr_mes_referencia",
  # airline
  empresa = "sg_empresa_icao",
  icao_empresa_aerea = "sg_empresa_icao",
  designador_icao_empresa = "sg_empresa_icao",
  # origin
  origem = "sg_icao_origem",
  icao_aerodromo_origem = "sg_icao_origem",
  designador_icao_aeroporto_origem = "sg_icao_origem",
  # destination
  destino = "sg_icao_destino",
  icao_aerodromo_destino = "sg_icao_destino",
  designador_icao_aeroporto_destino = "sg_icao_destino",
  # return airport (international)
  retorno = "sg_icao_retorno",
  icao_aerodromo_retorno = "sg_icao_retorno",
  designador_icao_aeroporto_retorno = "sg_icao_retorno",
  # fare classes (international)
  classe_ida = "cd_classe_ida",
  classe_volta = "cd_classe_volta",
  classe_retorno = "cd_classe_volta",
  # fare
  tarifa = "nr_tarifa",
  tarifa_n = "nr_tarifa",
  tarifa_nominal = "nr_tarifa",
  valor_tarifa = "nr_tarifa",
  # seats
  assentos = "nr_assentos",
  assentos_comercializados = "nr_assentos"
)
