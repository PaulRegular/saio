assessment_id <- "ices_saithe_north_sea_2026"
stock_id <- "ices_saithe_north_sea"
root <- "."
cache_dir <- file.path(root, "source_cache", "ices_saithe_north_sea_2026")
pdf_path <- file.path(cache_dir, "WGNSSK_2026.pdf")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to import the cached WGNSSK report tables.", call. = FALSE)
}
if (!file.exists(pdf_path)) {
  stop("The cached WGNSSK 2026 report is missing.", call. = FALSE)
}

report_url <- "https://doi.org/10.17895/ices.pub.32676345"
advice_url <- "https://doi.org/10.17895/ices.advice.30932291"
framework_url <- "https://doi.org/10.17895/ices.pub.25002470"
graphs_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22504"
pages <- pdftools::pdf_text(pdf_path)
all_lines <- unlist(strsplit(pages, "\n", fixed = TRUE), use.names = FALSE)

table_body <- function(table_id, page_range) {
  lines <- unlist(strsplit(pages[page_range], "\n", fixed = TRUE),
    use.names = FALSE
  )
  title <- paste0(
    "^\\s*Table\\s+", gsub(".", "[.]", table_id, fixed = TRUE),
    "[.]"
  )
  start <- grep(title, lines, perl = TRUE)
  if (length(start) != 1L) {
    stop("Expected one table caption for Table ", table_id, ".", call. = FALSE)
  }
  captions <- grep("^\\s*Table\\s+[0-9]+[.][0-9]+[.][0-9]+[.]",
    lines,
    perl = TRUE
  )
  following <- captions[captions > start]
  end <- if (length(following)) min(following) - 1L else length(lines)
  lines[seq.int(start + 1L, end)]
}

numeric_fields <- function(line) {
  suppressWarnings(as.numeric(strsplit(trimws(line), "[[:space:]]+",
    perl = TRUE
  )[[1L]]))
}

age_table <- function(table_id, page_range, expected_years, ages) {
  lines <- table_body(table_id, page_range)
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    fields <- numeric_fields(line)
    year <- as.integer(fields[[1L]])
    if (!year %in% expected_years) {
      return(NULL)
    }
    values <- fields[-1L]
    if (length(values) != length(ages) || anyNA(values)) {
      stop("Unexpected age columns in Table ", table_id,
        " for year ", year, ".",
        call. = FALSE
      )
    }
    data.frame(year = year, age = ages, value = values)
  })
  rows <- Filter(Negate(is.null), rows)
  out <- if (length(rows)) do.call(rbind, rows) else data.frame()
  if (!nrow(out) || anyDuplicated(out[c("year", "age")]) ||
    !setequal(unique(out$year), expected_years) || anyNA(out$value) ||
    any(!is.finite(out$value)) || any(out$value < 0)) {
    stop("Unexpected years or values in Table ", table_id, ".", call. = FALSE)
  }
  out
}

ages <- 3:10
years <- 1967:2025
catch <- age_table("14.3.5", 531:533, years, ages)
catch_weight <- age_table("14.3.8", 537:539, years, ages)
stock_weight <- age_table("14.3.11", 543:545, years, ages)
maturity <- age_table("14.3.12", 545:548, years, ages)
f_surface <- age_table("14.4.2", 555:557, years, 3:9)
n_surface <- age_table("14.4.3", 557:559, years, ages)

page_513_lines <- strsplit(pages[[513]], "\n", fixed = TRUE)[[1L]]
mortality_line <- grep("^\\s*Natural mortality\\s+", page_513_lines,
  value = TRUE, perl = TRUE
)
mortality_values <- if (length(mortality_line) == 1L) {
  as.numeric(strsplit(
    trimws(sub("^.*?Natural mortality\\s+", "", mortality_line,
      perl = TRUE
    )), "[[:space:]]+",
    perl = TRUE
  )[[1L]])
} else {
  numeric()
}
if (length(mortality_line) != 1L || length(mortality_values) != length(ages) ||
  anyNA(mortality_values)) {
  stop("Could not recover the published fixed M-at-age vector.", call. = FALSE)
}
natural_mortality <- mortality_values

index_lines <- table_body("14.3.13", 548:550)
index_lines <- index_lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", index_lines,
  perl = TRUE
)]
index_rows <- lapply(index_lines, function(line) {
  values <- numeric_fields(line)
  year <- as.integer(values[[1L]])
  if (year < 1992L || year > 2025L) {
    return(NULL)
  }
  if (!length(values) %in% c(7L, 8L) || anyNA(values)) {
    stop("Unexpected survey row in Table 14.3.13 for ", year, ".",
      call. = FALSE
    )
  }
  result <- data.frame(
    year = rep(year, 6L), age = 3:8, value = values[2:7],
    survey = "NS-IBTS Q3-Q4"
  )
  if (length(values) == 8L) {
    result <- rbind(
      result,
      data.frame(
        year = year, age = NA_integer_, value = values[[8L]],
        survey = "Combined commercial trawl CPUE"
      )
    )
  }
  result
})
index <- do.call(rbind, Filter(Negate(is.null), index_rows))
survey_index <- index[index$survey == "NS-IBTS Q3-Q4", , drop = FALSE]
cpue_index <- index[index$survey == "Combined commercial trawl CPUE", ,
  drop = FALSE
]
if (!setequal(unique(survey_index$year), 1992:2025) ||
  !setequal(unique(cpue_index$year), 2000:2025) ||
  anyNA(index$value) || any(!is.finite(index$value))) {
  stop("Unexpected survey-index coverage in Table 14.3.13.", call. = FALSE)
}

summary_lines <- table_body("14.6.1", 560:563)
summary_lines <- summary_lines[grepl("^\\s*(19|20)[0-9]{2}\\s+",
  summary_lines,
  perl = TRUE
)]
summary_rows <- lapply(summary_lines, function(line) {
  values <- numeric_fields(line)
  if (!length(values) || !values[[1L]] %in% 1967:2025) {
    return(NULL)
  }
  if (length(values) != 13L || anyNA(values)) {
    stop("Unexpected summary row in Table 14.6.1 for year ",
      values[[1L]], ".",
      call. = FALSE
    )
  }
  data.frame(
    year = as.integer(values[[1L]]),
    recruitment_lwr = values[[2L]], recruitment = values[[3L]],
    recruitment_upr = values[[4L]],
    ssb_lwr = values[[5L]], SSB = values[[6L]], ssb_upr = values[[7L]],
    fbar_lwr = values[[8L]], Fbar = values[[9L]], fbar_upr = values[[10L]],
    tsb_lwr = values[[11L]], TSB = values[[12L]], tsb_upr = values[[13L]]
  )
})
summary <- do.call(rbind, Filter(Negate(is.null), summary_rows))
if (!setequal(summary$year, 1967:2025) || anyNA(summary)) {
  stop("Unexpected summary-year coverage in Table 14.6.1.", call. = FALSE)
}

source_ref <- function(table, pages, report_pages = NULL) {
  paste0(
    "WGNSSK 2026, Table ", table, ", PDF pp. ", pages,
    if (!is.null(report_pages)) paste0(" (report pp. ", report_pages, ")")
  )
}
input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = NA_character_, survey = NA_character_,
                       sampling_time = NA_real_, source_reference,
                       transformation = "Transcribed from the rounded report table.",
                       notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = rep(basis, length.out = n), fleet = rep(fleet, length.out = n),
    survey = rep(survey, length.out = n), sex = NA_character_,
    region = NA_character_, season = NA_character_, year = year,
    year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = age, value = value, unit = unit,
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
    assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = survey, sex = NA_character_,
    region = NA_character_, season = NA_character_, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
new_output <- function(type, measure, year, value, unit, age = NA_integer_,
                       age_group = NA_character_, lwr = NA_real_, upr = NA_real_,
                       source_reference, notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = year,
    age = rep(age, length.out = n), age_group = rep(age_group, length.out = n),
    value = value, se = NA_real_, lwr = rep(lwr, length.out = n),
    upr = rep(upr, length.out = n), unit = rep(unit, length.out = n),
    source_type = "official_table", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
surface_output <- function(data, type, measure, unit, table,
                           plus_age = 10L, plus_label = "10+") {
  new_output(
    type, measure, data$year, data$value, unit,
    age = data$age,
    age_group = ifelse(data$age == plus_age, plus_label, NA_character_),
    source_reference = source_ref(
      table,
      switch(table,
        "14.4.2" = "555-557",
        "14.4.3" = "557-559"
      ),
      switch(table,
        "14.4.2" = "539-541",
        "14.4.3" = "541-543"
      )
    ),
    notes = paste0(
      "Age ", plus_age, " is the ", plus_label,
      " group; values are rounded as published."
    )
  )
}

inputs <- rbind(
  input_rows("catch", "numbers_at_age", "numbers", catch$year, catch$age,
    catch$value, "thousand fish",
    fleet = "Commercial catch",
    source_reference = source_ref("14.3.5", "531-533", "515-517"),
    notes = "Total catch-at-age used in the assessment; age 10 is 10+."
  ),
  input_rows("catch_weight", "weight_at_age", "kg_per_fish",
    catch_weight$year, catch_weight$age, catch_weight$value,
    "kg per fish",
    fleet = "Commercial catch",
    source_reference = source_ref("14.3.8", "537-539", "521-523"),
    notes = "Total catch weight-at-age; age 10 is 10+."
  ),
  input_rows("weight", "weight_at_age", "kg_per_fish",
    stock_weight$year, stock_weight$age, stock_weight$value,
    "kg per fish",
    source_reference = source_ref("14.3.11", "543-545", "527-529"),
    notes = "Stock weight-at-age used in the assessment; age 10 is 10+."
  ),
  input_rows("maturity", "maturity_at_age", "proportion",
    maturity$year, maturity$age, maturity$value, "proportion",
    source_reference = source_ref("14.3.12", "545-548", "529-532"),
    notes = "Year-specific model-based maturity; the 2026 intermediate-year forecast row is excluded."
  ),
  input_rows("M", "natural_mortality_at_age", "per_year", NA_integer_,
    ages, natural_mortality, "per year",
    source_reference = "WGNSSK 2026, Section 14.3.3, PDF p. 513 (report p. 497)",
    transformation = "Transcribed from the fixed age-specific natural mortality vector.",
    notes = "Time-invariant M from Lorenzen (1996), scaled to M at age 9 of about 0.2; age 10 is 10+."
  ),
  input_rows("index", "numbers_at_age", "index_scale",
    survey_index$year, survey_index$age, survey_index$value,
    "survey index (unit unresolved)",
    survey = "NS-IBTS Q3-Q4",
    source_reference = source_ref("14.3.13", "548-550", "532-534"),
    transformation = "Transcribed from the annual age-specific delta-GAM survey-index table.",
    notes = "Combined Q3-Q4 research survey index, ages 3-8. Numerical scale is relative; no abundance unit is reported."
  ),
  input_rows("index", "relative_biomass_index", "index_scale",
    cpue_index$year, cpue_index$age, cpue_index$value,
    "relative CPUE index",
    survey = "Combined commercial trawl CPUE",
    source_reference = source_ref("14.3.13", "548-550", "532-534"),
    transformation = "Transcribed from the annual standardized commercial CPUE table.",
    notes = "The annual relative CPUE index is tuned to exploitable biomass within SAM and is not an absolute biomass observation."
  )
)

assumptions <- do.call(rbind, list(
  new_assumption("assessment", "model_family", "SAM", report_url),
  new_assumption("assessment", "assessment_key", "22504", graphs_url),
  new_assumption(
    "assessment", "model_configuration_date", "2024-03-12",
    source_ref("14.4.1", "550-554", "534-538"),
    "The configuration reproduced in the 2026 report is timestamped 12 March 2024; no separate 2026 native model bundle was recovered."
  ),
  new_assumption(
    "population", "model_years", "1967-2025",
    source_ref("14.3.5", "531-533", "515-517")
  ),
  new_assumption(
    "population", "model_ages", "3-10; age 10 is the plus group",
    source_ref("14.4.1", "550-554", "534-538")
  ),
  new_assumption(
    "population", "recruitment_age", "3",
    source_ref("14.6.1", "560-562", "544-546")
  ),
  new_assumption(
    "population", "Fbar_ages", "4-7",
    source_ref("14.4.1", "550-554", "534-538")
  ),
  new_assumption(
    "N", "recruitment_process", "Random walk",
    source_ref("14.4.1", "552-554", "536-538"),
    "SAM stockRecruitmentModelCode is 0."
  ),
  new_assumption(
    "N", "variance_sharing_keys", "Age 3 separate; ages 4-10+ shared",
    source_ref("14.4.1", "551", "535"),
    "SAM keyVarLogN values are 0 1 1 1 1 1 1 1."
  ),
  new_assumption(
    "F", "age_state_coupling", "Ages 3-8 separate; ages 9 and 10+ share",
    source_ref("14.4.1", "550-551", "534-535"),
    "SAM keyLogFsta values are 0 1 2 3 4 5 6 6."
  ),
  new_assumption(
    "F", "age_correlation", "AR(1)",
    source_ref("14.4.1", "550-551", "534-535"),
    "SAM corFlag is 2."
  ),
  new_assumption(
    "F", "process_variance_sharing", "Ages 3, 4, and 5 separate; ages 6-10+ shared",
    source_ref("14.4.1", "551", "535"),
    "SAM keyVarF values are 0 1 2 3 3 3 3 3."
  ),
  new_assumption(
    "catch", "observation_likelihood", "Lognormal",
    source_ref("14.4.1", "552", "536")
  ),
  new_assumption(
    "index", "observation_likelihood", "Lognormal",
    source_ref("14.4.1", "552", "536")
  ),
  new_assumption(
    "catch", "observation_correlation", "AR(1) across ages",
    source_ref("14.4.1", "551-552", "535-536"),
    "The printed obsCorStruct entries are AR, AR, ID; the report does not label fleet rows in that setting block."
  ),
  new_assumption(
    "index", "observation_correlation",
    "AR(1) across ages for NS-IBTS Q3-Q4; independent for CPUE",
    source_ref("14.4.1", "551-552", "535-536"),
    "The printed obsCorStruct entries are AR, AR, ID; fleet order is catch, age-specific survey, CPUE."
  ),
  new_assumption(
    "index", "survey_series", "NS-IBTS Q3-Q4 ages 3-8; combined commercial CPUE",
    source_ref("14.3.13", "548-550", "532-534")
  ),
  new_assumption(
    "index", "sampling_time", "Exact 2026 fractions unresolved",
    source_ref("14.3.13", "548-550", "532-534"),
    "The report identifies Q3-Q4 and an annual commercial CPUE index, but does not provide exact sampling fractions. The cached 2024 native data object has 0.730 and 0.525, respectively; these values are not assumed to be verified for 2026."
  ),
  new_assumption(
    "index", "cpue_measurement", "Standardized annual relative index tuned to exploitable biomass",
    source_ref("14.3.13", "548-550", "532-534"),
    "This is an aggregate biomass-targeted index, not an absolute biomass observation."
  ),
  new_assumption(
    "M", "natural_mortality", paste(natural_mortality, collapse = ", "),
    "WGNSSK 2026, Section 14.3.3, PDF p. 513 (report p. 497)",
    "Fixed at age, based on mean stock weights under Lorenzen (1996), scaled to age 9 M of about 0.2."
  ),
  new_assumption(
    "weight", "stock_weight", "Annual stock weight-at-age used as known",
    source_ref("14.3.11", "543-545", "527-529"),
    "For 2003-2025, model-based estimates use survey data only; 1967-2002 values are catch weights scaled by estimated ratios from 2003-2022."
  ),
  new_assumption(
    "weight", "catch_weight", "Annual catch weight-at-age used as known",
    source_ref("14.3.8", "537-539", "521-523")
  ),
  new_assumption(
    "maturity", "maturity_model", "Annual model-based maturity-at-age used as known",
    source_ref("14.3.12", "545-548", "529-532")
  ),
  new_assumption(
    "source", "native_2026_model_object", "Not recovered",
    report_url,
    "The report contains numerical input and output tables; the native final 2026 SAM fit/data object was not located."
  )
))

age_group <- function(age) ifelse(age == 10L, "10+", NA_character_)
summary_outputs <- rbind(
  new_output("recruitment", "recruitment", summary$year, summary$recruitment,
    "thousand fish",
    age = 3L, age_group = "age 3",
    lwr = summary$recruitment_lwr, upr = summary$recruitment_upr,
    source_reference = source_ref("14.6.1", "560-563", "544-547"),
    notes = "Recruitment at age 3; lower and upper values are the published 95% confidence limits."
  ),
  new_output("biomass", "SSB", summary$year, summary$SSB, "tonnes",
    lwr = summary$ssb_lwr, upr = summary$ssb_upr,
    source_reference = source_ref("14.6.1", "560-563", "544-547"),
    notes = "Spawning-stock biomass; lower and upper values are the published 95% confidence limits."
  ),
  new_output("mortality", "Fbar", summary$year, summary$Fbar, "per year",
    age_group = "4-7", lwr = summary$fbar_lwr, upr = summary$fbar_upr,
    source_reference = source_ref("14.6.1", "560-563", "544-547"),
    notes = "Fishing mortality averaged over ages 4-7; lower and upper values are the published 95% confidence limits."
  ),
  new_output("biomass", "total_biomass", summary$year, summary$TSB, "tonnes",
    lwr = summary$tsb_lwr, upr = summary$tsb_upr,
    source_reference = source_ref("14.6.1", "560-563", "544-547"),
    notes = "Total-stock biomass; lower and upper values are the published 95% confidence limits."
  )
)
forecast_outputs <- rbind(
  new_output("recruitment", "recruitment", 2026L, 96955,
    "thousand fish",
    age = 3L, age_group = "age 3",
    source_reference = source_ref("14.8.1", "564", "548"),
    notes = "2026 geometric-mean recruitment assumption; forecast, no interval reported."
  ),
  new_output("biomass", "SSB", 2026L, 115676, "tonnes",
    source_reference = source_ref("14.6.1", "563", "547"),
    notes = "2026 short-term forecast; no interval reported."
  ),
  new_output("mortality", "Fbar", 2026L, 0.321, "per year",
    age_group = "4-7",
    source_reference = source_ref("14.8.1", "564", "548"),
    notes = "2026 intermediate-year Fbar under the TAC constraint; no interval reported."
  ),
  new_output("biomass", "total_biomass", 2026L, 199092, "tonnes",
    source_reference = source_ref("14.6.1", "563", "547"),
    notes = "2026 short-term forecast; no interval reported."
  )
)
outputs <- rbind(
  surface_output(
    n_surface, "population", "numbers_at_age", "thousand fish",
    "14.4.3"
  ),
  surface_output(f_surface, "mortality", "fishing_mortality_at_age",
    "per year", "14.4.2",
    plus_age = 9L, plus_label = "9+"
  ),
  summary_outputs,
  forecast_outputs
)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "pok.27.3a46", scientific_name = "Pollachius virens",
  common_name = "North Sea saithe",
  area = "Subareas 4 and 6 and Division 3.a",
  region = "Greater North Sea and Celtic Seas", ocean = "Northeast Atlantic",
  notes = "ICES stock code pok.27.3a46.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L, assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "WGNSSK 2026 official assessment; configuration table timestamped 2024-03-12",
  is_current = TRUE, is_applied = TRUE, framework_year = 2024L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graphs_url, model_url = NA_character_, repository_url = NA_character_,
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The official 2026 assessment has report-published inputs, assumptions, and N/F-at-age surfaces.",
    "The report reproduces a SAM configuration timestamped 2024; the final native 2026 fit/data object was not located.",
    "Exact current-run sampling fractions and uncertainty for age-specific N/F are unavailable."
  ),
  stringsAsFactors = FALSE
)

database <- file.path(root, "database")
stock_path <- file.path(database, "stocks.csv")
stock_existing <- read.csv(stock_path,
  colClasses = "character", na.strings = "",
  check.names = FALSE
)
if (any(stock_existing$stock_id == stock_id)) {
  stop("North Sea saithe stock already exists.", call. = FALSE)
}
for (path in file.path(database, c(
  "assessments.csv", "assumptions.csv",
  "inputs.csv", "outputs.csv"
))) {
  existing <- read.csv(path,
    colClasses = "character", na.strings = "",
    check.names = FALSE
  )
  if (!identical(
    names(existing),
    names(switch(basename(path),
      "assessments.csv" = assessment,
      "assumptions.csv" = assumptions,
      "inputs.csv" = inputs,
      "outputs.csv" = outputs
    ))
  )) {
    stop("Unexpected columns in ", basename(path), ".", call. = FALSE)
  }
  if ("assessment_id" %in% names(existing) &&
    any(existing$assessment_id == assessment_id, na.rm = TRUE)) {
    stop("North Sea saithe assessment already exists in ", basename(path), ".",
      call. = FALSE
    )
  }
}
if (!identical(names(stock_existing), names(stock))) {
  stop("Unexpected columns in stocks.csv.", call. = FALSE)
}
append_rows <- function(path, rows) {
  utils::write.table(rows, path,
    sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE,
    na = ""
  )
}
append_rows(file.path(database, "assessments.csv"), assessment)
append_rows(file.path(database, "assumptions.csv"), assumptions)
append_rows(file.path(database, "inputs.csv"), inputs)
append_rows(file.path(database, "outputs.csv"), outputs)
append_rows(stock_path, stock)

cat("Added ", nrow(inputs), " inputs, ", nrow(assumptions),
  " assumptions, and ", nrow(outputs), " outputs for North Sea saithe.\n",
  sep = ""
)
