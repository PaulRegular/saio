assessment_id <- "ices_cod_northern_coastal_2026"
stock_id <- "ices_cod_northern_coastal"
report_url <- "https://ices-library.figshare.com/articles/report/Arctic_Fisheries_Working_Group_AFWG_/32134696"
report_doi <- "https://doi.org/10.17895/ices.pub.32134696.v1"
framework_url <- "https://doi.org/10.17895/ices.pub.7920"
stock_graph_url <- "https://standardgraphs.ices.dk/ViewCharts.aspx?key=22637"
repository_url <- "https://github.com/ices-taf/2026_cod.27.1-2coastN_assessment"

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
database_dir <- file.path(base, "database")
report_file <- file.path(
  base, "source_cache", "ck_ices_afwg_morhua_coastnor_1_2",
  "assessment_2026", "AFWG 2026 Report.pdf"
)
if (!file.exists(report_file)) {
  stop("Cache the AFWG 2026 report before running this importer.", call. = FALSE)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("The source import requires the pdftools package.", call. = FALSE)
}

pdf_pages <- pdftools::pdf_text(report_file)

find_page <- function(text) {
  matches <- which(vapply(pdf_pages, grepl, logical(1),
    pattern = text, fixed = TRUE
  ))
  if (!length(matches)) stop("Could not find report text: ", text, call. = FALSE)
  matches[[1L]]
}

table_text <- function(heading, next_heading) {
  first_page <- find_page(heading)
  next_pages <- which(vapply(pdf_pages, grepl, logical(1),
    pattern = next_heading, fixed = TRUE
  ))
  next_pages <- next_pages[next_pages >= first_page]
  last_page <- if (length(next_pages)) next_pages[[1L]] else min(first_page + 4L, length(pdf_pages))
  text <- paste(pdf_pages[seq.int(first_page, last_page)], collapse = "\n")
  start <- regexpr(heading, text, fixed = TRUE)[[1L]]
  text <- substring(text, start)
  end <- regexpr(next_heading, text, fixed = TRUE)[[1L]]
  if (end > 0L) text <- substring(text, 1L, end - 1L)
  text
}

report_table <- function(heading, next_heading, years, field_count) {
  lines <- unlist(strsplit(table_text(heading, next_heading), "\n", fixed = TRUE))
  candidate <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines)]
  tokens <- strsplit(trimws(candidate), "[[:space:]]+")
  row_years <- suppressWarnings(as.integer(vapply(tokens, `[`, character(1), 1L)))
  keep <- lengths(tokens) == field_count & row_years %in% years
  tokens <- tokens[keep]
  row_years <- row_years[keep]
  if (anyDuplicated(row_years) || !setequal(row_years, years) || length(row_years) != length(years)) {
    stop("Unexpected year coverage in ", heading, ".", call. = FALSE)
  }
  values <- lapply(tokens, function(row) {
    suppressWarnings(as.numeric(gsub(",", "", row[-1L], fixed = TRUE)))
  })
  values <- do.call(rbind, values)[match(years, row_years), , drop = FALSE]
  rownames(values) <- as.character(years)
  values
}

survey_dat_block <- function(series, n_ages) {
  heading <- find_page("Table 2.2.12. Northern Norwegian coastal cod. Tuning data used in the final SAM run.")
  page_range <- seq.int(heading, min(heading + 1L, length(pdf_pages)))
  lines <- trimws(strsplit(paste(pdf_pages[page_range], collapse = "\n"),
    "\n", fixed = TRUE
  )[[1L]])
  start <- which(lines == series)
  if (length(start) != 1L) stop("Expected one survey block named ", series, ".", call. = FALSE)
  year_range <- as.integer(strsplit(lines[start + 1L], "[[:space:]]+")[[1L]])
  timing <- as.numeric(strsplit(lines[start + 2L], "[[:space:]]+")[[1L]])
  age_range <- as.integer(strsplit(lines[start + 3L], "[[:space:]]+")[[1L]])
  years <- seq.int(year_range[[1L]], year_range[[2L]])
  if (length(timing) != 4L || !all(timing[3:4] == 0.8) ||
    length(age_range) != 2L ||
    (!all(age_range == -1L) && diff(age_range) + 1L != n_ages)) {
    stop("Unexpected survey configuration for ", series, ".", call. = FALSE)
  }
  next_section <- which(seq_along(lines) > start & grepl(
    "^(Norw-Coast-Ac-Q4|Table 2.2.13)", lines
  ))
  end <- if (length(next_section)) next_section[[1L]] - 1L else length(lines)
  candidates <- lines[seq.int(start + 4L, end)]
  rows <- lapply(candidates, function(line) {
    suppressWarnings(as.numeric(strsplit(line, "[[:space:]]+")[[1L]]))
  })
  rows <- rows[vapply(rows, function(row) {
    length(row) == n_ages + 1L && isTRUE(row[[1L]] == 1)
  }, logical(1))]
  if (any(lengths(rows) != n_ages + 1L)) {
    stop("Unexpected number of columns in survey block ", series, ": ",
      paste(lengths(rows), collapse = ","), ".", call. = FALSE)
  }
  if (length(rows) != length(years)) {
    stop("Unexpected number of observations in survey block ", series, ".", call. = FALSE)
  }
  values <- do.call(rbind, rows)
  if (any(values[, 1L] != 1, na.rm = TRUE)) {
    stop("Survey observations have non-unit weights in ", series, ".", call. = FALSE)
  }
  list(years = years, values = values[, -1L, drop = FALSE], sampling_time = timing[[3L]])
}

years <- 1994:2025
ages <- 2:10
catch <- report_table(
  "Table 2.2.3c. Northern Norwegian coastal cod. Total estimated catch number",
  "Table 2.2.4. Northern Norwegian coastal cod. Mean catch weight at age",
  years, 11L
)[, 1:9, drop = FALSE]
catch_weight <- report_table(
  "Table 2.2.4. Northern Norwegian coastal cod. Mean catch weight at age",
  "Table 2.2.5. Northern Norwegian coastal cod. Acoustic total abundance",
  years, 10L
)
acoustic_reference <- report_table(
  "Table 2.2.5. Northern Norwegian coastal cod. Acoustic total abundance",
  "Table 2.2.6. Northern Norwegian coastal cod. Swept-area abundance indices by age",
  1995:2025, 7L
)
swept_reference <- report_table(
  "Table 2.2.6. Northern Norwegian coastal cod. Swept-area abundance indices by age",
  "Table 2.2.7. Northern Norwegian coastal cod. Swept-area abundance index coefficient of variation",
  2003:2025, 12L
)
maturity <- report_table(
  "Table 2.2.11. Northern Norwegian coastal cod. Maturity-at-age",
  "Table 2.2.12. Northern Norwegian coastal cod. Tuning data used in the final SAM run",
  1995:2025, 11L
)
stock_weight <- report_table(
  "Table 2.2.13. Northern Norwegian coastal cod. Stock mean weight-at-age",
  "Table 2.2.14. Northern Norwegian coastal cod. Natural mortality-at-age",
  years, 10L
)
natural_mortality <- report_table(
  "Table 2.2.14. Northern Norwegian coastal cod. Natural mortality-at-age",
  "Table 2.2.15. Northern Norwegian coastal cod. SAM configuration",
  years, 10L
)
aggregate <- report_table(
  "Table 2.2.17. Northern Norwegian coastal cod. SAM output. Estimated recruitment",
  "Table 2.2.18. Northern Norwegian coastal cod. SAM output. Estimated fishing mortalities at age",
  years, 13L
)
f_at_age <- report_table(
  "Table 2.2.18. Northern Norwegian coastal cod. SAM output. Estimated fishing mortalities at age",
  "Table 2.2.19. Northern Norwegian coastal cod. SAM output. Estimated stock numbers-at-age",
  years, 10L
)
n_at_age <- report_table(
  "Table 2.2.19. Northern Norwegian coastal cod. SAM output. Estimated stock numbers-at-age",
  "Table 2.2.20a. Northern Norwegian coastal cod. Assumptions for the interim year",
  years, 10L
)

acoustic_1 <- survey_dat_block("Norw-Coast-Ac-Q4-1995(Aco)", 1L)
acoustic_2 <- survey_dat_block("Norw-Coast-Ac-Q4-2003(Aco)", 1L)
swept <- survey_dat_block("Norw-Coast-Ac-Q4(BTr)", length(ages))
acoustic <- c(acoustic_1$values[, 1L], acoustic_2$values[, 1L])
acoustic_years <- c(acoustic_1$years, acoustic_2$years)
expected_acoustic <- acoustic_reference[match(acoustic_years, 1995:2025), 4L]
finite_acoustic <- is.finite(acoustic) & is.finite(expected_acoustic)
acoustic_mismatch <- finite_acoustic & acoustic != expected_acoustic
if (any(acoustic_mismatch & acoustic_years != 2000L) ||
  acoustic[match(2000L, acoustic_years)] != 35255 ||
  expected_acoustic[match(2000L, acoustic_years)] != 35243 ||
  !is.na(acoustic[match(2021L, acoustic_years)])) {
  stop("The final-run acoustic series has an unexpected difference from Table 2.2.5.",
    call. = FALSE)
}
if (!identical(swept$years, 2003:2025) ||
  !isTRUE(all.equal(swept$values, swept_reference[, 1:9, drop = FALSE], check.attributes = FALSE))) {
  stop("The final-run swept-area series does not match Table 2.2.6.", call. = FALSE)
}

read_db <- function(name) {
  read.csv(file.path(database_dir, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE
  )
}
stocks <- read_db("stocks.csv")
assessments <- read_db("assessments.csv")
assumptions <- read_db("assumptions.csv")
inputs <- read_db("inputs.csv")
outputs <- read_db("outputs.csv")

empty_rows <- function(schema, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(schema)),
    stringsAsFactors = FALSE
  )
  names(out) <- schema
  out
}
format_number <- function(x) ifelse(
  is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), ""
)
make_inputs <- function(type, measure, basis, years, ages, values, unit,
                        source_reference, fleet = "", survey = "",
                        sampling_time = NA_real_, transformation = "",
                        notes = "", source_type = "official_table") {
  if (length(ages) == 1L && ncol(as.matrix(values)) == 1L) {
    grid <- data.frame(year = years, age = ages)
    value <- as.numeric(values)
  } else {
    grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
    value <- as.numeric(as.matrix(values)[cbind(
      match(grid$year, years), match(grid$age, ages)
    )])
  }
  out <- empty_rows(names(inputs), nrow(grid))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- fleet
  out$survey <- survey
  out$year <- as.character(grid$year)
  out$year_basis <- "calendar_year"
  out$age <- as.character(grid$age)
  out$value <- format_number(value)
  out$unit <- unit
  out$sampling_time <- if (is.finite(sampling_time)) format_number(sampling_time) else ""
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out
}

input_rows <- list(
  make_inputs("catch", "numbers_at_age", "numbers", years, ages, catch,
    "thousand fish", paste(report_doi, "Table 2.2.3c, printed pp. 68-69"),
    fleet = "Total catch", notes = "Total estimated catch includes commercial, recreational, and tourist catches. Age 10 is the 10+ plus group; source values are rounded to thousands of fish."),
  make_inputs("catch_weight", "weight_at_age", "kg_per_fish", years, ages, catch_weight,
    "kg per fish", paste(report_doi, "Table 2.2.4, printed pp. 70-71"),
    fleet = "Total catch", notes = "Mean catch weight-at-age used in the assessment."),
  make_inputs("weight", "weight_at_age", "kg_per_fish", years, ages, stock_weight,
    "kg per fish", paste(report_doi, "Table 2.2.13, printed pp. 81-82"),
    notes = "Stock weight-at-age used in the assessment. Ages 8-10+ use catch weights; 1994 ages 2-7 are means of stock weights for 1995-1997."),
  make_inputs("M", "natural_mortality_at_age", "per_year", years, ages, natural_mortality,
    "per year", paste(report_doi, "Table 2.2.14, printed pp. 82-83"),
    transformation = "Annual natural mortality-at-age values reported by the assessment, derived from stock weight-at-age using the Lorenzen (1996) method.",
    notes = "Natural mortality is supplied as a known input and is not estimated by SAM."),
  make_inputs("maturity", "maturity_at_age", "proportion", 1995:2025, 1:10,
    maturity, "proportion mature", paste(report_doi, "Table 2.2.11, printed pp. 78-79"),
    sampling_time = 0.8,
    notes = "Annual maturity at age from the coastal survey. Age 10 is the 10+ group. No data were collected in 2022; the reported value is the mean of 2021 and 2023."),
  make_inputs("index", "index_by_age_group", "biomass", acoustic_years, 2,
    matrix(acoustic, ncol = 1L), "tonnes", paste(report_doi, "Table 2.2.12, printed p. 80"),
    survey = c(rep("Coastal acoustic biomass 1995-2002", length(acoustic_1$years)),
      rep("Coastal acoustic biomass 2003-2025", length(acoustic_2$years))),
    sampling_time = 0.8,
    notes = "Aggregate age-2+ biomass index from final-run Table 2.2.12; 2021 is missing because it was excluded for high uncertainty. The 2000 final-run value (35,255 t) differs from Table 2.2.5 (35,243 t), so the final tuning value is retained. tinyAM's age-specific index likelihood cannot use this aggregate series."),
  make_inputs("index", "numbers_at_age", "numbers", swept$years, ages,
    swept$values, "thousand fish", paste(report_doi, "Table 2.2.12, printed pp. 80-81"),
    survey = "Coastal swept-area index", sampling_time = 0.8,
    notes = "Age-specific swept-area abundance index in thousands of fish; age 10 is 10+. The source survey.dat observation weights are all 1.")
)
inputs_new <- do.call(rbind, input_rows)
rownames(inputs_new) <- NULL

assumption_values <- data.frame(
  component = c(
    "population", "population", "population", "recruitment", "F", "F", "F",
    "M", "index", "index", "index", "index", "index", "index", "catch",
    "catch", "SSB", "assessment"
  ),
  survey = c(
    "", "", "", "", "", "", "", "", "", "", "", "", "", "",
    "", "", "", ""
  ),
  setting = c(
    "model", "age_range", "N_process", "recruitment_age", "F_process",
    "F_age_sharing", "F_age_correlation", "natural_mortality",
    "acoustic_index", "acoustic_q", "swept_index", "swept_q",
    "observation_likelihood", "observation_weights", "observation_likelihood",
    "observation_variance", "SSB_timing", "initial_state_distribution"
  ),
  value = c(
    "SAM (State-space Assessment Model)", "Ages 2-10+, with age 10 as the plus group",
    "Log-abundance random walk; age-2 recruitment variance is separate and ages 3-10 share survival variance",
    "Age 3; the modeled population starts at age 2",
    "Log-F random walk with age-correlated increments",
    "F states at ages 7-9 are shared",
    "AR(1) correlation across ages",
    "Known annual age-specific values derived from stock weights using Lorenzen (1996); not estimated",
    "Aggregate biomass at age 2+; separate series for 1995-2002 and 2003-2025; 2021 omitted",
    "One q for each acoustic period",
    "Age-specific abundance index at ages 2-10+ for 2003-2025",
    "Separate q at ages 2, 3, 4, and 10+; one shared q at ages 5-9",
    "Lognormal for catch and all indices",
    "All final-run survey.dat observation weights are 1; fixVarToWeight=0",
    "Catch observation variance is shared across ages; the two acoustic periods and swept-area index have separate variance parameters",
    "Swept-area index observation residuals use AR(1) correlation across ages; acoustic and catch observations are independent",
    "Survey-time SSB at 0.8 of the year (October); actual spawning occurs March-June",
    "unknown"
  ),
  source_reference = c(
    rep(paste(report_doi, "Table 2.2.15, printed pp. 83-87"), 8L),
    paste(report_doi, "Tables 2.2.5, 2.2.12, printed pp. 72, 80-81"),
    paste(report_doi, "Table 2.2.16, printed p. 87"),
    paste(report_doi, "Table 2.2.12, printed pp. 80-81"),
    paste(report_doi, "Table 2.2.16, printed p. 87"),
    rep(paste(report_doi, "Table 2.2.15, printed pp. 83-87"), 4L),
    paste(report_doi, "Section 2.2.6 and Table 2.2.17, printed pp. 63, 88-89"),
    paste(report_doi, "Table 2.2.15, printed pp. 83-87")
  ),
  notes = c(
    rep("The report documents this final configuration field; the cited TAF repository could not be retrieved publicly.", 7L),
    "The model uses the annual age-specific mortality input; Table 2.2.14 reports values derived from stock weights.",
    "The report states that the 2021 acoustic index was removed because of high uncertainty.",
    "The two index phases have separate catchability parameters.",
    "Both retained surveys are sampled at 0.8 of the year.",
    "The report states the q sharing by age; tinyAM retains the age-specific swept index but not aggregate acoustic biomass.",
    "Likelihood and variance configuration from the final SAM table.",
    "The relative observation weights are 1; SAM estimates rather than fixes observation variances.",
    "Catch variance is shared across ages; the index phases and swept survey each have separate variance parameters.",
    "Age-correlation in survey residuals is not represented in tinyAM.",
    "Use this survey-time definition when interpreting native SSB.",
    "The final native model object/configuration was not retrievable from the TAF URL cited in the report; no initial-state prior or integration method is inferred."
  ),
  stringsAsFactors = FALSE
)
assumptions_new <- empty_rows(names(assumptions), nrow(assumption_values))
assumptions_new$assessment_id <- assessment_id
assumptions_new$component <- assumption_values$component
assumptions_new$survey <- assumption_values$survey
assumptions_new$setting <- assumption_values$setting
assumptions_new$value <- assumption_values$value
assumptions_new$source_reference <- assumption_values$source_reference
assumptions_new$notes <- assumption_values$notes

output_rows <- function(type, measure, years = NA_integer_, ages = NA_integer_,
                        age_group = "", values, unit, source_reference,
                        survey = "", lwr = rep(NA_real_, length(values)),
                        upr = rep(NA_real_, length(values)), notes = "") {
  n <- length(values)
  out <- empty_rows(names(outputs), n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$survey <- rep_len(survey, n)
  out$year <- ifelse(is.na(rep_len(years, n)), "", as.character(rep_len(years, n)))
  out$age <- ifelse(is.na(rep_len(ages, n)), "", as.character(rep_len(ages, n)))
  if ("age_group" %in% names(out)) out$age_group <- rep_len(age_group, n)
  out$value <- format_number(values)
  out$lwr <- format_number(lwr)
  out$upr <- format_number(upr)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- rep_len(notes, n)
  out
}
grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
matrix_values <- function(x) as.numeric(x[cbind(match(grid$year, years), match(grid$age, ages))])
outputs_new <- rbind(
  output_rows("population", "numbers_at_age", grid$year, grid$age, values = matrix_values(n_at_age),
    unit = "thousand fish", source_reference = paste(report_doi, "Table 2.2.19, printed pp. 91-92"),
    notes = "Point estimates only; age 10 is the 10+ plus group."),
  output_rows("mortality", "fishing_mortality_at_age", grid$year, grid$age, values = matrix_values(f_at_age),
    unit = "per year", source_reference = paste(report_doi, "Table 2.2.18, printed pp. 90-91"),
    notes = "Point estimates only; F at ages 7-9 is shared in the SAM configuration."),
  output_rows("recruitment", "recruitment", years, 3L, values = aggregate[, 1L],
    unit = "thousand fish", source_reference = paste(report_doi, "Table 2.2.17, printed pp. 88-89"),
    lwr = aggregate[, 2L], upr = aggregate[, 3L],
    notes = "Recruitment is reported at age 3; table limits are the 2.5% and 97.5% confidence limits."),
  output_rows("biomass", "SSB", years, values = aggregate[, 4L], unit = "tonnes",
    source_reference = paste(report_doi, "Table 2.2.17, printed pp. 88-89"),
    lwr = aggregate[, 5L], upr = aggregate[, 6L],
    notes = "Survey-time SSB at 0.8 of the year; reported 2.5% and 97.5% confidence limits."),
  output_rows("mortality", "Fbar", years, age_group = "4-8", values = aggregate[, 7L],
    unit = "per year", source_reference = paste(report_doi, "Table 2.2.17, printed pp. 88-89"),
    lwr = aggregate[, 8L], upr = aggregate[, 9L],
    notes = "Arithmetic Fbar for ages 4-8; reported 2.5% and 97.5% confidence limits."),
  output_rows("biomass", "total_biomass", years, values = aggregate[, 10L], unit = "tonnes",
    source_reference = paste(report_doi, "Table 2.2.17, printed pp. 88-89"),
    lwr = aggregate[, 11L], upr = aggregate[, 12L],
    notes = "Total stock biomass; reported 2.5% and 97.5% confidence limits."),
  output_rows("catchability", "q", values = c(0.219, 0.141, 0.065, 0.109, 0.150, 0.166, 0.201),
    ages = c(NA, NA, 2, 3, 4, NA, 10), age_group = c("2+", "2+", "", "", "", "5-9", ""),
    survey = c("Coastal acoustic biomass 1995-2002", "Coastal acoustic biomass 2003-2025",
      rep("Coastal swept-area index", 5)), unit = "unitless",
    source_reference = paste(report_doi, "Table 2.2.16, printed p. 87"),
    notes = "Reported catchability parameters; no uncertainty is shown in the source table.")
)
rownames(outputs_new) <- NULL

stock_values <- c(
  stock_id, "", "ICES", "cod.27.1-2.coastN", "Gadus morhua",
  "Northern Norwegian coastal cod", "ICES subareas 1 and 2 north of 67 degrees N",
  "Norwegian Sea and Barents Sea", "Northeast Atlantic",
  "Separate northern coastal-cod assessment after the 2021 WKBARFAR benchmark split. The legacy Charbonneau-Keith COASTNOR 1,2 record remains a composite pre-split entry and is not assigned to this stock."
)
stock_new <- as.data.frame(as.list(stock_values), stringsAsFactors = FALSE)
names(stock_new) <- names(stocks)
assessment_values <- c(
  assessment_id, stock_id, "2026", "2025", "2025", "annual", "SAM",
  "NCCN67_AFWG2025_v3 (as named in AFWG 2026)", "TRUE", "TRUE", "2021",
  report_doi, framework_url, stock_graph_url, repository_url, repository_url,
  "partial", "complete", "complete",
  "The 2026 AFWG report is the latest detailed official assessment recovered. Its cited TAF run could not be retrieved, so initial-state details remain unresolved. Source tables report catch-at-age in rounded thousands of fish; the canonical series reflects that published precision."
)
assessment_new <- as.data.frame(as.list(assessment_values), stringsAsFactors = FALSE)
names(assessment_new) <- names(assessments)

if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("The target stock or assessment already exists; review it before re-importing.", call. = FALSE)
}
if (any(inputs$assessment_id == assessment_id) ||
  any(assumptions$assessment_id == assessment_id) ||
  any(outputs$assessment_id == assessment_id)) {
  stop("Found orphaned rows for the target assessment; review before importing.", call. = FALSE)
}

stocks <- rbind(stocks, stock_new)
assessments <- rbind(assessments, assessment_new)
assumptions <- rbind(assumptions, assumptions_new)
inputs <- rbind(inputs, inputs_new)
outputs <- rbind(outputs, outputs_new)
write.csv(stocks, file.path(database_dir, "stocks.csv"), row.names = FALSE, na = "")
write.csv(assessments, file.path(database_dir, "assessments.csv"), row.names = FALSE, na = "")
write.csv(assumptions, file.path(database_dir, "assumptions.csv"), row.names = FALSE, na = "")
write.csv(inputs, file.path(database_dir, "inputs.csv"), row.names = FALSE, na = "")
write.csv(outputs, file.path(database_dir, "outputs.csv"), row.names = FALSE, na = "")
