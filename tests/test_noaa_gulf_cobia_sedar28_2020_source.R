read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character() else if (status != 0L)
    stop("Could not read assessment rows from ", path)
  rows <- rows[startsWith(rows, paste0('"', assessment_id, '",'))]
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}

stock_id <- "noaa_cobia_gulf_mexico_2020"
assessment_id <- paste0(stock_id, "_sedar28_update")
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10390", , drop = FALSE]
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
unit <- units[!is.na(units$matched_stock_id) & units$matched_stock_id == stock_id, , drop = FALSE]
selected <- read.csv("discovery/selected_batch_39_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- selected[selected$candidate_id == "NOAA:10390", , drop = FALSE]
manifest <- read.csv("provenance/discovery_noaa_gom_cobia_2020/sources.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_gulf_cobia_2020.md",
  warn = FALSE), collapse = " ")

input_values <- function(measure, year = NULL, observation_id = NULL) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.null(year)) x <- x[!is.na(x$year) & x$year == as.character(year), , drop = FALSE]
  if (!is.null(observation_id)) x <- x[x$observation_id == observation_id, , drop = FALSE]
  x
}
output_values <- function(measure, year) {
  outputs[outputs$measure == measure & !is.na(outputs$year) &
    outputs$year == as.character(year), , drop = FALSE]
}
numeric_values <- function(x) as.numeric(x$value)

stopifnot(
  nrow(candidate) == 1L, candidate$match_status == "matched",
  candidate$import_status == "partial", candidate$matched_stock_id == stock_id,
  nrow(unit) == 1L, unit$import_status == "partial",
  nrow(selected) == 1L, selected$curation_status == "partial_source_import",
  nrow(stocks[stocks$stock_id == stock_id, , drop = FALSE]) == 1L,
  nrow(assessments[assessments$assessment_id == assessment_id, , drop = FALSE]) == 1L,
  assessments$terminal_year[assessments$assessment_id == assessment_id] == 2018,
  assessments$inputs_status[assessments$assessment_id == assessment_id] == "partial",
  assessments$outputs_status[assessments$assessment_id == assessment_id] == "partial",
  nrow(inputs) == 1190L, nrow(outputs) == 844L,
  nrow(input_values("landings_biomass", observation_id =
    "cobia_commercial_landings_total_1927_2018")) == 92L,
  numeric_values(input_values("landings_biomass", 1927,
    "cobia_commercial_landings_total_1927_2018")) == 4.290,
  numeric_values(input_values("landings_biomass", 2018,
    "cobia_commercial_landings_total_1927_2018")) == 33.230,
  nrow(input_values("landings_numbers", observation_id =
    "cobia_recreational_landings_aggregate_1950_2018")) == 69L,
  numeric_values(input_values("landings_numbers", 1950,
    "cobia_recreational_landings_aggregate_1950_2018")) == 2.5,
  numeric_values(input_values("landings_numbers", 1981,
    "cobia_recreational_landings_aggregate_1950_2018")) == 168.355,
  nrow(input_values("discard_numbers", observation_id =
    "cobia_commercial_discards_longline")) == 26L,
  nrow(input_values("discard_numbers", observation_id =
    "cobia_recreational_discards_mrip")) == 38L,
  nrow(input_values("catch_numbers")) == 46L,
  nrow(input_values("effort")) == 74L,
  nrow(input_values("log_index_sd", observation_id =
    "cobia_shrimp_effort_1945_2018")) == 74L,
  nrow(input_values("relative_abundance_index")[
    input_values("relative_abundance_index")$survey == "MRIP", , drop = FALSE]) == 38L,
  nrow(input_values("relative_abundance_index")[
    input_values("relative_abundance_index")$survey == "SRHS Headboat", , drop = FALSE]) == 33L,
  nrow(input_values("log_index_sd")[
    input_values("log_index_sd")$survey == "MRIP", , drop = FALSE]) == 38L,
  nrow(input_values("log_index_sd")[
    input_values("log_index_sd")$survey == "SRHS Headboat", , drop = FALSE]) == 33L,
  sum(numeric_values(input_values("composition_sample_count")[
    input_values("composition_sample_count")$partition == "recreational_age", , drop = FALSE])) == 1267,
  nrow(input_values("natural_mortality_at_age")) == 12L,
  numeric_values(input_values("natural_mortality_at_age", observation_id = NULL)[
    input_values("natural_mortality_at_age")$age == "0", , drop = FALSE]) == 0.546,
  nrow(input_values("maturity_at_age")) == 9L,
  nrow(input_values("proportion_female_at_age")) == 11L,
  nrow(input_values("frequency_at_length")) == 0L,
  nrow(input_values("conditional_frequency_at_age")) == 0L,
  nrow(output_values("total_biomass", 1925)) == 1L,
  numeric_values(output_values("total_biomass", 1925)) == 20410.100,
  numeric_values(output_values("SSB", 1925)) == 18016.500,
  numeric_values(output_values("total_abundance", 1925)) == 2843.600,
  numeric_values(output_values("recruitment", 1925)) == 1905.640,
  numeric_values(output_values("apical_fishing_mortality", 2018)[
    output_values("apical_fishing_mortality", 2018)$fleet == "Recreational", , drop = FALSE]) == 0.545,
  numeric_values(output_values("exploitation_rate", 2018)) == 0.366,
  nrow(outputs[!is.na(outputs$age) & outputs$measure != "recruitment", , drop = FALSE]) == 0L,
  all(is.na(outputs$se)), all(is.na(outputs$lwr)), all(is.na(outputs$upr)),
  nrow(manifest) == 6L, !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  grepl("composition cells are presented in figures", review, fixed = TRUE),
  grepl("Tables 13", review, fixed = TRUE),
  grepl("super-period likelihood", review, fixed = TRUE)
)
cat("NOAA Gulf cobia SEDAR 28 source values, coverage, units, gaps, and point-estimate outputs passed.\n")
