# DFO Atlantic herring, NAFO 4RSw spring and fall components

## Unit and current assessment

The DFO inventory contains separate 4R spring- and fall-spawner rows. The
current biological assessment unit is now NAFO 4RSw: the latest advisory says
4Sw is assessed jointly with 4R because movement evidence supports a single
biological unit. Spring and fall spawners remain genetically distinguishable
and are assessed separately. They are therefore represented by two candidate
units, not by one pooled assessment or by separate geographic 4R/4Sw cases.
The existing database has no 4RSw herring stock record; the existing 4TVn and
4VWX herring entries are different units.

The latest production assessment is the 2024 assessment, based on data through
2024. It is a state-space statistical catch-at-age model implemented in WHAM;
the assessment approach was reviewed and approved in 2025. The 2026 advisory
report states the detailed 4RSw framework/model research document was still in
preparation and that companion publications would be posted later. As of this
review date, no run-matched detailed model report, native fitted object, or
machine-readable current-run input/output bundle was located.

## Inputs and assumptions

- **Commercial catch and age data:** The 2026 advisory identifies commercial
  landings and catch age/spawning-component composition for 1966-2024. The
  2025 catch-age revision report documents revised spring and fall catch-age
  estimates, chiefly for 1973-2021 in 4R and 1985-2021 in 4Sw. It presents
  catch-age comparisons in figures, not as a run-matched numeric matrix for the
  accepted 2024 fit. The current assessment's exact age grid and numerical
  catch-age inputs were not recovered.
- **Acoustic survey information:** The current advisory identifies total
  biomass indices plus age and spawning-component composition from the summer
  acoustic survey in 4RSw (2019-2024) and the fall acoustic survey in 4R
  (1991-2022). The fall series ended in 2022; the summer series is now the
  primary fishery-independent input. The reviewed survey reports describe
  revised survey methods and biomass calculations, but exact current-run age
  grids, numeric likelihood inputs and scales were not located.
- **Biology:** The current advisory identifies maturity-at-age and
  weight-at-age by spawning component for 1966-2024. It does not provide the
  fitted age grid or numeric current-run arrays in the reviewed summary.
- **Mortality:** Natural mortality is described as constant. Its numeric value
  and the complete current model specification are not in the advisory; the
  detailed framework/model report remains the key missing source.
- **Timing:** Summer and fall survey seasons are identified, but no fitted
  within-year timing fractions were recovered.

## Outputs

The advisory reports aggregate time series for SSB, fully selected fishing
mortality and age-2 recruitment for each spawning component. SSB and the
plotted F and recruitment series include 95% uncertainty intervals. Spring
spawner 2024 SSB is 50,608 t (95% interval 16,501-155,214 t); fall spawner
2024 SSB is 48,353 t (95% interval 21,736-107,567 t). Numeric current-run
N-at-age, F-at-age and M-at-age outputs were not located. The report also notes
that its self-tests show downward SSB bias, estimated at 10.5% for spring
spawners and 16.6% for fall spawners.

## Screening decision

Both candidate rows are screened, but age-based source-curation eligibility
remains **unresolved**. The official sources verify a current age-structured
assessment, age-based catch/survey-composition and biological data, and
comparable aggregate outputs. However, the detailed current model report is
not yet publicly located; the run-matched numerical inputs, mortality value,
survey timings, exact age grid and numeric age-specific fitted outputs remain
unavailable. Keep 4RSw as the current-unit assessment. Do not substitute the
2021 4R-only assessment or interpret the 2025/065 data-revision report as the
accepted 2024 model fit. No numerical canonical records were added during this
screen.

## Sources

- [2026 Science Advisory Report 2026/013, assessment in 2024](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41329181.pdf)
- [2025 Research Document 2025/065, catch-age revisions](https://open-science.canada.ca/server/api/core/bitstreams/4634e276-cae2-499f-b696-b4e0434c66dd/content)
- [2024 Proceedings 2024/006, assessment-framework data review](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41230607.pdf)
- [2024 Research Document 2024/061, summer acoustic survey](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41260776.pdf)
- [2024 Research Document 2024/026, fall acoustic-index revisions, French edition](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41243663.pdf)
- [2024 Research Document 2024/004, 2021 assessment for the preceding 4R boundary](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41234790.pdf)

The official PDFs, retrieval URLs, retrieval date and SHA-256 checksums are in
the gitignored local cache `source_cache/discovery_dfo_herring_4rsw_2024_2026/`.
