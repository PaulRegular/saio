candidate_id <- "ICES:ane.27.8"
candidate_unit_id <- "ices_bay_biscay_anchovy_8"
review_date <- "2026-11-08"
candidate_path <- "discovery/candidates.csv"
batch_path <- "discovery/selected_batch_19_2026.csv"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

sources <- data.frame(
  file = c(
    "source_cache/ices_ane_27_8/ices_wghansa_2025_report.pdf",
    "source_cache/ices_ane_27_8/stock_annex.pdf",
    "source_cache/ices_ane_27_8/ices_wgacegg_2025_survey_report.pdf",
    "source_cache/ices_ane_27_8/ices_2025_advice_ane_27_8.pdf",
    "source_cache/ices_ane_27_8/ices_standardgraphs_source_data.html"
  ),
  sha256 = c(
    "91A780F00878529C9CEE208137A9F9EDE22F49AD1A83C5840D1D72395103C6D9",
    "68A47D82EC4B83AF0F85D84FCF57D83BC087910F84F2069C363405F93E9A307C",
    "B5ED2946E7A28B8F7CE3FD789BD8B77447E42688BE8CCAE7CF2B08015902A7A3",
    "461BB0E6EB7D8C2E97B853F5585AAB920102943E26BB9F7EBC9E2F63B762197F",
    "994A20018912B26B2FAA1AD2FB9072C741C47E961B2F5E9C0154DACFDB7CE4C3"
  ),
  stringsAsFactors = FALSE
)
source_hashes <- unname(toupper(tools::sha256sum(sources$file)))
if (!all(file.exists(sources$file)) || !identical(source_hashes, sources$sha256)) {
  stop("Cached ICES source files are missing or differ from the reviewed versions.", call. = FALSE)
}

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to verify the cached assessment report before selection.", call. = FALSE)
}
report_text <- paste(pdftools::pdf_text(sources$file[1L]), collapse = "\n")
required_sections <- c(
  "Table 2.5.2.1", "Table 2.5.3.2", "Table 2.5.3.3", "Table 2.5.3.4",
  "Catch-at age", "BIOMAN DEPM survey", "PELGAS spring acoustic survey",
  "JUVENA autumn acoustic survey", "Maturity-at-age", "Natural mortality"
)
if (!all(vapply(required_sections, grepl, logical(1L), x = report_text, fixed = TRUE))) {
  stop("The cached report is missing one or more reviewed input/output sections.", call. = FALSE)
}

read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- read_table(candidate_path)
candidate_row <- which(candidates$candidate_id == candidate_id)
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
if (length(candidate_row) != 1L ||
    candidates$screening_status[candidate_row] != "screened" ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started" ||
    candidate_unit_id %in% stocks$stock_id ||
    candidate_unit_id %in% assessments$stock_id ||
    file.exists(batch_path)) {
  stop("The ICES candidate is not eligible for a new selection checkpoint.", call. = FALSE)
}

candidates$assessment_area[candidate_row] <- "ICES Subarea 8 (Bay of Biscay)"
candidates$catch_age_evidence[candidate_row] <- paste(
  "WGHANSA 2025 Table 2.5.2.1 describes the fitted catch input as biomass and",
  "catch-at-age for ages 1, 2, and 3+ by semester, 1987-2025, in tonnes and",
  "thousands of fish. Table 2.2.3.2 reports historical catches-at-age by semester",
  "through 2024 with finer ages 0-5. The 2025 catch is provisional and the",
  "assessment-year second-semester age composition is unavailable."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Table 2.5.2.1 describes BIOMAN and PELGAS numbers-at-age for ages 1, 2, and",
  "3+ and the JUVENA age-0 series, all in thousands of fish. BIOMAN and PELGAS",
  "historical age series are graphed; 2025 BIOMAN values are tabulated, while",
  "JUVENA Table 2.3.3.1 reports age-0 biomass in tonnes. Recovering historical",
  "index values may require documented digitization or source-supported conversion."
)
candidates$weights_evidence[candidate_row] <- paste(
  "WGHANSA 2025 Table 2.2.4.1 reports mean catch weight-at-age by semester",
  "through 2024 in grams. Stock weight-at-age at spawning comes from BIOMAN, with",
  "linear interpolation for missing years; keep these series distinct."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "WGHANSA 2025 section 2.4.1: maturity is 0 at age 0 and 1 at ages 1, 2, and 3+."
)
candidates$mortality_evidence[candidate_row] <- paste(
  "WGHANSA 2025 section 2.4.2: M0=2.17, M1=0.80, M2=1.20, and M3+=2.26 per year.",
  "M0 is back-calculated with the Gislason model; M3+ was estimated at the 2024",
  "benchmark and retained in the 2025 assessment."
)
candidates$timing_evidence[candidate_row] <- paste(
  "The model has two seasons (January-June and July-December), spawning on 15 May,",
  "and recruitment settlement on 1 July. BIOMAN and PELGAS are spring surveys;",
  "JUVENA is an autumn survey. Confirm the exact model sampling fractions from the",
  "stock annex before translating."
)
candidates$output_evidence[candidate_row] <- paste(
  "WGHANSA 2025 Table 2.5.3.2 reports annual SSB, recruitment, and apical F with",
  "95% intervals through 2025; Tables 2.5.3.3 and 2.5.3.4 report F-at-age by",
  "semester and beginning-of-year N-at-age through 2024, without intervals.",
  "Catch for 2025 is an assumption; M-at-age is fixed input, not an estimated output."
)
candidates$detailed_source_url[candidate_row] <- paste(
  "https://doi.org/10.17895/ices.pub.29335520.v3;",
  "https://doi.org/10.17895/ices.pub.28053440.v2;",
  "https://doi.org/10.17895/ices.pub.31353469.v3;",
  "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265;",
  "https://asd.ices.dk/viewAdvice/4005"
)
candidates$review_date[candidate_row] <- review_date
candidates$decision_reason[candidate_row] <- paste(
  "The 2025 production run is the active ICES assessment used for 2026 advice.",
  "The official report identifies catch-at-age, age-specific BIOMAN and PELGAS",
  "series, JUVENA age-0 information, biological inputs, and age-specific outputs.",
  "Historical survey series are partly graphical and require value-level source",
  "recovery before completeness can be judged; select for source curation without",
  "treating graphical descriptions as already imported numerical observations."
)
candidates$notes[candidate_row] <- paste(
  "Run identity: WGHANSA 2025, Stock Synthesis 3.30.22.beta, assessment key 21265,",
  "used for 2026 advice. The 2025 report's BIOMAN narrative states 145,608 t, while",
  "Tables 2.3.1.3, 2.3.1.4, and 2.5.1.1 report/use 157,247 t; preserve this source",
  "discrepancy and use the model input table for the fitted series. Source PDFs and",
  "Standard Graphs data are cached in source_cache/ices_ane_27_8; checksums and",
  "retrieval metadata are in provenance/ices_ane_27_8_sources.csv. No canonical",
  "assessment or numerical records are added by this selection checkpoint."
)

batch <- data.frame(
  priority = "1", candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "ICES", official_stock_id = "ane.27.8",
  scientific_name = "Engraulis encrasicolus",
  stock_name = "Anchovy (Engraulis encrasicolus) in Subarea 8 (Bay of Biscay)",
  assessment_area = "ICES Subarea 8 (Bay of Biscay)",
  inventory_assessment_year = "2025",
  detailed_source_url = candidates$detailed_source_url[candidate_row],
  review_date = review_date,
  selection_basis = paste(
    "Selected for source curation from the current 2025 ICES Stock Synthesis run.",
    "It has catch-age and age-specific survey information plus comparable N/F/SSB",
    "outputs. Historical survey values must be recovered from the report's charts or",
    "other official data sources and recorded with any digitization/conversion details."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE, check.names = FALSE
)
if (!identical(names(batch), names(read_table("discovery/selected_batch_18_2026.csv")))) {
  stop("Selection fields do not match the selected-batch schema.", call. = FALSE)
}

cat("Verified official 2025 assessment tables, current assessment identity, and cached source checksums.\n")
cat("Selected ICES ane.27.8 for source curation; historical survey data remain to be recovered.\n")
if (write_mode) {
  source("scripts/database/candidate_register_io.R", local = TRUE)
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  write.csv(batch, batch_path, row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Recorded selected batch 19 and refreshed discovery summaries.\n")
}
