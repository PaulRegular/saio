# Sandeel in Area 2r: HAWG 2026

## Identity and sources

`ices_sandeel_area_2r_2026` is the official ICES `san.sa.2r` assessment through
2025, covering Skagerrak and the central/southern North Sea, Divisions 4.b–c
and Subdivision 20. Its stable stock ID is `ices_sandeel_area_2r`, taxon
*Ammodytes* spp., basin Northeast Atlantic.

The broad Charbonneau–Keith `ICES-HAWG_dubius_NS` record does not identify
one current regional unit. Its original stock ID, taxon and catalogue ID
remain intact. This regional stock has no invented catalogue identifier;
neither Area 1r nor Area 2r completes every North Sea sandeel unit.

The official 2026 advice entry 4046 identifies SAG key 21281. All 43 historical
recruitment and SSB points match HAWG Tables 9.3.9–9.3.10. The production
repository HEAD is pinned at `7a77f3b7a2e2fc2cb6609bbe234f8de9b97dac3f`,
verified against the remote. Its software bibliography specifies smsR
`a097011f2fff959c9a263e5f6acb49795b9a53ad`. Native R/C++ files were inspected
as text, not executed. The benchmark meetings concluded in 2023, with the
report published in 2024; `framework_year` records 2023.

## Native model and recovered records

The model has 1983–2025, ages 0–4+, two half-year seasons, one combined-sex
regional population and one commercial fishery. Recruitment enters in July;
older ages advance in January. Initial January abundance at ages 1–4+ is
free, and older-cohort survival is deterministic under seasonal F+M.
July recruitment has a hockey-stick expectation, fixed 18,949-tonne
breakpoint, and likelihood weight 0.05. Native code confirms that the
breakpoint is not the recruitment plateau, despite a shorthand comment.

F is proportional to standardized seasonal effort with age/season
coefficients in blocks 1983–1998, 1999–2004, 2005–2009 and 2010–2025.
Ages 3 and 4+ share selectivity. `isFseason=c(1,0)` fixes a normalization;
it does not turn off second-half F in all years. Fixed M uses long-term
multispecies averages from the WGSAM 2023 key run and is constant over time
at each age and season. The source survival equation uses integrated
half-year hazards directly, without another factor of one-half.

| Input | Native coverage and units |
|---|---|
| Catch, Table 9.3.1 | 1983–2025, ages 0–4+ in both half-years; million fish; source likelihood excludes age 0 |
| Stock/catch weights, Table 9.3.2 | First-half ages 1–4+, second-half ages 0–4+; grams/fish; source uses the same weight for stock and catch |
| Maturity, Table 9.3.3 | The same seasonal age grid; proportions |
| M, Table 9.3.8 | The same seasonal age grid; integrated half-year hazards |
| Dredge, Table 9.3.4 | 2004–2025, ages 0–1; scaled number index, absolute multiplier unstated |
| Effort, Tables 9.1.5–9.1.7 | Annual and half-year fishing days for a standard 200 GT vessel; Area 2r column only |
| SAG catches | Annual all-age observed tonnes; separate from tabled model-predicted Yield |

The import adds **2,192 inputs, 17 assumptions and 1,032 outputs**. Outputs
include January N at ages 1–4+, July age-0 recruitment, annual and seasonal
F, January SSB/biomass, predicted yield and arithmetic Fbar ages 1–2.
Derived January abundance sums ages 1–4+ only. July recruits must not be
added to that simultaneous population. Supplied fixed M is not represented
as an estimated output.

Dredge predictions average abundance over fractions 0.75–1 of season 2,
equivalent to annual interval 0.875–1. A midpoint is an approximation, not
the exact source timing. Constant q and observation SD are separate at ages
0 and 1. No commercial tuning series is active. Catch observation SDs share
ages 1–2 and 3–4+ within each season.

SAG limits for SSB, recruitment and Fbar are retained. Their level and
construction are not labelled on the source data page, so no SE is inferred.
The numerical N/F tables do not supply uncertainty. Source SSB uses January
biology and zero pre-spawning F/M fractions in the pinned configuration.

## Verification and unresolved details

Native configuration and the reported 44 survey observations support two
Dredge ages in 2004–2025. Narrative section 10.3.5.2 instead says 2010.
The full published series is retained, with the conflict recorded; no years
are silently deleted. The catch table has 321 positive eligible cells,
whereas Table 9.3.5 reports 324 observations. Rounded zeros or unavailable
selection flags could explain this, but exact cells cannot be resolved.
Neither zeros nor positive values are altered to force agreement.

Second-half effort rows for 2007 and 2022 are absent from the published
table. They remain missing; complete direct annual totals and first-half
values are retained separately. Annual effort is not added to its seasonal
components. No first-half age-0 biology is invented.

Older-cohort survival agrees with annual F and summed seasonal M to their
printed precision. January biomass and SSB agree with N, weights and maturity
within explicit rounding bounds. Tabled Yield matches seasonal Baranov
predictions within rounding bounds and differs from observed catch times
weights. The package's `getSummary()` helper instead calls observed
`getYield()`; its generic field name alone does not establish the meaning of
this published table. Reported Yield is retained as predicted catch based on
the numerical equation check, without substituting another getter's output.

The summary's 2026 recruitment is the full-history geometric mean
(22,706,561 thousand fish). The forecast explicitly uses 2015–2024
(12,832,431 in the input table and 12,832,432 in SAG). Pinned `getSummary()`,
`getForecastTable()` and `report.R` explain the different averaging windows.
These are future assumptions, not contradictory historical observations.
The source narrative also describes 2025 SSB as above Bpa, whereas its
numerical 25,786 tonnes is below Bpa = 27,757 tonnes; numerical report/SAG
values are preserved.

The native `2r` data folder, unrounded arrays, zero-catch flags and fitted
`sas.rds` are absent from the public pinned repository. All three canonical
completeness statuses remain **partial**. Detailed report/configuration
coverage supports a limited annual translation, not exact reconstruction
of the native likelihood.

The published configuration supplies `surveySD`, `catchSD` and `estSD`,
but the declared pinned builder accepts `surveyCV`, `catchCV` and `estCV`
without those aliases. Read-only inspection confirms that these public
snapshots are not directly compatible. The exact production builder revision
remains unverified, so `model_version` identifies a **declared** version.
No aliases, native fitted objects or altered source values are invented to
conceal this reproducibility gap. The official output series remain anchored
by report/SAG agreement and independent numerical equation checks.

Source files, manifests and verification logs are cached in
`source_cache/ck_ices_hawg_dubius_ns/2026_san.sa.2r/`. The manifest references
the shared full HAWG report, benchmark and pinned software locally rather
than duplicating large files. Importer checks and focused tests protect
dimensions, units, mixed state dates, survey coverage, source gaps, yield
meaning and future recruitment definitions.

## Yield reporting clarification

The declared C++ `Catchtot` reporting loop sums predictions only where
observed and predicted catch cells are positive. Tabled Yield is conditional
predicted yield, not unrestricted all-age predicted yield or observed
landings. Its exact mask is unresolved where printed zeros differ from native
observation counts. Yield tests bound known positive-cell contributions below
and all possible contributions above, allowing for source rounding. This
clarification changes notes only; numerical values and fit inputs are unchanged.

## Sources

- [HAWG 2026](https://doi.org/10.17895/ices.pub.31424315), section 10.3 and Tables 9.1.5–9.1.7, 9.3.1–9.3.12.
- [Official 2026 advice entry](https://asd.ices.dk/viewAdvice/4046) and [SAG 21281](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21281).
- [Pinned production repository](https://github.com/ices-advice/2026_san.sa.2r/tree/7a77f3b7a2e2fc2cb6609bbe234f8de9b97dac3f).
- [Pinned smsR](https://github.com/nissandjac/smsR/tree/a097011f2fff959c9a263e5f6acb49795b9a53ad), survival, observation, recruitment and reporting equations.
- [2024 sandeel benchmark](https://doi.org/10.17895/ices.pub.21581151.v2).
