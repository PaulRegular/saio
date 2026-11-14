# Bay of Biscay anchovy (ICES `ane.27.8`)

Review date: 2026-11-08

## Stock unit and assessment

The assessment unit is anchovy (*Engraulis encrasicolus*) in ICES Subarea 8 (Bay of Biscay). It is distinct from the two Iberian anchovy units in Division 9.a. The 2025 WGHANSA Stock Synthesis run (version 3.30.22.beta; ICES Standard Graphs key 21265) is the current detailed production assessment used for 2026 advice (advice record 4005).

This unit is selected in `discovery/selected_batch_19_2026.csv` for source curation. The partial import is defined by `scripts/database/611_import_ices_bay_biscay_anchovy_2025.R`; imported values remain traceable to the official report tables and retain their reported scales.

## Source evidence

| Component | Official evidence | Coverage and remaining work |
|---|---|---|
| Commercial catch | WGHANSA 2025 Table 2.5.1.1 reports semester catch biomass; Table 2.2.3.2 gives catch numbers-at-age by semester. Table 2.5.2.1 summarizes the fitted model's catch-at-age coverage. | Imported catch biomass by semester, including provisional 2025 values, and tabulated catch numbers-at-age at ages 0-5 for 1987-2024, in thousands of fish. The model-configuration table says the 2025 run included catch-at-age through 2025 except for the second semester, but the published numerical catch-at-age table ends in 2024. The 2025 first-semester age data are therefore unrecovered; no values are inferred. |
| BIOMAN spring DEPM survey | Table 2.5.1.1 gives annual BIOMAN SSB/CV inputs. Table 2.5.2.1 is the model-configuration table and identifies the BIOMAN age-series coverage; it does not give the annual age observations. Table 2.3.1.4 gives the 2025 estimates, CVs, and weights. | Imported annual SSB/CV values from Table 2.5.1.1 and the 2025 numbers-at-age (4,951, 3,430, and 266 million), age-specific CVs (0.2133, 0.1172, and 0.1798), and weights (13.7, 25.1, and 28.5 g per fish) from Table 2.3.1.4. The age estimates sum to the reported 8,647 million. Table 2.5.2.1 lists model coverage for ages 1, 2, and 3+ in 1987-2025, with missing years 1993, 1996, 1999, and 2000; historical numeric values are not tabulated in the reviewed report and remain unrecovered. The assessment configuration uses thousands for population numbers, so downstream conversion from the reported millions must be documented. |
| PELGAS spring acoustic survey | Table 2.5.1.1 gives annual aggregate SSB/CV inputs. Table 2.5.2.1 is the model-configuration table and identifies age-series coverage; Figure 2.3.2.4 shows the historical age series. | Imported aggregate SSB/CV values from Table 2.5.1.1 for 1989-2025, with the source's missing years retained. Table 2.5.2.1 lists numbers-at-age for ages 1, 2, and 3+ in 2000-2025 except 2020, but contains no numerical observations. Figure 2.3.2.4 is graphical, so historical age-specific values remain unrecovered and were not digitized. |
| JUVENA autumn acoustic survey | Table 2.5.1.1 directly reports the fitted age-0 abundance input (`Juvena N0`) and its CV for 2003-2025. Table 2.3.3.1 reports juvenile biomass separately. | Imported the directly reported N0/CV series without rescaling. The table does not state the N0 unit, although the model configuration describes numbers in thousands; the source-to-model unit mapping remains unresolved. The 2025 value is 386,953,330.0 with CV 0.25. The separately reported juvenile biomass was not substituted for N0. |
| Aggregate assessment inputs | WGHANSA 2025 Table 2.5.1.1 lists annual PELGAS SSB/CV, BIOMAN SSB/CV, JUVENA N0/CV, and catch biomass by semester. | These are direct assessment-input values. PELGAS SSB spans 1989-2025, BIOMAN SSB 1987-2025, JUVENA N0 2003-2025, and catch biomass 1987-2025. In 2025 the input table reports PELGAS SSB 153,374.13 t (CV 0.09), BIOMAN SSB 157,246.81 t (CV 0.11), JUVENA N0 386,953,330.0 (CV 0.25), and catch biomass 22,744 t / 7,061 t by semester. Preserve blank survey cells as missing; 2025 catch is provisional. |
| Catch weights | WGHANSA 2025 Table 2.2.4.1 reports mean catch weight-at-age by semester. | Imported available age-specific catch weights in grams per fish for 1987-2024. The table has no values for 2007-2009; these gaps remain missing. Catch weights are kept separate from stock weights. |
| Stock weights | The report and stock annex describe spawning-time weight-at-age from BIOMAN, with linear interpolation for missing years. | Imported only the 2025 BIOMAN weights-at-age (ages 1, 2, and 3+) in grams per fish from Table 2.3.1.4. Historical values and the interpolated assessment surface remain unrecovered; catch weights are not substituted. |
| Maturity and natural mortality | WGHANSA 2025 sections 2.4.1-2.4.2. | Maturity is 0 at age 0 and 1 at ages 1, 2, and 3+. M-at-age is 2.17, 0.80, 1.20, and 2.26 per year for ages 0, 1, 2, and 3+, respectively. These are fixed in the 2025 run; age-3+ M had been estimated at the 2024 benchmark and was retained. |
| Model timing | WGHANSA 2025 Table 2.5.2.1 and the stock annex. | Recorded two seasons (January-June and July-December), spawning on 15 May, and recruitment settlement on 1 July. BIOMAN/PELGAS are spring surveys and JUVENA is an autumn survey, but exact model sampling fractions remain unresolved. |
| Reported outputs | WGHANSA 2025 Tables 2.5.3.1-2.5.3.4; ICES Standard Graphs source data. | Imported 16 non-deviation Stock Synthesis parameter estimates and their reported `Parm_StDev` values from Table 2.5.3.1; these SEs remain on the native parameter scales and the table gives no confidence intervals. Imported annual SSB, recruitment, and apical F with reported 95% intervals for 1987-2025. Imported F-at-age by semester and beginning-of-year N-at-age for 1987-2024, without age-specific intervals. Total abundance is derived by summing the four reported N groups; its uncertainty is unavailable. Fixed M is an input, not an estimated output. |

## Source discrepancies and blockers

- The WGHANSA narrative on BIOMAN 2025 reports 145,608 t, while Tables 2.3.1.3, 2.3.1.4, and the model input table (2.5.1.1) report/use 157,247 t. Preserve the discrepancy; for the fitted input series, the model input table is the direct evidence for 157,246.81 t.
- Table 2.5.2.1 is a model-configuration table: it documents the age-series coverage and model units, but does not provide annual numerical survey-age observations. Historical BIOMAN and PELGAS age series are shown graphically (including Figures 2.3.1.9, 2.3.2.4, and 2.5.1.3) and remain unimported; no values have been digitized or reconstructed from those figures. BIOMAN 2025 age-specific numbers and CVs are tabulated in WGHANSA Table 2.3.1.4 and WGACEGG 2026 Table 4.5.
- The model-configuration table describes 2025 catch-at-age coverage, but the reviewed detailed catch table ends in 2024. The stated 2025 first-semester age input was not recoverable from the public tables reviewed and remains a source gap.
- Table 2.5.1.1 directly provides JUVENA N0 and aggregate PELGAS/BIOMAN survey inputs. The JUVENA N0 table does not state a unit, while the model configuration describes numbers in thousands; the canonical import preserves the reported value without conversion. The original Stock Synthesis data file has not been located to resolve the mapping.
- The importer checks the pinned report hash, coverage, and numeric anchors from the extracted PDF text. It validates the 16 reported parameter rows and retains their standard errors on their original parameter scales. No chart-digitized historical survey-age inputs or 2025 first-semester catch-age values are included. Catch weights have no reported values for 2007-2009; stock weights are imported only for BIOMAN 2025.
- Age-specific F and N outputs are reported for ages 0, 1, 2, and 3, with age 3 representing 3+. The derived total-N series sums those four official groups and has no uncertainty estimate.

## Sources and local cache

- [WGHANSA 2025 report, v3](https://doi.org/10.17895/ices.pub.29335520.v3)
- [2025 stock annex, v2](https://doi.org/10.17895/ices.pub.28053440.v2)
- [WGACEGG 2025 survey report, v3](https://doi.org/10.17895/ices.pub.31353469.v3)
- [ICES 2026 advice record 4005](https://asd.ices.dk/viewAdvice/4005)
- [ICES Standard Graphs source data, key 21265](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265)

The reviewed PDFs and source-data page snapshot are cached in the gitignored `source_cache/ices_ane_27_8/` folder. Retrieval dates, pinned report revisions, byte sizes, and SHA-256 checksums are recorded in `provenance/ices_ane_27_8_sources.csv`.
