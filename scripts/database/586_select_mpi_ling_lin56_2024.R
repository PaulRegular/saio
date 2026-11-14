root <- "."
candidate_id <- "MPI:LIN56+LIN6B"
candidate_unit_id <- "mpi_ling_lin56_lin6b"
stock_id <- "mpi_ling_lin56_lin6b"
register_path <- file.path(root, "discovery", "candidates.csv")
selection_path <- file.path(root, "discovery", "selected_batch_06_2026.csv")

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
if (candidate_id %in% register$candidate_id ||
    candidate_unit_id %in% register$candidate_unit_id) {
  stop("The Sub-Antarctic ling unit is already represented; review before adding.", call. = FALSE)
}
stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
if (stock_id %in% stocks$stock_id ||
    any(stocks$authority == "Fisheries New Zealand" &
      grepl("LIN 5&6", stocks$authority_stock_id, fixed = TRUE))) {
  stop("A canonical Sub-Antarctic ling stock record already exists; review identity.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "LIN 5&6 and LIN 6B",
  scientific_name = "Genypterus blacodes",
  stock_name = "Sub-Antarctic ling",
  assessment_area = "LIN 5&6 and LIN 6B; Sub-Antarctic biological stock",
  inventory_assessment_year = "2024",
  inventory_url = "https://fs.fish.govt.nz/Doc/26063/ling-fisheries-assessment-plenary-may-2025-volume-2.pdf.ashx",
  retrieved_on = "2026-11-06",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2024 production model used catch biomass by three fisheries, reported in",
    "tonnes for 1972-2023 in FAR 2024/82 Table E.1. It also used fishery age",
    "compositions, but the reviewed sources give their years and age ranges rather",
    "than numerical fitted composition vectors. No catch numbers-at-age were inferred."
  ),
  survey_age_evidence = paste(
    "The base model used summer and autumn Tangaroa biomass indices and age",
    "compositions. FAR 2024/84 Table 2 lists observation years; the numerical",
    "index values, CVs, and composition vectors were not tabulated in the reviewed",
    "reports. The longline CPUE series was a sensitivity, not a base-case input."
  ),
  weights_evidence = paste(
    "FAR 2024/84 Table 3 reports sex-specific von Bertalanffy growth and length-weight",
    "parameters. No direct weight-at-age matrix was located; no matrix has been derived."
  ),
  maturity_evidence = paste(
    "FAR 2024/84 Table 4 reports male and female maturity at ages 3-13. Values",
    "outside that tabulated range are not added without a source."
  ),
  mortality_evidence = "The base model fixes natural mortality at 0.18 per year for both sexes, constant at age.",
  timing_evidence = paste(
    "The model year is calendar year, with January-August and September-December",
    "time steps. FAR 2024/84 Table 1 documents observation timing by step."
  ),
  output_evidence = paste(
    "FAR 2024/84 Tables 8-11 report biomass/status summaries, sensitivities, and",
    "projections. Annual numeric N-at-age, F-at-age, M-at-age, and recruitment",
    "trajectories are shown as figures rather than tables."
  ),
  detailed_source_url = paste(
    "https://fs.fish.govt.nz/Doc/25826/FAR-2024-82-Descriptive-analysis-of-ling-in-the-Sub-Antarctic-up-to-2023-and-inputs-for-the-2024-stock-assessment.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/25827/FAR-2024-83-Stock-hypothesis-for-ling-in-the-Sub-Antarctic.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/25828/FAR-2024-84-2024-stock-assessment-of-ling-in-the-Sub-Antarctic.pdf.ashx;",
    "https://fs.fish.govt.nz/Doc/26063/ling-fisheries-assessment-plenary-may-2025-volume-2.pdf.ashx"
  ),
  review_date = "2026-11-06",
  decision_reason = paste(
    "Selected for source curation: the 2025 Plenary identifies the 2024 age-structured",
    "Casal2 assessment as the latest assessment used for advice. The official input",
    "and assessment reports provide annual catch biomass, documented age-series",
    "coverage, biological assumptions, and comparable posterior biomass outputs.",
    "Numeric age-composition and survey-index series remain source gaps."
  ),
  notes = paste(
    "The 2024 assessment includes LIN 6B as a separate fishery with shared biological",
    "parameters and recruitment, treating it as part of the Sub-Antarctic population.",
    "Statistical Area 032 was moved to LIN 7WC. Source coverage does not establish",
    "composition and survey-index values remain unavailable."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
candidate[] <- lapply(candidate, as.character)
if (!identical(names(candidate), names(register))) {
  stop("Candidate row does not match the register schema.", call. = FALSE)
}
candidate_line <- capture.output(write.table(candidate, file = "", sep = ",",
  row.names = FALSE, col.names = FALSE, quote = TRUE, na = "",
  qmethod = "double", eol = ""))
bytes <- readBin(register_path, "raw", n = file.info(register_path)$size)
if (length(bytes) && tail(bytes, 1L) != as.raw(10L)) {
  cat("\n", file = register_path, append = TRUE, sep = "")
}
cat(candidate_line, "\n", file = register_path, append = TRUE, sep = "")

selection <- data.frame(
  priority = 1L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "LIN 5&6 and LIN 6B",
  scientific_name = "Genypterus blacodes",
  stock_name = "Sub-Antarctic ling",
  assessment_area = "LIN 5&6 and LIN 6B; Sub-Antarctic biological stock",
  inventory_assessment_year = 2024L,
  detailed_source_url = "https://fs.fish.govt.nz/Doc/25828/FAR-2024-84-2024-stock-assessment-of-ling-in-the-Sub-Antarctic.pdf.ashx",
  review_date = "2026-11-06",
  selection_basis = paste(
    "The latest assessment used for advice is the 2024 age-structured Casal2 run.",
    "Official input and assessment reports expose verified catch histories, biology,",
    "age-series coverage, and aggregate posterior results; unavailable likelihood",
    "vectors will remain explicit source gaps."
  ),
  curation_status = "selected",
  stringsAsFactors = FALSE
)
write.csv(selection, selection_path, row.names = FALSE, na = "")

selected_candidate_id <- candidate_id
source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
  local = new.env(parent = globalenv()))
source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
  local = new.env(parent = globalenv()))
updated <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stopifnot(sum(updated$candidate_id == selected_candidate_id) == 1L,
  sum(updated$candidate_unit_id == candidate_unit_id) == 1L,
  updated$match_status[updated$candidate_id == selected_candidate_id] == "new",
  updated$eligibility[updated$candidate_id == selected_candidate_id] == "unresolved",
  file.exists(selection_path))
cat("Selected the 2024 Sub-Antarctic ling assessment for partial source curation.")
