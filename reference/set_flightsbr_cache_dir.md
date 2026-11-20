# Set the folder where flightsbr caches downloaded data

flightsbr saves the files it downloads from ANAC in a cache folder, so
that each file is downloaded only once, even across R sessions. This
function sets which folder is used. The choice is saved and persists
across R sessions.

Files already cached in the previous folder are not moved. They stay
where they are until you delete them, for example with
[`delete_flightsbr_cache()`](https://ipea.github.io/flightsbr/reference/delete_flightsbr_cache.md)
before changing the folder.

## Usage

``` r
set_flightsbr_cache_dir(path = NULL, verbose = TRUE)
```

## Arguments

- path:

  String. The path to the folder used to cache downloaded data. If
  `NULL` (the default), flightsbr goes back to its default folder,
  `tools::R_user_dir("flightsbr", which = "cache")`.

- verbose:

  Logical. Whether to print a message with the cache folder. Defaults to
  `TRUE`.

## Value

Invisibly, the path to the cache folder.

## See also

Other Cache data:
[`delete_flightsbr_cache()`](https://ipea.github.io/flightsbr/reference/delete_flightsbr_cache.md),
[`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/reference/get_flightsbr_cache_dir.md),
[`list_flightsbr_cache()`](https://ipea.github.io/flightsbr/reference/list_flightsbr_cache.md)

## Examples

``` r
if (FALSE) { # interactive()
# use a custom folder
set_flightsbr_cache_dir(tempdir())

# go back to the default folder
set_flightsbr_cache_dir(NULL)
}
```
