# Sole in Division 7.e: 2026 ICES XSA assessment

## Selection and source coverage

The 2026 WGCSE assessment is the latest detailed production assessment located for `sol.27.7e`. It is an XSA assessment fitted through 2025; 2026 aggregate recruitment and SSB are short-term forecasts. The detailed chapter identifies FLR-FLXSA and provides tables for catch numbers-at-age, catch weights, stock weights, tuning data, N-at-age, F-at-age and annual summaries. The pinned public ICES advice repository contains assessment scripts, but the report states that the TAF data repository is private. No native fitted model object was recovered.

The Charbonneau–Keith metadata record already identifies the stock as ICES-WGSCE, `Solea solea`, area 7.e. The database now records the official code `sol.27.7e` and the name Western English Channel common sole.

## Inputs

Table 21.2 supplies landings numbers-at-age in thousands of fish for ages 2–12+ during 1969–2025. Table 21.3 supplies landings weights-at-age and Table 21.4 supplies stock weights in kg per fish over the same grid. Table 21.11 supplies maturity by age, with age 12 as the plus group. M is fixed at 0.1 per year for every age.

Table 21.6 contains four active tuning fleets among six listed series. The 2026 settings table uses UK-CBT-late, UK-COT, Q1SWBeam-nonoffset and FSP-UK, with ages 3–11. The source tuning format stores effort followed by age-specific catch numbers. Following FLCore's `readIndicesVPA` convention, the fitted index is catch-at-age divided by effort. The database preserves the raw numerator and effort separately and labels the reconstructed per-effort series as `reconstructed_source_input`. The index scale multiplier and physical count/effort units are not stated, so values are not rescaled.

The assessment settings specify q plateau age 7, lognormal tuning fleets, a tricubic 15-year time taper, and fleet-specific timing windows. The translation uses the window midpoints, filters to the official fleet year and age ranges, excludes Q1 2022, and omits zero-valued indices that tinyAM's lognormal observation model cannot represent. It does not apply the XSA time taper. These differences remain visible in the stock recipe and dashboard background.

## Outputs and cross-checks

Tables 21.8 and 21.9 provide 1969–2025 N-at-age and F-at-age for ages 2–12+. Table 21.10 provides rounded annual recruitment, total biomass, SSB, landings and unweighted Fbar for 1969–2025. The official SAG XML provides higher precision for annual recruitment, total biomass, SSB and Fbar, including 2026 forecast recruitment and SSB; the 2026 total biomass and Fbar fields are blank and are not imported.

The reported N, stock weights and maturity reproduce Table 21.10 total biomass and SSB within 0.04% over 1969–2025. The import therefore records the SAG annual series as native source outputs and the reported total-numbers series from Table 21.8, without uncertainty. The total column can differ by one thousand fish from the sum of rounded age rows. No age-specific confidence intervals are supplied. The 2026 forecast rows are kept separate from the 1969–2025 fitted period by `terminal_year` and output notes.

## Discovery inventory screening

The ICES 2026 inventory entry sol.27.7e matches this existing Division 7.e stock and is screened eligible. The latest detailed XSA report supplies age-disaggregated catch and tuning inputs, age weights and maturity, fixed M, timing windows, fitted N/F at age, and annual summary outputs; no native fitted object was located.
