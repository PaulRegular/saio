# Icelandic plaice (`ple.27.5a`), 2026 assessment

Reviewed 2026-11-14. The current stock unit is plaice in ICES Division 5.a
(Iceland grounds), assessment year 2026. The detailed MFRI production report
uses data through 2025. This is a distinct current management unit from the
North Sea and Baltic plaice records already in the database.

## Inputs and assumptions

The 2026 production assessment is a statistical catch-at-age SAM. The MFRI
supplementary **Tables** page provides annual numerical catch-at-age in
thousands for ages 3-12 from 1980-2025. The assessment report says catch-at-age
is used from 1979, so the 1979 age row remains unavailable. Age 12 is the plus
group. The table has one combined commercial catch series and does not split
catch-at-age by gear.

The page also provides catch weights and stock weights in grams per fish for
ages 3-12 from 1980-2025. Catch weights describe commercial catches. Stock
weights are based on the spring survey; ages 9+ are smoothed with a three-year
running average, and values before 1985 use 1985. Numerical female maturity
proportions are available for ages 3-12 over the same years. The report says
these are derived from annual maturity-at-length ogives, smoothed with a
three-year running average, with pre-1985 values held at 1985 levels. The
separate table for spawning-stock weights is empty, so those values are not
available.

The MFRI IS-SMB table provides age-disaggregated spring-survey index values
for ages 3-12 from 1985-2025. Five year-age cells are blank and remain missing.
The table describes the values as numbers but does not state a scale
multiplier. Values are stored on the reported index scale without rescaling.
The survey occurs in March; an exact within-year timing fraction is not
reported and remains unknown. Natural mortality is fixed at 0.15 per year.

## Outputs

The MFRI Tables page provides historical estimated stock numbers-at-age in
thousands for ages 3-12 from 1980-2025 and fishing mortality-at-age per year
for the same period. The 2026 stock numbers are published with the short-term
forecast and are stored separately from historical fitted values. No
age-specific uncertainty is reported.

ICES Standard Graphs assessment key 22531 supplies annual age-3 recruitment,
SSB, total biomass and F for ages 5-10 through 2025. The MFRI report's Figure
28 caption defines low/high bounds for recruitment, SSB and F as **90%
confidence intervals**. No standard errors are derived. Total biomass
estimates have no reported bounds. MFRI Table 5 supplies the 2026-2028
short-term forecast for F(5-10), recruitment at age 3, SSB and catch; these
remain separate from historical observations.

## Coverage and limitations

The source record now includes the numerical age tables that were previously
only identified in the report figures. Input completeness remains partial
because the published catch table begins in 1980 despite the report's 1979
model-data start, the spawning-stock weight table is empty, and the IS-SMB
index multiplier is not stated. The five missing survey cells are not filled.
Assumption completeness remains partial because exact survey timing and other
run-specific settings are not fully exposed in the published tables. Output
point-estimate coverage is complete for the published historical age surfaces
and aggregate series; age-specific uncertainty is unavailable.

## Sources

- [MFRI 2026 production report](https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_techreport_en.html), including model description, Tables 2 and 5, and Figure 28.
- [MFRI supplementary numerical tables](https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_tables_en.html), including catch-at-age, catch/stock weights, maturity, IS-SMB index, N-at-age and F-at-age.
- [MFRI 2026/2027 advice](https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_advice_en.html).
- [ICES Standard Graphs assessment key 22531](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22531) and [source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22531).
- [ICES 2022 Stock Annex](https://doi.org/10.17895/ices.pub.20132660.v1).
- [ICES 2022 WKICEMP benchmark report](https://doi.org/10.17895/ices.pub.19663971).

The reviewed report, advice, tables page, graph pages, and framework PDFs are
cached under the gitignored `source_cache/discovery_ices_iceland_plaice_2026/`.
Their retrieval dates, revisions, byte sizes, URLs and SHA-256 checksums are
recorded in `provenance/ices_plaice_iceland_5a_2026/sources.csv`.
