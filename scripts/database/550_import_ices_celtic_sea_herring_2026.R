root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_celtic_sea_herring_2026")
candidate_id <- "ICES:her.27.irls"
stock_id <- "ices_her_27_irls"
assessment_id <- "ices_her_27_irls_2026"
report_url <- "https://doi.org/10.17895/ices.pub.31424315"
report_reference <- "ICES HAWG 2026, section 6 and Tables 6.6.1.1-6.6.1.4"
survey <- "Celtic Sea Pelagic Ecosystem Survey (CSHAS)"

source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify SHA-256 for ", path, call. = FALSE)
  hashes
}

report_path <- file.path(cache, "ices_hawg_2026_full_report.pdf")
tables_path <- file.path(cache, "celtic_herring_assessment_tables.txt")
manifest <- utils::read.csv(file.path(cache, "sources.csv"), stringsAsFactors = FALSE)
expected_report_hash <- "a0c3928fde2693cbbcc176abfb7450e7f426e47898d2020529e1fb563542bb66"
expected_tables_hash <- "8cbe6efe0d82f03f9d4f87edf4d16fbcc48b491017532140803dd8a69a557fc6"
report_row <- manifest[manifest$file == basename(report_path), , drop = FALSE]
if (nrow(report_row) != 1L || tolower(report_row$sha256) != expected_report_hash ||
    report_row$retrieved_on != "2026-10-29" ||
    sha256_file(report_path) != expected_report_hash ||
    sha256_file(tables_path) != expected_tables_hash) {
  stop("The cached Celtic Sea herring report tables differ from the reviewed source.", call. = FALSE)
}

table_text <- readLines(tables_path, warn = FALSE, encoding = "UTF-8")
page_text <- function(page_number) {
  marker <- paste0("===== PDF PAGE ", page_number, " =====")
  start <- match(marker, trimws(table_text))
  if (is.na(start)) stop("Missing extracted HAWG page ", page_number, call. = FALSE)
  page_markers <- grep("^===== PDF PAGE ", trimws(table_text))
  next_page <- page_markers[page_markers > start][1L]
  if (is.na(next_page)) next_page <- length(table_text) + 1L
  table_text[seq.int(start + 1L, next_page - 1L)]
}

pages_text <- function(pages) unlist(lapply(pages, page_text), use.names = FALSE)

section_lines <- function(pages, start_pattern, end_pattern) {
  lines <- pages_text(pages)
  start <- grep(start_pattern, lines, ignore.case = TRUE)[1L]
  end <- grep(end_pattern, lines, ignore.case = TRUE)[1L]
  if (is.na(start) || is.na(end) || end <= start) {
    stop("Could not isolate HAWG table section: ", start_pattern, call. = FALSE)
  }
  lines[seq.int(start + 1L, end - 1L)]
}

parse_annual_rows <- function(lines, years, values_per_year, label,
                              allow_missing_trailing = FALSE) {
  lines <- trimws(lines)
  selected <- lines[grepl("^(19|20)[0-9]{2}[[:space:]]+", lines)]
  parsed <- lapply(selected, function(line) {
    tokens <- strsplit(line, "[[:space:]]+")[[1L]]
    if (allow_missing_trailing && length(tokens) == values_per_year) {
      tokens <- c(tokens, NA_character_)
    }
    if (length(tokens) != values_per_year + 1L) {
      stop(label, " row has ", length(tokens) - 1L, " values; expected ",
        values_per_year, ": ", line, call. = FALSE)
    }
    suppressWarnings(as.numeric(tokens))
  })
  values <- do.call(rbind, parsed)
  if (anyNA(values[, 1L]) || anyDuplicated(values[, 1L]) ||
      !identical(as.integer(values[, 1L]), as.integer(years))) {
    stop(label, " does not contain the expected annual coverage.", call. = FALSE)
  }
  values
}

parse_fixed_age_vector <- function(lines, heading, n_ages = 9L) {
  heading_row <- grep(heading, lines, ignore.case = TRUE)[1L]
  if (is.na(heading_row)) stop("Missing HAWG input heading: ", heading, call. = FALSE)
  candidates <- lines[seq.int(heading_row + 1L, length(lines))]
  candidates <- candidates[grepl("^[[:space:]]*[0-9.]+([[:space:]]+[0-9.]+)+[[:space:]]*$", candidates)]
  for (line in candidates) {
    values <- suppressWarnings(as.numeric(strsplit(trimws(line), "[[:space:]]+")[[1L]]))
    if (length(values) == n_ages && all(is.finite(values))) return(values)
  }
  stop("Could not parse the fixed age vector for ", heading, call. = FALSE)
}

age_names <- as.character(1:9)
catch_matrix <- parse_annual_rows(pages_text(392:394), 1958:2025, 10L,
  "Catch numbers-at-age and total catch")
catch_ages <- catch_matrix[, -c(1L, 11L), drop = FALSE]
catch_totals <- catch_matrix[, c(1L, 11L), drop = FALSE]
rownames(catch_ages) <- rownames(catch_totals) <- as.character(as.integer(catch_matrix[, 1L]))
colnames(catch_ages) <- age_names

catch_weight_lines <- section_lines(387:389,
  "Weight-at-age in the catch inputs", "Weight-at-age in the stock inputs")
stock_weight_lines <- section_lines(389:391,
  "Weight-at-age in the stock inputs", "Fishery[[:space:]]+Selectivity block inputs")
catch_weight_values <- parse_annual_rows(catch_weight_lines, 1958:2025, 9L,
  "Catch weight-at-age", allow_missing_trailing = TRUE)
stock_weight_values <- parse_annual_rows(stock_weight_lines, 1958:2025, 9L,
  "Stock weight-at-age", allow_missing_trailing = TRUE)
make_age_matrix <- function(values) {
  result <- values[, -1L, drop = FALSE]
  rownames(result) <- as.character(as.integer(values[, 1L]))
  colnames(result) <- age_names
  result
}
catch_weights <- make_age_matrix(catch_weight_values)
stock_weights <- make_age_matrix(stock_weight_values)

static_lines <- page_text(386L)
natural_mortality <- parse_fixed_age_vector(static_lines, "Natural mortality inputs")
maturity <- parse_fixed_age_vector(static_lines, "Maturity inputs")
if (!identical(natural_mortality,
    c(0.767, 0.385, 0.356, 0.339, 0.319, 0.314, 0.307, 0.307, 0.307)) ||
    !identical(maturity, c(0.5, rep(1, 8)))) {
  stop("Fixed M or maturity values differ from HAWG Table 6.6.1.1.", call. = FALSE)
}

survey_matrix <- parse_annual_rows(page_text(395L), 2002:2025, 9L,
  "Acoustic survey inputs")
summary_lines <- section_lines(397:399,
  "Table 6.6.1.4.", "Table 6.7.1.1.")
summary_matrix <- parse_annual_rows(summary_lines, 1958:2025, 5L,
  "Assessment stock summary")

if (any(!is.finite(catch_ages)) || any(!is.finite(catch_totals)) ||
    any(!is.finite(catch_weights[, 1:8])) || any(!is.finite(stock_weights[, 1:8])) ||
    any(is.finite(catch_weights["2025", "9"])) || any(is.finite(stock_weights["2025", "9"])) ||
    !all(as.integer(survey_matrix[, 1L]) == 2002:2025) ||
    !all(summary_matrix[, 1L] == 1958:2025)) {
  stop("The extracted HAWG input or output tables contain unexpected gaps.", call. = FALSE)
}

age_long <- function(x) {
  out <- data.frame(
    year = rep(as.integer(rownames(x)), times = ncol(x)),
    age = rep(as.integer(colnames(x)), each = nrow(x)),
    value = as.vector(x)
  )
  out[is.finite(out$value), , drop = FALSE]
}

input_rows <- function(data, type, measure, basis, unit, source_reference,
                       survey_name = "", season = "", sampling_time = NA_real_,
                       transformation = "", notes = "") {
  sample_size <- if ("sample_size" %in% names(data)) data$sample_size else NA_real_
  pacific_database_row(
    "inputs", n = nrow(data), assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = if (type == "catch" || type == "catch_weight") "Combined fishery" else "",
    survey = survey_name, sex = "", region = "Celtic Sea", season = season,
    year = data$year, year_basis = ifelse(is.na(data$year), "", "model_year"),
    age = data$age, value = data$value, unit = unit,
    sampling_time = sampling_time, sample_size = sample_size,
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes
  )
}

catch_age_data <- age_long(catch_ages)
catch_total_data <- data.frame(
  year = as.integer(catch_totals[, 1L]), age = NA_integer_, value = catch_totals[, 2L]
)
catch_weight_data <- age_long(catch_weights)
stock_weight_data <- age_long(stock_weights)
static_age_data <- data.frame(age = 1:9, year = NA_integer_, value = natural_mortality)
maturity_data <- data.frame(age = 1:9, year = NA_integer_, value = maturity)

survey_year <- as.integer(survey_matrix[, 1L])
survey_total <- as.numeric(survey_matrix[, 2L])
survey_cv <- as.numeric(survey_matrix[, 3L])
survey_age_values <- survey_matrix[, 4:9, drop = FALSE]
survey_sample_size <- as.numeric(survey_matrix[, 10L])
survey_available <- survey_total >= 0 & survey_cv >= 0
survey_total_data <- data.frame(
  year = survey_year[survey_available], age = NA_integer_,
  value = survey_total[survey_available],
  sample_size = survey_sample_size[survey_available]
)
survey_age_data <- data.frame(
  year = rep(survey_year, times = 6L),
  age = rep(2:7, each = length(survey_year)),
  value = as.vector(survey_age_values)
)
survey_age_data <- survey_age_data[is.finite(survey_age_data$value) &
  survey_age_data$value >= 0, , drop = FALSE]
survey_age_data <- survey_age_data[
  survey_age_data$year %in% survey_year[survey_available], , drop = FALSE
]
survey_cv_data <- data.frame(
  year = survey_year[survey_available], age = NA_integer_,
  value = survey_cv[survey_available]
)

catch_cv_data <- data.frame(
  year = as.integer(1958:2025), age = NA_integer_, value = rep(0.2, 68L)
)

age_notes <- "Ages are winter rings; age 9 is the reported 9+ group."
input_data <- do.call(rbind, list(
  input_rows(catch_age_data, "catch", "numbers_at_age", "numbers", "thousand fish",
    "ICES HAWG 2026, Table 6.6.1.1, printed pp. 384-386",
    transformation = "Transcribed as printed; no scaling applied.",
    notes = paste(age_notes, "The annual assessment year is 1 April-31 March, labelled by its first year.")),
  input_rows(catch_total_data, "catch", "total_biomass", "biomass", "tonnes",
    "ICES HAWG 2026, Table 6.6.1.1, printed pp. 384-386",
    transformation = "Transcribed as printed; no scaling applied.",
    notes = "Total catch in the ASAP input table. Its 2025 value (987 t) differs from the reported 2025 assessment summary catch (687 t); both source values are retained."),
  input_rows(catch_weight_data, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg per fish",
    "ICES HAWG 2026, Table 6.6.1.1, printed pp. 379-383",
    transformation = "Transcribed as printed; no scaling applied.", notes = age_notes),
  input_rows(stock_weight_data, "weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "ICES HAWG 2026, Table 6.6.1.1, printed pp. 381-383",
    transformation = "Transcribed as printed; no scaling applied.",
    notes = paste(age_notes, "Stock weights are reported for the stock at spawning time; biological samples are from Q4.")),
  input_rows(static_age_data, "M", "natural_mortality_at_age", "per_year", "per year",
    "ICES HAWG 2026, Table 6.6.1.1, printed p. 378",
    transformation = "Stored once because the published M vector is time-invariant.",
    notes = paste(age_notes, "Fixed, not estimated; values follow the HAWG 2015 procedure using a 2011 SMS run.")),
  input_rows(maturity_data, "maturity", "maturity_at_age", "proportion", "proportion",
    "ICES HAWG 2026, Table 6.6.1.1, printed p. 378",
    transformation = "Stored once because the published maturity vector is time-invariant.", notes = age_notes),
  input_rows(survey_total_data, "index", "total_numbers", "numbers", "thousand fish",
    "ICES HAWG 2026, Table 6.6.1.2, printed p. 387", survey_name = survey,
    season = "October", sampling_time = 0.5,
    transformation = "Transcribed as printed; no scaling applied. October is represented at the midpoint of the April-March model year (0.5).",
    notes = "The source sample size is the number of hauls with sufficient herring, not an effective likelihood sample size. The 2024 zero is retained from the table but excluded from tuning because no mature fish were encountered."),
  input_rows(survey_age_data, "index", "numbers_at_age", "numbers", "thousand fish",
    "ICES HAWG 2026, Table 6.6.1.2, printed p. 387", survey_name = survey,
    season = "October", sampling_time = 0.5,
    transformation = "Transcribed as printed; no scaling applied. October is represented at the midpoint of the April-March model year (0.5).",
    notes = paste(age_notes, "The report excludes 2004, 2017, and 2024 from tuning. The 2019 age-2 entry (98,229) is retained exactly as printed, although it exceeds the reported total index of 8,873; no correction is inferred.")),
  input_rows(survey_cv_data, "index", "abundance_index_cv", "relative_scale", "coefficient of variation",
    "ICES HAWG 2026, Tables 6.6.1.2-6.6.1.3, printed pp. 387-389",
    survey_name = survey, season = "October", sampling_time = 0.5,
    transformation = "Transcribed as printed; index CV is 0.5 in survey years; 2024 CV is 0 in the excluded no-mature-fish row.",
    notes = "The index was tuned at ages 2-7; the reported 2024 zero row is not a survey observation."),
  input_rows(catch_cv_data, "catch", "relative_standard_error", "relative_scale", "coefficient of variation",
    "ICES HAWG 2026, Table 6.6.1.3, printed pp. 388-389",
    transformation = "The reported catch-total CV of 0.2 for all years is recorded as relative standard error.",
    notes = "Catch likelihood is on total catch in weight; the report states a CV of 0.2 for every year.")
))

output_rows <- function(measure, value, unit, age_group = "", notes = "") {
  pacific_database_row(
    "outputs", n = length(value), assessment_id = assessment_id,
    type = if (measure %in% c("total_catch")) "catch" else if (measure == "Fbar") "mortality" else if (measure == "recruitment") "recruitment" else "biomass",
    measure = measure, fleet = "", survey = "", sex = "", region = "Celtic Sea",
    season = "", year = as.integer(summary_matrix[, 1L]), age = NA_integer_,
    age_group = age_group, value = as.numeric(value), se = NA_real_, lwr = NA_real_,
    upr = NA_real_, unit = unit, source_type = "official_table",
    source_reference = "ICES HAWG 2026, Table 6.6.1.4, printed pp. 389-391",
    notes = if (nzchar(notes)) notes else "Published point estimate only; the table reports no uncertainty interval."
  )
}
outputs <- do.call(rbind, list(
  output_rows("total_catch", summary_matrix[, 2L], "tonnes",
    notes = "Published point estimate only. The 2025 value (687 t) differs from the Table 6.6.1.1 ASAP input total (987 t); both source values are retained."),
  output_rows("SSB", summary_matrix[, 3L], "tonnes"),
  output_rows("total_biomass", summary_matrix[, 4L], "tonnes"),
  output_rows("Fbar", summary_matrix[, 5L], "per year", age_group = "2-5 winter rings"),
  output_rows("recruitment", summary_matrix[, 6L], "thousand fish", age_group = "1 winter ring",
    notes = "Published point estimate only. Recruitment is at age 1 winter ring; unit is thousand fish, consistent with the ASAP population scale.")
))

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                            survey_name = "") {
  pacific_database_row(
    "assumptions", assessment_id = assessment_id, component = component,
    fleet = if (component == "catch") "Combined fishery" else "",
    survey = survey_name, sex = "", region = "Celtic Sea", season = "",
    setting = setting, value = value, source_reference = source_reference, notes = notes
  )
}

assumptions <- do.call(rbind, list(
  assumption_rows("population", "model_years", "1958-2025", report_reference,
    "The assessment year runs 1 April-31 March and is labelled by the first year in the season."),
  assumption_rows("population", "model_age_range", "1-9+ winter rings", report_reference,
    "Age 9 is the plus group."),
  assumption_rows("population", "plus_group", "9+ winter rings", report_reference),
  assumption_rows("catch", "discard_treatment", "No discards", "ICES HAWG 2026, section 6.6 and pinned TAF data.R",
    "The TAF preparation sets catch equal to landings and uses no discard component."),
  assumption_rows("catch", "catch_at_age_units", "thousand fish", "ICES HAWG 2026, Table 6.6.1.1",
    "The source table does not print the scale; the unit is consistent with its totals and kg-per-fish weights, but is an inferred presentation scale."),
  assumption_rows("catch", "total_catch_cv", "0.2 in all years", "ICES HAWG 2026, Table 6.6.1.3, printed pp. 388-389",
    "The assessment fits total catch in weight; the stated likelihood weight is 1."),
  assumption_rows("catch", "catch_composition_sample_size", "Irish sampling programme; down-weighted to 5 in 2015-2025",
    "ICES HAWG 2026, Table 6.6.1.3, printed pp. 388-389",
    "The report does not give the exact year-specific effective sample sizes. No values are imputed."),
  assumption_rows("survey", "index_series", "Celtic Sea Pelagic Ecosystem Survey (CSHAS)", report_reference,
    "The ASAP input is an acoustic numbers index; the table's total and age-specific rows are overlapping summaries, not independent series.", survey_name = survey),
  assumption_rows("survey", "index_units", "thousand fish", "ICES HAWG 2026, Tables 6.3.1.1 and 6.6.1.2",
    "The ASAP input table values are in thousands; Table 6.3.1.1 presents the full abundance index in millions.", survey_name = survey),
  assumption_rows("survey", "tuning_ages", "2-7 winter rings", "ICES HAWG 2026, Table 6.6.1.3",
    "Survey ages 2-7 are used for tuning; selectivity is fixed at ages 3-5.", survey_name = survey),
  assumption_rows("survey", "survey_cv", "0.5 in observed years", "ICES HAWG 2026, Tables 6.6.1.2-6.6.1.3",
    "The 2024 row is zero because no mature fish were encountered and is excluded from tuning.", survey_name = survey),
  assumption_rows("survey", "sample_size_definition", "Number of hauls with sufficient herring collected per survey",
    "ICES HAWG 2026, Table 6.6.1.3",
    "This is not the effective sample size for the index likelihood; the assessment separately specifies CV 0.5.", survey_name = survey),
  assumption_rows("survey", "survey_exclusions", "2004, 2017, and 2024",
    "ICES HAWG 2026, Tables 6.6.1.2-6.6.1.3",
    "No survey in 2004; insufficient biological data in 2017; no mature fish encountered in 2024.", survey_name = survey),
  assumption_rows("survey", "survey_timing", "October; approximate model-year fraction 0.5",
    "ICES HAWG 2026, Table 6.6.1.3 and section 6.3",
    "The assessment year starts 1 April; October is represented at its midpoint within that model year. Exact annual sampling dates are unavailable.", survey_name = survey),
  assumption_rows("biology", "catch_weight_basis", "Catch weight-at-age from Table 6.6.1.1", report_reference,
    "The table reports kg per fish by assessment year and winter-ring age."),
  assumption_rows("biology", "stock_weight_basis", "Stock weight-at-age at spawning time; Q4 biological samples",
    "ICES HAWG 2026, section 6.4 and Table 6.6.1.1",
    "The stock weight matrix is time-varying by year and age."),
  assumption_rows("biology", "maturity_at_age", "0.5 at age 1; 1 at ages 2-9+",
    "ICES HAWG 2026, Table 6.6.1.1, printed p. 378",
    "Time-invariant input; the source report does not identify it as estimated."),
  assumption_rows("M", "natural_mortality", paste("Fixed M at ages 1-9+:",
    paste(format(natural_mortality, nsmall = 3), collapse = ", ")),
    "ICES HAWG 2026, Table 6.6.1.1, printed p. 378",
    "Time-invariant; carried over from the HAWG 2015 procedure using the 2011 SMS run."),
  assumption_rows("mortality", "Fbar_ages", "2-5 winter rings", "ICES HAWG 2026, Tables 6.6.1.3-6.6.1.4"),
  assumption_rows("index", "selectivity", "Survey ages 2-7: 0.8,1,1,1,1,1; fixed at ages 3-5",
    "ICES HAWG 2026, Tables 6.6.1.1 and 6.6.1.3, printed pp. 386-389",
    "Index selectivity is not linked to fishery selectivity.", survey_name = survey),
  assumption_rows("catch", "selectivity", "Fishery ages 1-9+: 0.3,0.5,1,1,1,1,1,1,1; fixed at age 3",
    "ICES HAWG 2026, Tables 6.6.1.1 and 6.6.1.3, printed pp. 386-389"),
  assumption_rows("recruitment", "stock_recruitment", "Not fitted",
    "ICES HAWG 2026, Table 6.6.1.3, printed pp. 388-389",
    "The reported stock-recruitment phase is -5."),
  assumption_rows("model", "software", "ASAP; 2026 HAWG applied production assessment",
    report_reference,
    "The pinned TAF repository includes data-preparation and reporting scripts but not the bootstrap inputs, ASAP DAT, executable, or fitted numerical output object."),
  assumption_rows("model", "observation_likelihood_weights", "Catch total 1; acoustic index 1",
    "ICES HAWG 2026, Table 6.6.1.3, printed pp. 388-389",
    "Other per-year likelihood weights and exact effective sample sizes could not be independently verified."),
  assumption_rows("assessment_output", "uncertainty", "Not reported in Table 6.6.1.4",
    "ICES HAWG 2026, Table 6.6.1.4, printed pp. 389-391",
    "Annual outputs are retained as point estimates; no uncertainty values are added."),
  assumption_rows("assessment_output", "age_specific_population_outputs", "Unavailable",
    "Pinned ICES-advice TAF snapshot at cf29535caedd3b97d1912a1fd5b37be350e3d916",
    "The output script writes N-at-age and F-at-age, but the generated numerical arrays were not present in the public snapshot."),
  assumption_rows("data_quality", "source_table_conflicts", "2019 acoustic age-2 value; 2025 catch total",
    "ICES HAWG 2026, Tables 6.6.1.1, 6.6.1.2, and 6.6.1.4",
    "The 2019 survey age-2 value 98,229 exceeds its reported total index 8,873. The 2025 ASAP catch input total is 987 t while the assessment summary catch is 687 t. Both values are retained as printed pending the native run data."),
  assumption_rows("stock_identity", "mixing_and_area_uncertainty", "Unquantified mixing with Irish Sea herring; 7.h stock assignment uncertain",
    "ICES HAWG 2026, section 6.1",
    "These are biological boundary uncertainties and do not collapse the distinct ICES assessment units her.27.irls and her.27.nirs.")
))

stock <- pacific_database_row(
  "stocks", stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "her.27.irls", scientific_name = "Clupea harengus",
  common_name = "Herring - Celtic Sea and southwest of Ireland",
  area = "ICES Division 7.a south of 52°30′N and divisions 7.g, 7.h, 7.j, and 7.k",
  region = "Celtic Sea", ocean = "Northeast Atlantic",
  notes = "Distinct ICES unit from Irish Sea herring her.27.nirs. HAWG notes unquantified mixing with Irish Sea herring and uncertainty about whether 7.h belongs to this stock area."
)
assessment <- pacific_database_row(
  "assessments", assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
  assessment_type = "annual_assessment", model_family = "ASAP",
  model_version = "2026 HAWG applied production run; exact build unavailable",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = report_url,
  data_url = report_url, model_url = "",
  repository_url = "https://github.com/ices-advice/2026_her.27.irls/tree/cf29535caedd3b97d1912a1fd5b37be350e3d916/2026_her.27.irls_assessment",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The 2026 HAWG ASAP assessment is the current applied run with terminal year 2025.",
    "Report tables provide age-specific catch and acoustic index inputs, biology, fixed M, and annual catch, SSB, total biomass, Fbar, and recruitment outputs.",
    "The source tables contain a 2019 acoustic age-2/total inconsistency and a 2025 catch-input/output discrepancy; values are preserved as printed.",
    "The public TAF snapshot lacks raw bootstrap/model input files, fitted N/F-at-age arrays, and uncertainty for the published annual outputs."
  )
)

existing_stocks <- utils::read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
existing_assessments <- utils::read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (!stock_id %in% existing_stocks$stock_id && !assessment_id %in% existing_assessments$assessment_id) {
  append_pacific_case(stock, assessment, assumptions, input_data, outputs)
} else {
  if (sum(existing_stocks$stock_id == stock_id, na.rm = TRUE) != 1L ||
      sum(existing_assessments$assessment_id == assessment_id, na.rm = TRUE) != 1L) {
    stop("The Celtic Sea herring stock and assessment are duplicated or only partly imported.", call. = FALSE)
  }
  inputs_existing <- utils::read.csv(file.path(database, "inputs.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  assumptions_existing <- utils::read.csv(file.path(database, "assumptions.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  outputs_existing <- utils::read.csv(file.path(database, "outputs.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (sum(inputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(input_data) ||
      sum(assumptions_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(assumptions) ||
      sum(outputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(outputs)) {
    stop("Existing Celtic Sea herring rows differ from the verified source import.", call. = FALSE)
  }
}

replace_discovery_row <- function(path, row_index, row, key_column, key) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  existing <- utils::read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (nrow(row) != 1L || !key_column %in% names(existing) ||
      !identical(as.character(existing[[key_column]][row_index]), key)) {
    stop("Discovery register row identity does not match ", key, call. = FALSE)
  }
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  record <- row_index + 1L
  first <- bounds$start[record]
  last <- bounds$end[record]
  next_byte <- last + 1L
  has_carriage_return <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_carriage_return <- TRUE
    next_byte <- next_byte + 1L
  }
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement,
      if (has_carriage_return) as.raw(13L) else raw(0L), as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE), error = function(e) NULL)
  if (is.null(updated) || nrow(updated) != nrow(existing) ||
      sum(updated[[key_column]] == key, na.rm = TRUE) != 1L) {
    writeBin(original, path)
    stop("Discovery register update failed its identity or row-count check.", call. = FALSE)
  }
}

candidates_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(candidates_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected one Celtic Sea herring candidate row.", call. = FALSE)
candidates$import_status[candidate_row] <- "partial"
candidates$review_date[candidate_row] <- "2026-11-03"
candidates$output_evidence[candidate_row] <- paste(
  "HAWG Table 6.6.1.4 provides annual catch, SSB, total biomass, Fbar ages 2-5 and age-1 recruitment through 2025.",
  "No uncertainty intervals or fitted N-at-age/F-at-age values were recovered."
)
if (!grepl("Imported report-table inputs and outputs", candidates$notes[candidate_row], fixed = TRUE)) {
  candidates$notes[candidate_row] <- paste(
    candidates$notes[candidate_row],
    "Imported report-table inputs and outputs. The 2019 acoustic index row and 2025 catch input/output disagree internally; source values are retained pending the native run files."
  )
}
replace_candidate_register_row(candidates_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- which(inventory$unit_key == paste0("candidate:", stock_id))
if (length(inventory_row) != 1L) stop("Expected one Celtic Sea herring inventory row.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"
replace_discovery_row(inventory_path, inventory_row,
  inventory[inventory_row, , drop = FALSE], "unit_key", paste0("candidate:", stock_id))

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(selected_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("Expected one selected Celtic Sea herring row.", call. = FALSE)
selected$review_date[selected_row] <- "2026-11-03"
selected$curation_status[selected_row] <- "partial_source_import"
replace_discovery_row(selected_path, selected_row,
  selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)

cat("Imported partial Celtic Sea herring source records:", nrow(input_data), "inputs,",
  nrow(assumptions), "assumptions, and", nrow(outputs), "outputs.\n")
