# DFO Northern contingent Atlantic mackerel, 2025

## Assessment identity and source selection

The existing Charbonneau–Keith row `DFO-QC_scombrus_4T` is retained as stock `ck_dfo_qc_scombrus_4t`. DFO's 2025 assessment is for the northern contingent of Atlantic mackerel in the Northwest Atlantic, whose main spawning area is NAFO Division 4T. The stock's area description now reflects that assessment scope while retaining the catalogue identifier and 4T context.

The official assessment is the 2025 run summarized in DFO Science Advisory Report 2026/040, published in August 2026. The numerical inputs, fitted outputs, code and fit object are from the DFO mackerel assessment repository, pinned at commit `435d10bcb6ee64e0d94c77f6854e0d37f53e4b8b`; the CCAM model code is pinned at `1bcb06473343c13ebeebecdb54acd905220aeb61`. The source script `Rscripts/2025/script.R` loads `Rdata/2025/fit.Rdata`, and `Rscripts/2025/surplus/save_csv.R` exports the fitted tables used here.

DFO Research Document 2025/054 is the detailed report for the preceding 2024 assessment. It is used only for method and age-group context, never as a source of 2025 values. The current 2026/040 publication record's English and French PDF URLs both returned archived HTML responses on 2026-10-19; the responses are retained in the ignored local cache with their correct `.html` extensions. No PDF was available from those URLs during this import. The pinned model repository supplies the source files used for the 2025 assessment.

Source files are cached under `source_cache/dfo_northern_mackerel_2025/`. Its ignored `manifest.csv` records source URLs, retrieval date, checksums, repository revisions, and unsuccessful PDF retrievals.

## Model dimensions and inputs

The source files span 1968–2025; the run script drops 1968 before fitting. The model uses ages 1–10+, with age 10 as the plus group. The detailed 2024 report and source configuration are consistent with this age range.

The canonical input rows preserve the source model streams:

- Commercial catch-at-age is reported in thousands of fish for 1969–2025, ages 1–10+. The source model passes these values as age-composition data, transformed with continuation-ratio logits; tinyAM's direct lognormal catch-at-age likelihood is not equivalent.
- The source model's annual total-catch bounds are retained separately from their components. The run script reconstructs the lower bound as `ct * 1.10 + ctUSA * 0.20` and the upper bound as `ct + ctUnaccounted + ctUSA * 0.80`, in tonnes. The underlying annual catch, U.S. catch component and unaccounted-catch allowance are also retained so the reconstruction is reproducible. `ctForeign.dat` is read by the script but is not passed to the fitted data object.
- The aggregate total egg production (TEP) index has 39 observations from 1979–2025. The values are stored in their native trillion-egg scale, with source timing 0.47. This scale is supported by DFO Research Document 2022/068, Table S9, and the 2024 detailed report's TEP discussion. The 2025 run script multiplies the raw TEP values by 1e9 for its internal likelihood scale; the database retains the native source values and records the internal scaling separately. The CCAM TEP prediction sums abundance, maturity, female fraction and fecundity across ages after mortality to sampling time. Its code adds F only where `keySel < 0`; the 2025 run assigns nonnegative keys 0–4. TEP is an aggregate fecundity-weighted egg index, not an age-specific fish-abundance or biomass index.
- Annual age-specific maturity, stock weight, January 1 stock weight, catch weight, fecundity, female proportion, pre-spawning F and M fractions, and natural mortality are retained for 1969–2025, ages 1–10+. Natural mortality is fixed at 0.28 per year. Both pre-spawning fractions are 0.47 at every modeled age and year. Fecundity and female proportion are used in the TEP prediction.
- The source run uses a Beverton–Holt stock–recruitment relationship and summarizes Fbar over ages 5–10+.

Input status is complete for the annual data passed to the applied run and the source catch-bound reconstruction. Assumption status remains partial because the 2025 detailed research report and some run-level statistical details are not available as a separate publication.

## Fitted outputs

The repository exports fitted numbers-at-age and F-at-age for all 57 years and 10 age groups. Numbers-at-age are in thousands of fish; F is per year and rounded to 0.01 in the export. The annual tables also provide SSB, recruitment, total biomass, Fbar and predicted total catch. Recruitment is age-1 abundance in the same calendar year, in thousands of fish. SSB and biomass are in tonnes.

The source's annual N, SSB, recruitment, total biomass and catch intervals are back-transformed estimate (pm 2) asymptotic standard deviations on the log scale. They are recorded as source intervals, not exact 95% confidence intervals. Fbar is a point estimate only. The public F-at-age table is rounded to 0.01; exact F is reconstructed from the cached fit's annual `logFy` and selectivity mapping and reproduces that table after rounding. Conditional `logFy` state SDs are recorded as natural-scale delta-method SEs, with approximate `exp(log F +/- 2 SD(logFy))` bounds. These bounds condition on fitted fixed parameters: they omit fixed selectivity uncertainty and its covariance with `logFy`, so they are not full marginal F intervals. Total abundance is additionally calculated as the sum of official N-at-age for ages 1–10+; it has no uncertainty because the required joint covariance is unavailable.

The cached fit object reports CCAM `RemoteSha` `1d1cc18416b2`, whereas the locally cached CCAM source snapshot is pinned at `1bcb06473343c13ebeebecdb54acd905220aeb61`; the fit SHA is not present in the cached source history. The pinned source's F mapping reproduces the stored public F table after rounding, but the exact historical CCAM source used to build the fit object is not available locally. The conditional uncertainty added here comes directly from the covariance saved in the official fit object and is explicitly distinguished from full marginal uncertainty.

M is fixed input, not an estimated output, so no M-at-age estimate is recorded. Outputs status remains partial: the saved fit supports conditional log-F state uncertainty, but not full marginal uncertainty for the age-specific F surface.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/dfo_northern_mackerel_2025.md). They do not determine source completeness or official run selection.
