# Assessment Database Structure

## Purpose

This document defines the schema for the stock-assessment database in `database/`.

The database preserves, in a tidy and auditable form, the available inputs, assumptions, and outputs of official stock assessments. Source curation records age-structured and other official assessment methods when supported by the schema.

The canonical database contains five CSV files:

``` text
saio/
└── database/
    ├── stocks.csv
    ├── assessments.csv
    ├── assumptions.csv
    ├── inputs.csv
    └── outputs.csv
```

All canonical tables should remain ordinary CSV files so they can be inspected directly in R, Excel, or a text editor.

This document defines the canonical source records and database schema. It does
not define stock-specific analysis transformations, model settings, or
comparisons. Use `PROTOCOL.md` to obtain, verify, or repair records. If a
downstream analysis reveals a source-data gap, validate and revise the affected
database records while keeping analysis-specific choices separate.

## Candidate register

Keep discovery records in a separate version-controlled register under
`discovery/`, outside the five canonical source tables. A row
identifies an official candidate stock unit, its organization, scientific name,
area, latest assessment and source links; record inventory date and coverage,
matched stock ID or unresolved identity, evidence for each key input and output,
and the screening decision and reason. Track screening, eligibility and import
progress separately from canonical input/output completeness and translation
results. `candidate_unit_id` is an internal cross-inventory key for source rows
verified to represent the same biological or management unit. It is not an
official identifier or a canonical `stock_id`; leave it blank until the unit
crosswalk is supported by source evidence. Use `matched_stock_id` when the unit is
already represented in the canonical database. `match_status` describes the current
database crosswalk. After a newly curated unit is added, set `matched_stock_id` to
its canonical `stock_id` and change `match_status` to `matched`. Inventory rows alone
do not create canonical assessment events or values. `charbonneau_id` may be blank when no
verified catalogue match exists.

The current controlled basin vocabulary is validated by the database validator.
When a verified new stock requires another basin, add and document a specific
label and update validation alongside that import. `Southern Indian Ocean` is
used for the SIOFA orange roughy assessment area. For example, the SESSF
Commonwealth Trawl Sector blue grenadier unit covers waters labelled as the
Southern Ocean and Tasman Sea; preserve that extent with the documented label Southwest Pacific and Southern Ocean. The
Australian Hydrographic Office places the Great Australian Bight within the
Southern Ocean; use that basin label for GAB assessment units. Preserve the
stock's precise extent in area and region, including genuinely wide-ranging
units; do not force Southern Hemisphere stocks into a single basin when the
assessment unit crosses basins.

## Core principles

1.  **Represent the official assessment faithfully.** Preserve the dimensions and meaning of the official model, including fleets, surveys, sexes, regions, and seasons where applicable.
2.  **Preserve provenance.** Material data and assumptions should be traceable to an authoritative file, object, table, document, or documented reconstruction.
3.  **Keep the canonical database source-focused.** Tidy reshaping is allowed, but downstream-analysis transformations and settings do not belong in the canonical tables.

------------------------------------------------------------------------

# Relationships

``` text
stocks.csv
    1
    |
    +----< assessments.csv
               1
               |
               +----< assumptions.csv
               |
               +----< inputs.csv
               |
               +----< outputs.csv
```

`stock_id` identifies the biological or management stock. Keep distinct stock
units identifiable when boundaries split, merge or otherwise change, and record
their relationship in notes.

`assessment_id` identifies a particular assessment event or official assessment run.

------------------------------------------------------------------------

# 1. `stocks.csv`

One row per biological or management stock.

## Required columns

| Column | Description |
|------------------------------------|------------------------------------|
| `stock_id` | Stable internal identifier for the stock |
| `charbonneau_id` | Identifier in the Charbonneau–Keith database, when applicable |
| `authority` | Assessment authority, e.g. DFO, ICES, NOAA-AFSC |
| `authority_stock_id` | Current official stock identifier/code |
| `scientific_name` | Scientific name |
| `common_name` | Common name |
| `area` | Assessment or management area |
| `region` | Broader geographic region |
| `ocean` | Regional basin: Northwest Atlantic, Northeast Atlantic, Southwest Atlantic, Northeast Pacific, Northwest Pacific, Southeast Pacific, Southwest Pacific, South Pacific, Southern Indian Ocean, or a documented multi-basin label when the official stock unit spans basins |
| `notes` | Stock-identity, boundary, split/merge, or other notes |

Use `Western and Central Pacific` for a stock managed across the WCPFC area;
retain the precise stock boundary and model-region coverage in `area`, `region`,
and `notes`.

## Identifier rules

`stock_id` should be readable, unique, stable through time, and independent of assessment year.

Examples:

``` text
dfo_cod_2j3kl
ices_cod_north_sea
afsc_pollock_ebs
```

Do not embed an assessment year in `stock_id`.

------------------------------------------------------------------------

# 2. `assessments.csv`

One row per assessment event or model run represented in the database.

## Required columns

| Column | Description |
|------------------------------------|------------------------------------|
| `assessment_id` | Stable identifier for this assessment |
| `stock_id` | Foreign key to `stocks.csv` |
| `assessment_year` | Year of the assessment/advice |
| `terminal_year` | Last year of data fitted by the model |
| `estimate_terminal_year` | Last year with a population estimate reported; may be later than `terminal_year` |
| `assessment_type` | Annual, update, benchmark, framework, etc. |
| `model_family` | SAM, Stock Synthesis, WHAM, NCAM, VPA/ADAPT, etc. |
| `model_version` | Model/package/version identifier where known |
| `is_current` | The selected publicly accessible detailed official assessment for this stock record, following `PROTOCOL.md`. It may be partial or predate newer summary-only advice. A selected assessment for an earlier stock record does not mean that historical unit is the latest stock unit; document any boundary change and fallback in notes. |
| `is_applied` | Whether this assessment was applied for advice in its assessment cycle. A current detailed benchmark can be `FALSE` if it has not yet been used for advice; more than one historical assessment can be `TRUE`. |
| `framework_year` | Benchmark/framework year defining the current model, if distinct |
| `assessment_url` | Main authoritative assessment/report URL |
| `framework_url` | Benchmark/framework/methodology URL |
| `data_url` | Official input-data URL where distinct |
| `model_url` | Native model object/run URL where distinct |
| `repository_url` | Reproducible assessment repository where available |
| `assumptions_status` | Completeness of assumptions extraction |
| `inputs_status` | Completeness of official-model input extraction |
| `outputs_status` | Completeness of official-model output extraction |
| `notes` | Assessment-level caveats or provenance notes |

## Status values

Use:

``` text
not_started
partial
complete
not_applicable
```

Use `not_applicable` sparingly.

Status fields describe completeness relative to the official assessment, not relative to a downstream analysis.

Keep translation readiness, fitting failures, convergence results, and
comparison completion in analysis diagnostics. A partial source record can
support a documented limited analysis, and a complete source record can still
require modeling approximations. Neither case changes what these status
fields mean.

------------------------------------------------------------------------

# 3. `assumptions.csv`

Long-format description of biological and statistical assumptions.

## Required columns

| Column | Description |
|------------------------------------|------------------------------------|
| `assessment_id` | Foreign key |
| `component` | Population, recruitment, N, F, M, catch, index, q, biology, etc. |
| `fleet` | Fleet to which the assumption applies |
| `survey` | Survey/index to which the assumption applies |
| `sex` | Sex to which the assumption applies |
| `region` | Region to which the assumption applies |
| `season` | Season to which the assumption applies |
| `setting` | Name of the assumption |
| `value` | Value or concise description |
| `source_reference` | Specific file, object field, table, page, or section |
| `notes` | Clarification, interpretation, or unresolved ambiguity |

Blank `fleet`, `survey`, `sex`, `region`, or `season` fields mean the assumption is not specific to that dimension.

If an important assumption cannot be resolved, use:

``` text
value = unknown
```

and explain the unresolved issue in `notes`.

------------------------------------------------------------------------

# 4. `inputs.csv`

Long-format representation of numerical inputs supplied to the official assessment.

## Required columns

| Column | Description |
|------------------------------------|------------------------------------|
| `assessment_id` | Foreign key |
| `type` | Broad input family |
| `measure` | Exact quantity represented |
| `basis` | Numbers, biomass, number proportion, biomass proportion, etc. |
| `fleet` | Fleet identity |
| `survey` | Survey/index identity |
| `sex` | Sex |
| `region` | Spatial region used by the fitted model |
| `season` | Season |
| `year` | Calendar/model year, or cohort identifier when year_basis says so; blank for time-invariant inputs |
| `year_basis` | Meaning of `year`: `calendar_year`, `model_year` (document the native annual period), or `birth_cohort` |
| `age` | Age |
| `value` | Numerical value |
| `unit` | Explicit unit |
| `sampling_time` | Timing within year as a fraction from 0 to 1 when part of the source/model definition |
| `source_type` | Provenance category |
| `source_reference` | Specific file/table/object/page |
| `transformation` | Transformation used only to recover the official-model input |
| `notes` | Additional clarification |

## Initial `type` vocabulary

``` text
catch
index
weight
catch_weight
maturity
M
covariate
biology
tag
```

Add new types only when a real assessment requires them.

## Initial `measure` vocabulary

### Catch/removals and indices

``` text
numbers_at_age
numbers_at_age_group
numbers_at_age_for_M_reconstruction
index_by_age_group
index_catch_numbers_at_age
catch_numbers
Aggregate landings_numbers and discard_numbers retain annual fish counts on a numbers scale; they are not age-specific. Use type = catch and basis = numbers, retaining fleet identity and discard-treatment details.
effort
biomass_at_age
total_numbers
landings_numbers
discard_numbers
total_biomass
catch_biomass
landings_biomass
discard_biomass
catch_cv
discard_fraction
discard_fraction_cv
discard_fraction_se
catch_se
total_egg_production
landings_lower_bound
landings_upper_bound
catch_lower_bound
catch_upper_bound
proportion_at_age
relative_biomass_index
spawning_output_index
relative_abundance_index
relative_fishing_mortality_index
recruitment_index
relative_precision_weight
relative_standard_error
log_catch_sd
abundance_index_cv
biomass_index_cv
recruitment_index_cv
```

`index_catch_numbers_at_age` preserves the numerator in a source index stored as catch numbers-at-age and effort. Use `type = index`, `basis = numbers`, and document that these numerator rows are not a second observation series. Pair them with `effort` rows (`type = covariate`, `basis = native_covariate`) when needed to reproduce a per-effort index. `effort` has no age dimension; preserve its native units and do not treat it as an independent abundance observation.

`spawning_output_index` preserves an index modeled as proportional to spawning output. Use `type = index` and `basis = index_scale`; retain the native index scale and document its units code rather than treating the value as absolute egg production.

`landings_biomass` and `discard_biomass` distinguish the aggregate components
of a fishery when both are material inputs. Use the same actual fleet identity,
`type = catch` and `basis = biomass`; do not invent separate fleets for catch
components. A matching `total_biomass` can include surviving discards and must
not automatically be interpreted as dead removals. Preserve source survival
assumptions and avoid counting component totals as independent observations.
Unavailable component observations remain blank, rather than zero; finite
non-missing observations must remain non-negative.

catch_biomass preserves a source catch or removal history reported as mass
when the source does not separate the full series into landings and discards.
Use type = catch and basis = biomass; retain source fleet distinctions and
document any adjustments.

`catch_cv` preserves a source-reported coefficient of variation for an
aggregate catch, landings, or discard observation. Use `type = catch`,
`basis = relative_scale`, `unit = ratio`, and blank `age`. Match the same year,
fleet, region, season, and `partition` as the corresponding catch observation.
This is a relative uncertainty measure, not an absolute standard error or a
likelihood weight.

`catch_numbers` preserves aggregate catch recorded as numbers of fish when the
source does not identify it specifically as landings or discards. Use
`type = catch` and `basis = numbers`; preserve fleet and source time dimensions.

An `index_by_age_group` row preserves a native index value that combines
multiple age classes and cannot be represented as a single-age observation.
Store the lower age in age and record the full source age interval, including
any plus group, in notes. This measure is kept for provenance and is not
treated as single-age observations.

`numbers_at_age_group` preserves fish numbers reported for a grouped catch age
bin. Store the lower age in `age` and the full source interval, including any
plus group, in `notes`. It is not interchangeable with single-age
`numbers_at_age` and is not passed to a single-age likelihood.

`numbers_at_age_for_M_reconstruction` preserves an age-specific total catch
series used to reconstruct a separate natural-mortality input. It is distinct
from the residual catch series fitted in the assessment. Do not treat both
series as separate catch observations in a downstream model.

For `type = index`, `measure = numbers_at_age` normally uses `basis = numbers`
and a documented count unit. When the source reports age-specific index values
but does not state its scale multiplier, use `basis = index_scale` and record
the reported quantity with the missing scale noted, for example
`number (index scale; multiplier not stated)`. Preserve the values without
guessing a conversion factor, and explain whether they are used as direct
observations or as inputs to a separate age-composition and aggregate-index
likelihood.

### Biology

``` text
growth_length_at_age
weight_at_age
catch_weight_at_age
start_weight_at_age
maturity_at_age
maturity_at_length
reproductive_potential_at_length
mature_weight_at_age
natural_mortality_at_age
fecundity_at_age
batches_per_year_at_age
reproductive_potential_at_age
proportion_female_at_age
fraction_F_before_spawning
fraction_M_before_spawning
landings_numbers_at_age
discard_numbers_at_age
landings_fraction_at_age
landings_weight_at_age
discard_weight_at_age
log_index_sd
landings_proportion
mean_body_weight
mean_body_weight_cv
ageing_error_sd
```

`landings_numbers_at_age`, `discard_numbers_at_age`, and
`landings_fraction_at_age` retain removal components used by a source model
alongside its combined catch. Landings and discard weights are distinct from
combined catch weights. `catch_weight_at_age` records a source fishery's catch
weights when they differ in meaning from stock weights; use `type = catch_weight`
and retain the source units. These values are not substituted for stock or
spawning weights.

Assessment reports may also publish fitted relative indices, catch and discard values, and mean weights. Preserve them with a specific output measure, fleet or survey, area, year, and units. Use a season where it distinguishes reported components. Do not treat predictions as observations or infer uncertainty that the source does not report. `log_index_sd` stores a supplied
standard deviation of the log survey index as a separate year record, with age
when the index is age-specific, and
the same survey identity as the corresponding observation; use `type = index`,
`basis = log_scale`, and document whether it fixes variance or supplies a relative
weight. `landings_proportion` retains a source landings-weight composition by substock
or quarter (`basis = proportion_biomass`); these records have no age. Reference
components are retained, and report rounding is not silently renormalized.

`log_catch_sd` stores the standard error of log catch when the source model
specifies that scale. Use `type = catch` and `basis = log_scale`; do not label it
as a coefficient of variation unless the source defines it that way.
When separate landings and discard observations have a log-scale error, use the same partition as the corresponding catch input.
`catch_se` preserves a source model's native catch error field when its scale
is not documented well enough to call it a log-scale standard error or a CV;
use `type = catch`, `basis = native_scale`, and a unit that identifies the
native field. Do not transform it.

`discard_fraction` records a source fraction of total catch discarded. Use
`type = catch` and `basis = proportion_biomass` or `proportion_numbers` to match
the source fleet's catch basis. `discard_fraction_cv` stores its source CV with
`basis = relative_scale` and `unit = ratio`. Keep the CV as a separate row and
document the source likelihood. When a source table explicitly leaves a CV cell
blank, preserve a blank value with a note identifying the omission; do not treat
it as zero or infer a value.
`discard_fraction_se` preserves an additive standard error for a discard
fraction reported on the proportion scale. Use `type = catch`,
`basis = native_scale`, and `unit = proportion`; pair it with the matching
`discard_fraction` row by year and source dimensions. This is an absolute
standard error, not a CV, and must be non-negative.

`mean_body_weight` stores a source mean body-weight observation, not a
stock-weight-at-age surface. Use `type = weight`, `basis = weight_per_fish`,
and the source unit. `mean_body_weight_cv` stores its source CV separately
using `basis = relative_scale` and `unit = ratio`.

`age_error_mean_age` stores the source mean observed age for each true age and
age-error definition. Use `type = biology`, `basis = native_scale`, unit `years`,
the true age in `age`, and the source definition code in `age_error`. This
preserves age-reading bias; it is not a transition probability.

`ageing_error_sd` stores a source age-error standard-deviation vector. Use
`type = biology`, `basis = age_error_sd`, the age-error definition code in
`age_error`, and the source unit (normally years). Preserve half-year age
labels when the source defines them as bin midpoints. It does not by itself
represent the full transition matrix from true age to observed age.

age_error_probability preserves a complete age-error transition matrix as
probabilities. Use type = biology, basis = proportion, unit = probability,
age as the true age, and age_error as the observed age. Probabilities for each
true age must sum to one across observed ages, within a small tolerance for
rounding in the source matrix. This is distinct from the ageing_error_sd vector.
Landings fractions should normally lie in `[0, 1]`. If an official model input
contains values slightly above one, preserve them without clipping and explain
the source-specific exception in `notes`; the validator accepts only documented
`landings_fraction_at_age` exceptions. Other input proportions must remain in
`[0, 1]`.

`relative_precision_weight` stores a native relative precision weight for an
age-specific catch or index observation, or for an aggregate index observation.
Use the corresponding input type (`catch` or `index`) and
`basis = relative_precision`. For an unaged aggregate index weight, leave age
blank and match the index by assessment, survey, region, season, and year.
Record the weight scale and any equivalent relative log-SD transformation in
the notes.

`observation_likelihood_weight` preserves a source likelihood weight when its
effect is not documented well enough to interpret as a precision or standard-
deviation multiplier. Use the corresponding input type, `basis = relative_scale`,
and retain the supplied value without transforming it. Explain the source
field and its intended source purpose. For a weight applied to a whole
composition sample or aggregate index observation, leave age blank and link it
to the matching observation rows with `observation_id`. An age-specific weight
should identify its age.

`relative_standard_error` stores the source-reported standard error divided by
the estimate for an age-specific catch or index observation. Use basis =
`relative_scale`, retain the reported value and unit, and record whether the
assessment used it as an observation weight. It is a source precision measure,
not an observation or an independently estimated standard error.

For an aggregate catch or index CV, leave `age` blank and match the same total
observation by year and its fleet or survey dimensions. Preserve catch
`partition` when it distinguishes landings and discards. This records one
aggregate precision value without repeating it over ages.

`abundance_index_cv`, `biomass_index_cv`, and `recruitment_index_cv` preserve
aggregate index CVs without inventing separate surveys. Use `type = index`,
`basis = relative_scale`, `unit = ratio`, and blank `age`. An abundance CV may
match `total_numbers` or `relative_abundance_index`; a biomass CV may match
`total_biomass` or `relative_biomass_index`; a recruitment CV must match a
`recruitment_index`. These precision rows do not create independent survey
observations and do not by themselves establish which index variance was
fitted. Preserve missing reported CVs as blank values with their source
qualification.

`relative_biomass_index` stores an aggregate relative index, such as standardized
CPUE tuned to exploitable biomass. It is not an absolute biomass observation;
use `basis = index_scale` and document the scale and model interpretation.

`recruitment_index` stores an aggregate index intended to track incoming
recruitment. Use `type = index`, `basis = index_scale`, preserve the source
units and timing, and distinguish this observation index from model-estimated
recruitment outputs.

`relative_abundance_index` stores an aggregate relative abundance index that
does not have a physical count or biomass scale. Use `basis = index_scale`,
preserve the reported or digitized index scale, and do not infer an unreported
multiplier. Record any age range represented by the aggregate index in notes;
leave `age` blank when the source reports one value for the age group as a
whole.

`relative_fishing_mortality_index` stores an aggregate index whose native
Stock Synthesis unit code identifies fishing mortality. Use `type = index`
and `basis = index_scale`, preserve the source unit code in `unit`, and do
not relabel it as an abundance or biomass index.

`maturity_at_length` preserves a supplied proportion-mature curve by length.
`reproductive_potential_at_length` preserves a source curve that combines
sex ratio and maturity, or another explicitly defined reproductive weighting;
do not relabel it as maturity alone. Both use `type = maturity` or `biology`,
`basis = proportion`, and native length-bin labels in `length_bin`.

`landings_lower_bound` and `landings_upper_bound` preserve source bounds for a
censored total-landings likelihood. Store each bound separately using the same
year, fleet, unit and basis as its landings observation.

`larval_abundance_index` represents an index tied to a spawning component. Use
`type = index`, `basis = numbers` when the source reports an abundance
scale, or `basis = native_scale` when it supplies only a special model unit
code. Leave fish age blank and record the spawning component in `region` and
survey time window in `season`. Native units and configured model timing
should be documented separately; time-window column numbers are not fish ages.

`index_sd` stores a supplied standard deviation on the native scale of a survey
index, matched to the same survey and year as the observation. Use
`type = index`, `basis = index_scale`, and the same units as the index. If the
model transforms this SD for its likelihood, document that transformation in
`notes`; retain the supplied value here.

`numbers_at_age_cv` stores a source-reported coefficient of variation for an
age-specific catch or survey number-at-age estimate. Use `type = catch` or
`index`, `basis = relative_scale`, and `unit = ratio`; match its sex, year, age,
fleet or survey, and `observation_id` to the corresponding `numbers_at_age`
row. The CV is not an absolute-scale standard error.

`regional_scaling_value` preserves source covariates used in a model regional-scaling penalty. Use `type = covariate` and `basis = native_covariate`; retain source year, area/region, season, unit, and observation ID. Preserve the supplied value as-is. It is not a direct abundance index, and no physical unit should be inferred without source documentation.

Additional measures may be added when necessary, but should remain explicit and biologically interpretable.

`mean_catch_length`, `length_at_first_capture` and `MSY_proxy_length` retain
reported length summaries used by a category-3 advice rule. Use `type = biology`,
`basis = native_covariate`, source length units and a blank age. Document the
cutoff used for mean length separately from any annually reported first-capture
length. These summaries do not reconstruct catch-at-age or raw length frequencies.

`catch_lower_bound` and `catch_upper_bound` preserve bounds used by a censored
total-catch likelihood; they are distinct from landings bounds. `start_weight_at_age`
is a source model's January 1 weight surface when it differs in meaning from the
annual stock-weight surface. `total_egg_production` stores an aggregate egg
count index; it is not a biomass index or age-specific fish-abundance index.
`fecundity_at_age` and `proportion_female_at_age` retain the biological inputs
used to calculate egg production. Use type `biology` for these biological
surfaces when no existing type represents their meaning.

`batches_per_year_at_age` preserves an age-specific annual batch count used
with batch fecundity. Use `type = biology`, `basis = native_scale`, and the
source unit (for example, `batches per year`). Keep it separate from
`fecundity_at_age`, which records eggs per batch.

`reproductive_potential_at_age` preserves age-specific spawning output that
already combines maturity and fecundity, such as egg production per mature
female fish. Keep its source unit (for example, million eggs per fish) and do
not treat it as a maturity proportion or conventional biomass.

`fixed_mortality_medium`, `fixed_mortality_low` and `fixed_mortality_high`
retain the reported scalar M settings for the three BC petrale ensemble
components (`type = M`, `basis = per_year`). Leave year and age blank: these
are distinct component parameters, not a recovered age-specific input surface
or a single averaged ensemble M. Component weights and unresolved sex/age
application belong in assumptions and notes. Observation translation does not
use these records as `natural_mortality_at_age` inputs.

## Initial `basis` vocabulary

``` text
numbers
biomass
proportion_numbers
proportion_biomass
kg_per_fish
g_per_fish
proportion
per_year
per_season
log_scale
relative_precision
relative_scale
index_scale
egg_count
```

Use `basis = egg_count` for egg-production observations and document the scale
in `unit`, such as `trillion eggs`. It must not be converted to fish numbers
without a source-supported model relationship.

`per_season` preserves a mortality hazard supplied for one source season.
State the season duration in `unit` and retain `season`. For example, SMS
sandeel uses integrated half-year M in `exp(-F_season-M_season)`; these values
must not be treated as annual M repeated across seasons. Any annual sum is a
documented downstream conversion, not a replacement of the source inputs.

For example:

``` text
type = index
measure = proportion_at_age
basis = proportion_numbers
```

is distinct from:

``` text
type = index
measure = proportion_at_age
basis = proportion_biomass
```

For `proportion_at_age` and age-specific catch components such as
`discard_numbers_at_age`, preserve blank source cells as missing values rather
than replacing them with zeros. Add a note identifying the source omission
when a reported table has blank cells.

## `source_type`

Use:

``` text
native_model
official_machine_readable
official_table
official_document
digitized
reconstructed_source_input
derived_source_output
charbonneau_seed
```

Use `official_document` for values stated in an official report's prose when
they are not presented in a numerical table. Use `official_table` for values
transcribed from tables and `digitized` for values recovered from figures.

`reconstructed_source_input` means that the actual official-model input was not directly available but was reconstructed from authoritative source quantities. Record the reconstruction in `transformation`.

Do not use `reconstructed_source_input` for values derived solely for a downstream analysis.

## Reshaping

Changing a source table from wide to long form is allowed when scientific meaning is unchanged.

Preserve the quantities and dimensions actually used by the official model.
When a source input must be reconstructed from other authoritative source
quantities, record the calculation, source references, and units in
`transformation`, with `source_type = reconstructed_source_input`. If the model
uses separate total and composition observations, retain them as separate
source inputs rather than presenting a derived quantity as a native input.
Do not place values derived only for a downstream analysis in the canonical
tables. Keep source quantities needed to reproduce a documented reconstruction,
and do not sum overlapping direct and reconstructed values. Include other
removal details when they are part of the official model or needed to document
the source inputs.

Example:

``` text
year | age1 | age2 | age3
```

may be represented as:

``` text
year | age | value
```

------------------------------------------------------------------------

# 5. `outputs.csv`

Long-format outputs from the official assessment.

## Required columns

| Column             | Description                     |
|--------------------|---------------------------------|
| `assessment_id`    | Foreign key                     |
| `type`             | Broad family: population, mortality, biomass, recruitment, catch, index, catchability, biology, probability, management, parameter, or diagnostic |
| `measure`          | Exact output represented        |
| `fleet`            | Fleet where applicable          |
| `survey`           | Survey where applicable         |
| `sex`              | Sex where applicable            |
| `region`           | Region where applicable         |
| `season`           | Season where applicable         |
| `year`             | Year; blank for time-invariant estimates, period summaries, or source-defined scenarios without a calendar year |
| `age`              | Age where applicable            |
| `age_group`        | Optional age range for grouped measures such as Fbar or Mbar |
| `scenario`         | Optional source-defined assessment or projection scenario |
| `value`            | Point estimate                  |
| `se`               | Standard error if available     |
| `lwr`              | Lower interval if available     |
| `upr`              | Upper interval if available     |
| `unit`             | Unit                            |
| `source_type`      | Provenance category             |
| `source_reference` | Specific file/table/object/page |
| `notes`            | Additional clarification        |

Use `type = management` for official management quantities such as OFL, ABC, ACL, and their buffer rules; preserve the exact quantity in `measure` and its definition in `notes`.

A blank output value may be retained when the source includes a reported row but leaves the estimate missing. Do not replace it with zero or a derived value; document the source omission in the assessment notes and source review.

Use `type = parameter` for a fitted model parameter reported on its native
scale. Put the source's exact parameter name in `measure`, leave `year` blank
unless it is explicitly year-specific, and document the parameter meaning,
units and any transformation in `notes`. Preserve signed parameter estimates
as reported; do not back-transform them unless the source specifies the
transformation.

Use `type = diagnostic` for source-reported model-fit diagnostics such as a
negative log-likelihood. Keep the total and its components distinct using
`scenario`, retain the reported scale, and note rounding or other limitations.

`scenario` distinguishes source-reported estimates under alternative assessment
or projection conditions. Leave it blank when the output is not scenario-specific.
For values summarizing a named multi-year advice period, leave `year` blank and
identify the period or horizon in `scenario` or `notes`. A source-defined
reference state with no calendar year (for example, a reported virgin state)
may also have a blank `year`; identify it in `scenario`. Record annual
components with their individual years.

## High-priority output measures

``` text
numbers_at_age
fishing_mortality_at_age
natural_mortality_at_age
SSB
recruitment
```

Use `natural_mortality_at_age` when M is estimated.

Life-cycle and run-reconstruction assessments may report stage-specific `returns`, `spawners`, and `pre_fishery_abundance`. Store these with `type = population`, preserve the source stage or sea-age label in `age_group`, and retain the source region. These measures are not conventional numbers-at-age, SSB, recruitment, or F-at-age. Preserve reported medians and interval quantiles on their native scale, and identify the interval level in `notes`.

## Secondary output measures

``` text
total_biomass
SSB_standard_deviation
biomass_standard_deviation
recruitment_standard_deviation
unfished_biomass
sum_expected_cohort_density
mature_biomass_at_age
biomass_by_age_group
total_mortality_at_age
total_removals_at_age
predicted_catch
predicted_landings_numbers
predicted_landings_weight
expected_relative_abundance_index
expected_landings_biomass
expected_landings_numbers
expected_discard_numbers
expected_dead_discard_numbers
expected_discard_biomass
expected_dead_discard_biomass
mean_landings_weight
mean_discard_weight
catch_advice
predicted_index
Fbar
Mbar
fishing_mortality_summary
fishing_intensity_Fxx_percent
fishing_intensity_1_minus_spr
spawning_output_ratio_to_unfished
spawning_potential_biomass
unfished_spawning_potential_biomass
recruitment_deviation
apical_F
F_ratio_to_Fmsy
total_numbers
total_biomass_from_age_surface
total_biomass_ratio_to_unfished
SSB_ratio_to_SSBMSY
SSB_ratio_to_MSST
F75_percent_Fmsy
F85_percent_Fmsy
F65_percent_Fmsy
F20_percent
F30_percent
F40_percent
SSBMSY
MSST
RMSY
landings_at_85_percent_Fmsy
landings_at_75_percent_Fmsy
landings_at_65_percent_Fmsy
mean_fishing_mortality
q
LRP
USR
Fmsy
Bmsy
msy
mean_recruitment
median_recruitment
recruitment_ar1_rho
natural_mortality_average_parameter
natural_mortality_parameter_sd
relative_1_minus_SPR_to_target
natural_mortality_sex_difference_parameter
maximum_sustainable_yield_rate
effort_saturation_parameter
pup_production_depletion
negative_log_likelihood
SSB_ratio_to_B0
SSB_ratio_to_terminal_biomass
unfished_spawning_biomass
spawning_biomass_at_40_percent_SB0
SSB_ratio_to_SB40
F_reference_at_SB40
F_ratio_to_FSB40
exploitation_rate
exploitation_rate_reference_at_SB40
exploitation_rate_ratio_to_SB40_reference
probability_above_40_percent_B0
probability_below_20_percent_B0
probability_above_20_percent_B0
probability_above_10_percent_B0
probability_below_FSB40
yield_at_FSB40
yield_at_85_percent_Fmsy
yield_at_75_percent_Fmsy
yield_at_65_percent_Fmsy
```

For assessments that report spawning-potential and historical-percentile
reference points, use `current_spawning_potential_ratio` for the reported
current SPR percentage; `F0.1_ratio_to_Fcurrent` and
`F30SPR_ratio_to_Fcurrent` through `F70SPR_ratio_to_Fcurrent` for F reference
ratios; and `SSB_reference_point_25th_percentile` through
`SSB_reference_point_70th_percentile` for historical SSB percentile values.
Use `SSB_ratio_to_25th_percentile_reference` through
`SSB_ratio_to_70th_percentile_reference` for year-specific status ratios and
`SSB_25th_percentile_reference_to_unfished_SSB` through
`SSB_70th_percentile_reference_to_unfished_SSB` for reference-point ratios to
unfished SSB. Preserve the source's period or biological parameter set in
`scenario`; these reference-point outputs may have a blank `year`.

`sum_expected_cohort_density` preserves a reported sum of expected densities across age cohorts when it differs from a separately reported overall expected density. Keep both source values distinct, preserve their units, and document the discrepancy.

`natural_mortality_average_parameter` and
`natural_mortality_sex_difference_parameter` preserve time-invariant estimated
M parameters when an assessment reports them directly instead of a numerical
M-at-age surface. Keep the reported parameterization and direction in the
notes; do not expand these parameters into sex-specific M values unless the
source defines the transformation.
The sex-difference parameter is signed and may be negative.
`natural_mortality_parameter_sd` preserves an uncertainty value explicitly
labelled as a parameter standard deviation by the source. Store the SD as the
output value and leave the output `se` field blank unless the source itself
reports an SE. `relative_1_minus_SPR_to_target` preserves a source-reported
ratio such as `(1-SPR)/(1-SPR50)`; it is a diagnostic, not an estimate of
instantaneous fishing mortality or F-at-age.

`unfished_biomass` preserves a source-defined B0 or other unfished biomass
quantity. Keep its source scale and units; do not treat it as unfished SSB
unless the assessment defines it that way. If the source does not state its
unit or biological basis, record that limitation rather than inferring one.

`maximum_sustainable_yield_rate` preserves a reported rate such as MSYR; record
the exact numerator and denominator in `notes`. `effort_saturation_parameter`
preserves a fitted effort-saturation parameter and its native scale. Its units
may depend on the effort definition used by the assessment.

`pup_production_depletion` preserves pup production relative to unfished pup
production. It is not an SSB estimate, even when the source uses pup
production as a proxy for spawning biomass. Retain the source's reported scale
(for example, percent or ratio).

`negative_log_likelihood` is a model-fit diagnostic, not a population
estimate. When the source reports a total and components, retain each value
separately and note that rounded components may not sum to the rounded total.
`change_in_negative_log_likelihood` records the signed difference from a named
reference fit; negative values indicate a lower objective than that reference.

`SSB_ratio_to_B0` and `SSB_ratio_to_terminal_biomass` preserve reported
spawning-biomass ratios on the scale and with the interval convention used by
the source. `probability_above_40_percent_B0` and
`probability_below_20_percent_B0` preserve reported probabilities for those
reference points; they are not deterministic status classifications.

Other source-reported probability measures should name their reference point
explicitly, such as `probability_above_20_percent_B0`,
`probability_above_10_percent_B0`, or `probability_below_FSB40`.

Use exact threshold names when an assessment reports other reference points, including probability_above_50_percent_B0, probability_above_30_percent_B0, and probability_below_10_percent_B0. These measures preserve the reported probability; they are not deterministic status classifications.

`spawning_biomass_at_40_percent_SB0` and `F_reference_at_SB40` are
time-invariant reference values and may have a blank year. `SSB_ratio_to_SB40`
and `F_ratio_to_FSB40` retain reported ratios to those references for the
specified year. Record the source's exact reference definitions and interval
conventions in the notes.

`exploitation_rate` preserves an annual source-defined removal rate, with its
numerator and denominator described in `notes`; it is not instantaneous fishing
mortality. `exploitation_rate_reference_at_SB40` stores a reported annual
proportional-removal reference associated with 40% of unfished spawning biomass
and may have a blank year. `exploitation_rate_ratio_to_SB40_reference` stores
the reported annual rate relative to that reference. Keep these distinct from
`F_reference_at_SB40` and `F_ratio_to_FSB40`.

`yield_at_FSB40` stores a source-reported yield associated with the FSB40
reference. It is a reference yield, not an observed catch series.
`yield_at_85_percent_Fmsy`, `yield_at_75_percent_Fmsy`, and
`yield_at_65_percent_Fmsy` store reference yields associated with those FMSY
fractions. They may have blank years and are not observed catch series; retain
the source definition of yield, including whether it includes discards.

`SSB_standard_deviation` preserves a source-reported standard deviation of
spawning biomass as a separate annual biomass output. Keep it on the source
scale and use the same year and dimensions as its SSB estimate. This is not an
SE or a confidence interval, so leave the `se`, `lwr`, and `upr` fields blank.


`recruitment_standard_deviation` preserves a source-reported standard deviation
of recruitment as a separate annual recruitment output. Retain its age when
specified and preserve the source scale and units. It is not an SE or a
confidence interval, so leave the `se`, `lwr`, and `upr` fields blank.

`mean_recruitment` stores a reported time-invariant mean of recruitment. Leave
year blank and retain the recruitment age when the source specifies one; it is
not an annual recruitment series.

`median_recruitment` stores a reported time-invariant median recruitment
estimate. Leave year blank and retain the recruitment age when the source
specifies one; it is not an annual recruitment series.

`recruitment_ar1_rho` stores a reported time-invariant AR(1) correlation
parameter for annual recruitment deviations. Leave year blank and retain its
reported standard error and interval when available.

`catch_advice` stores an official recommended catch or landings limit for its
advice years. Preserve whether the source specifies catches or landings and
state that basis in the notes. This is a management recommendation, not a
model-predicted catch or a population-state estimate.

apical_F preserves a source-reported annual apical fishing-mortality summary,
including a sum across fleets when that is how the source defines it. Record
the source age and fleet scope in notes. It is not an F-at-age surface or an
age-averaged Fbar.

`fishing_mortality_summary` preserves a reported annual F estimate when the
source does not state enough detail to classify it as F-at-age, apical F, or
Fbar for a known age range. Record the source's definition and any unresolved
age range in `notes` rather than inferring one.

`fishing_intensity_Fxx_percent` preserves an assessment's annual SPR-based
fishing-intensity value reported as Fxx%. Retain the source percentage and its
uncertainty interval. It is not instantaneous F or F-at-age; for the IPHC
definition, smaller percentages indicate greater fishing intensity.

`fishing_intensity_1_minus_spr` preserves annual fishing intensity defined as
1 minus the spawning potential ratio. It is a proportion, not instantaneous F
or F-at-age. Keep it distinct from Fxx% metrics and document the source's SPR
definition.

`spawning_output_ratio_to_unfished` preserves spawning output relative to its
unfished level. It may be measured in eggs or another source-defined quantity;
it is not automatically an SSB ratio. Preserve the source scale and definition.

`spawning_potential_biomass` and `unfished_spawning_potential_biomass` retain a
source biomass surface that is weighted by reproductive potential such as
fecundity or sex ratio. Preserve the source's own label and units in `notes`;
do not assume it is interchangeable with conventional SSB.

`recruitment_deviation` preserves an annual source-reported recruitment
deviation. Use `type = parameter`; keep its reported scale and uncertainty
interval, and do not back-transform a log-scale deviation unless the source
specifies that transformation.

Use measures defined by the official assessment. `derived_source_output` may
also record an explicitly requested summary calculated from that assessment's
reported outputs and documented biology. Preserve the native values, identify
the formula and age range in notes, and leave uncertainty missing when the
required covariance is unavailable. State timing differences explicitly: a
sum of January 1 mature biomass is not an April 1 SSB estimate.

`survey_biomass_index` and `length_based_fishing_pressure_proxy` preserve
reported category-3 assessment indicators. They are not absolute biomass/SSB
or instantaneous F and must not fill the corresponding population comparisons.

`survey_biomass_index_working_group` preserves an alternative reported survey
indicator from a working-group table when it conflicts with the published advice
or SAG series. Retain its original units and source, explain the discrepancy,
and do not count it as an additional independent survey observation.

`B_over_Bmsy` and `F_over_Fmsy` preserve reported dimensionless relative
states from a surplus-production assessment. Generic source columns labelled
SSB or F do not make these absolute biomass or mortality. Keep any reported
bounds on the ratio scale; do not infer absolute values or missing SEs.

`relative_harvest_rate` preserves a reported dead-catch/biomass-index indicator
in its composite units, rather than instantaneous F. `assumed_dead_catch`
stores a source-reported catch summary under an explicit discard-survival
assumption; it is not predicted catch or another observation likelihood.

`exploitable_biomass` and `exploitation_rate` preserve empirical assessment
indicators with their source definitions. They are not SSB or instantaneous
fishing mortality; describe the biomass construction and the numerator and
denominator of the rate in the source notes.

`harvest_rate` preserves a source-defined annual fraction of exploitable biomass removed by fishing. Record the source numerator, denominator, and period. It is not instantaneous F. For a multi-year summary, leave `year` blank and name the period in `scenario` or `notes.

When total abundance is derived from official numbers-at-age, sum all reported
age groups and any separately reported sexes, preserve other population
dimensions, and state the derivation in `notes`. Leave its standard error and
interval blank unless the required joint uncertainty is available.

biomass_by_age_group stores a reported aggregate biomass for a named age group, such as 3+. Put the group label in age_group and leave age blank; it is not an age-specific biomass surface.

Retain uncertainty where readily available. Parameter estimates reported by the official assessment may be stored as `type = biology`, with `measure` naming the exact parameter and `age` or `year` set only when that dimension applies.

When a summary reports growth quantities without identifying the formal model parameterization, use mean_length_parameter, length_at_age_1_parameter, or growth_rate_parameter as appropriate. Preserve reported sex and units, and quote the source definition in notes; do not infer that a mean length is asymptotic length or that a growth-rate label identifies a particular parameter.

`fleet_selectivity_at_age` retains a reported normalized fleet selectivity
proportion (`type = biology`, `unit = proportion`, with age and fleet). Leave
year blank when the curve is time-invariant. `fleet_F_coefficient` stores the
corresponding annual fleet mortality coefficient before selectivity; it is
neither total F-at-age nor Fbar. A reconstructed total F surface must be
labelled `derived_source_output` and retain the source equation and rounding
limitations in notes.

## Uncertainty and estimate definitions

The `se` column records a standard error, not a coefficient of variation (CV).
Document its scale in `notes`: normally the natural scale of `value`, or an
explicitly reported log scale. Identify delta-method natural-scale SEs as
approximations. Do not silently put a CV in `se` or infer a scale from the size
of the number. If only a CV is available, preserve it with its source meaning
in notes; any conversion to an SE must be justified and documented.

For `lwr` and `upr`, record the interval level and whether it is a confidence
or credible interval. Identify whether `value` is a mean, median, or another
reported estimate when that distinction matters. Unknown uncertainty or
interval construction remains unknown; missing values must not be interpreted
as zero uncertainty or used to invent new intervals.

Keep native definitions, such as recruitment age, SSB timing and sex convention,
Fbar age range and weighting, and terminal age groups, in the associated
assumptions and row notes. Common-definition comparisons belong in analysis
outputs rather than replacing source values here.

`type` identifies the broad output family; `measure` identifies the exact
quantity. For example, an age-specific fishing mortality row uses
`type = mortality` and `measure = fishing_mortality_at_age`.

------------------------------------------------------------------------

# Canonical-data integrity

Validation should check:

- required columns;
- unique `stock_id`;
- unique `assessment_id`;
- valid foreign keys;
- controlled `source_type` values;
- sensible year, age, and numerical fields;
- maturity proportions in `[0,1]`;
- `sampling_time` in `[0,1]` where represented numerically;
- duplicate canonical rows;
- missing fleet or survey labels where the model distinguishes them;
- unexplained multiple current assessments for the same stock.

Per-assessment summaries should include:

- input rows by `type`, `measure`, fleet, and survey;
- fleets represented;
- surveys represented;
- year and age coverage;
- outputs represented;
- assumptions represented.

Downstream-analysis-specific transformations, settings, compatibility judgments, and fitted results do not belong in the canonical database.

`spawning_weight_at_age` distinguishes supplied spawning-stock weights from
population weights when the source uses different biological surfaces. Use
`type = weight`, with `basis = kg_per_fish` or `g_per_fish` matching the
source unit; do not label biological purposes as spatial regions.

## Native length and conditional age compositions

`mat_beta1` and `mat_beta2` are signed coefficients of a documented fitted
logistic maturity curve (`type = biology` in outputs). Their SEs are on the
coefficient scale. These time-invariant estimates may have blank years; they
are outputs, not a supplied maturity-at-age input vector.

`frequency_at_length` with `basis = native_frequency` and `unit = source
frequency` preserves supplied length-frequency vectors when the native files
mix counts and proportions. Preserve the row totals and record the source's
normalization rule; these are composition samples, not removal or abundance
counts.

`frequency_at_weight` preserves native weight-frequency vectors when the source
model uses weight-bin frequencies. Use `basis = native_frequency`, preserve the
source bin code in `weight_bin`, and document its physical interval and units.
These values are not catch biomass or weight-at-age observations. Leave
`sample_size` blank when the source does not provide a separate unweighted
sample count, and explain that in `notes`.

Add `frequency_at_weight`, `tag_release_frequency_at_length`, and
`tag_recapture_count` to the controlled measure vocabulary when these source
fields are represented.

`maturity_sample_size` and `mature_sample_count` retain female biological
sampling counts used by an estimated maturity likelihood (`type = biology`,
`basis = numbers`, `unit = fish`), with `observation_id` identifying the dataset.
`composition_sample_count` likewise preserves the raw number of sampled fish
when a model supplies a transformed/reweighted count to its composition
likelihood. Keep the actual supplied likelihood count in `sample_size` on the
composition cells and describe its transformation; neither quantity is the
model's estimated effective sample size.

`conditional_frequency_at_age` preserves the native age-by-length frequency
matrix used for conditional age-at-length data. Use `type = biology`,
`basis = native_frequency`, and `unit = fish`; store age in `age`, the
conditioning length interval in `length_bin_lower` and `length_bin_upper`,
and identify each fishery/year/month stratum with `observation_id`. These raw
cell counts are not age compositions for the whole population. Record the
source's effective-sample-size rule separately; do not replace counts with
proportions or multiply them by that rule in the canonical database.

`tag_release_frequency_at_length` and `tag_recapture_count` preserve native
tagging observations. Use `type = tag`; store the release group, program, and
release cohort in `observation_id`. Release-length frequencies use
`basis = native_frequency` and `length_bin`; recaptures use `basis = numbers`,
the recapture year/season, and the recapture fleet. Keep any source-specific
release scale and release-length meaning explicit in `notes`.

`proportion_at_length`, `proportion_at_weight`, and
`conditional_proportion_at_age` retain the composition representation consumed
by an assessment. Use `basis = proportion_numbers` and `unit = proportion` for
number compositions. Do not replace these with an unconditional age
distribution. For `proportion_at_weight`, use `type = catch_weight` and store
the native weight-bin label in `weight_bin`; describe its unit and whether it
represents individual fish weight, a mean packed weight, or another source
quantity in `notes`.

Optional input columns preserve their dimensions:

- `observation_id`: stable source record identifier, shared by its composition cells.
- `length_bin`: native length-bin label for a length composition, in cm.
- `weight_bin`: native weight-composition bin label; state its unit in `notes`.
- `length_bin_lower`, `length_bin_upper`: native conditioning-bin codes/bounds for
  conditional age composition; specify the coding method and units in notes.
- `sample_size`: supplied input sample size, distinct from an estimated effective size. Leave it blank when the source does not supply a value and document that omission in `notes`; do not infer a default.
- `age_error`: native ageing-error definition code; interpretation belongs in assumptions.
- `partition`: native retained/discard/combined observation code, documented in notes.

These columns are blank for inputs to which they do not apply. Preserve the
source month in notes and record survey timing separately as a fraction of year.

## Covariates

``` text
environmental_covariate
condition_index_for_mortality
capelin_biomass_index
```

Use `type = covariate` and `basis = native_covariate` for supplied covariates
used by the model. `environmental_covariate` records environmental series;
`condition_index_for_mortality` records a fish-condition index used to inform a
time-varying natural-mortality process. Retain the source scale and timing.
Signed finite values are permitted. Do not treat either covariate as an
abundance index or, for the condition index, as a natural-mortality estimate.
`capelin_biomass_index` preserves a source Capelin biomass index used to form
a prey-to-cod biomass ratio for a mortality model. Record its spatial coverage
and units; it is not a cod abundance index or a direct M estimate.

`type = biology` with `fraction_F_before_spawning` or
`fraction_M_before_spawning` records supplied year-age mortality fractions used
in spawning biomass, with `basis = proportion`. Preserve fleet dimensions for F
where present. These are biological inputs, separate from survey sampling timing.

Time-invariant `q_power` outputs may have a blank year, like `q`. Record the
power separately from the catchability coefficient and document the observation
equation; a coefficient in a power relationship is not a simple catch fraction.
Natural-scale SEs obtained by the delta method must be identified as such.

## Native age frequencies and fecundity weights

`frequency_at_age` uses `basis = native_frequency` to retain source age
compositions supplied as counts or percentages rather than unit-sum proportions.
Keep the original units (for example `percent`), row totals, sample sizes and
age-error codes, and describe the source normalization. Normalization for a
secondary analysis belongs outside the canonical tables.

`maturity_fecundity_at_age` uses `type = biology`, `basis = kg_per_fish` and
the original weight units to retain supplied maturity-times-fecundity weights.
It is not a maturity proportion. Record the source sex fraction, minimum mature
age and SSB equation separately. Deriving a maturity proportion for another model by
dividing this product by population weight is an analysis transformation.

`mature_weight_at_age` records a source product of maturity proportion and body
weight when that is the quantity supplied. It is not a standalone maturity
proportion or a maturity-times-fecundity series; retain the source units and
document any fecundity assumption separately.

`fishing_mortality_intensity` is an annual mortality output parameter before
age selectivity. It is neither F-at-age nor an age-averaged Fbar; do not substitute
it for either comparison. `exploitation_fraction_at_age` retains the source
removal fraction and its original unit (such as percent), which likewise is
not an instantaneous F. Record the source definitions and estimate conventions.
