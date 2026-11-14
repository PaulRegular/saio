root <- "."
source_dir <- file.path(root, "../../discovery_noaa_chilipepper_2025")
model_dir <- file.path(source_dir, "model_input", "PFMC Shared")
assessment_id <- "noaa_chilipepper_2025"
stock_id <- "noaa_chilipepper_pacific_coast"
candidate_id <- "NOAA:17357"
candidate_unit_id <- "noaa_stocksmart_17357"
report_url <- "https://repository.library.noaa.gov/view/noaa/72420"
model_url <- "https://www.pcouncil.org/documents/chilipepper-rockfish-2025-model-files-zip-file/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(file.path(root, "provenance/discovery_noaa_chilipepper_2025/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
sha256_file <- function(path) toupper(unname(tools::sha256sum(path)))
verify_source <- function(file) {
  row <- manifest[manifest$file == file, , drop = FALSE]
  path <- file.path(source_dir, file)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from the pinned provenance record: ", file, call. = FALSE)
  }
  path
}

invisible(verify_source("chilipepper_models.zip"))
invisible(verify_source("noaa_report.pdf"))
if (!all(file.exists(file.path(model_dir, c("Chili_2025.dat", "Chili_2025.ctl", "Report.sso")))) ||
    length(list.files(model_dir, pattern = "\\.par$", ignore.case = TRUE)) > 0L || file.exists(file.path(model_dir, "CompReport.sso"))) {
  stop("The reviewed Stock Synthesis input or output files differ from the cached archive.", call. = FALSE)
}

dat <- r4ss::SS_readdat(file = file.path(model_dir, "Chili_2025.dat"), verbose = FALSE)
fit <- r4ss::SS_output(dir = model_dir, verbose = FALSE, printstats = FALSE,
  forecast = FALSE, warn = FALSE)
if (dat$styr != 1875 || dat$endyr != 2024 || dat$Nsexes != 2L ||
    dat$Nages != 35L || !identical(as.integer(dat$agebin_vector), 0:35) ||
    !identical(as.integer(dat$lbin_vector), as.integer(seq(8, 60, 2))) ||
    nrow(dat$fleetinfo) != 12L || nrow(dat$CPUE) != 146L ||
    nrow(dat$agecomp) != 2515L || nrow(dat$lencomp) != 353L) {
  stop("The cached Stock Synthesis dimensions differ from the reviewed 2025 assessment.", call. = FALSE)
}

fleet_names <- as.character(dat$fleetinfo$fleetname)
sex_for <- function(code) c("female", "male")[as.integer(code)]
source_reference <- function(file, section) paste0(file, ", ", section)
input_rows <- list()
add_input <- function(...) {
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs",
    assessment_id = assessment_id, source_type = "native_model", ...)
}

catch <- dat$catch[dat$catch$year >= dat$styr & dat$catch$year <= dat$endyr, , drop = FALSE]
for (fleet_id in sort(unique(catch$fleet))) {
  x <- catch[catch$fleet == fleet_id, , drop = FALSE]
  add_input(type = "catch", measure = "catch_biomass", basis = "biomass",
    fleet = fleet_names[fleet_id], region = "U.S. Pacific Coast", year = x$year,
    year_basis = "calendar_year", value = x$catch, unit = "metric tons",
    source_reference = source_reference("Chili_2025.dat", "catch observations"),
    notes = "Native annual catch biomass supplied to Stock Synthesis. The -999 equilibrium sentinel is not a calendar-year observation and is excluded.")
  add_input(type = "catch", measure = "log_catch_sd", basis = "log_scale",
    fleet = fleet_names[fleet_id], region = "U.S. Pacific Coast", year = x$year,
    year_basis = "calendar_year", value = x$catch_se, unit = "log scale",
    source_reference = source_reference("Chili_2025.dat", "catch observation standard errors"),
    notes = "Native catch_se retained as the log-scale standard deviation specified by the model.")
}

index_rows <- dat$CPUE[order(dat$CPUE$index, dat$CPUE$year), , drop = FALSE]
for (i in seq_len(nrow(index_rows))) {
  x <- index_rows[i, , drop = FALSE]
  fleet_id <- as.integer(x$index)
  is_survey <- dat$fleetinfo$type[fleet_id] == 3L
  unit_code <- dat$CPUEinfo$units[match(fleet_id, dat$CPUEinfo$fleet)]
  measure <- switch(as.character(unit_code),
    "1" = "relative_biomass_index", "30" = "spawning_output_index",
    "33" = "recruitment_index", stop("Unexpected CPUE units code.", call. = FALSE))
  unit_label <- switch(as.character(unit_code),
    "1" = "native model index scale (biomass; Stock Synthesis units code 1)",
    "30" = "native model index scale (spawning output; Stock Synthesis units code 30)",
    "33" = "native model index scale (age-0 recruitment; Stock Synthesis units code 33)")
  source_year <- as.integer(x$year)
  index_fields <- list(fleet = if (is_survey) "" else fleet_names[fleet_id],
    survey = if (is_survey) fleet_names[fleet_id] else "",
    sampling_time = (as.integer(x$month) - 1) / 12, year = abs(source_year))
  status_note <- if (source_year < 0L) "Negative source year marks an evaluation-only row outside the likelihood." else "Positive source year marks a likelihood row."
  add_input(type = "index", measure = measure, basis = "index_scale",
    fleet = index_fields$fleet, survey = index_fields$survey,
    region = "U.S. Pacific Coast", season = "July",
    sampling_time = index_fields$sampling_time, year = index_fields$year,
    year_basis = "calendar_year", value = x$obs, unit = unit_label,
    observation_id = paste0("CPUE:", i, ":source_year:", source_year),
    source_reference = source_reference("Chili_2025.dat", "CPUE observations and CPUEinfo units"),
    notes = paste("Native aggregate index; no age-specific index is observed.", status_note,
      "Stock Synthesis units code", unit_code, "is retained in the unit description."))
  add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
    fleet = index_fields$fleet, survey = index_fields$survey,
    region = "U.S. Pacific Coast", season = "July",
    sampling_time = index_fields$sampling_time, year = index_fields$year,
    year_basis = "calendar_year", value = x$se_log, unit = "log scale",
    observation_id = paste0("CPUE_SD:", i, ":source_year:", source_year),
    source_reference = source_reference("Chili_2025.dat", "CPUE log-scale standard errors"),
    notes = paste("Native se_log retained without rescaling.", status_note))
}
add_compositions <- function(x, component) {
  is_age <- component == "age"
  bin_values <- if (is_age) as.integer(dat$agebin_vector) else as.integer(dat$lbin_vector)
  out <- list()
  for (i in seq_len(nrow(x))) {
    sex_code <- as.integer(x$sex[i])
    sex_parts <- switch(as.character(sex_code),
      "0" = list(list(name = "combined", columns = "f", add_male = TRUE)),
      "1" = list(list(name = "female", columns = "f", add_male = FALSE)),
      "2" = list(list(name = "male", columns = "m", add_male = FALSE)),
      "3" = list(list(name = "female", columns = "f", add_male = FALSE),
                 list(name = "male", columns = "m", add_male = FALSE)),
      stop("Unexpected composition sex code.", call. = FALSE))
    fleet_id <- abs(as.integer(x$fleet[i]))
    fishery <- dat$fleetinfo$type[fleet_id] %in% c(1L, 2L)
    source_year <- as.integer(x$year[i])
    for (part in sex_parts) {
      columns <- paste0(part$columns, bin_values)
      values <- as.numeric(x[i, columns, drop = TRUE])
      if (isTRUE(part$add_male)) {
        values <- values + as.numeric(x[i, paste0("m", bin_values), drop = TRUE])
      }
      component_name <- if (is_age) "agecomp" else "lencomp"
      observation_id <- paste0(component_name, ":", i, ":", part$name,
        ":source_year:", source_year)
      notes <- paste0("Native Stock Synthesis frequency cells preserved without normalization. ",
        if (is_age) "Conditional age-at-length composition." else "Length composition.",
        " Source sex code ", sex_code, "; sample size, partition and signed source year are retained.",
        if (source_year < 0L) " Negative source year identifies an evaluation-only row outside the likelihood." else "",
        if (x$fleet[i] < 0L) " Negative source fleet code identifies an evaluation-only row outside the likelihood." else "")
      out[[length(out) + 1L]] <- pacific_database_row("inputs", n = length(bin_values),
        assessment_id = assessment_id, type = if (is_age) "biology" else if (fishery) "catch" else "index",
        measure = if (is_age) "conditional_frequency_at_age" else "frequency_at_length",
        basis = "native_frequency", fleet = if (fishery) fleet_names[fleet_id] else "",
        survey = if (fishery) "" else fleet_names[fleet_id], sex = part$name,
        region = "U.S. Pacific Coast", season = "July", year = abs(source_year),
        year_basis = "calendar_year", age = if (is_age) bin_values else NA_integer_,
        length_bin = if (is_age) NA_integer_ else bin_values,
        length_bin_lower = if (is_age && x$Lbin_lo[i] >= 0) x$Lbin_lo[i] else NA_real_,
        length_bin_upper = if (is_age && x$Lbin_hi[i] >= 0) x$Lbin_hi[i] else NA_real_,
        value = values, unit = "native frequency", sample_size = x$Nsamp[i],
        age_error = if (is_age) x$ageerr[i] else NA_integer_,
        partition = x$part[i], sampling_time = (as.integer(x$month[i]) - 1) / 12,
        observation_id = observation_id, source_type = "native_model",
        source_reference = source_reference("Chili_2025.dat", paste(component_name, "observations")),
        notes = notes)
    }
  }
  do.call(rbind, out)
}

input_rows[[length(input_rows) + 1L]] <- add_compositions(dat$agecomp, "age")
input_rows[[length(input_rows) + 1L]] <- add_compositions(dat$lencomp, "length")
age_error_rows <- list()
for (definition in 1:3) {
  age_error_rows[[length(age_error_rows) + 1L]] <- pacific_database_row("inputs", n = 36L,
    assessment_id = assessment_id, type = "biology", measure = "age_error_mean_age",
    basis = "native_scale", age = 0:35, age_error = definition,
    value = as.numeric(dat$ageerror[2L * definition - 1L, ]), unit = "years",
    source_type = "native_model",
    source_reference = source_reference("Chili_2025.dat", paste("age-error definition", definition)),
    notes = "Native observed-age midpoint vector by true age; retained alongside its age-error standard deviation.")
  age_error_rows[[length(age_error_rows) + 1L]] <- pacific_database_row("inputs", n = 36L,
    assessment_id = assessment_id, type = "biology", measure = "ageing_error_sd",
    basis = "age_error_sd", age = 0:35, age_error = definition,
    value = as.numeric(dat$ageerror[2L * definition, ]), unit = "years",
    source_type = "native_model",
    source_reference = source_reference("Chili_2025.dat", paste("age-error definition", definition)),
    notes = "Native age-error standard deviation by true age, with age midpoints defined by the preceding source row.")
}
input_rows[[length(input_rows) + 1L]] <- do.call(rbind, age_error_rows)
inputs <- do.call(rbind, input_rows)

assumption_rows <- list()
add_assumption <- function(component, setting, value, reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = reference, notes = notes)
}
add_assumption("population", "model_dimensions", "1875-2024 annual data; one U.S. Pacific Coast area; two sexes; ages 0-35+; Stock Synthesis 3.30.23.1",
  "Chili_2025.dat; Chili_2025.ctl; 2025 assessment report, Section 2",
  "Age 35 is the plus-group accumulator. The 2025 model is a coastwide current-unit assessment spanning California, Oregon and Washington.")
add_assumption("catch", "catch_observations", "Eight fishery fleets; annual catch biomass in metric tons; catch log-scale SD 0.05",
  "Chili_2025.dat, catch section",
  "The seven -999 rows are equilibrium sentinels, not observations. The report describes catch as known with high precision.")
add_assumption("index", "index_series_and_units", "Six aggregate indices: two fishery CPUE series, two biomass-scaled trawl survey indices, one spawning-output index and one age-0 recruitment index",
  "Chili_2025.dat, CPUE and CPUEinfo sections; 2025 assessment report, Sections 2.2.1-2.2.4",
  "Native Stock Synthesis units codes 1, 30 and 33 are preserved. Index observations remain on their model scales; no absolute scaling or age-specific series is invented.")
add_assumption("index", "survey_timing", "July observations; within-year sampling_time 0.5",
  "Chili_2025.dat, CPUE, agecomp and lencomp sections; fleet timing entries",
  "All index and composition rows specify month 7. Sampling time is represented as (month - 1) / 12.")
add_assumption("composition", "composition_data", "Conditional age-at-length and length frequencies; ages 0-35; lengths 8-60 cm in 2-cm bins",
  "Chili_2025.dat, agecomp and lencomp sections; 2025 assessment report, Section 2.2",
  "Native frequency values, sample sizes, age-error definitions, partitions, sex codes and age-composition length bounds are retained. Age compositions are not marginal catch-at-age inputs.")
add_assumption("biology", "growth_weight_maturity", "Growth and weight-at-length are modeled; the 2025 model reuses the 2015 female maturity-at-length relationship",
  "Chili_2025.ctl; 2025 assessment report, Section 2.2.5 and Appendix C",
  "No empirical weight-at-age or maturity-at-age input surface is supplied. Report.sso has fitted length-based biological output, which the current output schema cannot represent.")
add_assumption("M", "natural_mortality", "Female M has a lognormal prior with median 5.4/Amax and log-scale SD 0.31; male M is an estimated exponential offset without an explicit prior",
  "Chili_2025.ctl; 2025 assessment report, Section 2.2.6; Report.sso M_AT_AGE",
  "The fitted age- and sex-specific M surface is imported from Report.sso. The .par file is unavailable, so age-specific uncertainty is not available.")
add_assumption("output", "uncertainty_and_predictions", "Published 2025 forecast intervals are available for spawning output and fraction unfished; no fitted covariance or composition predictions are cached",
  "2025 assessment report, Table e; model archive contents",
  "The archive contains Report.sso but no .par or CompReport.sso. Age-specific uncertainty and composition predictions are unavailable.")
assumptions <- do.call(rbind, assumption_rows)
output_rows <- list()
add_output <- function(type, measure, value, year, unit, age = NA_integer_, sex = "",
                       fleet = "", region = "U.S. Pacific Coast", se = NA_real_,
                       lwr = NA_real_, upr = NA_real_, source_type = "native_model",
                       reference, notes = "", scenario = "") {
  n <- max(length(value), length(year), length(age), length(sex), length(fleet),
    length(region), length(se), length(lwr), length(upr), length(scenario))
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, value = value,
    year = year, age = age, sex = sex, fleet = fleet, region = region, unit = unit,
    se = se, lwr = lwr, upr = upr, source_type = source_type,
    source_reference = reference, notes = notes, scenario = scenario)
}
add_surface <- function(data, year_col, sex_col, age_cols, type, measure, unit,
                        reference, notes = "", fleet_col = NULL,
                        source_type = "native_model") {
  n <- nrow(data)
  ages <- as.integer(age_cols)
  a <- length(ages)
  values <- as.vector(t(as.matrix(data[age_cols])))
  if (any(!is.finite(values))) stop("Non-finite values in output surface ", measure, ".", call. = FALSE)
  add_output(type = type, measure = measure, value = values,
    year = rep(as.integer(data[[year_col]]), each = a), age = rep(ages, times = n),
    sex = rep(sex_for(data[[sex_col]]), each = a),
    fleet = if (is.null(fleet_col)) "" else rep(fleet_names[as.integer(data[[fleet_col]])], each = a),
    unit = unit, reference = reference, notes = notes, source_type = source_type)
  invisible(NULL)
}

historical_years <- 1875:2024
ts <- fit$timeseries[fit$timeseries$Era == "TIME" & fit$timeseries$Yr %in% historical_years, , drop = FALSE]
ts <- ts[order(ts$Yr), , drop = FALSE]
forecast <- fit$timeseries[fit$timeseries$Era == "FORE" & fit$timeseries$Yr == 2025L, , drop = FALSE]
if (!identical(as.integer(ts$Yr), historical_years) || nrow(forecast) != 1L ||
    abs(forecast$SpawnBio - 9924.9) > 0.1 || abs(ts$SpawnBio[ts$Yr == 2024L] - 10467.4) > 0.1 ||
    abs(ts$Bio_all[ts$Yr == 2024L] - 44605.4) > 0.1 ||
    abs(ts$Recruit_0[ts$Yr == 2024L] - 68167.9) > 0.1) {
  stop("Report.sso TIME or forecast output does not match the reviewed assessment run.", call. = FALSE)
}
virgin_spawn <- fit$timeseries$SpawnBio[fit$timeseries$Era == "VIRG"]
if (length(virgin_spawn) != 1L || abs(virgin_spawn - 11922.2) > 0.1) {
  stop("Report.sso does not contain the reviewed unfished spawning-output baseline.", call. = FALSE)
}
add_output("biomass", "total_biomass", ts$Bio_all, ts$Yr, "metric tons",
  reference = "Report.sso, TIMESERIES Bio_all", notes = "Estimated total biomass.")
add_output("biomass", "summary_biomass", ts$Bio_smry, ts$Yr, "metric tons",
  reference = "Report.sso, TIMESERIES Bio_smry", notes = "Model-defined summary biomass; definition follows the assessment.")
add_output("biomass", "spawning_output", ts$SpawnBio, ts$Yr, "billion eggs",
  reference = "Report.sso, TIMESERIES SpawnBio", notes = "Estimated spawning output in billions of eggs.")
add_output("recruitment", "recruitment", ts$Recruit_0, ts$Yr, "thousand fish", age = 0L,
  reference = "Report.sso, TIMESERIES Recruit_0", notes = "Estimated age-0 recruitment in thousands of fish.")
add_output("biomass", "SSB_ratio", ts$SpawnBio / virgin_spawn, ts$Yr, "proportion",
  source_type = "derived_source_output",
  reference = "Derived from Report.sso TIMESERIES SpawnBio and the VIRG SpawnBio baseline",
  notes = "Spawning output divided by the assessment's unfished spawning-output baseline.")
add_output("biomass", "spawning_output", 9925, 2025L, "billion eggs",
  lwr = 6263, upr = 13587, source_type = "official_document",
  reference = "2025 assessment report, Table e",
  notes = "Published 2025 forecast point estimate and 95% asymptotic interval, rounded as reported; Report.sso point estimate is 9,924.9 billion eggs.",
  scenario = "2025 forecast")
add_output("biomass", "SSB_ratio", 0.832, 2025L, "proportion",
  lwr = 0.628, upr = 1.037, source_type = "official_document",
  reference = "2025 assessment report, Table e",
  notes = "Published 2025 fraction-unfished point estimate and 95% asymptotic interval, rounded as reported.",
  scenario = "2025 forecast")
add_output("recruitment", "recruitment", forecast$Recruit_0, 2025L, "thousand fish", age = 0L,
  reference = "Report.sso, TIMESERIES Recruit_0 FORE row",
  notes = "Forecast recruitment follows the stock-recruitment curve; it is not a new observation.",
  scenario = "2025 forecast")

n_surface <- fit$natage_annual_2_with_fishery
n_surface <- n_surface[n_surface$Yr %in% historical_years, , drop = FALSE]
n_surface <- n_surface[order(n_surface$Yr, n_surface$Sex), , drop = FALSE]
age_cols <- as.character(0:35)
if (nrow(n_surface) != length(historical_years) * 2L) stop("Unexpected annual N-at-age dimensions.", call. = FALSE)
add_surface(n_surface, "Yr", "Sex", age_cols, "population", "numbers_at_age", "thousand fish",
  "Report.sso, NUMBERS_AT_AGE annual with fishery",
  "Annual abundance-at-age surface as reported; age 35 is the plus-group accumulator.")
n_long <- data.frame(year = rep(as.integer(n_surface$Yr), each = length(age_cols)),
  value = as.vector(t(as.matrix(n_surface[age_cols]))))
total_n <- aggregate(value ~ year, n_long, sum)
add_output("population", "total_abundance", total_n$value, total_n$year, "thousand fish",
  source_type = "derived_source_output",
  reference = "Derived from Report.sso NUMBERS_AT_AGE annual with fishery",
  notes = "Total abundance is the sum across both sexes and ages 0-35, including the plus group.")

b_surface <- fit$batage[fit$batage$Era == "TIME" & fit$batage[["Beg/Mid"]] == "B" &
  fit$batage$Yr %in% historical_years, , drop = FALSE]
b_surface <- b_surface[order(b_surface$Yr, b_surface$Sex), , drop = FALSE]
if (nrow(b_surface) != length(historical_years) * 2L) stop("Unexpected beginning-year biomass-at-age dimensions.", call. = FALSE)
add_surface(b_surface, "Yr", "Sex", age_cols, "biomass", "biomass_at_age", "metric tons",
  "Report.sso, BIOMASS_AT_AGE Beg rows",
  "Beginning-of-year biomass contribution by age; age 35 is the plus-group accumulator.")

catch_surface <- fit$catage[fit$catage$Era == "TIME" & fit$catage$Yr %in% historical_years &
  fit$catage$Fleet %in% 1:8, , drop = FALSE]
catch_surface <- catch_surface[order(catch_surface$Yr, catch_surface$Fleet, catch_surface$Sex), , drop = FALSE]
add_surface(catch_surface, "Yr", "Sex", age_cols, "catch", "catch_numbers_at_age", "thousand fish",
  "Report.sso, CATCH_AT_AGE TIME rows",
  "Model-estimated catch numbers by age and fishery, not observed catch-at-age input.", fleet_col = "Fleet")

f_surface <- fit$fatage[fit$fatage$Era == "TIME" & fit$fatage$Yr %in% historical_years &
  fit$fatage$Fleet %in% 1:8, , drop = FALSE]
f_surface <- f_surface[order(f_surface$Yr, f_surface$Fleet, f_surface$Sex), , drop = FALSE]
add_surface(f_surface, "Yr", "Sex", age_cols, "mortality", "fishing_mortality_at_age", "yr-1",
  "Report.sso, F_AT_AGE TIME rows",
  "Fleet-specific instantaneous fishing mortality at age; age 35 is the plus-group accumulator.", fleet_col = "Fleet")

m_surface <- fit$M_at_age[fit$M_at_age$Yr %in% historical_years, , drop = FALSE]
z_surface <- fit$Z_at_age[fit$Z_at_age$Yr %in% historical_years, , drop = FALSE]
m_age_cols <- as.character(0:34)
m_surface <- m_surface[order(m_surface$Yr, m_surface$Sex), , drop = FALSE]
z_surface <- z_surface[order(z_surface$Yr, z_surface$Sex), , drop = FALSE]
if (nrow(m_surface) != length(historical_years) * 2L || nrow(z_surface) != nrow(m_surface)) {
  stop("Unexpected M-at-age or Z-at-age dimensions.", call. = FALSE)
}
add_surface(m_surface, "Yr", "Sex", m_age_cols, "mortality", "natural_mortality_at_age", "yr-1",
  "Report.sso, M_AT_AGE", "Instantaneous natural mortality at age; ages 0-34 have separate values.")
add_surface(z_surface, "Yr", "Sex", m_age_cols, "mortality", "total_mortality_at_age", "yr-1",
  "Report.sso, Z_AT_AGE", "Instantaneous total mortality at age; ages 0-34 have separate values.")
if (nrow(catch) != 756L || sum(dat$CPUE$year < 0L) != 22L ||
    sum(dat$lencomp$year < 0L) != 57L ||
    !all(dat$CPUEinfo$units %in% c(1L, 30L, 33L)) ||
    sum(inputs$measure == "catch_biomass") != 756L ||
    sum(inputs$measure == "log_catch_sd") != 756L ||
    sum(inputs$measure %in% c("relative_biomass_index", "spawning_output_index", "recruitment_index")) != 146L ||
    sum(inputs$measure == "log_index_sd") != 146L ||
    sum(inputs$measure == "conditional_frequency_at_age") != 91512L ||
    sum(inputs$measure == "frequency_at_length") != 13338L ||
    sum(inputs$measure == "age_error_mean_age") != 108L ||
    sum(inputs$measure == "ageing_error_sd") != 108L) {
  stop("Parsed rows differ from the reviewed Chilipepper source coverage.", call. = FALSE)
}
outputs <- do.call(rbind, output_rows)
input_keys <- do.call(paste, c(lapply(inputs[c("type", "measure", "fleet", "survey", "sex",
  "year", "age", "length_bin", "length_bin_lower", "length_bin_upper", "observation_id", "age_error")], function(x) {
    x[is.na(x)] <- ""
    as.character(x)
  }), sep = ""))
output_keys <- do.call(paste, c(lapply(outputs[c("type", "measure", "fleet", "survey", "sex",
  "region", "year", "age", "scenario")], function(x) {
    x[is.na(x)] <- ""
    as.character(x)
  }), sep = ""))
if (any(!is.finite(as.numeric(inputs$value))) || any(!is.finite(as.numeric(outputs$value))) ||
    anyDuplicated(input_keys) || anyDuplicated(output_keys)) {
  stop("Input/output values or row keys failed validation.", call. = FALSE)
}

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NWFSC/SWFSC", authority_stock_id = "17357",
  scientific_name = "Sebastes goodei",
  common_name = "Chilipepper rockfish - U.S. Pacific Coast",
  area = "U.S. Pacific Coast (U.S.-Mexico border to U.S.-Canada border)",
  region = "California, Oregon and Washington", ocean = "Northeast Pacific",
  notes = "Current U.S. coastwide stock unit in NOAA Stock SMART (ID 17357). The 2025 assessment covers California, Oregon and Washington; legacy NOAA:10395 is not treated as a distinct current stock, and the exact identifier crosswalk remains undocumented.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2025L,
  assessment_type = "benchmark_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.23.1", is_current = TRUE, is_applied = TRUE,
  assessment_url = report_url, data_url = model_url, model_url = model_url,
  repository_url = model_url, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed production assessment for NOAA:17357; report and native model files are cached under the local source cache. Inputs preserve catch biomass, aggregate indices, conditional age-at-length and length frequencies, and three age-error definitions; no observed catch-at-age or age-specific index is invented. Report.sso provides N, biomass, model-estimated catch numbers, fleet F, M and Z surfaces. 2025 forecast spawning-output and fraction-unfished intervals are from report Table e. No .par or CompReport.sso is in the cached archive, so age-specific uncertainty and composition predictions are unavailable. Standalone empirical weight-at-age and maturity-at-age inputs are not supplied; growth, weight and maturity are modelled on length scales.")

if (nrow(inputs) != 106870L || nrow(assumptions) != 8L || nrow(outputs) != 216303L ||
    sum(outputs$measure == "numbers_at_age") != 10800L ||
    sum(outputs$measure == "biomass_at_age") != 10800L ||
    sum(outputs$measure == "catch_numbers_at_age") != 86400L ||
    sum(outputs$measure == "fishing_mortality_at_age") != 86400L ||
    sum(outputs$measure == "natural_mortality_at_age") != 10500L ||
    sum(outputs$measure == "total_mortality_at_age") != 10500L ||
    sum(outputs$measure == "total_abundance") != 150L) {
  stop("Unexpected canonical row counts for the reviewed assessment.", call. = FALSE)
}

if (write_mode) {
  stocks_existing <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE)
  assessments_existing <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE)
  if (stock_id %in% stocks_existing$stock_id || assessment_id %in% assessments_existing$assessment_id ||
      "17357" %in% stocks_existing$authority_stock_id) {
    stop("The Chilipepper stock or assessment already exists; do not append it twice.", call. = FALSE)
  }
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)

  candidate_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L || !candidates$import_status[candidate_row] %in% c("not_started", "partial")) {
    stop("Expected one unimported NOAA:17357 candidate row.", call. = FALSE)
  }
  candidate <- candidates[candidate_row, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "Native catch biomass is available for eight fishery fleets, alongside fishery marginal age/length information and conditional age-at-length samples. Catch-at-age is a model-estimated output, not a direct input; source quantities are retained without reconstructing age splits here."
  candidate$survey_age_evidence <- "Two trawl surveys supply aggregate biomass-scaled indices plus length and conditional age-at-length samples. CalCOFI supplies a spawning-output index and RREAS an age-0 recruitment index. No observed age-specific abundance index is supplied."
  candidate$weights_evidence <- "Empirical weight-at-age input is disabled. Growth and weight-at-length are modelled; fitted length-based biological output is present in Report.sso but not represented in the age-only output schema."
  candidate$maturity_evidence <- "The model reuses the 2015 female maturity-at-length relationship. No standalone maturity-at-age input is supplied."
  candidate$mortality_evidence <- "Female M uses a lognormal prior with median 5.4/Amax and log-scale SD 0.31; male M is estimated as an exponential offset without an explicit prior. Report.sso includes age- and sex-specific M."
  candidate$timing_evidence <- "All index and composition observations use July (month 7), represented by sampling_time 0.5."
  candidate$output_evidence <- "Report.sso provides N-at-age, biomass-at-age, model-estimated catch numbers-at-age, fleet F-at-age, M-at-age, Z-at-age and annual aggregate series through 2024. Report Table e supplies 2025 forecast spawning-output and fraction-unfished intervals. No .par or CompReport.sso means age-specific uncertainty and composition predictions are unavailable."
  candidate$review_date <- "2026-11-11"
  candidate$decision_reason <- "The 2025 coastwide production assessment is the latest detailed assessment for the current U.S. Pacific Coast unit. Native data, control and Report.sso files are cached, and report spawning output matches the fitted report output to rounding."
  candidate$notes <- "Partial source import: native catch biomass and log SDs, aggregate indices and log SDs, conditional age-at-length and length frequencies, three age-error mean/SD definitions, assumptions, and Report.sso population/mortality/catch surfaces plus annual outputs. No direct observed catch-at-age or survey index-at-age was added; age-specific uncertainty, composition predictions and standalone age-scale weight/maturity inputs remain unavailable."
  replace_candidate_register_row(candidate_path, candidate_row, candidate, candidate_id)

  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  inventory_row <- which(inventory$candidate_unit_id == candidate_unit_id)
  if (length(inventory_row) != 1L || !inventory$import_status[inventory_row] %in% c("not_started", "partial")) {
    stop("Expected one unimported inventory unit for NOAA:17357.", call. = FALSE)
  }
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
    "unit_key", inventory$unit_key[inventory_row])

  batch_path <- file.path(root, "discovery/selected_batch_29_2026.csv")
  batch <- read.csv(batch_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  batch_row <- which(batch$candidate_id == candidate_id)
  if (length(batch_row) != 1L) stop("Expected one selected-batch row for NOAA:17357.", call. = FALSE)
  batch$candidate_unit_id[batch_row] <- candidate_unit_id
  batch$curation_status[batch_row] <- "partial_source_import"
  write.csv(batch, batch_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")

  unworked_path <- file.path(root, "discovery/selected_unworked_2026.csv")
  unworked <- read.csv(unworked_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  unworked_row <- which(unworked$candidate_id == candidate_id)
  if (length(unworked_row) == 1L) {
    unworked$curation_status[unworked_row] <- "source_curated_partial"
    write.csv(unworked, unworked_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }
  cat("Imported ", nrow(inputs), " inputs, ", nrow(assumptions), " assumptions, and ",
    nrow(outputs), " outputs for ", assessment_id, ".\n", sep = "")
} else {
  cat("Prepared ", nrow(inputs), " inputs, ", nrow(assumptions), " assumptions, and ",
    nrow(outputs), " outputs for ", assessment_id, ".\n", sep = "")
  cat("Inputs preserve 756 catch observations, 146 aggregate indices, ",
    sum(inputs$measure == "conditional_frequency_at_age"), " conditional age-at-length cells, and ",
    sum(inputs$measure == "frequency_at_length"), " length-frequency cells. Historical output ends in 2024; reported forecast outputs extend to 2025.\n", sep = "")
}






