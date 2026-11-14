# AFMA Bight Redfish, Great Australian Bight (2022)

## Stock and assessment

AFMA identifies Bight Redfish (Centroberyx gerrardi) as one Zone 80 stock in the Great Australian Bight. The latest detailed assessment listed on the AFMA species page is the 2022 Tier 1 assessment, using Stock Synthesis 3.30.19.01 and data through 2021/22. AFMA's 2026 species summary still reports the 2022 assessment and its results. No later detailed report or native model files were located.

The detailed report is a preliminary base-case development document. AFMA's 2026 summary describes later changes to the current assessment: the catch series was revised to include 535 tonnes from southern Western Australia, and male and female growth parameters differ. The preliminary report says its base-case catch excluded Western Australia and initially describes one growth curve shared across sexes. Because native final model files are unavailable, the database follows the later summary for current model results and uses the report's Total WA catch table column for the revised catch series. This version distinction remains a source limitation.

## Sources and provenance

- [AFMA, Stock Assessment for Bight Redfish (Tier 1) 2022](https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-bight-redfish-tier-1-2022.pdf)
- [AFMA, 2026 SESSF Species Summaries](https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf)
- [AFMA Bight Redfish species page](https://www.afma.gov.au/species/bight-redfish)

The two PDFs are cached under the ignored source_cache/australia_afma_bight_redfish_2022/ directory. Retrieval dates, URLs, and SHA-256 checksums are in provenance/afma_bight_redfish_gab_2022/manifest.csv.

## Inputs and assumptions

Table 2 provides the annual catch series and standardized trawl CPUE. Catch uses the source's Total WA catch column, which includes the Commonwealth/South Australian total and the additional southern WA catches; the 2026 AFMA summary reports that the WA component totals 535 tonnes. The preliminary report's Total catch column excludes that component. Financial-year values are stored under the first year of the season. CPUE units are not stated, and its initial CV of 0.107 was retuned during fitting, so that initial value is recorded as an assumption rather than a final likelihood error.

Table 3 reports nine aggregate GAB Fishery Independent Survey relative-abundance estimates and their CVs. These are relative indices in tonnes, not absolute population biomass. The report says surveys generally occurred from February to April and describes the latest trip as March 2021, while the table labels its final observation 2021/22. The table year is retained and the discrepancy is noted; no fractional survey timing is inferred.

Tables 4 and 5 give length- and age-sample counts by data source. Those counts are preserved as counts only; the report does not provide the composition vectors or effective likelihood sample sizes. Table 6 supplies age-reading-error standard deviations for ages 0–64. They are not a complete age-error transition matrix.

The assessment is age- and size-structured, with one area and one trawl fleet. It uses length compositions and conditional age-at-length observations, a Beverton-Holt stock-recruitment relationship, fixed steepness of 0.75, and recruitment deviations estimated through 2007/08. Natural mortality is estimated and constant over age and time. AFMA's current summary reports M = 0.1049 per year with a 95% profile range of 0.091–0.107; the preliminary report's likelihood profile gives a different point estimate of 0.1065. The later summary value is retained for the current assessment output.

## Outputs and remaining gaps

AFMA's 2026 summary reports unfished female spawning biomass (B0) of 4,535 tonnes, projected 2023/24 SSB at 0.67 B0, M and its profile range, selected growth estimates, and a 2023/24 recommended biological catch of 1,056 tonnes. It also reports a three-year average RBC of 994 tonnes and a long-term yield of 595 tonnes per year. These scalar values are imported with their source definitions; uncertainty is left missing when not reported.

Annual numerical abundance-at-age, fishing mortality-at-age, natural mortality-at-age, recruitment, and their uncertainty were not found. The public report describes catch and conditional age-at-length inputs but does not publish catch-at-age, age-specific survey indices, numeric conditional age-at-length vectors, age-specific weights, or maturity-at-age. Therefore the source record is partial and age-based translation eligibility remains unresolved. No observations or biological schedules were manufactured.