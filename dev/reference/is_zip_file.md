# Check whether local files are zip archives

Reads the first two bytes of each file and checks for the zip signature
`PK`. ANAC sometimes returns an HTML page with HTTP status 200 instead
of the requested zip file.

## Usage

``` r
is_zip_file(path)
```

## Arguments

- path:

  Character vector of local file paths.

## Value

A logical vector, `FALSE` for files that are missing, empty, or not zip
archives.
