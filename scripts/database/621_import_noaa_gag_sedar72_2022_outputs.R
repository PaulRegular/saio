root <- "."
cache_dir <- file.path("source_cache", "noaa_gag_sedar72_2022")
manifest_path <- file.path("provenance", "noaa_gag_sedar72_2022", "manifest.csv")
stock_id <- "noaa_gag_gulf"
assessment_id <- "noaa_gag_gulf_sedar72_srfs_2022"
candidate_id <- "NOAA:10348"
assessment_url <- "https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-operational-assessment-report-amendment-state-reef-fish-survey-srfs-run/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")

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
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

verify_source <- function(name) {
  row <- manifest[basename(manifest$file) == name, , drop = FALSE]
  path <- file.path(cache_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.numeric(row$bytes) != file.info(path)$size ||
      !identical(sha256_file(path), tolower(row$sha256))) {
    stop("Cached source differs from its provenance record: ", name, call. = FALSE)
  }
  path
}

source_files <- c(
  "sedar72_srfs_amendment_2022.pdf",
  "sedar72_final_report_2021.pdf",
  "sedar72_wp17_compositions_2021.pdf",
  "sedar72_executive_summary_2022.pdf",
  "sedar72_ssc_review_2022.pdf"
)
paths <- setNames(vapply(source_files, verify_source, character(1L)), source_files)
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached SEDAR 72 output tables.", call. = FALSE)
}
pages <- pdftools::pdf_text(paths[["sedar72_srfs_amendment_2022.pdf"]])

table_rows <- function(number, heading, n_fields, expected_years) {
  pattern <- paste0("Table ", number, "( Continued)?[.] ", heading)
  table_pages <- pages[grepl(pattern, pages, perl = TRUE)]
  if (length(table_pages) != 2L) {
    stop("Expected two printed pages for SEDAR 72 Table ", number, ".", call. = FALSE)
  }
  lines <- trimws(unlist(strsplit(paste(table_pages, collapse = "\n"), "\n")))
  lines <- lines[grepl("^(19|20)[0-9]{2}[[:space:]]+", lines)]
  parsed <- lapply(lines, function(line) {
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    fields <- gsub(",", "", fields, fixed = TRUE)
    values <- suppressWarnings(as.numeric(fields))
    if (length(values) < n_fields || anyNA(values[seq_len(n_fields)])) return(NULL)
    values[seq_len(n_fields)]
  })
  parsed <- Filter(Negate(is.null), parsed)
  values <- do.call(rbind, parsed)
  years <- as.integer(values[, 1L])
  if (!identical(years, expected_years)) {
    stop("SEDAR 72 Table ", number, " does not contain the expected 1963-2019 series.",
      call. = FALSE)
  }
  list(year = years, values = values[, -1L, drop = FALSE])
}

years <- 1963:2019
table6 <- table_rows(6L, "Estimates of annual exploitation rate", 2L, years)
table7 <- table_rows(7L, "Estimates of annual exploitation rate", 8L, years)
table8 <- table_rows(8L, "Expected biomass", 7L, years)
table9 <- table_rows(9L, "Expected spawning stock biomass", 8L, years)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, sex = "", fleet = "",
                       age = NA_integer_, table_number, notes) {
  n <- length(value)
  if (!n) return(invisible(NULL))
  out <- pacific_database_row("outputs", n = n)
  out$assessment_id <- assessment_id
  out$type <- rep_len(type, n)
  out$measure <- rep_len(measure, n)
  out$fleet <- rep_len(fleet, n)
  out$sex <- rep_len(sex, n)
  out$year <- as.integer(year)
  out$age <- rep_len(age, n)
  out$value <- as.numeric(value)
  out$unit <- rep_len(unit, n)
  out$source_type <- "official_table"
  out$source_reference <- paste0("SEDAR72_SRFS_Amendment_2022.pdf, Table ", table_number)
  out$notes <- rep_len(notes, n)
  output_rows[[length(output_rows) + 1L]] <<- out
  invisible(out)
}

add_output("mortality", "exploitation_rate", table6$values[, 1L], "proportion",
  table6$year, fleet = "All fleets excluding red tide", table_number = 6L,
  notes = "Annual total biomass killed divided by total biomass age 3+; the report uses this as a proxy for annual fishing mortality. It is an exploitation rate, not instantaneous F.")

fleet_names <- c("Commercial vertical line", "Commercial longline",
  "Recreational headboat", "Recreational charter", "Recreational private + shore",
  "Red tide mortality", "All fleets including red tide")
for (i in seq_along(fleet_names)) {
  add_output("mortality", "exploitation_rate", table7$values[, i], "proportion",
    table7$year, fleet = fleet_names[i], table_number = 7L,
    notes = "Annual fleet or total biomass-killed fraction relative to total biomass age 3+. Red tide is a separate mortality source; values are not instantaneous fishing mortality.")
}

table8_specs <- list(
  list(type = "biomass", measure = "total_biomass", unit = "metric tons", column = 1L,
       note = "Expected biomass for all ages, as reported in Table 8."),
  list(type = "biomass", measure = "exploitable_biomass", unit = "metric tons", column = 2L,
       note = "Expected exploitable biomass for ages 3+, as reported in Table 8."),
  list(type = "biomass", measure = "SSB", unit = "metric tons", column = 3L,
       note = "Expected spawning stock biomass in metric tons, as defined by the assessment."),
  list(type = "population", measure = "exploitable_abundance", unit = "1000 fish", column = 4L,
       note = "Expected exploitable abundance for ages 3+ in thousands of fish; this is not total abundance."),
  list(type = "recruitment", measure = "recruitment", unit = "1000 fish", column = 5L,
       note = "Expected age-0 recruits in thousands of fish."),
  list(type = "probability", measure = "SSB_ratio_to_SSB0", unit = "proportion", column = 6L,
       note = "Spawning stock biomass divided by unfished spawning stock biomass SSB0 = 67,045 metric tons.")
)
for (spec in table8_specs) {
  add_output(spec$type, spec$measure, table8$values[, spec$column], spec$unit,
    table8$year, age = if (spec$measure == "recruitment") 0L else NA_integer_,
    table_number = 8L, notes = spec$note)
}

table9_specs <- list(
  list(type = "biomass", measure = "SSB", unit = "metric tons", column = 1L,
       sex = "female", note = "Female spawning stock biomass from Table 9."),
  list(type = "biomass", measure = "SSB", unit = "metric tons", column = 2L,
       sex = "male", note = "Male spawning stock biomass from Table 9."),
  list(type = "biomass", measure = "exploitable_biomass", unit = "metric tons", column = 3L,
       sex = "female", note = "Female exploitable biomass for ages 3+ from Table 9."),
  list(type = "biomass", measure = "exploitable_biomass", unit = "metric tons", column = 4L,
       sex = "male", note = "Male exploitable biomass for ages 3+ from Table 9."),
  list(type = "population", measure = "exploitable_abundance", unit = "1000 fish", column = 5L,
       sex = "female", note = "Female exploitable abundance for ages 3+ in thousands of fish."),
  list(type = "population", measure = "exploitable_abundance", unit = "1000 fish", column = 6L,
       sex = "male", note = "Male exploitable abundance for ages 3+ in thousands of fish."),
  list(type = "population", measure = "male_to_female_exploitable_abundance_ratio", unit = "ratio", column = 7L,
       sex = "", note = "Exploitable male:female abundance ratio as reported in Table 9.")
)
for (spec in table9_specs) {
  add_output(spec$type, spec$measure, table9$values[, spec$column], spec$unit,
    table9$year, sex = spec$sex, table_number = 9L, notes = spec$note)
}
outputs <- do.call(rbind, output_rows)

assumption <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "run_identity", "SEDAR 72 Gulf gag operational assessment, State Reef Fish Survey (SRFS) run; accepted September 2022; data through 2019.",
    "SEDAR 72 operational assessment report amendment; Gulf SSC review; executive summary"),
  assumption("model", "model_family", "Stock Synthesis age-structured operational assessment.",
    "SEDAR 72 final report and SRFS amendment"),
  assumption("population", "age_and_sex_structure", "One Gulf of Mexico area; male and female population components; age bins 0-20+.",
    "SEDAR 72 final report; SRFS amendment Tables 8-9",
    "Age 20 is the plus group. The source output tables provide selected aggregate estimates but not complete N-at-age or F-at-age arrays."),
  assumption("M", "natural_mortality", "Fixed age-specific Lorenzen M scaled to the Then et al. (2015) estimate of 0.159 per year.",
    "SEDAR 72 final report, biology tables"),
  assumption("maturity", "maturity_structure", "Female maturity is a fixed logistic curve; males and transitioning fish are treated as mature.",
    "SEDAR 72 final report, biology tables"),
  assumption("biology", "growth_and_weight", "The SRFS run retains the SEDAR 72 base assessment growth and fixed sex-combined length-weight relationship.",
    "SEDAR 72 final report; SRFS amendment"),
  assumption("timing", "annual_process", "Annual model with removals and data collection treated as continuous and homogeneous through the year.",
    "SEDAR 72 final report",
    "A single within-year sampling fraction for the aggregate abundance indices was not reported."),
  assumption("output", "spawning_stock_definition", "SSB is spawning stock biomass in metric tons; Table 8 also reports SSB/SSB0 with SSB0 = 67,045 metric tons.",
    "SEDAR 72 SRFS amendment, Table 8"),
  assumption("uncertainty", "reported_output_uncertainty", "The imported Tables 6-9 report point estimates without age-specific or annual output intervals.",
    "SEDAR 72 SRFS amendment, Tables 6-9")
))

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10348",
  scientific_name = "Mycteroperca microlepis", common_name = "Gag - Gulf of Mexico",
  area = "Gulf of Mexico", region = "United States Gulf of Mexico",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10348; distinct from the South Atlantic gag assessment unit.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2022L, terminal_year = 2019L,
  estimate_terminal_year = 2019L, assessment_type = "operational_assessment",
  model_family = "Stock Synthesis",
  model_version = "SEDAR 72 SRFS operational assessment run; accepted September 2022",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = assessment_url,
  framework_url = "https://sedarweb.org/assessments/sedar-72/",
  data_url = "https://sedarweb.org/assessments/sedar-72/",
  model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "not_started", outputs_status = "partial",
  notes = paste("The Gulf SSC accepted the SRFS run as best scientific information for advice in September 2022.",
    "NOAA still identifies SEDAR 72 as the most recent population assessment in its 2026 notice; SEDAR 105 is underway.",
    "This initial source import covers selected aggregate outputs only; no N-at-age or F-at-age arrays are available in the recovered tables."))

candidates_path <- file.path(root, "discovery/candidates.csv")
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
candidate_row <- which(candidates$candidate_id == candidate_id)
existing_stocks <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
existing_assessments <- read.csv(file.path(root, "database/assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
if (length(candidate_row) != 1L || candidates$candidate_unit_id[candidate_row] != stock_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started" ||
    any(existing_stocks$stock_id == stock_id) ||
    any(existing_stocks$authority_stock_id == "10348" & existing_stocks$authority == "NOAA Fisheries") ||
    any(existing_assessments$assessment_id == assessment_id)) {
  stop("Gulf gag identity conflicts with the eligible candidate or canonical database.", call. = FALSE)
}

inventory_path <- file.path(root, "discovery/inventory_units.csv")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
inputs <- pacific_database_row("inputs", n = 0L)

if (nrow(outputs) != 1197L || any(!is.finite(outputs$value)) ||
    anyDuplicated(paste(outputs$type, outputs$measure, outputs$year, outputs$sex,
      outputs$fleet, outputs$age, sep = "|")) ||
    !identical(as.integer(table6$year), years) || !identical(as.integer(table7$year), years) ||
    !identical(as.integer(table8$year), years) || !identical(as.integer(table9$year), years)) {
  stop("Gulf gag output tables failed expected coverage, value, or uniqueness checks.", call. = FALSE)
}

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Tables 6-9 from the 2022 SRFS amendment are now imported: annual exploitation rates, biomass, SSB, exploitable abundance, age-0 recruitment, SSB/SSB0, and sex-specific SSB, biomass and abundance. No N-at-age/F-at-age arrays or output intervals are available.")
  replace_candidate_register_row(candidates_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(outputs),
    " output rows from SEDAR 72 Tables 6-9, and no input rows. Use --write to import the outputs.")
}
