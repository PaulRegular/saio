# NOAA golden tilefish assessments

**Reviewed:** 2026-11-10
**Scope:** NOAA Stock SMART IDs 10384 (South Atlantic) and 10385 (Mid-Atlantic). These are distinct management units and remain separate candidate records.

## South Atlantic (NOAA:10384)

The latest accepted run identified in NOAA Stock SMART is assessment 14290 (SEDAR 89 Rev2), assessed in 2025 with data through 2022. The report describes a Beaufort Assessment Model (BAM) catch-age assessment with commercial handline, commercial longline and recreational removals, commercial age compositions, aggregate commercial and MARMAP indices, and ages 1-20+.

The official report and supporting documents are cached under the ignored `source_cache/noaa_south_atlantic_golden_tilefish_sedar89_2025/` directory; URLs, revisions, retrieval dates, sizes and checksums are recorded in the tracked manifest. The report supplies numeric removals (Table 1), composition sample counts (Tables 3-4), aggregate indices and CVs (Table 5), fixed life-history inputs including maturity, reproductive potential and M-at-age (Table 6), age-specific population and fishing outputs (Tables 7-17), management quantities and uncertainty summaries (Table 18), and projections (Tables 19-21).

Table 1 reports commercial removals in thousand gutted pounds and recreational landings in thousand fish. Table 5 provides a relative commercial-longline biomass index for 1993-2006 and a relative MARMAP longline abundance index for 1996-2016, with paired CVs. The report says the model evaluates both index series at midyear; this is retained as model observation timing, not asserted as the physical survey date. Table 6 reports whole and gutted weights, female proportion, female maturity, egg production per female, and fixed age-specific M. Table 10 defines SSB as egg production by mature females at peak spawning on May 15 (0.37 of the year).

Tables 3-4 provide sample counts, not the numeric observed composition vectors. Composition values are shown in figures and were not digitized. The numerical ageing-error matrix described by the report was not found in the reviewed documents. Tables 7-17 provide annual point estimates of N, biomass, F, fleet selectivity and landings by age or fleet; annual uncertainty for these surfaces is not supplied in the tables. The source import is therefore marked **partial**, while retaining all verified material.

Table 18's reported SSBMSY and MSST values conflict by about a factor of 1,000 with the corresponding Section 4.8 narrative values and the egg scale in Table 10. The import stores the table values as printed and narrative values separately, with the discrepancy clearly marked. It does not silently rescale either source representation.

## Mid-Atlantic (NOAA:10385)

The latest accepted Stock SMART run is assessment 13544, assessed in 2024 with data through 2023, using WHAM. The June 2024 Management Track peer-review panel found the update technically sufficient for stock status and advice and identified it as Best Scientific Information Available. NOAA's SASINF search exposes final input-data and results reports, plus an assessment archive. The archive contains PDFs and a results image rather than a native fitted object.

The model uses catch and age compositions through 2023, ages 1-10+, commercial longline CPUE indices, annual weights-at-age, maturity-at-age, age-specific natural mortality, and age-specific outputs. The 2024 report summary provides SSB, fully selected F and age-1 recruitment for 2014-2023; SASINF results show N-at-age and SSB-at-age across the modeled series. Input and result matrices are mostly chart-based and will need digitization or additional file recovery. The assessment report remains labeled a draft in the public portal, so retain that publication-status caveat with any later extraction. This unit is eligible for source curation, with numerical matrix recovery as the main source task.

## Unit and provenance notes

NOAA identifies South Atlantic and Mid-Atlantic golden tilefish as separate management stocks; the South Atlantic assessment uses its own regional BAM and the Mid-Atlantic assessment its own WHAM. Preserve them as separate candidate units despite the shared species name. Do not treat the SEDAR report's broader study area or historical assessments as a reason to merge them.

The Mid-Atlantic unit has not yet been imported. Its detailed input and output series are mostly chart-based in the public SASINF reports, and the assessment report remains publicly marked as a draft despite peer-review acceptance for management. Do not merge South Atlantic and Mid-Atlantic records based on species identity.
