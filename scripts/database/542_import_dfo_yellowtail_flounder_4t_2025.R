root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))

assessment_id <- "dfo_yellowtail_flounder_4t_2025"
stock_id <- "dfo_yellowtail_flounder_4t"
candidate_id <- "DFO:Gulf:Yellowtail Flounder - NAFO 4T"
report_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41331849.pdf"
research_document_url <- "https://publications.gc.ca/pub?id=9.964766&sl=0"
dry_run <- identical(Sys.getenv("SAIO_IMPORT_DRY_RUN"), "1")

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = NA_character_, authority = "DFO",
  authority_stock_id = "NAFO Division 4T", scientific_name = "Myzopsetta ferruginea",
  common_name = "Yellowtail flounder", area = "NAFO Division 4T",
  region = "Southern Gulf of St. Lawrence", ocean = "Northwest Atlantic",
  notes = paste(
    "Current DFO stock unit; distinct from United States yellowtail-flounder units.",
    "Detailed 2025 assessment inputs and trajectories remain unavailable from the linked PDF."
  ))

assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "state-space age-structured model",
  model_version = "2025 assessment; detailed companion Research Document 2026/054",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = NA_character_,
  data_url = NA_character_, model_url = research_document_url,
  repository_url = NA_character_, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "2025 full assessment used for 2025 advice. The official summary report is accessible,",
    "but the Research Document 2026/054 PDF link currently redirects to an archived-page notice.",
    "Only the age-5+ biomass estimate and the reported recent F=0 statement are imported."
  ))

assumption <- function(component, setting, value, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    region = "4T", source_reference = report_url, notes = notes)
}

assumptions <- do.call(rbind, list(
  assumption("assessment", "approach", "Full state-space age-structured assessment.",
    "The detailed process specification is not available from the accessible summary."),
  assumption("assessment", "terminal_data_year", "2025"),
  assumption("fishery", "inputs", "Annual catch totals and numbers-at-age proportions by seine and trawl fleets, 1985-2022.",
    "Input types and years are stated in the Science Advisory Report; numerical source arrays were not recovered."),
  assumption("survey", "inputs", "Annual RV age proportions and age-aggregated biomass index, 1985-2025; RV maturity-at-age and weight-at-age, 1985-2025.",
    "Input types and years are stated in the Science Advisory Report; numerical source arrays were not recovered."),
  assumption("biology", "age_length_keys", "Updated age-length keys include earlier-period information to refine growth and maturity dynamics."),
  assumption("survey", "vessel_gear_change", "RV vessel and gear changed in 2021; length-dependent conversion factors were applied to maintain survey continuity."),
  assumption("M", "process", "Time-varying, age-dependent natural mortality; summary groups are ages 4-7, 8-9 and 10+.",
    "Exact age treatment, annual values and process likelihood were not recovered."),
  assumption("biomass", "reported_definition", "Stock biomass is biomass of ages 5+; it is not reported as spawning-stock biomass."),
  assumption("reference_points", "limit_reference_point", "25800 t"),
  assumption("uncertainty", "reported_interval", "2025 age-5+ stock biomass has a 95% confidence interval; detailed annual and age-specific uncertainty was not recovered.")
))

outputs <- pacific_database_row("outputs", n = 4L,
  assessment_id = assessment_id,
  type = c("biomass", rep("mortality", 3L)),
  measure = c("biomass_age_5plus", rep("fishing_mortality_age_4_10plus", 3L)),
  region = "4T", year = c(2025L, 2023:2025),
  age_group = c("5+", rep("4-10+", 3L)),
  value = c(8269, 0, 0, 0),
  lwr = c(5666, rep(NA_real_, 3L)),
  upr = c(10872, rep(NA_real_, 3L)),
  unit = c("t", rep("per year", 3L)),
  source_type = "official_document", source_reference = report_url,
  notes = c(
    "Official 2025 age-5+ stock biomass; 95% confidence interval. Not SSB.",
    rep("The report states F for ages 4-10+ has been zero since the fishery closure after 2022.", 3L)
  ))

inputs <- pacific_database_row("inputs", n = 0L)

prepare_record_update <- function(path, key_column, key_value, updates) {
  raw <- readBin(path, what = "raw", n = file.info(path)$size)
  text <- rawToChar(raw)
  key <- paste0("\"", key_value, "\",")
  starts <- gregexpr(key, text, fixed = TRUE)[[1L]]
  if (length(starts) != 1L || starts[1L] < 0L) {
    stop("Could not locate one register record for: ", key_value, call. = FALSE)
  }
  start <- starts[1L]
  tail <- substring(text, start)
  newline <- regexpr("\n", tail, fixed = TRUE)[[1L]]
  if (newline < 0L) stop("Register record is not newline terminated.", call. = FALSE)
  record <- substring(tail, 1L, newline - 1L)
  if (endsWith(record, "\r")) record <- substr(record, 1L, nchar(record) - 1L)
  columns <- names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
  row <- utils::read.csv(text = record, header = FALSE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character())
  if (nrow(row) != 1L || ncol(row) != length(columns)) {
    stop("Could not safely parse the single-line register record in ", path,
      " (found ", ncol(row), " columns; expected ", length(columns), ").",
      call. = FALSE)
  }
  names(row) <- columns
  if (!key_column %in% columns || row[[key_column]][1L] != key_value) {
    stop("Register key did not match the requested record.", call. = FALSE)
  }
  for (name in names(updates)) row[[name]][1L] <- as.character(updates[[name]])
  temp <- tempfile(fileext = ".csv")
  utils::write.csv(row, temp, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  rendered <- readBin(temp, what = "raw", n = file.info(temp)$size)
  unlink(temp)
  rendered_text <- rawToChar(rendered)
  rendered_newline <- regexpr("\n", rendered_text, fixed = TRUE)[[1L]]
  updated_record <- substring(rendered_text, rendered_newline + 1L)
  updated_record <- sub("[\r\n]+$", "", updated_record)
  record_end <- start + newline - 1L
  paste0(substring(text, 1L, start - 1L), updated_record,
    substring(text, record_end))
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidate_text <- prepare_record_update(candidate_path, "candidate_id", candidate_id,
  list(
    matched_stock_id = stock_id,
    match_status = "matched",
    import_status = "partial",
    review_date = "2026-11-02",
    catch_age_evidence = "The 2026/022 summary confirms catch totals and number proportions-at-age for seine and trawl fleets, 1985-2022. Numerical source series were not recovered because the detailed Research Document PDF is currently unavailable.",
    survey_age_evidence = "The summary confirms RV age proportions and an age-aggregated biomass index, 1985-2025. Numerical arrays and the expansion needed for an age-specific index were not recovered.",
    weights_evidence = "RV weight-at-age is identified for 1985-2025; numerical age-specific values were not recovered.",
    maturity_evidence = "RV maturity-at-age is identified for 1985-2025; numerical values and sex treatment were not recovered.",
    mortality_evidence = "The summary describes time-varying, age-dependent M, with groups 4-7, 8-9 and 10+; annual values and process details were not recovered.",
    output_evidence = "The 2025 summary reports age-5+ biomass of 8,269 t (95% CI 5,666-10,872) and F ages 4-10+ = 0 since 2023. Numerical historical N, recruitment, SSB and mortality trajectories were not accessible.",
    decision_reason = "Partial source import completed from the official summary. The detailed report PDF link currently redirects to an archived notice; numerical model inputs and historical trajectories remain unavailable, so is ready.",
    notes = "Current DFO 4T unit; imported the official 2025 age-5+ biomass estimate and recent F=0 statement only. Detailed numerical inputs and historical outputs remain blocked by unavailable Research Document 2026/054 PDF. See discovery/source_reviews/dfo_gulf_yellowtail_flounder_2025.md."
  ))

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(selected_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
selected_row <- match(candidate_id, selected$candidate_id)
if (is.na(selected_row)) stop("Selected-batch candidate row is missing.", call. = FALSE)
selected$curation_status[selected_row] <- "partial_source_import"
selected_tmp <- tempfile(tmpdir = dirname(selected_path), fileext = ".csv")
utils::write.csv(selected, selected_tmp, row.names = FALSE, na = "",
  fileEncoding = "UTF-8")

db <- file.path(root, "database")
existing_assessments <- utils::read.csv(file.path(db, "assessments.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)$assessment_id
existing_stocks <- utils::read.csv(file.path(db, "stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)$stock_id
if (!dry_run && (assessment_id %in% existing_assessments || stock_id %in% existing_stocks)) {
  stop("The yellowtail assessment or stock already exists; do not append it twice.", call. = FALSE)
}

if (dry_run) {
  unlink(selected_tmp)
  cat("Dry run validated one stock, one assessment, 10 assumptions, no numeric input rows, and 4 official summary outputs.\n")
} else {
  candidate_tmp <- tempfile(tmpdir = dirname(candidate_path), fileext = ".csv")
  writeBin(charToRaw(candidate_text), candidate_tmp)
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  if (!file.copy(candidate_tmp, candidate_path, overwrite = TRUE) ||
      !file.copy(selected_tmp, selected_path, overwrite = TRUE)) {
    stop("Could not update the candidate and selected-batch registers.", call. = FALSE)
  }
  unlink(c(candidate_tmp, selected_tmp))
  cat("Imported the partial 2025 NAFO 4T yellowtail flounder source record.\n")
}
