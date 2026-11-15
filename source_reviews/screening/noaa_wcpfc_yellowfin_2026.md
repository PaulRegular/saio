# Western and Central Pacific yellowfin tuna

**Reviewed:** 2026-11-13
**Candidate:** NOAA Stock SMART 11694
**Stock unit:** WCPFC Western and Central Pacific yellowfin tuna (*Thunnus albacares*)
**Assessment record:** wcpfc_wcpo_yellowfin_2026
**Import status:** Partial; the latest detailed run is diagnostic and is not the current advice basis.

## Stock and assessment status

Stock SMART identifies the WCPFC Western and Central Pacific unit, separate from Eastern Pacific and Indian Ocean yellowfin. Its latest listed assessment is the 2023 PIFSC assessment, data through 2021, marked Full acceptance. The latest detailed model files located are for the 2026 WCPFC assessment, with data through 2024. The report says this run was not reviewed at SC22 for management advice and its review was deferred to SC23. The database therefore records the 2026 detailed run as current for source coverage but not applied as an advice result; the 2023 assessment remains the latest assessment identified as accepted for advice.

The 2026 model has quarterly time steps, five model areas and 40 quarterly age classes. Class 40 is a plus group; these are not 40 annual ages.

## Inputs preserved

- The native MFCL fishery file has 8,225 fishery-time records. Catch flags distinguish longline catch in fish numbers from other extraction catches in tonnes. The database preserves fleet, area and quarter. Non-negative effort values are retained in their source units; the source uses different units among gears.
- The TAF table has 297,920 preprocessed length-frequency values for 1956–2024, across 36 fisheries, 95 two-centimetre bins and four quarters. These frequencies are preserved as supplied, including fractional values. The export does not supply the unweighted sample size after preprocessing.
- The otolith export contains 1,873 individual fish with conditional age-at-length information from 2006–2024, across five areas and four quarters. These aggregate to 1,631 age-by-length cells in 1,229 year-quarter-area-length samples. They inform growth; they are not marginal catch-at-age or age-specific abundance observations. The reported ess field is retained separately as 1,229 source likelihood-weight rows.
- Five quarterly longline CPUE series cover 1952–2024 (1,452 observations). The values match native fishery catch divided by effort and 1,000,000. The TAF export does not include the CPUE CV time series, so no CV values were added.
- The regional-scaling table contains 1,420 year-area-quarter values from 1954–2024. They are preserved on their native scale as model covariates used in the regional-scaling penalty, not as abundance indices. Their physical units are not established by the export.
- Tag files contribute 13,585 release-frequency rows and 6,331 recapture-count rows. The source does not establish that release frequencies are raw tag counts, so their scale is left as supplied.

## Outputs preserved

The pinned TAF exports contain 58,400 numbers-at-age rows, 17,520 annual fishing-mortality-at-age rows, 58,400 mature-biomass-at-age rows, 1,460 regional/quarterly biomass rows, 1,460 predicted-index rows and 9,052 fishery-level predicted-catch rows. Eight area-5 predicted CPUE values for 1952–1953 are blank in the source and remain missing. Annual summary exports add recruitment, total biomass, spawning-potential biomass, unfished spawning potential, ratios, mean F and 73 annual aggregate-catch predictions. The biology export supplies model-derived length, weight, maturity and natural mortality for 40 quarterly age classes.

These are point estimates from MFCL Model 16, Diagnostic2026. The pinned outputs do not contain standard errors or confidence limits. The report describes a 48-model uncertainty ensemble, which is not represented by these single-run exports. Input and output completeness therefore remain partial.

## Remaining source gaps

The detailed source package does not provide catch-at-age or an age-specific abundance index. Age-at-length samples are conditional growth data and do not become marginal age-composition observations without additional reconstruction choices. The export also omits the CPUE CV time series and final effective sample sizes for the reweighted length compositions. Independent observed weight-at-age and maturity-at-age inputs were not recovered; the imported surfaces are fitted model outputs. No uncertainty estimates were found for the imported Diagnostic2026 outputs.

## Provenance

The local, gitignored cache is source_cache/discovery_noaa_wcpo_yellowfin_2026/. Its tracked manifest records URLs, retrieval dates, sizes, checksums and the pinned SPC repository revision b00a02f3537ef54520b219488f899188ea6eff3f.

- [2026 WCPFC assessment report, WCPFC-SC22-2026-SA-WP05 Rev. 01](https://meetings.wcpfc.int/node/32678)
- [2026 assessment input paper, WCPFC-SC22-2026-SA-IP03 Rev. 01](https://meetings.wcpfc.int/file/21826/download)
- [WCPFC SC22 outcome notice](https://www.wcpfc.int/node/244)
- [Pinned SPC diagnostic repository](https://github.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/tree/b00a02f3537ef54520b219488f899188ea6eff3f)
- [NOAA Stock SMART ID 11694](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11694)
