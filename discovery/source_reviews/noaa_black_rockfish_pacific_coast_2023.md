# Pacific Coast black rockfish: 2023 assessment screen

## Current assessment and stock identity

NOAA's 2023 Pacific Coast benchmark work covers three state-level assessment
units: Washington, Oregon, and California. The Washington and Oregon reports
each describe a separate Stock Synthesis assessment. The California report
describes one California stock assessment represented by northern and central
sub-area models. Those sub-area models are components of the California
assessment, not additional stock cases.

The pinned NOAA Stock SMART summary identifies four 2023 records: stock IDs
14409 (Washington; assessment 12965), 14407 (Oregon; assessment 12964), 17194
(South of Point Conception; assessment 12963), and 17195 (Point Conception /
Oregon Border; assessment 12962). The Stock SMART metadata field `itis` is
166727 for all four; the number in parentheses in the NOAA-EDAB changelog is
the species taxonomic identifier, not a unique Stock SMART stock ID. The
California Stock SMART area labels do not map one-to-one to the assessment's
Point Arena sub-area split. They are therefore grouped under the single
California assessment-unit key for inventory counts, with the precise
crosswalk retained as unresolved; the source models remain separate.

Older Stock SMART rows 10402 and 11302 are broad northern and southern Pacific
Coast units from 2007. Row 14408 is a California record from 2019. The available
sources do not establish a one-to-one mapping from these older boundaries to
the current state-specific stock definitions. They remain ambiguous historical
rows and are not counted as current assessment cases.

## Source evidence

The 2023 California report describes the California stock as two sub-area
models, northern and central, divided at Point Arena to represent differing
exploitation histories, compositions, and abundance trends. The central model
extends to the U.S.-Mexico border, although black rockfish are rare south of
Point Conception and the data informing that model are concentrated farther
north. Washington, Oregon, and California each have their own source model
files; retain the state and sub-area distinctions in any later extraction.

The four regional model components use Stock Synthesis 3. Their reports and
archives provide fleet catches, fishery and survey age/length compositions,
abundance indices, sex-specific biological settings, and numeric age-specific
population output. The available age grids are ages 0-40 for Washington and
Oregon and ages 0-50 for both California sub-area models. Reported population
histories begin in 1940 for Washington, 1892 for Oregon, and 1875 for both
California components.

Catch-at-age and age-specific survey indices are not all provided as direct
observation matrices. Preserve the original likelihood inputs
and regional settings. Natural mortality and other assumptions differ among
the regional models and sexes.

The official archives provide sex-specific abundance-at-age and
biomass-at-age. California spawning output is reported in billions of eggs,
not spawning biomass in tonnes. The case is eligible for source curation
because its native archive contains age-composition inputs and numeric
age-specific outputs; those compositions are not themselves catch-at-age or
age-specific abundance indices.

## Screening decision

Screen three current assessment units as eligible for source curation:
Washington (NOAA:14409), Oregon (NOAA:14407), and California (NOAA:17194 and
NOAA:17195, grouped as the single California assessment). Oregon and Washington
now have partial canonical 2023 source records; see
`noaa_black_rockfish_oregon_2023.md` and
`noaa_black_rockfish_washington_2023.md`. California now also has a partial source record.
The California import preserves its North and Central model components
separately and records the unresolved crosswalk between Stock SMART labels and
the Point Arena model boundary. Keep NOAA:10402, NOAA:11302, and NOAA:14408 as
ambiguous, ineligible historical rows. The prior register entry NOAA:166727 was
invalid as a stock key and has been removed; it was a taxonomic identifier, not
a Stock SMART stock row.

## Sources

- [NOAA Stock SMART changelog](https://noaa-edab.github.io/stocksmart/news/index.html)
- [PFMC groundfish assessment documents and model files](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [2023 Black Rockfish STAR panel report](https://www.pcouncil.org/documents/2023/11/stock-assessment-review-star-panel-report-for-black-rockfish.pdf/)
- [NOAA peer-review record for the 2023 assessments](https://www.noaa.gov/information-technology/stock-assessment-review-panel-review-of-2023-stock-assessments-for-black-rockfish-off-washington)
- Oregon and California reports and model-file archives are cached locally. Their URLs, revisions, retrieval dates, byte sizes, and SHA-256 checksums are listed in `source_cache/discovery_noaa_black_rockfish_2023/sources.csv`. Washington sources are separately cached and recorded in `provenance/noaa_black_rockfish_washington_2023_sources.csv`.
