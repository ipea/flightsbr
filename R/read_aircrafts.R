#' Download aircrafts data from Brazil
#'
#' @description
#'`r lifecycle::badge("deprecated")`
#'
#' This function was deprecated in favor of `read_aircraft()` simply to
#' fix a typo in the function name.
#'
#' @template date
#' @template showProgress
#' @template cache
#'
#' @return A `"data.table" "data.frame"` object. All columns are returned with
#'         `class` of type `"character"`.
#' @export
#' @keywords internal
#' @family download flight data
#' @examples \dontrun{ if (interactive()) {
#' # Read aircraft data
#' aircraft <- read_aircraft(date = 202001,
#'                           showProgress = TRUE)
#'
#'}}
read_aircrafts <- function(date = 202001,
                           showProgress = TRUE,
                           cache = TRUE
                           ){


  lifecycle::deprecate_stop(
    when = "v1.0.1",
    what = "read_aircrafts()",
    with = "read_aircraft()"
    )
}
