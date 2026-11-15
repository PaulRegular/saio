# NOAA South Atlantic black sea bass (Stock SMART 10310)

Reviewed 2026-10-29. This is the current South Atlantic management stock south
of Cape Hatteras, North Carolina. No matching canonical stock record was found;
the source-specific Stock SMART identifier is retained and a provisional
candidate unit is assigned.

The newest detailed public assessment located is the March 2025 SEDAR 76 Update,
using data through 2023. It is an age-structured Beaufort Assessment Model
(BAM) catch-age assessment for ages 0–11+, with five fleets. It fits annual
landings in thousands of pounds whole weight, dead discard mortalities in
thousands of fish, fleet age and length compositions, and four abundance
indices. Age compositions are not present for every fleet-year; length
compositions are used where age samples are absent or sparse. The report
describes catch and composition inputs but does not provide a complete
machine-readable set of annual age-composition matrices. Those source arrays
and a pinned current model-input bundle remain unverified.

The model uses an age-specific Lorenzen natural-mortality curve, rescaled so
survival over fully selected ages 3–11 matches a constant M of 0.375 per year.
Length-at-age and weight-at-age are based on a von Bertalanffy growth model and
length-weight relationship. Female maturity and male sex transition are age
based. The report tabulates annual abundance-at-age, total fishing mortality at
age, landings-at-age in numbers and weight, biomass, and recruitment. M is a
fixed input, not an estimated M-at-age output. The report uses annual time
steps; a fractional within-year timing for the abundance indices was not
verified.

Eligibility remains unresolved. The age-structured inputs and age-specific
outputs make this a strong candidate, but the full numerical age-composition
inputs have not been recovered. In addition, the 2025 update is being revised
and a new SEDAR 108 process is underway. The September 2026 proposed rule
describes the 2025 update as the latest completed assessment and says revised
recreational catch inputs and further review are pending. NOAA's species page
still displays the formal status determination based on the 2018 assessment;
that status label should not be mistaken for the latest assessment run.

Sources:

- [SEDAR 76 assessment page](https://sedarweb.org/assessments/sedar-76/) and [SEDAR 76 Update, March 2025](https://sedarweb.org/documents/sedar-76-bsb-update/), data through 2023.
- [NOAA proposed rule, September 2026](https://www.govinfo.gov/content/pkg/FR-2026-09-22/pdf/2026-19341.pdf), documents the pending revision and assessment-status context.
- [SEDAR 108 South Atlantic black sea bass](https://sedarweb.org/assessments/sedar-108-south-atlantic-black-sea-bass/), current follow-up assessment process.
- [NOAA Black Sea Bass resources](https://www.fisheries.noaa.gov/species/black-sea-bass/resources), current public stock-status page.

The SEDAR 76 Update is cached with size and SHA-256 in the ignored local
`source_cache/discovery_noaa_black_sea_bass_2025/sources.csv`.
