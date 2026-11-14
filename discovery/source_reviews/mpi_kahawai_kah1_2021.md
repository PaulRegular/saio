# Kahawai in KAH 1 — 2021 assessment

## Stock unit and latest assessment

KAH 1 is the Fisheries New Zealand stock off the northeast North Island. FAR 2022/54 describes the 2021 CASAL assessment using data through the 2019–20 fishing year and publishes its model input appendix.

The May 2026 Fisheries Assessment Plenary includes a KAH 1 summary and lists 2021 as the most recent assessment. Fisheries New Zealand's 2026–27 research plan also says the last assessment was in 2021 and schedules a new assessment for 2029. Neither source reports a newer production run, so the detailed 2021 assessment remains the canonical run. The 2026 Plenary is retained as current status context; its summary values are not mixed into the 2021 records.

Sources:

- [FAR 2022/54: 2021 KAH 1 assessment](https://www.mpi.govt.nz/dmsdocument/54118/direct)
- Cached direct report PDF
- [Fisheries Assessment Plenary May 2026, Volume 2](https://fs.fish.govt.nz/Doc/26242/Fisheries-Assessment-Plenary-May-2026-Volume-2.pdf.ashx)
- [Proposed Fisheries Research Services for 2026–27](https://www.mpi.govt.nz/dmsdocument/71944/direct)

## Imported assessment inputs

- **Catch biomass:** 819 annual records for nine CASAL fleets, spanning model years 1930–2020. The source values are retained in tonnes, including source zeros and the original model-year labels.
- **Sampled age compositions:** 975 age proportions across 50 observations from seven fleets. The model uses multinomial sampled-catch proportions and down-weighted effective sample sizes. These data are not catch numbers-at-age. Source age ranges and plus-group settings are noted by fleet; the printed proportions are preserved without renormalization.
- **Aggregate indices:** 77 observations from three recreational CPUE series and one Bay of Plenty aerial SPUE series, plus 77 matching CV records. The CASAL appendix marks CPUE as abundance and SPUE as biomass; values remain on their reported relative scales. Each series uses proportion_mortality = 0.5.
- **Biology and mortality:** CASAL specifies von Bertalanffy size-at-age, length-weight, knife-edge maturity at age 4, and fixed M=0.22 per year in the base model; M=0.20 and 0.24 are sensitivity runs. The report prose gives length-weight a=0.0236, while the CASAL appendix gives a=2.36e-08 with the same b=2.89. Their unit conversion is not stated, so both forms are retained without conversion.
- **Recruitment:** Beverton–Holt stock-recruitment with steepness 0.75; year-class strengths are estimated for 1994–2014.

The canonical inputs are marked complete because the CASAL appendix publishes the original observation series and model inputs captured here. Assumptions remain partial because the length-weight coefficient scaling is not fully explained.

## Reported outputs and limits

Table 9 reports MCMC medians and 95% credible intervals for SSB0, 2020 spawning biomass, the 52% B0 target, and the two status ratios under base M=0.22 and fixed-M sensitivities of 0.20 and 0.24. These are stored as 15 official-table rows across the three scenarios. Standard errors are not reported.

The report does not tabulate annual numerical N-at-age, F-at-age, M-at-age, recruitment, or spawning-biomass trajectories; those outputs are figures. M is fixed in each run and is not an estimated output. The model calculates weights from growth and the length-weight relationship rather than supplying a weight-at-age table.

The 2021 assessment PDF and 2026 Plenary Volume 2 are cached in the ignored local source cache. Their URLs, retrieval dates, and SHA-256 checksums are recorded in provenance/mpi_kahawai_kah1_2021_sources.csv. The 2026–27 research plan is retained as an official link because the document endpoint did not provide a usable local PDF during this review.
