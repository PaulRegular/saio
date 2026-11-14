root <- "."
source_dir <- file.path(root, "source_cache/discovery_noaa_darkblotched_2017")
model_dir <- file.path(source_dir, "model_files")
assessment_id <- "noaa_darkblotched_rockfish_2017"
stock_id <- "noaa_darkblotched_rockfish_pacific"
candidate_id <- "NOAA:10562"
candidate_unit_id <- "noaa_stocksmart_10562"
report_url <- paste0("https://www.pcouncil.org/documents/2018/01/",
  "status-of-the-darkblotched-rockfish-resource-off-the-continental-u-s-pacific-coast-in-2017-update-of-2015-assessment-model.pdf/")
model_url <- "https://www.pcouncil.org/documents/2017-darkblotched-assessment-model-files-13-3-mb/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(file.path(root, "provenance/discovery_noaa_darkblotched_2017/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
sha256_file <- function(path) toupper(unname(tools::sha256sum(path)))
verify_source <- function(file) {
  row <- manifest[manifest$cached_file == file, , drop = FALSE]
  path <- file.path(source_dir, file)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from the pinned provenance record: ", file, call. = FALSE)
  }
  path
}

invisible(verify_source("darkblotched_2017_model_files.zip"))
invisible(verify_source("wallace_gertseva_2017_assessment.pdf"))
invisible(verify_source("pfmc_2025_groundfish_assessment_status_table.pdf"))
if (!file.exists(file.path(model_dir, "darkblotched_data.ss")) ||
    !file.exists(file.path(model_dir, "darkblotched_control.ss")) ||
    !file.exists(file.path(model_dir, "Report.sso"))) {
  stop("The extracted native model inputs or Report.sso are missing.", call. = FALSE)
}

dat <- r4ss::SS_readdat(file = file.path(model_dir, "darkblotched_data.ss"), verbose = FALSE)
fit <- r4ss::SS_output(dir = model_dir, verbose = FALSE, printstats = FALSE,
  forecast = FALSE, warn = FALSE)
if (dat$endyr != 2016 || dat$styr != 1915 || dat$Nsexes != 2L ||
    dat$Nages != 45L || !identical(as.integer(dat$agebin_vector), 0:35) ||
    nrow(dat$fleetinfo) != 7L) {
  stop("The cached Stock Synthesis data dimensions differ from the reviewed run.", call. = FALSE)
}

fleet_names <- as.character(dat$fleetinfo$fleetname)
fleet_for <- function(code) fleet_names[abs(as.integer(code))]
sex_for <- function(code) c("female", "male")[as.integer(code)]
source_reference <- function(file, section) paste0(file, ", ", section)
input_rows <- list()
add_input <- function(...) {
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs",
    assessment_id = assessment_id, source_type = "native_model", ...)
}

catch <- dat$catch[dat$catch$year >= 1915 & dat$catch$year <= dat$endyr, , drop = FALSE]
for (fleet_id in sort(unique(catch$fleet))) {
  x <- catch[catch$fleet == fleet_id, , drop = FALSE]
  add_input(type = "catch", measure = "total_biomass", basis = "biomass",
    fleet = fleet_names[fleet_id], year = x$year, year_basis = "calendar_year",
    value = x$catch, unit = "metric tons",
    source_reference = source_reference("darkblotched_data.ss", "catch observations"),
    notes = "Native annual Stock Synthesis catch biomass. The year -999 model sentinel is not an observed calendar-year catch and is not stored as an observation.")
  add_input(type = "catch", measure = "log_catch_sd", basis = "log_scale",
    fleet = fleet_names[fleet_id], year = x$year, year_basis = "calendar_year",
    value = x$catch_se, unit = "log scale",
    source_reference = source_reference("darkblotched_data.ss", "catch observation standard errors"),
    notes = "Native catch_se values retained on the model's log scale.")
}

cpue <- dat$CPUE[order(dat$CPUE$index, dat$CPUE$year), , drop = FALSE]
add_input(type = "index", measure = "total_biomass", basis = "biomass",
  survey = fleet_names[cpue$index], year = cpue$year, year_basis = "calendar_year",
  season = "July", sampling_time = (cpue$month - 1) / 12,
  value = cpue$obs, unit = "metric tons",
  source_reference = source_reference("darkblotched_data.ss", "CPUE biomass indices"),
  notes = "Native aggregate bottom-trawl survey biomass index. Month 7 converts to sampling_time 0.5; fleet timing is also 0.5.")
add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
  survey = fleet_names[cpue$index], year = cpue$year, year_basis = "calendar_year",
  season = "July", sampling_time = (cpue$month - 1) / 12,
  value = cpue$se_log, unit = "log scale",
  source_reference = source_reference("darkblotched_data.ss", "CPUE log-scale standard errors"),
  notes = "Native se_log values retained without rescaling.")

add_compositions <- function(x, component) {
  age_component <- component == "age"
  bin_values <- if (age_component) as.integer(dat$agebin_vector) else as.integer(dat$lbin_vector)
  out <- list()
  for (i in seq_len(nrow(x))) {
    sex_code <- as.integer(x$sex[i])
    sex_parts <- switch(as.character(sex_code),
      "0" = list(list(name = "combined", cols = "f", add_male = TRUE)),
      "1" = list(list(name = "female", cols = "f")),
      "2" = list(list(name = "male", cols = "m")),
      "3" = list(list(name = "female", cols = "f"), list(name = "male", cols = "m")),
      stop("Unexpected composition sex code.", call. = FALSE))
    fleet_id <- abs(as.integer(x$fleet[i]))
    fishery <- fleet_id <= 3L
    fleet_label <- fleet_names[fleet_id]
    for (part in sex_parts) {
      columns <- paste0(part$cols, bin_values)
      values <- as.numeric(x[i, columns, drop = TRUE])
      if (isTRUE(part$add_male)) {
        values <- values + as.numeric(x[i, paste0("m", bin_values), drop = TRUE])
      }
      row_ref <- paste0(if (age_component) "agecomp" else "lencomp", " row ", i)
      add <- pacific_database_row("inputs", n = length(bin_values),
        assessment_id = assessment_id,
        type = if (fishery) "catch" else "index",
        measure = if (age_component) "frequency_at_age" else "frequency_at_length",
        basis = "native_frequency",
        fleet = if (fishery) fleet_label else "",
        survey = if (fishery) "" else fleet_label,
        sex = part$name, region = "U.S. Pacific Coast",
        season = "July", year = as.integer(x$year[i]), year_basis = "calendar_year",
        age = if (age_component) bin_values else NA_integer_,
        length_bin = if (age_component) NA_integer_ else bin_values,
        length_bin_lower = if (age_component && x$Lbin_lo[i] >= 0) x$Lbin_lo[i] else NA_real_,
        length_bin_upper = if (age_component && x$Lbin_hi[i] >= 0) x$Lbin_hi[i] else NA_real_,
        value = values, unit = "source frequency", sample_size = x$Nsamp[i],
        age_error = if (age_component) x$ageerr[i] else NA_integer_,
        partition = x$part[i], sampling_time = (x$month[i] - 1) / 12,
        observation_id = paste0(if (age_component) "agecomp" else "lencomp", ":", i, ":", part$name),
        source_type = "native_model", source_reference = source_reference("darkblotched_data.ss",
          if (age_component) "age-composition observations" else "length-composition observations"),
        notes = paste0("Native frequency values preserved without normalization. Signed source fleet code ",
          x$fleet[i], " maps to ", fleet_label, "; negative codes identify evaluation-only rows not included in the likelihood. ",
          if (age_component && x$Lbin_lo[i] >= 0) paste0("Conditional age-at-length source bounds Lbin_lo/Lbin_hi are ",
            x$Lbin_lo[i], "/", x$Lbin_hi[i], " cm. ") else "",
          "Source composition sex code ", sex_code, "; Nsamp, Part and Ageerr are retained.")
      )
      out[[length(out) + 1L]] <- add
    }
  }
  do.call(rbind, out)
}

age_compositions <- add_compositions(dat$agecomp, "age")
length_compositions <- add_compositions(dat$lencomp, "length")
input_rows[[length(input_rows) + 1L]] <- age_compositions
input_rows[[length(input_rows) + 1L]] <- length_compositions

age_error <- dat$ageerror
age_error_rows <- list()
for (code in 1:2) {
  sd_row <- 2L * code
  age_error_rows[[code]] <- pacific_database_row("inputs", n = 46L,
    assessment_id = assessment_id, type = "biology", measure = "ageing_error_sd",
    basis = "age_error_sd", age = 0:45, observation_id = paste0("age_error_", code),
    value = as.numeric(age_error[sd_row, ]), unit = "years", source_type = "native_model",
    source_reference = source_reference("darkblotched_data.ss", paste0("age-error definition ", code)),
    notes = "Native standard deviation of observed age by true age; the age midpoint vector in the preceding source row is 0.5-45.5 years.")
}
input_rows[[length(input_rows) + 1L]] <- do.call(rbind, age_error_rows)
inputs <- do.call(rbind, input_rows)

assumption_rows <- list()
add_assumption <- function(component, setting, value, reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = reference, notes = notes)
}
add_assumption("population", "model_dimensions", "1915-2016 input years; population dynamics begin in 1916 from an unfished 1915 equilibrium; one area; two sexes; ages 0-45 (age 45 accumulator)",
  "darkblotched_data.ss; Wallace and Gertseva (2017), Section 2",
  "The report treats 1915 as the unfished equilibrium reference year. Age compositions use bins 0-35.")
add_assumption("catch", "catch_data", "Three catch fleets; biomass in metric tons, 1915-2016",
  "darkblotched_data.ss; Wallace and Gertseva (2017), Table ES-1",
  "The model's -999 sentinel rows are not observations and are excluded from database input rows. Foreign POP fleet does not operate beyond 1976.")
add_assumption("index", "survey_series", "Four active biomass indices: AFSC shelf, AFSC slope, NWFSC slope, NWFSC shelf-slope",
  "darkblotched_data.ss; Wallace and Gertseva (2017), Section 2.1.2.1 and Figures 38-45",
  "31 aggregate survey observations, 1980-2016; values in metric tons. NWCBO is active in the supplied run.")
add_assumption("index", "survey_timing", "Data month 7; within-year time 0.5; all fleet timing entries 0.5",
  "darkblotched_data.ss, CPUE and fleet-info sections",
  "Month 7 is represented as (month - 1) / 12 = 0.5; this agrees with the fleet table.")
add_assumption("composition", "age_and_length_compositions", "Age bins 0-35; length bins 4-62 cm in 2-cm increments; fishery marginal and survey conditional age-at-length data",
  "darkblotched_data.ss; Wallace and Gertseva (2017), Sections 2.1 and Figures 61-79",
  "Source frequency values, sample size, partition, age-error definition, signed fleet IDs and conditional length bounds are preserved. Negative fleet-code rows are evaluation-only, not likelihood data.")
add_assumption("biology", "growth_weight_maturity_fecundity", "Sex-specific growth and weight-length relationships; female maturity and fecundity relationships",
  "darkblotched_control.ss; Wallace and Gertseva (2017), Section 2 and Figures 30-37",
  "The model derives biological surfaces; separately observed age-specific weight and maturity input vectors were not supplied or reconstructed here.")
add_assumption("M", "natural_mortality", "Female M fixed at 0.054 yr-1; male M estimated with a flat prior",
  "Wallace and Gertseva (2017), Section 2; Report.sso M_at_age",
  "Report.sso male M is approximately 0.0693217 yr-1. The fitted M-at-age surface is imported as an output.")
add_assumption("output", "uncertainty", "No age-specific uncertainty imported",
  "Report.sso; model archive contents",
  "The archive has Report.sso but no .par or CompReport.sso; age-specific standard errors and composition predictions are unavailable.")
assumptions <- do.call(rbind, assumption_rows)

output_rows <- list()
add_output <- function(type, measure, value, year, unit, age = NA_integer_, sex = "",
                       fleet = "", source_type = "native_model", reference,
                       notes = "", scenario = "") {
  n <- max(length(value), length(year), length(age), length(sex), length(fleet), length(scenario))
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, value = value,
    year = year, age = age, sex = sex, fleet = fleet, unit = unit,
    source_type = source_type, source_reference = reference,
    notes = notes, scenario = scenario)
}
add_surface <- function(data, year_col, sex_col, age_cols, type, measure, unit,
                        reference, notes = "", fleet_col = NULL,
                        source_type = "native_model") {
  n <- nrow(data); ages <- as.integer(age_cols); a <- length(ages)
  values <- as.vector(t(as.matrix(data[age_cols])))
  if (any(!is.finite(values))) stop("Non-finite values in Report.sso surface ", measure, ".", call. = FALSE)
  add_output(type = type, measure = measure, value = values,
    year = rep(as.integer(data[[year_col]]), each = a), age = rep(ages, times = n),
    sex = rep(sex_for(data[[sex_col]]), each = a),
    fleet = if (is.null(fleet_col)) "" else rep(fleet_names[as.integer(data[[fleet_col]])], each = a),
    unit = unit, reference = reference, notes = notes, source_type = source_type)
  invisible(NULL)
}

historical_years <- 1915:2016
ts <- fit$timeseries[fit$timeseries$Era == "TIME" & fit$timeseries$Yr %in% historical_years, , drop = FALSE]
ts <- ts[order(ts$Yr), , drop = FALSE]
if (!identical(as.integer(ts$Yr), historical_years) || any(!is.finite(ts$SPB_vir_LH))) {
  stop("Report.sso TIME series does not cover the expected historical years.", call. = FALSE)
}
virgin_spawn <- fit$timeseries$SpawnBio[fit$timeseries$Era == "VIRG"]
if (length(virgin_spawn) != 1L || !is.finite(virgin_spawn) || virgin_spawn <= 0) {
  stop("Report.sso does not contain one positive virgin spawning-output reference.", call. = FALSE)
}
add_output("biomass", "total_biomass", ts$Bio_all, ts$Yr, "metric tons",
  reference = "Report.sso, TIMESERIES Bio_all", notes = "Estimated beginning-of-year total biomass.")
add_output("biomass", "summary_biomass", ts$Bio_smry, ts$Yr, "metric tons",
  reference = "Report.sso, TIMESERIES Bio_smry", notes = "Estimated summary biomass as defined by the Stock Synthesis model.")
add_output("biomass", "spawning_output", ts$SpawnBio, ts$Yr, "eggs",
  reference = "Report.sso, TIMESERIES SpawnBio", notes = "Model spawning output in eggs; the assessment report also presents this in million eggs.")
add_output("recruitment", "recruitment", ts$Recruit_0, ts$Yr, "thousand fish", age = 0L,
  reference = "Report.sso, TIMESERIES Recruit_0", notes = "Estimated age-0 recruits; thousand fish.")
add_output("biomass", "SSB_ratio", ts$SpawnBio / virgin_spawn, ts$Yr, "proportion",
  source_type = "derived_source_output", reference = "Derived from Report.sso TIMESERIES SpawnBio and the VIRG SpawnBio baseline",
  notes = "Spawning output divided by the model's unfished spawning output from the VIRG row.")

n_surface <- fit$natage_annual_2_with_fishery
n_surface <- n_surface[n_surface$Year %in% historical_years, , drop = FALSE]
n_surface <- n_surface[order(n_surface$Year, n_surface$Gender), , drop = FALSE]
ages <- as.character(0:45)
if (nrow(n_surface) != length(historical_years) * 2L) stop("Unexpected annual N-at-age dimensions.", call. = FALSE)
add_surface(n_surface, "Year", "Gender", ages, "population", "numbers_at_age", "thousand fish",
  "Report.sso, NUMBERS_AT_AGE annual with fishery", "Beginning-of-year abundance after fishery mortality; age 45 is the accumulator.")
n_long <- data.frame(year = rep(n_surface$Year, each = length(ages)),
  value = as.vector(t(as.matrix(n_surface[ages]))))
total_n <- aggregate(value ~ year, n_long, sum)
add_output("population", "total_abundance", total_n$value, total_n$year, "thousand fish",
  source_type = "derived_source_output", reference = "Derived from Report.sso NUMBERS_AT_AGE annual with fishery",
  notes = "Sum of numbers-at-age across both sexes and ages 0-45, including the age-45 accumulator.")

b_surface <- fit$batage[fit$batage$Era == "TIME" & fit$batage$`Beg/Mid` == "B" &
  fit$batage$Yr %in% historical_years, , drop = FALSE]
b_surface <- b_surface[order(b_surface$Yr, b_surface$Gender), , drop = FALSE]
add_surface(b_surface, "Yr", "Gender", ages, "biomass", "biomass_at_age", "metric tons",
  "Report.sso, BIOMASS_AT_AGE Beg rows", "Beginning-of-year biomass contribution at age; ages sum to Bio_all, with age 45 as accumulator.")

catch_surface <- fit$catage[fit$catage$Era == "TIME" & fit$catage$Yr %in% historical_years &
  fit$catage$Fleet %in% 1:3, , drop = FALSE]
catch_surface <- catch_surface[order(catch_surface$Yr, catch_surface$Fleet, catch_surface$Gender), , drop = FALSE]
add_surface(catch_surface, "Yr", "Gender", ages, "catch", "catch_numbers_at_age", "thousand fish",
  "Report.sso, CATCH_AT_AGE TIME rows", "Model-estimated catch numbers by age and fleet, not observed catch-at-age input.", fleet_col = "Fleet")

m_surface <- fit$M_at_age[fit$M_at_age$Year %in% historical_years, , drop = FALSE]
z_surface <- fit$Z_at_age[fit$Z_at_age$Year %in% historical_years, , drop = FALSE]
m_age_cols <- as.character(0:44)
m_surface <- m_surface[order(m_surface$Year, m_surface$Gender), , drop = FALSE]
z_surface <- z_surface[order(z_surface$Year, z_surface$Gender), , drop = FALSE]
add_surface(m_surface, "Year", "Gender", m_age_cols, "mortality", "natural_mortality_at_age", "yr-1",
  "Report.sso, M_AT_AGE", "Instantaneous natural mortality at age; age 45 is an accumulator and has no separate M value.")
z_key <- paste(z_surface$Year, z_surface$Gender)
m_key <- paste(m_surface$Year, m_surface$Gender)
if (!identical(z_key, m_key)) stop("M and Z output rows do not align.", call. = FALSE)
z_minus_m <- as.data.frame(as.matrix(z_surface[m_age_cols]) - as.matrix(m_surface[m_age_cols]))
z_minus_m$Year <- z_surface$Year
z_minus_m$Gender <- z_surface$Gender
add_surface(z_minus_m, "Year", "Gender", m_age_cols, "mortality", "fishing_mortality_at_age", "yr-1",
  "Derived from Report.sso Z_AT_AGE minus M_AT_AGE", "Total instantaneous F at age is Z minus M; it is not fleet-specific.",
  source_type = "derived_source_output")

if (nrow(inputs) != 42658L || nrow(assumptions) != 8L ||
    !all(c("AKSHLF", "AKSLP", "NWSLP", "NWCBO") %in% fleet_names) ||
    nrow(cpue) != 31L || nrow(dat$agecomp) != 941L || nrow(dat$lencomp) != 98L) {
  stop("Parsed rows differ from reviewed Darkblotched source coverage.", call. = FALSE)
}
outputs <- do.call(rbind, output_rows)
input_keys <- do.call(paste, c(inputs[c("type", "measure", "fleet", "survey", "sex",
  "year", "age", "length_bin", "length_bin_lower", "length_bin_upper", "observation_id")], sep = "\r"))
if (any(!is.finite(as.numeric(inputs$value))) || any(!is.finite(as.numeric(outputs$value))) ||
    anyDuplicated(input_keys)) {
  stop("Input/output values or row keys failed validation.", call. = FALSE)
}

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NWFSC/SWFSC", authority_stock_id = "10562",
  scientific_name = "Sebastes crameri", common_name = "Darkblotched rockfish - U.S. Pacific Coast",
  area = "U.S. Pacific Coast (Washington, Oregon and California)", region = "NWFSC / SWFSC",
  ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART ID 10562. The coastwide U.S. unit is separate from Canadian waters occupied by the species.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2017L, terminal_year = 2016L, estimate_terminal_year = 2016L,
  assessment_type = "update_assessment", model_family = "Stock Synthesis", model_version = "3.30.01.12",
  is_current = TRUE, is_applied = TRUE, assessment_url = report_url, data_url = model_url,
  model_url = model_url, repository_url = model_url, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed full age-structured assessment for the current U.S. Pacific Coast unit is the 2017 update of the 2015 model, with data through 2016. Later 2019/2025 activity is catch-only projection and is not mixed into this run. Native catches, four survey indices, age/length composition frequencies and age-error SDs are imported. Report.sso N, biomass, catch, M and Z surfaces and aggregate outputs are imported; total F, total abundance and SSB ratio are explicitly derived. Standalone observed weight-at-age/maturity-at-age, direct catch-at-age inputs and uncertainty remain unavailable. The cached archive has no .par or CompReport.sso.")

if (nrow(inputs) < 42000L || nrow(outputs) < 65000L ||
    sum(inputs$measure == "frequency_at_age") != 36432L ||
    sum(inputs$measure == "frequency_at_length") != 5460L ||
    sum(outputs$measure == "numbers_at_age") != 9384L ||
    sum(outputs$measure == "natural_mortality_at_age") != 9180L ||
    sum(outputs$measure == "fishing_mortality_at_age") != 9180L) {
  stop("Unexpected canonical row counts for the reviewed assessment.", call. = FALSE)
}

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidate_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L || candidates$import_status[candidate_row] != "not_started") {
    stop("Expected one unimported NOAA:10562 candidate row.", call. = FALSE)
  }
  candidate <- candidates[candidate_row, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "The run supplies biomass catches for three fleets and native fishery marginal age-frequency samples. Observed catch-at-age is not a direct input; the Report.sso catch-at-age surface is model-estimated, not an observed input."
  candidate$survey_age_evidence <- "Four active aggregate biomass indices are present: AFSC shelf (AKSHLF), AFSC slope (AKSLP), NWFSC slope (NWSLP), and NWFSC shelf-slope (NWCBO), along with survey conditional age-at-length compositions. No observed age-specific survey index is supplied."
  candidate$weights_evidence <- "The control file and report describe sex-specific growth and weight-length relationships. A standalone observed weight-at-age input schedule is not supplied; Report.sso biomass-at-age is an estimated output."
  candidate$maturity_evidence <- "The model includes female maturity and fecundity relationships; numerical age-specific biological input vectors are not supplied as independent observations in the archive."
  candidate$mortality_evidence <- "Female natural mortality is fixed at 0.054 yr-1; male natural mortality is estimated with a flat prior (Report.sso approximately 0.0693217 yr-1)."
  candidate$timing_evidence <- "The four survey series are recorded in July (month 7), which maps to sampling_time 0.5; the fleet timing entries are also 0.5."
  candidate$output_evidence <- "Report.sso provides annual N-at-age, biomass-at-age, model-estimated catch numbers-at-age, M-at-age and Z-at-age through 2016; total F is derived as Z-M. Aggregate biomass, spawning output and age-0 recruitment are available. No .par/CompReport.sso means age-specific uncertainty and composition predictions are unavailable."
  candidate$review_date <- "2026-11-11"
  candidate$decision_reason <- "The 2017 update is the latest detailed full age-structured assessment for the current NOAA Pacific Coast unit; later 2019/2025 activity is catch-only projection. The native run and official report support a partial source import with verified inputs and run-matched age-specific outputs."
  candidate$notes <- "Partial source import: three fleets' annual catch biomass and log SDs; four active survey biomass series and log SDs; native age- and length-frequency compositions; two age-error SD definitions; assumptions; and Report.sso outputs. No observed age-specific catch/index, standalone observed age-specific weight/maturity, .par, or age-specific uncertainty was supplied."
  replace_candidate_register_row(candidate_path, candidate_row, candidate, candidate_id)

  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  inventory_row <- which(inventory$candidate_unit_id == candidate_unit_id)
  if (length(inventory_row) != 1L || inventory$import_status[inventory_row] != "not_started") {
    stop("Expected one unimported inventory unit for NOAA:10562.", call. = FALSE)
  }
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
    "unit_key", inventory$unit_key[inventory_row])

  batch_path <- file.path(root, "discovery/selected_batch_28_2026.csv")
  batch <- read.csv(batch_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
  batch_row <- which(batch$candidate_id == candidate_id)
  if (length(batch_row) != 1L) stop("Expected one selected-batch row for NOAA:10562.", call. = FALSE)
  batch$candidate_unit_id[batch_row] <- candidate_unit_id
  batch$curation_status[batch_row] <- "partial_source_import"
  write.csv(batch, batch_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat("Imported ", nrow(inputs), " inputs, ", nrow(assumptions), " assumptions, and ",
    nrow(outputs), " outputs for ", assessment_id, ".\n", sep = "")
} else {
  cat("Prepared ", nrow(inputs), " inputs, ", nrow(assumptions), " assumptions, and ",
    nrow(outputs), " outputs for ", assessment_id, ".\n", sep = "")
  cat("Inputs include ", sum(inputs$measure == "total_biomass" & inputs$type == "index"),
    " survey observations, ", sum(inputs$measure == "frequency_at_age"), " age-frequency rows, and ",
    sum(inputs$measure == "frequency_at_length"), " length-frequency rows. Outputs end in 2016.\n", sep = "")
}
