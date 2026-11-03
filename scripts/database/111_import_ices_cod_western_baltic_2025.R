assessment_id <- "ices_cod_western_baltic_2025"
stock_id <- "ck_ices_wgbfas_morhua_bs"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", assessment_id)
database <- file.path(base, "database")
model_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/WBCod2025"
report_url <- "https://doi.org/10.17895/ices.pub.29099786"
tables_url <- paste0(report_url, "; section 2.3, Tables 2.3.15 and 2.3.17-2.3.26")
framework_url <- "https://doi.org/10.17895/ices.pub.4984"
taf_url <- "https://github.com/ices-advice/2025_cod.27.22-24"

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to import the cached WBCod2025 SAM fit.", call. = FALSE)
}

required <- file.path(cache, c(
  "WBCod2025_fitfromweb.rds", "wgbfas_2025_section_02_cod_baltic_kattegat.txt",
  file.path("sam_data", c("cn.dat", "cw.dat", "dw.dat", "lf.dat", "lw.dat", "mo.dat", "nm.dat", "pf.dat", "pm.dat", "survey.dat", "sw.dat")),
  file.path("sam_config", "model.cfg")
))
if (any(!file.exists(required))) {
  stop("The cached WGBFAS report, SAM data, configuration or fit is incomplete.", call. = FALSE)
}

fit <- readRDS(file.path(cache, "WBCod2025_fitfromweb.rds"))
dat <- fit$data
years <- as.integer(dat$years)
ages <- as.integer(colnames(dat$stockMeanWeight))
fleet_names <- as.character(attr(dat, "fleetNames"))
survey_codes <- c("", "BITS Q4", "BITS Q1", "FEJUCS")
sample_times <- as.numeric(dat$sampleTimes)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
observed <- is.finite(dat$logobs)

if (fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  max(abs(fit$sdrep$gradient.fixed)) > 1e-8 ||
  !identical(years, 1985:2025) || !identical(ages, 0:7) ||
  !identical(fleet_names, c("Residual catch", "SD2224w_4Q", "SD2224w_Q1", "SD24_poundnet")) ||
  !isTRUE(all.equal(sample_times, c(0, 0.8477816, 0.1653494, 0.85), tolerance = 1e-6)) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 1L, 1L, 0L)) ||
  !identical(as.integer(fit$conf$fbarRange), c(3L, 5L)) ||
  !identical(as.integer(fit$conf$keyLogFsta[1L, ]), c(-1L, 0L, 1L, 2L, 3L, 4L, 4L, 4L)) ||
  fit$conf$stockRecruitmentModelCode != 0L ||
  !identical(as.character(fit$conf$obsCorStruct), c("ID", "ID", "AR", "ID"))) {
  stop("The cached SAM fit differs from the reviewed WBCod2025 run or diagnostics.", call. = FALSE)
}

read_ices <- get("read.ices", envir = asNamespace("stockassessment"))
raw_dat <- stockassessment::setup.sam.data(
  surveys = read_ices(file.path(cache, "sam_data", "survey.dat")),
  residual.fleets = read_ices(file.path(cache, "sam_data", "cn.dat")),
  prop.mature = read_ices(file.path(cache, "sam_data", "mo.dat")),
  stock.mean.weight = read_ices(file.path(cache, "sam_data", "sw.dat")),
  catch.mean.weight = read_ices(file.path(cache, "sam_data", "cw.dat")),
  dis.mean.weight = read_ices(file.path(cache, "sam_data", "dw.dat")),
  land.mean.weight = read_ices(file.path(cache, "sam_data", "lw.dat")),
  prop.f = read_ices(file.path(cache, "sam_data", "pf.dat")),
  prop.m = read_ices(file.path(cache, "sam_data", "pm.dat")),
  natural.mortality = read_ices(file.path(cache, "sam_data", "nm.dat")),
  land.frac = read_ices(file.path(cache, "sam_data", "lf.dat"))
)
for (field in c(
  "years", "propMat", "stockMeanWeight", "catchMeanWeight", "natMor",
  "landFrac", "disMeanWeight", "landMeanWeight", "propF", "propM", "sampleTimes"
)) {
  if (!isTRUE(all.equal(dat[[field]], raw_dat[[field]], check.attributes = FALSE))) {
    stop("The fitted SAM data differ from the cached native inputs in ", field, ".", call. = FALSE)
  }
}
fit_aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
raw_aux <- as.data.frame(raw_dat$aux, stringsAsFactors = FALSE)
names(fit_aux) <- names(raw_aux) <- c("year", "fleet", "age")
key <- function(x) paste(x[[1L]], x[[2L]], x[[3L]], sep = "\r")
source_row <- match(key(fit_aux), key(raw_aux))
if (anyNA(source_row) || anyDuplicated(key(raw_aux)) ||
  !isTRUE(all.equal(dat$logobs, raw_dat$logobs[source_row], check.attributes = FALSE))) {
  stop("The fitted SAM observation rows do not match the cached .dat files.", call. = FALSE)
}

if (!identical(as.integer(table(aux$fleet[observed])), c(277L, 130L, 120L, 13L)) ||
  any(dat$weight[aux$fleet == 1L & aux$year <= 2019L] != 1) ||
  any(dat$weight[aux$fleet == 1L & aux$year >= 2020L] != 0.1) ||
  any(!is.na(dat$weight[aux$fleet != 1L]))) {
  stop("Observed fleet coverage or native SAM observation weights differ from the reviewed run.", call. = FALSE)
}

stock_path <- file.path(database, "stocks.csv")
stocks <- read.csv(stock_path, colClasses = "character", na.strings = character(),
  stringsAsFactors = FALSE, check.names = FALSE)
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) stop("Expected one matching Charbonneau-Keith stock row.", call. = FALSE)
stocks$common_name[stock_row] <- "Western Baltic cod"
stocks$authority_stock_id[stock_row] <- "cod.27.22-24"
stocks$area[stock_row] <- "ICES subdivisions 22-24"
stocks$region[stock_row] <- "Western Baltic"
stocks$notes[stock_row] <- paste(
  "Charbonneau-Keith Master metadata reconciled to ICES stock cod.27.22-24.",
  "The detailed 2025 WBCod2025 SAM assessment is imported; see source review for source coverage, weight treatment and advice caveats."
)
if (assessment_id %in% read.csv(file.path(database, "assessments.csv"),
  colClasses = "character", stringsAsFactors = FALSE)$assessment_id) {
  stop("The assessment event already exists; review it before re-importing.", call. = FALSE)
}

input_rows <- function(type, measure, basis, year = NA_integer_, age = NA_integer_,
                       value, unit, fleet = "", survey = "", sampling_time = NA_real_,
                       source_reference, transformation = "Copied from the native SAM input or fitted data object.",
                       notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  y <- recycle(year)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = recycle(basis), fleet = recycle(fleet), survey = recycle(survey),
    sex = "", region = "", season = "", year = y,
    year_basis = ifelse(is.na(y), "", "calendar_year"), age = recycle(age),
    value = as.numeric(value), unit = recycle(unit), sampling_time = recycle(sampling_time),
    source_type = "native_model", source_reference = recycle(source_reference),
    transformation = recycle(transformation), notes = recycle(notes), observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

surface_input <- function(x, type, measure, basis, unit, file, notes) {
  if (length(dim(x)) == 3L) {
    if (dim(x)[3L] != 1L) stop("Unexpected fleet dimension in ", file, ".", call. = FALSE)
    x <- x[, , 1L]
  }
  x <- as.matrix(x)
  input_years <- years[seq_len(nrow(x))]
  if (!identical(ncol(x), length(ages)) || any(!is.finite(x))) {
    stop("Unexpected dimensions or missing values in SAM input ", file, ".", call. = FALSE)
  }
  grid <- expand.grid(year = input_years, age = ages, KEEP.OUT.ATTRS = FALSE)
  input_rows(
    type, measure, basis, grid$year, grid$age, as.vector(x), unit,
    source_reference = paste0(model_url, "/data/", file), notes = notes
  )
}

obs_index <- which(observed)
catch_index <- obs_index[aux$fleet[obs_index] == 1L]
survey_index <- obs_index[aux$fleet[obs_index] > 1L]
observation_rows <- lapply(obs_index, function(i) {
  fleet <- aux$fleet[i]
  if (fleet == 1L) {
    input_rows(
      "catch", "numbers_at_age", "numbers", aux$year[i], aux$age[i], exp(dat$logobs[i]),
      "thousand fish", fleet = "Total catch",
      source_reference = paste0(model_url, "/data/cn.dat; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the log catch stored in the fitted SAM data object.",
      notes = "Combined landings, discards and recreational catch; age 7 is the 7+ group. Source-missing catch cells are omitted."
    )
  } else {
    input_rows(
      "index", "numbers_at_age", "index_scale", aux$year[i], aux$age[i], exp(dat$logobs[i]),
      "native survey-index units", survey = survey_codes[fleet],
      sampling_time = sample_times[fleet],
      source_reference = paste0(model_url, "/data/survey.dat; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the log index stored in the fitted SAM data object.",
      notes = paste0("Native SAM survey fleet ", fleet_names[fleet], "; reported as CPUE, with no physical scale multiplier supplied.")
    )
  }
})
observations <- do.call(rbind, observation_rows)
catch_weights <- input_rows(
  "catch", "observation_likelihood_weight", "relative_scale",
  aux$year[catch_index], aux$age[catch_index], dat$weight[catch_index], "relative scale",
  fleet = "Total catch",
  source_reference = paste0(model_url, "/run/model.RData; fit$data$weight"),
  transformation = "Copied the native SAM data weight without conversion.",
  notes = "The model object assigns 1 through 2019 and 0.1 in 2020-2024. The report does not explain the weight's exact likelihood-scale interpretation; tinyAM's catch likelihood does not currently apply it."
)

inputs <- do.call(rbind, c(list(observations, catch_weights), list(
  surface_input(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish", "kg per fish", "sw.dat", "Annual stock weight-at-age from the native SAM data object."),
  surface_input(dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "cw.dat", "Annual combined catch weight-at-age."),
  surface_input(dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish", "lw.dat", "Annual landings weight-at-age."),
  surface_input(dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish", "dw.dat", "Annual discard weight-at-age."),
  surface_input(dat$propMat, "maturity", "maturity_at_age", "proportion", "proportion", "mo.dat", "Fixed maturity ogive as supplied to the SAM fit; age 7 is the 7+ group."),
  surface_input(dat$natMor, "M", "natural_mortality_at_age", "per_year", "per year", "nm.dat", "Fixed natural mortality-at-age supplied to SAM; age 7 is the 7+ group."),
  surface_input(dat$landFrac, "catch", "landings_fraction_at_age", "proportion", "proportion", "lf.dat", "Native landings fraction at age, retained without clipping."),
  surface_input(dat$propF, "biology", "fraction_F_before_spawning", "proportion", "proportion", "pf.dat", "Fraction of annual F before spawning; source values are zero."),
  surface_input(dat$propM, "biology", "fraction_M_before_spawning", "proportion", "proportion", "pm.dat", "Fraction of annual M before spawning; source values are zero.")
)))

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                            survey = "", fleet = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet, survey = survey,
    sex = "", region = "", season = "", setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
cfg_ref <- paste0(model_url, "/conf/model.cfg; fit$conf")
assumptions <- do.call(rbind, list(
  assumption_rows("assessment", "model_family", "SAM", taf_url, "The 2025 WGBFAS assessment uses the WBCod2025 stockassessment run."),
  assumption_rows("population", "years_and_ages", "1985-2025; ages 0-7", paste0(model_url, "/run/model.RData; fit$data and fit$pl"), "Catch observations end in 2024; the fitted model contains population estimates through 2025. Age 7 is the catch and survey plus group where configured."),
  assumption_rows("population", "terminal_catch_year", "2024", paste0(model_url, "/data/cn.dat"), "Catch ends in 2024; Q1 observations and the fitted population surface extend through 2025."),
  assumption_rows("population", "recruitment_age", "1", cfg_ref, "The report labels recruitment as age 1. No year shift is applied."),
  assumption_rows("N", "process_variance_sharing", "Separate age 0; shared ages 1-7", cfg_ref, "SAM keyVarLogN assigns age 0 one variance and ages 1-7 another; tinyAM uses IID cohort deviations as an approximation."),
  assumption_rows("N", "initial_state", "initState=0", cfg_ref, "Native SAM configuration; tinyAM uses its standard exponential initialization."),
  assumption_rows("F", "process", "Independent log-F states; corFlag=0", cfg_ref, "SAM estimates log-F state at ages 1-7; age 0 has no F state and ages 5-7 share one state. One process variance is shared across fitted ages."),
  assumption_rows("F", "Fbar_ages", "3-5", cfg_ref, "Native SAM Fbar age range. The report cautions that F is unreliable for this stock and uses harvest rate for advice."),
  assumption_rows("M", "process", "Fixed natural mortality", paste0(model_url, "/data/nm.dat; Table 2.3.21"), "M is not estimated by SAM; age-specific annual values are retained in inputs.csv."),
  assumption_rows("M", "age_values_per_year", "0:1.318; 1:0.598; 2:0.411; 3:0.324; 4:0.274; 5:0.241; 6:0.218; 7+:0.201", paste0(tables_url, "; Table 2.3.21"), "Rates are per year; the report table covers 1985-2024 and the native input surface supplies 2025 as well."),
  assumption_rows("catch", "observation_model", "Lognormal", cfg_ref, "Catch is represented on the log scale in SAM; ages 1 and 2-7 have separate observation-variance groups."),
  assumption_rows("catch", "observation_weights", "1 through 2019; 0.1 in 2020-2024", paste0(model_url, "/run/model.RData; fit$data$weight"), "Copied as source observation likelihood weights; their exact scaling interpretation is unresolved in the report."),
  assumption_rows("index", "observation_model", "Lognormal age-specific CPUE indices", cfg_ref, "The SAM fit uses the source log-index observations."),
  assumption_rows("index", "observation_correlation", "BITS Q4: ID; BITS Q1: AR across ages; FEJUCS: ID", cfg_ref, "The Q1 age residual correlation is not represented in tinyAM."),
  assumption_rows("index", "catchability_age_groups", "BITS Q4 ages 0-4; BITS Q1 ages 1-4; FEJUCS age 0", cfg_ref, "SAM estimates q by available survey-age cell; no density-dependent q power is enabled."),
  assumption_rows("index", "survey_timing", "BITS Q4 0.8477816; BITS Q1 0.1653494; FEJUCS 0.85", paste0(model_url, "/run/model.RData; fit$data$sampleTimes"), "Sampling times are represented as fractions of the model year."),
  assumption_rows("biology", "maturity", "Fixed ogive; age 7+ = 1.00", paste0(tables_url, "; Table 2.3.20 and mo.dat"), "The report describes a fixed maturity ogive based on the 1998-2023 mean."),
  assumption_rows("biology", "SSB_timing", "Start of year; propF=0 and propM=0", paste0(tables_url, "; section 2.3.3.3 and pf.dat/pm.dat"), "No mortality is applied before spawning."),
  assumption_rows("biology", "weight_surfaces", "Annual stock, catch, landings and discard weights", paste0(model_url, "/data/sw.dat, cw.dat, lw.dat, dw.dat"), "Native SAM input surfaces are retained without smoothing or substitution."),
  assumption_rows("outputs", "reported_quantities", "Recruitment age 1; SSB; Fbar ages 3-5; TSB; N-at-age; total mortality; harvest rate", tables_url, "The report says F is unreliable for advice; harvest rate is used instead."),
  assumption_rows("assessment", "sam_package", as.character(utils::packageVersion("stockassessment")), paste0(taf_url, "; model_fit.R"), paste0("Fit retrieved with stockassessment::fitfromweb('WBCod2025'); RemoteSha=", attr(fit, "RemoteSha")))
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
    season = "", year = recycle(year), age = recycle(age), age_group = recycle(age_group),
    value = as.numeric(value), se = recycle(se), lwr = recycle(lwr), upr = recycle(upr),
    unit = recycle(unit), source_type = recycle(source_type),
    source_reference = recycle(source_reference), notes = recycle(notes),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

random_state_se <- function(name, state) {
  indices <- which(names(fit$sdrep$par.random) == name)
  if (length(indices) != length(state) ||
    max(abs(unname(fit$sdrep$par.random[indices]) - as.vector(state))) > 1e-10 ||
    any(!is.finite(fit$sdrep$diag.cov.random[indices])) || any(fit$sdrep$diag.cov.random[indices] <= 0)) {
    stop("Could not align conditional SAM random-state uncertainty for ", name, ".", call. = FALSE)
  }
  matrix(sqrt(fit$sdrep$diag.cov.random[indices]), nrow = nrow(state), ncol = ncol(state))
}

z <- stats::qnorm(0.975)
n_surface <- stockassessment::ntable(fit)
n_se_log <- random_state_se("logN", fit$pl$logN)
n_estimate <- n_surface
n_error <- exp(t(fit$pl$logN)) * t(n_se_log)
n_grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
n_value <- as.vector(n_estimate)
n_se <- as.vector(n_error)
n_low <- n_high <- rep(NA_real_, length(n_value))
n_positive <- is.finite(n_value) & n_value > 0 & is.finite(n_se)
n_low[n_positive] <- exp(log(n_value[n_positive]) - z * as.vector(t(n_se_log))[n_positive])
n_high[n_positive] <- exp(log(n_value[n_positive]) + z * as.vector(t(n_se_log))[n_positive])
n_keep <- is.finite(n_value) & !(n_grid$year == 2025L & n_grid$age == 0L)
n_outputs <- output_rows(
  "population", "numbers_at_age", n_grid$year[n_keep], n_grid$age[n_keep],
  ifelse(n_grid$age[n_keep] == 7L, "7+", ""), n_value[n_keep], "thousand fish",
  se = n_se[n_keep], lwr = n_low[n_keep], upr = n_high[n_keep],
  source_reference = paste0(model_url, "/run/model.RData; stockassessment::ntable(fit) and conditional logN covariance"),
  notes = "Beginning-of-year N from the native SAM fit. SEs are natural-scale delta-method approximations; limits are 95% log-Wald intervals. Age 7 is the plus group. The unreported 2025 age-0 cell is omitted."
)

f_state <- fit$pl$logF
f_se_log <- random_state_se("logF", f_state)
f_key <- as.integer(fit$conf$keyLogFsta[1L, ])
f_grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
f_value <- f_se <- f_low <- f_high <- rep(NA_real_, nrow(f_grid))
f_value[f_grid$age == 0L] <- 0
for (age in ages[ages > 0]) {
  row <- f_key[match(age, ages)] + 1L
  i <- which(f_grid$age == age)
  f_value[i] <- exp(f_state[row, ])
  f_se[i] <- f_value[i] * f_se_log[row, ]
  f_low[i] <- exp(f_state[row, ] - z * f_se_log[row, ])
  f_high[i] <- exp(f_state[row, ] + z * f_se_log[row, ])
}
f_rows <- lapply(years, function(year) {
  i <- which(f_grid$year == year)
  c(
    list(output_rows(
      "mortality", "fishing_mortality_at_age", year = year, age = 0L,
      value = 0, unit = "per year", source_reference = paste0(model_url, "/run/model.RData; fit$conf$keyLogFsta"),
      notes = "F at age 0 is structurally absent in SAM and shown as zero; the source report cautions that F is unreliable for advice."
    )),
    lapply(1:4, function(age) {
      j <- i[f_grid$age[i] == age]
      output_rows(
        "mortality", "fishing_mortality_at_age", year = year, age = age,
        value = f_value[j], unit = "per year", se = f_se[j], lwr = f_low[j], upr = f_high[j],
        source_reference = paste0(model_url, "/run/model.RData; fit$pl$logF and conditional random-effect covariance"),
        notes = "F at age from the native SAM fit; uncertainty is a natural-scale delta-method SE with 95% log-Wald interval. The source report cautions that F is unreliable for advice."
      )
    }),
    list(output_rows(
      "mortality", "fishing_mortality_at_age", year = year, age = NA_integer_, age_group = "5-7",
      value = f_value[i[f_grid$age[i] == 5L]], unit = "per year",
      se = f_se[i[f_grid$age[i] == 5L]], lwr = f_low[i[f_grid$age[i] == 5L]], upr = f_high[i[f_grid$age[i] == 5L]],
      source_reference = paste0(model_url, "/run/model.RData; fit$conf$keyLogFsta"),
      notes = "Ages 5-7 share one fitted SAM F state; this grouped output is not split into separate age estimates. F is considered unreliable for advice."
    ))
  )
})
f_outputs <- do.call(rbind, unlist(f_rows, recursive = FALSE))

native_summary <- function(fun, measure, unit, type, age = NA_integer_, age_group = "", notes) {
  table <- fun(fit)
  row <- table[as.character(years), , drop = FALSE]
  if (!identical(rownames(row), as.character(years)) || any(!is.finite(row[, "Estimate"]))) {
    stop("Could not recover the annual native SAM ", measure, " series.", call. = FALSE)
  }
  output_rows(
    type, measure, year = years, age = age, age_group = age_group,
    value = row[, "Estimate"], lwr = row[, "Low"], upr = row[, "High"], unit = unit,
    source_reference = paste0(model_url, "/run/model.RData; ", deparse(substitute(fun)), "(fit)"),
    notes = notes
  )
}

q_log <- stockassessment::qtable(fit)
q_se_log <- attr(q_log, "sd")
q_grid <- expand.grid(survey = rownames(q_log), age = as.integer(colnames(q_log)), KEEP.OUT.ATTRS = FALSE)
q_grid$log_est <- as.vector(q_log)
q_grid$log_se <- as.vector(q_se_log)
q_grid <- q_grid[is.finite(q_grid$log_est) & is.finite(q_grid$log_se), , drop = FALSE]
q_value <- exp(q_grid$log_est)
q_outputs <- output_rows(
  "catchability", "q", age = q_grid$age, survey = survey_codes[match(q_grid$survey, fleet_names)],
  value = q_value, se = q_value * q_grid$log_se,
  lwr = exp(q_grid$log_est - z * q_grid$log_se), upr = exp(q_grid$log_est + z * q_grid$log_se),
  unit = "native survey-index units per thousand fish",
  source_reference = paste0(model_url, "/run/model.RData; stockassessment::qtable(fit)"),
  notes = "Exponentiated native log-q; SE is natural-scale delta method and limits are 95% log-Wald intervals."
)

prediction <- exp(as.numeric(fit$rep$predObs))
if (length(prediction) != nrow(aux) || any(!is.finite(prediction))) {
  stop("Native SAM predictions do not align with the model observation rows.", call. = FALSE)
}
catch_prediction <- which(aux$fleet == 1L)
index_prediction <- which(aux$fleet > 1L)
prediction_outputs <- rbind(
  output_rows(
    "catch", "predicted_catch", year = aux$year[catch_prediction], age = aux$age[catch_prediction],
    value = prediction[catch_prediction], unit = "thousand fish", fleet = "Total catch",
    source_reference = paste0(model_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM catch prediction; includes model slots without an observed catch value."
  ),
  output_rows(
    "index", "predicted_index", year = aux$year[index_prediction], age = aux$age[index_prediction],
    value = prediction[index_prediction], unit = "native survey-index units",
    survey = survey_codes[aux$fleet[index_prediction]],
    source_reference = paste0(model_url, "/run/model.RData; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM survey prediction; native index scale is retained."
  )
)

report_table <- readLines(file.path(cache, "wgbfas_2025_section_02_cod_baltic_kattegat.txt"), warn = FALSE)
table_values <- function(marker, n_values, expected_years) {
  starts <- grep(marker, report_table, fixed = TRUE)
  if (!length(starts)) stop("Could not locate report table: ", marker, call. = FALSE)
  candidates <- report_table[seq.int(starts[[1L]] + 1L, min(length(report_table), starts[[1L]] + 160L))]
  parsed <- lapply(candidates, function(line) {
    fields <- strsplit(trimws(line), "\\s+")[[1L]]
    if (length(fields) != n_values + 1L || !grepl("^[0-9]{4}$", fields[[1L]])) return(NULL)
    values <- suppressWarnings(as.numeric(fields))
    if (any(!is.finite(values))) return(NULL)
    values
  })
  parsed <- Filter(Negate(is.null), parsed)
  parsed <- parsed[vapply(parsed, function(x) x[[1L]] %in% expected_years, logical(1))]
  years_found <- vapply(parsed, `[[`, numeric(1), 1L)
  if (!identical(as.integer(years_found), as.integer(expected_years))) {
    stop("Report table rows do not match expected years for ", marker, ".", call. = FALSE)
  }
  do.call(rbind, parsed)[, -1L, drop = FALSE]
}

z_table <- table_values("Table 2.3.25.   Western Baltic cod. Estimated total mortality by age", 5L, 1985:2024)
z_outputs <- do.call(rbind, c(
  lapply(1:4, function(age) output_rows(
    "mortality", "total_mortality_at_age", year = 1985:2024, age = age,
    value = z_table[, age], unit = "per year", source_type = "official_table",
    source_reference = paste0(tables_url, "; Table 2.3.25"),
    notes = "Rounded total mortality by age as reported; no uncertainty is shown."
  )),
  list(output_rows(
    "mortality", "total_mortality_at_age", year = 1985:2024, age_group = "5-7",
    value = z_table[, 5L], unit = "per year", source_type = "official_table",
    source_reference = paste0(tables_url, "; Table 2.3.25"),
    notes = "Rounded total mortality for the grouped ages 5-7; no age-specific split or uncertainty is reported."
  ))
))
harvest_table <- table_values("Table 2.3.26.   Western Baltic cod. Estimated harvest rate", 1L, 1985:2024)
harvest_outputs <- output_rows(
  "mortality", "harvest_rate", year = 1985:2024, value = harvest_table[, 1L], unit = "proportion",
  source_type = "official_table", source_reference = paste0(tables_url, "; Table 2.3.26"),
  notes = "Reported catch/SSB harvest rate; retained because the report uses it for advice instead of F."
)

total_n_years <- years[years <= 2024L]
total_n <- rowSums(n_surface[as.character(total_n_years), , drop = FALSE])
total_n_outputs <- output_rows(
  "population", "total_numbers", year = total_n_years, value = total_n,
  unit = "thousand fish", source_type = "derived_source_output",
  source_reference = paste0(model_url, "/run/model.RData; stockassessment::ntable(fit)"),
  notes = "Derived by summing all reported N-at-age from 0 through 7+; no uncertainty is available for this derived total."
)

outputs <- rbind(
  n_outputs, f_outputs,
  output_rows(
    "recruitment", "recruitment", year = years, age = 1L, age_group = "age 1",
    value = n_surface[as.character(years), "1"], unit = "thousand fish",
    se = n_se[match(years, n_grid$year) + (match(1L, ages) - 1L) * length(years)],
    lwr = n_low[match(years, n_grid$year) + (match(1L, ages) - 1L) * length(years)],
    upr = n_high[match(years, n_grid$year) + (match(1L, ages) - 1L) * length(years)],
    source_reference = paste0(model_url, "/run/model.RData; stockassessment::ntable(fit), age 1"),
    notes = "Age-1 recruitment is the same-year beginning-of-year N at age 1, matching Table 2.3.23. SEs and 95% log-Wald limits are conditional random-effect approximations."
  ),
  native_summary(stockassessment::ssbtable, "SSB", "tonnes", "biomass", notes = "Native SAM start-of-year SSB and reported 95% limits."),
  native_summary(stockassessment::tsbtable, "total_biomass", "tonnes", "biomass", notes = "Native SAM total stock biomass and reported 95% limits."),
  native_summary(stockassessment::fbartable, "Fbar", "per year", "mortality", age_group = "3-5", notes = "Native SAM arithmetic Fbar for ages 3-5 and reported 95% limits; the report cautions that F is unreliable for advice."),
  q_outputs, prediction_outputs, z_outputs, harvest_outputs, total_n_outputs
)

if (nrow(observations) != 540L || nrow(catch_weights) != 277L ||
  nrow(inputs) != 3737L || any(!is.finite(inputs$value)) ||
  any(!is.finite(outputs$value)) || anyDuplicated(paste(
    outputs$type, outputs$measure, outputs$year, outputs$age, outputs$age_group, outputs$survey
  ))) {
  stop("The WBCod2025 input/output rows differ from the reviewed source inventory.", call. = FALSE)
}
if (max(abs(n_surface[c("2024", "2025"), "1"] - c(16542, 26782))) > 0.5 ||
  max(abs(stockassessment::ssbtable(fit)[c("2024", "2025"), "Estimate"] - c(1714, 2452))) > 0.5 ||
  max(abs(stockassessment::fbartable(fit)[c("2024", "2025"), "Estimate"] - c(0.96, 0.96))) > 0.01 ||
  max(abs(stockassessment::tsbtable(fit)[c("2024", "2025"), "Estimate"] - c(3512, 4689))) > 1) {
  stop("The selected SAM run does not match the WGBFAS 2025 summary table.", call. = FALSE)
}
if (abs(n_surface["2025", "0"] - n_surface["2024", "0"]) > 1e-8) {
  stop("The unreported 2025 age-0 N value is not the duplicated prior-year model cell reviewed for omission.", call. = FALSE)
}

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025,
  terminal_year = 2025, estimate_terminal_year = 2025,
  assessment_type = "full_assessment", model_family = "SAM",
  model_version = paste0("WBCod2025; stockassessment ", utils::packageVersion("stockassessment")),
  is_current = TRUE, is_applied = TRUE, framework_year = 2019,
  assessment_url = report_url, framework_url = framework_url,
  data_url = paste0(model_url, "/data/"), model_url = model_url,
  repository_url = taf_url, assumptions_status = "complete",
  inputs_status = "complete", outputs_status = "complete",
  notes = paste(
    "2025 WGBFAS production assessment; catch observations end in 2024 and fitted model outputs extend through 2025.",
    "Exact SAM fit and native inputs are cached locally. Reported F is considered unreliable for advice; harvest rate is retained.",
    "The native catch likelihood weight of 0.1 in 2020-2024 is preserved, but its exact scale interpretation is unresolved."
  ), stringsAsFactors = FALSE, check.names = FALSE
)

append_csv <- function(x, path) {
  write.table(x, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8")
}
write.csv(stocks, stock_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
append_csv(assessment, file.path(database, "assessments.csv"))
append_csv(assumptions, file.path(database, "assumptions.csv"))
append_csv(inputs, file.path(database, "inputs.csv"))
append_csv(outputs, file.path(database, "outputs.csv"))

cat("Imported", assessment_id, "with", nrow(inputs), "input rows and", nrow(outputs), "output rows.\n")
