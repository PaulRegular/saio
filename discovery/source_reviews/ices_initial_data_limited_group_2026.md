# ICES data-limited and trend-based inventory screens

Review date: 2026-10-31

## Scope and identity

The six units below were reconciled by their current ICES stock codes and
assessment areas against `stocks.csv`. None has an exact stock-code record in
the canonical database. Their assessment areas distinguish them from other
units for the same species; they are recorded as separate new candidate units.
No numerical assessment data were added to the canonical database.

The review uses the 2026 ICES Stock Information Database snapshot and the
latest advice-linked assessment/source-data pair available for each unit. A
source-list row or the existence of biological age samples does not make an
assessment age structured. Eligibility here means that the current official
assessment provides the age-disaggregated inputs and population outputs needed
for the requested assessment comparison.

## Findings

| ICES stock | Latest advice assessment | Current method and published quantities | Decision |
|---|---|---|---|
| `rhg.27.nea` — roughhead grenadier, subareas 5–8, 10, 12, 14 | 2025, category 6.3 | SID says no assessment. Advice is for no directed fisheries. Standard Graphs provides total landings only (1990–2024); no age-based inputs or population estimates are published. | Ineligible |
| `aru.27.6b7-1012` — greater silver smelt, subareas 7–10, 12 and division 6.b | 2025, category 3.21 in the advice record; SID describes a survey-trends assessment | Standard Graphs identifies the stock-size measure as aggregate `B_index` (kg/haul) and fishing pressure as `Fproxy`; it reports aggregate catches, landings and discards. It does not report N-at-age, F-at-age or M-at-age. | Ineligible |
| `mur.27.67a-ce-k89a` — striped red mullet, subareas 6 and 8, divisions 7.a–c, 7.e–k and 9.a | 2026, category 5.2 | SID says no assessment and landings advice. Standard Graphs contains total landings (1975–2025), without age-structured inputs or population estimates. | Ineligible |
| `rji.27.67` — sandy ray, subareas 6–7 | 2024, category 5 | SID says no assessment and landings advice. Standard Graphs contains total landings (2009–2024), without age-structured inputs or population estimates. | Ineligible |
| `rju.27.7bj` — undulate ray, divisions 7.b and 7.j | 2024, category 6.3 | SID says no assessment. The advice is a precautionary zero-catch recommendation; current advice sources do not provide age-structured inputs or population estimates. | Ineligible |
| `rjm.27.67bj` — spotted ray, subarea 6 and divisions 7.b and 7.j | 2026, category 3 | SID describes trends from an aggregate biomass index and length-based indicators. Standard Graphs reports an aggregate `B_index`, total landings and `Lfm/Lmean`; it does not report N-at-age, F-at-age or M-at-age. | Ineligible |

These decisions exclude the units from the age-disaggregated comparison set; they
do not establish that age samples do not exist in survey or biological
monitoring programs. `aru.27.6b7-1012` has the strongest aggregate assessment
information in this group, but its advice method remains survey-trends-based and
its published outputs do not provide an age-structured population series.

## Sources and cached copies

For each stock, the matching ICES Advice and Scenarios Database record and
Standard Graphs source-data page are cached locally in the gitignored
`source_cache/discovery_ices_screen_first_six_2026/`. The adjacent `sources.csv`
records direct URLs, retrieval date, byte count and SHA-256 checksum. The 2026
SID inventory snapshot is cached under `source_cache/discovery_ices_sid/`.

| Stock | ICES advice | Standard Graphs source data |
|---|---|---|
| `rhg.27.nea` | [2025 advice record 3961](https://asd.ices.dk/viewAdvice/3961) | [2025 source data, key 20946](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=20946) |
| `aru.27.6b7-1012` | [2025 advice record 3954](https://asd.ices.dk/viewAdvice/3954) | [2025 source data, key 20919](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=20919) |
| `mur.27.67a-ce-k89a` | [2026 advice record 7229](https://asd.ices.dk/viewAdvice/7229) | [2026 source data, key 25910](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25910) |
| `rji.27.67` | [2024 advice record 3780](https://asd.ices.dk/viewAdvice/3780) | [2024 source data, key 19099](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19099) |
| `rju.27.7bj` | [2024 advice record 3781](https://asd.ices.dk/viewAdvice/3781) | [2024 source data, key 19179](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19179) |
| `rjm.27.67bj` | [2026 advice record 7166](https://asd.ices.dk/viewAdvice/7166) | [2026 source data, key 25849](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25849) |

The entries in the candidate register retain the individual evidence and link
to this review. No native age-structured assessment files or age-indexed outputs
were found for these six latest advice runs in the reviewed sources.
