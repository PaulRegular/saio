# Gulf of Riga herring, 2026

## Assessment selected

The selected record is the 2026 official annual SAM assessment, run
`GoR_WGBFAS_2026`, for Gulf of Riga herring (`her.27.28`). Its fitted data end
in 2025. The WGBFAS report uses this assessment for 2027 advice. The 2026 run
is available from the official stockassessment.org directory with its fitted
object, input data, configuration, and R scripts. The cached fit converges
(optimizer code 0; objective 313.7562) and its final estimates match the
assessment report and ICES standard graphs.

The stock was benchmarked from XSA to SAM in 2023. WKBBALTPEL excluded the
trap-net tuning series, updated maturity, and retained one acoustic tuning
series. The 2026 assessment uses the same broad model structure.

## Sources and local cache

- [WGBFAS 2026, ICES Scientific Reports 8:39, section 4.4](https://doi.org/10.17895/ices.pub.32455056), especially Tables 4.4.3–4.4.9.
- [WKBBALTPEL 2023 benchmark report](https://doi.org/10.17895/ices.pub.23216492), including the SAM configuration and model transition.
- [ICES advice for 2027](https://doi.org/10.17895/ices.advice.30932084); its Advice and Scenarios Database record identifies assessment year 2026 and standard-graph key 22423.
- [ICES standard assessment graphs and tables](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22423).
- [Official fitted SAM object](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/GoR_WGBFAS_2026/run/model.RData) and the matching `data/`, `conf/`, and `src/` files.

The PDF and native model files are cached locally at
`source_cache/ck_ices_wgbfas_harengus_bs_28_1/assessment_2026/`.
`source_manifest.csv` records the retrieval date, source URL, assessment name,
and SHA-256 checksum for each cached file. The cache is gitignored. The fitted
object reports `stockassessment` version 0.12.0 and RemoteSha
`1cc464b80f6f`.

## Inputs and assumptions

- Catch-at-age is for ages 0–8+, 1977–2025, in thousand fish (Table 4.4.3).
  The model uses one residual-catch fleet. Its catch series includes Gulf of
  Riga stock catch taken in subdivision 28.2 as described in the report.
- The GRAHS acoustic tuning index is age-specific for ages 1–8+, 1999–2025
  (Table 4.4.6). The report does not state a physical multiplier, so the
  database preserves its native index scale. The SAM survey data specify a
  within-year time interval of 0.65–0.70; the model uses 0.675. The report
  identifies the survey as occurring in August.
- Annual stock, catch, discard, and landings weights are preserved from the
  model data object. The stock-weight surface equals catch weight because
  spawning-time weights were unavailable. The model sets landings fraction to
  one, so its discard and landings weight surfaces do not create additional
  removal streams.
- M is fixed at 0.20 per year except 1979–1983, when it is 0.25 because cod
  were present (WGBFAS 2026, p. 349). Maturity is fixed for 1977–1994 and
  GAM-smoothed annually from 1995 onward based on commercial landings samples
  from January to April (Table 4.4.5).
- The native model uses age-0 recruitment with a random-walk process, separate
  recruitment and survival-process variance groups, an age-correlated F
  process, and a lognormal likelihood for both catch and acoustic index.
  Ages 7 and 8+ share the F state; acoustic catchability shares one parameter
  across ages 3–8. Catch observation SD is separate for age 0 and shared over
  ages 1–8. Acoustic observation SD uses age 1, ages 2–7, and age 8+ groups.
  Catch residuals are independent across ages, while acoustic residuals use
  age-correlated AR(1) groups. Fbar is ages 2–6.
- The exact annual pre-spawning fractions from the model object are retained:
  F is 0.10 through 1998 and 0.20 in 1999–2025; M is 0.30 throughout. The
  2026 forecast inputs are outside the fitted historical assessment and are
  not mixed into the database series.

## Outputs and uncertainty

The database contains SAM numbers-at-age and F-at-age for 1977–2025. The
model-object log-state uncertainty is converted to natural-scale standard
errors with the delta method; these are conditional state standard errors,
not intervals transcribed from the report. Native 95% confidence intervals
are retained for SSB, age-0 recruitment, and Fbar from Table 4.4.9. Total
abundance is additionally derived as the sum of SAM numbers-at-age for ages
0–8+; no uncertainty is assigned to that derived total. Fitted catch and
acoustic predictions are retained from the SAM object.

The 2025 output values match the published summary after report rounding:
SSB about 157,813 tonnes, age-0 recruitment about 2,832,471 thousand fish,
and Fbar ages 2–6 about 0.2252. The report does not provide age-specific
confidence intervals, but the cached SAM object supplies conditional
uncertainty for N and F states.

## Remaining qualifications

The acoustic index multiplier is not stated; its scale is intentionally left
native. The source-model uncertainty for age-specific N and F is conditional
and has been converted to the natural scale with a first-order delta method.
The derived total-abundance series is a sum of the reported age estimates and
has no propagated uncertainty. The 2026–2027 forecast is not an input or
historical model output in this record.
