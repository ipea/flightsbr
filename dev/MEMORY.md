# Project Memory

Corrections and learned facts that persist across sessions for
**flightsbr**. When a mistake is corrected, or a non-obvious approach is
confirmed, append a `[LEARN:category]` entry below.

Prior content (inherited from the workflow template’s own development
history, not about flightsbr) is archived at
[`quality_reports/archive/inherited-template-memory.md`](https://ipea.github.io/flightsbr/dev/quality_reports/archive/inherited-template-memory.md).

------------------------------------------------------------------------

\[LEARN:anac\] 2026-11: gov.br flights page links are relative
(`/anac/.../x.zip`) and lead to an HTML landing page → resolve with
[`rvest::url_absolute()`](http://xml2.r-lib.org/reference/url_absolute.md)
and append `/@@download/file`. \[LEARN:anac\] sas.anac.gov.br (airfares)
blocks bursts of scripted requests with an HTML “Requisição Bloqueada”
page served as **HTTP 200** → status codes alone don’t prove success;
check content type / first bytes, keep `max_active` low. \[LEARN:anac\]
404s on sas/sistemas hosts still write the HTML error page to the
`paths=` file in
[`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html)
→ download to a temp `.part` file, rename only on success.
\[LEARN:anac\] Airfare headers changed 5 times (ANO/TARIFA; Ano de
Referência/Tarifa-N; designador\_*/VALOR_TARIFA; leading “” index col;
nr\_*/sg\_\*), interleaved month by month, never reordered. 202005 is
UTF-8, other Portuguese-header files Latin-1. Map by name
(`airfare_col_map`), never by date. \[LEARN:anac\] RAB layout changed
2026-01→2026-03: MARCA→MARCAS; owner/operator columns became JSON arrays
(restructured, not renamed). Every field is quoted, so fread’s
`na.strings` does nothing and `""` escapes are kept literally → clean
after reading. \[LEARN:anac\] `nr_*` column names are not a numeric
signal: movements `nr_aeroporto_referencia` = “SBAR”, RAB `nr_serie` =
“LA-189”, flights `nr_voo`/`nr_chave` are IDs. Convert only if all
values parse. \[LEARN:anac\] Private airports file writes coordinate
seconds with a decimal comma (`39,8"S`) that parzer can’t read; `",0"`
is ANAC’s missing-altitude code.
