# Download airports data from Brazil

Download data of all airports and aerodromes registered in Brazil’s
Civil Aviation Agency (ANAC). Data source:
<https://www.gov.br/anac/pt-br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos>.
The data dictionary for public airports can be found at
<https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-publicos-v2/70-lista-de-aerodromos-publicos-v2>.
The data dictionary for private airports can be found at
<https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2>.

## Usage

``` r
read_airports(type = "all", showProgress = TRUE, cache = TRUE)
```

## Arguments

- type:

  String. Whether the function should download data on `all`, `public`
  or `private` airports. Defaults to `all`, returning fewer columns.
  Downloading `public` and `private` airports separately will return the
  full set of columns available for each of those data sets.

- showProgress:

  Logical. Defaults to `TRUE` display progress.

- cache:

  Logical. Whether the function should read cached data downloaded
  previously. Defaults to `TRUE`. If `FALSE`, the function will always
  download the data and overwrite cached data.

## Value

A `"data.table" "data.frame"` object.

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read airports data
all_airports <- read_airports(type = 'all')

public_airports <- read_airports(type = 'public')

private_airports <- read_airports(type = 'private')
} # \dontrun{}
```
