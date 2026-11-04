# Greenland halibut, NAFO Subarea 2 + Divisions 3KLMNO

## Current unit and annual advice

The stock is the transboundary Greenland halibut (*Reinhardtius hippoglossoides*) unit in NAFO Subarea 2 and Divisions 3KLMNO. It is distinct from DFO's Gulf of St. Lawrence 4RST stock and from Greenland Subarea 1 units.

The latest annual update reviewed is the 2026 NAFO Scientific Council report. It applies the management procedure adopted in 2024 to recommend a 2027 total allowable catch of 14,351 tonnes. The report gives five survey series through 2025 and the resulting TAC; it does not report a new age-structured population fit. This information is stored in `dfo_greenland_halibut_2_3klmno_2026_mp`.

The detailed age-structured models reviewed here are the separate 2023 SCAA and SSM MSE assessments, both fitted through 2021. Neither model was the annual TAC advice model.

## 2023 SCAA base-case operating model

`dfo_greenland_halibut_2_3klmno_2023_scaa` records the 2023 statistical catch-at-age (SCAA) base-case operating model used for management-strategy evaluation. The 2023 report states that the 2017 SCAA method was updated with data through 2021. This is a separate run and input set from the state-space model in `dfo_greenland_halibut_2_3klmno_2023_ssm`.

The imported SCAA inputs are:

- Landings in kilotonnes for 1960-2021. The supporting data report states that the SCAA uses landings from 1960 onward.
- Commercial catch numbers-at-age in thousands of fish, ages 0-10+, for 1975-2021. The supporting data table gives ages 1-10+; the SCAA report's Table B2 also shows age 0, reported as zero in every year.
- Commercial catch weights-at-age in kilograms per fish, ages 0-10+, for 1975-2021. Age 0 is zero in the SCAA table; age 10 is the 10+ group. The model method uses catch weights as the available fish-mass-at-age input; no separate stock or spawning weight series was recovered.
- Survey mean numbers per tow at ages 0-10+ and mean-weight-per-tow biomass indices in kilograms per tow for the six SCAA base-case series: Canada Autumn 2J3K, Canada Autumn 3LNO, Canada Spring 3LNO, EU 3M 0-700 m, EU 3M 0-1400 m, and EU-Spain 3NO. Coverage varies by series. The EU-Spain 3L and 3LNO series are sensitivities and are not included in the base-case event.
- A fixed maturity schedule: ages 1-9 are immature and ages 10-14+ are mature.

The supporting data report prints the numerical input tables at two decimal places. Those values are preserved at the printed precision. In the SCAA report, the age-8+ Canada Autumn 2J3K values are present in 2018, 2019, and 2021. They remain present here. The companion SSM report excludes those nine age-8+ cells because deep strata were not covered; that SSM exclusion is not applied to the SCAA event. The supporting report leaves some EU 3M age-0 cells blank, while the SCAA Table B5 prints them as zero; the imported SCAA rows preserve those reported zeros. Other blank cells remain missing.

The SCAA base case fixes natural mortality at 0.12 per year and steepness at 0.80. Its survey biomass-index calculation accounts for within-year survey timing, but the numerical timing values were not recovered from the reviewed model tables. No timing values are imputed.

Table 1 of the SCAA report gives selected estimates, with Hessian-based CVs in parentheses:

| Quantity | 1975 | 2016 | 2021 |
|---|---:|---:|---:|
| Spawning biomass, Bsp (kt) | 545 (0.18) | 85 (0.19) | 91 (0.19) |
| Exploitable biomass, B5-9 (kt) | 153 (0.24) | 86 (0.09) | 62 (0.13) |

The point estimates and years are stored as outputs. The source reports CVs, not standard errors or intervals; the CVs are preserved in row notes and are not placed in `se`. The report's other annual N-at-age, F-at-age, recruitment, and biomass trajectories are shown in figures rather than numeric tables and have not been digitized. The SCAA output record therefore remains partial.

## 2023 state-space model update

`dfo_greenland_halibut_2_3klmno_2023_ssm` records the 2023 SSM 3NO base case, also updated through 2021 for MSE work. It contains:

- Landings in kilotonnes, catch numbers-at-age in thousands of fish, and catch weights-at-age in kilograms per fish for 1975-2021; catch and weight ages are 1-10+.
- Mean survey numbers per tow at ages 0-10+ for Canada Autumn 2J3K, Canada Autumn 3LNO, Canada Spring 3LNO, EU 3M 0-1400 m, and EU-Spain 3NO.
- Fixed M of 0.12 per year, with F fixed at zero for ages 1-2 and estimated for ages 3-10+.
- Annual age-1 recruitment, exploitable biomass for ages 5-9, and mean F for ages 5-9.

The SSM report prints values for Canada Autumn 2J3K ages 8+ in 2018, 2019, and 2021, but says they were excluded from the SSM fit because deep strata were not covered. Those nine cells are blank in the imported SSM values, and their printed values are retained in notes. This differs from the SCAA event, which includes the values. The SSM output tables do not provide numeric SSB, N-at-age, F-at-age, or uncertainty series; graphical estimates are not digitized. The record remains partial.

The SCAA and SSM events are separate fits with distinct input series, assumptions and output coverage. Inputs are not copied between their assessment IDs.

## Sources and local cache

- [2026 NAFO Scientific Council report, SCS Doc. 26/12](https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf)
- [2023 SCAA assessment update, SCR Doc. 23/008REV](https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-008REV.pdf)
- [2023 supporting input data, SCR Doc. 23/007](https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-007.pdf)
- [2023 SSM update, SCR Doc. 23/014](https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-014.pdf)
- [2017 SCAA framework, SCR Doc. 17/002](https://www.nafo.int/Portals/0/PDFs/sc/2017/scr17-002.pdf)
- [2024 management procedure, CEM Doc. 24-01REV](https://www.nafo.int/Portals/0/PDFs/com/2024/comdoc24-01REV.pdf)

The local, gitignored cache is `source_cache/discovery_dfo_greenland_halibut_2_3klmno_2025/`. Source URLs, retrieval dates and SHA-256 checksums are recorded in `provenance/discovery_dfo_greenland_halibut_2_3klmno_2025/sources.csv`.
