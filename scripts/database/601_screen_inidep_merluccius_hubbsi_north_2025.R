root <- "."
candidate_id <- "INIDEP:MERLUCCIUS_HUBBSI_NORTH41"
candidate_unit_id <- "argentina_merluccius_hubbsi_north_41s"
stock_id <- candidate_unit_id
assessment_id <- paste0(stock_id, "_2025")
report_url <- "https://marabierto.inidep.edu.ar/handle/inidep/5103"
act_url <- "https://cfp.gob.ar/actas/ACTA%20CFP%2034-2025.pdf"
resolution_url <- paste0(
  "https://cfp.gob.ar/resoluciones/Resolucion%2016%20%2811-12-25%29%20",
  "CMP%20merluza%20comun%2C%20polaca%2C%20cola%20y%20negra%202026.pdf")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_character_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
rows <- function(columns, values) {
  out <- lapply(columns, function(name) {
    value <- values[[name]]
    if (is.null(value)) return("")
    value <- as.character(value)
    value[is.na(value)] <- ""
    value
  })
  names(out) <- columns
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
append_rows <- function(path, value) {
  utils::write.table(value, path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n")
}

source_files <- file.path(root, c(
  "source_cache/inidep_merluccius_hubbsi_north_2025/report.pdf",
  "source_cache/inidep_merluccius_hubbsi_north_2025/acta_cfp_34_2025.pdf",
  "source_cache/inidep_merluccius_hubbsi_north_2025/resolucion_cfp_16_2025.pdf"))
expected_hashes <- c(
  "1EA0A1FFF0F7CA297692CA573DE4CC773FDCED9F657314DE8C54B7E92490E9A7",
  "330DA13B1BF30FD768C2F0E564443D1193D553FE87DE7ECDB37C033968D0300C",
  "434FBD00B5206C51EEAE05221FE36F32D04F5BC0A4D4C4F43D5CA2438F77DD36")
if (!all(file.exists(source_files)) ||
    !identical(toupper(unname(tools::sha256sum(source_files))), expected_hashes)) {
  stop("The cached INIDEP report or CFP documents differ from the reviewed sources.",
    call. = FALSE)
}

candidates_path <- file.path(root, "discovery/candidates.csv")
units_path <- file.path(root, "discovery/inventory_units.csv")
selection_path <- file.path(root, "discovery/selected_batch_13_2026.csv")
candidates <- read_character_csv(candidates_path)
units <- read_character_csv(units_path)
stocks <- read_csv(file.path(root, "database/stocks.csv"))
assessments <- read_csv(file.path(root, "database/assessments.csv"))
has_value <- function(x, value) any(!is.na(x) & x == value)
if (has_value(candidates$candidate_id, candidate_id) ||
    has_value(candidates$candidate_unit_id, candidate_unit_id) ||
    has_value(stocks$stock_id, stock_id) ||
    has_value(assessments$assessment_id, assessment_id) ||
    has_value(units$candidate_unit_id, candidate_unit_id) ||
    file.exists(selection_path)) {
  stop("The candidate or northern stock is already present; review before proceeding.",
    call. = FALSE)
}

candidate_fields <- fields(candidates_path)
candidate <- rows(candidate_fields, list(
  candidate_id = candidate_id, candidate_unit_id = candidate_unit_id,
  organization = "INIDEP", official_stock_id = "Efectivo norte de 41° S",
  scientific_name = "Merluccius hubbsi", stock_name = "Northern Argentine hake",
  assessment_area = "North of 41°S; ZCPAU and adjacent Argentine waters",
  inventory_assessment_year = 2025L, inventory_url = report_url,
  retrieved_on = "2026-11-07", matched_stock_id = "", match_status = "new",
  screening_status = "screened", eligibility = "eligible", import_status = "not_started",
  catch_age_evidence = paste(
    "INIDEP ITO 43/2025 Table 2 reports estimated catch numbers-at-age for",
    "1986–2024, ages 1–6 and 7+, in thousands of fish. The methods describe",
    "age-composition data from the Argentine trawl fleet. Table 1 reports",
    "country and Argentine-area catch biomass in tonnes."),
  survey_age_evidence = paste(
    "Table 5 reports global-survey numbers-at-age for selected years 1996–2016,",
    "ages 1–6 and 7+, in thousands of fish. Tables 8–9 provide age-2 and",
    "age-1 juvenile abundance indices."),
  weights_evidence = paste(
    "Table 3 reports commercial catch weight-at-age for 1986–2024; Table 6",
    "reports population weight-at-age from the 1997 survey, recalculated to",
    "1 January."),
  maturity_evidence = "Table 7 reports mature proportions for ages 1–6 and 7+.",
  mortality_evidence = "Table 7 fixes natural mortality at 0.3 per year for all ages and years.",
  timing_evidence = paste(
    "The report specifies global survey in September (0.75), Aldebarán autumn",
    "in May (0.417), spring in September (0.75), and December age-1 observations",
    "assigned to age 2 at the start of the following year. CPUE timing is not stated."),
  output_evidence = paste(
    "Table 11 reports total biomass, spawning biomass and recruitment for",
    "1986–2024 under E1–E3. Table 12 gives E2 2026 catch advice; CFP Resolution",
    "16/2025 sets the 2026 maximum catch. Annual N-at-age, F-at-age and state",
    "uncertainty are not tabulated."),
  detailed_source_url = paste(report_url, act_url, resolution_url, sep = "; "),
  review_date = "2026-11-07",
  decision_reason = paste(
    "The latest detailed report located for the current northern effective is",
    "INIDEP ITO 43/2025, assessing through 2024 and providing 2026 advice.",
    "It publishes source catch, age composition, survey, biological and",
    "aggregate state-output tables."),
  notes = paste(
    "Targeted report search, not a comprehensive national inventory. The",
    "biological effective includes the ZCPAU and adjacent Argentine waters;",
    "the southern effective south of 41°S remains a separate stock record.")))

unit_fields <- fields(units_path)
unit <- rows(unit_fields, list(
  unit_key = paste0("candidate:", candidate_unit_id), matched_stock_id = "",
  candidate_unit_id = candidate_unit_id, match_status = "new", eligibility = "eligible",
  screening_status = "screened", import_status = "not_started", organizations = "INIDEP",
  source_regions = "North of 41°S; ZCPAU and adjacent Argentine waters",
  candidate_ids = candidate_id, inventory_entries = 1L))
selection <- rows(c("priority", "candidate_id", "candidate_unit_id", "organization",
  "official_stock_id", "scientific_name", "stock_name", "assessment_area",
  "inventory_assessment_year", "detailed_source_url", "review_date",
  "selection_basis", "curation_status"), list(
    priority = 1L, candidate_id = candidate_id, candidate_unit_id = candidate_unit_id,
    organization = "INIDEP", official_stock_id = "Efectivo norte de 41° S",
    scientific_name = "Merluccius hubbsi", stock_name = "Northern Argentine hake",
    assessment_area = "North of 41°S; ZCPAU and adjacent Argentine waters",
    inventory_assessment_year = 2025L,
    detailed_source_url = paste(report_url, act_url, resolution_url, sep = "; "),
    review_date = "2026-11-07",
    selection_basis = paste(
      "Select for source curation: current INIDEP production report provides",
      "catch-at-age, survey age data, weights, maturity, fixed M and annual",
      "biomass and recruitment outputs; official CFP records confirm 2026 advice."),
    curation_status = "selected_for_source_curation"))

manifest <- data.frame(
  local_file = c(
    "source_cache/inidep_merluccius_hubbsi_north_2025/report.pdf",
    "source_cache/inidep_merluccius_hubbsi_north_2025/acta_cfp_34_2025.pdf",
    "source_cache/inidep_merluccius_hubbsi_north_2025/resolucion_cfp_16_2025.pdf"),
  source_url = c(
    "https://marabiertonew.inidep.edu.ar/server/api/core/bitstreams/998a991e-3565-4b04-93cd-ce143f669346/content",
    act_url, resolution_url),
  record_url = c(report_url, act_url, resolution_url),
  retrieved_on = "2026-11-07", sha256 = expected_hashes,
  bytes = c(1869756L, 388010L, 146194L),
  description = c(
    "INIDEP Official Technical Report 43/2025, current northern Merluccius hubbsi assessment through 2024 with advice for 2026.",
    "Official CFP Act 34/2025 identifies INIDEP Technical Report 43/2025 in the 2026 advice cycle.",
    "Official CFP Resolution 16/2025 sets the northern hake maximum catch at 28,700 t for 2026."),
  stringsAsFactors = FALSE)

cat("Candidate:", candidate_id, "\n")
cat("Current run: 2025; terminal year: 2024; source screen: eligible\n")
if (write_mode) {
  append_rows(candidates_path, candidate)
  append_rows(units_path, unit)
  utils::write.csv(selection, selection_path, row.names = FALSE, na = "")
  utils::write.csv(manifest, file.path(root,
    "provenance/inidep_merluccius_hubbsi_north_2025_sources.csv"),
    row.names = FALSE, na = "")
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  cat("Added the source-led candidate and provenance manifest.\n")
}
