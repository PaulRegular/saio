# Pacific Coast Squarespot rockfish: 2021 source screen

## Unit and current assessment

NOAA Stock SMART identifies Squarespot rockfish (*Sebastes hopkinsi*) as
Pacific Coast Stock 10442. Its cached metadata lists the fully accepted 2021
Stock Synthesis assessment (assessment ID 11658, version 3.30.16.00) as the
latest run, using data through 2020. The detailed report is titled for the
California U.S. West Coast. It discusses North and South management complexes
split at 40°10′ N; keep that assessment extent distinct from the broader
Stock SMART label.

## Assessment data and outputs

| Evidence | What the sources support |
|---|---|
| Catch | The model contains annual total removals from 1916–2020 and fishery length compositions. It does not fit catch-at-age or an age-composition likelihood. The report explicitly describes ages as external life-history information, not one of the assessment input data types. |
| Survey | The reference model uses one aggregate biomass index from the NWFSC Hook-and-Line survey and survey length compositions. It does not fit an age-specific survey index or age-composition likelihood. The CalCOFI larval index is a sensitivity, not part of the base model. |
| Age samples | Fishery-independent samples from 2004–2019 inform sex-specific growth/length-at-age parameters. These ages are not an age-disaggregated observation likelihood. |
| Weights and maturity | Sex-specific length-weight relationships are estimated outside the model. The maturity ogive is length-based, with L50 = 14 cm and an assumed slope of -0.95. Age-specific surfaces would be derived from growth, not supplied as direct observed weight-at-age or maturity-at-age input matrices. |
| Mortality | The control file estimates sex-specific natural mortality using a composite life-history prior. The assessment reports median M = 0.133 per year and CV = 0.22. |
| Timing | The native data use one annual season, tag Hook-and-Line index rows with season 9, and set fleet timing to -1. The report does not specify a fractional-year conversion; do not infer one from the survey label. |
| Official outputs | `Report.sso` contains annual numbers-at-age, F-at-age, and catch-at-age. Spawning output is reported in eggs. These fitted outputs do not make the assessment's length-based inputs age-disaggregated. |

## Screen decision

Ineligible for the age-disaggregated source set. The report defines the
category-2 assessment data as removals, length compositions, and
fishery-independent abundance. Its age observations inform life-history
parameters outside the assessment. The native input confirms total catches,
one aggregate survey index, and length compositions, with no age-composition
likelihood. Retain the age-indexed model outputs as audit evidence; do not
convert this assessment into a canonical age-data record.

No canonical database records were
added. The report and model archive provenance, retrieval date, sizes, and
SHA-256 hashes are in
`source_cache/discovery_noaa_squarespot_rockfish_pacific_2021/sources.csv`.

## Sources

- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10442); the pinned metadata snapshot and checksum are in `source_cache/discovery_noaa_stocksmart/sources.csv`.
- [2021 Squarespot rockfish assessment](https://www.pcouncil.org/documents/2021/10/stock-assessment-of-the-squarespot-rockfish-sebastes-hopkinsi-along-the-california-u-s-west-coast-in-2021-using-catch-length-and-fishery-independent-abundance-data.pdf/), especially pp. 2–10, 14, and the model-input description in section 3.2.
- [2021 Squarespot rockfish Stock Synthesis model archive](https://www.pcouncil.org/documents/squarespot-rockfish-2021-model-files-zip-file/), including `SS_LB.dat`, `SS_LB.ctl`, and `Report.sso`.
