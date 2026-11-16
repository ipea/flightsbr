# Pick one airfare file per month from the hrefs of ANAC's listings

ANAC's folders contain duplicates and stray files (re-uploads named
`yyyymm (1).csv`, `.CSV.csv` copies, the same month in two year folders,
`.txt` and `.csv` versions). This keeps files that follow the naming
convention and, for each month, prefers the file in the folder of its
own year, then a `.csv` over a `.txt`, then a name without `(1)`.

## Usage

``` r
airfare_files_from_hrefs(href, dom)
```

## Arguments

- href:

  Character vector of hrefs (relative or absolute).

- dom:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

## Value

A data.table with columns `date` (numeric) and `url` (the href).
