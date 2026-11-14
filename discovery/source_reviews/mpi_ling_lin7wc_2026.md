# West Coast South Island ling (LIN 7WC), 2026 assessment

## Stock unit and assessment

The 2026 Fisheries New Zealand assessment defines the west coast South Island ling biological stock (LIN 7WC). It includes Statistical Area 032. This is distinct from the Chatham Rise LIN 3&4 stock already represented in SAIO.

The selected record is the 2026 production assessment, fitted with Casal2 v24.02. It uses model years defined as calendar years and data through 2025, with status estimated for 2026. The 2026 report was published after the assessment data year and is the latest detailed source located for this current unit.

## Sources

- FAR 2026/26, The 2026 stock assessment of ling off the west coast South Island.
- FAR 2026/25, Descriptive analysis of LIN 7WC to 2025 and inputs for the 2026 stock assessment.
- FAR 2026/06, Catch-at-age estimates for hake and ling from 2023-24 commercial fisheries and 2024 trawl surveys.
- FAR 2025/41, TAN2407 trawl survey report.

The four reports are cached in the ignored source_cache/mpi_ling_lin7wc_2026 directory. Their retrieval dates, URLs and SHA-256 checksums will be recorded in the source manifest with the imported records.

## Verified source coverage

FAR 2026/26 describes a two-sex age-based statistical catch-at-age model, ages 1-28 with age 28 as a plus group, and a Beverton-Holt stock-recruit relationship. The model fits annual catch biomass, sexed age compositions, bottom-longline and bottom-trawl CPUE, and Tangaroa survey biomass and age compositions.

The report gives the observation years for survey biomass and age compositions as 2000, 2012-13, 2016, 2018, 2021 and 2024. Bottom-longline CPUE covers 1990-2025; bottom-trawl CPUE covers 1997-2025. Commercial age-composition years are listed separately by fishery in Table 2.

FAR 2026/25 Appendix E reports annual scaled catch biomass by trawl, longline and potting fleet for 1972-2025. Appendix D reports adjusted CPUE values and CVs; the adjusted series includes the 1% annual learning-rate adjustment used in the assessment. The report does not state the CPUE unit.

FAR 2025/41 Table 16 reports the Tangaroa core survey biomass series from 2000 to 2024 with CVs. It also reports a separate all-strata series beginning in 2012. The core series is the one with the year coverage used in the assessment report. FAR 2026/06 Tables 15 and 23 report sex-specific 2023-24 commercial trawl and 2024 survey numbers-at-age with CVs. Dashes are defined as no data.

FAR 2026/26 Table 3 reports sex-specific growth and length-weight parameters, fixed M=0.18 per year, stock-recruit steepness h=0.84, recruitment variability sigma-R=0.6, ageing CV=0.05, male proportion at birth 0.5, and proportion of mature fish that spawn 1.0. Table 4 reports maturity-at-age only for ages 3-12 by sex. The model uses a January-December annual cycle and places observations at 0.5 of total mortality.

Tables 7-8 provide MPD biomass estimates, posterior median B0 and 2026 status relative to B0 with 95% credible intervals, and probabilities relative to the 40% and 20% reference levels.

## Source limits

The reports do not provide numeric historical age-composition vectors for every year used by the 2026 assessment. The latest age report supplies only the 2023-24 commercial trawl and 2024 survey estimates, and those tables contain no-data cells. Commercial longline age compositions for 2024 and commercial trawl age compositions for 2025 are listed in the assessment but were not numerically located.

A complete weight-at-age surface was not located; the model reports growth and length-weight equations instead. The published maturity schedule covers ages 3-12 only, while the model age grid is 1-28. No numerical annual N-at-age, F-at-age, recruitment or SSB trajectory was located in the detailed assessment report; those quantities are presented as figures. The report's 2026 B2026/B0 estimate is a posterior status ratio, not an absolute SSB estimate.
