root <- "."
.libPaths(c(file.path(root, "source_cache", "r-library"), .libPaths()))
stock_id <- "nafo_american_plaice_3lno"
historical_id <- "nafo_american_plaice_3lno_2021"
monitoring_id <- "nafo_american_plaice_3lno_2026_monitoring"
candidate_id <- "NAFO:american_plaice.3LNO"

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
  qmethod = "double")
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

add_input <- function(id, type, measure, basis, value, unit,
  year = NA_integer_, age = NA_real_, fleet = "", survey = "",
  region = "NAFO Divisions 3LNO", season = "", source_reference,
  transformation = "", notes = "") data.frame(
    assessment_id = id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = region, season = season,
    year = if (!is.na(year)) as.integer(year) else NA_integer_,
    year_basis = if (!is.na(year)) "calendar_year" else "", age = age,
    value = value, unit = unit, sampling_time = NA_real_,
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = NA_character_, length_bin = NA_character_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = NA_character_, partition = NA_character_,
    stringsAsFactors = FALSE
  )

add_assumption <- function(id, component, setting, value, source_reference, notes = "") data.frame(
  assessment_id = id, component = component, fleet = "", survey = "",
  sex = "", region = "NAFO Divisions 3LNO", season = "", setting = setting,
  value = as.character(value), source_reference = source_reference, notes = notes,
  stringsAsFactors = FALSE
)

add_output <- function(id, type, measure, value, unit, year = NA_integer_,
  age = NA_real_, se = NA_real_, source_reference, notes = "") data.frame(
    assessment_id = id, type = type, measure = measure, fleet = "", survey = "",
    sex = "", region = "NAFO Divisions 3LNO", season = "",
    year = if (!is.na(year)) as.integer(year) else NA_integer_, age = age,
    age_group = "", value = value, se = se, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )

# Detailed 2021 full assessment
pdf_path <- file.path(root, "source_cache", "nafo_american_plaice_3lno_2021", "nafo_scr21_035_american_plaice_3lno.pdf")
if (!requireNamespace("pdftools", quietly = TRUE) || !file.exists(pdf_path)) stop("Install pdftools and cache SCR 21/035 before importing.", call. = FALSE)
pages <- pdftools::pdf_text(pdf_path)
table_lines <- unlist(strsplit(paste(pages[33:39], collapse = "\n"), "\n", fixed = TRUE), use.names = FALSE)
section <- function(number) {
  starts <- vapply(23:29, function(n) grep(paste0("Table ", n, "\\."), table_lines)[1], integer(1))
  i <- match(number, 23:29)
  if (is.na(starts[i])) stop("Table ", number, " was not found in the source pages.", call. = FALSE)
  end <- if (i < length(starts)) starts[i + 1L] - 1L else length(table_lines)
  table_lines[starts[i]:end]
}
parse_age_table <- function(number, years, n_ages, decimal = NA_real_) {
  lines <- section(number)
  row_pattern <- "^\\s*(19[0-9]{2}|20[0-9]{2})(?:\\.([0-9]+))?\\s+(.+)$"
  matches <- regexec(row_pattern, lines, perl = TRUE)
  parsed <- regmatches(lines, matches)
  out <- list()
  for (row in parsed) {
    if (!length(row)) next
    year_value <- as.numeric(row[[2L]])
    year <- as.integer(floor(year_value))
    fraction <- if (nzchar(row[[3L]])) as.numeric(paste0("0.", row[[3L]])) else 0
    if (!year %in% years || (!is.na(decimal) && abs(fraction - decimal) > 0.001)) next
    values <- suppressWarnings(as.numeric(gsub(",", "", strsplit(trimws(row[[4L]]), "\\s+")[[1]], fixed = TRUE)))
    if (length(values) != n_ages || anyNA(values) || any(!is.finite(values))) stop("Table ", number, " has an unreadable row for ", year_value, ".", call. = FALSE)
    out[[as.character(year)]] <- values
  }
  if (length(out) != length(years) || !all(as.character(years) %in% names(out))) stop("Table ", number, " does not contain the expected year coverage.", call. = FALSE)
  do.call(rbind, out[as.character(years)])
}

catch_years <- 1960:2020
weight_years <- 1960:2021
maturity_years <- 1960:2025
fall_years <- setdiff(1990:2020, c(2004, 2014))
spring_years <- setdiff(1985:2019, c(2006, 2015, 2017))
spain_years <- 1998:2019
catch_age <- parse_age_table(23, catch_years, 11L)
stock_weight <- parse_age_table(24, weight_years, 11L)
maturity <- parse_age_table(25, maturity_years, 11L)
fall_index <- parse_age_table(26, fall_years, 10L, decimal = 0.9)
spring_index <- parse_age_table(27, spring_years, 10L, decimal = 0.5)
spain_index <- parse_age_table(28, spain_years, 10L, decimal = 0.5)

inputs <- list()
for (year in catch_years) for (age in 5:15) inputs[[length(inputs) + 1L]] <- add_input(
  historical_id, "catch", "numbers_at_age", "numbers", catch_age[as.character(year), age - 4L],
  "thousand fish", year, age, fleet = "NAFO Divisions 3LNO commercial fishery",
  source_reference = "NAFO SCR Doc. 21/035, Table 23, p. 33",
  notes = "Age 15 is the terminal 15+ group. The report identifies changes in source methods: effort method for 2014, DCRs for 2015–2016, and CDAG for 2017–2020."
)
for (year in weight_years) for (age in 5:15) inputs[[length(inputs) + 1L]] <- add_input(
  historical_id, "weight", "weight_at_age", "kg_per_fish", stock_weight[as.character(year), age - 4L],
  "kg/fish", year, age, source_reference = "NAFO SCR Doc. 21/035, Table 24, p. 34",
  notes = "Beginning-of-year stock weight; age 15 is the 15+ group."
)
for (year in maturity_years) for (age in 5:15) inputs[[length(inputs) + 1L]] <- add_input(
  historical_id, "maturity", "maturity_at_age", "proportion", maturity[as.character(year), age - 4L],
  "proportion", year, age, source_reference = "NAFO SCR Doc. 21/035, Table 25, p. 35",
  notes = "Annual estimated proportion mature; age 15 is the terminal group."
)
for (survey_data in list(
  list(values = fall_index, years = fall_years, name = "Canadian autumn RV bottom-trawl survey", season = "autumn", ref = "NAFO SCR Doc. 21/035, Table 26, p. 36"),
  list(values = spring_index, years = spring_years, name = "Canadian spring RV bottom-trawl survey", season = "spring", ref = "NAFO SCR Doc. 21/035, Table 27, p. 37"),
  list(values = spain_index, years = spain_years, name = "EU-Spain Divisions 3NO spring bottom-trawl survey", season = "spring", ref = "NAFO SCR Doc. 21/035, Table 28, p. 38")
)) {
  for (year in survey_data$years) for (age in 5:14) inputs[[length(inputs) + 1L]] <- add_input(
    historical_id, "index", "numbers_at_age", "numbers",
    survey_data$values[as.character(year), age - 4L], "fish per tow", year, age,
    survey = survey_data$name, region = if (grepl("3NO", survey_data$name, fixed = TRUE)) "NAFO Division 3NO" else "NAFO Divisions 3LNO",
    season = survey_data$season, source_reference = survey_data$ref,
    notes = "The decimal year in the source table denotes survey season; no exact within-year sampling fraction is reported. Age-specific mean number per tow; no plus group."
  )
}
for (year in catch_years) for (age in 5:15) {
  m <- if (year >= 1989 && year <= 1996) 0.53 else 0.2
  inputs[[length(inputs) + 1L]] <- add_input(
    historical_id, "M", "natural_mortality_at_age", "per_year", m, "year^-1", year, age,
    source_reference = "NAFO SCR Doc. 21/035, Section 2.1, p. 6",
    transformation = "Expanded the documented fixed annual mortality assumption over ages 5–15 and years 1960–2020; M=0.53 in 1989–1996 and 0.2 otherwise.",
    notes = "Fixed mortality assumption used for the VPA; no estimated M-at-age series was reported."
  )
}

# Current 2026 interim monitoring sources
monitor_inputs <- list()
monitor_catch <- c(1.2, 1.0, 1.2, 1.2, 1.6, 0.8, 0.6, 0.376, 0.574)
for (year in 2017:2025) {
  precise_text_catch <- year %in% 2024:2025
  catch_note <- if (precise_text_catch) {
    paste0("STACFIS reports ", c(`2024` = 376, `2025` = 574)[[as.character(year)]],
      " tonnes in the text; converted to 1000 tonnes. This is a monitoring series, not catch-at-age for a 2026 full assessment.")
  } else {
    "Rounded total catch as reported in thousands of tonnes; this is a monitoring series, not catch-at-age for a 2026 full assessment."
  }
  monitor_inputs[[length(monitor_inputs) + 1L]] <- add_input(
    monitoring_id, "catch", "total_biomass", "biomass", monitor_catch[[year - 2016L]],
    "1000 tonnes", year, fleet = "NAFO Divisions 3LNO fisheries",
    source_reference = "NAFO SCS Doc. 26/12, American plaice monitoring section, pp. 160–161",
    transformation = if (precise_text_catch) "Converted the text value in tonnes to 1000 tonnes by dividing by 1000; the report table rounds these catches to 0.1 thousand tonnes." else "None; retained the report table value in 1000 tonnes.",
    notes = catch_note
  )
}

survey_3no <- "EU-Spain spring bottom-trawl survey, NAFO Divisions 3NO"
biomass_3no <- c(27475, 8228, 35187, 41277, 35664)
sd_biomass_3no <- c(8940, 1284, 4467, 4912, 6700)
number_3no <- c(93318, 37036, 147875, 175966, 142349)
sd_number_3no <- c(19049, 7739, 18705, 33003, 17608)
for (i in seq_along(2021:2025)) {
  year <- 2020L + i
  monitor_inputs[[length(monitor_inputs) + 1L]] <- add_input(monitoring_id, "index", "total_biomass", "biomass", biomass_3no[[i]], "tonnes", year,
    survey = survey_3no, region = "NAFO Division 3NO", season = "spring",
    source_reference = "NAFO SCR Doc. 26/001, Table 9, p. 16",
    notes = "Total stratified survey biomass by swept-area method; this is an aggregate monitoring index, not an age-specific XSA observation.")
  monitor_inputs[[length(monitor_inputs) + 1L]] <- add_input(monitoring_id, "index", "index_sd", "biomass", sd_biomass_3no[[i]], "tonnes", year,
    survey = survey_3no, region = "NAFO Division 3NO", season = "spring",
    source_reference = "NAFO SCR Doc. 26/001, Table 9, p. 16",
    notes = "Reported SD_B for total stratified biomass index; not an estimated population standard error.")
  monitor_inputs[[length(monitor_inputs) + 1L]] <- add_input(monitoring_id, "index", "total_numbers", "numbers", number_3no[[i]], "thousand fish", year,
    survey = survey_3no, region = "NAFO Division 3NO", season = "spring",
    source_reference = "NAFO SCR Doc. 26/001, Table 9, p. 16",
    notes = "Total stratified survey abundance by swept-area method; reported in thousands, not an age-specific XSA observation.")
  monitor_inputs[[length(monitor_inputs) + 1L]] <- add_input(monitoring_id, "index", "index_sd", "numbers", sd_number_3no[[i]], "thousand fish", year,
    survey = survey_3no, region = "NAFO Division 3NO", season = "spring",
    source_reference = "NAFO SCR Doc. 26/001, Table 9, p. 16",
    notes = "Reported SD_A for total stratified abundance index; not an estimated population standard error.")
}

survey_3l <- "EU-Spain bottom-trawl survey, NAFO Division 3L"
biomass_3l <- c(10738, 8111, 10439, 8850, 11459)
years_3l <- c(2018L, 2019L, 2023L, 2024L, 2025L)
for (i in seq_along(years_3l)) monitor_inputs[[length(monitor_inputs) + 1L]] <- add_input(
  monitoring_id, "index", "total_biomass", "biomass", biomass_3l[[i]], "tonnes", years_3l[[i]],
  survey = survey_3l, region = "NAFO Division 3L", season = "summer",
  source_reference = "NAFO SCR Doc. 26/005, Table 20, p. 27",
  notes = "Published total biomass index for the 3L survey component. The table overprints a second table; only the total biomass point estimates are imported. No SD is inferred from the overprinted row. No surveys were conducted in 2020–2022."
)

assumptions_new <- rbind(
  add_assumption(historical_id, "assessment", "assessment_method", "ADAPT VPA, full assessment",
    "NAFO SCR Doc. 21/035, pp. 1–2 and assessment sections"),
  add_assumption(historical_id, "population", "assessment_period", "Catch and survey inputs through 2019; population estimates through 2020; 2021 terminal survivor parameters",
    "NAFO SCR Doc. 21/035, Tables 20–29, pp. 27–39"),
  add_assumption(historical_id, "population", "assessment_ages", "Ages 5–14 and terminal age 15+",
    "NAFO SCR Doc. 21/035, Tables 23–29, pp. 33–39"),
  add_assumption(historical_id, "mortality", "fixed_natural_mortality", "M=0.2 year^-1 except M=0.53 year^-1 in 1989–1996, all modeled ages",
    "NAFO SCR Doc. 21/035, Section 2.1, p. 6"),
  add_assumption(historical_id, "index", "survey_timing", "Spring series use source decimal year .5; fall series use .9; these codes do not establish exact within-year timing fractions",
    "NAFO SCR Doc. 21/035, Tables 26–28, pp. 36–38"),
  add_assumption(historical_id, "population", "absolute_population_reliability", "Authors accepted ADAPT as a stock-trend indicator, not as reliable absolute population estimates",
    "NAFO SCR Doc. 21/035, assessment results and conclusions",
    "The report identifies poor fit, residual patterns, retrospective behaviour and instability in the absolute population estimates."),
  add_assumption(monitoring_id, "assessment", "assessment_method", "Interim monitoring only; no full assessment was conducted in 2026",
    "NAFO SCS Doc. 26/12, American plaice monitoring section, pp. 161–164"),
  add_assumption(monitoring_id, "management", "advice", "No directed fishing until an assessment indicates a very low probability of being below Blim; bycatch should be minimized and limited to unavoidable bycatch",
    "NAFO SCS Doc. 26/12, American plaice advice section, p. 162"),
  add_assumption(monitoring_id, "assessment", "next_full_assessment", "June 2028 after a benchmark work plan",
    "NAFO SCS Doc. 26/12, American plaice advice section, p. 162")
)
inputs_new <- do.call(rbind, c(inputs, monitor_inputs))
output_rows <- list()
parameter_lines <- unlist(strsplit(pages[[39]], "\n", fixed = TRUE), use.names = FALSE)
parameter_rows <- parameter_lines[grepl("N\\[2021 [0-9]+\\]", parameter_lines)]
for (line in parameter_rows) {
  match <- regexec("N\\[2021 ([0-9]+)\\]\\s+([0-9.]+)\\s+([0-9.]+)", line, perl = TRUE)
  parts <- regmatches(line, match)[[1L]]
  if (!length(parts)) next
  output_rows[[length(output_rows) + 1L]] <- add_output(
    historical_id, "population", "survivors_at_age", as.numeric(parts[[3L]]),
    "thousand fish", year = 2021L, age = as.integer(parts[[2L]]), se = as.numeric(parts[[4L]]),
    source_reference = "NAFO SCR Doc. 21/035, Table 29, p. 39",
    notes = "ADAPT terminal survivor parameter before bias adjustment; its SE is not an SE for the bias-adjusted historical N-at-age series. The authors caution against interpreting the model's absolute population estimates as reliable."
  )
}
outputs_new <- do.call(rbind, output_rows)

stock_new <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NAFO",
  authority_stock_id = "american_plaice.3LNO", scientific_name = "Hippoglossoides platessoides",
  common_name = "American plaice", area = "NAFO Divisions 3LNO", region = "Grand Bank",
  ocean = "Northwest Atlantic",
  notes = "NAFO-managed American plaice in Divisions 3LNO; no existing canonical DFO record for this unit was identified.",
  stringsAsFactors = FALSE)
assessments_new <- rbind(
  data.frame(assessment_id = historical_id, stock_id = stock_id, assessment_year = 2021L,
    terminal_year = 2020L, estimate_terminal_year = 2021L, assessment_type = "full_assessment",
    model_family = "ADAPT", model_version = "ADAPT; software version not reported",
    is_current = FALSE, is_applied = TRUE, framework_year = NA_integer_,
    assessment_url = "https://www.nafo.int/Portals/0/PDFs/sc/2021/scr21-035.pdf",
    framework_url = "", data_url = "https://www.nafo.int/Portals/0/PDFs/sc/2021/scr21-035.pdf",
    model_url = "", repository_url = "", assumptions_status = "partial",
    inputs_status = "complete", outputs_status = "partial",
    notes = "Latest detailed full assessment located. The 2021 authors regarded ADAPT as useful for trends, not reliable absolute population estimates, because of poor fit, retrospective patterns and instability. Terminal survivor parameters are reported for 2021; full historical numerical population trajectories are not tabulated.",
    stringsAsFactors = FALSE),
  data.frame(assessment_id = monitoring_id, stock_id = stock_id, assessment_year = 2026L,
    terminal_year = 2025L, estimate_terminal_year = 2025L, assessment_type = "interim_monitoring",
    model_family = "No full assessment", model_version = "NAFO interim monitoring; no 2026 model run",
    is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
    assessment_url = "https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf",
    framework_url = "", data_url = "https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-001.pdf",
    model_url = "", repository_url = "", assumptions_status = "partial",
    inputs_status = "partial", outputs_status = "not_applicable",
    notes = "The latest 2026 advice is based on interim monitoring, not a full assessment. Recent catch and aggregate survey series are recorded separately; age-specific model inputs and numerical population outputs were not reported. No numeric zero-catch output is inferred from the no-directed-fishing recommendation.",
    stringsAsFactors = FALSE)
)

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates <- read_csv(candidate_path)
if (stock_id %in% stocks$stock_id || any(assessments_new$assessment_id %in% assessments$assessment_id)) stop("Stock or assessment already exists; inspect before importing.", call. = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || candidates$candidate_unit_id[candidate_row] != stock_id) stop("Expected exactly one matching 3LNO American plaice candidate.", call. = FALSE)
if (nrow(assumptions_new) != 9L || nrow(inputs_new) != 3614L || nrow(outputs_new) != 10L) stop("Unexpected plaice extraction row counts.", call. = FALSE)
if (any(!is.finite(inputs_new$value) & !is.na(inputs_new$value)) || any(!is.finite(outputs_new$value))) stop("Non-finite plaice source values.", call. = FALSE)

if (identical(Sys.getenv("SAIO_NAFO_IMPORT_DRY_RUN"), "1")) {
  message("Dry run only: ", nrow(inputs_new), " inputs; ", nrow(assumptions_new), " assumptions; ", nrow(outputs_new), " outputs.")
  message("2021 inputs: ", sum(inputs_new$assessment_id == historical_id), "; 2026 monitoring inputs: ", sum(inputs_new$assessment_id == monitoring_id), ".")
  quit(save = "no", status = 0L)
}

has_assessment <- function(path, ids) {
  con <- file(path, open = "r"); on.exit(close(con), add = TRUE)
  prefixes <- paste0("\"", ids, "\",\"")
  repeat { lines <- readLines(con, n = 100000L, warn = FALSE); if (!length(lines)) return(FALSE); if (any(vapply(prefixes, function(prefix) any(startsWith(lines, prefix)), logical(1)))) return(TRUE) }
}
for (path in c(assumptions_path, inputs_path, outputs_path)) if (has_assessment(path, assessments_new$assessment_id)) stop("Assessment rows already exist; inspect before importing.", call. = FALSE)
append_csv(stock_new, stocks_path)
append_csv(assessments_new, assessments_path)
append_csv(assumptions_new, assumptions_path)
append_csv(inputs_new, inputs_path)
append_csv(outputs_new, outputs_path)
candidates$matched_stock_id[candidate_row] <- stock_id
candidates$match_status[candidate_row] <- "matched"
candidates$inventory_assessment_year[candidate_row] <- 2026L
candidates$import_status[candidate_row] <- "partial"
candidates$notes[candidate_row] <- "The current 2026 advice is based on interim monitoring with no full assessment; aggregate recent catches and survey indices are retained, with no inferred zero catch or age-specific input. The 2021 ADAPT is the latest detailed full model. It was judged suitable for stock trends but not reliable absolute population estimates. No duplicate DFO assessment record for 3LNO was found."
replace_candidate_register_row(candidate_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id)
message("Imported 3LNO plaice monitoring and 2021 assessment: ", nrow(inputs_new), " inputs; ", nrow(assumptions_new), " assumptions; ", nrow(outputs_new), " outputs.")



