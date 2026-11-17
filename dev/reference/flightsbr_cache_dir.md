# Directory where flightsbr caches downloaded files

Defaults to `tools::R_user_dir("flightsbr", which = "cache")`, so cached
files persist across R sessions. It can be changed with
`options(flightsbr.cache_dir = "path/to/dir")`.

## Usage

``` r
flightsbr_cache_dir(create = TRUE)
```

## Arguments

- create:

  Logical. Whether to create the directory if it does not exist.
  Defaults to `TRUE`.

## Value

The path to the cache directory.
