# Plan: all errors, warnings and messages through {cli}

**Status:** COMPLETED (v2, simplified after 3 adversarial reviews; approved for v1.3.0) · 2026-11-19 · new branch from `origin/main` (7d2d4be)


## Goal

Every error, warning and message that flightsbr raises goes through `cli::cli_abort()`, `cli::cli_warn()` or `cli::cli_inform()`. Nothing else is in scope.

## What's there today

- `R/` has 49 calls in 11 files: 25 `stop()`, 2 `warning()` and 22 `message()`. There are no `cat()` or `print()` calls.
- `read_airports(type=)` and `read_flights(type=)` raise base-R errors: `read_airports()` through `stop()`, `read_flights()` through `match.arg()`.
- The same `is.logical()` check for `showProgress` and `cache` is copy-pasted 11 times, and 8 of the copies have a broken quote (`'TRUE' or 'FALSE.`). An `is.logical()` check accepts `NA` and `c(TRUE, FALSE)`. `R/cache.R` already has a stricter `check_flag()`.
- Errors raised inside internal helpers (`check_date()`, `check_input_date_format()`, `generate_all_months()`, ...) name that helper (e.g. `Error in check_date(...)`), not the `read_*()` function the user called.
- **Cost:** none for users. httr2, lifecycle and rvest already import both cli (3.6.6) and rlang (1.3.0).


## The four rules

1. **Call cli directly at each site.** No wrapper functions and no condition classes. Both were dropped as scope creep, and the wrapper sketch in v1 was broken: it didn't forward `message` or `.envir`.
2. **Never paste data into a cli template.** cli runs `{...}` as R code. If an ANAC column name, file name, cell value or user path is pasted into the template with `paste0()` or `sprintf()`, three things can happen: the code runs, the text is silently changed (`{2024}` becomes `2024`), or a parse error aborts the whole `read_*()` call. External text may only enter through a substitution: `{x}`, `{.val {x}}`, `{.file {path}}` or `{.field {cols}}`. This is the most important rule in the plan.
3. **Name the user's function in errors.** In helpers that `read_*()` calls directly (`check_flag()`, `check_date()`, `check_input_date_format()`), use `call = rlang::caller_env()` inside `cli_abort()`. Their signatures stay the same, so no exported function or Rd page changes. For data-layout errors raised deep in the read pipeline (`harmonize_airfare_names()`, `latlon_to_numeric()`, `altitude_to_numeric()`), use `call = NULL`.
4. **Keep the behaviour, change only the format.** Connection failures stay as messages that return `NULL` invisibly, because CRAN requires packages to fail gracefully when internet resources are down. No new gating on `showProgress`. The "Unziping" typo is fixed because that line is being rewritten anyway.


## Changes

### `DESCRIPTION`
- Add `cli` and `rlang` to `Imports`. rlang is required because `cli_abort()`, `cli_warn()` and `cli_inform()` call rlang at runtime, while cli lists rlang only under Suggests. The `rlang::caller_env()` and `rlang::arg_match()` calls also avoid the "Namespace in Imports field not imported from" NOTE.

### Argument checks (the only helper)
Rewrite the existing `check_flag(x, name)` in `R/cache.R`, keeping the same signature:

```r
check_flag <- function(x, name) {
  if (!isTRUE(x) && !isFALSE(x)) {
    cli::cli_abort("{.arg {name}} must be {.code TRUE} or {.code FALSE}.",
                   call = rlang::caller_env())
  }
  invisible(TRUE)
}
#> Error in `read_flights()`:
#> ! `showProgress` must be `TRUE` or `FALSE`.
```

- Replace the 11 copy-pasted checks in `read_aircraft()`, `read_airfares()`, `read_airport_movements()`, `read_airports()` and `read_flights()` with `check_flag(showProgress, "showProgress")`, and do the same for `cache`.
- For `type`, use `rlang::arg_match(type, c(...))` in `read_airports()` and `read_flights()`. That gives a cli error with a "Did you mean …?" hint.
  - Behaviour change: `read_flights()` no longer accepts partial matches like `type = "comb"`. This goes in NEWS.
  - The internal `match.arg()` in `get_flight_dates_available()` stays: it only sees values that `read_flights()` has already validated.
- The other one-off checks become inline `cli_abort()` calls: `domestic` and `select` in `read_airfares()`, `path` and `file` in `R/cache.R`, and `dest_file` length in `R/utils.R`.

### Everything else: one-to-one conversion

| File | Calls | Notes |
|---|---|---|
| `R/cache.R` | 3 stop, 4 message | `{.file {cache_dir}}`, `{n} file{?s}` |
| `R/read_airfares.R` | 1 warning | Unknown `select` columns as `{.val {select[...]}}` |
| `R/utils.R` | 8 stop, 5 message | `check_date()` and `check_input_date_format()` use `call = rlang::caller_env()`. `convert_to_numeric()` passes the vector, not a string built with `sprintf()` (rule 2). |
| `R/utils_aircraft.R` | 1 message, 1 warning | RAB layout warning, columns as `{.field {cols}}` |
| `R/utils_airfares.R` | 4 message, 1 stop | Unknown header: `{.file {file_name}}`, `{.field {cols}}`, `{.url https://github.com/ipea/flightsbr/issues}`, `call = NULL`. "Could not reach {n} of {m} year{?s}" no longer uses `sprintf()`. |
| `R/utils_airport_movement.R` | 3 message | Same partial-failure message |
| `R/utils_flights.R` | 5 message | File names as `{.file {...}}`, fix the "Unziping" typo |

The "Problem connecting to ANAC data server" message appears 9 times. Each copy is converted in place, without a shared helper.

### Tests
- Existing tests stay as they are. They use testthat edition 2, with no snapshots and no move to edition 3.
- **Line wrapping:** cli wraps messages at about 80 characters, so keep each phrase a test matches near the start of its message. The phrases are "Deleted 1/2/0", "not found", "empty", "my_cache", "nr_preco", "202401", "nova_coluna", "different RAB file layouts" and "Using 1 cached file".
- Add two small offline tests:
  - `check_flag()` rejects `NA` and `c(TRUE, FALSE)`, and the error message names the argument.
  - A cli message that contains a value with `{` in it (via `convert_to_numeric()`) prints the value literally and doesn't error. This guards rule 2.

### `NEWS.md` (under the existing development heading)
- Errors, warnings and messages are now formatted with {cli}.
- `showProgress` and `cache` now reject `NA` and vectors longer than one.
- `read_flights(type =)` no longer accepts partial matches (e.g. `"comb"`).


## Out of scope (possible follow-ups)

- Condition classes (`flightsbr_error`, ...)
- Snapshot tests, and moving to testthat edition 3
- Showing "Unzipping…" only when `showProgress = TRUE`
- Re-raising fread's unknown-`select` warning in `read_flights()`
- cli progress bars in place of pbapply
- A `flightsbr.verbose` option


## Verification

1. `grep -nE "\b(stop|warning|message|match\.arg)\(" R/*.R | grep -v "#'"` finds only the internal `match.arg()` in `get_flight_dates_available()`.
2. `devtools::document()`: no Rd changes expected, since no signatures change.
3. `devtools::test()` offline, and with `NOT_CRAN=true` for the live ANAC tests.
4. In a console, call a `read_*()` function with a bad argument, a missing month and the cache functions. The error header should name `read_*()`.
5. `R CMD check --as-cran`: 0 errors and 0 warnings. Then `/r-package-check` and a PR.

**Size:** about 2–3 hours of mechanical edits.

## Decision (user, 2026-11-19)

**Release timing:** included in **v1.3.0**.


## Review log (v1 → v2)

Three adversarial reviews were run, one each on simplicity, accuracy against the code, and cli/CRAN risk. No CRITICAL finding was introduced by the judge. Accepted changes:

- **CRITICAL:** the wrapper sketch dropped `message` and `.envir`, so every warning and message would have errored. Fixed by removing the wrappers.
- **CRITICAL:** pasting data into a cli template can run code. Now rule 2.
- **MAJOR:**
  - The class hierarchy, wrappers and snapshot tests were cut as scope creep. Snapshots would also have required testthat edition 3.
  - Adding `call` to the exported `check_date()` would have changed its signature and given a codoc WARNING. `rlang::caller_env()` is used inside it instead.
  - v1 missed `read_flights(type=)`'s `match.arg()`. It now uses `rlang::arg_match()`, and the loss of partial matching is noted in NEWS.
  - cli line wrapping can break tests that match on phrases. The at-risk phrases are now listed.
  - The "quieter by default" behaviour change was dropped.
- **MINOR (corrected):**
  - 11 files, not 12. `utils.R` has 8 stop and 5 message, not 7 and 6.
  - The connection message appears 9 times, not 8.
  - The `not the string "banana"` wording needs rlang ≥ 1.2.0's `check_bool()`; dropped.
  - `{.val}` doesn't quote numbers.
  - The stated reason for adding rlang was wrong (cli calls rlang at runtime).
