# Northeast Arctic saithe source review

## Assessment and provenance

The current detailed assessment is the 2026 ICES assessment of Northeast
Arctic saithe (*Pollachius virens*), stock code `pok.27.1-2`, in ICES Subareas
1 and 2. The [ICES Stock Assessment Graphs record, key 22657](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22657)
provides the official annual series and the 2026 short-term forecast. The
[WKBGAD 2024 framework report](https://doi.org/10.17895/ices.pub.25002470)
documents the SAM model framework and its biological assumptions.

The native assessment files are hosted in the
[NEA_saithe_2026_v2 run directory](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NEA_saithe_2026_v2/).
The run identifies `stockassessment` 0.12.0 and RemoteSha
`1cc464b80f6f`. Four public run versions were cached; v2 was selected because
its fitted 2025 recruitment, SSB, Fbar and total biomass reproduce the ICES
SAG estimates at the published precision. The model object, input object,
configuration, input files and HTML output tables are cached locally in the
gitignored `source_cache/ices_nea_saithe_2026/` directory. Its manifest records
retrieval dates, URLs, byte counts and SHA-256 checksums; the source servers do
not provide a verified last-modified date for these downloads.

## Inputs and assumptions recovered

The fitted run covers 1960–2025 and ages 3–12, with age 12 as the plus group
and age 3 as recruitment. It has one combined catch fleet and two separate
Norwegian acoustic series: FLT13 for 1994–2001 and FLT14 for 2002–2025. Both
surveys use a sampling time of 0.8 and observe ages 3–7. Catch numbers are in
thousand fish. The acoustic series remain on their source index scale; a
physical unit was not reported.

The database preserves annual stock weight, catch weight, landings weight,
discard weight, maturity, landings fraction and fractions of fishing and
natural mortality before spawning for ages 3–12. Weights are in kg per fish;
maturity and fractions are proportions. Landings and discard weights equal
catch weights in this run, the landings fraction is 1, and both mortality
fractions before spawning are 0. Natural mortality is fixed at 0.2 per year
for every modeled age. It is an input, not an estimated output.

The native data object contains 660 catch observations, 40 FLT13 observations
and 120 FLT14 observations. It also contains 110 finite relative precision
weights for FLT14 ages 3–7 in 2003–2024. With `fixVarToWeight = 0`, SAM divides
the log-observation SD by the square root of each weight; rows without a
weight use multiplier 1. The raw StoX CV matrix is preserved separately. Its
values match the fitted weights as a set after the documented CV conversion,
but the year-age pairing does not match the native model weights.

The model uses a Beverton–Holt stock-recruit relationship with a three-year
lag. Age-3 recruitment and ages 4–12 survival innovations have separate
variances; survival innovations are independent across ages. Initial N states
have no process-density contribution. Fishing mortality follows a random walk
on log F, with AR(1) correlation across age increments and one process
variance. Ages 3–7 have separate F states; ages 8–12 share one state. The
model uses lognormal observations, a shared catch SD with a prediction-variance
link, independent FLT13 age errors, and AR(1) FLT14 age errors. Survey q is
survey-specific: ages 3, 4 and 5 have separate values, while ages 6–7 share a
value.

## Additional source details

The native run supplies annual N-at-age and F-at-age, fitted catch and survey
predictions, survey q estimates, and annual recruitment, SSB, Fbar (ages 4–7)
and total biomass. Age-specific N/F standard errors are obtained from the
native TMB report on the log scale and converted to natural-scale standard
errors with the delta method; displayed limits use a normal approximation on
the log scale. These are model-based approximations, not intervals transcribed
from a published age-surface table. The aggregate HTML table's Low/High
columns are retained as given; their interval level is not identified in the
cached table. The 2026 forecast recruitment and SSB are taken from ICES SAG;
age-specific forecast values and forecast intervals are not available.

The source age surfaces allow total abundance to be derived over ages 3–12. Official N, weight and maturity surfaces and zero pre-spawning mortality fractions establish the source beginning-of-year mature-biomass definition.
