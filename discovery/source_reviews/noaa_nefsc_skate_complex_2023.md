# NOAA Northeast Skate Complex (2023)

Review date: 2026-11-01. NOAA Stock SMART lists seven species-level rows for the Northeast Skate Complex: clearnose, little, rosette, smooth, thorny, winter and barndoor skate (IDs 11036, 11047, 11063, 11071, 11076, 11080 and 11269). All seven identify the same accepted 2023 management-track assessment using data through 2022. NOAA Fisheries describes these species as one Northeast Skate Complex management unit spanning Maine to Cape Hatteras. No matching canonical skate stock or complex was found. The seven rows therefore share one candidate-unit crosswalk so the single assessment is not counted seven times.

## Assessment method and evidence

The accepted 2023 management-track assessment updates catch, survey biomass indices and reference points. It uses an empirical index-based approach, with survey biomass indices by species; the spring survey is used for little skate and the fall survey for the other managed species. The assessment does not estimate an age-structured population surface. The final peer-review report states that annual fishing mortality, recruitment and stock biomass could not be estimated under the method. It also says the assessment generated an abundance index and length frequencies, and that age and growth studies are needed to improve future assessment work.

Stock SMART classifies all seven current entries as an “Index Method” (model category 2). Each has Composition Input Data level 1. NOAA's data dictionary defines level 1 as some size or age composition data having been collected, with major coverage gaps, and not used in the assessment. That metadata does not establish model age-composition likelihood inputs. The assessment report notes that catches by species are uncertain; historical species-specific catch is derived using survey species distributions. Neither this nor the survey biomass index is catch-at-age or an age-specific abundance index.

The sources reviewed do not provide age-specific catch, a fitted index-at-age, weight-at-age and maturity-at-age surfaces, age-specific mortality, or comparable annual N/F/SSB/recruitment outputs. Catch is reported as fishery removals in metric tonnes; survey indices are biomass/weight indices. There is no age-structured observation timing fraction to record for this empirical assessment. These gaps make the complex ineligible for the initial age-disaggregated stock set, although the current assessment remains recorded as a screened candidate unit.

## Identity and database status

The seven Stock SMART component entries map to one Northeast Skate Complex assessment unit. They are not seven independent assessment cases for this inventory. No canonical database stock, assessment, input or output records were added. The complex is a newly identified unit for matching purposes, but is excluded from the age-structured shortlist based on the accepted method and reported outputs.

## Sources and cache

- [NOAA Fisheries: Northeast Skate Complex](https://www.fisheries.noaa.gov/species/northeast-skate-complex) identifies the seven species and management unit.
- [NOAA Stock SMART 2023 skate assessment report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9056), a report marked as the peer-review draft.
- [NOAA / NEFSC 2023 management-track peer-review report](https://repository.library.noaa.gov/view/noaa/70900/noaa_70900_DS1.pdf); its report states the assessment met the panel's recommendations and was the best scientific information available, and describes the outputs that could not be estimated.
- [Skate PDT memo to the Scientific and Statistical Committee](https://d23h0vhsm26o6d.cloudfront.net/2_231004-Skate-PDT-memo-to-SSC-re-ABCr.pdf) summarizes the 2023 inputs, survey indices and fishery data limitations.
- [NOAA Stock SMART data dictionary](https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf) defines the composition-input level.

The assessment draft, PDT memo and Stock SMART data dictionary are cached under the gitignored `source_cache/discovery_noaa_nefsc_skates_2023/`; their URLs, retrieval dates, byte sizes and SHA-256 checksums are recorded in `sources.csv`. The peer-review report is publicly viewable through NOAA's repository and cited above; direct file downloads from NOAA's repository and NOAA's S3 endpoint were denied in this environment, so that PDF could not be cached locally.