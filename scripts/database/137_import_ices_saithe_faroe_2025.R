assessment_id <- "ices_saithe_faroe_2025"
stock_id <- "ck_ices_nwwg_virens_fa5b"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", "ck_ices_nwwg_virens_fa5b_2025")
database <- file.path(base, "database")
run_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "fsaithe-NWWG-2025"
)
advice_url <- "https://asd.ices.dk/viewAdvice/4018"
framework_url <- "https://doi.org/10.17895/ices.pub.21565164"
report_url <- "https://doi.org/10.17895/ices.pub.29086181.v2"
model_file <- file.path(cache, "run", "model.RData")
raw_data_file <- file.path(cache, "run", "data.RData")
catch_file <- file.path(cache, "data", "cn.dat")
survey_file <- file.path(cache, "data", "survey.dat")

required <- c(
  model_file, raw_data_file, catch_file, survey_file,
  file.path(cache, "conf", "model.cfg"),
  file.path(cache, "src", "datascript.R"),
  file.path(cache, "NWWG_2025_Faroe_saithe.pdf"),
  file.path(cache, "ices_sag_stockdata.xml")
)
if (any(!file.exists(required))) {
  stop("The cached Faroe saithe 2025 native assessment sources are incomplete.", call. = FALSE)
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

fit_env <- new.env(parent = baseenv())
load(model_file, envir = fit_env)
fit <- fit_env$fit
data_env <- new.env(parent = baseenv())
load(raw_data_file, envir = data_env)
dat <- fit$data
raw_dat <- data_env$dat
years <- as.integer(dat$years)
ages <- 3:15
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
fleet_names <- as.character(attr(dat, "fleetNames"))
survey_names <- c("", "SummerSurvey", "SpringSurvey")
observed <- is.finite(dat$logobs)
catch_slots <- which(aux$fleet == 1L)
data_surface <- function(x) {
  if (length(dim(x)) == 3L) {
    if (dim(x)[3L] != 1L) stop("Unexpected fleet dimension in a biological surface.", call. = FALSE)
    x <- x[, , 1L]
  }
  as.matrix(x)
}
stock_weight_input <- data_surface(dat$stockMeanWeight)
catch_weight_input <- data_surface(dat$catchMeanWeight)
land_weight_input <- data_surface(dat$landMeanWeight)
discard_weight_input <- data_surface(dat$disMeanWeight)
maturity_input <- data_surface(dat$propMat)
natural_mortality_input <- data_surface(dat$natMor)
landings_fraction_input <- data_surface(dat$landFrac)
pre_spawn_F_input <- data_surface(dat$propF)
pre_spawn_M_input <- data_surface(dat$propM)

read_catch_matrix <- function(path, n_years, age_values) {
  lines <- readLines(path, warn = FALSE)
  values <- scan(text = paste(lines[-seq_len(5L)], collapse = " "), quiet = TRUE)
  n_ages <- length(age_values)
  if (length(values) != n_years * n_ages) {
    stop("The native catch file does not match the model year-age grid.", call. = FALSE)
  }
  matrix(values, nrow = n_years, ncol = n_ages, byrow = TRUE,
    dimnames = list(as.character(years), as.character(age_values)))
}

read_survey_block <- function(path, name) {
  lines <- trimws(readLines(path, warn = FALSE))
  start <- which(lines == name)
  if (length(start) != 1L) stop("Expected one ", name, " source block.", call. = FALSE)
  year_range <- scan(text = lines[start + 1L], quiet = TRUE)
  age_range <- scan(text = lines[start + 3L], quiet = TRUE)
  block_years <- seq.int(as.integer(year_range[1L]), as.integer(year_range[2L]))
  block_ages <- seq.int(as.integer(age_range[1L]), as.integer(age_range[2L]))
  row_lines <- lines[seq.int(start + 4L, start + 3L + length(block_years))]
  rows <- lapply(row_lines, function(line) scan(text = line, quiet = TRUE))
  if (any(lengths(rows) != length(block_ages) + 1L)) {
    stop("The effort and catch rows in ", name, " do not match its age range.", call. = FALSE)
  }
  values <- do.call(rbind, rows)
  list(
    years = block_years,
    ages = block_ages,
    effort = values[, 1L],
    numbers = values[, -1L, drop = FALSE],
    rate = values[, -1L, drop = FALSE] / values[, 1L]
  )
}

catch_at_age <- read_catch_matrix(catch_file, length(years), ages)
survey_data <- list(
  SummerSurvey = read_survey_block(survey_file, "SummerSurvey"),
  SpringSurvey = read_survey_block(survey_file, "SpringSurvey")
)
source_observation <- paste0(run_url, "/run/model.RData; fit$data$logobs and fit$data$aux")
cfg_reference <- paste0(run_url, "/conf/model.cfg; fit$conf")
data_reference <- paste0(run_url, "/run/data.RData; fit$data")
catch_reference <- paste0(run_url, "/data/cn.dat; Table 6.2.2.2 in the 2025 NWWG report")
survey_reference <- paste0(run_url, "/data/survey.dat; Table 6.2.5.1 in the 2025 NWWG report")

if (!inherits(fit, "sam") ||
  !identical(years, 1961:2025) || !identical(ages, 3:15) ||
  !identical(as.integer(dim(aux)), c(1341L, 3L)) ||
  !identical(as.integer(table(aux$fleet)), c(845L, 240L, 256L)) ||
  !identical(fleet_names, c("Residual catch", "SummerSurvey", "SpringSurvey")) ||
  !isTRUE(all.equal(as.numeric(dat$sampleTimes), c(0, 0.65, 0.225), tolerance = 1e-8)) ||
  !isTRUE(all.equal(dat$years, raw_dat$years, check.attributes = FALSE)) ||
  !isTRUE(all.equal(dat$aux, raw_dat$aux, check.attributes = FALSE)) ||
  !isTRUE(all.equal(dat$logobs, raw_dat$logobs, check.attributes = FALSE)) ||
  !isTRUE(all.equal(dat$weight, raw_dat$weight, check.attributes = FALSE)) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 0L, 0L)) ||
  !identical(as.integer(fit$conf$fbarRange), c(4L, 8L)) ||
  !identical(as.integer(fit$conf$keyVarLogN), c(0L, rep(1L, 12L))) ||
  !identical(as.integer(fit$conf$keyLogFsta[1L, ]), c(0:7, rep(8L, 5L))) ||
  !identical(as.integer(fit$conf$keyLogFpar[2L, ]), c(0:5, 6L, 6L, rep(-1L, 5L))) ||
  !identical(as.integer(fit$conf$keyLogFpar[3L, ]), c(7:12, 13L, 13L, rep(-1L, 5L))) ||
  !identical(as.integer(fit$conf$keyVarObs[1L, ]), rep(0L, 13L)) ||
  !identical(as.integer(fit$conf$keyVarObs[2L, ]), c(1:8, rep(-1L, 5L))) ||
  !identical(as.integer(fit$conf$keyVarObs[3L, ]), c(9:16, rep(-1L, 5L))) ||
  !identical(as.integer(fit$conf$obsCorStruct), c(1L, 2L, 2L)) ||
  fit$conf$corFlag != 2L || fit$conf$stockRecruitmentModelCode != 0L ||
  fit$conf$fixVarToWeight != 0L ||
  !identical(as.integer(fit$conf$keyVarF[1L, ]), rep(0L, 13L)) ||
  any(fit$conf$keyQpow != -1L) ||
  any(!is.finite(maturity_input)) || any(!is.finite(natural_mortality_input)) ||
  any(!is.finite(land_weight_input)) || any(!is.finite(discard_weight_input)) ||
  any(!is.finite(landings_fraction_input)) || any(!is.finite(pre_spawn_F_input)) ||
  any(!is.finite(pre_spawn_M_input)) || any(abs(natural_mortality_input - 0.2) > 1e-10) ||
  any(pre_spawn_F_input != 0) || any(pre_spawn_M_input != 0) ||
  sum(!is.finite(stock_weight_input)) != length(ages) ||
  sum(!is.finite(catch_weight_input)) != length(ages) ||
  any(!is.finite(stock_weight_input[-length(years), , drop = FALSE])) ||
  any(!is.finite(catch_weight_input[-length(years), , drop = FALSE])) ||
  !identical(as.integer(table(aux$fleet[!observed])), c(28L)) ||
  any(!is.finite(dat$weight[catch_slots])) ||
  !setequal(unique(dat$weight[catch_slots]), c(0.5, 1)) ||
  sum(catch_at_age == 0) != 28L ||
  !identical(attr(fit, "RemoteSha"), "1cc464b80f6f") ||
  fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  max(abs(fit$sdrep$gradient.fixed)) > 1e-8) {
  stop("The cached model is not the reviewed official Faroe saithe 2025 run.", call. = FALSE)
}

if (!isTRUE(all.equal(
  as.numeric(dat$weight[catch_slots][aux$year[catch_slots] == 2025L]),
  rep(0.5, sum(aux$year[catch_slots] == 2025L)), tolerance = 1e-10
)) || any(dat$weight[catch_slots][aux$year[catch_slots] < 2025L] != 1)) {
  stop("The catch precision weights do not match src/datascript.R.", call. = FALSE)
}
catch_slots_by_age_year <- cbind(
  match(aux$year[catch_slots], years), match(aux$age[catch_slots], ages)
)
source_catch <- catch_at_age[catch_slots_by_age_year]
if (!isTRUE(all.equal(
  source_catch[observed[catch_slots]],
  exp(dat$logobs[catch_slots][observed[catch_slots]]), tolerance = 1e-10
)) || any(source_catch[!observed[catch_slots]] != 0)) {
  stop("The native catch file differs from the fitted SAM catch observations.", call. = FALSE)
}

for (fleet_id in 2:3) {
  name <- survey_names[fleet_id]
  block <- survey_data[[name]]
  slots <- which(aux$fleet == fleet_id)
  source_rate <- block$rate[cbind(match(aux$year[slots], block$years),
    match(aux$age[slots], block$ages))]
  if (!identical(block$ages, 3:10) ||
    !identical(block$years, if (fleet_id == 2L) 1996:2025 else 1994:2025) ||
    !isTRUE(all.equal(source_rate, exp(dat$logobs[slots]), tolerance = 1e-10))) {
    stop("The source effort and age counts do not match the fitted ", name,
      " observations.", call. = FALSE)
  }
}

input_rows <- function(type, measure, basis, year = NA_integer_, age = NA_integer_,
                       value, unit, fleet = "", survey = "", sampling_time = NA_real_,
                       source_type = "native_model", source_reference,
                       transformation = "", notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  out <- empty_rows(schemas$inputs, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- recycle(basis)
  out$fleet <- recycle(fleet)
  out$survey <- recycle(survey)
  out$year <- ifelse(is.na(recycle(year)), "", as.character(recycle(year)))
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
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("Unexpected dimensions in fit$data$", slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  values <- as.vector(x)
  available <- is.finite(values)
  input_rows(type, measure, basis, grid$year[available], grid$age[available],
    values[available], unit,
    source_reference = paste0(data_reference, "$", slot), notes = notes)
}

constant_age_input <- function(x, measure, basis, unit, slot, notes) {
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages))) ||
    any(apply(x, 2L, function(z) diff(range(z))) > 1e-12)) {
    stop("Expected a time-invariant age vector in fit$data$", slot, ".", call. = FALSE)
  }
  input_rows("M", measure, basis, age = ages, value = x[1L, ], unit = unit,
    source_reference = paste0(data_reference, "$", slot), notes = notes)
}

catch_grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
inputs <- input_rows(
  "catch", "numbers_at_age", "numbers", catch_grid$year, catch_grid$age,
  as.vector(catch_at_age), "thousand fish",
  fleet = "Residual catch", source_reference = catch_reference,
  transformation = "Removed the source age-0 column; retained model ages 3–15.",
  notes = "Total commercial catch-at-age in thousands of fish. Age 15 is the catch plus group. The 28 source zero catches are preserved and excluded from the lognormal likelihood."
)
inputs <- rbind(inputs, input_rows(
  "catch", "relative_precision_weight", "relative_precision",
  aux$year[catch_slots], aux$age[catch_slots], dat$weight[catch_slots],
  "relative weight", fleet = "Residual catch",
  source_reference = paste0(run_url, "/src/datascript.R; catch weight attribute"),
  transformation = "Matched fit$data$weight to the catch year-age slots.",
  notes = "fixVarToWeight=0: weights modify relative precision and do not fix observation variances. Catch weights are 1 through 2024 and 0.5 in 2025."
))

for (fleet_id in 2:3) {
  survey <- survey_names[fleet_id]
  block <- survey_data[[survey]]
  sample_time <- dat$sampleTimes[fleet_id]
  grid <- expand.grid(year = block$years, age = block$ages,
    KEEP.OUT.ATTRS = FALSE)
  index_measure <- as.vector(block$rate)
  index_counts <- as.vector(block$numbers)
  sampling_times <- rep(sample_time, length(index_measure))
  inputs <- rbind(inputs,
    input_rows("index", "numbers_at_age", "numbers", grid$year, grid$age,
      index_measure, "fish per effort-hour", survey = survey,
      sampling_time = sampling_times, source_reference = survey_reference,
      transformation = "Divided the source survey catch-at-age by annual survey effort in hours, matching stockassessment::read.ices() and the SAM likelihood scale.",
      notes = "Age-specific survey index retained on the official per-effort scale."),
    input_rows("index", "index_catch_numbers_at_age", "numbers",
      grid$year, grid$age, index_counts, "fish", survey = survey,
      source_reference = survey_reference,
      transformation = "Retained the numerator from the official survey catch-at-age and effort table.",
      notes = "Source numerator used to reproduce the SAM per-effort index; these values are not an additional observation series."),
    input_rows("covariate", "effort", "native_covariate", year = block$years,
      value = block$effort, unit = "hours", survey = survey,
      source_reference = survey_reference,
      notes = "Annual survey effort used as the denominator of the age-specific index.")
  )
}

inputs <- rbind(inputs,
  surface_input(stock_weight_input, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "stockMeanWeight", "Annual source stock weight-at-age; 2025 is missing in the input file and estimated by SAM."),
  surface_input(catch_weight_input, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "catchMeanWeight", "Annual source catch weight-at-age; 2025 is missing in the input file and estimated by SAM."),
  surface_input(land_weight_input, "catch_weight", "landings_weight_at_age", "kg_per_fish",
    "kg per fish", "landMeanWeight", "Annual landings weight-at-age."),
  surface_input(discard_weight_input, "catch_weight", "discard_weight_at_age", "kg_per_fish",
    "kg per fish", "disMeanWeight", "Annual discard weight-at-age."),
  surface_input(maturity_input, "maturity", "maturity_at_age", "proportion",
    "proportion", "propMat", "Annual maturity-at-age."),
  constant_age_input(natural_mortality_input, "natural_mortality_at_age", "per_year",
    "per year", "natMor", "Natural mortality is fixed at 0.2 per year."),
  surface_input(landings_fraction_input, "catch", "landings_fraction_at_age", "proportion",
    "proportion", "landFrac", "Annual landings fraction at age."),
  surface_input(pre_spawn_F_input, "biology", "fraction_F_before_spawning", "proportion",
    "proportion", "propF", "Fraction of annual F applied before spawning; source values are zero."),
  surface_input(pre_spawn_M_input, "biology", "fraction_M_before_spawning", "proportion",
    "proportion", "propM", "Fraction of annual M applied before spawning; source values are zero.")
)

imported_observations <- inputs[inputs$measure == "numbers_at_age", , drop = FALSE]
imported_stream <- ifelse(imported_observations$type == "catch",
  imported_observations$fleet, imported_observations$survey)
native_key <- paste(aux$year, aux$age, fleet_names[aux$fleet], sep = "\r")
imported_key <- paste(imported_observations$year, imported_observations$age,
  imported_stream, sep = "\r")
native_match <- match(imported_key, native_key)
native_values <- exp(dat$logobs)
native_values[catch_slots] <- source_catch
if (anyNA(native_match) || !isTRUE(all.equal(
  as.numeric(imported_observations$value), native_values[native_match],
  tolerance = 1e-12, check.attributes = FALSE
))) {
  cli::cli_abort("Imported observations do not match the native SAM year, age, and fleet map.")
}

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
  assumption_rows("population", "years_and_ages", "1961–2025; ages 3–15+",
    cfg_reference, "Age 15 is the catch and population plus group; surveys cover ages 3–10."),
  assumption_rows("population", "recruitment_age", "3", cfg_reference,
    "Recruitment is the beginning-of-year population at age 3."),
  assumption_rows("N", "recruitment_process", "stockRecruitmentModelCode=0 (random walk)",
    cfg_reference, "SAM uses a random walk for recruitment."),
  assumption_rows("N", "process_variance_sharing", "Age 3 separate; ages 4–15 share one variance",
    cfg_reference, "Read from keyVarLogN."),
  assumption_rows("F", "age_state_sharing", "Ages 3–10 distinct; ages 11–15 share one F state",
    cfg_reference, "Read from keyLogFsta; the shared state contributes once to the process."),
  assumption_rows("F", "process", "AR(1) correlation across F age states",
    cfg_reference, "corFlag=2."),
  assumption_rows("F", "process_variance_sharing", "One F process variance across estimated ages",
    cfg_reference, "Read from keyVarF."),
  assumption_rows("F", "Fbar_ages", "4–8", cfg_reference,
    "Native Fbar is the arithmetic mean over ages 4–8."),
  assumption_rows("M", "natural_mortality", "Fixed at 0.2 per year for ages 3–15",
    data_reference, "M is supplied as a time-invariant age vector and is not estimated."),
  assumption_rows("catch", "observation_model", "Lognormal catch-at-age",
    cfg_reference, "Catch observation variance is shared over ages 3–15; zero catches are omitted from the lognormal likelihood."),
  assumption_rows("catch", "relative_precision_weight", "1 for 1961–2024; 0.5 for 2025",
    paste0(run_url, "/src/datascript.R; fit$data$weight"),
    "fixVarToWeight=0, so the terminal-year weight changes relative precision rather than fixing the variance."),
  assumption_rows("index", "observation_model", "Lognormal age-specific survey indices",
    cfg_reference, "Survey catch numbers-at-age are divided by annual effort before fitting."),
  assumption_rows("index", "observation_correlation", "Catch ID; summer AR(1); spring AR(1)",
    cfg_reference, "tinyAM does not represent the source age correlation in survey residuals."),
  assumption_rows("index", "catchability_age_groups",
    "Both surveys: ages 3–8 distinct; ages 9–10 share one q",
    cfg_reference, "Read from keyLogFpar; no q is fitted for unsampled ages 11–15."),
  assumption_rows("index", "observation_variance_sharing",
    "Each survey has a separate observation variance at ages 3–10",
    cfg_reference, "Read from keyVarObs."),
  assumption_rows("index", "survey_timing", "0.65", data_reference,
    "Native sampling time as a proportion of model year; the source survey window is 0.60–0.70.", survey = "SummerSurvey"),
  assumption_rows("index", "survey_timing", "0.225", data_reference,
    "Native sampling time as a proportion of model year; the source survey window is 0.20–0.25.", survey = "SpringSurvey"),
  assumption_rows("biology", "annual_inputs",
    "Stock, catch, landings, and discard weights; maturity; fixed M; landings fraction; spawning-time fractions",
    data_reference, "Original annual input surfaces are retained. SAM estimates missing terminal stock and catch weights internally."),
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
    !isTRUE(all.equal(sqrt(fit$sdrep$diag.cov.random[ix]),
      as.vector(fit$plsd[[name]]), tolerance = 1e-8))) {
    stop("SAM random-effect uncertainty does not align for ", name, ".", call. = FALSE)
  }
  matrix(sqrt(fit$sdrep$diag.cov.random[ix]), nrow = nrow(state), ncol = ncol(state))
}

state_outputs <- function(measure, unit, estimate_log, se_log, age_values) {
  grid <- expand.grid(year = years, age = age_values, KEEP.OUT.ATTRS = FALSE)
  estimate <- as.vector(t(exp(estimate_log)))
  error <- as.vector(t(se_log))
  output_rows(
    if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age,
    ifelse(grid$age == max(ages), paste0(max(ages), "+"), ""),
    estimate, unit, se = estimate * error,
    lwr = exp(as.vector(t(estimate_log - z * se_log))),
    upr = exp(as.vector(t(estimate_log + z * se_log))),
    source_reference = paste0(run_url, "/run/model.RData; fit$pl$", if (measure == "numbers_at_age") "logN" else "logF"),
    notes = paste0("Native SAM ", measure,
      "; conditional random-effect covariance, delta-method SE, and 95% log-scale Wald limits. Age 15 is the plus group.")
  )
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
  output_rows(type, measure, year = years, age = age, age_group = age_group,
    value = estimate, unit = unit, se = estimate * log_se,
    lwr = exp(log_est - z * log_se), upr = exp(log_est + z * log_se),
    source_reference = paste0(run_url, "/run/model.RData; fit$sdrep$", parameter),
    notes = paste0(notes, " Natural-scale SE and 95% Wald limits use the log-scale SAM estimate and uncertainty."))
}

derived_surface_output <- function(parameter, measure, unit, notes) {
  ix <- which(names(fit$sdrep$value) == parameter)
  n_rows <- nrow(fit$pl[[parameter]])
  n_cols <- ncol(fit$pl[[parameter]])
  if (length(ix) != n_rows * n_cols || n_cols != length(ages) || n_rows < length(years)) {
    stop("Could not align native SAM biological output ", parameter, ".", call. = FALSE)
  }
  log_est <- matrix(fit$sdrep$value[ix], nrow = n_rows, ncol = n_cols)[seq_along(years), , drop = FALSE]
  log_se <- matrix(fit$sdrep$sd[ix], nrow = n_rows, ncol = n_cols)[seq_along(years), , drop = FALSE]
  grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  estimate <- as.vector(exp(log_est))
  error <- as.vector(log_se)
  output_rows("biology", measure, grid$year, grid$age, value = estimate,
    unit = unit, se = estimate * error,
    lwr = exp(as.vector(log_est - z * log_se)),
    upr = exp(as.vector(log_est + z * log_se)),
    source_reference = paste0(run_url, "/run/model.RData; fit$pl$", parameter),
    notes = paste0(notes, " Native SAM estimated surface; natural-scale delta-method SE and 95% log-scale Wald limits."))
}

f_key <- as.integer(fit$conf$keyLogFsta[1L, ]) + 1L
n_log <- fit$pl$logN
n_log_se <- random_sd("logN")
f_state <- fit$pl$logF
f_state_se <- random_sd("logF")
f_log <- f_state[f_key, , drop = FALSE]
f_log_se <- f_state_se[f_key, , drop = FALSE]
if (!identical(dim(n_log), c(length(ages), length(years))) ||
  !identical(dim(f_log), c(length(ages), length(years))) ||
  any(!is.finite(n_log)) || any(!is.finite(f_log))) {
  stop("SAM abundance or fishing mortality has unexpected dimensions.", call. = FALSE)
}

q_rows <- list()
for (fleet_id in 2:3) {
  positions <- which(fit$conf$keyLogFpar[fleet_id, ] >= 0)
  key <- as.integer(fit$conf$keyLogFpar[fleet_id, positions]) + 1L
  q_log <- fit$pl$logFpar[key]
  q_log_se <- fit$plsd$logFpar[key]
  q_value <- exp(q_log)
  q_rows[[fleet_id]] <- output_rows(
    "catchability", "q", age = ages[positions], value = q_value,
    unit = "fish per effort-hour per thousand fish",
    se = q_value * q_log_se, lwr = exp(q_log - z * q_log_se),
    upr = exp(q_log + z * q_log_se), survey = survey_names[fleet_id],
    source_reference = paste0(run_url, "/run/model.RData; fit$pl$logFpar and fit$conf$keyLogFpar"),
    notes = "Exponentiated fitted SAM log-q; ages 9–10 share a parameter. Intervals are 95% log-scale Wald limits."
  )
}

predicted <- exp(as.numeric(fit$rep$predObs))
if (length(predicted) != nrow(aux) || any(!is.finite(predicted))) {
  stop("Native SAM fitted observations do not align with the observation map.", call. = FALSE)
}
catch_i <- which(aux$fleet == 1L)
index_i <- which(aux$fleet > 1L)
n_surface <- t(exp(n_log))
f_surface <- t(exp(f_log))
sw <- exp(fit$pl$logSW[seq_along(years), , drop = FALSE])
if (length(dim(fit$pl$logCW)) == 3L) {
  cw <- exp(fit$pl$logCW[seq_along(years), , 1L])
} else {
  cw <- exp(fit$pl$logCW[seq_along(years), , drop = FALSE])
}
ssb_native <- exp(fit$sdrep$value[names(fit$sdrep$value) == "logssb"])
tsb_native <- exp(fit$sdrep$value[names(fit$sdrep$value) == "logtsb"])
fbar_native <- exp(fit$sdrep$value[names(fit$sdrep$value) == "logfbar"])
recruitment_native <- exp(fit$sdrep$value[names(fit$sdrep$value) == "logR"])
if (max(abs(rowSums(n_surface * sw * dat$propMat) - ssb_native)) > 1e-6 ||
  max(abs(rowSums(n_surface * sw) - tsb_native)) > 1e-6 ||
  max(abs(rowMeans(f_surface[, match(4:8, ages), drop = FALSE]) - fbar_native)) > 1e-8 ||
  max(abs(n_surface[, 1L] - recruitment_native)) > 1e-8 ||
  abs(recruitment_native[length(years)] - 23847) > 1 ||
  abs(ssb_native[length(years)] - 57509) > 1 ||
  abs(tsb_native[length(years)] - 118012) > 1 ||
  abs(fbar_native[length(years)] - 0.48) > 0.001) {
  stop("Native derived quantities do not match their definitions and 2025 ICES table.", call. = FALSE)
}

outputs <- rbind(
  state_outputs("numbers_at_age", "thousand fish", n_log, n_log_se, ages),
  state_outputs("fishing_mortality_at_age", "per year", f_log, f_log_se, ages),
  do.call(rbind, q_rows),
  output_rows("catch", "predicted_catch", year = aux$year[catch_i],
    age = aux$age[catch_i], value = predicted[catch_i], unit = "thousand fish",
    fleet = fleet_names[1L], source_reference = paste0(run_url,
      "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-catch predictions, including source zero-catch slots excluded from the lognormal likelihood."),
  output_rows("index", "predicted_index", year = aux$year[index_i],
    age = aux$age[index_i], value = predicted[index_i], unit = "fish per effort-hour",
    survey = survey_names[aux$fleet[index_i]], source_reference = paste0(run_url,
      "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-index predictions on the per-effort scale."),
  derived_output("logR", "recruitment", "recruitment", "thousand fish",
    age = 3L, age_group = "age 3", notes = "Native SAM age-3 recruitment."),
  derived_output("logssb", "biomass", "SSB", "tonnes",
    notes = "Native SAM spawning-stock biomass."),
  derived_output("logtsb", "biomass", "total_biomass", "tonnes",
    notes = "Native SAM total stock biomass."),
  derived_output("logfbar", "mortality", "Fbar", "per year",
    age_group = "4-8", notes = "Native SAM Fbar over ages 4–8."),
  output_rows("population", "total_numbers", year = years,
    value = rowSums(n_surface), unit = "thousand fish",
    source_type = "derived_source_output",
    source_reference = paste0(run_url, "/run/model.RData; sum(exp(fit$pl$logN))"),
    notes = "Derived by summing SAM N-at-age over ages 3–15+; uncertainty is not available for this derived sum."),
  derived_surface_output("logSW", "weight_at_age", "kg per fish",
    "SAM-estimated stock weight-at-age; includes model estimates where the source input file has no terminal-year weight."),
  derived_surface_output("logCW", "catch_weight_at_age", "kg per fish",
    "SAM-estimated catch weight-at-age; includes model estimates where the source input file has no terminal-year weight.")
)

if (!identical(names(outputs), schemas$outputs) ||
  any(!is.finite(suppressWarnings(as.numeric(outputs$value)))) ||
  anyDuplicated(paste(outputs$type, outputs$measure, outputs$year,
    outputs$age, outputs$survey, outputs$fleet, sep = "\r"))) {
  stop("Imported SAM outputs have invalid values or duplicate keys.", call. = FALSE)
}

stocks <- read_db("stocks.csv")
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L ||
  stocks$charbonneau_id[stock_row] != "ICES-NWWG_virens_FA5b") {
  stop("The existing Charbonneau–Keith Faroe saithe stock match is ambiguous.", call. = FALSE)
}
assessments <- read_db("assessments.csv")
existing_assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
if (nrow(existing_assessment) > 1L ||
  nrow(existing_assessment) == 1L && existing_assessment$stock_id != stock_id) {
  cli::cli_abort("The existing Faroe saithe assessment does not identify the expected stock.")
}
stocks$authority_stock_id[stock_row] <- "pok.27.5b"
stocks$common_name[stock_row] <- "Faroe saithe"
stocks$area[stock_row] <- "ICES Division 5.b (Faroe Grounds)"
stocks$region[stock_row] <- "Faroe Grounds"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Matched the existing Charbonneau–Keith stock record to official ICES stock pok.27.5b.",
  "The detailed 2025 NWWG production run fsaithe-NWWG-2025 is represented by the current assessment record."
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "annual",
  model_family = "SAM",
  model_version = paste0("stockassessment ", attr(fit, "Version"),
    " (", attr(fit, "RemoteSha"), ")"),
  is_current = TRUE, is_applied = TRUE, framework_year = "2017",
  assessment_url = advice_url, framework_url = framework_url,
  data_url = paste0(run_url, "/run/data.RData"),
  model_url = paste0(run_url, "/run/model.RData"), repository_url = "",
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste0("Official 2025 ICES assessment, run fsaithe-NWWG-2025. The SAM fit converged with optimizer code 0 and a positive-definite Hessian; maximum absolute fixed-effect gradient is ",
    signif(max(abs(fit$sdrep$gradient.fixed)), 4), "."),
  stringsAsFactors = FALSE, check.names = FALSE
)

if (!identical(names(assessment), schemas$assessments) ||
  !identical(names(inputs), schemas$inputs) ||
  !identical(names(outputs), schemas$outputs) ||
  !identical(names(assumptions), schemas$assumptions)) {
  stop("Unexpected database schema.", call. = FALSE)
}

write_source_rows <- function(file, rows, id = assessment_id) {
  path <- file.path(database, file)
  if (!identical(names(read.csv(path, nrows = 0, check.names = FALSE)), names(rows))) {
    stop("Unexpected schema for ", file, ".", call. = FALSE)
  }
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', id, '",')))
  if (!length(selected)) {
    utils::write.table(rows, path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
    return(invisible(NULL))
  }
  if (length(selected) != nrow(rows)) {
    cli::cli_abort("Existing {.file {file}} rows have unexpected coverage for this assessment.")
  }
  existing <- utils::read.csv(text = paste(lines[selected], collapse = "\n"),
    header = FALSE, col.names = names(rows), colClasses = "character",
    na.strings = "", check.names = FALSE)
  normalized <- function(x) {
    out <- vapply(x, as.character, character(nrow(x)))
    out[is.na(out)] <- ""
    unname(out)
  }
  if (identical(normalized(existing), normalized(rows))) return(invisible(NULL))
  stage <- tempfile(tmpdir = dirname(path))
  on.exit(unlink(stage), add = TRUE)
  utils::write.table(rows, stage, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(stage, warn = FALSE, encoding = "UTF-8")
  lines[selected] <- paste0(enc2utf8(replacement),
    ifelse(endsWith(lines[selected], "\r"), "\r", ""))
  writeBin(charToRaw(paste0(paste(lines, collapse = "\n"),
    if (endsWith(contents, "\n")) "\n" else "")), stage)
  if (!file.copy(stage, path, overwrite = TRUE)) {
    cli::cli_abort("Could not replace {.file {file}} with the verified assessment rows.")
  }
}
write_source_rows("stocks.csv", stocks[stock_row, , drop = FALSE], id = stock_id)
write_source_rows("assessments.csv", assessment)
write_source_rows("assumptions.csv", assumptions)
write_source_rows("inputs.csv", inputs)
write_source_rows("outputs.csv", outputs)

cat("Imported Faroe saithe 2025: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n", sep = "")
