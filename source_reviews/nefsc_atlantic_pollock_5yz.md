# Atlantic pollock (5YZ)

## Official assessment and source selection

The stock record is `ck_nefsc_virens_5yz` (Charbonneau–Keith identifier `NEFSC_ virens_5YZ`), Atlantic pollock (*Pollachius virens*) in the NOAA 5YZ assessment area. The assessment used here is the 2024 Management Track update, fitted through 2023. The final NOAA peer-review panel report found the assessment technically sufficient and best scientific information available. Its SASI base run is Run10.

The native ASAP3 input and output files are the most complete record of the fitted run. The 2024 assessment report in SASI is marked draft and is used only to clarify and cross-check model details. The 2026 SASI item is a data/projection update, not a later age-structured assessment, so its values are not mixed into this record. The local source cache and checksums are recorded in `source_cache/nefsc_pollock_5yz_2024/manifest.csv`.

## Model inputs

The official model has 54 calendar years (1970–2023), ages 1–9+, one sex-combined stock and one combined fishery. The fishery has six age-specific selectivity blocks. Commercial catch and dead discards are separate source streams. Catch numbers-at-age are in thousands of fish for 1970–2023; dead-discard numbers-at-age are present from 1981–2023. Their total biomass observations are in metric tons, with separate model CVs and effective sample sizes. The annual total-catch CV is 0.05 and its composition ESS is 26; the discard ESS is 14.

The fitted inputs fix natural mortality at 0.20 yr-1 at all ages. Maturity is fixed over time at ages 1–9+ as 0.088, 0.293, 0.640, 0.884, 0.970, 0.993, 0.998, 1, and 1. Three annual weight-at-age matrices are retained: matrix 1 for catch and discards, matrix 2 for spawning biomass, and matrix 3 for January 1 biomass and all survey weights. The spawning fraction is 0.0, so the reported SSB is at the start of the year.

Four of five survey indices are active: Albatross spring (1970–2008), Bigelow spring (2009–2022, excluding 2020), Albatross fall (1970–2008), and Bigelow fall (2009–2023, excluding 2020). The summer index in the native input file is explicitly inactive. All indices use biomass-scale aggregate observations and age-specific biomass-scale inputs for ages 1–9+. Aggregate CVs and composition effective sample sizes are retained separately. The native start-of-month codes identify April spring surveys and October fall surveys, represented as within-year times 0.25 and 0.75.

## Reported outputs and limits

The native output file supplies January 1 N-at-age, directed and discard F-at-age, and annual January 1 biomass, SSB, and exploitable biomass. Total F-at-age is stored as directed F plus discard F. The reported Fbar is an unweighted mean over ages 5–7. Total abundance is derived by summing the reported N-at-age values; recruitment is represented by age-1 abundance in the same year. These derived quantities have no added uncertainty. The native output file does not provide complete time-by-age uncertainty surfaces, so the output record is partial and no age-specific standard errors are invented.

## tinyAM translation choices

The translation combines catch and dead-discard numbers-at-age into one total-removals series. It uses the four active survey series and source survey timing, but approximates the source's biomass-index/composition likelihood as age-specific abundance indices. The model uses one F process in place of ASAP's six selectivity blocks and estimates survey-by-age q effects in place of the source survey-specific annual q deviations. It also uses tinyAM's own process and observation-error structures. The source totals, age compositions, biological surfaces, and official outputs remain unchanged in the canonical database; transformations for fitting are performed only in the stock translation script.

## tinyAM fit status

The 2026-10-21 fit did not pass numerical convergence checks. The package-default initialization returned optimizer code 1 (`false convergence (8)`), objective 3154.205, maximum gradient 168,801, and a non-positive-definite Hessian with non-finite fixed-parameter covariance. The single policy-permitted retry with year- and age-aligned source N and F starts also failed: optimizer code 1, objective 3140.939, maximum gradient 5.57 billion, NA/NaN function evaluations, and a non-positive-definite Hessian. An exploratory dashboard was rendered from that failed fit for inspection only; its large differences are not a valid agreement result. The fit and attempt diagnostics are cached locally under `results/cache/nefsc_pollock_5yz_2024/`.

## Sources

- [Final September 2024 Management Track peer-review panel report](https://www.fisheries.noaa.gov/s3/2024-10/2024-Management-Track-Peer-Review-Panel-Report_10_8_24_508.pdf)
- [Official ASAP3 input file](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=7&stock_id=6&review_type_id=3&info_type_id=3&map_type_type_id=&map_type_id=&filename=2024_POK_UNIT_MOD_BaseASAPInput.dat)
- [Official ASAP3 output file](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=7&stock_id=6&review_type_id=3&info_type_id=3&map_type_type_id=&map_type_id=&filename=2024_POK_UNIT_MOD_BaseASAPOutput.rep)
- [2024 pollock update report (draft; supporting details only)](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=7&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&filename=2024_POK_UNIT_RPT_Update_2024_09_20.pdf)
- [2026 data and projection update](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=7&stock_id=6&review_type_id=7&info_type_id=-1&map_type_id=&filename=data_projection_update_pollock_20260817.pdf)
