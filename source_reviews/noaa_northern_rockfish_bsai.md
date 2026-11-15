# NOAA BSAI northern rockfish, 2023 Model 21

## Assessment and sources

NOAA Stock SMART unit 10416 is Bering Sea / Aleutian Islands northern rockfish (Sebastes polyspinis). The December 2023 BSAI SAFE documents Model 21, the latest full assessment fit located for this unit. It is an age-structured model implemented in AD Model Builder. The report says the model is unchanged from the accepted 2021 model.

The Gulf of Alaska unit (Stock SMART 10417) is assessed separately. The 2025 BSAI catch report says the scheduled full assessment was cancelled during the federal shutdown. The 2026 BSAI chapter carries forward the 2023 population estimates, updates catches through 2026 and lists the next operational assessment for 2027. The database records the 2023 fit. The [source manifest](../provenance/shared/noaa_northern_rockfish/sources.csv) identifies the files cached under the shared northern rockfish collection.

- [2023 BSAI northern rockfish SAFE](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAInork.pdf)
- [2026 harvest-projection chapter](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=13.+BSAI+Northern+Rockfish.pdf&p=c7d07ded-c246-4798-883b-1aacc01d8172.pdf)

- [2025 BSAI catch report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C5+BSAI+2025+Catch+Reports.pdf&p=b2b4068a-522e-42f6-a0ca-68a7ffa83ae7.pdf)
- [2026 SSC assessment review plan](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=F+2026+Groundfish+Stock+Assessment+SSC+Review.pdf&p=2aa31081-76e1-4025-af01-e17fd99ba0d6.pdf)

## Data recorded

The database preserves Table 3 annual catch biomass for 1977?2023 in tonnes. The 2023 total is retained as the report presents it, with the report's note that data were available through September 16.

The model's observed fishery age compositions are transcribed from Table 12 for 17 sampled years (2000?2021, with gaps). Survey age compositions are from Table 14 for 13 Aleutian Islands survey years (1991?2022). Both cover ages 3?39 and a 40+ group, represented as age 40 with the plus-group label documented in notes. Table 10 and Table 15 otolith-read counts are recorded with the compositions. These counts are the reported number of otoliths, not a separately reported effective sample size. Proportions are preserved as printed to three decimal places and are not renormalized; rounding means some annual columns do not sum exactly to one.

Table 13 survey biomass and CVs are recorded for the 13 Aleutian Islands survey years used in Model 21. The three cooperative survey estimates from 1980, 1983, and 1986 are retained in the transcription files but excluded from the model input series because the SAFE identifies vessel and gear differences. The 2022 CV is stored as 0.23, the Table 13 value.

Table 18 assumptions are recorded for the age range and plus group, age-3 recruitment, mature female spawning biomass, M and q priors, composition weighting, likelihood weights, and process penalties. Table 22 selected fitted parameters include M, q, selectivity parameters, maturity parameters, and log_avg_fmort on its reported log scale.

Tables 23 and 24 provide total biomass, spawning biomass, age-3 recruitment, and numbers-at-age. Table 23 CVs are stored separately as reported coefficients of variation; they are not converted to standard errors. Total abundance for ages 3+ is derived by summing the Table 24 numbers-at-age, including age 40+, and is clearly labelled as derived with no uncertainty. The 2024 total- and spawning-biomass values are retained as the official projection shown in Table 23. Table 17's reported model-predicted average weight-at-age and maturity-at-age are stored as fitted biological outputs, not treated as original model inputs.

## Source gaps and limitations

The SAFE does not provide annual catch numbers-at-age or age-specific survey abundance observations. It reports total catch and age-composition samples as separate likelihood inputs; the compositions are not abundance indices. Survey age compositions and aggregate survey biomass are both available, but deriving age-specific abundance would require annual survey weights and expansion conventions that are not given here.

The original age-specific weight and maturity input schedules, full ageing-error matrix, exact fractional survey timing, and some likelihood details were not recovered from the public tables. Table 17 contains fitted average biological surfaces, not those original inputs. Table 22 gives a scalar average-F parameter, but no numeric annual F-at-age surface was recovered. The database preserves the parameter on its reported log scale rather than transforming it into an unsupported F series.

The record remains partial.

