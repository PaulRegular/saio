# NOAA Gulf of Alaska Rex Sole

## Stock identity and assessment

NOAA Stock SMART IDs 10058, 15410 and 15411 refer to the Gulf of Alaska rex sole assessment record: 10058 is the older Gulf-wide entry, while 15410 and 15411 list the eastern and western-central areas. The final 2026 assessment is one two-area model, so these rows share `candidate_unit_id = noaa_goa_rex_sole` and count as one stock unit. NOAA Stock SMART ID 10059, Pacific Coast rex sole, is a separate unit. No matching Gulf of Alaska rex sole stock is currently in the canonical database; this remains provisional until the cross-organization identity review is complete.

The latest detailed assessment is the 2026 Gulf of Alaska SAFE chapter. It is a full assessment based on data through 2026. Model 25.1 is the author's preferred model; the September Plan Team recommended it for the 2027–2028 harvest specifications and the October 2026 SSC supported that recommendation. The model is a split-sex, age-structured Stock Synthesis assessment with Eastern and Western-Central areas. It uses ages 0–20, with age 20 as the plus group, and a fixed allocation of recruitment between areas.

The NOAA-AFSC `goa_rex` repository is cached at commit `453e1166e1bf83b9062fe228b93f2225b1cbe1aa`. It contains proposed-model runs, but the available `run_14_asfor7_ageing_error` files end in 2024 and are not the final 2026 Model 25.1 inputs. The repository's current public `main` was checked and was at the same revision. Do not treat those files as the run-matched final archive. The report-linked Appendix E input attachment is locally cached, but its pages identify it as a draft; verify its exact correspondence to the final run before importing those values.

## Inputs and assumptions

The final report lists fishery catches in tonnes from 1982 through August 2026. The fishery operates in the Western-Central area. Fishery age compositions are available by sex for 1992, 1995, 1999, 2003, 2005, 2007, 2009, 2010, 2012 and 2014–2024. These compositions are proportions estimated from samples, not observed catch numbers-at-age. An age-specific catch series would need an explicit reconstruction from catch biomass, composition proportions and weight-at-age. The report's Table 7 gives August 29 as the 2026 catch cutoff, while page 9 describes catch as of August 22; resolve this date difference before extracting a final catch value.

The AFSC RACE bottom-trawl survey supplies biomass indices for the eastern and western-central model areas. Table 7 lists the series as triennial for 1984–1999 and biennial for 2001–2025. Survey conditional age-at-length data are available for 1984, 1987, 1993, 1999 and biennially from 2001–2025. The report says marginal survey age compositions are not included in the objective function; the model fits survey ages conditional on length. An age-specific survey index would therefore be a documented transformation, not the assessment's native survey likelihood. Page 11 also calls 112,824 t a 2026 survey-biomass estimate, which does not match Table 7's terminal year; verify the survey year before importing the index.

The assessment's age grid is 0–20, with 20 as the plus group. Sex- and area-specific growth is estimated. Fixed sex-specific weight–length relationships are used (female alpha 1.35e-6 and beta 3.44963; male alpha 2.18e-6 and beta 3.30571), and weights-at-age depend on the estimated growth curves. Female maturity is based on a logistic length-at-maturity relationship (50% at 351.7 mm; slope 0.0392 per mm), converted to age using survey-based mean length-at-age. Natural mortality is fixed at 0.17 per year for both sexes.

The assessment is annual. The cached proposed-run input uses one 12-month season and assigns survey biomass observations to month 7, but that file is not the final 2026 run. The October SSC report also notes that survey timing was misspecified in the SS3-to-SPoRC bridge. The exact timing in the final model inputs must be verified in the final production files; do not infer a precise year fraction from the earlier run.

## Outputs and screening decision

Appendix F reports numeric numbers-at-age for Model 25.1 by year (1982–2026), area and sex, at ages 0–20. It does not show uncertainty intervals, and the table heading does not state the number scale; resolve the scale before import. The assessment also reports spawning-biomass and recruitment results. The available final report and appendices do not provide a numeric F-at-age surface. M is an input fixed at 0.17, not an estimated output.

Screening decision: provisionally new and eligible for source curation. The final assessment documents fishery age compositions, survey age-at-length data, area-specific biomass indices, biological inputs and comparable population outputs. Catch-at-age and an age-specific survey index are not direct source observations. The exact final-run input archive and the scale of Appendix F numbers-at-age remain unverified. Native distinctions include two areas, separate sexes, conditional age-at-length likelihoods, age error and recruitment allocation; final-run survey timing is unresolved. The assessment itself notes poor fit to recent survey biomass and sensitivity associated with similar maturity and selectivity curves.

## References

- [2026 GOA Rex Sole SAFE chapter](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=6.+GOA+Rex+Sole.pdf&p=44a13dd4-61ed-4ab1-9eb8-69094d5e517b.pdf), especially Table 7, pages 10–15, and Appendix F.
- [September 2026 GOA Groundfish Plan Team report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C3+GOA+Groundfish+Plan+Team+Report.pdf&p=1e1317f4-91d2-49f2-91ca-ae9865e7e7bc.pdf), pages 7–8.
- [October 2026 SSC final report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+October+2026+FINAL.pdf&p=72476d9c-c900-4f64-8e25-bb9dc7842c26.pdf), page 35.
- [NOAA-AFSC GOA rex sole assessment repository at the cached revision](https://github.com/noaa-afsc/goa_rex/tree/453e1166e1bf83b9062fe228b93f2225b1cbe1aa).
- NOAA Stock SMART entity records for [10058](https://apps-st.fisheries.noaa.gov/stocksmart/), [15410](https://apps-st.fisheries.noaa.gov/stocksmart/) and [15411](https://apps-st.fisheries.noaa.gov/stocksmart/); their query responses and source hashes are in the ignored local `source_cache/discovery_noaa_goa_rex_2026/sources.csv` manifest.
