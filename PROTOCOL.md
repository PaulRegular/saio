# Assessment Database Curation Protocol

## Purpose

This document defines the standing protocol for adding, reviewing, and revising stock assessments in SAIO.

The governing question is:

> **For the latest official stock unit, what inputs, assumptions, and outputs can be recovered from the most recent publicly accessible detailed sources for the assessment used for advice?**

Source recovery comes before translation. The first priority is to recover
original model inputs and reported outputs from the most recent publicly
accessible detailed documentation for the latest assessment of the latest
stock unit. Record the model assumptions that explain those data. Keep the
latest-unit assessment as the primary record whenever at least one
run-specific input or reported output is verified, even if the record is
partial. A preceding stock definition is eligible only as a separate fallback
when a documented search finds no detailed run-specific input or output for
the latest current-unit assessment beyond summary advice. Assumptions or
settings alone do not count as recovered assessment data, but should still be
recorded for the latest unit. Never use a fallback to fill current-unit gaps.
Assess downstream uses only after source coverage and limitations are recorded. For each stock, follow this order:

1. Establish the latest official stock unit and the most recent assessment used
   for advice on that unit.
2. Search for detailed public sources for that assessment run, including
   research documents, native files, machine-readable tables, and repositories.
   Verify the run by its assessment year, terminal data year, model version,
   and reported results; a detailed report may be published after the advice.
3. For the latest unit and assessment, first capture every verifiable original
   model input and reported output in the detailed sources, then record the
   assumptions needed to understand them. Keep the current-unit record even
   when partial, record newer summary-only advice separately, and leave
   unavailable values unresolved. A missing input or output series within an
   otherwise detailed record is a source gap to pursue, not a reason to
   substitute an older run.
4. Only when a documented search finds no recoverable run-specific detailed
   input or reported output for the latest assessment of the latest unit may
   you add the most recent detailed assessment for a preceding stock
   definition. Preserve any verified latest-unit information and keep the
   fallback under separate stock and assessment IDs. Explain the boundary
   change and the fallback's limits; never use it to fill gaps in the
   latest-unit record.

Prioritize stocks by the availability of actionable detailed sources for the
latest official unit and assessment used for advice. Empty or partial database
rows are follow-up signals, not reasons to choose a different stock definition
or assessment. If the active task specifies an unworked stock set, stay within
that scope and prioritize source availability within it.

### Selecting stocks for an active task

Treat the active goal's stock set as the scope boundary. If it targets unworked
stocks with no input or output records, select only from that set; do not switch
to partly populated stocks because they are easier to source or translate.
Within the target set, prioritize stocks with actionable detailed sources for
the latest official unit and its assessment used for advice. For each selected
stock, follow Section 2.2: curate the latest-unit assessment first, retain its
verified partial data, and add a preceding-unit assessment only when a
documented search finds no recoverable run-specific detail for the latest
assessment beyond summary advice. Translation readiness does not affect stock
selection or the source-curation target.

Do not postpone recoverable assessment data while fitting or tuning a downstream model.

Follow the schema and controlled vocabularies in `DATABASE_STRUCTURE.md`.
The [scope and provenance statement](README.md#scope-and-verification) applies
to all records and their downstream use. Extraction and automated checks do
not substitute for verification against the authoritative sources.

Use this protocol and `DATABASE_STRUCTURE.md` to curate or repair source records. New source extraction and validation code should use R. Keep source importers separate from secondary analyses. Official assumptions, source reconstructions and unresolved data gaps belong here; downstream model settings, fitting attempts and comparison statistics do not.

At the start of source work, read both governing documents. Complete source curation independently of downstream software or model performance.

------------------------------------------------------------------------

# 1. Discovering candidate assessments

Use official stock and assessment inventories as the starting point for new
stock discovery. The Charbonneau–Keith catalogue is the seed already reviewed
and remains an identity and source cross-check. Its historical model labels do
not establish the current assessment or its inputs.

For the first expansion, audit NOAA Stock SMART and regional science-centre
inventories, ICES SID and working-group listings, and DFO sustainability-survey
and regional CSAS listings together. Record each inventory's retrieval date,
coverage limits and source. Inventory membership alone does not establish an
age-structured assessment or availability of model inputs.

Maintain the separate candidate register described in DATABASE_STRUCTURE.md.
Reconcile official identifiers, scientific names, areas, authorities and unit
boundaries against existing stocks, including joint assessments and splits or
mergers. Record uncertain matches for review; never create a duplicate merely
because a source uses another name. A new stock without a Charbonneau–Keith
match may leave charbonneau_id blank.

Screen public evidence for the latest official production run: catch numbers at
age, age-specific survey information, weights, maturity, mortality assumptions,
survey timing and comparable official outputs. Record source URLs, review date,
coverage, unresolved fields and the distinction between a confirmed absence and
an unsearched source. Direct age observations and source-supported reconstruction
from totals and age compositions are eligible; a model label or length compositions
alone do not establish eligibility. Do not manufacture observations from fitted
states or parameters. Preserve native likelihood inputs in the canonical database;
perform analysis-specific conversions outside the canonical database.

For an expansion batch, rank verified new stock units by recoverable inputs and
outputs and access to native or machine-readable sources. Use underrepresented
regions and species groups to break comparable-readiness ties, followed by stable
official identifiers. Do not count assessment years, sexes, variants or regional
components of one unit as additional stocks. Record source blockers and actual
shortfalls rather than guessing to meet a numerical target. Commit the reviewed
inventory and selected batch before importing numerical source data.

------------------------------------------------------------------------

# 2. Source hierarchy

After identifying the stock, seek evidence approximately in this order:

1. native fitted assessment object;
2. native assessment input and output files;
3. official reproducible assessment repository;
4. official machine-readable assessment tables;
5. official assessment or framework tables and appendices;
6. documented reconstruction from authoritative source information;
7. Charbonneau–Keith extracted values when they are the best available source or a useful cross-check.

Prefer the original input structure actually consumed by the official model.

When native model files or fitted objects are publicly available, inspect them before relying on transcribed report tables.

If the detailed production assessment omits a specification (for example survey
timing, catchability sharing, initial states or biomass definitions), consult
the framework or benchmark research document and the supporting survey reports
it cites before recording `unknown`. Confirm that the production model retains
that specification. Framework documents can clarify model structure; their
historical observations, parameter estimates and sensitivity outputs must not
be substituted for quantities from the represented production run. Record the
source and any remaining ambiguity explicitly.

## 2.1 Where to look for model objects, native files, and reproducible assessments

Before concluding that native model files are unavailable, search the main repositories and portals associated with the assessment authority and model family.

### ICES

Check the following resources:

- ICES Transparent Assessment Framework (TAF) GitHub organization:
  https://github.com/ices-taf

  TAF contains repositories for reproducible ICES assessments. Search using the ICES stock code, species, assessment year, and relevant expert-group acronym.

- ICES TAF portal:
  https://taf.ices.dk

- stockassessment.org:
  https://www.stockassessment.org

  This is particularly important for assessments fitted with SAM. When the short stock/case name is known, the R package `stockassessment` provides `fitfromweb()` for retrieving fitted SAM objects from stockassessment.org.

- `stockassessment` package documentation:
  https://fishfollower.r-universe.dev/stockassessment

  Use this to understand the contents of SAM objects and functions such as `fitfromweb()`, `read.data.files()`, `loadConf()`, and related extraction tools.

- ICES Scientific Reports / ICES Library:
  https://ices-library.figshare.com

  Search for the relevant assessment working group, benchmark workshop, stock code, species, and year. Working-group reports often contain detailed assessment methods, tables, annexes, and links or references to model files.

- ICES Stock Assessment Graphs:
  https://standardgraphs.ices.dk/stockList.aspx

  Useful for published stock-level graphs, tables, and downloadable assessment time series.

- ICES Advice and Scenarios Database:
  https://asd.ices.dk

  Useful for confirming current advice, stock codes, assessment year, advice category, and links to published advice.

Do not assume that the newest repository or stockassessment.org case is the official assessment. TAF and stockassessment.org may contain historical, test, benchmark, sensitivity, or development runs. Confirm the official assessment against ICES advice and working-group or benchmark documentation.

### Fisheries and Oceans Canada (DFO)

Check:

- Canadian Science Advisory Secretariat (CSAS):
  https://www.dfo-mpo.gc.ca/csas-sccs/index-eng.htm

- DFO science reports and publications:
  https://www.dfo-mpo.gc.ca/science/publications/reports-rapports-eng.html

Search for the species, stock area, assessment year, Research Document, Science Advisory Report, Science Response, and Proceedings.

CSAS Research Documents and Proceedings are particularly important because detailed assessment inputs, model descriptions, diagnostics, and appendices may appear there even when the Science Advisory Report contains only summary results.

Also follow any repositories, supplementary files, R packages, data archives, or model-object links cited in CSAS documents. DFO does not have a single public repository containing all assessment model objects, so stock-specific searches may be necessary.

### NAFO

Check:

- NAFO Library and Archives:
  https://www.nafo.int/Library/NAFOdocuments

- NAFO Scientific Council documents:
  https://www.nafo.int/Library/Science/SC-Documents/ev/1

- NAFO Scientific Council Reports:
  https://www.nafo.int/Library/Science-Council/Annual-Scientific-Council-Report-Compilations/ev/1

- NAFO stock advice:
  https://www.nafo.int/Science/Science-Advice/Stock-advice

Search by stock, NAFO Division/Subarea, assessment year, SCR document number, SCS document number, and Scientific Council meeting.

Scientific Council Research Documents (SCRs) can contain substantially more assessment detail than summary advice sheets, including model formulations, input tables, sensitivity analyses, and references to data or code.

Where a stock is assessed jointly or closely connected with ICES, also search the ICES Library and relevant joint working-group reports.

### NOAA Fisheries

Start with:

- NOAA Population Assessments resources:
  https://www.fisheries.noaa.gov/topic/population-assessments/resources

- Stock SMART:
  https://www.fisheries.noaa.gov/resource/tool-app/stock-smart

Stock SMART is useful for confirming assessment identity, year, stock status, reference points, and published output time series, but it will not usually contain the full native age-structured model input files.

For Alaska and North Pacific assessments, also search:

- Alaska Fisheries Science Center GitHub:
  https://github.com/noaa-afsc

Many AFSC stock-specific repositories contain assessment code, Stock Synthesis configurations, input files, output files, SAFE documents, and assessment run material.

For Northeast U.S. assessments, check:

- Northeast Stock Assessment Documents Search Tool:
  https://www.fisheries.noaa.gov/resource/publications-database/northeast-stock-assessment-documents-search-tool

- Stock Assessment Review Index (SARI):
  https://apps-nefsc.fisheries.noaa.gov/saw/sari.php

For Stock Synthesis assessments, search stock-specific repositories for files such as:

- `data.ss`;
- `control.ss`;
- `starter.ss`;
- `forecast.ss`;
- `Report.sso`;
- model run directories;
- associated R scripts and input tables.

NOAA GitHub repositories are distributed across programs and science centers rather than one universal stock-assessment repository. Search using the official stock name, assessment area, assessment year, model family, and science-center acronym.

## 2.2 Search strategy when the model object is not immediately obvious

For each assessment, search combinations of:

- official stock code;
- species name;
- stock area or management unit;
- assessment year;
- benchmark/framework year;
- expert-group or working-group acronym;
- model family, e.g. SAM, Stock Synthesis, WHAM, ASAP, VPA/ADAPT;
- phrases such as `assessment`, `benchmark`, `model`, `input`, `data`, `run`, `repository`, and `GitHub`.

When a report cites a model repository, supplemental dataset, package, or file archive, follow that trail before transcribing tables manually.

If multiple candidate model runs are found, determine which one corresponds to the official assessment by comparing:

- terminal data year;
- assessment year;
- model version;
- fleet and survey structure;
- age range;
- reported SSB, recruitment, and F trajectories;
- benchmark or working-group documentation.

Do not select a model object solely because it is the newest file or repository.

### Select the stock unit and detailed assessment

The latest official stock unit is always the primary database target. If the
unit has changed, do not default to the older definition represented in a
catalogue or an earlier assessment. First identify the latest assessment used
for advice on the current unit, then search for detailed sources for that run.
Publication date and assessment year can differ, so confirm the run using its
model version, terminal data year and reported results.

Recover and validate the inputs, assumptions and outputs available for the
latest run, even when the resulting source record is partial. Record newer
summary-only advice or information separately. Do not replace the latest run
with an older, more detailed assessment simply because the older material is
easier to use or more compatible with a downstream analysis. An older run of the same unit
may be retained separately when useful, but it does not stand in for the
latest run.

Judge source detail by what it documents about the official run, not by
whether it can be fitted with downstream software. The assessment need not be age-structured or
fit-ready for its source data to be curated. Preserve aggregate and index-based
methods in their source units and dimensions; do not manufacture age-specific
states. If a source requires a new schema measure, document it and update the
relevant validation before importing it.

If the latest assessment for the latest unit is available only as summary
advice, or no run-specific detailed input or reported output can be recovered
after a documented search of relevant authoritative sources, retain and record
any verified latest-unit information and document the remaining gaps. A missing
input or output series within an otherwise detailed record of the latest run is
a gap to pursue, not by itself a reason to switch stock units. Assumptions,
settings, or model descriptions without run-specific inputs or outputs should
still be documented, but do not by themselves prevent a separate fallback to
the most recent publicly accessible detailed official assessment for the
preceding stock definition. Document where you searched, which detailed
materials were unavailable, the latest and preceding stock boundaries and
codes, and why the fallback is useful. Never use fallback data to fill gaps in
or replace the latest-unit record. Do not fall back because the earlier
assessment is more complete, easier to fit, or more likely to agree with
a downstream model. There is no fixed numerical completeness threshold; explain the
available material and selection rationale in the stock review.

Apply this distinction consistently: a partial detailed record has at least
one assessment-specific model input or reported output verified for the latest
production run from a detailed source. Keep that current-unit record as the
primary target and pursue its remaining source gaps. Detailed assessment data
are unavailable when a documented search finds no recoverable run-specific
input or output beyond summary advice; in that case, a separate earlier-unit
fallback is appropriate even if assumptions or settings for the latest run are
known. Keep all latest-unit information attached to that unit, and never
combine it with the fallback assessment.

Keep the latest-unit assessment and the earlier-unit fallback under separate
stock and assessment IDs. Never copy, pool or relabel data across the changed
boundaries, and never imply that fallback results apply to the latest unit.
Retain verified partial data for the latest unit even when an earlier unit
supplies the detailed fallback. Revisit the selection if detailed data for the
latest assessment become publicly available.

Keep distinct stock units and assessment runs identifiable under their own stock
and assessment IDs. Record their relationship in stock notes and source reviews;
do not copy, pool or relabel data across changed boundaries or runs. Do not
create duplicate assessments for sex-specific catalogue aliases or guess an
unresolved stock identity. Mark the selected detailed assessment for each
represented stock record `is_current = TRUE` under the existing schema. This
flag describes the selected detailed assessment for that record; it does not
establish that a historical stock unit is the latest unit or that its assessment
is the latest advice. Record that distinction and any fallback explicitly in
the stock and assessment notes. `is_applied` separately describes whether the
assessment was used for advice in its cycle.

If a newer official assessment is documented only in summary material, record
it separately and explain which details were unavailable. Its published values
belong to that assessment alone and must not be substituted for or combined
with another run's inputs or outputs. Keep unresolved gaps visible and
completeness statuses partial where appropriate.

A detailed Research Document may be published a year or more after its Science Advisory Report or other summary product, so publication year and assessment year must not be treated as the same thing. Check the model version, terminal data year, and official run described by the detailed source, and record the assessment year and data terminal year separately from the source's publication date.

## 2.3 Source discipline

Do not:

- reconstruct an input from fitted outputs when the original input is available;
- manufacture missing values;
- assume a prominently reported quantity is necessarily a fitted-model input;
- assume that a public model object is the official assessment without verification;
- mix inputs or outputs from different assessment runs.

Within the same assessment, prioritize the most complete age and time detail supported by authoritative sources. Do not collapse or pool observations merely to imitate the coarser groups used by the model when more detailed source values are available. Preserve the model-ready grouped data and the more detailed table as distinct records when both are informative, and label each record's role and provenance.

Preserve the most detailed defensible source series and the official likelihood grouping. Record report rounding and unresolved precision limits. Aggregation to a different model age grid and avoidance of duplicated observations are responsibilities of the downstream analysis, not reasons to change canonical source records.

Keep raw observations, model inputs, transformed inputs, fitted values, outputs, and diagnostics conceptually distinct.

When the native assessment object or input files are found, preserve their provenance and use them as the preferred basis for populating the database. Report tables should generally be used as a cross-check or fallback when native inputs are available.

------------------------------------------------------------------------

# 3. Identify the official assessment and inventory the model

Before extracting numerical data, establish:

- latest stock unit, assessment authority, boundary changes, and related earlier units;
- latest official assessment and data terminal year;
- selected publicly accessible detailed assessment and any earlier-unit fallback, with reasons and missing current-unit data;
- terminal fitted data year;
- model family/version where known;
- model-defining benchmark or framework when distinct;
- official/base run when several runs are presented.

Do not infer official status from filenames alone.

Avoid test, sensitivity, preliminary, forecast-only, development, experimental, clone, and alternate runs unless official documentation identifies one as official.

If an annual assessment continues to use a model defined at an earlier benchmark/framework, record both assessment and framework years.

Then inventory the structure actually used by the official model:

- modeled years;
- modeled ages;
- recruitment age;
- terminal plus group;
- fishing fleets;
- survey/index series;
- sexes;
- spatial regions;
- seasons;
- landings, discards, and other removal components.

This inventory defines what must be curated.

A source table is material when it is:

1.  an input to the official model;
2.  an output from the official model; or
3.  needed to reconstruct an official-model input that is not directly available.

------------------------------------------------------------------------

# 4. Curate numerical inputs

## 4.1 Catch and removals

Capture every fitted catch/removal fleet separately.

Preserve the representation actually used by the model, including as applicable:

- numbers-at-age;
- biomass-at-age;
- total numbers;
- total biomass;
- proportions-at-age by number;
- proportions-at-age by biomass;
- landings;
- discards;
- other removals.

If the model uses a total plus an age composition, retain both.

Catch-at-age is a priority input for age-disaggregated source coverage.
If a report supplies proportions describing an underlying catch-at-age input,
recover that input using matching totals and, when biomass is involved,
compatible catch weights; document the calculation. If the official model
instead fits totals and compositions separately, preserve those native inputs
and derive any secondary catch-at-age series outside the canonical database. Do not count
the native and reconstructed representations twice.

Total landings are otherwise optional unless the official model uses them or
they are needed for a documented conversion. Detailed gear splits are not
required unless they correspond to separate fitted fleets.

If the model combines several real-world fisheries into one modeled fleet, represent the modeled fleet rather than inventing finer fleet distinctions.

Capture catch weight-at-age when it is an explicit model input or needed to interpret a biomass-based catch input.

For catch compositions, determine whether values are:

- number proportions;
- biomass proportions;
- normalized frequencies;
- sample counts;
- another composition measure.

Do not infer the basis merely because values sum to one.

Capture composition weighting or effective sample size when it is a material model input.

## 4.2 Surveys and indices

Capture **every survey/index used by the official model**.

For each fitted survey, determine as applicable:

- survey identity;
- fitted spatial extent;
- years and ages used;
- native index measure;
- total abundance or biomass;
- direct abundance- or biomass-at-age;
- age composition and its basis;
- sex and season;
- sampling timing.

If the model uses an aggregate index plus an age composition, retain both.

Do not replace source totals/compositions with a derived age-specific abundance series unless that derived series was itself the official-model input.

Match the spatial scale used by the fitted model. If published material contains finer subareas than the model fits, do not treat them as separate fitted indices.

If the official model uses a combined index and only component values are published, reconstruct the combined input only when the aggregation is documented or defensible from authoritative information, and record the transformation.

For survey timing, prefer model configuration or documented timing. If only approximate timing can be recovered, document the limitation rather than inventing precision.

## 4.3 Biological inputs

Capture as applicable:

- stock weight-at-age;
- catch weight-at-age;
- survey-specific weight-at-age;
- maturity-at-age;
- natural mortality;
- spawning timing;
- fraction of fishing mortality before spawning;
- fraction of natural mortality before spawning.

Preserve annual variation when used by the official model.

If a model uses a constant vector, store the source vector rather than manufacturing repeated annual rows unless the source itself represents a complete matrix.

Keep stock weight and catch weight distinct.

For maturity, preserve the official sex convention rather than averaging sexes arbitrarily.

For natural mortality, distinguish:

- constant M;
- age-specific M;
- year-specific M;
- age-year M;
- internally estimated M.

Capture numerical M whenever it is a fixed or externally supplied input. If M is estimated internally, document the assumption and capture estimated M in `outputs.csv` where available.

------------------------------------------------------------------------

# 5. Curate model assumptions

Use `assumptions.csv` for the biological and statistical structure of the official model.

Investigate at least:

## Population and recruitment

- modeled years and ages;
- recruitment age;
- plus group;
- sex/spatial/seasonal structure;
- recruitment treatment;
- stock-recruit relationship where applicable;
- process-error structure;
- abundance/recruitment deviations and correlations.

## Fishing mortality

For each fitted fleet: - selectivity or F structure; - state sharing; - temporal process; - age correlation; - variance structure; - catch likelihood and observation variance.

## Natural mortality

- fixed versus estimated;
- age/time structure;
- process or estimation structure.

## Surveys and catchability

For every fitted survey: - sampling timing; - q/catchability structure; - q age blocks/sharing; - q time variation; - observation likelihood; - observation variance; - observation correlation.

## Biology

- stock and catch weights;
- maturity;
- spawning timing assumptions.

If an assumption cannot be resolved, record:

``` text
value = unknown
```

and explain the uncertainty.

Never infer statistical meaning from a field name, integer key, shorthand code, or parameter index without checking documentation or implementation.

------------------------------------------------------------------------

# 6. Curate outputs

Recover outputs needed to characterize the official assessment.

## High priority

- numbers-at-age;
- fishing mortality-at-age;
- natural mortality-at-age when estimated;
- spawning-stock biomass;
- recruitment.

## Secondary, where available

- total biomass;
- Fbar;
- Mbar when estimated;
- catchability estimates;
- predicted catch;
- predicted survey indices;
- Fmsy;
- Bmsy;
- MSY.

Preserve fleet, survey, sex, region, and season dimensions where the output is specific to them.

Retain uncertainty when practical.

Document the SE scale, interval level and type, and point-estimate convention
using the rules in `DATABASE_STRUCTURE.md`. A reported CV or log-scale SE
must not be presented as a natural-scale SE without a documented conversion.

Do not use fitted outputs as substitutes for source inputs.

------------------------------------------------------------------------

# 7. Transformations and reconstruction

The canonical database may standardize representation without changing scientific meaning.

Allowed examples include:

- wide-to-long reshaping;
- standardized variable names;
- explicit fleet/survey labels;
- standardized missing-value representation.

Do not silently:

- convert biomass to numbers;
- combine fleets or surveys;
- combine regions;
- change plus-group definitions;
- interpolate missing biological values;
- replace total-plus-composition inputs with derived age-specific values.

A scientific transformation is allowed only when needed to recover the **actual input used by the official assessment** and the model-ready input is not directly available.

In that case:

- use `source_type = reconstructed_source_input`;
- document the formula or aggregation in `transformation`;
- cite the source quantities;
- retain component source quantities when useful;
- do not present the reconstructed value as directly published.

This exception concerns reconstruction of the official assessment, not preparation for a downstream analysis.

These restrictions apply to canonical source records. Analysis-specific observations, settings, comparisons and fitted results belong outside this repository.

------------------------------------------------------------------------

# 8. Completeness and source cache

An assessment is input-complete when all material input streams used by the official model have been represented or transparently reconstructed.

This includes, where applicable:

- all fitted fleets;
- all fitted surveys;
- biological inputs;
- natural mortality inputs;
- material sex, spatial, and seasonal structure.

Do not declare an assessment input-complete merely because one usable catch series and one survey have been found.

`outputs_status` and `assumptions_status` likewise refer to completeness relative to the official assessment.

## Stock source reviews

When reviewing model specifications, verify the actual source equations and
parameter activation, not only labels such as RW, AR1, BH or logistic. Record
which curve, variance and correlation parameters are estimated, fixed,
penalized or mapped out in the official run. Check recruitment age and parent
year, spawning-time survival, lognormal bias corrections, selectivity
normalization and the scale on which covariates/processes act. Consult the
framework/benchmark and pinned native code when the production report omits
these details. An unused input array is not evidence of an active process;
a logistic survey curve does not establish logistic fishery F. Preserve these
source facts in the canonical assumptions; downstream candidate choices and
their diagnostics belong in the translation review, not the database.

Keep stock-specific review notes in one Markdown file per stock under
`source_reviews/`, named with the stable stock ID.
Use that file for official-run verification, source trails, input and output
coverage, transformations, validation findings, and unresolved gaps. When a
stock has several assessment records, identify the assessment IDs and keep
run-specific notes clearly separated within the stock's file.

Keep the README focused on the database's purpose, structure and usage, with
a compact index linking to the stock review files. Do not put detailed
stock-specific review notes in the README or duplicate them there. Move any
existing stock notes into the appropriate review file when revisiting a stock.
The database tables remain the source of numerical values, assumptions,
provenance and completeness statuses; review files explain the supporting
checks and limitations.

## Source cache

For every stock processed or revisited, cache the authoritative source files
used for curation locally under:

``` text
source_cache/
```

This directory must remain gitignored.

Useful cached artifacts include assessment/framework PDFs, native input/output files, fitted objects, supplementary CSVs, and configuration files.

Organize files by stock and assessment run. Maintain a manifest identifying the
source URL, retrieval date, file checksum, and represented assessment. Record
failed or restricted downloads and any alternative source used. Keep useful
files already cached; do not download every document or unrelated material.

Use the cache to repair canonical records. Routine downstream data preparation and
fitting workflow reads the database, not native files from the cache.

Keep authoritative URLs in `assessments.csv`.

Do not mix artifacts from different assessment runs without preserving provenance.

------------------------------------------------------------------------

# 9. Per-assessment workflow and completion criteria

For every assessment:

1.  locate the stock in Charbonneau–Keith where applicable, record its identifier, and verify the latest official stock unit;
2.  verify the latest official assessment used for advice and select the accessible detailed official/base run, including any documented earlier-unit fallback under Section 2.2;
3.  identify the model-defining benchmark/framework;
4.  inventory modeled years, ages, fleets, surveys, sexes, regions, seasons, and plus group;
5.  enumerate all material input streams before extraction;
6.  curate catch/removal inputs for every fitted fleet;
7.  curate every survey/index used by the official model;
8.  curate biological and natural-mortality inputs;
9.  curate source-model assumptions;
10. curate high-priority outputs;
11. run structural validation;
12. compare represented fleets and surveys against the official-model inventory;
13. assign completeness statuses and record missing items;
14. record the reviewed changes for the next database batch. See
    [Batch commits and snapshots](#batch-commits-and-snapshots).

Before declaring the assessment curated, report compactly:

``` text
Identity:
  stock
  Charbonneau ID
  assessment year
  terminal year
  model/framework/base run

Model dimensions:
  years
  ages
  recruitment age
  plus group
  fleets
  surveys
  sexes/regions/seasons

Inputs:
  fleet coverage
  survey coverage
  biology
  M

Outputs:
  N-at-age
  F-at-age
  M-at-age if estimated
  SSB
  recruitment
  other important outputs

Status:
  inputs_status
  outputs_status
  assumptions_status
  missing/unresolved items
```

Do not treat one or two useful data streams as a complete assessment. Pursue the material source streams, document genuine gaps after searching the relevant sources, preserve verified partial records, and continue with other stocks when necessary.

## Gaps discovered during reuse

When a translator identifies a missing or inconsistent source input,
assumption, or output, return to this protocol and revisit that stock's
authoritative sources. Correct or complete the canonical records, update the
source review and relevant completeness statuses, run validation, and reload
the revised database before retrying translation. Record the database revision
used in the resulting analysis.

Do not change source values, drop required ages, or shorten the fitted period
simply to make downstream software accept the data. Document a genuine unresolved source gap
and continue with other requested stocks when it cannot be filled.

Distinguish these gaps from unsupported source-model features. For example,
an assessment that estimates M may have no fixed numerical M input to recover.
Curate its actual assumptions and estimated outputs; choose any simplified
M treatment outside the canonical tables.

Curation does not depend on a downstream fit. Missing source data, an unsupported method or numerical failure in another analysis does not make verified source data ineligible for this database.

------------------------------------------------------------------------

# 10. Validation and final review

Run the structural validation defined in `DATABASE_STRUCTURE.md`.

Structural validation does not establish scientific completeness.

Also verify that:

- every expected fitted fleet is represented;
- every expected fitted survey is represented;
- spatial/sex/seasonal dimensions match the official model;
- outputs and assumptions are not being substituted for inputs;
- reconstructed inputs are explicitly identified and documented.

Prefer:

> incomplete but correct

over:

> complete but guessed.

When information is unclear, inspect native files, fitted objects, framework documents, appendices, official repositories, and Charbonneau–Keith source notes before recording `unknown`.

## Batch commits and snapshots

1. Commit reviewed importers, source manifests, reviews and tests in small,
   logical steps. Build and test candidate table updates in a local working
   copy. Combine reviewed changes to the five consolidated tables into one
   data commit per batch. Keep unrelated edits out of that commit. A
   time-sensitive correction can be its own batch. Git LFS stores a full new
   copy of each changed table, so a single push containing many table commits
   still carries their distinct file versions.
   [GitHub LFS storage](https://docs.github.com/en/billing/concepts/product-billing/git-lfs)
2. Validate the combined tables from the repository root with
   `Rscript scripts/database/002_validate_database.R` and run the affected
   source tests. Record the included assessment IDs and any changes to units,
   definitions or schema in the batch commit or its accompanying notes.
3. For a milestone used by an analysis or publication, archive the exact five
   CSVs at the committed SAIO revision in one compressed file. Record the full
   SAIO SHA, the analysis code revision, the software versions and the
   reproduction commands in the consuming project. Include a manifest of
   table paths, byte sizes and SHA-256 hashes, plus a checksum for the archive.
   Keep a recoverable copy separate from the working LFS cache and retain the
   source attribution and reuse terms.
4. Verify the archive by extracting it into a temporary directory and matching
   all five table hashes and sizes to the Git LFS pointers at the recorded
   SAIO SHA. Check that the tables load and that the analysis can rebuild its
   milestone outputs from the recorded inputs. Keep milestone archives and
   their manifests immutable. Create a new snapshot for a correction.

After a successful data push, use Git LFS to preview local cache cleanup against
GitHub. Repeat without `--dry-run` after reviewing the result. The verification
options retain objects GitHub cannot verify, including objects referenced only
locally. To recover a pruned milestone from GitHub, run
`git lfs fetch origin <SAIO SHA>`. [Git LFS prune](https://github.com/git-lfs/git-lfs/blob/v3.5.1/docs/man/git-lfs-prune.adoc)

```sh
git fetch origin
git lfs prune --dry-run --verify-remote --verify-unreachable --when-unverified=continue
```

------------------------------------------------------------------------

# 11. Scope discipline

Do not:

- turn the database into a new R package;
- build database-server infrastructure;
- preemptively build generic model-format converters;
- archive every document;
- collect unrelated descriptive tables;
- aggregate away fitted fleets or surveys in canonical inputs;
- create derived series solely for a downstream analysis;
- alter source-assessment values to make them easier to use elsewhere.

Reusable source-specific helpers may be added later when repeated real use justifies them.

------------------------------------------------------------------------

# 12. Agent task completion

The protocol does not define how many assessments to add or review. The active task does.

Report complete and partial source records, the selected assessment and stock unit, any earlier-unit fallback, and unresolved gaps. Keep downstream modelling progress outside canonical completeness fields.

If the goal says:

> Add 10 assessments

the task is complete only after 10 assessments have been added according to this protocol, unless an external blocker requires user intervention.

Completing a representative subset does not satisfy a numeric target.

For long-running tasks, report progress explicitly:

``` text
Progress: 4 / 10 assessments completed.
```

If one requested assessment is blocked by unavailable authoritative source material, document the blocker and continue with the remaining requested assessments unless user guidance is required before substitution.

A final multi-assessment report should state:

- target number;
- number complete;
- number partial;
- number blocked;
- assessment IDs;
- commits created;
- major missing data or unresolved assumptions.

Do not stop merely because the workflow has been demonstrated successfully on a subset.
