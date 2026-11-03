# Greenland halibut, NAFO Subarea 2 + Divisions 3KLMNO

## Current unit and advice

The stock is the transboundary Greenland halibut (*Reinhardtius hippoglossoides*) unit in NAFO Subarea 2 and Divisions 3KLMNO. It is distinct from DFO's Gulf of St. Lawrence 4RST stock and from Greenland Subarea 1 units.

The latest official update found is the 2026 NAFO Scientific Council report. It applies the management procedure adopted in 2024 to set the 2027 total allowable catch at 14,351 t. All five survey series were available for the 2026 calculation, and the Scientific Council reported that exceptional circumstances were not occurring. This is a survey-based annual management procedure; no age-structured population model was refit for this advice. The 2026 MP table reports mean-weight-per-tow values from 2011–2025 and the final TAC, but no annual N-at-age, F-at-age, SSB, or recruitment estimates.

The previous 2025 advice used four survey series because the EU-Spain 3L series was excluded under the exceptional-circumstances protocol. It is retained in the local source cache as prior-year context and is superseded by the 2026 update.

## Detailed age-structured model source

The latest detailed age-structured source located is the 2023 state-space model update (SSM), fitted through 2021 and prepared to update operating-model outputs for the 2023 management-strategy evaluation. It was not the model used to calculate the 2026 TAC. The report presents three survey variants; the import records only the 3NO base case and does not combine sensitivity inputs with it.

The base-case source tables report:

- Commercial catch numbers-at-age, ages 1–10+, in thousands of fish for 1975–2021.
- Landings in kilotonnes for 1975–2021, the years used by the SSM.
- Commercial catch weights-at-age in kg per fish, ages 1–10+, 1975–2021.
- Mean survey numbers per tow at ages 0–10+, with survey-specific years, for Canada Autumn 2J3K, Canada Autumn 3LNO, Canada Spring 3LNO, EU 3M 0–1400 m, and EU-Spain 3NO. The age-10 column is a 10+ group. Blank cells remain missing and reported zeros remain zero. Although Table 6 prints Canada Autumn 2J3K indices for ages 8+ in 2018, 2019, and 2021, the report says those observations were excluded from the fitted SSM because deep strata were not covered; the database therefore leaves those model-input cells missing and records the printed values in their notes.
- Fixed natural mortality of 0.12 per year. F is fixed at zero for ages 1–2 and estimated for ages 3–10+.
- Age-1 recruitment, exploitable biomass ages 5–9, and mean F ages 5–9 as annual output tables for the 3NO base case.

The SSM describes adjusting survey observations using the midpoint of each survey-year as a fraction of the year, but the numerical survey-specific timing values are not tabulated. No maturity-at-age or stock/spawning-weight surface was recovered for this SSM event. Its numerical N-at-age, F-at-age, and SSB surfaces appear only in figures or are unavailable in the reviewed sources; they are not digitized. The annual SSM output tables do not provide numerical uncertainty for the imported point estimates. Figure 1 shows 95% confidence intervals for recruitment, numbers, exploitable biomass, and average F, but these intervals are graphical and are not entered as numerical confidence limits.

The companion 2023 SCAA update is a separate operating-model assessment with its own survey series and maturity inputs. Its values are not mixed into the SSM records. The 2026 MP report and the 2023 SSM update are separate assessment events and have separate input and output records.

## Database records

The canonical stock is `dfo_greenland_halibut_2_3klmno`, with two partial events:

- `dfo_greenland_halibut_2_3klmno_2026_mp`: current and applied annual MP update; survey indices through 2025 and 2027 TAC advice.
- `dfo_greenland_halibut_2_3klmno_2023_ssm`: non-current, non-applied SSM update for MSE; catch, catch weights, survey age indices, fixed M, and selected annual outputs through 2021.

The current MP input values are stored on the source's mean-weight-per-tow scale. The 2023 SSM report identifies this index family in kg per tow; no additional scaling is applied. Missing survey years are omitted from the annual MP input rows. No uncertainty is created for outputs where the source provides none.

This source record can support translation work with documented approximations, but it is not a direct reproduction of current 2026 advice. Translation would use the 2023 SSM inputs and outputs as a historical age-structured case, and would have to address the missing timing values, maturity/stock weights, and annual N/F/SSB surfaces. The current MP TAC should not be treated as an age-structured fit output.

## Sources

- [2026 NAFO Scientific Council Report, SCS Doc. 26/12](https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf)
- [2025 NAFO Scientific Council Report, SCS Doc. 25/13](https://www.nafo.int/Portals/0/PDFs/sc/2025/scs25-13.pdf)
- [2024 management procedure, NAFO CEM Doc. 24-01, revised](https://www.nafo.int/Portals/0/PDFs/com/2024/comdoc24-01REV.pdf)
- [2023 updated SSM, NAFO SCR Doc. 23/014](https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-014.pdf)
- [2023 updated SCAA base case, NAFO SCR Doc. 23/008REV](https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-008REV.pdf)

Retrieved PDFs, source URLs, retrieval dates, and SHA-256 checksums are stored in the gitignored local cache `source_cache/discovery_dfo_greenland_halibut_2_3klmno_2025/`.
