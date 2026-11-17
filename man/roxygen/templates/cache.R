#' @param cache Logical. Whether the function should read cached data downloaded
#'              previously. Defaults to `TRUE`. Downloaded files are cached
#'              in a folder that persists across R sessions (see
#'              [get_flightsbr_cache_dir()] and [set_flightsbr_cache_dir()]),
#'              and a cached file is downloaded again only if ANAC's copy has
#'              a different size. If `FALSE`, the function will always
#'              download the data and overwrite cached data. See
#'              [list_flightsbr_cache()] and [delete_flightsbr_cache()] to
#'              manage cached files.
