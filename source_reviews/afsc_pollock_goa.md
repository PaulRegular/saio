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

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/afsc_pollock_goa.md). They do not determine source completeness or official run selection.
