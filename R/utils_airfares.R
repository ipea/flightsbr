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
#' a <- get_airfares_dates_available(domestic = TRUE)
#'}}
get_airfares_dates_available <- function(dom, cache = TRUE) { # nocov start

  # this function makes ~1 HTTP request per year subdirectory on ANAC's
  # server (~25 requests). Cache the result to a session-scoped temp file
  # so repeated calls within the same R session (e.g. several read_airfares()
  # calls) don't repeatedly re-scrape the whole site
  cache_file <- fs::path(
    fs::path_temp(),
    paste0(
      "flightsbr_airfares_dates_",
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

  # base URL
  if (isTRUE(dom)) {
    base_url <- "https://sas.anac.gov.br/sas/tarifadomestica/"
  } else {
    base_url <- "https://sas.anac.gov.br/sas/tarifainternacional/"
  }

  # helper to read ANAC HTML pages. ANAC's server intermittently drops
  # individual requests when this function has to make many of them in a
  # row (one per year subdirectory below), so each request gets a timeout
  # and automatic retries for transient failures (both HTTP-level, e.g.
  # 429/503, and low-level connection failures/timeouts).
  read_anac_html <- function(url) {

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

    return(httr2::resp_body_html(resp))
  }

  # read main page
  h <- read_anac_html(base_url)

  if (is.null(h)) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  # get links
  href <- h |>
    rvest::html_elements("a") |>
    rvest::html_attr("href")

  # keep links to year subdirectories
  if (isTRUE(dom)) {
    basica_urls <- href[
      grepl("/tarifadomestica/2", href, fixed = TRUE)
    ]
  } else {
    basica_urls <- href[
      grepl("/tarifainternacional/2", href, fixed = TRUE)
    ]
  }

  # get years available
  years <- gsub(
    "[^\\d]+",
    "",
    basica_urls,
    perl = TRUE
  )

  # remove missing/empty values
  years <- years[
    !is.na(years) &
      nzchar(years)
  ]

  # get URLs of year subdirectories
  urls <- paste0(base_url, years)

  # search for CSV/TXT files inside each year. returns NULL (as opposed to
  # character(0)) when the request itself failed, so failures can be told
  # apart from a year subdirectory that legitimately has no files
  recursive_search <- function(url) {

    h <- read_anac_html(url)

    if (is.null(h)) {
      return(NULL)
    }

    href <- h |>
      rvest::html_elements("a") |>
      rvest::html_attr("href")

    files <- href[
      grepl(
        "\\.(csv|txt)$",
        href,
        ignore.case = TRUE
      )
    ]

    return(files)
  }

  # get URLs of CSV/TXT files, one request per year subdirectory
  csv_urls_by_year <- lapply(urls, recursive_search)

  # a handful of individual year requests can still fail even after the
  # retries in read_anac_html() -- track them instead of silently dropping
  # them, so we can tell "ANAC is down" apart from "this year has no data"
  failed_years <- sum(vapply(csv_urls_by_year, is.null, logical(1)))

  if (failed_years == length(urls)) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  if (failed_years > 0) {
    message(sprintf(
      paste0(
        "Could not reach %d of %d year(s) on the ANAC data server; the ",
        "list of available dates may be incomplete. Please try it again."
      ),
      failed_years, length(urls)
    ))
  }

  csv_urls <- unlist(csv_urls_by_year)

  # get all dates available
  if (isTRUE(dom)) {

    all_dates <- substr(
      csv_urls,
      nchar(csv_urls) - 9L,
      nchar(csv_urls) - 4L
    )

  } else {

    csv_urls <- csv_urls[
      nchar(csv_urls) == 55L
    ]

    all_dates <- substr(
      csv_urls,
      nchar(csv_urls) - 10L,
      nchar(csv_urls) - 4L
    )

    all_dates <- gsub(
      "-",
      "",
      all_dates,
      fixed = TRUE
    )
  }

  all_dates <- suppressWarnings(
    as.numeric(all_dates)
  )

  all_dates <- all_dates[
    !is.na(all_dates)
  ]

  # keep the contract strict: callers only need to check is.null() to
  # detect failure, never an empty-but-non-null vector
  if (length(all_dates) == 0) {
    message("Problem connecting to ANAC data server. Please try it again.")
    return(invisible(NULL))
  }

  saveRDS(all_dates, cache_file)

  return(all_dates)
} # nocov end


    # get_airfares_dates_available <- function(dom) { # nocov start
    #
    # # read html table
    # if( isTRUE(dom) ) { base_url = 'https://sas.anac.gov.br/sas/tarifadomestica/' }
    # if( isFALSE(dom)) { base_url = 'https://sas.anac.gov.br/sas/tarifainternacional/' }
    #
    # h <- try(rvest::read_html(base_url), silent = TRUE)
    #
    # # check if internet connection worked
    # if (class(h)[1]=='try-error') {
    #   message("Problem connecting to ANAC data server. Please try it again.")
    #   return(invisible(NULL))
    # }
    #
    # # filter elements of basica data
    # elements <- rvest::html_elements(h, "a")
    #
    # if( isTRUE(dom) ) {
    #   basica_urls <- elements[ data.table::like(elements, '/tarifadomestica/2') ]
    # }
    #
    # if( isFALSE(dom)) {
    #   basica_urls <- elements[ data.table::like(elements, '/tarifainternacional/2') ]
    # }
    #
    #
    # basica_urls <- lapply(X=basica_urls, FUN=function(i){rvest::html_attr(i,"href")})
    #
    # # get all dates available
    # years <- gsub("[^\\d]+", "", basica_urls, perl=TRUE)
    #
    # # get url of subdirectories
    # urls <- paste0(base_url, years)
    #
    # # function to search .csv data in subdirectories
    # recursive_search <- function(i){ # i=urls[21]
    #
    #   # read html table
    #   h2 <- try(rvest::read_html(i), silent = TRUE)
    #
    #   if (class(h2)[1]=='try-error') {
    #     message("Problem connecting to ANAC data server. Please try it again.")
    #     return(invisible(NULL))}
    #
    #   # get url of subdirectories
    #   elements2 <- rvest::html_elements(h2, "a")
    #   href2 <- rvest::html_attr(elements2, "href")
    #   # files_all <- grep("../", href2, fixed = TRUE, value = TRUE, invert = TRUE)
    #   files_csv <- href2[ data.table::like(href2, '.csv|.CSV|.txt')]
    #   # temp_urls <- paste0(i, files_csv)
    #   # return(temp_urls)
    #   return(files_csv)
    # }
    #
    # # get urls of .csv files
    # csv_urls <- lapply(X=urls, FUN=recursive_search)
    # csv_urls <- unlist(csv_urls)
    #
    # # get all dates available
    # options(warn=-1) # suppress warnings
    # if( isTRUE(dom) ) {
    #   all_dates <- substr(csv_urls , (nchar(csv_urls ) + 1) -10, nchar(csv_urls )-4 ) }
    #
    # if( isFALSE(dom)) {
    #   csv_urls <- csv_urls[ nchar(csv_urls)==55 ]
    #   all_dates <- substr(csv_urls , (nchar(csv_urls ) + 1) -11, nchar(csv_urls )-4 )
    #   all_dates <- gsub("[-]", "", all_dates)
    # }
    #
    # all_dates <- as.numeric(all_dates)
    # all_dates <- all_dates[ ! is.na(all_dates)]
    # options(warn=0) # unsuppress warnings
    #
    # return(all_dates)
    # } # nocov end
    #
    #

#' Put together the url of airfare data files
#'
#' @param dom Logical. Defaults to `TRUE` download airfares of domestic
#'                 flights. If `FALSE`, the function downloads airfares of
#'                 international flights.
#' @param date Numeric. Date of the data in the format `yyyymm`. To download the
#'             data for all months in a year, the user can pass a 4-digit year
#'             input `yyyy`. The parameter also accepts a vector of dates such as
#'             `c(202001, 202006, 202012)`.
#'
#' @return A url string.
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' a <- get_airfares_url(year=2002, month=11)
#'}}
get_airfares_url <- function(dom,
                             date = parent.frame()$date) { # nocov start

  # Domestic flights
  if( isTRUE(dom) ) {
    url_root = 'https://sas.anac.gov.br/sas/tarifadomestica/'

    # date with format yyyymm
    if (all(nchar(date)==6)) {
      years <- substring(date,1,4)
      months <- substring(date,5,6)
      file_urls <- paste0(url_root, years, '/', date, '.csv')
    }

    # date with format yyyy
    if (all(nchar(date)==4)) {
      all_dates <- generate_all_months(date)
      years <- substring(all_dates,1,4)
      months <- substring(all_dates,5,6)
      file_urls <- paste0(url_root, years, '/', all_dates, '.csv')
    }
  }


  # International flights
  if( isFALSE(dom)) {

    url_root = 'https://sas.anac.gov.br/sas/tarifainternacional/'

    # date with format yyyymm
    if (all(nchar(date)==6)) {
      years <- substring(date,1,4)
      months <- substring(date,5,6)
      file_urls <- paste0(url_root, years, '/Internacional_', years, '-', months, '.csv')
    }

    # date with format yyyy
    if (all(nchar(date)==4)) {
      all_dates <- generate_all_months(date)
      years <- substring(all_dates,1,4)
      months <- substring(all_dates,5,6)
      file_urls <- paste0(url_root, years, '/Internacional_', years, '-', months, '.csv')
    }

    # replace .csv with .txt for dates earlier than 2016
    fix_file_extension <- function(url){
      yyyy <- gsub(".*(199[0-9]|20[01][0-9]).*","\\1",url)[1] # detect year of reference
      if(yyyy < 2017) { url <- gsub('.csv', '.txt', url) }
      return(url)
    }

    file_urls <- lapply(X=file_urls, FUN=fix_file_extension)
    file_urls <- unlist(file_urls)
    }

  return(file_urls)
} # nocov end




#' Download and read ANAC air fares data
#'
#' @param file_urls String. A url passed from above.
#' @template showProgress
#' @template select
#' @template cache
#'
#' @return A `"data.table" "data.frame"` object
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' # Generate url
#' file_url <- get_airfares_url(dom = TRUE, date=200211)
#'
#' # download data
#' a <- download_airfares_data(file_urls=file_url, showProgress=TRUE, select=NULL)
#'}}
download_airfares_data <- function(file_urls = parent.frame()$file_urls,
                                   showProgress = parent.frame()$showProgress,
                                   select = parent.frame()$select,
                                   cache = parent.frame()$cache
                                   ){ # nocov start

  # create temp local file
  file_name <- basename(file_urls)
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
    check_download <- download_flightsbr_file(file_url=file_urls,
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

  # read files stored locally
  dt <- pbapply::pblapply(X=temp_local_file,
                          FUN = function(x){

                            # read
                            temp_x <- data.table::fread(x,
                                                        select = select,
                                                        showProgress = showProgress,
                                                        encoding = 'Latin-1',
                                                        colClasses = 'character',
                                                        sep = ';')
                            })

            # # isso aqui funciona
            # dt <- duckplyr::read_csv_duckdb(
            #   path = temp_local_file,
            #   options = list(
            #     delim = ";",
            #     # types = list("VARCHAR"),
            #     all_varchar = TRUE,
            #     encoding = 'UTF-8'
            #     , skip = 1
            #   )
            # )

  dt <- data.table::rbindlist(dt, fill = TRUE)

  # return to original threads
  data.table::setDTthreads(orig_threads)

  return(dt)
} # nocov end


