# NOAA Southeastern U.S. yellowtail snapper, SEDAR 96 (2025)

## Screen result

NOAA Stock SMART ID 11081 is the single Southeastern U.S. yellowtail snapper
management stock shared by the South Atlantic and Gulf councils. The latest
fully accepted production assessment found is the 2025 operational SEDAR 96
assessment, with data through 2023. Its assessment model is Stock Synthesis
3.30.15, a one-area, age- and size-structured model for Florida waters; the
modeled ages are 0 through 20. This unit has no exact canonical-stock match.

The assessment has three fleets (commercial, headboat, and MRIP) and four
aggregate abundance indices (commercial CPUE, MRIP CPUE, Reef Fish Visual
Census Florida Keys, and Dry Tortugas). Age observations include headboat and
MRIP landed age compositions for 1981–2023, weighted to landings-at-age, and
commercial age samples from 1992–2023 configured as conditional
age-at-length data. The report also describes length compositions for catches,
discards, and indices, plus fishery-independent conditional age-at-length
data. Those fishery-independent age data are not linked to an abundance index.

The assessment uses a fixed maturity-at-age schedule carried forward from
SEDAR 64, fixed age-specific natural mortality derived from a Lorenzen
relationship and external growth model, and a fixed length-weight relationship
of `weight_kg = 2.574e-5 * fork_length_cm^2.8797`. It is annual, with surveys,
composition data, and conditional age-at-length observations configured at
mid-year (July 1). The Dry Tortugas RVC index samples May–July in its survey
years.

The report says the model estimates a full N-at-age time series (thousands of
fish), biomass, female spawning stock biomass, age-0 recruitment, and fishing
mortality. Tables include annual total and spawning biomass, recruitment, and
age-4 and fleet-apical fishing mortality. The exact N-at-age surface is not
published as a numeric table or native model output in the reviewed public
bundle. The report's age compositions are shown in figures, and the 2024 SEDAR
document list does not list a model or input-data archive. The accessible
SEDAR96-WP-07 describes age-sampling programs, rather than supplying the model
vectors.

Eligibility therefore remains **unresolved** for an age-disaggregated
comparison. The stock is clearly modeled by an age-structured production
assessment, but its public bundle does not provide model-ready annual age
vectors, an age distribution linked to the fishery-independent abundance
indices, or the numerical N-at-age output surface. A catch age composition
cannot stand in for the RVC index age composition. Do not derive those values
from unrelated observations or approximate figures without recovering and
documenting the underlying data.

## Source cache

The January 2025 SEDAR 96 final report, SEDAR96-WP-07, and the SEDAR 96
document list are cached locally under the ignored directory
`source_cache/discovery_noaa_yellowtail_snapper_sedar96_2025/`. Their URLs,
retrieval date, revisions, and SHA-256 checksums are in its `sources.csv`
manifest. No canonical stock, assessment, input, or output records were added.

## Sources

- [SEDAR 96 Southeastern U.S. Yellowtail Snapper final assessment report](https://sedarweb.org/documents/sedar-96-southeastern-us-yellowtail-snapper-final-stock-assessment-report/), January 2025.
- [SEDAR96-WP-07: Size and age information for Southeastern U.S. Yellowtail Snapper](https://sedarweb.org/documents/sedar-96-wp-07size-and-age-information-for-southeastern-us-yellowtail-snapper-ocyurus-chrysurus-collected-in-association-with-fishery-dependent-projects/), submitted September 12, 2024.
- [SEDAR 96 document list](https://sedarweb.org/documents/sedar-96-southeastern-us-yellowtail-snapper-document-list/), dated October 31, 2024.
- [NOAA Stock SMART, yellowtail snapper stock 11081](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11081).
