# Retrieve all dates available for airfares data from ANAC website

Retrieve all dates available for airfares data from ANAC website

## Usage

``` r
get_airfares_dates_available(dom)
```

## Arguments

- dom:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

## Value

Numeric vector.

## Examples

``` r
if (FALSE)  if (interactive()) {
# check dates
a <- get_airfares_dates_available(domestic = TRUE)
} # \dontrun{}
```
