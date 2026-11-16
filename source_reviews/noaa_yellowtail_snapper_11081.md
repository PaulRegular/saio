# NOAA Southeastern U.S. yellowtail snapper, SEDAR 96 (2025)

## Stock and assessment

NOAA Stock SMART ID `11081` identifies the Southeastern U.S. yellowtail snapper management stock shared by the South Atlantic and Gulf councils. The latest fully accepted operational assessment found is SEDAR 96 (2025), with data through 2023. It is a Stock Synthesis 3.30.15 model for one Florida population area, with ages 0–20. This is a partial source import, not a complete reconstruction of the fitted assessment.

The partial canonical record contains 251 input rows, 256 output rows and 18 assumptions.

## Imported information

- **Biology and mortality:** Table 7 supplies predicted fork length, fixed age-specific M (`Mat-age`) and fixed female maturity for ages 0–20. The M schedule is derived using an external growth model; the report's fixed length-weight relationship is also recorded as an assumption. These rows do not constitute an annual catch-weight-at-age input matrix.
- **Aggregate indices:** Table 25 supplies four series with matching CVs: commercial CPUE (1993–2023), MRIP (1991–2023), Florida Keys RVC (18 reported years) and Dry Tortugas RVC (12 reported years). Index values remain on their source scales because physical multipliers are not stated. CVs are retained as ratios, not converted to standard errors. The assessment configuration places observations at mid-year; the Dry Tortugas survey itself samples in May–July.
- **Population summaries:** Table 28 supplies annual total biomass, female SSB, total abundance and age-0 recruitment for 1992–2023. Table 29 supplies combined F at age 4 and fleet-specific apical F for the same years. The output table has 256 rows. The report does not provide uncertainty intervals for these values.

## Remaining gaps

The assessment uses age and length compositions, but the numerical catch compositions are shown in figures and run-matched model input vectors were not found in the public bundle. Commercial conditional age-at-length data are described, but no machine-readable vectors were located. Fishery-independent age-at-length observations are not linked to the RVC abundance indices, so they cannot be used as index age compositions. Consequently, no catch numbers-at-age or survey numbers-at-age are imported. The report describes a full fitted N-at-age surface, but its numerical values are not published as a table or native fitted object; only total abundance and other summaries are available. The report also does not establish whether age 20 is a plus group. No estimates or uncertainty have been invented from figures.

Eligibility for an age-disaggregated comparison remains unresolved. The imported aggregate summaries are useful for source review but do not make this case translation-ready.

## Sources and provenance

- [SEDAR 96 Southeastern U.S. Yellowtail Snapper final assessment report](https://sedarweb.org/documents/sedar-96-southeastern-us-yellowtail-snapper-final-stock-assessment-report/), January 2025; Tables 7, 25–29.
- [SEDAR96-WP-07: Size and age information](https://sedarweb.org/documents/sedar-96-wp-07size-and-age-information-for-southeastern-us-yellowtail-snapper-ocyurus-chrysurus-collected-in-association-with-fishery-dependent-projects/), reviewed for data-sampling context.
- [SEDAR 96 document list](https://sedarweb.org/documents/sedar-96-southeastern-us-yellowtail-snapper-document-list/), checked for publicly listed model and input files.
- [NOAA Stock SMART record, stock 11081](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11081).

The three PDFs are cached under `source_cache/noaa_yellowtail_snapper_11081/noaa_yellowtail_snapper_11081_2025/source_material/`. Their URLs, revisions, retrieval date, sizes and checksums are in [`provenance/noaa_yellowtail_snapper_11081_2025/sources.csv`](../provenance/noaa_yellowtail_snapper_11081_2025/sources.csv).
