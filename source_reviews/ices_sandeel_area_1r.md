# Sandeel in Area 1r: HAWG 2026

## Identity and official run

`ices_sandeel_area_1r_2026` represents the ICES production assessment for
`san.sa.1r`, through 2025: central and southern North Sea, Dogger Bank,
Divisions 4.b–c. The official taxon is *Ammodytes* spp. The new stock ID is
`ices_sandeel_area_1r`; its Charbonneau identifier is deliberately blank.

Charbonneau–Keith's `ICES-HAWG_dubius_NS` cites the full HAWG 2016 report and
labels the whole North Sea, without identifying one current assessment area.
It does not establish a one-to-one match to Area 1r. That original catalogue
row and identifier remain intact, with a link to this verified regional
record. This import is not a completed reconstruction of every North Sea
sandeel unit. Areas 2r, 3r and 4 require their own selected assessments.

The current report, SAG key 21280 and ICES assessment repository agree on
the historical recruitment and SSB series. The repository is pinned at
`8a556698db2c9c23321980c8fec368c80562b89f`. Its software bibliography specifies
smsR `a097011f2fff959c9a263e5f6acb49795b9a53ad`. Downloaded R/C++ files were
read as source, not executed. The older smsR package example describes a
different assessment and is not substituted for 2026 data. The framework
workshop concluded in 2023 and its report was published in 2024;
`framework_year` records 2023 rather than the publication year.

## Native model and recovered data

The SMS-effort model has two half-year seasons, ages 0–4+, one combined
commercial fishery and one regional, combined-sex population, 1983–2025.
Recruitment enters in July at age 0. Older ages advance at the January
boundary and survive deterministically through seasonal F+M. Initial January
ages 1–4+ are estimated freely. Recruitment has a hockey-stick expectation,
a fixed 105,809-tonne breakpoint and likelihood weight 0.05.

F is proportional to seasonal standardized effort, with age/season coefficients
in blocks 1983–1998, 1999–2021 and 2022–2025. Ages 3 and 4+ share selectivity.
`isFseason=c(1,0)` fixes a seasonal normalization; it does not remove second-half
fishing. The source reports positive F in both half-years.

| Input | Coverage and source | Meaning |
|---|---|---|
| Catch numbers | Table 9.2.1; 1983–2025, ages 0–4+ in both half-years | Million fish, retaining zeros and age-0 values; source likelihood excludes age 0 |
| Stock and catch weight | Table 9.2.2; ages 1–4+ in season 1, 0–4+ in season 2 | Grams/fish; source reports the same values for catch and stock |
| Maturity | Table 9.2.3; same seasonal grid | Proportions, not annual averages |
| M | Table 9.2.8; same seasonal grid | Integrated half-year hazards, supplied from multispecies modelling |
| Dredge index | Table 9.2.4; ages 0–1, 2004–2025 | Native scaled number index; an absolute abundance multiplier is not stated |
| RTM index | Table 9.2.4; ages 1–3, 2016–2020, 2023, 2025 | Native scaled numbers per standard-vessel fishing day |
| Effort | Tables 9.1.5–9.1.7; annual and half-year | Days for a standard 200 GT vessel; annual and seasonal representations are not additive |
| All-age catch totals | SAG 21280, 1983–2025 | Observed tonnes, including excluded age-0 catches; not the tabled predicted Yield |

The Dredge likelihood predicts average abundance over fractions 0.75–1 of
season 2, equivalent to annual time 0.875–1. There is no single exact point
sampling time. RTM uses the beginning of season 1 in the source equation
(`surveyStart=surveyEnd=0`), although samples are collected in April/early May.
Both specifications are recorded rather than inferred from survey names.
Constant q is estimated separately by survey and age. Survey SD groups are
Dredge ages 0/1 separately, and RTM age 1 separately from shared ages 2–3.

The importer adds **2,213 inputs, 17 assumptions and 1,032 outputs**, retaining
both annual and half-year F. Native N reports age 0 at July and older ages at
January: those five columns must not be summed as one simultaneous population.
The derived January abundance sums only ages 1–4+. Source SSB and total biomass
refer to January, with zero fractions of F and M before spawning in the pinned
configuration. The report's Yield is model-predicted catch, distinct from SAG
observed catches. No fitted M is manufactured from supplied fixed M.

SAG provides historical lower/upper limits for SSB, age-0 recruitment and Fbar. They are retained with their reported meaning; the source data page does not
label their interval level or construction. No SE is inferred. N-at-age and
F-at-age tables do not supply numerical uncertainty.

## Validation and unresolved source details

The source importer pins the report, SAG and configuration checksums. Its
checks confirm all historical SAG recruitment and SSB points, annual F as
the sum of seasonal F to printed precision, and older-cohort survival with
the sum of seasonal M. January biomass and SSB reconstructed from reported
N and biology agree within bounds from their printed rounding.

Two effort rows, second-half 2007 and 2022, are absent from Table 9.1.7.
They remain absent; no zero or residual is invented. The source supplies
annual totals and first-half effort separately. The published catch table
has 320 positive eligible cells, whereas the diagnostic table reports 318
catch observations. The exact omitted cells or precision discrepancy is
unresolved. These are source gaps, not grounds to alter reported observations.

The public repository contains settings but its `DATA.bib` points to a local
`1r` folder that is not included. Exact native input files, zero-catch flags,
the fitted `sas.rds` and unrounded biological arrays were not recovered.
All three completeness statuses therefore remain **partial**. The source
summary appends the full-history geometric-mean recruitment for 2026
(111,219,266 thousand fish). The configured forecast instead averages
1983–2024 (112,607,331 thousand fish), explaining its different value in SAG
and the forecast-input table. Pinned `getSummary()`, `getForecastTable()` and
the production `report.R` distinguish these windows. The narrative says
1983–2025, whereas the configuration excludes the final fitted year. Neither
future assumption is imported as a historical observation.

Sources and inspection logs are cached under
`source_cache/ices_sandeel_area_1r_2026/`, with the broader catalogue/repository
search under `source_cache/ck_ices_hawg_dubius_ns/`. Manifests retain URLs,
retrieval/verification dates, revisions and SHA-256 hashes. The focused source
test protects units, seasonal hazards, observation roles, mixed state dates,
reported gaps and uncertainty. The limited annual translation must document
its age-1 entry, seasonal aggregation, survey timing approximation and changed
recruitment/effort likelihoods before a fit is interpreted.

The published `data.R` supplies `surveySD`, `catchSD` and `estSD`, whereas
the declared pinned builder accepts `surveyCV`, `catchCV` and `estCV`
without those aliases. Read-only inspection confirms the interface mismatch.
The exact production builder revision remains unverified; `model_version`
therefore identifies a **declared** version. No downloaded code is rewritten
or executed to conceal that gap. Report/SAG agreement and numerical equation
checks anchor the official historical record independently of this
reproducibility limitation.

## Yield reporting clarification

The declared C++ `Catchtot` reporting loop sums predictions only where
observed and predicted catch cells are positive. Tabled Yield is therefore
conditional predicted yield, not unrestricted all-age predicted yield or
observed landings. The source's rounded age-count/likelihood-count differences
leave its exact positive-cell mask unresolved. This clarification changes
notes only, not any source value, fit or comparison statistic; the Area 4
audit independently verifies the same reporting rule with a fully matching
positive-cell count.

## Sources

- [HAWG 2026](https://doi.org/10.17895/ices.pub.31424315), section 10.2 and Tables 9.1.5–9.2.10.
- [ICES SAG 21280](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21280), regional identity, historical aggregates and limits.
- [Pinned ICES assessment repository](https://github.com/ices-advice/2026_san.sa.1r/tree/8a556698db2c9c23321980c8fec368c80562b89f).
- [Pinned smsR source](https://github.com/nissandjac/smsR/tree/a097011f2fff959c9a263e5f6acb49795b9a53ad), survival, recruitment, observation equations and spawning defaults.
- [2024 sandeel benchmark](https://doi.org/10.17895/ices.pub.21581151.v2), selected regional framework.
