# DFO Atlantic herring, NAFO 4VWX

## Assessment and source selection

The Charbonneau-Keith row `ck_dfo_mar_harengus_4vwx` identifies DFO Atlantic herring in NAFO areas 4VWX. DFO treats 4VWX as a management unit containing several distinct spawning and fishery components. The stock label and area now identify those distinctions explicitly.

The latest published advice located is DFO Science Response 2025/026, *4VWX Herring Stock Status Update to 2024*. It reports landings, component-level acoustic indicators, and a 2022-2024 three-year mean acoustic SSB index of 296,430 t against the 317,846 t limit reference point. It gives no catch advice. The current CSAS schedule lists a March 31, 2027 assessment for the SWNS/BoF component with an update of indices for 4VWX; no results from that process were published as of October 23, 2026.

The 2022 assessment used a management strategy evaluation (MSE) framework for the Southwest Nova Scotia/Bay of Fundy (SWNS/BoF) component. The 2022 Science Advisory Report says other spawning components continue to be reported using indicators from the 2018 assessment. The detailed 2018 evaluation (Research Document 2020/062) describes the stock-wide advice as indicator-based rather than a single analytical age-structured assessment. The 2019 data-input report (Research Document 2020/028) documents commercial catch and age data, acoustic surveys, biology, and other candidate inputs.

The 2022 MSE is component-specific. Its public conditioning report (Research Document 2023/022) links to a GitHub repository with input RDS/CSV files and scripts to build reference and sensitivity operating models. The pinned local snapshot is commit `515857664de2719f7fd1b227b41862b82673ac56`. Direct inspection confirms that its catch history ends in 2018, catch-at-age covers 1970–2018 and acoustic age data cover 1999–2018. Catch ages are 1–11 with four base fleets (gillnet, other, purse seine and weir/shut-off), plus an alternative five-fleet arrangement that splits purse seine. The repository does not contain saved fitted operating-model state surfaces. DFO's 2024 update explicitly says the production reference operating models were conditioned through 2020. This archive therefore cannot be treated as the complete production input set or used to generate official 2022 states without recovering the missing update.

## Imported 2025 indicator update

`dfo_herring_4vwx_2025_indicators` is a **summary-only**, applied record with
all completeness statuses partial and `is_current = FALSE`. No current
detailed production assessment has yet been populated. The importer
`scripts/database/144_import_dfo_herring_4vwx_2025_summary.R` uses only the
verified 2025 PDF; it does not read numerical inputs from the older archive.

The 68 input records preserve SWNS/BoF landings for 2020–2024 in the original
rounded kilotonnes, coastal component landings and acoustic indices for
2015–2024, and the available 2024 offshore landings and German Bank/Scots Bay
annual index. Components remain separate. Pre-2020 catch report-year labels
are retained without assuming an exact calendar period. Published zeros
remain zero; missing acoustic surveys are not replaced by zeros.

The reported 2022–2024 German Bank/Scots Bay mean of 296,430 t is retained as
`acoustic_SSB_index_three_year_mean`. It is not assigned to the standard SSB
measure. Acoustic spawning-biomass indices are survey information, not a
recovered stock-wide fitted N/F/M surface. No uncertainty, age allocations or
survey timing fractions are invented. The 2025 report corrects the 2021–2024
Scots Bay turnover calculation, so its indicators must not be appended to an
older series without reviewing those revisions.

## Translation readiness

The available materials do not yet identify one production fitted N/F/M-at-age surface for the complete 4VWX management unit. The 2022 framework is an ensemble of alternative operating models for only SWNS/BoF, while other components are represented by separate indicators. Treating one reconstructed operating model as a stock-wide official assessment would change the assessment scope and select one scenario from the reference set without an official basis.

The partial 2025 import does not provide age-specific observations or biological surfaces for a tinyAM fit. A component-specific approximation requires the actual production input update and official reference OM outputs, with ensemble and population definitions resolved. No fitting, source-based starting values, or dashboard has been attempted. Source tests verify the reported values, units, component separation and that the acoustic indicator does not become a fitted SSB comparison.

The source PDFs and pinned code/data archive are cached under `source_cache/ck_dfo_mar_harengus_4vwx/`; checksums and URLs are recorded in `accessible_sources_manifest.csv`. The cache remains local and gitignored.

## Sources

- [DFO Science Response 2025/026: 4VWX Herring Stock Status Update to 2024](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4130293x.pdf)
- [DFO Science Response 2024/030: Stock Status Update of 4VWX Herring for the 2024 Fishing Season](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41251349.pdf)
- [DFO Science Advisory Report 2022/050: 2022 Assessment of 4VWX Herring](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41087719.pdf)
- [DFO Research Document 2020/062: 2018 Evaluation of 4VWX Herring](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40951686.pdf)
- [DFO Research Document 2020/028: 2019 SWNS/BoF Herring Framework Data Inputs](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40946265.pdf)
- [DFO Research Document 2023/022: Framework for Conditioning SWNS/BoF Herring Operating Models](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41206903.pdf)
- [Pinned public operating-model repository](https://github.com/z5a1n/herring_OM_conditioning/tree/515857664de2719f7fd1b227b41862b82673ac56)
- [Current CSAS assessment schedule](https://csas-scas.dfo-mpo.gc.ca/)

