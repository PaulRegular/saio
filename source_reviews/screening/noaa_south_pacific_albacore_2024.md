# South Pacific albacore (`Thunnus alalunga`), 2024

Review date: 2026-11-09

## Assessment and run

NOAA Stock SMART ID 11688 is a discovery alias for the joint SPC/IATTC South
Pacific albacore assessment. The 2024 assessment extends through 2022 and
covers the WCPFC Convention Area and the eastern Pacific model region. It is
separate from the North Pacific albacore stock.

The pinned SPC repository contains the MULTIFAN-CL input files and TAF exports
for a single diagnostic reference model. The assessment's management advice
uses a 100-model ensemble. The canonical record
`wcpfc_south_pacific_albacore_2024` is partial: the diagnostic inputs and
point-estimate outputs below are preserved, but ensemble output and some
likelihood details are unavailable in the export.

## Inputs and assumptions captured

- **Catch and effort:** 3,288 catch records from 17 extraction fisheries,
  1954–2022. The source fishery flags distinguish catches recorded in fish
  numbers from catches recorded in metric tonnes; the import preserves those
  units. The native effort field is present for 2,744 records. The assessment
  guide describes effort as arbitrary within each fishery and internally
  rescaled; records with no effort and the missing effort for weight-flagged
  fleets are not filled in.
- **Length compositions:** 1,270 fishery/year/season strata with 50 two-centimetre
  length classes (30–128 cm labels), 1965–2022. TAF frequencies are already
  reweighted: extraction-fishery values by catch and index-fishery values by
  relative abundance. The export has no separate raw sample-size field, so
  `sample_size` is blank.
- **CPUE indices:** 169 annual aggregate index observations from three index
  fisheries. These are not age-specific abundance indices. The year- and
  fishery-specific precision multipliers from `alb.frq` are preserved as
  relative precision weights, not converted to CVs. The report specifies a
  generic CV of 0.20 for each series, which is recorded once per series.
- **Conditional age-at-length:** 33 raw 50-length-by-12-age matrices from
  2006–2013, containing 654 aged fish at observed ages 1–10. The matrices and
  sample counts by length interval are preserved without scaling. The source
  applies an effective sample-size multiplier of 0.75; this is recorded as an
  assumption, not applied to the canonical counts.
- **Reproductive potential and growth:** the 50-value vector in `alb.ini` is
  sex ratio multiplied by maturity-at-length and rescaled to one. It is
  therefore retained as reproductive potential, not maturity alone. The
  native length-weight relationship and resulting model-derived biological
  surfaces are recorded separately.
- **Other assumptions:** the import records the annual population and seasonal
  catch structure, recruitment timing, Lorenzen M-at-age specification,
  average M of 0.36 per year at ages 4–12+, maximum age 15, composition
  weighting, and CPUE likelihood description.

The partial import adds 89,720 input rows and 15 assumption rows. It does not
create catch-at-age records: the native assessment uses catches, length
compositions, and conditional age-at-length data.

## Outputs captured

TAF point estimates cover 1954–2022. The import preserves numbers-at-age for
ages 1–12 (age 12 is the plus group) in each of the two model regions, and
annual F-at-age in both regions plus the TAF `all` region series. The output
does not document the aggregation formula for `all`, so it is labelled “All
model regions” and retained separately.

Regional and all-region biomass and spawning biomass, recruitment, catch,
selectivity, growth, weight-at-age, reproductive potential-at-age, and the
diagnostic M-at-age surface are also recorded. Total abundance is derived by
summing the reported N-at-age over the available ages, by region and across
regions; no uncertainty is assigned to these derived values. The output import
contains 6,762 rows. The TAF export has no SEs or intervals, and its values
represent the diagnostic reference model rather than the 100-model management
ensemble.

## Remaining source gaps

- There is no native observed catch-at-age series or age-specific abundance
  index in the reviewed model files.
- Raw sample sizes for the reweighted length-composition frequencies are not
  provided in the TAF export.
- The diagnostic output does not include uncertainty, and the 100-model
  ensemble results are not included in the cached TAF export.
- The aggregation method behind the `area = all` F-at-age output is not
  specified in the export.

These gaps are why input, assumption, and output completeness remain marked
`partial`.

## Sources and local cache

- [WCPFC 2024 assessment (SC20-SA-WP-02 Rev.03)](https://meetings.wcpfc.int/node/23119)
- [WCPFC data-input paper (SC20-SA-IP-05)](https://meetings.wcpfc.int/node/23128)
- [WCPFC longline size-frequency paper (SC20-SA-IP-03)](https://meetings.wcpfc.int/node/23127)
- [Pinned SPC diagnostic model repository](https://github.com/PacificCommunity/ofp-sam-alb-2024-diagnostic/tree/e9640087a9831dece824062a338c21bf81414044)

The PDFs and pinned native/TAF files are cached locally under
`source_cache/discovery_noaa_south_pacific_albacore_2024/`. The tracked
manifest at `provenance/discovery_noaa_south_pacific_albacore_2024/sources.csv`
records URLs, retrieval dates, checksums, and represented model files.
