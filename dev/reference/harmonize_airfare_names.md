# Rename airfare columns to ANAC's current names

ANAC has used five different headers for the same columns over the
years. Every version is mapped to the names ANAC uses in its current
files (see `airfare_col_map`), so files from different periods bind into
the same columns. A leading row-index column (empty header) is dropped.

## Usage

``` r
harmonize_airfare_names(dt, file_name = "")
```

## Arguments

- dt:

  A data.table read from an airfare file. Modified by reference.

- file_name:

  String. File name, used in error messages.

## Value

`dt`, invisibly.
