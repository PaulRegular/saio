root <- "."
cache <- file.path(root, "source_cache", "discovery_noaa_anchovy_2021")
manifest_path <- file.path(root, "provenance", "discovery_noaa_anchovy_2021", "sources.csv")
assessment_id <- "noaa_northern_anchovy_central_subpopulation_2021"
stock_id <- "noaa_northern_anchovy_central_subpopulation"
candidate_id <- "NOAA:10574"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

local_lib <- file.path(root, "source_cache", "r-lib")
if (dir.exists(local_lib)) .libPaths(c(local_lib, .libPaths()))
if (!requireNamespace("r4ss", quietly = TRUE) ||
    !requireNamespace("pdftools", quietly = TRUE)) {
  stop("The cached r4ss and pdftools packages are required.", call. = FALSE)
}
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))
read_csv <- function(path, ... ) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), ...)
sha256_file <- function(path) {
  value <- tools::sha256sum(path)
  if (length(value) != 1L || is.na(value)) stop("Could not hash ", path, call. = FALSE)
  tolower(unname(value))
}
manifest <- read_csv(manifest_path)
verify_source <- function(relative_path) {
  record <- manifest[manifest$file == relative_path, , drop = FALSE]
  path <- file.path(cache, relative_path)
  if (nrow(record) != 1L || !file.exists(path) ||
      !identical(tolower(record$sha256), sha256_file(path))) {
    stop("Cached source differs from provenance: ", relative_path, call. = FALSE)
  }
  path
}
report_path <- verify_source("noaa_2021_central_anchovy_assessment.pdf")
archive_path <- verify_source("pfmc_anchovy_2021_model_files.zip")
invisible(verify_source("noaa_northern_anchovy_status.html"))
model_dir <- file.path(cache, "pfmc_anchovy_2021_model_files")
data_path <- file.path(model_dir, "anchovy2021.dat")
control_path <- file.path(model_dir, "anchovy2021.ctl")
starter_path <- file.path(model_dir, "starter.ss")
forecast_path <- file.path(model_dir, "forecast.ss")
wtatage_path <- file.path(model_dir, "wtatage.ss")
for (path in c(data_path, control_path, starter_path, forecast_path, wtatage_path)) {
  relative <- paste0("pfmc_anchovy_2021_model_files/", basename(path))
  verify_source(relative)
}
dat <- r4ss::SS_readdat(data_path, verbose = FALSE)
pages <- pdftools::pdf_text(report_path)
if (dat$styr != 2015L || dat$endyr != 2021L || dat$nseas != 2L ||
    dat$Nsexes != 1L || dat$Nages != 3L ||
    !identical(as.character(dat$fleetinfo$fleetname),
      c("MexCal_S1", "MexCal_S2", "AT_summer", "CalCOFI",
        "RREAS_YOY", "CalCOFI_eggs", "AT_spring"))) {
  stop("The native Stock Synthesis dimensions or fleet labels changed.", call. = FALSE)
}
number <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}
parse_state_table <- function(page, n_values) {
  rows <- list()
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (length(tokens) != n_values + 2L ||
        !grepl("^20[0-9]{2}-[12]$", tokens[1L]) ||
        !grepl("^20[0-9]{2}-[12]$", tokens[2L])) next
    values <- number(tokens[seq.int(3L, length(tokens))])
    if (anyNA(values)) next
    rows[[length(rows) + 1L]] <- c(tokens[1:2], as.character(values))
  }
  if (!length(rows)) stop("No source state rows parsed on PDF page ", page, call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("calendar_state", "model_state", paste0("v", seq_len(n_values)))
  for (name in paste0("v", seq_len(n_values))) out[[name]] <- as.numeric(out[[name]])
  out
}
parse_annual_table <- function(page, n_values, years) {
  rows <- list()
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (length(tokens) != n_values + 1L ||
        !grepl("^[0-9]{4}$", tokens[1L]) ||
        !as.integer(tokens[1L]) %in% years) next
    values <- number(tokens[-1L])
    if (anyNA(values)) next
    rows[[length(rows) + 1L]] <- c(tokens[1L], as.character(values))
  }
  if (!length(rows)) stop("No annual source rows parsed on PDF page ", page, call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", paste0("v", seq_len(n_values)))
  out$year <- as.integer(out$year)
  for (name in paste0("v", seq_len(n_values))) out[[name]] <- as.numeric(out[[name]])
  out
}
state_parts <- function(x) {
  pieces <- strsplit(x, "-", fixed = TRUE)
  data.frame(year = as.integer(vapply(pieces, function(z) z[[1L]], character(1L))),
    season = as.integer(vapply(pieces, function(z) z[[2L]], character(1L))))
}
table11 <- parse_state_table(51L, 4L)
table12 <- parse_state_table(51L, 6L)
table13 <- parse_state_table(52L, 4L)
table14 <- parse_annual_table(52L, 2L, 2015:2021)
table15 <- parse_annual_table(53L, 3L, 2015:2021)
if (nrow(table11) != 14L || nrow(table12) != 14L ||
    nrow(table13) != 16L || nrow(table14) != 7L || nrow(table15) != 7L) {
  stop("Published output table coverage differs from the expected run.", call. = FALSE)
}
input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference, notes,
  year = NA_real_, year_basis = NULL, age = NA_real_, fleet = NA_character_,
  survey = NA_character_, season = NA_character_, sampling_time = NA_real_,
  sex = "single modeled sex", age_error = NA_real_, partition = NA_character_,
  observation_id = NA_character_, sample_size = NA_real_,
  length_bin = NA_real_, source_type = "native_model", transformation = "") {
  n <- length(value)
  years <- rep_len(year, n)
  if (is.null(year_basis)) {
    year_basis <- if (all(is.na(years))) rep(NA_character_, n) else "calendar_year"
  }
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs",
    n = n, assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = sex,
    region = "Central subpopulation", season = season, year = years,
    year_basis = year_basis, age = age, value = as.numeric(value), unit = unit,
    sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    sample_size = sample_size, age_error = age_error, partition = partition)
}
output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
  year = NA_real_, age = NA_real_, age_group = NA_character_,
  fleet = NA_character_, survey = NA_character_, season = NA_character_,
  scenario = NA_character_, se = NA_real_, source_type = "official_table") {
  n <- length(value)
  keep <- is.finite(value)
  if (!any(keep)) return(invisible(NULL))
  at <- function(x) rep_len(x, n)[keep]
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs",
    n = sum(keep), assessment_id = assessment_id, type = type,
    measure = measure, fleet = at(fleet), survey = at(survey),
    region = "Central subpopulation", season = at(season), year = at(year),
    age = at(age), age_group = at(age_group), scenario = at(scenario),
    value = as.numeric(value[keep]), se = at(se), unit = unit,
    source_type = source_type, source_reference = source_reference,
    notes = notes)
}
assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row(
    "assumptions", assessment_id = assessment_id, component = component,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes)
}
native_data_ref <- "PFMC Stock Synthesis 2021 input archive, anchovy2021.dat"
for (i in seq_len(nrow(dat$catch))) {
  x <- dat$catch[i, ]
  year <- if (x$year == -999L) NA_real_ else as.numeric(x$year)
  basis <- if (is.na(year)) NA_character_ else "calendar_year"
  obs <- if (is.na(year)) paste0("SS3_initialization_year_-999_season_", x$seas,
    "_fleet_", x$fleet) else NA_character_
  fleet <- dat$fleetinfo$fleetname[x$fleet]
  note <- if (is.na(year)) {
    "Native SS3 year=-999 equilibrium-initialization catch placeholder; not a calendar-year likelihood observation."
  } else {
    "Native semester catch observation. Catch units code 1 is metric tonnes; model season 1 covers June-December and season 2 January-May."
  }
  add_input("catch", "catch_biomass", "biomass", x$catch, "metric tonnes",
    native_data_ref, note, year = year, year_basis = basis,
    fleet = fleet, season = paste0("model season ", x$seas),
    observation_id = obs)
  add_input("catch", "catch_se", "relative_scale", x$catch_se, "ratio",
    native_data_ref, paste(note, "The native catch_se value is preserved without conversion."),
    year = year, year_basis = basis, fleet = fleet,
    season = paste0("model season ", x$seas), observation_id = obs)
}

index_type <- dat$CPUEinfo$units[match(dat$CPUE$index, dat$CPUEinfo$fleet)]
index_fleet <- dat$fleetinfo$fleetname[dat$CPUE$index]
index_measure <- ifelse(index_type == 33L, "recruitment_index",
  ifelse(index_type == 0L, "relative_abundance_index", "relative_biomass_index"))
base_index <- dat$CPUE$index %in% c(3L, 7L)
for (i in seq_len(nrow(dat$CPUE))) {
  x <- dat$CPUE[i, ]
  is_fishery <- dat$fleetinfo$type[x$index] == 1L
  shared <- list(year = x$year, year_basis = "calendar_year",
    season = paste0("source time code ", x$month),
    fleet = if (is_fishery) index_fleet[i] else NA_character_,
    survey = if (!is_fishery) index_fleet[i] else NA_character_,
    observation_id = paste0("SS3_CPUE_row_", i))
  code_note <- paste0("Native SS3 index-unit code ", index_type[i],
    "; source time code ", x$month, ".")
  likelihood_note <- if (base_index[i]) {
    "This is one of the two acoustic-trawl indices (AT summer and AT spring) used in the base-model likelihood."
  } else {
    "Preserved from the native data file; this series is an alternative or supporting index and is not in the base-model likelihood."
  }
  common <- c(list(type = "index", basis = "index_scale"),
    shared)
  do.call(add_input, c(common, list(measure = index_measure[i],
    value = x$obs, unit = "native index units",
    source_reference = native_data_ref,
    notes = paste(code_note, likelihood_note,
      "The exact within-year sampling fraction was not reported in reviewed sources."),
    sampling_time = NA_real_)))
  do.call(add_input, c(common, list(measure = "log_index_sd",
    value = x$se_log, unit = "log units",
    source_reference = native_data_ref,
    notes = paste(code_note, "Native se_log value; no transformation."),
    sampling_time = NA_real_)))
}

age_columns <- paste0("a", 0:3)
age <- 0:3
for (i in seq_len(nrow(dat$agecomp))) {
  x <- dat$agecomp[i, ]
  fleet_id <- x$fleet
  fleet_name <- dat$fleetinfo$fleetname[fleet_id]
  fishery <- dat$fleetinfo$type[fleet_id] == 1L
  observation_id <- paste0("SS3_agecomp_row_", i, "_", fleet_name,
    "_", x$year, "_month_", x$month)
  do.call(add_input, list(
    type = if (fishery) "catch" else "index",
    measure = "proportion_at_age", basis = "proportion_numbers",
    value = as.numeric(unlist(x[age_columns], use.names = FALSE)), unit = "proportion",
    source_reference = native_data_ref,
    notes = paste0("Native age composition; SS3 month code ", x$month,
      ", part code ", x$part, ", and age-error definition ", x$ageerr,
      ". Supplied Nsamp is retained in sample_size; age 3 is the 3+ group."),
    year = x$year, year_basis = "calendar_year", age = age,
    fleet = if (fishery) fleet_name else NA_character_,
    survey = if (!fishery) fleet_name else NA_character_,
    season = paste0("source month ", x$month),
    age_error = x$ageerr, partition = as.character(x$part),
    observation_id = observation_id, sample_size = x$Nsamp))
}

length_columns <- grep("^l[0-9]", names(dat$lencomp), value = TRUE)
length_bins <- as.numeric(sub("^l", "", length_columns))
if (length(length_columns) != 27L || anyNA(length_bins)) {
  stop("Unexpected native length-composition bins.", call. = FALSE)
}
for (i in seq_len(nrow(dat$lencomp))) {
  x <- dat$lencomp[i, ]
  fleet_id <- abs(x$fleet)
  fleet_name <- dat$fleetinfo$fleetname[fleet_id]
  fishery <- dat$fleetinfo$type[fleet_id] == 1L
  observation_id <- paste0("SS3_lencomp_row_", i, "_native_fleet_", x$fleet,
    "_", x$year, "_month_", x$month)
  note <- paste0("Native length composition; SS3 month code ", x$month,
    ", part code ", x$part, ". The source fleet code is ", x$fleet, ".")
  if (x$fleet < 0L) {
    note <- paste(note, "A negative native fleet code excludes this composition from the likelihood; it is retained as supplied.")
  }
  do.call(add_input, list(
    type = if (fishery) "catch" else "index",
    measure = "proportion_at_length", basis = "proportion_numbers",
    value = as.numeric(unlist(x[length_columns], use.names = FALSE)), unit = "proportion",
    source_reference = native_data_ref, notes = note,
    year = x$year, year_basis = "calendar_year",
    fleet = if (fishery) fleet_name else NA_character_,
    survey = if (!fishery) fleet_name else NA_character_,
    season = paste0("source month ", x$month),
    partition = as.character(x$part), observation_id = observation_id,
    sample_size = x$Nsamp, length_bin = length_bins))
}

wt_lines <- readLines(wtatage_path, warn = FALSE)
wt_rows <- list()
for (line in wt_lines) {
  tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
  if (length(tokens) != 10L) next
  values <- number(tokens)
  if (anyNA(values) || values[1L] != as.integer(values[1L]) || values[1L] == -9999) next
  wt_rows[[length(wt_rows) + 1L]] <- values
}
if (length(wt_rows) != 460L) stop("Unexpected number of native wtatage rows.", call. = FALSE)
wt <- as.data.frame(do.call(rbind, wt_rows), stringsAsFactors = FALSE)
names(wt) <- c("year", "season", "sex_code", "growth_pattern",
  "birth_season", "fleet_code", paste0("age", 0:3))
for (i in seq_len(nrow(wt))) {
  x <- wt[i, ]
  fleet_name <- if (x$fleet_code > 0L) {
    dat$fleetinfo$fleetname[x$fleet_code]
  } else NA_character_
  if (x$fleet_code == -2L) {
    type <- "biology"
    measure <- "maturity_fecundity_at_age"
    basis <- "kg_per_fish"
    unit <- "kg per fish"
    note <- "Native Stock Synthesis fleet -2 row, labelled maturity*fecundity; this product is not a maturity proportion. Age 3 is the 3+ group."
  } else if (x$fleet_code == -1L) {
    type <- "weight"
    measure <- "weight_at_age"
    basis <- "kg_per_fish"
    unit <- "kg per fish"
    note <- "Native Stock Synthesis fleet -1 mid-season population weight-at-age. Age 3 is the 3+ group."
  } else if (x$fleet_code == 0L) {
    type <- "weight"
    measure <- "start_weight_at_age"
    basis <- "kg_per_fish"
    unit <- "kg per fish"
    note <- "Native Stock Synthesis fleet 0 beginning-season population weight-at-age. Age 3 is the 3+ group."
  } else if (x$fleet_code %in% c(1L, 2L)) {
    type <- "catch_weight"
    measure <- "catch_weight_at_age"
    basis <- "kg_per_fish"
    unit <- "kg per fish"
    note <- "Native fishery-specific weight-at-age used by Stock Synthesis. Age 3 is the 3+ group."
  } else {
    type <- "weight"
    measure <- "weight_at_age"
    basis <- "kg_per_fish"
    unit <- "kg per fish"
    note <- "Native survey-specific weight-at-age used by Stock Synthesis. Age 3 is the 3+ group."
  }
  do.call(add_input, list(type = type, measure = measure, basis = basis,
    value = as.numeric(unlist(x[paste0("age", 0:3)], use.names = FALSE)), unit = unit,
    source_reference = "PFMC Stock Synthesis 2021 input archive, wtatage.ss",
    notes = paste(note, "Native sex code", x$sex_code, "growth pattern",
      x$growth_pattern, "and birth season", x$birth_season, "are preserved in observation_id."),
    year = x$year, year_basis = "model_year", age = age,
    fleet = fleet_name, season = paste0("model season ", x$season),
    observation_id = paste0("wtatage_y", x$year, "_s", x$season,
      "_sex", x$sex_code, "_gp", x$growth_pattern,
      "_birth", x$birth_season, "_fleet", x$fleet_code)))
}

control_lines <- readLines(control_path, warn = FALSE)
maturity_line <- grep("maturity_option", control_lines, fixed = TRUE)
if (length(maturity_line) != 1L) stop("Could not locate maturity parameters.", call. = FALSE)
maturity <- scan(text = sub("#.*$", "", control_lines[maturity_line + 1L]),
  what = numeric(), quiet = TRUE)
if (length(maturity) != 4L || any(maturity < 0 | maturity > 1)) {
  stop("Unexpected fixed maturity-at-age vector.", call. = FALSE)
}
for (i in seq_along(age)) {
  add_input("maturity", "maturity_at_age", "proportion", maturity[i],
    "proportion", "PFMC Stock Synthesis 2021 input archive, anchovy2021.ctl",
    "Fixed one-sex maturity-at-age input; age 3 is the 3+ group.",
    age = age[i])
}

age_error <- as.matrix(dat$ageerror)
age_error_mean <- age_error[seq(1L, nrow(age_error), by = 2L), , drop = FALSE]
age_error_sd <- age_error[seq(2L, nrow(age_error), by = 2L), , drop = FALSE]
if (nrow(age_error_mean) != 6L || ncol(age_error_mean) != 4L ||
    any(!is.finite(age_error))) stop("Unexpected age-error definitions.", call. = FALSE)
for (definition in seq_len(6L)) {
  for (j in seq_along(age)) {
    add_input("biology", "age_error_mean_age", "native_scale",
      age_error_mean[definition, j], "years",
      native_data_ref, "Source mean-age vector for this SS3 age-error definition; not a transition probability.",
      age = age[j], age_error = definition,
      observation_id = paste0("SS3_age_error_definition_", definition, "_mean"))
    add_input("biology", "ageing_error_sd", "age_error_sd",
      age_error_sd[definition, j], "years",
      native_data_ref, "Source standard-deviation vector paired with the mean-age vector for this SS3 age-error definition.",
      age = age[j], age_error = definition,
      observation_id = paste0("SS3_age_error_definition_", definition, "_sd"))
  }
}
output_reference <- function(table, printed_page, description) {
  paste0("PFMC 2021 Northern anchovy assessment, Table ", table,
    ", printed p. ", printed_page, "; PDF p. ", printed_page + 17L,
    " (", description, ")")
}
state11 <- state_parts(table11$model_state)
add_output("population", "numbers_at_age",
  as.vector(t(as.matrix(table11[paste0("v", 1:4)]))), "1,000 fish",
  output_reference(11L, 34L, "model year-season abundance"),
  paste0("Source-reported numbers-at-age. Model Y-S ",
    rep(table11$model_state, each = 4L), " corresponds to calendar Y-S ",
    rep(table11$calendar_state, each = 4L), "; age 3 is the 3+ group."),
  year = rep(state11$year, each = 4L), season = rep(state11$season, each = 4L),
  age = rep(age, times = nrow(table11)),
  age_group = rep(c(NA_character_, NA_character_, NA_character_, "3+"),
    times = nrow(table11)), scenario = "Base-run estimate")

state12 <- state_parts(table12$model_state)
add_output("biomass", "biomass_at_age",
  as.vector(t(as.matrix(table12[paste0("v", 1:4)]))), "metric tonnes",
  output_reference(12L, 34L, "model year-season biomass"),
  paste0("Source-reported biomass-at-age. Model Y-S ",
    rep(table12$model_state, each = 4L), " corresponds to calendar Y-S ",
    rep(table12$calendar_state, each = 4L), "; age 3 is the 3+ group."),
  year = rep(state12$year, each = 4L), season = rep(state12$season, each = 4L),
  age = rep(age, times = nrow(table12)),
  age_group = rep(c(NA_character_, NA_character_, NA_character_, "3+"),
    times = nrow(table12)), scenario = "Base-run estimate")
add_output("biomass", "biomass_by_age_group",
  c(table12$v5, table12$v6), "metric tonnes",
  output_reference(12L, 34L, "age-0+ and age-1+ biomass"),
  "Source-reported biomass totals for the 0+ and 1+ groups at each model year-season.",
  year = rep(state12$year, times = 2L),
  season = rep(state12$season, times = 2L),
  age_group = c(rep("0+", nrow(table12)), rep("1+", nrow(table12))),
  scenario = "Base-run estimate")

state13 <- state_parts(table13$model_state)
ssb_rows <- table13$v1 > 0
recruit_rows <- table13$v3 > 0
scenario13 <- ifelse(state13$year <= 2021L, "Base-run estimate",
  "Base-model projection beyond terminal data year 2021")
add_output("biomass", "SSB", table13$v1[ssb_rows], "metric tonnes",
  output_reference(13L, 35L, "SSB and recruitment"),
  paste0("SSB is evaluated at the beginning of model season 2 (January). Calendar Y-S ",
    table13$calendar_state[ssb_rows], " maps to model Y-S ",
    table13$model_state[ssb_rows], "."),
  year = state13$year[ssb_rows], season = state13$season[ssb_rows],
  se = table13$v2[ssb_rows], scenario = scenario13[ssb_rows])
add_output("recruitment", "recruitment", table13$v3[recruit_rows], "1,000 fish",
  output_reference(13L, 35L, "SSB and recruitment"),
  paste0("Age-0 recruitment is evaluated at the beginning of model year (June). Calendar Y-S ",
    table13$calendar_state[recruit_rows], " maps to model Y-S ",
    table13$model_state[recruit_rows], "."),
  year = state13$year[recruit_rows], season = state13$season[recruit_rows],
  age = 0, se = table13$v4[recruit_rows], scenario = scenario13[recruit_rows])

add_output("biomass", "biomass_by_age_group",
  c(table14$v1, table14$v2), "metric tonnes",
  output_reference(14L, 35L, "June 1 annual biomass"),
  "Source-reported June 1 total biomass by age group.",
  year = rep(table14$year, times = 2L),
  age_group = c(rep("0+", nrow(table14)), rep("1+", nrow(table14))),
  scenario = "Base-run estimate")

fleet_names <- c("Mexico", "USA", "Total")
for (j in seq_along(fleet_names)) {
  add_output("management", "exploitation_rate", table15[[paste0("v", j)]],
    "proportion", output_reference(15L, 36L, "annual exploitation rate"),
    "Annual calendar-year landings divided by June total biomass; this is not instantaneous fishing mortality.",
    year = table15$year, fleet = fleet_names[j],
    scenario = "Base-run estimate")
}

parameter_lines <- strsplit(pages[[54L]], "\n", fixed = TRUE)[[1L]]
parameter_values <- function(label) {
  selected <- parameter_lines[grepl(label, parameter_lines, fixed = TRUE)]
  if (identical(label, "LnQ base AT spring(7)")) selected <- selected[!grepl("BLK6repl", selected, fixed = TRUE)]
  if (length(selected) != 1L) stop("Could not locate Table 16 row: ", label, call. = FALSE)
  tokens <- strsplit(trimws(selected), "[[:space:]]+")[[1L]]
  values <- number(tail(tokens, 8L))
  if (length(values) != 8L || anyNA(values)) stop("Malformed Table 16 row: ", label, call. = FALSE)
  values
}
base_column <- 4L
base_scenario <- "Base-model parameter estimate at steepness h=0.6"
add_output("parameter", "natural_mortality_average_parameter",
  parameter_values("NatM uniform Fem GP 1")[base_column], "per year",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Estimated uniform natural mortality for the base run (h=0.6); the report gives no SE for this parameter in the table.",
  scenario = base_scenario)
add_output("parameter", "log_q",
  parameter_values("LnQ base AT spring(7) BLK6repl 2020")[base_column], "log scale",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Estimated log catchability for the AT spring 2020 replacement block.",
  survey = "AT_spring", scenario = paste(base_scenario, "2020 block replacement"))
add_output("parameter", "log_q",
  parameter_values("LnQ base AT spring(7)")[base_column], "log scale",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Estimated base log catchability for the AT spring index.",
  survey = "AT_spring", scenario = base_scenario)
add_output("parameter", "log_q",
  parameter_values("LnQ base AT summer(3)")[base_column], "log scale",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Estimated base log catchability for the AT summer index.",
  survey = "AT_summer", scenario = base_scenario)
add_output("parameter", "log_R0",
  parameter_values("SR LN(R0)")[base_column], "log scale",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Estimated log unfished recruitment parameter in the base run.",
  scenario = base_scenario)
add_output("parameter", "recruitment_deviation",
  parameter_values("SR regime BLK1repl 2014")[base_column], "log scale",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Estimated 2014 recruitment-regime block replacement deviation in the base run.",
  year = 2014L, scenario = base_scenario)
add_output("diagnostic", "negative_log_likelihood",
  parameter_values("Total NLL")[base_column], "objective units",
  output_reference(16L, 37L, "steepness sensitivity"),
  "Total negative log likelihood for the base run, h=0.6.",
  scenario = base_scenario)

if (any(abs(rowSums(as.matrix(table12[paste0("v", 1:4)])) - table12$v5) > 5) ||
    any(abs(rowSums(as.matrix(table12[paste0("v", 2:4)])) - table12$v6) > 5)) {
  stop("Table 12 age-group totals do not reconcile within printed rounding.", call. = FALSE)
}
assumption_ref <- "PFMC 2021 Northern anchovy assessment, report and native Stock Synthesis files"
add_assumption("assessment", "run_identity",
  "Northern anchovy central subpopulation 2021 benchmark, adopted June 2022",
  assumption_ref,
  "NOAA Stock SMART 10574 uses the label Southern Pacific Coast; PFMC names the assessed subpopulation central. This is the latest detailed production run located.")
add_assumption("model", "model_dimensions",
  "Stock Synthesis 3.30; model years 2015-2021; two biological semesters; one sex, one area; ages 0, 1, 2 and 3+.",
  "PFMC 2021 assessment, Sections 2-3; native anchovy2021.dat header",
  "Biological semester 1 covers June-December and semester 2 January-May; birth date is June 1.")
add_assumption("catch", "catch_inputs",
  "Two pooled MexCal fishery fleets with seasonal biomass catches and catch_se=0.05.",
  "Native anchovy2021.dat",
  "The native file includes year=-999 equilibrium-initialization placeholders; these are preserved with blank calendar year and are not treated as observations.")
add_assumption("index", "base_model_indices",
  "The base model uses the acoustic-trawl summer and spring biomass indices.",
  "PFMC 2021 assessment, Sections 2.4 and 3; native anchovy2021.dat",
  "All seven index series present in the native data file are preserved; the other series are alternatives or supporting information, not base-run likelihood indices.")
add_assumption("composition", "composition_inputs",
  "Fishery and survey age proportions and length proportions are supplied in the Stock Synthesis data file.",
  "Native anchovy2021.dat; PFMC 2021 assessment, Sections 2.3-2.4",
  "Age 3 is a 3+ group. Supplied Nsamp values are retained, including fishery sample sizes divided by 25 and survey sample sizes weighted by positive trawl clusters. Negative length-composition fleet codes are retained but excluded from the likelihood.")
add_assumption("age_error", "age_error_definitions",
  "Six paired mean-age and standard-deviation vectors are supplied for ages 0, 1, 2 and 3+.",
  "Native anchovy2021.dat",
  "The source vectors are preserved separately; no transition probabilities are inferred.")
add_assumption("biology", "maturity_and_fecundity",
  paste0("Fixed maturity at ages 0, 1, 2 and 3+ is ",
    paste(maturity, collapse = ", "),
    "; the native wtatage file supplies maturity*fecundity and model weights."),
  "Native anchovy2021.ctl and wtatage.ss",
  "The native maturity*fecundity rows are not maturity proportions. Age 3 is a 3+ group.")
add_assumption("M", "natural_mortality",
  "Uniform natural mortality is estimated; the base-run estimate is 0.414 per year.",
  "PFMC 2021 assessment, Table 16, printed p. 37",
  "The report gives no age-specific M surface; no age-specific M values are created.")
add_assumption("timing", "survey_timing",
  "The native survey observations are assigned to model seasons; the exact within-year sampling fractions were not recovered.",
  "Native anchovy2021.dat; PFMC 2021 assessment, Sections 2.4 and 3.3",
  "sampling_time is left blank for survey observations rather than inferred from season codes.")
add_assumption("outputs", "population_output_timing",
  "Table 11 and 12 outputs are reported by calendar year-season and model year-season; Table 13 reports January SSB and June age-0 recruitment.",
  "PFMC 2021 assessment, Tables 11-14, printed pp. 34-35",
  "Both calendar and model year-season labels are retained in row notes; model year 2022 values are projections beyond the 2021 terminal data year.")
add_assumption("outputs", "fishing_mortality_output",
  "Apical fishing mortality by fishery is shown graphically; no numeric age-specific F table was located.",
  "PFMC 2021 assessment, model results",
  "No F-at-age series is transcribed or inferred. Table 15 exploitation rates are preserved as a separate source-defined metric.")

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
if (nrow(inputs) != 2828L || nrow(outputs) != 198L ||
    any(!is.finite(inputs$value)) || any(!is.finite(outputs$value))) {
  stop("Source rows failed expected dimensions or finite-value checks.", call. = FALSE)
}
age_prop <- inputs[inputs$measure == "proportion_at_age", ]
length_prop <- inputs[inputs$measure == "proportion_at_length", ]
age_sums <- tapply(age_prop$value, age_prop$observation_id, sum)
length_sums <- tapply(length_prop$value, length_prop$observation_id, sum)
if (nrow(age_prop) != 84L || nrow(length_prop) != 540L ||
    any(age_sums <= 0 | age_sums > 1.001) ||
    any(length_sums <= 0 | length_sums > 1.001) ||
    sum(inputs$measure == "age_error_mean_age") != 24L ||
    sum(inputs$measure == "ageing_error_sd") != 24L ||
    sum(inputs$measure == "maturity_at_age") != 4L ||
    sum(inputs$measure == "log_index_sd") != 64L ||
    sum(outputs$measure == "numbers_at_age") != 56L ||
    sum(outputs$measure == "fishing_mortality_at_age") != 0L ||
    !any(outputs$measure == "natural_mortality_average_parameter" &
      abs(outputs$value - 0.414) < 1e-8) ||
    !any(outputs$measure == "biomass_by_age_group" &
      outputs$year == 2021L & outputs$age_group == "1+" &
      outputs$value == 2090640)) {
  stop("Anchovy source values or coverage failed focused checks.", call. = FALSE)
}
states_june <- state_parts(table12$model_state)
june_rows <- states_june$season == 1L
tab14_match <- match(states_june$year[june_rows], table14$year)
if (anyNA(tab14_match) ||
    any(abs(table12$v5[june_rows] - table14$v1[tab14_match]) > 10) ||
    any(abs(table12$v6[june_rows] - table14$v2[tab14_match]) > 10)) {
  stop("Table 12 June biomass does not agree with Table 14 within rounding.", call. = FALSE)
}
recruitment_match <- match(table13$model_state, table11$model_state)
table13_recruits <- table13$v3 > 0 & state13$year <= 2021L
if (anyNA(recruitment_match[table13_recruits]) ||
    any(table13$v3[table13_recruits] != table11$v1[recruitment_match[table13_recruits]])) {
  stop("Table 13 recruitment does not match age-0 numbers in Table 11.", call. = FALSE)
}

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA Fisheries",
  authority_stock_id = "10574", scientific_name = "Engraulis mordax",
  common_name = "Northern anchovy - central subpopulation",
  area = "Central subpopulation, California to northern Baja California",
  region = "U.S. West Coast and northern Baja California",
  ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10574 calls this Northern anchovy - Southern Pacific Coast; the PFMC 2021 benchmark identifies the central subpopulation. This crosswalk follows that 2021 production run.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2022L, terminal_year = 2021L,
  estimate_terminal_year = 2023L, assessment_type = "benchmark",
  model_family = "Stock Synthesis", model_version = "Stock Synthesis 3.30",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = "https://www.pcouncil.org/documents/2022/07/assessment-of-the-northern-anchovy-engraulis-mordax-central-subpopulation-in-2021-for-u-s-management-june-2022.pdf/",
  framework_url = "https://www.pcouncil.org/documents/2022/07/assessment-of-the-northern-anchovy-engraulis-mordax-central-subpopulation-in-2021-for-u-s-management-june-2022.pdf/",
  data_url = "https://www.pcouncil.org/documents/anchovy-2021-model-files/",
  model_url = "https://www.pcouncil.org/documents/anchovy-2021-model-files/",
  repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "The 2021 central-subpopulation benchmark was adopted in June 2022. The assessment fits data through 2021; Tables 11-13 include model state estimates through calendar 2023, with model year 2022 identified as projection. Native catches, indices, compositions, weights, maturity and age-error vectors are imported. Direct catch-at-age, a numeric age-specific survey index, exact survey fractions, and numeric F-at-age outputs remain unavailable.")

assumptions <- do.call(rbind, assumption_rows)
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selection_path <- file.path(root, "discovery", "selected_batch_26_2026.csv")
candidates <- read_csv(candidate_path)
candidate_row <- which(candidates$candidate_id == candidate_id)
stocks_existing <- read_csv(file.path(root, "database", "stocks.csv"))
assessments_existing <- read_csv(file.path(root, "database", "assessments.csv"))
if (length(candidate_row) != 1L ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started" ||
    any(stocks_existing$stock_id == stock_id) ||
    any(stocks_existing$authority_stock_id == "10574" &
      stocks_existing$authority == "NOAA Fisheries") ||
    any(assessments_existing$assessment_id == assessment_id)) {
  stop("NOAA:10574 candidate or canonical identity changed; review before writing.",
    call. = FALSE)
}
inventory <- read_csv(inventory_path, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
selection <- read_csv(selection_path)
selection_row <- which(selection$candidate_id == candidate_id)
if (length(selection_row) != 1L) stop("Expected one Batch 26 selection row.", call. = FALSE)
if (!write_mode) {
  message("Dry run: NOAA:10574; 1 stock, 1 assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs and ",
    nrow(outputs), " outputs.")
} else {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Imported Tables 11-15 and Table 16 base parameter estimates, including N/biomass at age, SSB/recruitment with SE, M, log-q and exploitation rates.")
  candidates$decision_reason[candidate_row] <- paste(
    candidates$decision_reason[candidate_row],
    "Partial source import completed; direct catch-at-age, numeric age-specific survey indices, exact within-year survey timing, and numeric F-at-age remain unavailable.")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key",
    inventory$unit_key[inventory_row])
  selection$curation_status[selection_row] <- "partial_source_import"
  utils::write.csv(selection, selection_path, row.names = FALSE, na = "")
  message("Imported NOAA Northern anchovy central subpopulation 2021: ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs and ",
    nrow(outputs), " outputs; status remains partial.")
}
