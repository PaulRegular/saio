root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- Sys.getenv("SAIO_DATABASE_DIR", "database")
if (!grepl("^(?:[A-Za-z]:|/)", database)) database <- file.path(root, database)
database <- normalizePath(database, winslash = "/", mustWork = TRUE)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
options(scipen = 999)

stock_id <- "noaa_atlantic_menhaden"
assessment_id <- "noaa_atlantic_menhaden_2025"
candidate_id <- "NOAA:11089"
assessment_url <- "https://asmfc.org/wp-content/uploads/2025/11/2025AtlMenhadenSingleSpeciesAssmtUpdate_October2025.pdf"
framework_url <- "https://sedarweb.org/documents/sedar102-rd-03-sedar-69-benchmark-stock-assessment-report/"
manifest_path <- file.path(root, "data-raw/provenance", assessment_id, "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
manifest$file <- gsub("\\\\", "/", manifest$file)

sha256 <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  tolower(unclass(as.character(openssl::sha256(con))))
}
source_paths <- file.path(root, "source_cache", manifest$cache_folder, manifest$file)
if (!all(c("file", "url", "revision", "retrieved_on", "sha256", "bytes", "cache_folder") %in% names(manifest)) ||
    any(!file.exists(source_paths)) || any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
    !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256, character(1L))))) {
  stop("Atlantic menhaden source files do not match their provenance manifest.", call. = FALSE)
}
report_path <- source_paths[manifest$file == "atlantic_menhaden_update_2025.pdf"]
if (length(report_path) != 1L) stop("Expected one 2025 single-species update in the source manifest.", call. = FALSE)
pages <- pdftools::pdf_text(report_path)
pdf_tokens <- pdftools::pdf_data(report_path)

number <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  value <- suppressWarnings(as.numeric(x))
  if (length(value) != 1L || !is.finite(value)) stop("Unexpected table value: ", x, call. = FALSE)
  value
}
input_columns <- names(read.csv(file.path(database, "inputs.csv"), nrows = 0L, check.names = FALSE))
output_columns <- names(read.csv(file.path(database, "outputs.csv"), nrows = 0L, check.names = FALSE))
assumption_columns <- names(read.csv(file.path(database, "assumptions.csv"), nrows = 0L, check.names = FALSE))

input_row <- function(type, measure, basis, value, unit, source_reference,
  fleet = "", survey = "", sex = "", region = "", year = NA_integer_, age = NA_integer_,
  sampling_time = NA_real_, source_type = "official_table", transformation = "",
  notes = "", observation_id = "", sample_size = NA_real_, partition = "") {
  data.frame(assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = "",
    year = year, year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
    value = value, unit = unit, sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation, notes = notes,
    observation_id = observation_id, length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = sample_size, age_error = "", partition = partition,
    weight_bin = NA_real_, stringsAsFactors = FALSE, check.names = FALSE)
}
output_row <- function(type, measure, value, unit, source_reference, year, notes = "") {
  data.frame(assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = year, age = NA_integer_,
    age_group = "", value = value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = "", stringsAsFactors = FALSE, check.names = FALSE)
}
assumption_row <- function(component, setting, value, source_reference, fleet = "",
  survey = "", sex = "", region = "", notes = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE)
}
inputs_list <- list()
outputs_list <- list()
assumptions_list <- list()
add_input <- function(...) inputs_list[[length(inputs_list) + 1L]] <<- input_row(...)
add_output <- function(...) outputs_list[[length(outputs_list) + 1L]] <<- output_row(...)
add_assumption <- function(...) assumptions_list[[length(assumptions_list) + 1L]] <<- assumption_row(...)

# Table A1: preserve source catch components and the model's bait-fleet pooling.
landings_rows <- list()
for (page in 51:52) {
  z <- pdf_tokens[[page]]
  year_tokens <- z[grepl("^(19|20)[0-9]{2}$", z$text) & z$x >= 70 & z$x <= 105, , drop = FALSE]
  for (j in seq_len(nrow(year_tokens))) {
    year <- as.integer(year_tokens$text[j])
    if (!year %in% 1955:2023) next
    row <- z[abs(z$y - year_tokens$y[j]) <= 1, , drop = FALSE]
    get_cell <- function(low, high) {
      cell <- row[row$x >= low & row$x < high & grepl("^[0-9]+(?:\\.[0-9]+)?$", row$text, perl = TRUE), , drop = FALSE]
      if (!nrow(cell)) return(NA_real_)
      if (nrow(cell) != 1L) stop("Ambiguous Atlantic menhaden Table A1 cell in ", year, call. = FALSE)
      number(cell$text)
    }
    values <- c(reduction_north = get_cell(160, 205), reduction_south = get_cell(205, 250),
      bait_north = get_cell(300, 345), bait_south = get_cell(345, 390),
      recreational_north = get_cell(440, 485), recreational_south = get_cell(485, 530))
    if (any(!is.finite(values[1:4]))) stop("Missing Table A1 reduction or bait landings in ", year, call. = FALSE)
    landings_rows[[as.character(year)]] <- values
  }
}
landings <- do.call(rbind, landings_rows)
if (!identical(as.integer(rownames(landings)), 1955:2023))
  stop("Atlantic menhaden Table A1 does not cover 1955-2023.", call. = FALSE)
for (year in 1955:2023) {
  v <- landings[as.character(year), ]
  for (region in c("North", "South")) {
    add_input("catch", "landings_biomass", "biomass", v[paste0("reduction_", tolower(region))],
      "1,000 metric tons", "ASMFC 2025 single-species update, Table A1", fleet = "Reduction",
      region = region, year = year,
      notes = "Source-reported regional commercial reduction landings. Retained on the table's 1,000 metric ton scale.")
    add_input("catch", "landings_biomass", "biomass", v[paste0("bait_", tolower(region))],
      "1,000 metric tons", "ASMFC 2025 single-species update, Table A1", fleet = "Bait",
      region = region, year = year, partition = "commercial_bait",
      notes = if (year < 1985) "Source-reported commercial bait component. The report says bait landings before 1985 are incomplete. Bait and recreational components together form the assessment's bait fleet." else
        "Source-reported commercial bait component. Bait and recreational components together form the assessment's bait fleet.")
    recreational <- v[paste0("recreational_", tolower(region))]
    if (!is.na(recreational)) add_input("catch", "landings_biomass", "biomass", recreational,
      "1,000 metric tons", "ASMFC 2025 single-species update, Table A1", fleet = "Bait",
      region = region, year = year, partition = "recreational_added_to_bait",
      notes = "Source-reported recreational landings. The report says recreational harvest is added to the assessment's bait landings; stored as a component of that fleet, not as a fifth fleet.")
  }
}

# Tables A2-A5: age proportions and raw counts of sampled fish.
doc_lines <- trimws(unlist(strsplit(paste(pages, collapse = "\n"), "\n", fixed = TRUE)))
extract_age_table <- function(table_number, years, fleet, region) {
  heading <- paste0("^Table A", table_number, "\\.")
  starts <- grep(heading, doc_lines, perl = TRUE)
  starts <- starts[!grepl("Continued", doc_lines[starts], fixed = TRUE)]
  start <- if (length(starts)) tail(starts, 1L) else NA_integer_
  if (is.na(start)) stop("Missing Atlantic menhaden Table A", table_number, call. = FALSE)
  next_heading <- paste0("^Table A", table_number + 1L, "\\.")
  later <- grep(next_heading, doc_lines, perl = TRUE)
  later <- later[later > start]
  end <- if (length(later)) min(later) else length(doc_lines) + 1L
  lines <- doc_lines[seq.int(start + 1L, end - 1L)]
  data_lines <- lines[grepl("^(19|20)[0-9]{2}\\*?\\s", lines, perl = TRUE)]
  data_lines <- data_lines[vapply(data_lines, function(line) {
    year <- suppressWarnings(as.integer(sub("\\*.*$", "", strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]][1L])))
    !is.na(year) && year %in% years
  }, logical(1L))]
  parsed <- lapply(data_lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
    year <- as.integer(sub("\\*$", "", fields[1L]))
    nums <- if (length(fields) > 1L) vapply(fields[-1L], number, numeric(1L)) else numeric()
    if (length(nums) == 8L) return(list(year = year, proportions = nums[1:7], count = nums[8L]))
    if (length(nums) == 1L && nums[1L] == 0) return(list(year = year, proportions = NULL, count = 0))
    stop("Unexpected row structure in Atlantic menhaden Table A", table_number,
      " year ", year, ": ", line, call. = FALSE)
  })
  parsed <- parsed[vapply(parsed, function(x) x$year %in% years, logical(1L))]
  found_years <- vapply(parsed, `[[`, integer(1L), "year")
  if (!identical(as.integer(found_years), as.integer(years)))
    stop("Unexpected year coverage in Atlantic menhaden Table A", table_number, call. = FALSE)
  for (x in parsed) {
    obs_id <- paste0("A", table_number, "_", gsub("[^A-Za-z0-9]+", "_", fleet), "_", region, "_", x$year)
    add_input("catch", "composition_sample_count", "numbers", x$count, "fish",
      paste0("ASMFC 2025 single-species update, Table A", table_number), fleet = fleet,
      region = region, year = x$year, observation_id = obs_id,
      notes = "Raw number of fish sampled for the reported age composition; not identified as an effective likelihood sample size.")
    if (is.null(x$proportions)) next
    for (age in 0:6) add_input("catch", "proportion_at_age", "proportion_numbers", x$proportions[age + 1L],
      "proportion", paste0("ASMFC 2025 single-species update, Table A", table_number),
      fleet = fleet, region = region, year = x$year, age = age, observation_id = obs_id,
      sample_size = NA_real_,
      notes = paste0("Source-reported catch age proportion by number; age 6 is the 6+ group. The raw fish count is stored separately; sample_size is left blank because the report does not identify an effective composition likelihood sample size.",
        if (table_number == 5L && x$year == 2020L) " The 2025 report states the 2020 south bait composition was censored from the base run; table values are retained as reported, not asserted to be fitted.", ""))
  }
}
extract_age_table(2L, 1955:2023, "Reduction", "North")
extract_age_table(3L, 1955:2023, "Reduction", "South")
extract_age_table(4L, 1985:2023, "Bait", "North")
extract_age_table(5L, 1985:2023, "Bait", "South")

# Table A6: the four Conn aggregate abundance indices and source CVs.
index_specs <- data.frame(
  code = c("YOY", "NAD", "MAD", "SAD"),
  survey = c("Conn YOY", "Conn NAD", "Conn MAD", "Conn SAD"),
  region = c("Coastwide", "North", "Mid-Atlantic", "South"),
  value_low = c(115, 211, 301, 401), value_high = c(160, 255, 350, 450),
  cv_low = c(161, 256, 351, 451), cv_high = c(210, 300, 400, 500),
  years = I(list(1959:2023, 1990:2023, 1985:2023, 1990:2023)),
  stringsAsFactors = FALSE)
index_years <- vector("list", nrow(index_specs))
for (page in 59:60) {
  z <- pdf_tokens[[page]]
  year_tokens <- z[grepl("^(19|20)[0-9]{2}$", z$text) & z$x >= 70 & z$x <= 105, , drop = FALSE]
  for (j in seq_len(nrow(year_tokens))) {
    year <- as.integer(year_tokens$text[j])
    row <- z[abs(z$y - year_tokens$y[j]) <= 1, , drop = FALSE]
    for (k in seq_len(nrow(index_specs))) {
      spec <- index_specs[k, ]
      if (!year %in% spec$years[[1L]]) next
      parse_cell <- function(low, high) {
        cell <- row[row$x >= low & row$x < high & grepl("^[0-9]+(?:\\.[0-9]+)?$", row$text, perl = TRUE), , drop = FALSE]
        if (!nrow(cell)) return(NA_real_)
        if (nrow(cell) != 1L) stop("Ambiguous Atlantic menhaden Table A6 cell in ", year, call. = FALSE)
        number(cell$text)
      }
      value <- parse_cell(spec$value_low, spec$value_high)
      cv <- parse_cell(spec$cv_low, spec$cv_high)
      if (xor(is.na(value), is.na(cv))) stop("Incomplete Conn index/CV pair for ", spec$code, " ", year, call. = FALSE)
      if (is.na(value)) next
      index_years[[k]] <- c(index_years[[k]], year)
      add_input("index", "relative_abundance_index", "index_scale", value,
        "Conn index (source scale)", "ASMFC 2025 single-species update, Table A6",
        survey = spec$survey, region = spec$region, year = year,
        notes = "Aggregate abundance index from the Conn method. No physical unit or scaling multiplier is stated; the source index is retained without conversion. Fractional within-year timing is not reported for this combined index.")
      add_input("index", "abundance_index_cv", "relative_scale", cv, "ratio",
        "ASMFC 2025 single-species update, Table A6", survey = spec$survey,
        region = spec$region, year = year,
        notes = "Source-reported CV for the matching aggregate Conn index; not an absolute standard error.")
    }
  }
}
expected_index_years <- lapply(index_specs$years, as.integer)
if (!identical(index_years, expected_index_years))
  stop("Unexpected Atlantic menhaden Table A6 index year coverage.", call. = FALSE)

# Table 2: fixed age-varying M for the 2025 base run.
m_values <- c(1.39, 1.03, 0.82, 0.71, 0.64, 0.60, 0.57)
for (age in 0:6) add_input("M", "natural_mortality_at_age", "per_year", m_values[age + 1L], "yr-1",
  "ASMFC 2025 single-species update, Table 2", age = age,
  notes = if (age == 6L) "Fixed 2025 base-run M; age 6 represents the 6+ group." else
    "Fixed age-specific 2025 base-run natural mortality, revised using the tagging-based estimate.")

# Table A7: survey process-error SDs used to form the Conn indices.
sigma_rows <- data.frame(
  group = c(rep("Age 1+", 15L), rep("YOY", 9L)),
  survey = c("CT Long Island Sound Trawl", "DE Adult Trawl", "NJ Ocean Trawl",
    "MD Striped Bass Spring Gill Net", "VIMS Shad and River Herring Monitoring",
    "NC Program 915 Pamlico Sound Gill Net", "SEAMAP", "GA Ecological Monitoring Trawl",
    "RI Coastal Trawl", "CT River Juvenile Alosine Seine", "CT Thames River Seine",
    "CT Long Island Sound Trawl", "NY Peconic Bay Small Mesh Trawl",
    "NY Western Long Island Seine", "NY Juvenile Striped Bass Beach Seine",
    "NJ Ocean Trawl", "NJ Delaware River Striped Bass Seine", "DE Inland Bays",
    "MD Coastal Bays Trawl", "MD Juvenile Striped Bass Seine",
    "VIMS Juvenile Fish and Blue Crab Trawl", "VIMS Juvenile Striped Bass Seine",
    "NC Program 120 Estuarine Trawl", "SC Electrofishing"),
  sigma_p = c(1.20, 0.60, 0.80, 2.10, 0.20, 0.50, 0.50, 0.90, 2.90, 2.70, 3.20,
    1.70, 2.20, 3.00, 2.10, 1.90, 1.60, 4.90, 4.50, 1.50, 1.30, 1.30, 1.00, 0.90),
  stringsAsFactors = FALSE)
sigma_rows$source_survey <- sigma_rows$survey
sigma_rows$survey[1L] <- "CT Long Island Sound Trawl (first Table A7 entry)"
sigma_rows$survey[12L] <- "CT Long Island Sound Trawl (second Table A7 entry)"
for (j in seq_len(nrow(sigma_rows))) add_assumption("index", "Conn_component_process_sd",
  as.character(sigma_rows$sigma_p[j]), "ASMFC 2025 single-species update, Table A7",
  survey = paste(sigma_rows$group[j], sigma_rows$survey[j], sep = " - "),
  notes = paste0("2025-update sigma_p: process-error SD for this component survey in the Conn index model. The report does not state a physical unit; this is not the aggregate index CV. Source survey label: ", sigma_rows$source_survey[j], if (j %in% c(1L, 12L)) paste0(". Table A7 prints this label twice in the Age 1+ section; this is entry ", ifelse(j == 1L, "1", "12"), ", and the report does not explain the distinction.") else ""))

for (x in list(
  assumption_row("population", "model_domain", "1955-2023; ages 0-6+", "ASMFC 2025 single-species update, Table 2", notes = "The source reports a terminal age group of 6+."),
  assumption_row("population", "model_family", "Beaufort Assessment Model (BAM), single-species catch-at-age update", "ASMFC 2025 single-species update, assessment description"),
  assumption_row("population", "fleet_structure", "Four fleets: north/south commercial reduction and north/south bait", "ASMFC 2025 single-species update, Table 2"),
  assumption_row("population", "fishing_year_start", "March 1", "ASMFC 2025 single-species update, methods"),
  assumption_row("biology", "sex_ratio", "Fixed 1:1 male:female", "ASMFC 2025 single-species update, Table 2"),
  assumption_row("M", "natural_mortality_treatment", "Fixed age-varying M scaled to the tagging-based estimate; 2025 base-run vector in inputs.csv", "ASMFC 2025 single-species update, Table 2"),
  assumption_row("biology", "maturity", "Time-varying maturity-at-age based on length-at-age", "ASMFC 2025 single-species update, Table 2", notes = "Numerical updated arrays for 2018-2023 were not located."),
  assumption_row("biology", "fecundity", "Time-varying fecundity-at-age; 2025 update revised information using VIMS data", "ASMFC 2025 single-species update, assessment description", notes = "Numerical updated arrays for 2018-2023 were not located; fecundity is not SSB."),
  assumption_row("index", "index_construction", "Conn hierarchical analysis produces YOY, NAD, MAD and SAD aggregate abundance indices", "ASMFC 2025 single-species update, Tables 1 and A6"),
  assumption_row("index", "survey_timing_fraction", "unknown", "ASMFC 2025 single-species update, Table 1", notes = "Component surveys span different months and seasons; a single fractional timing for each annual aggregate index is not reported."),
  assumption_row("recruitment", "recruitment_process", "unknown", "ASMFC 2025 single-species update", notes = "The reviewed report does not specify the exact recruitment process and variance structure."),
  assumption_row("F", "fishing_mortality_and_selectivity_structure", "unknown", "ASMFC 2025 single-species update", notes = "The reviewed update identifies the BAM and four fleets but does not provide the run-matched numeric parameterization or all selectivity settings."),
  assumption_row("catch", "bait_and_recreational_landings", "Recreational harvest is added to bait landings; regional source components are retained as partitions", "ASMFC 2025 single-species update, fishery-dependent data section and Table A1"),
  assumption_row("catch", "bait_age_compositions", "Age proportions for bait include MRIP recreational catch", "ASMFC 2025 single-species update, Tables A4-A5"),
  assumption_row("index", "survey_age_information", "Base run uses aggregate abundance indices and survey length compositions, not observed survey numbers-at-age", "ASMFC 2025 single-species update, fishery-independent data section", notes = "Updated numeric survey length compositions were not available in the reviewed source package."),
  assumption_row("observation", "composition_effective_sample_sizes", "unknown", "ASMFC 2025 single-species update, Tables A2-A5", notes = "Tables report raw sampled fish counts. The effective likelihood sample sizes and any rescaling are not specified in the retrieved update."),
  assumption_row("population", "native_model_files", "not located", "ASMFC 2025 single-species update and SEDAR 102 document listing", notes = "The concurrent SEDAR 102 ERP assessment is separate and was not substituted for the single-species BAM run.")
)) assumptions_list[[length(assumptions_list) + 1L]] <- x

# Table 4 reports only terminal full F and fecundity; annual curves are not numerical tables.
add_output("mortality", "fishing_mortality_summary", 0.26, "yr-1",
  "ASMFC 2025 single-species update, Table 4", 2023,
  notes = "Source labels this as full fishing mortality for 2023; no age range or uncertainty interval is tabulated.")
add_output("population", "total_egg_production", 1240272, "billion eggs",
  "ASMFC 2025 single-species update, Table 4", 2023,
  notes = "Source-reported fecundity. This is egg production, not biomass-based spawning stock biomass.")

inputs_new <- do.call(rbind, inputs_list)
outputs_new <- do.call(rbind, outputs_list)
assumptions_new <- do.call(rbind, assumptions_list)
inputs_new <- inputs_new[, input_columns, drop = FALSE]
outputs_new <- outputs_new[, output_columns, drop = FALSE]
assumptions_new <- assumptions_new[, assumption_columns, drop = FALSE]

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
stocks_current <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_current <- read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
if (stock_id %in% stocks_current$stock_id || assessment_id %in% assessments_current$assessment_id)
  stop("The Atlantic menhaden stock or assessment has already been imported.", call. = FALSE)

stocks_new <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "ASMFC",
  authority_stock_id = "Atlantic coastwide; NOAA Stock SMART 11089",
  scientific_name = "Brevoortia tyrannus", common_name = "Atlantic menhaden",
  area = "Atlantic coastwide; North and South regions separated at Machipongo Inlet, Virginia",
  region = "Northwest Atlantic coast", ocean = "Northwest Atlantic",
  notes = "The Atlantic States Marine Fisheries Commission manages the coastwide stock; NOAA Stock SMART ID 11089 is retained as a cross-reference. Regional landings and indices are components of one assessment unit.",
  stringsAsFactors = FALSE)
assessments_new_record <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2023L, estimate_terminal_year = 2023L,
  assessment_type = "update", model_family = "Beaufort Assessment Model (BAM)",
  model_version = "2025 single-species update; implementation version not stated",
  is_current = TRUE, is_applied = TRUE, framework_year = 2020L,
  assessment_url = assessment_url, framework_url = framework_url, data_url = "",
  model_url = "", repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "Latest detailed single-species BAM update found, with data through 2023. This is distinct from the concurrent SEDAR 102 ecological reference point benchmark. Imported tables provide landings, catch age proportions and raw sample counts, Conn aggregate indices/CVs, fixed M, and terminal full F/fecundity. Updated biological arrays and numerical population time series remain unavailable.",
  stringsAsFactors = FALSE)

candidate_path <- file.path(database, "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- match(candidate_id, candidates$candidate_id)
if (is.na(candidate_row) || candidates$match_status[candidate_row] != "new" || candidates$import_status[candidate_row] != "not_started")
  stop("The Atlantic menhaden candidate row is not in its reviewed pre-import state.", call. = FALSE)
candidates_new <- candidates[candidate_row, , drop = FALSE]
candidates_new$matched_stock_id <- stock_id
candidates_new$match_status <- "matched"
candidates_new$import_status <- "partial"
candidates_new$eligibility <- "unresolved"
candidates_new$catch_age_evidence <- "Tables A2-A5 import number-based age proportions for reduction and bait fleets, plus raw fish sample counts. Table A1 landings are imported in 1,000 metric tons by region; bait and recreational components are distinguished because the report states recreation is added to the bait fleet. Proportions multiplied by biomass landings would not yield catch numbers-at-age; compatible current-year catch weights are not available."
candidates_new$survey_age_evidence <- "Table A6 aggregate Conn YOY, NAD, MAD and SAD abundance indices and CVs imported. The base run uses aggregate indices and survey length compositions, not observed survey numbers-at-age. Numeric updated survey length compositions and exact fractional survey timing were not recovered."
candidates_new$weights_evidence <- "The 2025 update describes time-varying weight-at-age/length inputs but numeric updated arrays for 2018-2023 were not located; the 2020 benchmark arrays were not substituted into this run."
candidates_new$maturity_evidence <- "2025 update uses time-varying maturity-at-age based on length-at-age; updated numeric arrays for 2018-2023 were not located."
candidates_new$mortality_evidence <- "The fixed 2025 base-run M vector for ages 0-6+ is imported from Table 2."
candidates_new$output_evidence <- "Table 4 supplies 2023 full F (0.26 yr-1) and fecundity (1,240,272 billion eggs). The update shows annual recruitment, age-1+ biomass, fecundity and F mostly as figures; no numerical N-at-age or F-at-age output matrix or BAM fit object was located."
candidates_new$decision_reason <- "Partial canonical records added from the latest detailed English single-species update. Eligibility remains unresolved: actual catch numbers-at-age cannot be reconstructed from number proportions and biomass landings without matching catch weights; updated recent biology, survey timing, and numeric age-specific outputs remain unavailable."
candidates_new$notes <- "The 2025 single-species BAM update is separate from SEDAR 102 ERP. Use 2025 update values only; SEDAR 69 biological arrays through 2017 were not substituted. See data-raw/source_reviews/noaa_atlantic_menhaden.md for source interpretation and gaps."

append_csv <- function(data, path) {
  cols <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  if (!identical(cols, names(data))) stop("Column mismatch while appending ", path, call. = FALSE)
  write.table(data, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
}
if (write_mode) {
  append_csv(stocks_new, stocks_path)
  append_csv(assessments_new_record, assessments_path)
  append_csv(assumptions_new, file.path(database, "assumptions.csv"))
  append_csv(inputs_new, file.path(database, "inputs.csv"))
  append_csv(outputs_new, file.path(database, "outputs.csv"))
  source(file.path(root, "data-raw/scripts/shared/candidate_register_io.R"))
  replace_candidate_register_row(candidate_path, candidate_row, candidates_new, candidate_id)
  cat("Imported NOAA Atlantic menhaden 2025: ", nrow(inputs_new),
    " input rows, ", nrow(outputs_new), " output rows, and ", nrow(assumptions_new),
    " assumption rows.\n", sep = "")
} else {
  cat("Prepared NOAA Atlantic menhaden 2025: ", nrow(inputs_new),
    " input rows, ", nrow(outputs_new), " output rows, and ", nrow(assumptions_new),
    " assumption rows. Use --write to append verified rows.\n", sep = "")
}



