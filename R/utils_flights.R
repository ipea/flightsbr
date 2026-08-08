
# get_flights_files_available ----------------------------------------------------------------

#' Retrieve flight files available from the ANAC website
#'
#' @return A data.table with columns `date`, `type`, and `url`.
#' @keywords internal
get_flights_files_available <- function() { # nocov start

  url <- paste0(
    "https://www.gov.br/anac/pt-br/assuntos/regulados/empresas-aereas/",
    "Instrucoes-para-a-elaboracao-e-apresentacao-das-demonstracoes-contabeis/",
    "envio-de-informacoes"
  )

  req <- httr2::request(url) |>
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
    httr2::req_perform()
  resp <- try(req, silent = TRUE)

  if (inherits(resp, "try-error")) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  h <- httr2::resp_body_html(resp)

  rows <- rvest::html_elements(h, "tbody tr")
  rows <- rows[-1]

  files <- lapply(rows, function(row) {

    cells <- row |>
      rvest::html_elements("td")

    if (length(cells) < 5L) {
      return(NULL)
    }

    year <- cells[[1]] |>
      rvest::html_text2()

    month <- cells[[2]] |>
      rvest::html_text2()

    basica_url <- cells[[4]] |>
      rvest::html_element("a") |>
      rvest::html_attr("href")

    combinada_url <- cells[[5]] |>
      rvest::html_element("a") |>
      rvest::html_attr("href")

    date <- suppressWarnings(
      as.numeric(paste0(year, sprintf("%02d", as.numeric(month))))
    )

    tbl <- data.table::data.table(
      # year = rep(year, 2L),
      # month = rep(month, 2L),
      date = rep(date, 2L),
      type = c("basica", "combinada"),
      url = c(basica_url, combinada_url)
    )

    return(tbl)
  })

  files <- data.table::rbindlist(files, fill = TRUE)

  files <- files[
    !is.na(date) &
    !is.na(url) &
    nzchar(url)
  ]

  files <- unique(files)
  return(files)
} # nocov end


# get_flight_dates_available -----------------------------------------------------------------

#' Retrieve all dates available for flights data from ANAC website
#'
#' @param type String. Whether the data set should be of the type `basica`
#'             (flight stage, the default) or `combinada` (On flight origin and
#'             destination - OFOD).
#' @return Numeric vector.
#' @export
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # check dates
#' a <- get_flight_dates_available()
#'}}
get_flight_dates_available <- function(type = NULL) {
  # nocov start

  if (!is.null(type)) {
    requested_type <- match.arg(type, c("basica", "combinada"))
  } else {
    requested_type <- NULL
  }

  files <- get_flights_files_available()

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
#' @param file_url String. A url passed from \code{\link{get_flights_url}}.
#' @param showProgress Logical, passed from \code{\link{read_flights}}
#' @param select A vector of column names or numbers to keep, passed from \code{\link{read_flights}}
#' @param cache Logical, passed from \code{\link{read_flights}}
#'
#' @return A `"data.table" "data.frame"` object
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' file_url <- get_flights_url(type='basica', year=2000, month=11)
#'
#' # download data
#' a <- download_flights_data(file_url=file_url, showProgress=TRUE, select=NULL)
#'}}
download_flights_data <- function(file_url = parent.frame()$file_url,
                                  showProgress = parent.frame()$showProgress,
                                  select = parent.frame()$select,
                                  cache = parent.frame()$cache){ # nocov start

  # create temp local file
  file_name <- basename(file_url)
  temp_local_file <- fs::path(fs::path_temp(), file_name)

  # use cached files or not
  if (any(cache==FALSE & file.exists(temp_local_file))) {
    unlink(temp_local_file, recursive = T)
  }

  # has the file been downloaded already? If not, download it
  if (any(cache==FALSE |
          !file.exists(temp_local_file) |
          file.info(temp_local_file)$size == 0)) {

    # download data
    check_download <- download_flightsbr_file(
      file_url=file_url,
      showProgress=showProgress,
      dest_file = temp_local_file,
      cache = cache)

  # check if internet connection worked
  if (is.null(check_download)) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
    }
  }


  ### set threads for fread
  orig_threads <- data.table::getDTthreads()
  data.table::setDTthreads(percent = 100)

  ## unzip and fread
  unzip_and_fread <- function(single_temp_local_file,
                              showProgress = parent.frame()$showProgress,
                              select = parent.frame()$select){

    # single_temp_local_file = temp_local_file[1]

    # unzip file to tempdir
    temp_local_dir <- fs::path_temp()

    #  utils::unzip(zipfile = single_temp_local_file, exdir = temp_local_dir)
    archive::archive_extract(
      archive = single_temp_local_file,
      dir = temp_local_dir
      )


    # get file name
    file_name <- utils::unzip(single_temp_local_file, list = TRUE)$Name

    # read file stored locally
    temp_dt <- data.table::fread(fs::path(temp_local_dir, file_name),
                                 select = select,
                                 showProgress = showProgress,
                                 colClasses = 'character',
                                 sep = ';',
                                 encoding = 'Latin-1')
    return(temp_dt)
  }

  message('Unziping and reading data to memory.')
  if(isTRUE(showProgress)){
    dt <- pbapply::pblapply(X=temp_local_file, FUN=unzip_and_fread,
                            select = select,
                            showProgress = showProgress)
  } else {
    dt <- lapply(X=temp_local_file, FUN=unzip_and_fread,
                 select = select,
                 showProgress = showProgress)
  }


  # return to original threads
  data.table::setDTthreads(orig_threads)

  return(dt)

} # nocov end
