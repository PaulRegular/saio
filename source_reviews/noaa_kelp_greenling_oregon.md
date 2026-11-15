# Oregon Kelp Greenling

## Stock and assessment

NOAA Stock SMART identifies *Hexagrammos decagrammus* in Oregon coastal waters as stock 10462. This is the Oregon unit; Washington and California Kelp Greenling are separate assessment units. The canonical database had no existing Oregon Kelp Greenling record.

The latest full assessment located for this unit is the 2015 benchmark, fitted through 2014 with Stock Synthesis 3.24u. The assessment report reproduces the data, control, starter and forecast files in its appendices. The 2025 Groundfish SAFE and 2026 harvest-specification materials continue to use the 2015 fit; they do not document a later fitted assessment.

## Inputs and assumptions recovered

Appendix A reports annual total catch for 1900–2014 by commercial, recreational ocean, recreational estuary, recreational shore and special-project fleets. Values are metric tons and include landings plus discard mortality. The model years are 1915–2014; pre-1915 zero rows in the printed input are retained as source rows.

The report supplies 37 aggregate CPUE observations with log-scale standard errors: commercial logbook (2004–2013), observer CPFV (2001, 2003–2014), and ORBS (2001–2014). They are fishery-dependent indices, not independent surveys. Stock Synthesis assigns the commercial series an index-unit code for biomass and the other two a code for numbers; the database preserves these native distinctions without converting the relative index scale. Every fleet and index is timed at 0.5 in the annual model.

The printed model input contains 100 length-composition records, with bins from 6 to 60 cm at 2-cm increments. Gender code 0 is a combined-sex vector; code 3 contains separate female and male vectors. The source frequencies, sample-size field and partition codes are preserved without normalization.

There are 36 negative-fleet age-composition records for the commercial and recreational ocean fleets, with ages 0–12. Stock Synthesis treats negative-fleet records as expected-value/diagnostic rows rather than likelihood observations. The file also contains 217 conditional age-at-length records for commercial, recreational ocean and special-project samples. The stored age bins are 0–12. Their Lbin_method=2 lower and upper labels are preserved as native codes and are not interpreted as centimetres.

The assessment assumes fixed age-invariant natural mortality of 0.360 per year for females and 0.318 for males. It uses a fixed female maturity-at-length vector for 0–60 cm bins at 2-cm intervals; the vector is reproduced from the control file. Female length at 50% maturity is 29.34 cm. Male maturity was assumed similar but was not confirmed with histology. The assessment uses sex-specific weight-length relationships, W = alpha * L^beta, with female coefficients 6.81e-6 and 3.211 and male coefficients 9.76e-6 and 3.116; weight is kilograms and length is fork length in centimetres. Growth is estimated from conditional age-at-length information, so the report does not supply a separate fixed weight-at-age surface.

There is an unresolved age-grid discrepancy in the public report. The assessment text describes ages 0–12 with age 12 as the accumulator, while the printed data-file header declares 15 ages; the supplied composition bins end at age 12. The source values are retained as printed and no age-13/14 observations are inferred.

## Outputs and remaining gaps

Table 15 reports total biomass, spawning biomass, depletion, age-0 recruitment, total catch, relative exploitation and SPR for 1915–2014, plus total biomass, spawning biomass, depletion and recruitment for 2015. Tables E2 and E3 give approximate 95% asymptotic confidence limits for spawning biomass, depletion and recruitment for 2006–2015. These intervals are retained as lower and upper limits; standard errors are not inferred from them.

The reviewed public report and model listing do not provide numeric fitted numbers-at-age, fishing-mortality-at-age or estimated natural-mortality-at-age surfaces, nor age-specific uncertainty. The reported M values are fixed base-model inputs, not estimated outputs. No values have been fabricated for these gaps.

## Sources

- [2015 Oregon Kelp Greenling assessment](https://www.pcouncil.org/documents/2016/04/status-of-kelp-greenling-hexagrammos-decagrammus-along-the-oregon-coast-in-2015-november-17-2015.pdf)
- [2015 Kelp Greenling STAR panel report](https://www.pcouncil.org/documents/2016/04/kelp-greenling-star-panel-report-july-27-31-2015.pdf/)
- [ODFW Information Report 2015-02](https://nrimp.dfw.state.or.us/DataClearinghouse/default.aspx?att=ODFW%2FODFW_42532_2_Rodomsky.2015.INFO2015-02_Kelp_Greenling.pdf&pn=ViewFile)
- [Pacific Coast Groundfish SAFE, July 2025](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [2026 harvest specifications analysis for 2027-28](https://www.pcouncil.org/documents/2026/03/c-4-attachment-1-harvest-specifications-impact-analysis-for-2027-28-biennium.pdf/)
