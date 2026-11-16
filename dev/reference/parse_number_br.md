# Parse numbers written in Brazilian or international format

Parse numbers written in Brazilian or international format

## Usage

``` r
parse_number_br(x)
```

## Arguments

- x:

  Character vector.

## Value

Numeric vector. Values with a decimal comma have their thousands dots
removed first; values without a comma are parsed as they are.
