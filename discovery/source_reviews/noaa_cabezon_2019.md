# NOAA Pacific Coast cabezon, 2019

## Assessment identity and run

The 2019 PFMC assessment is the latest detailed production assessment located for cabezon. It covers four management substocks: Northern California (NCS), Southern California (SCS), Oregon (ORS), and Washington (WAS). NCS, SCS, and ORS are separate Stock Synthesis 3 age-structured fits with data through 2018. WAS is a separate data-poor Simple Stock Synthesis assessment. The historical NOAA Stock SMART California row 10299 (2009) is superseded by the two 2019 California substock rows, 15050 and 15051; it is a one-to-many historical alias, not another current unit. Oregon row 12193 maps to ORS, Washington row 14803 maps to WAS. No canonical database records have been added.

The PFMC 2019 assessment and model files are cached locally under `source_cache/discovery_noaa_cabezon_2019/`. The cache manifest records original URLs, retrieval date, file sizes, and SHA-256 hashes. The three full Stock Synthesis archives include their data, controls, reports, and model-derived population surfaces. The Washington model is Simple Stock Synthesis and does not provide a comparable fitted age-structured output.

## Age-input screening

The California fits use catch histories, length compositions, and aggregate CPUE indices. NCS also uses the CCFRP fishery-independent abundance index and research conditional age-at-length data from the Grebel study (1991–2002 samples, representing six years in the NCS area) to estimate growth. The report explicitly says these research ages do not represent fishery catch age composition; age-based catch observations are unavailable. SCS has no conditional age-at-length observations in the fitted likelihood; it uses NCS growth estimates. Reconstructing catch-at-age for either California fit would require applying fitted age–length relationships to observed length compositions, which is not a source-observed catch-at-age series. Both are therefore ineligible for the age-disaggregated input set, despite their age-structured fits and age-specific outputs.

The ORS model uses fleet catches, length compositions, four aggregate abundance indices, and conditional age-at-length inputs. Recreational ocean-boat age samples cover 2005–2018 (2,328 fish); commercial dead-fishery ages are sparse (364 samples from 2003 and 2007–2018). Marginal age compositions were included as diagnostics, not as separate likelihood components. These observed age samples, fleet catches, and overlapping aggregate recreational indices provide source quantities for a documented, partial age-specific reconstruction. They do not constitute a complete observed catch-at-age series or a directly observed age-specific survey index, so any later tinyAM use must label the conversion and its limited fleet/year coverage.

WAS uses a length-based spawner-potential-ratio analysis within Simple Stock Synthesis. Its limited ages supported growth and mortality calculations rather than a fitted age-structured population model. It is ineligible for this age-structured set.

## Biology, timing, and reported outputs

The three Stock Synthesis reports include age-specific numbers, fishing mortality, catch, and spawning output. California natural mortality is estimated with priors; the Oregon model also documents its own stock-specific mortality treatment. Weights, growth, maturity, and mortality are a mix of fixed biological inputs and fitted quantities; retain their stock, sex, and model-specific definitions rather than assuming a common surface. The report notes that the California catch and length-composition observations use month 6 in the 2019 models, changed from month 1 in the 2009 assessment. Oregon timing is encoded in its fleet inputs and must be interpreted from the native files before any fractional-year translation. No timing fraction is assigned by this screening.

The four substock areas are components of one species-level assessment family; they should not be counted as four additional species cases in a later batch total.

## Sources

- [2019 PFMC cabezon assessment and appendices](https://www.pcouncil.org/documents/2019/10/assessing-cabezon-scorpaenichthys-marmoratus-stocks-in-waters-off-of-california-and-oregon-with-catch-limit-estimation-for-washington-state-10-18-2019.pdf)
- [2019 supplementary tables](https://www.pcouncil.org/documents/2019/10/cabezon-supplementary-tables-october-2019.xlsx)
- [2019 STAR panel report](https://www.pcouncil.org/documents/2019/10/cabezon-star-panel-report-may-6-10-2019.pdf)
- [PFMC groundfish assessment archive](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [NOAA 2026 phase-two stock-definition review](https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf)
