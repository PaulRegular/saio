# NOAA Pacific Coast lingcod, 2021

## Assessment units and run

NOAA Fisheries identifies separate Northern and Southern Pacific Coast lingcod stocks and still cites the 2021 assessment for stock status. The 2021 PFMC assessments split the U.S. population at 40°10′N (Cape Mendocino); the northern model ends at the U.S.-Canada boundary. The U.S. north and south units are not interchangeable with the separate DFO outside-waters unit. The model files use assessment data through 2020. PFMC planning documents identify a benchmark assessment for 2027; the pinned assessment repository describes work on that upcoming assessment, so it does not displace the 2021 production run used for current management status.

Stock SMART IDs 12194 and 12195 are recorded as two candidate units. Neither matches a canonical database stock or an existing numerical assessment record. No stock, assessment, input, or output values have been added to the canonical database.

## Inputs and outputs in the accepted fits

Both pinned Stock Synthesis archives contain fleet catches, age and length composition data, model-generated weight-at-age, growth and maturity calculations, estimated sex-specific natural mortality, and Report.sso outputs for catch-at-age, numbers-at-age and F-at-age. The age bins span 0–20 with a plus group above age 20. Catch totals are biomass observations; any catch-at-age reconstruction must combine the exact fleet catches with composition and biological inputs and preserve the source unit conversions.

The northern base fit includes conditional-age-at-length data from commercial trawl, fixed gear, Washington and Oregon recreational fleets, the Triennial Survey, WCGBTS, and Lam research. Active fleet-year coverage in the pinned model is: trawl 1978–2020 (43 years); fixed gear 1980–2020 (37 years); Washington recreational 1979–2020 (41); Oregon recreational 1999–2019 (18); Triennial 1992–2004 (5); WCGBTS 2003–2019 except 2017 (16); and Lam research 2016 (1). Aggregate CPUE or survey indices accompany age compositions. This provides age information across the principal fisheries and surveys and is eligible for source curation, with composition expansion, observation units, plus groups and timing to be resolved during import.

The southern fit has only the WCGBTS conditional-age-at-length series in its age-composition likelihood (2003–2019, 17 years). The data file retains some other negative-fleet age observations, but Stock Synthesis treats those as expected-only records with no likelihood contribution. The STAR panel and assessment report explain that sparse fishery and Triennial ages were excluded after poor/conflicting fits and strong effects on estimated population scale. Because the accepted fit lacks a usable fishery age-composition likelihood to support catch-at-age reconstruction, the southern unit is screened ineligible for this age-disaggregated input set. Its official age-specific outputs remain useful reference information but do not substitute for those inputs.

The reports state that maturity values are fixed from a separate biological analysis, weight-length relationships are fixed from WCGBTS paired observations, and sex-specific M is estimated. This review does not assign a timing value. Report.sso contains the population and mortality surfaces needed for comparison, but this screening step does not import or refit either model.

## Cached sources

The source archive, model input/output files, retrieval dates, pinned repository revision and SHA-256 checksums are listed in `source_cache/discovery_noaa_lingcod_2021/sources.csv`. Extracted north and south model files are retained under the ignored `source_cache` folder.

- [NOAA Lingcod status](https://www.fisheries.noaa.gov/species/lingcod)
- [2021 northern assessment](https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-northern-u-s-west-coast-in-2021-december-2021.pdf/)
- [2021 southern assessment](https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-southern-u-s-west-coast-in-2021-december-2021.pdf/)
- [2021 STAR panel report](https://www.pcouncil.org/documents/2021/10/lingcod-stock-assessment-review-star-panel-report.pdf/)
- [2021 Stock Synthesis model files](https://www.pcouncil.org/documents/lingcod-2021-model-files-zip-file/)
- [Pinned PFMC lingcod repository README](https://raw.githubusercontent.com/pfmc-assessments/lingcod/4d295683f7caf41bf703cb2de07f1ff7245b354a/README.md)
