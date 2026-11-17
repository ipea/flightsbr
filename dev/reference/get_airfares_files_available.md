# Retrieve the airfare files available on the ANAC website

Scrapes ANAC's directory listing (one request per year folder) and keeps
one file per month. The result is cached for the R session. If some year
folders could not be read, the result has an attribute `failed_years`
with those years.

## Usage

``` r
get_airfares_files_available(dom, cache = TRUE)
```

## Arguments

- dom:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

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

A data.table with columns `date` (numeric, `yyyymm`) and `url`, or
`NULL` if ANAC could not be reached.
