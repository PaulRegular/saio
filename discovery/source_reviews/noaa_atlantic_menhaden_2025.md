# NOAA Atlantic menhaden, latest single-species assessment

## Stock unit and assessment

NOAA Stock SMART ID `11089` is Atlantic coastwide Atlantic menhaden (*Brevoortia tyrannus*). The NOAA snapshot lists a 2022 assessment year, but the latest detailed single-species assessment located is the ASMFC 2025 update of the peer-reviewed Beaufort Assessment Model (BAM), with data through 2023. The concurrent SEDAR 102 ecological reference point benchmark is a separate model and is not the source for the single-species BAM results.

No canonical stock record or other NOAA, ICES, or DFO candidate row for this coastwide unit was found. The north/south reduction and bait fisheries are model fleets, not separate stock units.

## Inputs and age structure

The 2025 update reports landings by fishery and north/south region for 1955–2023 in thousands of metric tons (Table A1). Bait landings are incomplete before 1985. Tables A2–A5 give catch-at-age proportions for ages 0–6+ by the four reduction/bait and north/south fleets, with fish sample counts. These proportions and the matching landings provide source quantities for reconstructing catch numbers-at-age. The southern bait composition for 2020 is censored in the base run.

The assessment uses aggregate young-of-year and regional adult abundance indices with survey length-composition information. It does not use observed survey numbers-at-age in the base run. The SEDAR 69 benchmark report documents a sensitivity that converted survey length compositions to age using fishery-dependent age-length keys. This offers a documented approximation for an age-based comparison, but it must not be represented as the base-run survey likelihood.

The 2025 update specifies a fixed age-varying M vector for ages 0, 1, 2, 3, 4, 5, and 6+ of 1.39, 1.03, 0.82, 0.71, 0.64, 0.60, and 0.57 per year. It also uses time-varying maturity-at-age and fecundity-at-age derived from length and weight information. The SEDAR 69 benchmark tables provide earlier biological arrays through 2017. The 2025 update says fecundity information was revised using VIMS data, but the updated numerical weight, maturity, and fecundity arrays for 2018–2023 were not located in the reviewed public sources.

The fishing year begins March 1. The 2025 report describes survey-specific seasons and timing, but exact within-year timing fractions have not yet been transcribed for the indices.

## Outputs and screening decision

The 2025 single-species update presents recruitment, age-1+ biomass, full F, geometric-mean F for ages 2–4, and fecundity through 2023, primarily as figures. Fecundity is not SSB. No numerical N-at-age or F-at-age output matrix or fitted BAM object was verified in the reviewed sources. The SEDAR 102 ERP model is separate and its outputs must not be substituted.

The inventory row is **screened, with eligibility unresolved**. The current run provides detailed age-composition and landing tables and a possible survey-age reconstruction, but the updated biological arrays for 2018–2023, exact survey timing fractions, and numerical age-specific outputs remain unverified. Keep this unit as a source-search candidate; do not count it as eligible for the first import batch yet. No canonical assessment records were added.

## Sources

- [ASMFC 2025 Atlantic Menhaden Stock Assessment Update](https://asmfc.org/wp-content/uploads/2025/11/2025AtlMenhadenSingleSpeciesAssmtUpdate_October2025.pdf), particularly Table 2 and Appendix Tables A1–A5.
- [SEDAR 102 final report](https://sedarweb.org/documents/sedar-102-atlantic-menhaden-and-erp-final-stock-assessment-report/), August 2025, Section II summary of the BAM, growth, maturity, fecundity, and M methods.
- [SEDAR 69 benchmark report reissued as SEDAR 102 RD03](https://sedarweb.org/documents/sedar102-rd-03-sedar-69-benchmark-stock-assessment-report/), especially the single-species methods, biological input tables, and survey length-to-age sensitivity.

The three PDFs are cached with retrieval dates, URLs, file sizes, and checksums in `source_cache/discovery_noaa_atlantic_menhaden_2025/sources.csv`.
