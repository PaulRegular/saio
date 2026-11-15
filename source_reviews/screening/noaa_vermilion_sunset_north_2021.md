# Vermilion and Sunset rockfishes, Northern California — 2021

## Assessment unit and source selection

NOAA Stock SMART identifies the Northern California Vermilion/Sunset complex as a distinct assessment unit. The 2021 benchmark covers U.S. waters off California north of Point Conception through the California–Oregon border and combines vermilion rockfish (*Sebastes miniatus*) with sunset rockfish (*S. crocotulus*). It is distinct from the Southern California, Oregon and Washington assessments. The 2021 assessment and model archive are the latest detailed assessment sources located for this unit; the 2025 Pacific Coast Groundfish SAFE and current Stock SMART status material were checked for later assessment activity.

The assessment report, native model archive and STAR panel report are cached under `source_cache/discovery_noaa_vermilion_sunset_north_2021/`. Source URLs, retrieval date, file sizes and SHA-256 checksums are recorded in `provenance/noaa_vermilion_sunset_north_2021_sources.csv`.

## Inputs and assumptions

- The Stock Synthesis model has one area, two sexes, one annual season and ages 0–70, with age 70 as the accumulator. The fitted data span 1875–2020; 2021 is forecast.
- The native catch block has 542 annual fleet-year observations from 1875–2020. Fleets 1–3 report biomass in metric tonnes; fleets 4–7 report numbers in thousands of fish. Catch standard deviations are retained as supplied. The model does not use a catch-at-age series.
- Five aggregate abundance-index series contribute 77 observations. Their source units are Stock Synthesis code 0 (numbers); each has month code 7, represented as 0.5 of the annual cycle. The model does not use an age-specific abundance index.
- The model includes 205 length-composition rows in 10–70 cm lower-edge bins at 2 cm spacing. Of these, 178 use combined-sex vectors and 27 use joint female/male vectors.
- The 224 age-composition rows span ages 0–70; 208 are conditional age-at-length samples and 16 are marginal age-composition samples. Four rows use a combined-sex vector and 220 use joint female/male vectors. The native frequencies, signed year/fleet codes, sample sizes, partitions, conditioning lengths and age-error codes are retained without normalization. Conditional age-at-length values are biological composition observations, not annual catch-at-age.
- Natural mortality is estimated separately by sex. The fitted uniform parameters are 0.0855991 per year for females (SE 0.00828715) and 0.0804851 per year for males (SE 0.00879103). The public output surface contains finite M-at-age values for ages 13–69.
- Growth is sex-specific and estimated. The model uses length-based maturity and fecundity and a fixed length-to-weight relationship; the archive does not provide observed maturity-at-age or an empirical weight-at-age input series. Model-derived weight-at-age is available in the fitted output files.

## Reported and fitted outputs

The public `Report.sso` supplies fitted numbers-, biomass-, fishing-mortality-, natural-mortality- and weight-at-age surfaces by sex for 1875–2020. It also supplies annual total biomass, egg-based spawning output and age-0 recruitment through the 2021 forecast. Total abundance was derived by summing the official beginning-of-year N-at-age surface over both sexes and ages; it has no separate uncertainty estimate.

Report Tables II and III provide approximate 95% asymptotic intervals for spawning output and recruitment in 2011–2021. Table II also gives the fraction of unfished spawning output and its interval. Spawning output is measured in million eggs and must not be relabeled as spawning-stock biomass. The report does not provide age-specific uncertainty intervals.

The report's printed recent series are checked against the annual values in `Report.sso` before import. The canonical assessment is marked partial because direct catch-at-age, an age-specific abundance index, observed maturity-at-age and empirical weight-at-age inputs are not available in the reviewed sources.

## References

- [2021 assessment report](https://www.pcouncil.org/documents/2022/01/the-status-of-vermilion-rockfish-sebastes-miniatus-and-sunset-rockfish-sebastes-crocotulus-in-u-s-waters-off-the-coast-of-california-north-of-point-conception-in-2021-december-2021.pdf/)
- [2021 Northern California model files](https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-nca-zip-file/)
- [2021 STAR panel report](https://www.pcouncil.org/documents/vermilion-and-sunset-rockfishes-stock-assessment-review-star-panel-report/)
- [2025 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock)
