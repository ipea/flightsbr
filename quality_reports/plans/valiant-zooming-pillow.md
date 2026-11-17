# Plan: download-once cache for flightsbr

**Status:** COMPLETED · 2026-11-15 · branch `claude/flightsbr-download-once-4c8815`

## Context

The goal is to copy censobr's `download_file_censobr()` idea: never download a file twice. flightsbr already checks for files on disk, but the check has four problems:

1. **All or nothing.** Every caller runs `any(cache==FALSE | !file.exists(f) | size==0)` and then sends *every* URL to `download_flightsbr_file()`. If one of 12 monthly zips is missing, all 12 are downloaded again.
2. **Partial files count as cached.** httr2 writes straight to the final path. A download that is cut off leaves a broken zip with size > 0, and the next call reuses it and fails in `archive_extract`.
3. **The cache lasts one session.** Files go to `fs::path_temp()` and disappear when R restarts.
4. **The same code is copied 6 times** (flights, aircraft, airfares, airport movements, airports public and private). Also, `download_flightsbr_file()` overwrites its own `dest_file` argument.

What the ANAC servers actually send, from HEAD checks on 2026-11-15:

| Source | Content-Length | Last-Modified | ETag |
|---|---|---|---|
| `sistemas.anac.gov.br` CSVs (movements, airports, RAB) | yes | yes, but **rewritten daily** (a 2021 file shows 2026-11-01; airports shows today) | nginx (mtime-size) |
| `www.gov.br` flight zips | yes | **no** | weak |
| `sas.anac.gov.br` airfares | yes | no | no |

So censobr's size + mtime test would re-download almost every CSV every day. **Decision (user): compare remote `Content-Length` only.**
**Decision (user): store the cache in `tools::R_user_dir("flightsbr", "cache")` so files survive restarts.**

## Approach

### 1. New internal helpers in `R/utils.R`

- `flightsbr_cache_dir()` returns `getOption("flightsbr.cache_dir", tools::R_user_dir("flightsbr", "cache"))` and creates the folder (`fs::dir_create`). The option lets tests, CRAN checks and users send the cache somewhere else.
- `is_valid_local_file(path)` returns TRUE if the file exists and has size > 0. For `.zip` files it also requires `tryCatch(nrow(utils::unzip(path, list = TRUE)) > 0, error = \(e) FALSE)` to succeed.
- `remote_sizes(urls, timeout)` sends parallel HEAD requests through `httr2::req_perform_parallel(on_error = "continue")`, using the same user-agent and headers as now. It returns a numeric vector of `Content-Length` values, with `NA` where the request failed or the header is missing.

### 2. Rewrite `download_flightsbr_file(file_url, showProgress, cache)` in `R/utils.R`

It returns the local paths (one per URL, in the same order) or `NULL` if a download failed.

1. Set `dest <- fs::path(flightsbr_cache_dir(), basename(file_url))`. Basenames are unique across sources: `basica2000-01.zip`, `202301.csv`, `Internacional_2023-01.csv`, `2023-01.csv`, `Movimentacoes_Aeroportuarias_*.csv`, `Aerodromos*.csv`.
2. If `cache = FALSE`, delete the existing files and download everything.
3. If `cache = TRUE`:
   - Mark files that are not `is_valid_local_file()` for download.
   - Send HEAD requests only for the valid local files. Re-download a file only if its remote size is known and differs from the local size.
   - If the HEAD request fails or has no Content-Length, **keep the local file**. That way an offline user or a flaky server still gets the cached copy. This is the opposite of censobr's "safer to redownload".
4. Download only the files that need it. Write each one to `paste0(dest, ".part")`, then `file.rename()` it to `dest` once it succeeds. A file that was cut off never reaches the final name.
5. Keep the existing single retry, adding a short `Sys.sleep()` backoff, and delete leftover `.part` files after each failed attempt.
6. When `showProgress` is on, print a message like "Using N cached file(s); downloading M."
7. Remove the unused `dest_file` argument and update the roxygen block.

### 3. Simplify the 6 callers

Replace each ~20-line "use cached files / has the file been downloaded" block with:

```r
local_file <- download_flightsbr_file(file_url, showProgress = showProgress, cache = cache)
if (is.null(local_file)) {
  message("Problem connecting to ANAC data server. Please try it again.")
  return(invisible(NULL))
}
```

Then read from `local_file`.

Files: `R/utils_flights.R` (`download_flights_data`), `R/utils_aircraft.R`, `R/utils_airfares.R` (`download_airfares_data`), `R/utils_airport_movement.R`, `R/read_airports.R` (2 blocks).

### 4. Avoid re-extracting zips (`R/utils_flights.R`, `unzip_and_fread`)

- Extract into the session `fs::path_temp()`. Don't keep the large CSVs in the persistent cache.
- Skip `archive::archive_extract()` if the CSV is already extracted and its size matches the `Length` from `utils::unzip(list = TRUE)`.
- Call `unzip(list = TRUE)` once instead of twice.

### 5. Keep the page scrapes session-scoped

The scrape caches (`flightsbr_flights_files.rds`, the airfares dates `.rds`) stay in `fs::path_temp()` on purpose. The list of available dates has to refresh in each new session.

### 6. New exported function `flightsbr_cache()` (new file `R/flightsbr_cache.R`)

Its API mirrors `censobr_cache()`: `flightsbr_cache(list_files = TRUE, delete_file = NULL)`.

- It lists the cached files.
- `delete_file = "all"` empties the cache. A basename deletes that one file.
- It returns the file paths invisibly, and its examples are runnable.

Also update the `@template cache` text in `man/roxygen/templates/cache.R` to say where the cache lives and that it persists across sessions. Add the function to `pkgdown/_pkgdown.yml`, add a NEWS entry, and run `devtools::document()`.

## CRAN safety

- Tests, examples and vignettes must not write to the user's home folder. Add `tests/testthat/setup.R` with `options(flightsbr.cache_dir = tempdir())` and a `withr`-free reset at the end.
- In each vignette's setup chunk, set the same option if the vignette runs code. Check `vignettes/*.Rmd` for `eval=` first.
- `tools::R_user_dir` needs R >= 4.0, and the package already requires `Depends: R (>= 4.1.0)`. `tools` is base R, so `DESCRIPTION` doesn't change.

## Tests (`tests/testthat/`)

- `test_utils.R` (offline):
  - `is_valid_local_file()` returns TRUE for a real zip and FALSE for an empty file, a truncated zip, or a missing path.
  - `flightsbr_cache_dir()` respects the option.
- `test_flightsbr_cache.R` (new):
  - Listing an empty or filled temp cache.
  - Deleting one file and deleting all.
- Network test, marked `skip_on_cran()`:
  - Call `read_airport_movements(202112)` twice and check that the second call makes no GET. Do this by comparing the file's mtime before and after, or with an `expect_message("Using 1 cached")`.
  - Call `read_flights(200001)` with `cache = FALSE` and check that the file is downloaded again.

## Verification

1. `devtools::document()`, then `devtools::test()`.
2. Manual check in a fresh R session:
   - Run `read_flights(2000)` (12 zips).
   - Delete one zip from `flightsbr_cache()`.
   - Run it again. Only 1 file should download.
   - Restart R and run it again. Nothing should download.
3. Cut a download off partway (Ctrl+C). Confirm that only a `.part` file is left and that the next call downloads the file again.
4. Disconnect from the network and call the function again. It should serve the cached files without an error.
5. Run `/r-package-check` (`devtools::check(args = "--as-cran")`). The bar is 0 errors, 0 warnings, and no new NOTE.
