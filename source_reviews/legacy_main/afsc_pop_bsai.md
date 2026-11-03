# Bering Sea/Aleutian Islands Pacific ocean perch

## Official run and sources

`afsc_pop_bsai_2024` represents the 2024 Model 24, not a profile or sensitivity.
The stock is `AFSC_alutus_BSAI` in the broader Charbonneau–Keith `Master.csv`.
The December 2025 catch reports and NOAA's February 2026 harvest-specification
review confirm that the 2024 fitted assessment remains the production basis.
The newer catch reports do not supply replacement historical fitted states.

The [2024 SAFE chapter](https://files.npfmc.org/SAFE/2024/BSAIpop.pdf) is checked
against the pinned [native model repository](https://github.com/afsc-assessments/BSAI-POP).
Local PDFs, native data/control/code, the `.rdat`, `.std`, `.rep` and composition
exports are cached under `source_cache/afsc_pop_bsai/`, with retrieval dates,
URLs, checksums and the repository revision in its manifest. Run
`057_import_bsai_pop_2024.R` to reproduce the numerical import from that cache.

Native 2024 total biomass is 864,800 t, female SSB is 359,278 t (359,280 printed),
and M is 0.0505762 (0.051 printed). Earlier checks include 1977 SSB 84,759.6 t
(84,760 printed) and 2021 age-3 recruitment 34.1771 million (34,177 thousand
printed). Table 12.25's historical 2024 column is distinct from its 2022-model
column and from the 2025 projections. The table was inspected visually because
its numerical body is an embedded image.

## Inputs and active assumptions

The combined-sex, one-region population runs from 1960 through 2024, with
recruitment at age 3 and a 46+ model boundary. It fits one combined fishery and
the Aleutian Islands and EBS slope trawl surveys. Observation compositions and
exported N use ages 3–39 and 40+; that is not the model plus age.

The database retains annual fishery biomass; both surveys' supplied biomass,
number totals and biomass SDs; fishery and survey age compositions; fishery
and AI survey length frequencies; raw sample counts; separate population and
catch weights; maturity sampling counts; the ageing-error and length-at-age
matrices; and composition multipliers. EBS has no length observations even
though its length-likelihood flag is enabled. Some original length-frequency
rows are counts and others sum to one. Their row totals are preserved; the
source normalizes each row. These are samples, not catch-at-length counts.

The active survey likelihoods fit biomass, not the supplied number totals.
Both use constant q with logistic age selectivity. Only AI has an active q prior
(mean 1, CV 0.15). Survey predictions use annual average survival
`(1 - exp(-Z)) / Z`, not abundance on an exact sampling day. Canonical survey
timing is therefore blank. Stock and fishery weights are constant vectors in
grams, including modeled ages above the observation 40+ group.

Recruitment has two historical mean periods split at 1990, lognormal deviations
with SD 0.75, and a bias-corrected mean rule in the final three years. Older
cohorts have deterministic survival. Initial abundance is equilibrium with
historical F fixed at zero. F combines annual intensity with a penalized
bicubic age/year selectivity surface. M is estimated as one constant under a
tight lognormal prior (mean 0.05, CV 0.05), rather than supplied as fixed M.
Maturity is estimated from female biological samples using a logistic age curve;
the commented-out maturity vector is inactive and is not imported as a fixed
input. Native SSB is female biomass at April 1: half the combined N, with
survival through one quarter of the year.

## Outputs and remaining limits

The database retains historical N at ages 3–39/40+, F reconstructed from the
reported intensity and normalized selectivity, estimated M, native SSB and
biomass, age-3 recruitment, and estimated maturity coefficients. The tail of
selectivity is held constant above age 40 in the native code. Natural-scale
ADMB SSB SEs are retained without inventing intervals; coefficient SEs remain
on the coefficient scale. No covariance-based intervals are constructed for N
or derived F.

Composition cells retain the exact supplied square-root sample counts multiplied
by `compweights.ctl`. Raw measured/aged fish counts are separate
`composition_sample_count` rows. The `.rdat` column called `sampsize` contains
the transformed/reweighted count (132.03 for the 1981 fishery), not the original
510 otoliths. The importer checks the control-file values rather than inferring
their meaning from that column name. Fitted effective sample sizes are distinct
and are not substituted for either input.

Completeness remains partial: full ungrouped N at ages 40–46+, age-state
uncertainty, and some initialization/control semantics are not exported. The
source review distinguishes these gaps from confirmed inactive likelihoods.

## tinyAM translation

The recipe uses 1960–2024 and ages 3–40+, the observed/exported terminal age
group. It reconstructs age-specific catch and survey indices from the original
biomass, compositions and weights. Source length samples, ageing error,
composition likelihoods, spline penalties and priors are omitted. Survey time
0.5 approximates the source's annual-average survival. Recruitment has separate
mean periods before/after 1990, with estimated IID variation; survival is
deterministic, initial abundance is free, F has independent temporal random
walks, and M is an estimated constant without the source prior. Maturity is
held at the official fitted logistic curve, with a female fraction of 0.5
and spawning time 0.25. These choices are explicit in the dashboard background.

Preparation and the default-first/retry, plus-group, reference-alignment and
comparison-definition regression tests pass. The full default-initialization
pipeline was launched at the translation checkpoint but had not returned a fit
after more than seven hours of CPU time. It was terminated as an execution
failure. Objective, gradients, uncertainty and convergence are unknown; no
agreement statistics or dashboard are claimed. The helper then in use retained
attempts only when the complete pipeline returned, so its active initialization
stage and any earlier completed-attempt diagnostics could not be recovered.
No additional retry was launched because that could exceed the single-retry
policy. The helper now saves each attempt before and after execution so later
interruptions cannot lose this history. No data or model assumptions were
changed to rescue this case.
