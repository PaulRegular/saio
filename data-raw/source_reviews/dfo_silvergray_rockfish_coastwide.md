# British Columbia coastwide Silvergray Rockfish: 2025 assessment

## Assessment and stock unit

The current DFO unit is one coastwide British Columbia stock covering Groundfish Management Areas 3CD5ABCDE, excluding inside waters in 4B. DFO’s 2026/038 Science Advisory Report describes the 2025 full, peer-reviewed assessment and advice for the stock at the beginning of 2026. The model uses Stock Synthesis 3 version 3.30.23, two sexes, ages 0–60 with age 60 as the accumulator, and an unfished equilibrium start in 1935. It reconstructs the population through 2025.

This current unit and run are the candidate of record. The report identifies the 2013 full assessment, published as Research Document 2016/042, as the previous full assessment. That older assessment is not used to fill gaps in the current run.

## Reported inputs and assumptions

The model uses catch histories for areas 5ABC, 5DE, and 3CD. Table 3 reports catch in tonnes, landings plus releases, by area from 1996 through 2025; the values for 2025 were set equal to 2024 because the full 2025 catch was not yet available. DFO says the realized 2025 catch was 12% lower than the assumed value. The report says the full catch history is in a Research Document listed as in preparation.

The report describes four synoptic fishery-independent survey indices, two historical survey indices, and three commercial CPUE series. It says composition data are proportions-at-age from three commercial fisheries and three surveys. The advisory report does not publish the numerical age-composition observations, the fitted numerical survey/CPUE series, age-specific growth/weight arrays, or the current female maturity schedule. It therefore does not support a verified reconstruction of catch numbers-at-age or survey abundance-at-age.

The model estimates natural mortality separately for females and males. Table 1 gives posterior quantiles: female M has median 0.0639 with 5th–95th percentiles 0.0496–0.0801; male M has median 0.0566 with 5th–95th percentiles 0.0427–0.0720. These are estimates, not a complete age-specific M input surface. The report identifies female maturity and male/female growth and length–weight relationships as estimated outside the model but does not publish the numeric schedules. Survey-specific within-year timing is not reported.

## Reported outputs

Tables 1–2 provide posterior summaries for M by sex, unfished female spawning biomass, beginning-of-2026 female spawning biomass, biomass ratios, exploitation-rate quantities, and reference points. The reported posterior quantiles are based on 2,000 MCMC samples; the 5th and 95th percentiles form the 90% interval. Figures show annual stock-status, recruitment, and exploitation trends, but the report does not provide numeric annual N-at-age or F-at-age surfaces. These summary results are useful as official output records but do not substitute for age-specific model outputs.

## Source search and decision

The [official English DFO report](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-038-eng.pdf) and [catalogue record](https://publications.gc.ca/site/eng/9.964191/publication.html) were reviewed on 2026-11-14. The official CSAS schedule lists the March 2026 coastwide review. The advisory report says additional publications will be posted as they become available. A targeted publication search did not locate a detailed companion Research Document or public Stock Synthesis input/output files for this run. The older [2016 research document](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/365822.pdf) documents a different earlier assessment and is not a substitute.

The English catalogue page is cached locally under the ignored `source_cache/dfo_silvergray_rockfish_coastwide/source_material/` directory. The catalogue lists the 2026/038 PDF, but a local request to its PDF endpoint returned an archived HTML placeholder on 2026-11-14, so the PDF itself could not be saved to the cache. The source and cache details are recorded in `data-raw/provenance/dfo_silvergray_rockfish_coastwide/sources.csv`.

Screening is complete and age-input eligibility remains unresolved. Keep the current assessment on the watchlist. Do not create canonical input or output rows from figures or fitted states, and do not fall back to the 2013 assessment to complete the current record. Recheck for the companion Research Document/native files when they are released; then decide whether the verifiable current-run data support a partial canonical import.