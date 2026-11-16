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

  String. A url passed from above.

- showProgress:

  Logical, passed from
  [`read_flights`](https://ipea.github.io/flightsbr/dev/reference/read_flights.md)

- cache:

  Logical, passed from
  [`read_flights`](https://ipea.github.io/flightsbr/dev/reference/read_flights.md)

## Value

A `"data.table" "data.frame"` object

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
file_url <- get_aircraft_url(date = 202409)

# download data
a <- download_aircraft_data(file_url = file_url, showProgress = TRUE, cache = TRUE)
} # \dontrun{}
```
