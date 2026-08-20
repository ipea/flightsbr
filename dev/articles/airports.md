# Airport data

The airport data in the **flightsbr** package is downloaded from
Brazil’s Civil Aviation Agency (ANAC). The data covers all airports and
aerodromes registered in ANAC. It brings detailed information
on….\[mention a few key variables\].

- Data dictionary:
  - [Public
    airports](https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-publicos-v2/70-lista-de-aerodromos-publicos-v2).
  - [Private
    airports](https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2).

Before downloading the data, let’s first load the libraries we’ll use in
this vignette:

``` r

library(flightsbr)
library(ggplot2)
# library(geobr)
```

Now, downloading data of all airports in Brazil is as simple as this:

``` r

# private airports
airports_prv <- flightsbr::read_airports(
  type = 'private', 
  showProgress = FALSE
  )

# public airports
airports_pbl <- flightsbr::read_airports(
  type = 'public', 
  showProgress = FALSE
  )
```

You will notice that the data sets on private and public airports have
different columns. This can make row binding these data.frames a bit
tricky. For now, the function
[`read_airports()`](https://ipeagit.github.io/flightsbr/dev/reference/read_airports.md)
can return a data.frame with both types of airports and only a few
columns if the user set `type = "all"`. The geographical coordinates are
provided in `EPSG Projection 4326 - WGS 84`.

``` r

airports_all <- flightsbr::read_airports(
  type = 'all', 
  showProgress = FALSE
  )

# plot
# brazil <- geobr::read_country()

ggplot() +
   # geom_sf(data=brazil, color='gray') +
  geom_point(data=airports_all, aes(x=longitude, y=latitude), size=.3 , alpha=.4) +
  coord_equal()
```

![](https://github.com/ipea/flightsbr/blob/main/inst/img/vig_output_airports.png?raw=true)
