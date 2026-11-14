assessment_id <- "noaa_south_atlantic_red_snapper_2024"
candidate_id <- "NOAA:10231"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source("scripts/database/candidate_register_io.R")
manifest <- read.csv(
  "provenance/discovery_noaa_satl_red_snapper_2024/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"
)
cache_options <- c(
  file.path("source_cache", "discovery_noaa_satl_red_snapper_2024"),
  file.path("..", "..", "discovery_noaa_satl_red_snapper_2024")
)
source_dir <- cache_options[vapply(cache_options, function(path) {
  file.exists(file.path(path, "sources.csv"))
}, logical(1))][1L]
if (is.na(source_dir)) stop("Could not find the cached SEDAR 73 sources.", call. = FALSE)

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  value <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(value) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  value
}
verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), tolower(row$sha256))) {
    stop("Cached source differs from pinned provenance: ", name, call. = FALSE)
  }
  path
}

report_pdf <- verify_source("SEDAR73_SAR_2021.pdf")
update_pdf <- verify_source("SEFSC_2024_update_SEDAR73.pdf")
report_text <- sub("\\.pdf$", ".txt", report_pdf, ignore.case = TRUE)
if (!file.exists(report_text)) stop("Missing local SEDAR 73 text extract.", call. = FALSE)
lines <- readLines(report_text, warn = FALSE, encoding = "UTF-8")

parse_biology_table <- function() {
  title <- "Table 2. Average size (TL, in mm and in) and weight"
  start <- which(grepl(title, lines, fixed = TRUE))[1L]
  if (is.na(start)) stop("Could not find the age-specific biology table.", call. = FALSE)
  next_tables <- which(grepl("^Table[[:space:]]+[0-9]+\\.", trimws(lines)))
  next_tables <- next_tables[next_tables > start]
  end <- min(next_tables) - 1L
  section <- lines[seq.int(start + 1L, end)]
  parsed <- lapply(section, function(line) {
    line <- gsub("([0-9])[[:space:]]+\\.([0-9]+)", "\\1.\\2", line,
      perl = TRUE)
    fields <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    values <- suppressWarnings(as.numeric(fields))
    if (length(values) != 9L || any(!is.finite(values))) return(NULL)
    values
  })
  parsed <- Filter(Negate(is.null), parsed)
  result <- as.matrix(do.call(rbind, parsed))
  if (nrow(result) != 20L || !identical(as.integer(result[, 1L]), 1:20)) {
    stop("Unexpected age coverage in the SEDAR 73 biology table.", call. = FALSE)
  }
  result
}

table <- parse_biology_table()
if (!identical(as.numeric(table[1L, 2:9]),
    c(323.9, 12.8, 1.2, 0.5, 0.43, 55.5, 22, 0.29)) ||
    !identical(as.numeric(table[20L, 2:9]),
      c(905.2, 35.6, 25.2, 0.5, 1, 2705.7, 128, 0.11))) {
  stop("Age-specific biology values do not match the published table.", call. = FALSE)
}

reference <- paste(
  "SEDAR 73 South Atlantic Red Snapper SAR, Section II, Table 2, p. 45;",
  "SEFSC 2024 update to SEDAR 73, Section 2.1, p. 9"
)
base_notes <- paste(
  "Static age-specific life-history input carried forward from SEDAR 73.",
  "The 2024 update identifies SEDAR 73 life-history sources as inputs and",
  "states that its only methodological difference is discard-mortality treatment.",
  "Age 20 is the model plus group (20+)."
)
input_columns <- c(
  "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age", "value", "unit",
  "sampling_time", "source_type", "source_reference", "transformation", "notes",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin"
)
specs <- list(
  list(type = "biology", measure = "growth_length_at_age",
    basis = "native_covariate", column = 2L, unit = "mm", sex = "",
    note = "Population average total length at age, in millimetres; the source also reports the same curve in inches."),
  list(type = "weight", measure = "weight_at_age", basis = "weight_per_fish",
    column = 4L, unit = "lb whole weight per fish", sex = "",
    note = "Population average whole weight at age."),
  list(type = "biology", measure = "proportion_female_at_age",
    basis = "proportion", column = 5L, unit = "proportion", sex = "",
    note = "Proportion female at age."),
  list(type = "maturity", measure = "maturity_at_age", basis = "proportion",
    column = 6L, unit = "proportion", sex = "female",
    note = "Female maturity proportion at age."),
  list(type = "biology", measure = "fecundity_at_age", basis = "egg_count",
    column = 7L, unit = "1000 eggs per batch", sex = "female",
    note = "Batch fecundity at age; kept separate from batches per year."),
  list(type = "biology", measure = "batches_per_year_at_age",
    basis = "native_scale", column = 8L, unit = "batches per year", sex = "female",
    note = "Annual number of batches at age."),
  list(type = "M", measure = "natural_mortality_at_age", basis = "per_year",
    column = 9L, unit = "per year", sex = "",
    note = "Fixed natural mortality at age; constant over years in the assessment.")
)
inputs <- do.call(rbind, lapply(specs, function(spec) {
  data.frame(
    assessment_id = assessment_id, type = spec$type, measure = spec$measure,
    basis = spec$basis, fleet = "", survey = "", sex = spec$sex,
    region = "", season = "", year = NA_integer_, year_basis = "",
    age = as.integer(table[, 1L]), value = as.numeric(table[, spec$column]),
    unit = spec$unit, sampling_time = NA_real_, source_type = "official_table",
    source_reference = reference, transformation = "",
    notes = paste(base_notes, spec$note), observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "", weight_bin = "",
    stringsAsFactors = FALSE
  )[input_columns]
}))
rownames(inputs) <- NULL
if (nrow(inputs) != 140L || any(!is.finite(inputs$value))) {
  stop("Unexpected age-specific biology row count or missing values.", call. = FALSE)
}

write_table_rows <- function(path, rows) {
  write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double")
}
update_assessment <- function() {
  path <- "database/assessments.csv"
  assessments <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(assessments$assessment_id == assessment_id)
  if (length(i) != 1L) stop("Current assessment row is not unique.", call. = FALSE)
  assessments$inputs_status[i] <- "partial"
  assessments$notes[i] <- paste(
    "Age-specific static life-history inputs carried forward from SEDAR 73 are imported.",
    "Run-specific 2024 catch, index, and composition observations remain unavailable."
  )
  write.csv(assessments, path, row.names = FALSE, na = "")
}
update_candidate <- function() {
  path <- "discovery/candidates.csv"
  candidates <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(candidates$candidate_id == candidate_id)
  if (length(i) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
  evidence <- paste(
    "2024 update confirms the SEDAR 73 life-history sources are used; age-specific",
    "length, weight, female proportion, maturity, fecundity, batches/year, and fixed M",
    "from SEDAR 73 Table 2 are imported as carried-forward static inputs."
  )
  append_evidence <- function(old, new) {
    if (is.na(old) || !nzchar(old)) new else paste(old, new)
  }
  candidates$weights_evidence[i] <- append_evidence(candidates$weights_evidence[i], evidence)
  candidates$maturity_evidence[i] <- append_evidence(candidates$maturity_evidence[i], evidence)
  candidates$mortality_evidence[i] <- append_evidence(candidates$mortality_evidence[i], evidence)
  candidates$import_status[i] <- "partial"
  candidates$review_date[i] <- as.character(Sys.Date())
  candidates$notes[i] <- paste(
    candidates$notes[i],
    "Static age-specific biology carried forward from SEDAR 73 Table 2 is now recorded for the 2024 update; its run-specific observation arrays remain unavailable."
  )
  replace_candidate_register_row(path, i, candidates[i, , drop = FALSE], candidate_id)
}

if (!write_mode) {
  cat("Dry run:", nrow(inputs), "age-specific biological input rows; ages 1-20+;",
    "assessment", assessment_id, ".\n")
} else {
  assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    check.names = FALSE)
  candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
    check.names = FALSE)
  if (sum(assessments$assessment_id == assessment_id) != 1L ||
      sum(candidates$candidate_id == candidate_id) != 1L) {
    stop("Import the 2024 assessment and verify its candidate row first.", call. = FALSE)
  }
  existing <- suppressWarnings(system2("rg", c("--color", "never",
    "--no-heading", "--no-line-number", "-F", assessment_id,
    "database/inputs.csv"), stdout = TRUE, stderr = FALSE))
  rg_status <- attr(existing, "status")
  if (is.null(rg_status)) rg_status <- 0L
  if (rg_status == 0L && length(existing)) {
    stop("Input rows already exist; review before writing.", call. = FALSE)
  }
  if (rg_status != 1L) stop("Could not check for existing input rows.", call. = FALSE)
  write_table_rows("database/inputs.csv", inputs)
  update_assessment()
  update_candidate()
  cat("Imported", nrow(inputs), "static biological input rows for", assessment_id, ".\n")
}
