# Georges Bank yellowtail flounder

## Stock and assessment selection

This is the combined US–Canada Georges Bank stock of *Limanda ferruginea*, Charbonneau–Keith `DFO-NEFSC_ferruginea_GB`, retained under `ck_dfo_nefsc_ferruginea_gb`. The latest production assessment recovered is the 2025 NEFSC WHAM management-track update, with observations through 2024 and projections through 2028. It updates the 2024 research-track model selected after peer review.

The published 2025 unit report is still labelled “draft working paper for peer review only”. Its production status is independently supported by the Council's final Framework 72 submission, which states that the 2025 management-track assessment was approved for management. The database preserves this caveat rather than treating the draft label as proof that a different model should be imported.

`nefsc_yellowtail_georges_bank_2025` is a partial summary record, with `is_applied = TRUE` and `is_current = FALSE`. A summary-only document is not promoted to the current detailed run simply because no detailed production run has yet been populated. The unresolved detailed-data gap remains explicit.

## Critical distinction between model runs

The public 2024 `GB_runs` archive contains directories for `Constant_M` and `Age_based_M`. The recoverable numerical `fit_input.RDS`, N-at-age tables, F-at-age tables and parameter tables belong to **Constant_M**. The `Age_based_M/res_tables` directory has no numerical tables; that run is represented by plot images. The final 2024 peer review selected the revised age-based-M model. The model-selection document in the public archive confirms this change.

Consequently, none of those constant-M inputs or outputs is imported as the official 2024 or 2025 model. In particular, they cannot supply a missing natural-mortality vector, official N/F surface or a replacement maturity schedule. The 2025 assessment explicitly updated the maturity ogive, so copying the earlier candidate's biology would mix runs even if some other data were unchanged. No tutorial WHAM data or re-fitted candidate estimates are substituted.

The new research archive accompanying Kittel et al. (2026), DOI
`10.1139/cjfas-2025-0289`, was checked on 2026-10-24. Its public Zenodo record
`19443644` contains `GBK.DAT`, `WHAMcode.R`, `BT.csv` and a README. All four
files were cached and checked against the archive's published MD5 values;
the local manifest also records SHA256 checksums. The data header identifies
an earlier research-track input: 50 years from 1973 through 2022, six ages,
and all 300 supplied natural-mortality entries equal to 0.4. The visible WHAM
preparation call supplies no M-model override. The paper describes a research
comparison of environmental/recruitment formulations, not a verified copy of
the selected revised age-based-M production run. Its methods text describes
data through 2021, whereas the archived file extends through 2022; that
discrepancy is retained rather than resolved by dropping a year. These files
are useful source leads, but do not close the production-run gap and are not
imported as official inputs or used to generate replacement official outputs.
They are retained under `source_cache/ck_dfo_nefsc_ferruginea_gb/zenodo_19443644_research/`
with the original record metadata and `manifest.csv`; the section check is
recorded in `zenodo_research_review.log` in the stock cache. Downloaded scripts
were inspected as text, not executed.

## Verified recovered values

The importer extracts all ten annual columns from 2025 Table 1, covering 2015–2024:

- combined catch biomass in tonnes;
- native, unadjusted SSB in tonnes;
- reported fully selected F, labelled `Ffull`, for ages 4–6;
- age-1 recruitment in thousand fish.

Component landings and discards are used only to check the independently rounded assessment catch total, allowing a one-tonne printed-rounding difference. They are not treated as additional fitted fleets or used to invent catch-at-age. At 2024 the report gives catch 12 t, SSB 713 t, Ffull 0.017 per year and recruitment 534 thousand fish. The mean/median convention for the annual point estimates is not identified in Table 1.

The terminal approximate 90% confidence regions are retained for SSB (491–1034 t) and Ffull (0.012–0.025). No SE is inferred. The rho-adjusted terminal SSB of 684 t and Ffull of 0.017 are separate output measures, not replacements for the unadjusted annual series. Table 3's 2025–2028 SSB and F projections remain labelled projections. Its interval level and construction are not stated and are not assumed to match the historical 90% regions.

The source model uses a Beverton–Holt recruitment relationship with bottom-water-temperature effects, three surveys (NEFSC spring and fall, DFO spring), and correlated fishery-selectivity dynamics. The report notes missing 2023 NEFSC spring observations and unavailable calibration for the 2022 DFO survey. Exact survey timing, numerical revised maturity, complete annual weights and age-based M, age compositions, likelihood weights and production N/F-at-age remain unrecovered.

## Validation and translation decision

All three completeness statuses remain partial. No tinyAM translation or comparison dashboard is claimed: aggregate catches do not provide catch-at-age, and the selected production biology cannot be filled from the rejected candidate. Ffull is not relabelled as an arithmetic or population-weighted Fbar; its precise averaging convention remains unresolved. The useful next source is a native age-based-M production input/output archive or matching official numerical tables.

The focused source test checks every Table 1 output, terminal intervals, adjusted/native separation, projection years, units, recruitment age, partial statuses and the absence of candidate-run provenance or invented age states. The source cache remains gitignored. `manifest.csv` records current URLs, retrieval times, SHA-256 checksums and the NOAA download restriction with its successful Council-hosted alternative. Earlier cached archives without original retrieval provenance are retained for investigation; their numerical candidates are not canonical sources for this production record.

The source test, central reference-alignment test, plus-group reference test and canonical database validation pass. At the original import checkpoint, the database had 114 stocks, 101 assessments, 2057 assumptions, 350125 inputs and 185611 outputs. All records outside this stock/assessment were unchanged; rerunning that importer left all five canonical files byte-for-byte unchanged. The later research-archive review changes no canonical values. No package or model-mathematics changes were made.

## Sources

- [2025 NEFSC assessment unit report](https://d23h0vhsm26o6d.cloudfront.net/Georges-Bank-Yellowtail-Flounder-Assessment-Update-2025.pdf), Tables 1–3 and pp. 1–3
- [Final 2024 yellowtail research-track peer review](https://www.fisheries.noaa.gov/s3/2024-12/Panel-Summary-Report_Yellowtail-Flounder_508_final_12_12_2024.pdf), [accessible Council copy](https://d23h0vhsm26o6d.cloudfront.net/10b.-Panel-Summary-Report_Yellowtail-Flounder_508_final_12_12_2024.pdf)
- [Framework 72 final submission, April 2026](https://d23h0vhsm26o6d.cloudfront.net/260423_Groundfish_FW72_SIR_FINAL-Submission.pdf), assessment adoption and status-determination sections
- [NOAA assessment supplementary information portal](https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php), public 2024 research-track and 2025 management-track materials
- [Kittel et al. (2026) research paper](https://doi.org/10.1139/cjfas-2025-0289) and [associated research archive](https://zenodo.org/records/19443644); excluded as unverified production data.

## Additional 2025 historical trajectories

NOAA Stock SMART assessment 14076 supplies annual SSB, fully selected F and
age-1 recruitment for 1973–2024 and total catch for 1935–2024. All 2015–2024
values agree with the report table within its rounding; the report's values
and confidence limits remain unchanged. The earlier values were added from
the machine-readable source. Catch before the 1973 model start is historical
context, not a fitted observation. F is rounded to three decimals to remove
binary storage noise; uncertainty is not inferred. These aggregate series
do not supply missing age compositions or change the translation blocker.

The NOAA [Stock SMART snapshot](https://github.com/NOAA-EDAB/stocksmart/tree/664c4237e26520b260a090e1821a2cee5d1cdf07)
is cached with its pinned revision and checksum in `stocksmart_manifest.csv`.
