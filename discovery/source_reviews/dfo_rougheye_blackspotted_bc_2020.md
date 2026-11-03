# DFO B.C. Rougheye/Blackspotted Rockfish

## Stock identity and latest assessment

The DFO Sustainability Survey has one broad “Rougheye Rockfish” entry and no official stock identifier. The latest detailed assessment located is the 2020 Rougheye/Blackspotted Rockfish assessment, published as CSAS Research Document 2022/020. It defines two distinct BC assessment units: REBS north in PMFC areas 5DE and REBS south in 3CD5AB. The northern unit is predominantly Blackspotted Rockfish; the southern unit is predominantly Rougheye Rockfish. The DFO survey row therefore maps to two current units, not one. No canonical stock records for either unit were found. Keep `candidate_unit_id` blank and the identity status ambiguous until the candidate register can represent both assessment units without inventing source identifiers.

This is separate from the NOAA U.S. West Coast Rougheye/Blackspotted assessment (Stock SMART 14516). The units have different jurisdictional and geographic boundaries and must not be merged.

## Assessment inputs and assumptions

The DFO assessment is an annual, sex-specific Awatea catch-at-age model from 1935 to the beginning of 2021, with ages 1–80 and age 80 as the accumulator group. It uses two fisheries: combined bottom/midwater trawl and “Other” (longline, trap, troll and hook-and-line). Catch histories are reconstructed by fishery. The model also uses standardized commercial bottom-trawl CPUE from 1996–2019.

The assessment uses age proportions (weighted age frequencies), not direct annual catch numbers-at-age. The report documents commercial proportions-at-age for REBS north in 19 trawl-fishery years and 6 “Other” fishery years, and for REBS south in 5 trawl years and 1 “Other” year. Survey age proportions cover 7 WCHG years for REBS north and 3 years each for QCS and WCVI for REBS south. The report also documents survey abundance indices and biological inputs. Exact age-composition vectors were not recovered as machine-readable data; the report presents their distributions primarily as figures. Catch-at-age would require a documented conversion using catch, age proportions and weight-at-age.

The composite base cases vary fixed natural mortality values of 0.035, 0.045 and 0.055 and CPUE process error. Recruitment variability is fixed at 0.9 and stock-recruitment steepness at 0.7. The assessment estimates sex-specific growth and selectivity and derives weight-at-age and maturity-at-age from biological samples. The final report describes aging error and model reweighting. The peer-review proceedings note that seamount age observations were excluded from the final stock definition after being included in a draft, and that limited REBS south ages caused poor MCMC diagnostics and required fixed survey selectivity parameters.

The model is annual. Survey series and seasons are described in the report, but the exact within-year timing needed for tinyAM has not been converted to a verified year fraction.

## Outputs and screening decision

The report contains MPD and MCMC results for both units, stock-status summaries, decision tables, and population and age-structure figures. The published report provides comparable aggregate spawning-biomass and recruitment results, but a run-matched machine-readable output object or complete numeric annual age surfaces were not located. Do not digitize plotted age inputs or outputs as if they were original observations.

Screening decision: identity ambiguous and age-data eligibility unresolved. The assessment demonstrably uses catch-at-age information, survey indices, biological inputs and an age-structured population model, but the exact input age-proportion vectors and numeric output series needed for canonical import have not been recovered. The generic DFO inventory row also covers two stock units. Revisit if the source data or Awatea run files become publicly available; do not create two numerical records from the figures alone.

## Sources

- [DFO Research Document 2022/020](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41072091.pdf)
- [DFO Science Advisory Report 2020/047](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40953488.pdf)
- [DFO regional peer-review proceedings](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41033073.pdf)
- Retrieved files, URLs and checksums are recorded in the ignored local `source_cache/discovery_dfo_rebs_2020/sources.csv` manifest.
