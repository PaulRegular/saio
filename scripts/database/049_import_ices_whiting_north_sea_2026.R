assessment_id <- "ices_whiting_north_sea_2026"
stock_id <- "ices_whiting_north_sea"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", assessment_id)
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NSwhiting_2026n/run/model.RData"
)
report_url <- "https://doi.org/10.17895/ices.pub.32676345"
framework_url <- "https://doi.org/10.17895/ices.pub.32019630"
graph_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22488"

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to verify native SAM survey weights.", call. = FALSE)
}

model_env <- new.env(parent = baseenv())
data_env <- new.env(parent = baseenv())
load(file.path(cache, "NSwhiting_2026n_model.RData"), envir = model_env)
load(file.path(cache, "NSwhiting_2026n_data.RData"), envir = data_env)
fit <- model_env$fit
dat <- fit$data
years <- as.integer(dat$years)
ages <- as.integer(colnames(dat$stockMeanWeight))
fleet_names <- attr(dat, "fleetNames")
sample_times <- as.numeric(dat$sampleTimes)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")

stopifnot(
  fit$opt$convergence == 0L,
  identical(as.integer(data_env$dat$years), years),
  identical(as.numeric(data_env$dat$logobs), as.numeric(dat$logobs)),
  identical(dim(dat$stockMeanWeight), c(length(years), length(ages))),
  length(fleet_names) == 3L,
  identical(as.integer(table(aux$fleet)), c(432L, 264L, 245L)),
  identical(sample_times, c(0, 0.125, 0.625))
)

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_type = "native_model", source_reference,
                       transformation = "Copied from the official native SAM fit.",
                       notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = rep_len(basis, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey, n), sex = "", region = "", season = "",
    year = rep_len(year, n),
    year_basis = ifelse(is.na(rep_len(year, n)), "", "calendar_year"),
    age = rep_len(age, n), value = value, unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

matrix_input <- function(x, type, measure, basis, unit, source_slot,
                         notes = "", years = NULL, ages = NULL,
                         source_type = "native_model") {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x <- as.matrix(x)
  if (is.null(years)) years <- as.integer(rownames(x))
  if (is.null(ages)) ages <- as.integer(colnames(x))
  if (length(years) != nrow(x) || length(ages) != ncol(x)) {
    stop("Unexpected dimensions in ", source_slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages)
  values <- as.vector(x)
  keep <- is.finite(values)
  input_rows(
    type, measure, basis, grid$year[keep], grid$age[keep], values[keep], unit,
    source_type = source_type,
    source_reference = paste0(model_url, "; fit$data$", source_slot),
    notes = notes
  )
}

obs_rows <- lapply(seq_along(fleet_names), function(fleet_id) {
  take <- which(aux$fleet == fleet_id)
  if (fleet_id == 1L) {
    input_rows(
      "catch", "numbers_at_age", "numbers", aux$year[take], aux$age[take],
      exp(dat$logobs[take]), "thousand fish",
      fleet = "Total catch",
      source_reference = paste0(model_url, "; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated native log catch observation.",
      notes = "The official total catch-at-age observation used in SAM."
    )
  } else {
    input_rows(
      "index", "numbers_at_age", "index_scale", aux$year[take], aux$age[take],
      exp(dat$logobs[take]), "native survey-index units",
      survey = fleet_names[[fleet_id]], sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated native log survey-index observation.",
      notes = "Retained on the fitted assessment's relative index scale; no physical abundance unit is assigned."
    )
  }
})
inputs <- do.call(rbind, c(obs_rows, list(
  matrix_input(
    dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "stockMeanWeight",
    "Known annual stock weight; ages 6-8 repeat the source 6+ group."
  ),
  matrix_input(
    dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "catchMeanWeight",
    "Known total-catch weight-at-age; age 8 is the model plus group."
  ),
  matrix_input(
    dat$propMat, "maturity", "maturity_at_age", "proportion",
    "proportion", "propMat",
    "Known smoothed maturity surface; ages 6+ are grouped in the source."
  ),
  matrix_input(
    dat$natMor, "M", "natural_mortality_at_age", "per_year",
    "per year", "natMor",
    "Time-varying M observations supplied to the SAM mortality process; values after 2022 are missing and estimated by SAM."
  ),
  matrix_input(
    dat$landFrac, "catch", "landings_fraction_at_age", "proportion",
    "proportion", "landFrac",
    "Native landings fraction used with catch-component weight inputs."
  ),
  matrix_input(
    dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish",
    "kg per fish", "landMeanWeight",
    "Native landings mean weight-at-age retained from the SAM input object."
  ),
  matrix_input(
    dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish",
    "kg per fish", "disMeanWeight",
    "Native discard mean weight-at-age retained from the SAM input object."
  ),
  matrix_input(
    dat$propF, "biology", "fraction_F_before_spawning", "proportion",
    "proportion", "propF",
    "Native mortality fraction used in the spawning-biomass calculation."
  ),
  matrix_input(
    dat$propM, "biology", "fraction_M_before_spawning", "proportion",
    "proportion", "propM",
    "Native mortality fraction used in the spawning-biomass calculation."
  )
)))

survey_obs <- which(aux$fleet %in% 2:3)
precision <- dat$weight[survey_obs]
stopifnot(all(is.finite(precision)), all(precision > 0))
precision_rows <- input_rows(
  "index", "relative_precision_weight", "relative_precision",
  year = aux$year[survey_obs],
  age = aux$age[survey_obs], value = precision,
  unit = "relative precision weight", survey = fleet_names[aux$fleet[survey_obs]],
  sampling_time = sample_times[aux$fleet[survey_obs]],
  source_reference = paste0(model_url, "; fit$data$weight"),
  transformation = "Copied from the fitted SAM data object.",
  notes = "Native survey likelihood weight used by the official fit. SAM reads the first declared number of columns from the supplied CV matrix."
)
log_sd_rows <- input_rows(
  "index", "log_index_sd", "log_scale",
  year = aux$year[survey_obs],
  age = aux$age[survey_obs], value = 1 / sqrt(precision),
  unit = "relative log-scale SD factor", survey = fleet_names[aux$fleet[survey_obs]],
  sampling_time = sample_times[aux$fleet[survey_obs]],
  source_reference = paste0(model_url, "; fit$data$weight"),
  transformation = "Derived as 1/sqrt(relative precision weight) for the tinyAM relative-SD input.",
  notes = "This is a relative scaling factor, not an estimated final observation SD."
)

validate_native_weights <- function(fleet_id, file) {
  cv <- stockassessment::read.ices(file)
  expected <- 1 / log(cv^2 + 1)
  take <- which(aux$fleet == fleet_id)
  target <- expected[cbind(
    match(aux$year[take], as.integer(rownames(expected))),
    match(aux$age[take], as.integer(colnames(expected)))
  )]
  if (anyNA(target) || max(abs(dat$weight[take] - target)) > 1e-12) {
    stop("Native weights do not match read.ices() for fleet ", fleet_id, ".", call. = FALSE)
  }
}
validate_native_weights(
  2L, file.path(cache, "NSwhiting_2026n", "data", "Q1_Mod10_CV.dat")
)
validate_native_weights(
  3L, file.path(cache, "NSwhiting_2026n", "data", "Q3_Mod9_CV.dat")
)

read_cv_matrix <- function(file, years, ages) {
  x <- as.matrix(utils::read.table(file, skip = 5, header = FALSE, fill = TRUE))
  if (nrow(x) != length(years) || ncol(x) != length(ages) + 1L) {
    stop("Unexpected CV file layout in ", basename(file), ".", call. = FALSE)
  }
  values <- x[, seq.int(2L, length(ages) + 1L), drop = FALSE]
  expand.grid(year = years, age = ages) |>
    transform(value = as.vector(values))
}
pdf <- file.path(cache, "WGNSSK_2026.pdf")
if (!requireNamespace("pdftools", quietly = TRUE) || !file.exists(pdf)) {
  stop("The cached WGNSSK report and pdftools are required for import.", call. = FALSE)
}
pages <- pdftools::pdf_text(pdf)

q1_cv <- read_cv_matrix(
  file.path(cache, "NSwhiting_2026n", "data", "Q1_Mod10_CV.dat"), 1983:2026, 1:6
)
q3_cv <- read_cv_matrix(
  file.path(cache, "NSwhiting_2026n", "data", "Q3_Mod9_CV.dat"), 1991:2025, 0:6
)
read_report_cv <- function(page_range, year_range, ages) {
  lines <- unlist(strsplit(pages[page_range], "\n", fixed = TRUE),
    use.names = FALSE
  )
  candidates <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+",
    lines,
    perl = TRUE
  )]
  rows <- lapply(candidates, function(line) {
    values <- suppressWarnings(as.numeric(strsplit(trimws(line),
      "[[:space:]]+",
      perl = TRUE
    )[[1L]]))
    if (length(values) != length(ages) + 1L ||
      values[[1L]] < min(year_range) || values[[1L]] > max(year_range) ||
      anyNA(values[-1L]) || any(values[-1L] <= 0 | values[-1L] >= 1)) {
      return(NULL)
    }
    data.frame(
      year = as.integer(values[[1L]]), age = ages,
      value = values[-1L]
    )
  })
  do.call(rbind, Filter(Negate(is.null), rows))
}
reported_q1_cv <- read_report_cv(908:910, 1983:2026, 1:6)
reported_q3_cv <- read_report_cv(911:912, 1991:2025, 0:6)
cv_match <- function(file_values, report_values) {
  i <- match(
    paste(report_values$year, report_values$age),
    paste(file_values$year, file_values$age)
  )
  !anyNA(i) && max(abs(file_values$value[i] - report_values$value)) <= 0.00051
}
stopifnot(
  nrow(reported_q1_cv) == 264L, nrow(reported_q3_cv) == 245L,
  cv_match(q1_cv, reported_q1_cv), cv_match(q3_cv, reported_q3_cv)
)

reported_cv <- rbind(
  input_rows("index", "relative_standard_error", "relative_scale",
    q1_cv$year, q1_cv$age, q1_cv$value, "coefficient of variation",
    survey = fleet_names[[2L]], sampling_time = sample_times[[2L]],
    source_type = "native_model",
    source_reference = paste0("stockassessment.org NSwhiting_2026n/data/Q1_Mod10_CV.dat; WGNSSK 2026 Table 22.17, PDF pp. 908-909"),
    transformation = "Read the six age-labelled CV fields after the leading marker in each source row.",
    notes = "The native fitted precision weights follow stockassessment::read.ices() and therefore use the first six fields, including the leading 1; the published age-labelled CVs are retained separately."
  ),
  input_rows("index", "relative_standard_error", "relative_scale",
    q3_cv$year, q3_cv$age, q3_cv$value, "coefficient of variation",
    survey = fleet_names[[3L]], sampling_time = sample_times[[3L]],
    source_type = "native_model",
    source_reference = paste0("stockassessment.org NSwhiting_2026n/data/Q3_Mod9_CV.dat; WGNSSK 2026 Table 22.19, PDF pp. 911-912"),
    transformation = "Read the seven age-labelled CV fields after the leading marker in each source row.",
    notes = "The native fitted precision weights follow stockassessment::read.ices() and therefore use the first seven fields, including the leading 1; the published age-labelled CVs are retained separately."
  )
)
inputs <- rbind(inputs, precision_rows, log_sd_rows, reported_cv)

output_rows <- function(type, measure, year, age = NA_integer_, age_group = "",
                        value, unit, lwr = NA_real_, upr = NA_real_,
                        source_type = "native_model", source_reference,
                        notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = rep_len(year, n), age = rep_len(age, n),
    age_group = rep_len(age_group, n), value = value, se = NA_real_,
    lwr = rep_len(lwr, n), upr = rep_len(upr, n), unit = rep_len(unit, n),
    source_type = source_type, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

surface_output <- function(x, type, measure, unit, slot, years, ages,
                           plus_age = 8L, plus_label = "8+", notes = "") {
  x <- as.matrix(x)
  grid <- expand.grid(year = years, age = ages)
  values <- as.vector(x)
  output_rows(
    type, measure, grid$year, grid$age,
    ifelse(grid$age == plus_age, plus_label, ""), values, unit,
    source_reference = paste0(model_url, "; exp(fit$pl$", slot, ")"),
    notes = paste(notes, paste0("Age ", plus_age, " is the ", plus_label, " group."))
  )
}

n_surface <- exp(t(fit$pl$logN))
f_surface <- exp(t(fit$pl$logF))
m_surface <- exp(fit$pl$logNM[seq_along(years), , drop = FALSE])
dimnames(n_surface) <- dimnames(f_surface) <- dimnames(m_surface) <-
  list(as.character(years), as.character(ages))
outputs <- rbind(
  surface_output(
    n_surface, "population", "numbers_at_age", "thousand fish",
    "logN", years, ages
  ),
  surface_output(
    f_surface, "mortality", "fishing_mortality_at_age", "per year",
    "logF", years, ages
  ),
  surface_output(m_surface, "mortality", "natural_mortality_at_age", "per year",
    "logNM", years, ages,
    notes = "Native SAM-estimated M surface; input M observations end in 2022, with later years estimated by the SAM mortality process."
  )
)

summary_lines <- unlist(strsplit(pages[917:920], "\n", fixed = TRUE),
  use.names = FALSE
)
summary_lines <- summary_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+",
  summary_lines,
  perl = TRUE
)]
summary_rows <- lapply(summary_lines, function(line) {
  values <- suppressWarnings(as.numeric(strsplit(trimws(line),
    "[[:space:]]+",
    perl = TRUE
  )[[1L]]))
  if (anyNA(values)) {
    return(NULL)
  }
  if (length(values) == 13L) {
    return(data.frame(
      year = as.integer(values[[1L]]), recruitment = values[[2L]],
      rec_lwr = values[[3L]], rec_upr = values[[4L]],
      SSB = values[[5L]], ssb_lwr = values[[6L]], ssb_upr = values[[7L]],
      Fbar = values[[8L]], fbar_lwr = values[[9L]], fbar_upr = values[[10L]],
      TSB = values[[11L]], tsb_lwr = values[[12L]], tsb_upr = values[[13L]]
    ))
  }
  if (length(values) == 4L && values[[1L]] == 2026L) {
    return(data.frame(
      year = 2026L, recruitment = NA_real_, rec_lwr = NA_real_, rec_upr = NA_real_,
      SSB = values[[2L]], ssb_lwr = values[[3L]], ssb_upr = values[[4L]],
      Fbar = NA_real_, fbar_lwr = NA_real_, fbar_upr = NA_real_,
      TSB = NA_real_, tsb_lwr = NA_real_, tsb_upr = NA_real_
    ))
  }
  NULL
})
summary <- do.call(rbind, Filter(Negate(is.null), summary_rows))
if (nrow(summary) != length(years) || !setequal(summary$year, years) ||
  anyDuplicated(summary$year)) {
  stop("Could not recover all annual summary rows from WGNSSK 2026 Table 22.22.", call. = FALSE)
}

native_summary <- data.frame(
  year = years,
  recruitment = n_surface[, "0"],
  SSB = rowSums(n_surface * dat$stockMeanWeight * dat$propMat),
  Fbar = rowMeans(f_surface[, as.character(2:5), drop = FALSE]),
  TSB = rowSums(n_surface * dat$stockMeanWeight)
)
comparison <- merge(summary, native_summary, by = "year", suffixes = c("_report", "_native"))
stopifnot(
  max(abs(comparison$recruitment_report - comparison$recruitment_native), na.rm = TRUE) < 1,
  max(abs(comparison$SSB_report - comparison$SSB_native), na.rm = TRUE) < 1,
  max(abs(comparison$Fbar_report - comparison$Fbar_native), na.rm = TRUE) < 0.00051,
  max(abs(comparison$TSB_report - comparison$TSB_native), na.rm = TRUE) < 1
)
summary_outputs <- rbind(
  output_rows("recruitment", "recruitment", summary$year[!is.na(summary$recruitment)],
    age = 0L,
    age_group = "age 0", value = summary$recruitment[!is.na(summary$recruitment)],
    unit = "thousand fish", lwr = summary$rec_lwr[!is.na(summary$recruitment)],
    upr = summary$rec_upr[!is.na(summary$recruitment)], source_type = "official_table",
    source_reference = paste0(report_url, "; Table 22.22, PDF pp. 917-919"),
    notes = "Recruitment at age 0; report-published 95% confidence limits."
  ),
  output_rows("biomass", "SSB", summary$year,
    value = summary$SSB,
    unit = "tonnes", lwr = summary$ssb_lwr, upr = summary$ssb_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; Table 22.22, PDF pp. 917-919"),
    notes = "Report-published SSB and 95% confidence limits."
  ),
  output_rows("mortality", "Fbar", summary$year[!is.na(summary$Fbar)],
    age_group = "2-5",
    value = summary$Fbar[!is.na(summary$Fbar)], unit = "per year",
    lwr = summary$fbar_lwr[!is.na(summary$Fbar)], upr = summary$fbar_upr[!is.na(summary$Fbar)],
    source_type = "official_table",
    source_reference = paste0(report_url, "; Table 22.22, PDF pp. 917-919"),
    notes = "Mean fishing mortality over ages 2-5 with report-published 95% confidence limits."
  ),
  output_rows("biomass", "total_biomass", summary$year[!is.na(summary$TSB)],
    value = summary$TSB[!is.na(summary$TSB)],
    unit = "tonnes", lwr = summary$tsb_lwr[!is.na(summary$TSB)], upr = summary$tsb_upr[!is.na(summary$TSB)],
    source_type = "official_table",
    source_reference = paste0(report_url, "; Table 22.22, PDF pp. 917-919"),
    notes = "Total stock biomass and report-published 95% confidence limits."
  )
)
outputs <- rbind(outputs, summary_outputs)

assumption <- function(component, setting, value, source_reference, notes = "",
                       survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = survey, sex = "", region = "", season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
report_ref <- paste0(report_url, "; WGNSSK 2026, Section 22 and Tables 22.13-22.24")
model_cfg_ref <- paste0(model_url, "; fit$conf and conf/model.cfg")
assumptions <- do.call(rbind, list(
  assumption("model", "model_age_range", "ages 0-8+, recruitment at age 0", report_ref),
  assumption("model", "terminal_year", "2025 fitted catch year; 2026 intermediate year", report_ref),
  assumption(
    "N", "process", "random walk with age-specific variance sharing", model_cfg_ref,
    "stockRecruitmentModelCode=0; keyVarLogN groups ages 0, 1-7 and 8+"
  ),
  assumption(
    "N", "logN_mean", "median", model_cfg_ref,
    "logNMeanAssumption is 0 for recruitment and older ages"
  ),
  assumption(
    "F", "process", "random-walk increments with AR(1) correlation across ages", model_cfg_ref,
    "corFlag=2; one shared F-process variance; age-specific F states"
  ),
  assumption("F", "Fbar_ages", "2-5", model_cfg_ref),
  assumption(
    "M", "process", "GMRF estimated from WGSAM M observations", report_ref,
    "Observed M inputs end in 2022; SAM estimates the later-year M surface."
  ),
  assumption("M", "mean_age_groups", "ages 0-5 separate; ages 6-8 share the 6+ group", model_cfg_ref),
  assumption(
    "catch", "likelihood", "lognormal; independent age residuals", model_cfg_ref,
    "Observation variance is shared across the configured catch-age groups."
  ),
  assumption(
    "index", "catchability", "separate q by survey and age; no q-power parameters", model_cfg_ref,
    "Native survey scale is retained; no physical abundance unit is assigned.", fleet_names[[2L]]
  ),
  assumption(
    "index", "observation_process", "lognormal with AR(1) age residual correlation", model_cfg_ref,
    "Native relative precision weights are preserved.", fleet_names[[2L]]
  ),
  assumption(
    "index", "sampling_time", as.character(sample_times[[2L]]), model_cfg_ref,
    "Native sampleTimes entry.", fleet_names[[2L]]
  ),
  assumption(
    "index", "age_range", "ages 1-6+", report_ref,
    "Q1 survey series from 1983 through 2026.", fleet_names[[2L]]
  ),
  assumption(
    "index", "observation_process", "lognormal with AR(1) age residual correlation", model_cfg_ref,
    "Native relative precision weights are preserved.", fleet_names[[3L]]
  ),
  assumption(
    "index", "sampling_time", as.character(sample_times[[3L]]), model_cfg_ref,
    "Native sampleTimes entry.", fleet_names[[3L]]
  ),
  assumption(
    "index", "age_range", "ages 0-6+", report_ref,
    "Q3 survey series from 1991 through 2025.", fleet_names[[3L]]
  ),
  assumption("biology", "weights_and_maturity", "stock weight, catch weight and smoothed maturity are known", model_cfg_ref),
  assumption(
    "biology", "spawning_time", "propF=0 and propM=0", model_cfg_ref,
    "The native data object supplies zero mortality fractions before spawning."
  ),
  assumption(
    "fit", "optimizer", fit$opt$message, model_url,
    paste0("Convergence code ", fit$opt$convergence, "; objective ", signif(fit$opt$objective, 8), ".")
  )
))

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "whg.27.47d", scientific_name = "Merlangius merlangus",
  common_name = "North Sea whiting", area = "Subarea 4 and Division 7.d",
  region = "Greater North Sea", ocean = "Northeast Atlantic",
  notes = "ICES stock code whg.27.47d; age-structured SAM assessment.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L, assessment_type = "annual_assessment",
  model_family = "SAM", model_version = "WGNSSK 2026 official NSwhiting_2026n run",
  is_current = TRUE, is_applied = TRUE, framework_year = 2026L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graph_url, model_url = model_url, repository_url = "",
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "partial",
  notes = paste(
    "The April NSwhiting_2026n run matches published summary estimates for 1978-2025 and the official 2026 SSB value.",
    "A later June update exists but does not match the published 2026 summary series and is not treated as official.",
    "Age-specific state uncertainty and fitted observation predictions are not exported; aggregate intervals are available from the report. The native fit and documented input matrices are cached locally outside Git."
  ),
  stringsAsFactors = FALSE
)

database <- file.path(base, "database")
read_db <- function(name) {
  read.csv(file.path(database, name),
    colClasses = "character", na.strings = "",
    check.names = FALSE
  )
}
append_rows <- function(path, rows, current) {
  if (!identical(names(current), names(rows))) {
    stop("Unexpected columns in ", basename(path), ".", call. = FALSE)
  }
  if (any(current$assessment_id == assessment_id, na.rm = TRUE)) {
    stop("North Sea whiting is already present in ", basename(path), ".", call. = FALSE)
  }
  utils::write.table(rows, path,
    sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}

stocks_path <- file.path(database, "stocks.csv")
stocks <- read_db("stocks.csv")
if (!identical(names(stocks), names(stock)) || any(stocks$stock_id == stock_id)) {
  stop("Unexpected stock schema or North Sea whiting already exists.", call. = FALSE)
}
append_rows(
  file.path(database, "assessments.csv"), assessment,
  read_db("assessments.csv")
)
append_rows(
  file.path(database, "assumptions.csv"), assumptions,
  read_db("assumptions.csv")
)
append_rows(file.path(database, "inputs.csv"), inputs, read_db("inputs.csv"))
append_rows(file.path(database, "outputs.csv"), outputs, read_db("outputs.csv"))
utils::write.table(stock, stocks_path,
  sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
)

cat("Added North Sea whiting: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n",
  sep = ""
)
