assessment_id <- "ices_whiting_west_scotland_2025"
stock_id <- "ck_ices_wgsce_merlangus_cs27_6a"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", "ices_whiting_6a_2025")
model_dir <- file.path(cache, "model")
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "whiting_27.6a_2025"
)
report_url <- "https://doi.org/10.17895/ices.pub.29401877.v3"
framework_url <- "https://doi.org/10.17895/ices.pub.7922"
advice_url <- "https://asd.ices.dk/viewAdvice/3936"

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to verify the cached native SAM fit.", call. = FALSE)
}

required_files <- file.path(model_dir, c(
  "run/data.RData", "run/model.RData", "run/ver", "conf/model.cfg",
  file.path("data", c(
    "cn.dat", "cw.dat", "dw.dat", "lf.dat", "lw.dat", "mo.dat",
    "nm.dat", "pf.dat", "pm.dat", "sw.dat", "survey.dat",
    "survey_variance.txt"
  ))
))
if (any(!file.exists(required_files))) {
  stop("The cached West of Scotland whiting SAM bundle is incomplete.", call. = FALSE)
}

model_env <- new.env(parent = baseenv())
load(file.path(model_dir, "run/model.RData"), envir = model_env)
fit <- model_env$fit
dat <- fit$data
version <- readLines(file.path(model_dir, "run/ver"), warn = FALSE)
if (!any(grepl("Version: 0.12.0", version, fixed = TRUE)) ||
  !any(grepl("RemoteSha: 1cc464b80f6f", version, fixed = TRUE))) {
  stop("The cached model uses an unexpected stockassessment version.", call. = FALSE)
}

years <- as.integer(dat$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
fleet_names <- c("Total catch", "WCIBTS.Q1", "SCO.Q1", "SWC.Q4")
survey_names <- c("", "WCIBTS.Q1", "SCO.Q1", "SWC.Q4")
sample_times <- as.numeric(dat$sampleTimes)
observed <- is.finite(dat$logobs)
obs_aux <- aux[observed, , drop = FALSE]
if (fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  !identical(years, 1981:2025) || !identical(ages, 0:7) ||
  length(dat$logobs) != nrow(aux) || length(dat$weight) != nrow(aux) ||
  length(fit$rep$predObs) != nrow(aux) ||
  !identical(as.integer(table(obs_aux$fleet)), c(327L, 156L, 84L, 232L)) ||
  !isTRUE(all.equal(sample_times, c(0, 0.125, 0.125, 0.8530996), tolerance = 1e-8))) {
  stop("The cached SAM fit does not match the reviewed year, age, fleet, or fit structure.", call. = FALSE)
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_reference, source_type = "native_model",
                       transformation = "Copied from the fitted SAM data object.",
                       notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  y <- recycle(year)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = recycle(basis), fleet = recycle(fleet), survey = recycle(survey),
    sex = "", region = "", season = "", year = y,
    year_basis = ifelse(is.na(y), "", "calendar_year"),
    age = recycle(age), value = value, unit = recycle(unit),
    sampling_time = recycle(sampling_time), source_type = source_type,
    source_reference = recycle(source_reference),
    transformation = recycle(transformation), notes = recycle(notes),
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "",
    partition = "", stringsAsFactors = FALSE, check.names = FALSE
  )
}

surface_input <- function(x, type, measure, basis, unit, slot, surface_years,
                          notes = "", source_type = "native_model") {
  if (length(dim(x)) == 3L) {
    if (dim(x)[3L] != 1L) stop("Unexpected fleet dimension in ", slot, ".", call. = FALSE)
    x <- x[, , 1L]
  }
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(surface_years), length(ages)))) {
    stop("Unexpected dimensions in fit$data$", slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = surface_years, age = ages)
  input_rows(
    type, measure, basis, grid$year, grid$age, as.vector(x), unit,
    source_reference = paste0(model_url, "/run/model.RData; fit$data$", slot),
    source_type = source_type, notes = notes
  )
}

observations <- lapply(sort(unique(obs_aux$fleet)), function(fleet_id) {
  i <- which(obs_aux$fleet == fleet_id)
  j <- which(observed)[i]
  if (fleet_id == 1L) {
    input_rows(
      "catch", "numbers_at_age", "numbers", obs_aux$year[i], obs_aux$age[i],
      exp(dat$logobs[j]), "thousand fish", fleet = fleet_names[[fleet_id]],
      source_reference = paste0(model_url, "/run/model.RData; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the fitted SAM log catch observation.",
      notes = "Total catch-at-age; age 7 is the plus group."
    )
  } else {
    input_rows(
      "index", "numbers_at_age", "index_scale", obs_aux$year[i], obs_aux$age[i],
      exp(dat$logobs[j]), "native survey index units",
      survey = survey_names[[fleet_id]], sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "/run/model.RData; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated fitted log index after native SAM input processing; the source reader divides the raw series by its effort value.",
      notes = paste0(
        "Retained on the survey's native relative scale; no physical abundance unit is assigned. ",
        "Age 7 is the plus group where present."
      )
    )
  }
})
inputs <- do.call(rbind, observations)

weighted <- observed & is.finite(dat$weight)
weight_aux <- aux[weighted, , drop = FALSE]
inputs <- rbind(inputs, input_rows(
  "index", "relative_precision_weight", "relative_precision",
  weight_aux$year, weight_aux$age, dat$weight[weighted],
  "relative precision weight",
  survey = survey_names[weight_aux$fleet],
  sampling_time = sample_times[weight_aux$fleet],
  source_reference = paste0(model_url, "/run/model.RData; fit$data$weight aligned to fit$data$aux"),
  transformation = "Copied from the native SAM observation-weight vector.",
  notes = "Where finite, SAM scales log-index observation SD by 1/sqrt(weight). Missing weights are retained as absent; the tinyAM translation uses its default factor for those rows."
))

catch_years <- years[-length(years)]
inputs <- rbind(
  inputs,
  surface_input(dat$stockMeanWeight, "weight", "weight_at_age",
    "kg_per_fish", "kg per fish", "stockMeanWeight", years,
    "Annual stock weight-at-age used in the assessment."),
  surface_input(dat$catchMeanWeight, "catch_weight", "weight_at_age",
    "kg_per_fish", "kg per fish", "catchMeanWeight", catch_years,
    "Annual catch weight-at-age."),
  surface_input(dat$landMeanWeight, "catch_weight", "landings_weight_at_age",
    "kg_per_fish", "kg per fish", "landMeanWeight", catch_years,
    "Annual landings weight-at-age."),
  surface_input(dat$disMeanWeight, "catch_weight", "discard_weight_at_age",
    "kg_per_fish", "kg per fish", "disMeanWeight", catch_years,
    "Annual discard weight-at-age."),
  surface_input(dat$propMat, "maturity", "maturity_at_age",
    "proportion", "proportion", "propMat", years,
    "Annual maturity-at-age supplied to the assessment."),
  surface_input(dat$natMor, "M", "natural_mortality_at_age",
    "per_year", "per year", "natMor", years,
    "Fixed natural mortality supplied to SAM; no M process is estimated."),
  surface_input(dat$landFrac, "catch", "landings_fraction_at_age",
    "proportion", "proportion", "landFrac", catch_years,
    "Annual fraction of removals assigned to landings."),
  surface_input(dat$propF, "biology", "fraction_F_before_spawning",
    "proportion", "proportion", "propF", years,
    "Fraction of annual F applied before spawning."),
  surface_input(dat$propM, "biology", "fraction_M_before_spawning",
    "proportion", "proportion", "propM", years,
    "Fraction of annual M applied before spawning.")
)

output_rows <- function(type, measure, year, value, unit, age = NA_integer_,
                        age_group = "", fleet = "", survey = "",
                        se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        source_type = "native_model", source_reference,
                        notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = recycle(fleet), survey = recycle(survey), sex = "", region = "",
    season = "", year = recycle(year), age = recycle(age),
    age_group = recycle(age_group), value = value, se = recycle(se),
    lwr = recycle(lwr), upr = recycle(upr), unit = recycle(unit),
    source_type = source_type, source_reference = recycle(source_reference),
    notes = recycle(notes), stringsAsFactors = FALSE, check.names = FALSE
  )
}

state_output <- function(log_state, log_sd, type, measure, unit, slot) {
  estimate <- exp(t(log_state))
  state_sd <- t(log_sd)
  dimnames(estimate) <- dimnames(state_sd) <- list(as.character(years), as.character(ages))
  grid <- expand.grid(year = years, age = ages)
  val <- as.vector(estimate)
  sd <- as.vector(state_sd)
  age_group <- ifelse(grid$age == max(ages), paste0(max(ages), "+"), "")
  output_rows(
    type, measure, grid$year, val, unit, grid$age, age_group,
    se = val * sd, lwr = exp(log(val) - stats::qnorm(0.975) * sd),
    upr = exp(log(val) + stats::qnorm(0.975) * sd),
    source_reference = paste0(model_url, "/run/model.RData; exp(fit$pl$", slot, ")"),
    notes = "Natural-scale SE uses the delta method; 95% limits are log-scale Wald intervals."
  )
}

n_surface <- exp(t(fit$pl$logN))
f_surface <- exp(t(fit$pl$logF))
m_surface <- dat$natMor
if (!identical(dim(n_surface), c(length(years), length(ages))) ||
  !identical(dim(f_surface), c(length(years), length(ages))) ||
  !all(is.finite(n_surface)) || !all(is.finite(f_surface)) ||
  !all(is.finite(m_surface))) {
  stop("A fitted population or mortality surface contains unexpected values.", call. = FALSE)
}
dimnames(n_surface) <- dimnames(f_surface) <- dimnames(m_surface) <-
  list(as.character(years), as.character(ages))

outputs <- rbind(
  state_output(fit$pl$logN, fit$plsd$logN,
    "population", "numbers_at_age", "thousand fish", "logN"),
  state_output(fit$pl$logF, fit$plsd$logF,
    "mortality", "fishing_mortality_at_age", "per year", "logF"),
  {
    grid <- expand.grid(year = years, age = ages)
    output_rows(
      "mortality", "natural_mortality_at_age", grid$year,
      as.vector(m_surface), "per year", grid$age,
      ifelse(grid$age == max(ages), paste0(max(ages), "+"), ""),
      source_reference = paste0(model_url, "/run/model.RData; fit$data$natMor"),
      notes = "Fixed SAM input; no fitted standard error is available."
    )
  }
)

total_numbers <- rowSums(n_surface)
outputs <- rbind(
  outputs,
  output_rows(
    "population", "total_numbers", years, total_numbers, "thousand fish",
    source_type = "derived_source_output",
    source_reference = paste0(model_url, "/run/model.RData; sum(exp(t(fit$pl$logN)))"),
    notes = "Derived by summing fitted numbers-at-age, including the age-7 plus group; uncertainty is not available for this derived total."
  )
)

biomass_surface <- n_surface * dat$stockMeanWeight
biomass_grid <- expand.grid(year = years, age = ages)
biomass_value <- as.vector(biomass_surface)
biomass_log_sd <- as.vector(t(fit$plsd$logN))
outputs <- rbind(outputs, output_rows(
  "biomass", "biomass_at_age", biomass_grid$year, biomass_value,
  "tonnes", biomass_grid$age,
  ifelse(biomass_grid$age == max(ages), paste0(max(ages), "+"), ""),
  se = biomass_value * biomass_log_sd,
  lwr = exp(log(biomass_value) - stats::qnorm(0.975) * biomass_log_sd),
  upr = exp(log(biomass_value) + stats::qnorm(0.975) * biomass_log_sd),
  source_type = "derived_source_output",
  source_reference = paste0(model_url,
    "/run/model.RData; fit$pl$logN and fit$data$stockMeanWeight"),
  notes = paste(
    "Derived as fitted N (thousand fish) times fixed stock weight (kg/fish);",
    "the numerical product is tonnes. SE and 95% limits reflect N uncertainty",
    "only and treat stock weights as fixed."
  )
))
summary_table <- function(fun, measure, type, unit, age_group = "") {
  tab <- fun(fit)
  years_tab <- as.integer(rownames(tab))
  output_rows(
    type, measure, years_tab, tab[, "Estimate"], unit, age_group = age_group,
    se = NA_real_, lwr = tab[, "Low"], upr = tab[, "High"],
    source_reference = paste0(model_url, "/run/model.RData; stockassessment::",
      deparse(substitute(fun)), "(fit)"),
    notes = "Native SAM summary estimate and reported 95% confidence limits."
  )
}

outputs <- rbind(
  outputs,
  summary_table(stockassessment::rectable, "recruitment", "recruitment",
    "thousand fish", "age 0"),
  summary_table(stockassessment::ssbtable, "SSB", "biomass", "tonnes"),
  summary_table(stockassessment::fbartable, "Fbar", "mortality", "per year",
    paste(fit$conf$fbarRange, collapse = "-")),
  summary_table(stockassessment::tsbtable, "total_biomass", "biomass", "tonnes")
)

q <- stockassessment::qtable(fit)
q_sd <- attr(q, "sd")
q_grid <- expand.grid(age = as.integer(colnames(q)), survey = rownames(q))
q_log <- as.vector(t(as.matrix(q)))
q_log_sd <- as.vector(t(as.matrix(q_sd)))
q_keep <- is.finite(q_log) & is.finite(q_log_sd)
q_grid <- q_grid[q_keep, , drop = FALSE]
q_value <- exp(q_log[q_keep])
q_sigma <- q_log_sd[q_keep]
outputs <- rbind(outputs, output_rows(
  "catchability", "q", rep(NA_integer_, length(q_value)), q_value,
  "native index units per thousand fish", q_grid$age,
  ifelse(q_grid$age == max(ages), paste0(max(ages), "+"), ""),
  survey = q_grid$survey, se = q_value * q_sigma,
  lwr = exp(q_log[q_keep] - stats::qnorm(0.975) * q_sigma),
  upr = exp(q_log[q_keep] + stats::qnorm(0.975) * q_sigma),
  source_reference = paste0(model_url, "/run/model.RData; stockassessment::qtable(fit)"),
  notes = "q is stored on its natural scale; SE uses the delta method from the log-q SD and confidence limits are log-scale Wald intervals."
))

predicted <- exp(fit$rep$predObs[observed])
pred_aux <- aux[observed, , drop = FALSE]
pred_is_catch <- pred_aux$fleet == 1L
outputs <- rbind(
  outputs,
  output_rows(
    "catch", "predicted_catch", pred_aux$year[pred_is_catch],
    predicted[pred_is_catch], "thousand fish", pred_aux$age[pred_is_catch],
    ifelse(pred_aux$age[pred_is_catch] == max(ages), paste0(max(ages), "+"), ""),
    fleet = "Total catch",
    source_reference = paste0(model_url, "/run/model.RData; exp(fit$rep$predObs)"),
    notes = "Fitted SAM prediction for rows with observed catch data."
  ),
  output_rows(
    "index", "predicted_index", pred_aux$year[!pred_is_catch],
    predicted[!pred_is_catch], "native survey index units",
    pred_aux$age[!pred_is_catch],
    ifelse(pred_aux$age[!pred_is_catch] == max(ages), paste0(max(ages), "+"), ""),
    survey = survey_names[pred_aux$fleet[!pred_is_catch]],
    source_reference = paste0(model_url, "/run/model.RData; exp(fit$rep$predObs)"),
    notes = "Fitted SAM prediction for rows with observed survey data."
  )
)

assumption <- function(component, setting, value, source_reference,
                       notes = "", survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = survey, sex = "", region = "", season = "", setting = setting,
    value = as.character(value), source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}
cfg_ref <- paste0(model_url, "/conf/model.cfg and fit$conf")
assumptions <- do.call(rbind, list(
  assumption("population", "model_years", "1981-2025", cfg_ref,
    "Catch observations extend through 2024; 2025 is the final model and survey year."),
  assumption("population", "model_ages", "0-7; age 7 is the plus group", cfg_ref),
  assumption("recruitment", "process", "Random walk on log recruitment", cfg_ref,
    "stockRecruitmentModelCode=0."),
  assumption("N", "process", "Log-abundance transition process with age-shared variances", cfg_ref,
    "keyVarLogN assigns age 0 separately and shares one variance across ages 1-7."),
  assumption("F", "process", "Random walk on log F with AR(1) correlation across ages", cfg_ref,
    "Separate F state by age; one process variance is shared across ages."),
  assumption("F", "Fbar_ages", "1-3", cfg_ref),
  assumption("M", "process", "Fixed natural mortality input", cfg_ref,
    "The assessment does not estimate an M process."),
  assumption("catch", "likelihood", "Lognormal catch-at-age likelihood", cfg_ref,
    "Observation SDs are shared across the configured catch age groups."),
  assumption("catch", "observation_sd_age_groups", "Age 0; ages 1-6; age 7+", cfg_ref),
  assumption("index", "likelihood", "Lognormal age-specific survey index likelihood", cfg_ref,
    "Relative precision weights are retained where present; Q4 includes AR(1) residual correlation across ages."),
  assumption("index", "survey_names", "WCIBTS.Q1; SCO.Q1; SWC.Q4", cfg_ref,
    "The old and replacement Q1 survey series are preserved as separate fleets."),
  assumption("index", "sampling_time", "WCIBTS.Q1=0.125; SCO.Q1=0.125; SWC.Q4=0.8530996", cfg_ref),
  assumption("index", "q_age_sharing", "Q1 ages 1-4 separate and ages 5-6 shared; Q4 ages 0-5 separate and ages 6-7 shared", cfg_ref),
  assumption("index", "relative_precision_weights", "Finite weights for 316 fitted observations", cfg_ref,
    "The native log-index SD is scaled by 1/sqrt(weight); the remainder use unit weight."),
  assumption("biology", "biological_inputs", "Stock weight, catch/landings/discard weights, maturity, M and spawning-time fractions are supplied", cfg_ref),
  assumption("fit", "optimizer", fit$opt$message, paste0(model_url, "/run/model.RData"),
    paste0("Convergence code ", fit$opt$convergence, "; objective ",
      signif(fit$opt$objective, 8), "; positive-definite Hessian=",
      isTRUE(fit$sdrep$pdHess), "."))
))

assessment_url <- report_url
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "WGCSE 2025; stockassessment 0.12.0 (RemoteSha 1cc464b80f6f)",
  is_current = TRUE, is_applied = TRUE, framework_year = 2021L,
  assessment_url = assessment_url, framework_url = framework_url,
  data_url = paste0(model_url, "/data/"),
  model_url = paste0(model_url, "/run/model.RData"),
  repository_url = paste0(model_url, "/"),
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste(
    "The selected 2025 WGCSE run is the latest detailed production assessment recovered; the 2026 report chapter available during review is a placeholder.",
    "The native SAM run converges with a positive-definite Hessian and matches the WGCSE 2025 N-at-age, F-at-age and summary tables.",
    "Age 7 is the plus group. Catch observations end in 2024; model states and Q1 survey estimates extend through 2025."
  ),
  stringsAsFactors = FALSE, check.names = FALSE
)

database <- file.path(base, "database")
read_db <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}
append_rows <- function(name, rows) {
  path <- file.path(database, name)
  current <- read_db(name)
  if (!identical(names(current), names(rows))) {
    stop("Unexpected schema in ", name, ".", call. = FALSE)
  }
  if (any(current$assessment_id == assessment_id, na.rm = TRUE)) {
    stop(assessment_id, " already exists in ", name, ".", call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "")
}

stocks_path <- file.path(database, "stocks.csv")
stocks <- read_db("stocks.csv")
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L ||
  any(stocks$authority_stock_id == "whg.27.6a", na.rm = TRUE)) {
  stop("Expected one metadata-only stock row and an unused ICES stock code.", call. = FALSE)
}
stocks$authority[stock_row] <- "ICES"
stocks$authority_stock_id[stock_row] <- "whg.27.6a"
stocks$common_name[stock_row] <- "West of Scotland whiting"
stocks$area[stock_row] <- "Division 6.a"
stocks$region[stock_row] <- "Celtic Seas and West of Scotland"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Official ICES stock code whg.27.6a; detailed 2025 SAM assessment imported.",
  "Source review: source_reviews/ices_whiting_west_scotland_2025.md."
)

for (table_name in c("assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
  current <- read_db(table_name)
  rows <- switch(table_name,
    "assessments.csv" = assessment,
    "assumptions.csv" = assumptions,
    "inputs.csv" = inputs,
    "outputs.csv" = outputs
  )
  if (!identical(names(current), names(rows)) ||
    any(current$assessment_id == assessment_id, na.rm = TRUE)) {
    stop("Unexpected schema or duplicate assessment in ", table_name, ".", call. = FALSE)
  }
}
utils::write.csv(stocks, stocks_path, row.names = FALSE, na = "")
append_rows("assessments.csv", assessment)
append_rows("assumptions.csv", assumptions)
append_rows("inputs.csv", inputs)
append_rows("outputs.csv", outputs)

cat(
  "Added West of Scotland whiting: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n",
  sep = ""
)
