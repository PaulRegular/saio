assessment_id <- "ices_haddock_faroe_2025"
stock_id <- "ck_ices_nwwg_aeglefinus_fa5b"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", "ices_haddock_faroe_2025")
database <- file.path(base, "database")
run_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NWWG2025_had"
)
advice_url <- "https://doi.org/10.17895/ices.advice.30738524"
model_file <- file.path(cache, "fit_with_derived.rds")
raw_data_file <- file.path(cache, "run", "data.RData")
catch_file <- file.path(cache, "data", "cn.dat")

required <- c(model_file, raw_data_file, catch_file,
  file.path(cache, "conf", "model.cfg"),
  file.path(cache, "src", "datascript.R"),
  file.path(cache, "ICES_advice_2025_had_27_5b.pdf"))
if (any(!file.exists(required))) {
  stop("The cached Faroe haddock SAM inputs or selected fit are incomplete.", call. = FALSE)
}

read_db <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE)
}
schemas <- lapply(c("stocks.csv", "assessments.csv", "assumptions.csv",
  "inputs.csv", "outputs.csv"), function(name) {
  names(utils::read.csv(file.path(database, name), nrows = 0,
    colClasses = "character", check.names = FALSE))
})
names(schemas) <- c("stocks", "assessments", "assumptions", "inputs", "outputs")

empty_rows <- function(schema, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(schema)),
    stringsAsFactors = FALSE)
  names(out) <- schema
  out
}
value_text <- function(x) ifelse(
  is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), ""
)

fit <- readRDS(model_file)
raw_env <- new.env(parent = baseenv())
load(raw_data_file, envir = raw_env)
dat <- fit$data
raw_dat <- raw_env$dat
years <- as.integer(dat$years)
ages <- seq_len(ncol(dat$stockMeanWeight))
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
fleet_names <- as.character(attr(dat, "fleetNames"))
survey_codes <- c("", "FO-GFS-Q3", "FO-GFS-Q1")
observed <- is.finite(dat$logobs)
catch_slots <- which(aux$fleet == 1L)
index_slots <- which(aux$fleet > 1L)

read_catch_matrix <- function(path, n_years, n_ages) {
  lines <- readLines(path, warn = FALSE)
  values <- scan(text = paste(lines[-seq_len(5L)], collapse = " "),
    quiet = TRUE)
  if (length(values) != n_years * (n_ages + 1L)) {
    stop("Catch file does not match the fitted year-age grid.", call. = FALSE)
  }
  full <- matrix(values, nrow = n_years, byrow = TRUE)
  full[, -1L, drop = FALSE]
}
catch_at_age <- read_catch_matrix(catch_file, length(years), length(ages))
if (!inherits(fit, "sam") ||
  !identical(years, 1957:2025) || !identical(ages, 1:10) ||
  !identical(as.integer(dim(aux)), c(1154L, 3L)) ||
  !identical(as.integer(table(aux$fleet)), c(690L, 240L, 224L)) ||
  !identical(fleet_names, c("Residual catch", "SUMMERSURVEY", "SPRINGSURVEY")) ||
  !isTRUE(all.equal(as.numeric(dat$sampleTimes), c(0, 0.65, 0.225), tolerance = 1e-8)) ||
  !isTRUE(all.equal(dat$years, raw_dat$years, check.attributes = FALSE)) ||
  !isTRUE(all.equal(dat$aux, raw_dat$aux, check.attributes = FALSE)) ||
  !isTRUE(all.equal(dat$logobs, raw_dat$logobs, check.attributes = FALSE)) ||
  !isTRUE(all.equal(dat$weight, raw_dat$weight, check.attributes = FALSE)) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 0L, 0L)) ||
  !identical(as.integer(fit$conf$fbarRange), c(3L, 7L)) ||
  !identical(as.integer(fit$conf$keyVarLogN), c(0L, rep(1L, 9L))) ||
  !identical(as.integer(fit$conf$keyLogFsta[1L, ]), c(0:8, 8L)) ||
  !identical(as.integer(fit$conf$keyLogFpar[2L, ]), c(0:6, 6L, -1L, -1L)) ||
  !identical(as.integer(fit$conf$keyLogFpar[3L, ]), c(7:11, 12L, 12L, -1L, -1L, -1L)) ||
  !identical(as.integer(fit$conf$keyVarObs[1L, ]), rep(0L, 10L)) ||
  !identical(as.integer(fit$conf$keyVarObs[2L, ]), c(1L, 1L, rep(2L, 6L), -1L, -1L)) ||
  !identical(as.integer(fit$conf$keyVarObs[3L, ]), c(3L, rep(4L, 6L), -1L, -1L, -1L)) ||
  !identical(as.integer(fit$conf$obsCorStruct), c(1L, 2L, 2L)) ||
  fit$conf$corFlag != 2L || fit$conf$stockRecruitmentModelCode != 0L ||
  fit$conf$fixVarToWeight != 0L ||
  !identical(as.integer(fit$conf$keyVarF[1L, ]), rep(0L, 10L)) ||
  any(fit$conf$keyQpow != -1L) ||
  any(!is.finite(dat$stockMeanWeight)) || any(!is.finite(dat$propMat)) ||
  any(!is.finite(dat$natMor)) || any(!is.finite(dat$catchMeanWeight)) ||
  any(!is.finite(dat$landMeanWeight)) || any(!is.finite(dat$disMeanWeight)) ||
  any(!is.finite(dat$landFrac)) || any(!is.finite(dat$propF)) ||
  any(!is.finite(dat$propM)) || any(abs(dat$natMor - 0.2) > 1e-10) ||
  any(dat$propF != 0) || any(dat$propM != 0) ||
  any(!is.finite(dat$weight[catch_slots])) ||
  !setequal(unique(dat$weight[catch_slots]), c(0.5, 1)) ||
  sum(catch_at_age == 0) != 41L ||
  any(!is.finite(dat$logobs[catch_slots][observed[catch_slots]])) ||
  !identical(attr(fit, "RemoteSha"), "1cc464b80f6f") ||
  fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  max(abs(fit$sdrep$gradient.fixed)) > 1e-8) {
  stop("The cached fit does not match the reviewed 2025 Faroe haddock run.", call. = FALSE)
}

catch_source <- catch_at_age[cbind(
  aux$year[catch_slots] - min(years) + 1L,
  aux$age[catch_slots]
)]
if (!isTRUE(all.equal(
  catch_source[observed[catch_slots]],
  exp(dat$logobs[catch_slots][observed[catch_slots]]),
  tolerance = 1e-10
)) || any(catch_source[!observed[catch_slots]] != 0)) {
  stop("The cached catch table differs from the fitted SAM observations.", call. = FALSE)
}
if (length(dat$weight) != nrow(aux) ||
  !all(dat$weight[catch_slots][aux$year[catch_slots] == 2025L] == 0.5) ||
  !all(dat$weight[catch_slots][aux$year[catch_slots] < 2025L] == 1)) {
  stop("The SAM catch likelihood weights differ from the source recipe.", call. = FALSE)
}

source_observation <- paste0(run_url, "/run/model.RData; fit$data$logobs and fit$data$aux")
cfg_reference <- paste0(run_url, "/conf/model.cfg; fit$conf")
data_reference <- paste0(run_url, "/run/model.RData; fit$data")

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_reference, transformation = "", notes = "",
                       source_type = "native_model") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  y <- recycle(year)
  out <- empty_rows(schemas$inputs, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- recycle(basis)
  out$fleet <- recycle(fleet)
  out$survey <- recycle(survey)
  out$year <- ifelse(is.na(y), "", as.character(y))
  out$year_basis <- ifelse(nzchar(out$year), "calendar_year", "")
  out$age <- ifelse(is.na(recycle(age)), "", as.character(recycle(age)))
  out$value <- value_text(recycle(value))
  out$unit <- recycle(unit)
  out$sampling_time <- ifelse(is.finite(recycle(sampling_time)),
    value_text(recycle(sampling_time)), "")
  out$source_type <- recycle(source_type)
  out$source_reference <- recycle(source_reference)
  out$transformation <- recycle(transformation)
  out$notes <- recycle(notes)
  out
}

surface_input <- function(x, type, measure, basis, unit, slot, notes) {
  if (length(dim(x)) == 3L) {
    if (dim(x)[3L] != 1L) stop("Unexpected fleet dimension in ", slot, ".", call. = FALSE)
    x <- x[, , 1L]
  }
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("Unexpected dimensions in fit$data$", slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  input_rows(type, measure, basis, grid$year, grid$age, as.vector(x), unit,
    source_reference = paste0(data_reference, "$", slot), notes = notes)
}

constant_age_input <- function(x, measure, basis, unit, slot, notes) {
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages))) ||
    any(apply(x, 2L, function(z) diff(range(z))) > 1e-12)) {
    stop("Expected a time-invariant age vector in fit$data$", slot, ".", call. = FALSE)
  }
  input_rows("M", measure, basis, year = NA_integer_, age = ages,
    value = x[1L, ], unit = unit, source_reference = paste0(data_reference, "$", slot),
    notes = notes)
}

catch_grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
inputs <- input_rows(
  "catch", "numbers_at_age", "numbers",
  catch_grid$year, catch_grid$age, as.vector(catch_at_age), "thousand fish",
  fleet = "Residual catch", source_reference = paste0(run_url, "/data/cn.dat"),
  transformation = "Removed the source age-0 column; retained ages 1–10 as fitted.",
  notes = "Total commercial catch-at-age in thousands of fish; age 10 is the plus group. Source zero catches are retained; SAM excludes zero values from its lognormal likelihood."
)
inputs <- rbind(inputs, input_rows(
  "catch", "relative_precision_weight", "relative_precision",
  aux$year[catch_slots], aux$age[catch_slots], dat$weight[catch_slots],
  "relative weight", fleet = "Residual catch",
  source_reference = paste0(run_url, "/src/datascript.R; catch weight attribute"),
  transformation = "Matched fit$data$weight to catch year-age slots.",
  notes = "fixVarToWeight=0: these are relative likelihood precision weights. The 2025 catch cells have weight 0.5; earlier years have weight 1."
))
for (fleet_id in 2:3) {
  i <- which(aux$fleet == fleet_id)
  inputs <- rbind(inputs, input_rows(
    "index", "numbers_at_age", "index_scale",
    aux$year[i], aux$age[i], exp(dat$logobs[i]), "native survey-index units",
    survey = survey_codes[fleet_id], sampling_time = dat$sampleTimes[fleet_id],
    source_reference = source_observation,
    transformation = "Exponentiated the fitted SAM log-index observations.",
    notes = paste0("Native index scale; source fleet label: ", fleet_names[fleet_id],
      ". Ages and years follow the fitted SAM observation slots.")
  ))
}
inputs <- rbind(inputs,
  surface_input(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "stockMeanWeight", "Annual stock weight-at-age."),
  surface_input(dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "catchMeanWeight", "Annual catch weight-at-age."),
  surface_input(dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish",
    "kg per fish", "landMeanWeight", "Annual landings weight-at-age."),
  surface_input(dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish",
    "kg per fish", "disMeanWeight", "Annual discard weight-at-age."),
  surface_input(dat$propMat, "maturity", "maturity_at_age", "proportion",
    "proportion", "propMat", "Annual maturity-at-age."),
  constant_age_input(dat$natMor, "natural_mortality_at_age", "per_year",
    "per year", "natMor", "Natural mortality is fixed at 0.2 per year."),
  surface_input(dat$landFrac, "catch", "landings_fraction_at_age", "proportion",
    "proportion", "landFrac", "Annual landings fraction at age."),
  surface_input(dat$propF, "biology", "fraction_F_before_spawning", "proportion",
    "proportion", "propF", "Fraction of annual F applied before spawning; source values are zero."),
  surface_input(dat$propM, "biology", "fraction_M_before_spawning", "proportion",
    "proportion", "propM", "Fraction of annual M applied before spawning; source values are zero.")
)

assumption_rows <- function(component, setting, value, source_reference,
                            notes = "", survey = "") {
  out <- empty_rows(schemas$assumptions, length(value))
  out$assessment_id <- assessment_id
  out$component <- component
  out$survey <- rep_len(survey, length(value))
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- rep_len(notes, length(value))
  out
}
assumptions <- do.call(rbind, list(
  assumption_rows("population", "years_and_ages", "1957–2025; ages 1–10+",
    cfg_reference, "Catch age 10 is the plus group; the summer and spring surveys cover ages 1–8 and 1–7."),
  assumption_rows("population", "recruitment_age", "1", cfg_reference,
    "Recruitment is the beginning-of-year population at age 1."),
  assumption_rows("N", "recruitment_process", "stockRecruitmentModelCode=0 (random walk)",
    cfg_reference, "SAM uses a random walk for recruitment."),
  assumption_rows("N", "process_variance_sharing", "Age 1 separate; ages 2–10 share one variance",
    cfg_reference, "Read from keyVarLogN."),
  assumption_rows("F", "age_state_sharing", "Ages 1–8 distinct; ages 9–10 share one F state",
    cfg_reference, "Read from keyLogFsta; the shared state is included once."),
  assumption_rows("F", "process", "AR(1) correlation across F age states",
    cfg_reference, "corFlag=2."),
  assumption_rows("F", "process_variance_sharing", "One F process variance across estimated ages",
    cfg_reference, "Read from keyVarF."),
  assumption_rows("F", "Fbar_ages", "3–7", cfg_reference,
    "Native Fbar is the arithmetic mean over ages 3–7."),
  assumption_rows("M", "natural_mortality", "Fixed at 0.2 per year for ages 1–10",
    data_reference, "Natural mortality is supplied as a time-invariant age vector and is not estimated."),
  assumption_rows("catch", "observation_model", "Lognormal catch-at-age",
    cfg_reference, "Catch observation variance is shared over ages 1–10; zero catches are omitted from the lognormal likelihood."),
  assumption_rows("catch", "relative_precision_weight", "1 for 1957–2024; 0.5 for 2025",
    paste0(run_url, "/src/datascript.R; fit$data$weight"),
    "fixVarToWeight=0, so the final-year weight modifies relative precision rather than fixing the variance."),
  assumption_rows("index", "observation_model", "Lognormal age-specific indices",
    cfg_reference, "Native index values and scales are retained."),
  assumption_rows("index", "observation_correlation", "Catch ID; summer AR(1); spring AR(1)",
    cfg_reference, "The translated tinyAM model uses independent index residuals."),
  assumption_rows("index", "catchability_age_groups",
    "Summer: ages 1–6 distinct, ages 7–8 shared; spring: ages 1–5 distinct, ages 6–7 shared",
    cfg_reference, "Read from keyLogFpar; no q parameter is fitted for unsampled ages."),
  assumption_rows("index", "observation_variance_sharing",
    "Summer: ages 1–2 share, ages 3–8 share; spring: age 1 separate, ages 2–7 share",
    cfg_reference, "Read from keyVarObs."),
  assumption_rows("index", "survey_timing", "0.65", data_reference,
    "Native sampling time as a proportion of the model year.", survey = "FO-GFS-Q3"),
  assumption_rows("index", "survey_timing", "0.225", data_reference,
    "Native sampling time as a proportion of the model year.", survey = "FO-GFS-Q1"),
  assumption_rows("biology", "annual_inputs",
    "Stock, catch, landings, and discard weights; maturity; fixed M; landings fraction; spawning-time fractions",
    data_reference, "Native source surfaces are preserved on their original year-age grid."),
  assumption_rows("assessment", "fit_diagnostics",
    paste0("optimizer code ", fit$opt$convergence, "; ", fit$opt$message,
      "; objective ", signif(fit$opt$objective, 9)),
    paste0(run_url, "/run/model.RData"),
    paste0("Positive-definite Hessian: ", isTRUE(fit$sdrep$pdHess),
      "; maximum absolute fixed-effect gradient: ",
      signif(max(abs(fit$sdrep$gradient.fixed)), 5), "."))
))

output_rows <- function(type, measure, year = NA_integer_, age = NA_integer_,
                        age_group = "", value, unit, se = NA_real_,
                        lwr = NA_real_, upr = NA_real_, fleet = "", survey = "",
                        source_type = "native_model", source_reference, notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  out <- empty_rows(schemas$outputs, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$fleet <- recycle(fleet)
  out$survey <- recycle(survey)
  out$year <- ifelse(is.na(recycle(year)), "", as.character(recycle(year)))
  out$age <- ifelse(is.na(recycle(age)), "", as.character(recycle(age)))
  out$age_group <- recycle(age_group)
  out$value <- value_text(recycle(value))
  out$se <- value_text(recycle(se))
  out$lwr <- value_text(recycle(lwr))
  out$upr <- value_text(recycle(upr))
  out$unit <- recycle(unit)
  out$source_type <- recycle(source_type)
  out$source_reference <- recycle(source_reference)
  out$notes <- recycle(notes)
  out
}

z <- stats::qnorm(0.975)
random_sd <- function(name) {
  state <- fit$pl[[name]]
  ix <- which(names(fit$sdrep$par.random) == name)
  if (length(ix) != length(state) ||
    max(abs(unname(fit$sdrep$par.random[ix]) - as.vector(state))) > 1e-10 ||
    !isTRUE(all.equal(
      sqrt(fit$sdrep$diag.cov.random[ix]),
      as.vector(fit$plsd[[name]]), tolerance = 1e-8
    ))) {
    stop("SAM random-effect uncertainty does not align for ", name, ".", call. = FALSE)
  }
  matrix(sqrt(fit$sdrep$diag.cov.random[ix]), nrow = nrow(state), ncol = ncol(state))
}
state_outputs <- function(state, measure, unit, log_est, log_se) {
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  estimate <- as.vector(t(exp(log_est)))
  error <- as.vector(t(log_se))
  output_rows(
    if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age,
    ifelse(grid$age == max(ages), paste0(max(ages), "+"), ""),
    estimate, unit, se = estimate * error,
    lwr = exp(as.vector(t(log_est - z * log_se))),
    upr = exp(as.vector(t(log_est + z * log_se))),
    source_reference = paste0(run_url, "/run/model.RData; fit$pl$", state),
    notes = paste0("Native SAM ", measure,
      "; conditional random-effect covariance, delta-method standard error, and 95% log-scale Wald limits. Age 10 is the plus group.")
  )
}
n_log <- fit$pl$logN
n_log_se <- random_sd("logN")
f_log <- rbind(fit$pl$logF, fit$pl$logF[9L, , drop = FALSE])
f_log_se <- rbind(random_sd("logF"), random_sd("logF")[9L, , drop = FALSE])
if (!identical(dim(n_log), c(10L, 69L)) ||
  !identical(dim(f_log), c(10L, 69L)) ||
  any(!is.finite(n_log)) || any(!is.finite(f_log))) {
  stop("SAM abundance or fishing-mortality states have unexpected dimensions.", call. = FALSE)
}

derived_output <- function(parameter, type, measure, unit, age = NA_integer_,
                           age_group = "", notes) {
  value_index <- which(names(fit$sdrep$value) == parameter)
  if (length(value_index) != length(years)) {
    stop("Could not align native SAM derived output ", parameter, ".", call. = FALSE)
  }
  log_est <- fit$sdrep$value[value_index]
  log_se <- fit$sdrep$sd[value_index]
  estimate <- exp(log_est)
  output_rows(
    type, measure, year = years, age = age, age_group = age_group,
    value = estimate, unit = unit, se = estimate * log_se,
    lwr = exp(log_est - z * log_se), upr = exp(log_est + z * log_se),
    source_reference = paste0(run_url, "/run/model.RData; fit$sdrep$", parameter),
    notes = paste0(notes, " Natural-scale SE and 95% Wald limits use the log-scale SAM estimate and uncertainty.")
  )
}

q_rows <- list()
for (fleet_id in 2:3) {
  q_ages <- which(fit$conf$keyLogFpar[fleet_id, ] >= 0)
  key <- as.integer(fit$conf$keyLogFpar[fleet_id, q_ages]) + 1L
  log_est <- fit$pl$logFpar[key]
  log_se <- fit$plsd$logFpar[key]
  q_value <- exp(log_est)
  q_rows[[fleet_id]] <- output_rows(
    "catchability", "q", age = q_ages, value = q_value,
    unit = "native index units per thousand fish",
    se = q_value * log_se, lwr = exp(log_est - z * log_se),
    upr = exp(log_est + z * log_se), survey = survey_codes[fleet_id],
    source_reference = paste0(run_url, "/run/model.RData; fit$pl$logFpar and fit$conf$keyLogFpar"),
    notes = "Exponentiated fitted SAM log-q; age groups share parameters according to the native keyLogFpar matrix. Intervals are 95% log-scale Wald limits."
  )
}

predicted <- exp(as.numeric(fit$rep$predObs))
if (length(predicted) != nrow(aux) || any(!is.finite(predicted))) {
  stop("Native SAM fitted observations do not align with the observation map.", call. = FALSE)
}
catch_i <- which(aux$fleet == 1L)
index_i <- which(aux$fleet > 1L)
outputs <- rbind(
  state_outputs("logN", "numbers_at_age", "thousand fish", n_log, n_log_se),
  state_outputs("logF", "fishing_mortality_at_age", "per year", f_log, f_log_se),
  do.call(rbind, q_rows),
  output_rows("catch", "predicted_catch", year = aux$year[catch_i],
    age = aux$age[catch_i], value = predicted[catch_i], unit = "thousand fish",
    fleet = fleet_names[1L],
    source_reference = paste0(run_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-catch predictions, including the 41 zero-catch source slots excluded from the lognormal likelihood."),
  output_rows("index", "predicted_index", year = aux$year[index_i],
    age = aux$age[index_i], value = predicted[index_i],
    unit = "native survey-index units", survey = survey_codes[aux$fleet[index_i]],
    source_reference = paste0(run_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-index predictions."),
  derived_output("logR", "recruitment", "recruitment", "thousand fish",
    age = 1L, age_group = "age 1", notes = "Native SAM age-1 recruitment."),
  derived_output("logssb", "biomass", "SSB", "tonnes",
    notes = "Native SAM spawning-stock biomass."),
  derived_output("logtsb", "biomass", "total_biomass", "tonnes",
    notes = "Native SAM total stock biomass."),
  derived_output("logfbar", "mortality", "Fbar", "per year",
    age_group = "3-7", notes = "Native SAM Fbar over ages 3–7."),
  output_rows("population", "total_numbers", year = years,
    value = rowSums(t(exp(n_log))), unit = "thousand fish",
    source_type = "derived_source_output",
    source_reference = paste0(run_url, "/run/model.RData; sum(exp(fit$pl$logN))"),
    notes = "Derived by summing native SAM N-at-age over ages 1–10+; uncertainty is not available for this derived total.")
)

n_surface <- t(exp(n_log))
f_surface <- t(exp(f_log))
stock_weight <- dat$stockMeanWeight
maturity <- dat$propMat
if (max(abs(rowSums(n_surface * stock_weight * maturity) -
  exp(fit$sdrep$value[names(fit$sdrep$value) == "logssb"]))) > 1e-6 ||
  max(abs(rowMeans(f_surface[, 3:7, drop = FALSE]) -
    exp(fit$sdrep$value[names(fit$sdrep$value) == "logfbar"]))) > 1e-8 ||
  max(abs(n_surface[, 1L] -
    exp(fit$sdrep$value[names(fit$sdrep$value) == "logR"]))) > 1e-8) {
  stop("Native SAM SSB, Fbar, or recruitment does not match its defining surface.", call. = FALSE)
}
if (any(!is.finite(as.numeric(outputs$value))) ||
  anyDuplicated(paste(outputs$type, outputs$measure, outputs$year,
    outputs$age, outputs$survey, sep = "\r"))) {
  stop("Imported output values are non-finite or have duplicate keys.", call. = FALSE)
}

stocks <- read_db("stocks.csv")
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) stop("Expected one Charbonneau–Keith stock row.", call. = FALSE)
assessments <- read_db("assessments.csv")
if (assessment_id %in% assessments$assessment_id) {
  stop("The 2025 Faroe haddock assessment is already registered.", call. = FALSE)
}
stocks$authority_stock_id[stock_row] <- "had.27.5b"
stocks$common_name[stock_row] <- "Faroe haddock"
stocks$area[stock_row] <- "ICES Division 5.b (Faroe Grounds)"
stocks$region[stock_row] <- "Faroe Grounds"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Matched to the official ICES stock code had.27.5b.",
  "The 2025 NWWG2025_had SAM production run is represented by the current assessment record."
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "annual",
  model_family = "SAM",
  model_version = paste0("stockassessment ", attr(fit, "Version"),
    " (", attr(fit, "RemoteSha"), ")"),
  is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = advice_url, framework_url = "",
  data_url = paste0(run_url, "/run/data.RData"),
  model_url = paste0(run_url, "/run/model.RData"), repository_url = "",
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste0("Official 2025 ICES assessment run NWWG2025_had. The selected SAM fit converged with optimizer code 0 and a positive-definite Hessian; maximum absolute fixed-effect gradient is ",
    signif(max(abs(fit$sdrep$gradient.fixed)), 4), "."),
  stringsAsFactors = FALSE, check.names = FALSE
)

if (!identical(names(assessment), schemas$assessments) ||
  !identical(names(inputs), schemas$inputs) ||
  !identical(names(outputs), schemas$outputs) ||
  !identical(names(assumptions), schemas$assumptions)) {
  stop("Unexpected database schema.", call. = FALSE)
}
append_rows <- function(file, rows) {
  path <- file.path(database, file)
  if (!identical(names(read.csv(path, nrows = 0, check.names = FALSE)), names(rows))) {
    stop("Unexpected schema for ", file, ".", call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
stocks_path <- file.path(database, "stocks.csv")
stock_record <- paste(capture.output(utils::write.table(
  stocks[stock_row, , drop = FALSE], sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, na = ""
)), collapse = "")
stock_record <- sub("\r$", "", stock_record)
stock_bytes <- readBin(stocks_path, "raw", n = file.info(stocks_path)$size)
stock_key <- charToRaw(paste0('"', stock_id, '"'))
candidate_starts <- which(stock_bytes == stock_key[1L])
matching_starts <- candidate_starts[vapply(candidate_starts, function(i) {
  j <- i + length(stock_key) - 1L
  j <= length(stock_bytes) &&
    identical(stock_bytes[i:j], stock_key)
}, logical(1))]
if (length(matching_starts) != 1L) {
  stop("Could not locate the existing stock record for a line-preserving update.", call. = FALSE)
}
stock_start <- matching_starts[[1L]]
newline_relative <- which(stock_bytes[seq.int(stock_start, length(stock_bytes))] == as.raw(10))[1L]
if (is.na(newline_relative)) {
  stop("The existing stock row does not end with a newline.", call. = FALSE)
}
newline_position <- stock_start + newline_relative - 1L
row_end <- newline_position - 1L
if (stock_bytes[row_end] == as.raw(13)) row_end <- row_end - 1L
prefix <- if (stock_start > 1L) stock_bytes[seq_len(stock_start - 1L)] else raw()
suffix <- stock_bytes[seq.int(row_end + 1L, length(stock_bytes))]
writeBin(c(prefix, charToRaw(enc2utf8(stock_record)), suffix), stocks_path)
append_rows("assessments.csv", assessment)
append_rows("assumptions.csv", assumptions)
append_rows("inputs.csv", inputs)
append_rows("outputs.csv", outputs)

cat("Imported Faroe haddock 2025: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n", sep = "")
