# Import the detailed 2016 4X5Y haddock assessment and the 2024 summary update.

root <- "."
db <- file.path(root, "database")
cache_2016 <- file.path(root, "source_cache", "ck_dfo_aeglefinus_4x5y_2016")
cache_2024 <- file.path(root, "source_cache", "ck_dfo_aeglefinus_4x5y_2024")
assessment_id <- "dfo_haddock_4x5y_2016"
summary_id <- "dfo_haddock_4x5y_2024_summary"
abort <- function(...) stop(paste0(...), call. = FALSE)

assessment_file <- file.path(cache_2016, "assessment_2017_006.pdf")
framework_file <- file.path(cache_2016, "framework_vpa_2017_026.pdf")
summary_file <- file.path(cache_2024, "assessment_2025_047.pdf")
for (path in c(assessment_file, framework_file, summary_file)) {
  if (!file.exists(path)) abort("A required cached source is missing: ", path)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  abort("Install pdftools to extract the published tables.")
}

assessment_text <- pdftools::pdf_text(assessment_file)
framework_text <- pdftools::pdf_text(framework_file)
summary_text <- pdftools::pdf_text(summary_file)

parse_number <- function(token) {
  if (token %in% c("-", "–", "—")) return(NA_real_)
  token <- sub("\\*$", "", token)
  if (!grepl("^[0-9]+(,[0-9]{3})*(\\.[0-9]+)?$", token)) return(NA_real_)
  as.numeric(gsub(",", "", token, fixed = TRUE))
}

read_year_age_table <- function(text, pages, years, n_ages, label,
                                extra_columns = 0L) {
  lines <- trimws(unlist(strsplit(text[pages], "\\n")))
  lines <- lines[grepl("^(19|20)[0-9]{2}[[:space:]]+", lines)]
  lines <- lines[as.numeric(sub("^((19|20)[0-9]{2}).*", "\\1", lines)) %in% years]
  if (!identical(as.numeric(sub("^((19|20)[0-9]{2}).*", "\\1", lines)),
                 as.numeric(years))) {
    abort(label, " has unexpected year coverage.")
  }
  value <- matrix(NA_real_, nrow = length(years), ncol = n_ages,
                  dimnames = list(as.character(years), NULL))
  for (i in seq_along(lines)) {
    fields <- strsplit(lines[[i]], "[[:space:]]+")[[1]]
    if (length(fields) < 2L) abort("Malformed row in ", label, ": ", lines[[i]])
    tokens <- fields[seq.int(2L, min(length(fields), n_ages + 1L))]
    parsed <- vapply(tokens, parse_number, numeric(1))
    value[i, seq_along(parsed)] <- parsed
  }
  list(year = years, value = value)
}

long_inputs <- function(x, ages, type, measure, basis, unit,
                        fleet = "", survey = "", season = "",
                        year_basis = "calendar_year", sampling_time = NA_real_,
                        source_reference, notes = "", transformation = "") {
  grid <- expand.grid(year_row = seq_along(x$year), age_col = seq_along(ages))
  grid <- grid[order(grid$year_row, grid$age_col), , drop = FALSE]
  value <- as.vector(t(x$value))
  keep <- is.finite(value)
  grid <- grid[keep, , drop = FALSE]
  out <- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = "", region = "4X5Y",
    season = season, year = x$year[grid$year_row], year_basis = year_basis,
    age = ages[grid$age_col], value = value[keep], unit = unit,
    sampling_time = sampling_time, source_type = "official_table",
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = "", length_bin = "",
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE
  )
  out
}

empty_assumptions <- function(n) data.frame(
  assessment_id = rep(assessment_id, n), component = "", fleet = "",
  survey = "", sex = "", region = "4X5Y", season = "", setting = "",
  value = "", source_reference = "", notes = "", stringsAsFactors = FALSE
)
assumption <- function(component, setting, value, source_reference, notes = "") {
  out <- empty_assumptions(1L)
  out$component <- component
  out$setting <- setting
  out$value <- as.character(value)
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

empty_outputs <- function(n) data.frame(
  assessment_id = rep(assessment_id, n), type = "", measure = "",
  fleet = "", survey = "", sex = "", region = "4X5Y", season = "",
  year = NA_real_, age = NA_real_, age_group = "", value = NA_real_,
  se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = "",
  source_type = "official_table", source_reference = "", notes = "",
  stringsAsFactors = FALSE
)

add_age_outputs <- function(table, years, ages, type, measure, unit,
                            source_reference, notes = "") {
  grid <- expand.grid(year_row = seq_along(years), age_col = seq_along(ages))
  grid <- grid[order(grid$year_row, grid$age_col), , drop = FALSE]
  out <- empty_outputs(nrow(grid))
  out$type <- type
  out$measure <- measure
  out$year <- years[grid$year_row]
  out$age <- ages[grid$age_col]
  out$value <- as.vector(t(table$value))
  out$unit <- unit
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

model_years <- 1985:2015
all_years <- 1970:2015

# Assessment inputs
catch <- read_year_age_table(assessment_text, 18:19, all_years, 16,
                             "2017/006 Table 5")
catch_weight <- read_year_age_table(assessment_text, 20:21, all_years, 16,
                                    "2017/006 Table 6")
survey_index <- read_year_age_table(assessment_text, 23:24, all_years, 13,
                                    "2017/006 Table 8")
survey_weight <- read_year_age_table(assessment_text, 25:26, all_years, 15,
                                     "2017/006 Table 9")

# Table 8 prints the 2014 age-1 value with a misplaced comma; the 2016
# framework input table independently gives 168,470. The 2015 age-2 token
# "12,4322" is unresolved and remains absent from numeric records.
survey_index$value[2014 - 1970 + 1L, 1L] <- 168470
survey_index$value[2015 - 1970 + 1L, 2L] <- NA_real_

inputs <- list(
  long_inputs(catch, 1:16, "catch", "numbers_at_age", "numbers",
    "thousand fish", fleet = "Commercial fishery",
    source_reference = "DFO Research Document 2017/006, Table 5, pp. 13-15",
    notes = "Source age classes 1-16 retained. Ages 11-16 sum to the assessment's 11+ group when translated; the assessment fits 1985-2015."),
  long_inputs(catch_weight, 1:16, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg/fish", fleet = "Commercial fishery",
    source_reference = "DFO Research Document 2017/006, Table 6, pp. 15-17",
    notes = "Commercial mean weight-at-age; unavailable cells are omitted."),
  long_inputs(survey_index, 1:13, "index", "numbers_at_age", "index_scale",
    "thousand fish", survey = "DFO Summer RV", season = "summer",
    sampling_time = 0.5,
    source_reference = "DFO Research Document 2017/006, Table 8, pp. 18-20",
    notes = "Swept-area abundance index in thousands of fish. The source applies a 1.2 vessel/gear conversion for 1970-1981. Zeros are retained as published; the assessment treats zero index cells as missing. The 2015 age-2 cell is omitted because the printed token is malformed and unresolved.",
    transformation = "2014 age 1 transcribed as 168,470 from the matching 2016 framework input table (Research Document 2017/026, Table 8, pp. 25-26); 2015 age 2 omitted, not imputed."),
  long_inputs(survey_weight, 0:14, "weight", "weight_at_age", "kg_per_fish",
    "kg/fish", survey = "DFO Summer RV", season = "summer",
    source_reference = "DFO Research Document 2017/006, Table 9, pp. 21-23",
    notes = "Survey mean weight-at-age; source dashes are omitted." )
)
inputs <- do.call(rbind, inputs)

spawn_weight <- c(0.06, 0.16, 0.35, 0.56, 0.71, 0.84, 0.95, 1.01, 1.11, 1.20, 1.30)
maturity <- c(0, 0, 0, rep(1, 8))
static_biology <- function(measure, values, unit, notes) {
  out <- data.frame(
    assessment_id = assessment_id, type = if (measure == "maturity_at_age") "maturity" else "weight",
    measure = measure, basis = if (measure == "maturity_at_age") "proportion" else "kg_per_fish",
    fleet = "", survey = "", sex = "", region = "4X5Y", season = "",
    year = NA_real_, year_basis = "", age = 1:11, value = values,
    unit = unit, sampling_time = NA_real_, source_type = "official_table",
    source_reference = "DFO Research Document 2017/026, Table 15, p. 35",
    transformation = "", notes = notes, observation_id = "", length_bin = "",
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE
  )
  out
}
inputs <- rbind(
  inputs,
  static_biology("weight_at_age", spawn_weight, "kg/fish",
    "Spawning stock weight-at-age reported for per-recruit analysis, not as an annual VPA input."),
  static_biology("maturity_at_age", maturity, "proportion",
    "Maturity-at-age reported for per-recruit analysis, not an estimated VPA surface. The assessment reports age-4+ biomass.")
)

m_values <- matrix(0.2, nrow = length(model_years), ncol = 11,
                   dimnames = list(model_years, 1:11))
m_values[model_years >= 2000 & model_years <= 2004, 10:11] <- 0.3
m_values[model_years >= 2005 & model_years <= 2009, 10:11] <- 0.6
m_values[model_years >= 2010, 10:11] <- 0.9
m_input <- list(year = model_years, value = m_values)
inputs <- rbind(inputs, long_inputs(m_input, 1:11, "M",
  "natural_mortality_at_age", "per_year", "per year",
  source_reference = "DFO Research Document 2017/006, Table 13, p. 26",
  notes = "Fixed VPA input: M=0.2 except ages 10-11+ at 0.3 (2000-2004), 0.6 (2005-2009), and 0.9 (2010-2015)."))

assumptions <- do.call(rbind, list(
  assumption("assessment", "assessment_type", "Full assessment", "DFO Research Document 2017/006, cover"),
  assumption("model", "model_family", "ADAPT VPA", "DFO Research Document 2017/006, pp. 8-10"),
  assumption("model", "fitted_years", "1985-2015", "DFO Research Document 2017/006, pp. 8-10; Tables 5, 8, 12, 13"),
  assumption("model", "age_structure", "Ages 1-11+, with age 11+ as the plus group", "DFO Research Document 2017/026, pp. 14-16; DFO Research Document 2017/006, pp. 8-10"),
  assumption("catch", "catch_at_age", "Commercial fishery catch-at-age is supplied to the VPA; ages 11+ are pooled", "DFO Research Document 2017/006, Table 5; DFO Research Document 2017/026, pp. 14-16"),
  assumption("index", "survey_input", "DFO Summer RV swept-area abundance-at-age index; model ages 1-10, 1985-2015", "DFO Research Document 2017/006, pp. 8-10; Table 8"),
  assumption("index", "zero_observations", "Zero survey-index cells are treated as missing", "DFO Research Document 2017/006, pp. 8-10"),
  assumption("index", "catchability", "Age-specific q estimated for ages 1-10", "DFO Research Document 2017/006, Table 11, p. 24"),
  assumption("index", "timing", "Summer survey; exact within-year timing is not specified in the recovered assessment files", "DFO Research Document 2017/006, pp. 8-10", "The fraction 0.5 is a midyear timing approximation."),
  assumption("M", "natural_mortality", "Fixed at 0.2 except ages 10-11+ at 0.3, 0.6, and 0.9 in 2000-2004, 2005-2009, and 2010-2015", "DFO Research Document 2017/006, Table 13, p. 26"),
  assumption("F", "plus_group", "F11+ is set from F10 using a Fratio; the 1985-1994 ratio is 2 and later ratios follow the assessment formulation", "DFO Research Document 2017/006, pp. 8-10; DFO Research Document 2017/026, pp. 16-17"),
  assumption("population", "terminal_N", "Terminal-year population abundance is estimated for ages 2-11+; age 1 in 2016 is assigned as a geometric mean excluding the exceptional 2013 year class", "DFO Research Document 2017/006, Table 11, p. 24; Table 13, p. 26"),
  assumption("mortality", "Fbar", "Fbar is the reported population-number-weighted mean F for ages 6-10", "DFO Research Document 2017/006, Table 12, pp. 24-25"),
  assumption("biology", "per_recruit_inputs", "Table 15 maturity and spawning weights are per-recruit assumptions, not annual VPA state inputs", "DFO Research Document 2017/026, Table 15, p. 35"),
  assumption("data_quality", "survey_index_transcription", "2014 age-1 value corrected to 168,470 using the matching framework input table; 2015 age-2 value is unresolved and omitted", "DFO Research Document 2017/006, Table 8, pp. 18-20; DFO Research Document 2017/026, Table 8, pp. 25-26", "The 2017/006 table prints 16,8470 and 12,4322 respectively. Only the 2014 correction is independently confirmed."),
  assumption("model_availability", "native_run", "No applied ADAPT input file or native fitted object was located in the cached official documents or targeted source search", "DFO Research Documents 2017/006 and 2017/026; source search 2026-10-20"),
  assumption("model_availability", "output_uncertainty", "Approximate terminal parameter standard errors are reported; annual N/F uncertainty is not tabulated", "DFO Research Document 2017/006, Table 11, p. 24")
))

# Published assessment outputs
f_table <- read_year_age_table(assessment_text, 29, model_years, 12,
                               "2017/006 Table 12")
n_table <- read_year_age_table(assessment_text, 30:31, 1985:2016, 12,
                               "2017/006 Table 13")
f_age <- f_table$value[, 1:11, drop = FALSE]
fbar <- f_table$value[, 12]
n_age <- n_table$value[, 1:11, drop = FALSE]
ssb <- n_table$value[, 12]
if (anyNA(f_age) || anyNA(fbar) || anyNA(n_age) || anyNA(ssb)) {
  abort("A required numeric output cell did not parse: F=",
    paste(which(is.na(f_age), arr.ind = TRUE), collapse = ";"),
    "; Fbar=", paste(which(is.na(fbar)), collapse = ";"),
    "; N=", paste(which(is.na(n_age), arr.ind = TRUE), collapse = ";"),
    "; SSB=", paste(which(is.na(ssb)), collapse = ";"))
}

output_rows <- list(
  add_age_outputs(list(value = n_age), 1985:2016, 1:11, "population",
    "numbers_at_age", "thousand fish", "DFO Research Document 2017/006, Table 13, pp. 26-27",
    "Age 11 is the 11+ group. Age-1 abundance in 2016 was assigned from a geometric mean excluding the exceptional 2013 year class; no uncertainty is reported."),
  add_age_outputs(list(value = f_age), model_years, 1:11, "mortality",
    "fishing_mortality_at_age", "per year", "DFO Research Document 2017/006, Table 12, pp. 24-25",
    "Age 11 is the 11+ group; reported VPA fishing mortality." )
)

derived <- empty_outputs(length(1985:2016) * 3L + length(model_years) + 20L)
derived <- derived[0, , drop = FALSE]
add_aggregate <- function(type, measure, years, value, unit, source_reference,
                          notes, age_group = "", source_type = "derived_source_output") {
  out <- empty_outputs(length(years))
  out$type <- type
  out$measure <- measure
  out$year <- years
  out$value <- value
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- notes
  out$age_group <- age_group
  out
}
output_rows <- c(output_rows, list(
  add_aggregate("biomass", "SSB", 1985:2016, ssb, "t",
    "DFO Research Document 2017/006, Table 13, pp. 26-27",
    "Native assessment output labelled ages 4+ biomass; the report uses this as its SSB measure.", "4+", "official_table"),
  add_aggregate("population", "total_numbers", 1985:2016, rowSums(n_age), "thousand fish",
    "DFO Research Document 2017/006, Table 13, pp. 26-27",
    "Derived by summing the reported ages 1-11+ numbers-at-age in each year; uncertainty unavailable."),
  add_aggregate("population", "recruitment", 1985:2016, n_age[, 1], "thousand fish",
    "DFO Research Document 2017/006, Table 13, pp. 26-27",
    "Derived from same-year age-1 abundance; recruitment age is 1; uncertainty unavailable.", "age 1"),
  add_aggregate("mortality", "Fbar", model_years, fbar, "per year",
    "DFO Research Document 2017/006, Table 12, pp. 24-25",
    "Reported population-number-weighted mean F for ages 6-10.", "6-10", "official_table")
))

terminal_n <- c(73007, 191730, 23484, 11828, 9536, 2814, 777, 357, 1584, 498)
terminal_n_se <- c(46000, 76166, 8229, 3450, 3032, 754, 225, 117, 424, 94)
terminal_n_cv <- c(.630, .397, .350, .292, .318, .268, .289, .327, .268, .188)
terminal_n_bias <- c(15.12, 6.77, 5.16, 4.34, 3.46, 1.77, 3.72, 3.97, 2.21, 1.56)
terminal <- empty_outputs(10)
terminal$type <- "population"
terminal$measure <- "terminal_parameter_numbers_at_age"
terminal$year <- 2016
terminal$age <- 2:11
terminal$value <- terminal_n
terminal$se <- terminal_n_se
terminal$unit <- "fish"
terminal$source_reference <- "DFO Research Document 2017/006, Table 11, p. 24"
terminal$notes <- paste0(
  "Bias-corrected terminal N parameter estimate, distinct from Table 13 population N-at-age; approximate linearized SE on natural scale; CV=",
  terminal_n_cv, "; bias=", terminal_n_bias, "%.")
q <- empty_outputs(10)
q$type <- "catchability"
q$measure <- "q"
q$age <- 1:10
q$value <- c(.495, .769, .910, 1.089, 1.038, 1.004, 1.073, 1.100, 1.006, 1.080)
q$se <- c(.055, .081, .094, .110, .106, .103, .112, .122, .110, .116)
q$unit <- "relative catchability"
q$source_reference <- "DFO Research Document 2017/006, Table 11, p. 24"
q$notes <- "Age-specific catchability estimate and approximate linearized SE on natural scale."
output_rows <- do.call(rbind, c(output_rows, list(terminal, q)))

new_assessments <- data.frame(
  assessment_id = c(assessment_id, summary_id),
  stock_id = "ck_dfo_aeglefinus_4x5y",
  assessment_year = c(2016, 2024), terminal_year = c(2015, 2022),
  estimate_terminal_year = c(2016, 2022),
  assessment_type = c("full", "summary_update"),
  model_family = c("ADAPT VPA", ""),
  model_version = c("", ""), is_current = c("TRUE", "FALSE"),
  is_applied = c("TRUE", "TRUE"), framework_year = c(2016, 2024),
  assessment_url = c(
    "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40722697.pdf",
    "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41306132.pdf"),
  framework_url = c(
    "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40613215.pdf",
    "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41306430.pdf"),
  data_url = c("", "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290562.pdf"),
  model_url = c("", ""), repository_url = c("", ""),
  assumptions_status = c("partial", "partial"),
  inputs_status = c("partial", "partial"),
  outputs_status = c("partial", "partial"),
  notes = c(
    "Most recent detailed production assessment recovered. Tables provide the fitted 1985-2015 inputs and major outputs; the applied ADAPT native run, one malformed survey index cell, and annual output uncertainty remain unavailable.",
    "The 2024 advice used updated survey information and a management procedure. The only numeric model-based population output recovered here is 2022 SSB=33,531 mt, cited from a 2022 model run; it is not combined with the 2016 VPA inputs or outputs. Framework data/model documents describe later framework work, not a complete applied annual output series."),
  stringsAsFactors = FALSE
)

summary_output <- data.frame(
  assessment_id = summary_id, type = "biomass", measure = "SSB",
  fleet = "", survey = "", sex = "", region = "4X5Y", season = "",
  year = 2022, age = NA_real_, age_group = "", value = 33531,
  se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = "t",
  source_type = "official_document",
  source_reference = "DFO Science Advisory Report 2025/047, p. 3",
  notes = "Model-based SSB estimate from the most recent model run in 2022, attributed in the report to Barrett et al. in press; no uncertainty or full annual output table is provided.",
  stringsAsFactors = FALSE
)

assumptions <- rbind(assumptions, data.frame(
  assessment_id = summary_id, component = "model_availability", fleet = "",
  survey = "", sex = "", region = "4X5Y", season = "",
  setting = "2024_summary_only", value = "one SSB value for 2022",
  source_reference = "DFO Science Advisory Report 2025/047, p. 3",
  notes = "The 2024 assessment summary cites 2022 model-based SSB but does not provide the complete numerical assessment inputs, assumptions, or age-specific outputs needed for a separate translation.",
  stringsAsFactors = FALSE
))

read_csv <- function(name) read.csv(file.path(db, name), stringsAsFactors = FALSE,
                                    check.names = FALSE)
replace_assessment_rows <- function(name, ids, new_rows) {
  path <- file.path(db, name)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  pattern <- paste0('^"?(', paste(ids, collapse = "|"), ')"?,')
  lines <- c(lines[1L], lines[-1L][!grepl(pattern, lines[-1L])])
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  write.csv(new_rows, tmp, row.names = FALSE, na = "")
  appended <- readLines(tmp, warn = FALSE, encoding = "UTF-8")[-1L]
  writeLines(c(lines, appended), path, useBytes = TRUE)
}

stocks <- read_csv("stocks.csv")
stock_i <- which(stocks$stock_id == "ck_dfo_aeglefinus_4x5y")
if (length(stock_i) != 1L) abort("Expected one Charbonneau-Keith 4X5Y stock row.")
stocks$authority_stock_id[stock_i] <- "4X5Y"
stocks$common_name[stock_i] <- "Haddock"
stocks$notes[stock_i] <- paste(
  "DFO 4X5Y haddock; latest detailed production assessment is the 2016 ADAPT VPA.",
  "A 2024 summary-only assessment is recorded separately.",
  "Charbonneau-Keith Master.csv identifier DFO_aeglefinus_4X5Y retained."
)
stock_path <- file.path(db, "stocks.csv")
stock_lines <- readLines(stock_path, warn = FALSE, encoding = "UTF-8")
stock_pattern <- paste0('^"?ck_dfo_aeglefinus_4x5y"?,')
stock_line_i <- grep(stock_pattern, stock_lines)
if (length(stock_line_i) != 1L) abort("Expected one existing haddock stock CSV row.")
tmp <- tempfile(fileext = ".csv")
write.csv(stocks[stock_i, , drop = FALSE], tmp, row.names = FALSE, na = "")
stock_lines[stock_line_i] <- readLines(tmp, warn = FALSE, encoding = "UTF-8")[[2L]]
unlink(tmp)
writeLines(stock_lines, stock_path, useBytes = TRUE)

replace_assessment_rows("assessments.csv", c(assessment_id, summary_id), new_assessments)
replace_assessment_rows("assumptions.csv", c(assessment_id, summary_id), assumptions)
replace_assessment_rows("inputs.csv", assessment_id, inputs)
replace_assessment_rows("outputs.csv", c(assessment_id, summary_id),
                        rbind(output_rows, summary_output))

cat("Imported ", nrow(inputs), " 2016-assessment inputs and ",
    nrow(output_rows), " 2016-assessment outputs; added one 2024 summary output.\n", sep = "")
