# Download and read ANAC air fares data

Download and read ANAC air fares data

## Usage

``` r
download_airfares_data(
  file_urls = parent.frame()$file_urls,
  showProgress = parent.frame()$showProgress,
  cache = parent.frame()$cache
)
```

## Arguments

- file_urls:

  String. A url passed from above.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

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

A `"data.table" "data.frame"` object with harmonized column names, or
`NULL` if the download failed.

## Examples

``` r
if (FALSE)  if (interactive()) {
files <- get_airfares_files_available(dom = TRUE)

a <- download_airfares_data(file_urls = files$url[1], showProgress = TRUE)
} # \dontrun{}
```
