# NOAA Far North Migrating Chinook salmon (2024 detailed status assessment)

## Assessment and sources

NOAA Stock SMART ID 10604 is listed as Chinook salmon - Eastern North Pacific
Far North Migrating, under the Alaska Salmon Fisheries in the EEZ Fishery
Management Plan. The latest detailed full-acceptance operational record in the
cached Stock SMART summary is assessment 13942, finalized in 2024 with data
through 2024. Stock SMART labels the assessment model “Chinook model,” Model
Category 2 (index-based), Composition Input Data 0, Catch Input Data 5,
Abundance Input Data 5, and Biological Input Data 3. The data dictionary
defines Composition Input Data 0 as no composition data collected. Catch Input
Data 5 describes very complete total catch; it does not mean catch-at-age.
Likewise, the abundance and life-history scores do not provide an age-indexed
input surface.

NOAA's fourth-quarter 2025 stock-status table is a newer annual status update:
it lists this unit as neither subject to overfishing nor overfished. The table
contains no age-specific inputs or population surfaces. The latest detailed
public report located is NOAA's 2024 Status of Salmon Stocks Under the Alaska
Salmon FMP. It describes the East Area Chinook status framework. Fishing status
uses the prior five years of all-gear catch and preseason catch limits; the
overfished determination compares five-year pooled escapement across 22 Pacific
Salmon Commission indicator stocks with the corresponding aggregate threshold.
The report therefore does not provide a single-stock age-structured population
assessment for the named Far North Migrating Stock SMART unit.

The 2024 Stock SMART row reports catch and biomass-like values on five-year
rolling bases, but the detailed status report shows that these are management
status summaries, not annual F-at-age or N-at-age surfaces for this candidate.
They were not copied into the canonical database as population outputs.

## Screening decision

This is a distinct NOAA Salmon FMP reporting unit and has no exact canonical
stock match. The broad migration-based label overlaps with multiple river and
transboundary Chinook populations; a one-to-one crosswalk to a DFO or NOAA river
unit is not supported. It is screened **ineligible** for the age-structured
comparison set: the assessment is index-based, its composition-input score is
zero, and the available detailed source reports aggregate catch and pooled
escapement status rather than catch-at-age, age-specific abundance, biological
surfaces, or N/F/M-at-age outputs. No canonical assessment, input, or output
rows were added.

## Sources and cache

- [NOAA 2024 Status of Salmon Stocks Under the Alaska Salmon FMP](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10339).
- [NOAA fourth-quarter 2025 Stock Status Tables](https://www.fisheries.noaa.gov/s3/2026-02/FINAL-Q4-2025-Stock-Status-Tables.pdf), listing the unit's status as not overfishing and not overfished.
- [NOAA Stock SMART, ID 10604](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10604).
- [NOAA Stock SMART Data Dictionary](https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf).

The two status PDFs and data dictionary are cached under
`source_cache/noaa_far_north_chinook_2024/`; its `sources.csv` records each URL,
retrieval date, file size, and SHA-256 checksum. The pinned Stock SMART summary
snapshot and provenance are retained in
`source_cache/discovery_noaa_stocksmart/`.