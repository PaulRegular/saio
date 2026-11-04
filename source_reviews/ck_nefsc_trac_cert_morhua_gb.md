# Eastern Georges Bank Atlantic cod

## Identity and selected records

`ck_nefsc_trac_cert_morhua_gb` retains Charbonneau-Keith identifier
`NEFSC-TRAC-CERT_morhua_GB`. The catalogue's source label, `GB 5Ze Gadus
morhua.pdf`, refers to the eastern transboundary assessment unit. This is now
DFO's 5Zejm unit, corresponding to US statistical areas 551, 552, 561 and 562.
It is distinct from the broader NOAA domestic Georges Bank stock and the
alternative total-Georges-Bank (TGB) model. No assessment values are borrowed
from either of those models.

The database separates three events:

| Assessment ID | Event | Historical terminal year | Current detailed record |
|---|---|---|---|
| `dfo_cod_eastern_georges_bank_2025_framework` | Selected EGB WHAM framework, approved in 2025; detailed documents published in 2026 | 2023 | Yes |
| `dfo_cod_eastern_georges_bank_2025_summary` | June 2025 assessment; SAR 2025/039 | 2024 | No: newer summary only |
| `dfo_cod_eastern_georges_bank_2026_summary` | June 2026 assessment; SAR 2026/046, published September 2026 | 2025 | No: latest advice, summary only |

The detailed modelling report identifies EGB Run 1 (internal run 84) with
two-dimensional AR1 older-age process error. The projections/reference-points
document explicitly selects EGB for the framework because raw US sub-trip
data required for TGB were not accessible. TGB was preferred biologically;
that preference does not make its numerical outputs the selected DFO EGB run.
The framework year follows the approval year stated in the annual advice,
not the research documents' 2026 publication year.

## Inputs and assumptions recovered

The framework is a sex-combined WHAM model for 1978-2023, ages 1-9+, with age 1
recruitment. Three separate fleet total-catch inputs are recovered from
Research Document 2026/039 Table 1: Canada reported, US reported EGB, and US
misattributed EGB (46 years each). The adjacent TGB column is excluded. The
one-tonne misattribution values outside 2005-2016 are an explicit source-model
floor imposed because WHAM could not accept zero fleet totals. They are
preserved as supplied inputs, not interpreted as measured one-tonne catches.
The selected misattribution CV is 0.2; the empirical CV of 0.57 is not the
fitted model's observation CV.

Canadian CATCH weight-at-age from Research Document 2026/032 Table 6 is
preserved at its original 1978-2022, age 1-16 resolution (720 values, kg per
fish), including printed zeros and rounding. The source retains CATCH for
weights, but the table is not a complete stock-weight or multi-fleet weight
surface, nor an identified model age-9+ weight. Zero cells are not replaced,
2023 weights are not extrapolated, and older ages are not pooled using
unverified age abundances.

**The CATCH numbers-at-age in Part 1 Table 5 are not the selected observations.**
The peer-review conclusion on pp. 10-11 selects NTS catch-at-age while
retaining CATCH weights. Consequently Table 5 is not imported as the EGB
model's age observations. Its count-scale multiplier is also not inferred.
US EGB age compositions are explicitly missing in 2020-2023. Published figures
and fitted states are not used to fill either country's observation arrays.
Figures 23 and 40 in the data-input review plot fishery and survey catch-at-age
as bubbles, but provide no numeric labels or bubble-size scale. They establish
the plotted fleets, years and age ranges, but do not permit reproducible
recovery of the selected NTS catch observations or survey age-composition
observations. No values are digitized from these figures.

The framework fits separate aggregate-biomass and age-composition data for
DFO winter, NMFS spring and NMFS fall RV surveys. Table 10 of the data-input
report provides the three EGB swept-area biomass index series in metric tonnes.
The selected model period, 1978-2023, is imported with one row for every year
and survey: 37 finite DFO winter values, 44 NMFS spring values and 44 NMFS fall
values. The winter series begins in 1986; both NMFS series are missing in 2020
and 2023. Source dashes remain missing, not zero. The table also lists TGB
mean kg/tow series, which are excluded. Its notes identify the NMFS EGB
length-based corrections for vessel and trawl-door changes. The modelling
report identifies these three surveys in the selected EGB run.

Aggregate observations have bias-adjusted lognormal errors; compositions use
a Dirichlet likelihood that pools nil cells with adjacent ages. DFO winter
and NMFS spring selectivity are logistic; fall selectivity is estimated by
age, fixing ages 2 and 3 at 0.8 and 1. Survey seasons do not establish exact
configured sampling fractions. Those fractions, numerical annual CV arrays
and age-composition observations remain unavailable.

Recruitment is a log-scale random walk with AR1-correlated innovations,
separate from the older-age two-dimensional AR1 deviations. The report states
that fixed Lorenzen M was calculated from weight-at-age and varied by year and
age. Figure 11 prints black annual M points for ages 1-9 across 1978-2023;
these 414 points have been digitized as approximate source inputs. The blue
smoothers are excluded, no missing years are interpolated, age-1 values are
rounded to 0.01, and ages 2-9 to 0.001. Age 9 is mapped to the model's 9+ group
from the reported age grid. These are figure read-offs, not a verified copy of
the native WHAM input array, and do not represent internally estimated M.
Older-fish apparent mortality inferred from N process error is not a directly
estimated M surface. The exact native M array, full biological surfaces,
spawning fraction, native model configuration, numerical process parameters
and exact bias-adjustment settings remain unrecovered.

## Outputs and later updates

Table 4 supplies three aggregate survey q coefficients for selected EGB
Run 1: 0.434 (DFO winter), 0.223 (NMFS spring), and 0.109 (NMFS fall). These
are separate from age selectivity and are not direct age-specific q. Their
native unit multiplier is unresolved; no scale change, SE or CI is invented.
Approximate M inputs are digitized from the black points in Figure 11. Full
historical N/F/SSB/recruitment surfaces are shown only as figures in the
framework documents. The fitted WHAM object and numerical arrays were not
recovered from the cited publications, DFO data/code links, NOAA resources or
public model-repository searches. Generic WHAM examples, rejected TRAC models
and the separate NOAA domestic GB run are not substitutes.

Research Document 2026/073 identifies the LRP method as the SSB where mean
surplus production is not significantly different from zero. The document's
text does not state a numerical threshold, but reports two candidate USR
approaches of 43.7 and 51.4 kt. The 2025 and 2026 Science Advisory Reports
still say that a USR has not been determined, so those candidates are not
recorded as adopted reference points. The annual summaries report separate
LRP values: 24.9 kt for the 2025 assessment and 26,847 metric tonnes for the
2026 update. They remain attached to their respective assessment records.

The 2025 summary reports SSB of 7.96 kt in 2022 and 10.9 kt in 2024, plus
fully-selected F of 0.03 in 2024. Its Current Status paragraph separately
reports 2024 median SSB of 10.4 kt at 42% of the 24.9 kt LRP. The database
retains the 10.9 kt headline value and flags the conflicting 10.4 kt text.
The 2026 summary supplies Canada/US removals for 2016-2025, median 2025 SSB
of 8,469 t, the 26,847 t LRP and fully-selected F of 0.03. Native kt and tonne
units are preserved. These F coefficients are not F-at-age or
population-weighted Fbar. Numerical uncertainty is unavailable; plotted
bands are not digitized.

Two internal discrepancies in SAR 2026/046 remain explicit. It gives 2022
SSB as 8,273 t in the summary and 8,327 t in the body; neither is selected for
the database. Table 1's average column is labelled 2004-2015 in the header
and 2004-2019 in the caption. That average is excluded rather than assigned
to 2015 or any other single year. Only unambiguous annual 2016-2025 removals
are imported. Revisions between events remain separate: for example, 2023 US
reported catch is 31 t in the framework table and 32 t in later summaries.

The 2025 update adds DFO stratum 5Z9 for 2010-2024 and calibrates the 2022
DFO vessel/gear change. The 2026 assessment excludes the 2025 NMFS fall survey
point after reviewing its timing and coverage. Earlier framework inputs must
not silently stand in for those revised observation arrays.

## Validation and source coverage

The importer is `scripts/database/147_import_dfo_eastern_georges_bank_cod.R`.
It verifies cached source hashes and table dimensions, preserves original
ages/years/units and changes only this stock and its three assessment records.
The focused test checks current-versus-summary selection, all three fleet
totals, weight coverage and zeros, all three aggregate survey index series and
their missing years, selected q, source output definitions, missing
uncertainty, omitted averages and conflicting values, and the remaining
unavailable age observations.

There are 1,440 recovered inputs (1,410 for the framework, including 414 approximate M points), 22 assumptions and ten outputs across the three events. All completeness statuses remain **partial**.

## Sources and cache

- [Data-input review, Research Document 2026/032](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331539.pdf), especially pp. 9-11, Table 6 and Table 10.
- [Modelling review, Research Document 2026/039](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331783.pdf), especially pp. 3, 5-10 and Tables 1, 3-4.
- Research Document 2026/073, *5Z Cod Assessment Framework: Projections and Reference Points*, October 2026, pp. 1-2; the DFO download URL is in the local manifest.
- [2025 assessment summary, SAR 2025/039](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41299206.pdf).
- [2026 assessment summary, SAR 2026/046](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41341557.pdf).

Authoritative PDFs are cached under `source_cache/ck_nefsc_trac_cert_morhua_gb/`
with URLs, retrieval dates, sizes and SHA256 checksums in `manifest.csv`.
The earlier `_2025` cache contains HTML landing pages bearing PDF suffixes;
those are not PDFs and are excluded from extraction. A landing page response
must not be mistaken for missing or verified assessment data.
