# NOAA inventory rows for Atlantic yellowfin and bigeye tuna (ICCAT assessments)

Reviewed 2026-10-30. NOAA Stock SMART rows 10166 (Atlantic yellowfin) and 10169 (Atlantic bigeye) are inventory records for single Atlantic-wide ICCAT stock units. They are not separate U.S. regional assessment units. No existing canonical tinyAM stock record matches either unit.

## Atlantic yellowfin tuna

ICCAT lists the 2024 Stock Synthesis assessment as the latest assessment, using data through 2022. The meeting report says results remain preliminary pending SCRS/Commission adoption. The model uses nominal catches, fleet/year/season length compositions, and three aggregate abundance indices: the Region 2 joint longline series (1979-2022), seasonal acoustic buoy index (2010-2022), and purse-seine free-school index (1993-2022). Conditional age-at-length observations from fleets 13 and 17 in 2007-2021 are included to estimate growth. The report does not describe these as catch-at-age or population age compositions. The assessment uses a length-weight relationship, maturity at length, and age-specific M assumptions. Reported outputs include SSB and aggregate exploitation/stock-status trajectories; numeric annual N-at-age and F-at-age surfaces were not located.

Eligibility remains unresolved because the reports do not provide the numeric conditional age-at-length and fleet length-composition arrays needed to determine whether a defensible, limited catch-at-age reconstruction can be made. This uncertainty is separate from the clear fact that age-at-length informs growth rather than serving as an age-specific abundance index.

## Atlantic bigeye tuna

ICCAT lists the 2025 Stock Synthesis assessment as the latest assessment, using data through 2023. The meeting report says results remain preliminary pending SCRS/Commission adoption. The final reference case is run 9 in a seasonal, one-area, combined-sex model. It uses nominal catch, fleet/year/season length compositions, a Region 2 joint longline index, and a quarterly juvenile index (acoustic buoy or purse-seine FAD in separate uncertainty runs). The fitted observation data are not age-stratified. The data-preparation report specifies growth and weight-length assumptions, maturity at length, and a Lorenzen age-specific M schedule with uncertainty grid scenarios.

The assessment report shows derived age-specific exploitation estimates for 2017-2023, calculated from predicted catch-at-age divided by estimated numbers-at-age. These are fitted outputs, not observations. A full annual N-at-age or F-at-age output table and the underlying numerical input matrices were not located. Eligibility remains unresolved pending evidence that the source data support an age-disaggregated input reconstruction.

## Sources and local cache

- [ICCAT stock assessments](https://www.iccat.int/en/assess.html), latest assessment/model listing for both species.
- [2024 Atlantic yellowfin assessment report](https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_YFT_SA_ENG.pdf).
- [2024 Atlantic yellowfin data-preparation report](https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_YFT_DP_ENG.pdf).
- [2025 Atlantic bigeye assessment report](https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_BET_SA_ENG.pdf).
- [2025 Atlantic bigeye data-preparation report](https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_BET_DP_ENG.pdf).

All four PDFs are cached in `source_cache/noaa_iccat_tunas_2024_2025/`. The ignored local `manifest.csv` records each source URL, report revision, retrieval time, byte size, and SHA-256 checksum. No canonical stock, assessment, input, or output records were added.
