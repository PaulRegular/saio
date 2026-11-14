# NOAA Gulf of Alaska Rex Sole

## Stock identity and assessment

NOAA Stock SMART IDs 10058, 15410 and 15411 describe one Gulf of Alaska rex sole assessment unit. ID 10058 is the Gulf-wide entry; IDs 15410 and 15411 identify the eastern and western-central areas used by the assessment. NOAA ID 10059, Pacific Coast rex sole, is a separate stock unit.

The September 2026 Gulf of Alaska SAFE chapter is the latest detailed assessment located for this unit. It uses the author's preferred Model 25.1, Stock Synthesis 3.3.25.1, with data through 2026. The September Plan Team recommended Model 25.1 for the 2027–2028 harvest specifications, and the October 2026 SSC supported it. The model has Eastern and Western-Central areas, separate sexes, ages 0–20, and age 20 as the plus group.

The public NOAA-AFSC goa_rex repository is cached at commit 453e1166e1bf83b9062fe228b93f2225b1cbe1aa. Its available proposed-model run files end in 2024 and are not the final 2026 Model 25.1 inputs. The report-linked Appendix E composition attachment is marked draft, so its inputs have not been treated as final-run data.

## Inputs and assumptions

Table 9 reports fishery catch in tonnes for 1982–2026. The 2026 value is partial. Table 9 identifies the cutoff as August 22, while Table 7 and the assessment narrative say August 29. The database retains the Table 9 value without annualizing it and records the discrepancy.

Table 14 reports Eastern and Western-Central GOA survey biomass and a column labelled “Log Standard Error” for 1990, 1993, 1996, 1999, and biennially from 2001 through 2025. Eastern GOA has no 2001 sample. The database preserves the reported log-scale standard errors separately from the biomass observations. Table 7 describes earlier 1984 and 1987 survey coverage, but the report does not provide numerical biomass values for those years in Table 14. Table 14 labels its terminal value 2025; the narrative on page 11 refers to the 112,824 t sum as 2026. The table year is retained.

The final model identifies the survey timing as July (Appendix B). Database sampling_time = 0.5 represents the month-start convention, (7 - 1) / 12; rows retain “July” as their season.

The report describes fishery age compositions and survey conditional age-at-length data. Survey ages are fitted conditional on length; marginal survey age compositions are not included in the objective function. The final numerical composition tables in the report-linked Appendix E are labelled draft and have not been imported. Table 16's Francis relative weights are recorded as assumptions, not sample sizes.

Natural mortality is fixed at 0.17 per year for both sexes. Growth curves are estimated separately by sex and area. The report describes weight-at-age as calculated from the weight–length relationship and estimated growth; it gives the weight–length form and sex-specific coefficients but does not state their units in that passage. Female maturity is described by a logistic length relationship with 50% maturity at 351.7 mm and slope 0.0392 mm⁻¹; the report gives an age-at-50%-maturity of 5.7 years and age-scale slope of -1.113.

## Outputs and remaining source gaps

Table 30 reports recruitment at ages 0 and 3 for 1982–2026 and the standard deviation of age-0 recruits through 2025. The database retains those values at the ages reported. The table does not state the number scale, and its 2026 age-0 recruitment standard deviation is blank; neither is inferred.

Table 31 reports total biomass for ages 3+, female spawning biomass, and the standard deviation of spawning biomass for 1982–2026. The biomass unit is tonnes. The source-reported standard deviation is stored as its own output measure, not as an SE or confidence interval.

Appendix F reports numbers-at-age for 1982–2026 by area, sex, and ages 0–20. Values are preserved as printed because the table does not state their number scale. No uncertainty is reported for this table. Age 20 is the plus group.

The report does not tabulate a fishing-mortality-at-age surface. Natural mortality is fixed rather than estimated. The assessment report describes age compositions, conditional age-at-length data, growth and maturity assumptions, but the draft Appendix E prevents verification of final-run numerical composition inputs. The final run-matched model-input archive and the scale of recruitment and Appendix F numbers remain unavailable. The record is therefore partial even though several official source tables have been recovered.

## References

- [2026 GOA Rex Sole SAFE chapter](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=6.+GOA+Rex+Sole.pdf&p=44a13dd4-61ed-4ab1-9eb8-69094d5e517b.pdf), especially Tables 9, 14, 16, 30 and 31, Appendix B, and Appendix F.
- [September 2026 GOA Groundfish Plan Team report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C3+GOA+Groundfish+Plan+Team+Report.pdf&p=1e1317f4-91d2-49f2-91ca-ae9865e7e7bc.pdf), pages 7–8.
- [October 2026 SSC final report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+October+2026+FINAL.pdf&p=72476d9c-c900-4f64-8e25-bb9dc7842c26.pdf), page 35.
- [NOAA-AFSC GOA rex sole assessment repository at the cached revision](https://github.com/noaa-afsc/goa_rex/tree/453e1166e1bf83b9062fe228b93f2225b1cbe1aa).
- NOAA Stock SMART records for [10058](https://apps-st.fisheries.noaa.gov/stocksmart/) and [15410/15411](https://apps-st.fisheries.noaa.gov/stocksmart/). Query responses, retrieval details and checksums are recorded in the gitignored local source-cache manifest.