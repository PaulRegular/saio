root <- "."
cache <- file.path(root, "source_cache/discovery_noaa_cabezon_2019")
assessment_id <- "noaa_cabezon_oregon_2019"
stock_id <- "noaa_cabezon_oregon"
candidate_id <- "NOAA:12193"
candidate_unit_id <- "noaa_cabezon_oregon_2019"
report_url <- "https://www.pcouncil.org/documents/2019/10/assessing-cabezon-scorpaenichthys-marmoratus-stocks-in-waters-off-of-california-and-oregon-with-catch-limit-estimation-for-washington-state-10-18-2019.pdf/"
model_url <- "https://www.pcouncil.org/documents/cabezon-ors-model-files-zip-file/"
supplement_url <- "https://www.pcouncil.org/documents/2019/10/cabezon-supplementary-tables-october-2019.xlsx/"
star_url <- "https://www.pcouncil.org/documents/2019/10/cabezon-star-panel-report-may-6-10-2019.pdf/"
region <- "Oregon"
years <- 1970:2018
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
test_mode <- identical(Sys.getenv("TAM_SOURCE_TEST_MODE"), "1")
if (test_mode && write_mode) {
  stop("Source test mode cannot write database records.", call. = FALSE)
}

.libPaths(c(file.path(root, "source_cache/r-lib"),
  file.path(root, "source_cache/R-library"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(file.path(root,
  "provenance/noaa_cabezon_oregon_2019_sources.csv"),
  colClasses = "character", check.names = FALSE)
source_files <- c(
  "discovery_noaa_cabezon_2019/cabezon_2019_assessment.pdf",
  "discovery_noaa_cabezon_2019/cabezon_2019_supplementary_tables.xlsx",
  "discovery_noaa_cabezon_2019/cabezon_2019_star_panel.pdf",
  "discovery_noaa_cabezon_2019/cabezon_2019_ors_model.zip",
  "discovery_noaa_cabezon_2019/cabezon_2019_scs_model.zip",
  "discovery_noaa_cabezon_2019/cabezon_2019_ncs_model.zip")
if (!all(c("local_file", "source_url", "retrieved_on", "sha256", "bytes") %in% names(manifest)) ||
    !setequal(manifest$local_file, source_files) || anyDuplicated(manifest$local_file)) {
  stop("The cabezon source manifest is incomplete.", call. = FALSE)
}
sha256_file <- function(path) unname(tools::sha256sum(path))
for (local_file in source_files) {
  row <- manifest[manifest$local_file == local_file, , drop = FALSE]
  path <- file.path(root, "source_cache", local_file)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.numeric(row$bytes) != file.info(path)$size ||
      !identical(tolower(row$sha256), tolower(sha256_file(path)))) {
    stop("Cached cabezon source differs from its pinned manifest: ", local_file,
      call. = FALSE)
  }
}
if (!all(manifest$retrieved_on == "2026-11-11")) {
  stop("The pinned cabezon source retrieval date changed.", call. = FALSE)
}
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to read the cached cabezon assessment sources.", call. = FALSE)
}

one_file <- function(directory, pattern) {
  files <- list.files(directory, pattern = pattern, recursive = TRUE,
    full.names = TRUE)
  if (length(files) != 1L) {
    stop("Expected one ", pattern, " under ", directory, call. = FALSE)
  }
  files
}
model_dir <- tempfile("cabezon_ors_2019_")
dir.create(model_dir)
utils::unzip(file.path(cache, "cabezon_2019_ors_model.zip"), exdir = model_dir)
data_file <- one_file(model_dir, "^ORcab_data[.]ss$")
control_file <- one_file(model_dir, "^ORcab_control[.]ss$")
report_file <- one_file(model_dir, "^Report[.]sso$")
model_dir <- dirname(report_file)
dat <- r4ss::SS_readdat(data_file, version = "3.30.13", verbose = FALSE)
fit <- r4ss::SS_output(dir = model_dir, covar = FALSE, forecast = FALSE,
  warn = FALSE, readwt = TRUE, verbose = FALSE)

age_bins <- as.integer(dat$agebin_vector)
length_bins <- as.integer(dat$lbin_vector)
conditional_age <- dat$agecomp$Lbin_lo >= 0 & dat$agecomp$Lbin_hi >= 0
marginal_age <- dat$agecomp$Lbin_lo < 0 & dat$agecomp$Lbin_hi < 0
if (dat$styr != 1970L || dat$endyr != 2018L || dat$nseas != 1L ||
    dat$Nages != 20L || dat$Nsexes != 2L || nrow(dat$fleetinfo) != 9L ||
    !identical(age_bins, 0:20) || !identical(length_bins, seq.int(4L, 92L, by = 2L)) ||
    nrow(dat$catch) != 200L || sum(dat$catch$year == -999L) != 4L ||
    sum(dat$catch$year %in% years) != 196L ||
    nrow(dat$CPUE) != 68L || !identical(sort(unique(as.integer(dat$CPUE$index))), 5:8) ||
    any(dat$CPUE$month != 7L) || any(dat$CPUE$obs <= 0 | dat$CPUE$se_log <= 0) ||
    nrow(dat$lencomp) != 129L || nrow(dat$agecomp) != 597L ||
    sum(conditional_age) != 525L || sum(marginal_age) != 72L ||
    any(!(conditional_age | marginal_age)) ||
    length(unique(fit$timeseries$Yr[fit$timeseries$Area == 1L &
      fit$timeseries$Era == "TIME" & fit$timeseries$Yr %in% years])) != length(years)) {
  stop("The cached ORS inputs or Report.sso do not match the reviewed 2019 assessment.",
    call. = FALSE)
}

fleet_names <- as.character(dat$fleetinfo$fleetname)
fleet_types <- as.integer(dat$fleetinfo$type)
source_ref <- function(file, section) paste0(file, ", ", section)
input_rows <- list()
output_rows <- list()
assumption_rows <- list()
add_input <- function(...) {
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs",
    assessment_id = assessment_id, source_type = "native_model", ...)
}
add_output <- function(...) {
  values <- list(...)
  values$assessment_id <- assessment_id
  if (is.null(values$source_type)) values$source_type <- "native_model"
  output_rows[[length(output_rows) + 1L]] <<- do.call(pacific_database_row,
    c(list(table = "outputs"), values))
}
add_assumption <- function(component, setting, value, source, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row(
    "assumptions", assessment_id = assessment_id, component = component,
    region = region, setting = setting, value = value,
    source_reference = source, notes = notes)
}

# Native input data
catch <- dat$catch[dat$catch$year %in% years, , drop = FALSE]
catch_fleet <- fleet_names[as.integer(catch$fleet)]
add_input(type = "catch", measure = "catch_biomass", basis = "biomass",
  fleet = catch_fleet, region = region, year = catch$year,
  year_basis = "calendar_year", season = "annual", value = catch$catch,
  unit = "metric tons", source_reference = source_ref("ORcab_data.ss", "catch block"),
  notes = "Annual fishery catch biomass used by the 2019 Oregon model. Four -999 equilibrium/sentinel rows are not calendar-year observations and are excluded.")
add_input(type = "catch", measure = "catch_se", basis = "log_scale",
  fleet = catch_fleet, region = region, year = catch$year,
  year_basis = "calendar_year", season = "annual", value = catch$catch_se,
  unit = "log-scale standard error",
  source_reference = source_ref("ORcab_data.ss", "catch uncertainty field"),
  notes = "Native catch observation error values retained separately from catch biomass.")

cpue <- dat$CPUE[order(dat$CPUE$index, dat$CPUE$year), , drop = FALSE]
cpue_info <- dat$CPUEinfo[match(cpue$index, dat$CPUEinfo$fleet), , drop = FALSE]
cpue_survey <- fleet_names[as.integer(cpue$index)]
cpue_time <- (as.integer(cpue$month) - 1) / 12
cpue_measure <- ifelse(cpue_info$units == 1L,
  "relative_biomass_index", "relative_abundance_index")
cpue_unit <- ifelse(cpue_info$units == 1L,
  "native relative biomass-index units (Stock Synthesis CPUE units code 1)",
  "native relative abundance-index units (Stock Synthesis CPUE units code 0)")
add_input(type = "index", measure = cpue_measure, basis = "index_scale",
  survey = cpue_survey, region = region, year = cpue$year,
  year_basis = "calendar_year", season = paste0("month ", cpue$month),
  sampling_time = cpue_time, value = cpue$obs, unit = cpue_unit,
  source_reference = source_ref("ORcab_data.ss", "CPUE observations"),
  notes = "Four aggregate lognormal indices. Stock Synthesis units code 1 denotes biomass and code 0 denotes numbers; neither is an absolute abundance scale.")
add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
  survey = cpue_survey, region = region, year = cpue$year,
  year_basis = "calendar_year", season = paste0("month ", cpue$month),
  sampling_time = cpue_time, value = cpue$se_log,
  unit = "standard error on log index",
  source_reference = source_ref("ORcab_data.ss", "CPUE se_log field"),
  notes = "Native lognormal observation standard errors for the aggregate indices.")

add_compositions <- function(x, kind, bins) {
  is_age <- kind == "age"
  for (i in seq_len(nrow(x))) {
    row <- x[i, , drop = FALSE]
    code <- as.integer(row$sex)
    vector_for <- function(prefix) as.numeric(unlist(
      row[1L, paste0(prefix, bins), drop = FALSE], use.names = FALSE))
    female <- vector_for("f")
    male <- vector_for("m")
    parts <- if (code == 3L) {
      list(female = female, male = male)
    } else if (code == 1L) {
      list(female = female)
    } else if (code == 2L) {
      list(male = male)
    } else if (code == 0L && (all(male == 0) || isTRUE(all.equal(female, male)))) {
      list(combined = female)
    } else {
      stop("Unexpected sex code or frequency vector in ORS ", kind,
        " row ", i, ".", call. = FALSE)
    }
    fleet_id <- abs(as.integer(row$fleet))
    is_fishery <- fleet_types[fleet_id] == 1L
    is_conditional <- is_age && conditional_age[i]
    measure <- if (is_conditional) "conditional_frequency_at_age" else
      if (is_age) "frequency_at_age" else "frequency_at_length"
    input_type <- if (is_conditional) "biology" else if (is_fishery) "catch" else "index"
    note <- if (is_conditional) {
      "Native conditional age-at-length frequency; length bounds are centimetres."
    } else if (is_age) {
      "Native marginal age-composition frequency supplied for model evaluation; the negative source fleet code marks it as evaluation-only."
    } else {
      "Native length-composition frequency."
    }
    note <- paste(note,
      "Frequency cells and Nsamp are retained without normalization or expansion.",
      if (code == 3L) "Source sex code 3 provides separate female and male vectors." else
        paste("Source sex code", code, "is retained as", names(parts)[1L], "."),
      if (as.integer(row$fleet) < 0L) paste0("Signed source fleet code ",
        row$fleet, " is retained in observation_id; its absolute fleet ID names the sampling program.") else "")
    for (sex_name in names(parts)) {
      add_input(type = input_type, measure = measure, basis = "native_frequency",
        fleet = if (is_fishery) fleet_names[fleet_id] else "",
        survey = if (!is_fishery) fleet_names[fleet_id] else "",
        sex = sex_name, region = region, year = as.integer(row$year),
        year_basis = "calendar_year", season = paste0("month ", row$month),
        sampling_time = (as.integer(row$month) - 1) / 12,
        age = if (is_age) bins else NA_real_,
        length_bin = if (!is_age) bins else NA_real_,
        length_bin_lower = if (is_conditional) as.numeric(row$Lbin_lo) else NA_real_,
        length_bin_upper = if (is_conditional) as.numeric(row$Lbin_hi) else NA_real_,
        value = parts[[sex_name]], unit = "source frequency",
        sample_size = as.numeric(row$Nsamp),
        age_error = if (is_age) as.integer(row$ageerr) else NA_integer_,
        partition = as.character(row$part),
        source_reference = source_ref("ORcab_data.ss",
          if (is_conditional) "conditional age-at-length block" else
            if (is_age) "marginal age-composition block" else "length-composition block"),
        notes = note,
        observation_id = paste(kind, i, "source_fleet", row$fleet, sex_name, sep = ":"))
    }
  }
}
add_compositions(dat$lencomp, "length", length_bins)
add_compositions(dat$agecomp, "age", age_bins)

surface_long <- function(x, ages, year_column = "Yr", sex_column = "Sex") {
  values <- as.matrix(x[, as.character(ages), drop = FALSE])
  storage.mode(values) <- "numeric"
  result <- data.frame(year = rep(as.integer(x[[year_column]]), each = length(ages)),
    sex = rep(ifelse(as.integer(x[[sex_column]]) == 1L, "female", "male"),
      each = length(ages)),
    age = rep(ages, times = nrow(x)), value = as.vector(t(values)))
  if ("Fleet" %in% names(x)) result$fleet <- rep(fleet_names[as.integer(x$Fleet)],
    each = length(ages))
  result
}
population_rows <- function(x) x$Area == 1L & x$Bio_Pattern == 1L &
  x$Sex %in% 1:2 & x$Morph == x$Sex & x$Seas == 1L &
  x$Era == "TIME" & x$Yr %in% years
population_filter <- function(x) population_rows(x) & x$BirthSeas == 1L &
  x$Settlement == 1L & x$Platoon == 1L & x[["Beg/Mid"]] == "B"
n_rows <- fit$natage[population_filter(fit$natage), , drop = FALSE]
b_rows <- fit$batage[population_filter(fit$batage), , drop = FALSE]
f_rows <- fit$fatage[fit$fatage$Area == 1L & fit$fatage$Fleet %in% 1:4 &
  fit$fatage$Sex %in% 1:2 & fit$fatage$Morph == fit$fatage$Sex &
  fit$fatage$Seas == 1L & fit$fatage$Era == "TIME" &
  fit$fatage$Yr %in% years, , drop = FALSE]
c_rows <- fit$catage[fit$catage$Area == 1L & fit$catage$Fleet %in% 1:4 &
  fit$catage$Sex %in% 1:2 & fit$catage$Type == "dead" &
  fit$catage$Morph == fit$catage$Sex & fit$catage$Seas == 1L &
  fit$catage$Era == "TIME" & fit$catage$Yr %in% years, , drop = FALSE]
m_rows <- fit$M_at_age[fit$M_at_age$Bio_Pattern == 1L &
  fit$M_at_age$Sex %in% 1:2 & fit$M_at_age$Yr %in% years, , drop = FALSE]
w_rows <- fit$wtatage[fit$wtatage$seas == 1L & fit$wtatage$bio_pattern == 1L &
  fit$wtatage$birthseas == 1L & fit$wtatage$fleet == 0L &
  fit$wtatage$sex %in% 1:2 & fit$wtatage$year %in% years, , drop = FALSE]
if (nrow(n_rows) != 98L || nrow(b_rows) != 98L || nrow(f_rows) != 392L ||
    nrow(c_rows) != 392L || nrow(m_rows) != 98L || nrow(w_rows) != 98L) {
  stop("The ORS Report.sso age surfaces do not have the reviewed historical dimensions.",
    call. = FALSE)
}
n_long <- surface_long(n_rows, age_bins)
b_long <- surface_long(b_rows, age_bins)
f_long <- surface_long(f_rows, age_bins)
c_long <- surface_long(c_rows, age_bins)
m_long <- surface_long(m_rows, 0:19)
w_values <- as.matrix(w_rows[, as.character(age_bins), drop = FALSE])
storage.mode(w_values) <- "numeric"
w_long <- data.frame(year = rep(as.integer(w_rows$year), each = length(age_bins)),
  sex = rep(ifelse(as.integer(w_rows$sex) == 1L, "female", "male"),
    each = length(age_bins)), age = rep(age_bins, times = nrow(w_rows)),
  value = as.vector(t(w_values)))
if (nrow(n_long) != 98L * 21L || nrow(b_long) != 98L * 21L ||
    nrow(f_long) != 392L * 21L || nrow(c_long) != 392L * 21L ||
    nrow(m_long) != 98L * 20L || nrow(w_long) != 98L * 21L ||
    any(!is.finite(c(n_long$value, b_long$value, f_long$value,
      c_long$value, m_long$value, w_long$value)))) {
  stop("The ORS Report.sso surfaces contain unexpected ages or missing estimates.",
    call. = FALSE)
}
weight_check <- merge(b_long, n_long, by = c("year", "sex", "age"),
  suffixes = c("_biomass", "_numbers"))
weight_check <- merge(weight_check, w_long, by = c("year", "sex", "age"))
if (max(abs(weight_check$value_biomass / weight_check$value_numbers -
    weight_check$value)) > 5e-5) {
  stop("Population weight-at-age does not match the Report.sso biomass/numbers surfaces.",
    call. = FALSE)
}
m_input <- aggregate(value ~ sex + age, m_long, function(x) {
  if (max(x) - min(x) > 1e-10) stop("The supposedly fixed ORS M surface varies by year.",
    call. = FALSE)
  x[1L]
})
add_input(type = "M", measure = "natural_mortality_at_age", basis = "per_year",
  sex = m_input$sex, region = region, age = m_input$age, value = m_input$value,
  unit = "year^-1", source_reference = source_ref("ORcab_control.ss and Report.sso",
    "fixed sex-specific M; M_at_age output"),
  notes = "Fixed, time-invariant natural mortality by sex. Age 20 is not assigned a reported M value.")
add_output(type = "population", measure = "numbers_at_age", region = region,
  year = n_long$year, sex = n_long$sex, age = n_long$age, value = n_long$value,
  unit = "thousand fish", source_reference = source_ref("Report.sso", "NUMBERS_AT_AGE"),
  notes = "Fitted beginning-year numbers at age; age 20 is the plus group.")
add_output(type = "biomass", measure = "biomass_at_age", region = region,
  year = b_long$year, sex = b_long$sex, age = b_long$age, value = b_long$value,
  unit = "metric tons", source_reference = source_ref("Report.sso", "BIOMASS_AT_AGE"),
  notes = "Fitted beginning-year population biomass at age; age 20 is the plus group.")
add_output(type = "biology", measure = "weight_at_age", region = region,
  year = w_long$year, sex = w_long$sex, age = w_long$age, value = w_long$value,
  unit = "kg per fish", source_reference = source_ref("Report.sso", "Wtatage, population fleet 0"),
  notes = "Model-derived beginning-year population weight at age, not an independent observed weight-at-age input. Its scale matches biomass at age divided by numbers at age.")
add_output(type = "mortality", measure = "fishing_mortality_at_age", region = region,
  fleet = f_long$fleet, year = f_long$year, sex = f_long$sex, age = f_long$age,
  value = f_long$value, unit = "year^-1",
  source_reference = source_ref("Report.sso", "F_AT_AGE"),
  notes = "Fitted fleet-specific fishing mortality at age; age 20 is the plus group.")
add_output(type = "catch", measure = "catch_numbers_at_age", region = region,
  fleet = c_long$fleet, year = c_long$year, sex = c_long$sex, age = c_long$age,
  value = c_long$value, unit = "thousand fish",
  source_reference = source_ref("Report.sso", "CATCH_AT_AGE"),
  notes = "Fitted dead catch at age from the model. This is a model output, not observed catch-at-age input.")
add_output(type = "mortality", measure = "natural_mortality_at_age", region = region,
  year = m_long$year, sex = m_long$sex, age = m_long$age, value = m_long$value,
  unit = "year^-1", source_reference = source_ref("Report.sso", "M_at_age"),
  notes = "Fitted-report surface for fixed, sex-specific M; age 20 has no reported value.")

time_series <- fit$timeseries[fit$timeseries$Area == 1L &
  fit$timeseries$Era == "TIME" & fit$timeseries$Yr %in% years, , drop = FALSE]
time_series <- time_series[order(time_series$Yr), , drop = FALSE]
if (!identical(as.integer(time_series$Yr), as.integer(years)) ||
    any(!is.finite(time_series$Bio_all)) || any(!is.finite(time_series$SpawnBio)) ||
    any(!is.finite(time_series$Recruit_0))) {
  stop("The ORS TIME_SERIES does not match the 1970-2018 historical period.",
    call. = FALSE)
}
pages <- pdftools::pdf_text(file.path(cache, "cabezon_2019_assessment.pdf"))
es7_page <- pages[grepl("Table ES7. Recent trend in beginning year biomass and depletion for Cabezon in Oregon waters.",
  pages, fixed = TRUE)]
if (length(es7_page) != 1L) stop("Could not identify Oregon Table ES7 in the cached assessment report.",
  call. = FALSE)
table_lines <- strsplit(es7_page, "\n", fixed = TRUE)[[1L]]
table_values <- lapply(table_lines, function(line) {
  tokens <- regmatches(line, gregexpr("[0-9]+([.][0-9]+)?", line, perl = TRUE))[[1L]]
  if (length(tokens) < 7L) return(NULL)
  values <- as.numeric(tokens)
  if (values[1L] %in% 2007:2019) values[1:4] else NULL
})
table_values <- table_values[!vapply(table_values, is.null, logical(1L))]
table_es7 <- as.data.frame(do.call(rbind, table_values))
names(table_es7) <- c("year", "value", "lwr", "upr")
table_es7$year <- as.integer(table_es7$year)
if (!identical(table_es7$year, 2007:2019) ||
    !identical(as.numeric(unlist(table_es7[table_es7$year == 2019L,
      c("value", "lwr", "upr")], use.names = FALSE)),
      c(177, 128, 226))) {
  stop("Oregon Table ES7 values differ from the reviewed 2007-2019 table.",
    call. = FALSE)
}
ssb_bounds <- match(time_series$Yr, table_es7$year)
ssb_lwr <- ssb_upr <- rep(NA_real_, nrow(time_series))
has_bounds <- !is.na(ssb_bounds)
ssb_lwr[has_bounds] <- table_es7$lwr[ssb_bounds[has_bounds]]
ssb_upr[has_bounds] <- table_es7$upr[ssb_bounds[has_bounds]]
ssb_reference <- ifelse(has_bounds,
  "Report.sso, TIME_SERIES SpawnBio; 2019 assessment report, Table ES7",
  source_ref("Report.sso", "TIME_SERIES SpawnBio"))
ssb_notes <- ifelse(has_bounds,
  "Point estimate is the native Report.sso value; 95% asymptotic confidence limits are from Table ES7, which rounds spawning output to whole metric tons.",
  "Fitted historical spawning output/biomass; the report uses these terms for total female spawning biomass. No annual interval is available in the source table for these years.")
add_output(type = "biomass", measure = "SSB", region = region,
  year = time_series$Yr, value = time_series$SpawnBio, lwr = ssb_lwr, upr = ssb_upr,
  unit = "metric tons", source_reference = ssb_reference, notes = ssb_notes)
forecast_ssb <- table_es7[table_es7$year == 2019L, , drop = FALSE]
add_output(type = "biomass", measure = "SSB", region = region,
  year = forecast_ssb$year, scenario = "assessment forecast", value = forecast_ssb$value,
  lwr = forecast_ssb$lwr, upr = forecast_ssb$upr, unit = "metric tons",
  source_type = "official_table",
  source_reference = "2019 assessment report, Table ES7, p. 19",
  notes = "Assessment-year forecast. Table ES7 reports 128-226 metric tons; the executive-summary narrative rounds the lower limit to 129, so the table values are retained.")
add_output(type = "biomass", measure = "total_biomass", region = region,
  year = time_series$Yr, value = time_series$Bio_all, unit = "metric tons",
  source_reference = source_ref("Report.sso", "TIME_SERIES Bio_all"),
  notes = "Fitted total population biomass on the model's metric-ton scale.")
add_output(type = "recruitment", measure = "recruitment", region = region,
  year = time_series$Yr, age = 0, value = time_series$Recruit_0,
  unit = "thousand fish", source_reference = source_ref("Report.sso", "TIME_SERIES Recruit_0"),
  notes = "Fitted age-0 recruitment.")
total_numbers <- aggregate(value ~ year, n_long, sum)
add_output(type = "population", measure = "total_numbers", region = region,
  year = total_numbers$year, value = total_numbers$value,
  unit = "thousand fish", source_reference = source_ref("Report.sso", "NUMBERS_AT_AGE"),
  notes = "Derived by summing reported numbers at ages 0-20 across both sexes. Uncertainty is unavailable because the joint covariance is not reported.")

add_assumption("assessment", "run_identity",
  "2019 PFMC Oregon substock assessment; Stock Synthesis 3.30.13.00-safe; terminal observed year 2018.",
  "Report.sso, version and run date; 2019 PFMC assessment report")
add_assumption("model", "model_structure",
  "One population area, two sexes, one annual season, ages 0-20 with age 20 as the plus group.",
  source_ref("ORcab_data.ss", "model dimensions"))
add_assumption("catch", "catch_observations",
  "Four annual fishery catch-biomass series from 1970-2018, in metric tons; four non-calendar -999 rows are equilibrium/sentinel values.",
  source_ref("ORcab_data.ss", "catch and fleet blocks"),
  "The native fit does not contain an observed catch-numbers-at-age series.")
index_details <- vapply(sort(unique(cpue$index)), function(fleet_id) {
  z <- cpue[cpue$index == fleet_id, , drop = FALSE]
  paste0(fleet_names[fleet_id], " (", nrow(z), ", ", min(z$year), "-", max(z$year),
    "; units code ", cpue_info$units[match(fleet_id, cpue$index)], ")")
}, character(1L))
add_assumption("index", "aggregate_indices",
  paste(index_details, collapse = "; "),
  source_ref("ORcab_data.ss", "CPUE and CPUEinfo blocks"),
  "Four aggregate lognormal indices; no age-specific abundance index is supplied.")
add_assumption("timing", "observation_month",
  "CPUE, length-composition, and age-composition observations use month 7; represented as sampling_time 0.5.",
  source_ref("ORcab_data.ss", "month fields"),
  "The source month is retained in season; the fraction is (month - 1)/12.")
add_assumption("composition", "age_and_length_samples",
  "129 length-composition rows (length bins 4-92 cm by 2 cm) and 597 age-composition rows (ages 0-20; 525 conditional age-at-length and 72 marginal rows).",
  source_ref("ORcab_data.ss", "lencomp and agecomp blocks"),
  "Native frequencies, Nsamp, sex grouping, age-error code, partition, conditional length bounds, and signed source fleet codes are retained. Negative-fleet marginal ages are evaluation-only, not additional likelihood observations.")
add_assumption("biology", "growth_weight_maturity",
  "Sex-specific growth is estimated. Oregon length-weight relationships are estimated outside the model from ORBS biological records and PacFIN and then held fixed; the Oregon maturity ogive is externally estimated and fixed.",
  "2019 PFMC assessment report, Oregon biology section; ORcab_control.ss",
  "The fitted Report.sso contains model-derived weight-at-age, but the native input does not provide an independent empirical weight-at-age or maturity-at-age vector.")
add_assumption("mortality", "natural_mortality",
  paste0("Natural mortality is fixed by sex at female ",
    format(unique(m_input$value[m_input$sex == "female"])[1L], digits = 7),
    " and male ", format(unique(m_input$value[m_input$sex == "male"])[1L], digits = 7),
    " year^-1; values are constant across ages 0-19."),
  source_ref("ORcab_control.ss and Report.sso", "fixed M parameters and M_at_age"))
add_assumption("recruitment", "stock_recruitment",
  "Beverton-Holt stock-recruit relationship; steepness is fixed at 0.7 and recruitment variability CV at 0.5.",
  "2019 PFMC assessment report, Oregon model section; ORcab_control.ss")
add_assumption("output", "uncertainty",
  "Table ES7 reports 95% asymptotic confidence intervals for spawning output in 2007-2019; age-specific N, F, M, catch, biomass, and weight uncertainty is not tabulated.",
  "2019 PFMC assessment report, Table ES7 and Report.sso",
  "The table's 2019 lower limit is 128 metric tons; the executive-summary narrative states 129 after rounding.")
add_assumption("management", "current_management_status",
  "The 2019 Oregon assessment remains the model cited for 2027-2028 Oregon cabezon harvest specifications. The Council voted in 2025 to remove Oregon and California cabezon from the federal Groundfish FMP.",
  "2019 PFMC assessment report; 2025 September Council Meeting Record; 2026 draft 2027-2028 harvest specifications",
  "This record captures the latest detailed Oregon assessment and its documented use; it does not imply that Oregon cabezon remains in the federal FMP.")

inputs_new <- do.call(rbind, input_rows)
outputs_new <- do.call(rbind, output_rows)
assumptions_new <- do.call(rbind, assumption_rows)
if (any(!is.finite(inputs_new$value)) || any(!is.finite(outputs_new$value)) ||
    any(inputs_new$source_type != "native_model") ||
    any(!nzchar(inputs_new$source_reference)) || any(!nzchar(outputs_new$source_reference))) {
  stop("The cabezon import contains non-finite values or missing provenance.", call. = FALSE)
}
key_for <- function(x, fields) {
  values <- lapply(x[fields], function(z) {
    z[is.na(z)] <- ""
    as.character(z)
  })
  do.call(paste, c(values, sep = "\r"))
}
input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey",
  "sex", "region", "season", "year", "year_basis", "age", "observation_id",
  "length_bin", "length_bin_lower", "length_bin_upper", "sample_size",
  "age_error", "partition", "weight_bin")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
  "region", "season", "year", "age", "age_group", "scenario")
if (anyDuplicated(key_for(inputs_new, input_key)) ||
    anyDuplicated(key_for(outputs_new, output_key))) {
  stop("The cabezon import contains duplicate canonical rows.", call. = FALSE)
}

stocks_path <- file.path(root, "database/stocks.csv")
assessments_path <- file.path(root, "database/assessments.csv")
stocks_table <- read.csv(stocks_path, colClasses = "character", check.names = FALSE)
assessments_table <- read.csv(assessments_path, colClasses = "character", check.names = FALSE)
stock_exists <- stock_id %in% stocks_table$stock_id
assessment_exists <- assessment_id %in% assessments_table$assessment_id
existing_identity_matches <- stock_exists && assessment_exists &&
  sum(stocks_table$stock_id == stock_id) == 1L &&
  sum(assessments_table$assessment_id == assessment_id) == 1L &&
  assessments_table$stock_id[assessments_table$assessment_id == assessment_id] == stock_id &&
  sum(assessments_table$stock_id == stock_id) == 1L
if (xor(stock_exists, assessment_exists) ||
    ((stock_exists || assessment_exists) &&
      (!test_mode || !existing_identity_matches)) ||
    any(stocks_table$scientific_name == "Scorpaenichthys marmoratus" &
      stocks_table$stock_id != stock_id, na.rm = TRUE)) {
  stop("A cabezon stock or assessment record exists; reconcile it before importing.",
    call. = FALSE)
}
blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks_table), list(
  stock_id = stock_id, authority = "NOAA Fisheries", authority_stock_id = "12193",
  scientific_name = "Scorpaenichthys marmoratus", common_name = "Oregon cabezon",
  area = "Oregon", region = "Oregon Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART unit 12193; the ORS component of the 2019 PFMC assessment. Oregon is one component of the coastwide species assessment family, not a separate species. The Council voted in 2025 to remove Oregon cabezon from the federal Groundfish FMP; the 2019 model is nevertheless cited for 2027-2028 harvest specifications."))
assessment <- blank_row(names(assessments_table), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2019L,
  terminal_year = 2018L, estimate_terminal_year = 2018L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.13.00-safe (Report.sso)", is_current = TRUE,
  is_applied = TRUE, assessment_url = report_url, data_url = model_url,
  model_url = model_url,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed Oregon cabezon assessment located, with observed data through 2018. Native inputs provide catches, aggregate indices, and length/age compositions; fitted surfaces provide age-specific N, biomass, F, M, catch, and weight. Observed catch-at-age, age-specific abundance indices, empirical weight/maturity-at-age vectors, and age-specific uncertainty are not supplied. The assessment-year 2019 SSB point and interval are separately marked as a forecast."))

candidate_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
unworked_path <- file.path(root, "discovery/selected_unworked_2026.csv")
candidates <- read.csv(candidate_path, colClasses = "character", check.names = FALSE)
inventory <- read.csv(inventory_path, colClasses = "character", check.names = FALSE)
ci <- which(candidates$candidate_id == candidate_id)
ii <- which(inventory$candidate_unit_id == candidate_unit_id)
if (length(ci) != 1L || length(ii) != 1L || candidates$eligibility[ci] != "eligible" ||
    !candidates$import_status[ci] %in% c("not_started", "partial") ||
    !inventory$import_status[ii] %in% c("not_started", "partial") ||
    (nzchar(candidates$matched_stock_id[ci]) && candidates$matched_stock_id[ci] != stock_id)) {
  stop("The NOAA:12193 candidate registers no longer match the screened Oregon assessment.",
    call. = FALSE)
}
candidate_update <- candidates[ci, , drop = FALSE]
candidate_update$matched_stock_id <- stock_id
candidate_update$match_status <- "new"
candidate_update$import_status <- "partial"
candidate_update$catch_age_evidence <- "Imported native catch biomass, length compositions, and fishery age-at-length frequencies; no observed catch-numbers-at-age series is supplied. Fitted catch-at-age is stored only as an output."
candidate_update$survey_age_evidence <- "Four aggregate lognormal CPUE indices are imported; age compositions are not an age-specific abundance index."
candidate_update$weights_evidence <- "The model uses an Oregon length-weight relationship estimated outside the fit; Report.sso weight-at-age is model-derived and stored as output. No empirical weight-at-age input vector is supplied."
candidate_update$maturity_evidence <- "The Oregon maturity ogive is externally estimated and fixed; no standalone maturity-at-age input vector is supplied."
candidate_update$mortality_evidence <- paste0("Natural mortality is fixed by sex at female ",
  format(unique(m_input$value[m_input$sex == "female"])[1L], digits = 7),
  " and male ", format(unique(m_input$value[m_input$sex == "male"])[1L], digits = 7),
  " year^-1; the time-invariant age surfaces are imported.")
candidate_update$timing_evidence <- "CPUE and composition inputs retain native month 7; sampling_time is represented as 0.5."
candidate_update$output_evidence <- "Imported fitted N, biomass, fleet F, M, catch, and weight surfaces for 1970-2018; annual SSB, total biomass, recruitment, derived total abundance, and SSB 95% intervals for 2007-2019. No age-specific uncertainty is published."
candidate_update$detailed_source_url <- paste(report_url, supplement_url, star_url, model_url,
  "https://www.pcouncil.org/documents/cabezon-scs-model-files-zip-file/",
  "https://www.pcouncil.org/documents/cabezon-ncs-model-files-zip-file/", sep = "; ")
candidate_update$review_date <- "2026-11-12"
candidate_update$decision_reason <- "The latest detailed Oregon model archive and its original inputs/outputs were recovered and imported. The source record is partial because the native observations do not include catch-at-age or an age-specific index, and age-specific uncertainty is unavailable."
candidate_update$notes <- "The Council voted in 2025 to remove Oregon cabezon from the federal Groundfish FMP; the 2019 model remains cited for 2027-2028 Oregon harvest specifications. The source record preserves the model run and current management context without treating the Oregon assessment component as a separate species."
inventory_update <- inventory[ii, , drop = FALSE]
inventory_update$matched_stock_id <- stock_id
inventory_update$match_status <- "new"
inventory_update$import_status <- "partial"
unworked_updates <- NULL
if (file.exists(unworked_path)) {
  unworked <- read.csv(unworked_path, colClasses = "character", check.names = FALSE)
  ui <- which(unworked$candidate_id == candidate_id)
  if (length(ui) == 1L) {
    unworked_updates <- unworked[ui, , drop = FALSE]
    if ("curation_status" %in% names(unworked_updates))
      unworked_updates$curation_status <- "source_curated_partial"
    if ("import_status" %in% names(unworked_updates))
      unworked_updates$import_status <- "partial"
  }
}

cat("Prepared ", nrow(inputs_new), " inputs, ", nrow(assumptions_new),
  " assumptions, and ", nrow(outputs_new), " outputs for Oregon cabezon.\n", sep = "")
cat("Observed catch-at-age and age-specific survey indices are not added; fitted catch-at-age remains an output.\n")
if (write_mode) {
  append_pacific_case(stock, assessment, assumptions_new, inputs_new, outputs_new)
  replace_candidate_register_row(candidate_path, ci, candidate_update, candidate_id)
  replace_csv_register_row(inventory_path, ii, inventory_update, "unit_key", inventory$unit_key[ii])
  if (!is.null(unworked_updates)) replace_csv_register_row(unworked_path, ui,
    unworked_updates, "candidate_id", candidate_id)
  source(file.path(root, "scripts/database/002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("Oregon cabezon records appended and full database validation passed.\n")
}
