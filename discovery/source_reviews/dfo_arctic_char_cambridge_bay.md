# DFO Arctic Char, Cambridge Bay

## Unit and latest assessment

The DFO 2021 Cambridge Bay IFMP names five commercially fished river
waterbodies: Ekalluktok (Ekalluk), Paliryuak (Surrey), Halokvik (Thirty-Mile),
Paalik (Lauchlan) and Jayko (Jayco). It states that each commercial waterbody
is a separate management unit with a river-specific quota. The DFO
Sustainability Survey entry therefore describes a fishery spanning several
units, not one fitted stock.

The latest detailed population-dynamics report located is the 2021 assessment
of the Halokvik and Jayko rivers. The separate 2013 Cambridge Bay stock-status
assessment covers a wider historical fishery, while Research Document
2019/062 summarizes harvest, catch-effort and biological information for
Halokvik and Jayko. A 2020 Lauchlan Science Response evaluates a proposed quota
change with fishery and biological summaries. These reports do not establish a
single current assessment covering all five waterbodies. The register row is
therefore marked **ambiguous** and is not assigned a candidate-unit ID; any
river-specific candidates need separate boundary review.

## Inputs and model structure

The 2021 Halokvik/Jayko work applies depletion-based stock reduction analysis
(DB-SRA) and other data-limited methods. The assessment uses aggregate river
harvest, empirical natural-mortality estimates, age-at-maturity assumptions,
and relative depletion/biomass information. It is not an age-structured
population assessment.

- **Catch:** Annual harvest is reported by river in tonnes. Fish-plant and
  survey programs collect otolith ages, but the reports do not describe a
  catch-numbers-at-age likelihood.
- **Survey information:** Short abundance-index series are described, including
  historical weir counts and 2010–2015 multi-mesh gillnet surveys. The
  age-at-length/weight samples characterize sampled fish and do not form an
  age-specific abundance index.
- **Weights and maturity:** Round weights are measured in grams and weight at
  age is summarized or modelled for biological samples. DB-SRA uses
  age-at-maturity; the report gives ages at 50% maturity, not a fitted
  maturity-at-age population vector. These are not run-matched population
  weight and maturity surfaces for an age-structured model.
- **Mortality:** Age-dependent M is calculated from empirical life-history and
  growth relationships. It is not a fitted natural-mortality surface from an
  age-structured population model.
- **Timing:** The reports describe seasonal fisheries, including downstream
  fishing in July and upstream runs from mid-August to early September. The
  annual DB-SRA does not specify a fractional survey timing.

## Outputs and screening

The 2021 report gives biomass trajectories and reference-point results from
DB-SRA for Halokvik and Jayko, along with biological growth and empirical M
results. It does not report fitted population N-at-age, F-at-age, or annual
recruitment trajectories.

This inventory entry is **ineligible for the age-disaggregated candidate
set**. Aggregate harvest and biomass information, biological age samples, and
empirical age-dependent M do not substitute for catch-at-age or population
age-specific observations and outputs. That screening does not mean the
reports lack useful source data; it means this multi-unit fishery is not a
verified age-structured assessment candidate under the current screening
criteria.

## Sources and local cache

The PDFs and the current IFMP page are cached under
`source_cache/discovery_dfo_arctic_char_cambridge_bay_2026/`. Its `sources.csv`
records retrieval date, URL and SHA-256 checksum.

| Source | URL | SHA-256 |
|---|---|---|
| DFO Research Document 2021/016, Halokvik and Jayko population dynamics | <https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40961308.pdf> | `3C4C6F909641B8DAD60ADB9DC74799B623A187DC8190600503A858919C6206F4` |
| DFO Research Document 2019/062, Halokvik and Jayko stock-status information | <https://publications.gc.ca/collections/collection_2021/mpo-dfo/fs70-5/Fs70-5-2019-062-eng.pdf> | `BA22B7F7E96CD1A4728222D61DD05552DEE2762846FE3B55F6022868F8E873A5` |
| DFO Research Document 2013/068, Cambridge Bay stock status | <https://waves-vagues.dfo-mpo.gc.ca/Library/350263.pdf> | `BAE2149B29903E9131030DC09EC7FA26CA4B4DC53C3AD5E42F21DD64DBB1AB3E` |
| DFO Science Response 2020/049, Lauchlan River quota request | <https://publications.gc.ca/collections/collection_2020/mpo-dfo/fs70-7/Fs70-7-2020-049-eng.pdf> | `A42A1A3BCC18D966C6C5041A4A17DD7599210EE5787556D38F0C5B15D2154674` |
| DFO Cambridge Bay IFMP, effective 2021 | <https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/arctic-char-omble-chev/arctic-char-omble-chev-eng.html> | `5CA6B9C99C61DDCE0990126BDB792939227D94B38026A60E1371F067594FB8AF` |

No canonical stock, assessment, input or output rows were added.
