root <- "."
stock_id <- "noaa_california_scorpionfish_southern_california"
assessment_id <- "noaa_california_scorpionfish_southern_california_2017"
candidate_id <- "NOAA:10461"
cache <- file.path(root, "source_cache", "discovery_noaa_california_scorpionfish_2017")
manifest_path <- file.path(root, "provenance", "noaa_california_scorpionfish_southern_california_2017", "manifest.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("r4ss", quietly = TRUE)) {
  stop("Install r4ss to parse the cached California scorpionfish assessment.", call. = FALSE)
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
model_zip <- verify_source("california_scorpionfish_2017_model_files.zip")
invisible(verify_source("california_scorpionfish_2017_assessment.pdf"))
invisible(verify_source("pacific_coast_groundfish_safe_july_2025.pdf"))
work <- tempfile("scorpionfish_2017_")
dir.create(work)
on.exit(unlink(work, recursive = TRUE), add = TRUE)
unzip(model_zip, exdir = work)
dat_path <- list.files(work, "^scor1\\.dat$", recursive = TRUE, full.names = TRUE)
if (length(dat_path) != 1L) stop("Expected one scor1.dat in the archive.", call. = FALSE)
model_dir <- dirname(dat_path)
for (file in c("scor1.ctl", "Report.sso")) {
  if (!file.exists(file.path(model_dir, file))) stop("Official model archive lacks ", file, call. = FALSE)
}

dat <- r4ss::SS_readdat(dat_path, verbose = FALSE)
out <- r4ss::SS_output(model_dir, printstats = FALSE, verbose = FALSE)
years <- 1916:2016
ages <- 0:21
mortality_ages <- 0:20
region_name <- "Southern California"
if (dat$styr != 1916L || dat$endyr != 2016L || dat$nseas != 1L ||
    dat$Nsexes != 2L || dat$Nages != 21L || dat$N_areas != 1L ||
    dat$lbin_method != 1L || dat$Lbin_method != 3L ||
    !identical(as.integer(dat$agebin_vector), ages) ||
    nrow(dat$fleetinfo) != 12L || nrow(dat$catch) != 627L ||
    sum(dat$catch$year != -999L) != 620L || nrow(dat$CPUE) != 160L ||
    nrow(dat$lencomp) != 233L || nrow(dat$agecomp) != 198L ||
    sum(dat$lencomp$sex == 0L) != 219L || sum(dat$lencomp$sex == 3L) != 14L ||
    !identical(as.integer(dat$lbin_vector), 1:45) ||
    !identical(as.integer(dat$agebin_vector), ages) ||
    !all(dat$agecomp$sex == 3L) || !all(dat$agecomp$ageerr == 1L)) {
  stop("Archived scorpionfish input dimensions differ from the reviewed 2017 assessment.", call. = FALSE)
}
if (!setequal(unique(dat$CPUEinfo$units), c(0L, 1L)) ||
    !all(dat$CPUE$month == 7L) || !all(dat$CPUE$se_log > 0) ||
    !setequal(unique(dat$lencomp$part), c(0L, 2L)) ||
    !all(dat$agecomp$part == 0L) ||
    !all(abs(rowSums(dat$agecomp[paste0("f", ages)]) +
      rowSums(dat$agecomp[paste0("m", ages)]) - dat$agecomp$Nsamp) < 1e-8)) {
  stop("Scorpionfish index or composition coding differs from the source review.", call. = FALSE)
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
sex_name <- function(code) {
  code <- as.integer(code)
  ifelse(code == 1L, "female", ifelse(code == 2L, "male", "combined"))
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
catch_year_code <- as.integer(dat$catch$year[catch_keep])
catch_year <- abs(catch_year_code)
catch_id <- as.integer(dat$catch$fleet[catch_keep])
catch_fleet <- fleet_name(catch_id)
catch_obs <- paste0("SCOR_CATCH_F", catch_id, "_", catch_year)
catch_rows <- frame_input("catch", "catch_biomass", "biomass", dat$catch$catch[catch_keep],
  "metric tonnes", fleet = catch_fleet, region = region_name, season = "annual", year = catch_year,
  source_reference = "scor1.dat, catch block",
  transformation = "Store the absolute calendar year; omit only the -999 sentinel rows.",
  notes = paste0("Native annual catch biomass; source year code ", catch_year_code,
    ". Catch is in metric tonnes, cross-checked against the report's rounded 2016 landings."),
  observation_id = catch_obs)
catch_sd <- frame_input("catch", "log_catch_sd", "log_scale", dat$catch$catch_se[catch_keep],
  "log-scale SD", fleet = catch_fleet, region = region_name, season = "annual", year = catch_year,
  source_reference = "scor1.dat, catch block, catch_se",
  notes = "Native catch_se retained on the source log-error scale.", observation_id = catch_obs)

index_id <- as.integer(dat$CPUE$index)
index_year_code <- as.integer(dat$CPUE$year)
index_year <- abs(index_year_code)
index_month <- as.integer(dat$CPUE$month)
index_name <- fleet_name(index_id)
index_type_code <- fleet_type(index_id)
index_unit_code <- as.integer(dat$CPUEinfo$units[match(index_id, dat$CPUEinfo$fleet)])
if (anyNA(index_unit_code) || any(!index_type_code %in% c(1L, 3L))) {
  stop("Unexpected scorpionfish index unit or fleet type.", call. = FALSE)
}
index_obs <- paste0("SCOR_INDEX_F", index_id, "_", index_year, "_m", index_month)
index_measure <- ifelse(index_unit_code == 1L, "relative_biomass_index", "relative_abundance_index")
index_basis <- ifelse(index_unit_code == 1L, "biomass", "numbers")
index_unit <- ifelse(index_unit_code == 1L,
  "native biomass-index units; physical scale not stated",
  "native numbers-index units; physical scale not stated")
index_notes <- paste0("Native index from fleet ", index_id, " (", index_name,
  "); Stock Synthesis unit code ", index_unit_code,
  ifelse(index_unit_code == 1L, " denotes biomass", " denotes numbers"),
  ". No additional physical scale is stated in the data file. Source year code ", index_year_code,
  ifelse(index_year_code < 0L, " marks an observation excluded from the likelihood.", "."))
index_rows <- frame_input("index", index_measure, index_basis, dat$CPUE$obs, index_unit,
  fleet = ifelse(index_type_code == 1L, index_name, ""),
  survey = ifelse(index_type_code == 3L, index_name, ""), region = region_name,
  season = paste0("month ", index_month), year = index_year,
  sampling_time = (index_month - 1) / 12,
  source_reference = "scor1.dat, CPUE and CPUEinfo blocks",
  notes = index_notes, observation_id = index_obs)
index_sd <- frame_input("index", "log_index_sd", "log_scale", dat$CPUE$se_log,
  "log-scale SD", fleet = ifelse(index_type_code == 1L, index_name, ""),
  survey = ifelse(index_type_code == 3L, index_name, ""), region = region_name,
  season = paste0("month ", index_month), year = index_year,
  sampling_time = (index_month - 1) / 12,
  source_reference = "scor1.dat, CPUE block, se_log",
  notes = "Native standard deviation on the log scale; month 7 maps to within-year time 0.5.",
  observation_id = index_obs)

length_bins <- as.numeric(dat$lbin_vector)
length_cols_f <- paste0("f", seq_along(length_bins))
length_cols_m <- paste0("m", seq_along(length_bins))
length_rows <- do.call(rbind, lapply(seq_len(nrow(dat$lencomp)), function(i) {
  x <- dat$lencomp[i, , drop = FALSE]
  fleet_id <- as.integer(x$fleet)
  ftype <- fleet_type(fleet_id)
  code <- as.integer(x$sex)
  if (!code %in% c(0L, 3L) || !ftype %in% c(1L, 3L)) {
    stop("Unexpected fleet or sex code in scorpionfish length compositions.", call. = FALSE)
  }
  if (code == 0L) {
    sexes <- "combined"
    values <- matrix(as.numeric(x[1L, length_cols_f]), nrow = 1L)
    scale_note <- "Sex code 0: combined-sex frequencies are stored in the female vector; the male vector is ignored by Stock Synthesis."
  } else {
    sexes <- c("female", "male")
    values <- rbind(as.numeric(x[1L, length_cols_f]), as.numeric(x[1L, length_cols_m]))
    scale_note <- "Sex code 3: female and male vectors form the source joint sex-by-length composition; source values are retained as supplied."
  }
  year_code <- as.integer(x$year)
  row_id <- paste0("SCOR_LEN_F", fleet_id, "_", abs(year_code), "_p", x$part,
    "_r", sprintf("%03d", i))
  observation_id <- if (code == 0L) row_id else paste0(row_id, "_", c("F", "M"))
  type <- if (ftype == 1L) "catch" else "index"
  frame_input(type, "frequency_at_length", "native_frequency", as.vector(t(values)),
    "source frequency", fleet = if (ftype == 1L) fleet_name(fleet_id) else "",
    survey = if (ftype == 3L) fleet_name(fleet_id) else "", sex = rep(sexes, each = length(length_bins)),
    region = region_name, season = paste0("month ", x$month), year = abs(year_code),
    sampling_time = (as.integer(x$month) - 1) / 12,
    source_reference = paste0("scor1.dat, lencomp row ", i),
    transformation = "No normalization. Native length-bin labels are the supplied lower edges in centimetres.",
    notes = paste0(scale_note, " Nsamp=", x$Nsamp,
      " is retained exactly as the source likelihood sample-size input. Partition code ", x$part,
      " (0=combined, 2=retained). Source year code ", year_code,
      ifelse(year_code < 0L, " marks an observation excluded from the likelihood.", ".")),
    observation_id = rep(observation_id, each = length(length_bins)),
    length_bin = rep(length_bins, times = length(sexes)),
    sample_size = rep(as.numeric(x$Nsamp), length(values)))
}))

age_cols_f <- paste0("f", ages)
age_cols_m <- paste0("m", ages)
age_rows <- do.call(rbind, lapply(seq_len(nrow(dat$agecomp)), function(i) {
  x <- dat$agecomp[i, , drop = FALSE]
  fleet_id <- as.integer(x$fleet)
  if (fleet_type(fleet_id) != 3L || as.integer(x$sex) != 3L) {
    stop("Unexpected fleet or sex code in scorpionfish conditional age-at-length data.", call. = FALSE)
  }
  values <- rbind(as.numeric(x[1L, age_cols_f]), as.numeric(x[1L, age_cols_m]))
  year_code <- as.integer(x$year)
  row_id <- paste0("SCOR_CAAL_F", fleet_id, "_", abs(year_code), "_L",
    x$Lbin_lo, "-", x$Lbin_hi, "_r", sprintf("%03d", i))
  observation_id <- paste0(row_id, "_", c("F", "M"))
  frame_input("biology", "conditional_frequency_at_age", "native_frequency",
    as.vector(t(values)), "fish", survey = fleet_name(fleet_id), region = region_name,
    season = paste0("month ", x$month), year = abs(year_code),
    sampling_time = (as.integer(x$month) - 1) / 12,
    age = rep(ages, times = 2L), source_reference = paste0("scor1.dat, agecomp row ", i),
    transformation = "Raw female and male age counts are separated into sex-specific rows; no proportions or age-length-key reconstruction is applied.",
    notes = paste0("Native conditional age-at-length record, source sex code 3 (joint sexes); source Nsamp=",
      x$Nsamp, " is the combined sample-size field. Partition code ", x$part,
      ". Source year code ", year_code, ". Age-error definition code ", x$ageerr, "."),
    observation_id = rep(observation_id, each = length(ages)),
    length_bin_lower = rep(as.numeric(x$Lbin_lo), length(values)),
    length_bin_upper = rep(as.numeric(x$Lbin_hi), length(values)),
    sample_size = rep(as.numeric(x$Nsamp), length(values)),
    age_error = rep(as.integer(x$ageerr), length(values)),
    sex = rep(rep(c("female", "male"), each = length(ages)), 1L),
    partition = as.character(x$part))
}))
inputs_new <- do.call(rbind, list(catch_rows, catch_sd, index_rows, index_sd, length_rows, age_rows))

frame_output <- function(type, measure, year, value, unit, age = NA_integer_, age_group = "",
                         fleet = "", survey = "", sex = "combined", region = region_name,
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
  values <- as.matrix(x[, as.character(ages), drop = FALSE])
  keep <- is.finite(values)
  years_out <- rep(as.integer(x$Yr), each = length(ages))
  ages_out <- rep(ages, times = nrow(x))
  sexes_out <- rep(sex_name(x$Sex), each = length(ages))
  fleet <- if (is.null(fleet_column)) rep("", nrow(x)) else fleet_name(x[[fleet_column]])
  frame_output(type, measure,
    years_out[as.vector(t(keep))], as.vector(t(values))[as.vector(t(keep))], unit,
    age = ages_out[as.vector(t(keep))],
    fleet = rep(fleet, each = length(ages))[as.vector(t(keep))],
    sex = sexes_out[as.vector(t(keep))], source_reference = reference, notes = notes)
}

time_series <- out$timeseries[out$timeseries$Era == "TIME" & out$timeseries$Yr %in% years, , drop = FALSE]
n_surface <- out$natage_annual_2_with_fishery[
  out$natage_annual_2_with_fishery$Yr %in% years, , drop = FALSE]
z_surface <- out$Z_at_age[out$Z_at_age$Yr %in% years, , drop = FALSE]
m_surface <- out$M_at_age[out$M_at_age$Yr %in% years, , drop = FALSE]
c_surface <- out$catage[out$catage$Era == "TIME" & out$catage$Yr %in% years, , drop = FALSE]
sort_surface <- function(x) x[order(x$Yr, x$Sex), , drop = FALSE]
n_surface <- sort_surface(n_surface)
z_surface <- sort_surface(z_surface)
m_surface <- sort_surface(m_surface)
if (nrow(time_series) != length(years) || nrow(n_surface) != length(years) * 2L ||
    nrow(z_surface) != length(years) * 2L || nrow(m_surface) != length(years) * 2L ||
    nrow(c_surface) != length(years) * 2L * 6L ||
    !identical(as.integer(n_surface$Yr), rep(years, each = 2L)) ||
    !identical(as.integer(z_surface$Yr), rep(years, each = 2L)) ||
    !identical(as.integer(m_surface$Yr), rep(years, each = 2L)) ||
    !all(abs(as.matrix(m_surface[, as.character(mortality_ages), drop = FALSE]) - 0.235) < 1e-8)) {
  stop("Scorpionfish historical Report.sso surfaces differ from the reviewed coverage or fixed-M base model.", call. = FALSE)
}

N_out <- surface_rows(n_surface, "population", "numbers_at_age", "thousand fish",
  "Report.sso, natage_annual_2_with_fishery",
  "Fitted model numbers-at-age, by sex; age 21 is the terminal plus group. No uncertainty is supplied.")
Z_out <- surface_rows(z_surface, "mortality", "total_mortality_at_age", "per year",
  "Report.sso, Z_at_age", "Fitted total mortality at age. Age 21 is not reported in this table.")
M_out <- surface_rows(m_surface, "mortality", "natural_mortality_at_age", "per year",
  "Report.sso, M_at_age", "Base-model M is fixed at 0.235 per year; age 21 is not reported in this table.")
f_surface <- z_surface
f_surface[, as.character(ages)] <- as.matrix(z_surface[, as.character(ages), drop = FALSE]) -
  as.matrix(m_surface[, as.character(ages), drop = FALSE])
F_out <- surface_rows(f_surface, "mortality", "fishing_mortality_at_age", "per year",
  "Derived from Report.sso, Z_at_age minus M_at_age",
  "Derived total F-at-age as Z minus source-reported M for matching year, sex, and age; no uncertainty is available.")
C_out <- surface_rows(c_surface, "catch", "numbers_at_age", "thousand fish",
  "Report.sso, catage, historical TIME rows",
  "Model-generated catch numbers-at-age by fleet and sex; this is an output, not an observed catch-at-age input.",
  fleet_column = "Fleet")

history <- time_series[order(time_series$Yr), , drop = FALSE]
total_N <- aggregate(value ~ year, N_out, sum)
total_N_out <- frame_output("population", "total_numbers", total_N$year, total_N$value,
  "thousand fish", age_group = "0-21", source_type = "derived_source_output",
  source_reference = "Derived from Report.sso, natage_annual_2_with_fishery",
  notes = "Derived by summing model-reported N-at-age over both sexes and ages 0-21; uncertainty is unavailable.")
ssb_out <- frame_output("biomass", "SSB", history$Yr, history$SpawnBio, "metric tonnes",
  source_reference = "Report.sso, TIME, SpawnBio",
  notes = "Model-reported spawning biomass; uncertainty is not present in the cached run outputs.")
biomass_out <- frame_output("biomass", "total_biomass", history$Yr, history$Bio_all, "metric tonnes",
  source_reference = "Report.sso, TIME, Bio_all",
  notes = "Model-reported total biomass over modeled ages; uncertainty is not present in the cached run outputs.")
recruitment_out <- frame_output("recruitment", "recruitment", history$Yr, history$Recruit_0,
  "thousand fish", source_reference = "Report.sso, TIME, Recruit_0",
  notes = "Model-reported age-0 recruitment; uncertainty is not present in the cached run outputs.")
outputs_new <- do.call(rbind, list(N_out, Z_out, M_out, F_out, C_out,
  total_N_out, ssb_out, biomass_out, recruitment_out))

assumption <- function(component, setting, value, source_reference, notes = "", fleet = "", survey = "",
                       sex = "", region = "", season = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet, survey = survey,
    sex = sex, region = region, season = season, setting = setting, value = value,
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE)
}
assumptions_new <- rbind(
  assumption("population", "dimensions", "One area, two sexes, ages 0-21, modeled years 1916-2016.",
    "scor1.dat; Report.sso", "Age 21 is the terminal plus group."),
  assumption("model", "software", "Stock Synthesis 3.30.05.03.",
    "scor1.ctl; official model archive"),
  assumption("catch", "fleets_and_units", paste(fleet_name(1:6), collapse = "; "),
    "scor1.dat, fleetinfo and catch blocks", "Six commercial/recreational fleets; native annual catch biomass is in metric tonnes."),
  assumption("index", "series_and_units", "160 observations across eight fleets; Stock Synthesis units code 0=numbers and code 1=biomass.",
    "scor1.dat, CPUE and CPUEinfo blocks", "Physical index units are not stated in the data file; source values and index SDs are retained without rescaling."),
  assumption("index", "timing", "All index observations occur in July, within-year timing 0.5.",
    "scor1.dat, CPUE block"),
  assumption("composition", "length_data", "233 native length-composition rows from six fleets, 1970-2016; source sex codes 0 and 3 and partitions 0 and 2 are retained.",
    "scor1.dat, lencomp block", "29 negative-year rows are retained with absolute calendar year and marked as excluded from the likelihood. Source Nsamp values, including fractional values, are preserved."),
  assumption("composition", "conditional_age_at_length", "198 NWFSC bottom-trawl records, 2005-2016; ages 0-21 and source length bounds 14-39.",
    "scor1.dat, agecomp block", "Source sex code 3 is retained as separate female/male raw count vectors; source Nsamp, partition, and age-error code 1 are preserved."),
  assumption("biology", "growth_and_weight", "Sex-specific von Bertalanffy growth and length-weight relationships are specified in the base model.",
    "scor1.ctl; assessment report", "Age-specific weight inputs are generated by the model; no independent age-weight table was supplied."),
  assumption("biology", "maturity", "Maturity is specified as a length-based logistic relationship.",
    "scor1.ctl; assessment report", "No independent maturity-at-age input vector was supplied."),
  assumption("mortality", "natural_mortality_base", "0.235 per year, fixed for both sexes in the base model.",
    "scor1.ctl; Report.sso, M_at_age"),
  assumption("mortality", "low_M_sensitivity", "0.164 per year.",
    "2017 assessment report", "Alternative low-M state of nature; not part of the imported base-case input."),
  assumption("uncertainty", "available", "No covariance or uncertainty file was included in the cached model archive.",
    "2017 model archive", "No standard errors or confidence intervals are assigned to the imported time series or age surfaces."),
  assumption("source", "latest_assessment", "2017 full assessment using data through 2016; July 2025 SAFE continues to report the stock from this assessment.",
    "2017 assessment report; Pacific Coast Groundfish SAFE, July 2025")
)

stock_row <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NOAA-SWFSC",
  authority_stock_id = "10461", scientific_name = "Scorpaena guttata",
  common_name = "California scorpionfish - Southern California",
  area = "Southern California, Point Conception to the U.S.-Mexico border",
  region = region_name, ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10461 assessment unit; south of Point Conception. The 2017 benchmark remains the latest full assessment located in the July 2025 SAFE.",
  stringsAsFactors = FALSE)
assessment_row <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2017L, terminal_year = 2016L, estimate_terminal_year = 2016L,
  assessment_type = "full", model_family = "Stock Synthesis", model_version = "3.30.05.03",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.pcouncil.org/documents/2017/01/status-of-california-scorpionfish-scorpaena-guttata-off-southern-california-in-2017.pdf",
  framework_url = "", data_url = "https://www.pcouncil.org/documents/2017-california-scorpionfish-model-files-zip-file/",
  model_url = "https://www.pcouncil.org/documents/2017-california-scorpionfish-model-files-zip-file/",
  repository_url = "", assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2017 full assessment fitted through 2016. The native archive provides catch, aggregate indices, length compositions, conditional age-at-length data, and fitted age surfaces. Direct fishery catch-at-age and unconditional age-specific indices were not supplied; age surfaces are model outputs. No covariance file or surface uncertainty was recovered.",
  stringsAsFactors = FALSE)

input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex", "region",
  "season", "year", "year_basis", "age", "observation_id", "length_bin", "length_bin_lower",
  "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season",
  "year", "age", "age_group", "scenario")
row_key <- function(x, columns) do.call(paste, c(lapply(x[columns], function(z) {
  z <- as.character(z); z[is.na(z)] <- ""; z
}), sep = "\r"))
if (nrow(inputs_new) != 21387L || nrow(outputs_new) != 44238L ||
    nrow(assumptions_new) != 13L || anyDuplicated(row_key(inputs_new, input_key)) ||
    anyDuplicated(row_key(outputs_new, output_key)) ||
    sum(inputs_new$measure == "catch_biomass") != 620L ||
    sum(inputs_new$measure == "log_catch_sd") != 620L ||
    sum(inputs_new$measure == "relative_abundance_index") != 141L ||
    sum(inputs_new$measure == "relative_biomass_index") != 19L ||
    sum(inputs_new$measure == "log_index_sd") != 160L ||
    sum(inputs_new$measure == "frequency_at_length") != 11115L ||
    sum(inputs_new$measure == "conditional_frequency_at_age") != 8712L ||
    nrow(N_out) != 4444L || nrow(Z_out) != 4242L || nrow(M_out) != 4242L ||
    nrow(F_out) != 4242L || nrow(C_out) != 26664L) {
  stop("Scorpionfish import has unexpected row counts or duplicate dimensions.", call. = FALSE)
}

row_signature <- function(data) {
  values <- lapply(data, function(x) {
    if (is.numeric(x)) {
      out <- format(x, scientific = FALSE, trim = TRUE, digits = 15)
      out[is.na(x)] <- ""
    } else {
      out <- as.character(x)
      out[is.na(x)] <- ""
    }
    out
  })
  do.call(paste, c(values, sep = "\r"))
}
read_matching_rows <- function(path, id) {
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to check existing assessment rows.", call. = FALSE)
  found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading", "--no-line-number",
    "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(found, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not scan ", path, call. = FALSE)
  found <- found[startsWith(found, paste0('"', id, '",'))]
  if (!length(found)) return(data.frame())
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, found), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
}
assert_rows_match_or_absent <- function(existing, expected, label) {
  if (!nrow(existing)) return(invisible(FALSE))
  if (nrow(existing) != nrow(expected) ||
      !setequal(row_signature(existing), row_signature(expected))) {
    stop("Existing scorpionfish ", label, " rows differ from the verified source tables.", call. = FALSE)
  }
  invisible(TRUE)
}

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stock_existing <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment_existing <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions_existing <- read_matching_rows(assumptions_path, assessment_id)
inputs_existing <- read_matching_rows(inputs_path, assessment_id)
outputs_existing <- read_matching_rows(outputs_path, assessment_id)
if (nrow(stock_existing) > 1L || nrow(assessment_existing) > 1L ||
    (nrow(stock_existing) && !setequal(row_signature(stock_existing), row_signature(stock_row))) ||
    (nrow(assessment_existing) && !setequal(row_signature(assessment_existing), row_signature(assessment_row)))) {
  stop("Existing scorpionfish stock or assessment differs from the verified unit.", call. = FALSE)
}
assert_rows_match_or_absent(assumptions_existing, assumptions_new, "assumption")
assert_rows_match_or_absent(inputs_existing, inputs_new, "input")
assert_rows_match_or_absent(outputs_existing, outputs_new, "output")

cat("Verified NOAA California scorpionfish 2017 source import.\n")
cat("Inputs:", nrow(inputs_new), "rows; 620 annual catch records, 160 index observations, 233 native length-composition rows, and 198 conditional age-at-length samples.\n")
cat("Outputs:", nrow(outputs_new), "rows; historical SSB, recruitment, biomass, N/Z/M/F-at-age, total abundance, and model-generated catch-at-age for 1916-2016.\n")
cat("Direct fishery catch-at-age and unconditional age-specific survey indices were not supplied; no reconstruction was imported.\n")
if (!write_mode) {
  cat("Dry run only. Add --write to append the reviewed records and update the candidate register.\n")
} else {
  append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double", eol = "\n")
  expected_columns <- list(
    stocks = names(read.csv(stocks_path, nrows = 0L, check.names = FALSE)),
    assessments = names(read.csv(assessments_path, nrows = 0L, check.names = FALSE)),
    assumptions = names(read.csv(assumptions_path, nrows = 0L, check.names = FALSE)),
    inputs = names(read.csv(inputs_path, nrows = 0L, check.names = FALSE)),
    outputs = names(read.csv(outputs_path, nrows = 0L, check.names = FALSE)))
  row_sets <- list(stocks = stock_row, assessments = assessment_row,
    assumptions = assumptions_new, inputs = inputs_new, outputs = outputs_new)
  if (!all(vapply(names(row_sets), function(name)
      identical(names(row_sets[[name]]), expected_columns[[name]]), logical(1L)))) {
    stop("An import table does not match the canonical database column order.", call. = FALSE)
  }
  if (!nrow(stock_existing)) append_csv(stock_row, stocks_path)
  if (!nrow(assessment_existing)) append_csv(assessment_row, assessments_path)
  if (!nrow(assumptions_existing)) append_csv(assumptions_new, assumptions_path)
  if (!nrow(inputs_existing)) append_csv(inputs_new, inputs_path)
  if (!nrow(outputs_existing)) append_csv(outputs_new, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"), local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- match(candidate_id, candidates$candidate_id)
  if (is.na(ci) || candidates$screening_status[ci] != "screened" ||
      candidates$eligibility[ci] != "eligible" ||
      !candidates$match_status[ci] %in% c("new", "matched") ||
      (!is.na(candidates$matched_stock_id[ci]) && candidates$matched_stock_id[ci] != stock_id)) {
    stop("NOAA:10461 candidate status differs from the reviewed stock unit.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$detailed_source_url[ci] <- paste(assessment_row$assessment_url,
    assessment_row$model_url, "https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/",
    sep = "; ")
  candidates$review_date[ci] <- "2026-11-11"
  candidates$catch_age_evidence[ci] <- paste(
    "Imported all 620 native annual catch-biomass rows and 233 native length-composition records.",
    "No observed fishery catch-at-age is supplied. Report.sso model-generated catch-at-age is retained only as an output; no age-length-key reconstruction was added.")
  candidates$survey_age_evidence[ci] <- paste(
    "Imported 160 source index observations and 198 native NWFSC conditional age-at-length samples for ages 0-21 (2005-2016).",
    "The assessment does not provide an unconditional age-specific survey index; any age-index reconstruction remains an explicit approximation and was not imported.")
  candidates$weights_evidence[ci] <- "The model generates age-specific weights from sex-specific growth and length-weight functions; no independent weight-at-age input vector is supplied."
  candidates$maturity_evidence[ci] <- "Maturity is specified as a length-based logistic relationship; no independent maturity-at-age input vector is supplied."
  candidates$mortality_evidence[ci] <- "Base-model M is fixed at 0.235 per year for both sexes; 0.164 is a separate low-M sensitivity state."
  candidates$timing_evidence[ci] <- "All index and composition records are in July (month 7), represented as within-year time 0.5."
  candidates$output_evidence[ci] <- paste(
    "Imported 1916-2016 SSB, total biomass, age-0 recruitment, total abundance, N-at-age, Z/M/F-at-age, and fleet/sex catch-at-age.",
    "F is derived as Z minus M; no uncertainty file was recovered, so age-surface SEs and intervals are unavailable.")
  candidates$decision_reason[ci] <- "The 2017 benchmark remains the latest full assessment located; the July 2025 SAFE continues to use it. Source curation is partial because direct fishery catch-at-age and an age-specific survey index are not supplied."
  candidates$notes[ci] <- paste(
    "Partial source import from the official 2017 model archive and assessment report.",
    "Native compositions, source signs, sample sizes, age-error code, and index units are preserved; see source_reviews/noaa_california_scorpionfish_southern_california_2017.md.")
  replace_candidate_register_row(candidate_path, ci, candidates[ci, , drop = FALSE], candidate_id)

  source(file.path(root, "scripts", "database", "002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("Scorpionfish rows imported and database validation passed.\n")
}
