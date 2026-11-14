# Trevally in TRE 7 — 2026 assessment

## Stock unit and assessment

The latest detailed production assessment located is Fisheries New Zealand FAR 2026/34, published 21 September 2026. It assesses the TRE 7 fishstock for model years 1975–2025 using Stock Synthesis 3.30.23.1. The model combines sexes and uses ages 1–39 plus a 40+ group.

The report distinguishes the stock unit from the area covered by each model. The base assessment covers the northern NMB and KMNTB areas and excludes South Taranaki Bight (STB) catches. A separate TwoRegion sensitivity includes all TRE 7 catches and models northern and southern sub-stocks. The base and TwoRegion results must remain identified separately.

## Recoverable inputs

- **Commercial catch:** Table A13 reports catch histories from 1975–2025 for NMB bottom trawl, KMNTB bottom trawl, combined NMB/KMNTB pair trawl, and STB bottom trawl plus pair trawl. The base model uses the three northern series and excludes STB. The assessment describes the histories as including unreported catch; the main report also documents historical discard and under-reporting allowances and the apportionment rules.
- **Commercial age compositions:** Table 3 identifies the fitted series. BPT samples cover 1975, 1976, 1978, 1979, 1998, 1999 and 2001. KMNTB samples cover 1998–2001, 2006–2008, 2010, 2013, 2023 and 2024. NMB samples cover 1998–2001, 2007–2008, 2010, 2013, 2023 and 2024. FAR 2025/38 publishes detailed recent age-composition and age-length tables for 2022–23 and 2023–24. Historical likelihood vectors require the earlier sampling reports cited in FAR 2026/34.
- **CPUE:** Appendix 2 Table A8 provides combined KMNTB trawl CPUE indices and 95% confidence limits for fishing years 1993–94 through 2024–25. Table 6 reports the fitted series CV range, including process error, as 0.21–0.31. The model uses KMNTB CPUE as its primary abundance index.
- **Trawl survey:** Table 4 reports northern-area Kaharoa biomass indices and one-year-old abundance indices, with CVs, for the listed surveys. It maps survey calendar years to model years. Table 6 reports the fitted survey series and CV ranges. The report states that surveys occur in October–November; the numerical within-year observation timing is not stated.
- **Biology and model assumptions:** Table 5 reports fixed natural mortality of 0.10 per year, combined-sex von Bertalanffy growth (L1 13.64 cm, Linf 44.99 cm, k 0.225), the length-weight relationship, age-based maturity (ages 1–3 = 0, age 4 = 0.5, ages 5+ = 1), Beverton–Holt steepness 0.80 and recruitment log-SD 0.60. The model uses estimated initial fishing mortality and early recruitment deviations to establish the 1975 age structure.

## Reported outputs and limits

Tables 7–9 report MCMC medians and 95% intervals for unfished and terminal spawning biomass, target biomass, fishing-mortality reference measures, probabilities, and projections. These outputs are useful for comparison, with the area scope noted above. Annual numerical N-at-age, F-at-age, M-at-age and recruitment arrays are not tabulated; annual SSB and recruitment are shown in figures only. Natural mortality is fixed in the base assessment, not estimated.

The 2026 assessment report and 2025 age-composition report are cached locally. The source hashes and official URLs are recorded in `provenance/mpi_trevally_tre7_2026_sources.csv`. Native Stock Synthesis input/output files were not located in this review. Exact within-year survey timing and the older age-composition likelihood vectors remain to be verified from the cited source reports.


## Database import (5 November 2026)

A partial canonical source record has been added for the 2026 assessment. The import preserves:

- The four Table A13 catch-biomass series for model years 1975-2025, keeping NMB BT, KMNTB BT, combined NMB/KMNTB BPT, and STB BT+BPT separate.
- The 1994-2025 KMNTB combined CPUE index, with the table's annual 95% limits retained in row notes. The report gives a 10% process error and a fitted CV range, but does not publish the annual fitted CV vector.
- The northern Kaharoa biomass and one-year-old abundance indices and reported CVs; the southern biomass series is retained as TwoRegion sensitivity data.
- The 2022-23 and 2023-24 reported proportion-at-age and CV tables by source subarea, with raw aged-fish sample counts. Age 20 is the source >19 plus group. These are kept in their source-area form; the KMH and NTB vectors are not combined into an unpublished KMNTB series.
- The reported model settings and base-model summary outputs from Tables 5 and 7-9.

The catch series is biomass, not catch-at-age. No transformation to age-specific catch numbers was made. The input record therefore remains partial: most fitted historical age-composition vectors, exact KMNTB aggregation, annual ESS values, survey length-composition vectors, and annual numerical SSB, recruitment, N-at-age, F-at-age, and M-at-age outputs were not recovered in the cached sources. Natural mortality is fixed in the Base model and is recorded as an assumption, not an estimated output.

One source discrepancy is preserved: Table 4 reports a CV of 9.26 for the model-year 2000 one-year-old survey index, while Table 6 summarizes the fitted-series CV range as 0.59-3.49. The imported value remains 9.26, and the inconsistency is recorded rather than adjusted.

The two cached files listed in provenance/mpi_trevally_tre7_2026_sources.csv are the 2026 assessment report and the 2025 age-composition report. Older sampling reports cited by FAR 2026/34 are identified for later recovery, but their vectors were not used in this import.

