# NOAA, ICES, DFO, and NAFO inventory audit

The detailed three-organization tables below are a historical audit snapshot
from 2026-11-02. The screened NAFO inventory was added on 2026-11-04. Current row totals and the NAFO screening results are in
[inventory_progress.csv](inventory_progress.csv); the complete NAFO unit review is in
`source_reviews/nafo_inventory_2026.md`.

At the 2026-11-02 snapshot, the reviewed inventories contained 905 source-list
entries: 432 NOAA Stock SMART records, 274 ICES SID entries, and 199 DFO
entries (198 from the 2024 Sustainability Survey plus one supplementary
Pacific IFMP entry for coastwide yellowtail rockfish). Inventory source
revisions, retrieval dates, checksums and coverage limits are recorded below.

## Sources for the original inventory

The initial snapshot was retrieved on 2026-10-28 from:

| Source | Entries | Local cached source and provenance | Coverage limit |
|---|---:|---|---|
| NOAA Stock SMART via NOAA-EDAB | 432 stock IDs | `source_cache/shared/noaa_stocksmart/stock_assessment_summary.rda`, revision `664c4237e26520b260a090e1821a2cee5d1cdf07`, SHA-256 `AD47F9EEB240C2E77B2B952809A12C4FA739E3F0D39BEAB283B413FDBAEF76A8` | Latest metadata row per stock ID, not a verified official production run or proof of age observations. Regional official sources require separate review. |
| ICES SID | 274 published stock entries | `source_cache/shared/ices_sid/stock_list_2026.json`, SHA-256 `913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42` | Published 2026 stock list includes assessments and advice that may not use age observations. |
| DFO Sustainability Survey | 198 selected stocks, plus one supplementary Pacific IFMP entry for coastwide yellowtail rockfish | `source_cache/shared/dfo_sustainability/survey_2024.html`, SHA-256 `A10E65EEF028C2A524973FFCFA155915D673AE3AB9A9F1312581449E29644A28` | The 2024 survey covers only selected managed stocks, including non-finfish. Supplement with regional CSAS inventories. Official IDs and scientific names require review. |

Regional supplementation: the [2026 DFO Pacific groundfish plan](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html), retrieved 2026-10-28, led to a British Columbia yellowtail rockfish candidate absent from the initial survey list. The cached regional page SHA-256 is `2CB8792B9AEBE6FE5B27F3887BEFF57F02E2E7CE15D9344353AD705AED18475B`. This partial regional review is not an exhaustive CSAS inventory; further regional sources must still be audited.

The [Pacific Fishery Management Council groundfish assessment listing](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/) was retrieved 2026-10-28; cached HTML SHA-256 `77FEB82D8A674A018FD3FC7E02CE16579B36F3101B8603FF61286927B1D8B32D`. It provides reports and model files for recent West Coast assessments. The chilipepper identity has been reviewed, but the remainder of this regional listing still needs reconciliation and screening.

The [NOAA source manifest](../provenance/shared/noaa_stocksmart/sources.csv) and the
[ICES source manifest](../provenance/shared/ices_sid/sources.csv) record the
cached inventory files.

## Source-row screening

These are inventory-entry counts, not unique stock-unit counts. Every row has a
screening decision recorded; `eligible` means public evidence supports the
age-disaggregated source-curation scope, while `eligibility unresolved` means
important run-specific inputs or outputs remain unverified.

| Organization | Entries | Matched rows | New rows | Ambiguous rows | Identity unreviewed | Eligible rows | Ineligible rows | Eligibility unresolved | Eligible new rows | Eligible new-unit placements in source-region groups* |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DFO | 199 | 20 | 63 | 18 | 98 | 21 | 147 | 31 | 7 | 7 |
| ICES | 274 | 59 | 212 | 3 | 0 | 60 | 185 | 29 | 18 | 18 |
| NOAA | 432 | 28 | 388 | 14 | 2 | 89 | 252 | 91 | 75 | 67 |
| **Total** | **905** | **107** | **663** | **35** | **100** | **170** | **584** | **151** | **100** | **90 distinct** |

`eligible new rows` is not a stock count. Multiple source rows can represent one
candidate unit. The full row-level matrix for all 75 organization/region groups
is `inventory_progress.csv`: DFO regions, NOAA science centers, and the source
assessment-area labels supplied by ICES SID. It also reports distinct new
candidate units by evidence class for each source-region group. The region-group
placements in the final column sum to 92. One unit appears in both DFO and NOAA
groups, and one ICES unit spans two SID assessment-area labels; those repeated
placements deduplicate to 90 distinct eligible new units.

## Deduplicated unit counts

`inventory_units.csv` contains 736 linked unit keys covering 775 source rows:
100 matched canonical stock units and 636 candidate-unit keys. The candidate
keys comprise 632 new units, two units still classified as ambiguous and two
with mixed identity classifications. Of the 632 new units, 90 have eligible
input/output evidence, 421 are ineligible, 118 have unresolved eligibility,
and three have mixed eligibility evidence. Thus the screened inventory
supported 90 distinct, linked, eligible new stock units in that snapshot.

The 62 source-screened new rows that received stable internal candidate keys in
this audit were 34 NOAA, 17 ICES and 11 DFO entries. Their keys use the
source-defined NOAA Stock SMART ID, ICES stock code, or DFO region and stock
label. Keys are internal crosswalk identifiers, not canonical stock IDs and
not claims that different organizations assess the same unit. The 62 entries
include 22 eligible, 23 ineligible and 17 eligibility-unresolved rows. No
canonical stock, assessment, input or output values were added.

## Remaining unlinked identity rows by source region

The 130 rows without a unit crosswalk split into 30 documented ambiguous
identity/boundary cases and 100 entries that are explicitly outside the
marine-finfish scope. The latter comprise 95 DFO invertebrate or marine-mammal
entries, three Great Slave Lake freshwater entries and two NOAA squid
complexes. The ambiguous entries each have a review date, source URL, decision
reason and notes; they remain unlinked where the source label spans multiple
units, represents a historical boundary, or otherwise cannot be matched
one-to-one without inventing an equivalence.

| Organization | Source region | Unlinked rows | Ambiguous identity rows | Out-of-scope rows |
|---|---|---:|---:|---:|
| DFO | Arctic | 21 | 3 | 18 |
| DFO | Gulf | 5 | 1 | 4 |
| DFO | Maritimes | 25 | 2 | 23 |
| DFO | National Capital Region | 12 | 0 | 12 |
| DFO | Newfoundland and Labrador | 10 | 2 | 8 |
| DFO | Pacific | 21 | 8 | 13 |
| DFO | Quebec | 20 | 0 | 20 |
| ICES | Celtic Seas, Greater North Sea | 1 | 1 | 0 |
| ICES | Celtic Seas, Oceanic Northeast Atlantic | 1 | 1 | 0 |
| ICES | Greenland Sea, Oceanic Northeast Atlantic | 1 | 1 | 0 |
| NOAA | AFSC | 3 | 1 | 2 |
| NOAA | NEFSC | 1 | 1 | 0 |
| NOAA | NWFSC / SWFSC | 7 | 7 | 0 |
| NOAA | PIFSC | 1 | 1 | 0 |
| NOAA | SEFSC | 1 | 1 | 0 |
| **Total** |  | **130** | **30** | **100** |

Thirty-five inventory rows carry the `ambiguous` identity status; five of them
already have a documented candidate-unit key, while the 30 above remain
unlinked. This is distinct from eligibility: an identity can be understood
without the available assessment supporting age-disaggregated source curation,
and an eligible assessment cannot be counted as a new stock until its unit
identity is sufficiently clear.

## Status and next step

The inventory-level identity and source-evidence audit is recorded, including
the remaining source blockers. Several otherwise eligible source rows remain
unlinked because their labels cover multiple assessment units; they are not
included in the 90 eligible new units. Before selecting an import batch, use
the candidate register and its linked source reviews to resolve any additional
unit crosswalks supported by authoritative evidence. Do not turn these
documented ambiguities into extra candidate stocks or select the 20-stock
batch until the audit has been reviewed as complete.
