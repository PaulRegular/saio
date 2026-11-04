# North Sea sole source review

## Assessment selected

The stock is ICES `sol.27.4`, Solea solea in Subarea 4 (North Sea), matched to the existing Charbonneau–Keith catalogue record `ck_ices_wgnssk_solea_ns_4`. The latest detailed production assessment recovered is WGNSSK 2026. Its Stock Synthesis 3 model uses data through 2025 and reports population estimates through 2025, with 2026 advice-year summary values. The current advice is ICES 2027 advice based on assessment key 23777. The 2024 WKBFLATFISH benchmark introduced the Stock Synthesis 3 reference model.

The previous detailed run is WGNSSK 2025, with data through 2024 and a 2025 forecast. It remains in the database as a historical assessment; its source data are not carried forward into the 2026 record.

## Sources and local cache

- Current detailed assessment: [WGNSSK 2026](https://doi.org/10.17895/ices.pub.32676345), Tables 16.3–16.12 provide catches, weights, biology, abundance indices, N-at-age and F-at-age.
- Historical detailed assessment: [WGNSSK 2025, North Sea sole chapter](https://ndownloader.figshare.com/files/59358092), from [ICES WGNSSK report, version 4](https://doi.org/10.17895/ices.pub.29085995.v4).
- Framework: [WKBFLATFISH 2024](https://doi.org/10.17895/ices.pub.25471987.v1). The sole chapter documents survey standardization, benchmark choices and SS3 structure.
- Annual summaries: [ICES SAG 2025, key 21217](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21217) and [ICES SAG 2026, key 23777](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23777), with the corresponding XML exports.

The PDFs, extracted text and SAG HTML/XML are cached locally under the gitignored `source_cache/ices_sole_north_sea_2025/`. `SOURCES.md` there records retrieval date, source versions, URLs and SHA-256 hashes. Public ICES TAF/GitHub searches did not identify a matching native 2026 SS3 run archive; this import therefore uses the detailed official report tables and the ICES SAG machine-readable outputs.

## 2026 inputs

- Landings-at-age: 1957–2025, ages 0–10+, in thousand fish. Discards-at-age: 2002–2025, ages 0–10+, in thousand fish. Age 0 is explicitly reported as zero. Earlier discards are reconstructed in total from landings, but an age allocation is not tabulated.
- Landings weights, discard weights and stock weights: 1957–2025, ages 0–10+, in kg per fish. The report gives age-0 landings weight as 0.01 kg. Quarter-2 catch weights are used as stock weights at the start and end of spawning.
- Maturity and natural mortality: fixed, age-specific values for ages 0–10+. Maturity is knife-edged at age 3. M follows the reported Lorenzen formulation, with exponent −0.288; the values in Table 16.8 are the source values, not estimated surfaces.
- BTS and combined COAST (SNS + DYFS) abundance indices: one annual aggregate value per survey for 1990–2025. The report does not specify a physical scale multiplier, so the reported relative scale is retained. Both are Q3 surveys. Its rows follow ages 0–10 in order and its columns are labelled 0–10. The printed rows for ages 9 and 10 sum to 0.991 and 0.910; they are preserved as printed and not normalized.

## 2026 outputs and assumptions

The report provides N-at-age and F-at-age point estimates for 1957–2025, ages 0–10+. The complete N surface supports a derived total-abundance series by summing ages; uncertainty is not available for either the age-specific or derived totals. Aggregate recruitment, SSB and Fbar remain from the corresponding ICES SAG series (key 23777); SAG supplies uncertainty for historical estimates through 2025, while the 2026 advice-year row is a forecast with recruitment and SSB but no Fbar.

The 2026 production model is SS3 3.30.24.2, single-area and single-sex, ages 0–10+, with recruitment at the start of the year and Beverton–Holt stock recruitment with fixed steepness 0.6646. SSB is calculated at the start of the year, and Fbar covers ages 2–6. Landings selectivity is logistic and fixed except during pulse-trawl years 2011–2021; discards and both survey indices use double-normal selectivity. The 2016 age-reading matrix is retained even though a 2024 exchange produced an updated matrix.

The WGNSSK report's convergence paragraph describes a maximum gradient of 0.0001762 as exceeding a threshold of 0.001. Those values conflict; the database does not use that sentence as independent evidence about convergence.

The 2026 source record is partial because native SS3 files, full likelihood details and age-specific uncertainty were not recovered. Report tables and SAG summaries are kept tied to the same 2026 assessment ID; the 2025 values remain a separate historical record.

## 2025 historical inputs

- Landings-at-age: 1957–2024, ages 1–10+, in thousand fish. Discards-at-age: 2002–2024, ages 1–10+, in thousand fish. Age 0 is not reported in these catch tables and is left absent.
- Landings weights-at-age: ages 1–10+, 1957–2024. The report explicitly gives age-0 landings weight as a constant 0.01 kg; that value is recorded for each year. Discard weights and stock weights cover ages 0–10+ and 1957–2024. All weights are in kg per fish.
- Maturity and natural mortality are fixed age vectors for ages 0–10+. Maturity is knife-edged at age 3. M is not estimated; the reported rates follow the size-based Lorenzen formulation, with exponent −0.288 and scaling based on maximum validated age 26.
- The age-specific survey series are the Q3 BTS index (ages 0–10+, 1990–2024) and the Q3 COAST index combining SNS and DYFS (ages 0–5, 1990–2024). The report’s index tables do not state a physical multiplier, so original values are retained as relative-index units. The report says aggregate survey-biomass indices also inform model scale; their reported values closely match the rounded sums of the age-specific tables.

## 2025 historical outputs and assumptions

The 2025 report provides point estimates of N-at-age (1957–2024, ages 0–10+) and F-at-age (1957–2024, ages 1–10+); it does not provide age-specific uncertainty. The ICES SAG 2025 XML supplies recruitment, SSB and Fbar summaries and lower/upper bounds. Its bounds are defined as mean ± 2 SD; those bounds are retained directly, and no standard errors are inferred. Recruitment is in thousand fish, SSB in tonnes, and Fbar is the mean F over ages 2–6. The ICES SAG 2026 XML supplies the comparable aggregate summary series through 2026; the 2026 row contains recruitment and SSB but no Fbar.

The production model is single-area and single-sex, with separate landings and discards fleets, age-0 recruitment at the beginning of the year, a Beverton–Holt stock-recruitment relationship with fixed steepness 0.6646, time-varying landings selectivity, time-invariant discards and survey selectivity, and selectivity/catchability constraints from age 5 onward. SSB is calculated at the start of the year. The 2016 age-reading-error matrix is retained in the assessment, but its numerical values were not recovered from the cached report tables.

## Completeness and source gaps

Both assessment records remain partial. For 2026, the numerical catch-at-age, weight, fixed biology, aggregate-index and age-specific output tables are present, but native SS3 files, full likelihood details and age-specific uncertainty are unavailable. For 2025, the original source extraction and its limits are retained as historical data. Fixed M is an input, not an estimated M output.

The recovered BTS and COAST observations are aggregate biomass indices. No matching 2026 age-composition series was recovered. Age compositions are not inferred from fitted abundance.
