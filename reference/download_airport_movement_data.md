# Download and read ANAC airport movement data

Download and read ANAC airport movement data

## Usage

``` r
download_airport_movement_data(
  file_url = parent.frame()$file_url,
  showProgress = parent.frame()$showProgress,
  cache = parent.frame()$cache
)
```

## Arguments

- file_url:

  String. A url passed from
  [`read_airport_movements`](https://ipeagit.github.io/flightsbr/reference/read_airport_movements.md).

- showProgress:

  Logical, passed from
  [`read_airport_movements`](https://ipeagit.github.io/flightsbr/reference/read_airport_movements.md)

- cache:

  Logical, passed from
  [`read_airport_movements`](https://ipeagit.github.io/flightsbr/reference/read_airport_movements.md)

## Value

A `"data.table" "data.frame"` object

## Examples

``` r
if (FALSE)  if (interactive()) {
# Generate url
file_url <- get_airport_movements_url(year=2020, month=11)

# download data
a <- download_airport_movement_data(file_url=file_url, showProgress=TRUE)
} # \dontrun{}
```
