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
already represented in the canonical database. Inventory rows alone do not create
canonical assessment events or values. `charbonneau_id` may be blank when no
verified catalogue match exists.

The current controlled basin vocabulary is validated by the database validator.
When a verified new stock requires another basin, add and document a specific
label and update validation alongside that import. Preserve the stock's precise
extent in area and region, including genuinely wide-ranging units; do not force
Southern Hemisphere stocks into the current Northern Hemisphere labels.

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
| `ocean` | Regional basin: Northwest Atlantic, Northeast Atlantic, Northeast Pacific, Northwest Pacific, or Southwest Pacific |
| `notes` | Stock-identity, boundary, split/merge, or other notes |

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
effort
biomass_at_age
total_numbers
total_biomass
landings_biomass
discard_biomass
discard_fraction
discard_fraction_cv
catch_se
total_egg_production
landings_lower_bound
landings_upper_bound
catch_lower_bound
catch_upper_bound
proportion_at_age
relative_biomass_index
relative_abundance_index
relative_precision_weight
relative_standard_error
log_catch_sd
abundance_index_cv
biomass_index_cv
```

`index_catch_numbers_at_age` preserves the numerator in a source index stored as catch numbers-at-age and effort. Use `type = index`, `basis = numbers`, and document that these numerator rows are not a second observation series. Pair them with `effort` rows (`type = covariate`, `basis = native_covariate`) when needed to reproduce a per-effort index. `effort` has no age dimension; preserve its native units and do not treat it as an independent abundance observation.

`landings_biomass` and `discard_biomass` distinguish the aggregate components
of a fishery when both are material inputs. Use the same actual fleet identity,
`type = catch` and `basis = biomass`; do not invent separate fleets for catch
components. A matching `total_biomass` can include surviving discards and must
not automatically be interpreted as dead removals. Preserve source survival
assumptions and avoid counting component totals as independent observations.
Unavailable component observations remain blank, rather than zero; finite
non-missing observations must remain non-negative.

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
weight_at_age
catch_weight_at_age
start_weight_at_age
maturity_at_age
mature_weight_at_age
natural_mortality_at_age
fecundity_at_age
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
spawning weights. `log_index_sd` stores a supplied
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
`catch_se` preserves a source model's native catch error field when its scale
is not documented well enough to call it a log-scale standard error or a CV;
use `type = catch`, `basis = native_scale`, and a unit that identifies the
native field. Do not transform it.

`discard_fraction` records a source fraction of total catch discarded. Use
`type = catch` and `basis = proportion_biomass` or `proportion_numbers` to match
the source fleet's catch basis. `discard_fraction_cv` stores its source CV with
`basis = relative_scale` and `unit = ratio`. Keep the CV as a separate row and
document the source likelihood.

`mean_body_weight` stores a source mean body-weight observation, not a
stock-weight-at-age surface. Use `type = weight`, `basis = weight_per_fish`,
and the source unit. `mean_body_weight_cv` stores its source CV separately
using `basis = relative_scale` and `unit = ratio`.

`ageing_error_sd` stores a source age-error standard-deviation vector. Use
`type = biology`, `basis = age_error_sd`, the age-error definition code in
`age_error`, and the source unit (normally years). Preserve half-year age
labels when the source defines them as bin midpoints. It does not by itself
represent the full transition matrix from true age to observed age.
Landings fractions should normally lie in `[0, 1]`. If an official model input
contains values slightly above one, preserve them without clipping and explain
the source-specific exception in `notes`; the validator accepts only documented
`landings_fraction_at_age` exceptions. Other input proportions must remain in
`[0, 1]`.

`relative_precision_weight` stores a native relative precision weight for an
age-specific catch or index observation. Use the corresponding input type
(`catch` or `index`) and basis = `relative_precision`. Record the weight scale
and any equivalent relative log-SD transformation in the notes.

`observation_likelihood_weight` preserves a source likelihood weight when its
effect is not documented well enough to interpret as a precision or standard-
deviation multiplier. Use the corresponding input type, `basis = relative_scale`,
and retain the supplied value without transforming it. Explain the source
field and its intended source purpose.

`relative_standard_error` stores the source-reported standard error divided by
the estimate for an age-specific catch or index observation. Use basis =
`relative_scale`, retain the reported value and unit, and record whether the
assessment used it as an observation weight. It is a source precision measure,
not an observation or an independently estimated standard error.

For an aggregate catch or index CV, leave `age` blank and match the same total
observation by year and its fleet or survey dimensions. Preserve catch
`partition` when it distinguishes landings and discards. This records one
aggregate precision value without repeating it over ages.

When the source reports both aggregate number and biomass indices for the
same survey and year, `abundance_index_cv` and `biomass_index_cv` distinguish
their CVs without inventing separate surveys. Use `type = index`,
`basis = relative_scale`, `unit = ratio`, and blank `age`. Each must match its
corresponding `total_numbers` or `total_biomass` record. The two representations
are not independent survey observations, and these reported CVs do not by
themselves establish which index or variance was fitted. Preserve missing
reported CVs as blank values with their source qualification.

`relative_biomass_index` stores an aggregate relative index, such as standardized
CPUE tuned to exploitable biomass. It is not an absolute biomass observation;
use `basis = index_scale` and document the scale and model interpretation.

`relative_abundance_index` stores an aggregate relative abundance index that
does not have a physical count or biomass scale. Use `basis = index_scale`,
preserve the reported or digitized index scale, and do not infer an unreported
multiplier. Record any age range represented by the aggregate index in notes;
leave `age` blank when the source reports one value for the age group as a
whole.

`landings_lower_bound` and `landings_upper_bound` preserve source bounds for a
censored total-landings likelihood. Store each bound separately using the same
year, fleet, unit and basis as its landings observation.

`larval_abundance_index` represents an index tied to a spawning component. Use
`type = index`, `basis = numbers`, blank fish age, and record the spawning
component in `region` and survey time window in `season`. Native units and
configured model timing should be documented separately; time-window column
numbers are not fish ages.

`index_sd` stores a supplied standard deviation on the native scale of a survey
index, matched to the same survey and year as the observation. Use
`type = index`, `basis = index_scale`, and the same units as the index. If the
model transforms this SD for its likelihood, document that transformation in
`notes`; retain the supplied value here.

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
| `type`             | Broad family: population, mortality, biomass, recruitment, catch, index, catchability, or biology |
| `measure`          | Exact output represented        |
| `fleet`            | Fleet where applicable          |
| `survey`           | Survey where applicable         |
| `sex`              | Sex where applicable            |
| `region`           | Region where applicable         |
| `season`           | Season where applicable         |
| `year`             | Year; blank for time-invariant estimates such as reported catchability parameters and reference points |
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

`scenario` distinguishes source-reported estimates under alternative assessment
or projection conditions. Leave it blank when the output is not scenario-specific.

## High-priority output measures

``` text
numbers_at_age
fishing_mortality_at_age
natural_mortality_at_age
SSB
recruitment
```

Use `natural_mortality_at_age` when M is estimated.

## Secondary output measures

``` text
total_biomass
mature_biomass_at_age
biomass_by_age_group
total_mortality_at_age
predicted_catch
catch_advice
predicted_index
Fbar
Mbar
fishing_mortality_summary
apical_F
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
natural_mortality_sex_difference_parameter
SSB_ratio_to_B0
SSB_ratio_to_terminal_biomass
probability_above_40_percent_B0
probability_below_20_percent_B0
```

`natural_mortality_average_parameter` and
`natural_mortality_sex_difference_parameter` preserve time-invariant estimated
M parameters when an assessment reports them directly instead of a numerical
M-at-age surface. Keep the reported parameterization and direction in the
notes; do not expand these parameters into sex-specific M values unless the
source defines the transformation.
The sex-difference parameter is signed and may be negative.

`SSB_ratio_to_B0` and `SSB_ratio_to_terminal_biomass` preserve reported
spawning-biomass ratios on the scale and with the interval convention used by
the source. `probability_above_40_percent_B0` and
`probability_below_20_percent_B0` preserve reported probabilities for those
reference points; they are not deterministic status classifications.

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

When total abundance is derived from official numbers-at-age, sum all reported
age groups and any separately reported sexes, preserve other population
dimensions, and state the derivation in `notes`. Leave its standard error and
interval blank unless the required joint uncertainty is available.

biomass_by_age_group stores a reported aggregate biomass for a named age group, such as 3+. Put the group label in age_group and leave age blank; it is not an age-specific biomass surface.

Retain uncertainty where readily available. Parameter estimates reported by the official assessment may be stored as `type = biology`, with `measure` naming the exact parameter and `age` or `year` set only when that dimension applies.

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
counts. `maturity_sample_size` and `mature_sample_count` retain female biological
sampling counts used by an estimated maturity likelihood (`type = biology`,
`basis = numbers`, `unit = fish`), with `observation_id` identifying the dataset.
`composition_sample_count` likewise preserves the raw number of sampled fish
when a model supplies a transformed/reweighted count to its composition
likelihood. Keep the actual supplied likelihood count in `sample_size` on the
composition cells and describe its transformation; neither quantity is the
model's estimated effective sample size.

`proportion_at_length` and `conditional_proportion_at_age` retain the composition
representation consumed by an assessment. Use `basis = proportion_numbers` and
`unit = proportion`. Do not replace these with an unconditional age distribution.

Optional input columns preserve their dimensions:

- `observation_id`: stable source record identifier, shared by its composition cells.
- `length_bin`: native length-bin label for a length composition, in cm.
- `length_bin_lower`, `length_bin_upper`: native conditioning-bin codes/bounds for
  conditional age composition; specify the coding method and units in notes.
- `sample_size`: supplied input sample size, distinct from an estimated effective size.
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

