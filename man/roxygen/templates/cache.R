#' @param cache Logical. Whether the function should read cached data downloaded
#'              previously. Defaults to `TRUE`. Downloaded files are cached
#'              in `tools::R_user_dir("flightsbr", which = "cache")`, so they
#'              persist across R sessions, and a cached file is downloaded
#'              again only if ANAC's copy has a different size. If `FALSE`,
#'              the function will always download the data and overwrite
#'              cached data. See [flightsbr_cache()] to list or delete cached
#'              files.
