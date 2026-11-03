# Eastern Bering Sea northern rock sole

## Official model and sources

`afsc_northern_rock_sole_ebs_2024` is the final 2024 SSC-selected Model 24.2.
It estimates female M as well as male M; Model 18.3 and Model 24.1 are not
substituted. Charbonneau–Keith identifies the stock as
`AFSC_EEBSAI_Lepidopsetta_polyxystra`. It is one BSAI management stock,
with an Eastern Bering Sea assessment area and two sexes, not two cases.
The 2025 funding lapse did not produce a replacement fitted assessment.

The [2024 SAFE report](https://files.npfmc.org/SAFE/2024/BSAIrocksole.pdf)
and [native Model 24.2 inputs](https://github.com/noaa-afsc/BSAI_NRS/tree/71cf64a8f5c3b22ed99378a9bd2a754c5e0d3bdf/2024/model_runs/model_24.2)
are cached locally with retrieval dates, checksums and a pinned revision.
The public run directory supplies inputs, not fitted output files. Current
outputs are therefore extracted from the final report's Model 24.2 columns.
The [flatfish framework code](https://github.com/noaa-afsc/flatfish_assessment_code/blob/9709548fafc7d69a2e3f88f80f60c74b7d3cfb0e/src/fm.tpl)
is separately pinned and used to verify equations, not to replace current data.

## Inputs and active processes

The model covers 1975–2024, ages 1–20+, female/male, one fishery and one EBS
bottom-trawl survey. Catch and survey biomass are in **thousand tonnes**;
weights are **kg/fish**, unlike yellowfin sole's grams. Joint-sex number
compositions and their supplied sample sizes are preserved. The source
normalizes supplied joint rows across both sexes, not within each sex.
There are 42 fishery age-sample years; 1995–1997 are absent, not zero. Survey
age samples and survey biomass cover different year sets; no unobserved age
composition is manufactured for the terminal 2024 biomass observation.

Empirical population, catch and survey weights are distinct original inputs
under Growth_Option 1. Source zeros and repeated terminal weights are retained.
Female maturity is supplied; SSB uses survival to **February 1 (1/12)**.
The fishery log-catch residual sum of squares has weight 300. Survey biomass
uses supplied natural-scale SE transformed to a log SD. The biomass prediction
is at time 0.5, whereas age-composition predictions use begin-year N. Francis
composition weighting and the source multinomial offsets are not equivalent
to independent age-specific lognormal observations.

Female M is estimated at 0.192 (SE 0.003), male M at 0.226 (SE 0.004), rounded
in Table 8.14. The report describes lognormal M priors with center 0.15 and
log width 0.2. The pinned framework explicitly adds this penalty for female M;
the corresponding male penalty could not be corroborated. Male-prior activation
in the production executable remains unresolved, rather than confirmed absent.
Scalar survey q is estimated at 1.633 (SE 0.050), with prior mean 1.5 and log
width 0.2. Its sex-specific logistic selectivity remains separate. Temperature
arrays exist in the data file, but q and growth temperature effects are
inactive under negative phases. They are not attributed to the production fit.

Survival is deterministic, recruitment is equally split between sexes, initial
age parameters are active, and a fitted Ricker relationship with lag one is
penalized over 1978–2018 with fixed log SD 0.6. Annual F multiplies sex-specific
logistic curves with log deviations in slope and age at 50% selectivity;
ages 17+ share fishery selectivity and the male multiplier is estimated.

## Output recovery and validation

Native N is printed in whole **million fish**. Tables 8.20–8.24 give female
SSB, all-age biomass, combined-sex age-1 recruitment and both sexes' N. SSB,
biomass and recruitment retain natural-scale asymptotic SEs. Neither state
SEs nor combined confidence intervals are invented.

F-at-age is derived from rounded annual F deviations, slope/a50 deviations
and Table 8.14 parameters using the pinned source equations. It is not
inferred from rounded N. Some minus signs in the PDF wrap above their numbers;
the extractor reads each target cell geometrically and checks a visually
verified negative cell. The resulting non-plus-group cohort survival differs
from reported next-year N by at most 1.70 million females and 1.52 million
males, consistent with whole-million N rounding and rounded M/curve parameters.
No F uncertainty is reconstructed without joint covariance.

The 2024 reference checks are SSB 271988 t, biomass 1051040 t and combined
age-1 recruitment 1462.25 million. Canonical units remain those originally
reported. Completeness stays partial: full ageing-error/control detail,
auxiliary input arrays and state covariance are not yet exported.

## tinyAM translation and numerical result

The recipe represents female ages 5–20+ over 1982–2023. It converts original
biomass and joint compositions using both sexes' empirical weights before
retaining female observations and restricting ages. Female biology and
February 1 spawning are retained. Female M is estimated as one constant;
the official estimate is not converted to a fixed input. Native male states
remain canonical but are outside this fitted female population.

The independent F random walks, constant-mean age-5 recruitment, logistic
survey q and independent age observations approximate the source curves,
stock–recruit relationship and joint composition likelihood. Source M/q
priors are omitted, and the different source composition/biomass timings
remain an approximation. The original observations are not tuned to the fit.

Neither permitted initialization attempt passed numerical checks. Default
starts returned code 1 (singular convergence), objective 3866.355, maximum
gradient 1.203 and a non-positive-definite Hessian after 193 seconds. One
aligned female N/F retry returned code 0, objective 3963.453 and gradient
0.0788 after 148 seconds, but still failed the gradient tolerance and Hessian
checks. Fixed-parameter SEs were non-finite; an SD-report object alone does
not mean uncertainty estimation succeeded. No further retry or model change
was made.

The returned retry drives M close to zero, the scalar q baseline extremely
high and initial young-age N upward, while some old initial states approach
zero. These are failed-fit estimates, not evidence of stock status or model
agreement. The source priors and joint observation structure differ, but the
two attempts do not isolate the cause. An exploratory dashboard and numerical
comparisons are retained with the failure diagnostics; female-only comparisons
and rounded-derived F/SSB are labelled explicitly.

An exponential initial-abundance sensitivity was also fit with package-default
starts and the same remaining settings. It did not resolve the instability:
optimizer code 1, gradient 0.217, non-positive-definite Hessian, and
non-finite fixed-effect covariance. N-at-age and SSB median percent differences
rose to about 100% and 864%, respectively, and abundance and recruitment
differences became orders of magnitude larger. The free initial-age treatment
is therefore retained as the closer source representation, although neither
initialization has produced a numerically reliable fit.
