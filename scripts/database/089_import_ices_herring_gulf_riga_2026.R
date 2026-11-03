assessment_id <- "ices_herring_gulf_riga_2026"
stock_id <- "ck_ices_wgbfas_harengus_bs_28_1"
root <- "."
cache <- file.path(root, "source_cache", stock_id, "assessment_2026")
db <- file.path(root, "database")
model_file <- file.path(cache, "run_model.RData")
if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to run this source importer.", call. = FALSE)
}
if (!file.exists(model_file)) stop("The cached official SAM fit is missing.", call. = FALSE)

model_env <- new.env(parent = emptyenv())
load(model_file, envir = model_env)
sam <- model_env$fit
sam_data <- sam$data
sam_conf <- sam$conf
if (is.null(sam) || sam$opt$convergence != 0L) {
  stop("The cached SAM fit is not the converged official run.", call. = FALSE)
}

report <- "ICES. 2026. Baltic Fisheries Assessment Working Group (WGBFAS). ICES Scientific Reports 8:39, section 4.4. doi:10.17895/ices.pub.32455056"
report_url <- "https://doi.org/10.17895/ices.pub.32455056"
framework <- "ICES. 2023. Benchmark Workshop on Baltic Pelagic stocks (WKBBALTPEL). ICES Scientific Reports 5:47. doi:10.17895/ices.pub.23216492"
framework_url <- "https://doi.org/10.17895/ices.pub.23216492"
advice_url <- "https://doi.org/10.17895/ices.advice.30932084"
graphs_url <- "https://standardgraphs.ices.dk/ViewCharts.aspx?key=22423"
model_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/GoR_WGBFAS_2026/run/model.RData"
data_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/GoR_WGBFAS_2026/data/"
model_reference <- paste("Official WGBFAS 2026 SAM run GoR_WGBFAS_2026;", model_url)

paths <- setNames(
  file.path(db, paste0(c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
stocks <- read_db("stocks")
if (sum(stocks$stock_id == stock_id) != 1L ||
  assessment_id %in% read_db("assessments")$assessment_id) {
  stop("Expected one catalogue stock row and no existing assessment record.", call. = FALSE)
}

years <- as.integer(sam_data$years)
ages <- as.integer(colnames(sam_data$stockMeanWeight))
aux <- as.data.frame(sam_data$aux)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
aux$obs <- exp(sam_data$logobs)
aux$prediction <- exp(sam$rep$predObs)
fleet_names <- attr(sam_data, "fleetNames")
if (length(fleet_names) != 2L || !identical(as.numeric(sam_data$sampleTimes[2L]), 0.675)) {
  stop("Unexpected fleet identities or GRAHS sampling time in the official fit.", call. = FALSE)
}
if (!identical(years, 1977:2025) || !identical(ages, 0:8) ||
  sum(aux$fleet == 1L) != 49L * 9L || sum(aux$fleet == 2L) != 27L * 8L) {
  stop("Unexpected year, age, or observation coverage in the official fit.", call. = FALSE)
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       transformation = "Copied from the converged official SAM model object.",
                       notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = rep_len(fleet, n), survey = rep_len(survey, n),
    sex = "combined", region = "ICES Subdivision 28.1 Gulf of Riga stock",
    season = "", year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
    value = value, unit = unit, sampling_time = rep_len(sampling_time, n),
    source_type = "native_model", source_reference = model_reference,
    transformation = transformation, notes = notes,
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "",
    partition = "", stringsAsFactors = FALSE, check.names = FALSE
  )
}

observation_input <- function(fleet, type, measure, basis, unit, source_table,
                              survey = "", sampling_time = NA_real_, notes = "") {
  x <- aux[aux$fleet == fleet, , drop = FALSE]
  input_rows(type, measure, basis, x$year, x$age, x$obs, unit,
    fleet = fleet_names[[fleet]], survey = survey, sampling_time = sampling_time,
    transformation = "Exponentiated the natural-log observations in the official SAM object; no scale conversion was applied.",
    notes = paste0(notes, " Cross-checked against ", report, ", ", source_table, "."))
}

surface_input <- function(surface, type, measure, basis, unit, notes,
                          source_reference = model_reference) {
  surface <- as.matrix(surface)
  grid <- expand.grid(year = as.integer(rownames(surface)),
    age = as.integer(colnames(surface)))
  rows <- input_rows(type, measure, basis, grid$year, grid$age,
    as.vector(surface), unit,
    transformation = "Copied from the official SAM input surface without rescaling.",
    notes = notes)
  rows$source_reference <- source_reference
  rows
}

catch_rows <- observation_input(1L, "catch", "numbers_at_age", "numbers",
  "thousand fish", "Table 4.4.3, pp. 359-360",
  notes = "Total Gulf of Riga stock catch at age; age 8 is the 8+ group. The source assessment includes Gulf of Riga stock catch taken in subdivision 28.2.")
index_rows <- observation_input(2L, "index", "numbers_at_age", "index_scale",
  "number (index scale; multiplier not stated)", "Table 4.4.6, p. 366",
  survey = "GRAHS", sampling_time = sam_data$sampleTimes[[2L]],
  notes = "Gulf of Riga Acoustic Herring Survey age-specific tuning index; ages 1-8+, with no physical scale multiplier stated in the report.")

array_surface <- function(x) {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x
}
inputs_add <- do.call(rbind, c(list(catch_rows, index_rows), list(
  surface_input(sam_data$stockMeanWeight, "weight", "weight_at_age",
    "kg_per_fish", "kg per fish",
    "Annual stock weights; the report states stock weights were assumed equal to catch weights because spawning-time weights were unavailable. Table 4.4.4, pp. 361-362."),
  surface_input(array_surface(sam_data$catchMeanWeight), "catch_weight", "weight_at_age",
    "kg_per_fish", "kg per fish", "Annual catch weights at age from the fitted SAM data object; Table 4.4.4, pp. 361-362."),
  surface_input(array_surface(sam_data$disMeanWeight), "catch_weight", "discard_weight_at_age",
    "kg_per_fish", "kg per fish", "Annual discard weights at age as supplied to SAM; the source data object uses the same surface as catch weights."),
  surface_input(array_surface(sam_data$landMeanWeight), "catch_weight", "landings_weight_at_age",
    "kg_per_fish", "kg per fish", "Annual landings weights at age as supplied to SAM; the source data object uses the same surface as catch weights."),
  surface_input(sam_data$propMat, "maturity", "maturity_at_age", "proportion",
    "proportion mature", "Annual maturity-at-age surface. Values for 1977-1994 are fixed; values from 1995 onward are GAM-smoothed estimates from commercial landings samples. Table 4.4.5, p. 363."),
  surface_input(sam_data$natMor, "M", "natural_mortality_at_age", "per_year",
    "per year", "Fixed M=0.20 except M=0.25 in 1979-1983 due to cod presence. WGBFAS 2026, p. 349."),
  surface_input(array_surface(sam_data$landFrac), "catch", "landings_fraction_at_age",
    "proportion", "proportion", "The official SAM input sets the landings fraction to 1 at every year and age; no discards are represented."),
  surface_input(array_surface(sam_data$propF), "biology", "fraction_F_before_spawning",
    "proportion", "proportion", "F fraction before spawning from the official model object; 0.10 through 1998 and 0.20 in 1999-2025. The report's 2026 forecast uses 0.20."),
  surface_input(sam_data$propM, "biology", "fraction_M_before_spawning",
    "proportion", "proportion", "M fraction before spawning from the official model object; 0.30 in every year.")
)))

assumption <- function(component, setting, value, notes = "", source_reference = model_reference,
                       fleet = "", survey = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = fleet, survey = survey, sex = "combined",
    region = "ICES Subdivision 28.1 Gulf of Riga stock", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
assumptions_add <- do.call(rbind, list(
  assumption("assessment", "model_name", "SAM", paste("Official run GoR_WGBFAS_2026; stockassessment", as.character(utils::packageVersion("stockassessment")), "RemoteSha", attr(sam, "RemoteSha"), "; optimizer convergence code 0; objective 313.7562.")),
  assumption("assessment", "assessment_year", "2026", "The 2026 WGBFAS assessment supports 2027 advice.", advice_url),
  assumption("assessment", "stock_category", "1", "Analytical category 1 assessment; assessment audit in WGBFAS 2026." , report_url),
  assumption("population", "model_years", "1977-2025", "The fitted SAM data cover 1977 through 2025; the 2026-2027 forecast is not included in the fitted series."),
  assumption("population", "model_ages", "0-8+", "Age 8 is the plus group in the model and source tables.", report_url),
  assumption("recruitment", "recruitment_age", "0", "SAM estimates age-0 recruitment. The report notes the age-0 estimate is informed only by catch data and is uncertain.", report_url),
  assumption("recruitment", "process", "Random walk", "stockRecruitmentModelCode=0 in the official SAM configuration."),
  assumption("N", "process_variance_sharing", "Recruitment separate; ages 1-8 share one survival-process variance", "Recorded from keyVarLogN; the source uses a separate age-0 recruitment-state variance group."),
  assumption("F", "process", "Temporal random walk with age-correlated increments", "corFlag=2 specifies AR(1) correlation across age-specific F states."),
  assumption("F", "age_state_sharing", "Ages 0-6 separate; ages 7 and 8+ share the age-7 state", "keyLogFsta is 0,1,2,3,4,5,6,7,7."),
  assumption("F", "process_variance_sharing", "Age groups 0; 1; 2-4; 5; 6; 7-8", "Recorded from keyVarF=0,1,2,2,2,3,4,5,5."),
  assumption("F", "Fbar_ages", "2-6", "The official Fbar range is ages 2-6.", report_url),
  assumption("index", "survey", "GRAHS acoustic tuning series", "The acoustic series is the only tuning survey in the final model; the 2023 benchmark excluded the trap-net tuning series.", framework_url, survey = "GRAHS"),
  assumption("index", "survey_years", "1999-2025", "Age-specific acoustic observations are available for 1999-2025, ages 1-8+.", report_url, survey = "GRAHS"),
  assumption("index", "sampling_time", "0.675", "SAM uses the midpoint of the source survey time interval 0.65-0.70; WGBFAS describes the GRAHS survey as occurring in August.", survey = "GRAHS"),
  assumption("index", "catchability_age_groups", "Age 1; age 2; ages 3-8", "Recorded from keyLogFpar for the acoustic fleet; ages 3-8 share a catchability parameter.", survey = "GRAHS"),
  assumption("catch", "observation_likelihood", "Lognormal", "obsLikelihoodFlag=LN for the catch fleet.", fleet = fleet_names[[1L]]),
  assumption("index", "observation_likelihood", "Lognormal", "obsLikelihoodFlag=LN for the acoustic fleet.", survey = "GRAHS"),
  assumption("catch", "observation_variance_sharing", "Age 0 separate; ages 1-8 share", "Recorded from keyVarObs for the residual-catch fleet." , fleet = fleet_names[[1L]]),
  assumption("index", "observation_variance_sharing", "Age 1; ages 2-7; age 8+", "Recorded from keyVarObs for the acoustic fleet.", survey = "GRAHS"),
  assumption("catch", "observation_correlation", "Independent across ages", "obsCorStruct=ID for the catch fleet.", fleet = fleet_names[[1L]]),
  assumption("index", "observation_correlation", "AR(1) across ages with two shared transition groups", "keyCorObs shares the age-correlation increment for transitions 1-2 through 4-5 and a second increment for transitions 5-6 through 7-8.", survey = "GRAHS"),
  assumption("M", "natural_mortality", "Fixed 0.20 per year, except 0.25 in 1979-1983", "The 1979-1983 increase is attributed to cod presence.", report_url),
  assumption("biology", "maturity_at_age", "Fixed values for 1977-1994; GAM-smoothed annual values from 1995-2025", "Maturity estimates use commercial landings samples collected January-April.", report_url),
  assumption("weight", "stock_weight", "Stock weights assumed equal to catch weights", "Historical spawning-time weights were unavailable; source says catch gears are not selective.", report_url),
  assumption("biology", "spawning_fraction", "F fraction 0.10 through 1998 and 0.20 in 1999-2025; M fraction 0.30", "Exact annual surfaces are retained in inputs from the official SAM data object; 2026 forecast uses F fraction 0.20 and M fraction 0.30."),
  assumption("assessment", "forecast_scope", "Forecast excluded from fitted assessment series", "The database retains the fitted 1977-2025 model outputs; forecast inputs and 2026-2027 advice scenarios are not mixed into model estimates.", advice_url)
))

output_rows <- function(type, measure, year, age = NA_integer_, age_group = "",
                        value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        unit, fleet = "", survey = "", source_type = "native_model",
                        source_reference = model_reference, notes = "") {
  n <- length(value)
  data.frame(assessment_id = assessment_id, type = type, measure = measure,
    fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = "combined",
    region = "ICES Subdivision 28.1 Gulf of Riga stock", season = "",
    year = rep_len(year, n), age = rep_len(age, n), age_group = rep_len(age_group, n),
    value = value, se = rep_len(se, n), lwr = rep_len(lwr, n), upr = rep_len(upr, n),
    unit = unit, source_type = source_type, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
surface_output <- function(surface, se, type, measure, unit, notes) {
  surface <- as.matrix(surface)
  se <- as.matrix(se)
  if (!identical(dim(surface), dim(se))) stop("Output surface and uncertainty dimensions differ.", call. = FALSE)
  grid <- expand.grid(year = as.integer(rownames(surface)), age = as.integer(colnames(surface)))
  output_rows(type, measure, grid$year, grid$age,
    value = as.vector(surface), se = as.vector(se), unit = unit, notes = notes)
}
summary_output <- function(x, type, measure, unit, notes, age_group = "",
                           source_reference = report) {
  x <- as.data.frame(x)
  output_rows(type, measure, as.integer(rownames(x)), age_group = age_group,
    value = x$Estimate, lwr = x$Low, upr = x$High, unit = unit,
    source_reference = source_reference,
    notes = paste(notes, "Source bounds are pointwise 95% confidence intervals."))
}
n_at_age <- stockassessment::ntable(sam)
f_at_age <- stockassessment::faytable(sam)
n_se <- n_at_age * t(sam$plsd$logN)
f_log_se <- t(sam$plsd$logF)
if (ncol(f_log_se) == ncol(f_at_age) - 1L) f_log_se <- cbind(f_log_se, f_log_se[, ncol(f_log_se)])
if (ncol(f_log_se) == ncol(f_at_age)) f_at_age[, ncol(f_at_age)] <- f_at_age[, ncol(f_at_age) - 1L]
f_se <- f_at_age * f_log_se
dimnames(n_se) <- dimnames(n_at_age)
dimnames(f_se) <- dimnames(f_at_age)

output_add <- do.call(rbind, list(
  surface_output(n_at_age, n_se, "population", "numbers_at_age", "thousand fish",
    "SAM fitted abundance at age; age 8 is the plus group. Standard errors are delta-method natural-scale approximations from conditional log-state uncertainty in the cached fit."),
  surface_output(f_at_age, f_se, "mortality", "fishing_mortality_at_age", "per year",
    "SAM fitted F at age; age 8+ shares age-7 F. Standard errors are delta-method natural-scale approximations from conditional log-state uncertainty in the cached fit."),
  output_rows("population", "total_numbers", as.integer(rownames(n_at_age)),
    value = rowSums(n_at_age), unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste(report, "Table 4.4.8; derived from SAM numbers at age"),
    notes = "Derived source output calculated as the sum of the reported SAM numbers-at-age, ages 0-8+; uncertainty is not calculated."),
  summary_output(stockassessment::ssbtable(sam), "biomass", "SSB", "tonnes",
    "Native SAM spawning-stock biomass estimates.",
    source_reference = paste(report, "Table 4.4.9")),
  summary_output(stockassessment::rectable(sam), "recruitment", "recruitment", "thousand fish",
    "Age-0 recruitment estimates.",
    source_reference = paste(report, "Table 4.4.9")),
  summary_output(stockassessment::fbartable(sam), "mortality", "Fbar", "per year",
    "Fbar over ages 2-6.", age_group = "2-6",
    source_reference = paste(report, "Table 4.4.9")),
  output_rows("catch", "predicted_catch", aux$year[aux$fleet == 1L], aux$age[aux$fleet == 1L],
    value = aux$prediction[aux$fleet == 1L], unit = "thousand fish",
    notes = "Exponentiated SAM fitted log-catch predictions from the official model object."),
  output_rows("index", "predicted_index", aux$year[aux$fleet == 2L], aux$age[aux$fleet == 2L],
    value = aux$prediction[aux$fleet == 2L], unit = "number (index scale; multiplier not stated)",
    survey = "GRAHS", notes = "Exponentiated SAM fitted log-index predictions; retained on the native acoustic index scale.")
))

assessment_add <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026,
  terminal_year = 2025, estimate_terminal_year = 2025,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = paste0("GoR_WGBFAS_2026; stockassessment ",
    as.character(utils::packageVersion("stockassessment")), "; RemoteSha ", attr(sam, "RemoteSha")),
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2023,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graphs_url, model_url = model_url, repository_url = "",
  assumptions_status = "complete", inputs_status = "complete", outputs_status = "complete",
  notes = paste("Official WGBFAS 2026 final assessment, run GoR_WGBFAS_2026, verified against the section 4.4 report tables and 2026 ICES standard graph key 22423. The fit converges with objective 313.7562. Age-specific N/F standard errors are conditional delta-method approximations; 95% intervals for SSB, age-0 recruitment, and Fbar are retained from the report. Forecast years are excluded."),
  stringsAsFactors = FALSE
)
stock_add <- data.frame(
  stock_id = stock_id, charbonneau_id = "ICES-WGBFAS_harengus_BS 28.1",
  authority = "ICES", authority_stock_id = "her.27.28",
  scientific_name = "Clupea harengus", common_name = "Gulf of Riga herring",
  area = "ICES Subdivision 28.1 (Gulf of Riga)",
  region = "Baltic Sea", ocean = "Northeast Atlantic",
  notes = "Distinct spring-spawning herring population in ICES Subdivision 28.1. Assessment catch data also include Gulf of Riga stock catches taken in subdivision 28.2, as described in WGBFAS 2026.",
  stringsAsFactors = FALSE
)

append_rows <- function(name, rows) {
  path <- paths[[name]]
  columns <- names(read_db(name))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
if (anyDuplicated(paste(inputs_add$type, inputs_add$measure, inputs_add$fleet,
  inputs_add$survey, inputs_add$year, inputs_add$age, sep = "\034")) ||
  anyDuplicated(paste(output_add$measure, output_add$year, output_add$age,
    output_add$survey, sep = "\034")) || any(!is.finite(inputs_add$value)) ||
  any(!is.finite(output_add$value))) {
  stop("The generated source rows have duplicate keys or non-finite values.", call. = FALSE)
}

stock_lines <- readLines(paths[["stocks"]], warn = FALSE, encoding = "UTF-8")
stock_row <- which(startsWith(stock_lines, paste0('"', stock_id, '"')))
if (length(stock_row) != 1L) stop("Expected one existing catalogue stock row.", call. = FALSE)
stock_lines[[stock_row]] <- capture.output(write.csv(stock_add, row.names = FALSE, na = ""))[[2L]]
writeLines(stock_lines, paths[["stocks"]], useBytes = TRUE)
append_rows("assessments", assessment_add)
append_rows("assumptions", assumptions_add)
append_rows("inputs", inputs_add)
append_rows("outputs", output_add)
cat("Imported Gulf of Riga herring 2026: ", nrow(inputs_add), " inputs, ",
  nrow(assumptions_add), " assumptions, and ", nrow(output_add), " outputs.\n", sep = "")
