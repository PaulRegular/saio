# NOAA golden tilefish source screen

**Screened:** 2026-10-30  
**Scope:** NOAA Stock SMART IDs 10384 (South Atlantic) and 10385 (Mid-Atlantic). This is a discovery screen; it adds no canonical stock, assessment, input, assumption, or output rows.

## South Atlantic (NOAA:10384)

The latest accepted Stock SMART run is assessment 14290, assessed in 2025 with data through 2022. The SEDAR 89 report was revised in September 2025 and describes a BAM catch-age model with fleet removals, commercial handline and longline age compositions, recreational removals, and a MARMAP longline index. Commercial age-composition methods are documented in SEDAR89-WP-06. The model uses ages 1-20+, with age-specific life history in Table 6. Table 7 reports annual N-at-age in thousands of fish, Table 8 reports biomass-at-age, and Table 10 reports SSB, recruitment, and apical F. The base mortality schedule is age-specific and its values are tabulated by age.

Inputs include report tables and figures. Age-composition arrays need to be extracted from the source paper and composition figures. The MARMAP index is annual, but its exact fractional observation time was not identified. The report states that SSB is evaluated at peak spawning on May 15 (0.37 of the year); this is not assumed to be the MARMAP survey timing. This unit is eligible for source curation, with digitization and index timing recorded as follow-up questions.

## Mid-Atlantic (NOAA:10385)

The latest accepted Stock SMART run is assessment 13544, assessed in 2024 with data through 2023, using WHAM. The June 2024 Management Track peer-review panel found the update technically sufficient for stock status and advice and identified it as Best Scientific Information Available. NOAA's SASINF search exposes final input-data and results reports, plus an assessment archive. The archive contains PDFs and a results image rather than a native fitted object.

The model uses catch and age compositions through 2023, ages 1-10+, commercial longline CPUE indices, annual weights-at-age, maturity-at-age, age-specific natural mortality, and age-specific outputs. The 2024 report summary provides SSB, fully selected F and age-1 recruitment for 2014-2023; SASINF results show N-at-age and SSB-at-age across the modeled series. Input and result matrices are mostly chart-based and will need digitization or additional file recovery. The assessment report remains labeled a draft in the public portal, so retain that publication-status caveat with any later extraction. This unit is eligible for source curation, with numerical matrix recovery as the main source task.

## Unit and provenance notes

NOAA identifies South Atlantic and Mid-Atlantic golden tilefish as separate management stocks; the South Atlantic assessment uses its own regional BAM and the Mid-Atlantic assessment its own WHAM. Preserve them as separate candidate units despite the shared species name. Do not treat the SEDAR report's broader study area or historical assessments as a reason to merge them.

The source files are cached in the ignored folder `source_cache/noaa_golden_tilefish_2025/`. Its manifest records URLs, revisions, retrieval date, byte size, and SHA-256. The candidate register records the evidence and screening decision. No canonical database rows have been added.