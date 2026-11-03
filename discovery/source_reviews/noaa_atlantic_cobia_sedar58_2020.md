# NOAA Atlantic cobia: SEDAR 58 (2020)

**Candidate:** NOAA:12149, Atlantic cobia (`Rachycentron canadum`), Georgia and north
**Screened:** 2026-11-02
**Decision:** Eligible for source curation; not imported yet.

## Identity and current assessment

The Stock SMART row is an inventory pointer, not the assessment-method source. The detailed SEDAR 58 report identifies the Atlantic stock and its 2020 BAM benchmark assessment. The revised base run, co23, is identified by the review panel as the definitive assessment. SEDAR 107 was still an undelivered benchmark at review time. NOAA:10390 is the distinct Gulf of Mexico cobia unit and remains separate.

## Recoverable age-structured inputs and outputs

The final run spans 1986–2017. It fits annual age compositions from general recreational landings, with age classes 1–12, as well as pooled commercial length compositions and a headboat CPUE index for 1991–2015. Commercial age compositions were not used because the samples were not representative of the commercial fleet. The model input includes age-specific natural mortality, female maturity-at-age, sex ratio, and age-specific weights for ages 1–15. The report documents spawning timing as a fraction of year; an observation-time fraction for the headboat index still needs checking in its supporting index document.

SEDAR 58 reports population, fishing-mortality, biomass, recruitment and reference-point results for the revised base run, with assessment uncertainty and diagnostics. The exact input tables and run outputs should be extracted from the report appendices/native source during curation; this screen does not add canonical database values.

## Screening interpretation

The source provides age-composition observations that are fitted in an age-structured model, total catch, an abundance index, age-specific biological inputs and official model outputs. It qualifies for future source curation. A tinyAM translation will need to preserve the distinction between general-recreational age compositions, pooled commercial length compositions and aggregate headboat CPUE; it should not imply that commercial catch-at-age was observed.

## Sources

- [SEDAR 58 Atlantic Cobia Stock Assessment Report, revised September 14, 2020](https://sedarweb.org/documents/sedar-58-stock-assessment-report-atlantic-cobia-revised-september-14-2020/)
- [SEDAR 58 CIE reviewer report (Casey)](https://sedarweb.org/documents/sedar-58-cie-reviewer-report-casey/)
- [SEDAR 58 project page](https://sedarweb.org/assessments/sedar-58/)

The SEDAR 58 report and reviewer report were downloaded to the gitignored local discovery cache. Their retrieval date, file size, URL and SHA-256 checksum are recorded in `source_cache/discovery_noaa_sedar_current_assessments_2026/sources.csv`.
