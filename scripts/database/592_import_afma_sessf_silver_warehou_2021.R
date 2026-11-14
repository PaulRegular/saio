assessment_id <- "afma_sessf_silver_warehou_2021"
stock_id <- "afma_sessf_silver_warehou"
candidate_id <- "AFMA:SESSF_SILVER_WAREHOU"
selected_path <- "discovery/selected_batch_08_2026.csv"
manifest_path <- "provenance/afma_sessf_silver_warehou_2021_sources.csv"
report_url <- "https://www.afma.gov.au/sites/default/files/2023-02/Stock%20Assessments%20for%20SESSF%202020%E2%80%9321%20-%20Part%201.pdf"
summary_url <- "https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf"
retrieved_on <- "2026-11-06"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.", call. = FALSE)
}

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0, check.names = FALSE))
  missing <- setdiff(header, names(rows))
  if (length(missing)) stop("Import rows lack columns: ", paste(missing, collapse = ", "), call. = FALSE)
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    final_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(final_byte, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  rows[] <- lapply(rows[header], as.character)
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "\n")
}

replace_csv_row <- function(path, id, row) {
  lines <- readLines(path, warn = FALSE)
  pattern <- paste0('(^|,)"', id, '"(,|$)')
  index <- which(grepl(pattern, lines, perl = TRUE))
  if (length(index) != 1L) stop("Could not identify one row for ", id, " in ", path, call. = FALSE)
  temporary <- tempfile()
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "")
  lines[index] <- readLines(temporary, warn = FALSE)
  unlink(temporary)
  writeLines(lines, path, useBytes = TRUE)
}

rows_exist <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  prefix <- paste0('"', id, '",')
  repeat {
    lines <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}

stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
candidates <- read_table("discovery/candidates.csv")
selected <- read_table(selected_path)
manifest <- read_table(manifest_path)
candidate_index <- which(candidates$candidate_id == candidate_id)
selected_index <- which(selected$candidate_id == candidate_id)
source_paths <- file.path("source_cache", manifest$local_file)

stopifnot(
  length(candidate_index) == 1L,
  length(selected_index) == 1L,
  candidates$import_status[candidate_index] == "not_started",
  candidates$eligibility[candidate_index] == "unresolved",
  selected$curation_status[selected_index] == "selected_for_partial_source_curation",
  !stock_id %in% stocks$stock_id,
  !assessment_id %in% assessments$assessment_id,
  !rows_exist("database/assumptions.csv", assessment_id),
  !rows_exist("database/inputs.csv", assessment_id),
  !rows_exist("database/outputs.csv", assessment_id),
  nrow(manifest) == 2L,
  all(manifest$retrieved_on == retrieved_on),
  all(file.exists(source_paths)),
  identical(toupper(unname(tools::sha256sum(source_paths))), toupper(manifest$sha256))
)

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "AFMA",
  authority_stock_id = "Silver Warehou (SESSF)",
  scientific_name = "Seriolella punctata",
  common_name = "Silver warehou",
  area = "Southern and Eastern Scalefish and Shark Fishery; east trawl zones 10, 20 and 30, and west trawl zones 40 and 50",
  region = "Southern and eastern Australia",
  ocean = "Southwest Pacific and Southern Ocean",
  notes = "AFMA models one stock with separate east and west trawl fleets. The 2021 report splits the fleets east and west of 147 degrees east; no separate biological stocks are identified.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2021L,
  terminal_year = 2020L,
  estimate_terminal_year = 2040L,
  assessment_type = "Tier 1 full assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.17.00",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = "",
  assessment_url = report_url,
  framework_url = "",
  data_url = summary_url,
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The model fits data through 2020; reported projections extend through 2040.",
    "AFMA's 2026 summary states the later 2024 Tier 1 assessment was not accepted",
    "and current TAC advice continues to use fixed-catch projections from 2021.",
    "The published report does not provide the numerical CPUE, length-frequency,",
    "conditional age-at-length, or annual age-specific state arrays."
  ),
  stringsAsFactors = FALSE
)

assumption_row <- function(component, setting, value, source_reference, notes = "",
                           fleet = "", survey = "", region = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = "", region = region, season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption_row("assessment", "stock_structure", "One modelled stock in one region with separate east and west trawl fleets.", "AFMA 2020-21 assessment, Section 13.3.1, p. 626; AFMA 2026 species summary, p. 139"),
  assumption_row("population", "model_years", "Annual calendar years 1980-2020; 2021 catch was repeated from 2020 for projections and is not an observed input.", "AFMA 2020-21 assessment, Section 13.3.2.1 and Table 13.2, pp. 628 and 630"),
  assumption_row("population", "fleet_structure", "East trawl covers SESSF zones 10, 20 and 30; west trawl covers zones 40 and 50, separated at 147 degrees east.", "AFMA 2020-21 assessment, Section 13.2.2, p. 624 and Section 13.3.1, p. 626"),
  assumption_row("assessment", "model_version", "Stock Synthesis 3.30.17.00; annual age- and size-structured model.", "AFMA 2020-21 assessment, Section 13.3.1, p. 626"),
  assumption_row("population", "age_plus_group", "Age 23 is the observation plus group.", "AFMA 2020-21 assessment, Table 13.1, p. 627"),
  assumption_row("M", "natural_mortality", "M = 0.30 per year, fixed.", "AFMA 2020-21 assessment, Table 13.1, p. 627; AFMA 2026 species summary, p. 139"),
  assumption_row("recruitment", "stock_recruitment_steepness", "Beverton-Holt steepness h = 0.75, fixed.", "AFMA 2020-21 assessment, Table 13.1, p. 627; AFMA 2026 species summary, p. 139"),
  assumption_row("biology", "growth", "Von Bertalanffy length-at-age curve estimated for males and females combined.", "AFMA 2020-21 assessment, Section 13.3.1, p. 626; AFMA 2026 species summary, p. 139"),
  assumption_row("biology", "length_weight_relationship", "Weight = 0.0000065 * length^3.27, with length in cm and weight in grams.", "AFMA 2020-21 assessment, Table 13.1, p. 627; AFMA 2026 species summary, p. 139", "The coefficients are fixed source parameters; no weight-at-age vector is tabulated."),
  assumption_row("biology", "maturity", "Female maturity is logistic in length, with 50% maturity fixed at 37 cm; fecundity at length is proportional to weight at length.", "AFMA 2020-21 assessment, p. 627 and Table 13.1; AFMA 2026 species summary, p. 139", "No numeric maturity-at-age surface is published."),
  assumption_row("recruitment", "recruitment_variability_start_value", "The starting value for the recruitment process-error parameter sigma_R is 0.7.", "AFMA 2020-21 assessment, Section 13.3.3, p. 639; AFMA 2026 species summary, p. 139", "This is an initial parameter value, not a fixed final estimate."),
  assumption_row("recruitment", "low_recruitment_projection", "The base case projects low recruitment from 2016 onward using the mean recruitment deviations from 2011-2015.", "AFMA 2020-21 assessment, Section 13.2.4, p. 625; Section 13.4.1.4, p. 650; AFMA 2026 species summary, p. 140"),
  assumption_row("selectivity", "fleet_selectivity", "Selectivity is estimated separately for east and west trawl fleets.", "AFMA 2020-21 assessment, Section 13.3.1, p. 626; Table 13.8, p. 644"),
  assumption_row("catch", "retention_time_blocks", "Retention has a time block in 2002; east trawl has an additional block from 2018 to represent increased recent discarding.", "AFMA 2020-21 assessment, Section 13.2.4, p. 625; AFMA 2026 species summary, p. 140"),
  assumption_row("index", "standardized_cpue", "Aggregate standardized CPUE indices are used for east and west trawl fleets for 1986-2020.", "AFMA 2020-21 assessment, Section 13.3.2 and Figures 13.10-13.11, pp. 628-644", "The annual numerical index vectors are shown in figures, not tabulated, and were not digitized."),
  assumption_row("index", "cpue_observation_error", "Initial CVs are 0.174 for east and 0.178 for west; an additional SD is estimated in Stock Synthesis after tuning.", "AFMA 2020-21 assessment, Section 13.3.3, p. 639", "The initial CVs are not the final fitted likelihood errors. No CPUE input rows are created without the numerical observations."),
  assumption_row("index", "fishery_independent_survey", "Fishery-independent survey abundance indices are excluded from the base-case assessment and considered as a sensitivity.", "AFMA 2020-21 assessment, Section 13.2.4, p. 625"),
  assumption_row("observation", "composition_likelihoods", "The model fits retained and discard length frequencies and conditional age-at-length data; observed composition cells are not tabulated.", "AFMA 2020-21 assessment, Section 13.3.1, p. 626; Tables 13.4-13.6, pp. 635-637", "Published sample counts are retained separately and are not represented as composition vectors."),
  assumption_row("observation", "length_composition_sample_rules", "Length composition sample sizes were initially weighted using trip and shot counts where available; trips were capped at 100, shots at 200, and samples with fewer than 100 fish were excluded.", "AFMA 2020-21 assessment, Section 13.3.3, p. 639; Tables 13.4-13.5, pp. 635-636", "The report does not publish the numerical length-frequency cells."),
  assumption_row("observation", "age_reading_error", "Fishery-wide age-reading error SDs are supplied for ages 0-23.", "AFMA 2020-21 assessment, Table 13.7, p. 638", "The numeric SD vector is imported in inputs.csv; it is not a true-age to observed-age transition matrix."),
  assumption_row("observation", "survey_timing", "unknown", "AFMA 2020-21 assessment, Sections 13.3.1-13.3.2", "Annual CPUE series are described, but a within-year observation fraction is not specified."),
  assumption_row("assessment", "current_advice_status", "The 2021 assessment remains the basis for fixed-catch TAC advice; the 2024 Tier 1 assessment was not accepted.", "AFMA 2026 SESSF species summary, pp. 140-143", "The 2026 summary recommends and the Commission determined a 350 t TAC for 2026-27 using fixed-catch projections from the 2021 assessment.")
))

input_row <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = "", year = NA_character_, age = NA_character_,
                      sample_size = NA_character_, age_error = "", partition = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = "", sex = "", region = "", season = "",
    year = year, year_basis = if (is.na(year)) "" else "calendar_year",
    age = age, value = value, unit = unit, sampling_time = "",
    source_type = "official_table", source_reference = source_reference,
    transformation = "", notes = notes, observation_id = "", length_bin = "",
    length_bin_lower = "", length_bin_upper = "", sample_size = sample_size,
    age_error = age_error, partition = partition, stringsAsFactors = FALSE
  )
}

catch_years <- 1980:2020
catch_east <- c(
  29.5, 59.0, 88.6, 118.1, 147.6, 58.4, 433.3, 261.0, 781.6, 342.8,
  866.8, 664.3, 1246.0, 1115.7, 1671.8, 1307.0, 1222.1, 1236.1, 987.5,
  1091.1, 803.0, 713.4, 771.3, 618.8, 528.2, 511.3, 442.9, 313.9,
  450.5, 413.1, 312.2, 252.5, 209.3, 181.3, 95.9, 71.4, 128.3, 105.8,
  94.5, 77.5, 106.6
)
catch_west <- c(
  29.5, 59.0, 88.6, 118.1, 147.6, 301.6, 574.7, 487.8, 584.0, 577.6,
  258.7, 698.9, 618.8, 853.5, 825.7, 843.7, 1145.4, 1354.8, 1446.4,
  2158.7, 2923.7, 2583.3, 3330.7, 2439.3, 2787.5, 2400.6, 1933.2,
  1688.9, 1073.6, 968.9, 977.0, 976.4, 638.4, 464.4, 285.7, 315.3,
  222.3, 242.4, 299.0, 256.1, 190.7
)
stopifnot(length(catch_years) == length(catch_east), length(catch_years) == length(catch_west))

catch_inputs <- do.call(rbind, lapply(seq_along(catch_years), function(i) {
  year <- catch_years[i]
  note <- if (year <= 1993) {
    "Total East/West assessment catch. The 1980-1993 series is the agreed historical series; the current assessment compiles catches from 1994 onward."
  } else {
    "Total East/West assessment catch, combining the SESSF and state catch components shown in the table."
  }
  rbind(
    input_row("catch", "catch_biomass", "biomass", catch_east[i], "tonnes",
      "AFMA 2020-21 assessment, Table 13.2, p. 630", note, fleet = "East trawl", year = year),
    input_row("catch", "catch_biomass", "biomass", catch_west[i], "tonnes",
      "AFMA 2020-21 assessment, Table 13.2, p. 630", note, fleet = "West trawl", year = year)
  )
}))

discard_years <- 1992:2020
discard_east <- c(0, .06, .02, .74, .10, .12, .15, .01, .09, .21, .31, .31, .46, .23, .09, .01, .03, .03, .01, .10, .04, .25, .05, .37, .24, .19, .43, .58, .79)
discard_east_n <- c(6, 182, 199, 123, 173, 285, 174, 155, 135, 228, 209, 262, 343, 299, 271, 53, 155, 108, 106, 108, 76, 70, 42, 89, 121, 99, 98, 149, 71)
discard_east_used <- c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)
discard_west <- c(0, 0, .04, .05, .33, .32, .40, .17, .14, .09, .14, 0, .13, .13, 0, .06, .03, .03, .02, .10, .17, .02, .02, .01, .02, .10, 0, .18, .08)
discard_west_n <- c(7, 52, 109, 127, 120, 90, 120, 121, 94, 161, 184, 129, 123, 263, 125, 71, 143, 159, 233, 229, 165, 161, 57, 77, 54, 78, 71, 213, 416)
discard_west_used <- c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE)
stopifnot(all(lengths(list(discard_east, discard_east_n, discard_east_used,
  discard_west, discard_west_n, discard_west_used)) == length(discard_years)))

discard_inputs <- do.call(rbind, lapply(seq_along(discard_years), function(i) {
  year <- discard_years[i]
  rbind(
    input_row("catch", "discard_fraction", "proportion", discard_east[i], "proportion",
      "AFMA 2020-21 assessment, Table 13.3, p. 632",
      paste("Reported east-trawl discard proportion; source used flag is", ifelse(discard_east_used[i], "y", "n"),
        "(the table identifies small samples or proportions close to zero as excluded). Proportion basis is not specified in the report."),
      fleet = "East trawl", year = year, sample_size = discard_east_n[i]),
    input_row("catch", "discard_fraction", "proportion", discard_west[i], "proportion",
      "AFMA 2020-21 assessment, Table 13.3, p. 632",
      paste("Reported west-trawl discard proportion; source used flag is", ifelse(discard_west_used[i], "y", "n"),
        "(the table identifies small samples or proportions close to zero as excluded). Proportion basis is not specified in the report."),
      fleet = "West trawl", year = year, sample_size = discard_west_n[i])
  )
}))

age_sample_years <- c(1988, 1993:2020)
age_sample_east <- c(0, 172, 186, 157, 317, 443, 404, 220, 139, 366, 327, 122, 126, 250, 132, 237, 313, 493, 687, 543, 659, 89, 153, 165, 206, 220, 118, 414, 371)
age_sample_west <- c(132, 163, 173, 294, 198, 123, 181, 562, 267, 631, 395, 302, 512, 375, 261, 69, 234, 345, 135, 309, 214, 383, 139, 218, 273, 316, 13, 475, 510)
age_sample_inputs <- do.call(rbind, lapply(seq_along(age_sample_years), function(i) {
  year <- age_sample_years[i]
  rows <- list()
  if (age_sample_east[i] > 0) rows[[length(rows) + 1L]] <- input_row(
    "biology", "composition_sample_count", "numbers", age_sample_east[i], "aged otoliths",
    "AFMA 2020-21 assessment, Table 13.6, p. 637",
    "Number of conditional age-at-length samples reported for the fleet-year. This is a sample count, not an age composition or effective likelihood sample size.",
    fleet = "East trawl", year = year, partition = "conditional_age_at_length"
  )
  if (age_sample_west[i] > 0) rows[[length(rows) + 1L]] <- input_row(
    "biology", "composition_sample_count", "numbers", age_sample_west[i], "aged otoliths",
    "AFMA 2020-21 assessment, Table 13.6, p. 637",
    "Number of conditional age-at-length samples reported for the fleet-year. This is a sample count, not an age composition or effective likelihood sample size.",
    fleet = "West trawl", year = year, partition = "conditional_age_at_length"
  )
  do.call(rbind, rows)
}))

age_error_sd <- c(.170607, .170607, .229462, .290210, .352911, .417629, .484427,
  .553373, .624537, .697988, .773802, .852053, .932821, 1.016190, 1.102230,
  1.191040, 1.282710, 1.377330, 1.474980, 1.575780, 1.679820, 1.787210,
  1.898040, 2.012440)
age_error_inputs <- do.call(rbind, lapply(0:23, function(age) input_row(
  "biology", "ageing_error_sd", "age_error_sd", age_error_sd[age + 1L], "years",
  "AFMA 2020-21 assessment, Table 13.7, p. 638",
  "Standard deviation of age-reading error, combined across east and west fleets; not a transition matrix.",
  age = age, age_error = "age_reading_error_sd"
)))
inputs <- rbind(catch_inputs, discard_inputs, age_sample_inputs, age_error_inputs)

output_row <- function(type, measure, value, unit, source_reference, notes = "",
                       year = NA_character_, fleet = "", scenario = "",
                       lwr = "", upr = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = "", sex = "", region = "", season = "",
    year = year, age = "", age_group = "", value = value, se = "",
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes,
    scenario = scenario, stringsAsFactors = FALSE
  )
}

parameter_names <- c(
  "L_at_amin", "L_at_amax", "VonBert_K", "CV_young", "Q_EastTrawl",
  "Q_WestTrawl", "Size_inflection_Etrawl", "Size_95_width_Etrawl",
  "Size_inflection_Wtrawl", "Size_95_width_Wtrawl"
)
parameter_values <- c(14.12, 51.30, .30, .08, 9.40, -.02, 22.24, 2.50, 38.40, 12.91)
parameter_units <- c("cm", "cm", "year^-1", "ratio", rep("native Stock Synthesis parameter scale", 2), rep("cm", 4))
parameter_notes <- c(
  "Estimated Stock Synthesis parameter as printed; the report does not define its exact length-at-age role in the parameter table.",
  "Estimated Stock Synthesis parameter as printed; the report does not define its exact length-at-age role in the parameter table.",
  "Estimated Von Bertalanffy K parameter; males and females are combined.",
  "Estimated CV_young parameter; the report does not define a further transformation in the table.",
  "The report labels this estimated parameter Q_EastTrawl. Preserve the native reported value; no transformation or back-transformation is inferred.",
  "The report labels this estimated parameter Q_WestTrawl. Preserve the signed native reported value; no transformation or back-transformation is inferred.",
  "Estimated east-trawl size-inflection parameter as printed.",
  "Estimated east-trawl size 95% width parameter as printed.",
  "Estimated west-trawl size-inflection parameter as printed.",
  "Estimated west-trawl size 95% width parameter as printed."
)
parameter_outputs <- do.call(rbind, lapply(seq_along(parameter_names), function(i) output_row(
  "parameter", parameter_names[i], parameter_values[i], parameter_units[i],
  "AFMA 2020-21 assessment, Table 13.8, p. 644", parameter_notes[i]
)))

table_13_10_years <- 2018:2025
table_13_10_status <- c(23, 25, 27, 29, 28, 29, 29, 29)
table_13_10_retained <- c(393, 334, 297, 297, 467, 461, 457, 457)
table_13_10_discards <- c(89, 70, 80, 78, 120, 119, 118, 118)
table_13_10_rbc <- c(587, 580, 575, 575)
table_13_10_outputs <- c(
  lapply(seq_along(table_13_10_years), function(i) output_row(
    "biomass", "SSB_ratio_to_B0", table_13_10_status[i], "percent of B0",
    "AFMA 2020-21 assessment, Table 13.10, p. 659",
    "Reported stock status rounded to a whole percent; Table 13.10 low-recruitment HCR summary.",
    year = table_13_10_years[i], scenario = "Low recruitment HCR summary"
  )),
  lapply(seq_along(table_13_10_years), function(i) output_row(
    "catch", "retained_catch", table_13_10_retained[i], "tonnes",
    "AFMA 2020-21 assessment, Table 13.10, p. 659",
    "Reported retained catch under the low-recruitment HCR summary; fitted-period values and projections are distinguished by year.",
    year = table_13_10_years[i], scenario = "Low recruitment HCR summary"
  )),
  lapply(seq_along(table_13_10_years), function(i) output_row(
    "catch", "estimated_discards", table_13_10_discards[i], "tonnes",
    "AFMA 2020-21 assessment, Table 13.10, p. 659",
    "Reported estimated discard mass under the low-recruitment HCR summary.",
    year = table_13_10_years[i], scenario = "Low recruitment HCR summary"
  )),
  lapply(seq_along(table_13_10_rbc), function(i) output_row(
    "management", "recommended_biological_catch", table_13_10_rbc[i], "tonnes",
    "AFMA 2020-21 assessment, Table 13.10, p. 659",
    "Recommended biological catch from the low-recruitment HCR; this is advice, not observed catch.",
    year = 2022L + i - 1L, scenario = "Low recruitment HCR summary"
  ))
)

projection_years <- 2022:2040
projection_scenarios <- c("0 t constant catch", "250 t constant catch", "350 t constant catch", "450 t constant catch", "Harvest control rule")
projection_status <- list(
  c(.29, .31, .34, .36, .37, .39, .40, .42, .43, .44, .44, .45, .46, .46, .46, .47, .47, .47, .48),
  c(.29, .30, .31, .32, .33, .34, .34, .35, .36, .36, .36, .37, .37, .38, .38, .38, .38, .38, .39),
  c(.29, .30, .30, .31, .31, .31, .32, .32, .33, .33, .33, .33, .34, .34, .34, .34, .34, .34, .35),
  c(.29, .29, .29, .29, .29, .29, .29, .30, .30, .30, .30, .30, .30, .30, .30, .30, .30, .30, .30),
  rep(.29, 19)
)
projection_retained <- list(
  rep(0, 19), rep(250, 19), rep(350, 19), rep(450, 19),
  c(587, 580, 575, 575, 580, 585, 588, 590, 590, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591)
)
projection_discards <- list(
  rep(0, 19),
  c(61, 60, 59, 59, 58, 58, 57, 57, 56, 56, 56, 56, 55, 55, 55, 55, 55, 55, 55),
  c(86, 85, 85, 84, 84, 83, 83, 83, 82, 82, 82, 81, 81, 81, 81, 81, 81, 81, 80),
  c(110, 110, 110, 110, 110, 110, 110, 110, 110, 110, 110, 109, 109, 109, 109, 109, 109, 109, 109),
  c(120, 119, 118, 118, 119, 120, 121, 121, 121, 121, 121, 122, 122, 122, 122, 122, 122, 122, 122)
)
stopifnot(all(lengths(projection_status) == length(projection_years)),
  all(lengths(projection_retained) == length(projection_years)),
  all(lengths(projection_discards) == length(projection_years)))

projection_outputs <- list()
for (s in seq_along(projection_scenarios)) {
  for (i in seq_along(projection_years)) {
    year <- projection_years[i]
    scenario <- paste("Low recruitment;", projection_scenarios[s])
    projection_outputs[[length(projection_outputs) + 1L]] <- output_row(
      "biomass", "SSB_ratio_to_B0", projection_status[[s]][i], "ratio",
      "AFMA 2020-21 assessment, Table 13.11, p. 662",
      "Projected stock status under the source-defined low-recruitment catch scenario.", year, scenario = scenario
    )
    projection_outputs[[length(projection_outputs) + 1L]] <- output_row(
      "catch", "retained_catch", projection_retained[[s]][i], "tonnes",
      "AFMA 2020-21 assessment, Table 13.11, p. 662",
      "Projected retained catch under the source-defined low-recruitment catch scenario.", year, scenario = scenario
    )
    projection_outputs[[length(projection_outputs) + 1L]] <- output_row(
      "catch", "estimated_discards", projection_discards[[s]][i], "tonnes",
      "AFMA 2020-21 assessment, Table 13.11, p. 662",
      "Projected discard mass under the source-defined low-recruitment catch scenario.", year, scenario = scenario
    )
  }
}
projection_outputs <- do.call(rbind, projection_outputs)

scalar_outputs <- rbind(
  output_row("biomass", "unfished_spawning_biomass", 18806, "tonnes",
    "AFMA 2020-21 assessment, Table 13.12, p. 680",
    "Base-case unfished spawning biomass includes male and female biomass; no uncertainty is reported."),
  output_row("biomass", "SSB", 5374, "tonnes",
    "AFMA 2020-21 assessment, Table 13.12, p. 680",
    "Projected 2022 spawning biomass, including male and female biomass; no uncertainty is reported.", year = 2022L,
    scenario = "Base case, low recruitment projections"),
  output_row("biomass", "SSB_ratio_to_B0", .29, "ratio",
    "AFMA 2020-21 assessment, Table 13.12, p. 680",
    "Projected 2022 SSB/B0 ratio; male and female biomass are included; no uncertainty is reported.", year = 2022L,
    scenario = "Base case, low recruitment projections")
)
outputs <- do.call(rbind, c(list(parameter_outputs), table_13_10_outputs,
  list(projection_outputs, scalar_outputs)))

stopifnot(
  nrow(catch_inputs) == 82L,
  nrow(discard_inputs) == 58L,
  nrow(age_sample_inputs) == 57L,
  nrow(age_error_inputs) == 24L,
  nrow(parameter_outputs) == 10L,
  nrow(projection_outputs) == 285L,
  inputs$value[inputs$measure == "catch_biomass" & inputs$fleet == "East trawl" & inputs$year == 1980] == 29.5,
  inputs$value[inputs$measure == "catch_biomass" & inputs$fleet == "West trawl" & inputs$year == 2020] == 190.7,
  inputs$value[inputs$measure == "discard_fraction" & inputs$fleet == "East trawl" & inputs$year == 2020] == .79,
  inputs$value[inputs$measure == "ageing_error_sd" & inputs$age == 23] == 2.012440,
  outputs$value[outputs$measure == "Q_WestTrawl"] == -.02,
  outputs$value[outputs$measure == "SSB" & outputs$year == 2022] == 5374,
  outputs$value[outputs$measure == "SSB_ratio_to_B0" & outputs$scenario == "Low recruitment; 350 t constant catch" & outputs$year == 2040] == .35
)

candidate <- candidates[candidate_index, , drop = FALSE]
candidate$import_status <- "partial"
candidate$decision_reason <- paste(
  "A partial source record was imported from the 2021 assessment, the latest detailed assessment used for current advice.",
  "Catch biomass, discard proportions and sample counts, age-reading error, fitted parameters, stock-status outputs, and low-recruitment projections are preserved.",
  "Age-input eligibility remains unresolved because the CPUE, length-composition, and age-at-length observation arrays were not located."
)
candidate$notes <- paste(
  "Imported source rows are limited to reported tables; no compositions or fitted annual age-specific surfaces were reconstructed.",
  "The 2024 Tier 1 assessment was not accepted. See discovery/source_reviews/afma_sessf_silver_warehou_2021.md."
)

selected_row <- selected[selected_index, , drop = FALSE]
selected_row$curation_status <- "source_curated_partial"

cat("AFMA SESSF silver warehou:", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions,", nrow(outputs), "outputs.\n")
cat("Age-input eligibility remains unresolved; no tinyAM fit was attempted.\n")

if (!write_mode) {
  cat("Dry run only. Re-run with --write to update the source tables.\n")
} else {
  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/assumptions.csv", assumptions)
  append_csv("database/inputs.csv", inputs)
  append_csv("database/outputs.csv", outputs)
  replace_csv_row("discovery/candidates.csv", candidate_id, candidate)
  replace_csv_row(selected_path, candidate_id, selected_row)
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Imported the partial AFMA SESSF silver warehou source record.\n")
}
