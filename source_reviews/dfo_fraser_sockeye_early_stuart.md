# Fraser River Early Stuart Sockeye

## Current unit and assessment product

The inventory label resolves to the Fraser River Early Stuart sockeye management
group, not to Fraser sockeye as a whole. The PSC production dataset maps the
Early Stuart production group to the Takla/Trembleur Early Stuart Conservation
Unit. It is one of the Fraser run-timing management groups, not a separate
assessment for each spawning stream. No unique DFO assessment identifier is
published in the inventory source, so official_stock_id remains blank.

The latest detailed public age-specific output located is the PSC Fraser
Sockeye Stock-Recruit Dataset, version 2026.05.07, which contains Early Stuart
recruits by return year and Gilbert-Rich age code through 2025. The PSC
documentation explains that the production data combine DFO spawner
enumerations with PSC recruitment estimates. Recruit estimates are constructed
from age-specific spawning estimates plus catch/run-size information, with
post-season run-size adjustment (post-RSA) used since 2009. The DFO 2025/021
science advisory describes this stock-specific post-season run-size process;
its displayed Early Stuart series covers 2009–2022.

The PSC file has 955 Early Stuart cohort-age rows across return years 1950–2025
and age codes 2.1 through 7.2. Return year 2025 is explicitly
in-season-based, with only age 4.2 and 5.2 recruit estimates populated in the
current file; the other age cells are missing. Treat those as provisional
in-season data, not a complete final age series. The historical/post-season
file also contains post-DBE and post-RSA estimates. The documented values are
source outputs; they are not a fitted N-at-age surface from an age-structured
population assessment, and no uncertainty is included in the file.

## Inputs and output coverage

- **Catch:** the PSC dataset contains recruits/run-size estimates by age, but
  not the original fishery catch numbers-at-age likelihood or all source
  catch-age matrices needed to reproduce the run-size calculations.
- **Abundance index:** no independent age-specific abundance-index likelihood
  was identified. The PSC age-specific recruits are constructed outputs from
  run-size assessment, catch and spawning-ground information, not independent
  survey observations.
- **Weights and maturity:** no current production age-specific weight and
  maturity input vectors were recovered for a population model. DFO spawner
  enumeration data include sex and spawning-success information, which is not
  a substitute for those inputs.
- **Mortality and timing:** the sources describe run-size adjustment, migration
  conditions and in-season assessment. They do not define annual F-at-age,
  M-at-age or a within-year timing fraction for an age-specific survey
  likelihood.
- **Outputs:** the PSC dataset provides age-specific recruit estimates and
  brood-year spawner estimates. It does not provide an age-structured
  population assessment's annual N-at-age, F-at-age or M-at-age surfaces with
  uncertainty.

The current stock unit and age-specific run-size outputs are well documented,
but the verified public product does not supply the observations and biological
inputs needed to fit a comparable age-structured population assessment.
Screen this unit ineligible for the age-input candidate set. This does not mean
that Fraser sockeye are unmonitored or that age-specific data are absent; it
means the data located are part of a run-size/stock-recruit product rather
than the required population-assessment inputs.

No canonical stock, assessment, input or output records were added.

## Sources and cache

- [PSC Fraser Sockeye Stock-Recruit Dataset](https://www.psc.org/publications/data/fraser-sockeye-stock-recruit-dataset/)
- [PSC Stock-Recruit Data Documentation](https://www.psc.org/download/130/frp-data/19739/stock-recruit-data-documentation.pdf)
- [DFO Science Advisory Report 2025/021](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294622.pdf)
- [2026/2027 Southern B.C. Salmon IFMP summary](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/smon-sc-cs-ifmp-pgip-sm-eng.html)
- [Pacific Salmon Outlook 2026](https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs141-9-2026-eng.pdf)

The ignored local cache contains the PSC detailed CSV and documentation, the
DFO 2025/021 advisory, and the 2026/2027 IFMP summary. Their URLs, retrieval
date, file sizes and SHA-256 checksums are in
source_cache/discovery_dfo_fraser_sockeye/sources.csv. The 2026 Outlook was
reviewed online to confirm the current Fraser Early Stuart management label,
but its direct local download returned a Government of Canada HTML page rather
than the PDF; that response was discarded and is not represented as a cached
source file.
