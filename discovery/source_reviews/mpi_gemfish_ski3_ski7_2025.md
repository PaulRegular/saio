# Southern gemfish (SKI 3 and SKI 7), 2025 assessment

## Identity and selected assessment

Fisheries New Zealand treats SKI 3 and SKI 7 as one southern biological stock complex. The latest detailed assessment located for this current unit is the 2025 assessment in FAR 2026/39. It used a Casal2 age-structured model and extends through the 2024–25 fishing year, labelled 2025. The assessment used an annual fixed proportional-removal reference for advice.

The selected base model was the survey-abundance growth model. The working group rejected CPUE-abundance variants because their predicted historical depletion was considered biologically implausible. The assessment report also says the model had likelihood conflict, and repeated MCMC attempts did not achieve statistically acceptable convergence. Its MPD point estimates therefore have no reported uncertainty and should not be read as precise stock-status estimates.

## Model structure and source inputs

The model represents ages 1–15+ and both sexes, with recruitment entering at age 1. It has one annual step, assumes homogeneous distribution over the combined SKI 3+7 area, and treats the 1975 state as approximately unfished. Commercial catches are modelled as two bottom-trawl fleets, one for each QMA. The model catch series is reported for fishing years 1975–2025. The report states that catch totals were increased by 20% before the QMS began in 1986 and by 10% from 1986 onward; the 2024–25 model catch was assigned from a five-year average. The published Appendix 15 values are preserved as printed. The two 2025 values do not equal the arithmetic means of the preceding five rounded Appendix 15 entries; the report does not explain this difference, so no alternative values are inferred.

Table 9 reports 29 trawl-survey biomass indices and CVs: three SKI 3 Shinkai Maru, four SKI 3 Tangaroa, 16 SKI 7 Kaharoa, and six SKI 7 Tangaroa observations. The source values assume area availability, vertical availability, and vulnerability are each 1. CVs are reported as percentages and are stored as ratios after division by 100. Survey trip months or month ranges are retained. The model has one annual time step and the report does not give a within-year fraction for these observations.

The selected survey-abundance base model excludes commercial CPUE indices. It uses separate catchability parameters for the four survey series.

## Biological and process assumptions

- Natural mortality is fixed at 0.25 per year for both sexes. Sensitivities use 0.20 and 0.30.
- Beverton–Holt steepness is fixed at 0.85. Sensitivities use 0.75 and 0.95. The report lists recruitment deviations for 1975–2023 and sigmaR = 1.8.
- Table 13 states maturity proportions as “(0.1, 0.4, 0.8, 1.0) for ages 1–5” for both sexes. Four values are given for five ages, without stating which ages share a value. The original statement is recorded without inferring a numerical maturity-at-age vector.
- The report gives male and female von Bertalanffy parameters and length–weight equations. Table 14 identifies growth parameters as estimated, but final fitted growth values are not tabulated. No direct weight-at-age matrix is provided.
- The model fitted recent observer age compositions and selected survey compositions with multinomial error. Composition age vectors and their fitted likelihood weights are not included in the assessment report.

## Catch-at-age source review

Three official companion reports are cached and listed in the provenance manifest. They publish calculated sex-specific catch numbers-at-age and CVs for 2020–21, 2021–22, and 2022–23. FAR 2026/39 describes its recent observer age-composition observations as 2021–22, 2022–23, and 2023–24. It cites Devine et al. (2023, 2024, 2025), but the cited companion reports cover 2020–21, 2021–22, and 2022–23. This leaves the selected-run year mapping unresolved; these companion values are not imported as exact likelihood inputs. The assessment also lists age compositions for four SKI 3 Tangaroa trips from 1993–1996 but does not publish their numeric vectors.

## Imported source records

The canonical database now contains:

- Two model catch series by QMA for 1975–2025 (102 rows), including the source's catch adjustments and 2025 values.
- Twenty-nine survey biomass indices and 29 matched CV records.
- Base-model and sensitivity MPD estimates from Table 17 for B0, 2025 SSB/B0, the U40%B0 proportional-removal reference, 2025 exploitation rate, and the exploitation-rate/reference ratio.
- The source-reported biological, temporal, spatial, and model assumptions described above.

No annual N-at-age, F-at-age, M-at-age, recruitment series, absolute annual SSB trajectory, or uncertainty intervals were available as numerical tables in the reviewed report. The recorded assessment is therefore partial.

## Sources

- McKenzie, Doonan & Bian (2026), Fisheries New Zealand FAR 2026/39, *2025 stock assessment of gemfish (Rexea solandri) in SKI 3 and SKI 7*: [report page](https://fs.fish.govt.nz/Page.aspx?dk=26272&pk=113) · [PDF](https://fs.fish.govt.nz/Doc/26272/FAR-2026-39-2025-stock-assessment-gemfish-in-SKI3-and-SKI7.pdf.ashx).
- Fisheries Assessment Plenary, May 2025, Volume 1, Gemfish section: [PDF](https://fs.fish.govt.nz/Doc/26039/gemfish-ski-fisheries-assessment-plenary-may-2025-volume-1.pdf.ashx).
- Devine et al. (2023), FAR 2023/22, catch-at-age for 2020–21: [PDF](https://webstatic.niwa.co.nz/library/FAR2023-22.pdf).
- Devine et al. (2024), FAR 2024/01, catch-at-age for 2021–22: [PDF](https://webstatic.niwa.co.nz/library/FAR2024-01.pdf).
- Devine et al. (2025), FAR 2025/05, catch-at-age for 2022–23: [PDF](https://fs.fish.govt.nz/Doc/25855/FAR-2025-05-Catch-at-age-for-BAR5-and-SKI3-and-SKI7-for-the-2022-23-fishing-year.pdf.ashx).

The four PDFs are cached under `source_cache/mpi_gemfish_ski3_ski7_2025/`. Retrieval dates and SHA-256 checksums are listed in `provenance/mpi_gemfish_ski3_ski7_2025_sources.csv`.
