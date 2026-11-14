# Northwest Pacific chub mackerel: NPFC 2025 assessment

## Stock unit and current assessment

The North Pacific Fisheries Commission (NPFC) assesses one chub mackerel stock for the Northwest Pacific Ocean, covering the NPFC Convention Area and Member exclusive economic zones. The assessment includes catch data from China, Japan and Russia. This assessment unit is broader than the NOAA-managed Pacific Coast unit; the shared species name does not make them the same stock. The NPFC report identifies the 2025 state-space age-structured model as the current base-case assessment. The Scientific Committee endorsed the assessment report in December 2025. The 2026 Commission meeting retained that report as the scientific basis for management measures.

The selected base case is S02-Index24_1. The population assessment period is FY1970-FY2023, with fishing years running July through June. Seven age groups are used: ages 0-5 and 6+. The selected scenario includes Japanese and Russian FY2024 abundance indices; it estimates stock status at the start of FY2024. FY2024 weight-at-age and maturity-at-age are set to their FY2016-FY2023 means in this scenario, and the Russian catch share is set to its FY2021-FY2023 mean.

## Inputs and assumptions recovered

Catch-at-age is constructed from quarterly, member-specific data. Japan supplied the FY1970-FY2013 series; Russian catch in FY1967-FY1988 is included in that Japanese series because it could not be separated by Member. From FY2014 onward, the assessment combines quarterly catch-at-length and age-length keys from China, Japan and Russia. In years without Chinese or Russian age-length keys, the Eastern Japan key was used. The public input presentation shows catch-at-age only as a plot, not as a numeric series.

The 2025 assessment uses annual weight-at-age. For FY1970-FY2013 it uses the Japanese domestic Pacific-stock series. For FY2014-FY2023 it calculates weighted member values from China, Eastern and Western Japan, and Russia using catch-number shares, then averages quarterly values within fishing year. The report shows the final annual series as a figure; an exact run-matched numeric array was not located.

Base-case maturity-at-age is the annual Japanese domestic assessment series for FY1970-FY2023. It varies by decade and is also presented only as a figure. The report says recent maturity is lower: age-2 maturity is zero and age-3 maturity is 0.3 in recent Japanese waters. Those statements do not replace the full annual input series.

The base case uses fixed, time-invariant natural mortality by age: 0.80, 0.60, 0.51, 0.46, 0.43, 0.41 and 0.40 per year for ages 0, 1, 2, 3, 4, 5 and 6+, respectively. These values are the only fully numeric age-specific biological input recovered so far.

Seven abundance-index series are used: Japanese summer age-0; Japanese autumn age-0 and age-1; Japanese egg-survey SSB; Japanese dip-net SSB; Chinese light-purse-seine vulnerable biomass; and Russian trawl vulnerable biomass. Japanese and Russian series extend through FY2024; the Chinese series extends through FY2023. The accessible reports show the fitted series in figures, but do not provide the exact run-matched observation arrays. The fishing-year convention is documented; exact within-year model timing for each index was not found.

The NPFC Scientific Committee report describes the model as a state-space catch-at-age model with lognormal observation likelihoods for catch-at-age and abundance indices, a Beverton-Holt stock-recruitment relationship, process error in abundance and fishing mortality, and age-correlated fishing-mortality increments. Three indices have nonlinear relationships to population abundance; the remaining indices have linear relationships. The report specifies different observation-error terms among index series. The complete model source files and fitted object were not found in the public source search.

## Reported outputs

Table E-1 reports exact reference points for base case S02-Index24_1. With recent FY2016-FY2023 biological parameters, current fishing mortality is 16.2% SPR; F0.1/Fcur is 0.838; F30%SPR/Fcur is 0.580; F40%SPR/Fcur is 0.412; F50%SPR/Fcur is 0.295; F60%SPR/Fcur is 0.207; and F70%SPR/Fcur is 0.139. The corresponding full-period FY1970-FY2023 values are current SPR 27.8%, F0.1/Fcur 0.838, F30%SPR/Fcur 0.911, F40%SPR/Fcur 0.609, F50%SPR/Fcur 0.416, F60%SPR/Fcur 0.282 and F70%SPR/Fcur 0.184.

The reference-period description for current fishing mortality is inconsistent within the report: the reference-point section describes Fcur as the FY2021-FY2023 average, while Annex 1's glossary describes the Fcur denominator for the F ratios as the FY2020-FY2023 average. The published reference-point values are retained without resolving that discrepancy.

The same table reports SSB_F=0_RECENT of 1,399 thousand tonnes; SSB_LIM of 107 thousand tonnes; SSB_REFERENCE_A of 289 thousand tonnes; and SSB_REFERENCE_B of 585 thousand tonnes. Estimated FY2023 SSB ratios are 1.23 relative to SSB_LIM, 0.46 relative to SSB_REFERENCE_A and 0.23 relative to SSB_REFERENCE_B. The table does not report uncertainty for these values.

Figure E-8 shows annual trajectories of total biomass, SSB, recruitment, catch, mean F and exploitation rate. Those annual values are plotted with uncertainty bands but are not numerically tabulated in the reviewed report. Annual N-at-age and F-at-age output arrays were not located.

## Source status and unresolved information

The reviewed documents support a partial current-unit source record based on the exact fixed M schedule and Table E-1 reference points. Numerical annual catch-at-age, weight-at-age, maturity-at-age and abundance-index arrays remain unavailable from the reviewed public sources. The input presentation gives those observations as plots, and the NPFC scientific-data database announcement in April 2026 said its new data system was planned to launch in 2027.

Age-input eligibility remains unresolved because the full numerical catch-at-age series and the survey age-index observations are not available in the reviewed sources. The canonical record preserves the verified fixed M input and reported reference-point values without implying that the model's age-specific input set has been recovered.

The NPFC Scientific Committee's 2026 final report states that Japan identified errors in FY2014-FY2017 catch-at-age used for the 2025 NPFC assessment and reran SAM with corrected data. It reports no substantial change in estimated biomass, SSB or recruitment and no change to reference points or overall conclusions. The reviewed public material did not contain the corrected NPFC arrays or revised numeric Table E-1 values. The database therefore retains the values from the endorsed published assessment report and explicitly records the correction as an unresolved run-data limitation; it does not substitute domestic Japanese corrected values for the NPFC outputs.

## Sources and local provenance

- [NPFC 2025 chub mackerel stock assessment report (Annex H to the 2026 SC10 report)](https://www.npfc.int/sites/default/files/2026-01/SC10%20Report.pdf)
- [NPFC 2025 base-case input data presentation](https://www.npfc.int/system/files/2025-07/NPFC-2025-TWG%20CMSA11-WP03%20SuppDoc.1%20Input_data_presentation_0.pdf)
- [NPFC 2026 Scientific Committee final report](https://www.npfc.int/system/files/2026-03/NPFC-2026-SC10-Final%20Report.pdf)
- [NPFC 2026 Commission-adopted measure for chub mackerel](https://www.npfc.int/system/files/2026-04/NPFC-2026-COM10-WP02%20Rev.4%20CM%20adopted.pdf)
- [FRA 2025 Pacific-stock assessment detailed report](https://abchan.fra.go.jp/wpt/wp-content/uploads/2026/03/details_2025_05.pdf)
- [NPFC notice about its scientific-data database](https://www.npfc.int/news/new-npfc-database-scientific-data)

Cached documents, URLs, retrieval dates and SHA-256 checksums are listed in provenance/npfc_chub_mackerel_nw_pacific_2025_sources.csv. They are stored in the ignored source_cache/npfc_northwest_pacific_chub_mackerel_2025/ directory; the FRA report is retained in the cited Japanese-assessment cache folder.


