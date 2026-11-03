root <- "."
cache <- file.path(root, "source_cache", "ck_ices_wgcse_aeglefinus_rock6b")
tables <- file.path(cache, "extracted_tables")
db <- file.path(root, "database")
assessment_id <- "ices_haddock_rockall_2026"
stock_id <- "ck_ices_wgcse_aeglefinus_rock6b"
report <- "ICES WGCSE 2026, Haddock in Division 6.b, doi:10.17895/ices.pub.32625759"
framework <- "ICES WKBGAD 2024, doi:10.17895/ices.pub.25002470"
report_url <- "https://doi.org/10.17895/ices.pub.32625759"
framework_url <- "https://doi.org/10.17895/ices.pub.25002470"
model_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/had.6b_2025/run/model.RData"
taf_commit <- "2b768d6e2563d38a172918390e8fe964596b1325"
taf_repository_url <- paste0(
  "https://github.com/ices-advice/2026_had.27.6b/tree/", taf_commit
)
taf_stock_weight_code_url <- paste0(
  "https://github.com/ices-advice/2026_had.27.6b/blob/", taf_commit,
  "/2026_had.27.6b_assessment/data_stockweights.R"
)
taf_data_code_url <- paste0(
  "https://github.com/ices-advice/2026_had.27.6b/blob/", taf_commit,
  "/2026_had.27.6b_assessment/data.R"
)

paths <- setNames(
  file.path(db, paste0(c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs")
)
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_table <- function(name) {
  path <- file.path(tables, paste0(name, ".csv"))
  if (!file.exists(path)) stop("Missing extracted report table: ", path, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

stocks <- read_db("stocks")
assessments <- read_db("assessments")
if (!stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("The Rockall haddock stock must exist and the assessment must not already exist.", call. = FALSE)
}
ages <- 1:8
catch <- read_table("table_8_7_catch_numbers")
land_frac <- read_table("table_8_8_landing_fraction")
catch_weight <- read_table("table_8_11_catch_weight_kg")
rockall_pt1 <- read_table("table_8_12_rockall_pt1_index")
modelled_mean <- read_table("table_8_13_modelled_q3_mean")
modelled_cv <- read_table("table_8_13_modelled_q3_cv")
n_at_age <- read_table("table_8_16_numbers_at_age")
f_at_age <- read_table("table_8_17_fishing_mortality_at_age")
summary <- read_table("table_8_18_summary")

check_age_table <- function(x, expected_years, allow_missing = FALSE) {
  stopifnot(identical(as.integer(x$year), as.integer(expected_years)))
  stopifnot(identical(names(x), c("year", as.character(ages))))
  values <- as.matrix(x[as.character(ages)])
  storage.mode(values) <- "numeric"
  if (!allow_missing) stopifnot(all(is.finite(values)))
  values
}
catch_values <- check_age_table(catch, 1991:2025)
land_frac_values <- check_age_table(land_frac, 1991:2025)
catch_weight_values <- check_age_table(catch_weight, 1991:2025)
pt1_values <- check_age_table(rockall_pt1, 1991:1997, allow_missing = TRUE)
stopifnot(sum(pt1_values == -1, na.rm = TRUE) == 1L)
pt1_values[pt1_values == -1] <- NA_real_
rockall_pt1[["8"]][rockall_pt1[["8"]] == -1] <- NA_real_
modelled_values <- check_age_table(modelled_mean, 1999:2025, allow_missing = TRUE)
modelled_cv_values <- check_age_table(modelled_cv, 1999:2025, allow_missing = TRUE)
n_values <- check_age_table(n_at_age, 1991:2025)
f_values <- check_age_table(f_at_age, 1991:2025)
stopifnot(
  identical(as.integer(summary$year), 1991:2025),
  identical(names(summary), c("year", "recruitment_low", "recruitment", "recruitment_high",
    "ssb_low", "ssb", "ssb_high", "fbar_low", "fbar", "fbar_high",
    "catch_low", "catch", "catch_high")),
  all(catch_values >= 0),
  all(land_frac_values >= 0 & land_frac_values <= 1),
  all(catch_weight_values > 0),
  all(is.na(pt1_values) | pt1_values >= 0),
  all(is.na(modelled_values) | modelled_values > 0),
  all(is.na(modelled_cv_values) | modelled_cv_values > 0),
  all(n_values > 0), all(f_values >= 0),
  identical(which(rowSums(is.na(modelled_values)) == 8L), c(2L, 6L, 12L)),
  identical(which(rowSums(is.na(modelled_cv_values)) == 8L), c(2L, 6L, 12L)),
  is.na(pt1_values[5, 8])
)

input_row <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", source_reference,
                       source_type = "official_table", transformation = "",
                       notes = "", sampling_time = NA_real_) {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = rep_len(basis, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey, n), sex = "combined", region = "ICES Division 6.b",
    season = "", year = rep_len(year, n),
    year_basis = ifelse(is.na(rep_len(year, n)), "", "calendar_year"),
    age = rep_len(age, n), value = value, unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
age_inputs <- function(type, measure, basis, x, unit, source_reference,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_type = "official_table", transformation = "",
                       notes = "", keep_missing = FALSE) {
  grid <- expand.grid(year = x$year, age = ages)
  grid$value <- as.vector(as.matrix(x[as.character(ages)]))
  if (!keep_missing) grid <- grid[is.finite(grid$value), , drop = FALSE]
  input_row(type, measure, basis, grid$year, grid$age, grid$value, unit,
    fleet = fleet, survey = survey, source_reference = source_reference,
    source_type = source_type, transformation = transformation,
    notes = notes, sampling_time = sampling_time)
}

inputs_add <- do.call(rbind, list(
  age_inputs("catch", "numbers_at_age", "numbers", catch,
    "thousand fish", paste(report, "Table 8.7, p. 290"),
    fleet = "International catch",
    transformation = "Retain the source values in thousands of fish.",
    notes = "Total catch numbers-at-age, including landings, discards and BMS; age 8 is 8+."),
  age_inputs("catch", "landings_fraction_at_age", "proportion", land_frac,
    "proportion", paste(report, "Table 8.8, p. 291"),
    fleet = "International catch",
    notes = "Fraction of total catch retained as landings; the table accounts for discards including BMS."),
  age_inputs("catch_weight", "weight_at_age", "kg_per_fish", catch_weight,
    "kg per fish", paste(report, "Table 8.11, p. 294"),
    fleet = "International catch",
    notes = "Mean weights-at-age in international catch (landings and discards); not the SAM stock-weight surface."),
  age_inputs("weight", "weight_at_age", "kg_per_fish", catch_weight,
    "kg per fish", paste(report, "Table 8.11, p. 294;", taf_stock_weight_code_url),
    source_type = "reconstructed_source_input",
    transformation = paste(
      "The pinned official TAF script reads cw.dat and writes its values",
      "unchanged to sw.dat; Table 8.11 supplies the cw.dat values."
    ),
    notes = paste(
      "SAM stock-weight observations; age 8 is 8+.",
      "These observations are modelled by SAM and are not the fitted",
      "stock-weight surface."
    )),
  age_inputs("index", "numbers_at_age", "index_scale", rockall_pt1,
    "native survey-index units", paste(report, "Table 8.12, p. 295"),
    survey = "Rockall pt1", sampling_time = 0.725,
    source_type = "official_table",
    transformation = "The printed -1 at age 8 in 1995 is treated as the source missing-value sentinel and omitted.",
    notes = "Scottish quarter-3 Rockall design-based index; ages 1-8 used by the assessment. Scale is relative and is not converted to abundance.",
    keep_missing = FALSE),
  age_inputs("index", "numbers_at_age", "index_scale", modelled_mean,
    "native survey-index units", paste(report, "Table 8.13, pp. 296-298"),
    survey = "Modelled Q3", sampling_time = 0.75,
    transformation = "Rows with all ages missing in 2000, 2004 and 2010 are omitted.",
    notes = "Modelled quarter-3 survey index mean; ages 1-8+; native index scale is retained."),
  age_inputs("index", "relative_standard_error", "relative_scale", modelled_cv,
    "coefficient of variation", paste(report, "Table 8.13, pp. 296-298"),
    survey = "Modelled Q3", sampling_time = 0.75,
    notes = "Published CVs retained on their original scale. The translation derives the corresponding relative log-SD from the CV; missing years are omitted."),
  input_row("M", "natural_mortality_at_age", "per_year", NA_real_, ages,
    c(0.3559, 0.2998, 0.2755, 0.2574, 0.2386, 0.2280, 0.2114, 0.2),
    "per year", source_reference = paste(report, "p. 272"),
    source_type = "official_document",
    notes = "Fixed time-invariant M-at-age from the 2026 scaled-Lorenzen profile; age 8 is 8+."),
  input_row("maturity", "maturity_at_age", "proportion", NA_real_, ages,
    c(0.24, 0.84, 0.99, 1, 1, 1, 1, 1), "proportion mature",
    source_reference = paste(report, "p. 273"), source_type = "official_document",
    notes = "Fixed maturity-at-age from quarter-3 survey data; age 8 is 8+." )
))

output_row <- function(type, measure, year, age = NA_real_, value, unit,
                       source_reference, notes, lwr = NA_real_, upr = NA_real_,
                       age_group = NULL) {
  if (is.null(age_group)) age_group <- ifelse(!is.na(age) & age == 8, "8+", "")
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "combined", region = "ICES Division 6.b",
    season = "", year = year, age = age,
    age_group = rep_len(age_group, length(value)), value = value,
    se = NA_real_, lwr = lwr, upr = upr, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}
age_outputs <- function(measure, x, values, unit, reference, notes) {
  grid <- expand.grid(year = x$year, age = ages)
  grid$value <- as.vector(values)
  output_row(if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age, grid$value, unit, reference, notes)
}
outputs_add <- do.call(rbind, list(
  age_outputs("numbers_at_age", n_at_age, n_values, "thousand fish",
    paste(report, "Table 8.16, pp. 315-316"),
    "Final SAM numbers-at-age; age 8 is the 8+ group. Point estimates are reported without age-specific uncertainty."),
  age_outputs("fishing_mortality_at_age", f_at_age, f_values, "per year",
    paste(report, "Table 8.17, pp. 317-318"),
    "Final SAM fishing mortality-at-age; age 8 is the 8+ group. Point estimates are reported without age-specific uncertainty."),
  output_row("biomass", "SSB", summary$year, value = summary$ssb,
    unit = "tonnes", source_reference = paste(report, "Table 8.18, pp. 319-320"),
    notes = "Published Low/Value/High bounds retained as lwr/value/upr. The table does not state interval coverage; these are not labelled as 95% intervals.",
    lwr = summary$ssb_low, upr = summary$ssb_high),
  output_row("recruitment", "recruitment", summary$year, age = 1,
    value = summary$recruitment, unit = "thousand fish",
    source_reference = paste(report, "Table 8.18, pp. 319-320"),
    notes = "Age-1 recruitment. Published Low/Value/High bounds retained; interval coverage is not stated.",
    lwr = summary$recruitment_low, upr = summary$recruitment_high),
  output_row("mortality", "Fbar", summary$year, value = summary$fbar,
    unit = "per year", source_reference = paste(report, "Table 8.18, pp. 319-320"),
    notes = "Fbar for ages 2-5. Published Low/Value/High bounds retained; interval coverage is not stated.",
    lwr = summary$fbar_low, upr = summary$fbar_high, age_group = "2-5"),
  output_row("catch", "total_biomass", summary$year, value = summary$catch,
    unit = "tonnes", source_reference = paste(report, "Table 8.18, pp. 319-320"),
    notes = "Estimated catch in tonnes. Published Low/Value/High bounds retained; interval coverage is not stated.",
    lwr = summary$catch_low, upr = summary$catch_high)
))

assumption_rows <- data.frame(
  assessment_id = assessment_id,
  component = c("assessment", "population", "recruitment", "F", "F", "M",
    "catch", "catch", "index", "index", "index", "index", "biology", "weight"),
  fleet = c(rep("", 6), "International catch", "International catch", rep("", 6)),
  survey = c(rep("", 9), "Rockall pt1", "Modelled Q3", "Modelled Q3", "", ""),
  sex = "combined", region = "ICES Division 6.b", season = "",
  setting = c("model_family", "age_structure", "process", "process", "age_correlation",
    "natural_mortality", "catch_observations", "observation_error", "survey_series",
    "sampling_time", "sampling_time", "observation_precision", "maturity", "stock_weight"),
  value = c("SAM age-structured state-space assessment",
    "Ages 1-8+, with age 8 as the plus group; assessment years 1991-2025",
    "Age-1 recruitment random walk",
    "F uses an AR(1) process with one shared process-variance parameter",
    "F-state keys ages 1-6 separately and ages 7-8 together; AR(1) correlation across ages",
    "Fixed time-invariant scaled-Lorenzen age profile from the 2026 report",
    "International catch-at-age includes landings, discards and BMS",
    "Catch observation variance shared by age; extra catch uncertainty is fitted for observations from 2011 onward",
    "Separate design-based Rockall pt1 (1991-1997) and modelled Q3 (1999-2025) survey series",
    "0.725, carried forward from the 2025 SAM object; 2026 report identifies quarter 3 only",
    "0.75, carried forward from the 2025 SAM object; 2026 report identifies quarter 3 only",
    paste(
      "Modelled Q3 CVs are used as relative observation weights; the TAF",
      "script replaces selected cohort-year CV cells with age-series",
      "maxima before converting them to weights."
    ),
    "Fixed time-invariant maturity-at-age based on quarter-3 survey data",
    "SAM estimates the stock-weight surface from catch-weight observations using a correlated biological process; the complete fitted surface is not published"),
  source_reference = c(
    rep(report, 9), rep(model_url, 2),
    paste(report, "Table 8.13;", taf_data_code_url), report,
    paste(report, "Table 8.11;", taf_stock_weight_code_url)
  ),
  notes = c(rep("2026 assessment represented by its current WGCSE report.", 9),
    rep("Exact sample times are not given in the 2026 report; values were verified in the overlapping 2025 SAM object and are carried forward as a documented approximation.", 2),
    paste(
      "Table 8.13 CVs are retained as published. TAF data.R replaces",
      "selected 2023-2025 CV cells with age-series maxima before",
      "weighting; exact unrounded adjusted values are absent from the",
      "public mirror."
    ),
    "Fixed values are transcribed from the 2026 report.",
    paste(
      "The TAF data_stockweights.R script copies cw.dat unchanged to",
      "sw.dat. These observations are reconstructed from Table 8.11; no",
      "complete fitted stock-weight surface was recovered."
    )),
  stringsAsFactors = FALSE
)

stock_add <- data.frame(
  stock_id = stock_id, charbonneau_id = "ICES-WGCSE_aeglefinus_ROCK6b",
  authority = "ICES", authority_stock_id = "had.27.6b",
  scientific_name = "Melanogrammus aeglefinus", common_name = "Rockall haddock",
  area = "ICES Division 6.b (Rockall)", region = "Northeast Atlantic",
  ocean = "Northeast Atlantic",
  notes = "ICES Rockall haddock stock; stock identity confirmed by WGCSE 2026 assessment report.",
  stringsAsFactors = FALSE
)
assessment_add <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026, terminal_year = 2025, estimate_terminal_year = 2025,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = "WGCSE 2026 production assessment",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2024,
  assessment_url = report_url, framework_url = framework_url,
  data_url = "", model_url = "", repository_url = taf_repository_url,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Current detailed assessment. The 2025 SAM fit object was inspected only to verify overlapping input values and survey sample times; it is not represented as the 2026 fit.",
    "The pinned public TAF code mirror confirms that Table 8.11 catch weights are copied unchanged into the SAM stock-weight observation file. The mirror does not include the raw input data or fitted outputs.",
    "The report does not provide the complete fitted stock-weight surface or age-specific uncertainty for N and F, and does not state coverage for summary Low/High bounds."
  ), stringsAsFactors = FALSE
)

append_rows <- function(name, rows) {
  path <- paths[[name]]
  columns <- names(read_db(name))
  if (!setequal(names(rows), columns)) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
stopifnot(
  nrow(inputs_add) == 1575L,
  nrow(outputs_add) == 700L,
  all(is.finite(inputs_add$value)), all(is.finite(outputs_add$value)),
  !anyDuplicated(paste(inputs_add$type, inputs_add$measure, inputs_add$survey,
    inputs_add$year, inputs_add$age, sep = "\034")),
  !anyDuplicated(paste(outputs_add$measure, outputs_add$year, outputs_add$age, sep = "\034")),
  all(assumption_rows$assessment_id == assessment_id)
)

stock_lines <- readLines(paths[["stocks"]], warn = FALSE, encoding = "UTF-8")
stock_row <- which(startsWith(stock_lines, paste0('"', stock_id, '"')))
if (length(stock_row) != 1L) stop("Expected one existing Rockall haddock stock row.", call. = FALSE)
stock_lines[[stock_row]] <- capture.output(write.csv(stock_add, row.names = FALSE, na = ""))[[2L]]
writeLines(stock_lines, paths[["stocks"]], useBytes = TRUE)
append_rows("assessments", assessment_add)
append_rows("assumptions", assumption_rows)
append_rows("inputs", inputs_add)
append_rows("outputs", outputs_add)
cat("Imported Rockall haddock 2026: ", nrow(inputs_add), " inputs and ",
  nrow(outputs_add), " outputs.\n", sep = "")
