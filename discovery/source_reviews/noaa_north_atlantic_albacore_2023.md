# North Atlantic albacore: current age-data screen

Review date: 2026-11-01

## Assessment identity and recency

NOAA Stock SMART identifies assessment 13464 for stock 10950 as a full-acceptance 2023 assessment and reports a last data year of 2022. The detailed ICCAT Stock Synthesis model paper describes an age-structured 2023 reference run spanning 1930-2021. The 2025 SCRS report still describes the 2023 North Atlantic assessment as current. The 2026 Albacore meeting agenda covers a South Atlantic assessment and an MSE update for North Atlantic albacore, not a new North Atlantic assessment. The NOAA metadata and detailed-run endpoints differ by one year and should be reconciled before assessment data are imported.

The North Atlantic unit is separate from the North Pacific albacore unit already screened in the register. No matching canonical tinyAM stock is present.

## Inputs and assessment structure

The 2023 Stock Synthesis reference case uses 15 fleets, fleet catches, eight standardized fishery CPUE indices, length compositions, and spine-age samples. Length samples were compiled annually in two-centimetre bins and weighted over quarters. The age information came from fish sampled in 1990 and 2008-2012. Because the source fleet was unclear, the assessment assigned these age samples to baitboat. The report describes age composition by length bin, not observed annual catch numbers-at-age for all fleets.

The model uses a Lorenzen natural-mortality curve anchored at M=0.36 at age 6 under a 15-year maximum-age assumption; maturity is 50% at age 5 and 100% at age 6. It fixes a length-weight relationship. Spawning is set at the beginning of month 6, and the model represents four within-year seasons. These inputs support detailed assumption mapping, but the reviewed public material does not verify the annual fleet-year observation values and expansion factors needed for an age-specific tinyAM reconstruction.

## Outputs and screening decision

The assessment and later SCRS summaries report aggregate SSB, recruitment, and fishing-mortality status. The reviewed public reports did not provide complete numeric annual N-at-age, F-at-age, or M-at-age tables. Stock SMART reports terminal status values, but its reported 2022 endpoint differs from the 2021 endpoint described for the detailed SS3 run.

Keep the candidate screened with eligibility unresolved. It is a strong source-review candidate because the detailed age-structured model, fleet-level data descriptions, age samples, and biological assumptions are public. Before classifying it as ready for age-disaggregated curation, recover the underlying fleet-year catch/size/age data and CPUE series, verify what can be reconstructed without model-derived pseudo-observations, and reconcile the terminal-year discrepancy. Do not add canonical numerical records or begin a tinyAM translation yet.

## Sources

- [NOAA Stock SMART stock 10950](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10950), snapshot retrieved 2026-10-28.
- [ICCAT, 2023 North Atlantic Albacore Data Preparatory Meeting](https://www.iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_NALB_DP_ENG.pdf).
- [ICCAT, 2023 Atlantic Albacore Stock Assessment Meeting](https://www.iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_ALB_SA_ENG.pdf).
- [SCRS/2023/107, Preliminary Stock Synthesis Assessment Model for North Atlantic Albacore](https://www.iccat.int/Documents/CVSP/CV080_2023/n_3/CV080030279.pdf).
- [SCRS/2023/145, Review and Diagnostics for the Stock Synthesis Model](https://www.iccat.int/Documents/CVSP/CV080_2023/n_3/CV080030336.pdf).
- [ICCAT, 2025 SCRS Report](https://iccat.int/Documents/Meetings/Docs/2025/Reports/2025_SCRS_ENG.pdf).
- [ICCAT, 2026 Albacore Stock Assessment Meeting agenda](https://www.iccat.int/Documents/Meetings/Docs/2026/02859-26_ENG.pdf).

The official PDFs, source URLs, retrieval dates, pinned report identifiers, and SHA-256 checksums are recorded in the gitignored local cache at `source_cache/noaa_north_atlantic_albacore_2023/sources.csv`.
