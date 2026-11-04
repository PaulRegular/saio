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

## Data definitions and processing

- Catch-at-age values are transcribed from Tables A3, A6, A10, A23, A28, and
  A32. Fleet tables report ages 0-10; ages 7-10 are summed to the official
  model's 7+ group, and Maine-Virginia and North Carolina commercial landings
  are summed for the commercial-landings fleet. Table A32's published total is
  preserved as a separate aggregate series, not as a fifth fleet. The fleet
  age series and published aggregate differ by as much as 941 thousand fish in
  an age-year cell, although annual totals are close. The difference is
  documented rather than reconciled by altering source values. Sampling times 0.25 and
  0.75 are seasonal midpoint approximations; the source report does not give
  within-season timing for these series. The other indices used by
  `F2018_BASE_V2` are not yet represented.
- M is fixed at age in the official model. The age 0-7+ values are 0.26, 0.26,
  0.26, 0.25, 0.25, 0.25, 0.25, and 0.24 per year (Table A90). These values
  are stored as source inputs, not as estimated M outputs.
- Table A90 reports mean November SSB weights at age for 2013-2017. Those
  published values are stored as the source schedule. No 2017 row is reported because 2017 fall maturity data were
  unavailable. The recovered annual maturity series ends in 2016; no 2017 maturity row is inferred.
- Tables A87-A89 provide annual SSB, recruitment, F-at-age, and January 1
  abundance-at-age through 2017. Recruitment is at true age 0. The report
  provides terminal-year 90% MCMC intervals for aggregate F and SSB, but no
  matched age-specific uncertainty table was recovered.

## Sources

- [66th SAW Summer Flounder Assessment Report (2018)](https://repository.library.noaa.gov/view/noaa/23031/noaa_23031_DS1.pdf)
- [2025 June Management Track Peer Review Panel Report](https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf)
- [NOAA SASINF assessment-data search](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php)
- [2025 Summer Flounder Management Track Assessment Report](https://asmfc.org/wp-content/uploads/2025/08/SF_Management_Track_Assessment_2025.pdf)
- [NOAA Summer Flounder assessment status](https://www.fisheries.noaa.gov/species/summer-flounder/science)

## 2025 update: recovered aggregate trajectories

The 2025 peer-reviewed assessment is separately recorded as
`nefsc_summer_flounder_2025`. NOAA Stock SMART assessment 13936 provides annual
catch, SSB, fully selected F at age 4, and age-0 recruitment for 1982–2024.
All 2014–2024 values agree with Table 1 of the assessment report. The table
also supplies commercial and recreational landings and discards for those
11 years. These components overlap the total catch and must not be fitted
as an additional fleet. F values were rounded to three decimal places to
remove binary storage noise. Uncertainty was not inferred from plotted bands.
The latest run's age-specific inputs and outputs remain unavailable; the 2018 age-based record remains separate.

The report, peer review and pinned Stock SMART snapshot are cached locally
under `source_cache/nefsc_summer_flounder_2025/`. The importer verifies SHA-256
checksums and the report overlap. [2025 report](https://asmfc.org/wp-content/uploads/2025/08/SF_Management_Track_Assessment_2025.pdf),
[peer review](https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf),
[Stock SMART snapshot](https://github.com/NOAA-EDAB/stocksmart/tree/664c4237e26520b260a090e1821a2cee5d1cdf07).
