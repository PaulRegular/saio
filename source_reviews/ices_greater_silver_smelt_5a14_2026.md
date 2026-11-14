# ICES greater silver smelt, aru.27.5a14, 2026

## Assessment unit and run

This record covers greater silver smelt (*Argentina silus*) in ICES Subarea 14 and Division 5.a (East Greenland and Iceland grounds). The 2026 MFRI assessment supported 2026/2027 advice and used an annual statistical catch-at-age (SAM) model. The reported fitted series ends in 2025; the 2026 values on the ICES Standard Graphs page are forecast/advice values and are not included in the fitted output series.

The 2025 ICES WKBDEEP benchmark replaced the earlier Gadget method with SAM. It selected fixed natural mortality of 0.1 per year for all ages. The report identifies recruitment at age 5 and Fbar over ages 6–14. Management reference points include FMSY = 0.093 per year, Bpa/MSY Btrigger = 49,481 tonnes, and Blim = 40,531 tonnes.

## Source files and provenance

The 2026 MFRI technical report, 2026 advice page, ICES Standard Graphs page and source-data table, and 2025 WKBDEEP report are cached in the ignored `source_cache/discovery_ices_gss_2026/` folder. Retrieval dates, URLs, sizes and SHA-256 checksums are in `provenance/ices_greater_silver_smelt_5a14_2026/manifest.csv`.

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/19_arg_2026_1_techreport_en.html)
- [MFRI 2026/2027 advice](https://www.hafogvatn.is/static/extras/images/19_arg_2026_1_advice_en.html)
- [ICES 2026 Standard Graphs](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22476)
- [ICES 2026 Standard Graphs source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22476)
- [ICES WKBDEEP 2025 benchmark report](https://doi.org/10.17895/ices.pub.28882295)

## Values imported

The database includes the annual `Catches` series published in the ICES Standard Graphs source table for 2000–2025 (26 tonnes values). It also includes 104 annual official outputs for 2000–2025: total biomass, SSB, age-5 recruitment, and Fbar for ages 6–14. The lower and upper fields preserve the source's 2.5th and 97.5th percentile values. The source does not report standard errors.

The current MFRI report's Table 3 provides landings separately for Section 5.a and Section 14.b from 1988–2025. Those source values were checked against the ICES catch series but are not substituted for it because the report's Section 5.a values differ in three years: 2015 (6,058 tonnes versus 6,068), 2019 (3,209 versus 3,211), and 2020 (3,775 versus 3,780). The reason for the small differences is not given. Section 14.b catches are also shown separately in MFRI Table 3; the reviewed sources do not identify those values as a separate fitted SAM observation series. No separate row is inferred from them.

The standard-graph 2026 row is excluded from the fitted series because it represents the advice-year forecast. Published forecast values remain available in the cached source but are not mixed with the 2000–2025 assessment estimates.

## Remaining source gaps

The current report describes commercial catch age data and age-specific indices from the IS-SMB spring groundfish survey and IS-SMH autumn groundfish survey. The age composition, survey-at-age, stock-weight-at-age and maturity-at-age information is presented in figures rather than recoverable numerical tables. A native SAM input file or fitted object was not located. The assessment-specific catch values before 2000, annual within-year survey timing fractions, numeric age-specific biological surfaces, and age-specific N and F outputs therefore remain unavailable.

The imported assessment is partial. The available annual catch and aggregate outputs support source-level review, but they do not yet provide the numeric age-specific inputs needed for a defensible tinyAM translation.
