candidate_id <- "MPI:GUR7"
candidate_unit_id <- "mpi_red_gurnard_gur7"
review_date <- "2026-11-08"
report <- file.path("source_cache", "nz_red_gurnard_gur7_2022",
  "FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf")
candidate_path <- "discovery/candidates.csv"
batch_path <- "discovery/selected_batch_18_2026.csv"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to verify the cached GUR 7 assessment tables.", call. = FALSE)
}
if (!identical(toupper(unname(tools::sha256sum(report))),
  "C6AFAA340A1EDBDC44E8B6B0AB9DCDD17262558E098859F0DC57DB11E4E1CD84")) {
  stop("The cached GUR 7 report does not match the reviewed source.", call. = FALSE)
}

pdf_lines <- unlist(lapply(pdftools::pdf_text(report), function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE)

normalize_numbers <- function(x) {
  gsub("(?<=\\d) (?=\\d{3}(?:\\.|\\s|$))", "", x, perl = TRUE)
}

number_tokens <- function(x) {
  x <- normalize_numbers(x)
  hits <- regmatches(x, gregexpr("[0-9]+(?:\\.[0-9]+)?", x, perl = TRUE))[[1L]]
  if (identical(hits, character(0))) numeric() else as.numeric(hits)
}

section_lines <- function(start, end) {
  a <- grep(start, pdf_lines)
  b <- grep(end, pdf_lines)
  if (length(a) != 1L || length(b) != 1L || b <= a) {
    stop("Could not locate a unique GUR 7 source-table section.", call. = FALSE)
  }
  pdf_lines[(a + 1L):(b - 1L)]
}

age_lines <- section_lines("^Table A2:", "^Table A3a:")
age_lines <- age_lines[grepl("^\\s*(10|[1-9])\\s+0\\.", age_lines, perl = TRUE)]
age_rows <- lapply(age_lines, number_tokens)
if (length(age_rows) != 10L || any(lengths(age_rows) != 11L)) {
  stop("Table A2 does not contain ten ages and ten numeric proportions per age.", call. = FALSE)
}
age_values <- do.call(rbind, age_rows)
if (!identical(as.integer(age_values[, 1L]), 1:10) ||
    any(age_values[, -1L] < 0 | age_values[, -1L] > 1)) {
  stop("Table A2 ages or proportions differ from the reviewed source.", call. = FALSE)
}
age_years <- c(1994L, 1995L, 2003L, 2005L, 2007L)
age_totals <- vapply(seq_along(age_years), function(i) {
  sum(age_values[, 1L + i], age_values[, 6L + i])
}, numeric(1))
if (any(abs(age_totals - 1) > 0.001)) {
  stop("Table A2 female and male components do not sum to one by survey year.", call. = FALSE)
}

read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)

candidates <- read_table(candidate_path)
candidate_row <- match(candidate_id, candidates$candidate_id)
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
if (is.na(candidate_row) || candidates$import_status[candidate_row] != "not_started" ||
    candidates$screening_status[candidate_row] != "screened" ||
    candidate_unit_id %in% stocks$stock_id || candidate_unit_id %in% assessments$stock_id ||
    file.exists(batch_path)) {
  stop("GUR 7 is missing, already curated, or already selected for batch 18.", call. = FALSE)
}

candidates$survey_age_evidence[candidate_row] <- paste(
  "Appendix Table A2 tabulates the complete female/male age-composition vectors",
  "for 1994, 1995, 2003, 2005, and 2007, ages 1-9 and 10+; Table 3 assigns ESS 50.",
  "The sex components sum together to approximately one for each year."
)
candidates$decision_reason[candidate_row] <- paste(
  "The report publishes numeric survey age compositions, survey biomass and CVs,",
  "annual commercial catch biomass, fixed biology, and comparable aggregate outputs.",
  "Select for partial current-unit source recovery. It remains ineligible for the",
  "complete age-disaggregated batch because there are no commercial age compositions",
  "or catch-at-age, and no precomputed weight-at-age series."
)
candidates$notes[candidate_row] <- paste(
  "The previous screen incorrectly stated that survey age vectors were not tabulated;",
  "Appendix Table A2 contains numeric proportions. A partial source record will preserve",
  "the available survey compositions, but catch-at-age and annual N/F age outputs remain",
  "unavailable. Fisheries New Zealand plans an assessment update for completion in 2027."
)

batch <- data.frame(
  priority = "1", candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand", official_stock_id = "GUR 7",
  scientific_name = "Chelidonichthys kumu", stock_name = "Red gurnard",
  assessment_area = "GUR 7 (Challenger)", inventory_assessment_year = "2022",
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/25169/FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx"
  ),
  review_date = review_date,
  selection_basis = paste(
    "Selected for partial current-unit source recovery: the 2022 production report publishes",
    "commercial catch biomass, 15 survey biomass/CV observations, numeric survey age and length",
    "compositions, fixed biology, and aggregate assessment outputs. The report has no commercial",
    "age compositions, so catch-at-age is unavailable; this is not a complete age-input or",
    "translation-ready case."
  ),
  curation_status = "selected_for_partial_source_import",
  stringsAsFactors = FALSE, check.names = FALSE
)
if (!identical(names(batch), names(read_table("discovery/selected_batch_17_2026.csv")))) {
  stop("Selection fields do not match the selected-batch schema.", call. = FALSE)
}

cat("Verified Table A2: five years, ages 1-10+, female/male components sum to one.\n")
cat("Selected GUR 7 for partial current-unit source recovery; complete age-input eligibility remains ineligible.\n")

if (write_mode) {
  write.csv(candidates, candidate_path, row.names = FALSE, na = "")
  write.csv(batch, batch_path, row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Recorded GUR 7 selection and refreshed discovery summaries.\n")
}
