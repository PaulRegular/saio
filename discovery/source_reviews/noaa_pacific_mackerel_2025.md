# NOAA Stock SMART 10163: Pacific mackerel, 2025

Reviewed 2026-10-29. NOAA Stock SMART 10163 is the U.S.-managed Pacific
mackerel sub-stock of *Scomber japonicus* along the Pacific coast north of
Punta Abreojos, Baja California. It is a transboundary assessment unit that
includes U.S. and Mexican fisheries. No matching canonical tinyAM stock record
was found.

## Latest assessment and inherited data

The latest official assessment located is the 2025 catch-only assessment for
the 2025-26 and 2026-27 fishing years. The Pacific Fishery Management Council
and its Scientific and Statistical Committee adopted its biomass estimates in
April 2025. It uses the 2023 benchmark's age-structured Stock Synthesis model
structure and updates the catch data. The 2025 assessment uses Stock Synthesis
3.30.22.1; it updates commercial/recreational landings through model year 2023
and forecasts landings for 2024-2026. Its likelihood summary still contains
age-composition and survey components, confirming that the 2023 fishery and
acoustic-trawl age data remain part of the latest fitted model.

The inherited benchmark data cover model years 2008-2021, with annual July-
through-June model years, combined sexes and age groups 0-8+. The model has one
combined fishery and one summer Acoustic-Trawl (AT) survey. Fishery age
compositions are based on California commercial samples; AT survey age
compositions are also fitted. The 2023 model input file records the AT index
observations at model month 1.6. Catch is entered as biomass; the 2025 report
provides updated catch values through model year 2023. This supports
source-based reconstruction of catch-at-age for years with fishery age
compositions. Years after 2021 have updated aggregate catch but no new age
compositions.

The model fits an aggregate AT abundance index with the survey age
compositions. Empirical weight-at-age is used for the fishery and AT survey;
survey weight-at-age is derived from the acoustic-trawl abundance-at-length,
length-weight relationship and age-length keys. A fixed age-specific maturity
vector is estimated from summer AT samples of 494 female fish and multiplied
by a fixed fecundity vector. Natural mortality is age-specific with a Lorenzen
pattern; the average M is estimated using a longevity-based prior. These inputs
and settings are documented in the 2023 benchmark report and model archive,
and the 2025 report says the update retained the same model structure.

The 2025 report gives age-1+ biomass estimates of 61,737 mt (SD 41,422) for
model year 2025 and 67,954 mt (SD 43,375) for model year 2026. It also reports
recruitment and fishing-mortality/exploitation trajectories. The available
public report provides model-level results, but run-matched annual numeric
N-at-age and F-at-age output tables were not located. The 2025 assessment is
eligible for the current age-disaggregated source set: age compositions,
empirical weights-at-age, maturity, M, the survey index, and official biomass
outputs are documented. The age-composition series ends in 2021, so the latest
catch years have less age-specific information.

## Inventory discrepancy

The cached NOAA Stock SMART metadata lists a 2025 row for this stock but gives
`last_data_year = 2024`, Stock Synthesis 3.30.20, and a 2022 biomass value of
46,682 mt. Those fields do not match the detailed 2025 catch-only report,
which documents Stock Synthesis 3.30.22.1 and 2025/2026 model-year biomass
forecasts. The report and Council adoption record were used to identify the
latest run; the Stock SMART discrepancy is retained as a metadata limitation,
not used to replace the run-specific report values.

No assessment event or numerical input/output records were added to the
canonical database. Import status remains `not_started`.

## Sources

- [PFMC 2025 catch-only assessment](https://www.pcouncil.org/documents/2025/05/catch-only-stock-assessment-of-pacific-mackerel-scomber-japonicus-for-u-s-management-in-the-2025-26-and-2026-27-fishing-years.pdf)
- [NOAA Repository record for the 2025 assessment](https://repository.library.noaa.gov/view/noaa/67353)
- [Federal Register: 2025-26 and 2026-27 Pacific mackerel specifications and Council adoption](https://www.govinfo.gov/content/pkg/FR-2025-08-25/pdf/2025-16233.pdf)
- [PFMC 2023 benchmark assessment](https://www.pcouncil.org/documents/2023/06/assessment-of-pacific-mackerel-scomber-japonicus-for-u-s-management-in-the-2023-24-and-2024-25-fishing-years.pdf)
- [PFMC 2023 benchmark model files](https://www.pcouncil.org/documents/mackerel-2023-model-files-zip-file/)
- [NOAA Pacific mackerel status](https://www.fisheries.noaa.gov/species/pacific-mackerel)
- NOAA Stock SMART snapshot `stock_assessment_summary.rda`, revision `664c4237e26520b260a090e1821a2cee5d1cdf07`; its source URL and checksum are in the discovery inventory README.

The 2025 report, 2023 benchmark report and 2023 model archive are stored in
the gitignored `source_cache/discovery_noaa_pacific_mackerel_2025/`; its
`sources.csv` records retrieval dates, URLs and SHA-256 checksums. The model
archive is also unpacked in that ignored directory for local review.
