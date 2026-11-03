root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
db_dir <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ices_turbot_north_sea_preflight")
id_benchmark <- "ices_turbot_north_sea_2025_benchmark"
id_summary <- "ices_turbot_north_sea_2026_summary"
stock_id <- "ck_ices_wgnssk_maximus_ns_4"

abort <- function(...) stop(paste0(...), call. = FALSE)
user_library <- Sys.glob(file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", "*"))
.libPaths(c(user_library, .libPaths()))
if (!requireNamespace("stockassessment", quietly = TRUE)) abort("Install stockassessment to read SAM summary tables.")
if (requireNamespace("TMB", quietly = TRUE)) loadNamespace("TMB")
if (!requireNamespace("rvest", quietly = TRUE)) abort("Install rvest to read the cached ICES summary table.")

model_file <- file.path(cache, "tur4_m9", "run", "model.RData")
summary_file <- file.path(cache, "ices_sag_2026_turbot_source.html")
if (!all(file.exists(c(model_file, summary_file)))) abort("The cached SAM model object and 2026 ICES summary source are required.")
fit_env <- new.env(parent = globalenv())
load(model_file, envir = fit_env)
if (!exists("fit", envir = fit_env, inherits = FALSE)) abort("The cached model object does not contain fit.")
fit <- fit_env$fit

if (!identical(as.integer(fit$data$years), 1981:2023) ||
    fit$conf$minAge != 1L || fit$conf$maxAge != 8L ||
    !all(fit$conf$maxAgePlusGroup == 1L) ||
    !identical(as.integer(fit$conf$fbarRange), c(2L, 6L))) {
  abort("The cached tur4.m9 fit no longer matches the reviewed years, ages, or plus-group settings.")
}
if (!identical(as.integer(fit$opt$convergence), 0L) || !isTRUE(fit$sdrep$pdHess)) {
  abort("The cached tur4.m9 model does not have the reviewed convergence diagnostics.")
}

make_input <- function(type, measure, basis, value, unit, year = NA_real_, age = NA_real_,
                       fleet = "", survey = "", sex = "", sampling_time = NA_real_,
                       source_reference, transformation = "", notes = "") {
  n <- length(value)
  rep_n <- function(x) rep_len(x, n)
  year <- rep_n(year)
  data.frame(
    assessment_id = id_benchmark, type = rep_n(type), measure = rep_n(measure),
    basis = rep_n(basis), fleet = rep_n(fleet), survey = rep_n(survey),
    sex = rep_n(sex), region = NA_character_, season = NA_character_, year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"), age = rep_n(age),
    value = as.numeric(value), unit = rep_n(unit), sampling_time = as.numeric(rep_n(sampling_time)),
    source_type = "native_model", source_reference = rep_n(source_reference),
    transformation = rep_n(transformation), notes = rep_n(notes),
    observation_id = NA_character_, length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_character_,
    partition = NA_character_, stringsAsFactors = FALSE, check.names = FALSE
  )
}

make_output <- function(id, type, measure, year, value, unit, age = NA_real_,
                        age_group = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        source_type, source_reference, notes) {
  n <- length(value)
  rep_n <- function(x) rep_len(x, n)
  data.frame(
    assessment_id = rep_n(id), type = rep_n(type), measure = rep_n(measure),
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = rep_n(year),
    age = rep_n(age), age_group = rep_n(age_group), value = as.numeric(value),
    se = as.numeric(rep_n(se)), lwr = as.numeric(rep_n(lwr)), upr = as.numeric(rep_n(upr)),
    unit = rep_n(unit), source_type = rep_n(source_type),
    source_reference = rep_n(source_reference), notes = rep_n(notes),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

make_assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = id_benchmark, component = component, fleet = NA_character_,
    survey = NA_character_, sex = NA_character_, region = NA_character_,
    season = NA_character_, setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

finite_matrix_input <- function(x, type, measure, basis, unit, source_reference, notes) {
  ij <- which(is.finite(x), arr.ind = TRUE)
  make_input(
    type, measure, basis, x[ij], unit,
    year = fit$data$years[ij[, 1L]], age = ij[, 2L],
    source_reference = source_reference, notes = notes
  )
}

ages <- seq_len(fit$conf$maxAge)
years <- as.integer(fit$data$years)
obs <- as.data.frame(fit$data$aux)
obs$value <- exp(fit$data$logobs)
obs$sample_time <- fit$data$sampleTimes[obs$fleet]
obs <- obs[is.finite(obs$value), , drop = FALSE]

input_rows <- list()
catch_obs <- obs[obs$fleet == 1L, , drop = FALSE]
input_rows[[length(input_rows) + 1L]] <- make_input(
  "catch", "numbers_at_age", "numbers", catch_obs$value, "thousand fish",
  year = catch_obs$year, age = catch_obs$age, fleet = "Residual catch",
  source_reference = "tur4.m9/data/cn.dat; tur4.m9/run/model.RData",
  transformation = "Exponentiated the natural-log observation in the SAM data object to recover the input scale.",
  notes = "Age 8 is 8+. The thousand-fish scale is consistent with catch-at-age multiplied by catch weights reproducing the official total catch in tonnes. Missing cells remain absent."
)

survey_names <- c("BTS+COAST", "BSAS")
for (fleet_id in 2:3) {
  survey_obs <- obs[obs$fleet == fleet_id, , drop = FALSE]
  survey_name <- survey_names[[fleet_id - 1L]]
  input_rows[[length(input_rows) + 1L]] <- make_input(
    "index", "numbers_at_age", "index_scale", survey_obs$value,
    "native survey index (unit unresolved)",
    year = survey_obs$year, age = survey_obs$age, survey = survey_name,
    sampling_time = survey_obs$sample_time,
    source_reference = "tur4.m9/data/survey.dat; tur4.m9/run/model.RData; WKBNSCS 2025, Tables 2.5-2.6",
    transformation = "Exponentiated the natural-log observation in the SAM data object to recover the input scale.",
    notes = "Age 8 is 8+; original index scale retained."
  )
}

input_rows[[length(input_rows) + 1L]] <- finite_matrix_input(
  fit$data$catchMeanWeight[, , 1L], "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish",
  "tur4.m9/data/cw.dat; WKBNSCS 2025, Section 2.4.2.2",
  "Annual catch weights used as observations by the internal SAM GMRF weight model; age 8 is 8+."
)
input_rows[[length(input_rows) + 1L]] <- finite_matrix_input(
  fit$data$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish", "kg per fish",
  "tur4.m9/data/sw.dat; WKBNSCS 2025, Section 2.4.2.2",
  "Annual stock weights used by the internal SAM GMRF weight model and population biomass calculations; age 8 is 8+."
)

prop_mat <- fit$data$propMat
nat_m <- fit$data$natMor
if (max(abs(sweep(prop_mat, 2L, prop_mat[1L, ], "-")), na.rm = TRUE) > 1e-12 ||
    max(abs(sweep(nat_m, 2L, nat_m[1L, ], "-")), na.rm = TRUE) > 1e-12) {
  abort("Maturity and natural mortality are expected to be time-invariant in the reviewed model.")
}
input_rows[[length(input_rows) + 1L]] <- make_input(
  "maturity", "maturity_at_age", "proportion", prop_mat[1L, ], "proportion",
  age = ages, sex = "female", source_reference = "tur4.m9/data/mo.dat; WKBNSCS 2025, Table 2.2",
  notes = "Updated female maturity ogive, fixed in the assessment; age 8 is 8+."
)
input_rows[[length(input_rows) + 1L]] <- make_input(
  "M", "natural_mortality_at_age", "per_year", nat_m[1L, ], "per year",
  age = ages, source_reference = "tur4.m9/data/nm.dat; WKBNSCS 2025, Section 2.1 and Table 2.7",
  notes = "Fixed, age-varying Lorenzen M; not estimated. The same vector applies in every model year; age 8 is 8+."
)
inputs_benchmark <- do.call(rbind, input_rows)

component_for <- function(setting) {
  if (grepl("^(keyLogFsta|corFlag|keyVarF|fracMixF|fbarRange)", setting)) return("F")
  if (grepl("^(keyLogFpar|keyQpow)", setting)) return("q")
  if (grepl("^(keyVarLogN|keyVarLogP|fracMixN|stockRecruitmentModelCode|constRecBreaks|initN)", setting)) return("N")
  if (grepl("^(keyVarObs|obsCorStruct|keyCorObs|fixVarToWeight|fracMixObs|predVarObsLink|keyXtraSd)", setting)) return("observation_model")
  if (grepl("(Weight|Mature|Mortality|mature|mortality)", setting)) return("biology")
  "assessment"
}
serialize_setting <- function(x) {
  value_text <- function(v) ifelse(is.na(v), "NA", as.character(v))
  if (length(x) == 0L) return("not specified")
  if (length(dim(x)) == 2L) {
    return(paste(apply(x, 1L, function(row) paste(value_text(row), collapse = " ")), collapse = "; "))
  }
  paste(value_text(x), collapse = " ")
}
config_rows <- lapply(names(fit$conf), function(setting) make_assumption(
  component_for(setting), paste0("SAM configuration: ", setting), serialize_setting(fit$conf[[setting]]),
  "tur4.m9/conf/model.cfg; tur4.m9/run/model.RData (fit$conf)",
  "Exact SAM configuration value; matrix rows are separated by semicolons."
))
human_rows <- list(
  make_assumption("assessment", "selected_model", "Model 9*: Fixed Lorenzen's M; final WKBNSCS 2025 benchmark model.", "WKBNSCS 2025, Table 2.7"),
  make_assumption("population", "model_years", "1981-2023", "tur4.m9/data/cn.dat; tur4.m9/run/model.RData"),
  make_assumption("population", "age_range", "Ages 1-8; age 8 is a plus group.", "tur4.m9/conf/model.cfg; WKBNSCS 2025, Table 2.8"),
  make_assumption("F", "Fbar_age_range", "2-6", "tur4.m9/conf/model.cfg; WKBNSCS 2025, Table 2.8"),
  make_assumption("F", "age_state_sharing", "Ages 7 and 8 share the same fitted log-F state.", "tur4.m9/conf/model.cfg, keyLogFsta"),
  make_assumption("index", "survey_timing", "BTS+COAST and BSAS are sampled at 0.705 of the year.", "tur4.m9/data/survey.dat; tur4.m9/run/model.RData"),
  make_assumption("biology", "natural_mortality", "Fixed age-varying Lorenzen M; no M parameters are estimated.", "tur4.m9/data/nm.dat; WKBNSCS 2025, Section 2.1 and Table 2.7"),
  make_assumption("biology", "maturity", "Updated female maturity ogive, fixed; ages 1-8+ are 0, 0.01, 0.58, 0.98, 1, 1, 1, 1.", "WKBNSCS 2025, Table 2.2"),
  make_assumption("biology", "weight_model", "Stock and catch weights are estimated internally using SAM GMRF models, informed by the supplied annual weight-at-age observations.", "WKBNSCS 2025, Section 2.1; tur4.m9/conf/model.cfg"),
  make_assumption("assessment", "fit_diagnostics", paste0("Optimizer convergence code ", fit$opt$convergence, "; positive-definite Hessian = ", fit$sdrep$pdHess, "."), "tur4.m9/run/model.RData")
)
assumptions_benchmark <- do.call(rbind, c(config_rows, human_rows))

log_n <- fit$pl$logN
se_log_n <- fit$plsd$logN
n_at_age <- t(stockassessment::ntable(fit))
if (!identical(dim(n_at_age), c(length(ages), length(years)))) abort("Unexpected log-N dimensions.")

age_key <- as.integer(fit$conf$keyLogFsta[1L, ])
key_levels <- sort(unique(age_key[age_key >= 0L]))
f_row <- match(age_key, key_levels)
if (length(f_row) != length(ages) || anyNA(f_row) || max(f_row) != nrow(fit$pl$logF)) {
  abort("Could not map the compact log-F parameters to model ages.")
}
log_f <- fit$pl$logF[f_row, , drop = FALSE]
se_log_f <- fit$plsd$logF[f_row, , drop = FALSE]
f_at_age <- t(stockassessment::faytable(fit))

n_outputs <- make_output(
  id_benchmark, "population", "numbers_at_age", rep(years, each = length(ages)),
  as.vector(n_at_age), "thousand fish", age = rep(ages, times = length(years)),
  se = as.vector(se_log_n), source_type = "native_model",
  source_reference = "tur4.m9/run/model.RData (fit$pl$logN, fit$plsd$logN)",
  notes = "Value is exp(logN). SE is on the log scale. Age 8 is 8+; ages 7 and 8 share the same fitted F state only, not the N state."
)
f_outputs <- make_output(
  id_benchmark, "mortality", "fishing_mortality_at_age", rep(years, each = length(ages)),
  as.vector(f_at_age), "per year", age = rep(ages, times = length(years)),
  se = as.vector(se_log_f), source_type = "native_model",
  source_reference = "tur4.m9/run/model.RData (fit$pl$logF, fit$plsd$logF); tur4.m9/conf/model.cfg (keyLogFsta)",
  notes = "Value is exp(logF). SE is on the log scale. Ages 7 and 8 map to the same fitted log-F state; age 8 is 8+."
)
recruitment_outputs <- make_output(
  id_benchmark, "recruitment", "recruitment", years, n_at_age[1L, ], "thousand fish", age = 1,
  se = se_log_n[1L, ], source_type = "native_model",
  source_reference = "tur4.m9/run/model.RData (fit$pl$logN age 1)",
  notes = "Recruitment is abundance at age 1; value is exp(logN). SE is on the log scale."
)
total_numbers_outputs <- make_output(
  id_benchmark, "population", "total_numbers", years, colSums(n_at_age), "thousand fish",
  source_type = "derived_source_output",
  source_reference = "tur4.m9/run/model.RData (fit$pl$logN)",
  notes = "Derived by summing fitted numbers-at-age over ages 1-8+. Uncertainty is omitted because cross-age covariance was not propagated for this sum."
)
ssb_table <- stockassessment::ssbtable(fit)
ssb_outputs <- make_output(
  id_benchmark, "biomass", "SSB", as.integer(rownames(ssb_table)), ssb_table[, "Estimate"], "tonnes",
  lwr = ssb_table[, "Low"], upr = ssb_table[, "High"], source_type = "native_model",
  source_reference = "tur4.m9/run/model.RData; stockassessment::ssbtable",
  notes = "Start-of-year SSB from the fitted SAM model using modelled stock weights and fixed maturity. Low/high are exp(log estimate +/- 2 SD) on the log scale; no separate SE is reported."
)
fbar_table <- stockassessment::fbartable(fit)
fbar_outputs <- make_output(
  id_benchmark, "mortality", "Fbar", as.integer(rownames(fbar_table)), fbar_table[, "Estimate"], "per year",
  age_group = "2-6", lwr = fbar_table[, "Low"], upr = fbar_table[, "High"], source_type = "native_model",
  source_reference = "tur4.m9/run/model.RData; stockassessment::fbartable; tur4.m9/conf/model.cfg (fbarRange)",
  notes = "Fbar ages 2-6. Low/high are exp(log estimate +/- 2 SD) on the log scale; no separate SE is reported."
)
outputs_benchmark <- rbind(n_outputs, f_outputs, recruitment_outputs, total_numbers_outputs, ssb_outputs, fbar_outputs)

summary_html <- xml2::read_html(summary_file)
read_label <- function(id) {
  node <- xml2::xml_find_first(summary_html, paste0("//*[@id='", id, "']"))
  if (inherits(node, "xml_missing")) NA_character_ else xml2::xml_text(node)
}
if (!identical(read_label("lblStockCode"), "tur.27.4") ||
    !identical(read_label("lblKey"), "22472") ||
    !identical(read_label("lblYear"), "2026") ||
    !identical(read_label("lblRecruitmentAge"), "1") ||
    !identical(read_label("lblFAge"), "2-6") ||
    !identical(read_label("lblStockSizeUnits"), "tonnes")) {
  abort("The cached ICES source table does not match the reviewed turbot 2026 summary.")
}
summary_tables <- rvest::html_table(summary_html, fill = TRUE)
summary_columns <- c("Year", "Low Recruitment", "Recruitment", "High Recruitment", "Low SSB", "SSB", "High SSB", "Low F", "F", "High F")
summary_index <- which(vapply(summary_tables, function(x) all(summary_columns %in% names(x)), logical(1)))
if (length(summary_index) != 1L) abort("Could not identify the 2026 ICES source-data table.")
summary_data <- as.data.frame(summary_tables[[summary_index]], stringsAsFactors = FALSE)
summary_data$Year <- as.integer(summary_data$Year)
if (!identical(summary_data$Year, 1981:2026)) abort("Unexpected years in the 2026 ICES source table.")
number_column <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x), fixed = TRUE)))
summary_outputs <- list()
add_summary_metric <- function(value_column, low_column, high_column, type, measure, unit, age = NA_real_, age_group = "") {
  value <- number_column(summary_data[[value_column]])
  low <- number_column(summary_data[[low_column]])
  high <- number_column(summary_data[[high_column]])
  keep <- is.finite(value)
  notes <- ifelse(summary_data$Year[keep] == 2026L,
    "2026 forecast value; the source table provides no low/high interval.",
    "Official ICES source-table estimate. Low/high values are retained as published; the interval level is not stated."
  )
  summary_outputs[[length(summary_outputs) + 1L]] <<- make_output(
    id_summary, type, measure, summary_data$Year[keep], value[keep], unit,
    age = age, age_group = age_group, lwr = low[keep], upr = high[keep],
    source_type = "official_table", source_reference = "ICES Stock Assessment Graphs, source table key 22472",
    notes = notes
  )
}
add_summary_metric("Recruitment", "Low Recruitment", "High Recruitment", "recruitment", "recruitment", "thousand fish", age = 1)
add_summary_metric("SSB", "Low SSB", "High SSB", "biomass", "SSB", "tonnes")
add_summary_metric("F", "Low F", "High F", "mortality", "Fbar", "per year", age_group = "2-6")
outputs_summary <- do.call(rbind, summary_outputs)

read_db <- function(name, nrows = Inf) read.csv(
  file.path(db_dir, name), stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE, skipNul = TRUE, nrows = nrows
)
stock_rows <- read_db("stocks.csv")
stock_row <- stock_rows[stock_rows$stock_id == stock_id, , drop = FALSE]
if (nrow(stock_row) != 1L) abort("Expected one existing Charbonneau-Keith stock row.")
if (stock_row$scientific_name != "Scophthalmus maximus" || stock_row$common_name != "Turbot") abort("Correct the stock identity fields from the cited ICES report before importing.")
assessments_existing <- read_db("assessments.csv")
if (any(assessments_existing$assessment_id %in% c(id_benchmark, id_summary))) abort("Turbot assessment IDs already exist; inspect the existing records before rerunning.")

new_assessments <- data.frame(
  assessment_id = c(id_benchmark, id_summary), stock_id = stock_id,
  assessment_year = c(2025L, 2026L), terminal_year = c(2023L, 2025L),
  estimate_terminal_year = c(2023L, 2026L),
  assessment_type = c("benchmark", "assessment_update"),
  model_family = c("SAM", NA_character_), model_version = NA_character_,
  is_current = c(TRUE, FALSE), is_applied = c(FALSE, TRUE), framework_year = c(2025L, NA_integer_),
  assessment_url = c("https://doi.org/10.17895/ices.pub.28715180", "https://asd.ices.dk/viewAdvice/5097"),
  framework_url = c("https://doi.org/10.17895/ices.pub.28715180", NA_character_),
  data_url = c("https://stockassessment.org/datadisk/stockassessment/userdirs/user3/tur4.m9/run/data.RData", "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22472"),
  model_url = c("https://stockassessment.org/datadisk/stockassessment/userdirs/user3/tur4.m9/run/model.RData", NA_character_),
  repository_url = c("https://stockassessment.org/datadisk/stockassessment/userdirs/user3/tur4.m9/", NA_character_),
  assumptions_status = c("complete", "partial"), inputs_status = c("complete", "partial"),
  outputs_status = c("complete", "partial"),
  notes = c(
    paste0("Final WKBNSCS 2025 benchmark Model 9* (Fixed Lorenzen's M), fitted through 2023. Native inputs, configuration and fitted outputs are available. Optimizer convergence code ", fit$opt$convergence, "; positive-definite Hessian = ", fit$sdrep$pdHess, ". Not applied for 2025 advice; see source review."),
    "Official 2026 advice summary only. Aggregate recruitment, SSB and Fbar are recorded separately; detailed inputs, assumptions and age-specific outputs were not recovered. The table has estimates through 2025 and 2026 forecast SSB/recruitment. It is not the 2025 M9 benchmark run."
  ), stringsAsFactors = FALSE, check.names = FALSE
)

append_rows <- function(file, rows) {
  header <- names(read.csv(file, nrows = 0L, check.names = FALSE, skipNul = TRUE))
  if (!setequal(header, names(rows))) abort("Column mismatch while appending ", basename(file), ".")
  rows <- rows[, header, drop = FALSE]
  write.table(rows, file, sep = ",", append = TRUE, row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "", eol = "\r\n", fileEncoding = "UTF-8")
}

append_rows(file.path(db_dir, "assessments.csv"), new_assessments)
append_rows(file.path(db_dir, "assumptions.csv"), assumptions_benchmark)
append_rows(file.path(db_dir, "inputs.csv"), inputs_benchmark)
append_rows(file.path(db_dir, "outputs.csv"), rbind(outputs_benchmark, outputs_summary))

cat("Added", nrow(inputs_benchmark), "benchmark inputs,", nrow(assumptions_benchmark), "benchmark assumptions,", nrow(outputs_benchmark), "benchmark outputs,", nrow(outputs_summary), "2026 summary outputs.\n")
