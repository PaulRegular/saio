# Northern Norwegian coastal cod, 2026 ICES assessment

## Assessment and source selection

The latest detailed production assessment recovered is the 2026 Arctic Fisheries Working Group report. It identifies the final SAM run as NCCN67_AFWG2025_v3, with assessment data through 2025. ICES Standard Graphs lists the stock as cod.27.1-2.coastN.

The 2021 WKBARFAR benchmark report documents the split between the data-rich northern coastal cod category and the southern coastal component. The existing Charbonneau-Keith COASTNOR 1,2 stock record is a composite pre-split catalogue entry and remains separate. No Charbonneau-Keith identifier is assigned to this northern assessment.

The assessment report cites a TAF repository for the final SAM model, but that repository was not retrievable during this review. A historical stockassessment.org run was found, but it ends in 2019 and is not used as the 2026 production assessment.

## Cached sources

The full report and framework report are cached in the gitignored source cache.

- AFWG 2026 report, DOI 10.17895/ices.pub.32134696.v1. Retrieved 2026-10-23. SHA-256: 35DB72D64947EA001E16AB358FD48F4F55CAAE958C80A861348E5A4B778D77B1.
- WKBARFAR 2021 benchmark report, DOI 10.17895/ices.pub.7920. SHA-256: 362106840B5C8CC5F5F161AE432C6616A7579188A129485B37F2607060D04F8F.

The report and framework are available at https://ices-library.figshare.com/articles/report/Arctic_Fisheries_Working_Group_AFWG_/32134696 and https://ices-library.figshare.com/articles/report/Benchmark_Workshop_for_Barents_Sea_and_Faroese_Stocks_WKBARFAR_2021_/18619163. The report's stock graph is https://standardgraphs.ices.dk/ViewCharts.aspx?key=22637.

## Imported data

The importer reads the published report tables and the final SAM tuning data in Table 2.2.12.

- Total catch-at-age, catch weight, stock weight, natural mortality, and maturity are retained at their source ages, years, units, and printed precision.
- The age-specific swept-area abundance index is retained for 2003-2025, ages 2-10+, in thousands of fish, with sampling time 0.8. The source survey.dat weights are all one.
- The aggregate acoustic biomass index is retained in tonnes for 1995-2025, at age 2+ and sampling time 0.8. The final run omits 2021 because of high uncertainty. For 2000, the final tuning table gives 35,255 tonnes while the report summary table gives 35,243 tonnes; the final tuning value is retained and the discrepancy is noted.
- Natural mortality is treated as a fixed supplied input and is derived in the assessment from stock weights using the Lorenzen (1996) method.
- The report provides age-specific N and F point estimates for 1994-2025, age-3 recruitment, SSB, Fbar ages 4-8, total biomass, and q. Aggregate recruitment, SSB, Fbar and total-biomass tables include 95% limits; age-specific N and F do not have reported uncertainty intervals.

Source assumptions record the SAM process configuration, q-sharing, observation variances, relative weights, SSB timing, and unresolved initial-state distribution. The assessment row is marked complete for inputs and outputs and partial for assumptions because the exact fitted object and initial-state integration could not be verified.

## tinyAM translation

The translation fits 1995-2025 at ages 3-10. It excludes age 2 so the youngest tinyAM age corresponds to official recruitment age 3. The assessment's age-10 plus group remains a terminal modeled group in tinyAM; hidden ages within that group are unavailable.

The fit uses total catch-at-age and the age-specific swept-area index. It retains official stock weight, maturity, and supplied natural mortality. M is not estimated. Recruitment and abundance residuals use random walks, while F uses correlated random-walk increments and the source mean-F ages 4-8. q groups reproduce the reported swept-survey sharing at ages 3, 4, 5-9, and 10+. The fit uses one independent lognormal SD for the age-specific swept observations; SAM's cross-age observation correlation is not reproduced.

The aggregate acoustic biomass index is not fitted because tinyAM supports age-specific abundance-index likelihoods rather than an aggregate biomass index. No source observations are changed to improve agreement. The current SAM run's initial-state treatment, exact variance sharing, shared F states at ages 7-9, and full likelihood are not reproduced.

The dashboard's common-age SSB, abundance, and biomass comparisons use ages 3-10; native SAM aggregates remain separately reported. The fixed M comparison checks that the same source surface reaches tinyAM and is not evidence that M was estimated. The assessment's arithmetic Fbar is retained as a native output; the common-definition comparison uses abundance-weighted F over ages 4-8.

For comparison reporting, biomass-at-age is derived as official N-at-age in thousand fish multiplied by official stock weight in kilograms per fish, giving tonnes. Age 10 retains the source 10+ group. This comparison-only series is not added to the canonical database, and no uncertainty is assigned because age-specific N uncertainty is unavailable. The refreshed fit remains numerically converged (optimizer code 0, objective 154.1478, maximum absolute gradient 0.0003204, successful standard-error report, positive-definite Hessian). The dashboard is regenerated from this fit and includes the derived biomass-at-age comparison.
