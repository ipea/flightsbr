# List the data cached by flightsbr

Lists the files saved in the flightsbr cache folder (see
[`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/reference/get_flightsbr_cache_dir.md)).

## Usage

``` r
list_flightsbr_cache(print_tree = FALSE)
```

## Arguments

- print_tree:

  Logical. Whether to print the content of the cache folder as a tree.
  Defaults to `FALSE`.

## Value

A character vector with the paths of the cached files (invisibly when
`print_tree = TRUE`). An empty vector if nothing is cached.

## See also

Other Cache data:
[`delete_flightsbr_cache()`](https://ipea.github.io/flightsbr/reference/delete_flightsbr_cache.md),
[`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/reference/get_flightsbr_cache_dir.md),
[`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/reference/set_flightsbr_cache_dir.md)

## Examples

``` r
list_flightsbr_cache()
#> The flightsbr cache is empty: /home/runner/.cache/R/flightsbr
#> character(0)

list_flightsbr_cache(print_tree = TRUE)
#> The flightsbr cache is empty: /home/runner/.cache/R/flightsbr
#> character(0)
```
