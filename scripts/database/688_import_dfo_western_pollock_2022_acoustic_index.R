root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

stock_id <- "dfo_western_component_pollock_4xopqrs5"
assessment_id <- "dfo_western_component_pollock_2022_j_m4b"
candidate_id <- "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)"
survey_name <- "Western Component Pollock acoustic index"
source_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-029-eng.pdf"
ages <- 2:13
age_columns <- paste0("age_", ages)
cache_options <- c(
  file.path(root, "source_cache", "discovery_dfo_western_pollock_2022"),
  file.path("..", "..", "discovery_dfo_western_pollock_2022")
)
source_name <- "dfo_western_pollock_2026_029_table10_acoustic_biomass_at_age.csv"
source_file_options <- file.path(cache_options, source_name)
source_file <- source_file_options[file.exists(source_file_options)][1L]
if (is.na(source_file)) stop("The Table 10 acoustic-index transcription is missing.")

source_table <- utils::read.csv(source_file, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
expected_columns <- c("year", age_columns, "total_mt", "low_ci_mt", "high_ci_mt")
expected_years <- c(2012L, 2016L:2020L)
if (!identical(names(source_table), expected_columns) ||
    !identical(as.integer(source_table$year), expected_years) ||
    anyNA(source_table[c("total_mt", "low_ci_mt", "high_ci_mt")]) ||
    any(source_table$total_mt < 0) ||
    any(source_table$low_ci_mt > source_table$total_mt) ||
    any(source_table$high_ci_mt < source_table$total_mt) ||
    any(unlist(source_table[age_columns], use.names = FALSE) < 0, na.rm = TRUE)) {
  stop("The Table 10 source transcription failed its structural checks.")
}

age_values <- as.numeric(t(as.matrix(source_table[age_columns])))
age_inputs <- data.frame(
  year = rep(as.integer(source_table$year), each = length(ages)),
  age = rep(ages, times = nrow(source_table)),
  value = age_values,
  stringsAsFactors = FALSE
)
age_inputs <- age_inputs[!is.na(age_inputs$value), , drop = FALSE]

ci_notes <- paste0(
  "Table 10 reports bootstrapped total-index LowCI=",
  source_table$low_ci_mt, " mt and HighCI=", source_table$high_ci_mt,
  " mt; the confidence level is not stated."
)
total_inputs <- data.frame(
  year = as.integer(source_table$year),
  value = source_table$total_mt,
  notes = ci_notes,
  stringsAsFactors = FALSE
)

source_reference <- paste(source_url, "Table 10, printed p. 47", sep = "; ")
transformation <- paste(
  "Reshaped the official acoustic biomass index table to age-specific and",
  "aggregate rows. The report describes disaggregation using tow length",
  "frequencies. Source dashes (not used) remain missing and are not entered as zero."
)
age_rows <- pacific_database_row("inputs", n = nrow(age_inputs),
  assessment_id = assessment_id,
  type = "index", measure = "biomass_at_age", basis = "index_scale",
  survey = survey_name, region = "4Xopqrs5Yb5Zc", season = "summer",
  year = age_inputs$year, year_basis = "calendar_year", age = age_inputs$age,
  value = age_inputs$value, unit = "mt", sampling_time = 0.5,
  source_type = "official_table", source_reference = source_reference,
  transformation = transformation,
  notes = paste(
    "Age-disaggregated acoustic biomass index for the 2022 M4B model family.",
    "The table's age-specific values are retained in metric tonnes."
  )
)
total_rows <- pacific_database_row("inputs", n = nrow(total_inputs),
  assessment_id = assessment_id,
  type = "index", measure = "total_biomass", basis = "index_scale",
  survey = survey_name, region = "4Xopqrs5Yb5Zc", season = "summer",
  year = total_inputs$year, year_basis = "calendar_year", value = total_inputs$value,
  unit = "mt", sampling_time = 0.5,
  source_type = "official_table", source_reference = source_reference,
  transformation = transformation, notes = total_inputs$notes
)
new_inputs <- rbind(age_rows, total_rows)

input_path <- file.path(root, "database", "inputs.csv")
header <- readLines(input_path, n = 1L, warn = FALSE)
con <- file(input_path, open = "r")
readLines(con, n = 1L, warn = FALSE)
existing_lines <- character()
repeat {
  chunk <- readLines(con, n = 50000L, warn = FALSE)
  if (!length(chunk)) break
  target <- startsWith(chunk, paste0('"', assessment_id, '",'))
  if (any(target)) existing_lines <- c(existing_lines, chunk[target])
}
close(con)

as_character_table <- function(x) {
  out <- as.data.frame(lapply(x, function(column) {
    value <- as.character(column)
    value[is.na(column)] <- ""
    value
  }), stringsAsFactors = FALSE, check.names = FALSE)
  names(out) <- names(x)
  rownames(out) <- NULL
  out
}
if (length(existing_lines)) {
  existing <- utils::read.csv(text = paste(c(header, existing_lines), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character",
    na.strings = character())
  selected <- existing$type == "index" & existing$survey == survey_name &
    existing$measure %in% c("biomass_at_age", "total_biomass")
  existing <- existing[selected, , drop = FALSE]
  rownames(existing) <- NULL
} else {
  existing <- utils::read.csv(text = header, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character())
}
key_columns <- c("assessment_id", "type", "measure", "survey", "region",
  "season", "year", "year_basis", "age")
row_key <- function(x) do.call(paste, c(x[key_columns], sep = "|"))
expected <- as_character_table(new_inputs)
existing <- existing[, names(expected), drop = FALSE]
expected_keys <- row_key(expected)
existing_keys <- row_key(existing)
if (anyDuplicated(expected_keys) || anyDuplicated(existing_keys) ||
    any(!existing_keys %in% expected_keys)) {
  stop("Existing acoustic-index rows conflict with the Table 10 import.")
}
overlap <- match(existing_keys, expected_keys)
expected_overlap <- expected[overlap, , drop = FALSE]
rownames(expected_overlap) <- NULL
if (length(overlap)) {
  existing_matrix <- as.matrix(existing)
  expected_matrix <- as.matrix(expected_overlap)
  existing_matrix[is.na(existing_matrix)] <- ""
  expected_matrix[is.na(expected_matrix)] <- ""
  if (!identical(unname(existing_matrix), unname(expected_matrix))) {
    stop("Existing acoustic-index rows differ from the Table 10 source values.")
  }
}
missing <- !expected_keys %in% existing_keys
if (any(missing)) {
  utils::write.table(new_inputs[missing, , drop = FALSE], input_path,
    sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

assessments_path <- file.path(root, "database", "assessments.csv")
assessments <- utils::read.csv(assessments_path, stringsAsFactors = FALSE,
  check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L || assessments$stock_id[assessment_row] != stock_id) {
  stop("Expected the current Western Component Pollock J_M4B assessment row.")
}
assessments$notes[assessment_row] <- paste(
  "Tables 1 and 5 provide commercial catch-at-age and summer RV abundance-at-age.",
  "Table 10 provides 51 age-specific acoustic biomass values and six aggregate totals with bootstrapped bounds.",
  "The 2020 age values sum to 38,407 mt while Table 10 reports 38,061 mt; Part I Table 9 reports 38,408 mt. Both totals are retained as published.",
  "The Model J_M4B mortality input is now imported at published precision; run-specific weight and maturity matrices and annual fitted population surfaces remain unavailable.",
  "Local transcriptions and access records are checksummed in the ignored cache; the original PDF binary was not retrieved."
)
assessment_tmp <- tempfile(tmpdir = dirname(assessments_path), fileext = ".csv")
utils::write.csv(assessments, assessment_tmp, row.names = FALSE, na = "")
if (!file.copy(assessment_tmp, assessments_path, overwrite = TRUE)) {
  stop("Could not update the assessment source note.")
}
unlink(assessment_tmp)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(candidate_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected one Western Component Pollock candidate.")
candidates$review_date[candidate_row] <- "2026-11-14"
candidates$survey_age_evidence[candidate_row] <- paste(
  "Tables 5 and 10 provide separate summer RV abundance-at-age and acoustic biomass-at-age series.",
  "Table 10 has 51 non-missing age values for ages 2-12 in 2012 and 2016-2020; dashes are not-used cells, not zero observations.",
  "The age allocation is based on tow length frequencies. The 2020 age values sum to 38,407 mt; Table 10 reports a 38,061 mt total while Part I Table 9 reports 38,408 mt. Both totals are retained as published."
)
candidates$decision_reason[candidate_row] <- paste(
  "Partial source import now includes commercial catch-at-age, summer RV abundance-at-age, and acoustic biomass-at-age data for the 2022 model family.",
  "The 2020 age cells sum to 38,407 mt; Table 10 reports 38,061 mt while Part I Table 9 reports 38,408 mt. Both totals are retained as published.",
  "The published M input matrix is now imported; run-specific weight and maturity matrices and annual fitted population surfaces remain unavailable.",
  "The original PDF binary could not be cached; searchable official tables were transcribed with checksums in the ignored cache."
)
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)

if (any(missing)) {
  cat(sprintf("Appended %d Table 10 acoustic-index rows; the assessment remains partial.\n", sum(missing)))
} else {
  cat("All Table 10 acoustic-index rows already match; nothing was appended.\n")
}
