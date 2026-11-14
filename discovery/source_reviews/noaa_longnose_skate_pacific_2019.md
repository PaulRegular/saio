# NOAA Longnose Skate, U.S. Pacific Coast (2019)

Review date: 2026-11-12. NOAA Stock SMART identifies this coastwide U.S. unit as stock 10731. The 2019 Stock Synthesis assessment is the latest full assessment located for the unit; it uses data through 2018 and reports a one-year 2019 forecast. The assessment covers U.S. waters from the Canadian to Mexican borders and is distinct from Gulf of Alaska Longnose Skate (NOAA:10730). The assessment uses the scientific name *Beringraja rhina*; Stock SMART retains *Raja rhina*.

## Inputs and assumptions

The archived native Stock Synthesis files contain annual removals in metric tons for 1916–2018 across four fleets, with source standard deviations for log catch. The import retains those fleet identities and error values. It also retains five aggregate relative-abundance indices: four on a biomass-index scale and one numbers-index scale. These are relative indices, not absolute abundance estimates. The native model uses lognormal index errors, records survey observations in July, and sets survey timing to 0.5.

The files contain annual length-frequency compositions, including fishery and survey samples, discard fractions for 1995–2017 with additive standard errors, and discard mean body weights for 2002–2017 with their CVs. They contain 91 conditional age-at-length samples: 22 fishery samples from 2004 and 69 NWFSC shelf-slope samples from 2003, 2011, and 2012. Four negative-fleet marginal-age records are retained as diagnostics; the Stock Synthesis manual states that negative-fleet composition observations are evaluated but excluded from the total likelihood. These observations are not annual catch-at-age or a continuous survey index-at-age series.

The model combines sexes and tracks ages 0–30, with age 30 as the accumulator plus group. It estimates growth, uses a fixed combined-sex weight–length relationship (`W = 4.288369e-6 * L^3.068629 kg`, with length in cm), and fixes a maturity-at-length curve. It estimates a scalar natural mortality parameter with an informative Hamel prior. The report gives M = 0.22 per year and labels its parameter standard deviation as 0.01; the import preserves that as an SD, not an SE. Standalone annual weights-at-age, maturity-at-age, and M-at-age surfaces were not found in the reviewed files.

## Outputs and remaining gaps

The official supplementary workbook provides fitted abundance-at-age for 1916–2018, ages 0–29 and 30+. The workbook does not state the count multiplier, so values are stored unchanged with the unit marked as unstated. The 2019 report's Table 16 provides total biomass, spawning biomass, age-2+ biomass, depletion, age-0 recruitment, total catch, relative exploitation, and `(1-SPR)/(1-SPR50)` through 2018, plus the reported 2019 forecast quantities. Table ES-8 supplies 95% confidence intervals for SSB, recruitment, and depletion for 2009–2019; these intervals are retained separately from the point estimates.

The public model archive includes the native data, control, starter, and forecast files, but no fitted `Report.sso`. Therefore fitted F-at-age, continuous index-at-age, and annual catch-at-age remain unavailable. The reported relative exploitation and SPR diagnostic are preserved under their source definitions and are not labelled as F-at-age.

## Sources and status

The authoritative assessment report, STAR review, supplementary tables, 2023 available-data review, and native model archive are cached under the gitignored `source_cache/discovery_noaa_longnose_skate_2019/`. The tracked provenance manifest records source URLs, retrieval dates, revisions, file sizes, and SHA-256 checksums. The import is marked partial because age-specific mortality and direct annual catch/index-at-age inputs and several biological surfaces are not publicly available in the reviewed materials.
