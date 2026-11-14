read_assessment_rows <- function(path, id) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    chunk <- readLines(con, n = 100000L, warn = FALSE, encoding = "bytes")
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
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

assessment_id <- "noaa_bluefish_atlantic_2025"
stock_id <- "noaa_bluefish_atlantic_coast"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
parameters <- outputs[outputs$type == "parameter", , drop = FALSE]
stocks <- read_columns("database/stocks.csv",
  c("stock_id", "authority", "authority_stock_id", "scientific_name",
    "common_name", "area", "region", "ocean"))
assessments <- read_columns("database/assessments.csv",
  c("assessment_id", "stock_id", "assessment_year", "terminal_year",
    "estimate_terminal_year", "assessment_type", "model_family", "is_current",
    "is_applied", "inputs_status", "outputs_status", "assumptions_status"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10388", , drop = FALSE]
unit <- inventory[inventory$unit_key == paste0("stock:", stock_id), , drop = FALSE]
get_input <- function(measure, year = NULL, fleet = NULL) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.null(year)) x <- x[!is.na(x$year) & x$year == year, , drop = FALSE]
  if (!is.null(fleet)) x <- x[!is.na(x$fleet) & x$fleet == fleet, , drop = FALSE]
  x
}
get_output <- function(measure, year = NULL, age = NULL, age_group = NULL, fleet = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(year)) x <- x[!is.na(x$year) & x$year == year, , drop = FALSE]
  if (!is.null(age)) x <- x[!is.na(x$age) & x$age == age, , drop = FALSE]
  if (!is.null(age_group)) x <- x[!is.na(x$age_group) & x$age_group == age_group, , drop = FALSE]
  if (!is.null(fleet)) x <- x[!is.na(x$fleet) & x$fleet == fleet, , drop = FALSE]
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA-NEFSC",
  stock$authority_stock_id == "10388",
  stock$scientific_name == "Pomatomus saltatrix",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == "2025",
  assessment$terminal_year == "2024",
  assessment$model_family == "WHAM",
  assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial",
  nrow(inputs) == 40L,
  nrow(assumptions) == 8L,
  nrow(outputs) == 1216L,
  sum(inputs$measure == "catch_biomass") == 40L,
  all(inputs$year %in% 2015:2024),
  all(inputs$unit == "metric tonnes"),
  sum(inputs$value[inputs$year == 2024]) == 8637,
  sum(outputs$measure == "numbers_at_age") == 280L,
  sum(outputs$measure == "fishing_mortality_at_age" & is.na(outputs$fleet)) == 280L,
  sum(outputs$measure == "fishing_mortality_at_age" &
    !is.na(outputs$fleet) & outputs$fleet == "Commercial") == 280L,
  sum(outputs$measure == "fishing_mortality_at_age" &
    !is.na(outputs$fleet) & outputs$fleet == "Recreational") == 280L,
  all(get_output("numbers_at_age")$year %in% 1985:2024),
  all(get_output("numbers_at_age")$age %in% 0:6),
  all(get_output("numbers_at_age", age_group = "6+")$age == 6L),
  get_output("numbers_at_age", year = 2024L, age = 0L)$value == 125408,
  get_output("numbers_at_age", year = 2024L, age = 0L)$unit == "1,000 fish",
  get_output("SSB", year = 2024L)$value == 77065,
  get_output("fully_selected_fishing_mortality", year = 2024L)$value == 0.108,
  get_output("recruitment", year = 2024L)$value == 125408,
  sum(outputs$measure == "SSB") == 10L,
  sum(outputs$measure == "recruitment") == 10L,
  nrow(parameters) == 66L,
  length(unique(parameters$measure)) == 66L,
  all(parameters$unit == "native parameter scale"),
  all(parameters$source_type == "official_table"),
  all(parameters$source_reference ==
    "2025_BLF_UNIT_TAB_wham_par_tables.pdf, Table 1, PDF pp. 2-6"),
  all(is.na(parameters$year)),
  all(is.finite(as.numeric(parameters$value))),
  all(is.finite(as.numeric(parameters$se))),
  all(is.finite(as.numeric(parameters$lwr))),
  all(is.finite(as.numeric(parameters$upr))),
  sum(grepl("fully selected q$", parameters$measure)) == 9L,
  parameters$value[parameters$measure == "stock 1 Mean Recruitment"] == "120340.859",
  parameters$se[parameters$measure == "stock 1 Mean Recruitment"] == "21380.585",
  parameters$lwr[parameters$measure == "stock 1 Mean Recruitment"] == "84953.795",
  parameters$upr[parameters$measure == "stock 1 Mean Recruitment"] == "170468.222",
  parameters$value[parameters$measure == "NEFSC Inshore fully selected q"] == "0.0002648",
  parameters$se[parameters$measure == "NEFSC Inshore fully selected q"] == "5.15e-05",
  parameters$value[parameters$measure == "stock 1 NAA AR1 rho age"] == "-0.232",
  parameters$age[parameters$measure == "Comm Selectivity for age 0 (Block 1)"] == "0",
  parameters$fleet[parameters$measure == "Comm Selectivity for age 0 (Block 1)"] == "Commercial",
  candidate$review_date == "2026-11-13",
  grepl("66 fitted parameter estimates", candidate$output_evidence, fixed = TRUE),
  sum(outputs$measure %in% c("M_at_age", "natural_mortality_at_age")) == 0L,
  sum(inputs$measure %in% c("proportion_at_age", "relative_biomass_index",
    "weight_at_age", "maturity_at_age")) == 0L
)

cat("NOAA Atlantic bluefish source values, coverage, units, partial status, and provenance passed.\n")
