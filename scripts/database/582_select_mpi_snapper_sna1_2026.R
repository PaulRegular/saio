root <- "."
candidate_id <- "MPI:SNA1"
candidate_unit_id <- "mpi_snapper_sna1"
stock_id <- "mpi_snapper_sna1"
register_path <- file.path(root, "discovery", "candidates.csv")
selection_path <- file.path(root, "discovery", "selected_batch_05_2026.csv")

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
if (sum(register$candidate_id == candidate_id, na.rm = TRUE) > 1L ||
    any(register$candidate_unit_id == candidate_unit_id &
      register$candidate_id != candidate_id, na.rm = TRUE)) {
  stop("SNA 1 candidate or unit has a conflicting register entry.", call. = FALSE)
}
candidate_present <- candidate_id %in% register$candidate_id
if (candidate_present &&
    register$candidate_unit_id[match(candidate_id, register$candidate_id)] != candidate_unit_id) {
  stop("The registered SNA 1 candidate has an unexpected unit key.", call. = FALSE)
}

stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
if (stock_id %in% stocks$stock_id) {
  stop("SNA 1 is already in the canonical stock table.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "SNA 1",
  scientific_name = "Chrysophrys auratus",
  stock_name = "Snapper",
  assessment_area = "SNA 1: East Northland, Hauraki Gulf, and Bay of Plenty",
  inventory_assessment_year = "2023",
  inventory_url = "https://fs.fish.govt.nz/Doc/26109/snapper-sna-1-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx",
  retrieved_on = "2026-11-06",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2024/47 describes fishery catch histories and age-composition observations.",
    "Compositions are separate from catch totals; exact model series and any",
    "numbers-at-age reconstruction remain to be verified from the cited sources."
  ),
  survey_age_evidence = paste(
    "FAR 2024/47 Table 40 lists Hauraki Gulf and Bay of Plenty trawl-survey",
    "relative-number indices for ages 1-5 and a relative-biomass index for age 6+.",
    "East Northland Table 33 lists bottom-trawl CPUE and tag-based estimates,",
    "not age-specific survey indices; exact numeric rows remain to be imported."
  ),
  weights_evidence = paste(
    "FAR 2024/47 specifies regional mean length-at-age through 2021 and",
    "length-weight relationships. A complete numeric assessment weight-at-age",
    "surface has not yet been imported."
  ),
  maturity_evidence = paste(
    "The base assessment fixes maturity at 0 for ages 1-3, 0.5 at age 4,",
    "and 1 for ages greater than 4."
  ),
  mortality_evidence = "The base assessment fixes natural mortality at 0.075 y-1.",
  timing_evidence = paste(
    "The model uses two annual time steps; most observations are assigned to",
    "the spring-summer second step. Tag-release timing is treated separately."
  ),
  output_evidence = paste(
    "FAR 2024/47 reports MCMC biomass, status, and exploitation summaries with",
    "uncertainty. Numerical annual age-specific N, F, and M arrays were not",
    "located in the reviewed report tables."
  ),
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/25775/FAR-2024-47-Assessment-of-SNA1-stocks%20in-2022-and-2023.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/25280/FAR-2022-24-Snapper-Age-Composition-SNA1-SNA2-201920-4267.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/25557/FAR-2023-41-Snapper-CPUE-For-Hauraki-Gulf-And-East-Northland-Trawl-Fisheries-To-202021-4414.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26109/snapper-sna-1-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx"
  ),
  review_date = "2026-11-06",
  decision_reason = paste(
    "Eligible for source curation: the latest detailed production assessment",
    "is age-structured and documents fishery age compositions, age-specific",
    "trawl-survey indices, biological assumptions, and comparable biomass",
    "outputs. Treat the three modeled biological components as one current",
    "SNA 1 management unit. Import each source series only after verifying its",
    "years, units, uncertainty, and role in the accepted run."
  ),
  notes = paste(
    "No canonical numerical records have yet been imported. FAR 2024/69 reports",
    "2022-23 age samples after the represented 2023 assessment and is context,",
    "not an input to that run."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
candidate[] <- lapply(candidate, as.character)
if (!identical(names(candidate), names(register))) {
  stop("Candidate row does not match the register columns.", call. = FALSE)
}

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
if (candidate_present) {
  candidate_index <- match(candidate_id, register$candidate_id)
  if (register$import_status[candidate_index] != "not_started") {
    stop("SNA 1 has already entered canonical import; refusing to replace its discovery row.", call. = FALSE)
  }
  replace_candidate_register_row(register_path, candidate_index, candidate, candidate_id)
} else {
  candidate_line <- capture.output(write.table(candidate, file = "", sep = ",",
    row.names = FALSE, col.names = FALSE, quote = TRUE, na = "",
    qmethod = "double", eol = ""))
  bytes <- readBin(register_path, "raw", n = file.info(register_path)$size)
  if (length(bytes) && tail(bytes, 1L) != as.raw(10L)) {
    cat("\n", file = register_path, append = TRUE, sep = "")
  }
  cat(candidate_line, "\n", file = register_path, append = TRUE, sep = "")
}

selection <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "SNA 1",
  scientific_name = "Chrysophrys auratus",
  stock_name = "Snapper",
  assessment_area = "SNA 1: East Northland, Hauraki Gulf, and Bay of Plenty",
  inventory_assessment_year = 2023L,
  detailed_source_url = "https://fs.fish.govt.nz/Doc/25775/FAR-2024-47-Assessment-of-SNA1-stocks%20in-2022-and-2023.pdf.ashx",
  review_date = "2026-11-06",
  selection_basis = paste(
    "The latest detailed assessment has commercial age compositions, age-specific",
    "trawl-survey indices, documented biology, and comparable reported biomass",
    "outputs. The three biological areas are kept within one SNA 1 stock unit."
  ),
  curation_status = "selected",
  stringsAsFactors = FALSE
)
write.csv(selection, selection_path, row.names = FALSE, na = "")

source(file.path(root, "scripts", "database", "195_summarize_discovery.R"))
source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"))

updated <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stopifnot(nrow(updated) == nrow(register) + as.integer(!candidate_present),
  sum(updated$candidate_id == candidate_id) == 1L,
  updated$candidate_unit_id[updated$candidate_id == candidate_id] == candidate_unit_id,
  sum(updated$candidate_unit_id == candidate_unit_id, na.rm = TRUE) == 1L,
  !anyDuplicated(updated$candidate_id))

cat("Registered and selected SNA 1 for source curation; no canonical source values were added.")
