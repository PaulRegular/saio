# Hoki (HOK 1), 2025 assessment

## Stock and assessment

HOK 1 is one New Zealand management unit. The latest detailed production run is the 2025 assessment, published in 2026, with fitted data through the 2024 fishing year and population estimates for 2025. This review uses the official base model with separate East and West biological stocks. The reported single-stock alternative is a different model structure for HOK 1, not another stock unit.

The assessment uses Casal2 v23.04. Model years run October through September and are labelled by ending year. The annual cycle uses five time steps. Catches are assumed without observation error; the 2025 catch vector repeats 2024 catches for the projection estimate.

## Sources and provenance

- [FAR 2026/04: Assessment of hoki in 2025](https://fs.fish.govt.nz/Doc/26195/FAR-2026-04-Assessment-of-hoki-in-2025.pdf.ashx)
- [FAR 2025/42: Hoki catch, size, and age information used for the 2025 assessment](https://fs.fish.govt.nz/Doc/26136/FAR-2025-42-Catches-size-and-age-structure-2023-24-hoki-fishery-and-input-data-for-2025-stock-assessment.pdf.ashx)
- [Fisheries New Zealand Hoki stock page](https://www.mpi.govt.nz/fishing-aquaculture/fisheries-management/fish-stock-status/hoki-new-zealands-largest-fishery)

The two reports are cached locally under the ignored `source_cache/mpi_hoki_hok1_2025/` directory. Retrieval dates and SHA-256 checksums are in `provenance/mpi_hoki_hok1_2025_sources.csv`. The assessment report embeds the Casal2 base-model input files in Appendix B.

## Inputs recovered

The source import preserves the model's supplied observation forms:

- Aggregate catch biomass for 10 fisheries in model years 1972–2025 (540 records, in tonnes). Year 2025 is the assumed projection catch and duplicates 2024; it is not an additional fitted data year.
- Sixteen multinomial age-composition series (10 fishery and six trawl-survey series), with 293 year-specific samples and 9,618 sex-by-age values. The native input is proportions across male and female categories and ages, not catch numbers-at-age. Raw `error_values` sample sizes are retained; the model's separate `error_value_multiplier`, likelihood, age range, plus-group setting, age-reading error, timing, and related observation settings are recorded as assumptions.
- Six aggregate biomass-index series (three acoustic and three trawl surveys), with 95 observations and their paired source CVs. These are separate index records, not age-specific abundance indices.
- The fixed instantaneous-M vector and its native relative-age-selectivity references. The source vector is retained in model category order and is not expanded into an unsupported M-at-age surface.
- The 16 base-model population categories and their age-length object mapping, plus four sex- and stock-specific von Bertalanffy functions. East male parameters are k = 0.232, t0 = -1.23, and Linf = 89.5 cm; East female parameters are 0.161, -2.18, and 101.8 cm; West male parameters are 0.261, -0.50, and 92.6 cm; West female parameters are 0.213, -0.60, and 104.0 cm. All four use CVs of 0.05 at the first and last ages and time-step proportions of 0.25, 0.60, 0.90, 0.90, and 0.0.
- The shared length-to-weight parameters (a = 4.79e-09, b = 2.89; weight in tonnes) and the East and West April–June immature-to-mature category transition processes. Male age selectivity uses a50 = ato95 = 2; female selectivity uses a50 = ato95 = 3. These are source model settings, not direct weight-at-age or maturity-at-age observations.

Age compositions are not standardized abundance indices. Composition rows sum across the source's male and female categories and ages; plus groups are identified where the source marks them. Index biomass is recorded in tonnes, with CVs on the relative scale. Survey and composition timing is retained using the model's October–September year and source time step. Sampling-time fractions are derived from the model time-step proportions and within-step timing; the conversion is documented in the importer.

## Outputs recovered

FAR 2026/04 Table 10 reports medians of marginal posterior distributions and 95% intervals for unfished spawning biomass (B0) and mid-season 2025 spawning biomass for East, West, and Total, in thousand tonnes. These six reported values are stored with their intervals; no standard errors are inferred from the posterior intervals.

Annual numerical age-specific abundance, fishing mortality, and natural mortality posterior arrays were not located in the report appendices. The report's plots and diagnostics are not transcribed as artificial annual tables.

## Remaining source gaps

The assessment model uses sex-specific growth and length-to-weight functions and stock/sex maturity settings rather than supplying a direct annual weight-at-age and maturity-at-age table. These biological parameters and their complete category mapping still need a source-by-source extraction and validation before inputs can be marked complete. The report's direct age-composition proportions and catch biomass are preserved as fitted inputs; catch numbers-at-age have not been invented by multiplying those quantities or applying unverified weights.

The source record is partial: the report provides biological functions and seasonal maturation settings, but not direct age-specific weight or maturity surfaces. Full annual posterior abundance and mortality outputs also remain unavailable in the reviewed report appendices. Catch-at-age is not directly reported in the recovered base-model inputs; the assessment's age-composition samples are not a substitute. These gaps remain relevant to completeness and comparison, while all values above stay in their native form and are not expanded into unsupported surfaces.
