# West Coast South Island ling (LIN 7WC), 2026 assessment

## Stock unit and assessment

The 2026 Fisheries New Zealand assessment defines the west coast South Island ling biological stock (LIN 7WC), including Statistical Area 032. This is distinct from the Chatham Rise LIN 3&4 stock already represented in SAIO.

The selected record is the 2026 production assessment, fitted with Casal2 v24.02. It uses calendar model years, catch data through 2025, and estimates stock status for 2026. The 2026 assessment report was published after the data year and is the latest detailed source located for this current unit.

## Official sources and provenance

- [FAR 2026/26 assessment](https://fs.fish.govt.nz/Doc/26250/FAR-2026-26-The-2026-stock-assessment-LIN7WC.pdf.ashx)
- [FAR 2026/25 assessment inputs](https://fs.fish.govt.nz/Doc/26249/FAR-2026-25-Descriptive-analysis-LIN7WC-to-2025-and-inputs-for-2026-stock-assessment.pdf.ashx)
- [FAR 2026/06 catch-at-age report](https://fs.fish.govt.nz/Doc/26199/FAR-2026-06-Catch-at-age-estimates-for-hake-and-ling-from-commercial-fisheries-in-2023-24-and-trawl-surveys-in-2024%20(1).pdf.ashx)
- [FAR 2025/41 TAN2407 survey report](https://fs.fish.govt.nz/Doc/26135/FAR-2025-41-Trawl-survey-for-middle-depth-fish-species-WCSI-2024-TAN2407.pdf.ashx)

The four PDFs are cached under the ignored source_cache/mpi_ling_lin7wc_2026 directory. The provenance manifest records their retrieval date, URL, and SHA-256 checksum.

## Source coverage and records

FAR 2026/26 describes a two-sex age-based statistical catch-at-age model, ages 1-28 with age 28 as a plus group, and a Beverton-Holt stock-recruit relationship. The model fits annual catch biomass, sexed age compositions, bottom-longline and bottom-trawl CPUE, and Tangaroa survey biomass and age compositions.

The assessment lists survey biomass and age-composition observations in 2000, 2012-13, 2016, 2018, 2021, and 2024. Bottom-longline CPUE covers 1990-2025; bottom-trawl CPUE covers 1997-2025. Commercial age-composition years are listed separately by fishery in Table 2.

The canonical record contains 162 annual scaled catch-biomass values for trawl, bottom longline, and potting (1972-2025); 65 adjusted CPUE values and 65 matching CVs; and seven Tangaroa core-strata biomass indices with seven CVs. Appendix D says the adjusted CPUE values include the 1% annual learning-rate correction used by the assessment. The report does not state physical CPUE units. The core survey series was used because it includes the 2000 observation listed in the assessment; the separate all-strata series beginning in 2012 was not mixed into this series. The 2000 core index was recalculated using 2012-13 stratum areas.

FAR 2026/06 Tables 15 and 23 contain 87 reported sex-specific numbers-at-age values and their CVs for the 2023-24 commercial trawl fishery and 2024 TAN2407 survey. Table 15 does not state a separate unit or scaling factor for the calculated commercial numbers-at-age, so that limitation is retained in the unit field. Dashes are defined by the source as no data and were omitted rather than changed to zero. Table 23 says survey values were scaled to relative biomass but gives no multiplier; these are retained on the reported index scale. The tables do not provide the full historical age-composition vectors used by the model.

Table 4 of FAR 2026/26 supplies 20 fixed maturity-at-age values for ages 3-12 by sex. The assessment's full modeled ages 1-28 are not all tabulated. The model's growth and length-weight parameters, fixed M, recruitment, observation likelihoods, selectivity, q treatment, and annual timing are recorded in assumptions.csv.

Tables 7-8 provide nine selected source outputs: MPD B0 and 2023/2026 spawning biomass and status estimates, posterior median B0 and 2026 status ratio with 95% credible intervals, and probabilities relative to the 40% and 20% B0 reference levels. The posterior 2026 SSB/B0 ratio is not converted to an absolute posterior SSB estimate.

## Source gaps

The reports list historical fishery and survey age-composition years but do not provide numerical vectors for every year used in the 2026 model. The recent age report provides the 2023-24 commercial trawl and 2024 survey tables, but 2024 commercial longline and 2025 commercial trawl composition values were not located.

A numeric age-specific weight surface was not located; the report provides growth and length-weight equations. Maturity values are published only for ages 3-12. Annual numerical N-at-age, F-at-age, recruitment, and SSB trajectories were not located; they are presented as figures. Table 7 reports selected MPD biomass estimates, but Table 8 does not report an absolute posterior median SSB for 2026, so none is derived.

The reviewed official sources did not link a public native fitted object, model input files, or run repository. The assessment, assumptions, inputs, and outputs are marked partial.
