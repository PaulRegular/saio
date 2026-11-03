# Irish Sea herring: 2026 source review

ICES stock `her.27.nirs` is herring in Division 7.a north of 52°30′N. The 2026 HAWG report describes the applied SAM assessment with terminal year 2025. This is a distinct current assessment unit from Celtic Sea herring (`her.27.irls`, south of 52°30′N) and West of Ireland herring (`her.27.6aS7bc`).

## Inputs and assumptions

The HAWG 2026 report provides detailed numerical assessment tables:

- Table 8.2.1.2 reports catch-at-age in thousands for winter-ring ages 1–8+ over 1980–2025. There is no estimate for 2009.
- Table 8.3.1 reports Irish Sea Acoustic Survey (ISAS) age-specific abundance in thousands for ages 1–8+ over 1994–2025. Table 8.3.2 gives the Irish Sea Commercial Acoustic Survey (ISSS) aggregate SSB index for 2007–2025; the report does not state an index unit or multiplier.
- Tables 8.5.1–8.5.2 provide catch and stock weights-at-age in kg. Catch weights use all catch seasons; stock weights are based on Q3 catches. The published 2009 values are means of 2008 and 2010 values at age.
- Table 8.5.3 provides annual maturity ogives for ages 1–8+ from Q3 catch samples. The published 2009 values are means of 2008 and 2010 values at age.
- Table 8.5.4 gives fixed natural mortality for all years, borrowed from North Sea herring: 0.787, 0.380, 0.353, 0.335, 0.315, 0.311, 0.304 and 0.304 for ages 1–8+.
- ISAS is conducted in late August and September. The 2025 survey ran 26 August–19 September, with remaining transects completed 7–9 October. ISSS is normally conducted in late September or early October. The exact annual sampling-time fractions used by the assessment were not found.

The source import retains the printed 2009 biology values and does not recompute them from rounded cells. Age 8 is retained as the reported 8+ group. ISAS values are stored in thousands of fish; ISSS values are kept on the reported scale because its unit is not stated. No additional scaling, missing-value imputation or numeric survey timing is applied.

The report refers to the 2026 stock annex for model settings. The latest public `ices-advice` code snapshot located is from 2024, revision `808b6c896474f7210c7f95ee4c7aef5046aaf491`, before the 2024 and 2025 configuration reviews described by HAWG. It is not used as a source of current numerical inputs. No 2026 `ices-taf` repository was found.

## Outputs and limitations

HAWG Table 8.7.1.1 reports annual age-1 recruitment, SSB, Fbar at ages 2–4 and catch through 2025. It provides 95% intervals for recruitment, SSB and Fbar, but not for total catch. ICES SAG source data (key 21319) additionally report total biomass and landings; total biomass has 95% intervals. The SAG outputs were imported for 1980–2025, excluding its 2026 forecast row. The 2025 values match HAWG: recruitment 157,581 thousand, SSB 11,298 t, Fbar 0.342 and total catch 5,359 t. SAG reports identical catch and landings series. Fitted N-at-age and F-at-age arrays were not recovered.

HAWG documents substantial uncertainty in acoustic scaling: estimated survey catchabilities range from 2.7 to 4.9, and fitted biomass is below direct survey biomass estimates. The assessment treats the fishery and surveys as mixed-stock observations, including Celtic Sea herring; the extent of mixing is not quantified and occurs across ages. Natural mortality is borrowed from North Sea herring rather than estimated for this stock.

## Imported database record

`ices_her_27_nirs_2026` is the current assessment record and remains partial. It contains 1,747 input rows, 18 assumption records and 276 output rows:

- Inputs include catch-at-age, both acoustic series, catch and stock weights-at-age, maturity-at-age, and fixed age-specific M.
- Outputs include recruitment, total biomass, SSB, landings, total catch and Fbar (ages 2–4).
- Fitted N-at-age and F-at-age are unavailable. The public sources also do not provide the applied fitted object, exact observation-error weights or precise annual survey timing fractions. These gaps keep the assessment, input and output completeness statuses partial.

The full HAWG report is cached in the shared Celtic Sea herring source folder. The Irish Sea SAG pages and extracted HAWG table text are cached locally under `source_cache/discovery_ices_irish_sea_herring_2026/`. The downloaded sources have retrieval dates and SHA-256 checksums in their cache manifests.

## Sources

- [HAWG 2026 full report, section 8 and Tables 8.2.1.2, 8.3.1–8.3.2, 8.5.1–8.5.4, 8.7.1.1](https://doi.org/10.17895/ices.pub.31424315)
- [ICES 2026 SAG graphs, key 21319](https://standardgraphs.ices.dk/ViewCharts.aspx?key=21319)
- [ICES 2026 SAG source data, key 21319](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21319)
- [ICES 2027 advice](https://doi.org/10.17895/ices.advice.32133760.v1)
- [Older 2024 ICES-advice code snapshot](https://github.com/ices-advice/2024_her.27.nirs/tree/808b6c896474f7210c7f95ee4c7aef5046aaf491/2024_her.27.nirs_assessment)

This review is based on sources retrieved 2026-10-29.
