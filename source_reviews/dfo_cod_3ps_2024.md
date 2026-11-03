# DFO 3Ps Atlantic cod, 2024 assessment

## Assessment identity and source selection

The metadata-only Charbonneau–Keith record `DFO_morhua_3PS` is DFO Atlantic cod in NAFO Subdivision 3Ps. It is represented as `ck_dfo_morhua_3ps`; the assessment import updates this stock identity to “Atlantic cod” and authority code `3Ps`.

The production assessment used the HYBRID model under the framework adopted in 2019. The current detailed report is DFO Research Document 2026/051, which documents the 2024 assessment. Its Appendix A supplies the model input tables. The associated DFO Science Advisory Report 2025/007 summarizes the same 2024 assessment and provides annual aggregate estimates for 2020–2024 in Table 1. DFO’s assessment-history field identifies 2023 as the previous “last full assessment”; the 2024 record is the latest annual assessment documented here. The later DFO Research Document 2026/047 updates catch and survey information through 2025; it is retained in the local cache as a separate follow-up and none of its values are imported into this 2024 assessment.

The local ignored cache is `source_cache/ck_dfo_morhua_3ps/assessment_2024/`. It contains the detailed 2026/051 report (SHA-256 `759b26fe500dca205b669cf9475707d0b67604ca3c0cf00fb98aae0328d23728`), the 2025/007 summary, the 2026/047 later update (SHA-256 `78fedd1cbc0593013a5066d18878594f73204897084ecc9abe020d42986bb965`), and earlier assessment/data-review documents. `accessible_sources_manifest.csv` records retrieval dates, source URLs, roles and checksums. The 2024/015 document is a comparison-model development report for SAM, not the applied HYBRID run.

## Newer 2025 annual assessment (summary-only)

DFO's 2025 assessment peer review was held November 4–7, 2025, and its Science Advisory Report 2026/004 was published in January 2026. The report identifies 2024 as the last full assessment, describes the 2025 assessment as a state-space age-based HYBRID model, and notes that a complementary SAM fit was examined as a consistency check. It also reports three material data updates: stock weights were revised to include both inshore and offshore strata; 2023 catch-at-age was corrected; and Sentinel index standardization used additional data.

Table 1 reports aggregate SSB, age-2 recruitment, and mean M and F for ages 5–8 for 2021–2025, plus projected 2026 SSB. These outputs are recorded under the separate `dfo_cod_3ps_2025` assessment ID. The supporting Research Document 2026/047 provides corrected 2023 and 2024 catch-at-age tables and updated catch and survey information through 2025. The two published catch-at-age tables are imported at their exact ages and original fish-count scale. Other supporting tables include commercial weights-at-age and recent survey summaries, but they do not recover the complete annual input matrices and model controls used by HYBRID. Numerical N/F/M-at-age output surfaces are not tabulated. it does not replace the 2024 detailed comparison record. The 2024 inputs and 2025 outputs are kept in separate assessment records.

The official 2026/004 PDF is cached under `source_cache/ck_dfo_morhua_3ps/assessment_2025/` with retrieval date and SHA-256 in its manifest. The Publications Canada download URL currently returns an archived-page HTML response; the cached PDF uses DFO's direct library URL.
## Official model and inputs

The applied model spans calendar years 1959–2024 and ages 2–14+, with age 2 as recruitment. It fits annual landings with a censored likelihood and the age composition using continuation-ratio logits. Fishing mortality follows an age-correlated multivariate random walk for ages 3+, with age 2 separate and a break at the 1993 moratorium. Natural mortality varies with a scaled fish-condition index, with condition-response coefficients shared across ages 2–5 and 6+; the mean of 1978–1982 supplies the index values for 1959–1977.

The import script `scripts/database/073_import_dfo_cod_3ps_2024.R` transcribes Appendix A tables A-1 through A-11 into `inputs.csv`:

- Table A-1: calendar-year landings and the lower and upper bounds used by the censored likelihood, in tonnes, 1959–2024. The report says 2024 landings are set to the 2024/25 TAC.
- Table A-2: commercial catch numbers at age, 1959–2023, ages 2–14+. The current table omits the scale label. DFO Research Documents 2023/025 and 2024/002 label the same catch-at-age series in thousands of fish (000s); this confirms the unit convention, but their revised historical values are not copied into the 2024/051 input series.
- Table A-3: the signed annual fish-condition index used to inform M, 1959–2024; 1959–1977 use the 1978–1982 average.
- Tables A-4 through A-8: age-specific indices from the DFO RV spring survey (1983–2024), French ERHAPS (1978–1991), GEAC (1998–2005), Sentinel Gillnet (1995–2023), and Sentinel Line-trawl (1995–2023). Values and zeros are retained at the printed scales. Because the tables do not identify units or multipliers, these are recorded as survey-index scale with units unresolved. The DFO RV table omits 2006 (incomplete survey), 2020 and 2023 (no survey). The report states that zero survey catches are censored in HYBRID.
- Table A-9: maturity proportions at age, 1959–2024, ages 2–14+.
- Table A-10: model stock weights, kg per fish, 1959–2024, ages 2–14+.
- Table A-11: catch weights, kg per fish, 1959–2024; the source prints the last group as age 14 without a plus sign. This is retained as printed and its mapping to the model’s 14+ group is unresolved.

The tables do not give the exact survey timing fractions or all likelihood weights, random-effect covariance settings, priors, and other run controls. Those source gaps keep assumptions and input status `partial`. Do not supply artificial sampling times or treat the summarized index values as exact count units.

## Outputs and comparison limits

The detailed report presents historical trajectories mainly as figures and does not provide a complete numerical table of fitted N-at-age, F-at-age, M-at-age, q, or annual SSB and recruitment. Table 1 of the associated 2025/007 Science Advisory Report provides annual aggregate SSB, age-2 recruitment, and mean F/M for ages 5–8 for 2020–2024. The 2024 SSB/recruitment intervals and grouped F/M intervals are also stated in Research Document 2026/051; earlier grouped F/M confidence limits are not tabulated. A separate 2025 SSB projection is reported under a specified catch. No public applied HYBRID executable, full parameter file or fitted result object was found in the examined DFO materials. The database records the five-year aggregate series and 2025 projection, without digitizing model curves:

- SSB for 2020–2024: 27.6, 26.7, 27.4, 27.7, and 29.9 kt; 2024 95% CI 24–37.3 kt.
- Beginning-of-year 2025 projected SSB under a 1,550 t catch: 33.2 kt (95% CI 26.4–41.8 kt).
- Age-2 recruitment for 2020–2024: 17.4, 20.0, 34.3, 36.8, and 36.6 million fish; 2024 95% CI 14.3–93.3 million.
- Mean F for ages 5–8 in 2020–2024: 0.04, 0.02, 0.03, 0.03, and 0.04 per year; 2024 95% CI 0.03–0.06.
- Mean M for ages 5–8 in 2020–2024: 0.37, 0.35, 0.35, 0.35, and 0.32 per year; 2024 95% CI 0.31–0.34.

Outputs remain `partial`; the five-year aggregate table improves recent comparison, but the figures are not digitized as exact time series. Total abundance cannot be derived because numerical N-at-age is unavailable. Age-specific N/F/M and annual outputs before 2020 cannot be compared until additional HYBRID output data are recovered.
