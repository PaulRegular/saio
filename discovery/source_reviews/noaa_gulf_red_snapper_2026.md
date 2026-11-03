# Gulf red snapper, SEDAR 98 (2026)

## Unit and current assessment

NOAA Stock SMART inventory row 10230 identifies the Gulf of Mexico red snapper
unit, but its latest listed assessment is from 2021. The latest detailed run
located is SEDAR 98, with a terminal data year of 2023. Its final Stock
Assessment Report was disseminated in October 2026. The report says the Gulf
Councils' Scientific and Statistical Committee will review it, so this screen
does not claim Council certification. NOAA:10230 is distinct from NOAA:10231,
the Southern Atlantic Coast unit.

SEDAR 98 models the Gulf unit in West, Central, and East areas. These are model
areas within one management unit, not three separate candidate stocks.

## Inputs and biology

SEDAR 98 is a three-area Stock Synthesis 3.30.20 age-structured assessment,
starting in 1950 and ending in 2023. Fishery inputs combine fleet- and
area-specific catch totals with year-specific conditional age-at-length
compositions for commercial and recreational fleets. The report gives
commercial landings in whole-weight pounds, converted to metric tons, and
recreational landings in thousands of fish. This is not a standalone observed
catch-numbers-at-age table. The SEDAR 98 commercial and recreational data
reports document the age samples and composition construction; the age-data
report summarizes observations collected from 1980 through 2023, with no ages
processed for 1981–1985. Model compositions use a plus group at age 20.

The assessment uses aggregate annual survey indices together with age
compositions for SEAMAP trawl, G-FISHER video, and SEFSC bottom-longline
surveys. Several survey age compositions are derived from length compositions
through age-length keys; they are not separate age-specific abundance indices.

Growth and length-weight relationships are fixed. Spatial growth curves were
estimated externally in SEDAR 74; length-weight parameters are common among
areas. Age-specific maturity is a fixed, time-invariant logistic curve by area;
Central and East share the East-area estimates. Natural mortality is a fixed
age-specific Lorenzen vector, scaled from 0.104 per year, with age-0 and age-1
values set to 2.0 and 1.2 per year. The vector is constant over time and space.
The report uses weight as the proxy for fecundity in SSB.

## Outputs and screening decision

The final report provides annual area-specific total biomass, exploitable
biomass, SSB, age-1+ abundance, age-0 recruitment, and exploitation rates for
1950–2023. Exploitation rate is not instantaneous F-at-age. Numeric N-at-age
and F-at-age arrays were not found in the published report. The reported
population and recruitment series are comparable official outputs for source
curation, while the absence of age-specific output surfaces remains a
limitation for detailed model comparison.

This unit is eligible for source curation: public sources document an
age-structured production assessment, fleet catch totals, fishery
age-at-length compositions, survey indices and compositions, age-based biology,
and population outputs. The source record should preserve the assessment's
native totals and conditional compositions; it should not fabricate
catch-at-age or age-specific fitted outputs. Survey timing suitable for a
tinyAM translation still needs to be established. The candidate is not part of
a selected import batch, and no canonical numerical records were imported.

## Sources

- [SEDAR 98 final Stock Assessment Report](https://sedarweb.org/documents/sedar-98-gulf-red-snapper-final-stock-assessment-report/)
- [SEDAR 98 commercial length and age compositions, DW-06](https://sedarweb.org/documents/sedar-98-dw-06-gulf-of-mexico-red-snapper-lutjanus-campechanus-commercial-landings-preliminary-length-and-age-compositions/)
- [SEDAR 98 recreational length and age compositions, DW-07](https://sedarweb.org/documents/sedar-98-dw-07-gulf-of-mexico-red-snapper-lutjanus-campechanus-length-and-age-compositions-from-the-recreational-fishery/)
- [SEDAR 98 Gulf age-data description, DW-09](https://sedarweb.org/documents/sedar-98-dw-09-description-of-red-snapper-lutjanus-campechanus-age-data-collected-from-the-northern-gulf-of-mexico-from-1980-2023/)
- [SEDAR 98 assessment page and project status](https://sedarweb.org/assessments/sedar-98-gulf-of-mexico-red-snapper/)
- [NOAA Stock SMART inventory row 10230](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10230&stockname=Red+snapper+-+Gulf+of+Mexico)

The final report and three cited age-data papers are cached in
`source_cache/discovery_noaa_gom_red_snapper_2026/`. Their URLs, retrieval
date, SHA-256 checksums, and brief descriptions are recorded in `sources.csv`.
