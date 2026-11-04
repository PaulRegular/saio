# Southern horse mackerel in ICES Subarea 9.a

## Assessment selected

The latest detailed assessment recovered is the 2024 WGHANSA assessment for 1992–2023, using Stock Synthesis 3.30.22. The 2026 ICES Stock Assessment Graphs page contains a later summary series, which is kept as a separate summary-only event rather than mixed with the 2024 assessment. The 2024 event remains the current detailed record.

- [WGHANSA 2024 report](https://doi.org/10.17895/ices.pub.26003356.v3), especially Tables 5.2.4.1, 5.2.5.1, 5.3.1.2, 5.3.2.1, 5.4.1.1, and 5.4.1.2.
- [WKBHMB 2024 benchmark report](https://doi.org/10.17895/ices.pub.25002482.v2), which informs maturity, natural mortality, and assessment methods.
- [ICES 2026 SAG source table, key 23760](https://sg.ices.dk/ViewSourceData.aspx?key=23760), for the separate 2026 summary-only record.
- The cited [2024 assessment TAF repository](https://github.com/ices-taf/2024_hom.27.9a_assessment) did not provide a recoverable model bundle when checked. No native model object or CPUE input series was imported.

The PDFs and SAG source page are cached locally under source_cache/ck_ices_wghansa_trachurus_sp9a/. source_manifest.csv records retrieval dates, URLs, SHA-256 checksums, and the unavailable model-repository attempt.

## Recovered 2024 inputs

The assessment is annual, one-area, and sexes-combined, with ages 0–10 and an age-11 plus group.

| Input | Coverage | Unit and treatment |
|---|---|---|
| Combined Portuguese-Spanish catch-at-age | 1992–2023, ages 0–11+ | Thousands of fish; transcribed from Table 5.2.4.1 |
| Total catch biomass | 1992–2023 | Tonnes; input-catch totals from Table 5.4.1.2 |
| Catch and stock weight-at-age | 1992–2023, ages 0–11+ | kg per fish; stock weights are stated to equal catch weights |
| Portuguese-Spanish IBTS abundance-at-age | 1992–2023, ages 0–11+ | Number per hour; combined index unavailable in 2012, 2019, and 2020. Age 0 is shown but excluded from the assessment input. |
| BIOMAN DEPM SSB | 2013, 2016, 2019, 2022 | Thousand tonnes; reported CVs 0.371, 0.426, 0.482, and 0.380. SSB was not estimated in 2010. |
| Natural mortality | Ages 0–11+ | Fixed age vector from the Gislason method; age 11 is the plus group. |
| Maturity | Ages 0–11+ | Time-invariant female ogive used for the combined-sex model. |

The model settings report catch CV 0.05, IBTS CV 0.30, DEPM CV 0.40, and CPUE CV 0.14. Catch and IBTS age data use Dirichlet-multinomial weighting with age-reading uncertainty. Recruitment follows Beverton–Holt with sigmaR 0.74 and input steepness 0.8; the initial population uses an equilibrium age structure derived from a 30,000-tonne equilibrium catch. Fishery selectivity is double-normal with two time-varying parameters. Survey selectivity is fixed and dome-shaped.

The source also uses IBTS aggregate biomass and standardized commercial CPUE in biomass. Their numeric series were not tabulated in the detailed report; the CPUE is shown only as a figure. They are therefore recorded as known source-model streams but are not reconstructed or added as observations.

## Recovered outputs and limits

Table 5.4.1.2 reports annual SSB, recruitment, F(1–10), FApical, CVs for SSB/recruitment/F, and input catch. The database retains these summaries. The SE columns are calculated as the point estimate multiplied by the reported CV; the report table does not give confidence intervals. Age-specific N and F are not numerically available, so no age-specific outputs or total abundance are inferred.

The 2026 SAG series supplies recruitment (thousands, age 0), stock size (tonnes), and F (ages 1–10), with low/high values. It extends through 2026; the 2026 row is a forecast. The source table does not label low/high intervals with a confidence level, so the database preserves those bounds without calling them 95% intervals. Aggregate catch is retained, but the 2026 model assumptions, age inputs, native fitted object, and age-specific population outputs remain unavailable.

Both assessment events are marked partial. The database preserves official source values and their reported limits.
