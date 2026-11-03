# North Sea turbot source review

## Assessment selected

The stock is ICES `tur.27.4`, North Sea turbot (*Scophthalmus maximus*), matched to the existing Charbonneau–Keith record `ck_ices_wgnssk_maximus_ns_4`. The existing stock record was corrected to the official scientific and common names while retaining its stable stock ID. The most recent detailed assessment recovered is the final 2025 WKBNSCS benchmark model, run M9 (Fixed Lorenzen's M), with data through 2023. It is retained as the current detailed record. The M9 run was not the model used for 2025 advice.

ICES published 2026 advice and a source-data table with aggregate recruitment, SSB and Fbar through 2025 plus 2026 forecast values. The 2026 table is recorded as a separate summary-only assessment, not combined with the M9 benchmark. The 2023 SSB differs between the sources (3,564.575 t in the M9 object versus 4,685 t in the 2026 table), confirming that their outputs must remain distinct. The detailed model run behind the newer summary was not recovered.

## Sources and local cache

- [WKBNSCS 2025 report](https://doi.org/10.17895/ices.pub.28715180), Turbot in Subarea 4, especially Tables 2.2, 2.5–2.8 and Section 2.6. The report identifies run 9* as the final benchmark model.
- [Final M9 fitted object](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/tur4.m9/run/model.RData), corresponding data object and configuration under the same public `tur4.m9` run directory.
- [ICES 2026 Advice View](https://asd.ices.dk/viewAdvice/5097) and [2026 Stock Assessment Graphs source table, key 22472](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22472).

The report, fitted object, configuration, native input files and 2026 summary pages are cached locally under the gitignored `source_cache/ices_turbot_north_sea_preflight/`. `manifest.csv` records retrieval URLs, UTC timestamps and SHA-256 checksums.

## Recovered model inputs and assumptions

The M9 model covers 1981–2023, ages 1–8 with age 8 as the plus group. It has one residual-catch fleet, the BTS+COAST age-structured survey (1991–2023, ages 1–7), and the BSAS survey (2019–2023, ages 1–8). Both surveys use timing 0.705. Catch-at-age is in thousands of fish; multiplying it by catch weights in kg per fish gives tonnes and closely reproduces the official 1981 total catch (4,759 t calculated versus 4,755 t published, rounded).

Annual catch weights and stock weights are supplied as kg per fish and are internally estimated with SAM GMRF weight models. The canonical input table contains 242 observed stock-weight year-age cells. The fixed female maturity vector is 0, 0.01, 0.58, 0.98, 1, 1, 1, 1. Natural mortality is fixed to the age-varying Lorenzen vector in `nm.dat`; it is an input, not an estimated M surface. The M9 configuration includes AR(1) correlation among F states by age, ties ages 7 and 8 to the same F state, and defines Fbar over ages 2–6. Full configuration keys are retained in the assumptions table.

The age-specific survey values remain on their native relative-index scales. The physical multiplier is not stated, so values are preserved as a native index scale without a guessed conversion. The final benchmark configuration includes BTS+COAST and BSAS separately and excludes Dutch commercial LPUE. Missing observation cells remain missing.

## Recovered outputs and uncertainty

The M9 object supplies fitted numbers-at-age and fishing mortality at age for 1981–2023. Age 8 is 8+, and ages 7 and 8 share a single fitted F state. Recruitment is abundance at age 1. SSB and Fbar are extracted with the `stockassessment` package table methods; Fbar is ages 2–6. Their low/high bounds are generated as exp(log estimate ± 2 standard errors) on the log scale. The log-scale standard errors for N-at-age and F-at-age are retained with their scale stated in row notes. Total abundance is derived by summing N-at-age, with uncertainty left blank because cross-age covariance was not propagated for that sum.

M is fixed, so the database records its age-specific input and does not present it as an estimated output. The 2026 summary table's low/high values are retained as published; its interval level is not stated. For 2026, the table supplies forecast SSB and recruitment but no bounds or F value.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/ices_turbot_north_sea.md). They do not determine source completeness or official run selection.
