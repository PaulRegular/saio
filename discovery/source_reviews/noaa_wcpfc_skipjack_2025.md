# Western and Central Pacific skipjack (NOAA:11691), 2025

## Assessment and data screen

The NOAA Stock SMART snapshot still lists assessment ID 13027 from 2022 with
data through 2021. WCPFC accepted a newer 2025 assessment for the current
Western and Central Pacific skipjack unit, using data through 2024. The 2025
assessment is therefore the relevant source for this screen.

The 2025 MULTIFAN-CL assessment is internally age-structured, but its observed
data likelihoods are catch-conditioned fishery catches, length-frequency data,
aggregate fishery CPUE, and tag release/recapture data. The official assessment
report says the model uses 32 extraction fisheries and 10 CPUE index fisheries.
It does not use observed catch-at-age or an age-specific abundance index. The
public TAF inputs confirm length frequencies in 2-cm fork-length bins for
1972–2024, with no age-composition or age-length-key likelihood. Without
age-observation information, these length-only observations do not support a
verified catch-at-age reconstruction for tinyAM.

Age-specific weight, maturity, and reproductive-potential surfaces are derived
inside the assessment from estimated growth, a length-weight relationship, a
maturity-at-length ogive, and a fecundity adjustment. Natural mortality follows
an inverse-length Lorenzen pattern with an estimated scale. These fitted or
derived surfaces are not observed age-specific inputs.

The public TAF diagnostic outputs do include recruitment, biomass and spawning
biomass, N-at-age for ages 1–16 across eight regions, and annual F-at-age
through 2024. These outputs do not make the underlying likelihood inputs
age-disaggregated, so the current unit is screened ineligible for the
age-structured tinyAM candidate set. No canonical database values were added.

One input-quality caveat remains: the pinned TAF CPUE CSV contains a single
record with `year = 36` and `season = 14.333`. This anomaly should be resolved
before reusing that CPUE file. It does not alter the finding that the assessment
has no age-specific abundance index.

## Sources and local cache

- [WCPFC 2025 assessment, SC21-SA-WP-02 Rev.03](https://meetings.wcpfc.int/node/26679)
- [WCPFC background analyses and data inputs, SC21-SA-IP-03 Rev.01](https://meetings.wcpfc.int/system/files/2025-08/SC21-SA-IP-03_SKJ_background_paper_rev1-Teears_et_al.pdf)
- [WCPFC SC21 summary and acceptance record](https://meetings.wcpfc.int/file/19534/download)
- [SPC 2025 diagnostic model](https://github.com/PacificCommunity/ofp-sam-skj-2025-diagnostic/tree/f33de3a9d6f3acb02a0717340c1cc325f89f2eb6)
- [SPC 2025 ensemble repository](https://github.com/PacificCommunity/ofp-sam-skj-2025-ensemble)

The reports and selected TAF input/output files are cached under
`source_cache/discovery_noaa_wcpfc_skipjack_2025/`, with retrieval dates,
source URLs, byte sizes, and SHA-256 hashes in `sources.csv`.
