root <- "."
stock_id <- "noaa_cowcod_southern_california"
assessment_id <- "noaa_cowcod_southern_california_2019"
candidate_id <- "NOAA:10443"
cache <- file.path(root, "source_cache", "discovery_noaa_cowcod_california_2019")
manifest_path <- file.path(root, "provenance", "noaa_cowcod_southern_california_2019", "manifest.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to parse the cached Cowcod assessment.", call. = FALSE)
}

manifest <- read.csv(manifest_path, colClasses = "character", stringsAsFactors = FALSE)
verify_source <- function(file) {
  path <- file.path(cache, file)
  i <- which(manifest$source == file)
  if (length(i) != 1L || !file.exists(path) ||
      file.info(path)$size != as.numeric(manifest$bytes[i]) ||
      tolower(unname(tools::sha256sum(path))) != tolower(manifest$sha256[i])) {
    stop("Source does not match manifest: ", file, call. = FALSE)
  }
  path
}
report_path <- verify_source("cowcod_2019_assessment.pdf")
model_zip <- verify_source("cowcod_2019_model_files.zip")
work <- tempfile("cowcod_2019_")
dir.create(work)
on.exit(unlink(work, recursive = TRUE), add = TRUE)
unzip(model_zip, exdir = work)
dat_path <- list.files(work, "^cowcod2019\\.dat$", recursive = TRUE, full.names = TRUE)
if (length(dat_path) != 1L) stop("Expected one cowcod2019.dat in the archive.", call. = FALSE)
model_dir <- dirname(dat_path)
for (file in c("cowcod2019.ctl", "Report.sso", "forecast.ss")) {
  if (!file.exists(file.path(model_dir, file))) stop("Official model archive lacks ", file, call. = FALSE)
}

dat <- r4ss::SS_readdat(dat_path, verbose = FALSE)
out <- r4ss::SS_output(model_dir, printstats = FALSE, verbose = FALSE)
pdf_pages <- pdftools::pdf_text(report_path)
years <- 1900:2018
ages <- 0:60
region_name <- "Southern California Bight"
if (dat$styr != 1900L || dat$endyr != 2018L || dat$nseas != 1L || dat$Nages != 60L ||
    dat$Nsexes != 1L || dat$N_areas != 1L || dat$lbin_method != 2L || dat$Lbin_method != 3L ||
    !identical(as.numeric(dat$lbin_vector), seq(6, 98, 2)) ||
    !identical(as.integer(dat$agebin_vector), ages) || nrow(dat$catch) != 211L ||
    sum(dat$catch$year == -999L) != 1L || nrow(dat$CPUE) != 57L ||
    nrow(dat$lencomp) != 60L || nrow(dat$agecomp) != 438L ||
    !setequal(unique(dat$CPUE$month), c(1L, 7L))) {
  stop("Archived Cowcod dimensions or input coverage differ from the reviewed assessment.", call. = FALSE)
}
if (!all(dat$catch$year[dat$catch$year != -999L] %in% years) ||
    !all(abs(dat$CPUE$year - round(dat$CPUE$year)) == 0) ||
    !all(dat$agecomp$Lbin_lo >= min(dat$lbin_vector) & dat$agecomp$Lbin_hi <= max(dat$lbin_vector))) {
  stop("Cowcod input years or length bounds fall outside the native model dimensions.", call. = FALSE)
}
fleet_name <- function(id) {
  id <- as.integer(id)
  if (any(id < 1L | id > nrow(dat$fleetinfo))) stop("Unexpected fleet code.", call. = FALSE)
  as.character(dat$fleetinfo$fleetname[id])
}
fleet_type <- function(id) {
  id <- as.integer(id)
  if (any(id < 1L | id > nrow(dat$fleetinfo))) stop("Unexpected fleet code.", call. = FALSE)
  as.integer(dat$fleetinfo$type[id])
}

frame_input <- function(type, measure, basis, value, unit, fleet = "", survey = "", sex = "",
                        region = "", season = "", year = NA_integer_, age = NA_integer_,
                        sampling_time = NA_real_, source_type = "native_model", source_reference,
                        transformation = "", notes = "", observation_id = "", length_bin = NA_real_,
                        length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
                        age_error = NA_real_, partition = "", weight_bin = NA_real_) {
  args <- list(type, measure, basis, value, unit, fleet, survey, sex, region, season, year, age,
    sampling_time, source_type, source_reference, transformation, notes, observation_id,
    length_bin, length_bin_lower, length_bin_upper, sample_size, age_error, partition, weight_bin)
  n <- max(lengths(args))
  repn <- function(x) rep_len(x, n)
  year <- repn(year)
  data.frame(assessment_id = rep(assessment_id, n), type = repn(type), measure = repn(measure),
    basis = repn(basis), fleet = repn(fleet), survey = repn(survey), sex = repn(sex),
    region = repn(region), season = repn(season), year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"), age = as.numeric(repn(age)),
    value = as.numeric(repn(value)), unit = repn(unit), sampling_time = as.numeric(repn(sampling_time)),
    source_type = repn(source_type), source_reference = repn(source_reference),
    transformation = repn(transformation), notes = repn(notes), observation_id = repn(observation_id),
    length_bin = as.numeric(repn(length_bin)), length_bin_lower = as.numeric(repn(length_bin_lower)),
    length_bin_upper = as.numeric(repn(length_bin_upper)), sample_size = as.numeric(repn(sample_size)),
    age_error = as.numeric(repn(age_error)), partition = repn(partition),
    weight_bin = as.numeric(repn(weight_bin)), stringsAsFactors = FALSE)
}

catch_keep <- dat$catch$year != -999L
catch_year <- as.integer(dat$catch$year[catch_keep])
catch_id <- as.integer(dat$catch$fleet[catch_keep])
catch_fleet <- fleet_name(catch_id)
catch_obs <- paste0("COW_CATCH_", catch_id, "_", catch_year)
catch_rows <- frame_input("catch", "catch_biomass", "biomass", dat$catch$catch[catch_keep],
  "metric tonnes", fleet = catch_fleet, region = region_name, season = "annual", year = catch_year,
  source_reference = "cowcod2019.dat, catch block",
  notes = "Native annual commercial or recreational catch biomass; the -999 placeholder is not a calendar-year observation and is excluded.",
  observation_id = catch_obs)
catch_sd <- frame_input("catch", "log_catch_sd", "log_scale", dat$catch$catch_se[catch_keep],
  "log-scale SD", fleet = catch_fleet, region = region_name, season = "annual", year = catch_year,
  source_reference = "cowcod2019.dat, catch block, catch_se",
  notes = "Native catch_se retained on the model's log-error scale.", observation_id = catch_obs)

index_id <- as.integer(dat$CPUE$index)
index_year <- as.integer(dat$CPUE$year)
index_month <- as.integer(dat$CPUE$month)
index_fleet <- fleet_name(index_id)
index_time <- (index_month - 1) / 12
index_obs <- paste0("COW_INDEX_", index_id, "_", index_year, "_m", index_month)
if (!all(fleet_type(index_id) == 3L) || !all(dat$CPUE$se_log > 0)) {
  stop("Cowcod index fleet types or log-scale SDs differ from the source review.", call. = FALSE)
}
index_unit_code <- as.integer(dat$CPUEinfo$units[match(index_id, dat$CPUEinfo$fleet)])
if (anyNA(index_unit_code) || !setequal(unique(index_unit_code), c(0L, 1L, 30L)) ||
    sum(index_unit_code == 1L) != 2L || sum(index_unit_code == 0L) != 41L ||
    sum(index_unit_code == 30L) != 14L) {
  stop("Cowcod CPUE unit codes differ from the four relative series and two visual surveys.", call. = FALSE)
}
index_measure <- ifelse(index_unit_code == 1L, "total_biomass",
  ifelse(index_unit_code == 30L, "larval_abundance_index", "relative_abundance_index"))
index_basis <- ifelse(index_unit_code == 1L, "biomass", "index_scale")
index_unit <- ifelse(index_unit_code == 1L, "metric tonnes",
  ifelse(index_unit_code == 30L, "native larval abundance index units", "native relative index units"))
index_note <- ifelse(index_unit_code == 1L,
  paste0("Native absolute visual-survey biomass observation from fleet ", index_id,
    " (", index_fleet, "); Stock Synthesis CPUE unit code 1 is biomass in metric tonnes."),
  ifelse(index_unit_code == 30L,
    paste0("Native CalCOFI larval abundance index from fleet ", index_id,
      "; retain Stock Synthesis unit code 30 and its source scale."),
    paste0("Native relative abundance index from fleet ", index_id, " (", index_fleet,
      "); preserve its relative scale and separate fleet identity.")))
index_rows <- frame_input("index", index_measure, index_basis, dat$CPUE$obs,
  index_unit, survey = index_fleet, region = region_name,
  season = paste0("month ", index_month), year = index_year, sampling_time = index_time,
  source_reference = "cowcod2019.dat, CPUE and CPUEinfo blocks",
  notes = index_note, observation_id = index_obs)
index_sd <- frame_input("index", "log_index_sd", "log_scale", dat$CPUE$se_log,
  "log-scale SD", survey = index_fleet, region = region_name,
  season = paste0("month ", index_month), year = index_year, sampling_time = index_time,
  source_reference = "cowcod2019.dat, CPUE block, se_log",
  notes = "Native observation SD on the log scale; January maps to within-year time 0 and July to 0.5.",
  observation_id = index_obs)

length_bins <- as.numeric(dat$lbin_vector)
n_length <- length(length_bins)
length_cols <- paste0("l", length_bins)
length_mat <- as.matrix(dat$lencomp[, length_cols, drop = FALSE])
length_row <- rep(seq_len(nrow(dat$lencomp)), each = n_length)
length_year_code <- as.integer(dat$lencomp$year)
length_year <- abs(length_year_code)
length_fleet_id <- as.integer(dat$lencomp$fleet)
length_fishery <- length_fleet_id > 0L & fleet_type(ifelse(length_fleet_id > 0L, length_fleet_id, 1L)) == 1L
length_survey <- length_fleet_id > 0L & fleet_type(ifelse(length_fleet_id > 0L, length_fleet_id, 1L)) == 3L
if (any(length_fleet_id < -1L) || any(length_fleet_id > 0L & !(length_fishery | length_survey))) {
  stop("Unrecognized fleet code in Cowcod length compositions.", call. = FALSE)
}
length_state <- ifelse(length_year_code < 0L, "excluded", "active")
length_type <- ifelse(length_fleet_id < 1L, "biology", ifelse(length_fishery, "catch", "index"))
length_fleet <- ifelse(length_fishery, fleet_name(ifelse(length_fishery, length_fleet_id, 1L)), "")
length_survey_name <- ifelse(length_survey, fleet_name(ifelse(length_survey, length_fleet_id, 1L)), "")
length_obs <- paste0("COW_LENCOMP_f", length_fleet_id, "_", length_year, "_", length_state,
  "_r", sprintf("%03d", seq_len(nrow(dat$lencomp))))
length_upper <- c(length_bins[-1L], NA_real_)
length_rows <- frame_input(
  type = rep(length_type, each = n_length), measure = "frequency_at_length", basis = "native_frequency",
  value = as.vector(t(length_mat)), unit = "native frequency units",
  fleet = rep(length_fleet, each = n_length), survey = rep(length_survey_name, each = n_length),
  region = region_name, season = paste0("month ", rep(dat$lencomp$month, each = n_length)),
  year = rep(length_year, each = n_length),
  sampling_time = rep((as.integer(dat$lencomp$month) - 1) / 12, each = n_length),
  source_reference = paste0("cowcod2019.dat, lencomp row ", length_row),
  transformation = "Preserve native Lbin_method 2 labels as centimetres; store absolute year and retain source sign in notes.",
  notes = paste0("Native frequency vector and Nsamp retained. Lbin_method=2; source fleet code ",
    rep(length_fleet_id, each = n_length), "; negative source year code ",
    rep(length_year_code, each = n_length), " marks a row excluded from the likelihood."),
  observation_id = rep(length_obs, each = n_length),
  length_bin = rep(length_bins, times = nrow(dat$lencomp)),
  sample_size = rep(as.numeric(dat$lencomp$Nsamp), each = n_length))

age_bins <- as.integer(dat$agebin_vector)
n_age <- length(age_bins)
age_cols <- paste0("a", age_bins)
age_mat <- as.matrix(dat$agecomp[, age_cols, drop = FALSE])
age_row <- rep(seq_len(nrow(dat$agecomp)), each = n_age)
age_year_code <- as.integer(dat$agecomp$year)
age_year <- abs(age_year_code)
age_fleet_id <- as.integer(dat$agecomp$fleet)
age_fishery <- fleet_type(age_fleet_id) == 1L
age_survey <- fleet_type(age_fleet_id) == 3L
if (any(!(age_fishery | age_survey))) stop("Unrecognized fleet type in Cowcod conditional age compositions.", call. = FALSE)
age_state <- ifelse(age_year_code < 0L, "excluded", "active")
age_lo <- as.numeric(dat$agecomp$Lbin_lo)
age_hi <- as.numeric(dat$agecomp$Lbin_hi)
age_error <- as.integer(dat$agecomp$ageerr)
if (!all(age_error %in% c(1L, 2L)) || any(age_lo < min(length_bins) | age_hi > max(length_bins) | age_hi < age_lo)) {
  stop("Cowcod conditional age-at-length bins or age-error codes differ from the source review.", call. = FALSE)
}
age_obs <- paste0("COW_AGECOMP_f", age_fleet_id, "_", age_year, "_", age_lo, "_", age_hi,
  "_", age_state, "_r", sprintf("%03d", seq_len(nrow(dat$agecomp))))
age_rows <- frame_input(
  "biology", "conditional_frequency_at_age", "native_frequency", as.vector(t(age_mat)),
  "native frequency units", fleet = ifelse(rep(age_fishery, each = n_age),
    rep(fleet_name(age_fleet_id), each = n_age), ""),
  survey = ifelse(rep(age_survey, each = n_age), rep(fleet_name(age_fleet_id), each = n_age), ""),
  region = region_name, season = paste0("month ", rep(dat$agecomp$month, each = n_age)),
  year = rep(age_year, each = n_age),
  sampling_time = rep((as.integer(dat$agecomp$month) - 1) / 12, each = n_age),
  age = rep(age_bins, times = nrow(dat$agecomp)),
  source_reference = paste0("cowcod2019.dat, agecomp row ", age_row),
  transformation = "Preserve native Lbin_method 3 length bounds as centimetres; store absolute year and retain source sign in notes.",
  notes = paste0("Conditional age-at-length native frequency; age-error code ",
    rep(age_error, each = n_age), "; negative source year code ",
    rep(age_year_code, each = n_age), " marks a row excluded from the likelihood."),
  observation_id = rep(age_obs, each = n_age),
  length_bin_lower = rep(age_lo, each = n_age), length_bin_upper = rep(age_hi, each = n_age),
  sample_size = rep(as.numeric(dat$agecomp$Nsamp), each = n_age),
  age_error = rep(age_error, each = n_age))
inputs_new <- do.call(rbind, list(catch_rows, catch_sd, index_rows, index_sd, length_rows, age_rows))

frame_output <- function(type, measure, year, value, unit, age = NA_integer_, age_group = "",
                         fleet = "", survey = "", sex = "female", region = region_name,
                         season = "annual", se = NA_real_, lwr = NA_real_, upr = NA_real_,
                         source_type = "native_model", source_reference, notes = "", scenario = "") {
  args <- list(type, measure, year, value, unit, age, age_group, fleet, survey, sex,
    region, season, se, lwr, upr, source_type, source_reference, notes, scenario)
  n <- max(lengths(args))
  repn <- function(x) rep_len(x, n)
  data.frame(assessment_id = rep(assessment_id, n), type = repn(type), measure = repn(measure),
    fleet = repn(fleet), survey = repn(survey), sex = repn(sex), region = repn(region),
    season = repn(season), year = as.integer(repn(year)), age = as.numeric(repn(age)),
    age_group = repn(age_group), value = as.numeric(repn(value)), se = as.numeric(repn(se)),
    lwr = as.numeric(repn(lwr)), upr = as.numeric(repn(upr)), unit = repn(unit),
    source_type = repn(source_type), source_reference = repn(source_reference),
    notes = repn(notes), scenario = repn(scenario), stringsAsFactors = FALSE)
}
surface_rows <- function(x, type, measure, unit, reference, notes, fleet_column = NULL) {
  ages_out <- ages
  age_values <- as.matrix(x[, as.character(ages_out), drop = FALSE])
  keep <- is.finite(age_values)
  if (is.null(fleet_column)) {
    fleet <- rep("", nrow(x))
  } else {
    fleet <- fleet_name(x[[fleet_column]])
  }
  frame_output(type, measure,
    rep(as.integer(x$Yr), each = length(ages_out))[as.vector(t(keep))],
    as.vector(t(age_values))[as.vector(t(keep))], unit,
    age = rep(ages_out, times = nrow(x))[as.vector(t(keep))],
    fleet = rep(fleet, each = length(ages_out))[as.vector(t(keep))],
    source_reference = reference, notes = notes)
}

n_surface <- out$natage[out$natage$Era == "TIME" & out$natage[["Beg/Mid"]] == "B" & out$natage$Yr %in% years, , drop = FALSE]
b_surface <- out$batage[out$batage$Era == "TIME" & out$batage[["Beg/Mid"]] == "B" & out$batage$Yr %in% years, , drop = FALSE]
m_surface <- out$M_at_age[out$M_at_age$Yr %in% years, , drop = FALSE]
f_surface <- out$fatage[out$fatage$Era == "TIME" & out$fatage$Yr %in% years, , drop = FALSE]
c_surface <- out$catage[out$catage$Era == "TIME" & out$catage$Type == "dead" & out$catage$Yr %in% years, , drop = FALSE]
if (nrow(n_surface) != length(years) || nrow(b_surface) != length(years) ||
    nrow(m_surface) != length(years) || nrow(f_surface) != length(years) * 2L ||
    nrow(c_surface) != length(years) * 2L ||
    !identical(sort(unique(as.integer(n_surface$Yr))), years)) {
  stop("Report.sso historical Cowcod surface coverage differs from 1900-2018.", call. = FALSE)
}
N_out <- surface_rows(n_surface, "population", "numbers_at_age", "thousand fish",
  "Report.sso, TIME, beginning-year N-at-age", "Fitted female numbers-at-age; age 60 is the terminal age group.")
B_out <- surface_rows(b_surface, "biomass", "biomass_at_age", "metric tonnes",
  "Report.sso, TIME, beginning-year biomass-at-age", "Fitted female biomass-at-age; age 60 is the terminal age group.")
M_out <- surface_rows(m_surface, "mortality", "natural_mortality_at_age", "per year",
  "Report.sso, TIME, M-at-age", "Estimated natural mortality by age. The archive reports no value at age 60.")
F_out <- surface_rows(f_surface, "mortality", "fishing_mortality_at_age", "per year",
  "Report.sso, TIME, fleet-specific F-at-age", "Fitted fleet-specific female F-at-age; fishery fleet identity retained.", "Fleet")
C_out <- surface_rows(c_surface, "catch", "numbers_at_age", "thousand fish",
  "Report.sso, TIME, Type=dead catch-at-age", "Model-generated dead catch-at-age, not an observed catch-at-age input.", "Fleet")

f_total <- do.call(rbind, lapply(years, function(y) {
  z <- f_surface[f_surface$Yr == y, , drop = FALSE]
  if (nrow(z) != 2L) stop("Expected two fishery F surfaces in ", y, call. = FALSE)
  values <- colSums(as.matrix(z[, as.character(ages), drop = FALSE]))
  data.frame(year = y, t(values), check.names = FALSE)
}))
names(f_total) <- c("year", as.character(ages))
F_total <- frame_output("mortality", "fishing_mortality_at_age",
  rep(f_total$year, each = length(ages)), as.vector(t(as.matrix(f_total[, as.character(ages), drop = FALSE]))),
  "per year", age = rep(ages, times = nrow(f_total)), source_type = "derived_source_output",
  source_reference = "Report.sso, TIME, fleet-specific F-at-age",
  notes = "Derived total F-at-age by summing the two reported fishery F surfaces; uncertainty is unavailable.")
history <- out$timeseries[out$timeseries$Era == "TIME" & out$timeseries$Yr %in% years, , drop = FALSE]
if (nrow(history) != length(years)) stop("Expected annual Report.sso output from 1900 through 2018.", call. = FALSE)
total_N <- frame_output("population", "total_numbers", history$Yr,
  rowSums(as.matrix(n_surface[, as.character(ages), drop = FALSE])), "thousand fish",
  age_group = "0-60", source_type = "derived_source_output",
  source_reference = "Report.sso, TIME, beginning-year N-at-age",
  notes = "Derived by summing reported N-at-age over ages 0-60. The modeled sex is female; uncertainty is unavailable.")
total_biomass <- rbind(
  frame_output("biomass", "total_biomass", history$Yr, history$Bio_all, "metric tonnes",
    age_group = "all ages", source_reference = "Report.sso, TIME, Bio_all",
    notes = "Reported biomass over all modeled ages."),
  frame_output("biomass", "total_biomass", history$Yr, history$Bio_smry, "metric tonnes",
    age_group = "10+", source_reference = "Report.sso, TIME, Bio_smry",
    notes = "Reported summary biomass for ages 10 and older.")
)
spawn_line <- unlist(strsplit(pdf_pages[grepl("Spawning Output in 2019", pdf_pages, fixed = TRUE)][1L], "\n", fixed = TRUE))
spawn_line <- spawn_line[grepl("Spawning Output in 2019", spawn_line, fixed = TRUE)][1L]
if (is.na(spawn_line) || !grepl("163.*130.*195", spawn_line)) {
  stop("The 2019 report's spawning-output point estimate/interval differs from the reviewed table.", call. = FALSE)
}
spawn_native <- history$SpawnBio
spawn_report_scale <- spawn_native / 2
spawn <- rbind(
  frame_output("biology", "spawning_output", history$Yr, spawn_report_scale, "billion eggs",
    source_type = "derived_source_output", source_reference = "Report.sso, TIME, SpawnBio; assessment report Table E",
    notes = "Report-scale spawning output. The single-sex SS3 SpawnBio is divided by two, as documented for the official report, which plots twice the actual single-sex value."),
  frame_output("biology", "spawning_output", 2019L, 163, "billion eggs", lwr = 130, upr = 195,
    source_type = "official_table", source_reference = "Assessment report, Table E, p. viii (PDF p. 11)",
    notes = "Beginning-of-2019 spawning output; 95% asymptotic interval. The point estimate agrees with half of the Report.sso 2019 derived quantity after printed rounding.",
    scenario = "beginning of 2019")
)
recruitment <- frame_output("recruitment", "recruitment", history$Yr, history$Recruit_0,
  "thousand fish", source_reference = "Report.sso, TIME, Recruit_0",
  notes = "Age-0 recruitment in thousands of fish for the single modeled female population.")
M_parameter <- frame_output("parameter", "natural_mortality_average_parameter", NA_integer_, 0.088,
  "per year", sex = "female", season = "", se = 0.011, source_type = "official_table",
  source_reference = "Assessment report, Table 50, p. 78 (PDF p. 95)",
  notes = "Estimated female natural-mortality parameter; table reports SE 0.011. This is a scalar parameter, not an independent age-specific estimate.")
outputs_new <- do.call(rbind, list(N_out, B_out, M_out, F_out, C_out, F_total, total_N,
  total_biomass, spawn, recruitment, M_parameter))

observation_weights <- data.frame(
  setting = c(rep("length_relative_weight", 5L), rep("conditional_age_at_length_relative_weight", 5L)),
  fleet = c("REC_FISHERY", "NWFSC_TWL", "SANITATION", "NWFSC_HKL", "NWFSC_HKL_EARLY_COMPS",
    "COM_FISHERY", "REC_FISHERY", "NWFSC_TWL", "NWFSC_HKL", "NWFSC_HKL_EARLY_COMPS"),
  survey = c("", "NWFSC_TWL", "SANITATION", "NWFSC_HKL", "NWFSC_HKL_EARLY_COMPS",
    "", "", "NWFSC_TWL", "NWFSC_HKL", "NWFSC_HKL_EARLY_COMPS"),
  value = c("0.399", "0.217", "0.120", "1.000", "0.404", "0.490", "0.391", "0.510", "0.315", "0.227"),
  stringsAsFactors = FALSE)
assumption <- function(component, setting, value, source_reference, notes = "", fleet = "", survey = "",
                       sex = "", region = "", season = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet, survey = survey,
    sex = sex, region = region, season = season, setting = setting, value = value,
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE)
}
weights_assumptions <- do.call(rbind, lapply(seq_len(nrow(observation_weights)), function(i) {
  assumption("composition", observation_weights$setting[i], observation_weights$value[i],
    "Assessment report, Table 49, p. 77 (PDF p. 94)",
    "Relative Francis composition likelihood weight, preserved as reported.",
    fleet = observation_weights$fleet[i], survey = observation_weights$survey[i])
}))
assumptions_new <- rbind(
  assumption("population", "dimensions", "One area and one modeled female sex; ages 0-60; fitted years 1900-2018.",
    "cowcod2019.dat; Report.sso", "Age 60 is the terminal age group; do not infer a second sex surface."),
  assumption("model", "software", "Stock Synthesis 3.30.13.09.", "cowcod2019.ctl; assessment report"),
  assumption("catch", "likelihood", "Annual commercial and recreational catch biomass in metric tonnes; one -999 placeholder is not a calendar-year observation.",
    "cowcod2019.dat, catch block"),
  assumption("index", "series", "Six distinct survey fleets; report describes four relative-abundance series plus absolute visual-survey biomass estimates from 2002 and 2012.",
    "cowcod2019.dat, CPUE and CPUEinfo blocks; Stock Synthesis User Manual 3.30.15, Index Units; assessment report sections 2.1.2 and 2.2.5"),
  assumption("index", "timing", "Survey observations occur in January or July; within-year timing is 0 or 0.5, respectively.",
    "cowcod2019.dat, CPUE block; Report.sso, cpue table"),
  assumption("biology", "composition_inputs", "Length frequencies and conditional age-at-length frequencies are retained on their native scales; negative-year rows are excluded by the official model.",
    "cowcod2019.dat, lencomp and agecomp blocks"),
  assumption("biology", "growth", "Von Bertalanffy growth is estimated; the report gives length-at-age and growth-rate estimates in Table 50.",
    "Assessment report, sections 2.1.3 and 2.2.5; Table 50"),
  assumption("biology", "maturity_and_fecundity", "The model uses a functional length-based maturity relationship and length-based fecundity to calculate egg-production spawning output.",
    "Assessment report, sections 2.1.3 and 2.2.5; cowcod2019.ctl"),
  assumption("mortality", "natural_mortality", "Female M is estimated; the report gives M=0.088 per year with SE=0.011 and a lognormal prior with log mean -2.321 and SD 0.438.",
    "Assessment report, Table 50, p. 78 (PDF p. 95)"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt stock-recruitment relationship; steepness is fixed at 0.72; R0 is estimated.",
    "Assessment report, Table 50, p. 78 (PDF p. 95); cowcod2019.ctl"),
  assumption("output", "spawning_output_scale", "SS3 Report.sso SpawnBio is divided by two to match the report's single-sex output convention; the 2019 value matches Table E after rounding.",
    "Report.sso; assessment report, Figure 99 and Table E"),
  assumption("uncertainty", "reported_uncertainty", "The archive has no parameter/covariance file. The report supplies a 95% asymptotic interval for 2019 spawning output; age-specific surface uncertainty was not recovered.",
    "Cowcod 2019 model archive; assessment report, Table E"),
  weights_assumptions
)

input_key_cols <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex", "region",
  "season", "year", "year_basis", "age", "observation_id", "length_bin", "length_bin_lower",
  "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin")
output_key_cols <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season",
  "year", "age", "age_group", "scenario")
key <- function(x, cols) do.call(paste, c(lapply(x[cols], function(z) {
  z <- as.character(z)
  z[is.na(z)] <- ""
  z
}), sep = "\r"))
if (anyDuplicated(key(inputs_new, input_key_cols)) || anyDuplicated(key(outputs_new, output_key_cols))) {
  stop("New Cowcod records contain duplicate canonical keys.", call. = FALSE)
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidate <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
ci <- match(candidate_id, candidate$candidate_id)
if (is.na(ci) || candidate$screening_status[ci] != "screened" || candidate$eligibility[ci] != "eligible" ||
    !candidate$match_status[ci] %in% c("new", "matched") ||
    (!is.na(candidate$matched_stock_id[ci]) && candidate$matched_stock_id[ci] != stock_id)) {
  stop("NOAA Cowcod candidate status differs from the reviewed unit.", call. = FALSE)
}
candidate$match_status[ci] <- "matched"
candidate$matched_stock_id[ci] <- stock_id
candidate$import_status[ci] <- "partial"
candidate$notes[ci] <- paste("Official 2019 Cowcod assessment imported from the native Stock Synthesis archive and report.",
  "Inputs preserve catch totals, six survey series, length compositions, conditional age-at-length compositions, and the report's likelihood weights.",
  "Outputs preserve fitted age surfaces, spawning output on the report scale, and recruitment; direct catch-at-age and age-specific index inputs are not supplied.",
  "See source_reviews/noaa_cowcod_southern_california_2019.md for coverage and limits.")

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

cat("NOAA Cowcod 2019 import: ", nrow(inputs_new), " inputs; ", nrow(outputs_new), " outputs.\n",
  "Catch ", min(catch_year), "-", max(catch_year), "; surveys ", min(index_year), "-", max(index_year),
  "; length compositions ", sum(dat$lencomp$year > 0L), " active / ", sum(dat$lencomp$year < 0L),
  " excluded; conditional age-at-length ", sum(dat$agecomp$year > 0L), " active / ",
  sum(dat$agecomp$year < 0L), " excluded.\n", sep = "")
if (!write_mode) {
  cat("Dry run only; add --write to append the records and reconcile the candidate unit.\n")
  quit(save = "no", status = 0L)
}

stock_row <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NOAA-SWFSC",
  authority_stock_id = "10443", scientific_name = "Sebastes levis", common_name = "Cowcod",
  area = "Southern California Bight, south of Point Conception", region = "U.S. West Coast",
  ocean = "Northeast Pacific", notes = "NOAA Stock SMART assessment unit 10443; distinct southern California Bight stock unit.",
  stringsAsFactors = FALSE)
assessment_row <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2019L, terminal_year = 2018L, estimate_terminal_year = 2019L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis", model_version = "3.30.13.09",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.pcouncil.org/documents/2019/10/status-of-cowcod-sebastes-levis-in-2019-october-24-2019.pdf",
  framework_url = "", data_url = "https://www.pcouncil.org/documents/cowcod-2019-ss-model-files-zip-file/",
  model_url = "https://www.pcouncil.org/documents/cowcod-2019-ss-model-files-zip-file/",
  repository_url = "", assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2019 full assessment fitted through 2018 with a 2019 estimate. The native archive provides no covariance file; age-specific uncertainty was not recovered. Report.sso SpawnBio is divided by two to match the official report scale.",
  stringsAsFactors = FALSE)

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
unlink(tmp_candidate)
writeLines(candidate_lines, candidate_path, useBytes = TRUE)
source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"), local = TRUE)
source(file.path(root, "scripts", "database", "002_validate_database.R"), local = TRUE)
cat("Import written and database validation passed.\n")
