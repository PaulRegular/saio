# Gulf of Alaska Pacific cod: official-assessment source review

Status: canonical partial record afsc_cod_goa_2026 imported. Inputs and reported summary outputs are transcribed; numerical N-at-age and F-at-age surfaces from the current official run have not been recovered.
Charbonneau identifier: AFSC_GOA_Gadus_macrocephalus.

The active control fixes BH steepness at one and recruitment SD at 0.44;
a freely estimated BH curve would change that source assumption.

## January 2026 assessment

The January 2026 update (presented February 2026) uses Model 24.0 official in 2024, updated through 2025. The 54-page detailed update and 2024 full model-defining chapter are cached under source_cache/afsc_cod_goa_2026/.
Current detailed source: https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C1+GOA+Pcod+Assessment.pdf&p=f00593eb-12f5-458c-842e-a5cdd45306bb.pdf
Framework/full 2024 source: https://files.npfmc.org/SAFE/2024/GOApcod.pdf

The Council's February 6, 2026 announcement confirms that the updated assessment was reviewed by the Plan Team and SSC and superseded December 2025 specifications. Thus the 2025 shutdown catch-only rollover is not the current official assessment for this stock.
Acceptance source: https://www.npfmc.org/council-recommends-substantial-increase-to-gulf-of-alaska-pacific-cod-catch-limits-for-2026-27/

The report states 2026 ABC 41,520 t and OFL 49,782 t, projected total age-0+ biomass 182,156 t, and female SSB 52,772 t. These are projection values, not historical 2025 estimates. Historical values must be extracted from their own tables without mixing columns or assessments.

## Native model files

The report page 2 directly links to https://afsc-assessments.github.io/goapcod/2025_Assessment/January_Model/.
Corresponding repository: https://github.com/afsc-assessments/goapcod
Inspected revision: e632807e4947686c16caf99b864bfe8466f8dbca.
The native archive docs/2025_Assessment/January_Model/model_files/M24.0_SS3_files.zip is cached and unpacked locally. It contains GOAPcod2025Dec08.dat, Model24_0.ctl, starter.ss and forecast.ss. The archive itself has no fitted output file; the matching management-run repository contains a compact ss3.rep, discussed below.

The starter names those exact data/control files and has retro_yr=0. The data specify 1977–2025, one annual season, two subseasons, spawning month 1, one sex and area, maximum modeled age 10, and seven fleet definitions. The three removal fleets are FshTrawl, FshLL and FshPot. The report explicitly says the longline category includes jig catches. Survey definitions also include Srv, LLSrv, ADFG and Seine; determine which actually contribute positive-weight observations before assuming four fitted surveys. Report inventory identifies bottom trawl and longline surveys as fitted abundance/composition streams.

Native inputs include length compositions and conditional age-at-length observations. Do not collapse these into age-only catches or infer an age composition from model predictions. A faithful representation will need to retain conditioning length bins and native weighting, with a narrow schema extension if required.

The control uses estimated natural mortality with a temporal block including 2014. Its parameter starting values are not estimated M outputs and must not be exported as fixed M inputs. Maturity is length-logistic in the control; do not substitute a guessed age-maturity vector. Detailed parameter, temperature-covariate, biology, survey timing and uncertainty interpretation remains pending.

An older author repository, https://github.com/pete-hulson/goa_pcod at facf41573f9a0b609d0096611bc9302aaab43abe, was inspected initially; the current report's directly linked repository is preferred. Earlier 2024 numerical files are context only, not substitutes for the current official run.

## Native observation inventory

The source-specific inventory reader cached in inventory_native_observations.py checks column counts and section sentinels, and stages every source cell in native_observation_sections_raw.csv. It found 150 catch rows: three initial-equilibrium rows and 147 historical fleet/year catches (49 years for each of trawl, longline/jig and pot). The index section has 110 source rows, of which 52 have positive year and fleet codes: 17 bottom-trawl indices and 35 longline indices. ADFG/Seine definitions do not imply active fitted indices.

Length compositions have 182 positive year/fleet rows: trawl 48, longline/jig 46, pot 36, bottom trawl 17, longline survey 35. The age section has 923 source rows, of which 857 have positive year/fleet codes: trawl 205, longline/jig 190, pot 168 and bottom trawl 294. These are composition records, not counts of unique observation years. Their conditioning length intervals, sample sizes, age-error codes, partition and sex fields must be retained. Remaining age/index records include negative codes and must not be counted as fitted streams.

The official Stock Synthesis manual explains that a negative fleet code excludes a composition observation's likelihood contribution, even though predictions and diagnostics may still be calculated. It also confirms that the observation's month determines survey timing; the fleet-definition timing field is not sufficient.
Manual: https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html

## Historical summary staging

stage_historical_summaries.py cached 147 current-run values (49 years each for female SSB, total age-0+ biomass and age-0 recruitment) from Tables 2.7 and 2.8. Row counts passed. Earlier-assessment columns and the separate 2026 forecast were excluded. Reported SDs are retained separately without inventing intervals.

Recruitment units need resolution before canonical import: Table 2.8 labels values such as 0.48 as millions, whereas Table 2.6 reports log(mean recruitment)=13.09 and Stock Synthesis normally represents numbers in thousands. exp(13.09) is approximately 484,000 model units, or 484 million fish; this suggests the printed table may actually be in billions, but it is not yet direct evidence of each reported recruitment's scaling. Obtain native time-series outputs or verify the table-generation scale before changing the unit or importing a guessed correction. Preserve the original printed values in the source staging table.

## Recruitment scale resolved and official output verified

The author repository DOES contain the current management run under 2025/mgmt/24.0. Its data and control numeric contents match the report-linked January archive exactly after removing comments/whitespace; byte hashes differ because formatting/comments differ. The cached ss3.rep is a compact fitted report, not a full Report.sso, and contains historical spawning output/recruitment and selectivity information.

Direct reporting code 2025/R/safe_tbls.R at facf41573f9a0b609d0096611bc9302aaab43abe divides recruitment Value and StdDev by 1,000,000. Since native SS numbers are thousands, Table 2.8 is in BILLIONS of fish despite its printed millions heading. It also divides native spawning output Value and StdDev by 2 for reported female SSB. Thus native unadjusted spawning output is not directly the published female SSB.

verify_historical_summary.py checked all 49 historical years: native recruitment / 1e6 matches Table 2.8 to 0.0051 printed units, and native spawning output / 2 matches Table 2.7 female SSB to one tonne (compact-report rounding). Both checks passed. The verified staging file records billion fish units; the original raw extraction retains the misleading printed label and remains cached. No input observations were adjusted using fitted parameters.

Source code: https://github.com/pete-hulson/goa_pcod/blob/facf41573f9a0b609d0096611bc9302aaab43abe/2025/R/safe_tbls.R
Native output: https://github.com/pete-hulson/goa_pcod/blob/facf41573f9a0b609d0096611bc9302aaab43abe/2025/mgmt/24.0/ss3.rep
## Composition and timing checks

All 857 positive-year, positive-fleet age records are conditional age compositions. Each has identical lower/upper conditioning labels, ranging from 4.5 to 104.5, an age-error code of 1 or 2, and partition 0. Their ten age proportions sum to between 0.99999 and 1.00001, consistent with source rounding. These records must retain the conditioning labels rather than being collapsed into annual unconditional age compositions.

The data file sets Lbin_method=1 (population-length bins), while the observation labels are half-integers matching the length-composition labels. The interpretation of these labels needs verification against the fitted SS version/implementation before treating them as physical centimetre bounds. Preserve native values; do not silently reinterpret them as integer bin indices.

Every positive index observation uses month 7. Length and age composition records use months 1 or 7. Survey timing must therefore be derived from the observation month, not the fleet-definition default. Fishery composition timing and continuous catch timing remain distinct.

The composition schema validator checks finite numeric dimensions, non-negative integer age-error/partition codes, positive supplied sample sizes, observation IDs and ordered conditioning labels. The canonical Pacific cod composition rows retain the native conditioning labels, sample sizes and age-error codes; source and database validation pass. The tinyAM translation uses a pooled age-length key and does not preserve the source conditional-composition likelihood.

## Canonical coverage and validation

Assessment afsc_cod_goa_2026 contains 12,689 input cells: 147 catch totals, 52 index observations, 52 index log SDs, 46 environmental covariates, 3,822 length-proportion cells and 8,570 conditional-age-proportion cells. The 1,039 composition observations retain supplied sample sizes, native length labels/conditioning bounds, age-error codes and partitions. The outputs table contains 147 historical summaries, 539 repeated year/age representations of two shared M estimates, and two published baseline-q estimates. The assessment has 34 documented assumptions.

The source-specific validator checks each composition cell against the cached native data, verifies observation counts, sample sizes and timing, and confirms that adding optional composition dimensions leaves all earlier input values unchanged. These checks and full database structural validation pass. All completeness statuses remain partial. Equilibrium inputs, selectivity details, interpretation of environmental-covariate units and N/F-at-age outputs still require work. Published baseline q estimates and source ageing-error vectors are recorded; they do not complete the assessment.
## Additional material input review

The control links longline catchability to environmental variable 1 (env_var&link=101). All 46 supplied annual temperature-covariate values, 1979–2024, are now represented verbatim as environmental covariates, including negative values. Native scaling units remain unresolved; no restandardization was applied. Source-specific validation checks every year/value against the data section.

All 16 mean-size-at-age observations have negative fleet code -4 and therefore no fitted likelihood contribution. Their absence from canonical fitted observations is intentional; source records remain cached. Three initial-equilibrium catch values and their supplied SEs are retained in fleet-specific assumptions because native year -999 is not a calendar year. The two ageing-error mean/SD definitions (age 0 through age 10) are retained once as numerical assumption vectors. Definition 2's -1 mean flags must not be interpreted as measured negative ages or an empirical misclassification matrix.

Pacific cod coverage is now 12,689 input cells, 688 outputs and 34 assumptions. Structural and source-specific validation pass. Selectivity details, covariate units and fitted N/F-at-age surfaces remain incomplete; all statuses remain partial. The earlier gap list is superseded for temperature, equilibrium catches and source ageing-error vectors.
## Estimated mortality and fixed biological parameters

Table 2.6 reports estimated M=0.50 (SD 0.023) outside the 2014–2016 block and M=0.84 (SD 0.053) inside it. The native control specifies age-constant M (natM_type=0) with replacement block 4 covering exactly 2014–2016. The database now expands these rounded published estimates to 1977–2025, ages 0–10+, as 539 mortality output cells. These are repeated representations of two shared parameters, not independently estimated age/year values; notes state the rounding and shared uncertainty. No confidence intervals are manufactured.

Fixed weight-length coefficient/exponent, maturity length/slope, stock-recruit steepness and recruitment sigma are retained as numerical assumptions from negative-phase control parameters. The native stock-recruit code 3 selects the standard Beverton-Holt relationship, now recorded in the assumptions table. They are input parameters, not estimated age-specific biological surfaces. The compact ss3.rep does not contain N-at-age or F-at-age surfaces. Table 2.6 supplies age-constant M estimates with a 2014–2016 block; the database repeats these shared estimates over year and age to match the canonical mortality surface, not as independent age-year estimates.

Coverage is now 12,689 input cells, 688 outputs and 34 assumptions. Source validation verifies the M block/year/age mapping and absence of invented intervals, alongside native composition/covariate checks; full structural validation passes. N/F-at-age and selectivity interpretation still require work. Status remains partial.

## Active-survey catchability controls

The official native control estimates baseline log q for both active surveys (phase 1). Bottom-trawl q has no environmental term; longline q also estimates the environmental coefficient (phase 5, env-var/link 101). Neither baseline uses annual deviations or time blocks. These parameter controls are now explicit assumptions, verified by scripts/database/023_review_goa_cod_catchability.R. Parameter starting values are not exported as estimates. This source-review script supplements the initial importer; it belongs to curation, not routine database-to-model translation. Structural validation passes. The published baseline q estimates are summarized below; selectivity details remain unresolved.

## Published baseline catchability estimates

Table 2.6 supplies bottom-trawl baseline q=1.28 (SD 0.123) and longline baseline q=1.17 (SD 0.108). Both are now outputs, with no invented confidence limits. The cached safe_tbls.R confirms exponentiation of log-q estimates and natural-scale delta-method SDs. These rounded baseline coefficients are distinct from starting values and from the environmentally varying annual longline q surface. scripts/database/024_import_goa_cod_catchability.R records and checks the published values.

The current report explicitly states that CFSR was discontinued and no 2025 value was available. SS3 uses a zero environmental effect in that year; this model rule is now an assumption, not an observed-zero input. The 46 supplied covariates remain 1979–2024. Physical anomaly units remain unresolved.

## Published growth parameters

Table 2.6 of the January 2026 assessment reports estimates and standard deviations for beginning-year length at ages 1 and 10, the von Bertalanffy growth rate, and length-at-age standard deviation at ages 1 and 10. These five estimates are now recorded in `outputs.csv` with their reported natural-scale standard deviations. The official control specifies one von Bertalanffy growth pattern and length-at-age standard deviation as a function of mean length. These parameters support an explicit translation-time reconstruction of biological surfaces; they are not direct annual weight-at-age or maturity-at-age input tables. The record remains partial because fitted abundance-at-age and a complete output inventory are unavailable.

## Current tinyAM candidate translation and fit

The translation fits 2007–2025, when fishery length compositions and conditional
age-at-length samples overlap. Separate fishery-specific pooled age–length keys
are estimated from supplied samples (through 2024), used to convert annual length
compositions and biomass catches into catch-at-age, and then the three fisheries
are aggregated. Uncovered length-bin mass is omitted and reconstructed age shares
are normalized. The official likelihood is based on fleet catches, length
compositions and conditional ages, not these pseudo-observed catch numbers at age.

Only the age-sampled NMFS bottom-trawl survey is translated. Its aggregate index
is allocated across ages with the pooled age–length key; the original aggregate
log SD is repeated across reconstructed age rows. Month-7 observations use an
approximate year fraction of 0.5. The longline survey is not fitted because
age-composition coverage required by this translation is unavailable.

Population weights/maturity are reconstructed from official fitted mean-growth
parameters and the source weight–length and maturity functions. The approximation
does not integrate length variability within age. The female maturity multiplier
is 0.5. Source M estimates (including the 2014–2016 elevated M block) are supplied
and held fixed. SSB in the original assessment includes age 0, whereas the tinyAM
translation starts at age 1, so agreement is approximate by definition.

### Candidate specification (requires a new fit)

```r
N_settings     = list(process = "off", init = "exp")
# Default tinyAM recruitment RW retained (not source BH recruitment)
F_settings     = list(process = "cor_rw", mu_form = NULL)
M_settings     = list(process = "off", mu_form = NULL,
                      mu_supplied = ~ M_assumption)
catch_settings = list(sd_form = ~ 1)
index_settings = list(
  q_form = ~ logistic(age) + rw(year),
  sd_form = ~ 1,
  sd_supplied = ~ relative_sd
)
```

This paired-specification experiment replaces the earlier **IID F deviations
around age means** (`process = "iid", mu_form = ~ factor(age)`) with correlated
annual F random walks. In contrast to a fixed logistic F-age curve, each age can
evolve through time while annual changes are correlated across ages. The survey q
model now combines a smooth ascending logistic age curve with a shared year random
walk on log catchability. That RW affects the *survey level* and is **not**
equivalent to the original length-based time-varying survey selectivity. Unlike the
source, the small translation has one aggregated fishery and does not reproduce
the conditional age-at-length likelihood.

Earlier candidate exploration suggested that additional **F flexibility** was
important for agreement, but did not establish that `cor_rw` outperforms IID F.
This new candidate has not been fitted or diagnosed as part of this revision.
The GOA translation retains exponential older-age initialization because the
previous free-initial-state configuration was numerically unreliable.

### Historical comparison from the preceding F-IID candidate

The previously documented `F_settings = list(process = "iid", mu_form = ~ factor(age))`
candidate reported optimizer code 0, relative convergence 4, objective 274.38,
maximum absolute gradient 0.000411, positive-definite Hessian, 25 fixed and 208
random effects. Its approximate 2007–2025 aggregate SSB comparison reported
mean absolute difference 24,893 t (32.10%), terminal difference +7.73%, and
trend correlation 0.945. Those results belong to that earlier fit and should
**not** be used to describe the new `cor_rw` F / logistic-plus-year-RW q model.

Official N-at-age and F-at-age surfaces remain unavailable. The M comparison
is equal by construction because numerical official M was supplied; recruitment
and total biomass remain definition-non-equivalent because of source age 0.

## Cached fitted-object check

The cached goapcod_obj.RDS at
https://github.com/pete-hulson/goa_pcod/blob/facf41573f9a0b609d0096611bc9302aaab43abe/2025/rsch/SPoRC/goapcod_mod_files/goapcod_obj.RDS
was inspected rather than assumed to be the official 2026 fit. Its fitted
years end in 2024, and its aggregate SSB does not reproduce the current Model
24.0 report series (for example, 78,050 t versus 81,532 t in 1977 and 62,366
t versus 72,336 t in 2007). It therefore is not used to populate official
outputs. The current official source remains the pinned 2025/mgmt/24.0/ss3.rep
and the official report. The compact report supports historical aggregate
female SSB, age-0 recruitment and the published M blocks, but does not provide
official N-at-age or F-at-age surfaces. Do not derive them from plots or from
this mismatched cached fit object.

The comparison keeps official SSB in tonnes and scales tinyAM kilograms to
tonnes by 1e-3. It is approximate because the source aggregate covers ages
0+ while tinyAM starts at age 1. The dashboard also retains official total
biomass in tonnes and recruitment in billions, but reports no percent
difference: age-0 biomass cannot be removed from the aggregate total, and
source recruitment is age 0 while tinyAM recruitment is age 1. Official M is
numerically available and matches tinyAM by construction because the reported
M blocks are supplied as fixed M; it is not an independent model validation.
N-at-age, F-at-age and definition-matched F summaries remain unavailable. The
assessment stays partial.
