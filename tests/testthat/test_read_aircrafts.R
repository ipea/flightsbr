context("read_aircrafts")

# skip tests because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()


# ERRORS and messages  -----------------------

testthat::test_that("read_aircrafts", {

  testthat::expect_error(
    read_aircrafts(showProgress = FALSE)
    )

  testthat::expect_error(
    read_aircrafts(showProgress = TRUE)
    )

  testthat::expect_error(
    read_aircrafts(date = c(202001, 202005))
  )

})


# ERRORS and messages  -----------------------
testthat::test_that("read_aircrafts", {

  # Wrong date 4 digits
  testthat::expect_error(read_aircrafts(date=1990))
  testthat::expect_error(read_aircrafts(date=9999))

  # Wrong date 6 digits
  testthat::expect_error(read_aircrafts(date=199001))
  testthat::expect_error(read_aircrafts(date=999901))

  # mixed date format
  testthat::expect_error(read_aircrafts(date=c(2020, 202101)))

  testthat::expect_error(read_aircrafts(showProgress='banana'))
  testthat::expect_error(read_aircrafts(showProgress=NULL))
  testthat::expect_error(read_aircrafts(showProgress=3))
  testthat::expect_error(read_aircrafts(a=NULL))

  testthat::expect_error(read_aircrafts(cache='banana'))
  testthat::expect_error(read_aircrafts(cache=NULL))
  testthat::expect_error(read_aircrafts(cache=3))

})

