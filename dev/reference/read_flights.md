# Download flight data from Brazil

Download flight data from Brazil’s Civil Aviation Agency (ANAC). The
data includes detailed information on every international flight to and
from Brazil, as well as domestic flights within the country. The data
include flight-level information of airports of origin and destination,
flight duration, aircraft type, payload, and the number of passengers,
and several other variables. A description of all variables included in
the data is available at
<https://www.gov.br/anac/pt-br/assuntos/regulados/empresas-aereas/Instrucoes-para-a-elaboracao-e-apresentacao-das-demonstracoes-contabeis/descricao-de-variaveis>.

## Usage

``` r
read_flights(
  date = NULL,
  type = "basica",
  showProgress = TRUE,
  select = NULL,
  cache = TRUE
)
```

## Arguments

- date:

  Numeric. Date of the data in the format `yyyymm`. Defaults to the
  latest available month. To download the data for all months in a year,
  the user can pass a 4-digit year input `yyyy`. The parameter also
  accepts a vector of dates such as `c(202001, 202006, 202012)`.

- type:

  String. Whether the data set should be of the type `basica` (flight
  stage, the default) or `combinada` (On flight origin and destination -
  OFOD).

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

A `"data.table" "data.frame"` object. All columns are returned with
`class` of type `"character"`.

## See also

Other download flight data:
[`read_aircraft()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircraft.md),
[`read_aircrafts()`](https://ipeagit.github.io/flightsbr/dev/reference/read_aircrafts.md)

## Examples

``` r
if (FALSE)  if (interactive()) {
# Read flights data
f201506 <- read_flights(date = 201506)

f2015 <- read_flights(date = 2015)
} # \dontrun{}
```
