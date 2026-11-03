# Summer flounder source review

## Assessment represented

The 2025 management-track assessment is the latest official assessment and
supports current advice, using data through 2024. Its public materials provide
summary and diagnostic outputs, but the SASINF package available for this
review did not include age-specific input tables or fitted age surfaces. The
canonical database therefore represents the latest official assessment with
recoverable detailed age data: the 2018 SAW-66 official ASAP run
`F2018_BASE_V2`, through 2017. The 2025 summary is recorded separately and is
not used to fill gaps in the 2018 record.

The official 2018 model combines sexes, uses true ages 0-7+, and estimates
recruitment at true age 0. It has four catch fleets: commercial landings,
commercial discards, recreational landings, and recreational discards. It
retains a large set of fishery-independent indices. The database currently
contains only the NEFSC Bigelow spring and fall age indices.

## Data and translation decisions

- Catch-at-age values are transcribed from Tables A3, A6, A10, A23, A28, and
  A32. Fleet tables report ages 0-10; ages 7-10 are summed to the official
  model's 7+ group, and Maine-Virginia and North Carolina commercial landings
  are summed for the commercial-landings fleet. Table A32's published total is
  preserved as a separate aggregate series, not as a fifth fleet. The fleet
  age series and published aggregate differ by as much as 941 thousand fish in
  an age-year cell, although annual totals are close. The difference is
  documented rather than reconciled by altering source values. A tinyAM fit
  should use either the published aggregate catch or the four fleets, never
  both together.
- The NEFSC Bigelow spring and fall age-index rows are transcribed from Tables
  A40-A41 for 2009-2017 and 2009-2016, respectively. Sampling times 0.25 and
  0.75 are seasonal midpoint approximations; the source report does not give
  within-season timing for these series. The other indices used by
  `F2018_BASE_V2` are not yet represented.
- M is fixed at age in the official model. The age 0-7+ values are 0.26, 0.26,
  0.26, 0.25, 0.25, 0.25, 0.25, and 0.24 per year (Table A90). These values
  are stored as source inputs, not as estimated M outputs.
- Table A90 reports mean November SSB weights at age for 2013-2017. Those
  published values are stored as the source schedule; using them as a
  time-invariant weight series across a tinyAM historical fit is an explicit
  approximation, not an annual official weight surface.
- Table A86 reports the combined-sex, three-year moving-window maturity ogive
  through 2016. No 2017 row is reported because 2017 fall maturity data were
  unavailable. A fit that extends through 2017 must state how it handles that
  final year; the conservative comparison period using the available maturity
  data is 1982-2016.
- Tables A87-A89 provide annual SSB, recruitment, F-at-age, and January 1
  abundance-at-age through 2017. Recruitment is at true age 0. The report
  provides terminal-year 90% MCMC intervals for aggregate F and SSB, but no
  matched age-specific uncertainty table was recovered.

## Translation status

The source inputs and outputs above have been added to the canonical database.
The initial tinyAM translation uses the published aggregate catch series once,
the Bigelow spring/fall age indices, and the static SSB-weight approximation.
Its 1982-2016 fit did not pass tinyAM's convergence check: the optimizer
returned code 0 with objective 757.41 and maximum gradient 0.00045, but the
Hessian was not positive definite (24 fixed and 552 random effects). The
standard-error calculation returned, but it is not treated as a successful
fit. No model-comparison dashboard was generated. No alternate settings were
tried to force convergence.

The official run retained more observations and assessment detail than this
tinyAM translation can represent. Any later comparison should be limited to
definitions and years that can be matched; in particular, the available
maturity schedule ends in 2016.

## Sources

- [66th SAW Summer Flounder Assessment Report (2018)](https://repository.library.noaa.gov/view/noaa/23031/noaa_23031_DS1.pdf)
- [2025 June Management Track Peer Review Panel Report](https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf)
- [NOAA SASINF assessment-data search](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php)
- [2025 Summer Flounder Management Track Assessment Report](https://asmfc.org/wp-content/uploads/2025/08/SF_Management_Track_Assessment_2025.pdf)
- [NOAA Summer Flounder assessment status](https://www.fisheries.noaa.gov/species/summer-flounder/science)
