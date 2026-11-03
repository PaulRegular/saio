root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ck_nefsc_garmiii_tenuis_gom_gb")
input_file <- file.path(cache, "RUN_005.DAT")
table_file <- file.path(cache, "2025_HKW_UNIT_TAB_ALL.pdf")
stock_id <- "ck_nefsc_garmiii_tenuis_gom_gb"
assessment_id <- "nefsc_white_hake_2025"
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

number_tokens <- function(line) {
  tokens <- strsplit(trimws(line), "[[:space:],]+")[[1L]]
  values <- suppressWarnings(as.numeric(tokens))
  values[!is.na(values)]
}

input_section <- function(lines, label, columns = NULL, rows = NULL) {
  trimmed <- trimws(lines)
  start <- which(trimmed == paste0("# ", label))
  if (length(start) != 1L) stop("Expected one input section: ", label, call. = FALSE)
  next_comment <- which(seq_along(lines) > start & grepl("^#", trimmed))
  end <- if (length(next_comment)) min(next_comment) - 1L else length(lines)
  parsed <- lapply(lines[seq.int(start + 1L, end)], number_tokens)
  parsed <- parsed[lengths(parsed) > 0L]
  if (!is.null(columns)) parsed <- parsed[lengths(parsed) == columns]
  if (!is.null(rows) && length(parsed) != rows) {
    stop(label, " has ", length(parsed), " rows; expected ", rows, ".", call. = FALSE)
  }
  if (!is.null(columns)) {
    return(matrix(unlist(parsed, use.names = FALSE), ncol = columns, byrow = TRUE))
  }
  unlist(parsed, use.names = FALSE)
}

pdf_table14 <- function(path) {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("Install pdftools to import reported White Hake Table 14.", call. = FALSE)
  }
  pages <- pdftools::pdf_text(path)
  lines <- unlist(strsplit(paste(pages[24:25], collapse = "\n"), "\n"))
  pattern <- "^\\s*((?:19|20)[0-9]{2})\\s+([0-9,]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9,]+)\\s+([0-9.]+)\\s*$"
  matches <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
  matches <- matches[lengths(matches) == 8L]
  if (length(matches) != 62L) {
    stop("Could not extract all 62 rows from official Table 14.", call. = FALSE)
  }
  values <- do.call(rbind, lapply(matches, function(x) {
    as.numeric(gsub(",", "", x[-1L], fixed = TRUE))
  }))
  colnames(values) <- c("year", "ssb", "ssb_cv", "Fbar", "Fbar_cv",
    "recruitment", "recruitment_cv")
  if (!identical(as.integer(values[, "year"]), 1963:2024)) {
    stop("Unexpected year range in official Table 14.", call. = FALSE)
  }
  values
}

add_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n", fileEncoding = "UTF-8")
}

if (!all(file.exists(c(input_file, table_file)))) {
  stop("White Hake cache files are missing; see the local source manifest.", call. = FALSE)
}

input_lines <- readLines(input_file, warn = FALSE)
stopifnot(
  input_section(input_lines, "Phase for Recruitment Deviations") == 4,
  input_section(input_lines, "Phase for Stock Recruitment Relationship") == 3,
  input_section(input_lines, "Phase for Steepness") == -3,
  input_section(input_lines, "Initial Steepness") == 1,
  input_section(input_lines, "Lambda for Recruitment Deviations") == 0,
  input_section(input_lines, "Phase for N in 1st Year") == 2,
  input_section(input_lines, "NAA Deviations Flag") == 1,
  input_section(input_lines, "Lambda for N in 1st Year Deviations") == 1,
  input_section(input_lines, "CV for N in 1st Year Deviations") == 0.2
)
n_years <- input_section(input_lines, "Number of Years")[[1L]]
year1 <- input_section(input_lines, "First Year")[[1L]]
n_ages <- input_section(input_lines, "Number of Ages")[[1L]]
years <- seq.int(year1, length.out = n_years)
ages <- seq_len(n_ages)
if (!identical(years, 1963:2024) || !identical(ages, 1:9)) {
  stop("Unexpected years or ages in the official ASAP input.", call. = FALSE)
}

M <- input_section(input_lines, "Natural Mortality", n_ages, n_years)
maturity <- input_section(input_lines, "Maturity", n_ages, n_years)
weight_matrices <- lapply(1:3, function(i) {
  input_section(input_lines, paste("Weight Matrix -", i), n_ages, n_years)
})
catch <- input_section(input_lines, "Fleet-1 Catch Data", n_ages + 1L, n_years)
discard <- input_section(input_lines, "Fleet-1 Discards Data", n_ages + 1L, n_years)
release <- input_section(input_lines, "Fleet-1 Release Data", n_ages, n_years)
catch_cv <- input_section(input_lines, "Catch Total CV by Year and Fleet", 1L, n_years)[, 1L]
catch_ess <- input_section(input_lines, "Catch Effective Sample Size by Year and Fleet", 1L, n_years)[, 1L]
weight_pointers <- as.integer(input_section(input_lines, "Weights at Age Pointers"))
index_names <- c(
  "NEFSC spring bottom trawl survey",
  "NEFSC fall bottom trawl survey",
  "ASMFC shrimp trawl survey",
  "NEFSC spring bottom longline survey",
  "NEFSC fall bottom longline survey"
)
index_seasons <- c("spring", "fall", "summer", "spring", "fall")
index_month <- as.numeric(input_section(input_lines, "Index Month"))
index_active <- as.integer(input_section(input_lines, "Use Index (Yes=1)"))
index_acomp_active <- as.integer(input_section(input_lines, "Estimate Proportion (Yes=1)"))
index_units <- as.integer(input_section(input_lines, "Aggregate Index Units"))
index_acomp_units <- as.integer(input_section(input_lines, "Age Proportion Index Units"))
index_weight_pointers <- as.integer(input_section(input_lines, "Weight at Age Matrix"))
index_data <- lapply(seq_along(index_names), function(i) {
  input_section(input_lines, paste0("Index-", i, " Data"), n_ages + 4L, n_years)
})

if (length(weight_pointers) != 6L ||
  !identical(weight_pointers, c(1L, 1L, 1L, 1L, 2L, 3L)) ||
  any(index_active != 1L) || any(index_acomp_active != 1L) ||
  any(index_units != 2L) || any(index_acomp_units != 2L) ||
  !identical(index_weight_pointers, rep(2L, 5L)) ||
  any(discard != 0) || any(release != 0)) {
  stop("Unexpected catch, discard, survey, or weight settings in the source run.", call. = FALSE)
}
if (!identical(which(catch_ess > 0), 27:62) ||
  any(catch_ess[27:62] != 58)) {
  stop("Unexpected catch age-composition sample-size pattern.", call. = FALSE)
}

outputs <- pdf_table14(table_file)
stocks <- read_table(file.path(database, "stocks.csv"))
assessments <- read_table(file.path(database, "assessments.csv"))
inputs <- read_table(file.path(database, "inputs.csv"))
assumptions <- read_table(file.path(database, "assumptions.csv"))
output_table <- read_table(file.path(database, "outputs.csv"))
if (sum(stocks$stock_id == stock_id) != 1L) stop("Expected one White Hake stock row.", call. = FALSE)
if (!dry_run && (assessment_id %in% assessments$assessment_id ||
  assessment_id %in% inputs$assessment_id ||
  assessment_id %in% assumptions$assessment_id ||
  assessment_id %in% output_table$assessment_id)) {
  stop("White Hake assessment rows already exist; inspect before importing.", call. = FALSE)
}

input_fields <- names(inputs)
output_fields <- names(output_table)
assumption_fields <- names(assumptions)
new_inputs <- list()
new_outputs <- list()
new_assumptions <- list()
add_input <- function(...) {
  new_inputs[[length(new_inputs) + 1L]] <<- blank_row(input_fields, list(...))
}
add_output <- function(...) {
  new_outputs[[length(new_outputs) + 1L]] <<- blank_row(output_fields, list(...))
}
add_assumption <- function(...) {
  new_assumptions[[length(new_assumptions) + 1L]] <<- blank_row(assumption_fields, list(...))
}

input_ref <- "RUN_005.DAT"
output_ref <- "2025_HKW_UNIT_TAB_ALL.pdf, Table 14"
for (age in ages) {
  add_input(assessment_id = assessment_id, type = "M",
    measure = "natural_mortality_at_age", basis = "per_year", age = age,
    value = M[1L, age], unit = "yr-1", source_type = "native_model",
    source_reference = paste(input_ref, "Natural Mortality"),
    notes = "Fixed natural mortality; the same age vector is repeated across all model years.")
  add_input(assessment_id = assessment_id, type = "maturity",
    measure = "maturity_at_age", basis = "proportion", age = age,
    value = maturity[1L, age], unit = "proportion", source_type = "native_model",
    source_reference = paste(input_ref, "Maturity"),
    notes = "Fixed maturity; the same age vector is repeated across all model years.")
}

for (i in seq_along(years)) {
  year <- years[i]
  for (age in ages) {
    add_input(assessment_id = assessment_id, type = "catch_weight",
      measure = "weight_at_age", basis = "kg_per_fish", fleet = "Combined catch",
      year = year, year_basis = "calendar_year", age = age,
      value = weight_matrices[[1L]][i, age], unit = "kg per fish",
      source_type = "native_model",
      source_reference = paste(input_ref, "Weight Matrix - 1; Weights at Age Pointers"),
      notes = "Native catch weight matrix 1; the fleet catch weight pointer equals 1.")
    add_input(assessment_id = assessment_id, type = "weight",
      measure = "weight_at_age", basis = "kg_per_fish",
      year = year, year_basis = "calendar_year", age = age,
      value = weight_matrices[[2L]][i, age], unit = "kg per fish",
      source_type = "native_model",
      source_reference = paste(input_ref, "Weight Matrix - 2; Weights at Age Pointers"),
      notes = "Native spawning-biomass weight matrix 2; spawning pointer equals 2 and all index pointers also equal 2.")
    add_input(assessment_id = assessment_id, type = "weight",
      measure = "start_weight_at_age", basis = "kg_per_fish",
      year = year, year_basis = "calendar_year", age = age,
      value = weight_matrices[[3L]][i, age], unit = "kg per fish",
      source_type = "native_model",
      source_reference = paste(input_ref, "Weight Matrix - 3; Weights at Age Pointers"),
      notes = "Native start-of-year biomass weight matrix 3; population biomass pointer equals 3.")
  }
  add_input(assessment_id = assessment_id, type = "catch",
    measure = "total_biomass", basis = "biomass", fleet = "Combined catch",
    year = year, year_basis = "calendar_year", value = catch[i, n_ages + 1L],
    unit = "metric tons", partition = "combined", source_type = "native_model",
    source_reference = paste(input_ref, "Fleet-1 Catch Data"),
    notes = "Total catch biomass for the single combined catch fleet.")
  add_input(assessment_id = assessment_id, type = "catch",
    measure = "relative_standard_error", basis = "relative_scale",
    fleet = "Combined catch", year = year, year_basis = "calendar_year",
    value = catch_cv[i], unit = "coefficient of variation", partition = "combined",
    source_type = "native_model",
    source_reference = paste(input_ref, "Catch Total CV by Year and Fleet"),
    notes = "Model-specified CV for the total catch biomass observation.")
  if (catch_ess[i] > 0) {
    for (age in ages) {
      add_input(assessment_id = assessment_id, type = "catch",
        measure = "numbers_at_age", basis = "numbers", fleet = "Combined catch",
        year = year, year_basis = "calendar_year", age = age,
        value = catch[i, age], unit = "thousand fish", sample_size = catch_ess[i],
        partition = "combined", source_type = "native_model",
        source_reference = paste(input_ref, "Fleet-1 Catch Data; Catch Effective Sample Size by Year and Fleet"),
        notes = "Native ASAP catch-at-age numbers; zero cells are retained and age-composition ESS is stored separately from total catch CV.")
    }
  }
}

for (i in seq_along(index_names)) {
  data <- index_data[[i]]
  sampling_time <- (index_month[i] - 1) / 12
  valid <- which(data[, 2L] > 0)
  for (j in valid) {
    year <- as.integer(data[j, 1L])
    for (age in ages) {
      add_input(assessment_id = assessment_id, type = "index",
        measure = "numbers_at_age", basis = "numbers", survey = index_names[i],
        region = "Gulf of Maine-Georges Bank", season = index_seasons[i],
        year = year, year_basis = "calendar_year", age = age,
        value = data[j, age + 3L],
        unit = if (i %in% c(4L, 5L)) "number per set" else "number per tow",
        sampling_time = sampling_time, sample_size = data[j, n_ages + 4L],
        source_type = "native_model",
        source_reference = paste(input_ref, paste0("Index-", i, " Data")),
        notes = "Native age-specific number index; preserve the row even when its effective sample size is zero, because the source input includes the age values.")
    }
    add_input(assessment_id = assessment_id, type = "index",
      measure = "total_numbers", basis = "numbers", survey = index_names[i],
      region = "Gulf of Maine-Georges Bank", season = index_seasons[i],
      year = year, year_basis = "calendar_year", value = data[j, 2L],
      unit = if (i %in% c(4L, 5L)) "number per set" else "number per tow",
      sampling_time = sampling_time, source_type = "native_model",
      source_reference = paste(input_ref, paste0("Index-", i, " Data")),
      notes = "Native aggregate relative abundance index; age-specific rows and their composition ESS are preserved separately.")
    add_input(assessment_id = assessment_id, type = "index",
      measure = "relative_standard_error", basis = "relative_scale",
      survey = index_names[i], region = "Gulf of Maine-Georges Bank",
      season = index_seasons[i], year = year, year_basis = "calendar_year",
      value = data[j, 3L], unit = "coefficient of variation",
      sampling_time = sampling_time, source_type = "native_model",
      source_reference = paste(input_ref, paste0("Index-", i, " Data")),
      notes = "Model-specified CV for the aggregate index; this is distinct from the age-composition effective sample size.")
  }
}

for (i in seq_len(nrow(outputs))) {
  year <- outputs[i, "year"]
  add_output(assessment_id = assessment_id, type = "biomass",
    measure = "SSB", year = year, value = outputs[i, "ssb"],
    se = outputs[i, "ssb"] * outputs[i, "ssb_cv"], unit = "metric tons",
    source_type = "official_table", source_reference = output_ref,
    notes = paste0("Official annual SSB; Table 14 reports CV ", outputs[i, "ssb_cv"],
      ". SE is approximate, calculated as estimate multiplied by reported CV."))
  add_output(assessment_id = assessment_id, type = "mortality",
    measure = "Fbar", year = year, age_group = "6-9+",
    value = outputs[i, "Fbar"],
    se = outputs[i, "Fbar"] * outputs[i, "Fbar_cv"], unit = "yr-1",
    source_type = "official_table", source_reference = output_ref,
    notes = paste0("Unweighted fully selected F over ages 6-9+; Table 14 reports CV ",
      outputs[i, "Fbar_cv"], ". SE is approximate, calculated as estimate multiplied by reported CV."))
  add_output(assessment_id = assessment_id, type = "recruitment",
    measure = "recruitment", year = year, age = 1,
    value = outputs[i, "recruitment"],
    se = outputs[i, "recruitment"] * outputs[i, "recruitment_cv"],
    unit = "thousand fish", source_type = "official_table",
    source_reference = output_ref,
    notes = paste0("Age-1 recruitment; Table 14 reports CV ", outputs[i, "recruitment_cv"],
      ". SE is approximate, calculated as estimate multiplied by reported CV."))
}

assignment <- as.integer(input_section(
  input_lines, "Fleet 1 Selectivity Block Assignment", 1L, n_years
)[, 1L])
block_runs <- rle(assignment)
block_ends <- cumsum(block_runs$lengths)
block_starts <- block_ends - block_runs$lengths + 1L
selectivity_blocks <- paste0(
  "block ", block_runs$values, " (", years[block_starts], "-", years[block_ends], ")"
)
add_assumption(assessment_id = assessment_id, component = "population",
  setting = "modeled_years", value = "1963-2024",
  source_reference = paste(input_ref, "Number of Years; First Year"),
  notes = "62 historical years; no projection years are in the fitted run.")
add_assumption(assessment_id = assessment_id, component = "population",
  setting = "modeled_ages", value = "ages 1-9+",
  source_reference = paste(input_ref, "Number of Ages"),
  notes = "Nine age groups; age 9 is the terminal plus group.")
add_assumption(assessment_id = assessment_id, component = "population",
  setting = "sex", value = "sex-combined",
  source_reference = input_ref,
  notes = "One stock and one combined catch fleet; no sex-specific model dimension.")
add_assumption(assessment_id = assessment_id, component = "catch",
  setting = "fleet", value = "one combined catch fleet",
  source_reference = paste(input_ref, "Fleet Names; Fleet Directed Flag"),
  notes = "The fitted model combines catch streams; source discard and release matrices are all zero.")
add_assumption(assessment_id = assessment_id, component = "catch",
  setting = "observation_model",
  value = "total catch biomass with CV plus numbers-at-age composition",
  source_reference = paste(input_ref, "Fleet-1 Catch Data; Catch Total CV by Year and Fleet; Catch Effective Sample Size by Year and Fleet"),
  notes = "Total catch is supplied for 1963-2024. Catch-at-age and ESS 58 are supplied for 1989-2024; ESS is zero before 1989.")
add_assumption(assessment_id = assessment_id, component = "F",
  setting = "selectivity_blocks", value = paste(selectivity_blocks, collapse = "; "),
  source_reference = paste(input_ref, "Fleet 1 Selectivity Block Assignment; Selectivity Options for each block"),
  notes = "Two blocks use age-specific selectivity. The fleet is fixed fully selected over ages 6-9+.")
add_assumption(assessment_id = assessment_id, component = "F",
  setting = "Fbar_definition", value = "unweighted mean over ages 6-9+",
  source_reference = paste(input_ref, "Age Range for Average F; Average F report option; Table 14"),
  notes = "The official annual F series is fully selected F, not F-at-age.")
add_assumption(assessment_id = assessment_id, component = "M",
  setting = "treatment", value = "fixed M = 0.20 yr-1 at ages 1-9+",
  source_reference = paste(input_ref, "Natural Mortality"),
  notes = "The annual input matrix repeats the same age vector; no M process is estimated.")
add_assumption(assessment_id = assessment_id, component = "biology",
  setting = "maturity", value = "fixed age-specific maturity",
  source_reference = paste(input_ref, "Maturity"),
  notes = "The same maturity vector is repeated in all years.")
add_assumption(assessment_id = assessment_id, component = "biology",
  setting = "weight_matrices", value = "matrix 1 catch; matrix 2 SSB and all surveys; matrix 3 start-of-year biomass",
  source_reference = paste(input_ref, "Weight Matrix - 1; Weight Matrix - 2; Weight Matrix - 3; Weights at Age Pointers; Weight at Age Matrix"),
  notes = "All three annual age-specific matrices are retained in inputs.csv. All five survey weight pointers equal 2.")
add_assumption(assessment_id = assessment_id, component = "biology",
  setting = "spawning_time", value = "0.25",
  source_reference = paste(input_ref, "Fraction of year that elapses prior to SSB calculation"),
  notes = "SSB is calculated one quarter of the year after January 1.")
add_assumption(assessment_id = assessment_id, component = "index",
  setting = "active_surveys", value = paste(index_names, collapse = "; "),
  source_reference = paste(input_ref, "Survey Names; Use Index (Yes=1)"),
  notes = "All five active indices are retained: NEFSC spring/fall trawl, ASMFC shrimp trawl, and NEFSC spring/fall bottom longline.")
add_assumption(assessment_id = assessment_id, component = "index",
  setting = "observation_model",
  value = "aggregate number index with CV and age-composition likelihood with effective sample size",
  source_reference = paste(input_ref, "Aggregate Index Units; Age Proportion Index Units; Index Data"),
  notes = "Both unit codes are 2 (numbers). Age-specific rows are preserved as native numbers per tow or per set.")
add_assumption(assessment_id = assessment_id, component = "index",
  setting = "survey_timing", value = "April 0.25; July 0.50; October 0.75",
  source_reference = paste(input_ref, "Index Month"),
  notes = "Within-year timing is calculated as (month - 1) / 12.")
add_assumption(assessment_id = assessment_id, component = "index",
  setting = "catchability", value = "five survey-specific q levels; annual q deviations inactive",
  source_reference = paste(input_ref, "Phase for Catchability in 1st Year; Phase for Catchability Deviations"),
  notes = "The q-deviation phase is -5; tinyAM's survey-by-age q structure is an approximation.")
add_assumption(assessment_id = assessment_id, component = "recruitment",
  setting = "recruitment_and_initial_states",
  value = "constant expected age-1 recruitment; steepness fixed at 1; annual recruitment deviations estimated without a recruitment penalty",
  source_reference = paste(input_ref, "Phase for Recruitment Deviations; Phase for Stock Recruitment Relationship; Phase for Steepness; Initial Steepness; Lambda for Recruitment Deviations; ASAP3 Technical Documentation pp. 3-4, 41-42"),
  notes = "The recruitment scaler is estimated in phase 3 and log deviations in phase 4; steepness is fixed (phase -3) at 1, so BH beta is zero and expected recruitment is independent of SSB. Recruitment CV 0.5 is supplied but lambda = 0 removes its likelihood contribution. Log deviations are sum-to-zero fixed-effect parameters, not integrated random effects. No lognormal bias correction appears in the documented recruitment equation.")
add_assumption(assessment_id = assessment_id, component = "N",
  setting = "cohort_survival",
  value = "deterministic survival after recruitment with terminal plus-group accumulation",
  source_reference = paste(input_ref, "ASAP3 Technical Documentation p. 5 Eq. 13 and p. 31 get_numbers_at_age"),
  notes = "For ages 2-8, N[t,a] = N[t-1,a-1] * exp(-Z[t-1,a-1]); age 9+ also retains survivors from age 9+. No older-cohort process deviations enter this recursion. NAA Deviations Flag controls the initial-age penalty, not an annual N process.")
add_assumption(assessment_id = assessment_id, component = "N",
  setting = "initial_abundance",
  value = "initial older-age abundances estimated with a lognormal penalty around first-year equilibrium survival",
  source_reference = paste(input_ref, "Phase for N in 1st Year; NAA Deviations Flag; Lambda for N in 1st Year Deviations; CV for N in 1st Year Deviations; ASAP3 Technical Documentation pp. 43-44"),
  notes = "Phase 2 estimates initial older-age abundances. Flag 1 sets the penalty reference from expected first-year recruitment and cumulative first-year survival, with a plus-group divisor 1-exp(-Z[1,9]). Lambda is 1 and supplied CV is 0.2 (log SD sqrt(log(1+0.2^2))). The documented objective uses all initial ages in its norm; this is not tinyAM's unpenalized free or deterministic exp initialization.")
add_assumption(assessment_id = assessment_id, component = "model",
  setting = "selected_run", value = "2025 Management Track Run_005; ASAP 3.0",
  source_reference = input_ref,
  notes = "The final peer-review panel accepted the 2025 management-track assessment as best scientific information available.")
add_assumption(assessment_id = assessment_id, component = "model",
  setting = "output_availability", value = "SSB, fully selected F, recruitment and CVs reported annually",
  source_reference = output_ref,
  notes = "Complete N-at-age, F-at-age, and their uncertainty surfaces were not recovered; no age-specific estimates are inferred.")

new_inputs <- do.call(rbind, new_inputs)
new_outputs <- do.call(rbind, new_outputs)
new_assumptions <- do.call(rbind, new_assumptions)
new_assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025, terminal_year = 2024, estimate_terminal_year = 2024,
  assessment_type = "assessment_update", model_family = "ASAP",
  model_version = "ASAP 3.0 Run_005",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2013,
  assessment_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&filename=2025_HKW_UNIT_RPT.pdf",
  framework_url = "https://repository.library.noaa.gov/view/noaa/4374/noaa_4374_DS1.pdf",
  data_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=RUN_005.DAT",
  model_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3&filename=2025_HKW_UNIT.zip",
  repository_url = "https://www.fisheries.noaa.gov/s3/2025-11/September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf",
  assumptions_status = "partial", inputs_status = "complete", outputs_status = "partial",
  notes = "Latest detailed official White Hake assessment recovered: 2025 Management Track Run_005, fitted through 2024. The final peer-review panel concluded it met the terms of reference and represented best scientific information available. The SASI working paper is marked draft but provides the detailed tables; the peer-review decision verifies the run. Only annual SSB, fully selected F and recruitment are numerically reported in Table 14; fitted N-at-age and F-at-age surfaces and their uncertainty are unavailable. See source_reviews/ck_nefsc_garmiii_tenuis_gom_gb.md."
))

cat("White Hake import prepared:", nrow(new_inputs), "inputs,",
  nrow(new_assumptions), "assumptions,", nrow(new_outputs), "outputs.\n")
if (!dry_run) {
  stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
  stock$authority_stock_id <- "GOM/GB"
  stock$common_name <- "White hake"
  stock$notes <- paste(
    "Charbonneau-Keith GOM/GB identity retained (NEFSC-GARMIII_tenuis_GOM, GB).",
    "The latest detailed official assessment is the 2025 NOAA NEFSC Management Track Run_005, accepted for management use by the final peer-review panel."
  )
  stocks[stocks$stock_id == stock_id, ] <- stock
  temp_stock <- tempfile(tmpdir = database, fileext = ".csv")
  write.csv(stocks, temp_stock, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  if (!file.rename(temp_stock, file.path(database, "stocks.csv"))) {
    stop("Could not replace stocks.csv.", call. = FALSE)
  }
  add_rows(file.path(database, "assessments.csv"), new_assessment)
  add_rows(file.path(database, "inputs.csv"), new_inputs)
  add_rows(file.path(database, "assumptions.csv"), new_assumptions)
  add_rows(file.path(database, "outputs.csv"), new_outputs)
}
