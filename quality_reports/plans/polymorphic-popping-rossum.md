# Plan: fix the 16 bugs found in the 2026-11-15 bug hunt

**Status:** IMPLEMENTED 2026-11-16 (PR pending) (v2, revised after 3 adversarial reviews: side effects, simplification, correctness)
**Branch:** `claude/fix-bug-hunt-2026-11` (from main 50cf000 + cherry-pick of d892282 → 11c18d5)
**Base:** new branch from `main`; cherry-pick `d892282` (read_flights relative-link fix) first. One PR.

## Context

Three bug-hunting agents reviewed flightsbr at `d892282`. 16 verified issues remain; several silently
return wrong data (NA identifier columns, HTML error pages cached and read as data, airfare fares split
across half-NA columns, 29% of private airports with NA coordinates). Most stem from shared helpers in
`R/utils.R`, so shared code is fixed first.

User decisions (2026-11-15): airfares → ANAC's newest `nr_*` names; numeric conversion → convert only
if every non-empty value parses, plus keep-as-character IDs; RAB → rename shared columns + warn across
layouts; one branch/PR.

New fact from review: `sas.anac.gov.br` rate-limits scripted traffic by answering **HTTP 200 `text/html`**
("Requisição Bloqueada") for data files and listings. Downloads must treat that as failure and stay polite.

## Approach (commit order; each commit updates the tests its behavior change breaks)

### 1. Downloads and cache — `R/utils.R` `download_flightsbr_file()`
Rewrite it as the single fetch-to-cache function; the 6 copy-pasted cache blocks (flights, aircraft,
movements, airfares, airports public/private) become one call each:
`if (is.null(download_flightsbr_file(...))) return(invisible(NULL))`.
- `cache = FALSE` → `unlink(dest_file)`; `todo <- !file.exists(dest_file)`; `unique()` the url/dest pairs.
- Download to `tempfile(pattern = basename(dest), tmpdir = dirname(dest))` (unique `.part`, no fork
  collisions); `req_perform_parallel(..., on_error = "continue", max_active = 4)`; requests get
  `req_retry(max_tries = 3)` with backoff.
- Success per file = `inherits(r, "httr2_response")` **and** content type is not `text/html` **and**
  the first 512 bytes don't start with `<`. Only then `file.rename()` into place, and a FALSE rename
  (Windows lock) counts as failure. Always `unlink()` the part files. One retry pass for failures.
- A 404 is an `httr2_http_404` condition that still wrote the error page — with part files it never
  reaches `dest_file`. No `resps_ok()` → no httr2 version floor.
- Messages: say "ANAC server refused/blocked the request" vs "connection failed", per cause.
- Keep `is_zip_file()` (2-byte check) as-is; instead wrap `archive_extract` + `fread` in flights in
  `tryCatch` that unlinks the zip and its extract dir on error (covers corrupt zips, no fixture churn).
- Delete every `setDTthreads(percent = 100)` set/restore pair (10, in 5 files): fread already
  multithreads, and forcing 100% overrides the user's setting and leaks on error.

### 2. Year → available months — all `read_*()` with a `date`
- Small helper `available_months(date, all_dates)` in `R/utils.R`: yyyymm passes through; yyyy →
  `intersect(generate_all_months(date), all_dates)` with a `message()` listing months "not available on
  ANAC". (`check_date()` already errors if the year has none, so the result is never empty.)
- Call it after `check_date()` in `read_aircraft()`, `read_airport_movements()`, `read_airfares()`;
  `read_flights()` keeps its existing `files[date %in% …]` filter.
- Drop the dead yyyy branches of `get_aircraft_url()` / `get_airport_movements_url()` (no other callers).
- `check_date()` unchanged (keeps `test_check_date` expectations).

### 3. Numeric conversion — `convert_to_numeric()` `R/utils.R:217`
- Candidates: names matching `^(nr|qt|comprimento|largura)_` or `^(lat|lon)geopoint$`, minus keep-as-
  character IDs `nr_voo, nr_voo_numero, nr_chave, nr_singular, nr_serie, nr_cert_matricula`.
  Remove the `type = 'airfare'` branch (canonical airfare names are `nr_*`, step 5).
- Per column:
  1. NA tokens → NA: `"", "null", "NULL", "NA", "N/A", "-", "XXXX", "...."`.
  2. `nr_pmd` (integer kg): strip non-digits (`"5 490"`, `"5670kg"`, `"2.850"` → 5490/5670/2850).
  3. Per value: if it contains `,` → drop `.` then `,`→`.`; else leave (handles mixed comma/dot-decimal
     months, e.g. airfares 2025, and dot-decimal geopoints like `-11.885`).
  4. Convert only if every non-NA value parses; an all-NA column becomes numeric NA (today's type).
  5. Otherwise leave the column character and emit one `message()` naming such columns, with the
     bad-value count and two examples (types can differ between requests — documented in NEWS).
- Drop: the `kg_|km_|lt_` extension (new behavior, not a bug) and the "nr_preco_venda → numeric" claim
  (47 free-text values keep it character; NEWS says so).

### 4. Airports — `R/utils.R:149-211`, `R/read_airports.R`
- `latlon_to_numeric()`: `gsub(",", ".", x)` before `parzer::parse_lat/lon` (private NA 1,159 → 0, verified).
- `altitude_to_numeric()`: values starting with `,` (`",0"`, the only missing code) → NA. Altitude only.
- Replace `options(warn = -1)` juggling with `suppressWarnings()`.
- `type = 'all'`: `rbindlist(use.names = TRUE)`.
- Geopoints handled by step 3's pattern.

### 5. Airfares — `R/utils_airfares.R`, `R/read_airfares.R`
- **Listing:** `get_airfares_files_available(dom, cache)` returns `data.table(date, url)` from the
  scraped hrefs (mirrors `get_flights_files_available()`), so `get_airfares_url()` (~70 lines incl. the
  accidental `.csv`/`.txt` year hack) is deleted.
  - Accept `yyyymm.csv`, `yyyymm (1).csv`, `internacional_yyyy-mm.(csv|txt)`; dedupe one url per date
    preferring: year folder = date's year → canonical basename → `.csv` over `.txt` → no `(1)`.
    Assert one url per date. (Check `INTERNACIONAL_2023-05.CSV.csv` / `tarifa_N_202305.csv` twins first.)
  - A year page that parses to zero data links counts as failed (block page), not "empty year".
  - Partial listing (`failed_years > 0`): cache it with `attr(, "failed_years")`; if a requested date is
    missing and falls in a failed year, re-scrape once with `cache = FALSE` before erroring.
  - New cache filename (old `.rds` held a numeric vector). `get_airfares_dates_available()` stays as an
    exported wrapper returning `as.numeric` dates.
- **Header harmonization** (per file, before `rbindlist(use.names = TRUE, fill = TRUE)`):
  - Encoding per file: `if (validUTF8(rawToChar(readBin(f, "raw", 4096)))) "UTF-8" else "Latin-1"`
    (202005 is UTF-8; all other Portuguese-header files Latin-1).
  - `make_clean_names()` → rename via `airfare_col_map` (table below) → drop `v1` → `stop()` if any
    column remains outside the canonical set (new ANAC version fails loudly).
  - Canonical domestic: `nr_ano_referencia, nr_mes_referencia, sg_empresa_icao, sg_icao_origem,
    sg_icao_destino, nr_tarifa, nr_assentos`; international adds `sg_icao_retorno, cd_classe_ida, cd_classe_volta`.

  | old (cleaned) | canonical |
  |---|---|
  | `ano`, `ano_de_referencia` | `nr_ano_referencia` |
  | `mes`, `mes_de_referencia` | `nr_mes_referencia` |
  | `empresa`, `icao_empresa_aerea`, `designador_icao_empresa` | `sg_empresa_icao` |
  | `origem`, `icao_aerodromo_origem`, `designador_icao_aeroporto_origem` | `sg_icao_origem` |
  | `destino`, `icao_aerodromo_destino`, `designador_icao_aeroporto_destino` | `sg_icao_destino` |
  | `retorno`, `icao_aerodromo_retorno`, `designador_icao_aeroporto_retorno` | `sg_icao_retorno` |
  | `classe_ida` | `cd_classe_ida` |
  | `classe_volta`, `classe_retorno` | `cd_classe_volta` |
  | `tarifa`, `tarifa_n`, `tarifa_nominal`, `valor_tarifa` | `nr_tarifa` |
  | `assentos`, `assentos_comercializados` | `nr_assentos` |
  | `v1` | drop |
- **`select`:** resolved through the same pipeline — user names → `make_clean_names()` → map → canonical,
  so old raw (`'TARIFA'`, `'VALOR_TARIFA'`) and old output (`'tarifa'`) names keep working. Applied after
  harmonization; unknown names → `warning()` (same as `read_flights`). Numeric positions: `stop()`
  (ambiguous across layouts). Template doc updated (columns are read, then dropped).
- `domestic`: inline `isTRUE(domestic) || isFALSE(domestic)` check.
- Remove `make_clean_names` block from `read_airfares()` (done per file now).

### 6. RAB aircraft — `R/utils_aircraft.R`
- Per file, on raw names: `setnames(x, "MARCA", "MARCAS", skip_absent = TRUE)` — always (breaking:
  `marca` → `marcas`, NEWS). Owner/operator columns are restructured (text vs JSON) and stay separate.
- Per file after fread (`na.strings` is ignored for quoted fields): `""`/`"null"` → NA in all columns;
  `gsub('""', '"', fixed = TRUE)` on character columns that contain `""` (makes the JSON columns valid,
  verified 100% with `jsonlite::validate`).
- If the files' column sets differ, one `warning()` listing old-only and new-only columns.
- Optional: normalize `TP_POUSO` "CONVECIONAL" → "CONVENCIONAL".

### 7. Small fixes
- `get_flights_files_available()` `R/utils_flights.R:125`: if the bound table lacks `date`/`type`/`url`
  or has 0 rows → message + NULL, before subsetting.
- `latest_flights_date()`: `if (is.null(all_dates)) return(invisible(NULL))`.
- Flights: `on.exit(unlink(<extracted txt>), add = TRUE)` inside `unzip_and_fread`.
- Movements listing: keep partial results with a message; NULL only if every year fails.
- Docs: `@return` "all columns character" wording (flights, aircraft, movements); movements first month
  (201903, not Jan 2019); `read_aircraft` example `202001` → `202409`; `select` template.
- Not doing (review: no observed bug / breaks tests): `normalize_anac_url` host restriction,
  `check_flag()`, `kg_/km_/lt_` conversion, stricter `is_zip_file()`.

### 8. Tests, docs, NEWS, version
- New offline test file **without** top-level `skip_on_cran()` (runs on CRAN): `convert_to_numeric()`
  (NA tokens, mixed decimals, keep-list, all-NA column, nr_pmd), lat/lon + altitude on in-memory rows,
  airfare harmonization with tiny in-memory CSVs for every header version incl. a UTF-8 accented one and
  a `v1` one, `available_months()` with a fake `all_dates`, listing dedupe on a fake href vector,
  `download_flightsbr_file()` success logic via `httr2::local_mocked_responses` if it supports `paths`
  (else unit-test the success predicate).
- Update in the commit that breaks them: `test_read_flights.R:18` (`nr_voo` character);
  `test_read_airfares.R:32` (`ano` → `nr_ano_referencia`), `:36-38`, `:43-46` (select now returns
  canonical names), `:77` (still a warning); `test_get_airfares_dates_available.R:15` (numeric).
- Live tests (`skip_on_cran`): content assertions on 1–2 months only — no all-NA code columns in
  movements, private-airport coordinate NA rate < 1%, a 2-month airfare call spanning header versions has
  no all-NA `nr_tarifa`. Heavy full-year checks behind `FLIGHTSBR_LIVE_HEAVY`. No current-year live test.
- `Version: 1.2.0.9000`; NEWS "Breaking changes" (airfare names, `nr_voo`/ID columns character,
  `marca`→`marcas`, empty/`"null"` RAB cells → NA, column types may differ by request) + "Bug fixes".
- `devtools::document()`. Any non-ASCII literal in R code as `\u` escapes.

## Critical files
`R/utils.R`, `R/utils_flights.R`, `R/utils_airfares.R`, `R/read_airfares.R`, `R/utils_aircraft.R`,
`R/read_aircraft.R`, `R/utils_airport_movement.R`, `R/read_airport_movements.R`, `R/read_airports.R`,
`R/latest_flights_date.R`, `DESCRIPTION`, `NEWS.md`, `man-roxygen/select.R` (or equivalent), `tests/testthat/*`.

## Verification
1. `devtools::document()`; `devtools::test()` — all pass (offline tests also with `NOT_CRAN=false`).
2. Live smoke script (scratchpad), politely paced, reporting rows / NA rate of key columns / names:
   `read_airport_movements(202512)`, `read_aircraft(c(202601, 202611))`, `read_airports('private')`,
   `read_airfares(c(202304, 202305))`, `read_airfares(c(202412, 202501), domestic = FALSE)`,
   `read_flights(202601)`, `read_aircraft(2024)`, `read_airfares(202605)`.
3. Cache-poisoning check: request a 404 month → nothing at dest path; second call still NULL, not HTML rows.
4. `R CMD check --as-cran` via `/r-package-check`: 0 errors / 0 warnings.
5. Push, open PR, watch the 5 GitHub Actions jobs. If live tests fail only on ANAC blocking (HTTP 200
   HTML), report that rather than weaken tests.
