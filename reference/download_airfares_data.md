# Download and read ANAC air fares data

Download and read ANAC air fares data

## Usage

``` r
download_airfares_data(
  file_urls = parent.frame()$file_urls,
  showProgress = parent.frame()$showProgress,
  select = parent.frame()$select,
  cache = parent.frame()$cache
)
```

## Arguments

- file_urls:

  String. A url passed from above.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

- select:

  A vector of column names or positions to keep. The rest of the columns
  are not read. The order that the columns passed determines the order
  of the columns in the result.

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A `"data.table" "data.frame"` object

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
file_url <- get_airfares_url(dom = TRUE, date=200211)

# download data
a <- download_airfares_data(file_urls=file_url, showProgress=TRUE, select=NULL)
} # \dontrun{}
```
