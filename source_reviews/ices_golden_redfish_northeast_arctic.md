# Northeast Arctic golden redfish

## Identity and production assessment

The catalogue stock `ICES-AFWG_norvegicus_DEEP1,2` is ICES `reg.27.1-2`,
Sebastes norvegicus in subareas 1 and 2. Its existing stock ID is retained;
the regional basin is Northeast Atlantic and the assessment area is the
Barents and Norwegian seas. It is distinct from beaked redfish `reb.27.1-2`
and Iceland/Faroes golden redfish `reg.27.561214`.

In February 2026 the WKBWNG benchmark replaced the former age-length Gadget
assessment with **SPiCT**, an aggregate surplus-production model. The annual
AFWG update uses catches through 2025 and produces advice for 2027. The final
advice identifies this as an ICES category-2 assessment, not an age-structured
assessment under the catalogue's historical model label.

The new canonical event is `ices_golden_redfish_northeast_arctic_2026`.
It is current and applied. The terminal data year is 2025; relative biomass
also has a reported 2026 state. That extra row is not an observed catch year,
and its precise within-year timing is not specified in the summary table.
All completeness statuses remain partial.

## Source recovery

Importer `154_import_ices_golden_redfish_northeast_arctic_2026.R` adds:

- **118 inputs:** total commercial landings in tonnes, 1908–2025, pooled as
  in the official model. Pre-1989 catch is a historical reconstruction by the
  assessment. Discards are excluded and assumed negligible. There is no
  invented age allocation or extra fleet split.
- **237 outputs:** 119 B/BMSY states for 1908–2026 and 118 F/FMSY states for
  1908–2025, retaining every published Low/High bound. The table does not
  specify the interval construction or level, so no SE is inferred.
- **14 assumptions:** model change, pooled populations, input coverage,
  priors, unresolved native configuration, reported states and conflicts.

The machine-readable source is SAG key 23725. **Every one of its 118
historical rows matches all seven numeric columns in final advice Table 9**:
catch and both relative states with their lower and upper bounds. The
additional 2026 biomass row also matches. AFWG Table 7.1 independently
confirms every annual catch total for 1989–2025. Source-table layout and
terminal values were also reviewed visually.

The 2025 total is 11,435 t. The source assumes Russian catch of 2,069 t,
equal to its 2024 value, because the 2025 value was unavailable. This is
explicitly identified as an official source assumption; the importer does
not make a new imputation or conceal preliminary status.

SAG's generic `SSB` column means **B/BMSY**, and its `F` column means
**F/FMSY**. These are dimensionless relative states. They are stored as
`B_over_Bmsy` and `F_over_Fmsy`, without populating absolute SSB, Fbar,
recruitment or age-specific N/F tables. For 2025, B/BMSY is 0.44
(reported bounds 0.26–0.74) and F/FMSY is 1.59 (0.91–2.76).
No absolute biomass is derived by multiplying by an unrecovered BMSY.

## Model and input assumptions

SPiCT uses the complete catch series from 1908 and a new compiled
spatiotemporal sdmTMB bottom-trawl biomass index for golden redfish over
30 cm, 1991–2025. It is intended to represent the adult, fishable portion,
whereas the former winter Barents Sea index primarily sampled juveniles.
The advice describes the threshold as both over 30 cm and at least 30 cm;
the exact native cutoff and observation rows require the production files.
Benchmark descriptions identify a 1994 sampling gap. No current numerical
index, unit/precision vector or single sampling-time fraction is recovered,
so no index values or survey fraction are invented.

The assessment pools at least three populations whose proportions cannot
be separated in historical observations. Species misidentification with
S. mentella and incomplete historical species reporting remain important
source uncertainties. They do not justify altering observations here.

The benchmark's final model is model 25, with production-shape parameter
n fixed at 2. Working document 4c reports priors described as r
(`mu=0.064, sd=0.5`), initial biomass fraction (`mu=0.9, sd=0.5`) and
biomass-process SD (`mu=0.05, sd=0.2`). Exact native parameter coding/scales
are not recovered, so these descriptions are not reinterpreted as verified
natural-scale normal distributions. The annual update retains the benchmark
baseline but updates the data; benchmark numerical results are not copied
into the annual record.

The benchmark documents an alternative high-biomass solution reached by
roughly half of jitter runs. Model 25 was retained after expert review;
the alternative had high K, low q and much greater biomass. This is an
identifiability limitation of the official assessment, not something resolved
by importing its selected output. No tinyAM convergence result is claimed.

## Historical states and forecast discrepancies

Final advice Table 9 and SAG agree on historical 2025 F/FMSY = **1.59**.
Final advice Table 1 nevertheless calls **1.71** the status-quo 2025 F/FMSY
used in the forecast, and the AFWG narrative also uses 1.71. The discrepancy
is not silently corrected: the canonical historical series follows Table 9,
and the scenario value is recorded separately in assumptions.
The difference may reflect an annual average versus a particular continuous-time
F state or another forecast-extraction choice. The native object and reporting
times are needed to establish the explanation; this import does not establish
that either value is erroneous.

AFWG describes advised catch of 4,913 t, while the final advice specifies
**4,912 t** for 2027. The final advice controls. Its scenario table also has
a small nonzero catch of 12 t for the scenario labelled F = 0. Neither that
scenario nor the alternative forecast scenarios are presented as observed
historical catches or silently appended to the fitted series.

## Native-source searches and cache

The AFWG chapter, complete WKBWNG benchmark and golden redfish working
documents are cached locally. The latter's final-model HTML links point to
temporary local paths on the document author's computer, rather than public
download URLs. The publisher archive lists PDFs, not the named model reports
or fitted objects. Candidate `ices-advice/2026_reg.27.1-2` was not publicly
available when checked. This does not establish that no requestable archive
exists.

The public DeepWaterIMR survey-paper repository explicitly describes itself
as a showcase that does not reconstruct the paper results exactly: the paper
used internal and partly restricted data, while the public workflow uses an
updated curated dataset and excludes Russian data by default. Its source
compilation also depends on local IMR database access. It is not verified as
the updated 2026 production index and must not silently replace it.
Reconstructing a new index from this workflow would be a separate analysis,
not recovery of the exact input. The exact annual SPiCT object, software
version/configuration, current index and its precision remain gaps.

Sources are retained in the gitignored
`source_cache/ck_ices_afwg_norvegicus_deep1_2/`, with original URLs,
retrieval/verification dates and SHA-256 checksums. Older 2024 Gadget material
remains cached for context and is not mixed into this assessment event.

## tinyAM translation limit

The current assessment uses aggregate biomass data and does not supply
catch-at-age, current age-specific weights/maturity/M or fitted N/F-at-age.
A current source-faithful tinyAM age-structured fit cannot be assembled from
these recovered inputs. Historical Gadget age/length data or states cannot
be substituted without defining a separate historical assessment case.

There is no tinyAM recipe, fit, optimizer result, comparison statistic or
comparison dashboard for this event. The runner returns no stock specification
when preparation is requested. Tests ensure the relative states do not become
absolute SSB/F references and the 2026 state is outside the observed period.
This is a source/model-structure shortfall, not a numerical fitting failure
or a reason to change tinyAM's mathematics.

## Validation

Full database validation passed: 118 stocks, 116 assessment events,
2,232 assumptions, 364,416 inputs and 195,350 outputs. A second import was
byte-identical, and hashes excluding this event and its stock row confirmed
that all unrelated canonical records were unchanged. Source checks cover
identity, all historical values against the advice, catch totals, native
units/bounds, the extra reported year and exclusion from age-based references.
Eight focused assessment-analysis scripts passed, including the new source
check, the preceding Celtic Sea plaice check, reference alignment, plus groups,
comparison definitions, default-first initialization and unit conversion.

No package source or model mathematics changed, so the full package suite and
R CMD check were not repeated for this source-only milestone. Their preceding
Area 4 reporting results were 2,936 passes and Status: OK, with package tests
run separately. The full assessment-analysis suite was not rerun; previously
recorded unrelated failures remain unresolved. The user's readiness-table
edits were preserved, and shared comparison results were not regenerated.
## Sources

- [Final 2026 advice](https://doi.org/10.17895/ices.advice.30932315.v1), especially Tables 1, 5, 8 and 9.
- [AFWG 2026](https://doi.org/10.17895/ices.pub.32134696), chapter 7.
- [WKBWNG 2026](https://doi.org/10.17895/ices.pub.32019630), golden redfish chapter and working document 4c.
- [SAG 23725](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23725).
- [Survey index paper code](https://github.com/DeepWaterIMR/ref-index-paper/tree/56d4baba5b14aafd924b9ee415bd60c703ba215f).
