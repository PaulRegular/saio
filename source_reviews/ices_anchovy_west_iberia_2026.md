# Western Iberian anchovy

## Assessment and stock identity

`ices_anchovy_west_iberia_2026` is the 2026 official assessment of European
anchovy (*Engraulis encrasicolus*) in western division 9.a, stock code
`ane.27.9aW`. The 2024 benchmark split the former combined stock into western
and southern stocks. This record is separate from the historical catalogue row
`ck_ices_wghansa_mordax_sp9a` and southern `ices_anchovy_gulf_cadiz`; the
catalogue's original species label was incorrect and is not assigned here.

The current assessment is an ICES category 3.2 constant-harvest-rate rule,
not an age-structured population model. The index combines the spring
PELACUS estimate in 9.a North with PELAGO estimates for 9.a Central-North and
Central-South. The 2026 combined biomass index is 65,291 tonnes; applying the
0.25 harvest-rate proxy gives advice of 16,323 tonnes for July 2026–June 2027.
The 2026 surveys were conducted March–April. Exact common survey timing is
not recorded as a model input.

## Recovered data and caveats

- WGHANSA Table 3.3.2.1 gives calendar-year catches for 1989–2025, both total
  and three regional components. They overlap and must not be fitted twice.
  2025 total catch is 12,940 tonnes; 2026 is provisional and omitted. Spanish
  2020 first-semester discard sampling was unavailable.
- Table 3.3.5.2.2 supplies Spanish North catch-at-age, ages 0–3, for 2011,
  2012 and 2015–2024, in thousands of fish. These are regional observations,
  not complete whole-stock catch. Years 2013–2014 are unavailable. The 2025
  entries are withheld because the same report's Table 3.3.5.2.1 gives
  inconsistent annual age values; the latter's quarterly table also has an
  apparent inconsistent Q4 total. The Portuguese 2025 regional tables are
  retained in the cached report pending resolution of other table/narrative
  discrepancies; no source values were silently corrected.
- SAG key 23750 gives the combined acoustic biomass index for 2007–2011 and
  2013–2026 and a reported relative harvest-rate indicator for 2007–2011 and
  2013–2025. The index is recorded both as the assessment input and the same
  reported indicator; these are not independent observations or an SSB
  estimate. The harvest-rate ratio is not instantaneous F. SAG catch fields
  use the management-period convention and differ from the report's calendar
  catch (e.g. 2025); calendar catches above are taken from the report.
- Fixed natural mortality proposed for modelling exercises is not an input to
  this index-based assessment. No fixed age-specific M has been invented.

Completeness is partial: the public 2026 TAF URL printed in the report returned
404, and the full numerical source inputs and age-structured population states
were not recovered. The method does not estimate N-at-age, F-at-age,
recruitment or SSB. A defensible age-structured tinyAM comparison is not yet
supported and no dashboard was produced.

The [2026 working-group report](https://doi.org/10.17895/ices.pub.32614524.v2)
and [SAG XML](https://sag.ices.dk/SAG_API/StockXmlDownload/23750) are cached
under `source_cache/ices_anchovy_west_iberia_2026/` with URLs and checksums in
`manifest.csv`. The [2026 advice](https://asd.ices.dk/viewAdvice/7195) confirms
the stock code, assessment year and management advice. The stock identity and
2024 split are described in the report's sections 3.1–3.2.
