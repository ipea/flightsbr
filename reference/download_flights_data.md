# Download and read ANAC flight data

Download and read ANAC flight data

## Usage

``` r
download_flights_data(
  file_url = parent.frame()$file_url,
  showProgress = parent.frame()$showProgress,
  select = parent.frame()$select,
  cache = parent.frame()$cache
)
```

## Arguments

- file_url:

  String. An ANAC url passed from above.

- showProgress:

  Logical, passed from above.

- select:

  A vector of column names or numbers to keep, passed from above.

- cache:

  Logical, passed from above.

## Value

A `"data.table" "data.frame"` object

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
file_url <- get_flights_files_available()$url[1]

# download data
a <- download_flights_data(
  file_url=file_url,
  showProgress=TRUE,
  select=NULL,
  cache=TRUE
  )
} # \dontrun{}
```
