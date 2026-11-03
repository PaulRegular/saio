assessment_id <- "dfo_herring_4tvn_fall_2024"
summary_id <- "dfo_herring_4tvn_fall_2026"
stock_id <- "ck_dfo_gsl_harengus_4t_fall"
root <- "."
source_dir <- file.path(root, "source_cache", stock_id)
support_file <- file.path(source_dir, "dfo_2024_supporting_material_2024-058.txt")
methods_file <- file.path(source_dir, "dfo_2022_assessment_2022-068.txt")
if (!file.exists(support_file) || !file.exists(methods_file)) {
  stop("The cached 2024 supporting text or 2022 methods text is missing.")
}
lines <- readLines(support_file, warn = FALSE, encoding = "UTF-8")

assessment_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41256384.pdf"
advice_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-032-eng.pdf"
framework_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-050-eng.pdf"
methods_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091589.pdf"
biomass_url <- paste0(
  "https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
  "7c17f4eb-93fc-11ea-b1dd-f48c505b2a29/attachments/",
  "7C17f4eb_herring_historic_biomass_2025.csv"
)
dictionary_url <- paste0(
  "https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
  "7c17f4eb-93fc-11ea-b1dd-f48c505b2a29/attachments/",
  "7c17f4eb_herring_data_dictionary.csv"
)

table_block <- function(number, next_number) {
  starts <- grep(paste0("^\\s*Table ", number, "\\."), lines)
  if (!length(starts)) stop("Cannot find Table ", number, ".")
  start <- tail(starts, 1L)
  ends <- grep(paste0("^\\s*Table ", next_number, "\\."), lines)
  ends <- ends[ends > start]
  end <- if (length(ends)) ends[[1L]] else length(lines) + 1L
  lines[seq.int(start + 1L, end - 1L)]
}

parse_values <- function(line, expected, table_number) {
  tokens <- strsplit(trimws(gsub(",", "", line, fixed = TRUE)), "[[:space:]]+")[[1L]]
  values <- tokens[-1L]
  if (length(values) != expected) {
    stop("Unexpected number of values in Table ", table_number, " row: ", line)
  }
  values[values %in% c("-", "–", "—")] <- NA_character_
  values <- suppressWarnings(as.numeric(values))
  if (any(!is.na(values) & !is.finite(values))) {
    stop("Non-finite values in Table ", table_number, ".")
  }
  values
}

parse_region_table <- function(number, next_number, value_count,
                               select_values, expected_years = NULL) {
  x <- table_block(number, next_number)
  region <- NA_character_
  rows <- list()
  for (line in x) {
    match_region <- regmatches(
      line,
      regexec("^\\s*[a-c]\\)\\s*(North|Middle|South)", line, ignore.case = TRUE)
    )[[1L]]
    if (length(match_region) > 1L) {
      region <- tools::toTitleCase(tolower(match_region[[2L]]))
      next
    }
    if (!grepl("^\\s*(19|20)[0-9]{2}\\s+", line) || is.na(region)) next
    year <- as.integer(sub("^\\s*((19|20)[0-9]{2}).*$", "\\1", line))
    values <- parse_values(line, value_count, number)
    rows[[length(rows) + 1L]] <- data.frame(
      year = year, region = region,
      age_index = seq_along(select_values),
      value = values[select_values],
      stringsAsFactors = FALSE
    )
  }
  result <- do.call(rbind, rows)
  if (is.null(result) || !nrow(result)) stop("No data rows parsed from Table ", number, ".")
  regions <- c("North", "Middle", "South")
  for (r in regions) {
    found <- sort(unique(result$year[result$region == r]))
    if (!length(found)) stop("Missing region ", r, " in Table ", number, ".")
    if (!is.null(expected_years) && !identical(found, as.integer(expected_years))) {
      stop(
        "Unexpected years in Table ", number, " (", r, "): ",
        paste(found, collapse = ", ")
      )
    }
  }
  result
}

parse_flat_table <- function(number, next_number, value_count,
                             expected_years = NULL, section = NULL) {
  x <- table_block(number, next_number)
  if (!is.null(section)) {
    marker <- grep(paste0("^\\s*", section, "\\s*$"), x, ignore.case = TRUE)
    if (length(marker) != 1L) stop("Cannot locate section ", section, " in Table ", number, ".")
    x <- x[seq.int(marker[[1L]] + 1L, length(x))]
  }
  rows <- list()
  for (line in x) {
    if (!grepl("^\\s*(19|20)[0-9]{2}\\s+", line)) next
    year <- as.integer(sub("^\\s*((19|20)[0-9]{2}).*$", "\\1", line))
    values <- parse_values(line, value_count, number)
    rows[[length(rows) + 1L]] <- data.frame(
      year = year, age_index = seq_along(values), value = values,
      stringsAsFactors = FALSE
    )
  }
  result <- do.call(rbind, rows)
  if (is.null(result) || !nrow(result)) stop("No data rows parsed from Table ", number, ".")
  found <- sort(unique(result$year))
  if (!is.null(expected_years) && !identical(found, as.integer(expected_years))) {
    stop(
      "Unexpected years in Table ", number, ": ",
      paste(found, collapse = ", ")
    )
  }
  result
}

years <- 1978:2023
ages <- 2:11
catch_fixed <- parse_region_table(6, 7, 11, 1:10, years)
catch_mobile <- parse_region_table(10, 11, 11, 1:10, years)
weight_fixed <- parse_region_table(7, 8, 10, 1:10, years)
weight_mobile <- parse_flat_table(11, 12, 10, 1978:2022)
cpue <- parse_region_table(14, 15, 8, 1:8, 1986:2023)
acoustic <- parse_flat_table(15, 16, 9, 1994:2023, "Fall spawners")
rv <- parse_flat_table(17, 18, 11, 1994:2023)

same_mobile_as_fixed <- isTRUE(all.equal(
  catch_mobile[order(catch_mobile$year, catch_mobile$region, catch_mobile$age_index), c("year", "region", "age_index", "value")],
  catch_fixed[order(catch_fixed$year, catch_fixed$region, catch_fixed$age_index), c("year", "region", "age_index", "value")],
  check.attributes = FALSE
))
if (!same_mobile_as_fixed) {
  stop("Expected the apparent Table 10/Table 6 duplication was not reproduced.")
}

source_ref <- "DFO Research Document 2024/058"
input_rows <- function(x, ages, type, measure, basis, unit,
                       fleet = "", survey = "", season = "fall",
                       table_number, note = "",
                       region_column = TRUE,
                       source_type = "official_table") {
  result <- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = "",
    region = if (region_column && "region" %in% names(x)) x$region else "",
    season = season, year = x$year, year_basis = "calendar_year",
    age = ages[x$age_index], value = x$value, unit = unit,
    sampling_time = NA_real_, source_type = source_type,
    source_reference = paste(source_ref, "Table", table_number),
    transformation = "", notes = note,
    stringsAsFactors = FALSE
  )
  result[is.finite(result$value), , drop = FALSE]
}

inputs <- rbind(
  input_rows(
    catch_fixed, ages, "catch", "numbers_at_age", "numbers",
    "thousand fish", fleet = "Fixed gear", table_number = 6,
    note = "Fall-spawner commercial catch-at-age. Age 11 is the 11+ group; values are thousand fish."
  ),
  input_rows(
    catch_mobile, ages, "catch", "numbers_at_age", "numbers",
    "thousand fish", fleet = "Mobile gear", table_number = 10,
    note = paste(
      "Values are transcribed as published. Table 10 duplicates Table 6",
      "exactly for every year, age and region, despite identifying mobile",
      "gear. This is treated as a suspected publication transcription error;",
      ""
    )
  ),
  input_rows(
    weight_fixed, ages, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", fleet = "Fixed gear", table_number = 7,
    note = "Fall-spawner fixed-gear weight-at-age in kg per fish; age 11 is 11+."
  ),
  input_rows(
    weight_mobile, ages, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", fleet = "Mobile gear", table_number = 11,
    region_column = FALSE,
    note = "Fall-spawner mobile-gear weight-at-age in kg per fish; age 11 is 11+. Table 11 ends in 2022, so 2023 mobile weight-at-age is unavailable."
  ),
  input_rows(
    cpue, 4:11, "index", "numbers_at_age", "numbers",
    "number per net-haul", survey = "Fall fixed-gear CPUE",
    table_number = 14,
    note = "Age-specific regional CPUE in numbers per net-haul; age 11 is 11+."
  ),
  input_rows(
    acoustic, 2:10, "index", "numbers_at_age", "numbers",
    "thousand fish", survey = "4Tmno acoustic survey",
    table_number = 15, region_column = FALSE,
    note = paste(
      "Fall-spawner acoustic age index, ages 2-10. Unit clarified as",
      "thousand fish by DFO Research Document 2016/060 Table 16; the 2024",
      "values are retained on their published numeric scale."
    )
  ),
  input_rows(
    rv, 1:11, "index", "numbers_at_age", "numbers",
    "mean number per tow", survey = "DFO multispecies RV survey",
    table_number = 17, region_column = FALSE,
    note = "Fall-spawner stratified mean numbers per tow at age; age 11 is 11+."
  )
)
inputs$source_reference[inputs$survey == "4Tmno acoustic survey"] <- paste(
  source_ref, "Table 15; DFO Research Document 2016/060 Table 16 (unit clarification)"
)
inputs$transformation[inputs$survey == "4Tmno acoustic survey"] <- paste(
  "Resolved the omitted scale as thousand fish from the explicit unit in",
  "DFO Research Document 2016/060 Table 16; kept 2024 Table 15 values unchanged."
)

output_rows_region <- function(table_number, next_number, value_count,
                               ages, type, measure, unit,
                               value_indices = seq_along(ages), note = "") {
  x <- parse_flat_table(table_number, next_number, value_count, years)
  x <- x[x$age_index %in% value_indices, , drop = FALSE]
  region_map <- c("22" = "North", "23" = "North", "24" = "Middle",
                  "25" = "Middle", "26" = "South", "27" = "South")
  region <- unname(region_map[as.character(table_number)])
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = region, season = "",
    year = x$year, age = ages[match(x$age_index, value_indices)],
    age_group = "", value = x$value, se = NA_real_, lwr = NA_real_,
    upr = NA_real_, unit = unit, source_type = "official_table",
    source_reference = paste(source_ref, "Table", table_number),
    notes = note, stringsAsFactors = FALSE
  )
}

output_total_age_table <- function(table_number, next_number, value_count,
                                   measure, type, unit, note) {
  x <- parse_flat_table(table_number, next_number, value_count, years)
  age_rows <- x[x$age_index <= 10, , drop = FALSE]
  rows <- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = age_rows$year, age = ages[age_rows$age_index], age_group = "",
    value = age_rows$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table",
    source_reference = paste(source_ref, "Table", table_number),
    notes = note, stringsAsFactors = FALSE
  )
  group_rows <- x[x$age_index == 11, , drop = FALSE]
  grouped <- data.frame(
    assessment_id = assessment_id, type = type,
    measure = if (measure == "biomass_at_age") "SSB" else "total_numbers",
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = group_rows$year, age = NA_real_, age_group = "4+",
    value = group_rows$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table",
    source_reference = paste(source_ref, "Table", table_number),
    notes = paste(note, "The reported 4+ age-group total is retained as published."),
    stringsAsFactors = FALSE
  )
  rbind(rows, grouped)
}

biomass_tables <- list(
  output_rows_region(22, 23, 11, ages, "biomass", "biomass_at_age", "tonnes",
    value_indices = 1:10, note = "August 1 maximum-likelihood biomass estimate by region; age 11 is 11+."),
  output_rows_region(24, 25, 11, ages, "biomass", "biomass_at_age", "tonnes",
    value_indices = 1:10, note = "August 1 maximum-likelihood biomass estimate by region; age 11 is 11+."),
  output_rows_region(26, 27, 11, ages, "biomass", "biomass_at_age", "tonnes",
    value_indices = 1:10, note = "August 1 maximum-likelihood biomass estimate by region; age 11 is 11+.")
)
abundance_tables <- list(
  output_rows_region(23, 24, 11, ages, "population", "numbers_at_age", "thousand fish",
    value_indices = 1:10, note = "January 1 maximum-likelihood abundance estimate by region; age 11 is 11+."),
  output_rows_region(25, 26, 11, ages, "population", "numbers_at_age", "thousand fish",
    value_indices = 1:10, note = "January 1 maximum-likelihood abundance estimate by region; age 11 is 11+."),
  output_rows_region(27, 28, 11, ages, "population", "numbers_at_age", "thousand fish",
    value_indices = 1:10, note = "January 1 maximum-likelihood abundance estimate by region; age 11 is 11+.")
)

total_biomass <- output_total_age_table(
  28, 29, 11, "biomass_at_age", "biomass", "tonnes",
  "August 1 maximum-likelihood biomass for the combined fall-spawner population; age 11 is 11+."
)
total_abundance <- output_total_age_table(
  29, 30, 11, "numbers_at_age", "population", "thousand fish",
  "January 1 maximum-likelihood abundance for the combined fall-spawner population; age 11 is 11+."
)
ssb_rows <- total_biomass[total_biomass$measure == "SSB", , drop = FALSE]
ssb_rows$notes <- paste(
  "August 1 biomass at ages 4+ from Table 28, matching the assessment's",
  "knife-edge maturity schedule (ages 4+ mature). No uncertainty is tabulated."
)
total_biomass[total_biomass$measure == "SSB", ] <- ssb_rows
recruitment <- total_abundance[which(!is.na(total_abundance$age) & total_abundance$age == 2), , drop = FALSE]
recruitment$measure <- "recruitment"
recruitment$age_group <- ""
recruitment$notes <- "Recruitment represented by January 1 abundance at age 2."

f_tables <- lapply(30:33, function(number) {
  next_number <- number + 1L
  region_map <- c("30" = "North", "31" = "Middle", "32" = "South", "33" = "")
  region <- unname(region_map[as.character(number)])
  x <- parse_flat_table(number, next_number, 11, years)
  age_data <- x[x$age_index <= 10, , drop = FALSE]
  age_rows <- data.frame(
    assessment_id = assessment_id, type = "mortality",
    measure = "fishing_mortality_at_age", fleet = "", survey = "",
    sex = "", region = region, season = "", year = age_data$year,
    age = ages[age_data$age_index], age_group = "", value = age_data$value,
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = "per_year",
    source_type = "official_table",
    source_reference = paste(source_ref, "Table", number),
    notes = "January 1 maximum-likelihood fishing mortality; age 11 is 11+.",
    stringsAsFactors = FALSE
  )
  fbar_data <- x[x$age_index == 11, , drop = FALSE]
  fbar <- data.frame(
    assessment_id = assessment_id, type = "mortality", measure = "Fbar",
    fleet = "", survey = "", sex = "", region = region, season = "",
    year = fbar_data$year, age = NA_real_, age_group = "5-10",
    value = fbar_data$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "per_year", source_type = "official_table",
    source_reference = paste(source_ref, "Table", number),
    notes = "Source-reported January 1 abundance-weighted F for ages 5-10.",
    stringsAsFactors = FALSE
  )
  rbind(age_rows, fbar)
})
annual_sum <- function(x, measure, type, unit, table_number, note) {
  sums <- aggregate(value ~ year, x[!is.na(x$age), ], sum)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = sums$year, age = NA_real_, age_group = "2-11+", value = sums$value,
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "derived_source_output",
    source_reference = paste(source_ref, "Table", table_number), notes = note,
    stringsAsFactors = FALSE
  )
}
derived_total_biomass <- annual_sum(
  total_biomass, "total_biomass", "biomass", "tonnes", 28,
  "Sum of reported August 1 biomass-at-age for ages 2-11+; uncertainty is unavailable."
)
derived_total_abundance <- annual_sum(
  total_abundance, "total_numbers", "population", "thousand fish", 29,
  "Sum of reported January 1 abundance-at-age for ages 2-11+; uncertainty is unavailable."
)
outputs <- do.call(rbind, c(
  biomass_tables, abundance_tables,
  list(total_biomass, total_abundance, recruitment,
       derived_total_biomass, derived_total_abundance), f_tables
))

acoustic_file <- file.path(source_dir, "herring_historic_biomass_2025.csv")
dictionary_file <- file.path(source_dir, "herring_data_dictionary.csv")
if (!file.exists(acoustic_file) || !file.exists(dictionary_file)) {
  stop("The cached acoustic biomass CSV and dictionary are required.")
}
biomass_lines <- readLines(acoustic_file, warn = FALSE, encoding = "latin1")
acoustic_biomass <- read.csv(
  text = paste(biomass_lines[-1L], collapse = "\n"),
  header = FALSE, col.names = c("year", "fall", "spring", "total", "prop_fall", "prop_spring"),
  check.names = FALSE
)
dictionary_lines <- readLines(dictionary_file, warn = FALSE, encoding = "latin1")
if (!identical(as.integer(acoustic_biomass$year), 1994:2025) ||
    !all(is.finite(acoustic_biomass$fall)) ||
    !any(grepl("^Fall_acoustic_biomass.*Fall spawners acoustic biomass in tons", dictionary_lines))) {
  stop("Unexpected acoustic biomass years, values, or units.")
}
summary_inputs <- data.frame(
  assessment_id = summary_id, type = "index", measure = "total_biomass",
  basis = "biomass", fleet = "", survey = "4Tmno acoustic survey",
  sex = "", region = "", season = "fall",
  year = as.integer(acoustic_biomass$year), year_basis = "calendar_year",
  age = NA_real_, value = as.numeric(acoustic_biomass$fall), unit = "tonnes",
  sampling_time = NA_real_, source_type = "official_machine_readable",
  source_reference = paste(biomass_url, dictionary_url),
  transformation = "",
  notes = paste(
    "Fall acoustic biomass from the DFO 2025 public data release, retained",
    "on its reported tonne scale. It is associated with the separate 2026",
    "assessment summary record; exact model input revision is not confirmed."
  ), stringsAsFactors = FALSE
)
summary_output <- data.frame(
  assessment_id = summary_id, type = "biomass", measure = "SSB",
  fleet = "", survey = "", sex = "", region = "", season = "",
  year = 2025, age = NA_real_, age_group = "4+",
  value = 321000, se = NA_real_, lwr = 259000, upr = 433000,
  unit = "tonnes", source_type = "official_document",
  source_reference = "DFO Science Advisory Report 2026/032, assessment to 2025",
  notes = paste(
    "The report gives total spawning biomass of 321 kt (95% interval",
    "259-433 kt). The values are stored in tonnes; no standard error is reported."
  ), stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "",
                       survey = "", region = "", fleet = "", season = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = "", region = region, season = season,
    setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
assumptions <- do.call(rbind, list(
  assumption("model", "model_family", "Statistical catch-at-age model implemented in AD Model Builder",
    paste(source_ref, "pp. 16-18")),
  assumption("population", "years", "1978-2023", paste(source_ref, "Tables 22-33")),
  assumption("population", "ages", "2-11+", paste(source_ref, "Tables 22-33")),
  assumption("population", "spatial_scale", "Three regional populations: North, Middle and South; combined outputs are also reported",
    "DFO Research Document 2022/068, pp. 16-18"),
  assumption("N", "recruitment_age", "Age 2", "DFO Research Document 2022/068, p. 17"),
  assumption("N", "initial_abundance", "Initial abundance at age estimated in 1978 separately by region",
    "DFO Research Document 2022/068, p. 17"),
  assumption("N", "recruitment_process", "Annual age-2 recruitment estimated through 2021 in the documented model",
    "DFO Research Document 2022/068, p. 17",
    "The 2024 supporting document does not restate detailed parameter integration for the 2022-2023 update."),
  assumption("F", "selectivity", "Gear-specific selectivity; commercial selectivity varies among three periods and includes age-size and mesh effects",
    "DFO Research Document 2022/068, pp. 17-18"),
  assumption("M", "age_groups", "Ages 2-6 and 7-11+",
    "DFO Research Document 2022/068, p. 17"),
  assumption("M", "process", "Log-M random walks with increment SD fixed at 0.075; initial-M prior mean 0.2",
    "DFO Research Document 2022/068, p. 17",
    "Detailed settings are methodological context; not independently reconfirmed for the 2022-2023 assessment update."),
  assumption("index", "fall_fixed_CPUE", "Regional age-specific index and aggregate biomass index, 1986-2023",
    paste(source_ref, "Table 14; DFO Research Document 2022/068, p. 16"),
    survey = "Fall fixed-gear CPUE", season = "fall"),
  assumption("index", "acoustic_index", "Fall-spawner age-at-age index, ages 2-10, 1994-2023; source model also used an aggregate biomass index",
    paste(source_ref, "Table 15; DFO Research Document 2022/068, p. 16"),
    "The source likelihood weighting for aggregate acoustic biomass is not reproduced in Table 15.",
    survey = "4Tmno acoustic survey", season = "fall"),
  assumption("index", "rv_index", "Multispecies RV survey age-specific index and aggregate biomass index, 1994-2023",
    paste(source_ref, "Table 17; DFO Research Document 2022/068, p. 16"),
    survey = "DFO multispecies RV survey", season = "fall"),
  assumption("catch", "catch_likelihood", "Total catch and age-composition likelihoods",
    "DFO Research Document 2022/068, pp. 17-18",
    "The published 2024 mobile-gear Table 10 duplicates fixed-gear Table 6; independent 2022-2023 mobile catch-at-age remains unresolved."),
  assumption("biology", "maturity", "Knife-edge maturity between ages 3 and 4",
    "DFO Research Document 2022/068, p. 10"),
  assumption("biology", "weights", "Beginning-year weights combine fixed and mobile gear weights; age a uses the geometric mean of age a-1 in year t-1 and age a in year t",
    "DFO Research Document 2022/068, p. 6",
    "The source report does not publish the complete fitted stock-weight surface or exact regional pooling rule.")
))
summary_assumptions <- data.frame(
  assessment_id = summary_id,
  component = c("model", "population", "M", "index", "assessment"),
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c("model_family", "regional_structure", "natural_mortality", "data_span", "assessment_status"),
  value = c(
    "WHAM state-space model",
    "Three regional models (North, Middle, South); estimates combined after fitting",
    "M fixed at 0.30 for younger ages; older-age M varies over time",
    "Inputs reported through 2025, including fishery-independent acoustic data",
    "2025 production assessment summarized in DFO Science Advisory Report 2026/032; full detailed model outputs not recovered"
  ),
  source_reference = advice_url, notes = "",
  stringsAsFactors = FALSE
)
summary_assumptions$notes[summary_assumptions$setting == "data_span"] <- paste(
  "Public acoustic biomass values are retained from the 2025 data release;",
  "the exact input revision used in the model has not been verified."
)
summary_assumptions$notes[summary_assumptions$setting == "assessment_status"] <- paste(
  "DFO Research Documents 2026/050 and 2026/061 provide framework/index",
  "context but are not treated as the final 2025 model output."
)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "DFO-GSL_harengus_4T-Fall",
  authority = "DFO",
  authority_stock_id = "NAFO Division 4TVn fall-spawning component",
  scientific_name = "Clupea harengus",
  common_name = "Southern Gulf of St. Lawrence fall-spawning Atlantic herring",
  area = "NAFO Division 4TVn", region = "Gulf Region",
  ocean = "Northwest Atlantic",
  notes = paste(
    "Fall-spawning component is biologically and assessment-wise distinct",
    "from the 4T spring-spawning component. Matched to Charbonneau-Keith",
    "Master unique_ID DFO-GSL_harengus_4T-Fall."
  ), stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024, terminal_year = 2023, estimate_terminal_year = 2023,
  assessment_type = "full_assessment", model_family = "SCA",
  model_version = "AD Model Builder SCA updated for the 2022-2023 assessment",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022,
  assessment_url = assessment_url, framework_url = methods_url,
  data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Most recent detailed numerical source currently recovered. Table 10",
    "mobile-gear catch-at-age exactly duplicates fixed-gear Table 6 and is",
    "suspected to be a publication error. Gear-specific sampling, some",
    "likelihood inputs, fitted M and uncertainty are not fully tabulated."
  ), stringsAsFactors = FALSE
)
summary_assessment <- data.frame(
  assessment_id = summary_id, stock_id = stock_id,
  assessment_year = 2026, terminal_year = 2025, estimate_terminal_year = 2025,
  assessment_type = "full_assessment", model_family = "WHAM",
  model_version = "2025 regional WHAM state-space assessment",
  is_current = FALSE, is_applied = TRUE, framework_year = 2026,
  assessment_url = advice_url, framework_url = framework_url,
  data_url = biomass_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The 2026/032 report summarizes the official assessment through 2025.",
    "Only total 2025 SSB with its reported 95% interval and the available",
    "public fall acoustic biomass series are recorded. Detailed annual",
    "inputs, population surfaces and model objects were not recovered."
  ), stringsAsFactors = FALSE
)

complete_inputs <- function(x) {
  x$observation_id <- ""
  x$length_bin <- NA_real_
  x$length_bin_lower <- NA_real_
  x$length_bin_upper <- NA_real_
  x$sample_size <- NA_real_
  x$age_error <- NA_real_
  x$partition <- NA_real_
  x
}
inputs <- complete_inputs(inputs)
summary_inputs <- complete_inputs(summary_inputs)
inputs_all <- rbind(inputs, summary_inputs)
assumptions_all <- rbind(assumptions, summary_assumptions)
outputs$age_group[is.na(outputs$age_group)] <- ""
summary_output$age_group[is.na(summary_output$age_group)] <- ""
outputs_all <- rbind(outputs, summary_output)

write_updated <- function(name, new_rows, key) {
  path <- file.path(root, "database", name)
  columns <- names(read.csv(path, nrows = 0, check.names = FALSE))
  new_rows <- new_rows[columns]
  ids <- unique(as.character(new_rows[[key]]))
  for (id in ids) {
    current <- new_rows[as.character(new_rows[[key]]) == id, , drop = FALSE]
    existing_lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    starts <- c(paste0(id, ","), paste0('"', id, '",'))
    existing <- existing_lines[vapply(existing_lines, function(z) any(startsWith(z, starts)), logical(1))]
    csv_field <- function(x) {
      if (is.na(x)) return("")
      x <- enc2utf8(as.character(x))
      if (grepl('[",\\r\\n]', x) || grepl("^\\s|\\s$", x)) {
        paste0('"', gsub('"', '""', x, fixed = TRUE), '"')
      } else x
    }
    new_lines <- vapply(seq_len(nrow(current)), function(i) {
      paste(vapply(current, function(column) csv_field(column[i]), character(1)), collapse = ",")
    }, character(1))
    if (identical(existing, new_lines)) next
    original <- readBin(path, "raw", n = file.info(path)[["size"]])
    crlf <- length(original) > 1L && any(
      original[-1L] == as.raw(10) & original[-length(original)] == as.raw(13)
    )
    eol <- if (crlf) "\r\n" else "\n"
    matched <- vapply(existing_lines, function(z) any(startsWith(z, starts)), logical(1))
    first <- which(matched)
    if (length(first)) {
      rows <- append(existing_lines[!matched], new_lines, after = min(first) - 1L)
    } else rows <- c(existing_lines, new_lines)
    suffix <- if (length(original) && tail(original, 1L) == as.raw(10)) eol else ""
    con <- file(path, open = "wb")
    writeBin(charToRaw(enc2utf8(paste0(paste(rows, collapse = eol), suffix))), con)
    close(con)
  }
}

write_database <- if (exists("write_database", inherits = FALSE)) isTRUE(write_database) else FALSE
if (write_database) {
  write_updated("stocks.csv", stock, "stock_id")
  write_updated("assessments.csv", rbind(assessment, summary_assessment), "assessment_id")
  write_updated("assumptions.csv", assumptions_all, "assessment_id")
  write_updated("inputs.csv", inputs_all, "assessment_id")
  write_updated("outputs.csv", outputs_all, "assessment_id")
}

cat(
  "Prepared", nrow(inputs_all), "source inputs and", nrow(outputs_all),
  "official or derived outputs across the detailed 2024 and summary 2026 records.\n"
)



