# Sub-Antarctic hake (HAK 1), 2024 assessment

## Assessment and sources

The current record is the Sub-Antarctic biological stock within administrative
fishstock HAK 1. It includes the Puysegur Bank treatment and is distinct from
Chatham Rise hake. The latest detailed production assessment located is the
assessment for the 2023-24 fishing year, published as Fisheries New Zealand FAR
2026/02. Its selected base case is R5.0, described as the 2025 base case in
the report, so the database assessment year is 2025. The model-year terminal
state is labelled 2025; model years run September through August.

The assessment, its descriptive input report, the 2023-24/2024 catch-at-age
report, and the 2025 Fisheries Assessment Plenary cross-check are cached under
`source_cache/mpi_hake_hak1_2024/`. Retrieval dates, source URLs and checksums
are in `provenance/mpi_hake_hak1_2024_sources.csv`.

## Records captured

- Table 1 scaled summer and winter catches are recorded for model years
  1975-2025. The 2025 entry is the report's assumed catch based on the previous
  five years; earlier values reflect the report's September reassignment and
  catch scaling.
- Table 5 Nov-Dec and Apr-May Tangaroa biomass indices and sampling CVs are
  recorded. The incomplete, scaled 2017 survey and the September series are
  excluded from the assessment input rows, as the report says they were not
  used in the base case. Exact within-year sampling fractions are not reported.
- Table 3 maturity proportions for males and females at ages 1-14 are recorded.
- FAR 2026/06 Tables 3 and 7 provide separate 2023-24 fishery and TAN2413
  survey numbers-at-age with age-specific CVs. These are stored under a
  separate `data_update` event. They are estimated scaled numbers-at-age, not
  the assessment's full numerical age-composition likelihood vectors.
- Table 11 base-case MCMC medians and 95% credible intervals for B0, B2025 and
  B2025/B0, and Table 12 catchability for both survey series are recorded.
- The source-reported natural mortality, growth, length-weight, recruitment,
  sex-ratio and spawning assumptions are recorded separately. No weight-at-age
  surface is calculated from the growth and length-weight parameters.

## Remaining source gaps

The assessment describes sex-specific multinomial fishery and survey age
compositions, but the numerical historical age proportions and effective
sample-size vectors are presented in figures rather than full numerical
tables. The newer catch-at-age report does not replace those likelihood inputs.
No direct weight-at-age matrix or annual numerical N-at-age, F-at-age or
recruitment output series was found. The published assessment record is
therefore partial for assumptions, inputs and outputs. The supplementary age
tables are preserved without implying that they are a complete reconstruction
of the fitted observations.

The numerical source material supports later model translation, but the
missing historical composition vectors remain a key limitation. No tinyAM
translation is included in this source review.
