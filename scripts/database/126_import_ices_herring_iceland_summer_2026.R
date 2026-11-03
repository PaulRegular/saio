root <- "."
cache_dir <- file.path(root, "source_cache", "ck_ices_nwwg_harengus_ice_summer", "assessment_2026")
assessment_id <- "ices_herring_iceland_summer_2026"
stock_id <- "ck_ices_nwwg_harengus_ice_summer"
assessment_year <- 2026L
report_url <- "https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_techreport_en.html"
tables_url <- "https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_tables_en.html"
advice_url <- "https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_advice_en.html"
ices_sag_url <- "https://sg.ices.dk/ViewCharts.aspx?key=22455"
framework_url <- "https://doi.org/10.17895/ices.pub.25605135"

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The source importer requires jsonlite.", call. = FALSE)
}
tables_path <- file.path(cache_dir, "MFRI_2026_tables_en.html")
if (!file.exists(tables_path)) stop("Missing cached MFRI 2026 tables.", call. = FALSE)
html <- paste(readLines(tables_path, warn = FALSE), collapse = "\n")

extract_widget <- function(id) {
  pattern <- paste0(
    '(?s)<div id="', id,
    '" class="section level3">\\s*<h3>([^<]+)</h3>.*?',
    '<script type="application/json" data-for="[^"]+">(.*?)</script>'
  )
  match <- regmatches(html, regexec(pattern, html, perl = TRUE))[[1]]
  if (length(match) != 3L) stop("Could not locate MFRI table: ", id, call. = FALSE)
  widget <- tryCatch(
    jsonlite::fromJSON(match[[3]], simplifyVector = FALSE)$x,
    error = function(error) stop("Could not parse MFRI table ", id, ": ",
      conditionMessage(error), call. = FALSE)
  )
  header_tags <- regmatches(widget$container,
    gregexpr("(?s)<th[^>]*>.*?</th>", widget$container, perl = TRUE))[[1]]
  headers <- trimws(gsub("(?s)<[^>]*>", "", header_tags, perl = TRUE))
  cell_value <- function(value) {
    if (is.null(value) || !length(value)) return(NA_character_)
    value <- unlist(value, recursive = TRUE, use.names = FALSE)
    if (!length(value)) NA_character_ else as.character(value[[1]])
  }
  columns <- lapply(widget$data, function(values) {
    vapply(values, cell_value, character(1))
  })
  if (length(headers) != length(columns)) {
    stop("MFRI table columns do not match headings: ", id, call. = FALSE)
  }
  out <- as.data.frame(columns, check.names = FALSE, stringsAsFactors = FALSE)
  names(out) <- headers
  out
}

as_number <- function(value) suppressWarnings(as.numeric(trimws(value)))
read_age_table <- function(id, years, ages) {
  out <- extract_widget(id)
  out$Year <- as.integer(as_number(out$Year))
  age_columns <- as.character(ages)
  if (!all(age_columns %in% names(out))) stop("Missing age columns in ", id, call. = FALSE)
  for (age in age_columns) out[[age]] <- as_number(out[[age]])
  if (anyNA(out$Year) || anyDuplicated(out$Year) ||
    !all(range(years) %in% out$Year) || any(!out$Year %in% years) ||
    any(!is.na(out$Species) & out$Species != "Herring") ||
    any(!is.na(out$`Latin Name`) & out$`Latin Name` != "Clupea harengus")) {
    stop("Unexpected stock identity or coverage in MFRI table: ", id, call. = FALSE)
  }
  out[out$Year %in% years, , drop = FALSE]
}
age_matrix <- function(table, ages, label, allow_missing = FALSE) {
  values <- as.matrix(table[as.character(ages)])
  storage.mode(values) <- "numeric"
  if (!allow_missing && any(!is.finite(values))) {
    stop(label, " has missing or non-finite cells.", call. = FALSE)
  }
  if (any(values < 0, na.rm = TRUE)) stop(label, " has negative values.", call. = FALSE)
  values
}

ages <- 2:15
input_years <- 1980:2023
output_years <- 1980:2024
summary_table <- extract_widget("assessment-summary")
summary_table$Year <- as.integer(as_number(summary_table$Year))
summary_table <- summary_table[match(1980:2026, summary_table$Year), , drop = FALSE]
if (anyNA(summary_table$Year)) stop("Assessment summary does not cover 1980-2026.", call. = FALSE)

catch_table <- read_age_table("catch-at-age", input_years, ages)
index_table <- read_age_table("acoustic-survey-index", input_years, ages)
stock_weight_table <- read_age_table("stock-weights", 1980:2024, ages)
catch_weight_table <- read_age_table("catch-weights", 1980:2024, ages)
maturity_table <- read_age_table("maturity-at-age", input_years, ages)
n_table <- read_age_table("stock-in-numbers", output_years, ages)
f_table <- read_age_table("fishing-mortality", output_years, ages)

catch <- age_matrix(catch_table, ages, "Catch at age", allow_missing = TRUE)
index <- age_matrix(index_table, ages, "Acoustic index", allow_missing = TRUE)
index_years <- index_table$Year
stock_weight <- age_matrix(stock_weight_table, ages, "Stock weight")
catch_weight <- age_matrix(catch_weight_table, ages, "Catch weight")
maturity <- age_matrix(maturity_table, ages, "Maturity")
n_at_age <- age_matrix(n_table, ages, "Stock numbers at age")
f_at_age <- age_matrix(f_table, ages, "Fishing mortality at age")

summary_fields <- c(
  SSB = "SSB", low_ssb = "Low SSB", high_ssb = "High SSB",
  biomass_4plus = "Ref. Biomass", low_biomass_4plus = "Low Ref. Biomass",
  high_biomass_4plus = "High Ref. Biomass", recruitment = "Recruitment",
  low_recruitment = "Low Recruitment", high_recruitment = "High Recruitment",
  fbar = "F", low_fbar = "Low F", high_fbar = "High F",
  harvest_rate = "HR"
)
summary_values <- lapply(summary_fields, function(field) as_number(summary_table[[field]]))
names(summary_values) <- names(summary_fields)
if (any(!vapply(summary_values[c("SSB", "low_ssb", "high_ssb", "recruitment", "low_recruitment", "high_recruitment")],
  function(x) all(is.finite(x)), logical(1))) ||
  any(maturity < 0 | maturity > 1) || any(stock_weight <= 0) ||
  any(catch_weight <= 0) || any(n_at_age < 0) || any(f_at_age < 0)) {
  stop("Icelandic summer herring values failed coverage or range checks.", call. = FALSE)
}

sag_path <- file.path(cache_dir, "ICES_SAG_2026_key_22455.xml")
if (!requireNamespace("xml2", quietly = TRUE) || !file.exists(sag_path)) {
  stop("The cached ICES SAG XML and xml2 are required for cross-checking.", call. = FALSE)
}
sag <- xml2::read_xml(sag_path)
sag_years <- as.integer(xml2::xml_text(xml2::xml_find_all(sag, "//Fish_Data/Year")))
sag_ssb <- as.numeric(xml2::xml_text(xml2::xml_find_all(sag, "//Fish_Data/StockSize")))
sag_recruitment <- as.numeric(xml2::xml_text(xml2::xml_find_all(sag, "//Fish_Data/Recruitment")))
if (!identical(sort(unique(sag_years)), 1980:2026) ||
  any(abs(summary_values$SSB[match(sag_years, summary_table$Year)] - sag_ssb) > 1) ||
  any(abs(summary_values$recruitment[match(sag_years, summary_table$Year)] - sag_recruitment) > 1)) {
  stop("MFRI summary values do not match the ICES SAG 2026 XML.", call. = FALSE)
}

input_row <- function(type, measure, basis, survey = "", year, age,
                      value, unit, source_reference, notes = "",
                      transformation = "", sampling_time = NA_real_,
                      source_type = "official_table") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = "", survey = survey, sex = "combined", region = "ICES 5.a",
    season = ifelse(nzchar(survey), "winter", ""), year = year,
    year_basis = ifelse(is.na(year), "", "model_year"), age = age,
    value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = NA_real_, stringsAsFactors = FALSE
  )
}
age_inputs <- function(type, measure, basis, years, values, unit,
                       source_reference, notes = "", survey = "",
                       sampling_time = NA_real_, transformation = "",
                       allow_missing = FALSE) {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(values)
  if (!allow_missing && any(!is.finite(grid$value))) {
    stop("Unexpected missing values for ", source_reference, call. = FALSE)
  }
  grid <- grid[is.finite(grid$value), , drop = FALSE]
  input_row(type, measure, basis, survey = survey, year = grid$year,
    age = grid$age, value = grid$value, unit = unit,
    source_reference = source_reference, notes = notes,
    transformation = transformation, sampling_time = sampling_time)
}

input_ref <- function(table) paste("MFRI 2026 assessment tables:", table)
inputs_add <- rbind(
  age_inputs("catch", "numbers_at_age", "numbers", input_years, catch,
    "million fish", input_ref("Catch-at-age"),
    notes = "MFRI's machine-readable assessment table. The 2026 technical report publishes a more recent raw catch-at-age table through 2025; exact correspondence to the fitted SAM data is unresolved, so this imported series stops at the table's 2023 coverage.",
    allow_missing = TRUE),
  age_inputs("index", "numbers_at_age", "numbers", index_years, index,
    "million fish", input_ref("Acoustic survey index"),
    notes = "Age-specific acoustic abundance series as tabulated for the assessment. The 2026 technical report's raw acoustic estimates extend through 2026 and use autumn age labels; their exact mapping to this model-year series is unresolved.",
    survey = "IS-Her-Aco-4Q/1Q", sampling_time = 0,
    transformation = "Use the year and age indexing in the MFRI assessment table; do not apply an additional shift." ,
    allow_missing = TRUE),
  age_inputs("weight", "weight_at_age", "kg_per_fish", 1980:2024, stock_weight,
    "kg", input_ref("Stock weights"),
    notes = "Annual stock weight at age in kg per fish."),
  age_inputs("catch_weight", "weight_at_age", "kg_per_fish", 1980:2024, catch_weight,
    "kg", input_ref("Catch weights"),
    notes = "Annual catch weight at age in kg per fish."),
  age_inputs("maturity", "maturity_at_age", "proportion", input_years, maturity,
    "proportion", input_ref("Maturity at age"),
    notes = "Annual proportion mature at age."),
  input_row("M", "natural_mortality_at_age", "per_year", year = NA_real_,
    age = ages, value = rep(0.1, length(ages)), unit = "per year",
    source_reference = "MFRI 2026 technical report; ICES WKICEHER 2024, Annex 5, Table A7",
    notes = "Baseline M is 0.1 per year. The official assessment adds infection-related mortality with a multiplier; the full current age-year surface is not recoverable from the published machine-readable tables.",
    source_type = "official_document")
)

output_row <- function(type, measure, year, age = NA_real_, age_group = "",
                       value, unit, source_reference, notes = "",
                       lwr = NA_real_, upr = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "combined", region = "ICES 5.a", season = "",
    year = year, age = age, age_group = age_group, value = value, se = NA_real_,
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE
  )
}
age_outputs <- function(measure, years, values, unit, source_reference, notes) {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(values)
  output_row(if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age, value = grid$value, unit = unit,
    source_reference = source_reference, notes = notes)
}
summary_years <- summary_table$Year
output_ref <- "MFRI 2026 assessment tables; ICES SAG 2026 key 22455"
ssb_note <- "Published SSB in tonnes. Low and high values are the ICES SAG 95% interval; the MFRI table does not identify the interval construction."
recruit_note <- "Recruitment at age 2 in thousands of fish. Low and high values are the ICES SAG 95% interval; the MFRI table does not identify the interval construction."
outputs_add <- rbind(
  age_outputs("numbers_at_age", output_years, n_at_age, "thousand fish",
    input_ref("Stock in numbers"),
    "Official beginning-of-year abundance at age; values are in thousands of fish. No age-specific uncertainty was published in the table."),
  age_outputs("fishing_mortality_at_age", output_years, f_at_age, "per year",
    input_ref("Fishing mortality"),
    "Official fishing mortality at age, per year. No age-specific uncertainty was published in the table."),
  output_row("biomass", "SSB", summary_years,
    value = summary_values$SSB, unit = "tonnes", source_reference = output_ref,
    notes = ssb_note, lwr = summary_values$low_ssb, upr = summary_values$high_ssb),
  output_row("recruitment", "recruitment", summary_years, age = 2,
    value = summary_values$recruitment, unit = "thousand fish",
    source_reference = output_ref, notes = recruit_note,
    lwr = summary_values$low_recruitment, upr = summary_values$high_recruitment),
  output_row("mortality", "Fbar", summary_years, age_group = "5-10",
    value = summary_values$fbar, unit = "per year", source_reference = output_ref,
    notes = "MFRI summary-table F; the 2024 SAM configuration reports Fbar ages 5-10. Confidence limits are retained as published, with interval construction unresolved.",
    lwr = summary_values$low_fbar, upr = summary_values$high_fbar),
  output_row("mortality", "harvest_rate",
    summary_years[is.finite(summary_values$harvest_rate)],
    value = summary_values$harvest_rate[is.finite(summary_values$harvest_rate)],
    unit = "ratio", source_reference = output_ref,
    notes = "Published harvest-rate series; this is not Fbar.")
)

paths <- setNames(file.path(root, "database", paste0(
  c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs"))
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = "")
read_first_column <- function(name) {
  columns <- names(read.csv(paths[[name]], nrows = 0, check.names = FALSE))
  read.csv(paths[[name]], colClasses = c("character", rep("NULL", length(columns) - 1L)),
    stringsAsFactors = FALSE, check.names = FALSE)$assessment_id
}
stocks <- read_db("stocks")
assessments <- read_db("assessments")
assumptions <- read_db("assumptions")
if (sum(stocks$stock_id == stock_id) != 1L ||
  any(assessments$assessment_id == assessment_id) ||
  any(read_first_column("inputs") == assessment_id, na.rm = TRUE) ||
  any(read_first_column("outputs") == assessment_id, na.rm = TRUE)) {
  stop("Expected one existing stock and no existing 2026 assessment rows.", call. = FALSE)
}
if (nrow(inputs_add) < 3000L || nrow(outputs_add) < 1400L ||
  any(!is.finite(inputs_add$value)) || any(!is.finite(outputs_add$value)) ||
  any(inputs_add$value[inputs_add$type == "maturity"] > 1) ||
  any(inputs_add$value[inputs_add$type == "M"] != 0.1)) {
  stop("Icelandic summer herring rows failed coverage or value checks.", call. = FALSE)
}

stock_row <- which(stocks$stock_id == stock_id)
stocks$authority_stock_id[stock_row] <- "her.27.5a"
stocks$common_name[stock_row] <- "Icelandic summer-spawning herring"
stocks$area[stock_row] <- "ICES Division 5.a (Iceland grounds)"
stocks$region[stock_row] <- "Icelandic Waters"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Charbonneau-Keith metadata entry verified as Icelandic summer-spawning herring (ICES her.27.5a).",
  "The 2026 production assessment is represented below; see the stock source review for coverage and unresolved year/age mapping."
)

assessment_add <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = assessment_year, terminal_year = 2023L,
  estimate_terminal_year = 2026L, assessment_type = "annual",
  model_family = "SAM",
  model_version = "2026 production assessment using the 2024 WKICEHER SAM framework",
  is_current = TRUE, is_applied = TRUE, framework_year = 2024L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = tables_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Latest official assessment for 2026 advice. terminal_year follows the last year in the MFRI machine-readable age-specific input tables (2023); estimate_terminal_year follows the aggregate assessment series (2026).",
    "The 2026 technical report publishes newer raw catch and acoustic series than the machine-readable assessment tables. Exact mapping to the production SAM data is unresolved, so inputs and assumptions remain partial. Age-specific N and F surfaces are published through 2024; uncertainty is not published for those surfaces."
  ), stringsAsFactors = FALSE
)
assumption_row <- function(component, setting, value, source_reference, notes = "",
                            survey = "", season = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = survey, sex = "combined", region = "ICES 5.a", season = season,
    setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
assumptions_add <- rbind(
  assumption_row("population", "recruitment_age", 2,
    "ICES Stock Assessment Graphs, 2026 key 22455",
    "Recruitment is reported at age 2."),
  assumption_row("population", "model_ages", "2-15",
    "ICES WKICEHER 2024, Annex 6",
    "Fifteen is a modeled age, not a plus group, in the benchmark configuration."),
  assumption_row("population", "stock_recruitment_model", "piecewise constant (SAM code 3)",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("F", "process", "AR(1) across ages",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("F", "age_parameter_groups", "ages 2-6 separate; ages 7-15 shared",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("F", "Fbar_ages", "5-10",
    "ICES Stock Assessment Graphs, 2026 key 22455"),
  assumption_row("N", "process_variance_groups", "age 2 separate; ages 3-15 shared",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("index", "q_age_groups", "age 2 not estimated; ages 3, 4, 5, and 6 separate; ages 7-15 shared",
    "ICES WKICEHER 2024, Annex 6",
    "The production fit configuration was not recovered; treated as the 2024 benchmark specification."),
  assumption_row("index", "observation_covariance", "AR(1) across ages",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("index", "sampling_time", 0,
    "ICES WKICEHER 2024, section 3.3",
    "The acoustic series is modeled at the beginning of the assessment year; the exact production mapping is not published.",
    survey = "IS-Her-Aco-4Q/1Q", season = "winter"),
  assumption_row("biology", "stock_weight_model", "fixed as known",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("biology", "maturity_model", "fixed as known",
    "ICES WKICEHER 2024, Annex 6"),
  assumption_row("M", "baseline", "0.1 per year plus infection mortality",
    "MFRI 2026 technical report; ICES WKICEHER 2024, Annex 5 Table A7",
    "The infection multiplier is estimated in the assessment; the current numerical age-year M surface was not recovered."),
  assumption_row("M", "infection_multiplier", 0.22,
    "ICES WKICEHER 2024; MFRI 2026 technical report",
    "The 2024 benchmark revised the multiplier; the 2026 production coefficient is not separately tabulated."),
  assumption_row("assessment", "source_run", "2026 ICES advice assessment, key 22455",
    ices_sag_url,
    "ICESSAG aggregate output is cross-checked against the MFRI 2026 assessment tables.")
)

assessments <- rbind(assessments, assessment_add)
assumptions <- rbind(assumptions, assumptions_add)
append_rows <- function(path, rows) {
  columns <- names(read.csv(path, nrows = 0, check.names = FALSE))
  if (!setequal(names(rows), columns)) stop("Column mismatch: ", basename(path), call. = FALSE)
  invisible(columns)
}
append_rows(paths[["inputs"]], inputs_add)
append_rows(paths[["outputs"]], outputs_add)
if (identical(Sys.getenv("TINYAM_DATABASE_DRY_RUN"), "true")) {
  cat("Dry run passed: ", nrow(inputs_add), " inputs and ", nrow(outputs_add),
    " outputs validated; database files were not changed.\n", sep = "")
} else {
  utils::write.csv(stocks, paths[["stocks"]], row.names = FALSE, na = "")
  utils::write.csv(assessments, paths[["assessments"]], row.names = FALSE, na = "")
  utils::write.csv(assumptions, paths[["assumptions"]], row.names = FALSE, na = "")
  append_rows <- function(path, rows) {
    columns <- names(read.csv(path, nrows = 0, check.names = FALSE))
    utils::write.table(rows[columns], path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  }
  append_rows(paths[["inputs"]], inputs_add)
  append_rows(paths[["outputs"]], outputs_add)
  cat("Imported Icelandic summer herring 2026: ", nrow(inputs_add),
    " inputs and ", nrow(outputs_add), " outputs. Coverage is partial; see source review.\n", sep = "")
}
