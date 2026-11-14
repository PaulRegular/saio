# Cod in NAFO Division 3M — 2026 assessment

## Stock and assessment

NAFO cod.3M is the Atlantic cod stock on Flemish Cap. The 2026 production assessment is the latest detailed assessment used for advice for 2027. It is a Bayesian statistical catch-at-age (SCAA) model fitted in JAGS, with data through 2025. The stock record is distinct from nearby Canadian cod units.

The 2018 benchmark established the continuing SCAA formulation. The current report documents the production run and its data; the public sources reviewed do not include the fitted JAGS object or the production-run code version.

## Inputs recovered

The database captures the source tables from SCR 26/023:

- Table 1A: annual estimated commercial catch for 1988–2025, in tonnes. The imported series uses the STACFIS estimated catch column, not nominal catch.
- Table 2: commercial catch numbers-at-age for ages 1–8+, in thousands of fish, for 1988–2001 and 2006–2025. No catch-at-age is reported for 2002–2005 because commercial length distributions were unavailable. The assessment sets age-1 catch numbers to zero and fixes age-1 fishing mortality at zero. Published zero catch observations at ages 2+ are treated as missing by the fitted likelihood.
- Table 4: Flemish Cap survey abundance-at-age indices for source ages 1–19 and the assessment's grouped ages 1–8+, in thousands of fish. Published source zeros are retained; the assessment treats zero indices as missing. The source table has a blank age-7 value in 2005 and a blank age-15 value in 2018. Because age 15 belongs to the grouped 8+ class, the exact 2018 model-age-8 index cannot be recovered. Neither missing value is inferred from total survey abundance or biomass.
- Tables 3 and 5: catch and stock mean weight-at-age for ages 1–8+ across 1988–2025, in kg per fish. The report says that 2025 catch weights use the EU survey length–weight relationship; stock weights use the EU survey relationship.
- Table 6: maturity-at-age for ages 1–8+. Where yearly ogives are unavailable, values are interpolated between adjacent available years. The 2023–2025 values use the 2020–2022 average. The reported age at 50% maturity is stored separately as a biology summary.
- Table 10 and Annex I: age-specific natural-mortality prior medians and model assumptions. M is age-dependent, estimated, and constant across years; its prior CV is 0.15. Annex I also gives the catch and survey observation variation, recruitment and first-year abundance priors, and the annual fishing-mortality and age-specific selectivity processes.

Annex I specifies EU survey-timing parameters `alpha.EU = 0.50` and `beta.EU = 0.58`. The 2025 Flemish Cap survey report dates that survey from 8 July to 4 August. The database retains the timing parameters and does not replace them with a single fixed within-year fraction.

## Outputs recovered

Tables 7–10 provide annual total biomass, spawning biomass, recruitment, Fbar for ages 3–5, fishing mortality at age, abundance at age, total abundance, number mature, and natural mortality at age. The annual aggregate output series are recorded from those tables.

Table 7 reports the 10th and 90th posterior percentiles, so its intervals are central 80%, not 95%. The recruitment series is age-1 abundance in thousands of fish; although the table caption says “tons,” the values agree with age-1 abundance in Table 9 and with the report's recruitment definition. The age-specific output tables do not provide numeric uncertainty bounds, so those bounds remain blank.

## Completeness and source trail

Input, assumption, and output completeness remain marked partial. The input record preserves the four-year catch-at-age gap, the unavailable 2018 grouped survey index, and other missing survey cells. The output record preserves the intervals reported for aggregate quantities without inferring age-specific uncertainty. The production JAGS code and fitted object were not located in the public sources reviewed.

The assessment report, official 2027 advice, prior assessment, benchmark documents, natural-mortality report, and supporting 2025 survey report are cached under `source_cache/nafo_cod_3m_2026/`. Retrieval dates, source URLs, filenames, and SHA-256 checksums are listed in `provenance/nafo_cod_3m_2026/manifest.csv`.

- [NAFO SCR 26/023: Assessment of the Cod Stock in NAFO Division 3M](https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-023.pdf), input tables, model methods, outputs, and Annex I.
- [NAFO SCR 26/003: Results from the 2025 Flemish Cap bottom-trawl survey](https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-003.pdf), survey coverage and timing.
- [NAFO SCR 18/030: 3M cod benchmark model](https://www.nafo.int/Portals/0/PDFs/sc/2018/scr18-030.pdf), model formulation.
- [NAFO 2026 scientific advice for cod in Division 3M](https://www.nafo.int/Portals/0/PDFs/Advice/2026/cod3m.pdf).