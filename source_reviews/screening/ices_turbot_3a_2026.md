# ICES turbot in Division 3.a (`tur.27.3a`)

Reviewed 2026-10-30. The current ICES management and advice unit is Division 3.a (Skagerrak and Kattegat), a separate unit from North Sea turbot (`tur.27.4`). The latest available production assessment is the 2026 WGNSSK update, using a revised SPiCT model developed in 2025. The 2026 ICES advice is for catches in 2027.

The current model is not age-disaggregated. It uses an aggregate catch series in tonnes for 1960-2025 and three combined exploitable-biomass indices: Q1 (1983-2025), Q3 and Q4 (1991-2025). The index model combines five surveys and applies length-based vulnerability weighting using commercial and survey length data from 2012-2018. Those length observations help construct an aggregate biomass index; the assessment does not use catch-at-age or an age-specific abundance index.

Age-specific weights, maturity, and natural mortality are not inputs to the current SPiCT model. The model reports annual relative exploitable biomass (B/BMSY) and relative fishing pressure (F/FMSY), with low/high 95% intervals in the assessment table. It does not report numbers-at-age, F-at-age, M-at-age, absolute SSB, or age-specific recruitment. ICES advises a maximum catch of 396 tonnes in 2027.

The ICES 2026 WGNSSK report notes that turbot in Division 3.a is connected to North Sea and Baltic populations and that the stock identity is being evaluated with genetic analysis. This uncertainty concerns biological population boundaries; the official ICES assessment and advice unit remains Division 3.a.

The candidate is screened ineligible for the age-disaggregated input set. It remains a possible source for future aggregate-model comparisons, but this audit step does not create a canonical assessment or import its values.

Sources:

- [ICES WGNSSK 2026 report](https://doi.org/10.17895/ices.pub.32676345.v2), Section 19, pp. 1072-1091; assessment chapter updated 12 October 2026.
- [ICES 2026 Advice View](https://asd.ices.dk/viewAdvice/5098), stock key 22416; catch advice for 2027.
- [ICES Standard Graphs source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22416), stock key 22416.

The chapter, advice PDF and Standard Graphs source page are cached in the gitignored `source_cache/ices_turbot_3a_2026/`; `manifest.csv` records source URLs, retrieval time and SHA-256 checksums.
