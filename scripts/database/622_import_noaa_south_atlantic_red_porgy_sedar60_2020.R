root <- "."
cache_dir <- file.path("source_cache", "noaa_south_atlantic_red_porgy_sedar60_2020")
manifest_path <- file.path("provenance", "noaa_south_atlantic_red_porgy_sedar60_2020", "manifest.csv")
stock_id <- "noaa_south_atlantic_red_porgy"
assessment_id <- "noaa_south_atlantic_red_porgy_sedar60_2020"
candidate_id <- "NOAA:10100"
assessment_url <- "https://sedarweb.org/documents/sedar-60-stock-assessment-report-south-atlantic-red-porgy/"
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
  if (length(hashes) != 1L) stop("Could not calculate source SHA-256.", call. = FALSE)
  hashes
}

source_name <- "sedar60_south_atlantic_red_porgy.pdf"
source_row <- manifest[basename(manifest$file) == source_name, , drop = FALSE]
pdf_path <- file.path(cache_dir, source_name)
if (nrow(source_row) != 1L || !file.exists(pdf_path) ||
    as.numeric(source_row$bytes) != file.info(pdf_path)$size ||
    !identical(sha256_file(pdf_path), tolower(source_row$sha256))) {
  stop("Cached SEDAR 60 report differs from its provenance record.", call. = FALSE)
}

pages <- pdftools::pdf_text(pdf_path)
years <- 1972:2017
ages <- 1:14
numeric_values <- function(x) {
  x[x == "."] <- NA_character_
  suppressWarnings(as.numeric(x))
}
parse_year_table <- function(page, field_count) {
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  parsed <- list()
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    year_position <- which(grepl("^(19|20)[0-9]{2}$", tokens))
    if (!length(year_position)) next
    year_position <- year_position[1L]
    year <- as.integer(tokens[year_position])
    if (!year %in% years || year_position == length(tokens)) next
    values <- tokens[seq.int(year_position + 1L, length(tokens))]
    if (length(values) != field_count) next
    parsed[[as.character(year)]] <- numeric_values(values)
  }
  if (!setequal(names(parsed), as.character(years))) {
    stop("Unexpected year coverage in PDF page ", page, ".", call. = FALSE)
  }
  values <- do.call(rbind, parsed[as.character(years)])
  rownames(values) <- as.character(years)
  values
}
parse_age_table <- function(page, field_count) {
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  parsed <- list()
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    candidate <- which(tokens %in% as.character(ages))
    candidate <- candidate[vapply(candidate, function(i) {
      length(tokens) - i == field_count
    }, logical(1L))]
    if (length(candidate) != 1L) next
    position <- candidate[1L]
    age <- as.integer(tokens[position])
    parsed[[as.character(age)]] <- numeric_values(tokens[seq.int(position + 1L, length(tokens))])
  }
  if (!setequal(names(parsed), as.character(ages))) {
    stop("Unexpected age coverage in PDF page ", page, ".", call. = FALSE)
  }
  values <- do.call(rbind, parsed[as.character(ages)])
  rownames(values) <- as.character(ages)
  values
}

t10 <- parse_year_table(95L, 7L)
t12 <- parse_year_table(97L, 4L)
t13 <- parse_year_table(98L, 4L)
t14 <- parse_year_table(99L, 4L)
t15 <- parse_age_table(100L, 10L)
t16 <- parse_year_table(101L, 15L)
t17 <- parse_year_table(102L, 15L)
t18 <- parse_year_table(103L, 15L)
t19 <- parse_year_table(104L, 8L)
t20 <- parse_age_table(105L, 18L)
t21 <- parse_year_table(106L, 8L)
t22 <- parse_year_table(107L, 14L)
t23 <- parse_year_table(108L, 14L)
t24 <- parse_year_table(109L, 14L)
t25 <- parse_year_table(110L, 4L)
t26 <- parse_year_table(111L, 4L)
t27 <- parse_year_table(112L, 3L)
t28 <- parse_year_table(113L, 3L)

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = NA_character_, survey = NA_character_, sex = NA_character_,
                      year = NA_integer_, age = NA_integer_, year_basis = NA_character_,
                      sampling_time = NA_real_, partition = NA_character_,
                      observation_id = NA_character_, source_type = "official_table",
                      transformation = NA_character_) {
  n <- length(value)
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs", n = n,
    assessment_id = rep(assessment_id, n), type = rep_len(type, n),
    measure = rep_len(measure, n), basis = rep_len(basis, n),
    fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = rep_len(sex, n),
    year = rep_len(year, n), year_basis = rep_len(year_basis, n),
    age = rep_len(age, n), value = as.numeric(value), unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = rep_len(source_type, n),
    source_reference = rep_len(source_reference, n),
    transformation = rep_len(transformation, n), notes = rep_len(notes, n),
    partition = rep_len(partition, n), observation_id = rep_len(observation_id, n))
}
output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
                       year = NA_integer_, age = NA_integer_, age_group = NA_character_,
                       fleet = NA_character_, survey = NA_character_, scenario = NA_character_,
                       se = NA_real_, source_type = "official_table") {
  n <- length(value)
  if (is.null(fleet)) fleet <- NA_character_
  if (is.null(survey)) survey <- NA_character_
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs", n = n,
    assessment_id = rep(assessment_id, n), type = rep_len(type, n),
    measure = rep_len(measure, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey, n), year = rep_len(year, n), age = rep_len(age, n),
    age_group = rep_len(age_group, n), scenario = rep_len(scenario, n),
    value = as.numeric(value), se = rep_len(se, n), unit = rep_len(unit, n),
    source_type = rep_len(source_type, n), source_reference = rep_len(source_reference, n),
    notes = rep_len(notes, n))
}

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10100",
  scientific_name = "Pagrus pagrus", common_name = "Red porgy - Southern Atlantic Coast",
  area = "Southern Atlantic Coast", region = "United States South Atlantic Coast",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10100; South Atlantic management unit for red porgy.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2020L, terminal_year = 2017L,
  estimate_terminal_year = 2017L, assessment_type = "benchmark_assessment",
  model_family = "Beaufort Assessment Model",
  model_version = "SEDAR 60 base run, April 2020",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = assessment_url,
  framework_url = "https://sedarweb.org/assessments/sedar-60/",
  data_url = "https://sedarweb.org/assessments/sedar-60/",
  model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Latest completed detailed assessment located for the current NOAA unit; report data through 2017. Exact composition proportions and some native model files are not tabulated in the report.")

assumptions <- do.call(rbind, list(
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "assessment",
    setting = "run_identity", value = "SEDAR 60 South Atlantic red porgy benchmark assessment; April 2020; data through 2017.",
    source_reference = "SEDAR 60 Stock Assessment Report, cover and Tables 10-29",
    notes = "Selected as the latest completed detailed assessment located for NOAA Stock SMART unit 10100."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "model",
    setting = "model_family", value = "Beaufort Assessment Model (BAM), statistical catch-age model.",
    source_reference = "SEDAR 60 Stock Assessment Report, Section 3.3",
    notes = "The assessment models ages 1-14+, years 1972-2017, and assumes a closed population."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "catch",
    setting = "catch_observation_error", value = "A fixed CV of 0.05 was used for landings and discards in the assessment fit.",
    source_reference = "SEDAR 60 Stock Assessment Report, Table 11 note",
    notes = "The year-specific CVs listed in Table 11 were used for the Monte Carlo/Bootstrap ensemble analysis only, not for fitting the base assessment."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "composition",
    setting = "age_composition_data", value = "Handline, headboat and SERFS chevron trap age compositions were fitted; numeric age proportions are shown in figures rather than tabulated.",
    source_reference = "SEDAR 60 Stock Assessment Report, Tables 12-13 and Figures 4-13",
    notes = "Table 12 trip counts and Table 13 fish sample counts are imported; composition proportions remain unavailable as machine-readable source rows."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "index",
    setting = "abundance_indices", value = "Aggregate recreational headboat and SERFS chevron trap/video indices were fitted.",
    source_reference = "SEDAR 60 Stock Assessment Report, Table 14",
    notes = "The report describes indices predicted from beginning-of-year abundance; a single within-year sampling fraction for each index is not reported."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "M",
    setting = "natural_mortality", value = "Natural mortality is fixed over time and age-varying under a growth-based Charnov form, scaled to survival equivalent to constant M = 0.22 per year over ages 3-25.",
    source_reference = "SEDAR 60 Stock Assessment Report, Section 3.3 and Table 15",
    notes = "The fixed age-specific values printed in Table 15 are imported as the reported M-at-age input."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "biology",
    setting = "growth_and_weight", value = "The assessment uses fixed age-specific length and mid-year weight inputs.",
    source_reference = "SEDAR 60 Stock Assessment Report, Table 15",
    notes = "Length, weight, female proportion and spawning weight are retained in their reported dimensions; age 14 is the 14+ group."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "maturity",
    setting = "maturity_at_age", value = "Age-specific maturity is fixed; male maturity is 1 at all ages and female maturity follows the Table 15 vector.",
    source_reference = "SEDAR 60 Stock Assessment Report, Table 15",
    notes = "No time variation is reported for the base run."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "timing",
    setting = "spawning_time", value = "Spawning is represented on February 1 (year fraction 0.167).",
    source_reference = "SEDAR 60 Stock Assessment Report, Section 3.3",
    notes = "Survey timing is not specified as a single effective fraction within year."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "outputs",
    setting = "reported_uncertainty", value = "Tables 16-28 report point estimates without annual intervals; Table 29 reports Monte Carlo/Bootstrap medians and standard errors for selected reference quantities.",
    source_reference = "SEDAR 60 Stock Assessment Report, Tables 16-29",
    notes = "Uncertainty is preserved only where reported in Table 29; no annual uncertainty is inferred for population surfaces."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "outputs",
    setting = "projection_tables", value = "Projection Tables 31-34 are not included in this historical population-output import.",
    source_reference = "SEDAR 60 Stock Assessment Report, Tables 31-34",
    notes = "These are management projection scenarios, separate from the historical fitted population series imported here.")
))

catch_specs <- list(
  list(column = 1L, fleet = "Commercial handline", measure = "landings_biomass", basis = "biomass", unit = "1,000 lb whole weight", partition = "landings"),
  list(column = 2L, fleet = "Commercial trawl", measure = "landings_biomass", basis = "biomass", unit = "1,000 lb whole weight", partition = "landings"),
  list(column = 3L, fleet = "Recreational headboat", measure = "landings_numbers", basis = "numbers", unit = "1,000 fish", partition = "landings"),
  list(column = 4L, fleet = "Recreational MRIP", measure = "landings_numbers", basis = "numbers", unit = "1,000 fish", partition = "landings"),
  list(column = 5L, fleet = "Commercial handline", measure = "discard_numbers", basis = "numbers", unit = "1,000 fish", partition = "dead_discards"),
  list(column = 6L, fleet = "Recreational headboat", measure = "discard_numbers", basis = "numbers", unit = "1,000 fish", partition = "dead_discards"),
  list(column = 7L, fleet = "Recreational MRIP", measure = "discard_numbers", basis = "numbers", unit = "1,000 fish", partition = "dead_discards")
)
for (spec in catch_specs) {
  values <- t10[, spec$column]
  keep <- is.finite(values)
  if (!any(keep)) next
  source_ref <- "SEDAR 60 Stock Assessment Report, Table 10"
  notes <- "Observed annual landings or dead discards as reported. These are aggregate fleet totals, not catch-at-age observations."
  add_input("catch", spec$measure, spec$basis, values[keep], spec$unit, source_ref,
    notes, fleet = spec$fleet, year = years[keep], year_basis = "calendar_year",
    partition = spec$partition)
  add_input("catch", "catch_cv", "relative_scale", rep(0.05, sum(keep)), "ratio",
    "SEDAR 60 Stock Assessment Report, Table 11 note",
    "Fixed CV of 0.05 used in the fitted assessment for all landings and dead discards; Table 11 year-varying CVs are for MCB only.",
    fleet = spec$fleet, year = years[keep], year_basis = "calendar_year",
    partition = spec$partition)
}

composition_specs <- list(
  list(column = 1L, fleet = "Commercial trawl", survey = NA_character_, kind = "length composition"),
  list(column = 2L, fleet = "Commercial handline", survey = NA_character_, kind = "age composition"),
  list(column = 3L, fleet = "Recreational headboat", survey = NA_character_, kind = "age composition"),
  list(column = 4L, fleet = NA_character_, survey = "SERFS chevron trap", kind = "age composition")
)
for (table_number in c(12L, 13L)) {
  composition_table <- if (table_number == 12L) t12 else t13
  unit <- if (table_number == 12L) "trips" else "fish"
  suffix <- if (table_number == 12L) "trips" else "fish"
  for (spec in composition_specs) {
    values <- composition_table[, spec$column]
    keep <- is.finite(values)
    if (!any(keep)) next
    add_input("biology", "composition_sample_count", "numbers", values[keep], unit,
      paste0("SEDAR 60 Stock Assessment Report, Table ", table_number),
      paste("Reported sample count for", spec$kind, "data; numeric composition values are not tabulated."),
      fleet = spec$fleet, survey = spec$survey, year = years[keep],
      year_basis = "calendar_year", observation_id = paste0("Table", table_number, "_", suffix))
  }
}

index_specs <- list(
  list(value_column = 1L, cv_column = 3L, survey = "Recreational headboat index"),
  list(value_column = 2L, cv_column = 4L, survey = "SERFS chevron trap/video index")
)
for (spec in index_specs) {
  index_values <- t14[, spec$value_column]
  keep <- is.finite(index_values)
  add_input("index", "relative_abundance_index", "index_scale", index_values[keep],
    "relative index units", "SEDAR 60 Stock Assessment Report, Table 14",
    "Aggregate abundance index retained on the reported scale; no multiplier or age-specific index surface is supplied.",
    survey = spec$survey, year = years[keep], year_basis = "calendar_year")
  cv_values <- t14[, spec$cv_column]
  cv_keep <- is.finite(cv_values)
  add_input("index", "abundance_index_cv", "relative_scale", cv_values[cv_keep], "ratio",
    "SEDAR 60 Stock Assessment Report, Table 14",
    "Source-reported annual coefficient of variation for the matching aggregate index.",
    survey = spec$survey, year = years[cv_keep], year_basis = "calendar_year")
}

age14_notes <- "Age 14 represents the 14+ plus group in the assessment. Values are fixed source inputs."
for (j in seq_along(ages)) {
  age <- ages[j]
  add_input("biology", "growth_length_at_age", "native_covariate", t15[j, 1L], "mm",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed total length at age;", age14_notes), age = age)
  add_input("weight", "weight_at_age", "kg_per_fish", t15[j, 4L], "kg/fish",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed mid-year stock weight at age;", age14_notes), age = age)
  add_input("biology", "proportion_female_at_age", "proportion", t15[j, 6L], "proportion",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed proportion female at age;", age14_notes), age = age)
  add_input("maturity", "maturity_at_age", "proportion", t15[j, 7L], "proportion",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed female maturity at age;", age14_notes), sex = "female", age = age)
  add_input("maturity", "maturity_at_age", "proportion", t15[j, 8L], "proportion",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed male maturity at age;", age14_notes), sex = "male", age = age)
  add_input("weight", "spawning_weight_at_age", "kg_per_fish", t15[j, 9L], "kg/fish",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed mature spawning weight at age, including sex proportion and maturity;", age14_notes), age = age)
  add_input("M", "natural_mortality_at_age", "per_year", t15[j, 10L], "per_year",
    "SEDAR 60 Stock Assessment Report, Table 15",
    paste("Fixed age-specific natural mortality;", age14_notes), age = age)
}

add_matrix_output <- function(table, table_name, type, measure, unit, notes,
                              total_measure = NULL, total_unit = unit, total_type = type) {
  values <- table[, seq_len(length(ages)), drop = FALSE]
  for (j in seq_along(ages)) {
    add_output(type, measure, values[, j], unit,
      paste0("SEDAR 60 Stock Assessment Report, Table ", table_name), notes,
      year = years, age = ages[j], age_group = if (ages[j] == 14L) "14+" else NA_character_)
  }
  if (!is.null(total_measure)) {
    add_output(total_type, total_measure, table[, length(ages) + 1L], total_unit,
      paste0("SEDAR 60 Stock Assessment Report, Table ", table_name),
      paste(notes, "The table's total column is retained separately."), year = years)
  }
}
add_matrix_output(t16, 16L, "population", "numbers_at_age", "1,000 fish",
  "Estimated start-of-year abundance at age; age 14 is the 14+ group.", "total_numbers")
add_matrix_output(t17, 17L, "biomass", "biomass_at_age", "metric tons",
  "Estimated start-of-year biomass at age; age 14 is the 14+ group.", "total_biomass")
add_matrix_output(t18, 18L, "biomass", "biomass_at_age_whole_weight", "1,000 lb whole weight",
  "Estimated start-of-year biomass at age on the source whole-weight scale; age 14 is the 14+ group.",
  "total_biomass_whole_weight")

status_specs <- list(
  list(column = 1L, type = "mortality", measure = "apical_F", unit = "per_year"),
  list(column = 2L, type = "mortality", measure = "F_ratio_to_Fmsy", unit = "ratio"),
  list(column = 4L, type = "biomass", measure = "total_biomass_ratio_to_unfished", unit = "ratio"),
  list(column = 5L, type = "biomass", measure = "SSB", unit = "metric tons"),
  list(column = 6L, type = "biomass", measure = "SSB_ratio_to_SSBMSY", unit = "ratio"),
  list(column = 7L, type = "biomass", measure = "SSB_ratio_to_MSST", unit = "ratio"),
  list(column = 8L, type = "probability", measure = "current_spawning_potential_ratio", unit = "proportion")
)
for (spec in status_specs) {
  add_output(spec$type, spec$measure, t19[, spec$column], spec$unit,
    "SEDAR 60 Stock Assessment Report, Table 19",
    "Annual base-run status estimate as printed; biomass is at the start of year. F is apical F including dead discards.",
    year = years)
}

selectivity_specs <- list(
  list(column = 3L, fleet = "Commercial handline", year = 1972L),
  list(column = 4L, fleet = "Commercial handline", year = 1999L),
  list(column = 5L, fleet = "Commercial trawl", year = NA_integer_),
  list(column = 6L, fleet = "Recreational headboat", year = 1972L),
  list(column = 7L, fleet = "Recreational headboat", year = 1992L),
  list(column = 8L, fleet = "Recreational headboat", year = 1999L),
  list(column = 9L, fleet = "Recreational MRIP", year = 1972L),
  list(column = 10L, fleet = "Recreational MRIP", year = 1992L),
  list(column = 11L, fleet = "Recreational MRIP", year = 1999L),
  list(column = 12L, fleet = "Commercial handline dead discards", year = NA_integer_),
  list(column = 13L, fleet = "Recreational headboat dead discards", year = NA_integer_),
  list(column = 14L, fleet = "Recreational MRIP dead discards", year = NA_integer_),
  list(column = 15L, survey = "SERFS chevron trap", year = NA_integer_),
  list(column = 16L, fleet = "Average landings selectivity", year = NA_integer_),
  list(column = 17L, fleet = "Average dead-discard selectivity", year = NA_integer_),
  list(column = 18L, fleet = "Total removals selectivity", year = NA_integer_)
)
for (spec in selectivity_specs) {
  add_output("biology", "fleet_selectivity_at_age", t20[, spec$column], "proportion",
    "SEDAR 60 Stock Assessment Report, Table 20",
    "Source-reported selectivity. A year identifies the first year of the constant selectivity period; age 14 is the 14+ group.",
    year = spec$year, age = ages,
    age_group = ifelse(ages == 14L, "14+", NA_character_),
    fleet = spec$fleet, survey = spec$survey)
}

f_fleets <- c("Commercial handline", "Commercial trawl", "Recreational headboat",
  "Recreational MRIP", "Commercial handline dead discards",
  "Recreational headboat dead discards", "Recreational MRIP dead discards")
for (j in seq_along(f_fleets)) {
  add_output("mortality", "fishing_mortality_summary", t21[, j], "per_year",
    "SEDAR 60 Stock Assessment Report, Table 21",
    "Annual fully selected F for this fleet as printed; Table 21 also reports apical F, retained at greater precision in Table 19.",
    year = years, fleet = f_fleets[j])
}
for (j in seq_along(ages)) {
  add_output("mortality", "fishing_mortality_at_age", t22[, j], "per_year",
    "SEDAR 60 Stock Assessment Report, Table 22",
    "Estimated instantaneous fishing mortality at age, including discard mortality; age 14 is the 14+ group.",
    year = years, age = ages[j], age_group = if (ages[j] == 14L) "14+" else NA_character_)
  add_output("catch", "landings_numbers_at_age", t23[, j], "1,000 fish",
    "SEDAR 60 Stock Assessment Report, Table 23",
    "Estimated total landings at age in numbers; this is a fitted output, not an observed catch input. Age 14 is the 14+ group.",
    year = years, age = ages[j], age_group = if (ages[j] == 14L) "14+" else NA_character_)
  add_output("catch", "landings_biomass_at_age", t24[, j], "1,000 lb whole weight",
    "SEDAR 60 Stock Assessment Report, Table 24",
    "Estimated total landings at age in whole weight; this is a fitted output, not an observed catch input. Age 14 is the 14+ group.",
    year = years, age = ages[j], age_group = if (ages[j] == 14L) "14+" else NA_character_)
}

fleet4 <- c("Commercial handline", "Commercial trawl", "Recreational headboat", "Recreational MRIP")
for (j in seq_along(fleet4)) {
  add_output("catch", "landings_numbers", t25[, j], "1,000 fish",
    "SEDAR 60 Stock Assessment Report, Table 25",
    "Estimated fleet landings in numbers; fitted output.", year = years, fleet = fleet4[j])
  add_output("catch", "landings_biomass", t26[, j], "1,000 lb whole weight",
    "SEDAR 60 Stock Assessment Report, Table 26",
    "Estimated fleet landings in whole weight; fitted output.", year = years, fleet = fleet4[j])
}
discard_fleets <- c("Commercial handline dead discards", "Recreational headboat dead discards", "Recreational MRIP dead discards")
for (j in seq_along(discard_fleets)) {
  add_output("catch", "discard_numbers", t27[, j], "1,000 fish",
    "SEDAR 60 Stock Assessment Report, Table 27",
    "Estimated dead discards in numbers; fitted output.", year = years, fleet = discard_fleets[j])
  add_output("catch", "discard_biomass", t28[, j], "1,000 lb whole weight",
    "SEDAR 60 Stock Assessment Report, Table 28",
    "Estimated dead discards in whole weight; fitted output.", year = years, fleet = discard_fleets[j])
}

benchmark_rows <- data.frame(
  type = c("mortality", "mortality", "mortality", "mortality", "biomass", "biomass",
    "biomass", "catch", "catch", "recruitment", "catch", "catch", "catch",
    "mortality", "biomass", "biomass"),
  measure = c("Fmsy", "F75_percent_Fmsy", "F30_percent", "F40_percent", "Bmsy",
    "SSBMSY", "MSST", "msy", "estimated_discards", "RMSY",
    "landings_at_85_percent_Fmsy", "landings_at_75_percent_Fmsy",
    "landings_at_65_percent_Fmsy", "F_ratio_to_Fmsy", "SSB_ratio_to_MSST",
    "SSB_ratio_to_SSBMSY"),
  estimate = c(.18, .135, 1.21, .6, 3604.6, 2883.7, 2249.3, 531.4, 126.8, 2641.2,
    527.2, 515.7, 494.9, 1.73, .347, .271),
  median = c(.18, .135, 1.175, .585, 3593.7, 2902.6, 2261, 538.2, 118.5, 2554.1,
    532.8, 521.9, 502.9, 1.664, .369, .285),
  se = c(.027, .020, .796, .326, 487.3, 337.3, 219, 59.3, 118.5, 796.3,
    59.4, 59.4, 59.1, .304, .101, .063),
  unit = c("per_year", "per_year", "per_year", "per_year", "metric tons", "metric tons",
    "metric tons", "1,000 lb whole weight", "1,000 lb dead fish", "1,000 fish",
    "1,000 lb whole weight", "1,000 lb whole weight", "1,000 lb whole weight",
    "ratio", "ratio", "ratio"),
  stringsAsFactors = FALSE
)
benchmark_rows <- rbind(benchmark_rows, data.frame(
  type = c("mortality", "mortality", "mortality", "catch"),
  measure = c("F85_percent_Fmsy", "F65_percent_Fmsy", "F20_percent", "estimated_discards"),
  estimate = c(.153, .117, 3.115, 104),
  median = c(.153, .117, 3.022, 96.7),
  se = c(.023, .018, 1.425, 96.7),
  unit = c("per_year", "per_year", "per_year", "1,000 dead fish"),
  stringsAsFactors = FALSE
))
for (i in seq_len(nrow(benchmark_rows))) {
  row <- benchmark_rows[i, ]
  scenario <- if (row$measure == "F_ratio_to_Fmsy") {
    "2015-2017 geometric mean F"
  } else if (row$measure == "estimated_discards" && row$unit == "1,000 dead fish") {
    "MSY dead-discard numbers"
  } else if (row$measure == "estimated_discards") {
    "MSY dead-discard biomass"
  } else {
    "base-run reference quantity"
  }
  year <- if (row$measure %in% c("SSB_ratio_to_MSST", "SSB_ratio_to_SSBMSY")) 2017L else NA_integer_
  add_output(row$type, row$measure, as.numeric(row$estimate), row$unit,
    "SEDAR 60 Stock Assessment Report, Table 29",
    "Table 29 estimate; SE is from Monte Carlo/Bootstrap analysis. The corresponding MCB median is retained as a separate scenario row.",
    year = year, scenario = paste(scenario, "estimate"), se = as.numeric(row$se))
  add_output(row$type, row$measure, as.numeric(row$median), row$unit,
    "SEDAR 60 Stock Assessment Report, Table 29",
    "Monte Carlo/Bootstrap median, reported separately from the base-run estimate.",
    year = year, scenario = paste(scenario, "MCB median"))
}

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)

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
    any(existing_stocks$authority_stock_id == "10100" & existing_stocks$authority == "NOAA Fisheries") ||
    any(existing_assessments$assessment_id == assessment_id)) {
  stop("Red porgy identity conflicts with the eligible candidate or canonical database.", call. = FALSE)
}
inventory_path <- file.path(root, "discovery/inventory_units.csv")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)

output_key <- paste(outputs$type, outputs$measure, outputs$fleet, outputs$survey, outputs$year,
  outputs$age, outputs$age_group, outputs$scenario, sep = "|")
input_key <- paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey, inputs$sex,
  inputs$year, inputs$age, inputs$partition, inputs$observation_id, sep = "|")
if (nrow(t15) != 14L || nrow(t20) != 14L || nrow(outputs) < 5000L ||
    any(!is.finite(outputs$value)) || anyDuplicated(output_key) ||
    anyDuplicated(input_key) || any(!is.finite(inputs$value))) {
  stop("Red porgy source tables failed coverage, value, or uniqueness checks.", call. = FALSE)
}
if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Imported observed aggregate catches, index values/CVs, fixed age biology and model outputs from SEDAR 60 Tables 10 and 12-29; composition proportions remain figure-only, Table11 ensemble CVs and Tables31-34 projections are not included.")
  replace_candidate_register_row(candidates_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " input rows, and ",
    nrow(outputs), " output rows from SEDAR 60 Tables 10 and 12-29; no figure-digitized compositions.")
}
