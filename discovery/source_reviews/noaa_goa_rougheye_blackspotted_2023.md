# NOAA Gulf of Alaska rougheye and blackspotted rockfish — 2023

## Assessment and stock unit

NOAA Stock SMART ID 11443 is the current Gulf of Alaska rougheye and blackspotted rockfish complex. The December 2023 SAFE recommends age-structured Model 23.1b, with reported estimates through 2023. The 2024 SAFE is a projection based on that fit. NOAA's December 2025 catch report confirms that the most recent full assessment remained 2023 and that no assessment was conducted in 2025. A 2026 full-assessment document was uploaded for the November 18–20 Plan Team meeting on November 9; it was still awaiting review on November 12 and is not treated here as an accepted production assessment.

## Inputs and assumptions recovered

- Table 13-2 reports total commercial catch for 1977–2022 and Western, Central, and Eastern GOA catch components for 2005–2022, in metric tons. Catch is not reported for 2023. Total and area rows are overlapping summaries, not additive observations.
- Table 13-8 reports fishery age proportions for 12 years from 1990–2022, ages 3–41 and 42+. Table 13-9 reports fishery length proportions for 12 years from 1991–2021 in adjacent 2-cm bins, with 60+ pooled. The published fish sample sizes and haul counts are retained. Table 13-9 columns sum to roughly 0.5; the report does not explain the scale, so those values are preserved as printed without renormalization.
- Table 13-10 reports GOA-wide bottom-trawl biomass and longline relative population numbers (RPN), with CVs. The indices are relative measures. The reported 1984 and 1987 bottom-trawl estimates are retained but the report says they were removed from Model 23.1b. Area-specific biomass and relative population weights used for apportionment are not included in this population-model import.
- Table 13-11 reports bottom-trawl survey age proportions for 16 surveys, ages 3–41 and 42+, with fish sample sizes and haul counts. The 1984 and 1987 samples are retained with their exclusion from Model 23.1b noted. Table 13-12 reports bottom-trawl length compositions and explicitly states that these data are not fit in the population model. Table 13-13 reports area-weighted longline length compositions for 1993–2023.
- Table 13-16 supplies Model 23.1b weight-at-age in grams and maturity-at-age in percent for ages 3–51 and 52+. The maturity percentages are converted to proportions by dividing by 100. Model 15.4 comparison values in parentheses are not imported as Model 23.1b data. The assessment fixes natural mortality at 0.042 per year and recruitment variability at 1.10.
- The report assigns likelihood weights of 5 to historical catch (1977–2005), 50 to modern catch (2005 onward), 1 to fishery ages, trawl survey ages, fishery sizes and longline sizes, 0 to trawl survey sizes, and 1 to both survey indices. The printed catch periods overlap at 2005.
- Table 13-15 reports MLE and MCMC estimates and intervals for survey catchability. Within-year survey timing is not reported.

## Outputs and unresolved source gaps

Tables 13-17 and 13-18 report MLE and MCMC posterior mean time series for female spawning biomass, age-3 recruitment, and age-3+ biomass through 2023. The MCMC table provides 95% credible intervals. Table 13-16 reports 2023 numbers-at-age and selectivity-at-age without age-specific uncertainty. Total abundance for 2023 is derived as the sum of reported ages 3–51 and the 52+ group; no uncertainty is assigned.

The detailed report does not provide catch numbers-at-age, a separate fishery weight-at-age vector, F-at-age, a numerical age-error matrix, a numerical age-length transition matrix, or survey timing fractions. The accessible report tables therefore support a partial source record; no missing values or scaling factors are inferred.

## Sources and local cache

The three cached PDFs, retrieval dates, URLs, sizes and SHA-256 checksums are listed in provenance/discovery_noaa_goa_rougheye_2023/sources.csv. The source cache is ignored by Git.

- [2023 GOA Rougheye and Blackspotted SAFE](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOArougheye.pdf)
- [2024 GOA projection update](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10291)
- [2025 GOA catch report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C4+GOA+2025+Catch+Reports.pdf&p=f6b9ff85-9a04-46e3-a7ce-0c2a09b6ccee.pdf)
- [November 2026 GOA Plan Team meeting materials](https://meetings.npfmc.org/Meeting/Details/8165)
