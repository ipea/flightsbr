# Changelog

## flightsbr v1.2.0 DEV

- Minor changes:

  - When the package tries to download multiples but fails with a few
    ones, the package now only try to download again the files that
    failed in the first attempt.
  - The function
    [`read_aircrafts()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircrafts.md)
    now throws an error, as it has been deprecated in favor of
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    simply to fix a typo in the function name. The behavior and outputs
    are identical.
  - [`read_airfares()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airfares.md)
    and
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    now cache the list of dates/files available from ANAC to a
    session-scoped temp file, governed by the existing `cache`
    parameter. This avoids re-scraping ANAC’s website on every single
    call within the same R session.
  - Files are now downloaded using
    [`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html),
    replacing
    [`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html).

- Bug fixes:

  - Fixed error in reading data from ANAC website. Fixed
    [\#52](https://github.com/ipea/flightsbr/issues/52) and
    [\#51](https://github.com/ipea/flightsbr/issues/51).
  - Fixed the `select` parameter in
    [`read_airfares()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airfares.md),
    which was silently ignored and had no effect on the columns
    returned. It now behaves the same way as `select` in
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md).
  - Fixed
    [`get_airfares_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airfares_dates_available.md)
    (used internally by
    [`read_airfares()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airfares.md))
    to retry requests to ANAC that fail transiently (timeouts,
    connection errors, HTTP 429/503) instead of silently dropping the
    affected year and returning an incomplete list of available dates.
  - Fixed
    [`get_airfares_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airfares_dates_available.md)
    and
    [`latest_airfares_date()`](https://ipeagit.github.io/flightsbr/dev/reference/latest_airfares_date.md)
    to fail cleanly with `NULL` when ANAC can’t be reached, instead of
    occasionally producing a nonsensical “data available between Inf and
    -Inf” error, or `-Inf` as a date.
  - Replaced a brittle hardcoded filename-length check (`nchar == 55`)
    used to filter valid international airfare files listed by ANAC with
    an explicit filename-pattern check, and added the equivalent check
    to the domestic airfare listing (which previously had no filter at
    all). This guards against malformed, duplicate, or misplaced files
    that ANAC occasionally publishes (e.g. typo’d names, files uploaded
    to the wrong year, re-uploads with `(1)` appended) corrupting the
    list of available dates.

## flightsbr v1.1.1

CRAN release: 2025-07-24

- The previous version of {flightsbr} was temporarily taken down from
  CRAN because one of its dependencies (the {parzer} package) was
  removed from CRAN on July 1st 2025. This update of flightsbr v1.1.1 is
  simply intended to put the package back on CRAN.

## flightsbr v1.1.0

CRAN release: 2025-05-19

- Major changes:
  - The default of all `read_` functions now is to download data from
    the latest date available.
  - The function
    [`read_aircrafts()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircrafts.md)
    is now deprecated in favor of
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    simply to fix a typo in the function name. The behavior and outputs
    are identical. Closes
    [\#45](https://github.com/ipeaGIT/flightsbr/issues/45)
- CRAN policy:
  - updaed DESCRIPTION file removing ‘NeedsCompilation’

## flightsbr v1.0.0

CRAN release: 2024-10-22

- Breaking changes:
  - The names of all columns in the data outputs are now cleanned with
    {janitor}
  - Function
    [`read_airports()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airports.md)
    now downloads v2 version of public airports data. Closes
    [\#41](https://github.com/ipeaGIT/flightsbr/issues/41)
- Major changes:
  - Function
    [`read_airfares()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airfares.md)
    is working again. Closes
    [\#30](https://github.com/ipeaGIT/flightsbr/issues/30). The prices
    of air tickets are now returned as numeric.
  - Function
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    with fixed decimal values in numeric columns. Closes
    [\#43](https://github.com/ipeaGIT/flightsbr/issues/43)
  - Function
    [`read_airports()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airports.md)
    with fixed numeric values for `"altitude"` column. Closes
    [\#42](https://github.com/ipeaGIT/flightsbr/issues/42)
- Minor changes:
  - Internally check of the consistency of date inputs. The date input
    must be consistent in either a 6-digit format `yyyymm` OR a 4-digit
    format `yyyy`.
  - New support function
    [`latest_airfares_date()`](https://ipeagit.github.io/flightsbr/dev/reference/latest_airfares_date.md)
  - Fix error that stopped reading aircraft data
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    for multiple months when the number of collums differed across
    months. Fixed using `data.table::rbindlist(fill = TRUE)`

## flightsbr v0.5.0

CRAN release: 2024-09-18

- Major changes:
  - Fixed ANAC’s broken link of public airports
  - Functions
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md),
    [`read_airport_movements()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airport_movements.md),
    and
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    now accept vectors of dates like `c(202201, 202301)` or
    `c(2022, 2024)`
  - Functions
    [`read_airports()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airports.md)
    and
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    now has a `cache` parameter.
  - The package is now significantly faster because it is using
    [`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html)
    to download files in parallel. This brings the advantage that the
    package now automatically detects whether the data file has been
    updated and should be downloaded again.
- Minor changes:
  - Removed dependency on the {httr} package
  - Streamlined functions to simplify package maintenance and improve
    performance
  - Using {fs} to manage file paths and {archive} to unzip files
  - Reorganization of internal functions to simplify package maintenance

## flightsbr v0.4.1

CRAN release: 2024-04-23

- Minor changes:
  - The
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    function now uses `fread(encoding = 'Latin-1')` internally to avoid
    issues with encoding. Closed
    [\#35](https://github.com/ipeaGIT/flightsbr/issues/35).
  - The function
    [`get_airport_movement_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airport_movement_dates_available.md)
    does not throw warnings of `NA` values anymore.
  - The
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    function now used `fread(skip = 1)` internally to read column names
    correctly.

## flightsbr v0.4.0

CRAN release: 2023-12-04

- Major changes:
  - The functions
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    and
    [`read_airport_movements()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airport_movements.md)
    now have a new parameter `cache`, which indicates whether the
    function should read cached data downloaded previously. Defaults to
    `TRUE`. Closed
    [\#31](https://github.com/ipeaGIT/flightsbr/issues/31).
  - The function
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    now has a `date` parameter, which allows one to download the data on
    aircraft registered at ANAC at particular years/months. Closed
    [\#33](https://github.com/ipeaGIT/flightsbr/issues/33).
- Minor changes:
  - All functions now return numeric columns with `numeric` class.
    Closed [\#32](https://github.com/ipeaGIT/flightsbr/issues/32).
- Bug fixes:
  - Fixed bug when unzipping files for
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    function in Unix systems. Closed
    [\#31](https://github.com/ipeaGIT/flightsbr/issues/31).
  - Updated link to private airports data changed by ANAC. Closed
    [\#34](https://github.com/ipeaGIT/flightsbr/issues/34).

## flightsbr v0.3.0

CRAN release: 2023-06-29

- Major changes:
  - Function read_airfares() is temporarily unavailable. See issue
    [\#30](https://github.com/ipeaGIT/flightsbr/issues/30)
- Minor changes:
  - Function
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    now accepts a vector of dates. Closed
    [\#29](https://github.com/ipeaGIT/flightsbr/issues/29).
- Bug fixes:
  - Fixed broken link for data dictionary for airport movement data
  - Fixed code to rbindlist air fares from multiple years. Closed
    [\#26](https://github.com/ipeaGIT/flightsbr/issues/26).
  - Fixed code to read a few dates that were not caught in
    [`get_airfares_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airfares_dates_available.md)
    because of “.CSV” in ANAC url. Closed
    [\#27](https://github.com/ipeaGIT/flightsbr/issues/27).
  - Fixed code to use
    [`get_airport_movement_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airport_movement_dates_available.md)

## flightsbr v0.2.1

CRAN release: 2022-11-27

- Bug fixes:
  - Fixed bug in
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    due to changes in ANAC data links.
  - Fixed broken link in `intro_flightsbr` vignette

## flightsbr v0.2.0

CRAN release: 2022-05-05

- Major changes:
  - Update urls to new location where flights data is stored. This makes
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    work again.
  - New function
    [`read_airfares()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airfares.md)
    to read data on airfares of domestic and international flights
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/22)
    [\#22](https://github.com/ipeaGIT/flightsbr/issues/22).
- Minor changes:
  - The data downloaded in
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    and
    [`read_airport_movements()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airport_movements.md)
    are now cached in temp dir. Closed
    [\#20](https://github.com/ipeaGIT/flightsbr/issues/21).
  - All columns are now returned with class `character`. This fixes a
    bug in the
    [`read_airport_movements()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airport_movements.md)
    function. Closed
    [\#20](https://github.com/ipeaGIT/flightsbr/issues/20).

## flightsbr v0.1.2

CRAN release: 2022-03-18

- Bug fixes:
  - Fixed bug that stopped flightsbr from downloading 2022 data.

## flightsbr v0.1.1

CRAN release: 2022-03-06

- Bug fixes:
  - functions
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    and
    [`read_airport_movements()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airport_movements.md)
    no longer have side effects on objects named `month` and `year` on
    the global environment. The `split_date()` support function was
    removed from the package.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/17)
    [\#17](https://github.com/ipeaGIT/flightsbr/issues/17).
  - `read_` functions now try to download for a 2nd time if the 1st
    attempt failed. This will help overcome a small issue with the
    instability of ANAC data links.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/18)
    [\#18](https://github.com/ipeaGIT/flightsbr/issues/18).
  - Using a simpler / slightly faster version of
    [`latlon_to_numeric()`](https://ipeagit.github.io/flightsbr/dev/reference/latlon_to_numeric.md)
    with suppressed warnings.
  - Update package citation, adding OSF preprint DOI.

## flightsbr v0.1.0

CRAN release: 2022-02-08

- Major changes:
  - New function
    [`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md)
    to read data on all aircraft registered in the Brazilian
    Aeronautical Registry (Registro Aeronáutico Brasileiro - RAB)
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/14)
    [\#14](https://github.com/ipeaGIT/flightsbr/issues/14).
  - New function
    [`read_airports()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airports.md)
    to read data on all public and private airports.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/4)
    [\#4](https://github.com/ipeaGIT/flightsbr/issues/4) and
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/9)
    [\#9](https://github.com/ipeaGIT/flightsbr/issues/9).
  - New function
    [`latest_flights_date()`](https://ipeagit.github.io/flightsbr/dev/reference/latest_flights_date.md)
    to check the date of the latest flight data available.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/16)
    [\#16](https://github.com/ipeaGIT/flightsbr/issues/16).
  - New function
    [`read_airport_movements()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airport_movements.md)
    to download data on airport movements.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/15)
    [\#15](https://github.com/ipeaGIT/flightsbr/issues/15).
  - Function
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    now takes `date` input in the format `yyyymm` or `yyyy`. When the
    date input is a 4-digit number, the function now downloads data of
    all months in that year.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/1)
    [\#1](https://github.com/ipeaGIT/flightsbr/issues/1).
  - Function
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)
    now automatically detects and checks the latest flights data
    available. [Closed](https://github.com/ipeaGIT/flightsbr/issues/13)
    [\#13](https://github.com/ipeaGIT/flightsbr/issues/13).
  - new internal support functions:
    - `split_date()`: Split a date from yyyymmm to year yyyy and month
      mm
    - [`check_date()`](https://ipeagit.github.io/flightsbr/dev/reference/check_date.md):
      Check whether date input is acceptable
    - [`generate_all_months()`](https://ipeagit.github.io/flightsbr/dev/reference/generate_all_months.md):
      Generate all months with `yyyymm` format in a year
    - [`latlon_to_numeric()`](https://ipeagit.github.io/flightsbr/dev/reference/latlon_to_numeric.md):
      Convert spatial coordinates of airports to lat lon
    - `get_flights_url()`: Put together the url of flight data files
    - [`get_flight_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_flight_dates_available.md):
      Retrieve from ANAC website all dates available for flights data
    - [`download_flights_data()`](https://ipeagit.github.io/flightsbr/dev/reference/download_flights_data.md):
      Download and read ANAC flight data
    - [`get_airport_movements_url()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airport_movements_url.md):
      Put together the url of airport movement data files
    - [`get_airport_movement_dates_available()`](https://ipeagit.github.io/flightsbr/dev/reference/get_airport_movement_dates_available.md):
      Retrieve all dates available for airport movements data
    - [`download_airport_movement_data()`](https://ipeagit.github.io/flightsbr/dev/reference/download_airport_movement_data.md):
      Download and read ANAC airport movement data
  - Three separate vignettes. A general intro to the package, and more
    detailed vignettes on `read_flights` and
    [`read_airports()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airports.md).
- Minor changes:
  - new parameter `select` in
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md),
    allowing the user to specify the columns that should be read.
  - new tests of
    [`read_flights()`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md).
    Coverage of 95.24%.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/5)
    [\#5](https://github.com/ipeaGIT/flightsbr/issues/5).
  - New checks on `date` input.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/2)
    [\#2](https://github.com/ipeaGIT/flightsbr/issues/2).
  - Functions now should fail gracefully in case of problems with
    internet connection.
    [Closed](https://github.com/ipeaGIT/flightsbr/issues/7)
    [\#7](https://github.com/ipeaGIT/flightsbr/issues/7).

## flightsbr v0.0.1

CRAN release: 2022-01-21

- Launch of **flightsbr** v0.0.1 on CRAN
  <https://cran.r-project.org/package=flightsbr>
