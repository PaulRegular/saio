assessment_id <- "noaa_south_atlantic_red_snapper_2024"
stock_id <- "noaa_south_atlantic_red_snapper"

read_output_rows <- function() {
  path <- "database/outputs.csv"
  header <- readLines(path, n = 1L, warn = FALSE)
  lines <- system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE)
  status <- attr(lines, "status")
  if (is.null(status)) status <- 0L
  stopifnot(status == 0L, length(lines) > 0L)
  read.csv(text = paste(c(header, lines), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

outputs <- read_output_rows()
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10231", , drop = FALSE]

measure_count <- function(measure) sum(outputs$measure == measure)
get_value <- function(measure, year, age = NA_real_) {
  rows <- outputs[outputs$measure == measure & outputs$year == year, , drop = FALSE]
  if (!is.na(age)) rows <- rows[rows$age == age, , drop = FALSE]
  stopifnot(nrow(rows) == 1L)
  as.numeric(rows$value)
}

stopifnot(
  nrow(assessment) == 1L,
  assessment$is_current %in% c("TRUE", "1"),
  assessment$is_applied %in% c("TRUE", "1"),
  assessment$terminal_year == 2023L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(stock) == 1L,
  stock$authority_stock_id == "10231",
  stock$scientific_name == "Lutjanus campechanus",
  stock$ocean == "Northwest Atlantic",
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(outputs) == 11616L,
  measure_count("numbers_at_age") == 74L * 20L,
  measure_count("total_numbers") == 74L,
  measure_count("recruitment") == 74L,
  measure_count("biomass_at_age") == 74L * 20L,
  measure_count("fishing_mortality_at_age") == 74L * 20L,
  measure_count("apical_F") == 74L,
  measure_count("total_biomass") == 74L,
  measure_count("SSB") == 74L,
  setequal(sort(unique(outputs$year)), 1950:2023),
  setequal(as.numeric(unique(outputs$age[outputs$measure == "numbers_at_age"])), 1:20),
  all(outputs$age_group[!is.na(outputs$age) & outputs$age == 20] == "20+"),
  all(outputs$source_type == "official_table"),
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  get_value("numbers_at_age", 1950, 1) == 482.76,
  get_value("numbers_at_age", 1950, 20) == 148.52,
  get_value("total_numbers", 1950) == 2672.26,
  get_value("recruitment", 1950) == 482.76,
  get_value("fishing_mortality_at_age", 1950, 1) == 0.003,
  get_value("fishing_mortality_at_age", 1950, 20) == 0.013,
  get_value("apical_F", 1950) == 0.013,
  get_value("total_biomass", 1950) == 13597,
  get_value("SSB", 1950) == 1478810,
  all(grepl("SEFSC 2024 update to SEDAR 73", outputs$source_reference, fixed = TRUE)),
  all(grepl("20+", outputs$notes[outputs$measure == "numbers_at_age"], fixed = TRUE))
)

input_lines <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
  "--no-line-number", "-F", assessment_id, "database/inputs.csv"),
  stdout = TRUE, stderr = FALSE))
input_status <- attr(input_lines, "status")
if (is.null(input_status)) input_status <- 0L
stopifnot(input_status == 0L)
input_header <- readLines("database/inputs.csv", n = 1L, warn = FALSE)
inputs <- read.csv(text = paste(c(input_header, input_lines), collapse = "\n"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stopifnot(
  nrow(inputs) == 140L,
  all(table(inputs$measure) == 20L),
  setequal(unique(inputs$age), 1:20),
  all(is.na(inputs$year)),
  all(inputs$source_type == "official_table"),
  all(grepl("SEDAR 73 South Atlantic Red Snapper SAR, Section II, Table 2, p. 45", inputs$source_reference, fixed = TRUE)),
  all(grepl("SEFSC 2024 update to SEDAR 73, Section 2.1, p. 9", inputs$source_reference, fixed = TRUE)),
  !any(inputs$type %in% c("catch", "index")),
  identical(as.numeric(inputs$value[inputs$measure == "weight_at_age" & inputs$age == 1]), 1.2),
  identical(as.numeric(inputs$value[inputs$measure == "maturity_at_age" & inputs$age == 1]), 0.43),
  identical(as.numeric(inputs$value[inputs$measure == "natural_mortality_at_age" & inputs$age == 1]), 0.29),
  identical(as.numeric(inputs$value[inputs$measure == "fecundity_at_age" & inputs$age == 20]), 2705.7),
  identical(as.numeric(inputs$value[inputs$measure == "batches_per_year_at_age" & inputs$age == 20]), 128)
)
