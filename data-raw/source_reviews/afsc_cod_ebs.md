# Eastern Bering Sea Pacific cod

## Production source

Charbonneau–Keith identity `AFSC_BSAI_Gadus_macrocephalus`. The December 2024
SSC selected Model 24.1. The 2024 SAFE report, Appendix 2.3 native files and
Appendix 2.4 workbook describe that run, rather than a newer development model.
The NOAA review of 2026 harvest specifications explains the retention of the
2024 detailed fits following the 2025 funding lapse. Source files are cached
under `source_cache/afsc_cod_ebs/`, with retrieval dates, checksums and the pinned
EBS_PCOD repository revision in the manifest.

The source models 1977–2024 and ages 0–20+, one combined-sex population, one
fishery and one VAST survey. Catch is tonnes; the survey is **thousands of fish**
at July 1, not a biomass index. Native CPUEinfo sets Units=0. The survey scalar
q is estimated, as is additional survey SD; the inactive/active parameter
phases and Q_setup float=0 matter here.

## Observations and biology

Preserve annual catch biomass, fishery and survey length proportions, marginal
age proportions and conditional age-at-length samples separately. The source
uses **23 active survey marginal-age rows, 2000–2023 excluding 2020**. Negative
fleet codes disable the other age rows, including all fishery conditional-age
samples. The workbook's longer age-composition series must not silently add
these observations to the fitted likelihood. Conditional ages are biological
samples, not independent abundance indices. Supplied sample sizes, age-error
codes, partition and conditioning lengths are retained.

M is fixed at 0.3866, not 0.386. Richards growth and annual L1/K deviations
produce the model's weights: **WTATAGE is fitted output, not an original input**.
The fixed weight–length equation is kg = 5.40706e-6 × cm^3.19601; maturity is
logistic in length with L50=58 cm and slope 0.132, first mature age 1. Spawning
is January 1. Steepness is fixed to one, with recruitment log SD 0.6908, an
early regime block and bias adjustments. F/selectivity and growth vary over time in the official model.

## Reference definitions and checks

The workbook gives beginning- and midyear N in thousands of fish and computed
population weights in kg. For the single continuous-mortality season,
F = −2 log(N_mid/N_begin) − 0.3866. Recover positive F-at-age values using this
identity; omit nine unresolved nonpositive young-age cells caused by source
rounding rather than clipping them. All ages 1–20 in 2000–2023 are resolved.
These derived F values have no reconstructed SE. The worksheet's `F_year`
summary is not assumed to be a population-weighted Fbar.

The single-sex worksheet SSB is **combined mature biomass**: its 2024 point
is 446,577 t. Table 2.26 explicitly reports female spawning biomass, 223,289 t
with SD 35,481 t. Both are retained under different measures. The worksheet's
native SD is 50,177.3; no assumed transformation replaces the published female
SD or manufactures intervals. Tests check the factor of two in point estimates
across all overlapping historical years. Age-0 recruitment in 2024 is 621,430
thousand fish, with worksheet natural-scale SD 27,663.3.

## Source details retained from the modelling review

Original maturity-at-age and empirical stock weights were not supplied to SS.
Do not label a weight-derived maturity proxy as the official maturity curve.
Canonical completeness remains partial; the missing original biology remains an explicit source gap.
