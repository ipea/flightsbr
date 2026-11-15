# Download file from url

Download file from url

## Usage

``` r
download_flightsbr_file(
  file_url = parent.frame()$file_url,
  showProgress = parent.frame()$showProgress,
  dest_file = fs::path(fs::path_temp(), basename(file_url)),
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
  Defaults to the temp dir plus `basename(file_url)`.

- cache:

  Logical, passed from above.

## Value

Silently saves downloaded file to temp dir.

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
