# Download aircrafts data from Brazil

**\[deprecated\]**

This function was deprecated in favor of
[`read_aircraft()`](https://ipeagit.github.io/flightsbr/reference/read_aircraft.md)
simply to fix a typo in the function name.

## Usage

``` r
read_aircrafts(date = 202001, showProgress = TRUE, cache = TRUE)
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
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A `"data.table" "data.frame"` object. All columns are returned with
`class` of type `"character"`.

## See also

Other download flight data:
[`read_aircraft()`](https://ipeagit.github.io/flightsbr/reference/read_aircraft.md),
[`read_flights()`](https://ipeagit.github.io/flightsbr/reference/read_flights.md)

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read aircraft data
aircraft <- read_aircraft(date = 202001,
                          showProgress = TRUE)

} # \dontrun{}
```
