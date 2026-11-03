root <- "."
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_acadian_redfish_2025")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")

candidate_id <- "NOAA:10455"
stock_id <- "noaa_acadian_redfish_gom_gb"
assessment_id <- "noaa_acadian_redfish_gom_gb_2025"
fleet <- "Trawl"
surveys <- c("NEFSC fall survey", "NEFSC spring survey")
report_name <- "2025_RED_UNIT_RPT_2025_09_17_121440.522737.pdf"
input_name <- "2025_RED_UNIT_MOD_BaseWHAMInput.DAT"
code_name <- "2025_RED_UNIT_MOD_BaseWHAMCode.R"
output_file <- "2025_RED_UNIT_FIG_BaseWHAMFiguresTables.html"
output_name <- file.path("figures", output_file)
output_sha256 <- "009dd6a38215b2e4ce2eb8f10dc51e2fa5959542cfd198af7a8e938fd5ed679b"

source(file.path(root, "scripts", "database", "candidate_register_io.R"), local = TRUE)

read_table <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

blank_row <- function(fields, values = list()) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, stringsAsFactors = FALSE, optional = TRUE)
}

rows_from <- function(fields, rows) {
  if (!length(rows)) return(blank_row(fields)[FALSE, , drop = FALSE])
  do.call(rbind, lapply(rows, function(row) blank_row(fields, row)))
}

append_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  utils::write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n", fileEncoding = "UTF-8")
}

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

source_manifest <- read_table(file.path(cache, "sources.csv"))
verify_source <- function(file) {
  row <- source_manifest[source_manifest$file == file, , drop = FALSE]
  path <- file.path(cache, file)
  if (nrow(row) != 1L || !file.exists(path) ||
      tolower(row$sha256) != sha256_file(path)) {
    stop("The cached NOAA source differs from its manifest: ", file, call. = FALSE)
  }
}
for (file in c(
  "2025_RED_UNIT.zip", report_name, code_name, input_name,
  "2025_RED_UNIT_FIG_FiguresTables.zip",
  "September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf",
  output_name,
  "bundle/2025_RED_UNIT_BKG_2023AssessmentReport.pdf",
  "bundle/2025_RED_UNIT_BKG_2024StateSpaceRTReport.pdf"
)) verify_source(file)

input_path <- file.path(cache, input_name)
html_path <- file.path(cache, output_name)
if (!file.exists(html_path) || sha256_file(html_path) != output_sha256) {
  stop("The extracted Run 5 output table differs from the reviewed archive member.",
    call. = FALSE)
}

years <- 1963:2024
ages <- 1:26
n_years <- length(years)
n_ages <- length(ages)
age_labels <- c(as.character(1:25), "26+")
dat_lines <- readLines(input_path, warn = FALSE)

read_after <- function(pattern, n) {
  i <- grep(pattern, dat_lines)[1L]
  if (is.na(i)) stop("Missing ASAP input field: ", pattern, call. = FALSE)
  values <- scan(text = paste(dat_lines[seq.int(i + 1L, length(dat_lines))],
    collapse = " "), what = double(), n = n, quiet = TRUE)
  if (length(values) != n) stop("Unexpected values after ", pattern, call. = FALSE)
  values
}

read_matrix <- function(pattern, nrow, ncol) {
  matrix(read_after(pattern, nrow * ncol), nrow = nrow, ncol = ncol, byrow = TRUE)
}

dimensions <- c(
  read_after("^# Number of Years", 1L),
  read_after("^# First Year", 1L),
  read_after("^# Number of Ages", 1L),
  read_after("^# Number of Fleets", 1L),
  read_after("^# Number of Available Survey Indices", 1L)
)
if (!identical(as.integer(dimensions), c(62L, 1963L, 26L, 1L, 2L))) {
  stop("The NOAA Run 5 input dimensions differ from the reviewed assessment.", call. = FALSE)
}

labels <- sub("^#\\$", "", grep("^#\\$[[:alnum:]]", dat_lines, value = TRUE))
if (!identical(labels, c("Trawl", "Fall", "Spring"))) {
  stop("Unexpected fleet or survey labels in the ASAP input.", call. = FALSE)
}

natural_mortality <- read_matrix("^# Natural Mortality", n_years, n_ages)
maturity <- read_matrix("^# Maturity", n_years, n_ages)
spawning_fraction <- read_after(
  "^# Fraction of year that elapses prior to SSB calculation", 1L
)
weight_matrices <- lapply(1:3, function(i) {
  read_matrix(paste0("^# Weight Matrix - ", i), n_years, n_ages)
})
weight_pointers <- as.integer(read_after("^# Weights at Age Pointers", 6L))
index_units <- as.integer(read_after("^# Aggregate Index Units", 2L))
age_comp_units <- as.integer(read_after("^# Age Proportion Index Units", 2L))
index_weight_pointers <- as.integer(read_after("^# Weight at Age Matrix", 2L))
index_month <- read_after("^# Index Month", 2L)
index_selectivity_link <- as.integer(read_after("^# Index Selectivity Link to Fleet", 2L))
index_start_age <- as.integer(read_after("^# Index Start Age", 2L))
index_end_age <- as.integer(read_after("^# Index End Age", 2L))
use_index_composition <- as.integer(read_after("^# Estimate Proportion", 2L))
use_index <- as.integer(read_after("^# Use Index", 2L))

catch <- read_matrix("^# Fleet-1 Catch Data", n_years, n_ages + 1L)
catch_neff <- read_after("^# Catch Effective Sample Size by Year and Fleet", n_years)
catch_cv <- read_after("^# Catch Total CV by Year and Fleet", n_years)
discard <- read_matrix("^# Fleet-1 Discards Data", n_years, n_ages + 1L)
release <- read_matrix("^# Fleet-1 Release Data", n_years, n_ages)
lambda_catch <- read_after("^# Lambda for Total Catch in Weight by Fleet", 1L)
lambda_discard <- read_after("^# Lambda for Total Discards at Age by Fleet", 1L)

indices <- lapply(1:2, function(i) {
  values <- read_matrix(paste0("^# Index-", i, " Data"), n_years, n_ages + 4L)
  if (!identical(as.integer(values[, 1L]), years)) {
    stop("Index ", i, " does not align with the modeled years.", call. = FALSE)
  }
  list(
    index = values[, 2L], cv = values[, 3L],
    composition = values[, 4L:(3L + n_ages), drop = FALSE],
    neff = values[, n_ages + 4L],
    sampling_time = (index_month[i] - 1) / 12
  )
})

constant_over_years <- function(x) {
  all(apply(x, 2L, function(v) length(unique(v)) == 1L))
}
if (!all(vapply(
  c(list(natural_mortality, maturity), weight_matrices),
  constant_over_years, logical(1L)
))) stop("This import expects the reviewed constant age schedules.", call. = FALSE)
if (!all(natural_mortality == 0.05) ||
    !all(discard == 0) || !all(release == 0) ||
    lambda_discard != 0 || lambda_catch != 1 ||
    !identical(weight_pointers, c(1L, 1L, 1L, 1L, 2L, 3L)) ||
    !identical(index_units, c(2L, 2L)) ||
    !identical(age_comp_units, c(2L, 2L)) ||
    !identical(index_weight_pointers, c(3L, 3L)) ||
    !identical(index_month, c(10.5, 4.5)) ||
    !identical(index_selectivity_link, c(-1L, -1L)) ||
    !identical(index_start_age, c(1L, 1L)) ||
    !identical(index_end_age, c(26L, 26L)) ||
    !identical(use_index_composition, c(1L, 1L)) ||
    !identical(use_index, c(1L, 1L)) ||
    spawning_fraction != 0.4) {
  stop("A reviewed Run 5 mortality, weights, catch, or index setting changed.", call. = FALSE)
}
if (any(catch[, n_ages + 1L] < 0) || any(catch_neff < 0) ||
    any(catch_cv < 0) || any(catch[, 1:n_ages] < 0)) {
  stop("The native catch inputs contain unexpected negative values.", call. = FALSE)
}

html <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
html_tables <- regmatches(html, gregexpr(
  "(?is)<table[^>]*>.*?</table>", html, perl = TRUE
))[[1L]]

html_text <- function(x) {
  x <- gsub("&nbsp;", " ", x, fixed = TRUE)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("<[^>]*>", " ", x, perl = TRUE)
  x <- gsub("\\\\[()]", "", x, perl = TRUE)
  trimws(gsub("[[:space:]]+", " ", x, perl = TRUE))
}

table_for_caption <- function(pattern) {
  found <- which(vapply(html_tables, function(x) grepl(pattern, x, fixed = TRUE),
    logical(1L)))
  if (length(found) != 1L) stop("Expected one output table for ", pattern, call. = FALSE)
  html_tables[found]
}

table_rows <- function(table) {
  rows <- regmatches(table, gregexpr("(?is)<tr[^>]*>.*?</tr>", table, perl = TRUE))[[1L]]
  lapply(rows, function(row) {
    cells <- regmatches(row, gregexpr(
      "(?is)<t[dh][^>]*>.*?</t[dh]>", row, perl = TRUE
    ))[[1L]]
    vapply(cells, html_text, character(1L))
  })
}

numeric_cell <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  if (!nzchar(x) || x %in% c("-", "–", "—")) return(NA_real_)
  suppressWarnings(as.numeric(x))
}

parse_age_table <- function(table) {
  rows <- table_rows(table)
  if (length(rows) < 3L) stop("The fitted age table is incomplete.", call. = FALSE)
  header <- rows[[1L]]
  if (!identical(unname(header[-1L]), age_labels)) {
    stop("The official age table has an unexpected age grid.", call. = FALSE)
  }
  selected <- lapply(rows[-1L], function(row) {
    if (length(row) != n_ages + 1L ||
        !grepl("^(19|20)[0-9]{2}$", row[[1L]])) return(NULL)
    year <- as.integer(row[[1L]])
    values <- vapply(row[-1L], numeric_cell, numeric(1L))
    if (anyNA(values)) stop("A non-numeric age-table value was found.", call. = FALSE)
    c(year = year, values)
  })
  selected <- selected[!vapply(selected, is.null, logical(1L))]
  matrix_data <- do.call(rbind, selected)
  if (!identical(as.integer(matrix_data[, 1L]), 1963:2028)) {
    stop("The fitted output table must cover 1963-2028 before projection filtering.",
      call. = FALSE)
  }
  colnames(matrix_data) <- c("year", age_labels)
  matrix_data
}

n_table <- parse_age_table(
  table_for_caption("Abundance at age (1000s) for stock 1 in region 1")
)
f_table <- parse_age_table(
  table_for_caption("Total fishing mortality at age in Trawl")
)
n_at_age <- n_table[seq_along(years), -1L, drop = FALSE]
f_at_age <- f_table[seq_along(years), -1L, drop = FALSE]

input_fields <- names(read_table(file.path(database, "inputs.csv")))
output_fields <- names(read_table(file.path(database, "outputs.csv")))
assumption_fields <- names(read_table(file.path(database, "assumptions.csv")))
input_rows <- list()
assumption_rows <- list()
output_rows <- list()
add_input <- function(...) {
  input_rows[[length(input_rows) + 1L]] <<- blank_row(input_fields, list(...))
}
add_assumption <- function(...) {
  assumption_rows[[length(assumption_rows) + 1L]] <<- blank_row(
    assumption_fields, list(...)
  )
}
add_output <- function(...) {
  output_rows[[length(output_rows) + 1L]] <<- blank_row(output_fields, list(...))
}

native_input_ref <- paste0(input_name, ", ")
machine_output_ref <- paste0(output_file, ", ")
for (age in ages) {
  age_label <- age_labels[age]
  add_input(assessment_id = assessment_id, type = "M",
    measure = "natural_mortality_at_age", basis = "per_year", age = age,
    value = natural_mortality[1L, age], unit = "yr-1",
    source_type = "native_model",
    source_reference = paste0(native_input_ref, "Natural Mortality"),
    notes = paste("Fixed at 0.05 per year; the source matrix repeats this age",
      "schedule for all modeled years. Age", age_label, "is represented."))
  add_input(assessment_id = assessment_id, type = "maturity",
    measure = "maturity_at_age", basis = "proportion", age = age,
    value = maturity[1L, age], unit = "proportion",
    source_type = "native_model",
    source_reference = paste0(native_input_ref, "Maturity"),
    notes = paste("The source schedule is constant over 1963-2024. Age",
      age_label, "is represented."))
  add_input(assessment_id = assessment_id, type = "catch_weight",
    measure = "catch_weight_at_age", basis = "kg_per_fish", fleet = fleet,
    age = age, value = weight_matrices[[1L]][1L, age], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste0(native_input_ref, "Weight Matrix - 1; catch pointers"),
    notes = paste("ASAP weight pointer 1 is used for Trawl fleet catch. The",
      "source matrix is constant over time. Age", age_label, "is represented."))
  add_input(assessment_id = assessment_id, type = "weight",
    measure = "spawning_weight_at_age", basis = "kg_per_fish", age = age,
    value = weight_matrices[[2L]][1L, age], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste0(native_input_ref, "Weight Matrix - 2; SSB pointer"),
    notes = paste("ASAP weight pointer 2 is used for SSB. The source matrix is",
      "constant over time. Age", age_label, "is represented."))
  add_input(assessment_id = assessment_id, type = "weight",
    measure = "start_weight_at_age", basis = "kg_per_fish", age = age,
    value = weight_matrices[[3L]][1L, age], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste0(native_input_ref, "Weight Matrix - 3; January 1 biomass pointer"),
    notes = paste("ASAP weight pointer 3 is used for January 1 biomass. The source",
      "matrix is constant over time. Age", age_label, "is represented."))
}

catch_comp_years <- which(catch_neff > 0)
if (any(abs(rowSums(catch[catch_comp_years, 1:n_ages, drop = FALSE]) - 1) > 0.005)) {
  stop("Observed catch age compositions are not proportions summing to one.", call. = FALSE)
}
for (i in seq_len(n_years)) {
  year <- years[i]
  add_input(assessment_id = assessment_id, type = "catch",
    measure = "total_biomass", basis = "biomass", fleet = fleet,
    year = year, year_basis = "calendar_year", value = catch[i, n_ages + 1L],
    unit = "metric tons", source_type = "native_model",
    source_reference = paste0(native_input_ref, "Catch Data; final column of Fleet-1 Catch Data"),
    notes = "The native annual catch total is retained separately from age-composition proportions.")
  add_input(assessment_id = assessment_id, type = "catch",
    measure = "relative_standard_error", basis = "relative_scale", fleet = fleet,
    year = year, year_basis = "calendar_year", value = catch_cv[i],
    unit = "ratio", source_type = "native_model",
    source_reference = paste0(native_input_ref, "Catch Total CV by Year and Fleet"),
    notes = "Native coefficient of variation for the aggregate catch likelihood.")
  if (catch_neff[i] > 0) for (age in ages) {
    add_input(assessment_id = assessment_id, type = "catch",
      measure = "proportion_at_age", basis = "proportion_numbers", fleet = fleet,
      year = year, year_basis = "calendar_year", age = age,
      value = catch[i, age], unit = "proportion", sample_size = catch_neff[i],
      source_type = "native_model",
      source_reference = paste0(native_input_ref, "Catch Data; Fleet-1 Catch Data"),
      notes = paste("Values retained without renormalization; source-supplied effective",
        "sample size is stored on each composition cell; raw fish counts are not supplied.",
        "Age", age_labels[age], "is represented."))
  }
}

for (i in seq_along(indices)) {
  survey <- surveys[i]
  index <- indices[[i]]
  observed <- index$index != -1
  season <- if (i == 1L) "fall" else "spring"
  for (j in seq_len(n_years)) {
    year <- years[j]
    value <- if (observed[j]) index$index[j] else NA_real_
    cv <- if (observed[j]) index$cv[j] else NA_real_
    timing_note <- paste0("Native index month ", index_month[i],
      "; sampling time calculated as (month - 1) / 12.")
    add_input(assessment_id = assessment_id, type = "index",
      measure = "total_numbers", basis = "index_scale", survey = survey,
      season = season, year = year, year_basis = "calendar_year", value = value,
      unit = "native number-index units (ASAP code 2; multiplier unspecified)",
      sampling_time = index$sampling_time, source_type = "native_model",
      source_reference = paste0(native_input_ref, "Survey Index Data; Index-", i, " Data"),
      transformation = if (observed[j]) "" else "Native index sentinel -1 converted to missing.",
      notes = paste("ASAP aggregate index unit code 2 denotes numbers. The input",
        "does not give a physical multiplier, so native values are unchanged.", timing_note))
    add_input(assessment_id = assessment_id, type = "index",
      measure = "abundance_index_cv", basis = "relative_scale", survey = survey,
      season = season, year = year, year_basis = "calendar_year", value = cv,
      unit = "ratio", sampling_time = index$sampling_time, source_type = "native_model",
      source_reference = paste0(native_input_ref, "Survey Index Data; Index-", i, " Data"),
      notes = "Native CV for the aggregate number index; blank when the source index is -1.")
    if (use_index_composition[i] == 1L && index$neff[j] > 0) {
      if (abs(sum(index$composition[j, ]) - 1) > 0.005) {
        stop("Observed age compositions do not sum to one for ", survey, " in ", year, ".",
          call. = FALSE)
      }
      for (age in ages) add_input(
        assessment_id = assessment_id, type = "index",
        measure = "proportion_at_age", basis = "proportion_numbers",
        survey = survey, season = season, year = year,
        year_basis = "calendar_year", age = age,
        value = index$composition[j, age], unit = "proportion",
        sample_size = index$neff[j],
        sampling_time = index$sampling_time, source_type = "native_model",
        source_reference = paste0(native_input_ref, "Survey Index Data; Index-", i, " Data"),
        notes = paste("Values retained without renormalization; source-supplied effective",
          "sample size is stored on each composition cell; raw fish counts are not supplied.",
          "Age", age_labels[age], "is represented.")
      )
    }
  }
}

input_data <- rows_from(input_fields, input_rows)
assumption_values <- list(
  list(component = "assessment", setting = "official_run", value = "Run 5"),
  list(component = "assessment", setting = "official_assessment_id", value = "NOAA Stock SMART 14070"),
  list(component = "population", setting = "modeled_years", value = "1963-2024"),
  list(component = "population", setting = "age_grid", value = "Ages 1-25 and 26+"),
  list(component = "catch", setting = "fleet", value = "One commercial trawl fleet"),
  list(component = "catch", setting = "age_composition_likelihood", value = "Logistic-normal AR(1); zeros treated as missing"),
  list(component = "catch", setting = "catch_likelihood_weight", value = lambda_catch),
  list(component = "catch", setting = "discard_likelihood_weight", value = lambda_discard),
  list(component = "index", setting = "aggregate_index_unit_code", value = "2 = numbers"),
  list(component = "index", setting = "physical_index_multiplier", value = "unknown"),
  list(component = "index", setting = "age_composition_unit_code", value = "2 = number proportions"),
  list(component = "index", setting = "index_names", value = "Fall; Spring"),
  list(component = "index", setting = "index_months", value = "Fall 10.5; Spring 4.5"),
  list(component = "index", setting = "sampling_time_conversion", value = "(index_month - 1) / 12"),
  list(component = "index", setting = "index_selectivity_link", value = "Not linked to fleet selectivity"),
  list(component = "index", setting = "index_weight_pointers", value = "Weight Matrix 3 for both surveys"),
  list(component = "mortality", setting = "natural_mortality", value = "Fixed M = 0.05 per year at all ages"),
  list(component = "biology", setting = "maturity", value = "Age-specific; constant across years"),
  list(component = "biology", setting = "weight_pointers", value = "Catch pointer 1; SSB pointer 2; January 1 biomass pointer 3"),
  list(component = "biology", setting = "spawning_fraction_of_year", value = spawning_fraction),
  list(component = "population", setting = "recruitment_model", value = "Random effects around a constant mean; AR(1) in year"),
  list(component = "population", setting = "initial_abundance", value = "Equilibrium initial age structure"),
  list(component = "model", setting = "fleet_selectivity", value = "Age-specific selectivity in one time-invariant block"),
  list(component = "model", setting = "fitted_output_years", value = "1963-2024; table also includes 2025-2028 projections")
)
for (setting in assumption_values) add_assumption(
  assessment_id = assessment_id, component = setting$component,
  fleet = if (setting$component == "catch") fleet else "",
  survey = if (setting$component == "index") "NEFSC fall and spring surveys" else "",
  setting = setting$setting, value = setting$value,
  source_reference = if (setting$component %in% c("assessment", "model", "population")) {
    paste0(code_name, "; ", input_name)
  } else input_name,
  notes = if (setting$setting == "physical_index_multiplier") {
    "The input identifies number units (code 2), but does not state a physical scale multiplier; no conversion is applied."
  } else if (setting$setting == "sampling_time_conversion") {
    "The original month values are also preserved in the input and assumptions."
  } else ""
)
assumptions <- rows_from(assumption_fields, assumption_rows)

output_fields <- names(read_table(file.path(database, "outputs.csv")))
output_rows <- list()
add_output <- function(...) {
  output_rows[[length(output_rows) + 1L]] <<- blank_row(output_fields, list(...))
}
machine_output_ref <- paste0(output_file, ", ")
for (i in seq_len(n_years)) {
  year <- years[i]
  add_output(assessment_id = assessment_id, type = "population",
    measure = "numbers_at_age", year = year, age = ages,
    value = n_at_age[i, ], unit = "thousand fish",
    source_type = "official_machine_readable",
    source_reference = paste0(machine_output_ref, "Abundance at age table"),
    notes = "Fitted historical point estimate; age 26 is the 26+ group. No age-year uncertainty is tabulated.")
  add_output(assessment_id = assessment_id, type = "mortality",
    measure = "fishing_mortality_at_age", fleet = fleet,
    year = year, age = ages, value = f_at_age[i, ], unit = "yr-1",
    source_type = "official_machine_readable",
    source_reference = paste0(machine_output_ref, "Fishing mortality at age by fleet table"),
    notes = "Fitted historical point estimate; age 26 is the 26+ group. No age-year uncertainty is tabulated.")
  add_output(assessment_id = assessment_id, type = "population",
    measure = "total_numbers", year = year, value = sum(n_at_age[i, ]),
    unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(machine_output_ref, "Abundance at age table; sum of ages 1-25 and 26+"),
    notes = "Derived by summing the reported N-at-age point estimates. No uncertainty is calculated.")
  add_output(assessment_id = assessment_id, type = "recruitment",
    measure = "recruitment", year = year, age = 1L, value = n_at_age[i, 1L],
    unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(machine_output_ref, "Abundance at age table; age 1"),
    notes = "Recruitment is represented by age-1 abundance in the fitted model. No uncertainty is calculated.")
  ssb <- sum(n_at_age[i, ] * weight_matrices[[2L]][1L, ] *
    maturity[1L, ] * exp(-(f_at_age[i, ] + natural_mortality[i, ]) * spawning_fraction))
  add_output(assessment_id = assessment_id, type = "biomass",
    measure = "SSB", year = year, value = ssb, unit = "metric tons",
    source_type = "derived_source_output",
    source_reference = paste0(machine_output_ref, "N-at-age and F-at-age tables; ",
      input_name, " Maturity, Natural Mortality, Weight Matrix - 2, and spawning fraction"),
    notes = paste("Derived at", spawning_fraction, "of the year as sum of January 1 N-at-age times",
      "spawning weight, maturity, and exp[-(F + M) * spawning_fraction]. Uses rounded table",
      "values and has no calculated uncertainty."))
}

parameter_table <- table_for_caption(
  "Parameter estimates, standard errors, and confidence intervals."
)
parameter_rows <- table_rows(parameter_table)
parameter_estimate <- function(label) {
  selected <- Filter(function(row) length(row) == 5L && row[[1L]] == label,
    parameter_rows)
  if (length(selected) != 1L) stop("Missing unique fitted parameter: ", label, call. = FALSE)
  values <- vapply(selected[[1L]][-1L], numeric_cell, numeric(1L))
  if (anyNA(values)) stop("The fitted parameter table has unavailable values for ", label, call. = FALSE)
  values
}
parameters <- list(
  list(label = "Fall fully selected q", type = "catchability", measure = "q",
    survey = surveys[1L], values = parameter_estimate("Fall fully selected q"),
    unit = "native number-index units per thousand fish"),
  list(label = "Spring fully selected q", type = "catchability", measure = "q",
    survey = surveys[2L], values = parameter_estimate("Spring fully selected q"),
    unit = "native number-index units per thousand fish"),
  list(label = "stock 1 Mean Recruitment", type = "recruitment",
    measure = "mean_recruitment", survey = "", age = 1L,
    values = parameter_estimate("stock 1 Mean Recruitment"), unit = "thousand fish"),
  list(label = "stock 1 Recruitment AR1 rho year", type = "biology",
    measure = "recruitment_ar1_rho", survey = "",
    values = parameter_estimate("stock 1 Recruitment AR1 \\rho year"),
    unit = "correlation coefficient")
)
for (p in parameters) add_output(
  assessment_id = assessment_id, type = p$type, measure = p$measure,
  survey = p$survey, age = if (is.null(p$age)) "" else p$age,
  value = p$values[1L], se = p$values[2L],
  lwr = p$values[3L], upr = p$values[4L], unit = p$unit,
  source_type = "official_machine_readable",
  source_reference = paste0(machine_output_ref, "Parameter estimates table; ", p$label),
  notes = if (p$measure == "q") {
    "Run 5 estimate with reported SE and 95% confidence interval. Q retains the source index scale."
  } else if (p$measure == "mean_recruitment") {
    "Mean recruitment to age 1 with reported SE and 95% confidence interval."
  } else {
    "Recruitment AR(1) correlation estimate with reported SE and 95% confidence interval."
  }
)
outputs <- rows_from(output_fields, output_rows)

stock <- blank_row(names(read_table(file.path(database, "stocks.csv"))), list(
  stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NEFSC", authority_stock_id = "10455",
  scientific_name = "Sebastes fasciatus",
  common_name = "Acadian redfish - Gulf of Maine / Georges Bank",
  area = "Gulf of Maine / Georges Bank", region = "Gulf of Maine / Georges Bank",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART stock 10455. Distinct from DFO and NAFO redfish units; shared species name does not establish the same assessment boundary."
))
assessment <- blank_row(names(read_table(file.path(database, "assessments.csv"))), list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2028L,
  assessment_type = "Management Track", model_family = "WHAM",
  model_version = "WHAM 2.1.0.9002; commit 47506172e9a55376137501608e645ddae8a574e9",
  is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = source_manifest$url[source_manifest$file == report_name],
  framework_url = "",
  data_url = source_manifest$url[source_manifest$file == input_name],
  model_url = source_manifest$url[source_manifest$file == code_name],
  repository_url = "",
  assumptions_status = "partial", inputs_status = "complete", outputs_status = "partial",
  notes = paste("Run 5 of the 2025 Management Track assessment; the September 2025 peer-review panel found it met the terms of reference and represented best scientific information available.",
    "Input years are 1963-2024; output tables also contain 2025-2028 projections, which are excluded.",
    "Aggregate survey unit code 2 denotes numbers, but its physical multiplier is unspecified.",
    "Annual N-at-age/F-at-age values are point estimates without age-year uncertainty; total abundance, recruitment, and SSB are labeled derived outputs.")
))

candidate_data <- read_table(candidate_path)
candidate_row <- which(candidate_data$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    any(candidate_data$candidate_unit_id[-candidate_row] == stock_id, na.rm = TRUE)) {
  stop("The NOAA candidate row is missing, duplicated, or conflicts with another unit.", call. = FALSE)
}
stocks <- read_table(file.path(database, "stocks.csv"))
assessments <- read_table(file.path(database, "assessments.csv"))
inputs_existing <- read_table(file.path(database, "inputs.csv"))
outputs_existing <- read_table(file.path(database, "outputs.csv"))
if (!dry_run && (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id) ||
    any(inputs_existing$assessment_id == assessment_id) ||
    any(outputs_existing$assessment_id == assessment_id))) {
  stop("NOAA Acadian redfish source records already exist; review before importing.", call. = FALSE)
}
if (!dry_run && (candidate_data$eligibility[candidate_row] != "eligible" ||
    candidate_data$import_status[candidate_row] != "not_started")) {
  stop("The selected NOAA candidate is not ready for this first source import.", call. = FALSE)
}
inventory <- read_table(inventory_path)
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
selected <- read_table(selected_path)
selected_row <- which(selected$candidate_unit_id == stock_id)
if (length(inventory_row) != 1L || length(selected_row) != 1L) {
  stop("The selected candidate is missing from the inventory or batch register.", call. = FALSE)
}

replace_csv_row <- function(path, key_column, key_value, row_index, row) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  if (record_index < 2L || record_index > length(bounds$start)) {
    stop("CSV row index is out of range for ", basename(path), call. = FALSE)
  }
  current <- read_table(path)
  if (row_index > nrow(current) ||
      as.character(current[[key_column]][row_index]) != key_value) {
    stop("CSV row identity differs in ", basename(path), call. = FALSE)
  }
  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, what = "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  next_byte <- last + 1L
  has_cr <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_cr <- TRUE
    next_byte <- next_byte + 1L
  }
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, if (has_cr) as.raw(c(13L, 10L)) else as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, replacement, after), path)
  updated <- read_table(path)
  if (nrow(updated) != length(bounds$start) - 1L ||
      sum(as.character(updated[[key_column]]) == key_value, na.rm = TRUE) != 1L ||
      as.character(updated[[key_column]][row_index]) != key_value) {
    stop("Updated CSV failed identity and row-count checks: ", basename(path), call. = FALSE)
  }
  invisible(NULL)
}

if (!dry_run) {
  append_rows(file.path(database, "stocks.csv"), stock)
  append_rows(file.path(database, "assessments.csv"), assessment)
  append_rows(file.path(database, "assumptions.csv"), assumptions)
  append_rows(file.path(database, "inputs.csv"), input_data)
  append_rows(file.path(database, "outputs.csv"), outputs)

  candidate_data$match_status[candidate_row] <- "new"
  candidate_data$screening_status[candidate_row] <- "screened"
  candidate_data$eligibility[candidate_row] <- "eligible"
  candidate_data$import_status[candidate_row] <- "partial"
  candidate_data$catch_age_evidence[candidate_row] <- paste(
    "The official 2025 Run 5 WHAM input contains annual catch totals and age",
    "proportions for ages 1-25 and 26+ over 1963-2024. Effective sample sizes",
    "are preserved; years with zero effective N have no observed composition.")
  candidate_data$survey_age_evidence[candidate_row] <- paste(
    "The model includes Fall and Spring NEFSC number indices and age proportions.",
    "The ASAP unit code is 2 (numbers), but the physical multiplier is unspecified;",
    "native values and age-composition effective sample sizes are preserved.")
  candidate_data$weights_evidence[candidate_row] <- paste(
    "Three age-weight matrices are imported in their source roles: catch, SSB,",
    "and January 1 biomass. The schedules are constant over 1963-2024.")
  candidate_data$maturity_evidence[candidate_row] <- paste(
    "The official input provides an age-specific maturity schedule for ages",
    "1-25 and 26+, repeated over 1963-2024.")
  candidate_data$mortality_evidence[candidate_row] <- paste(
    "Natural mortality is fixed at 0.05 per year for every modeled age and year;",
    "no estimated M output is available.")
  candidate_data$timing_evidence[candidate_row] <- paste(
    "Native survey months are Fall 10.5 and Spring 4.5. Sampling times are",
    "calculated as (month - 1) / 12; original month values are retained.")
  candidate_data$output_evidence[candidate_row] <- paste(
    "Run 5 tables provide N-at-age and fleet F-at-age for 1963-2024 plus",
    "2025-2028 projections; only historical values are imported. Total abundance,",
    "age-1 recruitment, and SSB are labeled derived outputs. N/F surfaces have no",
    "age-year uncertainty in the machine-readable table.")
  candidate_data$review_date[candidate_row] <- "2026-11-03"
  candidate_data$decision_reason[candidate_row] <- paste(
    "The 2025 Management Track assessment (Stock SMART 14070) met the terms of",
    "reference and represented best scientific information available according to",
    "the September 2025 peer-review panel. Run 5 native inputs and output tables",
    "support source curation for the current Gulf of Maine / Georges Bank unit.",
    "The survey index physical multiplier and age-year uncertainty remain unavailable.")
  candidate_data$notes[candidate_row] <- paste(
    "Sources and provenance are cached under the gitignored",
    "discovery_noaa_acadian_redfish_2025 directory. Native WHAM inputs are complete;",
    "assumptions and outputs remain partial because the physical index multiplier",
    "and age-year uncertainty are not available. Derived abundance and SSB have",
    "no uncertainty. ")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidate_data[candidate_row, , drop = FALSE], candidate_id)

  inventory$import_status[inventory_row] <- "partial"
  replace_csv_row(inventory_path, "unit_key", inventory$unit_key[inventory_row],
    inventory_row, inventory[inventory_row, , drop = FALSE])

  selected$curation_status[selected_row] <- "partial_source_import"
  replace_csv_row(selected_path, "candidate_unit_id", stock_id, selected_row,
    selected[selected_row, , drop = FALSE])
}

cat(if (dry_run) "Dry run parsed " else "Imported ",
  nrow(input_data), " input rows, ", nrow(assumptions), " assumptions, and ",
  nrow(outputs), " output rows for NOAA Acadian redfish.\n", sep = "")
