root <- "."
cache_dir <- file.path(root, "source_cache", "nefsc_summer_flounder_2018")
pdf_path <- file.path(cache_dir, "assessment.pdf")
assessment_id <- "nefsc_summer_flounder_2018"
summary_id <- "nefsc_summer_flounder_2025"
stock_id <- "nefsc_summer_flounder"
report_url <- "https://repository.library.noaa.gov/view/noaa/23031/noaa_23031_DS1.pdf"
summary_url <- "https://asmfc.org/wp-content/uploads/2025/08/SF_Management_Track_Assessment_2025.pdf"

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to import the cached 66th SAW report tables.", call. = FALSE)
}
if (!file.exists(pdf_path)) stop("The cached 2018 assessment PDF is missing.", call. = FALSE)

db <- file.path(root, "database")
stocks_path <- file.path(db, "stocks.csv")
assessments_path <- file.path(db, "assessments.csv")
assumptions_path <- file.path(db, "assumptions.csv")
inputs_path <- file.path(db, "inputs.csv")
outputs_path <- file.path(db, "outputs.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, check.names = FALSE)
if (stock_id %in% stocks$stock_id || any(assessments$assessment_id %in% c(assessment_id, summary_id))) {
  stop("Summer flounder records already exist in the database.", call. = FALSE)
}

pages <- pdftools::pdf_text(pdf_path)
page_text <- function(id, caption) {
  base <- which(grepl(caption, pages, perl = TRUE))
  continued <- which(grepl(paste0(
    "(?m)^\\s*Table ", id,
    " (continued|contd)[.]"
  ), pages, perl = TRUE))
  selected <- sort(unique(c(base, continued)))
  if (!length(base) || !length(selected)) {
    stop("Could not locate Table ", id, " in the cached report.", call. = FALSE)
  }
  selected_lines <- lapply(selected, function(page) {
    lines <- strsplit(pages[[page]], "\\n", perl = TRUE)[[1L]]
    start <- grep(paste0("^\\s*Table ", id, "([.]| (continued|contd)[.])"),
      lines,
      perl = TRUE
    )
    if (!length(start)) stop("Could not locate Table ", id, " caption on PDF page ", page, ".")
    start <- start[[1L]]
    following <- grep("^\\s*Table A[0-9]+[.]", lines, perl = TRUE)
    following <- following[following > start]
    end <- if (length(following)) min(following) - 1L else length(lines)
    lines[seq.int(start, end)]
  })
  unlist(selected_lines, use.names = FALSE)
}
year_rows <- function(lines, table_id, fields, years) {
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    fields_in_row <- strsplit(gsub(",", "", trimws(line)), "[[:space:]]+",
      perl = TRUE
    )[[1L]]
    values <- suppressWarnings(as.numeric(fields_in_row))
    if (!length(values) || is.na(values[[1L]]) || !values[[1L]] %in% years) {
      return(NULL)
    }
    if (length(values) != fields || anyNA(values)) {
      stop("Unexpected row width in Table ", table_id, ": ", trimws(line),
        call. = FALSE
      )
    }
    values
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) stop("No year rows found in Table ", table_id, ".", call. = FALSE)
  values <- do.call(rbind, rows)
  if (anyDuplicated(values[, 1L]) || !setequal(values[, 1L], years)) {
    stop("Unexpected year coverage in Table ", table_id, ".", call. = FALSE)
  }
  values[match(years, values[, 1L]), , drop = FALSE]
}
age_table <- function(id, caption, fields, years) {
  year_rows(page_text(id, caption), id, fields, years)
}
collapse_to_model_ages <- function(x) {
  cbind(x[, 1L], x[, 2:8, drop = FALSE], rowSums(x[, 9:12, drop = FALSE]))
}
age_index_table <- function(id, caption, years) {
  lines <- page_text(id, caption)
  headers <- grep("^\\s*(19|20)[0-9]{2}\\s+0\\s+1\\s+2\\s+", lines, perl = TRUE)
  rows <- lapply(headers, function(i) {
    header <- strsplit(trimws(lines[[i]]), "[[:space:]]+", perl = TRUE)[[1L]]
    year <- as.integer(header[[1L]])
    if (!year %in% years) {
      return(NULL)
    }
    following <- seq.int(i + 1L, min(length(lines), i + 3L))
    big <- following[grepl("^\\s*BIG\\s+", lines[following], perl = TRUE)]
    if (length(big) != 1L) stop("Could not find the Bigelow row for ", year, " in Table ", id, ".", call. = FALSE)
    fields <- strsplit(gsub(",", "", trimws(lines[[big]])), "[[:space:]]+", perl = TRUE)[[1L]]
    values <- suppressWarnings(as.numeric(fields[-1L]))
    if (length(values) != 9L || anyNA(values)) {
      stop("Unexpected Bigelow row in Table ", id, ": ", trimws(lines[[big]]), call. = FALSE)
    }
    c(year, values[1:8])
  })
  rows <- Filter(Negate(is.null), rows)
  values <- do.call(rbind, rows)
  if (!setequal(values[, 1L], years) || anyDuplicated(values[, 1L])) {
    stop("Unexpected Bigelow years in Table ", id, ".", call. = FALSE)
  }
  values[match(years, values[, 1L]), , drop = FALSE]
}

years <- 1982:2017
catch_a3 <- age_table("A3", "(?m)^\\s*Table A3[.] Commercial fishery landings at age", 13L, years)
catch_a6 <- age_table("A6", "(?m)^\\s*Table A6[.] Commercial fishery landings at age", 13L, years)
catch_a10 <- age_table("A10", "(?m)^\\s*Table A10[.] Estimated commercial fishery discards at age", 13L, years)
catch_a23 <- age_table("A23", "(?m)^\\s*Table A23[.] Estimated recreational landings at age", 13L, years)
catch_a28 <- age_table("A28", "(?m)^\\s*Table A28[.] Estimated recreational fishery discards at age", 13L, years)
catch_a32 <- age_table("A32", "(?m)^\\s*Table A32[.] Total catch at age of summer flounder", 14L, years)

catch_by_fleet <- list(
  "Commercial landings" = collapse_to_model_ages(cbind(catch_a3[, 1L], catch_a3[, 2:12] + catch_a6[, 2:12]))[, -1L, drop = FALSE],
  "Commercial discards" = collapse_to_model_ages(catch_a10)[, -1L, drop = FALSE],
  "Recreational landings" = collapse_to_model_ages(catch_a23)[, -1L, drop = FALSE],
  "Recreational discards" = collapse_to_model_ages(catch_a28)[, -1L, drop = FALSE]
)
catch_sum <- Reduce(`+`, catch_by_fleet)
published_total <- cbind(catch_a32[, 1L], catch_a32[, 2:8, drop = FALSE], catch_a32[, 14L])
catch_age_difference <- catch_sum - published_total[, -1L, drop = FALSE]
max_catch_age_difference <- max(abs(catch_age_difference))
if (max(abs(rowSums(catch_a32[, 2:12, drop = FALSE]) - catch_a32[, 13L])) > 5) {
  stop("Published total catch-at-age rows do not reconcile with their reported totals.", call. = FALSE)
}

input_rows <- list()
add_age_input <- function(type, measure, basis, fleet, survey, years, ages, values,
                          unit, reference, source_type = "official_table", notes = "",
                          transformation = "") {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(t(values))
  if (nrow(grid) != length(values)) stop("Input value dimensions do not match years and ages.")
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = "", season = "",
    year = grid$year, year_basis = "calendar_year", age = grid$age,
    value = grid$value, unit = unit, sampling_time = NA_real_,
    source_type = source_type, source_reference = reference,
    transformation = transformation,
    notes = notes, observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = NA_real_, partition = NA_real_, stringsAsFactors = FALSE
  )
}
model_ages <- 0:7
for (fleet in names(catch_by_fleet)) {
  table_ref <- switch(fleet,
    "Commercial landings" = "Tables A3 and A6, report pp. 124-125 and 129-130",
    "Commercial discards" = "Table A10, report pp. 137-138",
    "Recreational landings" = "Table A23, report pp. 156-157",
    "Recreational discards" = "Table A28, report pp. 163-164"
  )
  input_rows[[length(input_rows) + 1L]] <- add_age_input(
    "catch", "numbers_at_age", "numbers", fleet, "", years, model_ages,
    catch_by_fleet[[fleet]], "thousand fish", paste0("66th SAW 2018 assessment, ", table_ref),
    "reconstructed_source_input",
    "The published fleet tables give ages 0-10; ages 7-10 are summed to the official model's 7+ group.",
    if (fleet == "Commercial landings") {
      "Sum Maine-Virginia and North Carolina commercial landings within year and age; sum ages 7-10 to 7+."
    } else {
      "Sum source ages 7-10 to the official model's 7+ group."
    }
  )
}
input_rows[[length(input_rows) + 1L]] <- add_age_input(
  "catch", "numbers_at_age", "numbers", "Published total", "", years, model_ages,
  published_total[, 2:9, drop = FALSE], "thousand fish",
  "66th SAW 2018 assessment, Table A32, report pp. 171-172", "official_table",
  "Published aggregate catch-at-age retained separately from fleet series. It is not an additional fleet. The report's fleet age series do not add to this table at every age-year cell, so both source forms are preserved.",
  "Retain published ages 0-6 and the table's explicit 7+ total."
)

spring_years <- 2009:2017
fall_years <- 2009:2016
spring_index <- age_index_table("A40", "(?m)^\\s*Table A40[.] Northeast Fisheries Science Center", spring_years)
fall_index <- age_index_table("A41", "(?m)^\\s*Table A41[.] Northeast Fisheries Science Center", fall_years)
add_survey_index <- function(x, survey, times, table_id, report_pages) {
  rows <- expand.grid(year = x[, 1L], age = model_ages)
  rows$value <- as.vector(t(x[, 2:9, drop = FALSE]))
  rows$sampling_time <- times
  rows$survey <- survey
  rows$source_reference <- paste0(
    "66th SAW 2018 assessment, Table ", table_id,
    ", report pp. ", report_pages
  )
  rows
}
survey_rows <- rbind(
  add_survey_index(spring_index, "NEFSC Bigelow spring trawl", 0.25, "A40", "183-185"),
  add_survey_index(fall_index, "NEFSC Bigelow fall trawl", 0.75, "A41", "185-186")
)
input_rows[[length(input_rows) + 1L]] <- data.frame(
  assessment_id = assessment_id, type = "index", measure = "numbers_at_age",
  basis = "index_scale", fleet = "", survey = survey_rows$survey, sex = "",
  region = "", season = ifelse(grepl("spring", survey_rows$survey), "spring", "fall"),
  year = survey_rows$year, year_basis = "calendar_year", age = survey_rows$age,
  value = survey_rows$value, unit = "fish per tow", sampling_time = survey_rows$sampling_time,
  source_type = "official_table", source_reference = survey_rows$source_reference,
  transformation = "Use published Bigelow index-at-age row; the table reports the 7+ group directly.",
  notes = "The season midpoint is used as a timing approximation (0.25 spring; 0.75 fall). The official assessment also used additional indices not imported here.",
  observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
  length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
  partition = NA_real_, stringsAsFactors = FALSE
)

maturity <- age_table("A86", "(?m)^\\s*Table A86[.] Summer flounder estimated maturity at age", 9L, 1982:2016)
maturity_grid <- expand.grid(year = 1982:2016, age = model_ages)
maturity_grid$value <- as.vector(t(maturity[, 2:9, drop = FALSE]))
maturity_rows <- data.frame(
  assessment_id = assessment_id, type = "maturity", measure = "maturity_at_age",
  basis = "proportion", fleet = "", survey = "", sex = "", region = "", season = "",
  year = maturity_grid$year, year_basis = "calendar_year", age = maturity_grid$age,
  value = maturity_grid$value, unit = "proportion mature", sampling_time = NA_real_,
  source_type = "official_table",
  source_reference = "66th SAW 2018 assessment, Table A86, report p. 237",
  transformation = "", notes = "Sexes-combined three-year moving-window ogive; the report says the input series ends in 2016 because 2017 fall maturity data were unavailable.",
  observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
  length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
  partition = NA_real_, stringsAsFactors = FALSE
)
input_rows[[length(input_rows) + 1L]] <- maturity_rows

ssb_weights <- c(0.201, 0.431, 0.693, 0.895, 1.137, 1.413, 1.758, 1.964)
ssb_weight_rows <- data.frame(
  assessment_id = assessment_id, type = "weight", measure = "weight_at_age",
  basis = "kg_per_fish", fleet = "", survey = "", sex = "", region = "",
  season = "", year = NA_real_, year_basis = "", age = model_ages,
  value = ssb_weights, unit = "kg per fish", sampling_time = NA_real_,
  source_type = "official_table",
  source_reference = "66th SAW 2018 assessment, Table A90, report p. 241",
  transformation = "Use the published November spawning-stock-biomass weights at age.",
  notes = "These are 2013-2017 mean SSB weights, not annual historical stock weights. The tinyAM translation treats this published reference-period schedule as constant across its fitted years.",
  observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
  length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
  partition = NA_real_, stringsAsFactors = FALSE
)
input_rows[[length(input_rows) + 1L]] <- ssb_weight_rows

M_at_age <- c(0.26, 0.26, 0.26, 0.25, 0.25, 0.25, 0.25, 0.24)
M_rows <- data.frame(
  assessment_id = assessment_id, type = "M", measure = "natural_mortality_at_age",
  basis = "per_year", fleet = "", survey = "", sex = "", region = "", season = "",
  year = NA_real_, year_basis = "", age = model_ages, value = M_at_age,
  unit = "per year", sampling_time = NA_real_, source_type = "official_table",
  source_reference = "66th SAW 2018 assessment, pp. 64-65 and Table A90, report pp. 240-241",
  transformation = "", notes = "Fixed age-specific M schedule, ages 0-7+; the official-model schedule averages 0.25 per year.",
  observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
  length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
  partition = NA_real_, stringsAsFactors = FALSE
)
input_rows[[length(input_rows) + 1L]] <- M_rows
inputs_add <- do.call(rbind, input_rows)

ssb <- age_table("A87", "(?m)^\\s*Table A87[.] 2018 SAW-66 assessment summary results", 4L, years)
f_at_age <- age_table("A88", "(?m)^\\s*Table A88[.] 2018 SAW-66 assessment fishing mortality", 9L, years)
n_at_age <- age_table("A89", "(?m)^\\s*Table A89[.] 2018 SAW-66 assessment January 1 population number", 10L, years)
output_rows <- list()
add_age_output <- function(type, measure, ages, values, unit, reference, plus_age = max(ages), notes = "") {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(t(values))
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = grid$year,
    age = grid$age, age_group = ifelse(grid$age == plus_age, paste0(plus_age, "+"), ""),
    value = grid$value, se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "official_table", source_reference = reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
output_rows[[1L]] <- add_age_output(
  "population", "numbers_at_age", model_ages, n_at_age[, 2:9, drop = FALSE],
  "thousand fish", "66th SAW 2018 assessment, Table A89, report p. 240",
  notes = "F2018_BASE_V2 January 1 population estimates; age 7 is the 7+ group."
)
output_rows[[2L]] <- add_age_output(
  "mortality", "fishing_mortality_at_age", model_ages, f_at_age[, 2:9, drop = FALSE],
  "per year", "66th SAW 2018 assessment, Table A88, report p. 239",
  notes = "F2018_BASE_V2 estimates; age 7 is the 7+ group."
)
output_rows[[3L]] <- data.frame(
  assessment_id = assessment_id, type = "biomass", measure = "SSB", fleet = "",
  survey = "", sex = "", region = "", season = "", year = ssb[, 1L],
  age = NA_real_, age_group = "", value = ssb[, 2L], se = NA_real_,
  lwr = NA_real_, upr = NA_real_, unit = "metric tons", source_type = "official_table",
  source_reference = "66th SAW 2018 assessment, Table A87, report p. 238",
  notes = "F2018_BASE_V2 point estimates. The report separately presents terminal-year 90% MCMC intervals; they are not paired with these point estimates.",
  stringsAsFactors = FALSE
)
output_rows[[4L]] <- data.frame(
  assessment_id = assessment_id, type = "recruitment", measure = "recruitment",
  fleet = "", survey = "", sex = "", region = "", season = "", year = ssb[, 1L],
  age = 0L, age_group = "", value = ssb[, 3L], se = NA_real_, lwr = NA_real_,
  upr = NA_real_, unit = "thousand fish", source_type = "official_table",
  source_reference = "66th SAW 2018 assessment, Table A87, report p. 238",
  notes = "Recruitment is reported at true age 0.", stringsAsFactors = FALSE
)
outputs_add <- do.call(rbind, output_rows)
largest_catch_difference <- which(abs(catch_age_difference) == max_catch_age_difference,
  arr.ind = TRUE
)[1L, ]
catch_difference_note <- paste0(
  "The largest absolute difference is ", format(max_catch_age_difference, trim = TRUE),
  " thousand fish at year ", years[largest_catch_difference[[1L]]],
  ", age group ", c(0:6, "7+")[largest_catch_difference[[2L]]],
  ". Annual fleet totals are close to the published aggregate; age cells are not silently reconciled."
)

stock_add <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NEFSC",
  authority_stock_id = "Summer flounder, Maine-North Carolina management unit",
  scientific_name = "Paralichthys dentatus", common_name = "Summer flounder",
  area = "Maine to North Carolina", region = "Northwest Atlantic", ocean = "Northwest Atlantic",
  notes = "The official 2018 model covers the Maine-North Carolina stock unit; current advice uses a newer summary-only update.",
  stringsAsFactors = FALSE
)
assessment_add <- data.frame(
  assessment_id = c(assessment_id, summary_id), stock_id = stock_id,
  assessment_year = c(2018, 2025), terminal_year = c(2017, 2024),
  estimate_terminal_year = c(2017, 2024),
  assessment_type = c("benchmark", "management_track_update"),
  model_family = c("ASAP", "ASAP"),
  model_version = c("F2018_BASE_V2", "2025 Management Track; detailed run files unavailable"),
  is_current = c("TRUE", "FALSE"), is_applied = c("TRUE", "TRUE"),
  framework_year = c(2018, 2018), assessment_url = c(report_url, summary_url),
  framework_url = c(report_url, ""), data_url = c("", ""), model_url = c("", ""),
  repository_url = c("", ""), assumptions_status = c("partial", "partial"),
  inputs_status = c("partial", "partial"), outputs_status = c("partial", "partial"),
  notes = c(
    "Most recent official assessment with recoverable numerical age-specific input and output tables. Official model is ASAP F2018_BASE_V2 through 2017. The newer 2025 management-track update is recorded separately; no 2025-run ages or inputs are substituted.",
    "Most recent official assessment and basis for current advice, using data through 2024. Public SASINF and assessment materials provide summary/diagnostic outputs but no age-specific source inputs or fitted age surfaces; this is not the current detailed database record."
  ), stringsAsFactors = FALSE
)
assumptions_add <- data.frame(
  assessment_id = assessment_id, component = c("assessment", "population", "catch", "catch", "catch", "index", "M", "maturity", "F", "uncertainty"),
  fleet = rep("", 10L),
  survey = c(rep("", 4L), "NEFSC spring and fall", rep("", 5L)),
  sex = c(rep("", 6L), "combined", rep("", 3L)),
  region = rep("", 10L),
  season = c(rep("", 4L), "spring and fall", rep("", 5L)),
  setting = c("selected_model", "age_structure", "fleet_structure", "catch_age_grouping", "catch_age_reconciliation", "index_set", "natural_mortality", "maturity_schedule", "fully_recruited_age", "uncertainty"),
  value = c(
    "F2018_BASE_V2", "Combined sexes; ages 0-7+; recruitment at true age 0",
    "Four fleets: commercial landings, commercial discards, recreational landings, recreational discards",
    "The official model uses a 7+ terminal group; the report's fleet tables give ages 0-10",
    paste0("Fleet and published aggregate catch-at-age are retained separately; maximum cell difference is ", format(max_catch_age_difference, trim = TRUE), " thousand fish"),
    "The official run retained all available survey indices; only the NEFSC Bigelow spring/fall age series are transcribed here",
    "Fixed, age-specific, time-invariant M; ages 0-7+ are 0.26, 0.26, 0.26, 0.25, 0.25, 0.25, 0.25, 0.24 per year",
    "Sexes-combined, three-year moving-window ogive based on NEFSC fall survey data; updated through 2016",
    "Peak/fully recruited F is reported at true age 4",
    "The report includes terminal-year MCMC intervals for SSB and F, but no matched age-specific uncertainty table was recovered"
  ),
  source_reference = c(
    "66th SAW 2018 assessment, pp. 88-90 and Tables A87-A89",
    "66th SAW 2018 assessment, Tables A88-A89",
    "66th SAW 2018 assessment, pp. 82-89",
    "66th SAW 2018 assessment, Tables A3, A6, A10, A23, A28, A32 and A88-A89",
    "66th SAW 2018 assessment, Tables A3, A6, A10, A23, A28 and A32",
    "66th SAW 2018 assessment, pp. 88-89 and Tables A40-A41",
    "66th SAW 2018 assessment, pp. 64-65 and Table A90",
    "66th SAW 2018 assessment, Table A86 and p. 74",
    "66th SAW 2018 assessment, Table A87",
    "66th SAW 2018 assessment, p. 90"
  ),
  notes = c(
    "The assessment was adopted for management advice after SAW-66 review.",
    "Age 7 represents the 7+ group in official model outputs.",
    "The official model fits separate fleet totals and age compositions.",
    "Ages 7-10 are summed to the official model's 7+ group; commercial Maine-Virginia and North Carolina landings are summed for the commercial-landings fleet.",
    catch_difference_note,
    "The report includes many additional state, university, and NEFSC indices that are not included in the canonical rows extracted for this comparison.",
    "The age schedule averages 0.25 per year. It is fixed across time.",
    "No 2017 fall maturity data were available; the source report does not tabulate a 2017 maturity row.",
    "The model's F surface is also reported by age in Table A88.",
    "Available terminal-year MCMC intervals are 90%; they are not attached to the separate point estimates in outputs.csv."
  ), stringsAsFactors = FALSE
)
assumptions_add <- rbind(assumptions_add, data.frame(
  assessment_id = assessment_id, component = "biology", fleet = "",
  survey = "", sex = "combined", region = "", season = "",
  setting = "spawning_weight_schedule",
  value = "2013-2017 mean November SSB weights at age, ages 0-7+",
  source_reference = "66th SAW 2018 assessment, Table A90, report p. 241",
  notes = "The values are preserved as a static source schedule for tinyAM because an annual SSB-weight surface is not transcribed from the assessment report.",
  stringsAsFactors = FALSE
))

read_db <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
append_rows <- function(path, rows) {
  columns <- names(read_db(path))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", basename(path), call. = FALSE)
  utils::write.table(rows[columns], path,
    sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}
if (nrow(inputs_add) != 1872L || nrow(outputs_add) != 648L ||
  any(!is.finite(inputs_add$value)) || any(!is.finite(outputs_add$value)) ||
  any(inputs_add$value < 0) || any(outputs_add$value < 0) ||
  !isTRUE(all.equal(as.numeric(M_rows$value), M_at_age)) ||
  !isTRUE(all.equal(as.numeric(ssb_weight_rows$value), ssb_weights))) {
  stop("Summer flounder records failed dimensional or value checks.", call. = FALSE)
}
if (tail(ssb[, 2L], 1L) != 44552 || tail(ssb[, 3L], 1L) != 42415 ||
  tail(ssb[, 4L], 1L) != 0.334) {
  stop("Terminal-year F2018_BASE_V2 values do not match Table A87.", call. = FALSE)
}

append_rows(stocks_path, stock_add)
append_rows(assessments_path, assessment_add)
append_rows(assumptions_path, assumptions_add)
append_rows(inputs_path, inputs_add)
append_rows(outputs_path, outputs_add)
cat("Imported the detailed 2018 summer flounder record and registered the 2025 summary-only update: ",
  nrow(inputs_add), " inputs and ", nrow(outputs_add), " outputs.\n",
  sep = ""
)
