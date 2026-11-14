# Washington black rockfish, 2023 assessment

## Assessment and sources

NOAA's 2023 production assessment is the current Washington black rockfish
assessment unit (Stock SMART 14409; `Sebastes melanops`). The assessment report
and native Stock Synthesis archive are cached locally. Retrieval dates, URLs,
archive revisions, byte sizes and SHA-256 hashes are recorded in
`provenance/noaa_black_rockfish_washington_2023_sources.csv`.

The report identifies the run as the 2023 assessment and its fitted time series
ends in 2022. The archived reference model uses Stock Synthesis 3.30.21.00. It
has one area, one season, two sexes, ages 0-40 (with age 40 as the 40+ group),
and reports forecasts through 2034. The source model's natural mortality is
constant by sex and fixed at 0.17 per year for females and 0.152 for males; it
is not estimated in this reference run.

## Inputs recovered

The import preserves 249 annual fleet catch-biomass records from 1940-2022,
86 aggregate index observations with their log-scale errors, 226 raw
length-composition rows, and 2,285 raw age-composition rows. Index observations
retain their native fleet, unit code, month and error convention. Five index
series are biomass-scale; the OCNMS YOY series uses Stock Synthesis unit code 33,
which denotes age-0 recruitment. Unknown physical multipliers are not inferred.
Source month is retained and translated to `(month - 1) / 12` for the database's
fractional-year field.

The age and length observations remain frequency data, not numbers-at-age.
Many age-composition rows are conditional on a source length interval; the
unconditioned `-1/-1` interval is preserved as missing bounds. Negative signed
fleet codes identify provisional compositions that Stock Synthesis excludes
from the total objective. The database retains these source codes in notes and
keeps the raw compositions separate from catch biomass and abundance indices.
Age-error codes 1 and 2 are retained on their corresponding composition rows;
their source definitions remain in the cached, checksum-pinned `datafile.dat`.

The control file reads a length-specific maturity schedule and uses a
length-based fecundity relationship. No standalone maturity-at-age or
observed-weight-at-age input vector was located. The native `wtatage.ss_new`
file supplies generated population, fleet and maturity-fecundity surfaces;
these are recorded as model outputs, not relabelled as observed inputs.

## Outputs recovered and limits

The reference archive provides sex-specific numbers-at-age, biomass-at-age,
fishing mortality-at-age and fixed natural mortality-at-age for model years and
forecasts. It also provides annual total biomass, recruitment and spawning
output. Total numbers are derived by summing the archived numbers-at-age over
both sexes and ages; no uncertainty is assigned to that sum.

The assessment reports spawning output in **billions of eggs**, not spawning
biomass. Its Table ii reports point estimates and 95% asymptotic intervals for
2013-2023; those intervals are retained. The report's Table v separately gives
reference-point intervals. Age-specific uncertainty is not available in the
imported source tables.

The database record remains partial. The archive does not provide a direct
catch-numbers-at-age matrix or a direct age-specific abundance-index series.
Compositions and aggregate indices are retained in their native form; no
catch-at-age or age-index series has been manufactured. There is also no
standalone supplied maturity-at-age input. These limitations should be
considered before any downstream analysis uses the record.

## Sources

- [2023 Washington black rockfish assessment report](https://www.pcouncil.org/documents/2024/02/status-of-black-rockfish-sebastes-melanops-in-2023-in-state-and-federal-waters-off-washington-state.pdf/)
- [Official Stock Synthesis model archive](https://www.pcouncil.org/documents/black-rockfish-wa-2023-model-files-zip-file/)
- [2023 Black Rockfish STAR panel report](https://www.pcouncil.org/documents/2023/11/stock-assessment-review-star-panel-report-for-black-rockfish.pdf/)
- [Stock Synthesis 3.30 user manual](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html)
