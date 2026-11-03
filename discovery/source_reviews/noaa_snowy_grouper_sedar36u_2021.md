# NOAA South Atlantic Snowy Grouper — SEDAR 36 Update (2021)

## Stock and assessment

NOAA Stock SMART 10339 identifies the South Atlantic Snowy Grouper unit,
currently listed under the scientific name *Epinephelus niveatus*. The SEDAR
report also uses the synonym *Hyporthodus niveatus*. Neither name is present in
the canonical stock table, and this unit is distinct from other snowy grouper
records.

The latest completed assessment located is the SEDAR 36 Update, published in
November 2020 and revised in January 2021. It is a Beaufort Assessment Model
(BAM) statistical catch-age assessment with data through 2018. The draft SAFMC
2027 statement of work still lists this update and terminal year 2018 as the
prior assessment. No later completed assessment was located in the sources
reviewed.

The earlier SEDAR 36 WP15 lists ADMB code and input data for the 2013 benchmark,
not the 2020 update. It is not used as a substitute for update-specific inputs.
The 2020 update document list contains two working papers, but no run-matched
model input or fitted-object file was identified in those materials.

## Inputs and outputs located

The assessment period is 1974–2018 and uses three modeled removal fleets:
commercial handline, commercial longline, and combined recreational. Annual
removals include landings and dead discards. Commercial input removals are in
whole weight; recreational removals are in numbers. Commercial discards were
converted from numbers to weight using mean weight at age 2.5 and assumed to
have 100% mortality. Headboat and general recreational removals were combined
because the composition sample was not sufficient to estimate separate
selectivities.

The report provides annual fleet removals, aggregate headboat and fishery
independent abundance indices, annual composition sample sizes, and observed
and fitted age-composition figures. The chevron-trap and vertical-longline
indices cover 1996–2018; the headboat index begins in 1978. Age compositions
are used for commercial handline, commercial longline, recreational, chevron
trap, and vertical longline. Age compositions use age 14 as the plus group; selectivity is held equal across ages 15–25+. The report
does not provide the age-composition input matrices as numerical tables, so
reconstructing catch-at-age requires digitizing the observed compositions and
combining them with the report's removal totals. This is source-based but
approximate.

The report gives age-specific whole weight, female maturity and proportion
female for ages 1–25+, with age 25+ as the plus group. Female maturity is zero at
ages 1–2 and logistic thereafter, with 50% maturity at 5.6 years. All males are
treated as mature; proportion male increases from age 5 onward. Spawning
biomass is mature biomass at mid-year peak spawning. Base-run natural mortality
is fixed and age-dependent, using a Charnov curve scaled to M = 0.08 at maximum
age 56. The report also describes MCB uncertainty trials that draw the scalar
M from 0.05–0.12.

Numeric fitted outputs include abundance-at-age (Table 6), biomass-at-age
(Table 7), annual stock status and SSB (Table 8), total F-at-age (Table 11),
and estimated removals-at-age (Tables 12–15). Recruitment is the age-1
abundance series in Table 6. The tables provide base-run point estimates;
age-specific confidence intervals were not located. Aggregate uncertainty is
summarized through the MCB ensemble.

The unit is eligible for source curation because the report supports
reconstruction of age-disaggregated removals and provides age-specific biology
and fitted population/mortality outputs. A later import should preserve the
reported inputs and clearly identify figure-digitized compositions as
reconstructed values.

## Source files and provenance

The revised assessment report and two update working papers are cached in the
ignored local directory
source_cache/noaa_snowy_grouper_sedar36u_2021/.
Their URLs, cited revisions, retrieval time, byte sizes and SHA-256 checksums
are recorded in manifest.csv.

- [SEDAR 36 Update assessment page](https://sedarweb.org/assessments/sedar-36-update-south-atlantic-snowy-grouper/)
- [Revised SEDAR 36 Update assessment report (January 2021)](https://sedarweb.org/documents/2020-update-sedar-36-update-assessment-report-south-atlantic-snowy-grouper-revised-january-2021-2/)
- [SEDAR 36 Update WP01: recreational survey data](https://sedarweb.org/documents/2020-sedar36u-wp01-general-recreational-data_satl_snowy_grouper_22apr20/)
- [SEDAR 36 Update WP02: management history](https://sedarweb.org/documents/2020-sedar-36u-wp02-snowy-grouper-management-history-2-18-2020/)
- [Original SEDAR 36 assessment page, including superseded 2013 WP15](https://sedarweb.org/assessments/sedar-36/)
- [Draft SAFMC 2027 statement of work](https://safmc.net/documents/sedar_a2_draft_sow-for-2027-pdf/)

This review changes discovery metadata only. It does not create a canonical
stock, assessment, input, or output record.
