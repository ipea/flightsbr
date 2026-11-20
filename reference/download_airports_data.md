# Download and read one ANAC airports file

Download and read one ANAC airports file

## Usage

``` r
download_airports_data(file_url, airport_type, showProgress, cache)
```

## Arguments

- file_url:

  String. Url of the public or private airports file.

- airport_type:

  String. `"public"` or `"private"`, stored in the `type` column.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

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

A `"data.table" "data.frame"` object, or `NULL` if the download failed.
