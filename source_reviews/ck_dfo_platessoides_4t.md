# Southern Gulf of St. Lawrence 4T American plaice

## Assessment records

The most recent full assessment is the March 2016 VPA, published as DFO Research Document 2016/057. The later 2024 indicator update, published in 2025 as Science Response 2025/010, is recorded separately: it reports a survey-derived biomass indicator and does not replace the 2016 population assessment. No later detailed population-model run was identified.

## Sources and cached copies

- DFO Research Document 2016/057, *Assessment of the southern Gulf of St. Lawrence (NAFO Division 4T) stock of American plaice*: https://waves-vagues.dfo-mpo.gc.ca/Library/365839.pdf
- DFO Science Response 2025/010, *Gulf of St. Lawrence NAFO Division 4T American Plaice ... Stock Indicators to 2024*: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf

PDFs and text extractions are cached under `source_cache/dfo_american_plaice_4t_2016/`. The local `sources.csv` manifest records retrieval dates and checksums. The 2016 report describes the production model and its parameterization; no separate framework document, native ADMB inputs, or fitted object was located in the reviewed sources.

## 2016 assessment inputs and model

The source VPA covers 1976–2015 and ages 4–16+, with age 16 as the plus group. The database retains commercial catch-at-age including estimated discards, the DFO research-vessel survey index, the mobile-gear sentinel survey index, January 1 population weights-at-age, and annual maturity-at-age. The catch and survey age values are reported in thousands of fish; weights are kg/fish and maturity values are proportions. The September surveys use a 0.75 sampling-time value for tinyAM preparation, documented as a within-year approximation because the annual sampling dates are not reported.

The RV survey table reports `NA` for every age in 2003. The later indicator report explicitly says 2003 survey data were omitted because an uncalibrated vessel was used. That year is therefore absent from the RV numeric index rows. The mobile-gear sentinel index covers 2003–2015 and uses age-length keys from the corresponding RV surveys.

Table 5 reports a 2003 age-16+ weight of 0.000 kg/fish. This literal value is retained in the database and flagged as unresolved because the report does not say whether it represents a lack of observations or was supplied to the VPA as zero. It is not replaced or interpolated.

The source estimates separate log-scale M random walks for ages 4–9 and 10+. Their annual log increments have mean zero and fixed SD 0.075. Initial-M prior means are 0.6 and 0.3, respectively; their prior SDs are not stated. The lognormal abundance-index likelihood estimates separate age-specific q and observation-error variances for each survey. Catch-at-age is an input to the VPA, not a catch-observation likelihood. The VPA is implemented in ADMB. The report describes 144 estimated parameters and reports parameter and population estimates as medians of 5,000 retained MCMC samples.

Table 6 uses median post-1996 maturity-curve coefficients for 1976–1996. Because recent maturity coding was considered unreliable, the 2012 proportions were carried forward through 2015. Weights are adjusted from the September survey to the model's January 1 population state.

## Outputs and remaining gaps

The database contains the complete 1976–2015 N-at-age table, plus total abundance and age-4 recruitment derived from that table without uncertainty. Annual SSB medians and 95% credible intervals are digitized from Figure 23 (printed p. 41); values are converted from kt to t. The 2015 median uses the exact 55,023 t value stated in the report, while its interval is digitized from the figure.

Figure 21 (printed p. 39) provides annual median M and F for ages 4–9 and 10+. The two M series and their visible 95% credible intervals are digitized. The F 4–9 point series is digitized for 1976–2015; the F 10+ series is retained through 2008, after which its near-zero line cannot be separated reliably from the other series. Three M 4–9 points (1993, 1997, and 2005) are also obscured and omitted rather than interpolated. The figure does not show separable F credible-interval bands, so F uncertainty remains blank. Figure-based values are approximate at the PDF raster resolution. Age-specific q and survey-error estimates are not tabulated. The outputs remain partial because some mortality points and model parameters are unavailable.

The 2024 indicator update reports a three-year moving average of survey-derived biomass for fish at least 30 cm long: 1.25 kg/tow for 2024. This is not SSB and is stored only on its separate indicator-update record.

The 2016 source input streams are represented, but complete model assumptions and outputs remain partial because the native fit, full parameter estimates, and annual F, M, and SSB values are unavailable.

## tinyAM translation

The first translation uses the source years 1976–2015 and ages 4–16+, with commercial catch, both abundance indices, source weight and maturity surfaces, and estimated-M age groups. tinyAM's population and fishing-mortality processes and its catch likelihood simplify the VPA; it does not reproduce the source's VPA catch equation, M random-walk priors, age-specific q and observation-variance parameters, or MCMC integration. The 2003 RV index remains omitted. The 2003 age-16+ zero weight is preserved as supplied when preparing observations and will be evaluated as a potential source limitation rather than silently changed.

The first fit used package-default initialization, with no explicit starting values. It passed the numerical convergence checks (optimizer code 0, maximum absolute gradient 0.00139, successful standard-error calculation, positive-definite Hessian). Comparing the cached fit with the newly recovered outputs gives mean absolute percent differences of about 661% for N-at-age, 66% for total abundance, 89% for age-4 recruitment, and 90% for the digitized native SSB series; trend correlations are 0.865, 0.947, 0.944, and 0.962, respectively. The grouped mortality comparison uses official-N-weighted means of tinyAM ages. F has about 70% mean absolute percent difference, a -91% terminal difference, and 0.914 trend correlation; M has about 66%, a -76% terminal difference, and 0.453 trend correlation. These figure-based rate comparisons are approximate and F coverage is incomplete. The fit is numerically usable, but its mortality and population scale do not closely reproduce the VPA.
