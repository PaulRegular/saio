root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ices_sole_north_sea_2025")
pdf_file <- file.path(cache, "WGNSSK_2026.pdf")
assessment_id <- "ices_sole_north_sea_2026_summary"
stock_id <- "ck_ices_wgnssk_solea_ns_4"
report_url <- "https://doi.org/10.17895/ices.pub.32676345"
framework_url <- "https://doi.org/10.17895/ices.pub.25471987.v1"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23777"

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to import the official ICES report tables.", call. = FALSE)
}
if (!file.exists(pdf_file)) stop("The cached 2026 WGNSSK PDF is required.", call. = FALSE)
sha256 <- system2("certutil", c("-hashfile", shQuote(pdf_file), "SHA256"), stdout = TRUE)
sha256 <- gsub("[^A-F0-9]", "", toupper(sha256[grepl("^[0-9A-Fa-f ]+$", sha256)]))
if (!identical(sha256, "9D33846CF100DD8544BA30DBEFFC7435A857A71854D318DBC7B383D668B03857")) {
  stop("The cached WGNSSK 2026 report does not match its recorded SHA-256.", call. = FALSE)
}

pdf_pages <- pdftools::pdf_text(pdf_file)
report <- unlist(strsplit(pdf_pages, "\n", fixed = TRUE), use.names = FALSE)
table_captions <- grep("Table 16.", report, fixed = TRUE)
table_captions <- table_captions[grepl("^\\s*Table 16\\.[0-9]+[a-z]?[:.]", report[table_captions], perl = TRUE)]

read_report_table <- function(table, years, ages) {
  pattern <- paste0("^\\s*Table\\s+", gsub(".", "[.]", table, fixed = TRUE), "[:.]")
  start <- grep(pattern, report, perl = TRUE)
  if (length(start) != 1L) stop("Expected one caption for Table ", table, ".", call. = FALSE)
  end <- min(table_captions[table_captions > start], length(report) + 1L)
  lines <- report[start:(end - 1L)]
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}", lines, perl = TRUE)]
  parsed <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    year <- as.integer(gsub("[^0-9].*$", "", tokens[[1L]]))
    values <- suppressWarnings(as.numeric(gsub("[*†‡]$", "", tokens[-1L])))
    if (length(values) != length(ages) || anyNA(values)) {
      stop("Unexpected values in Table ", table, ": ", line, call. = FALSE)
    }
    c(year = year, values)
  })
  values <- do.call(rbind, parsed)
  if (!identical(as.integer(values[, "year"]), as.integer(years))) {
    stop("Unexpected year coverage in Table ", table, ".", call. = FALSE)
  }
  if (anyDuplicated(values[, "year"])) stop("Duplicate years in Table ", table, ".", call. = FALSE)
  result <- data.frame(year = as.integer(values[, "year"]), values[, -1L, drop = FALSE],
    check.names = FALSE, row.names = NULL
  )
  names(result)[-1L] <- ifelse(is.na(ages), "total", as.character(ages))
  result
}

read_biology_table <- function() {
  start <- grep("^\\s*Table\\s+16\\.8[:.]", report, perl = TRUE)
  end <- min(table_captions[table_captions > start], length(report) + 1L)
  lines <- report[start:(end - 1L)]
  lines <- lines[grepl("^\\s*[0-9]+\\s+", lines, perl = TRUE)]
  parsed <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    values <- suppressWarnings(as.numeric(tokens))
    if (length(values) != 3L || anyNA(values)) return(NULL)
    values
  })
  parsed <- Filter(Negate(is.null), parsed)
  values <- do.call(rbind, parsed)
  if (!identical(as.integer(values[, 1L]), 0:10)) {
    stop("Table 16.8 must cover ages 0 through 10+.", call. = FALSE)
  }
  data.frame(age = as.integer(values[, 1L]), maturity = values[, 2L],
    natural_mortality = values[, 3L], row.names = NULL
  )
}

as_long <- function(table, ages) {
  columns <- ifelse(is.na(ages), "total", as.character(ages))
  data.frame(
    year = rep(table$year, times = length(ages)),
    age = rep(ages, each = nrow(table)),
    value = as.vector(as.matrix(table[columns])),
    stringsAsFactors = FALSE
  )
}

landings <- read_report_table("16.3", 1957:2025, 0:10)
discards <- read_report_table("16.4", 2002:2025, 0:10)
landings_weight <- read_report_table("16.5", 1957:2025, 0:10)
discard_weight <- read_report_table("16.6", 1957:2025, 0:10)
stock_weight <- read_report_table("16.7", 1957:2025, 0:10)
biology <- read_biology_table()
bts <- read_report_table("16.9", 1990:2025, NA_integer_)
coast <- read_report_table("16.10", 1990:2025, NA_integer_)
numbers <- read_report_table("16.11", 1957:2025, 0:10)
fishing_mortality <- read_report_table("16.12", 1957:2025, 0:10)

age_error_lines <- strsplit(pdf_pages[[606L]], "\n", fixed = TRUE)[[1L]]
age_error_rows <- lapply(age_error_lines, function(line) {
  tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
  values <- suppressWarnings(as.numeric(tokens))
  if (length(values) != 11L || anyNA(values)) return(NULL)
  values
})
age_error_rows <- Filter(Negate(is.null), age_error_rows)
age_error_matrix <- do.call(rbind, age_error_rows)
if (nrow(age_error_matrix) == 12L && identical(as.integer(age_error_matrix[1L, ]), 0:10)) {
  age_error_matrix <- age_error_matrix[-1L, , drop = FALSE]
}
age_error_sums <- rowSums(age_error_matrix)
if (nrow(age_error_matrix) != 11L || ncol(age_error_matrix) != 11L ||
  any(!is.finite(age_error_matrix)) || any(age_error_matrix < 0 | age_error_matrix > 1) ||
  any(abs(age_error_sums[1:9] - 1) > 0.002) ||
  abs(age_error_sums[10] - 0.991) > 0.002 || abs(age_error_sums[11] - 0.91) > 0.002) {
  stop("Table 16.1 age-reading error matrix did not validate.", call. = FALSE)
}
age_error_value <- paste(vapply(seq_len(nrow(age_error_matrix)), function(i) {
  paste0(i - 1L, ":", paste(sprintf("%.3f", age_error_matrix[i, ]), collapse = ","))
}, character(1)), collapse = ";")

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", season = "", sampling_time = NA_real_,
                       source_reference, transformation = "Copied from the official report.", notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  years <- recycle(year)
  data.frame(
    assessment_id = assessment_id, type = recycle(type), measure = recycle(measure),
    basis = recycle(basis), fleet = recycle(fleet), survey = recycle(survey),
    sex = "", region = "", season = recycle(season), year = years,
    year_basis = ifelse(is.na(years), "", "calendar_year"), age = recycle(age),
    value = as.numeric(value), unit = recycle(unit), sampling_time = recycle(sampling_time),
    source_type = "official_table", source_reference = recycle(source_reference),
    transformation = recycle(transformation), notes = recycle(notes), observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

long_inputs <- function(table, ages, type, measure, basis, unit, source_table,
                        fleet = "", survey = "", season = "", sampling_time = NA_real_,
                        transformation = "Copied the reported values without rescaling.", notes = "") {
  values <- as_long(table, ages)
  input_rows(type, measure, basis, values$year, values$age, values$value, unit,
    fleet = fleet, survey = survey, season = season, sampling_time = sampling_time,
    source_reference = paste0(report_url, "; Table ", source_table),
    transformation = transformation, notes = notes
  )
}

inputs_new <- do.call(rbind, list(
  long_inputs(landings, 0:10, "catch", "numbers_at_age", "numbers", "thousand fish", "16.3",
    fleet = "Landings", notes = "Age 10 is the 10+ group. The table includes an explicit zero age-0 column; the narrative describes age 1-10+ catches."),
  long_inputs(discards, 0:10, "catch", "numbers_at_age", "numbers", "thousand fish", "16.4",
    fleet = "Discards", notes = "Age 10 is the 10+ group. Age-specific discards are tabulated from 2002; earlier total discards are reconstructed but their age allocation is not tabulated."),
  long_inputs(landings_weight, 0:10, "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish", "16.5",
    fleet = "Landings", notes = "Age 0 landings weight is reported as a constant 0.01 kg; age 10 is the 10+ group."),
  long_inputs(discard_weight, 0:10, "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish", "16.6",
    fleet = "Discards", notes = "Age 10 is the 10+ group."),
  long_inputs(stock_weight, 0:10, "weight", "weight_at_age", "kg_per_fish", "kg per fish", "16.7",
    notes = "Quarter-2 catch weights are used as stock weights at both the start and end of the spawning season; age 10 is the 10+ group."),
  input_rows("maturity", "maturity_at_age", "proportion", NA_integer_, biology$age,
    biology$maturity, "proportion", source_reference = paste0(report_url, "; Table 16.8"),
    notes = "Fixed knife-edge maturity at age 3."),
  input_rows("M", "natural_mortality_at_age", "per_year", NA_integer_, biology$age,
    biology$natural_mortality, "per year", source_reference = paste0(report_url, "; Table 16.8"),
    notes = "Fixed, time-invariant age-specific Lorenzen mortality; values are rounded as printed."),
  long_inputs(bts, NA_integer_, "index", "relative_biomass_index", "index_scale",
    "source relative-index units (multiplier not stated)", "16.9", survey = "BTS Q3",
    season = "Q3", sampling_time = 0.625,
    notes = "Annual BTS abundance index. The report does not state a physical scale multiplier."),
  long_inputs(coast, NA_integer_, "index", "relative_biomass_index", "index_scale",
    "source relative-index units (multiplier not stated)", "16.10", survey = "COAST (SNS + DYFS)",
    season = "Q3", sampling_time = 0.625,
    notes = "Annual combined SNS and DYFS abundance index. The report does not state a physical scale multiplier.")
))

assumption_rows <- function(component, setting, value, source_reference, notes = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = "",
    survey = "", sex = "", region = "", season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

assumptions_new <- do.call(rbind, list(
  assumption_rows("assessment", "model_family", "Stock Synthesis 3", report_url, "The 2026 report identifies the production model as SS3 version 3.30.24.2."),
  assumption_rows("population", "model_structure", "Single area, single sex, ages 0-10+", report_url, "Age 10 is the plus group; age-0 fish are explicitly included and recruitment enters at the beginning of the year."),
  assumption_rows("population", "stock_recruitment", "Beverton-Holt; fixed steepness h=0.6646", report_url, "Steepness is taken from FishLife correlations for Solea solea and is fixed."),
  assumption_rows("population", "spawning_stock_biomass_timing", "Start of year", report_url, "Fecundity is assumed directly proportional to individual weight."),
  assumption_rows("F", "fleets", "Landings and discards", report_url, "Both are represented as separate fleets in SS3."),
  assumption_rows("F", "selectivity", "Landings logistic, fixed in time except pulse-trawl years 2011-2021; discards and both surveys double-normal", report_url, "Some selectivity parameters are fixed at values from an initial fit because they were poorly estimated."),
  assumption_rows("F", "Fbar_ages", "2-6", report_url, "Ages 2-6 are fully selected for the mean fishing-mortality metric."),
  assumption_rows("index", "surveys", "BTS Q3 and COAST (SNS + DYFS) Q3", report_url, "The COAST index combines the Sole Net Survey and Demersal Young Fish Survey."),
  assumption_rows("index", "survey_age_ranges", "BTS ages 0-10+; SNS ages 0-5; DYFS ages 0-1", report_url, "The assessment uses standardized annual BTS and combined COAST indices; the report tables give one aggregate value per year."),
  assumption_rows("index", "survey_timing", "Q3 represented as 0.625", report_url, "The report identifies all survey inputs as Q3; 0.625 is the quarter midpoint used for the database timing field."),
  assumption_rows("biology", "maturity_at_age", "Knife-edge maturity at age 3", report_url, "The assessment retains the benchmark ogive despite evidence that age-2 and age-3 maturity may have changed."),
  assumption_rows("M", "natural_mortality", "Fixed Lorenzen formulation, M_a proportional to W_a^-0.288", report_url, "The report gives the age-specific fixed values in Table 16.8; no time-varying M is estimated."),
  assumption_rows("biology", "age_reading_error_matrix", age_error_value, paste0(report_url, "; Table 16.1"), "Time-invariant 2016 exchange matrix retained by the assessment. Columns are labelled ages 0-10 and the 11 rows are assigned in order to ages 0-10. Rows 9 and 10 sum to 0.991 and 0.910 from the printed entries; values are not rescaled."),
  assumption_rows("catch", "historical_discard_reconstruction", "Total discards before 2002 reconstructed from landings", report_url, "The report does not tabulate an age-specific allocation for these earlier years; only the 2002-2025 discard-at-age series is imported."),
  assumption_rows("assessment", "native_model_files", "Not recovered", report_url, "The report documents the production model, but a matching native SS3 input/output archive was not located.")
))

age_outputs <- function(table, ages, measure, type, unit, source_table, notes) {
  values <- as_long(table, ages)
  data.frame(assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = values$year, age = values$age,
    age_group = ifelse(values$age == max(ages), paste0(max(ages), "+"), ""),
    value = values$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table",
    source_reference = paste0(report_url, "; Table ", source_table),
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

numbers_output <- age_outputs(numbers, 0:10, "numbers_at_age", "population",
  "thousand fish", "16.11", "SS3 estimated stock numbers at age; age 10 is the plus group. Point estimates only.")
f_output <- age_outputs(fishing_mortality, 0:10, "fishing_mortality_at_age", "mortality",
  "per year", "16.12", "SS3 estimated fishing mortality at age; age 10 is the plus group. Point estimates only.")
total_numbers <- stats::aggregate(value ~ year, numbers_output, sum)
total_output <- data.frame(assessment_id = assessment_id, type = "population",
  measure = "total_numbers", fleet = "", survey = "", sex = "", region = "",
  season = "", year = total_numbers$year, age = NA_integer_, age_group = "",
  value = total_numbers$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
  unit = "thousand fish", source_type = "derived_source_output",
  source_reference = paste0(report_url, "; Table 16.11"),
  notes = "Derived by summing reported N-at-age values; uncertainty is unavailable.",
  stringsAsFactors = FALSE, check.names = FALSE
)
outputs_new <- rbind(numbers_output, f_output, total_output)

assessments_file <- file.path(database, "assessments.csv")
assumptions_file <- file.path(database, "assumptions.csv")
inputs_file <- file.path(database, "inputs.csv")
outputs_file <- file.path(database, "outputs.csv")
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
assessments <- read_table(assessments_file)
assumptions_existing <- read_table(assumptions_file)
inputs_existing <- read_table(inputs_file)
outputs_existing <- read_table(outputs_file)

current_index <- which(assessments$assessment_id == assessment_id)
historical_index <- which(assessments$assessment_id == "ices_sole_north_sea_2025")
if (length(current_index) != 1L || length(historical_index) != 1L ||
  any(inputs_existing$assessment_id == assessment_id) || any(assumptions_existing$assessment_id == assessment_id) ||
  any(outputs_existing$assessment_id == assessment_id & outputs_existing$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "total_numbers"))) {
  stop("Expected one existing 2026 SAG record and no duplicate detailed 2026 tables.", call. = FALSE)
}
assessments$is_current[historical_index] <- FALSE
assessments$assessment_type[current_index] <- "annual_assessment"
assessments$model_family[current_index] <- "Stock Synthesis"
assessments$model_version[current_index] <- "3.30.24.2"
assessments$is_current[current_index] <- TRUE
assessments$is_applied[current_index] <- TRUE
assessments$framework_year[current_index] <- 2024L
assessments$assessment_url[current_index] <- report_url
assessments$framework_url[current_index] <- framework_url
assessments$data_url[current_index] <- sag_url
assessments$assumptions_status[current_index] <- "partial"
assessments$inputs_status[current_index] <- "partial"
assessments$outputs_status[current_index] <- "partial"
assessments$notes[current_index] <- paste(
  "The 2026 WGNSSK production assessment uses data through 2025 and is documented in the detailed report.",
  "Input tables, fixed biology, the age-reading error matrix, and N/F-at-age outputs are imported from the report; aggregate estimates and intervals remain from ICES SAG.",
  "Native SS3 files, likelihood settings, and age-specific uncertainty are not available. The legacy _summary ID is retained because it identifies the SAG series."
)

if (anyDuplicated(paste(inputs_new$assessment_id, inputs_new$type, inputs_new$measure,
  inputs_new$fleet, inputs_new$survey, inputs_new$year, inputs_new$age, sep = "\r"))) {
  stop("The 2026 input import contains duplicate rows.", call. = FALSE)
}
if (anyDuplicated(paste(outputs_new$assessment_id, outputs_new$type, outputs_new$measure,
  outputs_new$year, outputs_new$age, sep = "\r"))) stop("The 2026 output import contains duplicate rows.", call. = FALSE)
if (any(!is.finite(inputs_new$value)) || any(inputs_new$value < 0) || any(!is.finite(outputs_new$value))) {
  stop("Imported observations and estimates must be finite and non-negative.", call. = FALSE)
}

if (identical(Sys.getenv("TINYAM_IMPORT_DRY_RUN"), "true")) {
  cat("Dry run: inputs", nrow(inputs_new), "outputs", nrow(outputs_new), "assumptions", nrow(assumptions_new), "\n")
} else {
  data.table::fwrite(assessments, assessments_file, quote = TRUE, na = "", eol = "\r\n")
  data.table::fwrite(rbind(assumptions_existing, assumptions_new), assumptions_file, quote = TRUE, na = "", eol = "\r\n")
  data.table::fwrite(rbind(inputs_existing, inputs_new), inputs_file, quote = TRUE, na = "", eol = "\r\n")
  data.table::fwrite(rbind(outputs_existing, outputs_new), outputs_file, quote = TRUE, na = "", eol = "\r\n")
  cat("Imported North Sea sole 2026 report data. Inputs:", nrow(inputs_new),
    "Outputs:", nrow(outputs_new), "Assumptions:", nrow(assumptions_new), "\n")
}
