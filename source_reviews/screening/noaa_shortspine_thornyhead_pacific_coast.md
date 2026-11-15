# NOAA Pacific Coast Shortspine Thornyhead

## Stock identity and latest assessment

NOAA Stock SMART ID 10458 identifies the Pacific Coast shortspine thornyhead stock (*Sebastolobus alascanus*). The 2023 assessment covers the U.S. West Coast coastwide unit. No canonical database stock or cross-organization record for this same U.S. management unit was found; NOAA's Gulf of Alaska thornyhead complex (ID 10457) is a separate management unit and remains separate.

The 2023 assessment is the latest full detailed assessment located. It is a data-moderate, length-based age-structured Stock Synthesis model with data through 2022. The later 2025 update is a catch-only projection: it updates removals for 2023–2024, applies projected removals for 2025–2026, and extends management projections. It uses the 2023 assessment and does not add age-composition observations. The 2023 report, model archive and 2025 projection are cached under `source_cache/discovery_noaa_shortspine_pacific_2023/`; the ignored `sources.csv` manifest records retrieval dates, URLs and checksums.

## Inputs, biology and outputs

The 2023 model conditions on catch by three fishery fleets, survey biomass indices and length compositions from fisheries and surveys. Its native data file has a 100-age internal population grid and length-composition data, but no age-composition input section. The assessment report explicitly says no age-composition data were used because reliable production ageing is unavailable. Therefore, the reported age-specific population, catch and fishing-mortality surfaces are model-derived outputs; they are not observed age inputs and cannot establish catch-at-age or an age-specific survey index for this source screen.

Growth, weight and maturity are represented through length-based relationships. Natural mortality is fixed at 0.04 per year for both sexes in the archived 2023 model. Survey observations are timed to July (month 7) in the annual model. The native model archive reports age-specific N, catch and F outputs and the assessment reports spawning output, recruitment and stock status. The 2025 catch-only projection provides updated catch and management projections, not a new age-data likelihood.

## Decision

Screening decision: provisionally new as a distinct current U.S. Pacific Coast stock, but ineligible for the age-disaggregated input set. The existence of an internal age grid and derived age outputs does not replace the missing age observations. The 2023 assessment uses length compositions rather than age compositions, and no source-based age-specific catch or survey observation series can be recovered from its inputs without substituting model-derived quantities. The 2025 catch-only projection does not change that conclusion. Do not substitute the older 2013 age-structured assessment or the separate Gulf of Alaska thornyhead complex.

## References

- [2023 Shortspine Thornyhead assessment](https://www.pcouncil.org/documents/2024/02/status-of-shortspine-thornyhead-sebastolobus-alascanus-along-the-us-west-coast-in-2023.pdf)
- [2023 Shortspine Thornyhead model files](https://www.pcouncil.org/documents/shortspine-thornyhead-2023-model-files-zip-file/)
- [2025 catch-only projection for Shortspine Thornyhead](https://www.pcouncil.org/documents/2025/08/g-7-attachment-3-catch-only-projection-for-shortspine-thornyhead.pdf/)
