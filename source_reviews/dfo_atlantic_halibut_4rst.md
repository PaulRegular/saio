# DFO Atlantic halibut, Gulf of St. Lawrence (4RST; 2024 assessment)

## Unit and assessment

DFO treats Atlantic halibut in NAFO divisions 4RST as a separate management
unit from the Scotian Shelf and southern Grand Banks unit 3NOPs4VWX5Zc. The
canonical database does not currently contain the 4RST unit, so this is a
provisional new unit. NOAA Stock SMART 10056 is not a one-to-one match for
either DFO unit.

The latest assessment advice located for 4RST is the assessment in 2024,
reviewed in February 2025 and published as Science Advisory Report 2025/013.
The report identifies the assessment type as full and says the assessment
approach was revised during the current assessment. It classifies the model as
a delay-difference population-dynamics model. The same report's “Most Recent
Assessment Date” field lists 2023 as the last full assessment, which conflicts
with the report title and its description of the current full assessment. The
2026 Gulf groundfish plan still describes the 2024 assessment as current. The
register uses 2024 for this advice record and preserves the report's
inconsistent assessment-date note here.

The 2025/028 research document is a data review for 2022. It says it does not
provide a definitive stock-status assessment. It is useful for understanding
biological samples and indicators but is not run-specific documentation for
the 2024 assessment. No detailed 2024 research document, downloadable fitted
object, or native model files were located in the official CSAS and Government
of Canada publication sources reviewed for this screen. The 2024 Science
Advisory Report itself says additional meeting products would be posted as
they became available.

## Inputs and assumptions relevant to an age-indexed model

- **Catch:** The 2024 report lists commercial landings through 2024 and
  sampling of commercial catches at sea and dockside for 1998–2024. It does not
  identify a catch-at-age series or age-composition likelihood. The 2022 data
  review discusses fishery sampling and biological measurements, but these
  should not be substituted for run-specific inputs to the 2024 assessment.
- **Abundance indices:** The 2024 report identifies estuary/northern Gulf
  trawl surveys (1984–2024), southern Gulf trawl surveys (1990–2024), a winter
  northern Gulf survey (1983–1994), and the DFO-industry longline survey
  (2017–2024). It reports aggregate biomass, pre-recruit, and fishery indices;
  an age-specific abundance index or age-composition likelihood was not
  identified. The 2022 data review reports 168 otolith pairs aged from 2021
  samples to estimate growth, not an age-indexed observation series.
- **Weights and maturity:** The 2022 data review estimates a length-weight
  relationship from 2,031 halibut sampled in trawl surveys during 2013–2022
  and describes growth from the 2021 otolith sample. These are useful
  biological sources but do not establish weight-at-age or maturity-at-age as
  inputs to the 2024 delay-difference assessment. An assessment-specific
  age-maturity vector was not verified.
- **Mortality:** The 2024 report identifies a delay-difference model and
  reports fishing mortality, but the summary does not describe an
  age-specific mortality process or provide an estimated natural-mortality
  series. No run-specific natural-mortality assumptions were verified.
- **Timing:** The 2022 data review describes summer trawl-survey sampling,
  mainly July–September. Exact fractional-year timing for the indices in the
  2024 assessment was not verified.

## Reported outputs

The 2024 report estimates exploitable biomass for fish at least 85 cm at
81,392 t in 2024 (95% CI: 67,935–97,516 t) and instantaneous fishing mortality
at 0.03 (95% CI: 0.025–0.035). It describes recruitment to the fishery as high
and stable since 2010 and provides aggregate trend figures and two-year
projection scenarios. Exploitable biomass is not SSB. No N-at-age or F-at-age
output series was located.

## Screening decision

This unit is **ineligible for the age-indexed candidate set**. The latest
assessment is classified as a delay-difference model, and the reviewed
run-specific source does not document age-indexed catch, survey observations,
or age-specific population outputs. The availability of otolith samples and
age data for growth does not establish those assessment inputs. No canonical numerical
records were imported during this inventory screen.

## Sources

- [2024 assessment, published as Science Advisory Report 2025/013](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290744.pdf)
- [2022 data review, published as Research Document 2025/028](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294300.pdf)
- [2022 assessment, Science Advisory Report 2023/036](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41206691.pdf)
- [2026 Gulf groundfish plan, Annex K](https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/groundfish-poisson-fond/2026/groundfish-poisson-fond-4rst-3pn-4vn-eng.html)
- [NOAA Atlantic halibut review](noaa_atlantic_halibut_2024.md)

The official PDFs and their retrieval dates and SHA-256 checksums are stored in
the ignored local cache `source_cache/discovery_dfo_atlantic_halibut_4rst_2024/`.
