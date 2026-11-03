assessment_id <- "ices_saithe_northeast_arctic_2026"
stock_id <- "ck_ices_afwg_virens_nea_1_2"
root <- "."
cache_dir <- file.path(root, "source_cache", "ices_nea_saithe_2026")
run_dir <- file.path(cache_dir, "NEA_saithe_2026_v2")

required_files <- file.path(run_dir, c(
  "run/data.RData", "run/model.RData", "run/ver",
  "data/coast_survey_cv.dat", "res/xxx-00-00.00.00_tab1.html",
  "res/xxx-00-00.00.00_tab2.html", "res/xxx-00-00.00.00_tab3.html"
))
if (any(!file.exists(required_files))) {
  stop("The cached 2026 v2 SAM source bundle is incomplete.", call. = FALSE)
}

source_env <- new.env(parent = emptyenv())
load(file.path(run_dir, "run/data.RData"), envir = source_env)
dat <- source_env$dat
load(file.path(run_dir, "run/model.RData"), envir = source_env)
fit <- source_env$fit
source_version <- readLines(file.path(run_dir, "run/ver"), warn = FALSE)
if (!any(grepl("Version: 0.12.0", source_version, fixed = TRUE)) ||
  !any(grepl("RemoteSha: 1cc464b80f6f", source_version, fixed = TRUE))) {
  stop("The cached run does not match the reviewed stockassessment version.", call. = FALSE)
}
if (!identical(dat$aux, fit$data$aux) || !identical(dat$logobs, fit$data$logobs) ||
  !identical(dat$weight, fit$data$weight)) {
  stop("The run data and fitted object do not contain the same observations.", call. = FALSE)
}

years <- as.integer(fit$data$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
if (!identical(years, 1960:2025) || !identical(ages, 3:12) ||
  length(fit$conf$keyLogFsta[1, ]) != length(ages) ||
  !isTRUE(fit$conf$maxAgePlusGroup[1] == 1)) {
  stop("Unexpected year, age, or plus-group dimensions in the selected SAM run.", call. = FALSE)
}

year_age <- function(value) {
  if (!identical(dim(value), c(length(years), length(ages)))) {
    stop("Unexpected year-age input dimensions.", call. = FALSE)
  }
  expand.grid(age = ages, year = years)
}
new_input <- function(type, measure, basis, year, age, value, unit,
                      fleet = NA_character_, survey = NA_character_,
                      sampling_time = NA_real_, source_reference,
                      transformation = "Extracted from the fitted SAM data object.",
                      source_type = "native_model", notes = "") {
  n <- length(value)
  repeat_to_n <- function(x) rep(x, length.out = n)
  year <- repeat_to_n(year)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = repeat_to_n(basis), fleet = repeat_to_n(fleet),
    survey = repeat_to_n(survey), sex = NA_character_, region = NA_character_,
    season = NA_character_, year = year,
    year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = repeat_to_n(age), value = value, unit = repeat_to_n(unit),
    sampling_time = repeat_to_n(sampling_time), source_type = source_type,
    source_reference = repeat_to_n(source_reference),
    transformation = repeat_to_n(transformation), notes = repeat_to_n(notes),
    observation_id = NA_character_, length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = NA_character_, partition = NA_character_,
    stringsAsFactors = FALSE
  )
}
new_surface_input <- function(value, type, measure, basis, unit,
                               source_file, source_field, notes = "") {
  grid <- year_age(value)
  new_input(
    type, measure, basis, grid$year, grid$age, as.vector(t(value)), unit,
    source_reference = paste0(
      "NEA_saithe_2026_v2/", source_file, " and run/model.RData fit$data$",
      source_field
    ),
    notes = notes
  )
}
new_assumption <- function(component, setting, value, source_reference,
                           notes = "", survey = NA_character_) {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = survey, sex = NA_character_,
    region = NA_character_, season = NA_character_, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
new_output <- function(type, measure, year, value, unit,
                       age = NA_integer_, age_group = NA_character_,
                       fleet = NA_character_, survey = NA_character_,
                       se = NA_real_, lwr = NA_real_, upr = NA_real_, source_type = "native_model",
                       source_reference, notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = rep(fleet, length.out = n), survey = rep(survey, length.out = n), sex = NA_character_,
    region = NA_character_, season = NA_character_, year = year,
    age = rep(age, length.out = n), age_group = rep(age_group, length.out = n),
    value = value, se = rep(se, length.out = n), lwr = rep(lwr, length.out = n),
    upr = rep(upr, length.out = n), unit = rep(unit, length.out = n),
    source_type = source_type, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}

survey_names <- c(
  `2` = "FLT13 Norwegian acoustic survey",
  `3` = "FLT14 Norwegian acoustic survey"
)
aux <- as.data.frame(dat$aux)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
if (nrow(aux) != length(dat$logobs) || any(!aux$year %in% years) ||
  any(!aux$age %in% ages) || !identical(as.integer(table(aux$fleet)), c(660L, 40L, 120L))) {
  stop("Unexpected observation coverage in the native SAM input object.", call. = FALSE)
}

observation_inputs <- lapply(sort(unique(aux$fleet)), function(fleet_id) {
  i <- aux$fleet == fleet_id
  if (fleet_id == 1L) {
    new_input(
      "catch", "numbers_at_age", "numbers", aux$year[i], aux$age[i],
      exp(dat$logobs[i]), "thousand fish", fleet = "Total catch (FLT1)",
      source_reference = paste0(
        "NEA_saithe_2026_v2/data/cn.dat and run/data.RData dat$aux/dat$logobs"
      ),
      transformation = "Back-transformed log observations; values remain in the native catch unit.",
      notes = "Single combined catch series; ages 3-12, with age 12 the plus group."
    )
  } else {
    survey <- unname(survey_names[as.character(fleet_id)])
    new_input(
      "index", "numbers_at_age", "index_scale", aux$year[i], aux$age[i],
      exp(dat$logobs[i]), "survey index (unit unresolved)",
      survey = survey, sampling_time = dat$sampleTimes[fleet_id],
      source_reference = paste0(
        "NEA_saithe_2026_v2/data/survey.dat and run/data.RData dat$aux/dat$logobs"
      ),
      transformation = "Back-transformed log observations; no abundance-scale multiplier applied.",
      notes = paste0(
        "Age-specific Norwegian acoustic index; FLT", fleet_id,
        " is retained as a separate survey series. Original numerical scale has no reported physical unit."
      )
    )
  }
})
observation_inputs <- do.call(rbind, observation_inputs)

cv_path <- file.path(run_dir, "data/coast_survey_cv.dat")
cv_lines <- readLines(cv_path, warn = FALSE)
cv_table <- utils::read.table(
  text = paste(cv_lines[7:length(cv_lines)], collapse = "\n"),
  header = FALSE
)
cv_years <- 2003:2024
cv_ages <- 3:7
if (!identical(dim(cv_table), c(length(cv_years), length(cv_ages) + 1L)) ||
  any(cv_table[[1]] != 1) || any(!is.finite(as.matrix(cv_table[-1]))) ||
  any(as.matrix(cv_table[-1]) <= 0)) {
  stop("Unexpected Coast survey CV table structure.", call. = FALSE)
}
cv_values <- as.matrix(cv_table[-1])
cv_grid <- expand.grid(age = cv_ages, year = cv_years)
cv_inputs <- new_input(
  "index", "relative_standard_error", "relative_scale",
  cv_grid$year, cv_grid$age, as.vector(t(cv_values)), "relative SE (CV)",
  survey = unname(survey_names["3"]), sampling_time = 0.8,
  source_reference = "NEA_saithe_2026_v2/data/coast_survey_cv.dat",
  transformation = "Transcribed as reported; no age-year reordering or scaling.",
  notes = "The file labels these values StoX CVs. Their pairing with the native fitted relative weights is unresolved; these CVs are retained as a separate source series."
)
weight_index <- aux$fleet == 3L & is.finite(dat$weight)
weight_aux <- aux[weight_index, , drop = FALSE]
precision_inputs <- new_input(
  "index", "relative_precision_weight", "relative_precision",
  weight_aux$year, weight_aux$age, dat$weight[weight_index],
  "relative precision weight", survey = unname(survey_names["3"]),
  sampling_time = 0.8,
  source_reference = "NEA_saithe_2026_v2/run/data.RData dat$weight aligned to dat$aux",
  transformation = "Extracted the exact relative precision weight attached to each fitted observation.",
  notes = paste(
    "fixVarToWeight=0: the model scales log-index SD by 1/sqrt(weight).",
    "Across the 110 fitted observations, the weights match 1/log(1+CV^2) from coast_survey_cv.dat as a set, but not when joined by the source file's year-age labels; no pairing is inferred."
  )
)
if (nrow(cv_inputs) != 110L || nrow(precision_inputs) != 110L ||
  !isTRUE(all.equal(
    sort(precision_inputs$value),
    sort(as.vector(1 / log1p(cv_values^2))), tolerance = 1e-8
  ))) {
  stop("The source CV and fitted relative-weight checks failed.", call. = FALSE)
}

matrix_input <- function(x, dim_names = NULL) {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("A biological input has unexpected dimensions.", call. = FALSE)
  }
  x
}
stock_weight <- matrix_input(fit$data$stockMeanWeight)
catch_weight <- matrix_input(fit$data$catchMeanWeight)
landings_weight <- matrix_input(fit$data$landMeanWeight)
discard_weight <- matrix_input(fit$data$disMeanWeight)
maturity <- matrix_input(fit$data$propMat)
landings_fraction <- matrix_input(fit$data$landFrac)
fraction_F <- matrix_input(fit$data$propF)
fraction_M <- matrix_input(fit$data$propM)
M <- matrix_input(fit$data$natMor)
if (!all(M == M[1L, ]) || !all(landings_weight == catch_weight) ||
  !all(discard_weight == catch_weight)) {
  stop("The reviewed constant M or equal removal-weight structure has changed.", call. = FALSE)
}

biology_inputs <- rbind(
  new_surface_input(stock_weight, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "data/sw.dat", "stockMeanWeight",
    "Annual stock weight-at-age used in the assessment."),
  new_surface_input(catch_weight, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "data/cw.dat", "catchMeanWeight",
    "Annual catch weight-at-age."),
  new_surface_input(landings_weight, "catch_weight", "landings_weight_at_age", "kg_per_fish",
    "kg per fish", "data/lw.dat", "landMeanWeight",
    "Landings weight-at-age; numerically identical to catch and discard weights in this run."),
  new_surface_input(discard_weight, "catch_weight", "discard_weight_at_age", "kg_per_fish",
    "kg per fish", "data/dw.dat", "disMeanWeight",
    "Discard weight-at-age; numerically identical to catch and landings weights in this run."),
  new_surface_input(maturity, "maturity", "maturity_at_age", "proportion",
    "proportion", "data/mo.dat", "propMat",
    "Annual maturity-at-age supplied at the start of the year."),
  new_surface_input(landings_fraction, "biology", "landings_fraction_at_age", "proportion",
    "proportion", "data/lf.dat", "landFrac",
    "Annual fraction of removals assigned to landings; all values are 1."),
  new_surface_input(fraction_F, "biology", "fraction_F_before_spawning", "proportion",
    "proportion", "data/pf.dat", "propF",
    "Fraction of annual fishing mortality before spawning; all values are 0."),
  new_surface_input(fraction_M, "biology", "fraction_M_before_spawning", "proportion",
    "proportion", "data/pm.dat", "propM",
    "Fraction of annual natural mortality before spawning; all values are 0.")
)
mortality_inputs <- new_input(
  "M", "natural_mortality_at_age", "per_year", rep(NA_integer_, length(ages)),
  ages, M[1L, ], "per year",
  source_reference = "NEA_saithe_2026_v2/data/nm.dat and run/model.RData fit$data$natMor",
  transformation = "Collapsed the repeated annual SAM input to its identical time-invariant age vector.",
  notes = "Fixed M=0.2 per year at ages 3-12; not estimated."
)
inputs <- rbind(
  observation_inputs, cv_inputs, precision_inputs, biology_inputs, mortality_inputs
)

logN <- fit$pl$logN
logF <- fit$pl$logF
logN_se <- fit$plsd$logN
logF_se <- fit$plsd$logF
if (!identical(dim(logN), c(length(ages), length(years))) ||
  !identical(dim(logF), c(6L, length(years))) ||
  !identical(dim(logN_se), dim(logN)) ||
  !identical(dim(logF_se), dim(logF)) ||
  any(!is.finite(logN_se)) || any(!is.finite(logF_se))) {
  stop("Unexpected latent-state dimensions in fit$pl.", call. = FALSE)
}
N_surface <- t(exp(logN))
N_log_se <- t(logN_se)
F_state <- t(exp(logF))
F_mapping <- as.integer(fit$conf$keyLogFsta[1, ]) + 1L
F_surface <- F_state[, F_mapping, drop = FALSE]
F_log_se <- t(logF_se)[, F_mapping, drop = FALSE]
colnames(N_surface) <- as.character(ages)
colnames(F_surface) <- as.character(ages)
if (!all(vapply(8:12, function(age) {
  all(F_surface[, as.character(age)] == F_surface[, "8"])
}, logical(1)))) {
  stop("The documented shared F state at ages 8-12 is not present.", call. = FALSE)
}

parse_cells <- function(line) {
  cells <- regmatches(line, gregexpr("<td\\b[^>]*>.*?</td>", line, perl = TRUE))[[1L]]
  cells <- gsub("<[^>]+>", "", cells, perl = TRUE)
  cells <- gsub("&nbsp;", "", cells, fixed = TRUE)
  trimws(cells)
}
parse_report_surface <- function(file, expected_ages) {
  lines <- readLines(file.path(run_dir, "res", file), warn = FALSE)
  rows <- lapply(lines, function(line) {
    cells <- parse_cells(line)
    values <- suppressWarnings(as.numeric(cells))
    if (length(values) != length(expected_ages) + 1L || anyNA(values) ||
      !values[[1L]] %in% years) return(NULL)
    data.frame(year = as.integer(values[[1L]]),
      as.list(stats::setNames(values[-1L], paste0("age", expected_ages))),
      check.names = FALSE)
  })
  out <- do.call(rbind, Filter(Negate(is.null), rows))
  if (nrow(out) != length(years) || !setequal(out$year, years)) {
    stop("The native report age surface has unexpected coverage: ", file, call. = FALSE)
  }
  out
}
report_F <- parse_report_surface("xxx-00-00.00.00_tab2.html", ages)
report_N <- parse_report_surface("xxx-00-00.00.00_tab3.html", ages)
if (max(abs(as.matrix(report_F[-1L]) - F_surface[match(report_F$year, years), ])) > 0.00051 ||
  max(abs(as.matrix(report_N[-1L]) - N_surface[match(report_N$year, years), ])) > 0.51) {
  stop("The fitted model surfaces do not match the selected native report tables.", call. = FALSE)
}

n_rows <- expand.grid(age = ages, year = years)
source_N <- as.vector(t(N_surface))
source_F <- as.vector(t(F_surface))
N_se <- as.vector(t(N_surface * N_log_se))
N_lwr <- as.vector(t(exp(log(N_surface) - stats::qnorm(0.975) * N_log_se)))
N_upr <- as.vector(t(exp(log(N_surface) + stats::qnorm(0.975) * N_log_se)))
F_se <- as.vector(t(F_surface * F_log_se))
F_lwr <- as.vector(t(exp(log(F_surface) - stats::qnorm(0.975) * F_log_se)))
F_upr <- as.vector(t(exp(log(F_surface) + stats::qnorm(0.975) * F_log_se)))
source_group <- ifelse(n_rows$age == 12L, "12+", NA_character_)
age_outputs <- rbind(
  new_output("population", "numbers_at_age", n_rows$year, source_N,
    "thousand fish", age = n_rows$age, age_group = source_group,
    se = N_se, lwr = N_lwr, upr = N_upr,
    source_reference = "NEA_saithe_2026_v2/run/model.RData fit$pl$logN",
    notes = paste(
      "Native SAM fitted number-at-age estimate; age 12 is the 12+ group.",
      "SE is the TMB marginal log-state SE converted by the delta method; limits are a normal-approximation 95% interval on log N."
    )),
  new_output("mortality", "fishing_mortality_at_age", n_rows$year, source_F,
    "per year", age = n_rows$age, age_group = source_group,
    se = F_se, lwr = F_lwr, upr = F_upr,
    source_reference = paste(
      "NEA_saithe_2026_v2/run/model.RData fit$pl$logF and fit$conf$keyLogFsta"
    ),
    notes = paste(
      "Native SAM fitted fishing mortality; ages 8-12 repeat one shared F state,",
      "with age 12 representing the 12+ group.",
      "SE is the TMB marginal log-state SE converted by the delta method; limits are a normal-approximation 95% interval on log F."
    ))
)

summary_lines <- readLines(file.path(run_dir, "res/xxx-00-00.00.00_tab1.html"), warn = FALSE)
summary_rows <- lapply(summary_lines, function(line) {
  values <- suppressWarnings(as.numeric(parse_cells(line)))
  if (length(values) != 13L || anyNA(values) || !values[[1L]] %in% years) return(NULL)
  data.frame(year = as.integer(values[[1L]]),
    recruitment = values[[2L]], recruitment_lwr = values[[3L]],
    recruitment_upr = values[[4L]], ssb_lwr = values[[5L]], SSB = values[[6L]],
    ssb_upr = values[[7L]], Fbar_lwr = values[[8L]], Fbar = values[[9L]],
    Fbar_upr = values[[10L]], TSB_lwr = values[[11L]], TSB = values[[12L]],
    TSB_upr = values[[13L]])
})
summary <- do.call(rbind, Filter(Negate(is.null), summary_rows))
if (nrow(summary) != length(years) || !setequal(summary$year, years)) {
  stop("The native summary table does not cover 1960-2025.", call. = FALSE)
}
interval_note <- paste(
  "Lower and upper values are preserved from the native Low/High columns;",
  "the interval level is not identified in the cached table."
)
summary_outputs <- rbind(
  new_output("recruitment", "recruitment", summary$year, summary$recruitment,
    "thousand fish", age = 3L, age_group = "age 3",
    lwr = summary$recruitment_lwr, upr = summary$recruitment_upr,
    source_type = "native_model",
    source_reference = "NEA_saithe_2026_v2/res/xxx-00-00.00.00_tab1.html, Table 1",
    notes = paste("Recruitment at age 3.", interval_note)),
  new_output("biomass", "SSB", summary$year, summary$SSB, "tonnes",
    lwr = summary$ssb_lwr, upr = summary$ssb_upr,
    source_type = "native_model",
    source_reference = "NEA_saithe_2026_v2/res/xxx-00-00.00.00_tab1.html, Table 1",
    notes = paste("Native SAM spawning-stock biomass.", interval_note)),
  new_output("mortality", "Fbar", summary$year, summary$Fbar, "per year",
    age_group = "4-7", lwr = summary$Fbar_lwr, upr = summary$Fbar_upr,
    source_type = "native_model",
    source_reference = "NEA_saithe_2026_v2/res/xxx-00-00.00.00_tab1.html, Table 1",
    notes = paste("Reported arithmetic Fbar over ages 4-7.", interval_note)),
  new_output("biomass", "total_biomass", summary$year, summary$TSB, "tonnes",
    lwr = summary$TSB_lwr, upr = summary$TSB_upr,
    source_type = "native_model",
    source_reference = "NEA_saithe_2026_v2/res/xxx-00-00.00.00_tab1.html, Table 1",
    notes = paste("Native SAM total-stock biomass.", interval_note))
)

sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22657"
sag_file <- file.path(cache_dir, "ICES_SAG_22657_2026.html")
sag_text <- paste(readLines(sag_file, warn = FALSE), collapse = " ")
sag_rows <- regmatches(sag_text, gregexpr("<tr\\b[^>]*>.*?</tr>", sag_text, perl = TRUE))[[1L]]
forecast_row <- sag_rows[grepl("<td[^>]*>2026</td>", sag_rows, perl = TRUE)]
if (length(forecast_row) != 1L) stop("Could not find the 2026 ICES SAG row.", call. = FALSE)
forecast_values <- suppressWarnings(as.numeric(parse_cells(forecast_row)))
if (length(forecast_values) != 15L || forecast_values[[1L]] != 2026L ||
  forecast_values[[3L]] != 146848 || forecast_values[[9L]] != 204799) {
  stop("Unexpected 2026 forecast values in the cached ICES SAG page.", call. = FALSE)
}
forecast_outputs <- rbind(
  new_output("recruitment", "recruitment", 2026L, forecast_values[[3L]],
    "thousand fish", age = 3L, age_group = "age 3",
    source_type = "official_machine_readable",
    source_reference = sag_url,
    notes = "Official ICES SAG one-year forecast at recruitment age 3; no interval is reported."),
  new_output("biomass", "SSB", 2026L, forecast_values[[9L]], "tonnes",
    source_type = "official_machine_readable",
    source_reference = sag_url,
    notes = "Official ICES SAG one-year forecast; no interval is reported.")
)
if (length(fit$rep$predObs) != nrow(aux) || any(!is.finite(fit$rep$predObs))) {
  stop("The fitted observation predictions do not align with native observations.", call. = FALSE)
}
predicted <- exp(fit$rep$predObs)
prediction_outputs <- do.call(rbind, lapply(sort(unique(aux$fleet)), function(fleet_id) {
  rows <- which(aux$fleet == fleet_id)
  if (fleet_id == 1L) {
    new_output(
      "catch", "predicted_catch", aux$year[rows], predicted[rows], "thousand fish",
      age = aux$age[rows], fleet = "Total catch (FLT1)",
      source_reference = "NEA_saithe_2026_v2/run/model.RData fit$rep$predObs and run/data.RData dat$aux",
      notes = "Back-transformed native model prediction on the catch numbers-at-age scale."
    )
  } else {
    survey <- unname(survey_names[as.character(fleet_id)])
    new_output(
      "index", "predicted_index", aux$year[rows], predicted[rows],
      "survey index (unit unresolved)", age = aux$age[rows], survey = survey,
      source_reference = "NEA_saithe_2026_v2/run/model.RData fit$rep$predObs and run/data.RData dat$aux",
      notes = "Back-transformed native model prediction on the survey's source index scale."
    )
  }
}))

q_outputs <- do.call(rbind, lapply(2:3, function(fleet_id) {
  keys <- as.integer(fit$conf$keyLogFpar[fleet_id, ])
  parameter_keys <- sort(unique(keys[keys >= 0L]))
  do.call(rbind, lapply(parameter_keys, function(key) {
    ages_in_group <- ages[keys == key]
    log_q <- fit$pl$logFpar[key + 1L]
    se_log_q <- fit$plsd$logFpar[key + 1L]
    q <- exp(log_q)
    new_output(
      "catchability", "q", NA_integer_, q,
      "native index scale per thousand fish (physical index unit unresolved)",
      age = if (length(ages_in_group) == 1L) ages_in_group else NA_integer_,
      age_group = if (length(ages_in_group) == 1L) NA_character_ else {
        paste(range(ages_in_group), collapse = "-")
      },
      survey = unname(survey_names[as.character(fleet_id)]),
      se = q * se_log_q,
      lwr = exp(log_q - stats::qnorm(0.975) * se_log_q),
      upr = exp(log_q + stats::qnorm(0.975) * se_log_q),
      source_reference = "NEA_saithe_2026_v2/run/model.RData fit$pl$logFpar, fit$plsd$logFpar, and conf/model.cfg $keyLogFpar",
      notes = paste(
        "Natural-scale q is exp(logFpar); SE is delta-method from the native log-q SE.",
        "Limits are a normal-approximation 95% interval on log-q.",
        "Age groups follow the configured sharing keys."
      )
    )
  }))
}))
outputs <- rbind(age_outputs, summary_outputs, forecast_outputs,
  prediction_outputs, q_outputs)

source_ref_cfg <- "NEA_saithe_2026_v2/conf/model.cfg"
source_ref_code <- "stockassessment 0.12.0, RemoteSha 1cc464b80f6f; pinned source n.hpp, predn.hpp, f.hpp, obs.hpp"
assumptions <- do.call(rbind, list(
  new_assumption("assessment", "model_run", "NEA_saithe_2026_v2; fits the 2026 ICES SAG 2025 estimates", "run/ver; res/xxx-00-00.00.00_tab1.html; ICES SAG key 22657", "Selected after comparing the cached run's 2025 recruitment, SSB, Fbar, and total biomass with the official SAG values."),
  new_assumption("assessment", "model_version", "stockassessment 0.12.0; RemoteSha 1cc464b80f6f", "NEA_saithe_2026_v2/run/ver"),
  new_assumption("population", "model_years", "1960-2025", "run/model.RData fit$data$years"),
  new_assumption("population", "model_ages", "3-12; age 12 is the plus group", paste(source_ref_cfg, "$minAge, $maxAge, $maxAgePlusGroup")),
  new_assumption("population", "recruitment_age", "3", "run/model.RData fit$conf$minAge"),
  new_assumption("population", "sex_structure", "Single combined-sex population", "run/model.RData fit$data; conf/model.cfg", "The fit contains one population and one set of biological surfaces."),
  new_assumption("population", "initial_state", "No initial N-process density (initState=0)", paste(source_ref_code, "n.hpp"), "The initial abundance state is freely estimated; the N process density starts with subsequent transition residuals."),
  new_assumption("N", "recruitment_relationship", "Beverton-Holt; recruitment at year t uses SSB from t-3", paste(source_ref_cfg, "$stockRecruitmentModelCode; stockassessment source predn.hpp and recruitment.hpp"), "The first age is age 3; SAM evaluates parent SSB three calendar years before recruitment."),
  new_assumption("N", "process", "Annual log-abundance transition residuals are multivariate normal with independent ages; recruitment and older-age variances are separate", paste(source_ref_cfg, "$keyVarLogN, $fracMixN; stockassessment source n.hpp and predn.hpp"), "Age 3 has variance key 0; ages 4-12 share key 1; fracMixN is zero. No lognormal mean correction is applied."),
  new_assumption("F", "age_state_mapping", "Ages 3-7 have separate F states; ages 8-12 share one state", paste(source_ref_cfg, "$keyLogFsta"), "The age 12 state represents the plus group."),
  new_assumption("F", "temporal_process", "Random walk on log F", paste(source_ref_cfg, "$keyLogFsta; stockassessment source f.hpp"), "The transition likelihood is on annual differences of log F."),
  new_assumption("F", "age_correlation", "AR(1) correlation across ordered F states", paste(source_ref_cfg, "$corFlag; stockassessment source f.hpp"), "One process-SD group is shared across all fitted F states."),
  new_assumption("F", "Fbar_ages", "4-7", paste(source_ref_cfg, "$fbarRange")),
  new_assumption("M", "mortality_structure", "Fixed M=0.2 per year for ages 3-12; not estimated", "data/nm.dat; run/model.RData fit$data$natMor", "The numerical input is constant across years and age classes."),
  new_assumption("biology", "maturity_and_spawning", "Annual maturity-at-age at year start; no F or M is applied before spawning", "data/mo.dat, data/pf.dat, data/pm.dat; fit$data$propMat/propF/propM", "The source proportion-before-spawning arrays are zero."),
  new_assumption("catch", "observation_likelihood", "Lognormal with one shared catch observation variance and a prediction-variance link", paste(source_ref_cfg, "$obsLikelihoodFlag, $keyVarObs, $predVarObsLink; stockassessment source obs.hpp"), "Relative observation weights are retained where supplied."),
  new_assumption("catch", "fleet", "One combined catch series (FLT1)", "data/cn.dat; run/model.RData fit$data$aux"),
  new_assumption("index", "surveys", "Two Norwegian acoustic series: FLT13 (1994-2001) and FLT14 (2002-2025)", "data/survey.dat; run/model.RData fit$data$aux"),
  new_assumption("index", "survey_timing", "0.8 for both survey series; source window 0.75-0.85", "data/survey.dat; run/model.RData fit$data$sampleTimes"),
  new_assumption("index", "q_age_sharing", "Within each survey, ages 3, 4, and 5 have separate q; ages 6-7 share q", paste(source_ref_cfg, "$keyLogFpar"), "Survey-specific q blocks are not shared between FLT13 and FLT14.", survey = "FLT13 Norwegian acoustic survey; FLT14 Norwegian acoustic survey"),
  new_assumption("index", "observation_likelihood", "Lognormal; FLT13 age errors independent and FLT14 errors AR(1) across ages", paste(source_ref_cfg, "$obsLikelihoodFlag, $obsCorStruct, $keyCorObs; stockassessment source obs.hpp"), "The same FLT14 correlation parameter applies to adjacent ages 3-6."),
  new_assumption("index", "observation_precision", "Relative precision weights for FLT14 ages 3-7 in 2003-2024; SD is divided by sqrt(weight)", "data/coast_survey_cv.dat; run/data.RData dat$weight and dat$aux", "The native weights match the CV-derived precision values as a set, but their year-age pairing with the source CV matrix is unresolved; both are retained separately.", survey = "FLT14 Norwegian acoustic survey")
))

assessment_url <- sag_url
framework_url <- "https://doi.org/10.17895/ices.pub.25002470"
model_base <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NEA_saithe_2026_v2"
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L, assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "stockassessment 0.12.0 (RemoteSha 1cc464b80f6f), NEA_saithe_2026_v2",
  is_current = TRUE, is_applied = TRUE, framework_year = 2024L,
  assessment_url = assessment_url, framework_url = framework_url,
  data_url = paste0(model_base, "/run/data.RData"),
  model_url = paste0(model_base, "/run/model.RData"),
  repository_url = paste0(model_base, "/"),
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste(
    "The selected native v2 run reproduces the official 2026 ICES SAG estimates through 2025.",
    "One-year forecast recruitment and SSB for 2026 are retained from SAG; age-specific forecast surfaces are unavailable.",
    "The native run contains all fitted observations, biological inputs, and relative weights; the raw StoX CV row pairing remains unresolved and is documented separately."
  ),
  stringsAsFactors = FALSE
)

stock_path <- file.path(root, "database/stocks.csv")
stocks <- utils::read.csv(stock_path, colClasses = "character",
  na.strings = c("", "NA"), check.names = FALSE)
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) stop("Expected one existing Charbonneau-Keith stock row.", call. = FALSE)
code_conflict <- which(!is.na(stocks$authority_stock_id) &
  stocks$authority_stock_id == "pok.27.1-2" & stocks$stock_id != stock_id)
if (length(code_conflict)) {
  stop("The official stock code is already assigned to another stock.", call. = FALSE)
}
stocks$authority_stock_id[stock_row] <- "pok.27.1-2"
stocks$common_name[stock_row] <- "Northeast Arctic saithe"
stocks$area[stock_row] <- "ICES Subareas 1 and 2"
stocks$region[stock_row] <- "Northeast Atlantic"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stock_note <- paste(
  "Official ICES stock code pok.27.1-2; assessment details in source_reviews/ck_ices_afwg_virens_nea_1_2.md."
)
if (!grepl(stock_note, stocks$notes[stock_row], fixed = TRUE)) {
  stocks$notes[stock_row] <- paste(stocks$notes[stock_row], stock_note)
}

paths <- file.path(root, "database", c(
  "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv"
))
new_tables <- list(assessment, assumptions, inputs, outputs)
for (i in seq_along(paths)) {
  existing <- utils::read.csv(paths[i], colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
  if (!identical(names(existing), names(new_tables[[i]]))) {
    stop("Unexpected schema in ", basename(paths[i]), ".", call. = FALSE)
  }
  if (any(existing$assessment_id == assessment_id, na.rm = TRUE)) {
    stop(assessment_id, " already exists in ", basename(paths[i]), ".", call. = FALSE)
  }
}
if (!identical(names(stocks), names(utils::read.csv(stock_path,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)))) {
  stop("Unexpected stock metadata schema.", call. = FALSE)
}

append_rows <- function(path, rows) {
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
for (i in seq_along(paths)) append_rows(paths[i], new_tables[[i]])
utils::write.csv(stocks, stock_path, row.names = FALSE, na = "")

cat(
  "Added ", nrow(inputs), " inputs, ", nrow(assumptions),
  " assumptions, and ", nrow(outputs), " outputs for Northeast Arctic saithe.\n",
  sep = ""
)
