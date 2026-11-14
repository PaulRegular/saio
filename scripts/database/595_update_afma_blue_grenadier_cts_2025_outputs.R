assessment_id <- "afma_blue_grenadier_cts_2025"
candidate_id <- "AFMA:SESSF_CTS_Blue_Grenadier"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

manifest <- read_table("provenance/afma_blue_grenadier_cts_2025_sources.csv")
source_files <- file.path("source_cache", manifest$local_file)
if (any(!file.exists(source_files))) {
  stop("Cached AFMA source documents are required before updating this record.",
    call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, toupper(manifest$sha256))) {
  stop("A cached AFMA source document does not match its recorded SHA-256 checksum.",
    call. = FALSE)
}

outputs <- data.frame(
  assessment_id = assessment_id,
  type = c(
    "biomass", "parameter", "parameter",
    rep("management", 4), rep("catch", 4),
    "management", "management", "management", "catch"
  ),
  measure = c(
    "unfished_spawning_biomass",
    "natural_mortality_average_parameter",
    "natural_mortality_average_parameter",
    rep("recommended_biological_catch", 4),
    rep("estimated_discards", 4),
    "tier_2_discount_factor", "provisional_TAC",
    "long_term_recommended_biological_catch",
    "long_term_estimated_discards"
  ),
  fleet = "",
  survey = "",
  sex = c("female", "female", "male", rep("", 12)),
  region = "Commonwealth Trawl Sector",
  season = "",
  year = c(NA, NA, NA, 2026, 2027, 2028, NA, 2026, 2027, 2028, NA, NA, 2026, NA, NA),
  age = "",
  age_group = "",
  value = c(42626, 0.238, 0.248, 17744, 15459, 13727, 15643,
    218, 209, 205, 211, 782, 14650, 8300, 185),
  se = "",
  lwr = "",
  upr = "",
  unit = c(
    "tonnes", "per year", "per year",
    rep("tonnes including estimated discards", 4),
    rep("tonnes", 8)
  ),
  source_type = c(
    "official_document", "official_table", "official_table",
    rep("official_table", 10), "official_document", "official_document"
  ),
  source_reference = c(
    "AFMA 2026 SESSF Species Summaries, p. 115, Blue Grenadier assessment summary",
    rep("AFMA 2026 SESSF Species Summaries, p. 115, Blue Grenadier assessment summary", 14)
  ),
  notes = c(
    "2025 preliminary base-case estimate of virgin female spawning biomass B0. No uncertainty interval is reported.",
    "Base-case estimated female natural-mortality parameter. The summary does not state its age or time structure and gives no uncertainty.",
    "Base-case estimated male natural-mortality parameter. The summary does not state its age or time structure and gives no uncertainty.",
    "Annual RBC before the Tier 2 discount; includes estimated discards. The 2026 value applies to the 2026-27 SESSF season.",
    "Annual RBC before the Tier 2 discount; includes estimated discards. The 2027 value applies to the 2027-28 SESSF season.",
    "Annual RBC before the Tier 2 discount; includes estimated discards. The 2028 value applies to the 2028-29 SESSF season.",
    "Source-reported three-year average RBC for the 2026-27 to 2028-29 seasons, before the Tier 2 discount.",
    "Model-estimated discards included in the 2026 RBC.",
    "Model-estimated discards included in the 2027 RBC.",
    "Model-estimated discards included in the 2028 RBC.",
    "Source-reported average estimated discards over the three-year RBC period.",
    "Five-percent Tier 2 discount applied to the three-year average RBC.",
    "Provisional 2026-27 TAC under the harvest strategy, after the Tier 2 discount and estimated discards are deducted.",
    "Approximate long-term RBC under average recruitment; the source reports approximately 8,300 tonnes, including 185 tonnes of discards.",
    "Long-term model-estimated discards reported with the approximate long-term RBC."
  ),
  scenario = c(
    "2025 preliminary base case", "2025 preliminary base case", "2025 preliminary base case",
    rep("2026-27 to 2028-29 Tier 2 advice", 9),
    "2026-27 Tier 2 advice",
    "Long-term average recruitment", "Long-term average recruitment"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
outputs[] <- lapply(outputs, as.character)
outputs[is.na(outputs)] <- ""

read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

output_key_fields <- c("assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "scenario")
row_keys <- function(rows) {
  do.call(paste, c(lapply(rows[output_key_fields], function(x) {
    ifelse(is.na(x), "", x)
  }), sep = "\r"))
}
existing_outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
existing_keys <- row_keys(existing_outputs)
if (anyDuplicated(existing_keys)) {
  stop("Duplicate output keys already exist for the AFMA assessment.", call. = FALSE)
}
new_keys <- row_keys(outputs)
if (anyDuplicated(new_keys)) {
  stop("The proposed AFMA outputs contain duplicate keys.", call. = FALSE)
}

outputs_to_add <- outputs[!new_keys %in% existing_keys, , drop = FALSE]
already_present <- match(new_keys, existing_keys)
for (i in which(!is.na(already_present))) {
  existing <- existing_outputs[already_present[i], names(outputs), drop = FALSE]
  existing[] <- lapply(existing, function(x) ifelse(is.na(x), "", x))
  if (!identical(unlist(existing[1L, ], use.names = FALSE),
    unlist(outputs[i, ], use.names = FALSE))) {
    stop("An existing AFMA output key has different source values.", call. = FALSE)
  }
}

append_rows <- function(path, rows) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  rows <- rows[, fields, drop = FALSE]
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, na = "", qmethod = "double")
}

replace_csv_record <- function(path, key_fields, key_values, row) {
  table <- read_table(path)
  if (!identical(names(row), names(table)) || nrow(row) != 1L) {
    stop("Replacement row does not match the CSV schema.", call. = FALSE)
  }
  matches <- rep(TRUE, nrow(table))
  for (i in seq_along(key_fields)) {
    values <- table[[key_fields[i]]]
    values[is.na(values)] <- ""
    matches <- matches & values == key_values[i]
  }
  record_index <- which(matches)
  if (length(record_index) != 1L) {
    stop("Expected exactly one CSV record to update.", call. = FALSE)
  }

  row_connection <- textConnection("serialized_row", open = "w", local = TRUE)
  write.table(row, row_connection, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "")
  close(row_connection)
  if (length(serialized_row) != 1L || grepl("[\r\n]", serialized_row)) {
    stop("The replacement record must fit on one CSV line.", call. = FALSE)
  }

  if (key_fields[1L] != names(table)[1L]) {
    stop("The CSV replacement key must begin with the first column.", call. = FALSE)
  }
  connection <- file(path, open = "rb")
  file_bytes <- readBin(connection, what = "raw", n = file.info(path)$size)
  close(connection)
  byte_values <- as.integer(file_bytes)
  line_starts <- c(1L, which(byte_values == 10L) + 1L)
  line_starts <- line_starts[line_starts <= length(byte_values)]
  prefix_bytes <- charToRaw(paste0('"', key_values[1L], '",'))
  prefix_length <- length(prefix_bytes)
  possible_starts <- line_starts[vapply(line_starts, function(start) {
    end <- start + prefix_length - 1L
    end <= length(file_bytes) &&
      identical(file_bytes[start:end], prefix_bytes)
  }, logical(1))]
  record_matches <- list()
  for (start in possible_starts) {
    in_quotes <- FALSE
    i <- start
    while (i <= length(byte_values)) {
      if (byte_values[i] == 34L) {
        if (in_quotes && i < length(byte_values) && byte_values[i + 1L] == 34L) {
          i <- i + 2L
        } else {
          in_quotes <- !in_quotes
          i <- i + 1L
        }
      } else if (byte_values[i] == 10L && !in_quotes) {
        break
      } else {
        i <- i + 1L
      }
    }
    end <- if (i <= length(byte_values)) i - 1L else length(byte_values)
    if (end >= start && identical(file_bytes[end], as.raw(13L))) end <- end - 1L
    row_text <- rawToChar(file_bytes[start:end])
    parsed_row <- read.csv(text = row_text, header = FALSE,
      col.names = names(table), stringsAsFactors = FALSE,
      colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
    matches <- rep(nrow(parsed_row) == 1L, nrow(parsed_row))
    for (j in seq_along(key_fields)) {
      values <- parsed_row[[key_fields[j]]]
      values[is.na(values)] <- ""
      matches <- matches & values == key_values[j]
    }
    if (length(matches) == 1L && matches) {
      record_matches[[length(record_matches) + 1L]] <- list(start = start, end = end)
    }
  }
  if (length(record_matches) != 1L) {
    stop("Expected exactly one matching CSV record boundary.", call. = FALSE)
  }
  start <- record_matches[[1L]]$start
  end <- record_matches[[1L]]$end
  prefix <- if (start > 1L) file_bytes[seq_len(start - 1L)] else raw()
  suffix_start <- end + 1L
  suffix <- if (suffix_start <= length(file_bytes)) {
    file_bytes[seq.int(suffix_start, length(file_bytes))]
  } else {
    raw()
  }
  connection <- file(path, open = "wb")
  writeBin(c(prefix, charToRaw(enc2utf8(serialized_row)), suffix), connection)
  close(connection)
}

assumptions <- read_table("database/assumptions.csv")
assumption_updates <- list(
  list(
    setting = "model_family_and_version",
    value = "Two-sex age-structured assessment; software family and version unknown.",
    source_reference = "AFMA 2026 SESSF Species Summaries, pp. 114-115",
    notes = "The summary identifies a two-sex age-structured base case but no software version. Page 114 labels the assessment Tier 1; page 115 says SERAG recommended Tier 2 and applied a 5% RBC discount after retrospective patterns were noted."
  ),
  list(
    setting = "natural_mortality",
    value = "Estimated separately by sex; see reported female and male parameter estimates.",
    source_reference = "AFMA 2026 SESSF Species Summaries, p. 115",
    notes = "The summary does not state the age or time structure or report uncertainty. Point estimates are stored as assessment outputs."
  ),
  list(
    setting = "weights_and_maturity",
    value = "Female length at 50% maturity is 63.7 cm; weight-at-age is not reported.",
    source_reference = "AFMA 2026 SESSF Species Summaries, p. 115",
    notes = "The summary does not provide a complete maturity-at-age surface or current-run weight-at-age values."
  )
)
new_assumptions <- data.frame(
  assessment_id = assessment_id,
  component = c("stock_recruitment", "recruitment", "biology"),
  fleet = "",
  survey = "",
  sex = c("", "", "female"),
  region = "",
  season = "",
  setting = c("steepness", "estimated_recruitment_years", "length_at_50_percent_maturity"),
  value = c("0.75 (fixed)", "1974-2019", "63.7 cm"),
  source_reference = rep("AFMA 2026 SESSF Species Summaries, p. 115", 3),
  notes = c(
    "Fixed stock-recruitment steepness reported for the 2025 base case.",
    "Years for which recruitment was estimated in the 2025 base case.",
    "Female length at 50% maturity; this is a length-based setting, not an age-specific maturity vector."
  ),
  stringsAsFactors = FALSE
)

assumption_key <- function(setting) {
  which(assumptions$assessment_id == assessment_id &
    assumptions$setting == setting)
}
assumptions_to_add <- new_assumptions
assumption_already_present <- rep(FALSE, nrow(new_assumptions))
for (update in assumption_updates) {
  i <- assumption_key(update$setting)
  if (length(i) != 1L) stop("Expected one existing AFMA assumption row: ", update$setting, call. = FALSE)
  row <- assumptions[i, , drop = FALSE]
  row$value <- update$value
  row$source_reference <- update$source_reference
  row$notes <- update$notes
  assumptions[i, ] <- row
}
for (i in seq_len(nrow(new_assumptions))) {
  found <- assumption_key(new_assumptions$setting[i])
  if (length(found)) {
    expected <- new_assumptions[i, names(assumptions), drop = FALSE]
    existing <- assumptions[found, names(assumptions), drop = FALSE]
    existing[] <- lapply(existing, function(x) ifelse(is.na(x), "", x))
    expected[] <- lapply(expected, function(x) ifelse(is.na(x), "", x))
    if (length(found) != 1L || !identical(
      unlist(existing[1L, ], use.names = FALSE),
      unlist(expected[1L, ], use.names = FALSE))) {
      stop("A new AFMA assumption key already exists with different values.",
        call. = FALSE)
    }
    assumption_already_present[i] <- TRUE
  }
}
assumptions_to_add <- new_assumptions[!assumption_already_present, , drop = FALSE]

assessment_table <- read_table("database/assessments.csv")
assessment_row <- which(assessment_table$assessment_id == assessment_id)
if (length(assessment_row) != 1L) stop("Expected one AFMA assessment row.", call. = FALSE)
assessment_notes <- paste(
  "The 2025 tuned base case is the latest assessment update, with catch and age data through 2024.",
  "Public sources report selected biomass, sex-specific M, and RBC outputs but no numerical observation arrays or native current-run files.",
  "The 2026 summary labels the run Tier 1 on page 114 but reports a SERAG Tier 2 recommendation and 5% RBC discount on page 115."
)
assessment_table$notes[assessment_row] <- assessment_notes

candidates <- read_table("discovery/candidates.csv")
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected exactly one AFMA candidate row.", call. = FALSE)
candidates$mortality_evidence[candidate_row] <- paste(
  "The 2026 summary reports estimated base-case M of 0.238 per year for females and 0.248 for males.",
  "It does not state the age/time structure or uncertainty."
)
candidates$output_evidence[candidate_row] <- paste(
  "The 2025 run has reported B0, historical and projected SSB/B0 ratios, sex-specific M estimates,",
  "and 2026-2028 RBC and discard projections. Annual age-specific N/F/M outputs and observation arrays remain unavailable."
)
candidates$decision_reason[candidate_row] <- paste(
  "The 2025 current-unit update remains partial. Eligibility is unresolved because the public sources do not provide numerical catch-age arrays or enough age-composition data to establish faithful reconstruction."
)
candidates$review_date[candidate_row] <- "2026-11-07"

if (write_mode) {
  if (nrow(outputs_to_add)) append_rows("database/outputs.csv", outputs_to_add)
  if (nrow(assumptions_to_add)) append_rows("database/assumptions.csv", assumptions_to_add)
  for (update in assumption_updates) {
    updated <- read_table("database/assumptions.csv")
    index <- which(updated$assessment_id == assessment_id &
      updated$setting == update$setting)
    row <- updated[index, , drop = FALSE]
    row$value <- update$value
    row$source_reference <- update$source_reference
    row$notes <- update$notes
    replace_csv_record("database/assumptions.csv",
      c("assessment_id", "setting"), c(assessment_id, update$setting), row)
  }
  replace_csv_record("database/assessments.csv", "assessment_id",
    assessment_id, assessment_table[assessment_row, , drop = FALSE])
  replace_csv_record("discovery/candidates.csv", "candidate_id",
    candidate_id, candidates[candidate_row, , drop = FALSE])
  cat("Updated AFMA Blue Grenadier 2025 outputs and source notes.\n")
} else {
  cat("Preflight passed:", nrow(outputs_to_add), "new output rows and",
    nrow(assumptions_to_add), "new assumption rows. Pass --write to update.\n")
}
