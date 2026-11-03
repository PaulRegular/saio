root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))

stock_id <- "dfo_western_component_pollock_4xopqrs5"
candidate_id <- "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)"
model_id <- "dfo_western_component_pollock_2022_j_m4b"
hcr_id <- "dfo_western_component_pollock_2025_hcr_update"
sar_url <- "https://publications.gc.ca/collections/collection_2023/mpo-dfo/fs70-6/Fs70-6-2023-037-eng.pdf"
data_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-025-eng.pdf"
model_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-029-eng.pdf"
hcr_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-015-eng.pdf"
dry_run <- identical(Sys.getenv("TINYAM_IMPORT_DRY_RUN"), "1")

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = NA_character_, authority = "DFO",
  authority_stock_id = "Western Component Pollock (4Xopqrs + 5Yb + 5Zc)",
  scientific_name = "Pollachius virens",
  common_name = "Western Component Pollock",
  area = "NAFO 4Xopqrs plus Canadian portions of 5Yb and 5Zc",
  region = "Maritimes Region", ocean = "Northwest Atlantic",
  notes = paste(
    "The DFO science unit differs from the broader 4X5YbZc management area,",
    "which also includes 4Xmn. Do not merge with NOAA 5YZ."
  ))

model_assessment <- pacific_database_row("assessments",
  assessment_id = model_id, stock_id = stock_id,
  assessment_year = 2022L, terminal_year = 2020L,
  estimate_terminal_year = 2020L, assessment_type = "full_assessment",
  model_family = "statistical catch-at-age; Management Strategy Evaluation",
  model_version = "J_M4B",
  is_current = FALSE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = sar_url, framework_url = model_url,
  data_url = data_url, model_url = model_url,
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "J_M4B is the accepted candidate population model for the 2022 MSE.",
    "The 2026 research documents tabulate input series, but direct PDF requests",
    "from this environment return archived-page HTML. Only summary outputs that",
    "are explicitly stated in official reports have been imported."
  ))

hcr_assessment <- pacific_database_row("assessments",
  assessment_id = hcr_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L,
  assessment_type = "interim-year update",
  model_family = "harvest control rule update; no population-model refit",
  model_version = "2025 HCR update; Science Response 2026/015",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = hcr_url, framework_url = model_url,
  data_url = data_url, model_url = model_url,
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The latest interim update uses bottom-trawl data through 2025, acoustic",
    "data through 2024, and fishery data through the 2024-2025 fishing year.",
    "It applies the existing HCR and does not refit the age-structured model."
  ))

assumption <- function(assessment_id, component, setting, value, source_reference,
                       notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    region = "4Xopqrs5Yb5Zc", source_reference = source_reference,
    notes = notes)
}

assumptions <- do.call(rbind, list(
  assumption(model_id, "assessment", "accepted_model", "J_M4B statistical catch-at-age model.", model_url,
    "Accepted candidate population model within the 2022 MSE review."),
  assumption(model_id, "assessment", "terminal_data_year", "2020", sar_url),
  assumption(model_id, "fishery", "catch_at_age", "Ages 2-13, 1982-2020; thousands of fish.", model_url,
    "Corrected age assignments for 2017-2020 are used in the published table."),
  assumption(model_id, "survey", "bottom_trawl_index", "Summer RV age-specific relative-abundance indices; 1984-2020 with gaps.", model_url,
    "The MSE input review also describes the expanded age range and area treatment."),
  assumption(model_id, "survey", "acoustic_index", "Age-specific acoustic index for 2012 and 2016-2020.", model_url,
    "The age-specific index is derived from total biomass using tow length frequencies."),
  assumption(model_id, "M", "age_year_blocks", "M=0.2 for ages 2-4; ages 5+ vary across three periods: 1994-2000, 2001-2010, 2011-2020.", model_url,
    "The model supplies the age-year M matrix from the selected time-varying-M model; numeric matrix values are not imported."),
  assumption(model_id, "biology", "weights_and_maturity", "Model uses year- and age-specific weight and maturity inputs; SSB is start-of-year biomass for ages 4+.", model_url,
    "Numeric run-specific surfaces are not imported in this partial record."),
  assumption(model_id, "timing", "observation_timing", "Catch and tuning indices at mid-year; population outputs at start of year.", model_url),
  assumption(model_id, "likelihood", "index_and_catch_weights", "Commercial catch-at-age and both survey indices receive equal objective-function weights.", model_url),
  assumption(hcr_id, "assessment", "update_type", "Interim HCR update; the 2022 population model is unchanged.", hcr_url),
  assumption(hcr_id, "survey", "updated_series", "Bottom trawl through 2025; acoustic through 2024.", hcr_url),
  assumption(hcr_id, "fishery", "updated_series", "Canadian fishery data through the 2024-2025 fishing year.", hcr_url),
  assumption(hcr_id, "HCR", "reference_points", "LRP=14350 t; USR=22960 t; removal reference=0.187.", hcr_url),
  assumption(hcr_id, "HCR", "proxy_biomass", "Three-year geometric mean of available bottom-trawl and acoustic biomass indices, adjusted by model-generated index-specific q.", hcr_url,
    "This is a survey proxy used by the HCR, not the model-estimated SSB trajectory."),
  assumption(hcr_id, "HCR", "advice_year", "Catch advice is for fishing year 2026-2027.", hcr_url)
))

outputs <- pacific_database_row("outputs", n = 6L,
  assessment_id = c(rep(model_id, 3L), rep(hcr_id, 3L)),
  type = c("biomass", "mortality", "recruitment", "index", "catch", "mortality"),
  measure = c("ssb_age_4plus", "f_age_6_9", "mean_recruitment_age2_2016_2020",
    "survey_ssb_3yr_geomean_q_adjusted", "hcr_catch_advice", "hcr_relative_harvest_rate"),
  region = "4Xopqrs5Yb5Zc",
  year = c(2020L, 2020L, 2020L, 2025L, 2026L, 2026L),
  age_group = c("4+", "6-9", "2; mean 2016-2020", NA, NA, NA),
  value = c(21711, 0.124, 4700000, 28368, 2999, 0.11),
  unit = c("t", "per year", "fish", "t", "t", "proportion"),
  source_type = "official_document",
  source_reference = c(sar_url, hcr_url, sar_url, hcr_url, hcr_url, hcr_url),
  notes = c(
    "2020 model-estimated SSB for ages 4+; not the later q-adjusted survey proxy.",
    "F on ages 6-9 at the time of the 2022 MSE model; reported as 0.124.",
    "Mean age-2 recruitment for 2016-2020; not an annual 2020 cohort estimate.",
    "2025 q-adjusted three-year survey SSB proxy; distinct from model-estimated SSB.",
    "HCR catch advice for fishing year 2026-2027; not observed catch.",
    "Relative harvest rate corresponding to the 2026-2027 HCR advice; not model F."
  ))

inputs <- pacific_database_row("inputs", n = 0L)

prepare_record_update <- function(path, key_column, key_value, updates) {
  raw <- readBin(path, what = "raw", n = file.info(path)$size)
  text <- rawToChar(raw)
  key <- paste0("\"", key_value, "\",")
  starts <- gregexpr(key, text, fixed = TRUE)[[1L]]
  if (length(starts) != 1L || starts[1L] < 0L) stop("Could not locate one register record: ", key_value, call. = FALSE)
  start <- starts[1L]
  tail <- substring(text, start)
  newline <- regexpr("\n", tail, fixed = TRUE)[[1L]]
  if (newline < 0L) stop("Register record is not newline terminated.", call. = FALSE)
  record <- substring(tail, 1L, newline - 1L)
  if (endsWith(record, "\r")) record <- substr(record, 1L, nchar(record) - 1L)
  columns <- names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
  row <- utils::read.csv(text = record, header = FALSE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character())
  if (nrow(row) != 1L || ncol(row) != length(columns)) stop("Could not safely parse candidate record.", call. = FALSE)
  names(row) <- columns
  if (!key_column %in% columns || row[[key_column]][1L] != key_value) stop("Candidate key mismatch.", call. = FALSE)
  for (name in names(updates)) row[[name]][1L] <- as.character(updates[[name]])
  temp <- tempfile(fileext = ".csv")
  utils::write.csv(row, temp, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  rendered <- rawToChar(readBin(temp, "raw", n = file.info(temp)$size))
  unlink(temp)
  rendered_newline <- regexpr("\n", rendered, fixed = TRUE)[[1L]]
  updated_record <- sub("[\r\n]+$", "", substring(rendered, rendered_newline + 1L))
  record_end <- start + newline - 1L
  paste0(substring(text, 1L, start - 1L), updated_record, substring(text, record_end))
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidate_text <- prepare_record_update(candidate_path, "candidate_id", candidate_id,
  list(
    matched_stock_id = stock_id,
    match_status = "matched",
    import_status = "partial",
    review_date = "2026-11-02",
    catch_age_evidence = "Research Document 2026/029 Table 1 gives corrected commercial catch-at-age for ages 2-13 in 1982-2020, in thousands of fish. The exact table rows are not yet in the canonical database because direct PDF retrieval returns an archived-page notice.",
    survey_age_evidence = "The 2022 J_M4B model uses age-specific summer RV bottom-trawl abundance indices and the acoustic index for 2012 and 2016-2020. Numerical arrays remain to be transferred from the official reports.",
    weights_evidence = "The MSE report describes model weight-at-age surfaces; exact run-matched numeric values remain to be transferred and checked.",
    maturity_evidence = "The MSE report describes model maturity-at-age inputs; exact run-matched numeric values remain to be transferred and checked.",
    mortality_evidence = "J_M4B uses a time-blocked M matrix for ages 5+, with M=0.2 for ages 2-4; numeric fitted block values remain unimported.",
    timing_evidence = "The 2022 model treats catch and tuning indices as mid-year observations and reports population outputs at the start of year.",
    output_evidence = "Official sources report 2020 J_M4B SSB=21,711 t, mean age-2 recruitment of 4.7 million fish in 2016-2020, and recent F=0.124 for ages 6-9. The 2025 HCR update reports a distinct 2025 q-adjusted survey SSB proxy of 28,368 t and 2026-2027 advice of 2,999 t.",
    decision_reason = "Partial import records the latest 2022 J_M4B model summaries and the 2025 HCR update separately. The 2026 official documents tabulate core input arrays, but their direct PDF links return archived-page HTML in this environment; numeric inputs remain to be transferred before translation.",
    notes = "Current DFO science unit 4Xopqrs plus Canadian 5Yb and 5Zc, distinct from 4Xmn management geography and NOAA 5YZ. See source_reviews/dfo_western_component_pollock_2022.md."
  ))

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(selected_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
selected_row <- match("dfo_western_component_pollock_4xopqrs5", selected$candidate_unit_id)
if (is.na(selected_row)) stop("Selected-batch Pollock row is missing.", call. = FALSE)
selected$curation_status[selected_row] <- "partial_source_import"
selected$inventory_assessment_year[selected_row] <- 2025L
selected_tmp <- tempfile(tmpdir = dirname(selected_path), fileext = ".csv")
utils::write.csv(selected, selected_tmp, row.names = FALSE, na = "", fileEncoding = "UTF-8")

db <- file.path(root, "database")
existing_assessments <- utils::read.csv(file.path(db, "assessments.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)$assessment_id
existing_stocks <- utils::read.csv(file.path(db, "stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)$stock_id
if (!dry_run && (any(c(model_id, hcr_id) %in% existing_assessments) || stock_id %in% existing_stocks)) {
  stop("The Pollock stock or assessment record already exists; do not append twice.", call. = FALSE)
}

if (dry_run) {
  unlink(selected_tmp)
  cat("Dry run validated one stock, two assessment records, 15 assumptions, no numeric input rows, and 6 official summary outputs.\n")
} else {
  candidate_tmp <- tempfile(tmpdir = dirname(candidate_path), fileext = ".csv")
  writeBin(charToRaw(candidate_text), candidate_tmp)
  append_pacific_case(stock, rbind(model_assessment, hcr_assessment), assumptions, inputs, outputs)
  if (!file.copy(candidate_tmp, candidate_path, overwrite = TRUE) ||
      !file.copy(selected_tmp, selected_path, overwrite = TRUE)) {
    stop("Could not update the candidate and selected-batch registers.", call. = FALSE)
  }
  unlink(c(candidate_tmp, selected_tmp))
  cat("Imported partial DFO Western Component Pollock model and HCR source records.\n")
}
