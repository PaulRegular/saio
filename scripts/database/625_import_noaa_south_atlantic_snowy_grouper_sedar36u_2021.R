root <- "."
cache <- file.path("source_cache", "noaa_snowy_grouper_sedar36u_2021")
manifest_path <- file.path("provenance", "noaa_snowy_grouper_sedar36u_2021", "manifest.csv")
stock_id <- "noaa_snowy_grouper_south_atlantic"
assessment_id <- "noaa_snowy_grouper_south_atlantic_sedar36u_2021"
candidate_id <- "NOAA:10339"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source("scripts/database/pacific_tables.R")
source("scripts/database/candidate_register_io.R")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract SEDAR 36 Update tables.", call. = FALSE)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
sha256_file <- function(path) {
  output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    output, value = TRUE)))
  if (length(hashes) != 1L) stop("Could not calculate source SHA-256.", call. = FALSE)
  hashes
}
verify_source <- function(name) {
  record <- manifest[basename(manifest$file) == name, , drop = FALSE]
  path <- file.path(cache, name)
  if (nrow(record) != 1L || !file.exists(path) ||
      as.numeric(record$bytes) != file.info(path)$size ||
      !identical(sha256_file(path), tolower(record$sha256))) {
    stop("Cached source differs from its provenance record: ", name, call. = FALSE)
  }
  path
}

sar <- verify_source("sedar36u_report_revised_2021.pdf")
invisible(verify_source("sedar36u_wp01_recreational_data_2020.pdf"))
invisible(verify_source("sedar36u_wp02_management_history_2020.pdf"))
sar_pages <- pdftools::pdf_text(sar)

number <- function(x) {
  x[x == "."] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

parse_year_table <- function(page, years, value_count) {
  parsed <- list()
  lines <- strsplit(sar_pages[[page]], "\n", fixed = TRUE)[[1L]]
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    year_position <- which(tokens %in% as.character(years))
    if (!length(year_position)) next
    year_position <- year_position[1L]
    year <- as.integer(tokens[year_position])
    if (length(tokens) - year_position != value_count) next
    if (as.character(year) %in% names(parsed)) {
      stop("Duplicate year ", year, " on PDF page ", page, call. = FALSE)
    }
    parsed[[as.character(year)]] <- number(tokens[seq.int(year_position + 1L,
      length(tokens))])
  }
  if (!setequal(names(parsed), as.character(years))) {
    stop("Unexpected year coverage on PDF page ", page, call. = FALSE)
  }
  values <- do.call(rbind, parsed[as.character(years)])
  rownames(values) <- as.character(years)
  values
}

parse_age_table <- function(page, ages, value_count) {
  parsed <- list()
  lines <- strsplit(sar_pages[[page]], "\n", fixed = TRUE)[[1L]]
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (!length(tokens)) next
    age_position <- which(tokens %in% as.character(ages) &
      seq_along(tokens) == length(tokens) - value_count)
    if (length(age_position) != 1L) next
    age_position <- age_position[1L]
    age <- as.integer(tokens[age_position])
    if (as.character(age) %in% names(parsed)) {
      stop("Duplicate age ", age, " on PDF page ", page, call. = FALSE)
    }
    parsed[[as.character(age)]] <- number(tokens[seq.int(age_position + 1L,
      length(tokens))])
  }
  if (!setequal(names(parsed), as.character(ages))) {
    stop("Unexpected age coverage on PDF page ", page, call. = FALSE)
  }
  values <- do.call(rbind, parsed[as.character(ages)])
  rownames(values) <- as.character(ages)
  values
}

historical_years <- 1974:2018
estimate_years <- 1974:2019
ages <- 1:25
age_group <- ifelse(ages == 25L, "25+", NA_character_)

biology <- parse_age_table(31L, ages, 8L)
catch <- parse_year_table(32L, historical_years, 3L)
indices <- parse_year_table(33L, 1978:2018, 6L)
sample_fish <- parse_year_table(34L, historical_years, 8L)
sample_trips <- parse_year_table(35L, historical_years, 8L)
n_at_age <- parse_year_table(36L, estimate_years, 26L)
biomass_at_age <- parse_year_table(37L, estimate_years, 26L)
status <- parse_year_table(38L, estimate_years, 8L)
selectivity <- parse_age_table(39L, ages, 8L)
fully_selected_f <- parse_year_table(40L, historical_years, 4L)
f_at_age <- parse_year_table(41L, historical_years, 25L)
removals_numbers_at_age <- parse_year_table(42L, historical_years, 25L)
removals_weight_at_age <- parse_year_table(43L, historical_years, 25L)
removals_numbers <- parse_year_table(44L, historical_years, 4L)
removals_weight <- parse_year_table(45L, historical_years, 4L)

expected_dimensions <- list(
  biology = c(25L, 8L), catch = c(45L, 3L), indices = c(41L, 6L),
  sample_fish = c(45L, 8L), sample_trips = c(45L, 8L),
  n_at_age = c(46L, 26L), biomass_at_age = c(46L, 26L),
  status = c(46L, 8L), selectivity = c(25L, 8L),
  fully_selected_f = c(45L, 4L), f_at_age = c(45L, 25L),
  removals_numbers_at_age = c(45L, 25L), removals_weight_at_age = c(45L, 25L),
  removals_numbers = c(45L, 4L), removals_weight = c(45L, 4L)
)
parsed_tables <- mget(names(expected_dimensions))
if (any(!vapply(names(expected_dimensions), function(name) {
  identical(dim(parsed_tables[[name]]), expected_dimensions[[name]])
}, logical(1L))) ||
    any(biology[, 4L] <= 0) || any(biology[, 5L] < 0) ||
    any(biology[, 6L] < 0 | biology[, 6L] > 1) ||
    any(biology[, 7L] < 0 | biology[, 7L] > 1) || any(biology[, 8L] <= 0) ||
    any(!is.finite(n_at_age)) || any(n_at_age[, 26L] <= 0) ||
    any(abs(rowSums(n_at_age[, 1:25, drop = FALSE]) - n_at_age[, 26L]) > 0.15) ||
    any(abs(rowSums(biomass_at_age[, 1:25, drop = FALSE]) - biomass_at_age[, 26L]) > 1.5) ||
    any(indices[, c(2L, 4L, 6L)] < 0, na.rm = TRUE)) {
  stop("SEDAR 36 Update tables failed dimensions or value checks.", call. = FALSE)
}

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = NA_character_, survey = NA_character_, sex = NA_character_,
                      year = NA_integer_, age = NA_integer_, partition = NA_character_,
                      observation_id = NA_character_, transformation = NA_character_) {
  n <- max(length(value), length(fleet), length(survey), length(sex),
    length(year), length(age), length(partition), length(observation_id),
    length(transformation))
  year_basis <- if (length(year) == 1L && is.na(year)) NA_character_ else "calendar_year"
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, year = year,
    year_basis = year_basis, age = age, value = value, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes, partition = partition,
    observation_id = observation_id)
}

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
                       year = NA_integer_, age = NA_integer_, age_group = NA_character_,
                       fleet = NA_character_, survey = NA_character_, scenario = NA_character_,
                       se = NA_real_) {
  keep <- is.finite(value)
  if (!any(keep)) return(invisible(NULL))
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs",
    n = sum(keep), assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = survey, year = year[keep], age = age[keep],
    age_group = age_group[keep], scenario = scenario[keep], value = value[keep],
    se = se[keep], unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes)
}

for (j in seq_along(ages)) {
  age <- ages[j]
  add_input("biology", "growth_length_at_age", "native_covariate", biology[j, 1L],
    "mm total length", "SEDAR 36 Update SAR, Table 1",
    "Mid-year population length at age; age 25 is the 25+ group.", age = age)
  add_input("weight", "weight_at_age", "kg_per_fish", biology[j, 4L],
    "kg/fish whole weight", "SEDAR 36 Update SAR, Table 1",
    "Mid-year whole weight at age; the source also reports the same values in lb/fish.", age = age)
  add_input("maturity", "maturity_at_age", "proportion", biology[j, 6L],
    "proportion", "SEDAR 36 Update SAR, Table 1",
    "Fixed female maturity-at-age.", sex = "female", age = age)
  add_input("biology", "proportion_female_at_age", "proportion", biology[j, 7L],
    "proportion", "SEDAR 36 Update SAR, Table 1",
    "Fixed proportion female-at-age; age 25 is the 25+ group.", age = age)
  add_input("M", "natural_mortality_at_age", "per_year", biology[j, 8L],
    "per_year", "SEDAR 36 Update SAR, Table 1",
    "Fixed age-specific natural mortality; age 25 is the 25+ group.", age = age)
  add_input("maturity", "maturity_at_age", "proportion", 1, "proportion",
    "SEDAR 36 Update SAR, Section 3.3", "The assessment assumes all males are mature.",
    sex = "male", age = age,
    transformation = "Encoded the report statement as a value of 1.")
}
add_output("biology", "growth_length_cv_at_age", biology[, 3L], "ratio",
  "SEDAR 36 Update SAR, Table 1",
  "Length coefficient of variation estimated by the assessment; other Table 1 values were treated as inputs.",
  year = rep(2018L, length(ages)), age = ages, age_group = age_group)

catch_specs <- list(
  list(column = 1L, fleet = "Commercial handline", measure = "catch_biomass",
    basis = "biomass", unit = "1,000 lb whole weight"),
  list(column = 2L, fleet = "Commercial longline", measure = "catch_biomass",
    basis = "biomass", unit = "1,000 lb whole weight"),
  list(column = 3L, fleet = "General recreational", measure = "catch_numbers",
    basis = "numbers", unit = "1,000 fish")
)
for (spec in catch_specs) {
  values <- catch[, spec$column]
  keep <- is.finite(values)
  add_input("catch", spec$measure, spec$basis, values[keep], spec$unit,
    "SEDAR 36 Update SAR, Table 2",
    "Observed annual landings and dead discards combined; not age-specific. The commercial and recreational series retain their reported mass and number units.",
    fleet = spec$fleet, year = historical_years[keep],
    partition = "landings_and_dead_discards")
}

index_specs <- list(
  list(value_column = 1L, cv_column = 2L, survey = "MARMAP chevron trap"),
  list(value_column = 3L, cv_column = 4L, survey = "MARMAP vertical longline"),
  list(value_column = 5L, cv_column = 6L, survey = "Headboat index")
)
for (spec in index_specs) {
  values <- indices[, spec$value_column]
  keep <- is.finite(values)
  add_input("index", "relative_abundance_index", "index_scale", values[keep],
    "relative index units; multiplier not stated", "SEDAR 36 Update SAR, Table 3",
    "Observed aggregate abundance index; not age-specific.",
    survey = spec$survey, year = (1978:2018)[keep])
  cvs <- indices[, spec$cv_column]
  keep_cv <- is.finite(cvs)
  add_input("index", "abundance_index_cv", "relative_scale", cvs[keep_cv],
    "ratio", "SEDAR 36 Update SAR, Table 3", "Source-reported annual index CV.",
    survey = spec$survey, year = (1978:2018)[keep_cv])
}

sample_specs <- list(
  list(column = 1L, fleet = "Commercial handline", survey = NA_character_, label = "length commercial handline"),
  list(column = 2L, fleet = "Commercial longline", survey = NA_character_, label = "length commercial longline"),
  list(column = 3L, fleet = "General recreational", survey = NA_character_, label = "length general recreational"),
  list(column = 4L, fleet = NA_character_, survey = "MARMAP chevron trap", label = "age chevron trap"),
  list(column = 5L, fleet = NA_character_, survey = "MARMAP vertical longline", label = "age vertical longline"),
  list(column = 6L, fleet = "Commercial handline", survey = NA_character_, label = "age commercial handline"),
  list(column = 7L, fleet = "Commercial longline", survey = NA_character_, label = "age commercial longline"),
  list(column = 8L, fleet = "General recreational", survey = NA_character_, label = "age general recreational")
)
for (table in list(list(values = sample_fish, unit = "fish", page = 34L),
                   list(values = sample_trips, unit = "trips", page = 35L))) {
  for (spec in sample_specs) {
    values <- table$values[, spec$column]
    keep <- is.finite(values)
    add_input("biology", "composition_sample_count", "numbers", values[keep],
      table$unit, paste0("SEDAR 36 Update SAR, Table ", table$page),
      paste("Source sample size for", spec$label,
        "composition; these counts are not composition proportions."),
      fleet = spec$fleet, survey = spec$survey,
      year = historical_years[keep],
      observation_id = paste0("SEDAR36U_Table", table$page, "_", gsub(" ", "_", spec$label)))
  }
}

projection_scenario <- ifelse(estimate_years > 2018L,
  "2019 assessment projection", NA_character_)
age_year <- rep(estimate_years, each = length(ages))
age_index <- rep(ages, times = length(estimate_years))
age_group_index <- rep(age_group, times = length(estimate_years))
scenario_index <- rep(projection_scenario, each = length(ages))
add_output("population", "numbers_at_age", as.vector(t(n_at_age[, 1:25, drop = FALSE])),
  "1,000 fish", "SEDAR 36 Update SAR, Table 6",
  "Estimated start-of-year abundance; age 25 is the 25+ group.",
  year = age_year, age = age_index, age_group = age_group_index,
  scenario = scenario_index)
add_output("population", "total_numbers", n_at_age[, 26L], "1,000 fish",
  "SEDAR 36 Update SAR, Table 6",
  "Source-reported total abundance column; equals the sum of the age-specific estimates within rounding.",
  year = estimate_years, scenario = projection_scenario)
add_output("recruitment", "recruitment", n_at_age[, 1L], "1,000 age-1 fish",
  "SEDAR 36 Update SAR, Table 6",
  "Recruitment represented by reported age-1 abundance; age 1 is the assessment recruitment age.",
  year = estimate_years, scenario = projection_scenario)

add_output("biomass", "biomass_at_age", as.vector(t(biomass_at_age[, 1:25, drop = FALSE])),
  "1,000 lb whole weight", "SEDAR 36 Update SAR, Table 7",
  "Estimated start-of-year biomass-at-age; age 25 is the 25+ group.",
  year = age_year, age = age_index, age_group = age_group_index,
  scenario = scenario_index)
add_output("biomass", "total_biomass_from_age_surface", biomass_at_age[, 26L],
  "1,000 lb whole weight", "SEDAR 36 Update SAR, Table 7",
  "Source-reported total column from biomass-at-age; the separate Table 8 total biomass is reported in metric tons.",
  year = estimate_years, scenario = projection_scenario)

status_specs <- list(
  list(column = 1L, type = "mortality", measure = "apical_F", unit = "per_year",
    notes = "Apical fishing mortality; the maximum age-specific total F, not the sum of fully selected fleet F."),
  list(column = 2L, type = "mortality", measure = "F_ratio_to_Fmsy", unit = "ratio",
    notes = "Apical F divided by FMSY."),
  list(column = 3L, type = "biomass", measure = "total_biomass", unit = "metric tons",
    notes = "Total biomass at start of year."),
  list(column = 4L, type = "biomass", measure = "total_biomass_ratio_to_unfished", unit = "ratio",
    notes = "Total biomass divided by unfished biomass."),
  list(column = 5L, type = "biomass", measure = "SSB", unit = "metric tons",
    notes = "Total mature male and female biomass at peak spawning, mid-year."),
  list(column = 6L, type = "biomass", measure = "SSB_ratio_to_SSBMSY", unit = "ratio",
    notes = "Spawning biomass divided by SSBMSY."),
  list(column = 7L, type = "biomass", measure = "SSB_ratio_to_MSST", unit = "ratio",
    notes = "Spawning biomass divided by MSST."),
  list(column = 8L, type = "biology", measure = "proportion_female_among_mature_fish", unit = "proportion",
    notes = "Estimated proportion of mature fish that are female.")
)
for (spec in status_specs) {
  add_output(spec$type, spec$measure, status[, spec$column], spec$unit,
    "SEDAR 36 Update SAR, Table 8", spec$notes,
    year = estimate_years, scenario = projection_scenario)
}

selectivity_specs <- list(
  list(column = 3L, fleet = NA_character_, survey = "MARMAP chevron trap"),
  list(column = 4L, fleet = NA_character_, survey = "MARMAP vertical longline"),
  list(column = 5L, fleet = "Commercial handline", survey = NA_character_),
  list(column = 6L, fleet = "Commercial longline", survey = NA_character_),
  list(column = 7L, fleet = "General recreational", survey = NA_character_)
)
for (spec in selectivity_specs) {
  add_output("biology", "fleet_selectivity_at_age", selectivity[, spec$column],
    "proportion", "SEDAR 36 Update SAR, Table 9",
    "Source-reported terminal-year selectivity at age.", age = ages,
    age_group = age_group, fleet = spec$fleet, survey = spec$survey,
    year = rep(2018L, length(ages)))
}
add_output("biology", "average_fleet_selectivity_at_age", selectivity[, 8L],
  "proportion", "SEDAR 36 Update SAR, Table 9",
  "Source-reported average selectivity across fleets; not an individual fleet.",
  age = ages, age_group = age_group, year = rep(2018L, length(ages)))

fleet_f_specs <- list(
  list(column = 1L, fleet = "Commercial handline"),
  list(column = 2L, fleet = "Commercial longline"),
  list(column = 3L, fleet = "General recreational")
)
for (spec in fleet_f_specs) {
  add_output("mortality", "fully_selected_fishing_mortality",
    fully_selected_f[, spec$column], "per_year", "SEDAR 36 Update SAR, Table 10",
    "Estimated annual fully selected fishing mortality for the named fleet.",
    year = historical_years, fleet = spec$fleet)
}
add_output("mortality", "fishing_mortality_at_age", as.vector(t(f_at_age)),
  "per_year", "SEDAR 36 Update SAR, Table 11",
  "Estimated annual instantaneous total fishing mortality at age; age 25 is the 25+ group.",
  year = rep(historical_years, each = length(ages)),
  age = rep(ages, times = length(historical_years)),
  age_group = rep(age_group, times = length(historical_years)))
add_output("catch", "estimated_removals_numbers_at_age",
  as.vector(t(removals_numbers_at_age)), "1,000 fish",
  "SEDAR 36 Update SAR, Table 12",
  "Estimated total removals (landings and dead discards) at age; age 25 is the 25+ group.",
  year = rep(historical_years, each = length(ages)),
  age = rep(ages, times = length(historical_years)),
  age_group = rep(age_group, times = length(historical_years)))
add_output("catch", "estimated_removals_weight_at_age",
  as.vector(t(removals_weight_at_age)), "1,000 lb whole weight",
  "SEDAR 36 Update SAR, Table 13",
  "Estimated total removals (landings and dead discards) by weight at age; age 25 is the 25+ group.",
  year = rep(historical_years, each = length(ages)),
  age = rep(ages, times = length(historical_years)),
  age_group = rep(age_group, times = length(historical_years)))

removal_specs <- list(
  list(column = 1L, fleet = "Commercial handline"),
  list(column = 2L, fleet = "Commercial longline"),
  list(column = 3L, fleet = "General recreational"),
  list(column = 4L, fleet = NA_character_)
)
for (spec in removal_specs) {
  add_output("catch", "estimated_removals_numbers", removals_numbers[, spec$column],
    "1,000 fish", "SEDAR 36 Update SAR, Table 14",
    "Estimated annual removals (landings and dead discards); the final column is the reported total across fleets.",
    year = historical_years, fleet = spec$fleet)
  add_output("catch", "estimated_removals_weight", removals_weight[, spec$column],
    "1,000 lb whole weight", "SEDAR 36 Update SAR, Table 15",
    "Estimated annual removals (landings and dead discards); the final column is the reported total across fleets.",
    year = historical_years, fleet = spec$fleet)
}

benchmark_specs <- data.frame(
  measure = c("Fmsy", "F85_percent_Fmsy", "F75_percent_Fmsy", "F65_percent_Fmsy",
    "F30_percent", "F40_percent", "Bmsy", "SSBMSY", "MSST", "msy", "RMSY",
    "yield_at_85_percent_Fmsy", "yield_at_75_percent_Fmsy", "yield_at_65_percent_Fmsy",
    "F_ratio_to_Fmsy", "SSB_ratio_to_MSST", "SSB_ratio_to_SSBMSY"),
  estimate = c(0.10, 0.09, 0.08, 0.07, 0.09, 0.06, 3237.6, 1908.0, 1430.8,
    532.0, 252.0, 527.5, 518.5, 503.0, NA, NA, NA),
  median = c(0.10, 0.09, 0.08, 0.07, 0.10, 0.07, 3400.9, 1930.9, 1448.2,
    533.6, 325.6, 529.0, 519.3, 503.9, 1.13, 0.48, 0.36),
  se = c(0.04, 0.04, 0.03, 0.03, 0.02, 0.01, 6682.9, 5004.2, 3753.2,
    716.1, 298.4, 708.5, 693.3, 668.1, 0.59, 0.78, 0.58),
  unit = c(rep("per_year", 6L), "metric tons", "metric tons", "metric tons",
    "1,000 lb whole weight", "1,000 age-1 fish", rep("1,000 lb whole weight", 3L),
    rep("ratio", 3L)),
  stringsAsFactors = FALSE
)
for (j in seq_len(nrow(benchmark_specs))) {
  spec <- benchmark_specs[j, ]
  if (is.finite(spec$estimate)) {
    add_output("management", spec$measure, spec$estimate, spec$unit,
      "SEDAR 36 Update SAR, Table 16",
      "Base-run benchmark estimate; Table 16 also reports Monte Carlo/Bootstrap medians and standard errors.",
      scenario = "base-run estimate")
  }
  add_output("management", spec$measure, spec$median, spec$unit,
    "SEDAR 36 Update SAR, Table 16",
    "Monte Carlo/Bootstrap median; SE is the source-reported measure of precision, not an annual time-series standard error.",
    scenario = "Monte Carlo/Bootstrap median", se = spec$se)
}

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
source_checks <- c(
  input_rows = nrow(inputs) > 0L,
  output_rows = nrow(outputs) > 0L,
  finite_inputs = all(is.finite(inputs$value)),
  finite_outputs = all(is.finite(outputs$value)),
  female_maturity = all(inputs$value[inputs$measure == "maturity_at_age" &
    inputs$sex == "female" & !is.na(inputs$sex)] >= 0 &
    inputs$value[inputs$measure == "maturity_at_age" &
      inputs$sex == "female" & !is.na(inputs$sex)] <= 1),
  index_cvs = all(inputs$value[inputs$measure == "abundance_index_cv"] >= 0),
  table_6_recruitment = nrow(outputs[outputs$measure == "recruitment" &
    outputs$year == 1974L, , drop = FALSE]) == 1L,
  projection_label = all(!is.na(outputs$scenario[!is.na(outputs$year) &
    outputs$year == 2019L]) & outputs$scenario[!is.na(outputs$year) &
      outputs$year == 2019L] == "2019 assessment projection")
)
if (any(!source_checks)) {
  stop("SEDAR 36 Update values failed checks: ",
    paste(names(source_checks)[!source_checks], collapse = ", "), call. = FALSE)
}

assumption_rows <- list()
assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes)
}
assumption("assessment", "run_identity",
  "SEDAR 36 Update South Atlantic Snowy Grouper assessment; revised January 2021; data through 2018.",
  "SEDAR 36 Update SAR, cover and executive summary",
  "The report presents 2019 start-of-year population estimates as the first projection year.")
assumption("model", "model_family",
  "Beaufort Assessment Model (BAM), statistical catch-age model.",
  "SEDAR 36 Update SAR, Sections 3.3-3.4 and Table 16",
  "Annual age-structured assessment; no update-specific native fitted object or input files were located.")
assumption("model", "model_dimensions",
  "Historical model years 1974-2018; ages 1-25+, with 2019 reported as a projection year.",
  "SEDAR 36 Update SAR, Tables 1-15",
  "The assessment uses age 25 as the plus group; composition sample sizes use the source's fishery and survey groupings.")
assumption("catch", "removal_inputs",
  "Commercial handline and longline removals are in whole weight; general recreational removals are in numbers.",
  "SEDAR 36 Update SAR, Table 2",
  "Observed landings and dead discards are combined in the source series. The table does not provide catch-at-age as numerical values.")
assumption("composition", "composition_inputs",
  "The assessment uses length and age compositions for commercial, recreational, and survey sources.",
  "SEDAR 36 Update SAR, Tables 4-5 and composition figures",
  "Tables 4-5 provide fish and trip sample sizes. Numeric observed composition matrices are not printed in the report; no values were digitized or reconstructed for this import.")
assumption("index", "abundance_indices",
  "Three aggregate indices: MARMAP chevron trap, MARMAP vertical longline, and headboat.",
  "SEDAR 36 Update SAR, Table 3",
  "Index values and CVs are reported; the multiplier for the index scale is not stated. Chevron-trap and vertical-longline series begin in 1996; the headboat series ends in 2010.")
assumption("biology", "age_specific_inputs",
  "Table 1 reports mid-year length and weight, female maturity, proportion female, and age-specific natural mortality for ages 1-25+.",
  "SEDAR 36 Update SAR, Table 1",
  "The assessment treats length CV as estimated and the other Table 1 quantities as input; all males are treated as mature.")
assumption("M", "natural_mortality",
  "Natural mortality is fixed and age-dependent in the base run.",
  "SEDAR 36 Update SAR, Table 1 and Section 3.3",
  "Table 1 values were imported directly; the assessment describes the age pattern as a Charnov curve scaled to M = 0.08 at age 56.")
assumption("biology", "spawning_biomass_definition",
  "SSB is total mature biomass of males and females at peak spawning in mid-year.",
  "SEDAR 36 Update SAR, Table 8 and Table 16",
  "Table 8 annual SSB is reported in metric tons; Table 16 gives benchmark estimates and Monte Carlo/Bootstrap summaries.")
assumption("timing", "survey_and_spawning_timing",
  "Spawning is represented at mid-year; exact within-year timing for the annual indices is not reported.",
  "SEDAR 36 Update SAR, Table 1 and Table 8",
  "No survey fraction of year was assigned.")
assumption("uncertainty", "annual_output_uncertainty",
  "Annual age-specific population, biomass, fishing mortality, and SSB tables provide point estimates without annual confidence intervals.",
  "SEDAR 36 Update SAR, Tables 6-15",
  "Table 16 separately reports Monte Carlo/Bootstrap medians and standard errors for benchmarks and related summary quantities.")

assumptions <- do.call(rbind, assumption_rows)
stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10339",
  scientific_name = "Epinephelus niveatus", common_name = "Snowy Grouper - South Atlantic",
  area = "South Atlantic Coast", region = "United States South Atlantic Coast",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10339; the SEDAR report also uses Hyporthodus niveatus. Distinct from snowy grouper units outside the South Atlantic.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2021L, terminal_year = 2018L,
  estimate_terminal_year = 2019L, assessment_type = "update_assessment",
  model_family = "Beaufort Assessment Model",
  model_version = "SEDAR 36 Update base run, revised January 2021",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = "https://sedarweb.org/documents/2020-update-sedar-36-update-assessment-report-south-atlantic-snowy-grouper-revised-january-2021-2/",
  framework_url = "https://sedarweb.org/assessments/sedar-36-update-south-atlantic-snowy-grouper/",
  data_url = "https://sedarweb.org/assessments/sedar-36-update-south-atlantic-snowy-grouper/",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest completed detailed assessment located for NOAA unit 10339; data through 2018 with 2019 projection estimates. Numeric composition matrices are not reported in the assessment tables; annual output uncertainty is not available, although Table 16 reports benchmark Monte Carlo/Bootstrap summaries.")

candidate_path <- file.path("discovery", "candidates.csv")
inventory_path <- file.path("discovery", "inventory_units.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv(file.path("database", "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- read.csv(file.path("database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    candidates$candidate_unit_id[candidate_row] != stock_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started" ||
    any(stocks$stock_id == stock_id) ||
    any(stocks$authority == "NOAA Fisheries" & stocks$authority_stock_id == "10339") ||
    any(assessments_existing$assessment_id == assessment_id)) {
  stop("NOAA South Atlantic Snowy Grouper candidate or database identity has changed.",
    call. = FALSE)
}
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)

row_key <- function(x, columns) {
  do.call(paste, c(lapply(x[columns], function(value) {
    value[is.na(value)] <- ""
    as.character(value)
  }), sep = "|"))
}
input_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
  "year", "age", "partition", "observation_id")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "year",
  "age", "age_group", "scenario")
if (anyDuplicated(row_key(inputs, input_key)) ||
    anyDuplicated(row_key(outputs, output_key)) ||
    nrow(inputs[inputs$measure %in% c("proportion_at_age", "frequency_at_age"), ]) != 0L) {
  stop("SEDAR 36 Update rows have duplicate keys or unsupported composition values.",
    call. = FALSE)
}

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Imported SEDAR 36 Update Tables 6-16: N and biomass at age, recruitment, SSB, total and apical F, selectivity, total removals, and benchmark estimates with reported Monte Carlo/Bootstrap medians and SEs.")
  candidates$decision_reason[candidate_row] <- paste(
    candidates$decision_reason[candidate_row],
    "Input and output records are partial: age-composition matrices are figure-only and annual population uncertainty is not reported.")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs, and ",
    nrow(outputs), " outputs from SEDAR 36 Update.")
}
