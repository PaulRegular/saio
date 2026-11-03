# Western Atlantic skipjack tuna, ICCAT 2022

## Identity and latest assessment

NOAA Stock SMART 10158 identifies Western Atlantic skipjack (*Katsuwonus
pelamis*). No corresponding canonical tinyAM stock record was found. ICCAT's
assessment calendar lists the last assessment as 2022 and the advice method as
Stock Synthesis 3.30.18. The latest executive summary located states that the
last eastern and western skipjack assessments were conducted in 2022 and
summarizes Western Atlantic status for 2020. Later management-strategy
operating-model work used updated data through 2024 but is not a new stock
assessment fit.

The advice model covers 1952–2020, with one area, combined sexes, annual time
steps, ages 0–6+, and five fleets and abundance indices. The stock unit spans
the western Atlantic from the U.S. coast to southern Brazil. No canonical
numerical assessment records were added.

## Inputs and outputs

The model uses annual fleet catch in mass, treated as known with a CV of 0.01,
plus seasonal catch-at-size/size-composition information. Fork lengths are
measured in centimetres and represented in 2-cm bins from 20 to 156 cm. Size
compositions are fitted with a multinomial likelihood. The model also uses five
aggregate CPUE indices with lognormal errors and within-year timing adjustments.

The official data-preparatory report states that there were no plans to use
catch-at-age in the assessment and that no effort would be made to calculate
it. The age-structured model therefore does not provide catch-at-age
observations or fitted age compositions. The size samples and growth model do
not by themselves establish an observed age-composition series for reconstructing
catch-at-age. No age-specific survey index was located. Consequently, the
assessment is not eligible for the current age-disaggregated candidate set,
even though Stock Synthesis models age-specific population dynamics.

Biology is combined-sex. Growth follows a von Bertalanffy model. The adopted
length-weight relationship is `7.48e-06 * fork length(cm)^3.253`; maturity is
50% at 42 cm and complete at 55 cm. SSB is the summed biomass of mature fish.
The advice uncertainty grid evaluates alternative natural-mortality-at-age
hypotheses across growth quantiles and steepness values. Its runs use Lorenzen
scaling anchored to the age-6 mortality hypothesis associated with each growth
scenario.

The assessment publishes SSB and F trajectories, relative stock-status
estimates, uncertainty summaries and projections through 2020. The latest
summary reports 2020 relative biomass ratio of 1.60 (95% interval 0.90–2.87) and relative
F of 0.41 (0.19–0.89) across the uncertainty grid. Estimated numbers-at-age are
plotted, but numeric annual N-at-age and F-at-age tables were not located. The
2024–2025 executive summary's later catch totals are not observations from the
2022 fitted model.

## Screening decision

The unit is **ineligible** for the current age-disaggregated source set. The
production model's observation inputs are catch in mass, catch-at-size/size
compositions and aggregate CPUE; the official data-preparatory report explicitly
says catch-at-age was not planned. No age compositions or age-specific survey
observations are reported. A model's internal age structure and plotted
age-specific fitted states do not substitute for the missing age-based inputs.

No assessment event or numerical input/output values were added to the
canonical database. Import status remains `not_started`.

## Sources

- [ICCAT assessment calendar](https://iccat.int/en/assess.html)
- [2022 Skipjack Data Preparatory Meeting report](https://www.iccat.int/Documents/SCRS/DetRep/SKJ_DP_ENG.pdf)
- [2022 Skipjack Stock Assessment Meeting report](https://www.iccat.int/Documents/SCRS/DetRep/SKJ_SA_ENG.pdf)
- [SCRS/2022/001: fleet structure and decision not to calculate catch-at-age](https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010001.pdf)
- [SCRS/2022/093: final inputs and assessment settings](https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010907.pdf)
- [SCRS/2022/098: Western skipjack Stock Synthesis model](https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010611.pdf)
- [SCRS/2022/130: final Stock Synthesis status and projections](https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010701.pdf)
- [ICCAT 2024–2025 Skipjack executive summary](https://www.iccat.int/Documents/SCRS/ExecSum/SKJ_ENG.pdf)

The reviewed files were downloaded into the gitignored
`source_cache/discovery_iccat_western_skipjack_2022/`; `sources.csv` records the
retrieval date, source URL and SHA-256 checksum for each cached file.
