# Download data on airfares flights in Brazil

Download data on air fares of domestic and international flights in
Brazil. The data is collected by Brazil’s Civil Aviation Agency (ANAC).
A description of all variables included in the data for domestic
airfares is available at
<https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/voos-e-operacoes-aereas/tarifas-aereas-domesticas/46-tarifas-aereas-domesticas>.
A description of all variables included in the data for international
airfares is available at
<https://www.gov.br/anac/pt-br/assuntos/dados-e-estatisticas/microdados-de-tarifas-aereas-comercializadas>.

## Usage

``` r
read_airfares(
  date = NULL,
  domestic = TRUE,
  showProgress = TRUE,
  select = NULL,
  cache = TRUE
)
```

## Arguments

- date:

  Numeric. Date of the data in the format `yyyymm`. Defaults to the
  latest date available. To download the data for all months in a year,
  the user can pass a 4-digit year input `yyyy`. The function also
  accepts a vector of dates, like `c(202201, 202301)` or
  `c(2022, 2024)`.

- domestic:

  Logical. Defaults to `TRUE` download airfares of domestic flights. If
  `FALSE`, the function downloads airfares of international flights.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

- select:

  A vector of column names or positions to keep. The rest of the columns
  are not read. The order that the columns passed determines the order
  of the columns in the result.

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A `"data.table" "data.frame"` object.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read air fare data
af_201506 <- read_airfares(date = 201506, domestic = TRUE)

af_2015 <- read_airfares(date = 2015, domestic = TRUE)
} # \dontrun{}
```
