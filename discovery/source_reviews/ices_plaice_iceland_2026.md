# Icelandic plaice (`ple.27.5a`), 2026 assessment

Reviewed 2026-10-29. ICES identifies `ple.27.5a` as plaice in Division 5.a (Iceland grounds), assessment year 2026, key 22531. The latest detailed production report is MFRI's 2026 assessment report, which describes data through 2025. This is a distinct current management unit from the North Sea and Baltic plaice records already in the database; no canonical record uses the `ple.27.5a` authority code.

The 2026 report describes a statistical catch-at-age SAM. Commercial catch-at-age is available from 1979 onward, and the age-disaggregated Icelandic spring groundfish survey (IS-SMB) index is available from 1985 onward. The report identifies age 12 as the plus group and estimates recruitment at age 3. Its 2026 assessment advice identifies catch in numbers and the age-disaggregated IS-SMB index as assessment inputs. The catch-at-age, survey-index, stock weight-at-age, maturity-at-age, and model-fit series are shown mainly in figures rather than numerical annual matrices. Exact matrix values and some plotted units therefore remain to be verified before source import; any digitization must be documented and retain its visual-source precision limits.

The report says natural mortality is fixed at 0.15 per year for all ages. Stock weights-at-age use spring-survey data; ages 9+ are smoothed with a three-year running average, and pre-1985 values use the 1985 levels. Female maturity-at-age is estimated from annual maturity-at-length ogives and length distributions, smoothed with a three-year running average, with pre-1985 values held at 1985. The fitted age-specific index is the March spring survey. A timing fraction of 0.125 is a quarter-based approximation, not a recovered SAM setting. The separate autumn survey and its aggregate indices should not be treated as the fitted age-specific survey input.

The MFRI assessment table and ICES Standard Graphs report recruitment at age 3, SSB, and F for ages 5–10 annually with 95% uncertainty intervals. Catch totals are also shown. The latest fitted-year outputs are through 2025; the 2026 row in the ICES assessment graphs is a projection and is not part of the fitted historical series. The public reports and graphs do not provide full fitted N-at-age or F-at-age arrays, nor age-specific output uncertainty.

The 2022 ICES Stock Annex and WKICEMP benchmark report describe the model framework and data review. A search of the MFRI data server found stock-assessment CSV directories only through 2018; no 2026 run-specific numerical input bundle or fitted SAM object was located in the reviewed MFRI or ICES sources. The public record is nevertheless eligible for source curation because the latest production report documents age-disaggregated likelihood inputs and comparable outputs. The complete numerical input package has not been recovered.

Sources:

- [MFRI 2026 plaice assessment report](https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_techreport_en.html), data through 2025.
- [MFRI 2026/2027 advice](https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_advice_en.html), published 12 June 2026.
- [ICES Standard Graphs, assessment key 22531](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22531) and [source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22531).
- [ICES 2022 Stock Annex](https://doi.org/10.17895/ices.pub.20132660.v1).
- [ICES 2022 WKICEMP benchmark report](https://doi.org/10.17895/ices.pub.19663971).

The reviewed reports and graph pages are cached in the gitignored `source_cache/discovery_ices_iceland_plaice_2026/`; its `sources.csv` records URLs, retrieval date, assessment revisions/keys, file sizes and SHA-256 checksums.
