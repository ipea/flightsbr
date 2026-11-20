# Read one RAB file

Reads a monthly RAB file and makes the layouts ANAC has used comparable:
the registration mark column is always `MARCAS` (it was `MARCA` until
early 2026), empty cells and the text `"null"` become `NA`, and quotes
escaped as `""` inside a field (used in the JSON owner and operator
columns) are un-escaped.

## Usage

``` r
read_aircraft_file(path, showProgress = FALSE)
```

## Arguments

- path:

  String. Local file path. The file name must be `yyyy-mm.csv`.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

## Value

A data.table with raw (upper case) column names and a `reference_date`
column.
