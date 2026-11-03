assessment_id <- "ices_herring_central_baltic_2026"
stock_id <- "ck_ices_wgbfas_harengus_bs_25_29_32"
root <- "."
cache <- file.path(root, "source_cache", stock_id)
database <- file.path(root, "database")
report_file <- file.path(cache, "wgbfas_2026_herring_section.pdf")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to run this source importer.", call. = FALSE)
}
if (!file.exists(report_file)) {
  stop("The cached 2026 ICES herring section is missing.", call. = FALSE)
}

read_db <- function(name) {
  read.csv(file.path(database, name), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE
  )
}
paths <- setNames(
  file.path(database, paste0(c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
stocks <- read_db("stocks.csv")
if (sum(stocks$stock_id == stock_id) != 1L ||
  assessment_id %in% read_db("assessments.csv")$assessment_id) {
  stop("Expected one catalogue stock row and no existing assessment record.", call. = FALSE)
}

pages <- pdftools::pdf_text(report_file)
page_for <- function(marker) {
  page <- which(vapply(pages, grepl, logical(1), pattern = marker, fixed = TRUE))
  if (length(page) != 1L) stop("Could not locate one report page for: ", marker, call. = FALSE)
  page
}
table_text <- function(start_marker, end_marker) {
  start_page <- page_for(start_marker)
  end_page <- page_for(end_marker)
  text <- paste(pages[start_page:end_page], collapse = "\n")
  start <- regexpr(start_marker, text, fixed = TRUE)[[1L]]
  end <- regexpr(end_marker, text, fixed = TRUE)[[1L]]
  if (start < 1L || end <= start) stop("Invalid report table boundaries.", call. = FALSE)
  substr(text, start, end - 1L)
}
year_rows <- function(text, n_values, expected_years = NULL, allow_more = FALSE) {
  lines <- unlist(strsplit(text, "\n", fixed = TRUE), use.names = FALSE)
  lines <- gsub("0\\.\\s+0000", "0.0000", lines, perl = TRUE)
  lines <- lines[grepl("^\\s*[12][0-9]{3}\\*?\\s+", lines)]
  rows <- lapply(lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+")[[1L]]
    year <- as.integer(sub("\\*$", "", fields[[1L]]))
    values <- suppressWarnings(as.numeric(gsub("\\*+", "", fields[-1L])))
    if ((!allow_more && length(values) != n_values) || length(values) < n_values ||
      anyNA(values) || any(!is.finite(values))) return(NULL)
    values <- values[seq_len(n_values)]
    c(year = year, values)
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) stop("No complete year rows found in a source table.", call. = FALSE)
  result <- as.data.frame(do.call(rbind, rows), check.names = FALSE)
  names(result) <- c("year", paste0("value", seq_len(n_values)))
  result$year <- as.integer(result$year)
  if (anyDuplicated(result$year)) stop("A source table contains duplicate years.", call. = FALSE)
  if (!is.null(expected_years) && !identical(result$year, as.integer(expected_years))) {
    stop("Unexpected year coverage in a source table: ",
      paste(range(result$year), collapse = "-"), "; missing: ",
      paste(setdiff(expected_years, result$year), collapse = ", "),
      "; extra: ", paste(setdiff(result$year, expected_years), collapse = ", "),
      call. = FALSE
    )
  }
  result
}
input_rows <- function(type, measure, basis, year, age, value, unit,
                       source_reference, source_type = "official_table",
                       transformation = "", notes = "", fleet = "", survey = "",
                       sampling_time = NA_real_) {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = rep_len(type, n),
    measure = rep_len(measure, n), basis = rep_len(basis, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey, n), sex = "combined",
    region = "ICES subdivisions 25-29 and 32, excluding the Gulf of Riga",
    season = "", year = rep_len(year, n),
    year_basis = ifelse(is.na(year), "", "calendar_year"),
    age = rep_len(age, n), value = as.numeric(value), unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = rep_len(source_type, n),
    source_reference = rep_len(source_reference, n),
    transformation = rep_len(transformation, n), notes = rep_len(notes, n),
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "",
    partition = "", stringsAsFactors = FALSE, check.names = FALSE
  )
}
matrix_rows <- function(table, age_labels, measure, type, basis, unit,
                        source_reference, source_type = "official_table",
                        transformation = "Transcribed the published value without rescaling.",
                        notes = "", fleet = "", survey = "", sampling_time = NA_real_) {
  grid <- expand.grid(age = age_labels, year = table$year)
  values <- as.vector(t(as.matrix(table[-1L])))
  if (length(values) != nrow(grid)) stop("Table values do not match their age labels.", call. = FALSE)
  input_rows(type, measure, basis, grid$year, grid$age, values, unit,
    source_reference = source_reference, source_type = rep_len(source_type, length(values)),
    transformation = rep_len(transformation, length(values)),
    notes = rep_len(notes, length(values)), fleet = fleet, survey = survey,
    sampling_time = sampling_time
  )
}
expand_annual_surface <- function(table, ages, years, copy_year, table_label,
                                  assumption_note, measure, type, basis, unit,
                                  source_reference) {
  source_values <- as.matrix(table[-1L])
  if (!all(years[years >= min(table$year)] %in% table$year)) {
    stop("The source surface does not cover its reported years.", call. = FALSE)
  }
  expanded <- matrix(NA_real_, nrow = length(years), ncol = length(ages))
  rownames(expanded) <- years
  colnames(expanded) <- ages
  expanded[match(table$year, years), ] <- source_values
  copy_rows <- years < min(table$year)
  expanded[copy_rows, ] <- matrix(
    source_values[match(copy_year, table$year), ],
    nrow = sum(copy_rows), ncol = length(ages), byrow = TRUE
  )
  grid <- expand.grid(age = ages, year = years)
  copied <- grid$year < min(table$year)
  values <- as.vector(t(expanded))
  input_rows(type, measure, basis, grid$year, grid$age, values, unit,
    source_reference = source_reference,
    source_type = ifelse(copied, "reconstructed_source_input", "official_table"),
    transformation = ifelse(copied,
      paste0("Repeated the ", copy_year, " surface for ", min(years), "-", min(table$year) - 1L,
        " as stated in ", table_label, "."),
      "Transcribed the published annual value without rescaling."),
    notes = assumption_note
  )
}
output_rows <- function(type, measure, year, age = NA_integer_, age_group = "",
                        value, lwr = NA_real_, upr = NA_real_, unit,
                        notes, source_reference) {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "combined",
    region = "ICES subdivisions 25-29 and 32, excluding the Gulf of Riga",
    season = "", year = rep_len(year, n), age = rep_len(age, n),
    age_group = rep_len(age_group, n), value = as.numeric(value), se = NA_real_,
    lwr = rep_len(lwr, n), upr = rep_len(upr, n), unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch <- year_rows(
  table_text("Table 4.2.5. Herring in", "Table 4.2.6. Herring in"),
  n_values = 8L, expected_years = 1974:2025
)
weights <- year_rows(
  table_text("Table 4.2.6. Herring in", "Table 4.2.7.a. Herring in"),
  n_values = 9L, expected_years = 1974:2025
)
maturity <- year_rows(
  table_text("Table 4.2.8. Herring in", "Table 4.2.9. Herring in"),
  n_values = 10L, expected_years = 1974:2025
)
acoustic <- year_rows(
  table_text("Table 4.2.9. Herring in", "The tuning index includes subdivisions"),
  n_values = 9L
)
if (!identical(acoustic$year, c(2000L, 2006L, 2007L, 2009L:2025L))) {
  stop("Unexpected BIAS survey years in Table 4.2.9.", call. = FALSE)
}

m_table <- function(start, end) year_rows(table_text(start, end),
  n_values = 9L, expected_years = 1974:2025
)
m_scenarios <- list(
  M_M1_010_All = m_table("Table 4.2.7.a. Herring in", "Table 4.2.7.b. Herring in"),
  M_M1_020_All = m_table("Table 4.2.7.b. Herring in", "Table 4.2.7.c. Herring in"),
  M_lim10_All = m_table("Table 4.2.7.c. Herring in", "Table 4.2.8. Herring in")
)
scenario_means <- vapply(m_scenarios, function(x) mean(as.matrix(x[-1L])), numeric(1))
if (!(scenario_means[["M_lim10_All"]] < scenario_means[["M_M1_010_All"]] &&
  scenario_means[["M_M1_010_All"]] < scenario_means[["M_M1_020_All"]])) {
  stop("The reported M scenarios do not match the expected low/medium/high ordering.", call. = FALSE)
}
expand_m <- function(x, scenario, measure) {
  source_values <- as.matrix(x[-1L])
  base <- source_values[match(1974:2021, x$year), , drop = FALSE]
  if (!all(source_values[match(2022:2025, x$year), , drop = FALSE] ==
    matrix(base[nrow(base), ], nrow = 4L, ncol = ncol(base), byrow = TRUE))) {
    stop("The report's 2022-2025 M values do not repeat 2021.", call. = FALSE)
  }
  years <- 1903:2025
  expanded <- matrix(NA_real_, nrow = length(years), ncol = ncol(base))
  expanded[match(1974:2021, years), ] <- base
  expanded[match(1903:1973, years), ] <- matrix(base[1L, ], nrow = 71L, ncol = ncol(base), byrow = TRUE)
  expanded[match(2022:2025, years), ] <- matrix(base[nrow(base), ], nrow = 4L, ncol = ncol(base), byrow = TRUE)
  grid <- expand.grid(age = 0:8, year = years)
  copied <- grid$year < 1974L | grid$year > 2021L
  values_out <- as.vector(t(expanded))
  table <- if (scenario == "M_M1_010_All") "Table 4.2.7.a" else
    if (scenario == "M_M1_020_All") "Table 4.2.7.b" else "Table 4.2.7.c"
  note <- paste0("Native SMS scenario ", scenario,
    ". Values before 1974 equal 1974 by the report assumption; values in 2022-2025 repeat 2021 as noted below the table.")
  input_rows("M", measure, "per_year", grid$year, grid$age, values_out,
    "per year", paste0("ICES WGBFAS 2026, ", table, ", pp. 269-274"),
    source_type = ifelse(copied, "reconstructed_source_input", "official_table"),
    transformation = ifelse(copied,
      "Repeated the report's stated boundary-year M values; numeric values are unchanged.",
      "Transcribed the published annual M value without rescaling."),
    notes = note
  )
}
maturity_expanded <- expand_annual_surface(
  maturity, 0:9, 1903:2025, 1974L, "ICES Stock Annex 2026, Table 3.1",
  "Annual proportion mature at year start. The 2026 report prose says 1974-1983 repeat 1984, but Table 4.2.8 lists a distinct constant 1974-1983 ogive; the tabled SS3 input values are preserved. The Stock Annex states pre-1974 equals 1974.",
  "maturity_at_age", "maturity", "proportion", "proportion mature",
  "ICES WGBFAS 2026, Table 4.2.8, pp. 275-276; Stock Annex 2026, Table 3.1"
)
weight_surface <- expand_annual_surface(
  weights, 0:8, 1903:2025, 1974L, "ICES Stock Annex 2026, Table 3.1",
  "Mean catch weight at age; stock weights equal catch weights. The Stock Annex says 1903-1973 repeat 1974; the annual report text says 1973, which is not present in the published table.",
  "weight_at_age", "weight", "kg_per_fish", "kg per fish",
  "ICES WGBFAS 2026, Table 4.2.6, pp. 266-268; Stock Annex 2026, Table 3.1"
)
catch_weight_surface <- weight_surface
catch_weight_surface$type <- "catch_weight"
catch_weight_surface$measure <- "weight_at_age"
catch_weight_surface$fleet <- "commercial"
catch_weight_surface$source_reference <- "ICES WGBFAS 2026, Table 4.2.6, pp. 266-268; Stock Annex 2026, Table 3.1"

inputs_add <- do.call(rbind, list(
  matrix_rows(catch, 1:8, "numbers_at_age", "catch", "numbers",
    "thousand fish", "ICES WGBFAS 2026, Table 4.2.5, pp. 264-266",
    notes = "Commercial catch-at-age in numbers; age 8 is the 8+ group. The assessment uses these as age-composition inputs alongside total catch in tonnes; Russian 2022-2025 catches lack age compositions and represented about 26% of 2025 catch.",
    fleet = "commercial"),
  weight_surface,
  catch_weight_surface,
  matrix_rows(acoustic, 0:8, "numbers_at_age", "index", "numbers",
    "million fish", "ICES WGBFAS 2026, Table 4.2.9, p. 277",
    notes = "BIAS October acoustic tuning index. Age 0 entries are reported as zero.",
    survey = "BIAS"),
  expand_m(m_scenarios[["M_M1_010_All"]], "M_M1_010_All", "fixed_mortality_medium"),
  expand_m(m_scenarios[["M_M1_020_All"]], "M_M1_020_All", "fixed_mortality_high"),
  expand_m(m_scenarios[["M_lim10_All"]], "M_lim10_All", "fixed_mortality_low"),
  maturity_expanded
))
if (nrow(inputs_add) != 7361L || any(!is.finite(inputs_add$value))) {
  stop("Unexpected source input count or non-finite values.", call. = FALSE)
}

raw_year_rows <- function(text, min_values) {
  lines <- unlist(strsplit(text, "\n", fixed = TRUE), use.names = FALSE)
  lines <- gsub("0\\.\\s+0000", "0.0000", lines, perl = TRUE)
  lines <- lines[grepl("^\\s*[12][0-9]{3}\\*?\\s+", lines)]
  rows <- lapply(lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+")[[1L]]
    year <- as.integer(sub("\\*$", "", fields[[1L]]))
    values <- suppressWarnings(as.numeric(gsub("\\*+", "", fields[-1L])))
    if (length(values) < min_values || anyNA(values) || any(!is.finite(values))) return(NULL)
    list(year = year, values = values)
  })
  Filter(Negate(is.null), rows)
}
summary_a_rows <- raw_year_rows(
  table_text("Table 4.2.11a. Herring in", "Table 4.2.11b. Herring in"), 6L
)
summary_b_rows <- raw_year_rows(
  table_text("Table 4.2.11b. Herring in", "Figure 4.2.4 Herring in"), 3L
)
summary_a_rows <- summary_a_rows[!duplicated(vapply(summary_a_rows, `[[`, integer(1), "year"))]
summary_b_rows <- summary_b_rows[!duplicated(vapply(summary_b_rows, `[[`, integer(1), "year"))]
expected_output_years <- as.integer(1904:2026)
if (!identical(vapply(summary_a_rows, `[[`, integer(1), "year"), expected_output_years) ||
  !identical(vapply(summary_b_rows, `[[`, integer(1), "year"), expected_output_years)) {
  stop("The official summary tables do not have expected year coverage.", call. = FALSE)
}
summary_a <- data.frame(
  year = expected_output_years,
  recruitment_lwr = vapply(summary_a_rows, function(x) x$values[[1L]], numeric(1)),
  recruitment = vapply(summary_a_rows, function(x) x$values[[2L]], numeric(1)),
  recruitment_upr = vapply(summary_a_rows, function(x) x$values[[3L]], numeric(1)),
  ssb_relative_lwr = vapply(summary_a_rows, function(x) x$values[[4L]], numeric(1)),
  ssb_relative = vapply(summary_a_rows, function(x) x$values[[5L]], numeric(1)),
  ssb_relative_upr = vapply(summary_a_rows, function(x) x$values[[6L]], numeric(1)),
  catch = vapply(summary_a_rows, function(x) if (length(x$values) >= 7L) x$values[[7L]] else NA_real_, numeric(1)),
  f_relative_lwr = vapply(summary_a_rows, function(x) if (length(x$values) >= 8L) x$values[[8L]] else NA_real_, numeric(1)),
  f_relative = vapply(summary_a_rows, function(x) if (length(x$values) >= 9L) x$values[[9L]] else NA_real_, numeric(1)),
  f_relative_upr = vapply(summary_a_rows, function(x) if (length(x$values) >= 10L) x$values[[10L]] else NA_real_, numeric(1))
)
summary_b <- data.frame(
  year = expected_output_years,
  ssb_lwr = vapply(summary_b_rows, function(x) x$values[[1L]], numeric(1)),
  ssb = vapply(summary_b_rows, function(x) x$values[[2L]], numeric(1)),
  ssb_upr = vapply(summary_b_rows, function(x) x$values[[3L]], numeric(1)),
  fbar_lwr = vapply(summary_b_rows, function(x) if (length(x$values) >= 6L) x$values[[4L]] else NA_real_, numeric(1)),
  fbar = vapply(summary_b_rows, function(x) if (length(x$values) >= 6L) x$values[[5L]] else NA_real_, numeric(1)),
  fbar_upr = vapply(summary_b_rows, function(x) if (length(x$values) >= 6L) x$values[[6L]] else NA_real_, numeric(1))
)
if (!identical(summary_a$year, summary_b$year) ||
  any(!is.finite(summary_a$catch[summary_a$year <= 2025L])) ||
  any(is.finite(summary_a$catch[summary_a$year == 2026L])) ||
  any(is.finite(summary_b$fbar[summary_b$year == 2026L]))) {
  stop("The official summary tables do not have matching year coverage.", call. = FALSE)
}

report_url <- "https://doi.org/10.17895/ices.pub.32455056.v3"
report_reference <- "ICES WGBFAS 2026, Herring in SD 25-29 and 32 excluding the Gulf of Riga, section 4.2"
framework_url <- "https://doi.org/10.17895/ices.pub.23216492"
graphs_url <- "https://sg.ices.dk/ViewSourceData.aspx?key=23758"
total_catch_add <- input_rows("catch", "total_biomass", "biomass",
  summary_a$year, NA_integer_, summary_a$catch, "tonnes",
  source_reference = paste(report_reference, "Table 4.2.11a, pp. 279-286; Stock Annex 2026, Table 3.1"),
  source_type = "official_table",
  fleet = "commercial",
  notes = "Total catch in tonnes is an official model input, as confirmed by Stock Annex Table 3.1. The summary table starts in 1904; no value is available here for 1903. Values marked ** for 2022-2025 include Russian Federation landings that were not officially reported to ICES."
)
total_catch_add <- total_catch_add[!is.na(total_catch_add$value), , drop = FALSE]
outputs_add <- do.call(rbind, list(
  output_rows("recruitment", "recruitment", summary_a$year, age = 0L,
    value = summary_a$recruitment, lwr = summary_a$recruitment_lwr, upr = summary_a$recruitment_upr,
    unit = "thousand fish",
    notes = "Native age-0 recruitment from the weighted-median ensemble. lwr/upr are the reported 5th/95th percentiles (central 90% interval), not a 95% interval. Values for 2025 and 2026 are recruitment estimates derived from the Beverton-Holt stock-recruitment function.",
    source_reference = paste(report_reference, "Table 4.2.11a, pp. 279-286")),
  output_rows("biomass", "SSB", summary_b$year,
    value = summary_b$ssb, lwr = summary_b$ssb_lwr, upr = summary_b$ssb_upr,
    unit = "tonnes",
    notes = "Native SSB from the weighted-median ensemble. lwr/upr are the reported 5th/95th percentiles (central 90% interval); the report says absolute values are for ecosystem analyses, not advice. 2026 is a forecast.",
    source_reference = paste(report_reference, "Table 4.2.11b, pp. 287-295")),
  output_rows("mortality", "Fbar", summary_b$year[!is.na(summary_b$fbar)],
    age_group = "3-6", value = summary_b$fbar[!is.na(summary_b$fbar)], lwr = summary_b$fbar_lwr[!is.na(summary_b$fbar)],
    upr = summary_b$fbar_upr[!is.na(summary_b$fbar)], unit = "per year",
    notes = "Simple F average over ages 3-6 from the weighted-median ensemble. lwr/upr are the reported 5th/95th percentiles (central 90% interval). The 2026 forecast table does not report F.",
    source_reference = paste(report_reference, "Table 4.2.11b, pp. 287-295")),
  output_rows("biomass", "SSB_relative_to_MSY_Btrigger", summary_a$year,
    value = summary_a$ssb_relative, lwr = summary_a$ssb_relative_lwr,
    upr = summary_a$ssb_relative_upr, unit = "ratio",
    notes = "Native relative SSB status indicator at 1 January. Bounds are the reported 5th/95th percentiles (central 90% interval). 2026 is a forecast.",
    source_reference = paste(report_reference, "Table 4.2.11a, pp. 279-286")),
  output_rows("mortality", "Fbar_relative_to_FMSY", summary_a$year[!is.na(summary_a$f_relative)],
    age_group = "3-6", value = summary_a$f_relative[!is.na(summary_a$f_relative)],
    lwr = summary_a$f_relative_lwr[!is.na(summary_a$f_relative)],
    upr = summary_a$f_relative_upr[!is.na(summary_a$f_relative)],
    unit = "ratio",
    notes = "Native relative fishing-pressure status indicator for the simple mean over ages 3-6. Bounds are the reported 5th/95th percentiles (central 90% interval).",
    source_reference = paste(report_reference, "Table 4.2.11a, pp. 279-286"))
))
inputs_add <- rbind(inputs_add, total_catch_add)
input_at <- function(type, measure, year, age = NA_integer_, fleet = "", survey = "") {
  age_match <- if (is.na(age)) is.na(inputs_add$age) else inputs_add$age == age
  rows <- inputs_add[inputs_add$type == type & inputs_add$measure == measure &
    inputs_add$year == year & age_match &
    inputs_add$fleet == fleet & inputs_add$survey == survey, , drop = FALSE]
  if (nrow(rows) != 1L) stop("Expected one input row for ", measure, " in ", year, ".", call. = FALSE)
  rows$value[[1L]]
}
output_at <- function(type, measure, year, age = NA_integer_, age_group = "") {
  age_match <- if (is.na(age)) is.na(outputs_add$age) else outputs_add$age == age
  rows <- outputs_add[outputs_add$type == type & outputs_add$measure == measure &
    outputs_add$year == year & age_match &
    outputs_add$age_group == age_group, , drop = FALSE]
  if (nrow(rows) != 1L) stop("Expected one output row for ", measure, " in ", year, ".", call. = FALSE)
  rows$value[[1L]]
}
expected_values <- c(
  catch_age_1974 = 2436300,
  catch_age_2025 = 233601,
  weight_1903 = 0.006,
  weight_1974 = 0.006,
  weight_2025 = 0.0553,
  maturity_1974 = 0.0954,
  maturity_1984 = 0.0872,
  acoustic_2000 = 36325,
  acoustic_2025 = 250,
  catch_total_2025 = 112427,
  recruitment_2025 = 22543827,
  ssb_2025 = 951517,
  fbar_2025 = 0.143,
  ssb_status_2025 = 0.68,
  f_status_2025 = 0.57
)
observed_values <- c(
  catch_age_1974 = input_at("catch", "numbers_at_age", 1974L, 1L, fleet = "commercial"),
  catch_age_2025 = input_at("catch", "numbers_at_age", 2025L, 8L, fleet = "commercial"),
  weight_1903 = input_at("weight", "weight_at_age", 1903L, 0L),
  weight_1974 = input_at("weight", "weight_at_age", 1974L, 0L),
  weight_2025 = input_at("weight", "weight_at_age", 2025L, 8L),
  maturity_1974 = input_at("maturity", "maturity_at_age", 1974L, 1L),
  maturity_1984 = input_at("maturity", "maturity_at_age", 1984L, 1L),
  acoustic_2000 = input_at("index", "numbers_at_age", 2000L, 1L, survey = "BIAS"),
  acoustic_2025 = input_at("index", "numbers_at_age", 2025L, 8L, survey = "BIAS"),
  catch_total_2025 = input_at("catch", "total_biomass", 2025L, fleet = "commercial"),
  recruitment_2025 = output_at("recruitment", "recruitment", 2025L, 0L),
  ssb_2025 = output_at("biomass", "SSB", 2025L),
  fbar_2025 = output_at("mortality", "Fbar", 2025L, age_group = "3-6"),
  ssb_status_2025 = output_at("biomass", "SSB_relative_to_MSY_Btrigger", 2025L),
  f_status_2025 = output_at("mortality", "Fbar_relative_to_FMSY", 2025L, age_group = "3-6")
)
if (!isTRUE(all.equal(observed_values, expected_values, tolerance = 0))) {
  stop("Extracted values failed the source-table spot checks.", call. = FALSE)
}
maturity_repeats <- all(vapply(1974:1983, function(year) {
  input_at("maturity", "maturity_at_age", year, 1L) ==
    input_at("maturity", "maturity_at_age", 1974L, 1L)
}, logical(1)))
early_m_repeats <- input_at("M", "fixed_mortality_medium", 1903L, 0L) ==
  input_at("M", "fixed_mortality_medium", 1974L, 0L)
late_m_repeats <- input_at("M", "fixed_mortality_medium", 2025L, 0L) ==
  input_at("M", "fixed_mortality_medium", 2021L, 0L)
if (!maturity_repeats || !early_m_repeats || !late_m_repeats) {
  stop("Expanded surface check failed: maturity repeats 1974 in 1974-1983 = ", maturity_repeats,
    "; pre-1974 M repeats 1974 = ", early_m_repeats,
    "; 2025 M repeats 2021 = ", late_m_repeats,
    ". Values: ", input_at("M", "fixed_mortality_medium", 1903L, 0L), ", ",
    input_at("M", "fixed_mortality_medium", 1974L, 0L), ", ",
    input_at("M", "fixed_mortality_medium", 2025L, 0L), ", ",
    input_at("M", "fixed_mortality_medium", 2021L, 0L), call. = FALSE)
}

assumption <- function(component, setting, value, notes = "",
                       source_reference = report_reference, survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = survey, sex = "combined",
    region = "ICES subdivisions 25-29 and 32, excluding the Gulf of Riga",
    season = "", setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
assumptions_add <- do.call(rbind, list(
  assumption("assessment", "model_family", "Stock Synthesis 3", "The 2023 WKBBALTPEL benchmark accepted an age-based SS3 framework; the 2026 ICES Stock Annex identifies it as the basis for advice."),
  assumption("assessment", "model_version", "3.30.22.1", "Version stated in the 2026 assessment report; native control and data files were not recovered."),
  assumption("assessment", "assessment_year", "2026", "WGBFAS 2026 assessment supporting 2027 advice."),
  assumption("assessment", "official_run", "Reference_run_SD32_survey", "The Stock Annex identifies the SD32 survey model configuration as the reference run; all three ensemble models share its configuration except age-year M."),
  assumption("population", "model_years", "1903-2025", "The official model starts in 1903; total landed weight is input from 1903 and age-composition data begin in 1974. The published summary tables provide total catch only from 1904."),
  assumption("population", "model_ages", "0-8+", "The model starts at age 0; age 8 is the plus group. Maturity is published through age 9."),
  assumption("population", "sex_area_fleet_structure", "Combined sexes; one area; one commercial fleet; one survey", "Source structure from Stock Annex 2026, sections 3.1-3.3."),
  assumption("population", "initial_state", "Exploited", "The initial population is assumed exploited; initial commercial catches are the average of 1903-1905 with fixed standard error 0.2."),
  assumption("recruitment", "recruitment_age", "0", "The model's recruitment is abundance at age 0 in the same year."),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt", "Recruitment occurs at the beginning of the year and deviates from the stock-recruitment curve; steepness and recruitment autocorrelation are estimated."),
  assumption("recruitment", "process_sd", "0.5", "Recruitment process SD is fixed at 0.5. Deviations are estimated for 1974-current year and early deviations for 1968-1983."),
  assumption("F", "method", "Fleet-specific F, hybrid method", "The model uses an age-based logistic fishery selection pattern; report basis option 5 corresponds to a simple unweighted mean of F at ages 3-6."),
  assumption("F", "selectivity", "Age-specific and time-invariant for fishery; random-walk log selectivity over age for fishery and survey; logistic at ages 5-8+", "Exact coefficient activation and parameter bounds are summarized in Stock Annex 2026 Table 4.1; native control files were not recovered."),
  assumption("F", "Fbar_ages", "3-6", "The official Fbar is the unweighted arithmetic mean over ages 3-6."),
  assumption("M", "ensemble_scenarios", "M_M1_010_All; M_M1_020_All; M_lim10_All", "Three SS3 models share inputs and configuration but use different age-year M surfaces; the assessment output is a diagnostic-weighted ensemble."),
  assumption("M", "scenario_low", "M_lim10_All", "Stored as fixed_mortality_low; this uses the 10th percentile of cod food-consumption parameters."),
  assumption("M", "scenario_medium", "M_M1_010_All", "Stored as fixed_mortality_medium; average annual M1 is 0.1."),
  assumption("M", "scenario_high", "M_M1_020_All", "Stored as fixed_mortality_high; average annual M1 is 0.2."),
  assumption("M", "boundary_years", "1903-1973 = 1974; 2022-2025 = 2021", "The Stock Annex and 2026 report state the fixed boundary-year extensions; the tabled annual M scenarios are retained."),
  assumption("catch", "total_catch", "Total landed weight in tonnes; 1903-last data year", "The 2026 Stock Annex confirms catch biomass is an official input. Report Table 4.2.11a provides 1904-2025 values but not 1903."),
  assumption("catch", "observation_error", "0.2 initial; 0.1 for 1903-1973; 0.05 from 1974", "The Stock Annex calls these standard errors; it does not specify their scale in the accessible text."),
  assumption("catch", "age_compositions", "Commercial catch-at-age numbers, 1974-2025, ages 1-8+", "Non-sampled catches use the same age distribution as sampled catches in the same subdivision and quarter. Russian Federation age composition is unavailable for 2022-2025; about 26% of total catch lacks composition in 2025."),
  assumption("catch", "composition_sample_size", "Trips sampled", "Annual values are defined as number of trips in national sources but the numeric series and corresponding composition weighting are not published in the recovered files."),
  assumption("catch", "composition_weighting", "Dirichlet-multinomial", "The Stock Annex reports a Dirichlet-multinomial error distribution as additional weighting of age compositions."),
  assumption("index", "survey", "Baltic International Acoustic Survey (BIAS)", "The survey is the only abundance index and covers SD 25-27, 28.2, 29 and 32.", survey = "BIAS"),
  assumption("index", "survey_years_and_ages", "2000, 2006-2007, 2009-2025; ages 1-8+", "Years 2001-2005 and 2008 are excluded; the report table also prints zero values for age 0, outside the survey's age range.", survey = "BIAS"),
  assumption("index", "survey_timing", "October; exact fractional timing unknown", "The assessment report identifies the survey season as October but does not give a within-year fraction. The translation uses 0.8 as an explicitly documented approximation.", survey = "BIAS"),
  assumption("index", "index_cv", "Estimated by bootstrapping", "Annual CV values and fitted index likelihood weights are not available in the recovered public files.", survey = "BIAS"),
  assumption("weight", "weight_at_age", "Catch weight equals stock weight", "Weights are time varying; the Stock Annex says 1903-1973 repeat 1974. Main-report prose says repeat 1973, which is not in the table, so the Stock Annex tabled assumption is used for the expansion."),
  assumption("maturity", "maturity_at_age", "Time-varying; age 0-9; proportion mature at year start", "The source table provides a constant 1974-1983 ogive and the main-report prose says those years repeat 1984, whose published values differ. Tabled SS3 inputs are preserved; pre-1974 values are expanded from 1974 as stated by the Stock Annex."),
  assumption("ensemble", "weighting_method", "Diagnostic-weighted delta-MVLN; weighted-median output", "The ensemble stitches joint posterior distributions using each run's diagnostics, MLEs, Hessian uncertainty and correlations."),
  assumption("outputs", "uncertainty", "5th and 95th percentiles", "Published intervals are central 90% ensemble intervals, not 95% confidence intervals; recruitment and SSB bounds are percentiles, not standard errors."),
  assumption("outputs", "available_surfaces", "Age-0 recruitment, SSB, Fbar ages 3-6, relative SSB and relative F", "No tabulated N-at-age, F-at-age or M-at-age output surfaces were found in the report or ICES Standard Graph source data."),
  assumption("data", "source_completeness", "partial", "Published inputs and selected ensemble outputs are transcribed. Missing material includes the 1903 catch value, numeric composition sample sizes/weights, annual acoustic CVs, native SS3 files and age-specific N/F/M outputs.")
))

assessment_add <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026,
  terminal_year = 2025, estimate_terminal_year = 2026,
  assessment_type = "annual_assessment", model_family = "Stock Synthesis",
  model_version = "Stock Synthesis 3.30.22.1; 2023 benchmark framework",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2023,
  assessment_url = report_url, framework_url = framework_url,
  data_url = graphs_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Official ICES WGBFAS 2026 assessment. The 2026 report provides published annual input tables and selected weighted-median ensemble outputs, but the native SS3 files were not recovered.",
    "The Stock Annex says total catch input starts in 1903; the recovered summary table provides 1904-2025 values, so the 1903 value remains unavailable. Catch-at-age begins in 1974; exact composition sample sizes, acoustic CVs and likelihood settings are unavailable.",
    "Available outputs include age-0 recruitment, SSB, Fbar and relative status ratios; no tabulated N-at-age, F-at-age or M-at-age surfaces were found."
  ),
  stringsAsFactors = FALSE
)
stock_add <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
stock_add$authority_stock_id <- "her.27.25-2932"
stock_add$scientific_name <- "Clupea harengus"
stock_add$common_name <- "Central Baltic herring"
stock_add$area <- "ICES subdivisions 25-29 and 32, excluding the Gulf of Riga"
stock_add$region <- "Central Baltic Sea"
stock_add$ocean <- "Northeast Atlantic"
stock_add$notes <- paste(stock_add$notes,
  "Official ICES stock code her.27.25-2932; area and name verified against WGBFAS 2026.")

if (anyDuplicated(paste(inputs_add$type, inputs_add$measure, inputs_add$year,
  inputs_add$age, inputs_add$survey, sep = "\034")) ||
  anyDuplicated(paste(outputs_add$type, outputs_add$measure, outputs_add$year,
    outputs_add$age, outputs_add$age_group, sep = "\034"))) {
  stop("Generated source rows contain duplicate keys.", call. = FALSE)
}
append_rows <- function(name, rows) {
  path <- paths[[name]]
  columns <- names(read_db(paste0(name, ".csv")))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
if (identical(Sys.getenv("SAIO_IMPORT_DRY_RUN"), "1")) {
  cat("Parsed Central Baltic herring 2026: ", nrow(inputs_add), " inputs, ",
    nrow(assumptions_add), " assumptions, and ", nrow(outputs_add), " outputs.\n", sep = "")
  quit(save = "no", status = 0L)
}
stock_lines <- readLines(paths[["stocks"]], warn = FALSE, encoding = "UTF-8")
stock_row <- which(startsWith(stock_lines, paste0('"', stock_id, '"')))
if (length(stock_row) != 1L) stop("Expected one existing stock row.", call. = FALSE)
stock_lines[[stock_row]] <- capture.output(write.csv(stock_add, row.names = FALSE, na = ""))[[2L]]
writeLines(stock_lines, paths[["stocks"]], useBytes = TRUE)
append_rows("assessments", assessment_add)
append_rows("assumptions", assumptions_add)
append_rows("inputs", inputs_add)
append_rows("outputs", outputs_add)

cat("Imported Central Baltic herring 2026: ", nrow(inputs_add), " inputs, ",
  nrow(assumptions_add), " assumptions, and ", nrow(outputs_add), " outputs.\n", sep = "")
