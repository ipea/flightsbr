# Delete data cached by flightsbr

Deletes files from the flightsbr cache folder (see
[`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/get_flightsbr_cache_dir.md)):
all cached files, or only the ones named in `file`.

## Usage

``` r
delete_flightsbr_cache(file = NULL, verbose = TRUE)
```

## Arguments

- file:

  String. Names of cached files to delete, for example
  `"basica2000-01.zip"` (see
  [`list_flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/list_flightsbr_cache.md)).
  If `NULL` (the default), all cached files are deleted.

- verbose:

  Logical. Whether to print a message saying what was deleted. Defaults
  to `TRUE`.

## Value

Invisibly, the path to the cache folder.

## Details

Only files saved directly in the cache folder are deleted. Subfolders
and their content are never touched, so pointing the cache at a folder
that also holds other things (see
[`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/set_flightsbr_cache_dir.md))
can't wipe them out. The cache folder itself is removed if it ends up
empty.

## See also

Other Cache data:
[`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/get_flightsbr_cache_dir.md),
[`list_flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/list_flightsbr_cache.md),
[`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/set_flightsbr_cache_dir.md)

## Examples

``` r
if (FALSE) { # interactive()
# delete one file
delete_flightsbr_cache("basica2000-01.zip")

# delete all cached files
delete_flightsbr_cache()
}
```
