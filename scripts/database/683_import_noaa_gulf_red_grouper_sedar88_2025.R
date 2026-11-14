stock_id <- "noaa_red_grouper_gom"
assessment_id <- paste0(stock_id, "_sedar88_2025")
candidate_id <- "NOAA:10331"
cache_name <- "discovery_noaa_red_grouper_gom_2025"
report_file <- "sedar_88_red_grouper_final_updated_2025.pdf"
report_url <- "https://sedarweb.org/documents/sedar-88-gulf-of-mexico-red-grouper-final-stock-assessment-report-updated-december-2025/"
project_url <- "https://sedarweb.org/assessments/sedar-88-gulf-of-mexico-red-grouper/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path("source_cache", "R-library"), .libPaths()))
source("scripts/database/pacific_tables.R")
source("scripts/database/candidate_register_io.R")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached SEDAR 88 report.", call. = FALSE)
}

manifest <- read.csv(file.path("provenance", cache_name, "sources.csv"),
  stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
cache_options <- c(file.path("source_cache", cache_name),
  file.path("..", "..", cache_name))
cache <- cache_options[dir.exists(cache_options)][1L]
report_path <- file.path(cache, report_file)
manifest_row <- which(manifest$file == report_file)
expected_sha <- "17c2c2a6b95e1adce8fb2f0e3fd6ddd08cb838ef2a42fe1b441d1b512159a0ba"
if (length(manifest_row) != 1L || !file.exists(report_path) ||
    manifest$retrieved_on[manifest_row] != "2026-10-29" ||
    as.numeric(manifest$bytes[manifest_row]) != file.info(report_path)$size ||
    tolower(manifest$sha256[manifest_row]) != expected_sha ||
    tolower(unname(tools::sha256sum(report_path))) != expected_sha) {
  stop("The cached corrected SEDAR 88 report differs from its provenance manifest.",
    call. = FALSE)
}

pages <- pdftools::pdf_text(report_path)
layout <- pdftools::pdf_data(report_path)
if (length(pages) != 296L) stop("Unexpected page count in the corrected SEDAR 88 report.",
  call. = FALSE)

number_tokens <- function(line) {
  pattern <- "(?<![[:alnum:]])(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?"
  tokens <- regmatches(line, gregexpr(pattern, line, perl = TRUE))[[1L]]
  if (length(tokens) == 1L && tokens == "") return(numeric())
  as.numeric(gsub(",", "", tokens, fixed = TRUE))
}

annual_table <- function(page_ids, years, n_values, label) {
  lines <- unlist(lapply(page_ids, function(page_id) {
    strsplit(pages[[page_id]], "\n", fixed = TRUE)[[1L]]
  }), use.names = FALSE)
  lines <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines,
    perl = TRUE)]
  rows <- list()
  for (line in lines) {
    values <- number_tokens(line)
    if (length(values) != n_values + 1L || !values[[1L]] %in% years) next
    rows[[length(rows) + 1L]] <- values
  }
  if (!length(rows)) stop("No annual rows parsed from ", label, ".", call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", paste0("value", seq_len(n_values)))
  out <- out[order(out$year), , drop = FALSE]
  if (anyDuplicated(out$year) || !identical(as.integer(out$year), as.integer(years))) {
    stop(label, " does not contain the expected unique annual coverage.", call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

first_annual_value <- function(page_ids, years, label) {
  lines <- unlist(lapply(page_ids, function(page_id) {
    strsplit(pages[[page_id]], "\n", fixed = TRUE)[[1L]]
  }), use.names = FALSE)
  lines <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines,
    perl = TRUE)]
  rows <- list()
  for (line in lines) {
    values <- number_tokens(line)
    if (length(values) < 2L || !values[[1L]] %in% years) next
    rows[[length(rows) + 1L]] <- values[1:2]
  }
  if (!length(rows)) stop("No annual rows parsed from ", label, ".", call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "value")
  out <- out[order(out$year), , drop = FALSE]
  if (anyDuplicated(out$year) || !identical(as.integer(out$year), as.integer(years))) {
    stop(label, " does not contain the expected unique annual coverage.", call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

age_mortality <- function() {
  lines <- strsplit(pages[[92L]], "\n", fixed = TRUE)[[1L]]
  lines <- lines[grepl("^[[:space:]]*[0-9]{1,2}[[:space:]]+", lines, perl = TRUE)]
  rows <- list()
  for (line in lines) {
    values <- number_tokens(line)
    age <- as.integer(values[[1L]])
    if (!age %in% 0:29) next
    mortality <- if (length(values) == 5L) values[[3L]] else if (length(values) == 4L) values[[2L]] else NA_real_
    if (!is.finite(mortality)) stop("Unexpected Table 4 row: ", line, call. = FALSE)
    rows[[length(rows) + 1L]] <- c(age = age, value = mortality)
  }
  if (length(rows) != 30L) stop("SEDAR 88 Table 4 must cover ages 0-29.", call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  out$age <- as.integer(out$age)
  out$value <- as.numeric(out$value)
  out <- out[order(out$age), , drop = FALSE]
  if (!identical(out$age, 0:29) || out$value[1L] != 1.09 ||
      out$value[out$age == 29L] != 0.15) {
    stop("SEDAR 88 Table 4 age-specific M values failed source checks.", call. = FALSE)
  }
  out
}

index_table <- function() {
  centers <- seq(116, 512, by = 36)
  series <- c("Commercial Handline CPUE", "Commercial Longline CPUE",
    "Recreational Headboat", "Combined Video Survey",
    "SEAMAP Summer Groundfish Survey", "NMFS Bottom Longline Survey")
  rows <- list()
  numeric_pattern <- "^[0-9]+(\\.[0-9]+)?$"
  for (page_id in 101:102) {
    p <- layout[[page_id]]
    years <- p[grepl("^(19|20)[0-9]{2}$", trimws(p$text)) & p$x < 100, , drop = FALSE]
    for (i in seq_len(nrow(years))) {
      year <- as.integer(years$text[i])
      if (!year %in% 1986:2022) next
      cells <- p[abs(p$y - years$y[i]) < 1 & p$x > 100 &
        grepl(numeric_pattern, trimws(p$text)), , drop = FALSE]
      values <- rep(NA_real_, length(centers))
      for (j in seq_len(nrow(cells))) {
        col <- which.min(abs(centers - cells$x[j]))
        if (abs(centers[col] - cells$x[j]) > 8 || !is.na(values[col])) {
          stop("Unexpected or duplicate Table 10 cell in year ", year, ".", call. = FALSE)
        }
        values[col] <- as.numeric(cells$text[j])
      }
      for (s in seq_along(series)) {
        value <- values[(s - 1L) * 2L + 1L]
        log_sd <- values[(s - 1L) * 2L + 2L]
        if (xor(is.na(value), is.na(log_sd))) {
          stop("Table 10 index and log-SE cells do not align for ", series[s],
            " in ", year, ".", call. = FALSE)
        }
        if (!is.na(value)) rows[[length(rows) + 1L]] <-
          data.frame(year = year, survey = series[s], value = value,
            log_sd = log_sd, stringsAsFactors = FALSE)
      }
    }
  }
  if (!length(rows)) stop("No Table 10 index rows were extracted.", call. = FALSE)
  out <- do.call(rbind, rows)
  if (anyDuplicated(paste(out$survey, out$year, sep = "\r"))) {
    stop("Table 10 contains duplicate index series-year cells.", call. = FALSE)
  }
  out[order(out$survey, out$year), , drop = FALSE]
}

commercial_landings <- annual_table(93:94, 1986:2022, 4L, "Table 5 commercial landings")
recreational <- annual_table(96:97, 1986:2022, 8L, "Table 7 recreational landings and discards")
private_mode <- annual_table(98:99, 1986:2022, 6L, "Table 8 SRFS private-mode landings")
commercial_discards <- annual_table(100L, 1993:2022, 4L, "Table 9 commercial discards")
indices <- index_table()
m_at_age <- age_mortality()
exploitation_total <- first_annual_value(114:115, 1986:2022, "Table 13 total exploitation")
exploitation_fleet <- annual_table(116:117, 1986:2022, 6L, "Table 14 fleet exploitation")
population <- annual_table(118:119, 1986:2022, 6L, "Table 15 population outputs")

blank_row <- function(table, values) {
  fields <- names(read.csv(file.path("database", paste0(table, ".csv")),
    nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  row <- as.data.frame(setNames(rep(list(""), length(fields)), fields),
    stringsAsFactors = FALSE, check.names = FALSE)
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  row
}

stock <- blank_row("stocks", list(
  stock_id = stock_id,
  authority = "NOAA Fisheries",
  authority_stock_id = "10331",
  scientific_name = "Epinephelus morio",
  common_name = "Red grouper - Gulf of Mexico",
  area = "Gulf of Mexico",
  region = "Gulf of Mexico",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10331; distinct from the South Atlantic red grouper unit 10332."
))
assessment <- blank_row("assessments", list(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2025L,
  terminal_year = 2022L,
  estimate_terminal_year = 2022L,
  assessment_type = "operational_assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.21.0",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2025L,
  assessment_url = report_url,
  framework_url = project_url,
  data_url = project_url,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "SEDAR 88 is the latest full production assessment located for NOAA unit 10331. The corrected December 2025 report covers data through 2022. Numeric fishery age-composition matrices and age-specific survey indices were not recovered; annual numeric N-at-age and F-at-age surfaces and output uncertainty are not tabulated."
))

input_rows <- list()
output_rows <- list()
assumption_rows <- list()
add_input <- function(...) {
  args <- list(...)
  args$assessment_id <- assessment_id
  if (is.null(args$region)) args$region <- "Gulf of Mexico"
  if (is.null(args$source_type)) args$source_type <- "official_table"
  input_rows[[length(input_rows) + 1L]] <<- do.call(pacific_database_row,
    c(list(table = "inputs"), args))
}
add_output <- function(...) {
  args <- list(...)
  args$assessment_id <- assessment_id
  if (is.null(args$region)) args$region <- "Gulf of Mexico"
  if (is.null(args$source_type)) args$source_type <- "official_table"
  output_rows[[length(output_rows) + 1L]] <<- do.call(pacific_database_row,
    c(list(table = "outputs"), args))
}
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row(
    "assumptions", assessment_id = assessment_id, component = component,
    region = "Gulf of Mexico", setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}

commercial_fleets <- c("Commercial Handline", "Commercial Longline",
  "Commercial Other (reported component)", "Commercial Trap")
for (j in seq_along(commercial_fleets)) {
  value <- commercial_landings[[paste0("value", j)]]
  fleet <- commercial_fleets[j]
  partition <- "reported_component"
  source_type <- "official_table"
  note <- "Reported commercial landings in pounds gutted weight."
  if (j == 1L) {
    value <- value + commercial_landings$value3
    partition <- "assessment_input"
    source_type <- "reconstructed_source_input"
    note <- "Commercial handline assessment input reconstructed by adding the reported Other-gear landings, which the report says were lumped into Handline."
  }
  if (j == 2L) {
    partition <- "assessment_input"
    note <- "Commercial longline landings input in pounds gutted weight."
  }
  if (j == 4L) {
    partition <- "assessment_input"
    note <- "Commercial trap landings input in pounds gutted weight."
  }
  add_input(type = "catch", measure = "landings_biomass", basis = "biomass",
    fleet = fleet, year = commercial_landings$year, year_basis = "calendar_year",
    season = "annual", value = value, unit = "pounds gutted weight",
    partition = partition, source_type = source_type,
    source_reference = "SEDAR 88 corrected final report, Section III, Table 5, pp. 62-63",
    notes = note)
}
add_input(type = "catch", measure = "landings_biomass", basis = "biomass",
  fleet = "Commercial Handline (reported component)",
  year = commercial_landings$year, year_basis = "calendar_year", season = "annual",
  value = commercial_landings$value1, unit = "pounds gutted weight",
  partition = "reported_component", source_type = "official_table",
  source_reference = "SEDAR 88 corrected final report, Section III, Table 5, pp. 62-63",
  notes = "Reported Handline column before adding the Other-gear component for the assessment input.")

rec_year <- recreational$year
rec_specs <- list(
  list(measure = "landings_numbers", basis = "numbers", value = recreational$value1,
    unit = "fish", partition = "aggregate_landings", note = "Aggregate recreational landings in numbers."),
  list(measure = "landings_biomass", basis = "biomass", value = recreational$value3,
    unit = "pounds gutted weight", partition = "aggregate_landings", note = "Aggregate recreational landings in pounds gutted weight."),
  list(measure = "discard_numbers", basis = "numbers", value = recreational$value4,
    unit = "fish", partition = "aggregate_discards", note = "Aggregate recreational discards in numbers."),
  list(measure = "catch_cv", basis = "relative_scale", value = recreational$value2,
    unit = "ratio", partition = "aggregate_landings", note = "Source CV ratio for aggregate recreational landings."),
  list(measure = "catch_cv", basis = "relative_scale", value = recreational$value5,
    unit = "ratio", partition = "aggregate_discards", note = "Source CV ratio for aggregate recreational discards.")
)
for (x in rec_specs) {
  add_input(type = "catch", measure = x$measure, basis = x$basis,
    fleet = "Recreational", year = rec_year, year_basis = "calendar_year",
    season = "annual", value = x$value, unit = x$unit, partition = x$partition,
    source_reference = "SEDAR 88 corrected final report, Section III, Table 7, pp. 65-66",
    notes = x$note)
}
for (j in 1:3) {
  mode <- c("Charter boat", "Headboat", "Private mode")[j]
  add_input(type = "catch", measure = "landings_numbers", basis = "numbers",
    fleet = "Recreational", year = rec_year, year_basis = "calendar_year",
    season = "annual", value = recreational[[paste0("value", j + 5L)]],
    unit = "fish", partition = paste0("mode_component_", tolower(gsub(" ", "_", mode))),
    source_reference = "SEDAR 88 corrected final report, Section III, Table 7, pp. 65-66",
    notes = paste("Reported recreational landings component for", mode,
      "; this partitions the aggregate landings row and is not an additional total."))
}

private_specs <- list(
  list(measure = "landings_biomass", basis = "biomass", value = private_mode$value1,
    unit = "pounds whole weight", partition = "SRFS_private_landings", note = "Source-reported SRFS private-mode landings in whole weight."),
  list(measure = "landings_numbers", basis = "numbers", value = private_mode$value2,
    unit = "fish", partition = "SRFS_private_landings", note = "Source-reported SRFS private-mode landings in numbers."),
  list(measure = "mean_body_weight", basis = "weight_per_fish", value = private_mode$value3,
    unit = "pounds whole weight per fish", partition = "SRFS_private_mean_weight_whole", note = "Source-reported private-mode mean whole weight per fish."),
  list(measure = "mean_body_weight", basis = "weight_per_fish", value = private_mode$value4,
    unit = "pounds gutted weight per fish", partition = "SRFS_private_mean_weight_gutted", note = "Source-reported private-mode mean gutted weight per fish."),
  list(measure = "mean_body_weight_cv", basis = "relative_scale", value = private_mode$value5,
    unit = "coefficient of variation", partition = "SRFS_private_mean_weight_cv", note = "Source-reported CV for the private-mode mean gutted weight."),
  list(measure = "discard_numbers", basis = "numbers", value = private_mode$value6,
    unit = "fish", partition = "SRFS_private_discards", note = "Source-reported SRFS private-mode discards in numbers.")
)
for (x in private_specs) {
  add_input(type = "catch", measure = x$measure, basis = x$basis,
    fleet = "Recreational", year = private_mode$year, year_basis = "calendar_year",
    season = "annual", value = x$value, unit = x$unit, partition = x$partition,
    source_reference = "SEDAR 88 corrected final report, Section III, Table 8, p. 67",
    notes = x$note)
}

for (fleet_data in list(
  list(name = "Commercial Handline", value = commercial_discards$value1,
    se = commercial_discards$value3),
  list(name = "Commercial Longline", value = commercial_discards$value2,
    se = commercial_discards$value4)
)) {
  add_input(type = "catch", measure = "discard_numbers", basis = "numbers",
    fleet = fleet_data$name, year = commercial_discards$year,
    year_basis = "calendar_year", season = "annual", value = fleet_data$value,
    unit = "fish", partition = "commercial_discards",
    source_reference = "SEDAR 88 corrected final report, Section III, Table 9, p. 69",
    notes = "Commercial discard numbers as reported by fleet.")
  add_input(type = "catch", measure = "catch_se", basis = "numbers",
    fleet = fleet_data$name, year = commercial_discards$year,
    year_basis = "calendar_year", season = "annual", value = fleet_data$se,
    unit = "fish", partition = "commercial_discard_se",
    source_reference = "SEDAR 88 corrected final report, Section III, Table 9, p. 69",
    notes = "Source-reported additive standard error for commercial discard numbers.")
}

for (survey_name in unique(indices$survey)) {
  x <- indices[indices$survey == survey_name, , drop = FALSE]
  add_input(type = "index", measure = "relative_abundance_index", basis = "index_scale",
    survey = survey_name, year = x$year, year_basis = "calendar_year",
    value = x$value, unit = "standardized relative abundance index",
    source_reference = "SEDAR 88 corrected final report, Section III, Table 10, pp. 70-71",
    notes = "Aggregate standardized index; no age-specific survey index is tabulated.")
  add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
    survey = survey_name, year = x$year, year_basis = "calendar_year",
    value = x$log_sd, unit = "log-scale standard error",
    source_reference = "SEDAR 88 corrected final report, Section III, Table 10, pp. 70-71",
    notes = "Source-reported log-scale standard error for the standardized index.")
}

add_input(type = "M", measure = "natural_mortality_at_age", basis = "per_year",
  sex = "Female", age = m_at_age$age, value = m_at_age$value, unit = "year^-1",
  source_reference = "SEDAR 88 corrected final report, Section III, Table 4, p. 61",
  notes = "Female age-specific M vector used in SEDAR 88; the assessment applies a Lorenzen schedule with Mtarget = 0.186 year^-1.")

add_output(type = "mortality", measure = "exploitation_rate", year = exploitation_total$year,
  season = "annual", value = exploitation_total$value, unit = "proportion per year",
  source_reference = "SEDAR 88 corrected final report, Section III, Table 13, pp. 84-85",
  notes = "Combined annual exploitation rate, defined as total biomass killed across all ages divided by total biomass age 0+. The assessment uses it as a proxy for annual fishing mortality; it is not instantaneous F.")
fleet_names <- c("Handline", "Longline", "Trap", "Recreational", "Red tide")
for (j in seq_along(fleet_names)) {
  add_output(type = "mortality", measure = "exploitation_rate", fleet = fleet_names[j],
    year = exploitation_fleet$year, season = "annual",
    value = exploitation_fleet[[paste0("value", j)]], unit = "proportion per year",
    source_reference = "SEDAR 88 corrected final report, Section III, Table 14, pp. 85-86",
    notes = "Fleet-specific annual exploitation rate; the source defines this as biomass killed divided by total biomass age 0+. It is not instantaneous F.")
}

output_specs <- list(
  list(type = "biomass", measure = "total_biomass", col = "value1",
    unit = "metric tons", note = "Expected biomass for all Red Grouper."),
  list(type = "biomass", measure = "exploitable_biomass", col = "value2",
    unit = "metric tons", note = "Expected biomass for exploited ages 0+."),
  list(type = "biomass", measure = "SSB", col = "value3",
    unit = "relative number of eggs", note = "Spawning output is reported as relative egg production, not biomass."),
  list(type = "population", measure = "total_numbers", col = "value4",
    unit = "thousand fish", note = "Expected exploitable abundance, ages 0+; the age range begins at age 0."),
  list(type = "recruitment", measure = "recruitment", col = "value5",
    unit = "thousand fish", age = 0L, note = "Expected age-0 recruitment."),
  list(type = "population", measure = "SSB_ratio_to_SSB0", col = "value6",
    unit = "ratio", note = "Source-reported SSB divided by SSB0; SSB is relative egg production.")
)
for (x in output_specs) {
  args <- list(type = x$type, measure = x$measure, year = population$year,
    season = "annual", value = population[[x$col]], unit = x$unit,
    source_reference = "SEDAR 88 corrected final report, Section III, Table 15, pp. 87-88",
    notes = x$note)
  if (!is.null(x$age)) args$age <- x$age
  do.call(add_output, args)
}

add_assumption("assessment", "run_identity",
  "SEDAR 88 Operational Assessment, completed in 2025 with data through 2022; Stock Synthesis 3.30.21.0.",
  "SEDAR 88 corrected final report, cover and Section III; SEDAR project page",
  "The December 10, 2025 revision is used because it corrected Tables 5, 7, 8 and 19.")
add_assumption("model", "model_structure",
  "One Gulf of Mexico stock unit, annual model, ages 0-29.",
  "SEDAR 88 corrected final report, Sections 2.1 and 3.1",
  "NOAA Stock SMART unit 10331 is distinct from South Atlantic red grouper unit 10332.")
add_assumption("catch", "commercial_landings",
  "Commercial landings are reported in pounds gutted weight for Handline, Longline, Other and Trap. Other gears were lumped into Handline for model input.",
  "SEDAR 88 corrected final report, Section III, Table 5, pp. 62-63",
  "The database retains reported Handline and Other components and a separately identified reconstructed Handline assessment input.")
add_assumption("catch", "recreational_landings_and_discards",
  "Table 7 reports aggregate recreational landings, gutted weight, discards and landings by charter, headboat and private modes; Table 8 reports SRFS private-mode landings and discards.",
  "SEDAR 88 corrected final report, Section III, Tables 7-8, pp. 65-67",
  "Aggregate totals, mode components and SRFS private-mode series are kept in distinct partitions; do not sum them together.")
add_assumption("composition", "fishery_age_compositions",
  "Weighted commercial handline, longline and trap, and recreational landing age compositions are used; annual age bins include a 20+ group.",
  "SEDAR 88 corrected final report, Sections 2.3 and 3.1; SEDAR 88 WP-06 and WP-09",
  "Numerical annual composition matrices are shown in figures and were not imported as numeric observations.")
add_assumption("index", "standardized_indices",
  paste(unique(indices$survey), collapse = "; "),
  "SEDAR 88 corrected final report, Section III, Table 10, pp. 70-71",
  "The report tabulates aggregate standardized indices and log-scale standard errors; it does not provide age-specific index series.")
add_assumption("mortality", "natural_mortality",
  "Fixed age-specific female Lorenzen M schedule with Mtarget = 5.4/29 = 0.186 year^-1.",
  "SEDAR 88 corrected final report, Section 2.2.3, Table 4, pp. 17-18 and Table 12, p. 73",
  "The reported age-specific SEDAR 88 M vector is imported; M is an assumed input, not an estimated time-varying process.")
add_assumption("biology", "growth_and_weight",
  "Growth uses a von Bertalanffy model; fixed length-weight conversion parameters were carried forward from SEDAR 42.",
  "SEDAR 88 corrected final report, Section 2.2 and Tables 1-2",
  "A run-matched numerical stock weight-at-age surface is not tabulated and was not derived from fitted outputs.")
add_assumption("biology", "maturity_and_sex_transition",
  "Maturity and female-to-male transition schedules were carried forward from SEDAR 42. Fecundity-at-age is based on proportion female, proportion mature and batch fecundity.",
  "SEDAR 88 corrected final report, Section 2.2.4",
  "Numerical run-matched maturity and transition vectors were not recovered from the reviewed production report.")
add_assumption("biology", "spawning_output_definition",
  "SSB is relative egg production, calculated from the fixed fecundity-at-age vector.",
  "SEDAR 88 corrected final report, Sections 3.1 and 4.8; Table 15",
  "This output is not a biomass-based mature-biomass SSB estimate.")
add_assumption("timing", "observation_and_spawning_timing",
  "The model is annual. SEAMAP indices use summer data; NMFS Bottom Longline samples are primarily August in the eastern Gulf and September in the central/western Gulf, with early October 2022 stations. The combined video index pools surveys sampled in different months.",
  "SEDAR 88 corrected final report, Sections 2.4 and 3.1; SEDAR 88 WP-12, WP-13 and WP-16",
  "The reviewed sources do not establish one fractional timing for the pooled indices; sampling_time is left blank.")
add_assumption("output", "reported_population_outputs",
  "Table 15 reports total and exploitable biomass, relative egg-production SSB, exploitable abundance, age-0 recruitment and SSB/SSB0 for 1986-2022. Tables 13-14 report total and fleet-specific exploitation rates.",
  "SEDAR 88 corrected final report, Section III, Tables 13-15, pp. 84-88",
  "Numeric N-at-age and instantaneous F-at-age appear only in figures; annual uncertainty for the population outputs was not tabulated.")

inputs_new <- do.call(rbind, input_rows)
outputs_new <- do.call(rbind, output_rows)
assumptions_new <- do.call(rbind, assumption_rows)
if (any(!is.finite(as.numeric(inputs_new$value))) ||
    any(!is.finite(as.numeric(outputs_new$value))) ||
    any(!nzchar(inputs_new$source_reference)) ||
    any(!nzchar(outputs_new$source_reference))) {
  stop("Gulf red grouper extraction has missing provenance or non-finite values.",
    call. = FALSE)
}

cat("Prepared ", nrow(inputs_new), " inputs, ", nrow(assumptions_new),
  " assumptions, and ", nrow(outputs_new), " outputs.\n", sep = "")
cat("Parsed Table 5: ", nrow(commercial_landings), " years; Table 7: ",
  nrow(recreational), " years; Table 8: ", nrow(private_mode),
  " years; Table 9: ", nrow(commercial_discards), " years; Table 10: ",
  nrow(indices), " series-year rows; Table 4: ", nrow(m_at_age),
  " ages; Table 15: ", nrow(population), " years.\n", sep = "")
cat("No figure-only age compositions, age-specific survey indices, N-at-age or F-at-age values were digitized or inferred.\n")

if (write_mode) {
  stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (any(stocks$stock_id == stock_id, na.rm = TRUE) ||
      any(stocks$authority_stock_id == "10331", na.rm = TRUE) ||
      any(assessments$assessment_id == assessment_id, na.rm = TRUE)) {
    stop("Gulf red grouper stock or assessment already exists.", call. = FALSE)
  }
  if (nrow(stock) != 1L || nrow(assessment) != 1L) {
    stop("Expected exactly one stock row and one assessment row.", call. = FALSE)
  }
  candidates_path <- "discovery/candidates.csv"
  inventory_path <- "discovery/inventory_units.csv"
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), colClasses = "character", check.names = FALSE)
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), colClasses = "character", check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  ii <- candidate_inventory_row(inventory, candidate_id, stock_id)
  if (length(ci) != 1L || candidates$eligibility[ci] != "eligible" ||
      candidates$import_status[ci] != "not_started") {
    stop("NOAA:10331 candidate status changed before import.", call. = FALSE)
  }

  append_pacific_case(stock, assessment, assumptions_new, inputs_new, outputs_new)
  candidate_update <- candidates[ci, , drop = FALSE]
  candidate_update$matched_stock_id <- stock_id
  candidate_update$match_status <- "new"
  candidate_update$import_status <- "partial"
  candidate_update$review_date <- "2026-11-13"
  candidate_update$decision_reason <- paste(
    "Partial source import completed from the corrected SEDAR 88 production report.",
    "Annual catches/discards, aggregate CPUE indices, age-specific M, assumptions,",
    "exploitation rates and population summary outputs are preserved. Figure-only",
    "age compositions, age-specific survey indices and numerical N/F-at-age remain gaps."
  )
  candidate_update$notes <- paste(
    "Canonical input values preserve reported source partitions and a separately",
    "identified Handline assessment input including Other gears. Figure-only age",
    "compositions and unavailable surfaces were not digitized or inferred."
  )
  replace_candidate_register_row(candidates_path, ci, candidate_update, candidate_id)
  inventory_update <- inventory[ii, , drop = FALSE]
  inventory_update$matched_stock_id <- stock_id
  inventory_update$match_status <- "new"
  inventory_update$import_status <- "partial"
  replace_csv_register_row(inventory_path, ii, inventory_update, "unit_key",
    inventory$unit_key[ii])
  batch_path <- "discovery/selected_batch_41_2026.csv"
  batch <- read.csv(batch_path, stringsAsFactors = FALSE, check.names = FALSE)
  batch$curation_status[batch$candidate_id == candidate_id] <- "source_curated_partial"
  batch$selection_basis[batch$candidate_id == candidate_id] <- paste(
    "Imported corrected-report Tables 5, 7-10 and 13-15, age-specific M, and source",
    "assumptions. Numeric age-composition matrices, survey age indices, annual N/F-at-age",
    "and output uncertainty remain unavailable."
  )
  write.csv(batch, batch_path, row.names = FALSE, na = "")
  source("scripts/database/002_validate_database.R", local = new.env(parent = globalenv()))
  cat("Gulf red grouper source records appended and database validation passed.\n")
}
