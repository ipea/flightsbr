# Internal helpers ---------------------------------------------------------------

#' Default flightsbr cache directory
#'
#' @return The path to the default cache directory,
#'         `tools::R_user_dir("flightsbr", which = "cache")`.
#' @keywords internal
default_cache_dir <- function() {
  fs::path(tools::R_user_dir("flightsbr", which = "cache"))
}

#' Config file that stores a custom cache directory
#'
#' @return The path to the config file. The file may not exist.
#' @keywords internal
cache_config_file <- function() {
  fs::path(tools::R_user_dir("flightsbr", which = "config"), "cache_dir")
}

#' Check that a single argument is `TRUE` or `FALSE`
#'
#' @param x The value to check.
#' @param name String. The argument name, used in the error message.
#' @return `TRUE` invisibly, or an error.
#' @keywords internal
check_flag <- function(x, name) {
  if (!isTRUE(x) && !isFALSE(x)) {
    # name the user-facing function that called check_flag() in the error
    cli::cli_abort("{.arg {name}} must be {.code TRUE} or {.code FALSE}.",
                   call = rlang::caller_env())
  }
  invisible(TRUE)
}



# set_flightsbr_cache_dir --------------------------------------------------------

#' Set the folder where flightsbr caches downloaded data
#'
#' @description
#' flightsbr saves the files it downloads from ANAC in a cache folder, so that
#' each file is downloaded only once, even across R sessions. This function
#' sets which folder is used. The choice is saved and persists across R
#' sessions.
#'
#' Files already cached in the previous folder are not moved. They stay where
#' they are until you delete them, for example with [delete_flightsbr_cache()]
#' before changing the folder.
#'
#' @param path String. The path to the folder used to cache downloaded data.
#'        If `NULL` (the default), flightsbr goes back to its default folder,
#'        `tools::R_user_dir("flightsbr", which = "cache")`.
#' @param verbose Logical. Whether to print a message with the cache folder.
#'        Defaults to `TRUE`.
#'
#' @return Invisibly, the path to the cache folder.
#'
#' @export
#' @family Cache data
#' @examplesIf interactive()
#' # use a custom folder
#' set_flightsbr_cache_dir(tempdir())
#'
#' # go back to the default folder
#' set_flightsbr_cache_dir(NULL)
set_flightsbr_cache_dir <- function(path = NULL, verbose = TRUE) {

  # checks
  if (!is.null(path) &&
      (!is.character(path) || length(path) != 1 || is.na(path) || !nzchar(path))) {
    cli::cli_abort("{.arg path} must be a single folder path or {.code NULL}.")
  }
  check_flag(verbose, "verbose")

  config_file <- cache_config_file()

  if (is.null(path)) {
    # without a config file, flightsbr uses its default folder
    unlink(config_file)
    cache_dir <- default_cache_dir()
  } else {
    cache_dir <- fs::path_norm(fs::path_expand(path))
    fs::dir_create(fs::path_dir(config_file))
    writeLines(as.character(cache_dir), con = config_file)
  }

  cache_dir <- as.character(cache_dir)

  if (isTRUE(verbose)) {
    cli::cli_inform("flightsbr cache folder set to: {.file {cache_dir}}")
  }

  return(invisible(cache_dir))
}



# get_flightsbr_cache_dir --------------------------------------------------------

#' Get the folder where flightsbr caches downloaded data
#'
#' Returns the folder used to cache data downloaded by flightsbr: the folder
#' set with [set_flightsbr_cache_dir()], possibly in a previous R session, or
#' the default folder, `tools::R_user_dir("flightsbr", which = "cache")`.
#'
#' @return String. The path to the cache folder. The folder may not exist yet
#'         if no data has been downloaded.
#'
#' @export
#' @family Cache data
#' @examples
#' get_flightsbr_cache_dir()
get_flightsbr_cache_dir <- function() {

  config_file <- cache_config_file()

  cache_dir <- NULL
  if (file.exists(config_file)) {
    saved <- readLines(config_file, warn = FALSE)
    saved <- trimws(saved[nzchar(trimws(saved))])
    if (length(saved) > 0) cache_dir <- fs::path_norm(saved[1])
  }

  if (is.null(cache_dir)) {
    cache_dir <- default_cache_dir()
  }

  return(as.character(cache_dir))
}



# list_flightsbr_cache -----------------------------------------------------------

#' List the data cached by flightsbr
#'
#' Lists the files saved in the flightsbr cache folder (see
#' [get_flightsbr_cache_dir()]).
#'
#' @param print_tree Logical. Whether to print the content of the cache folder
#'        as a tree. Defaults to `FALSE`.
#'
#' @return A character vector with the paths of the cached files (invisibly
#'         when `print_tree = TRUE`). An empty vector if nothing is cached.
#'
#' @export
#' @family Cache data
#' @examples
#' list_flightsbr_cache()
#'
#' list_flightsbr_cache(print_tree = TRUE)
list_flightsbr_cache <- function(print_tree = FALSE) {

  check_flag(print_tree, "print_tree")

  cache_dir <- get_flightsbr_cache_dir()

  cached_files <- character(0)
  if (dir.exists(cache_dir)) {
    cached_files <- as.character(
      fs::dir_ls(cache_dir, type = "file", recurse = TRUE)
    )
  }

  if (length(cached_files) == 0) {
    cli::cli_inform("The flightsbr cache is empty: {.file {cache_dir}}")
    return(cached_files)
  }

  if (isTRUE(print_tree)) {
    fs::dir_tree(cache_dir)
    return(invisible(cached_files))
  }

  return(cached_files)
}



# delete_flightsbr_cache ---------------------------------------------------------

#' Delete data cached by flightsbr
#'
#' Deletes files from the flightsbr cache folder (see
#' [get_flightsbr_cache_dir()]): all cached files, or only the ones named in
#' `file`.
#'
#' Only files saved directly in the cache folder are deleted. Subfolders and
#' their content are never touched, so pointing the cache at a folder that
#' also holds other things (see [set_flightsbr_cache_dir()]) can't wipe them
#' out. The cache folder itself is removed if it ends up empty.
#'
#' @param file String. Names of cached files to delete, for example
#'        `"basica2000-01.zip"` (see [list_flightsbr_cache()]). If `NULL` (the
#'        default), all cached files are deleted.
#' @param verbose Logical. Whether to print a message saying what was deleted.
#'        Defaults to `TRUE`.
#'
#' @return Invisibly, the path to the cache folder.
#'
#' @export
#' @family Cache data
#' @examplesIf interactive()
#' # delete one file
#' delete_flightsbr_cache("basica2000-01.zip")
#'
#' # delete all cached files
#' delete_flightsbr_cache()
delete_flightsbr_cache <- function(file = NULL, verbose = TRUE) {

  # checks
  if (!is.null(file) && (!is.character(file) || anyNA(file))) {
    cli::cli_abort("{.arg file} must be a character vector of file names or {.code NULL}.")
  }
  check_flag(verbose, "verbose")

  cache_dir <- get_flightsbr_cache_dir()

  cached_files <- character(0)
  if (dir.exists(cache_dir)) {
    cached_files <- as.character(fs::dir_ls(cache_dir, type = "file"))
  }

  if (is.null(file)) {
    to_delete <- cached_files
  } else {
    to_delete <- cached_files[basename(cached_files) %in% basename(file)]

    not_found <- setdiff(basename(file), basename(cached_files))
    if (length(not_found) > 0 && isTRUE(verbose)) {
      cli::cli_inform("File{?s} not found in the flightsbr cache: {.file {not_found}}")
    }
  }

  unlink(to_delete)

  # remove the folder if nothing is left in it
  if (dir.exists(cache_dir) &&
      length(fs::dir_ls(cache_dir, all = TRUE)) == 0) {
    fs::dir_delete(cache_dir)
  }

  if (isTRUE(verbose)) {
    n_deleted <- length(to_delete)
    cli::cli_inform("Deleted {n_deleted} file{?s} from the flightsbr cache: {.file {cache_dir}}")
  }

  return(invisible(cache_dir))
}
