# Put together the url of airfare data files

Put together the url of airfare data files

## Usage

``` r
get_airfares_url(dom, date = parent.frame()$date)
```

## Arguments

- dom:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

- date:

  Numeric. Date of the data in the format `yyyymm`. To download the data
  for all months in a year, the user can pass a 4-digit year input
  `yyyy`. The parameter also accepts a vector of dates such as
  `c(202001, 202006, 202012)`.

## Value

A url string.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
a <- get_airfares_url(year=2002, month=11)
} # \dontrun{}
```
