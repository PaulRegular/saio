# NOAA Oregon Kelp Greenling

## Stock identity and assessment

NOAA Stock SMART ID 10462 identifies *Hexagrammos decagrammus* in Oregon coastal waters. The 2015 assessment is a single Oregon stock unit; it does not include Washington or California. No same-species stock record was found in the canonical database or the currently reviewed candidate crosswalks, so this is provisionally new pending completion of cross-organization identity review.

The latest full age-structured assessment located is the 2015 benchmark, using data through 2014 and Stock Synthesis 3.24u. The assessment report prints the run's data, control, starter and forecast files in appendices A-D, although a separate downloadable model archive and `Report.sso` were not found on the Pacific Council listing. The 2025 Groundfish SAFE still presents status from the 2015 assessment. The 2026 harvest-specification analysis and Council record use the 2026 OFL and ABC levels for 2027-28; these are management projections linked to the older assessment, not a new fitted age-structured run.

## Inputs and assumptions

The printed Stock Synthesis data file describes one annual area, two sexes, four fishery fleets (commercial, recreational ocean boat, estuary boat and shore), a special-project age sample, and three fishery-dependent CPUE indices. The model year is January-December, with all fleet and index observations assigned to year fraction 0.5. Catch is supplied in metric tonnes and combines landings with dead discards. The report identifies three aggregate CPUE series: commercial logbook (2004-2013), onboard CPFV observer (2005-2014), and recreational ORBS (2001-2014). None is a fishery-independent survey.

Age compositions are included for commercial catches (2003-2013), recreational ocean-boat catches (2005-2013), and special-project samples used to inform young-fish growth (2013-2014). The report's age compositions and catch totals are source quantities for a documented age-specific catch reconstruction, but that reconstruction is not a directly observed catch-at-age series. Age-splitting the CPUE series would also require matching the fishery compositions to the index fleets and years; it would be an approximation, not an age-specific survey observation. Length compositions cover additional fleets and years, with 2-cm data bins from 6 to 60 cm and population bins from 0 to 60 cm.

Age-specific weights can be derived from the sex-specific growth and weight-length functions. The assessment uses fixed length-based maturity, informed by Oregon histology; the reported female length at 50% maturity is 29.3 cm, while male maturity was assumed similar without histological confirmation. Base natural mortality is fixed at 0.360 per year for females and 0.318 for males, based on maximum-age priors; it is not estimated in the base model. Alternative M values are sensitivity cases. The model uses Beverton-Holt recruitment with estimated deviations for 1980-2012 and fixed steepness 0.7.

There is a source-level age-grid discrepancy to resolve before extraction: the model-description text says population ages 0-12 with age 12 as the accumulator, while the printed data-file header declares 15 age categories and the age-composition appendix includes observed ages above 12. The printed files should be checked against a parser or native model files before recording a definitive age/plus-group mapping.

## Outputs and screening decision

The report provides aggregate spawning biomass, depletion, recruitment, SPR and reference-point outputs. For 2015 it reports spawning biomass of 316 mt (approximate 95% interval 116-516 mt), depletion of 0.80 (0.59-1.00), and recruitment of 1,413 thousand (0-3,318 thousand). It does not provide a numeric fitted N-at-age or F-at-age table, and the public sources located do not include the fitted `Report.sso`. Fixed M is available as an input assumption, not an estimated M trajectory.

Screening decision: provisionally new and eligible for **source curation** because the official report reproduces run-specific age compositions, catches, biological assumptions and comparable aggregate outputs. Translation readiness is not established by this screen. The missing independent survey, approximate age-splitting of fishery CPUE, incomplete age-composition coverage across fleets, lack of numeric fitted age surfaces, and unresolved age-grid discrepancy must remain explicit. The register does not treat catch totals or compositions as a fabricated age-specific index.

## References

- [2015 Status of Kelp Greenling along the Oregon Coast](https://www.pcouncil.org/documents/2016/04/status-of-kelp-greenling-hexagrammos-decagrammus-along-the-oregon-coast-in-2015-november-17-2015.pdf)
- [2015 Kelp Greenling STAR Panel Report](https://www.pcouncil.org/documents/2016/04/kelp-greenling-star-panel-report-july-27-31-2015.pdf/)
- [ODFW Information Report 2015-02: growth, spawning seasonality and maturity](https://nrimp.dfw.state.or.us/DataClearinghouse/default.aspx?att=ODFW%2FODFW_42532_2_Rodomsky.2015.INFO2015-02_Kelp_Greenling.pdf&pn=ViewFile)
- [Pacific Coast Groundfish SAFE, July 2025](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [2026 harvest specifications analysis for 2027-28](https://www.pcouncil.org/documents/2026/03/c-4-attachment-1-harvest-specifications-impact-analysis-for-2027-28-biennium.pdf/)
- [November 2025 Pacific Council meeting record](https://www.pcouncil.org/documents/2026/04/november-2025-council-meeting-record.pdf/)
- [NOAA 2026 Amendment 37 assessment history](https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf)
