# Download airport movement data from Brazil

Download airport movements data from Brazil’s Civil Aviation Agency
(ANAC). The data covers all passenger, aircraft, cargo and mail movement
data from airports regulated by ANAC. Data only available from Jan 2019
onwards. A description of all variables included in the data is
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
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A `"data.table" "data.frame"` object. All columns are returned with
`class` of type `"character"`.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read airport movement data
amov202006 <- read_airport_movements(date = 202006)

amov2020 <- read_airport_movements(date = 2020)
} # \dontrun{}
```
