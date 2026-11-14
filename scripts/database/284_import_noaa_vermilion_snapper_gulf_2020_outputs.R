root <- "."
stock_id <- "noaa_vermilion_snapper_gulf"
assessment_id <- "noaa_vermilion_snapper_gulf_sedar67_2020"
candidate_id <- "NOAA:10256"
report_url <- "https://sedarweb.org/documents/sedar-67-gulf-of-mexico-vermilion-snapper-final-stock-assessment-report/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

source_dir <- file.path(root, "source_cache/discovery_noaa_vermilion_snapper_gom_2020")
manifest <- read.csv(file.path(root,
  "provenance/discovery_noaa_vermilion_snapper_gom_2020/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}

verify_source <- function(name) {
  record <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_dir, name)
  if (nrow(record) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), record$sha256)) {
    stop("Cached source differs from its pinned provenance record: ", name,
      call. = FALSE)
  }
  path
}

report <- verify_source("sedar67_final_assessment.pdf")
text_path <- paste0(report, ".txt")
if (!file.exists(text_path)) {
  stop("Create the local page-separated text extract beside the cached report.",
    call. = FALSE)
}
report_text <- readChar(text_path, file.info(text_path)$size, useBytes = TRUE)
pages <- strsplit(report_text, "\f", fixed = TRUE)[[1L]]
table_page <- grepl("Table 18:", pages, fixed = TRUE) |
  grepl("Table 18 (cont.):", pages, fixed = TRUE)
if (sum(table_page) != 2L) {
  stop("Expected the two SEDAR 67 Table 18 pages.", call. = FALSE)
}

table_lines <- unlist(lapply(pages[table_page], function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE)
year_lines <- grep("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+",
  table_lines, value = TRUE, perl = TRUE)
table_values <- lapply(year_lines, function(line) {
  tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
  as.numeric(gsub(",", "", tokens, fixed = TRUE))
})
if (length(table_values) != 68L || any(lengths(table_values) != 6L)) {
  stop("SEDAR 67 Table 18 did not parse as 68 rows with six values.",
    call. = FALSE)
}
table_values <- as.data.frame(do.call(rbind, table_values))
names(table_values) <- c("year", "total_biomass", "spawning_output",
  "total_abundance", "recruitment", "SSB_ratio")
table_values$year <- as.integer(table_values$year)
if (!identical(table_values$year, 1950:2017) ||
    any(!is.finite(as.matrix(table_values)))) {
  stop("SEDAR 67 Table 18 years or values are invalid.", call. = FALSE)
}

output <- function(type, measure, value, unit, year = table_values$year,
                   age = NA_integer_, source_reference = "SEDAR67_SAR.pdf, Table 18",
                   notes = "") {
  pacific_database_row("outputs", assessment_id = assessment_id,
    type = type, measure = measure, value = value, unit = unit,
    year = year, age = age, source_type = "official_table",
    source_reference = source_reference, notes = notes)
}

outputs <- do.call(rbind, list(
  output("biomass", "total_biomass", table_values$total_biomass,
    "metric tons", notes = "Source-reported expected total biomass; values are rounded in Table 18."),
  output("biomass", "spawning_output", table_values$spawning_output,
    "eggs", notes = "Source-reported egg production; this is not biomass SSB. Values are rounded in Table 18."),
  output("population", "total_abundance", table_values$total_abundance,
    "thousand fish", notes = "Source-reported aggregate abundance, not numbers at age; values are rounded in Table 18."),
  output("recruitment", "recruitment", table_values$recruitment,
    "thousand fish", age = 0L,
    notes = "Source-reported age-0 recruitment; values are rounded in Table 18."),
  output("biomass", "SSB_ratio", table_values$SSB_ratio,
    "proportion", notes = "Source-reported depletion, defined as spawning output divided by unfished spawning output.")
))

assumption <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "run_identity",
    "SEDAR 67 standard Gulf of Mexico vermilion snapper assessment; terminal data year 2017.",
    "SEDAR67_SAR.pdf, report summary and Appendix A"),
  assumption("assessment", "later_summary_update",
    "Stock SMART records a 2023 Stock Monitoring Update; review outcome was accept previous approach and remand a new attempt.",
    "NOAA Stock SMART, stock 10256; source review",
    "The 2023 G-FISHER interim analysis was not accepted for revised catch advice and is not combined with SEDAR 67."),
  assumption("model", "model_version", "Stock Synthesis 3.30.14.05-safe",
    "SEDAR67_SAR.pdf, Appendix A"),
  assumption("population", "dimensions",
    "One Gulf management unit and one model area; one sex; model age bins 1-14 with age 14 as the plus group. Age-0 recruitment is reported separately.",
    "SEDAR67_SAR.pdf, Appendix A DAT file and Table 18"),
  assumption("observation", "catch_units",
    "Commercial east and west handline catch is in metric tons; recreational catch is in thousands of fish.",
    "SEDAR67_SAR.pdf, Appendix A DAT file",
    "Catch and composition inputs are recoverable from Appendix A but have not yet been transcribed into canonical input rows."),
  assumption("observation", "survey_indices",
    "The accepted model includes aggregate headboat, recreational, larval, video, SEAMAP groundfish, and shrimp-effort index series.",
    "SEDAR67_SAR.pdf, Appendix A DAT file and assessment description",
    "The survey likelihoods are not age-specific abundance indices; no within-year sampling fraction is inferred."),
  assumption("M", "natural_mortality",
    "Fixed age-specific Lorenzen M based on target average M = 0.25 per year; age-0 mortality is discounted for an assumed midyear birth date.",
    "SEDAR67_SAR.pdf, Table 3 and model description",
    "The numerical age vector is not yet imported."),
  assumption("biology", "growth_and_weight",
    "Fixed growth and length-weight relationships carried forward from SEDAR 45.",
    "SEDAR67_SAR.pdf, Table 2 and model description",
    "Annual weight-at-age is not directly reported in Table 18 and has not been derived."),
  assumption("biology", "maturity_and_spawning_output",
    "Spawning output is calculated in eggs from female proportion, maturity, fecundity, and spawning frequency; age-0 fish are not mature.",
    "SEDAR67_SAR.pdf, Table 2 and model description",
    "The source output is retained as eggs and is not converted to biomass SSB."),
  assumption("observation", "output_coverage",
    "Table 18 reports annual total biomass, egg-based spawning output, total abundance, age-0 recruitment, and depletion for 1950-2017.",
    "SEDAR67_SAR.pdf, Table 18",
    "The table provides point estimates only; it does not provide annual uncertainty or numeric N-at-age/F-at-age arrays.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA Fisheries", authority_stock_id = "10256",
  scientific_name = "Rhomboplites aurorubens",
  common_name = "Gulf of Mexico vermilion snapper",
  area = "Gulf of Mexico", region = "United States Gulf of Mexico",
  ocean = "Northwest Atlantic",
  notes = paste("NOAA stock 10256. This is the Gulf management unit and is",
    "separate from the Southern Atlantic Coast vermilion snapper unit NOAA:10257."))

assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2020L, terminal_year = 2017L,
  estimate_terminal_year = 2017L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.14.05-safe",
  is_current = TRUE, is_applied = TRUE, framework_year = 2016L,
  assessment_url = report_url,
  framework_url = "https://sedarweb.org/assessments/sedar-45/",
  data_url = "https://sedarweb.org/assessments/sedar-67/",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste("Latest publicly accessible detailed age-structured production",
    "assessment located. Stock SMART records a newer 2023 monitoring update,",
    "but no newer accepted age-structured output set was recovered. See the",
    "source review for the separate interim analysis and its limitations."))

inputs <- pacific_database_row("inputs", n = 0L)

row_signature <- function(data) {
  columns <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
    "region", "season", "year", "age", "age_group", "value", "se", "lwr",
    "upr", "unit", "source_type", "source_reference", "notes", "scenario")
  values <- lapply(data[columns], function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  do.call(paste, c(values, sep = "\r"))
}

read_assessment_rows <- function(path, id) {
  prefix <- paste0('"', id, '",')
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(NULL)
  if (status != 0L) stop("Could not read assessment rows from ", path, ".", call. = FALSE)
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(NULL)
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

update_candidate <- function() {
  path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(candidates$candidate_id == candidate_id)
  if (length(i) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
  if (candidates$match_status[i] %in% c("new", "unresolved")) {
    candidates$matched_stock_id[i] <- stock_id
    candidates$match_status[i] <- "matched"
  } else if (!identical(candidates$matched_stock_id[i], stock_id)) {
    stop("Candidate is already matched to another stock.", call. = FALSE)
  }
  candidates$import_status[i] <- "partial"
  added_evidence <- paste(
    "Imported SEDAR 67 Table 18 annual total biomass, egg-based spawning output,",
    "total abundance, age-0 recruitment, and depletion for 1950-2017; point estimates only."
  )
  current <- as.character(candidates$output_evidence[i])
  if (is.na(current) || !grepl(added_evidence, current, fixed = TRUE)) {
    candidates$output_evidence[i] <- paste(current, added_evidence)
  }
  candidates$notes[i] <- paste(
    "Table 18 output values are imported; no uncertainty, N-at-age, or F-at-age",
    "array is published there. The SEDAR 67 appendix contains model input files",
    "whose numerical observations remain to be transcribed. Source PDFs and",
    "checksums are cached locally."
  )
  replace_candidate_register_row(path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

if (!write_mode) {
  cat("Dry run:", nrow(assumptions), "assumptions;", nrow(outputs),
    "Table 18 outputs for", min(table_values$year), "-", max(table_values$year),
    "\n")
} else {
  assessment_rows <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (!assessment_id %in% assessment_rows$assessment_id) {
    if (stock_id %in% read.csv("database/stocks.csv", stringsAsFactors = FALSE)$stock_id) {
      stop("Stock ID already exists without its assessment; review before importing.",
        call. = FALSE)
    }
    append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  } else {
    existing_outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
    if (is.null(existing_outputs) ||
        !identical(sort(row_signature(existing_outputs)), sort(row_signature(outputs)))) {
      stop("Existing Table 18 output rows differ from this pinned import.", call. = FALSE)
    }
  }
  update_candidate()
  cat("Imported", assessment_id, ":", nrow(outputs),
    "Table 18 output rows; source inputs remain partial.\n")
}
