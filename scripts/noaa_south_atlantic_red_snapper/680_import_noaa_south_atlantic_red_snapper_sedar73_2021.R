root <- "."
stock_id <- "noaa_south_atlantic_red_snapper"
assessment_id <- "noaa_south_atlantic_red_snapper_sedar73_2021"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

manifest_path <- "provenance/discovery_noaa_satl_red_snapper_2024/sources.csv"
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
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
report_text <- sub("\\.pdf$", ".txt", report_pdf, ignore.case = TRUE)
if (!file.exists(report_text)) stop("Missing local SEDAR 73 text extract.", call. = FALSE)
lines <- readLines(report_text, warn = FALSE, encoding = "UTF-8")

parse_table <- function(title, columns, first_year, last_year, allow_missing = FALSE) {
  start <- which(grepl(title, lines, fixed = TRUE))[1L]
  if (is.na(start)) stop("Could not find table heading: ", title, call. = FALSE)
  next_tables <- which(grepl("^Table[[:space:]]+[0-9]+\\.", trimws(lines)))
  next_tables <- next_tables[next_tables > start]
  end <- if (length(next_tables)) min(next_tables) - 1L else length(lines)
  section <- lines[seq.int(start + 1L, end)]
  records <- section[grepl("^\\s*(19|20)[0-9]{2}\\s+", section)]
  parsed <- lapply(records, function(line) {
    line <- gsub("([0-9])[[:space:]]+\\.([0-9]+)", "\\1.\\2", line,
      perl = TRUE)
    values <- suppressWarnings(as.numeric(strsplit(trimws(line),
      "[[:space:]]+")[[1L]]))
    if (length(values) != columns || any(is.infinite(values)) ||
        (!allow_missing && any(!is.finite(values)))) {
      stop("Unexpected numeric row in ", title, ": ", line, call. = FALSE)
    }
    values
  })
  result <- as.matrix(do.call(rbind, parsed))
  result <- result[result[, 1L] >= first_year & result[, 1L] <= last_year,
    , drop = FALSE]
  if (!identical(as.integer(result[, 1L]), first_year:last_year)) {
    stop("Unexpected year coverage for ", title, call. = FALSE)
  }
  result
}

catch_table <- parse_table("Table 3. Observed time series of landings", 7L,
  1950L, 2019L, allow_missing = TRUE)
index_table <- parse_table("Table 4. Observed indices of abundance", 11L,
  1976L, 2019L, allow_missing = TRUE)
n_age <- parse_table("Table 9. Estimated total abundance at age", 22L,
  1950L, 2019L)
biomass_age <- parse_table("Table 11. Estimated biomass at age", 22L,
  1950L, 2019L)
status <- parse_table("Table 12. Estimated time series of status indicators", 11L,
  1950L, 2019L, allow_missing = TRUE)
f_age <- parse_table("Table 18. Estimated instantaneous", 21L,
  1950L, 2019L)
years <- as.integer(n_age[, 1L])
if (!identical(years, 1950:2019) ||
    !identical(as.integer(biomass_age[, 1L]), years) ||
    !identical(as.integer(status[, 1L]), years) ||
    !identical(as.integer(f_age[, 1L]), years) ||
    !identical(as.integer(catch_table[, 1L]), years) ||
    !identical(as.integer(index_table[, 1L]), 1976:2019)) {
  stop("SEDAR 73 source tables do not have matching year coverage.", call. = FALSE)
}

input_columns <- c(
  "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age", "value", "unit",
  "sampling_time", "source_type", "source_reference", "transformation", "notes",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin"
)
make_input_rows <- function(type, measure, basis, fleet = "", survey = "",
    years, values, unit, source_reference, notes, partition = "") {
  keep <- !is.na(values)
  if (!any(keep)) return(NULL)
  rows <- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = "", season = "",
    year = years[keep], year_basis = "calendar_year", age = NA_real_,
    value = as.numeric(values[keep]), unit = unit, sampling_time = NA_real_,
    source_type = "official_table", source_reference = source_reference,
    transformation = "", notes = notes, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "",
    partition = partition, weight_bin = "", stringsAsFactors = FALSE
  )
  rows[input_columns]
}

catch_specs <- list(
  list(column = 2L, measure = "landings_biomass", basis = "biomass",
    fleet = "Commercial handline", unit = "1000 lb whole weight",
    partition = "landings", note = "Commercial handline landings."),
  list(column = 3L, measure = "landings_numbers", basis = "numbers",
    fleet = "Headboat", unit = "1000 fish", partition = "landings",
    note = "Headboat landings."),
  list(column = 4L, measure = "landings_numbers", basis = "numbers",
    fleet = "General recreational", unit = "1000 fish", partition = "landings",
    note = "General recreational landings."),
  list(column = 5L, measure = "discard_numbers", basis = "numbers",
    fleet = "Commercial handline", unit = "1000 fish", partition = "dead_discards",
    note = "Commercial handline dead discards."),
  list(column = 6L, measure = "discard_numbers", basis = "numbers",
    fleet = "Headboat", unit = "1000 fish", partition = "dead_discards",
    note = "Headboat dead discards."),
  list(column = 7L, measure = "discard_numbers", basis = "numbers",
    fleet = "General recreational", unit = "1000 fish", partition = "dead_discards",
    note = "General recreational dead discards.")
)
catch_rows <- lapply(catch_specs, function(spec) make_input_rows(
  "catch", spec$measure, spec$basis, fleet = spec$fleet,
  years = catch_table[, 1L], values = catch_table[, spec$column],
  unit = spec$unit, source_reference = "SEDAR 73 Stock Assessment Report, Section II, Table 3, p. 46",
  notes = paste(spec$note, "Values are observed source totals; blank cells remain missing."),
  partition = spec$partition
))

index_names <- c("Commercial handline", "Headboat", "Headboat discard",
  "SERFS chevron trap", "SERFS video")
index_rows <- list()
for (i in seq_along(index_names)) {
  index_column <- 2L + (i - 1L) * 2L
  cv_column <- index_column + 1L
  index_rows[[length(index_rows) + 1L]] <- make_input_rows(
    "index", "relative_abundance_index", "index_scale",
    survey = index_names[i], years = index_table[, 1L],
    values = index_table[, index_column], unit = "source index units",
    source_reference = "SEDAR 73 Stock Assessment Report, Section II, Table 4, p. 47",
    notes = "Aggregate relative-abundance index on the reported source scale; no physical unit or within-year timing is specified."
  )
  index_rows[[length(index_rows) + 1L]] <- make_input_rows(
    "index", "abundance_index_cv", "relative_scale",
    survey = index_names[i], years = index_table[, 1L],
    values = index_table[, cv_column], unit = "ratio",
    source_reference = "SEDAR 73 Stock Assessment Report, Section II, Table 4, p. 47",
    notes = "Source-reported CV paired with the aggregate index; it is not an age-specific likelihood weight."
  )
}
inputs <- do.call(rbind, c(catch_rows, index_rows))
rownames(inputs) <- NULL

output_columns <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group", "value", "se", "lwr", "upr",
  "unit", "source_type", "source_reference", "notes", "scenario"
)
age_surface <- function(type, measure, table, unit, source_reference, notes) {
  ages <- rep(1:20, times = length(years))
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = rep(years, each = 20L), age = ages,
    age_group = ifelse(ages == 20, "20+", ""),
    value = as.numeric(t(table[, 2:21, drop = FALSE])),
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = "", stringsAsFactors = FALSE
  )
}
annual_output <- function(type, measure, value, unit, source_reference, notes) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = years, age = NA_real_, age_group = "", value = as.numeric(value),
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = "", stringsAsFactors = FALSE
  )
}
outputs <- rbind(
  age_surface("population", "numbers_at_age", n_age, "1000 fish",
    "SEDAR 73 Stock Assessment Report, Section II, Table 9, p. 52",
    "Estimated abundance at start of year; age 20 is the 20+ group. Point estimates only."),
  annual_output("population", "total_numbers", n_age[, 22L], "1000 fish",
    "SEDAR 73 Stock Assessment Report, Section II, Table 9, p. 52",
    "Source-reported total abundance at start of year; rounded table values."),
  annual_output("recruitment", "recruitment", n_age[, 2L], "1000 fish",
    "SEDAR 73 Stock Assessment Report, Section II, Table 9, p. 52",
    "Age-1 abundance at start of year, identified as recruitment."),
  age_surface("biomass", "biomass_at_age", biomass_age, "1000 lb",
    "SEDAR 73 Stock Assessment Report, Section II, Table 11, p. 54",
    "Estimated biomass at age at start of year; age 20 is the 20+ group."),
  age_surface("mortality", "fishing_mortality_at_age", f_age, "per year",
    "SEDAR 73 Stock Assessment Report, Section II, Table 18, p. 61",
    "Estimated instantaneous fishing mortality at age. Point estimates only."),
  annual_output("mortality", "apical_F", status[, 2L], "per year",
    "SEDAR 73 Stock Assessment Report, Section II, Table 12, p. 55",
    "Annual apical fishing mortality rate."),
  annual_output("biomass", "total_biomass", status[, 4L], "mt",
    "SEDAR 73 Stock Assessment Report, Section II, Table 12, p. 55",
    "Estimated total biomass at start of year."),
  annual_output("biomass", "SSB", status[, 6L], "1e8 eggs",
    "SEDAR 73 Stock Assessment Report, Section II, Table 12, p. 55",
    "Source-defined spawning output in eggs at peak spawning; not biomass SSB.")
)[output_columns]

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2021L, terminal_year = 2019L,
  estimate_terminal_year = 2019L, assessment_type = "operational_assessment",
  model_family = "Beaufort Assessment Model",
  model_version = "SEDAR 73 operational assessment",
  is_current = "FALSE", is_applied = "TRUE", framework_year = 2021L,
  assessment_url = "https://sedarweb.org/documents/sedar-73-stock-assessment-report-south-atlantic-red-snapper/",
  framework_url = "https://sedarweb.org/documents/sedar-73-stock-assessment-report-south-atlantic-red-snapper/",
  data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Historical SEDAR 73 operational assessment, fitted through 2019.",
    "This is separate from the later 2024 update and does not supply inputs for that run.",
    "Numeric catches and aggregate indices are recovered from report Tables 3-4; age-composition vectors are not tabulated."
  ), stringsAsFactors = FALSE
)
discard_values <- c(.48, .38, .36, .32, .37, .26, .25, .22, .37, .28, .26, .23)
discard_fleets <- rep(c("cH", "HB", "GR"), each = 4L)
discard_blocks <- rep(paste0("block_", 1:4), times = 3L)
discard_ranges <- c(
  "0.38-0.58; 0.28-0.48; 0.26-0.46; 0.22-0.42",
  "0.27-0.45; 0.18-0.34; 0.17-0.33; 0.14-0.30",
  "0.27-0.45; 0.20-0.36; 0.18-0.34; 0.15-0.31"
)
assumptions <- data.frame(
  assessment_id = assessment_id,
  component = c("assessment", "model", "population", "spawning_output", "M",
    rep("discard_mortality", 12L)),
  fleet = c("", "", "", "", "", discard_fleets),
  survey = "", sex = "", region = "", season = "",
  setting = c("run_identity", "model_name", "age_range", "definition",
    "natural_mortality_structure", discard_blocks),
  value = c(
    "SEDAR 73 operational assessment; data through 2019",
    "Beaufort Assessment Model (BAM)", "Ages 1-20+, age 20 is the plus group",
    "Spawning biomass expressed as eggs at peak spawning; not biomass",
    "Fixed age-dependent Lorenzen natural mortality",
    as.character(discard_values)
  ),
  source_reference = c(
    rep("SEDAR 73 Stock Assessment Report, Sections II-III", 5L),
    rep("SEDAR 73 Stock Assessment Report, Section II, Table 6, p. 50", 12L)
  ),
  notes = c(rep("", 5L), rep(
    paste("Discard-mortality block estimate for the named fleet.",
      "The source-reported uncertainty ranges for blocks 1-4 are:",
      paste0("cH ", discard_ranges[1L], "; HB ", discard_ranges[2L],
        "; GR ", discard_ranges[3L], ".")), 12L
  )), stringsAsFactors = FALSE
)

if (!identical(names(inputs), input_columns) || !identical(names(outputs), output_columns) ||
    nrow(assessment) != 1L || nrow(inputs) == 0L || nrow(outputs) != 4550L ||
    nrow(assumptions) != 17L || any(!is.finite(inputs$value)) ||
    any(!is.finite(outputs$value)) || n_age[1L, 2L] != 436.87 ||
    n_age[1L, 22L] != 2422.24 || catch_table[1L, 2L] != 368.657 ||
    index_table[index_table[, 1L] == 1993L, 2L] != 1.09 ||
    index_table[index_table[, 1L] == 1993L, 3L] != 0.2 ||
    status[1L, 6L] != 1342193 || f_age[1L, 2L] != 0.003) {
  stop("SEDAR 73 input/output tables failed structural checks.", call. = FALSE)
}

cat("Prepared SEDAR 73 red snapper import: ", nrow(assumptions),
  " assumptions, ", nrow(inputs), " inputs, and ", nrow(outputs),
  " outputs.\n", sep = "")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to append this separate 2021 event.\n")
  quit(save = "no", status = 0L)
}

append_csv_rows <- function(name, rows) {
  path <- file.path(root, "database", name)
  found <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(found, "status")
  if (is.null(status)) status <- 0L
  if (status == 0L && length(found)) {
    if (length(found) == nrow(rows)) {
      cat("Rows already present in ", name, "; leaving them unchanged.\n", sep = "")
      return(invisible(FALSE))
    }
    stop("Partial rows already exist in ", name, "; review before retrying.",
      call. = FALSE)
  }
  if (status != 1L) stop("Could not check for existing rows in ", name, ".")
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  if (!identical(header, names(rows))) stop("Unexpected database schema in ", name, ".")
  size <- file.info(path)$size
  con <- file(path, open = "rb")
  seek(con, where = max(0, size - 2), origin = "start")
  ending <- readBin(con, what = "raw", n = min(2, size))
  close(con)
  eol <- if (length(ending) == 2L && identical(ending, as.raw(c(13L, 10L)))) "\r\n" else "\n"
  if (!length(ending) || tail(ending, 1L) != as.raw(10L)) {
    append_con <- file(path, open = "ab")
    writeBin(charToRaw(eol), append_con)
    close(append_con)
  }
  write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
    eol = eol, append = TRUE)
}
stock_table <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
assessment_table <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
existing_assessment <- assessment_table[
  assessment_table$assessment_id == assessment_id, , drop = FALSE
]
if (!stock_id %in% stock_table$stock_id ||
    !"noaa_south_atlantic_red_snapper_2024" %in% assessment_table$assessment_id ||
    nrow(existing_assessment) > 1L ||
    (nrow(existing_assessment) == 1L &&
      (existing_assessment$stock_id != stock_id ||
       existing_assessment$assessment_year != "2021" ||
       existing_assessment$terminal_year != "2019"))) {
  stop("Expected the matching South Atlantic red snapper stock and separate assessment records.")
}
append_csv_rows("assessments.csv", assessment)
append_csv_rows("assumptions.csv", assumptions)
append_csv_rows("inputs.csv", inputs)
append_csv_rows("outputs.csv", outputs)
cat("Appended separate SEDAR 73 assessment event; the 2024 current record was not changed.\n")
