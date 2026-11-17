context("cache")

# These tests are offline and fast, so they also run on CRAN.

# helper: fresh, empty user cache and config folders for one test
local_test_user_dirs <- function(env = parent.frame()) {
  root <- withr::local_tempdir(pattern = "flightsbr_user_", .local_envir = env)
  withr::local_envvar(
    c(R_USER_CACHE_DIR = file.path(root, "cache"),
      R_USER_CONFIG_DIR = file.path(root, "config")),
    .local_envir = env
  )
  root
}

norm <- function(x) as.character(fs::path_norm(x))


# set / get -----------------------

test_that("get_flightsbr_cache_dir returns the default without creating it", {

  local_test_user_dirs()

  dir <- get_flightsbr_cache_dir()
  expect_type(dir, "character")
  expect_equal(norm(dir), norm(tools::R_user_dir("flightsbr", which = "cache")))
  expect_false(dir.exists(dir))
  expect_false(file.exists(cache_config_file()))
})

test_that("set_flightsbr_cache_dir saves the folder and NULL resets it", {

  root <- local_test_user_dirs()
  custom <- file.path(root, "my_cache")

  expect_message(out <- set_flightsbr_cache_dir(custom), "my_cache")
  expect_equal(norm(out), norm(custom))
  expect_equal(norm(get_flightsbr_cache_dir()), norm(custom))

  # saved in the config file, so it persists across sessions
  expect_true(file.exists(cache_config_file()))
  expect_equal(norm(readLines(cache_config_file())), norm(custom))

  # the download code uses it
  expect_equal(norm(flightsbr_cache_dir(create = FALSE)), norm(custom))

  # NULL goes back to the default and removes the config file
  expect_silent(out <- set_flightsbr_cache_dir(NULL, verbose = FALSE))
  expect_equal(norm(out), norm(tools::R_user_dir("flightsbr", which = "cache")))
  expect_equal(norm(get_flightsbr_cache_dir()), norm(out))
  expect_false(file.exists(cache_config_file()))
})

test_that("an empty config file falls back to the default", {

  local_test_user_dirs()
  fs::dir_create(dirname(cache_config_file()))
  writeLines("", cache_config_file())

  expect_equal(norm(get_flightsbr_cache_dir()),
               norm(tools::R_user_dir("flightsbr", which = "cache")))
})

test_that("set_flightsbr_cache_dir checks its inputs", {

  local_test_user_dirs()

  expect_error(set_flightsbr_cache_dir(1))
  expect_error(set_flightsbr_cache_dir(c("a", "b")))
  expect_error(set_flightsbr_cache_dir(NA_character_))
  expect_error(set_flightsbr_cache_dir(""))
  expect_error(set_flightsbr_cache_dir(tempdir(), verbose = "banana"))
  expect_false(file.exists(cache_config_file()))
})


# list -----------------------

test_that("list_flightsbr_cache lists files without creating the folder", {

  root <- local_test_user_dirs()
  dir <- file.path(root, "my_cache")
  set_flightsbr_cache_dir(dir, verbose = FALSE)

  # missing folder
  expect_message(out <- list_flightsbr_cache(), "empty")
  expect_equal(out, character(0))
  expect_false(dir.exists(dir))

  # with files
  dir.create(dir)
  writeLines("x", file.path(dir, "a.csv"))
  writeLines("x", file.path(dir, "b.zip"))

  out <- list_flightsbr_cache()
  expect_setequal(basename(out), c("a.csv", "b.zip"))

  # as a tree: printed, paths returned invisibly
  expect_output(out_tree <- list_flightsbr_cache(print_tree = TRUE), "a.csv")
  expect_setequal(basename(out_tree), c("a.csv", "b.zip"))

  expect_error(list_flightsbr_cache(print_tree = NA))
})


# delete -----------------------

test_that("delete_flightsbr_cache deletes one file, unknown files, and all", {

  root <- local_test_user_dirs()
  dir <- file.path(root, "my_cache")
  set_flightsbr_cache_dir(dir, verbose = FALSE)
  dir.create(dir)
  for (f in c("a.csv", "b.csv", "c.zip")) writeLines("x", file.path(dir, f))

  # one file
  expect_message(delete_flightsbr_cache("a.csv"), "Deleted 1")
  expect_setequal(list.files(dir), c("b.csv", "c.zip"))

  # unknown file
  expect_message(delete_flightsbr_cache("nope.csv"), "not found")
  expect_setequal(list.files(dir), c("b.csv", "c.zip"))

  # everything: the folder is removed once empty
  expect_message(out <- delete_flightsbr_cache(), "Deleted 2")
  expect_equal(norm(out), norm(dir))
  expect_false(dir.exists(dir))

  # nothing cached: no error
  expect_message(delete_flightsbr_cache(), "Deleted 0")
})

test_that("delete_flightsbr_cache never deletes subfolders", {

  root <- local_test_user_dirs()
  dir <- file.path(root, "shared_folder")
  set_flightsbr_cache_dir(dir, verbose = FALSE)

  dir.create(file.path(dir, "my_project"), recursive = TRUE)
  writeLines("x", file.path(dir, "basica2000-01.zip"))
  writeLines("keep me", file.path(dir, "my_project", "notes.txt"))

  delete_flightsbr_cache(verbose = FALSE)

  expect_false(file.exists(file.path(dir, "basica2000-01.zip")))
  expect_true(file.exists(file.path(dir, "my_project", "notes.txt")))
  expect_true(dir.exists(dir))
})

test_that("delete_flightsbr_cache checks its inputs", {
  local_test_user_dirs()
  expect_error(delete_flightsbr_cache(1))
  expect_error(delete_flightsbr_cache(NA_character_))
  expect_error(delete_flightsbr_cache(verbose = NA))
})
