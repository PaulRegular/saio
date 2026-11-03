# Bering Sea/Aleutian Islands Alaska plaice

## Official run and sources

`afsc_alaska_plaice_bsai_2024` is the final SSC-selected 2024 Model 24.1b,
Stock Synthesis 3.30.22. The Charbonneau–Keith starting identifier is
`AFSC_BSAI_Pleuronectes_quadrituberculatus`. It is one BSAI management stock;
the assessment covers the Eastern Bering Sea and preserves female and male fish.
The 2025 funding lapse did not produce a replacement fitted assessment.

The [2024 SAFE report](https://files.npfmc.org/SAFE/2024/BSAIplaice.pdf) and
[production files](https://github.com/afsc-assessments/BSAI_Alaska_plaice/tree/96b65a032cda06013376a8c8a11b553ebf194784/2024/Models/Model_24.1b)
are cached locally with retrieval dates, checksums and a pinned revision.
`data_echo.ss_new`, `control.ss_new` and `Report.sso` identify the actual
consumed inputs, parameter phases and fitted outputs. Adjacent model variants
and projection years are excluded.

## Inputs and likelihood

Historical years are 1975–2024, ages 0–25+. Total dead catch and the EBS survey
biomass are tonnes. Survey observations use month 7 (fraction 0.5) and supplied
lognormal SDs. Fishery age compositions exist only in 2000, 2002 and 2003;
survey ages cover a longer, intermittent period. Joint female/male number
proportions sum to one across both sexes, not separately within each sex.
The database preserves native age and length compositions, sample sizes,
age-error and partition codes. Length sample-size multipliers are 1 and
0.14693; age multipliers are 1 and 0.2749 for fishery and survey respectively.
All these composition likelihoods are active. Composition sizes are not
abundance observations.

M is fixed at 0.13 for both sexes. Survey log q is fixed at 0.182322
(approximately 1.2), not estimated. Sex-specific, time-invariant ascending
selectivity curves are fitted. Annual fishing intensity has no random-walk
likelihood. Recruitment has fixed Beverton–Holt steepness 1, giving a constant
mean, and fixed log SD 0.4243. Main recruitment deviations end in 2019;
subsequent recruitment uses source forecast and bias-adjustment rules.

Six growth parameters are estimated. Weight-length coefficients, length CVs,
the female empirical maturity vector and recruitment sex ratio 0.5 are fixed.
`wtatage.ss_new` is an exported calculation: the run does not read a supplied
weight-at-age file. Beginning- and mid-year weights are therefore stored as
computed biological outputs, dated 2024 and described as time-invariant in
this run. They must not be presented as original input vectors.

## Outputs and checks

N is in **million fish**, computed weights in **grams/fish**, and biomass in
tonnes. Summing sex-specific beginning-year N times beginning-year weight
reproduces `Bio_all` at printed precision. Female January 1 N times weight
and maturity reproduces spawning biomass. The 2024 checks are `Bio_all =
394455 t` and `SpawnBio = 147511 t`. The separately reported `Bio_smry` is
age 3+ biomass and is retained under its own definition.

Annual N and F retain sex and the 25+ group. SSB and age-0 recruitment retain
their natural-scale marginal ADMB standard errors; no state uncertainty or
combined-sex confidence intervals are invented. Completeness remains partial
because the full covariance and some model-control details are not exported
to the canonical tables.

## tinyAM translation and numerical result

The translation uses 2000–2023 and ages 5–25+. Biomass and joint-sex age
proportions are converted to numbers using sex-specific computed mid-year
weights before pooling sexes or restricting ages. Only three fishery age
samples are available; length samples are omitted. Stock biology uses an
equal-sex approximation, holding source growth estimates fixed. M remains
0.13. Survey observations are divided by the source's **fixed** calibration
exp(0.182322), with a logistic q curve constrained to asymptote 1; no fitted
q or fitted population state is used to adjust observations. Source
sex-specific selectivity, ageing error, length likelihood and composition
weights are not reproduced. Initial ages are free, F follows independent
random walks, and age-5 recruitment has an estimated constant mean and SD.

Default initialization failed (code 1, false convergence; maximum gradient
about 203000; non-positive-definite Hessian). The one permitted retry from
aligned pooled N and N-weighted F converged: code 0, objective 296.489,
maximum gradient 0.000904, positive-definite Hessian and successful SD report.
Both attempts are saved; data and model settings were unchanged.

The local dashboard compares native outputs and explicitly labelled common
definitions. Modeled-age female SSB is approximate because tinyAM pools sexes:
MAPD 3.73%, terminal difference −13.38%, correlation 0.981. This does not mean
the other states agree. N-at-age is 29.71%, +10.23%, 0.816; total abundance
45.22%, +77.25%, 0.277; age-5 recruitment 110.75%, +18.18%, 0.698; and
N-weighted F-at-age 587.46%, +1201.45%, −0.177. Very small juvenile F makes
relative differences especially large. These metrics require review. Fixed
M is checked only for input consistency. Native age-0 recruitment and all-age
SSB are retained separately; no combined uncertainty is invented.
