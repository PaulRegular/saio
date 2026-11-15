# NOAA Atlantic halibut (2024)

## Identity

NOAA Stock SMART inventory row `NOAA:10056` describes Atlantic halibut
(*Hippoglossus hippoglossus*) in the Northwestern Atlantic and lists 2024 as
its latest assessment year. The NOAA assessment uses U.S. catch and survey
information, includes Canadian landings in the catch series, and discusses
uncertainty in how the U.S. assessment unit relates to the larger halibut stock
centered in Canadian waters. The DFO inventory separately lists Canadian
units in NAFO 3NOPs4VWX5Zc and 4RST. The available sources do not establish a
one-to-one stock-unit match, so this candidate remains identity-ambiguous and
is not added as a canonical stock.

## Official assessment

The 2024 Management Track update extends the existing First and Second
Derivative (FSD) approach through 2023 and provides catch advice for 2025.
The Assessment Oversight Panel recommended Level 1 direct delivery. The
assessment report describes FSD as an empirical method based on recent trends
and changes in trends across three abundance indices; it has no underlying
population dynamics and does not estimate stock status, biomass, fishing
mortality, or population projections.

## Age-structured input screen

The 2024 assessment does not use a catch-at-age series, age-specific abundance
indices, weights-at-age, maturity-at-age, or an estimated natural-mortality
process. Its catch inputs are aggregate annual catches by disposition in
metric tonnes. The abundance information consists of the NEFSC fall bottom
trawl survey biomass index and two commercial discard-ratio indices, not
age-specific indices. The report identifies additional age and length data as
information needed to support a more sophisticated future assessment.

The report specifies discard mortality assumptions of 0.76 for trawl gear and
0.30 for gillnet gear. These are not natural-mortality estimates. The 2020
fall-survey index was interpolated from 2019 and 2021; zero survey observations
in 2018 and 2019 were treated as missing in the selected approach.

## Reported outputs and decision

The report provides catch-multiplier values and catch advice, with total and
component catches in metric tonnes for 2016–2023. It also plots the three
abundance indices through 2023 with 90% lognormal intervals. It does not
provide age-specific or population-state outputs. The candidate is therefore
screened **ineligible for the current age-disaggregated assessment set**;
this is not a statement that the aggregate data have no value for other
analyses.

## Sources

- [2024 Management Track assessment report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9875)
- [October 2024 SSC report](https://d23h0vhsm26o6d.cloudfront.net/SSC-report-groundfish-10_21_24.pdf)
- [Assessment Oversight Panel meeting materials](https://www.fisheries.noaa.gov/event/2024-assessment-oversight-panel-meeting-september-stocks)
- [NOAA Stock SMART entry](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10056)
- [DFO Atlantic halibut stock profile](https://www.dfo-mpo.gc.ca/species-especes/profiles-profils/atl-halibut-fletan-atl-eng.html)

The report and SSC source files are cached under
`source_cache/discovery_noaa_atlantic_halibut_2024/`. The retrieved report is
labelled a draft working paper for peer review; it is the detailed 2024 report
linked from the official meeting materials. No source model object or
age-structured input archive was identified because the reported method is
empirical and non-age-structured.
