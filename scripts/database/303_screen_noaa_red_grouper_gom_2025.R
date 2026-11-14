candidate_id <- "NOAA:10331"
stock_id <- "noaa_red_grouper_gom"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

source("scripts/database/candidate_register_io.R")

candidate_path <- "discovery/candidates.csv"
inventory_path <- "discovery/inventory_units.csv"
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), colClasses = "character", check.names = FALSE)
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), colClasses = "character", check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

ci <- which(candidates$candidate_id == candidate_id)
ii <- candidate_inventory_row(inventory, candidate_id, stock_id)
if (length(ci) != 1L || candidates$official_stock_id[ci] != "10331" ||
    candidates$scientific_name[ci] != "Epinephelus morio" ||
    candidates$assessment_area[ci] != "Gulf of Mexico" ||
    candidates$match_status[ci] != "new" ||
    any(stocks$authority_stock_id == "10331", na.rm = TRUE) ||
    any(assessments$assessment_id == paste0(stock_id, "_sedar88_2025"))) {
  stop("Gulf red grouper identity or canonical status changed.", call. = FALSE)
}

selection_basis <- paste(
  "SEDAR 88 is the latest full production assessment, with data through 2022.",
  "The corrected December 2025 report provides run-specific catch, age-composition,",
  "index, biological-assumption and population-output information. Select for a",
  "partial source import; preserve figure-only age compositions and unavailable",
  "age-specific survey values as gaps."
)
selected <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = stock_id,
  organization = "NOAA",
  official_stock_id = "10331",
  scientific_name = "Epinephelus morio",
  stock_name = "Red grouper - Gulf of Mexico",
  assessment_area = "Gulf of Mexico",
  inventory_assessment_year = 2026L,
  detailed_source_url = candidates$detailed_source_url[ci],
  review_date = "2026-11-13",
  selection_basis = selection_basis,
  curation_status = "selected_for_partial_source_curation",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
batch_path <- "discovery/selected_batch_41_2026.csv"
if (file.exists(batch_path)) {
  old <- read.csv(batch_path, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(old) != 1L || old$candidate_id != candidate_id) {
    stop("Gulf red grouper selection batch contains unexpected rows.", call. = FALSE)
  }
} else if (write_mode) {
  write.csv(selected, batch_path, row.names = FALSE, na = "")
}

candidate_update <- candidates[ci, , drop = FALSE]
candidate_update$eligibility <- "eligible"
candidate_update$review_date <- "2026-11-13"
candidate_update$decision_reason <- paste(
  "Eligible for partial source curation: SEDAR 88 is the latest full production",
  "assessment and provides run-specific fishery age-composition inputs, aggregate",
  "abundance indices, age-specific natural mortality and annual population outputs.",
  "The age-composition matrices are figure-only, survey indices are not age-specific,",
  "and biological/timing details remain incomplete; these are documented source gaps."
)
candidate_update$notes <- paste(
  "NOAA Stock SMART 10331 is distinct from South Atlantic unit 10332.",
  "Eligibility is for partial source curation; it does not imply that every input",
  "series is machine-readable or that all age-specific survey data are available."
)

inventory_update <- inventory[ii, , drop = FALSE]
inventory_update$eligibility <- "eligible"
if (!write_mode) {
  cat("NOAA Gulf red grouper SEDAR 88 is eligible for partial source curation.\n")
} else {
  replace_candidate_register_row(candidate_path, ci, candidate_update, candidate_id)
  replace_csv_register_row(inventory_path, ii, inventory_update, "unit_key",
    inventory$unit_key[ii])
  if (!file.exists(batch_path)) write.csv(selected, batch_path, row.names = FALSE, na = "")
  cat("Selected NOAA Gulf red grouper SEDAR 88 for partial source curation.\n")
}
