root <- "."
assessment_id <- "australia_east_coast_sea_mullet_2026"
candidate_id <- "QDAF:EAST_COAST_SEA_MULLET_2026"
stock_id <- "australia_east_coast_sea_mullet"
report_path <- file.path(root, "source_cache/australia_east_coast_sea_mullet_2024/sea_mullet_assessment_data_2024.pdf")
report_url <- "https://era.dpi.qld.gov.au/id/eprint/16056/1/2026_sea_mullet_stock_assessment.pdf"
expected_hash <- "59069D68DCE3E2F19AD9393210F073A3D12632B9C93ACE0A61B39529EF37AE21"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(report_path) ||
    toupper(unname(tools::sha256sum(report_path))) != expected_hash) {
  stop("The cached Queensland–NSW assessment PDF is missing or has changed.", call. = FALSE)
}

make_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (nm in intersect(names(values), fields)) {
    value <- values[[nm]]
    row[[nm]] <- if (length(value) == 0L || is.na(value[1L])) "" else
      as.character(value[1L])
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}
make_rows <- function(fields, rows) {
  if (!length(rows)) return(as.data.frame(setNames(replicate(length(fields),
    character(), simplify = FALSE), fields), check.names = FALSE))
  do.call(rbind, rows)
}
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))
append_csv <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  fields <- read_fields(path)
  if (length(setdiff(fields, names(rows)))) {
    stop("Proposed rows do not match ", path, ".", call. = FALSE)
  }
  utils::write.table(rows[fields], path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n")
}
read_rows_csv <- function(records) {
  record_connection <- textConnection(records)
  on.exit(close(record_connection))
  utils::read.csv(record_connection, stringsAsFactors = FALSE,
    colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
}
read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  lines <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    lines <- c(lines, chunk[startsWith(chunk, prefix)])
  }
  read_rows_csv(c(header, lines))
}
normalize_rows <- function(rows) {
  rows[] <- lapply(rows, function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  rows
}
row_keys <- function(rows, fields) {
  do.call(paste, c(lapply(rows[fields], function(x) ifelse(is.na(x), "", x)),
    sep = "\r"))
}
rows_to_add <- function(existing, proposed, key_fields) {
  existing <- normalize_rows(existing)
  proposed <- normalize_rows(proposed)
  old_keys <- row_keys(existing, key_fields)
  new_keys <- row_keys(proposed, key_fields)
  if (anyDuplicated(new_keys)) stop("Proposed rows contain duplicate keys.", call. = FALSE)
  for (i in which(new_keys %in% old_keys)) {
    j <- match(new_keys[i], old_keys)
    if (!identical(unlist(existing[j, names(proposed), drop = FALSE],
        use.names = FALSE), unlist(proposed[i, , drop = FALSE], use.names = FALSE))) {
      stop("An existing source row has a different value.", call. = FALSE)
    }
  }
  proposed[!new_keys %in% old_keys, , drop = FALSE]
}
ensure_append <- function(path, proposed, id_field) {
  existing <- read_csv(path)
  ids <- as.character(existing[[id_field]])
  found <- which(ids == as.character(proposed[[id_field]][1L]))
  if (!length(found)) {
    append_csv(path, proposed)
  } else if (length(found) != 1L ||
      !identical(unlist(normalize_rows(existing[found, names(proposed), drop = FALSE]),
        use.names = FALSE), unlist(normalize_rows(proposed), use.names = FALSE))) {
    stop("Existing ", id_field, " does not match the reviewed record.", call. = FALSE)
  }
}

manifest <- read.csv("provenance/australia_east_coast_sea_mullet_2026_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
if (nrow(manifest) != 1L || manifest$sha256 != expected_hash ||
    manifest$source_url != report_url || manifest$retrieved_on != "2026-11-08") {
  stop("The provenance record does not match the reviewed assessment PDF.", call. = FALSE)
}

candidate_path <- "discovery/candidates.csv"
candidate_rows <- read_csv(candidate_path)
candidate_index <- which(candidate_rows$candidate_id == candidate_id)
if (length(candidate_index) != 1L) {
  stop("Expected exactly one sea mullet candidate.", call. = FALSE)
}
candidate <- candidate_rows[candidate_index, , drop = FALSE]
if (candidate$scientific_name != "Mugil cephalus" ||
    candidate$assessment_area != "Queensland and New South Wales east coast waters" ||
    !candidate$screening_status == "screened" ||
    !candidate$eligibility == "unresolved" ||
    !candidate$import_status %in% c("not_started", "partial")) {
  stop("The candidate register no longer matches the reviewed sea mullet unit.", call. = FALSE)
}

stock_fields <- read_fields("database/stocks.csv")
assessment_fields <- read_fields("database/assessments.csv")
assumption_fields <- read_fields("database/assumptions.csv")
input_fields <- read_fields("database/inputs.csv")
output_fields <- read_fields("database/outputs.csv")

stock_row <- make_row(stock_fields, list(
  stock_id = stock_id, charbonneau_id = "",
  authority = "Fisheries Queensland / NSW DPIRD",
  authority_stock_id = "Australian east coast sea mullet",
  scientific_name = "Mugil cephalus",
  common_name = "Sea mullet",
  area = "Queensland and New South Wales east coast waters",
  region = "Eastern Australia",
  ocean = "Southwest Pacific",
  notes = "Shared Queensland–New South Wales biological stock assessed as one unit."
))
assessment_row <- make_row(assessment_fields, list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2024L,
  estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.24.2",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "",
  assessment_url = "https://era.dpi.qld.gov.au/id/eprint/16056/",
  framework_url = "", data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Fourth eastern Australian sea mullet assessment; data through December 2024 and status estimated at the beginning of 2025. The report provides only an aggregate annual catch summary, not the fleet-specific input series or numeric composition vectors."
))

catch_row <- make_row(input_fields, list(
  assessment_id = assessment_id, type = "catch", measure = "catch_biomass",
  basis = "biomass", fleet = "All four fleets (reported aggregate)",
  year = 2024L, year_basis = "calendar_year", value = 3021,
  unit = "tonnes", source_type = "official_document",
  source_reference = "Lovett et al. 2026, Section 3.1, p. 16",
  notes = "The report states that total catch declined to 3,021 tonnes in 2024. This is a published aggregate across the four NSW and Queensland fleets, not the numerical fleet-specific catch series used by the model."
))
input_rows <- catch_row

assumption_specs <- list(
  list("assessment", "assessment_number", "Fourth assessment", "Introduction",
    "The 2026 report describes this as the fourth assessment of the eastern Australian sea mullet stock."),
  list("population", "model_software", "Stock Synthesis 3.30.24.2", "Section 2.3",
    "Version reported for the production assessment."),
  list("population", "model_time_step", "Annual", "Section 2.3",
    "The model uses annual time steps."),
  list("population", "sex_structure", "Two-sex", "Section 2.3",
    "The population model distinguishes female and male fish."),
  list("population", "fishery_fleets", "4: NSW estuarine, NSW ocean beach, Queensland estuarine, Queensland ocean beach", "Section 3.1 and Figure 3.2",
    "The model fits four fleet components; the published 2024 catch figure is their aggregate."),
  list("population", "scenario_ensemble_size", "24", "Sections 2.6.3 and 3.3",
    "The assessment combines results across 24 scenarios."),
  list("natural_mortality", "scenario_values", "0.28, 0.33, and 0.37 per year", "Appendix A, natural mortality",
    "Natural mortality is common across sexes, ages, and years within each scenario; 0.33 is the central value."),
  list("biology", "stock_recruitment_steepness", "0.75", "Appendix A, stock-recruitment relationship",
    "Steepness is fixed at 0.75."),
  list("index", "standardized_catch_rate_indices", "4 annual fleet-specific series", "Sections 2.4 and 3.3",
    "The report describes four standardized catch-rate indices but does not tabulate their numerical series."),
  list("composition", "age_composition_data", "Sex-specific compositions shown in figures; numerical vectors not tabulated", "Figure 3.5 and Appendix H",
    "The report shows age-composition fits, with ages 1–9 illustrated, but does not publish the numeric likelihood vectors."),
  list("data_availability", "native_model_files", "Not located in the public report record", "Official report record",
    "No native Stock Synthesis input/output bundle was included with the cached report.")
)
assumption_rows <- make_rows(assumption_fields, lapply(assumption_specs, function(x) {
  make_row(assumption_fields, list(
    assessment_id = assessment_id, component = x[[1L]], setting = x[[2L]],
    value = x[[3L]], source_reference = paste("Lovett et al. 2026,", x[[4L]]),
    notes = x[[5L]]
  ))
}))

output_row <- function(type, measure, value, unit, source_reference, notes,
    year = "", scenario = "", se = "", lwr = "", upr = "") {
  make_row(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    year = year, scenario = scenario, value = value, se = se,
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes
  ))
}
status_ref <- "Lovett et al. 2026, Table 1, printed p. ii"
ratio_notes <- "Source-reported percent of unfished spawning biomass; percentage scale retained. This is a relative status output, not absolute spawning biomass."
output_rows <- list(
  output_row("biomass", "SSB_ratio_to_B0", 39, "percent",
    status_ref, paste(ratio_notes, "Median with a 95% credible interval."),
    year = 2025L, lwr = 25, upr = 76),
  output_row("probability", "probability_below_20_percent_B0", 0.001, "probability",
    status_ref, "Source reports 0.1%; stored as a probability from 0 to 1.",
    year = 2025L),
  output_row("probability", "probability_between_20_and_40_percent_B0", 0.539, "probability",
    status_ref, "Source reports 53.9%; stored as a probability from 0 to 1.",
    year = 2025L),
  output_row("probability", "probability_between_40_and_60_percent_B0", 0.351, "probability",
    status_ref, "Source reports 35.1%; stored as a probability from 0 to 1.",
    year = 2025L),
  output_row("probability", "probability_above_60_percent_B0", 0.109, "probability",
    status_ref, "Source reports 10.9%; stored as a probability from 0 to 1.",
    year = 2025L),
  output_row("mortality", "harvest_rate", 0.15, "proportion per year",
    status_ref, "Median annual proportion of exploited biomass removed by fishing over 2020–2024; not an instantaneous F estimate. Source reports 15% with a 95% credible interval of 10–21%.",
    scenario = "2020-2024 annual harvest-rate summary", lwr = 0.10, upr = 0.21)
)
output_rows <- make_rows(output_fields, output_rows)

stocks <- read_csv("database/stocks.csv")
assessments <- read_csv("database/assessments.csv")
if (sum(stocks$stock_id == stock_id) > 1L ||
    sum(assessments$assessment_id == assessment_id) > 1L ||
    (!stock_id %in% stocks$stock_id &&
      any(stocks$scientific_name == "Mugil cephalus", na.rm = TRUE))) {
  stop("Conflicting sea mullet stock or assessment rows already exist.", call. = FALSE)
}
assessment_exists <- assessment_id %in% assessments$assessment_id
existing_assumptions <- if (assessment_exists) {
  read_assessment_rows("database/assumptions.csv", assessment_id)
} else utils::read.csv("database/assumptions.csv", nrows = 0L,
  stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
existing_inputs <- if (assessment_exists) {
  read_assessment_rows("database/inputs.csv", assessment_id)
} else utils::read.csv("database/inputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
existing_outputs <- if (assessment_exists) {
  read_assessment_rows("database/outputs.csv", assessment_id)
} else utils::read.csv("database/outputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)

assumption_key <- c("assessment_id", "component", "fleet", "survey", "sex",
  "region", "season", "setting")
input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey",
  "sex", "region", "season", "year", "year_basis", "age", "observation_id", "partition")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
  "region", "season", "year", "age", "age_group", "scenario")
assumptions_to_add <- rows_to_add(existing_assumptions, assumption_rows, assumption_key)
inputs_to_add <- rows_to_add(existing_inputs, input_rows, input_key)
outputs_to_add <- rows_to_add(existing_outputs, output_rows, output_key)

candidate$matched_stock_id <- stock_id
candidate$match_status <- "matched"
candidate$import_status <- "partial"
candidate$catch_age_evidence <- "One aggregate 2024 catch biomass total (3,021 tonnes) is imported. The report does not tabulate fleet-specific annual catch inputs or commercial catch-at-age."
candidate$survey_age_evidence <- "The model fits four fleet-specific standardized annual catch-rate indices and age compositions, but the report does not tabulate numeric CPUE or composition vectors; no age-specific abundance survey index is reported."
candidate$weights_evidence <- "Growth and length-weight relationships are described, but complete numerical age-specific weight surfaces are not provided in the report."
candidate$maturity_evidence <- "Maturity relationships are described, but a complete numerical age-specific maturity schedule is not tabulated in the report."
candidate$mortality_evidence <- "Natural mortality is common across sexes, ages, and years; the 24-scenario ensemble uses 0.28, 0.33, and 0.37 per year."
candidate$timing_evidence <- "The model time step is annual; fractional-year timing for its catch-rate indices is not reported."
candidate$output_evidence <- "Imported beginning-of-2025 SSB/B0 median and 95% credible interval, status probabilities, and the 2020–2024 harvest-rate median and interval. No annual numerical N-at-age or F-at-age series is tabulated."
candidate$decision_reason <- "Partially imported the latest official assessment for the current shared eastern Australian stock. Age-input eligibility remains unresolved because the report does not publish numerical fleet catch, CPUE, composition, or complete age-specific biological inputs."
candidate$notes <- "One shared Queensland–NSW biological stock; do not count the state components as separate units. The canonical record preserves only source-reported aggregate catch and status summaries."

cat("Eastern Australian sea mullet partial source import\n")
cat("  inputs: ", nrow(inputs_to_add), " new of ", nrow(input_rows), "\n", sep = "")
cat("  assumptions: ", nrow(assumptions_to_add), " new of ", nrow(assumption_rows), "\n", sep = "")
cat("  outputs: ", nrow(outputs_to_add), " new of ", nrow(output_rows), "\n", sep = "")
cat("  age-input eligibility remains unresolved; no series have been digitized or reconstructed.\n")
if (!write_mode) {
  cat("Dry run only. Add --write to append the reviewed source values.\n")
} else {
  source(file.path(root, "scripts/database/candidate_register_io.R"), local = TRUE)
  ensure_append("database/stocks.csv", stock_row, "stock_id")
  ensure_append("database/assessments.csv", assessment_row, "assessment_id")
  append_csv("database/assumptions.csv", assumptions_to_add)
  append_csv("database/inputs.csv", inputs_to_add)
  append_csv("database/outputs.csv", outputs_to_add)
  replace_candidate_register_row(candidate_path, candidate_index, candidate, candidate_id)
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts/database/196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Appended the partial source record and updated the candidate crosswalk.\n")
}
