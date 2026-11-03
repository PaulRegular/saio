# Baltic plaice in ICES Subdivisions 21-32: WGBFAS 2026

## Assessment and source set

ICES combined the former Subdivisions 21-23 and 24-32 plaice assessment units after the WKBPLAICE benchmark. WGBFAS 2026 reports the current SAM assessment for ple.27.21-32. The native run is ple.27.21.32_WGBFAS_2026_SA; its model and data objects, input files, and supporting code are cached locally in source_cache/ices_plaice_baltic_21_32_2026/official_SA/. The manifest records the retrieval date, URLs, file sizes, and SHA-256 hashes.

- WGBFAS 2026 report: <https://literatur.thuenen.de/digbib_extern/dn071152.pdf>
- WKBPLAICE benchmark: <https://literatur.thuenen.de/digbib_extern/dn069680.pdf>
- ICES 2026 assessment data: <https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22470>
- Native SAM run: <https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.21.32_WGBFAS_2026_SA/>

The combined assessment represents the new 21-32 management unit, not either historical component alone. The two prior Charbonneau-Keith stock rows remain in the metadata table and are not treated as separate current assessment cases here.

## Inputs and assumptions

The cached run/data.RData and run/model.RData objects match years 2002-2025, ages 1-7+, fleet counts of 161 catch, 168 Q1 survey, and 161 Q4 survey observations, and sampling times 0, 0.1507111, and 0.8173179. The native SAM fit reports optimizer convergence code 0. The input data script and model configuration are retained with the source cache.

- Catch is total catch-at-age, including landings and discards, divided by 1,000 and stored in thousand fish. The separate landings fraction and landings/discard weights are also retained.
- Survey observations are age-specific relative indices. Each survey series is normalized to mean 1; no physical abundance multiplier is stated.
- Ages 7 and older are combined to the official 7+ group using the source data script's weighting rules.
- Survey timing is recorded from the SAM object: Q1 at 0.1507111 and Q4 at 0.8173179 of the year.
- Survey precision weights are copied from the per-observation fit$data$weight. The source code derives these from inverse squared CVs. They are relative weights, not fixed variances (fixVarToWeight=0).
- Recruitment follows the SAM random-walk model. N process variance is separate for age 1 and shared for ages 2-7.
- F has an AR(1) age-correlation structure, one shared process variance, separate states at ages 1-5, and a shared state at ages 6-7.
- M is fixed, age- and year-varying Gislason mortality with a five-year sliding average. The source supplies annual maturity ogives smoothed over a five-year sliding window.
- Stock weights vary annually and are used in an estimated SAM weight process. tinyAM uses the supplied stock weights as fixed values.

The WGBFAS report defines Fbar over ages 3-5. The cached SAM configuration has fbarRange=3:6; this mismatch is recorded rather than silently changing the source object. The assessment table values are used for reported SSB, recruitment, Fbar, N-at-age, and F-at-age. The 2025 table values are retained as published, although the report does not make clear in these tables whether every 2025 age-specific F value is a fitted estimate or a forecast.

## Reported outputs and unresolved differences

WGBFAS 2026 Tables 5.2.5-5.2.7 provide annual recruitment, SSB, Fbar, N-at-age, and F-at-age for 2002-2025. The 2025 point values are recruitment 8,796,107 thousand fish, SSB 96,773 tonnes, and Fbar(3-5) 0.020; the aggregate table supplies 95% confidence limits for recruitment, SSB, and Fbar. Age-specific uncertainty is not tabulated. Total abundance is derived as the sum of the published N-at-age medians and has no uncertainty.

The downloaded SAM object gives different direct point estimates in recent years (for example, 2025 age-1 N is 14,910,084 thousand fish and direct Fbar is for ages 3-6). The precise reason for the difference from the report's published medians and Fbar definition is unresolved. Therefore, assessment inputs are complete for the pinned native run, but assumptions and outputs remain partial. The canonical comparison values use the WGBFAS tables; fitted observation predictions are separately labeled as coming from the downloaded SAM object. Do not interpret this record as a numerically exact reproduction of every official report value.

## Native catchability outputs

The cached fitted object also reports nine native q estimates. Q1 shares q across ages 3-5, while Q4 shares q across ages 4-7+, represented by model ages 4-7; Q1 ages 1, 2, 6, and 7+ and Q4 ages 1, 2, and 3 each have separate parameters. The last modeled age is 7+, as in the population outputs. The q values are exp(logFpar). Their natural-scale standard errors use the delta method, and the limits are 95% Wald intervals calculated on the log-q scale. The physical survey-index multiplier is unresolved, so the q unit is retained as native index scale per thousand fish with that limitation stated.

These fitted q rows are now included in outputs.csv as native model outputs. They do not resolve the differences between recent fitted SAM population estimates and the WGBFAS report tables, so outputs_status remains partial.

## tinyAM translation

The translation retains the 2002-2025, ages 1-7+ observation grid; Q1 and Q4 timing; source q and observation-variance sharing; fixed time-varying M; and source maturity and weight surfaces. It uses random-walk recruitment, IID N-process errors, an AR(1) F process, exponential initial abundance, and the official Fbar ages 3-5.

The translation cannot reproduce the full SAM state-space structure, age-correlated F random walk, estimated stock-weight process, or all source likelihood details. These are stated in the stock recipe and comparison dashboard. No observations are adjusted to improve agreement, and no explicit starting values are used.
