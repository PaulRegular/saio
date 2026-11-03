assessment_id <- "ices_sprat_baltic_2026"
stock_id <- "ices_sprat_baltic"
root <- "."
cache <- file.path(root, "source_cache", assessment_id)
report_path <- file.path(cache, "wgbfas_2026_report.pdf")
text_path <- file.path(cache, "wgbfas_2026_report.txt")
report_url <- "https://doi.org/10.17895/ices.pub.32455056"
if (!file.exists(text_path)) {
  if (!file.exists(report_path) || !requireNamespace("pdftools", quietly = TRUE)) {
    stop("Cache the WGBFAS 2026 report and extracted text before importing.",
      call. = FALSE
    )
  }
  writeLines(paste(pdftools::pdf_text(report_path), collapse = "\n"),
    text_path,
    useBytes = TRUE
  )
}
report_lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")

table_lines <- function(table_id) {
  caption <- paste0("^\\s*Table\\s+", gsub(".", "[.]", table_id,
    fixed = TRUE
  ), "([.]|\\s)")
  start <- grep(caption, report_lines, perl = TRUE)
  if (length(start) != 1L) stop("Expected one report table: ", table_id)
  headings <- grep("^\\s*Table\\s+7[.][0-9]+([.]|\\s)", report_lines,
    perl = TRUE
  )
  following <- headings[headings > start]
  end <- if (length(following)) min(following) - 1L else length(report_lines)
  report_lines[seq.int(start + 1L, end)]
}

table_fields <- function(line) {
  fields <- strsplit(trimws(line), "[[:space:]]{2,}", perl = TRUE)[[1L]]
  gsub("[[:space:]]", "", fields)
}

age_table <- function(table_id, age_count = 8L, has_effort = FALSE,
                      years = NULL) {
  lines <- table_lines(table_id)
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\*?(\\s|$)", lines,
    perl = TRUE
  )]
  rows <- lapply(lines, function(line) {
    fields <- table_fields(line)
    year <- as.integer(sub("\\*.*$", "", fields[[1L]]))
    fields <- fields[-1L]
    if (has_effort) fields <- fields[-1L]
    if (length(fields) != age_count) {
      stop(
        "Unexpected age count in Table ", table_id, ", year ", year,
        ": ", length(fields), "; row: ", line
      )
    }
    values <- suppressWarnings(as.numeric(fields))
    data.frame(year = year, age = seq_len(age_count), value = values)
  })
  if (!length(rows)) stop("No annual records found in Table ", table_id)
  out <- do.call(rbind, rows)
  if (anyDuplicated(out[c("year", "age")])) {
    stop("Duplicate year-age records in Table ", table_id)
  }
  if (!is.null(years) && !setequal(unique(out$year), years)) {
    stop("Unexpected year coverage in Table ", table_id)
  }
  out
}

summary_table <- function() {
  lines <- table_lines("7.17")
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    fields <- table_fields(line)
    year <- as.integer(fields[[1L]])
    values <- suppressWarnings(as.numeric(fields[-1L]))
    if (length(values) > 9L) stop("Unexpected Table 7.17 columns.")
    values <- c(values, rep(NA_real_, 9L - length(values)))
    data.frame(
      year = year, recruitment = values[1L],
      recruitment_lwr = values[2L], recruitment_upr = values[3L],
      SSB = values[4L], SSB_lwr = values[5L], SSB_upr = values[6L],
      Fbar = values[7L], Fbar_lwr = values[8L], Fbar_upr = values[9L]
    )
  })
  out <- do.call(rbind, rows)
  if (!setequal(out$year, 1974:2026)) stop("Unexpected Table 7.17 years.")
  out[order(out$year), ]
}

new_input <- function(type, measure, basis, year, age, value, unit,
                      fleet = NA_character_, survey = NA_character_,
                      region = NA_character_, season = NA_character_,
                      sampling_time = NA_real_, year_basis = "calendar_year",
                      source_reference, transformation = "Transcribed from the official assessment report.",
                      notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = rep(fleet, length.out = n),
    survey = rep(survey, length.out = n), sex = NA_character_,
    region = rep(region, length.out = n), season = rep(season, length.out = n),
    year = year, year_basis = rep(year_basis, length.out = n), age = age,
    value = value, unit = unit,
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
                       source_reference, notes = "",
                       source_type = "official_table") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = year,
    age = rep(age, length.out = n), age_group = rep(age_group, length.out = n),
    value = value, se = NA_real_, lwr = rep(lwr, length.out = n),
    upr = rep(upr, length.out = n), unit = unit,
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

catch <- age_table("7.6", years = 1974:2025)
weights <- age_table("7.7", years = 1974:2025)
natural_mortality <- age_table("7.8", years = 1974:2025)
maturity_values <- c(0.17, 0.93, rep(1, 6))
maturity <- data.frame(
  year = NA_integer_, age = 1:8,
  value = maturity_values
)

inputs <- list(
  new_input("catch", "numbers_at_age", "numbers", catch$year, catch$age,
    catch$value, "thousand fish",
    fleet = "Total catch",
    source_reference = paste(report_url, "Table 7.6"),
    notes = "Age 8 is the 8+ group."
  ),
  new_input("catch_weight", "weight_at_age", "kg_per_fish", weights$year,
    weights$age, weights$value, "g per fish",
    fleet = "Total catch",
    source_reference = paste(report_url, "Table 7.7"),
    notes = "Reported catch weights are also assumed for stock weight."
  ),
  new_input("weight", "weight_at_age", "kg_per_fish", weights$year,
    weights$age, weights$value, "g per fish",
    source_reference = paste(report_url, "Table 7.7"),
    transformation = "The official assessment assumes stock weights equal catch weights.",
    notes = "Annual stock weights are the same source values as catch weights; age 8 is 8+."
  ),
  new_input("M", "natural_mortality_at_age", "per_year",
    natural_mortality$year, natural_mortality$age,
    natural_mortality$value, "per year",
    source_reference = paste(report_url, "Table 7.8"),
    notes = "M varies by year and age due to cod predation; 2025 values are assumed equal to 2024."
  ),
  new_input("maturity", "maturity_at_age", "proportion", NA_integer_,
    maturity$age, maturity$value, "proportion",
    year_basis = NA_character_,
    source_reference = paste(report_url, "Table 7.9"),
    notes = "The same age-specific maturity values are used throughout 1974-2025; age 8 is 8+."
  ),
  new_input("biology", "fraction_M_before_spawning", "proportion",
    NA_integer_, 1:8, rep(0.4, 8), "proportion",
    year_basis = NA_character_, source_reference = paste(report_url, "Table 7.10"),
    notes = "The official assessment assigns 40% of M to the period before spawning."
  ),
  new_input("biology", "fraction_F_before_spawning", "proportion",
    NA_integer_, 1:8, rep(0.4, 8), "proportion",
    year_basis = NA_character_, source_reference = paste(report_url, "Table 7.11"),
    notes = "The official assessment assigns 40% of F to the period before spawning."
  )
)

survey_specs <- list(
  list(
    table = "7.12", survey = "BIAS_October_SD22_29_32_recent",
    fleet = "Fleet 1", season = "October", time = 0.8,
    region = "Subdivisions 22-29 and 32",
    years = 2000:2025, dropped = c(2001:2005, 2008), ages = 1:8,
    note = "October BIAS acoustic abundance at age; gaps reflect unavailable observations."
  ),
  list(
    table = "7.13", survey = "BIAS_October_SD22_29_early",
    fleet = "Fleet 2", season = "October", time = 0.8,
    region = "Subdivisions 22-29",
    years = 1991:2008, dropped = c(1993, 1995, 1997, 2000, 2006, 2007),
    ages = 1:8,
    note = "October BIAS acoustic abundance at age; low-coverage years and years overlapping fleet 1 were excluded."
  ),
  list(
    table = "7.14", survey = "BASS_May_SD24_26_28",
    fleet = "Fleet 3", season = "May", time = 0.375,
    region = "Subdivisions 24-26 and 28",
    years = 2001:2025, dropped = 2016, ages = 1:8,
    note = "May BASS acoustic abundance at age; 2016 was excluded because only about half of planned areas were covered."
  ),
  list(
    table = "7.15", survey = "BIAS_October_age0_shifted_to_age1",
    fleet = "Fleet 4", season = "October", time = 0.8,
    region = "Subdivisions 22-29 and 32",
    years = 2010:2026, dropped = integer(), ages = 1L,
    has_effort = TRUE,
    note = "Age-0 acoustic series is reported already shifted to age 1 in the following year. The 2026 row supports the intermediate-year recruitment estimate."
  )
)

for (spec in survey_specs) {
  x <- age_table(spec$table,
    age_count = length(spec$ages),
    has_effort = TRUE, years = spec$years
  )
  x <- x[!is.na(x$value) & !x$year %in% spec$dropped, , drop = FALSE]
  inputs[[length(inputs) + 1L]] <- new_input(
    "index", "numbers_at_age", "numbers", x$year, spec$ages[x$age],
    x$value, "thousand fish",
    fleet = spec$fleet, survey = spec$survey,
    region = spec$region, season = spec$season, sampling_time = spec$time,
    source_reference = paste(report_url, "Table", spec$table),
    notes = paste(spec$note, "Age 8 is 8+ where present.")
  )
}
inputs <- do.call(rbind, inputs)

assumptions <- do.call(rbind, list(
  new_assumption("assessment", "assessment_type", "Annual full assessment", report_url),
  new_assumption("assessment", "model_family", "SAM", report_url),
  new_assumption(
    "population", "fitted_years", "1974-2025", paste(report_url, "section 7.4"),
    "The 2026 intermediate year is reported separately."
  ),
  new_assumption("population", "reported_estimate_years", "1974-2026", paste(report_url, "Tables 7.17-7.19")),
  new_assumption("population", "model_ages", "1-8; age 8 is a plus group", paste(report_url, "Table 7.16")),
  new_assumption("population", "recruitment_age", "1", paste(report_url, "Table 7.16")),
  new_assumption(
    "population", "intermediate_year", "2026", report_url,
    "The 2025 year class is estimated from one shifted age-0 acoustic observation; 2026 SSB uses an F assumption and is not a full catch-data year."
  ),
  new_assumption("N", "recruitment_process", "Random walk", paste(report_url, "section 7.4.1")),
  new_assumption("N", "process_variance_sharing", "Age 1 separate; ages 2-8 shared", paste(report_url, "Table 7.16")),
  new_assumption("F", "age_pattern", "Ages 1-7 independent; age 8 shares age 7", paste(report_url, "Table 7.16")),
  new_assumption(
    "F", "age_correlation", "AR(1)", paste(report_url, "Table 7.16"),
    "SAM corFlag is 2."
  ),
  new_assumption("F", "Fbar_ages", "3-5", paste(report_url, "Table 7.16")),
  new_assumption(
    "M", "natural_mortality", "Annual age-specific M varies due to cod predation", paste(report_url, "Table 7.8"),
    "M for 2025 is assumed equal to 2024."
  ),
  new_assumption("weight", "stock_weights", "Equal to catch weights", paste(report_url, "section 7.2.2")),
  new_assumption(
    "maturity", "maturity_at_age", "0.17, 0.93, then 1.0 for ages 3-8", paste(report_url, "Table 7.9"),
    "Constant throughout the time series; age 8 is 8+."
  ),
  new_assumption("spawning", "proportion_M_before_spawning", "0.4 at all ages", paste(report_url, "Table 7.10")),
  new_assumption("spawning", "proportion_F_before_spawning", "0.4 at all ages", paste(report_url, "Table 7.11")),
  new_assumption("index", "fleet_count", "Four tuning fleets", paste(report_url, "section 7.3")),
  new_assumption("index", "observation_covariance", "Independent across ages (ID) for each fleet", paste(report_url, "section 7.4.1")),
  new_assumption("index", "q_age_pattern", "Fleet-specific q at ages 1-5; ages 6-8 share age-6 q", paste(report_url, "section 7.4.1; Table 7.16")),
  new_assumption("index", "q_year_class_effect", "Catchability depends on year-class strength at age 1 for all four fleets", paste(report_url, "section 7.4.1")),
  new_assumption(
    "index", "poor_coverage_exclusions", "BIAS 1993, 1995, 1997; BASS 2016", paste(report_url, "section 7.3"),
    "The report also excludes overlapping early BIAS years from fleet 2."
  ),
  new_assumption(
    "index", "sampling_time", "October 0.8; May 0.375", report_url,
    "Approximate within-year timing inferred from the reported survey months."
  )
))

summary <- summary_table()
n_surface <- age_table("7.18", years = 1974:2026)
f_surface <- age_table("7.19", years = 1974:2025)
total_numbers <- aggregate(value ~ year, n_surface, sum)
output_reference <- function(table) paste(report_url, "Table", table)
outputs <- rbind(
  new_output("mortality", "natural_mortality_at_age",
    natural_mortality$year, natural_mortality$value, "per year",
    age = natural_mortality$age,
    age_group = ifelse(natural_mortality$age == 8L, "8+", NA_character_),
    source_reference = output_reference("7.8"),
    notes = "Annual age-specific M used as an input to SAM; these values are not estimated within the sprat SAM fit."
  ),
  new_output("population", "numbers_at_age", n_surface$year,
    n_surface$value, "million fish",
    age = n_surface$age,
    age_group = ifelse(n_surface$age == 8L, "8+", NA_character_),
    source_reference = output_reference("7.18"),
    notes = "SAM point estimates; age 8 is the 8+ group, and 2026 is the intermediate-year estimate."
  ),
  new_output("population", "total_numbers", total_numbers$year,
    total_numbers$value, "million fish",
    source_reference = output_reference("7.18"),
    notes = paste(
      "Derived by summing reported numbers-at-age for ages 1-8; age 8 is the 8+ group.",
      "Values inherit report rounding; 2026 is an intermediate-year estimate."
    ),
    source_type = "derived_source_output"
  ),
  new_output("mortality", "fishing_mortality_at_age", f_surface$year,
    f_surface$value, "per year",
    age = f_surface$age,
    age_group = ifelse(f_surface$age == 8L, "8+", NA_character_),
    source_reference = output_reference("7.19"),
    notes = "SAM point estimates; age 8 is the 8+ group, and 2026 is the intermediate-year estimate."
  ),
  new_output("recruitment", "recruitment", summary$year,
    summary$recruitment, "million fish",
    age = 1L,
    lwr = summary$recruitment_lwr, upr = summary$recruitment_upr,
    source_reference = output_reference("7.17"),
    notes = "Age-1 recruitment estimate and reported lower/upper bounds; confidence level is not stated in the chapter. The 2026 intermediate estimate represents the 2025 year class and is not used for advice."
  ),
  new_output("biomass", "SSB", summary$year, summary$SSB, "tonnes",
    lwr = summary$SSB_lwr, upr = summary$SSB_upr,
    source_reference = output_reference("7.17"),
    notes = "Spawning-stock biomass estimate and reported lower/upper bounds; confidence level is not stated in the chapter. 2026 is an intermediate-year estimate."
  ),
  new_output("mortality", "Fbar", summary$year[!is.na(summary$Fbar)],
    summary$Fbar[!is.na(summary$Fbar)], "per year",
    age_group = "3-5",
    lwr = summary$Fbar_lwr[!is.na(summary$Fbar)],
    upr = summary$Fbar_upr[!is.na(summary$Fbar)],
    source_reference = output_reference("7.17"),
    notes = "Fbar over ages 3-5 with reported lower/upper bounds; confidence level is not stated in the chapter. 2026 Fbar is not reported."
  )
)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "spr.27.22-32", scientific_name = "Sprattus sprattus",
  common_name = "Baltic sprat", area = "ICES subdivisions 22-32",
  region = "Baltic Sea", ocean = "Northeast Atlantic",
  notes = "Age-structured SAM assessment; age 8 is the plus group.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L, assessment_type = "annual_assessment",
  model_family = "SAM", model_version = "Official 2026 WGBFAS assessment",
  is_current = TRUE, is_applied = TRUE, framework_year = 2023L,
  assessment_url = report_url,
  framework_url = NA_character_,
  data_url = "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22378",
  model_url = NA_character_, repository_url = NA_character_,
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "partial",
  notes = paste(
    "Official 2026 assessment; catch and full input series are through 2025.",
    "The reported 2026 values are intermediate-year estimates, with recruitment informed by the shifted age-0 acoustic series.",
    "Age-specific N/F and summary intervals are transcribed from the report; fitted q estimates, predictions, and age-specific uncertainty are not tabulated."
  ), stringsAsFactors = FALSE
)

database <- file.path(root, "database")
append_rows(file.path(database, "stocks.csv"), stock, "stock_id", stock_id)
append_rows(
  file.path(database, "assessments.csv"), assessment,
  "assessment_id", assessment_id
)
append_rows(
  file.path(database, "assumptions.csv"), assumptions,
  "assessment_id", assessment_id
)
append_rows(
  file.path(database, "inputs.csv"), inputs,
  "assessment_id", assessment_id
)
append_rows(
  file.path(database, "outputs.csv"), outputs,
  "assessment_id", assessment_id
)
