# Petrale sole - U.S. Pacific Coast

## Assessment and source selection

NOAA Stock SMART ID 10011 is the Pacific Coast U.S. management unit for *Eopsetta jordani*. It is distinct from Canadian petrale sole and the Alaska flatfish-complex entries. The latest full benchmark located is the 2023 Stock Synthesis assessment, fitted through 2022. The September 2025 catch-only projection updates removals using 2023-2024 information and provides two 2026 catch scenarios. NOAA's 2026 emergency action and the 2027-2028 harvest-specification analysis use the 2025 projection; the alternative Table 2 scenario is the basis for the adopted 2026 increase.

The official 2023 assessment report, native model archive, and 2025 projection are cached under `source_cache/discovery_noaa_petrale_10011/`. Their retrieval dates, source links, sizes, and SHA-256 hashes are recorded in `provenance/noaa_petrale_10011_sources.csv`. The native files identify Stock Synthesis 3.30.21.00, a final gradient of 0.00271749, final phase 7, 2,302 iterations, and total LogL 647.723.

## Inputs retained

The canonical record contains two separate assessment events: the 2023 full benchmark and the 2025 catch-only projection. The 2023 source import preserves the native observations without rescaling or replacing them with fitted values.

- **Catch:** 274 annual North and South observations from 1876-2022. Catch is retained in metric tonnes. The native `catch_se` field is also retained without assigning it a scale not stated in the source.
- **Survey indices:** 28 aggregate biomass-index observations from the Triennial survey and WCGBTS, 1980-2022. Native index values and `se_log` are preserved; no absolute abundance multiplier is applied. Both use season 7 and fleet timing code 1007. Sampling time is recorded as 0.5 using the July convention `(month - 1) / 12`.
- **Discard observations:** 43 North/South fractions of catch from 1985-2021, with the native `Std_in` values retained as observation CVs.
- **Mean body weight:** 40 North/South observations from 2002-2021, in kg per fish with their source CVs. These are mean-body-weight observations, not stock weight-at-age.
- **Length compositions:** 177 source samples from 1948-2022 in 2 cm bins from 12 to 62 cm. Fleet, sex code, partition, sample size and raw source frequencies are retained.
- **Age compositions:** 809 source samples from 1960-2022 in ages 1-17. Conditional age-at-length and marginal age compositions are distinguished; source age-error codes, length bounds, partitions, sex codes, sample sizes, and raw frequency values are retained.

Composition values are copied as supplied and are not normalized. Some are frequency totals rather than proportions. Sex code 3 carries one joint observation with separate female and male vectors; its sample size repeats for the two vectors and should not be added across sex. Sex code 0 is combined-sex data stored in the female vector. Negative fleet codes and negative years are retained in the row notes; Stock Synthesis excludes those composition records from the likelihood.

The native likelihood uses biomass catches and aggregate biomass indices together with length and age compositions. It does not supply observed catch-at-age or a direct age-specific survey abundance index. Fishery catch-at-age can be reconstructed downstream only with additional assumptions; it is not imported as an observed input. Model-generated weight-at-age, maturity-at-age, and M-at-age are kept in outputs and are not treated as observations.

## Assumptions and biological inputs

The 2023 model has one area, two sexes and ages 0-40. Recruitment follows a Beverton-Holt relationship with steepness fixed at 0.8; annual recruitment deviations are estimated for 1959-2020. Natural mortality is estimated for both sexes using meta-analytical priors. The female base estimate is about 0.142 per year. Growth, sex-specific weight-length relationships, maturity and fecundity are represented by model parameters. The source does not provide observed stock weight-at-age or maturity-at-age vectors.

The full control file, survey and fleet settings, ageing-error definitions, selectivity and parameter activation are preserved in the cached native archive but are not all transcribed parameter-by-parameter in the canonical assumptions table. Assumptions completeness therefore remains partial.

## Outputs retained

The 2023 `Report.sso` provides annual fitted and forecast time series from 1876 through 2034, with the fitted data ending in 2022 and forecasts from 2023 onward. The import retains total and age-3+ summary biomass, spawning output, age-0 recruitment, numbers and biomass at age, fleet-specific F-at-age and dead catch-at-age, M-at-age, beginning-of-year weight-at-age, and the 2034 terminal biology table's maturity-at-age. Total abundance is derived by summing native N-at-age across ages and sexes and has no uncertainty.

Spawning output is reported in trillions of eggs; it is not spawning biomass. The 2023 report's Tables ii and iii provide 95% intervals for spawning output and recruitment for 2013-2023. No uncertainty is assigned to age-specific surfaces or derived total abundance.

The 2025 projection Tables 1 and 2 are retained as two separately labelled scenarios through 2036. They provide updated and assumed removals, OFL, buffer, ABC, ACL, spawning output and fraction of unfished spawning output. These projection estimates are rounded and have no reported uncertainty intervals. Table 2 assumes 2026 removals equal 92% of the 2,489 mt ACL; NOAA implemented the resulting 2026 harvest-specification increase in its 2026 emergency action.

## Status and remaining source gaps

The 2025 catch-only projection is the current applied event; the 2023 full benchmark is retained as its base assessment. Inputs, assumptions and outputs remain marked partial because the source likelihood is not a direct age-structured catch/index series, biological age surfaces are model-generated, detailed control settings are not fully transcribed, and age-specific output uncertainty is not tabulated in the report. The cached covariance output is available for later inspection but has not been converted into age-surface intervals.

## Sources

- [Status of Petrale Sole along the U.S. West Coast in 2023](https://www.pcouncil.org/documents/status-of-petrale-sole-eopsetta-jordanialong-the-u-s-west-coast-in-2023/)
- [Petrale Sole 2023 Stock Synthesis model files](https://www.pcouncil.org/documents/petrale-sole-2023-model-files-zip-file/)
- [Catch-only projection for Petrale Sole, September 2025](https://www.pcouncil.org/documents/2025/09/g-8-supplemental-attachment-3-catch-only-projection-for-petrale-sole.pdf/)
- [NOAA 2026 emergency action](https://www.fisheries.noaa.gov/action/emergency-action-temporarily-increase-2026-harvest-specifications-and-sector-allocations-for-shortspine-thornyhead-canary-rockfish-and-petrale-sole)
- [Harvest Specifications Analysis for the 2027-2028 Biennium](https://www.pcouncil.org/documents/2026/03/c-4-attachment-1-harvest-specifications-impact-analysis-for-2027-28-biennium.pdf/)
