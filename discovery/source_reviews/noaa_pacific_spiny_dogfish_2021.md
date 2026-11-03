# NOAA Pacific Coast spiny dogfish, 2021

## Unit and assessment

Stock SMART ID 10702 is the U.S. Pacific Coast unit of Pacific spiny dogfish,
from the U.S.-Canada border to the U.S.-Mexico border. It is separate from the
Alaska shark-complex entries and from DFO's inside and outside British Columbia
units. Stock SMART uses the older scientific name *Squalus acanthias*; current
NOAA materials use *Squalus suckleyi* for the Pacific species. Preserve both
names with their source context.

The latest full production assessment identified is the 2021 PFMC assessment,
with data through 2020. NOAA's later catch-based status updates do not replace
that assessment. The assessment report, accepted model archive, supplementary
tables, STAR panel report and NOAA status page are cached locally under
`source_cache/discovery_noaa_spiny_dogfish_2021/`; `sources.csv` records their
URLs, retrieval date, revisions, sizes and checksums.

## Inputs and outputs

The accepted Stock Synthesis model uses eight fishery catch series and annual
length compositions, plus five aggregate survey abundance indices and survey
length compositions. It does not use observed fishery catch-at-age or a
year-specific age-at-age survey index. Fishery age samples were considered but
were excluded from the accepted likelihood because they were noisy and did not
include the smaller fish needed for growth estimation.

The archive contains one fitted conditional age-at-length sample: 2010
WCGBTS, 33 sex-by-length cells, 515 fish, and ages 0-71. This sample can inform
an age-length key, but transferring it across years and fleets is an assumption.
Combined with annual fleet length compositions and catches or aggregate survey
indices, it can support explicitly labelled approximate age-specific inputs.
Those reconstructed series must never be described as observed catch-at-age or
age-specific survey observations. This candidate is eligible for source
curation only with that reconstruction caveat, and should rank below units with
direct age-composition inputs.

The model archive supplies sex-specific model-derived weights-at-age,
length-based maturity biology, and annual age-specific catch, N and F surfaces.
Natural mortality is fixed at 0.065 per year for both sexes; it is not an
estimated M surface. The assessment has one 12-month season and a January
spawning month. Fishery catches are seasonal; survey timing is encoded in the
native fleet table and must be interpreted before assigning a fractional year.

## Decision and limitations

Screen as a new, eligible source-curation candidate (`noaa_spiny_dogfish_pacific_coast_2021`), not as an already imported assessment. Eligibility relies on a
documented, approximate age-length-key reconstruction. The available single
survey-year age sample, fleet differences, sparse age coverage and absence of
direct annual age indices are material limitations. No canonical stock,
assessment, input or output rows were added during this screening.

The source checks in
`scripts/database/475_screen_noaa_spiny_dogfish_2021.R` verify the assessment
years, fleet structure, age bins, 2010 age sample, fixed M and reported age
surfaces against the cached files.

## Sources

- [2021 PFMC assessment](https://www.pcouncil.org/documents/2022/01/status-of-the-pacific-spiny-dogfish-shark-resource-off-the-continental-u-s-pacific-coast-in-2021-october-19-2021.pdf/)
- [2021 Stock Synthesis model archive](https://www.pcouncil.org/documents/spiny-dogfish-2021-model-files-zip-file/)
- [2021 supplementary tables](https://www.pcouncil.org/documents/spiny-dogfish-assessment-supplementary-table-excel/)
- [2021 STAR panel report](https://www.pcouncil.org/documents/spiny-dogfish-stock-assessment-review-star-panel-report/)
- [NOAA Pacific spiny dogfish status page](https://www.fisheries.noaa.gov/species/pacific-spiny-dogfish)
