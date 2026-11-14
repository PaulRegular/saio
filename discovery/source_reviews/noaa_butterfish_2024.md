# NOAA Butterfish, 2024 Management Track

## Stock unit and assessment

NOAA Stock SMART 10187 is the single U.S. butterfish (*Peprilus triacanthus*) management unit from the Gulf of Maine to Cape Hatteras. The 2024 Management Track is the latest detailed production assessment found, using data through 2023. The June 2024 peer-review panel concluded that the assessment met its terms of reference and represented the best scientific information available. The Mid-Atlantic Fishery Management Council's June 2026 stock-status summary still identifies the 2024 assessment as the basis for butterfish status. SASINF listings for 2025 and 2026 contain data-update materials, not later production assessments.

## Inputs captured

The 2024 SASINF archive reports catch and biological series in `2024_BUT_UNIT_TAB_ALL.pdf`:

- Table 1 gives landings, historic discards, estimated discards, foreign catch, and total catch in metric tons for 1965-2023. Table 2 repeats estimated discards and total catch with CVs for 1989-2023. The 1989-2023 total-catch input uses Table 2 values; these can differ by 1 mt from the Table 1 totals rounded from the components. Catch components are retained as source partitions, not as separate model fleets.
- Table 3 gives total-catch mean weight at ages 0-4+ in kg/fish for 1989-2023. The report identifies age-4+ weight interpolations in 1996-1997 and the age-0 weight interpolation in 2017.
- Table 4 gives total-catch age proportions on the weight basis for ages 0-4+ in 1989-2023. Values are retained as printed; source rounding is not renormalized. Raw sample counts and fitted effective sample sizes are not provided.

Tables 5-10 report survey totals and age-specific mean numbers per tow. The current model presentation lists five survey series:

- NEFSC fall Albatross, 1989-2008;
- NEFSC fall Bigelow, 2009-2023, with 2017 and 2020 missing;
- NEFSC spring Bigelow, 2009-2022, with 2020 missing; the incomplete 2023 spring survey covered only Georges Bank and is not included;
- NEAMAP spring, 2008-2023, with 2017 and 2020 missing; and
- NEAMAP fall, 2007-2023.

The tables report age-specific values for ages 0-4+. These rows and the corresponding aggregate totals are linked representations of the survey series, not independent duplicate indices. The model inventory does not include NEFSC spring Albatross, although older-year values appear in the support tables, so those unused series are not imported. The assessment also uses a young-of-the-year index for 2003-2023, but its numerical values were not recovered from the public 2024 archive.

## Model assumptions and outputs

The 2024 presentation identifies WHAM, model years 1989-2023, ages 0-4+, one fishery with selectivity blocks for 1989-2013 and 2014-2023, and selectivity fixed at 1 for age 3. It describes numbers-at-age as random effects with AR(1) correlation over years and independent processes across ages, and a logistic-normal age-composition likelihood. The model uses annual maturity ogives and a spawning fraction of 0.5. The short report states that scalar M = 1.278 per year was carried forward from the 2020 ASAP4 management-track model. It also says q = 0.2 for the NEFSC fall Albatross survey is required to scale the population based on availability, but does not clarify whether q was fixed or estimated. The 2024 reference-point recruitment stanza begins in 2010; the report says this change affects reference points, not fitted annual recruitment.

Table 11 reports annual SSB, fully selected F at age 3, and age-0 recruitment for 1989-2023, each with a CV. The numeric estimates are imported; their CVs are recorded in the output notes rather than the `se` field. The public support archive does not provide annual fitted N-at-age or F-at-age arrays.

## Remaining source gaps

- No fitted 2024 WHAM object or complete native input files were found.
- Numerical annual values for the current maturity ogives are not in the public archive; older-run maturity values were not substituted.
- The numerical young-of-the-year index is absent from the support tables.
- Run-matched fractional survey times, age-composition weights/effective sample sizes, and the exact conversion from the reported weight-basis catch proportions to the model's fitted composition are not documented in the public archive.
- Age-specific uncertainty for the survey indices and population outputs is unavailable.

The canonical assessment is therefore partial: recoverable inputs and outputs are retained, while unavailable series and specifications remain explicit gaps.

## Sources

- NOAA Stock Assessment Support Information, 2024 butterfish Level 2 archive: [2024_BUT_UNIT.zip](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=16&stock_id=6&review_type_id=2&filename=2024_BUT_UNIT.zip). The support tables, report, and presentation are included in the archive.
- 2024 June Management Track Peer Review Panel Report: [NOAA Fisheries PDF](https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf).
- 2026 MAFMC stock-status summary: [Stock-status PDF](https://static1.squarespace.com/static/511cdc7fe4b00307a2628ac6/t/6a22f8f34ed3ff7106e06f41/1780676852144/00_Stock-Status-2026-06.pdf).
- Butterfish 2021 Research Track Assessment Report, consulted for the assessment's lineage and prior methods: [SASINF PDF](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=16&stock_id=6&review_type_id=5&info_type_id=5&map_type_id=&filename=Butterfish_2021_Assessment_Report.pdf). Older-run numerical values were not used to fill 2024 gaps.

Source-file URLs, retrieval dates, revisions, and SHA-256 checksums are recorded in `provenance/discovery_noaa_butterfish_2024/sources.csv`; the downloaded files are in the ignored local source cache.
