root <- "."
stock_id <- "noaa_greater_amberjack_south_atlantic"
assessment_id <- "noaa_greater_amberjack_south_atlantic_sedar59_2020"
candidate_id <- "NOAA:10208"
report_url <- "https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=5755"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache_options <- c(
  file.path("source_cache", "discovery_noaa_south_atlantic_greater_amberjack_2020"),
  file.path("..", "..", "discovery_noaa_south_atlantic_greater_amberjack_2020")
)
source_dir <- cache_options[
  vapply(cache_options, function(path) file.exists(file.path(path, "sources.csv")), logical(1))
][1L]
if (is.na(source_dir)) stop("Could not find the shared SEDAR 59 source cache.", call. = FALSE)

manifest_path <- file.path("provenance", "discovery_noaa_greater_amberjack_south_atlantic_2020", "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE,
  colClasses = "character")

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result, value = TRUE)))
  if (length(hashes) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hashes
}

verify_source <- function(name) {
  record <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_dir, name)
  if (nrow(record) != 1L || !file.exists(path) ||
      as.numeric(record$bytes) != file.info(path)$size ||
      !identical(sha256_file(path), tolower(record$sha256))) {
    stop("Cached source differs from its pinned provenance: ", name, call. = FALSE)
  }
  path
}

report_path <- verify_source("SEDAR59_final_SAR.pdf")
wp05_path <- verify_source("SEDAR59_WP05_commercial_age_compositions.pdf")
report_text_path <- sub("\\.pdf$", ".txt", report_path, ignore.case = TRUE)
wp05_text_path <- sub("\\.pdf$", ".txt", wp05_path, ignore.case = TRUE)
if (!file.exists(report_text_path) || !file.exists(wp05_text_path)) {
  stop("Create local text extracts beside the cached SEDAR 59 PDFs before importing.", call. = FALSE)
}
report_lines <- readLines(report_text_path, warn = FALSE, encoding = "UTF-8")
wp05_lines <- readLines(wp05_text_path, warn = FALSE, encoding = "UTF-8")

# Extract the published tables
parse_numeric_line <- function(line) {
  line <- gsub("([0-9])[[:space:]]+\\.[[:space:]]*([0-9]+)", "\\1.\\2", line, perl = TRUE)
  tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
  tokens[tokens %in% c(".", "...", "–", "—")] <- NA_character_
  suppressWarnings(as.numeric(tokens))
}

table_lines <- function(lines, title) {
  starts <- which(grepl(title, lines, fixed = TRUE))
  if (!length(starts)) stop("Could not find table heading: ", title, call. = FALSE)
  starts <- max(starts)
  next_tables <- which(grepl("^[[:space:]]*Table[[:space:]]+[0-9]+\\.", trimws(lines), perl = TRUE))
  next_tables <- next_tables[next_tables > starts]
  end <- if (length(next_tables)) min(next_tables) - 1L else length(lines)
  lines[seq.int(starts + 1L, end)]
}

parse_rows <- function(lines, title, keys, fields, key_pattern) {
  section <- table_lines(lines, title)
  records <- section[grepl(key_pattern, section, perl = TRUE)]
  parsed <- lapply(records, parse_numeric_line)
  keep <- vapply(parsed, function(x) length(x) == fields &&
    is.finite(x[1L]) && x[1L] %in% keys, logical(1L))
  parsed <- parsed[keep]
  if (!length(parsed) || anyDuplicated(vapply(parsed, `[[`, numeric(1L), 1L))) {
    stop("Could not uniquely parse rows for ", title, call. = FALSE)
  }
  result <- do.call(rbind, parsed)
  result <- result[order(result[, 1L]), , drop = FALSE]
  if (!identical(as.integer(result[, 1L]), as.integer(keys))) {
    stop("Unexpected key coverage in ", title, call. = FALSE)
  }
  result
}

biology <- parse_rows(report_lines,
  "Table 1. Life-history characteristics at age", 1:10, 9L,
  "^[[:space:]]*[0-9]{1,2}[[:space:]]+")
catch <- parse_rows(report_lines,
  "Table 2. Observed time series of landings", 1980:2017, 5L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
catch_cv <- parse_rows(report_lines,
  "Table 3. Landings (L) and Discards (D) CVs", 1980:2017, 4L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
indices <- parse_rows(report_lines,
  "Table 4. Observed indices of abundance", 1980:2017, 7L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
n_age <- parse_rows(report_lines,
  "Table 6. Estimated total abundance at age", 1980:2018, 12L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
biomass_age <- parse_rows(report_lines,
  "Table 7. Estimated biomass at age", 1980:2018, 12L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
status <- parse_rows(report_lines,
  "Table 8. Estimated time series and status indicators", 1980:2018, 9L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
f_age <- parse_rows(report_lines,
  "Table 11. Estimated instantaneous", 1980:2017, 11L,
  "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+")
commercial_age_lines <- table_lines(wp05_lines,
  "Table 3.  Weighted age composition for commercial handline")
commercial_records <- commercial_age_lines[grepl("^[[:space:]]*(199[8-9]|20[0-1][0-9])[[:space:]]+",
  commercial_age_lines, perl = TRUE)]
commercial_age <- do.call(rbind, lapply(commercial_records, parse_numeric_line))
if (ncol(commercial_age) != 18L || !identical(as.integer(commercial_age[, 1L]),
    c(1998:2004, 2007:2017)) ||
    any(abs(rowSums(commercial_age[, 4:18, drop = FALSE]) - 1) > 0.002)) {
  stop("SEDAR59-WP05 Table 3 failed year, age-bin, or composition checks.", call. = FALSE)
}

if (any(!is.finite(biology)) || any(!is.finite(n_age)) ||
    any(!is.finite(biomass_age)) || any(!is.finite(f_age)) ||
    !identical(as.integer(catch[, 1L]), 1980:2017) ||
    !identical(as.integer(catch_cv[, 1L]), 1980:2017) ||
    !identical(as.integer(indices[, 1L]), 1980:2017) ||
    !identical(as.integer(n_age[, 1L]), 1980:2018) ||
    !identical(as.integer(biomass_age[, 1L]), 1980:2018) ||
    !identical(as.integer(f_age[, 1L]), 1980:2017) ||
    n_age[1L, 2L] != 1401.81 || n_age[1L, 12L] != 2793.99 ||
    biomass_age[1L, 2L] != 5439.2 || f_age[1L, 2L] != 0.03 ||
    biology[1L, 5L] != 1.76 || biology[10L, 9L] != 0.29) {
  stop("SEDAR 59 source tables failed coverage or value checks.", call. = FALSE)
}

ages <- 1:10
years <- 1980:2018
input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference,
                      year = NA_integer_, age = NA_integer_, age_group = "",
                      fleet = "", survey = "", sex = "", partition = "",
                      sample_size = NA_real_, sampling_time = NA_real_,
                      source_type = "official_table", notes = "") {
  original_n <- length(value)
  keep <- is.finite(as.numeric(value))
  if (!any(keep)) return(invisible(NULL))
  year <- rep_len(year, original_n)[keep]
  age <- rep_len(age, original_n)[keep]
  age_group <- rep_len(age_group, original_n)[keep]
  fleet <- rep_len(fleet, original_n)[keep]
  survey <- rep_len(survey, original_n)[keep]
  sex <- rep_len(sex, original_n)[keep]
  partition <- rep_len(partition, original_n)[keep]
  sample_size <- rep_len(sample_size, original_n)[keep]
  sampling_time <- rep_len(sampling_time, original_n)[keep]
  source_type <- rep_len(source_type, original_n)[keep]
  notes <- rep_len(notes, original_n)[keep]
  value <- value[keep]
  n <- length(value)
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row(
    "inputs", assessment_id = assessment_id, type = rep_len(type, n),
    measure = rep_len(measure, n), basis = rep_len(basis, n),
    fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = rep_len(sex, n),
    year = rep_len(year, n), year_basis = ifelse(is.na(rep_len(year, n)), "", "calendar_year"),
    age = rep_len(age, n), value = value, unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = rep_len(source_type, n),
    source_reference = rep_len(source_reference, n), sample_size = rep_len(sample_size, n),
    partition = rep_len(partition, n), notes = rep_len(notes, n)
  )
}

input_source <- function(table) paste0("SEDAR 59 final SAR, ", table)
input_source_wp05 <- "SEDAR59-WP05, Table 3"
plus_group <- ifelse(ages == 10L, "10+", "")

add_input("catch", "landings_biomass", "biomass", catch[, 2L], "1000 lb whole weight",
  input_source("Table 2"), year = 1980:2017, fleet = "Commercial",
  partition = "landings", notes = "Annual commercial landings as reported; not expanded to age.")
add_input("catch", "landings_numbers", "numbers", catch[, 3L], "1000 fish",
  input_source("Table 2"), year = 1980:2017, fleet = "General recreational",
  partition = "landings", notes = "Annual recreational landings as reported; not expanded to age.")
add_input("catch", "discard_numbers", "numbers", catch[, 4L], "1000 fish",
  input_source("Table 2"), year = 1980:2017, fleet = "Commercial",
  partition = "discards", notes = "Annual commercial discards as reported; age-specific discard composition is unavailable.")
add_input("catch", "discard_numbers", "numbers", catch[, 5L], "1000 fish",
  input_source("Table 2"), year = 1980:2017, fleet = "General recreational",
  partition = "discards", notes = "Annual recreational discards as reported; age-specific discard composition is unavailable.")

add_input("catch", "catch_cv", "relative_scale", catch_cv[, 2L], "ratio",
  input_source("Table 3"), year = 1980:2017, fleet = "General recreational",
  partition = "landings", notes = "CV reported for the assessment ensemble; not a fleet-specific age-composition weight.")
add_input("catch", "catch_cv", "relative_scale", catch_cv[, 3L], "ratio",
  input_source("Table 3"), year = 1980:2017, fleet = "Commercial",
  partition = "landings", notes = "CV reported for the assessment ensemble; the table labels this commercial handline.")
add_input("catch", "catch_cv", "relative_scale", catch_cv[, 4L], "ratio",
  input_source("Table 3"), year = 1980:2017, fleet = "General recreational",
  partition = "discards", notes = "CV reported for the assessment ensemble.")

index_names <- c("Headboat", "Commercial handline", "SERFS video")
index_columns <- c(2L, 4L, 6L)
cv_columns <- c(3L, 5L, 7L)
for (j in seq_along(index_names)) {
  observed <- is.finite(indices[, index_columns[j]])
  add_input("index", "relative_abundance_index", "index_scale",
    indices[observed, index_columns[j]], "relative index",
    input_source("Table 4"), year = indices[observed, 1L],
    survey = index_names[j], notes = "Annual aggregate abundance index; the source report does not specify a single within-year timing fraction.")
  add_input("index", "abundance_index_cv", "relative_scale",
    indices[observed, cv_columns[j]], "ratio", input_source("Table 4"),
    year = indices[observed, 1L], survey = index_names[j],
    notes = "Reported coefficient of variation for the annual aggregate abundance index.")
}

add_input("biology", "growth_length_at_age", "native_covariate", biology[, 2L], "mm",
  input_source("Table 1"), age = ages, age_group = plus_group,
  notes = "Mid-year mean total length; age 10 is the 10+ model group.")
add_input("weight", "weight_at_age", "kg_per_fish", biology[, 5L], "kg/fish",
  input_source("Table 1"), age = ages, age_group = plus_group,
  notes = "Input whole weight at age at mid-year; the report also gives equivalent values in pounds.")
add_input("maturity", "maturity_at_age", "proportion", biology[, 7L], "proportion",
  input_source("Table 1"), age = ages, age_group = plus_group, sex = "female",
  notes = "Input proportion of females mature at age; age 10 is the 10+ model group.")
add_input("biology", "proportion_female_at_age", "proportion", biology[, 8L], "proportion",
  input_source("Table 1"), age = ages, age_group = plus_group,
  notes = "Input female fraction at age; age 10 is the 10+ model group.")
add_input("M", "natural_mortality_at_age", "per_year", biology[, 9L], "per year",
  input_source("Table 1"), age = ages, age_group = plus_group,
  notes = "Fixed age-specific Charnov-curve natural mortality; M was not estimated as a time-varying process.")

composition_values <- as.vector(t(commercial_age[, 4:18, drop = FALSE]))
composition_year <- rep(as.integer(commercial_age[, 1L]), each = 15L)
composition_age <- rep(1:15, times = nrow(commercial_age))
composition_sample <- rep(commercial_age[, 2L], each = 15L)
composition_trips <- rep(commercial_age[, 3L], each = 15L)
add_input("catch", "proportion_at_age", "proportion_numbers", composition_values,
  "proportion", input_source_wp05, year = composition_year, age = composition_age,
  fleet = "Commercial handline", sample_size = composition_sample,
  notes = paste0("Weighted age proportion from WP05 Table 3; n.fish is retained in sample_size and n.trips is ",
    composition_trips, ". Original source bins 1-15 are retained; the BAM model uses ages 1-10+ and this source-series aggregation is not applied here."))

inputs <- do.call(rbind, input_rows)

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, year,
                       age = NA_integer_, age_group = "", source_type = "official_table",
                       notes = "") {
  n <- length(value)
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row(
    "outputs", assessment_id = assessment_id, type = rep_len(type, n),
    measure = rep_len(measure, n), fleet = "", survey = "", sex = "", region = "", season = "",
    year = rep_len(year, n), age = rep_len(age, n), age_group = rep_len(age_group, n),
    value = value, se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = rep_len(unit, n),
    source_type = rep_len(source_type, n), source_reference = rep_len(source_reference, n),
    notes = rep_len(notes, n), scenario = ""
  )
}

long_age <- function(table, measure, type, unit, reference, years, notes) {
  values <- as.vector(t(table[, 2:11, drop = FALSE]))
  ages <- rep(1:10, times = length(years))
  age_groups <- ifelse(ages == 10L, "10+", "")
  add_output(type, measure, values, unit, reference,
    year = rep(years, each = 10L), age = ages, age_group = age_groups, notes = notes)
}

output_ref <- function(table) paste0("SEDAR 59 final SAR, ", table)
long_age(n_age, "numbers_at_age", "population", "1000 fish", output_ref("Table 6"),
  years, "Estimated abundance at start of year; age 10 is the 10+ model group. No age-specific uncertainty is tabulated.")
add_output("population", "total_numbers", n_age[, 12L], "1000 fish", output_ref("Table 6"),
  years, notes = "Official total column for abundance at start of year.")
add_output("recruitment", "recruitment", n_age[, 2L], "1000 fish", output_ref("Table 6"),
  years, age = 1L, notes = "Age-1 abundance at start of year, the assessment model's recruitment age; copied from Table 6.")
long_age(biomass_age, "biomass_at_age", "biomass", "1000 lb", output_ref("Table 7"),
  years, "Estimated biomass at age at start of year; age 10 is the 10+ model group.")
long_age(f_age, "fishing_mortality_at_age", "mortality", "per year", output_ref("Table 11"),
  1980:2017, "Estimated instantaneous fishing mortality at age; age 10 is the 10+ model group.")
add_output("mortality", "apical_F", status[1:38, 2L], "per year", output_ref("Table 8"),
  1980:2017, notes = "Estimated annual apical instantaneous fishing mortality.")
add_output("mortality", "F_ratio_to_Fmsy", status[1:38, 3L], "ratio", output_ref("Table 8"),
  1980:2017, notes = "Source-reported annual apical F divided by Fmsy.")
add_output("biomass", "total_biomass", status[, 4L], "metric tons", output_ref("Table 8"),
  years, notes = "Estimated total biomass at start of year; the 2018 estimate is reported without F or SSB.")
add_output("biomass", "B_ratio_to_unfished", status[, 5L], "ratio", output_ref("Table 8"),
  years, notes = "Source-reported total biomass relative to unfished biomass.")
add_output("biomass", "SSB", status[1:38, 6L], "metric tons", output_ref("Table 8"),
  1980:2017, notes = "Mature-female spawning biomass at peak spawning in mid-April.")
add_output("biomass", "SSB_ratio_to_SSBMSY", status[1:38, 7L], "ratio", output_ref("Table 8"),
  1980:2017, notes = "Source-reported SSB relative to SSBmsy.")
add_output("biomass", "SSB_ratio_to_MSST", status[1:38, 8L], "ratio", output_ref("Table 8"),
  1980:2017, notes = "Source-reported SSB relative to MSST.")
add_output("biology", "proportion_female_age2plus", status[, 9L], "proportion", output_ref("Table 8"),
  years, notes = "Source-reported female fraction of the age-2+ population.")
outputs <- do.call(rbind, output_rows)

assumption <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "run_identity", "SEDAR 59 final South Atlantic greater amberjack assessment; data through 2017.",
    "SEDAR 59 final SAR, report summary and Table 1"),
  assumption("model", "model_family", "Beaufort Assessment Model (BAM)",
    "SEDAR 59 final SAR, Section 2.2", "No native fitted BAM object was located in the reviewed public sources."),
  assumption("population", "years_ages_and_sexes", "1980-2017 fitted data; ages 1-10+; both-sex abundance and female spawning biomass.",
    "SEDAR 59 final SAR, Sections 2.2.6-2.2.7 and Tables 1, 6-8", "Age 10 is the accumulation plus group."),
  assumption("catch", "fleet_structure", "Commercial and general recreational landings and discards.",
    "SEDAR 59 final SAR, Tables 2-3", "Commercial landings are biomass; recreational landings and both discard series are numbers. Age-specific discard compositions were not found."),
  assumption("catch", "landings_discard_uncertainty", "Table 3 reports landings and discard CVs used in the assessment ensemble.",
    "SEDAR 59 final SAR, Table 3", "The table contains general-recreational landings, commercial handline landings and general-recreational discards; it does not report a commercial discard CV."),
  assumption("composition", "commercial_age_bins", "Weighted commercial handline age compositions are available for 1998-2004 and 2007-2017 in source bins 1-15.",
    "SEDAR59-WP05, Table 3", "The model uses ages 1-10+; the canonical inputs retain the published 1-15 bins. 2016 and 2017 did not meet stated minimum sample-size thresholds, but the report describes their inclusion as a sensitivity; the table values are preserved as published."),
  assumption("composition", "recreational_age_bins", "Weighted recreational age compositions are plotted but not tabulated.",
    "SEDAR59-WP11, Figures 3-4; SEDAR 59 final SAR, Figure 3", "Numeric values are not imported or digitized."),
  assumption("index", "abundance_series", "Headboat 1980-2017, commercial handline 1993-2017, and SERFS video 2011-2017 annual relative indices with CVs.",
    "SEDAR 59 final SAR, Table 4", "The annual table does not specify a single within-year observation fraction."),
  assumption("biology", "weight_maturity_sex_ratio", "Mid-year whole weight, female maturity and female fraction by age are fixed inputs.",
    "SEDAR 59 final SAR, Table 1", "Age 10 represents the 10+ group."),
  assumption("M", "natural_mortality", "Fixed age-specific M from a Charnov curve based on updated growth information.",
    "SEDAR 59 final SAR, Table 1 and Section 2.2.7", "M is not estimated as a time-varying process."),
  assumption("index", "observation_timing", "No single within-year timing fraction is specified for the aggregate indices.",
    "SEDAR 59 final SAR, Table 4 and index working papers", "The source documents retain distinct seasonal structures for each index."),
  assumption("output", "biomass_definitions", "Total biomass is start-of-year biomass in metric tons; SSB is mature-female biomass at peak spawning in mid-April.",
    "SEDAR 59 final SAR, Table 8"),
  assumption("output", "estimate_terminal_year", "Population estimates extend to 2018 although fitted observations end in 2017.",
    "SEDAR 59 final SAR, Tables 6-8", "2018 total biomass is reported; F and SSB are not tabulated for 2018."),
  assumption("uncertainty", "reported_output_uncertainty", "Tables 6-8 and 11 provide point estimates only.",
    "SEDAR 59 final SAR, Tables 6-8 and 11", "No corresponding annual output intervals or standard errors are transcribed here.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10208",
  scientific_name = "Seriola dumerili", common_name = "South Atlantic greater amberjack",
  area = "South Atlantic U.S. EEZ within South Atlantic Fishery Management Council jurisdiction",
  region = "United States South Atlantic", ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10208; distinct from Gulf of Mexico greater amberjack (NOAA:10207). No verified Charbonneau-Keith Master match.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2020L, terminal_year = 2017L,
  estimate_terminal_year = 2018L, assessment_type = "assessment",
  model_family = "Beaufort Assessment Model",
  model_version = "SEDAR 59 operational assessment",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = report_url,
  framework_url = "https://www.fisheries.noaa.gov/s3/2024-01/GAJ-Framework-Action-508-FINAL.pdf",
  data_url = "https://sedarweb.org/assessments/sedar-59/", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Latest completed detailed assessment located for NOAA:10208.",
    "Tables 1-4 and WP05 commercial compositions, plus Tables 6-8 and 11, are captured.",
    "Recreational age-composition vectors and age-specific discards remain unavailable;",
    "no model object or tabulated output uncertainty was found."))

existing_stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
existing_assessments <- read.csv(file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidates_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || candidates$candidate_unit_id[candidate_row] != stock_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    any(existing_stocks$stock_id == stock_id) ||
    any(existing_assessments$assessment_id == assessment_id)) {
  stop("The candidate identity conflicts with the register or canonical database.", call. = FALSE)
}
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)

if (nrow(stock) != 1L || nrow(assessment) != 1L || nrow(inputs) != 714L ||
    nrow(outputs) != 1545L || nrow(assumptions) != 14L ||
    any(!is.finite(as.numeric(inputs$value))) || any(!is.finite(as.numeric(outputs$value))) ||
    anyDuplicated(paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey,
      inputs$year, inputs$age, inputs$partition, sep = "|")) ||
    anyDuplicated(paste(outputs$type, outputs$measure, outputs$year, outputs$age, sep = "|"))) {
  message("rows: stock=", nrow(stock), ", assessment=", nrow(assessment),
    ", assumptions=", nrow(assumptions), ", inputs=", nrow(inputs),
    ", outputs=", nrow(outputs), "; duplicate inputs=",
    anyDuplicated(paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey,
      inputs$year, inputs$age, inputs$partition, sep = "|")),
    "; duplicate outputs=", anyDuplicated(paste(outputs$type, outputs$measure,
      outputs$year, outputs$age, sep = "|")))
  stop("Greater amberjack import rows failed dimensions, finiteness, or uniqueness checks.", call. = FALSE)
}

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$decision_reason[candidate_row] <- paste(
    "Imported verified SEDAR 59 Table 1-4 inputs, WP05 commercial handline age proportions,",
    "and Tables 6-8 and 11 point outputs. Recreational age proportions, age-specific discards,",
    "and output uncertainty remain source gaps."
  )
  candidates$notes[candidate_row] <- paste(
    "The 2020 SEDAR 59 assessment is the latest completed detailed run located for this current unit.",
    "The canonical record is partial; no recreational age-composition values were digitized or invented."
  )
  replace_candidate_register_row(candidates_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id)

  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs, and ",
    nrow(outputs), " outputs parsed. Use --write to append the source records.")
}
