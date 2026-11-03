# Gulf of Cadiz and southern Portugal anchovy

## Stock identity and official assessment

The Charbonneau–Keith starting row is `ICES-WGHANSA_mordax_SP9a`, retained
under `ck_ices_wghansa_mordax_sp9a`. Its species name *Engraulis mordax* is
an error for this Iberian stock: the official sources identify European
anchovy, *Engraulis encrasicolus*. The Master identifier and `SP9a` area
suffix remain unchanged, and the taxonomic correction is explicit in notes.
It is not a global synonym between the two species.

The 2024 benchmark split Division 9.a into western `ane.27.9aW` and southern
`ane.27.9aS` stocks. The new stock `ices_anchovy_gulf_cadiz` represents the
southern stock only; it does not inherit the historical combined Master ID.
The western successor is recorded separately; see [its source review](ices_anchovy_west_iberia_2026.md).

`ices_anchovy_gulf_cadiz_2025` is the November 2025 production SS3 assessment,
1989–2025. The June 2026 WGHANSA report assesses western anchovy, not this
stock; the next southern update is scheduled for November 2026. Although
SS3 supplies population estimates, advice uses a category-3 1-over-2 rule
applied to SSB because Fcap has not been defined. A data-limited advice
category therefore does not mean that an analytical assessment is absent.

## Sources and cache

- [WGHANSA 2025, version 3](https://doi.org/10.17895/ices.pub.29335520.v3),
  chapter 4, including the November meeting; published update March 2026.
- [Official stock annex](https://doi.org/10.17895/ices.pub.28053362),
  describing the 2024 benchmark and seasonal observation model.
- [2025 advice](https://doi.org/10.17895/ices.advice.27202494) and
  [SAG export, key 21266](https://sag.ices.dk/SAG_API/StockXmlDownload/21266).
- [2025 assessment code](https://github.com/ices-advice/2025_ane.27.9aS/tree/075ed16570d08be9378848ddabe15c3b64feb07b),
  pinned to `075ed16570d08be9378848ddabe15c3b64feb07b`.

Original PDFs, XML, source scripts and extracted review text are cached in
`source_cache/ck_ices_wghansa_mordax_sp9a/`, with URL/date/checksum manifests.
The public TAF tree contains code but no `LastYear` or `update2025` folders,
and has no release assets. Its code is inspected as text, not executed.
I rechecked the pinned repository on 2026-10-26: the same SHA is still the
default-branch head, and the public tree still contains no data folders. The
`icesTAF::get.artifacts()` documentation describes a TAF API lookup, but the
documented anonymous `Artifacts` endpoint currently returns 404. This does
not establish that access-controlled copies do not exist; no usable public
download route was found.

An [MSE project](https://github.com/mariazuba/Fcap_ane27.9aS/tree/a7a0024be8a80185eb2be7e3fcec50dce26853a1)
contains original-looking SS3 inputs and an r4ss object spanning 1989–2024.
Those files are cached with a separate manifest. They are **not** the current
production run: for example its 1989 SSB is 15479.8 t versus 15775 t in the
2025 official series. Its biology, parameters and states are not imported
or substituted for missing 2025 files.

## Recovered observations and biology

The source importer is `scripts/database/157_import_ices_anchovy_gulf_cadiz_2025.R`.

- Annual sums of the quarterly model catch inputs cover 1989–2025 in tonnes.
  These are one stock-level summary, not another fleet. The 2025 value
  6440 t includes assumed interim catch. The current assessment deliberately
  excludes 2025 fishery ages and catch weights; previous-year averages must
  not be used to fill them.
- Spanish annual numbers-at-age are available for 1995–2024, ages 0–3,
  in thousand fish. The whole-fishery quarterly table is recovered for 2024
  separately. Spanish annual counts and whole-stock quarterly counts have
  different coverage; neither is silently promoted to the missing complete
  native quarterly composition likelihood.
- Raw quarterly catch weights are recovered for 2024 in grams/fish, including
  source zeros for absent ages. The SS3 empirical weight surface instead uses
  mixed-model quarter/year/age estimates. Raw catch weights cannot complete
  that missing surface, and no extrapolated stock weights are supplied.
- Fixed annual M is 2.97, 1.6, 2.48 and 2.48 for ages 0–3. Maturity is
  0, 1, 1 and 1. These are input assumptions, not estimated-M successes.
- PELAGO southern-stock biomass is the **S (Total)** column, not the grand
  total covering western and southern waters. For 2025 these are 60838 t
  and 151558 t respectively. The reported 2011 southern zero is preserved
  as survey context but is excluded from the source model's input years.
- ECOCADIZ biomass ends in 2023; 2010 is Spanish-only partial coverage.
  BOCADEVA provides mature biomass, with 2020/2023 estimates relying on mean
  spawning fractions; 2023 is still provisional. The ECOCADIZ-RECLUTAS
  likelihood uses the **age-0 biomass in parentheses**, not all-age biomass
  or fish numbers: 20758 t in 2025. Its incomplete 2017 survey does not
  receive an invented whole-stock value.
- Published PELAGO/ECOCADIZ ages 0–4 are expanded survey abundances in
  **million fish**, not trawl sample counts. They describe the same information
  underlying biomass and composition and must not be fitted as an extra
  independent dataset. Some totals differ between tables: PELAGO 2014 age
  counts sum to 2891 million while the biomass table reports 2241 million;
  neither value is adjusted. Current native age compositions and their
  Francis-adjusted sample sizes remain unverified. The production population
  bins end at age 3, whereas the raw survey table retains age 4.

Survey seasons are retained. Exact current SS3 observation fractions are not
in the recovered files; variable survey months and an older run's dates are
not silently converted to fixed timing fractions.

## Processes, outputs and uncertainty

The model has one area, combined sexes, four seasons, spawning on 1 April,
and age-0 settlement on 1 July. F uses the SS3 hybrid method and separate
quarterly logistic selectivity. PELAGO selectivity is constant; ECOCADIZ has
two blocks. BOCADEVA selects mature ages and the recruitment survey age 0.
Survey q is linear. Reported catch CV is 0.05 and survey CV 0.30; the
current native log-SDs and adjusted composition sample sizes are unavailable.

Recruitment is Beverton–Holt with fitted R0, fixed h=0.8 and sigmaR=0.33.
The report's fractional early-deviation start, 1962.8, conflicts with the
public script, which uses it as a bias-adjustment ramp boundary. Exact early
deviation controls require the missing production control file. They remain
unresolved, rather than being inferred from an older reference model.

SAG supplies 37 years of SSB, July age-0 recruitment and annual age-3 F.
Source 95% limits are retained where available; no SEs or missing intervals
are invented. Rounded report CVs are preserved in notes. F is age-3/apical F,
not population-weighted Fbar. The 2025 values are SSB 18730 t, recruitment
11059600 thousand fish and F3=0.692 per year. SAG SSB in 2012 is 10584 t,
while the report prints 10585 t; the SAG point stays with its own interval,
and that one-tonne discrepancy is recorded. Other SSB and recruitment points
match the report, and F agrees at the report's two-decimal precision.

No current fitted N-at-age or full F-at-age surface was recovered. Total N
and common-definition SSB therefore cannot be derived. The 2026 forecast
is not imported into the historical series.

## Translation status

This is a partial source import, not a completed tinyAM fit. Missing current
empirical stock weights and native quarterly compositions prevent a
defensible replication-oriented fit. A future annual approximation must
also address July settlement, strong seasonal mortality and seasonal
survey/composition timing. It must not pretend July recruitment occurred
on 1 January, or use the older MSE states to manufacture observations.
No optimization or starting-value retry is justified before those input
gaps are resolved. All three canonical source-completeness statuses remain
partial.

The stock recipe stops at source readiness for both preparation and fitting;
it runs no optimizer and constructs no starting values. A standalone local
dashboard at
`results/cache/ices_anchovy_gulf_cadiz_2025/dashboard_official_only.html`
shows the available official SSB, July recruitment and age-3 F with source
uncertainty. Its Background states that no tinyAM fit or agreement comparison
is available. Missing observations, population patterns and other states
remain unavailable rather than being reconstructed from the older MSE run.
