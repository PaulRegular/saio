# NOAA Gulf of Mexico cobia, 2020 assessment update

## Decision

**New unit; eligible for source curation, with an age-input reconstruction caveat.**
This screen verifies that the official model used age-at-length data and reports
population estimates. It does not add a canonical assessment or numerical values.

The Gulf unit is distinct from the Southern Atlantic cobia unit. SEDAR defines
the dividing boundary at the Florida–Georgia state line. The NOAA inventory row
is Stock SMART ID `10390`; no matching stock or assessment is present in the
canonical database.

## Assessment and sources

The latest detailed Gulf assessment located is the SEDAR 28 update, dated June
2020 and fitted through 2018. It uses Stock Synthesis 3, version 3.24, with a
single-area age-structured population model from 1927 through 2018. The assessment
assumes annual, continuous fishing and spawning with no seasonal structure. NOAA's
2024 management amendment still cites this update as its most recent stock
assessment. No later Gulf assessment or native SS3 input/output archive was found
in the SEDAR project documentation reviewed on 2026-10-31.

The official update and supporting files were cached locally under
`source_cache/discovery_noaa_gom_cobia_2020/`. The
ignored `sources.csv` manifest records each URL, retrieval date, byte count and
SHA-256 checksum.

| Source | Use |
|---|---|
| [SEDAR 28 Gulf Cobia Update report](https://sedarweb.org/documents/2019-update-sedar-28-gulf-of-mexico-cobia-final-report/) | Assessment inputs, assumptions, fit description and outputs |
| [2019-S28Update-WP-02](https://sedarweb.org/documents/2019-s28update-wp-02-recreational-survey-data-for-cobia-in-the-gulf-of-mexico/) | Recreational catch and survey data methods |
| [2019-S28Update-WP-04](https://sedarweb.org/documents/2019-s28update-wp-04-gulf-of-mexico-cobia-rachycentron-canadum-commercial-and-recreational-length-compositions/) | Commercial and recreational length-composition methods and coverage |
| [2019-S28Update-WP-05](https://sedarweb.org/documents/2019-s28update-wp-05-standardized-index-of-gulf-of-mexico-cobia-rachycentron-canadum-from-headboat-data/) | Headboat abundance-index methods |
| [2019-S28Update-WP-06](https://sedarweb.org/documents/2019-s28update-wp-06-cpue-expansion-estimation-for-total-commercial-discards-of-gulf-of-mexico-cobia-using-reef-fish-observer-data-and-adjustments-to-discard-logbook-estimates-for-florida-east-coast/) | Commercial discard estimates |
| [2019-S28Update-WP-07](https://sedarweb.org/documents/2019-s28update-wp-07-shrimp-fishery-bycatch-estimates-for-gulf-of-mexico-cobia-1972-2017/) | Shrimp bycatch inputs |
| [NOAA 2024 Amendment 32](https://www.noaa.gov/general-counsel/NEPA/final-amendment-32-to-fishery-management-plan-for-coastal-migratory-pelagic-resources-of-gulf-of) | Confirms continued management use of the 2020 assessment |

## Inputs and biological assumptions

- Commercial landings are reported in thousands of pounds and converted to
  metric tons for the model (1927–2018). Recreational landings are reported in
  numbers of fish and entered as thousands of fish (1950–2018).
- The model also uses commercial and recreational discards, shrimp bycatch, and
  annual length compositions. Recreational age information is entered as
  conditional age-at-length compositions for 3 cm length bins, ages 0–10, with
  age 10 as a plus group. The report records 1,266 age-length samples from
  1987–2002 and 2004–2018; there were no age samples in 2003.
- The age likelihood is not direct catch-at-age. A documented recreational
  catch-at-age reconstruction is possible in principle by combining annual
  recreational length composition, conditional age-at-length composition and
  recreational catch totals. The conditional age proportions are plotted rather
  than tabulated, and no native SS3 data files were found in the reviewed public
  project files. These values must be recovered or transparently digitized and
  validated before import.
- The MRIP index covers 1981–2018 and the SRHS headboat index covers 1986–2019.
  Both are fishery-dependent aggregate abundance indices. Their selectivity is
  assumed to match the aggregate recreational fleet. The assessment does not
  include an independent age-specific survey index. Any age-specific index
  derived from these observations and fishery age compositions would be an
  approximation, not a native assessment input.
- The model uses a fixed sex-combined length–weight relationship, sex-specific
  growth, fixed maturity (age 2: 50%; ages 3+: 100%), and a 60% female sex ratio.
  Age-specific weights can be derived from the reported growth and length–weight
  inputs.
- Natural mortality is a fixed age-specific Lorenzen vector, scaled to a fully
  selected-age M of 0.38 per year. M is not estimated.
- There is no within-year timing fraction because the model assumes continuous,
  homogeneous fishing and spawning throughout the year.

## Official outputs and cautions

Table 15 reports annual model biomass, spawning biomass, total abundance,
age-0 recruitment and depletion for 1927–2018. Recruitment uncertainty is also
shown in a figure. Numbers-at-age appear as a bubble plot; a numeric N-at-age
table was not located. Fleet fishing mortality and age selectivity are shown in
figures, but a numeric F-at-age table was not located. The report provides
aggregate official population outputs for comparison, while age-specific output
recovery would require further source work.

The assessment report notes that conditional age-composition fits were poor,
partly because of small sample sizes and fixed growth parameters. It also
discusses low confidence in the abundance indices and broader data limitations.
These are properties of the official assessment, not reasons to alter its
observations during any later translation.
