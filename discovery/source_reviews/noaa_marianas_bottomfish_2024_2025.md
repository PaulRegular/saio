# NOAA Guam and CNMI bottomfish assessment updates (2024–2025)

## Current assessment units

NOAA Stock SMART lists fully accepted JABBA updates for Guam (Stock SMART ID
11696, 2024 assessment, data through 2023) and the Commonwealth of the Northern
Mariana Islands (CNMI; ID 11731, 2025 assessment, data through 2023). These are
two separate management complexes, each comprising 13 Mariana Archipelago
Bottomfish Management Unit Species (BMUS). They remain aggregate multispecies
units; the species are not counted as separate candidate cases.

The latest detailed Guam assessment is Bohaboy and Matthews' 2024 update
(PIFSC-162). The latest detailed CNMI assessment is their 2025 update
(PIFSC-179). Both update the 2019 benchmark model with newer data and retain a
state-space Bayesian surplus-production model implemented in JABBA. The 2026
CNMI administrative report describes a fishery-independent life-history survey
that collected age, growth, maturity, and mortality samples; it is not a newer
stock-assessment run and those samples were not inputs to the 2025 JABBA model.

## Inputs and outputs

| Unit | Assessment data years | Model inputs | Comparable outputs |
|---|---:|---|---|
| Guam | 1982–2023 | Annual aggregate catch in thousand pounds with catch CVs; annual standardized boat-based creel CPUE in pounds per gear-hour with log-scale SEs | Annual exploitable biomass, relative biomass, harvest rate, stock-status probabilities, and catch projections through 2029 |
| CNMI | 2000–2023 | Annual aggregate catch in thousand pounds with catch CVs; annual standardized boat-based creel CPUE in pounds per gear-hour | Annual exploitable biomass, relative biomass, harvest rate, stock-status probabilities, and catch projections for 2026–2030 |

Both assessments use complex-level catch and CPUE observations. The CPUE is
standardized with delta binomial-lognormal models; it is not an age-specific
abundance index. The assessment likelihoods do not use catch-at-age, age
compositions, or age-specific survey indices. The reports provide biomass and
harvest-rate trajectories, not numerical abundance-at-age or fishing-mortality-
at-age series. Therefore these two current units are ineligible for the
age-disaggregated candidate pool even though their reports contain detailed
aggregate inputs, assumptions, and outputs.

The assessment outputs should not be confused with age-structured population
surfaces: JABBA estimates total exploitable biomass and harvest rate for each
complex. It does not provide stock-specific weights-at-age, maturity-at-age,
age-specific natural mortality, survey timing for an age index, or age-based
uncertainty outputs.

## Candidate decisions

- NOAA 11696 maps to the distinct Guam bottomfish complex and is screened
  ineligible for the age-disaggregated candidate pool.
- NOAA 11731 maps to the distinct CNMI bottomfish complex and is screened
  ineligible for the age-disaggregated candidate pool.
- The 2026 CNMI fishery-independent life-history survey may support future
  assessments, but it does not turn the 2025 aggregate production model into an
  age-based assessment and is not used to fill its input gaps.
- No canonical stock, assessment, input, or output records were added.

## Sources and local cache status

The pinned NOAA Stock SMART snapshot and source metadata are recorded in
`source_cache/discovery_noaa_marianas_bottomfish_2025/sources.csv`. The 2024
Guam, 2025 CNMI, and 2026 CNMI life-history reports are publicly available from
the NOAA repository, but direct local PDF downloads returned HTTP 403 in this
environment. Their official repository checksums are retained in the manifest;
no access-denied response was stored as if it were a source document.

- [2024 Guam bottomfish assessment, PIFSC-162](https://repository.library.noaa.gov/view/noaa/61479)
- [2025 CNMI bottomfish assessment, PIFSC-179](https://repository.library.noaa.gov/view/noaa/71158)
- [2026 CNMI bottomfish life-history survey report, AR-26-02](https://repository.library.noaa.gov/view/noaa/74400)
- [2019 Mariana bottomfish benchmark, PIFSC-86](https://repository.library.noaa.gov/view/noaa/21164)
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart)
