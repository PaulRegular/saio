root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

stock_id <- "dfo_western_component_pollock_4xopqrs5"
assessment_id <- "dfo_western_component_pollock_2022_j_m4b"
candidate_id <- "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)"
model_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-029-eng.pdf"
ages <- 2:13

cache_options <- c(
  file.path(root, "source_cache", "discovery_dfo_western_pollock_2022"),
  file.path("..", "..", "discovery_dfo_western_pollock_2022")
)
catch_file <- "dfo_western_pollock_2026_029_table1_catch_at_age.csv"
survey_file <- "dfo_western_pollock_2026_029_table5_rv_abundance_at_age.csv"
usable_cache <- cache_options[vapply(cache_options, function(path) {
  all(file.exists(file.path(path, c(catch_file, survey_file))))
}, logical(1L))]
if (!length(usable_cache)) {
  stop("The local Western Component Pollock table transcriptions are missing.")
}
cache_dir <- normalizePath(usable_cache[1L], winslash = "/", mustWork = TRUE)

catch_path <- file.path(cache_dir, catch_file)
survey_path <- file.path(cache_dir, survey_file)
if (!all(file.exists(c(catch_path, survey_path)))) {
  stop("Both local Table 1 and Table 5 transcriptions are required.")
}

read_source_table <- function(path, years) {
  x <- utils::read.csv(path, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "numeric")
  expected <- c("year", paste0("age_", ages))
  if (!identical(names(x), expected) ||
      !identical(as.integer(x$year), years) ||
      anyNA(x) || any(x[-1L] < 0)) {
    stop("Invalid source-table transcription: ", basename(path))
  }
  x
}

catch_wide <- read_source_table(catch_path, 1982:2020)
survey_wide <- read_source_table(survey_path, 1984:2020)

manifest_path <- file.path(cache_dir, "sources.csv")
manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE)
transcription_files <- c(catch_file, survey_file)
transcription_paths <- c(catch_path, survey_path)
missing_manifest <- !transcription_files %in% manifest$file
if (any(missing_manifest)) {
  new_sources <- data.frame(
    file = transcription_files[missing_manifest],
    source_url = model_url,
    retrieved_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    repository_revision = "DFO CSAS Research Document 2026/029, Tables 1 and 5",
    sha256 = unname(tools::sha256sum(transcription_paths[missing_manifest])),
    bytes = file.info(transcription_paths[missing_manifest])$size,
    notes = paste(
      "Local transcription of the cited official PDF table, not the original PDF binary.",
      "The PDF download returned archived-page HTML; values were transcribed from the",
      "official searchable PDF text on 2026-11-14."
    ),
    stringsAsFactors = FALSE
  )
  manifest <- rbind(manifest, new_sources)
  utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")
}

table_long <- function(x) {
  data.frame(
    year = rep(as.integer(x$year), each = length(ages)),
    age = rep(ages, times = nrow(x)),
    value = as.numeric(t(as.matrix(x[-1L]))),
    stringsAsFactors = FALSE
  )
}

catch_long <- table_long(catch_wide)
survey_long <- table_long(survey_wide)

catch_inputs <- pacific_database_row("inputs", n = nrow(catch_long),
  assessment_id = assessment_id,
  type = "catch", measure = "numbers_at_age", basis = "numbers",
  fleet = "Commercial fishery", region = "4Xopqrs5Yb5Zc", season = "annual",
  year = catch_long$year, year_basis = "calendar_year", age = catch_long$age,
  value = catch_long$value, unit = "thousand fish", sampling_time = 0.5,
  source_type = "official_table",
  source_reference = paste(model_url, "Table 1, printed p. 34", sep = "; "),
  transformation = paste(
    "Reshaped the official year-by-age table to one row per year and age.",
    "Values remain in the reported thousands of fish."
  ),
  notes = paste(
    "Corrected commercial catch-at-age for ages 2-13, 1982-2020.",
    "The report notes corrected age assignments for 2017-2020."
  )
)

actual_egb_years <- c(2016L, 2017L, 2019L, 2020L)
survey_notes <- ifelse(
  survey_long$year %in% actual_egb_years,
  paste(
    "Summer RV relative abundance at age for the Western Component.",
    "Table 5 uses actual Eastern Georges Bank (EGB) survey indices in this year."
  ),
  paste(
    "Summer RV relative abundance at age for the Western Component.",
    "Table 5 includes a simulated EGB index for this year."
  )
)
survey_inputs <- pacific_database_row("inputs", n = nrow(survey_long),
  assessment_id = assessment_id,
  type = "index", measure = "numbers_at_age", basis = "index_scale",
  survey = "DFO summer RV survey", region = "4Xopqrs5Yb5Zc",
  season = "summer",
  year = survey_long$year, year_basis = "calendar_year", age = survey_long$age,
  value = survey_long$value, unit = "thousand fish", sampling_time = 0.5,
  source_type = "official_table",
  source_reference = paste(model_url, "Table 5, printed p. 39", sep = "; "),
  transformation = paste(
    "Reshaped the official year-by-age table to one row per year and age.",
    "Values remain in the reported thousands of fish."
  ),
  notes = survey_notes
)

new_inputs <- rbind(catch_inputs, survey_inputs)
if (anyNA(new_inputs$value) || any(!is.finite(new_inputs$value)) ||
    anyDuplicated(new_inputs[c("assessment_id", "type", "measure", "fleet",
      "survey", "region", "season", "year", "age")])) {
  stop("The generated Pollock source-input rows are invalid.")
}

input_path <- file.path(root, "database", "inputs.csv")
input_header <- readLines(input_path, n = 1L, warn = FALSE)
con <- file(input_path, open = "r")
readLines(con, n = 1L, warn = FALSE)
existing_lines <- character()
repeat {
  chunk <- readLines(con, n = 100000L, warn = FALSE)
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
  existing_inputs <- utils::read.csv(
    text = paste(c(input_header, existing_lines), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character",
    na.strings = character()
  )
  selected <- (existing_inputs$type == "catch" &
    existing_inputs$measure == "numbers_at_age" &
    existing_inputs$fleet == "Commercial fishery") |
    (existing_inputs$type == "index" &
      existing_inputs$measure == "numbers_at_age" &
      existing_inputs$survey == "DFO summer RV survey")
  existing_inputs <- existing_inputs[selected, , drop = FALSE]
  rownames(existing_inputs) <- NULL
} else {
  existing_inputs <- utils::read.csv(text = input_header,
    stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character",
    na.strings = character())
}
expected_inputs <- as_character_table(new_inputs)
existing_inputs <- existing_inputs[, names(expected_inputs), drop = FALSE]
key_columns <- c("assessment_id", "type", "measure", "fleet", "survey",
  "region", "season", "year", "age")
row_key <- function(x) do.call(paste, c(x[key_columns], sep = "|"))
expected_keys <- row_key(expected_inputs)
existing_keys <- row_key(existing_inputs)
if (anyDuplicated(expected_keys) || anyDuplicated(existing_keys) ||
    any(!existing_keys %in% expected_keys)) {
  stop("Existing Pollock Table 1 or Table 5 rows conflict with the official tables.")
}
if (length(existing_keys)) {
  expected_overlap <- expected_inputs[match(existing_keys, expected_keys), , drop = FALSE]
  existing_matrix <- as.matrix(existing_inputs)
  expected_matrix <- as.matrix(expected_overlap)
  existing_matrix[is.na(existing_matrix)] <- ""
  expected_matrix[is.na(expected_matrix)] <- ""
  if (!identical(unname(existing_matrix), unname(expected_matrix))) {
    stop("Existing Pollock Table 1 or Table 5 rows differ from the official tables.")
  }
}
missing <- !expected_keys %in% existing_keys
if (any(missing)) {
  utils::write.table(new_inputs[missing, , drop = FALSE], input_path,
    sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
} else {
  message("Pollock Table 1 and Table 5 input rows already match; no duplicate append.")
}

assessments_path <- file.path(root, "database", "assessments.csv")
assessments <- utils::read.csv(assessments_path, stringsAsFactors = FALSE,
  check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L) stop("Expected one 2022 J_M4B assessment row.")
assessments$notes[assessment_row] <- paste(
  "Official Table 1 commercial catch-at-age and Table 5 summer RV",
  "abundance-at-age indices have been transcribed into the input table.",
  "The original PDF binary could not be cached; local table transcriptions",
  "and failed-download access records are documented in the source cache.",
  "Acoustic index and M inputs are also imported; run-specific weights, maturity,",
  "and annual population output matrices remain unavailable."
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
candidates$catch_age_evidence[candidate_row] <- paste(
  "Official Table 1 corrected commercial catch-at-age for ages 2-13 in",
  "1982-2020, in thousands of fish, is imported as 468 source rows."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Official Table 5 summer RV relative-abundance indices for ages 2-13 in",
  "1984-2020 are imported as 444 rows; simulated EGB values are identified",
  "except in 2016, 2017, 2019, and 2020, which use actual EGB indices.",
  "Table 10 adds 51 age-specific acoustic biomass values; the 2020 total conflicts with the total in Part I Table 9, and both reported values are retained."
)
candidates$decision_reason[candidate_row] <- paste(
  "Partial source import now includes tabulated commercial catch-at-age and",
  "summer RV abundance-at-age, acoustic biomass-at-age, and mortality inputs for the 2022 J_M4B model.",
  "The official PDF binaries still cannot be downloaded in this environment;",
  "the cache preserves source-table transcriptions, checksums, and failed",
  "download notices. Run-specific weight, maturity, and annual fitted output series",
  "remain unimported."
)
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)

cat(
  "Verified 468 commercial catch-at-age rows and 444 summer RV index-at-age rows.",
  "The 2022 J_M4B record remains partial."
)
