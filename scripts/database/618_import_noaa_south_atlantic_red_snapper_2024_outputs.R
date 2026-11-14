root <- "."
stock_id <- "noaa_south_atlantic_red_snapper"
assessment_id <- "noaa_south_atlantic_red_snapper_2024"
candidate_id <- "NOAA:10231"
update_url <- paste0("https://sedarweb.org/documents/",
  "sefsc-2024-update-to-sedar-73-south-atlantic-red-snapper-assessment/")
framework_url <- paste0("https://sedarweb.org/documents/",
  "sedar-73-stock-assessment-report-south-atlantic-red-snapper/")
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
source_dir <- cache_options[
  vapply(cache_options, function(x) file.exists(file.path(x, "sources.csv")), logical(1))
][1L]
if (is.na(source_dir)) stop("Could not find the shared SEDAR 73 cache.", call. = FALSE)

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
update_pdf <- verify_source("SEFSC_2024_update_SEDAR73.pdf")
framework_pdf <- verify_source("SEDAR73_SAR_2021.pdf")
update_text_path <- sub("\\.pdf$", ".txt", update_pdf, ignore.case = TRUE)
if (!file.exists(update_text_path)) stop("Missing local text extract.", call. = FALSE)
lines <- readLines(update_text_path, warn = FALSE, encoding = "UTF-8")

parse_table <- function(title, columns) {
  start <- which(grepl(title, lines, fixed = TRUE))[1L]
  if (is.na(start)) stop("Could not find table heading: ", title, call. = FALSE)
  next_tables <- which(grepl("^Table[[:space:]]+[0-9]+\\.", trimws(lines)))
  next_tables <- next_tables[next_tables > start]
  end <- if (length(next_tables)) min(next_tables) - 1L else length(lines)
  section <- lines[seq.int(start + 1L, end)]
  records <- section[grepl("^\\s*(19|20)[0-9]{2}\\s+", section)]
  parsed <- lapply(records, function(line) {
    line <- gsub("([0-9])[[:space:]]+\\.([0-9]+)", "\\1.\\2", line, perl = TRUE)
    values <- suppressWarnings(as.numeric(strsplit(trimws(line), "[[:space:]]+")[[1L]]))
    if (length(values) != columns || any(!is.finite(values))) {
      stop("Unexpected numeric row in ", title, ": ", line, call. = FALSE)
    }
    values
  })
  result <- as.matrix(do.call(rbind, parsed))
  result <- result[result[, 1L] >= 1950 & result[, 1L] <= 2023, , drop = FALSE]
  if (!identical(as.integer(result[, 1L]), 1950:2023)) {
    stop("Unexpected year coverage for ", title, call. = FALSE)
  }
  result
}
n_age <- parse_table("Table 2. Estimated total abundance at age", 22L)
biomass_age <- parse_table("Table 3. Estimated biomass at age", 22L)
status <- parse_table("Table 4. Estimated time series of status indicators", 11L)
f_age <- parse_table("Table 10. Estimated instantaneous fishing mortality rate", 21L)
years <- as.integer(n_age[, 1L])
if (!identical(years, as.integer(biomass_age[, 1L])) ||
    !identical(years, as.integer(status[, 1L])) ||
    !identical(years, as.integer(f_age[, 1L]))) {
  stop("Annual output tables have different year coverage.", call. = FALSE)
}

age_surface <- function(type, measure, table, unit, reference, notes) {
  values <- table[, 2:21, drop = FALSE]
  ages <- rep(1:20, times = length(years))
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = rep(years, each = 20L), age = ages,
    age_group = ifelse(ages == 20, "20+", ""),
    value = as.numeric(t(values)), se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table",
    source_reference = reference, notes = notes, scenario = "",
    stringsAsFactors = FALSE
  )
}
annual_output <- function(type, measure, value, unit, reference, notes) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = years, age = NA_real_, age_group = "",
    value = as.numeric(value), se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table",
    source_reference = reference, notes = notes, scenario = "",
    stringsAsFactors = FALSE
  )
}
outputs <- rbind(
  age_surface("population", "numbers_at_age", n_age, "1000 fish",
    "SEFSC 2024 update to SEDAR 73, Table 2, p. 21",
    "Estimated abundance at start of year. Age 20 is the 20+ group; age-specific uncertainty is not tabulated."),
  annual_output("population", "total_numbers", n_age[, 22L], "1000 fish",
    "SEFSC 2024 update to SEDAR 73, Table 2, p. 21",
    "Official total column; rounded source values."),
  annual_output("recruitment", "recruitment", n_age[, 2L], "1000 fish",
    "SEFSC 2024 update to SEDAR 73, Table 2, p. 21",
    "Age-1 abundance at start of year, identified as recruitment in the report."),
  age_surface("biomass", "biomass_at_age", biomass_age, "1000 lb",
    "SEFSC 2024 update to SEDAR 73, Table 3, p. 22",
    "Estimated biomass at age at start of year. Age 20 is the 20+ group."),
  age_surface("mortality", "fishing_mortality_at_age", f_age, "per year",
    "SEFSC 2024 update to SEDAR 73, Table 10, p. 29",
    "Estimated instantaneous fishing mortality at age. Age 20 is the 20+ group."),
  annual_output("mortality", "apical_F", status[, 2L], "per year",
    "SEFSC 2024 update to SEDAR 73, Table 4, p. 23",
    "Annual apical fishing mortality rate."),
  annual_output("biomass", "total_biomass", status[, 4L], "mt",
    "SEFSC 2024 update to SEDAR 73, Table 4, p. 23",
    "Estimated total biomass at start of year."),
  annual_output("biomass", "SSB", status[, 6L], "1e8 eggs",
    "SEFSC 2024 update to SEDAR 73, Table 4, p. 23",
    "Source labels this egg-based spawning output as SSB; it is not biomass.")
)
if (nrow(outputs) != 4810L || any(!is.finite(outputs$value)) ||
    n_age[1L, 2L] != 482.76 || n_age[1L, 22L] != 2672.26 ||
    f_age[1L, 2L] != 0.003 || status[1L, 4L] != 13597 ||
    status[1L, 6L] != 1478810) {
  stop("Parsed output dimensions or source values did not pass checks.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA Fisheries",
  authority_stock_id = "10231", scientific_name = "Lutjanus campechanus",
  common_name = "South Atlantic red snapper", area = "South Atlantic Coast",
  region = "United States South Atlantic", ocean = "Northwest Atlantic",
  notes = paste(
    "NOAA Stock SMART unit 10231.",
    "Distinct from Gulf of Mexico red snapper (NOAA:10230).",
    "No verified Charbonneau-Keith Master match."
  ), stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2023L,
  estimate_terminal_year = 2023L, assessment_type = "assessment_update",
  model_family = "Beaufort Assessment Model",
  model_version = "SEFSC 2024 update to SEDAR 73",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2021L,
  assessment_url = update_url, framework_url = framework_url,
  data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "not_started",
  outputs_status = "partial",
  notes = paste(
    "Latest accepted update located for NOAA:10231, fitted through 2023.",
    "The update uses SEDAR 73 life-history sources; the companion importer records their age-specific values.",
    "Run-specific 2024 catch, index, and composition observations remain unavailable."
  ), stringsAsFactors = FALSE
)
assumptions <- data.frame(
  assessment_id = assessment_id,
  component = c("assessment", "model", "population", "spawning_output", "M",
    rep("discard_mortality", 12L)),
  fleet = c("", "", "", "", "", rep(c("cH", "HB", "GR"), each = 4L)),
  survey = "", sex = "", region = "", season = "",
  setting = c("run_identity", "model_name", "age_range", "definition",
    "natural_mortality_structure", rep(paste0("block_", 1:4), times = 3L)),
  value = c(
    "SEFSC 2024 update to SEDAR 73; data through 2023",
    "Beaufort Assessment Model (BAM)",
    "Ages 1-20+, with age 20 as the plus group",
    "Population fecundity in eggs at peak spawning; not biomass SSB",
    "Fixed age-specific Lorenzen mortality retained from SEDAR 73",
    as.character(c(.48, .38, .36, .32, .37, .26, .25, .22, .37, .28, .26, .23))
  ),
  source_reference = c(
    rep("SEFSC 2024 update to SEDAR 73, assessment summary and Tables 2-4, 10", 5L),
    rep("SEFSC 2024 update to SEDAR 73, Table 1, p. 20", 12L)
  ),
  notes = c(rep("", 5L), rep(
    "This row stores the estimate for the named fleet and block. Table 1 uncertainty ranges for blocks 1-4 are cH 0.38-0.58/0.28-0.48/0.26-0.46/0.22-0.42; HB 0.27-0.45/0.18-0.34/0.17-0.33/0.14-0.30; and GR 0.27-0.45/0.20-0.36/0.18-0.34/0.15-0.31.",
    12L
  )),
  stringsAsFactors = FALSE
)

write_table_rows <- function(path, rows) {
  write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double")
}
update_candidate <- function() {
  path <- "discovery/candidates.csv"
  candidates <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(candidates$candidate_id == candidate_id)
  if (length(i) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
  candidates$matched_stock_id[i] <- stock_id
  candidates$match_status[i] <- "matched"
  candidates$import_status[i] <- "partial"
  candidates$review_date[i] <- as.character(Sys.Date())
  candidates$output_evidence[i] <- paste(
    candidates$output_evidence[i],
    "2024 update point estimates for annual N-at-age, biomass-at-age, F-at-age, recruitment, SSB and total biomass imported."
  )
  candidates$notes[i] <- paste(
    candidates$notes[i],
    "Selected 2024 output tables imported; the companion source importer adds life-history inputs explicitly carried forward from SEDAR 73. Run-specific observation arrays remain unavailable. These tables do not provide age-specific uncertainty."
  )
  replace_candidate_register_row(path, i, candidates[i, , drop = FALSE], candidate_id)
}

if (!write_mode) {
  cat("Dry run:", nrow(outputs), "output rows;", length(years),
    "years;", "ages 1-20+; assessment", assessment_id, ".\n")
} else {
  stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
    check.names = FALSE)
  assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    check.names = FALSE)
  if (any(stocks$stock_id == stock_id) ||
      any(assessments$assessment_id == assessment_id)) {
    stop("Stock or assessment already exists; review before writing.", call. = FALSE)
  }
  existing <- suppressWarnings(system2("rg", c("--color", "never",
    "--no-heading", "--no-line-number", "-F", assessment_id,
    "database/outputs.csv"), stdout = TRUE, stderr = FALSE))
  rg_status <- attr(existing, "status")
  if (is.null(rg_status)) rg_status <- 0L
  if (rg_status == 0L && length(existing)) {
    stop("Output rows already exist; review before writing.", call. = FALSE)
  }
  if (rg_status != 1L) stop("Could not check for existing output rows.", call. = FALSE)
  write_table_rows("database/stocks.csv", stock)
  write_table_rows("database/assessments.csv", assessment)
  write_table_rows("database/assumptions.csv", assumptions)
  write_table_rows("database/outputs.csv", outputs)
  update_candidate()
  cat("Imported", nrow(outputs), "official output rows for", assessment_id, ".\n")
}
