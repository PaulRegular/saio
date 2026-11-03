# Sandeel in Area 4: detailed 2025 assessment

## Identity and selected assessment

`ices_sandeel_area_4_2025` represents the official ICES `san.sa.4` SMS-effort
assessment through 2024, covering the northern/central North Sea, Divisions
4.a–b. The stable stock ID is `ices_sandeel_area_4`, taxon *Ammodytes* spp.,
basin Northeast Atlantic. The broad Charbonneau–Keith
`ICES-HAWG_dubius_NS` entry is the catalogue starting point, not a verified
one-to-one regional identity. Its ID/taxonomy remain intact; no new catalogue
identifier is invented.

HAWG 2025 version 5 was published in March 2026. Its publication date does
not make this a 2026 age-based assessment. All 32 historical recruitment and
SSB values match official SAG 19335. The native repository is pinned at
`5ccb6abb2595153a88c9c47ad628ad17f3ea3e06`, independently verified against
remote HEAD, and declares smsR `a097011f2fff959c9a263e5f6acb49795b9a53ad`.
Its CV argument names match that builder; this particular snapshot does not
have the SD-name mismatch found in the 2026 regional configurations.
The benchmark concluded in 2023 and was published in 2024.

Newer category-5 advice, SAG 21271, is recorded separately as
`ices_sandeel_area_4_2026_summary`. Its official data export supplies annual
total catches in tonnes for 1993–2025 and custom age-0/1 dredge-series values
for 2008–2025. The 33 catch and 36 index rows are recorded under the 2026
summary event, not used to fill gaps in the 2025 age-based run. The SAG export
leaves custom series units blank and does not identify their scaling, sampling
time, or likelihood role, so their values remain on an explicitly unknown
index scale.
The official HTML source-data table is used for numerical values because it
preserves more displayed precision than the accompanying SAG XML; the XML is
used to verify category, series labels, blank units and absent stock outputs.
Both files and their retrieval hashes are cached under
`source_cache/ck_ices_hawg_dubius_ns/2026_san.sa.4/`.
The separate import is reproducible from
`scripts/database/180_import_ices_sandeel_area_4_2026_summary.R`.

The SAG XML identifies category 5, names the data as coming from a previous
assessment, and reports no model name or recruitment, stock-size, or fishing-
pressure outputs. No age-structured N/F/SSB outputs are available for this
summary event; its output status is therefore not applicable. The 2025 run
remains the latest recovered detailed age-based assessment.

## Recovered inputs and outputs

The native model spans 1993–2024, ages 0–4+, two half-years, combined sexes
and one regional fishery. Age-0 recruitment enters in July; older ages
advance in January. Initial January abundance at ages 1–4+ is freely
estimated, with deterministic older-cohort survival afterward. July
recruitment has a hockey-stick expectation, fixed 44,716-tonne SSB
breakpoint and likelihood weight 0.05. The breakpoint is not the recruitment
plateau. F is proportional to seasonal standardized effort with constant
age/season coefficients, shared ages 3/4+, no time blocks or technical creep.

| Input | Native coverage and units |
|---|---|
| Catch, Table 9.5.1 | 1993–2024, ages 0–4+ in both halves; million fish; age 0 excluded from the likelihood |
| Stock/catch weights, Table 9.5.2 | First-half ages 1–4+, second-half ages 0–4+; grams/fish |
| Maturity, Table 9.5.3 | Same seasonal age grid; supplied proportions |
| M, Table 9.5.8 | Same grid; fixed long-term multispecies averages, integrated half-year hazards |
| Dredge, Table 9.5.4 | 1999–2003, ages 0–1; age 1 in 2003 missing |
| Dredge2, Table 9.5.4 | 2008–2024, ages 0–1; scaled number indices, absolute multiplier unstated |
| Effort, Tables 9.1.5–9.1.7 | Annual and half-year days for a standard 200 GT vessel; second-half header correction below |
| SAG catches | Annual all-age observed tonnes, retained separately from age-count records and predicted yield |

The detailed import contains **1,642 input rows, 20 assumptions and 768
outputs**. There are 44 survey cells but only 43 numerical values: the dash
for Dredge age 1 in 2003 remains missing. All 132 positive eligible catch
cells match the native diagnostic count. Printed zero age counts in several
years coexist with positive SAG total catches; zero-coded age data do not
establish zero total landings. No total-derived age counts replace them.

M is constant over historical years at each age/season, based on the WGSAM
2023 key run. Survival uses `exp(-F_season-M_season)` without multiplying the
integrated hazards by another half. January biology defines SSB with zero
pre-spawning mortality fractions. Annual M at ages 1–4+ is 1.35, 0.95, 0.86
and 0.80. The native population reports January ages 1–4+ together with July
age 0; derived total January abundance sums only the January states.

Outputs include N, annual and seasonal F, July recruitment, January
SSB/biomass, conditional predicted yield and arithmetic Fbar ages 1–2.
Fixed supplied M is not represented as an estimated output. SAG limits are
retained without inferring SEs or an undocumented interval construction.
No uncertainty is invented for N/F tables or derived aggregate sums.

## Effort header correction

Table 9.1.7 prints the Area 4 and Area 5r numerical columns under reversed
headers. Reassigning that pair restores **both** independent identities
`annual = first half + second half` in all 30 available historical rows,
within one rounded day. For 1996, Area 4 has annual 1,501 and first-half
535 days: the second half is 966 days, printed under Area 5r. The column
printed Area 4 is zero and cannot reconcile those totals. Reported positive
seasonal F independently supports the nonzero Area 4 second-half effort.

The numbers themselves are unchanged. Second-half records are labelled
`reconstructed_source_input`, with the column reassignment and evidence in
`transformation`. Direct annual and first-half records retain
`official_table`. Second-half rows for 2007 and 2022 are absent and are not
reconstructed from residual totals or replaced by zero. The original PDF
and paired-column checks remain cached; the exact native effort file is
still unavailable.

## Likelihood and reporting checks

Each Dredge era has separate q and log-observation SDs at ages 0 and 1.
Predictions average abundance over fractions 0.75–1 of season 2, equivalent
to annual times 0.875–1. All four survey SDs are estimated with a 0.3
lower-bound penalty. The three values printed 0.3 are boundary estimates,
not fixed supplied errors; Dredge2 age 1 is 0.8923429. The source C++ uses
these as log-residual SDs, so the report's CV label is approximate.

Catch SDs share ages 1–2 and 3–4+ within each season. With
`estCV=c(0,2,0)`, they are calculated internally from catch residuals and
mapped out of the free parameters. Recruitment SD is estimated. The catch
and index likelihood weights are one; recruitment weight is 0.05. Native
diagnostics report 50 parameters and maximum gradient 0.0002. Source R/C++
was inspected as text; no downloaded scripts were executed to fabricate a
replacement native fit.

The apparent Yield discrepancies are resolved by the native reporting
equation. `Catchtot` accumulates predicted catch only where the observed
and predicted catch cells are positive. This is **conditional predicted
yield**, distinct from unrestricted Baranov yield and observed catch times
weights. Applying that mask reconciles all 32 table values within explicit
rounding bounds. In 1996 it reduces roughly 99,622 tonnes of unrestricted
prediction to about 41,708 tonnes, consistent with the reported 41,518
after rounding. It also explains zero reported Yield in years with some
positive F but no positive age-count observations.

Annual F sums seasonal F within 0.000895. Older-cohort log survival agrees
with N, annual F and summed M within 0.007373, consistent with two-decimal
M rounding. January biomass and SSB are checked against N and biology with
explicit rounding bounds. Annual F is exactly zero in 2009 and 2024;
finite log-F states cannot reproduce these structural zeros.

The summary's future recruitment is the full-history geometric mean
(1993–2024: 49,075,026 thousand fish), whereas the forecast explicitly uses
2014–2023 (53,694,267 in SAG; 53,694,268 from rounded table values). These
are future assumptions, not historical observations. Stale year/value
references in the narrative do not override the matching numerical tables
and configuration.

## Remaining source gaps

The native `4` data folder, unrounded arrays, exact zero-catch flags and
fitted `sas.rds` are absent from the pinned public repository. The declared
software is compatible with the configuration, but the actual production
object/revision is not independently recovered. All three completeness
statuses remain **partial**. The newer summary's numerical extraction is
not claimed complete. Regional recovery does not silently resolve the broad
legacy catalogue entry or complete every North Sea sandeel unit.

Cached originals, hashes, URLs, dates and revisions are recorded under
`source_cache/ck_ices_hawg_dubius_ns/2025_san.sa.4/`. The yield and effort
audits are numerical checks against the source equations/independent
tables; they do not adjust observations to improve tinyAM agreement.

## Annual translation and fitting outcome

The recipe uses January ages 1–4+ in 1993–2024, free initial abundance,
deterministic older-cohort survival, IID age-1 recruitment and independent
random-walk annual F increments. It sums seasonal M hazards and catch
numbers, converts million to thousand fish, and uses January biology with
spawning time zero. This preserves annual older-cohort survival for given
annual F/M, but simplifies the within-year catch/survey equations and does
not reproduce effort-proportional/shared F or exact structural zeros.
The survey SD floor and profiled seasonal catch-SD construction are not
reproduced. No fitted values alter source observations.

The juvenile survey is retained through an observation-mean re-expression,
without changing any index values. For July recruitment R0, constant supplied
second-half M0 and zero age-0 F, define

`A(M0) = mean(exp(-M0*t)), t in [0.75, 1]`.

The source prediction is `q0 * R0 * A(M0)`. Following January abundance is
`N1 = R0 * exp(-M0)`, so the same prediction is `q_star * N1`, where
`q_star = q0 * exp(M0) * A(M0)`. Because M0 is constant and each era/age has
its own free q, this absorbs a constant into q and preserves the conditional
log-observation likelihood exactly. It does not require source fitted N/F/q
to transform observations. Tests verify both expected values and likelihoods.

Original age-0 observations are linked to the next January's age-1 state at
model time zero. Their actual survey year and age remain `source_year` and
`source_age` in the data/dashboard. Original age-1 observations retain their
year at autumn midpoint 0.9375. Four series preserve era/source-age q and SD
sharing. There are 42 numerical observations: only the final 2024 juvenile
index is omitted because its January survivor state is outside the fitted
window; the original missing 2003 age-1 cell is not filled. This mapping is
conditional on constant M0 and zero age-0 F and is guarded accordingly.
It is **not** applied to reference recruitment: comparisons still use official
January N1 in the same calendar year, with native July recruitment separate.

Catch reporting uses observed-count-weighted seasonal weights for positive
cells and equal-duration weights for zero cells, only for predicted-yield
reporting. Zero-coded age arrays with positive SAG landings do not become
zero observed biomass: those six annual biomass observations remain missing.
Verified zero-landings years 2009/2024 retain zero. Source conditional Yield
is not compared as though it were unrestricted tinyAM yield.

Both package-default and the single aligned source-start attempt failed
with **NA/NaN gradient evaluation**, taking about 3.34 seconds together in the
earlier attempt. A recheck on 2026-10-26 against database revision `b73231f`
failed in both attempts again: 1.47 seconds from package defaults and 2.02
seconds from the aligned source start. Both retained missing optimizer codes,
objectives and gradients, and neither produced a successful `sdreport`.
No optimizer result, final objective/gradient, usable sdreport or `tam_fit`
object was returned. Source starts used aligned January N and positive
annual F cells; unrepresentable zero F retained package log-F starts of zero
(F = 1). The data and settings were identical between attempts. No further
starting-value or assumption tuning was used to force convergence.

The exact cause of the non-finite gradient has not been isolated. Missing
support for the source's structural-zero/shared F representation and survey
SD floor are documented differences, not a demonstrated causal diagnosis.
This case is a verified import and tested runnable translation with actual
failed fitting attempts, **not a successful replication**. SSB, recruitment,
N/F-at-age and abundance agreement statistics are unavailable, not passes;
fixed M is an input consistency check, not estimated-M agreement.

The local `results/cache/ices_sandeel_area_4_2025/dashboard_official_only.html`
shows recovered Official outputs and translated inputs, explicitly without
tinyAM estimates. It supplies no invented parameters, standard errors or
optimizer. The missing yield comparison is labelled unavailable. Two narrow
reporting fixes permit this: a missing-yield guard in the dashboard template,
and complete projection/missing-q metadata for standalone references.
Cached initialization attempts, failure diagnostics, the reference object
and original-to-model index mapping remain available. No core mathematics
or public API was changed and shared aggregate tables were not regenerated.

## Validation

The four regional source checks, four translation checks, reference alignment,
plus-group handling and default-first initialization checks all passed (11
assessment-analysis scripts). The dashboard tests passed 203 assertions;
the full package suite passed 2,936 assertions with no failures, warnings or
skips. A package-only `R CMD check --no-manual --no-tests` returned Status: OK;
the complete package tests were run separately. The full assessment-analysis
suite was not repeated for this milestone; its previously documented unrelated
failures remain outside this source/translation review. The actual Official-only
Area 4 dashboard rendered successfully. No successful tinyAM fit or agreement
statistics are claimed.
## Sources

- [HAWG 2025, version 5](https://doi.org/10.17895/ices.pub.28389008.v5), section 10.5 and Tables 9.1.5–9.1.7, 9.5.1–9.5.12.
- [Official 2025 advice](https://asd.ices.dk/viewAdvice/3832), [SAG 19335](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19335) and separate [2026 SAG 21271](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21271).
- [SAG 21271 machine-readable XML](https://sag.ices.dk/SAG_API/StockXmlDownload/21271), cached with the source page and checksums under `source_cache/ck_ices_hawg_dubius_ns/2026_san.sa.4/`.
- [Pinned production repository](https://github.com/ices-advice/2025_san.sa.4/tree/5ccb6abb2595153a88c9c47ad628ad17f3ea3e06).
- [Declared smsR source](https://github.com/nissandjac/smsR/tree/a097011f2fff959c9a263e5f6acb49795b9a53ad), particularly survey SDs, catch SD profiling and `Catchtot`.
- [Sandeel benchmark, published 2024](https://doi.org/10.17895/ices.pub.21581151.v2).
