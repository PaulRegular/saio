# Snapper in SNA 7 — 2024 assessment

## Stock unit and latest assessment

Fisheries New Zealand's detailed 2024 assessment is the latest production assessment located for the current SNA 7 unit. The 2025 Fisheries Assessment Plenary still identifies the 2024 run as the latest assessment, and the 2026/27 research plan schedules the next full assessment for 2027. The accepted 2024 model is Stock Synthesis 3.30.22, with model years 1931–2023, one sex, and ages 1–30+.

SNA 7 covers Tasman Bay/Golden Bay and the west coast of the South Island. The assessment includes Marlborough Sounds catches while noting that area is biologically distinct.

## Assessment inputs recorded

- **Catch:** Table A5 reports BT1, BT2, pair-trawl and recreational catch biomass in tonnes for model years 1931–2023. Commercial values include the assessment's under-reporting allowances.
- **Commercial age compositions:** BPT samples from 1978, 1979, 1980 and 1983; BT1 samples from 1992, 1997–2000, 2003, 2006, 2013, 2016, 2019 and 2022; BT2 samples from 2006, 2013, 2016, 2019 and 2022. Each composition is retained as the published proportions for ages 1–30+, with age 30 as the plus group. The 1974 BPT composition appears in Table A6 but is not among the four fitted BPT years in Table 5, so it is not recorded as a fitted input.
- **Commercial age sampling:** Table 3 reports raw otolith counts for the fitted commercial samples. For samples assigned to both BT1 and BT2, the reported count is retained as pooled; it is not split between the two seasonal fleets.
- **CPUE:** The model uses the combined BT1 CPUE index from 1989–2009 and the BT2 index from 1989–2022. The later BT1 series is excluded because the assessment raises concerns about increased avoidance as abundance rose. Published index values are retained. Table 5 gives observation-error CV ranges of 0.09–0.16 for BT1 and 0.14–0.20 for BT2, but not year-specific CVs. Confidence limits in Tables A3 and A4 are not converted to annual CVs because that calculation does not reproduce the reported ranges.
- **Trawl survey:** The assessment uses 16 core-area biomass observations. Survey biomass and CVs are transcribed from Table 7 of Fisheries Assessment Report 2024/06. The source labels survey years; the database stores the model year one year earlier, consistent with Table A9. Core and core-plus-shallow age compositions are recorded separately for 2016, 2018, 2020 and 2022 model years.
- **Tagging:** The 1987 Petersen estimate of 1,549 tonnes and its 0.30 CV are included as a single biomass observation. The report notes concerns about its precision and possible low bias.
- **Length compositions:** The four core survey length compositions (2008, 2010, 2012 and 2014 model years) are retained as proportions. Recreational length compositions for 2005, 2011 and 2015–2021 are retained in their reported frequency form. Their reported effective sample sizes are recorded separately from raw sample counts.

Table 5 does not identify year-specific effective sample sizes for BT1 and BT2 age compositions; it gives ranges of 10–25 and 6–12. The database preserves the reported ranges rather than assigning a value to each year. Table 3 raw otolith counts are not treated as likelihood sample sizes.

## Biology and model assumptions

Natural mortality is fixed at 0.075 per year. The assessment reports time-period-specific von Bertalanffy growth, a length-weight relation, and a fixed logistic maturity-at-length. It does not tabulate age-specific weight or maturity vectors. Recruitment uses a Beverton-Holt relationship with fixed steepness 0.95 and fixed sigma-R of 1.5; the unfished recruitment scale is estimated.

The survey is described as occurring in March–April, but the assessment report does not state the model's numeric within-year survey timing. No fractional sampling time is assigned. CPUE process-error CVs are 0.3 for BT1 and 0.2 for BT2; the trawl survey process-error CV is 0.2.

## Outputs recorded

For the Base_RecCatch run, Table 7 reports 2023–24 spawning biomass of 13,816 tonnes (median; 95% MCMC interval 9,810–18,530), target FSB40 of 0.051 per year, F2023/FSB40 of 0.376 (95% interval 0.278–0.532), probability below target of 1.00, yield at FSB40 of 1,872 tonnes (95% interval 1,313–2,537), and MPD vulnerable biomass of 32,963 tonnes.

Annual numerical N-at-age, F-at-age, M-at-age and SSB trajectories are not tabulated in the assessment report. M is fixed, so there is no estimated M output. These limits are reflected in the partial output status.

## Other source material and cache

The cached 2025/22 catch-at-age report covers the 2022–23 and 2023–24 fishing years. Those data are a later supporting study and are not mixed into the 2024 assessment's likelihood inputs. The cached 2025 Plenary supports the assessment-year review.

The Fisheries Assessment Report 2024/06 survey PDF is available at [the official Fisheries New Zealand document page](https://www.mpi.govt.nz/dmsdocument/61021/direct), and its searchable PDF text was used to transcribe Table 7. A direct local download was blocked by the site's hCaptcha security check; no challenge was completed and no HTML response was retained as a PDF. The source URL and this cache gap are recorded here. The 2026/27 research-plan document was also consulted to confirm the next assessment schedule but is not cached.

The three valid local PDFs, their URLs, retrieval date and SHA-256 checksums are listed in provenance/mpi_snapper_sna7_2024_sources.csv. The canonical record remains partial because exact BT1/BT2 year-specific composition ESS, the numeric survey timing and complete annual population-output series are not available from the reviewed sources.
