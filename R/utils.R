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

  error_message <-  paste0("The data is currently only available for dates between ", min(all_dates), " and ", max(all_dates), ".")

  for(d in date){
    if (nchar(d)==6) {
      if (!(d %in% all_dates)) {stop(error_message)}
      }

    if (nchar(d)!=6) {
      if (!(d %in% unique(substr(all_dates, 1, 4)) )) {stop(error_message)}
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
  if (any(nchar(date)!=4)) { stop(paste0("Argument 'date' must be 4-digit in the format `yyyy`.")) }

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




#' Download files from urls, reusing cached copies
#'
#' Downloads each file to a temporary `.part` file and only moves it to
#' `dest_file` once the download succeeded and the content is not an HTML
#' page. A failed or blocked request therefore never leaves a file at
#' `dest_file`, so later calls with `cache = TRUE` cannot read an error page as
#' data.
#'
#' @param file_url String. A url passed from above.
#' @param showProgress Logical, passed from above.
#' @param dest_file String. Local path(s) where the file(s) are saved, one per
#'        `file_url`. Defaults to the temp dir plus `basename(file_url)`.
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
                                    dest_file = fs::path(fs::path_temp(), basename(file_url)),
                                    cache = cache) { # nocov start

  if (length(dest_file) != length(file_url)) {
    stop("'dest_file' must have the same length as 'file_url'.")
  }

  dest_file <- as.character(dest_file)

  # two requests writing to the same path would collide
  keep <- !duplicated(dest_file)
  file_url <- file_url[keep]
  dest_file <- dest_file[keep]

  if (isFALSE(cache)) {
    unlink(dest_file)
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
    message(
      "The ANAC data server refused the request (it returned a web page ",
      "instead of the data file). Please wait a few minutes and try again."
    )
  } else {
    message("Problem connecting to ANAC data server. Please try it again.")
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
#' @param df A data.frame internal to the `read_airport()` function.
#'
#' @return A `"data.table" "data.frame"` object
#'
#' @keywords internal
latlon_to_numeric <- function(df){ # nocov start

  # check if df has lat lon colnames
  if(!'latitude' %in% names(df)){ stop("Column 'latitude' is missing from original ANAC data.") }
  if(!'longitude' %in% names(df)){ stop("Column 'longitude' is missing from original ANAC data.") }

  # ref
  # https://semba-blog.netlify.app/02/25/2020/geographical-coordinates-conversion-made-easy-with-parzer-package-in-r/

  # supress warning
  defaultW <- getOption("warn")
  options(warn = -1)

  # # fix string
  # df[, latitude := gsub("[\u00c2]", "", latitude) ]
  # df[, longitude := gsub("[\u00c2]", "", longitude) ]

  # convert to numeric
  df[, latitude := parzer::parse_lat(latitude) ]
  df[, longitude := parzer::parse_lon(longitude) ]

  # duckplyr
  # df <- df |>
  #   mutate(latitude = parzer::parse_lat(latitude),
  #          longitude = parzer::parse_lon(longitude)
  #          )


  # restore warnings
  options(warn = defaultW)

  return(df)
} # nocov end


#' Convert altitude column to numeric
#'
#' @param df A data.frame internal to the `read_airport()` function.
#'
#' @return A `"data.table" "data.frame"` object
#'
#' @keywords internal
altitude_to_numeric <- function(df){ # nocov start

  # check if df has lat lon colnames
  if(!'altitude' %in% names(df)){ stop("Column 'altitude' is missing from original ANAC data.") }

  # supress warning
  defaultW <- getOption("warn")
  options(warn = -1)

  # fix string
  df[, altitude := gsub(" m", "", altitude) ]
  df[, altitude := gsub(",", ".", altitude) ]

  # convert to numeric
  df[, altitude := as.numeric(altitude) ]

  # restore warnings
  options(warn = defaultW)

  return(df)
} # nocov end




#' @keywords internal
convert_to_numeric <- function(dt, type='standard') { # nocov start

  # detect if there are any columns that should be numeric
  numeric_cols <- names(dt)[names(dt) %like% 'NR_|nr_|qt_|comprimento_|largura_']
  numeric_cols <- numeric_cols[numeric_cols != 'nr_singular']

  if (type =='airfare') {
    airfare_num_cols <- c('ano', 'mes', 'tarifa_n', 'tarifa', 'assentos')
    airfare_num_cols <- airfare_num_cols[airfare_num_cols %in% names(dt)]
    numeric_cols <- c(numeric_cols, airfare_num_cols)
    }


  if (length(numeric_cols)==0) { return(invisible(TRUE)) }

  # replace , with . for numbers
  dt[,(numeric_cols):= lapply(.SD, FUN = function(x){gsub(',','.',x)}), .SDcols = numeric_cols]
  # to numeric
  suppressWarnings(
    dt[,(numeric_cols):= lapply(.SD, as.numeric), .SDcols = numeric_cols]
    )

  return(invisible(TRUE))
} # nocov end









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
  stop("The 'date' input must be consistent in either a 6-digit format `yyyymm` OR a 4-digit format `yyyy`.")
  }
}


