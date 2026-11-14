root <- "."
assessment_id <- "mpi_tarakihi_eastern_2026"
stock_id <- "mpi_tarakihi_eastern"
candidate_id <- "MPI:TAR:EASTERN"
retrieved_on <- "2026-11-05"
source_file <- file.path(root, "source_cache/mpi_tarakihi_eastern_2026/FAR-2026-44-eastern-tarakihi-2026.pdf")
source_url <- "https://fs.fish.govt.nz/Doc/26277/FAR-2026-44-Stock-assessment-of-eastern-tarakihi-for-2026.pdf.ashx"
expected_hash <- "20F9D9B6430AD975C095F4F652B4C4AD9AF84D991651D0BE13C4C5F5827051CF"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(source_file)) stop("Cache the reviewed FAR 2026/44 PDF before importing.", call. = FALSE)
actual_hash <- toupper(unname(tools::sha256sum(source_file)))
if (!identical(actual_hash, expected_hash)) stop("The cached report differs from the reviewed source.", call. = FALSE)

text_file <- file.path(root, "source_cache/mpi_tarakihi_eastern_2026/FAR-2026-44-text.txt")
if (file.exists(text_file)) {
  lines <- readLines(text_file, warn = FALSE, encoding = "UTF-8")
} else if (requireNamespace("pdftools", quietly = TRUE)) {
  lines <- unlist(strsplit(pdftools::pdf_text(source_file), "\n", fixed = TRUE), use.names = FALSE)
} else {
  stop("Extract the cached report text to FAR-2026-44-text.txt or install pdftools.", call. = FALSE)
}

section_lines <- function(start, end = NULL) {
  first <- which(startsWith(trimws(lines), start))[1L]
  if (is.na(first)) stop("Source table not found: ", start, call. = FALSE)
  last <- length(lines) + 1L
  if (!is.null(end)) {
    later <- which(seq_along(lines) > first & startsWith(trimws(lines), end))
    if (!length(later)) stop("End of source table not found: ", end, call. = FALSE)
    last <- later[1L]
  }
  lines[seq.int(first, last - 1L)]
}

normalize_number_spacing <- function(text) {
  gsub("(?<=\\d)\\s(?=\\d{3}(?:\\s|$))", "", text, perl = TRUE)
}

number_tokens <- function(text) {
  tokens <- strsplit(trimws(normalize_number_spacing(text)), "[[:space:]]+")[[1L]]
  values <- suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
  values[is.finite(values)]
}

parse_catches <- function() {
  table <- section_lines("Table A30:", "Table A31:")
  rows <- list()
  for (line in table) {
    year_match <- regmatches(line, regexec("^[[:space:]]*((?:19|20)[0-9]{2})[[:space:]]+", line, perl = TRUE))[[1L]]
    if (!length(year_match)) next
    year <- as.integer(year_match[2L])
    if (!year %in% 1932:2025) next
    values <- number_tokens(sub("^[[:space:]]*(?:19|20)[0-9]{2}[[:space:]]+", "", line, perl = TRUE))
    if (length(values) != 8L) stop("Expected eight fishery catches for model year ", year, ": ", line, call. = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(year = year, t(values), stringsAsFactors = FALSE)
  }
  out <- do.call(rbind, rows)
  names(out) <- c("year", "ECSI", "Kaikoura", "Cook", "TAR2_trawl", "TAR2_rec", "BPLE_trawl", "BPLE_rec", "ENLD")
  out <- out[order(out$year), , drop = FALSE]
  if (!identical(out$year, 1932:2025) || nrow(out) != 94L || any(!is.finite(as.matrix(out[, -1L]))) || any(as.matrix(out[, -1L]) < 0)) {
    stop("Catch-table coverage or values do not match model years 1932-2025.", call. = FALSE)
  }
  out
}

parse_age_table <- function(start, end = NULL) {
  table <- section_lines(start, end)
  age_rows <- grep("^[[:space:]]*(30\\+|[1-9]|[12][0-9])[[:space:]]+", table, perl = TRUE)
  if (!length(age_rows)) stop("No age rows found in ", start, ".", call. = FALSE)
  header <- table[seq_len(age_rows[1L] - 1L)]
  year_tokens <- lapply(header, function(line) {
    matches <- gregexpr("(?:19|20)[0-9]{2}", line, perl = TRUE)
    suppressWarnings(as.integer(regmatches(line, matches)[[1L]]))
  })
  years <- unique(unlist(year_tokens[lengths(year_tokens) >= 2L], use.names = FALSE))
  if (!length(years)) stop("No model-year headings found in ", start, ".", call. = FALSE)
  rows <- list()
  for (line in table[age_rows]) {
    match <- regmatches(line, regexec("^[[:space:]]*(30\\+|[1-9]|[12][0-9])[[:space:]]+(.+?)[[:space:]]*$", line, perl = TRUE))[[1L]]
    age <- if (match[2L] == "30+") 30L else as.integer(match[2L])
    values <- number_tokens(match[3L])
    if (length(values) != length(years) || any(!is.finite(values)) || any(values < 0)) {
      stop("Age row does not match the table headings in ", start, ": ", line, call. = FALSE)
    }
    rows[[length(rows) + 1L]] <- data.frame(age = age, year = years, value = values)
  }
  out <- do.call(rbind, rows)
  if (!identical(sort(unique(out$age)), 1:30) || anyDuplicated(out[c("age", "year")])) {
    stop("Age-table coverage or row keys are invalid in ", start, ".", call. = FALSE)
  }
  out
}

parse_biomass_indices <- function() {
  table <- section_lines("Table 8:", "Table 9:")
  rows <- list()
  current_series <- ""
  for (line in table) {
    z <- strsplit(trimws(normalize_number_spacing(line)), "[[:space:]]+")[[1L]]
    if (!length(z)) next
    if (z[1L] %in% c("Winter", "Summer")) {
      current_series <- z[1L]
      z <- z[-1L]
    }
    if (!grepl("^KAH[0-9]{4}$", z[1L])) next
    if (length(z) < 5L || !grepl("^(19|20)[0-9]{2}$", z[2L]) || !grepl("^(19|20)[0-9]{2}$", z[3L])) {
      stop("Unexpected survey-biomass row: ", line, call. = FALSE)
    }
    rows[[length(rows) + 1L]] <- data.frame(
      series = current_series, code = z[1L], survey_year = as.integer(z[2L]),
      year = as.integer(z[3L]), value = as.numeric(z[4L]), cv_percent = as.numeric(z[5L]),
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, rows)
  if (nrow(out) != 20L || sum(out$series == "Winter") != 15L || sum(out$series == "Summer") != 5L) {
    stop("Survey-biomass table does not match 15 winter and five summer observations.", call. = FALSE)
  }
  out
}

parse_age2_indices <- function() {
  table <- section_lines("Table 9:", "Figure 36:")
  rows <- list()
  for (line in table) {
    z <- strsplit(trimws(normalize_number_spacing(line)), "[[:space:]]+")[[1L]]
    if (!length(z) || !grepl("^KAH[0-9]{4}$", z[1L])) next
    if (length(z) < 6L) stop("Unexpected age-2 index row: ", line, call. = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(
      code = z[1L], survey_year = as.integer(z[2L]), year = as.integer(z[3L]),
      cohort_year = as.integer(z[4L]), value = as.numeric(z[5L]), cv_percent = as.numeric(z[6L]),
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, rows)
  if (nrow(out) != 10L || !identical(out$year, c(2007L, 2008L, 2009L, 2012L, 2014L, 2016L, 2018L, 2021L, 2022L, 2024L))) {
    stop("Age-2 index years do not match Table 9.", call. = FALSE)
  }
  out
}

parse_cpue <- function(start, end, expected_years) {
  table <- section_lines(start, end)
  rows <- list()
  for (line in table) {
    match <- regmatches(line, regexec("^[[:space:]]*((?:19|20)[0-9]{2})<U\\+2013>[0-9]{2,4}[[:space:]]+(.+)$", line, perl = TRUE))[[1L]]
    if (!length(match)) next
    if (!grepl("^[[:space:]]*[0-9]+(?:\\.[0-9]+)?[[:space:]]+", match[3L], perl = TRUE)) next
    values <- number_tokens(match[3L])
    if (length(values) < 3L) stop("Expected combined CPUE estimate and 95% limits: ", line, call. = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(year = as.integer(match[2L]) + 1L,
      index = values[1L], lwr = values[2L], upr = values[3L])
  }
  out <- do.call(rbind, rows)
  if (!identical(out$year, expected_years) || any(out$index <= 0 | out$lwr <= 0 | out$upr <= 0 | out$lwr > out$upr)) {
    stop("CPUE table coverage or interval values do not match the report: ", start, call. = FALSE)
  }
  out
}

catch <- parse_catches()
compositions <- list(
  list(data = parse_age_table("Table A31:", "Table A32:"), table = "Table A31", name = "ECSI winter survey", type = "index", fleet = "", survey = "Kaharoa ECSI winter trawl survey", region = "ECSI", ess = 20),
  list(data = parse_age_table("Table A32:", "Table A33:"), table = "Table A32", name = "ENLD fishery", type = "catch", fleet = "ENLD commercial trawl fishery", survey = "", region = "ENLD", ess = 15),
  list(data = parse_age_table("Table A33:", "Table A34:"), table = "Table A33", name = "BPLE fishery", type = "catch", fleet = "BPLE commercial trawl fishery", survey = "", region = "BPLE", ess = 20),
  list(data = parse_age_table("Table A34:", "Table A35:"), table = "Table A34", name = "TAR2 fishery", type = "catch", fleet = "TAR 2 commercial trawl fishery", survey = "", region = "TAR 2", ess = 30),
  list(data = parse_age_table("Table A35:", "Table A36:"), table = "Table A35", name = "Cook fishery", type = "catch", fleet = "Cook Strait commercial trawl fishery", survey = "", region = "Cook Strait", ess = 5),
  list(data = parse_age_table("Table A36:", "Table A37:"), table = "Table A36", name = "Kaikoura set-net fishery", type = "catch", fleet = "Kaikoura set-net fishery", survey = "", region = "Kaikoura", ess = 10),
  list(data = parse_age_table("Table A37:"), table = "Table A37", name = "ECSI fishery", type = "catch", fleet = "ECSI commercial trawl fishery", survey = "", region = "ECSI", ess = 30)
)

cpue <- list(
  list(data = parse_cpue("Table A5:", "Table A6:", 1994:2025), table = "Table A5", fleet = "ENLD commercial trawl fishery", region = "ENLD"),
  list(data = parse_cpue("Table A10:", "Table A11:", 1994:2025), table = "Table A10", fleet = "BPLE commercial trawl fishery", region = "BPLE"),
  list(data = parse_cpue("Table A15:", "Table A16:", 2008:2025), table = "Table A15", fleet = "TAR 2 commercial trawl fishery", region = "TAR 2"),
  list(data = parse_cpue("Table A20:", "Table A21:", 2008:2025), table = "Table A20", fleet = "Cook Strait commercial trawl fishery", region = "Cook Strait"),
  list(data = parse_cpue("Table A24:", "Table A25:", 1990:2025), table = "Table A24", fleet = "Kaikoura set-net fishery", region = "Kaikoura")
)
biomass_indices <- parse_biomass_indices()
age2_indices <- parse_age2_indices()

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_integer_, year_basis = "",
    age = NA_real_, fleet = "", survey = "", sex = "", region = "", season = "",
    sampling_time = NA_real_, source_type = "official_table", source_reference,
    transformation = "", notes = "", observation_id = "", sample_size = NA_real_) {
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id, type, measure, basis, fleet, survey, sex, region, season,
    year = as.integer(year), year_basis, age = as.numeric(age), value = as.numeric(value),
    unit, sampling_time, source_type, source_reference, transformation, notes,
    observation_id, length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = as.numeric(sample_size),
    age_error = NA_real_, partition = NA_character_, stringsAsFactors = FALSE
  )
}

catch_fleets <- c(ECSI = "ECSI commercial trawl fishery", Kaikoura = "Kaikoura set-net fishery",
  Cook = "Cook Strait commercial trawl fishery", TAR2_trawl = "TAR 2 commercial trawl fishery",
  TAR2_rec = "TAR 2 recreational fishery", BPLE_trawl = "BPLE commercial trawl fishery",
  BPLE_rec = "BPLE recreational fishery", ENLD = "ENLD commercial trawl fishery")
catch_regions <- c(ECSI = "ECSI", Kaikoura = "Kaikoura", Cook = "Cook Strait", TAR2_trawl = "TAR 2",
  TAR2_rec = "TAR 2", BPLE_trawl = "BPLE", BPLE_rec = "BPLE", ENLD = "ENLD")
for (i in seq_len(nrow(catch))) for (fleet_key in names(catch_fleets)) {
  year <- catch$year[i]
  add_input("catch", "total_biomass", "biomass", catch[[fleet_key]][i], "tonnes",
    year = year, year_basis = "model_year", fleet = unname(catch_fleets[fleet_key]),
    region = unname(catch_regions[fleet_key]),
    source_reference = "Fisheries New Zealand FAR 2026/44, Table A30",
    notes = "Published catch biomass, including the report's allowance for unreported commercial catch. Model year 2025 represents the 2024-25 fishing year.",
    observation_id = paste("catch", fleet_key, year, sep = "_"))
}

for (spec in compositions) for (i in seq_len(nrow(spec$data))) {
  z <- spec$data[i, ]
  add_input(spec$type, "proportion_at_age", "proportion_numbers", z$value, "proportion",
    year = z$year, year_basis = "model_year", age = z$age, fleet = spec$fleet,
    survey = spec$survey, sex = "both", region = spec$region, sample_size = spec$ess,
    source_reference = paste("Fisheries New Zealand FAR 2026/44,", spec$table),
    notes = paste("Source-reported age composition for both sexes combined; age 30 represents 30+. Values are retained as reported and were not normalized. The Table 15 effective sample size applies to the whole observation, not to an age cell."),
    observation_id = paste(spec$name, z$year, sep = "_"))
}

add_index <- function(measure, basis, value, unit, cv, year, survey = "", fleet = "", region = "",
    age = NA_real_, source_reference, observation_id, notes, cv_measure, cv_source_type = "official_table",
    cv_transformation = "") {
  add_input("index", measure, basis, value, unit, year = year, year_basis = "model_year",
    age = age, survey = survey, fleet = fleet, region = region,
    source_reference = source_reference, notes = notes, observation_id = observation_id)
  add_input("index", cv_measure, "relative_scale", cv, "ratio", year = year,
    year_basis = "model_year", age = age, survey = survey, fleet = fleet, region = region,
    source_type = cv_source_type, source_reference = source_reference,
    transformation = cv_transformation,
    notes = "Coefficient of variation for the matching index observation.", observation_id = observation_id)
}

for (i in seq_len(nrow(biomass_indices))) {
  z <- biomass_indices[i, ]
  survey <- paste("Kaharoa ECSI", tolower(z$series), "trawl survey")
  obs_id <- paste0("ECSI_", tolower(z$series), "_biomass_", z$year)
  add_index("total_biomass", "biomass", z$value, "tonnes", z$cv_percent / 100,
    z$year, survey = survey, region = "ECSI", source_reference = "Fisheries New Zealand FAR 2026/44, Table 8",
    observation_id = obs_id,
    notes = paste("Kaharoa ECSI", tolower(z$series), "survey biomass index. Source model year", z$year,
      "is mapped from survey year", z$survey_year, ". No fractional-year sampling time is reported."),
    cv_measure = "biomass_index_cv", cv_transformation = "Source CV reported as percent; divided by 100 to store a ratio.")
}

for (i in seq_len(nrow(age2_indices))) {
  z <- age2_indices[i, ]
  obs_id <- paste0("ECSI_age2_abundance_", z$year)
  add_index("numbers_at_age", "index_scale", z$value, "survey index units (scale not specified)",
    z$cv_percent / 100, z$year, survey = "Kaharoa ECSI age-2 trawl survey index",
    region = "ECSI", age = 2, source_reference = "Fisheries New Zealand FAR 2026/44, Table 9",
    observation_id = obs_id,
    notes = paste("Age-2 abundance index; the report does not specify the numeric scale multiplier. Survey year class is", z$cohort_year, ". No fractional-year sampling time is reported."),
    cv_measure = "numbers_at_age_cv", cv_transformation = "Source CV reported as percent; divided by 100 to store a ratio.")
}

for (spec in cpue) for (i in seq_len(nrow(spec$data))) {
  z <- spec$data[i, ]
  obs_id <- paste0(gsub("[^A-Za-z0-9]+", "_", spec$fleet), "_", z$year)
  ref <- paste("Fisheries New Zealand FAR 2026/44,", spec$table)
  add_input("index", "relative_abundance_index", "index_scale", z$index,
    "relative index units", year = z$year, year_basis = "model_year",
    fleet = spec$fleet, region = spec$region, source_reference = ref,
    notes = paste("Combined standardized CPUE series listed as a base-model abundance index. Fishing year is mapped to its ending model year. Source 95% interval:", z$lwr, "to", z$upr, ". Table 14 reports the model CV separately; the interval is not converted to a per-year CV."),
    observation_id = obs_id)
}

for (age in 1:6) {
  value <- if (age <= 3L) 0 else if (age == 4L) 0.25 else if (age == 5L) 0.5 else 1
  add_input("maturity", "maturity_at_age", "proportion_numbers", value, "proportion",
    age = age, source_reference = "Fisheries New Zealand FAR 2026/44, Table 13, p. 50",
    notes = if (age == 6L) "Age 6 represents ages 6+; the report provides one age-based schedule and no sex-specific schedule." else "Source-reported age-based maturity schedule.")
}

inputs <- do.call(rbind, input_rows)
if (nrow(inputs) != 2364L || sum(inputs$measure == "total_biomass" & inputs$type == "catch") != 752L ||
    sum(inputs$measure == "proportion_at_age") != 1410L ||
    sum(inputs$measure == "total_biomass" & inputs$type == "index") != 20L ||
    sum(inputs$measure == "numbers_at_age" & inputs$type == "index") != 10L ||
    sum(inputs$measure == "relative_abundance_index") != 136L ||
    any(!is.finite(inputs$value))) {
  stop("Parsed input coverage does not match the published eastern tarakihi tables.", call. = FALSE)
}

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "", sex = "", region = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id, component, fleet = "", survey = "", sex, region, season = "",
    setting, value = as.character(value), source_reference, notes,
    stringsAsFactors = FALSE
  )
}
bio_ref <- "Fisheries New Zealand FAR 2026/44, Table 13, p. 50"
add_assumption("mortality", "natural mortality", "0.10 per year, fixed for both sexes", bio_ref,
  "The report attributes this value to an age-structure analysis of a lightly exploited tarakihi population sampled in 1971-1972.")
growth <- data.frame(sex = rep(c("male", "female"), each = 4L),
  parameter = rep(c("L1", "L40", "k", "b"), 2L),
  value = c(12.23, 41.74, 0.085, 3.39, 12.32, 45.25, 0.104, 2.53),
  unit = c("cm", "cm", "per year", "", "cm", "cm", "per year", ""), stringsAsFactors = FALSE)
for (i in seq_len(nrow(growth))) add_assumption("growth", paste("Schnute", growth$parameter[i]),
  paste(growth$value[i], growth$unit[i]), bio_ref,
  "Sex-specific Schnute growth parameter reported for the 2026 base assessment.", sex = growth$sex[i])
add_assumption("length_weight", "length-weight relationship", "W = 4.0e-05 * L^2.79", bio_ref,
  "The report gives parameters a=4.0e-05 and b=2.79; the table does not state units for L or W.")
add_assumption("maturity", "proportion mature at age", "Ages 1-3: 0; age 4: 0.25; age 5: 0.5; ages 6+: 1.0", bio_ref,
  "One age-based schedule is reported; no sex-specific maturity schedule is tabulated.")
add_assumption("recruitment", "stock-recruitment relationship", "Beverton-Holt; steepness fixed at 0.8", bio_ref)
add_assumption("recruitment", "recruitment standard deviation", "sigmaR = 0.6", bio_ref,
  "The main recruitment deviations are estimated as independent deviations without an averaging constraint.")
add_assumption("recruitment", "estimated deviations", "1980-2023; independent deviations without an averaging constraint",
  "Fisheries New Zealand FAR 2026/44, section 7.2, p. 50")
add_assumption("population", "model structure", "Three spatial regions; two sexes; 40 age classes with age 40+ as a plus group",
  "Fisheries New Zealand FAR 2026/44, section 7.2, pp. 49-50",
  "The eastern biological stock spans TAR 3, TAR 2 and eastern portions of TAR 1 and TAR 7. The model estimates age-dependent movement among regions.")
add_assumption("population", "model years", "1932-2025", "Fisheries New Zealand FAR 2026/44, section 7.2, p. 49",
  "Model year 2025 represents the 2024-25 fishing year.")
add_assumption("population", "movement", "Age-dependent movement among three regions; annual deviations estimated for the age-2 transition point from 2010-2024",
  "Fisheries New Zealand FAR 2026/44, section 7.2, pp. 52-54",
  "Movement is a central feature of the eastern model and was varied in a no-movement sensitivity run.")
add_assumption("time", "annual time step", "October-September; periods October-March and April-September",
  "Fisheries New Zealand FAR 2026/44, section 7.2, p. 50",
  "Spawning is assumed instantaneously at the start of period 2. The report does not specify fractional-year sampling times for individual indices.")
add_assumption("data_weighting", "age-composition effective sample sizes", "ENLD 15; BPLE 20; TAR 2 30; Cook 5; Kaikoura set net 10; ECSI commercial 30; ECSI winter survey 20",
  "Fisheries New Zealand FAR 2026/44, Table 15, p. 51",
  "Effective sample sizes apply to each composition observation; they are not counts of fish aged.")
add_assumption("index_precision", "base CPUE CVs and process error", "ENLD 0.30; BPLE 0.27-0.34; TAR 2 daily 0.20 and event 0.14-0.15; Cook daily 0.20 and event 0.19-0.21; Kaikoura set net 0.20",
  "Fisheries New Zealand FAR 2026/44, Table 14, p. 51",
  "Daily TAR 2 and Cook CPUE series are listed for 1990-2007 but their annual values are not tabulated in this report. Event-based TAR 2 and Cook indices include an additional 0.10 process error.")
add_assumption("index_precision", "ECSI survey index CV ranges", "Winter biomass 0.19-0.55; summer biomass 0.13-0.24; age-2 abundance 0.23-0.38",
  "Fisheries New Zealand FAR 2026/44, Table 14, p. 51")
add_assumption("selectivity", "CPUE index sharing", "Daily and event-based TAR 2 and Cook indices share corresponding selectivity but estimate separate catchability coefficients",
  "Fisheries New Zealand FAR 2026/44, section 7.2, p. 50")
add_assumption("data_selection", "ECSI CPUE", "Not included in the base assessment model",
  "Fisheries New Zealand FAR 2026/44, section 7.2, p. 48",
  "The report considers these indices less reliable due to changes in fishery operation and recent differences from other abundance indices.")
add_assumption("data_selection", "FMA 2 inshore trawl surveys", "Not included in the base assessment model",
  "Fisheries New Zealand FAR 2026/44, section 5.2, pp. 44-45",
  "Three surveys have biomass indices but no age compositions; the report says they provide limited abundance and population-structure information.")
add_assumption("likelihood", "abundance indices", "Lognormal likelihood",
  "Fisheries New Zealand FAR 2026/44, Table 13",
  "Applies to the CPUE and Kaharoa survey indices included in the base model.")
add_assumption("likelihood", "age compositions", "Multinomial likelihood",
  "Fisheries New Zealand FAR 2026/44, Table 13",
  "Commercial fishery and ECSI winter survey age compositions are reported for ages 1-29 and 30+.")
assumptions <- do.call(rbind, assumption_rows)

output_values <- data.frame(
  type = c(rep("biomass", 6L), rep("mortality", 3L), "catch", rep("biomass", 12L)),
  measure = c("unfished_spawning_biomass", "SSB", "SSB_ratio_to_B0",
    "probability_above_40_percent_B0", "probability_above_20_percent_B0", "probability_above_10_percent_B0",
    "F_reference_at_SB40", "F_ratio_to_FSB40", "probability_below_FSB40", "yield_at_FSB40",
    rep(c("SSB_ratio_to_B0", "probability_above_10_percent_B0", "probability_above_20_percent_B0", "probability_above_40_percent_B0"), 3L)),
  year = c(NA_integer_, rep(2025L, 5L), NA_integer_, 2025L, 2025L, NA_integer_, rep(2030L, 12L)),
  value = c(69831, 5403, 0.077, 0, 0, 0.005, 0.065, 2.62, 0, 881,
    0.069, 0.070, 0, 0, 0.067, 0.062, 0, 0, 0.123, 0.948, 0.002, 0),
  lwr = c(67885, 4398, 0.063, NA, NA, NA, NA, 2.25, NA, 698,
    0.036, NA, NA, NA, 0.035, NA, NA, NA, 0.096, NA, NA, NA),
  upr = c(72224, 6466, 0.092, NA, NA, NA, NA, 3.06, NA, 1080,
    0.114, NA, NA, NA, 0.112, NA, NA, NA, 0.160, NA, NA, NA),
  unit = c("tonnes", "tonnes", "ratio", "probability", "probability", "probability",
    "per year", "ratio", "probability", "tonnes", rep(c("ratio", "probability", "probability", "probability"), 3L)),
  scenario = c(rep("", 10L), rep(c("TACC", "Catch", "FSB40%"), each = 4L)),
  stringsAsFactors = FALSE
)
outputs <- do.call(rbind, lapply(seq_len(nrow(output_values)), function(i) data.frame(
  assessment_id, type = output_values$type[i], measure = output_values$measure[i],
  fleet = "", survey = "", sex = "", region = "", season = "", year = output_values$year[i],
  age = NA_real_, age_group = "", value = output_values$value[i], se = NA_real_,
  lwr = output_values$lwr[i], upr = output_values$upr[i], unit = output_values$unit[i],
  source_type = "official_table",
  source_reference = if (i <= 6L) "Fisheries New Zealand FAR 2026/44, Table 17, p. 67" else if (i <= 10L) "Fisheries New Zealand FAR 2026/44, Table 18, p. 68" else "Fisheries New Zealand FAR 2026/44, Table 19, p. 69",
  notes = paste("Base-case MCMC median or probability. The report labels intervals as 95% confidence intervals and describes the MCMC uncertainty as 95% credible intervals.",
    if (i > 10L) "Projection result for the named 2030 scenario." else ""),
  scenario = output_values$scenario[i], stringsAsFactors = FALSE
)))

stocks <- data.frame(
  stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "TAR 3, TAR 2, and eastern portions of TAR 1 and TAR 7",
  scientific_name = "Nemadactylus macropterus", common_name = "Eastern tarakihi",
  area = "Eastern biological stock: TAR 3, TAR 2, and eastern portions of TAR 1 and TAR 7",
  region = "New Zealand east coast waters", ocean = "Southwest Pacific",
  notes = "One eastern biological stock represented by a three-region Stock Synthesis model with estimated movement; regional components are not separate stocks.",
  stringsAsFactors = FALSE
)
assessments <- data.frame(
  assessment_id, stock_id, assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.23.1; 2026 base case",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_, assessment_url = source_url,
  framework_url = "", data_url = source_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Latest detailed production assessment located for the eastern tarakihi biological stock; model years 1932-2025, with 2025 representing the 2024-25 fishing year.",
    "The three-region model includes age-dependent movement. Canonical inputs preserve fishery catch biomass, age compositions, selected CPUE series, ECSI survey biomass and the age-2 index.",
    "Annual values for the daily TAR 2 and Cook CPUE series (1990-2007) are listed as model inputs but not tabulated in the report. The report does not provide direct age-specific weights or annual N-at-age, F-at-age, M-at-age and recruitment arrays. No associated native Stock Synthesis run files were located in the official report entry or targeted repository search."
  ), stringsAsFactors = FALSE
)
manifest <- data.frame(local_file = sub("^\\./?", "", source_file), source_url = source_url,
  retrieved_on = retrieved_on, sha256 = expected_hash, stringsAsFactors = FALSE)

cat("Eastern tarakihi parsed: ", nrow(inputs), " inputs (752 catches, 1,410 composition cells, 136 CPUE indices, 30 survey indices with source CVs, six maturity values), ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n", sep = "")

if (write_mode) {
  id_exists <- function(path, id) {
    con <- file(path, open = "r")
    on.exit(close(con))
    repeat {
      chunk <- readLines(con, n = 20000L, warn = FALSE)
      if (!length(chunk)) return(FALSE)
      if (any(startsWith(chunk, paste0('"', id, '"')))) return(TRUE)
    }
  }
  database_dir <- file.path(root, "database")
  if (id_exists(file.path(database_dir, "stocks.csv"), stock_id) ||
      id_exists(file.path(database_dir, "assessments.csv"), assessment_id)) {
    stop("Refusing to duplicate the eastern tarakihi stock or assessment.", call. = FALSE)
  }
  append_csv <- function(data, path) write.table(data, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  append_csv(stocks, file.path(database_dir, "stocks.csv"))
  append_csv(assessments, file.path(database_dir, "assessments.csv"))
  append_csv(inputs, file.path(database_dir, "inputs.csv"))
  append_csv(assumptions, file.path(database_dir, "assumptions.csv"))
  append_csv(outputs, file.path(database_dir, "outputs.csv"))
  write.csv(manifest, "provenance/mpi_tarakihi_eastern_2026_sources.csv", row.names = FALSE, na = "")

  source("scripts/database/candidate_register_io.R")
  register_path <- file.path(root, "discovery", "candidates.csv")
  register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  position <- match(candidate_id, register$candidate_id)
  if (is.na(position)) stop("Eastern tarakihi candidate is missing from the register.", call. = FALSE)
  candidate <- register[position, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "Imported 752 published catch-biomass cells (eight fisheries, 1932-2025) and 1,410 source-reported age-composition cells for 47 observations. Catch numbers-at-age are not tabulated; composition proportions remain separate and unnormalized."
  candidate$survey_age_evidence <- "Imported 15 winter and five summer ECSI biomass indices, ten age-2 abundance indices, five base-model CPUE series where annual values are tabulated, and the available age compositions. Daily TAR 2 and Cook CPUE values for 1990-2007 are not tabulated."
  candidate$weights_evidence <- "Imported sex-specific Schnute growth and length-weight parameters as assumptions; no direct annual weight-at-age surface is published."
  candidate$maturity_evidence <- "Imported the age-based schedule: ages 1-3 0, age 4 0.25, age 5 0.5, ages 6+ 1.0; the report does not provide a sex-specific schedule."
  candidate$mortality_evidence <- "Imported fixed natural mortality of 0.10 per year for both sexes."
  candidate$timing_evidence <- "Model year is October-September, split into October-March and April-September, with spawning at the start of period 2. No fractional-year timing is specified for individual indices."
  candidate$output_evidence <- "Imported Tables 17-19 MCMC medians, available 95% intervals, biomass-status probabilities, fishing-mortality reference outputs and projection summaries. Annual numeric N/F/M-at-age and recruitment arrays are not tabulated."
  candidate$decision_reason <- "Partial source import completed from the latest detailed 2026 eastern tarakihi production assessment. Catch biomass, age compositions, available base-model indices, biological assumptions and terminal/projection outputs are represented; missing daily CPUE and annual fitted state arrays remain explicit source gaps."
  candidate$notes <- "One eastern biological stock spanning TAR 3, TAR 2 and eastern portions of TAR 1 and TAR 7; the official model has three spatial regions and estimated movement."
  replace_candidate_register_row(register_path, position, candidate, candidate_id)
  sys.source("scripts/database/195_summarize_discovery.R", envir = new.env(parent = globalenv()))
  sys.source("scripts/database/196_summarize_inventory_units.R", envir = new.env(parent = globalenv()))
}
