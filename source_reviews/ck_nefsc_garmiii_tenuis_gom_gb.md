# White Hake (Gulf of Maine–Georges Bank)

## Assessment and source selection

The stock record is ck_nefsc_garmiii_tenuis_gom_gb (Charbonneau–Keith identifier NEFSC-GARMIII_tenuis_GOM, GB), White Hake (*Urophycis tenuis*) in the Gulf of Maine–Georges Bank area. The current detailed record is NOAA NEFSC's 2025 Management Track update, ASAP 3.0 Run_005, with data through 2024. The final September 2025 peer-review panel report concluded the assessment met its terms of reference and represented best scientific information available for management. The run archive includes the native RUN_005.DAT input and a 25-page table supplement. The SASI working paper is marked draft for peer review; its status is made clear here and it is used for detailed input/output tables alongside the final review decision.

The 2022 Management Track assessment updated the 2013 SAW56 benchmark and provides background on model history. Attempts to cache those NOAA Institutional Repository PDFs returned Access Denied. Their NOAA links and the failed retrievals are recorded in the local source-cache manifest; no 2022 or 2013 numerical values are mixed into the 2025 record.

## Model and inputs

The ASAP input covers 1963–2024, ages 1–9+ and a sex-combined stock. The single combined catch fleet has catch biomass in every model year and catch numbers-at-age with effective sample size 58 for 1989–2024; the source catch-age ESS is zero before 1989. The source discard and release arrays are zero. The age-specific catch numbers are stored in thousands of fish, with a total-catch biomass observation in metric tons and a separate annual CV. Multiplying catch numbers by the matrix-1 age weights gives an internal cross-check against observed total catch. The supporting report's Table 5 labels its catch-at-age table in metric tons while repeating the native age values; the native ASAP field structure and the weight-based cross-check support the thousands-of-fish interpretation used here. This table-label inconsistency remains a source caveat.

The model fixes natural mortality at 0.20 yr-1 for ages 1–9+. Maturity is fixed by age. Three annual weight matrices are retained: matrix 1 is assigned to catch, matrix 2 to SSB and all five surveys, and matrix 3 to start-of-year biomass. SSB is calculated at 0.25 of the year. The two fishery selectivity blocks are 1963–1997 and 1998–2024 and use age-specific selectivity; fully selected F is the unweighted mean over ages 6–9+.

All five model indices are included: NEFSC spring and fall bottom trawl, ASMFC shrimp trawl, and NEFSC spring and fall bottom longline. The native index and age-composition units are numbers. Survey timing is April (0.25), July (0.50), or October (0.75), as specified by the ASAP input month codes. Aggregate indices have separate CVs; age-composition effective sample sizes are retained on the age rows. Annual q deviations are inactive in Run_005. Exact index observations, age rows, weights, timing, and sample sizes are retained in the database.

The production input fixes Beverton-Holt steepness at 1 (initial value 1, phase -3), estimates the recruitment scaler (phase 3) and annual log recruitment deviations (phase 4), and sets the recruitment-deviation likelihood weight to zero. Expected recruitment is therefore constant, independent of SSB. The supplied annual recruitment CV of 0.5 does not impose a recruitment penalty when its weight is zero. The ASAP3 technical documentation confirms the equation and the sum-to-zero fixed-effect deviation vector; these are not integrated random effects.

Older cohorts follow deterministic survival under F + M, with accumulation into age 9+. Initial older-age abundances are estimated in phase 2. NAA Deviations Flag 1 selects a penalty reference formed from expected first-year recruitment and first-year survival, including the terminal plus-group divisor. Its likelihood weight is 1 and its CV is 0.2; the documented objective includes all initial ages in the log-residual norm. This flag does not activate annual older-cohort process error. Neither tinyAM's deterministic exponential initialization nor unpenalized free initialization reproduces this penalty exactly.

These meanings were checked against the author's ASAP3 technical documentation (pp. 3-5, 31, 41-44, including the printed ADMB implementation) and user manual (phase conventions). Both are cached from `cmlegault/ASAPplots` revision `75adfd7cf889a5a2b66b6ef0a4dbe22b51aa2084`, with URLs and SHA256 checksums in `ASAP_manual_manifest.csv`. They establish method semantics; only Run_005 supplies the production settings. The NOAA toolbox archive contains an installer only, which was not executed. Its separate manifest records the inspected revision and checksum.

## Reported outputs and remaining gaps

Table 14 reports annual SSB, fully selected F, age-1 recruitment, and their CVs for 1963–2024. The database retains those estimates and converts each reported CV to an approximate natural-scale SE as estimate multiplied by CV; the source CV is repeated in the row notes. This is a derived uncertainty scale, not a separately reported SE.

Table 3 in the same 2025 working paper reports a 2025-2028 management projection under the FMSY-proxy harvest scenario for 2026-2028. It identifies the 2025 catch (1,802 t) as the NEFMC Groundfish Plan Development Team estimate, not a fit output. The table reports SSB bounds as 5th and 95th percentiles; no SE or point-estimate summary is specified. The database stores catch, SSB, and fully selected F projections separately from the historical 1963-2024 series; projected F is 0.144 in 2025 and the scenario value 0.176 in 2026-2028. A pinned NOAA Stock SMART snapshot (revision 664c4237, SHA-256 141db3599cbf37af3e019bd53d2323d829a719b273e8ab0226b73f6ad18620b0) independently reproduces the 2025 SSB estimate of 13,385 t. It corroborates that value only; the snapshot contains no Fmort value for 2025.

The public run archive did not include a numerical ASAP .rep output. No full fitted N-at-age or F-at-age surface was found in the report tables. Those outputs and their uncertainty remain unavailable; figures are not digitized and estimates are not reconstructed from SSB or recruitment. The output status is therefore partial.

## Sources

- [Final September 2025 Management Track Peer Review Panel Report](https://www.fisheries.noaa.gov/s3/2025-11/September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf)
- [2025 White Hake assessment working paper and report tables](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&filename=2025_HKW_UNIT_RPT.pdf)
- [2025 Run_005 ASAP input](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=RUN_005.DAT)
- [2025 White Hake run archive](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3&filename=2025_HKW_UNIT.zip)
- [NOAA Stock SMART snapshot](https://github.com/NOAA-EDAB/stocksmart/tree/664c4237e26520b260a090e1821a2cee5d1cdf07), assessment_id 14071; the locally cached data file and checksum are recorded in the stock-specific manifest.
- [2022 Management Track assessment](https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf)
- [2013 SAW56 White Hake assessment summary](https://repository.library.noaa.gov/view/noaa/4374/noaa_4374_DS1.pdf)
- [ASAP3 technical documentation and printed implementation](https://raw.githubusercontent.com/cmlegault/ASAPplots/75adfd7cf889a5a2b66b6ef0a4dbe22b51aa2084/pdf/Technical_Documentation_for_ASAP3.pdf)
- [ASAP3 user manual](https://raw.githubusercontent.com/cmlegault/ASAPplots/75adfd7cf889a5a2b66b6ef0a4dbe22b51aa2084/pdf/User_Manual_for_ASAP3.pdf)

The local, gitignored source cache and checksums are recorded in source_cache/ck_nefsc_garmiii_tenuis_gom_gb/manifest.csv.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/ck_nefsc_garmiii_tenuis_gom_gb.md). They do not determine source completeness or official run selection.
