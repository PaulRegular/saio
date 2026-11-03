# ICES seal inventory screen

**Review date:** 2026-11-01
**Inventory source:** ICES Stock Information Database, 2026 snapshot retrieved 2026-10-28
**Scope:** Identity and initial marine-finfish scope screen; no canonical records added.

## Findings

The ICES 2026 stock list contains three distinct pinniped assessment units:

| ICES stock code | Stock and boundary | SID assessment information | Discovery decision |
|---|---|---|---|
| `seh.27.125a14` | Harp seal, Greenland Sea stock: subareas 1, 2, and 14 and Division 5.a | Last assessment 2019; the list identifies an analytical model type but does not describe its age inputs or outputs. | Excluded from the initial marine-finfish scope. No absence of age data is inferred. |
| `seh.27.1` | Harp seal, Barents and White Sea stock: Subarea 1 | Last assessment 2019; the SID describes an age-based SAM assessment considered indicative of trends only. The underlying age inputs and outputs were not reviewed. | Excluded from the initial marine-finfish scope. The status does not imply that its assessment lacks age-based information. |
| `sez.27.2514` | Hooded seal, Greenland Sea stock: subareas 2, 5, and 14 | Last assessment 2019; the list identifies an analytical model type but does not describe its age inputs or outputs. | Excluded from the initial marine-finfish scope. No absence of age data is inferred. |

These are separate ICES stock units, not aliases. The two harp seal stocks have
different assessment boundaries. Neither Greenland Sea unit is crosswalked to
the DFO Northwest Atlantic harp seal inventory entry: the shared species name
does not establish a shared stock boundary. The hooded seal is a different
species and stock.

The exclusion is based on the active first-wave scope (marine finfish, including
elasmobranchs), not on a finding that seal assessments or age data are
unavailable. The age-specific input and output search was therefore not
continued for these mammal units. No ICES seal stock is represented in the
canonical database; these source IDs are retained as distinct, ineligible
candidate units only.

## Source and provenance

The official [ICES SID 2026 stock list](https://sid.ices.dk/services/year/2026)
is cached at `source_cache/discovery_ices_sid/stock_list_2026.json`. Its local
manifest records retrieval date, URL, byte size and SHA-256. The reviewed
snapshot is 324,088 bytes with SHA-256
`913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42`.
The SID is an identity and assessment-metadata source; its stock-list entries
do not replace detailed run inputs or outputs.
