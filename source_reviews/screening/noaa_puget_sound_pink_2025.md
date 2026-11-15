# NOAA Puget Sound pink salmon (2025 assessment)

## Assessment and sources

NOAA Stock SMART ID 10576 is the Puget Sound pink salmon unit. The latest
full-acceptance operational record in the cached Stock SMART inventory is
assessment 14157, finalized in 2025 with data through 2024. Stock SMART labels
the method “CSA (Collie Sissenwine)” and model category 3, which its data
dictionary defines as aggregate biomass dynamics. The same record lists
`composition_input_data = 3`; that is a discovery signal about composition-data
availability, not a recoverable age-specific observation series by itself.

The PFMC's 2025 Preseason Report I gives total Puget Sound pink salmon run-size
forecasts and actuals for odd-numbered years. It reports a 2025 forecast of
7.76 million fish and a 2023 actual run size of 7.22 million. The 2024 Salmon
SAFE and its Appendix B historical workbook give commercial net catch and
spawning escapement in numbers of fish, separated by odd year, subregion, and
hatchery/natural origin. Table B-43 does not report catch-at-age or age
composition. The reviewed current production sources do not provide an
age-specific abundance index, weights-at-age, maturity-at-age, or annual
age-specific mortality and population outputs.

There is a source-basis discrepancy that should be resolved before using the
Stock SMART summary value as an official output: its 2023 value of 7,222,610 is
labelled “Adult Spawners - Natural Escapement,” while PFMC reports the same
number as total run size. This value was not imported into the canonical
database.

The 2024 SAFE, 2025 Preseason Report I, and PFMC historical Appendix B workbook
are cached in `source_cache/noaa_puget_sound_pink_2025/`, with URLs, retrieval
date, file sizes, and SHA-256 checksums in its local `sources.csv`. The NOAA
Stock SMART snapshot and data dictionary are already cached with the discovery
sources.

## Screening decision

This is a distinct current Puget Sound pink salmon unit and is not matched to
the DFO Fraser or Skeena pink salmon records. It is screened **ineligible** for
the age-structured comparison set. The latest official production record is an
aggregate biomass-dynamics assessment and the available detailed sources expose
aggregate run-size, catch, and escapement quantities rather than the
age-disaggregated inputs and population outputs required for the comparison.
No canonical assessment, input, or output rows were added.

## Sources

- [PFMC Review of 2024 Ocean Salmon Fisheries](https://www.pcouncil.org/documents/2025/02/review-of-2024-ocean-salmon-fisheries.pdf/), especially Appendix B, Table B-43.
- [PFMC 2025 Preseason Report I](https://www.pcouncil.org/documents/2025/03/2025-preseason-report-i.pdf/), Appendix F, Table IV-1.
- [PFMC historical escapement and catch workbook, Appendix B](https://www.pcouncil.org/documents/escapements-to-inland-fisheries-and-spawning-areas-salmon-review-appendix-b-excel-file-format/), sheet B-43.
- [NOAA Stock SMART, ID 10576](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10576).
- [NOAA Stock SMART data dictionary](https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf).
