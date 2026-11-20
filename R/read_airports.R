#' Download airports data from Brazil
#'
#' @description
#' Download data of all airports and aerodromes registered in Brazil’s Civil
#' Aviation Agency (ANAC). Data source: \url{https://www.gov.br/anac/pt-br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos}.
#' The data dictionary for public airports can be found at \url{https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-publicos-v2/70-lista-de-aerodromos-publicos-v2}.
#' The data dictionary for private airports can be found at \url{https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2}.
#'
#' @param type String. Whether the function should download data on `all`,
#'             `public` or `private` airports. Defaults to `all`, returning fewer
#'             columns. Downloading `public` and `private` airports separately
#'             will return the full set of columns available for each of those
#'             data sets.
#' @template showProgress
#' @template cache
#'
#' @return A `"data.table" "data.frame"` object.
#' @importFrom data.table :=
#' @export
#' @family download airport data
#' @examples \dontrun{ if (interactive()) {
#' # Read airports data
#' all_airports <- read_airports(type = 'all')
#'
#' public_airports <- read_airports(type = 'public')
#'
#' private_airports <- read_airports(type = 'private')
#'}}
read_airports <- function(type = 'all',
                          showProgress = TRUE,
                          cache = TRUE
                          ){

### check inputs
  type <- rlang::arg_match(type, c("all", "public", "private"))
  check_flag(showProgress, "showProgress")
  check_flag(cache, "cache")

  # data url
  # https://www.gov.br/anac/pt-br/assuntos/regulados/aerodromos/lista-de-aerodromos-civis-cadastrados

  url_public <- 'https://sistemas.anac.gov.br/dadosabertos/Aerodromos/Aer%C3%B3dromos%20P%C3%BAblicos/Lista%20de%20aer%C3%B3dromos%20p%C3%BAblicos/AerodromosPublicos.csv'
  url_private <- 'https://sistemas.anac.gov.br/dadosabertos/Aerodromos/Aer%C3%B3dromos%20Privados/Lista%20de%20aer%C3%B3dromos%20privados/Aerodromos%20Privados/AerodromosPrivados.csv'

  if (type %in% c('public', 'all')) {
    dt_public <- download_airports_data(url_public, 'public', showProgress, cache)
    if (is.null(dt_public)) { return(invisible(NULL)) }
    if (type == 'public') { return(dt_public) }
  }

  if (type %in% c('private', 'all')) {
    dt_private <- download_airports_data(url_private, 'private', showProgress, cache)
    if (is.null(dt_private)) { return(invisible(NULL)) }
    if (type == 'private') { return(dt_private) }
  }

  # type == 'all': keep only the columns both data sets have
  cols_to_keep <- intersect(names(dt_private), names(dt_public))

  dt <- data.table::rbindlist(
    list(dt_public[, cols_to_keep, with = FALSE],
         dt_private[, cols_to_keep, with = FALSE]),
    use.names = TRUE
    )

  return(dt)
}


#' Download and read one ANAC airports file
#'
#' @param file_url String. Url of the public or private airports file.
#' @param airport_type String. `"public"` or `"private"`, stored in the `type`
#'        column.
#' @template showProgress
#' @template cache
#'
#' @return A `"data.table" "data.frame"` object, or `NULL` if the download
#'         failed.
#' @keywords internal
download_airports_data <- function(file_url,
                                   airport_type,
                                   showProgress,
                                   cache) { # nocov start

  temp_local_file <- fs::path(flightsbr_cache_dir(), basename(file_url))

  check_download <- download_flightsbr_file(file_url = file_url,
                                            showProgress = showProgress,
                                            dest_file = temp_local_file,
                                            cache = cache)
  if (is.null(check_download)) { return(invisible(NULL)) }

  dt <- data.table::fread(temp_local_file,
                          skip = 1,
                          encoding = 'Latin-1',
                          colClasses = 'character',
                          sep = ';',
                          showProgress = showProgress)

  # clean names
  data.table::setnames(dt, janitor::make_clean_names(names(dt)))

  # fix geographical coordinates
  latlon_to_numeric(dt)
  altitude_to_numeric(dt)

  # add type info
  dt[, type := airport_type]

  # convert columns to numeric
  convert_to_numeric(dt)

  return(dt)
} # nocov end
