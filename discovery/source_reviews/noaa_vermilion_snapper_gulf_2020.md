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
- Commercial east and west handline catch is in metric tons. Recreational catch is
  in thousands of fish. Catch-at-age is recoverable by combining fleet catches
  with the accepted age compositions in the final SS3 data file.
- Commercial handline age compositions are separate for east and west Gulf areas;
  they are sparse before 2000. Recreational samples from modes and regions are
  pooled into one Gulf-wide composition and begin in 1994. Composition samples
  are reweighted using length-frequency data; these are age compositions, not
  observed catch numbers at age.
- The assessment fits aggregate indices, including recreational headboat CPUE,
  SEAMAP larval abundance, combined video, and SEAMAP summer groundfish. The video
  and groundfish surveys use length compositions; the reviewed run does not provide
  age-specific survey abundance indices.
- Growth, length-weight relationships, and maturity are fixed biological inputs
  carried forward from SEDAR 45. Age-specific weights can be derived from the
  model's growth and length-weight inputs. Spawning output is egg production based
  on female proportion, maturity, fecundity, and spawning frequency; it is not
  biomass SSB.
- Natural mortality is a fixed age-specific Lorenzen vector scaled to an average
  of 0.25. Age-0 mortality is adjusted for the assumed midyear birth date.
- The 2023 G-FISHER index update is a separate interim analysis and must not be
  merged into the SEDAR 67 likelihood or output series.

## Available outputs and limitations

Table 18 reports annual total biomass (metric tons), spawning output (eggs), total
abundance (thousands of fish), and recruitment (thousands of fish) through 2017.
Tables 16-17 report annual fleet fishing mortality and total harvest rate, not
numeric F-at-age. The report plots N-at-age but does not provide a numeric N-at-age
table or downloadable fitted population arrays. The aggregate population table
does not include annual uncertainty estimates.

The source record is eligible for detailed curation because the accepted run's
final input files and comparable aggregate outputs are printed in the official
report. A tinyAM translation will need to distinguish source catch totals and
composition samples from reconstructed age-specific catch, derive age-specific
weights from the fixed biology, preserve egg-based spawning output as a native
definition, and document any survey-timing approximation. No canonical database
values have been imported.

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

Reviewed 2026-10-30. The source files and checksums are recorded in the ignored
local cache at `source_cache/discovery_noaa_vermilion_snapper_gom_2020/sources.csv`.
