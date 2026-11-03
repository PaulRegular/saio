root <- "."
cache_dir <- file.path(root, "source_cache", "nefsc_atlantic_mackerel_2018")
pdf_path <- file.path(cache_dir, "assessment.pdf")
assessment_id <- "nefsc_atlantic_mackerel_2018"
summary_id <- "nefsc_atlantic_mackerel_2025"
stock_id <- "nefsc_atlantic_mackerel"
report_url <- "https://repository.library.noaa.gov/view/noaa/23690/noaa_23690_DS1.pdf"
summary_url <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php"

if (!requireNamespace("pdftools", quietly = TRUE)) stop("Install pdftools to import the cached SAW-64 tables.", call. = FALSE)
if (!file.exists(pdf_path)) stop("The cached 2018 assessment PDF is missing.", call. = FALSE)

db <- file.path(root, "database")
paths <- setNames(
  file.path(db, paste0(c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE, check.names = FALSE)
stocks <- read_db("stocks")
assessments <- read_db("assessments")
if (stock_id %in% stocks$stock_id || any(assessments$assessment_id %in% c(assessment_id, summary_id))) {
  stop("Atlantic mackerel records already exist in the database.", call. = FALSE)
}

pages <- pdftools::pdf_text(pdf_path)
page_text <- function(id, caption) {
  base <- which(grepl(caption, pages, perl = TRUE))
  continued_pattern <- paste0("(?m)^\\s*Table ", id, "[, ]*(contd\\.?|continued)\\b")
  continued <- which(grepl(continued_pattern, pages, perl = TRUE))
  selected <- sort(unique(c(base, continued)))
  if (!length(base)) stop("Could not locate Table ", id, " in the cached report.", call. = FALSE)
  unlist(lapply(selected, function(page) {
    lines <- strsplit(pages[[page]], "\\n", perl = TRUE)[[1L]]
    start <- grep(paste0("^\\s*Table ", id, "([.:,]|\\s+(contd\\.?|continued))"), lines, perl = TRUE)
    if (!length(start)) stop("Could not locate Table ", id, " on PDF page ", page, ".", call. = FALSE)
    following <- grep("^\\s*Table A[0-9]+[.:]", lines, perl = TRUE)
    following <- following[following > start[[1L]]]
    end <- if (length(following)) min(following) - 1L else length(lines)
    lines[seq.int(start[[1L]], end)]
  }), use.names = FALSE)
}
year_rows <- function(lines, table_id, fields, years) {
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    tokens <- strsplit(gsub(",", "", trimws(line)), "[[:space:]]+", perl = TRUE)[[1L]]
    values <- suppressWarnings(as.numeric(tokens))
    if (!length(values) || is.na(values[[1L]]) || !values[[1L]] %in% years) {
      return(NULL)
    }
    if (length(values) != fields || anyNA(values)) {
      stop("Unexpected row width in Table ", table_id, ": ", trimws(line), call. = FALSE)
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

years <- 1968:2016
ages <- 1:10
maturity <- age_table("A4", "(?m)^\\s*Table A4:", 11L, years)
catch <- age_table("A28", "(?m)^\\s*Table A28:", 11L, years)
weights <- age_table("A33", "(?m)^\\s*Table A33:", 11L, years)
albatross <- age_table("A38", "(?m)^\\s*Table A38:", 11L, 1974:2008)
bigelow <- age_table("A39", "(?m)^\\s*Table A39:", 11L, 2009:2016)
summary <- age_table("A42", "(?m)^\\s*Table A42:", 5L, years)
n_at_age <- age_table("A43", "(?m)^\\s*Table A43:", 11L, years)
f_at_age <- age_table("A45", "(?m)^\\s*Table A45:", 11L, years)

egg_lines <- page_text("A40", "(?m)^\\s*Table A40:")
egg_lines <- egg_lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", egg_lines, perl = TRUE)]
egg_rows <- lapply(egg_lines, function(line) {
  starts <- gregexpr("[0-9][0-9,]*(\\.[0-9]+)?([Ee][+-]?[0-9]+)?", line, perl = TRUE)[[1L]]
  if (starts[[1L]] < 0L) {
    return(NULL)
  }
  tokens <- regmatches(line, list(starts))[[1L]]
  year <- as.integer(tokens[[1L]])
  if (!year %in% years) {
    return(NULL)
  }
  combined_ssb <- which(starts >= 37L & starts < 50L)
  if (length(combined_ssb) > 1L) stop("Ambiguous combined SSB cell in Table A40: ", trimws(line), call. = FALSE)
  if (!length(combined_ssb)) {
    return(NULL)
  }
  c(year, as.numeric(gsub(",", "", tokens[[combined_ssb[[1L]]]])))
})
egg_rows <- Filter(Negate(is.null), egg_rows)
egg_ssb <- do.call(rbind, egg_rows)
if (is.null(egg_ssb) || anyDuplicated(egg_ssb[, 1L])) stop("Could not parse combined SSB rows in Table A40.", call. = FALSE)

source_name <- "64th SAW 2018 Atlantic mackerel assessment, NEFSC Reference Document 18-06"
add_age_input <- function(type, measure, basis, fleet, survey, input_years, input_ages,
                          values, unit, reference, notes = "", transformation = "",
                          sampling_time = NA_real_, source_type = "official_table") {
  grid <- expand.grid(year = input_years, age = input_ages)
  grid$value <- as.vector(values[, -1L, drop = FALSE])
  if (nrow(grid) != length(grid$value)) stop("Input dimensions do not match the year-age grid.", call. = FALSE)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = "", season = "",
    year = grid$year, year_basis = ifelse(is.na(grid$year), "", "calendar_year"), age = grid$age,
    value = grid$value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = reference,
    transformation = transformation, notes = notes,
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = NA_real_, stringsAsFactors = FALSE
  )
}
add_aggregate_input <- function(measure, basis, survey, input_years, values, unit, reference, notes = "") {
  data.frame(
    assessment_id = assessment_id, type = "index", measure = measure, basis = basis,
    fleet = "", survey = survey, sex = "", region = "", season = "",
    year = input_years, year_basis = "calendar_year", age = NA_real_, value = values,
    unit = unit, sampling_time = NA_real_, source_type = "official_table",
    source_reference = reference, transformation = "", notes = notes,
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = NA_real_, stringsAsFactors = FALSE
  )
}
index_rows <- rbind(
  add_age_input("index", "numbers_at_age", "numbers", "", "NEFSC Albatross spring trawl",
    1974:2008, ages, albatross, "fish per tow", paste(source_name, "Table A38, report pp. 112-113"),
    notes = "The source tables provide ages 1-10; the official final model uses ages 3-10 in the Albatross series.",
    transformation = "Retain the published spring survey numbers-per-tow at age.",
    sampling_time = 95.7 / 365
  ),
  add_age_input("index", "numbers_at_age", "numbers", "", "NEFSC Bigelow spring trawl",
    2009:2016, ages, bigelow, "fish per tow", paste(source_name, "Table A39, report p. 113"),
    notes = "The source tables provide ages 1-10; the official final model uses ages 3-7 in the Bigelow series.",
    transformation = "Retain the published spring survey numbers-per-tow at age.",
    sampling_time = 95.7 / 365
  )
)
input_rows <- list(
  add_age_input("catch", "numbers_at_age", "numbers", "Combined U.S. + Canadian fishery", "",
    years, ages, catch, "thousand fish", paste(source_name, "Table A28, report pp. 96-97"),
    notes = "Published combined commercial and other removals used as the official model's catch-at-age input; age 10 is the 10+ group."
  ),
  add_age_input("weight", "weight_at_age", "kg_per_fish", "", "",
    years, ages, weights, "kg per fish", paste(source_name, "Table A33, report pp. 105-106"),
    notes = "Combined U.S.-Canadian catch/SSB weights at age. For 1968-1978 U.S. weights represent the whole stock; cells without catch use the 1992-2016 mean."
  ),
  add_age_input("maturity", "maturity_at_age", "proportion", "", "",
    years, ages, maturity, "proportion mature", paste(source_name, "Table A4, report pp. 67-68"),
    notes = "Annual maturity ogives from Canadian samples representing the northern spawning contingent; age 10 is the 10+ group."
  ),
  index_rows,
  add_age_input("M", "natural_mortality_at_age", "per_year", "", "",
    rep(NA_real_, 1L), ages, cbind(NA_real_, matrix(rep(0.2, length(ages)), nrow = 1L)),
    "per year", paste(source_name, "final ASAP model description, report pp. 73-74"),
    notes = "Fixed constant natural mortality, 0.2 per year for all ages and years."
  )
)
input_rows[[length(input_rows) + 1L]] <- add_aggregate_input(
  "total_biomass", "biomass", "Range-wide egg/ichthyoplankton SSB index",
  egg_ssb[, 1L], egg_ssb[, 2L], "metric tons",
  paste(source_name, "Table A40, report pp. 113-114"),
  "Combined U.S.-Canadian survey SSB estimates; the source table has years without an estimate."
)
inputs_add <- do.call(rbind, input_rows)

add_age_output <- function(type, measure, values, unit, reference, notes = "") {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(values[, -1L, drop = FALSE])
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = grid$year,
    age = grid$age, age_group = ifelse(grid$age == max(ages), "10+", ""),
    value = grid$value, se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "official_table", source_reference = reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
add_aggregate_output <- function(type, measure, values, unit, reference, age_group = "", notes = "", age = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = years,
    age = age, age_group = age_group, value = values, se = NA_real_,
    lwr = NA_real_, upr = NA_real_, unit = unit, source_type = "official_table",
    source_reference = reference, notes = notes, stringsAsFactors = FALSE
  )
}
outputs_add <- rbind(
  add_age_output(
    "population", "numbers_at_age", n_at_age, "million fish",
    paste(source_name, "Table A43, report pp. 118-119"),
    "Final ASAP Run 118 January 1 abundance estimates; age 10 is the 10+ group."
  ),
  add_age_output(
    "mortality", "fishing_mortality_at_age", f_at_age, "per year",
    paste(source_name, "Table A45, report pp. 121-122"),
    "Final ASAP Run 118 fishing mortality estimates; ages 6-10+ are fully selected."
  ),
  add_age_output(
    "mortality", "natural_mortality_at_age",
    cbind(years, matrix(rep(0.2, length(years) * length(ages)), nrow = length(years))),
    "per year", paste(source_name, "final ASAP model description, report pp. 73-74"),
    "Repeats the explicitly fixed model assumption as an age-year surface; M was not estimated."
  ),
  add_aggregate_output("biomass", "SSB", summary[, 3L], "metric tons",
    paste(source_name, "Table A42, report pp. 116-117"),
    notes = "Final ASAP Run 118 spawning stock biomass."
  ),
  add_aggregate_output("recruitment", "recruitment", n_at_age[, 2L], "million fish",
    paste(source_name, "Table A43, report pp. 118-119"),
    age_group = "age 1", notes = "Age-1 abundance from the published age table, used as recruitment at age 1.", age = 1
  ),
  add_aggregate_output("mortality", "Fbar", summary[, 5L], "per year",
    paste(source_name, "Table A42, report pp. 116-117"),
    age_group = "6-10", notes = "Published fully recruited fishing mortality; fishery selectivity is fixed at 1 for ages 6-10+."
  ),
  add_aggregate_output("biomass", "january_1_biomass", summary[, 2L], "metric tons",
    paste(source_name, "Table A42, report pp. 116-117"),
    notes = "Final ASAP Run 118 total biomass on January 1."
  ),
  add_aggregate_output("biomass", "exploitable_biomass", summary[, 4L], "metric tons",
    paste(source_name, "Table A42, report pp. 116-117"),
    notes = "Final ASAP Run 118 exploitable biomass."
  )
)
summary_years <- 2015:2024
summary_reference <- "2025 Atlantic Mackerel Management Track Assessment Report, Table 1, report p. 1"
add_summary_output <- function(type, measure, values, unit, age = NA_real_, age_group = "",
                               lwr = rep(NA_real_, length(values)),
                               upr = rep(NA_real_, length(values)), notes = "") {
  data.frame(
    assessment_id = summary_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = summary_years,
    age = age, age_group = age_group, value = values, se = NA_real_, lwr = lwr,
    upr = upr, unit = unit, source_type = "official_document",
    source_reference = summary_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
summary_outputs_add <- rbind(
  add_summary_output("biomass", "SSB",
    c(16453, 24166, 31315, 30375, 23894, 15876, 10942, 17193, 39458, 94702),
    "metric tons",
    lwr = c(rep(NA_real_, 9L), 52539),
    upr = c(rep(NA_real_, 9L), 170702),
    notes = "2025 management-track ASAP point estimates. Approximate 90% terminal-year interval is reported in the retrospective text; only 2024 has limits."
  ),
  add_summary_output("mortality", "Fbar",
    c(1.02, 0.78, 0.73, 0.74, 0.70, 1.19, 1.17, 0.20, 0.16, 0.04),
    "per year",
    age_group = "6+",
    lwr = c(rep(NA_real_, 9L), 0.021),
    upr = c(rep(NA_real_, 9L), 0.076),
    notes = "Fully selected F at ages 6+ from the 2025 management-track ASAP assessment. Approximate 90% terminal-year interval is reported in the retrospective text; only 2024 has limits."
  ),
  add_summary_output("recruitment", "recruitment",
    c(131658, 317190, 24301, 107612, 52170, 56500, 78015, 195186, 286681, 1292885),
    "thousand fish",
    age = 1,
    notes = "Annual age-1 recruitment from the 2025 management-track ASAP summary table; no numerical uncertainty interval is tabulated here."
  )
)
outputs_add <- rbind(outputs_add, summary_outputs_add)

stock_add <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NEFSC",
  authority_stock_id = "Northwest Atlantic mackerel stock",
  scientific_name = "Scomber scombrus", common_name = "Atlantic mackerel",
  area = "Northwest Atlantic, U.S. and Canada", region = "Northwest Atlantic",
  ocean = "Northwest Atlantic",
  notes = "The latest 2025 management-track assessment updates advice through 2024, but the 2018 SAW-64 report remains the latest official detailed source with recoverable age-specific inputs and outputs.",
  stringsAsFactors = FALSE
)
assessment_add <- data.frame(
  assessment_id = c(assessment_id, summary_id), stock_id = stock_id,
  assessment_year = c(2018, 2025), terminal_year = c(2016, 2024),
  estimate_terminal_year = c(2016, 2024),
  assessment_type = c("benchmark", "management_track_update"),
  model_family = c("ASAP", "ASAP"),
  model_version = c(
    "Final ASAP Run 118, 64th SAW official model",
    "2025 management-track assessment; detailed age-specific files unavailable"
  ),
  is_current = c("TRUE", "FALSE"), is_applied = c("TRUE", "TRUE"),
  framework_year = c(2018, 2018), assessment_url = c(report_url, summary_url),
  framework_url = c(report_url, ""), data_url = c("", ""), model_url = c("", ""),
  repository_url = c("", ""), assumptions_status = c("partial", "partial"),
  inputs_status = c("partial", "partial"), outputs_status = c("partial", "partial"),
  notes = c(
    "Most recent official assessment with recoverable age-specific numerical inputs and fitted outputs; final ASAP Run 118 covers 1968-2016. The 2025 update is recorded separately and its outputs are not substituted for this detailed record.",
    "Most recent official management-track assessment and basis for current advice through 2024. Aggregate SSB, fully selected F, and age-1 recruitment summaries are recorded for 2015-2024, but the full age-specific input tables and fitted age surfaces are unavailable."
  ), stringsAsFactors = FALSE
)
assumptions_add <- data.frame(
  assessment_id = assessment_id,
  component = c("assessment", "population", "population", "catch", "F", "F", "M", "maturity", "biology", "index", "index", "index", "recruitment", "uncertainty"),
  fleet = c("", "", "", "Combined U.S. + Canadian fishery", "", "Combined U.S. + Canadian fishery", "", "", "", "", "", "NEFSC spring trawl", "", ""),
  survey = c(rep("", 10L), "Range-wide egg/ichthyoplankton SSB index", "NEFSC Albatross and Bigelow spring trawl", "", ""),
  sex = rep("combined", 14L), region = rep("", 14L),
  season = c(rep("", 10L), "spring spawning surveys", "spring", "", ""),
  setting = c("selected_model", "age_structure", "recruitment_age", "fleet_structure", "fully_recruited_age", "selectivity", "natural_mortality", "maturity_schedule", "weight_schedule", "index_set", "aggregate_index_coverage", "survey_timing", "recruitment_definition", "uncertainty"),
  value = c(
    "Final ASAP Run 118, adopted at the 64th Northeast Regional Stock Assessment Workshop",
    "Combined sexes; ages 1-10+, with age 10 as the plus group",
    "Recruitment at age 1",
    "One combined U.S.-Canadian fishery; catch-at-age is reported directly as total removals",
    "Age 6",
    "Time-constant selectivity; ages 1-10: 0.13, 0.46, 0.77, 0.84, 0.88, 1.00, 1.00, 1.00, 1.00, 1.00",
    "Fixed constant M=0.2 per year for all ages and years",
    "Annual Canadian maturity ogives representing the northern spawning contingent",
    "Annual combined U.S.-Canadian catch/SSB weight-at-age; U.S. weights proxy the whole stock in 1968-1978; zero-catch cells use 1992-2016 means",
    "Range-wide egg/ichthyoplankton SSB index and NEFSC spring trawl indices-at-age",
    "Combined egg SSB index has intermittent years; only reported values are stored",
    "NEFSC spring survey runs March-May, with average mean day 95.7; a single timing of 95.7/365 is used for age indices",
    "Age-1 abundance from the official model is reported as recruitment for age-matched comparisons",
    "Point estimates are tabulated for age-specific N and F; no matched uncertainty table was recovered"
  ),
  source_reference = c(
    paste(source_name, "final ASAP model and Table A41"),
    paste(source_name, "Tables A28, A43-A45"),
    paste(source_name, "Table A43 and final ASAP model definition"),
    paste(source_name, "Table A28"), paste(source_name, "Tables A42, A44-A45"),
    paste(source_name, "Tables A44-A45"), paste(source_name, "final ASAP model description, report pp. 73-74"),
    paste(source_name, "Table A4 and final ASAP model description"),
    paste(source_name, "Table A33"), paste(source_name, "Tables A36-A40 and final ASAP model description"),
    paste(source_name, "Table A40"), paste(source_name, "Appendix A5, Effect of survey timing on spatial indices"),
    paste(source_name, "Table A43"), paste(source_name, "Tables A42-A45")
  ),
  notes = c(
    "Current detailed assessment in the canonical database; the newer 2025 assessment is retained separately as summary-only.",
    "Age 10 is treated as 10+ as specified by the official model.",
    "The assessment did not identify a stock-recruitment relationship for projections; its annual assessment recruitment series is the age-1 population estimate.",
    "the original model's catch likelihood and age-composition treatment are simplified.",
    "The table's fully recruited F is the common value at ages 6-10+.",
    "",
    "This fixed value is retained as an input and repeated in outputs only as the explicit fixed model surface; it was not estimated.",
    "The official model uses the Canadian maturity surface.",
    "these are not January-1 weight-at-age.",
    "Albatross ages 3-10 and Bigelow ages 3-7 are retained in the translation; age rows outside the official series are kept in the database.",
    "The aggregate SSB index cannot be translated into age-specific indices without inventing an age composition, so the fit excludes it.",
    "This is a constant approximation from the report's time-series average, not annual sampling-date information.",
    "Age-1 abundance is the available numerical recruitment definition; no separate recruitment table is used.",
    "The report provides point estimates and selected aggregate uncertainty summaries but no matched age-specific intervals in the extracted tables."
  ), stringsAsFactors = FALSE
)

append_rows <- function(name, rows) {
  path <- paths[[name]]
  columns <- names(read_db(name))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  utils::write.table(rows[columns], path,
    sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}
if (nrow(inputs_add) != 1910L + nrow(egg_ssb) || nrow(outputs_add) != 1745L ||
  nrow(maturity) != 49L || nrow(catch) != 49L || nrow(weights) != 49L ||
  nrow(index_rows) != 430L || nrow(egg_ssb) < 10L ||
  any(!is.finite(inputs_add$value)) || any(!is.finite(outputs_add$value)) ||
  any(maturity[, -1L] < 0 | maturity[, -1L] > 1) ||
  any(weights[, -1L] <= 0) || any(catch[, -1L] < 0) ||
  any(n_at_age[, -1L] <= 0) || any(f_at_age[, -1L] < 0) ||
  any(summary[, 2:4] <= 0) || any(summary[, 5L] < 0) ||
  any(egg_ssb[, 2L] <= 0)) {
  stop("Atlantic mackerel records failed dimensions or value checks.", call. = FALSE)
}
if (summary[nrow(summary), 3L] != 43519 || n_at_age[nrow(n_at_age), 2L] != 455.43 ||
  f_at_age[nrow(f_at_age), 7L] != 0.468 || summary[nrow(summary), 5L] != f_at_age[nrow(f_at_age), 7L]) {
  stop("Terminal-year Run 118 values do not match Tables A42-A45.", call. = FALSE)
}

append_rows("stocks", stock_add)
append_rows("assessments", assessment_add)
append_rows("assumptions", assumptions_add)
append_rows("inputs", inputs_add)
append_rows("outputs", outputs_add)
cat("Imported detailed SAW-64 Atlantic mackerel Run 118 and registered the 2025 summary-only update: ",
  nrow(inputs_add), " inputs and ", nrow(outputs_add), " outputs (", nrow(egg_ssb), " aggregate egg-index years).\n",
  sep = ""
)
