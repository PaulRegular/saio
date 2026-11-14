# NOAA South Atlantic Snowy Grouper — SEDAR 36 Update (2021)

## Stock and assessment

NOAA Stock SMART unit 10339 is the South Atlantic Snowy Grouper assessment unit. Its current scientific name is *Epinephelus niveatus*; the SEDAR report also uses *Hyporthodus niveatus*. This is distinct from snowy grouper units outside the South Atlantic.

The latest completed detailed assessment located for this unit is the SEDAR 36 Update report, revised in January 2021, with assessment data through 2018. It uses the Beaufort Assessment Model (BAM), an annual statistical catch-age model. Population tables include 2019 as the first projection year. The earlier SEDAR 36 WP15 model files are for the superseded 2013 benchmark and are not used as inputs for this update.

## Inputs recovered

- **Removals:** Table 2 reports annual landings and dead discards combined for 1974–2018. Commercial handline and longline are in 1,000 lb whole weight; general recreational removals are in 1,000 fish. Early longline cells shown as missing remain absent.
- **Abundance indices:** Table 3 reports aggregate MARMAP chevron-trap, MARMAP vertical-longline and headboat indices with annual CVs. Chevron-trap and vertical-longline values begin in 1996; headboat values run from 1978 through 2010. The index multiplier is not stated, so values and CVs retain the reported scales.
- **Composition sample sizes:** Tables 4 and 5 report fish and trip counts for length and age compositions by fleet and survey. These are sample counts, not age-composition observations.
- **Biology and mortality:** Table 1 reports mid-year length and whole weight, female maturity, proportion female, and fixed age-specific natural mortality for ages 1–25+. Length CV was estimated by the assessment; the other listed quantities were treated as inputs. The assessment treats males as mature and describes the M pattern as an age-based Charnov curve scaled to M = 0.08 at age 56.
- **Composition gap:** The report shows observed composition inputs in figures but does not provide the annual numerical composition matrices in its tables. No values were digitized or reconstructed for this import. Therefore the age-composition likelihood inputs and any catch-at-age reconstruction from those compositions remain unavailable.

## Outputs recovered

Tables 6–16 were imported where the report provides numeric values:

- Tables 6 and 7: start-of-year abundance-at-age and biomass-at-age, totals included, for 1974–2019. The 2019 rows are labelled as assessment projections; age 25 is the 25+ group. Recruitment is retained as the reported age-1 abundance.
- Table 8: annual apical F, F/FMSY, total biomass, biomass/unfished biomass, SSB, SSB/SSBMSY, SSB/MSST, and the estimated proportion of mature fish that are female. The 2019 row reports biomass and the female proportion but not F or SSB.
- Table 9: terminal-year selectivity-at-age by fleet and survey, plus the reported fleet-average selectivity.
- Tables 10 and 11: fully selected fleet F and total fishing mortality-at-age through 2018.
- Tables 12–15: estimated removals-at-age and annual removals by fleet through 2018, in numbers and whole weight.
- Table 16: base-run benchmark estimates and the reported Monte Carlo/Bootstrap medians and SEs for reference points and summary ratios. Those SEs are kept with the corresponding benchmark medians; they are not annual time-series uncertainty.

The annual population and mortality tables provide point estimates without annual confidence intervals. No uncertainty values were inferred.

## Completeness

The assessment is recorded as **partial** for inputs, assumptions and outputs. Inputs are partial because numerical composition matrices and update-specific native input files were not recovered. Outputs preserve the available annual point estimates and Table 16 benchmark summaries, but annual uncertainty is not reported.

The record retains source units and fleet/survey identities. No commercial whole-weight observations were converted, no missing composition values were filled, and no survey timing fraction was assigned. SSB is the total mature biomass of males and females at peak spawning in mid-year; the report does not specify an exact within-year timing fraction for the annual indices.

## Source files and provenance

The revised report and two SEDAR 36 Update working papers are cached locally in the ignored directory source_cache/noaa_snowy_grouper_sedar36u_2021/. Their source URLs, revisions, retrieval timestamps, byte sizes and SHA-256 checksums are recorded in provenance/noaa_snowy_grouper_sedar36u_2021/manifest.csv.

- [SEDAR 36 Update assessment page](https://sedarweb.org/assessments/sedar-36-update-south-atlantic-snowy-grouper/)
- [Revised SEDAR 36 Update assessment report (January 2021)](https://sedarweb.org/documents/2020-update-sedar-36-update-assessment-report-south-atlantic-snowy-grouper-revised-january-2021-2/)
- [SEDAR 36 Update WP01: recreational survey data](https://sedarweb.org/documents/2020-sedar36u-wp01-general-recreational-data_satl_snowy_grouper_22apr20/)
- [SEDAR 36 Update WP02: management history](https://sedarweb.org/documents/2020-sedar-36u-wp02-snowy-grouper-management-history-2-18-2020/)
- [Original SEDAR 36 assessment page](https://sedarweb.org/assessments/sedar-36/)
