root <- "."
retrieved_on <- "2026-11-07"
candidate_id <- "QLD:EAST_COAST_SPANISH_MACKEREL"
candidate_unit_id <- "australia_qld_spanish_mackerel_east_coast"
report_url <- "https://era.dpi.qld.gov.au/id/eprint/14912/1/2025%20East%20coast%20Spanish%20mackerel%20stock%20assessment%20report%20Final%208.5.25.pdf"
record_url <- "https://era.dpi.qld.gov.au/id/eprint/14912/"
report_file <- file.path(root, "source_cache/australia_qld_spanish_mackerel_2025/east_coast_assessment_2025.pdf")
expected_hash <- "740DD3DEFB074560A9F406ACF1E029170294494D3975642261DE96A284CF458E"

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- toupper(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result, value = TRUE)))
  if (length(hash) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hash
}

if (!file.exists(report_file) || !identical(sha256_file(report_file), expected_hash)) {
  stop("The cached Queensland assessment report differs from the reviewed source.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Queensland DPI",
  official_stock_id = "East Coast biological stock",
  scientific_name = "Scomberomorus commerson",
  stock_name = "Australian east coast Spanish mackerel",
  assessment_area = "Single east coast stock from Cape York Peninsula to Newcastle, New South Wales",
  inventory_assessment_year = 2025L,
  inventory_url = record_url,
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2025 Stock Synthesis model uses annual catch histories and conditional age-at-length compositions, not observed catch numbers-at-age.",
    "Table 3.1 reports rounded catch by four sectors only for selected years from 1970-2024; it is not the full native fleet input."
  ),
  survey_age_evidence = paste(
    "The model uses an aggregate standardised commercial CPUE index (2006-2023), not an age-specific survey index.",
    "Annual age frequencies are displayed as figures; numerical conditional age-at-length likelihood arrays were not located."
  ),
  weights_evidence = "The report gives a whole-weight/fork-length equation and sex-specific estimated growth, but no direct annual weight-at-age input series.",
  maturity_evidence = "Length-based maturity is specified as logistic(mat) = exp(-10.349 + 0.0128 FL)/(1 + exp(-10.349 + 0.0128 FL)); age-based maturity is model-derived.",
  mortality_evidence = "Natural mortality is constant across ages, sexes, and years, estimated in the final ensemble with a Hamel-Cope prior (median 5.4/25 = 0.216 per year; log-scale SD 0.31).",
  timing_evidence = "The assessment year is financial-year based (July-June) and the population model has an annual time step. No single within-year fraction for the commercial CPUE index was identified.",
  output_evidence = paste(
    "Tables 3.3-3.4 report beginning-2025 spawning-biomass ratios relative to unfished levels for the six-scenario ensemble and each MLE/MCMC scenario.",
    "Annual absolute SSB, N-at-age, F-at-age, recruitment trajectories, and their age-specific uncertainty are not tabulated as numerical series."
  ),
  detailed_source_url = report_url,
  review_date = retrieved_on,
  decision_reason = "Selected for partial source curation: the current 2025 production assessment has a detailed official report with traceable biological assumptions and numerical stock-status outputs. Translation eligibility remains unresolved because the full native fleet catches, numerical composition inputs, and age-specific biological arrays are not available in the reviewed public report.",
  notes = "Internal candidate and unit identifiers only; the report does not provide a formal stock code. The east coast stock is distinct from Gulf of Carpentaria and Torres Strait Spanish mackerel units."
)

candidate_path <- file.path(root, "discovery/candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
if (candidate_id %in% candidates$candidate_id || candidate_unit_id %in% candidates$candidate_unit_id) {
  stop("Candidate identity already exists; review the register before proceeding.", call. = FALSE)
}
stocks <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (any(stocks$scientific_name == candidate$scientific_name &
    grepl("east coast|New South Wales|Queensland", paste(stocks$area, stocks$region), ignore.case = TRUE))) {
  stop("A matching Australian east coast canonical stock may already exist.", call. = FALSE)
}
utils::write.table(candidate, candidate_path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")

selection_path <- file.path(root, "discovery/selected_batch_11_2026.csv")
if (file.exists(selection_path)) stop("Selection batch 11 already exists; review it manually.", call. = FALSE)
selection <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Queensland DPI",
  official_stock_id = candidate$official_stock_id,
  scientific_name = candidate$scientific_name,
  stock_name = candidate$stock_name,
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = 2025L,
  detailed_source_url = report_url,
  review_date = retrieved_on,
  selection_basis = "The 2025 official report identifies the current east coast biological unit, documents the Stock Synthesis structure and biological assumptions, and reports comparable ensemble stock-status outputs. Select for source curation only; key numerical likelihood inputs remain unavailable in the report.",
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE
)
utils::write.csv(selection, selection_path, row.names = FALSE, na = "")

manifest <- data.frame(
  local_file = "source_cache/australia_qld_spanish_mackerel_2025/east_coast_assessment_2025.pdf",
  source_url = report_url,
  record_url = record_url,
  retrieved_on = retrieved_on,
  sha256 = expected_hash,
  bytes = file.info(report_file)$size,
  description = "Official 2025 east coast Spanish mackerel assessment report, data through June 2024.",
  stringsAsFactors = FALSE
)
utils::write.csv(manifest,
  file.path(root, "provenance/australia_qld_spanish_mackerel_2025_sources.csv"),
  row.names = FALSE, na = "")

source(file.path(root, "scripts/database/195_summarize_discovery.R"), local = new.env(parent = globalenv()))
source(file.path(root, "scripts/database/196_summarize_inventory_units.R"), local = new.env(parent = globalenv()))

cat("Screened the current east coast Spanish mackerel unit and selected it for partial source curation.\n")
