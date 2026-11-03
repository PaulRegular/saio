assessment_id <- "ices_sole_eastern_channel_7d_2026"
stock_id <- "ck_ices_wgnssk_solea_ns_7d"
database_dir <- file.path("database")
source_dir <- file.path("source_cache", "ices_sole_7d_2026")
report_file <- file.path(source_dir, "wgnssk_2026.pdf")
xml_file <- file.path(source_dir, "ICES_SAG_StockXml_22546.xml")
report_ref <- "https://doi.org/10.17895/ices.pub.32676345"
sag_ref <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22546"
annex_ref <- "https://ices-library.figshare.com/articles/report/Stock_Annex_Sole_Solea_solea_in_Division_7_d_eastern_English_Channel_/18623249?file=33402290"
repository_ref <- "https://github.com/ices-advice/2026_sol.27.7d/tree/468baf44b275c47923b0485cd67d86beb59a4b39/2026_sol.27.7d_assessment"
years <- 1982:2025
ages <- 1:11

if (!requireNamespace("pdftools", quietly = TRUE)) {
  cli::cli_abort("Install pdftools before importing this ICES assessment.")
}
if (!all(file.exists(c(report_file, xml_file)))) {
  cli::cli_abort("Cache the pinned WGNSSK report and ICES SAG XML before importing.")
}

read_table <- function(name, nrows = Inf) {
  utils::read.csv(
    file.path(database_dir, name), nrows = nrows,
    colClasses = "character", na.strings = "", check.names = FALSE,
    stringsAsFactors = FALSE
  )
}
format_value <- function(x) {
  out <- rep("", length(x))
  ok <- is.finite(x)
  out[ok] <- format(x[ok], digits = 15, scientific = FALSE, trim = TRUE)
  out
}
numeric_cells <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  x <- gsub("\\*+$", "", x)
  x[x %in% c("-", "/", "NA", "N/A")] <- NA_character_
  suppressWarnings(as.numeric(x))
}

pdf_lines <- unlist(strsplit(pdftools::pdf_text(report_file), "\n", fixed = TRUE), use.names = FALSE)
table_headings <- grep("^\\s*Table 17\\.[0-9]+[a-z]?\\. Sole in Division 7\\.d\\.", pdf_lines, perl = TRUE)
table_block <- function(number) {
  target <- grep(
    paste0("^\\s*Table 17\\.", number, "\\. Sole in Division 7\\.d\\."),
    pdf_lines, perl = TRUE
  )
  if (length(target) != 1L) {
    cli::cli_abort("Could not uniquely locate Table 17.{number} in the pinned ICES report.")
  }
  following <- table_headings[table_headings > target]
  last <- if (length(following)) following[[1L]] - 1L else length(pdf_lines)
  pdf_lines[seq.int(target, last)]
}
table_cells <- function(line) {
  strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
}

parse_age_table <- function(number) {
  current_years <- NULL
  rows <- list()
  expected <- expand.grid(year = years, age = ages)
  expected_key <- paste(expected$year, expected$age)
  for (line in table_block(number)) {
    cells <- table_cells(line)
    if (length(cells) >= 3L && tolower(cells[[1L]]) == "age" &&
      all(grepl("^(19|20)[0-9]{2}$", cells[-1L]))) {
      current_years <- as.integer(cells[-1L])
      next
    }
    if (is.null(current_years) || length(cells) != length(current_years) + 1L ||
      !grepl("^[0-9]+\\+?$", cells[[1L]])) next
    age <- as.integer(sub("\\+$", "", cells[[1L]]))
    if (!age %in% ages) next
    values <- numeric_cells(cells[-1L])
    if (any(!is.finite(values)) || !all(current_years %in% years)) next
    rows[[length(rows) + 1L]] <- data.frame(
      year = current_years, age = age, value = values
    )
    parsed <- do.call(rbind, rows)
    if (nrow(parsed) == length(years) * length(ages) &&
      setequal(paste(parsed$year, parsed$age), expected_key)) {
      break
    }
  }
  if (!length(rows)) cli::cli_abort("No age rows parsed from Table 17.{number}.")
  out <- do.call(rbind, rows)
  key <- paste(out$year, out$age)
  if (anyDuplicated(key) || !setequal(key, expected_key)) {
    cli::cli_abort("Table 17.{number} does not cover each 1982-2025 year and age 1-11 exactly once.")
  }
  out[order(out$year, out$age), , drop = FALSE]
}

parse_index_table <- function(number, age_values, survey) {
  rows <- list()
  efforts <- list()
  for (line in table_block(number)) {
    cells <- table_cells(line)
    if (!length(cells) || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    year <- as.integer(cells[[1L]])
    if (length(cells) < 2L) next
    effort <- numeric_cells(cells[[2L]])
    if (length(effort) != 1L || !is.finite(effort)) next
    efforts[[length(efforts) + 1L]] <- data.frame(year = year, value = effort)
    values <- numeric_cells(cells[-c(1L, 2L)])
    if (length(values) != length(age_values)) next
    available <- is.finite(values)
    if (any(available)) {
      rows[[length(rows) + 1L]] <- data.frame(
        year = year, age = age_values[available], value = values[available],
        survey = survey
      )
    }
  }
  if (!length(rows)) cli::cli_abort("No observations parsed from Table 17.{number}.")
  list(rows = do.call(rbind, rows), effort = do.call(rbind, efforts))
}

parse_commercial_index <- function(number, fleet, expected_years) {
  rows <- list()
  for (line in table_block(number)) {
    cells <- table_cells(line)
    if (length(cells) != 3L || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    values <- numeric_cells(cells[-1L])
    if (any(!is.finite(values))) next
    rows[[length(rows) + 1L]] <- data.frame(
      year = as.integer(cells[[1L]]), effort = values[[1L]],
      value = values[[2L]], fleet = fleet
    )
  }
  if (!length(rows)) cli::cli_abort("No observations parsed from Table 17.{number}.")
  out <- do.call(rbind, rows)
  if (!identical(out$year, expected_years) || any(out$effort != 1)) {
    cli::cli_abort("Unexpected years or effort values in Table 17.{number}.")
  }
  out
}

parse_summary <- function() {
  rows <- list()
  forecast <- NULL
  for (line in table_block(16)) {
    cells <- table_cells(line)
    if (!length(cells) || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    year <- as.integer(cells[[1L]])
    if (!year %in% 1982:2026) next
    values <- numeric_cells(cells[-1L])
    if (year <= 2025L && length(values) == 11L && all(is.finite(values))) {
      rows[[length(rows) + 1L]] <- data.frame(
        year = year, recruitment_low = values[[1L]],
        recruitment = values[[2L]], recruitment_high = values[[3L]],
        SSB_low = values[[4L]], SSB = values[[5L]], SSB_high = values[[6L]],
        landings = values[[7L]], discards = values[[8L]],
        Fbar_low = values[[9L]], Fbar = values[[10L]], Fbar_high = values[[11L]]
      )
    } else if (year == 2026L && length(values) == 4L && all(is.finite(values))) {
      forecast <- data.frame(
        year = 2026L, recruitment_low = NA_real_, recruitment = values[[1L]],
        recruitment_high = NA_real_, SSB_low = values[[2L]], SSB = values[[3L]],
        SSB_high = values[[4L]], landings = NA_real_, discards = NA_real_,
        Fbar_low = NA_real_, Fbar = NA_real_, Fbar_high = NA_real_
      )
    }
  }
  if (length(rows) != length(years) || !identical(vapply(rows, `[[`, integer(1), "year"), years)) {
    cli::cli_abort("Table 17.16 did not yield one complete summary row for 1982-2025.")
  }
  list(historical = do.call(rbind, rows), forecast = forecast)
}

parse_sag <- function() {
  xml <- paste(readLines(xml_file, warn = FALSE, encoding = "UTF-8"), collapse = "")
  blocks <- regmatches(xml, gregexpr("<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
  if (!length(blocks)) cli::cli_abort("No fish-year records were parsed from the ICES SAG XML.")
  get_value <- function(block, tag) {
    pattern <- paste0("<", tag, ">(.*?)</", tag, ">")
    value <- regmatches(block, regexpr(pattern, block, perl = TRUE))
    if (!length(value) || !nzchar(value)) return(NA_real_)
    value <- sub(pattern, "\\1", value, perl = TRUE)
    if (!nzchar(value)) NA_real_ else as.numeric(value)
  }
  out <- as.data.frame(do.call(rbind, lapply(blocks, function(block) c(
    year = get_value(block, "Year"), recruitment = get_value(block, "Recruitment"),
    SSB = get_value(block, "StockSize"), Fbar = get_value(block, "FishingPressure")
  ))), stringsAsFactors = FALSE)
  out$year <- as.integer(out$year)
  out
}

catch <- parse_age_table(4)
catch_weight <- parse_age_table(5)
stock_weight <- parse_age_table(6)
n_at_age <- parse_age_table(17)
f_at_age <- parse_age_table(18)
ssb_at_age <- parse_age_table(19)
summary <- parse_summary()
commercial <- list(
  parse_commercial_index(7, "BE-CBT-LPUE", 2004:2025),
  parse_commercial_index(8, "FR-COTB-LPUE", 2005:2025),
  parse_commercial_index(9, "UK(E&W)-CBT-LPUE", 1986:2025)
)
names(commercial) <- c("BE-CBT-LPUE", "FR-COTB-LPUE", "UK(E&W)-CBT-LPUE")
survey <- list(
  parse_index_table(10, 1:6, "UK(E&W)-BTS-Q3"),
  parse_index_table(11, 1, "UK(E&W)-YFS"),
  parse_index_table(12, 1, "FR-YFS")
)
names(survey) <- c("UK(E&W)-BTS-Q3", "UK(E&W)-YFS", "FR-YFS")
if (!identical(sort(unique(survey[[1L]]$rows$year)), c(1989:2021, 2023:2025)) ||
  !identical(sort(unique(survey[[2L]]$rows$year)), 1987:2006) ||
  !identical(sort(unique(survey[[3L]]$rows$year)), 1987:2023)) {
  cli::cli_abort("Unexpected survey-year coverage in Tables 17.10-17.12.")
}
if (any(!is.finite(catch$value)) || any(catch$value < 0) ||
  any(!is.finite(catch_weight$value)) || any(catch_weight$value < 0) ||
  any(!is.finite(stock_weight$value)) || any(stock_weight$value <= 0) ||
  any(!is.finite(n_at_age$value)) || any(n_at_age$value <= 0) ||
  any(!is.finite(f_at_age$value)) || any(f_at_age$value < 0) ||
  any(!is.finite(ssb_at_age$value)) || any(ssb_at_age$value < 0)) {
  cli::cli_abort("An age table contains an invalid value.")
}

summary_history <- summary$historical
summary_forecast <- summary$forecast
sag <- parse_sag()
sag_history <- sag[match(years, sag$year), , drop = FALSE]
if (!identical(sag$year, 1982:2026) ||
  any(!is.finite(sag_history$recruitment)) || any(!is.finite(sag_history$SSB)) ||
  any(!is.finite(sag_history$Fbar)) ||
  any(round(sag_history$recruitment) != round(summary_history$recruitment)) ||
  any(round(sag_history$SSB) != round(summary_history$SSB)) ||
  any(round(sag_history$Fbar, 2) != round(summary_history$Fbar, 2)) ||
  round(sag$recruitment[sag$year == 2026L]) != round(summary_forecast$recruitment) ||
  round(sag$SSB[sag$year == 2026L]) != round(summary_forecast$SSB)) {
  cli::cli_abort("ICES SAG annual estimates do not agree with Table 17.16 to reported rounding.")
}

stock_maturity <- data.frame(age = 0:11, value = c(0, 0, 0.53, 0.92, 0.96, 0.97, rep(1, 6)))
n_matrix <- matrix(n_at_age$value, nrow = length(years), byrow = TRUE)
weight_matrix <- matrix(stock_weight$value, nrow = length(years), byrow = TRUE)
maturity_values <- stock_maturity$value[match(ages, stock_maturity$age)]
derived_total_numbers <- rowSums(n_matrix)
derived_total_biomass <- rowSums(n_matrix * weight_matrix)
derived_ssb <- rowSums(n_matrix * weight_matrix * rep(maturity_values, each = length(years)))
ssb_age_sum <- rowSums(matrix(ssb_at_age$value, nrow = length(years), byrow = TRUE))
ssb_age_relative_difference <- abs(ssb_age_sum - summary_history$SSB) / summary_history$SSB
if (any(ssb_age_relative_difference[years <= 2020L] > 0.002) ||
  max(abs(derived_ssb - summary_history$SSB) / summary_history$SSB) > 0.01) {
  cli::cli_abort("N-at-age, stock weight, and maturity do not reproduce the reported SSB summary, or the pre-2021 SSB-at-age table does not sum to its reported total.")
}
inconsistent_ssb_years <- years[ssb_age_relative_difference > 0.002]
if (length(inconsistent_ssb_years)) {
  cli::cli_warn("Table 17.19 SSB-at-age values do not sum to Table 17.16 for years {paste(inconsistent_ssb_years, collapse = ', ')}. The source values are retained as published and flagged for review.")
}

stocks <- read_table("stocks.csv")
stock_index <- match(stock_id, stocks$stock_id)
assessments <- read_table("assessments.csv")
if (is.na(stock_index) || any(assessments$assessment_id == assessment_id)) {
  cli::cli_abort("Expected a catalogue-only 7.d sole stock and no existing 2026 assessment record.")
}

input_header <- names(read_table("inputs.csv", nrows = 0L))
input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", source_reference,
                       source_type = "official_table", transformation,
                       notes = "", season = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(input_header)), stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$season <- rep_len(season, n)
  out$year <- ifelse(is.na(year), "", as.character(rep_len(year, n)))
  out$year_basis <- ifelse(is.na(year), "", "calendar_year")
  out$age <- ifelse(is.na(age), "", as.character(rep_len(age, n)))
  out$value <- format_value(rep_len(value, n))
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out
}
output_header <- names(read_table("outputs.csv", nrows = 0L))
output_rows <- function(type, measure, year, age, age_group, value, unit,
                        se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        fleet = "", survey = "", source_type = "official_table",
                        source_reference = report_ref, notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_header)), stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$year <- ifelse(is.na(year), "", as.character(rep_len(year, n)))
  out$age <- ifelse(is.na(age), "", as.character(rep_len(age, n)))
  if ("age_group" %in% names(out)) out$age_group <- rep_len(age_group, n)
  out$value <- format_value(rep_len(value, n))
  out$se <- format_value(rep_len(se, n))
  out$lwr <- format_value(rep_len(lwr, n))
  out$upr <- format_value(rep_len(upr, n))
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

wide_to_long <- function(x) x[order(x$year, x$age), , drop = FALSE]
catch_inputs <- input_rows(
  "catch", "numbers_at_age", "numbers", catch$year, catch$age, catch$value,
  "thousand fish", fleet = "Combined catch",
  source_reference = paste(report_ref, "Table 17.4"),
  transformation = "Transcribed from the published model catch-at-age table without rescaling.",
  notes = "Combined catch numbers at age, including the 11+ plus group; the report does not publish the source landings and discard inputs separately."
)
catch_weight_inputs <- input_rows(
  "catch_weight", "weight_at_age", "kg_per_fish", catch_weight$year,
  catch_weight$age, catch_weight$value, "kg per fish", fleet = "Combined catch",
  source_reference = paste(report_ref, "Table 17.5"),
  transformation = "Transcribed from the published catch-weight-at-age table.",
  notes = "Age 11 is the 11+ plus group."
)
stock_weight_inputs <- input_rows(
  "weight", "weight_at_age", "kg_per_fish", stock_weight$year,
  stock_weight$age, stock_weight$value, "kg per fish",
  source_reference = paste(report_ref, "Table 17.6"),
  transformation = "Transcribed from the published stock-weight-at-age table.",
  notes = "Quarter-1 catch weights are used as stock weights; values for 1982-2003 are identified by the assessment report as reconstructed. Age 11 is the 11+ plus group."
)
maturity_inputs <- input_rows(
  "maturity", "maturity_at_age", "proportion", NA_integer_,
  stock_maturity$age, stock_maturity$value, "proportion",
  source_reference = paste(report_ref, "Section 17.2.3"),
  transformation = "Transcribed from the age-specific maturity ogive in the assessment report.",
  notes = "The fitted age range is 1-11+, with age 11 as the plus group. Age 0 is retained from the reported ogive for source completeness."
)
m_inputs <- input_rows(
  "M", "natural_mortality_at_age", "per_year", NA_integer_, ages,
  rep(0.1, length(ages)), "per year", source_reference = paste(report_ref, "Section 17.2.3"),
  source_type = "official_document",
  transformation = "Recorded from the stated constant natural mortality assumption.",
  notes = "Fixed at 0.1 per year for all years and ages; M is not estimated."
)
commercial_inputs <- do.call(rbind, lapply(names(commercial), function(name) {
  x <- commercial[[name]]
  rbind(
    input_rows(
      "index", "relative_biomass_index", "index_scale", x$year, NA_integer_,
      x$value, "native relative biomass index (scale unit unresolved)", fleet = name,
      source_reference = paste(report_ref, paste0("Table 17.", match(name, names(commercial)) + 6L)),
      transformation = "Transcribed directly from the commercial LPUE series; no rescaling or conversion to absolute biomass.",
      notes = "The SAM treats this as a fishable-stock-biomass index. tinyAM has no aggregate FSB-index likelihood; it remains in the database and is excluded from the translation."
    ),
    input_rows(
      "covariate", "effort", "native_covariate", x$year, NA_integer_, x$effort,
      "source table effort field (unit unresolved)", fleet = name,
      source_reference = paste(report_ref, paste0("Table 17.", match(name, names(commercial)) + 6L)),
      transformation = "Transcribed directly from the source table.",
      notes = "The published table reports effort=1; its physical interpretation is not documented."
    )
  )
}))
survey_inputs <- do.call(rbind, lapply(names(survey), function(name) {
  x <- survey[[name]]
  table_number <- 10L + match(name, names(survey)) - 1L
  input_rows(
    "index", "numbers_at_age", "index_scale", x$rows$year, x$rows$age,
    x$rows$value, "native survey index (unit unresolved)", survey = name,
    source_reference = paste(report_ref, paste0("Table 17.", table_number)),
    transformation = "Transcribed directly from the age-disaggregated tuning table without rescaling.",
    notes = if (name == "UK(E&W)-BTS-Q3") {
      "All tabulated values are retained. Ages 1-3 from 2010 onward are grey in the source table and excluded from the official SAM fit; 2022 has no survey data."
    } else if (name == "FR-YFS") {
      "2024 and 2025 were sampled, but no data were available to the assessment."
    } else {
      "The UK Young Fish Survey stopped after 2006."
    }
  )
}))
inputs <- rbind(
  catch_inputs, catch_weight_inputs, stock_weight_inputs, maturity_inputs,
  m_inputs, commercial_inputs, survey_inputs
)

assumption_header <- names(read_table("assumptions.csv", nrows = 0L))
assumption_values <- data.frame(
  component = c(
    "assessment", "assessment", "assessment", "assessment", "population",
    "population", "population", "population", "population", "F", "F", "N",
    "catch", "index", "index", "index", "index", "index", "index", "index",
    "index", "index", "biology", "biology", "biology"
  ),
  fleet = c(rep("", 25L)), survey = c(rep("", 25L)),
  setting = c(
    "model_family", "fit_years", "model_age_range", "plus_group", "recruitment_model",
    "Fbar_ages", "catch_scaling", "likelihood", "biomass_treatment", "F_state_age_keys",
    "F_age_correlation", "log_N_process_variance_keys", "catch_observation_variance_keys",
    "commercial_q_keys", "survey_q_keys", "observation_variance_keys", "observation_correlation",
    "survey_timing_window", "commercial_timing_window", "commercial_index_type",
    "survey_index_type", "q_power", "stock_weight", "maturity_ogive", "natural_mortality"
  ),
  value = c(
    "SAM", "1982-2025", "1-11+", "Age 11 is the plus group.",
    "stockRecruitmentModelCode=0; random walk",
    "3-7", "None", "Lognormal for catch and all six tuning fleets.",
    "Commercial LPUE fleets use fishable stock biomass (keyBiomassTreat=2).",
    "Ages 1-11 keys: 0,1,2,3,4,5,5,6,6,7,7.",
    "corFlag=0; independent across ages.",
    "Ages 1-11 keys: 0,1,1,1,1,1,1,1,1,1,1.",
    "Catch ages 1-11 keys: 0,1,2,2,2,2,2,2,2,2,2.",
    "Separate q for BE-CBT-LPUE, UK(E&W)-CBT-LPUE, and FR-COTB-LPUE.",
    "UK BTS ages 1-4 have separate q; ages 5-6 share q; each YFS has one age-1 q.",
    "Catch age 1 and age 2 have separate variances; ages 3-11 share. Commercial indices each have separate variance. UK BTS age 1 and 2 each have separate variance; ages 3-6 share. Each YFS has a separate variance.",
    "UK BTS observations use AR(1) correlation across adjacent ages; other fleets use independent observation errors.",
    "UK BTS Q3; UK YFS and French YFS timing windows are 0.5-0.75 of year.",
    "Commercial index timing is the full year (0-1).",
    "Three commercial LPUE series are aggregated fishable-stock-biomass indices.",
    "UK BTS age 1-6, UK YFS age 1, French YFS age 1; BTS ages 1-3 from 2010 onward excluded.",
    "No density-dependent q power parameters.",
    "Q1 catch weight-at-age is used; 1982-2003 values are reconstructed.",
    "Age 0=0; age 1=0; age 2=0.53; age 3=0.92; age 4=0.96; age 5=0.97; ages 6-11+=1.",
    "Fixed at 0.1 per year for all ages and years; not estimated."
  ),
  reference = c(
    rep(report_ref, 17L), annex_ref, annex_ref,
    rep(report_ref, 6L)
  ),
  notes = c(
    "Configuration is reported in Table 17.13.",
    "The model has a random-walk stock-recruitment process (stockRecruitmentModelCode=0).",
    "The 2026 assessment fit ends at 2025; 2026 summary values are forecasts.",
    "The terminal group is modeled as an 11+ plus group.",
    "The report states the recruitment random-walk model code is 0.",
    "Native Fbar is the arithmetic mean over ages 3-7.",
    "No scaled catch years or scale parameters are used.",
    "All fleet observation likelihood flags are LN.",
    "The commercial tuning series are not age-disaggregated.",
    "SAM configuration keyLogFsta, ages 1-11.",
    "The age-specific F states are independent in their cross-age process covariance.",
    "SAM configuration keyVarLogN, ages 1-11.",
    "SAM configuration keyVarObs, catch fleet.",
    "SAM configuration keyLogFpar, commercial fleets.",
    "SAM configuration keyLogFpar, survey fleets.",
    "SAM configuration keyVarObs, all fleets.",
    "SAM configuration obsCorStruct and keyCorObs.",
    "The tinyAM translation uses the midpoint 0.625 as a single survey-time approximation.",
    "The assessment's biomass-index timing interval is not a point time.",
    "Commercial series are retained as inputs but not fitted by tinyAM.",
    "The source table also retains excluded BTS cells for provenance.",
    "SAM keyQpow is empty.",
    "Annual stock weight surface is published in Table 17.6.",
    "Ogive is published in Section 17.2.3.",
    "M is a fixed source assumption, not an estimate."
  ), stringsAsFactors = FALSE
)
assumptions <- as.data.frame(matrix("", nrow = nrow(assumption_values), ncol = length(assumption_header)), stringsAsFactors = FALSE)
names(assumptions) <- assumption_header
assumptions$assessment_id <- assessment_id
assumptions$component <- assumption_values$component
assumptions$fleet <- assumption_values$fleet
assumptions$survey <- assumption_values$survey
assumptions$setting <- assumption_values$setting
assumptions$value <- assumption_values$value
assumptions$source_reference <- assumption_values$reference
assumptions$notes <- assumption_values$notes

output_data <- list(
  output_rows("population", "numbers_at_age", n_at_age$year, n_at_age$age, "", n_at_age$value,
    "thousand fish", source_reference = paste(report_ref, "Table 17.17"),
    notes = "Start-of-year abundance estimates; age 11 is the 11+ plus group. The report provides no age-specific interval or SE."),
  output_rows("mortality", "fishing_mortality_at_age", f_at_age$year, f_at_age$age, "", f_at_age$value,
    "per year", source_reference = paste(report_ref, "Table 17.18"),
    notes = "Annual fishing mortality; age 11 is the 11+ plus group. The report provides no age-specific interval or SE."),
  output_rows("biomass", "mature_biomass_at_age", ssb_at_age$year, ssb_at_age$age, "", ssb_at_age$value,
    "tonnes", source_reference = paste(report_ref, "Table 17.19"),
    notes = ifelse(ssb_at_age$year %in% inconsistent_ssb_years,
      "Transcribed from Table 17.19 as published. For 2021-2025, age values do not sum to annual SSB in Table 17.16; retained with this source inconsistency flagged and not used to validate aggregate SSB. Age 11 is the 11+ plus group; no age-specific uncertainty is reported.",
      "Start-of-year SSB contribution at age; age 11 is the 11+ plus group. The rounded age values sum to Table 17.16 within rounding; no age-specific uncertainty is reported.")),
  output_rows("population", "total_numbers", years, NA_integer_, "1-11+", derived_total_numbers,
    "thousand fish", source_type = "derived_source_output", source_reference = paste(report_ref, "Table 17.17"),
    notes = "Derived as the sum of the reported N-at-age values for ages 1-11+. No uncertainty is calculated because joint covariance is not available."),
  output_rows("biomass", "total_biomass", years, NA_integer_, "1-11+", derived_total_biomass,
    "tonnes", source_type = "derived_source_output", source_reference = paste(report_ref, "Tables 17.6 and 17.17"),
    notes = "Derived as sum(N-at-age × stock weight-at-age) over ages 1-11+. Thousand fish × kg per fish gives tonnes. No uncertainty is calculated because joint covariance is not available."),
  output_rows("recruitment", "recruitment", summary_history$year, 1L, "", sag_history$recruitment,
    "thousand fish", lwr = summary_history$recruitment_low, upr = summary_history$recruitment_high,
    source_type = "official_machine_readable", source_reference = paste(sag_ref, "and", report_ref, "Table 17.16"),
    notes = "Age-1 recruitment. Point estimates are from the ICES SAG XML; lower and upper bounds are the published Table 17.16 endpoints, corresponding to the ICES 2.5th and 97.5th percentiles. The report does not state the interval construction."),
  output_rows("recruitment", "recruitment", 2026L, 1L, "", summary_forecast$recruitment,
    "thousand fish", source_type = "official_table", source_reference = paste(report_ref, "Table 17.16"),
    notes = "Short-term forecast; the table identifies this as the geometric mean of resampled recruitment estimates from 2020-2025. No bounds are reported."),
  output_rows("biomass", "SSB", summary_history$year, NA_integer_, "1-11+", sag_history$SSB,
    "tonnes", lwr = summary_history$SSB_low, upr = summary_history$SSB_high,
    source_type = "official_machine_readable", source_reference = paste(sag_ref, "and", report_ref, "Table 17.16"),
    notes = "Start-of-year spawning-stock biomass. Point estimates are from the ICES SAG XML; lower and upper bounds are the published Table 17.16 endpoints, corresponding to the ICES 2.5th and 97.5th percentiles. The report does not state the interval construction."),
  output_rows("biomass", "SSB", 2026L, NA_integer_, "1-11+", summary_forecast$SSB,
    "tonnes", lwr = summary_forecast$SSB_low, upr = summary_forecast$SSB_high,
    source_type = "official_table", source_reference = paste(report_ref, "Table 17.16"),
    notes = "Short-term forecast; 95% interval endpoints are reported in the ICES SAG 2.5th and 97.5th percentile fields. This is not a fitted historical year."),
  output_rows("catch", "landings", summary_history$year, NA_integer_, "", summary_history$landings,
    "tonnes", source_reference = paste(report_ref, "Table 17.16"), notes = "Reported annual landings summary."),
  output_rows("catch", "discards", summary_history$year, NA_integer_, "", summary_history$discards,
    "tonnes", source_reference = paste(report_ref, "Table 17.16"), notes = "Reported annual discard summary."),
  output_rows("mortality", "Fbar", summary_history$year, NA_integer_, "3-7", sag_history$Fbar,
    "per year", lwr = summary_history$Fbar_low, upr = summary_history$Fbar_high,
    source_type = "official_machine_readable", source_reference = paste(sag_ref, "and", report_ref, "Table 17.16"),
    notes = "Unweighted arithmetic mean F at ages 3-7. Point estimates are from the ICES SAG XML; lower and upper bounds are the published Table 17.16 endpoints. The report does not state the interval construction.")
)

q_output <- data.frame(
  fleet = c("BE-CBT-LPUE", "UK(E&W)-CBT-LPUE", "FR-COTB-LPUE", rep("", 6L), "", ""),
  survey = c(rep("", 3L), rep("UK(E&W)-BTS-Q3", 6L), "UK(E&W)-YFS", "FR-YFS"),
  age = c(NA_integer_, NA_integer_, NA_integer_, 1:6, 1L, 1L),
  log_q = c(-4.4166, -2.5919, -4.4297, -7.9927, -7.162, -7.4900, -7.7332, -7.8779, -7.8779, -9.6620, -11.8194),
  observation_sd = c(0.0724, 0.0673, 0.103, 0.2007, 0.0904, 0.0966, 0.0780, 0.0730, 0.0730, 0.1353, 0.1667)
)
output_data[[length(output_data) + 1L]] <- output_rows(
  "catchability", "q", NA_integer_, q_output$age, "", exp(q_output$log_q),
  "source index scale coefficient", fleet = q_output$fleet, survey = q_output$survey,
  source_reference = paste(report_ref, "Table 17.15"),
  notes = "Derived by exponentiating the log-q estimate printed in Table 17.15; no parameter uncertainty is reported."
)
output_data[[length(output_data) + 1L]] <- output_rows(
  "index", "observation_sd", NA_integer_, q_output$age, "", q_output$observation_sd,
  "log scale", fleet = q_output$fleet, survey = q_output$survey,
  source_reference = paste(report_ref, "Table 17.15"),
  notes = "Estimated observation SD on the log scale; no parameter uncertainty is reported."
)
outputs <- do.call(rbind, output_data)

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2026", terminal_year = "2025", estimate_terminal_year = "2026",
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = "WGNSSK 2026 production configuration; 2022 IBP model",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "2022",
  assessment_url = report_ref, framework_url = annex_ref, data_url = sag_ref,
  model_url = "", repository_url = repository_ref,
  assumptions_status = "complete", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The official 2026 SAM assessment is fitted through 2025, with 2026 recruitment and SSB forecasts.",
    "The detailed report provides the full input tables, SAM settings, at-age outputs, and aggregate summary; source tables are rounded.",
    "Table 17.19 SSB-at-age values for 2021-2025 do not sum to Table 17.16 annual SSB and appear misaligned; the raw table is preserved and output completeness is partial.",
    "The pinned public TAF repository contains processing/configuration code but does not track bootstrap input data or the fitted SAM object.",
    "The three commercial fishable-stock-biomass indices are preserved, although tinyAM cannot fit that aggregate observation structure.",
    "See source_reviews/ices_sole_eastern_channel_7d_2026.md."
  ),
  stringsAsFactors = FALSE
)

stocks$authority_stock_id[[stock_index]] <- "sol.27.7d"
stocks$scientific_name[[stock_index]] <- "Solea solea"
stocks$common_name[[stock_index]] <- "Eastern English Channel common sole"
stocks$area[[stock_index]] <- "ICES Division 7.d (eastern English Channel)"
stocks$region[[stock_index]] <- "Eastern English Channel"
stocks$notes[[stock_index]] <- paste(
  stocks$notes[[stock_index]],
  "Matched to the official 2026 ICES SAM assessment for stock sol.27.7d; the Charbonneau-Keith identifier is retained as a catalogue crosswalk."
)
utils::write.table(stocks, file.path(database_dir, "stocks.csv"), sep = ",", quote = TRUE,
  row.names = FALSE, na = "")
for (name in c("assessments", "assumptions", "inputs", "outputs")) {
  path <- file.path(database_dir, paste0(name, ".csv"))
  rows <- switch(name, assessments = assessment_row, assumptions = assumptions,
    inputs = inputs, outputs = outputs)
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
cat("Imported", nrow(inputs), "source inputs,", nrow(assumptions),
  "assumptions, and", nrow(outputs), "outputs for", assessment_id, "\n")
