# Check whether date input is acceptable

Check whether date input is acceptable

## Usage

``` r
check_date(date, all_dates)
```

## Arguments

- date:

  Numeric. Either a 6-digit date in the format `yyyymm` or a 4-digit
  date input `yyyy` .

- all_dates:

  Numeric vector created with the get_all_dates_available() function.

## Value

Check messages.

## Examples

``` r
if (FALSE)  if (interactive()) {

# get all dates available
all_dates <- get_all_dates_available()

# check dates
a <- check_date(200011, all_dates)
} # \dontrun{}
```
