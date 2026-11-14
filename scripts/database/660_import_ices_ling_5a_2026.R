root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_ling_5a_2026")
candidate_id <- "ICES:lin.27.5a"
unit_id <- "ices_ling_5a"
stock_id <- unit_id
assessment_id <- "ices_ling_5a_2026"

report_url <- "https://www.hafogvatn.is/static/extras/images/6_lin_2026_1_techreport_en.html"
graphs_url <- "https://standardgraphs.ices.dk/ViewCharts.aspx?key=22475"
source_data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22475"
annex_url <- "https://doi.org/10.17895/ices.pub.23599644.v1"
report_ref <- "MFRI 2026 Ling technical report, published 2026-06-12"
graph_ref <- "ICES Standard Graphs, 2026 assessment, key 22475"

if (!dir.exists(cache)) stop("The reviewed Icelandic ling source cache is missing.", call. = FALSE)
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(normalizePath(path)), "SHA256"),
    stdout = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

manifest <- utils::read.csv(file.path(cache, "sources.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
expected_hashes <- c(
  MFRI_ling_2026_technical_report.html = "7a5f1abcc0688204dc71d6dd13673363f4a90e2052aacf56d944ac235280e6c4",
  ICES_stock_graphs_2026_key_22475.html = "cbe4e38b7ff5e300aa7bc3e07ecaf704e58ee16a7472c0f84d79699bba358400",
  ICES_source_data_2026_key_22475.html = "50f190d685bb120e44fbc9d905c2641cfc41732bec661dc59f2cf5afbc155011",
  ICES_ling_5a_Stock_Annex_2023.pdf = "34f7909cc1c2ea9b89ae9a2ae9a23f7d905fa99cfdcb6b2647fd2b049d5a34e4",
  ICES_ling_5a_Stock_Annex_2023_metadata.json = "41884c232459adca22ff26241d0abfa19831eed9f5fc615917d4100cccf84f31"
)
if (nrow(manifest) != length(expected_hashes) ||
    anyDuplicated(manifest$file) || !setequal(manifest$file, names(expected_hashes))) {
  stop("The cached Icelandic ling source manifest is incomplete.", call. = FALSE)
}
for (file in names(expected_hashes)) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[i] != "2026-10-30" ||
      as.numeric(manifest$bytes[i]) != file.info(path)$size ||
      tolower(manifest$sha256[i]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]]) {
    stop("Cached Icelandic ling source differs from its manifest: ", file, call. = FALSE)
  }
}

parse_cells <- function(row) {
  cells <- regmatches(row, gregexpr(
    "(?is)<t[dh]\\b[^>]*>.*?</t[dh]>", row, perl = TRUE
  ))[[1L]]
  trimws(gsub("[[:space:]]+", " ", gsub("<[^>]*>", " ", cells, perl = TRUE)))
}
parse_number <- function(x) {
  x <- gsub("&nbsp;|&#160;", "", x, ignore.case = TRUE)
  x <- gsub("[[:space:],]", "", x)
  x[x %in% c("", "-", "—", "–", "NA")] <- NA_character_
  suppressWarnings(as.numeric(x))
}
source_html <- paste(readLines(
  file.path(cache, "ICES_source_data_2026_key_22475.html"), warn = FALSE
), collapse = "\n")
html_rows <- regmatches(source_html, gregexpr(
  "(?is)<tr\\b[^>]*>.*?</tr>", source_html, perl = TRUE
))[[1L]]
cells <- lapply(html_rows, parse_cells)
header <- c(
  "Year", "Low Recruitment", "Recruitment", "High Recruitment",
  "Low TBiomass", "TBiomass", "High TBiomass", "Low SSB", "SSB",
  "High SSB", "Landings", "Catches", "Discards", "Low F", "F", "High F"
)
header_row <- which(vapply(cells, function(x) identical(x, header), logical(1L)))
if (length(header_row) != 1L) stop("Could not isolate the ICES source-data table.", call. = FALSE)

parsed_rows <- lapply(cells, function(x) {
  if (length(x) != length(header) || !grepl("^[0-9]{4}$", x[1L])) return(NULL)
  vapply(x, parse_number, numeric(1L))
})
parsed_rows <- Filter(Negate(is.null), parsed_rows)
source_table <- as.data.frame(do.call(rbind, parsed_rows))
names(source_table) <- c(
  "year", "recruitment_lwr", "recruitment", "recruitment_upr",
  "biomass_lwr", "total_biomass", "biomass_upr", "ssb_lwr", "ssb",
  "ssb_upr", "landings", "catches", "discards", "fbar_lwr", "fbar", "fbar_upr"
)
source_table$year <- as.integer(source_table$year)
if (!identical(source_table$year, 1979:2026) ||
    anyDuplicated(source_table$year) ||
    any(!is.finite(source_table$recruitment)) ||
    any(!is.finite(source_table$ssb)) ||
    any(!is.finite(source_table$total_biomass)) ||
    !all(is.na(source_table$fbar[source_table$year == 2026L])) ||
    any(!is.finite(source_table$catches[source_table$year <= 2025L])) ||
    any(source_table$catches[source_table$year == 2025L] != 9791)) {
  stop("ICES source data have unexpected years, missing values, or totals.", call. = FALSE)
}
historical <- source_table[source_table$year <= 2025L, , drop = FALSE]
if (!identical(historical$year, 1979:2025) ||
    any(!is.finite(historical$landings)) ||
    any(!is.finite(historical$discards)) ||
    historical$landings[historical$year == 2025L] != 9791 ||
    historical$discards[historical$year == 2025L] != 0) {
  stop("The historical catch, landings, or discard series are incomplete.", call. = FALSE)
}

input_rows <- function(measure, values, years, notes, basis = "biomass",
                       type = "catch", unit = "tonnes", source_type = "official_machine_readable",
                       source_reference = graph_ref, age = NA_integer_) {
  pacific_database_row(
    "inputs", n = length(values),
    assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = "", survey = "", sex = "",
    region = "Iceland grounds", season = "",
    year = as.integer(years), year_basis = ifelse(is.na(years), "", "calendar_year"),
    age = rep_len(age, length(values)), value = as.numeric(values), unit = unit,
    sampling_time = NA_real_, source_type = source_type,
    source_reference = source_reference,
    transformation = "Transcribed as published; no rescaling or imputation.",
    notes = notes
  )
}

inputs <- do.call(rbind, list(
  input_rows(
    "catch_biomass", historical$catches, historical$year,
    "Aggregate catch from the ICES source-data table; tonnes. Figure-based catch-at-age is reported separately and has not yet been digitized."
  ),
  input_rows(
    "landings_biomass", historical$landings, historical$year,
    "Aggregate landings from the ICES source-data table; tonnes."
  ),
  input_rows(
    "discard_biomass", historical$discards, historical$year,
    "Discard biomass from the ICES source-data table; tonnes. Published zeros are retained as reported."
  ),
  input_rows(
    "natural_mortality_at_age", rep(0.15, 11L), rep(NA_integer_, 11L),
    "Fixed natural mortality for modeled ages 2-12+, applied in all years.",
    basis = "per_year", type = "M", unit = "per year",
    source_type = "official_document", source_reference = annex_url, age = 2:12
  )
))

output_rows <- function(type, measure, value, years, unit,
                        lower = NA_real_, upper = NA_real_,
                        age = NA_integer_, age_group = "", scenario = "",
                        notes = "") {
  keep <- is.finite(value)
  pacific_database_row(
    "outputs", n = sum(keep),
    assessment_id = assessment_id,
    type = type, measure = measure,
    fleet = "", survey = "", sex = "",
    region = "Iceland grounds", season = "",
    year = as.integer(years[keep]), age = age, age_group = age_group,
    value = as.numeric(value[keep]), se = NA_real_,
    lwr = as.numeric(lower[keep]), upr = as.numeric(upper[keep]),
    unit = unit, source_type = "official_machine_readable",
    source_reference = graph_ref,
    notes = notes,
    scenario = rep_len(scenario, length(value))[keep]
  )
}
scenario <- ifelse(source_table$year == 2026L, "2026 advice projection", "")
outputs <- do.call(rbind, list(
  output_rows(
    "recruitment", "recruitment_at_age", source_table$recruitment, source_table$year,
    "thousand fish", source_table$recruitment_lwr, source_table$recruitment_upr,
    age = 2L, scenario = scenario,
    notes = "Recruitment at age 2. Low and high bounds correspond to the published 2.5% and 97.5% limits."
  ),
  output_rows(
    "biomass", "SSB", source_table$ssb, source_table$year,
    "tonnes", source_table$ssb_lwr, source_table$ssb_upr, scenario = scenario,
    notes = "Spawning-stock biomass. Low and high bounds correspond to the published 2.5% and 97.5% limits."
  ),
  output_rows(
    "biomass", "total_biomass", source_table$total_biomass, source_table$year,
    "tonnes", source_table$biomass_lwr, source_table$biomass_upr, scenario = scenario,
    notes = "Total stock biomass. Low and high bounds correspond to the published 2.5% and 97.5% limits."
  ),
  output_rows(
    "mortality", "Fbar", source_table$fbar, source_table$year,
    "per year", source_table$fbar_lwr, source_table$fbar_upr,
    age_group = "8-11",
    notes = "Fishing mortality averaged over ages 8-11. The source table provides 2.5% and 97.5% limits."
  )
))
if (nrow(inputs) != 152L || nrow(outputs) != 191L ||
    any(!is.finite(inputs$value)) ||
    any(outputs$lwr > outputs$value | outputs$value > outputs$upr, na.rm = TRUE) ||
    !all(outputs$scenario[outputs$year == 2026L] == "2026 advice projection") ||
    any(outputs$year == 2026L & outputs$measure == "Fbar")) {
  stop("Constructed Icelandic ling rows failed source and coverage checks.", call. = FALSE)
}

assumption_row <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row(
    "assumptions", n = 1L,
    assessment_id = assessment_id, component = component,
    fleet = "", survey = "", sex = "",
    region = "Iceland grounds", season = "",
    setting = setting, value = value,
    source_reference = source_reference, notes = notes
  )
}
assumptions <- do.call(rbind, list(
  assumption_row(
    "assessment", "model_family", "Statistical Age-structured Model (SAM)",
    report_url, "The 2026 MFRI technical report describes the fitted model as SAM."
  ),
  assumption_row(
    "population", "model_age_range", "2-12+",
    annex_url, "Age 12 is the reported plus group."
  ),
  assumption_row(
    "M", "natural_mortality", "Fixed M = 0.15 per year",
    annex_url, "Fixed across modeled ages and years; retained as an input vector in inputs.csv."
  ),
  assumption_row(
    "recruitment", "recruitment_age", "2",
    graphs_url, "ICES source data identify recruitment at age 2."
  ),
  assumption_row(
    "mortality", "Fbar_age_range", "8-11",
    report_url, "The MFRI report describes fishing mortality for ages 8-11."
  ),
  assumption_row(
    "survey", "survey_timing", "Spring: March; autumn: October; gillnet survey: early April",
    report_url, "The report gives survey months but not the within-year sampling fractions used by the assessment."
  ),
  assumption_row(
    "uncertainty", "reported_interval", "2.5th and 97.5th percentiles",
    graphs_url, "Published low and high limits are retained in outputs.csv as lwr and upr."
  )
))

stock <- pacific_database_row(
  "stocks",
  stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "lin.27.5a", scientific_name = "Molva molva",
  common_name = "Ling - Iceland",
  area = "ICES Division 5.a (Iceland grounds)",
  region = "Iceland grounds", ocean = "Northeast Atlantic",
  notes = "Current Icelandic ling unit; distinct from ling in Division 5.b (Faroes grounds)."
)
assessment <- pacific_database_row(
  "assessments",
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L,
  assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "2026 MFRI assessment; software/model version not reported",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = report_url, framework_url = annex_url,
  data_url = paste(graphs_url, source_data_url, sep = "; "),
  model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The latest 2026 production assessment used for advice is represented.",
    "The fitted historical series ends in 2025; selected 2026 values are advice projections.",
    "Aggregate catches and reportable outputs are imported. Age-specific inputs remain partly figure-based,",
    "and age-specific N and F outputs are not available in the reviewed source tables."
  )
)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    candidates$official_stock_id[candidate_row] != "lin.27.5a" ||
    candidates$scientific_name[candidate_row] != "Molva molva" ||
    candidates$inventory_assessment_year[candidate_row] != 2026L) {
  stop("Icelandic ling candidate identity does not match the register.", call. = FALSE)
}
candidate_updated <- candidates[candidate_row, , drop = FALSE]
candidate_updated$import_status <- "partial"
candidate_updated$catch_age_evidence <- paste(
  "Figure 8 reports catch numbers-at-age; values remain figure-based and are not digitized.",
  "Aggregate catch, landings and discards for 1979-2025 are imported from the ICES source-data table."
)
candidate_updated$survey_age_evidence <- paste(
  "The 2026 report presents age-disaggregated survey indices in Figure 15.",
  "The reported values are not tabulated and remain to be digitized; survey scales and exact sampling times are not stated."
)
candidate_updated$weights_evidence <- paste(
  "Figures 10 and 16 present catch and stock weights-at-age.",
  "These values remain figure-based and are not digitized."
)
candidate_updated$maturity_evidence <- paste(
  "Figure 17 presents maturity-at-age used for spawning biomass.",
  "The numeric values remain figure-based and are not digitized."
)
candidate_updated$mortality_evidence <- paste(
  "The 2023 ICES Stock Annex states that natural mortality is fixed at 0.15 per year.",
  "An age 2-12+ vector is imported."
)
candidate_updated$timing_evidence <- paste(
  "The report identifies the spring survey in March, autumn survey in October, and gillnet survey in early April.",
  "The model's fractional-year sampling times are not reported."
)
candidate_updated$output_evidence <- paste(
  "ICES 2026 Standard Graphs/source data provide age-2 recruitment, SSB, total biomass and Fbar ages 8-11",
  "with 2.5th/97.5th-percentile limits. Aggregate outputs are imported; age-specific N/F surfaces are not available."
)
candidate_updated$review_date <- "2026-11-12"
candidate_updated$notes <- paste(
  "Current 2026 production assessment; inputs fitted through 2025 and selected 2026 outputs are projections.",
  "Source cache and SHA-256 manifest are recorded in source_cache/discovery_ices_ling_5a_2026/sources.csv."
)

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
inventory_row <- which(inventory$unit_key == paste0("candidate:", unit_id))
if (length(inventory_row) != 1L ||
    inventory$candidate_ids[inventory_row] != candidate_id ||
    !inventory$import_status[inventory_row] %in% c("not_started", "partial")) {
  stop("Icelandic ling inventory row is missing or has an unexpected status.", call. = FALSE)
}
inventory_updated <- inventory[inventory_row, , drop = FALSE]
inventory_updated$import_status <- "partial"

dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")
stocks_existing <- utils::read.csv(file.path(database, "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
assessments_existing <- utils::read.csv(file.path(database, "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
has_stock <- any(stocks_existing$stock_id == stock_id, na.rm = TRUE)
has_assessment <- any(assessments_existing$assessment_id == assessment_id, na.rm = TRUE)
if (has_stock != has_assessment) {
  stop("Icelandic ling stock and assessment are only partly present.", call. = FALSE)
}
if (!has_stock && !dry_run) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
} else if (has_stock && !dry_run) {
  stop("Icelandic ling import already exists; verify existing rows before rerunning.", call. = FALSE)
}

if (!dry_run) {
  replace_candidate_register_row(
    candidate_path, candidate_row, candidate_updated, candidate_id
  )
  replace_csv_register_row(
    inventory_path, inventory_row, inventory_updated,
    "unit_key", paste0("candidate:", unit_id)
  )
}
cat("Icelandic ling 2026 source rows: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, ", nrow(outputs), " outputs.\n", sep = "")

