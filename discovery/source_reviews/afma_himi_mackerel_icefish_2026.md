# AFMA HIMI mackerel icefish, 2026

## Assessment and stock unit

The current stock unit is mackerel icefish (*Champsocephalus gunnari*) in the Heard Island and McDonald Islands fishery, CCAMLR Division 58.5.2. No matching canonical SAIO stock record was found. It is distinct from HIMI Patagonian toothfish and the separate Macquarie Island toothfish unit.

AFMA's [HIMI fishery page](https://www.afma.gov.au/fisheries/heard-island-and-mcdonald-islands-fishery) identifies the 2026 report as the final assessment with TAC recommendations for 2026/27 and 2027/28, and says Australian Antarctic Division assessments are reviewed by SARAG and CCAMLR. The report itself is titled *A preliminary assessment for mackerel icefish in Division 58.5.2, based on results from the 2026 random stratified trawl survey*. Retain both descriptions: the analysis method is a survey-based CMIX cohort and Grym yield assessment, not an integrated annual age-structured population model.

## Sources and recovery

- Assessment report: [2026 HIMI mackerel icefish assessment](https://www.afma.gov.au/sites/default/files/2026-11/Mackerel%20Icefish%20stock%20assessment%202026.pdf), cached locally as `source_cache/discovery_afma_himi_2026/himi_mackerel_icefish_2026.pdf`.
- AFMA fishery page: https://www.afma.gov.au/fisheries/heard-island-and-mcdonald-islands-fishery
- The report identifies the March 2026 random stratified trawl survey (RSTS), three survey strata, CMIX length-mixture estimates and the Grym projection method.
- No run-specific raw haul data, length-density vectors, source model object, or complete input files were found in the linked report material. The age-cohort densities below are CMIX estimates derived from survey length-density data, then used in the yield calculation; they are not raw age observations.

## Values recoverable from the 2026 report

Table 1 (PDF p. 5) reports 2026 cohort densities of 29, 185, 273 and 612 fish/km² for cohorts 1+, 2+, 3+ and 4+. It also reports density SDs of 14, 37, 1,467 and 252 fish/km². The SD values are not standard errors; they are retained in the source notes and are not written into the database SE field. Table 1 gives a sum of expected cohort densities of 1,099 fish/km2, while Table 2 reports expected overall density of 1,098 fish/km2 and observed density of 1,099 fish/km2. These separate source values are retained without reconciliation. Table 2 also includes 2024 and 2025 survey context, but only 2026 represents the current assessment survey input.

Table 3 (PDF p. 6) gives the 2026 weight-length coefficients `a = 1.002e-9`, `b = 3.123`, with weight in kg and length in mm. The assessment uses von Bertalanffy growth parameters from the 2018–2024 survey data (`Linf = 559.1 mm`, `K = 0.294`, `t0 = 0.066`). Table 4 (PDF p. 8) reports mean weights at cohorts 1+ to 4+ of 0.022, 0.103, 0.218 and 0.297 kg, and biomass proportions of 0.25%, 7.30%, 22.78% and 69.67%. The method assumes ages 1–3 are mature and fixes natural mortality at `M = 0.4 yr^-1`. The projection uses cohorts 1+ through 3+; it excludes 4+.

Table 5 (PDF p. 8) reports bootstrapped survey biomass. The pooled estimate is 4,797 t (SE 994; 95% CI 2,998–6,845 t; lower one-sided 95% bound 3,254 t). Stratum estimates are Gunnari Ridge 2,808 t, Plateau Southeast 945 t and Plateau West 1,044 t, each with reported SE and intervals. Table 6 (PDF p. 8) reports a target fishing mortality of 0.1467 yr^-1, 210 t of post-survey catch from cohorts used in the projections, and recommended yields of 130 t for 2026/27 and 112 t for 2027/28. The report also says 419 t were caught after the survey; no age allocation for the full catch is provided.

A partial canonical record is now imported as `afma_himi_mackerel_icefish` / `afma_himi_mackerel_icefish_2026`. It preserves current cohort-density estimates, reported weights and maturity, fixed M, post-survey catch, survey biomass with uncertainty, cohort biomass shares, and yield recommendations. No annual N-at-age, F-at-age, recruitment, or historical catch-at-age series is reported.

## Source limits

The report supplies one current survey's estimated cohort densities and limited projection catch, not a historical catch-at-age or population time series. Raw survey length data and run-specific files were not recovered. The 2024 and 2025 Table 2 rows are prior-survey context, not inputs from the 2026 assessment, and are kept separate from its current input series.

The report's narrative once names the yield seasons as 2025/26 and 2026/27; its recommendation paragraph and Table 6 identify 2026/27 and 2027/28. The canonical advice rows follow the recommendation and Table 6, while noting this internal inconsistency. The AFMA page calls the report final, but its title calls the assessment preliminary; this is recorded without inferring that the recommended yields were adopted as final catch limits.
