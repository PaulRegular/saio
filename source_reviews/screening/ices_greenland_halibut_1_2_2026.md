# Greenland halibut in ICES subareas 1 and 2: 2026 screen

**Review date:** 2026-10-30  
**Official stock code:** `ghl.27.1-2`  
**Scientific name:** *Reinhardtius hippoglossoides*

## Stock identity and assessment

The ICES inventory entry is the Northeast Arctic Greenland halibut unit in subareas 1 and 2. It is a distinct assessment unit from ICES Greenland halibut in subareas 5, 6, 12, and 14, and from the separate DFO Greenland halibut units. Connectivity does not establish that those management units are interchangeable.

The most recent detailed advice located is the 2026 JRN-AFWG advice for 2027–2028. JRN-AFWG says this advice is outside ICES but follows the method agreed at the ICES 2023 benchmark. The current model is a single-area, two-sex GADGET age–length assessment with ages 1–25+, split into mature and immature components. The 2026 report says the Norwegian input data were revised at the 2023 benchmark and the Russian slope-survey series was revised for the 2024 JRN-AFWG update. The model data described in the report include commercial catch and length distributions through 2020.

The official IMR/NMDC archive contains the model source and selected inputs for a 2024 model version. It is useful evidence about the data structure, but it is not verified as the exact run bundle underlying the 2026 advice. The cache manifest records the archive release and retrieval metadata separately from the 2026 report and advice.

## Inputs and assumptions

The 2026 report describes catch in tonnes and quarterly length distributions by fleet and sex, not a commercial catch-at-age likelihood. It lists five aggregated commercial fleets. The archived model code prepares a sampled age–length distribution for longline and gillnet catches, but the corresponding `OtherNor_aldist` likelihood is commented out; the archived catch-age sample covers 2015–2021 and is not evidence of a full, run-matched catch-at-age series.

The report says age data from the Norwegian autumn slope survey (EggaN) are used in model tuning. The archived model code includes EggaN age–length-distribution likelihoods. Its survey age–length data file spans 2001–2023 (ages 0–41), but the example likelihood removes 2001 and 2007. The paired indices are aggregate biomass or abundance series, so these data may support a documented age-composition reconstruction if the exact 2026 run inputs and expansion basis are confirmed.

The model estimates sex-specific growth and maturity-at-length; it does not report a directly observed, run-matched stock weight-at-age or maturity-at-age table. Natural mortality is fixed at 0.12 for females and 0.16 for males. The 2026 report describes one annual model step and quarterly commercial distributions.

## Official outputs

The 2026 advice reports recruitment at age 2, female spawning-stock biomass, fishable biomass for fish at least 45 cm, harvest rate, and catches. It also includes historical model results and advice scenarios. Public annual N-at-age and F-at-age surfaces were not located. The report notes that recent recruitment magnitude is poorly constrained and that survey indices have considerable uncertainty.

## Screening decision

This is a distinct new candidate with **eligibility unresolved** for the age-disaggregated source-curation set. The current assessment uses survey age information, and the archived source includes partial sampled catch age–length data. However, the current report documents catches and fishery length distributions rather than a full catch-at-age likelihood; the archive is not verified as the 2026 run, and the available data do not yet establish a complete, run-matched input set with age-specific biology and a supported fishery catch-age reconstruction. The unresolved status reflects those specific gaps; the GADGET age–length label alone is not being treated as proof of age-at-age inputs.

No canonical stock, assessment, input, or output records were added. ## Sources

- Institute of Marine Research, [JRN-AFWG Report 2026](https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5), Greenland halibut chapter.
- Institute of Marine Research, [Greenland halibut advice for 2027–2028](https://www.hi.no/en/hi/nettrapporter/imr-vniro-en-2026-4).
- Norwegian Marine Data Centre, [GADGET3 source-code dataset for Greenland halibut in ICES areas 1 and 2 (2024)](https://metadata.nmdc.no/metadata-api/landingpage/789a27f9647f32c0fdeaa792d3ed5d7b).
- The gitignored `source_cache/discovery_ices_greenland_halibut_1_2_2026/sources.csv` records URLs, revisions, retrieval date, sizes, and SHA-256 checksums.
