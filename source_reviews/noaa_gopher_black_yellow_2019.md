# Gopher and Black-and-Yellow Rockfishes — 2019

## Assessment unit and run

The current unit is Gopher and Black-and-Yellow rockfishes south of 40°10′ N latitude, from Cape Mendocino to the US-Mexico border. The two species are represented in one combined benchmark assessment, not as separate assessment rows. The 2025 Groundfish SAFE lists 2019 as the latest assessment for this unit. The post-STAR Stock Synthesis model uses data from 1916–2018 and includes a 2019 forecast.

## Inputs recovered

The cached post-STAR files provide annual catch biomass for three fishery fleets, six aggregate lognormal indices, number-based length compositions, conditional age-at-length samples, fixed natural mortality, growth and maturity specifications, and control-file composition variance adjustments. The index records are all from month 7 (timing 0.5); five are relative-abundance indices and PISCOage0 is an age-0 recruitment index. The composition observations remain distinct from abundance indices. Catch-at-age and age-specific abundance indices are not supplied, and no defensible reconstruction of catch-at-age was recovered.

The model has one area, one model sex, one annual season, ages 0–28 with age 28 as the plus group, and fixed M of 0.193 per year. Growth uses estimated von Bertalanffy parameters with a fixed weight-length relationship. Maturity is a fixed logistic function of length. Model-derived weight-at-age is available in the fitted report; no separate empirical weight-at-age or numeric maturity-at-age input vector was located.

The native age-error values are retained at their supplied scale. The report describes reader standard deviations from 0.74 years at age 0 to 2.07 years at age 28, which do not match the native vector endpoints. The relationship between these values remains unresolved.

## Outputs and remaining gaps

The post-STAR Report.sso supplies beginning-of-year N-at-age and biomass-at-age, fishery-specific F-at-age, M-at-age, model-derived weight-at-age, and annual total biomass, spawning biomass, and age-0 recruitment. Total abundance is calculated by summing the reported N-at-age surface and is identified as a derived output. Table i supplies approximate 95% intervals for recruitment and depletion in 2010–2019. No age-specific uncertainty was found.

The report's output labels conflict: Report.sso and Table 28 identify SpawnBio as spawning biomass in metric tonnes, while the narrative and Tables b/i call the same numeric series spawning output in million eggs. The database preserves the model and Table 28 scale as reported and does not assign the Table b/i interval to the mass-scale series. The source record is therefore partial; missing catch-at-age, age-specific survey indices, and biological vectors are not inferred from fitted model states.
