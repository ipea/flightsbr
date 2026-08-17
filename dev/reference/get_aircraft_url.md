# Put together the url of aircraft data files

Put together the url of aircraft data files

## Usage

``` r
get_aircraft_url(date = parent.frame()$date)
```

## Arguments

- date:

  Numeric. Either a 6-digit date in the format `yyyymm` or a 4-digit
  date input `yyyy`. Defaults to `NULL`, in which case the function
  retrieves information for all years available.

## Value

A url string.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
a <- get_aircraft_url(202505)
} # \dontrun{}
```
