# Pacific chub mackerel, Pacific Coast

## Official assessments and sources

The 2025 Council-adopted catch-only update is the current assessment used for
advice. It updates the catch series through model year 2023 and forecasts
catches through 2026. Section 5 of the report states that the non-catch data
and model structure are unchanged from the 2023 benchmark. The 2025 report
does not provide a new native model archive.

The 2023 benchmark is therefore recorded separately as the detailed source of
the inherited age-composition, survey and biological inputs, and of the
available fitted age surfaces. Its Stock Synthesis 3.30.20 model covers
2008–2021. The reports and native archive are cached under
`source_cache/discovery_noaa_pacific_mackerel_2025/`; source URLs, retrieval
dates and checksums are in the adjacent provenance manifest. Checksums for the
extracted native files are recorded in
`provenance/noaa_pacific_mackerel_2023_model_files.csv`.

## Inputs

The model uses one fishery and one summer Acoustic-Trawl survey. Model years
run July through June, ages are 0–8+, and the fitted model has one sex. The
native age-composition records use the combined-sex code. Fishery compositions
are available for 13 years from 2008–2021 (excluding 2020); survey compositions
are available for nine years from 2012–2021 (excluding 2020). Their native
sample-size field is the supplied likelihood `Nsamp`, not a raw fish count.
Age 8 is the 8+ group. Fishery compositions are timed at model month 7; the
survey composition and index use model month 1.6, or 0.05 of the model year.
With July-June model years, month 7 is 0.5 of the model year and falls in
January.

The native 2023 model has aggregate fishery catch biomass for 2008–2021 in
metric tonnes and a log-catch standard error of 0.01. The 2025 report supplies
rounded catch totals for 2008–2023 and forecast catch for 2024–2026. Those
rounded values are retained as published, rather than substituted for the
unrounded benchmark inputs.

The Acoustic-Trawl survey has ten biomass-index observations (2008, 2012–2019
and 2021) with supplied CVs. Stock Synthesis identifies the index as biomass
scale, but the physical unit multiplier is not stated in the data file; the
database therefore preserves the native relative index scale. The 2025 report
confirms that the series was carried forward unchanged.

The native archive provides fishery, survey and population weight-at-age for
ages 0–8+ in 2008–2021. It also contains an age-specific maturity-times-
fecundity surface. The archived control and report identify the model's
maturity option as disabled. The sample-based maturity proportions in the
2023 report are not treated as a fitted maturity input. Natural mortality has
a Lorenzen age pattern; its average parameter is estimated with a
longevity-based prior.

## Outputs and remaining gaps

The 2023 `Report.sso` supplies beginning-year numbers-at-age and biomass-at-age,
annual F-at-age and M-at-age for 2008–2021, plus SSB and age-0 recruitment.
These are point estimates; age-specific and annual uncertainty is not
available in the report tables. The average natural-mortality parameter is
reported as 0.8512 per year with SE 0.1074.

For the current 2025 update, Table 5 reports age-1+ biomass for 2020–2026:
69,823, 50,282, 45,898, 51,060, 58,301, 61,737 and 67,954 mt. The report gives
standard deviations of 41,422 mt for 2025 and 43,375 mt for 2026; these are
stored as SDs, not SEs. The current-run report does not provide numerical
N-at-age, F-at-age or M-at-age surfaces, so the 2023 fitted surfaces are not
represented as outputs of the 2025 assessment.

Both assessment records remain partial. Unresolved items include the physical
unit multiplier for the survey biomass index, the lack of current-run
age-specific population outputs and their uncertainty, and the absence of a
standalone fitted maturity-at-age input.
