# Retrieve flight files available from the ANAC website

Retrieve flight files available from the ANAC website

## Usage

``` r
get_flights_files_available(cache = TRUE)
```

## Arguments

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A data.table with columns `date`, `type`, and `url`.
