# NOAA California scorpionfish: Southern California

## Stock and assessment

NOAA Stock SMART ID 10461 is the California scorpionfish (*Scorpaena guttata*) unit south of Point Conception to the U.S.–Mexico border. The 2017 benchmark assessment is the latest full assessment located and uses data through 2016. The July 2025 Pacific Coast Groundfish SAFE continues to report the stock from that assessment. The official report, model archive and SAFE are cached locally; URLs, retrieval date, byte counts and SHA-256 checksums are recorded in `provenance/noaa_california_scorpionfish_southern_california_2017/manifest.csv`.

The model is Stock Synthesis 3.30.05.03, with one area, two sexes, ages 0–21 and modeled years 1916–2016. Age 21 is the terminal age group.

## Inputs

The native archive supplies 620 annual catch-biomass observations from six commercial and recreational fleets over 1916–2016. The source values are metric tonnes. The six 2016 fleet catches sum to 74.18561 tonnes, consistent with the report's rounded 74-tonne landings. Native catch error values are retained as `log_catch_sd`; non-calendar `-999` sentinel rows are omitted.

The archive contains 160 index observations in eight fleets: RecPR, RecPC, RecDD, Sanitation, NWFSCTrawl, GillnetSurvey, SCBSurvey and RecPCOBR. All are recorded in July, represented as within-year time 0.5. Stock Synthesis unit code 0 denotes numbers and code 1 denotes biomass. The numerical observations and log-scale standard deviations are retained without rescaling. Where the data file does not state a physical index unit, the database records that limit rather than assigning one.

The 233 native length-composition records cover 1970–2016. They retain source sex and partition codes, bin labels, `Nsamp`, source year sign and row identity. The 29 negative-year records are preserved under their absolute calendar years and marked as excluded from the official likelihood. For sex code 0, the female vector contains the combined-sex composition and the male vector is ignored by Stock Synthesis. For sex code 3, the female and male vectors are retained separately as the joint sex-by-length distribution. No frequencies are normalized or reconstructed.

The archive also supplies 198 NWFSC bottom-trawl conditional age-at-length records from 2005–2016. The input contains female and male raw age counts for ages 0–21, length bounds 14–39, source sample size, partition code and age-error code 1. The paired age vectors sum to each source row's `Nsamp`. The database stores these as sex-specific cells while preserving the shared source sample size and joint-sex origin. These are conditional samples, not an unconditional age distribution or age-specific abundance index.

The model generates age-specific weights from sex-specific growth and length-weight relationships. Maturity is specified as a length-based logistic relationship. The base model fixes natural mortality at 0.235 per year for both sexes. The report's 0.164 value is a separate low-M sensitivity state, not the base-case input.

## Outputs

For 1916–2016, the native `Report.sso` provides spawning biomass, total biomass, age-0 recruitment, and N-at-age by sex. Total abundance is derived by summing reported N-at-age over both sexes and ages 0–21. The archive also provides total mortality and natural mortality at ages 0–20 and fleet-, sex- and age-specific model catch-at-age. Fishing mortality is derived as reported Z-at-age minus reported M-at-age for matching years, sexes and ages. Model-generated catch-at-age is stored as an output; it is not treated as an observed catch-at-age input.

The cached run does not include a covariance or uncertainty file. No SEs or confidence intervals are assigned to the imported time series or age surfaces. Inputs and outputs are therefore marked partial: direct fishery catch-at-age and an unconditional age-specific survey index are not supplied, several biological quantities are model-generated functions rather than independent input vectors, and uncertainty is unavailable.

## Sources

- [2017 California scorpionfish assessment](https://www.pcouncil.org/documents/2017/01/status-of-california-scorpionfish-scorpaena-guttata-off-southern-california-in-2017.pdf)
- [2017 Stock Synthesis model archive](https://www.pcouncil.org/documents/2017-california-scorpionfish-model-files-zip-file/)
- [Pacific Coast Groundfish SAFE, July 2025](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [NOAA Stock Synthesis user manual](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html), for index unit and composition sex-code definitions.
