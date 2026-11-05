# West Coast South Island hake (HAK 7), 2024 assessment

## Assessment and sources

HAK 7 is the West Coast South Island biological stock of hake. The latest
detailed production assessment located is the 2024 assessment for the
2023-24 fishing year, published as Fisheries New Zealand FAR 2025/03. The
selected base model is R2.4, implemented in Casal2. It uses model years from
October through September, labelled by ending year.

The assessment, the 2023-24/2024 catch-at-age report, and the 2025 Fisheries
Assessment Plenary cross-check are cached under
`source_cache/mpi_hake_hak7_2024/`. Retrieval dates, source URLs and checksums
are in `provenance/mpi_hake_hak7_2024_sources.csv`.

## Records captured

- Table 1 scaled HAK 7 catches are recorded for 1990-2024. The 2024 entry is
  explicitly assumed equal to the 2022-23 catch. The selected report says the
  model history begins before 1990, but its published catch table begins in
  1990; no older values were copied from a previous assessment.
- Table 4 Tangaroa core-strata biomass indices and sampling CVs are recorded
  for 2000, 2012, 2013, 2016, 2018 and 2021. The Kaharoa series is not included
  because the report says it was excluded from the assessment. Exact
  within-year sampling fractions are not reported.
- Table 3 maturity proportions for males and females at ages 1-10+ are
  recorded, retaining the plus group.
- Table 12 base-case MCMC medians and 95% credible intervals for B0, B2024 and
  B2024/B0, and Table 13 catchability for the Tangaroa series are recorded.
- The base-case fixed M, stock-recruitment, age-composition and survey
  assumptions are recorded. Growth and length-weight parameters are preserved
  as assumptions rather than converted to weight-at-age.
- FAR 2026/06 Tables 5 and 9 contain sex-specific estimated 2023-24 catch and
  2024 TAN2407 core/all-strata numbers-at-age with age-specific CVs. These
  observations are stored under a separate `data_update` event because the
  assessment's fitted commercial compositions end in 2022 and its survey
  compositions end in 2021.

The FAR 2025/03 Table 2 growth-parameter row labels are inconsistent: values
for t0 and asymptotic length appear under the wrong labels. The Fisheries
Assessment Plenary 2025, volume 1, confirms the intended mapping. The
assumptions record follows that official cross-check and describes the table
label issue.

## Remaining source gaps

The report describes sex-specific commercial compositions by three spatial
fishery strata and sex-specific Tangaroa core-strata compositions. Their
numerical proportions are plotted rather than tabulated. The published catch
table also omits the model's pre-1990 catch history. No direct weight-at-age
matrix or annual numerical N-at-age, F-at-age or recruitment series was found.
The current assessment record is partial for assumptions, inputs and outputs.

The available numerical material supports later model translation, but the
missing composition vectors and early catch history remain limitations. No
tinyAM translation is included in this source review.
