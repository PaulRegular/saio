candidate_id <- "INIDEP:MERLUCCIUS_HUBBSI_SUR41"
candidate_unit_id <- "argentina_merluccius_hubbsi_south_41s"
retrieved_on <- "2026-11-07"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

report_url <- paste0(
  "https://fisheryprogress.org/system/files/",
  "INIDEP%20Official%20Technical%20Report%20No%2004742%20pp%202025.pdf"
)
act_url <- "https://cfp.gob.ar/actas/ACTA%20CFP%2034-2025.pdf"
source_files <- file.path("source_cache/inidep_merluccius_hubbsi_south_2025", c(
  "INIDEP_Official_Technical_Report_04742_2025.pdf",
  "acta_cfp_34_2025.pdf"
))
source_hashes <- c(
  "14B409AF21DE3AF0F212B536D178C23E952F654568A034B28F0705DADBE7BC15",
  "330DA13B1BF30FD768C2F0E564443D1193D553FE87DE7ECDB37C033968D0300C"
)

if (!all(file.exists(source_files)) ||
    !identical(toupper(unname(tools::sha256sum(source_files))), source_hashes)) {
  stop("Cache the reviewed INIDEP report and CFP act before registering this candidate.",
    call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "INIDEP",
  official_stock_id = "Efectivo sur de 41° S",
  scientific_name = "Merluccius hubbsi",
  stock_name = "Southern Argentine hake",
  assessment_area = "South Atlantic south of 41°S; most abundant from 42°S to 48°S",
  inventory_assessment_year = "2025",
  inventory_url = "",
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "INIDEP ITO 47/2025 Table 9 reports estimated catch numbers for ages 1-6",
    "and 7+ from 1986-2024, in thousands of fish, with total catch in tonnes.",
    "Catch-at-age includes Argentine and foreign fisheries, discards and bycatch."
  ),
  survey_age_evidence = paste(
    "Table 8 reports winter global-survey numbers at ages 1-6 and 7+ for selected",
    "years from 1996-2016 and 2024, in thousands of fish. Table 7 also reports",
    "summer age-2 recruitment indices and reproductive-biomass indices."
  ),
  weights_evidence = paste(
    "Table 6 reports population weight-at-age at 1 January and 1 July, ages 1-6",
    "and 7+, in kg."
  ),
  maturity_evidence = paste(
    "Table 6 reports the proportion mature by age for ages 1-6 and 7+."
  ),
  mortality_evidence = paste(
    "Table 6 specifies natural mortality M=0.3 per year for ages 1-6 and 7+."
  ),
  timing_evidence = paste(
    "The assessment is annual and identifies summer and winter survey series;",
    "a precise within-year sampling fraction is not stated in the report."
  ),
  output_evidence = paste(
    "Table 11 reports annual total biomass, spawning biomass, recruitment and a",
    "scalar F component for 1986-2024 with CVs. Table 12 reports model-estimated",
    "numbers at ages 1-6 and 7+ for 1986-2024."
  ),
  detailed_source_url = paste(report_url, act_url, sep = "; "),
  review_date = retrieved_on,
  decision_reason = paste(
    "The 2025 INIDEP production report evaluates the southern unit through 2024",
    "and recommends 2026 biological catch advice. CFP Act 34/2025 identifies",
    "ITO 47/2025 and establishes the 2026 catch limit for this unit. The report",
    "publishes age-disaggregated catch, survey, biological and output tables."
  ),
  notes = paste(
    "Source-led candidate found through targeted report searches, not a",
    "comprehensive national inventory. The signed INIDEP report copy was",
    "retrieved from Fishery Progress and cross-checked against the official CFP",
    "act; no direct institutional-hosted copy was located."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

selected <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "INIDEP",
  official_stock_id = candidate$official_stock_id,
  scientific_name = candidate$scientific_name,
  stock_name = candidate$stock_name,
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = candidate$inventory_assessment_year,
  detailed_source_url = candidate$detailed_source_url,
  review_date = retrieved_on,
  selection_basis = paste(
    "Select for source curation: the latest detailed run found reports catch-at-age,",
    "survey numbers-at-age, age-specific biology and annual model outputs; the",
    "official CFP act confirms the 2025 report informed 2026 advice."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manifest <- data.frame(
  local_file = source_files,
  source_url = c(report_url, act_url),
  record_url = c(report_url, act_url),
  retrieved_on = retrieved_on,
  sha256 = source_hashes,
  bytes = file.info(source_files)$size,
  description = c(
    "Signed INIDEP 2025 official technical report, assessment of the southern Merluccius hubbsi unit through 2024 and biological catch advice for 2026; publicly hosted by Fishery Progress.",
    "Official Consejo Federal Pesquero Act 34/2025; cites INIDEP ITO 47/2025 and sets the southern-unit catch limit for 2026."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

register_path <- "discovery/candidates.csv"
selected_path <- "discovery/selected_batch_12_2026.csv"
units_path <- "discovery/inventory_units.csv"
progress_path <- "discovery/inventory_progress.csv"
manifest_path <- "provenance/inidep_merluccius_hubbsi_south_2025_sources.csv"
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
units <- read.csv(units_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

if (candidate_id %in% register$candidate_id ||
    candidate_unit_id %in% register$candidate_unit_id ||
    candidate_unit_id %in% units$candidate_unit_id ||
    any(stocks$scientific_name == candidate$scientific_name &
      grepl("south of 41|41° S", paste(stocks$area, stocks$region, stocks$authority_stock_id),
        ignore.case = TRUE)) || file.exists(selected_path) || file.exists(manifest_path)) {
  stop("The southern hake candidate, stock unit, selection, or manifest already exists; reconcile before proceeding.",
    call. = FALSE)
}
if (!identical(names(candidate), names(register))) {
  stop("Candidate fields do not match the current register.", call. = FALSE)
}

unit <- data.frame(
  unit_key = paste0("candidate:", candidate_unit_id),
  matched_stock_id = "",
  candidate_unit_id = candidate_unit_id,
  match_status = "new",
  eligibility = "eligible",
  screening_status = "screened",
  import_status = "not_started",
  organizations = "INIDEP",
  source_regions = "Argentina; targeted assessment-report search, not a comprehensive inventory",
  candidate_ids = candidate_id,
  inventory_entries = 1L,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

progress <- data.frame(
  organization = "INIDEP",
  source_region = "Argentina; targeted assessment-report search, not a comprehensive inventory",
  inventory_rows = 1L,
  matched = 0L,
  new = 1L,
  ambiguous = 0L,
  identity_unreviewed = 0L,
  eligible = 1L,
  excluded = 0L,
  eligible_new = 1L,
  eligibility_unresolved = 0L,
  screening_not_started = 0L,
  screening_in_progress = 0L,
  screening_complete = 1L,
  matched_units = 0L,
  crosswalked_candidate_units = 1L,
  identity_unlinked_rows = 0L,
  eligible_new_units = 1L,
  ineligible_new_units = 0L,
  unresolved_new_units = 0L,
  mixed_new_units = 0L,
  other_candidate_units = 0L,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

cat("Candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Assessment:", candidate$inventory_assessment_year,
  "production report for 2026 advice\n")
cat("Eligibility:", candidate$eligibility, "\n")
cat("Cached, checksummed primary sources:", nrow(manifest), "\n")

if (write_mode) {
  write.table(candidate, register_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  write.csv(selected, selected_path, row.names = FALSE, na = "")
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  write.table(unit, units_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  write.table(progress, progress_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  cat("Registered the source-led candidate and selected its assessment for curation.\n")
}
