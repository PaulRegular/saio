# NOAA Gulf of Mexico cobia — SEDAR 28 Update (2020)

## Assessment and stock unit

The Gulf of Mexico cobia unit (NOAA Stock SMART ID 10390) is separate from the Southern Atlantic cobia unit. The assessment identifies the Florida–Georgia state line as the boundary. The latest detailed Gulf assessment located is the SEDAR 28 Update, completed in June 2020, with input data through 2018. NOAA's 2024 management amendment continued to cite this as the latest assessment. The update uses Stock Synthesis 3.24.

The model is used for status determinations. The assessment review did not accept its results for quantitative OFL/ABC advice. Its management use is recorded with that limitation.

## Sources and imported data

The official assessment and its supporting work papers are cached locally under the ignored source_cache/discovery_noaa_gom_cobia_2020/ directory. The tracked provenance manifest records source URLs, retrieval date, file sizes, and SHA-256 checksums.

- [SEDAR 28 Gulf Cobia Update report](https://sedarweb.org/documents/2019-update-sedar-28-gulf-of-mexico-cobia-final-report/)
- [Recreational survey data work paper](https://sedarweb.org/documents/2019-s28update-wp-02-recreational-survey-data-for-cobia-in-the-gulf-of-mexico/)
- [Length-composition work paper](https://sedarweb.org/documents/2019-s28update-wp-04-gulf-of-mexico-cobia-rachycentron-canadum-commercial-and-recreational-length-compositions/)
- [Headboat index work paper](https://sedarweb.org/documents/2019-s28update-wp-05-standardized-index-of-gulf-of-mexico-cobia-rachycentron-canadum-from-headboat-data/)
- [Commercial discard work paper](https://sedarweb.org/documents/2019-s28update-wp-06-cpue-expansion-estimation-for-total-commercial-discards-of-gulf-of-mexico-cobia-using-reef-fish-observer-data-and-adjustments-to-discard-logbook-estimates-for-florida-east-coast/)
- [Shrimp bycatch work paper](https://sedarweb.org/documents/2019-s28update-wp-07-shrimp-fishery-bycatch-estimates-for-gulf-of-mexico-cobia-1972-2017/)

The database import preserves the report's numerical values and units:

- Table 4 commercial landings by gear, in pounds, and reported annual aggregate landings, in metric tons, 1927–2018.
- Table 5 recreational landings by Historical, FHWAR, MRIP, SRHS Headboat, TPWD, and Louisiana Creel sources, in fish, 1950–2018. Separate source rows are retained. The model aggregate is reconstructed by summing the reported non-missing components for each year and dividing by 1,000, as specified in the report.
- Tables 6 and 7 commercial and recreational discard estimates, preserving the reported gear/source breakdowns and fish counts.
- Table 8 annual shrimp-bycatch source estimates, 1972–2017. The assessment uses a super-period likelihood; these annual estimates are not treated as separate annual model observations.
- Table 9 annual length- and age-sample counts. Its recreational age counts sum to 1,267 for 1987–2002 and 2004–2018; 2003 has no age samples. The report narrative separately says there were 1,266 length-at-age samples. The one-sample discrepancy is preserved rather than adjusted.
- Table 10 normalized shrimp-effort index and its constant log-scale SD, 1945–2018. This is an index of shrimp-fleet effort used to inform shrimp fishing mortality, not an abundance index.
- Table 11 MRIP and SRHS Headboat aggregate relative-abundance indices with their reported log-scale SDs. The numerical table ends in 2018, although the report describes a headboat series through 2019; only tabulated observations are imported.
- Tables 1–3 fixed sex-combined length–weight coefficients, recommended growth parameters, and the age-specific fixed Lorenzen natural-mortality vector. The M vector is scaled using M = 0.38 per year over ages 3–11. The report specifies age 2 as 50% mature, ages 3+ as fully mature, and a 60% female fraction at all ages.
- Tables 13–15 annual exploitation-rate proxy, apical fishing mortality by fleet, biomass, spawning biomass, total abundance, age-0 recruitment, and depletion. The output tables provide point estimates only, so output uncertainty is left blank.

## Remaining source gaps and interpretation

The assessment fits commercial and recreational length compositions and recreational age-at-length compositions conditional on length. The report gives annual sample counts, but the numeric composition cells are presented in figures rather than tables. The reviewed public project files did not include a native Stock Synthesis data file. Therefore no annual age-composition proportions or direct catch numbers-at-age are imported. This is an age-input reconstruction caveat: the imported removals and sample counts do not reproduce the complete observation data supplied to the official model.

Annual numerical N-at-age and age-specific F surfaces were not found. The report provides a numeric total-abundance series and annual apical F by fleet, which are distinct outputs and are retained with those definitions. Table 13 exploitation rate is biomass killed divided by biomass; the report uses it as an F proxy, but it is not instantaneous age-specific F.

The annual model assumes continuous fishing and spawning and does not specify a fractional within-year sampling time. No timing value is added. Fixed maturity and growth inputs can support derived biological quantities, but no direct annual weight-at-age output table or age-specific output uncertainty is reported.

The assessment notes low confidence in its abundance indices and poor fit to age compositions, partly associated with small sample sizes and fixed growth assumptions. Those limitations are preserved as source context; the imported observations have not been altered to improve agreement.
