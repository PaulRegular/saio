# NOAA Rougheye and Blackspotted Rockfish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 14516 is the U.S. West Coast Rougheye and Blackspotted Rockfish Complex. The assessment pools *Sebastes aleutianus* and *Sebastes melanostictus* as one management unit because they are difficult to distinguish in catches. This is one stock and one assessment, not two cases. The current unit covers U.S. waters from the U.S.-Canada border to the U.S.-Mexico border.

The 2025 production assessment uses data through 2024. The archived native Stock Synthesis files contain the assessment data and Report.sso. The report executive summary and Report.sso identify version 3.30.23.2, while report section 3.4.1 says 3.30.23.1. The database records this discrepancy rather than choosing one silently.

## Inputs and assumptions

- The native data file contains six fishery catch streams in metric tons from 1892–2024. Six -999 equilibrium/sentinel rows are excluded from annual observations. Catch-at-age is not a direct model input.
- Four surveys have 38 aggregate biomass-index observations in total: Triennial (9, 1980–2004), Alaska Slope (4, 1997–2001), Northwest Slope (4, 1999–2002), and WCGBTS (21, 2003–2024). Their observation months are July; Stock Synthesis unit code 1 and lognormal error type 0 are recorded. The archive does not contain age-specific abundance-index values.
- The file contains 167 length-composition observations from 1980–2024 with source length labels 10–80 cm by 2 cm, and 1,988 age-composition rows from 2003–2024 in age bins 1–100. Of these, 1,929 are conditional age-at-length observations and 59 are marginal age samples. Frequencies and native sample sizes are retained without normalization. The 59 marginal rows have negative fleet codes and are supplied for fit evaluation rather than as a separate likelihood input.
- Sex-specific vectors are retained for female, male and combined-sex observations. Seven native age-error definitions are referenced by codes 1–7 in the age-composition rows. Composition timing is also July.
- The assessment uses one area, two sexes, one annual season, and population ages 0–140, with age 140 as the accumulator group. Female natural mortality is estimated and the fitted surface is 0.0391039 per year; male M is fixed at 0.036 per year.
- Growth and length-weight relationships are sex-specific; maturity is length-based and logistic. The assessment derives weight and maturity by age internally. It does not provide standalone empirical weight-at-age or maturity-at-age input matrices.

## Outputs and limits

Report.sso provides fitted beginning-of-year numbers and biomass at age, dead catch-at-age, fishing mortality by fishery fleet and sex, and natural mortality by sex. These surfaces cover 1892–2024. The population surfaces include age 140 as the accumulator; the M surface does not provide age 140. Total abundance is derived by summing N-at-age across sexes and ages, without uncertainty. Total biomass is retained from the native time series.

Spawning output is reported in trillions of eggs. It is not SSB in biomass. Table ii reports spawning output and its fraction of unfished output for 2015–2025, including a forecast for 2025. The table labels the spawning-output interval columns as metric tons even though its point estimate and Figure ii use trillions of eggs. The intervals appear to correspond to the Figure ii spawning-output scale, so they are retained on that scale as an interpretation; the conflicting unit label remains explicit in the output notes. Lower limits printed as <0.001 are stored blank rather than as exact numbers.

Table iii provides recruitment and recruitment-deviation estimates with 95% intervals for 2015–2024. Table iv provides 1-SPR fishing intensity and exploitation rate with intervals for 2015–2024. Exploitation rate is catch relative to age 26+ biomass; it is not instantaneous F.

The archive does not include .par or CompReport.sso, and it does not provide age-specific uncertainty. Published intervals are retained for the reported aggregate outputs above. Inputs, assumptions and outputs remain marked partial because direct catch-at-age, age-specific abundance indices, empirical age-specific biology and uncertainty for the fitted age surfaces are unavailable.

## Sources and provenance

The report and native model archive were retrieved 2026-10-29 and are cached locally under the ignored source_cache/discovery_noaa_rougheye_2025/ directory. The versioned manifest provenance/noaa_rougheye_blackspotted_2025_sources.csv records source URLs, retrieval date, byte size and SHA-256 checksums for the report, archive and imported native files.

- [2025 Rougheye and Blackspotted Rockfish assessment report](https://www.pcouncil.org/documents/2026/01/status-of-rougheye-and-blackspotted-rockfishes-stock-off-the-u-s-west-coast-in-2025.pdf/)
- [2025 native Stock Synthesis model files](https://www.pcouncil.org/documents/rougheye-blackspotted-2025-model-files-zip-file/)
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart)
