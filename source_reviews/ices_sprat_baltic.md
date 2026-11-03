# Baltic sprat source review

## Official assessment

The current detailed official assessment is the 2026 ICES assessment of sprat in subdivisions 22–32, stock `spr.27.22-32`. The WGBFAS 2026 report presents the complete SAM input tables, configuration, and numerical population outputs in Chapter 7. The full report is cached locally under `source_cache/ices_sprat_baltic_2026/`.

Sources:

- [WGBFAS 2026 report](https://doi.org/10.17895/ices.pub.32455056), Chapter 7, Tables 7.6–7.19.
- [ICES stock assessment data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22378), assessment key 22378.

## Inputs and model structure

| Component | Official assessment |
|---|---|
| Years and ages | Catch-at-age, weights, and natural mortality cover 1974–2025. The model uses ages 1–8, with age 8 as the plus group. Recruitment is at age 1. Reported population outputs extend into the 2026 intermediate year. |
| N | Recruitment follows a random walk. SAM has a separate log-N process variance for age 1 and a shared variance for ages 2–8. |
| F | SAM uses an age-correlated AR(1) process; the model's final F age shares the preceding age state. Fbar is ages 3–5. |
| M | Natural mortality varies by year and age due to cod predation. The 2025 values are assumed equal to 2024. |
| Catch | One aggregate catch-at-age series is reported in thousands of fish. |
| Index | Four tuning fleets are used: October BIAS for subdivisions 22–29 and 32 from 2000 onward; an earlier October BIAS series for subdivisions 22–29; May BASS for subdivisions 24–26 and 28; and an October age-0 acoustic series shifted to age 1 in the following year. |
| Weights and maturity | Catch and stock weights are assumed equal and vary by year and age. Maturity is fixed over time at 0.17, 0.93, and 1.0 for ages 1, 2, and 3–8. The assessment assigns 40% of both F and M to the period before spawning. |

The report excludes low-coverage BIAS observations in 1993, 1995, and 1997 and the 2016 BASS survey. It also excludes overlapping early BIAS years from the earlier fleet. Those observations are left absent from the numerical input rows. Survey timing is represented as 0.8 for October and 0.375 for May; these are month-based approximations, not exact sampling dates.

The age-0 acoustic series is reported already shifted to the following year as an age-1 index. Its table includes 2026 to estimate the intermediate-year age-1 abundance; this does not extend the catch series beyond 2025. The 2026 SSB is an intermediate-year estimate and uses an F assumption; it is not a full catch-data year.

## Database coverage and limits

The canonical record contains catch-at-age, catch and stock weight-at-age, annual M-at-age, static maturity, four age-specific index fleets, SAM process and sharing settings, and reported N, F, recruitment, SSB, and Fbar outputs. Total abundance is derived by summing the reported N-at-age values for ages 1-8, with age 8 representing 8+; its values inherit the report's rounding and have no separate uncertainty. The WGBFAS report does not tabulate fitted q values, fitted observation predictions, or age-specific uncertainty for N and F. Output completeness therefore remains partial. The low/high bounds reported for recruitment, SSB, and Fbar are retained as published; the chapter does not identify their confidence level.


## Translation review — 2026-10-17

Applied the documented 40% pre-spawning fraction for both F and M. Common-definition SSB now uses official N/F/M with the translated biology; native SSB/intervals remain separate. This corrects a biological definition, so its statistics must not be presented as a like-for-like improvement over the previous January-1 comparison.
