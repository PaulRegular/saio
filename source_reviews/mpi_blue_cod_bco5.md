# Blue cod, BCO 5 (Fisheries New Zealand)

Review date: 2026-11-09

## Stock unit and assessment used for advice

BCO 5 (*Parapercis colias*) is the current Fisheries New Zealand management unit. The 2019 age-based assessment fitted independent models to Statistical Areas 025, 027, and 030, then combined their estimates for BCO 5 status. The 2024 assessment attempted separate models for 025, 027+029, and 030. Fisheries Assessment Plenary May 2026 says the 2024 Area 025 assessment was rejected and BCO 5 status remained based on the 2019 assessment. The 2019 run is therefore the assessment used for advice; the 2024 attempt is a separate assessment record and must not be mixed into it.

## Inputs and assumptions reported for the 2019 run

- **Catch and fishery observations:** FAR 2020/14 Appendix 1 reports reconstructed catch histories for commercial line, commercial pot, and recreational fisheries by assessment area. The assessment also fitted commercial and recreational length frequencies, fishery age-frequency samples, and standardized commercial-pot CPUE. These are separate input types: the published age-frequency samples are compositions, not catch numbers-at-age.
- **Catch-age composition:** The report's Appendix 3 Tables 3.5–3.8 give scaled age-frequency samples for commercial catches by area. The assessment used fishery AF as a multinomial observation; the 2019 sample was down-weighted because it covered only three months. Age data for ages 1 and 2 were excluded from the 2019 assessment likelihood.
- **Survey:** Appendix 2 reports pot-survey age samples from 2010, 2014, and 2018. Standardized pot-survey abundance estimates were fitted for Statistical Area 025 only; the report also describes age and length sampling in areas 025 and 030. CPUE indices by areas 025, 027, and 030 cover fishing years 1990–2018 in Table 10.
- **Biology:** The model uses one annual time step, year-round fisheries, age 1–20 with a plus group, and male/female partitions crossed with three growth paths. Natural mortality is fixed at 0.17 per year. A shared maturity ogive uses A50 = 4.1 and Ato95 = 2.47. Length-at-age and a length-weight relationship are used to derive weights; the report does not provide a complete annual numerical weight-at-age surface. Spawning is placed after 93% of annual natural mortality, recruitment enters at age 1, and stock recruitment follows Beverton–Holt with steepness 0.75.

## Reported outputs

FAR 2020/14 reports an MPD estimate of B0 = 20,682 t and Bcurrent = 32.4% of B0. The area-specific MPD Bcurrent estimates are 31.2%, 31.5%, and 38.0% for Statistical Areas 025, 027, and 030. Its MCMC estimate of Bcurrent is 35.7% of B0, with a 95% credible interval of 31–41%; the executive summary and the 2026 Plenary round this to 36%. These are different estimator summaries, not conflicting runs. The report presents annual spawning-biomass and year-class-strength trajectories as figures. A numeric annual N-at-age or F-at-age surface was not found in the reviewed 2019 report.

## Imported source records

The canonical 2019 record preserves 1,738 numeric input rows, 28 assumptions, and 10 outputs. Inputs include the three area-specific catch histories, four reported CPUE series (the combined series is identified as sensitivity-only), Foveaux survey abundance and its source CVs, survey and commercial age compositions, and tabulated length compositions. Effective multinomial sample sizes are stored as likelihood weights, separate from raw sample size; the report does not give raw sample counts.

The recreational length table (Appendix 3, Table 3.9) omits the 35 cm bin and its printed proportions sum to 0.927152. The imported record preserves that source omission and does not insert a zero or renormalize the table. Effective multinomial sample sizes are stored as sample-level likelihood weights linked to each composition ID; raw sample counts are not reported. This is one reason the assessment remains marked partial.

Outputs preserve the overall and area-specific MPD depletion estimates, MCMC B0 estimates for each area, and the overall MCMC depletion estimate and interval. Approximate 2019 SSB of 6,701 t is derived from the rounded MPD B0 and Bcurrent/B0 summaries and has no uncertainty. The report does not tabulate annual SSB, recruitment, N-at-age, or F-at-age values. M is fixed at 0.17 per year, not estimated.

## 2024 assessment and later observations

FAR 2024/56 describes a separate assessment attempt using data to the 2022–23 fishing year. The 027+029 and 030 models were affected by spatial changes in fishing and age composition; the Area 025 run was completed but rejected by the Plenary. FAR 2024/03 reports the 2023 Foveaux Strait survey, and FAR 2024/55 reports commercial catch age samples for 2021–22 and 2022–23. These later observations do not belong to the 2019 assessment inputs. If curated, the 2024 attempt and its supporting data will be recorded separately from the 2019 run.

## Remaining source gaps

The 2019 report provides age-frequency compositions and reconstructed catch histories, not a direct catch-numbers-at-age series. It reports growth and length-weight parameters but no complete numerical weight-at-age surface; maturity is reported as a shared logistic ogive rather than an age-specific vector. Annual SSB and recruitment are plotted but not tabulated, and numerical annual N-at-age and F-at-age outputs were not found. The 2024 reports provide later observations but do not provide accepted assessment outputs for the full BCO 5 unit. These later observations are not used to fill the 2019 record. The assessment is retained as a partial source record.

## Cached sources

The 2019 assessment report, 2024 survey report, 2024 commercial catch-age report, 2024 assessment report, and May 2026 BCO 5 Plenary chapter are cached in the gitignored `source_cache/mpi_bco5/` directory. Retrieval URLs, retrieval date, file sizes, hashes, and represented run are recorded in `provenance/mpi_blue_cod_bco5_sources.csv`.

- [FAR 2020/14: BCO 5 assessment to 2019](https://www.mpi.govt.nz/dmsdocument/41406-FAR-202014-Stock-assessment-of-blue-cod-Parapercis-colias-in-BCO-5-using-data-to-2019/sitemap)
- [FAR 2024/03: Foveaux Strait survey](https://www.mpi.govt.nz/dmsdocument/60796-FAR-202403-Relative-abundance-size-and-age-structure-and-stock-status-of-blue-cod-in-Foveaux-Strait-in-2023/sitemap)
- [FAR 2024/55: commercial catch age samples](https://www.mpi.govt.nz/dmsdocument/64962/sitemap)
- [FAR 2024/56: BCO 5 assessment attempt](https://www.mpi.govt.nz/dmsdocument/64965-FAR-202456-Stock-assessment-of-blue-cod-Parapercis-colias-in-BCO-5-using-data-to-2023/sitemap)
- [Fisheries Assessment Plenary May 2026, BCO 5](https://www.mpi.govt.nz/dmsdocument/72170-Fisheries-Assessment-Plenary-May-2026-Volume-1-BLUE-COD-BCO-5)

The [2026–27 research-services proposal](https://www.mpi.govt.nz/dmsdocument/71944/direct) identifies a future catch-age project. Its direct download returned an access-challenge page during this review, so no invalid placeholder is retained in the source cache and it is not listed as a cached source.
