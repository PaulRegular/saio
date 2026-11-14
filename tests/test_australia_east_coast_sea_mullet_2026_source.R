read_rows_csv <- function(records) {
  record_connection <- textConnection(records)
  on.exit(close(record_connection))
  utils::read.csv(record_connection, stringsAsFactors = FALSE,
    check.names = FALSE, na.strings = c("", "NA"))
}
read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  read_rows_csv(c(header, rows))
}

assessment_id <- "australia_east_coast_sea_mullet_2026"
stock_id <- "australia_east_coast_sea_mullet"
candidate_id <- "QDAF:EAST_COAST_SEA_MULLET_2026"
source_url <- "https://era.dpi.qld.gov.au/id/eprint/16056/1/2026_sea_mullet_stock_assessment.pdf"
expected_hash <- "59069D68DCE3E2F19AD9393210F073A3D12632B9C93ACE0A61B39529EF37AE21"

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
manifest <- read.csv("provenance/australia_east_coast_sea_mullet_2026_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
unit <- units[units$unit_key == paste0("stock:", stock_id), , drop = FALSE]
ssb <- outputs[outputs$measure == "SSB_ratio_to_B0", , drop = FALSE]
probabilities <- outputs[outputs$type == "probability", , drop = FALSE]
harvest <- outputs[outputs$measure == "harvest_rate", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Mugil cephalus",
  stock$area == "Queensland and New South Wales east coast waters",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026L,
  assessment$terminal_year == 2024L,
  assessment$estimate_terminal_year == 2025L,
  assessment$is_current %in% c(TRUE, "TRUE"),
  assessment$is_applied %in% c(TRUE, "TRUE"),
  all(assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(inputs) == 1L,
  inputs$type == "catch",
  inputs$measure == "catch_biomass",
  inputs$basis == "biomass",
  inputs$year == 2024L,
  inputs$value == 3021,
  inputs$unit == "tonnes",
  inputs$source_type == "official_document",
  is.na(suppressWarnings(as.numeric(inputs$age))),
  grepl("aggregate across the four", inputs$notes, fixed = TRUE),
  nrow(assumptions) == 11L,
  any(assumptions$setting == "model_software" & assumptions$value == "Stock Synthesis 3.30.24.2"),
  any(assumptions$setting == "scenario_values" & grepl("0.28, 0.33, and 0.37", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "stock_recruitment_steepness" & assumptions$value == "0.75"),
  nrow(outputs) == 6L,
  nrow(ssb) == 1L,
  ssb$year == 2025L,
  as.numeric(ssb$value) == 39,
  as.numeric(ssb$lwr) == 25,
  as.numeric(ssb$upr) == 76,
  is.na(ssb$se),
  ssb$unit == "percent",
  nrow(probabilities) == 4L,
  isTRUE(all.equal(sort(as.numeric(probabilities$value)), sort(c(0.001, 0.539, 0.351, 0.109)))),
  all(probabilities$unit == "probability"),
  nrow(harvest) == 1L,
  is.na(harvest$year),
  harvest$scenario == "2020-2024 annual harvest-rate summary",
  as.numeric(harvest$value) == 0.15,
  as.numeric(harvest$lwr) == 0.10,
  as.numeric(harvest$upr) == 0.21,
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "SSB")),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$eligibility == "unresolved",
  unit$import_status == "partial",
  nrow(manifest) == 1L,
  manifest$source_url == source_url,
  manifest$sha256 == expected_hash,
  identical(toupper(unname(tools::sha256sum(
    "source_cache/australia_east_coast_sea_mullet_2024/sea_mullet_assessment_data_2024.pdf"
  ))), expected_hash)
)

cat("Eastern Australian sea mullet source data, status, units, and provenance passed.\n")
