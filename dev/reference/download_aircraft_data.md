# Download and read ANAC aircraft data

Download and read ANAC aircraft data

## Usage

``` r
download_aircraft_data(
  file_url = parent.frame()$file_url,
  showProgress = parent.frame()$showProgress,
  cache = parent.frame()$cache
)
```

## Arguments

- file_url:

  String. A url passed from
  [`get_flights_url`](https://ipeagit.github.io/flightsbr/dev/reference/get_flights_url.md).

- showProgress:

  Logical, passed from
  [`read_flights`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)

- cache:

  Logical, passed from
  [`read_flights`](https://ipeagit.github.io/flightsbr/dev/reference/read_flights.md)

## Value

A `"data.table" "data.frame"` object

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
file_url <- get_airfares_url(dom = TRUE, year=2002, month=11)

# download data
a <- download_airfares_data(file_url=file_url, showProgress=TRUE, select=NULL)
} # \dontrun{}
```
