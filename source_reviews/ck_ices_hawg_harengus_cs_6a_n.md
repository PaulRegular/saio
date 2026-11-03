# North of 56°N herring (6.a.N): source review

## Stock and assessment history

The Charbonneau–Keith entry `ICES-HAWG_harengus_CS 6a (N)` corresponds to
North Sea autumn-spawning herring in ICES Division 6.a North, stock code
`her.27.6aN`. The stock was assessed separately through 2014, jointly with
6.a South and 7.b–c from 2015 to 2021, and separately again from 2022 using
a genetically split acoustic survey. The combined historical assessment and
the two current units must not be treated as the same stock or merged.

HAWG 2026 presents a final 6.aN survey-index assessment based on data through
2025. The published 2026 advice record 4063, assessment key 21308, is marked
**Invalid** in the ICES Advice and Scenarios Database. The published 2026
ACOM advice identifies this assessment as its basis; its current validity and
any management application should not be inferred from publication. The
reason for the invalid status is unknown. The 2025 ICES ACOM
advice for this stock uses assessment key **19370** and DOI
`10.17895/ices.advice.27202632`; an earlier version of this review incorrectly
identified key 19342 and advice 3843, which refer to the distinct **southern**
stock. The 2025 advice recommends catches of 1,501 tonnes in 2026.

## Assessment method and recovered sources

The 2025 advice describes a survey-biomass trend assessment using a constant
harvest-rate rule. It combines commercial catches, catch-length frequencies,
and the genetically split Malin Shelf Herring Acoustic Survey (MSHAS). Its
2024 input index is 12,557 tonnes; the reported target harvest rate is 0.28,
Itrigger 14,711 tonnes, biomass safeguard 0.854, and precautionary multiplier
0.5. The advice rounds displayed values and calculates with unrounded inputs.
This is not an age-structured population assessment and its index is not an
independently estimated absolute SSB surface. Relative catch/index is a
harvest-rate indicator, not instantaneous fishing mortality.

The detailed 2025 and 2026 HAWG reports provide historical catch numbers and
catch weights by age, along with MSHAS numbers-at-age and biological summaries.
These age tables provide source information, but the adopted harvest-rate rule
is based on aggregate survey biomass and is not an age-specific likelihood.
Commercial catch is apportioned geographically and includes an unquantified
proportion of other herring populations; the survey is genetically split.

Source interpretation requires care:

- HAWG 2026 Table 4.2.2 prints zero catch numbers at each age in 2022, although
  the aggregate series reports 51 tonnes; its Table 4.2.3 calls the 2024
  zero-weight row “no catches” despite 2,157 tonnes of aggregate catch. HAWG
  2025 instead marks the corresponding age data unavailable. Preserve source
  values and flag these contradictions; do not assert that they establish zero
  removals or manufacture an age allocation.
- HAWG 2026 Table 4.2.1 lists no commercial samples for 2025, whereas
  Table 4.2.2 reports 2025 catch-at-age and the 2026 advice says fishery
  samples were available. The source of the age allocations is unresolved;
  retain the reported table without claiming the sampling discrepancy is solved.
- HAWG 2026 Table 4.4.1.1 labels weight in kilograms, but its 2025 row matches
  grams in Table 4.3.1. Do not silently apply the kilogram label to that row.
- For 2023, HAWG 2025 and 2026 Table 4.3.2 show an index of 22.463 thousand
  tonnes, whereas the ICES SAG export for both assessment keys gives 23,117
  tonnes, as do the 2025 and 2026 advice tables. These are not rounding
  differences. The published advice is the source for its respective index;
  the conflicting working-group age table is not silently treated as the
  decomposition of that value. The cause of the discrepancy is unresolved.

## Canonical records

The source importer `scripts/database/161_import_ices_herring_6a_n.R` records
the 2025 adopted advice and the 2026 HAWG assessment separately. The latter is
the selected detailed record, and `is_applied` records its use as the basis of
published ACOM advice; the ASD advice record is currently Invalid. That flag
does not assert that the advice is currently valid or was applied in management.
The 2025 and 2026 input records contain 1,566 and 1,629 rows respectively,
including reported catch numbers and weights by age 1–9+, survey numbers by
age, survey weight and maturity, the SMS-derived M vector, survey biomass
indicator and geographical catch history. Outputs contain the reported survey
indicator, a separately labelled working-group indicator, and relative
harvest-rate series, not fitted population states. The two indicators are
alternative representations of the same survey, not independent observations.
Missing biology cells are absent, not filled; missing catch numbers remain NA.
The survey is in June–July, but no exact within-year time is assigned.

The report tables, published advice and SAG export differ in places. The 2025
and 2026 advice and SAG publish 23,117 t for 2023, whereas both HAWG tables
print 22,463 t. Their 2023 reported relative harvest rate is consistent with
the 22,463 t denominator, so the source series itself is not arithmetically
self-consistent if the published 23,117 t biomass is substituted. The imported
input indicator uses the published advice/SAG series; outputs also retain the
working-group series in its original thousand-tonne units. Age data retain
their working-group table provenance. No adjustment is made. The 2026
report's zero catch and catch-weight exceptions are preserved and flagged, not
interpreted as proof of zero removals. The 2026 survey-weight table's 2025 row
is stored in grams, as independently labelled in Table 4.3.1, and not silently
interpreted as kilograms.

All completeness statuses remain partial: native rule inputs and calculations,
including complete catch length-frequency data and their underlying survey
processing, have not been recovered. The 2025 and 2026 HAWG PDFs, advice PDFs,
SAG XML and associated pages are cached locally with file hashes and URLs.

## Translation status

The survey-index rule does not estimate population N/F/M-at-age, recruitment,
or an age-structured population model. A comparison that presents those
quantities as official estimates would be misleading. A tinyAM translation
and comparison dashboard are not supported by this assessment alone.

## Sources

- [HAWG 2026 report](https://doi.org/10.17895/ices.pub.31424315), section 4
  and Tables 4.2.2–4.4.3.1 and 4.6.1.
- [HAWG 2025 report, version 5](https://ices-library.figshare.com/articles/report/Herring_Assessment_Working_Group_for_the_Area_South_of_62_N_HAWG_/28389008), section 4 and associated tables.
- [ICES 2025 6.aN advice](https://doi.org/10.17895/ices.advice.27202632).
- [ICES 2025 6.aN SAG source data, key 19370](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19370).
- [ICES 2026 6.aN SAG source data, key 21308](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21308).
- [ICES 2026 published 6.aN advice](https://doi.org/10.17895/ices.advice.32133586); [ASD record 4063](https://asd.ices.dk/viewAdvice/4063), marked Invalid.
