# Download files from urls, reusing cached copies

Downloads each file to a temporary `.part` file and only moves it to
`dest_file` once the download succeeded and the content is not an HTML
page. A failed or blocked request therefore never leaves a file at
`dest_file`, so later calls with `cache = TRUE` cannot read an error
page as data.

## Usage

``` r
download_flightsbr_file(
  file_url = parent.frame()$file_url,
  showProgress = parent.frame()$showProgress,
  dest_file = fs::path(flightsbr_cache_dir(), basename(file_url)),
  cache = cache
)
```

## Arguments

- file_url:

  String. A url passed from above.

- showProgress:

  Logical, passed from above.

- dest_file:

  String. Local path(s) where the file(s) are saved, one per `file_url`.
  Defaults to the flightsbr cache directory (see
  [`flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/flightsbr_cache.md))
  plus `basename(file_url)`.

- cache:

  Logical, passed from above. If `FALSE`, existing files at `dest_file`
  are deleted and downloaded again.

## Value

`TRUE` (invisibly) if every file is available locally, otherwise `NULL`
(invisibly) with a message.

## Details

With `cache = TRUE`, a file already at `dest_file` is reused unless the
ANAC server reports a different size for it (checked with a HEAD
request). If the size can't be checked (no connection, no size header,
or ANAC answers with a web page), the cached file is reused.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
file_url <- get_flights_url(type='basica', date=200011)

# download data
download_flightsbr_file(file_url=file_url,
                        showProgress=TRUE,
                        dest_file = tempfile(fileext = ".zip")
                       )
} # \dontrun{}
```
