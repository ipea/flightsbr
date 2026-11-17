# Retrieve flight files available from the ANAC website

Retrieve flight files available from the ANAC website

## Usage

``` r
get_flights_files_available(cache = TRUE)
```

## Arguments

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

A data.table with columns `date`, `type`, and `url`.
