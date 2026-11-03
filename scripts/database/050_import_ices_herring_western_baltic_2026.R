assessment_id <- "ices_herring_western_baltic_2026"
stock_id <- "ices_herring_western_baltic"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", assessment_id)

report_url <- "https://backend.orbit.dtu.dk/ws/portalfiles/portal/440308463/HAWG_2026_-_Full_Report.pdf"
framework_url <- "https://doi.org/10.17895/ices.pub.31538287"
graph_url <- "https://sg.ices.dk/ViewSourceData.aspx?key=21294"
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "WBSS_HAWG_2026/run/model.RData"
)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "model.RData"), envir = model_env)
fit <- model_env$fit
dat <- fit$data
years <- as.integer(dat$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
fleet_names <- attr(dat, "fleetNames")
sample_times <- as.numeric(dat$sampleTimes)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to verify the published summary table.", call. = FALSE)
}
pages <- pdftools::pdf_text(file.path(cache, "HAWG_2026_Full_Report.pdf"))

stopifnot(
  fit$opt$convergence == 0L,
  identical(years, 1991:2025),
  identical(ages, 0:8),
  length(fleet_names) == 5L,
  identical(as.integer(table(aux$fleet)), c(315L, 175L, 96L, 34L, 72L)),
  identical(sample_times, c(0, 0.625, 0.8, 0.4, 0.136365)),
  identical(as.integer(fit$conf$stockRecruitmentModelCode), 61L),
  identical(as.integer(fit$conf$corFlag), 2L),
  identical(as.integer(fit$conf$keyLogFsta[1, ]), c(0:7, 7L)),
  identical(as.integer(fit$conf$keyVarLogN), c(0L, rep(1L, 8L))),
  identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 1L, 0L, 0L, 1L)),
  all(dat$natMor == matrix(dat$natMor[1, ], nrow(dat$natMor),
    ncol(dat$natMor),
    byrow = TRUE
  )),
  all(dat$propMat == matrix(dat$propMat[1, ], nrow(dat$propMat),
    ncol(dat$propMat),
    byrow = TRUE
  ))
)

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_type = "native_model", source_reference,
                       transformation = "Copied from the official SAM fit.",
                       notes = "") {
  n <- length(value)
  yr <- rep_len(year, n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = rep_len(basis, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey, n), sex = "", region = "", season = "",
    year = yr, year_basis = ifelse(is.na(yr), "", "calendar_year"),
    age = rep_len(age, n), value = value, unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

matrix_input <- function(x, type, measure, basis, unit, slot, years, ages,
                         notes = "", source_reference = model_url) {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("Unexpected dimensions for fit$data$", slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages)
  values <- as.vector(x)
  keep <- is.finite(values)
  input_rows(
    type, measure, basis, grid$year[keep], grid$age[keep], values[keep], unit,
    source_reference = paste0(source_reference, "; fit$data$", slot),
    notes = notes
  )
}

static_input <- function(type, measure, basis, value, unit, slot,
                         notes, source_reference) {
  input_rows(
    type, measure, basis, NA_integer_, ages, as.numeric(value), unit,
    source_reference = paste0(source_reference, "; fit$data$", slot),
    notes = notes
  )
}

observation_inputs <- lapply(seq_along(fleet_names), function(fleet_id) {
  take <- which(aux$fleet == fleet_id & is.finite(dat$logobs))
  if (fleet_id == 1L) {
    input_rows(
      "catch", "numbers_at_age", "numbers", aux$year[take], aux$age[take],
      exp(dat$logobs[take]), "thousand fish",
      fleet = "Total catch",
      source_reference = paste0(model_url, "; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the native log catch observations.",
      notes = "Total catch-at-age supplied to the official assessment; age 8 is the plus group."
    )
  } else {
    input_rows(
      "index", "numbers_at_age", "index_scale", aux$year[take], aux$age[take],
      exp(dat$logobs[take]), "native survey-index units",
      survey = fleet_names[[fleet_id]],
      sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "; fit$data$logobs and fit$data$aux"),
      transformation = "Exponentiated the native log survey-index observations.",
      notes = "Retained on the native relative index scale; survey age ranges and plus groups are defined by the fitted model."
    )
  }
})

inputs <- do.call(rbind, c(observation_inputs, list(
  matrix_input(
    dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "stockMeanWeight", years, ages,
    "Annual stock weight-at-age used by SAM."
  ),
  matrix_input(
    dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "catchMeanWeight", years, ages,
    "Annual catch weight-at-age used by SAM."
  ),
  static_input(
    "maturity", "maturity_at_age", "proportion",
    dat$propMat[1, ], "proportion", "propMat",
    "Time-invariant maturity ogive used by the official model.",
    paste0(report_url, "; Table 3.6.5, PDF p. 247")
  ),
  static_input(
    "M", "natural_mortality_at_age", "per_year",
    dat$natMor[1, ], "per year", "natMor",
    "Fixed, age-specific natural mortality; mortalityModel=0 and the same values are used in every year. The HAWG report says this pattern is derived from NSAS herring M and was profiled during the 2025 benchmark.",
    paste0(report_url, "; p. 173 and Table 3.6.4")
  ),
  static_input(
    "biology", "fraction_F_before_spawning", "proportion",
    dat$propF[1, , 1], "proportion", "propF",
    "Fraction of annual F before spawning; constant over time.",
    paste0(report_url, "; p. 173 and Table 3.6.6")
  ),
  static_input(
    "biology", "fraction_M_before_spawning", "proportion",
    dat$propM[1, ], "proportion", "propM",
    "Fraction of annual M before spawning; constant over time.",
    paste0(report_url, "; p. 173 and Table 3.6.7")
  )
)))

weighted <- which(aux$fleet > 1L & is.finite(dat$logobs) & is.finite(dat$weight) & dat$weight > 0)
if (length(weighted)) {
  inputs <- rbind(inputs, input_rows(
    "index", "relative_precision_weight", "relative_precision",
    aux$year[weighted], aux$age[weighted], dat$weight[weighted],
    "relative precision weight",
    survey = fleet_names[aux$fleet[weighted]],
    sampling_time = sample_times[aux$fleet[weighted]],
    source_reference = paste0(model_url, "; fit$data$weight and fit$data$aux"),
    transformation = "Copied the finite native SAM observation precision weights.",
    notes = "SAM fits other index observations without a finite row-specific precision weight; missing weights remain unfilled."
  ))
  inputs <- rbind(inputs, input_rows(
    "index", "log_index_sd", "log_scale",
    aux$year[weighted], aux$age[weighted], 1 / sqrt(dat$weight[weighted]),
    "relative log-scale SD factor",
    survey = fleet_names[aux$fleet[weighted]],
    sampling_time = sample_times[aux$fleet[weighted]],
    source_reference = paste0(model_url, "; fit$data$weight and fit$data$aux"),
    transformation = "Derived as 1/sqrt(native precision weight), matching the relative SD multiplier in the SAM lognormal likelihood.",
    notes = "The multiplier applies to the estimated observation SD; observations with no native precision weight use a multiplier of 1 in tinyAM."
  ))
}

output_rows <- function(type, measure, year, age = NA_integer_,
                        age_group = "", value, unit, lwr = NA_real_,
                        upr = NA_real_, source_type = "native_model",
                        source_reference, notes = "") {
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
                           notes = "", source_reference = model_url) {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("Unexpected dimensions in ", slot, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages)
  values <- as.vector(x)
  output_rows(
    type, measure, grid$year, grid$age,
    ifelse(grid$age == max(ages), paste0(max(ages), "+"), ""),
    values, unit,
    source_reference = paste0(source_reference, "; ", slot),
    notes = paste(notes, paste0("Age ", max(ages), " is the ", max(ages), "+ group."))
  )
}

n_age_year <- exp(fit$pl$logN)
f_age_year <- exp(fit$pl$logF[as.integer(fit$conf$keyLogFsta[1, ]) + 1L, ,
  drop = FALSE
])
m_age_year <- t(dat$natMor)
dimnames(n_age_year) <- dimnames(f_age_year) <- dimnames(m_age_year) <-
  list(as.character(ages), as.character(years))

native_summary <- data.frame(
  year = years,
  recruitment = n_age_year[1, ],
  SSB = colSums(n_age_year * t(dat$stockMeanWeight) * t(dat$propMat) *
    exp(-m_age_year * t(dat$propM) -
      f_age_year * t(dat$propF[, , 1]))),
  Fbar = colMeans(f_age_year[match(2:5, ages), , drop = FALSE]),
  TSB = colSums(n_age_year * t(dat$stockMeanWeight))
)

summary_lines <- unlist(strsplit(pages[263:264], "\n", fixed = TRUE),
  use.names = FALSE
)
summary_lines <- summary_lines[
  grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", summary_lines,
    perl = TRUE
  )
]
summary_rows <- lapply(summary_lines, function(line) {
  values <- suppressWarnings(as.numeric(strsplit(trimws(line),
    "[[:space:]]+",
    perl = TRUE
  )[[1L]]))
  if (length(values) != 13L || anyNA(values)) {
    return(NULL)
  }
  data.frame(
    year = as.integer(values[[1L]]),
    recruitment = values[[2L]], recruitment_lwr = values[[3L]],
    recruitment_upr = values[[4L]], SSB = values[[5L]],
    SSB_lwr = values[[6L]], SSB_upr = values[[7L]],
    Fbar = values[[8L]], Fbar_lwr = values[[9L]], Fbar_upr = values[[10L]],
    TSB = values[[11L]], TSB_lwr = values[[12L]], TSB_upr = values[[13L]]
  )
})
summary <- do.call(rbind, Filter(Negate(is.null), summary_rows))
summary <- summary[order(summary$year), , drop = FALSE]
if (nrow(summary) != length(years) || !identical(summary$year, years)) {
  stop("Could not recover Table 3.6.11 for all years.", call. = FALSE)
}
check <- merge(summary, native_summary, by = "year", suffixes = c("_report", "_native"))
stopifnot(
  max(abs(check$recruitment_report - check$recruitment_native)) < 1,
  max(abs(check$SSB_report - check$SSB_native)) < 1,
  max(abs(check$Fbar_report - check$Fbar_native)) <= 0.00051,
  max(abs(check$TSB_report - check$TSB_native)) < 1
)

table_text <- paste(pages[264:270], collapse = "\n")
f_start <- regexpr("Table 3.6.12", table_text, fixed = TRUE)[[1L]]
n_start <- regexpr("Table 3.6.13", table_text, fixed = TRUE)[[1L]]
if (f_start < 1L || n_start < 1L || n_start <= f_start) {
  stop("Could not locate the published F- and N-at-age tables.", call. = FALSE)
}
read_surface_table <- function(text, label) {
  lines <- unlist(strsplit(text, "\n", fixed = TRUE), use.names = FALSE)
  rows <- lapply(lines, function(line) {
    value <- suppressWarnings(as.numeric(strsplit(trimws(line),
      "[[:space:]]+",
      perl = TRUE
    )[[1L]]))
    if (length(value) != length(ages) + 1L || anyNA(value) ||
      value[[1L]] < min(years) || value[[1L]] > max(years) ||
      value[[1L]] != as.integer(value[[1L]])) {
      return(NULL)
    }
    row <- as.data.frame(as.list(value))
    names(row) <- c("year", paste0("age", ages))
    row
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) stop("No rows found in ", label, ".", call. = FALSE)
  result <- do.call(rbind, rows)
  result <- result[order(result$year), , drop = FALSE]
  if (nrow(result) != length(years) || anyDuplicated(result$year) ||
    !identical(as.integer(result$year), years)) {
    stop("The published ", label, " table does not cover each model year once.",
      call. = FALSE
    )
  }
  as.matrix(result[, -1L, drop = FALSE])
}
published_F <- read_surface_table(
  substr(table_text, f_start, n_start - 1L), "F-at-age"
)
published_N <- read_surface_table(
  substr(table_text, n_start, nchar(table_text)),
  "stock-numbers-at-age"
)
stopifnot(
  max(abs(t(f_age_year) - published_F)) <= 0.00051,
  max(abs(t(n_age_year) - published_N)) < 1
)
summary_outputs <- rbind(
  output_rows("recruitment", "recruitment", summary$year,
    age = 0L,
    age_group = "age 0", value = summary$recruitment,
    unit = "thousand fish", lwr = summary$recruitment_lwr,
    upr = summary$recruitment_upr, source_type = "official_table",
    source_reference = paste0(report_url, "; Table 3.6.11, PDF pp. 253-254"),
    notes = "Recruitment at age 0 with published 95% confidence limits."
  ),
  output_rows("biomass", "SSB", summary$year,
    value = summary$SSB,
    unit = "tonnes", lwr = summary$SSB_lwr, upr = summary$SSB_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; Table 3.6.11, PDF pp. 253-254"),
    notes = "Spawning stock biomass with published 95% confidence limits."
  ),
  output_rows("mortality", "Fbar", summary$year,
    age_group = "2-5",
    value = summary$Fbar, unit = "per year",
    lwr = summary$Fbar_lwr, upr = summary$Fbar_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; Table 3.6.11, PDF pp. 253-254"),
    notes = "Mean F at ages 2-5 with published 95% confidence limits."
  ),
  output_rows("biomass", "total_biomass", summary$year,
    value = summary$TSB,
    unit = "tonnes", lwr = summary$TSB_lwr, upr = summary$TSB_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; Table 3.6.11, PDF pp. 253-254"),
    notes = "Total stock biomass with published 95% confidence limits."
  )
)

outputs <- rbind(
  surface_output(
    t(n_age_year), "population", "numbers_at_age",
    "thousand fish", "exp(fit$pl$logN)", years, ages,
    "Official stock numbers at age; values are on the SAM model scale."
  ),
  surface_output(
    t(f_age_year), "mortality", "fishing_mortality_at_age",
    "per year", "expanded exp(fit$pl$logF) using keyLogFsta",
    years, ages,
    "The fitted F state is shared for ages 7 and 8; the report table is rounded to three decimals.",
    paste0(report_url, "; Table 3.6.12, PDF pp. 254-256")
  ),
  surface_output(
    dat$natMor, "mortality", "natural_mortality_at_age",
    "per year", "fixed fit$data$natMor", years, ages,
    "The applied M surface repeats the fixed age-specific M input in every year; it was not estimated by this run.",
    paste0(report_url, "; Table 3.6.4 and p. 173")
  ),
  summary_outputs
)

assumption <- function(component, setting, value, source_reference, notes = "",
                       survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = survey, sex = "", region = "", season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
report_ref <- paste0(report_url, "; HAWG 2026, Section 3.6 and Tables 3.6.4-3.6.13")
config_ref <- paste0(model_url, "; fit$conf and fit$data")
assumptions <- do.call(rbind, list(
  assumption("model", "model_age_range", "ages 0-8+, recruitment at age 0", report_ref),
  assumption("model", "fitted_years", "1991-2025", report_ref),
  assumption(
    "N", "process", "SAM age-structured population process", config_ref,
    "keyVarLogN gives a separate variance for recruitment at age 0 and a shared variance for ages 1-8."
  ),
  assumption(
    "recruitment", "stock_recruitment", "segmented regression (hockey-stick)", config_ref,
    "stockRecruitmentModelCode=61; the report notes this relationship was estimated at the 2025 benchmark and held fixed for this assessment."
  ),
  assumption(
    "F", "age_process_correlation", "AR(1) across ages", config_ref,
    "corFlag=2; tinyAM does not reproduce this cross-age covariance."
  ),
  assumption(
    "F", "age_state_sharing", "ages 0-6 have separate states; ages 7 and 8 share one F state", config_ref,
    "keyLogFsta is 0,1,2,3,4,5,6,7,7 across ages 0-8."
  ),
  assumption(
    "F", "process_variance", "shared across modeled ages", config_ref,
    "keyVarF shares the F-process variance across age."
  ),
  assumption("F", "Fbar_ages", "2-5", config_ref),
  assumption(
    "M", "process", "fixed, time-invariant age-specific M", config_ref,
    "mortalityModel=0; the M surface in outputs is the applied fixed input, not an estimated process."
  ),
  assumption("M", "source", "derived from NSAS herring M and profiled during the 2025 benchmark", report_ref),
  assumption("biology", "maturity", "constant; ages 0-1 immature, ages 2-4 are 20%, 75%, 90% mature, ages 5+ fully mature", report_ref),
  assumption(
    "biology", "spawning_fractions", "propF=0.168; propM=0.25", report_ref,
    "Fractions of annual fishing and natural mortality occurring before spawning."
  ),
  assumption(
    "catch", "likelihood", "lognormal with age-grouped observation variances", config_ref,
    "keyVarObs uses separate catch variance groups for ages 0, 1, and 2-8."
  ),
  assumption(
    "index", "q_sharing", "survey-specific age groups as specified by keyLogFpar", config_ref,
    "HERAS ages 2 and 3-6; GERAS ages 1-2 and 3; N20 age 0; IBTS/BITS Q1 ages 3, 4, and 5+."
  ),
  assumption(
    "index", "observation_correlation", "AR(1) over age for HERAS, GERAS, and IBTS/BITS Q1; independent for N20", config_ref,
    "obsCorStruct=ID, AR, AR, ID, AR."
  ),
  assumption(
    "index", "precision_weights", "finite row-specific weights supplied only for IBTS/BITS Q1", config_ref,
    "Other source index observations have missing precision weights in the native SAM data object."
  ),
  assumption(
    "fit", "optimizer", as.character(fit$opt$convergence), config_ref,
    paste0("Convergence code ", fit$opt$convergence, "; objective ", signif(fit$opt$objective, 9), ".")
  )
))
for (i in seq_along(fleet_names)[-1L]) {
  assumption("index", "sampling_time", as.character(sample_times[[i]]), config_ref,
    "Native within-year sampling fraction in fit$data$sampleTimes.",
    survey = fleet_names[[i]]
  )
}
for (i in seq_along(fleet_names)[-1L]) {
  rows <- aux[aux$fleet == i, , drop = FALSE]
  assumption("index", "age_range",
    paste0(
      min(rows$age), "-", max(rows$age),
      if (fit$conf$maxAgePlusGroup[[i]] == 1L) "+" else ""
    ),
    config_ref,
    survey = fleet_names[[i]]
  )
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "her.27.20-24",
  scientific_name = "Clupea harengus",
  common_name = "Western Baltic spring-spawning herring",
  area = "Subdivisions 20-24", region = "Skagerrak, Kattegat, and western Baltic",
  ocean = "Northeast Atlantic",
  notes = "ICES stock her.27.20-24; spring-spawning herring assessed with single-fleet SAM.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "stockassessment 0.12.0; WBSS_HAWG_2026",
  is_current = TRUE, is_applied = TRUE, framework_year = 2025L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graph_url, model_url = model_url, repository_url = "",
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste(
    "Official HAWG 2026 single-fleet SAM assessment for 1991-2025.",
    "The cached fit converges and reproduces the report's annual recruitment, SSB, Fbar and TSB after applying keyLogFsta to expand the age-shared F state.",
    "Published F-at-age and stock-numbers-at-age are available in Tables 3.6.12 and 3.6.13; age-specific uncertainty is not tabulated."
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
append_rows <- function(path, rows, current, key) {
  if (!identical(names(current), names(rows))) {
    stop("Unexpected columns in ", basename(path), ".", call. = FALSE)
  }
  if (any(current[[key]] == assessment_id, na.rm = TRUE)) {
    stop("This assessment already occurs in ", basename(path), ".", call. = FALSE)
  }
  utils::write.table(rows, path,
    sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}

stocks <- read_db("stocks.csv")
if (!identical(names(stocks), names(stock)) || any(stocks$stock_id == stock_id)) {
  stop("Unexpected stock schema or this stock already exists.", call. = FALSE)
}
append_rows(
  file.path(database, "assessments.csv"), assessment,
  read_db("assessments.csv"), "assessment_id"
)
append_rows(
  file.path(database, "assumptions.csv"), assumptions,
  read_db("assumptions.csv"), "assessment_id"
)
append_rows(
  file.path(database, "inputs.csv"), inputs, read_db("inputs.csv"),
  "assessment_id"
)
append_rows(
  file.path(database, "outputs.csv"), outputs, read_db("outputs.csv"),
  "assessment_id"
)
utils::write.table(stock, file.path(database, "stocks.csv"),
  sep = ",",
  quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = ""
)

message(
  "Added ", nrow(inputs), " inputs, ", nrow(assumptions),
  " assumptions, and ", nrow(outputs), " outputs for ", assessment_id,
  ". Terminal checks: SSB=", tail(summary$SSB, 1),
  ", Fbar=", tail(summary$Fbar, 1),
  ", recruitment=", tail(summary$recruitment, 1), "."
)
