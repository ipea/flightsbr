# Directory where flightsbr caches downloaded files

The folder set with
[`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/set_flightsbr_cache_dir.md),
or by default `tools::R_user_dir("flightsbr", which = "cache")`, so
cached files persist across R sessions. See
[`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/get_flightsbr_cache_dir.md).

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
