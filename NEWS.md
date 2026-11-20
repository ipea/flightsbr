# flightsbr v1.3.0

* Major changes:

  * Downloaded files are now cached in `tools::R_user_dir("flightsbr", which = "cache")`, so they persist across R sessions and each file is downloaded only once. A cached file is downloaded again only if ANAC's copy has a different size, or when `cache = FALSE`. If ANAC can't be reached to check, the cached file is used. Closes [#49](https://github.com/ipea/flightsbr/issues/49).
  * New functions to manage the cache, similar to those in {geocodebr}:
    * `set_flightsbr_cache_dir()` sets the cache folder (the choice is kept across R sessions), 
    * `get_flightsbr_cache_dir()` returns path to cache dir
    * `list_flightsbr_cache()` lists the cached files
    * `delete_flightsbr_cache()` deletes some or all of the cached files.

* Minor changes:
  * Errors, warnings and messages are now formatted with {cli}.
  * Progress bars now come from {httr2} for downloads (a byte bar when a single file is downloaded) and from {cli} for reading several files. `showProgress = FALSE` now hides all of them, and {pbapply} is no longer a dependency.

* Breaking changes:
  * `read_airfares()` now returns the same column names for every period, using the names of ANAC's current files: `nr_ano_referencia`, `nr_mes_referencia`, `sg_empresa_icao`, `sg_icao_origem`, `sg_icao_destino`, `nr_tarifa`, `nr_assentos`, and for international flights also `sg_icao_retorno`, `cd_classe_ida` and `cd_classe_volta`. Older names such as `ano`, `tarifa` or `valor_tarifa` are no longer returned, but are still accepted by `select`.
  * Identifier columns are no longer converted to numbers, so they keep their leading zeros: `nr_voo` and `nr_chave` (`read_flights()`), `nr_voo_numero` (`read_airport_movements()`), and `nr_serie` and `nr_cert_matricula` (`read_aircraft()`).
  * More generally, a column named like a number (`nr_*`, `qt_*`, ...) is converted to numeric only if all its values are numbers. Otherwise it stays character, with a message when only a few values are the problem (e.g. `nr_preco_venda` in recent RAB files). The type of such a column can therefore differ between requests for different months.
  * `read_aircraft()`: the registration "marca" column is always called `marcas` (it was `marca` in files before 2026), and empty cells and the text `"null"` are returned as `NA`.

* Bug fixes:

  * Fixed `read_airport_movements()` returning `NA` for every airport, airline and aircraft code: the codes in `nr_*` columns were converted to numbers.
  * Fixed `read_aircraft()` returning `NA` for many serial numbers and almost all sale prices, which use Brazilian number formatting (`"1.500.000,00"`).
  * Fixed failed downloads being cached: ANAC answers missing files and blocked requests with an HTML page, which was saved and later read as data with `cache = TRUE`. Files are now downloaded to a temporary file and only kept when the download succeeded and is not a web page. Downloads are retried and run at most four at a time.
  * Fixed `read_airfares()` splitting fares and other columns into separate, half-empty columns when the requested months use different ANAC headers. Files with an unknown header now fail with an error.
  * Fixed `read_airfares()` failing for months that ANAC re-uploaded under another name (e.g. May 2026, `202605 (1).csv`). Download links now come from ANAC's listing.
  * Fixed `read_aircraft()`, `read_airport_movements()` and `read_airfares()` with a year (`date = yyyy`) failing whenever any month of that year is not available on ANAC. They now read the available months and list the missing ones in a message.
  * Fixed `read_airports()` returning `NA` coordinates for about 29% of private airports (seconds written with a decimal comma), and altitude `0` for airports whose altitude is missing (`",0"`). `latgeopoint` and `longeopoint` are now numeric.
  * Fixed the JSON owner and operator columns of recent RAB files (`proprietarios`, `operadores`) not being valid JSON. `read_aircraft()` warns when the requested months use different RAB layouts.
  * Fixed a page without the flight file table being cached as a bogus listing, which broke `read_flights()` for the rest of the session. `latest_flights_date()` returns `NULL` instead of `-Inf` when ANAC can't be reached.
  * `read_airfares()` rejects `domestic = NA` and vectors of length > 1.
  * Large text files extracted from the flight zip files are deleted after being read.
  * Functions no longer change the number of threads used by `data.table`.
  * Fixed `read_flights()` failing to download any data. ANAC's website now lists flight files with relative links that lead to an HTML page instead of the zip file. The package now builds the direct download link (`https://www.gov.br/.../<file>.zip/@@download/file`), saves each month under its own file name, and checks that each downloaded file is really a zip archive, with a clear message when ANAC returns a web page instead.


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


# flightsbr v1.1.1

* The previous version of {flightsbr} was temporarily taken down from CRAN because one of its dependencies (the {parzer} package) was removed from CRAN on July 1st 2025. This update of flightsbr v1.1.1 is simply intended to put the package back on CRAN.


# flightsbr v1.1.0

* Major changes:
  * The default of all `read_` functions now is to download data from the latest date available.
  * The function `read_aircrafts()` is now deprecated in favor of `read_aircraft()` simply to fix a typo in the function name. The behavior and outputs are identical. Closes [#45](https://github.com/ipea/flightsbr/issues/45)

* CRAN policy:
  * updaed DESCRIPTION file removing 'NeedsCompilation'

# flightsbr v1.0.0

* Breaking changes:
  * The names of all columns in the data outputs are now cleanned with {janitor}
  * Function `read_airports()` now downloads v2 version of public airports data. Closes [#41](https://github.com/ipea/flightsbr/issues/41)

* Major changes:
  * Function `read_airfares()` is working again. Closes [#30](https://github.com/ipea/flightsbr/issues/30). The prices of air tickets are now returned as numeric.
  * Function `read_flights()` with fixed decimal values in numeric columns. Closes [#43](https://github.com/ipea/flightsbr/issues/43)
  * Function `read_airports()` with fixed numeric values for `"altitude"` column. Closes [#42](https://github.com/ipea/flightsbr/issues/42)
    
* Minor changes:
  * Internally check of the consistency of date inputs. The date input must be consistent in either a 6-digit format `yyyymm` OR a 4-digit format `yyyy`.
  * New support function `latest_airfares_date()`
  * Fix error that stopped reading aircraft data `read_aircraft()` for multiple months when the number of collums differed across months. Fixed using `data.table::rbindlist(fill = TRUE)`

# flightsbr v0.5.0

* Major changes:
  * Fixed ANAC's broken link of public airports
  * Functions `read_flights()`, `read_airport_movements()`, and `read_aircraft()` now accept vectors of dates like `c(202201, 202301)` or `c(2022, 2024)`
  * Functions `read_airports()` and `read_aircraft()` now has a `cache` parameter.
  * The package is now significantly faster because it is using `curl::multi_download()` to download files in parallel. This brings the advantage that the package now automatically detects whether the data file has been updated and should be downloaded again.

* Minor changes:
  * Removed dependency on the {httr} package
  * Streamlined functions to simplify package maintenance and improve performance
  * Using {fs} to manage file paths and {archive} to unzip files
  * Reorganization of internal functions to simplify package maintenance

# flightsbr v0.4.1

* Minor changes:
  * The `read_flights()` function now uses `fread(encoding = 'Latin-1')` internally to avoid issues with encoding. Closed #35.
  * The function `get_airport_movement_dates_available()` does not throw warnings of `NA` values anymore.
  * The `read_aircraft()` function now used `fread(skip = 1)` internally to read column names correctly.


# flightsbr v0.4.0

* Major changes:
  * The functions `read_flights()` and `read_airport_movements()` now have a new parameter `cache`, which indicates whether the function should read cached data downloaded previously. Defaults to `TRUE`. Closed #31.
  * The function `read_aircraft()` now has a `date` parameter, which allows one to download the data on aircraft registered at ANAC at particular years/months.  Closed #33.

* Minor changes:
  * All functions now return numeric columns with `numeric` class. Closed #32.

* Bug fixes:
  * Fixed bug when unzipping files for `read_flights()` function in Unix systems. 
  Closed #31.
   * Updated link to private airports data changed by ANAC. Closed #34.

# flightsbr v0.3.0

* Major changes:
  * Function read_airfares() is temporarily  unavailable. See issue [#30](https://github.com/ipea/flightsbr/issues/30) 

* Minor changes:
  * Function `read_flights()` now accepts a vector of dates. Closed #29.

* Bug fixes:
  * Fixed broken link for data dictionary for airport movement data
  * Fixed code to rbindlist air fares from multiple years. Closed #26.
  * Fixed code to read a few dates that were not caught in `get_airfares_dates_available()` because of ".CSV" in ANAC url. Closed #27.
  * Fixed code to use `get_airport_movement_dates_available()`



# flightsbr v0.2.1

* Bug fixes:
  * Fixed bug in `read_flights()` due to changes in ANAC data links.
  * Fixed broken link in `intro_flightsbr` vignette


# flightsbr v0.2.0

* Major changes:
  * Update urls to new location where flights data is stored. This makes `read_flights()` work again.
  * New function `read_airfares()` to read data on airfares of domestic and international flights [Closed #22](https://github.com/ipea/flightsbr/issues/22).

* Minor changes:
  * The data downloaded in `read_flights()` and `read_airport_movements()` are now cached in temp dir. Closed [#20](https://github.com/ipea/flightsbr/issues/21).
  * All columns are now returned with class `character`. This fixes a bug in the `read_airport_movements()` function. Closed [#20](https://github.com/ipea/flightsbr/issues/20).



# flightsbr v0.1.2

* Bug fixes:
  * Fixed bug that stopped flightsbr from downloading 2022 data.



# flightsbr v0.1.1

* Bug fixes:
  * functions `read_flights()` and `read_airport_movements()` no longer have side effects on objects named `month` and `year` on the global environment. The `split_date()` support function was removed from the package. [Closed #17](https://github.com/ipea/flightsbr/issues/17).
  * `read_` functions now try to download for a 2nd time if the 1st attempt failed. This will help overcome a small issue with the instability of ANAC data links. [Closed #18](https://github.com/ipea/flightsbr/issues/18).
  * Using a simpler / slightly faster version of `latlon_to_numeric()` with suppressed warnings.
  * Update package citation, adding OSF preprint DOI.


# flightsbr v0.1.0

* Major changes:
  * New function `read_aircraft()` to read data on all aircraft registered in the Brazilian Aeronautical Registry (Registro Aeronáutico Brasileiro - RAB) [Closed #14](https://github.com/ipea/flightsbr/issues/14).
  * New function `read_airports()` to read data on all public and private airports. [Closed #4](https://github.com/ipea/flightsbr/issues/4) and [Closed #9](https://github.com/ipea/flightsbr/issues/9).
  * New function `latest_flights_date()` to check the date of the latest flight data available. [Closed #16](https://github.com/ipea/flightsbr/issues/16).
  * New function `read_airport_movements()` to download data on airport movements. [Closed #15](https://github.com/ipea/flightsbr/issues/15).
  * Function `read_flights()` now takes `date` input in the format `yyyymm` or `yyyy`. When the date input is a 4-digit number, the function now downloads data of all months in that year. [Closed #1](https://github.com/ipea/flightsbr/issues/1).
  * Function `read_flights()` now automatically detects and checks the latest flights data available. [Closed #13](https://github.com/ipea/flightsbr/issues/13).
  * new internal support functions:
    * `split_date()`: Split a date from yyyymmm to year yyyy and month mm
    * `check_date()`: Check whether date input is acceptable
    * `generate_all_months()`: Generate all months with `yyyymm` format in a year
    * `latlon_to_numeric()`: Convert spatial coordinates of airports to lat lon
    * `get_flights_url()`: Put together the url of flight data files
    * `get_flight_dates_available()`: Retrieve from ANAC website all dates available for flights data
    * `download_flights_data()`: Download and read ANAC flight data
    * `get_airport_movements_url()`: Put together the url of airport movement data files
    * `get_airport_movement_dates_available()`: Retrieve all dates available for airport movements data
    * `download_airport_movement_data()`: Download and read ANAC airport movement data
  * Three separate vignettes. A general intro to the package, and more detailed vignettes on `read_flights` and `read_airports()`.

* Minor changes:
  * new parameter `select` in `read_flights()`, allowing the user to specify the columns that should be read.
  * new tests of `read_flights()`. Coverage of 95.24%. [Closed #5](https://github.com/ipea/flightsbr/issues/5).
  * New checks on `date` input. [Closed #2](https://github.com/ipea/flightsbr/issues/2).
  * Functions now should fail gracefully in case of problems with internet connection. [Closed #7](https://github.com/ipea/flightsbr/issues/7).



# flightsbr v0.0.1

* Launch of **flightsbr** v0.0.1 on CRAN https://cran.r-project.org/package=flightsbr
