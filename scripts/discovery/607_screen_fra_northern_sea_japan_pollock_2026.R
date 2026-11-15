candidate_path <- "discovery/candidates.csv"
report_url <- "https://www.fra.go.jp/shigen/fisheries_resources/meeting/stock_assessment_meeting/2026/files/sa2026-sc01/fra-sa2026-sc01-01.pdf"
meeting_url <- "https://www.fra.go.jp/shigen/fisheries_resources/meeting/stock_assessment_meeting/2026/sa2026-sc01.html"
candidate_id <- "FRA:FRA-SA2026-SC01-01"

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
if (any(!is.na(candidates$candidate_unit_id) &
    candidates$candidate_unit_id == "fra_northern_sea_of_japan_pollock" &
    candidates$candidate_id != candidate_id)) {
  stop("The FRA Northern Sea of Japan pollock candidate is already registered.",
    call. = FALSE)
}

row <- as.list(rep("", ncol(candidates)))
names(row) <- names(candidates)
values <- list(
  candidate_id = candidate_id,
  candidate_unit_id = "fra_northern_sea_of_japan_pollock",
  organization = "FRA (Japan)",
  official_stock_id = "",
  scientific_name = "Gadus chalcogrammus",
  stock_name = "Northern Sea of Japan walleye pollock",
  assessment_area = "Northern Sea of Japan; Noto Peninsula to the west coast of Sakhalin",
  inventory_assessment_year = "2026",
  inventory_url = meeting_url,
  retrieved_on = "2026-11-08",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FRA-SA2026-SC01-01 Supplementary Table 6 reports exact catch numbers-at-age",
    "for 1980-2025, ages 2-9 and 10+, in thousand fish."
  ),
  survey_age_evidence = paste(
    "Supplementary Tables 5-1 to 5-3 report the October spawning biomass index,",
    "April age-0 abundance, and August-September age-0/1/2 abundance series."
  ),
  weights_evidence = paste(
    "Supplementary Table 2-1 reports stock weight-at-age for ages 2-10+ in grams,",
    "with separate schedules for 2005 and earlier versus 2006 onward."
  ),
  maturity_evidence = paste(
    "Supplementary Tables 2-2 and 2-3 report female maturity and combined-sex",
    "maturity-at-age, respectively, for the same two periods."
  ),
  mortality_evidence = paste(
    "Natural mortality is fixed at 0.30 per year for ages 2 and younger and",
    "0.25 for ages 3+; ages 0-1 use age-2 M when deriving survey abundance."
  ),
  timing_evidence = paste(
    "Fishing year is April-March, age is assigned on April 1; surveys occur in",
    "April, August-September, and October."
  ),
  output_evidence = paste(
    "Supplementary Table 6 reports annual age-specific N, biomass, SSB and F",
    "for 1980-2025; annual output uncertainty is shown graphically, not tabulated."
  ),
  detailed_source_url = report_url,
  review_date = "2026-11-08",
  decision_reason = paste(
    "Eligible: the latest FRA 2026 assessment report provides numeric catch-age,",
    "survey-index, biological input, and age-specific output tables. This is a new",
    "Japanese assessment unit; no matching stock record was found. The detailed",
    "report is preliminary pending final formatting."
  ),
  notes = paste(
    "The assessment document number is FRA-SA2026-SC01-01; no separate official",
    "stock-unit code is listed. The candidate_unit_id is an internal crosswalk key.",
    "Distinct from U.S.-managed Alaska pollock units already in SAIO."
  )
)
for (name in names(values)) row[[name]] <- values[[name]]
row <- as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
row <- row[names(candidates)]
existing <- which(!is.na(candidates$candidate_id) &
  candidates$candidate_id == candidate_id)
if (!length(existing)) {
  write.table(row, candidate_path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n")
} else {
  if (length(existing) != 1L ||
      !identical(as.character(candidates$candidate_unit_id[existing]),
        "fra_northern_sea_of_japan_pollock")) {
    stop("The existing candidate row does not match the expected unit.",
      call. = FALSE)
  }
  identity_fields <- c(
    "candidate_id", "candidate_unit_id", "organization", "scientific_name",
    "stock_name", "inventory_assessment_year", "inventory_url",
    "detailed_source_url"
  )
  for (name in identity_fields) {
    old <- candidates[[name]][existing]
    if (is.na(old)) old <- ""
    if (!identical(as.character(old), as.character(values[[name]]))) {
      stop("The existing candidate identity differs in field ", name, ".",
        call. = FALSE)
    }
  }
  if (!candidates$eligibility[existing] %in% "eligible" ||
      !candidates$import_status[existing] %in% c("not_started", "imported")) {
    stop("The existing candidate has an unexpected import status.", call. = FALSE)
  }
}
updated <- read.csv(candidate_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
if (sum(!is.na(updated$candidate_id) &
    updated$candidate_id == candidate_id) != 1L ||
    sum(!is.na(updated$candidate_unit_id) &
      updated$candidate_unit_id == "fra_northern_sea_of_japan_pollock") != 1L) {
  stop("Candidate register append failed identity checks.", call. = FALSE)
}
