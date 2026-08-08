# Put together the url of airport movement data files

Put together the url of airport movement data files

## Usage

``` r
get_airport_movements_url(date = parent.frame()$date)
```

## Arguments

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
# Generate url
a <- get_airport_movements_url(year=2000, month=11)
} # \dontrun{}
```
