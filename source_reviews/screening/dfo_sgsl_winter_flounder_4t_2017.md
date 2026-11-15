# DFO NAFO 4T winter flounder

## Assessment selected

The latest detailed full assessment located for the current NAFO Division 4T unit is the 2017 assessment, published as DFO Research Document 2019/026, with data through 2016. DFO Science Response 2025/010 updates survey indicators through 2024 and states that a new full assessment was planned for 2026. No later full assessment was found as of 2026-11-03; the 2025 response remains a separate interim update, not a new population-model fit.

The 2017 model is a combined-sex statistical catch-at-age model implemented in TMB. It treats the southern Gulf as one population and covers ages 2-12+, with age 12 as the plus group. Seven variants were compared. Table 11 gives Model 7 the lowest AIC, while the main inference figures and numerical results in the text are presented for Model 2. The imported population estimates are therefore labelled Model 2 outputs and are not described as results from an unambiguous selected run.

## Inputs recovered

- **Landings:** Table 1 reports annual total commercial landings in tonnes for 1973-2016. The parenthetical Magdalen Islands bait-fishery quantities are included in the reported totals and are not added again.
- **Commercial catch-at-age:** Table 9 reports numbers in thousands of fish for ages 2-12+, 1973-2016, and labels its 2016 estimates preliminary. The assessment fits annual catch proportions in numbers alongside total landings. Proportions are reconstructed by normalizing the displayed age counts within each year. The published counts are rounded, and the report does not explain how zero cells were handled in the model's log-scale composition residuals.
- **Survey age information:** Table 10 reports September RV trawlable abundance-at-age in thousands of fish, ages 2-12+, 1973-2016. Annual number proportions are reconstructed from those counts for the composition likelihood.
- **Aggregate survey index:** Figure 18 plots the offshore September RV series for strata 415-439. The lower panel shows weight per tow in kg/tow; its annual points were digitized to 0.1 kg/tow. The report's model-input list describes the aggregate survey input as tonnes, so its exact model-native scale cannot be confirmed without the original input data. Figure confidence intervals were not digitized.
- **Maturity:** Table 12 reports annual mature proportions-at-age from the RV survey for ages 2-12+, 1973-2016.
- **Survey weights:** Table 13 numerically reports RV-survey mean weights-at-age in kg/fish for ages 2-12+, 1973-2016.

The methods also state that fishery mean weights-at-age were used, but the report's numeric Table 13 is specifically the RV-survey surface. No fishery weight-at-age matrix or native input file was recovered. This prevents a fully faithful reconstruction of the source assessment's catch/biomass conversions, so input completeness remains partial. Table 9 and Table 10 count surfaces are retained with their derived compositions and are explicitly documented as the source basis for the composition likelihood, not as additional independent age-specific likelihoods.

The reported September survey timing is 0.71 of the annual step. Natural mortality is estimated in five-year blocks, with variants using age groups 2-4 and 5+, or 2-4, 5-7 and 8+. Fishing and survey selectivity are logistic; some variants change selectivity blocks over time. Catch uncertainty is described on the log scale with SD 0.1 except for 1984, assigned SD 2. The age-2 recruitment process uses an AR(1) form with logit(phi) fixed at -4.

## Outputs recovered and gaps

The report gives the following Model 2 estimates in prose, without numeric uncertainty: 2016 SSB of 76,270 tonnes, total abundance of 3.05 billion fish for ages 2-12+, age-2 recruitment of 1.8 billion fish, and age-3 recruitment of 0.7 billion fish. It reports a Model 2 survey catchability estimate of 0.232. Annual population abundance, F, M, and SSB are shown in figures but are not tabulated as numeric time series in the report, and no fitted model object was located. Outputs remain partial; no uncertainty has been inferred.

The 2025 interim update reports a three-year moving average of 1.38 kg/tow for commercial-size fish (at least 25 cm), assigned to 2024, and scaled survey-index reference points of 3.82 kg/tow (LRP) and 7.64 kg/tow (USR). These are separate from the 2017 population-model outputs and are not SSB reference points.

## Sources and cache

- [Surette and Rolland (2019), DFO Research Document 2019/026](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40804392.pdf)
- [DFO Science Response 2025/010, indicators through 2024](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf)
- [DFO publication record for Research Document 2019/026](https://csas-scas.dfo-mpo.gc.ca/publications/a05d569d-d016-4b92-98fe-2799ec55c72b)

The two PDFs, source URLs, retrieval dates, file sizes and SHA-256 checksums are recorded in the ignored local cache at `source_cache/discovery_dfo_4t_winter_flounder_2019/sources.csv`.
