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
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A `"data.table" "data.frame"` object, or `NULL` if the download failed.
