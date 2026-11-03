# Atlantic mackerel source review

## Assessment represented

The canonical database represents the 2018 64th Northeast Regional Stock
Assessment Workshop (SAW-64) final ASAP Run 118 as the latest official detailed
assessment with recoverable age-specific inputs and outputs. It covers
1968-2016. The September 2025 management-track update is recorded separately:
its published summary gives aggregate SSB, fully selected F, and age-1
recruitment for 2015-2024, but the cached package contains no age-specific input
tables or fitted age surfaces. Those summary values are not substituted into
the 2018 time series.

The 2018 assessment PDF and extracted text are cached under
`source_cache/nefsc_atlantic_mackerel_2018/`; the 2025 materials are under
`source_cache/nefsc_atlantic_mackerel_2025/`.

## Database records and translation choices

- Table A28 supplies combined U.S.-Canadian catch at ages 1-10+, in thousand
  fish. Table A33 supplies the combined catch/SSB weight-at-age used for the
  SSB basis. These weights are the appropriate recovered weights for an SSB
  comparison; they are distinct from Table A34 January-1 weights. The source
  weighted regional values by catch, used U.S. weights as the whole-stock proxy
  in 1968-1978, and filled age-years with zero catch using the 1992-2016 mean.
- Table A4 supplies annual Canadian maturity-at-age ogives for the northern
  spawning contingent. This surface is applied to the combined-stock numbers
  in the tinyAM translation, as in the recovered assessment inputs.
- Tables A38-A39 supply the spring trawl numbers-at-age. The full published
  ages 1-10 are retained in the database; the final ASAP model uses ages 3-10
  for Albatross and ages 3-7 for Bigelow. The translation applies a constant
  timing of 95.7/365, based on the report's time-series mean survey day. This is
  a timing approximation, not annual survey dates.
- Table A40's 17 reported range-wide egg/ichthyoplankton SSB observations are
  stored as aggregate biomass-index data. They are omitted from the tinyAM fit
  because tinyAM requires an age-specific index and no age composition is
  available to allocate these values.
- Tables A42-A45 provide official SSB, January-1 and exploitable biomass,
  numbers-at-age, F-at-age, Fbar, and the time-constant selectivity schedule.
  M=0.2 per year is fixed in the assessment, not estimated; the database stores
  that explicit assumption and its implied age-year surface separately from
  fitted outputs.

## tinyAM fit and comparison

The stock recipe fits 1968-2016, ages 1-10+, with an IID N process, AR1 F
deviations around an age-specific mean, fixed M=0.2, one lognormal catch
observation error, and separate catchability by survey-age. The official model's
time-constant fishery selectivity and its catch and age-composition likelihoods
are not represented directly. The aggregate egg SSB index is also omitted.
Accordingly this is a simplified comparison model, not a reproduction of ASAP.

The fit converged (optimizer code 0, relative convergence), with maximum
absolute gradient 0.00066, successful sdreport, and a positive-definite Hessian.
The terminal-year trajectory comparisons are strong for several quantities
(SSB trend correlation 0.95; N-at-age aggregate 0.88), but scale differences
remain material: terminal SSB is about 29% lower and terminal Fbar about 35%
higher in tinyAM. Recruitment comparisons use age 1 on both sides and have a
more modest trend correlation (0.61). M matches exactly by construction because
both models use fixed M=0.2; that agreement is not an independent validation.
These differences should be read alongside the structural approximations
above.

## Sources

- [SAW-64 Atlantic mackerel assessment, NEFSC Reference Document 18-06](https://doi.org/10.25923/swk4-1e81)
- [2025 Atlantic Mackerel Management Track Assessment materials, NOAA SASINF](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php)
- [NOAA Atlantic mackerel science and current status](https://www.fisheries.noaa.gov/species/atlantic-mackerel/science)
