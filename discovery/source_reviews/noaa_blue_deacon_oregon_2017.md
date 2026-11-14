# Blue and Deacon Rockfish, Oregon

The current Oregon Blue and Deacon Rockfish complex remains listed in NOAA's 2026 third-quarter stock-status table. The latest detailed production assessment located is the 2017 Stock Synthesis assessment, fitted through 2016 with a 2017 forecast. The 2017 report and Oregon model archive are cached locally; the source manifest records their retrieval dates, URLs, sizes, and checksums.

The native data file contains 625 annual aggregate catches from five fleets (1892–2016), 60 observations from four aggregate fishery-dependent CPUE series (1980–2016), 101 length-composition rows, and 418 age-composition rows. Of the age rows, 371 are conditional age-at-length and 47 are marginal. The native `catch_se` field, including its zero values, is preserved as a source field; the report treats catches as known, and the control file does not activate a catch likelihood. The composition cells are retained at their source scale with sample sizes, age-error IDs, source sex coding, partitions, and signed fleet/year codes. These samples are not annual catch-at-age or age-specific abundance indices. All index and composition records are from month 7 in a one-season model; the corresponding sampling-time fraction is 0.5.

The base model uses fixed, age-invariant natural mortality: female M is 0.1588 per year and male M is a fixed 0.159 log offset (about 0.186 per year). This is distinct from the California base model's female M of 0.119, which is not used here. Growth is sex-specific and fitted from age-length data; weight-at-age is generated from growth and weight-length relationships. Female maturity is a fixed logistic function of length, not a supplied maturity-at-age vector.

Table ES20 reports age-0+ biomass, egg-based spawning output, recruitment, depletion, exploitation rate, relative SPR intensity, landings, and removals for recent years. The 2017 estimates are forecasts beyond the 2016 data terminal year. Spawning output is in millions of eggs, not conventional mass-based SSB. Approximate 95% asymptotic intervals are available for spawning output, recruitment, and depletion. No numeric fitted N-at-age or F-at-age surface was found in the cached archive, which does not contain Report.sso. Source completeness remains partial.

PFMC's 2026 stock-priority record lists Oregon and Washington Blue/Deacon status as to be determined and the California area as removed from the FMP. NOAA's 2026 third-quarter table independently continues to list the Oregon Blue/Deacon complex as a current stock. The California 2017 model is therefore not imported as a current unit.

## Sources

- [2017 assessment report](https://www.pcouncil.org/documents/2018/01/the-combined-status-of-blue-and-deacon-rockfishes-in-u-s-waters-off-california-and-oregon-in-2017.pdf/)
- [2017 Oregon Stock Synthesis files](https://www.pcouncil.org/documents/2017-blue-and-deacon-rockfishes-oregon-model-files-2-zip-file-2-mb/)
- [2017 STAR panel report](https://www.pcouncil.org/documents/2017-star-panel-report-for-blue-deacon-rockfish.pdf/)
- [2026 PFMC stock-assessment prioritization](https://www.pcouncil.org/documents/2026/02/d-8-attachment-1-groundfish-stock-assessment-prioritization-to-inform-the-selection-of-species-for-assessment-in-2027.pdf/)
- [NOAA 2026 third-quarter stock-status table](https://www.fisheries.noaa.gov/s3/2026-11/final-q3-2026-stock-status-tables-updated-11-02-26.pdf)
