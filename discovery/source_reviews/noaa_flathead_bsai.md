# BSAI Flathead Sole assessment

## Assessment and source run

NOAA Stock SMART identifier 10015 refers to the Bering Sea/Aleutian Islands flathead sole assessment. The managed complex includes flathead sole (*Hippoglossoides elassodon*) and Bering flounder (*Hippoglossoides robustus*). Fishery catch is combined across the two species, while the age-composition samples are flathead sole only; this remains one assessment case.

The latest detailed production run located is the 2024 operational update, Model 18.2c using Stock Synthesis 3.30.22, with a final run dated 2024-10-23. The 2024 SAFE chapter is [BSAI Flathead Sole](https://files.npfmc.org/SAFE/2024/BSAIflathead.pdf). The model files are pinned to repository revision `8db5b6c505841aedc4b44c3cac5f85813ddebf94` under `source_cache/noaa_flatfish_screening_20261029/bsai_fhs_2024_final_model/`. The previously cached revision `bafa7658d31e0b99fe11d626a58e1c01807c69ee` is an earlier, superseded snapshot and is not used for the imported record. File URLs, retrieval date, sizes and SHA256 checksums are recorded in `provenance/noaa_flatfish_screening_20261029/sources.csv`.

The run is an operational update of the accepted 2020 configuration with updated data. It has a reported convergence level of 0 and objective 1766.68. The 2026 SAFE material located is a management projection, not a newer full assessment.

## Original inputs and assumptions

The final native input file covers 1964–2024, one BSAI area, two sexes and one annual season. It contains 61 annual combined-species fishery catches in tonnes plus an initial-equilibrium catch sentinel coded as year -999. The sentinel is retained with no calendar year. The aggregate trawl-survey biomass index is in tonnes and has 42 observations from 1982–2024. Survey observations are in July, represented by model timing 0.5; the catch observations are annual.

The input has 21 observed ages (1–21), with age 21 as a plus group, and 24 length-bin labels. It contains 1,202 age-composition rows and 92 length-composition rows:

- Survey age samples are conditional age-at-length frequencies by sex (635 female and 515 male rows). Values are native frequency counts, and the likelihood sample size, age-error code, partition and conditioning-bin labels are retained. These samples are not age-specific abundance indices.
- Fishery marginal age samples comprise 19 active rows for flathead sole only. Thirty survey and three fishery age rows have negative fleet codes and are retained as diagnostic rows, not active likelihood observations.
- Length compositions retain the supplied joint-sex proportions and sample sizes for survey and fishery, including negative-fleet diagnostic records.

The final model has no observed catch-at-age and no age-specific survey abundance index. Catch totals cannot be expanded to catch-at-age from the single-species composition samples without inventing an allocation. The aggregate survey index and conditional age samples therefore remain distinct source inputs.

Natural mortality is fixed at 0.2 per year for both sexes and ages 0–21. Female maturity is fixed to an age-logistic curve with first mature age 3, Mat50 9.70203 and slope -0.942711. The reconstructed maturity-at-age values match `Mat_F_Natage` in the report; `Mat_F_wtatage` is a different, weight-multiplied quantity. Sex-specific growth is estimated with cohort growth deviations, while the weight-length relationship is fixed at `kg = 2.98e-6 * cm^3.3268`. The archived `wtatage.ss_new` surface is model-generated weight-at-age, not a supplied biological input.

Fishery selectivity is length-based and survey selectivity is age-based. Recruitment follows Beverton–Holt with steepness 1 and sigmaR 0.5 fixed; the main recruitment deviations cover 1973–2020. The report gives effective sample-size multipliers of 0.079018 and 0.062439 for fishery and survey length compositions, and 0.085811 and 0.481957 for fishery and survey age compositions, respectively. Survey catchability is fixed at q=1 with no additional survey CV.

## Outputs and limits

`Report.sso` provides fitted historical values through 2024 and a separate Stock Synthesis forecast for 2025. It includes total biomass, age-3+ biomass, spawning biomass, age-0 recruitment, numbers-at-age, biomass-at-age, fishing mortality-at-age and model-estimated catch-at-age. Population surfaces include ages 0–21, with age 21 as the plus group. Numbers-at-age are in thousand fish; biomass surfaces are in tonnes. Summing N-at-age by sex and multiplying by the matching kilogram-per-fish weights reproduces annual all-age biomass within report rounding. Total abundance is derivable from the reported N-at-age surface, but has no separate uncertainty estimate. Age-specific output uncertainty is unavailable in the cached run files. Fixed M is an assumption, not an estimated mortality trajectory.

The October 2024 `alt_proj.out` file contains seven distinct management-projection alternatives through 2038, each with catch, ABC, OFL, SSB and total biomass. The alternative numbers are retained in the output scenarios. These values must not be confused with the one-year 2025 Stock Synthesis forecast in `Report.sso`. The accompanying `means.out` and `percentiles.out` contain seven alternative blocks, but the selected alternative and interval coverage are unresolved; their values are not labelled as 95% intervals or standard errors. 

## Curation status

The source import preserves verified native observations, biological assumptions, output surfaces, units, species distinctions, signed fleet codes and pinned provenance. It is partial because the assessment does not provide observed catch-at-age or an age-specific survey abundance index, and age-specific output uncertainty is unavailable. No values are reconstructed from fitted parameters or assigned to missing input series.