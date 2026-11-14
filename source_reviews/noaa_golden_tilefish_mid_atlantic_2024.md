# NOAA Mid-Atlantic golden tilefish, 2024

## Assessment and sources

NOAA Stock SMART unit 10385 is the Mid-Atlantic golden tilefish stock. It is separate from the Gulf of Mexico and South Atlantic golden tilefish units. The 2024 management-track WHAM assessment used data through 2023 and is the latest detailed production assessment located for this unit. The management-track panel review and council materials identify the assessment as the run used for advice.

The NOAA assessment report itself is marked “draft working paper for peer review only.” That publication label is retained here as a source caveat. The report's Table 1 provides the source-reported assessment catches and 2014–2023 SSB, fully selected fishing mortality at age 6, and age-1 recruitment. The report says its model results use iid random effects on N-at-age and full selection at ages 5 and 6 in the second selectivity block.

The final input and results PDFs and the NOAA SASI unit archive were also reviewed. The archive contains reports, diagnostic graphics, and a presentation, but no native WHAM fit object or machine-readable input arrays. Retrieval dates, URLs, sizes, and SHA-256 checksums are recorded in `provenance/noaa_golden_tilefish_mid_atlantic_2024/manifest.csv`; the files are cached locally under the ignored `source_cache/discovery_noaa_golden_tilefish_2024/` folder.

- [NOAA 2024 management-track assessment report](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&filename=2024_Golden_Tilefish_Report_07_02_132018.794267.pdf)
- [NOAA management-track peer-review panel report](https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf)
- [NOAA final input-data graphics](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=final_input_data.pdf)
- [NOAA final results graphics](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=final_results.pdf)
- [NOAA SASI assessment archive](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&filename=2024_GT_UNIT.zip)

## Values recorded

The database preserves the annual “Catch for Assessment” values in Table 1 for 2014–2023. The table also reports commercial landings, commercial discards, and recreational landings as components. Their displayed sum differs from the reported assessment total by 1 mt in 2016, 2018, and 2022, so the assessment total is retained as published rather than recalculated.

Thirty annual output rows preserve Table 1 point estimates for SSB, fully selected F at age 6, and age-1 recruitment for 2014–2023. The table does not provide annual uncertainty for these values. The support graphics show additional N-at-age and F-at-age trajectories and uncertainty plots, but the underlying numeric values were not available in the archive and have not been digitized here.

## Remaining source gaps

The final input graphics show catch age compositions, three commercial LPUE series, age-specific catch and stock weights, maturity, and natural mortality. Their numeric likelihood arrays and biological vectors were not found in a machine-readable source. The numeric age-specific N and F surfaces and annual output uncertainty are also not tabulated. The catch series before 2014 is not given in the assessment's summary table.

The record is therefore partial: the source-reported aggregate catch and several official population/mortality outputs are preserved, but the age-disaggregated inputs needed to reconstruct the full assessment remain unresolved. No tinyAM translation is attempted from these partial records.
