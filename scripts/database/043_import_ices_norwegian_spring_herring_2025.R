root <- "."
cache <- file.path(root, "source_cache", "ices_herring_norwegian_spring_2026")
database <- file.path(root, "database")
assessment_id <- "ices_herring_norwegian_spring_2025"
summary_id <- "ices_herring_norwegian_spring_2026"

pdf_path <- file.path(cache, "wgwide_2025_norwegian_spring_spawning_herring.pdf")
text_path <- file.path(cache, "wgwide_2025_extracted_text.txt")
age_tables_path <- file.path(cache, "wgwide_2025_age_tables.csv")
if (!file.exists(age_tables_path)) {
  stop("The age-aligned report table extraction is missing from source_cache.",
    call. = FALSE
  )
}
age_tables <- read.csv(age_tables_path,
  na.strings = c("", "NA"),
  check.names = FALSE
)
required_age_columns <- c("table_id", "year", "age", "value")
if (!all(required_age_columns %in% names(age_tables))) {
  stop("The cached age-table extraction has an unexpected structure.",
    call. = FALSE
  )
}
age_tables$year <- as.integer(age_tables$year)
age_tables$age <- as.integer(age_tables$age)
age_tables$value <- suppressWarnings(as.numeric(age_tables$value))
age_table_years <- list(
  `4.4.3.1` = 1950:2024,
  `4.4.4.1` = 1950:2024,
  `4.4.4.2` = 1950:2025,
  `4.4.5.1` = 1950:2025,
  `4.4.7.1` = 1988:2025,
  `4.4.7.2` = c(1991:2007, 2009:2024),
  `4.4.7.3` = 1996:2025,
  `4.4.7.4` = 2004:2024,
  `4.4.8.1` = 1988:2024,
  `4.4.8.2` = 1988:2025,
  `4.4.8.3` = 1991:2025,
  `4.4.8.4` = 1996:2025,
  `4.4.8.5` = 2017:2023,
  `4.5.1.2` = 1988:2025,
  `4.5.1.3` = 1988:2025
)
if (!file.exists(text_path)) {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("Install pdftools or provide the cached extracted report text.", call. = FALSE)
  }
  writeLines(paste(pdftools::pdf_text(pdf_path), collapse = "\n"),
    text_path,
    useBytes = TRUE
  )
}
report_lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")

read_report_table <- function(table_id, expected_columns) {
  header <- grep(paste0("^\\s*Table\\s+", gsub("\\.", "\\\\.", table_id)),
    report_lines,
    perl = TRUE
  )
  if (length(header) != 1L) stop("Expected one report table: ", table_id)
  next_header <- grep("^\\s*Table\\s+[0-9]+\\.", report_lines, perl = TRUE)
  next_header <- next_header[next_header > header]
  end <- if (length(next_header)) min(next_header) - 1L else length(report_lines)
  block <- report_lines[seq.int(header + 1L, end)]
  data_lines <- block[grepl("^\\s*(19|20)[0-9]{2}(\\*+)?(\\s+|$)", block, perl = TRUE)]
  rows <- lapply(data_lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+")[[1L]]
    year <- suppressWarnings(as.integer(sub("\\*.*$", "", fields[[1L]])))
    values <- fields[-1L]
    if (!length(values)) {
      return(NULL)
    }
    if (length(values) > expected_columns) {
      stop("Too many columns in table ", table_id, ", year ", year)
    }
    values <- c(values, rep("NA", expected_columns - length(values)))
    value <- suppressWarnings(as.numeric(values))
    data.frame(year = year, value = I(list(value)), stringsAsFactors = FALSE)
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) stop("No year rows found in report table: ", table_id)
  years <- vapply(rows, function(x) x[["year"]], integer(1))
  if (anyDuplicated(years)) stop("Duplicate years in report table: ", table_id)
  values <- do.call(rbind, lapply(rows, function(row) as.numeric(row$value[[1L]])))
  out <- as.data.frame(values, check.names = FALSE)
  names(out) <- paste0("v", seq_len(expected_columns))
  out$year <- years
  out[c("year", paste0("v", seq_len(expected_columns)))]
}

read_age_table <- function(table_id, ages) {
  x <- age_tables[age_tables$table_id == table_id, required_age_columns,
    drop = FALSE
  ]
  expected_years <- age_table_years[[table_id]]
  if (!nrow(x) || is.null(expected_years) || !setequal(unique(x$age), ages) ||
    !setequal(unique(x$year), expected_years) ||
    nrow(x) != length(ages) * length(expected_years) ||
    anyDuplicated(x[c("year", "age")])) {
    stop("Unexpected age coverage in report table ", table_id, call. = FALSE)
  }
  x[order(x$year, x$age), , drop = FALSE]
}

input_header <- names(read.csv(file.path(database, "inputs.csv"),
  nrows = 0, check.names = FALSE
))
output_header <- names(read.csv(file.path(database, "outputs.csv"),
  nrows = 0, check.names = FALSE
))
assumption_header <- names(read.csv(file.path(database, "assumptions.csv"),
  nrows = 0, check.names = FALSE
))

new_input <- function(type, measure, basis, year = NA_integer_, age = NA_integer_,
                      value, unit, survey = NA_character_, fleet = NA_character_,
                      season = NA_character_, sampling_time = NA_real_,
                      year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
                      source_type = "official_table", source_reference,
                      transformation = "Transcribed from the official assessment report.",
                      notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(input_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$year <- as.character(rep(year, length.out = n))
  out$year_basis <- as.character(rep(year_basis, length.out = n))
  out$age <- as.character(rep(age, length.out = n))
  out$value <- as.character(value)
  out$unit <- unit
  out$survey <- as.character(rep(survey, length.out = n))
  out$fleet <- as.character(rep(fleet, length.out = n))
  out$season <- as.character(rep(season, length.out = n))
  out$sampling_time <- as.character(rep(sampling_time, length.out = n))
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out[!is.na(value), , drop = FALSE]
}

new_output <- function(assessment, type, measure, year, value, unit,
                       age = NA_integer_, age_group = NA_character_,
                       se = NA_real_, lwr = NA_real_, upr = NA_real_,
                       source_type = "official_table", source_reference,
                       notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(output_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- output_header
  out$assessment_id <- assessment
  out$type <- type
  out$measure <- measure
  out$year <- as.character(rep(year, length.out = n))
  out$age <- as.character(rep(age, length.out = n))
  out$age_group <- as.character(rep(age_group, length.out = n))
  out$value <- as.character(value)
  out$se <- as.character(rep(se, length.out = n))
  out$lwr <- as.character(rep(lwr, length.out = n))
  out$upr <- as.character(rep(upr, length.out = n))
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- notes
  out[!is.na(value), , drop = FALSE]
}

new_assumption <- function(component, setting, value, source_reference, notes = "") {
  out <- as.data.frame(matrix(NA_character_, nrow = 1L, ncol = length(assumption_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- assumption_header
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

report_url <- "https://doi.org/10.17895/ices.pub.30233824"
benchmark_url <- "https://doi.org/10.17895/ices.pub.29279615"

catch_raw <- read_age_table("4.4.3.1", c(0:14, 15L))
catch_raw <- catch_raw[catch_raw$year %in% 1988:2024 & catch_raw$age >= 2, ]
catch_weights <- read_age_table("4.4.4.1", c(0:14, 15L))
catch_weights <- catch_weights[catch_weights$year %in% 1988:2024 & catch_weights$age >= 2, ]
stock_weights <- read_age_table("4.4.4.2", c(0:14, 15L))
stock_weights <- stock_weights[stock_weights$year %in% 1988:2024 & stock_weights$age >= 2, ]
maturity <- read_age_table("4.4.5.1", c(0:14, 15L))
maturity <- maturity[maturity$year %in% 1950:2025 & maturity$age >= 2, ]

inputs <- list(
  new_input("catch", "numbers_at_age", "numbers", catch_raw$year, catch_raw$age,
    catch_raw$value, "thousand fish",
    fleet = "Total catch",
    source_reference = paste(report_url, "Table 4.4.3.1"),
    transformation = "The source table reports ages 0-14 and 15+. Ages above the model plus group are retained separately here and summed in translation."
  ),
  new_input("catch_weight", "weight_at_age", "kg_per_fish", catch_weights$year,
    catch_weights$age, catch_weights$value, "kg per fish",
    fleet = "Total catch", source_reference = paste(report_url, "Table 4.4.4.1"),
    notes = "Original report age groups 0-14 and 15+; values are retained as reported."
  ),
  new_input("weight", "weight_at_age", "kg_per_fish", stock_weights$year,
    stock_weights$age, stock_weights$value, "kg per fish",
    source_reference = paste(report_url, "Table 4.4.4.2"),
    notes = "Annual stock weight-at-age values. tinyAM uses the published age-12 value for its 12+ group; older age-specific source values remain recorded."
  ),
  new_input("maturity", "maturity_at_age", "proportion", maturity$year,
    maturity$age, maturity$value, "proportion",
    year_basis = "birth_cohort", source_reference = paste(report_url, "Table 4.4.5.1"),
    notes = "Rows are birth cohorts: the report states maturity varies by cohort size and identifies 2020 as a cohort whose back-calculated values were not updated."
  ),
  new_input("M", "natural_mortality_at_age", "per_year", NA_integer_, 2:15,
    c(0.9, rep(0.15, 13)), "per year",
    year_basis = NA_character_, source_type = "official_document",
    source_reference = paste(report_url, "section 4.4.6"),
    notes = "Reported standard values are M=0.9 at age 2 and M=0.15 at ages 3+. The report points to stock-annex time-series deviations, which are not recovered in this age-only surface."
  )
)

nasf <- read_age_table("4.4.7.1", c(3:11, 12L))
iesns_barents <- read_age_table("4.4.7.2", 1:5)
iesns_norwegian <- read_age_table("4.4.7.3", c(3:11, 12L))
bess <- read_age_table("4.4.7.4", 2:3)
index_spec <- list(
  list(
    data = nasf[nasf$year %in% 1988:2008, ], survey = "NASF_1988_2008",
    season = "February-March", time = 0.13, unit = "billion fish",
    ref = "Table 4.4.7.1"
  ),
  list(
    data = nasf[nasf$year %in% 2015:2024, ], survey = "NASF_2015_onward",
    season = "February-March", time = 0.13, unit = "billion fish",
    ref = "Table 4.4.7.1"
  ),
  list(
    data = iesns_barents[iesns_barents$age == 2 & iesns_barents$year <= 2024, ],
    survey = "IESNS_Barents", season = "May-June", time = 0.42,
    unit = "billion fish", ref = "Table 4.4.7.2"
  ),
  list(
    data = iesns_norwegian[iesns_norwegian$year %in% 1996:2024, ],
    survey = "IESNS_Norwegian_Sea", season = "May", time = 0.38,
    unit = "million fish", ref = "Table 4.4.7.3"
  ),
  list(
    data = bess[bess$year %in% 2004:2024, ], survey = "BESS",
    season = "August-October", time = 0.75, unit = "billion fish",
    ref = "Table 4.4.7.4"
  )
)
for (spec in index_spec) {
  rows <- spec$data[!is.na(spec$data$value), , drop = FALSE]
  inputs[[length(inputs) + 1L]] <- new_input(
    "index", "numbers_at_age", "numbers", rows$year, rows$age, rows$value,
    spec$unit,
    survey = spec$survey, season = spec$season,
    sampling_time = spec$time, source_reference = paste(report_url, spec$ref),
    transformation = "Direct age-specific abundance estimate copied from the report table.",
    notes = paste(
      "Approximate timing from the reported season:", spec$season,
      "(", spec$time, "of year). Index ages above the tinyAM plus group are summed."
    )
  )
}

add_rse <- function(table_id, ages, survey = NA_character_, fleet = NA_character_,
                    years = 1988:2024) {
  x <- read_age_table(table_id, ages)
  x <- x[x$year %in% years & !is.na(x$value), , drop = FALSE]
  new_input(ifelse(is.na(survey), "catch", "index"),
    "relative_standard_error", "relative_scale", x$year, x$age,
    x$value, "relative standard error",
    survey = survey, fleet = fleet,
    source_reference = paste(report_url, paste("Table", table_id)),
    transformation = "Relative standard errors are retained as published; tinyAM does not apply these external SAM weights.",
    notes = "Source-model sampling precision, not an observation on the abundance scale."
  )
}
inputs[[length(inputs) + 1L]] <- add_rse("4.4.8.1", c(2:11, 12L), fleet = "Total catch")
inputs[[length(inputs) + 1L]] <- add_rse("4.4.8.2", c(3:11, 12L),
  survey = "NASF_1988_2008",
  years = 1988:2008
)
inputs[[length(inputs) + 1L]] <- add_rse("4.4.8.2", c(3:11, 12L),
  survey = "NASF_2015_onward",
  years = 2015:2024
)
inputs[[length(inputs) + 1L]] <- add_rse("4.4.8.3", 2L,
  survey = "IESNS_Barents",
  years = 1991:2024
)
inputs[[length(inputs) + 1L]] <- add_rse("4.4.8.4", c(3:11, 12L),
  survey = "IESNS_Norwegian_Sea",
  years = 1996:2024
)
inputs[[length(inputs) + 1L]] <- add_rse("4.4.8.5", c(3:11, 12L),
  survey = "RFID",
  years = 2017:2023
)

assumptions <- do.call(rbind, list(
  new_assumption("assessment", "assessment_type", "Annual official assessment", report_url),
  new_assumption(
    "assessment", "model_family", "SAM", report_url,
    "WGWIDE 2025 says the assessment uses the SAM platform with the WKBMACNSSH 2025 configuration."
  ),
  new_assumption("assessment", "framework_year", "2025", benchmark_url),
  new_assumption(
    "population", "model_years", "1988-2024", report_url,
    "Catch-at-age precision and official output summaries support this fitted historical period."
  ),
  new_assumption(
    "population", "model_ages", "2-12+", report_url,
    "The official N and F output tables report ages 2-11 and 12+; source catch/biology tables retain age groups through 15+."
  ),
  new_assumption("population", "recruitment_age", "2", report_url),
  new_assumption("population", "plus_group_age", "12", report_url),
  new_assumption("catch", "catch_streams", "One aggregate catch-at-age series", report_url),
  new_assumption(
    "catch", "observation_error", "Lognormal with age-year sampling uncertainty", report_url,
    "Published relative standard errors are retained, but tinyAM fits its own observation SDs."
  ),
  new_assumption(
    "F", "process", "SAM state-space F process; exact transition keys unresolved", benchmark_url,
    "The official native SAM configuration was not recovered."
  ),
  new_assumption("F", "Fbar_ages", "5-12+", report_url),
  new_assumption(
    "N", "process", "SAM state-space abundance process; exact transition keys unresolved", benchmark_url,
    "The official native SAM configuration was not recovered."
  ),
  new_assumption(
    "M", "natural_mortality", "0.9 at age 2; 0.15 at ages 3+", report_url,
    "The report also points to stock-annex time-series deviations; those annual adjustments are not recovered."
  ),
  new_assumption(
    "maturity", "maturity_basis", "Birth cohort by age", report_url,
    "The report describes cohort-size-dependent maturity and identifies strong cohorts."
  ),
  new_assumption("weight", "stock_weight", "Annual stock weight-at-age", report_url),
  new_assumption("weight", "catch_weight", "Annual catch weight-at-age", report_url),
  new_assumption(
    "index", "surveys", "NASF, IESNS Barents, IESNS Norwegian Sea, BESS, and RFID", report_url,
    "NASF is split into pre-2015 and 2015-onward series in the benchmark. RFID point estimates are available only in a figure, so numerical rows are not fabricated."
  ),
  new_assumption(
    "index", "missing_observation_year", "IESNS Barents Sea: 2008", report_url,
    "Table 4.4.7.2 has no abundance-at-age values for 2008; no observation is added for that year."
  ),
  new_assumption(
    "index", "IESNS_Barents_model_age", "2", report_url,
    "The abundance table lists ages 1-5, but the relative-standard-error table used by SAM provides a value only for age 2; only age 2 is recorded as an official-model index input."
  ),
  new_assumption(
    "index", "survey_timing", "Approximate seasonal midpoints", report_url,
    "NASF 0.13; IESNS Barents 0.42; IESNS Norwegian Sea 0.38; BESS 0.75. Exact official fleet settings were not recovered."
  ),
  new_assumption(
    "index", "external_precision", "Relative standard errors", report_url,
    "Tables 4.4.8.2-5 report relative errors used for SAM weighting; tinyAM currently does not apply these external weights."
  ),
  new_assumption(
    "index", "catchability_structure", "Unknown", benchmark_url,
    "Native q-sharing keys were not recoverable without the official configuration."
  ),
  new_assumption(
    "assessment", "newer_summary_only_assessment", "2026", "https://doi.org/10.17895/ices.advice.30932075",
    "The 2026 advice has summary output available via ICES Stock Assessment Graphs; detailed official inputs and native fit were not recovered."
  )
))

stock_row <- data.frame(
  stock_id = "ices_herring_norwegian_spring_spawning",
  charbonneau_id = "",
  authority = "ICES",
  authority_stock_id = "her.27.1-24a514a",
  scientific_name = "Clupea harengus",
  common_name = "Norwegian spring-spawning herring",
  area = "ICES subareas 1, 2, and 5; divisions 4.a and 14.a",
  region = "Northeast Atlantic and Arctic Ocean",
  ocean = "Northeast Atlantic",
  notes = "No matching Charbonneau-Keith stock entry was found in the current curated database.",
  stringsAsFactors = FALSE
)
assessment_rows <- data.frame(
  assessment_id = c(assessment_id, summary_id),
  stock_id = "ices_herring_norwegian_spring_spawning",
  assessment_year = c("2025", "2026"),
  terminal_year = c("2024", "2025"),
  estimate_terminal_year = c("2025", "2026"),
  assessment_type = c("annual_assessment", "assessment_update"),
  model_family = c("SAM", "SAM"),
  model_version = c("WKBMACNSSH 2025 configuration; native fit not recovered", "Not reported"),
  is_current = c("TRUE", "FALSE"),
  is_applied = c("TRUE", "TRUE"),
  framework_year = c("2025", "2025"),
  assessment_url = c(report_url, "https://doi.org/10.17895/ices.advice.30932075"),
  framework_url = c(benchmark_url, benchmark_url),
  data_url = c(
    "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21106",
    "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25912"
  ),
  model_url = c("", ""),
  repository_url = c("", ""),
  assumptions_status = c("partial", "partial"),
  inputs_status = c("partial", "partial"),
  outputs_status = c("partial", "partial"),
  notes = c(
    "Most recent official assessment with detailed source material. Fitted catch terminal is 2024; reported age-specific N/F and summary outputs extend through 2025. Missing numerical RFID index values, full stock-annex M adjustments, exact fitted model settings, and complete native uncertainty remain unresolved.",
    "Newer official assessment is represented by published summary time series only. Its values remain attached only to the 2026 assessment and are not used to fill or overwrite the 2025 detailed record."
  ),
  stringsAsFactors = FALSE
)

n_surface <- read_age_table("4.5.1.2", c(2:11, 12L))
f_surface <- read_age_table("4.5.1.3", c(2:11, 12L))
n_surface <- n_surface[n_surface$year %in% 1988:2025, ]
f_surface <- f_surface[f_surface$year %in% 1988:2025, ]
summary <- read_report_table("4.5.1.4", 10L)
if (!identical(as.integer(summary$year), 1988:2025)) {
  stop("The official summary table does not cover 1988-2025.", call. = FALSE)
}
names(summary)[2:11] <- c(
  "recruitment", "recruitment_high", "recruitment_low",
  "SSB", "SSB_high", "SSB_low", "catch", "Fbar",
  "Fbar_high", "Fbar_low"
)
summary <- summary[summary$year %in% 1988:2025, ]

outputs <- list(
  new_output(assessment_id, "population", "numbers_at_age", n_surface$year,
    n_surface$value, "million fish",
    age = n_surface$age,
    age_group = ifelse(n_surface$age == 12, "12+", NA_character_),
    source_reference = paste(report_url, "Table 4.5.1.2"),
    notes = "Point estimates from the official SAM report table; no age-specific uncertainty was tabulated."
  ),
  new_output(assessment_id, "mortality", "fishing_mortality_at_age", f_surface$year,
    f_surface$value, "per year",
    age = f_surface$age,
    age_group = ifelse(f_surface$age == 12, "12+", NA_character_),
    source_reference = paste(report_url, "Table 4.5.1.3"),
    notes = "Point estimates from the official SAM report table; no age-specific uncertainty was tabulated."
  ),
  new_output(assessment_id, "recruitment", "recruitment", summary$year,
    summary$recruitment, "million fish",
    age = 2,
    lwr = summary$recruitment_low, upr = summary$recruitment_high,
    source_reference = paste(report_url, "Table 4.5.1.4"),
    notes = "Approximate 95% confidence limits; recruitment is at age 2."
  ),
  new_output(assessment_id, "biomass", "SSB", summary$year, summary$SSB,
    "thousand tonnes",
    lwr = summary$SSB_low, upr = summary$SSB_high,
    source_reference = paste(report_url, "Table 4.5.1.4"),
    notes = "Approximate 95% confidence limits, copied from the report."
  ),
  new_output(assessment_id, "catch", "total_biomass", summary$year, summary$catch,
    "tonnes",
    source_reference = paste(report_url, "Table 4.5.1.4"),
    notes = "Annual total catch from the assessment summary; catch-at-age remains the key input."
  ),
  new_output(assessment_id, "mortality", "Fbar", summary$year, summary$Fbar,
    "per year",
    age_group = "5-12+",
    lwr = summary$Fbar_low, upr = summary$Fbar_high,
    source_reference = paste(report_url, "Table 4.5.1.4"),
    notes = "Fbar ages 5-12+; approximate 95% confidence limits."
  )
)

xml_path <- file.path(cache, "ices_stock_assessment_graph_data_25912.xml")
doc <- xml2::read_xml(xml_path)
nodes <- xml2::xml_find_all(doc, ".//*[local-name()='SAGDownload']")
xml_value <- function(node, name) {
  value <- xml2::xml_find_first(node, paste0("./*[local-name()='", name, "']"))
  if (inherits(value, "xml_missing")) NA_character_ else xml2::xml_text(value)
}
summary_xml <- lapply(nodes, function(node) {
  fields <- c(
    "Year", "Recruitment", "Low_Recruitment", "High_Recruitment",
    "TBiomass", "Low_TBiomass", "High_TBiomass",
    "StockSize", "Low_StockSize", "High_StockSize", "Catches",
    "FishingPressure", "Low_FishingPressure", "High_FishingPressure"
  )
  setNames(lapply(fields, function(field) xml_value(node, field)), fields)
})
summary_xml <- as.data.frame(do.call(rbind, lapply(summary_xml, unlist)),
  stringsAsFactors = FALSE
)
summary_xml[] <- lapply(summary_xml, function(x) suppressWarnings(as.numeric(x)))
summary_xml <- summary_xml[summary_xml$Year %in% 1988:2026, ]
outputs[[length(outputs) + 1L]] <- new_output(
  summary_id, "recruitment", "recruitment", summary_xml$Year,
  summary_xml$Recruitment, "thousand fish",
  lwr = summary_xml$Low_Recruitment, upr = summary_xml$High_Recruitment,
  source_type = "official_machine_readable",
  source_reference = "ICES Stock Assessment Graphs, assessment key 25912",
  notes = "2026 official assessment summary only; not combined with 2025 detailed outputs."
)
outputs[[length(outputs) + 1L]] <- new_output(
  summary_id, "biomass", "total_biomass", summary_xml$Year,
  summary_xml$TBiomass, "tonnes",
  lwr = summary_xml$Low_TBiomass,
  upr = summary_xml$High_TBiomass, source_type = "official_machine_readable",
  source_reference = "ICES Stock Assessment Graphs, assessment key 25912",
  notes = "Published total biomass; low/high interval level is not specified in the XML."
)
outputs[[length(outputs) + 1L]] <- new_output(
  summary_id, "biomass", "SSB", summary_xml$Year,
  summary_xml$StockSize, "tonnes",
  lwr = summary_xml$Low_StockSize,
  upr = summary_xml$High_StockSize, source_type = "official_machine_readable",
  source_reference = "ICES Stock Assessment Graphs, assessment key 25912",
  notes = "2026 official assessment summary only; not combined with 2025 detailed outputs."
)
outputs[[length(outputs) + 1L]] <- new_output(
  summary_id, "catch", "total_biomass", summary_xml$Year,
  summary_xml$Catches, "tonnes",
  source_type = "official_machine_readable",
  source_reference = "ICES Stock Assessment Graphs, assessment key 25912",
  notes = "Published total catch; summary output only."
)
outputs[[length(outputs) + 1L]] <- new_output(
  summary_id, "mortality", "Fbar", summary_xml$Year,
  summary_xml$FishingPressure, "per year",
  age_group = "5-12+",
  lwr = summary_xml$Low_FishingPressure, upr = summary_xml$High_FishingPressure,
  source_type = "official_machine_readable",
  source_reference = "ICES Stock Assessment Graphs, assessment key 25912",
  notes = "Published aggregate F; exact 2026 fitted age range is not reported in the summary data."
)

check_append <- function(path, rows, key, ids) {
  existing <- read.csv(path,
    colClasses = "character", na.strings = "",
    check.names = FALSE
  )
  if (!identical(names(existing), names(rows))) {
    stop("Unexpected columns in ", basename(path), call. = FALSE)
  }
  if (any(existing[[key]] %in% ids)) {
    stop("Assessment rows already exist in ", basename(path),
      "; refusing to duplicate them.",
      call. = FALSE
    )
  }
}
append_rows <- function(path, rows) {
  utils::write.table(rows, path,
    sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}

input_rows <- do.call(rbind, inputs)
output_rows <- do.call(rbind, outputs)
stock_path <- file.path(database, "stocks.csv")
stock_existing <- read.csv(stock_path,
  colClasses = "character", na.strings = "",
  check.names = FALSE
)
if (any(stock_existing$stock_id == stock_row$stock_id)) {
  stop("Norwegian spring-spawning herring stock already exists.", call. = FALSE)
}
paths <- file.path(database, c(
  "assessments.csv", "assumptions.csv",
  "inputs.csv", "outputs.csv"
))
rows <- list(assessment_rows, assumptions, input_rows, output_rows)
ids <- list(
  c(assessment_id, summary_id), assessment_id, assessment_id,
  c(assessment_id, summary_id)
)
for (i in seq_along(paths)) {
  check_append(paths[[i]], rows[[i]], "assessment_id", ids[[i]])
}
if (!identical(names(stock_existing), names(stock_row))) {
  stop("Unexpected columns in stocks.csv.", call. = FALSE)
}

utils::write.table(stock_row, stock_path,
  sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
)
for (i in seq_along(paths)) append_rows(paths[[i]], rows[[i]])

cat(
  "Added", nrow(input_rows), "input rows and", nrow(output_rows),
  "output rows for Norwegian spring-spawning herring.\n"
)
