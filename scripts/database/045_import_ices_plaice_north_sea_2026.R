assessment_id <- "ices_plaice_north_sea_2026"
stock_id <- "ices_plaice_north_sea"
root <- "."
cache <- file.path(root, "source_cache", assessment_id)
report_path <- file.path(cache, "wgnssk_2026_plaice_chapter.txt")
xml_path <- file.path(cache, "ices_sag_2026_key_22489.xml")
report_url <- "https://doi.org/10.17895/ices.pub.32676345"
advice_url <- "https://doi.org/10.17895/ices.advice.30932264"
framework_url <- "https://doi.org/10.17895/ices.pub.21558681"
graphs_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22489"

if (!file.exists(report_path) || !file.exists(xml_path)) {
  stop("Cache the official WGNSSK 2026 plaice chapter and ICES SAG XML first.",
    call. = FALSE
  )
}
report_lines <- readLines(report_path, warn = FALSE, encoding = "UTF-8")

table_lines <- function(table_id) {
  caption <- paste0(
    "^\\s*Table\\s+", gsub(".", "[.]", table_id, fixed = TRUE),
    "[.]\\s+Plaice"
  )
  start <- grep(caption, report_lines, perl = TRUE)
  if (length(start) != 1L) stop("Expected one report table: ", table_id)
  headings <- grep("^\\s*Table\\s+11[.][0-9]+[.][0-9]+[.]\\s+Plaice",
    report_lines,
    perl = TRUE
  )
  following <- headings[headings > start]
  end <- if (length(following)) min(following) - 1L else length(report_lines)
  report_lines[seq.int(start + 1L, end)]
}

numeric_fields <- function(line) {
  strsplit(trimws(line), "[[:space:]]+", perl = TRUE)[[1L]]
}

age_table <- function(table_id, age_count, years) {
  lines <- table_lines(table_id)
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    fields <- numeric_fields(line)
    year <- as.integer(fields[[1L]])
    values <- suppressWarnings(as.numeric(fields[-1L]))
    if (length(values) != age_count) {
      stop("Unexpected age count in Table ", table_id, ", year ", year,
        ": ", length(values),
        call. = FALSE
      )
    }
    data.frame(year = year, age = seq_len(age_count), value = values)
  })
  out <- do.call(rbind, rows)
  if (!nrow(out) || anyDuplicated(out[c("year", "age")]) ||
    !setequal(unique(out$year), years) || anyNA(out$value) ||
    any(!is.finite(out$value)) || any(out$value < 0)) {
    stop("Unexpected values or year coverage in Table ", table_id,
      call. = FALSE
    )
  }
  out
}

survey_table <- function() {
  lines <- table_lines("11.2.11")
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  rows <- list()
  for (line in lines) {
    fields <- numeric_fields(line)
    values <- suppressWarnings(as.numeric(fields))
    year <- as.integer(values[[1L]])
    if (year >= 1985L && year <= 1995L && length(values) == 9L) {
      rows[[length(rows) + 1L]] <- data.frame(
        survey = "BTS-Isis", year = year, age = 1:8, value = values[-1L]
      )
    } else if (year >= 1996L && year <= 2025L && length(values) == 11L) {
      rows[[length(rows) + 1L]] <- data.frame(
        survey = "BTS-IBTS Q3", year = year, age = 1:10, value = values[-1L]
      )
    } else if (year >= 1970L && year <= 1995L && length(values) == 14L) {
      rows[[length(rows) + 1L]] <- data.frame(
        survey = "SNS1", year = year, age = 1:6, value = values[2:7]
      )
      sns2_values <- values[9:14]
      sns2_year <- as.integer(values[[8L]])
      if (!all(is.na(sns2_values))) {
        rows[[length(rows) + 1L]] <- data.frame(
          survey = "SNS2", year = sns2_year, age = 1:6, value = sns2_values
        )
      }
    } else if (year >= 1996L && year <= 1999L && length(values) == 7L) {
      rows[[length(rows) + 1L]] <- data.frame(
        survey = "SNS1", year = year, age = 1:6, value = values[-1L]
      )
    } else if (year >= 2000L && year <= 2025L && length(values) == 14L) {
      sns2_values <- values[9:14]
      if (!all(is.na(sns2_values))) {
        rows[[length(rows) + 1L]] <- data.frame(
          survey = "SNS2", year = year, age = 1:6, value = sns2_values
        )
      }
    } else if (year >= 2007L && year <= 2025L && length(values) == 9L) {
      rows[[length(rows) + 1L]] <- data.frame(
        survey = "IBTS Q1", year = year, age = 1:8, value = values[-1L]
      )
    } else {
      stop("Could not classify survey table row: ", line, call. = FALSE)
    }
  }
  out <- do.call(rbind, rows)
  expected <- list(
    "BTS-Isis" = 1985:1995, "BTS-IBTS Q3" = 1996:2025,
    "SNS1" = 1970:1999, "SNS2" = setdiff(2000:2025, 2003),
    "IBTS Q1" = 2007:2025
  )
  for (survey in names(expected)) {
    series <- out[out$survey == survey, , drop = FALSE]
    if (!setequal(unique(series$year), expected[[survey]]) ||
      anyNA(series$value) || any(!is.finite(series$value)) ||
      any(series$value < 0)) {
      stop("Unexpected values or year coverage for ", survey,
        "; missing years: ", paste(setdiff(expected[[survey]], unique(series$year)), collapse = ", "),
        "; extra years: ", paste(setdiff(unique(series$year), expected[[survey]]), collapse = ", "),
        "; missing values: ", sum(is.na(series$value)),
        call. = FALSE
      )
    }
  }
  out
}

xml_values <- function(path) {
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  matches <- regmatches(text, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>", text,
    perl = TRUE
  ))[[1L]]
  if (!length(matches)) stop("No annual Fish_Data records in SAG XML.")
  field <- function(node, tag) {
    pattern <- paste0("(?s)<", tag, ">(.*?)</", tag, ">")
    value <- regmatches(node, regexec(pattern, node, perl = TRUE))[[1L]][2L]
    if (!length(value) || !nzchar(value)) {
      return(NA_real_)
    }
    suppressWarnings(as.numeric(value))
  }
  rows <- lapply(matches, function(node) {
    tags <- c(
      "Year", "Recruitment", "Low_Recruitment", "High_Recruitment",
      "StockSize", "Low_StockSize", "High_StockSize",
      "FishingPressure", "Low_FishingPressure", "High_FishingPressure"
    )
    values <- vapply(tags, function(tag) field(node, tag), numeric(1))
    as.data.frame(as.list(values))
  })
  out <- do.call(rbind, rows)
  names(out) <- c(
    "year", "recruitment", "recruitment_lwr", "recruitment_upr",
    "SSB", "SSB_lwr", "SSB_upr", "Fbar", "Fbar_lwr", "Fbar_upr"
  )
  out$year <- as.integer(out$year)
  out
}

new_input <- function(type, measure, basis, year, age, value, unit,
                      fleet = NA_character_, survey = NA_character_,
                      sampling_time = NA_real_, year_basis = "calendar_year",
                      source_reference, transformation, notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = rep(basis, length.out = n), fleet = rep(fleet, length.out = n),
    survey = rep(survey, length.out = n), sex = NA_character_,
    region = NA_character_, season = NA_character_, year = year,
    year_basis = rep(year_basis, length.out = n), age = age, value = value,
    unit = rep(unit, length.out = n),
    sampling_time = rep(sampling_time, length.out = n),
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = NA_character_, length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = NA_character_, partition = NA_character_,
    stringsAsFactors = FALSE
  )
}

new_assumption <- function(component, setting, value, source_reference,
                           notes = "", survey = NA_character_) {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = NA_character_,
    survey = survey, sex = NA_character_, region = NA_character_,
    season = NA_character_, setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

new_output <- function(type, measure, year, value, unit, age = NA_integer_,
                       age_group = NA_character_, lwr = NA_real_, upr = NA_real_,
                       source_type = "official_table", source_reference,
                       notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = year,
    age = rep(age, length.out = n), age_group = rep(age_group, length.out = n),
    value = value, se = NA_real_, lwr = rep(lwr, length.out = n),
    upr = rep(upr, length.out = n), unit = rep(unit, length.out = n),
    source_type = source_type, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}

append_rows <- function(path, rows, key, id) {
  existing <- read.csv(path,
    colClasses = "character", na.strings = "",
    check.names = FALSE
  )
  if (!identical(names(existing), names(rows))) {
    stop("Unexpected columns in ", basename(path), call. = FALSE)
  }
  if (any(existing[[key]] == id, na.rm = TRUE)) {
    stop("Rows already exist for ", id, " in ", basename(path),
      call. = FALSE
    )
  }
  utils::write.table(rows, path,
    sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}

catch <- age_table("11.2.4", 10L, 1957:2025)
stock_weight <- age_table("11.2.6", 10L, 1957:2025)
natural_mortality <- c(.495, .394, .343, .311, .292, .278, .268, .260, .252, .246)
maturity <- c(0, .5, .5, 1, 1, 1, 1, 1, 1, 1)
indices <- survey_table()
survey_times <- c(
  "BTS-Isis" = .75, "BTS-IBTS Q3" = .75, SNS1 = .75,
  SNS2 = .75, "IBTS Q1" = .125
)
survey_ages <- c(
  "BTS-Isis" = 8L, "BTS-IBTS Q3" = 10L, SNS1 = 6L,
  SNS2 = 6L, "IBTS Q1" = 8L
)

inputs <- list(
  new_input("catch", "numbers_at_age", "numbers", catch$year, catch$age,
    catch$value, "thousand fish",
    fleet = "Total catch",
    source_reference = paste(report_url, "Table 11.2.4"),
    transformation = "Transcribed from the official catch-at-age input table.",
    notes = "Includes landings and discards, including 50% of mature plaice caught in Division 7.d in Q1. Age 10 is 10+."
  ),
  new_input("weight", "weight_at_age", "kg_per_fish", stock_weight$year,
    stock_weight$age, stock_weight$value, "kg per fish",
    source_reference = paste(report_url, "Table 11.2.6"),
    transformation = "Transcribed from the official stock weight-at-age table.",
    notes = "Age 10 is 10+."
  ),
  new_input("M", "natural_mortality_at_age", "per_year", NA_integer_, 1:10,
    natural_mortality, "per year",
    year_basis = NA_character_,
    source_reference = paste(report_url, "Table 11.2.10"),
    transformation = "Transcribed from the fixed age-specific mortality assumption.",
    notes = "Time-invariant M; the official SAM assessment fixes these values. Age 10 is 10+."
  ),
  new_input("maturity", "maturity_at_age", "proportion", NA_integer_, 1:10,
    maturity, "proportion",
    year_basis = NA_character_,
    source_reference = paste(report_url, "Table 11.2.10"),
    transformation = "Transcribed from the time-invariant maturity ogive.",
    notes = "Age 10 is 10+."
  ),
  do.call(rbind, lapply(names(survey_times), function(survey) {
    x <- indices[indices$survey == survey, , drop = FALSE]
    new_input("index", "numbers_at_age", "numbers", x$year, x$age, x$value,
      "survey index (unit unresolved)",
      survey = survey,
      sampling_time = survey_times[[survey]],
      source_reference = paste(report_url, "Table 11.2.11"),
      transformation = "Transcribed from the published age-specific survey-index table; survey timing is approximated by the midpoint of its named quarter.",
      notes = paste0(
        "Reported ages 1-", survey_ages[[survey]],
        if (survey_ages[[survey]] %in% c(8L, 10L)) "+" else "",
        ". The source report does not specify numerical units."
      )
    )
  }))
)
inputs <- do.call(rbind, inputs)

assumptions <- do.call(rbind, list(
  new_assumption("assessment", "assessment_type", "Annual full assessment", report_url),
  new_assumption("assessment", "model_family", "SAM", report_url),
  new_assumption(
    "population", "assessment_scope", "North Sea Subarea 4 and Skagerrak Subdivision 20", report_url,
    "The stock assessment also includes 50% of mature North Sea plaice caught in Division 7.d during Q1."
  ),
  new_assumption("population", "model_years", "1957-2025", paste(report_url, "Tables 11.2.4, 11.2.6, 11.3.3, 11.3.4")),
  new_assumption("population", "model_ages", "1-10; age 10 is the plus group", paste(report_url, "section 11.3.1")),
  new_assumption("population", "recruitment_age", "1", paste(report_url, "Table 11.3.1")),
  new_assumption("population", "min_age", "1", paste(report_url, "section 11.3.1")),
  new_assumption("population", "max_age", "10", paste(report_url, "section 11.3.1")),
  new_assumption(
    "population", "max_age_plus_group_flags", "101100", paste(report_url, "section 11.3.1"),
    "SAM configuration value; the report's input and output tables show age 10 as the plus group."
  ),
  new_assumption(
    "N", "variance_sharing_keys", "0 1 1 1 1 1 1 1 1 1", paste(report_url, "section 11.3.1"),
    "SAM keyVarLogN; age 1 has a separate variance parameter and ages 2-10 share another."
  ),
  new_assumption(
    "F", "age_correlation", "AR(1)", paste(report_url, "section 11.3.1"),
    "SAM corFlag is 2; this is the reported correlation of fishing-mortality states across ages."
  ),
  new_assumption(
    "F", "state_coupling_keys", "0 1 2 3 4 5 6 7 8 8; remaining rows all -1", paste(report_url, "section 11.3.1"),
    "SAM keyLogFsta matrix; the printed report does not label the corresponding fleet rows."
  ),
  new_assumption(
    "F", "variance_sharing_keys", "0 1 2 2 2 2 2 3 3 3", paste(report_url, "section 11.3.1"),
    "SAM keyVarF; age-specific process-variance sharing is recorded as published."
  ),
  new_assumption("F", "Fbar_ages", "2-6", paste(report_url, "Table 11.3.1")),
  new_assumption(
    "M", "natural_mortality", paste(natural_mortality, collapse = ", "), paste(report_url, "Table 11.2.10"),
    "Fixed, time-invariant age-specific M. The 2022 benchmark derived these values from weight-dependent natural mortality and averaged them over years."
  ),
  new_assumption(
    "maturity", "maturity_at_age", paste(maturity, collapse = ", "), paste(report_url, "Table 11.2.10"),
    "A time-invariant maturity ogive was retained after the benchmark found little SSB effect from a time-varying alternative."
  ),
  new_assumption(
    "catch", "catch_at_age", "One aggregate series; landings plus discards", paste(report_url, "Table 11.2.4"),
    "Includes 50% of mature catches of North Sea plaice in Division 7.d during Q1."
  ),
  new_assumption("index", "surveys", paste(names(survey_times), collapse = "; "), paste(report_url, "Table 11.2.11")),
  new_assumption(
    "index", "missing_observations", "SNS2: 2003", paste(report_url, "Table 11.2.11"),
    "All age entries are missing for this year; no observation rows are stored."
  ),
  new_assumption(
    "index", "sampling_time", "Q3 = 0.75; Q1 = 0.125", paste(report_url, "sections 11.2.7 and 11.3.1"),
    "Quarter midpoints approximate within-year timing. The printed report does not give exact fleet sampling fractions; SNS is identified as Q3 in ICES survey descriptions."
  ),
  new_assumption(
    "index", "q_sharing_configuration", "-1 -1 -1 -1 -1 -1 -1 -1 -1 -1; 0 1 2 3 4 5 6 7 -1 -1; 8 9 10 11 12 12 12 12 12 12; 13 14 15 15 15 15 16 17 -1 -1; 18 19 20 21 22 23 -1 -1 -1 -1; 24 25 26 27 28 29 -1 -1 -1 -1", paste(report_url, "section 11.3.1"),
    "Fleet-specific q sharing is encoded in the published matrix; tinyAM translation will use separate survey-age q values unless an exact equivalent is clear."
  ),
  new_assumption(
    "index", "observation_correlation_configuration", "ID ID ID AR AR AR", paste(report_url, "section 11.3.1"),
    "The report lists the SAM fleet correlation structures but does not label the row-to-survey mapping in the printed block."
  ),
  new_assumption("weight", "stock_weights", "Annual stock weight-at-age", paste(report_url, "Table 11.2.6")),
  new_assumption(
    "outputs", "confidence_intervals", "95%", graphs_url,
    "The SAG XML defines the lower and upper recruitment, SSB, and F intervals as 95% confidence intervals."
  ),
  new_assumption(
    "source", "framework", "2022 WKNSCS benchmark", framework_url,
    "The 2026 official assessment uses the SAM framework adopted at the 2022 benchmark."
  ),
  new_assumption(
    "source", "native_model_files", "Not recovered", paste(report_url, "section 11.3.1"),
    "The official report and ICES SAG outputs are available; a native fitted SAM object or complete input bundle was not found in the public archive search."
  )
))

f_surface <- age_table("11.3.3", 10L, 1957:2025)
n_surface <- age_table("11.3.4", 10L, 1957:2025)
summary <- xml_values(xml_path)
if (!setequal(summary$year, 1957:2026) ||
  !all(is.finite(summary$recruitment[summary$year <= 2025])) ||
  !all(is.finite(summary$SSB[summary$year <= 2025])) ||
  !all(is.finite(summary$Fbar[summary$year <= 2025]))) {
  stop("Unexpected years or missing historical outputs in the ICES SAG XML.",
    call. = FALSE
  )
}
report_reference <- function(table) paste(report_url, "Table", table)
age_group <- function(age) ifelse(age == 10L, "10+", NA_character_)
outputs <- rbind(
  new_output("population", "numbers_at_age", n_surface$year, n_surface$value,
    "thousand fish",
    age = n_surface$age, age_group = age_group(n_surface$age),
    source_reference = report_reference("11.3.4"),
    notes = "Published SAM numbers-at-age estimates; age 10 is 10+."
  ),
  new_output("mortality", "fishing_mortality_at_age", f_surface$year,
    f_surface$value, "per year",
    age = f_surface$age,
    age_group = age_group(f_surface$age),
    source_reference = report_reference("11.3.3"),
    notes = "Published SAM fishing mortality at age; age 10 is 10+."
  ),
  new_output("recruitment", "recruitment",
    summary$year[is.finite(summary$recruitment)],
    summary$recruitment[is.finite(summary$recruitment)],
    "thousand fish",
    age = 1L,
    lwr = summary$recruitment_lwr[is.finite(summary$recruitment)],
    upr = summary$recruitment_upr[is.finite(summary$recruitment)],
    source_type = "official_machine_readable", source_reference = graphs_url,
    notes = "Age-1 recruitment; the ICES SAG XML gives 95% confidence bounds for historical estimates. 2026 is an advice forecast, not a fitted historical year."
  ),
  new_output("biomass", "SSB", summary$year[is.finite(summary$SSB)],
    summary$SSB[is.finite(summary$SSB)], "tonnes",
    lwr = summary$SSB_lwr[is.finite(summary$SSB)],
    upr = summary$SSB_upr[is.finite(summary$SSB)],
    source_type = "official_machine_readable", source_reference = graphs_url,
    notes = "Spawning-stock biomass; the ICES SAG XML gives 95% confidence bounds for historical estimates. 2026 is an advice forecast, not a fitted historical year."
  ),
  new_output("mortality", "Fbar", summary$year[is.finite(summary$Fbar)],
    summary$Fbar[is.finite(summary$Fbar)], "per year",
    age_group = "2-6", lwr = summary$Fbar_lwr[is.finite(summary$Fbar)],
    upr = summary$Fbar_upr[is.finite(summary$Fbar)],
    source_type = "official_machine_readable", source_reference = graphs_url,
    notes = "Fishing mortality averaged over ages 2-6; the ICES SAG XML gives 95% confidence bounds. No Fbar forecast is reported for 2026."
  )
)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "ple.27.420", scientific_name = "Pleuronectes platessa",
  common_name = "North Sea plaice",
  area = "ICES Subarea 4 and Subdivision 20 (North Sea and Skagerrak)",
  region = "Greater North Sea", ocean = "Northeast Atlantic",
  notes = "Added from the official ICES assessment; this stock is not represented in the current Charbonneau-Keith database seed.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L, assessment_type = "annual_assessment",
  model_family = "SAM", model_version = "Official WGNSSK 2026 assessment",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graphs_url, model_url = NA_character_, repository_url = NA_character_,
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The official detailed assessment uses catch, biological inputs, and age-specific outputs through 2025.",
    "The 2026 ICES SAG values are advice forecasts and are stored separately from the fitted historical period.",
    "Survey index units and exact sampling fractions are not reported; quarter midpoints are used for timing."
  ), stringsAsFactors = FALSE
)

database <- file.path(root, "database")
stock_path <- file.path(database, "stocks.csv")
stock_existing <- read.csv(stock_path,
  colClasses = "character", na.strings = "",
  check.names = FALSE
)
if (any(stock_existing$stock_id == stock_id)) {
  stop("North Sea plaice stock already exists.", call. = FALSE)
}
paths <- file.path(database, c(
  "assessments.csv", "assumptions.csv",
  "inputs.csv", "outputs.csv"
))
rows <- list(assessment, assumptions, inputs, outputs)
for (i in seq_along(paths)) {
  key <- if (i == 2L) "assessment_id" else "assessment_id"
  append_rows(paths[[i]], rows[[i]], key, assessment_id)
}
if (!identical(names(stock_existing), names(stock))) {
  stop("Unexpected columns in stocks.csv.", call. = FALSE)
}
utils::write.table(stock, stock_path,
  sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
)

cat(
  "Added", nrow(inputs), "input rows and", nrow(outputs),
  "output rows for North Sea plaice.\n"
)
