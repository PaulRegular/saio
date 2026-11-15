# DFO Western Component Pollock

## Stock unit and assessment

The assessment unit is Western Component Pollock (*Pollachius virens*): NAFO
4Xopqrs and the Canadian portions of 5Yb and 5Zc. This is the science unit;
the broader DFO management area also includes 4Xmn. It is distinct from NOAA
Stock SMART 10515 (5YZ), which overlaps geographically but is not the same
stock unit.

The latest full population-model run represented here is the 2022 assessment,
fitted through 2020. Research Document 2026/029 identifies Model J_M4B as the
reference model for the 2022 management strategy evaluation. Model J is the
ASAP version of Model F, which follows Model E; the progression carries the
acoustic index introduced in Model D forward into the reference-model family.
The 2025 harvest-control-rule update, published as Science Response 2026/015,
updates indices and advice without refitting the population model. It reports
the 2020 model SSB as 21,711 t, a 2025 q-adjusted three-year survey SSB index
of 28,368 t, and catch advice of 2,999 t for fishing year 2026–2027. The survey
index is not the same quantity as model SSB.

## Inputs and assumptions in the 2022 model

Research Document 2026/029, Table 1 (printed p. 34), provides corrected
commercial catch-at-age for ages 2–13 in 1982–2020, in thousands of fish. The
39-by-12 table is imported as 468 annual age-specific catch rows. The report
notes corrected age assignments for 2017–2020.

Table 5 (printed p. 39) provides summer RV relative-abundance indices at ages
2–13 for every year from 1984 through 2020, in thousands of fish. The 37-by-12
table is imported as 444 survey-index rows, preserving reported zeros. The
report describes simulated Eastern Georges Bank (EGB) index values in the
combined series except for 2016, 2017, 2019 and 2020, which use actual EGB
survey indices; row notes identify this distinction.

Table 10 (printed p. 47) reports the acoustic biomass index for 2012 and
2016–2020. The report describes disaggregating total biomass into an index at
age using tow length frequencies. The source table has 51 non-missing age
values for ages 2–12; its dashes indicate values not used, so they are retained
as missing and not entered as zeros. Six aggregate totals in metric tonnes are
also recorded. The table gives bootstrapped LowCI and HighCI values for each total but the confidence level is not stated. Since the input schema has no interval fields, these source bounds are preserved in the aggregate-row notes; they are not represented as age-specific uncertainty. Published age cells sum to within 1 mt of the total in five years, but sum to 38,407 mt in 2020 while Table 10 reports 38,061 mt. Part I, Table 9 reports the same total index as 38,408 mt, which agrees with the age-cell sum to rounding. These conflicting published totals are retained as printed; no adjustment or rescaling has been applied.

Table 12 reports Model F M4B natural mortality estimates for ages 5–13 as 0.661 (1994–2000), 0.587 (2001–2010), and 0.341 (2011–2020), each rounded to three decimals. The Model J description states that J_M4B uses the same M matrix as fixed input. The matrix is now recorded at the precision available in the report, together with fixed M=0.2 for ages 2–4 and the pre-1994 fixed block shown in the model specification. The report gives relative error and relative bias for the three estimated blocks; these remain in the input-row notes and are not converted to standard errors.

Run-specific year- and age-specific weight and maturity matrices remain unavailable. Catch and tuning indices are treated as mid-year observations, while population outputs are at the start of the year. Reported SSB is start-of-year biomass for ages 4+.

## Database coverage and remaining gaps

The database records the 2022 J_M4B model and 2025 HCR update separately. It
contains 468 commercial catch-at-age rows, 444 summer RV index-at-age rows,
51 acoustic biomass-at-age rows, six aggregate acoustic biomass-index rows, and 468 annual Model J_M4B mortality-input rows
from official report tables, along with summary outputs directly stated in
official reports. The 2025 q-adjusted survey SSB index remains distinct from
model SSB. Acoustic table dashes remain missing, not zero.

The run-specific weight and maturity matrices and annual
fitted population surfaces are still unavailable. The original Research
Document 2026/029 PDF could not be cached locally: direct requests returned
archived-page HTML. The ignored local source cache records those access
attempts and contains checksummed transcriptions of Tables 1, 5, 10 and 12 made
from the official searchable PDF text on 2026-11-14. These files are local
transcriptions, not cached PDF files.

## Sources

- [DFO Science Response 2026/015: HCR update in 2025](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-015-eng.pdf)
- [DFO Research Document 2026/029: population modelling and MSE](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-029-eng.pdf)
- [DFO Research Document 2026/025: data inputs](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-025-eng.pdf)
- [DFO Science Advisory Report 2023/037: MSE stock status and advice](https://publications.gc.ca/collections/collection_2023/mpo-dfo/fs70-6/Fs70-6-2023-037-eng.pdf)
- [DFO 2024 HCR update, published as Science Response 2025/012](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41291050.pdf)
- [DFO Pollock stock profile](https://www.dfo-mpo.gc.ca/species-especes/profiles-profils/pollock-goberge-eng.html)
