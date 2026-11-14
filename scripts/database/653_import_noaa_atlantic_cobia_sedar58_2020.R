root <- "."
assessment_id <- "noaa_atlantic_cobia_sedar58_2020"
stock_id <- "noaa_atlantic_cobia"
candidate_id <- "NOAA:12149"
candidate_unit_id <- "noaa_cobia_atlantic_2020"
report_url <- "https://sedarweb.org/documents/sedar-58-stock-assessment-report-atlantic-cobia-revised-september-14-2020/"
project_url <- "https://sedarweb.org/assessments/sedar-58/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
test_mode <- identical(Sys.getenv("TAM_SOURCE_TEST_MODE"), "1")
if (write_mode && test_mode) stop("Source test mode cannot write.", call. = FALSE)

cache_name <- "discovery_noaa_sedar_current_assessments_2026"
cache <- file.path(root, "source_cache", cache_name)
pdf_name <- "sedar58_atlantic_cobia_2020.pdf"
pdf_path <- file.path(cache, pdf_name)
text_path <- file.path(cache, "sedar58_atlantic_cobia_2020.pdf.txt")
manifest <- read.csv(file.path(root, "provenance", cache_name, "sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
expected_sha <- "f9444e4f851d3e38e40249be17a20041ced74e8c2a57a1007aed71a461270069"
sha256_file <- function(path) {
  value <- system2("certutil.exe", c("-hashfile",
    shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  value <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    value, value = TRUE)))
  if (length(value) != 1L) stop("Could not hash ", path, call. = FALSE)
  value
}
source_row <- manifest[manifest$file == pdf_name, , drop = FALSE]
if (nrow(source_row) != 1L || !file.exists(pdf_path) ||
    as.numeric(source_row$size_bytes) != file.info(pdf_path)$size ||
    tolower(source_row$sha256) != expected_sha ||
    sha256_file(pdf_path) != expected_sha) {
  stop("Cached SEDAR 58 report differs from the pinned source manifest.", call. = FALSE)
}
if (!file.exists(text_path)) {
  stop("Generate the local SEDAR 58 PDF text extract at ", text_path,
    " before running this importer.", call. = FALSE)
}

text_lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")
page_markers <- grep("^===== PDF PAGE [0-9]+ =====$", text_lines)
page_numbers <- as.integer(sub("^===== PDF PAGE ([0-9]+) =====$",
  "\\1", text_lines[page_markers]))
page_lines <- function(number) {
  i <- match(number, page_numbers)
  if (is.na(i)) stop("SEDAR 58 report extract is missing PDF page ", number, ".")
  first <- page_markers[i] + 1L
  last <- if (i < length(page_markers)) page_markers[i + 1L] - 1L else length(text_lines)
  text_lines[first:last]
}
normalize_decimal_spacing <- function(x) {
  gsub("([0-9])\\s+\\.\\s*([0-9])", "\\1.\\2", x, perl = TRUE)
}
numeric_tokens <- function(x) {
  tokens <- strsplit(trimws(normalize_decimal_spacing(x)),
    "[[:space:]]+")[[1L]]
  values <- suppressWarnings(as.numeric(tokens))
  if (!length(values) || any(!is.finite(values))) {
    stop("Could not parse a numeric SEDAR 58 table row: ", x, call. = FALSE)
  }
  values
}
annual_table <- function(page, n_values, first_year, last_year) {
  result <- list()
  for (line in page_lines(page)) {
    match <- regmatches(line, regexec(
      "^[[:space:]]*([0-9]{4})[[:space:]]+(.*)$", line, perl = TRUE
    ))[[1L]]
    if (!length(match)) next
    year <- as.integer(match[[2L]])
    if (year < first_year || year > last_year) next
    values <- numeric_tokens(match[[3L]])
    if (length(values) != n_values) {
      stop("Unexpected number of values on PDF p. ", page, ", year ", year, ".")
    }
    result[[as.character(year)]] <- values
  }
  expected_years <- seq.int(first_year, last_year)
  if (!identical(as.integer(names(result)), expected_years)) {
    stop("Incomplete year coverage on SEDAR 58 PDF p. ", page, ".")
  }
  matrix <- do.call(rbind, result)
  rownames(matrix) <- as.character(expected_years)
  matrix
}
age_table <- function(page, n_values, first_age, last_age) {
  result <- list()
  for (line in page_lines(page)) {
    match <- regmatches(line, regexec(
      "^[[:space:]]*([0-9]{1,2})[[:space:]]+(.*)$", line, perl = TRUE
    ))[[1L]]
    if (!length(match)) next
    age <- as.integer(match[[2L]])
    if (age < first_age || age > last_age) next
    values <- numeric_tokens(match[[3L]])
    if (length(values) != n_values) stop("Unexpected values in Table 1, age ", age, ".")
    result[[as.character(age)]] <- values
  }
  expected_ages <- seq.int(first_age, last_age)
  if (!identical(as.integer(names(result)), expected_ages)) {
    stop("Incomplete ages in SEDAR 58 Table 1.")
  }
  do.call(rbind, result)
}
sample_table <- function(page) {
  result <- list()
  for (line in page_lines(page)) {
    match <- regmatches(line, regexec(
      "^[[:space:]]*([0-9]{4})[[:space:]]+(.*)$", line, perl = TRUE
    ))[[1L]]
    if (!length(match)) next
    year <- as.integer(match[[2L]])
    if (year < 1986L || year > 2017L) next
    cells <- strsplit(trimws(match[[3L]]), "[[:space:]]+")[[1L]]
    if (length(cells) != 2L) stop("Unexpected sample-size row in Table 5.")
    values <- suppressWarnings(as.numeric(cells))
    values[cells == "."] <- NA_real_
    result[[as.character(year)]] <- values
  }
  if (!identical(as.integer(names(result)), 1986:2017)) {
    stop("Incomplete years in SEDAR 58 Table 5.")
  }
  matrix <- do.call(rbind, result)
  rownames(matrix) <- as.character(1986:2017)
  matrix
}

life_history <- age_table(358L, 8L, 1L, 16L)
removals <- annual_table(359L, 2L, 1986L, 2017L)
catch_components <- annual_table(360L, 10L, 1986L, 2017L)
headboat_index <- annual_table(361L, 2L, 1991L, 2015L)
composition_samples <- sample_table(362L)
numbers_at_age <- annual_table(363L, 17L, 1986L, 2018L)
biomass_at_age <- annual_table(364L, 17L, 1986L, 2018L)
status_series <- annual_table(365L, 9L, 1986L, 2017L)
fully_selected_f <- annual_table(367L, 3L, 1986L, 2017L)
fishing_at_age <- annual_table(368L, 16L, 1986L, 2017L)
landings_numbers_at_age <- annual_table(369L, 16L, 1986L, 2017L)
landings_weight_at_age <- annual_table(370L, 16L, 1986L, 2017L)
landings_numbers <- annual_table(371L, 3L, 1986L, 2017L)
landings_weight <- annual_table(372L, 3L, 1986L, 2017L)

table_ref <- function(number) paste0("SEDAR 58 SAR, Section IV, Table ",
  number, ", p. ", 26L + number, " (PDF p. ", 331L + number, ")")
inputs_list <- list()
outputs_list <- list()
add_input <- function(type, measure, basis, value, unit, source_reference,
    fleet = "", survey = "", sex = "", year = NA_integer_,
    year_basis = "calendar_year", age = NA_integer_, source_type = "official_table",
    transformation = "", notes = "", observation_id = "",
    partition = "", sampling_time = NA_real_, sample_size = NA_real_) {
  inputs_list[[length(inputs_list) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = "", season = "",
    year = year, year_basis = if (is.na(year)) "" else year_basis, age = age,
    value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes, observation_id = observation_id,
    length_bin = "", length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = sample_size, age_error = "", partition = partition,
    weight_bin = "", stringsAsFactors = FALSE
  )
}
add_output <- function(type, measure, value, unit, source_reference,
    year = NA_integer_, age = NA_integer_, fleet = "", survey = "",
    sex = "", scenario = "", notes = "") {
  outputs_list[[length(outputs_list) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = survey, sex = sex, region = "", season = "",
    year = year, age = age, age_group = "", value = value, se = NA_real_,
    lwr = NA_real_, upr = NA_real_, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario,
    stringsAsFactors = FALSE
  )
}

for (age in 1:16) {
  x <- life_history[age, ]
  add_input("biology", "growth_length_at_age", "native_covariate",
    x[1], "mm", table_ref(1), age = age,
    notes = "Total length at mid-year as printed.")
  add_input("biology", "weight_at_age", "kg_per_fish",
    x[4], "kg/fish", table_ref(1), age = age,
    notes = "Whole weight at mid-year; kilograms retained from the table.")
  add_input("maturity", "maturity_at_age", "proportion",
    x[6], "proportion", table_ref(1), sex = "female", age = age)
  add_input("biology", "proportion_female_at_age", "proportion",
    x[7], "proportion", table_ref(1), age = age)
  add_input("M", "natural_mortality_at_age", "per_year",
    x[8], "per year", table_ref(1), age = age,
    notes = "Fixed age-varying natural mortality schedule supplied to the assessment.")
  add_output("biology", "growth_sd_length_at_age", x[3], "ratio",
    table_ref(1), year = 2017L, age = age,
    notes = "Length CV estimated by the assessment; Table 1 identifies it as estimated.")
}

for (year in 1986:2017) {
  x <- catch_components[as.character(year), ]
  add_input("catch", "catch_biomass", "biomass", removals[as.character(year), 1],
    "1000 lb whole weight", table_ref(2), fleet = "Commercial", year = year,
    partition = "landings_and_dead_discards",
    notes = "Combined annual commercial landings and dead discards supplied to the model.")
  add_input("catch", "catch_numbers", "numbers", removals[as.character(year), 2],
    "1000 fish", table_ref(2), fleet = "General recreational", year = year,
    partition = "landings_and_dead_discards",
    notes = "Combined annual general-recreational landings and dead discards supplied to the model.")
  add_input("catch", "landings_numbers", "numbers", x[1], "1000 fish",
    table_ref(3), fleet = "General recreational", year = year,
    partition = "landings")
  add_input("catch", "landings_biomass", "biomass", x[2], "1000 lb whole weight",
    table_ref(3), fleet = "Commercial", year = year, partition = "landings")
  add_input("catch", "discard_biomass", "biomass", x[3], "1000 lb whole weight",
    table_ref(3), fleet = "Commercial", year = year, partition = "handline_discards")
  add_input("catch", "discard_biomass", "biomass", x[4], "1000 lb whole weight",
    table_ref(3), fleet = "Commercial", year = year, partition = "gillnet_dead_discards")
  add_input("catch", "discard_biomass", "biomass", x[5], "1000 lb whole weight",
    table_ref(3), fleet = "Commercial", year = year, partition = "gillnet_live_discards")
  add_input("catch", "discard_numbers", "numbers", x[6], "1000 fish",
    table_ref(3), fleet = "General recreational", year = year, partition = "discard")
  add_input("catch", "discard_biomass", "biomass", sum(x[3:5]),
    "1000 lb whole weight", table_ref(3), fleet = "Commercial", year = year,
    source_type = "reconstructed_source_input",
    transformation = "Sum of the three commercial discard series in Table 3; no discard-mortality adjustment.",
    partition = "discard",
    notes = "Aggregate of Table 3 commercial discard components to match their shared CV; not an independent observation.")
  for (j in 1:4) {
    fleet <- if (j %in% c(1L, 3L)) "General recreational" else "Commercial"
    partition <- if (j %in% c(1L, 2L)) "landings" else "discard"
    add_input("catch", "catch_cv", "relative_scale", x[6L + j], "ratio",
      table_ref(3), fleet = fleet, year = year, partition = partition)
  }
}
for (year in 1991:2015) {
  x <- headboat_index[as.character(year), ]
  add_input("index", "relative_abundance_index", "index_scale", x[1],
    "relative index (mean near 1)", table_ref(4), fleet = "Headboat",
    survey = "Headboat CPUE", year = year,
    observation_id = "sedar58_headboat_cpue_1991_2015",
    notes = "Aggregate index; model predictions use mid-year abundance but exact observation timing is not stated.")
  add_input("index", "abundance_index_cv", "relative_scale", x[2], "ratio",
    table_ref(4), fleet = "Headboat", survey = "Headboat CPUE", year = year,
    observation_id = "sedar58_headboat_cpue_1991_2015")
}
for (year in 1986:2017) {
  x <- composition_samples[as.character(year), ]
  if (is.finite(x[1])) add_input("biology", "composition_sample_count",
    "numbers", x[1], "fish", table_ref(5), fleet = "Commercial",
    year = year, observation_id = "sedar58_commercial_length_composition",
    notes = "Number of fish sampled; not an effective likelihood sample size.")
  if (is.finite(x[2])) add_input("biology", "composition_sample_count",
    "numbers", x[2], "fish", table_ref(5), fleet = "General recreational",
    year = year, observation_id = "sedar58_general_recreational_age_composition",
    notes = "Number of fish sampled; not an effective likelihood sample size.")
}

for (year in 1986:2018) {
  scenario <- if (year == 2018L) "projection_initialization" else ""
  note <- if (year == 2018L) {
    "Start-of-year state used to initialize projections; assessment terminal year is 2017."
  } else {
    "Estimated at the start of the assessment year."
  }
  x <- numbers_at_age[as.character(year), ]
  y <- biomass_at_age[as.character(year), ]
  for (age in 1:16) {
    add_output("population", "numbers_at_age", x[age], "1000 fish",
      table_ref(6), year = year, age = age, scenario = scenario, notes = note)
    add_output("biomass", "biomass_at_age", y[age], "1000 lb whole weight",
      table_ref(7), year = year, age = age, scenario = scenario, notes = note)
  }
  add_output("population", "total_numbers", x[17], "1000 fish", table_ref(6),
    year = year, scenario = scenario, notes = note)
  add_output("biomass", "total_biomass_age_surface", y[17],
    "1000 lb whole weight", table_ref(7), year = year, scenario = scenario,
    notes = note)
  add_output("recruitment", "recruitment", x[1], "1000 age-1 fish",
    table_ref(6), year = year, scenario = scenario,
    notes = "Age-1 abundance from Table 6.")
}
for (year in 1986:2017) {
  x <- status_series[as.character(year), ]
  add_output("mortality", "apical_fishing_mortality", x[1], "per year",
    table_ref(8), year = year, notes = "Apical F, the maximum F at age.")
  add_output("management", "fishing_mortality_ratio_to_F40_percent", x[2],
    "ratio", table_ref(8), year = year)
  add_output("biomass", "total_biomass", x[3], "metric tons", table_ref(8),
    year = year, notes = "At the start of the year.")
  add_output("management", "biomass_ratio_to_unfished_biomass", x[4],
    "ratio", table_ref(8), year = year)
  add_output("biomass", "SSB", x[5], "metric tons", table_ref(8), year = year,
    notes = "Mature female biomass at peak spawning, end of March.")
  add_output("population", "mature_female_numbers", x[6],
    "1000 mature females", table_ref(8), year = year)
  add_output("management", "SSB_ratio_to_SSB_F40_percent", x[7],
    "ratio", table_ref(8), year = year)
  add_output("management", "SSB_ratio_to_MSST_F40_percent", x[8],
    "ratio", table_ref(8), year = year)
  add_output("biology", "proportion_female_age_2_plus", x[9],
    "proportion", table_ref(8), year = year)
  x <- fully_selected_f[as.character(year), ]
  add_output("mortality", "fully_selected_fishing_mortality", x[1],
    "per year", table_ref(10), year = year, fleet = "Commercial")
  add_output("mortality", "fully_selected_fishing_mortality", x[2],
    "per year", table_ref(10), year = year, fleet = "General recreational")
  add_output("mortality", "apical_fishing_mortality_table10", x[3],
    "per year", table_ref(10), year = year,
    notes = "Maximum F at age summed across fleets.")
  for (age in 1:16) {
    add_output("mortality", "fishing_mortality_at_age",
      fishing_at_age[as.character(year), age], "per year", table_ref(11),
      year = year, age = age)
    add_output("catch", "landings_numbers_at_age",
      landings_numbers_at_age[as.character(year), age], "1000 fish",
      table_ref(12), year = year, age = age)
    add_output("catch", "landings_weight_at_age",
      landings_weight_at_age[as.character(year), age], "1000 lb whole weight",
      table_ref(13), year = year, age = age)
  }
  x <- landings_numbers[as.character(year), ]
  add_output("catch", "predicted_landings_numbers", x[1], "1000 fish",
    table_ref(14), year = year, fleet = "Commercial")
  add_output("catch", "predicted_landings_numbers", x[2], "1000 fish",
    table_ref(14), year = year, fleet = "General recreational")
  add_output("catch", "predicted_landings_numbers", x[3], "1000 fish",
    table_ref(14), year = year, notes = "Total across fleets.")
  x <- landings_weight[as.character(year), ]
  add_output("catch", "predicted_landings_weight", x[1], "1000 lb whole weight",
    table_ref(15), year = year, fleet = "Commercial")
  add_output("catch", "predicted_landings_weight", x[2], "1000 lb whole weight",
    table_ref(15), year = year, fleet = "General recreational")
  add_output("catch", "predicted_landings_weight", x[3], "1000 lb whole weight",
    table_ref(15), year = year, notes = "Total across fleets.")
}

table16 <- data.frame(
  type = c("mortality", "biomass", "biomass", "management", "catch",
    "catch", "recruitment", "management", "management", "management"),
  measure = c("F40_percent", "B_F40_percent", "SSB_F40_percent", "MSST",
    "L_F40_percent", "landings_numbers_F40_percent", "R_F40_percent",
    "fishing_mortality_ratio_to_F40_percent",
    "SSB_ratio_to_MSST_F40_percent", "SSB_ratio_to_SSB_F40_percent"),
  unit = c("per year", "metric tons", "metric tons", "metric tons",
    "1000 lb whole weight", "1000 fish", "age-1 fish", "ratio", "ratio",
    "ratio"),
  estimate = c(0.69, 12523, 3507, 2631, 4617, 176.461, 1781121, 0.18,
    2.58, 1.94),
  median = c(0.65, 11028, 3199, 2658, 4010, 151, 1525734, 0.24, 2.41, 1.81),
  ensemble_sd = c(0.19, 9140, 1872, 1007, 3428, 141, 1688, 0.28, 0.51, 0.38),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(table16))) {
  for (statistic in c("estimate", "median", "ensemble_sd")) {
    measure <- paste0(table16$measure[i], "_table16_", statistic)
    add_output(table16$type[i], measure, table16[[statistic]][i],
      table16$unit[i], table_ref(16), year = 2017L,
      notes = if (statistic == "ensemble_sd") {
        "Standard deviation from the ensemble model; not a standard error."
      } else {
        "Summary from Table 16, conditional on estimated selectivities averaged across 2015-2017."
      })
  }
}

inputs <- do.call(rbind, inputs_list)
outputs <- do.call(rbind, outputs_list)
rownames(inputs) <- NULL
rownames(outputs) <- NULL
if (anyDuplicated(inputs[c("type", "measure", "fleet", "survey", "sex",
    "year", "age", "observation_id", "partition")])) {
  stop("Duplicate input keys were created for Atlantic cobia.")
}
if (anyDuplicated(outputs[c("type", "measure", "fleet", "year", "age",
    "scenario")])) {
  stop("Duplicate output keys were created for Atlantic cobia.")
}

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, component = component, fleet = "", survey = "",
    sex = "", region = "", season = "", setting = setting, value = value,
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE
  )
}
add_assumption("assessment", "model_name", "Beaufort Assessment Model (BAM)",
  "SEDAR 58 SAR, Section IV, § 2.3")
add_assumption("assessment", "assessment_period", "1986-2017",
  "SEDAR 58 SAR, Section IV, § 2.3.1")
add_assumption("population", "age_structure",
  "Model description states ages 1-12+; Tables 1 and 6-13 print ages 1-16.",
  "SEDAR 58 SAR, Section IV, § 2.3.1 and Tables 1, 6-13",
  "The report does not reconcile this difference; table age labels are preserved.")
add_assumption("recruitment", "recruitment_process",
  "Age-1 recruitment estimated annually as deviations around an overall average; no stock-recruit relationship.",
  "SEDAR 58 SAR, Section IV, § 2.3.6")
add_assumption("M", "natural_mortality",
  "Fixed over time and decreasing with age using the Charnov et al. (2013) relationship.",
  "SEDAR 58 SAR, Section IV, § 2.3.4 and Table 1")
add_assumption("biology", "maturity_and_spawning",
  "Female maturity schedule from SEDAR 28; peak spawning at mid-June; SSB is mature female biomass at peak spawning.",
  "SEDAR 58 SAR, Section IV, §§ 2.3.5 and 2.3.13, Table 1")
add_assumption("catch", "annual_removals",
  "Commercial removals in 1000 lb whole weight; general-recreational removals in 1000 fish. Removals comprise landings and dead discards.",
  "SEDAR 58 SAR, Section IV, §§ 2.2-2.3.3, Tables 2-3")
add_assumption("observation", "index",
  "The sole abundance index is aggregate headboat CPUE for 1991-2015. Predictions use mid-year abundance; observation timing is not separately reported.",
  "SEDAR 58 SAR, Section IV, §§ 2.3.11-2.3.12, Table 4")
add_assumption("observation", "composition_likelihood",
  "Commercial length compositions and general-recreational age compositions use a Dirichlet-multinomial likelihood with estimated variance-inflation factors.",
  "SEDAR 58 SAR, Section IV, §§ 2.2 and 2.3.14")
add_assumption("observation", "composition_values",
  "Table 5 reports numbers of sampled fish, but numeric annual composition proportions are not tabulated in the report; composition figures are not digitized.",
  "SEDAR 58 SAR, Section IV, Table 5 and Figure 2")
add_assumption("uncertainty", "uncertainty_method",
  "The report uses an ensemble model with Monte Carlo and bootstrap variation; Table 16 reports an estimate, ensemble median, and ensemble standard deviation for summary quantities.",
  "SEDAR 58 SAR, Section IV, § 2.7 and Table 16")
add_assumption("projection", "projection_initialization",
  "Tables 6-7 include start-of-year 2018 abundance and biomass used to initialize projections; assessment terminal year is 2017.",
  "SEDAR 58 SAR, Section IV, § 2.8.1, Tables 6-7")
assumptions <- do.call(rbind, assumption_rows)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA Fisheries",
  authority_stock_id = "12149", scientific_name = "Rachycentron canadum",
  common_name = "Atlantic cobia",
  area = "Atlantic coast north of the Georgia-Florida border",
  region = "United States Atlantic coast", ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 12149. Distinct from Gulf of Mexico cobia (NOAA:10390). SEDAR 58 covers the Atlantic migratory stock north of the Georgia-Florida border.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2020,
  terminal_year = 2017, estimate_terminal_year = 2017,
  assessment_type = "full_assessment", model_family = "Beaufort Assessment Model",
  model_version = "", is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = report_url, framework_url = "", data_url = project_url,
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "SEDAR 58 revised final assessment; the reviewer identifies run co23 as the definitive base run.",
    "Tables 1-5 provide biological inputs, annual removals, catch/discard components, headboat CPUE, and composition sample counts.",
    "Tables 6-16 provide population and fishing outputs, with 2018 retained as projection initialization.",
    "Numeric annual composition proportions and age-specific output uncertainty are not tabulated in the reviewed report."
  ),
  stringsAsFactors = FALSE
)

register_path <- file.path(root, "discovery", "candidates.csv")
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    register$candidate_unit_id[candidate_row] != candidate_unit_id ||
    register$eligibility[candidate_row] != "eligible" ||
    !register$import_status[candidate_row] %in% c("not_started", "partial")) {
  stop("The Atlantic cobia candidate does not uniquely match the selected import.")
}
register$matched_stock_id[candidate_row] <- stock_id
register$match_status[candidate_row] <- "matched"
register$import_status[candidate_row] <- "partial"
register$review_date[candidate_row] <- "2026-11-12"
register$catch_age_evidence[candidate_row] <- paste(
  "SEDAR 58 Tables 2-3 provide annual removals and their commercial/general-recreational landings and discard components.",
  "Table 5 reports fish sample counts for annual recreational age compositions; numerical age-composition proportions are not tabulated."
)
register$survey_age_evidence[candidate_row] <- paste(
  "Table 4 provides aggregate headboat CPUE for 1991-2015.",
  "No age-specific survey index is used or reported; fractional observation timing is not specified."
)
register$weights_evidence[candidate_row] <- paste(
  "Table 1 provides length and whole weight at age for ages 1-16.",
  "The model input table reports weights in kg and lb; kg/fish is preserved."
)
register$maturity_evidence[candidate_row] <- "Table 1 provides female maturity proportions at age; the report identifies SEDAR 28 values as the input schedule."
register$mortality_evidence[candidate_row] <- "Table 1 provides the fixed age-varying natural mortality schedule based on Charnov et al. (2013)."
register$output_evidence[candidate_row] <- paste(
  "Tables 6-8 and 10-16 report abundance and biomass at age, SSB, apical and age-specific F, landings, and reference-point summaries through 2017.",
  "Table 16 includes ensemble medians and standard deviations; age-specific uncertainty is not tabulated."
)
register$notes[candidate_row] <- paste(
  "Partial source import completed from the revised SEDAR 58 report and co23 review.",
  "Assessment terminal year is 2017; 2018 N/B values in Tables 6-7 are projection initialization.",
  "The report's model-age text states 1-12+, while table headers print ages 1-16; the discrepancy is retained."
)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- candidate_inventory_row(inventory, candidate_id, candidate_unit_id)
if (!inventory$import_status[inventory_row] %in% c("not_started", "partial")) {
  stop("The Atlantic cobia inventory unit has an unexpected import status.")
}
inventory$import_status[inventory_row] <- "partial"
if ("matched_stock_id" %in% names(inventory)) {
  inventory$matched_stock_id[inventory_row] <- stock_id
}
selected_path <- file.path(root, "discovery", "selected_batch_37_2026.csv")
selected <- read.csv(selected_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L ||
    selected$curation_status[selected_row] != "selected") {
  stop("Atlantic cobia must have one selected-batch row before import.")
}
selected$curation_status[selected_row] <- "partial_source_import"
selected$selection_basis[selected_row] <- paste(
  selected$selection_basis[selected_row],
  "Source tables have been imported; numerical age-composition cells remain unavailable."
)

append_rows <- function(file, data) {
  path <- file.path(root, "database", file)
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  if (!identical(names(data), columns)) stop("Column mismatch in database/", file)
  connection <- file(path, open = "rb")
  seek(connection, where = -1L, origin = "end")
  last_byte <- readBin(connection, "raw", n = 1L)
  close(connection)
  if (length(last_byte) && !identical(last_byte, as.raw(10L))) {
    cat("\n", file = path, append = TRUE)
  }
  write.table(data, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", append = TRUE, qmethod = "double", eol = "\n")
}
if (any(read.csv(file.path(root, "database", "stocks.csv"),
    stringsAsFactors = FALSE, check.names = FALSE)$stock_id == stock_id) ||
    any(read.csv(file.path(root, "database", "assessments.csv"),
    stringsAsFactors = FALSE, check.names = FALSE)$assessment_id == assessment_id)) {
  stop("Atlantic cobia records already exist; refusing to append duplicates.")
}

if (!write_mode) {
  cat("Validated SEDAR 58 Atlantic cobia source import:",
    nrow(inputs), "input rows,", nrow(assumptions), "assumptions, and",
    nrow(outputs), "output rows. Run with --write to append records.\n")
} else {
  append_rows("stocks.csv", stock)
  append_rows("assessments.csv", assessment)
  append_rows("inputs.csv", inputs)
  append_rows("assumptions.csv", assumptions)
  append_rows("outputs.csv", outputs)
  replace_candidate_register_row(register_path, candidate_row,
    register[candidate_row, , drop = FALSE], candidate_id)
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key",
    inventory$unit_key[inventory_row])
  replace_csv_register_row(selected_path, selected_row,
    selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)
  cat("Imported partial NOAA Atlantic cobia SEDAR 58 source records.\n")
}
