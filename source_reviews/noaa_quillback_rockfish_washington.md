# NOAA Washington quillback rockfish, 2021

## Assessment unit and sources

Stock SMART ID 15341 is the Washington component assessed in 2021, using data
through 2020. The Oregon and Washington assessments are separate model runs;
their observations and outputs must not be pooled. Amendment 31 defined
separate state units for quillback rockfish. The Council's 2026 Amendment 37
recommendation would retain a Washington-only quillback stock in the federal
Groundfish FMP; federal status should be verified before changing the current
unit crosswalk. This screen records the Washington source component and does
not create a canonical stock.

The assessment reports and native 2021 model archive are cached under
`source_cache/discovery_noaa_quillback_oregon_washington_2021/`. The ignored
`sources.csv` manifest records the download URLs, retrieval date, sizes and
SHA-256 checksums.

| Source | Use |
|---|---|
| [Washington 2021 assessment](https://www.pcouncil.org/documents/2021/12/status-of-quillback-rockfish-sebastes-maliger-in-u-s-waters-off-the-coast-of-washington-in-2021-using-catch-and-length-data-november-2021.pdf/) | Data, fixed biological assumptions, method selection and outputs |
| [Quillback 2021 model files](https://www.pcouncil.org/documents/quillback-rockfish-2021-model-files-zip-file/) | Native Stock Synthesis inputs and Report.sso outputs for California, Oregon and Washington |
| [PFMC Amendment 31 analysis](https://www.fisheries.noaa.gov/s3/2023-08/AM31-Analysis-Final-inPress.pdf) | State-level unit definitions adopted for the 2025–2026 cycle |
| [PFMC Amendment 37 action page](https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-management-and-defining-their-stocks/) | Current Council recommendation and pending federal status |

## Inputs and biological assumptions

The Washington Stock Synthesis model spans 1958–2020 and is a one-sex,
catch-and-length data-moderate assessment with commercial and recreational
fleets. The native `.dat` file contains active length compositions and catch
histories. Its age-composition rows are commented out; the report states that
age compositions were not fit directly and that age and weight samples were
used only to estimate fixed biological parameters. Fishery-independent
abundance indices were not available because sample sizes were inadequate.

The report gives length-at-age, weight-at-age and maturity assumptions based
on biological samples. Natural mortality was fixed at 0.057 per year, based on
a maximum age of 95 years; steepness was fixed at 0.72. The archive's
`Report.sso` provides fitted numbers-at-age and fishing mortality at age, but
there is no age-specific observation series to fit and no abundance index.

## Screening decision

This is a new, distinct 2021 assessment component, but it is **ineligible for
the age-disaggregated source set**: the official base model has no age-composition
likelihood, no annual catch-at-age series, and no abundance index. Its age
samples inform fixed biology only. Population outputs are available, but they
cannot make up for the missing age-specific observations. No canonical stock,
assessment event, input or output was added.
