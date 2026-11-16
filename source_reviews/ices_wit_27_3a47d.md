# ICES North Sea witch flounder, 2026 assessment

**Stock:** `ices_wit_27_3a47d` (`wit.27.3a47d`)  
**Assessment:** `ices_wit_27_3a47d_2026`  
**Review date:** 2026-11-15  
**Official source:** [WGNSSK 2026, section 23](https://doi.org/10.17895/ices.pub.32676345.v2)  
**Applied model:** SAM, ages 1-10+, terminal assessment year 2025.

This is the current Northeast Atlantic witch flounder unit in Subarea 4 and divisions 3.a and 7.d. The pinned [ICES 2026 assessment repository](https://github.com/ices-advice/2026_wit.27.3a47d/tree/030bc61156d1369af85e77afd8f7c17d1d50ca0a/2026_wit.27.3a47d_assessment) identifies the applied run. The numerical input objects are not in the public code archive.

## Data imported

The canonical database contains 813 input rows, 1,824 output rows, and 13 source-backed assumptions for this run.

- **Catch and landings:** Table 23.2 official total landings, including 7.d, in tonnes for 1950-2008; Table 23.4 catch numbers-at-age for ages 1-10+ in 2009-2025. The landings source column is retained directly and not recalculated from rounded regional values. The catch numbers are preserved as printed because the table does not state a numeric multiplier.
- **Weights and biology:** Tables 23.5a-c landings, discard, and total catch weight-at-age in kg for ages 1-10+ in 2009-2025; Table 23.6 constant stock weight-at-age; Table 23.7 fixed maturity; and fixed M=0.2 per year for all ages and years. Age 10 is the assessment plus group. The maturity value for 10+ is the report's 0.851 mean for ages 10-12.
- **Survey indices:** Table 23.1 aggregate fishable-stock biomass in kg/hour: IBTS Q1 for 1983-2008 and combined IBTS-BTS Q3 for 1991-2008. Only the assessment-used series through 2008 are imported. More recent values in the report table are explicitly described as not included in the assessment.
- **Outputs:** Table 23.8 recruitment at age 1, SSB, Fbar ages 4-8, and total stock biomass for 1950-2025, with 95% confidence bounds; Table 23.9 F-at-age and Table 23.10 N-at-age for ages 1-10+ over 1950-2025. N-at-age is reported in thousands of fish. The report says age information was used only from 2009; earlier age-specific outputs are model estimates and not direct age observations. Age-specific uncertainty is not tabulated.

The report describes Q1 and Q3 survey age-index series for 2009-2025, but the numerical age-specific matrices were not found in the report tables or the public model archive. Survey season is identified only by quarter; no exact within-quarter sampling time was recovered. These gaps remain open in the canonical record and candidate register.

## Unresolved source gaps

- **Catch-at-age scale:** Table 23.4 labels its values as catch numbers-at-age but does not state a multiplier. The importer preserves the printed values without conversion.
- **Survey age matrices:** the report describes age-specific Q1 and Q3 indices for the recent period, but does not print their numeric values. The public code archive lacks the referenced run data objects.
- **Survey timing:** only Q1/Q3 labels were verified. `sampling_time` is left blank rather than assigning a midpoint to a quarter.

The assessment remains a partial import and eligibility is unresolved. The missing recent age-specific survey inputs and unconfirmed catch scale prevent a complete record of the production input data.

## Provenance

The official report, pinned model archive, ICES Standard Graphs data page, and the report text extraction used for transcription are cached under `source_cache/shared/ices_witch_northsea_2026/`. Their URLs, revisions, retrieval dates, sizes, and checksums are recorded in [`provenance/ices_wit_27_3a47d_2026/sources.csv`](../provenance/ices_wit_27_3a47d_2026/sources.csv). The report PDF was retrieved on 2026-10-28; its SHA-256 is `0e98d2913f9ea7418a4aba115785ab831a24376cc73f6b214be23efdb632d81d`.
