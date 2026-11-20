# Expand requested years into the months available on ANAC

Expand requested years into the months available on ANAC

## Usage

``` r
available_months(date, all_dates)
```

## Arguments

- date:

  Numeric. Requested dates, either all `yyyymm` or all `yyyy` (already
  checked with
  [`check_date()`](https://ipea.github.io/flightsbr/reference/check_date.md)).

- all_dates:

  Numeric vector of `yyyymm` dates available on ANAC.

## Value

Numeric vector of `yyyymm` dates. `yyyymm` input is returned unchanged;
`yyyy` input is expanded to the months of those years that are
available, with a message listing the missing months.
