# ICES Pollack in subareas 6–7, 2026

## Assessment identity

The current unit is pol.27.67, Pollack (Pollachius pollachius) in ICES subareas 6 and 7, covering the Celtic Seas and English Channel. The 2026 WGCSE assessment supplies advice for 2027. It is an age-structured Stock Synthesis 3 assessment (version 3.30.23.1) with one annual season and a 2025 terminal input year. The 2026 year is an intermediate-year estimate.

The production chapter reports that this assessment updates the SS3 model introduced at the 2025 WKBSS3 benchmark. The 2026 updates include a revised combined survey index, splitting the French CGFS series into 1998–2014 and 2015–2025 because the survey vessel changed, and removing sparse/unrepresentative French age samples for 2015, 2016, 2018, 2020, 2022 and 2023.

## Data recovered

- The ICES Stock Assessment Graphs XML for key 23709 provides aggregate landings for 1950–2025 in tonnes; age-0 recruitment for 1950–2026 in thousands of fish; SSB for 1950–2026 in tonnes; and Fbar for 1950–2025. The XML identifies a 95% confidence interval and F ages 3–7. Fbar is the unweighted average over ages 3–7 according to the Stock Annex. The XML run version is pol.27.67_2026_23709_20261112010501.
- The WGCSE chapter says the landings series uses official landings before ICES landings became available and that 1973–1977 were interpolated because observations were missing. For 2024 the report's subarea totals sum to 707 tonnes (17 + 690), while the pinned SAG XML reports 706 tonnes. The database retains the machine-readable SAG value and records this discrepancy.
- The SAG XML supplies lower and upper 95% interval endpoints for recruitment, SSB and historical Fbar. Standard errors are not supplied. Recruitment estimates for 2024 and 2025 are model-derived from the stock–recruit relationship rather than direct observations. The 2026 recruitment and SSB values are intermediate-year estimates.
- WGCSE Table 18.7 reports 2026 projected commercial landings of 2,317 tonnes, projected recreational removals of 1,561 tonnes, 2026 F at ages 3–7 of 0.29, 2027 forecast SSB of 14,534 tonnes, and 2027 age-0 recruitment of 40,624 thousand fish. These forecast values have no reported uncertainty in that table.
- WGCSE Table 18.8 gives 2027 advice of 3,216 tonnes total removals. It includes commercial and recreational removals; the figure is retained as reported.
- The Stock Annex lists fixed Lorenzen natural mortality for ages 0–10+ and maturity proportions (ages 0–2 = 0, age 3 = 0.9, ages 4+ = 1). These are values agreed at WKBSS3. The Annex does not establish that the exact vectors were retained in the 2026 production configuration, so the database labels them as benchmark-reported inputs rather than verified run-matched values.

## Important gaps

- The current SS3 assessment uses commercial age data from 2010, but numerical run-matched age-composition vectors were not recovered from the reviewed 2026 production sources or the cached WKBSS3 materials.
- The assessment uses a combined sdmTMB abundance index based on 12 trawl surveys from 2003. The numerical 2026 index series was not recovered, and the source does not provide an age-specific survey index. The exact within-year survey timing is not published; the model has one annual season.
- Three commercial LPUE indices are included (Irish gillnets, UK trawls and French trawls), but their numeric series were not recovered. WGCSE says they were not updated for 2024–2025.
- Run-matched catch weights-at-age, stock weights-at-age, estimated N-at-age and F-at-age were not recovered. The report provides assessment figures but not numerical age-specific output tables. The Annex has length–weight parameters but not current run-specific age-weight vectors.
- The current SS3 input/configuration files, fitted object, covariance information, and a complete native model export were not found in the reviewed public materials. Thus the present extraction does not reconstruct the full likelihood input set.

The 2026 assessment remains the primary stock record because run-specific aggregate inputs and outputs are available. The import is intentionally partial; no older unit or benchmark estimates were substituted for missing 2026 inputs or outputs.

## Database records

The import is in stocks.csv, assessments.csv, inputs.csv, assumptions.csv and outputs.csv under stock ices_pol_27_67 and assessment ices_pol_27_67_2026. Input, assumption and output completeness are marked partial. Source files, revisions, retrieval date, file sizes and SHA-256 checksums are listed in provenance/ices_pollack_67_2026/sources.csv; cached copies are under the ignored source_cache/ices_pollack_67_2026/ directory.