# Gulf of Maine/Georges Bank American plaice (5YZ)

## Assessment represented

The latest full native WHAM fit recovered for this stock is the
2022 Research Track candidate Run29F4, covering 1980–2019 and ages 1–10 plus
11+. The cached fit contains its native input and model objects. Run29F4 was
one of three research-track candidates (29F2, 29F4, and 29F5); the available
evidence does not establish which candidate was selected for the management
advice run. The database therefore labels the represented run as a candidate,
and the translation dashboard compares against this run only.

The 2024 Management Track update is later and supplies aggregate commercial
landings, discards, total catch, SSB, recruitment, and Fbar values through
2023. The catch values are transcribed as inputs from Table 1; the rounded
total is stored with its landings and discard components, not as a separate
output or independent observation. The report archive has no age-specific
catch inputs, fitted surfaces, or native model object. Those data and summary
outputs are stored under a separate assessment ID and are not mixed with
Run29F4. The 2026
Management Track report updates the summary through 2025 and is marked
pre-decisional. The September 2026 panel found the 2026 MT3 model technically
sufficient for status and catch advice; its candidate is now the selected
current assessment. The report and its results remain identified as
pre-review material, and management adoption for advice has not been verified.

## Inputs and assumptions

Run29F4 has one commercial catch series. Total catch numbers are in thousand
fish and number proportions-at-age cover ages 1–10 and 11+. The source
effective sample size is 100. The canonical database retains the aggregate
catch and composition as separate inputs; tinyAM reconstructs catch-at-age by
multiplying each annual total by its reported number proportions. The source
aggregate catch error and composition likelihood are not reproduced as
separate tinyAM likelihoods.

Four NEFSC survey series are retained: spring Albatross, spring Bigelow, fall
Albatross, and fall Bigelow. Aggregate biomass indices are in kg/tow; number
compositions use ages 1–10 and 11+ with effective sample size 50. The native
model records a log-scale SD for each year and index. Bigelow indices are not
calibrated to Albatross units. The database includes the survey-specific
weight-at-age series used to translate biomass plus number composition to
age-specific abundance indices.

The age-specific maturity schedule is constant over time. Stock weights and
survey weights retain their original year-age values and pointers. Natural
mortality is fixed at 0.3 per year for all ages; no estimated M output is
available. SSB is calculated at 0.25 of the year.

The model uses age-1 recruitment varying around an estimated mean and
random-effects abundance states, with independent errors and separate
standard deviations for age 1 and ages 2+. The fishery has logistic
selectivity with time-varying selectivity random effects. Run29F4 fixes one
age per survey at full selectivity and has no index-selectivity random effects.
The age-composition likelihood is logistic-normal.

The survey season labels and native timing values disagree for the middle two
series. The recorded values are 0.25, 0.75, 0.25, and 0.75 for spring
Albatross, spring Bigelow, fall Albatross, and fall Bigelow, respectively.
The age-composition tables support the series order, but no source evidence
resolved whether the Bigelow timing values or labels are wrong. The source
values remain unchanged and the tinyAM translation uses those recorded
fractions.

## Outputs and uncertainty

The cached fit reports N-at-age in thousand fish, F-at-age and Fbar in per
year, and SSB in metric tonnes. Fbar is for ages 6–9. The source model's
reported log-scale standard errors are converted to natural-scale marginal
standard errors with the delta method. Recruitment is the fitted age-1 N in
the same year. Total abundance is derived by summing the marginal N-at-age
point estimates; no uncertainty is reconstructed because the exported object
does not provide the cross-age covariance needed for the sum. M is an input,
not a fitted output. Native Fbar is the arithmetic mean of F-at-age over ages
6–9; the dashboard also shows a common N-weighted F mean derived from source
N/F-at-age and tinyAM N/F-at-age, while retaining native Fbar separately.

The 2024 and 2026 summary tables report no numerical uncertainty. The database
keeps their values, years, units, and provenance separate from the detailed
Run29F4 outputs.

## tinyAM translation

The translation fits the full Run29F4 years and ages, retains source stock,
maturity, catch, and survey weight inputs, and uses M = 0.3. It uses IID
recruitment, IID cohort-survival deviations with free initial older ages, and
an AR1 F process around a logistic age mean. q is estimated separately for
each survey and age. Source aggregate index log SDs are applied to every
age-specific index reconstructed for the matching year and survey.

These choices approximate the source model rather than reproduce it. In
particular, tinyAM fits age-specific lognormal catch and survey observations
instead of the source aggregate and composition likelihoods; it does not
propagate age-composition uncertainty, reproduce WHAM's joint random-effects
structure or selectivity constraints, or represent the source's separate age-1
and ages-2+ N process SDs. The later 2024 and 2026 summaries are
not used as input or output references for this fit.

The package default start did not pass checks because its fixed-effect Hessian
was not positive definite (optimizer code 0, adjusted maximum gradient
0.00197). The single permitted retry used source N-at-age and F-at-age aligned
to the model grid. It passed `check_tam()` (optimizer code 0, adjusted
maximum gradient 0.00353, positive-definite Hessian, and successful SD report).
The diagnostics still flag 48 pairs of highly correlated fixed parameters,
some residual groups with unusual spread, residuals above three standard
deviations, and adjacent-year residual correlation. The fit is numerically
usable but these findings warrant caution.

The dashboard's common-definition comparisons over 1980–2019 are: SSB mean
absolute percent difference 19.4%, terminal difference −36.6%, correlation
0.954; total abundance 34.8%, −46.8%, 0.743; N-at-age 38.3%, −40.9%, 0.930;
recruitment 46.1%, −60.2%, 0.852; F-at-age 48.1%, −22.5%, 0.841; and
N-weighted F over ages 6–9 33.4%, +7.9%, 0.956. These statistics describe the
candidate-run comparison and do not establish that Run29F4 was the production
advice model. Fixed M is identical by construction and is only an input check.

## Source cache

The primary reports, native files, and review materials are cached under the
gitignored `source_cache/nefsc_american_plaice_5yz/` and
`source_cache/nefsc_american_plaice_5yz_2024/` folders. The local
`source_cache/nefsc_american_plaice_5yz/manifest.csv` records file sizes,
SHA-256 checksums, local file dates, source URLs, and the pinned repository
revision for the native model objects. Local timestamps are provenance, not
publication dates. The direct endpoint for the cached 2024 archive was not
preserved by the earlier download.

Key sources:

- [2022 American Plaice Research Track peer-review materials](https://www.fisheries.noaa.gov/event/american-plaice-2022-research-track-assessment-peer-review-meeting)
- [2022 model and supporting documents archive](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=2&stock_id=4&review_type_id=5&filename=2022_PLA_GMGB_1.zip)
- [2022 WHAM model repository at pinned revision](https://github.com/ahart1/PlaiceWG2021/tree/be1dbc66ebef7fa2fe2614fee0fe9646051b97c3)
- [2024 Management Track report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9879)
- [2022 WHAM methods paper](https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf)
- [September 2026 Management Track review meeting](https://www.fisheries.noaa.gov/event/peer-review-2026-september-management-track-assessments)

## 2026 peer review and additional records

The [September 2026 peer-review panel](https://www.fisheries.noaa.gov/s3/fileserve?filepath=2026-10/september-2026-management-track-peer-review-panel-report_20261007.pdf)
concluded that MT3 was technically sufficient for stock status and catch
advice and met all terms of reference. It confirms revised 2018–2023
commercial age composition and weights, survey selectivity updates, and
removal of the lognormal adjustment. These details supersede treating the
model itself as unreviewed; the cached source report is still explicitly
pre-decisional. Management adoption has not been independently verified.

The 2026 report's Table 1 supplies commercial landings, discards and total
catch for 2015–2025. The total overlaps the components and is not an extra
fleet. The total catch in 2025 (1,564 t) and reference point estimates match
the peer review. The 90% reference-point intervals in Table 3 are retained.
The 2026 record remains partial: native catch-at-age, survey arrays and fitted
age-specific surfaces were not recovered. It cannot replace the historical
Run29F4 as a model-ready input, and its comparison dashboard remains a
candidate-run comparison. The 2026 assessment ID retains the word
`provisional` for identifier stability, not as its present review status.
