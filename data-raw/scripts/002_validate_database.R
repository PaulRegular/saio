root <- file.path("database")
for (name in c("stocks.csv", "assessments.csv", "assumptions.csv")) {
  path <- file.path(root, name)
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  if (any(bytes == as.raw(0))) {
    stop(name, " contains an embedded NUL byte.", call. = FALSE)
  }
}

read_table <- function(name) {
  read.csv(file.path(root, name),
    stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE
  )
}

stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
assumptions <- read_table("assumptions.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
if (!"age_group" %in% names(outputs)) outputs$age_group <- ""

schemas <- list(
  stocks = c(
    "stock_id", "charbonneau_id", "authority", "authority_stock_id",
    "scientific_name", "common_name", "area", "region", "ocean", "notes"
  ),
  assessments = c(
    "assessment_id", "stock_id", "assessment_year", "terminal_year",
    "estimate_terminal_year", "assessment_type", "model_family",
    "model_version", "is_current", "is_applied", "framework_year",
    "assessment_url", "framework_url", "data_url", "model_url",
    "repository_url", "assumptions_status", "inputs_status",
    "outputs_status", "notes"
  ),
  assumptions = c(
    "assessment_id", "component", "fleet", "survey", "sex", "region",
    "season", "setting", "value", "source_reference", "notes"
  ),
  inputs = c(
    "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
    "region", "season", "year", "year_basis", "age", "value", "unit",
    "sampling_time", "source_type", "source_reference", "transformation", "notes",
    "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
    "sample_size", "age_error", "partition", "weight_bin"
  ),
  outputs = c(
    "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
    "season", "year", "age", "age_group", "scenario", "value", "se", "lwr", "upr", "unit",
    "source_type", "source_reference", "notes"
  )
)
tables <- list(
  stocks = stocks, assessments = assessments, assumptions = assumptions,
  inputs = inputs, outputs = outputs
)
for (name in names(tables)) {
  missing <- setdiff(schemas[[name]], names(tables[[name]]))
  if (length(missing)) {
    stop(name, ".csv is missing columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

unique_id <- function(x, column, table) {
  id <- x[[column]]
  if (anyNA(id) || any(!nzchar(id)) || anyDuplicated(id)) {
    stop(table, "$", column, " must contain unique, non-empty values.", call. = FALSE)
  }
}
unique_id(stocks, "stock_id", "stocks")
unique_id(assessments, "assessment_id", "assessments")
ocean_values <- c(
  "Northwest Atlantic", "Northeast Atlantic", "Southwest Atlantic",
  "Northeast Pacific", "Northwest Pacific", "Southeast Pacific", "Southwest Pacific",
  "South Pacific", "Western and Central Pacific", "Southern Indian Ocean", "Southern Ocean",
  "Southwest Pacific and Southern Ocean"
)
if (anyNA(stocks$ocean) || any(!stocks$ocean %in% ocean_values)) {
  cli::cli_abort("stocks$ocean must use a documented regional basin label.")
}
if (any(!assessments$stock_id %in% stocks$stock_id)) {
  stop("assessments.csv has an unknown stock_id.", call. = FALSE)
}
assessment_ids <- assessments$assessment_id
for (name in c("assumptions", "inputs", "outputs")) {
  x <- tables[[name]]
  if (anyNA(x$assessment_id) || any(!x$assessment_id %in% assessment_ids)) {
    stop(name, ".csv has an unknown or empty assessment_id.", call. = FALSE)
  }
}

status_values <- c("not_started", "partial", "complete", "not_applicable")
for (field in c("assumptions_status", "inputs_status", "outputs_status")) {
  if (anyNA(assessments[[field]]) || any(!assessments[[field]] %in% status_values)) {
    stop("assessments$", field, " must use the documented status values.", call. = FALSE)
  }
}
logical_value <- function(x) tolower(as.character(x)) %in% c("true", "1")
for (field in c("is_current", "is_applied")) {
  raw <- tolower(as.character(assessments[[field]]))
  if (any(!raw %in% c("true", "false", "1", "0"))) {
    stop("assessments$", field, " must be TRUE/FALSE or 1/0.", call. = FALSE)
  }
}
current <- logical_value(assessments$is_current)
for (i in seq_len(nrow(assessments))) {
  row <- assessments[i, ]
  for (table_name in c("assumptions", "inputs", "outputs")) {
    status <- row[[paste0(
      if (table_name == "assumptions") "assumptions" else table_name,
      "_status"
    )]]
    has_rows <- any(tables[[table_name]]$assessment_id == row$assessment_id)
    if (status == "complete" && !has_rows) {
      stop(row$assessment_id, " is marked complete for ", table_name,
        " but has no rows.",
        call. = FALSE
      )
    }
    if (status == "not_applicable" && has_rows) {
      stop(row$assessment_id, " is marked not_applicable for ", table_name,
        " but has rows.",
        call. = FALSE
      )
    }
  }
}

whole_year <- function(x, field, table, allow_blank = FALSE) {
  raw <- x[[field]]
  value <- suppressWarnings(as.numeric(raw))
  required <- if (allow_blank) !is.na(raw) & nzchar(as.character(raw)) else rep(TRUE, length(raw))
  if (any(required & (is.na(value) | !is.finite(value) | value != as.integer(value)))) {
    stop(table, "$", field, " must contain whole years or blanks.", call. = FALSE)
  }
  value
}
assessment_year <- whole_year(assessments, "assessment_year", "assessments")
terminal_year <- whole_year(assessments, "terminal_year", "assessments")
estimate_year <- whole_year(assessments, "estimate_terminal_year", "assessments",
  allow_blank = TRUE
)
invisible(whole_year(assessments, "framework_year", "assessments", allow_blank = TRUE))
if (any(terminal_year > assessment_year) || any(estimate_year < terminal_year, na.rm = TRUE)) {
  stop("Assessment years, data terminals, and estimate terminals are inconsistent.",
    call. = FALSE
  )
}
current_stock <- assessments$stock_id[current]
if (anyDuplicated(current_stock)) {
  repeated <- unique(current_stock[duplicated(current_stock)])
  for (stock in repeated) {
    rows <- assessments[assessments$stock_id == stock & current, , drop = FALSE]
    if (anyNA(rows$notes) || any(!nzchar(rows$notes))) {
      stop("Multiple current assessments for ", stock,
        " need an explanation in notes.",
        call. = FALSE
      )
    }
  }
}

duplicates <- list(
  assumptions = c(
    "assessment_id", "component", "fleet", "survey", "sex", "region",
    "season", "setting"
  ),
  inputs = c(
    "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
    "region", "season", "year", "year_basis", "age"
  ),
  outputs = c(
    "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
    "season", "year", "age", "age_group", "scenario"
  )
)
composition_dimensions <- c(
  "observation_id", "length_bin", "length_bin_lower",
  "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin"
)
duplicates$inputs <- c(
  duplicates$inputs,
  intersect(composition_dimensions, names(inputs))
)
for (name in names(duplicates)) {
  x <- tables[[name]]
  key <- do.call(paste, c(lapply(x[duplicates[[name]]], function(z) {
    z[is.na(z)] <- ""
    as.character(z)
  }), sep = "\r"))
  if (anyDuplicated(key)) stop(name, ".csv has duplicate canonical rows.", call. = FALSE)
}

allowed_sources <- c(
  "native_model", "official_machine_readable", "official_table",
  "official_document",
  "digitized", "reconstructed_source_input", "derived_source_output",
  "charbonneau_seed"
)
allowed_input_types <- c("catch", "index", "weight", "catch_weight", "maturity", "M", "covariate", "biology", "tag")
allowed_output_types <- c(
  "population", "mortality", "biomass", "recruitment", "catch",
  "index", "catchability", "biology", "probability", "management", "parameter",
  "diagnostic"
)
allowed_input_measures <- c(
  "frequency_at_length", "frequency_at_weight", "frequency_at_age", "maturity_fecundity_at_age", "maturity_sample_size", "mature_sample_count", "composition_sample_count",
  "numbers_at_age", "numbers_at_age_cv", "numbers_at_age_group", "numbers_at_age_for_M_reconstruction", "index_by_age_group", "catch_numbers",
  "index_catch_numbers_at_age", "effort",
  "biomass_at_age", "total_numbers", "landings_numbers", "discard_numbers",
  "total_biomass", "catch_biomass", "landings_biomass", "discard_biomass", "catch_cv", "discard_fraction", "discard_fraction_cv", "discard_fraction_se", "catch_se", "total_egg_production", "landings_lower_bound", "landings_upper_bound",
  "catch_lower_bound", "catch_upper_bound", "proportion_at_age", "proportion_at_length",
  "conditional_proportion_at_age", "conditional_frequency_at_age", "proportion_at_weight", "weight_at_age", "catch_weight_at_age", "spawning_weight_at_age", "start_weight_at_age", "growth_length_at_age",
  "maturity_at_age", "age_error_probability", "maturity_at_length", "reproductive_potential_at_length", "mature_weight_at_age", "natural_mortality_at_age", "condition_index_for_mortality",
  "fecundity_at_age", "batches_per_year_at_age", "reproductive_potential_at_age", "proportion_female_at_age",
  "mean_catch_length", "length_at_first_capture", "MSY_proxy_length",
  "fixed_mortality_medium", "fixed_mortality_low", "fixed_mortality_high",
  "relative_biomass_index", "relative_abundance_index", "relative_fishing_mortality_index", "recruitment_index", "spawning_output_index", "abundance_index_cv", "biomass_index_cv", "recruitment_index_cv",
  "landings_proportion", "landings_numbers_at_age", "discard_numbers_at_age", "landings_fraction_at_age",
  "landings_weight_at_age", "discard_weight_at_age", "log_index_sd", "log_catch_sd", "index_sd", "relative_precision_weight", "observation_likelihood_weight", "relative_standard_error", "mean_body_weight", "mean_body_weight_cv", "ageing_error_sd", "age_error_mean_age", "larval_abundance_index", "environmental_covariate", "fraction_F_before_spawning",
  "fraction_M_before_spawning", "capelin_biomass_index",
  "tag_release_frequency_at_length", "tag_recapture_count", "regional_scaling_value"
)
allowed_bases <- c(
  "native_frequency",
  "numbers", "biomass", "proportion_numbers", "proportion_biomass",
  "kg_per_fish", "g_per_fish", "weight_per_fish", "age_error_sd", "native_scale", "proportion", "per_year", "per_season", "log_scale", "native_covariate",
  "relative_precision", "relative_scale", "index_scale", "egg_count", "tonnes_per_fish"
)
for (name in c("inputs", "outputs")) {
  x <- tables[[name]]
  if (anyNA(x$source_type) || any(!x$source_type %in% allowed_sources)) {
    stop(name, "$source_type must use the controlled source labels.", call. = FALSE)
  }
  if (anyNA(x$source_reference) || any(!nzchar(x$source_reference))) {
    stop(name, "$source_reference must identify the source location.", call. = FALSE)
  }
  allowed_type <- if (name == "inputs") allowed_input_types else allowed_output_types
  if (anyNA(x$type) || any(!x$type %in% allowed_type)) {
    stop(name, "$type must use the documented broad categories.", call. = FALSE)
  }
  if (anyNA(x$measure) || any(!nzchar(x$measure))) {
    stop(name, "$measure must identify the exact quantity.", call. = FALSE)
  }
  if (name == "inputs") {
    if (any(!x$measure %in% allowed_input_measures) || anyNA(x$basis) ||
      any(!x$basis %in% allowed_bases)) {
      stop("inputs.csv has an undocumented measure or basis.", call. = FALSE)
    }
    weight_composition <- x$measure == "proportion_at_weight"
    if (any(weight_composition & (x$type != "catch_weight" | x$basis != "proportion_numbers"))) {
      cli::cli_abort("Weight compositions must be catch_weight proportions by number.")
    }
    growth_length <- x$measure == "growth_length_at_age"
    regional_scaling <- x$measure == "regional_scaling_value"
    if (any(regional_scaling & (x$type != "covariate" | x$basis != "native_covariate" |
      is.na(x$year) | is.na(x$region) | !nzchar(x$region) |
      is.na(x$season) | !nzchar(x$season) |
      !is.na(suppressWarnings(as.numeric(x$age))) |
      is.na(x$observation_id) | !nzchar(x$observation_id)))) {
      cli::cli_abort("regional_scaling_value must preserve a year-, region-, and season-specific native covariate with observation identity.")
    }
    if (any(growth_length & (x$type != "biology" | x$basis != "native_covariate"))) {
      cli::cli_abort("growth_length_at_age inputs must preserve native biological lengths.")
    }
    catch_biomass <- x$measure == "catch_biomass"
    if (any(catch_biomass & (x$type != "catch" | x$basis != "biomass"))) {
      stop("catch_biomass must preserve catch mass on the biomass scale.", call. = FALSE)
    }
    catch_numbers <- x$measure == "catch_numbers"
    if (any(catch_numbers & (x$type != "catch" | x$basis != "numbers"))) {
      stop("catch_numbers must preserve aggregate catches on the numbers scale.", call. = FALSE)
    }
    discard_fraction_se <- x$measure == "discard_fraction_se"
    if (any(discard_fraction_se & (x$type != "catch" |
      x$basis != "native_scale" | x$unit != "proportion" |
      !is.na(suppressWarnings(as.numeric(x$age)))))) {
      cli::cli_abort("discard_fraction_se must preserve a non-negative additive standard error on the proportion scale, with no age dimension.")
    }
    if (any(discard_fraction_se)) {
      dimensions <- c("assessment_id", "fleet", "survey", "sex", "region",
        "season", "year", "year_basis", "partition")
      key <- function(z) do.call(paste, c(lapply(z[dimensions], function(v) {
        v[is.na(v)] <- ""
        as.character(v)
      }), sep = "\r"))
      discard_fraction <- x[x$measure == "discard_fraction", , drop = FALSE]
      if (any(!key(x[discard_fraction_se, , drop = FALSE]) %in%
        key(discard_fraction))) {
        cli::cli_abort("Each discard_fraction_se must match a source discard fraction with the same observation dimensions.")
      }
    }
    conditional_age_frequency <- x$measure == "conditional_frequency_at_age"
    if (any(conditional_age_frequency & (x$type != "biology" | x$basis != "native_frequency" |
      is.na(suppressWarnings(as.numeric(x$age))) |
      is.na(suppressWarnings(as.numeric(x$length_bin_lower))) |
      is.na(suppressWarnings(as.numeric(x$length_bin_upper))) |
      is.na(x$observation_id) | !nzchar(x$observation_id)))) {
      cli::cli_abort("conditional_frequency_at_age must retain age, conditioning length bounds, and observation identity as native frequencies.")
    }
    weight_frequency <- x$measure == "frequency_at_weight"
    if (any(weight_frequency & (!x$type %in% c("catch", "index") |
      x$basis != "native_frequency" |
      is.na(suppressWarnings(as.numeric(x$weight_bin))) |
      is.na(x$observation_id) | !nzchar(x$observation_id)))) {
      cli::cli_abort("frequency_at_weight must preserve native weight-bin frequencies and observation identity.")
    }
    tag_release <- x$measure == "tag_release_frequency_at_length"
    if (any(tag_release & (x$type != "tag" | x$basis != "native_frequency" |
      is.na(suppressWarnings(as.numeric(x$length_bin))) |
      is.na(x$observation_id) | !nzchar(x$observation_id)))) {
      cli::cli_abort("tag_release_frequency_at_length must retain native length bins and observation identity.")
    }
    tag_recapture <- x$measure == "tag_recapture_count"
    if (any(tag_recapture & (x$type != "tag" | x$basis != "numbers" |
      is.na(x$observation_id) | !nzchar(x$observation_id)))) {
      cli::cli_abort("tag_recapture_count must preserve counts and release-group identity.")
    }
    age_number_cv <- x$measure == "numbers_at_age_cv"
    if (any(age_number_cv)) {
      if (any(!x$type[age_number_cv] %in% c("catch", "index") |
        x$basis[age_number_cv] != "relative_scale" |
        x$unit[age_number_cv] != "ratio" |
        is.na(suppressWarnings(as.numeric(x$age[age_number_cv]))) |
        suppressWarnings(as.numeric(x$value[age_number_cv])) < 0)) {
        cli::cli_abort("numbers_at_age_cv must be a non-negative, age-specific relative-scale ratio for catch or index numbers-at-age.")
      }
      pair_fields <- c("assessment_id", "type", "fleet", "survey", "sex", "region", "season",
        "year", "year_basis", "age", "observation_id")
      row_key <- function(z) do.call(paste, c(lapply(z[pair_fields], function(v) {
        v[is.na(v)] <- ""
        as.character(v)
      }), sep = "\r"))
      age_numbers <- x[x$measure == "numbers_at_age", , drop = FALSE]
      if (any(!row_key(x[age_number_cv, , drop = FALSE]) %in% row_key(age_numbers))) {
        cli::cli_abort("Each numbers_at_age_cv row must match a numbers_at_age value with the same source dimensions.")
      }
    }
    catch_cv <- x$measure == "catch_cv"
    if (any(catch_cv)) {
      cv_age <- suppressWarnings(as.numeric(x$age[catch_cv]))
      cv_value <- suppressWarnings(as.numeric(x$value[catch_cv]))
      if (any(x$type[catch_cv] != "catch" |
        x$basis[catch_cv] != "relative_scale" |
        x$unit[catch_cv] != "ratio" | !is.na(cv_age) |
        is.na(cv_value) | cv_value < 0)) {
        cli::cli_abort("catch_cv must be a non-negative aggregate catch CV on the relative scale, with no age.")
      }
      columns <- c("assessment_id", "fleet", "region", "season", "year",
        "year_basis", "partition")
      key <- function(z) do.call(paste, c(lapply(z[columns], function(v) {
        v[is.na(v)] <- ""
        as.character(v)
      }), sep = "\r"))
      catch_observations <- x[x$type == "catch" & x$measure %in% c(
        "catch_biomass", "landings_biomass", "discard_biomass", "catch_numbers",
        "landings_numbers", "discard_numbers"), , drop = FALSE]
      if (any(!key(x[catch_cv, , drop = FALSE]) %in% key(catch_observations))) {
        cli::cli_abort("Each catch_cv row must match a catch observation with the same year, fleet, and partition.")
      }
    }

    has_year <- !is.na(x$year) & nzchar(as.character(x$year))
    has_year_basis <- !is.na(x$year_basis) & nzchar(as.character(x$year_basis))
    if (any(has_year & !x$year_basis %in% c("calendar_year", "model_year", "birth_cohort")) ||
      any(!has_year & has_year_basis)) {
      stop("inputs$year_basis must identify a supplied year dimension.", call. = FALSE)
    }
  }
  year <- whole_year(x, "year", name, allow_blank = name %in% c("inputs", "outputs"))
  blank_year <- is.na(x$year) | !nzchar(as.character(x$year))
  has_scenario <- !is.na(x$scenario) & nzchar(as.character(x$scenario))
  if (name == "outputs" && any(blank_year & !has_scenario & x$type != "parameter" & !x$measure %in% c(
    "q", "q_power", "process_sd", "observation_sd", "mat_beta1", "mat_beta2",
    "maturity_at_age",
    "log_q_power", "growth_length_at_age", "weight_at_age", "reproductive_potential_at_age",
    "growth_rate", "growth_sd_length_at_age",
    "Fmsy", "F85_percent_Fmsy", "F75_percent_Fmsy", "F65_percent_Fmsy", "F20_percent", "F30_percent", "F40_percent", "Bmsy", "SSBMSY", "MSST", "msy", "RMSY", "SSB_ratio_to_SSBMSY", "SSB_ratio_to_MSST", "landings_at_85_percent_Fmsy", "landings_at_75_percent_Fmsy", "landings_at_65_percent_Fmsy", "landings_at_75_percent_msy", "mean_current_landings", "mean_fishing_mortality", "F_ratio_to_Fmsy", "mean_recruitment", "median_recruitment",
    "recruitment_ar1_rho",
    "natural_mortality_average_parameter", "natural_mortality_sex_difference_parameter",
    "unfished_biomass", "unfished_spawning_biomass",
    "recommended_biological_catch", "retained_catch", "estimated_discards", "tier_2_discount_factor",
    "long_term_recommended_biological_catch", "long_term_estimated_discards", "long_term_yield",
    "mean_length_parameter", "length_at_age_1_parameter", "growth_rate_parameter",
    "fleet_selectivity_at_age", "natural_mortality_at_age", "LRP", "USR",
    "spawning_biomass_at_40_percent_SB0", "target_spawning_biomass", "F_reference_at_SB40",
    "exploitation_rate_reference_at_SB40",
    "maximum_exploitation_rate", "harvest_rate", "biomass_reference_point_0.4_BMSY",
    "biomass_reference_point_0.8_BMSY", "Bmsy_to_B0",
    "exploitation_rate_at_msy", "target_fishing_mortality", "yield_at_FSB40",
    "yield_at_85_percent_Fmsy", "yield_at_75_percent_Fmsy",
    "yield_at_65_percent_Fmsy",
    "current_spawning_potential_ratio", "F0.1_ratio_to_Fcurrent",
    "F30SPR_ratio_to_Fcurrent", "F40SPR_ratio_to_Fcurrent",
    "F50SPR_ratio_to_Fcurrent", "F60SPR_ratio_to_Fcurrent",
    "F70SPR_ratio_to_Fcurrent", "SSB_reference_point_25th_percentile",
    "SSB_reference_point_50th_percentile",
    "SSB_reference_point_70th_percentile",
    "negative_log_likelihood", "change_in_negative_log_likelihood",
    "SSB_25th_percentile_reference_to_unfished_SSB",
    "SSB_50th_percentile_reference_to_unfished_SSB",
    "SSB_70th_percentile_reference_to_unfished_SSB"
  ))) {
    stop("outputs$year may be blank only for time-invariant estimates, period summaries, explicitly named scenarios, or SD estimates.", call. = FALSE)
  }
  age_required <- if (name == "inputs") {
    x$measure %in% c(
      "numbers_at_age", "numbers_at_age_cv", "numbers_at_age_group", "numbers_at_age_for_M_reconstruction", "index_by_age_group",
      "index_catch_numbers_at_age",
      "biomass_at_age", "proportion_at_age", "frequency_at_age", "maturity_fecundity_at_age",
      "conditional_proportion_at_age", "growth_length_at_age", "fraction_F_before_spawning",
      "fraction_M_before_spawning", "weight_at_age", "catch_weight_at_age", "spawning_weight_at_age", "start_weight_at_age",
      "maturity_at_age", "age_error_probability", "age_error_mean_age", "mature_weight_at_age", "natural_mortality_at_age", "fecundity_at_age", "reproductive_potential_at_age", "proportion_female_at_age", "ageing_error_sd",
      "landings_numbers_at_age", "discard_numbers_at_age", "landings_fraction_at_age", "relative_standard_error",
      "landings_weight_at_age", "discard_weight_at_age", "relative_precision_weight", "observation_likelihood_weight"
    )
  } else {
    has_age_group <- if ("age_group" %in% names(x)) {
      !is.na(x$age_group) & nzchar(x$age_group)
    } else {
      rep(FALSE, nrow(x))
    }
    x$measure %in% c(
      "numbers_at_age", "biomass_at_age", "fishing_mortality_at_age",
      "natural_mortality_at_age", "mature_biomass_at_age",
      "total_mortality_at_age", "total_removals_at_age", "fleet_selectivity_at_age"
    ) & !has_age_group
  }
  age <- suppressWarnings(as.numeric(x$age))
  if (name == "inputs" && "observation_id" %in% names(x)) {
    unaged_observation_weight <- x$measure == "observation_likelihood_weight" &
      is.na(age) & !is.na(x$observation_id) & nzchar(x$observation_id)
    if (any(unaged_observation_weight)) {
      linked_observation_measure <- x$measure %in% c(
        "proportion_at_age", "frequency_at_age", "proportion_at_length",
        "frequency_at_length", "conditional_proportion_at_age",
        "conditional_frequency_at_age", "relative_abundance_index"
      )
      observation_key <- paste(x$assessment_id[linked_observation_measure],
        x$type[linked_observation_measure],
        x$observation_id[linked_observation_measure], sep = "\r")
      weight_key <- paste(x$assessment_id[unaged_observation_weight],
        x$type[unaged_observation_weight],
        x$observation_id[unaged_observation_weight], sep = "\r")
      if (any(!weight_key %in% observation_key)) {
        stop("Unaged observation likelihood weights must link to a composition or aggregate index observation by observation_id.", call. = FALSE)
      }
      age_required[unaged_observation_weight] <- FALSE
    }
  }
  if (name == "inputs") {
    unaged_index_precision <- x$type == "index" &
      x$measure == "relative_precision_weight" & is.na(age)
    if (any(unaged_index_precision)) {
      columns <- c("assessment_id", "survey", "sex", "region", "season", "year")
      key <- function(z) do.call(paste, c(lapply(z[columns], function(v) {
        v[is.na(v)] <- ""
        v
      }), sep = "\r"))
      indices <- x[x$type == "index" & x$measure %in% c(
        "total_biomass", "total_numbers", "relative_biomass_index", "relative_abundance_index"
      ), ]
      if (any(!key(x[unaged_index_precision, ]) %in% key(indices))) {
        stop("Unaged relative precision weights require a matching aggregate index observation.",
          call. = FALSE
        )
      }
    }
    seasonal_mortality <- x$basis == "per_season"
    if (any(seasonal_mortality & (x$type != "M" | x$measure != "natural_mortality_at_age" |
      is.na(x$season) | !nzchar(x$season)))) {
      cli::cli_abort("Seasonal mortality inputs must identify M-at-age and a source season.")
    }
    for (measure in c("abundance_index_cv", "biomass_index_cv", "recruitment_index_cv")) {
      selected <- x$measure == measure
      if (!any(selected)) next
      if (any(x$type[selected] != "index" | x$basis[selected] != "relative_scale" | !is.na(age[selected]))) {
        cli::cli_abort("{measure} must describe an aggregate index CV on its relative scale, without an age.")
      }
      columns <- c("assessment_id", "survey", "sex", "region", "season", "year")
      key <- function(z) do.call(paste, c(lapply(z[columns], function(v) ifelse(is.na(v), "", v)), sep = "\r"))
      target <- if (measure == "abundance_index_cv") {
        c("total_numbers", "relative_abundance_index")
      } else if (measure == "biomass_index_cv") {
        c("total_biomass", "relative_biomass_index")
      } else {
        "recruitment_index"
      }
      totals <- x[x$type == "index" & x$measure %in% target, ]
      if (any(!key(x[selected, ]) %in% key(totals))) cli::cli_abort("{measure} requires the corresponding {target} index.")
    }
    aggregate_precision <- x$measure == "relative_standard_error" & is.na(age)
    index_precision <- aggregate_precision & x$type == "index"
    catch_precision <- aggregate_precision & x$type == "catch"
    if (any(aggregate_precision & !index_precision & !catch_precision)) {
      stop("Unaged relative standard errors must describe aggregate catch or index observations.",
        call. = FALSE
      )
    }
    if (any(index_precision)) {
      columns <- c("assessment_id", "survey", "sex", "region", "season", "year")
      key <- function(z, columns) do.call(paste, c(lapply(z[columns], function(v) {
        v[is.na(v)] <- ""
        v
      }), sep = "\r"))
      totals <- x[x$type == "index" & x$measure %in%
        c("total_biomass", "total_numbers", "relative_biomass_index", "relative_abundance_index"), ]
      if (any(!key(x[index_precision, ], columns) %in% key(totals, columns))) {
        stop("Aggregate index precision requires a matching total index.", call. = FALSE)
      }
    }
    if (any(catch_precision)) {
      columns <- c("assessment_id", "fleet", "sex", "region", "season", "year")
      if ("partition" %in% names(x)) columns <- c(columns, "partition")
      key <- function(z, columns) do.call(paste, c(lapply(z[columns], function(v) {
        v[is.na(v)] <- ""
        v
      }), sep = "\r"))
      totals <- x[x$type == "catch" & x$measure %in%
        c("total_biomass", "total_numbers"), ]
      if (any(!key(x[catch_precision, ], columns) %in% key(totals, columns))) {
        stop("Aggregate catch precision requires a matching total catch observation.",
          call. = FALSE
        )
      }
    }
    age_required[aggregate_precision] <- FALSE
    age_required[unaged_index_precision] <- FALSE
  }
  whole_age <- !is.na(age) & is.finite(age) & age == as.integer(age)
  age_error_midpoint <- name == "inputs" & x$measure == "ageing_error_sd" &
    !is.na(age) & is.finite(age) &
    abs((age - floor(age)) - 0.5) < 1e-8
  if (any(age_required & !(whole_age | age_error_midpoint))) {
    stop(name, "$age must contain whole ages, except for native half-year ageing-error midpoints.", call. = FALSE)
  }
  value <- suppressWarnings(as.numeric(x$value))
  if (name == "outputs" && any(x$measure == "fleet_selectivity_at_age" &
    (is.na(value) | value < 0 | value > 1))) {
    cli::cli_abort("Fleet selectivity proportions must lie in [0, 1].")
  }
  missing_value <- is.na(value)
  signed <- if (name == "inputs") {
    x$type == "covariate" &
      x$measure %in% c("environmental_covariate", "condition_index_for_mortality") &
      x$basis == "native_covariate"
  } else {
    (x$type == "biology" & x$measure %in% c("mat_beta1", "mat_beta2")) |
      (x$type == "mortality" & x$measure == "natural_mortality_sex_difference_parameter") |
      (x$type == "diagnostic" & x$measure == "change_in_negative_log_likelihood") |
      x$type == "parameter"
  }
  missing_observation <- name == "inputs" & (
    (x$type %in% c("catch", "index") & x$measure %in% c(
      "numbers_at_age", "numbers_at_age_group", "index_by_age_group", "biomass_at_age",
      "total_numbers", "total_biomass", "catch_biomass", "relative_abundance_index", "relative_biomass_index", "spawning_output_index", "proportion_at_age",
      "abundance_index_cv", "biomass_index_cv"
    )) |
    (x$type == "catch" & x$measure %in% c(
      "discard_numbers_at_age", "catch_biomass", "landings_biomass", "discard_biomass"
    )) |
    (x$type == "catch" & x$measure == "discard_fraction_cv" & missing_value &
      !is.na(x$notes) & grepl("blank cells remain missing", x$notes, fixed = TRUE))
  )
  if (name == "outputs") {
    missing_observation <- x$type == "index" & x$measure == "predicted_index"
  }
  if (any(missing_value & !missing_observation) ||
    any(!is.finite(value[!missing_value])) ||
    any(value < 0 & !signed, na.rm = TRUE)) {
    stop(name, "$value must contain finite numbers except for documented missing catch or index observations, source-missing CVs, and source-missing predicted indices; negative values are allowed only for signed covariates, biological or mortality parameters, and relative fit diagnostics.", call. = FALSE)
  }
  if (name == "inputs") {
    if (any(x$type == "maturity" & (value < 0 | value > 1))) {
      stop("Maturity values must be proportions from 0 to 1.", call. = FALSE)
    }
    sampling_time <- suppressWarnings(as.numeric(x$sampling_time))
    if (any(!is.na(x$sampling_time) & is.na(sampling_time)) ||
      any(!is.na(sampling_time) & (!is.finite(sampling_time) |
        sampling_time < 0 | sampling_time > 1))) {
      stop("inputs$sampling_time must be numeric in [0, 1] where present.", call. = FALSE)
    }
    proportion <- x$basis %in% c("proportion", "proportion_numbers", "proportion_biomass")
    above_one_landings_fraction <- proportion &
      x$measure == "landings_fraction_at_age" & !is.na(value) & value > 1
    documented_landings_fraction <- !is.na(x$notes) &
      grepl("above one|exceed", x$notes, ignore.case = TRUE)
    if (any(above_one_landings_fraction & !documented_landings_fraction)) {
      stop("Landings fractions above one must be documented as unmodified source values.", call. = FALSE)
    }
    if (any(proportion & !is.na(value) & value > 1 & !above_one_landings_fraction)) {
      stop("Input proportions must lie in [0, 1].", call. = FALSE)
    }
    if (any(x$measure %in% c("log_index_sd", "log_catch_sd", "index_sd", "relative_precision_weight", "observation_likelihood_weight") & value <= 0)) {
      stop("Supplied SDs, precision weights, and likelihood weights must be positive.", call. = FALSE)
    }
    age_error_probability <- x$measure == "age_error_probability"
    if (any(age_error_probability)) {
      observed_age <- suppressWarnings(as.numeric(x$age_error))
      if (any(x$type[age_error_probability] != "biology" |
        x$basis[age_error_probability] != "proportion" |
        x$unit[age_error_probability] != "probability" |
        is.na(observed_age[age_error_probability]) |
        observed_age[age_error_probability] != as.integer(observed_age[age_error_probability]))) {
        cli::cli_abort("age_error_probability requires true-age rows and integer observed ages in age_error.")
      }
      group <- paste(x$assessment_id[age_error_probability],
        x$sex[age_error_probability], x$age[age_error_probability], sep = "\r")
      row_sums <- tapply(value[age_error_probability], group, sum)
      if (any(abs(row_sums - 1) > 1e-6)) {
        cli::cli_abort("Each age-error probability row must sum to one over observed ages.")
      }
    }
  } else {
    if ("age_group" %in% names(x) && any(x$measure %in% c("Fbar", "Mbar") &
      (is.na(x$age_group) | !nzchar(x$age_group)))) {
      stop("Grouped Fbar and Mbar outputs must identify their age_group.", call. = FALSE)
    }
    for (field in c("se", "lwr", "upr")) {
      z <- suppressWarnings(as.numeric(x[[field]]))
      if (any(!is.na(x[[field]]) & (is.na(z) | !is.finite(z)))) {
        stop("outputs$", field, " must contain finite numbers or blanks.", call. = FALSE)
      }
      if (field == "se" && any(z < 0, na.rm = TRUE)) {
        stop("outputs$se cannot be negative.", call. = FALSE)
      }
    }
    both <- !is.na(x$lwr) & !is.na(x$upr)
    if (any(as.numeric(x$lwr[both]) > as.numeric(x$upr[both]))) {
      stop("outputs confidence limits have lwr greater than upr.", call. = FALSE)
    }
  }
}

composition <- inputs$measure %in% c("proportion_at_length", "conditional_proportion_at_age", "proportion_at_weight", "frequency_at_weight")
if (any(composition)) {
  missing <- setdiff(composition_dimensions, names(inputs))
  if (length(missing)) stop("Composition inputs lack dimensions: ", paste(missing, collapse = ", "))
  z <- inputs[composition, , drop = FALSE]
  for (field in setdiff(composition_dimensions, "observation_id")) {
    values <- suppressWarnings(as.numeric(z[[field]]))
    if (any(!is.na(z[[field]]) & (is.na(values) | !is.finite(values)))) {
      stop("Composition inputs$", field, " must contain finite numbers or blanks.")
    }
    z[[field]] <- values
  }
  for (field in c("age_error", "partition")) {
    if (any(z[[field]] < 0 | z[[field]] != floor(z[[field]]), na.rm = TRUE)) {
      stop("Composition inputs$", field, " must contain non-negative integer codes.")
    }
  }
  if (anyNA(z$observation_id) || any(!nzchar(z$observation_id))) {
    stop("Composition inputs need observation IDs.")
  }
  missing_sample_size <- is.na(z$sample_size)
  documented_missing_sample_size <- !is.na(z$notes) &
    grepl("sample_size is left blank", z$notes, fixed = TRUE)
  if (any(missing_sample_size & !documented_missing_sample_size) ||
    any(!missing_sample_size & z$sample_size <= 0)) {
    stop("Composition inputs need positive supplied sample sizes or a documented source omission.")
  }
  length_rows <- z$measure == "proportion_at_length"
  if (any(length_rows & (is.na(z$length_bin) | z$length_bin < 0))) {
    stop("Length compositions need non-negative native length-bin labels.")
  }
  age_rows <- z$measure == "conditional_proportion_at_age"
  if (any(age_rows & (is.na(z$length_bin_lower) | is.na(z$length_bin_upper) |
    z$length_bin_upper < z$length_bin_lower | is.na(z$age_error)))) {
    stop("Conditional age compositions need ordered conditioning bins and age-error codes.")
  }
  weight_rows <- z$measure %in% c("proportion_at_weight", "frequency_at_weight")
  if (any(weight_rows & (is.na(z$weight_bin) | z$weight_bin < 0))) {
    stop("Weight compositions need non-negative native weight-bin labels.")
  }
}

cat("Database valid: ", nrow(stocks), " stocks, ", nrow(assessments),
  " assessments, ", nrow(assumptions), " assumptions, ", nrow(inputs),
  " inputs, and ", nrow(outputs), " outputs.\n",
  sep = ""
)
for (id in assessments$assessment_id) {
  x <- inputs[inputs$assessment_id == id, , drop = FALSE]
  surveys <- unique(x$survey[!is.na(x$survey) & nzchar(x$survey)])
  years <- suppressWarnings(as.numeric(x$year))
  ages <- suppressWarnings(as.numeric(x$age))
  cat(id, ": input rows by type: ",
    paste(names(table(x$type)), as.integer(table(x$type)), collapse = "; "),
    "; surveys: ", if (length(surveys)) paste(surveys, collapse = "; ") else "none",
    "; years: ", if (any(is.finite(years))) paste(range(years[is.finite(years)]), collapse = "-") else "unknown",
    "; ages: ", if (any(is.finite(ages))) paste(range(ages[is.finite(ages)]), collapse = "-") else "unknown",
    "\n",
    sep = ""
  )
}
