# South Atlantic vermilion snapper (noaa_vermilion_snapper_south_atlantic)

## South Atlantic vermilion snapper, SEDAR 55

SAIO stock `noaa_vermilion_snapper_south_atlantic`. Assessment `noaa_vermilion_snapper_south_atlantic_sedar55_2018`.

### Unit and assessment

NOAA Stock SMART identifies stock 10257 as South Atlantic vermilion snapper
(*Rhomboplites aurorubens*), distinct from Gulf of Mexico vermilion snapper
(stock 10256). The latest accepted full assessment located for this current
unit is SEDAR 55 (2018), using the Beaufort Assessment Model base run
`VSX.tpl`. The fitted observations extend through 2016; model estimates extend
through 2017. The 2023 interim analysis did not replace this full assessment.

The final SEDAR report and working papers document the assessment inputs. The
final commercial age-composition addendum presents its values as figures, so
the draft numeric table is not used as final data. Exact model-ready inputs and
outputs were recovered from the NOAA NMFS Office of Science and Technology
`stockplotr` repository's pinned `VermilionSnapper.rdat` artifact. Its metadata
identifies SEDAR 55, `VSX.tpl`, and the 2023-02-27 output file. This is a
machine-readable fit object, not original model source code or raw sampling
records. Its N-at-age and biomass-at-age values for 1946 agree with SEDAR 55
Tables 6 and 7 after the published unit conversions.

### Inputs captured

- Annual landings and discards are retained in their source fleet scales.
  Commercial landings are 1000 lb whole weight; recreational landings and
  discard series are 1000 fish. Discard observations are recorded before
  fleet-specific discard mortality.
- Five aggregate relative abundance indices and their source CVs are included:
  commercial handline, headboat, general recreational, SERFS chevron trap/video,
  and MARMAP Florida snapper trap. The SERFS survey also has an age composition,
  but no age-specific abundance index is reported. A single within-year
  sampling fraction was not found for these series.
- Age compositions are captured for commercial handline, headboat, general
  recreational, and SERFS trap/video observations. Length compositions are
  retained for the fleets supplied by the fit object. The age range is 1-12+;
  age 12 is the plus group. Effective sample sizes are stored on composition
  rows, with raw fish counts kept separately when available. Some length
  compositions have no reported positive effective sample size, which remains
  blank.
- The age-error transition matrix is retained without renormalizing its
  rounded source values. Columns represent true ages and rows represent
  observed ages.
- The fit object supplies mean length, whole weight, female maturity, female
  proportion, combined reproductive potential, and fixed age-specific M for
  ages 1-12+. M is an input, not an estimated annual output.

### Outputs and limits

The fit object supplies N-at-age, biomass-at-age, F-at-age, total abundance,
age-1 recruitment, total biomass, apical F, and egg-production SSB through
2017. SSB is reported in 1e12 eggs at mid-year and is not mature biomass in
tonnes. The output artifact does not provide age-specific standard errors or
intervals. Some length-composition effective sample sizes, the original model
code, raw sampling records, and a common index timing fraction were not
recovered. The assessment remains marked partial to reflect these gaps.

### Sources

- [SEDAR 55 final assessment report](https://sedarweb.org/documents/sedar-55-stock-assessment-report-south-atlantic-vermilion-snapper/)
- [SEDAR 55 commercial age and length compositions (WP06)](https://sedarweb.org/documents/s55wp06-commercial-age-and-length-compositions-for-u-s-vermilion-snapper-rhomboplites-aurorubens/)
- [SEDAR 55 life-history update (WP03)](https://sedarweb.org/documents/s55wp03-update-of-vermilion-snapper-rhomboplites-aurobens-reproductive-life-history-from-the-marmap-serfs-program/)
- [Pinned NOAA NMFS OST model artifact](https://github.com/nmfs-ost/stockplotr/blob/1bd3ec5dfbb544c19d319f7fd24d2628c57c7721/inst/extdata/VermilionSnapper.rdat)
- [SAFMC SSC October 2023 report](https://safmc.net/documents/fc1_a1e_ssc_oct2023_final_report-pdf/), reviewed to distinguish the interim analysis from a new full assessment.

Source files, retrieval dates, revisions, sizes, and SHA-256 checksums are
recorded in `provenance/noaa_vermilion_snapper_south_atlantic_sedar55_2018/sources.csv`.

## South Atlantic vermilion snapper (NOAA:10257)

**Review date:** 2026-10-31
**Scientific name:** *Rhomboplites aurorubens*
**Assessment unit:** South Atlantic, Southern Atlantic Coast
**Latest accepted full assessment located:** SEDAR 55, 2018; assessment years 1946–2016
**NOAA Stock SMART:** run 8220; Full Update; full acceptance

### Unit and assessment identity

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

### Inputs and age-data screen

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

### Reported outputs

SEDAR 55 reports numerical base-run abundance-at-age (Table 6, thousands of fish),
biomass-at-age (Table 7, thousands of pounds whole weight), and fishing mortality
at age (Table 11, per year) for the historical model ages 1–12+. It also reports
annual recruitment, total biomass, egg-production spawning stock, status
indicators, and reference points. The mixed Monte Carlo/bootstrap uncertainty
analysis covers selected aggregate and status quantities; the reviewed tables do
not provide age-specific uncertainty for N-at-age or F-at-age.

### Screening decision

This is a **new, screened, eligible candidate** for detailed source curation. The accepted assessment combines annual removals, fishery and survey age
compositions, aggregate abundance indices, and age-specific biological inputs. Those source quantities support a documented catch-at-age reconstruction while
preserving fleet units and composition weights. The official outputs include
numeric N-at-age and F-at-age. Eligibility here means the sources warrant
curation.

No canonical database values were imported was
attempted. Source files are cached locally in the gitignored directory
`source_cache/noaa_vermilion_snapper_south_atlantic/noaa_south_atlantic_vermilion_2026/`; its `sources.csv`
records source URLs, retrieval dates, revisions, byte sizes, and SHA-256 hashes.

### Sources

- [SEDAR 55 final stock assessment report](https://sedarweb.org/documents/sedar-55-stock-assessment-report-south-atlantic-vermilion-snapper/)
- [SEDAR 55 commercial age and length compositions, WP06](https://sedarweb.org/documents/s55wp06-commercial-age-and-length-compositions-for-u-s-vermilion-snapper-rhomboplites-aurorubens/)
- [SEDAR 55 recreational age and length compositions, WP09](https://sedarweb.org/documents/s55wp09-south-atlantic-u-s-vermilion-snapper-rhomboplites-aurorubens-age-and-length-composition-from-the-recreational-fisheries/)
- [SEDAR 55 SERFS chevron-trap index, WP02](https://sedarweb.org/documents/s55wp02-vemilion-snapper-fishery-independent-index-of-abundance-in-us-south-atlantic-waters-based-on-a-chevron-trap-survey-1990-2016/)
- [SEDAR 55 reproductive life history, WP03](https://sedarweb.org/documents/s55wp03-update-of-vermilion-snapper-rhomboplites-aurobens-reproductive-life-history-from-the-marmap-serfs-program/)
- [SEDAR 55 trap and video index, WP07](https://sedarweb.org/documents/s55wp07-integrated-data-from-chevron-traps-and-video-cameras-into-a-standardized-index-of-abundance-for-vermilion-snapper-rhomboplites-aurorubens/)
- [October 2023 SAFMC SSC final report](https://safmc.net/documents/fc1_a1e_ssc_oct2023_final_report-pdf/)
- [August 2026 draft terms of reference](https://safmc.net/documents/secad_a4c_south_atlantic_vermilion_snapper_tors_aug2026_draft_v3-pdf/)
- [September 2026 assessment schedule](https://safmc.net/documents/secad_a2_sedar_assessment_scheduling_grid-pdf/)
