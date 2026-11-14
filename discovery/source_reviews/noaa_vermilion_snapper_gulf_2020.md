# NOAA Gulf of Mexico vermilion snapper

## Unit and assessment selected

NOAA Stock SMART identifies `NOAA:10256` as Gulf of Mexico vermilion snapper
(*Rhomboplites aurorubens*). `NOAA:10257` is the separate Southern Atlantic Coast
unit and is not combined with it.

Stock SMART's latest row is assessment 13023 (2023), labelled a Stock Monitoring
Update and reviewed as “Accept previous approach, remand new attempt.” The Gulf
Council's 2023 interim analysis used the G-FISHER video index to consider updated
catch advice; the SSC motion to accept the analysis and recommend revised catch
advice failed. This is not a new accepted age-structured assessment.

The February 2025 SEDAR Steering Committee summary records the Gulf Council's
recommendation for a vermilion snapper update in 2027. This is a future schedule
recommendation, not a completed assessment or a replacement for SEDAR 67. The
August 2025 committee summary's vermilion assessment scheduled outside SEDAR is
under its South Atlantic section and is not evidence about the Gulf unit.

The latest full accepted age-structured run located is Stock SMART assessment
10102, the operational Stock Synthesis model from SEDAR 67. Its final report was
updated in July 2020 and the model's terminal data year is 2017. The final report
prints the assessment input files in Appendix A, including the SS3 data, control,
starter, and forecast files. The report and executive summary retain the official
model's aggregate population outputs.

## Inputs and assumptions

- One sex, one model area, and ages 0-14; age 14 is the plus group. The model has
  one season and assumes fishing and spawning occur continuously through the year.
  Fishing and fishery recruitment begin at age 1; age-0 fish are represented in
  population dynamics but are not directly fished or observed in the fishery data.
- Commercial east and west handline catches are in metric tons; recreational
  catches are in thousands of fish. The bycatch fleet's 0.001 catch entries are
  Stock Synthesis placeholders, not measured removals. The accepted DAT file
  contains catch totals and fishery age compositions, not a catch-at-age matrix.
- The DAT file contains 64 age-composition samples across the three fishery
  fleets, with 14 observed bins (ages 1-14, with age 14 the plus group), source
  sample sizes, and age-error code 1. These are composition samples, not
  age-specific abundance indices. The model also has 24 length-composition
  samples across its fleets; source length-bin units are not stated in the
  printed DAT file.
- The accepted model includes aggregate index observations for all nine SS3
  fleets: commercial east and west, recreational, bycatch, east and west
  headboat, larval, video, and SEAMAP groundfish. The unit codes distinguish
  biomass, numbers, fishing mortality, and a special larval index. These are
  aggregate series, not age-specific survey abundance. The five survey fleets
  use timing code 1 in the DAT file, but its conversion to a proportion of year
  is unresolved.
- Growth, weight-length, maturity, and egg-production parameters are fixed in
  the printed CTL file. Their native parameter values are recorded as
  assumptions; no age-specific weight or maturity surface is derived. Spawning
  output is egg production based on female proportion, maturity, fecundity, and
  spawning frequency; it is not biomass SSB.
- Natural mortality is a fixed age-specific Lorenzen vector scaled to an average
  of 0.25. Table 3 reports values for ages 0-15; age-0 mortality is adjusted for
  the assumed midyear birth date. The source table's age 15 value is retained
  without remapping to the model's age-14 plus group.
- The 2023 G-FISHER index update is a separate interim analysis and must not be
  merged into the SEDAR 67 likelihood or output series.

## Available outputs and limitations

Table 18 reports annual total biomass (metric tons), spawning output (eggs), total
abundance (thousands of fish), and recruitment (thousands of fish) through 2017.
Tables 16-17 report annual fleet fishing mortality and total harvest rate, not
numeric F-at-age. The report plots N-at-age but does not provide a numeric N-at-age
table or downloadable fitted population arrays. The aggregate population table
does not include annual uncertainty estimates.

The source record is eligible for detailed curation because the official report prints the accepted run's final inputs and comparable aggregate outputs. Catch totals and composition samples are distinct source observations. Age-specific weights require calculation from fixed biology; spawning output is egg-based, and exact survey timing remains unresolved.

## Data imported to the database

SEDAR 67 Table 18 has been transcribed for 1950-2017: total biomass, egg-based spawning output, total abundance, age-0 recruitment, and depletion (spawning output divided by unfished spawning output). These are rounded point estimates; the table provides no annual uncertainty, numeric N-at-age, or numeric F-at-age series. Spawning output remains in eggs and is not converted to biomass SSB.

The final report's Appendix A prints the run-matched Stock Synthesis data and
control files. The database now contains 2,494 input rows: 272 annual catch
records and their native catch_se fields; 243 aggregate index observations and
their log SDs; 132 discard observations and their native Std_in fields; 64 age
compositions across 14 age bins; 24 length compositions across 12 source bins;
and the 16 fixed Table 3 M-at-age values. Fixed growth, weight-length, maturity,
fecundity, timing, and source-code settings are recorded as assumptions.

The data remain partial for translation: catch totals and age compositions are
not combined into catch numbers at age; there is no age-specific abundance
index or age-specific survey composition; source length-bin units and survey
timing conversion are unresolved; and age-specific weight/maturity surfaces
are not derived. The source rows preserve the model's separate likelihood
inputs and native codes.

## Sources

- [SEDAR 67 final stock assessment report](https://sedarweb.org/documents/sedar-67-gulf-of-mexico-vermilion-snapper-final-stock-assessment-report/),
  updated July 2020.
- [SEDAR 67 Gulf Council SSC review](https://sedarweb.org/documents/report-of-the-gulf-of-mexico-ssc-review-of-the-sedar-67-vermilion-snapper-assessment/),
  June 1, 2020.
- [SEDAR 67 executive summary](https://sedarweb.org/documents/sedar-67-gulf-of-mexico-vermillion-snapper-executive-summary-report/).
- [Gulf Council September 2023 SSC meeting page](https://gulfcouncil.org/meetings/september-2023-standing-reef-fish-socioeconomic-and-ecosystem-ssc-meeting/)
  and its [meeting minutes](https://gulf-council-media.s3.amazonaws.com/uploads/2025/05/GMFMC-SSC-September-2023.pdf)
  and [summary](https://gulf-council-media.s3.amazonaws.com/uploads/2025/02/Gulf-Standing-RF-Socio-Eco-SSC-Summary-Sept-2023-10082023.pdf).
- [SEDAR Steering Committee February 2025 summary](https://gulf-council-media.s3.amazonaws.com/uploads/2025/04/I-4a-STC_Feb2025_Summary_v4_with_graphics.pdf),
  which records a Gulf Council recommendation for a 2027 update. The August 2025
  committee summary's vermilion schedule is under South Atlantic and was not applied
  to this Gulf unit.
- NOAA [Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10256)
  metadata snapshot cached with the discovery inventory.

Reviewed 2026-11-10. The source files and checksums are recorded in the ignored
local cache at `source_cache/discovery_noaa_vermilion_snapper_gom_2020/sources.csv`.
