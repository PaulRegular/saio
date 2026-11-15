# NOAA Oregon quillback rockfish, 2021

## Assessment unit and sources

Stock SMART ID 15340 is the Oregon component assessed in 2021, using data
through 2020. The Oregon and Washington assessments are separate model runs;
their observations and outputs must not be pooled. Amendment 31 defined
separate state units for quillback rockfish. The Council's 2026 Amendment 37
recommendation would retain a Washington-only quillback stock in the federal
Groundfish FMP. Its final status should be checked before treating Oregon as a
current assessment target; this record documents the Oregon source component,
not a new canonical stock.

The assessment reports and native 2021 model archive are cached under
`source_cache/discovery_noaa_quillback_oregon_washington_2021/`. The ignored
`sources.csv` manifest records the download URLs, retrieval date, sizes and
SHA-256 checksums.

| Source | Use |
|---|---|
| [Oregon 2021 assessment](https://www.pcouncil.org/documents/2021/12/status-of-quillback-rockfish-sebastes-maliger-in-u-s-waters-off-the-coast-of-oregon-in-2021-using-catch-and-length-data-december-2021.pdf/) | Data, fixed biological assumptions, method selection and outputs |
| [Quillback 2021 model files](https://www.pcouncil.org/documents/quillback-rockfish-2021-model-files-zip-file/) | Native Stock Synthesis inputs and Report.sso outputs for California, Oregon and Washington |
| [PFMC Amendment 31 analysis](https://www.fisheries.noaa.gov/s3/2023-08/AM31-Analysis-Final-inPress.pdf) | State-level unit definitions adopted for the 2025–2026 cycle |
| [PFMC Amendment 37 action page](https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-management-and-defining-their-stocks/) | Current Council recommendation and pending federal status |

## Inputs and biological assumptions

The Oregon Stock Synthesis model spans 1892–2020 and is a one-sex, catch-and-
length (SS-CL) data-moderate assessment with commercial and recreational
fleets. Its active likelihood uses length compositions; the native `.dat` file
contains age-composition material in commented lines, explicitly marked as
exploratory and not for the final model. The report confirms that age
compositions were not fit directly. Age and weight data, including coastwide
WCGBTS samples, were used only to estimate fixed biological inputs. The 2021
archive has no abundance-index observations, and the report says fishery-
independent indices lacked adequate sample sizes.

The report provides source-based length-at-age, weight-at-age and maturity
assumptions. Natural mortality was fixed at 0.057 per year, based on a maximum
age of 95 years; steepness was fixed at 0.72. Those biological values and age
samples do not constitute annual catch-at-age observations or an age-specific
abundance index. The archive's `Report.sso` does provide fitted numbers-at-age
and fishing mortality at age, plus spawning-output and recruitment outputs.

## Screening decision

This is a new, distinct 2021 assessment component, but it is **ineligible for
the age-disaggregated source set**: the official base model has no age-composition
likelihood, no annual catch-at-age series, and no abundance index. Its age
samples inform fixed biology only. Population outputs are available, but they
cannot make up for the missing age-specific observations. No canonical stock,
assessment event, input or output was added.
