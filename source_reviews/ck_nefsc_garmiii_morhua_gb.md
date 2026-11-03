# Georges Bank and South cod: SAW55 benchmark

## Assessment and stock boundary

The blank catalogue record `ck_nefsc_garmiii_morhua_gb` represents the
Charbonneau–Keith entry `NEFSC-GARMIII_morhua_GB`. The 2012 SAW55 assessment
reports the historical unit as Georges Bank and South (NAFO Division 5Z and
Subarea 6). This is the earlier, wider unit; it is not interchangeable with
the revised Georges Bank stock assessed in 2024 and stored as
`nefsc_cod_georges_bank`.

The detailed SAW55 report identifies the Base ASAP run as the final selected
benchmark. The later 2015 operational update is not imported into this event.
The 2015 peer review describes problems with that update and points to the
SAW55 benchmark as the best available information for status. This later
context does not turn the 2012 run into a 2015 assessment.

## Inputs recovered

The selected model covers 1978–2011 and ages 1–10+, with one combined fishery.
The database retains 340 catch-at-age values, 34 total catch biomasses, 34
assumed catch CVs, 340 catch weights-at-age, 340 January 1 stock weights,
340 female maturity values, and fixed M=0.2 for ages 1–10+. Catch-at-age and
stock weights use thousand fish and kilograms per fish, respectively. The
female ogives use the report's centered five-year moving window.

The three survey streams retain their original survey years and ages:

- NEFSC spring: ages 1–10+, 1978–2011, split into Yankee 41 (1978–1981) and
  Yankee 36 (1982–2011), with 340 age-specific values in total.
- NEFSC autumn: observed ages 0–5, 1977–2011, with 210 age-specific values.
  The assessment advances these observations one year and one age to align
  cohorts with January population states.
- DFO February: ages 1–10+, in 1986–1992, 1995–2004, and 2006–2011, with 230
  age-specific cells. Five source dashes remain missing. The 1993, 1994 and
  2012 series are excluded because the full Bank was not surveyed; the 2005
  R/V Teleost series is excluded because the R/V Needler index was unavailable.

Aggregate abundance indices and their CVs are retained alongside the age
series. The NEFSC CVs are converted from percent to ratios and increased by
0.20; DFO CVs are already ratios and increased by 0.10. The imported values
therefore match the assessment's documented annual CV adjustments. Survey
sampling fractions are DFO 0.16, NEFSC spring 0.25, and NEFSC autumn 0.75.
Age-composition effective sample sizes are DFO 9, autumn 14, spring Yankee 41
40, and spring Yankee 36 37.

The report describes multinomial age compositions, lognormal total catch and
survey indices, two fishery selectivity blocks (1978–1993 and 1994–2011),
logistic spring and DFO survey selectivity, and age-specific autumn
selectivity with age 3 fixed at 1. Recruitment deviations are constrained to
sum to zero with lambda=0. The age-varying Lorenzen M alternative was not
selected; the model uses M=0.2 for every year and age.

## Outputs and limitations

Tables B23a–B23b provide annual January 1 biomass, SSB, Fbar, recruitment,
total abundance, N-at-age and F-at-age for 1978–2011. Total abundance is taken
from the printed total row; its difference from summed rounded N-at-age is at
most 3 thousand fish. The report also gives retrospective-adjusted terminal
SSB, F and recruitment, which are stored separately from the unadjusted
annual series.

Only unadjusted 2011 SSB and F have published 90% MCMC probability intervals.
They are retained as limits without reconstructing standard errors. The
assessment's assumptions and output completeness statuses remain **partial**:
the report does not provide the full parameter phases, exact q configuration,
or complete age-specific uncertainty arrays. Inputs are marked **complete**
for the numerical observation and biological arrays documented for the
selected run; this does not imply that every model setting has been recovered.

No tinyAM translation or fit is included in this database import. No data from
the revised 2024 Georges Bank assessment have been copied into this record.

## Sources and cache

- [2012 SAW55 assessment report, especially the cod assessment and Tables B12,
  B14–B17, B23a–B23b](https://repository.library.noaa.gov/view/noaa/4432/noaa_4432_DS1.pdf).
- [2012 SAW55 assessment summary](https://repository.library.noaa.gov/view/noaa/4330/noaa_4330_DS1.pdf).
- [2015 NEFSC review](https://repository.library.noaa.gov/view/noaa/5293/noaa_5293_DS1.pdf),
  used only to review later assessment status.

The 2012 report and summary are cached in the gitignored
`source_cache/ck_nefsc_garmiii_morhua_gb_2012/` folder with retrieval dates,
URLs and SHA-256 hashes. A direct download of the 2015 review returned Access
Denied; it is recorded as unavailable in the local cache manifest and was not
used to extract numerical data.
