# Manage the cache of files downloaded by flightsbr

flightsbr keeps the files it downloads from ANAC in a cache directory,
so that each file is downloaded only once, even across R sessions. This
function lists the cached files and deletes some or all of them.

By default, the cache lives in
`tools::R_user_dir("flightsbr", which = "cache")`. You can use another
folder with `options(flightsbr.cache_dir = "path/to/folder")`.

## Usage

``` r
flightsbr_cache(list_files = TRUE, delete_file = NULL)
```

## Arguments

- list_files:

  Logical. Whether to print a message listing the files in the cache.
  Defaults to `TRUE`.

- delete_file:

  String. The name of a cached file to delete (for example
  `"basica2000-01.zip"`), or `"all"` to delete every cached file.
  Defaults to `NULL`, which deletes nothing.

## Value

Invisibly, a character vector with the paths of the files left in the
cache.

## Examples

``` r
# list the files in the cache
flightsbr_cache()
#> The flightsbr cache is empty: /home/runner/.cache/R/flightsbr

if (FALSE)  if (interactive()) {
# delete one file
flightsbr_cache(delete_file = "basica2000-01.zip")

# delete all files
flightsbr_cache(delete_file = "all")
} # \dontrun{}
```
