# Keep flightsbr's cache and config inside tempdir() while testing, so tests
# never touch the user's real cache folder or saved settings (CRAN policy).
# tools::R_user_dir() honours these environment variables. Restored after all
# tests.
withr::local_envvar(
  c(
    R_USER_CACHE_DIR = file.path(tempdir(), "flightsbr_test_user", "cache"),
    R_USER_CONFIG_DIR = file.path(tempdir(), "flightsbr_test_user", "config")
  ),
  .local_envir = testthat::teardown_env()
)
