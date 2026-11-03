assessment_id <- "ices_bluewhiting_northeast_atlantic_2026"
stock_id <- "ices_bluewhiting_northeast_atlantic"
root <- "."
source_dir <- file.path(root, "source_cache", assessment_id)
model_file <- file.path(source_dir, "BW-2026.rds")

if (!file.exists(model_file)) stop("The cached BW-2026 model object is missing.")

sam <- readRDS(model_file)
sam_data <- sam$data
sam_conf <- sam$conf
years <- as.integer(sam_data$years)
ages <- seq.int(sam_data$minAgePerFleet[[1L]], sam_data$maxAgePerFleet[[1L]])
model_reference <- paste(
  "stockassessment.org BW-2026 model.RData",
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/BW-2026/run/model.RData"
)
advice_url <- "https://www.hafogvatn.is/static/extras/images/34_whb_2026_1_advice_en.html"
technical_report_url <- "https://www.hafogvatn.is/static/extras/images/34_whb_2026_1_techreport_en.html"
wg_report_url <- "https://www.hav.fo/wp-content/uploads/2025/10/WGWIDE-2025_02-blue-whiting.pdf"

append_rows <- function(path, rows, id_column = "assessment_id",
                        id_value = assessment_id) {
  current <- utils::read.csv(path,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE
  )
  if (any(current[[id_column]] == id_value, na.rm = TRUE)) {
    stop("Assessment rows already exist in ", basename(path), ".")
  }
  utils::write.table(rows, path,
    sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       survey = NA_character_, fleet = NA_character_,
                       season = NA_character_, sampling_time = NA_real_,
                       transformation = "Copied from the official native SAM model object.",
                       notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    basis = basis,
    fleet = rep(fleet, length.out = n),
    survey = rep(survey, length.out = n),
    sex = NA_character_,
    region = NA_character_,
    season = rep(season, length.out = n),
    year = year,
    year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = age,
    value = value,
    unit = unit,
    sampling_time = rep(sampling_time, length.out = n),
    source_type = "native_model",
    source_reference = model_reference,
    transformation = transformation,
    notes = notes,
    observation_id = NA_character_,
    length_bin = NA_real_,
    length_bin_lower = NA_real_,
    length_bin_upper = NA_real_,
    sample_size = NA_real_,
    age_error = NA_character_,
    partition = NA_character_,
    stringsAsFactors = FALSE
  )
}

surface_inputs <- function(surface, type, measure, basis, unit, notes = "") {
  surface <- as.matrix(surface)
  grid <- expand.grid(year = years, age = ages)
  input_rows(
    type = type,
    measure = measure,
    basis = basis,
    year = grid$year,
    age = grid$age,
    value = as.vector(surface),
    unit = unit,
    notes = notes
  )
}

aux <- as.data.frame(sam_data$aux)
names(aux) <- c("year", "fleet", "age")
obs <- exp(sam_data$logobs)
observation_rows <- data.frame(aux, value = obs)
catch <- observation_rows[observation_rows$fleet == 1L, , drop = FALSE]
index <- observation_rows[observation_rows$fleet == 2L &
  is.finite(observation_rows$value), , drop = FALSE]

inputs <- rbind(
  input_rows(
    "catch", "numbers_at_age", "numbers", catch$year, catch$age,
    catch$value, "thousand fish",
    fleet = "Commercial catch",
    transformation = "Exponentiated natural-log catch observations from the official SAM data object.",
    notes = "SAM fleet 1 is the single aggregate commercial catch stream."
  ),
  input_rows(
    "index", "numbers_at_age", "numbers", index$year, index$age,
    index$value, "million fish",
    survey = "IBWSS", season = "spring",
    sampling_time = sam_data$sampleTimes[[2L]],
    transformation = "Exponentiated natural-log IBWSS observations from the official SAM data object.",
    notes = "SAM fleet 2; the source table reports abundance in millions. No survey observations are present in 2010 or 2020."
  ),
  surface_inputs(
    sam_data$stockMeanWeight, "weight", "weight_at_age",
    "kg_per_fish", "kg", "Annual stock weights from the official fit."
  ),
  surface_inputs(
    sam_data$catchMeanWeight[, , 1L], "catch_weight",
    "weight_at_age", "kg_per_fish", "kg",
    "Annual commercial catch weights from the official fit."
  ),
  surface_inputs(
    sam_data$propMat, "maturity", "maturity_at_age",
    "proportion", "proportion",
    "The model repeats the time-invariant maturity ogive across years."
  ),
  surface_inputs(
    sam_data$natMor, "M", "natural_mortality_at_age",
    "per_year", "per year",
    "Fixed time-invariant natural mortality repeated across years."
  )
)

assumption <- function(component, setting, value, notes = "",
                       fleet = NA_character_, survey = NA_character_,
                       source_reference = model_reference) {
  data.frame(
    assessment_id = assessment_id,
    component = component,
    fleet = fleet,
    survey = survey,
    sex = NA_character_,
    region = NA_character_,
    season = NA_character_,
    setting = setting,
    value = value,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("assessment", "assessment_type", "Full age-structured assessment"),
  assumption("assessment", "model_name", "SAM"),
  assumption("assessment", "model_object", "BW-2026"),
  assumption(
    "assessment", "stockassessment_version",
    as.character(utils::packageVersion("stockassessment")),
    paste("RemoteSha", utils::packageDescription("stockassessment")[["RemoteSha"]])
  ),
  assumption("population", "model_years", paste(range(years), collapse = "-")),
  assumption("population", "model_ages", paste(range(ages), collapse = "-")),
  assumption("population", "recruitment_age", "1"),
  assumption("population", "plus_group_age", "10"),
  assumption("population", "Fbar_ages", paste(sam_conf$fbarRange, collapse = "-")),
  assumption("catch", "catch_streams", "1", "One aggregate commercial catch stream."),
  assumption(
    "F", "process", "Random walk with age-correlated increments",
    "Ages 1-9 have separate states; age 10+ shares the age-9 state."
  ),
  assumption(
    "F", "process_variance_sharing", "One shared F process variance",
    "The SAM keyVarF configuration shares the process variance across ages."
  ),
  assumption(
    "F", "process_correlation", "Age-correlated increments",
    "The official SAM fit has corFlag = 2."
  ),
  assumption(
    "N", "process_variance_sharing", "Age 1 separate; ages 2-10 shared",
    "Recruitment age has its own variance group; all older ages share another."
  ),
  assumption(
    "M", "natural_mortality", "0.2 per year at all ages",
    "Fixed, time-invariant natural mortality from the official fit."
  ),
  assumption("maturity", "maturity_at_age",
    "0.11, 0.40, 0.82, 0.86, 0.91, 0.94, then 1.00 at ages 7-10",
    "Time-invariant maturity ogive estimated in 1994 by combining southern and northern areas.",
    source_reference = "ICES 2026 advice; WGWIDE 2025, Table 2.3.5.1"
  ),
  assumption(
    "weight", "stock_and_catch_weights",
    "Annual age-specific stock and catch weights",
    "The official SAM object supplies both surfaces."
  ),
  assumption("catch", "observation_likelihood", "Lognormal"),
  assumption("index", "observation_likelihood", "Lognormal",
    survey = "IBWSS"
  ),
  assumption("catch", "observation_correlation", "AR across ages",
    fleet = "Commercial catch"
  ),
  assumption("index", "observation_correlation", "AR across ages",
    survey = "IBWSS"
  ),
  assumption(
    "catch", "observation_variance_age_groups",
    "Age 1; age 2; ages 3-8; ages 9-10"
  ),
  assumption("index", "observation_variance_age_groups",
    "Age 1; age 2; age 3; ages 4-6; ages 7-8",
    survey = "IBWSS"
  ),
  assumption("index", "survey_catchability_age_groups",
    "Age 1; age 2; age 3; age 4; ages 5-8",
    survey = "IBWSS"
  ),
  assumption("index", "survey_catchability_power", "None",
    "All keyQpow entries are disabled.",
    survey = "IBWSS"
  ),
  assumption("index", "sampling_time", "0.245",
    "Proportion of year for the spring IBWSS survey.",
    survey = "IBWSS"
  ),
  assumption("advice", "2026_recruitment_adjustment",
    "39,366,774 thousand fish",
    "For advice, the model-estimated 2026 recruitment was replaced by the 75th percentile of the 1996-2025 geometric mean; this advice adjustment is not part of the native SAM fit.",
    source_reference = advice_url
  )
))

output_rows <- function(type, measure, year, age = NA_integer_, age_group = NA_character_,
                        value, se = NA_real_, lwr = NA_real_, upr = NA_real_, unit,
                        survey = NA_character_, fleet = NA_character_, notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    fleet = rep(fleet, length.out = n),
    survey = rep(survey, length.out = n),
    sex = NA_character_,
    region = NA_character_,
    season = NA_character_,
    year = year,
    age = rep(age, length.out = n),
    age_group = rep(age_group, length.out = n),
    value = value,
    se = rep(se, length.out = n),
    lwr = rep(lwr, length.out = n),
    upr = rep(upr, length.out = n),
    unit = unit,
    source_type = "native_model",
    source_reference = model_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

surface_output <- function(surface, type, measure, unit, se = NULL,
                           age_group = NA_character_, notes = "") {
  surface <- as.matrix(surface)
  grid <- expand.grid(
    year = as.integer(rownames(surface)),
    age = as.integer(colnames(surface))
  )
  if (length(age_group) > 1L) {
    age_group <- age_group[match(grid$age, as.integer(colnames(surface)))]
  }
  surface_se <- if (is.null(se)) rep(NA_real_, length(surface)) else as.vector(se)
  output_rows(type, measure, grid$year, grid$age, age_group,
    as.vector(surface), surface_se,
    unit = unit, notes = notes
  )
}

summary_output <- function(x, type, measure, unit, notes = "",
                           age_group = NA_character_) {
  x <- as.data.frame(x)
  output_rows(type, measure, as.integer(rownames(x)),
    age_group = age_group,
    value = x$Estimate,
    lwr = x$Low, upr = x$High, unit = unit, notes = notes
  )
}

n_est <- stockassessment::ntable(sam)
f_est <- stockassessment::faytable(sam)
n_se <- n_est * t(sam$plsd$logN)
f_log_se <- t(sam$plsd$logF)
f_se <- f_est[, seq_len(ncol(f_log_se)), drop = FALSE] * f_log_se
f_se <- cbind(f_se, f_se[, ncol(f_se)])
dimnames(f_se) <- dimnames(f_est)
f_est[, ncol(f_est)] <- f_est[, ncol(f_est) - 1L]

q_key <- sam_conf$keyLogFpar[2L, ]
q_age <- which(q_key >= 0L)
q_value <- exp(sam$pl$logFpar[q_key[q_age] + 1L])
q_groups <- vapply(q_age, function(a) {
  ages_in_group <- q_age[q_key[q_age] == q_key[a]]
  if (length(ages_in_group) == 1L) {
    as.character(a)
  } else {
    paste0(min(ages_in_group), "-", max(ages_in_group))
  }
}, character(1))

aux$prediction <- exp(sam$rep$predObs)
predictions <- rbind(
  output_rows("catch", "predicted_catch", aux$year[aux$fleet == 1L],
    aux$age[aux$fleet == 1L],
    value = aux$prediction[aux$fleet == 1L],
    unit = "thousand fish", fleet = "Commercial catch",
    notes = "Exponentiated SAM log-scale fitted predictions."
  ),
  output_rows("index", "predicted_index", aux$year[aux$fleet == 2L],
    aux$age[aux$fleet == 2L],
    value = aux$prediction[aux$fleet == 2L],
    unit = "million fish", survey = "IBWSS",
    notes = "Exponentiated SAM log-scale fitted predictions."
  )
)

sd_outputs <- rbind(
  output_rows("population", "process_sd",
    year = NA_integer_,
    age_group = c("1", "2-10"), value = exp(sam$pl$logSdLogN),
    unit = "log-scale SD",
    notes = "Fitted N-process standard deviation on log states."
  ),
  output_rows("mortality", "process_sd",
    year = NA_integer_,
    age_group = "1-10", value = exp(sam$pl$logSdLogFsta),
    unit = "log-scale SD",
    notes = "Fitted age-correlated F-increment standard deviation on log states."
  ),
  output_rows("catch", "observation_sd",
    year = NA_integer_,
    age_group = c("1", "2", "3-8", "9-10"),
    value = exp(sam$pl$logSdLogObs[1:4]), unit = "log-scale SD",
    fleet = "Commercial catch",
    notes = "Fitted SD of log catch observations; the source model also correlates residuals across ages."
  ),
  output_rows("index", "observation_sd",
    year = NA_integer_,
    age_group = c("1", "2", "3", "4-6", "7-8"),
    value = exp(sam$pl$logSdLogObs[5:9]), unit = "log-scale SD",
    survey = "IBWSS",
    notes = "Fitted SD of log survey observations; the source model also correlates residuals across ages."
  )
)

outputs <- rbind(
  surface_output(n_est, "population", "numbers_at_age", "thousand fish",
    se = n_se,
    age_group = ifelse(ages == max(ages), "10+", NA_character_),
    notes = "Conditional log-state SE converted to the natural scale by the delta method; no at-age 95% interval is supplied."
  ),
  surface_output(f_est, "mortality", "fishing_mortality_at_age", "per year",
    se = f_se,
    age_group = ifelse(ages == max(ages), "10+", NA_character_),
    notes = "Age 10+ shares the age-9 F state. Conditional log-state SE converted to the natural scale by the delta method; no at-age 95% interval is supplied."
  ),
  surface_output(sam_data$natMor, "mortality", "natural_mortality_at_age",
    "per year",
    age_group = ifelse(ages == max(ages), "10+", NA_character_),
    notes = "Fixed supplied natural mortality, not an estimated output."
  ),
  summary_output(
    stockassessment::ssbtable(sam), "biomass", "SSB", "tonnes",
    "Estimate and 95% confidence interval reported in the 2026 advice."
  ),
  summary_output(
    stockassessment::tsbtable(sam), "biomass", "total_biomass", "tonnes",
    "Estimate and 95% confidence interval from the official assessment."
  ),
  summary_output(
    stockassessment::rectable(sam), "recruitment", "recruitment",
    "thousand fish",
    "Age-1 recruitment; estimate and 95% confidence interval reported in the 2026 advice."
  ),
  summary_output(stockassessment::fbartable(sam), "mortality", "Fbar", "per year",
    "Estimate and 95% confidence interval reported in the 2026 advice.",
    age_group = "3-7"
  ),
  output_rows("catchability", "q",
    year = NA_integer_, age = q_age,
    age_group = q_groups, value = q_value, unit = "index per abundance unit",
    survey = "IBWSS", notes = "Exponentiated SAM log-q parameter; shared across the documented age groups."
  ),
  predictions,
  sd_outputs
)

stopifnot(nrow(catch) == length(years) * length(ages))
stopifnot(nrow(index) == 168L)
stopifnot(all(dim(sam_data$stockMeanWeight) == c(length(years), length(ages))))
stopifnot(isTRUE(sam$opt$convergence == 0L), isTRUE(sam$sdrep$pdHess))

stocks <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "ICES",
  authority_stock_id = "whb.27.1-91214",
  scientific_name = "Micromesistius poutassou",
  common_name = "Northeast Atlantic blue whiting",
  area = "ICES Subareas 1-9, 12, and 14",
  region = "Northeast Atlantic",
  ocean = "Northeast Atlantic",
  notes = "Current stock code whb.27.1-91214; age-structured SAM assessment.",
  stringsAsFactors = FALSE
)

assessments <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = max(years),
  estimate_terminal_year = max(years),
  assessment_type = "full_assessment",
  model_family = "SAM",
  model_version = "Official 2026 SAM run, BW-2026",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2026L,
  assessment_url = advice_url,
  framework_url = wg_report_url,
  data_url = technical_report_url,
  model_url = "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/BW-2026/run/model.RData",
  repository_url = NA_character_,
  assumptions_status = "complete",
  inputs_status = "complete",
  outputs_status = "complete",
  notes = paste(
    "Official 2026 assessment; the 2026 advice was published 30 September 2026.",
    "The native BW-2026 SAM object supplies fitted observations, biological inputs, configuration, and output surfaces.",
    "For advice, 2026 model recruitment was replaced by a management forecast assumption; this is recorded separately and does not alter the native fit outputs."
  ),
  stringsAsFactors = FALSE
)

stocks_file <- file.path(root, "database", "stocks.csv")
append_rows(stocks_file, stocks, id_column = "stock_id", id_value = stock_id)
append_rows(file.path(root, "database", "assessments.csv"), assessments)
append_rows(file.path(root, "database", "assumptions.csv"), assumptions)
append_rows(file.path(root, "database", "inputs.csv"), inputs)
append_rows(file.path(root, "database", "outputs.csv"), outputs)
