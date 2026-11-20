# Read the links of an ANAC directory listing page

Read the links of an ANAC directory listing page

## Usage

``` r
read_anac_listing(url)
```

## Arguments

- url:

  String. Url of an ANAC directory listing.

## Value

A character vector of hrefs, or `NULL` if the page could not be read or
is not a directory listing (e.g. a page blocking the request).
