#' Manage the cache of files downloaded by flightsbr
#'
#' @description
#' flightsbr keeps the files it downloads from ANAC in a cache directory, so
#' that each file is downloaded only once, even across R sessions. This
#' function lists the cached files and deletes some or all of them.
#'
#' By default, the cache lives in `tools::R_user_dir("flightsbr", which =
#' "cache")`. You can use another folder with
#' `options(flightsbr.cache_dir = "path/to/folder")`.
#'
#' @param list_files Logical. Whether to print a message listing the files in
#'        the cache. Defaults to `TRUE`.
#' @param delete_file String. The name of a cached file to delete (for example
#'        `"basica2000-01.zip"`), or `"all"` to delete every cached file.
#'        Defaults to `NULL`, which deletes nothing.
#'
#' @return Invisibly, a character vector with the paths of the files left in
#'         the cache.
#'
#' @export
#' @family Cache data
#' @examples
#' # list the files in the cache
#' flightsbr_cache()
#'
#' \dontrun{ if (interactive()) {
#' # delete one file
#' flightsbr_cache(delete_file = "basica2000-01.zip")
#'
#' # delete all files
#' flightsbr_cache(delete_file = "all")
#'}}
flightsbr_cache <- function(list_files = TRUE,
                            delete_file = NULL) {

  # checks
  if (!is.logical(list_files) || length(list_files) != 1 || is.na(list_files)) {
    stop("Argument 'list_files' must be either 'TRUE' or 'FALSE'.")
  }
  if (!is.null(delete_file) && !is.character(delete_file)) {
    stop("Argument 'delete_file' must be a file name or \"all\".")
  }

  # don't create the cache directory just to list it
  cache_dir <- flightsbr_cache_dir(create = FALSE)

  list_cached <- function() {
    if (!dir.exists(cache_dir)) return(character(0))
    as.character(fs::dir_ls(cache_dir, type = "file"))
  }

  cached_files <- list_cached()

  # delete files
  if (!is.null(delete_file)) {

    if ("all" %in% delete_file) {
      to_delete <- cached_files
    } else {
      to_delete <- cached_files[basename(cached_files) %in% basename(delete_file)]

      not_found <- setdiff(basename(delete_file), basename(cached_files))
      if (length(not_found) > 0) {
        message("File(s) not found in the cache: ",
                paste(not_found, collapse = ", "))
      }
    }

    unlink(to_delete)
    if (length(to_delete) > 0) {
      message("Deleted ", length(to_delete), " file(s) from the cache.")
    }

    cached_files <- list_cached()
  }

  # list files
  if (isTRUE(list_files)) {
    if (length(cached_files) == 0) {
      message("The flightsbr cache is empty: ", cache_dir)
    } else {
      message("Files in the flightsbr cache (", cache_dir, "):\n",
              paste0("  ", basename(cached_files), collapse = "\n"))
    }
  }

  return(invisible(cached_files))
}
