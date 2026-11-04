# Gulf of Alaska Pacific cod: official-assessment source review

Status: canonical partial record afsc_cod_goa_2026 imported. Original observations and reported summary outputs are transcribed. Beginning-of-year N-at-age and fleet-specific and summed F-at-age surfaces have now been recovered from a run-matched SS3 report reconstruction. Age-specific uncertainty and several model-input details remain unavailable.
Charbonneau identifier: AFSC_GOA_Gadus_macrocephalus.

## Currentness check as of 2026-10-28

The latest detailed operational run identified remains the January 2026 Model
24.0 assessment. NPFMC's February 2026 assessment-cycle memo planned a fall
harvest projection for GOA Pacific cod, rather than a new full assessment,
because no new survey data were expected. I did not find a separate GOA cod
projection report among the posted September Plan Team materials. The
September 9 presentation titled “Pacific cod” is a spatial SPoRC research
project, with results planned for the September 2027 Plan Team meeting; it is
not a new official operational fit or a source for replacement outputs. The
November 16–20, 2026 Plan Team schedule lists GOA Pacific cod and ESP, after
this review date, so revisit the source search when those materials are posted.

Sources:
- NPFMC February 2026 assessment priorities:
  https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=D2+Groundfish+Stock+Assessment+Priorities.pdf&p=ff7dee7e-242d-42e7-85c7-2479d7eeac96.pdf
- September 2026 Plan Team docket:
  https://meetings.npfmc.org/Meeting/Details/5140
- Cached spatial-research presentation:
  source_cache/afsc_cod_goa_2026/2026_09_goa_pcod_spatial_research_plan_team.pdf
- November 2026 Plan Team schedule:
  https://meetings.npfmc.org/Meeting/Details/8165

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

## Reconstructed native age-specific outputs

The report-linked January archive at `e632807e4947686c16caf99b864bfe8466f8dbca` supplies the Model 24.0 data and control files. The saved management-run `ss3.par` at `facf41573f9a0b609d0096611bc9302aaab43abe` matches the current report's objective (2108.97949000959) and maximum gradient (6.44551037822919e-06; reported as 6.45e-6). Using the official Stock Synthesis 3.30.22.1 executable, the archived files and saved parameters reproduced `Report.sso` with a single parameter evaluation (`-maxfn 0 -phase 50 -nohess`); this did not refit or change the saved estimates. The native inputs, parameter file, executable and generated report are cached locally and listed with checksums in `source_cache/afsc_cod_goa_2026/manifest.csv`.

`NUMBERS_AT_AGE report:35` supplies beginning-of-year N for ages 0–10 (age 10 is the plus group) in 1977–2025. `F_AT_AGE report:39` supplies annual F at ages 0–10 for the three removal fleets, FshTrawl, FshLL and FshPot, over the same years. The canonical outputs now retain all three fleet surfaces and their age-specific sum. N is recorded in thousand fish and F in per year. The summed F is a derived common surface; it is not the annual Sum Apical F reported in Table 2.9. The native age surfaces have no age-specific SE because uncertainty estimation was not run. No uncertainty has been inferred.

Cross-checks support the recovered scale and run identity: age-0 N divided by 1e6 matches the published recruitment series to a maximum absolute difference of 0.004886 billion fish, within the 0.0051 rounding bound; reported spawning output divided by two matches female SSB in Table 2.7 to 0.5 tonnes or less for all 49 years. The reconstructed report contains one warning about a time-block pattern ending at the terminal year and a note about the revised forecast-year protocol; neither changed the saved parameter estimates. The assessment remains partial because source coverage and interpretation gaps remain elsewhere.

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

The composition schema validator checks finite numeric dimensions, non-negative integer age-error/partition codes, positive supplied sample sizes, observation IDs and ordered conditioning labels. The canonical Pacific cod composition rows retain the native conditioning labels, sample sizes and age-error codes; source and database validation pass.

## Canonical coverage and validation

Assessment afsc_cod_goa_2026 contains 12,689 input cells: 147 catch totals, 52 index observations, 52 index log SDs, 46 environmental covariates, 3,822 length-proportion cells and 8,570 conditional-age-proportion cells. The 1,039 composition observations retain supplied sample sizes, native length labels/conditioning bounds, age-error codes and partitions. The outputs table contains 147 historical biomass/recruitment summaries, 539 repeated year/age representations of two shared M estimates, 49 annual sum apical-F estimates, five growth-parameter estimates, and two published baseline-q estimates (742 output rows total). The assessment has 34 documented assumptions.

The source-specific validator checks each composition cell against the cached native data, verifies observation counts, sample sizes and timing, and confirms that adding optional composition dimensions leaves all earlier input values unchanged. These checks and full database structural validation pass. All completeness statuses remain partial. Equilibrium inputs, selectivity details, interpretation of environmental-covariate units and age-specific uncertainty still require work. Published baseline q estimates and source ageing-error vectors are recorded; they do not complete the assessment.
## Additional material input review

The control links longline catchability to environmental variable 1 (env_var&link=101). All 46 supplied annual temperature-covariate values, 1979–2024, are now represented verbatim as environmental covariates, including negative values. Native scaling units remain unresolved; no restandardization was applied. Source-specific validation checks every year/value against the data section.

All 16 mean-size-at-age observations have negative fleet code -4 and therefore no fitted likelihood contribution. Their absence from canonical fitted observations is intentional; source records remain cached. Three initial-equilibrium catch values and their supplied SEs are retained in fleet-specific assumptions because native year -999 is not a calendar year. The two ageing-error mean/SD definitions (age 0 through age 10) are retained once as numerical assumption vectors. Definition 2's -1 mean flags must not be interpreted as measured negative ages or an empirical misclassification matrix.

Pacific cod coverage is now 12,689 input cells, 3,437 outputs and 34 assumptions. Structural and source-specific validation pass. Selectivity details, covariate units and age-specific uncertainty remain incomplete; all statuses remain partial. The earlier gap list is superseded for temperature, equilibrium catches, source ageing-error vectors and N/F-at-age surfaces.
## Annual apical fishing mortality

Table 2.9 reports annual Sum Apical F and SD[F] for 1977–2025. These rounded
three-decimal values are imported as the scalar measure apical_F, with the
reported SD retained in the output uncertainty field. They are not age-specific
F estimates or Fbar, and no confidence intervals are reconstructed. The
assessment output-generation script extracts the annual F-derived quantities
and rounds their estimates and SDs to three decimals. Script: https://github.com/pete-hulson/goa_pcod/blob/facf41573f9a0b609d0096611bc9302aaab43abe/2025/R/safe_tbls.R.

## Estimated mortality and fixed biological parameters

Table 2.6 reports estimated M=0.50 (SD 0.023) outside the 2014–2016 block and M=0.84 (SD 0.053) inside it. The native control specifies age-constant M (natM_type=0) with replacement block 4 covering exactly 2014–2016. The database now expands these rounded published estimates to 1977–2025, ages 0–10+, as 539 mortality output cells. These are repeated representations of two shared parameters, not independently estimated age/year values; notes state the rounding and shared uncertainty. No confidence intervals are manufactured.

Fixed weight-length coefficient/exponent, maturity length/slope, stock-recruit steepness and recruitment sigma are retained as numerical assumptions from negative-phase control parameters. The native stock-recruit code 3 selects the standard Beverton-Holt relationship, now recorded in the assumptions table. They are input parameters, not estimated age-specific biological surfaces. The compact ss3.rep does not contain N-at-age or F-at-age surfaces; those surfaces have now been recovered from a full Report.sso generated from the run-matched native inputs and saved fitted parameters. Table 2.6 supplies age-constant M estimates with a 2014–2016 block; the database repeats these shared estimates over year and age to match the canonical mortality surface, not as independent age-year estimates.

Coverage is now 12,689 input cells, 3,437 outputs and 34 assumptions. Source validation verifies the M block/year/age mapping and absence of invented intervals, alongside native composition/covariate checks; full structural validation passes. Selectivity interpretation and age-specific uncertainty still require work. Status remains partial.

## Active-survey catchability controls

The official native control estimates baseline log q for both active surveys (phase 1). Bottom-trawl q has no environmental term; longline q also estimates the environmental coefficient (phase 5, env-var/link 101). Neither baseline uses annual deviations or time blocks. These parameter controls are now explicit assumptions, verified by scripts/database/023_review_goa_cod_catchability.R. Parameter starting values are not exported as estimates. This source-review script supplements the initial importer. Structural validation passes. The published baseline q estimates are summarized below; selectivity details remain unresolved.

## Published baseline catchability estimates

Table 2.6 supplies bottom-trawl baseline q=1.28 (SD 0.123) and longline baseline q=1.17 (SD 0.108). Both are now outputs, with no invented confidence limits. The cached safe_tbls.R confirms exponentiation of log-q estimates and natural-scale delta-method SDs. These rounded baseline coefficients are distinct from starting values and from the environmentally varying annual longline q surface. scripts/database/024_import_goa_cod_catchability.R records and checks the published values.

The current report explicitly states that CFSR was discontinued and no 2025 value was available. SS3 uses a zero environmental effect in that year; this model rule is now an assumption, not an observed-zero input. The 46 supplied covariates remain 1979–2024. Physical anomaly units remain unresolved.

## Published growth parameters

Table 2.6 of the January 2026 assessment reports estimates and standard deviations for beginning-year length at ages 1 and 10, the von Bertalanffy growth rate, and length-at-age standard deviation at ages 1 and 10. These five estimates are now recorded in `outputs.csv` with their reported natural-scale standard deviations. The official control specifies one von Bertalanffy growth pattern and length-at-age standard deviation as a function of mean length. These parameters describe growth; they are not direct annual weight-at-age or maturity-at-age input tables. The recovered abundance-at-age surface is now recorded, but the overall output inventory, selectivity interpretation and age-specific uncertainty remain incomplete.

## Cached fitted-object check

The cached goapcod_obj.RDS at
https://github.com/pete-hulson/goa_pcod/blob/facf41573f9a0b609d0096611bc9302aaab43abe/2025/rsch/SPoRC/goapcod_mod_files/goapcod_obj.RDS
was inspected rather than assumed to be the official 2026 fit. Its fitted
years end in 2024, and its aggregate SSB does not reproduce the current Model
24.0 report series (for example, 78,050 t versus 81,532 t in 1977 and 62,366
t versus 72,336 t in 2007). It therefore is not used to populate official
outputs. The current official source remains the pinned 2025/mgmt/24.0 model
files, saved fitted parameters, and official report. The compact ss3.rep
supports historical aggregate female SSB, age-0 recruitment and the published
M blocks, but does not contain age-specific N or F. Those surfaces come from
the reconstructed full Report.sso described above, not from plots or from this
mismatched cached fit object.

This reconstruction is not an independent model validation. N-at-age and F-at-age are now available for age-specific comparison. Any
aggregate F calculated from those surfaces must be labelled with its age range
and weighting definition; it is distinct from reported Sum Apical F. The
assessment stays partial.
