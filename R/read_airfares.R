#' Download data on airfares flights in Brazil
#'
#' @description
#' Download data on air fares of domestic and international flights in Brazil.
#' The data is collected by Brazil’s Civil Aviation Agency (ANAC). A description
#' of all variables included in the data for domestic airfares is available at
#' \url{https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/voos-e-operacoes-aereas/tarifas-aereas-domesticas/46-tarifas-aereas-domesticas}.
#' A description of all variables included in the data for international airfares
#' is available at \url{https://www.gov.br/anac/pt-br/assuntos/dados-e-estatisticas/microdados-de-tarifas-aereas-comercializadas}.
#'
#' @template date
#' @param domestic Logical. Defaults to `TRUE` download airfares of domestic
#'                 flights. If `FALSE`, the function downloads airfares of
#'                 international flights.
#' @template showProgress
#' @template select
#' @template cache
#'
#' @details
#' ANAC has changed the column names of these files several times. All files
#' are returned with the names ANAC uses in its current files
#' (`nr_ano_referencia`, `nr_mes_referencia`, `sg_empresa_icao`,
#' `sg_icao_origem`, `sg_icao_destino`, `nr_tarifa`, `nr_assentos` and, for
#' international flights, `sg_icao_retorno`, `cd_classe_ida`,
#' `cd_classe_volta`), so files from different years can be combined.
#' `select` accepts these names as well as older names such as `"TARIFA"` or
#' `"ano"`.
#'
#' @return A `"data.table" "data.frame"` object.
#' @export
#' @family download air fares data
#' @examples \dontrun{ if (interactive()) {
#' # Read air fare data
#' af_201506 <- read_airfares(date = 201506, domestic = TRUE)
#'
#' af_2015 <- read_airfares(date = 2015, domestic = TRUE)
#'}}
read_airfares <- function(
  date = NULL,
  domestic = TRUE,
  showProgress = TRUE,
  select = NULL,
  cache = TRUE
) {
  ### check inputs
  if (!(isTRUE(domestic) || isFALSE(domestic))) {
    stop(paste0("Argument 'domestic' must be either 'TRUE' or 'FALSE'."))
  }
  if (!is.logical(showProgress)) {
    stop(paste0("Argument 'showProgress' must be either 'TRUE' or 'FALSE'."))
  }
  if (!is.logical(cache)) {
    stop(paste0("Argument 'cache' must be either 'TRUE' or 'FALSE'."))
  }
  if (!is.null(select) && !is.character(select)) {
    stop("Argument 'select' must be a character vector of column names.")
  }
  check_input_date_format(date)

  ### get files available
  files <- get_airfares_files_available(dom = domestic, cache = cache)

  if (is.null(files)) {
    return(invisible(NULL))
  }

  # the cached listing may miss years ANAC failed to list last time: if the
  # request touches one of them, list the files again
  failed_years <- attr(files, "failed_years")
  if (!is.null(date) && any(substr(date, 1, 4) %in% failed_years)) {
    files <- get_airfares_files_available(dom = domestic, cache = FALSE)
    if (is.null(files)) {
      return(invisible(NULL))
    }
  }

  all_dates <- files$date

  ### check date input
  if (is.null(date)) {
    date <- max(all_dates)
  }
  check_date(date = date, all_dates)

  # expand years to the months available on ANAC
  date <- available_months(date, all_dates)
  requested_dates <- date
  file_urls <- files[date %in% requested_dates]$url

  ### download and read data
  dt <- download_airfares_data(
    file_urls = file_urls,
    showProgress = showProgress,
    cache = cache
  )

  # check if download failed
  if (is.null(dt)) {
    return(invisible(NULL))
  }

  ### keep selected columns
  if (!is.null(select)) {
    select_cols <- airfare_canonical_names(select)

    if (anyNA(select_cols)) {
      warning(
        "Column(s) not found in airfare data: ",
        paste(select[is.na(select_cols)], collapse = ", ")
      )
    }

    select_cols <- intersect(unique(select_cols[!is.na(select_cols)]), names(dt))
    dt <- dt[, select_cols, with = FALSE]
  }

  # convert columns to numeric
  convert_to_numeric(dt)

  return(dt)
}
