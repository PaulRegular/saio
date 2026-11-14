cache <- file.path("source_cache", "noaa_south_atlantic_golden_tilefish_sedar89_2025")
manifest_path <- file.path("provenance", "noaa_south_atlantic_golden_tilefish_sedar89_2025", "manifest.csv")
assessment_id <- "noaa_golden_tilefish_south_atlantic_sedar89_2025"
stock_id <- "noaa_golden_tilefish_south_atlantic"
candidate_id <- "NOAA:10384"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

local_lib <- file.path("source_cache", "r-lib")
if (dir.exists(local_lib)) .libPaths(c(local_lib, .libPaths()))
source("scripts/database/pacific_tables.R")
source("scripts/database/candidate_register_io.R")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the SEDAR 89 report tables.", call. = FALSE)
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

sar <- verify_source("sedar89_sar_2025.pdf")
invisible(verify_source("sedar89_wp03_reproductive_biology.pdf"))
invisible(verify_source("sedar89_wp04_recreational_length_compositions.pdf"))
invisible(verify_source("sedar89_wp05_commercial_discards.pdf"))
invisible(verify_source("sedar89_wp06_commercial_length_age_compositions.pdf"))
pages <- pdftools::pdf_text(sar)

number <- function(x) {
  x[x == "."] <- NA_character_
  x <- gsub(",", "", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

parse_year_table <- function(page, years, value_count) {
  parsed <- list()
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    year_position <- which(tokens %in% as.character(years) &
      seq_along(tokens) == length(tokens) - value_count)
    if (length(year_position) != 1L) next
    year_position <- year_position[1L]
    year <- as.integer(tokens[year_position])
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
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
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

years <- 1972:2022
ages <- 1:20
age_group <- ifelse(ages == 20L, "20+", NA_character_)

landings <- parse_year_table(40L, years, 3L)
composition_trips <- parse_year_table(42L, years, 4L)
composition_fish <- parse_year_table(43L, years, 4L)
indices <- parse_year_table(44L, years, 4L)
biology <- parse_age_table(45L, ages, 10L)
n_at_age <- parse_year_table(46L, years, 21L)
biomass_at_age_mt <- parse_year_table(47L, years, 21L)
biomass_at_age_klb <- parse_year_table(48L, years, 21L)
status <- parse_year_table(49L, years, 9L)
selectivity <- parse_age_table(50L, ages, 10L)
fully_selected_f <- parse_year_table(51L, years, 4L)
f_at_age <- parse_year_table(52L, years, 20L)
landings_numbers_at_age <- parse_year_table(53L, years, 20L)
landings_weight_at_age <- parse_year_table(54L, years, 20L)
landings_numbers_by_fleet <- parse_year_table(55L, years, 3L)
landings_weight_by_fleet <- parse_year_table(56L, years, 3L)
projections <- list(
  list(page = 58L, value = "F = FMSY starting in 2026"),
  list(page = 59L, value = "F target with P* = 0.30 starting in 2026"),
  list(page = 60L, value = "F target with P* = 0.20 starting in 2026")
)
projection_tables <- lapply(projections, function(x) {
  parse_year_table(x$page, 2023:2027, 12L)
})

expected_dimensions <- list(
  landings = c(51L, 3L), composition_trips = c(51L, 4L),
  composition_fish = c(51L, 4L), indices = c(51L, 4L),
  biology = c(20L, 10L), n_at_age = c(51L, 21L),
  biomass_at_age_mt = c(51L, 21L), biomass_at_age_klb = c(51L, 21L),
  status = c(51L, 9L), selectivity = c(20L, 10L),
  fully_selected_f = c(51L, 4L), f_at_age = c(51L, 20L),
  landings_numbers_at_age = c(51L, 20L),
  landings_weight_at_age = c(51L, 20L),
  landings_numbers_by_fleet = c(51L, 3L),
  landings_weight_by_fleet = c(51L, 3L)
)
parsed_tables <- mget(names(expected_dimensions))
if (any(!vapply(names(expected_dimensions), function(name) {
  identical(dim(parsed_tables[[name]]), expected_dimensions[[name]])
}, logical(1L))) ||
    any(!is.finite(biology)) || any(!is.finite(n_at_age)) ||
    any(!is.finite(biomass_at_age_mt)) || any(!is.finite(biomass_at_age_klb)) ||
    any(!is.finite(f_at_age)) || any(biology[, 8L] < 0 | biology[, 8L] > 1) ||
    any(biology[, 10L] <= 0) || any(indices[, c(3L, 4L)] < 0, na.rm = TRUE) ||
    any(abs(rowSums(n_at_age[, 1:20, drop = FALSE]) - n_at_age[, 21L]) > 0.15) ||
    any(abs(rowSums(biomass_at_age_mt[, 1:20, drop = FALSE]) - biomass_at_age_mt[, 21L]) > 2) ||
    any(vapply(projection_tables, function(x) any(!is.finite(x)), logical(1L)))) {
  stop("SEDAR 89 tables failed dimensions or source-value checks.", call. = FALSE)
}

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = NA_character_, survey = NA_character_, sex = NA_character_,
                      year = NA_integer_, age = NA_integer_, sampling_time = NA_real_,
                      partition = NA_character_, season = NA_character_,
                      observation_id = NA_character_,
                      transformation = NA_character_) {
  n <- max(length(value), length(fleet), length(survey), length(sex),
    length(year), length(age), length(sampling_time), length(partition), length(season),
    length(observation_id), length(transformation))
  year_basis <- if (length(year) == 1L && is.na(year)) NA_character_ else "calendar_year"
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, year = year,
    year_basis = year_basis, age = age, value = value, unit = unit,
    sampling_time = sampling_time, season = season, source_type = "official_table",
    source_reference = source_reference, transformation = transformation,
    notes = notes, partition = partition, observation_id = observation_id)
}

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
                       year = NA_integer_, age = NA_integer_, age_group = NA_character_,
                       fleet = NA_character_, survey = NA_character_, scenario = NA_character_,
                       se = NA_real_) {
  keep <- is.finite(value)
  if (!any(keep)) return(invisible(NULL))
  keep_values <- function(x) rep_len(x, length(value))[keep]
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs",
    n = sum(keep), assessment_id = assessment_id, type = type, measure = measure,
    fleet = keep_values(fleet), survey = keep_values(survey),
    year = keep_values(year), age = keep_values(age),
    age_group = keep_values(age_group), scenario = keep_values(scenario),
    value = value[keep], se = keep_values(se), unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes)
}

catch_specs <- list(
  list(column = 1L, fleet = "Commercial handline", measure = "landings_biomass",
    partition = "landings", unit = "1,000 lb gutted weight"),
  list(column = 2L, fleet = "Commercial longline", measure = "catch_biomass",
    partition = "landings_and_discards", unit = "1,000 lb gutted weight"),
  list(column = 3L, fleet = "General recreational (MRIP + SRHS)", measure = "landings_numbers",
    partition = "landings", unit = "1,000 fish")
)
for (spec in catch_specs) {
  value <- landings[, spec$column]
  keep <- is.finite(value)
  basis <- if (spec$measure == "landings_numbers") "numbers" else "biomass"
  notes <- if (spec$fleet == "Commercial longline") {
    "The assessment adds estimated commercial longline discards to landings and fits the sum as the fleet removal series. Values are the reported Table 1 series; no separate discard value is added to avoid double counting."
  } else if (spec$fleet == "Commercial handline") {
    "Commercial handline landings in gutted weight; the assessment assumes no commercial handline discards."
  } else {
    "General recreational landings combine MRIP and Southeast Region Headboat Survey estimates. The assessment fits the number of landed fish; MRIP discards are excluded and headboat discards are assumed zero."
  }
  add_input("catch", spec$measure, basis, value[keep], spec$unit,
    "SEDAR 89 SAR, Table 1, p. 39 and Sections 2.2-2.3",
    notes, fleet = spec$fleet, year = years[keep], partition = spec$partition)
  add_input("catch", "catch_cv", "relative_scale", rep(0.05, sum(keep)), "ratio",
    "SEDAR 89 SAR, Section 3.3.13; Table 2, p. 40",
    "The base assessment uses an arithmetic-scale CV of 0.05 for landings likelihoods. Table 2 reports separate MCBE-only CVs and is not the base-model likelihood input.",
    fleet = spec$fleet, year = years[keep], partition = spec$partition)
}

index_specs <- list(
  list(value_column = 1L, cv_column = 3L, measure = "relative_biomass_index",
    cv_measure = "biomass_index_cv", fleet = "Commercial longline", survey = NA_character_,
    unit = "relative index units", notes = "Commercial longline logbook index; model predictions are based on vulnerable biomass and converted from gutted weight to whole weight. Catchability is constant through time."),
  list(value_column = 2L, cv_column = 4L, measure = "relative_abundance_index",
    cv_measure = "abundance_index_cv", fleet = NA_character_, survey = "MARMAP longline survey",
    unit = "relative index units", notes = "Fishery-independent MARMAP longline index; model predictions are based on vulnerable abundance. Catchability is constant through time.")
)
for (spec in index_specs) {
  value <- indices[, spec$value_column]
  keep <- is.finite(value)
  add_input("index", spec$measure, "index_scale", value[keep], spec$unit,
    "SEDAR 89 SAR, Table 5, p. 43 and Section 3.3.11",
    paste(spec$notes, "The table does not identify an absolute multiplier."),
    fleet = spec$fleet, survey = spec$survey, year = years[keep],
    season = "annual", sampling_time = rep(0.5, sum(keep)))
  cv <- indices[, spec$cv_column]
  keep_cv <- is.finite(cv)
  add_input("index", spec$cv_measure, "relative_scale", cv[keep_cv], "ratio",
    "SEDAR 89 SAR, Table 5, p. 43",
    "Source-reported coefficient of variation for the matching aggregate index.",
    fleet = spec$fleet, survey = spec$survey, year = years[keep_cv], season = "annual")
}

composition_specs <- list(
  list(column = 1L, fleet = "General recreational (MRIP + SRHS)", survey = NA_character_, label = "recreational length composition"),
  list(column = 2L, fleet = "Commercial handline", survey = NA_character_, label = "commercial handline age composition"),
  list(column = 3L, fleet = "Commercial longline", survey = NA_character_, label = "commercial longline age composition"),
  list(column = 4L, fleet = NA_character_, survey = "MARMAP longline survey", label = "MARMAP age composition")
)
for (table in list(
  list(values = composition_trips, unit = "trips", page = 41L, table = 3L),
  list(values = composition_fish, unit = "fish", page = 42L, table = 4L)
)) {
  for (spec in composition_specs) {
    value <- table$values[, spec$column]
    keep <- !is.na(value)
    add_input("biology", "composition_sample_count", "numbers", value[keep],
      table$unit, paste0("SEDAR 89 SAR, Table ", table$table, ", p. ", table$page),
      paste("Reported sample count for the", spec$label,
        "series. These counts are not composition proportions or age-specific abundance indices."),
      fleet = spec$fleet, survey = spec$survey, year = years[keep],
      observation_id = paste0("SEDAR89_Table", table$table, "_", gsub(" ", "_", spec$label)))
  }
}

for (j in seq_along(ages)) {
  age <- ages[j]
  plus_note <- if (age == 20L) " Age 20 is the 20+ group." else ""
  add_input("biology", "growth_length_at_age", "native_covariate", biology[j, 1L],
    "mm total length", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed population mean length at age.", plus_note), age = age)
  add_input("weight", "weight_at_age", "kg_per_fish", biology[j, 4L],
    "kg whole weight per fish", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed whole weight at age used for population biomass.", plus_note), age = age)
  add_input("weight", "weight_at_age", "weight_per_fish", biology[j, 6L],
    "lb gutted weight per fish", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed gutted weight at age. Kept in its source unit, distinct from whole weight.", plus_note), age = age)
  add_input("biology", "proportion_female_at_age", "proportion", biology[j, 7L],
    "proportion", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed population proportion female at age.", plus_note), age = age)
  add_input("maturity", "maturity_at_age", "proportion", biology[j, 8L],
    "proportion", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed proportion of females mature at age.", plus_note),
    sex = "female", age = age)
  add_input("biology", "reproductive_potential_at_age", "egg_count", biology[j, 9L],
    "million eggs per female fish", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed age-specific egg production, defined as proportion of females mature multiplied by total fecundity.", plus_note),
    sex = "female", age = age)
  add_input("M", "natural_mortality_at_age", "per_year", biology[j, 10L],
    "per_year", "SEDAR 89 SAR, Table 6, p. 44",
    paste0("Fixed age-specific natural mortality. Values are varied in the MCBE; age 20 is the 20+ group."), age = age)
}

output_year <- rep(years, each = length(ages))
output_age <- rep(ages, times = length(years))
output_age_group <- rep(age_group, times = length(years))
add_output("population", "numbers_at_age",
  as.vector(t(n_at_age[, 1:20, drop = FALSE])), "1,000 fish",
  "SEDAR 89 SAR, Table 7, p. 45",
  "Estimated start-of-year abundance at age; age 20 is the 20+ group.",
  year = output_year, age = output_age, age_group = output_age_group,
  scenario = rep("Base-run estimate", length(output_year)))
add_output("population", "total_numbers", n_at_age[, 21L], "1,000 fish",
  "SEDAR 89 SAR, Table 7, p. 45",
  "Source-reported total column; it equals the sum across age groups within table rounding.",
  year = years, scenario = rep("Base-run estimate", length(years)))
add_output("biomass", "biomass_at_age",
  as.vector(t(biomass_at_age_mt[, 1:20, drop = FALSE])), "metric tons",
  "SEDAR 89 SAR, Table 8, p. 46",
  "Estimated start-of-year biomass at age; age 20 is the 20+ group.",
  year = output_year, age = output_age, age_group = output_age_group,
  scenario = rep("Base-run estimate", length(output_year)))
add_output("biomass", "total_biomass_from_age_surface", biomass_at_age_mt[, 21L],
  "metric tons", "SEDAR 89 SAR, Table 8, p. 46",
  "Source-reported total column from the biomass-at-age surface.", year = years,
  scenario = rep("Base-run estimate", length(years)))
add_output("biomass", "biomass_at_age",
  as.vector(t(biomass_at_age_klb[, 1:20, drop = FALSE])), "1,000 lb whole weight",
  "SEDAR 89 SAR, Table 9, p. 47",
  "Source-reported alternate unit for start-of-year biomass at age; age 20 is the 20+ group.",
  year = output_year, age = output_age, age_group = output_age_group,
  scenario = rep("Base-run estimate; Table 9 source units", length(output_year)))
add_output("biomass", "total_biomass_from_age_surface", biomass_at_age_klb[, 21L],
  "1,000 lb whole weight", "SEDAR 89 SAR, Table 9, p. 47",
  "Source-reported total column in the Table 9 whole-weight unit.", year = years,
  scenario = rep("Base-run estimate; Table 9 source units", length(years)))

status_specs <- list(
  list(column = 2L, type = "mortality", measure = "F_ratio_to_Fmsy", unit = "ratio", notes = "Apical F divided by the assessment FMSY series."),
  list(column = 3L, type = "biomass", measure = "total_biomass", unit = "1,000 lb whole weight", notes = "Total biomass at start of year."),
  list(column = 4L, type = "biomass", measure = "total_biomass_ratio_to_unfished", unit = "ratio", notes = "Total biomass divided by unfished biomass."),
  list(column = 5L, type = "biomass", measure = "SSB", unit = "trillion eggs", notes = "Spawning stock biomass is total egg production of mature females at peak spawning, 15 May (0.37 of the year)."),
  list(column = 6L, type = "biomass", measure = "SSB_ratio_to_SSBMSY", unit = "ratio", notes = "Spawning egg production divided by SSBMSY."),
  list(column = 7L, type = "biomass", measure = "SSB_ratio_to_MSST", unit = "ratio", notes = "Spawning egg production divided by MSST."),
  list(column = 8L, type = "biology", measure = "current_spawning_potential_ratio", unit = "ratio", notes = "Annual static spawning-potential ratio."),
  list(column = 9L, type = "recruitment", measure = "recruitment", unit = "million age-1 fish", notes = "Annual age-1 recruitment.")
)
for (spec in status_specs) {
  add_output(spec$type, spec$measure, status[, spec$column], spec$unit,
    "SEDAR 89 SAR, Table 10, p. 48", spec$notes, year = years,
    scenario = rep("Base-run estimate", length(years)))
}

selectivity_specs <- list(
  list(column = 3L, fleet = "Commercial handline", year = 1972L),
  list(column = 4L, fleet = "Commercial handline", year = 2020L),
  list(column = 5L, fleet = "Commercial longline", year = 1972L),
  list(column = 6L, fleet = "Commercial longline", year = 2020L),
  list(column = 7L, fleet = "General recreational (MRIP + SRHS)", year = NA_integer_),
  list(column = 8L, fleet = NA_character_, survey = "MARMAP longline survey", year = NA_integer_),
  list(column = 9L, fleet = "F-weighted average landings selectivity", year = NA_integer_)
)
for (spec in selectivity_specs) {
  add_output("biology", "fleet_selectivity_at_age", selectivity[, spec$column],
    "proportion", "SEDAR 89 SAR, Table 11, p. 49",
    "Source-reported selectivity at age. The 1972 and 2020 labels identify the first year of the two commercial selectivity blocks; the other curves are reported as time-invariant or averaged.",
    age = ages, age_group = age_group, fleet = spec$fleet,
    survey = if (is.null(spec$survey)) NA_character_ else spec$survey,
    year = rep(spec$year, length(ages)), scenario = rep("Base-run estimate", length(ages)))
}

fleet_f_specs <- list(
  list(column = 1L, fleet = "Commercial handline"),
  list(column = 2L, fleet = "Commercial longline"),
  list(column = 3L, fleet = "General recreational (MRIP + SRHS)")
)
for (spec in fleet_f_specs) {
  add_output("mortality", "fully_selected_fishing_mortality",
    fully_selected_f[, spec$column], "per_year", "SEDAR 89 SAR, Table 12, p. 50",
    "Estimated annual fully selected F for the named fleet.", year = years,
    fleet = rep(spec$fleet, length(years)), scenario = rep("Base-run estimate", length(years)))
}
add_output("mortality", "apical_F", fully_selected_f[, 4L], "per_year",
  "SEDAR 89 SAR, Table 12, p. 50",
  "Source-reported apical F, the maximum total F at age after summing fleets.",
  year = years, scenario = rep("Base-run estimate", length(years)))
add_output("mortality", "fishing_mortality_at_age",
  as.vector(t(f_at_age)), "per_year", "SEDAR 89 SAR, Table 13, p. 51",
  "Estimated instantaneous total fishing mortality at age; age 20 is the 20+ group.",
  year = output_year, age = output_age, age_group = output_age_group,
  scenario = rep("Base-run estimate", length(output_year)))
add_output("catch", "estimated_landings_numbers_at_age",
  as.vector(t(landings_numbers_at_age)), "1,000 fish",
  "SEDAR 89 SAR, Table 14, p. 52",
  "Estimated total landings at age; age 20 is the 20+ group.",
  year = output_year, age = output_age, age_group = output_age_group,
  scenario = rep("Base-run estimate", length(output_year)))
add_output("catch", "estimated_landings_weight_at_age",
  as.vector(t(landings_weight_at_age)), "1,000 lb gutted weight",
  "SEDAR 89 SAR, Table 15, p. 53",
  "Estimated total landings weight at age; age 20 is the 20+ group.",
  year = output_year, age = output_age, age_group = output_age_group,
  scenario = rep("Base-run estimate", length(output_year)))

fleet_names <- c("Commercial handline", "Commercial longline",
  "General recreational (MRIP + SRHS)")
for (j in seq_along(fleet_names)) {
  add_output("catch", "predicted_landings_numbers", landings_numbers_by_fleet[, j],
    "1,000 fish", "SEDAR 89 SAR, Table 16, p. 54",
    "Estimated base-run annual landings in numbers for the named fleet.",
    year = years, fleet = rep(fleet_names[j], length(years)),
    scenario = rep("Base-run estimate", length(years)))
  add_output("catch", "predicted_landings_weight", landings_weight_by_fleet[, j],
    "1,000 lb gutted weight", "SEDAR 89 SAR, Table 17, p. 55",
    "Estimated base-run annual landings in gutted weight for the named fleet.",
    year = years, fleet = rep(fleet_names[j], length(years)),
    scenario = rep("Base-run estimate", length(years)))
}

benchmark_rows <- data.frame(
  measure = c("Fmsy", "F75_percent_Fmsy", "Bmsy", "SSBMSY", "MSST", "msy",
    "landings_at_75_percent_msy", "mean_current_landings", "RMSY",
    "F_ratio_to_Fmsy", "SSB_ratio_to_MSST", "SSB_ratio_to_SSBMSY"),
  estimate = c(0.204, NA, 6158.52, 515.42, 386.57, 523.31, 502.45, 373.42,
    0.05, 0.72, 1.31, 0.98),
  median = c(0.213, 0.16, 5856.66, 485.07, 363.80, 521.82, 501.52, 371.24,
    0.04, 0.71, 1.33, 1.00),
  se = c(0.06, 0.05, 997.99, 1165.03, 873.77, 66.82, 67.16, 16.91,
    0.01, 0.31, 0.48, 0.36),
  unit = c("per_year", "per_year", "1,000 lb whole weight",
    "Table 18 as printed; egg scale unresolved", "Table 18 as printed; egg scale unresolved",
    "1,000 lb gutted weight", "1,000 lb gutted weight", "1,000 lb gutted weight",
    "million age-1 fish", "ratio", "ratio", "ratio"),
  stringsAsFactors = FALSE
)
for (j in seq_len(nrow(benchmark_rows))) {
  spec <- benchmark_rows[j, ]
  note <- "The report gives a base-run estimate, an MCBE median, and an MCBE standard error; the SE approximates ensemble uncertainty and is not an annual time-series SE."
  scenario <- "Base-run estimate"
  if (spec$measure %in% c("SSBMSY", "MSST")) {
    note <- paste(note, "Table 18 prints values 1,000 times larger than the corresponding Section 4.8 narrative values and labels them trillion eggs. The raw Table 18 values are retained without scale adjustment; see the source review.")
    scenario <- "Table 18 as printed; scale discrepancy unresolved"
  }
  add_output("management", spec$measure, spec$estimate, spec$unit,
    "SEDAR 89 SAR, Table 18, p. 56 and Section 4.8",
    note, scenario = scenario)
  add_output("management", spec$measure, spec$median, spec$unit,
    "SEDAR 89 SAR, Table 18, p. 56 and Section 4.8",
    note, scenario = if (spec$measure %in% c("SSBMSY", "MSST")) {
      "MCBE median; Table 18 as printed; scale discrepancy unresolved"
    } else "Monte Carlo/Bootstrap median",
    se = spec$se)
}
for (spec in list(
  list(measure = "SSBMSY", estimate = 0.515, median = 0.485, unit = "trillion eggs"),
  list(measure = "MSST", estimate = 0.387, median = 0.364, unit = "trillion eggs")
)) {
  add_output("management", spec$measure, spec$estimate, spec$unit,
    "SEDAR 89 SAR, Section 4.8",
    "Source narrative value. The Table 18 tabulated value conflicts by a factor of 1,000; both representations are retained without silently converting the table.",
    scenario = "Section 4.8 narrative estimate")
  add_output("management", spec$measure, spec$median, spec$unit,
    "SEDAR 89 SAR, Section 4.8",
    "Source narrative MCBE median. The Table 18 tabulated value conflicts by a factor of 1,000; both representations are retained without silently converting the table.",
    scenario = "Section 4.8 narrative MCBE median")
}

projection_specs <- list(
  list(index = 1L, name = "F = FMSY starting in 2026", page = 57L),
  list(index = 2L, name = "F target with P* = 0.30 starting in 2026", page = 58L),
  list(index = 3L, name = "F target with P* = 0.20 starting in 2026", page = 59L)
)
for (spec in projection_specs) {
  x <- projection_tables[[spec$index]]
  py <- rep(2023:2027, each = 2L)
  for (j in seq_len(2L)) {
    estimate_type <- if (j == 1L) "expected" else "MCBE median"
    cols <- if (j == 1L) c(1L, 3L, 5L, 7L, 9L) else c(2L, 4L, 6L, 8L, 10L)
    years_projected <- 2023:2027
    suffix <- paste(estimate_type, spec$name, sep = "; ")
    add_output("recruitment", "recruitment", x[, cols[1L]], "million age-1 fish",
      paste0("SEDAR 89 SAR, Table ", 18L + spec$index, ", p. ", spec$page),
      "Projected age-1 recruitment.", year = years_projected,
      scenario = rep(suffix, length(years_projected)))
    add_output("mortality", "fishing_mortality_summary", x[, cols[2L]], "per_year",
      paste0("SEDAR 89 SAR, Table ", 18L + spec$index, ", p. ", spec$page),
      "Projected fishing-mortality rate under the named management scenario.",
      year = years_projected, scenario = rep(suffix, length(years_projected)))
    add_output("biomass", "SSB", x[, cols[3L]], "trillion eggs",
      paste0("SEDAR 89 SAR, Table ", 18L + spec$index, ", p. ", spec$page),
      "Projected spawning stock, defined as mature-female egg production.",
      year = years_projected, scenario = rep(suffix, length(years_projected)))
    add_output("catch", "predicted_landings_numbers", x[, cols[4L]], "1,000 fish",
      paste0("SEDAR 89 SAR, Table ", 18L + spec$index, ", p. ", spec$page),
      "Projected total landings in numbers across fleets.", year = years_projected,
      fleet = rep("All fleets", length(years_projected)),
      scenario = rep(suffix, length(years_projected)))
    add_output("catch", "predicted_landings_weight", x[, cols[5L]], "1,000 lb gutted weight",
      paste0("SEDAR 89 SAR, Table ", 18L + spec$index, ", p. ", spec$page),
      "Projected total landings in gutted weight across fleets.", year = years_projected,
      fleet = rep("All fleets", length(years_projected)),
      scenario = rep(suffix, length(years_projected)))
  }
  add_output("probability", "probability_at_or_below_SSBMSY",
    x[, 11L], "percent", paste0("SEDAR 89 SAR, Table ", 18L + spec$index,
      ", p. ", spec$page),
    "Percentage of stochastic projection replicates with SSB at or below SSBMSY.",
    year = 2023:2027, scenario = rep(spec$name, 5L))
  add_output("probability", "probability_at_or_below_MSST",
    x[, 12L], "percent", paste0("SEDAR 89 SAR, Table ", 18L + spec$index,
      ", p. ", spec$page),
    "Percentage of stochastic projection replicates with SSB at or below MSST.",
    year = 2023:2027, scenario = rep(spec$name, 5L))
}

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
source_checks <- c(
  input_rows = nrow(inputs) > 0L,
  output_rows = nrow(outputs) > 0L,
  landings_year_1972 = any(inputs$measure == "landings_biomass" & inputs$year == 1972L & inputs$value == 0.40),
  landings_recreational_1981 = any(inputs$measure == "landings_numbers" & inputs$year == 1981L & inputs$value == 227.08),
  index_central_1996 = any(inputs$measure == "relative_biomass_index" & inputs$year == 1996L & inputs$value == 0.571),
  M_age_20 = any(inputs$measure == "natural_mortality_at_age" & inputs$age == 20L & inputs$value == 0.13),
  N_age_1_1972 = any(outputs$measure == "numbers_at_age" & outputs$year == 1972L & outputs$age == 1L & outputs$value == 619.38),
  F_age_20_2022 = any(outputs$measure == "fishing_mortality_at_age" & outputs$year == 2022L & outputs$age == 20L),
  SSB_2022 = any(outputs$measure == "SSB" & outputs$year == 2022L & outputs$value > 0 & outputs$value < 2),
  benchmark_scale_reviewed = any(outputs$measure == "SSBMSY" & grepl("scale discrepancy unresolved", outputs$scenario, fixed = TRUE)),
  projections_present = any(outputs$measure == "probability_at_or_below_MSST" & outputs$year == 2027L)
)
if (any(!source_checks)) {
  stop("SEDAR 89 values failed checks: ",
    paste(names(source_checks)[!source_checks], collapse = ", "), call. = FALSE)
}

assumption_rows <- list()
assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes)
}
assumption("assessment", "run_identity", "SEDAR 89 South Atlantic Golden Tilefish Rev2; revised September 2025; data through 2022; NOAA Stock SMART assessment 14290.",
  "SEDAR 89 SAR, cover and document list; NOAA Stock SMART 10384",
  "This is the South Atlantic unit, separate from Gulf and Mid-Atlantic golden tilefish.")
assumption("model", "model_family", "Beaufort Assessment Model (BAM), integrated statistical catch-age model.",
  "SEDAR 89 SAR, Sections 3.1-3.3",
  "Model code is AD Model Builder; no run-matched native fitted object or input archive was located in the reviewed sources.")
assumption("model", "model_dimensions", "Model years 1972-2022; ages 1-20+; sexes modeled through female proportion and age-specific reproductive output.",
  "SEDAR 89 SAR, Tables 6-17",
  "Age 20 is the plus group. The assessment report contains a 2023-2027 projection section under three F scenarios; projections were imported separately by scenario.")
assumption("catch", "removals", "Commercial handline landings; commercial longline landings plus estimated discards; recreational landings in numbers.",
  "SEDAR 89 SAR, Table 1 and Sections 2.2-2.3; SEDAR89-WP-05",
  "Commercial longline discards are added to landings and fit as one fleet removal series. Handline and headboat discards are assumed zero; MRIP discards are excluded.")
assumption("catch", "landings_likelihood", "Lognormal likelihoods with an arithmetic-scale CV of 0.05 for landings in the base model.",
  "SEDAR 89 SAR, Section 3.3.13 and Table 2",
  "Table 2's separate annual recreational component CVs are used for MCBE bootstrapping, not the base-model likelihood; the report's base likelihood uses 0.05.")
assumption("composition", "composition_likelihood", "Length and age compositions are fit with a Dirichlet-multinomial likelihood.",
  "SEDAR 89 SAR, Sections 2.5-2.6 and 3.3.13; Tables 3-4",
  "The likelihood uses annual trip counts, adjusted by estimated variance-inflation parameters. Sample counts are imported; numeric observed composition arrays remain figure-only and were not digitized.")
assumption("composition", "ageing_error", "An ageing-error matrix estimated from a reference set of otoliths read by three readers is applied to age compositions.",
  "SEDAR 89 SAR, Section 2.6",
  "The numerical transition matrix was not available as a report table or in the reviewed supporting files.")
assumption("index", "abundance_indices", "Commercial longline biomass index for 1993-2006 and discontinuous MARMAP longline abundance index for 1996-2016.",
  "SEDAR 89 SAR, Table 5, Section 3.3.11",
  "Index predictions are evaluated at mid-year (sampling_time 0.5). Commercial CPUE is converted from gutted to whole weight in the model; indices use time-constant catchability. Absolute index multipliers are not stated.")
assumption("biology", "fixed_age_inputs", "Population length, whole and gutted weight, proportion female, female maturity, reproductive output and age-specific natural mortality are fixed at ages 1-20+.",
  "SEDAR 89 SAR, Table 6; SEDAR89-WP-03",
  "The assessment uses total egg production of mature females, not conventional biomass, as SSB.")
assumption("biology", "growth", "Population and female length-at-age follow separate von Bertalanffy growth curves; t0 is fixed at -0.5 in the base run.",
  "SEDAR 89 SAR, Section 2.2 and Table 6",
  "Whole weight is used for population biomass; female growth and reproductive output are used for spawning biomass.")
assumption("M", "natural_mortality", "Natural mortality is fixed and age-dependent in the base run.",
  "SEDAR 89 SAR, Table 6 and Section 3.3",
  "The age-specific vector is imported. MCBE varies natural-mortality inputs; the source values are not estimated annual M-at-age.")
assumption("timing", "spawning_and_index_timing", "Spawning stock is evaluated at peak spawning on 15 May (0.37 of the year); index predictions are evaluated at mid-year (0.5).",
  "SEDAR 89 SAR, Sections 2.2, 3.3.11 and Table 10",
  "The spawning fraction is not used as the survey timing.")
assumption("recruitment", "stock_recruitment", "Beverton-Holt spawner-recruit relationship; estimated h=0.58 and R0=500,900 age-1 fish; log-scale recruitment SD fixed at 0.6.",
  "SEDAR 89 SAR, Section 4.6",
  "Reported R0 is preserved as a source estimate; annual recruitment is age 1.")
assumption("uncertainty", "MCBE", "The base model was refit in 4,000 MCBE trials, of which 3,043 were retained.",
  "SEDAR 89 SAR, Section 3.9 and Table 18",
  "Table 18 reports MCBE medians and standard errors for benchmarks/status indicators. Annual age-specific surfaces are point estimates without annual uncertainty.")
assumption("outputs", "SSB_reference_scale", "Annual SSB in Table 10 is about 0.5 trillion eggs near the terminal year; Table 18 reports SSBMSY and MSST values about 1,000 times larger under a trillion-egg label.",
  "SEDAR 89 SAR, Table 10, Table 18 and Section 4.8",
  "Section 4.8 narrative values (SSBMSY 0.515/0.485 and MSST 0.387/0.364 trillion eggs) conflict with raw Table 18 values. Raw values and narrative values are stored as distinct scenarios without conversion.")

assumptions <- do.call(rbind, assumption_rows)
stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10384",
  scientific_name = "Lopholatilus chamaeleonticeps",
  common_name = "Golden Tilefish - South Atlantic",
  area = "South Atlantic Coast", region = "United States South Atlantic Coast",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10384; the South Atlantic assessment is distinct from Gulf of Mexico and Mid-Atlantic golden tilefish.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2025L, terminal_year = 2022L,
  estimate_terminal_year = 2022L, assessment_type = "operational_assessment",
  model_family = "Beaufort Assessment Model",
  model_version = "SEDAR 89 Rev2 base run, September 2025",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = "https://sedarweb.org/documents/sedar-89-golden-tilefish-stock-assessment-report-updated-september-30-2025/",
  framework_url = "https://sedarweb.org/assessments/sedar-89-south-atlantic-tilefish/",
  data_url = "https://sedarweb.org/assessments/sedar-89-south-atlantic-tilefish/",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest accepted NOAA Stock SMART assessment reviewed for unit 10384; data through 2022. Numerical composition arrays and the age-error matrix remain unrecovered. Table 18 SSB benchmark scale conflicts with Section 4.8 and Table 10; both source representations are retained without conversion.")

candidate_path <- file.path("discovery", "candidates.csv")
inventory_path <- file.path("discovery", "inventory_units.csv")
selection_path <- file.path("discovery", "selected_batch_25_2026.csv")
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
    any(stocks$authority_stock_id == "10384" & stocks$authority == "NOAA Fisheries") ||
    any(assessments_existing$assessment_id == assessment_id)) {
  stop("NOAA South Atlantic golden tilefish candidate or database identity has changed.", call. = FALSE)
}
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
selection <- read.csv(selection_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selection_row <- which(selection$candidate_id == candidate_id)
if (length(selection_row) != 1L) stop("Expected one selected-batch row for NOAA:10384.", call. = FALSE)

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$weights_evidence[candidate_row] <- paste(
    candidates$weights_evidence[candidate_row],
    "Imported Table 6 whole and gutted weight at age for ages 1-20+.")
  candidates$maturity_evidence[candidate_row] <- paste(
    candidates$maturity_evidence[candidate_row],
    "Imported female maturity and reproductive output at age from Table 6.")
  candidates$timing_evidence[candidate_row] <- paste(
    candidates$timing_evidence[candidate_row],
    "Confirmed SSB timing 0.37 at 15 May and mid-year index predictions (0.5).")
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Imported Tables 7-18, including N/biomass/F/landings at age, annual status, fleet selectivity, benchmarks, and projections. Table 18 egg-scale conflict is documented.")
  candidates$decision_reason[candidate_row] <- paste(
    candidates$decision_reason[candidate_row],
    "Partial source import completed; numerical composition arrays and ageing-error matrix remain unresolved.")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
  selection$curation_status[selection_row] <- "partial_source_import"
  write.csv(selection, selection_path, row.names = FALSE, na = "")
  message("Imported NOAA South Atlantic Golden Tilefish SEDAR 89: ",
    nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs and ",
    nrow(outputs), " outputs; completeness remains partial.")
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment),
    " assessment, ", nrow(assumptions), " assumptions, ", nrow(inputs),
    " inputs and ", nrow(outputs), " outputs from SEDAR 89.")
}
