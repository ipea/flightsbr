# Check the date of the latest airfare data available

Check the date of the latest airfare data available

## Usage

``` r
latest_airfares_date(dom = TRUE)
```

## Arguments

- dom:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

## Value

A numeric date in the format `yyyymm`.

## See also

Other support function:
[`latest_flights_date()`](https://ipeagit.github.io/flightsbr/reference/latest_flights_date.md)

## Examples

``` r
if (FALSE)  if (interactive()) {

latest_date <- latest_airfares_date()

} # \dontrun{}
```
