context("cache")

# These tests are offline and fast, so they also run on CRAN.

# helper: a fresh, empty cache directory for one test
local_test_cache <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(pattern = "flightsbr_cache_", .local_envir = env)
  withr::local_options(list(flightsbr.cache_dir = dir), .local_envir = env)
  dir
}


# flightsbr_cache_dir -----------------------

test_that("flightsbr_cache_dir respects the option", {

  dir <- file.path(tempdir(), "flightsbr_opt_test")
  withr::local_options(list(flightsbr.cache_dir = dir))
  withr::defer(unlink(dir, recursive = TRUE))

  # doesn't create the folder when asked not to
  unlink(dir, recursive = TRUE)
  expect_equal(as.character(flightsbr_cache_dir(create = FALSE)), as.character(fs::path(dir)))
  expect_false(dir.exists(dir))

  # creates it by default
  flightsbr_cache_dir()
  expect_true(dir.exists(dir))
})


# flightsbr_cache -----------------------

test_that("flightsbr_cache lists and deletes files", {

  dir <- local_test_cache()

  # empty cache
  expect_message(out <- flightsbr_cache(), "empty")
  expect_length(out, 0)

  # a cache with files
  writeLines("x", file.path(dir, "a.csv"))
  writeLines("x", file.path(dir, "b.csv"))
  writeLines("x", file.path(dir, "c.zip"))

  expect_message(out <- flightsbr_cache(), "a.csv")
  expect_setequal(basename(out), c("a.csv", "b.csv", "c.zip"))
  expect_silent(flightsbr_cache(list_files = FALSE))

  # delete one file
  expect_message(
    out <- flightsbr_cache(list_files = FALSE, delete_file = "a.csv"),
    "Deleted 1"
  )
  expect_setequal(basename(out), c("b.csv", "c.zip"))
  expect_false(file.exists(file.path(dir, "a.csv")))

  # a file that isn't cached
  expect_message(
    flightsbr_cache(list_files = FALSE, delete_file = "nope.csv"),
    "not found"
  )

  # delete all
  out <- flightsbr_cache(list_files = FALSE, delete_file = "all")
  expect_length(out, 0)
  expect_length(list.files(dir), 0)
})

test_that("flightsbr_cache doesn't create a missing cache folder", {

  dir <- file.path(tempdir(), "flightsbr_never_created")
  unlink(dir, recursive = TRUE)
  withr::local_options(list(flightsbr.cache_dir = dir))

  expect_message(out <- flightsbr_cache(), "empty")
  expect_length(out, 0)
  expect_false(dir.exists(dir))
})

test_that("flightsbr_cache checks its inputs", {
  expect_error(flightsbr_cache(list_files = "banana"))
  expect_error(flightsbr_cache(list_files = NA))
  expect_error(flightsbr_cache(delete_file = 1))
})
