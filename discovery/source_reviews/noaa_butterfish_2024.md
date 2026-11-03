# NOAA Butterfish, 2024 Management Track

## Identity and run

NOAA Stock SMART 10187 is the U.S. butterfish (*Peprilus triacanthus*) management unit spanning the Gulf of Maine to Cape Hatteras. No existing canonical record or matching candidate unit was found. The 2024 Level 2 Management Track is the latest production assessment located, with data through 2023. SASINF lists a 2025 Data Update and a 2026 data/projection update, not later production assessment runs; the result listings are cached with checksums. The June 2024 peer-review panel concluded that the assessment met its terms of reference and represented the best scientific information available. The SASINF report copy still carries a “draft working paper for peer review only” cover, so the review report is retained as evidence of its accepted production use.

## Age-structured inputs and outputs

The 2024 SASINF tables report total catch and its components in metric tonnes through 2023. Table 4 gives total-catch proportions by weight for ages 0, 1, 2, 3, and 4+ over 1989–2023; Table 3 gives mean total-catch weight at age in kg over the same years. Together with total catch, these support source-based catch numbers-at-age reconstruction. The canonical record should preserve the reported totals, proportions, and weights; any conversion to numbers-at-age belongs in a documented downstream step. The report identifies interpolated age-4+ weights for 1996–1997 and an interpolated age-0 weight for 2017.

Tables 6–7 provide NEFSC spring and fall age-specific mean numbers per tow for ages 0–4+ over 1989–2023. Tables 9–10 provide the corresponding NEAMAP spring and fall series, beginning in 2008 and 2007 respectively. Survey totals and CVs are separately tabulated in Tables 5 and 8. The 2021 research-track report describes survey use for its final ASAP3 configuration; the exact run-matched survey and age-index inputs for the updated 2024 WHAM fit are not included in its support archive.

The 2021 Research Track report Table 3.2 shows annual age-0 to 4+ maturity ogives for its final ASAP3 run over 1989–2019. The 2024 update uses WHAM, so that older ogive table is not confirmed as the current WHAM input; it also does not provide numeric 2020–2023 maturity values. The 2024 report states that its model carries forward M = 1.278 from the 2020 assessment. Survey periods are spring/fall; the 2021 ASAP3 configuration identifies spawning fraction 0.5 and month 10 for NEAMAP fall. Exact timing and maturity inputs for the updated 2024 WHAM run remain source follow-up items.

The 2024 Table 11 reports annual SSB (mt), fully selected F at age 3, and age-0 recruitment (millions) over 1989–2023, with CVs. The public 2024 archive does not provide numeric fitted N-at-age or F-at-age arrays. The base-model RDS archive is available for the 2021 research track, not the 2024 update.

## Screening decision

This is a provisional new, eligible source-curation unit: the official 2024 update provides age-specific fishery and survey information, weights, a documented mortality assumption, and annual official outputs. The assessment's native age proportions and their units should be retained. Exact 2024-run biology for 2020–2023, complete survey timing, and the current WHAM fitted object remain unresolved; those are source-record gaps, not grounds to substitute fitted states or values from another run.

## Sources

- NOAA Stock Assessment Support Information (SASINF), 2024 butterfish Level 2 assessment archive: [2024_BUT_UNIT.zip](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=16&stock_id=6&review_type_id=2&filename=2024_BUT_UNIT.zip). Tables 3–11 are in `2024_BUT_UNIT_TAB_ALL.pdf`.
- 2024 June Management Track Peer Review Panel Report: [NOAA Fisheries PDF](https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf).
- Butterfish 2021 Research Track Assessment Report, carried-forward base-model inputs: [SASINF assessment PDF](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=16&stock_id=6&review_type_id=5&info_type_id=5&map_type_id=&filename=Butterfish_2021_Assessment_Report.pdf).
- NOAA Stock SMART inventory record: [Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart).

Source files and SHA-256 checksums are recorded in the ignored local cache at `source_cache/discovery_noaa_butterfish_2024/sources.csv`.
