root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_haddock_7b_k_2026")
assessment_id <- "ices_haddock_celtic_sea_7b_k_2026"
stock_id <- "ck_ices_afwg_aeglefinus_is7bc_ek"
survey <- "FRA_IRL_IBTS"
years <- 1993:2025
ages <- 0:8

if (!requireNamespace("stockassessment", quietly = TRUE) ||
  !requireNamespace("rvest", quietly = TRUE)) {
  stop("Install stockassessment and rvest to read the official ICES run.", call. = FALSE)
}
source(file.path(root, "R", "read_database.R"))
db <- read_database()
if (assessment_id %in% db$assessments$assessment_id ||
  stock_id %in% db$assessments$stock_id) {
  stop("The Celtic Sea haddock assessment has already been imported.", call. = FALSE)
}
stock_index <- match(stock_id, db$stocks$stock_id)
if (is.na(stock_index)) stop("The Charbonneau–Keith stock row is missing.", call. = FALSE)

data_env <- new.env(parent = emptyenv())
load(file.path(cache, "run", "data.RData"), envir = data_env)
dat <- data_env$dat
model_env <- new.env(parent = emptyenv())
load(file.path(cache, "run", "model.RData"), envir = model_env)
sam <- model_env$fit

if (!identical(as.integer(dat$years), years) ||
  !identical(dim(sam$pl$logN), c(length(ages), length(years))) ||
  !identical(dim(sam$pl$logF), c(7L, length(years))) ||
  !identical(as.character(attr(dat, "fleetNames")), c("Residual catch", survey)) ||
  !isTRUE(all.equal(as.numeric(dat$sampleTimes), c(0, 0.875))) ||
  !identical(as.integer(dat$maxAgePerFleet), c(8L, 7L)) ||
  !isTRUE(as.integer(sam$opt$convergence) == 0L) || !isTRUE(sam$sdrep$pdHess)) {
  stop("The cached SAM run does not match the reviewed 1993–2025 model structure.", call. = FALSE)
}

stock <- db$stocks
stock$authority_stock_id[stock_index] <- "had.27.7b-k"
stock$common_name[stock_index] <- "Celtic Sea haddock"
stock$area[stock_index] <- "Divisions 7.b–k (southern Celtic Seas and English Channel)"
stock$notes[stock_index] <- paste(
  "Assessment identity verified against the 2026 ICES assessment and named SAM run HAD7bk_2026.",
  "Retains Charbonneau–Keith Master identifier ICES-AFWG_aeglefinus_IS7bc-ek."
)

assessment_add <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2025L,
  estimate_terminal_year = 2025L,
  assessment_type = "update_assessment",
  model_family = "SAM",
  model_version = "stockassessment 0.12.0; RemoteSha 1cc464b80f6f",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2020L,
  assessment_url = "https://doi.org/10.17895/ices.pub.32625759",
  framework_url = "https://doi.org/10.17895/ices.pub.5983",
  data_url = "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/HAD7bk_2026/data/",
  model_url = "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/HAD7bk_2026/run/model.RData",
  repository_url = "",
  assumptions_status = "complete",
  inputs_status = "complete",
  outputs_status = "partial",
  notes = paste(
    "Current official assessment applied for 2026 advice. The 2025 SAM run fits 1993–2025 at ages 0–8+, with age 8 as the plus group.",
    "All observation and biological inputs are recovered from the named native SAM data object and files. Core population estimates and annual summary outputs are recovered; fitted observation predictions and q parameter tables are not imported."
  ),
  stringsAsFactors = FALSE
)

assumption_row <- function(component, setting, value, source_reference, notes = "",
                            fleet = "", survey_name = "") {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = if (nzchar(fleet)) fleet else NA_character_,
    survey = if (nzchar(survey_name)) survey_name else NA_character_,
    sex = "combined", region = "ICES 7.b–k", season = NA_character_,
    setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions_add <- do.call(rbind, list(
  assumption_row("population", "model_years", "1993–2025", "run/data.RData (dat$years)"),
  assumption_row("population", "model_ages", "0–8+", "conf/model.cfg; run/data.RData",
    "Age 8 is the population and catch plus group; the survey index ends at age 7."),
  assumption_row("population", "recruitment_age", 0, "conf/model.cfg; res/*_tab1.html",
    "SAM reports recruitment at age 0."),
  assumption_row("N", "recruitment_process", "log recruitment random walk (stockRecruitmentModelCode 0)",
    "conf/model.cfg ($stockRecruitmentModelCode)"),
  assumption_row("N", "process_variance_groups", "Age 0 separate; ages 1–8 share one group",
    "conf/model.cfg ($keyVarLogN)"),
  assumption_row("F", "process", "Random walk over years with AR(1) correlation across ages",
    "conf/model.cfg ($corFlag, $keyLogFsta, $keyVarF)"),
  assumption_row("F", "age_state_groups", "Ages 1–6 separate; ages 7 and 8 share a state",
    "conf/model.cfg ($keyLogFsta)"),
  assumption_row("F", "Fbar_ages", "3–5", "conf/model.cfg ($fbarRange)"),
  assumption_row("M", "natural_mortality", "Fixed age-specific values from nm.dat",
    "data/nm.dat; run/data.RData (dat$natMor)"),
  assumption_row("catch", "fleet", "Residual catch combines landings and discards",
    "data/cn.dat; WGCSE 2026, section 10.3.2 and Table 10.3–10.4"),
  assumption_row("catch", "observation_likelihood", "Lognormal; one observation variance shared across ages",
    "conf/model.cfg ($obsLikelihoodFlag, $keyVarObs)"),
  assumption_row("catch", "relative_likelihood_weights", "Per-observation weights are retained from dat$weight; fixVarToWeight = 0",
    "conf/model.cfg ($fixVarToWeight); run/data.RData (dat$weight)",
    "Weights are relative likelihood weights, not direct standard errors.", fleet = "Residual catch"),
  assumption_row("index", "survey", "Combined French EVHOE Q4 WIBTS and Irish IGFS Q4 WIBTS; standardized using VAST",
    "WGCSE 2026, section 10.3.4; data/survey.dat", survey_name = survey),
  assumption_row("index", "age_range", "0–7; separate catchability by age",
    "data/survey.dat; conf/model.cfg ($keyLogFpar)", survey_name = survey),
  assumption_row("index", "sampling_time", 0.875,
    "data/survey.dat; run/data.RData (dat$sampleTimes)",
    "Fourth-quarter index timing as encoded in the official SAM input.", survey_name = survey),
  assumption_row("index", "observation_likelihood", "Lognormal; independent observation errors",
    "conf/model.cfg ($obsLikelihoodFlag, $obsCorStruct)", survey_name = survey),
  assumption_row("index", "observation_variance_groups", "Ages 0–5 share one variance; ages 6–7 share another",
    "conf/model.cfg ($keyVarObs)", survey_name = survey),
  assumption_row("index", "index_scale", "VAST age-specific index; physical unit or multiplier not stated",
    "WGCSE 2026, Table 10.5; data/survey.dat",
    "Values are retained on their native index scale; no absolute abundance multiplier is inferred.", survey_name = survey),
  assumption_row("biology", "stock_weight", "Three-year running average; discards included",
    "data/sw.dat; WGCSE 2026, section 10.3.2"),
  assumption_row("biology", "maturity", "Fixed age-specific proportions",
    "data/mo.dat; WGCSE 2026, section 10.3.3"),
  assumption_row("biology", "pre_spawning_mortality", "Fraction of F and M before spawning is zero",
    "data/pf.dat; data/pm.dat; run/data.RData (dat$propF, dat$propM)"),
  assumption_row("assessment", "source_run", "HAD7bk_2026; SAM fit to 2025 data",
    "WGCSE 2026, section 10; run/model.RData; run/ver",
    "WGCSE states the assessment followed the stock annex except for the 2026–2027 recruitment assumption; no forecast years are imported.")
))

inputs_add <- list()
add_inputs <- function(type, measure, basis, value, year = NA_integer_,
                       age = NA_integer_, fleet = NA_character_,
                       survey_name = NA_character_, unit, sampling_time = NA_real_,
                       source_reference, transformation = "", notes = "") {
  n <- length(value)
  inputs_add[[length(inputs_add) + 1L]] <<- data.frame(
    assessment_id = rep(assessment_id, n), type = rep(type, n),
    measure = rep(measure, n), basis = rep(basis, n),
    fleet = rep(fleet, length.out = n), survey = rep(survey_name, length.out = n),
    sex = rep("combined", n), region = rep("ICES 7.b–k", n),
    season = rep(NA_character_, n), year = rep(year, length.out = n),
    year_basis = ifelse(is.na(rep(year, length.out = n)), NA_character_, "calendar_year"),
    age = rep(age, length.out = n), value = as.numeric(value),
    unit = rep(unit, n), sampling_time = rep(sampling_time, length.out = n),
    source_type = rep("native_model", n),
    source_reference = rep(source_reference, n),
    transformation = rep(transformation, n), notes = rep(notes, n),
    observation_id = NA_character_, length_bin = NA_character_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = NA_character_, partition = NA_character_,
    stringsAsFactors = FALSE
  )
}
add_annual_surface <- function(type, measure, basis, surface, unit,
                               source_reference, transformation = "", notes = "") {
  surface <- as.matrix(surface)
  if (!identical(dim(surface), c(length(years), length(ages)))) {
    stop("Unexpected annual surface dimensions for ", measure, call. = FALSE)
  }
  add_inputs(type, measure, basis, as.vector(surface),
    year = rep(years, times = length(ages)), age = rep(ages, each = length(years)),
    unit = unit, source_reference = source_reference,
    transformation = transformation, notes = notes)
}
add_static_surface <- function(type, measure, basis, surface, unit,
                               source_reference, notes = "") {
  surface <- as.matrix(surface)
  if (!identical(dim(surface), c(length(years), length(ages))) ||
    any(apply(surface, 2, function(x) length(unique(x)) != 1L))) {
    stop("Expected a time-invariant age surface for ", measure, call. = FALSE)
  }
  add_inputs(type, measure, basis, surface[1, ], age = ages, unit = unit,
    source_reference = source_reference, notes = notes)
}

observation_rows <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
observation_rows$value <- exp(dat$logobs)
observation_rows$weight <- dat$weight
catch_obs <- observation_rows[observation_rows$fleet == 1L, , drop = FALSE]
index_obs <- observation_rows[observation_rows$fleet == 2L, , drop = FALSE]
if (nrow(catch_obs) != length(years) * length(ages) ||
  nrow(index_obs) != 23L * 8L ||
  sum(!is.finite(index_obs$value)) != 1L ||
  !any(index_obs$year == 2005L & index_obs$age == 7L & is.na(index_obs$value))) {
  stop("Unexpected catch or index observation coverage in the native SAM data.", call. = FALSE)
}
catch_obs$value[is.na(catch_obs$value)] <- 0
add_inputs("catch", "numbers_at_age", "numbers", catch_obs$value,
  year = catch_obs$year, age = catch_obs$age, fleet = "Residual catch",
  unit = "thousand fish", sampling_time = 0,
  source_reference = "data/cn.dat; run/data.RData (dat$aux, dat$logobs)",
  transformation = "exp(logobs); zero cells retained from cn.dat where logobs is NA",
  notes = "Combined landings and discards. Age 8 is the plus group. SAM does not fit zero age-0 catch cells because their log observations are NA.")
add_inputs("index", "numbers_at_age", "index_scale", index_obs$value,
  year = index_obs$year, age = index_obs$age, survey_name = survey,
  unit = "survey index (unit unresolved)", sampling_time = 0.875,
  source_reference = "data/survey.dat; run/data.RData (dat$aux, dat$logobs)",
  transformation = "exp(logobs)",
  notes = "Native VAST index scale; Table 10.5 does not state a physical unit or multiplier.")
keep_weight <- is.finite(catch_obs$weight) & is.finite(catch_obs$value) & catch_obs$weight > 0
add_inputs("catch", "relative_precision_weight", "relative_precision",
  catch_obs$weight[keep_weight], year = catch_obs$year[keep_weight],
  age = catch_obs$age[keep_weight], fleet = "Residual catch",
  unit = "relative likelihood weight",
  source_reference = "run/data.RData (dat$weight); conf/model.cfg ($fixVarToWeight)",
  notes = "Relative likelihood weight; fixVarToWeight=0, so this is not a direct SD or CV.")

add_annual_surface("weight", "weight_at_age", "kg_per_fish", dat$stockMeanWeight,
  "kg/fish", "data/sw.dat; run/data.RData (dat$stockMeanWeight)",
  notes = "Three-year running average; discards included. Age 8 is 8+.")
add_annual_surface("catch_weight", "weight_at_age", "kg_per_fish", dat$catchMeanWeight[, , 1],
  "kg/fish", "data/cw.dat; run/data.RData (dat$catchMeanWeight)",
  notes = "Combined catch weight-at-age; age 8 is 8+.")
add_annual_surface("biology", "landings_weight_at_age", "kg_per_fish", dat$landMeanWeight[, , 1],
  "kg/fish", "data/lw.dat; run/data.RData (dat$landMeanWeight)",
  notes = "Age 8 is 8+.")
add_annual_surface("biology", "discard_weight_at_age", "kg_per_fish", dat$disMeanWeight[, , 1],
  "kg/fish", "data/dw.dat; run/data.RData (dat$disMeanWeight)",
  notes = "Age 8 is 8+.")
add_annual_surface("biology", "landings_fraction_at_age", "proportion", dat$landFrac[, , 1],
  "proportion", "data/lf.dat; run/data.RData (dat$landFrac)",
  notes = "Fraction of combined catch landed; age 8 is 8+.")
add_static_surface("maturity", "maturity_at_age", "proportion", dat$propMat,
  "proportion", "data/mo.dat; run/data.RData (dat$propMat)")
add_static_surface("M", "natural_mortality_at_age", "per_year", dat$natMor,
  "per year", "data/nm.dat; run/data.RData (dat$natMor)")
add_static_surface("biology", "fraction_F_before_spawning", "proportion", dat$propF[, , 1],
  "proportion", "data/pf.dat; run/data.RData (dat$propF)")
add_static_surface("biology", "fraction_M_before_spawning", "proportion", dat$propM,
  "proportion", "data/pm.dat; run/data.RData (dat$propM)")
inputs_add <- do.call(rbind, inputs_add)

output_add <- list()
add_output <- function(type, measure, value, year = NA_integer_, age = NA_integer_,
                       age_group = NA_character_, unit, se = NA_real_,
                       lwr = NA_real_, upr = NA_real_, source_type = "native_model",
                       source_reference, notes = "") {
  n <- length(value)
  output_add[[length(output_add) + 1L]] <<- data.frame(
    assessment_id = rep(assessment_id, n), type = rep(type, n),
    measure = rep(measure, n), fleet = NA_character_, survey = NA_character_,
    sex = "combined", region = "ICES 7.b–k", season = NA_character_,
    year = rep(year, length.out = n), age = rep(age, length.out = n),
    age_group = rep(age_group, length.out = n), value = as.numeric(value),
    se = rep(se, length.out = n), lwr = rep(lwr, length.out = n),
    upr = rep(upr, length.out = n), unit = rep(unit, n),
    source_type = rep(source_type, n), source_reference = rep(source_reference, n),
    notes = rep(notes, n), stringsAsFactors = FALSE
  )
}

n_at_age <- exp(sam$pl$logN)
n_se <- n_at_age * sam$plsd$logN
add_output("population", "numbers_at_age", as.vector(n_at_age),
  year = rep(years, each = length(ages)), age = rep(ages, times = length(years)),
  age_group = rep(c(rep(NA_character_, length(ages) - 1L), "8+"), times = length(years)),
  se = as.vector(n_se), unit = "thousand fish",
  source_reference = "run/model.RData (fit$pl$logN, fit$plsd$logN); WGCSE 2026, Table 10.7",
  notes = "Start-of-year abundance. SE is on the natural scale by the delta method from the SAM log-state SE. Age 8 is 8+.")

f_surface <- matrix(0, nrow = length(ages), ncol = length(years))
f_se <- matrix(NA_real_, nrow = length(ages), ncol = length(years))
f_surface[2:8, ] <- exp(sam$pl$logF)
f_surface[9, ] <- f_surface[8, ]
f_se[2:8, ] <- f_surface[2:8, ] * sam$plsd$logF
f_se[9, ] <- f_se[8, ]
add_output("mortality", "fishing_mortality_at_age", as.vector(f_surface),
  year = rep(years, each = length(ages)), age = rep(ages, times = length(years)),
  age_group = rep(c(rep(NA_character_, length(ages) - 1L), "8+"), times = length(years)),
  se = as.vector(f_se), unit = "per year",
  source_reference = "run/model.RData (fit$pl$logF, fit$plsd$logF); WGCSE 2026, Table 10.6",
  notes = "Natural-scale F; age 0 is fixed at zero. SEs for estimated log-F states are delta-method approximations. Ages 7 and 8 share one SAM state.")

tab1_path <- file.path(cache, "res", "xxx-00-00.00.00_tab1.html")
tab1 <- rvest::html_table(rvest::read_html(tab1_path), fill = TRUE)[[1]]
summary_rows <- seq.int(5L, nrow(tab1) - 1L)
summary_years <- suppressWarnings(as.integer(trimws(tab1$X1[summary_rows])))
number <- function(x) suppressWarnings(as.numeric(gsub(",", "", trimws(x), fixed = TRUE)))
if (!identical(summary_years, years)) stop("SAM summary table years are incomplete.", call. = FALSE)
summary_values <- lapply(2:13, function(i) number(tab1[[paste0("X", i)]][summary_rows]))
names(summary_values) <- c("recruitment", "recruitment_lwr", "recruitment_upr",
  "SSB", "SSB_lwr", "SSB_upr", "Fbar", "Fbar_lwr", "Fbar_upr",
  "total_biomass", "total_biomass_lwr", "total_biomass_upr")
if (any(!vapply(summary_values, function(x) all(is.finite(x)), logical(1)))) {
  stop("SAM summary output table contains missing or non-numeric values.", call. = FALSE)
}
add_output("population", "recruitment", as.numeric(n_at_age[1, ]),
  year = years, age = 0L, se = as.numeric(n_se[1, ]),
  lwr = summary_values$recruitment_lwr, upr = summary_values$recruitment_upr,
  unit = "thousand fish", source_type = "native_model",
  source_reference = "run/model.RData (fit$pl$logN); res/*_tab1.html",
  notes = "Recruitment at age 0; the SAM summary table reports rounded Low/High limits. Natural-scale SE uses the delta method from the log-state SE.")
add_output("biomass", "SSB", summary_values$SSB, year = years,
  lwr = summary_values$SSB_lwr, upr = summary_values$SSB_upr,
  unit = "tonnes", source_type = "native_model",
  source_reference = "res/xxx-00-00.00.00_tab1.html; WGCSE 2026, Table 10.8",
  notes = "SAM-reported spawning-stock biomass and Low/High limits; interval confidence level is not specified in the table.")
add_output("biomass", "total_biomass", summary_values$total_biomass, year = years,
  lwr = summary_values$total_biomass_lwr, upr = summary_values$total_biomass_upr,
  unit = "tonnes", source_type = "native_model",
  source_reference = "res/xxx-00-00.00.00_tab1.html",
  notes = "SAM-reported total stock biomass (TSB); interval confidence level is not specified in the table.")
add_output("mortality", "Fbar", summary_values$Fbar, year = years,
  age_group = "3–5", lwr = summary_values$Fbar_lwr, upr = summary_values$Fbar_upr,
  unit = "per year", source_type = "native_model",
  source_reference = "conf/model.cfg ($fbarRange); res/xxx-00-00.00.00_tab1.html",
  notes = "SAM-reported arithmetic mean F at ages 3–5; interval confidence level is not specified in the table.")
add_output("population", "total_numbers", colSums(n_at_age), year = years,
  unit = "thousand fish", source_type = "derived_source_output",
  source_reference = "run/model.RData (fit$pl$logN)",
  notes = "Derived by summing the official start-of-year N-at-age estimates across ages 0–8+. Uncertainty is unavailable for the sum.")
outputs_add <- do.call(rbind, output_add)

append_rows <- function(path, rows) {
  columns <- names(utils::read.csv(path, nrows = 0, check.names = FALSE))
  if (!setequal(names(rows), columns)) stop("Column mismatch in ", basename(path), call. = FALSE)
  rows <- rows[columns]
  if (identical(Sys.getenv("TINYAM_DATABASE_DRY_RUN"), "true")) return(invisible(rows))
  utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "")
  invisible(rows)
}

paths <- file.path(database, c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv"))
if (identical(Sys.getenv("TINYAM_DATABASE_DRY_RUN"), "true")) {
  rows <- list(assessment_add, assumptions_add, inputs_add, outputs_add)
  for (i in seq_along(rows)) append_rows(paths[i + 1L], rows[[i]])
  cat("Dry run passed: ", nrow(inputs_add), " inputs and ", nrow(outputs_add),
    " outputs validated; database files were not changed.\n", sep = "")
} else {
  utils::write.csv(stock, paths[1], row.names = FALSE, na = "")
  append_rows(paths[2], assessment_add)
  append_rows(paths[3], assumptions_add)
  append_rows(paths[4], inputs_add)
  append_rows(paths[5], outputs_add)
  cat("Imported ", assessment_id, ": ", nrow(inputs_add), " inputs and ",
    nrow(outputs_add), " outputs. See the source review for scope and limitations.\n", sep = "")
}
