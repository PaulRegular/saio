# Northeast Atlantic blue whiting source review

## Assessment selected

The current assessment is ICES stock `whb.27.1-91214`, blue whiting
(*Micromesistius poutassou*) in Subareas 1–9, 12, and 14. The 2026 assessment
was applied to advice published on 30 September 2026. The numerical source is
the official SAM fit `BW-2026`, retrieved with
`stockassessment::fitfromweb()`. It covers 1981–2026 and ages 1–10+, with
recruitment at age 1 and Fbar over ages 3–7.

The fit is consistent with the 2026 ICES advice and its reported 2025
assessment estimates. The fit reports 2025 recruitment of 38,731,655 thousand,
SSB of 5,087,028 tonnes, and Fbar of 0.508. The native fit estimates 2026
recruitment at 24,735,494 thousand and SSB at 4,474,452 tonnes. For the advice
forecast, the 2026 recruitment estimate was replaced with 39,366,774 thousand
(the 75th percentile of the 1996–2025 geometric mean); the advice's 2026 SSB
is consequently 4,546,442 tonnes. The forecast recruitment adjustment is
recorded as an advice assumption and is not substituted for the model's fitted
output.

## Inputs and model structure

The native object contains one aggregate commercial catch series in
numbers-at-age for 1981–2026 (ages 1–10+), and the International Blue Whiting
Spawning Survey (IBWSS) index in numbers-at-age for 2004–2026 (ages 1–8).
There are no IBWSS observations in 2010 or 2020. Catch numbers are in thousands
of fish; the published survey table and model values are in millions of fish.
The IBWSS timing is 0.245 of the year. The model also supplies annual stock
weight and catch-weight surfaces, a time-invariant maturity ogive, and fixed
natural mortality of 0.2 per year at all modeled ages.

The official SAM fit uses a random-walk F process with age-correlated
increments and one shared F process variance. Fishing states are represented
separately for ages 1–9; the 10+ state shares age 9. N-process variance is
separate for age 1 and shared across ages 2–10. Catch and IBWSS observations
use lognormal likelihoods with autoregressive correlation across ages. Catch
observation variances are grouped as age 1, age 2, ages 3–8, and ages 9–10;
IBWSS variances are grouped as age 1, age 2, age 3, ages 4–6, and ages 7–8.
IBWSS catchability is grouped by ages 1, 2, 3, 4, and 5–8; no q-power term is
active.

The native fit converged (optimizer code 0), and its reported Hessian is
positive definite. The database records age-specific N, F, and fixed M,
SSB, total biomass, recruitment, Fbar, q, and fitted observation predictions. The reported
at-age N and F standard errors are conditional log-state errors converted by
the delta method; the source does not provide matching at-age 95% intervals.
Aggregate table intervals are retained as supplied by `stockassessment`.

## Sources and cache

- [2026 ICES advice and assessment summary](https://www.hafogvatn.is/static/extras/images/34_whb_2026_1_advice_en.html)
- [2026 MFRI technical report](https://www.hafogvatn.is/static/extras/images/34_whb_2026_1_techreport_en.html)
- [BW-2026 native SAM model object](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/BW-2026/run/model.RData)
- [WGWIDE 2025 blue whiting chapter](https://www.hav.fo/wp-content/uploads/2025/10/WGWIDE-2025_02-blue-whiting.pdf), including Tables 2.3.5.1 and 2.3.6.1.1.

The ignored local cache contains the native model object and a copy in RDS
format, the 2026 advice page, and the 2025 WGWIDE chapter. The 2026 technical
report is publicly listed and referenced above, but its large embedded HTML
page could not be downloaded in this environment because the local TLS
connection failed. Numerical inputs and configuration in the database are
therefore taken from the native official model object; the report is not used
as a substitute for those values.

## Initial abundance

The cached official SAM fit has `initState = 0` and no `initN` parameters.
The translation uses `init = "latent"`: older first-year log-abundances are
integrated without an initial density. First-year recruitment remains an
estimated fixed effect, so this is not complete SAM initial-state equivalence.
