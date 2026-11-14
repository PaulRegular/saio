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
read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = classes)
}

assessment_id <- "noaa_northern_anchovy_central_subpopulation_2021"
stock_id <- "noaa_northern_anchovy_central_subpopulation"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "region", "ocean"))
assessments <- read_columns("database/assessments.csv", c("assessment_id",
  "stock_id", "assessment_year", "terminal_year", "estimate_terminal_year",
  "is_current", "is_applied", "model_version", "inputs_status",
  "outputs_status", "assumptions_status"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
selected <- read.csv("discovery/selected_batch_26_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
manifest <- read.csv("provenance/discovery_noaa_anchovy_2021/sources.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10574", , drop = FALSE]
inventory <- inventory[grepl("NOAA:10574", inventory$candidate_ids, fixed = TRUE), , drop = FALSE]
selected <- selected[selected$candidate_id == "NOAA:10574", , drop = FALSE]
get_input <- function(measure, age = NULL, year = NULL, season = NULL,
                      fleet = NULL, survey = NULL, age_error = NULL) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.null(age)) x <- x[!is.na(x$age) & as.character(x$age) == as.character(age), , drop = FALSE]
  if (!is.null(year)) x <- x[!is.na(x$year) & as.character(x$year) == as.character(year), , drop = FALSE]
  if (!is.null(season)) x <- x[!is.na(x$season) & as.character(x$season) == as.character(season), , drop = FALSE]
  if (!is.null(fleet)) x <- x[!is.na(x$fleet) & x$fleet == fleet, , drop = FALSE]
  if (!is.null(survey)) x <- x[!is.na(x$survey) & x$survey == survey, , drop = FALSE]
  if (!is.null(age_error)) x <- x[!is.na(x$age_error) & as.character(x$age_error) == as.character(age_error), , drop = FALSE]
  x
}
get_output <- function(measure, year = NULL, season = NULL, age = NULL,
                       age_group = NULL, scenario = NULL, fleet = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(year)) x <- x[!is.na(x$year) & as.character(x$year) == as.character(year), , drop = FALSE]
  if (!is.null(season)) x <- x[!is.na(x$season) & as.character(x$season) == as.character(season), , drop = FALSE]
  if (!is.null(age)) x <- x[!is.na(x$age) & as.character(x$age) == as.character(age), , drop = FALSE]
  if (!is.null(age_group)) x <- x[!is.na(x$age_group) & x$age_group == age_group, , drop = FALSE]
  if (!is.null(scenario)) x <- x[!is.na(x$scenario) & x$scenario == scenario, , drop = FALSE]
  if (!is.null(fleet)) x <- x[!is.na(x$fleet) & x$fleet == fleet, , drop = FALSE]
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10574",
  stock$scientific_name == "Engraulis mordax",
  stock$ocean == "Northeast Pacific",
  grepl("central subpopulation", stock$area, ignore.case = TRUE),
  nrow(assessment) == 1L,
  assessment$assessment_year == "2022",
  assessment$terminal_year == "2021",
  assessment$estimate_terminal_year == "2023",
  assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(assumptions) == 11L,
  nrow(inputs) == 2828L,
  nrow(outputs) == 198L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(inventory) == 1L,
  inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import",
  nrow(manifest) == 8L,
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  sum(inputs$measure == "catch_biomass") == 92L,
  sum(inputs$measure == "catch_se") == 92L,
  sum(is.na(inputs$year[inputs$measure == "catch_biomass"])) == 4L,
  any(get_input("catch_biomass", year = 2000L, fleet = "MexCal_S1")$value == 9009.05),
  sum(inputs$measure %in% c("relative_biomass_index", "recruitment_index")) == 64L,
  sum(inputs$measure == "log_index_sd") == 64L,
  all(grepl("^source time code [0-9]+$", inputs$season[inputs$measure %in% c("relative_biomass_index", "recruitment_index")])),
  all(is.na(inputs$sampling_time[inputs$measure %in% c(
    "relative_biomass_index", "recruitment_index")])),
  sum(inputs$measure == "proportion_at_age") == 84L,
  sum(inputs$measure == "proportion_at_length") == 540L,
  sum(inputs$measure == "catch_weight_at_age") == 368L,
  sum(inputs$measure == "weight_at_age") == 1104L,
  sum(inputs$measure == "start_weight_at_age") == 184L,
  sum(inputs$measure == "maturity_fecundity_at_age") == 184L,
  sum(inputs$measure == "maturity_at_age") == 4L,
  sum(inputs$measure == "age_error_mean_age") == 24L,
  sum(inputs$measure == "ageing_error_sd") == 24L,
  any(get_input("age_error_mean_age", age = 3L, age_error = 6L)$value == 2.45),
  any(get_input("ageing_error_sd", age = 3L, age_error = 6L)$value == 0.90),
  abs(sum(get_input("proportion_at_age", year = 2020L, survey = "AT_spring")$value) -
    0.983744) < 1e-6,
  sum(outputs$measure == "numbers_at_age") == 56L,
  nrow(get_output("numbers_at_age", year = 2021L, season = 1L, age = 3L)) == 1L,
  get_output("numbers_at_age", year = 2021L, season = 1L, age = 3L)$value == 16863300,
  nrow(get_output("SSB", year = 2021L, season = 2L)) == 1L,
  get_output("SSB", year = 2021L, season = 2L)$value == 2586700,
  get_output("SSB", year = 2021L, season = 2L)$se == 718182,
  nrow(get_output("recruitment", year = 2021L, season = 1L)) == 1L,
  get_output("recruitment", year = 2021L, season = 1L)$value == 129427000,
  get_output("recruitment", year = 2021L, season = 1L)$se == 134584000,
  any(get_output("biomass_by_age_group", year = 2021L, age_group = "1+")$value == 2090640),
  any(outputs$measure == "natural_mortality_average_parameter" &
    outputs$value == 0.414),
  sum(outputs$measure == "exploitation_rate") == 21L,
  sum(outputs$measure == "fishing_mortality_at_age") == 0L,
  any(outputs$measure == "negative_log_likelihood" & outputs$value == 54.444),
  all(inputs$source_type == "native_model"),
  all(outputs$source_type == "official_table")
)

cat("NOAA Northern anchovy source inputs, output tables, uncertainty, native composition values, provenance, and partial coverage passed.\n")
