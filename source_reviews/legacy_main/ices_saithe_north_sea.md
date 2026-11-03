# North Sea saithe source review

## Assessment and source

The current detailed official assessment is the 2026 ICES assessment of
saithe (*Pollachius virens*) in subareas 4 and 6 and Division 3.a, stock code
`pok.27.3a46`, assessment key 22504. The working group's 2026 report is
published as [ICES Scientific Reports 8:43](https://doi.org/10.17895/ices.pub.32676345).
The official assessment is also represented in the [ICES advice database](https://doi.org/10.17895/ices.advice.30932291)
and [Stock Assessment Graphs, key 22504](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22504).
The [2024 WKBGAD benchmark](https://doi.org/10.17895/ices.pub.25002470)
documents the model framework and revisions to biological inputs.

The full WGNSSK 2026 PDF is cached locally at
`analysis/comp_assessments/source_cache/ices_saithe_north_sea_2026/WGNSSK_2026.pdf`.
Its SHA-256 is
`9d33846cf100dd8544ba30dbeffc7435a857a71854d318dbc7b383d668b03857`.
The cache is gitignored. Numerical values imported into the canonical database
are transcribed from this report's tables by
`scripts/database/048_import_ices_saithe_north_sea_2026.R`.

## Official assessment recovered

The assessment is a SAM age-structured model over 1967–2025 and ages 3–10+.
The report supplies total catch numbers-at-age, total catch weight-at-age,
stock weight-at-age, and annual maturity-at-age for those years and ages
(Tables 14.3.5, 14.3.8, 14.3.11, and 14.3.12). Separate landings/discard
number and weight tables are also published; the model input catch series is
the combined catch at age. The database retains the combined model inputs.

Stock weight is the scientifically appropriate weight for biomass and SSB
calculations. The report states that 2003–2025 stock weights are model-based
estimates using survey data only, because catch weights overestimate stock
weights through about age 6. The 1967–2002 stock-weight series is derived by
scaling catch weights by ratios estimated over 2003–2022. The official annual
stock-weight values are transcribed as reported; the earlier values are not
reconstructed again from catch weights.

Natural mortality is fixed by age using the Lorenzen relationship with mean
stock weight-at-age, scaled so age-9 M is about 0.2. The reported values at
ages 3–10+ are 0.384, 0.335, 0.294, 0.259, 0.232, 0.212, 0.197, and 0.177
per year (Section 14.3.3, report page 497).

The age-specific research-vessel index combines Q3 and Q4 surveys and reports
ages 3–8 for 1992–2025. A second series is standardized commercial trawl CPUE,
available from 2000–2025 and tuned to exploitable biomass in SAM (Table
14.3.13). Its annual values are relative CPUE, not absolute biomass. Both
series are retained in `inputs.csv` with their distinct meanings.

The printed SAM configuration is Table 14.4.1. It is timestamped
12 March 2024, despite being reproduced in the 2026 report. It specifies
recruitment at age 3; F states for ages 3–8 with ages 9 and 10+ coupled; an
AR(1) correlation of F states across ages; a separate N-process variance for
recruitment and shared variance for older ages; lognormal observations; known
stock weights, catch weights, maturity, and M; and age-correlated residuals
for catch and the age-specific survey. Fbar is ages 4–7. The configuration
date and exact 2026 sampling fractions remain flagged rather than treated as
newly verified settings.

The printed F variance keys are `0 1 2 3 3 3 3 3`: ages 3, 4 and 5 have
separate innovation SDs, with ages 6–10+ sharing one. tinyAM's retained F
process has one SD. Separate recruitment and shared older-cohort SDs are
already supported; that simpler N variance grouping is not itself a missing
capability. The initial-state treatment and F density still differ. The common
SSB comparison uses official N with the same translated biology as tinyAM;
it does not imply identical native spawning-time SSB.

The report gives official N-at-age for ages 3–10+ and F-at-age for ages 3–8
and 9+ through 2025 (Tables 14.4.2–14.4.3). It explicitly says F at age 9 and
10+ is coupled, so the F output surface uses a single 9+ value. Table 14.6.1
provides recruitment-at-age-3, SSB, TSB, and Fbar 4–7 with 95% intervals
through 2025. The 2026 short-term forecast values are stored separately from
the historical fitted period.

## Remaining limitations for translation

- The final 2026 native SAM data/model object was not located. The report
  provides rounded inputs and outputs, but not age-specific uncertainty or
  fitted observation predictions.
- Exact 2026 within-year sampling fractions are absent from the report. The
  cached 2024 native data object has sample times 0.730 for the Q3–Q4 index
  and 0.525 for commercial CPUE; these are useful context, not verified 2026
  values.
- tinyAM's current observation structure does not represent a single
  aggregate relative CPUE observation tuned to exploitable biomass. The
  translation therefore fits the Q3–Q4 age-specific index and records the
  CPUE series as omitted from the fit. It does not divide aggregate CPUE among
  ages or treat its relative scale as absolute biomass.
- The chosen F process, shared source F state and correlated observation errors
  differ from SAM. tinyAM supports age-correlated F RW increments and process-SD
  sharing, but their availability does not make the retained density identical.

The database status remains partial for assumptions, inputs, and outputs
because the current native run object and exact sampling fractions are
unavailable, and the published age-specific surfaces lack reported
uncertainty. No plot-derived values or fitted estimates are being substituted
for inputs.

## Current initial abundance

The retained translation estimates older first-year abundance freely. It does
not use source N/F estimates to construct starting values. Current age pooling,
catchability and other scientific settings are defined in the stock script.
