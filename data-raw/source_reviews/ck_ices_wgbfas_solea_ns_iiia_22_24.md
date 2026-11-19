# Common sole (ck_ices_wgbfas_solea_ns_iiia_22_24)

## Common sole in ICES Subdivisions 20–24

### Assessment selected

The stock is Common sole (*Solea solea*), ICES sol.27.20-24, in Subdivisions
20–24. WGBFAS 2025 remains a separate historical detailed assessment. Its
accepted SAM run uses observations through 2024 and reports fitted summaries
for 1984–2024. The cached fit converged (optimizer code 0; objective 45.71169)
and reproduces the report's annual recruitment, SSB and Fbar table within its
published rounding. The native N-at-age values also agree with the report.

WGBFAS 2026 is now the latest detailed assessment, with fitted inputs and
age-specific outputs transcribed in `ices_sole_20_24_2026.md`. Its aggregate
SAG values remain on the same 2026 assessment record. The 2026 report notes
that the new survey index and revised reference points introduced in 2025 make
estimates for 2025 incomparable with earlier assessment estimates.

### Sources and local cache

- [WGBFAS 2025 report](https://literatur.thuenen.de/digbib_extern/dn069788.pdf), especially Tables 6.5–6.10.
- [2025 SAM run and data files](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Sole20_24_2025_new_indicesCV_conf/).
- [WGBFAS 2026 report](https://literatur.thuenen.de/digbib_extern/dn071152.pdf), including the stock audit on pp. 663–664.
- [ICES SAG 2026 source data, key 21317](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21317).

Retrieved 2026-10-22. The report PDFs, SAG pages, model/data objects, model
configuration, and source data files are cached locally under the gitignored
`source_cache/ck_ices_wgbfas_solea_ns_iiia_22_24/ices_sole_20_24_2025/`. Its
`manifest.csv` records each cached source file's URL and SHA-256 checksum;
`SOURCES.md` records the principal checksums and retrieval details. The fitted
object identifies stockassessment version 0.12.0 and upstream SHA
`1cc464b80b6f`.

### Recovered inputs and assumptions

- Residual catch is landings only, in thousand fish, ages 2–9+ for 1984–2024;
  discards are excluded from the fitted assessment. The source observation
  table contains 328 finite catch-at-age values.
- The Q4 Sole survey index covers ages 1–9+ in 2004–2024. Eighteen cells from
  2012–2013 are missing and remain blank. Its within-year timing is 0.8754645. The original age-year CVs and the SAM relative precision weights are both
  retained. The assessment normalizes CVs by their overall mean and uses
  `1/(CV/mean(CV))^2`; these weights scale relative precision rather than
  fixing the observation variance.
- Gillnet CPUE covers ages 2–8 in 1994–2007 at timing 0.56. Trawl CPUE covers
  ages 2–6 in 1987–2008 at timing 0.875. Both remain on their native relative
  index scales. The source has 725 catch and index observation rows, including
  the missing Q4 cells.
- Annual stock and catch weights cover ages 1–9+ and 1984–2024, in kg per fish. SAM estimates weight processes from these observations. Natural mortality
  is fixed at 0.1 per year. Maturity is zero at ages 1–2 and one at ages 3–9. The source supplies zero fractions of F and M before spawning.
- Recruitment follows the source random-walk model. N-process variance is
  separate at age 1 and shared across ages 2–9. F follows a random walk with
  compound-symmetry correlation across ages; F at age 1 is not estimated,
  ages 2–5 have separate states, and ages 6–9 share a state. The source
  observation residual structures are independent for catch and the Q4/trawl
  indices, with AR(1) residual correlation across ages for gillnet.

### Recovered outputs and completeness

The 2025 record contains fitted N-at-age and F-at-age for 1984–2024. Age 1 F is
not estimated in SAM and is left unavailable. Total abundance is derived by
summing native N-at-age; no uncertainty is available for this derived sum.
Table 6.10 supplies recruitment, SSB, Fbar for ages 4–8, and total biomass,
with published lower and upper 95% confidence limits. Fitted observation
predictions are retained for catch and all three indices. The age-state SEs in
the native object are on the log scale and are identified as such in the
output notes. M is fixed, so there is no estimated M output.

The cached SAM fit also estimates twelve catchability parameters: Q4 has separate ages 1-3 and a shared 4-9+ block, Gillnet has separate ages 2-4 and a shared 5-8 block, and Trawl has separate ages 2-4 and a shared 5-6 block. The q estimates are exp(logFpar); natural-scale SEs use the delta method and limits are 95% log-scale Wald intervals. These native q outputs are now in outputs.csv. The physical survey-index units are unresolved, so the q unit is retained as native index scale per thousand fish with that limitation recorded.

The 2025 assessment now has complete recovered inputs, assumptions, and
outputs. Tables 6.11–6.12 supply the 2025–2027 short-term forecast N-at-age,
age-specific forecast F (`pF`), derived total abundance, 2025–2026 age-1
recruitment, 2026 SSB, 2025 Fbar, and projected 2025 landings, discards, and
total catch. Forecast N-at-age and `pF` are official forecast inputs, not fitted
historical estimates; total abundance is derived by summing the reported
N-at-age values. The report does not provide forecast uncertainty, and the
rounded age-specific forecast F values are retained separately from the
reported Fbar. The 2026 assessment record combines the detailed report tables
with aggregate SAG outputs; its assessment-year forecast remains identified
separately from fitted historical estimates.

## Common sole in ICES Subdivisions 20–24: 2026 assessment

### Assessment selected

The WGBFAS 2026 assessment is the latest detailed official assessment for
*Solea solea* in ICES sol.27.20-24. It uses data through 2025 and provides
fitted N-at-age, F-at-age and summary estimates. The existing database key
ices_sole_20_24_2026_summary is retained because it already identifies the
ICES SAG series; its assessment record now contains the detailed 2026 tables
as well as the aggregate SAG values. The 2025 run remains a separate historical
record.

### Sources

- [WGBFAS 2026 report, section 6 and Tables 6.5–6.10](https://doi.org/10.17895/ices.pub.32455056.v3).
- [2026 stock annex](https://doi.org/10.17895/ices.pub.29210012.v2), including the assessment input definitions and fleet age ranges.
- [ICES Advice View, 2026 assessment](https://asd.ices.dk/viewAdvice/6136).
- [ICES SAG source data, key 21317](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21317).
- [2025 SAM run](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Sole20_24_2025_new_indicesCV_conf/), used only to validate overlapping 2024 weights and Q4 index cells.
- The 2026 report names the final SAM run sole20_24_2026_new. A request for its run/model.RData from the public SAM server failed with a connection reset, so no native input, model, or fitted object was available.

The 2026 report, stock annex, and advice PDF are cached under the gitignored
source_cache/ck_ices_wgbfas_solea_ns_iiia_22_24/ices_sole_20_24_2026_summary/.
That folder's manifest.csv records the URLs, retrieval date, and SHA-256
checksums.

### Recovered inputs

- Table 6.6 supplies catch numbers at age for 1984–2025, ages 2–9+, in
  thousand fish (336 values). The report and stock annex identify discards as
  excluded from the assessment.
- Table 6.7 supplies stock weights for 1984–2025, ages 2–9+. The printed
  values were divided by 10,000 to obtain kg per fish. This scale conversion
  reproduces the 2025 native SAM weight observations for every overlapping
  2024 age.
- Table 6.5 supplies the three fitted tuning series. The Q4 survey contains
  171 finite values for ages 1–9 in 2004–2024, with 2012–2013 missing; although
  the table metadata extends to 2025, no 2025 row is printed. Gillnet CPUE has
  112 values for ages 2–9 in 1994–2007. Trawl CPUE has 110 values for ages 2–6
  in 1987–2008. The source table includes leading fields outside the stated
  age ranges for Q4 and trawl; those fields were not imported. The Q4 values
  in 2004–2024 agree with the prior native run where they overlap.

Exact sampling times and the observation precision/CV settings are not labelled
in the recovered report tables. These remain unresolved rather than being
borrowed from the older fit.

### Recovered outputs and assumptions

- Table 6.9 supplies fitted N-at-age for 1984–2025, ages 1–9, in thousand
  fish (378 estimates). Total abundance is derived by summing these values and
  has no uncertainty interval in the source.
- Table 6.8 supplies fitted F-at-age for the same years and ages (378
  estimates); the source constrains ages 6–9 to a common value.
- Table 6.10 reports recruitment, SSB, Fbar for ages 4–8, and total stock
  biomass with 95% confidence limits. Existing SAG recruitment, SSB and Fbar
  rows remain in the database; total stock biomass and its limits are added
  from the report.
- The stock annex identifies a single-area, single-sex SAM; fixed M of 0.1 per
  year; knife-edge maturity at age 3; stock weight equal to catch weight; and
  zero F and M before spawning. The native SAM object, exact software version,
  tuning-series timing and precision settings were not recovered.

Input, assumption, and output statuses remain partial: important source
series and fitted surfaces are now available, but the native SAM files, exact
observation settings, and age-specific uncertainty are not.
