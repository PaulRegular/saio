# Icelandic Atlantic wolffish (caa.27.5a), 2026 assessment

Reviewed 2026-11-03. The current Icelandic management unit is Atlantic wolffish (*Anarhichas lupus*) in ICES Division 5.a. The 2026 MFRI production assessment is a statistical catch-at-age SAM assessment, uses data through 2025, and is represented by ICES Standard Graphs key 22633. This is distinct from the U.S. Gulf of Maine/Georges Bank Atlantic wolffish unit.

The current 2026 report and table export provide numeric age-specific inputs and outputs that were not captured in the earlier review. The report states that the model tracks ages 4-16, with age 16 as a plus group, and fixes natural mortality at 0.15 per year for all ages.

## Inputs recovered

- Catch numbers-at-age: ages 4-16+ for 1979-1980 and 1998-2025. The report explicitly says age-disaggregated catches were unavailable in 1981-1997 and total landings were used then. Although the public catch table contains numeric values in those years, they are excluded from the assessment catch-at-age input records.
- Landings-only period: annual totals for 1981-1997 are reconstructed by summing the official MFRI landings table over country and gear rows for Area 5a. These totals are in tonnes. The raw annual aggregates agree with the ICES source-data landings series within 8 tonnes over 1979-2025. The separate MFRI assessment-summary landings field does not reconcile directly (for example, 1981 is 8.359 in that table versus 8,621 tonnes in the raw aggregate); its scale/definition is unresolved. Landings are therefore recorded as a partial reconstruction, not claimed to be exact run-specific values.
- Catch weights-at-age and stock weights-at-age: ages 4-16+ in 1979-2025, grams per fish.
- Maturity-at-age: ages 4-16+ in 1979-2025, proportions. The report describes the maturity samples as female; the canonical rows retain that sex designation.
- Spring IS-SMB index: ages 4-16+ in 1985-2025. Autumn IS-SMH index: ages 4-16+ in 2000-2025. The table describes these age-disaggregated indices as numbers but does not identify the scaling multiplier, so the values are retained on their native index scale. Sampling times of 0.17 (March) and 0.83 (mostly October) are approximate fractions of a calendar year.
- The published 2011 autumn-index row is retained. The public table does not resolve whether it is a direct autumn observation or a substituted series.
- The MFRI tables page lists SSB weights, but its cached SSB-weight table contains no numeric rows. No values are imputed from stock weights.

The 2022 ICES Stock Annex describes earlier input-construction details, but the numerical rows imported here come from the current 2026 MFRI tables page. The 2026 table and report do not expose the full production likelihood setup, all observation weights/effective sample sizes, or the exact residual-correlation structure.

## Outputs recovered

- N-at-age: ages 4-16+ for 1979-2026, thousands of fish. The 2026 row is a forecast; fitted data end in 2025.
- F-at-age: ages 4-16+ for 1979-2025, per year.
- SSB: 1979-2026, tonnes, with reported 95% confidence limits.
- Recruitment: age 4, 1979-2026, thousands of fish, with reported 95% confidence limits.
- F for ages 10-15: 1979-2025, per year, with reported 95% confidence limits.
- The age-specific N and F tables have no accompanying uncertainty. M is fixed, so there is no estimated M surface or M uncertainty to import.

The MFRI assessment-summary values for SSB, recruitment, and F agree with the ICES source-data series where both are finite. Recruitment also matches age-4 N in the MFRI population table. The ICES source-data page includes 2026 aggregate forecasts; no later advice projections are mixed into these annual series.

The stock and assessment records are marked partial because the exact run input files and likelihood configuration are unavailable, the landings-only reconstruction has a source-definition discrepancy, the 2011 autumn row is unresolved, and age-specific uncertainty is not reported.

## Sources and local cache

Authoritative sources are cached under the gitignored source_cache/discovery_ices_iceland_wolffish_2026/ directory. The local sources.csv records retrieval dates, pinned assessment identity, file sizes, and SHA-256 checksums for the report, advice, table page, ICES source data, and locally extracted table CSVs. The shared 2022 WKICEMP framework report is referenced from the adjacent Icelandic plaice cache.

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_techreport_en.html)
- [MFRI 2026/2027 advice](https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_advice_en.html)
- [MFRI 2026 tables](https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_tables_en.html)
- [ICES Standard Graphs, charts key 22633](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22633) and [source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22633)
- [ICES 2022 Stock Annex](https://doi.org/10.17895/ices.pub.22819988) and [WKICEMP benchmark report](https://doi.org/10.17895/ices.pub.19663971)

A search did not locate a current run repository or fitted SAM object. The stockassessment package is not installed in this execution environment, so fitfromweb() could not be queried. This does not establish that a fitted object is unavailable.
