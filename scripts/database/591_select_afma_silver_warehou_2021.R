candidate_id <- "AFMA:SESSF_SILVER_WAREHOU"
candidate_unit_id <- "afma_sessf_silver_warehou"
selected_path <- "discovery/selected_batch_08_2026.csv"

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.")
}

candidates_path <- "discovery/candidates.csv"
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)

if (candidate_id %in% candidates$candidate_id || file.exists(selected_path)) {
  stop("The candidate or selected batch already exists; review before rerunning.")
}

append_candidate <- function(rows) {
  header <- names(read.csv(candidates_path, nrows = 0, check.names = FALSE))
  if (!identical(header, names(rows))) {
    stop("Candidate columns do not match the discovery register.")
  }
  rows[] <- lapply(rows, as.character)
  write.table(rows, candidates_path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE,
    eol = "\n")
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "AFMA",
  official_stock_id = "Silver warehou (SESSF)",
  scientific_name = "Seriolella punctata",
  stock_name = "Silver warehou",
  assessment_area = "Southern and Eastern Scalefish and Shark Fishery (SESSF), east and west trawl fleets",
  inventory_assessment_year = "2021",
  inventory_url = "https://www.afma.gov.au/fisheries/southern-and-eastern-scalefish-and-shark-fishery",
  retrieved_on = "2026-11-06",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2021 report tabulates annual catch biomass by east and west fleet, not catch-at-age.",
    "The age-structured model uses conditional age-at-length samples, but the observed age-by-length vectors are not published."
  ),
  survey_age_evidence = paste(
    "The model uses aggregate east and west CPUE indices, not age-specific abundance indices.",
    "The report gives annual conditional age-at-length sample counts, but not the numerical age-by-length cells or CPUE vectors."
  ),
  weights_evidence = paste(
    "The report gives length-weight coefficients and estimates growth within the model;",
    "a numerical weight-at-age surface is not published."
  ),
  maturity_evidence = paste(
    "Maturity is a fixed logistic function of length with 50% maturity at 37 cm;",
    "a maturity-at-age vector is not published."
  ),
  mortality_evidence = "Natural mortality is fixed at 0.30 per year in the 2021 base case.",
  timing_evidence = paste(
    "The assessment uses calendar-year model steps and annual CPUE indices.",
    "A within-year timing fraction for CPUE is not specified."
  ),
  output_evidence = paste(
    "The detailed report gives stock-status proportions, SSB0 and SSB2022, catch projections, fitted parameter estimates,",
    "and likelihood diagnostics. Numeric annual N-at-age and F-at-age arrays and uncertainty intervals were not located."
  ),
  detailed_source_url = "https://www.afma.gov.au/sites/default/files/2023-02/Stock%20Assessments%20for%20SESSF%202020%E2%80%9321%20-%20Part%201.pdf",
  review_date = "2026-11-06",
  decision_reason = paste(
    "The 2021 assessment (data through 2020) remains the detailed assessment used for current advice.",
    "AFMA reports that the later 2024 Tier 1 assessment was not accepted and the 2026-27 TAC continues to use fixed-catch projections from 2021.",
    "The report supplies run-specific input and output tables; select for partial source curation while age-input eligibility remains unresolved."
  ),
  notes = paste(
    "One SESSF stock is represented with separate east and west trawl fleets.",
    "The 2021 assessment has a single modelled stock, fixed M, and conditional age-at-length data.",
    "See discovery/source_reviews/afma_sessf_silver_warehou_2021.md."
  ),
  stringsAsFactors = FALSE
)

stopifnot(identical(names(candidate), names(candidates)))
append_candidate(candidate)

selected <- data.frame(
  priority = "1",
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "AFMA",
  official_stock_id = "Silver warehou (SESSF)",
  scientific_name = "Seriolella punctata",
  stock_name = "Silver warehou",
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = "2021",
  detailed_source_url = candidate$detailed_source_url,
  review_date = "2026-11-06",
  selection_basis = paste(
    "AFMA's 2026 summary identifies the 2021 assessment as the basis for current constant-catch advice;",
    "the later 2024 Tier 1 assessment was not accepted.",
    "The detailed 2020-21 report publishes catch and discard tables, age-at-length sample counts, fixed M,",
    "fitted parameter estimates, stock status, and projections.",
    "Import the verified tables and keep age-input eligibility unresolved because the observed composition vectors are unavailable."
  ),
  curation_status = "selected_for_partial_source_curation",
  stringsAsFactors = FALSE
)
write.csv(selected, selected_path, row.names = FALSE, na = "")

source("scripts/database/195_summarize_discovery.R", local = TRUE)
source("scripts/database/196_summarize_inventory_units.R", local = TRUE)

cat("Selected AFMA SESSF Silver Warehou for partial source curation.\n")
