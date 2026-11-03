# Cross-inventory keys for screened new units

The candidate register contained 62 screened rows classified as new, but with
no `candidate_unit_id`. This prevented the unit summary from counting them as
stock units. Each row has now been assigned a stable internal key derived from
its source identity: NOAA Stock SMART ID, ICES stock code, or the DFO 2024
Sustainability Survey region and stock label.

These keys identify the source-defined assessment unit; they are not canonical
stock IDs and do not assert a cross-agency equivalence. The source code, area,
assessment evidence, and any same-species boundary relationships remain in the
candidate register and linked source reviews. Rows that remain ambiguous or
identity-unreviewed are not assigned a key.

The 62 keyed units comprise 34 NOAA, 17 ICES, and 11 DFO entries: 22 eligible,
23 ineligible, and 17 eligibility-unresolved. No canonical stock or numerical
assessment data were added. The remaining unlinked rows are recorded as
identity-unreviewed or ambiguous, rather than counted as distinct units.
