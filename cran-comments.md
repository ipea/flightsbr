── R CMD check results ─────────────────────────────────────────────────────────── flightsbr 1.2.0 ────
Duration: 9m 21s

- Fixed URL
- Added claude files to .Rbuildignore

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

# flightsbr v1.2.0

* Minor changes:

  * When the package tries to download multiples but fails with a few ones, the package now only try to download again the files that failed in the first attempt.
  * The function `read_aircrafts()` now throws an error, as it has been deprecated in favor of `read_aircraft()` simply to fix a typo in the function name. The behavior and outputs are identical.
  * `read_airfares()` and `read_flights()` now cache the list of dates/files available from ANAC to a session-scoped temp file, governed by the existing `cache` parameter. This avoids re-scraping ANAC's website on every single call within the same R session.
  * Files are now downloaded using `httr2::req_perform_parallel()`, replacing `curl::multi_download()`.

* Bug fixes:

  * Fixed error in reading data from ANAC website. Fixed [#52](https://github.com/ipea/flightsbr/issues/52) and [#51](https://github.com/ipea/flightsbr/issues/51).
  * Fixed the `select` parameter in `read_airfares()`, which was silently ignored and had no effect on the columns returned. It now behaves the same way as `select` in `read_flights()`.
  * Fixed `get_airfares_dates_available()` (used internally by `read_airfares()`) to retry requests to ANAC that fail transiently (timeouts, connection errors, HTTP 429/503) instead of silently dropping the affected year and returning an incomplete list of available dates.
  * Fixed `get_airfares_dates_available()` and `latest_airfares_date()` to fail cleanly with `NULL` when ANAC can't be reached, instead of occasionally producing a nonsensical "data available between Inf and -Inf" error, or `-Inf` as a date.
  * Replaced a brittle hardcoded filename-length check (`nchar == 55`) used to filter valid international airfare files listed by ANAC with an explicit filename-pattern check, and added the equivalent check to the domestic airfare listing (which previously had no filter at all). This guards against malformed, duplicate, or misplaced files that ANAC occasionally publishes (e.g. typo'd names, files uploaded to the wrong year, re-uploads with `(1)` appended) corrupting the list of available dates.

* New contributors

  * Arthur Bazolli
