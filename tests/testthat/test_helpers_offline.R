# Offline tests of internal helpers. No network access, so they also run on
# CRAN (no skip_on_cran() here).

# convert_to_numeric -----------------------------------------------------------

test_that("convert_to_numeric converts numbers and keeps codes", {

  dt <- data.table::data.table(
    nr_passageiros = c("1", "20", "null"),        # NA token
    nr_tarifa = c("1.500,25", "360.0", "2100,"),  # comma and dot decimals
    nr_aeroporto = c("SBGR", "SBRJ", "SBSP"),     # codes stay character
    nr_voo = c("0747", "1020", "0001"),           # identifier keeps zeros
    nr_escala = c("", "", ""),                    # all missing -> numeric NA
    nr_pmd = c("5 490", "5670kg", "2.850"),       # kg with units/separators
    latgeopoint = c("-13,866389", "-11.885", ",85"),
    other = c("1", "2", "3")                      # not a candidate
  )

  expect_silent(convert_to_numeric(dt))

  expect_equal(dt$nr_passageiros, c(1, 20, NA))
  expect_equal(dt$nr_tarifa, c(1500.25, 360, 2100))
  expect_type(dt$nr_aeroporto, "character")
  expect_equal(dt$nr_voo, c("0747", "1020", "0001"))
  expect_type(dt$nr_escala, "double")
  expect_true(all(is.na(dt$nr_escala)))
  expect_equal(dt$nr_pmd, c(5490, 5670, 2850))
  expect_equal(dt$latgeopoint, c(-13.866389, -11.885, 0.85))
  expect_type(dt$other, "character")
})

test_that("convert_to_numeric reports mostly-numeric columns it keeps", {

  dt <- data.table::data.table(
    nr_preco = c(as.character(1:20), "1,978,015.00")
  )

  expect_message(convert_to_numeric(dt), "nr_preco")
  expect_type(dt$nr_preco, "character")
})

test_that("parse_number_br reads Brazilian and international formats", {
  expect_equal(
    parse_number_br(c("1.500.000,00", "360.0", "-11.885", "12", NA)),
    c(1500000, 360, -11.885, 12, NA)
  )
})


# airports ---------------------------------------------------------------------

test_that("coordinates with a decimal comma are parsed", {

  dt <- data.table::data.table(
    latitude = c("30°50'39,8\"S", "08°07'34\"S"),
    longitude = c("051°09'08,04\"W", "034°55'23\"W")
  )
  latlon_to_numeric(dt)

  expect_false(anyNA(dt$latitude))
  expect_false(anyNA(dt$longitude))
  expect_equal(dt$latitude[1], -(30 + 50 / 60 + 39.8 / 3600), tolerance = 1e-6)
  expect_true(all(dt$longitude < 0))
})

test_that("altitude ',0' is missing, not zero", {

  dt <- data.table::data.table(altitude = c("512,3 m", ",0", "0,0"))
  altitude_to_numeric(dt)

  expect_equal(dt$altitude, c(512.3, NA, 0))
})


# dates -------------------------------------------------------------------------

test_that("available_months keeps only published months", {

  all_dates <- c(202409, 202410, 202411, 202412, 202501)

  expect_message(
    out <- available_months(2024, all_dates),
    "202401"
  )
  expect_equal(out, c(202409, 202410, 202411, 202412))

  # yyyymm input is returned as is
  expect_equal(available_months(c(202410, 202501), all_dates), c(202410, 202501))
})


# airfares ----------------------------------------------------------------------

test_that("airfare listings keep one file per month", {

  href <- c(
    "/sas/tarifadomestica/",
    "/sas/tarifadomestica/2026/202605%20(1).csv",
    "/sas/tarifadomestica/2026/202604.csv",
    "/sas/tarifadomestica/2024/202404.csv",
    "/sas/tarifadomestica/2024/202404.txt",
    "/sas/tarifadomestica/2024/202404%20(1).csv",
    "/sas/tarifadomestica/2021/2021-10.csv"
  )
  files <- airfare_files_from_hrefs(href, dom = TRUE)

  expect_equal(files$date, c(202404, 202604, 202605))
  expect_equal(basename(files$url), c("202404.csv", "202604.csv", "202605%20(1).csv"))

  href <- c(
    "/sas/tarifainternacional/2024/INTERNACIONAL_2023-04.csv",
    "/sas/tarifainternacional/2023/INTERNACIONAL_2023-04.csv",
    "/sas/tarifainternacional/2023/INTERNACIONAL_2023-05.CSV.csv",
    "/sas/tarifainternacional/2023/INTERNACIONAL_2023-05.csv",
    "/sas/tarifainternacional/2015/Internacional_2015-06.txt",
    "/sas/tarifainternacional/2015/INTERNACIONAL_2015-06.csv",
    "/sas/tarifainternacional/2023/202311.csv"
  )
  files <- airfare_files_from_hrefs(href, dom = FALSE)

  expect_equal(files$date, c(201506, 202304, 202305))
  expect_equal(
    files$url,
    c("/sas/tarifainternacional/2015/INTERNACIONAL_2015-06.csv",
      "/sas/tarifainternacional/2023/INTERNACIONAL_2023-04.csv",
      "/sas/tarifainternacional/2023/INTERNACIONAL_2023-05.csv")
  )
})

test_that("every airfare header version maps to the current names", {

  write_file <- function(header, row, encoding = "UTF-8") {
    path <- tempfile(fileext = ".csv")
    txt <- paste0(header, "\n", row, "\n")
    con <- file(path, "wb")
    writeBin(iconv(txt, "UTF-8", encoding, toRaw = TRUE)[[1]], con)
    close(con)
    path
  }

  dom <- c("nr_ano_referencia", "nr_mes_referencia", "sg_empresa_icao",
           "sg_icao_origem", "sg_icao_destino", "nr_tarifa", "nr_assentos")
  int <- c("nr_ano_referencia", "nr_mes_referencia", "sg_empresa_icao",
           "sg_icao_origem", "sg_icao_destino", "sg_icao_retorno",
           "cd_classe_ida", "cd_classe_volta", "nr_tarifa", "nr_assentos")

  pt_header <- paste0(
    "Ano de Referência;Mês de Referência;ICAO Empresa Aérea;",
    "ICAO Aeródromo Origem;ICAO Aeródromo Destino;Tarifa-N;",
    "Assentos Comercializados"
  )

  cases <- list(
    # domestic legacy
    list(write_file("ANO;MES;EMPRESA;ORIGEM;DESTINO;TARIFA;ASSENTOS",
                    "2002;1;TAM;SBGR;SBRJ;100,00;3"), dom),
    # domestic Portuguese headers, Latin-1 and UTF-8
    list(write_file(pt_header, "2020;1;GLO;SBGR;SBRJ;100,00;3", "latin1"), dom),
    list(write_file(pt_header, "2020;5;GLO;SBGR;SBRJ;100,00;3"), dom),
    # domestic with a leading row index
    list(write_file(paste0('"";', pt_header), '"1";2021;12;GLO;SBGR;SBRJ;100,00;3', "latin1"), dom),
    # domestic current
    list(write_file(paste(dom, collapse = ";"), "2026;1;GLO;SBGR;SBRJ;100.0;3"), dom),
    # international 2011-2016
    list(write_file(paste0(
      "ANO;MES;DESIGNADOR ICAO EMPRESA;DESIGNADOR ICAO AEROPORTO ORIGEM;",
      "DESIGNADOR ICAO AEROPORTO DESTINO;DESIGNADOR ICAO AEROPORTO RETORNO;",
      "CLASSE IDA;CLASSE RETORNO;VALOR TARIFA;ASSENTOS COMERCIALIZADOS"),
      "2011;1;TAM;SBGR;KMIA;SBGR;Y;Y;2464,00;1"), int),
    # international 2017-2024
    list(write_file("ANO;MES;EMPRESA;ORIGEM;DESTINO;RETORNO;CLASSE IDA;CLASSE VOLTA;TARIFA;ASSENTOS",
                    "2024;12;TAM;SBGR;KMIA;SBGR;Y;Y;642,60;1"), int),
    # international 2023-05 to 2023-07: row index, no fare classes
    list(write_file(paste0(
      '"";"Ano de Referência";"Mês de Referência";"ICAO Empresa Aérea";',
      '"ICAO Aeródromo Origem";"ICAO Aeródromo Destino";"ICAO Aeródromo Retorno";',
      '"Tarifa-Nominal";"Assentos"'),
      '"1";2023;5;"AAL";"SBGL";"KMIA";"9999";"2100,";3', "latin1"),
      setdiff(int, c("cd_classe_ida", "cd_classe_volta")))
  )

  for (case in cases) {
    dt <- read_airfare_file(case[[1]])
    expect_equal(names(dt), case[[2]])
  }
})

test_that("unknown airfare columns fail loudly", {
  dt <- data.table::data.table(ano = "2020", nova_coluna = "x")
  expect_error(harmonize_airfare_names(dt, "x.csv"), "nova_coluna")
})

test_that("select accepts old and current airfare names", {
  expect_equal(
    airfare_canonical_names(c("TARIFA", "ano", "nr_tarifa", "VALOR_TARIFA", "banana")),
    c("nr_tarifa", "nr_ano_referencia", "nr_tarifa", "nr_tarifa", NA)
  )
})


# downloads ---------------------------------------------------------------------

test_that("HTML pages are not accepted as data files", {

  html <- tempfile()
  writeLines("  <!DOCTYPE html><html><body>Requisição Bloqueada</body></html>", html)

  csv <- tempfile()
  writeBin(iconv("ANO;MES\n2020;1\n", "UTF-8", "latin1", toRaw = TRUE)[[1]], csv)

  expect_true(starts_like_html(html))
  expect_false(starts_like_html(csv))
  expect_false(starts_like_html(tempfile()))  # missing file

  resp_html <- httr2::response(200, headers = list(`Content-Type` = "text/html"))
  resp_csv <- httr2::response(200, headers = list(`Content-Type` = "application/octet-stream"))

  expect_true(is_html_response(resp_html, csv))
  expect_false(is_html_response(resp_csv, csv))
  expect_true(is_html_response(resp_csv, html))
})


# RAB ---------------------------------------------------------------------------

test_that("RAB files: MARCA becomes MARCAS, null becomes NA, quotes un-escaped", {

  path <- file.path(tempdir(), "2026-01.csv")
  writeLines(c(
    "Atualizado em: 2026-01-31",
    '"MARCA";"PROPRIETARIOS";"NR_ASSENTOS"',
    '"PRABC";"[{""NOME"":""JOAO""}]";"null"',
    '"PRXYZ";"";"4"'
  ), path)

  dt <- read_aircraft_file(path)

  expect_true("MARCAS" %in% names(dt))
  expect_false("MARCA" %in% names(dt))
  expect_equal(dt$PROPRIETARIOS, c('[{"NOME":"JOAO"}]', NA))
  expect_equal(dt$NR_ASSENTOS, c(NA, "4"))
  expect_equal(dt$reference_date, c("202601", "202601"))
})


# cli messages -----------------------------------------------------------------

test_that("check_flag accepts only a single TRUE or FALSE", {

  f <- function(showProgress) check_flag(showProgress, "showProgress")

  expect_silent(f(TRUE))
  expect_silent(f(FALSE))

  # the error names the argument and the calling function, not check_flag()
  err <- expect_error(f(NA), "showProgress")
  expect_identical(err$call, quote(f(NA)))
  expect_error(f(c(TRUE, FALSE)), "showProgress")
  expect_error(f("banana"), "showProgress")
  expect_error(f(NULL), "showProgress")
})

test_that("values with braces are printed literally in cli messages", {

  # cli evaluates {} in its templates: ANAC values must never be part of the
  # template, or a stray brace would break (or run code in) the message
  dt <- data.table::data.table(
    nr_preco = c(as.character(1:20), "{1,978}")
  )

  expect_message(convert_to_numeric(dt), "{1,978}", fixed = TRUE)
  expect_type(dt$nr_preco, "character")
})
