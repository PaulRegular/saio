root <- "."
source_cache <- file.path(root, "../../discovery_noaa_rougheye_2025")
model_dir <- file.path(source_cache, "model_files")
assessment_id <- "noaa_uswc_rougheye_blackspotted_2025"
stock_id <- "noaa_uswc_rougheye_blackspotted"
candidate_unit_id <- "noaa_uswc_rougheye_blackspotted"
candidate_id <- "NOAA:14516"
report_url <- "https://www.pcouncil.org/documents/2026/01/status-of-rougheye-and-blackspotted-rockfishes-stock-off-the-u-s-west-coast-in-2025.pdf/"
model_url <- "https://www.pcouncil.org/documents/rougheye-blackspotted-2025-model-files-zip-file/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest_path <- file.path(root, "provenance/noaa_rougheye_blackspotted_2025_sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
files <- c(
  "discovery_noaa_rougheye_2025/assessment_2025.pdf" = file.path(source_cache, "assessment_2025.pdf"),
  "discovery_noaa_rougheye_2025/model_files_2025.zip" = file.path(source_cache, "model_files_2025.zip"),
  "discovery_noaa_rougheye_2025/model_files/2025_rougheye_data.ss" = file.path(model_dir, "2025_rougheye_data.ss"),
  "discovery_noaa_rougheye_2025/model_files/2025_rougheye_control.ss" = file.path(model_dir, "2025_rougheye_control.ss"),
  "discovery_noaa_rougheye_2025/model_files/starter.ss" = file.path(model_dir, "starter.ss"),
  "discovery_noaa_rougheye_2025/model_files/forecast.ss" = file.path(model_dir, "forecast.ss"),
  "discovery_noaa_rougheye_2025/model_files/Report.sso" = file.path(model_dir, "Report.sso")
)
sha256_file <- function(path) unname(tools::sha256sum(path))
if (!all(c("local_file", "source_url", "retrieved_on", "sha256", "bytes") %in% names(manifest)) ||
    !setequal(manifest$local_file, names(files)) || anyDuplicated(manifest$local_file)) {
  stop("The rougheye/blackspotted source manifest is incomplete.", call. = FALSE)
}
verify_source <- function(local_file) {
  row <- manifest[manifest$local_file == local_file, , drop = FALSE]
  path <- files[[local_file]]
  if (nrow(row) != 1L || !file.exists(path) ||
      as.numeric(row$bytes) != file.info(path)$size ||
      !identical(toupper(row$sha256), toupper(sha256_file(path)))) {
    stop("Cached rougheye source differs from its pinned manifest: ", local_file,
      call. = FALSE)
  }
  path
}
invisible(lapply(names(files), verify_source))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to read the cached rougheye assessment sources.", call. = FALSE)
}
dat <- r4ss::SS_readdat(file.path(model_dir, "2025_rougheye_data.ss"),
  version = "3.30.23", verbose = FALSE)
fit <- r4ss::SS_output(dir = model_dir, covar = FALSE, forecast = FALSE,
  warn = FALSE, readwt = FALSE, verbose = FALSE)
years <- 1892:2024
length_bins <- as.integer(dat$lbin_vector)
age_bins <- as.integer(dat$agebin_vector)
conditional_age <- dat$agecomp$Lbin_lo >= 0 & dat$agecomp$Lbin_hi >= 0
marginal_age <- dat$agecomp$Lbin_lo == -1 & dat$agecomp$Lbin_hi == -1
if (dat$styr != 1892L || dat$endyr != 2024L || dat$Nsexes != 2L ||
    dat$Nages != 140L || dat$nseas != 1L || dat$Lbin_method != 3L ||
    !identical(length_bins, seq.int(10L, 80L, by = 2L)) ||
    !identical(age_bins, 1:100) || nrow(dat$fleetinfo) != 10L ||
    nrow(dat$catch) != 359L || sum(dat$catch$year == -999L) != 6L ||
    sum(dat$catch$year %in% years) != 353L ||
    !identical(sort(unique(as.integer(dat$catch$fleet))), 1:6) ||
    nrow(dat$CPUE) != 38L || !identical(sort(unique(as.integer(dat$CPUE$index))), 7:10) ||
    any(dat$CPUE$month != 7L) || nrow(dat$lencomp) != 167L ||
    nrow(dat$agecomp) != 1988L || sum(conditional_age) != 1929L ||
    sum(marginal_age) != 59L || sum(dat$agecomp$fleet < 0L) != 59L ||
    any(!(conditional_age | marginal_age)) ||
    any(dat$CPUE$obs <= 0 | dat$CPUE$se_log <= 0) ||
    !all(dat$CPUEinfo$units == 1L & dat$CPUEinfo$errtype == 0L) ||
    any(dat$catch$catch_se != 0.01)) {
  stop("The cached native data do not match the reviewed 2025 assessment structure.", call. = FALSE)
}

fleets <- as.character(dat$fleetinfo$fleetname)
region <- "U.S. West Coast"
source_reference <- function(file, section) paste0(file, ", ", section)
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
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, region = region,
    setting = setting, value = value, source_reference = source, notes = notes)
}

catch <- dat$catch[dat$catch$year %in% years, , drop = FALSE]
catch_fleet <- fleets[as.integer(catch$fleet)]
add_input(type = "catch", measure = "catch_biomass", basis = "biomass",
  fleet = catch_fleet, region = region, year = catch$year, year_basis = "calendar_year",
  season = "annual", value = catch$catch, unit = "metric tons",
  source_reference = source_reference("2025_rougheye_data.ss", "catch block"),
  notes = "Native annual fishery catch biomass. The six -999 equilibrium/sentinel records are not calendar-year observations and are excluded.")
add_input(type = "catch", measure = "catch_se", basis = "log_scale",
  fleet = catch_fleet, region = region, year = catch$year, year_basis = "calendar_year",
  season = "annual", value = catch$catch_se, unit = "log-scale standard error",
  source_reference = source_reference("2025_rougheye_data.ss", "catch uncertainty field"),
  notes = "Native catch observation error field retained separately from catch biomass.")

cpue <- dat$CPUE[order(dat$CPUE$index, dat$CPUE$year), , drop = FALSE]
index_survey <- fleets[as.integer(cpue$index)]
index_time <- (as.integer(cpue$month) - 1) / 12
add_input(type = "index", measure = "relative_biomass_index", basis = "index_scale",
  survey = index_survey, region = region, year = cpue$year, year_basis = "calendar_year",
  season = paste0("month ", cpue$month), sampling_time = index_time, value = cpue$obs,
  unit = "native relative biomass-index units (Stock Synthesis units code 1)",
  source_reference = source_reference("2025_rougheye_data.ss", "CPUE observations"),
  notes = "Four aggregate survey biomass indices; Stock Synthesis error type 0 is lognormal. These are not age-specific abundance indices.")
add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
  survey = index_survey, region = region, year = cpue$year, year_basis = "calendar_year",
  season = paste0("month ", cpue$month), sampling_time = index_time, value = cpue$se_log,
  unit = "standard error on log index",
  source_reference = source_reference("2025_rougheye_data.ss", "CPUE se_log field"),
  notes = "Native lognormal observation standard error for each aggregate survey index.")

add_compositions <- function(x, kind, bins) {
  is_age <- kind == "age"
  for (i in seq_len(nrow(x))) {
    row <- x[i, , drop = FALSE]
    code <- as.integer(row$sex)
    female <- as.numeric(row[1L, paste0("f", bins), drop = TRUE])
    male <- as.numeric(row[1L, paste0("m", bins), drop = TRUE])
    if (code == 3L) {
      parts <- list(female = female, male = male)
    } else if (code == 1L) {
      parts <- list(female = female)
    } else if (code == 2L) {
      parts <- list(male = male)
    } else if (code == 0L && !is_age && all(male == 0)) {
      parts <- list(combined = female)
    } else {
      stop("Unexpected sex code or frequency vector in rougheye composition row ", i, ".", call. = FALSE)
    }
    fleet_id <- abs(as.integer(row$fleet))
    is_fishery <- dat$fleetinfo$type[fleet_id] == 1L
    is_conditional <- is_age && conditional_age[i]
    measure <- if (is_conditional) "conditional_frequency_at_age" else
      if (is_age) "frequency_at_age" else "frequency_at_length"
    type <- if (is_conditional) "biology" else if (is_fishery) "catch" else "index"
    note <- if (is_conditional) {
      "Conditional age-at-length frequency; length bounds are native Lbin_lo/Lbin_hi values in centimetres."
    } else if (is_age) {
      "Marginal age-composition frequency supplied for model fit evaluation, not a separate likelihood input."
    } else {
      "Native length-composition frequency; length_bin is the Stock Synthesis source label in centimetres."
    }
    note <- paste(note,
      "Frequency values are preserved without normalization; sample_size retains native Nsamp.",
      if (code == 3L) "The native sex code supplies separate female and male vectors." else "The native source sex grouping is retained.",
      if (as.integer(row$fleet) < 0L) "The negative source fleet code marks an evaluation-only observation; the linked fleet is its absolute fleet ID." else "")
    for (sex_name in names(parts)) {
      add_input(type = type, measure = measure, basis = "native_frequency",
        fleet = if (is_fishery) fleets[fleet_id] else "",
        survey = if (!is_fishery) fleets[fleet_id] else "",
        sex = sex_name, region = region, year = abs(as.integer(row$year)),
        year_basis = "calendar_year", season = paste0("month ", row$month),
        sampling_time = (as.integer(row$month) - 1) / 12,
        age = if (is_age) bins else NA_real_,
        length_bin = if (is_age) NA_real_ else bins,
        length_bin_lower = if (is_conditional) as.numeric(row$Lbin_lo) else NA_real_,
        length_bin_upper = if (is_conditional) as.numeric(row$Lbin_hi) else NA_real_,
        value = parts[[sex_name]], unit = "source frequency",
        sample_size = as.numeric(row$Nsamp),
        age_error = if (is_age) as.integer(row$ageerr) else NA_integer_,
        partition = as.character(row$part),
        source_reference = source_reference("2025_rougheye_data.ss",
          if (is_conditional) "conditional age-at-length block" else if (is_age) "marginal age-composition block" else "length-composition block"),
        notes = paste(note, if (is_age) paste0("Native age-error code ", row$ageerr, " retained.") else ""),
        observation_id = paste(kind, i, sex_name, sep = ":"))
    }
  }
}
add_compositions(dat$lencomp, "length", length_bins)
add_compositions(dat$agecomp, "age", age_bins)

add_assumption("assessment", "model_structure",
  "One area, two sexes, one annual season; population ages 0 through 140, with age 140 as the accumulator group.",
  "2025_rougheye_data.ss and 2025_rougheye_control.ss",
  "The assessment pools rougheye and blackspotted rockfish into one U.S. West Coast management complex.")
add_assumption("model", "model_version",
  "Report.sso and the report executive summary identify Stock Synthesis 3.30.23.2; report section 3.4.1 states 3.30.23.1.",
  "Report.sso; 2025 assessment report, executive summary and section 3.4.1",
  "The report has an internal version discrepancy; the native Report.sso version is retained as the run-specific value.")
add_assumption("catch", "catch_inputs",
  "Six fishery fleets; annual catch biomass in metric tons; native catch observation error is 0.01.",
  source_reference("2025_rougheye_data.ss", "fleet and catch blocks"),
  "Catch-at-age is not a direct observed input in the archived model files.")
add_assumption("index", "survey_indices",
  "Four aggregate biomass-index series: TRIENNIAL (9 observations, 1980-2004), AK_SLOPE (4, 1997-2001), NW_SLOPE (4, 1999-2002), and WCGBTS (21, 2003-2024); Stock Synthesis units code 1 and lognormal error type 0.",
  source_reference("2025_rougheye_data.ss", "CPUE and CPUEinfo blocks"),
  "The archived inputs do not contain age-specific abundance indices; survey composition samples are stored separately.")
add_assumption("timing", "survey_observation_month",
  "All survey index and composition observations use month 7; represented as sampling_time 0.5.",
  source_reference("2025_rougheye_data.ss", "month fields"),
  "The conversion is (month - 1) / 12; it preserves the native July observation timing.")
add_assumption("composition", "age_length_samples",
  "1,929 conditional age-at-length rows and 59 marginal age rows from 2003-2024; 167 length-composition rows from 1980-2024.",
  source_reference("2025_rougheye_data.ss", "agecomp and lencomp blocks"),
  "Marginal age rows have negative source fleet codes and are supplied for fit evaluation; conditional age-at-length observations are the age-composition likelihood data. Native Nsamp values are retained.")
add_assumption("composition", "age_error_codes",
  "Seven native age-error definitions (codes 1-7).",
  source_reference("2025_rougheye_control.ss", "age-error definitions"),
  "Each age-composition row retains the native age-error code; definition matrices remain available in the cached control file.")
add_assumption("biology", "growth_weight_maturity",
  "Sex-specific growth and length-weight relationships; maturity follows a length-based logistic relationship.",
  "2025_rougheye_control.ss; 2025 assessment report, biology section",
  "Age-specific weight and maturity are generated by the model; separate empirical weight-at-age and maturity-at-age input matrices were not supplied.")
add_assumption("mortality", "natural_mortality",
  "Female M is estimated at 0.0391039 per year; male M is fixed at 0.036 per year.",
  "Report.sso M_at_age; 2025 assessment report, natural mortality section",
  "The native M surface is constant across ages and years within sex; age 140 has no M value in the output surface.")
add_assumption("recruitment", "stock_recruitment",
  "Beverton-Holt stock-recruit relationship with steepness fixed at 0.72.",
  "2025 assessment report, recruitment section; 2025_rougheye_control.ss",
  "Main recruitment deviations are estimated through 2023; the recruitment period from 2024 is treated as forecast in the report.")

long_age <- function(x, ages) {
  values <- as.matrix(x[, as.character(ages), drop = FALSE])
  data.frame(row = rep(seq_len(nrow(x)), each = length(ages)),
    age = rep(ages, times = nrow(x)), value = as.vector(t(values)))
}
population_rows <- function(x) x$Area == 1L & x$Bio_Pattern == 1L &
  x$Sex %in% 1:2 & x$Morph == x$Sex & x$Seas == 1L &
  x$Era == "TIME" & x$Yr %in% years
n <- fit$natage[population_rows(fit$natage) & fit$natage$BirthSeas == 1L &
  fit$natage$Settlement == 1L & fit$natage$Platoon == 1L &
  fit$natage[["Beg/Mid"]] == "B", , drop = FALSE]
b <- fit$batage[population_rows(fit$batage) & fit$batage$BirthSeas == 1L &
  fit$batage$Settlement == 1L & fit$batage$Platoon == 1L &
  fit$batage[["Beg/Mid"]] == "B", , drop = FALSE]
f <- fit$fatage[fit$fatage$Area == 1L & fit$fatage$Fleet %in% 1:6 &
  fit$fatage$Sex %in% 1:2 & fit$fatage$Morph == fit$fatage$Sex &
  fit$fatage$Seas == 1L & fit$fatage$Era == "TIME" & fit$fatage$Yr %in% years, , drop = FALSE]
c_age <- fit$catage[fit$catage$Area == 1L & fit$catage$Fleet %in% 1:6 &
  fit$catage$Sex %in% 1:2 & fit$catage$Type == "dead" &
  fit$catage$Morph == fit$catage$Sex & fit$catage$Seas == 1L &
  fit$catage$Era == "TIME" & fit$catage$Yr %in% years, , drop = FALSE]
m <- fit$M_at_age[fit$M_at_age$Bio_Pattern == 1L & fit$M_at_age$Sex %in% 1:2 &
  fit$M_at_age$Yr %in% years, , drop = FALSE]
time_series <- fit$timeseries[fit$timeseries$Area == 1L & fit$timeseries$Era == "TIME" &
  fit$timeseries$Yr %in% years, , drop = FALSE]
if (nrow(n) != length(years) * 2L || nrow(b) != length(years) * 2L ||
    nrow(f) != length(years) * 12L || nrow(c_age) != length(years) * 12L ||
    nrow(m) != length(years) * 2L || nrow(time_series) != length(years) ||
    !identical(sort(unique(as.integer(n$Yr))), years) ||
    any(!is.finite(as.matrix(n[, as.character(0:140), drop = FALSE]))) ||
    any(!is.finite(as.matrix(b[, as.character(0:140), drop = FALSE]))) ||
    any(!is.finite(as.matrix(f[, as.character(0:140), drop = FALSE]))) ||
    any(!is.finite(as.matrix(c_age[, as.character(0:140), drop = FALSE]))) ||
    any(!is.finite(as.matrix(m[, as.character(0:139), drop = FALSE]))) ||
    any(is.finite(m[["140"]])) ||
    any(!is.finite(time_series$Recruit_0) | !is.finite(time_series$SpawnBio) | !is.finite(time_series$Bio_all))) {
  stop("The native report does not contain the expected fitted age surfaces.", call. = FALSE)
}

ages <- 0:140
n_long <- long_age(n, ages)
b_long <- long_age(b, ages)
f_long <- long_age(f, ages)
c_long <- long_age(c_age, ages)
add_output(type = "population", measure = "numbers_at_age", region = region,
  year = n$Yr[n_long$row], age = n_long$age,
  age_group = ifelse(n_long$age == 140, "140+", ""),
  sex = ifelse(n$Sex[n_long$row] == 1L, "female", "male"), value = n_long$value,
  unit = "thousand fish", source_reference = "Report.sso, beginning-of-year natage",
  notes = "Native fitted beginning-of-year abundance at age; age 140 is the accumulator group. Age-specific uncertainty is not supplied.")
add_output(type = "biomass", measure = "biomass_at_age", region = region,
  year = b$Yr[b_long$row], age = b_long$age,
  age_group = ifelse(b_long$age == 140, "140+", ""),
  sex = ifelse(b$Sex[b_long$row] == 1L, "female", "male"), value = b_long$value,
  unit = "metric tons", source_reference = "Report.sso, beginning-of-year batage",
  notes = "Native fitted beginning-of-year biomass at age; age 140 is the accumulator group. Age-specific uncertainty is not supplied.")
add_output(type = "catch", measure = "catch_numbers_at_age", region = region,
  year = c_age$Yr[c_long$row], age = c_long$age,
  age_group = ifelse(c_long$age == 140, "140+", ""),
  fleet = fleets[c_age$Fleet[c_long$row]],
  sex = ifelse(c_age$Sex[c_long$row] == 1L, "female", "male"), value = c_long$value,
  unit = "thousand fish", source_reference = "Report.sso, dead catch catage",
  notes = "Native fitted dead catch-at-age output by fishery fleet and sex; not an observed catch-at-age input.")
add_output(type = "mortality", measure = "fishing_mortality_at_age", region = region,
  year = f$Yr[f_long$row], age = f_long$age,
  age_group = ifelse(f_long$age == 140, "140+", ""),
  fleet = fleets[f$Fleet[f_long$row]],
  sex = ifelse(f$Sex[f_long$row] == 1L, "female", "male"), value = f_long$value,
  unit = "per year", source_reference = "Report.sso, fatage",
  notes = "Native fitted fishing-mortality surface by fishery fleet and sex; age 140 is the accumulator group. Age-specific uncertainty is not supplied.")

m_long <- long_age(m, 0:139)
add_output(type = "mortality", measure = "natural_mortality_at_age", region = region,
  year = m$Yr[m_long$row], age = m_long$age,
  sex = ifelse(m$Sex[m_long$row] == 1L, "female", "male"), value = m_long$value,
  unit = "per year", source_reference = "Report.sso, M_at_age",
  notes = "Native fitted or fixed M-at-age surface; female M is estimated and male M is fixed. Age 140 is not available in the source output.")

numbers_total <- aggregate(n_long$value, list(year = n$Yr[n_long$row]), sum)
add_output(type = "population", measure = "total_numbers", region = region,
  year = numbers_total$year, value = numbers_total$x, unit = "thousand fish",
  source_type = "derived_source_output",
  source_reference = "Report.sso natage; sum of ages 0-140 and both sexes",
  notes = "Derived by summing beginning-of-year numbers at age across sexes and age 140+; no uncertainty is available.")
add_output(type = "biomass", measure = "total_biomass", region = region,
  year = time_series$Yr, value = time_series$Bio_all, unit = "metric tons",
  source_reference = "Report.sso, TIME_SERIES Bio_all",
  notes = "Native total biomass of all ages and sexes; it is not spawning output or SSB.")

report_text <- paste(pdftools::pdf_text(verify_source("discovery_noaa_rougheye_2025/assessment_2025.pdf")), collapse = "\n")
report_lines <- gsub("\u00ad", "", trimws(unlist(strsplit(report_text, "\n"))), fixed = TRUE)
read_report_table <- function(table_number, columns, next_table = NULL) {
  marker <- grep(paste0("^Table ", table_number, ":"), report_lines, ignore.case = TRUE)[1L]
  if (is.na(marker)) stop("Missing Table ", table_number, " in the report.", call. = FALSE)
  later <- if (is.null(next_table)) integer() else
    grep(paste0("^Table ", next_table, ":"), report_lines, ignore.case = TRUE)
  end <- if (length(later)) min(later[later > marker]) - 1L else length(report_lines)
  parse_value <- function(x) {
    if (grepl("^<", x)) return(NA_real_)
    suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
  }
  parsed <- list()
  for (line in report_lines[marker:end]) {
    fields <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (length(fields) != length(columns) || !grepl("^20[0-9]{2}$", fields[1L])) next
    values <- vapply(fields[-1L], parse_value, numeric(1L))
    censored <- grepl("^<", fields[-1L])
    if (anyNA(values[!censored])) next
    parsed[[length(parsed) + 1L]] <- c(as.numeric(fields[1L]), values)
  }
  if (!length(parsed)) stop("Could not read numeric rows from Table ", table_number, ".", call. = FALSE)
  result <- as.data.frame(do.call(rbind, parsed))
  names(result) <- columns
  result$year <- as.integer(result$year)
  result[!duplicated(result$year), , drop = FALSE]
}
table_ii <- read_report_table("ii", c("year", "spawning_output", "spawning_lower",
  "spawning_upper", "unfished_fraction", "fraction_lower", "fraction_upper"), "iii")
table_iii <- read_report_table("iii", c("year", "recruitment", "recruitment_lower",
  "recruitment_upper", "recruitment_deviation", "deviation_lower", "deviation_upper"), "iv")
table_iv <- read_report_table("iv", c("year", "fishing_intensity", "intensity_lower",
  "intensity_upper", "exploitation_rate", "exploitation_lower", "exploitation_upper"))
if (!identical(table_ii$year, 2015:2025) ||
    !identical(table_iii$year, 2015:2024) ||
    !identical(table_iv$year, 2015:2024)) {
  stop("Recent report table coverage differs from the reviewed 2025 assessment.", call. = FALSE)
}
recent_spawn <- match(table_ii$year[table_ii$year <= 2024], time_series$Yr)
if (anyNA(recent_spawn) || max(abs(table_ii$spawning_output[table_ii$year <= 2024] -
    time_series$SpawnBio[recent_spawn])) > 0.0006) {
  stop("Table ii spawning output does not match Report.sso to its printed precision.", call. = FALSE)
}
recent_rec <- match(table_iii$year, time_series$Yr)
if (anyNA(recent_rec) || max(abs(table_iii$recruitment - time_series$Recruit_0[recent_rec])) > 0.6) {
  stop("Table iii recruitment does not match Report.sso to its printed precision.", call. = FALSE)
}

spawn_series <- data.frame(year = time_series$Yr, value = time_series$SpawnBio,
  lwr = NA_real_, upr = NA_real_, source_type = "native_model",
  source_reference = "Report.sso, TIME_SERIES SpawnBio", scenario = "")
spawn_recent <- match(table_ii$year[table_ii$year <= 2024], spawn_series$year)
spawn_series$value[spawn_recent] <- table_ii$spawning_output[table_ii$year <= 2024]
spawn_series$lwr[spawn_recent] <- table_ii$spawning_lower[table_ii$year <= 2024]
spawn_series$upr[spawn_recent] <- table_ii$spawning_upper[table_ii$year <= 2024]
spawn_series$source_type[spawn_recent] <- "official_table"
spawn_series$source_reference[spawn_recent] <- "2025 assessment report, Table ii"
spawn_series <- rbind(spawn_series, data.frame(year = 2025L,
  value = table_ii$spawning_output[table_ii$year == 2025],
  lwr = table_ii$spawning_lower[table_ii$year == 2025],
  upr = table_ii$spawning_upper[table_ii$year == 2025],
  source_type = "official_table", source_reference = "2025 assessment report, Table ii",
  scenario = "forecast"))
add_output(type = "biomass", measure = "spawning_output", region = region,
  year = spawn_series$year, scenario = spawn_series$scenario,
  value = spawn_series$value, lwr = spawn_series$lwr, upr = spawn_series$upr,
  unit = "trillions of eggs", source_type = spawn_series$source_type,
  source_reference = spawn_series$source_reference,
  notes = "Fitted spawning output, not SSB in biomass. Table ii labels its interval columns as mt although its point estimates and Figure ii are in trillions of eggs; the intervals appear to be on the plotted scale and are retained as that interpretation, with the unit conflict unresolved. Values printed <0.001 are stored blank.")
add_output(type = "biomass", measure = "spawning_output_ratio_to_unfished", region = region,
  year = table_ii$year, scenario = ifelse(table_ii$year == 2025, "forecast", ""),
  value = table_ii$unfished_fraction, lwr = table_ii$fraction_lower,
  upr = table_ii$fraction_upper, unit = "proportion",
  source_type = "official_table", source_reference = "2025 assessment report, Table ii",
  notes = "Spawning output relative to unfished output; this is not an SSB ratio. The 2025 row is a forecast.")

recruitment <- data.frame(year = time_series$Yr, value = time_series$Recruit_0,
  lwr = NA_real_, upr = NA_real_, source_type = "native_model",
  source_reference = "Report.sso, TIME_SERIES Recruit_0")
rec_rows <- match(table_iii$year, recruitment$year)
recruitment$value[rec_rows] <- table_iii$recruitment
recruitment$lwr[rec_rows] <- table_iii$recruitment_lower
recruitment$upr[rec_rows] <- table_iii$recruitment_upper
recruitment$source_type[rec_rows] <- "official_table"
recruitment$source_reference[rec_rows] <- "2025 assessment report, Table iii"
add_output(type = "recruitment", measure = "recruitment", region = region,
  year = recruitment$year, age = 0, value = recruitment$value,
  lwr = recruitment$lwr, upr = recruitment$upr, unit = "thousand fish",
  source_type = recruitment$source_type, source_reference = recruitment$source_reference,
  notes = "Age-0 recruitment from Report.sso; 2015-2024 point estimates and 95% intervals are from Table iii. No annual uncertainty is available for earlier years.")
add_output(type = "parameter", measure = "recruitment_deviation", region = region,
  year = table_iii$year, age = 0, value = table_iii$recruitment_deviation,
  lwr = table_iii$deviation_lower, upr = table_iii$deviation_upper,
  unit = "log-scale deviation", source_type = "official_table",
  source_reference = "2025 assessment report, Table iii",
  notes = "Annual recruitment deviations and 95% intervals as reported in Table iii.")
add_output(type = "mortality", measure = "fishing_intensity_1_minus_spr", region = region,
  year = table_iv$year, value = table_iv$fishing_intensity,
  lwr = table_iv$intensity_lower, upr = table_iv$intensity_upper,
  unit = "proportion", source_type = "official_table",
  source_reference = "2025 assessment report, Table iv",
  notes = "Fishing intensity is 1-SPR; it is not instantaneous F. Lower intervals printed <0.001 are stored blank.")
add_output(type = "mortality", measure = "exploitation_rate", region = region,
  year = table_iv$year, value = table_iv$exploitation_rate,
  lwr = table_iv$exploitation_lower, upr = table_iv$exploitation_upper,
  unit = "proportion", source_type = "official_table",
  source_reference = "2025 assessment report, Table iv",
  notes = "Annual catch relative to age 26+ biomass; this is not instantaneous F. Lower intervals printed <0.001 are stored blank.")

input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumption_data <- do.call(rbind, assumption_rows)
if (any(!is.finite(input_data$value)) || any(!is.finite(output_data$value))) {
  stop("Rougheye source rows contain non-finite observation or point estimates.", call. = FALSE)
}

stocks_table <- read.csv(file.path(root, "database/stocks.csv"), colClasses = "character", check.names = FALSE)
assessments_table <- read.csv(file.path(root, "database/assessments.csv"), colClasses = "character", check.names = FALSE)
stock_exists <- stock_id %in% stocks_table$stock_id
assessment_exists <- assessment_id %in% assessments_table$assessment_id
if (xor(stock_exists, assessment_exists) || (write_mode && assessment_exists)) {
  stop("Rougheye stock or assessment already exists; inspect before importing.", call. = FALSE)
}
blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks_table), list(
  stock_id = stock_id, authority = "NOAA-NWFSC/SWFSC", authority_stock_id = "14516",
  scientific_name = "Sebastes aleutianus; Sebastes melanostictus",
  common_name = "Rougheye and Blackspotted Rockfish Complex",
  area = "U.S. West Coast", region = region, ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 14516 is one pooled U.S. West Coast management complex comprising rougheye and blackspotted rockfishes; the two species are not separate assessment units."))
assessment <- blank_row(names(assessments_table), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2024L, estimate_terminal_year = 2025L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.23.2 (Report.sso and executive summary); section 3.4.1 states 3.30.23.1",
  is_current = TRUE, is_applied = TRUE, assessment_url = report_url,
  data_url = model_url, model_url = model_url,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2025 assessment with data through 2024. Native files provide catch, aggregate indices, age/length compositions, and fitted N/B/C/F/M surfaces. No observed catch-at-age, age-specific index, empirical age-specific weight/maturity matrices, or age-specific uncertainty is supplied. Reported spawning output is measured in trillions of eggs, not SSB biomass. Table ii interval unit labels conflict with its figure; see source review."))

candidate_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
unworked_path <- file.path(root, "discovery/selected_unworked_2026.csv")
candidates <- read.csv(candidate_path, colClasses = "character", check.names = FALSE)
inventory <- read.csv(inventory_path, colClasses = "character", check.names = FALSE)
ci <- which(candidates$candidate_id == candidate_id)
ii <- which(inventory$candidate_unit_id == candidate_unit_id)
if (length(ci) != 1L || length(ii) != 1L || candidates$eligibility[ci] != "eligible" ||
    (!candidates$import_status[ci] %in% c("not_started", "partial")) ||
    (!inventory$import_status[ii] %in% c("not_started", "partial")) ||
    (assessment_exists && candidates$matched_stock_id[ci] != stock_id)) {
  stop("The NOAA:14516 candidate register no longer matches the screened assessment.", call. = FALSE)
}
candidate_update <- candidates[ci, , drop = FALSE]
candidate_update$matched_stock_id <- stock_id
candidate_update$match_status <- "new"
candidate_update$import_status <- "partial"
candidate_update$catch_age_evidence <- "Imported native catch biomass, conditional age-at-length and marginal age samples. The report does not provide observed catch-at-age numbers."
candidate_update$survey_age_evidence <- "Imported four aggregate survey biomass indices and their errors plus survey composition samples; no direct age-specific abundance index is supplied."
candidate_update$weights_evidence <- "Sex-specific model growth and length-weight relationships; no standalone empirical weight-at-age matrix is supplied."
candidate_update$maturity_evidence <- "Length-based logistic maturity; no standalone empirical maturity-at-age matrix is supplied."
candidate_update$mortality_evidence <- "Female M is estimated; male M is fixed at 0.036 per year. Native M-at-age outputs are imported."
candidate_update$timing_evidence <- "Survey and composition observation month 7 is retained and represented as sampling_time 0.5."
candidate_update$output_evidence <- "Imported fitted N/B/C/F/M surfaces through 2024, total abundance and biomass, recruitment, spawning output, and report tables with recent intervals. No age-specific uncertainty is available."
candidate_update$detailed_source_url <- paste(report_url, model_url, sep = "; ")
candidate_update$review_date <- "2026-11-11"
candidate_update$decision_reason <- "The adopted 2025 assessment has a matching native Stock Synthesis bundle with run-specific inputs and fitted outputs."
candidate_update$notes <- "Partial source import. Spawning output is in eggs, not SSB; Table ii labels its interval units inconsistently. Catch-at-age is fitted output, not observed input; age-specific biology and uncertainty are not available as source matrices."
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
    if ("curation_status" %in% names(unworked_updates)) unworked_updates$curation_status <- "source_curated_partial"
    if ("import_status" %in% names(unworked_updates)) unworked_updates$import_status <- "partial"
  }
}

cat("Prepared ", nrow(input_data), " inputs, ", nrow(assumption_data),
  " assumptions, and ", nrow(output_data), " outputs for NOAA Stock SMART 14516.\n", sep = "")
cat("Native composition frequencies are unnormalized; fitted catch-at-age is stored as output only.\n")
if (write_mode) {
  append_pacific_case(stock, assessment, assumption_data, input_data, output_data)
  replace_candidate_register_row(candidate_path, ci, candidate_update, candidate_id)
  replace_csv_register_row(inventory_path, ii, inventory_update, "unit_key", inventory$unit_key[ii])
  if (!is.null(unworked_updates)) replace_csv_register_row(unworked_path, ui, unworked_updates,
    "candidate_id", candidate_id)
  source(file.path(root, "scripts/database/002_validate_database.R"), local = new.env(parent = globalenv()))
  cat("Rougheye source records appended and full database validation passed.\n")
}
