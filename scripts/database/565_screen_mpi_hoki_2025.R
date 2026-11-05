root <- "."
register_path <- file.path(root, "discovery", "candidates.csv")
candidate_id <- "MPI:HOK1"
candidate_unit_id <- "nz_hoki_hok1"

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "HOK 1",
  scientific_name = "Macruronus novaezelandiae",
  stock_name = "Hoki",
  assessment_area = "HOK 1, New Zealand EEZ",
  inventory_assessment_year = 2025,
  inventory_url = "https://www.mpi.govt.nz/fishing-aquaculture/fisheries-management/fish-stock-status/hoki-new-zealands-largest-fishery",
  retrieved_on = "2026-11-04",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The base model uses catch biomass by fishery and multinomial age-composition proportions with sample sizes, not numbers-at-age.",
    "FAR 2025/42 provides supporting catch, size, and age information."
  ),
  survey_age_evidence = paste(
    "Six trawl survey age-composition series are used with aggregate trawl and acoustic biomass indices.",
    "The model input appendix identifies the years and observation settings."
  ),
  weights_evidence = "Growth is represented by sex-specific length-at-age and length-weight functions; no direct weight-at-age matrix is supplied.",
  maturity_evidence = "The base model uses stock- and sex-specific maturity settings; the source parameters should be preserved rather than replaced by a newer maturity surface.",
  mortality_evidence = "Natural mortality is fixed as a category-level instantaneous-M vector with relative age selectivity; it is not a time-varying M-at-age series.",
  timing_evidence = "Model years run October through September and are labelled by ending year. The annual cycle has five time steps and the source model specifies survey timing.",
  output_evidence = "Table 10 reports posterior B0 and mid-season 2025 SSB medians and 95% intervals for East, West, and Total. Numeric annual age-specific N/F/M arrays remain unlocated.",
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/26195/FAR-2026-04-Assessment-of-hoki-in-2025.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26136/FAR-2025-42-Catches-size-and-age-structure-2023-24-hoki-fishery-and-input-data-for-2025-stock-assessment.pdf.ashx"
  ),
  review_date = "2026-11-04",
  decision_reason = paste(
    "Eligible for source curation: the latest detailed Casal2 run provides catch biomass, fishery and survey age compositions with sample sizes, acoustic and trawl biomass indices, biological assumptions, and posterior biomass outputs.",
    "Preserve the source likelihood inputs as supplied; catch numbers-at-age and direct age-specific biological surfaces are not provided as such."
  ),
  notes = paste(
    "HOK 1 is one management area with East and West biological stocks in the base model; the single-stock run is a model alternative, not another unit.",
    "The 2025 assessment uses fitted data through 2024; 2025 catches repeat 2024 for projection."
  ),
  stringsAsFactors = FALSE
)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (anyDuplicated(register$candidate_id)) stop("Candidate IDs are not unique.", call. = FALSE)
if (!identical(names(candidate), names(register))) stop("Candidate row does not match the register schema.", call. = FALSE)
existing <- which(register$candidate_id == candidate_id)
if (!length(existing)) {
  write.table(candidate, register_path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
    append = TRUE, eol = "\n")
} else if (length(existing) != 1L ||
  register$candidate_unit_id[existing] != candidate_unit_id ||
  register$official_stock_id[existing] != candidate$official_stock_id) {
  stop("Existing Hoki candidate does not match the reviewed stock unit.", call. = FALSE)
}

assessment_pdf <- file.path(root, "source_cache", "mpi_hoki_hok1_2025", "FAR-2026-04-Assessment-of-hoki-in-2025.pdf")
input_pdf <- file.path(root, "source_cache", "mpi_hoki_hok1_2025", "FAR-2025-42-Hoki-input-data.pdf")
manifest <- data.frame(
  local_file = basename(c(assessment_pdf, input_pdf)),
  source_url = c(
    "https://fs.fish.govt.nz/Doc/26195/FAR-2026-04-Assessment-of-hoki-in-2025.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26136/FAR-2025-42-Catches-size-and-age-structure-2023-24-hoki-fishery-and-input-data-for-2025-stock-assessment.pdf.ashx"
  ),
  retrieved_on = "2026-11-04",
  sha256 = c(
    "938A110A43BF1F509D15CF6680756EF22F28FA6E351CC6BD9AB58D63545A2714",
    "3C91D1898394B35D7089B51B0C550D9C6EA20D50F4BBF55EF8EA4AADEE000938"
  ),
  represented_source = c(
    "HOK 1 assessment in 2025; base two-stock model and single-stock alternative",
    "Supporting catch, size, and age data for the 2025 assessment"
  ),
  stringsAsFactors = FALSE
)
if (!all(file.exists(c(assessment_pdf, input_pdf)))) stop("Cached Hoki source files are missing.", call. = FALSE)
source_hashes <- unname(toupper(tools::sha256sum(c(assessment_pdf, input_pdf))))
if (!identical(source_hashes, manifest$sha256)) stop("Cached source checksums do not match the source manifest.", call. = FALSE)
write.csv(manifest, file.path(root, "provenance", "mpi_hoki_hok1_2025_sources.csv"), row.names = FALSE, na = "")

selection_path <- file.path(root, "discovery", "selected_batch_02_2026.csv")
selection <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "HOK 1",
  scientific_name = "Macruronus novaezelandiae",
  stock_name = "Hoki",
  assessment_area = "HOK 1, New Zealand EEZ",
  inventory_assessment_year = 2025,
  detailed_source_url = candidate$detailed_source_url,
  review_date = "2026-11-04",
  selection_basis = "First source-ready New Zealand candidate; this initial case selection is not a complete NZ/Australia inventory ranking.",
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE
)
if (!file.exists(selection_path)) write.csv(selection, selection_path, row.names = FALSE, na = "")

source(file.path(root, "scripts", "database", "195_summarize_discovery.R"), local = TRUE)
source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"), local = TRUE)
updated <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stopifnot(sum(updated$candidate_id == candidate_id) == 1L,
  updated$candidate_unit_id[updated$candidate_id == candidate_id] == candidate_unit_id,
  sum(updated$candidate_unit_id == candidate_unit_id, na.rm = TRUE) == 1L)
cat("Registered HOK 1 as a source-ready New Zealand candidate.\n")
