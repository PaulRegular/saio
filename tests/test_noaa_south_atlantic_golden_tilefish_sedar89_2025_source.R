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

assessment_id <- "noaa_golden_tilefish_south_atlantic_sedar89_2025"
stock_id <- "noaa_golden_tilefish_south_atlantic"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "ocean"))
assessments <- read_columns("database/assessments.csv", c("assessment_id", "stock_id",
  "assessment_year", "terminal_year", "estimate_terminal_year", "is_current",
  "is_applied", "model_version", "inputs_status", "outputs_status", "assumptions_status"))
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
selected <- read.csv("discovery/selected_batch_25_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
manifest <- read.csv("provenance/noaa_south_atlantic_golden_tilefish_sedar89_2025/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10384", , drop = FALSE]
inventory <- inventory[inventory$unit_key == "candidate:noaa_golden_tilefish_south_atlantic", , drop = FALSE]
selected <- selected[selected$candidate_id == "NOAA:10384", , drop = FALSE]
get_input <- function(measure, age = NULL, year = NULL, type = NULL) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.null(age)) x <- x[x$age == as.character(age), , drop = FALSE]
  if (!is.null(year)) x <- x[x$year == as.character(year), , drop = FALSE]
  if (!is.null(type)) x <- x[x$type == type, , drop = FALSE]
  x
}
get_output <- function(measure, age = NULL, year = NULL, scenario = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(age)) x <- x[x$age == as.character(age), , drop = FALSE]
  if (!is.null(year)) x <- x[x$year == as.character(year), , drop = FALSE]
  if (!is.null(scenario)) x <- x[x$scenario == scenario, , drop = FALSE]
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10384",
  stock$scientific_name == "Lopholatilus chamaeleonticeps",
  stock$area == "South Atlantic Coast",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$assessment_year == "2025",
  assessment$terminal_year == "2022",
  assessment$estimate_terminal_year == "2022",
  assessment$model_version == "SEDAR 89 Rev2 base run, September 2025",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(assumptions) == 15L,
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  nrow(inventory) == 1L,
  inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import",
  nrow(manifest) == 5L,
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  nrow(inputs) == 614L,
  nrow(outputs) == 7538L,
  nrow(get_input("weight_at_age", age = 20L)) == 2L,
  any(get_input("weight_at_age", age = 20L)$value == 6.33),
  any(get_input("natural_mortality_at_age", age = 20L)$value == 0.13),
  any(get_input("maturity_at_age", age = 20L)$value == 1),
  any(get_input("reproductive_potential_at_age", age = 3L)$value == 0.07),
  nrow(get_input("relative_biomass_index", year = 1996L)) == 1L,
  nrow(get_input("relative_abundance_index", year = 1996L)) == 1L,
  all(as.numeric(inputs$sampling_time[inputs$measure %in% c(
    "relative_biomass_index", "relative_abundance_index")]) == 0.5),
  all(inputs$season[inputs$type == "index"] == "annual"),
  any(inputs$measure == "composition_sample_count"),
  !any(inputs$measure %in% c("proportion_at_age", "frequency_at_age")),
  nrow(get_output("numbers_at_age", age = 1L, year = 1972L)) == 1L,
  get_output("numbers_at_age", age = 1L, year = 1972L)$value == 619.38,
  nrow(get_output("fishing_mortality_at_age", age = 20L, year = 2022L)) == 1L,
  sum(outputs$measure == "predicted_landings_numbers") == 183L,
  sum(outputs$measure == "predicted_landings_weight") == 183L,
  sum(outputs$measure == "predicted_landings_numbers" & outputs$year %in% as.character(2023:2027)) == 30L,
  sum(outputs$measure == "predicted_landings_weight" & outputs$year %in% as.character(2023:2027)) == 30L,
  nrow(get_output("SSB", year = 2022L)) == 1L,
  get_output("SSB", year = 2022L)$value > 0,
  get_output("SSB", year = 2022L)$value < 2,
  nrow(get_output("SSB", year = 2025L, scenario = "expected; F = FMSY starting in 2026")) == 1L,
  nrow(get_output("probability_at_or_below_MSST", year = 2027L)) == 3L,
  any(get_output("SSBMSY")$scenario == "Table 18 as printed; scale discrepancy unresolved" &
    get_output("SSBMSY")$value == 515.42),
  any(get_output("SSBMSY")$scenario == "Section 4.8 narrative estimate" &
    get_output("SSBMSY")$value == 0.515)
)

cat("NOAA South Atlantic golden tilefish SEDAR 89 source inputs, outputs, units, partial status, scale conflict and provenance passed.\n")
