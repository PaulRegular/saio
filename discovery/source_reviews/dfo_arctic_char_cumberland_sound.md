# DFO Arctic Char, Cumberland Sound

## Stock units and latest assessment located

The inventory entry is broader than one assessment unit. The latest detailed
assessment located is the 2017 DFO regional review, published in August 2018 as
Science Advisory Report 2018/021. It separately assesses Ijaruvung Lake
(waterbody code PG003), Iqalujjuaq Fiord (PG027), and Irvine Inlet (PG018).
The 2022 proposed Fish Stock Provisions list those three units separately.

The DFO 2026–2027 work plan refers to fishery-monitoring risk screening for
Iqalujjuaq and Irvine; it is not a replacement population assessment. The
separate 2023 Ikaluit Lake (Robert Peel Inlet) assessment is also in the
Cumberland Sound area but is not one of the three waterbodies in the 2018
assessment. The inventory row therefore remains **ambiguous** and is not
assigned a `candidate_unit_id` or official stock ID.

## Assessment data and methods

The report covers commercial harvest histories through 2016, estimates of
subsistence harvest, test-fishery sampling, fish-plant sampling, and
fishery-independent biological and catch-effort sampling. It explicitly says
the time series are too short for standard catch-at-age or surplus-production
models. It instead reports results from a Baranov catch equation, Catch-MSY,
and depletion-corrected average catch methods.

- **Catch:** Commercial harvest is reported in mass, with approximate
  subsistence harvest included in the quantitative modeling. The report does
  not provide a catch-numbers-at-age series.
- **Survey:** Multi-mesh gillnet sampling produced fishery-independent CPUE
  (fish per 24 hours). The report says only five years of CPUE were available
  and that CPUE was not used in the quantitative modeling. It is not an
  age-specific abundance index.
- **Age and weight:** Fish were aged, and fork length and round weight in grams
  were collected. The age, length and weight results describe sampled fish;
  they are not a modeled population-at-age likelihood or a numeric
  weight-at-age input series. The report notes that ages below four were
  missing from samples.
- **Maturity:** Maturity stages were observed, but the report describes
  classification as subjective and does not give a run-matched numeric
  maturity-at-age vector.
- **Mortality:** The report presents Chapman–Robson sample-based total
  mortality (`Z`) and survival estimates, and scalar Catch-MSY `m` parameters.
  These are not annual age-specific F and M surfaces. Natural mortality for
  young fish is identified as unknown.
- **Timing:** Sampling was seasonal and differed among waterbodies. The report
  does not specify fractional survey timing for an age-structured population
  model.

## Outputs and screening

The advisory report provides aggregate abundance and biomass estimates with
5th and 95th percentiles, and Catch-MSY parameter summaries and reference-point
status for 2016. It does not report annual recruitment or fitted population
N-at-age and F-at-age outputs.

The register row is screened **ineligible** for the age-disaggregated
assessment set because the reviewed production assessment relies on aggregate
harvest and data-limited population methods. Biological age samples and
sample-based mortality estimates are not catch-at-age inputs, age-specific
indices, or fitted population-at-age outputs. No canonical stock, assessment,
input, or output records were added. This decision is specific to the
age-structured comparison scope; it does not imply that the assessment has no
useful biological or aggregate stock information.

## Sources and local cache

Retrieved 2026-10-29. Files and SHA-256 hashes are recorded in
`source_cache/discovery_dfo_arctic_char_cumberland_sound_2026/sources.csv`.

| Source | URL | SHA-256 |
|---|---|---|
| DFO Science Advisory Report 2018/021 | <https://waves-vagues.dfo-mpo.gc.ca/Library/40726174.pdf> | `4E0AFF6ED3E9B0976E1FFE102BC37A013B2F720F94FC080E1750C2E6EF93D1D1` |
| DFO proposed Fish Stock Provisions (2022) | <https://www.dfo-mpo.gc.ca/about-notre-sujet/engagement/2022/docs/fish-stock-provisions-dispositions-stocks-poissons-eng.pdf> | `7792375FC436879BFD57794137D8D39B8CE5D0F6C453C43FBF4A86EE2BAF6ADD` |
| DFO Arctic Char species profile | <https://www.dfo-mpo.gc.ca/species-especes/profiles-profils/arctic-char-omble-chevalier-eng.html> | `B76686D197E71A186941C80C63D10A90CEB7780A64840E82FBE36CB0AF4901C4` |
| DFO Sustainable Fisheries Framework Work Plan 2026–2027 | <https://www.dfo-mpo.gc.ca/about-notre-sujet/publications/work-plan-travail/2026-2027/wp-pt-eng.html> | `3829691182A92B088CB2EBA3782DB98CEE49CD55267FFF822C3CB91549D403C3` |
| DFO Research Document 2023/064, Ikaluit Lake | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41199595.pdf> | `36CE9B8FB441038E653FA995FBB42503FF93EC02085767DF60127A40351328A5` |
| DFO Science Advisory Report 2023/031, Ikaluit Lake | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41204177.pdf> | `1449C075FC7C8604E97706C84368B5B7F0DC0F6223ACB08EB0E4B37DE6DFA0F5` |
