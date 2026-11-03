# Pacific ocean perch in the Gulf of Alaska

## Stock unit and assessment

NOAA Stock SMART ID 11056 is the Gulf of Alaska (GOA) Pacific ocean perch unit (*Sebastes alutus*). It is distinct from the Bering Sea/Aleutian Islands unit (Stock SMART ID 11055) and the British Columbia assessment. The database records the GOA unit as `afsc_goa_pacific_ocean_perch`.

The latest completed detailed fit located on 2026-11-02 is the 2023 operational update, Model 20.1, with data through 2023. Its configuration matches the 2021 full assessment. The 2024 SAFE treated 2024 as a harvest projection; the scheduled 2025 full assessment was cancelled. A new GOA assessment was scheduled for December 2026 and had not yet been released by the review date. The canonical record therefore identifies the 2023 update as the latest detailed assessment available for this unit, not as a 2026 assessment.

The 2023 SAFE, subsequent assessment-schedule and catch documents, and native model files are cached locally in `source_cache/noaa_goa_pop_20261029/`. Native repository files are pinned to commit `e87bbfc60ab8bfc87d05e02ed1b4b39b76059d7e`. The cache manifest records the source URLs, retrieval dates, revisions, byte counts and SHA-256 checksums.

## Inputs and assumptions recovered

The import preserves the model's original observations and supporting biological data in `database/inputs.csv` (2,107 rows) and `database/assumptions.csv` (140 rows). It does not convert observed proportions into tinyAM-specific catch or survey-at-age values.

- Total fishery catch is in tonnes for 1961–2023. Values through 2022 are observed catch; 2023 is an in-year estimate. The model input also contains 17 fishery age compositions, sampled in 1990, 1998–2002, 2004–2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020 and 2022. They are number proportions for ages 2–24 and a 25+ group; sample counts, haul counts and age-error keys are retained.
- The bottom-trawl survey has 16 aggregate biomass indices and natural-scale standard errors in tonnes from 1990–2023. Fourteen survey age compositions are available for 1990, 1993, 1996, 1999 and 2003–2021 on the biennial survey schedule. Their number-proportion bins are ages 2–24 and 25+, with sample counts, haul counts and age-error keys. The 2001 biomass index includes the model's Eastern GOA biomass substitution because that area was not sampled.
- Fishery length compositions are included for 20 years and survey length compositions for 15 years, with source bins labelled 16–45 cm. Survey length compositions were supplied to the model but assigned zero likelihood weight. The fishery length likelihood rescales haul weights to a maximum of 100. These source observations are preserved even though tinyAM does not fit length compositions.
- The population model spans ages 2–29+, with age 29 as its plus group. The native observation compositions instead end in a 25+ group. The model's single weight-at-age vector and the separate supporting fishery and survey weight vectors are all recorded in grams per fish. The model vector is used for population biomass calculations; the supporting vectors must not be mistaken for that model input.
- Female maturity sample totals and mature counts from the Lunsford and Conrath datasets are retained. The fitted model estimates a logistic maturity curve from those binomial data and applies a 0.5 female fraction in biomass calculations.
- Natural mortality is one estimated constant across years and ages (0.074344943 per year in the fitted model), with a lognormal prior (mean 0.0614, CV 0.1). The bottom-trawl survey has one estimated catchability parameter, q = 1.736106. The survey biomass likelihood is lognormal and uses the natural-scale index SE as a CV. No within-year survey timing fraction is specified in the model files; spawning month 5 is not survey timing.
- The age-composition likelihood applies the supplied age-error matrices and uses the square root of nominal sample size as the composition weight. The import records the full transition matrices and maps their rows to true model ages and columns to observed ages.

One source-export difference is documented: the final 2023 model `.dat` file and SAFE summary contain a 1990 survey age composition, but the auxiliary `goa_bts_age_comp.csv` export begins in 1993. The import uses the run-matched `.dat` input, retaining its 1990 survey composition (n = 1,754), rather than dropping it to match the incomplete auxiliary export.

## Outputs and remaining gaps

The import contains 7,392 output rows. It records official point estimates of numbers-at-age (1961–2023, ages 2–29+), recruitment, total abundance derived by summing numbers-at-age, spawning and total biomass, fitted catch and survey biomass, and estimated maturity-at-age. Fishing mortality-at-age is derived from the reported annual fully selected F and the matching selectivity curve for four time blocks (1961–1976, 1977–1995, 1996–2006 and 2007–2023). The constant estimated M is expanded over the year-age surface. Aggregate 2024–2025 total biomass and SSB are management projections, not fitted historical estimates.

The imported outputs are point estimates; no output standard errors or intervals are invented. The report and repository include MCMC uncertainty for selected aggregate quantities and parameters, but complete age-specific uncertainty is not available in the exported N-at-age table, so the assessment's output completeness remains `partial`. The derived total-abundance series has no joint uncertainty. The source fit reports objective 267.668553 and maximum gradient component 0.00006063.

The source model's SSB definition changes at the terminal year: 1961–2022 use N × weight × maturity × 0.5 without survival to spawning, while terminal 2023 applies survival through one third of a year. This behavior is retained and explicitly noted rather than harmonized during import.

The source data support a later tinyAM translation, but it will be approximate. Catch-at-age would need to be reconstructed downstream from catch biomass, age proportions and fishery weights for sampled composition years. The aggregate survey index and survey proportions/weights can support a documented age-index reconstruction only for years with the required survey inputs. The 25+ observation bin must be handled explicitly against tinyAM's age grid. A translation would omit the length-composition likelihoods, use a simplified observation likelihood, and choose an explicit approximate survey timing because the source timing is unresolved. These choices belong in the translation, not the canonical observations.

## Sources

- [2023 GOA Pacific ocean perch assessment update](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOApop.pdf)
- [2024 GOA SAFE introduction and assessment schedule](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+SAFE+Introduction.pdf&p=ab2770e7-ed6f-4a2f-a69d-5cbd0bda1896.pdf)
- [2025 GOA catch report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C4+GOA+2025+Catch+Reports.pdf&p=f6b9ff85-9a04-46e3-a7ce-0c2a09b6ccee.pdf)
- [2026 SSC assessment review plan](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=F+2026+Groundfish+Assessment+SSC+Review.pdf&p=2aa31081-76e1-4025-af01-e17fd99ba0d6.pdf)
- [Pinned GOA POP 2023 model files](https://github.com/noaa-afsc/goa_pop/tree/e87bbfc60ab8bfc87d05e02ed1b4b39b76059d7e/2023/mgmt/2020.1-2023)
- [Pinned 2023 assessment data-generation script](https://github.com/noaa-afsc/goa_pop/blob/e87bbfc60ab8bfc87d05e02ed1b4b39b76059d7e/2023/R/2023_analysis.R)
