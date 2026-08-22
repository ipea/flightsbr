# Check whether the format of the date input is acceptable

Check whether the format of the date input is acceptable

## Usage

``` r
check_input_date_format(date = parent.frame()$date)
```

## Arguments

- date:

  Vector. Either a 6-digit date in the format `yyyymm` or a 4-digit date
  input `yyyy` .

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
