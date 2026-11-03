# NOAA Gulf of Mexico Spanish mackerel (Stock SMART 10173)

## Current unit and assessment

NOAA Stock SMART identifies ID 10173 as Gulf of Mexico Spanish mackerel (*Scomberomorus maculatus*). The Gulf management unit runs from the Texas–Mexico border east to the Dade–Monroe County line. The South Atlantic stock is a separate assessment unit and is not merged with this candidate.

The latest assessment used for Gulf catch-limit decisions is the SEDAR 81 operational assessment, completed in 2023 with data through 2021. The Gulf Scientific and Statistical Committee accepted its results as best available science in July 2023; NOAA's 2026 Framework Amendment 14 continues to set Gulf catch limits from SEDAR 81. The model is Stock Synthesis 3.30.21.00, one area, age 0 through 11+, and annual model years 1986–2021.

## Inputs and assumptions recovered

- **Catch:** The assessment reports commercial landings by gear in pounds whole weight for 1986–2021, recreational landings by mode in numbers of fish for the same years, and discard series. Commercial handline discards were incorporated into total catch after applying discard mortality. Commercial and recreational landings were modeled in different units, so these inputs must retain their native bases.
- **Age observations:** Commercial and recreational age samples were fitted as conditional age-at-length (CAAL), not as direct catch numbers-at-age. The assessment describes commercial age-composition coverage for gillnet/other in 1988–2015 and handline/other in 1988–2021; recreational headboat/charter in 1987–2021, private in 1990–2021, and shore in 2011–2021. The age range is 0–11. The supporting papers provide sample counts and figures, but the full run-matched year × length × age CAAL arrays and the corresponding numerical length-composition arrays were not found in the public files checked. Reconstructing catch numbers-at-age from figure traces would not reproduce the official model inputs and is not done here.
- **Abundance indices:** The assessment provides numerical annual aggregate indices and log-scale standard errors for the Florida commercial vertical-line CPUE (1986–2021) and two SEAMAP trawl series: early (1987–2008) and late (2009–2020; zero catch in 2021 was excluded). The SEAMAP paper reports that age samples were collected, but the assessment says fishery-independent age data were not included in Stock Synthesis. These indices are not age-specific.
- **Biology:** The report gives the fixed length–weight relationship `WW = 1.5e-05 * FL^2.8617` (fork length in cm, whole weight in kg), an age-specific Lorenzen M schedule for ages 0–11, and a fixed maturity-at-length logistic function (slope −0.44, L50 31.41 cm FL). Growth is estimated from age data, so age-specific weights and maturity are model-derived rather than supplied as complete fixed age surfaces.
- **Timing:** Settlement is set to May 1. Fishing is continuous and homogeneously distributed over the annual model year; the assessment does not use a seasonal population model or a survey timing fraction.

## Outputs and comparison limits

Table 15 reports annual total biomass, exploitable biomass, SSB, age-1+ abundance, age-0 recruitment, and SSB/SSB0 for 1986–2021. These are point estimates; the report also presents uncertainty and fitted population patterns in figures. Numerical annual N-at-age and F-at-age arrays were not found. The assessment defines its reported F metric as harvest rate (biomass killed divided by exploitable biomass), which is not the same quantity as instantaneous F-at-age. SSB, recruitment, and age-1+ abundance are usable aggregate comparison outputs if the year and units are aligned.

## Screening decision

Identity is **new** and source screening is **complete**. Eligibility for source curation remains **unresolved**: the assessment clearly uses age data, aggregate catch and survey series, and reports comparable population outputs, but its numerical CAAL and length-composition input arrays were not located. Survey age compositions are not part of the fitted model. The candidate remains separate from the South Atlantic Spanish mackerel stock. No canonical stock, assessment, input, or output rows were changed.

## Source cache

Files were retrieved on 2026-10-29 and are stored in the ignored local directory `source_cache/discovery_noaa_spanish_mackerel_sedar81/`.

| Cached source | Use | Source URL | SHA-256 |
|---|---|---|---|
| `SEDAR81_final_assessment.pdf` | Official assessment, input tables, assumptions, model methods and outputs | [SEDAR 81 assessment report](https://gulf-council-media.s3.amazonaws.com/uploads/2025/05/07d.-sedar-81-gulf-of-mexico-spanish-mackerel-final-stock-assessment.pdf) | `4C43D44F819407A391E14242B7754E54B057187741FABE770CED8DDAC042CC53` |
| `SEDAR81_executive_summary.pdf` | SSC-reviewed status summary and projections | [SEDAR 81 executive summary](https://sedarweb.org/documents/sedar-81-gulf-of-mexico-spanish-mackerel-executive-summary-report/) | `C88A3C3996C98BEACE14FEF7305BFCA7EA9C0ECE6465919B56381529C134CD93` |
| `SEDAR81_Gulf_SSC_review.pdf` | Management-use review of SEDAR 81 | [Gulf SSC review](https://sedarweb.org/documents/gulf-ssc-review-of-sedar-81-gulf-spanish-mackerel/) | `87122FB3B3C74D40D3A12E9766ACAE7B85E2D26BB2DD384BAF940F85F207C076` |
| `SEDAR81_WP03_age_data.pdf` | Age-data sources, sample coverage and age range | [SEDAR 81 WP-03](https://sedarweb.org/documents/sedar81-wp-03-a-review-of-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-age-data-1987-2021-from-various-age-data-sources/) | `3CB388F24F152C4ADBC503AFF5563835AD497F94280ABDD7B03270206D56B99C` |
| `SEDAR81_WP04_commercial_landings.pdf` | Commercial landings source and processing | [SEDAR 81 WP-04](https://sedarweb.org/documents/sedar81-wp-04-commercial-landings-of-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-1887-2021/) | `778DF7F7242DE874ACD28A6A68F8BD960EAE690CE34FE91888F563112D36CD2C` |
| `SEDAR81_WP06_recreational_length_age_compositions.pdf` | Recreational length and conditional age-at-length methods | [SEDAR 81 WP-06](https://sedarweb.org/documents/sedar-81-wp-06-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-recreational-landings-length-and-age-compositions/) | `67072697954C09B01B93F06CCD9514528754CF1BF39350D363EEE0D705A04F4B` |
| `SEDAR81_WP07_commercial_length_age_compositions.pdf` | Commercial length and conditional age-at-length methods | [SEDAR 81 WP-07](https://sedarweb.org/documents/sedar-81-wp-07-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-commercial-landings-length-and-age-compositions/) | `ED02D348340F452B6B2C02F6E02564907610BCC27962DE482874D535803DC4BF` |
| `SEDAR81_WP08_Florida_trip_ticket_index.pdf` | Commercial CPUE index methods and results | [SEDAR 81 WP-08](https://sedarweb.org/documents/sedar-81_wp_08-annual-indices-of-abundance-of-gulf-of-mexico-spanish-mackerel-from-florida-commercial-trip-tickets-1986-2021/) | `055A06D0626ACE4FF711BD5D7BA21FD4BA5401A5B8C952FD90B70EC60C3E4E0C` |
| `SEDAR81_WP09_SEAMAP_abundance_indices.pdf` | SEAMAP index methods and annual aggregate indices | [SEDAR 81 WP-09](https://sedarweb.org/documents/sedar-81-wp-09-spanish-mackerel-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/) | `22935F01DCCE8DC35A24E53F212D0AF80BB85B4295E5D1356226F0973F0009BD` |

The NOAA InPort SEDAR 81 project record and the SEDAR project page were also checked for run-specific native files; none were linked in the catalogue entries reviewed. This is a search result, not confirmation that internal files do not exist.