# Sandeel in Area 3r: HAWG 2026

## Identity and sources

`ices_sandeel_area_3r_2026` is the official ICES `san.sa.3r` assessment through
2025, covering Skagerrak and the northern/central North Sea, Divisions 4.a–b
and Subdivision 20. The stable stock ID is `ices_sandeel_area_3r`, taxon
*Ammodytes* spp., basin Northeast Atlantic. The broad Charbonneau–Keith
`ICES-HAWG_dubius_NS` entry does not identify one current regional stock.
Its ID and taxonomy are preserved; no catalogue identifier is invented for
this regional record.

Official advice entry 4047 identifies SAG 21282. All 39 historical recruitment
and SSB values match HAWG Tables 9.4.9–9.4.10. The production repository is
pinned at `93847fb928ebf02f995c503e67f52bc2dd1398cc`, verified against its
remote HEAD. The declared smsR revision is
`a097011f2fff959c9a263e5f6acb49795b9a53ad`. Source scripts and C++ were
inspected as text, not executed. The benchmark concluded in 2023 and was
published in 2024; the database records framework year 2023.

## Native model and recovered records

The active model spans **1987–2025**, ages 0–4+, with two half-years and
combined sexes, one area and one commercial fishery. The outer loader asks
for 1986–2025, but `startYear=1987`, state tables and SAG establish the fitted
window. No 1986 observations are invented. Recruitment enters in July at
age 0; older ages advance in January. Initial January abundance at ages
1–4+ is freely estimated, followed by deterministic older-cohort survival.
July recruitment has a hockey-stick expectation with fixed 72,713-tonne
SSB breakpoint and likelihood weight 0.05. This breakpoint is not the
recruitment plateau, despite a shorthand code comment.

F is proportional to seasonal standardized effort, with constant age/season
coefficients, no time blocks and no technical creep. Ages 3 and 4+ share
selectivity. `isFseason=c(1,0)` is a normalization, not a switch disabling
all second-half fishing. **Effort, catch and F are exactly zero in 2025**
under the zero TAC. These values are retained without pseudo-effort,
positive catch replacements or truncating the terminal year.

M is fixed supplied, time-varying multispecies mortality by age and season.
The survival equation uses the integrated half-year hazards directly:
`exp(-F_season-M_season)`. Annual M adds both seasonal hazards at the same
age; multiplying them by another half would be incorrect.

| Input | Native coverage and units |
|---|---|
| Catch, Table 9.4.1 | 1987–2025, ages 0–4+ in both halves; million fish; likelihood excludes age 0 |
| Stock/catch weights, Table 9.4.2 | First-half ages 1–4+, second-half ages 0–4+; grams/fish |
| Maturity, Table 9.4.3 | Same seasonal age grid; proportions |
| M, Table 9.4.8 | Same grid; integrated half-year hazards, changing over years |
| Dredge, Table 9.4.4 | 2006–2025, ages 0–1; scaled number index, absolute multiplier unstated |
| Acoustic, Table 9.4.4 | 2009–2025, separate observations at ages 1–4+; scaled number index |
| Effort, Tables 9.1.5–9.1.7 | Annual and seasonal fishing days for a standard 200 GT vessel; Area 3r column |
| SAG catches | All-age annual observed tonnes, distinct from predicted Yield |

The import adds **2,056 inputs, 18 assumptions and 936 outputs**. Outputs
include January N at ages 1–4+, July age-0 recruitment, annual and seasonal
F, January biomass/SSB, predicted yield and arithmetic Fbar ages 1–2.
Derived January abundance sums ages 1–4+ only: July recruits are not part
of that simultaneous population. Fixed supplied M is not an estimated output.

Dredge predictions average abundance over annual times 0.875–1; Acoustic
predictions average over 0.25–0.35. An interval midpoint is an approximation,
not the source's exact observation equation. Dredge q and observation SD are
separate at ages 0 and 1. Acoustic q is separate at ages 1 and 2 and shared
at ages 3/4+, with one SD across all four ages. Sharing q does **not** pool
age-3 and age-4 observations. Catch SD groups are ages 1–2 and 3–4+ within
each season. Table 9.4.5 confirms 108 survey observations and 244 catch
observations. No commercial tuning index is active.

SAG limits for SSB, recruitment and Fbar are retained without inferring SEs:
the data page does not label their confidence level or construction. N/F
tables have no uncertainty. Source SSB uses January abundance/biology and
zero pre-spawning mortality fractions in the declared configuration.

## Verification and unresolved details

The rounded catch table has 240 positive eligible cells, versus 244 in the
model diagnostic. Missing flags and unrounded arrays prevent identifying
the difference; no printed cell is changed to force agreement. Second-half
effort rows in 2007 and 2022 are absent and remain missing. Complete direct
annual totals and first-half effort are retained separately. There is no
first-half age-0 biology to import.

Seasonal F sums to annual F within rounding. Older-cohort survival agrees
with N, annual F and summed M within the printed mortality precision.
January biomass and SSB agree with N, weights and maturity within explicit
rounding bounds. Seasonal Baranov calculations check the tabled predicted
Yield rather than treating it as observed catch times weights. The generic
smsR `getSummary()` helper calls observed `getYield()`; this mismatch does
not override the numerical check of the published table's meaning.

The summary's future recruitment is the geometric mean over 1987–2025,
75,267,201 thousand fish. The configured forecast instead uses 1987–2024,
79,171,378 thousand. The narrative says 1987–2022, so the differing text is
recorded rather than silently changing the numerical forecast. These are
future assumptions, not historical observations. The narrative also calls
2025 SSB below Blim, whereas its numerical 91,332 tonnes is above Blim
72,713 and below Bpa 108,978. Report/SAG numerical values are retained.

The public repository omits the native `3r` folder, zero-catch flags,
unrounded arrays and fitted `sas.rds`. Published `data.R` passes
`surveySD/catchSD/estSD`, but its declared builder accepts
`surveyCV/catchCV/estCV` without those aliases. The actual production
builder revision therefore remains unverified. All three completeness
statuses remain **partial**; the missing native arrays prevent exact reconstruction of the source likelihood.

Sources, checksums, pinned revisions and verification logs are cached in
`source_cache/ck_ices_hawg_dubius_ns/2026_san.sa.3r/`. The manifest references
the shared HAWG report, benchmark and software rather than duplicating them.

## Validation

The full database validator passes: 117 stocks, 112 assessments, 2,186
assumptions, 361,971 inputs and 194,299 outputs. Repeating the importer is
byte-identical. All unrelated committed source rows remain unchanged, apart
from the explicit regional link appended to the legacy catalogue notes.

## Yield reporting clarification

The declared C++ `Catchtot` reporting loop sums predictions only where
observed and predicted catch cells are positive. Tabled Yield is conditional
predicted yield, not unrestricted all-age predicted yield or observed
landings. Its exact mask is unresolved where printed zeros differ from native
observation counts. Yield tests bound known positive-cell contributions below
and all possible contributions above, allowing for source rounding. This
clarification changes notes only; numerical values and fit inputs are unchanged.

## Sources

- [HAWG 2026](https://doi.org/10.17895/ices.pub.31424315), section 10.4 and Tables 9.1.5–9.1.7, 9.4.1–9.4.12.
- [Official advice entry 4047](https://asd.ices.dk/viewAdvice/4047) and [SAG 21282](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21282).
- [Pinned production repository](https://github.com/ices-advice/2026_san.sa.3r/tree/93847fb928ebf02f995c503e67f52bc2dd1398cc).
- [Declared smsR source](https://github.com/nissandjac/smsR/tree/a097011f2fff959c9a263e5f6acb49795b9a53ad).
- [Sandeel benchmark, published 2024](https://doi.org/10.17895/ices.pub.21581151.v2).
