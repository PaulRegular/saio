# Southern California cowcod: 2019 source screen

## Unit and assessment

NOAA Stock SMART identifies this unit as Cowcod (*Sebastes levis*) - Southern
California, Stock ID 10443. The PFMC 2019 assessment defines the unit as U.S.
waters in the Southern California Bight south of Point Conception to the
U.S.-Mexico border. It treats that area as one well-mixed stock; it does not
assess Mexican waters. The cached Stock SMART metadata lists the 2019
full-acceptance assessment as the latest run and identifies Stock Synthesis
3.30.13.09. The assessment fits data through 2018 and reports a 2019 estimate.

This is a new unit in the candidate register. No canonical stock or numerical
assessment records were added during screening.

## Evidence in the accepted model

The PFMC page provides the detailed report, its Stock Synthesis model archive,
and the STAR panel review. The archive contains `cowcod2019.dat`,
`cowcod2019.ctl`, and `Report.sso`. The data file identifies a one-sex model
with an age-60 accumulator group; this is the model's age grid, not a claim that
the source samples contain every age in every year.

| Evidence | What the source supports |
|---|---|
| Catch and age data | The model has annual fishery catch totals and length compositions. It uses conditional age-at-length observations from the commercial and recreational fisheries and from the NWFSC WCGBT and Hook-and-Line surveys. The report says the commercial sample is 129 aged fish from 1982–1986, with two lacking lengths; the recreational sample is 131 otoliths from 1975–1981 before exclusions. These are not direct catch-at-age observations. Age composition can be reconstructed only for fleet-years with compatible length and age-at-length inputs, and the pairing and weighting must be documented. |
| Survey information | The model uses aggregate abundance series from six fishery-independent sources and length compositions for several surveys. Conditional age-at-length data occur for the NWFSC WCGBT and Hook-and-Line surveys. These can support an age-specific reconstruction in overlapping survey years, but the assessment does not fit a directly observed age-specific abundance index. |
| Weight and growth | The report gives a weight-length relationship, `W = 9.6788e-6 * L^3.1462`, in kg whole weight and cm fork length. Growth is estimated from survey age and length data. A weight-at-age surface can be reproduced from those model relationships, but is not a standalone observed weight-at-age input table. |
| Maturity | The assessment uses maturity observations for 174 females and length-based biological and functional maturity ogives. Age-specific maturity would require applying the selected ogive to model growth and preserving the maturity definition. |
| Mortality and timing | Natural mortality is estimated with a prior; the accepted base-model estimate is 0.088 per year. The native data file records observation months by fleet and year, so timing is fleet-specific rather than one shared annual fraction. |
| Official outputs | The native `Report.sso` contains annual numbers-at-age, F-at-age, catch-at-age, and biomass-at-age tables. The report also gives spawning output, depletion, deterministic recruitment, and aggregate uncertainty. Spawning output is in eggs and should not be relabeled as SSB in tonnes. |

## Screen decision

Eligible for source curation. The native input archive pairs length compositions
with conditional age-at-length data and the fitted report contains age-indexed
outputs, so an age reconstruction is supportable for the overlapping sampled
fleet-years. The reconstruction would differ from the assessment's original
likelihood, which fits conditional age-at-length and length compositions
separately. It is not a direct catch-at-age likelihood. That difference must
remain explicit in any later source extraction.

Source files, retrieval date, versions,
sizes and SHA-256 checksums are recorded in
`source_cache/discovery_noaa_cowcod_southern_california_2019/sources.csv`.

## Sources

- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10443)
- [PFMC 2019 assessment and model files index](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [2019 cowcod assessment](https://www.pcouncil.org/documents/2019/10/status-of-cowcod-sebastes-levis-in-2019-october-24-2019.pdf)
- [2019 Cowcod Stock Synthesis model archive](https://www.pcouncil.org/documents/cowcod-2019-ss-model-files-zip-file/)
- [2019 Cowcod STAR panel report](https://www.pcouncil.org/documents/2019/10/cowcod-star-panel-report-july-22-26-2019.pdf)
- Dick, E.J. and He, X. (2019). *Status of Cowcod (Sebastes levis) in 2019*, pp. 5, 9–10, 18–22, 24–32, 34–37; Table 44 and the model archive.
