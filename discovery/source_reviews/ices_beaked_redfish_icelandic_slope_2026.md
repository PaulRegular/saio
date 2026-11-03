# ICES Icelandic slope beaked redfish, 5.a and 14 (2026)

ICES stock `reb.27.5a14` is the Icelandic-slope beaked redfish unit in Division
5.a and Subarea 14. It is distinct from the database's beaked-redfish record
for ICES Subareas 1 and 2 (`reb.27.1-2`). The 2026 ICES record is an active
Category 1 assessment.

## Source screen

The current MFRI assessment is an age- and length-based Gadget model covering
1975–2026, with two six-month time steps, immature and mature substocks, ages
3–50+ and lengths 5–60 cm. The report describes landings by six-month period,
commercial length distributions, length-disaggregated autumn-survey indices,
age–length compositions, and maturity observations. The diagnostics include
autumn-survey and commercial age–length compositions. Natural mortality is
fixed at 0.05. Growth and maturity are modelled on length; the length–weight
relationship is fixed from autumn-survey biological data.

These sources confirm that age observations are used within the assessment,
but they do not provide the numerical annual age–length likelihood inputs,
their complete sample expansion information, or a catch-at-age series. The
report gives data-availability summaries, selected composition plots, and
sample totals, but the reviewed current report, ICES advice record, Standard
Graphs/SAG files, and public Hafro data-server catalogue did not expose a
complete numeric input set. Length-disaggregated survey indices cannot be
treated as age-specific indices, and survey age samples cannot be substituted
for fishery catch-at-age without source-supported conversion data. The exact
annual survey timing fractions and age-specific weights/maturity inputs needed
for a defensible tinyAM translation were also not found.

The report presents SSB, age-3 recruitment, and fishing-mortality trends with
95% intervals, along with forecast tables. These provide some comparable
official outputs, but the current public materials reviewed do not provide a
complete numeric N-at-age or F-at-age series.

## Decision

Identity is resolved as a new unit and the public source screen is complete for
the sources listed below. Eligibility remains **unresolved**, rather than
ineligible: the assessment does use age–length observations, but it is not yet
clear whether a complete, numeric, source-supported age input set can be
recovered. Keep this as a source gap to pursue. Do not infer catch-at-age from
the fitted Gadget states or replace age observations with length compositions.
No canonical stock, assessment, input, or output records were added.

## Sources and cache

- MFRI 2026 technical report, published 12 June 2026:
  https://www.hafogvatn.is/static/extras/images/61_drf_2026_1_techreport_en.html
- Current ICES advice record 7218, assessment year 2026:
  https://asd.ices.dk/viewAdvice/7218
- ICES Standard Graphs source data, assessment key 22659:
  https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22659
- ICES SAG XML, assessment key 22659:
  https://sg.ices.dk/SAG_API/StockXmlDownload/22659
- Hafro data-server catalogue (annual assessment tables and selected archived
  raw model outputs): https://data.hafro.is/assmt/readme.html

Downloaded sources, retrieval dates, byte counts, and SHA-256 checksums are
recorded in `source_cache/discovery_ices_beaked_redfish_5a14_2026/sources.csv`;
the cache is gitignored.
