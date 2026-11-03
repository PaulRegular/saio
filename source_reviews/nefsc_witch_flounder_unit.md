# Witch flounder: catalogue entry and US unit stock

## Identity and assessment selection

The Charbonneau–Keith entry `NEFSC-GARMIII_cynoglossus_5Y` labels a 5Y
component. The official US assessment covers a broader unit, including the
Gulf of Maine–Georges Bank region and areas southward. The 2016 benchmark
draft identifies the assessment's statistical areas, and NOAA describes the
Gulf of Maine–Georges Bank region as a unit stock. The catalogue's 5Y label
does not establish that all values for the official unit are 5Y-only values.
The canonical record therefore retains the catalogue entry separately and
stores the broader unit under `nefsc_witch_flounder_unit`; their relationship
is geographic, not a claim of identical boundaries.

The latest management-track assessment found is the 2024 update through 2023.
Its report was a draft prepared for review; the peer-review panel and council
used the empirical assessment for advice. In 2016 the VPA and ASAP analytical
models were not accepted because of retrospective patterns. The 2024 ASAP
sensitivity is informational and is not the official assessment. The 2026
NEFSC monitoring-data update is a separate, more recent data source; it is
not identified here as a replacement population assessment.

## Recovered data and limitations

The 2024 report's Table 1 provides 2013–2023 commercial landings, discards,
total catch, exploitable biomass and exploitation rate. The survey-based
biomass is normally 0.9 times the average of spring biomass in year y and
fall biomass in year y-1. Spring and fall 2020 and spring 2023 surveys were
missing. Although the report repeats its generic formula for 2023, the peer
review clarifies that 2023 used fall 2022 alone. Exploitable biomass and the
catch/biomass exploitation ratio are not SSB or instantaneous F. The full
annual swept-area biomass inputs and year-specific survey catchability values
have not been recovered, so input and output completeness remain partial.
The report also states a 2024 empirical biomass indicator of 35,270 tonnes
used in the catch-advice calculation; it is retained as a separate output.

The separate 2026 data-update tables provide 1982–2025 commercial landings,
discards and total catches, and 1963–2026 seasonal NEFSC bottom-trawl biomass
indices and CVs. The update uses kg/tow indices; do not substitute them for
the 2024 assessment's swept-area and catchability-adjusted population biomass.
The incomplete 2020 surveys and spring 2023 survey are omitted rather than
invented; fall 2026 had not yet occurred. Sources report rounded values.
The 2024 and 2026 data versions are retained separately because historical
catch estimates differ, for example 2023 commercial discards are 85 versus
89 tonnes. The 2026 data update was presented to the council's SSC; its
status is not treated as an independently fitted assessment.

## Translation decision

The official empirical method does not provide fitted N-at-age, F-at-age,
SSB or recruitment. Neither its aggregate biomass indicator nor a rejected
or informational age-based model can serve as an official age-structured
comparison. A tinyAM translation and dashboard are not supported by the
recovered production assessment.

The assessment, 2026 data update, 2016 benchmark draft and extraction text are
cached with provenance and checksums under `source_cache/ck_nefsc_garmiii_cynoglossus_5y/`.

## Sources

- [2024 management-track assessment report, draft for review](https://d23h0vhsm26o6d.cloudfront.net/13d.-2024_WIT_UNIT_RPT_09_02_203738.pdf), Table 1.
- [2024 management-track peer review](https://www.fisheries.noaa.gov/s3/2024-10/2024-Management-Track-Peer-Review-Panel-Report_10_8_24_508.pdf).
- [2026 unit-stock data update](https://d23h0vhsm26o6d.cloudfront.net/1c_data_update_template_v2_1_2b_witch_flounder.pdf.pdf), Tables 1–2; [SSC meeting materials](https://www.nefmc.org/calendar/oct-7-2026-ssc-meeting).
- [2016 benchmark draft](https://d23h0vhsm26o6d.cloudfront.net/1.8-DRAFT-WitchFl_WP_B1_SAW62_AssessmentReport_Nov9_2016.pdf), stock-unit description.
- [NOAA witch flounder stock description](https://www.fisheries.noaa.gov/new-england-mid-atlantic/science-data/witch-flounder-age-determination-methods-northwest-atlantic).
