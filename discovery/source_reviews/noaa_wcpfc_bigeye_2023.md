# NOAA Stock SMART 11684: Western and Central Pacific bigeye tuna

**Reviewed:** 2026-11-02
**Inventory row:** NOAA:11684
**Assessment unit:** WCPFC Western and Central Pacific bigeye tuna (*Thunnus obesus*)
**Screen:** Eligible for source curation, with a reconstructed age-input caveat. No canonical database records were added.

## Identity and current assessment

Stock SMART lists the unit as Western and Central Pacific bigeye tuna and its latest row is assessment 13363 (2023, data through 2021; SWFSC/PIFSC). No matching canonical stock is present. It is distinct from the Atlantic bigeye candidate NOAA:10169 and the Eastern Pacific bigeye assessment NOAA:11685. The unit is linked internally as `wcpfc_wcpo_bigeye`.

The 2023 WCPFC assessment is the latest assessment accepted for stock-status advice: SC19 accepted its nine-region structure and unweighted 54-model uncertainty grid. The full report covers 1952–2021 and describes 41 fisheries (32 extraction and nine index fisheries), quarterly time steps, and 40 quarterly age classes including a plus group. A more recent 2026 assessment was reviewed at SC22, but the Committee did not reach consensus on its uncertainty grid. The 2026 report and data papers are retained as newer source material; they do not replace the 2023 assessment as the last accepted basis for advice.

## Inputs and outputs located

- **Catch and size:** The native MFCL `bet.frq` input carries the catch and frequency data. The pinned SPC TAF tables expose 96,235 length-composition rows from 1965–2021 and 707,200 weight-composition rows from 1952–2021. They cover 18 fisheries with length data and 24 with weight data. These are length/weight compositions, not catch-at-age observations.
- **Age data:** The native `bet.age_length` input and TAF `otoliths.csv` expose 1,010 individual conditional age-at-length records. They span 14 sampled years from 1990–2018, four quarters, and eight of nine regions. The model age index has 40 quarterly classes; it must not be read as 40 annual ages. The assessment uses these conditional samples to estimate growth, rather than as marginal catch-at-age observations. Combining age-length keys with the matching size compositions can support an approximate age-composition reconstruction in sampled strata. Extending those keys across unsampled years or areas requires pooling assumptions and must be labelled as reconstruction.
- **Abundance indices:** Nine standardized longline CPUE index series cover 1952–2021 at quarterly resolution. They are regional aggregate relative-abundance indices, not age-specific indices. A tinyAM age-specific index would need an additional, documented age-composition reconstruction.
- **Biology and mortality:** The model estimates growth internally from size and conditional age-at-length data. Natural mortality follows an internally estimated Lorenzen form. The public fitted biology surface reports age-specific length, weight, maturity and natural mortality; these are model-derived surfaces, not independent observed weight-at-age or maturity-at-age tables. Spawning potential combines maturity, sex ratio and fecundity, so its reported biomass measure should not automatically be relabelled conventional SSB.
- **Outputs:** The pinned TAF diagnostic output includes numbers-at-age by year, quarter and region (1952–2021; 40 quarterly classes, nine regions), annual fishing mortality-at-age by region, and annual summary quantities including recruitment and biomass. These are outputs from the diagnostic reference fit. The report's official status advice summarizes the 54-model grid; the diagnostic outputs are not a substitute for the grid distribution or its uncertainty.

## Screen decision

**Eligible for source curation.** The accepted assessment provides catches and size compositions plus observed conditional age-at-length data, which support an explicit approximate reconstruction of age-disaggregated catch information where the age samples support it. The reconstruction is not the likelihood used by MFCL; coverage is sparse in time and missing in one region, so age-key pooling must remain visible. The aggregate CPUE indices are usable as aggregate indices, but they do not supply age-specific abundance observations. The assessment also provides age-specific fitted outputs for comparison.

This is a source-curation screen only. It does not select the stock for the later 20-stock batch, create canonical records, or establish that tinyAM can represent the MFCL model.

## Sources and cache

The gitignored local cache is `source_cache/discovery_noaa_wcpfc_bigeye_2026/`. `sources.csv` records retrieval dates, URLs, byte counts, SHA-256 hashes, and the SPC repository revision. The pinned SPC diagnostic repository is `81fc412ad1f36416f78f84ef6bd2d5dff68d14c8`.

- [2023 WCPFC assessment report](https://meetings.wcpfc.int/node/19353) and [SC19 outcomes](https://meetings.wcpfc.int/system/files/2024-07/SC19%20Outcomes%20Document%20%2828Nov2923%29-Att%201%2C7%20fixed_0.pdf)
- [SPC 2023 diagnostic model and TAF data](https://github.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/tree/81fc412ad1f36416f78f84ef6bd2d5dff68d14c8)
- [2026 WCPFC assessment report](https://meetings.wcpfc.int/node/33590), [background inputs](https://meetings.wcpfc.int/taxonomy/term/2845?order=field_doc_symbol&sort=desc), [age-at-length data paper](https://meetings.wcpfc.int/file/21268/download), and [SC22 outcome summary](https://www.wcpfc.int/node/244)
