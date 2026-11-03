root <- "."
cache_dir <- file.path(root, "source_cache", "iceland_haddock_2025")
assessment_id <- "ices_haddock_iceland_2025"
summary_id <- "ices_haddock_iceland_2026"
stock_id <- "ices_haddock_iceland"
data_url <- "https://dt.hafogvatn.is/astand/2025/2_HAD_en.html"
report_url <- "https://www.hafogvatn.is/static/extras/images/02-had_2025_techreport_en.html"
summary_url <- "https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html"
framework_url <- "https://doi.org/10.17895/ices.pub.28444499.v1"
source_name <- "MFRI 2025 Icelandic haddock assessment tables and technical report"

db <- file.path(root, "database")
paths <- setNames(
  file.path(db, paste0(c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE, check.names = FALSE)
read_source <- function(name) {
  path <- file.path(cache_dir, paste0(name, ".csv"))
  if (!file.exists(path)) stop("Missing cached source table: ", path, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}
stocks <- read_db("stocks")
assessments <- read_db("assessments")
if (stock_id %in% stocks$stock_id ||
  any(assessments$assessment_id %in% c(assessment_id, summary_id))) {
  stop("Icelandic haddock records already exist in the database.", call. = FALSE)
}

ages <- 1:12
input_years <- 1979:2024
read_age_matrix <- function(name, years, year_column = "Year", allow_missing = FALSE) {
  x <- read_source(name)
  years_in_file <- as.integer(x[[year_column]])
  x <- x[match(years, years_in_file), , drop = FALSE]
  if (nrow(x) != length(years) || anyNA(x[[year_column]])) {
    stop(name, " does not cover the requested years.", call. = FALSE)
  }
  values <- as.matrix(x[as.character(ages)])
  storage.mode(values) <- "numeric"
  if (!allow_missing && anyNA(values)) {
    stop(name, " contains missing age values.", call. = FALSE)
  }
  values
}

catch <- read_age_matrix("HAD_catch_at_age", input_years)
catch_weight <- read_age_matrix("HAD_catch_weights", input_years)
stock_weight <- read_age_matrix("HAD_stock_weights", input_years)
maturity <- read_age_matrix("HAD_stock_maturity", input_years)
smb <- read_age_matrix("HAD_smb", 1985:2024, allow_missing = TRUE)
smh <- read_age_matrix("HAD_smh", 1995:2024, allow_missing = TRUE)
n_at_age <- read_age_matrix("HAD_numbers_at_age", 1979:2025)
f_at_age <- read_age_matrix("HAD_f", input_years)
summary <- read_source("HAD_assessment")
summary$year <- as.integer(summary$year)
summary <- summary[summary$year %in% 1979:2025, , drop = FALSE]
summary <- summary[order(summary$year), , drop = FALSE]
if (!identical(summary$year, 1979:2025) ||
  !identical(dim(catch), c(46L, 12L)) ||
  !identical(dim(smb), c(40L, 12L)) ||
  !identical(dim(smh), c(30L, 12L)) ||
  !identical(dim(n_at_age), c(47L, 12L)) ||
  !identical(dim(f_at_age), c(46L, 12L)) ||
  any(catch < 0) || any(catch_weight <= 0) || any(stock_weight <= 0) ||
  any(maturity < 0 | maturity > 1) ||
  any(n_at_age < 0) || any(f_at_age < 0) ||
  any(!is.finite(summary$ssb)) || any(!is.finite(summary$recruitment))) {
  stop("Icelandic haddock source tables failed coverage or value checks.", call. = FALSE)
}

input_row <- function(type, measure, basis, fleet = "", survey = "",
                      year, age, value, unit, source_reference, notes = "",
                      transformation = "", sampling_time = NA_real_,
                      source_type = "official_table") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "combined", region = "ICES 5.a",
    season = "", year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
    value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = NA_real_, stringsAsFactors = FALSE
  )
}
age_inputs <- function(type, measure, basis, years, values, unit,
                       source_reference, notes = "", transformation = "",
                       survey = "", season = "", sampling_time = NA_real_) {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(values)
  grid <- grid[!is.na(grid$value), , drop = FALSE]
  rows <- input_row(
    type, measure, basis,
    survey = survey, year = grid$year, age = grid$age,
    value = grid$value, unit = unit, source_reference = source_reference,
    notes = notes, transformation = transformation, sampling_time = sampling_time
  )
  rows$season <- season
  rows
}
static_M <- input_row(
  "M", "natural_mortality_at_age", "per_year",
  year = NA_real_, age = ages, value = rep(0.2, length(ages)),
  unit = "per year", source_reference = "MFRI 2025 technical report, model inputs",
  notes = "Natural mortality is fixed at 0.2 for all ages and years.",
  source_type = "official_document"
)
inputs_add <- rbind(
  age_inputs("catch", "numbers_at_age", "numbers", input_years, catch,
    "thousand fish", paste(source_name, "Catch numbers-at-age"),
    notes = "Reported catch-at-age for 1979-2024; age 12 is the 12+ group.",
    transformation = "Retain the official values in thousands of fish."
  ),
  age_inputs("catch_weight", "weight_at_age", "kg_per_fish", input_years, catch_weight,
    "g per fish", paste(source_name, "Catch weights-at-age"),
    notes = "Catch weight-at-age from commercial samples; age 12 is the 12+ group."
  ),
  age_inputs("weight", "weight_at_age", "kg_per_fish", input_years, stock_weight,
    "g per fish", paste(source_name, "Stock weights-at-age"),
    notes = "Stock weights from the March survey; the source reports pre-1985 values as the 1985 age vector."
  ),
  age_inputs("maturity", "maturity_at_age", "proportion", input_years, maturity,
    "proportion mature", paste(source_name, "Maturity-at-age"),
    notes = "Maturity-at-age from the March survey; the source reports pre-1985 values as the 1985 age vector."
  ),
  age_inputs("index", "numbers_at_age", "index_scale", 1985:2024, smb,
    "survey index (unit unresolved)", paste(source_name, "IS-SMB spring survey indices-at-age"),
    notes = "Official age-specific spring survey series. The source labels these values as numbers but does not identify a physical unit in the table; sampling_time 0.20 is a month-midpoint approximation, not the exact official-model timing.",
    survey = "IS-SMB", season = "spring", sampling_time = 0.20
  ),
  age_inputs("index", "numbers_at_age", "index_scale", 1995:2024, smh,
    "survey index (unit unresolved)", paste(source_name, "IS-SMH autumn survey indices-at-age"),
    notes = "Official age-specific autumn survey series. The source labels these values as numbers but does not identify a physical unit in the table; sampling_time 0.80 is a month-midpoint approximation, not the exact official-model timing.",
    survey = "IS-SMH", season = "autumn", sampling_time = 0.80
  ),
  static_M
)

output_row <- function(type, measure, year, age = NA_real_, value, unit,
                       source_reference, notes = "", lwr = NA_real_, upr = NA_real_,
                       source_type = "official_table") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "combined", region = "ICES 5.a", season = "",
    year = year, age = age,
    age_group = ifelse(!is.na(age) & age == 12, "12+", ""),
    value = value, se = NA_real_, lwr = lwr, upr = upr, unit = unit,
    source_type = source_type, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
age_outputs <- function(measure, years, values, unit, source_reference, notes) {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(values)
  output_row(
    if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age, grid$value, unit, source_reference, notes
  )
}
outputs_add <- rbind(
  age_outputs(
    "numbers_at_age", 1979:2025, n_at_age, "thousand fish",
    paste(source_name, "Stock numbers-at-age"),
    "Official assessment abundance estimates; age 12 is the 12+ group."
  ),
  output_row(
    "population", "total_numbers", 1979:2025,
    value = rowSums(n_at_age), unit = "thousand fish",
    source_reference = paste("Derived from", source_name, "Stock numbers-at-age"),
    notes = paste0(
      "Sum across all reported age groups (",
      paste(c(paste0("age:", ages[ages < 12]), "group:12+"), collapse = ", "),
      "). No standard error or interval was combined."
    ),
    source_type = "derived_source_output"
  ),
  age_outputs(
    "fishing_mortality_at_age", input_years, f_at_age, "per year",
    paste(source_name, "Fishing mortality-at-age"),
    "Official assessment fishing mortality estimates; age 12 is the 12+ group."
  ),
  output_row("biomass", "SSB", summary$year,
    value = summary$ssb,
    unit = "tonnes", source_reference = paste(source_name, "Assessment summary"),
    notes = "Published aggregate spawning biomass. Low/high values are retained as published; interval coverage is not specified in the table. The source uses pre-spawning mortality fractions; tinyAM comparisons derive a separately labelled common-definition mature biomass from N and shared biology.",
    lwr = summary$low_ssb, upr = summary$high_ssb
  ),
  output_row("biomass", "reference_biomass", summary$year,
    value = summary$refbio,
    unit = "tonnes", source_reference = paste(source_name, "Assessment summary"),
    notes = "Published biomass of fish at least 45 cm; low/high values are retained as published, with interval coverage unspecified. No equivalent length-based tinyAM quantity is available.",
    lwr = summary$low_refbio, upr = summary$high_refbio
  ),
  output_row("recruitment", "recruitment", summary$year,
    age = 1,
    value = summary$recruitment, unit = "thousand fish",
    source_reference = paste(source_name, "Assessment summary"),
    notes = "Age-1 recruitment as reported in the assessment summary; low/high interval coverage is unspecified in the table.",
    lwr = summary$low_recruitment, upr = summary$high_recruitment
  )
)

assumption_rows <- function(id, reference, notes) {
  component <- c(
    "assessment", "population", "recruitment", "F", "M",
    "catch", "index", "index", "spawning", "weight",
    "maturity", "selectivity"
  )
  setting <- c(
    "model_family", "age_structure", "recruitment_age", "process",
    "natural_mortality", "catch_data", "spring_survey",
    "autumn_survey", "pre_spawn_mortality", "weight_schedule",
    "maturity_schedule", "selectivity"
  )
  value <- c(
    "SAM state-space statistical catch-at-age model",
    "Ages 1-12+, age 12 is the plus group; model starts in 1979",
    "Recruitment at age 1",
    "Fishing mortality and selectivity vary over time",
    "Fixed M=0.2 per year for all ages",
    "Commercial catch-at-age and catch weights",
    "IS-SMB age-specific spring survey",
    "IS-SMH age-specific autumn survey",
    "F fraction before spawning 0.4; M fraction before spawning 0.3",
    "March survey stock weights; pre-1985 vector held at 1985 values",
    "March survey maturity; pre-1985 vector held at 1985 values",
    "Selectivity allowed to vary over time"
  )
  rows <- data.frame(
    assessment_id = id, component = component, fleet = "", survey = "",
    sex = "combined", region = "ICES 5.a", season = "",
    setting = setting, value = value, source_reference = reference,
    notes = notes, stringsAsFactors = FALSE
  )
  timing_rows <- data.frame(
    assessment_id = id, component = "survey_timing", fleet = "",
    survey = c("IS-SMB", "IS-SMH"), sex = "combined", region = "ICES 5.a",
    season = c("spring", "autumn"), setting = "sampling_time",
    value = c(
      "0.20 month-midpoint approximation for March",
      "0.80 month-midpoint approximation for October"
    ),
    source_reference = reference, notes = notes, stringsAsFactors = FALSE
  )
  rbind(rows, timing_rows)
}
assumptions_add <- rbind(
  assumption_rows(
    assessment_id, "MFRI 2025 technical report; ICES WKICEGAD 2025",
    "Reported structure for the detailed 2025 assessment. The exact SAM process covariance and all parameter-sharing settings are not available in the extracted source tables."
  ),
  assumption_rows(
    summary_id, "MFRI 2026 Icelandic haddock technical report; ICES WKICEGAD 2025",
    "The 2026 report says the assessment is in line with the previous year. These assumptions describe the report only; no 2025 age-specific input matrices are copied from the 2025 assessment."
  )
)

stock_add <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "MFRI/ICES",
  authority_stock_id = "had.27.5a",
  scientific_name = "Melanogrammus aeglefinus",
  common_name = "Icelandic haddock",
  area = "ICES Division 5.a", region = "Icelandic waters",
  ocean = "Northeast Atlantic",
  notes = "Icelandic haddock assessed in ICES Division 5.a.",
  stringsAsFactors = FALSE
)
assessment_add <- data.frame(
  assessment_id = c(assessment_id, summary_id), stock_id = stock_id,
  assessment_year = c(2025, 2026), terminal_year = c(2024, 2026),
  estimate_terminal_year = c(2025, 2026),
  assessment_type = c("benchmark_assessment", "assessment_update"),
  model_family = "SAM",
  model_version = c(
    "WKICEGAD 2025 benchmark assessment",
    "2026 annual assessment using the benchmark model"
  ),
  is_current = c("TRUE", "FALSE"), is_applied = c("TRUE", "TRUE"),
  framework_year = 2025,
  assessment_url = c(report_url, summary_url),
  framework_url = framework_url,
  data_url = c(data_url, ""),
  model_url = "", repository_url = "",
  assumptions_status = c("partial", "partial"),
  inputs_status = c("partial", "partial"),
  outputs_status = c("partial", "partial"),
  notes = c(
    "Most recent detailed assessment with recoverable numerical age inputs and outputs. Catch and biological input tables end in 2024; population estimates extend to 2025. Survey-index units and exact within-year survey timing are not specified in the tables.",
    "Newer 2026 official assessment represented by its technical report only. The public 2026 data-table endpoint was unavailable when reviewed; no 2025 age matrices are substituted for 2026 values."
  ), stringsAsFactors = FALSE
)

append_rows <- function(name, rows) {
  path <- paths[[name]]
  columns <- names(read_db(name))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  utils::write.table(rows[columns], path,
    sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}
if (nrow(inputs_add) < 2500L || nrow(outputs_add) != 1304L ||
  any(!is.finite(inputs_add$value)) || any(!is.finite(outputs_add$value)) ||
  any(inputs_add$value[inputs_add$type == "maturity"] > 1) ||
  any(inputs_add$value[inputs_add$type == "M"] != 0.2)) {
  stop("Icelandic haddock records failed final validation.", call. = FALSE)
}

append_rows("stocks", stock_add)
append_rows("assessments", assessment_add)
append_rows("assumptions", assumptions_add)
append_rows("inputs", inputs_add)
append_rows("outputs", outputs_add)
cat("Imported detailed 2025 Icelandic haddock records and registered the 2026 summary-only update: ",
  nrow(inputs_add), " inputs and ", nrow(outputs_add), " outputs.\n",
  sep = ""
)
