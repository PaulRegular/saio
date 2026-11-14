root <- "."
stock_id <- "noaa_flathead_sole_bsai"
assessment_id <- "noaa_flathead_sole_bsai_2024"
candidate_id <- "NOAA:10015"
candidate_unit_id <- "noaa_stocksmart_10015"
revision <- "8db5b6c505841aedc4b44c3cac5f85813ddebf94"
repository <- "https://github.com/afsc-assessments/bsai-fhs"
model_path <- "2024/mgmt/18.2c_2024"
report_url <- "https://files.npfmc.org/SAFE/2024/BSAIflathead.pdf"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))
cache_root <- file.path(root, "source_cache/noaa_flatfish_screening_20261029")
cache <- file.path(cache_root, "bsai_fhs_2024_final_model")
manifest <- read.csv(file.path(root,
  "provenance/noaa_flatfish_screening_20261029/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hash <- toupper(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
    )))
  } else {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hash <- toupper(strsplit(result, "[[:space:]]+")[[1L]][1L])
  }
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}
verify_source <- function(name) {
  relative <- paste0("bsai_fhs_2024_final_model/", name)
  row <- manifest[manifest$file == relative, , drop = FALSE]
  path <- file.path(cache_root, relative)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256)) ||
      !identical(row$repository_revision, revision)) {
    stop("Cached source differs from pinned manifest: ", relative, call. = FALSE)
  }
  path
}

data_file <- verify_source("2024_BSAI_FHS.dat")
control_file <- verify_source("BSAI_FHS.ctl")
report_file <- verify_source("Report.sso")
weight_file <- verify_source("wtatage.ss_new")
projection_file <- verify_source("alt_proj.out")
exec_summary_file <- verify_source("2024-10-23-exec_summ.csv")

ss_reader <- getOption("saio.ss_readdat")
if (is.null(ss_reader)) {
  if (!requireNamespace("r4ss", quietly = TRUE) ||
      !"SS_readdat" %in% getNamespaceExports("r4ss")) {
    stop("Install r4ss with SS_readdat() to parse the native input file.",
      call. = FALSE)
  }
  ss_reader <- r4ss::SS_readdat
}
dat <- ss_reader(data_file, verbose = FALSE)
normalize_columns <- function(x) {
  aliases <- c(year = "Yr", month = "Month", fleet = "FltSvy",
    sex = "Gender", part = "Part", ageerr = "Ageerr", seas = "Seas")
  for (target in names(aliases)) {
    old <- aliases[[target]]
    if (!target %in% names(x) && old %in% names(x)) names(x)[names(x) == old] <- target
  }
  x
}
dat$catch <- normalize_columns(dat$catch)
dat$CPUE <- normalize_columns(dat$CPUE)
dat$agecomp <- normalize_columns(dat$agecomp)
dat$lencomp <- normalize_columns(dat$lencomp)
age_bins <- as.integer(dat$agebin_vector)
length_bins <- as.numeric(dat$lbin_vector)
if (dat$styr != 1964L || dat$endyr != 2024L || dat$Nages != 21L ||
    nrow(dat$catch) != 62L || nrow(dat$CPUE) != 42L ||
    nrow(dat$agecomp) != 1202L || nrow(dat$lencomp) != 92L ||
    !identical(age_bins, 1:21) ||
    !identical(length_bins, c(6,8,10,12,14,16,18,20,22,24,26,28,
      30,32,34,36,38,40,43,46,49,52,55,58))) {
  stop("Final input dimensions differ from the reviewed 2024 source.", call. = FALSE)
}
fleet_names <- as.character(dat$fleetinfo$fleetname)
if (length(fleet_names) < 2L || !identical(fleet_names[1:2], c("Fishery", "Survey"))) {  stop("Final model fleet identity differs from the reviewed source.", call. = FALSE)
}
sex_names <- c("1" = "female", "2" = "male")
model_reference <- paste0(repository, "/tree/", revision, "/", model_path)
source_ref <- function(file, section = "") {
  url <- paste0(repository, "/blob/", revision, "/", model_path, "/", file)
  if (nzchar(section)) paste0(url, "# ", section) else url
}
data_ref <- source_ref("2024_BSAI_FHS.dat")
control_ref <- source_ref("BSAI_FHS.ctl")

input <- function(type, measure, basis, value, unit, year = NA_integer_,
  age = NA_integer_, sex = "", fleet = "", survey = "", season = "",
  sampling_time = NA_real_, source_type = "native_model", source_reference = data_ref,
  transformation = "", notes = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_real_, partition = NA_real_) {
  pacific_database_row("inputs", assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit,
    year = year, year_basis = ifelse(is.na(year), "", "calendar_year"),
    age = age, sex = sex, fleet = fleet, survey = survey, region = "BSAI",
    season = season, sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition)
}

calendar_year <- as.integer(dat$catch$year)
catch_year <- ifelse(calendar_year == -999L, NA_integer_, calendar_year)
inputs <- list(
  input("catch", "total_biomass", "biomass", dat$catch$catch, "t",
    catch_year, fleet = "Fishery",
    notes = ifelse(is.na(catch_year),
      "Native initial-equilibrium catch sentinel (year -999); retained with blank calendar year.",
      "Annual combined flathead sole and Bering flounder fishery catch; tonnes.")),
  input("catch", "catch_se", "log_scale", dat$catch$catch_se, "log SD",
    catch_year, fleet = "Fishery",
    notes = "Native fixed catch log-scale SD; source value is 0.01.")
)
survey_index <- dat$CPUE[dat$CPUE$index == 2L, , drop = FALSE]
inputs[[length(inputs) + 1L]] <- input("index", "total_biomass", "biomass",
  survey_index$obs, "t", survey_index$year, survey = "Survey", season = "summer",
  sampling_time = (survey_index$month - 1) / 12,
  notes = "Aggregate BSAI trawl-survey biomass index; no age-specific abundance index is supplied.")
inputs[[length(inputs) + 1L]] <- input("index", "log_index_sd", "log_scale",
  survey_index$se_log, "log SD", survey_index$year, survey = "Survey",
  season = "summer", sampling_time = (survey_index$month - 1) / 12,
  notes = "Native supplied log-index SD; no extra survey CV is activated.")

age_rows <- list()
for (i in seq_len(nrow(dat$agecomp))) {
  x <- dat$agecomp[i, , drop = FALSE]
  fleet_code <- as.integer(x$fleet)
  fleet_number <- abs(fleet_code)
  is_fishery <- fleet_number == 1L
  if (!fleet_number %in% 1:2) stop("Unexpected age-composition fleet code.")
  component_sexes <- if (x$sex == 3L) 1:2 else as.integer(x$sex)
  for (sex_code in component_sexes) {
    values <- as.numeric(x[paste0(if (sex_code == 1L) "f" else "m", age_bins)])
    joint <- x$sex == 3L
    measure <- if (joint) "proportion_at_age" else "frequency_at_age"
    basis <- if (joint) "proportion_numbers" else "native_frequency"
    unit <- if (joint) "proportion" else "source frequency"
    row_notes <- if (joint) {
      paste("Native marginal age composition; female and male vectors sum jointly to one.",
        if (fleet_code < 0L) "Negative fleet code: diagnostic row excluded from likelihood." else "Active likelihood row.",
        "Fishery age samples are flathead sole only; catches combine two species.")
    } else {
      paste("Native conditional age-at-length frequency counts retained without normalization.",
        "Lbin_method=3; conditioning labels are preserved verbatim, not asserted to be centimetre bounds.",
        "Nsamp, age-error code and partition are retained.",
        if (fleet_code < 0L) "Negative fleet code: diagnostic row excluded from likelihood." else "Active likelihood row.",
        "Survey CAAL samples are not age-specific abundance indices.")
    }
    age_rows[[length(age_rows) + 1L]] <- input(
      if (is_fishery) "catch" else "index", measure, basis, values, unit,
      year = rep(as.integer(x$year), length(age_bins)), age = age_bins,
      sex = sex_names[as.character(sex_code)],
      fleet = if (is_fishery) "Fishery" else "",
      survey = if (is_fishery) "" else "Survey",
      season = if (is_fishery) "" else "summer",
      sampling_time = if (is_fishery) NA_real_ else (x$month - 1) / 12,
      transformation = if (joint) "Split joint-sex cells into sex-labelled rows; values unchanged." else "",
      notes = row_notes, observation_id = paste0("agecomp:", i),
      length_bin_lower = if (joint) NA_real_ else as.numeric(x$Lbin_lo),
      length_bin_upper = if (joint) NA_real_ else as.numeric(x$Lbin_hi),
      sample_size = rep(as.numeric(x$Nsamp), length(age_bins)),
      age_error = rep(as.numeric(x$ageerr), length(age_bins)),
      partition = rep(as.numeric(x$part), length(age_bins)))
  }
}
inputs[[length(inputs) + 1L]] <- do.call(rbind, age_rows)

length_rows <- list()
for (i in seq_len(nrow(dat$lencomp))) {
  x <- dat$lencomp[i, , drop = FALSE]
  fleet_code <- as.integer(x$fleet)
  fleet_number <- abs(fleet_code)
  is_fishery <- fleet_number == 1L
  if (!fleet_number %in% 1:2 || x$sex != 3L) {
    stop("Unexpected length-composition fleet or sex code.")
  }
  for (sex_code in 1:2) {
    values <- as.numeric(x[paste0(if (sex_code == 1L) "f" else "m", length_bins)])
    length_rows[[length(length_rows) + 1L]] <- input(
      if (is_fishery) "catch" else "index", "proportion_at_length",
      "proportion_numbers", values, "proportion",
      year = rep(as.integer(x$year), length(length_bins)),
      sex = sex_names[as.character(sex_code)],
      fleet = if (is_fishery) "Fishery" else "",
      survey = if (is_fishery) "" else "Survey",
      season = if (is_fishery) "" else "summer",
      sampling_time = if (is_fishery) NA_real_ else (x$month - 1) / 12,
      transformation = "Split joint-sex cells into sex-labelled rows; values unchanged.",
      notes = paste("Native joint-sex length proportions sum to one across both sexes.",
        if (fleet_code < 0L) "Negative fleet code: diagnostic row excluded from likelihood." else "Active likelihood row.",
        "Source length-bin labels and Nsamp are retained."),
      observation_id = paste0("lencomp:", i), length_bin = length_bins,
      sample_size = rep(as.numeric(x$Nsamp), length(length_bins)),
      partition = rep(as.numeric(x$part), length(length_bins)))
  }
}
inputs[[length(inputs) + 1L]] <- do.call(rbind, length_rows)

m_ages <- 0:21
for (sex in c("female", "male")) {
  inputs[[length(inputs) + 1L]] <- input("M", "natural_mortality_at_age",
    "per_year", rep(0.2, length(m_ages)), "per year", age = m_ages, sex = sex,
    source_reference = control_ref,
    notes = "Fixed natural mortality 0.2 per year (phase -3), ages 0-21.")
}
maturity_value <- ifelse(m_ages < 3L, 0,
  1 / (1 + exp(-0.942711 * (m_ages - 9.70203))))
inputs[[length(inputs) + 1L]] <- input("maturity", "maturity_at_age",
  "proportion", maturity_value, "proportion", age = m_ages, sex = "female",
  source_type = "reconstructed_source_input", source_reference = control_ref,
  transformation = "Reconstructed from fixed age-logistic parameters and first-mature-age threshold.",
  notes = "Female maturity is zero below age 3, then 1/(1+exp(-0.942711*(age-9.70203))). Matches Report.sso Mat_F_Natage; not a separate observed sample.")
inputs <- do.call(rbind, inputs)

report_lines <- readLines(report_file, warn = FALSE)
read_report_table <- function(label, header_pattern) {
  marker <- tail(which(startsWith(trimws(report_lines), paste0(label, " report:"))), 1L)
  header <- grep(header_pattern, report_lines, perl = TRUE)
  header <- header[header > marker][1L]
  if (length(marker) != 1L || length(header) != 1L || is.na(header)) {
    stop("Could not locate Stock Synthesis report table: ", label)
  }
  columns <- strsplit(trimws(report_lines[header]), "[[:space:]]+")[[1L]]
  rows <- list()
  for (i in seq.int(header + 1L, length(report_lines))) {
    line <- trimws(report_lines[i])
    if (!nzchar(line) || startsWith(line, "#") || grepl(" report:", line, fixed = TRUE)) break
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (length(fields) != length(columns)) break
    rows[[length(rows) + 1L]] <- fields
  }
  if (!length(rows)) stop("Report table is empty: ", label)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE, check.names = FALSE)
  names(out) <- columns
  for (column in names(out)) {
    values <- suppressWarnings(as.numeric(out[[column]]))
    if (sum(!is.na(values)) == sum(!is.na(out[[column]]))) out[[column]] <- values
  }
  out
}

annual <- read_report_table("TIME_SERIES", "^Area Yr Era")
numbers <- read_report_table("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
biomass <- read_report_table("BIOMASS_AT_AGE", "^Area Bio_Pattern Sex")
fishing <- read_report_table("F_AT_AGE", "^Area Fleet Sex")
catch_at_age <- read_report_table("CATCH_AT_AGE", "^Area Fleet Sex")
biology <- read_report_table("Biology_at_age_in_endyr", "^Seas Morph Bio_Pattern Sex")
output_years <- 1964:2025
keep_forecast <- function(x) x$Yr %in% output_years & x$Era %in% c("TIME", "FORE")
annual <- annual[annual$Area == 1 & annual$Seas == 1 & keep_forecast(annual), , drop = FALSE]
population_rows <- function(x) x$Area == 1 & x$Bio_Pattern == 1 &
  x$Sex %in% 1:2 & x$Morph == x$Sex & x$BirthSeas == 1 &
  x$Settlement == 1 & x$Platoon == 1 & x$Seas == 1 &
  x[["Beg/Mid"]] == "B" & keep_forecast(x)
numbers <- numbers[population_rows(numbers), , drop = FALSE]
biomass <- biomass[population_rows(biomass), , drop = FALSE]
fishing <- fishing[fishing$Area == 1 & fishing$Fleet == 1 &
  fishing$Sex %in% 1:2 & fishing$Morph == fishing$Sex &
  fishing$Seas == 1 & keep_forecast(fishing), , drop = FALSE]
catch_at_age <- catch_at_age[catch_at_age$Area == 1 & catch_at_age$Fleet == 1 &
  catch_at_age$Sex %in% 1:2 & catch_at_age$Morph == catch_at_age$Sex &
  catch_at_age$Type == "dead" & catch_at_age$Seas == 1 & keep_forecast(catch_at_age),
  , drop = FALSE]
biology <- biology[biology$Seas == 1 & biology$Morph == 1 &
  biology$Bio_Pattern == 1 & biology$Settlement == 1 &
  biology$Platoon == 1 & biology$int_Age %in% m_ages & biology$Sex == 1, , drop = FALSE]

weight_lines <- readLines(weight_file, warn = FALSE)
weight_header <- grep("^#Yr[[:space:]]+Seas", weight_lines)[1L]
if (is.na(weight_header)) stop("Could not locate wtatage.ss_new header.")
weight_columns <- sub("^#", "", trimws(weight_lines[weight_header]))
weight <- read.table(text = c(weight_columns,
  weight_lines[(weight_header + 1L):length(weight_lines)]),
  header = TRUE, fill = TRUE, check.names = FALSE, comment.char = "#")
weight <- weight[weight$Yr %in% output_years & weight$Seas == 1 &
  weight$Sex %in% 1:2 & weight$Bio_Pattern == 1 & weight$BirthSeas == 1 &
  weight$Fleet == 0, , drop = FALSE]

expected_years <- 1964:2025
if (nrow(annual) != length(expected_years) ||
    nrow(numbers) != 2L * length(expected_years) ||
    nrow(biomass) != 2L * length(expected_years) ||
    nrow(fishing) != 2L * length(expected_years) ||
    nrow(catch_at_age) != 2L * length(expected_years) ||
    nrow(weight) != 2L * length(expected_years) || nrow(biology) != 22L ||
    !identical(as.integer(sort(unique(annual$Yr))), expected_years) ||
    any(annual$Era[annual$Yr == 2025L] != "FORE")) {
  stop("Final fitted/forecast output dimensions differ from the reviewed source.")
}

age_columns <- as.character(m_ages)
long_age <- function(x) {
  values <- as.matrix(x[, age_columns, drop = FALSE])
  storage.mode(values) <- "double"
  list(row = rep(seq_len(nrow(x)), each = length(age_columns)),
    age = rep(m_ages, times = nrow(x)), value = as.vector(t(values)))
}
n_long <- long_age(numbers)
b_long <- long_age(biomass)
f_long <- long_age(fishing)
c_long <- long_age(catch_at_age)
w_long <- long_age(weight)
report_ref <- source_ref("Report.sso")
output <- function(type, measure, value, unit, year = NA_integer_, age = NA_integer_,
  sex = "combined", fleet = "", survey = "", age_group = "", scenario = "",
  source_type = "native_model", source_reference = report_ref, notes = "") {
  pacific_database_row("outputs", assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    sex = sex, fleet = fleet, survey = survey, region = "BSAI",
    age_group = age_group, scenario = scenario, source_type = source_type,
    source_reference = source_reference, notes = notes)
}
surface_output <- function(x, long, type, measure, unit, section,
  fleet_column = NULL, notes) {
  row_year <- x$Yr[long$row]
  row_era <- x$Era[long$row]
  sex <- sex_names[as.character(x$Sex[long$row])]
  fleet <- if (is.null(fleet_column)) "" else
    c("1" = "Fishery", "2" = "Survey")[as.character(x[[fleet_column]][long$row])]
  scenario <- ifelse(row_era == "FORE", "Stock Synthesis forecast", "")
  note <- ifelse(row_era == "FORE", "Native forecast after terminal fitted year 2024.",
    "Native fitted historical output.")
  output(type, measure, long$value, unit, row_year, long$age, sex = sex,
    fleet = fleet, scenario = scenario, source_reference = source_ref("Report.sso", section),
    notes = paste(notes, note, "No age-specific uncertainty is reported."))
}

annual_scenario <- ifelse(annual$Era == "FORE", "Stock Synthesis forecast", "")
outputs <- list(
  output("biomass", "total_biomass", annual$Bio_all, "t", annual$Yr,
    scenario = annual_scenario, source_reference = source_ref("Report.sso", "TIME_SERIES report:16"),
    notes = "Native Bio_all, all model ages 0-21+; point estimate."),
  output("biomass", "biomass_by_age_group", annual$Bio_smry, "t", annual$Yr,
    age_group = "3+", scenario = annual_scenario, source_reference = source_ref("Report.sso", "TIME_SERIES report:16"),
    notes = "Native Bio_smry for ages 3+; distinct from all-age Bio_all."),
  output("biomass", "SSB", annual$SpawnBio, "t", annual$Yr, sex = "female",
    scenario = annual_scenario, source_reference = source_ref("Report.sso", "TIME_SERIES report:16"),
    notes = "Native spawning biomass point estimate; age-specific uncertainty is unavailable."),
  output("recruitment", "recruitment", annual$Recruit_0, "thousand fish", annual$Yr,
    age = 0L, scenario = annual_scenario, source_reference = source_ref("Report.sso", "TIME_SERIES report:16"),
    notes = "Native age-0 recruitment point estimate."),
  surface_output(numbers, n_long, "population", "numbers_at_age", "thousand fish",
    "NUMBERS_AT_AGE report:35", notes = "Beginning-of-year fitted abundance; age 21 is the plus group."),
  surface_output(biomass, b_long, "biomass", "biomass_at_age", "t",
    "BIOMASS_AT_AGE report:36", notes = "Beginning-of-year model biomass at age; not an observed input."),
  surface_output(fishing, f_long, "mortality", "fishing_mortality_at_age", "per year",
    "F_AT_AGE report:39", fleet_column = "Fleet", notes = "Fishery fleet fitted F-at-age."),
  surface_output(catch_at_age, c_long, "catch", "numbers_at_age", "thousand fish",
    "CATCH_AT_AGE report:40", fleet_column = "Fleet",
    notes = "Model-estimated dead catch numbers-at-age; output, not observed catch-at-age."),
  surface_output(weight, w_long, "biology", "weight_at_age", "kg/fish",
    "wtatage.ss_new fleet 0", notes = "Model-generated beginning-of-year population weights; not supplied weight-at-age inputs.")
)
outputs[[length(outputs) + 1L]] <- output("biology", "maturity_at_age",
  biology$Mat_F_Natage, "proportion", year = 2024L, age = biology$int_Age,
  sex = "female", source_reference = source_ref("Report.sso", "Biology_at_age_in_endyr report:47"),
  notes = "Native terminal-year maturity at age from the fixed age-logistic curve.")
total_numbers <- aggregate(n_long$value, list(year = numbers$Yr[n_long$row],
  scenario = ifelse(numbers$Era[n_long$row] == "FORE", "Stock Synthesis forecast", "")), sum)
outputs[[length(outputs) + 1L]] <- output("population", "total_numbers",
  total_numbers$x, "thousand fish", total_numbers$year, scenario = total_numbers$scenario,
  source_type = "derived_source_output", source_reference = source_ref("Report.sso", "NUMBERS_AT_AGE report:35"),
  notes = "Derived by summing fitted numbers-at-age over ages 0-21+ and both sexes; uncertainty unavailable.")

projection <- read.table(projection_file, header = TRUE, check.names = FALSE)
projection_scenario <- "October 2024 management projection"
projection_scenario_by_alt <- paste0("2024 management projection (Alt ", projection$Alt, ")")
executive_summary_scenario <- "October 2024 executive summary reference"
projection_ref <- source_ref("alt_proj.out")
outputs <- c(outputs, list(
  output("management", "projected_catch", projection$Catch, "t", projection$Year,
    scenario = projection_scenario_by_alt, source_reference = projection_ref,
    notes = "Official management-projection catch, separate from fitted catch and the SS forecast."),
  output("management", "ABC", projection$ABC, "t", projection$Year,
    scenario = projection_scenario_by_alt, source_reference = projection_ref,
    notes = "Official acceptable biological catch projection."),
  output("management", "OFL", projection$OFL, "t", projection$Year,
    scenario = projection_scenario_by_alt, source_reference = projection_ref,
    notes = "Official overfishing limit projection."),
  output("biomass", "SSB", projection$SSB, "t", projection$Year, sex = "female",
    scenario = projection_scenario_by_alt, source_reference = projection_ref,
    notes = "Official management-projection spawning biomass; definition retained as reported."),
  output("biomass", "total_biomass", projection$TotBiom, "t", projection$Year,
    scenario = projection_scenario_by_alt, source_reference = projection_ref,
    notes = "Official management-projection total biomass; distinct from Report.sso Bio_all and Bio_smry.")))
exec_summary <- unique(read.csv(exec_summary_file, stringsAsFactors = FALSE, check.names = FALSE))
reference_metrics <- c(SSBF100 = "SSB_at_F100", SSBFabc = "SSB_at_Fabc",
  SSBFofl = "SSB_at_Fofl", Fabc = "Fabc", Fofl = "Fofl")
for (metric in names(reference_metrics)) {
  z <- exec_summary[exec_summary$metric == metric, , drop = FALSE]
  if (nrow(z) != 1L) stop("Expected one unique projection metric: ", metric)
  years <- as.integer(names(z)[-1L])
  values <- as.numeric(z[1L, -1L])
  outputs[[length(outputs) + 1L]] <- output(
    if (startsWith(metric, "SSB")) "biomass" else "management",
    unname(reference_metrics[metric]), values,
    if (startsWith(metric, "SSB")) "t" else "per year", years,
    sex = if (startsWith(metric, "SSB")) "female" else "combined",
    scenario = executive_summary_scenario, source_reference = source_ref("2024-10-23-exec_summ.csv"),
    notes = "Native management-projection reference value; not an estimated annual fitted trajectory.")
}
outputs <- do.call(rbind, outputs)

assume <- function(component, setting, value, source_reference = control_ref,
  notes = "", fleet = "", survey = "", sex = "", season = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = as.character(value),
    fleet = fleet, survey = survey, sex = sex, region = "BSAI",
    season = season, source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assume("assessment", "official_run", "2024 operational update; Model 18.2c; Stock Synthesis 3.30.22; final run dated 2024-10-23", source_ref("Report.sso")),
  assume("assessment", "fit_diagnostic", "Convergence level 0; objective 1766.68", source_ref("Report.sso", "LIKELIHOOD report:2"), "Reported diagnostic, not independently reproduced."),
  assume("population", "dimensions", "One BSAI area; two sexes; one annual season; ages 0-21 with age 21 plus group; data years 1964-2024", data_ref),
  assume("fleet", "structure", "Fleet 1 Fishery uses annual timing; fleet 2 Survey timing is 0.5 (July)", data_ref),
  assume("index", "catchability", "Survey ln(q)=0; q=1 fixed; no extra survey CV", control_ref, survey = "Survey"),
  assume("M", "fixed_natural_mortality", "0.2 per year across ages 0-21", control_ref, sex = "female"),
  assume("M", "fixed_natural_mortality", "0.2 per year across ages 0-21", control_ref, sex = "male"),
  assume("maturity", "fixed_age_logistic", "Female; first mature age 3; Mat50=9.70203; slope=-0.942711", control_ref, "Reconstructed input vector matches Report.sso Mat_F_Natage."),
  assume("biology", "growth", "Sex-specific von Bertalanffy growth estimated; cohort growth deviations enabled", control_ref),
  assume("biology", "weight_length", "Fixed weight-length relationship for both sexes: kg=2.98e-6*cm^3.3268", control_ref),
  assume("recruitment", "spawner_recruit", "Beverton-Holt; steepness=1 and sigmaR=0.5 fixed; main recruitment deviations 1973-2020", control_ref),
  assume("selectivity", "fishery", "Sex-specific length-based selectivity with time block through 1987 and later base parameters", control_ref),
  assume("selectivity", "survey", "Sex-specific age-based survey selectivity", control_ref),
  assume("length_composition", "effective_sample_size_multiplier", "0.079018", source_ref("Report.sso", "Input_Variance_Adjustment report:3"), fleet = "Fishery"),
  assume("length_composition", "effective_sample_size_multiplier", "0.062439", source_ref("Report.sso", "Input_Variance_Adjustment report:3"), fleet = "Survey"),
  assume("age_composition", "effective_sample_size_multiplier", "0.085811", source_ref("Report.sso", "Input_Variance_Adjustment report:3"), fleet = "Fishery"),
  assume("age_composition", "effective_sample_size_multiplier", "0.481957", source_ref("Report.sso", "Input_Variance_Adjustment report:3"), fleet = "Survey"),
  assume("age_composition", "likelihood", "Fishery marginal ages are flathead sole samples; survey ages are conditional age-at-length samples by sex", data_ref),
  assume("management", "projection_definition", "October 2024 management projection is separate from Report.sso forecast; 2025 SAFE intro reports age-3+ biomass 801418 t and SSB 204323 t", source_ref("alt_proj.out")),
  assume("uncertainty", "projection_distribution", "means.out and percentiles.out contain seven alternative blocks with LowCI/UpperCI, median, mean and SD; interval level and selected alternative are not identified", source_ref("percentiles.out"), "Not labelled as 95% intervals or standard errors.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "NOAA-AFSC", authority_stock_id = "10015",
  scientific_name = "Hippoglossoides elassodon",
  common_name = "Bering Sea/Aleutian Islands flathead sole-Bering flounder complex",
  area = "Bering Sea / Aleutian Islands", region = "Alaska", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10015. The assessment combines flathead sole and Bering flounder catches, while age samples are flathead sole only. One stock-unit case; Bering flounder is Hippoglossoides robustus.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2024L, terminal_year = 2024L,
  estimate_terminal_year = 2024L, assessment_type = "operational_update",
  model_family = "Stock Synthesis", model_version = "3.30.22, Model 18.2c",
  is_current = TRUE, is_applied = TRUE, assessment_url = report_url,
  framework_url = report_url, data_url = paste0(model_reference, "/2024_BSAI_FHS.dat"),
  model_url = model_reference, repository_url = paste0(repository, "/tree/", revision),
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Final 2024 production operational update based on the accepted 2020 configuration with updated data. Native catch, aggregate index, compositions, fixed M and maturity, fitted age surfaces and a separate management projection are retained. No observed catch-at-age or age-specific abundance index is supplied; age-surface uncertainty is unavailable.")

if (any(!is.finite(inputs$value)) || any(!is.finite(outputs$value)) ||
    any(!nzchar(inputs$source_reference)) || any(!nzchar(outputs$source_reference)) ||
    any(inputs$measure == "maturity_at_age" & (inputs$value < 0 | inputs$value > 1))) {
  stop("Prepared source rows failed value, scale, or provenance checks.")
}
stocks_existing <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
assessments_existing <- read.csv(file.path(root, "database/assessments.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
candidates_path <- file.path(root, "discovery/candidates.csv")
selected_path <- file.path(root, "discovery/selected_batch_16_2026.csv")
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
selected <- read.csv(selected_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
candidate_row <- which(candidates$candidate_id == candidate_id)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(candidate_row) != 1L || length(selected_row) != 1L ||
    candidates$candidate_unit_id[candidate_row] != candidate_unit_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$match_status[candidate_row] != "new" ||
    candidates$import_status[candidate_row] != "not_started" ||
    selected$curation_status[selected_row] != "selected_for_source_curation" ||
    any(stocks_existing$stock_id == stock_id) ||
    any(assessments_existing$assessment_id == assessment_id)) {
  stop("Candidate, selection, or canonical database differs from reviewed state.")
}

cat("NOAA BSAI Flathead Sole/Bering Flounder 2024\n")
cat("Inputs:", nrow(inputs), "rows; outputs:", nrow(outputs),
  "rows; assumptions:", nrow(assumptions), "rows\n")
print(table(inputs$measure))
print(table(outputs$measure))
if (write_mode) {

  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidate <- candidates[candidate_row, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "Final model has combined two-species catch totals and flathead-sole age compositions; no observed catch-at-age is supplied."
  candidate$survey_age_evidence <- "Aggregate survey biomass and sex-specific conditional age-at-length are present; no age-specific abundance index is supplied."
  candidate$weights_evidence <- "Sex-specific growth is estimated and weight-length parameters are fixed; weight-at-age is model-generated output."
  candidate$maturity_evidence <- "Fixed female age-logistic maturity: first mature age 3, Mat50 9.70203, slope -0.942711; reconstructed values match Report.sso."
  candidate$mortality_evidence <- "M is fixed at 0.2 per year for both sexes across ages 0-21; not estimated."
  candidate$timing_evidence <- "Survey observations are in July with timing 0.5; fishery catch is annual."
  candidate$output_evidence <- "Pinned final Model 18.2c files provide annual biomass, SSB, recruitment, N-at-age, F-at-age and model catch-at-age outputs; age uncertainty is unavailable."
  candidate$detailed_source_url <- paste(report_url, model_reference, sep = "; ")
  candidate$review_date <- "2026-11-07"
  candidate$decision_reason <- paste("Partially imported from the finalized 2024 production update pinned to revision", revision, "with source forms and species distinctions preserved.")
  candidate$notes <- paste("NOAA Stock SMART ID 10015; one BSAI complex. Earlier bafa7658 snapshot is superseded by the final October 2024 Model 18.2c files. See discovery/source_reviews/noaa_flathead_bsai.md and provenance/noaa_flatfish_screening_20261029/sources.csv.")
  replace_candidate_register_row(candidates_path, candidate_row, candidate, candidate_id)
  selected$curation_status[selected_row] <- "partial_source_import"
  selected$detailed_source_url[selected_row] <- paste(report_url, model_reference, sep = "; ")
  write.csv(selected, selected_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts/database/196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported the verified source record and marked it partial.\n")
}

