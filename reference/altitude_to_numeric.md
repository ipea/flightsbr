# Convert altitude column to numeric

Altitudes are written like `"512,3 m"`. A value with no digit before the
decimal comma (`",0"`) is how ANAC marks a missing altitude, so it
becomes `NA`.

## Usage

``` r
altitude_to_numeric(df)
```

## Arguments

- df:

  A data.table internal to the
  [`read_airports()`](https://ipea.github.io/flightsbr/reference/read_airports.md)
  function.

## Value

A `"data.table" "data.frame"` object, modified by reference.
