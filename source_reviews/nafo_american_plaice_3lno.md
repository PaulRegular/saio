# NAFO American plaice in Divisions 3LNO

## Current monitoring and assessment history

The latest advice, published in June 2026 for 2027 and beyond, is based on interim monitoring; the Scientific Council did not undertake a full assessment in 2026. It reported no change in stock status, continued its recommendation of no directed fishing, and advised minimizing unavoidable bycatch. A full benchmark assessment is planned for June 2028. The current assessment record therefore represents the 2026 monitoring, not a fitted population model.

The 2021 NAFO ADAPT assessment is retained as a separate historical full assessment for the same 3LNO stock unit. No DFO assessment record for this NAFO-managed unit was identified. The 2021 report concluded that the model was useful for tracking stock trends but that its absolute population estimates were unreliable because of poor fit, residual patterns, retrospective behaviour and instability.

Cached sources, retrieval dates and checksums are in `provenance/nafo_american_plaice_3lno/manifest.csv`. Cached PDFs are local-only under ignored `source_cache/`.

## 2026 interim-monitoring data

The current monitoring record preserves the report's rounded 2017–2023 catch totals in thousands of tonnes. For 2024 and 2025, the report also gives STACFIS catches of 376 t and 574 t in the text, while the table rounds them to 0.4 and 0.6 thousand tonnes. The database uses the more precise text values, converted to 0.376 and 0.574 thousand tonnes, and records that conversion. These totals are not expanded into catch-at-age.

The 2026 Spanish spring-survey report for Division 3NO provides total biomass and abundance indices for 2021–2025 with their reported standard deviations. These are aggregate survey indicators, not age-specific XSA observations. The 2026 Spanish Division 3L report provides total biomass estimates for 2018, 2019 and 2023–2025. Only the total point estimates are imported because its Table 20 overprints a second table and does not support reliable separation of the reported SD row. No SD is inferred. The Canadian survey report was reviewed, but no new numeric age-specific index series was recoverable for this import. No surveys were conducted in the 3L Spanish series during 2020–2022.

The decimal year values in the 2021 assessment tables encode survey season (spring `.5`, autumn `.9`); they are not exact within-year sampling fractions. The 2026 monitoring observations therefore have season labels but no `sampling_time` value.

## Detailed 2021 ADAPT inputs

The 2021 assessment report tables provide commercial catch numbers-at-age for 1960–2020 at ages 5–14 and 15+, beginning-of-year stock weights for 1960–2021 at ages 5–14 and 15+, and annual maturity proportions for 1960–2025 at the same ages. Catch-at-age source methods changed over time: the report identifies the effort method for 2014, DCRs for 2015–2016 and CDAG for 2017–2020.

Three age-specific mean-number-per-tow survey series used in the assessment are retained separately: Canadian autumn RV (1990–2020, excluding 2004 and 2014), Canadian spring RV (1985–2019, excluding 2006, 2015 and 2017), and EU-Spain spring survey in Division 3NO (1998–2019). Survey ages are 5–14 and have no plus group. The report's tables do not provide one exact sampling-time fraction.

The assessment fixed M at 0.2 per year except 0.53 for all modeled ages during 1989–1996. This fixed surface is stored as year- and age-specific inputs because it is part of the VPA's mortality assumption, not an estimated M output.

## Outputs and completeness

The 2021 report's Table 29 reports ADAPT terminal survivor parameter estimates for ages 6–15 in 2021 with standard errors. Those are pre-bias-adjustment survivor parameters; their standard errors are not standard errors for the bias-adjusted historical N-at-age series. The accessible report does not provide numerical annual SSB, F-at-age or population trajectories in tables, so these are not digitized from figures.

For the 2021 full assessment, inputs are **complete** for the source streams tabulated in the report; assumptions and outputs are **partial** because the production model files and complete numerical fitted outputs are unavailable. For 2026, the current interim-monitoring inputs are **partial**, assumptions are **partial**, and numerical model outputs are **not applicable** because no full model was run. The qualitative no-directed-fishing recommendation is recorded as text; it is not converted into a numeric zero catch or TAC.

This review records source facts and gaps only; it contains no downstream model settings or comparison results.
