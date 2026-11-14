root <- "."
assessment_id <- "noaa_vermilion_snapper_gulf_sedar67_2020"
candidate_id <- "NOAA:10256"
source_dir <- "source_cache/discovery_noaa_vermilion_snapper_gom_2020"
report_url <- paste0(
  "https://sedarweb.org/documents/",
  "sedar-67-gulf-of-mexico-vermilion-snapper-final-stock-assessment-report/"
)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source("scripts/database/pacific_tables.R")
source("scripts/database/candidate_register_io.R")

manifest <- read.csv(
  "provenance/discovery_noaa_vermilion_snapper_gom_2020/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"
)

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  value <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(value) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  value
}

verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), tolower(row$sha256))) {
    stop("Cached source differs from its pinned provenance record: ", name,
      call. = FALSE)
  }
  path
}

report <- verify_source("sedar67_final_assessment.pdf")
text_path <- paste0(report, ".txt")
if (!file.exists(text_path)) {
  stop("Create the local page-separated report text extract beside the cached PDF.",
    call. = FALSE)
}
report_text <- readChar(text_path, file.info(text_path)$size, useBytes = TRUE)
pages <- strsplit(report_text, "\f", fixed = TRUE)[[1L]]
appendix_lines <- unlist(lapply(pages[175:190], function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE)

section_lines <- function(lines, start, end) {
  first <- which(grepl(start, lines, fixed = TRUE))[1L]
  last_candidates <- which(grepl(end, lines, fixed = TRUE))
  last_candidates <- last_candidates[last_candidates > first]
  if (is.na(first) || !length(last_candidates)) {
    stop("Could not find source section: ", start, call. = FALSE)
  }
  lines[seq.int(first + 1L, last_candidates[1L] - 1L)]
}

numeric_values <- function(line) {
  line <- sub("#.*$", "", line)
  matches <- gregexpr(
    "[-+]?(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?",
    line, perl = TRUE
  )[[1L]]
  if (matches[1L] < 0L) return(numeric())
  as.numeric(regmatches(line, list(matches))[[1L]])
}

year_start <- function(line) grepl("^\\s*(19|20)[0-9]{2}\\s+", line)

parse_fixed_rows <- function(lines, fields, label) {
  selected <- lines[year_start(lines)]
  rows <- lapply(selected, numeric_values)
  if (!length(rows) || any(lengths(rows) != fields)) {
    stop("Unexpected ", label, " row width in the SEDAR 67 DAT file.",
      call. = FALSE)
  }
  data <- as.data.frame(do.call(rbind, rows))
  if (any(!is.finite(as.matrix(data)))) {
    stop("Non-finite values in ", label, ".", call. = FALSE)
  }
  data
}

parse_compositions <- function(lines, fields, label) {
  records <- list()
  source_ids <- character()
  current <- numeric()
  current_id <- ""
  for (line in lines) {
    values <- numeric_values(line)
    if (year_start(line)) {
      if (length(current)) {
        if (length(current) != fields) {
          stop("Incomplete ", label, " record before the next year.", call. = FALSE)
        }
        records[[length(records) + 1L]] <- current
        source_ids <- c(source_ids, current_id)
      }
      current <- values
      current_id <- ""
    } else if (length(current) && length(values) &&
        grepl("^\\s*[-+.]?[0-9]", sub("#.*$", "", line))) {
      if (length(values) == 1L && values == floor(values) &&
          values >= 1 && values <= 200) next
      current <- c(current, values)
    }
    source_id <- regmatches(line, regexpr("#_[0-9]+", line))
    if (length(current) && length(source_id)) current_id <- sub("^#_", "", source_id)
    if (length(current) == fields) {
      records[[length(records) + 1L]] <- current
      source_ids <- c(source_ids, current_id)
      current <- numeric()
      current_id <- ""
    } else if (length(current) > fields) {
      stop("Too many values in a ", label, " record.", call. = FALSE)
    }
  }
  if (length(current)) {
    if (length(current) != fields) {
      stop("Incomplete final ", label, " record.", call. = FALSE)
    }
    records[[length(records) + 1L]] <- current
    source_ids <- c(source_ids, current_id)
  }
  if (!length(records) || any(lengths(records) != fields)) {
    stop("No complete ", label, " records were parsed.", call. = FALSE)
  }
  result <- as.data.frame(do.call(rbind, records))
  result$source_row <- source_ids
  result
}

fleet_info_lines <- section_lines(appendix_lines, "#_fleetinfo", "#Bycatch_fleet_input")
fleet_info <- lapply(fleet_info_lines, function(line) {
  clean <- trimws(sub("#.*$", "", line))
  cells <- strsplit(clean, "[[:space:]]+")[[1L]]
  source_code <- regmatches(line, regexpr("#_[0-9]+", line))
  if (length(cells) != 6L || !length(source_code) ||
      anyNA(suppressWarnings(as.numeric(cells[1:5])))) {
    return(NULL)
  }
  data.frame(
    fleet_code = as.integer(sub("^#_", "", source_code)),
    fleet_type = as.integer(cells[1L]),
    survey_timing_code = as.numeric(cells[2L]), area = as.integer(cells[3L]),
    catch_units = as.integer(cells[4L]), fleet = cells[6L],
    stringsAsFactors = FALSE
  )
})
fleet_info <- do.call(rbind, Filter(Negate(is.null), fleet_info))
if (nrow(fleet_info) != 9L || !identical(fleet_info$fleet_code, 1:9)) {
  stop("The SEDAR 67 DAT fleet map is incomplete.", call. = FALSE)
}
fleet_names <- setNames(fleet_info$fleet, fleet_info$fleet_code)
survey_names <- setNames(
  c("East Gulf headboat CPUE", "West Gulf headboat CPUE",
    "SEAMAP larval survey", "Video survey",
    "SEAMAP summer groundfish survey"),
  as.character(5:9)
)
catch_unit <- function(code) {
  if (code == 1L) return(list(basis = "biomass", unit = "metric tons",
    measure = "catch_biomass"))
  if (code == 2L) return(list(basis = "numbers", unit = "thousand fish",
    measure = "catch_numbers"))
  stop("Unknown SS3 catch-unit code: ", code, call. = FALSE)
}
input_rows <- list()
add_input <- function(type, measure, basis, value, unit, source_reference,
                      year = NA_integer_, season = NA_character_, age = NA_integer_,
                      fleet = NA_character_, survey = NA_character_, sex = NA_character_,
                      source_type = "native_model", observation_id = NA_character_,
                      length_bin = NA_real_, length_bin_lower = NA_real_,
                      length_bin_upper = NA_real_, sample_size = NA_real_,
                      age_error = NA_real_, partition = NA_real_, notes = "") {
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row(
    "inputs", assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, value = value, unit = unit, year = year,
    year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    season = season, age = age, fleet = fleet, survey = survey, sex = sex,
    source_type = source_type, source_reference = source_reference,
    observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition,
    notes = notes
  )
}

catch <- parse_fixed_rows(section_lines(
  appendix_lines, "#_Catch data", "#_CPUE_and_surveyabundance_observations"
), 5L, "catch")
names(catch) <- c("year", "season", "fleet_code", "value", "catch_se")
if (nrow(catch) != 272L || !setequal(unique(catch$year), 1950:2017) ||
    !setequal(unique(catch$fleet_code), 1:4)) {
  stop("SEDAR 67 catch rows do not cover 1950-2017 for fleets 1-4.",
    call. = FALSE)
}
for (i in seq_len(nrow(catch))) {
  code <- as.integer(catch$fleet_code[i])
  units <- catch_unit(fleet_info$catch_units[match(code, fleet_info$fleet_code)])
  is_placeholder <- code == 4L
  add_input("catch", units$measure, units$basis, catch$value[i], units$unit,
    "SEDAR 67 final report, Appendix A DAT file, catch data (PDF pp. 175-179)",
    year = as.integer(catch$year[i]), season = as.character(as.integer(catch$season[i])),
    fleet = fleet_names[as.character(code)], partition = "catch",
    notes = if (is_placeholder) {
      "Native 0.001 bycatch-fleet catch placeholder. Do not interpret as a measured catch total."
    } else {
      "Native annual fleet catch copied from the accepted SS3 DAT file."
    })
  add_input("catch", "catch_se", "native_scale", catch$catch_se[i],
    "native SS3 catch_se value",
    "SEDAR 67 final report, Appendix A DAT file, catch data (PDF pp. 175-179)",
    year = as.integer(catch$year[i]), season = as.character(as.integer(catch$season[i])),
    fleet = fleet_names[as.character(code)], partition = "catch",
    notes = "Native catch_se field retained without interpreting it as a CV or likelihood SD.")
}

index_fleet_lines <- section_lines(
  appendix_lines, "#_Fleet Units", "#_CPUE_data"
)
index_fleet_info <- lapply(index_fleet_lines, function(line) {
  clean <- trimws(sub("#.*$", "", line))
  cells <- strsplit(clean, "[[:space:]]+")[[1L]]
  if (length(cells) != 4L || anyNA(suppressWarnings(as.numeric(cells[1:4])))) {
    return(NULL)
  }
  data.frame(
    fleet_code = as.integer(cells[1L]), units = as.integer(cells[2L]),
    error_type = as.integer(cells[3L]), sd_report = as.integer(cells[4L])
  )
})
index_fleet_info <- do.call(rbind, Filter(Negate(is.null), index_fleet_info))
if (!identical(index_fleet_info$fleet_code, 1:9) ||
    !all(index_fleet_info$error_type == 0L)) {
  stop("Unexpected SEDAR 67 index-fleet settings.", call. = FALSE)
}
indices <- parse_fixed_rows(section_lines(
  appendix_lines, "#_CPUE_data", "#_discard_units"
), 5L, "index")
names(indices) <- c("year", "season", "fleet_code", "value", "se_log")
if (!setequal(unique(indices$fleet_code), 1:9) ||
    any(!indices$year %in% 1950:2017)) {
  stop("SEDAR 67 aggregate index rows have unexpected fleets or years.",
    call. = FALSE)
}
for (i in seq_len(nrow(indices))) {
  code <- as.integer(indices$fleet_code[i])
  unit_code <- index_fleet_info$units[match(code, index_fleet_info$fleet_code)]
  measure <- switch(as.character(unit_code),
    "0" = "relative_abundance_index",
    "1" = "relative_biomass_index",
    "2" = "relative_fishing_mortality_index",
    "30" = "larval_abundance_index",
    stop("Unrecognized SS3 index-unit code: ", unit_code, call. = FALSE))
  fleet <- if (code <= 4L) fleet_names[as.character(code)] else NA_character_
  survey <- if (code > 4L) survey_names[as.character(code)] else NA_character_
  basis <- if (code == 7L) "native_scale" else "index_scale"
  add_input("index", measure, basis, indices$value[i],
    paste0("native SS3 index units (code ", unit_code, ")"),
    "SEDAR 67 final report, Appendix A DAT file, CPUE data (PDF pp. 179-183)",
    year = as.integer(indices$year[i]),
    season = as.character(as.integer(indices$season[i])),
    fleet = fleet, survey = survey,
    notes = paste0("Aggregate fishery-dependent or survey index observation on its source scale. ",
      "No proportion-of-year survey timing is inferred from the SS3 timing code."))
  add_input("index", "log_index_sd", "log_scale", indices$se_log[i],
    "natural-log standard deviation",
    "SEDAR 67 final report, Appendix A DAT file, CPUE data (PDF pp. 179-183)",
    year = as.integer(indices$year[i]),
    season = as.character(as.integer(indices$season[i])),
    fleet = fleet, survey = survey,
    notes = "Native se_log value; the CPUE fleet error type is 0 (lognormal).")
}

discard_fleet_lines <- section_lines(
  appendix_lines, "#_discard_fleet_info", "#_discard_data"
)
discard_fleet_info <- lapply(discard_fleet_lines, function(line) {
  clean <- trimws(sub("#.*$", "", line))
  cells <- strsplit(clean, "[[:space:]]+")[[1L]]
  if (length(cells) != 3L || anyNA(suppressWarnings(as.numeric(cells)))) {
    return(NULL)
  }
  data.frame(
    fleet_code = as.integer(cells[1L]), units = as.integer(cells[2L]),
    error_type = as.integer(cells[3L])
  )
})
discard_fleet_info <- do.call(rbind, Filter(Negate(is.null), discard_fleet_info))
if (!identical(discard_fleet_info$fleet_code, 1:4) ||
    !all(discard_fleet_info$units == 1L) ||
    !all(discard_fleet_info$error_type == -2L)) {
  stop("Unexpected SEDAR 67 discard-fleet settings.", call. = FALSE)
}
discards <- parse_fixed_rows(section_lines(
  appendix_lines, "#_discard_data", "#_meanbodywt"
), 5L, "discard")
names(discards) <- c("year", "season", "fleet_code", "value", "std_in")
if (nrow(discards) != 132L ||
    !setequal(unique(abs(discards$fleet_code)), 1:4)) {
  stop("SEDAR 67 discard rows do not match the accepted DAT file.",
    call. = FALSE)
}
for (i in seq_len(nrow(discards))) {
  source_code <- as.integer(discards$fleet_code[i])
  code <- abs(source_code)
  units <- catch_unit(fleet_info$catch_units[match(code, fleet_info$fleet_code)])
  fleet <- fleet_names[as.character(code)]
  if (source_code < 0L) fleet <- paste0(fleet, " (SS3 source code ", source_code, ")")
  add_input("catch", if (units$basis == "biomass") "discard_biomass" else
      "discard_numbers", units$basis, discards$value[i], units$unit,
    "SEDAR 67 final report, Appendix A DAT file, discard data (PDF pp. 183-185)",
    year = as.integer(discards$year[i]),
    season = as.character(as.integer(discards$season[i])), fleet = fleet,
    partition = "discard",
    notes = paste0("Native discard observation. SS3 negative season/fleet codes ",
      "are preserved in the row dimensions and fleet label."))
  add_input("catch", "catch_se", "native_scale", discards$std_in[i],
    "native SS3 discard Std_in value",
    "SEDAR 67 final report, Appendix A DAT file, discard data (PDF pp. 183-185)",
    year = as.integer(discards$year[i]),
    season = as.character(as.integer(discards$season[i])), fleet = fleet,
    partition = "discard",
    notes = "Native discard Std_in retained; fleet discard error type is -2 (lognormal).")
}

length_bins_line <- section_lines(
  appendix_lines, "#_N_lbins", "#_lencomp"
)
length_bin_vector <- length_bins_line[
  grepl("#_lbin_vector", length_bins_line, fixed = TRUE) &
    vapply(length_bins_line, function(x) length(numeric_values(x)) > 0L, logical(1))
][1L]
length_bins <- numeric_values(length_bin_vector)
if (!identical(length_bins, c(1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55))) {
  stop("SEDAR 67 length-bin labels do not match the printed DAT vector.",
    call. = FALSE)
}
length_compositions <- parse_compositions(section_lines(
  appendix_lines, "#_lencomp", "#_N_agebins"
), 6L + length(length_bins), "length composition")
if (any(length_compositions[[6L]] <= 0)) {
  stop("Length composition Nsamp must be positive.", call. = FALSE)
}
for (i in seq_len(nrow(length_compositions))) {
  code <- as.integer(length_compositions[i, 3L])
  type <- if (code <= 4L) "catch" else "index"
  fleet <- if (code <= 4L) fleet_names[as.character(code)] else NA_character_
  survey <- if (code > 4L) survey_names[as.character(code)] else NA_character_
  observation_id <- paste0("SEDAR67_LEN_", length_compositions$source_row[i])
  for (j in seq_along(length_bins)) {
    add_input(type, "proportion_at_length", "proportion_numbers",
      length_compositions[i, 6L + j], "proportion",
      "SEDAR 67 final report, Appendix A DAT file, length compositions (PDF p. 186)",
      year = as.integer(length_compositions[i, 1L]),
      season = as.character(as.integer(length_compositions[i, 2L])),
      fleet = fleet, survey = survey,
      sex = as.character(as.integer(length_compositions[i, 4L])),
      observation_id = observation_id, length_bin = length_bins[j],
      sample_size = length_compositions[i, 6L],
      partition = as.integer(length_compositions[i, 5L]),
      notes = paste0("Native SS3 length-composition proportion and bin label. ",
        "Source length-bin units are not specified in the printed DAT file; ",
        "gender code 0 and partition code are preserved."))
  }
}

age_bins_line <- section_lines(
  appendix_lines, "#_N_agebins", "#_ageing_error"
)
age_bin_vector <- age_bins_line[
  grepl("#_agebin_vector", age_bins_line, fixed = TRUE) &
    vapply(age_bins_line, function(x) length(numeric_values(x)) > 0L, logical(1))
][1L]
age_bins <- numeric_values(age_bin_vector)
if (!identical(as.integer(age_bins), 1:14)) {
  stop("SEDAR 67 age-bin labels do not match the printed DAT vector.",
    call. = FALSE)
}
age_compositions <- parse_compositions(section_lines(
  appendix_lines, "#_age_info", "#_MeanSize_at_Age_obs"
), 9L + length(age_bins), "age composition")
if (any(age_compositions[[9L]] <= 0)) {
  stop("Age composition Nsamp must be positive.", call. = FALSE)
}
for (i in seq_len(nrow(age_compositions))) {
  code <- as.integer(age_compositions[i, 3L])
  type <- if (code <= 4L) "catch" else "index"
  fleet <- if (code <= 4L) fleet_names[as.character(code)] else NA_character_
  survey <- if (code > 4L) survey_names[as.character(code)] else NA_character_
  observation_id <- paste0("SEDAR67_AGE_", age_compositions$source_row[i])
  for (j in seq_along(age_bins)) {
    add_input(type, "proportion_at_age", "proportion_numbers",
      age_compositions[i, 9L + j], "proportion",
      "SEDAR 67 final report, Appendix A DAT file, age compositions (PDF pp. 187-190)",
      year = as.integer(age_compositions[i, 1L]),
      season = as.character(as.integer(age_compositions[i, 2L])),
      age = age_bins[j], fleet = fleet, survey = survey,
      sex = as.character(as.integer(age_compositions[i, 4L])),
      observation_id = observation_id,
      length_bin_lower = age_compositions[i, 7L],
      length_bin_upper = age_compositions[i, 8L],
      sample_size = age_compositions[i, 9L],
      age_error = as.integer(age_compositions[i, 6L]),
      partition = as.integer(age_compositions[i, 5L]),
      notes = paste0("Native SS3 age-composition proportion and sample size. ",
        "Age 14 is the terminal plus group; SS3 gender code 0, partition, ",
        "age-error code, and unconditioned length sentinels are retained."))
  }
}

natural_mortality_text <- readLines(text_path, warn = FALSE)
table_start <- grep("^Table 3:.*natural mortality", natural_mortality_text,
  ignore.case = TRUE)
table_end <- grep("^Table 4:", natural_mortality_text)
table_end <- table_end[table_end > table_start[1L]]
if (length(table_start) != 1L || !length(table_end)) {
  stop("Could not locate SEDAR 67 Table 3 natural mortality values.",
    call. = FALSE)
}
table_lines <- natural_mortality_text[seq.int(table_start + 1L, table_end[1L] - 1L)]
natural_mortality <- lapply(table_lines, numeric_values)
natural_mortality <- Filter(function(x) {
  length(x) == 2L && x[1L] %in% 0:15
}, natural_mortality)
natural_mortality <- as.data.frame(do.call(rbind, natural_mortality))
names(natural_mortality) <- c("age", "value")
if (!identical(as.integer(natural_mortality$age), 0:15) ||
    any(!is.finite(natural_mortality$value))) {
  stop("SEDAR 67 Table 3 does not parse as natural mortality for ages 0-15.",
    call. = FALSE)
}
for (i in seq_len(nrow(natural_mortality))) {
  add_input("M", "natural_mortality_at_age", "per_year",
    natural_mortality$value[i], "per year",
    "SEDAR 67 final report, Table 3",
    age = as.integer(natural_mortality$age[i]), source_type = "official_table",
    notes = "Source-reported fixed Lorenzen M input. Table 3 lists ages 0-15; the model is described as ages 0-14 with age 14 as the plus group, so age 15 is retained under its printed label without remapping.")
}

inputs <- do.call(rbind, input_rows)
assumptions <- do.call(rbind, list(
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "catch", setting = "catch_data_coverage",
    value = "Annual SS3 catch records for fleets 1-4, 1950-2017.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF pp. 175-179",
    notes = "Commercial east/west catches are in metric tons; recreational catch is in thousands of fish. Fleet 4 values are 0.001 bycatch-fleet placeholders, not measured catch totals."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "catch", setting = "catch_se_field",
    value = "Native SS3 catch_se copied per catch row.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF pp. 175-179",
    notes = "The fleet-info file sets need_catch_mult=0. Values are preserved without treating them as catch CVs or likelihood SDs."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "index", setting = "aggregate_index_coverage",
    value = "Aggregate CPUE/index records for SS3 fleets 1-9; no age-specific abundance index.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF pp. 179-183",
    notes = "All nine series use error type 0 (lognormal). Native se_log values are recorded on the log scale."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "index", setting = "ss3_index_unit_codes",
    value = "CM_E=1 biomass; CM_W=1 biomass; REC=0 numbers; SMP_BYC=2 F; HB_E=0 numbers; HB_W=0 numbers; LARVAL=30 special; VIDEO=0 numbers; SEAMAP=0 numbers.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF p. 179",
    notes = "Unit codes are retained verbatim in the input rows; no index scaling is inferred from these codes."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "index", setting = "survey_timing_code",
    value = "SS3 fleet-info survey timing code 1 for survey fleets.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF p. 175",
    notes = "The report does not establish a proportion-of-year conversion for this code. No numeric sampling_time is inferred."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "catch", setting = "discard_input_treatment",
    value = "Discard units code 1 (same as catch units); discard error type -2 (lognormal).",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF pp. 183-185",
    notes = "Native per-record discard Std_in values and signed season/fleet codes are retained without conversion."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "composition", setting = "age_composition_input",
    value = "SS3 age compositions by fleet with age bins 1-14; age 14 is the terminal plus group.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF pp. 187-190",
    notes = "Native proportions, input Nsamp, gender code, partition, age-error code, and length-bin sentinels are preserved. These samples are not age-specific abundance indices or catch numbers at age."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "composition", setting = "length_composition_input",
    value = "SS3 length compositions use source bin labels 1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55.",
    source_reference = "SEDAR 67 final report, Appendix A DAT file, PDF p. 186",
    notes = "Proportions and input Nsamp are preserved. The printed file does not state length-bin units."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "M", setting = "natural_mortality_input",
    value = "Table 3 fixed Lorenzen age-specific M, target average M 0.25.",
    source_reference = "SEDAR 67 final report, Table 3",
    notes = "Age 0 is adjusted for the assumed midyear birth date; the source table's age 0-15 labels are retained."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "biology", setting = "fixed_biological_parameters",
    value = paste(
      "L_at_Amin=11.83; L_at_Amax=34.4; VonBert_K=0.3254;",
      "CV_young=0.2535; CV_old=0.2535; Wtlen_1=2.19e-5; Wtlen_2=2.916;",
      "Mat50=14.087; Mat_slope=-0.574; Eggs_scalar=278.715;",
      "Eggs_exp_len=3.042; female fraction=0.5."
    ),
    source_reference = "SEDAR 67 final report, Appendix A CTL file, PDF p. 192",
    notes = "The printed CTL marks these biological parameters fixed. They are retained as native parameter values; no age-specific weight or maturity surface is derived here.")
))

if (!nrow(inputs) || any(!is.finite(inputs$value))) {
  stop("SEDAR 67 source input rows contain missing or non-finite values.",
    call. = FALSE)
}
duplicate_keys <- c("assessment_id", "type", "measure", "basis", "fleet",
  "survey", "sex", "region", "season", "year", "year_basis", "age",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin")
input_key <- do.call(paste, c(lapply(inputs[duplicate_keys], function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}), sep = "\r"))
if (anyDuplicated(input_key)) stop("Generated duplicate input rows.", call. = FALSE)

update_candidate <- function() {
  path <- "discovery/candidates.csv"
  candidates <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(candidates$candidate_id == candidate_id)
  if (length(i) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
  candidates$import_status[i] <- "partial"
  add_evidence <- function(old, new) {
    if (is.na(old) || !nzchar(old)) new else paste(old, new)
  }
  candidates$catch_age_evidence[i] <- add_evidence(
    candidates$catch_age_evidence[i],
    "SEDAR 67 Appendix A has catch totals and fishery age compositions; no catch-at-age matrix is directly reported or reconstructed."
  )
  candidates$survey_age_evidence[i] <- add_evidence(
    candidates$survey_age_evidence[i],
    "SEDAR 67 Appendix A supplies aggregate index series and fishery age compositions; no age-specific abundance index or survey age composition is supplied."
  )
  candidates$weights_evidence[i] <- add_evidence(
    candidates$weights_evidence[i],
    "SEDAR 67 CTL prints fixed growth and weight-length parameters; an age-specific weight surface is not directly transcribed."
  )
  candidates$maturity_evidence[i] <- add_evidence(
    candidates$maturity_evidence[i],
    "SEDAR 67 CTL prints fixed logistic maturity parameters; an age-specific maturity surface is not derived."
  )
  candidates$mortality_evidence[i] <- add_evidence(
    candidates$mortality_evidence[i],
    "SEDAR 67 Table 3 reports fixed Lorenzen M by age."
  )
  candidates$timing_evidence[i] <- add_evidence(
    candidates$timing_evidence[i],
    "The accepted DAT file gives SS3 survey-timing code 1; conversion to a proportion of year remains unresolved."
  )
  candidates$notes[i] <- paste(
    candidates$notes[i],
    "SEDAR 67 Appendix A catch, index, discard, age/length composition, and Table 3 M inputs imported; no age-specific catch or survey index derived."
  )
  replace_candidate_register_row(path, i, candidates[i, , drop = FALSE],
    candidate_id)
}

replace_csv_row <- function(path, key_column, key_value, row) {
  table <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
  i <- which(as.character(table[[key_column]]) == key_value)
  if (length(i) != 1L || nrow(row) != 1L) {
    stop("Expected one record for ", key_value, " in ", path, call. = FALSE)
  }
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- i + 1L
  old_record <- rawToChar(bytes[bounds$start[record_index]:bounds$end[record_index]])
  if (!startsWith(old_record, paste0('"', key_value, '"'))) {
    stop("CSV record identity changed before replacement.", call. = FALSE)
  }
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) {
    replacement <- replacement[-length(replacement)]
  }
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) {
    replacement <- replacement[-length(replacement)]
  }
  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  has_carriage_return <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_carriage_return <- TRUE
    next_byte <- next_byte + 1L
  }
  line_ending <- raw()
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    line_ending <- c(if (has_carriage_return) as.raw(13L) else raw(), as.raw(10L))
    last <- next_byte
    replacement <- c(replacement, line_ending)
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw()
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw()
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE), error = function(e) NULL)
  valid <- !is.null(updated) && nrow(updated) == nrow(table) &&
    sum(as.character(updated[[key_column]]) == key_value, na.rm = TRUE) == 1L
  if (!valid) {
    writeBin(original, path)
    stop("Updated CSV failed its row-count or identity check.", call. = FALSE)
  }
}

update_assessment_notes <- function() {
  path <- "database/assessments.csv"
  assessments <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(assessments$assessment_id == assessment_id)
  if (length(i) != 1L) stop("Assessment ID is not unique.", call. = FALSE)
  assessments$notes[i] <- paste(
    "SEDAR 67 Table 18 outputs and Appendix A DAT source inputs are imported.",
    "Catch totals and fishery compositions are retained separately; age-specific catch numbers and survey abundance were not derived.",
    "See the source review for unresolved unit and timing details."
  )
  replace_csv_row(path, "assessment_id", assessment_id,
    assessments[i, , drop = FALSE])
}

append_rows <- function(table, rows) {
  write.table(rows, file.path("database", paste0(table, ".csv")),
    sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
    qmethod = "double")
}

if (!write_mode) {
  cat(
    "Dry run:", nrow(inputs), "inputs;",
    nrow(catch), "catch rows;", nrow(indices), "indices;",
    nrow(discards), "discards;", nrow(length_compositions), "length compositions;",
    nrow(age_compositions), "age compositions;", nrow(natural_mortality),
    "fixed M-at-age values.\n"
  )
} else {
  existing <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, "database/inputs.csv"),
    stdout = TRUE, stderr = FALSE))
  status <- attr(existing, "status")
  if (is.null(status)) status <- 0L
  if (status == 0L && length(existing)) {
    stop("Input rows already exist for this assessment; review before writing.",
      call. = FALSE)
  }
  if (status != 1L) stop("Could not verify existing assessment inputs.",
    call. = FALSE)
  append_rows("inputs", inputs)
  append_rows("assumptions", assumptions)
  update_candidate()
  update_assessment_notes()
  cat("Imported", nrow(inputs), "input rows and", nrow(assumptions),
    "assumptions for", assessment_id, ".\n")
}
