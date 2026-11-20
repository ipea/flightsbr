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
  previously. Defaults to `TRUE`. Downloaded files are cached in a
  folder that persists across R sessions (see
  [`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/reference/get_flightsbr_cache_dir.md)
  and
  [`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/reference/set_flightsbr_cache_dir.md)),
  and a cached file is downloaded again only if ANAC's copy has a
  different size. If `FALSE`, the function will always download the data
  and overwrite cached data. See
  [`list_flightsbr_cache()`](https://ipea.github.io/flightsbr/reference/list_flightsbr_cache.md)
  and
  [`delete_flightsbr_cache()`](https://ipea.github.io/flightsbr/reference/delete_flightsbr_cache.md)
  to manage cached files.

## Value

Numeric vector.

## Examples

``` r
if (FALSE)  if (interactive()) {
# check dates
a <- get_flight_dates_available()
} # \dontrun{}
```
