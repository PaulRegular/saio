# ICES elasmobranch inventory screen

Review date: 2026-10-31

## Scope and identity

The six units below were checked against the 2026 ICES Stock Information
Database (SID) snapshot and the official Standard Graphs source linked by each
SID assessment key. None has an exact stock-code record in the canonical
database. Each has a distinct stock code and area, so each is retained as its
own discovery candidate. No numerical assessment data were added to the
canonical database.

The SID's current assessment type and the published source data were used to
screen for age-disaggregated assessment inputs and outputs. A generic graph
field labelled SSB or F is not treated as an age-structured output when the
source table contains only aggregate index or landings values.

## Findings

| ICES unit | Latest SID assessment | Current method and source data | Decision |
|---|---|---|---|
| `sho.27.67` — black-mouth dogfish, subareas 6–7 | 2023, category 3.9 | Survey-trends method; Standard Graphs key 18348 (2023) reports an aggregate B_Index in kilograms and landings. No age-indexed N, F, M or survey series is published. | Ineligible |
| `gfb.27.nea` — greater forkbeard, subareas 1–10, 12, 14 | 2026, category 3.2 | Survey-trends method; key 23774 (2026) reports aggregate B_index, catches, landings and discards. No age-indexed population outputs or age-specific survey index is published. | Ineligible |
| `raj.27.89a` — other rays and skates, subarea 8 and division 9.a | 2024, category 5.9 | SID says no assessment. Key 19096 (2024) has landings rows only; its generic SSB/F fields do not contain age-indexed population estimates. | Ineligible |
| `rjb.27.89a` — common skate complex, subarea 8 and division 9.a | 2024, category 6.3 | SID says no assessment. Its retained key 13860 points to a 2020 Standard Graphs record with landings only, not current assessment outputs. | Ineligible |
| `rjn.27.8c` — cuckoo ray, division 8.c | 2026, category 3 | SID describes biomass-index trends and length-based indicators. Its retained key 19116 points to a 2024 graph with aggregate B_index, catches, discards and landings; no age-indexed series is exposed for the 2026 run. | Ineligible |
| `syc.27.8abd` — lesser-spotted dogfish, divisions 8.a, 8.b and 8.d | 2025, category 3.9 | SID describes biomass-index trends and length-based indicators. Key 21069 (2025) reports aggregate B_index, Fproxy, catches, landings and discards; no age-indexed population outputs are published. | Ineligible |

These decisions concern the current official assessment methods and the
published sources reviewed. They do not imply that age samples are unavailable
for other biological or monitoring purposes. The retained keys for `rjb.27.89a`
and `rjn.27.8c` do not point to a graph from the SID's latest assessment year;
that mismatch is recorded rather than presenting the older graph as current
output.

## Sources and cached copies

The 2026 SID list snapshot is cached under the gitignored `source_cache/` tree.
The six linked Standard Graphs source-data pages are cached in
`source_cache/discovery_ices_elasmobranch_group_2026/`; `sources.csv` records
the URLs, retrieval date, displayed assessment year, byte counts and SHA-256
checksums.

| Stock | SID assessment key | Standard Graphs source |
|---|---:|---|
| `sho.27.67` | 18348 | [2023 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=18348) |
| `gfb.27.nea` | 23774 | [2026 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23774) |
| `raj.27.89a` | 19096 | [2024 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19096) |
| `rjb.27.89a` | 13860 | [retained 2020 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=13860) |
| `rjn.27.8c` | 19116 | [retained 2024 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19116) |
| `syc.27.8abd` | 21069 | [2025 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21069) |

The candidate register retains unit-level evidence and links to these sources.
