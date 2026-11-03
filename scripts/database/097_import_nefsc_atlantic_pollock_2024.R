root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "nefsc_pollock_5yz_2024")
stock_id <- "ck_nefsc_virens_5yz"
assessment_id <- "nefsc_pollock_5yz_2024"
input_file <- file.path(cache, "2024_POK_UNIT_MOD_BaseASAPInput.dat")
output_file <- file.path(cache, "2024_POK_UNIT_MOD_BaseASAPOutput.rep")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
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

number_tokens <- function(line) {
  tokens <- strsplit(trimws(line), "[[:space:],]+")[[1L]]
  { values <- suppressWarnings(as.numeric(tokens)); values[!is.na(values)] }
}

input_section <- function(lines, label, columns = NULL, rows = NULL) {
  trimmed <- trimws(lines)
  start <- which(trimmed == paste0("# ", label))
  if (length(start) != 1L) stop("Expected one input section: ", label, call. = FALSE)
  next_comment <- which(seq_along(lines) > start & grepl("^#", trimmed))
  end <- if (length(next_comment)) min(next_comment) - 1L else length(lines)
  candidates <- lines[seq.int(start + 1L, end)]
  parsed <- lapply(candidates, number_tokens)
  parsed <- parsed[lengths(parsed) > 0L]
  if (!is.null(columns)) parsed <- parsed[lengths(parsed) == columns]
  if (!is.null(rows) && length(parsed) != rows) {
    stop(label, " has ", length(parsed), " numeric rows; expected ", rows, ".", call. = FALSE)
  }
  values <- unlist(parsed, use.names = FALSE)
  if (!is.null(columns)) return(matrix(values, ncol = columns, byrow = TRUE))
  values
}

output_block <- function(lines, title, rows, columns) {
  start <- grep(paste0("^", title, "$"), trimws(lines))
  if (length(start) != 1L) stop("Expected one output block: ", title, call. = FALSE)
  candidates <- lines[seq.int(start + 1L, length(lines))]
  parsed <- lapply(candidates, number_tokens)
  parsed <- parsed[lengths(parsed) == columns]
  if (length(parsed) < rows) {
    stop(title, " has ", length(parsed), " numeric rows; expected ", rows, ".", call. = FALSE)
  }
  matrix(unlist(parsed[seq_len(rows)], use.names = FALSE), ncol = columns, byrow = TRUE)
}

add_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n", fileEncoding = "UTF-8")
}

if (!all(file.exists(c(input_file, output_file)))) {
  stop("Pollock source-cache files are missing; see the local source manifest.", call. = FALSE)
}

input_lines <- readLines(input_file, warn = FALSE)
output_lines <- readLines(output_file, warn = FALSE)
n_years <- input_section(input_lines, "Number of Years")[[1L]]
year1 <- input_section(input_lines, "First Year")[[1L]]
n_ages <- input_section(input_lines, "Number of Ages")[[1L]]
years <- seq.int(year1, length.out = n_years)
ages <- seq_len(n_ages)
if (!identical(years, 1970:2023) || !identical(ages, 1:9)) {
  stop("Unexpected year or age grid in the official ASAP input.", call. = FALSE)
}

M <- input_section(input_lines, "Natural Mortality", n_ages, n_years)
maturity <- input_section(input_lines, "Maturity", n_ages, n_years)
weight_matrices <- lapply(1:3, function(i) {
  input_section(input_lines, paste("Weight Matrix -", i), n_ages, n_years)
})
weight_pointers <- input_section(input_lines, "Weights at Age Pointers")
if (!identical(as.integer(weight_pointers), c(1L, 1L, 1L, 1L, 2L, 3L))) {
  stop("Unexpected ASAP catch, spawning, or start-weight pointers.", call. = FALSE)
}
index_weight_pointers <- as.integer(input_section(input_lines, "Weight at Age Matrix"))
if (length(index_weight_pointers) != 5L || any(index_weight_pointers != 3L)) {
  stop("Unexpected survey weight-at-age pointers.", call. = FALSE)
}
catch <- input_section(input_lines, "Fleet-1 Catch Data", n_ages + 1L, n_years)
discard <- input_section(input_lines, "Fleet-1 Discards Data", n_ages + 1L, n_years)
catch_cv <- input_section(input_lines, "Catch Total CV by Year and Fleet", 1L, n_years)[, 1L]
discard_cv <- input_section(input_lines, "Discard Total CV by Year and Fleet", 1L, n_years)[, 1L]
catch_ess <- input_section(input_lines, "Catch Effective Sample Size by Year and Fleet", 1L, n_years)[, 1L]
discard_ess <- input_section(input_lines, "Discard Effective Sample Size by Year and Fleet", 1L, n_years)[, 1L]
selectivity_blocks <- as.integer(input_section(input_lines, "Fleet 1 Selectivity Block Assignment", 1L, n_years)[, 1L])
block_runs <- rle(selectivity_blocks)
block_ends <- cumsum(block_runs$lengths)
block_starts <- block_ends - block_runs$lengths + 1L
block_year_labels <- ifelse(
  block_starts == block_ends,
  as.character(years[block_starts]),
  paste0(years[block_starts], "-", years[block_ends])
)
selectivity_assignment <- paste0(
  "block ", block_runs$values, " (", block_year_labels, ")"
)
index_names <- c("NEFSC Albatross spring trawl survey",
  "NEFSC Bigelow spring trawl survey", "NEFSC summer trawl survey",
  "NEFSC Albatross fall trawl survey", "NEFSC Bigelow fall trawl survey")
index_seasons <- c("spring", "spring", "summer", "fall", "fall")
index_month <- as.numeric(input_section(input_lines, "Index Month"))
index_active <- as.integer(input_section(input_lines, "Use Index (Yes=1)"))
index_acomp_active <- as.integer(input_section(input_lines, "Estimate Proportion (Yes=1)"))
index_units <- as.integer(input_section(input_lines, "Aggregate Index Units"))
index_acomp_units <- as.integer(input_section(input_lines, "Age Proportion Index Units"))
index_age_start <- as.integer(input_section(input_lines, "Index Start Age"))
index_age_end <- as.integer(input_section(input_lines, "Index End Age"))
if (!identical(index_active, c(1L, 1L, 0L, 1L, 1L)) ||
  !identical(index_acomp_active, c(1L, 1L, 0L, 1L, 1L)) ||
  !all(index_units == 2L) || !all(index_acomp_units == 2L) ||
  !all(index_age_start == 1L) || !all(index_age_end == 9L)) {
  stop("Unexpected ASAP survey activation, units, or age range.", call. = FALSE)
}
index_data <- lapply(1:5, function(i) {
  input_section(input_lines, paste0("Index-", i, " Data"), n_ages + 4L, n_years)
})

F_directed <- output_block(output_lines,
  "fleet 1 directed F at age", n_years, n_ages)
F_discard <- output_block(output_lines,
  "fleet 1 Discard F at age", n_years, n_ages)
N <- output_block(output_lines,
  "Population Numbers at the Start of the Year", n_years, n_ages)
biomass <- output_block(output_lines,
  "Biomass Time Series", n_years, 4L)
Fbar <- output_block(output_lines,
  "Average F for ages 5 to 7", n_years, 4L)
if (!identical(as.integer(biomass[, 1L]), years) ||
  !identical(as.integer(Fbar[, 1L]), years)) {
  stop("Unexpected years in the official ASAP output.", call. = FALSE)
}
F <- F_directed + F_discard
if (abs(mean(F[years == 2023, 5:7]) - Fbar[years == 2023, 2L]) > 1e-7) {
  stop("Derived age 5-7 mean F does not match the official unweighted Fbar.", call. = FALSE)
}

stocks <- read_table(file.path(database, "stocks.csv"))
assessments <- read_table(file.path(database, "assessments.csv"))
inputs <- read_table(file.path(database, "inputs.csv"))
assumptions <- read_table(file.path(database, "assumptions.csv"))
outputs <- read_table(file.path(database, "outputs.csv"))
if (sum(stocks$stock_id == stock_id) != 1L) stop("Expected one pollock stock record.", call. = FALSE)
if (assessment_id %in% assessments$assessment_id ||
  assessment_id %in% inputs$assessment_id ||
  assessment_id %in% assumptions$assessment_id ||
  assessment_id %in% outputs$assessment_id) {
  if (dry_run) stop("Pollock assessment rows already exist; inspect before dry run.", call. = FALSE)
  stop("Pollock assessment is already imported; inspect existing rows before importing.", call. = FALSE)
}
input_fields <- names(inputs)
output_fields <- names(outputs)
assumption_fields <- names(assumptions)
new_inputs <- list()
add_input <- function(...) {
  new_inputs[[length(new_inputs) + 1L]] <<- blank_row(input_fields, list(...))
}
new_outputs <- list()
add_output <- function(...) {
  new_outputs[[length(new_outputs) + 1L]] <<- blank_row(output_fields, list(...))
}

input_ref <- "2024_POK_UNIT_MOD_BaseASAPInput.dat"
output_ref <- "2024_POK_UNIT_MOD_BaseASAPOutput.rep"
for (age in ages) {
  add_input(assessment_id = assessment_id, type = "M",
    measure = "natural_mortality_at_age", basis = "per_year", age = age,
    value = M[1L, age], unit = "yr-1", source_type = "native_model",
    source_reference = paste(input_ref, "Natural Mortality"),
    notes = "Fixed natural mortality; the same 0.20 yr-1 value is present for every year in the official model matrix.")
  add_input(assessment_id = assessment_id, type = "maturity",
    measure = "maturity_at_age", basis = "proportion", age = age,
    value = maturity[1L, age], unit = "proportion", source_type = "native_model",
    source_reference = paste(input_ref, "Maturity"),
    notes = "Time-invariant age-specific maturity; the same vector is repeated in every modeled year.")
}

for (i in seq_along(years)) {
  year <- years[i]
  for (age in ages) {
    add_input(assessment_id = assessment_id, type = "catch",
      measure = "landings_numbers_at_age", basis = "numbers", fleet = "combined",
      year = year, year_basis = "calendar_year", age = age,
      value = catch[i, age], unit = "thousand fish", partition = "landings",
      sample_size = catch_ess[i], source_type = "native_model",
      source_reference = paste(input_ref, "Fleet-1 Catch Data"),
      notes = "ASAP catch-at-age values are in thousands of fish; the supplied annual effective sample size controls the composition likelihood.")
    if (discard[i, n_ages + 1L] > 0) {
      add_input(assessment_id = assessment_id, type = "catch",
        measure = "discard_numbers_at_age", basis = "numbers", fleet = "combined",
        year = year, year_basis = "calendar_year", age = age,
        value = discard[i, age], unit = "thousand fish", partition = "dead_discards",
        sample_size = discard_ess[i], source_type = "native_model",
        source_reference = paste(input_ref, "Fleet-1 Discards Data"),
        notes = "ASAP dead-discard-at-age values are in thousands of fish; the supplied annual effective sample size controls the composition likelihood.")
    }
  }
  add_input(assessment_id = assessment_id, type = "catch",
    measure = "total_biomass", basis = "biomass", fleet = "combined",
    year = year, year_basis = "calendar_year", value = catch[i, n_ages + 1L],
    unit = "metric tons", partition = "landings", source_type = "native_model",
    source_reference = paste(input_ref, "Fleet-1 Catch Data"),
    notes = "Annual observed catch biomass used with a 0.05 coefficient of variation in the ASAP likelihood.")
  add_input(assessment_id = assessment_id, type = "catch",
    measure = "relative_standard_error", basis = "relative_scale",
    fleet = "combined", year = year, year_basis = "calendar_year",
    value = catch_cv[i], unit = "coefficient of variation", partition = "landings",
    source_type = "native_model",
    source_reference = paste(input_ref, "Catch Total CV by Year and Fleet"),
    notes = "Model-specified CV for the total-catch observation likelihood; not an empirical sampling standard error.")
  if (discard[i, n_ages + 1L] > 0) {
    add_input(assessment_id = assessment_id, type = "catch",
      measure = "total_biomass", basis = "biomass", fleet = "combined",
      year = year, year_basis = "calendar_year", value = discard[i, n_ages + 1L],
      unit = "metric tons", partition = "dead_discards", source_type = "native_model",
      source_reference = paste(input_ref, "Fleet-1 Discards Data"),
      notes = "Annual observed dead-discard biomass; zero years are omitted. The source models this total separately from catch biomass.")
    add_input(assessment_id = assessment_id, type = "catch",
    measure = "relative_standard_error", basis = "relative_scale",
    fleet = "combined", year = year, year_basis = "calendar_year",
      value = discard_cv[i], unit = "coefficient of variation", partition = "dead_discards",
      source_type = "native_model",
      source_reference = paste(input_ref, "Discard Total CV by Year and Fleet"),
      notes = "Model-specified CV for the total dead-discard likelihood; not an empirical sampling standard error.")
  }
}

for (i in seq_len(n_years)) for (age in ages) {
  add_input(assessment_id = assessment_id, type = "catch_weight",
    measure = "weight_at_age", basis = "kg_per_fish", fleet = "combined",
    year = years[i], year_basis = "calendar_year", age = age,
    value = weight_matrices[[1L]][i, age], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste(input_ref, "Weight Matrix - 1; Weights at Age Pointers"),
    notes = "Catch and discard weight matrix; ASAP pointers for the combined fleet use matrix 1 for both streams.")
  add_input(assessment_id = assessment_id, type = "weight",
    measure = "weight_at_age", basis = "kg_per_fish",
    year = years[i], year_basis = "calendar_year", age = age,
    value = weight_matrices[[2L]][i, age], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste(input_ref, "Weight Matrix - 2; Weights at Age Pointers"),
    notes = "SSB weight-at-age matrix; source pointer 5 is used for the spawning biomass calculation.")
  add_input(assessment_id = assessment_id, type = "weight",
    measure = "start_weight_at_age", basis = "kg_per_fish",
    year = years[i], year_basis = "calendar_year", age = age,
    value = weight_matrices[[3L]][i, age], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste(input_ref, "Weight Matrix - 3; Weights at Age Pointers"),
    notes = "January 1/start-of-year weight matrix; source pointer 6 uses this matrix for start biomass and all five survey pointers use it for index biomass-at-age.")
  for (survey in index_names) {
    add_input(assessment_id = assessment_id, type = "weight",
      measure = "weight_at_age", basis = "kg_per_fish", survey = survey,
      year = years[i], year_basis = "calendar_year", age = age,
      value = weight_matrices[[3L]][i, age], unit = "kg per fish",
      source_type = "native_model",
      source_reference = paste(input_ref, "Weight Matrix - 3; Weight at Age Matrix"),
      notes = "Survey-specific assignment of shared matrix 3; all survey weight pointers are 3, including inactive Index 3.")
  }
}

for (index in seq_along(index_names)) {
  data <- index_data[[index]]
  valid <- data[, 2L] > 0
  if (!index_active[index]) next
  if (!index_acomp_active[index] || any(data[valid, n_ages + 4L] <= 0)) {
    stop("Active index has an unexpected composition setting or missing ESS.", call. = FALSE)
  }
  for (i in which(valid)) {
    year <- as.integer(data[i, 1L])
    sampling_time <- (index_month[index] - 1) / 12
    for (age in ages) {
      add_input(assessment_id = assessment_id, type = "index",
        measure = "biomass_at_age", basis = "index_scale",
        survey = index_names[index], region = "5YZ", season = index_seasons[index],
        year = year, year_basis = "calendar_year", age = age,
        value = data[i, age + 3L], unit = "kg per tow", sampling_time = sampling_time,
        sample_size = data[i, n_ages + 4L], source_type = "native_model",
        source_reference = paste(input_ref, paste0("Index-", index, " Data")),
        notes = paste0("Native age-specific biomass index values; ASAP normalizes this vector to age proportions for the composition likelihood. Aggregate index CV is stored separately. Source index name: $", c("Alb spring", "Big spring", "summer", "Alb fall", "Big fall")[index], "."))
    }
    add_input(assessment_id = assessment_id, type = "index",
      measure = "relative_biomass_index", basis = "index_scale",
      survey = index_names[index], region = "5YZ", season = index_seasons[index],
      year = year, year_basis = "calendar_year", value = data[i, 2L],
      unit = "kg per tow", sampling_time = sampling_time,
      source_type = "native_model",
      source_reference = paste(input_ref, paste0("Index-", index, " Data")),
      notes = paste0("Aggregate relative biomass index. The source estimates index-specific catchability; age range is 1-9+ and composition ESS is stored on age rows. Source index name: $", c("Alb spring", "Big spring", "summer", "Alb fall", "Big fall")[index], "."))
    add_input(assessment_id = assessment_id, type = "index",
      measure = "relative_standard_error", basis = "relative_scale",
      survey = index_names[index], region = "5YZ", season = index_seasons[index],
      year = year, year_basis = "calendar_year", value = data[i, 3L],
      unit = "coefficient of variation", sampling_time = sampling_time,
      source_type = "native_model",
      source_reference = paste(input_ref, paste0("Index-", index, " Data")),
      notes = "Model-specified CV for the aggregate biomass index; not an empirical sampling standard error.")
  }
}

new_assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024, terminal_year = 2023, estimate_terminal_year = 2023,
  assessment_type = "assessment_update", model_family = "ASAP",
  model_version = "ASAP 3.0 Run10 BaseASAP",
  is_current = "TRUE", is_applied = "TRUE",
  assessment_url = "https://www.fisheries.noaa.gov/s3/2024-10/2024-Management-Track-Peer-Review-Panel-Report_10_8_24_508.pdf",
  data_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=7&stock_id=6&review_type_id=3&info_type_id=3&map_type_type_id=&map_type_id=&filename=2024_POK_UNIT_MOD_BaseASAPInput.dat",
  model_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=7&stock_id=6&review_type_id=3&info_type_id=3&map_type_type_id=&map_type_id=&filename=2024_POK_UNIT_MOD_BaseASAPOutput.rep",
  assumptions_status = "partial", inputs_status = "complete", outputs_status = "partial",
  notes = "Final 2024 management-track ASAP base model; the peer-review panel accepted this assessment as technically sufficient and best scientific information available. It updates the 2022 Management Track model with data through 2023. A detailed supporting working paper is marked draft and is used only for detail/cross-check. The 2026 SASI item is a projection update only and is not a later age-structured assessment. Inputs retain the full native annual data and fixed biology; some estimation controls remain summarized rather than transcribed. The official output file has point estimates but no full time-age uncertainty surfaces. See source_reviews/nefsc_atlantic_pollock_5yz.md."))

assumption_values <- list(
  list(component = "population", setting = "modeled_years", value = "1970-2023", source_reference = paste(input_ref, "Number of Years; First Year"), notes = "54 historical years; no projection years are included in the fit."),
  list(component = "population", setting = "modeled_ages", value = "ages 1-9+", source_reference = paste(input_ref, "Number of Ages"), notes = "Nine age groups; age 9 is the terminal plus group."),
  list(component = "population", setting = "sex", value = "sex-combined", source_reference = input_ref, notes = "One stock and one fleet; the native model has no separate sex dimension."),
  list(component = "catch", setting = "fleet", value = "one combined fleet ($combined)", source_reference = paste(input_ref, "Fleet Names"), notes = "Fishery-specific removals are pooled in the official model input."),
  list(component = "catch", setting = "landings_observation", value = "total catch biomass with lognormal CV plus catch numbers-at-age composition", source_reference = paste(input_ref, "Fleet-1 Catch Data; Catch Total CV by Year and Fleet; Catch Effective Sample Size by Year and Fleet"), notes = "Total catch CV is 0.05; annual composition effective sample size is 26."),
  list(component = "catch", setting = "discard_observation", value = "dead discard biomass with lognormal CV plus discard numbers-at-age composition", source_reference = paste(input_ref, "Fleet-1 Discards Data; Discard Total CV by Year and Fleet; Discard Effective Sample Size by Year and Fleet"), notes = "Dead discards are observed from 1981-2023; annual composition effective sample size is 14. Discard observations are modeled separately from catch."),
  list(component = "catch", setting = "catch_weight_at_age", value = "annual matrix 1, 1970-2023, ages 1-9+", source_reference = paste(input_ref, "Weight Matrix - 1; Weights at Age Pointers"), notes = "ASAP pointers assign matrix 1 to the combined-fleet catch and discard streams."),
  list(component = "F", setting = "selectivity_blocks", value = paste0("six age-specific blocks; ", paste(selectivity_assignment, collapse = "; ")), source_reference = paste(input_ref, "Selectivity Block Assignment; Selectivity Options for each block"), notes = "All six fishery blocks use age-specific selectivity. The tinyAM translation approximates these six blocks with age effects and documented time blocks."),
  list(component = "F", setting = "Fbar_definition", value = "unweighted arithmetic mean of ages 5-7", source_reference = paste(output_ref, "Average F for ages 5 to 7"), notes = "The derived total F-at-age adds directed F and discard F; its 2023 age-5:7 mean matches the reported unweighted Fbar."),
  list(component = "M", setting = "treatment", value = "fixed M = 0.20 yr-1 at ages 1-9+", source_reference = paste(input_ref, "Natural Mortality"), notes = "The native matrix repeats the same age vector for all 54 years; M is not estimated."),
  list(component = "biology", setting = "maturity", value = "fixed maturity at ages 1-9+", source_reference = paste(input_ref, "Maturity"), notes = "The same maturity vector is repeated for all years."),
  list(component = "biology", setting = "spawning_weight_at_age", value = "annual matrix 2, 1970-2023, ages 1-9+", source_reference = paste(input_ref, "Weight Matrix - 2; Weights at Age Pointers"), notes = "Pointer 5 assigns this matrix to the SSB calculation; spawning fraction is 0.0 (January 1)."),
  list(component = "biology", setting = "start_weight_at_age", value = "annual matrix 3, 1970-2023, ages 1-9+", source_reference = paste(input_ref, "Weight Matrix - 3; Weights at Age Pointers"), notes = "Pointer 6 assigns matrix 3 to start-of-year biomass; all survey weight pointers also equal 3."),
  list(component = "index", setting = "active_surveys", value = paste(index_names[index_active == 1L], collapse = "; "), source_reference = paste(input_ref, "Use Index (Yes=1)"), notes = "Indices 1, 2, 4 and 5 are active; Index 3 (summer trawl survey) is present in the input file but explicitly excluded."),
  list(component = "index", setting = "observation_model", value = "aggregate biomass index with CV and age-specific biomass index composition with ESS", source_reference = paste(input_ref, "Aggregate Index Units; Age Proportion Index Units; Index Data"), notes = "Aggregate units and age-composition units both use biomass (code 2); raw age-specific biomass index values are normalized by ASAP to compositions. Index CV and composition ESS are retained separately."),
  list(component = "index", setting = "survey_timing", value = "spring surveys in April (0.25); fall surveys in October (0.75)", source_reference = paste(input_ref, "Index Month"), notes = "Month is the native ASAP start-of-month code; within-year timing is represented as (month - 1) / 12."),
  list(component = "index", setting = "catchability", value = "survey-specific catchability with annual deviations", source_reference = paste(input_ref, "Phase for Catchability in 1st Year; Phase for Catchability Deviations; Lambda for Catchability Deviations by Index"), notes = "The official output reports index-specific q series; tinyAM keeps separate survey q effects but does not reproduce the exact ASAP q-deviation formulation."),
  list(component = "recruitment", setting = "recruitment_deviations", value = "annual recruitment deviations estimated", source_reference = paste(input_ref, "Phase for Recruitment Deviations; Lambda for Recruitment Deviations"), notes = "Recruitment is represented at age 1 in the official model output."),
  list(component = "model", setting = "source_fit", value = "2024 Management Track update to the 2022 ASAP assessment; base run with data through 2023", source_reference = "September 2024 Management Track Peer Review Panel Report, sections 1-2", notes = "The panel found the update technically sufficient and best scientific information available."),
  list(component = "model", setting = "later_sasi_item", value = "2026 data/projection update only", source_reference = "data_projection_update_pollock_20260817.pdf", notes = "Not treated as a later age-structured assessment or historical fit."),
  list(component = "model", setting = "uncertainty_output", value = "full time-age standard errors unavailable in native .rep", source_reference = output_ref, notes = "Point estimates are retained; no uncertainty values are fabricated."))
new_assumptions <- rows_from(assumption_fields,
  lapply(assumption_values, function(x) c(list(assessment_id = assessment_id), x)))

for (i in seq_along(years)) {
  year <- years[i]
  for (age in ages) {
    add_output(assessment_id = assessment_id, type = "population",
      measure = "numbers_at_age", year = year, age = age,
      age_group = if (age == max(ages)) "9+" else "", value = N[i, age],
      unit = "thousand fish at January 1", source_type = "native_model",
      source_reference = paste(output_ref, "Population Numbers at the Start of the Year"),
      notes = if (age == max(ages)) "Age 9 is the model's 9+ plus group." else "January 1 population number.")
    add_output(assessment_id = assessment_id, type = "mortality",
      measure = "fishing_mortality_at_age", year = year, age = age,
      age_group = if (age == max(ages)) "9+" else "", value = F[i, age],
      unit = "yr-1", source_type = "derived_source_output",
      source_reference = paste(output_ref, "Directed F by age; Discard F by age"),
      notes = "Derived as directed F plus discard F to represent total fishing mortality; directed and discard components are separately reported in the source file.")
  }
  add_output(assessment_id = assessment_id, type = "recruitment",
    measure = "recruitment", year = year, age = 1, value = N[i, 1L],
    unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste(output_ref, "Population Numbers at the Start of the Year"),
    notes = "Age-1 abundance is the official recruitment definition; retained as a derived duplicate of age-1 N for comparison." )
  add_output(assessment_id = assessment_id, type = "population",
    measure = "total_abundance", year = year, value = sum(N[i, ]),
    unit = "thousand fish at January 1", source_type = "derived_source_output",
    source_reference = paste(output_ref, "Population Numbers at the Start of the Year"),
    notes = "Derived as the sum of reported age-specific abundance for ages 1-9+; no uncertainty is available for this sum.")
  add_output(assessment_id = assessment_id, type = "biomass",
    measure = "january_1_biomass", year = year, value = biomass[i, 2L],
    unit = "metric tons", source_type = "native_model",
    source_reference = paste(output_ref, "Biomass Time Series"),
    notes = "Official total biomass at January 1.")
  add_output(assessment_id = assessment_id, type = "biomass",
    measure = "SSB", year = year, value = biomass[i, 3L],
    unit = "metric tons", source_type = "native_model",
    source_reference = paste(output_ref, "Biomass Time Series"),
    notes = "Official spawning-stock biomass; spawning occurs at the start of the year in this model.")
  add_output(assessment_id = assessment_id, type = "biomass",
    measure = "exploitable_biomass", year = year, value = biomass[i, 4L],
    unit = "metric tons", source_type = "native_model",
    source_reference = paste(output_ref, "Biomass Time Series"),
    notes = "Official exploitable biomass time series.")
  add_output(assessment_id = assessment_id, type = "mortality", measure = "Fbar",
    year = year, age_group = "ages 5-7 (unweighted)", value = Fbar[i, 2L],
    unit = "yr-1", source_type = "native_model",
    source_reference = paste(output_ref, "Average F for ages 5 to 7"),
    notes = "Official unweighted average F over ages 5-7; matches the mean of total F-at-age derived from directed plus discard F.")
}
new_inputs <- do.call(rbind, new_inputs)
new_outputs <- do.call(rbind, new_outputs)

cat("Pollock import prepared:", nrow(new_inputs), "inputs,", nrow(new_outputs),
  "outputs,", nrow(new_assumptions), "assumptions, and 1 assessment.\n")
if (!dry_run) {
  stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
  stock$authority_stock_id <- "5YZ"
  stock$common_name <- "Atlantic pollock"
  stock$notes <- paste(
    "Charbonneau-Keith identity retained (NEFSC_ virens_5YZ; Master revision 7e4daca3cbfc14ce7fa0b28ed824eebe7113249b).",
    "Official NOAA assessment area 5YZ and common name Atlantic pollock verified against the 2024 assessment. See source_reviews/nefsc_atlantic_pollock_5yz.md."
  )
  stocks[stocks$stock_id == stock_id, ] <- stock
  temp_stock <- tempfile(tmpdir = database, fileext = ".csv")
  write.csv(stocks, temp_stock, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  if (!file.rename(temp_stock, file.path(database, "stocks.csv"))) {
    stop("Could not replace stocks.csv.", call. = FALSE)
  }
  add_rows(file.path(database, "assessments.csv"), new_assessment)
  add_rows(file.path(database, "assumptions.csv"), new_assumptions)
  add_rows(file.path(database, "inputs.csv"), new_inputs)
  add_rows(file.path(database, "outputs.csv"), new_outputs)
  source(file.path(root, "scripts", "database", "002_validate_database.R"))
}
