# NOAA Atlantic Bluefish source screen

**Screened:** 2026-10-30  
**Candidate:** NOAA Stock SMART 10388, Atlantic Bluefish (*Pomatomus saltatrix*)  
**Scope:** Discovery screen only; no canonical stock, assessment, input, assumption, or output rows are added.

## Current assessment and source run

NOAA Stock SMART identifies assessment 13933 as the 2025 WHAM Management Track assessment, with data through 2024 and full acceptance. The final June 2025 peer-review panel concluded that the assessment met all terms of reference and represented the best scientific information available. The report itself retains its draft working-paper label, so the panel conclusion is the source for its official status.

The 2025 SASINF bundle contains the assessment report, input and result figures, diagnostics, and fitted parameter tables. It does not contain a run-specific WHAM input file or model code. The 2022 Research Track bundle contains the benchmark report and supporting working papers, including numeric fishery data and the natural-mortality methods paper. The 2022 material is used to clarify the method, not to replace 2025 observations.

## Recoverable inputs and outputs

The 2025 production input figures show commercial and recreational catch age compositions for ages 0-5 and 6+ from 1985-2024. Bubble area represents composition proportion, with reference sizes shown in the figure legend. Annual fleet catch totals are reported in the assessment table, allowing catch-at-age to be reconstructed as total fleet catch multiplied by the digitized proportions. Exact numeric composition arrays and their sample-size series are not in the SASINF bundle.

The input report shows nine aggregate abundance-index series (NEFSC Inshore, Bigelow, MRIP, NEAMAP, SEAMAP0, PSIGN, Compound YOY, ChesMMAP, and SEAMAP1). Their trends are shown on a rescaled axis; age compositions are plotted for age-sampled indices. Relative index trends can be digitized for an approximation with index-specific catchability, but original numeric index levels and composition arrays are not provided in the bundle.

Annual weight-at-age surfaces are plotted for SSB, the commercial and recreational fleets, and survey series. Maturity-at-age is also plotted for ages 0-5 and 6+. These inputs are recoverable through documented figure digitization, while exact matrices remain to be extracted. The 2022 Research Track assessment replaced constant M=0.2 with an age-varying Lorenzen weight-based schedule. The 2025 update uses recent-year averages of M, maturity, selectivity, and weights for projections; its bundle does not provide the production-run M vector or code, so retention of the 2022 M assumptions must be verified during detailed curation.

The fitted parameter tables report numeric annual abundance-at-age (thousands of fish) and total and fleet fishing mortality-at-age for 1985-2024, ages 0-5 and 6+. Aggregate outputs include SSB, recruitment, and fishing mortality. The age-specific tables do not provide cell-level uncertainty intervals.

The WHAM model is annual and the 2025 input figures do not identify fractional-year observation times. Any annualization should be documented as an approximation.

## Identity and screening decision

No canonical NOAA Bluefish stock was found, and no existing candidate row uses this scientific name. Keep the Atlantic Coast management unit distinct. This candidate is **eligible for source curation** because the accepted production assessment provides age compositions and age-specific biological inputs in digitizable form, annual fishery totals and relative survey indices, and numeric fitted N-at-age and F-at-age outputs. It is eligible for reconstruction and comparison, but not for direct import of exact numeric input arrays. Preserve the figure-based reconstruction, missing sample sizes, relative index scaling, run-specific M, and timing limitations explicitly.

The 2025 SASINF archive, its run outputs, the final peer-review panel report, and 2022 supporting assessment sources are cached under the gitignored `source_cache/discovery_noaa_bluefish_2025/` folder. `sources.csv` records source URLs, revisions, retrieval date, byte counts, and SHA-256 hashes. The discovery register is updated; the canonical database remains unchanged.
