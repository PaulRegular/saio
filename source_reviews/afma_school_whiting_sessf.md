# AFMA Eastern School Whiting (SESSF, 2024)

## Stock and latest assessment

AFMA's 2026 SESSF species summary identifies the 2024 combined Tier 1 assessment as the latest assessment used for School Whiting advice. It covers the shared eastern school whiting stock from western Victoria, around Tasmania, and along Australia's east coast to southern Queensland. The summary identifies the production model as Stock Synthesis 3.30.22.01 with input data through 2023.

The original 2024 technical report is cited in the summaries as a paper presented to SERAG in November 2024. I did not locate that report itself through AFMA's assessment and SERAG pages, the CSIRO assessment listing, or the public fisheries assessment catalogue. A later supporting source is now available: the FRDC final report for project 2019-030, published in March 2026. Its Chapter 8 summarizes the 2020 and 2024 assessments and reproduces selected tables from Burch et al. (2024b). It supplies additional assumed biological parameters and numerical model outputs, but not the annual likelihood input arrays.

## Sources and provenance

- [AFMA, SESSF Species Summaries 2026](https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf), School Whiting section, pp. 96-100.
- [Hall et al., FRDC Final Report 2019-030](https://www.frdc.com.au/sites/default/files/products/2019-030-DLD.pdf), Chapter 8 and Tables 18, 42-44, pp. 130, 204, 207-208; selected tables are reproduced from Burch et al. (2024b).
- [CSIRO and NSW DPI, School Whiting stock assessment based on data up to 2019](https://research.csiro.au/efar/wp-content/uploads/sites/284/2022/06/SchoolWhiting2020.pdf), a separate older assessment run.
- [AFMA, SERAG Meeting 2, November 2024 minutes](https://www.afma.gov.au/sites/default/files/2025-05/SERAG-November-2024-minutes.pdf), agenda item 3, p. 7, reporting the final combined assessment's SSB0 and projected SSB2025.

The available PDFs are cached under the ignored `source_cache/afma_school_whiting/` directory. Retrieval dates and SHA-256 checksums are recorded in `provenance/afma_school_whiting_2024/manifest.csv`. The FRDC report was retrieved on 2026-11-07; its SHA-256 is `39FD3D537ACEB850769F85C7F602CC95C7DE8F7B739B4EF14C7ADFB932CDF25F`.

## 2024 model and reported results

The 2024 combined base case is an age- and size-structured Stock Synthesis model with six fleets, an unexploited population at the start of 1942, a plus group at age 9, a Beverton-Holt stock-recruitment relationship with steepness fixed at 0.75, annual recruitment process error fixed at 0.7, von Bertalanffy growth estimated in the model, and natural mortality fixed at 0.6 per year. The model increased maximum modelled length from 25 cm in the 2020 assessment to 30 cm in 2024 and split the earlier southern trawl fleet into separate Commonwealth and NSW southern-trawl fleets. Commonwealth discarding was time-blocked for 2017-2019. The assessment used catches, standardised CPUE, length compositions, conditional age-at-length, discard rates and ageing-error estimates; implied age distributions were constructed inside Stock Synthesis from length and conditional age-at-length information.

Table 18 of the FRDC report confirms the fixed values used in the 2024 assessment and reports the age observation plus group as 9 years. It also gives the non-estimated length-weight coefficients (a = 1.32 × 10^-5, b = 2.93) and female maturity-curve values (length at 50% maturity = 16 cm fork length; slope = -2). These assessment settings are stored separately from the report's newer biological estimates; for example, Table 29 reports current-project female and male age-at-50%-maturity estimates of 1.6 and 1.9 years, respectively, which are not the same as the assessment's fixed maturity input.

The November 2024 SERAG minutes report SSB0 = 13,207 tonnes and projected beginning-of-2025 SSB = 7,110 tonnes (53.8% of SSB0), assuming 2024 catches equal 2023 catches. Table 43 of the FRDC report reproduces the final base case as SSB0 = 13,208 tonnes, SSB2025 = 7,110 tonnes, and SSB2025/SSB0 = 0.54. The one-tonne SSB0 difference is retained as a source-reporting discrepancy and appears consistent with rounding; the detailed-table value is not treated as a different fit. Table 43 also reports NLL and the base-case biomass results for 18 sensitivity cases. Its spawning biomass includes both male and female biomass. Numeric confidence intervals are not tabulated, although Figure 73 displays asymptotic intervals.

Table 44 reports 2025 and 2026 RBCs of 3,086 and 2,961 tonnes, retained catches of 2,489 and 2,374 tonnes, estimated discards of 597 and 587 tonnes, and projected stock status of 0.538 and 0.509. It reports two-year averages of 3,023 tonnes RBC, 2,432 tonnes retained catch and 592 tonnes discards, plus a long-term yield of 2,830 tonnes. The table's 3,023-tonne RBC average differs by one tonne from the 3,024-tonne value in AFMA's later summary; both source presentations are retained separately. RBCs are advice values, not observed catch. The combined base case could not fit all regional CPUE trends simultaneously and fit the declining Victorian Danish seine series more closely than the increasing Commonwealth trawl and NSW southern-trawl series.

## Older detailed assessment and data gaps

The public 2020 assessment is a separate run using Stock Synthesis 3.30.16 and data through 2019. It reports catch tonnage, CPUE series, discard proportions, age-reading-error standard deviations, and age-sample counts. It describes fishery conditional age-at-length inputs, but does not publish their numerical vectors. It is not used to fill gaps in the 2024 run.

The reviewed 2024 sources do not provide annual numerical catch, CPUE, discard, or conditional age-at-length likelihood arrays; no age-specific survey abundance series was identified. The FRDC report includes figures and coverage periods, not the underlying annual vectors. These values have not been digitized or inferred. The partial canonical record now includes model settings, selected biological parameters, base-case and sensitivity outputs, and advice details, but still has no numerical likelihood inputs or age-specific state outputs. Age-input eligibility remains unresolved.
