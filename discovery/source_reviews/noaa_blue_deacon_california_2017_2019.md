# California Blue and Deacon Rockfish — 2017 assessment and 2019 catch update

## Unit and assessment history

NOAA stock 14821 is the California Blue and Deacon Rockfish complex, covering U.S. waters from Point Conception to the California–Oregon border. The assessment combines *Sebastes mystinus* and *S. diaconus*. NOAA's 2026 quarterly stock-status table still lists the complex. A PFMC 2026 assessment-prioritization document also describes a 2025 change to the federal groundfish-management boundary for California. Those sources leave the current management treatment unclear, so the database keeps the documented NOAA unit and flags the boundary question rather than assuming the unit disappeared.

The latest detailed population-model fit located is the 2017 Stock Synthesis assessment (3.30.03.07). The official 2017 STAR report documents its review. PFMC's 2019 report is a catch update based on that model, not a new benchmark fit; it updates removals and reports population outputs through 2019. No run-matched 2019 native model archive was located. The database therefore keeps separate 2017 benchmark and 2019 catch-update assessment records, with the 2019 event marked current.

The native 2017 `B17.dat` has a data terminal year of 2016, whereas the report's annual population tables include 2017. The 2017 output row is retained and labeled as an estimate beyond the native input terminal year. The assessment covers one area, two sexes, ages 0–35, and treats age 35 as the accumulator.

## Cached sources

The 2017 report, California native Stock Synthesis archive, STAR report, 2019 catch-update report, current NOAA stock-status table, and PFMC 2026 prioritization document are cached under `source_cache/discovery_noaa_blue_deacon_2017/`. The run-specific files, URLs, retrieval dates, sizes, and SHA-256 checksums are listed in `provenance/discovery_noaa_blue_deacon_california_2017/sources.csv`. The text files are local extractions from the cached PDFs used to make the transcriptions reproducible.

The public California archive includes `B17.dat`, `B17.ctl`, `starter.ss`, `forecast.ss`, and `ss.exe`, but no `Report.sso`. It therefore supplies model inputs and setup, not a fitted object or full age-specific output surfaces.

## Inputs and model settings recovered

The native file contains 641 annual aggregate catch observations across eight fleets for 1900–2016. The catches use biomass units. The source `catch_se` field is retained as supplied, but it is not treated as an estimated catch-observation SD. These are total fleet catches, not catch-at-age.

Five aggregate index series contain 69 observations. They include fishery-dependent CPUE and survey series; all use number-index units, lognormal errors, and month-7 timing (represented as 0.5 of the annual step). They are not age-specific indices. A separate fleet-14 synthetic SSB constraint uses Stock Synthesis special index unit code 30 and is disabled in the base likelihood (`lambda = 0`); it is retained as a scenario input.

The archive contains 162 length-composition samples and 136 age-composition rows. These include 126 conditional age-at-length rows and 10 marginal diagnostic rows whose negative fleet codes exclude them from the likelihood. Native frequency cells and sample sizes are retained by sex, age, length bin, fleet, year, partition, and age-error code. They are compositions, not catch-at-age or survey index-at-age. Age 35 is the accumulator. Two age-error definitions are retained; the age-composition rows refer to definition 1.

The 2017 report's Table 51 reports estimated age-invariant female M and an estimated male log-M offset, along with estimates and standard errors for five extra index SD parameters. These parameter estimates are kept as outputs, not reclassified as fixed biological inputs. The model uses sex-specific growth and length–weight relationships to generate weight-at-age and length-based maturity/fecundity. No numeric weight-at-age or maturity-at-age input surface is tabulated in the reviewed sources.

For the 2019 catch update, Table a provides six source categories of removals for 2010–2018; the 2017 and 2018 catch values were fixed by the PFMC Groundfish Management Team. These are stored as aggregate removals by source, not split into age-specific catches. The report states that 2017–2019 recruitment deviations were fixed at zero. No observed 2019 catch value is substituted from a projection.

## Outputs recovered and source discrepancy

The 2017 report's Table 55 provides aggregate time series for total biomass, egg-based spawning output, depletion, age-0 recruits, total catch, relative exploitation, and SPR for 1900–2017. Table ES19 gives higher-precision recent values for biomass, egg-based spawning output, recruitment, depletion, landings, removals, exploitation, and a source-defined SPR ratio for 2005–2017, with approximate 95% asymptotic intervals for spawning output, recruitment, and depletion. Spawning output is in millions of eggs, not mass-based SSB.

The 2019 update's Tables b–d report updated spawning output, depletion, recruitment, an SPR-to-target ratio, and exploitation through 2019, with approximate 95% intervals. The source-defined 2017 and 2019 SPR ratios have different labels and are stored as separate measures.

The two 2017 report tables give materially different values for their recruitment-like quantities. For 2005, Table 55's `Age-0 Recruits` value is 2,807 thousand fish, while Table ES19's `Recruitment` is 1,623 thousand fish; the discrepancy continues in later years. Both source columns are preserved separately as `age0_recruitment` and `recruitment`. The reviewed report does not explain whether these use different timing or definitions, so they are not combined or silently reconciled.

No reported N-at-age or F-at-age series was located. The 2017 table outputs and 2019 update contain no annual M-at-age surface. Reported annual output intervals are available for selected aggregate indicators only.

## Completeness

Both records are partial. The 2017 benchmark has substantial native input coverage and aggregate outputs, but no catch-at-age, age-specific indices, numeric weight/maturity-at-age surfaces, fitted N/F-at-age, or broad output uncertainty. The 2019 catch update has its update removals and selected aggregate output tables, but no new native model files or complete run-specific likelihood inputs. No missing observations or scaling factors have been invented.
