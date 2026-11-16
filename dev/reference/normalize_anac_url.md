# Turn an ANAC (gov.br) file href into a direct download url

The flight file listing on gov.br links to each zip file through a
relative href (e.g. `/anac/.../basica2020-04.zip`) that serves an HTML
landing page. The zip file itself is served at `<href>/@download/file`.

## Usage

``` r
normalize_anac_url(href, base)
```

## Arguments

- href:

  Character vector of hrefs, relative or absolute, with or without the
  `/@download/file` suffix.

- base:

  String. Url of the page the hrefs were scraped from, used to resolve
  relative hrefs.

## Value

A character vector of absolute urls ending in `/@download/file`.
