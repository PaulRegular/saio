# NOAA Cowcod, Southern California Bight, 2019

## Assessment unit and source run

The 2019 assessment covers Cowcod (*Sebastes levis*) in the Southern California Bight, south of Point Conception. The assessment report and native Stock Synthesis archive are the latest detailed run located for this current unit. The model is Stock Synthesis 3.30.13.09, uses data through 2018, and reports a 2019 terminal-year estimate. The report's separate northern-area sustainable-yield appendix is not part of this stock assessment.

Sources cached locally under the ignored `source_cache/discovery_noaa_cowcod_california_2019/` directory:

- [2019 assessment report](https://www.pcouncil.org/documents/2019/10/status-of-cowcod-sebastes-levis-in-2019-october-24-2019.pdf)
- [2019 Stock Synthesis model files](https://www.pcouncil.org/documents/cowcod-2019-ss-model-files-zip-file/)

Retrieval dates, file sizes and SHA-256 checksums are recorded in `provenance/noaa_cowcod_southern_california_2019/manifest.csv`.

## Inputs recovered

- The native data file contains two annual fishery catch series, commercial and recreational, in metric tonnes for 1900–2018. One `-999` placeholder row is not a calendar-year observation and is excluded from the canonical series.
- It contains 57 survey observations from six fleets for 1953–2018, with January and July timing and log-scale observation SDs. The model report describes four relative-abundance series and two absolute visual-survey biomass estimates from 2002 and 2012. The canonical records preserve 41 relative-index observations, 14 CalCOFI larval-index observations, and two absolute biomass observations as distinct measures. The visual-survey values use Stock Synthesis CPUE unit code 1, which denotes biomass in metric tonnes; the relative series retain their native index scale.
- It contains 60 length-composition strata for 1973–2018 (37 active and 23 marked unused with negative years), using 2-cm source bins labelled 6–98 cm.
- It contains 438 conditional age-at-length strata for 1975–2017 (425 active and 13 marked unused), with ages 0–60, source length bounds and age-error codes 1 or 2. These are conditional composition samples, not marginal catch numbers-at-age or age-specific abundance indices.
- The native archive provides the control specifications for growth, maturity, fecundity and mortality. The model uses one modeled female sex. Natural mortality is estimated, with the report giving M = 0.088 per year (SE 0.011); steepness is fixed at 0.72. Composition likelihood weights and the source's parameter estimates are reported in Table 49–50.

The canonical import preserves the observations in their source forms. It does not turn total catch and conditional age-at-length samples into observed catch-at-age.

## Outputs recovered and limits

`Report.sso` provides beginning-year numbers-at-age, biomass-at-age, natural mortality-at-age, fleet-specific fishing mortality-at-age, model-generated dead catch numbers-at-age, recruitment and spawning output for 1900–2018. Total abundance is derived by summing reported N-at-age and has no separately reported uncertainty. The report gives 2019 spawning output of 163 billion eggs with 95% asymptotic limits of 130–195 billion eggs. The archive's single-sex `SpawnBio` values are approximately twice the report scale; the imported annual series is divided by two, matching the report's stated plotting convention and Table E after rounding (the 2019 output is 163 billion eggs).

Spawning output is measured in eggs, not conventional spawning-stock biomass in tonnes. The annual series is reported on the official report scale after dividing native `SpawnBio` by two. The archive has no fitted parameter or covariance file, so uncertainty for age-specific surfaces and annual trajectories is unavailable from the cached native files. The 2019 summary interval is retained from the official report. No age-specific catch or survey abundance observations are reported as native model inputs.

## Completeness

Source recovery is partial. The input archive and detailed fitted surfaces support a documented canonical record, while direct catch-at-age and age-specific abundance indices are not input observations in this assessment. Biological quantities are available through the model's fitted growth, maturity and fecundity relationships rather than as complete original age-specific input tables. Assessment outputs with uncertainty are limited to the values explicitly tabulated in the report.
