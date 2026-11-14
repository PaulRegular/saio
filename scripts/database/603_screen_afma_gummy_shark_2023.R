root <- "."
retrieved_on <- "2026-11-07"
candidate_id <- "AFMA:SESSF_GUMMY_SHARK_2023"
candidate_unit_id <- "afma_gummy_shark_sessf"
report_url <- "https://www.afma.gov.au/sites/default/files/2024-02/Gummy_assessment_report_Dec2023_v3.pdf"
species_url <- "https://www.afma.gov.au/species/gummy-shark"
report_file <- file.path(root, "source_cache/afma_gummy_shark_2023/Gummy_assessment_report_Dec2023_v3.pdf")
expected_hash <- "3AA1245146CEE94FB36C89F9E8FB1FC134D647360896E401E5762D9E7CD467DC"

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- toupper(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result, value = TRUE)))
  if (length(hash) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hash
}

if (!file.exists(report_file) || !identical(sha256_file(report_file), expected_hash)) {
  stop("The cached AFMA report differs from the reviewed source.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "AFMA",
  official_stock_id = "SESSF Gummy Shark (Bass Strait, South Australia, Tasmania)",
  scientific_name = "Mustelus antarcticus",
  stock_name = "Gummy Shark",
  assessment_area = "Southern and Eastern Scalefish and Shark Fishery; three modeled components: Bass Strait, South Australia, and Tasmania",
  inventory_assessment_year = 2023L,
  inventory_url = species_url,
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "Appendix A, Tables 14-16 provide annual removals by eight gears and three model components for 1927-2022, in tonnes.",
    "These are total catch/removals, not catch-at-age. The report says the model uses age-composition data and conditional age-at-length data, but does not publish their numerical arrays."
  ),
  survey_age_evidence = paste(
    "The assessment fits aggregate gillnet, trawl, and shallow-line CPUE series for the three model components.",
    "No age-specific abundance-index likelihood is reported, and numeric CPUE vectors are not tabulated in the reviewed report."
  ),
  weights_evidence = "The report describes fixed sex-specific growth, but does not tabulate numerical annual or age-specific weight vectors.",
  maturity_evidence = "The assessment uses pup production as a proxy for spawning biomass; the reviewed report does not tabulate a numerical maturity/fecundity schedule by age.",
  mortality_evidence = "Bridge 17 estimates adult natural mortality shared among the three modeled components (0.18 per year) and calculates juvenile mortality to produce equilibrium without fishing.",
  timing_evidence = "The assessment is annual. The reviewed report does not identify fractional within-year timing for its CPUE series.",
  output_evidence = paste(
    "Table 5 reports Bridge 17 B0, MSYR, 1973 and terminal pup-production depletion, effort-saturation parameters, and negative log likelihood.",
    "The report identifies terminal depletion in 2022 as 50% for Bass Strait, 63% for South Australia, and 69% for Tasmania. No uncertainty intervals are given for these table values."
  ),
  detailed_source_url = paste(report_url, species_url, sep = "; "),
  review_date = retrieved_on,
  decision_reason = paste(
    "Selected for partial source curation because the latest detailed production run publishes numeric removals by gear and component for 1927-2022 and comparable fitted summary outputs.",
    "Age-input eligibility remains unresolved: the model uses age compositions and conditional age-at-length data, but the numeric arrays and age-specific biological vectors were not located in the reviewed public report."
  ),
  notes = paste(
    "One assessment case contains three modeled components (Bass Strait, South Australia, and Tasmania); preserve them as source regions rather than counting them as three cases.",
    "The Appendix A tables include Danish seine catches for some model runs; Danish seine is excluded from the official Bridge 17 base case."
  ),
  stringsAsFactors = FALSE
)

candidate_path <- file.path(root, "discovery/candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (candidate_id %in% candidates$candidate_id ||
    candidate_unit_id %in% candidates$candidate_unit_id ||
    any(tolower(stocks$scientific_name) == tolower(candidate$scientific_name)) ||
    any(grepl("gummy shark", stocks$common_name, ignore.case = TRUE))) {
  stop("A candidate or canonical stock record already matches Gummy Shark; reconcile it before adding a new unit.",
    call. = FALSE)
}
utils::write.table(candidate, candidate_path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")

selection_path <- file.path(root, "discovery/selected_batch_14_2026.csv")
if (file.exists(selection_path)) {
  stop("Selection batch 14 already exists; review it manually.", call. = FALSE)
}
selection <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "AFMA",
  official_stock_id = candidate$official_stock_id,
  scientific_name = candidate$scientific_name,
  stock_name = candidate$stock_name,
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = 2023L,
  detailed_source_url = candidate$detailed_source_url,
  review_date = retrieved_on,
  selection_basis = paste(
    "AFMA identifies the 2023 Bridge 17 assessment as the current detailed run.",
    "Appendix A contains numerical catch removals by gear and region for 1927-2022, while Table 5 gives fitted summary outputs.",
    "Select for partial source curation; numerical age-composition and conditional age-at-length arrays remain unresolved."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE
)
utils::write.csv(selection, selection_path, row.names = FALSE, na = "")

manifest <- data.frame(
  local_file = "source_cache/afma_gummy_shark_2023/Gummy_assessment_report_Dec2023_v3.pdf",
  source_url = report_url,
  record_url = species_url,
  retrieved_on = retrieved_on,
  sha256 = expected_hash,
  bytes = file.info(report_file)$size,
  description = "AFMA 2023 Gummy Shark production stock assessment report; Bridge 17 uses data through 2022.",
  stringsAsFactors = FALSE
)
utils::write.csv(manifest,
  file.path(root, "provenance/afma_gummy_shark_2023_sources.csv"),
  row.names = FALSE, na = "")

source(file.path(root, "scripts/database/195_summarize_discovery.R"),
  local = new.env(parent = globalenv()))
source(file.path(root, "scripts/database/196_summarize_inventory_units.R"),
  local = new.env(parent = globalenv()))

cat("Screened AFMA Gummy Shark and selected it for partial source curation.\n")
