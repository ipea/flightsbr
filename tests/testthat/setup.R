# Keep the flightsbr cache inside tempdir() while testing, so tests never
# write to the user's home directory (CRAN policy). Restored after all tests.
withr::local_options(
  list(flightsbr.cache_dir = file.path(tempdir(), "flightsbr_test_cache")),
  .local_envir = testthat::teardown_env()
)
