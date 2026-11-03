# DFO inventory Witch Flounder - NAFO 3NO

## Stock identity and latest assessment

The DFO Sustainability Survey entry refers to the NAFO 3NO witch flounder stock (`Glyptocephalus cynoglossus`). NAFO manages 3NO separately from its 2J+3KL witch stock. The canonical database has no 3NO record; existing witch flounder records are U.S. Gulf of Maine/Georges Bank or another U.S. assessment unit, not the NAFO 3NO stock.

The latest detailed full assessment located is the 2024 NAFO assessment, with model output through 2023. NAFO's 2026 advice reports updated status and projections for 2027-2028, describes the assessment as a Schaefer surplus-production model using survey and fishery data, and says the next full assessment is due in 2028. The 2024 report remains the detailed source for the underlying accepted model and input series.

## Inputs and assumptions

- **Catch:** The accepted model uses nominal catch in thousands of tonnes over 1960-2023. The assessment model does not use catch numbers-at-age.
- **Survey indices:** The model uses aggregate biomass indices in thousands of tonnes from four series: Campelen spring (late), Campelen fall, Campelen spring (early), and modified Campelen spring. The report documents non-comparable and incomplete years; the modified Campelen spring series combines selected years from 2014, 2016, 2018 and 2022-2023. No age-specific survey-abundance likelihood is used.
- **Age data:** The report says ageing has not been available for Canadian RV surveys since 1994. Commercial and survey length compositions and length-based recruitment proxies are described, but the accepted assessment likelihood is not age structured.
- **Biology:** The source reports length-composition and size-based information. Age-specific weights and maturity are not inputs to the accepted production model.
- **Mortality and timing:** The surplus-production model estimates biomass dynamics, carrying capacity and population growth; it does not estimate age-specific M or F-at-age. Observations are annual survey series, with no within-year timing fractions specified for a tinyAM-style age model.

## Outputs

The 2024 detailed assessment reports aggregate posterior reference points and trajectories, including B/BMSY and F/FMSY through 2023, with credible intervals. It estimates B/BMSY at 0.48 at the beginning of 2024 and F/FMSY at 0.16 for 2023. The 2026 advice estimates the stock at about 0.37 BMSY and provides aggregate projection risks and biomass ratios. Neither source reports annual N-at-age, F-at-age, M-at-age or age-structured SSB.

## Screening decision

This entry is screened **ineligible** for the age-disaggregated tinyAM candidate set. The current official assessment is an aggregate Bayesian surplus-production model based on catch and survey biomass indices. It does not use catch-at-age, age-specific survey abundance, or age-specific biology. The NAFO 3NO unit is distinct from the stock records already in the canonical database. No numerical canonical records were added during this inventory audit.

The DFO inventory row is retained as a discovery entry, while the 2024 detailed assessment and 2026 status advice are cached locally. The 2026 advice is not treated as a new full assessment: it states the next full assessment will be in 2028.

## Sources

- [NAFO 2024 assessment of witch flounder in Divisions 3NO, SCR Doc. 24/018](https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-018.pdf)
- [NAFO witch flounder in Divisions 3NO advice, June 2026 for 2027-2028](https://www.nafo.int/Portals/0/PDFs/Advice/2026/wf3no.pdf)
- [NAFO species and management-area description](https://www.nafo.int/Science/Science-Advice/Species)

The detailed report and current advice PDFs, with retrieval URLs, retrieval date and SHA-256 checksums, are in the gitignored local cache `source_cache/discovery_dfo_witch_flounder_3no_2026/sources.csv`.
