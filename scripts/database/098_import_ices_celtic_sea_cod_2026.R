assessment_id <- "ices_cod_celtic_sea_2026"
stock_id <- "ck_ices_wgcse_morhua_cs7e_k"
root <- "."
cache <- file.path(root, "source_cache", stock_id, "assessment_2026")
db <- file.path(root, "database")
model_file <- file.path(cache, "SAM_Cod_CS_WG2026_model.RData")

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to run this source importer.", call. = FALSE)
}
if (!file.exists(model_file)) stop("The cached official SAM fit is missing.", call. = FALSE)

model_env <- new.env(parent = emptyenv())
load(model_file, envir = model_env)
sam <- model_env$fit
sam_data <- sam$data
sam_conf <- sam$conf
if (is.null(sam) || sam$opt$convergence != 0L || !isTRUE(sam$sdrep$pdHess)) {
  stop("The cached official SAM fit is not numerically converged with a positive-definite Hessian.", call. = FALSE)
}

report_url <- "https://ices-library.figshare.com/articles/report/Working_Group_for_the_Celtic_Seas_Ecoregion_WGCSE_/32625759"
report_pdf <- "https://ndownloader.figshare.com/files/66387218"
framework_url <- "https://doi.org/10.17895/ices.pub.5983"
advice_url <- "https://asd.ices.dk/viewAdvice/6150"
graphs_url <- "https://standardgraphs.ices.dk/ViewCharts.aspx?key=22676"
model_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Cod_CS_WG2026/run/model.RData"
report <- "ICES. 2026. WGCSE 2026, cod in divisions 7.e-k, ICES Scientific Reports 8:42, section 7."
model_reference <- paste("Official ICES WGCSE 2026 SAM run Cod_CS_WG2026;", model_url)
area <- "ICES divisions 7.e-k"
region <- "Celtic Sea and eastern English Channel"

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
fleet_names <- attr(sam_data, "fleetNames")
aux <- as.data.frame(sam_data$aux)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)
aux$obs <- exp(sam_data$logobs)
aux$prediction <- exp(sam$rep$predObs)

if (!identical(years, 1980:2025) || !identical(ages, 1:7) ||
  !identical(fleet_names, c("Residual catch", "FR_OTDEF_Biomass", "VAST_IGFS_EVHOE")) ||
  !identical(as.numeric(sam_data$sampleTimes), c(0, 0.625, 0.855)) ||
  !identical(as.integer(sam_data$maxAgePerFleet), c(7L, -1L, 3L)) ||
  !identical(as.integer(sam_conf$fbarRange), c(2L, 5L)) ||
  !identical(as.integer(sam$opt$convergence), 0L) ||
  !isTRUE(sam$sdrep$pdHess)) {
  stop("Unexpected year, age, fleet, timing, Fbar, or convergence settings in the official fit.", call. = FALSE)
}
if (sum(aux$fleet == 1L) != 46L * 7L ||
  sum(aux$fleet == 2L) != 24L ||
  sum(aux$fleet == 3L) != 23L * 3L ||
  sum(is.na(aux$obs[aux$fleet == 1L])) != 48L ||
  sum(is.na(aux$obs[aux$fleet == 3L])) != 1L) {
  stop("Unexpected source observation coverage in the official fit object.", call. = FALSE)
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_type = "native_model", source_reference = model_reference,
                       transformation = "Copied from the official SAM input object without rescaling.",
                       notes = "") {
  n <- length(value)
  year <- rep_len(year, n)
  rows <- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = rep_len(fleet, n), survey = rep_len(survey, n),
    sex = "combined", region = region, season = "", year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"),
    age = rep_len(age, n), value = as.numeric(value), unit = unit,
    sampling_time = rep_len(sampling_time, n), source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
  if (any(is.infinite(rows$value))) {
    stop("Source input values cannot be infinite.", call. = FALSE)
  }
  rows[!is.na(rows$value), , drop = FALSE]
}

observation_input <- function(fleet, type, measure, basis, unit, source_reference,
                              survey = "", sampling_time = NA_real_, age = NULL,
                              notes = "") {
  rows <- aux[aux$fleet == fleet, , drop = FALSE]
  source_age <- if (is.null(age)) rows$age else rep_len(age, nrow(rows))
  if (fleet == 2L) source_age[rows$age == -1L] <- NA_integer_
  input_rows(
    type, measure, basis, rows$year, source_age, rows$obs, unit,
    fleet = fleet_names[[fleet]], survey = survey,
    sampling_time = sam_data$sampleTimes[[fleet]],
    source_reference = paste(report, source_reference, ";", model_reference),
    transformation = "Exponentiated the log observations stored by the official SAM fit; no scale conversion was applied. Source NA cells are omitted because they are not observations in the fitted likelihood.",
    notes = notes
  )
}

array_surface <- function(x) {
  if (length(dim(x)) == 3L) {
    if (dim(x)[[3L]] != 1L) stop("Expected a single source fleet surface.", call. = FALSE)
    x <- x[, , 1L]
  }
  x <- as.matrix(x)
  dimnames(x) <- list(as.character(years), as.character(ages))
  x
}

surface_input <- function(surface, type, measure, basis, unit, source_reference, notes) {
  surface <- array_surface(surface)
  grid <- expand.grid(year = years, age = ages)
  input_rows(
    type, measure, basis, grid$year, grid$age, as.vector(surface), unit,
    source_reference = paste(report, source_reference, "The numeric surface is from the official SAM fit object."),
    notes = notes
  )
}

matrix_input <- function(surface, type, measure, basis, unit, source_reference, notes) {
  surface <- as.matrix(surface)
  if (!all(apply(surface, 2L, function(x) length(unique(x)) == 1L))) {
    stop("The source M surface is not constant over years.", call. = FALSE)
  }
  input_rows(
    type, measure, basis, year = NA_integer_, age = ages,
    value = as.numeric(surface[1L, ]), unit,
    source_reference = paste(report, source_reference, "Reduced identical annual SAM values to the fixed age-specific input vector."),
    notes = notes
  )
}

inputs_add <- do.call(rbind, list(
  observation_input(1L, "catch", "numbers_at_age", "numbers", "thousand fish",
    "Table 7.2, pp. 230-231",
    notes = "Total catch at age includes landings and discards. Ages 1 and 2 are missing before 2004; the age-7 column is the 7+ group."),
  observation_input(2L, "index", "relative_biomass_index", "index_scale", "kg per hour",
    "Table 7.5a and Table 7.6, pp. 226 and 238",
    survey = "FR_OTDEF Q2+3+4", notes = "Aggregate French OTDEF commercial LPUE tuning index. The fit object has one aggregate observation per year."),
  observation_input(3L, "index", "numbers_at_age", "index_scale", "native survey index (unit unresolved)",
    "Table 7.6, p. 239", survey = "VAST_IGFS_EVHOE",
    notes = "Combined Irish IGFS and French EVHOE Q4 VAST index. The final SAM fit uses ages 1-3; the report table also displays age 4. The 2025 age-3 value is 0.000 in the report and is NA in the log-scale SAM input."),
  surface_input(sam_data$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "Table 7.4, pp. 231-232", "Annual stock weight-at-age."),
  surface_input(sam_data$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "Table 7.3, pp. 230-231", "Annual total catch weight-at-age."),
  surface_input(sam_data$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish",
    "Official SAM input object", "Annual landings weight-at-age supplied to the fitted model."),
  surface_input(sam_data$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish",
    "Official SAM input object", "Annual discard weight-at-age supplied to the fitted model; missing source cells are omitted and zero entries are preserved."),
  surface_input(sam_data$propMat, "maturity", "maturity_at_age", "proportion", "proportion mature",
    "Official SAM input object", "Maturity-at-age used by the final fitted model; the report refers to the updated WKCELTIC 2020 biology."),
  matrix_input(sam_data$natMor, "M", "natural_mortality_at_age", "per_year", "per year",
    "Official SAM input object", "Fixed age-specific M: 0.501, 0.330, 0.264, 0.233, 0.211, 0.211, 0.211 per year for ages 1-7+."),
  surface_input(sam_data$landFrac, "catch", "landings_fraction_at_age", "proportion", "proportion",
    "Official SAM input object", "Annual fraction of total catch landed at age."),
  surface_input(sam_data$propF, "biology", "fraction_F_before_spawning", "proportion", "proportion",
    "Official SAM input object", "The fitted model input is zero for every year and age; no F is applied before the spawning biomass calculation."),
  surface_input(sam_data$propM, "biology", "fraction_M_before_spawning", "proportion", "proportion",
    "Official SAM input object", "The fitted model input is zero for every year and age; no M is applied before the spawning biomass calculation.")
))

assumption <- function(component, setting, value, notes = "",
                       source_reference = model_reference, fleet = "", survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = "combined", region = region, season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}

assumptions_add <- do.call(rbind, list(
  assumption("assessment", "model_name", "SAM", paste("Official WGCSE2026 run Cod_CS_WG2026; stockassessment", as.character(utils::packageVersion("stockassessment")), "RemoteSha", attr(sam, "RemoteSha"), "; optimizer code 0; objective", signif(sam$opt$objective, 8), "; positive-definite Hessian.")),
  assumption("assessment", "assessment_year", "2026", "WGCSE 2026 assessed the stock for 2027 advice.", advice_url),
  assumption("population", "model_years", "1980-2025", "Native fitted SAM population years; forecasts are excluded."),
  assumption("population", "model_ages", "1-7+", "Age 7 is the plus group."),
  assumption("recruitment", "recruitment_age", "1", "SAM recruitment is age-1 abundance in the same model year."),
  assumption("N", "process", "Age-1 recruitment random walk with a shared age-2+ survival process", "stockRecruitmentModelCode=0; keyVarLogN separates age 1 from ages 2-7."),
  assumption("F", "process", "Correlated age-structured temporal process", "corFlag=2; the final SAM fit uses six F states, with age 7+ sharing the age-6 state."),
  assumption("F", "process_variance_sharing", "One shared F-process variance group", "keyVarF assigns all fitted F ages to variance group 0."),
  assumption("F", "Fbar_ages", "2-5", "The SAM configuration and report use mean fishing mortality over ages 2-5.", paste(report, "Table 7.7, p. 240")),
  assumption("M", "mortality_model", "Fixed age-specific natural mortality", "mortalityModel=0; no M process or M parameters are estimated."),
  assumption("catch", "observation_likelihood", "Lognormal", "obsLikelihoodFlag=LN for residual catch.", fleet = fleet_names[[1L]]),
  assumption("catch", "observation_variance_sharing", "Age 1 separate; age 2 separate; ages 3-7 shared", "Recorded from keyVarObs for Residual catch.", fleet = fleet_names[[1L]]),
  assumption("index", "observation_likelihood", "Lognormal", "obsLikelihoodFlag=LN for both indices."),
  assumption("index", "commercial_index", "Aggregate French OTDEF Q2+3+4 LPUE", "The native SAM series is an aggregate index, with age=-1.", survey = "FR_OTDEF Q2+3+4"),
  assumption("index", "commercial_index_years", "2002-2025", "One aggregate observation per year in the fitted SAM object.", survey = "FR_OTDEF Q2+3+4"),
  assumption("index", "survey", "Combined Irish IGFS and French EVHOE Q4 VAST index", "The two survey components are fitted as one index series.", survey = "VAST_IGFS_EVHOE"),
  assumption("index", "survey_years_and_ages", "2003-2025; ages 1-3", "The final fit object selects ages 1-3. Table 7.6 also displays age 4, which is not fitted by the released SAM object.", paste(report, "Table 7.6, p. 239"), survey = "VAST_IGFS_EVHOE"),
  assumption("index", "sampling_time", "0.855", "The value is read directly from the final SAM data object; the survey is the combined Q4 index.", survey = "VAST_IGFS_EVHOE"),
  assumption("index", "catchability_age_groups", "Commercial aggregate; VAST ages 1, 2, and 3 each have a separate parameter", "Recorded from keyLogFpar; keyQpow is -1 for all fitted index cells."),
  assumption("index", "observation_variance_sharing", "Commercial aggregate has one group; VAST ages 1-3 share one group", "Recorded from keyVarObs."),
  assumption("index", "observation_correlation", "Commercial index independent; VAST residuals use an age-correlated AR structure", "obsCorStruct=ID, ID, AR; VAST keyCorObs shares the age-transition parameter."),
  assumption("biology", "maturity_at_age", "0 at age 1; 0.54 at age 2; 0.93 at age 3; 1 at ages 4-7+", "The fitted SAM input is constant over 1980-2025."),
  assumption("weight", "stock_weight", "Annual first-quarter stock weight-at-age", "The fitted stock-weight surface is preserved from the final SAM data object."),
  assumption("biology", "spawning_fractions", "F and M fractions are zero", "The fitted SAM object applies no within-year F or M before the SSB calculation."),
  assumption("assessment", "forecast_scope", "Forecast excluded", "Only the 1980-2025 fitted historical series is imported; advice and projection outputs are not mixed into fitted estimates.", advice_url)
))

output_rows <- function(type, measure, year, age = NA_integer_, age_group = "",
                        value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        unit, fleet = "", survey = "", source_type = "native_model",
                        source_reference = model_reference, notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = "combined",
    region = region, season = "", year = rep_len(year, n),
    age = rep_len(age, n), age_group = rep_len(age_group, n),
    value = as.numeric(value), se = rep_len(se, n), lwr = rep_len(lwr, n),
    upr = rep_len(upr, n), unit = unit, source_type = source_type,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

surface_output <- function(surface, se, type, measure, unit, notes, source_reference) {
  surface <- as.matrix(surface)
  se <- as.matrix(se)
  if (!identical(dim(surface), dim(se))) stop("Output surface and uncertainty dimensions differ.", call. = FALSE)
  grid <- expand.grid(year = as.integer(rownames(surface)), age = as.integer(colnames(surface)))
  age_group <- ifelse(grid$age == max(ages), paste0(max(ages), "+"), "")
  output_rows(
    type, measure, grid$year, grid$age, age_group,
    as.vector(surface), as.vector(se), unit = unit,
    source_reference = source_reference,
    notes = notes
  )
}

summary_output <- function(x, type, measure, unit, notes, age = NA_integer_,
                           age_group = "", source_reference = report) {
  x <- as.data.frame(x)
  output_rows(
    type, measure, as.integer(rownames(x)), age = age, age_group = age_group,
    value = x$Estimate, lwr = x$Low, upr = x$High, unit = unit,
    source_reference = source_reference,
    notes = paste(notes, "Source 95% confidence limits are retained; no SE is inferred from the interval.")
  )
}

n_at_age <- stockassessment::ntable(sam)
f_at_age <- stockassessment::faytable(sam)
dimnames(n_at_age) <- list(as.character(years), as.character(ages))
dimnames(f_at_age) <- list(as.character(years), as.character(ages))
n_log_se <- t(sam$plsd$logN)
f_log_se <- t(sam$plsd$logF)
if (ncol(f_log_se) == ncol(f_at_age) - 1L) {
  f_log_se <- cbind(f_log_se, f_log_se[, ncol(f_log_se)])
}
if (!identical(dim(n_log_se), dim(n_at_age)) || !identical(dim(f_log_se), dim(f_at_age))) {
  stop("Conditional log-state uncertainty does not align with the fitted N/F surfaces.", call. = FALSE)
}
dimnames(n_log_se) <- dimnames(n_at_age)
dimnames(f_log_se) <- dimnames(f_at_age)
n_se <- n_at_age * n_log_se
f_se <- f_at_age * f_log_se

output_add <- do.call(rbind, list(
  surface_output(n_at_age, n_se, "population", "numbers_at_age", "thousand fish",
    "SAM fitted abundance-at-age. The reported SE is the delta-method natural-scale approximation from conditional logN uncertainty; age 7 is 7+.", paste(report, "Table 7.8, pp. 242-243")),
  surface_output(f_at_age, f_se, "mortality", "fishing_mortality_at_age", "per year",
    "SAM fitted F-at-age. The reported SE is the delta-method natural-scale approximation from conditional logF uncertainty; age 7+ shares the age-6 state.", paste(report, "Table 7.7, pp. 240-241")),
  summary_output(stockassessment::ssbtable(sam), "biomass", "SSB", "tonnes",
    "Native SAM spawning-stock biomass.", source_reference = paste(report, "Table 7.9, pp. 244-246")),
  summary_output(stockassessment::tsbtable(sam), "biomass", "total_biomass", "tonnes",
    "Native SAM total stock biomass.", source_reference = paste(report, "Table 7.9, pp. 244-246")),
  summary_output(stockassessment::rectable(sam), "recruitment", "recruitment", "thousand fish",
    "Native SAM age-1 recruitment.", age = 1L, source_reference = paste(report, "Table 7.9, pp. 244-246")),
  summary_output(stockassessment::fbartable(sam), "mortality", "Fbar", "per year",
    "Native SAM Fbar over ages 2-5.", age_group = "2-5", source_reference = paste(report, "Tables 7.7 and 7.9, pp. 240-246")),
  output_rows("population", "total_numbers", years,
    value = rowSums(n_at_age), unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste(report, "derived from Table 7.8 SAM numbers-at-age"),
    notes = "Sum of fitted SAM N-at-age over ages 1-7+. Uncertainty is not propagated."),
  output_rows("catch", "predicted_catch", aux$year[aux$fleet == 1L], aux$age[aux$fleet == 1L],
    age_group = ifelse(aux$age[aux$fleet == 1L] == max(ages), paste0(max(ages), "+"), ""),
    value = aux$prediction[aux$fleet == 1L], unit = "thousand fish",
    fleet = fleet_names[[1L]], notes = "Exponentiated fitted SAM log-catch predictions."),
  output_rows("index", "predicted_index", aux$year[aux$fleet == 2L], age = NA_integer_,
    age_group = "aggregate", value = aux$prediction[aux$fleet == 2L], unit = "kg per hour",
    fleet = fleet_names[[2L]], survey = "FR_OTDEF Q2+3+4",
    notes = "Exponentiated fitted SAM predictions on the native aggregate commercial LPUE scale."),
  output_rows("index", "predicted_index", aux$year[aux$fleet == 3L], aux$age[aux$fleet == 3L],
    value = aux$prediction[aux$fleet == 3L], unit = "native survey index (unit unresolved)",
    fleet = fleet_names[[3L]], survey = "VAST_IGFS_EVHOE",
    notes = "Exponentiated fitted SAM predictions for the combined VAST Q4 index on its native scale.")
))

assessment_add <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = paste0("Cod_CS_WG2026; stockassessment ",
    as.character(utils::packageVersion("stockassessment")), "; RemoteSha ", attr(sam, "RemoteSha")),
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2020L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graphs_url, model_url = model_url, repository_url = "",
  assumptions_status = "complete", inputs_status = "complete", outputs_status = "complete",
  notes = paste("Official WGCSE 2026 production SAM assessment used for 2027 advice; fitted years 1980-2025, ages 1-7+. Run Cod_CS_WG2026 converges with objective", signif(sam$opt$objective, 8), "and positive-definite Hessian. Inputs and fitted outputs are from the released model object and cross-checked against WGCSE tables 7.2-7.9. The report's age-4 VAST values are not used by the final fitted object; the 2025 age-3 zero is excluded from the log-scale likelihood. The stock annex download was restricted; the 2020 benchmark and final SAM object supply the documented model context."),
  stringsAsFactors = FALSE
)
stock_add <- data.frame(
  stock_id = stock_id, charbonneau_id = stocks$charbonneau_id[stocks$stock_id == stock_id],
  authority = "ICES", authority_stock_id = "cod.27.7e-k",
  scientific_name = "Gadus morhua", common_name = "Celtic Sea cod",
  area = area, region = region, ocean = "Northeast Atlantic",
  notes = "Official ICES stock cod.27.7e-k in divisions 7.e-k (eastern English Channel and southern Celtic Seas). Reconciled from the earlier Charbonneau-Keith catalogue metadata; the 2026 WGCSE assessment is the current detailed production run.",
  stringsAsFactors = FALSE
)

append_rows <- function(name, rows) {
  path <- paths[[name]]
  columns <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

input_key <- paste(inputs_add$type, inputs_add$measure, inputs_add$fleet,
  inputs_add$survey, inputs_add$year, inputs_add$age, sep = "\034")
output_key <- paste(output_add$measure, output_add$year, output_add$age,
  output_add$survey, sep = "\034")
if (anyDuplicated(input_key) || anyDuplicated(output_key) ||
  any(!is.finite(inputs_add$value)) ||
  any(!is.finite(output_add$value)) || any(!is.finite(output_add$se) & !is.na(output_add$se))) {
  stop("The generated source rows have duplicate keys or invalid values.", call. = FALSE)
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

cat("Imported Celtic Sea cod 2026: ", nrow(inputs_add), " inputs, ",
  nrow(assumptions_add), " assumptions, and ", nrow(output_add), " outputs.\n", sep = "")
