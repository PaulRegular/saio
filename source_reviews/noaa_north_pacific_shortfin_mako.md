# North Pacific shortfin mako shark (NOAA:11715)

**Reviewed:** 2026-11-02
**Inventory row:** NOAA:11715
**Assessment unit:** North Pacific Ocean shortfin mako shark (*Isurus oxyrinchus*)
**Screen:** Ineligible for the age-disaggregated source set. The detailed current assessment is aggregate; no canonical database records were added.

## Identity and assessment status

NOAA Stock SMART ID 11715 is the North Pacific shortfin mako unit. Its latest record is assessment 13565 (2024, data through 2022; SWFSC/PIFSC), marked Full acceptance and identified as a Bayesian state-space surplus-production assessment. It is distinct from NOAA:10657, the North Atlantic shortfin mako unit. No canonical *Isurus oxyrinchus* stock row exists.

The 2024 ISC Shark Working Group report is the latest detailed assessment located. ISC25 carried forward the status advice based on this 2024 assessment. The report says the accepted model used a Bayesian state-space surplus-production model (BSPM) for 1994–2022 after changes to historical catch and removal of an early index made an age-structured approach difficult. The report explicitly notes the lack of age structure in the final estimation model.

The 2018 assessment for the same unit used an age-based Stock Synthesis model. It is superseded by the detailed 2024 assessment and is not substituted as the current assessment record.

## Inputs and outputs located

- **Catch:** The report presents annual catch/removals in numbers for the BSPM. Catches reported in weight were converted to numbers using a Stock Synthesis model that accounted for selectivity, growth, growth variability and length-weight relationships. This is not a catch-at-age input to the accepted BSPM.
- **Abundance indices:** Four standardized annual longline CPUE indices were used, with the individual indices fitted across the model ensemble rather than combined in a single model. They are aggregate relative-abundance series, not age-specific indices.
- **Compositions and age data:** The report describes size-composition data used by an initial Stock Synthesis model. The final BSPM did not estimate age structure or use age-composition observations. Size compositions without source age samples do not support a defensible observed catch-at-age reconstruction here.
- **Biology:** Growth, length-weight, maturity, fecundity and natural-mortality-at-age assumptions inform the report's age-structured simulation scenarios. These are not age-specific likelihood inputs to the accepted BSPM.
- **Outputs:** The 2024 accepted model reports aggregate depletion, exploitation rate, removals/catch, MSY and related status quantities for 1994–2022. It does not report fitted N-at-age, F-at-age or M-at-age. The report's age-structured simulation generated scenario trajectories to assess whether biological and fishery characteristics could reproduce observed index trends; these diagnostic simulations are not fitted population outputs from the accepted assessment.

## Screen decision

**Ineligible for the age-disaggregated source set.** The latest detailed assessment and its accepted advice basis are recoverable, but the 2024 production assessment estimates aggregate surplus-production quantities. Its aggregate CPUE and catch inputs, plus the size-composition information described for an initial SS3 model, do not provide direct age-disaggregated observations for the accepted assessment. The report's age-structured simulations do not change that classification because they are diagnostic scenario results rather than estimated assessment states.

This is a discovery screen only. No stock, assessment, input or output records were added. The ISC stock-assessment page states that access to assessment data files requires a non-disclosure agreement; no public native fitted object was located in the reviewed sources.

## Sources and cache

The gitignored local cache is `source_cache/discovery_noaa_isc_shortfin_mako_2024/`. `sources.csv` records the URLs, retrieval dates, byte counts, SHA-256 hashes and revisions for the cached reports.

- [ISC24 shortfin mako assessment report, Annex 14](https://isc.fra.go.jp/pdf/ISC24/ISC24_ANNEX14-North_Pacific_Ocean_Shortfin_Mako_Shark_Stock_Assessment_Through_2022-FINAL.pdf)
- [ISC25 Plenary Report](https://isc.fra.go.jp/pdf/ISC25/ISC25_Plenary_Report_FINAL.pdf)
- [ISC stock-assessment report index and data-file access note](https://isc.fra.go.jp/reports/stock_assessments.html)
- [NOAA Stock SMART ID 11715](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11715)
