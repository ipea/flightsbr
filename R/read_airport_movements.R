#' Download airport movement data from Brazil
#'
#' @description
#' Download airport movements data from Brazil’s Civil Aviation Agency (ANAC).
#' The data covers all passenger, aircraft, cargo and mail movement data from
#' airports regulated by ANAC. Data only available from March 2019 onwards. A
#' description of all variables included in the data is available at
#' \url{https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/operador-aeroportuario/dados-de-movimentacao-aeroportuaria/60-dados-de-movimentacao-aeroportuaria}.
#'
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
#' @family download airport movement data
#' @examples \dontrun{ if (interactive()) {
#' # Read airport movement data
#' amov202006 <- read_airport_movements(date = 202006)
#'
#' amov2020 <- read_airport_movements(date = 2020)
#'}}
read_airport_movements <- function(date = NULL,
                                   showProgress = TRUE,
                                   cache = TRUE
                                   ){

  ### check inputs
  if( ! is.logical(showProgress) ){ stop(paste0("Argument 'showProgress' must be either 'TRUE' or 'FALSE.")) }
  if( ! is.logical(cache) ){ stop(paste0("Argument 'cache' must be either 'TRUE' or 'FALSE.")) }
  check_input_date_format(date)

  ### check date input
  # get all dates available
  all_dates <- get_airport_movement_dates_available()

  # check if download failed
  if (is.null(all_dates)) { return(invisible(NULL)) }

  # check dates
  if (is.null(date)) { date <- max(all_dates) }
  check_date(date=date, all_dates)

  # expand years to the months available on ANAC
  date <- available_months(date, all_dates)


  #### Download and read data

  # prepare url of online files
  file_url <- get_airport_movements_url(date=date)

  # download and read data
  dt <- download_airport_movement_data(file_url = file_url,
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
