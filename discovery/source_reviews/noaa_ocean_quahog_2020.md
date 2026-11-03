# NOAA Atlantic ocean quahog (2020 update)

## Assessment sources

NOAA Stock SMART ID 10788 is *Arctica islandica* on the Atlantic Coast. The latest
operational assessment located is the 2020 update (Stock SMART assessment 10663;
data through 2019), which updates the 2017 Stock Synthesis benchmark. Stock SMART
records Full acceptance and identifies the run as operational. The MAFMC-hosted
[2020 update report](https://www.mafmc.org/s/8_ocean_quahog_Update_2020_07_27_113541-k6xk.pdf)
labels itself a draft working paper for peer review only, so that qualification is
retained. NOAA's current [species science page](https://www.fisheries.noaa.gov/species/ocean-quahog/science)
still identifies stock status as supported by the 2020 assessment.

The [2017 benchmark report](https://repository.library.noaa.gov/view/noaa/14203/noaa_14203_DS1.pdf)
and [SARC summary](https://repository.library.noaa.gov/view/noaa/14209) provide the
model background. The benchmark used an age-structured Stock Synthesis model but
states that age data were scarce or unavailable for the assessment, and describes
commercial and survey length compositions. Age structure in a model is not the same
as observed numbers-at-age in the likelihood.

The 2020 report is cached locally at
`source_cache/noaa_ocean_quahog_2020/OceanQuahogUpdateMT2020.pdf`. Its source URL,
retrieval date, and SHA-256 checksum are recorded in the adjacent `sources.csv`.

## Inputs and outputs reviewed

The 2020 update reports commercial assessment catch in metric tonnes through 2019,
with landings and discards summarized by northern and southern areas. It updates
commercial length-composition data, not catch-at-age. No new survey data were
collected after the benchmark. The reported NEFSC clam-survey series extend through
2016 and are aggregate biomass indices: Research Set-Aside indices in kg per tow
and MCD indices in swept-area numbers, with approximate 90% log-normal intervals.
They are not age-specific abundance indices.

The benchmark fixed natural mortality at 0.02. It includes a maturity ogive and
growth/weight-at-length biology in the model, but the reviewed 2020 products do not
provide a recoverable numerical weight-at-age or maturity-at-age table suitable for
canonical import. Survey timing fractions were not reported in the reviewed
materials. The 2020 report gives aggregate SSB (3,651 thousand tonnes in 2019),
fully selected F (0.005 in 2019), recruitment indexed to unfished recruitment, and
aggregate survey fits; it does not publish annual N-at-age, F-at-age, or M-at-age.

## Screening decision

This is an official and informative aggregate assessment, but it does not meet the
current age-disaggregated input/output screen. Catch totals and length compositions,
aggregate survey biomass indices, and aggregate population summaries do not supply
observed catch-at-age, age-specific abundance indices, or comparable age-specific
population outputs. It is therefore recorded as a new ineligible candidate; no
canonical numerical assessment data were added. Reconsider only if the underlying
model files expose age-specific observations and outputs that are absent from the
reviewed public products.
