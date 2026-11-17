
# get_flights_files_available ----------------------------------------------------------------

#' Retrieve flight files available from the ANAC website
#'
#' @template cache
#' @return A data.table with columns `date`, `type`, and `url`.
#' @keywords internal
get_flights_files_available <- function(cache = TRUE) { # nocov start

  # cache the scraped file listing to a session-scoped temp file so
  # repeated calls within the same R session (e.g. several read_flights()
  # calls) don't repeatedly re-scrape the ANAC page
  cache_file <- fs::path(fs::path_temp(), "flightsbr_flights_files.rds")

  if (isFALSE(cache) && file.exists(cache_file)) {
    unlink(cache_file)
  }

  if (isTRUE(cache) && file.exists(cache_file)) {
    return(readRDS(cache_file))
  }

  url <- paste0(
    "https://www.gov.br/anac/pt-br/assuntos/regulados/empresas-aereas/",
    "Instrucoes-para-a-elaboracao-e-apresentacao-das-demonstracoes-contabeis/",
    "envio-de-informacoes"
  )

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
      httr2::req_perform(),
    silent = TRUE
  )

  if (inherits(resp, "try-error")) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  h <- httr2::resp_body_html(resp)

  # rows <- rvest::html_elements(h, "tr")
  tables <- rvest::html_elements(h, "table")

  files <- lapply(tables, function(tbl) {
    headers <- tbl |>
      rvest::html_elements(xpath = "./thead/tr/th") |>
      rvest::html_text2() |>
      trimws() |>
      janitor::make_clean_names()

    required <- c("ano", "mes", "basica", "combinada")

    if (!all(required %in% headers)) {
      return(NULL)
    }

    year_col <- match("ano", headers)
    month_col <- match("mes", headers)
    basica_col <- match("basica", headers)
    combinada_col <- match("combinada", headers)

    rows <- tbl |>
      rvest::html_elements(xpath = "./tbody/tr")

    out <- lapply(rows, function(row) {
      cells <- row |>
        rvest::html_elements(xpath = "./td")

      if (
        length(cells) <
          max(
            year_col,
            month_col,
            basica_col,
            combinada_col
          )
      ) {
        return(NULL)
      }

      year <- cells[[year_col]] |>
        rvest::html_text2() |>
        as.integer()

      month <- cells[[month_col]] |>
        rvest::html_text2() |>
        as.integer()

      if (is.na(year) || is.na(month)) {
        return(NULL)
      }

      basica_url <- cells[[basica_col]] |>
        rvest::html_element("a") |>
        rvest::html_attr("href")

      combinada_url <- cells[[combinada_col]] |>
        rvest::html_element("a") |>
        rvest::html_attr("href")

      tbl_out <- data.table::data.table(
        date = rep(year * 100L + month, 2L),
        type = c("basica", "combinada"),
        url = c(basica_url, combinada_url)
      )

      return(tbl_out)
    })

    return(data.table::rbindlist(out, fill = TRUE))
  })

  files <- data.table::rbindlist(files, fill = TRUE)

  # no table with the expected columns, e.g. ANAC served a maintenance page
  if (nrow(files) == 0 || !all(c("date", "type", "url") %in% names(files))) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  files <- files[
    !is.na(date) &
      !is.na(url) &
      nzchar(url)
  ]

  # ANAC lists relative hrefs that point to an HTML landing page; turn them
  # into absolute urls that point to the zip file itself
  page_url <- url
  files[, url := normalize_anac_url(url, base = page_url)]

  files <- unique(files)

  # don't cache an empty/partial result -- let the next call retry the scrape
  if (nrow(files) > 0) {
    saveRDS(files, cache_file)
  }

  return(files)
} # nocov end


# normalize_anac_url --------------------------------------------------------------------------

#' Turn an ANAC (gov.br) file href into a direct download url
#'
#' The flight file listing on gov.br links to each zip file through a relative
#' href (e.g. `/anac/.../basica2020-04.zip`) that serves an HTML landing page.
#' The zip file itself is served at `<href>/@@download/file`.
#'
#' @param href Character vector of hrefs, relative or absolute, with or
#'        without the `/@@download/file` suffix.
#' @param base String. Url of the page the hrefs were scraped from, used to
#'        resolve relative hrefs.
#'
#' @return A character vector of absolute urls ending in `/@@download/file`.
#' @keywords internal
normalize_anac_url <- function(href, base) {

  # resolve relative hrefs against the page url; absolute ones are kept as is
  url <- rvest::url_absolute(href, base)

  url <- ifelse(
    grepl("/@@download/file$", url),
    url,
    paste0(sub("/+$", "", url), "/@@download/file")
  )

  return(url)
}


# anac_file_name ------------------------------------------------------------------------------

#' Get the name of the file behind an ANAC download url
#'
#' @param file_url Character vector of urls, possibly ending in
#'        `/@@download/file`.
#'
#' @return A character vector of file names (e.g. `"basica2020-04.zip"`).
#' @keywords internal
anac_file_name <- function(file_url) {
  basename(sub("/@@download/file$", "", file_url))
}


# is_zip_file ---------------------------------------------------------------------------------

#' Check whether local files are zip archives
#'
#' Reads the first two bytes of each file and checks for the zip signature
#' `PK`. ANAC sometimes returns an HTML page with HTTP status 200 instead of
#' the requested zip file.
#'
#' @param path Character vector of local file paths.
#'
#' @return A logical vector, `FALSE` for files that are missing, empty, or not
#'         zip archives.
#' @keywords internal
is_zip_file <- function(path) {
  vapply(path, function(p) {
    if (!file.exists(p) || isTRUE(file.info(p)$size < 4)) {
      return(FALSE)
    }
    identical(readBin(p, what = "raw", n = 2L), charToRaw("PK"))
  }, logical(1), USE.NAMES = FALSE)
}


# get_flight_dates_available -----------------------------------------------------------------

#' Retrieve all dates available for flights data from ANAC website
#'
#' @param type String. Whether the data set should be of the type `basica`
#'             (flight stage, the default) or `combinada` (On flight origin and
#'             destination - OFOD).
#' @template cache
#' @return Numeric vector.
#' @export
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # check dates
#' a <- get_flight_dates_available()
#'}}
get_flight_dates_available <- function(type = NULL, cache = TRUE) {
  # nocov start

  if (!is.null(type)) {
    requested_type <- match.arg(type, c("basica", "combinada"))
  } else {
    requested_type <- NULL
  }

  files <- get_flights_files_available(cache = cache)

  if (is.null(files)) {
    return(invisible(NULL))
  }

  if (!is.null(requested_type)) {
    dates <- files[
      type == requested_type,
      sort(unique(date))
    ]
  } else {
    dates <- unique(files$date)
  }

  return(dates)
} # nocov end


# download_flights_data ----------------------------------------------------------------------

#' Download and read ANAC flight data
#'
#' @param file_url String. An ANAC url passed from above.
#' @param showProgress Logical, passed from above.
#' @param select A vector of column names or numbers to keep, passed from above.
#' @param cache Logical, passed from above.
#'
#' @return A `"data.table" "data.frame"` object
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' file_url <- get_flights_files_available()$url[1]
#'
#' # download data
#' a <- download_flights_data(
#'   file_url=file_url,
#'   showProgress=TRUE,
#'   select=NULL,
#'   cache=TRUE
#'   )
#'}}
download_flights_data <- function(file_url = parent.frame()$file_url,
                                  showProgress = parent.frame()$showProgress,
                                  select = parent.frame()$select,
                                  cache = parent.frame()$cache){ # nocov start

  # create temp local file. The name comes from the url without its
  # '/@@download/file' suffix, otherwise every month would be saved as 'file'
  file_name <- anac_file_name(file_url)
  temp_local_file <- fs::path(flightsbr_cache_dir(), file_name)

  # discard cached files that are not zip archives
  bad_cache <- file.exists(temp_local_file) & !is_zip_file(temp_local_file)
  unlink(temp_local_file[bad_cache])

  # download files that are not cached yet
  check_download <- download_flightsbr_file(
    file_url = file_url,
    showProgress = showProgress,
    dest_file = temp_local_file,
    cache = cache
    )

  if (is.null(check_download)) {
    return(invisible(NULL))
  }

  # ANAC can answer with a web page instead of the zip file
  not_zip <- !is_zip_file(temp_local_file)
  if (any(not_zip)) {
    unlink(temp_local_file[not_zip])
    message(
      "ANAC returned a web page instead of the data file for: ",
      paste(file_name[not_zip], collapse = ", "),
      ". Please try it again later."
    )
    return(invisible(NULL))
  }


  ## unzip and fread
  unzip_and_fread <- function(single_temp_local_file,
                              showProgress = parent.frame()$showProgress,
                              select = parent.frame()$select){

    # extract to a folder of its own, deleted after reading, so the large
    # .txt files don't pile up in the temp dir
    temp_local_dir <- tempfile(pattern = "flightsbr_")
    on.exit(unlink(temp_local_dir, recursive = TRUE), add = TRUE)

    tryCatch({
      archive::archive_extract(
        archive = single_temp_local_file,
        dir = temp_local_dir
        )

      txt_file <- list.files(temp_local_dir, full.names = TRUE, recursive = TRUE)

      data.table::fread(txt_file[1],
                        select = select,
                        showProgress = showProgress,
                        colClasses = 'character',
                        sep = ';',
                        encoding = 'Latin-1')
      },
      error = function(e) NULL
    )
  }

  message('Unziping and reading data to memory.')
  if (isTRUE(showProgress)) {
    dt <- pbapply::pblapply(X=temp_local_file, FUN=unzip_and_fread,
                            select = select,
                            showProgress = showProgress)
  } else {
    dt <- lapply(X=temp_local_file, FUN=unzip_and_fread,
                 select = select,
                 showProgress = showProgress)
  }

  # a corrupt zip can't be read: drop it from the cache so the next call
  # downloads it again
  failed <- vapply(dt, is.null, logical(1))
  if (any(failed)) {
    unlink(temp_local_file[failed])
    message(
      "Could not read the data file for: ",
      paste(file_name[failed], collapse = ", "),
      ". The cached copy was removed; please try it again."
    )
    return(invisible(NULL))
  }

  return(dt)

} # nocov end
