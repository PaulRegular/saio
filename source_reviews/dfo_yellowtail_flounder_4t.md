# Yellowtail flounder (dfo_yellowtail_flounder_4t)

## Yellowtail flounder, NAFO Division 4T, 2021 assessment to 2020

Assessment `dfo_yellowtail_flounder_4t_2020`.

### Assessment identity

This is a historical full assessment of the same NAFO Division 4T stock unit represented by `dfo_yellowtail_flounder_4t`. DFO identifies the last full assessment as February 2021, using data through 2020. Its detailed companion is Research Document 2022/041, published in June 2022. The 2025 assessment remains the current assessment record and is not replaced by this historical record.

### Source-native numerical inputs recovered

Research Document 2022/041 reports:

- Annual recorded Yellowtail Flounder landings for 1985-2020 in tonnes (Table 2). The table separately lists unspecified flatfish; those values are not included as Yellowtail Flounder catch.
- September research vessel survey biomass indices by length group for 1985-2020: less than 25 cm and at least 25 cm, in kg per tow (Table 8).

The input database contains the 36 annual landings values and 72 length-group index values transcribed from those tables. The report also provides whole-area and Magdalen Islands abundance indices in numbers per tow; these companion series are not represented as likelihood inputs here.

The assessment used annual catch proportions by length group, mean weights by length group for fishery and survey, mean weight-at-age and maturity-at-age. The report identifies these input types but the numerical annual arrays were not recovered from the reviewed tables. No age compositions, weights or maturity observations are reconstructed or inferred. Commercial catch-at-length arrays are shown graphically rather than in a numerical table and are not digitized. The 2019 and 2020 landings are marked preliminary.

### Model assumptions documented by the report

The assessment used a length-based age-structured population model for ages 1-8+ and years 1985-2020. Ages 1-3 were mapped to the less-than-25-cm length group, ages 5+ to the at-least-25-cm group, and age 4 was split evenly.

Recruitment was age 1 with annual log-scale deviations having SD 0.2. Fishing selectivity was logistic and changed across 1985-2008, 2009-2012 and 2013-2020. Natural mortality was estimated for age groups 1-3 and 5+ in six six-year periods; age-4 mortality was their average. Survey catchability had logistic age selectivity and an informative log-q prior with mean -0.3566 and SD 0.15. The initial M priors were 0.8 (SD 0.05) for ages 1-3 and 0.3 (SD 0.025) for ages 5+.

The reported likelihood weights were 1.5 for the small-fish index, 1.65 for the large-fish index and 0.85 for fishery catch proportions. The report says the model used penalized maximum likelihood and 5,000 retained MCMC samples for uncertainty.

### Reported outputs

The report gives text summaries rather than numerical annual output tables. The database records only explicit summaries:

- Approximate median abundance in 2020: 520 million fish ages 1-3 and 3 million fish ages 6+.
- Approximate median abundance of ages 4-5: about 95 million in both 2019 and 2020.
- Median >=25-cm biomass in 2020: 2,230 t, adjusted to mid-September.
- The >=25-cm biomass was 39% of its limit reference point in 2020.
- The source gives Bmsy proxy, upper stock reference and limit reference point estimates with stated 95% intervals.

The abundance group summaries are approximate prose values and do not have numeric uncertainty intervals in that prose. SSB is described as averaging 26 kt in 2017-2020, not as a single annual estimate, so no annual SSB is entered. Recruitment and F/M trajectories appear in figures and are not transcribed as annual point estimates. Numerical input and output completeness therefore remains partial.

### Sources

- DFO. 2021. *Stock Assessment of Yellowtail Flounder (Limanda ferruginea) of the southern Gulf of St. Lawrence (NAFO Div. 4T) to 2020*. Science Advisory Report 2021/022.
- Rolland, N., Swain, D., and Ricard, D. 2022. *The Status of Yellowtail Flounder (Limanda ferruginea) in NAFO Division 4T to 2020*. Research Document 2022/041.

## NAFO Division 4T Yellowtail Flounder — source review

### Current unit and assessment

The current DFO stock unit is NAFO Division 4T Yellowtail Flounder
(*Myzopsetta ferruginea*), represented by
`stock_id = dfo_yellowtail_flounder_4t`. The latest full production assessment used for
advice is the 2025 age-structured state-space assessment, with data through
2025 (`assessment_id = dfo_yellowtail_flounder_4t_2025`). Research Document
2026/054 supports Science Advisory Report 2026/022. The detailed report was
published in August 2026; the summary report was published in May 2026.

This is a distinct DFO assessment unit. It should not be confused with the
Georges Bank or Southern New England/Mid-Atlantic Yellowtail Flounder units.

### Inputs described by DFO

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

### Outputs currently represented

The database contains four outputs transcribed from Science Advisory Report
2026/022:

- 2025 biomass of ages 5+, 8,269 t, with a reported 95% confidence interval of
  5,666–10,872 t. This is not SSB.
- Mean fishing mortality for ages 4–10+ of zero in 2023, 2024 and 2025, as
  reported after the fishery closure.

The report describes age-1 recruitment and age- and time-varying natural
mortality, but its summary does not give numerical annual series for them. No
age-specific N, F, or M surfaces have been imported.

### Source access and completeness

The official Government of Canada catalogue lists the 61-page Research
Document 2026/054 and its PDF. As of 2026-11-09, the direct PDF URL redirected
to a Government Publications archive notice; a retry returned the notice page,
not the report. The official 12-page Science Advisory Report is cached at
`source_cache/dfo_yellowtail_flounder_4t/dfo_yellowtail_flounder_4t_2025/Science_Advisory_Report_2026_022.pdf`.
That cache also retains the catalogue page and the archive notice for the
detailed report. No numerical input arrays were found in the accessible
summary sources.

The assessment remains partial for inputs, outputs, and assumptions. Do not use
the 2021 assessment to fill gaps in the 2025 record. Revisit the detailed report
if its PDF or run-specific data become accessible.

### Sources

- [Research Document 2026/054 catalogue record](https://publications.gc.ca/site/eng/9.964766/publication.html)
- [Science Advisory Report 2026/022](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331849.pdf)
- [2024 indicator update, Science Response 2025/010](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf)

### Separate historical assessment source recovery

The detailed historical assessment to 2020 is recorded separately as `dfo_yellowtail_flounder_4t_2020`. Its source-native annual landings and September RV length-group biomass indices are not carried into the current 2025 assessment. The current 2025 record remains partial because its detailed Research Document 2026/054 PDF and numerical model inputs remain unavailable. See `source_reviews/dfo_yellowtail_flounder_4t.md` for the 2021 advice-cycle assessment and its separate source coverage.

## Yellowtail flounder, NAFO Division 4T

### Stock unit and assessment

This is the single current DFO biological unit in NAFO Division 4T, southern Gulf of St. Lawrence, for yellowtail flounder (*Myzopsetta ferruginea*). It is distinct from U.S. Georges Bank and Southern New England/Mid-Atlantic yellowtail flounder units. The canonical stock ID is `dfo_yellowtail_flounder_4t`.

The latest assessment is a full state-space, age-structured assessment using data through 2025. DFO's Science Advisory Report 2026/022 was published in May 2026. Its detailed companion, Research Document 2026/054, is listed in the Government of Canada Publications catalogue as a 61-page August 2026 report by Turcotte, McDermid and Sutton. The catalogue's direct PDF link currently redirects to an archived-page notice rather than the report. The notice and catalogue record have been retained in the local source cache. A ResearchGate author-profile entry identifies a full-text copy, but direct unauthenticated retrieval returned 403; it was not used as a source.

The official Science Advisory Report and the earlier 2025/010 interim-indicator response are cached in `source_cache/dfo_yellowtail_flounder_4t/dfo_yellowtail_flounder_4t_2025/`. The 2025 interim report is retained as assessment history only and is not used to fill inputs for the 2025 full assessment.

### Inputs verified from the official summary

The 2026/022 Science Advisory Report identifies the 2025 assessment's input series and coverage:

- Annual fishery catch totals and number proportions-at-age for seine and trawl fleets, 1985–2022.
- Annual RV survey proportions-at-age and an age-aggregated biomass index, 1985–2025.
- RV survey maturity-at-age and weight-at-age, 1985–2025.
- Age-length keys were updated with information from earlier in the series. The RV vessel and gear changed in 2021, and length-dependent conversion factors were applied to maintain survey continuity.
- Natural mortality is strongly time-varying and age-dependent, with reported age groups 4–7, 8–9 and 10+. The lower-age treatment and the fitted process details are not given in the summary report.

These descriptions establish that the assessment uses age-disaggregated observations and biology, but they are not the numerical arrays. The detailed report's PDF is not currently retrievable from the official catalogue link, and no matching native model files or run-specific data archive were found. Therefore no numerical catch, index, composition, weight or maturity inputs are imported. The input and assumptions records are marked partial; the separate 2025 interim indicator series is not copied into the 2025 assessment.

### Official outputs recovered

The 2025 assessment reports stock biomass for ages 5+ of 8,269 t, with a 95% confidence interval of 5,666–10,872 t. This is the assessment's age-5+ stock-biomass measure, not spawning-stock biomass. The report states that it is 32% of the 25,800 t limit reference point, with 100% probability of being below that reference point.

The report also states that fishing mortality for ages 4–10+ has been zero since 2023, following closure of the directed fishery after the 2022 season. The import records the reported zero for 2023–2025. It does not reconstruct annual recruitment, N-at-age, F-at-age, M-at-age, SSB, or earlier biomass from figures. The report describes M as high and variable (about 0.5–1.3) and gives trends, but it does not provide a numerical annual M series in the summary. No point estimates or uncertainty are inferred from those charts or ranges.

Only the age-5+ terminal biomass and the recent aggregate F statement are imported. Outputs remain partial because the full historical trajectories and detailed uncertainty are unavailable in accessible run-matched sources.

### Remaining source gaps

The official summary confirms suitable types of age-specific inputs, but the numerical series, plus-group definitions, weights, maturity, survey timing and exact likelihood settings remain unavailable. Age-5+ biomass is a distinct reported metric, not SSB.

### Sources

- [DFO Science Advisory Report 2026/022](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331849.pdf)
- [Government of Canada catalogue record for Research Document 2026/054](https://publications.gc.ca/pub?id=9.964766&sl=0)
- [Research Document 2026/054 PDF link](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-054-eng.pdf) (currently redirects to the archived-page notice)
- [DFO Stock Indicators to 2024, Science Response 2025/010](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf) (previous interim update; not mixed into this assessment)
