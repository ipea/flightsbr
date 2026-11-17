# Get the folder where flightsbr caches downloaded data

Returns the folder used to cache data downloaded by flightsbr: the
folder set with
[`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/set_flightsbr_cache_dir.md),
possibly in a previous R session, or the default folder,
`tools::R_user_dir("flightsbr", which = "cache")`.

## Usage

``` r
get_flightsbr_cache_dir()
```

## Value

String. The path to the cache folder. The folder may not exist yet if no
data has been downloaded.

## See also

Other Cache data:
[`delete_flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/delete_flightsbr_cache.md),
[`list_flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/list_flightsbr_cache.md),
[`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/set_flightsbr_cache_dir.md)

## Examples

``` r
get_flightsbr_cache_dir()
#> [1] "/home/runner/.cache/R/flightsbr"
```
