# ICES northern hake (`hke.27.3a46-8abd`)

Reviewed 2026-10-30. ICES continues to assess the northern hake unit across subareas 4, 6, and 7 and divisions 3.a, 8.a, 8.b, and 8.d. The latest production assessment is the 2026 WGBIE update; ICES issued advice for 2027 catches of no more than 46,824 tonnes.

The 2026 assessment uses a sex-separated Stock Synthesis population model with sex-dependent growth and natural mortality. Its observations are commercial catches, aggregate survey abundance indices, and length-frequency data for landings, discards, and surveys. Figure 9.7 also identifies mean-length-at-age observations, but the assessment does not report catch-at-age or annual age-composition inputs. The survey indices are aggregate; the North Sea IBTS biomass/abundance survey is discussed but explicitly not used in the fit.

ICES Standard Graphs reports annual age-0 recruitment, total biomass, female spawning-stock biomass, landings, catches, discards, and F averaged over ages 1-7, with 90% intervals for recruitment, SSB, and F. The report contains a numbers-at-age figure for the short-term forecast, not a historical annual N-at-age series. No historical F-at-age, M-at-age, or age-specific abundance series was recovered from the public outputs. Age-specific weights and numerical maturity/M inputs are not available in the recovered 2026 summary sources.

The case is screened ineligible for the age-disaggregated set because the current assessment lacks catch-at-age and age-specific survey observations, and a historical annual age-specific population output series was not recovered. The assessment report cites an ICES TAF repository, but its GitHub API endpoint returned 404 during this review, so its input and output files could not be checked. The detailed assessment and aggregate comparison outputs remain useful for a future non-age-structured comparison.

Sources:

- [ICES WGBIE 2026 report](https://doi.org/10.17895/ices.pub.32790321.v1), Section 9, pp. 416-464; especially Sections 9.2-9.3 and Figures 9.7 and 9.19.
- [ICES 2026 Advice View](https://asd.ices.dk/viewAdvice/5110), stock assessment key 22627; advice for 2027 catches.
- [ICES Standard Graphs source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22627), stock key 22627.
- The report cites [the 2026 TAF assessment repository](https://github.com/ices-taf/2026_hke.27.3a46-8abd_assessment) in footnote 3; public GitHub metadata was unavailable during this review.

The assessment section, advice PDF, and Standard Graphs source page are cached in the gitignored `source_cache/ices_northern_hake_2026/`; `manifest.csv` records download URLs, retrieval time, and SHA-256 checksums.
