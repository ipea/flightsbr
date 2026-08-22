# Retrieve all dates available for airfares data from ANAC website

Retrieve all dates available for airfares data from ANAC website

## Usage

``` r
get_airfares_dates_available(dom, cache = TRUE)
```

## Arguments

- dom:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

Numeric vector.

## Examples

``` r
if (FALSE)  if (interactive()) {
# check dates
a <- get_airfares_dates_available(domestic = TRUE)
} # \dontrun{}
```
