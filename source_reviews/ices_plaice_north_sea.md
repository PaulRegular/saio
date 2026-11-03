# North Sea plaice source review

## Official assessment

The canonical record represents the official 2026 ICES assessment of North Sea and Skagerrak plaice (`ple.27.420`). Its catch and fitted age-specific estimates end in 2025. The 2026 recruitment and SSB values in the ICES Stock Assessment Graphs are advice forecasts, so they are stored separately from the fitted historical series.

Sources:

- [WGNSSK 2026 report](https://doi.org/10.17895/ices.pub.32676345), plaice chapter, Tables 11.2.4, 11.2.6, 11.2.10–11.2.11, and 11.3.1–11.3.4.
- [ICES Stock Assessment Graphs](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22489), assessment key 22489; the XML defines the reported lower and upper bounds as 95% confidence intervals.
- [WKNSCS benchmark report](https://doi.org/10.17895/ices.pub.21558681), the 2022 benchmark framework adopted for plaice.
- [2026 ICES advice](https://doi.org/10.17895/ices.advice.30932264).

The official report chapter, survey/assessment XML, and other source files used for this record are cached locally under `source_cache/ices_plaice_north_sea_2026/`. The public SAM archive search did not locate a fitted object for the official 2026 run; a public test directory contained data files but no fitted model object, so it was not used as a substitute.

## Inputs and model structure

| Component | Official assessment |
|---|---|
| Years and ages | The model uses ages 1–10+, with age 10 as the plus group. Catch-at-age and stock weight-at-age cover 1957–2025. Recruitment is at age 1. |
| N | SAM uses an age-structured state-space model. Its printed `keyVarLogN` assigns a separate process-variance key to age 1 and a shared key to ages 2–10. |
| F | Fishing mortality is estimated at age. SAM reports AR(1) correlation across F age states and several shared process-variance keys. Fbar is ages 2–6. |
| M | Natural mortality is fixed by age and constant through time: 0.495, 0.394, 0.343, 0.311, 0.292, 0.278, 0.268, 0.260, 0.252, and 0.246 for ages 1–10+. The 2022 benchmark derived these values from weight-dependent natural mortality and averaged them over years. |
| Catch | One aggregate catch-at-age series is reported in thousands of fish and includes landings and discards. The assessment also includes 50% of mature North Sea plaice caught in Division 7.d during the first quarter. |
| Index | Five age-specific series are fitted: BTS-Isis (1985–1995, ages 1–8), BTS-IBTS Q3 (1996–2025, ages 1–10+), SNS1 (1970–1999, ages 1–6), SNS2 (2000–2025, ages 1–6), and IBTS Q1 (2007–2025, ages 1–8+). All SNS2 ages are missing in 2003. |
| Weights and maturity | Annual stock weight-at-age is reported in kg. The selected maturity ogive is time-invariant: 0, 0.5, 0.5, then 1.0 from ages 4–10+. |
| Outputs | SAM N-at-age and F-at-age estimates cover 1957–2025. The ICES graph XML supplies recruitment, SSB, and Fbar with 95% intervals through 2025, plus advice-year recruitment and SSB forecasts for 2026. M is an input assumption rather than a fitted output. |

The report identifies BTS and IBTS Q3 as third-quarter surveys, IBTS Q1 as first quarter, and ICES survey descriptions classify SNS as Q3. The database therefore uses quarter midpoints (0.75 and 0.125) as approximate sampling fractions; exact fractions from the official SAM configuration were not recovered. The report does not state numerical units for the survey indices, so their published values remain on their native scale and their database unit is marked unresolved.

The report prints SAM's parameter-sharing matrices and observation-correlation settings. The q matrix is retained as printed in the assumptions table, but its detailed correspondence to each input row is not fully identified in the report. The listed observation-correlation structures are also preserved without assigning their rows to specific surveys. tinyAM's translation uses separate survey-age catchability and survey-level observation SDs, so this is an approximation rather than an exact reproduction of those SAM settings.

## Database coverage and limits

The record includes direct catch-at-age, annual stock weights, fixed M-at-age, static maturity, all five published survey series, SAM process/configuration details, annual N/F-at-age, and summary recruitment, SSB, and Fbar. Observation predictions, fitted q values, and age-specific uncertainty for N and F are not tabulated in the available sources. The 2026 advice-year recruitment and SSB forecasts are not included in the 1957–2025 fit or common-period comparison. Completeness is marked partial because survey units and exact sampling fractions are unresolved and some fitted SAM settings cannot be mapped to individual series from the printed report.
