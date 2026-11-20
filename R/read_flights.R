#' Download flight data from Brazil
#'
#' @description
#' Download flight data from Brazil’s Civil Aviation Agency (ANAC). The data
#' includes detailed information on every international flight to and from Brazil,
#' as well as domestic flights within the country. The data include flight-level
#' information of airports of origin and destination, flight duration, aircraft
#' type, payload, and the number of passengers, and several other variables. A
#' description of all variables included in the data is available at \url{https://www.gov.br/anac/pt-br/assuntos/regulados/empresas-aereas/Instrucoes-para-a-elaboracao-e-apresentacao-das-demonstracoes-contabeis/descricao-de-variaveis}.
#'
#' @param date Numeric. Date of the data in the format `yyyymm`. Defaults to
#'             the latest available month. To download the data for all months
#'             in a year, the user can pass a 4-digit year input `yyyy`. The
#'             parameter also accepts a vector of dates such as
#'             `c(202001, 202006, 202012)`.
#' @param type String. Whether the data set should be of the type `basica`
#'             (flight stage, the default) or `combinada` (On flight origin and
#'             destination - OFOD).
#' @template showProgress
#' @template cache
#' @template select
#'
#' @return A `"data.table" "data.frame"` object. Columns of counts and
#'         measures are numeric; codes and identifiers (e.g. flight numbers,
#'         serial numbers, airport codes) are character, keeping leading
#'         zeros. A column with some values that are not numbers stays
#'         character, with a message.
#' @export
#' @family download flight data
#' @examples \dontrun{ if (interactive()) {
#' # Read flights data
#' f201506 <- read_flights(date = 201506)
#'
#' f2015 <- read_flights(date = 2015)
#'}}
read_flights <- function(
  date = NULL,
  type = "basica",
  showProgress = TRUE,
  select = NULL,
  cache = TRUE
  ){

  ### check inputs
  requested_type <- rlang::arg_match(type, c("basica", "combinada"))
  check_flag(showProgress, "showProgress")
  check_flag(cache, "cache")
  check_input_date_format(date)

  ### get files available
  files <- get_flights_files_available(cache = cache)

  if (is.null(files)) {
    return(invisible(NULL))
  }

  # subset files: only required type
  files <- files[type == requested_type]
  all_dates <- files$date

  ### check date input
  if (is.null(date)) {
    date <- max(all_dates)
  }
  check_date(date = date, all_dates)

  # expand years to months
  if (all(nchar(date) == 4L)) {
    date <- generate_all_months(date)
  }

  # subset files: only required dates
  requested_dates <- date
  files <- files[date %in% requested_dates]

  #### Download and read data
  dt_list <- download_flights_data(files$url, showProgress, select, cache)

  # check if download failed
  if (is.null(dt_list)) {
    return(invisible(NULL))
  }

  #### prep data

  # row bind data tables
  dt <- data.table::rbindlist(dt_list, fill = TRUE)

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
