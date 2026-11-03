# Western English Channel plaice

## Identity and production vintage

Charbonneau–Keith `ICES-WGCSE_platessa_IS7e` is ICES `ple.27.7e`,
Pleuronectes platessa in the western English Channel. The catalogue's `IS`
prefix does not turn Division 7.e into the Irish Sea. The stable stock and
catalogue IDs are retained; region and area now state the official identity,
with regional basin Northeast Atlantic.

The current production advice is **2025**, using data through **2024**, for
catches in 2026–2027. The 2024 WKBPLAICE benchmark, published in 2025,
replaced the previous rfb approach with a stock-specific MSE-tuned **chr**
constant-harvest-rate rule (category 3, method 2.2). The new canonical event is
`ices_plaice_western_channel_7e_2025`, current and applied.

WGCSE 2026 presents monitoring data through 2025 but explicitly states that
there is **no new advice in 2026**. Those later data are cached separately
and not mixed into the 2025 production vintage or treated as another fitted
assessment. Analytical trial models and the MSE's operating-model population
states do not constitute the current official annual N/F/SSB estimates.

## Recovered source records

Importer `155_import_ices_plaice_western_channel_2025.R` recovers **134 inputs,
13 assumptions and 66 indicator/catch-summary outputs**.

The inputs preserve stock-level landings and discards in tonnes for
1980–2024, the published total stock catch for 2003–2024, and the UK-FSP-Q3
biomass index for 2003–2024. The 22 blank discard cells before 2002 remain
missing. Landings, discards and total catch are components of the same
combined commercial fishery; they are not invented separate fleets or
independent likelihood observations. Aggregate component measures distinguish
their meanings without changing fleet identity.

SAG key 19546 provides reported landings/discards, biomass indices and
relative harvest rates. Final advice Table 9 and WGCSE Table 15.3 independently
agree in all 22 rows and six numerical columns. SAG agrees with both tables
at their printed precision. Total and assumed dead catch are rounded
independently of their components; their consistency checks propagate that
rounding rather than forcing rounded sums to match.

The FSP survey (B4381) is in Q3 and reports biomass in **kg per hour per
metre of beam length**. Native `data.R` sums its age-specific biomass columns
for ages **2–8**. The recovered quantity is that aggregate biomass index,
not fish numbers, a single-age index, absolute stock biomass or SSB.
No exact population-observation fraction is used by the rule or inferred
from Q3. The Q1SWBeam survey is explicitly not used by the assessment.

Outputs retain the reported biomass index, relative harvest-rate indicator
and assumed dead-catch summary for 2003–2024. No standard errors or intervals
are reported, so none are invented. Generic SAG `SSB` and `F` headings are
interpreted using the source definitions; they do not populate standard
SSB, Fbar or age-specific N/F reference surfaces.

## Dead catch, total catch and migration

The rule assumes **50% discard survival**. Its harvest-rate numerator is
`landings + 0.5 * discards`; total catch includes the surviving discards as
well. Reported 2024 stock totals are 1,336 t total catch and 1,030 t assumed
dead catch. Neither is silently replaced by a new sum of rounded components.
No observations are adjusted using fitted parameters.

The relative harvest rate is dead catch divided by the survey biomass index,
with composite units **tonnes per (kg per hour per metre beam)**. It is not
instantaneous fishing mortality. In 2024 the reported indicator is 1,291.
All annual indicator values agree with the dead-catch/index relationship
within propagated source rounding.

The observations describe the **7.e stock**, including its migrating fish
caught in area 7.d. Historical stock assembly adds the source's migration
correction, described as 15% of mature Q1 catch in 7.d. The 2025 advice also
uses revised forecast allocations following the eastern Channel benchmark.
These are not area-7.e-only landings, and no second migration adjustment is
applied to the recovered stock totals.

## Rule assumptions and source limitations

The index used for advice is the latest two-year mean. Target harvest rate
is the mean over 2003–2023 multiplied by
`0.66 / 1.0668263407026402`, approximately 1,424 tonnes per index unit.
The trigger is 3.7 times the 2007 index (about 1.037248), and the biomass
safeguard is `min(1, mean_index / trigger)`. The extra multiplier is one.
Native `method.R` declares `v = 2` in a list but does not pass it as an active
argument; no additional safeguard exponent is inferred.

The mean annual discard ratio over 2012–2024 is about 34.35034%; it is not
the ratio of pooled discards to pooled catch. The rule calculates about
722 t assumed dead-catch advice, then divides by
`1 - discard_rate * 0.5` to obtain **872 t total stock catch** in each of
2026 and 2027. The stability clause is not applied because the index is below
the trigger. The source's stock and area advice are different: the final
advice gives about **819 t catch in area 7.e** after allowing for stock catch
in 7.d. It rounds the latter as 54 t in Table 2 and 53 t in the narrative;
unrounded calculations underlie the rounded totals.

The WGCSE introduction and some footnotes contain stale year/advice references,
including 1,219 t as prior advice. The final advice correctly identifies
927 t as the prior 2025 total catch advice and gives the new advice for
2026–2027. The importer follows final advice and its matching summary table.

The official repository is pinned at
`31e51a7bfd2f7ab89ff1cba2fa799d248c94893a`. It declares cat3advice 0.1.1
at `fca97de` and icesTAF 4.2.0. Its four source CSVs are listed as local
files in `DATA.bib` and are absent from the public tree:
`FSP_biomass.csv`, `advice_history.csv`,
`ple7d_STF_removals_from_7e_2024.csv` and `idxB_percentiles.csv`.
The executed `method/advice.rds` is also absent. The public scripts were
inspected as text, not executed to download software or upload to SAG.

The reported aggregates and method are substantially recovered, but complete
native age-disaggregated biomass, unrounded migration components, the MSE
exception-range inputs and executed advice object remain unavailable.
All source completeness statuses therefore remain partial. Historical
benchmark arrays are not substituted: catch, survey and migration inputs
were revised before the 2025 production advice, and the index revision also
affects earlier standardized values.

Official PDFs, pinned native scripts and provenance are cached under the
gitignored `source_cache/ck_ices_wgcse_platessa_is7e/`, with URLs, retrieval
dates, checksums and repository revision in the manifest. The 2026 chapter
is retained solely to establish current monitoring/advice status.

## Translation limit

The source does not support a current age-structured tinyAM fit: current
catch-at-age and biological surfaces are not recovered, while the official
rule does not estimate annual N/F/M-at-age, recruitment or absolute SSB.
The aggregate biomass index cannot be split into invented age-specific
number indices. MSE operating models and earlier trial SAM fits are not
substituted for official annual estimates.

No tinyAM fit, agreement statistics or comparison dashboard is claimed.
Preparation returns no stock specification, and tests ensure that the native
indicators do not fill standard SSB/F/N comparison tables. This is a source
and assessment-structure shortfall rather than numerical non-convergence.

## Validation

The importer passed a byte-identical second run and preserved every unrelated
canonical row. Full database validation passed: 118 stocks, 117 assessment
events, 2,245 assumptions, 364,550 inputs and 195,416 outputs. The source test
and eight related assessment-analysis checks passed (nine scripts total),
covering the preceding plaice/redfish imports, reference alignment, plus groups,
comparison definitions, default-first initialization and unit conversion.

The source vocabulary now distinguishes aggregate landings and discard biomass
under one actual fishery identity. Its validator permits missing component
observations while retaining the existing non-negative finite-value checks;
the initial missing-discard rejection was resolved without replacing blanks
with zeros. Permanent checks compare both published summary tables, propagate
rounding for catch sums and harvest rates, and reject conversion of the native
indicators into standard N/F/SSB references.

No core model mathematics or package API changed. The full package suite and
R CMD check were not repeated for this analysis-only milestone; their preceding
Area 4 reporting results were 2,936 passes and Status: OK, with tests run
separately. The wider assessment-analysis suite was not rerun, and previously
recorded unrelated failures are not claimed resolved. User readiness-table
edits were preserved and shared comparison tables were not regenerated.
## Sources

- [Final 2025 advice, version 3](https://doi.org/10.17895/ices.advice.29412776.v3), especially Tables 1, 2 and 9.
- [WGCSE 2025, version 3](https://doi.org/10.17895/ices.pub.29401877.v3), chapter 15, particularly Table 15.3.
- [WKBPLAICE, held 2024 and published 2025](https://doi.org/10.17895/ices.pub.28400255).
- [SAG 19546](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19546).
- [Pinned official source](https://github.com/ices-advice/2025_ple.27.7e/tree/31e51a7bfd2f7ab89ff1cba2fa799d248c94893a).
- [WGCSE 2026 monitoring](https://doi.org/10.17895/ices.pub.32625759), chapter 15.
