# Icelandic summer-spawning herring

## Assessment represented

The canonical stock is Icelandic summer-spawning herring (*Clupea harengus*) in
ICES Division 5.a (Iceland grounds), stock code `her.27.5a`. The selected event
is the official 2026 production assessment used for ICES advice. It uses SAM,
adopted for the 2024 assessment after the WKICEHER benchmark. The ICES Stock
Assessment Graphs 2026 record is key 22455.

The exact production run and all of its input files were not found in the
public `stockassessment.org` user directory. The matching folders found there
(`ICEherring` and `testIceland`) are historical runs from 2020 and 2022, so they
were not treated as the 2026 production model. The 2024 WKICEHER report and the
2024 stock annex were used to document the model structure, not to replace
2026 observations or estimates.

The MFRI machine-readable 2026 assessment tables provide age-specific input
matrices through 2023, stock numbers and fishing mortality through 2024, and
aggregate assessment series through 2026. The 2026 technical report separately
publishes raw catch-at-age through 2025 and acoustic estimates through 2026.
Those more recent raw series do not have a complete corresponding set of
biological and age-specific output tables, and their exact mapping to the
production SAM input years and ages is not published. The database therefore
retains the machine-readable model matrices as the imported input series and
marks inputs and assumptions partial. It does not splice the raw report series
into the assessment-table series.

## Inputs and assumptions

The assessment tables cover ages 2–15. The 2024 benchmark configuration treats
age 15 as a modeled age, not a plus group; uses recruitment at age 2; uses an
AR(1) fishing-mortality process across ages; shares F parameters across ages
7–15 after estimating separate age effects at ages 2–6; and uses a piecewise
constant stock-recruitment model. Survey q is separate at ages 3–6 and shared
at ages 7–15 in that configuration. The exact 2026 production configuration
was not recovered, so these settings are recorded as benchmark-derived rather
than verified production settings.

The machine-readable tables contain catch-at-age, acoustic survey index,
catch and stock weights, and maturity. Counts are in millions of fish, the
age-specific stock abundance outputs are in thousands of fish, weight values
are in kilograms per fish, and maturity is a proportion. The 2024 benchmark
places the acoustic observations at the beginning of the assessment year.
The MFRI tables' year-age indexing is retained without an additional shift;
the report's separately labelled autumn survey series is not treated as a
direct copy of that model-year table.

Natural mortality has a baseline of 0.1 per year plus infection-related
mortality. The infection multiplier is estimated, and the age-year mortality
surface is only published in the older benchmark material. The 2026 numerical
surface was not recovered, so the database records the 0.1 baseline separately
and does not claim that it is total official M. MFRI reports stock weights and
maturity as known inputs. The exact annual survey covariance, observation
weights, and production-run variance parameters are not available.

## Outputs and limitations

The 2026 ICES source series reports SSB and recruitment through 2026, with a
95% confidence-interval definition. MFRI tables publish numbers-at-age and
fishing mortality-at-age through 2024 without age-specific uncertainty. The
MFRI summary also reports F and harvest rate; harvest rate is retained as its
own measure and is not interpreted as Fbar. Fbar ages 5–10 is taken from the
benchmark and recorded with the MFRI F series.

Input and output status are `partial` because the production model's fitted data mapping, the current infection-M surface, and age-specific uncertainty are not fully recoverable. The MFRI machine tables and later report series are not one verified input run.

## Source files cached locally

The gitignored cache is
`source_cache/ck_ices_nwwg_harengus_ice_summer/assessment_2026/`.
It contains the MFRI 2026 report, table page, advice page, ICES SAG 2026 XML,
the 2024 WKICEHER report, and the 2024 ICES stock annex. The local manifest
records retrieval URLs, dates and SHA-256 checksums.

Sources:

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_techreport_en.html)
- [MFRI 2026 assessment tables](https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_tables_en.html)
- [MFRI 2026 advice](https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_advice_en.html)
- [ICES Stock Assessment Graphs, 2026 key 22455](https://sg.ices.dk/ViewCharts.aspx?key=22455)
- [ICES WKICEHER 2024](https://doi.org/10.17895/ices.pub.25605135)
- [ICES stock annex, 2024](https://doi.org/10.17895/ices.pub.25639419)
