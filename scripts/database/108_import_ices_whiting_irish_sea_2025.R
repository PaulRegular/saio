assessment_id <- "ices_whiting_irish_sea_2025_benchmark"
summary_id <- "ices_whiting_irish_sea_2025_sag_summary"
stock_id <- "ck_ices_wgcse_merlangus_cs7a"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", stock_id)
database <- file.path(base, "database")

if (!requireNamespace("stockassessment", quietly = TRUE) ||
  !requireNamespace("rvest", quietly = TRUE)) {
  stop("Install stockassessment and rvest to import the cached ICES sources.", call. = FALSE)
}

model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "whg.27.7a_WKBNSCS_final"
)
report_url <- "https://doi.org/10.17895/ices.pub.28715180"
framework_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091589.pdf"
sag_url <- "https://sg.ices.dk/ViewSourceData.aspx?key=20997"

required <- file.path(cache, c(
  "model.RData", "data.RData", "model.cfg", "ver", "Makefile",
  "WKBNSCS_2025.pdf", "ICES_SAG_2025.html", "manifest.csv"
))
if (any(!file.exists(required))) {
  stop("The cached Irish Sea whiting sources or manifest are incomplete.", call. = FALSE)
}

fit_env <- new.env(parent = baseenv())
load(file.path(cache, "model.RData"), envir = fit_env)
data_env <- new.env(parent = baseenv())
load(file.path(cache, "data.RData"), envir = data_env)
fit <- fit_env$fit
dat <- fit$data
raw_dat <- data_env$dat
version <- readLines(file.path(cache, "ver"), warn = FALSE)

years <- as.integer(dat$years)
ages <- as.integer(colnames(dat$stockMeanWeight))
fleet_names <- attr(dat, "fleetNames")
sample_times <- as.numeric(dat$sampleTimes)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
observed <- is.finite(dat$logobs)
obs_aux <- aux[observed, , drop = FALSE]

if (fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  max(abs(fit$sdrep$gradient.fixed)) > 1e-8 ||
  !identical(years, 1980:2023) || !identical(ages, 0:6) ||
  !identical(fleet_names, c("Residual catch", "NIGFS-Q1", "NIGFS-Q4", "NIMIK")) ||
  !isTRUE(all.equal(sample_times, c(0, 0.23, 0.855, 0.48), tolerance = 1e-8)) ||
  !identical(as.integer(table(aux$fleet)), c(308L, 192L, 224L, 30L)) ||
  !identical(as.integer(table(obs_aux$fleet)), c(308L, 192L, 224L, 28L)) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 1L, 1L, 0L)) ||
  !identical(as.integer(fit$conf$keyVarLogN), c(0L, 1L, 1L, 1L, 1L, 1L, 1L))) {
  stop("The cached SAM fit does not match the reviewed years, ages, fleets, or diagnostics.", call. = FALSE)
}

for (field in c(
  "years", "logobs", "weight", "propMat", "stockMeanWeight",
  "catchMeanWeight", "natMor", "landFrac", "disMeanWeight",
  "landMeanWeight", "propF", "propM"
)) {
  if (!isTRUE(all.equal(dat[[field]], raw_dat[[field]], check.attributes = FALSE))) {
    stop("The fitted data object differs from cached source data in ", field, ".", call. = FALSE)
  }
}

expected_m <- c(2.20, 0.98, 0.75, 0.67, 0.63, 0.62, 0.61)
if (!isTRUE(all.equal(unname(dat$natMor[1, ]), expected_m, tolerance = 1e-8)) ||
  any(abs(dat$natMor - matrix(expected_m, nrow(dat$natMor), length(ages), byrow = TRUE)) > 1e-8) ||
  sum(dat$landFrac > 1, na.rm = TRUE) != 7L ||
  abs(max(dat$landFrac, na.rm = TRUE) - 1.0237) > 1e-4) {
  stop("A biological input did not match the reviewed source values.", call. = FALSE)
}

if (assessment_id %in% read.csv(file.path(database, "assessments.csv"),
  colClasses = "character", stringsAsFactors = FALSE)$assessment_id ||
  summary_id %in% read.csv(file.path(database, "assessments.csv"),
    colClasses = "character", stringsAsFactors = FALSE)$assessment_id) {
  stop("An assessment event already exists; review it before re-importing.", call. = FALSE)
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_reference, transformation = "Copied from the fitted SAM data object.",
                       notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  y <- recycle(year)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = recycle(basis), fleet = recycle(fleet), survey = recycle(survey),
    sex = "", region = "", season = "", year = y,
    year_basis = ifelse(is.na(y), "", "calendar_year"),
    age = recycle(age), value = as.numeric(value), unit = recycle(unit),
    sampling_time = recycle(sampling_time), source_type = "native_model",
    source_reference = recycle(source_reference), transformation = recycle(transformation),
    notes = recycle(notes), observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = "", partition = "", stringsAsFactors = FALSE, check.names = FALSE
  )
}

surface_input <- function(x, type, measure, basis, unit, slot, notes) {
  if (length(dim(x)) == 3L) {
    if (dim(x)[3L] != 1L) stop("Unexpected fleet dimension in fit$data$", slot, ".", call. = FALSE)
    x <- x[, , 1L]
  }
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages))) || any(!is.finite(x))) {
    stop("Unexpected dimensions or missing values in fit$data$", slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  input_rows(
    type, measure, basis, grid$year, grid$age, as.vector(x), unit,
    source_reference = paste0(model_url, "/run/model.RData; fit$data$", slot),
    notes = notes
  )
}

obs_rows <- lapply(seq_along(fleet_names), function(fleet_id) {
  i <- which(observed & aux$fleet == fleet_id)
  if (fleet_id == 1L) {
    input_rows(
      "catch", "numbers_at_age", "numbers", aux$year[i], aux$age[i],
      exp(dat$logobs[i]), "thousand fish", fleet = fleet_names[[fleet_id]],
      source_reference = paste0(model_url, "/run/model.RData; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the fitted SAM log-catch input.",
      notes = "Total commercial catch-at-age; age 6 is the plus group."
    )
  } else {
    input_rows(
      "index", "numbers_at_age", "index_scale", aux$year[i], aux$age[i],
      exp(dat$logobs[i]), "native survey-index units",
      survey = fleet_names[[fleet_id]], sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "/run/model.RData; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the fitted SAM log-index input; values remain on the native SAM scale.",
      notes = if (fleet_id %in% 2:3) "Age-specific NIGFS VAST index." else "NIMIK age-0 index."
    )
  }
})
observations <- do.call(rbind, obs_rows)

weighted <- which(observed & is.finite(dat$weight))
precision_rows <- input_rows(
  "index", "relative_precision_weight", "relative_precision",
  aux$year[weighted], aux$age[weighted], dat$weight[weighted],
  "relative precision weight", survey = fleet_names[aux$fleet[weighted]],
  sampling_time = sample_times[aux$fleet[weighted]],
  source_reference = paste0(model_url, "/run/model.RData; fit$data$weight and fit$data$aux"),
  transformation = "Copied native SAM precision weights; the observation variance is divided by this weight.",
  notes = "Finite weights are supplied for the two NIGFS indices; catch and NIMIK observations are unweighted."
)

inputs <- rbind(
  observations, precision_rows,
  surface_input(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish", "kg per fish", "stockMeanWeight", "Annual stock weight-at-age."),
  surface_input(dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "catchMeanWeight", "Annual catch weight-at-age."),
  surface_input(dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish", "landMeanWeight", "Annual landings weight-at-age."),
  surface_input(dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish", "disMeanWeight", "Annual discard weight-at-age."),
  surface_input(dat$propMat, "maturity", "maturity_at_age", "proportion", "proportion", "propMat", "Annual maturity-at-age."),
  surface_input(dat$natMor, "M", "natural_mortality_at_age", "per_year", "per year", "natMor", "Fixed M-at-age supplied to SAM; repeated annual surface is preserved."),
  surface_input(dat$landFrac, "catch", "landings_fraction_at_age", "proportion", "proportion", "landFrac", "Source values are retained unchanged; age-6 values slightly above one occur in several years."),
  surface_input(dat$propF, "biology", "fraction_F_before_spawning", "proportion", "proportion", "propF", "Fraction of annual F applied before spawning; all source values are zero."),
  surface_input(dat$propM, "biology", "fraction_M_before_spawning", "proportion", "proportion", "propM", "Fraction of annual M applied before spawning; all source values are zero.")
)

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                            fleet = "", survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = "", region = "", season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
cfg_ref <- paste0(model_url, "/conf/model.cfg; fit$conf")
assumptions <- do.call(rbind, list(
  assumption_rows("population", "years_and_ages", "1980–2023; ages 0–6+", cfg_ref, "Age 6 is a plus group for catch, NIGFS-Q1, and NIGFS-Q4; NIMIK observes age 0 only."),
  assumption_rows("population", "recruitment_age", "0", cfg_ref, "Recruitment is reported at age 0."),
  assumption_rows("recruitment", "process", "Random walk", cfg_ref, "Age-0 log abundance has its own process-variance key."),
  assumption_rows("N", "process_variance_sharing", "Age 0 separate; ages 1–6 share one variance key", cfg_ref, "Native keyVarLogN = 0,1,1,1,1,1,1."),
  assumption_rows("F", "process", "Log-F process with AR(1) correlation across ages", cfg_ref, "corFlag = 2; F process variance is shared across ages."),
  assumption_rows("F", "Fbar_ages", "1–3", report_url, "Native annual Fbar is the mean fishing mortality over ages 1–3."),
  assumption_rows("M", "process", "Fixed", paste0(model_url, "/run/model.RData; fit$data$natMor"), "M-at-age is 2.20, 0.98, 0.75, 0.67, 0.63, 0.62, and 0.61 per year; it is not estimated."),
  assumption_rows("biology", "spawning_time_mortality", "propF = 0 and propM = 0", paste0(model_url, "/run/model.RData; fit$data$propF and fit$data$propM"), "No annual F or M is applied before the spawning point in this model input."),
  assumption_rows("catch", "observation_model", "Lognormal total catch-at-age", cfg_ref, "One catch observation SD is shared across ages 0–6."),
  assumption_rows("index", "observation_model", "Lognormal age-specific indices", cfg_ref, "NIGFS-Q1 and NIGFS-Q4 use relative precision weights; NIMIK has no supplied weight. NIMIK has 28 fitted observations in 30 model slots; 2020 and 2022 are missing."),
  assumption_rows("index", "observation_correlation", "ID, AR, AR, ID by fleet", cfg_ref, "Residual age correlation is used for NIGFS-Q1 and NIGFS-Q4; tinyAM translation treats index residuals as independent."),
  assumption_rows("index", "catchability_age_groups", "Q1: age 1, ages 2–5, age 6; Q4: age 0, ages 1–3, age 4, age 5, age 6; NIMIK: age 0", cfg_ref, "Preserved as q_key groups in the translation."),
  assumption_rows("index", "survey_timing", "NIGFS-Q1 0.23; NIGFS-Q4 0.855; NIMIK 0.48", paste0(model_url, "/run/model.RData; fit$data$sampleTimes"), "Proportion of year from the annual model start."),
  assumption_rows("biology", "annual_inputs", "Stock, catch, landings, and discard weights; maturity; M; landings fraction; spawning-time fractions", paste0(model_url, "/run/model.RData; fit$data"), "Native source surfaces are stored without smoothing or interpolation."),
  assumption_rows("catch", "landings_fraction", "Source landFrac surface", paste0(model_url, "/run/model.RData; fit$data$landFrac"), "A few age-6 values are slightly above one; retained without clipping."),
  assumption_rows("assessment", "sam_version", "stockassessment 0.12.0; RemoteSha 7e947decf551", paste0(model_url, "/run/ver"), "The exact fitted run and source data object are cached locally with checksums.")
))

output_rows <- function(type, measure, year = NA_integer_, age = NA_integer_,
                        age_group = "", value, unit, se = NA_real_,
                        lwr = NA_real_, upr = NA_real_, fleet = "", survey = "",
                        source_type = "native_model", source_reference, notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = recycle(fleet), survey = recycle(survey), sex = "", region = "",
    season = "", year = recycle(year), age = recycle(age),
    age_group = recycle(age_group), value = as.numeric(value), se = recycle(se),
    lwr = recycle(lwr), upr = recycle(upr), unit = recycle(unit),
    source_type = source_type, source_reference = recycle(source_reference),
    notes = recycle(notes), stringsAsFactors = FALSE, check.names = FALSE
  )
}

z <- stats::qnorm(0.975)
random_names <- names(fit$sdrep$par.random)
random_values <- unname(fit$sdrep$par.random)
random_variances <- fit$sdrep$diag.cov.random
random_state_se <- function(name) {
  state <- fit$pl[[name]]
  index <- which(random_names == name)
  if (length(index) != length(state) ||
    max(abs(random_values[index] - as.vector(state))) > 1e-10 ||
    any(!is.finite(random_variances[index])) || any(random_variances[index] <= 0)) {
    stop("Could not align SAM random-state uncertainty for ", name, ".", call. = FALSE)
  }
  matrix(sqrt(random_variances[index]), nrow = nrow(state), ncol = ncol(state), dimnames = dimnames(state))
}

state_output <- function(measure, state_name, type, unit) {
  log_state <- t(fit$pl[[state_name]])
  log_se <- t(random_state_se(state_name))
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  log_est <- as.vector(log_state)
  log_error <- as.vector(log_se)
  plus <- ifelse(grid$age == max(ages), paste0(max(ages), "+"), "")
  output_rows(
    type, measure, grid$year, grid$age, plus,
    exp(log_est), unit, se = exp(log_est) * log_error,
    lwr = exp(log_est - z * log_error), upr = exp(log_est + z * log_error),
    source_reference = paste0(model_url, "/run/model.RData; fit$pl$", state_name, " and fit$sdrep$diag.cov.random"),
    notes = "Native SAM state; SE uses conditional random-effect covariance and limits are 95% Wald intervals on the log scale."
  )
}

native_summary <- function(fun, type, measure, unit, age = NA_integer_,
                           age_group = "", notes) {
  table <- fun(fit)
  row <- table[as.character(years), , drop = FALSE]
  if (!identical(rownames(row), as.character(years)) || any(!is.finite(row))) {
    stop("Could not recover the annual native SAM ", measure, " table.", call. = FALSE)
  }
  output_rows(
    type, measure, year = years, age = age, age_group = age_group,
    value = row[, "Estimate"], lwr = row[, "Low"], upr = row[, "High"],
    unit = unit, source_reference = paste0(model_url, "/run/model.RData; stockassessment::", deparse(substitute(fun)), "(fit)"),
    notes = notes
  )
}

q_log <- stockassessment::qtable(fit)
q_se <- attr(q_log, "sd")
if (!identical(dim(q_log), dim(q_se)) || !identical(dimnames(q_log), dimnames(q_se))) {
  stop("Native SAM q estimates and uncertainty do not align.", call. = FALSE)
}
q_grid <- expand.grid(survey = rownames(q_log), age = as.integer(colnames(q_log)),
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
q_grid$log_est <- as.vector(q_log)
q_grid$log_se <- as.vector(q_se)
q_grid <- q_grid[is.finite(q_grid$log_est) & is.finite(q_grid$log_se), , drop = FALSE]
q_value <- exp(q_grid$log_est)

predicted <- exp(as.numeric(fit$rep$predObs))
if (length(predicted) != nrow(aux)) stop("Native SAM predictions do not align with fit$data$aux.", call. = FALSE)
catch_id <- which(aux$fleet == 1L)
index_id <- which(aux$fleet > 1L)

outputs <- rbind(
  state_output("numbers_at_age", "logN", "population", "thousand fish"),
  state_output("fishing_mortality_at_age", "logF", "mortality", "per year"),
  output_rows(
    "catchability", "q", age = q_grid$age, survey = q_grid$survey,
    value = q_value, se = q_value * q_grid$log_se,
    lwr = exp(q_grid$log_est - z * q_grid$log_se),
    upr = exp(q_grid$log_est + z * q_grid$log_se),
    unit = "native index units per thousand fish",
    source_reference = paste0(model_url, "/run/model.RData; stockassessment::qtable(fit)"),
    notes = "Exponentiated native log-q; uncertainty is delta-method SE and 95% Wald limits on the log scale. Index scale is unchanged."
  ),
  output_rows(
    "catch", "predicted_catch", year = aux$year[catch_id], age = aux$age[catch_id],
    value = predicted[catch_id], unit = "thousand fish", fleet = fleet_names[[1L]],
    source_reference = paste0(model_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-catch predictions aligned to native year and age rows."
  ),
  output_rows(
    "index", "predicted_index", year = aux$year[index_id], age = aux$age[index_id],
    value = predicted[index_id], unit = "native survey-index units",
    survey = fleet_names[aux$fleet[index_id]],
    source_reference = paste0(model_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-index predictions aligned to native year, survey, and age rows."
  ),
  native_summary(stockassessment::rectable, "recruitment", "recruitment", "thousand fish", age = 0L, age_group = "age 0", notes = "Native SAM age-0 recruitment and 95% confidence limits."),
  native_summary(stockassessment::ssbtable, "biomass", "SSB", "tonnes", notes = "Native SAM spawning stock biomass and 95% confidence limits."),
  native_summary(stockassessment::fbartable, "mortality", "Fbar", "per year", age_group = "1-3", notes = "Native SAM Fbar over ages 1–3 and 95% confidence limits."),
  native_summary(stockassessment::tsbtable, "biomass", "total_biomass", "tonnes", notes = "Native SAM total stock biomass and 95% confidence limits.")
)

ssb_check <- rowSums(exp(t(fit$pl$logN)) * dat$stockMeanWeight * dat$propMat)
tsb_check <- rowSums(exp(t(fit$pl$logN)) * dat$stockMeanWeight)
if (max(abs(ssb_check - stockassessment::ssbtable(fit)[as.character(years), "Estimate"])) > 1e-6 ||
  max(abs(tsb_check - stockassessment::tsbtable(fit)[as.character(years), "Estimate"])) > 1e-6 ||
  max(abs(rowMeans(exp(t(fit$pl$logF))[, match(1:3, ages), drop = FALSE]) - stockassessment::fbartable(fit)[as.character(years), "Estimate"])) > 1e-8) {
  stop("SAM aggregate outputs do not match their documented population definitions.", call. = FALSE)
}

sag_tables <- rvest::html_table(rvest::read_html(file.path(cache, "ICES_SAG_2025.html")), fill = TRUE)
sag <- Filter(function(x) all(c("Year", "Recruitment", "Low Recruitment", "High Recruitment", "SSB", "Low SSB", "High SSB", "F", "Low F", "High F") %in% names(x)), sag_tables)
if (length(sag) != 1L || !identical(as.integer(sag[[1L]]$Year), 1980:2025)) {
  stop("Could not identify the full ICES SAG summary series for 1980–2025.", call. = FALSE)
}
sag <- as.data.frame(sag[[1L]], stringsAsFactors = FALSE)
summary_output <- function(type, measure, value_col, low_col, high_col, unit,
                           age = NA_integer_, age_group = "", notes) {
  value <- suppressWarnings(as.numeric(sag[[value_col]]))
  low <- suppressWarnings(as.numeric(sag[[low_col]]))
  high <- suppressWarnings(as.numeric(sag[[high_col]]))
  keep <- is.finite(value) & is.finite(low) & is.finite(high)
  output_rows(
    type, measure, year = sag$Year[keep], age = age, age_group = age_group,
    value = value[keep], lwr = low[keep], upr = high[keep],
    unit = unit, source_type = "official_document",
    source_reference = sag_url, notes = notes
  )
}
sag_outputs <- rbind(
  summary_output("recruitment", "recruitment", "Recruitment", "Low Recruitment", "High Recruitment", "thousand fish", age = 0L, age_group = "age 0", notes = "SAG summary series; distinct from the native 2025 benchmark run."),
  summary_output("biomass", "SSB", "SSB", "Low SSB", "High SSB", "tonnes", notes = "SAG summary series; distinct from the native 2025 benchmark run."),
  summary_output("mortality", "F", "F", "Low F", "High F", "per year", notes = "SAG reports an aggregate F series; its table does not identify the age range, so it is not relabelled Fbar. The 2025 value is not reported and is omitted.")
)
sag_outputs$assessment_id <- summary_id
sag_outputs$notes <- paste(sag_outputs$notes, "The SAG series ends in 2025 and is kept in a separate summary-only event.")

stock_path <- file.path(database, "stocks.csv")
stocks <- read.csv(stock_path, colClasses = "character", na.strings = "", check.names = FALSE, stringsAsFactors = FALSE)
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) stop("Expected one existing Charbonneau–Keith stock record.", call. = FALSE)
stocks$authority_stock_id[stock_row] <- "whg.27.7a"
stocks$common_name[stock_row] <- "Whiting"
stocks$area[stock_row] <- "ICES Division 7.a (Irish Sea)"
stocks$region[stock_row] <- "Northeast Atlantic"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Official ICES 2025 WKBNSCS SAM benchmark now represented as a detailed assessment event.",
  "Charbonneau–Keith Master unique_ID ICES-WGCSE_merlangus_CS7a retained as the source stock identifier; assessor family was ICES-WGSCE."
)

assessments <- data.frame(
  assessment_id = c(assessment_id, summary_id),
  stock_id = stock_id,
  assessment_year = c(2025L, 2025L), terminal_year = c(2023L, 2025L),
  estimate_terminal_year = c(2023L, 2025L),
  assessment_type = c("benchmark", "summary_update"),
  model_family = c("SAM", "SAM"),
  model_version = c("stockassessment 0.12.0 (7e947decf551)", "not available"),
  is_current = c(TRUE, FALSE), is_applied = c(TRUE, TRUE),
  framework_year = c(2025L, NA_integer_), assessment_url = c(report_url, sag_url),
  framework_url = c(framework_url, ""),
  data_url = c(paste0(model_url, "/run/data.RData"), sag_url),
  model_url = c(paste0(model_url, "/run/model.RData"), ""),
  repository_url = "",
  assumptions_status = c("complete", "partial"),
  inputs_status = c("complete", "partial"),
  outputs_status = c("complete", "partial"),
  notes = c(
    "Detailed official benchmark fit through 2023; 752 observations are fitted across 754 model slots, with native SAM inputs, estimates, predictions, and available uncertainty recorded. The fit has optimizer code 0, a positive-definite Hessian, and maximum absolute fixed-effect gradient below 1e-12.",
    "Official ICES SAG time-series summary through 2025, stored separately from the 2025 WKBNSCS benchmark because the 2023 SSB differs. Age-specific inputs and model settings are not published on this summary page."
  ), stringsAsFactors = FALSE, check.names = FALSE
)

append_rows <- function(file, rows) {
  path <- file.path(database, file)
  columns <- names(read.csv(path, nrows = 1L, check.names = FALSE))
  if (!all(columns %in% names(rows))) stop("Unexpected schema for ", file, ".", call. = FALSE)
  utils::write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

utils::write.table(stocks, stock_path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = TRUE, na = "")
append_rows("assessments.csv", assessments)
append_rows("assumptions.csv", assumptions)
append_rows("inputs.csv", inputs)
append_rows("outputs.csv", rbind(outputs, sag_outputs))

cat(
  "Imported 1 detailed benchmark and 1 separate SAG summary; ", nrow(inputs),
  " benchmark inputs, ", nrow(outputs), " benchmark outputs, and ",
  nrow(sag_outputs), " summary outputs.\n", sep = ""
)
