root <- file.path("database")
stock_path <- file.path(root, "stocks.csv")
stock_bytes <- readBin(stock_path, what = "raw", n = file.info(stock_path)$size)
if (any(stock_bytes == as.raw(0))) {
  stop("stocks.csv contains an embedded NUL byte.", call. = FALSE)
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
    "sampling_time", "source_type", "source_reference", "transformation", "notes"
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
  "Northwest Atlantic", "Northeast Atlantic",
  "Northeast Pacific", "Northwest Pacific", "Southwest Pacific"
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
  "length_bin_upper", "sample_size", "age_error", "partition"
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
allowed_input_types <- c("catch", "index", "weight", "catch_weight", "maturity", "M", "covariate", "biology")
allowed_output_types <- c(
  "population", "mortality", "biomass", "recruitment", "catch",
  "index", "catchability", "biology"
)
allowed_input_measures <- c(
  "frequency_at_length", "frequency_at_age", "maturity_fecundity_at_age", "maturity_sample_size", "mature_sample_count", "composition_sample_count",
  "numbers_at_age", "numbers_at_age_group", "numbers_at_age_for_M_reconstruction", "index_by_age_group",
  "index_catch_numbers_at_age", "effort",
  "biomass_at_age", "total_numbers",
  "total_biomass", "landings_biomass", "discard_biomass", "discard_fraction", "discard_fraction_cv", "catch_se", "total_egg_production", "landings_lower_bound", "landings_upper_bound",
  "catch_lower_bound", "catch_upper_bound", "proportion_at_age", "proportion_at_length",
  "conditional_proportion_at_age", "weight_at_age", "catch_weight_at_age", "spawning_weight_at_age", "start_weight_at_age",
  "maturity_at_age", "mature_weight_at_age", "natural_mortality_at_age", "condition_index_for_mortality",
  "fecundity_at_age", "proportion_female_at_age",
  "mean_catch_length", "length_at_first_capture", "MSY_proxy_length",
  "fixed_mortality_medium", "fixed_mortality_low", "fixed_mortality_high",
  "relative_biomass_index", "relative_abundance_index", "abundance_index_cv", "biomass_index_cv",
  "landings_proportion", "landings_numbers_at_age", "discard_numbers_at_age", "landings_fraction_at_age",
  "landings_weight_at_age", "discard_weight_at_age", "log_index_sd", "log_catch_sd", "index_sd", "relative_precision_weight", "observation_likelihood_weight", "relative_standard_error", "mean_body_weight", "mean_body_weight_cv", "ageing_error_sd", "larval_abundance_index", "environmental_covariate", "fraction_F_before_spawning",
  "fraction_M_before_spawning", "capelin_biomass_index"
)
allowed_bases <- c(
  "native_frequency",
  "numbers", "biomass", "proportion_numbers", "proportion_biomass",
  "kg_per_fish", "g_per_fish", "weight_per_fish", "age_error_sd", "native_scale", "proportion", "per_year", "per_season", "log_scale", "native_covariate",
  "relative_precision", "relative_scale", "index_scale", "egg_count"
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

    has_year <- !is.na(x$year) & nzchar(as.character(x$year))
    has_year_basis <- !is.na(x$year_basis) & nzchar(as.character(x$year_basis))
    if (any(has_year & !x$year_basis %in% c("calendar_year", "model_year", "birth_cohort")) ||
      any(!has_year & has_year_basis)) {
      stop("inputs$year_basis must identify a supplied year dimension.", call. = FALSE)
    }
  }
  year <- whole_year(x, "year", name, allow_blank = name %in% c("inputs", "outputs"))
  blank_year <- is.na(x$year) | !nzchar(as.character(x$year))
  if (name == "outputs" && any(blank_year & !x$measure %in% c(
    "q", "q_power", "process_sd", "observation_sd", "mat_beta1", "mat_beta2",
    "log_q_power", "growth_length_at_age", "growth_rate", "growth_sd_length_at_age",
    "Fmsy", "Bmsy", "msy", "mean_recruitment", "median_recruitment",
    "recruitment_ar1_rho",
    "natural_mortality_average_parameter", "natural_mortality_sex_difference_parameter",
    "fleet_selectivity_at_age", "natural_mortality_at_age", "LRP", "USR", "unfished_spawning_biomass",
    "maximum_exploitation_rate", "biomass_reference_point_0.4_BMSY",
    "biomass_reference_point_0.8_BMSY", "Bmsy_to_B0",
    "exploitation_rate_at_msy"
  ))) {
    stop("outputs$year may be blank only for time-invariant estimates or SD estimates.", call. = FALSE)
  }
  age_required <- if (name == "inputs") {
    x$measure %in% c(
      "numbers_at_age", "numbers_at_age_group", "numbers_at_age_for_M_reconstruction", "index_by_age_group",
      "index_catch_numbers_at_age",
      "biomass_at_age", "proportion_at_age", "frequency_at_age", "maturity_fecundity_at_age",
      "conditional_proportion_at_age", "fraction_F_before_spawning",
      "fraction_M_before_spawning", "weight_at_age", "catch_weight_at_age", "spawning_weight_at_age", "start_weight_at_age",
      "maturity_at_age", "mature_weight_at_age", "natural_mortality_at_age", "fecundity_at_age", "proportion_female_at_age", "ageing_error_sd",
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
      "total_mortality_at_age", "fleet_selectivity_at_age"
    ) & !has_age_group
  }
  age <- suppressWarnings(as.numeric(x$age))
  if (name == "inputs") {
    seasonal_mortality <- x$basis == "per_season"
    if (any(seasonal_mortality & (x$type != "M" | x$measure != "natural_mortality_at_age" |
      is.na(x$season) | !nzchar(x$season)))) {
      cli::cli_abort("Seasonal mortality inputs must identify M-at-age and a source season.")
    }
    for (measure in c("abundance_index_cv", "biomass_index_cv")) {
      selected <- x$measure == measure
      if (!any(selected)) next
      if (any(x$type[selected] != "index" | x$basis[selected] != "relative_scale" | !is.na(age[selected]))) {
        cli::cli_abort("{measure} must describe an aggregate index CV on its relative scale, without an age.")
      }
      columns <- c("assessment_id", "survey", "sex", "region", "season", "year")
      key <- function(z) do.call(paste, c(lapply(z[columns], function(v) ifelse(is.na(v), "", v)), sep = "\r"))
      target <- if (measure == "abundance_index_cv") "total_numbers" else "total_biomass"
      totals <- x[x$type == "index" & x$measure == target, ]
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
        c("total_biomass", "total_numbers", "relative_biomass_index"), ]
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
      (x$type == "mortality" & x$measure == "natural_mortality_sex_difference_parameter")
  }
  missing_observation <- name == "inputs" & (
    (x$type %in% c("catch", "index") & x$measure %in% c(
      "numbers_at_age", "numbers_at_age_group", "index_by_age_group", "biomass_at_age",
      "total_numbers", "total_biomass", "relative_abundance_index",
      "abundance_index_cv", "biomass_index_cv"
    )) |
    (x$type == "catch" & x$measure %in% c("landings_biomass", "discard_biomass"))
  )
  if (any(missing_value & !missing_observation) ||
    any(!is.finite(value[!missing_value])) ||
    any(value < 0 & !signed, na.rm = TRUE)) {
    stop(name, "$value must contain finite numbers except for documented missing catch or index observations; negative values are allowed only for signed covariates and documented signed biological or mortality parameters.", call. = FALSE)
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
      x$measure == "landings_fraction_at_age" & value > 1
    documented_landings_fraction <- !is.na(x$notes) &
      grepl("above one|exceed", x$notes, ignore.case = TRUE)
    if (any(above_one_landings_fraction & !documented_landings_fraction)) {
      stop("Landings fractions above one must be documented as unmodified source values.", call. = FALSE)
    }
    if (any(proportion & value > 1 & !above_one_landings_fraction)) {
      stop("Input proportions must lie in [0, 1].", call. = FALSE)
    }
    if (any(x$measure %in% c("log_index_sd", "log_catch_sd", "index_sd", "relative_precision_weight", "observation_likelihood_weight") & value <= 0)) {
      stop("Supplied SDs, precision weights, and likelihood weights must be positive.", call. = FALSE)
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

composition <- inputs$measure %in% c("proportion_at_length", "conditional_proportion_at_age")
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
  if (anyNA(z$observation_id) || any(!nzchar(z$observation_id)) ||
    anyNA(z$sample_size) || any(z$sample_size <= 0)) {
    stop("Composition inputs need observation IDs and positive supplied sample sizes.")
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

