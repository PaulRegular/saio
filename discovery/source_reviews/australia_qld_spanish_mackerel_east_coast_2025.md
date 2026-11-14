# Australian east coast Spanish mackerel — 2025 assessment

## Stock and latest detailed assessment

The 2025 Queensland DPI assessment treats east coast Spanish mackerel (*Scomberomorus commerson*) as one biological stock from Cape York Peninsula to Newcastle, New South Wales. The Gulf of Carpentaria stock is separate. The report uses data through June 2024, labelled by Australian financial year, and reports beginning-2025 status. It is the latest detailed official assessment located for this unit.

The population model is Stock Synthesis 3.30.22.1, with an annual time step and a two-sex population. The final reported results are an ensemble of six scenarios. Queensland fleets are split by sector, latitude, and season; NSW has commercial and recreational/charter fleets; a standardised commercial CPUE index is included as a survey fleet.

## Source data captured and gaps

- Table 3.1 gives rounded sector catch in tonnes for selected years from 1970 through 2024. These values are useful as a source-reported subset, but they are not the full annual fleet catch input. The report describes the full catch history and methods, while most annual values are shown only in figures. The four rounded 2024 sector values sum to 457 t, while report prose gives 459 t total; both are retained as reported without reconciliation.
- The population model fits annual catch histories, standardised CPUE, length compositions, conditional age-at-length compositions, and discard rates. The numeric annual CPUE series and raw composition likelihood arrays were not located in the report or its public record. Annual age frequencies appear as figures and must not be transcribed as exact input data.
- Biological assumptions are well described: two-sex von Bertalanffy growth; length-based maturity `exp(-10.349 + 0.0128 FL) / (1 + exp(-10.349 + 0.0128 FL))` with first maturity at age 2; whole-fish weight `3.40e-9 * FL^3.12` in kg when fork length is in mm; and fecundity `5.290168e-09 * FL^3.945` using fork length in cm.
- Natural mortality is constant across ages, sexes, and years. The final six scenarios estimate M with the Hamel and Cope prior, median `5.4 / 25 = 0.216` per year and log-scale SD 0.31. The report's pooled rounded MCMC summary is 0.2 (95% credible interval 0.2–0.3), which is too coarsely rounded to stand in for precise scenario estimates.
- Survey/CPUE timing is not given as one fractional point within the annual model step. The assessment year is July–June, but that alone does not establish observation timing for a model translation.

## Numerical outputs

Table 3.3 reports beginning-2025 spawning biomass relative to unfished biomass for the full MCMC ensemble: median 0.34, 95% credible interval 0.17–0.62, with probabilities of 0.08 below 0.20, 0.61 from 0.20 to 0.40, 0.28 from 0.40 to 0.60, and 0.03 above 0.60. The mean of the MLE scenario estimates is 0.25.

Table 3.4 reports beginning-2025 biomass ratios for each of six scenarios. MLE values and 95% confidence limits are, in scenario order: 0.28 (0.10–0.46), 0.25 (0.08–0.41), 0.22 (0.08–0.36), 0.29 (0.12–0.47), 0.25 (0.10–0.40), and 0.22 (0.08–0.35). MCMC medians and 95% credible limits are: 0.43 (0.25–0.66), 0.29 (0.18–0.42), 0.32 (0.16–0.58), 0.40 (0.23–0.63), 0.35 (0.17–0.63), and 0.26 (0.14–0.54).

The reviewed public report does not provide annual numeric absolute SSB, N-at-age, F-at-age, recruitment, or their age-specific uncertainty as tables. The assessment report includes figures for trajectories and composition fits; no values have been digitised from those figures.

## Source curation status

This candidate is selected for partial source curation because the official report documents model assumptions and provides numerical stock-status outputs. The public report does not provide the full annual fleet catch data, numeric CPUE series, raw age-at-length/length-composition likelihood inputs, or a single within-year index timing. The sparse rounded catch table and output summaries do not reproduce the full assessment input set. No data have been reconstructed from plots.

The canonical record preserves only the source-reported catch subset, stock-status summaries, pooled M summary, and documented assumptions. It is marked partial. This is not a claim that the full assessment input set is available.

## Sources and local cache

- [Queensland DPI eResearch Archive record](https://era.dpi.qld.gov.au/id/eprint/14912/)
- [Official Queensland Spanish mackerel stock page](https://www.dpi.qld.gov.au/services/fisheries/monitor/stock/species/spanish-mackerel)
- [2025 assessment PDF](https://era.dpi.qld.gov.au/id/eprint/14912/1/2025%20East%20coast%20Spanish%20mackerel%20stock%20assessment%20report%20Final%208.5.25.pdf)

The assessment PDF is cached in the ignored source cache at `source_cache/australia_qld_spanish_mackerel_2025/east_coast_assessment_2025.pdf`. Its source URL, retrieval date, byte count, and SHA-256 are recorded in `provenance/australia_qld_spanish_mackerel_2025_sources.csv`.
