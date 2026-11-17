# Retrieve all dates available for flights data from ANAC website

Retrieve all dates available for flights data from ANAC website

## Usage

``` r
get_flight_dates_available(type = NULL, cache = TRUE)
```

## Arguments

- type:

  String. Whether the data set should be of the type `basica` (flight
  stage, the default) or `combinada` (On flight origin and destination -
  OFOD).

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

Numeric vector.

## Examples

``` r
if (FALSE)  if (interactive()) {
# check dates
a <- get_flight_dates_available()
} # \dontrun{}
```
