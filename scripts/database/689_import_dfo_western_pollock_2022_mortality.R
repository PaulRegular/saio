root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

stock_id <- "dfo_western_component_pollock_4xopqrs5"
assessment_id <- "dfo_western_component_pollock_2022_j_m4b"
candidate_id <- "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)"
source_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-029-eng.pdf"
source_file_name <- "dfo_western_pollock_2026_029_table12_mortality_m4b.csv"
cache_options <- c(
  file.path(root, "source_cache", "discovery_dfo_western_pollock_2022"),
  file.path("..", "..", "discovery_dfo_western_pollock_2022")
)
cache_dirs <- cache_options[dir.exists(cache_options)]
cache_dir <- cache_dirs[vapply(cache_dirs, function(path) {
  file.exists(file.path(path, source_file_name))
}, logical(1L))][1L]
if (is.na(cache_dir)) stop("The local Table 12 transcription is missing.")
source_file <- file.path(cache_dir, source_file_name)
source_table <- utils::read.csv(source_file, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
expected_columns <- c("model", "year_start", "year_end", "age_start", "age_end",
  "estimate", "relative_error", "relative_bias", "source_note")
expected <- data.frame(
  model = rep("Model F M4B / Model J M4B", 5L),
  year_start = c(1982L, 1994L, 1994L, 2001L, 2011L),
  year_end = c(1993L, 2020L, 2000L, 2010L, 2020L),
  age_start = c(2L, 2L, 5L, 5L, 5L),
  age_end = c(13L, 4L, 13L, 13L, 13L),
  estimate = c(.2, .2, .661, .587, .341),
  relative_error = c(NA, NA, .184, .141, .212),
  relative_bias = c(NA, NA, -.013, -.006, -.016),
  source_note = c(
    "Fixed M before the 1994 estimated-M periods.",
    "M fixed at 0.2 for ages 2-4.",
    "Model F M4B estimated M; same matrix used as fixed input in Model J M4B.",
    "Model F M4B estimated M; same matrix used as fixed input in Model J M4B.",
    "Model F M4B estimated M; same matrix used as fixed input in Model J M4B."
  ),
  stringsAsFactors = FALSE
)
if (!identical(names(source_table), expected_columns) ||
    !isTRUE(all.equal(source_table, expected, check.attributes = FALSE))) {
  stop("The cached Table 12 transcription does not match the reviewed values.")
}

block_rows <- lapply(seq_len(nrow(source_table)), function(i) {
  row <- source_table[i, , drop = FALSE]
  out <- expand.grid(
    year = as.integer(row$year_start):as.integer(row$year_end),
    age = as.integer(row$age_start):as.integer(row$age_end),
    KEEP.OUT.ATTRS = FALSE
  )
  out$value <- as.numeric(row$estimate)
  if (is.na(row$relative_error)) {
    out$notes <- paste(row$source_note,
      "Model specification and Figure 32 show fixed M=0.2; no SE is reported for fixed values.")
  } else {
    out$notes <- paste0(
      row$source_note, " Reported estimate=", format(row$estimate, nsmall = 3L),
      "; relative error=", format(row$relative_error, nsmall = 3L),
      "; relative bias=", format(row$relative_bias, nsmall = 3L),
      ". Values are kept at the report's published precision."
    )
  }
  out
})
matrix <- do.call(rbind, block_rows)
matrix <- matrix[order(matrix$age, matrix$year), , drop = FALSE]
rownames(matrix) <- NULL
expected_cells <- expand.grid(year = 1982:2020, age = 2:13,
  KEEP.OUT.ATTRS = FALSE)
if (nrow(matrix) != 468L || anyDuplicated(matrix[c("year", "age")]) ||
    !identical(matrix[c("year", "age")], expected_cells) ||
    any(!is.finite(matrix$value)) || any(matrix$value <= 0)) {
  stop("The expanded Model J_M4B M matrix is incomplete or overlapping.")
}

source_reference <- paste(
  source_url,
  "Model F parameterization and Model J description; Table 12, printed p. 44; Figure 32, printed p. 69",
  sep = "; "
)
inputs <- pacific_database_row("inputs", n = nrow(matrix),
  assessment_id = assessment_id,
  type = "M", measure = "natural_mortality_at_age", basis = "per_year",
  region = "4Xopqrs5Yb5Zc", year = matrix$year,
  year_basis = "calendar_year", age = matrix$age, value = matrix$value,
  unit = "per year", source_type = "official_table",
  source_reference = source_reference,
  transformation = paste(
    "Expanded the published Model F M4B year and age blocks to the fixed",
    "natural-mortality input matrix used by the selected Model J_M4B run.",
    "M values remain at their published precision; no interpolation was applied."
  ),
  notes = matrix$notes
)

input_path <- file.path(root, "database", "inputs.csv")
header <- readLines(input_path, n = 1L, warn = FALSE)
con <- file(input_path, open = "r")
readLines(con, n = 1L, warn = FALSE)
existing_lines <- character()
repeat {
  chunk <- readLines(con, n = 50000L, warn = FALSE)
  if (!length(chunk)) break
  target <- startsWith(chunk, paste0("\"", assessment_id, "\","))
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
  existing <- existing[existing$type == "M" &
    existing$measure == "natural_mortality_at_age", , drop = FALSE]
  rownames(existing) <- NULL
} else {
  existing <- utils::read.csv(text = header, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character())
}
expected_inputs <- as_character_table(inputs)
existing <- existing[, names(expected_inputs), drop = FALSE]
key_columns <- c("assessment_id", "type", "measure", "region", "year", "age")
row_key <- function(x) do.call(paste, c(x[key_columns], sep = "|"))
expected_keys <- row_key(expected_inputs)
existing_keys <- row_key(existing)
if (anyDuplicated(expected_keys) || anyDuplicated(existing_keys) ||
    any(!existing_keys %in% expected_keys)) {
  stop("Existing Pollock mortality inputs conflict with Table 12.")
}
if (length(existing_keys)) {
  expected_overlap <- expected_inputs[match(existing_keys, expected_keys), , drop = FALSE]
  existing_matrix <- as.matrix(existing)
  expected_matrix <- as.matrix(expected_overlap)
  existing_matrix[is.na(existing_matrix)] <- ""
  expected_matrix[is.na(expected_matrix)] <- ""
  if (!identical(unname(existing_matrix), unname(expected_matrix))) {
    stop("Existing Pollock mortality rows differ from the Table 12 reconstruction.")
  }
}
missing <- !expected_keys %in% existing_keys
if (any(missing)) {
  utils::write.table(inputs[missing, , drop = FALSE], input_path,
    sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

manifest_path <- file.path(cache_dir, "sources.csv")
manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE)
if (!source_file_name %in% manifest$file) {
  manifest <- rbind(manifest, data.frame(
    file = source_file_name,
    source_url = source_url,
    retrieved_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    repository_revision = "DFO CSAS Research Document 2026/029, Model F and J descriptions, Table 12, Figure 32",
    sha256 = unname(tools::sha256sum(source_file)),
    bytes = file.info(source_file)$size,
    notes = paste(
      "Local transcription of the official searchable PDF, not the original PDF binary.",
      "Table 12 M4B estimates were transcribed at their reported precision; text",
      "documents that Model J uses the Model F M matrix as fixed input."
    ),
    stringsAsFactors = FALSE
  ))
  utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")
}

assessments_path <- file.path(root, "database", "assessments.csv")
assessments <- utils::read.csv(assessments_path, stringsAsFactors = FALSE,
  check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L ||
    assessments$stock_id[assessment_row] != stock_id) {
  stop("Expected the current Western Component Pollock J_M4B assessment row.")
}
assessments$notes[assessment_row] <- paste(
  "Tables 1 and 5 provide commercial catch-at-age and summer RV abundance-at-age; Table 10 provides the age-specific acoustic biomass index.",
  "Table 12 reports Model F M4B estimates, and the report states these same M blocks are fixed inputs in selected Model J_M4B.",
  "The annual M matrix is expanded at the report's precision; weights-at-age, maturity-at-age, and annual fitted population surfaces remain unavailable.",
  "In 2020, Table 10 age values sum to 38,407 mt while its total is 38,061 mt; Part I Table 9 reports 38,408 mt. Published values are preserved without adjustment.",
  "Local transcriptions and access records are checksummed in the ignored cache; original report PDFs were not retrieved locally."
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
candidates$mortality_evidence[candidate_row] <- paste(
  "Model F M4B estimates M=0.661 (1994-2000), 0.587 (2001-2010), and 0.341 (2011-2020) for ages 5-13; ages 2-4 and pre-1994 M are fixed at 0.2.",
  "The report states Model J_M4B uses the same M matrix; 468 year-age input rows are stored at published precision."
)
candidates$decision_reason[candidate_row] <- paste(
  "Partial source import includes commercial catch-at-age, summer RV abundance-at-age, acoustic biomass-at-age, and the selected Model J_M4B natural-mortality input matrix.",
  "The 2020 acoustic table has conflicting published total values across the two research documents; all values are retained without adjustment.",
  "Run-specific weights, maturity, and annual population output surfaces remain unavailable; source-data status stays partial."
)
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)

if (any(missing)) {
  cat(sprintf("Appended %d Model J_M4B mortality-input rows; the assessment remains partial.\n", sum(missing)))
} else {
  cat("All Model J_M4B mortality-input rows already match; nothing was appended.\n")
}
