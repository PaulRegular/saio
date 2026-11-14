# Southern bluefin tuna: CCSBT 2026 assessment

## Stock unit and current assessment

The Commission for the Conservation of Southern Bluefin Tuna (CCSBT) assesses southern bluefin tuna as one stock across the Southern Hemisphere. The latest full assessment is the 2026 R-RTMB assessment, using catch data through 2025. The 2026 report says the population model remains an annual age-structured model with two seasons. The CCSBT website identifies this as the latest full assessment and schedules the next full assessment for 2029.

The canonical record uses one CCSBT-wide stock unit. National fishery fleets, sexes and model-grid cells are not counted as separate stocks or assessments. The Southern Ocean database basin label is a broad geographic grouping for this circumglobal Southern Hemisphere stock, not a claim that its distribution is confined to the Southern Ocean.

## Inputs recovered and unavailable

The 2026 assessment report describes total catch biomass for six fisheries, length compositions for four longline fisheries, and age compositions for the Indonesian and Australian surface fisheries. Other inputs include Japanese longline CPUE, CPUE-weighted Japanese length compositions, an aerial relative-biomass survey for ages 2–4, conventional tag recaptures, age-2 gene-tagging estimates, parent–offspring and half-sibling close-kin data, and estimates of unaccounted mortality.

The 2026 preparation paper gives input coverage and describes data issues, but does not publish the complete run-specific observation arrays. The official CCSBT public data page provides catch histories, aggregated catch and effort, and raised catch-at-size data for selected members; those public tables are not the 2026 age-composition likelihood vectors or the full model inputs. The data-submission rules describe age data as part of the member exchange, but that does not make the assessment files public.

The public sbt RTMB package documentation explicitly distinguishes its simulated example from the assessment source objects and identifies the 2026 source-data package as private. The 2024 OMMP workshop report likewise recorded that assessment input files were confidential. I did not locate a public fitted object or complete, run-matched input archive for the 2026 assessment. Accordingly, no input observations, catch-at-age, age compositions, weights-at-age, maturity-at-age, CPUE, or tag/close-kin arrays are imported.

Natural mortality is described in the 2026 assessment as a length-scaled curve through age 25, with estimated M10 and M30, fixed exponent -1, then a linear increase from M25 to M30. The preparation paper lists length-based maturity values, but the final assessment report does not confirm that those values were retained, so they are not imported as final-run assumptions.

## Reported outputs

Table 1 reports posterior medians and 95% credible intervals across the reference set. The 2026 estimates are relative total reproductive output (TRO) of 0.281 (0.209–0.373), relative age-10+ biomass of 0.231 (0.171–0.313), and a 0.011 probability that relative TRO is below 0.2. The table also reports F/FMSY of 0.553 (0.383–0.811), TRO/TROMSY of 0.985 (0.629–1.587), and MSY of 32,529 tonnes (26,400–39,381). The report identifies 2025 as the latest fitted catch year for the MSY quantities; 2026 is the status year for relative TRO and age-10+ biomass.

Table 4 reports a 0.990 probability that 2035 TRO exceeds 0.2 TRO0 and a 0.712 probability that it exceeds 0.3 TRO0. Median 2035 TRO/TRO0 is 0.339 (0.218–0.542); mean TAC for 2026–2035 is 25,399 tonnes (25,349–26,249). Only the reference-set, nominal-allocation projection is imported.

These are reproductive-output and relative reference-point measures. They are not absolute SSB, recruitment-at-age, or N/F/M-at-age series. The report includes fitted trajectory and composition figures, but not numerical annual age-specific output tables. The canonical output record is therefore partial.

The full assessment informs the 2026 stock-status reporting. The global TAC recommendation for 2027–2029 was produced by the Cape Town Procedure in 2025, rather than calculated from this 2026 assessment; the record does not treat that TAC as an output of the 2026 fit.

## Source status

This stock is recorded as one partially curated assessment. Its age-data eligibility remains unresolved because the assessment confirms use of age compositions and age-specific abundance information, but the run-matched numeric data required to verify coverage and preserve source values are not public in the reviewed sources. No older assessment is substituted for the current run. Revisit this record if CCSBT releases the 2026 source objects or an equivalent machine-readable archive.

## Sources

- [CCSBT latest stock assessment](https://www.ccsbt.org/en/content/latest-stock-assessment)
- [CCSBT ESC31/20: 2026 SBT stock assessment](https://www.ccsbt.org/system/files/2026-08/ESC31_20_AU-JP_sbt_stock_assessment_2026.pdf)
- [CCSBT OMMP16/09: 2026 data-input review](https://www.ccsbt.org/system/files/2026-06/OMMP16_09_AU_DataPrep2026Assessment.pdf)
- [CCSBT public SBT data](https://www.ccsbt.org/en/content/sbt-data)
- [CCSBT data-submission requirements](https://www.ccsbt.org/en/content/data-submission-requirements)
- [Public sbt model data documentation](https://www.quantifish.co.nz/sbt/articles/data.html)
- [CCSBT OMMP14 information paper on model development and data](https://www.ccsbt.org/system/files/2024-05/OMMP14_info01_Report_2023_OMWorkshop_Tokyo.pdf)

The three cached PDFs, source URLs, retrieval dates and SHA-256 checksums are recorded in provenance/ccsbt_sbt_2026_sources.csv. Cached PDFs are stored under the ignored source_cache/discovery_ccsbt_sbt_2026/ folder.
