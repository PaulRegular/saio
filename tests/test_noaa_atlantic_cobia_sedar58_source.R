read_assessment_rows <- function(path, assessment_id) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', assessment_id, '",')
  rows <- character()
  repeat {
    lines <- readLines(con, n = 100000L, warn = FALSE, encoding = "bytes")
    if (!length(lines)) break
    rows <- c(rows, lines[startsWith(lines, prefix)])
  }
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessment_id <- "noaa_atlantic_cobia_sedar58_2020"
stock_id <- "noaa_atlantic_cobia"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]

stopifnot(
  nrow(assessment) == 1L, nrow(stock) == 1L,
  assessment$terminal_year == 2017,
  assessment$is_current, assessment$is_applied,
  assessment$inputs_status == "partial",
  stock$authority_stock_id == "12149",
  stock$ocean == "Northwest Atlantic",
  nrow(inputs) == 573L,
  nrow(outputs) == 3313L
)

pick_input <- function(measure, year = NA, age = NA, fleet = NA, partition = NA) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.na(year)) x <- x[as.character(x$year) == as.character(year), , drop = FALSE]
  if (!is.na(age)) x <- x[as.character(x$age) == as.character(age), , drop = FALSE]
  if (!is.na(fleet)) x <- x[x$fleet == fleet, , drop = FALSE]
  if (!is.na(partition)) x <- x[x$partition == partition, , drop = FALSE]
  x
}
pick_output <- function(measure, year = NA, age = NA, scenario = NA) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.na(year)) x <- x[as.character(x$year) == as.character(year), , drop = FALSE]
  if (!is.na(age)) x <- x[as.character(x$age) == as.character(age), , drop = FALSE]
  if (!is.na(scenario)) x <- x[x$scenario == scenario, , drop = FALSE]
  x
}

stopifnot(
  nrow(pick_input("natural_mortality_at_age")) == 16L,
  nrow(pick_input("maturity_at_age")) == 16L,
  nrow(pick_input("weight_at_age")) == 16L,
  nrow(pick_input("catch_biomass")) == 32L,
  nrow(pick_input("catch_numbers")) == 32L,
  nrow(pick_input("catch_cv")) == 128L,
  nrow(pick_input("relative_abundance_index")) == 25L,
  nrow(pick_input("abundance_index_cv")) == 25L,
  pick_input("growth_length_at_age", age = 1)$value == 589.4,
  pick_input("natural_mortality_at_age", age = 16)$value == 0.31,
  pick_input("catch_numbers", year = 1986)$value == 33.608,
  pick_input("composition_sample_count", year = 1986,
    fleet = "General recreational")$value == 22,
  nrow(inputs[inputs$measure %in% c("proportion_at_age",
    "conditional_proportion_at_age", "frequency_at_age"), , drop = FALSE]) == 0L
)

stopifnot(
  nrow(pick_output("numbers_at_age")) == 33L * 16L,
  nrow(pick_output("fishing_mortality_at_age")) == 32L * 16L,
  pick_output("numbers_at_age", year = 1986, age = 1)$value == 1325.98,
  pick_output("SSB", year = 2017)$value == 6795,
  pick_output("F40_percent_table16_estimate", year = 2017)$value == 0.69,
  pick_output("SSB_F40_percent_table16_ensemble_sd", year = 2017)$value == 1872,
  is.na(pick_output("SSB_F40_percent_table16_ensemble_sd",
    year = 2017)$se),
  nrow(pick_output("numbers_at_age", year = 2018,
    scenario = "projection_initialization")) == 16L
)

register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- register[register$candidate_id == "NOAA:12149", , drop = FALSE]
selected <- read.csv("discovery/selected_batch_37_2026.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
selected <- selected[selected$candidate_id == "NOAA:12149", , drop = FALSE]
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import"
)

cat("NOAA Atlantic cobia SEDAR 58 source records and limitations passed.\n")

