# DFO Pacific herring assessment regions: discovery screen

## Identity and current assessment

DFO lists five major Pacific herring assessment regions: Haida Gwaii (HG),
Prince Rupert District (PRD), Central Coast (CC), Strait of Georgia (SoG), and
West Coast of Vancouver Island (WCVI). The four inventory rows screened here
are distinct regional units. SoG already maps to the canonical dfo_herring_sog
record; no other canonical Clupea pallasii stock exists. The cross-inventory
register has no Pacific herring match outside DFO (its Atlantic herring records
are Clupea harengus). The four non-SoG identities are therefore provisionally
new and use DFO's regional codes, not invented stock identifiers.

The latest public assessment sources differ by region:

- HG, CC and WCVI use the 2025 statistical catch-age (SCA) assessment,
  reported in Science Response 2026/014. The status series runs through 2025;
  model structure is reported unchanged from the 2017 SCA update.
- PRD moved to SISCAH in 2025. Science Response 2026/006 reports the operating
  model through 2024 and management-strategy results for 2025-2027.
- Research Document 2024/066 describes the SISCAH framework, including
  density-dependent mortality, gear-specific catch timing, a blended spawn
  index and correlated age-composition errors. It is framework evidence, not a
  substitute for the latest stock-specific production outputs.

## Inputs and outputs found

The 2026 SCA report lists catch by gear, fishery/test-fishery number-at-age
compositions, weight-at-age, and spawning biomass index as assessment inputs.
The input series cover 1951-2025; roe gillnet and roe seine catches begin in
1972, while other-fishery catch begins in 1951. Biological reporting uses ages
2-10, with age 10 a plus group. Weights-at-age are reported in kg/fish.
Stock-assessment years run July 1 through June 30, so report year 2025 means
the 2024/2025 season.

DFO's public biological-sample dataset has separate regional files containing
individual age, weight, maturity, gear and sample-date fields. The roe-catch
dataset provides regional catch by gear and statistical area. The spawn-index
dataset provides the aggregate abundance series by region and year. Those
datasets make the underlying observations inspectable, but the production
model's exact sample filters, composition expansion, weight smoothing and
catch mapping still need to be reconciled before any numeric database import.
The current spawn-index dataset is updated through 2026; only values through
each assessment's terminal year belong to that assessment.

For HG, CC and WCVI, the latest SCA report provides posterior SSB, age-2
recruitment and annual natural-mortality summaries through 2025. The report
does not provide numerical fitted N-at-age or F-at-age arrays. For PRD, the
2026 report plots SSB, recruitment, mortality, harvest rate and catch through
2024; a machine-readable historical output series and age-specific fitted
N/F arrays were not recovered.

## Translation screen and source cache

All four assessments use an aggregate spawning-biomass index. The assessment
reports do not provide a survey age composition or an age-specific abundance
index. Fishery and test-fishery age compositions are not survey compositions,
so allocating the aggregate spawn index among ages would add an unsupported
selectivity assumption. These regions are therefore ineligible for the current
tinyAM age-indexed translation, even though their official assessment models
and biological inputs are age structured. Keep source curation separate from
that translation blocker; do not manufacture an age-indexed survey series.

Downloaded reference files and checksums are recorded in the gitignored
source_cache/discovery_dfo_pacific_herring_2026/sources.csv. The local cache
includes the prior 2024-status response, current official area datasets and
dictionaries, and DFO's assessment and management-plan pages. The latest
2026/014, 2026/006 and 2024/066 PDF links were reviewed, but the publication
server redirected direct shell downloads to its archive notice on 2026-10-29;
the source URLs and this limitation are recorded in
source_cache/discovery_dfo_pacific_herring_2026/not_cached_sources.csv.

No canonical input, assumption, assessment or output rows were added in this
discovery screen.
