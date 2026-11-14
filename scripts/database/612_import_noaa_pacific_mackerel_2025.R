root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_pacific_mackerel_2025")
model_files <- file.path(cache, "Mackerel_2023_Model_Files")
assessment_2023 <- "noaa_pacific_mackerel_2023"
assessment_2025 <- "noaa_pacific_mackerel_2025"
stock_id <- "noaa_pacific_mackerel_pacific_coast"
candidate_id <- "NOAA:10163"
candidate_unit_id <- stock_id
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))
sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile",
    shQuote(normalizePath(path, winslash = "\\")), "SHA256"), stdout = TRUE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result, value = TRUE)))
  if (length(hash) != 1L) stop("Could not calculate SHA-256 for ", path,
    call. = FALSE)
  hash
}
source_manifest <- read_csv(file.path(root, "provenance",
  "discovery_noaa_pacific_mackerel_2025", "sources.csv"))
verify_source <- function(source_id, path) {
  entry <- source_manifest[source_manifest$source_id == source_id, , drop = FALSE]
  if (nrow(entry) != 1L || !file.exists(path) ||
      tolower(entry$sha256) != sha256_file(path))
    stop("Cached source differs from its provenance record: ", source_id,
      call. = FALSE)
  path
}
verify_source("pfmc_2023_benchmark_assessment",
  file.path(cache, "pacific_mackerel_benchmark_2023.pdf"))
verify_source("pfmc_2025_catch_only_assessment",
  file.path(cache, "pacific_mackerel_catch_only_2025.pdf"))
verify_source("pfmc_2023_model_files",
  file.path(cache, "pacific_mackerel_2023_model_files.zip"))

data_file <- file.path(model_files, "pmack2023.dat")
control_file <- file.path(model_files, "pmack2023.ctl")
wtatage_file <- file.path(model_files, "wtatage.ss")
report_file <- file.path(model_files, "Report.sso")
required_files <- c(data_file, control_file, wtatage_file, report_file)
if (any(!file.exists(required_files)))
  stop("Cached Stock Synthesis archive is incomplete.", call. = FALSE)

input_fields <- read_fields(file.path(database, "inputs.csv"))
output_fields <- read_fields(file.path(database, "outputs.csv"))
assumption_fields <- read_fields(file.path(database, "assumptions.csv"))
stock_fields <- read_fields(file.path(database, "stocks.csv"))
assessment_fields <- read_fields(file.path(database, "assessments.csv"))

make_row <- function(fields, n, values) {
  out <- as.data.frame(lapply(fields, function(x) rep(NA_character_, n)),
    stringsAsFactors = FALSE, check.names = FALSE)
  names(out) <- fields
  for (name in names(values)) out[[name]] <- rep_len(values[[name]], n)
  out
}
make_input <- function(n, ...) make_row(input_fields, n, list(...))
make_output <- function(n, ...) make_row(output_fields, n, list(...))
make_assumption <- function(n, ...) make_row(assumption_fields, n, list(...))
make_stock <- function(...) make_row(stock_fields, 1L, list(...))
make_assessment <- function(...) make_row(assessment_fields, 1L, list(...))

read_numeric_block <- function(lines, marker, n_fields, regex = FALSE) {
  start <- if (is.numeric(marker)) as.integer(marker) else if (regex)
    grep(marker, lines, perl = TRUE) else which(trimws(lines) == marker)
  if (length(start) != 1L) stop("Expected one data block: ", marker,
    call. = FALSE)
  result <- list()
  for (i in seq.int(start + 1L, length(lines))) {
    line <- trimws(sub("#.*$", "", lines[i]))
    if (!nzchar(line)) next
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (fields[1L] == "-9999") break
    if (length(fields) != n_fields)
      stop("Unexpected field count in data block at line ", i, call. = FALSE)
    row <- suppressWarnings(as.numeric(fields))
    if (anyNA(row)) stop("Invalid number in data block at line ", i,
      call. = FALSE)
    result[[length(result) + 1L]] <- row
  }
  if (!length(result)) stop("No values in data block.", call. = FALSE)
  as.data.frame(do.call(rbind, result), stringsAsFactors = FALSE)
}
read_marked_block <- function(lines, marker, n_fields) {
  matches <- grep(marker, lines, ignore.case = TRUE, perl = TRUE)
  if (length(matches) != 1L) stop("Expected one section marker: ", marker,
    call. = FALSE)
  read_numeric_block(lines, matches, n_fields)
}
data_lines <- readLines(data_file, warn = FALSE)
catch <- read_marked_block(data_lines, "Updated catch values", 5L)
index <- read_marked_block(data_lines, "^#_yr month fleet obs stderr$", 5L)
age_composition <- read_marked_block(data_lines,
  "^#_yr month fleet sex part ageerr Lbin_lo Lbin_hi Nsamp datavector", 18L)

if (nrow(catch) != 14L || anyDuplicated(catch[[1L]]) ||
    any(catch[[1L]] < 2008 | catch[[1L]] > 2021))
  stop("Unexpected 2023 catch coverage.", call. = FALSE)
if (nrow(index) != 10L || anyDuplicated(index[[1L]]) ||
    any(index[[3L]] != 2))
  stop("Unexpected 2023 AT index coverage.", call. = FALSE)
if (any(!age_composition[[3L]] %in% 1:2) ||
    any(!age_composition[[6L]] %in% 1:2) ||
    any(abs(rowSums(age_composition[, 10:18]) - 1) > 1e-4))
  stop("Unexpected age-composition fields or row sums.", call. = FALSE)

composition_to_inputs <- function(frame, assessment_id, carried_forward = FALSE) {
  rows <- vector("list", nrow(frame))
  for (i in seq_len(nrow(frame))) {
    is_survey <- as.integer(frame[i, 3L]) == 2L
    year <- as.integer(frame[i, 1L])
    month <- as.numeric(frame[i, 2L])
    ref <- if (carried_forward)
      "2023 SS3 pmack2023.dat age-composition section; PFMC 2025 report section 5 confirms non-catch data unchanged"
    else "2023 SS3 pmack2023.dat age-composition section"
    note <- paste0("Native age-composition likelihood input; source sex code ",
      frame[i, 4L], ", partition code ", frame[i, 5L],
      "; age 8 is the 8+ group. sample_size is supplied likelihood Nsamp, not a raw fish count.",
      if (carried_forward) " Carried forward unchanged to the 2025 update." else "")
    source_sex <- as.integer(frame[i, 4L])
    rows[[i]] <- make_input(9L, assessment_id = assessment_id,
      type = if (is_survey) "index" else "catch",
      measure = "proportion_at_age", basis = "proportion_numbers",
      fleet = if (is_survey) NA_character_ else "FISHERY",
      survey = if (is_survey) "AT" else NA_character_,
      sex = if (source_sex == 0L) "combined" else paste0("model sex ", source_sex),
      season = if (is_survey) "summer" else "winter",
      year = year, year_basis = "model_year", age = 0:8,
      value = as.numeric(frame[i, 10:18]), unit = "proportion",
      sampling_time = (month - 1) / 12, source_type = "native_model",
      source_reference = ref, notes = note,
      observation_id = paste0(assessment_id, "_",
        if (is_survey) "AT" else "FISHERY", "_", year),
      sample_size = as.numeric(frame[i, 9L]),
      age_error = as.integer(frame[i, 6L]),
      partition = as.character(as.integer(frame[i, 5L])))
  }
  do.call(rbind, rows)
}
wt_lines <- readLines(wtatage_file, warn = FALSE)
wt_rows <- list()
for (line in wt_lines[grepl(
  "^\\s*20[0-9]{2}\\s+1\\s+1\\s+1\\s+1\\s+-?[0-2]([[:space:]]|$)",
  wt_lines, perl = TRUE)]) {
  fields <- strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
  if (length(fields) != 15L) stop("Unexpected wtatage.ss row length.",
    call. = FALSE)
  wt_rows[[length(wt_rows) + 1L]] <- suppressWarnings(as.numeric(fields))
}
wtatage <- as.data.frame(do.call(rbind, wt_rows), stringsAsFactors = FALSE)
wtatage <- wtatage[wtatage[[1L]] >= 2008 & wtatage[[1L]] <= 2021, , drop = FALSE]
if (nrow(wtatage) != 70L ||
    anyDuplicated(paste(wtatage[[1L]], wtatage[[6L]])))
  stop("Unexpected empirical weight-at-age coverage.", call. = FALSE)

weight_to_inputs <- function(frame, assessment_id, carried_forward = FALSE) {
  rows <- vector("list", nrow(frame))
  for (i in seq_len(nrow(frame))) {
    code <- as.integer(frame[i, 6L])
    if (code == -2L) {
      type <- "biology"; measure <- "maturity_fecundity_at_age"
      basis <- "native_scale"; unit <- "native model scale"
      fleet <- survey <- NA_character_
      note <- "Native wtatage.ss fleet -2 surface labelled maturity*fecundity; its unit definition is not specified, so it is retained on the native model scale, not as a standalone maturity proportion or weight."
    } else if (code == -1L) {
      type <- "weight"; measure <- "weight_at_age"
      basis <- "kg_per_fish"; unit <- "kg/fish"
      fleet <- survey <- NA_character_
      note <- "Native population mid-season weight-at-age (SS3 fleet code -1)."
    } else if (code == 0L) {
      type <- "weight"; measure <- "start_weight_at_age"
      basis <- "kg_per_fish"; unit <- "kg/fish"
      fleet <- survey <- NA_character_
      note <- "Native population beginning-season weight-at-age (SS3 fleet code 0)."
    } else if (code == 1L) {
      type <- "catch_weight"; measure <- "catch_weight_at_age"
      basis <- "kg_per_fish"; unit <- "kg/fish"
      fleet <- "FISHERY"; survey <- NA_character_
      note <- "Native fishery-specific weight-at-age (SS3 fleet code 1)."
    } else {
      type <- "weight"; measure <- "weight_at_age"
      basis <- "kg_per_fish"; unit <- "kg/fish"
      fleet <- NA_character_; survey <- "AT"
      note <- "Native acoustic-trawl survey weight-at-age (SS3 fleet code 2)."
    }
    if (carried_forward)
      note <- paste(note, "PFMC 2025 report section 5 confirms non-catch inputs unchanged.")
    rows[[i]] <- make_input(9L, assessment_id = assessment_id,
      type = type, measure = measure, basis = basis,
      fleet = fleet, survey = survey, season = "annual",
      year = as.integer(frame[i, 1L]), year_basis = "model_year",
      age = 0:8, value = as.numeric(frame[i, 7:15]), unit = unit,
      source_type = "native_model",
      source_reference = if (carried_forward)
        "2023 SS3 wtatage.ss; PFMC 2025 report section 5"
      else "2023 SS3 wtatage.ss",
      notes = paste(note, "Age 8 is the 8+ group."))
  }
  do.call(rbind, rows)
}

age_error_vector <- function(pattern) {
  i <- grep(pattern, data_lines, ignore.case = TRUE, perl = TRUE)
  if (length(i) != 1L) stop("Could not locate age-error vector: ", pattern,
    call. = FALSE)
  values <- suppressWarnings(as.numeric(strsplit(trimws(sub("#.*$", "",
    data_lines[i])), "[[:space:]]+")[[1L]]))
  if (length(values) != 9L || anyNA(values))
    stop("Unexpected age-error vector: ", pattern, call. = FALSE)
  values
}
fishery_age_sd <- age_error_vector("Ageing error for fishery age compositions")
survey_age_sd <- age_error_vector("SDs from Emmanis table")
age_error_to_inputs <- function(assessment_id, carried_forward = FALSE) {
  defs <- list(
    list(code = 1L, fleet = "FISHERY", survey = NA_character_,
      values = fishery_age_sd, note = "Fishery age-error definition 1."),
    list(code = 2L, fleet = NA_character_, survey = "AT",
      values = survey_age_sd, note = "Acoustic-trawl age-error definition 2.")
  )
  do.call(rbind, lapply(defs, function(def) {
    note <- paste(def$note, "Native SS3 standard deviations by age; age 8 is 8+.")
    if (carried_forward) note <- paste(note,
      "PFMC 2025 report section 5 confirms age-error definitions unchanged.")
    make_input(9L, assessment_id = assessment_id, type = "biology",
      measure = "ageing_error_sd", basis = "age_error_sd",
      fleet = def$fleet, survey = def$survey, age = 0:8,
      value = def$values, unit = "years",
      source_type = "native_model",
      source_reference = if (carried_forward)
        "2023 SS3 pmack2023.dat; PFMC 2025 report section 5"
      else "2023 SS3 pmack2023.dat age-error definitions",
      notes = note, age_error = def$code)
  }))
}

catch_2023 <- make_input(nrow(catch), assessment_id = assessment_2023,
  type = "catch", measure = "catch_biomass", basis = "biomass",
  fleet = "FISHERY", year = as.integer(catch[[1L]]),
  year_basis = "model_year", value = as.numeric(catch[[4L]]), unit = "mt",
  source_type = "native_model",
  source_reference = "2023 SS3 pmack2023.dat catch data section",
  notes = "Combined commercial and recreational fishery; discards assumed negligible. Exact native model input.")
catch_sd_2023 <- make_input(nrow(catch), assessment_id = assessment_2023,
  type = "catch", measure = "log_catch_sd", basis = "log_scale",
  fleet = "FISHERY", year = as.integer(catch[[1L]]),
  year_basis = "model_year", value = as.numeric(catch[[5L]]),
  unit = "log scale", source_type = "native_model",
  source_reference = "2023 SS3 pmack2023.dat catch data section",
  notes = "Native catch_se field; source comment defines it as standard error of log catch.")
index_2023 <- make_input(nrow(index), assessment_id = assessment_2023,
  type = "index", measure = "relative_biomass_index", basis = "index_scale",
  survey = "AT", season = "summer", year = as.integer(index[[1L]]),
  year_basis = "model_year", value = as.numeric(index[[4L]]),
  unit = "native biomass-index scale",
  sampling_time = (as.numeric(index[[2L]]) - 1) / 12,
  source_type = "native_model",
  source_reference = "2023 SS3 pmack2023.dat survey observations",
  notes = "SS3 declares biomass observation units; native physical unit multiplier is unstated. Relative biomass index, not direct abundance.")
index_cv_2023 <- make_input(nrow(index), assessment_id = assessment_2023,
  type = "index", measure = "biomass_index_cv", basis = "relative_scale",
  survey = "AT", season = "summer", year = as.integer(index[[1L]]),
  year_basis = "model_year", value = as.numeric(index[[5L]]), unit = "ratio",
  sampling_time = (as.numeric(index[[2L]]) - 1) / 12,
  source_type = "native_model",
  source_reference = "2023 SS3 pmack2023.dat survey observations",
  notes = "Native lognormal index stderr/CV field retained without transformation.")
inputs_2023 <- rbind(catch_2023, catch_sd_2023, index_2023, index_cv_2023,
  composition_to_inputs(age_composition, assessment_2023),
  age_error_to_inputs(assessment_2023),
  weight_to_inputs(wtatage, assessment_2023))

catch_2025_year <- 2008:2026
catch_2025_value <- c(5369, 3331, 4220, 4232, 12905, 14544, 9697, 13834,
  14426, 4611, 18353, 23034, 32027, 12222, 21895, 15866, 24163, 16661, 16661)
catch_2025_notes <- ifelse(catch_2025_year <= 2023,
  "Table 2 landings total; published value rounded to nearest mt.",
  ifelse(catch_2025_year == 2024,
    "Table 3 forecast: partial 2024 observations combined with recent averages; rounded to nearest mt.",
    "Table 3 forecast based on average annual landings in model years 2021-2023; rounded to nearest mt."))
catch_2025 <- make_input(length(catch_2025_year),
  assessment_id = assessment_2025, type = "catch",
  measure = "catch_biomass", basis = "biomass", fleet = "FISHERY",
  year = catch_2025_year, year_basis = "model_year",
  value = catch_2025_value, unit = "mt", source_type = "official_table",
  source_reference = ifelse(catch_2025_year <= 2023,
    "PFMC 2025 catch-only assessment Table 2, p. 11",
    "PFMC 2025 catch-only assessment Table 3, p. 11"),
  notes = catch_2025_notes)
index_2025 <- index_2023
index_2025$assessment_id <- assessment_2025
index_2025$source_reference <- paste(index_2025$source_reference,
  "PFMC 2025 report section 5 confirms it was retained unchanged.")
index_2025$notes <- paste(index_2025$notes,
  "Carried forward unchanged into the 2025 catch-only update.")
index_cv_2025 <- index_cv_2023
index_cv_2025$assessment_id <- assessment_2025
index_cv_2025$source_reference <- paste(index_cv_2025$source_reference,
  "PFMC 2025 report section 5 confirms it was retained unchanged.")
index_cv_2025$notes <- paste(index_cv_2025$notes,
  "Carried forward unchanged into the 2025 catch-only update.")
inputs_2025 <- rbind(catch_2025, index_2025, index_cv_2025,
  composition_to_inputs(age_composition, assessment_2025, TRUE),
  age_error_to_inputs(assessment_2025, TRUE),
  weight_to_inputs(wtatage, assessment_2025, TRUE))
input_data <- rbind(inputs_2023, inputs_2025)

assumption_2023 <- rbind(
  make_assumption(1L, assessment_id = assessment_2023, component = "model",
    setting = "model_year_definition",
    value = "July 1 through June 30; recruitment in July",
    source_reference = "PFMC 2023 assessment Table 5; pmack2023.dat"),
  make_assumption(1L, assessment_id = assessment_2023, component = "model",
    setting = "sex_and_age_structure",
    value = "One model sex; ages 0-8, with age 8 as the plus group",
    source_reference = "pmack2023.dat; Report.sso DEFINITIONS"),
  make_assumption(1L, assessment_id = assessment_2023, component = "model",
    setting = "fleet_structure",
    value = "One fishery combines commercial and recreational landings; discards assumed negligible; one acoustic-trawl survey",
    source_reference = "PFMC 2023 assessment section 2.1; pmack2023.dat"),
  make_assumption(1L, assessment_id = assessment_2023, component = "survey",
    survey = "AT", setting = "sampling_time",
    value = "Native model month 1.6; Report.sso time is 0.05 of model year",
    source_reference = "pmack2023.dat survey observations; Report.sso FIT_AGE_COMPS"),
  make_assumption(1L, assessment_id = assessment_2023, component = "biology",
    setting = "natural_mortality",
    value = "Lorenzen age pattern; mean natural mortality estimated with a longevity-based prior",
    source_reference = "pmack2023.ctl; PFMC 2023 assessment Table 10"),
  make_assumption(1L, assessment_id = assessment_2023, component = "biology",
    setting = "maturity_and_fecundity",
    value = "Native wtatage.ss includes a maturity*fecundity surface. The archived control/report identifies maturity option 5 as disabled; Table 9 maturity estimates are not treated as fitted age-maturity inputs.",
    source_reference = "wtatage.ss; pmack2023.ctl; Report.sso DEFINITIONS; PFMC 2023 Table 9"),
  make_assumption(1L, assessment_id = assessment_2023, component = "recruitment",
    setting = "stock_recruitment",
    value = "Beverton-Holt; recruitment deviations estimated",
    source_reference = "pmack2023.ctl; Report.sso SPAWN_RECRUIT"),
  make_assumption(1L, assessment_id = assessment_2023, component = "survey",
    survey = "AT", setting = "index_scale",
    value = "Biomass-scale observation; physical unit multiplier not stated",
    source_reference = "pmack2023.dat survey observation section"))
assumption_2025 <- rbind(
  make_assumption(1L, assessment_id = assessment_2025, component = "model",
    setting = "catch_update",
    value = "Updated catches for model years 2008-2022; added 2023 catch; 2024-2026 catches are forecasts",
    source_reference = "PFMC 2025 report sections 1 and 5; Tables 2-3"),
  make_assumption(1L, assessment_id = assessment_2025, component = "model",
    setting = "inherited_inputs",
    value = "2023 benchmark structure and non-catch inputs retained; 2025 report states catch time series is the only data change",
    source_reference = "PFMC 2025 report section 5; 2023 model archive"))
assumption_2025_inherited <- assumption_2023
assumption_2025_inherited$assessment_id <- assessment_2025
assumption_2025_inherited$source_reference <- paste(
  assumption_2025_inherited$source_reference,
  "PFMC 2025 report section 5 confirms the non-catch model settings were retained.")
assumption_2025_inherited$notes <- paste(
  assumption_2025_inherited$notes,
  "Inherited from the 2023 benchmark; PFMC 2025 report section 5 states that only the catch time series changed.")
assumption_data <- rbind(assumption_2023, assumption_2025_inherited,
  assumption_2025)
report_lines <- readLines(report_file, warn = FALSE)
read_report_table <- function(marker) {
  idx <- grep(marker, report_lines, perl = TRUE)
  if (!length(idx)) stop("Missing Report.sso table: ", marker, call. = FALSE)
  start <- tail(idx, 1L)
  rows <- list()
  started <- FALSE
  for (i in seq.int(start + 1L, length(report_lines))) {
    line <- trimws(report_lines[i])
    if (!nzchar(line)) {
      if (started) break
      next
    }
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (length(fields) < 2L || !grepl("^[0-9]+$", fields[1L])) {
      if (started) break
      next
    }
    started <- TRUE
    rows[[length(rows) + 1L]] <- fields
  }
  if (!length(rows)) stop("No data in Report.sso table: ", marker,
    call. = FALSE)
  rows
}
make_surface_output <- function(marker, years_at, era_at, ages_at,
  measure, type, unit, note, time_at = NULL, time_value = NULL) {
  rows <- read_report_table(marker)
  out <- list()
  for (fields in rows) {
    if (length(fields) < ages_at + 8L) next
    year <- suppressWarnings(as.integer(fields[years_at]))
    if (is.na(year) || year < 2008L || year > 2021L ||
        fields[era_at] != "TIME") next
    if (!is.null(time_at) && fields[time_at] != time_value) next
    values <- suppressWarnings(as.numeric(fields[ages_at:(ages_at + 8L)]))
    if (length(values) != 9L || anyNA(values))
      stop("Invalid age surface in Report.sso: ", marker, call. = FALSE)
    out[[length(out) + 1L]] <- make_output(9L,
      assessment_id = assessment_2023, type = type, measure = measure,
      sex = "model sex 1", year = year, age = 0:8, value = values,
      unit = unit, source_type = "native_model",
      source_reference = paste("2023 SS3 Report.sso", marker),
      notes = paste(note, "Age 8 is the 8+ group; point estimates only, no age-specific SE reported."))
  }
  if (!length(out)) stop("No historical rows in Report.sso table: ", marker,
    call. = FALSE)
  do.call(rbind, out)
}
numbers_output <- make_surface_output("NUMBERS_AT_AGE report:35",
  years_at = 8L, era_at = 12L, ages_at = 13L,
  measure = "numbers_at_age", type = "population",
  unit = "native SS3 abundance scale",
  note = "Beginning-of-model-year population numbers.",
  time_at = 11L, time_value = "B")
biomass_output <- make_surface_output("BIOMASS_AT_AGE report:36",
  years_at = 8L, era_at = 12L, ages_at = 13L,
  measure = "biomass_at_age", type = "biomass", unit = "mt",
  note = "Beginning-of-model-year biomass at age.",
  time_at = 11L, time_value = "B")
f_output <- make_surface_output("F_AT_AGE report:39",
  years_at = 5L, era_at = 7L, ages_at = 8L,
  measure = "fishing_mortality_at_age", type = "mortality",
  unit = "per year", note = "Annual instantaneous fishing mortality.")
m_output <- make_surface_output("Natural_Mortality report:43",
  years_at = 8L, era_at = 12L, ages_at = 13L,
  measure = "natural_mortality_at_age", type = "mortality",
  unit = "per year", note = "Beginning-of-model-year natural mortality at age.",
  time_at = 11L, time_value = "B")

time_series <- read_report_table("TIME_SERIES report:16")
time_rows <- lapply(time_series, function(fields) {
  if (length(fields) < 8L) return(NULL)
  year <- suppressWarnings(as.integer(fields[2L]))
  if (is.na(year) || year < 2008L || year > 2021L || fields[3L] != "TIME")
    return(NULL)
  c(year = year, ssb = suppressWarnings(as.numeric(fields[7L])),
    recruitment = suppressWarnings(as.numeric(fields[8L])))
})
time_rows <- Filter(Negate(is.null), time_rows)
time_values <- as.data.frame(do.call(rbind, time_rows), stringsAsFactors = FALSE)
if (nrow(time_values) != 14L || anyNA(time_values))
  stop("Unexpected 2023 TIME_SERIES coverage.", call. = FALSE)
ssb_output <- make_output(nrow(time_values), assessment_id = assessment_2023,
  type = "biomass", measure = "SSB", year = as.integer(time_values$year),
  value = as.numeric(time_values$ssb), unit = "mt",
  source_type = "native_model",
  source_reference = "2023 SS3 Report.sso TIME_SERIES report:16",
  notes = "SpawnBio point estimate; follows the source model's maturity/fecundity definition. No annual uncertainty is tabulated.")
recruitment_output <- make_output(nrow(time_values),
  assessment_id = assessment_2023, type = "recruitment", measure = "recruitment",
  year = as.integer(time_values$year), value = as.numeric(time_values$recruitment),
  unit = "native SS3 abundance scale", source_type = "native_model",
  source_reference = "2023 SS3 Report.sso TIME_SERIES report:16",
  notes = "Recruit_0 point estimate; native SS3 scale retained. No annual uncertainty is tabulated.")
parameter_output <- make_output(1L, assessment_id = assessment_2023,
  type = "parameter", measure = "NatM_Lorenzen_averageFem_GP_1",
  value = 0.8512, se = 0.1074, unit = "per year",
  source_type = "official_table",
  source_reference = "PFMC 2023 assessment Table 10, p. 35",
  notes = "Estimated average natural-mortality parameter; SE is on the reported scale.")
output_2023 <- rbind(numbers_output, biomass_output, f_output, m_output,
  ssb_output, recruitment_output, parameter_output)

biomass_year <- 2020:2026
biomass_value <- c(69823, 50282, 45898, 51060, 58301, 61737, 67954)
biomass_2025 <- make_output(length(biomass_year),
  assessment_id = assessment_2025, type = "biomass",
  measure = "biomass_by_age_group", age_group = "1+",
  year = biomass_year, value = biomass_value, unit = "mt",
  source_type = "official_table",
  source_reference = "PFMC 2025 catch-only assessment Table 5, p. 13",
  notes = "Reported age-1+ summary biomass; rounded to nearest mt. Years 2023 onward are described as highly uncertain.")
biomass_sd_2025 <- make_output(2L, assessment_id = assessment_2025,
  type = "biomass", measure = "biomass_standard_deviation",
  age_group = "1+", year = c(2025L, 2026L),
  value = c(41422, 43375), unit = "mt",
  source_type = "official_document",
  source_reference = "PFMC 2025 catch-only assessment section 6, p. 6",
  notes = "Source explicitly reports standard deviations (SD), not standard errors; stored as a separate output measure.")
output_2025 <- rbind(biomass_2025, biomass_sd_2025)
output_data <- rbind(output_2023, output_2025)

stock_data <- make_stock(
  stock_id = stock_id,
  authority = "NOAA-SWFSC",
  authority_stock_id = "10163",
  scientific_name = "Scomber japonicus",
  common_name = "Pacific chub mackerel, Pacific Coast",
  area = "Pacific Coast north of Punta Abreojos, Baja California",
  region = "Northeast Pacific Coast",
  ocean = "Northeast Pacific",
  notes = paste(
    "NOAA-managed Pacific Coast stock unit; the biological population is transboundary.",
    "The PFMC assessment covers the U.S. management unit north of Punta Abreojos."))

source_url <- function(id) {
  row <- source_manifest[source_manifest$source_id == id, , drop = FALSE]
  if (nrow(row) != 1L) stop("Missing source manifest row: ", id, call. = FALSE)
  as.character(row$url[[1L]])
}

assessment_data <- rbind(
  make_assessment(
    assessment_id = assessment_2023, stock_id = stock_id,
    assessment_year = 2023L, terminal_year = 2021L,
    estimate_terminal_year = 2021L, assessment_type = "benchmark",
    model_family = "Stock Synthesis", model_version = "3.30.20",
    is_current = "FALSE", is_applied = "TRUE", framework_year = 2023L,
    assessment_url = source_url("pfmc_2023_benchmark_assessment"),
    framework_url = source_url("pfmc_2023_benchmark_assessment"),
    model_url = source_url("pfmc_2023_model_files"),
    assumptions_status = "partial", inputs_status = "partial",
    outputs_status = "partial",
    notes = "Detailed benchmark fit for model years 2008-2021. It is retained as the source of detailed population outputs and the non-catch inputs inherited by the current 2025 catch-only update."),
  make_assessment(
    assessment_id = assessment_2025, stock_id = stock_id,
    assessment_year = 2025L, terminal_year = 2023L,
    estimate_terminal_year = 2026L, assessment_type = "catch_only_update",
    model_family = "Stock Synthesis", model_version = "2025 catch-only update based on the 2023 benchmark; native run files not located",
    is_current = "TRUE", is_applied = "TRUE", framework_year = 2023L,
    assessment_url = source_url("pfmc_2025_catch_only_assessment"),
    framework_url = source_url("pfmc_2023_benchmark_assessment"),
    model_url = NA_character_,
    assumptions_status = "partial", inputs_status = "partial",
    outputs_status = "partial",
    notes = "Current assessment used for advice. Updated catch series through 2023; 2024-2026 catches are forecasts. The report states non-catch data and model structure were retained from the 2023 benchmark. Only age-1+ biomass and its reported SD are available as numerical population outputs for this run."))

database_table <- function(name) read_csv(file.path(database, name))
existing_assessments <- database_table("assessments.csv")
existing_stocks <- database_table("stocks.csv")
if (any(existing_stocks$stock_id == stock_id, na.rm = TRUE) ||
    any(existing_assessments$assessment_id %in% c(assessment_2023,
      assessment_2025), na.rm = TRUE))
  stop("Pacific chub mackerel stock or assessment records already exist.",
    call. = FALSE)

candidates_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read_csv(candidates_path)
candidate_i <- which(candidates$candidate_id == candidate_id)
if (length(candidate_i) != 1L ||
    candidates$eligibility[candidate_i] != "eligible" ||
    !candidates$import_status[candidate_i] %in% c("not_started", "partial"))
  stop("Candidate register no longer matches the selected source case.",
    call. = FALSE)

candidate <- candidates[candidate_i, , drop = FALSE]
candidate$matched_stock_id <- stock_id
candidate$match_status <- "matched"
candidate$import_status <- "partial"
candidate$catch_age_evidence <- paste(
  "The 2025 catch-only assessment reports catch biomass through model year 2023 and forecasts through 2026.",
  "The inherited 2023 benchmark uses aggregate catch biomass plus fishery age compositions for 2008-2021; the source inputs support those records but are not direct catch numbers-at-age.")
candidate$survey_age_evidence <- paste(
  "The inherited 2023 benchmark fits a summer Acoustic-Trawl biomass index and survey age compositions for model years 2008-2021.",
  "The native model data give index timing as month 1.6; the report states that non-catch observations were unchanged in 2025.")
candidate$weights_evidence <- paste(
  "The native model archive provides fishery, survey, and population weight-at-age for ages 0-8+ in model years 2008-2021.",
  "Survey weight-at-age is retained as supplied; it is not represented as an index conversion factor.")
candidate$maturity_evidence <- paste(
  "The native archive contains a maturity*fecundity surface, while the control/report identifies the maturity option as disabled.",
  "PFMC 2023 Table 9 sample-based maturity estimates are not treated as fitted maturity inputs.")
candidate$mortality_evidence <- paste(
  "The 2023 model reports a Lorenzen age pattern and estimates the average M parameter under a longevity-based prior.",
  "The 2025 update retains the benchmark model settings.")
candidate$timing_evidence <- paste(
  "The model year runs July-June. The summer Acoustic-Trawl index is at native model month 1.6, equivalent to 0.05 of the model year.",
  "Fishery age compositions are sampled in model month 7 (0.5 of the model year).")
candidate$output_evidence <- paste(
  "The 2023 benchmark Report.sso provides N-at-age, biomass-at-age, F-at-age, M-at-age, SSB, and recruitment for 2008-2021.",
  "The current 2025 update reports age-1+ biomass for 2020-2026 and SD for 2025-2026; run-matched age surfaces and their uncertainty were not located.")
candidate$notes <- paste(
  "The 2025 update is the current advice run and changes the catch series only from the 2023 benchmark.",
  "The native composition data use the combined-sex code; the fitted SS3 output contains one model sex, ages 0-8+, one fishery and one Acoustic-Trawl survey.")
candidate$review_date <- format(Sys.Date(), "%Y-%m-%d")

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- read_csv(inventory_path)
inventory_i <- candidate_inventory_row(inventory, candidate_id, stock_id)
inventory$matched_stock_id[inventory_i] <- stock_id
inventory$match_status[inventory_i] <- "matched"
inventory$import_status[inventory_i] <- "partial"

selected_path <- file.path(root, "discovery", "selected_batch_23_2026.csv")
selected <- read_csv(selected_path)
selected_i <- which(selected$candidate_id == candidate_id)
if (length(selected_i) != 1L ||
    !selected$curation_status[selected_i] %in% c("not_started", "imported"))
  stop("Selected batch register no longer matches this source import.",
    call. = FALSE)
selected$curation_status[selected_i] <- "imported"

extracted_files <- list.files(model_files, recursive = TRUE, full.names = TRUE)
extracted_files <- extracted_files[!dir.exists(extracted_files)]
if (!length(extracted_files)) stop("No extracted native model files found.",
  call. = FALSE)
archive_sha <- source_manifest$sha256[
  match("pfmc_2023_model_files", source_manifest$source_id)]
extracted_manifest <- data.frame(
  assessment_id = assessment_2023,
  source_id = "pfmc_2023_model_files",
  archive_sha256 = archive_sha,
  file = substring(normalizePath(extracted_files, winslash = "/", mustWork = TRUE),
    nchar(normalizePath(model_files, winslash = "/", mustWork = TRUE)) + 2L),
  sha256 = vapply(extracted_files, sha256_file, character(1L)),
  bytes = as.numeric(file.info(extracted_files)$size),
  stringsAsFactors = FALSE)

cat("Pacific chub mackerel records prepared:\n")
cat("  assessments:", nrow(assessment_data), "\n")
cat("  inputs by assessment:\n")
print(table(input_data$assessment_id))
cat("  inputs by type and measure:\n")
print(with(input_data, table(type, measure)))
cat("  outputs by assessment:\n")
print(table(output_data$assessment_id))

if (!dry_run) {
  append_csv_rows <- function(path, rows) {
    connection <- file(path, open = "at", encoding = "UTF-8")
    on.exit(close(connection), add = TRUE)
    utils::write.table(rows, connection, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, quote = TRUE, na = "",
      qmethod = "double")
  }
  replace_register_record <- function(path, row_index, row, key) {
    bytes <- readBin(path, "raw", n = file.info(path)$size)
    bounds <- csv_record_bounds(bytes)
    record_index <- as.integer(row_index) + 1L
    if (record_index < 2L || record_index > length(bounds$start))
      stop("Register row index is out of range: ", path, call. = FALSE)
    old_record <- rawToChar(bytes[bounds$start[record_index]:bounds$end[record_index]])
    if (!grepl(paste0('"', key, '"'), old_record, fixed = TRUE))
      stop("Register row identity does not match: ", key, call. = FALSE)
    temporary <- tempfile(fileext = ".csv")
    on.exit(unlink(temporary), add = TRUE)
    utils::write.table(row, temporary, sep = ",", row.names = FALSE,
      col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
      eol = "\n")
    replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
    if (length(replacement) && tail(replacement, 1L) == as.raw(10L))
      replacement <- replacement[-length(replacement)]
    if (length(replacement) && tail(replacement, 1L) == as.raw(13L))
      replacement <- replacement[-length(replacement)]
    first <- bounds$start[record_index]
    last <- bounds$end[record_index]
    next_byte <- last + 1L
    has_carriage_return <- FALSE
    while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
      has_carriage_return <- TRUE
      next_byte <- next_byte + 1L
    }
    if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
      replacement <- c(replacement,
        if (has_carriage_return) as.raw(c(13L, 10L)) else as.raw(10L))
      last <- next_byte
    }
    before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
    after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
    writeBin(c(before, replacement, after), path)
  }
  append_csv_rows(file.path(database, "stocks.csv"), stock_data)
  append_csv_rows(file.path(database, "assessments.csv"), assessment_data)
  append_csv_rows(file.path(database, "assumptions.csv"), assumption_data)
  append_csv_rows(file.path(database, "inputs.csv"), input_data)
  append_csv_rows(file.path(database, "outputs.csv"), output_data)
  replace_candidate_register_row(candidates_path, candidate_i, candidate,
    candidate_id)
  replace_register_record(inventory_path, inventory_i, inventory[inventory_i,
    , drop = FALSE], candidate_id)
  replace_register_record(selected_path, selected_i, selected[selected_i,
    , drop = FALSE], candidate_id)
  write.csv(extracted_manifest, file.path(root, "provenance",
    "noaa_pacific_mackerel_2023_model_files.csv"), row.names = FALSE,
    na = "", fileEncoding = "UTF-8")
  cat("Database and discovery registers updated.\n")
} else {
  cat("Dry run: no canonical database or discovery files were changed.\n")
}
