root <- "."
stock_id <- "noaa_quillback_rockfish_california"
assessment_id <- "noaa_quillback_california_2025"
candidate_id <- "NOAA:15342"
cache <- file.path(root, "source_cache", "discovery_noaa_quillback_ca_2025")
manifest_path <- file.path(root, "provenance", "discovery_noaa_quillback_ca_2025", "sources.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) stop("Install r4ss and pdftools to parse the cached assessment.", call. = FALSE)

manifest <- read.csv(manifest_path, colClasses = "character", stringsAsFactors = FALSE)
verify_source <- function(file) {
  path <- file.path(cache, file); i <- which(manifest$source == file)
  if (length(i) != 1L || !file.exists(path) || file.info(path)$size != as.numeric(manifest$bytes[i]) ||
      tolower(unname(tools::sha256sum(path))) != tolower(manifest$sha256[i])) stop("Source does not match manifest: ", file, call. = FALSE)
  path
}
report_path <- verify_source("assessment_2025.pdf")
model_zip <- verify_source("model_files_2025.zip")
work <- tempfile("quillback_2025_"); dir.create(work); on.exit(unlink(work, recursive = TRUE), add = TRUE)
unzip(model_zip, exdir = work)
dat_path <- list.files(work, "^2025_ca_quillback\\.dat$", recursive = TRUE, full.names = TRUE)
if (length(dat_path) != 1L) stop("Expected one 2025_ca_quillback.dat in the archive.", call. = FALSE)
model_dir <- dirname(dat_path)
if (!file.exists(file.path(model_dir, "Report.sso"))) stop("Official archive lacks Report.sso.", call. = FALSE)
dat <- r4ss::SS_readdat(dat_path, verbose = FALSE)
out <- r4ss::SS_output(model_dir, printstats = FALSE, verbose = FALSE)
pdf_pages <- pdftools::pdf_text(report_path)
ages <- 0:80; years <- 1916:2024; region_name <- "California"
if (dat$styr != 1916L || dat$endyr != 2024L || dat$Nages != 80L || dat$N_areas != 1L ||
    dat$Nsexes != -1L || dat$spawn_month != 1L || dat$Lbin_method != 2L ||
    !identical(as.numeric(dat$lbin_vector), seq(10, 50, 2)) || !identical(as.integer(dat$agebin_vector), 1:60) ||
    nrow(dat$catch) != 218L || nrow(dat$CPUE) != 28L || nrow(dat$lencomp) != 96L || nrow(dat$agecomp) != 253L) {
  stop("The archived model dimensions or input coverage differ from the reviewed assessment.", call. = FALSE)
}
fleet_name <- function(id) as.character(dat$fleetinfo$fleetname[as.integer(id)])
fleet_type <- function(id) as.integer(dat$fleetinfo$type[as.integer(id)])

frame_input <- function(type, measure, basis, value, unit, fleet = "", survey = "", sex = "",
                        region = "", season = "", year = NA_integer_, age = NA_integer_,
                        sampling_time = NA_real_, source_type = "native_model", source_reference,
                        transformation = "", notes = "", observation_id = "", length_bin = NA_real_,
                        length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
                        age_error = NA_real_, partition = "", weight_bin = NA_real_) {
  args <- list(type, measure, basis, value, unit, fleet, survey, sex, region, season, year, age,
    sampling_time, source_type, source_reference, transformation, notes, observation_id,
    length_bin, length_bin_lower, length_bin_upper, sample_size, age_error, partition, weight_bin)
  n <- max(lengths(args)); repn <- function(x) rep_len(x, n); year <- repn(year)
  data.frame(assessment_id = rep(assessment_id, n), type = repn(type), measure = repn(measure), basis = repn(basis),
    fleet = repn(fleet), survey = repn(survey), sex = repn(sex), region = repn(region), season = repn(season),
    year = year, year_basis = ifelse(is.na(year), "", "calendar_year"), age = as.numeric(repn(age)),
    value = as.numeric(repn(value)), unit = repn(unit), sampling_time = as.numeric(repn(sampling_time)),
    source_type = repn(source_type), source_reference = repn(source_reference), transformation = repn(transformation),
    notes = repn(notes), observation_id = repn(observation_id), length_bin = as.numeric(repn(length_bin)),
    length_bin_lower = as.numeric(repn(length_bin_lower)), length_bin_upper = as.numeric(repn(length_bin_upper)),
    sample_size = as.numeric(repn(sample_size)), age_error = as.numeric(repn(age_error)),
    partition = repn(partition), weight_bin = as.numeric(repn(weight_bin)), stringsAsFactors = FALSE)
}

catch_year <- as.integer(dat$catch$year); catch_id <- as.integer(dat$catch$fleet)
catch_fleet <- fleet_name(catch_id); catch_obs <- paste0("CA_CATCH_", catch_id, "_", catch_year)
catch_rows <- frame_input("catch", "catch_biomass", "biomass", dat$catch$catch, "metric tonnes",
  fleet = catch_fleet, region = region_name, season = "annual", year = catch_year,
  source_reference = "2025_ca_quillback.dat, catch block",
  notes = "Native annual catch biomass supplied to Stock Synthesis; source fleet identity retained.", observation_id = catch_obs)
catch_sd <- frame_input("catch", "log_catch_sd", "log_scale", dat$catch$catch_se, "log-scale SD",
  fleet = catch_fleet, region = region_name, season = "annual", year = catch_year,
  source_reference = "2025_ca_quillback.dat, catch block, catch_se",
  notes = "Native catch_se retained on the log scale; 0.05 for each catch observation.", observation_id = catch_obs)

survey_name <- function(id) switch(as.character(id), "2" = "CA_Recreational CPUE", "4" = "CA_CCFRP", "5" = "CA_ROV", stop("Unexpected CPUE fleet."))
cpue_id <- as.integer(dat$CPUE$index); cpue_year <- as.integer(dat$CPUE$year)
cpue_fleet <- fleet_name(cpue_id); cpue_survey <- vapply(cpue_id, survey_name, character(1))
cpue_obs <- paste0("CA_CPUE_", cpue_id, "_", cpue_year)
if (!all(dat$CPUEinfo$units[match(cpue_id, dat$CPUEinfo$fleet)] == 0) || !all(dat$CPUE$month == 7L)) stop("CPUE units or timing differ from source review.")
cpue <- frame_input("index", "relative_abundance_index", "index_scale", dat$CPUE$obs, "relative index units",
  fleet = ifelse(fleet_type(cpue_id) == 1L, cpue_fleet, ""), survey = cpue_survey, region = region_name,
  season = "month 7", year = cpue_year, sampling_time = 0.5,
  source_reference = "2025_ca_quillback.dat, CPUE and CPUEinfo blocks",
  notes = paste0("Native relative abundance index; model fleet ", cpue_id, " (", cpue_fleet, "). July observations are at within-year model time 0.5."), observation_id = cpue_obs)
cpue_sd <- frame_input("index", "log_index_sd", "log_scale", dat$CPUE$se_log, "log-scale SD",
  fleet = ifelse(fleet_type(cpue_id) == 1L, cpue_fleet, ""), survey = cpue_survey, region = region_name,
  season = "month 7", year = cpue_year, sampling_time = 0.5,
  source_reference = "2025_ca_quillback.dat, CPUE block, se_log",
  notes = paste0("Native log-scale index SD; model fleet ", cpue_id, ". July observations are at within-year model time 0.5."), observation_id = cpue_obs)
# Preserve source frequency vectors and explicit negative-year exclusion flags.
length_bins <- as.numeric(dat$lbin_vector); n_len <- length(length_bins)
len_cols <- paste0("l", length_bins); len_mat <- as.matrix(dat$lencomp[, len_cols, drop = FALSE])
len_row <- rep(seq_len(nrow(dat$lencomp)), each = n_len)
len_year_code <- as.integer(dat$lencomp$year); len_year <- abs(len_year_code)
len_fleet_id <- as.integer(dat$lencomp$fleet); len_fleet <- fleet_name(len_fleet_id)
len_fishery <- fleet_type(len_fleet_id) == 1L
len_state <- ifelse(len_year_code < 0L, "excluded", "active")
len_obs <- paste0("CA_LENCOMP_", len_fleet_id, "_", len_year, "_", len_state, "_r", sprintf("%03d", seq_len(nrow(dat$lencomp))))
len_upper <- c(length_bins[-1L], NA_real_)
length_rows <- frame_input(
  type = ifelse(rep(len_fishery, each = n_len), "catch", "index"),
  measure = "frequency_at_length", basis = "native_frequency", value = as.vector(t(len_mat)),
  unit = "native frequency units",
  fleet = ifelse(rep(len_fishery, each = n_len), rep(len_fleet, each = n_len), ""),
  survey = ifelse(rep(len_fishery, each = n_len), "", rep(len_fleet, each = n_len)),
  region = region_name, season = "month 7", year = rep(len_year, each = n_len), sampling_time = 0.5,
  source_reference = paste0("2025_ca_quillback.dat, lencomp row ", len_row),
  transformation = "Map Lbin_method 2 labels to source lower-edge centimetres; store absolute year and preserve source sign in notes.",
  notes = paste0("Native frequencies and Nsamp are unscaled; first bin also captures values below 10 cm, and the final bin is open-ended. Negative source year code ", rep(len_year_code, each = n_len), " excludes the row from the likelihood."),
  observation_id = rep(len_obs, each = n_len), length_bin = rep(length_bins, times = nrow(dat$lencomp)),
  length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = rep(as.numeric(dat$lencomp$Nsamp), each = n_len))

age_bins <- as.integer(dat$agebin_vector); n_age <- length(age_bins)
age_cols <- paste0("a", age_bins); age_mat <- as.matrix(dat$agecomp[, age_cols, drop = FALSE])
age_row <- rep(seq_len(nrow(dat$agecomp)), each = n_age)
age_year_code <- as.integer(dat$agecomp$year); age_year <- abs(age_year_code)
age_fleet_id <- as.integer(dat$agecomp$fleet); age_fleet <- fleet_name(age_fleet_id)
age_survey <- age_fleet %in% c("CA_CCFRP", "CA_ROV")
age_state <- ifelse(age_year_code < 0L, "excluded", "active")
age_lo <- as.integer(dat$agecomp$Lbin_lo); age_hi <- as.integer(dat$agecomp$Lbin_hi)
if (any(age_lo < 1L | age_lo > length(length_bins) | age_hi < 1L | age_hi > length(length_bins) | age_hi < age_lo)) stop("Age-data length-bin codes are outside the native Lbin vector.", call. = FALSE)
age_obs <- paste0("CA_AGECOMP_", age_fleet_id, "_", age_year, "_", length_bins[age_lo], "_", length_bins[age_hi], "_", age_state, "_r", sprintf("%03d", seq_len(nrow(dat$agecomp))))
age_rows <- frame_input(
  "biology", "conditional_frequency_at_age", "native_frequency", as.vector(t(age_mat)), "fish frequency",
  fleet = ifelse(rep(!age_survey, each = n_age), rep(age_fleet, each = n_age), ""),
  survey = ifelse(rep(age_survey, each = n_age), rep(age_fleet, each = n_age), ""),
  region = region_name, season = "month 7", year = rep(age_year, each = n_age),
  age = rep(age_bins, times = nrow(dat$agecomp)), sampling_time = 0.5,
  source_reference = paste0("2025_ca_quillback.dat, agecomp row ", age_row),
  transformation = "Retain native Lbin_method 2 data-bin indices; lbin_vector defines their lower-edge centimetre labels. Store absolute year and preserve source sign in notes.",
  notes = paste0("Conditional native age-at-length frequencies, Nsamp and age-error code retained. Negative source year code ", rep(age_year_code, each = n_age), " excludes the row from the likelihood."),
  observation_id = rep(age_obs, each = n_age),
  length_bin_lower = rep(age_lo, each = n_age),
  length_bin_upper = rep(age_hi, each = n_age),
  sample_size = rep(as.numeric(dat$agecomp$Nsamp), each = n_age),
  age_error = rep(as.integer(dat$agecomp$ageerr), each = n_age))
m_rows <- frame_input("M", "natural_mortality_at_age", "per_year", rep(0.068, 81), "per year",
  region = region_name, age = 0:80,
  source_reference = "2025_ca_quillback.ctl; 2025 assessment report, section 2.4.1",
  notes = "Natural mortality is fixed at 0.068 per year at ages 0-80; age 80 is the plus group.")
inputs_new <- do.call(rbind, list(catch_rows, catch_sd, cpue, cpue_sd, length_rows, age_rows, m_rows))

frame_output <- function(type, measure, year, value, unit, age = NA_integer_, age_group = "",
                         fleet = "", survey = "", sex = "", region = region_name, season = "",
                         se = NA_real_, lwr = NA_real_, upr = NA_real_, source_type = "native_model",
                         source_reference, notes = "", scenario = "") {
  a <- list(type, measure, year, value, unit, age, age_group, fleet, survey, sex,
    region, season, se, lwr, upr, source_type, source_reference, notes, scenario)
  n <- max(lengths(a)); repn <- function(x) rep_len(x, n)
  data.frame(assessment_id = rep(assessment_id, n), type = repn(type), measure = repn(measure),
    fleet = repn(fleet), survey = repn(survey), sex = repn(sex), region = repn(region),
    season = repn(season), year = as.integer(repn(year)), age = as.numeric(repn(age)),
    age_group = repn(age_group), value = as.numeric(repn(value)), se = as.numeric(repn(se)),
    lwr = as.numeric(repn(lwr)), upr = as.numeric(repn(upr)), unit = repn(unit),
    source_type = repn(source_type), source_reference = repn(source_reference),
    notes = repn(notes), scenario = repn(scenario), stringsAsFactors = FALSE)
}
surface_rows <- function(x, type, measure, unit, reference, notes, fleet_column = NULL) {
  ages_out <- 0:80; cols <- as.character(ages_out)
  if (!all(cols %in% names(x))) stop("Report.sso surface lacks age columns.", call. = FALSE)
  fleets <- if (is.null(fleet_column)) rep("", nrow(x)) else fleet_name(x[[fleet_column]])
  frame_output(type, measure, rep(as.integer(x$Yr), each = length(ages_out)),
    as.vector(t(as.matrix(x[, cols, drop = FALSE]))), unit,
    age = rep(ages_out, times = nrow(x)), fleet = rep(fleets, each = length(ages_out)),
    season = "annual", source_reference = reference, notes = notes)
}
n_surface <- out$natage[out$natage$Era == "TIME" & out$natage[["Beg/Mid"]] == "B", , drop = FALSE]
b_surface <- out$batage[out$batage$Era == "TIME" & out$batage[["Beg/Mid"]] == "B", , drop = FALSE]
m_surface <- out$Natural_Mortality[out$Natural_Mortality$Era == "TIME" & out$Natural_Mortality[["Beg/Mid"]] == "B", , drop = FALSE]
f_surface <- out$fatage[out$fatage$Era == "TIME", , drop = FALSE]
c_surface <- out$catage[out$catage$Era == "TIME" & out$catage$Type == "dead", , drop = FALSE]
if (nrow(n_surface) != 109L || nrow(b_surface) != 109L || nrow(m_surface) != 109L || nrow(f_surface) != 218L || nrow(c_surface) != 218L || !identical(sort(unique(as.integer(n_surface$Yr))), 1916:2024)) stop("Report.sso historical surface coverage differs from 1916-2024.", call. = FALSE)
nat_file <- read.csv(file.path(model_dir, "natage.csv"), check.names = FALSE)
nat_file <- nat_file[nat_file$Year %in% years, , drop = FALSE]
nat_file_values <- as.matrix(nat_file[, paste0("Age", 0:80), drop = FALSE])
report_n_values <- as.matrix(n_surface[, as.character(0:80), drop = FALSE])
if (nrow(nat_file) != 109L || max(abs(nat_file_values - report_n_values)) > 0.000051 ||
    any(abs(as.matrix(m_surface[, as.character(0:80), drop = FALSE]) - 0.068) > 1e-12)) {
  stop("Report.sso N/M surfaces do not match the native age-series checks.", call. = FALSE)
}
N_rows <- surface_rows(n_surface, "population", "numbers_at_age", "thousand fish", "Report.sso, TIME, beginning-year N-at-age", "Fitted N at ages 0-80; age 80 is plus group.")
B_rows <- surface_rows(b_surface, "biomass", "biomass_at_age", "metric tonnes", "Report.sso, TIME, beginning-year biomass-at-age", "Fitted biomass at ages 0-80; age 80 is plus group.")
M_out <- surface_rows(m_surface, "mortality", "natural_mortality_at_age", "per year", "Report.sso, TIME, beginning-year M-at-age", "M is fixed at 0.068 per year for all ages.")
F_out <- surface_rows(f_surface, "mortality", "fishing_mortality_at_age", "per year", "Report.sso, TIME, fleet-specific F-at-age", "Fitted fleet-specific F; fleet identity retained.", "Fleet")
C_out <- surface_rows(c_surface, "catch", "numbers_at_age", "thousand fish", "Report.sso, TIME, Type=dead catch-at-age", "Model-generated dead catch numbers-at-age, not an observed input.", "Fleet")
# Preserve official time-series outputs and report confidence limits.
f_total <- do.call(rbind, lapply(1916:2024, function(y) {
  z <- f_surface[f_surface$Yr == y, , drop = FALSE]
  if (nrow(z) != 2L) stop("Expected both fishery F surfaces for year ", y, call. = FALSE)
  vals <- colSums(as.matrix(z[, as.character(0:80), drop = FALSE]))
  data.frame(year = y, t(vals), check.names = FALSE)
}))
names(f_total) <- c("year", as.character(0:80))
F_total <- frame_output("mortality", "fishing_mortality_at_age",
  rep(f_total$year, each = 81L), as.vector(t(as.matrix(f_total[, as.character(0:80), drop = FALSE]))),
  "per year", age = rep(0:80, times = nrow(f_total)), season = "annual",
  source_type = "derived_source_output", source_reference = "Report.sso, TIME, fleet-specific F-at-age",
  notes = "Derived total F-at-age by summing the two fishery fleets' reported F-at-age; uncertainty is unavailable.")
history <- out$timeseries[out$timeseries$Era == "TIME" & out$timeseries$Yr %in% 1916:2024, , drop = FALSE]
if (nrow(history) != 109L) stop("Expected historical time-series rows from 1916 through 2024.", call. = FALSE)
biomass_all <- frame_output("biomass", "total_biomass", history$Yr, history$Bio_all, "metric tonnes",
  age_group = "all ages", source_reference = "Report.sso, TIME, Bio_all", notes = "Reported biomass over all modeled ages.")
biomass_3plus <- frame_output("biomass", "total_biomass", history$Yr, history$Bio_smry, "metric tonnes",
  age_group = "3+", source_reference = "Report.sso, TIME, Bio_smry", notes = "SS3 summary biomass for ages 3+.")
total_n <- frame_output("population", "total_numbers", history$Yr,
  rowSums(as.matrix(n_surface[, as.character(0:80), drop = FALSE])), "thousand fish",
  age_group = "0-80", source_type = "derived_source_output",
  source_reference = "Report.sso, TIME, beginning-year N-at-age",
  notes = "Derived by summing reported N-at-age over ages 0-80; age 80 is the plus group. No uncertainty is available.")

parse_recent_table <- function(page, name) {
  lines <- strsplit(pdf_pages[[page]], "\n", fixed = TRUE)[[1L]]
  lines <- lines[grepl("^\\s*20(1[5-9]|2[0-5])\\s+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    tokens <- regmatches(line, gregexpr("(?<![[:alnum:].])[-+]?[0-9]+(?:\\.[0-9]+)?(?![[:alnum:].])", line, perl = TRUE))[[1L]]
    as.numeric(tokens)
  })
  rows <- Filter(function(x) length(x) == 7L, rows)
  if (length(rows) != 11L) stop(name, " does not contain 2015-2025 values.", call. = FALSE)
  x <- as.data.frame(do.call(rbind, rows)); names(x) <- c("year", "estimate", "lwr", "upr", "other", "other_lwr", "other_upr")
  x$year <- as.integer(x$year)
  if (!identical(x$year, 2015:2025)) stop(name, " years changed.", call. = FALSE)
  x
}
spawn_table <- parse_recent_table(10L, "Table ii")
recruit_table <- parse_recent_table(12L, "Table iii")
spawn_point <- out$timeseries$SpawnBio[match(spawn_table$year, out$timeseries$Yr)]
recruit_point <- out$timeseries$Recruit_0[match(recruit_table$year, out$timeseries$Yr)]
if (anyNA(spawn_point) || anyNA(recruit_point) || max(abs(spawn_point - spawn_table$estimate)) > 0.006 ||
    max(abs(recruit_point - recruit_table$estimate)) > 0.51) stop("Report.sso point estimates do not match Tables ii-iii within printed rounding.", call. = FALSE)
spawn_old <- out$timeseries[out$timeseries$Era == "TIME" & out$timeseries$Yr < 2015, , drop = FALSE]
recruit_old <- spawn_old
spawn <- rbind(
  frame_output("biology", "spawning_output", spawn_old$Yr, spawn_old$SpawnBio, "billion eggs",
    source_reference = "Report.sso, TIME, SpawnBio", notes = "Spawning output in eggs; not spawning-stock biomass (SSB)."),
  frame_output("biology", "spawning_output", spawn_table$year, spawn_point, "billion eggs",
    lwr = spawn_table$lwr, upr = spawn_table$upr, source_type = "official_table",
    source_reference = "Report.sso; assessment report Table ii, p. iii",
    notes = "Point estimate from Report.sso; rounded 95% confidence limits from Table ii. Spawning output is not SSB.",
    scenario = ifelse(spawn_table$year == 2025L, "one-year forecast", "")))
recruit <- rbind(
  frame_output("recruitment", "recruitment", recruit_old$Yr, recruit_old$Recruit_0, "thousand fish",
    source_reference = "Report.sso, TIME, Recruit_0", notes = "Age-0 recruitment in thousands of fish."),
  frame_output("recruitment", "recruitment", recruit_table$year, recruit_point, "thousand fish",
    lwr = recruit_table$lwr, upr = recruit_table$upr, source_type = "official_table",
    source_reference = "Report.sso; assessment report Table iii, p. v",
    notes = "Point estimate from Report.sso; rounded 95% confidence limits from Table iii.",
    scenario = ifelse(recruit_table$year == 2025L, "one-year forecast", "")))
outputs_new <- do.call(rbind, list(N_rows, B_rows, M_out, F_out, C_out, F_total,
  biomass_all, biomass_3plus, total_n, spawn, recruit))

stock_row <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NOAA-SWFSC",
  authority_stock_id = "15342", scientific_name = "Sebastes maliger",
  common_name = "California quillback rockfish", area = "California", region = "U.S. West Coast",
  ocean = "Northeast Pacific", notes = "NOAA Stock SMART assessment unit 15342; distinct from Canadian Quillback.", stringsAsFactors = FALSE)
assessment_row <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2025L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis", model_version = "3.30.23.1",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.pcouncil.org/documents/2026/01/status-of-quillback-rockfish-in-u-s-waters-off-california-in-2025.pdf/",
  framework_url = "", data_url = "https://www.pcouncil.org/documents/ca-quillback-2025-model-files-zip-file/",
  model_url = "https://www.pcouncil.org/documents/ca-quillback-2025-model-files-zip-file/",
  repository_url = "", assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2025 assessment fitted through 2024. Age-specific surfaces are retained through 2024; aggregate spawning-output and recruitment intervals extend through the one-year 2025 forecast. The public archive lacks fitted parameter/covariance output.", stringsAsFactors = FALSE)
assumption <- function(component, setting, value, source_reference, notes = "") data.frame(
  assessment_id = assessment_id, component = component, fleet = "", survey = "", sex = "", region = "", season = "",
  setting = setting, value = value, source_reference = source_reference, notes = notes, stringsAsFactors = FALSE)
assumptions_new <- rbind(
  assumption("population", "dimensions", "One area and one modeled sex; ages 0-80; age 80 is the plus group; fitted years 1916-2024.", "2025_ca_quillback.dat; Report.sso", "Single modeled sex is not labeled male or female."),
  assumption("model", "software", "Stock Synthesis 3.30.23.1.", "Report.sso; assessment report"),
  assumption("catch", "likelihood", "Annual catch biomass for CA_Commercial and CA_Recreational; catch_se is 0.05 on the log scale.", "2025_ca_quillback.dat, catch block"),
  assumption("index", "series", "CA_Recreational CPUE, CA_CCFRP and CA_ROV are relative abundance indices on separate native scales.", "2025_ca_quillback.dat, CPUE and CPUEinfo blocks"),
  assumption("index", "timing", "Source observations are from July; Report.sso represents index time at 0.5 within the annual model year.", "2025_ca_quillback.dat, CPUE; Report.sso, cpue table"),
  assumption("biology", "compositions", "Length frequencies and conditional age-at-length frequencies are preserved on their native scales; age-error code 1 is used. Negative-year rows are excluded from the likelihood.", "2025_ca_quillback.dat, lencomp and agecomp; SS3 User Manual composition rules"),
  assumption("biology", "growth", "Growth parameters are estimated with a von Bertalanffy model; an external length-weight relationship is used.", "2025_ca_quillback.ctl; assessment report sections 2.4.2 and 2.4.4"),
  assumption("biology", "maturity", "Length-based logistic maturity uses California-specific biological information.", "2025_ca_quillback.ctl; assessment report section 2.4.3"),
  assumption("biology", "fecundity", "Spawning output is fecundity in eggs calculated from length, not biomass SSB.", "Report.sso SpawnOutput fields; assessment report section 2.4.4, Table ii"),
  assumption("mortality", "natural_mortality", "M is fixed at 0.068 per year across ages, based on the median prior for a maximum age of 80 years.", "2025_ca_quillback.ctl; assessment report section 2.4.1"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt relationship; recruitment deviations begin in 1940; steepness is fixed at 0.72.", "2025_ca_quillback.ctl; assessment report executive summary and section 2.5"),
  assumption("uncertainty", "reported_uncertainty", "The report provides 95% intervals for spawning output and recruitment for 2015-2025; age-specific uncertainty surfaces were not recovered.", "Assessment report Tables ii-iii; Report.sso"),
  assumption("output", "age_surfaces", "N-at-age, biomass-at-age, M-at-age and fleet-specific F-at-age are retained for 1916-2024; total abundance and total F are derived from those surfaces.", "Report.sso, TIME era surfaces")
)
key <- function(x, cols) do.call(paste, c(lapply(x[cols], function(z) {
  z <- as.character(z); z[is.na(z)] <- ""; z
}), sep = "\r"))
input_key_cols <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex", "region", "season", "year", "year_basis", "age", "observation_id", "length_bin", "length_bin_lower", "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin")
output_key_cols <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "age_group", "scenario")
if (anyDuplicated(key(inputs_new, input_key_cols)) || anyDuplicated(key(outputs_new, output_key_cols))) stop("New records contain duplicate canonical keys.", call. = FALSE)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidate <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
ci <- match(candidate_id, candidate$candidate_id)
if (is.na(ci) || candidate$screening_status[ci] != "screened" || candidate$eligibility[ci] != "eligible" ||
    !candidate$match_status[ci] %in% c("new", "matched") ||
    (!is.na(candidate$matched_stock_id[ci]) && candidate$matched_stock_id[ci] != stock_id)) stop("NOAA candidate status differs from the reviewed unit.", call. = FALSE)
candidate$match_status[ci] <- "matched"; candidate$matched_stock_id[ci] <- stock_id
candidate$import_status[ci] <- "partial"
candidate$notes[ci] <- paste("Official 2025 California Quillback assessment imported from its native Stock Synthesis archive and detailed report.",
  "Inputs preserve catch biomass, relative CPUE, length frequencies, conditional age-at-length frequencies, and fixed M.",
  "Outputs include age-specific surfaces through 2024 and aggregate spawning-output/recruitment uncertainty through the 2025 forecast.",
  "See source_reviews/noaa_quillback_california_2025.md for coverage and limits.")

existing_rows <- function(path) {
  rg <- Sys.which("rg")
  if (nzchar(rg)) {
    found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
    status <- attr(found, "status"); if (is.null(status)) status <- 0L
    if (status == 1L) return(character())
    if (status != 0L) stop("Could not scan ", path, call. = FALSE)
    return(found[startsWith(found, paste0("\"", assessment_id, "\","))])
  }
  con <- file(path, open = "rt"); on.exit(close(con), add = TRUE); found <- character()
  repeat {
    lines <- readLines(con, n = 20000L, warn = FALSE); if (!length(lines)) break
    hit <- lines[startsWith(lines, paste0("\"", assessment_id, "\","))]
    if (length(hit)) found <- c(found, hit)
  }
  found
}
for (name in c("stocks", "assessments", "assumptions", "inputs", "outputs")) {
  path <- file.path(root, "database", paste0(name, ".csv"))
  if (length(existing_rows(path))) stop("Rows for this assessment already exist in ", path, "; refusing duplicate import.", call. = FALSE)
}
cat("California Quillback 2025 import: ", nrow(inputs_new), " inputs; ", nrow(outputs_new), " outputs.\n",
  "Catch ", min(catch_year), "-", max(catch_year), "; CPUE ", min(cpue_year), "-", max(cpue_year),
  "; length comps ", sum(dat$lencomp$year > 0L), " active / ", sum(dat$lencomp$year < 0L), " excluded; age comps ",
  sum(dat$agecomp$year > 0L), " active / ", sum(dat$agecomp$year < 0L), " excluded.\n",
  "Age-specific outputs end in 2024; aggregate spawning-output and recruitment intervals extend through the 2025 forecast.\n", sep = "")
if (!write_mode) {
  cat("Dry run only; add --write to append the records and reconcile the candidate unit.\n")
  quit(save = "no", status = 0L)
}
append_csv <- function(x, path) write.table(x, file = path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8")
append_csv(stock_row, file.path(root, "database", "stocks.csv"))
append_csv(assessment_row, file.path(root, "database", "assessments.csv"))
append_csv(assumptions_new, file.path(root, "database", "assumptions.csv"))
append_csv(inputs_new, file.path(root, "database", "inputs.csv"))
append_csv(outputs_new, file.path(root, "database", "outputs.csv"))

candidate_lines <- readLines(candidate_path, warn = FALSE, encoding = "UTF-8")
if (length(candidate_lines) != nrow(candidate) + 1L) stop("Candidate register has multiline CSV records; refusing a non-row-safe update.", call. = FALSE)
tmp_candidate <- tempfile(fileext = ".csv")
write.csv(candidate[ci, , drop = FALSE], tmp_candidate, row.names = FALSE, na = "", fileEncoding = "UTF-8")
candidate_lines[ci + 1L] <- readLines(tmp_candidate, warn = FALSE, encoding = "UTF-8")[-1L]
unlink(tmp_candidate); writeLines(candidate_lines, candidate_path, useBytes = TRUE)
source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"), local = TRUE)
source(file.path(root, "scripts", "database", "002_validate_database.R"), local = TRUE)
cat("Import written and database validation passed.\n")
