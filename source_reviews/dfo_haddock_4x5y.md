# 4X5Y haddock

## Assessment records

The most recent detailed production assessment recovered is the 2016 ADAPT VPA, assessed through 2015 with population estimates through 2016. It is the current detailed record. The 2024 stock-status advice is recorded separately: its report cites one model-based SSB value for 2022 but does not provide a complete fitted input and output series. The 2024 data-input and operating-model framework reports support the newer management-procedure work; their inputs and simulation results are not substituted into the 2016 VPA record.

## Sources and cached copies

- DFO Research Document 2017/006, *Assessment of 4X5Y Haddock in 2016*: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40722697.pdf
- DFO Research Document 2017/026, *4X5Y Haddock 2016 Framework Assessment: Modelling and Reference Points*: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40613215.pdf
- DFO Research Document 2015/022, data-input framework: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/359710.pdf
- DFO Science Advisory Report 2025/047, *Stock Assessment for 4X5Y Haddock in 2024*: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41306132.pdf
- DFO Research Document 2025/020, framework data-input review: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290562.pdf
- DFO Research Document 2025/064, operating-model specification and MSE: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41306430.pdf

PDF copies, retrieval date, URLs, and SHA-256 checksums are recorded in the gitignored `source_cache/ck_dfo_aeglefinus_4x5y_2016/sources.csv` and `source_cache/ck_dfo_aeglefinus_4x5y_2024/sources.csv` files. The cached 2016 assessment tables were checked against the framework report where the printed assessment table contained a transcription issue. No applied ADAPT input file or native fitted object was identified in the official material reviewed.

## Inputs and model structure

The 2016 ADAPT VPA used commercial fishery catch-at-age for ages 1–11+ and DFO Summer RV swept-area abundance-at-age indices for ages 1–10 over 1985–2015. The canonical database retains the reported source tables at finer age and year resolution: catch and commercial weights at ages 1–16, RV abundance indices at ages 1–13, and RV weights at ages 0–14, covering the years printed in each table. The source abundance indices are in thousands of fish. The 1.2 vessel/gear conversion for 1970–1981 is already included in the reported indices. The fit recipe selects the assessment years and age ranges and pools source catch ages 11–16 into age 11+.

Natural mortality is fixed at 0.2 per year except for ages 10–11+: 0.3 in 2000–2004, 0.6 in 2005–2009, and 0.9 in 2010–2015. The assessment estimates age-specific survey catchability for ages 1–10. It treats zero survey index cells as missing. The plus-group fishing mortality is defined using a Fratio, including a ratio of 2 for 1985–1994. Annual survey timing fractions are not reported in the recovered production assessment; tinyAM uses 0.5 as a documented midyear approximation.

The 2016 report's Table 8 prints the 2014 age-1 index as `16,8470`; the matching 2016 framework Table 8 gives `168,470`, which is used. The assessment report prints `12,4322` for the 2015 age-2 index. That value remains unresolved and is omitted from the numeric database rather than guessed. This one missing source cell is within the assessment's age 1–10 index range.

Table 15 of the framework report supplies maturity and spawning weight-at-age for per-recruit calculations. Those values are preserved as static biology and are used only as a documented time-invariant proxy for tinyAM's weight and maturity surfaces. They are not represented as annual input surfaces used by the 2016 VPA. The fit comparison therefore treats SSB as approximate; the official model reports its native age-4+ biomass measure.

## Outputs and remaining gaps

The canonical record includes reported 1985–2015 fishing mortality at age and Fbar (ages 6–10), 1985–2016 population numbers at age and age-4+ biomass, age-specific q estimates, and approximate terminal parameter N estimates and standard errors. Total abundance and age-1 recruitment are explicitly derived from the reported N-at-age table and have no uncertainty. The Table 13 age-1 abundance in 2016 is an assigned geometric mean excluding the exceptional 2013 year class. Annual uncertainty for N, F, and biomass is not tabulated; Table 11 terminal standard errors are approximate linearized values and are kept distinct from Table 13 population estimates.

The 2024 advice reports model-based SSB of 33,531 t for 2022, attributed to a 2022 model run. It also uses the 2024 summer survey and a management procedure for catch advice. The available summary does not provide a full numerical age-specific fit suitable for a separate tinyAM replication.

## tinyAM translation

The recipe uses 1985–2015, ages 1–11+, the source catch and survey index series, fixed source M, age-specific q, and the framework's per-recruit maturity and spawning weights as a proxy. tinyAM's catch likelihood and AR(1) F process are simplifications of ADAPT VPA, which treats catch-at-age as VPA input and estimates population states through its own VPA formulation. It also uses one midyear survey timing approximation. These differences are documented in the model background and mean that agreement is descriptive rather than a likelihood replication.
