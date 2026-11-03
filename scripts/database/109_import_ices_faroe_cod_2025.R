assessment_id <- "ices_cod_faroe_plateau_2025"
stock_id <- "ck_ices_nwwg_morhua_fapl5b1"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", stock_id)
run_cache <- file.path(cache, "run_2025_official")
database <- file.path(base, "database")

if (!requireNamespace("stockassessment", quietly = TRUE) ||
  !requireNamespace("rvest", quietly = TRUE) ||
  !requireNamespace("openssl", quietly = TRUE)) {
  stop("Install stockassessment, rvest, and openssl to import the cached ICES sources.", call. = FALSE)
}

model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "Cod_27_5b1_2025"
)
advice_url <- "https://doi.org/10.17895/ices.advice.28162805"
sag_url <- "https://sg.ices.dk/ViewSourceData.aspx?key=21240"
framework_url <- "https://doi.org/10.17895/ices.pub.21565164"
report_url <- "https://doi.org/10.17895/ices.pub.25605738"

required <- file.path(cache, c(
  "ICES_Advice_2025.pdf", "ICES_SAG_2025.html", "IBPFAR_2022.pdf",
  "NWWG_2024_Cod_chapter.pdf", "NWWG_2026_sections_1_2-6.pdf",
  "run_2025_official/run/model.RData",
  "run_2025_official/run/data.RData", "run_2025_official/conf/model.cfg",
  "run_2025_official/Makefile", "run_2025_official/make.R",
  "run_2025_official/src/model.R", "run_2025_official/src/datascript.R"
))
if (any(!file.exists(required))) {
  stop("The cached Faroe Plateau cod sources or selected 2025 run are incomplete.", call. = FALSE)
}

fit_env <- new.env(parent = baseenv())
load(file.path(run_cache, "run", "model.RData"), envir = fit_env)
data_env <- new.env(parent = baseenv())
load(file.path(run_cache, "run", "data.RData"), envir = data_env)
fit <- fit_env$fit
dat <- fit$data
raw_dat <- data_env$dat
years <- as.integer(dat$years)
ages <- as.integer(colnames(dat$stockMeanWeight))
fleet_names <- as.character(attr(dat, "fleetNames"))
survey_codes <- c("", "FO-GFS-Q3", "FO-GFS-Q1")
sample_times <- as.numeric(dat$sampleTimes)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
observed <- is.finite(dat$logobs)

if (fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  max(abs(fit$sdrep$gradient.fixed)) > 1e-8 ||
  !identical(years, 1959:2025) || !identical(ages, 1:10) ||
  length(fleet_names) != 3L ||
  !isTRUE(all.equal(sample_times, c(0, 0.65, 0.225), tolerance = 1e-8)) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 0L, 0L)) ||
  !identical(as.integer(fit$conf$fbarRange), c(3L, 7L)) ||
  !identical(as.integer(fit$conf$keyVarLogN), c(0L, rep(1L, 9L))) ||
  !identical(as.character(fit$conf$obsCorStruct), c("ID", "AR", "ID")) ||
  fit$conf$stockRecruitmentModelCode != 0L ||
  !identical(as.integer(fit$conf$keyLogFsta[1L, ]), c(-1L, 0L, 1L, 2L, 3L, 4L, 5L, 5L, 5L, 6L))) {
  stop("The selected SAM fit does not match the reviewed years, ages, process structure, or diagnostics.", call. = FALSE)
}

if (!identical(fleet_names[1L], "Residual catch") ||
  !grepl("SUMMERSURVEY", fleet_names[2L], fixed = TRUE) ||
  !grepl("SPRINGSURVEY", fleet_names[3L], fixed = TRUE) ||
  any(!is.finite(dat$stockMeanWeight)) || any(!is.finite(dat$propMat)) ||
  any(!is.finite(dat$natMor)) || any(!is.finite(dat$catchMeanWeight)) ||
  any(!is.finite(dat$landMeanWeight)) || any(!is.finite(dat$disMeanWeight)) ||
  any(!is.finite(dat$landFrac)) || any(!is.finite(dat$propF)) ||
  any(!is.finite(dat$propM)) || any(is.finite(dat$weight))) {
  stop("The source fleet labels or biological/observation inputs differ from the reviewed SAM data.", call. = FALSE)
}

for (field in c(
  "years", "logobs", "weight", "propMat", "stockMeanWeight",
  "catchMeanWeight", "natMor", "landFrac", "disMeanWeight",
  "landMeanWeight", "propF", "propM", "sampleTimes", "aux"
)) {
  if (field %in% c("logobs", "weight", "aux")) next
  if (!isTRUE(all.equal(dat[[field]], raw_dat[[field]], check.attributes = FALSE))) {
    stop("The fitted SAM data object differs from its cached source data in ", field, ".", call. = FALSE)
  }
}

fit_aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
raw_aux <- as.data.frame(raw_dat$aux, stringsAsFactors = FALSE)
names(fit_aux) <- names(raw_aux) <- c("year", "fleet", "age")
aux_key <- function(x) paste(x$year, x$fleet, x$age, sep = "\r")
source_row <- match(aux_key(fit_aux), aux_key(raw_aux))
if (anyNA(source_row) || anyDuplicated(aux_key(raw_aux))) {
  stop("The fitted SAM observation rows do not map uniquely to the cached source data object.", call. = FALSE)
}
for (field in c("logobs", "weight")) {
  if (!isTRUE(all.equal(
    dat[[field]], raw_dat[[field]][source_row], check.attributes = FALSE
  ))) {
    stop("The fitted SAM observations differ from the cached source data in ", field, ".", call. = FALSE)
  }
}

if (max(abs(dat$natMor - 0.2)) > 1e-10 ||
  any(dat$propF != 0) || any(dat$propM != 0) ||
  !identical(as.integer(fit$conf$keyVarF[1L, ]), c(-1L, 1L, rep(0L, 8L))) ||
  !identical(as.integer(fit$conf$keyLogFpar[2L, ]), c(0:7, 7L, -1L)) ||
  !identical(as.integer(fit$conf$keyLogFpar[3L, ]), c(8:15, 15L, -1L)) ||
  any(fit$conf$keyQpow != -1L) ||
  !identical(as.integer(fit$conf$keyVarObs[1L, ]), c(-1L, rep(0L, 8L), 5L)) ||
  !identical(as.integer(fit$conf$keyVarObs[2L, ]), c(1L, rep(2L, 8L), -1L)) ||
  !identical(as.integer(fit$conf$keyVarObs[3L, ]), c(3L, rep(4L, 8L), -1L))) {
  stop("The selected run's M, spawning-time, or observation-error configuration differs from the reviewed model.", call. = FALSE)
}

observed_counts <- tabulate(aux$fleet[observed], nbins = length(fleet_names))
if (!identical(as.integer(observed_counts), c(590L, 270L, 280L)) ||
  sum(!observed) != 21L ||
  !identical(as.integer(table(aux$age[observed & aux$fleet == 1L])), c(rep(67L, 8L), 54L)) ||
  any(is.finite(dat$weight))) {
  stop("The observed catch and survey records do not match the reviewed source coverage.", call. = FALSE)
}

if (assessment_id %in% read.csv(file.path(database, "assessments.csv"),
  colClasses = "character", stringsAsFactors = FALSE)$assessment_id) {
  stop("The assessment event already exists; review it before re-importing.", call. = FALSE)
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
      transformation = "Exponentiated SAM log-catch observations.",
      notes = "Total commercial catch-at-age; age 10 is the plus group. Missing source rows remain missing."
    )
  } else {
    input_rows(
      "index", "numbers_at_age", "index_scale", aux$year[i], aux$age[i],
      exp(dat$logobs[i]), "native survey-index units",
      survey = survey_codes[[fleet_id]], sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "/run/model.RData; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated SAM log-index observations; native index scale is retained.",
      notes = paste0("SAM fleet label: ", fleet_names[[fleet_id]], "; ages 1–9; no external scale multiplier is specified.")
    )
  }
})
observations <- do.call(rbind, obs_rows)

grid_ref <- paste0(model_url, "/run/model.RData; fit$data")
inputs <- rbind(
  observations,
  surface_input(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish", "kg per fish", "stockMeanWeight", "Annual stock weight-at-age."),
  surface_input(dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "catchMeanWeight", "Annual catch weight-at-age."),
  surface_input(dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish", "landMeanWeight", "Annual landings weight-at-age."),
  surface_input(dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish", "disMeanWeight", "Annual discard weight-at-age."),
  surface_input(dat$propMat, "maturity", "maturity_at_age", "proportion", "proportion", "propMat", "Annual maturity-at-age."),
  surface_input(dat$natMor, "M", "natural_mortality_at_age", "per_year", "per year", "natMor", "Fixed annual natural mortality; not estimated by SAM."),
  surface_input(dat$landFrac, "catch", "landings_fraction_at_age", "proportion", "proportion", "landFrac", "Native landings fraction at age; retained without clipping."),
  surface_input(dat$propF, "biology", "fraction_F_before_spawning", "proportion", "proportion", "propF", "Fraction of annual F applied before spawning; native values are zero."),
  surface_input(dat$propM, "biology", "fraction_M_before_spawning", "proportion", "proportion", "propM", "Fraction of annual M applied before spawning; native values are zero.")
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
  assumption_rows("population", "years_and_ages", "1959–2025; ages 1–10+", cfg_ref, "Age 10 is the terminal plus group for catch and population states; both surveys cover ages 1–9."),
  assumption_rows("population", "recruitment_age", "1", cfg_ref, "Recruitment is the age-1 beginning-of-year population; no cohort-year shift is applied."),
  assumption_rows("N", "process", "Independent age-specific log-N states with shared variance groups", cfg_ref, "keyVarLogN assigns age 1 its own variance; ages 2–10 share another variance."),
  assumption_rows("F", "process", "Log-F states with AR(1) correlation across age states", cfg_ref, "corFlag = 2; ages 7–9 share one latent F state; age 1 has no estimated F state."),
  assumption_rows("F", "process_variance_sharing", "Age 2 separate; ages 3–10 share one variance", cfg_ref, "The F process likelihood uses the unique states represented by keyLogFsta."),
  assumption_rows("F", "Fbar_ages", "3–7", cfg_ref, "Native Fbar is defined over ages 3–7."),
  assumption_rows("M", "process", "Fixed", paste0(model_url, "/run/model.RData; fit$data$natMor"), "Natural mortality is fixed at 0.2 per year at every age and year; it is not estimated."),
  assumption_rows("biology", "spawning_time_mortality", "propF = 0 and propM = 0", paste0(model_url, "/run/model.RData; fit$data$propF and fit$data$propM"), "No annual F or M is applied before the model's spawning point."),
  assumption_rows("catch", "observation_model", "Lognormal catch-at-age", cfg_ref, "Ages 2–9 share one observation variance; age 10+ has a separate variance. Catch observations are in thousand fish."),
  assumption_rows("index", "observation_model", "Lognormal age-specific indices", cfg_ref, "All model observations use the lognormal likelihood; no finite relative precision weights are supplied."),
  assumption_rows("index", "observation_correlation", "Catch ID; summer AR; spring ID", cfg_ref, "The summer survey has AR(1) residual correlation across ages; tinyAM uses independent index residuals."),
  assumption_rows("index", "catchability_age_groups", "Both surveys: ages 1–7 separate; ages 8–9 share; no age 10", cfg_ref, "q is age-specific except for shared ages 8–9; the same grouping is represented separately for each survey."),
  assumption_rows("index", "survey_identity_and_timing", "FO-GFS-Q3 0.65; FO-GFS-Q1 0.225", paste0(model_url, "/run/model.RData; fit$data$sampleTimes"), "The source fleet labels are SUMMERSURVEY and SPRINGSURVEY; timing is represented as a proportion of the year."),
  assumption_rows("biology", "annual_inputs", "Stock, catch, landings, and discard weights; maturity; fixed M; landings fraction; spawning-time fractions", grid_ref, "Native annual source surfaces are preserved without smoothing or interpolation."),
  assumption_rows("biology", "SSB_definition", "sum(N × stock weight × maturity)", paste0(model_url, "/run/model.RData; fit$data and stockassessment::ssbtable"), "propF and propM are zero; the formula reproduces the native SAM SSB surface in tonnes."),
  assumption_rows("assessment", "sam_version", "stockassessment 0.12.0; RemoteSha 1cc464b80f6f", paste0(model_url, "/run_listing.html"), "Selected 2025 run matches the 2025 ICES published recruitment, SSB, and F series for 2024 and 2025; the non-matching 2024 run was excluded.")
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
  matrix(sqrt(random_variances[index]), nrow = nrow(state), ncol = ncol(state))
}

state_outputs <- function(state_name, type, measure, unit, state_ages) {
  state <- fit$pl[[state_name]]
  log_se <- random_state_se(state_name)
  state_map <- matrix(NA_real_, nrow = length(years), ncol = length(ages))
  error_map <- state_map
  key <- as.integer(fit$conf$keyLogFsta[1L, ])
  for (age in ages) {
    if (state_name == "logN") {
      state_map[, age] <- exp(state[age, ])
      error_map[, age] <- log_se[age, ]
    } else if (key[age] >= 0L) {
      state_map[, age] <- exp(state[key[age] + 1L, ])
      error_map[, age] <- log_se[key[age] + 1L, ]
    } else {
      state_map[, age] <- 0
    }
  }
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  estimate <- as.vector(state_map)
  log_error <- as.vector(error_map)
  plus <- ifelse(grid$age == max(ages), paste0(max(ages), "+"), "")
  low <- high <- standard_error <- rep(NA_real_, length(estimate))
  positive <- is.finite(log_error) & is.finite(estimate) & estimate > 0
  standard_error[positive] <- estimate[positive] * log_error[positive]
  low[positive] <- exp(log(estimate[positive]) - z * log_error[positive])
  high[positive] <- exp(log(estimate[positive]) + z * log_error[positive])
  output_rows(
    type, measure, grid$year, grid$age, plus, estimate, unit,
    se = standard_error, lwr = low, upr = high,
    source_reference = paste0(model_url, "/run/model.RData; fit$pl$", state_name, " and fit$sdrep$diag.cov.random"),
    notes = if (state_name == "logN") {
      "Native SAM beginning-of-year abundance; conditional random-effect covariance gives natural-scale delta-method SEs and 95% Wald intervals on the log scale. Age 10 is 10+."
    } else {
      "Native SAM fishing mortality; F at age 1 is structurally zero. F states for ages 7–9 are shared. Conditional random-effect covariance gives natural-scale delta-method SEs and 95% Wald intervals on the log scale. Age 10 is 10+."
    }
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
    unit = unit,
    source_reference = paste0(model_url, "/run/model.RData; stockassessment::", deparse(substitute(fun)), "(fit)"),
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
if (length(predicted) != nrow(aux) || any(!is.finite(predicted))) {
  stop("Native SAM predictions do not align with fit$data$aux.", call. = FALSE)
}
catch_id <- which(aux$fleet == 1L)
index_id <- which(aux$fleet > 1L)
n_surface <- stockassessment::ntable(fit)
f_surface <- stockassessment::faytable(fit)
ssb_check <- rowSums(n_surface * dat$stockMeanWeight * dat$propMat)
tsb_check <- rowSums(n_surface * dat$stockMeanWeight)
fbar_check <- rowMeans(f_surface[, 3:7, drop = FALSE])
if (max(abs(ssb_check - stockassessment::ssbtable(fit)[as.character(years), "Estimate"])) > 1e-6 ||
  max(abs(tsb_check - stockassessment::tsbtable(fit)[as.character(years), "Estimate"])) > 1e-6 ||
  max(abs(fbar_check - stockassessment::fbartable(fit)[as.character(years), "Estimate"])) > 1e-8) {
  stop("SAM aggregate outputs do not match the documented N, biology, and Fbar definitions.", call. = FALSE)
}
if (abs(stockassessment::rectable(fit)["2024", "Estimate"] - 7283) > 0.5 ||
  abs(stockassessment::ssbtable(fit)["2024", "Estimate"] - 17240) > 0.5 ||
  abs(stockassessment::fbartable(fit)["2024", "Estimate"] - 0.38) > 0.005 ||
  abs(stockassessment::rectable(fit)["2025", "Estimate"] - 6912) > 0.5 ||
  abs(stockassessment::ssbtable(fit)["2025", "Estimate"] - 20958) > 0.5 ||
  abs(stockassessment::fbartable(fit)["2025", "Estimate"] - 0.57) > 0.005) {
  stop("The selected SAM run does not match the 2025 ICES published summary to its reported precision.", call. = FALSE)
}

outputs <- rbind(
  state_outputs("logN", "population", "numbers_at_age", "thousand fish", ages),
  state_outputs("logF", "mortality", "fishing_mortality_at_age", "per year", ages),
  output_rows(
    "catchability", "q", age = q_grid$age, survey = survey_codes[match(q_grid$survey, fleet_names)],
    value = q_value, se = q_value * q_grid$log_se,
    lwr = exp(q_grid$log_est - z * q_grid$log_se),
    upr = exp(q_grid$log_est + z * q_grid$log_se),
    unit = "native index units per thousand fish",
    source_reference = paste0(model_url, "/run/model.RData; stockassessment::qtable(fit)"),
    notes = "Exponentiated native log-q; delta-method natural-scale SE and 95% Wald limits on the log scale."
  ),
  output_rows(
    "catch", "predicted_catch", year = aux$year[catch_id], age = aux$age[catch_id],
    value = predicted[catch_id], unit = "thousand fish", fleet = fleet_names[[1L]],
    source_reference = paste0(model_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-catch predictions; includes model slots with missing observed catch. Age 10 is the plus group."
  ),
  output_rows(
    "index", "predicted_index", year = aux$year[index_id], age = aux$age[index_id],
    value = predicted[index_id], unit = "native survey-index units",
    survey = survey_codes[aux$fleet[index_id]],
    source_reference = paste0(model_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-index predictions; predictions are retained for unobserved survey-age slots."
  ),
  native_summary(stockassessment::rectable, "recruitment", "recruitment", "thousand fish", age = 1L, age_group = "age 1", notes = "Native SAM age-1 recruitment and 95% confidence limits."),
  native_summary(stockassessment::ssbtable, "biomass", "SSB", "tonnes", notes = "Native SAM spawning stock biomass and 95% confidence limits."),
  native_summary(stockassessment::fbartable, "mortality", "Fbar", "per year", age_group = "3-7", notes = "Native SAM Fbar over ages 3–7 and 95% confidence limits."),
  native_summary(stockassessment::tsbtable, "biomass", "total_biomass", "tonnes", notes = "Native SAM total stock biomass and 95% confidence limits."),
  output_rows(
    "population", "total_numbers", year = years, value = rowSums(n_surface),
    unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(model_url, "/run/model.RData; stockassessment::ntable(fit)"),
    notes = "Derived by summing native SAM N-at-age over ages 1–10+; no uncertainty is available for this derived total."
  )
)

if (any(!is.finite(outputs$value)) || anyDuplicated(paste(
  outputs$type, outputs$measure, outputs$year, outputs$age, outputs$age_group, outputs$survey
))) {
  stop("Imported output values are non-finite or have duplicate keys.", call. = FALSE)
}

stocks_path <- file.path(database, "stocks.csv")
stocks <- read.csv(stocks_path, colClasses = "character", na.strings = "", check.names = FALSE, stringsAsFactors = FALSE)
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) stop("Expected one existing Charbonneau–Keith stock row.", call. = FALSE)
stocks$authority_stock_id[stock_row] <- "cod.27.5b1"
stocks$common_name[stock_row] <- "Faroe Plateau cod"
stocks$area[stock_row] <- "ICES Subdivision 5.b.1 (Faroe Plateau)"
stocks$region[stock_row] <- "Faroe Plateau"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Matched to the official ICES stock code cod.27.5b1.",
  "The 2025 SAM run is the detailed fit selected for the current record; its terminal estimates match ICES advice and SAG values for 2024–2025."
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "annual",
  model_family = "SAM", model_version = "stockassessment 0.12.0 (1cc464b80f6f)",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = advice_url, framework_url = framework_url,
  data_url = paste0(model_url, "/run/data.RData"),
  model_url = paste0(model_url, "/run/model.RData"),
  repository_url = "", assumptions_status = "complete",
  inputs_status = "complete", outputs_status = "complete",
  notes = paste(
    "Selected official 2025 SAM production run, fitted for 1959–2025.",
    "The selected fit matches the published 2025 ICES recruitment, SSB, and F series for 2024 and 2025 at table precision.",
    "The model converged (optimizer code 0), its Hessian is positive definite, and maximum absolute fixed gradient is below 2e-12."
  ), stringsAsFactors = FALSE, check.names = FALSE
)

append_rows <- function(file, rows) {
  path <- file.path(database, file)
  columns <- names(read.csv(path, nrows = 1L, check.names = FALSE))
  if (!all(columns %in% names(rows))) stop("Unexpected schema for ", file, ".", call. = FALSE)
  utils::write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

utils::write.table(stocks, stocks_path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = TRUE, na = "")
append_rows("assessments.csv", assessment)
append_rows("assumptions.csv", assumptions)
append_rows("inputs.csv", inputs)
append_rows("outputs.csv", outputs)

manifest_files <- c(
  "ICES_Advice_2025.pdf", "ICES_SAG_2025.html", "IBPFAR_2022.pdf",
  "NWWG_2024_Cod_chapter.pdf", "NWWG_2026_sections_1_2-6.pdf",
  "run_2025_official/run/model.RData",
  "run_2025_official/run/data.RData", "run_2025_official/conf/model.cfg",
  "run_2025_official/Makefile", "run_2025_official/make.R",
  "run_2025_official/src/model.R", "run_2025_official/src/datascript.R",
  "run_2025_official/src/common.R", "run_2025_official/run/forecast.RData"
)
manifest_url <- c(
  advice_url, sag_url, "https://ndownloader.figshare.com/files/38370317",
  "https://ndownloader.figshare.com/files/52057925",
  "https://doi.org/10.17895/ices.pub.32414577",
  paste0(model_url, "/run/model.RData"), paste0(model_url, "/run/data.RData"),
  paste0(model_url, "/conf/model.cfg"), paste0(model_url, "/Makefile"),
  paste0(model_url, "/make.R"), paste0(model_url, "/src/model.R"),
  paste0(model_url, "/src/datascript.R"), paste0(model_url, "/src/common.R"),
  paste0(model_url, "/run/forecast.RData")
)
manifest <- data.frame(
  file = manifest_files, url = manifest_url,
  retrieval_date = "2026-10-21",
  sha256 = vapply(file.path(cache, manifest_files), function(path) {
    bytes <- readBin(path, "raw", n = file.info(path)$size)
    hash <- as.character(openssl::sha256(bytes))
    tolower(gsub(":", "", sub("^sha256\\s+", "", hash)))
  }, character(1)),
  represented_assessment = "2025 ICES SAM assessment for cod.27.5b1",
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(cache, "manifest.csv"), row.names = FALSE)

cat(
  "Imported the 2025 official Faroe Plateau cod SAM assessment: ", nrow(inputs),
  " input rows, ", nrow(assumptions), " assumptions, and ", nrow(outputs),
  " output rows.\n", sep = ""
)
