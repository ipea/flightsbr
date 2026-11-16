context("read_airport_movements")

# skip tests because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()


# Reading the data -----------------------
testthat::test_that("read_airport_movements", {

  # (default), one month, basica, progress
  test1 <- read_airport_movements()
  testthat::expect_true(is(test1, "data.table"))
  testthat::expect_true(nrow(test1) >0 )

  # all months in a year
  test2 <- read_airport_movements(date=202401, showProgress = FALSE)
  testthat::expect_true(is(test2, "data.table"))

  # test vector of dates
  test3 <- read_airport_movements(date = c(202401, 202405), showProgress = FALSE)
  testthat::expect_true(is(test3, "data.table"))


  # check whether cache argument is working
  time_first <- system.time(
    f1 <- read_airport_movements(date = 202401))

  time_cache_true <- system.time(
    f2 <- read_airport_movements(date = 202401, cache = TRUE))

  time_cache_false <- system.time(
    f3 <- read_airport_movements(date = 202401, cache = FALSE))

  testthat::expect_true( time_cache_true[['elapsed']] < time_cache_false[['elapsed']] )
 })


# Download once -----------------------
testthat::test_that("cached files are not downloaded again", {

  withr::local_options(list(flightsbr.cache_dir = withr::local_tempdir()))
  cached_file <- file.path(getOption("flightsbr.cache_dir"),
                           "Movimentacoes_Aeroportuarias_202401.csv")

  # first call downloads the file
  f1 <- read_airport_movements(date = 202401, showProgress = FALSE)
  testthat::expect_true(file.exists(cached_file))
  mtime_first <- file.mtime(cached_file)

  # second call reuses it: the file isn't rewritten
  Sys.sleep(1.1)
  testthat::expect_message(
    f2 <- read_airport_movements(date = 202401, showProgress = TRUE),
    "Using 1 cached file"
  )
  testthat::expect_equal(file.mtime(cached_file), mtime_first)
  testthat::expect_equal(nrow(f1), nrow(f2))

  # a broken cached file is replaced
  writeLines("broken", cached_file)
  f3 <- read_airport_movements(date = 202401, showProgress = FALSE)
  testthat::expect_equal(nrow(f3), nrow(f1))

  # cache = FALSE downloads again
  Sys.sleep(1.1)
  mtime_before <- file.mtime(cached_file)
  f4 <- read_airport_movements(date = 202401, showProgress = FALSE, cache = FALSE)
  testthat::expect_true(file.mtime(cached_file) > mtime_before)

  # no .part files are left behind
  testthat::expect_length(
    list.files(getOption("flightsbr.cache_dir"), pattern = "\\.part$"), 0
  )
})


# ERRORS and messages  -----------------------
testthat::test_that("read_airport_movements", {

  # Wrong date 4 digits
  testthat::expect_error(read_airport_movements(date=1990))
  testthat::expect_error(read_airport_movements(date=199012))
  testthat::expect_error(read_airport_movements(date=123456))

  # mixed date format
  testthat::expect_error(read_airport_movements(date=c(2020, 202101)))

  # Wrong type and showProgress and cache
  testthat::expect_error(read_airport_movements(showProgress='banana'))
  testthat::expect_error(read_airport_movements(cache='banana'))

})

# # mock test
# testthat::test_that("internet problem: throws informative message", {
#
#   testthat::local_mocked_bindings(
#     download_flightsbr_file = function(...) NULL
#   )
#
#   testthat::expect_message( read_airport_movements() )
#   testthat::expect_null( read_airport_movements() )
# })
