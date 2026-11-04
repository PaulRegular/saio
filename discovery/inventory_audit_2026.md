# NOAA, ICES, DFO, and NAFO inventory audit

The detailed three-organization tables below are a historical audit snapshot
from 2026-11-02. The screened NAFO inventory was added on 2026-11-04. The
current four-organization row totals and NAFO screening results are summarized
in `README.md`; the complete NAFO unit review is in
`source_reviews/nafo_inventory_2026.md`.

At the 2026-11-02 snapshot, the reviewed inventories contained 905 source-list
entries: 432 NOAA Stock SMART records, 274 ICES SID entries, and 199 DFO
entries (198 from the 2024 Sustainability Survey plus one supplementary
Pacific IFMP entry for coastwide yellowtail rockfish). Inventory source
revisions, retrieval dates, hashes and coverage limits are recorded in
`README.md`; source files are retained under the ignored `source_cache/`
directory.

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
currently supports 90 distinct, linked, eligible new stock units.

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
