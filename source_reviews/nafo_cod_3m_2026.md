# NAFO cod in Division 3M, 2026 assessment

## Assessment and sources

The selected record is the official 2026 production assessment of cod in NAFO Division 3M, fitted through 2025 and used for advice for 2027. The assessment is a Bayesian sequential catch-at-age model with ages 1–8+, fitted in JAGS from R through `rjags`. The 2018 benchmark defines the continuing model framework. No public fitted object or production JAGS code was located.

Primary sources:

- NAFO SCR 2026/023, assessment tables and model description: <https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-023.pdf>
- NAFO SCR 2026/003, Flemish Cap survey report: <https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-003.pdf>
- NAFO SCR 2018/030, 3M cod benchmark model: <https://www.nafo.int/Portals/0/PDFs/sc/2018/scr18-030.pdf>
- NAFO SCR 2018/001, benchmark input data: <https://www.nafo.int/Portals/0/PDFs/sc/2018/scr18-001.pdf>
- NAFO SCR 2018/003, natural-mortality analysis: <https://www.nafo.int/Portals/0/PDFs/sc/2018/scr18-003.pdf>
- NAFO SCR 2025/032, previous assessment, used only to check run continuity: <https://www.nafo.int/Portals/0/PDFs/sc/2025/scr25-032.pdf>
- Official advice for 2027: <https://www.nafo.int/Portals/0/PDFs/Advice/2026/cod3m.pdf>

Cached source URLs, retrieval dates and SHA-256 checksums are in `provenance/nafo_cod_3m_2026/manifest.csv`. The cached PDFs are local-only under the ignored `source_cache/` directory.

## Inputs and assumptions

Table 1A reports estimated total commercial catch in tonnes for 1988–2025. The imported series uses its `Estimated` column (STACFIS estimates), not the separately reported nominal statistical total. Table 2 reports catch numbers-at-age in thousands of fish for 1988–2001 and 2006–2025, ages 1–8+. The assessment sets the age-1 catch input to zero in every year and fixes F at age 1 to zero. Published zeros for catch ages 2+ are treated as missing in the fitted likelihood. No catch-at-age observations are reported for 2002–2005.

Table 3 provides catch weight-at-age, and Table 5 provides stock weight-at-age, both in kg/fish for ages 1–8+ and years 1988–2025. The report states that 2025 catch weights use the EU survey length-weight relationship. Table 6 gives annual maturity ogives. The report documents the source years and how the missing years were filled or mixed; in 2023–2025 the 2020–2022 average is used. The annual a50 medians are also stored as reported biology summaries; their numerical uncertainty is not tabulated.

Table 4 reports EU Flemish Cap bottom-trawl abundance indices at source ages 1–19, in thousands of fish. Both the published source-age series and the assessment's age-1–8+ series are retained. For the model series, ages 8–19 are summed into 8+; zero index values are represented as missing, consistent with the report. The source table has a blank age-7 cell in 2005 and a blank age-15 cell in 2018. The 2018 blank is within the 8+ group, so the exact 2018 model-group index cannot be reconstructed. These cells are left missing; the published total abundance and total biomass are not used to infer them. Table 4 also presents total survey abundance and biomass summaries; they are not imported as separate likelihood observations because the assessment fits the age-specific survey indices.

The production assessment's survey-timing interval is `alpha.EU = 0.50` to `beta.EU = 0.58`, which Annex I associates with July. The 2025 survey report dates the survey from 8 July to 4 August. The database keeps the interval in assumptions and does not replace it with a single within-year sampling fraction.

Natural mortality is age-dependent, constant across years, and estimated under lognormal priors. Table 10 provides prior and posterior medians for ages 1–8+. The prior medians are stored as inputs and posterior medians as outputs. The reported prior CV is 0.15. The report also documents priors and structures for recruitment, first-year abundance, fishing mortality, catch error, survey error and age-specific catchability; these are stored in `assumptions.csv`.

## Outputs and completeness

Tables 7–10 provide posterior medians for total biomass, SSB, recruitment, Fbar (ages 3–5), F-at-age, N-at-age, total abundance, number mature and M-at-age. Table 7 reports 10th and 90th posterior percentiles, so its intervals are central 80%, not 95%. Recruitment is the age-1 abundance in thousands of fish; although Table 7's caption says “tons,” its values match Table 9 age-1 abundance and the report's recruitment definition. The remaining age-specific output tables give medians without numeric uncertainty limits.

The record is **partial** for inputs because the source tables do not resolve the 2018 8+ survey value. Assumptions are **partial** because the published model description does not include a recoverable production-run code or fitted object. Outputs are **partial** because the report does not tabulate uncertainty for age-specific N, F or M. No values were inferred from plotted curves or aggregate survey totals.

This is source curation only. No tinyAM settings, fits or comparison results are represented here.
