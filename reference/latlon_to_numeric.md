# Convert latitude and longitude columns to numeric

Coordinates are written in degrees, minutes and seconds (e.g.
`30\u00b050'39,8"S`). Some files use a decimal comma in the seconds,
which `parzer` can't read, so commas are replaced with dots first.

## Usage

``` r
latlon_to_numeric(df)
```

## Arguments

- df:

  A data.table internal to the
  [`read_airports()`](https://ipea.github.io/flightsbr/reference/read_airports.md)
  function.

## Value

A `"data.table" "data.frame"` object, modified by reference.
