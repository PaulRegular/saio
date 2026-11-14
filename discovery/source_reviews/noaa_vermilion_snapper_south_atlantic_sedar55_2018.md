# South Atlantic vermilion snapper, SEDAR 55

## Unit and assessment

NOAA Stock SMART identifies stock 10257 as South Atlantic vermilion snapper
(*Rhomboplites aurorubens*), distinct from Gulf of Mexico vermilion snapper
(stock 10256). The latest accepted full assessment located for this current
unit is SEDAR 55 (2018), using the Beaufort Assessment Model base run
`VSX.tpl`. The fitted observations extend through 2016; model estimates extend
through 2017. The 2023 interim analysis did not replace this full assessment.

The final SEDAR report and working papers document the assessment inputs. The
final commercial age-composition addendum presents its values as figures, so
the draft numeric table is not used as final data. Exact model-ready inputs and
outputs were recovered from the NOAA NMFS Office of Science and Technology
`stockplotr` repository's pinned `VermilionSnapper.rdat` artifact. Its metadata
identifies SEDAR 55, `VSX.tpl`, and the 2023-02-27 output file. This is a
machine-readable fit object, not original model source code or raw sampling
records. Its N-at-age and biomass-at-age values for 1946 agree with SEDAR 55
Tables 6 and 7 after the published unit conversions.

## Inputs captured

- Annual landings and discards are retained in their source fleet scales.
  Commercial landings are 1000 lb whole weight; recreational landings and
  discard series are 1000 fish. Discard observations are recorded before
  fleet-specific discard mortality.
- Five aggregate relative abundance indices and their source CVs are included:
  commercial handline, headboat, general recreational, SERFS chevron trap/video,
  and MARMAP Florida snapper trap. The SERFS survey also has an age composition,
  but no age-specific abundance index is reported. A single within-year
  sampling fraction was not found for these series.
- Age compositions are captured for commercial handline, headboat, general
  recreational, and SERFS trap/video observations. Length compositions are
  retained for the fleets supplied by the fit object. The age range is 1-12+;
  age 12 is the plus group. Effective sample sizes are stored on composition
  rows, with raw fish counts kept separately when available. Some length
  compositions have no reported positive effective sample size, which remains
  blank.
- The age-error transition matrix is retained without renormalizing its
  rounded source values. Columns represent true ages and rows represent
  observed ages.
- The fit object supplies mean length, whole weight, female maturity, female
  proportion, combined reproductive potential, and fixed age-specific M for
  ages 1-12+. M is an input, not an estimated annual output.

## Outputs and limits

The fit object supplies N-at-age, biomass-at-age, F-at-age, total abundance,
age-1 recruitment, total biomass, apical F, and egg-production SSB through
2017. SSB is reported in 1e12 eggs at mid-year and is not mature biomass in
tonnes. The output artifact does not provide age-specific standard errors or
intervals. Some length-composition effective sample sizes, the original model
code, raw sampling records, and a common index timing fraction were not
recovered. The assessment remains marked partial to reflect these gaps.

## Sources

- [SEDAR 55 final assessment report](https://sedarweb.org/documents/sedar-55-stock-assessment-report-south-atlantic-vermilion-snapper/)
- [SEDAR 55 commercial age and length compositions (WP06)](https://sedarweb.org/documents/s55wp06-commercial-age-and-length-compositions-for-u-s-vermilion-snapper-rhomboplites-aurorubens/)
- [SEDAR 55 life-history update (WP03)](https://sedarweb.org/documents/s55wp03-update-of-vermilion-snapper-rhomboplites-aurobens-reproductive-life-history-from-the-marmap-serfs-program/)
- [Pinned NOAA NMFS OST model artifact](https://github.com/nmfs-ost/stockplotr/blob/1bd3ec5dfbb544c19d319f7fd24d2628c57c7721/inst/extdata/VermilionSnapper.rdat)
- [SAFMC SSC October 2023 report](https://safmc.net/documents/fc1_a1e_ssc_oct2023_final_report-pdf/), reviewed to distinguish the interim analysis from a new full assessment.

Source files, retrieval dates, revisions, sizes, and SHA-256 checksums are
recorded in `provenance/discovery_noaa_south_atlantic_vermilion_snapper_2018/sources.csv`.
