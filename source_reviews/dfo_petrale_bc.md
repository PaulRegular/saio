# British Columbia petrale sole

## Record and readiness

`dfo_petrale_bc_2024` is imported as a **partial summary/public-output record**.
It is the official applied assessment (`is_applied = TRUE`), but is not marked
as the current detailed record (`is_current = FALSE`): original observations,
biology and the final production configuration remain unrecovered. All three
canonical completeness fields are `partial`. No earlier detailed run has
been substituted, and the stock is not counted as a completed translation.

The stock is one coastwide Canadian catalogue exception in the Northeast
Pacific. Neither `Master.csv` nor the PLOS metadata at Charbonneau revision
`7e4daca3cbfc14ce7fa0b28ed824eebe7113249b` contains a petrale/Eopsetta match.
No catalogue identifier was invented.

## Official assessment

The coastwide 2024 assessment is documented in
[Science Advisory Report 2025/002](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4127961x.pdf).
It uses a two-sex Stock Synthesis catch-at-age model: catches for 1938–2023,
three synoptic survey indices for 2003–2023, and fishery/survey age compositions
for 2004–2019. The official result is an ensemble with fixed M of 0.154, 0.124
and 0.184, weighted 50%, 25% and 25%, respectively. A single base-M fit would
be a component approximation, not the official ensemble.

No final matching detailed research document was located in this search.
The 2024 State of the Pacific Ocean technical report cites the Mazur, Holt,
Fisch and English research document as in press. That citation does not
establish its present publication status. An older public working template
is not used as a production assessment source. The government open-science
catalogue search recovered the advisory report, not native input files. Direct
research-document index requests returned access-error HTML, not verified
publication inventories; this is a search limitation, not proof of absence.

## Input and assumption inventory

The database retains three reported numerical M settings as distinct scalar
inputs: `fixed_mortality_medium`, `fixed_mortality_low` and
`fixed_mortality_high`. They have no invented age, year or sex grid and are
not averaged into a single mortality input. Their mixture weights and known
source methods are recorded among 33 assumptions, including all three surveys.

No numerical catch, index, weight or maturity observations were recovered.
The missing observations are not zeros. Survey timing, native composition
basis and sex normalization, population ages/plus group, recruitment age,
biological coefficients, q/SD sharing, and detailed parameter activation remain
explicitly unresolved. Script column positions and generic SS3 defaults are
not used to infer them. No information is borrowed from U.S. petrale or the
preliminary Canadian working template.

## Recovered numerical output

The [gftrends repository](https://github.com/pbs-assess/gftrends/tree/7f1c59b8cc3895a3477204ac16da6cf15e2466c6)
provides `data-raw/petrale-sole-bc-mcmc-2024.rds` and its processing script.
The cached object has 174,000 rows: **2,000 complete posterior SSB trajectories
for 1938–2024**, with corresponding BMSY and reference points. There are no
duplicate draw/year cells, and all biomass values are finite and positive.
The script extracts `SSB_1938` through `SSB_2024` from medium-, low- and high-M
nuisance-posterior CSVs, joins BMSY by draw and downsamples to 2,000 draws.
The underlying CSVs are not included in the inspected public tree.

| Quantity | Cached 2.5% | Cached median | Cached 97.5% | Official report 2.5% / median / 97.5% |
|---|---:|---:|---:|---|
| Female SSB in 2024 (t) | 10,512.47 | 17,274.80 | 28,107.54 | 10,830 / 17,330 / 27,977 |
| BMSY (t) | 2,798.42 | 5,729.49 | 8,342.80 | 2,793 / 5,704 / 8,323 |

These are close, but not identical, summaries. Downsampling is documented.
The `hdiAnalysis` repository at
`0d0e0c0910fddaf1636b4471299acd4e409d6ef3` provides an independent larger
relative-biomass object (27,995 draws for 1938–2023). Its accompanying report
records the authors' intended mixture: 14,000 medium-M draws and 7,000 each
from low/high M, with five missing BMSY values. This corroborates mixture
intent, but does not identify component membership in the 2,000-draw gftrends
subset. Do not reweight it again or label its summaries as exact published quantiles.
The 2024 state is the assessment boundary after catches through 2023, not an
additional observed catch year.

The canonical outputs contain 87 annual SSB medians with equal-tail 95%
credible limits, calculated with R's default type-7 quantiles. Standard errors
remain missing. The exact published 2024 SSB is retained separately as
`published_terminal_SSB`, alongside Table 1 BMSY and FMSY. Reference-point
rows use 2024 to identify the assessment boundary, not an annual varying
reference-point series. No N, F-at-age, estimated M or recruitment outputs
were invented.

## Remaining readiness requirements

The [pbs-assess/petrale repository](https://github.com/pbs-assess/petrale/tree/fc214bd26288dd98633d3e6b2c0c7f1bddca5db0)
contains environmental-analysis scripts for assessment appendices. They read
external SS3 outputs and `mcmcresults.RData`; those objects and the native
production input arrays are not in the inspected tree. The recovered gftrends
object contains no N-at-age, F-at-age or recruitment. Original catch/survey
composition arrays, biological inputs, timing, likelihood weights and final
configuration must be recovered before a faithful tinyAM translation.

The follow-up inspected related `recruitea`, `gfenvirocor`, `gfcondition` and
`gfcondition-ms` repositories, readme-based repository search results, and all
four commits of `pbs-assess/petrale` and both commits of `cgrandin/petrale`.
These did not recover matching production observations or biology. The
larger `hdiAnalysis` data are relative biomass, not original assessment inputs
or N/F/recruitment. Searches and failed downloads remain in the cache manifest.

BC petrale remains a promising Canadian comparison candidate, with numerical
SSB now preserved in the canonical database. Fitting is **source-blocked**.
These source gaps must be resolved before preparing a model. There is no
catch-only substitute, invented `fit_tam()` model, optimizer result or dashboard.

The stock entry point is
`scripts/translation/stocks/dfo_petrale_bc_2024.R`. It records the source
background and stops with the missing-input inventory before `prepare_tam()`
or `fit_tam()`, for both `fit = FALSE` and `fit = TRUE`. An explicit runner
attempt is recorded as `translation_failed`, with no optimizer or uncertainty
values. It is not an actual optimization attempt or a completed translation.
The non-current summary record is excluded from the default detailed-case
batch; it can still be inspected or explicitly requested by assessment ID.

## Cache and checks — 2026-10-17

The import is reproducible through
`scripts/database/069_import_bc_petrale_2024.R`. It retrieves pinned public
sources into `source_cache/dfo_petrale_bc/`, validates draw coverage and appends
only this stock. Retrieval is part of curation, not the routine fitting path.
The wider search inventory is retained under
`source_cache/dfo_petrale_bc_2024_preflight/`. The validated advisory PDF is the
Waves copy; the publications.gc.ca download returned HTML and is excluded.
Offline tests verify quantile mathematics, complete year/draw coverage,
duplicate/missing/invalid-draw rejection, units, provenance, component M scalars,
and separation of subset and published uncertainty. Database structural
validation passes. All pre-existing canonical records remain unchanged; no
package mathematics or API was changed.

The explicit readiness attempt used committed database revision `2a66fcf` and
stopped before optimization. Both new-case test files pass. All 65
assessment-analysis files were run: 59 pass, with the same six pre-existing
failures in age-subset, Southern Gulf herring, F-process, herring, Norway pout
and general translation fixtures. The stock-script inventory test now explicitly
checks the documented BC POP and BC petrale blockers; its runnable-case
assertions are unchanged. The full package suite passes with one
interactive-only skip. `R CMD check --no-manual --no-tests` has zero errors,
zero warnings and the existing `plot_bubbles`/`head` NOTE; package tests ran
separately. The initial check's invalid inherited locale was corrected for the
check process without changing package code. Logs and the readiness result
remain local. No agreement or convergence statistics exist for this case.
