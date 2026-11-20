# Convert numeric-like columns to numeric

Candidate columns are those named like `nr_*`, `qt_*`, `comprimento_*`,
`largura_*`, `latgeopoint` and `longeopoint`, except identifiers that
must keep their leading zeros (e.g. flight numbers and serial numbers).
A candidate column is converted only if every non-missing value can be
read as a number. Otherwise it is left as character, so codes such as
airport or airline identifiers are never turned into `NA`. A message
lists the columns that were left as character because of a few stray
values.

## Usage

``` r
convert_to_numeric(dt)
```

## Arguments

- dt:

  A data.table with clean (lower case) column names. Modified by
  reference.

## Value

`TRUE`, invisibly.

## Details

Values with a decimal comma (`"1.500.000,00"`) have their thousands dots
removed; values without a comma are read as they are (`"360.0"`).
