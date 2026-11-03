# Eastern Bering Sea pollock: official-assessment source review

Status: canonical record afsc_pollock_ebs_2024 imported; inputs, outputs and assumptions remain partial.
Charbonneau identifier: AFSC_ESB_Gadus_chalcogrammus (historical catalogue spelling ESB).

## Assessment identity

The official 2025 SAFE catch report states that no new assessment was conducted because of the lapse in Congressional appropriations and government shutdown. Its latest full EBS assessment is 2024; previous assessment outputs were rolled forward for specifications. Do not label the 2025 catch-only notice or September 2026 development work as a new fitted assessment.

2025 notice: https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=1.+Pollock+.pdf&p=edbdecfa-ca53-4fc2-a7a2-7caeed6ec8f8.pdf
2024 detailed chapter: https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/EBSpollock.pdf
Both PDFs are cached in source_cache/afsc_pollock_ebs_2024/. The detailed chapter has 212 pages and identifies Model 23.0, with methodology unchanged from 2023. The 2025 rollover ABC/OFL values match its Tier 3 recommendations (2026 ABC 2,036,000 t, OFL 2,496,000 t), providing a production-use crosscheck. The detailed chapter itself is labeled draft for December Council review; verify official model configuration against final SSC/Council decisions before importing numerical records.

## Native source trail

Official repository: https://github.com/noaa-afsc/EBS_pollock
Inspected revision: 44e0cb0ac8698e1d3954273e8aaf760d7c76cba5.
The cached recursive tree is complete. runs/lastyr/README.md explicitly describes main model runs for the 2024 assessment. Its pm.dat starter labels pm_2024_Starter and references pm_24.dat, selvar24.dat, control.dat, pm_fmsy_alt.dat, cov_2024.dat, wtage2024.dat, surveycpue.dat, temp_paul23.dat and q_bts.dat. All referenced files, pm.tpl and compweights.ctl are cached at the pinned revision. The starter and data agree on terminal year 2024, start year 1964, recruitment age 1 and 15 modeled ages. These are candidate official-model inputs, pending numerical verification against the detailed report. Do not use the SAM/Stock Synthesis/RTMB alternative runs or current 2026 sensitivity outputs as production sources solely because they are available.

The native control fixes the age-specific M vector (0.9, 0.45, then 0.3) at phase -6, and SAFE section 5.3.1 confirms constant natural mortality. The canonical database records the vector once. Preserve native total-catch plus composition structure rather than deriving a replacement catch-at-age likelihood input. Survey timing, likelihood weights, covariance and biological transformations are reviewed below; unresolved details remain explicit.

## Native input checks

The source-specific staging reader validated 53 named blocks in pm_24.dat and saved native_input_blocks.json and native_input_block_inventory.csv in the ignored cache. Annual fishery and stock weights have 61 rows by 15 ages, total catch has 61 years, and maturity has 15 ages. Fishery compositions cover 60 years (1964–2023); bottom-trawl compositions cover 42 years (1982–2024); acoustic-trawl compositions cover 19 years (1994–2024). Thus the final modeled catch year has no fishery composition and must not be given an invented age composition.

The runs/lastyr/pm.tpl file is a symlink text pointing to ../../source/pm.tpl; the actual source implementation is separately cached as source_pm.tpl at the same pinned revision. It normalizes fishery and BTS age observations, splits ATS age 1 into a separate recruitment index when use_age1_ats=1, and normalizes ATS compositions over the retained older ages. Therefore ATS total/age-1/composition streams cannot be replaced indiscriminately with a single abundance-at-age series. Their model-ready transformations and sample-size weights require separate representation.

The source multiplies p_mature by 0.5 for female spawning biomass. Keep the source maturity vector and document the female fraction rather than mistaking this for a different maturity-at-age observation. Spawning occurs at fraction (4-1)/12 = 0.25 in this implementation. The starter control uses use_popwts_ssb=1 and phase_natmort=-6; these are implementation evidence requiring final-run verification, not assumptions inferred from names. Current source code may have evolved since the 2024 fit, so matching inputs and outputs to the official report remains necessary before canonical import.

## Report crosscheck

All 510 fishery weight-at-age values overlapping 1991–2024 match SAFE Table 20 within 0.00051 kg (maximum difference 0.000505 kg). This tolerance accommodates the three-decimal report and intermediate five-decimal rounding; report values were not substituted into the higher-precision native inputs. The verification script and result are cached. This verifies the weight input stream, not the entire official run.

SAFE Table 24 reports N with a displayed 10+ group although the native model represents ages 1–15. The displayed output grouping must be identified separately from the actual model plus group. SAFE Table 5 reports observer catch numbers in millions, whereas native fishery oac_fsh_data contains number compositions normalized for its likelihood; native total catch is a separate biomass input. Do not substitute the report observer-number series or its displayed terminal-age grouping for the actual fitted total-plus-composition representation.

## Acceptance and historical output verification

The final December 2024 SSC report, pp. 21–22, explicitly endorses Model 23.0, confirms the listed 2024 data updates and supports Tier 3a classification. This resolves official-model identity; the numerical native-run crosscheck remains separate. The report is cached as SSC_December_2024_final.pdf from https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=2587e1ac-2a37-4a80-b68b-7a8c7e7a02ca.pdf.

Tables 24 and 26 have been staged as report_historical_outputs_raw.csv: 793 historical N-at-age, female SSB, age-1 recruitment and age-3+ biomass estimates for all 61 years 1964–2024. Displayed N ages 1–9 and 10+ remain explicit. Advice projections are excluded from this staging file. Printed CV columns are retained as source fields, not interpreted as absolute standard errors or invented intervals; Table 26 prints zero CV for many SSB/recruitment rows, which must not be treated as evidence of zero estimation uncertainty without checking the reporting implementation/native fit.

## Survey likelihood and unresolved biomass discrepancy

The cached implementation Get_Catch_at_Age evaluates BTS and ATS at mid-year, using N multiplied by S^0.5. Historical fishery CPUE and AVO predictions instead use beginning-year N without this survival adjustment; record model timing separately from field sampling dates. The active controls use biomass indices (do_bts_bio=1, do_ats_bio=1), BTS full covariance (DoCovBTS=1), and ATS age-1 separation (use_age1_ats=1). The calculated terminal ATS number-index error ratio is 1.8076, above 0.4, so the source exclusion rule omits the 2024 ATS age-1 index from its process likelihood. This conditional exclusion must be retained when preparing fitted-observation rows.

The first text-only reading of SAFE Table 14 incorrectly assigned its 2024 value 7,958 to VAST. Visual inspection of PDF page 73 confirms that this is DDC; the 2024 VAST cell is blank. Native pm_24.dat gives VAST biomass 9,407.463571 thousand t, so there is no contradictory 2024 VAST cell in this table. ATS 2024 biomass agrees (2,870.636995 versus rounded 2,871 thousand t). BTS age-composition shapes agree with the report's 2024 values, but their printed numerical scale is distinct from the raw native matrix and must not be assigned from a caption alone. GitHub history for runs/data/pm_24.dat shows a single startup commit, 890a51deadb50549cdd8bd769b47b172dfc2aa38, dated 2025-01-27; there is no evidence of a later edit to this file. Earlier reported VAST values differ slightly from the native file (for example 2023: 4,934 versus 4,945.387531 thousand t); matching weights alone does not settle those revisions. Preserve both sources, prefer verified final native input values, and do not silently average or rescale them. The report population-biomass prose also mentions 9.41 million t, but that is a fitted population output and must not be used as survey-input verification.

## Fixed natural mortality resolved

SAFE section 5.3.1 explicitly states constant natural mortality rates at age for M23. Native control.dat supplies 0.9 at age 1, 0.45 at age 2 and 0.3 at ages 3–15, fixes the mortality-scaling parameter at phase -6, and sets switch_pred_mort=0. The implementation copies this vector into annual M when optional alternative mortality switches are inactive. The 15-value supplied vector is now canonical input, stored once for the full modeled period, with age 15 the plus group. It is not a fitted output or an annual predation estimate. scripts/database/026_import_ebs_pollock_mortality.R checks the source controls and report wording.

Initial ages 2–15 are exp(log_avginit + log_initdevs), rather than an equilibrium age distribution. The code estimates the mean from phase 1 and bounded age deviations from phase 3, with a quadratic deviation penalty. This verified parameterization is now recorded separately; additional conditional constraints are not assumed resolved. The stock-specific validator now includes the recovered fixed M vector.

The additional mean-initial-abundance constraint is optimization-phase conditioning only: 10*(log_avginit-log_avgrec)^2 applies below phase 3 and is removed from the final objective. The final initial-age penalty is 0.1*sum(log_initdevs^2), multiplied by ctrl_flag(3)=1. This distinction is now explicit in the assumptions record.

## Bottom-trawl covariance recovered

All 1,764 cells of the 42-by-42 supplied covariance matrix are now preserved as year-labeled numerical assumption rows, with explicit column years 1982–2019 and 2021–2024. Native-source checks confirm symmetry, positive definiteness and exact numerical round-trip. The likelihood uses unlogged biomass residuals after q normalization, not log-index errors. This matrix must not be replaced by independent observation SDs when describing the official assessment.

## Composition weights and active observation likelihoods

The 60 fishery, 42 BTS and 19 ATS sam values have been captured by year as native composition likelihood weights. These are the values passed to robust_p and remain distinct from raw age frequencies. Control flags also verify BTS full-covariance biomass likelihood, ATS biomass likelihood and separate ATS age-1 treatment. Numerical BTS covariance is independently stored by calendar-year rows. The no-age-error switch is zero, so the official fit uses an identity ageing-error treatment.

## Remaining native observation inputs

The database now includes the source-specific weight-at-age matrices for BTS (42 years), ATS (19 years), and AVO (18 years), each across ages 1–15. It also includes the four native index-SD vectors: CPUE (12 years), AVO (18), BTS (42), and ATS (19). CPUE and AVO use their native-scale SDs in their residual likelihoods; ATS converts its supplied SDs to log-scale variance; BTS uses the supplied full covariance under `DoCovBTS=1`, so its SD vector is retained but is not the active likelihood variance.

The native temperature vector is recorded by BTS year. Its unit is not stated in the model data file, and the control fixes the temperature slope at zero. The single fishery length-composition vector is also recorded after the same normalization used by the model; its fixed likelihood weight is 50. The model code defines its length-bin values as 20–69 in unit increments, but the input does not identify their units.

## Recovered outputs and comparison definitions

The official report's historical outputs are retained in their native units:
N-at-age (ages 1–9 and a reported 10+ group), age-1 recruitment, female SSB,
and one age-3+ biomass total for each year from 1964–2024. The 10+ report row
is not age 10. In comparisons it maps to the sum of tinyAM ages 10–15, while
the tinyAM model plus group remains age 15. Total abundance is calculated
from all official N groups and compared with tinyAM abundance across ages
1–15. Recruitment is matched at age 1.

SAFE Table 26's age-3+ biomass is stored as biomass_by_age_group, with age
blank and age_group set to 3+. It is compared with tinyAM biomass summed over
ages 3–15. Female SSB is available for both fits over ages 1–15. The current
tinyAM translation sets `obs$maturity$spawn_time = 0.25` and scales supplied
maturity by 0.5, matching the source's female spawning-time biomass convention.
The SSB comparison is now marked `matched` in the sense of its biomass
definition, **not** as a claim of identical fitted SSB estimates or likelihoods.
Printed CV fields are not converted to standard errors; uncertainty is
unavailable for these source outputs.

Annual official F-at-age was reconstructed from the fitted parameter file
runs/lastyr/pm_or.parxx, the selectivity-change table runs/data/selvar24.dat,
and source/pm.tpl, all at pinned repository revision
44e0cb0ac8698e1d3954273e8aaf760d7c76cba5. The reconstruction uses
F(y,a) = exp(log_avg_F + log_F_devs[y]) * exp(log_sel[y,a]); selectivity
coefficients are extended through age 15 as the source code specifies,
time-varying deviations are applied in their flagged years, and exp(log_sel)
is re-normalized to arithmetic mean one across ages for each year. All 915
year-age values pass the source normalization check: their annual age mean
equals exp(log_avg_F + log_F_devs[y]). This is a deterministic reconstruction
from the official fitted object and its implementation, not values digitized
from figures. F uncertainty is unavailable. No Fbar comparison is reported
because a common age range and weighting definition have not been established.
The record remains partial because other official inputs, assumptions and
uncertainty are not fully represented.

## Final tinyAM translation (current candidate)

The attached stock translation retains model years **1964–2024**, ages **1–15**,
and age **15+** as the terminal plus group. It retains the source's fixed
age-dependent natural mortality: M = 0.9 at age 1, 0.45 at age 2 and 0.3 at
ages 3–15. Annual stock weights, source-specific survey weights, and source
maturity are supplied through the translation. The maturity vector is
multiplied by **0.5** for female biomass and SSB uses **`spawn_time = 0.25`**.

The fitted settings in the updated stock recipe are:

```r
N_settings = list(process = "off", init = "exp")
F_settings = list(process = "cor_rw", mu_form = NULL)
M_settings = list(process = "off", mu_form = NULL,
                  mu_supplied = ~M_assumption)
catch_settings = list(sd_form = ~1)
index_settings = list(
  q_form = ~0 + survey + logistic(age, by = survey),
  sd_form = ~0 + survey
)
# rec_settings is omitted: tinyAM's default recruitment random walk applies.
```

**Population process and scale.** Older cohorts follow deterministic survival
through F and M, without IID abundance-process deviations. Initial
older-age abundance uses tinyAM's exponential survivorship parameterization.
This remains different from the source's penalized initial-age deviations,
and tinyAM's default recruitment random walk is not the native recruitment
parameterization. Earlier tinyAM trials included IID N deviations; removing
those deviations was the principal change associated with much better
agreement in scale, according to the subsequent model-development comparison.
This observation is qualitative until the updated diagnostics and comparison
summary are regenerated.

**Fishing mortality.** The current translation uses `cor_rw`, with an
age-correlated innovation vector for annual changes in log F; the model does
not impose a fixed F selectivity curve. In contrast, the official model
factorizes annual fishing intensity and age-specific fishery selectivity,
with selectivity itself varying over time under regularization. Thus the
current correlated F random walk is a parsimonious approximation, not an
exact representation of the native fishery process.

**Catch observations.** The official fit uses total fishery catch biomass
and an effective-sample-size-weighted age-composition likelihood, rather
than direct lognormal catch-at-age observations. tinyAM reconstructs catch
numbers-at-age and fits the positive observations with **one shared lognormal
catch SD** (`sd_form = ~1`), without the earlier quadratic age effect.
Reconstructed catch observations below **0.02** are set to zero to align
with rounded zero cells in the report; those zero cells are not fitted as
positive lognormal observations. The source's missing 2024 fishery
composition is not fabricated.

**Bottom-trawl and acoustic-trawl surveys.** The native BTS model includes
a full across-year VAST biomass covariance, age-composition likelihood,
and time-varying logistic selectivity with a separate treatment of age 1.
Native ATS uses biomass and age-composition likelihoods with time-varying,
penalized age-selectivity coefficients rather than a static logistic curve.
The current tinyAM translation replaces these components with reconstructed
mid-year age-specific indices. Each survey receives its **own catchability
baseline and static logistic age curve** through
`~0 + survey + logistic(age, by = survey)`, and its own independent lognormal
observation SD through `~0 + survey`. There is **no temporal survey-q random
walk** in the final translation. The former survey-by-age q blocks and their
pooled ages 9+ are not used by the current fitted formula.

The source treats ATS age 1 as a separate recruitment index, whereas tinyAM
combines available ATS age-1 values with the main acoustic-trawl age-specific
index. The 2024 age-1 value remains excluded in both representations because
it fails the native uncertainty criterion. Historical fishery CPUE and
acoustic-vessel-of-opportunity indices are omitted from tinyAM's age-specific
translation because they lack the associated age-composition information.

**Comparison definitions.** Reported official N for ages 1–9 is compared
directly with tinyAM, whereas the official reported **10+** abundance is
compared with the sum of tinyAM ages **10–15**; it is not the model's age-15
plus group. Age-1 recruitment, total abundance over ages 1–15, and reported
age-3+ biomass are matched on their corresponding age definitions. Female
SSB now also uses the same **0.25-year spawning fraction** and **0.5 female
maturity multiplier** as the source, so it is no longer labelled an
approximate comparison *because of spawning time*. Differences in fitted
SSB may still arise from different mortality, population, and observation
models. Official F-at-age is reconstructed from the pinned native fit and
source code; F uncertainty remains unavailable. The fixed source M vector
matches by construction.

**Updated numerical validation pending.** The numerical diagnostics and
agreement statistics previously recorded here (including the objective
1,917.084, 27 fixed parameters, 1,815 random effects, and the corresponding
scale differences and correlations) describe an **older tinyAM configuration**
with IID N deviations, independent F random walks, quadratic catch SD, and
survey-by-age q blocks. They should **not** be attributed to this revised
model. Once the updated fit and comparison tables are available, regenerate
`fit_diagnostics.csv`, `comparison_summary.csv` and the relevant figures, and
insert the current convergence, SSB-scale, abundance, recruitment and F-at-age
comparison results here. No updated numerical performance claims have been
introduced without those outputs.

The current candidate is a deliberately **simplified structural
translation**, not a claim of likelihood-level equivalence to the operational
assessment.
