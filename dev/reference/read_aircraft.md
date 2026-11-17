# Download aircraft data from Brazil

Download data of all aircraft registered in the Brazilian Aeronautical
Registry (Registro Aeronáutico Brasileiro - RAB), organized by the
Brazilian Civil Aviation Agency (ANAC). A description of all variables
included in the data is available at
<https://www.gov.br/anac/pt-br/sistemas/rab>.

## Usage

``` r
read_aircraft(date = NULL, showProgress = TRUE, cache = TRUE)
```

## Arguments

- date:

  Numeric. Date of the data in the format `yyyymm`. Defaults to the
  latest date available. To download the data for all months in a year,
  the user can pass a 4-digit year input `yyyy`. The function also
  accepts a vector of dates, like `c(202201, 202301)` or
  `c(2022, 2024)`.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. Downloaded files are cached in
  `tools::R_user_dir("flightsbr", which = "cache")`, so they persist
  across R sessions, and a cached file is downloaded again only if
  ANAC's copy has a different size. If `FALSE`, the function will always
  download the data and overwrite cached data. See
  [`flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/flightsbr_cache.md)
  to list or delete cached files.

## Value

A `"data.table" "data.frame"` object. Columns of counts and measures are
numeric; codes and identifiers (e.g. flight numbers, serial numbers,
airport codes) are character, keeping leading zeros. A column with some
values that are not numbers stays character, with a message.

## See also

Other download flight data:
[`read_aircrafts()`](https://ipea.github.io/flightsbr/dev/reference/read_aircrafts.md),
[`read_flights()`](https://ipea.github.io/flightsbr/dev/reference/read_flights.md)

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read aircraft data
aircraft <- read_aircraft(date = 202409,
                          showProgress = TRUE
                          )


} # \dontrun{}
```
