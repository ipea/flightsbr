#' Retrieve all dates available for aircraft data from ANAC website
#'
#' @return Numeric vector.
#' @export
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # check dates
#' a <- get_aircraft_dates_available()
#'}}
get_aircraft_dates_available <- function() { # nocov start

  # read html table
  base_url = 'https://sistemas.anac.gov.br/dadosabertos/Aeronaves/RAB/Historico_RAB/'
  h <- try(rvest::read_html(base_url), silent = TRUE)

  # check if internet connection worked
  if (class(h)[1]=='try-error') {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  # filter elements of basica data
  elements <- rvest::html_elements(h, "a")
  basica_urls <- elements[ data.table::like(elements, '.csv') ]
  basica_urls <- lapply(X=basica_urls, FUN=function(i){rvest::html_attr(i,"href")})

  # get all dates available
  all_dates <- substr(basica_urls, 1, nchar(basica_urls)-4 )
  all_dates <- gsub("[-]", "", all_dates)
  all_dates <- gsub("[_]", "", all_dates)

  # remove eventual letters
  all_dates <- sub("a", "", all_dates, fixed = TRUE)
  ## remove ALL eventual letters
  # all_dates <- lapply(X = base::letters,
  #                     FUN = function(x){
  #                       all_datesf <- sub(x, "", all_dates, fixed = TRUE)
  #                       return(all_datesf)}
  #                     )
  all_dates <- unique(all_dates)
  all_dates <- as.numeric(all_dates)
  return(all_dates)
} # nocov end



#' Put together the url of aircraft data files
#'
#' @param date Numeric. Either a 6-digit date in the format `yyyymm` or a 4-digit
#'             date input `yyyy`. Defaults to `NULL`, in which case the function
#'             retrieves information for all years available.
#'
#' @return A url string.
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' a <- get_aircraft_url(202505)
#'}}
get_aircraft_url <- function(date = parent.frame()$date) { # nocov start

  url_root <- 'https://sistemas.anac.gov.br/dadosabertos/Aeronaves/RAB/Historico_RAB/'

  # date with format yyyymm (years are expanded by available_months())
  years <- substring(date,1,4)
  months <- substring(date,5,6)
  file_urls <- paste0(url_root, years, '-', months, '.csv')

  return(file_urls)
} # nocov end


#' Download and read ANAC aircraft data
#'
#' @param file_url String. A url passed from above.
#' @param showProgress Logical, passed from \code{\link{read_flights}}
#' @param cache Logical, passed from \code{\link{read_flights}}
#'
#' @return A `"data.table" "data.frame"` object
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' file_url <- get_aircraft_url(date = 202409)
#'
#' # download data
#' a <- download_aircraft_data(file_url = file_url, showProgress = TRUE, cache = TRUE)
#'}}
download_aircraft_data <- function(file_url = parent.frame()$file_url,
                                    showProgress = parent.frame()$showProgress,
                                    cache = parent.frame()$cache
                                    ){ # nocov start

  # create temp local file
  file_name <- basename(file_url)
  temp_local_file <- fs::path(flightsbr_cache_dir(), file_name)

  # download files that are not cached yet
  check_download <- download_flightsbr_file(file_url = file_url,
                                            showProgress = showProgress,
                                            dest_file = temp_local_file,
                                            cache = cache)
  if (is.null(check_download)) { return(invisible(NULL)) }

  # read files stored locally
  dt <- pbapply::pblapply(X = temp_local_file,
                          FUN = read_aircraft_file,
                          showProgress = showProgress)

  # ANAC changed the RAB layout in 2026: warn when months with different
  # layouts are combined
  layouts <- unique(lapply(dt, names))
  if (length(layouts) > 1) {
    all_cols <- unique(unlist(layouts))
    partial <- all_cols[!vapply(all_cols, \(col) all(vapply(dt, \(x) col %in% names(x), logical(1))), logical(1))]
    warning(
      "The requested months use different RAB file layouts. These columns ",
      "only exist in some months and are NA in the others: ",
      paste(janitor::make_clean_names(partial), collapse = ", "),
      call. = FALSE
    )
  }

  dt <- data.table::rbindlist(dt, use.names = TRUE, fill = TRUE)

  return(dt)
} # nocov end


#' Read one RAB file
#'
#' Reads a monthly RAB file and makes the layouts ANAC has used comparable:
#' the registration mark column is always `MARCAS` (it was `MARCA` until early
#' 2026), empty cells and the text `"null"` become `NA`, and quotes escaped as
#' `""` inside a field (used in the JSON owner and operator columns) are
#' un-escaped.
#'
#' @param path String. Local file path. The file name must be `yyyy-mm.csv`.
#' @template showProgress
#'
#' @return A data.table with raw (upper case) column names and a
#'         `reference_date` column.
#' @keywords internal
read_aircraft_file <- function(path, showProgress = FALSE) {

  dt <- data.table::fread(path,
                          showProgress = showProgress,
                          encoding = 'UTF-8',
                          colClasses = 'character',
                          skip = 1,
                          sep = ';')

  data.table::setnames(dt, "MARCA", "MARCAS", skip_absent = TRUE)

  # fread keeps "" (an escaped quote) as two characters, and its na.strings
  # argument does not apply to quoted fields, so fix both here
  for (col in names(dt)) {
    x <- dt[[col]]
    x[x %in% c("", "null")] <- NA_character_
    has_escaped_quote <- !is.na(x) & grepl('""', x, fixed = TRUE)
    x[has_escaped_quote] <- gsub('""', '"', x[has_escaped_quote], fixed = TRUE)
    data.table::set(dt, j = col, value = x)
  }

  # add date of reference
  xdate <- gsub('-', '', fs::path_ext_remove(basename(path)))
  dt[, reference_date := xdate]

  return(dt)
}
