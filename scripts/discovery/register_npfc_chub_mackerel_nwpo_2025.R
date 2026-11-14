candidate_id <- "NPFC:CM_NWPO"
candidate_unit_id <- "npfc_chub_mackerel_nw_pacific"
retrieved_on <- "2026-11-06"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

candidate_path <- "discovery/candidates.csv"
manifest_path <- "provenance/npfc_chub_mackerel_nw_pacific_2025_sources.csv"
cache_root <- file.path("source_cache", "npfc_northwest_pacific_chub_mackerel_2025")

if (!file.exists(candidate_path)) {
  stop("Run this script from the SAIO repository root.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "NPFC",
  official_stock_id = "",
  scientific_name = "Scomber japonicus",
  stock_name = "Chub mackerel",
  assessment_area = "Northwest Pacific Ocean; NPFC Convention Area and Member EEZs",
  inventory_assessment_year = "2025",
  inventory_url = "https://www.npfc.int/stock-assessment-report-chub-mackerel-0",
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2025 base-case assessment uses member catch-at-age for FY1970-2023,",
    "ages 0-5 and 6+. The public report shows the series in a figure rather",
    "than a numerical table or downloadable input file. The 2026 SC10 report",
    "notes a correction and rerun after errors in the FY2014-2017 data; no",
    "corrected NPFC data arrays were located."
  ),
  survey_age_evidence = paste(
    "Seven fitted relative indices are described: Japanese summer age-0,",
    "Japanese autumn age-0 and age-1, Japanese egg-survey SSB, Japanese",
    "dip-net SSB, Chinese purse-seine vulnerable biomass, and Russian trawl",
    "vulnerable biomass. Numeric series are shown as figures, not downloadable",
    "run-matched observations."
  ),
  weights_evidence = paste(
    "Annual stock weight-at-age for ages 0-5 and 6+ is shown in a figure.",
    "For FY1970-2013 it comes from the Japanese domestic assessment; for",
    "FY2014-2023 it is a member-weighted series. The exact array is not",
    "published in the reviewed machine-readable sources."
  ),
  maturity_evidence = paste(
    "Base-case maturity-at-age is the annual Japanese domestic series for",
    "FY1970-2023, shown only as a figure in the reviewed input appendix.",
    "Exact annual values were not located."
  ),
  mortality_evidence = paste(
    "The assessment uses time-invariant age-specific M: 0.80, 0.60, 0.51,",
    "0.46, 0.43, 0.41, and 0.40 per year for ages 0, 1, 2, 3, 4, 5, and 6+."
  ),
  timing_evidence = paste(
    "Fishing years run July-June. Japanese indices include summer, autumn,",
    "egg-survey, and dip-net series. Exact within-year model timing for each",
    "series is not stated in the accessible report."
  ),
  output_evidence = paste(
    "The 2025 base-case report gives exact F- and SSB-reference-point values",
    "in Table E-1 and trajectory figures for biomass, SSB, recruitment, catch,",
    "mean F, and exploitation. Annual numeric N-at-age and F-at-age tables",
    "were not located."
  ),
  detailed_source_url = paste(
    "https://www.npfc.int/sites/default/files/2026-01/SC10%20Report.pdf;",
    "https://www.npfc.int/system/files/2025-07/NPFC-2025-TWG%20CMSA11-WP03%20SuppDoc.1%20Input_data_presentation_0.pdf;",
    "https://www.npfc.int/system/files/2026-03/NPFC-2026-SC10-Final%20Report.pdf;",
    "https://www.npfc.int/system/files/2026-04/NPFC-2026-COM10-WP02%20Rev.4%20CM%20adopted.pdf;",
    "https://abchan.fra.go.jp/wpt/wp-content/uploads/2026/03/details_2025_05.pdf"
  ),
  review_date = retrieved_on,
  decision_reason = paste(
    "This is a distinct joint Northwest Pacific assessment unit, not the",
    "NOAA-managed Pacific Coast unit that has the same species name. The",
    "official 2025 assessment report supports partial source records for",
    "age-specific M and Table E-1 reference points. Age-data eligibility",
    "remains unresolved because the other run-specific input arrays are not",
    "publicly available as numerical files and the documented FY2014-2017",
    "catch-at-age correction has no located corrected NPFC data package."
  ),
  notes = paste(
    "The NPFC source review treats the joint Northwest Pacific unit as one",
    "candidate, not separate national fleets or member areas. The SC10 report",
    "states that a corrected rerun followed the FY2014-2017 catch-at-age error;",
    "the correction's exact fitted outputs were not located. The NPFC scientific",
    "data database was still planned for 2027 in the April 2026 public notice."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manifest <- data.frame(
  local_file = c(
    file.path(cache_root, "NPFC-2026-SC10-Final-Report.pdf"),
    file.path(cache_root, "NPFC-2025-TWG-CMSA11-WP03-input-data-presentation.pdf"),
    file.path(cache_root, "NPFC-2026-COM10-WP02-Rev4-chub-mackerel-adopted.pdf"),
    file.path("source_cache", "japan_pacific_chub_mackerel_fra_2025",
      "FRA-SA2026-AC005_details_2025_05.pdf")
  ),
  source_url = c(
    "https://www.npfc.int/sites/default/files/2026-01/SC10%20Report.pdf",
    "https://www.npfc.int/system/files/2025-07/NPFC-2025-TWG%20CMSA11-WP03%20SuppDoc.1%20Input_data_presentation_0.pdf",
    "https://www.npfc.int/system/files/2026-04/NPFC-2026-COM10-WP02%20Rev.4%20CM%20adopted.pdf",
    "https://abchan.fra.go.jp/wpt/wp-content/uploads/2026/03/details_2025_05.pdf"
  ),
  retrieved_on = retrieved_on,
  sha256 = c(
    "F3770150C3754CAE40A8CBE0742DCCA00E09F57FC2CE79929CCA451FB3B9CA51",
    "C5F78A72321FD85A65847DBA3FA3588F20320CDB01BB5E0175107D0E432DEC8E",
    "246B2BF329693D2159B35E15F8577884CB6D1E332C3ED3A1D8632FBE9FE800DB",
    "EB43126DBF324C0F6102FDF2C797C2918CFD6B48F7C6952B52225975E46D14F4"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

register <- read_table(candidate_path)
stocks <- read_table("database/stocks.csv")
units <- read_table("discovery/inventory_units.csv")
cached_files <- manifest$local_file
actual_hashes <- toupper(unname(tools::sha256sum(cached_files)))

stopifnot(
  identical(names(candidate), names(register)),
  !candidate_id %in% register$candidate_id,
  !candidate_unit_id %in% register$candidate_unit_id,
  !candidate_unit_id %in% units$candidate_unit_id,
  !candidate$stock_name %in% stocks$common_name,
  identical(actual_hashes, toupper(manifest$sha256))
)

cat("Candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Assessment:", candidate$inventory_assessment_year, "NPFC base case\n")
cat("Age-input eligibility:", candidate$eligibility, "\n")
cat("Sources cached and checksummed:", nrow(manifest), "\n")

if (write_mode) {
  file_size <- file.info(candidate_path)$size
  if (file_size > 0) {
    con <- file(candidate_path, open = "rb")
    seek(con, where = file_size - 1, origin = "start")
    last_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(last_byte, as.raw(10L))) {
      con <- file(candidate_path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  write.table(candidate, candidate_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double",
    na = "", eol = "\n")
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Registered the screened NPFC unit and source provenance.\n")
}


