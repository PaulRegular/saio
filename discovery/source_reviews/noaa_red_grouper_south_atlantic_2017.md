# NOAA South Atlantic red grouper

Review date: 2026-11-10

## Unit and latest assessment

NOAA Stock SMART 10332 is the U.S. South Atlantic red grouper management unit (*Epinephelus morio*), separate from Gulf of Mexico unit 10331. The latest completed detailed production assessment located is SEDAR 53, published in 2017, with data through 2015. NOAA identifies it as the assessment used for current stock status. The later SEDAR 86 operational update was not completed.

## Available source data

The SEDAR 53 report documents a Beaufort Assessment Model statistical catch-age assessment with ages 1–16+, where age 16 is the accumulator group. Table 1 provides fixed length, whole weight, female maturity, proportion female, and age-varying natural mortality. The report states that all males are mature. M is fixed over time and age-varying under the Lorenzen relationship, rescaled to match cumulative survival under constant M = 0.14 through age 26.

Table 2 reports aggregate annual commercial landings in 1,000 lb whole weight, recreational landings in 1,000 fish, and releases in numbers. Releases include live and dead fish; these values are not catch-at-age. Table 3 provides commercial handline, headboat, and SERFS chevron trap/video aggregate abundance indices with annual CVs. Tables 4 and 5 give sample counts in fish and trips for length and age compositions by fleet or survey.

SEDAR 53-WP05 Table 3 reports weighted commercial handline/longline age proportions for 1996–2015, with ages 17–25 pooled into 16+. There is a source discrepancy for 1996: the working paper includes a composition row, but SEDAR 53 SAR Table 4 does not list a commercial age sample that year. The source-paper row is retained in the input records with this discrepancy noted. Other numerical composition proportions are not available in the reviewed tables.

The report's Tables 6, 7, 8, and 11 provide annual outputs: start-of-year abundance at age in 1,000 fish; start-of-year biomass at age in 1,000 lb whole weight; apical F, total biomass and peak-spawning SSB; and instantaneous F at age. The fitted period ends in 2015. The 2016 values in Tables 6–8 are forecast values; 2016 has no F or SSB estimate in Table 8. These tables give point estimates without age-specific uncertainty intervals.

## Database status and remaining gaps

The canonical database now contains the NOAA stock, the SEDAR 53 assessment, source assumptions, and the numerical input/output values described above. Completeness remains **partial**: the report and working paper do not provide all fitted age/length composition proportions in numerical tables, survey age compositions were not recovered, and annual output uncertainty is unavailable. Table 2 catch totals remain aggregate, not observed catch-at-age. Survey source timing is not given as one common within-year fraction.

## Sources and local cache

The detailed report and two supporting age-composition papers are cached under the gitignored source_cache/noaa_red_grouper_sedar53_2017/ directory. Their URLs, retrieval date, file sizes and SHA-256 checksums are recorded in provenance/noaa_red_grouper_sedar53_2017/manifest.csv.

- [NOAA Red Grouper status](https://www.fisheries.noaa.gov/species/red-grouper)
- [SEDAR 53 project page](https://sedarweb.org/assessments/sedar-53/)
- [SEDAR 53 final assessment report](https://sedarweb.org/documents/sedar-53-stock-assessment-report-south-atlantic-red-grouper/)
- [SEDAR 86 project status](https://sedarweb.org/assessments/sedar-86/)
- [SEDAR 53-WP05 commercial age-composition paper](https://sedarweb.org/documents/s53wp05-commercial-age-and-length-composition-weighting-for-u-s-red-grouper-epinephelus-morio/)
- [SEDAR 53-WP08 recreational age-composition paper](https://sedarweb.org/documents/s53wp08-south-atlantic-u-s-red-grouper-epinephelus-morio-age-and-length-composition-from-the-recreational-fisheries/)
