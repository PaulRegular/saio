candidate_id <- "MPI:GUR3"
candidate_unit_id <- "mpi_red_gurnard_gur3"
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
  official_stock_id = "GUR 3",
  scientific_name = "Chelidonichthys kumu",
  stock_name = "Red gurnard",
  assessment_area = "GUR 3 (East coast South Island)",
  inventory_assessment_year = "2022",
  inventory_url = "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx",
  retrieved_on = review_date,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The assessment provides annual catch biomass by BT-MIX and BT-FLA for 1985-2021,",
    "but explicitly reports no commercial age or length compositions. Catch-at-age",
    "cannot be reconstructed from survey age compositions."
  ),
  survey_age_evidence = paste(
    "Appendix Table A5 gives female and male survey age-composition proportions for",
    "1992-1994 (ages 1-9 and 10+; ESS 20); Table A4 gives 24 survey biomass indices",
    "with CVs. The assessment also uses length compositions, but no annual age-specific",
    "abundance series is published."
  ),
  weights_evidence = paste(
    "The report provides sex-specific von Bertalanffy growth, length-weight parameters,",
    "and length-at-age CV, but no precomputed weight-at-age series."
  ),
  maturity_evidence = "The base model fixes maturity at 0 for age 1, 0.5 for age 2, and 1 for ages 3+.",
  mortality_evidence = "Base-model natural mortality is fixed at 0.29 y-1 for females and 0.35 y-1 for males.",
  timing_evidence = paste(
    "The model has no seasonal structure; catches are taken midyear. The report identifies",
    "survey seasons and years but no within-year observation fraction."
  ),
  output_evidence = paste(
    "Tables 15-17 report MCMC SSB, status, F-threshold, yield, and projection summaries",
    "with 95% intervals. Annual numerical N-at-age and F-at-age surfaces are not tabulated."
  ),
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/25168/FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx;",
    "https://www.mpi.govt.nz/dmsdocument/71944/direct"
  ),
  review_date = review_date,
  decision_reason = paste(
    "Selected for partial source curation because the current detailed production run",
    "publishes numerical survey age compositions, survey biomass and CVs, annual catch",
    "biomass, biological assumptions, and comparable aggregate SSB/F outputs. The record",
    "will remain partial: no commercial age composition is available and CPUE values are",
    "not tabulated, so a complete age-disaggregated input set cannot be reconstructed."
  ),
  notes = paste(
    "Source-curation eligibility does not imply a complete age-specific catch series or",
    "translation readiness. Preserve the assessment's whole-QMA catches and FMA 3 survey",
    "coverage as distinct spatial scopes."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manifest <- data.frame(
  local_file = c(
    "nz_red_gurnard_gur3_2022/FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf",
    "nz_red_gurnard_gur7_2022/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf",
    "nz_red_gurnard_gur3_2022/Proposed-Fisheries-Research-Services-2026-27.pdf"
  ),
  source_url = c(
    "https://fs.fish.govt.nz/Doc/25168/FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx",
    "https://www.mpi.govt.nz/dmsdocument/71944/direct"
  ),
  retrieved_on = review_date,
  sha256 = c(
    "D5626CA8A0C9A6E6989291EBE7BFB0BFD7EB02E232E41CA62A810B2F31FA9DE7",
    "2CC34CFBB453287C5A4C05F3266DC8BB2B283BA9B3E94C498BC19BFE0C9D868B",
    "D02032286070B4DD9D8FBD985A7BDCA8AF8EDF52B89FF177DB3BFCB2C8A9C43D"
  ),
  represented_source = c(
    "FAR 2022/21, GUR 3 production assessment through model year 2021",
    "May 2026 Plenary, current assessment status",
    "Plan for the next GUR 3 production assessment, scheduled for completion in 2027"
  ),
  stringsAsFactors = FALSE
)

batch <- data.frame(
  priority = "1", candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand", official_stock_id = "GUR 3",
  scientific_name = "Chelidonichthys kumu", stock_name = "Red gurnard",
  assessment_area = "GUR 3 (East coast South Island)",
  inventory_assessment_year = "2022",
  detailed_source_url = paste(candidate$detailed_source_url, collapse = ""),
  review_date = review_date,
  selection_basis = paste(
    "Selected for partial source curation: the current detailed production report publishes annual catch biomass,",
    "survey biomass with CVs, numeric survey age and length compositions, fixed biology, and comparable SSB/F summary outputs.",
    "The source explicitly has no commercial age composition; catch-at-age cannot be reconstructed from the survey compositions,",
    "and the numerical BT-MIX CPUE vector is not tabulated. Import only the verified native series and outputs."
  ),
  curation_status = "selected_for_partial_source_import",
  stringsAsFactors = FALSE
)

register_path <- "discovery/candidates.csv"
manifest_path <- "provenance/mpi_red_gurnard_gur3_2022_sources.csv"
batch_path <- "discovery/selected_batch_17_2026.csv"
source_paths <- file.path("source_cache", manifest$local_file)
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
register <- read_table(register_path)

if (candidate_id %in% register$candidate_id ||
    candidate_unit_id %in% register$candidate_unit_id ||
    candidate_unit_id %in% stocks$stock_id ||
    candidate_unit_id %in% assessments$stock_id ||
    file.exists(manifest_path) || file.exists(batch_path)) {
  stop("GUR 3 is already registered or has canonical records.", call. = FALSE)
}
if (!identical(names(candidate), names(register)) ||
    !identical(names(batch), names(read_table("discovery/selected_batch_16_2026.csv")))) {
  stop("Candidate or batch fields do not match their register schemas.", call. = FALSE)
}
if (!all(file.exists(source_paths)) ||
    !identical(toupper(unname(tools::sha256sum(source_paths))), toupper(manifest$sha256))) {
  stop("Cached GUR 3 source documents are missing or their checksums differ.", call. = FALSE)
}

cat("Candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Latest detailed assessment:", candidate$inventory_assessment_year, "\n")
cat("Decision:", candidate$eligibility, "for partial source curation\n")
cat("Cached official sources verified:", nrow(manifest), "\n")

if (write_mode) {
  write.table(candidate, register_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  write.csv(batch, batch_path, row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Registered the GUR 3 source screen and selected partial curation.\n")
}
