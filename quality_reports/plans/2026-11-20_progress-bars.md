# Plan: progress bars from httr2 (downloads) and cli (reading)

**Status:** APPROVED (v2, simplified after 3 adversarial reviews) · 2026-11-20 · branch `dev` (PR ipea/flightsbr#61, part of v1.3.0)

## Context

Downloads already show httr2's progress bar, which httr2 draws with cli. Reading the files uses `pbapply::pblapply()`, which has two problems:

- It has no `showProgress` argument. In `read_aircraft()`, `read_airfares()` and `read_airport_movements()` the reading bar ignores `showProgress = FALSE` in interactive sessions.
- Its bar counts files. A single month jumps straight from 0% to 100%.

For downloads, one file is the usual case, and httr2's per-file count bar then also goes 0 → 1 with nothing in between.

**Goal:**
- A single-file download shows a byte bar.
- Reading several files shows a cli bar.
- Every bar follows `showProgress`.
- pbapply is removed from Imports.

## Changes

### 1. Downloads: `download_flightsbr_file()` in `R/utils.R`

Inside the existing 2-pass loop, decide on each pass from `sum(todo)`, because `reqs` is rebuilt for every pass:

```r
reqs <- lapply(file_url[todo], anac_request)
single <- isTRUE(showProgress) && length(reqs) == 1
if (single) reqs[[1]] <- httr2::req_progress(reqs[[1]], type = "down")

responses <- httr2::req_perform_parallel(
  reqs, paths = part_file, on_error = "continue",
  progress = isTRUE(showProgress) && !single,   # count bar for 2+ files
  max_active = 4
)
```

- **One file left to download:** byte bar ("Downloading 45% ■■■ ETA 3s"). If ANAC sends no Content-Length, httr2 shows a spinner instead.
- **Two or more files:** httr2's existing count bar, unchanged. There is no custom format. A list `format` would need httr2 ≥ 1.2.0, and DESCRIPTION's floor is 1.1.1.
- `req_progress()` exists since httr2 1.0.0, so DESCRIPTION's floor doesn't change.

### 2. Reading: a new helper `lapply_progress()` in `R/utils.R`

```r
# lapply() with a cli progress bar over files. The bar is shown only for 2+
# files. FUN's own showProgress (fread's bar) is on only when there is one
# file, so the two bars never share a line. The lapply() must stay inside this
# function: cli_progress_along() closes its bar when the calling frame exits.
lapply_progress <- function(x, FUN, ..., .progress, .name = "Reading files") {
  many <- isTRUE(.progress) && length(x) > 1
  idx <- if (many) cli::cli_progress_along(x, name = .name) else seq_along(x)
  lapply(idx, function(i) {
    FUN(x[[i]], ..., showProgress = isTRUE(.progress) && !many)
  })
}
```

- **Argument names:** the helper's own arguments are `.progress` and `.name`. It passes `showProgress` to `FUN` explicitly, and call sites must not put `showProgress` in `...`. This fixes a review CRITICAL: otherwise `unzip_and_fread()`'s default `parent.frame()$showProgress` would evaluate to `NULL`, `fread()` would error, and the `tryCatch` would delete every cached file.
- **Call sites:** replace the 4 `pblapply()` calls with it. All 4 reading functions already take `showProgress`.
  - `R/utils_aircraft.R:106`: `lapply_progress(temp_local_file, read_aircraft_file, .progress = showProgress)`
  - `R/utils_airfares.R:244`: `lapply_progress(temp_local_file, read_airfare_file, .progress = showProgress)`
  - `R/utils_airport_movement.R:154`: `lapply_progress(temp_local_file, data.table::fread, colClasses = 'character', sep = ';', .progress = showProgress)`
  - `R/utils_flights.R:357-365`: `lapply_progress(temp_local_file, unzip_and_fread, select = select, .progress = showProgress, .name = "Unzipping and reading files")`. This removes the `if/else`.
- **"Unzipping" message:** in `read_flights()`, `cli_inform("Unzipping and reading data to memory.")` now prints only when `isTRUE(showProgress)`.

### 3. DESCRIPTION and NEWS

- Remove `pbapply` from Imports. Nothing else references it: not NAMESPACE, tests, vignettes or README.
- Add one NEWS bullet under Minor changes: "Progress bars now come from httr2 (downloads, with a byte bar when downloading a single file) and cli (reading several files). `showProgress = FALSE` now hides all of them, and pbapply is no longer a dependency."

### 4. Test (`tests/testthat/test_helpers_offline.R`)

Add one `test_that` block, using `f <- function(x, showProgress) list(x, showProgress)`:

- For `x` of length 0, 1 and 3, and both values of `.progress`, the result equals `lapply(x, f, showProgress = <expected>)`.
- `FUN` receives `showProgress = TRUE` only when there is 1 file and `.progress = TRUE`. This covers the fread rule.
- `expect_silent()` only with `.progress = FALSE`.

## Accepted behaviour notes

- **Non-interactive runs:** cli bars appear in Rscript and CI logs when a read takes more than 2 s (`cli.progress_show_after`). pbapply never drew in non-interactive sessions. httr2's download bar already behaves the cli way, so reading now matches it. Users can silence both with `showProgress = FALSE`.
- **`read_airports(type = "all")`** downloads 2 files one after the other, so it shows 2 byte bars.
- **Retries:** a retried request (`req_retry(max_tries = 3)`) restarts its byte bar.

## Verification

1. `grep -rn "pbapply\|pblapply" R/ DESCRIPTION` returns nothing.
2. `devtools::document()` leaves NAMESPACE unchanged.
3. Run `devtools::test()` offline, then with `NOT_CRAN=true`.
4. **Required manual check** in an interactive console, with `cache = FALSE`. One review noted that httr2 binds the byte bar to the `req_progress()` frame, so the bar has to be seen drawing.
   - `read_flights(date = 202401)` shows a byte bar.
   - `read_flights(date = 2023)` shows the count bar, then "Unzipping and reading files n/12".
   - `read_aircraft(date = 2025)` and `read_airfares(date = 2024)` show the reading bar.
   - Each of the above with `showProgress = FALSE` prints nothing.
   - If the byte bar doesn't draw, drop change 1 and keep `progress = showProgress`.
5. `R CMD check --as-cran`: 0 errors and 0 warnings.

## Review log (v1 → v2)

- **CRITICAL (accuracy):** the helper swallowed `showProgress`, so `unzip_and_fread()` would get `NULL` and delete every cached file. Fixed: the helper has its own `.progress` argument and passes `showProgress` to `FUN` explicitly.
- **MAJOR (accuracy):** with the same flaw, `fread` passed directly as `FUN` would default to `showProgress = interactive()`. Fixed by the same change.
- **MAJOR (simplicity):** the rule for turning off fread's bar was left to each call site. It now lives in the helper.
- **MAJOR (cli/CRAN):** a list `progress` format is ignored at httr2 1.1.1. The custom format was dropped and httr2's default count bar is kept.
- **MINOR (accepted):**
  - Choose the byte bar on each pass with `sum(todo)`.
  - cli bars print in non-interactive sessions. Noted, not gated.
  - No `expect_silent()` with progress on.
  - The manual byte-bar check is required.
  - Merge the 2 NEWS bullets into 1 and the tests into 1 block.
