assessment_id <- "ices_plaice_baltic_21_32_2026"
stock_id <- "ices_plaice_baltic_21_32"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", "ices_plaice_baltic_21_32_2026")
run_file <- file.path(cache, "run__model.RData")
data_file <- file.path(cache, "run__data.RData")
report_file <- file.path(cache, "WGBFAS_2026.pdf")
run_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.21.32_WGBFAS_2026_SA/run/model.RData"
data_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.21.32_WGBFAS_2026_SA/data/"
report_url <- "https://literatur.thuenen.de/digbib_extern/dn071152.pdf"
database <- file.path(base, "database")

if (!requireNamespace("stockassessment", quietly = TRUE) ||
  !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install stockassessment and pdftools before running this importer.", call. = FALSE)
}

read_db <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE
  )
}

schemas <- lapply(c("stocks.csv", "assessments.csv", "assumptions.csv",
  "inputs.csv", "outputs.csv"), function(name) {
  names(utils::read.csv(file.path(database, name), nrows = 0,
    colClasses = "character", check.names = FALSE
  ))
})
names(schemas) <- c("stocks", "assessments", "assumptions", "inputs", "outputs")

empty_rows <- function(schema, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(schema)),
    stringsAsFactors = FALSE
  )
  names(out) <- schema
  out
}

value_text <- function(x) {
  ifelse(is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_reference, transformation, notes = "",
                       source_type = "native_model") {
  n <- length(value)
  out <- empty_rows(schemas$inputs, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- rep_len(basis, n)
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$year <- ifelse(is.na(rep_len(year, n)), "", as.character(rep_len(year, n)))
  out$year_basis <- ifelse(nzchar(out$year), "calendar_year", "")
  out$age <- ifelse(is.na(rep_len(age, n)), "", as.character(rep_len(age, n)))
  out$value <- value_text(rep_len(value, n))
  out$unit <- rep_len(unit, n)
  out$sampling_time <- ifelse(is.finite(rep_len(sampling_time, n)),
    value_text(rep_len(sampling_time, n)), ""
  )
  out$source_type <- rep_len(source_type, n)
  out$source_reference <- rep_len(source_reference, n)
  out$transformation <- rep_len(transformation, n)
  out$notes <- rep_len(notes, n)
  out
}

output_rows <- function(type, measure, year, value, unit, age = NA_integer_,
                        age_group = "", fleet = "", survey = "",
                        lwr = NA_real_, upr = NA_real_,
                        source_reference, notes = "",
                        source_type = "official_table") {
  n <- length(value)
  out <- empty_rows(schemas$outputs, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(rep_len(year, n))
  out$age <- ifelse(is.na(rep_len(age, n)), "", as.character(rep_len(age, n)))
  out$age_group <- rep_len(age_group, n)
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$value <- value_text(rep_len(value, n))
  out$lwr <- value_text(rep_len(lwr, n))
  out$upr <- value_text(rep_len(upr, n))
  out$unit <- rep_len(unit, n)
  out$source_type <- rep_len(source_type, n)
  out$source_reference <- rep_len(source_reference, n)
  out$notes <- rep_len(notes, n)
  out
}

matrix_inputs <- function(x, type, measure, basis, unit, years, ages,
                          source_reference, transformation, notes = "") {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("Unexpected dimensions for ", measure, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages)
  value <- as.vector(x)
  keep <- is.finite(value)
  input_rows(type, measure, basis, grid$year[keep], grid$age[keep], value[keep],
    unit, source_reference = source_reference, transformation = transformation,
    notes = notes
  )
}

assumption_rows <- function(component, setting, value, source_reference,
                            notes = "", survey = "") {
  out <- empty_rows(schemas$assumptions, length(value))
  out$assessment_id <- assessment_id
  out$component <- component
  out$survey <- rep_len(survey, length(value))
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- rep_len(notes, length(value))
  out
}

read_report_table <- function(pattern, expected_values) {
  pages <- pdftools::pdf_text(report_file)
  page <- grep(pattern, pages, perl = TRUE)
  if (length(page) != 1L) {
    stop("Could not uniquely locate report table ", pattern, ".", call. = FALSE)
  }
  lines <- unlist(strsplit(pages[page], "\n", fixed = TRUE), use.names = FALSE)
  lines <- lines[grepl("^[[:space:]]*20[0-9]{2}[[:space:]]+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    cells <- strsplit(trimws(gsub("[[:space:]]+", " ", line)), " ", fixed = TRUE)[[1L]]
    values <- suppressWarnings(as.numeric(cells))
    if (length(values) != expected_values + 1L || anyNA(values)) return(NULL)
    values
  })
  rows <- Filter(Negate(is.null), rows)
  out <- as.data.frame(do.call(rbind, rows))
  names(out) <- c("year", paste0("value", seq_len(expected_values)))
  out$year <- as.integer(out$year)
  out <- out[out$year %in% 2002:2025, , drop = FALSE]
  if (!identical(out$year, 2002:2025)) {
    stop("Report table ", pattern, " does not cover 2002-2025.", call. = FALSE)
  }
  out
}

model_env <- new.env(parent = baseenv())
data_env <- new.env(parent = baseenv())
load(run_file, envir = model_env)
load(data_file, envir = data_env)
fit <- model_env$fit
dat <- fit$data
years <- as.integer(dat$years)
ages <- seq_len(ncol(dat$stockMeanWeight))
aux <- as.data.frame(dat$aux)
names(aux) <- c("year", "fleet", "age")
fleet_names <- attr(dat, "fleetNames")
sample_times <- as.numeric(dat$sampleTimes)

if (!inherits(fit, "sam") || fit$opt$convergence != 0L ||
  !identical(as.integer(data_env$dat$years), years) ||
  !identical(as.numeric(data_env$dat$logobs), as.numeric(dat$logobs)) ||
  !identical(years, 2002:2025) || !identical(ages, 1:7) ||
  dat$nobs != 490L || !identical(as.integer(table(aux$fleet)), c(161L, 168L, 161L)) ||
  !identical(sample_times, c(0, 0.1507111, 0.8173179)) ||
  !identical(as.integer(fit$conf$keyLogFsta[1L, ]), 0:5 |> c(5L))) {
  stop("The cached SAM model does not match the pinned WGBFAS 2026 run.", call. = FALSE)
}

run_version <- paste0("WGBFAS 2026; stockassessment ", attr(fit, "Version"),
  "; upstream revision ", attr(fit, "RemoteSha"))
if (!grepl("1cc464b80f6f", run_version, fixed = TRUE)) {
  stop("The cached SAM object is not the pinned stockassessment revision.", call. = FALSE)
}

catch_rows <- which(aux$fleet == 1L)
survey_names <- unname(fleet_names[2:3])
observation_rows <- lapply(seq_len(3L), function(fleet_id) {
  take <- which(aux$fleet == fleet_id)
  is_catch <- fleet_id == 1L
  input_rows(
    type = if (is_catch) "catch" else "index",
    measure = "numbers_at_age",
    basis = if (is_catch) "numbers" else "index_scale",
    year = aux$year[take], age = aux$age[take], value = exp(dat$logobs[take]),
    unit = if (is_catch) "thousand fish" else "native survey index (unit unresolved)",
    fleet = if (is_catch) fleet_names[[fleet_id]] else "",
    survey = if (is_catch) "" else survey_names[[fleet_id - 1L]],
    sampling_time = sample_times[[fleet_id]],
    source_reference = paste0(run_url, "; fit$data$logobs and fit$data$aux; data/cn.dat or data/survey.dat"),
    transformation = if (is_catch) {
      "Exponentiated the native SAM log catch after the data script divided catch numbers by 1000."
    } else {
      "Exponentiated the native SAM log index after the data script normalized each survey series to mean 1."
    },
    notes = if (is_catch) {
      "Total catch numbers-at-age, including landings and discards; age 7 is the 7+ group."
    } else {
      "Relative age-specific survey index; the source states no physical abundance multiplier."
    }
  )
})

weight_take <- which(is.finite(dat$weight))
weight_rows <- input_rows(
  type = ifelse(aux$fleet[weight_take] == 1L, "catch", "index"),
  measure = "relative_precision_weight",
  basis = "relative_precision",
  year = aux$year[weight_take], age = aux$age[weight_take],
  value = dat$weight[weight_take], unit = "relative weight",
  survey = ifelse(aux$fleet[weight_take] == 1L, "", survey_names[aux$fleet[weight_take] - 1L]),
  fleet = ifelse(aux$fleet[weight_take] == 1L, fleet_names[[1L]], ""),
  sampling_time = sample_times[aux$fleet[weight_take]],
  source_reference = paste0(run_url, "; fit$data$weight; data/Plaice2125-Q1-CV.csv and Plaice2125-Q4-CV.csv"),
  transformation = "Stored the per-observation weights used by the native SAM object, without rescaling.",
  notes = "SAM sets survey precision weights from the inverse squared CV. fixVarToWeight=0, so these are relative likelihood weights rather than fixed observation variances."
)

input_parts <- c(observation_rows, list(weight_rows,
  matrix_inputs(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", years, ages, paste0(run_url, "; fit$data$stockMeanWeight; data/sw.dat"),
    "Copied the native annual stock-weight surface, after combining ages 7 and older into 7+.",
    "SAM estimates a stock-weight process from these observations; tinyAM will use the recorded surface as fixed input."
  ),
  matrix_inputs(dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", years[-length(years)], ages,
    paste0(run_url, "; fit$data$catchMeanWeight; data/cw.dat"),
    "Copied the native annual catch-weight surface, ages 7 and older combined into 7+."
  ),
  matrix_inputs(dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish",
    "kg per fish", years[-length(years)], ages,
    paste0(run_url, "; fit$data$landMeanWeight; data/lw.dat"),
    "Copied the native annual landings-weight surface, ages 7 and older combined into 7+."
  ),
  matrix_inputs(dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish",
    "kg per fish", years[-length(years)], ages,
    paste0(run_url, "; fit$data$disMeanWeight; data/dw.dat"),
    "Copied the native annual discard-weight surface, ages 7 and older combined into 7+."
  ),
  matrix_inputs(dat$landFrac, "catch", "landings_fraction_at_age", "proportion",
    "proportion", years[-length(years)], ages,
    paste0(run_url, "; fit$data$landFrac; data/lf.dat"),
    "Copied the native annual landings fraction after combining ages 7 and older into 7+."
  ),
  matrix_inputs(dat$propMat, "maturity", "maturity_at_age", "proportion",
    "proportion", years, ages, paste0(run_url, "; fit$data$propMat; data/mo.dat"),
    "Copied the native annual maturity surface, ages 7 and older combined into 7+.",
    "Maturity is a five-year sliding-window input in the assessment, not an estimated process."
  ),
  matrix_inputs(dat$natMor, "M", "natural_mortality_at_age", "per_year",
    "per year", years, ages, paste0(run_url, "; fit$data$natMor; data/nm.dat"),
    "Copied the native age- and year-varying M surface, ages 7 and older combined into 7+.",
    "Fixed Gislason natural mortality with a five-year sliding average; not estimated by SAM."
  ),
  matrix_inputs(dat$propF, "biology", "fraction_F_before_spawning", "proportion",
    "proportion", years, ages, paste0(run_url, "; fit$data$propF; data/pf.dat"),
    "Copied the native pre-spawning fishing mortality fraction."
  ),
  matrix_inputs(dat$propM, "biology", "fraction_M_before_spawning", "proportion",
    "proportion", years, ages, paste0(run_url, "; fit$data$propM; data/pm.dat"),
    "Copied the native pre-spawning natural mortality fraction."
  )
))
inputs <- do.call(rbind, input_parts)

recruitment_table <- read_report_table("Table 5[.]2[.]5 Plaice", 9L)
F_table <- read_report_table("Table 5[.]2[.]6[.] Plaice", 7L)
N_table <- read_report_table("Table 5[.]2[.]7[.] Plaice", 7L)
if (recruitment_table$value1[recruitment_table$year == 2025L] != 6044652 ||
  recruitment_table$value2[recruitment_table$year == 2025L] != 8796107 ||
  recruitment_table$value4[recruitment_table$year == 2025L] != 79727 ||
  recruitment_table$value5[recruitment_table$year == 2025L] != 96773 ||
  recruitment_table$value8[recruitment_table$year == 2025L] != 0.02 ||
  abs(N_table$value1[N_table$year == 2025L] - 8796107) > 1) {
  stop("WGBFAS 2026 report values do not match the pinned tables.", call. = FALSE)
}

table_n_surface <- as.matrix(N_table[paste0("value", 1:7)])
table_f_surface <- as.matrix(F_table[paste0("value", 1:7)])
surface_rows <- function(x, type, measure, unit, source_reference, notes) {
  grid <- expand.grid(year = years, age = ages)
  value <- as.vector(x)
  output_rows(type, measure, grid$year, value, unit, grid$age,
    ifelse(grid$age == max(ages), "7+", ""),
    source_reference = source_reference, notes = notes
  )
}

age_outputs <- rbind(
  surface_rows(table_n_surface, "population", "numbers_at_age", "thousand fish",
    paste0(report_url, "; WGBFAS 2026 Table 5.2.7, printed p. 467"),
    "Published median estimates; age 7 is the 7+ group. The report does not provide age-specific uncertainty."
  ),
  surface_rows(table_f_surface, "mortality", "fishing_mortality_at_age", "per year",
    paste0(report_url, "; WGBFAS 2026 Table 5.2.6, printed p. 466"),
    "Published point estimates; age 7 is the 7+ group. The report does not provide age-specific uncertainty; the 2025 row's fitted-versus-forecast status is not specified."
  )
)

reported_summary <- rbind(
  output_rows("recruitment", "recruitment", recruitment_table$year,
    recruitment_table$value2, "thousand fish", age = 1L,
    lwr = recruitment_table$value1, upr = recruitment_table$value3,
    source_reference = paste0(report_url, "; WGBFAS 2026 Table 5.2.5, printed p. 465"),
    notes = "Published median age-1 recruitment; low and high values are 95% confidence limits."
  ),
  output_rows("biomass", "SSB", recruitment_table$year,
    recruitment_table$value5, "tonnes",
    lwr = recruitment_table$value4, upr = recruitment_table$value6,
    source_reference = paste0(report_url, "; WGBFAS 2026 Table 5.2.5, printed p. 465"),
    notes = "Published median spawning-stock biomass; low and high values are 95% confidence limits."
  ),
  output_rows("mortality", "Fbar", recruitment_table$year,
    recruitment_table$value8, "per year", age_group = "3-5",
    lwr = recruitment_table$value7, upr = recruitment_table$value9,
    source_reference = paste0(report_url, "; WGBFAS 2026 Table 5.2.5, printed p. 465"),
    notes = "Published median Fbar for ages 3-5; low and high values are 95% confidence limits."
  ),
  output_rows("population", "total_numbers", N_table$year,
    rowSums(table_n_surface), "thousand fish",
    source_type = "derived_source_output",
    source_reference = paste0(report_url, "; derived from WGBFAS 2026 Table 5.2.7"),
    notes = "Derived as the sum of published median N-at-age over ages 1-7+; uncertainty is unavailable."
  )
)

predicted_values <- exp(as.numeric(fit$rep$predObs))
if (length(predicted_values) != nrow(aux)) {
  stop("SAM fitted observation predictions do not align with the native observations.", call. = FALSE)
}
prediction_rows <- lapply(seq_len(3L), function(fleet_id) {
  take <- which(aux$fleet == fleet_id)
  is_catch <- fleet_id == 1L
  output_rows(
    type = if (is_catch) "catch" else "index",
    measure = if (is_catch) "predicted_catch" else "predicted_index",
    year = aux$year[take], age = aux$age[take],
    age_group = ifelse(aux$age[take] == max(ages), "7+", ""),
    value = predicted_values[take],
    unit = if (is_catch) "thousand fish" else "native survey index (unit unresolved)",
    fleet = if (is_catch) fleet_names[[fleet_id]] else "",
    survey = if (is_catch) "" else survey_names[[fleet_id - 1L]],
    source_type = "native_model",
    source_reference = paste0(run_url, "; fit$rep$predObs and fit$data$aux"),
    notes = "Fitted predictions from the public SAM object; the report's tabulated population estimates are stored separately."
  )
})

outputs <- rbind(age_outputs, reported_summary, do.call(rbind, prediction_rows))

key_logf <- as.integer(fit$conf$keyLogFsta[1L, ])
key_logfpar <- as.integer(fit$conf$keyLogFpar)
key_var_obs <- as.integer(fit$conf$keyVarObs)
assumptions <- do.call(rbind, list(
  assumption_rows("model", "model_age_range", "2002-2025; ages 1-7 with age 7 as 7+", paste0(report_url, "; Tables 5.2.5-5.2.7")),
  assumption_rows("N", "recruitment_age", "1", paste0(run_url, "; fit$conf$minAge")),
  assumption_rows("population", "plus_group", "7+", paste0(run_url, "; fit$conf$maxAge")),
  assumption_rows("model", "assessment_area", "ICES stock ple.27.21-32; Subdivisions 21-32", report_url),
  assumption_rows("N", "recruitment_process", "stockRecruitmentModelCode=0 (random walk)", paste0(run_url, "; fit$conf$stockRecruitmentModelCode")),
  assumption_rows("N", "process_variance_sharing", "age 1 separate; ages 2-7 share one variance", paste0(run_url, "; fit$conf$keyVarLogN")),
  assumption_rows("F", "process", "AR(1) correlation across ages; one F process variance", paste0(run_url, "; fit$conf$corFlag and keyVarF")),
  assumption_rows("F", "age_state_sharing", "ages 1-5 separate; ages 6-7 share one state", paste0(run_url, "; fit$conf$keyLogFsta"),
    notes = paste(key_logf, collapse = ", ")
  ),
  assumption_rows("F", "Fbar_ages", "3-5 in the WGBFAS 2026 report; the cached run config says 3-6", paste0(report_url, "; Table 5.2.5; ", run_url, "; fit$conf$fbarRange")),
  assumption_rows("M", "natural_mortality", "fixed, age- and year-varying Gislason M with a five-year sliding average", paste0(report_url, "; Section 5.3.3; ", run_url, "; fit$data$natMor")),
  assumption_rows("biology", "maturity", "fixed annual maturity ogives smoothed over a five-year sliding window", paste0(report_url, "; Section 5.3.4; ", run_url, "; fit$data$propMat")),
  assumption_rows("biology", "stock_weight", "annual age-specific weight input with an estimated SAM weight process", paste0(run_url, "; fit$conf$stockWeightModel and fit$data$stockMeanWeight")),
  assumption_rows("catch", "observation", "total catch-at-age; landings and discards retained as components", paste0(run_url, "; data/cn.dat, data/lf.dat")),
  assumption_rows("catch", "variance_sharing", "age 1 separate; ages 2-7 share one observation variance", paste0(run_url, "; fit$conf$keyVarObs")),
  assumption_rows("index", "surveys", paste(survey_names, collapse = "; "), paste0(run_url, "; fit$data$aux and fleetNames")),
  assumption_rows("index", "survey_timing", as.character(sample_times[2:3]), paste0(run_url, "; fit$data$sampleTimes"), survey = survey_names),
  assumption_rows("index", "q_age_groups", "Q1: 1, 2, 3-5, 6, 7+; Q4: 1, 2, 3, 4-7+", paste0(run_url, "; fit$conf$keyLogFpar")),
  assumption_rows("index", "variance_sharing", "Q1: all ages; Q4: age 1, ages 2-5, ages 6-7", paste0(run_url, "; fit$conf$keyVarObs")),
  assumption_rows("index", "relative_precision", "inverse squared survey CV; relative weights do not fix observation variance", paste0(run_url, "; fit$data$weight and fit$conf$fixVarToWeight")),
  assumption_rows("fit", "optimizer", fit$opt$message, run_url,
    paste0("Convergence code ", fit$opt$convergence, "; objective ", signif(fit$opt$objective, 8),
      "; stockassessment ", attr(fit, "Version"), "; upstream revision ", attr(fit, "RemoteSha"), ".")
  )
))

stock_rows <- read_db("stocks.csv")
if (any(stock_rows$stock_id == stock_id) ||
  any(read_db("assessments.csv")$assessment_id == assessment_id)) {
  stop("The Baltic plaice stock or assessment is already present.", call. = FALSE)
}
if (!any(stock_rows$stock_id == "ck_ices_wgbfas_platessa_bs_21_23") ||
  !any(stock_rows$stock_id == "ck_ices_wgbfas_platessa_bs_24_32")) {
  stop("Expected the two pre-merge Charbonneau-Keith metadata rows.", call. = FALSE)
}

stock_row <- empty_rows(schemas$stocks, 1L)
stock_row$stock_id <- stock_id
stock_row$authority <- "ICES"
stock_row$authority_stock_id <- "ple.27.21-32"
stock_row$scientific_name <- "Pleuronectes platessa"
stock_row$common_name <- "Baltic plaice"
stock_row$area <- "Subdivisions 21-32 (Kattegat, Belt Seas, Sound, and Baltic Sea)"
stock_row$region <- "Baltic Sea"
stock_row$ocean <- "Northeast Atlantic"
stock_row$notes <- paste(
  "Merged ICES assessment unit introduced after the WKBPLAICE benchmark.",
  "The Charbonneau-Keith catalogue retains earlier 21-23 and 24-32 records;",
  "this stock row represents the combined current assessment area."
)

assessment_rows <- read_db("assessments.csv")
assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = run_version, is_current = TRUE, is_applied = TRUE,
  framework_year = 2025L, assessment_url = report_url,
  framework_url = "https://doi.org/10.17895/ices.pub.28400255",
  data_url = data_url, model_url = run_url, repository_url = "",
  assumptions_status = "partial", inputs_status = "complete", outputs_status = "partial",
  notes = "Inputs are from the public SAM run named WGBFAS_2026_SA. The canonical population summaries use WGBFAS 2026 report tables; the run's point estimates differ in recent years, and its configured Fbar ages (3-6) differ from the report definition (3-5). Those output differences are unresolved, so output completeness is partial. Age-specific uncertainty and forecast detail are not available in the canonical series.",
  stringsAsFactors = FALSE, check.names = FALSE
)

if (!identical(names(stock_row), schemas$stocks) ||
  !identical(names(assessment_row), schemas$assessments) ||
  !identical(names(assumptions), schemas$assumptions) ||
  !identical(names(inputs), schemas$inputs) ||
  !identical(names(outputs), schemas$outputs) ||
  nrow(inputs) == 0L || nrow(outputs) == 0L || nrow(assumptions) == 0L) {
  stop("Unexpected database schema or empty imported records.", call. = FALSE)
}

append_rows <- function(name, rows) {
  path <- file.path(database, name)
  header <- names(utils::read.csv(path, nrows = 0, colClasses = "character",
    na.strings = "", check.names = FALSE
  ))
  if (!identical(header, names(rows))) {
    stop("Unexpected column schema in ", name, ".", call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}

append_rows("stocks.csv", stock_row)
append_rows("assessments.csv", assessment_row)
append_rows("assumptions.csv", assumptions)
append_rows("inputs.csv", inputs)
append_rows("outputs.csv", outputs)

cat("Imported ICES Baltic plaice: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n", sep = "")
