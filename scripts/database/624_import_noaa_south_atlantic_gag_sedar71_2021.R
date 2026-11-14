root <- "."
cache <- file.path("source_cache", "noaa_gag_sedar71_2021")
manifest_source <- file.path(cache, "manifest.csv")
manifest_path <- file.path("provenance", "noaa_gag_sedar71_2021", "manifest.csv")
stock_id <- "noaa_gag_south_atlantic"
assessment_id <- "noaa_gag_south_atlantic_sedar71_2021"
candidate_id <- "NOAA:10349"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source("scripts/database/pacific_tables.R")
source("scripts/database/candidate_register_io.R")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract SEDAR 71 tables.", call. = FALSE)
}

manifest <- read.csv(manifest_source, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
manifest$file <- paste0("source_cache/noaa_gag_sedar71_2021/",
  basename(manifest$file))
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

sar <- verify_source("sedar71_final_report_2021.pdf")
wp04 <- verify_source("sedar71_wp04_chevron_age_2019.pdf")
invisible(verify_source("sedar71_wp03_reproductive_parameters.pdf"))
invisible(verify_source("sedar71_wp05_recreational_survey.pdf"))
invisible(verify_source("sedar71_wp02_video_index.pdf"))
sar_pages <- pdftools::pdf_text(sar)
wp04_data <- pdftools::pdf_data(wp04)

number <- function(x) {
  x[x == "."] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

parse_year_table <- function(pages, page, years, value_count) {
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  parsed <- list()
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (!length(tokens)) next
    year_position <- which(grepl("^(19|20)[0-9]{2}$", tokens) & tokens %in% as.character(years))
    if (!length(year_position)) next
    year_position <- year_position[1L]
    year <- as.integer(tokens[year_position])
    if (!year %in% years || length(tokens) - year_position != value_count) next
    if (as.character(year) %in% names(parsed)) {
      stop("Duplicate year ", year, " on PDF page ", page, call. = FALSE)
    }
    parsed[[as.character(year)]] <- number(tokens[seq.int(year_position + 1L, length(tokens))])
  }
  if (!setequal(names(parsed), as.character(years))) {
    stop("Unexpected year coverage on PDF page ", page, call. = FALSE)
  }
  values <- do.call(rbind, parsed[as.character(years)])
  rownames(values) <- as.character(years)
  values
}

parse_age_table <- function(pages, page, ages, value_count) {
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  parsed <- list()
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (!length(tokens) || !tokens[1L] %in% as.character(ages) ||
        length(tokens) != value_count + 1L) next
    age <- as.integer(tokens[1L])
    if (as.character(age) %in% names(parsed)) {
      stop("Duplicate age ", age, " on PDF page ", page, call. = FALSE)
    }
    parsed[[as.character(age)]] <- number(tokens[-1L])
  }
  if (!setequal(names(parsed), as.character(ages))) {
    stop("Unexpected age coverage on PDF page ", page, call. = FALSE)
  }
  values <- do.call(rbind, parsed[as.character(ages)])
  rownames(values) <- as.character(ages)
  values
}

parse_chevron_table <- function(page, percentage = FALSE) {
  page_data <- wp04_data[[page]]
  header_y <- page_data$y[page_data$text == "Calendar"][1L]
  header <- page_data[page_data$y == header_y &
    grepl("^(19|20)[0-9]{2}$", page_data$text), , drop = FALSE]
  header <- header[order(header$x), , drop = FALSE]
  years <- as.integer(header$text)
  expected_years <- c(1990:2002, 2004:2019)
  if (!identical(years, expected_years)) {
    stop("Unexpected chevron composition years on WP04 page ", page, call. = FALSE)
  }
  age_rows <- page_data[page_data$x < 80 & page_data$y > header_y &
    page_data$text %in% as.character(1:16), , drop = FALSE]
  age_rows <- age_rows[order(age_rows$y), , drop = FALSE]
  values <- matrix(NA_real_, nrow = nrow(age_rows), ncol = length(years),
    dimnames = list(age_rows$text, as.character(years)))
  year_right_edges <- header$x + header$width
  for (i in seq_len(nrow(age_rows))) {
    row <- age_rows[i, , drop = FALSE]
    cells <- page_data[page_data$y == row$y & page_data$x > 80 &
      grepl("^[0-9]+(\\.[0-9]+)?$", page_data$text), , drop = FALSE]
    for (j in seq_len(nrow(cells))) {
      right_edge <- cells$x[j] + cells$width[j]
      column <- which.min(abs(year_right_edges - right_edge))
      if (abs(year_right_edges[column] - right_edge) > 5 ||
          !is.na(values[i, column])) {
        stop("Could not align chevron age cell on WP04 page ", page,
          call. = FALSE)
      }
      values[i, column] <- as.numeric(cells$text[j])
    }
  }
  if (anyDuplicated(rownames(values)) || !nrow(values)) {
    stop("Unexpected chevron age rows on WP04 page ", page, call. = FALSE)
  }
  if (percentage) {
    if (any(values < 0, na.rm = TRUE) || any(colSums(values, na.rm = TRUE) > 100.1)) {
      stop("Chevron age percentages exceed 100 on WP04 page ", page, call. = FALSE)
    }
    values <- values / 100
  }
  list(years = years, values = values)
}

parse_chevron_summary <- function(page, label, years) {
  page_data <- wp04_data[[page]]
  label_row <- page_data[page_data$text == label, , drop = FALSE]
  if (nrow(label_row) != 1L) {
    stop("Could not identify the ", label, " row on WP04 page ", page,
      call. = FALSE)
  }
  header_y <- page_data$y[page_data$text == "Calendar"][1L]
  header <- page_data[page_data$y == header_y &
    grepl("^(19|20)[0-9]{2}$", page_data$text), , drop = FALSE]
  header <- header[order(header$x), , drop = FALSE]
  cells <- page_data[page_data$y == label_row$y & page_data$x > 80 &
    grepl("^[0-9]+$", page_data$text), , drop = FALSE]
  values <- rep(NA_real_, length(years))
  year_right_edges <- header$x + header$width
  for (i in seq_len(nrow(cells))) {
    right_edge <- cells$x[i] + cells$width[i]
    column <- which.min(abs(year_right_edges - right_edge))
    if (abs(year_right_edges[column] - right_edge) > 5 ||
        !is.na(values[column])) {
      stop("Could not align the ", label, " row on WP04 page ", page,
        call. = FALSE)
    }
    values[column] <- as.numeric(cells$text[i])
  }
  if (length(values) != length(years)) {
    stop("Unexpected ", label, " coverage on WP04 page ", page, call. = FALSE)
  }
  values
}

age_years <- 1962:2019
projection_years <- 1962:2020
ages <- 1:16
biology <- parse_age_table(sar_pages, 74L, ages, 8L)
catch <- parse_year_table(sar_pages, 75L, age_years, 7L)
indices <- parse_year_table(sar_pages, 76L, 1980:2019, 4L)
sample_fish <- parse_year_table(sar_pages, 77L, 1980:2019, 5L)
sample_trips <- parse_year_table(sar_pages, 78L, 1980:2019, 5L)
n_at_age <- parse_year_table(sar_pages, 79L, projection_years, 17L)
biomass_at_age <- parse_year_table(sar_pages, 80L, projection_years, 17L)
status <- parse_year_table(sar_pages, 81L, projection_years, 8L)
selectivity <- parse_age_table(sar_pages, 82L, ages, 11L)
f_full <- parse_year_table(sar_pages, 83L, age_years, 8L)
landings_n <- parse_year_table(sar_pages, 84L, age_years, 5L)
landings_w <- parse_year_table(sar_pages, 85L, age_years, 5L)
discards_n <- parse_year_table(sar_pages, 86L, 1981:2019, 4L)
discards_w <- parse_year_table(sar_pages, 87L, 1981:2019, 4L)
chevron_counts <- parse_chevron_table(13L)
chevron_props <- parse_chevron_table(14L, percentage = TRUE)
chevron_fish <- parse_chevron_summary(13L, "Fish", chevron_counts$years)
chevron_deployments <- parse_chevron_summary(13L, "Deployments", chevron_counts$years)
common_ages <- intersect(rownames(chevron_counts$values),
  rownames(chevron_props$values))
count_proportions <- sweep(chevron_counts$values[common_ages, , drop = FALSE],
  2L, chevron_fish, "/")
reported_proportions <- chevron_props$values[common_ages, , drop = FALSE]
comparable_cells <- is.finite(count_proportions) & is.finite(reported_proportions)
chevron_mismatch <- comparable_cells & abs(count_proportions -
  reported_proportions) > 0.00015
chevron_mismatch_count <- sum(chevron_mismatch)
message("Chevron Tables 4 and 5 differ in ", chevron_mismatch_count,
  " overlapping age-year cells; both tables will be preserved as published.")

if (!identical(dim(biology), c(16L, 8L)) ||
    !identical(dim(n_at_age), c(59L, 17L)) ||
    !identical(dim(selectivity), c(16L, 11L)) ||
    !identical(chevron_counts$years, chevron_props$years) ||
    !identical(rownames(chevron_counts$values), as.character(c(1:14, 16))) ||
    !identical(rownames(chevron_props$values), as.character(c(1:10, 12:14, 16))) ||
    any(!is.finite(chevron_fish)) || any(!is.finite(chevron_deployments))) {
  stop("SEDAR 71 table dimensions do not match the source tables.", call. = FALSE)
}

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = NA_character_, survey = NA_character_, sex = NA_character_,
                      year = NA_integer_, age = NA_integer_, sample_size = NA_real_,
                      partition = NA_character_, observation_id = NA_character_,
                      transformation = NA_character_) {
  n <- max(length(value), length(fleet), length(survey), length(sex), length(year),
    length(age), length(sample_size), length(partition), length(observation_id),
    length(transformation))
  year_basis <- if (length(year) == 1L && is.na(year)) NA_character_ else "calendar_year"
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, year = year,
    year_basis = year_basis, age = age, value = value, unit = unit,
    sample_size = sample_size, source_type = "official_table",
    source_reference = source_reference, transformation = transformation,
    notes = notes, partition = partition, observation_id = observation_id)
}

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
                       year = NA_integer_, age = NA_integer_, age_group = NA_character_,
                       fleet = NA_character_, survey = NA_character_, scenario = NA_character_,
                       source_type = "official_table") {
  keep <- is.finite(value)
  if (!any(keep)) return(invisible(NULL))
  n <- sum(keep)
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, fleet = fleet,
    survey = survey, year = year[keep], age = age[keep], age_group = age_group[keep],
    scenario = scenario[keep], value = value[keep], se = NA_real_, unit = unit,
    source_type = source_type, source_reference = source_reference, notes = notes)
}

for (j in seq_along(ages)) {
  age <- ages[j]
  add_input("biology", "growth_length_at_age", "native_covariate", biology[j, 1L],
    "mm total length", "SEDAR 71 SAR, Table 1",
    "Fixed mid-year population length; age 16 is the 16+ group.", age = age)
  add_input("weight", "weight_at_age", "kg_per_fish", biology[j, 4L],
    "kg/fish whole weight", "SEDAR 71 SAR, Table 1",
    "Fixed mid-year whole weight; the source also displays pounds per fish.", age = age)
  add_input("maturity", "maturity_at_age", "proportion", biology[j, 6L],
    "proportion", "SEDAR 71 SAR, Table 1",
    "Fixed female maturity-at-age.", sex = "female", age = age)
  add_input("biology", "proportion_female_at_age", "proportion", biology[j, 7L],
    "proportion", "SEDAR 71 SAR, Table 1",
    "Fixed proportion female-at-age; age 16 is the 16+ group.", age = age)
  add_input("maturity", "maturity_at_age", "proportion", 1,
    "proportion", "SEDAR 71 SAR, Section 3.3",
    "The assessment assumes all males are mature.", sex = "male", age = age,
    transformation = "Encoded the source statement as a value of 1.")
  add_input("M", "natural_mortality_at_age", "per_year", biology[j, 8L],
    "per_year", "SEDAR 71 SAR, Table 1",
    "Fixed over time; age 16 is the 16+ group.", age = age)
  add_output("biology", "growth_length_cv_at_age", biology[j, 3L], "ratio",
    "SEDAR 71 SAR, Table 1",
    "CV of length-at-age estimated by the assessment model, not an input.",
    year = 2019L, age = age, age_group = if (age == 16L) "16+" else NA_character_)
}

catch_specs <- list(
  list(1L, "Commercial handlines", "landings_biomass", "biomass", "1,000 lb gutted weight", "landings"),
  list(2L, "Commercial diving", "landings_biomass", "biomass", "1,000 lb gutted weight", "landings"),
  list(3L, "Recreational headboat", "landings_numbers", "numbers", "1,000 fish", "landings"),
  list(4L, "General recreational", "landings_numbers", "numbers", "1,000 fish", "landings"),
  list(5L, "Commercial handlines", "discard_numbers", "numbers", "1,000 fish", "dead_discards"),
  list(6L, "Recreational headboat", "discard_numbers", "numbers", "1,000 fish", "dead_discards"),
  list(7L, "General recreational", "discard_numbers", "numbers", "1,000 fish", "dead_discards")
)
for (spec in catch_specs) {
  values <- catch[, spec[[1L]]]
  keep <- is.finite(values)
  add_input("catch", spec[[3L]], spec[[4L]], values[keep], spec[[5L]],
    "SEDAR 71 SAR, Table 2",
    "Observed aggregate annual catch; this is not catch-at-age.",
    fleet = spec[[2L]], year = age_years[keep], partition = spec[[6L]])
}

for (spec in list(
  list(1L, 2L, "Recreational headboat index"),
  list(3L, 4L, "SERFS video index")
)) {
  values <- indices[, spec[[1L]]]
  keep <- is.finite(values)
  years <- 1980:2019
  add_input("index", "relative_abundance_index", "index_scale", values[keep],
    "relative index units", "SEDAR 71 SAR, Table 3",
    "Aggregate abundance index; not age-specific.", survey = spec[[3L]], year = years[keep])
  cvs <- indices[, spec[[2L]]]
  keep_cv <- is.finite(cvs)
  add_input("index", "abundance_index_cv", "relative_scale", cvs[keep_cv], "ratio",
    "SEDAR 71 SAR, Table 3", "Source-reported index CV.",
    survey = spec[[3L]], year = years[keep_cv])
}

sample_specs <- list(
  list(1L, "Recreational headboat", "length composition"),
  list(2L, "Headboat discards", "length composition"),
  list(3L, "Commercial handlines", "age composition"),
  list(4L, "Commercial diving", "age composition"),
  list(5L, "Recreational headboat", "age composition")
)
for (table in list(list(sample_fish, "fish", 4L), list(sample_trips, "trips", 5L))) {
  for (spec in sample_specs) {
    values <- table[[1L]][, spec[[1L]]]
    keep <- is.finite(values)
    add_input("biology", "composition_sample_count", "numbers", values[keep],
      table[[2L]], paste0("SEDAR 71 SAR, Table ", table[[3L]]),
      paste("Source sample size for", spec[[3L]], "from", spec[[2L]], "."),
      fleet = spec[[2L]], year = (1980:2019)[keep],
      observation_id = paste0("SEDAR71_Table", table[[3L]], "_", gsub(" ", "_", spec[[3L]])))
  }
}

for (composition in list(
  list(chevron_counts, "frequency_at_age", "native_frequency", "fish",
    "SEDAR 71 WP04, Table 4", "Source-published count of fish sampled at age in the chevron survey; blank cells remain unreported. Table 5 percentages are stored separately and are not used to fill or replace counts."),
  list(chevron_props, "proportion_at_age", "proportion_numbers", "proportion",
    "SEDAR 71 WP04, Table 5", "Source-published chevron survey age percentages divided by 100; annual totals may be below 1 because some sampled fish were not aged. Table 4 counts are stored separately; the two tables disagree in some shared cells.")
)) {
  matrix <- composition[[1L]]$values
  value <- as.vector(t(matrix))
  years <- rep(composition[[1L]]$years, times = nrow(matrix))
  composition_ages <- rep(as.integer(rownames(matrix)),
    each = length(composition[[1L]]$years))
  sample_size <- rep(chevron_fish, times = nrow(matrix))
  keep <- is.finite(value)
  add_input("index", composition[[2L]], composition[[3L]], value[keep],
    composition[[4L]], composition[[5L]], composition[[6L]],
    survey = "MARMAP/SERFS chevron trap", year = years[keep],
    age = composition_ages[keep], sample_size = sample_size[keep],
    observation_id = paste0("SEDAR71_WP04_Table", if (composition[[2L]] == "frequency_at_age") 4L else 5L))
}

deployments <- chevron_deployments
add_input("index", "effort", "native_covariate", deployments, "deployments",
  "SEDAR 71 WP04, Table 4",
  "Annual number of MARMAP/SERFS chevron-trap deployments; this describes the age-composition sample, not the fitted video index.",
  survey = "MARMAP/SERFS chevron trap", year = chevron_counts$years)

projection_scenario <- ifelse(projection_years == 2020L,
  "2020 assessment projection", NA_character_)
for (j in seq_along(ages)) {
  age <- ages[j]
  group <- if (age == 16L) "16+" else NA_character_
  add_output("population", "numbers_at_age", n_at_age[, j], "1,000 fish",
    "SEDAR 71 SAR, Table 6",
    "Estimated start-of-year abundance; age 16 is the 16+ group. 2020 is the first projection year.",
    year = projection_years, age = rep(age, length(projection_years)),
    age_group = rep(group, length(projection_years)), scenario = projection_scenario)
  add_output("biomass", "biomass_at_age", biomass_at_age[, j],
    "1,000 lb whole weight", "SEDAR 71 SAR, Table 7",
    "Estimated start-of-year biomass; age 16 is the 16+ group. 2020 is the first projection year.",
    year = projection_years, age = rep(age, length(projection_years)),
    age_group = rep(group, length(projection_years)), scenario = projection_scenario)
}
add_output("population", "total_numbers", n_at_age[, 17L], "1,000 fish",
  "SEDAR 71 SAR, Table 6", "Reported table total, not recomputed from rounded age rows.",
  year = projection_years, scenario = projection_scenario)
add_output("biomass", "total_biomass_from_age_table", biomass_at_age[, 17L], "1,000 lb whole weight",
  "SEDAR 71 SAR, Table 7", "Reported total column, not recomputed from rounded age rows.",
  year = projection_years, scenario = projection_scenario)
add_output("recruitment", "recruitment", n_at_age[, 1L], "1,000 age-1 fish",
  "SEDAR 71 SAR, Table 6",
  "Derived from the reported start-of-year abundance at age 1; the table does not print a separate numeric recruitment series.",
  year = projection_years, scenario = projection_scenario,
  source_type = "derived_source_output")

status_specs <- list(
  list(1L, "mortality", "apical_F", "per_year"),
  list(2L, "mortality", "F_ratio_to_Fmsy", "ratio"),
  list(3L, "biomass", "total_biomass", "metric tons"),
  list(4L, "biomass", "total_biomass_ratio_to_unfished", "ratio"),
  list(5L, "biomass", "SSB", "metric tons"),
  list(6L, "biomass", "SSB_ratio_to_SSBMSY", "ratio"),
  list(7L, "biomass", "SSB_ratio_to_MSST", "ratio"),
  list(8L, "biology", "proportion_mature_fish_female", "proportion")
)
for (spec in status_specs) {
  add_output(spec[[2L]], spec[[3L]], status[, spec[[1L]]], spec[[4L]],
    "SEDAR 71 SAR, Table 8",
    "Annual base-run status indicator; 2020 values, where reported, are projection outputs.",
    year = projection_years, scenario = projection_scenario)
}

selectivity_specs <- c("Commercial handlines", "Commercial diving",
  "Recreational headboat landings", "Commercial handline discards",
  "Headboat discards", "SERFS video index", "Fleet-average landings",
  "Fleet-average discards", "Combined average landings and discards")
selectivity_columns <- 3L:11L
for (j in seq_along(selectivity_specs)) {
  add_output("biology", "fleet_selectivity_at_age", selectivity[, selectivity_columns[j]],
    "proportion", "SEDAR 71 SAR, Table 9",
    "Terminal-year selectivity; time-varying selectivities are shown for 2019.",
    year = rep(2019L, length(ages)), age = ages,
    age_group = ifelse(ages == 16L, "16+", NA_character_),
    fleet = selectivity_specs[j])
}

f_specs <- list(
  list(1L, "Commercial handlines"), list(2L, "Commercial diving"),
  list(3L, "Recreational headboat landings"), list(4L, "General recreational landings"),
  list(5L, "Commercial handline discards"), list(6L, "Headboat discards"),
  list(7L, "General recreational discards")
)
for (spec in f_specs) {
  add_output("mortality", "fully_selected_fishing_mortality", f_full[, spec[[1L]], drop = TRUE],
    "per_year", "SEDAR 71 SAR, Table 10",
    "Estimated fully selected fleet F; apical F is reported separately in Table 8.",
    year = age_years, fleet = spec[[2L]])
}

catch_output_specs <- list(
  list(landings_n, 1:4, c("Commercial handlines", "Commercial diving", "Recreational headboat", "General recreational"), "landings_numbers", "1,000 fish", "SEDAR 71 SAR, Table 11"),
  list(landings_w, 1:4, c("Commercial handlines", "Commercial diving", "Recreational headboat", "General recreational"), "landings_biomass", "1,000 lb gutted weight", "SEDAR 71 SAR, Table 12"),
  list(discards_n, 1:3, c("Commercial handlines", "Recreational headboat", "General recreational"), "discard_numbers", "1,000 fish", "SEDAR 71 SAR, Table 13"),
  list(discards_w, 1:3, c("Commercial handlines", "Recreational headboat", "General recreational"), "discard_biomass", "1,000 lb gutted weight", "SEDAR 71 SAR, Table 14")
)
for (spec in catch_output_specs) {
  table <- spec[[1L]]
  years <- if (nrow(table) == length(age_years)) age_years else 1981:2019
  for (j in seq_along(spec[[2L]])) {
    add_output("catch", spec[[4L]], table[, spec[[2L]][j]], spec[[5L]], spec[[6L]],
      "Estimated fleet landings or dead-discard output.", year = years,
      fleet = spec[[3L]][j])
  }
  add_output("catch", spec[[4L]], table[, ncol(table)], spec[[5L]], spec[[6L]],
    "Reported total across fleets; not recomputed from rounded fleet rows.", year = years)
}

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
source_checks <- c(
  input_rows = nrow(inputs) > 0L,
  output_rows = nrow(outputs) > 0L,
  finite_inputs = all(is.finite(inputs$value)),
  finite_outputs = all(is.finite(outputs$value)),
  proportions_in_range = all(abs(chevron_props$values) <= 1, na.rm = TRUE),
  abundance_total = isTRUE(all.equal(
    unname(sum(n_at_age["1962", 1:16])), unname(n_at_age["1962", 17L]),
    tolerance = 0.01))
)
if (any(!source_checks)) {
  stop("SEDAR 71 values failed checks: ",
    paste(names(source_checks)[!source_checks], collapse = ", "), call. = FALSE)
}

assumption_rows <- list()
assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes)
}
assumption("assessment", "run_identity", "SEDAR 71 South Atlantic Gag operational assessment; April 2021; terminal year 2019.",
  "SEDAR 71 SAR, cover and Section 3.3", "2020-2029 are deterministic projection years; only 2020 is included in the imported population tables.")
assumption("model", "model_family", "Beaufort Assessment Model (BAM), integrated statistical catch-age model.",
  "SEDAR 71 SAR, Section 3.3", "Annual population model with a closed population assumption.")
assumption("model", "model_dimensions", "Model years 1962-2019; ages 1-16+.",
  "SEDAR 71 SAR, Section 3.3", "Age 16 is the plus group; selected tables include 2020 projection values.")
assumption("initialization", "initial_abundance", "Initial (1962) abundance-at-age is an equilibrium age structure based on natural mortality and estimated initial fishing mortality; no initial age deviations are estimated.",
  "SEDAR 71 SAR, Section 3.3", "The reported estimated initial F is 0.032 per year.")
assumption("catch", "catch_units", "Commercial landings are in 1,000 lb gutted weight; recreational landings and dead discards are in 1,000 fish.",
  "SEDAR 71 SAR, Table 2", "The assessment converts whole weight to gutted weight using GW = WW / 1.059.")
assumption("composition", "fitted_compositions", "The assessment fits age and length compositions from commercial handline, commercial diving, headboat, and headboat discard sources.",
  "SEDAR 71 SAR, Tables 4-5 and Sections 3.3-3.4", "Fishery composition proportions are shown in figures, not numeric tables; only sample counts were imported.")
assumption("composition", "chevron_age_compositions", "SEDAR 71 WP04 reports chevron-trap age counts and percentages for 1990-2002 and 2004-2019.",
  "SEDAR 71 WP04, Tables 4-5", paste0("These are supporting survey age samples, not a separate age-specific abundance index. Percentages were divided by 100 to store proportions; annual totals may be below 1 because some fish were not aged. The count and percentage tables disagree in ", chevron_mismatch_count, " shared age-year cells, so each is preserved as published without deriving one from the other; blank count cells remain unreported."))
assumption("index", "abundance_indices", "The model fits aggregate recreational headboat and SERFS video abundance indices.",
  "SEDAR 71 SAR, Table 3", "Source index values and CVs were imported; the chevron-trap age composition is not itself an abundance index.")
assumption("M", "natural_mortality", "M is fixed over time and declines with age according to a Lorenzen curve; the age vector is scaled over fully selected ages 5+ to survival equivalent to constant M = 0.15 through age 30.",
  "SEDAR 71 SAR, Section 3.3 and Table 1", "The fixed age-specific source values were imported as inputs.")
assumption("biology", "sex_and_maturity", "Female maturity and proportion female vary with age; all males are assumed mature. Sex ratio is constant across years.",
  "SEDAR 71 SAR, Section 3.3 and Table 1", "Reported age-specific values are imported; the sex-transition parameter is estimated by the model.")
assumption("growth", "growth_and_weight", "Population growth follows a von Bertalanffy curve; whole weight at age is fixed. The model uses a separate fishery growth curve to convert ages to lengths.",
  "SEDAR 71 SAR, Section 3.3 and Table 1", "The table's length CV is estimated and stored as an output, not as a fixed input.")
assumption("timing", "index_timing", "A single fractional within-year timing was not recovered for the aggregate indices.",
  "SEDAR 71 SAR, Sections 3.3-3.4 and Table 3", "The reported annual headboat and SERFS index series are preserved without an invented sampling fraction.")
assumption("uncertainty", "population_output_uncertainty", "Annual abundance-at-age, biomass-at-age, SSB and fishing-mortality tables provide point estimates without annual standard errors.",
  "SEDAR 71 SAR, Tables 6-14", "The report's ensemble analyses do not provide annual uncertainty in these tables; no values are inferred.")

assumptions <- do.call(rbind, assumption_rows)
stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10349",
  scientific_name = "Mycteroperca microlepis", common_name = "Gag - South Atlantic",
  area = "South Atlantic Coast", region = "United States South Atlantic Coast",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10349; distinct from Gulf Gag Grouper unit 10348.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2021L, terminal_year = 2019L,
  estimate_terminal_year = 2020L, assessment_type = "operational_assessment",
  model_family = "Beaufort Assessment Model",
  model_version = "SEDAR 71 base run, April 2021",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = "https://sedarweb.org/documents/sedar-71-stock-assessment-report-south-atlantic-gag/",
  framework_url = "https://sedarweb.org/assessments/sedar-71/",
  data_url = "https://sedarweb.org/assessments/sedar-71/",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest completed detailed assessment located for NOAA unit 10349; data through 2019. Tables 6-8 include selected first-year projection values for 2020. Fishery age-composition proportions and annual population uncertainty remain unavailable as numeric tables. WP04 chevron count and percentage tables disagree in 8 shared age-year cells and are retained separately as published.")

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
    any(stocks$authority == "NOAA Fisheries" & stocks$authority_stock_id == "10349") ||
    any(assessments_existing$assessment_id == assessment_id)) {
  stop("NOAA South Atlantic Gag candidate or database identity has changed.", call. = FALSE)
}
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)

if (write_mode) {
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$survey_age_evidence[candidate_row] <- paste(
    candidates$survey_age_evidence[candidate_row],
    "Imported WP04 Table 4 counts and Table 5 proportions as separate source series; 8 shared age-year cells disagree, so no cross-table correction was made. Chevron age samples are not a direct age-specific index.")
  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Imported SEDAR 71 Tables 6-14, including N-at-age, biomass-at-age, status indicators, selectivity, fleet F and estimated catch outputs; 2020 values are labeled projection where reported.")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
  message("Imported NOAA South Atlantic Gag Grouper SEDAR 71: ",
    nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs and ",
    nrow(outputs), " outputs; completeness remains partial.")
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment),
    " assessment, ", nrow(assumptions), " assumptions, ", nrow(inputs),
    " inputs and ", nrow(outputs), " outputs from SEDAR 71.")
}
