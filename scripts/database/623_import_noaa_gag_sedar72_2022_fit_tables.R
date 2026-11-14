root <- "."
cache_name <- "noaa_gag_sedar72_2022"
cache_candidates <- c(
  file.path(root, "source_cache", cache_name),
  file.path(root, "..", "..", cache_name)
)
cache_dir <- cache_candidates[dir.exists(cache_candidates)][1L]
manifest_path <- file.path("provenance", cache_name, "manifest.csv")
assessment_id <- "noaa_gag_gulf_sedar72_srfs_2022"
candidate_id <- "NOAA:10348"
stock_id <- "noaa_gag_gulf"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

if (is.na(cache_dir) || !length(cache_dir)) {
  stop("Could not find the gitignored SEDAR 72 source cache.", call. = FALSE)
}
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
source_name <- "sedar72_srfs_amendment_2022.pdf"
source_row <- manifest[basename(manifest$file) == source_name, , drop = FALSE]
pdf_path <- file.path(cache_dir, source_name)
sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
      output, value = TRUE)))
  } else {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hashes <- sub("[[:space:]].*$", "", output[1L])
  }
  if (length(hashes) != 1L) stop("Could not calculate source SHA-256.", call. = FALSE)
  hashes
}
if (nrow(source_row) != 1L || !file.exists(pdf_path) ||
    as.numeric(source_row$bytes) != file.info(pdf_path)$size ||
    !identical(sha256_file(pdf_path), tolower(source_row$sha256))) {
  stop("Cached SEDAR 72 amendment does not match its provenance record.", call. = FALSE)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached SEDAR 72 tables.", call. = FALSE)
}
pages <- pdftools::pdf_text(pdf_path)

table_markers <- c(
  "Table 10. Input (with log-scale standard errors, SE) and expected (Exp) landings for the",
  "Table 11. Input (with log-scale standard errors, SE) and expected (Exp) landings for the",
  "Table 12. Input (with log-scale standard errors, SE) and expected (Exp) landings for the",
  "Table 13. Input (with log-scale standard errors, SE) and expected (Exp) landings for the",
  "Table 14. Input (with log-scale standard errors, SE) and expected (Exp) landings for the",
  "Table 15. Input (with log-scale standard errors, SE) and expected (Exp) discards for the",
  "Table 16. Input (with log-scale standard errors, SE) and expected (Exp) discards for the",
  "Table 17. Input (with log-scale standard errors, SE) and expected (Exp) discards for the",
  "Table 18. Input (with log-scale standard errors, SE) and expected (Exp) discards for the",
  "Table 19. Input (with log-scale standard errors, SE) and expected (Exp) discards for the",
  "Table 20. Observed (Obs) versus predicted (Exp) standardized fishery-dependent",
  "Table 21. Observed (Obs) versus predicted (Exp) standardized fishery-independent"
)
table_starts <- vapply(table_markers, function(marker) {
  hits <- which(vapply(pages, function(page) grepl(marker, page, fixed = TRUE),
    logical(1L)))
  if (length(hits) != 1L) stop("Could not uniquely locate ", marker, call. = FALSE)
  hits
}, integer(1L))

table_page_lines <- function(index) {
  first_page <- table_starts[index]
  last_page <- if (index < length(table_starts)) table_starts[index + 1L] - 1L else first_page
  lines <- trimws(unlist(strsplit(paste(pages[first_page:last_page], collapse = "\n"), "\n")))
  lines[grepl("^(19|20)[0-9]{2}[[:space:]]+", lines)]
}
parse_values <- function(tokens, year) {
  values <- suppressWarnings(as.numeric(gsub("[,*]", "", tokens[-1L])))
  if (anyNA(values)) stop("Could not parse table row for year ", year, call. = FALSE)
  values
}
parse_sequential_table <- function(index, years, slot_names) {
  lines <- table_page_lines(index)
  if (length(lines) != length(years)) stop("Unexpected year count in SEDAR 72 Table ", index + 9L)
  rows <- lapply(lines, function(line) {
    positions <- gregexpr("[^[:space:]]+", line, perl = TRUE)[[1L]]
    tokens <- regmatches(line, list(positions))[[1L]]
    year <- as.integer(tokens[1L])
    values <- parse_values(tokens, year)
    if (length(values) != length(slot_names)) {
      stop("Unexpected columns in SEDAR 72 Table ", index + 9L, ", year ", year)
    }
    as.list(setNames(c(year, values), c("year", slot_names)))
  })
  out <- as.data.frame(do.call(rbind, lapply(rows, as.data.frame)),
    check.names = FALSE)
  out$year <- as.integer(out$year)
  if (!identical(out$year, years)) stop("Unexpected years in SEDAR 72 Table ", index + 9L)
  out
}
parse_position_table <- function(index, years, slot_names, reference_positions) {
  lines <- table_page_lines(index)
  if (length(lines) != length(years)) stop("Unexpected year count in SEDAR 72 Table ", index + 9L)
  rows <- lapply(lines, function(line) {
    positions <- gregexpr("[^[:space:]]+", line, perl = TRUE)[[1L]]
    tokens <- regmatches(line, list(positions))[[1L]]
    year <- as.integer(tokens[1L])
    values <- rep(NA_real_, length(slot_names))
    if (length(tokens) > 1L) {
      for (j in seq.int(2L, length(tokens))) {
        slot <- which.min(abs(reference_positions - positions[j]))
        if (!is.na(values[slot])) stop("Duplicate column in SEDAR 72 Table ", index + 9L, ", year ", year)
        value <- suppressWarnings(as.numeric(gsub("[,*]", "", tokens[j])))
        if (!is.finite(value)) stop("Could not parse SEDAR 72 Table ", index + 9L, ", year ", year)
        values[slot] <- value
      }
    }
    as.list(setNames(c(year, values), c("year", slot_names)))
  })
  out <- as.data.frame(do.call(rbind, lapply(rows, as.data.frame)),
    check.names = FALSE)
  out$year <- as.integer(out$year)
  if (!identical(out$year, years)) stop("Unexpected years in SEDAR 72 Table ", index + 9L)
  out
}

table10 <- parse_sequential_table(1L, 1963:2019,
  c("input_sd", "input", "expected_biomass", "expected_numbers", "mean_weight"))
table11 <- parse_sequential_table(2L, 1979:2019,
  c("input_sd", "input", "expected_biomass", "expected_numbers", "mean_weight"))
table12 <- parse_sequential_table(3L, 1963:2019,
  c("input_sd", "input", "expected_numbers", "expected_biomass", "mean_weight"))
table13 <- parse_sequential_table(4L, 1963:2019,
  c("input_sd", "input", "expected_numbers", "expected_biomass", "mean_weight"))
table14 <- parse_sequential_table(5L, 1963:2019,
  c("input_sd", "input", "expected_numbers", "expected_biomass", "mean_weight"))

discard_slots <- c("input_sd", "input", "expected_numbers", "expected_dead_numbers",
  "expected_biomass", "expected_dead_biomass", "mean_weight")
table15 <- parse_position_table(6L, 1963:2019, discard_slots,
  c(15, 23, 34, 50, 60, 76, 87))
table16 <- parse_position_table(7L, 1979:2019, discard_slots,
  c(15, 24, 34, 50, 60, 75, 86))
table17 <- parse_position_table(8L, 1963:2019, discard_slots,
  c(13, 23, 33, 50, 60, 76, 87))
table18 <- parse_position_table(9L, 1963:2019, discard_slots,
  c(13, 24, 34, 50, 61, 77, 89))
table19 <- parse_position_table(10L, 1963:2019, discard_slots,
  c(14, 24, 34, 51, 59, 76, 85))

table20_slots <- c("vl_obs", "vl_exp", "vl_se", "ll_obs", "ll_exp", "ll_se",
  "headboat_obs", "headboat_exp", "headboat_se", "charter_private_obs",
  "charter_private_exp", "charter_private_se")
table20 <- parse_position_table(11L, 1986:2019, table20_slots,
  c(9, 17, 24, 32, 39, 46, 54, 61, 69, 77, 84, 91))
table21_slots <- c("age0_obs", "age0_exp", "age0_se", "seamap_obs", "seamap_exp",
  "seamap_se", "pc_video_obs", "pc_video_exp", "pc_video_se")
table21 <- parse_position_table(12L, 1993:2019, table21_slots,
  c(8, 16, 24, 35, 49, 60, 68, 78, 86))
row_at <- function(data, year) data[data$year == year, , drop = FALSE]
stopifnot(
  row_at(table10, 1963)$input == 1.635,
  row_at(table10, 1963)$expected_biomass == 1.637,
  row_at(table10, 1963)$expected_numbers == 87.144,
  row_at(table11, 1979)$input == 0.001,
  is.na(row_at(table15, 1981)$input_sd),
  is.na(row_at(table15, 1981)$input),
  row_at(table15, 2019)$input_sd == 0.25,
  row_at(table15, 2019)$input == 20.621,
  row_at(table15, 2019)$expected_dead_numbers == 5.015,
  row_at(table16, 2019)$input == 6.193,
  row_at(table20, 1990)$vl_obs == 0.31,
  row_at(table20, 1990)$vl_exp == 1.18,
  row_at(table20, 1990)$vl_se == 0.63,
  row_at(table20, 1990)$charter_private_obs == 0.72,
  row_at(table21, 2019)$age0_obs == 0.595,
  row_at(table21, 2019)$seamap_exp == 0.389,
  row_at(table21, 2019)$pc_video_obs == 1.383
)

input_rows <- list()
output_rows <- list()
add_input <- function(measure, basis, fleet, survey, year, value, unit, partition,
                      reference_table, notes, age = NA_integer_) {
  out <- pacific_database_row("inputs", n = length(value))
  out$assessment_id <- assessment_id
  out$type <- if (measure %in% c("relative_abundance_index", "log_index_sd")) "index" else "catch"
  out$measure <- measure
  out$basis <- basis
  out$fleet <- rep_len(fleet, length(value))
  out$survey <- rep_len(survey, length(value))
  out$year <- as.integer(year)
  out$year_basis <- "calendar_year"
  out$age <- rep_len(age, length(value))
  out$value <- as.numeric(value)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- paste0("SEDAR72_SRFS_Amendment_2022.pdf, Table ", reference_table)
  out$partition <- partition
  out$notes <- notes
  input_rows[[length(input_rows) + 1L]] <<- out
  invisible(out)
}
add_output <- function(type, measure, fleet, survey, year, value, unit,
                       reference_table, notes, age = NA_integer_) {
  out <- pacific_database_row("outputs", n = length(value))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$fleet <- rep_len(fleet, length(value))
  out$survey <- rep_len(survey, length(value))
  out$year <- as.integer(year)
  out$age <- rep_len(age, length(value))
  out$value <- as.numeric(value)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- paste0("SEDAR72_SRFS_Amendment_2022.pdf, Table ", reference_table)
  out$notes <- rep_len(notes, length(value))
  output_rows[[length(output_rows) + 1L]] <<- out
  invisible(out)
}

add_landings_table <- function(data, fleet, table, input_unit, biomass_unit,
                               number_unit, weight_unit, input_measure, input_basis) {
  add_input(input_measure, input_basis, fleet, NA_character_, data$year,
    data$input, input_unit, "landings", table,
    "Assessment landings input, transcribed at the precision printed in the table.")
  add_input("log_catch_sd", "log_scale", fleet, NA_character_, data$year,
    data$input_sd, "log-scale standard error", "landings", table,
    "Source-reported standard error on log landings, retained as printed.")
  add_output("catch", "expected_landings_biomass", fleet, NA_character_, data$year,
    data$expected_biomass, biomass_unit, table,
    "Model-predicted landings biomass reported in the source table.")
  add_output("catch", "expected_landings_numbers", fleet, NA_character_, data$year,
    data$expected_numbers, number_unit, table,
    "Model-predicted landings numbers reported in the source table.")
  add_output("biology", "mean_landings_weight", fleet, NA_character_, data$year,
    data$mean_weight, weight_unit, table,
    "Mean body weight computed by the source assessment from expected biomass and numbers.")
}
add_discard_table <- function(data, fleet, table, include_inputs, input_unit,
                              biomass_unit, number_unit, weight_unit) {
  if (include_inputs) {
    has_input <- is.finite(data$input) & is.finite(data$input_sd)
    if (any(is.finite(data$input) != is.finite(data$input_sd))) {
      stop("Discard input and log-scale error coverage differ in Table ", table, ".")
    }
    add_input("discard_numbers", "numbers", fleet, NA_character_, data$year[has_input],
      data$input[has_input], input_unit, "discards", table,
      "Assessment discard input before applying discard mortality; transcribed at printed precision.")
    add_input("log_catch_sd", "log_scale", fleet, NA_character_, data$year[has_input],
      data$input_sd[has_input], "log-scale standard error", "discards", table,
      "Source-reported standard error on log discards, retained as printed.")
  }
  add_output("catch", "expected_discard_numbers", fleet, NA_character_, data$year,
    data$expected_numbers, number_unit, table,
    "Model-predicted total discards before discard mortality.")
  add_output("catch", "expected_dead_discard_numbers", fleet, NA_character_, data$year,
    data$expected_dead_numbers, number_unit, table,
    "Model-predicted dead discards after the source fleet-specific discard-mortality rate.")
  add_output("catch", "expected_discard_biomass", fleet, NA_character_, data$year,
    data$expected_biomass, biomass_unit, table,
    "Model-predicted discard biomass before discard mortality.")
  add_output("catch", "expected_dead_discard_biomass", fleet, NA_character_, data$year,
    data$expected_dead_biomass, biomass_unit, table,
    "Model-predicted dead-discard biomass after the source fleet-specific discard-mortality rate.")
  add_output("biology", "mean_discard_weight", fleet, NA_character_, data$year,
    data$mean_weight, weight_unit, table,
    "Mean discard body weight computed by the source assessment from expected biomass and numbers.")
}

add_landings_table(table10, "Commercial vertical line + other", 10L,
  "million pounds gutted weight", "million pounds gutted weight", "1000 fish",
  "gutted pounds per fish", "landings_biomass", "biomass")
add_landings_table(table11, "Commercial longline", 11L,
  "million pounds gutted weight", "million pounds gutted weight", "1000 fish",
  "gutted pounds per fish", "landings_biomass", "biomass")

landings_specs <- list(
  list(data = table12, fleet = "Recreational headboat", table = 12L),
  list(data = table13, fleet = "Recreational charter", table = 13L),
  list(data = table14, fleet = "Recreational private + shore", table = 14L)
)
for (spec in landings_specs) {
  add_output("catch", "expected_landings_numbers", spec$fleet, NA_character_,
    spec$data$year, spec$data$expected_numbers, "1000 fish", spec$table,
    "Model-predicted landings numbers reported in the source table.")
  add_output("catch", "expected_landings_biomass", spec$fleet, NA_character_,
    spec$data$year, spec$data$expected_biomass, "million pounds gutted weight", spec$table,
    "Model-predicted landings biomass reported in the source table.")
  add_output("biology", "mean_landings_weight", spec$fleet, NA_character_,
    spec$data$year, spec$data$mean_weight, "gutted pounds per fish", spec$table,
    "Mean body weight computed by the source assessment from expected biomass and numbers.")
}

discard_specs <- list(
  list(data = table15, fleet = "Commercial vertical line + other", table = 15L,
    input = TRUE, input_unit = "1000 fish", biomass_unit = "thousand pounds gutted weight"),
  list(data = table16, fleet = "Commercial longline", table = 16L,
    input = TRUE, input_unit = "1000 fish", biomass_unit = "thousand pounds gutted weight"),
  list(data = table17, fleet = "Recreational headboat", table = 17L,
    input = FALSE, input_unit = "1000 fish", biomass_unit = "thousand pounds gutted weight"),
  list(data = table18, fleet = "Recreational charter", table = 18L,
    input = FALSE, input_unit = "1000 fish", biomass_unit = "thousand pounds gutted weight"),
  list(data = table19, fleet = "Recreational private + shore", table = 19L,
    input = FALSE, input_unit = "1000 fish", biomass_unit = "thousand pounds gutted weight")
)
for (spec in discard_specs) {
  add_discard_table(spec$data, spec$fleet, spec$table, spec$input,
    spec$input_unit, spec$biomass_unit, "1000 fish", "gutted pounds per fish")
}

add_index_rows <- function(data, groups, table, age = NA_integer_) {
  for (group in groups) {
    observed <- data[[paste0(group$key, "_obs")]]
    expected <- data[[paste0(group$key, "_exp")]]
    error <- data[[paste0(group$key, "_se")]]
    present <- is.finite(observed) | is.finite(expected) | is.finite(error)
    if (any(present & !(is.finite(observed) & is.finite(expected) & is.finite(error)))) {
      stop("Incomplete observed/predicted/SE triplet in SEDAR 72 Table ", table,
        " for ", group$label, ".")
    }
    keep <- is.finite(observed)
    if (!any(keep)) next
    add_input("relative_abundance_index", "index_scale", group$fleet,
      group$survey, data$year[keep], observed[keep],
      "relative index normalized to mean", NA_character_, table,
      "Observed standardized index normalized to its mean; retained on the source relative scale.", age)
    add_input("log_index_sd", "log_scale", group$fleet, group$survey,
      data$year[keep], error[keep], "log-scale standard error", NA_character_, table,
      "Source-reported log-scale standard error after the assessment weighting procedure.", age)
    add_output("index", "expected_relative_abundance_index", group$fleet,
      group$survey, data$year[keep], expected[keep],
      "relative index normalized to mean", table,
      "Model-predicted standardized index reported alongside the observed index.", age)
  }
}
table20_groups <- list(
  list(key = "vl", fleet = "Commercial vertical line", survey = NA_character_, label = "vertical line CPUE"),
  list(key = "ll", fleet = "Commercial longline", survey = NA_character_, label = "longline CPUE"),
  list(key = "headboat", fleet = "Recreational headboat", survey = NA_character_, label = "headboat CPUE"),
  list(key = "charter_private", fleet = "Recreational charter + private", survey = NA_character_, label = "charter/private CPUE")
)
table21_groups <- list(
  list(key = "age0", fleet = NA_character_, survey = "Age-0 index", label = "age-0 index"),
  list(key = "seamap", fleet = NA_character_, survey = "SEAMAP video", label = "SEAMAP video index"),
  list(key = "pc_video", fleet = NA_character_, survey = "PC video", label = "Panama City video index")
)
add_index_rows(table20, table20_groups, 20L)
add_index_rows(table21, table21_groups, 21L, age = 0L)

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
input_key <- paste(inputs$measure, inputs$year, inputs$fleet, inputs$survey,
  inputs$age, inputs$partition, sep = "|")
output_key <- paste(outputs$type, outputs$measure, outputs$year, outputs$fleet,
  outputs$survey, outputs$age, sep = "|")
if (nrow(inputs) != 626L || nrow(outputs) != 2313L || any(!is.finite(inputs$value)) ||
    any(!is.finite(outputs$value)) || anyDuplicated(input_key) || anyDuplicated(output_key)) {
  stop("SEDAR 72 fit tables failed finite-value or uniqueness checks.", call. = FALSE)
}

read_assessment_rows <- function(path, id) {
  lines <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(lines, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not read rows from ", path, call. = FALSE)
  prefix <- paste0('"', id, '",')
  lines <- lines[startsWith(lines, prefix)]
  if (!length(lines)) return(data.frame())
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  read.csv(text = paste(lines, collapse = "\n"), header = FALSE,
    col.names = header, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}
existing_inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
existing_outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
existing_input_key <- paste(existing_inputs$measure, existing_inputs$year,
  existing_inputs$fleet, existing_inputs$survey, existing_inputs$age,
  existing_inputs$partition, sep = "|")
existing_output_key <- paste(existing_outputs$type, existing_outputs$measure,
  existing_outputs$year, existing_outputs$fleet, existing_outputs$survey,
  existing_outputs$age, sep = "|")
if (any(input_key %in% existing_input_key) || any(output_key %in% existing_output_key)) {
  stop("One or more SEDAR 72 fit-table rows already exist; refusing duplicate import.", call. = FALSE)
}

assessment_path <- file.path("database", "assessments.csv")
assessments <- read.csv(assessment_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
candidate_path <- file.path("discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(assessment_row) != 1L || length(candidate_row) != 1L ||
    assessments$inputs_status[assessment_row] != "partial" ||
    assessments$outputs_status[assessment_row] != "partial" ||
    candidates$import_status[candidate_row] != "partial") {
  stop("Gulf gag assessment or candidate status differs from this import.", call. = FALSE)
}

if (write_mode) {
  write.table(inputs, file.path("database", "inputs.csv"), sep = ",",
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  write.table(outputs, file.path("database", "outputs.csv"), sep = ",",
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  assessments$notes[assessment_row] <- paste(assessments$notes[assessment_row],
    "SEDAR 72 SRFS amendment Tables 10-21 add commercial landings/discard inputs, standardized fishery and survey index observations with reported errors, and fitted expected catch/index tables.")
  replace_csv_register_row(assessment_path, assessment_row,
    assessments[assessment_row, , drop = FALSE], "assessment_id", assessment_id)
  candidates$catch_age_evidence[candidate_row] <- paste(
    candidates$catch_age_evidence[candidate_row],
    "Tables 10-21 additionally supply commercial landings biomass, commercial discard numbers, standardized fishery and survey index observations with source errors, and fitted expected catches and indices; numeric age-composition arrays remain unavailable.")
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Tables 10-21 now add fitted expected landings/discards by fleet and observed-versus-predicted fishery and survey indices; no N-at-age or F-at-age arrays or annual output intervals were found in the amendment tables.")
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
} else {
  cat("Dry run: ", nrow(inputs), " additional Gulf gag inputs and ",
    nrow(outputs), " fitted outputs from SEDAR 72 Tables 10-21.\n", sep = "")
  print(table(inputs$measure, useNA = "ifany"))
  print(table(outputs$measure, useNA = "ifany"))
}
