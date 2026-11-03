# ICES ray and dogfish method screen

**Review date:** 2026-11-01
**Inventory source:** ICES Stock Information Database (SID), 2026 snapshot retrieved 2026-10-28
**Scope:** Current assessment method, age-disaggregated input/output screen, and stock-code identity check. No canonical data were imported.

## Findings

The eight ICES codes below are separate assessment units. The codes identify
different species and/or ICES areas; same-species units remain separate. None
matches an exact ICES stock code in the canonical stock table. The current SID
describes these methods as survey-trend/length-indicator assessments or SPiCT,
not age-structured population assessments.

| ICES code | Species and assessment area | Latest SID assessment | Current method | Linked Standard Graphs reporting |
|---|---|---:|---|---|
| sho.27.89a | Black-mouth dogfish, Subarea 8 and Division 9.a | 2025 | Survey trends-based assessment | Aggregate biomass index in kg/h, landings, catches, and discards |
| rjc.27.3a47d | Thornback ray, Subarea 4 and divisions 3.a and 7.d | 2025 | SPiCT | Relative biomass and fishing pressure; aggregate landings, catches, and discards |
| rjh.27.4bc7d | Blonde ray, divisions 4.b, 4.c, and 7.d | 2025 | SPiCT | Relative biomass and fishing pressure; aggregate landings, catches, and discards |
| rjn.27.3a4 | Cuckoo ray, Subarea 4 and Division 3.a | 2025 | Biomass-index trends and length-based indicator | Aggregate biomass index in kg/h, landings, and F |
| rjn.27.678abd | Cuckoo ray, subareas 6 and 7 and divisions 8.a, 8.b, and 8.d | 2026 | SPiCT | Relative biomass and fishing pressure; aggregate landings |
| rjm.27.7ae-h | Spotted ray, divisions 7.a and 7.e-h | 2026 | Biomass-index trends and length-based indicators | Aggregate biomass index in kg/h, landings, and a length-based F proxy |
| rjc.27.7afg | Thornback ray, divisions 7.a, 7.f, and 7.g | 2026 | Biomass-index trends and length-based indicators | Aggregate biomass index in kg/h, landings, and a length-based F proxy |
| syt.27.67 | Greater-spotted dogfish, subareas 6 and 7 | 2025 | Biomass-index trends and length-based indicator | Aggregate biomass index, landings, and F proxy |

The linked Standard Graphs pages identify the stock code, assessment year, and
assessment key from SID. Their age/length fields do not report F by age or
length, and their fish tables contain only aggregate indicators, catches,
landings, discards, and/or fishing-pressure summaries. No N-at-age, F-at-age,
or M-at-age assessment outputs are published for these runs. The current method
and available assessment tables therefore do not support the age-disaggregated
input/output screen used for this database.

These decisions concern the inputs and outputs exposed by the current
assessment. They do **not** establish that age samples are unavailable for
other research or monitoring purposes. No catch-at-age, survey age composition,
weight-at-age, maturity-at-age, age-specific M, or age-specific survey timing
was identified in the reviewed current assessment sources.

No stock, assessment, input, or output rows were added to the canonical
database. Candidate rows remain import_status = not_started.

## Sources and provenance

- [ICES SID 2026](https://sid.ices.dk/services/year/2026), cached as
  source_cache/discovery_ices_sid/stock_list_2026.json. The snapshot manifest
  records retrieval date, URL, byte size, and checksum.
- Official ICES Standard Graphs source pages, cached individually with URLs,
  retrieval date, byte size, and SHA-256 in
  source_cache/discovery_ices_ray_method_group_2026/sources.csv:
  - [Black-mouth dogfish, key 21013](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21013)
  - [Thornback ray, key 21096](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21096)
  - [Blonde ray, key 21097](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21097)
  - [Cuckoo ray, key 21067](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21067)
  - [Cuckoo ray, key 25826](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25826)
  - [Spotted ray, key 25810](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25810)
  - [Thornback ray, key 25860](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25860)
  - [Greater-spotted dogfish, key 21014](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21014)

The 2026 SID is an inventory and current-method source; Standard Graphs is the
source for the linked assessment's published time-series and reporting fields.
Neither source is treated as evidence that age samples do not exist outside
these assessment runs.
