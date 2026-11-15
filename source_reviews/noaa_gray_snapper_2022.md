# NOAA Gulf of Mexico gray snapper: SEDAR 75 source review

**Reviewed:** 2026-11-10
**Stock:** NOAA Stock SMART 10221, Gulf of Mexico gray snapper (*Lutjanus griseus*)
**Assessment:** SEDAR 75 operational Stock Synthesis assessment, data through 2020; completed in 2022 and accepted by the Gulf SSC for advice in January 2023.

## Stock unit and source files

The assessment unit extends from the Texas/Mexico border east to the Atlantic side of Monroe County, including Florida Bay and adjacent fishing areas. It is distinct from the South Atlantic gray snapper unit. SEDAR 75 is the latest completed detailed operational assessment located for this Gulf unit; the next external update was scheduled for 2027, not completed at this review.

The final assessment report and its supporting landings, life-history, and abundance-index papers are cached locally under `source_cache/discovery_noaa_gray_snapper_2022/`. Their URLs, retrieval details, and SHA-256 hashes are recorded in `provenance/discovery_noaa_gray_snapper_2022/sources.csv`.

## Inputs recovered

- **Age-composition inputs:** The accepted model covers ages 0-28, with composition bins through 21+. It uses commercial vertical-line and longline, recreational private, and recreational charter/headboat compositions. Recreational shore compositions were removed during model development. The report presents the accepted compositions as figures rather than numeric age-frequency vectors, so no composition values or sample sizes have been transcribed as model inputs.
- **Fleet landings:** SEDAR 75 Tables 14-19 provide annual model input values and log-scale errors for three commercial fleets and three recreational fleets over 1945-2020. Commercial values are million pounds whole weight; recreational values are thousand fish. These are aggregate fleet totals, not catch-at-age observations.
- **Discard observations:** Tables 6-7 provide annual discard counts and row-specific log-scale errors for commercial vertical line/longline and recreational fleets over the reported years. The values and units are transcribed as printed (`fish`); the report also says the Stock Synthesis inputs were in thousands of fish. The table values are retained without an inferred rescaling, and this unit discrepancy remains unresolved.
- **Abundance indices:** Tables 8-9 provide seven standardized annual relative-abundance series and their log-scale standard errors. The age-0 FWRI FIM index covers 1998-2020, and the age-1 FWRI FIM index covers 1996-2020; the other five series are retained at their reported ages and years. Source scales are preserved. Survey months are described in supporting papers but are not converted into an annual sampling-time value here.
- **Natural mortality:** Table 3 provides the fixed base-case M vector for ages 0-28, reported as the same for males and females. The printed base values are retained; the upper and lower sensitivity values are not treated as uncertainty intervals.

The imported observation-error values follow the detailed source tables. There are two unresolved report discrepancies: Tables 14-16 show commercial landings log-SE 0.05 and Tables 17-19 show recreational log-SE 0.1, while captions for Tables 4-5 describe different values; Tables 6-7 print varying discard log-SEs while the narrative says a fixed value of 0.3. Imported rows preserve the detailed table entries and identify these conflicts rather than choosing an undocumented replacement.

## Outputs recovered

Table 13 provides annual estimates for 1945-2020 of total biomass, age-2+ biomass, SSB, age-2+ abundance, age-0 recruitment, and SSB relative to unfished SSB. Table 35 provides the age-2+ biomass harvest rate for the same years. Values are rounded as published. The report does not provide uncertainty intervals for these annual output series, so no output SEs or intervals are recorded. The Table 35 harvest rate is not instantaneous F.

## Remaining source gaps

Numeric fitted N-at-age and instantaneous F-at-age arrays were not located. The report and supporting life-history paper describe growth, weight-length, and functional-maturity methods, but the complete model-ready annual/age-specific weight and maturity surfaces were not recoverable from the reviewed sources. These gaps are why the canonical input, assumption, and output completeness statuses remain **partial**.

The imported values are the assessment's published input and output tables. No fitted values have been substituted for missing observations or biological inputs.
