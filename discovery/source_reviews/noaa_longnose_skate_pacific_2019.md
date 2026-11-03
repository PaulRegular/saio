# NOAA Longnose Skate, U.S. Pacific Coast (2019)

Review date: 2026-11-01. The screened inventory entry is NOAA Stock SMART 10731 (scientific name shown as *Raja rhina*; the assessment uses *Beringraja rhina*). The official Stock Synthesis assessment is the 2019 full run using data through 2018. The PFMC's assessment archive and its 2023 data-availability review identify no newer full assessment for this coastwide unit. The assessment area is U.S. state and federal waters from the U.S.-Canada to the U.S.-Mexico border. It is a different unit from Gulf of Alaska longnose skate (NOAA:10730). No matching canonical database stock was found.

## Age-disaggregated source evidence

The 2019 native Stock Synthesis files and report support an age-based reconstruction, but do not provide a complete annual catch-at-age and index-at-age dataset ready for import. The model tracks ages 0-30, combines sexes, and uses conditional age-at-length compositions in 24 observed age bins (0-23).

The assessment input file contains fishery removals in biomass units across the 1916-2018 model period, with current fishery removals from 1995-2018. It contains current-fishery length compositions and one fishery conditional age-at-length sample, from 2004. A catch-at-age series would therefore require combining the annual fishery length compositions with the sampled age-at-length information and clearly documenting how the single fishery sample is applied across years; direct annual catch numbers-at-age were not identified.

Five relative abundance indices are used: four in biomass units and one in numbers. Conditional age-at-length compositions for the NWFSC shelf-slope survey are available in 2003, 2011, and 2012, by lengths and observed ages 0-23. Together with the matching survey length compositions and aggregate index, these data permit limited age-index reconstruction for the sampled years. They do not establish a continuous observed index-at-age series for all surveys and years.

The assessment estimates growth by age and fixes a combined-sex weight-length relationship (weight in kg, total length in cm; W = 4.288369e-6 * L^3.068629). Age-specific weights can be derived from those model biology components. The assessment fixes a maturity-at-length ogive from WCGBT survey samples; maturity-at-age would also be derived using the fitted growth relationship. Natural mortality is estimated as a scalar with an informative prior. Survey observations are recorded in July; the native model sets survey fleet timing to 0.5 in the annual model.

The official report gives comparable population outputs, including spawning biomass, total biomass, recruitment and depletion, with uncertainty information. The public report does not provide a complete fitted N-at-age or F-at-age time series, and the public model archive contains the native input/control/starter/forecast files but no fitted `Report.sso` output. Those age-specific outputs remain unavailable in the reviewed source set.

## Screen decision

Mark this distinct unit as eligible for source curation because the official run-matched archive contains age-at-length samples, annual fishery/survey length compositions, aggregate catches and indices, biological relationships, an estimated mortality assumption, and comparable population outputs. Eligibility is conditional on the documented reconstruction and sparsity caveats above; it does not mean the observations are already tinyAM-ready. No canonical stock, assessment, input or output records were added.

The authoritative PDFs, native model ZIP and supplementary workbook are cached locally under the gitignored `source_cache/discovery_noaa_longnose_skate_2019/`. `sources.csv` records their URLs, retrieval date, revision, byte size and SHA-256 checksums.