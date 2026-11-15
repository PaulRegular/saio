# Yellowtail flounder, NAFO Division 4T

## Stock unit and assessment

This is the single current DFO biological unit in NAFO Division 4T, southern Gulf of St. Lawrence, for yellowtail flounder (*Myzopsetta ferruginea*). It is distinct from U.S. Georges Bank and Southern New England/Mid-Atlantic yellowtail flounder units. The canonical stock ID is `dfo_yellowtail_flounder_4t`.

The latest assessment is a full state-space, age-structured assessment using data through 2025. DFO's Science Advisory Report 2026/022 was published in May 2026. Its detailed companion, Research Document 2026/054, is listed in the Government of Canada Publications catalogue as a 61-page August 2026 report by Turcotte, McDermid and Sutton. The catalogue's direct PDF link currently redirects to an archived-page notice rather than the report. The notice and catalogue record have been retained in the local source cache. A ResearchGate author-profile entry identifies a full-text copy, but direct unauthenticated retrieval returned 403; it was not used as a source.

The official Science Advisory Report and the earlier 2025/010 interim-indicator response are cached in `source_cache/discovery_dfo_gulf_yellowtail_2026/`. The 2025 interim report is retained as assessment history only and is not used to fill inputs for the 2025 full assessment.

## Inputs verified from the official summary

The 2026/022 Science Advisory Report identifies the 2025 assessment's input series and coverage:

- Annual fishery catch totals and number proportions-at-age for seine and trawl fleets, 1985–2022.
- Annual RV survey proportions-at-age and an age-aggregated biomass index, 1985–2025.
- RV survey maturity-at-age and weight-at-age, 1985–2025.
- Age-length keys were updated with information from earlier in the series. The RV vessel and gear changed in 2021, and length-dependent conversion factors were applied to maintain survey continuity.
- Natural mortality is strongly time-varying and age-dependent, with reported age groups 4–7, 8–9 and 10+. The lower-age treatment and the fitted process details are not given in the summary report.

These descriptions establish that the assessment uses age-disaggregated observations and biology, but they are not the numerical arrays. The detailed report's PDF is not currently retrievable from the official catalogue link, and no matching native model files or run-specific data archive were found. Therefore no numerical catch, index, composition, weight or maturity inputs are imported. The input and assumptions records are marked partial; the separate 2025 interim indicator series is not copied into the 2025 assessment.

## Official outputs recovered

The 2025 assessment reports stock biomass for ages 5+ of 8,269 t, with a 95% confidence interval of 5,666–10,872 t. This is the assessment's age-5+ stock-biomass measure, not spawning-stock biomass. The report states that it is 32% of the 25,800 t limit reference point, with 100% probability of being below that reference point.

The report also states that fishing mortality for ages 4–10+ has been zero since 2023, following closure of the directed fishery after the 2022 season. The import records the reported zero for 2023–2025. It does not reconstruct annual recruitment, N-at-age, F-at-age, M-at-age, SSB, or earlier biomass from figures. The report describes M as high and variable (about 0.5–1.3) and gives trends, but it does not provide a numerical annual M series in the summary. No point estimates or uncertainty are inferred from those charts or ranges.

Only the age-5+ terminal biomass and the recent aggregate F statement are imported. Outputs remain partial because the full historical trajectories and detailed uncertainty are unavailable in accessible run-matched sources.

## Remaining source gaps

The official summary confirms suitable types of age-specific inputs, but the numerical series, plus-group definitions, weights, maturity, survey timing and exact likelihood settings remain unavailable. Age-5+ biomass is a distinct reported metric, not SSB.

## Sources

- [DFO Science Advisory Report 2026/022](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331849.pdf)
- [Government of Canada catalogue record for Research Document 2026/054](https://publications.gc.ca/pub?id=9.964766&sl=0)
- [Research Document 2026/054 PDF link](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-054-eng.pdf) (currently redirects to the archived-page notice)
- [DFO Stock Indicators to 2024, Science Response 2025/010](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf) (previous interim update; not mixed into this assessment)
