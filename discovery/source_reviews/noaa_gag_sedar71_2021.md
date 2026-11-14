# NOAA South Atlantic Gag Grouper — SEDAR 71 (2021)

## Stock and assessment

NOAA Stock SMART 10349 identifies the South Atlantic Gag Grouper unit
(*Mycteroperca microlepis*). It is distinct from Gulf Gag Grouper (Stock SMART
10348), which has its own candidate unit and SEDAR 72 review.

The latest completed assessment located for the South Atlantic unit is the
SEDAR 71 operational assessment, published in April 2021 and fitted through
2019. It is an integrated statistical catch-age model implemented in BAM. The
current successor, SEDAR 106, was planned for 2026 with a 2024 terminal year,
but the project page says the start was delayed and no new schedule has been
posted. This is therefore a review of SEDAR 71, not the unfinished SEDAR 106
work.

## Inputs and outputs located

The assessment report tabulates annual fleet landings and dead discards for
1962–2019, in 1,000 lb gutted weight for commercial landings and 1,000 fish for
recreational landings and discards. It fits annual age compositions for
commercial handline, commercial diving and headboat fleets; figures show the
observed age proportions, and Tables 4–5 give fish and trip sample sizes.
The report does not provide these fishery composition arrays as machine-readable
numeric tables, so catch-at-age requires digitizing observed proportions and
combining them with source catch totals and age-specific weights.

The model fits two aggregate abundance indices: headboat through 2019 and the
SERFS video index from 2011–2019. Table 3 provides annual values and CVs.
SEDAR 71 WP04 reports MARMAP/SERFS chevron-trap age counts and percentages for
1990–2002 and 2004–2019, along with total fish and deployments. These are survey
age-composition samples that support the index/selectivity work; they are not a
direct age-specific abundance index. The source report's Table 4 count values
and Table 5 percentages disagree in eight shared age-year cells. Both tables
were imported independently as published, without using one to correct or fill
the other. The count table reports ages 1–14 and 16; the percentage table
reports ages 1–10, 12–14 and 16. Age 11 is absent from Table 5 and age 15 is
absent from both tables. Table 4 leaves age 1 in 2017 and age 3 in 2019 blank;
those cells remain missing rather than being treated as zero.

The report supplies age-specific whole weight, female maturity and sex ratio,
and natural mortality. Female maturity is logistic with age at 50% maturity
estimated near 4.6 years; all males are treated as mature. M is fixed over time,
declines with age under a Lorenzen curve, and is scaled over fully selected ages
5+ so survival to age 30 matches a constant M = 0.15. The age-specific mortality
and biology tables allow the reported assumptions to be represented directly.

Imported numeric outputs include abundance-at-age, biomass-at-age, total
biomass, SSB, recruitment, status indicators, terminal selectivity, fleet
fully-selected F, and estimated fleet landings/discards. Tables 6–14 provide
the reported values through 2019; the 2020 values shown in Tables 6–8 are
identified as first-year projections. The report does not provide annual
uncertainty for these outputs. The source tables provide selectivity and
fully-selected fleet F rather than a full numeric F-at-age time series, and
run-matched native assessment files were not located.

The database record is partial. Verified numerical inputs and outputs from the
detailed report and working papers are imported, but observed fishery
age-composition proportions remain available only as figures. Catch-at-age is
therefore not reconstructed. The reported chevron compositions are retained as
supporting source data, not converted into an age-specific abundance index.

## Source files and provenance

The five official SEDAR PDFs listed below are cached in the ignored local
directory source_cache/noaa_gag_sedar71_2021/.
Their retrieval date, URLs, cited revision, byte sizes, and SHA-256 checksums
are recorded in that directory's manifest.csv.

- [SEDAR 71 assessment page](https://sedarweb.org/assessments/sedar-71/)
- [SEDAR 71 stock assessment report (April 2021)](https://sedarweb.org/documents/sedar-71-stock-assessment-report-south-atlantic-gag/)
- [SEDAR 71 WP04: chevron-trap index and age/length compositions](https://sedarweb.org/documents/sedar-71-wp04-gag-fishery-independent-index-of-abundance-and-age-length-compositions-in-us-south-atlantic-waters-based-on-a-chevron-trap-survey-1990-2019/)
- [SEDAR 71 WP03: reproductive parameters](https://sedarweb.org/documents/sedar-71-wp03-gag-grouper-mycteroperca-microlepis-reproductive-parameters-in-support-of-the-sedar-71-assessment/)
- [SEDAR 71 WP05: general recreational survey data](https://sedarweb.org/documents/sedar-71-wp05-general-recreational-survey-data-for-gag-in-the-south-atlantic/)
- [SEDAR 71 WP02: standardized video counts](https://sedarweb.org/documents/sedar71-wp02-standardized-video-counts-of-southeast-u-s-atlantic-gag-mycteroperca-microlepis-from-the-southeast-reef-fish-survey/)
- [SEDAR 106 South Atlantic Gag assessment project](https://sedarweb.org/assessments/sedar-106-south-atlantic-gag-grouper/)
- [NOAA InPort report record](https://www.fisheries.noaa.gov/inport/item/65068)

The canonical database now includes the SEDAR 71 stock and assessment, reported
assumptions, numeric inputs, and reported outputs. Completeness remains partial
because the fishery age-composition proportions and annual output uncertainty
are unavailable as numeric tables.
