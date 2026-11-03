root <- "."
cache <- file.path(root, "source_cache", "ck_ices_afwg_aeglefinus_nea_1_2", "assessment_2026")
assessment_id <- "jrn_afwg_haddock_northeast_arctic_2026"
stock_id <- "ck_ices_afwg_aeglefinus_nea_1_2"
report <- "JRN-AFWG Report 2026, section 4: Haddock in subareas 1 and 2"
report_url <- "https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5"
case_url <- "https://www.stockassessment.org/datadisk/stockassessment/userdirs/user3/NEAHaddock2026/"

paths <- setNames(
  file.path(root, "database", paste0(c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_cache <- function(name) file.path(cache, name)
read_native <- function(name) {
  if (!file.exists(read_cache(name))) stop("Missing cached source file: ", read_cache(name), call. = FALSE)
  read_cache(name)
}
load_objects <- function(path) {
  env <- new.env(parent = emptyenv())
  load(path, envir = env)
  env
}

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to rerun this native-object importer.", call. = FALSE)
}
model_env <- load_objects(read_native("run_model.RData"))
data_env <- load_objects(read_native("run_data.RData"))
fit <- model_env$fit
dat <- data_env$dat
cnW <- data_env$cnW
cnWO <- data_env$cnWO
if (is.null(fit) || is.null(dat) || is.null(cnW) || is.null(cnWO)) {
  stop("The cached JRN-AFWG files do not contain the expected SAM objects.", call. = FALSE)
}
if (assessment_id %in% read_db("assessments")$assessment_id) {
  stop("The JRN-AFWG haddock assessment is already imported.", call. = FALSE)
}

years <- as.integer(fit$data$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
input_years <- 1950:2025
fleet_names <- attr(fit$data, "fleetNames")
sample_times <- as.numeric(fit$data$sampleTimes)
if (!identical(years, 1950:2026) || !identical(ages, 3:13) ||
  length(fleet_names) != 5L || length(sample_times) != 5L ||
  any(is.infinite(fit$data$logobs)) || !any(is.finite(fit$data$logobs))) {
  stop("The cached fit does not match the reviewed 1950-2026, ages 3-13 model.", call. = FALSE)
}

as_surface <- function(x, years, ages) {
  if (length(dim(x)) == 3L) {
    x <- x[, , 1L]
  }
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("A cached model surface has unexpected dimensions.", call. = FALSE)
  }
  x
}
input_row <- function(type, measure, basis, year, age, value, unit,
                      fleet = "", survey = "", season = "", sampling_time = NA_real_,
                      source_type = "native_model", source_reference,
                      transformation = "", notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = rep(fleet, length.out = n), survey = rep(survey, length.out = n),
    sex = "combined", region = "Northeast Arctic", season = rep(season, length.out = n),
    year = year, year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
    value = value, unit = unit, sampling_time = rep(sampling_time, length.out = n),
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = NA_real_, stringsAsFactors = FALSE
  )
}
surface_rows <- function(type, measure, basis, x, years, ages, unit,
                         source_reference, fleet = "", notes = "",
                         transformation = "", source_type = "native_model") {
  x <- as_surface(x, years, ages)
  grid <- expand.grid(year = years, age = ages)
  input_row(type, measure, basis, grid$year, grid$age, as.vector(x), unit,
    fleet = fleet, source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes)
}

catch_rows <- function(x, fleet, measure, source_reference, notes) {
  if (!identical(dim(x), c(length(input_years), length(ages)))) {
    stop("Catch-at-age input has unexpected dimensions.", call. = FALSE)
  }
  grid <- expand.grid(year = input_years, age = ages)
  input_row("catch", measure, "numbers", grid$year, grid$age, as.vector(x),
    "thousand fish", fleet = fleet, source_reference = source_reference,
    notes = notes)
}

inputs_add <- list(
  catch_rows(cnWO, "Residual catch", "numbers_at_age",
    "run_data.RData: cnWO; supplied as residual.fleet to setup.sam.data",
    "Residual catch series used in the final SAM likelihood. Cod-consumption removals are represented through the separate fixed M surface."),
  catch_rows(cnW, "Total catch for M reconstruction", "numbers_at_age_for_M_reconstruction",
    "run_data.RData: cnW; JRN-AFWG Report 2026, Table 4.4",
    "Total catch-at-age retained as a source input to the cod-predation M reconstruction; not a second catch likelihood."),
  surface_rows("catch_weight", "weight_at_age", "kg_per_fish",
    fit$data$catchMeanWeight, input_years, ages, "kg per fish",
    "run_data.RData: dat$catchMeanWeight; JRN-AFWG Report 2026, Table 4.5",
    fleet = "Total catch", notes = "Annual catch weight-at-age supplied to the final SAM data object."),
  surface_rows("biology", "discard_weight_at_age", "kg_per_fish",
    fit$data$disMeanWeight, input_years, ages, "kg per fish",
    "run_data.RData: dat$disMeanWeight",
    fleet = "Total catch", notes = "Annual discard weight-at-age supplied to the final SAM data object."),
  surface_rows("biology", "landings_weight_at_age", "kg_per_fish",
    fit$data$landMeanWeight, input_years, ages, "kg per fish",
    "run_data.RData: dat$landMeanWeight",
    fleet = "Total catch", notes = "Annual landings weight-at-age supplied to the final SAM data object."),
  surface_rows("biology", "landings_fraction_at_age", "proportion",
    fit$data$landFrac, input_years, ages, "proportion",
    "run_data.RData: dat$landFrac",
    fleet = "Total catch", notes = "Annual landings fractions supplied to the final SAM data object."),
  surface_rows("weight", "weight_at_age", "kg_per_fish",
    fit$data$stockMeanWeight, years, ages, "kg per fish",
    "run_model.RData: fit$data$stockMeanWeight; JRN-AFWG Report 2026, Table 4.6",
    notes = "Beginning-of-year stock weights; ages 12 and older retain distinct values, with age 13 as the plus group."),
  surface_rows("maturity", "maturity_at_age", "proportion",
    fit$data$propMat, years, ages, "proportion mature",
    "run_model.RData: fit$data$propMat; JRN-AFWG Report 2026, Table 4.7",
    notes = "Beginning-of-year smoothed maturity-at-age."),
  surface_rows("M", "natural_mortality_at_age", "per_year",
    fit$data$natMor, years, ages, "per year",
    "run_model.RData: fit$data$natMor; JRN-AFWG Report 2026, Table 4.14",
    notes = "Fixed in the final SAM fit. Ages 3-6 include externally reconstructed cod-predation mortality; ages 7-13+ are 0.2."),
  surface_rows("biology", "fraction_F_before_spawning", "proportion",
    fit$data$propF, years, ages, "proportion",
    "run_model.RData: fit$data$propF; JRN-AFWG Report 2026, section 4.4.5",
    notes = "All supplied values are zero."),
  surface_rows("biology", "fraction_M_before_spawning", "proportion",
    fit$data$propM, years, ages, "proportion",
    "run_model.RData: fit$data$propM; JRN-AFWG Report 2026, section 4.4.5",
    notes = "All supplied values are zero.")
)

aux <- as.data.frame(fit$data$aux)
names(aux) <- c("year", "fleet_id", "age")
aux$value <- exp(fit$data$logobs)
aux <- aux[is.finite(aux$value), , drop = FALSE]
aux$survey <- fleet_names[aux$fleet_id]
aux$sampling_time <- sample_times[aux$fleet_id]
aux$season <- ifelse(aux$fleet_id == 2L, "Q4",
  ifelse(aux$fleet_id %in% c(3L, 4L), "Q1", ifelse(aux$fleet_id == 5L, "Q3", "")))
aux$max_age <- fit$data$maxAgePerFleet[aux$fleet_id]
aux <- aux[aux$fleet_id > 1L, , drop = FALSE]
aux$measure <- ifelse(aux$age == aux$max_age, "index_by_age_group", "numbers_at_age")
aux$notes <- ifelse(aux$measure == "index_by_age_group",
  paste0("Native terminal age group is ", aux$age, "+; retained for provenance and not translated as a single-age index."),
  "Native age-specific index value; the physical scale multiplier is not stated in the assessment table.")
index_add <- input_row(
  "index", aux$measure, "index_scale", aux$year, aux$age, aux$value,
  "survey index (unit unresolved)", survey = aux$survey, season = aux$season,
  sampling_time = aux$sampling_time, source_reference = "run_model.RData: fit$data$aux and fit$data$logobs; JRN-AFWG Report 2026, Table 4.9",
  transformation = "exp(logobs)", notes = aux$notes
)
inputs_add[[length(inputs_add) + 1L]] <- index_add
inputs_add <- do.call(rbind, inputs_add)

read_report_table <- function(title, next_title, expected_years, n_values) {
  lines <- readLines(read_native("report_text.txt"), warn = FALSE)
  start <- grep(paste0("^", title), lines)[1L]
  end <- grep(paste0("^", next_title), lines)[1L]
  if (is.na(start) || is.na(end) || end <= start) {
    stop("Could not locate report table: ", title, call. = FALSE)
  }
  block <- trimws(lines[seq.int(start + 1L, end - 1L)])
  numeric_value <- suppressWarnings(as.numeric(block))
  year_positions <- integer(length(expected_years))
  year_positions[[1L]] <- which(numeric_value == expected_years[[1L]])[1L]
  for (i in seq_len(length(expected_years) - 1L)) {
    candidates <- which(numeric_value == expected_years[[i + 1L]] &
      seq_along(block) > year_positions[[i]])
    valid <- candidates[vapply(candidates, function(candidate) {
      sum(is.finite(numeric_value[seq.int(year_positions[[i]] + 1L, candidate - 1L)])) == n_values
    }, logical(1))]
    if (length(valid)) year_positions[[i + 1L]] <- valid[[1L]]
  }
  if (anyNA(year_positions) || any(year_positions == 0L)) {
    stop("Unexpected years in report table: ", title, call. = FALSE)
  }
  result <- matrix(NA_real_, nrow = length(expected_years), ncol = n_values)
  for (i in seq_along(year_positions)) {
    first <- year_positions[[i]]
    last <- if (i < length(year_positions)) year_positions[[i + 1L]] - 1L else length(block)
    values <- suppressWarnings(as.numeric(block[seq.int(first + 1L, last)]))
    values <- values[is.finite(values)]
    if (length(values) == n_values) {
      result[i, ] <- values
    } else if (length(values) == n_values - 3L && expected_years[[i]] == 2026L) {
      result[i, ] <- c(values[1:6], rep(NA_real_, 3L), values[7:9])
    } else {
      stop("Unexpected number of table values in ", title, " for year ", expected_years[[i]], call. = FALSE)
    }
  }
  result
}

summary_table <- read_report_table(
  "Table 4.11. Northeast Arctic haddock", "Table 4.12. Northeast Arctic haddock",
  years, 12L
)
f_table <- read_report_table(
  "Table 4.12. Northeast Arctic haddock", "Table 4.13. Northeast Arctic haddock",
  input_years, length(ages)
)
n_table <- read_report_table(
  "Table 4.13. Northeast Arctic haddock", "Table 4.14. Northeast Arctic haddock",
  years, length(ages)
)
m_table <- read_report_table(
  "Table 4.14. Northeast Arctic haddock", "Table 4.15. Northeast Arctic haddock",
  input_years, length(ages)
)

N_native <- stockassessment::ntable(fit)
F_native <- stockassessment::faytable(fit)
M_native <- fit$data$natMor
if (max(abs(round(N_native) - n_table)) > 1 ||
  max(abs(round(F_native[as.character(input_years), , drop = FALSE], 3) - f_table)) > 0.001 ||
  max(abs(round(M_native[seq_along(input_years), , drop = FALSE], 3) - m_table)) > 0.001) {
  stop("Published age-specific tables do not agree with the saved final SAM fit.", call. = FALSE)
}
weights <- as_surface(fit$data$stockMeanWeight, years, ages)
maturity <- as_surface(fit$data$propMat, years, ages)
derived_ssb <- rowSums(N_native * weights * maturity)
derived_tsb <- rowSums(N_native * weights)
derived_fbar <- rowMeans(F_native[, as.character(4:7), drop = FALSE])
if (max(abs(round(derived_ssb) - summary_table[, 4L]), na.rm = TRUE) > 1 ||
  max(abs(round(derived_tsb) - summary_table[, 10L]), na.rm = TRUE) > 1 ||
  max(abs(round(derived_fbar[seq_along(input_years)], 3) - summary_table[seq_along(input_years), 7L]), na.rm = TRUE) > 0.001) {
  stop("Derived aggregate outputs do not agree with report Table 4.11.", call. = FALSE)
}

output_row <- function(type, measure, year, age = NA_real_, age_group = "",
                       value, unit, source_reference, notes = "",
                       lwr = NA_real_, upr = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "combined", region = "Northeast Arctic", season = "",
    year = year, age = age, age_group = age_group, value = value, se = NA_real_,
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE
  )
}
age_outputs <- function(measure, values, output_years, unit, table, notes) {
  grid <- expand.grid(year = output_years, age = ages)
  output_row(
    if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age,
    age_group = ifelse(grid$age == max(ages), paste0(max(ages), "+"), ""),
    value = as.vector(values), unit = unit,
    source_reference = paste(report, table), notes = notes
  )
}
outputs_add <- rbind(
  age_outputs("numbers_at_age", n_table, years, "thousand fish", "Table 4.13",
    "Published SAM stock numbers-at-age; age 13 is the 13+ group. No age-specific uncertainty is tabulated."),
  age_outputs("fishing_mortality_at_age", f_table, input_years, "per year", "Table 4.12",
    "Published SAM fishing mortality-at-age; age 13 is the 13+ group. No age-specific uncertainty is tabulated."),
  age_outputs("natural_mortality_at_age", m_table, input_years, "per year", "Table 4.14",
    "M was fixed in the final SAM fit from the externally reconstructed cod-predation surface; equality with the input table does not represent an estimated M process."),
  output_row("recruitment", "recruitment", years, age = 3,
    value = summary_table[, 1L], unit = "thousand fish",
    source_reference = paste(report, "Table 4.11"),
    notes = "Recruitment at age 3. Published Low/High bounds retained; interval coverage is not specified.",
    lwr = summary_table[, 2L], upr = summary_table[, 3L]),
  output_row("biomass", "SSB", years, value = summary_table[, 4L], unit = "tonnes",
    source_reference = paste(report, "Table 4.11"),
    notes = "Published spawning-stock biomass. Low/High bounds retained as printed; interval coverage is not specified.",
    lwr = summary_table[, 5L], upr = summary_table[, 6L]),
  output_row("mortality", "Fbar", input_years, age_group = "4-7",
    value = summary_table[seq_along(input_years), 7L], unit = "per year",
    source_reference = paste(report, "Table 4.11"),
    notes = "Average fishing mortality for ages 4-7. Published Low/High bounds retained; interval coverage is not specified.",
    lwr = summary_table[seq_along(input_years), 8L], upr = summary_table[seq_along(input_years), 9L]),
  output_row("biomass", "total_biomass", years, value = summary_table[, 10L], unit = "tonnes",
    source_reference = paste(report, "Table 4.11"),
    notes = "Published total stock biomass for ages 3+; Low/High bounds retained as printed, with coverage unspecified.",
    lwr = summary_table[, 11L], upr = summary_table[, 12L])
)

assumption <- function(component, setting, value, source_reference, notes = "",
                       fleet = "", survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = "combined", region = "Northeast Arctic", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
assumptions_add <- rbind(
  assumption("assessment", "authority", "JRN-AFWG (IMR/VNIRO), outside ICES", report_url),
  assumption("assessment", "model_family", "SAM age-structured state-space model", "run_model.RData: fit"),
  assumption("assessment", "model_version", "stockassessment 0.12.0; RemoteSha 1cc464b80f6f", "run_model.RData: fit"),
  assumption("population", "age_structure", "Ages 3-13; age 13 is the plus group", "conf_model.cfg: minAge/maxAge/maxAgePlusGroup"),
  assumption("population", "years", "Model estimates 1950-2026; catch ends in 2025", "run_model.RData: fit$data$years"),
  assumption("recruitment", "process", "Age-3 recruitment random walk; stockRecruitmentModelCode = 0", "conf_model.cfg: stockRecruitmentModelCode"),
  assumption("N", "process", "Age-structured survival states with innovation variance shared for ages 4-13 and separate at age 3", "conf_model.cfg: keyVarLogN"),
  assumption("N", "initial_state", "Initial abundance states have no separate process density", "conf_model.cfg and JRN-AFWG Report 2026 SAM configuration"),
  assumption("F", "process", "Log-F random-walk innovations with AR(1) correlation across age; ages 3-7 have separate states and ages 8-13 share the age-8 state", "conf_model.cfg: keyLogFsta/corFlag"),
  assumption("F", "process_sd_groups", "Age 3 has a separate innovation SD; ages 4-13 share one SD", "conf_model.cfg: keyVarF"),
  assumption("F", "Fbar_ages", "4-7", "conf_model.cfg: fbarRange"),
  assumption("M", "natural_mortality", "Fixed 0.2 plus cod-predation mortality at ages 3-6; ages 7-13+ fixed at 0.2", "JRN-AFWG Report 2026, sections 4.4.5 and 4.6; Table 4.14"),
  assumption("M", "predation_period", "Direct predation estimates for 1984-2025; 1950-1983 use the 1984-2025 age-specific average; 2026 copies 2025", "src_model.R and run_model.RData: fit$data$natMor", "The report states the historical average period and the final saved surface is authoritative."),
  assumption("catch", "observation", "Residual catch-at-age is the single fitted catch fleet; total catch-at-age is kept separately as an input to M reconstruction", "src_datascript.R; run_data.RData: cnW/cnWO"),
  assumption("catch", "likelihood", "Lognormal observations; no source observation weights are supplied in fit$data$weight", "conf_model.cfg: obsLikelihoodFlag/fixVarToWeight; run_model.RData: fit$data$weight"),
  assumption("index", "observation_model", "Lognormal index observations; index residuals use AR(1) correlation across ages", "conf_model.cfg: obsLikelihoodFlag/obsCorStruct"),
  assumption("index", "catchability", "Survey- and age-group-specific catchability, with six density-dependent q-power parameters", "conf_model.cfg: keyLogFpar/keyQpow"),
  assumption("index", "index_scale", "Native age-specific values retained; the physical scale multiplier is not stated", "JRN-AFWG Report 2026, Table 4.9", "The saved SAM object preserves the exact observed scale."),
  assumption("index", "reported_prior_weight", "Table 4.9 lists prior weight 1 for each survey", "JRN-AFWG Report 2026, section 4.4.6, Table 4.9", "The saved SAM observation weight vector is entirely missing; no explicit weights were used by the final fit."),
  assumption("index", "sampling_time", "RU-BTr-Q4 0.95; Q1 acoustic and bottom-trawl surveys 0.133; ecosystem Q3 survey 0.7", "run_model.RData: fit$data$sampleTimes"),
  assumption("biology", "spawning_timing", "Proportion of F and M before spawning is zero", "JRN-AFWG Report 2026, section 4.4.5; run_model.RData: fit$data$propF/propM"),
  assumption("weight", "stock_weight", "Smoothed beginning-of-year stock weight-at-age", "JRN-AFWG Report 2026, section 4.4.3, Table 4.6"),
  assumption("maturity", "maturity", "Smoothed maturity-at-age at the beginning of the year", "JRN-AFWG Report 2026, section 4.4.4, Table 4.7"),
  assumption("index", "observation_age_groups", "The last age group is a plus group for each survey", "JRN-AFWG Report 2026, section 4.4.6, Table 4.9")
)

stocks <- read_db("stocks")
stock_match <- which(stocks$stock_id == stock_id)
if (length(stock_match) != 1L) stop("Expected one Charbonneau–Keith metadata row for Northeast Arctic haddock.", call. = FALSE)
stock_add <- stocks[stock_match, , drop = FALSE]
stock_add$authority <- "JRN-AFWG"
stock_add$authority_stock_id <- "had.27.1-2"
stock_add$scientific_name <- "Melanogrammus aeglefinus"
stock_add$common_name <- "Northeast Arctic haddock"
stock_add$area <- "ICES subareas 1 and 2"
stock_add$region <- "Barents Sea and Norwegian Sea"
stock_add$ocean <- "Northeast Atlantic"
stock_add$notes <- paste(
  stock_add$notes,
  "Current production assessment is conducted by JRN-AFWG; the Charbonneau–Keith identifier is retained."
)
stocks[stock_match, ] <- stock_add
assessment_add <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026,
  terminal_year = 2026, estimate_terminal_year = 2026,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = "stockassessment 0.12.0 (RemoteSha 1cc464b80f6f)",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = report_url, framework_url = "", data_url = paste0(case_url, "data/"),
  model_url = paste0(case_url, "run/model.RData"), repository_url = "",
  assumptions_status = "partial", inputs_status = "complete", outputs_status = "partial",
  notes = paste("Current detailed JRN-AFWG production run. Survey index physical units are unresolved.",
    "Published aggregate Low/High bounds do not state interval coverage; q outputs and some derived model reports are not included."),
  stringsAsFactors = FALSE
)

append_rows <- function(name, rows) {
  existing <- read_db(name)
  if (!setequal(names(rows), names(existing))) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  write.table(rows[names(existing)], paths[[name]], sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
replace_stock_record <- function(path, row_index, row, stock_id) {
  row[] <- lapply(row, function(value) {
    if (is.character(value)) chartr("\r\n", "  ", value) else value
  })
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, na = "")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  replacement <- replacement[seq_len(length(replacement) - 1L)]
  if (tail(replacement, 1L) == as.raw(13L)) {
    replacement <- replacement[-length(replacement)]
  }

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  original <- readBin(con, "raw", n = file.info(path)$size)
  bytes <- as.integer(original)
  spans <- list()
  start <- 1L
  quoted <- FALSE
  i <- 1L
  while (i <= length(bytes)) {
    if (bytes[[i]] == 34L) {
      if (quoted && i < length(bytes) && bytes[[i + 1L]] == 34L) {
        i <- i + 1L
      } else {
        quoted <- !quoted
      }
    } else if (bytes[[i]] == 10L && !quoted) {
      end <- i - 1L
      if (end >= start && bytes[[end]] == 13L) end <- end - 1L
      spans[[length(spans) + 1L]] <- c(start, end)
      start <- i + 1L
    }
    i <- i + 1L
  }
  if (start <= length(bytes)) spans[[length(spans) + 1L]] <- c(start, length(bytes))

  span <- spans[[row_index + 1L]]
  existing_id <- read.csv(text = rawToChar(original[seq.int(span[[1L]], span[[2L]])]),
    header = FALSE, stringsAsFactors = FALSE, check.names = FALSE)[[1L]][[1L]]
  if (!identical(existing_id, stock_id)) stop("Stock row order changed; refusing to update stocks.csv.", call. = FALSE)
  updated <- c(
    original[seq_len(span[[1L]] - 1L)], replacement,
    original[seq.int(span[[2L]] + 1L, length(original))]
  )
  writeBin(updated, path)
}
if (anyDuplicated(inputs_add[c("assessment_id", "type", "measure", "fleet", "survey", "year", "age")]) ||
  anyDuplicated(outputs_add[c("assessment_id", "type", "measure", "year", "age", "age_group")])) {
  stop("The imported input or output keys are duplicated.", call. = FALSE)
}
if (!all(is.finite(inputs_add$value)) || !all(is.finite(outputs_add$value)) ||
  any(inputs_add$sampling_time < 0 | inputs_add$sampling_time > 1, na.rm = TRUE)) {
  stop("The imported source values failed finite-value or sampling-time checks.", call. = FALSE)
}
replace_stock_record(paths[["stocks"]], stock_match, stock_add, stock_id)
append_rows("assessments", assessment_add)
append_rows("assumptions", assumptions_add)
append_rows("inputs", inputs_add)
append_rows("outputs", outputs_add)
cat("Imported ", assessment_id, ": ", nrow(inputs_add), " inputs and ",
  nrow(outputs_add), " outputs.\n", sep = "")
