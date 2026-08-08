# Put together the url of flight data files

Put together the url of flight data files

## Usage

``` r
get_flights_url(type, date)
```

## Arguments

- type:

  String. Whether the data set should be of the type `basica` (flight
  stage, the default) or `combinada` (On flight origin and destination -
  OFOD).

- date:

  Numeric. Date of the data in the format `yyyymm`. Defaults to
  `202001`. To download the data for all months in a year, the user can
  pass a 4-digit year input `yyyy`. The parameter also accepts a vector
  of dates such as `c(202001, 202006, 202012)`.

## Value

A url string.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate urls
a <- get_flights_url(type='basica', year=2000, month=11)
} # \dontrun{}
```
