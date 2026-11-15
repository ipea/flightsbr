# data.table::fread vs duckdb for `read_flights()`

**Date:** 2026-11-15 · **Status:** evaluation only, no package code changed
**Method:** three Sonnet agents worked independently, each taking a different route. They shared one zip cache. Windows 11, R 4.5.1, duckdb 1.5.6, data.table 1.18.4, arrow 25.0.0, duckplyr 1.2.1.

| Agent | Route | Months tested |
|---|---|---|
| 1 | duckdb SQL `read_csv` → Parquet, compared cell by cell with fread | 41 basica (every year 2000–2026) + 14 combinada |
| 2 | duckplyr / arrow high-level readers, plus a `collect = TRUE/FALSE` prototype | 27 basica + 8 combinada |
| 3 | Sweep for problem files, synthetic repros, benchmark | **all 321 basica** + 160 combinada |

Data files in this folder:
- `sweep_all_months.csv`: agent 3, one row per month.
- `compare_vs_fread_55_months.csv`: agent 1.
- `candidate_config_results.csv`, `bench_log.csv`: agent 3.
- `prototype_read_flights_duck.R`: agent 2. Not reviewed.

---

## 0. Separate blocker: the downloader is broken today

`get_flights_files_available()` returns **all 642 hrefs as relative paths** (`/anac/pt-br/.../basica2022-05.zip`). Running `download_flightsbr_file()` on basica 2022-05 failed with "Internet connection not working", so `read_flights()` currently cannot download anything (verified by the coordinator).

Adding `https://www.gov.br` in front is not enough. That URL returns an HTML page of about 297 KB. The real zip is at `https://www.gov.br<href>/@@download/file`; only the 2026-06..09 hrefs already end that way (8 of 642). All three agents confirmed this independently. The fix is needed whatever happens with duckdb. The download step should also check that the file starts with the zip signature `PK`.

## 1. What is actually wrong in the ANAC files

From agent 3's full basica sweep:
- **No** NUL bytes, control characters, BOMs, lone CRs, rows with the wrong number of fields, unbalanced quotes or header problems in any of the 481 swept months.
- fread's row count equals the data-line count in every month.
- Only two categories of problem exist.

| Category | What it is | Months (basica) | fread | duckdb default |
|---|---|---|---|---|
| **A. Backslash-escaped quotes** | `"BUCHAREST \"HENRI COANDA\""` inside quoted fields | 22: 2014-05, 2014-07, 2015-11, 2015-12, 2016-03, 2017-04, 2017-06, 2017-09, 2018-03, 2019-04, 2019-11, 2020-02, 2020-03, 2021-01, 2021-02, 2021-03, 2021-06, 2022-05, 2022-06, 2022-07, 2025-07, 2025-10 (+8 combinada) | warns "improper quoting", keeps every row and keeps `\"` literally | errors on 22 of 30; on the other 8 it **silently alters 1–10 cells** |
| **B. Windows-1252 bytes 0x80–0x9F** | e.g. `Š` (0x8A), 2–12 bytes per file | 7: 2002-02, 2015-11, 2017-01, 2017-09, 2019-06, 2019-11, 2021-05 (+5 combinada) | reads them | **errors on the whole month at every tolerance level**: duckdb's `latin-1` rejects 0x80–0x9F, and the `encodings` extension needs a network install |

Column counts vary between 111, 110 (2015-10 to 2018-05, no `nr_chave`) and 90 (combinada). Multi-month reads therefore **must** use `union_by_name=true`.

## 2. duckdb configuration that matches fread

Combining agent 1's and agent 3's results:

```sql
COPY (
  SELECT * FROM read_csv('<file>',
    delim = ';', header = true, all_varchar = true,
    encoding = 'latin-1',
    strict_mode = false,   -- needed for category A
    escape = '',           -- keep \" literally, as fread does; the default and '\' both alter cells
    nullstr = 'NA')        -- empty field = "" and "NA" = NA, as fread does
) TO '<month>.parquet' (FORMAT parquet, COMPRESSION zstd);
```

- Agent 1: **cell-for-cell identical to fread on 54 of 55 months**. The one failure (2017-09) is category B.
- Agent 3: after converting CP1252 to UTF-8 first, `strict_mode=false, escape=''` gave **0 cell mismatches on 41 of 41 months** (35 problem months + 6 clean controls).
- Leaving out `nullstr='NA'` turns empty strings into NULL. Agent 2 found 13–21 columns per month that differ from fread for this reason.
- **Do not use `ignore_errors=true`.** It dropped 2,695 rows from 2014-07 without an error (94,656 → 91,961). No real file needs it.
- Keep `null_padding=true` out of the default. No real file needs it, and with quoted newlines it errors on the parallel scanner.

### Category B: convert on demand

When duckdb errors with "not latin-1 encoded", convert the file from CP1252 to UTF-8 and retry with `encoding='utf-8'`. With R's `iconv` this costs **6–24 s and 1.2–3.9 GB per file**, so only do it after a failure. It affects 7 basica months of 321.

### Recommended fallback chain (agent 3)

1. duckdb with the configuration above → Parquet.
2. On "not latin-1": convert to UTF-8, then retry.
3. On any other error: retry with `null_padding=true, ignore_errors=true, store_rejects=true, parallel=false` and **report the reject count**.
4. Last resort: `fread`, then write the result to Parquet.

## 3. fread is less tolerant than assumed

On synthetic broken files (agents 1 and 3), fread **silently truncates** at a row with too many or too few fields, or at a mid-file blank line. In one case it returned 100 of 201 rows, and in another 3,001 of 30,002, with only a warning. duckdb with `strict_mode=false` (+`null_padding`) keeps every row. None of the real ANAC files have these problems today.

Other differences seen on synthetic files:
- fread trims surrounding whitespace in fields; duckdb does not.
- fread drops a trailing `Total;3` footer line; duckdb keeps it as a row.

Neither appeared in the real files: there were 0 cell differences in the 54 months compared.

## 4. Performance

Timings were taken on a shared, loaded machine, so treat them as rough. The agents disagree on per-month eager reads: agent 1 included an arrow read-back and the machine was busier.

| Scenario | fread | duckdb CSV→Parquet | Parquet→R (duckdb) | Lazy `count()` |
|---|---|---|---|---|
| median basica month (2016-06, 69 MB CSV) | 0.58 s, 246 MB | 0.81 s, 428 MB | 0.45 s, 332 MB | 0.04 s |
| largest basica month (2012-01, 92 MB) | 0.72 s, 294 MB | 1.03 s, 535 MB | 0.62 s, 406 MB | 0.04 s |
| largest combinada (2010-06, 252 MB) | 1.44 s, 596 MB | 1.45 s, 1.29 GB | 1.19 s | – |
| **year 2024 basica (12 months)** | 14.5 s, 1.96 GB | 4.9 s, 3.7 GB | 9.9 s, 3.0 GB | **0.03 s** |
| year 2023, end to end (agent 2) | 67–99 s | first run 75 s | cached 12–14 s | 0.5 s |

- **Loading one month into memory:** no faster than fread, and uses roughly 1.5–2× the peak memory.
- **After the first run, from the cache:** a year loads about 5× faster.
- **Lazy access** to a year or several years takes under a second.
- **Disk:** a year of basica is about 57 MB of zstd Parquet, against about 905 MB of CSV and about 90 MB of zips. A month is about 0.7–7 MB.

## 5. Proposed design (agent 2's prototype)

```r
read_flights(date, type, showProgress, select, cache = TRUE,
             collect = TRUE,                      # FALSE -> lazy duckdb tbl
             cache_dir = tools::R_user_dir("flightsbr", "cache"))
```

- One Parquet file per month: `flights/type=<t>/year=<y>/<t>YYYY-MM.parquet`, written atomically (`.part`, then rename).
- Read with `read_parquet([...], union_by_name=true, hive_partitioning=false)`. Without `hive_partitioning=false`, `type` and `year` columns are added from the folder names.
- Name cleaning: run `janitor::make_clean_names()` on the header only. Numeric conversion in SQL: `TRY_CAST(replace(x, ',', '.') AS DOUBLE)`, using the same column-name pattern as `convert_to_numeric()`.
- `collect=TRUE` returns `setDT(collect(...))`, the same class as today. `collect=FALSE` returns a `tbl_duckdb_connection`.
- **Connection:** one package-level in-memory duckdb connection, closed by a finalizer, plus an exported disconnect function.
  - Lazy tables don't survive `saveRDS` or a new session.
  - The duckplyr default connection was rejected. Its "prudent" frames error on `nrow()`, and its "lavish" mode silently loads everything into memory.
- **Windows:** on local NTFS, an open lazy table did not lock the Parquet file; delete and replace both worked. A cache path of about 200 characters hit Windows' 260-character path limit.
- **Refreshing the cache:** ANAC's HEAD response has `Content-Length` and a stable weak ETag, but no `Last-Modified`. Both are stored in the Parquet metadata; `check_updates=TRUE` makes one HEAD request per month, and the default trusts the cache.
- **Dependencies:**
  - Imports: `duckdb` and `DBI`. duckdb is a large binary and slow to build from source on CRAN.
  - Suggests: `dplyr` and `dbplyr`, for `collect=FALSE`.
  - Not needed: `duckplyr`, `arrow`, and possibly `archive` (`utils::unzip` handled 85 MB members).
- **arrow is ruled out.** `open_delim_dataset()` ignores latin-1 (0/35 months). `read_delim_arrow(encoding="latin1")` works but is about 5× slower than fread.

## 6. Other observations

- **`nr_chave` (a 25-digit ID) is converted to numeric** by `convert_to_numeric()` because it matches `nr_`. A double holds only about 15–17 significant digits, so **the current package already loses precision** in this key. duckdb's cast differed from R's `as.numeric` by one unit in the last place on 782 of 929k rows. This column should probably be excluded from numeric conversion, like `nr_singular`.
- Agent 2 timed the extra CP1252 conversion at 13–24 s on 2002-02.

## 7. Verdict

**Viable, with caveats.** duckdb can reproduce fread's output exactly on the real ANAC files, but only with `strict_mode=false, escape='', nullstr='NA'` plus on-demand CP1252 conversion. Default duckdb settings either error or silently alter cells. The benefit is the **Parquet cache and lazy access**, not faster reading: a single month loaded into memory is no faster and uses more memory. The cost is a heavy `duckdb` dependency and a fallback chain to maintain.

A reasonable path:
1. Fix the downloader (§0) now, separately.
2. Put the duckdb path behind an option or new argument, keeping fread as the default.
3. Make it the default only after a full sweep of all 642 files passes cell by cell, including on Linux and macOS.

## Not covered

- 161 combinada months were not swept.
- About 385 basica months were checked by row count only, not cell by cell.
- Linux/macOS (fread's encoding behaviour differs there).
- `R CMD check --as-cran` with duckdb in Imports.
- Concurrent sessions writing the same cache, Dropbox or antivirus file locks, and duckdb's `memory_limit`.
- The `encodings` extension (it needs a network install).
- Precise peak-memory figures (the machine was shared).
- `read_flights()` end to end. It can't run until the downloader is fixed.
