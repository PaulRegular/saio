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
codes, partition and conditioning lengths are retained; control weighting and
ageing error are not converted into tinyAM precision weights.

M is fixed at 0.3866, not 0.386. Richards growth and annual L1/K deviations
produce the model's weights: **WTATAGE is fitted output, not an original input**.
The fixed weight–length equation is kg = 5.40706e-6 × cm^3.19601; maturity is
logistic in length with L50=58 cm and slope 0.132, first mature age 1. Spawning
is January 1. Steepness is fixed to one, with recruitment log SD 0.6908, an
early regime block and bias adjustments. F/selectivity and growth have time
variation that a simple age-structured translation does not reproduce.

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

## Translation

The original likelihood uses catch-at-length. A tinyAM approximation needs an
explicit allocation from length to age. The native inactive fishery age samples
provide a potential pooled empirical key, without using fitted N to adjust an
observation. Its covered length bins contain 99.46–99.99% of annual fishery
number proportions in 2000–2024. Uncovered lengths must remain unallocated,
not be assigned invented ages or silently redistributed. Any such translation
must disclose pooling across years, omitted mass, age-error differences,
weight–length bin approximation and plug-in fitted population biology.

Original maturity-at-age and empirical stock weights were not supplied to SS.
Do not label a weight-derived maturity proxy as the official maturity curve.
Canonical completeness remains partial; source preservation and numerical
model readiness are separate claims.

The retained recipe fits 2000–2023, ages 1–12+, using the pooled fishery key,
original VAST numbers and active survey ages. Catch total numbers use the
fixed weight–length equation at five-cm bin midpoints. Population weights are
plug-in official outputs; the maturity proxy applies the original length
ogive to weight-equivalent length. Pool ages 12–20+ with official N weights
for biological reporting. This is not the source's length-integrated maturity.
SSB comparisons therefore use a labelled common proxy; native female SSB and
its reported SD remain separate. Neither fitted q nor fitted N changes an
observation. Zero source proportions remain zero; tinyAM's lognormal
observations treat these zero entries as missing.

### Proposed paired-model candidate (not yet fitted)

The updated translation continues to use deterministic older-age survival (`N process = "off"`),
free first-year older-age abundance (`init = "free"`), and IID log recruitment around
an estimated constant mean. **The recruitment log SD is now estimated** (the
`sd` setting was removed), whereas the accepted assessment fixes it at 0.6908.
This deliberately adds flexibility and is not an exact match to the source
recruitment penalty. Natural mortality remains fixed at 0.3866; January spawning
timing and the existing proxy biology are unchanged.

Relative to the earlier paired candidate, the new change is the estimated
recruitment SD. The other two non-operational process approximations remain:
F-at-age follows **correlated temporal random walks** (`F_settings = list(process = "cor_rw", mu_form = NULL)`), in which
annual log-F innovations are correlated among ages. This is a simple proxy for
collective changes in fishing intensity and selectivity, not an exact representation
of length-based fishing or the official selectivity penalties. Second, the survey
index uses **rising logistic age-specific catchability with an annual common log-q
random walk** (`q_form = ~ logistic(age) + rw(year)`). The logistic component
approximates the ascending survey selectivity curve. The RW permits the whole survey
q level to change among years; it does **not** reproduce the official annual changes
in length-selectivity width or the official scalar-q specification.

The translation now ends in a single `if (do_fit)` block calling `tinyAM::fit_tam()`.
The previous `fit_default_first()` helper, fitted-official-N/F retry starts and
initialization-attempt cache have been removed. Original catch/survey reconstruction,
source data, biological proxy and comparison definitions are retained.
The estimated recruitment SD should be reported from the new fit rather than
assumed to equal 0.6908. Its value and the new fit diagnostics have not been
provided, so no numerical conclusions are attributed to this candidate.

### Historical baseline results (not results for this candidate)

The **superseded** independent age-specific F random walk / unrestricted age-q
configuration converged with optimizer code 0, objective 372.2591, maximum gradient
0.0013577, positive-definite Hessian and finite covariance (approximately 6.45 s).
Its source comparisons reported 42.1% mean absolute N-at-age difference, -43.7%
terminal N difference, within-age N correlation 0.681; 70.1% mean absolute F-at-age
difference, +107.0% terminal F difference, within-age F correlation -0.200; and
21.7% mean absolute proxy-SSB difference. None of these figures should be quoted
as performance of the newly specified `cor_rw` F / logistic-plus-year-RW q candidate.

Substantial limitations remain: fishery catch numbers are reconstructed with a
pooled empirical age–length key; the source fits catch-at-length and age/length
compositions; the source selectivity varies in length space; age error and survey
precision are simplified; and age-0 recruitment/SSB definitions are not fully
matched. Official fixed M is not an independent validation of M estimation.
