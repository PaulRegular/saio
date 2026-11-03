# Gulf of Alaska pollock: official-assessment source review

Status: canonical record afsc_pollock_goa_2024 imported; inputs, outputs and assumptions remain partial.
Charbonneau identifier: AFSC_GOA_Gadus_chalcogrammus.

## Official assessment

The November 2024 detailed SAFE chapter is cached as source_cache/afsc_pollock_goa_2024/2024_GOA_pollock_SAFE.pdf (118 pages).
Source: https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=GOA+Pollock+2024.pdf&p=bd9a9aa2-3a33-4841-9133-d9ccf593e051.pdf

Final December 2024 SSC report, page 40, explicitly accepts Model 23d for the Western/Central/West Yakutat stock. It endorses revised survey CVs/sample sizes, a Shelikof catchability covariate, removal of Shelikof age-1/age-2 indices, and Dirichlet-multinomial composition likelihoods. The separate Southeast Outside Tier 5 assessment must not be combined with this age-structured stock.
SSC source: https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=2587e1ac-2a37-4a80-b68b-7a8c7e7a02ca.pdf

The 2025 catch-only notice is cached separately; its rollover was verified against the official 2024 run as described below.
Source: https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=1.+Pollock.pdf&p=b8e2f063-e4d4-4749-a5c3-ac04a7bbc612.pdf

## Native files

Official repository: https://github.com/afsc-assessments/GOApollock
Inspected commit: aefe1692520510d55fd25db60121b292a53840a3.
Cached metadata, recursive tree, README, data/2024/pk24_12.txt, data/2024/goa_pk.cpp, data/2024/run_assessment.R, R/tmb_fns.R, R/utils.R and data/READMD.md.

The README explains that annual releases reproduce assessments, while some SAFE inputs/outputs are not publicly shared. No fitted 2024 object appears in the inspected tree. Earlier ADMB/WHAM runs are context, not replacements for Model 23d.

The 2024 script explicitly labels the fit '23d: 2024 final' and requests D-M composition likelihoods. Its first comment incorrectly says 2023; the actual path, data filename, version label and terminal year identify 2024. It fixes log_q4/log_q5 and doubles multN_srv1, multN_srv3 and multN_srv6 after reading. Those post-read transformations must be retained in model-ready composition weights.

The inspected official read_dat function was evaluated independently, without fitting or executing the assessment workflow. It validated the final -999 sentinel, start 1970, terminal 2024, recruitment age 1 and terminal modeled age 10. Parsed values are cached as native_inputs_raw.rds and a lossless key/row/column/value CSV. These are raw parsed inputs, not yet fully transformed inputs consumed by the model.

## Inventory and pending checks

Native total catch: 55 years, tonnes, 1970–2024; terminal catch is assumed 131,000 t. Native fishery age compositions: 49 years, 1975–2023, 10 fitted columns, with lower/upper accumulation ages. Final SAFE Table 1.6 also publishes catch numbers at ages 1–15 for those years; those detailed values are now stored separately in the canonical inputs with their report provenance. Annual fishery weights: 55 by 10. Fishery length-composition placeholders have zero sample sizes and must not be mistaken for fitted observations.

Survey blocks 1, 2, 3 and 6 contain respectively 31, 16, 37 and 6 total-index observations, and 31, 16, 20 and 6 age-composition rows. Survey identities, units, fitted accumulation ages, positive-weight length compositions and annual timing must be matched to the report/source before import. Blocks 4 and 5 remain in the file, but their log-SD values must be inspected: implementation only contributes their likelihood when log SD is positive. Merely finding these arrays does not establish that they are fitted.

The source uses annual survey timing fractions directly in N * exp(-timing * Z), with survey-specific weight matrices. Preserve the timing for each observation year. The environmental catchability component has 40 observed years plus a latent AR1 surface; it is a material input, not optional descriptive context.

Natural mortality is coded as the age vector 1.39, 0.69, 0.48, 0.37, 0.34, 0.30, 0.30, 0.29, 0.28, 0.29, multiplied by natMscalar. The default parameter map fixes natMscalar at 1. The final report confirms externally supplied age-specific M rescaled to an older-age average of 0.3; the scalar is not a substitute for the vector.

The default reader/preparation code fixes sigmaR at 1.3. Final report page 16 confirms this value; the September proposal of 1.0 was not retained. The official 2024 repository revision is pinned above.

The 2025 rollover notice, fitted-stream and biology inventory, native/report cross-checks, historical outputs and uncertainty have since been reviewed below. Remaining source gaps are listed at the end.

## Finalized report and staging checks

The finalized 120-page chapter is now cached as 2024_GOA_pollock_SAFE_final.pdf, from https://files.npfmc.org/SAFE/2024/GOApollock.pdf. Prefer it to the earlier 118-page Plan Team draft for extraction.

The 2025 catch notice explicitly confirms no new assessment in 2025. Its GOA-wide totals include Southeast Outside: 2025 ABC 181,022 + 9,749 = 190,771 t; 2026 ABC 133,075 + 9,749 = 142,824 t; 2025 OFL 210,111 + 12,998 = 223,109 t; 2026 OFL 153,971 + 12,998 = 166,969 t. Thus the notice supports production use of the 2024 result; its combined totals must not be stored as outputs of the W/C/WYK age-structured model.

Final report page 16 confirms recruitment sigmaR=1.3, agreeing with the native default fixed parameter. September's proposed 1.0 was not the final convention. Pages 19–20 explain fixed external age-specific M, rescaled to average 0.3 for older fish, and a constant maturity vector based on 1983–2024 female observations. The native maturity vector matches the printed all-years row to rounding. The annual maturity estimates in Table 1.16 are supporting observations, not the maturity surface consumed by this model.

Native arrays confirm all Shelikof age-1/age-2 index log SDs are zero, so their likelihood contributions are disabled. All fishery and survey length-composition sample sizes are zero. Do not import these disabled streams as fitted input coverage.

Active indices are Shelikof winter acoustic (block 1, 31 observations, 1992–2024), NMFS bottom trawl (block 2, 16, 1990–2023), ADF&G crab/groundfish (block 3, 37, 1988–2024), and summer acoustic (block 6, 6, 2013–2023). Source timing fractions are 0.209, annual 0.543–0.584, 0.60989 and 0.519 respectively. Some report prose/tabulated likelihood summaries have stale end years; native arrays control the actual fitted input dates.

Cached stage_report_outputs.py extracted 550 historical numbers-at-age values from Table 1.22 and 110 recruitment/SSB estimates with published 95% intervals and CVs from Table 1.24. Checks require 55 years, 10 ages, valid interval ordering, and exact agreement between printed age-1 N and recruitment. They passed. Units are million fish and thousand tonnes. No SE has been inferred from the rounded CVs. These source-staged outputs have been imported into the canonical records.

## Canonical import and validation

The canonical record contains 5,909 input values, 1,134 output values and 49 assumptions. The outputs include 550 official N-at-age values, 55 total-abundance values derived by summing those age groups, 371 partial F-at-age values derived conservatively from the rounded N-at-age surface, 55 SSB values, 55 recruitment values and 48 reported age-3+ biomass values. The checks in scripts/database/017_validate_goa_pollock.R and full database structural validation pass. Coverage includes one combined fishery, four active biomass/composition surveys, annual survey/fishery/population/spawning weights, and constant supplied maturity and M vectors. Model years are 1970–2024, ages 1–10+, recruitment age 1, combined-sex abundance with female SSB fraction 0.5. Spawning survival timing is 0.21, distinct from the winter acoustic observation timing 0.209.

The official fishery likelihood accumulates ages 1–2 into its first fitted bin and ages 10+ into the terminal bin. The canonical database retains these native grouped proportions and separately stores the report's finer catch numbers at ages 1–15. tinyAM now uses the finer published catch table, summing reported ages 10–15 into its model age-10 plus group. Shelikof compositions accumulate ages 1–3; these model-ready aggregations are labeled reconstructed_source_input with explicit formulas. Remaining compositions preserve native numerical values, without silent renormalization. Survey total biomass units are million tonnes on the native scale. SD rows match the same observation years and sampling times, with blank fish age for aggregate indices. Supplied spawning weights use measure spawning_weight_at_age, distinct from population weight_at_age and survey-specific weights; biological purposes are not treated as spatial regions.

The fitted object and direct F-at-age table are not available in the cached report or model files. A partial F-at-age surface is now derived for ages 1-8 in 1970-2023 from the official rounded N-at-age table and the source cohort equation `N[y+1,a+1] = N[y,a] * exp(-Z[y,a])`, with `Z = F-at-age + M[a]`. Because N is rounded to the nearest million fish, a row is retained only when F remains positive across the possible +/-0.5-million rounding range. Near-zero or rounding-ambiguous cells are omitted; the age-10+ plus group is excluded because its transition mixes ages. These 371 values are labeled `derived_source_output`, have no SE or interval, and are not direct official F estimates. Physical environmental-covariate units remain unresolved. Active selectivity priors and the Dirichlet-multinomial parameter prior are recorded from the pinned source, alongside temporal penalty scales, environmental observations, observation SD, age-error matrix and composition sample sizes. Completeness statuses remain partial.

## Native process and initial-state review

The official 2024 script uses `prepare_pk_input()` and its default parameter map. Extra initial-age deviations are fixed at zero. Initial ages 2–10 are constructed from first-year recruitment and M, with the exact zero-based mortality indexing recorded in the assumptions table; subsequent survival is deterministic conditional on F and M. Fishery selectivity is double-logistic, normalized at age 7, with penalized annual ascending-limb changes and fixed descending-limb deviations.

Catchability differs by survey: Shelikof uses a baseline plus an integrated latent environmental effect, bottom trawl uses constant estimated q with a log-scale prior, ADF&G uses penalized annual log-q changes, and summer acoustic uses constant estimated q. Thus the implementation does not support treating all survey catchabilities as interchangeable random walks. Evidence is the cached, pinned `R/tmb_fns.R`, `data/2024/run_assessment.R`, and `data/2024/goa_pk.cpp`; the environmental observations and age-error matrix are now represented as described below.

The 40 native environmental observations and their exact observation years are now canonical covariate inputs. Values are preserved without restandardization; physical units remain unresolved. The official map fixes their observation SD at 0.02 on the native scale. The fitted latent annual environmental process is distinct from these supplied observations. Validation compares all 40 values and years directly with the cached native export.

The supplied composition sample sizes are now explicit numeric fields, including the official script’s doubling for surveys 1, 3 and 6. They remain distinct from D-M effective sample sizes. The constant 10-by-10 `age_trans` matrix is preserved row by row in the biological assumptions record. Its orientation is verified from prediction code: true-age row compositions multiply the matrix to obtain observed-age compositions before bin accumulation. All four active surveys and the fishery use this matrix.

Native age-transition row sums differ from one by up to 0.0001 because of supplied numerical precision. Values are retained exactly, without renormalization; validation allows this source precision.

Survey selectivity shapes and fixed/estimated limbs are now recorded separately for all four active surveys. All 54 fishery ascending log-slope increment SDs equal 0.05; ascending inflection SDs are 0.2. The 54 ADF&G log-q increment SDs are preserved in transition order and checked directly against native inputs. Supplied q1/q2 penalty arrays are not treated as active annual processes because their corresponding deviations are fixed at zero.

Final Table 1.23 adds 48 official-run beginning-year age-3+ biomass estimates for 1977–2024, in thousand tonnes. The previous-assessment columns are excluded. SSB and recruitment in the same rows agree exactly with independently extracted Table 1.24. Harvest rate is catch divided by age-3+ biomass, not instantaneous F; it is not used to manufacture F-at-age.

## Current tinyAM translation

The current candidate fits 1970–2024 at ages 1–10+, matching the official
stock extent and retaining the fixed age-specific M vector. It uses
deterministic survival of older cohorts (`N_settings$process = "off"`) with
exponential initial abundance. Recruitment is IID around an estimated constant
log mean, with its SD fixed at 1.3. This matches the official annual
recruitment-deviation variance and lack of temporal correlation more closely
than the previous tinyAM recruitment RW. The first recruitment state in
tinyAM remains an unpenalized fixed anchor, and exact official initial-age
construction is not reproduced.

Fishing mortality now uses `F_settings$process = "ar1"` with a rising logistic
mean-at-age (`mu_form = ~ logistic(age)`) and reporting ages 3–10. This
regularizes an age/year log-F surface around a static smooth mean rather than
using independent random walks at each age. It is an approximation to the
official model's annual F intensity multiplied by double-logistic selectivity,
whose ascending-limb parameters evolve under penalties; tinyAM does not
reproduce that parameter evolution or a descending fishery-selectivity limb.

The four survey age patterns are represented parsimoniously by *two* shared
logistic effects and four survey-specific intercepts. A reversed age coordinate
(`sel_age = 11 - age`) gives descending age responses for the Shelikof winter
and summer acoustic surveys; unmodified age gives rising responses for the
NMFS bottom trawl and ADF&G crab/groundfish trawl surveys. The formula
`~ 0 + survey + logistic(sel_age, by = survey_type)` therefore fits one
logistic shape for the acoustic surveys and another for the trawl surveys,
not a separate age curve for every survey. Both enter the **logit-q**
linear predictor; they are not literal multiplicative selectivity curves on
the original q scale. The source uses distinct age-selectivity curves: a
descending logistic for Shelikof, double logistics for NMFS bottom trawl and
summer acoustic, and a rising logistic for ADF&G. This shared two-curve
approximation intentionally does not reproduce all those distinctions.

Annual catchability now includes `rw(year, by = adfg_indicator)`, applied
*only* to the ADF&G survey. This improves on the former independent annual
ADF&G fixed effects by penalizing changes between years. The official model
instead penalizes log-q changes using source-supplied, year-specific increment
SDs; tinyAM's formula uses one estimated increment SD and operates on
logit-q rather than log-q. Shelikof uses the observed environmental covariate
as a logit-q predictor; the source fits a latent environmental AR1 process
with observation error, which is not reconstructed here. Bottom-trawl and
summer acoustic catchability have no annual random walk in the candidate,
consistent with the absence of active q deviations in the official fit.
The bottom-trawl prior is also omitted and all tinyAM catchabilities remain
bounded by the logit link, unlike the official positive log-q formulation.

The candidate fits the published fishery catch numbers at ages 1–15
(1975–2023), summing ages 10–15 into the modeled age-10 plus group. Because
the published table is rounded to 0.01 million fish, printed zeros are treated
as missing by tinyAM's lognormal catch-at-age observation likelihood. This
uses one estimated catch log-SD rather than the source's separate total catch
biomass and Dirichlet-multinomial composition likelihoods, including source
age-bin accumulation and age-reading error. Survey numbers-at-age are
reconstructed from native biomass, proportions-at-age and appropriate survey
weights and timing; aggregate-only survey years and the reconstructed Shelikof
pooled age-1–3 observation (represented as an age-3 row) are omitted. Survey
observation SDs use supplied relative log-SDs multiplied by an estimated
survey-specific factor. The source instead uses distinct biomass/composition
likelihoods and composition weights.

The pinned official C++ implementation expresses population N and catch C
in billions of fish, with weights in kg per fish. Its total catch expression
`1e6 * sum(C * wt_fsh)` gives tonnes; survey biomass is expressed in million
tonnes. For survey reconstruction, source biomass is converted to kg and
allocated across ages by the native composition and survey weights. The
published catch numbers are converted from millions to fish, and official
N/recruitment and SSB/biomass outputs retain their native million-fish and
thousand-tonne reporting scales. The existing staged native data and unit
checks are unchanged by this translation update.

Female maturity is multiplied by 0.5 in tinyAM. **SSB definitions still
differ:** the official calculation is
`sum(N * exp(-0.21 * Z) * wt_spawn * 0.5 * mat)` using spawning weights,
whereas the candidate's tinyAM SSB is
`sum(N * wt_pop * 0.5 * mat)` at the beginning of the year because no
`spawn_time` was supplied. The native preparation sets
`wt_spawn = wt_srv1` and `wt_pop = wt_srv2`. Numerical common-definition
summaries continue to use translated stock weights and maturity, while the
dashboard retains the official native SSB. Yield reporting continues to use
source total catches and predictions multiplied by source catch weights;
these are conditional median predictions without a lognormal mean correction.

The candidate remains a structural approximation: logistic age curves are
grouped by survey type, fitted q effects use a logit rather than log link, and
the source selectivity priors, environmental measurement process, ADF&G
increment-specific penalties, age-reading error, and composition likelihoods
are not fitted directly. The current package-default fit converged with
optimizer code 0 (`relative convergence (4)`), objective 1,358.922, maximum
absolute gradient 0.000196, successful uncertainty estimation, and a
positive-definite Hessian. Residual checks still flag group location, spread,
and outliers.

Over 1970-2024, the current comparison summary reports mean absolute
percentage differences of 29.2% for total abundance, 46.6% for N-at-age,
50.4% for recruitment, 29.7% for SSB under the shared-biology definition, and
26.1% for biomass. Their terminal differences are +83.9%, +104.1%, +79.2%,
+11.1%, and +48.8%; trend correlations are 0.937, 0.950, 0.949, 0.924, and
0.912. This SSB comparison uses official N with the translated stock weights
and maturity at the start of year; it is not the official native SSB
definition. A separate calculation using the candidate's fitted N/F/M with
the source spawning weights and 0.21 spawning fraction gives 38.7% mean
absolute percentage difference, +7.4% terminal difference, and 0.870 trend
correlation against native official SSB. This derived series has no propagated
uncertainty and is not currently part of the exported comparison summary.

The database retains 371 approximate F-at-age cells derived from rounded
N-at-age and fixed M, but they do not form a complete age-year surface; current
F-at-age and Fbar comparisons are unavailable. Fixed M matches by construction.
An otherwise identical fit using `N_settings$init = "free"` and default
initialization failed numerical checks (optimizer code 1, false convergence,
maximum absolute gradient 93,800, unavailable finite fixed-effect covariance,
and non-positive-definite Hessian). The converged exponential initializer is
therefore retained. No source-based starting values or other model changes
were used.

## Catchability-link sensitivity

Because the official model uses positive log-q, a default-start fit was tested
with the same translated observations and formulas but `q_link = "log"` in
place of the current `"logit"`. The optimizer stopped at code 0 with a small
gradient (0.000055), but fixed-effect covariance was unavailable and the
Hessian was not positive definite, so the fit failed tinyAM's numerical
checks. Aggregate trend correlations were mostly high (0.90–0.96), but median
absolute percent differences increased to 59.6% for SSB, 51.5% for biomass,
44.1% for total abundance, 51.3% for N-at-age and 41.2% for recruitment.
This candidate is not retained. The source's positive q scale is a real
structural difference, but this test cannot establish that the bounded q link
is preferable: the reconstructed age-specific observations and independent
lognormal likelihood may leave q and absolute abundance weakly identified.
