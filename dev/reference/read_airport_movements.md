# Download airport movement data from Brazil

Download airport movements data from Brazil’s Civil Aviation Agency
(ANAC). The data covers all passenger, aircraft, cargo and mail movement
data from airports regulated by ANAC. Data only available from March
2019 onwards. A description of all variables included in the data is
available at
<https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/operador-aeroportuario/dados-de-movimentacao-aeroportuaria/60-dados-de-movimentacao-aeroportuaria>.

## Usage

``` r
read_airport_movements(date = NULL, showProgress = TRUE, cache = TRUE)
```

## Arguments

- date:

  Numeric. Date of the data in the format `yyyymm`. Defaults to the
  latest date available. To download the data for all months in a year,
  the user can pass a 4-digit year input `yyyy`. The function also
  accepts a vector of dates, like `c(202201, 202301)` or
  `c(2022, 2024)`.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. Downloaded files are cached in a
  folder that persists across R sessions (see
  [`get_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/get_flightsbr_cache_dir.md)
  and
  [`set_flightsbr_cache_dir()`](https://ipea.github.io/flightsbr/dev/reference/set_flightsbr_cache_dir.md)),
  and a cached file is downloaded again only if ANAC's copy has a
  different size. If `FALSE`, the function will always download the data
  and overwrite cached data. See
  [`list_flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/list_flightsbr_cache.md)
  and
  [`delete_flightsbr_cache()`](https://ipea.github.io/flightsbr/dev/reference/delete_flightsbr_cache.md)
  to manage cached files.

## Value

A `"data.table" "data.frame"` object. Columns of counts and measures are
numeric; codes and identifiers (e.g. flight numbers, serial numbers,
airport codes) are character, keeping leading zeros. A column with some
values that are not numbers stays character, with a message.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read airport movement data
amov202006 <- read_airport_movements(date = 202006)

amov2020 <- read_airport_movements(date = 2020)
} # \dontrun{}
```
