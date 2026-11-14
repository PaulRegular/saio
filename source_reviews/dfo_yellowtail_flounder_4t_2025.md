# NAFO Division 4T Yellowtail Flounder — source review

## Current unit and assessment

The current DFO stock unit is NAFO Division 4T Yellowtail Flounder
(*Myzopsetta ferruginea*), represented by
`stock_id = dfo_yellowtail_flounder_4t`. The latest full production assessment used for
advice is the 2025 age-structured state-space assessment, with data through
2025 (`assessment_id = dfo_yellowtail_flounder_4t_2025`). Research Document
2026/054 supports Science Advisory Report 2026/022. The detailed report was
published in August 2026; the summary report was published in May 2026.

This is a distinct DFO assessment unit. It should not be confused with the
Georges Bank or Southern New England/Mid-Atlantic Yellowtail Flounder units.

## Inputs described by DFO

The Science Advisory Report lists these model inputs:

- Fishery total catch and proportions-at-age by seine and trawl, 1985–2022.
- Research vessel survey proportions-at-age and an age-aggregated biomass
  index, 1985–2025.
- Survey weight-at-age and maturity-at-age, 1985–2025.

The assessment updated age-length keys using earlier survey samples and applied
length-dependent conversion factors for the 2021 vessel and gear change.
These are source descriptions, not the numerical likelihood arrays. The
canonical database currently has no numerical input rows for this assessment;
the exact age compositions, catch series, survey index and biological vectors
remain unverified and were not reconstructed from figures or fitted outputs.

## Outputs currently represented

The database contains four outputs transcribed from Science Advisory Report
2026/022:

- 2025 biomass of ages 5+, 8,269 t, with a reported 95% confidence interval of
  5,666–10,872 t. This is not SSB.
- Mean fishing mortality for ages 4–10+ of zero in 2023, 2024 and 2025, as
  reported after the fishery closure.

The report describes age-1 recruitment and age- and time-varying natural
mortality, but its summary does not give numerical annual series for them. No
age-specific N, F, or M surfaces have been imported.

## Source access and completeness

The official Government of Canada catalogue lists the 61-page Research
Document 2026/054 and its PDF. As of 2026-11-09, the direct PDF URL redirected
to a Government Publications archive notice; a retry returned the notice page,
not the report. The official 12-page Science Advisory Report is cached at
`source_cache/discovery_dfo_gulf_yellowtail_2026/Science_Advisory_Report_2026_022.pdf`.
That cache also retains the catalogue page and the archive notice for the
detailed report. No numerical input arrays were found in the accessible
summary sources.

The assessment remains partial for inputs, outputs, and assumptions. Do not use
the 2021 assessment to fill gaps in the 2025 record. Revisit the detailed report
if its PDF or run-specific data become accessible.

## Sources

- [Research Document 2026/054 catalogue record](https://publications.gc.ca/site/eng/9.964766/publication.html)
- [Science Advisory Report 2026/022](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331849.pdf)
- [2024 indicator update, Science Response 2025/010](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf)

## Separate historical assessment source recovery

The detailed historical assessment to 2020 is recorded separately as `dfo_yellowtail_flounder_4t_2020`. Its source-native annual landings and September RV length-group biomass indices are not carried into the current 2025 assessment. The current 2025 record remains partial because its detailed Research Document 2026/054 PDF and numerical model inputs remain unavailable. See `source_reviews/dfo_yellowtail_flounder_4t_2020.md` for the 2021 advice-cycle assessment and its separate source coverage.
