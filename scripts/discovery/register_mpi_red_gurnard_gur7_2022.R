candidate_id <- "MPI:GUR7"
candidate_unit_id <- "mpi_red_gurnard_gur7"
review_date <- "2026-11-08"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "GUR 7",
  scientific_name = "Chelidonichthys kumu",
  stock_name = "Red gurnard",
  assessment_area = "GUR 7 (Challenger)",
  inventory_assessment_year = "2022",
  inventory_url = "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx",
  retrieved_on = review_date,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "ineligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2022 base model uses commercial catch biomass for 1987-2021.",
    "The report explicitly says no commercial fishery age or length compositions",
    "are available; catch numbers-at-age are not an assessment input."
  ),
  survey_age_evidence = paste(
    "The WCSI survey provides 15 biomass indices in tonnes for 1992-2021.",
    "Age compositions are described for 1994, 1995, 2003, 2005, and 2007;",
    "length compositions are described for the other ten surveys. The report",
    "summarizes years and ESS but does not tabulate complete numeric composition vectors."
  ),
  weights_evidence = paste(
    "Table 2 reports sex-specific growth and a length-weight relationship",
    "as model biological assumptions; a direct empirical weight-at-age input",
    "series is not reported."
  ),
  maturity_evidence = paste(
    "The model assumes maturity 0 at age 1, 0.5 at age 2, and 1 at ages 3+."
  ),
  mortality_evidence = paste(
    "Base-model natural mortality is fixed at 0.31 per year for both sexes;",
    "0.25 and 0.35 are sensitivity values."
  ),
  timing_evidence = paste(
    "The model is annual. WCSI surveys are conducted in March-April;",
    "the report does not specify a within-year observation fraction."
  ),
  output_evidence = paste(
    "Tables 6-9 report biomass, status, fishing mortality, yield, and forecast",
    "summaries with MCMC intervals. Annual N-at-age and F-at-age are not tabulated."
  ),
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/25169/FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx"
  ),
  review_date = review_date,
  decision_reason = paste(
    "The May 2026 Plenary still identifies the 2022 run as the latest assessment.",
    "The source report has sparse survey-age compositions but no fishery catch-at-age",
    "and does not tabulate the composition vectors, so the stock does not meet the",
    "age-disaggregated input criteria for the current source-curation batch."
  ),
  notes = paste(
    "This is a source-screening record only; no canonical stock or assessment",
    "record was created. Fisheries New Zealand's 2026-27 research services plan",
    "an updated GUR 7 assessment for completion in 2027."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manifest <- data.frame(
  local_file = c(
    "nz_red_gurnard_gur7_2022/FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf",
    "nz_red_gurnard_gur7_2022/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf"
  ),
  source_url = c(
    "https://fs.fish.govt.nz/Doc/25169/FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx"
  ),
  retrieved_on = review_date,
  sha256 = c(
    "C6AFAA340A1EDBDC44E8B6B0AB9DCDD17262558E098859F0DC57DB11E4E1CD84",
    "2CC34CFBB453287C5A4C05F3266DC8BB2B283BA9B3E94C498BC19BFE0C9D868B"
  ),
  represented_source = c(
    "FAR 2022/22, detailed GUR 7 assessment through the 2020/21 fishing year",
    "May 2026 Plenary, latest stock-status summary confirming the 2022 assessment remains current"
  ),
  stringsAsFactors = FALSE
)

register_path <- "discovery/candidates.csv"
manifest_path <- "provenance/mpi_red_gurnard_gur7_2022_sources.csv"
source_paths <- file.path("source_cache", manifest$local_file)
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
register <- read_table(register_path)

if (candidate_id %in% register$candidate_id ||
    candidate_unit_id %in% register$candidate_unit_id ||
    candidate_unit_id %in% register$matched_stock_id ||
    candidate_unit_id %in% stocks$stock_id ||
    candidate_unit_id %in% assessments$stock_id ||
    file.exists(manifest_path)) {
  stop("GUR 7 is already registered or has canonical records.", call. = FALSE)
}
if (!identical(names(candidate), names(register))) {
  stop("Candidate fields do not match the candidate register.", call. = FALSE)
}
if (!all(file.exists(source_paths)) ||
    !identical(toupper(unname(tools::sha256sum(source_paths))), toupper(manifest$sha256))) {
  stop("Cached GUR 7 documents are missing or their checksums differ.", call. = FALSE)
}
cat("Candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Latest detailed assessment:", candidate$inventory_assessment_year, "\n")
cat("Screening decision:", candidate$eligibility, "\n")
cat("Cached official sources verified:", nrow(manifest), "\n")

if (write_mode) {
  write.table(candidate, register_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Registered the GUR 7 screen and refreshed discovery summaries.\n")
}
