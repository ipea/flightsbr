#' Download aircraft data from Brazil
#'
#' @description
#'
#' Download data of all aircraft registered in the Brazilian Aeronautical
#' Registry (Registro Aeronáutico Brasileiro - RAB), organized by the Brazilian
#' Civil Aviation Agency (ANAC). A description of all variables included in the
#' data is available at \url{https://www.gov.br/anac/pt-br/sistemas/rab}.
#'
#' @template date
#' @template showProgress
#' @template cache
#'
#' @return A `"data.table" "data.frame"` object. Columns of counts and
#'         measures are numeric; codes and identifiers (e.g. flight numbers,
#'         serial numbers, airport codes) are character, keeping leading
#'         zeros. A column with some values that are not numbers stays
#'         character, with a message.
#' @export
#' @family download flight data
#' @examples \dontrun{ if (interactive()) {
#' # Read aircraft data
#' aircraft <- read_aircraft(date = 202409,
#'                           showProgress = TRUE
#'                           )
#'
#'
#'}}
read_aircraft <- function(date = NULL,
                          showProgress = TRUE,
                          cache = TRUE
                          ){

### check inputs
  check_flag(showProgress, "showProgress")
  check_flag(cache, "cache")
  check_input_date_format(date)

  ### check date input
  # get all dates available
  all_dates <- get_aircraft_dates_available()

  # check if download failed
  if (is.null(all_dates)) { return(invisible(NULL)) }

  # check dates
  if (is.null(date)) { date <- max(all_dates) }
  check_date(date=date, all_dates)

  # expand years to the months available on ANAC
  date <- available_months(date, all_dates)

  # get url of files
  file_urls <- get_aircraft_url(date)


  # download and read data
  dt <- download_aircraft_data(file_url = file_urls,
                                showProgress = showProgress,
                                cache = cache)

  # check if download failed
  if (is.null(dt)) { return(invisible(NULL)) }

  # clean names
  nnn <- names(dt)
  data.table::setnames(
    x = dt,
    old = nnn,
    new = janitor::make_clean_names(nnn)
    )

  # convert columns to numeric
  convert_to_numeric(dt)

  return(dt)
}
