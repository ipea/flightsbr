context("ANAC download urls")

# these tests are offline and fast, so they run on CRAN too

base <- "https://www.gov.br"
href <- paste0(
  "/anac/pt-br/assuntos/regulados/empresas-aereas/",
  "Instrucoes-para-a-elaboracao-e-apresentacao-das-demonstracoes-contabeis/",
  "envio-de-informacoes/basica/2020/basica2020-04.zip"
)
expected <- paste0(base, href, "/@@download/file")

# page the hrefs are scraped from
page <- paste0(
  base,
  "/anac/pt-br/assuntos/regulados/empresas-aereas/",
  "Instrucoes-para-a-elaboracao-e-apresentacao-das-demonstracoes-contabeis/",
  "envio-de-informacoes"
)

test_that("normalize_anac_url builds direct download urls", {

  # relative href
  testthat::expect_equal(normalize_anac_url(href, page), expected)

  # absolute url
  testthat::expect_equal(normalize_anac_url(paste0(base, href), page), expected)

  # absolute url on another host is kept as is
  testthat::expect_equal(
    normalize_anac_url("https://example.org/a/basica2020-04.zip", page),
    "https://example.org/a/basica2020-04.zip/@@download/file"
  )

  # suffix already present is not duplicated
  testthat::expect_equal(normalize_anac_url(expected, page), expected)
  testthat::expect_equal(
    normalize_anac_url(paste0(href, "/@@download/file"), page),
    expected
  )

  # trailing slash
  testthat::expect_equal(normalize_anac_url(paste0(href, "/"), page), expected)

  # vectorised
  testthat::expect_equal(
    normalize_anac_url(c(href, expected), page),
    c(expected, expected)
  )
})


test_that("anac_file_name returns the zip name, not 'file'", {

  testthat::expect_equal(anac_file_name(expected), "basica2020-04.zip")
  testthat::expect_equal(anac_file_name(paste0(base, href)), "basica2020-04.zip")
  testthat::expect_equal(
    anac_file_name(c(expected, sub("2020-04", "2020-05", expected))),
    c("basica2020-04.zip", "basica2020-05.zip")
  )
})


test_that("is_zip_file detects zip files and rejects HTML pages", {

  zip_path <- tempfile(fileext = ".zip")
  html_path <- tempfile(fileext = ".zip")
  empty_path <- tempfile(fileext = ".zip")
  missing_path <- tempfile(fileext = ".zip")
  on.exit(unlink(c(zip_path, html_path, empty_path)), add = TRUE)

  # a file starting with the zip signature (an empty zip archive); written
  # byte by byte so the test does not need an external zip program
  writeBin(
    as.raw(c(0x50, 0x4b, 0x05, 0x06, rep(0x00, 18))),
    zip_path
  )

  writeLines("<!DOCTYPE html><html></html>", html_path)
  file.create(empty_path)

  testthat::expect_equal(
    is_zip_file(c(zip_path, html_path, empty_path, missing_path)),
    c(TRUE, FALSE, FALSE, FALSE)
  )
})
