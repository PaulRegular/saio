candidate_id <- "MPI:LIN7WC"
candidate_unit_id <- "mpi_ling_lin7wc"
stock_id <- "mpi_ling_lin7wc"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
path <- "discovery/candidates.csv"

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "LIN 7WC",
  scientific_name = "Genypterus blacodes",
  stock_name = "West Coast South Island ling",
  assessment_area = "West Coast South Island biological stock; Statistical Area 032 included",
  inventory_assessment_year = "2026",
  inventory_url = "https://fs.fish.govt.nz/Page.aspx?dk=26250&pk=113",
  retrieved_on = "2026-11-06",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2026 assessment uses annual scaled catch biomass and sexed commercial",
    "age compositions. FAR 2026/06 reports 2023-24 commercial trawl numbers-at-age",
    "and CVs in Table 15; earlier and 2025 fitted composition vectors were not",
    "numerically located in the reviewed detailed sources."
  ),
  survey_age_evidence = paste(
    "The 2026 assessment uses Tangaroa biomass and sexed age compositions in",
    "2000, 2012-13, 2016, 2018, 2021 and 2024. FAR 2025/41 reports core biomass",
    "indices; FAR 2026/06 Table 23 reports 2024 sex-specific numbers-at-age and CVs."
  ),
  weights_evidence = paste(
    "The assessment reports sex-specific von Bertalanffy growth and length-weight",
    "equations. A numeric age-specific weight surface was not located."
  ),
  maturity_evidence = paste(
    "FAR 2026/26 Table 4 reports fixed maturity-at-age values for ages 3-12",
    "by sex; other modeled ages are not tabulated."
  ),
  mortality_evidence = paste(
    "Base-case natural mortality is fixed at 0.18 per year, constant across ages",
    "and sexes; 0.16 and 0.20 are sensitivities."
  ),
  timing_evidence = paste(
    "The model annual cycle is January-December. Table 1 assigns 0.5 of total",
    "mortality to all observations; the 2024 Tangaroa survey ran July-August."
  ),
  output_evidence = paste(
    "FAR 2026/26 Tables 7-8 report MPD biomass points, posterior B0 and 2026",
    "status summaries with 95% credible intervals, and status probabilities.",
    "Annual numerical N-at-age, F-at-age and recruitment series were not located."
  ),
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/26250/FAR-2026-26-The-2026-stock-assessment-LIN7WC.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26249/FAR-2026-25-Descriptive-analysis-LIN7WC-to-2025-and-inputs-for-2026-stock-assessment.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26199/FAR-2026-06-Catch-at-age-estimates-for-hake-and-ling-from-commercial-fisheries-in-2023-24-and-trawl-surveys-in-2024%20(1).pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26135/FAR-2025-41-Trawl-survey-for-middle-depth-fish-species-WCSI-2024-TAN2407.pdf.ashx"
  ),
  review_date = "2026-11-06",
  decision_reason = paste(
    "Eligible for source curation: the current LIN 7WC production assessment",
    "documents catch, age-composition and survey series, biological inputs,",
    "fixed M and comparable outputs. Numerical coverage is partial and will be",
    "kept that way where source values are unavailable."
  ),
  notes = paste(
    "LIN 7WC is the West Coast South Island biological stock, distinct from",
    "the Chatham Rise LIN 3&4 record. The 2026 assessment includes Statistical",
    "Area 032. Assessment-year and model-year values are not mixed with the",
    "LIN 3&4 record."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

schema <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
  check.names = FALSE))
candidate <- candidate[schema]

if (sum(read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
  check.names = FALSE)$candidate_id == candidate_id) != 0L) {
  stop("LIN 7WC is already in the candidate register.")
}

cat("Screened candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Decision:", candidate$eligibility, "; import status:", candidate$import_status, "\n")

if (write_mode) {
  write.table(candidate, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
  cat("Added LIN 7WC to the candidate register.\n")
}
