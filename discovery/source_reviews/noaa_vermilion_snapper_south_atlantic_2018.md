# South Atlantic vermilion snapper (NOAA:10257)

**Review date:** 2026-10-31
**Scientific name:** *Rhomboplites aurorubens*
**Assessment unit:** South Atlantic, Southern Atlantic Coast
**Latest accepted full assessment located:** SEDAR 55, 2018; assessment years 1946–2016
**NOAA Stock SMART:** run 8220; Full Update; full acceptance

## Unit and assessment identity

NOAA Stock SMART distinguishes the South Atlantic management unit (NOAA:10257)
from the Gulf of Mexico unit (NOAA:10256). They share a scientific name but are
different assessment units and must not be matched or combined.

SEDAR 55 is the latest accepted full catch-at-age assessment located. It covers
1946–2016, with final report publication in April 2018. The 2023 South Atlantic
interim analysis was not accepted as a basis for catch advice: the SSC reported
that its index-based approach did not fit the index and did not inform population
estimates or management advice. The SAFMC's 2026 draft terms of reference and
September 2026 scheduling materials describe a future update planned for 2027;
no completed replacement run was located as of this review.

## Inputs and age-data screen

| Input | Verified assessment information | Coverage and units |
|---|---|---|
| Landings and discards | Annual removals from commercial handline, historic trawl, commercial other, headboat, and general recreational fleets. Dead discards are modeled separately. | Commercial landings: 1,000 lb whole weight; recreational landings and dead discards: 1,000 fish. Commercial series span 1958–2016 (historic trawl 1961–1962; other 1971–2016); recreational removals 1947–2016. |
| Fishery age compositions | Weighted compositions for commercial handline, headboat, and general recreational fleets. The source papers describe final reweighted age data; the assessment excludes low-sample years under its trip threshold. | Calendar ages 1–12+, with age 12 the accumulator group. Sample years vary by fleet; the report provides the years and sample sizes used. Compositions are not themselves observed catch numbers-at-age. |
| Survey age information | SERFS chevron-trap age compositions are included in the model. | 1990–2016, ages 1–12+. The MARMAP Florida snapper-trap index (1983–1987) is an aggregate index without age compositions. The assessment fits aggregate indices, not an age-specific abundance index. |
| Weights | Growth was estimated externally and treated as fixed. Mean length follows von Bertalanffy parameters L∞ = 506 mm, K = 0.12/year, t0 = −3.5 years; whole weight is calculated as `2.1e−5 × TL^2.91`, with TL in mm and weight in kg. The report tabulates life-history quantities by age. | Weight-at-age is model-derived from the fixed growth and length-weight relationship. |
| Maturity and spawning | Female maturity is age-specific: 91% at age 1 and 99–100% at ages 2–12+. Spawning output includes female proportion, batch fecundity, and age-specific spawning frequency. | The official spawning-stock measure is egg production, not conventional SSB biomass. |
| Natural mortality | Fixed, age-decreasing Lorenzen M, scaled to match cumulative survival through age 19 under constant M = 0.22/year. | No estimated M-at-age series. Charnov M is a sensitivity, not the base run. |
| Timing | Annual model; spawning is computed at midyear and index predictions use midyear abundance (commercial handline predictions use weight at age). | Specific month-level timing for each survey index was not established in the reviewed sources. |

The five fleets' annual landings and the weighted age compositions provide the
source quantities for a documented catch-at-age reconstruction. Commercial
landings are in weight and must be converted using the assessment's age-specific
weights; recreational landings are in numbers. The original totals and
compositions should remain distinct in canonical records, with any reconstructed
age-specific removals documented downstream.

## Reported outputs

SEDAR 55 reports numerical base-run abundance-at-age (Table 6, thousands of fish),
biomass-at-age (Table 7, thousands of pounds whole weight), and fishing mortality
at age (Table 11, per year) for the historical model ages 1–12+. It also reports
annual recruitment, total biomass, egg-production spawning stock, status
indicators, and reference points. The mixed Monte Carlo/bootstrap uncertainty
analysis covers selected aggregate and status quantities; the reviewed tables do
not provide age-specific uncertainty for N-at-age or F-at-age.

## Screening decision

This is a **new, screened, eligible candidate** for detailed source curation.
The accepted assessment combines annual removals, fishery and survey age
compositions, aggregate abundance indices, and age-specific biological inputs.
Those source quantities support a documented catch-at-age reconstruction while
preserving fleet units and composition weights. The official outputs include
numeric N-at-age and F-at-age. Eligibility here means the sources warrant
curation; it does not imply that every series is ready for tinyAM or that the
assessment's egg-production spawning measure is directly comparable to tinyAM
SSB.

No canonical database values were imported, and no tinyAM translation was
attempted. Source files are cached locally in the gitignored directory
`source_cache/discovery_noaa_south_atlantic_vermilion_2026/`; its `sources.csv`
records source URLs, retrieval dates, revisions, byte sizes, and SHA-256 hashes.

## Sources

- [SEDAR 55 final stock assessment report](https://sedarweb.org/documents/sedar-55-stock-assessment-report-south-atlantic-vermilion-snapper/)
- [SEDAR 55 commercial age and length compositions, WP06](https://sedarweb.org/documents/s55wp06-commercial-age-and-length-compositions-for-u-s-vermilion-snapper-rhomboplites-aurorubens/)
- [SEDAR 55 recreational age and length compositions, WP09](https://sedarweb.org/documents/s55wp09-south-atlantic-u-s-vermilion-snapper-rhomboplites-aurorubens-age-and-length-composition-from-the-recreational-fisheries/)
- [SEDAR 55 SERFS chevron-trap index, WP02](https://sedarweb.org/documents/s55wp02-vemilion-snapper-fishery-independent-index-of-abundance-in-us-south-atlantic-waters-based-on-a-chevron-trap-survey-1990-2016/)
- [SEDAR 55 reproductive life history, WP03](https://sedarweb.org/documents/s55wp03-update-of-vermilion-snapper-rhomboplites-aurobens-reproductive-life-history-from-the-marmap-serfs-program/)
- [SEDAR 55 trap and video index, WP07](https://sedarweb.org/documents/s55wp07-integrated-data-from-chevron-traps-and-video-cameras-into-a-standardized-index-of-abundance-for-vermilion-snapper-rhomboplites-aurorubens/)
- [October 2023 SAFMC SSC final report](https://safmc.net/documents/fc1_a1e_ssc_oct2023_final_report-pdf/)
- [August 2026 draft terms of reference](https://safmc.net/documents/secad_a4c_south_atlantic_vermilion_snapper_tors_aug2026_draft_v3-pdf/)
- [September 2026 assessment schedule](https://safmc.net/documents/secad_a2_sedar_assessment_scheduling_grid-pdf/)
