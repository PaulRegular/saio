# ICES Faroes ling (lin.27.5b), 2026

**Stock unit:** Ling (*Molva molva*) in ICES Division 5.b, the Faroese grounds. This is distinct from Icelandic ling (*lin.27.5a*).

**Assessment:** The 2026 WGDEEP report identifies the final applied SAM run as `lin.27.5b_wgdeep2026_final`, fitted through 2025. ICES advice record 7205 and SAG key 23735 identify the assessment. The run-specific numeric records below come from the 2026 report tables; a native fit object and the exact data object were not recovered from the public run directory. This is therefore a verified but partial source record, not a tinyAM translation.

## Inputs and assumptions recorded

The canonical database now contains **1,172 inputs and 13 assumptions**:

- **Catch numbers-at-age:** 300 rows for ages 3–12+ and years 1996–2025, in thousand fish (Table 3.2.7). The report presents a combined catch-at-age series rather than fleet-specific arrays.
- **Catch weights-at-age:** 300 rows for ages 3–12+ and years 1996–2025 (Table 3.2.8). The report does not state the unit. Interpreting the values as kg per fish makes the reported N-at-age and weights reproduce the reported SSB and total biomass within 0.1% for every year. The database records this as an explicit consistency-based unit inference, with no numeric rescaling. The WKBARFAR 2021 benchmark selected catch weights as stock weights rather than spring-survey weights.
- **Spring survey:** 224 age-specific index rows for ages 4–11 in 1998–2025 and 28 annual effort rows (Table 3.2.9; G1264).
- **Summer survey:** 270 age-specific index rows for ages 3–11 in 1996–2025 and 30 annual effort rows (Table 3.2.10; G3284).
- **Survey scales and effort:** Index values and effort values are transcribed as reported. The report does not identify their absolute scale or define the effort unit/model role. No scaling, offset, or likelihood weight was added.
- **Survey timing:** Spring is described as February/March and summer as August, but exact SAM year fractions were not reported. `sampling_time` remains missing.
- **Gear-change downweighting:** The report says summer indices in 2021–2023 and spring indices in 2022–2024 were downweighted after the rockhopper-gear change. Numeric factors and implementation were not found, so no weights were invented or applied.
- **Biology and mortality:** Ten fixed maturity proportions are recorded for ages 3–12+ (0, 0.04, 0.19, 0.50, 0.79, 0.93, 0.98, 1, 1, 1); fixed natural mortality is 0.15 per year for all ages (section 3.2.5.5).

The input age column stores the terminal age as 12; the source plus-group meaning is documented in the associated notes and model-age assumption. Survey effort is kept as a covariate, separate from the age-specific index observations.

## Outputs recorded

The canonical database contains **720 output rows** for 1996–2025:

- Recruitment at age 3, SSB, Fbar ages 6–10, and total stock biomass: 120 aggregate rows with the published 95% confidence limits (Table 3.2.11).
- Fishing mortality-at-age and numbers-at-age: 300 rows each, point estimates without age-specific uncertainty (Tables 3.2.12–3.2.13). The report labels the terminal group as age 12; it is aligned with the model's age-12-plus group.

Reported units are thousands of fish for recruitment and numbers-at-age, tonnes for SSB and total biomass, and per year for fishing mortality. Source-table age surfaces reconcile with the reported summaries: recruitment equals age-3 stock numbers, SSB and total biomass reproduce from N-at-age and weights under the documented kg-per-fish inference, and arithmetic mean F-at-age 6–10 matches Fbar within rounding.

## Remaining gaps

The native SAM fit/data objects, exact survey index scale and effort definition, exact survey timing fractions, and numeric gear-change downweights remain unresolved. Those details may affect an eventual translation. No tinyAM fitting has been attempted while source curation for the selected batch continues.

## Sources and cached files

- WGDEEP 2026 report, ICES Scientific Reports 8:30: https://doi.org/10.17895/ices.pub.32051352.v1
- ICES advice record 7205: https://asd.ices.dk/viewAdvice/7205
- ICES Standard Graphs source data, assessment key 23735: https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23735
- ICES SAG XML, assessment key 23735: https://sg.ices.dk/SAG_API/StockXmlDownload/23735
- Final SAM run directory: https://stockassessment.org/datadisk/stockassessment/userdirs/user3/lin.27.5b_wgdeep2026_final/
- WKBARFAR 2021 benchmark report: https://doi.org/10.17895/ices.pub.7920
- The report links the 2021 stock annex at https://www.ices.dk/sites/pub/Publication%20Reports/Stock%20Annexes/2021/lin.27.5b_SA.pdf; the annex material is also included in the cached benchmark report. The direct legacy annex URL returned HTTP 401 during retrieval.

The files, retrieval dates, sizes, URLs, and SHA-256 checksums are in `source_cache/discovery_ices_ling_5b_2026/sources.csv`. The full WGDEEP report PDF is reused from the adjacent cached WGDEEP source directory; its provenance and checksum are recorded there.
