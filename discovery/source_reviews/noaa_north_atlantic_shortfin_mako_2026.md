# North Atlantic shortfin mako (NOAA Stock SMART 10657)

Review date: 2026-11-01

## Assessment identity and recency

NOAA Stock SMART snapshot 2026-10-28 lists assessment 7878, a full-acceptance 2017 benchmark using data through 2015. That is not the latest assessment evidence for this shared North Atlantic unit. ICCAT's 2026 North Atlantic shortfin mako stock assessment was completed in June 2026, and its model-runs paper documents a final agreed Stock Synthesis run covering 1950-2024. No matching stock or assessment is currently present in tinyAM's canonical assessment database.

## Inputs and model structure

The 2026 model is described as a length-based age-structured Stock Synthesis assessment. The integrated model uses catches, CPUE indices, and length-composition data. Some model runs also use conditional age-at-length (CAAL) observations. The ICCAT meeting report says CAAL records came from Portuguese and U.S. fleets and were used to estimate growth; the SS3 model paper explains that CAAL describes age distributions conditional on length and can also affect year-class-strength estimates.

These CAAL samples are a useful source of age information, but they are not documented as annual catch-at-age or annual index-at-age series. Their fleet and year correspondence, sample expansion, and coverage are not sufficient from the reviewed documents to establish that catch numbers-at-age or age-specific abundance indices can be reconstructed faithfully. The 2026 assessment also considered three biological scenarios with different age-specific natural mortality assumptions. A complete set of tinyAM-compatible stock weights-at-age and maturity-at-age inputs was not verified.

## Outputs and screening decision

The final assessment reports recruitment, spawning-stock fecundity, and fishing-mortality/status trajectories through 2024. The model-runs document includes final agreed model details and diagnostics. Full N-at-age, F-at-age, and M-at-age output tables suitable for a common-definition comparison were not verified in the reviewed source material.

Keep the candidate screened but eligibility unresolved. The assessment is current and has age-based population structure and some CAAL data, but the public source evidence reviewed so far does not establish the annual age-resolved observation series required for a defensible tinyAM translation. Revisit eligibility if machine-readable CAAL and length-composition inputs, including fleet/year expansion information, can be recovered. No canonical stock, assessment, input, or output records were added, and no tinyAM translation was attempted.

## Sources

- NOAA Stock SMART stock 10657, snapshot retrieved 2026-10-28; its cached assessment summary remains at 2017.
- ICCAT, [Report of the 2026 North Atlantic Shortfin Mako Stock Assessment Meeting](https://www.iccat.int/Documents/CVSP/CV083_2026/n_7/CV08307009.pdf), SCRS/2026/009.
- Fernández et al., [Preliminary 2026 Stock Synthesis model runs and final agreed run for North Atlantic shortfin mako](https://www.iccat.int/Documents/CVSP/CV083_2026/n_7/CV08307143.pdf), SCRS/2026/143.

The two 2026 ICCAT PDFs, retrieval dates, source URLs, revisions, and SHA-256 checksums are recorded in the gitignored source cache at `source_cache/noaa_shortfin_mako_north_atlantic_2026/sources.csv`.