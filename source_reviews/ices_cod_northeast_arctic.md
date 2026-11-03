# Northeast Arctic cod: 2026 source review

Completeness remains partial; verified source findings and the remaining gaps are summarized below.

## Identity and source trail

Charbonneau–Keith identifier: `ICES-AFWG_NEA1-2_Gadus_morhua`.
Current assessment authority is JRN-AFWG (IMR/VNIRO), not ICES. The official
2026 advice explicitly identifies the assessment as conducted outside ICES,
following the ICES 2021 benchmark methodology.

- Detailed report: https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5
- Advice published 26 June 2026: https://www.hi.no/en/hi/nettrapporter/imr-vniro-en-2026-1
- Candidate native run: https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NEAcod_2026_final/

The detailed PDF, HTML, advice, run directory listings, fitted `model.RData`,
configuration, and all twelve published `.dat` inputs are cached in the ignored
`source_cache/ices_cod_northeast_arctic_2026/` directory. The fit is loaded for
inspection without executing its saved objective function or modifying it.

## Native model inventory

SAM version 0.12.0; saved RemoteSha `1cc464b80f6f`. Model years 1946–2026;
ages 3–15, with terminal plus group. One residual-catch fleet and five indices.
The native observation array has 2,710 slots, of which 2,377 contain fitted observations: 1,028 catch and 1,349 index observations. Missing slots are retained in the cached export and must not be counted as observations.

| Native index | Fitted years | Sampling fraction | Observations |
|---|---|---:|---:|
| FLT15_I:NorBarTrSur_I | 1981–2013 | 0.137 | 290 |
| FLT15_II:NorBarTrSur_II | 2014–2026 | 0.137 | 130 |
| FLT16:NorBarLofAcSur | 1985–2026 | 0.1725 | 403 |
| FLT18:RusSweptArea | 1982–2017 | 0.95 | 336 |
| FLT007:Ecosystem | 2004–2025 | 0.7 | 190 |

Catch observations end in 2025; fitted survey observations extend through 2026.
Original inputs include stock/catch weights, maturity, natural mortality,
landings fractions and pre-spawning F/M fractions. M includes externally
calculated cannibalism mortality; it is fixed within the saved SAM fit, rather
than an internally estimated mortality process.

The cached fit contains survey observations and corresponding fitted values
only through the source terminal age group 12+; it has no survey rows at ages
13–15 to add to the database. It does contain separate population, catch, and
fishing-mortality outputs at ages 13–15. Keep the observed survey series as
ages 3–12+, and retain the model's age-3–15 structure for the other inputs and
outputs. The 12+ index cannot be split into ages 13–15 from this fit without
inventing age-specific observations.

## Official-run evidence and remaining checks

The saved fit uses the prediction–observation-variance link added in 2026,
matching section 3.4.1 of the report. Its 2025 Fbar is 0.548025 and 2026 SSB is
338,013.7 tonnes, matching the report's rounded 0.548 and 338 kt. Optimizer
convergence code is zero and the saved sdreport Hessian indicator is positive.

Fitted SAM age-3 recruitment in 2026 is 132.286 million; the advice instead
uses a separate RCT3 forecast of 243 million. Do not substitute the forecast
for fitted recruitment. The report's 2026 short-term-prediction biomass is
1,069 kt whereas the native fitted TSB is 1,049.567 kt; verify the reporting
definitions and input substitutions before comparing these quantities.

All 320 recruitment, TSB, SSB and Fbar values for 1946–2025 match table 3.18 within published rounding. This establishes trajectory-level agreement with the official report, rather than relying on the run name or two terminal values.

The native N/F/M surfaces, benchmark configuration, source timing and missing-value conventions have now been checked. The fitted object supplies diagonal conditional covariance for its random N/F states; fixed-effect uncertainty and some survey-unit interpretations remain unresolved.

## Canonical extraction and validation

8,682 input rows, 4,843 output rows and 41 assumptions are represented. Original SAM log-observations are exponentiated to their native scale; missing slots are omitted rather than filled. Fixed final M includes externally iterated cannibalism mortality. N and summary quantities extend through fitted survey year 2026; historical F/Fbar end in catch year 2025. Predictions use the corresponding native observation rows. Available summary intervals are preserved; log-scale SEs are not placed in the canonical natural-scale SE field.

Structural validation and scripts/database/007_validate_northeast_arctic_cod.R passed. Source exporters and report crosschecks are retained in the cache. No core package mathematics changed.

## Benchmark follow-up

WKBARFAR 2021 sections 2.3.1–2.3.2 confirm survey terminal age 12+, the 2014 winter-trawl split with separate q and shared error parameters, independent F innovations, and deliberate exclusion of suspicious historical catch values of one. The 2026 report section 3.2 confirms that the Russian survey was discontinued after 2017; empty later slots are not observations. The prediction–variance link was tested but excluded at the 2021 benchmark, then adopted in 2026. These are distinct official configurations.

## Spawning inputs and catchability uncertainty

The official fit has no logQpow parameters and all keyQpow entries are -1, confirming no density-dependent power. Fifty survey-age q values now represent 45 unique logFpar parameters across the five index series; ages 11 and 12 share q within each series. Values come directly from native fixed effects. Reported SEs are natural-scale delta-method approximations and intervals are 95% log-Wald intervals; neither log SEs nor arbitrary units are substituted.

Both propF and propM full matrices (81 years by 13 ages) are now retained as biological inputs, adding 2,106 source cells. All are zero, consistent with the earlier assumption notes. The stock-specific validator confirms the zero spawning fractions, q age sharing and uncertainty transformation. Coverage is 8,682 inputs, 4,843 outputs and 41 assumptions. Completeness remains partial because source units and remaining statistical-interpretation details are unresolved; initial-state semantics are documented below.

Conditional uncertainty is now recorded for all 1,053 N-at-age and 1,040 F-at-age outputs. The fitted random-effect vector confirms the covariance ordering for `logN` and `logF`; variances come from the diagonal of `fit$sdrep$diag.cov.random`. Standard errors are converted to the natural state scale with the delta method, and limits are 95% log-Wald intervals. They condition on fitted fixed parameters and exclude fixed-effect and covariance uncertainty, so they are not fully marginal. F ages 14 and 15 share the same fitted state and therefore receive identical conditional intervals. The output-completeness status remains partial.
## Initial-state semantics resolved

Both native initN/initF vectors are empty and initState=0. The official SAM revision's n.hpp and f.hpp evaluate ordinary process transitions from the second modeled year onward, with no explicit density for the first logN/logF state. Those first-year states remain latent random effects in the Laplace fit. A broad first-state normal prior is added only when calculating observation residuals; it must not be described as a regular assessment prior. The native configuration checks pass. This resolves the earlier initial-state gap without changing the fitted object or model mathematics.

Exact source files:
https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/n.hpp
https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/f.hpp

## Initial abundance

The cached official SAM fit has `initState = 0` and no `initN` parameters.
The translation retains `init = "free"`, estimating older initial abundances
as fixed effects. This differs from integrating the source initial states
without an initial density; first-year recruitment remains an estimated fixed
effect in tinyAM.
