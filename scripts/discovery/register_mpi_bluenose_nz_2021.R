candidate_id <- "MPI:BNS_NZ"
candidate_unit_id <- "mpi_bluenose_nz"
stock_id <- "mpi_bluenose_nz"
retrieved_on <- "2026-11-06"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "BNS (New Zealand-wide assessment unit)",
  scientific_name = "Hyperoglyphe antarctica",
  stock_name = "Bluenose",
  assessment_area = "New Zealand-wide single-stock model spanning BNS QMAs 1, 2, 3, 7, 8, and 10",
  inventory_assessment_year = "2021",
  inventory_url = "https://fs.fish.govt.nz/Doc/26241/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf.ashx",
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "Appendix D of FAR 2021/82 supplies fleet-specific catch biomass for 1936-2021",
    "and two fishery age-composition series. These compositions are proportions",
    "with supplied likelihood sample sizes, not catch numbers-at-age."
  ),
  survey_age_evidence = paste(
    "The model uses 12 aggregate commercial CPUE indices with annual CVs; no",
    "research-survey biomass or age-specific survey index is reported."
  ),
  weights_evidence = paste(
    "The base model supplies sex-specific empirical length-at-age and a common",
    "length-weight relationship. It does not list a direct weight-at-age vector."
  ),
  maturity_evidence = paste(
    "The base model specifies sex-specific logistic maturity ogives by age",
    "(male a50=15.1, ato95=5; female a50=16.7, ato95=10)."
  ),
  mortality_evidence = "The reference model fixes natural mortality at M=0.08 per year; Table 5 also reports M sensitivities.",
  timing_evidence = paste(
    "Model years are fishing years ending in the labelled year (October-September);",
    "spawning and all CPUE observations use the mid-year time-step proportion 0.5."
  ),
  output_evidence = paste(
    "FAR 2021/82 Table 5 reports the base-model MPD B0 and 2021 depletion (%B0).",
    "Annual numerical N-at-age, F-at-age, and recruitment trajectories are not tabulated."
  ),
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/25020/FAR-2021-82-New-Zealand-Bluenose-Stock-Assessment-2021.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26241/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf.ashx"
  ),
  review_date = retrieved_on,
  decision_reason = paste(
    "Selected for source curation because the May 2026 Plenary still identifies",
    "the 2021 model as the latest assessment and the accepted FAR 2021/82 publishes",
    "the full Casal2 population and observation inputs plus base-model outputs.",
    "No later completed assessment run was identified in the reviewed sources."
  ),
  notes = paste(
    "BNS QMAs are management areas; the 2021 assessment models one New Zealand-wide",
    "stock with background/features spatial partitions. The 2026 Plenary says stock",
    "boundaries remain uncertain and a single stock is most likely."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

selected <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "BNS (New Zealand-wide assessment unit)",
  scientific_name = "Hyperoglyphe antarctica",
  stock_name = "Bluenose",
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = "2021",
  detailed_source_url = candidate$detailed_source_url,
  review_date = retrieved_on,
  selection_basis = paste(
    "The latest 2026 Plenary confirms that the 2021 accepted CASAL2 assessment",
    "remains the latest run. FAR 2021/82 contains the full model input appendix",
    "and summary biomass outputs, making this a strong source-curation case."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manifest <- data.frame(
  local_file = c(
    "mpi_bluenose_nz_2021/FAR-2021-82-bluenose.pdf",
    "mpi_bluenose_nz_2021/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf"
  ),
  source_url = c(
    "https://webstatic.niwa.co.nz/library/FAR2021-82.pdf",
    "https://fs.fish.govt.nz/Doc/26241/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf.ashx"
  ),
  retrieved_on = retrieved_on,
  sha256 = c(
    "DD5B5A8734CDA32529BD879272469C9E2F3114A7A3BD7D5E8FE69C774658DC22",
    "52E0E771D267589A511C8EE1880B0B1FB7A84B5DD4C11E8C0DF0280C25517AA1"
  ),
  represented_source = c(
    "Accepted New Zealand bluenose assessment conducted in 2021; includes Casal2 model files and result tables",
    "Latest Fisheries Assessment Plenary chapter; confirms the 2021 model remains the latest assessment as of May 2026"
  ),
  stringsAsFactors = FALSE
)

register_path <- "discovery/candidates.csv"
units_path <- "discovery/inventory_units.csv"
progress_path <- "discovery/inventory_progress.csv"
selected_path <- "discovery/selected_batch_09_2026.csv"
manifest_path <- "provenance/mpi_bluenose_nz_2021_sources.csv"
source_paths <- file.path("source_cache", manifest$local_file)

register <- read_table(register_path)
units <- read_table(units_path)
stocks <- read_table("database/stocks.csv")
if (candidate_id %in% register$candidate_id || candidate_unit_id %in% register$candidate_unit_id ||
    stock_id %in% stocks$stock_id || file.exists(selected_path)) {
  stop("Bluenose candidate or stock is already registered.", call. = FALSE)
}
if (!identical(names(candidate), names(register))) {
  stop("Candidate fields do not match the candidate register.", call. = FALSE)
}
if (!identical(toupper(unname(tools::sha256sum(source_paths))), toupper(manifest$sha256))) {
  stop("Cached source checksums do not match the reviewed bluenose sources.", call. = FALSE)
}
unit_key <- paste0("candidate:", candidate_unit_id)
if (unit_key %in% units$unit_key || file.exists(selected_path) || file.exists(manifest_path)) {
  stop("Bluenose inventory unit, batch, or provenance manifest already exists.", call. = FALSE)
}

cat("Candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Decision:", candidate$eligibility, "; latest detailed run:", candidate$inventory_assessment_year, "\n")
cat("Sources cached and checksummed:", nrow(manifest), "\n")

if (write_mode) {
  write.table(candidate, register_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  write.csv(selected, selected_path, row.names = FALSE, na = "")
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")

  unit <- data.frame(
    unit_key = unit_key,
    matched_stock_id = "",
    candidate_unit_id = candidate_unit_id,
    match_status = "new",
    eligibility = "eligible",
    screening_status = "screened",
    import_status = "not_started",
    organizations = "Fisheries New Zealand",
    source_regions = "New Zealand",
    candidate_ids = candidate_id,
    inventory_entries = "1",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  write.table(unit, units_path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "")

  progress_lines <- readLines(progress_path, warn = FALSE)
  progress_index <- grep('^"Fisheries New Zealand","New Zealand",', progress_lines)
  if (length(progress_index) != 1L) stop("Expected one New Zealand inventory summary row.", call. = FALSE)
  progress <- read.csv(text = progress_lines[c(1L, progress_index)],
    stringsAsFactors = FALSE, check.names = FALSE)
  increment <- c("inventory_rows", "new", "eligible", "eligible_new", "screening_complete",
    "crosswalked_candidate_units", "eligible_new_units")
  for (field in increment) progress[[field]][1L] <- progress[[field]][1L] + 1L
  progress_lines[progress_index] <- capture.output(write.table(progress,
    sep = ",", row.names = FALSE, col.names = FALSE, quote = TRUE,
    qmethod = "double", na = ""))
  writeLines(progress_lines, progress_path, useBytes = TRUE)
  cat("Registered the selected bluenose unit and cached-source provenance.\n")
}

