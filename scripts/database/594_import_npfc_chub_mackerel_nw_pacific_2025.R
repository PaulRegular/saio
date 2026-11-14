source_id <- "npfc_chub_mackerel_nw_pacific_2025"
stock_id <- "npfc_chub_mackerel_nw_pacific"
candidate_id <- "NPFC:CM_NWPO"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.", call. = FALSE)
}

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

append_rows <- function(path, rows) {
  rows <- rows[, names(read_table(path)), drop = FALSE]
  rows[] <- lapply(rows, as.character)
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    last_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(last_byte, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

replace_csv_record <- function(path, key_field, key_value, row) {
  table <- read_table(path)
  if (!identical(names(row), names(table)) || nrow(row) != 1L) {
    stop("The replacement CSV record must match the table schema.", call. = FALSE)
  }
  record_index <- which(table[[key_field]] == key_value)
  if (length(record_index) != 1L) {
    stop("Expected exactly one CSV record to update.", call. = FALSE)
  }

  row_connection <- textConnection("serialized_row", open = "w", local = TRUE)
  write.table(row, row_connection, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "")
  close(row_connection)
  if (length(serialized_row) != 1L || grepl("[\r\n]", serialized_row)) {
    stop("The replacement record must fit on one CSV line.", call. = FALSE)
  }

  connection <- file(path, open = "rb")
  file_bytes <- readBin(connection, what = "raw", n = file.info(path)$size)
  close(connection)
  line_feeds <- which(file_bytes == as.raw(10L))
  physical_row <- record_index + 1L
  if (length(line_feeds) < physical_row) {
    stop("CSV row locations do not match the parsed table.", call. = FALSE)
  }
  start <- if (physical_row == 1L) 1L else line_feeds[physical_row - 1L] + 1L
  end <- line_feeds[physical_row] - 1L
  if (end >= start && identical(file_bytes[end], as.raw(13L))) end <- end - 1L
  prefix <- if (start > 1L) file_bytes[seq_len(start - 1L)] else raw()
  suffix_start <- end + 1L
  suffix <- if (suffix_start <= length(file_bytes)) {
    file_bytes[seq.int(suffix_start, length(file_bytes))]
  } else {
    raw()
  }
  connection <- file(path, open = "wb")
  writeBin(c(prefix, charToRaw(serialized_row), suffix), connection)
  close(connection)
}

manifest <- read_table("provenance/npfc_chub_mackerel_nw_pacific_2025_sources.csv")
cached_files <- manifest$local_file
if (any(!file.exists(cached_files))) {
  stop("Cached NPFC source documents are required before importing this record.",
    call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(cached_files)))
if (!identical(actual_hashes, toupper(manifest$sha256))) {
  stop("A cached NPFC source document does not match its recorded SHA-256 checksum.",
    call. = FALSE)
}

stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
assumptions_existing <- read_table("database/assumptions.csv")
inputs_existing <- read_table("database/inputs.csv")
outputs_existing <- read_table("database/outputs.csv")
candidates <- read_table("discovery/candidates.csv")

candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) {
  stop("Expected exactly one screened NPFC candidate row.", call. = FALSE)
}
if (stock_id %in% stocks$stock_id || source_id %in% assessments$assessment_id) {
  stop("The NPFC stock or assessment is already present; refusing duplicate import.",
    call. = FALSE)
}
if (any(c(assumptions_existing$assessment_id, inputs_existing$assessment_id,
  outputs_existing$assessment_id) == source_id)) {
  stop("The NPFC assessment already has canonical child rows.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "NPFC",
  authority_stock_id = NA_character_,
  scientific_name = "Scomber japonicus",
  common_name = "Northwest Pacific chub mackerel",
  area = "NPFC Convention Area and Member EEZs",
  region = "Northwest Pacific Ocean",
  ocean = "Northwest Pacific",
  notes = paste(
    "Joint NPFC assessment unit spanning the Convention Area and Member EEZs.",
    "No official stock code was identified in the reviewed sources.",
    "This unit is distinct from the NOAA-managed Pacific Coast chub mackerel unit."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

report_url <- "https://www.npfc.int/sites/default/files/2026-01/SC10%20Report.pdf"
input_url <- "https://www.npfc.int/system/files/2025-07/NPFC-2025-TWG%20CMSA11-WP03%20SuppDoc.1%20Input_data_presentation_0.pdf"
correction_url <- "https://www.npfc.int/system/files/2026-03/NPFC-2026-SC10-Final%20Report.pdf"
table_ref <- paste(
  "NPFC-2025-SC10-WP10; NPFC SC10 Report, Annex H, Table E-1, report p. 67"
)
model_ref <- "NPFC SC10 Report, Annex H, Section 4, report pp. 57-59"
config_ref <- "NPFC SC10 Report, Annex H, Annex 1 Table A2, report pp. 141-142"
region <- "Northwest Pacific Ocean"

assessment <- data.frame(
  assessment_id = source_id,
  stock_id = stock_id,
  assessment_year = "2025",
  terminal_year = "2023",
  estimate_terminal_year = "2024",
  assessment_type = "full_assessment",
  model_family = "SAM",
  model_version = "S02-Index24_1",
  is_current = "TRUE",
  is_applied = "TRUE",
  framework_year = NA_character_,
  assessment_url = report_url,
  framework_url = NA_character_,
  data_url = input_url,
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The 2025 base case uses catch data through FY2023 and estimates status at the start of FY2024.",
    "The 2026 SC10 report documents corrected FY2014-FY2017 catch-at-age and a rerun; it reports no change to reference points, but corrected input arrays and exact updated numeric outputs were not located.",
    "The published Table E-1 values are retained with that limitation."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

assumption <- function(component, setting, value, source_reference,
                       notes = "", survey = NA_character_) {
  data.frame(
    assessment_id = source_id,
    component = component,
    fleet = NA_character_,
    survey = survey,
    sex = NA_character_,
    region = region,
    season = NA_character_,
    setting = setting,
    value = value,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("model", "model_structure", "State-space age-structured SAM model.", model_ref),
  assumption("assessment", "base_case", "S02-Index24_1.", model_ref),
  assumption("population", "model_period", "FY1970-FY2023; fishing year runs July through June.", model_ref),
  assumption("population", "age_groups", "Ages 0-5 and 6+.", model_ref),
  assumption("population", "fleet_count", "One fleet.", config_ref,
    "Catch-at-age observations combine member-specific source data."),
  assumption("recruitment", "recruitment_age", "0", model_ref,
    "Recruitment is defined as numbers at age 0."),
  assumption("recruitment", "stock_recruitment_relationship", "Beverton-Holt; alpha and beta estimated.", config_ref),
  assumption("biology", "SSB_definition", "Sum of numbers-at-age multiplied by stock weight-at-age and maturity-at-age.", model_ref),
  assumption("F", "temporal_process", "Age-specific fishing mortality coefficients follow a multivariate random walk, allowing time-varying selectivity.", model_ref),
  assumption("F", "age_correlation", "Correlation follows rho raised to the absolute age difference.", config_ref),
  assumption("F", "process_sd_blocks", "Random-walk SDs estimated for ages 0-1, age 2, and ages 3+.", config_ref),
  assumption("N", "process_errors", "Process errors apply to numbers at ages older than age 0; the base case does not place a breakpoint between ages 2 and 3.", config_ref),
  assumption("observation", "catch_likelihood", "Observed catch-at-age is fitted with the Baranov catch equation under lognormal observation error.", model_ref),
  assumption("observation", "index_likelihood", "Abundance indices use lognormal observation errors, with separate observation-error terms among index series.", model_ref, config_ref),
  assumption("index", "series", paste(
    "Seven series: Japan summer age-0; Japan autumn age-0 and age-1; Japan egg-survey SSB;",
    "Japan dip-net SSB; China light purse-seine vulnerable biomass; and Russia trawl vulnerable biomass."
  ), model_ref),
  assumption("index", "nonlinear_relationship", "The nonlinear coefficient is estimated for the three Japanese age-specific indices and fixed to 1 for the other indices.", config_ref),
  assumption("index", "catchability_time_structure", "Index catchability is constant across years.", config_ref),
  assumption("index", "within_year_timing", "unknown", model_ref,
    "Index names identify survey season or fishery, but the model's within-year timing fractions were not found."),
  assumption("catch", "catch_at_age_construction", "Japanese domestic catch-at-age is used for FY1970-FY2013; quarterly member catch-at-length and age-length keys are combined for FY2014-FY2023.", model_ref,
    "Where Chinese or Russian age-length keys are unavailable, Eastern Japan age-length keys were substituted. The numerical series is shown in a figure, not tabulated."),
  assumption("biology", "weight_at_age", "Japanese domestic stock weights are used for FY1970-FY2013; FY2014-FY2023 values are weighted across members using catch-number proportions.", model_ref,
    "Quarterly weighted values are averaged within fishing year. The numerical series is shown in a figure, not tabulated."),
  assumption("biology", "maturity_at_age", "Annual Japanese domestic maturity-at-age for FY1970-FY2023, with decadal changes.", model_ref,
    "The numerical series is shown in a figure, not tabulated."),
  assumption("mortality", "natural_mortality", "Fixed age-specific annual M: 0.80, 0.60, 0.51, 0.46, 0.43, 0.41 and 0.40 for ages 0-5 and 6+.",
    "NPFC-2025-TWG CMSA11-WP03 Supplementary Document 1, slide 10"),
  assumption("assessment", "FY2024_scenario", "FY2024 indices from Japanese and Russian fisheries and Japanese surveys are included; FY2024 weight and maturity are FY2016-FY2023 means, and Russian catch share is the FY2021-FY2023 mean.", model_ref,
    "FY2024 catch is unavailable; the scenario estimates stock status at the start of FY2024."),
  assumption("reference_points", "Fcurrent_period", "unknown", table_ref,
    "The reference-point section describes Fcur as the FY2021-FY2023 average, while Annex 1 Table A1 describes the Fcur denominator as the FY2020-FY2023 average."),
  assumption("source", "corrected_catch_at_age_rerun", "A corrected rerun followed errors in FY2014-FY2017 catch-at-age; no change to reference points is reported.",
    "NPFC 2026 SC10 Final Report, paragraph 64",
    "The corrected NPFC input arrays and exact rerun outputs were not located.")
))

m_ages <- c(0L, 1L, 2L, 3L, 4L, 5L, 6L)
m_values <- c(0.80, 0.60, 0.51, 0.46, 0.43, 0.41, 0.40)
inputs <- data.frame(
  assessment_id = source_id,
  type = "M",
  measure = "natural_mortality_at_age",
  basis = "per_year",
  fleet = NA_character_,
  survey = NA_character_,
  sex = NA_character_,
  region = region,
  season = NA_character_,
  year = NA_character_,
  year_basis = NA_character_,
  age = as.character(m_ages),
  value = as.character(m_values),
  unit = "per year",
  sampling_time = NA_character_,
  source_type = "official_table",
  source_reference = "NPFC-2025-TWG CMSA11-WP03 Supplementary Document 1, slide 10",
  transformation = NA_character_,
  notes = c(
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1.",
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1.",
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1.",
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1.",
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1.",
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1.",
    "Fixed, time-invariant natural mortality used in base case S02-Index24_1; age 6 represents the 6+ group."
  ),
  observation_id = NA_character_,
  length_bin = NA_character_,
  length_bin_lower = NA_character_,
  length_bin_upper = NA_character_,
  sample_size = NA_character_,
  age_error = NA_character_,
  partition = NA_character_,
  weight_bin = NA_character_,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

output <- function(type, measure, value, unit, scenario, notes,
                   year = NA_character_) {
  data.frame(
    assessment_id = source_id,
    type = type,
    measure = measure,
    fleet = NA_character_,
    survey = NA_character_,
    sex = NA_character_,
    region = region,
    season = NA_character_,
    year = as.character(year),
    age = NA_character_,
    age_group = NA_character_,
    value = as.character(value),
    se = NA_character_,
    lwr = NA_character_,
    upr = NA_character_,
    unit = unit,
    source_type = "official_table",
    source_reference = table_ref,
    notes = notes,
    scenario = scenario,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

output_notes <- paste(
  "Source-reported Table E-1 value; no SE or interval is reported.",
  "The 2026 SC10 report documents corrected FY2014-FY2017 catch-at-age and states that reference points were unaffected; exact corrected outputs were not published in the reviewed sources."
)
f_metrics <- list(
  current_spawning_potential_ratio = c(16.2, 27.8),
  `F0.1_ratio_to_Fcurrent` = c(0.838, 0.838),
  `F30SPR_ratio_to_Fcurrent` = c(0.580, 0.911),
  `F40SPR_ratio_to_Fcurrent` = c(0.412, 0.609),
  `F50SPR_ratio_to_Fcurrent` = c(0.295, 0.416),
  `F60SPR_ratio_to_Fcurrent` = c(0.207, 0.282),
  `F70SPR_ratio_to_Fcurrent` = c(0.139, 0.184)
)
periods <- c(
  "S02-Index24_1; biological parameters FY2016-FY2023",
  "S02-Index24_1; biological parameters FY1970-FY2023"
)
outputs <- list()
for (measure in names(f_metrics)) {
  for (j in seq_along(periods)) {
    source_measure <- switch(measure,
      current_spawning_potential_ratio = "Current%SPR",
      `F0.1_ratio_to_Fcurrent` = "F0.1/Fcur",
      `F30SPR_ratio_to_Fcurrent` = "F30%SPR/Fcur",
      `F40SPR_ratio_to_Fcurrent` = "F40%SPR/Fcur",
      `F50SPR_ratio_to_Fcurrent` = "F50%SPR/Fcur",
      `F60SPR_ratio_to_Fcurrent` = "F60%SPR/Fcur",
      `F70SPR_ratio_to_Fcurrent` = "F70%SPR/Fcur"
    )
    period_note <- if (measure == "current_spawning_potential_ratio") {
      "Current%SPR is the source label; the report glossary defines current SPR relative to SPR0 using FY2021-FY2023."
    } else {
      "The report gives conflicting Fcur averaging periods in the reference-point text and Annex 1 glossary; the tabulated ratio is preserved as printed."
    }
    outputs[[length(outputs) + 1L]] <- output(
      "mortality",
      measure,
      f_metrics[[measure]][j],
      if (measure == "current_spawning_potential_ratio") "percent" else "ratio",
      periods[j],
      paste(output_notes, "Source measure:", source_measure, period_note)
    )
  }
}

recent_period <- "S02-Index24_1; biological parameters FY2016-FY2023"
outputs[[length(outputs) + 1L]] <- output(
  "biomass", "unfished_spawning_biomass", 1399, "thousand mt", recent_period,
  paste(output_notes, "Source measure: SSB_F=0_RECENT."))
reference_points <- data.frame(
  measure = c(
    "SSB_reference_point_25th_percentile",
    "SSB_reference_point_50th_percentile",
    "SSB_reference_point_70th_percentile"
  ),
  value = c(107, 289, 585),
  source_measure = c("SSB_LIM", "SSB_REFERENCE_A", "SSB_REFERENCE_B"),
  percentile = c(25, 50, 70),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(reference_points))) {
  outputs[[length(outputs) + 1L]] <- output(
    "biomass", reference_points$measure[i], reference_points$value[i],
    "thousand mt", recent_period,
    paste(output_notes, "Source measure:", reference_points$source_measure[i],
      "historical SSB percentile:", reference_points$percentile[i]))
}

status_ratios <- data.frame(
  measure = c(
    "SSB_ratio_to_25th_percentile_reference",
    "SSB_ratio_to_50th_percentile_reference",
    "SSB_ratio_to_70th_percentile_reference"
  ),
  value = c(1.23, 0.46, 0.23),
  source_measure = c("SSB2023/SSB_LIM", "SSB2023/SSB_REFERENCE_A", "SSB2023/SSB_REFERENCE_B"),
  percentile = c(25, 50, 70),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(status_ratios))) {
  outputs[[length(outputs) + 1L]] <- output(
    "biomass", status_ratios$measure[i], status_ratios$value[i], "ratio",
    "S02-Index24_1; FY2023 status; recent biological parameters",
    paste(output_notes, "Source measure:", status_ratios$source_measure[i],
      "historical SSB percentile:", status_ratios$percentile[i]),
    year = "2023")
}

unfished_ratios <- data.frame(
  measure = c(
    "SSB_25th_percentile_reference_to_unfished_SSB",
    "SSB_50th_percentile_reference_to_unfished_SSB",
    "SSB_70th_percentile_reference_to_unfished_SSB"
  ),
  value = c(0.08, 0.21, 0.42),
  source_measure = c("SSB_LIM/SSB_F=0_RECENT", "SSB_REFERENCE_A/SSB_F=0_RECENT", "SSB_REFERENCE_B/SSB_F=0_RECENT"),
  percentile = c(25, 50, 70),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(unfished_ratios))) {
  outputs[[length(outputs) + 1L]] <- output(
    "biomass", unfished_ratios$measure[i], unfished_ratios$value[i], "ratio",
    recent_period,
    paste(output_notes, "Source measure:", unfished_ratios$source_measure[i],
      "historical SSB percentile:", unfished_ratios$percentile[i]))
}
outputs <- do.call(rbind, outputs)

candidate <- candidates[candidate_row, , drop = FALSE]
if (candidate$eligibility != "unresolved" || candidate$match_status != "new") {
  stop("Candidate identity or screening status changed; review before importing.",
    call. = FALSE)
}

stopifnot(
  identical(names(stock), names(stocks)),
  identical(names(assessment), names(assessments)),
  identical(names(assumptions), names(assumptions_existing)),
  identical(names(inputs), names(inputs_existing)),
  identical(names(outputs), names(outputs_existing)),
  nrow(inputs) == 7L,
  nrow(outputs) == 24L
)
output_key <- do.call(paste, c(lapply(outputs[
  c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
    "season", "year", "age", "age_group", "scenario")
], function(x) ifelse(is.na(x), "", x)), sep = "\r"))
stopifnot(!anyDuplicated(output_key))

cat("Preflight passed:", nrow(inputs), "age-specific M inputs and",
  nrow(outputs), "Table E-1 outputs.\n")

if (write_mode) {
  append_rows("database/stocks.csv", stock)
  append_rows("database/assessments.csv", assessment)
  append_rows("database/assumptions.csv", assumptions)
  append_rows("database/inputs.csv", inputs)
  append_rows("database/outputs.csv", outputs)

  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  replace_csv_record("discovery/candidates.csv", "candidate_id", candidate_id,
    candidates[candidate_row, , drop = FALSE])

  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Imported", stock_id, "with", nrow(inputs), "age-specific M inputs and",
    nrow(outputs), "Table E-1 outputs.\n")
} else {
  cat("Dry run only; pass --write to append the canonical records.\n")
}
