root <- "."
assessment_id <- "noaa_south_atlantic_red_snapper_2024"
candidate_id <- "NOAA:10231"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

source("scripts/database/candidate_register_io.R")

manifest <- utils::read.csv(
  "provenance/discovery_noaa_satl_red_snapper_2024/sources.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  colClasses = "character"
)
cache_options <- c(
  file.path("source_cache", "discovery_noaa_satl_red_snapper_2024"),
  file.path("..", "..", "discovery_noaa_satl_red_snapper_2024")
)
source_dir <- cache_options[
  vapply(cache_options, function(path) file.exists(file.path(path, "sources.csv")), logical(1))
][1L]
if (is.na(source_dir)) stop("Could not find the shared SEDAR 73 source cache.", call. = FALSE)

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
  value <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE)))
  if (length(value) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  value
}

report_name <- "SEFSC_2024_update_SEDAR73.pdf"
report_path <- file.path(source_dir, report_name)
manifest_row <- manifest[manifest$file == report_name, , drop = FALSE]
if (nrow(manifest_row) != 1L || !file.exists(report_path) ||
    !identical(sha256_file(report_path), tolower(manifest_row$sha256))) {
  stop("The cached SEDAR 73 update report does not match its source manifest.", call. = FALSE)
}

text_path <- sub("\\.pdf$", ".txt", report_path, ignore.case = TRUE)
if (!file.exists(text_path)) stop("The local report text extract is missing.", call. = FALSE)
lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")

parse_table <- function(table_number, column_count, years) {
  headings <- which(grepl(paste0("^Table ", table_number, "[.]"), trimws(lines)))
  if (length(headings) != 1L) stop("Expected one heading for Table ", table_number, ".", call. = FALSE)
  next_tables <- which(grepl("^Table [0-9]+[.]", trimws(lines)))
  next_tables <- next_tables[next_tables > headings]
  end <- if (length(next_tables)) min(next_tables) - 1L else length(lines)
  records <- lines[seq.int(headings + 1L, end)]
  records <- records[grepl("^\\s*(19|20)[0-9]{2}\\s+", records)]
  parsed <- lapply(records, function(line) {
    line <- gsub("([0-9])[[:space:]]+\\.([0-9]+)", "\\1.\\2", line, perl = TRUE)
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (length(tokens) != column_count) {
      stop("Unexpected number of columns in Table ", table_number, ": ", line, call. = FALSE)
    }
    suppressWarnings(as.numeric(ifelse(tokens == ".", NA_character_, tokens)))
  })
  result <- as.matrix(do.call(rbind, parsed))
  if (!identical(as.integer(result[, 1L]), years) ||
      any(result[, 1L] != years) || any(result[, -1L] < 0, na.rm = TRUE)) {
    stop("Unexpected year coverage or negative value in Table ", table_number, ".", call. = FALSE)
  }
  result
}

tables <- list(
  `11` = parse_table(11L, 5L, 1950:2023),
  `12` = parse_table(12L, 5L, 1950:2023),
  `13` = parse_table(13L, 5L, 1981:2023),
  `14` = parse_table(14L, 5L, 1981:2023),
  `15` = parse_table(15L, 21L, 1950:2023),
  `16` = parse_table(16L, 21L, 1950:2023),
  `17` = parse_table(17L, 21L, 1950:2023),
  `18` = parse_table(18L, 21L, 1950:2023)
)

assert_age_totals <- function(age_table, annual_table, label) {
  age_sum <- rowSums(age_table[, -1L, drop = FALSE])
  annual_total <- annual_table[, ncol(annual_table)]
  annual_year <- annual_table[, 1L]
  annual_index <- match(age_table[, 1L], annual_year)
  keep <- !is.na(annual_index) & is.finite(annual_total[annual_index])
  if (any(abs(age_sum[keep] - annual_total[annual_index[keep]]) > 0.05)) {
    stop(label, " does not reconcile to its annual total within report rounding.", call. = FALSE)
  }
}

assert_age_totals(tables[["16"]], tables[["12"]], "Table 16 landings at age")
assert_age_totals(tables[["17"]], tables[["13"]], "Table 17 discards at age")
assert_age_totals(tables[["18"]], tables[["14"]], "Table 18 discard biomass at age")

table15_total <- rowSums(tables[["15"]][, -1L, drop = FALSE])
table11_total <- tables[["11"]][, 5L]
table13_total_2023 <- tables[["13"]][tables[["13"]][, 1L] == 2023L, 5L]
if (any(abs(table15_total - table11_total) > 0.05) ||
    abs(table15_total[tables[["15"]][, 1L] == 2023L] -
      (table11_total[tables[["11"]][, 1L] == 2023L] + table13_total_2023)) < 100) {
  stop("Table 15's published discrepancy changed; review before import.", call. = FALSE)
}

fleet_names <- c("cH", "HB", "GR", "Total")
table_reference <- function(number, page) {
  paste0("SEFSC 2024 update to SEDAR 73, Table ", number, ", p. ", page)
}

output_frame <- function(type, measure, fleet, year, age, age_group, value,
                         unit, reference, notes) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = "", sex = "", region = "", season = "",
    year = as.integer(year), age = as.integer(age), age_group = age_group,
    value = as.numeric(value), se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table", source_reference = reference,
    notes = notes, scenario = "", stringsAsFactors = FALSE
  )
}

annual_rows <- function(table_number, measure, unit, page, notes) {
  source_table <- tables[[as.character(table_number)]]
  values <- as.numeric(t(source_table[, -1L, drop = FALSE]))
  years <- rep(as.integer(source_table[, 1L]), each = length(fleet_names))
  fleets <- rep(fleet_names, times = nrow(source_table))
  keep <- is.finite(values)
  output_frame(
    "catch", measure, fleets[keep], years[keep], rep(NA_integer_, sum(keep)),
    rep("", sum(keep)), values[keep], unit,
    table_reference(table_number, page), notes
  )
}

age_rows <- function(table_number, measure, unit, page, notes) {
  source_table <- tables[[as.character(table_number)]]
  ages <- rep(seq_len(ncol(source_table) - 1L), times = nrow(source_table))
  years <- rep(as.integer(source_table[, 1L]), each = ncol(source_table) - 1L)
  values <- as.numeric(t(source_table[, -1L, drop = FALSE]))
  keep <- is.finite(values)
  output_frame(
    "catch", measure, rep("", sum(keep)), years[keep], ages[keep],
    ifelse(ages[keep] == 20L, "20+", ""), values[keep], unit,
    table_reference(table_number, page), notes
  )
}

outputs <- do.call(rbind, list(
  annual_rows(11L, "predicted_landings_numbers", "1000 fish", 30L,
    "Model-estimated landings, not observed input catches. Source Total is retained alongside the fleet estimates."),
  annual_rows(12L, "predicted_landings_weight", "1000 lb", 31L,
    "Model-estimated landings, not observed input catches. Source Total is retained alongside the fleet estimates."),
  annual_rows(13L, "expected_dead_discard_numbers", "1000 fish", 32L,
    "Model-estimated discard mortalities. Source cells printed as '.' are omitted, not treated as zero; Source Total is retained when reported."),
  annual_rows(14L, "expected_dead_discard_biomass", "1000 lb", 33L,
    "Model-estimated discard mortalities. Source cells printed as '.' are omitted, not treated as zero; Source Total is retained when reported."),
  age_rows(15L, "total_removals_at_age", "1000 fish", 34L,
    "Source-reported Table 15 age surface. The table labels this total removals (landings and dead discards), but its annual age sums match Table 11 landings rather than the sum of Tables 11 and 13; preserved as printed and flagged in the source review."),
  age_rows(16L, "predicted_landings_weight", "1000 lb", 35L,
    "Model-estimated landings by age, not observed input catches. Age 20 is the 20+ group."),
  age_rows(17L, "expected_dead_discard_numbers", "1000 fish", 36L,
    "Model-estimated discard numbers by age; annual age sums reconcile to Table 13 discard mortalities within report rounding. Age 20 is the 20+ group."),
  age_rows(18L, "expected_dead_discard_biomass", "1000 lb", 37L,
    "Model-estimated discard biomass by age; annual age sums reconcile to Table 14 discard mortalities within report rounding. Age 20 is the 20+ group.")
))

expected_rows <- sum(vapply(tables, function(x) sum(is.finite(x[, -1L])), integer(1)))
if (nrow(outputs) != expected_rows || any(!is.finite(outputs$value)) ||
    any(outputs$value < 0) || any(outputs$source_type != "official_table")) {
  stop("The fitted catch output rows failed dimensions or value checks.", call. = FALSE)
}

assessments <- utils::read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
candidates_path <- "discovery/candidates.csv"
candidates <- utils::read.csv(candidates_path, stringsAsFactors = FALSE, check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(assessment_row) != 1L || length(candidate_row) != 1L ||
    assessments$stock_id[assessment_row] != "noaa_south_atlantic_red_snapper" ||
    assessments$assessment_year[assessment_row] != 2024L ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "partial") {
  stop("The 2024 assessment or candidate register no longer matches the reviewed case.", call. = FALSE)
}

if (!write_mode) {
  cat("Dry run:", nrow(outputs), "fitted catch output rows across Tables 11-18;",
    "table years 1950-2023; report-missing cells omitted.\n")
} else {
  output_path <- "database/outputs.csv"
  marker <- paste0('"', assessment_id, '","catch","total_removals_at_age"')
  existing <- suppressWarnings(system2("rg", c(
    "--max-count", "1", "--fixed-strings", marker, output_path
  ), stdout = TRUE, stderr = FALSE))
  status <- attr(existing, "status")
  if (is.null(status)) status <- 0L
  if (status == 0L) stop("Supplemental fitted catch outputs already exist; review before writing.", call. = FALSE)
  if (status != 1L) stop("Could not check for prior supplemental output rows.", call. = FALSE)

  utils::write.table(outputs, output_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double")

  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "SEFSC 2024 update Tables 11-18 fitted landings, discard, and age-specific catch outputs imported; Table 15 is retained with its source inconsistency documented."
  )
  candidates$notes[candidate_row] <- paste(
    candidates$notes[candidate_row],
    "The 2024 report's fitted landings and discard tables (11-14, 16-18) are now imported separately from observed inputs. Table 15 is kept as printed but does not reconcile with its stated total-removals definition."
  )
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  replace_candidate_register_row(candidates_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  cat("Imported", nrow(outputs), "fitted catch output rows for", assessment_id, ".\n")
}
