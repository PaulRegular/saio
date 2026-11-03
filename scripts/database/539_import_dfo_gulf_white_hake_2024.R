root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_dfo_gulf_white_hake_2025")
pdf_path <- file.path(cache, "research_document_2025_008.pdf")
manifest <- utils::read.csv(
  file.path(cache, "sources.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
pdf_row <- match(basename(pdf_path), manifest$file)
if (is.na(pdf_row) || !file.exists(pdf_path) ||
  file.info(pdf_path)$size != as.numeric(manifest$bytes[pdf_row])) {
  stop("The cached DFO research document is missing or has changed size.", call. = FALSE)
}

sha256_file <- function(path) {
  result <- system2(
    "certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256"),
    stdout = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify the cached PDF checksum.", call. = FALSE)
  hashes
}
if (!identical(tolower(manifest$sha256[pdf_row]), sha256_file(pdf_path))) {
  stop("The cached DFO research document checksum does not match its manifest.", call. = FALSE)
}

pdf_pages <- pdftools::pdf_data(pdf_path)
parse_number <- function(x) {
  value <- gsub(",", "", paste0(x, collapse = ""))
  value <- gsub("[^0-9.\\-]", "", value)
  if (!nzchar(value) || identical(value, "-")) return(NA_real_)
  suppressWarnings(as.numeric(value))
}

cells_on_row <- function(page, y, column_starts, x_min, tolerance = 24) {
  row <- page[abs(page$y - y) < 0.5 & page$x > x_min, , drop = FALSE]
  row <- row[order(row$x), , drop = FALSE]
  cell <- vapply(row$x, function(x) {
    distance <- abs(column_starts - x)
    at <- which.min(distance)
    if (distance[at] <= tolerance) at else NA_integer_
  }, integer(1))
  out <- rep(NA_real_, length(column_starts))
  for (i in seq_along(column_starts)) {
    pieces <- row$text[cell == i & !is.na(cell)]
    if (length(pieces)) out[i] <- parse_number(pieces)
  }
  out
}

extract_grid <- function(pages, years, ages, age_groups, year_x_max,
                         column_starts, x_min, regions, tolerance = 24) {
  rows <- list()
  for (page_number in pages) {
    page <- pdf_pages[[page_number]]
    region <- regions[[as.character(page_number)]]
    year_words <- page[
      page$x <= year_x_max & page$text %in% as.character(years) &
        page$y >= region[[1]] & page$y <= region[[2]], , drop = FALSE
    ]
    for (j in seq_len(nrow(year_words))) {
      values <- cells_on_row(
        page, year_words$y[[j]], column_starts, x_min, tolerance
      )
      rows[[length(rows) + 1L]] <- data.frame(
        year = as.integer(year_words$text[[j]]),
        age = as.integer(ages), age_group = age_groups, value = values
      )
    }
  }
  out <- do.call(rbind, rows)
  if (!setequal(unique(out$year), years) || anyDuplicated(paste(out$year, out$age, sep = "|"))) {
    stop("The PDF age table has incomplete years or duplicate cells.", call. = FALSE)
  }
  out[order(out$year, match(out$age_group, age_groups)), , drop = FALSE]
}

extract_scalar_table <- function(pages, years, year_x_max, value_x,
                                 regions, tolerance = 18) {
  rows <- list()
  for (page_number in pages) {
    page <- pdf_pages[[page_number]]
    region <- regions[[as.character(page_number)]]
    year_words <- page[
      page$x <= year_x_max & page$text %in% as.character(years) &
        page$y >= region[[1]] & page$y <= region[[2]], , drop = FALSE
    ]
    for (j in seq_len(nrow(year_words))) {
      value <- cells_on_row(
        page, year_words$y[[j]], value_x, x_min = year_x_max,
        tolerance = tolerance
      )
      rows[[length(rows) + 1L]] <- data.frame(
        year = as.integer(year_words$text[[j]]), value = value
      )
    }
  }
  out <- do.call(rbind, rows)
  if (!setequal(out$year, years) || anyDuplicated(out$year) || anyNA(out$value)) {
    stop("The PDF scalar table has incomplete years or values.", call. = FALSE)
  }
  out[order(out$year), , drop = FALSE]
}

years <- 1978:2022
catch_total <- extract_scalar_table(
  pages = 74L:75L, years = years, year_x_max = 135, value_x = 474,
  regions = list("74" = c(110, Inf), "75" = c(80, Inf))
)
catch_age_groups <- c("0-2", as.character(3:12), "13+")
catch_age <- extract_grid(
  pages = 77L:78L, years = years, ages = c(0L, 3L:13L),
  age_groups = catch_age_groups, year_x_max = 120,
  column_starts = c(144, 182, 228, 278, 328, 378, 427, 477, 525, 576, 624, 672),
  x_min = 130, regions = list("77" = c(115, Inf), "78" = c(80, Inf))
)
rv_ages <- 2L:14L
rv_index <- extract_grid(
  pages = 79L:80L, years = years, ages = rv_ages,
  age_groups = as.character(rv_ages), year_x_max = 110,
  column_starts = c(116, 164, 212, 260, 308, 356, 404, 452, 500, 548, 596, 644, 692),
  x_min = 110, regions = list("79" = c(115, Inf), "80" = c(80, Inf))
)
rv_weight_ages <- c(2L:10L, 12L, 11L, 13L, 14L)
rv_weight <- extract_grid(
  pages = 81L:82L, years = years, ages = rv_weight_ages,
  age_groups = as.character(rv_weight_ages), year_x_max = 110,
  column_starts = c(108, 156, 204, 252, 300, 348, 396, 444, 492, 540, 588, 646, 694),
  x_min = 105, regions = list("81" = c(115, Inf), "82" = c(80, Inf))
)
rv_weight <- rv_weight[is.finite(rv_weight$value), , drop = FALSE]

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
register_path <- file.path(root, "discovery", "candidates.csv")
stocks_existing <- utils::read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- utils::read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assumptions_existing <- utils::read.csv(assumptions_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
inputs_existing <- utils::read.csv(inputs_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
outputs_existing <- utils::read.csv(outputs_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
register <- utils::read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock_id <- "dfo_white_hake_4t"
assessment_id <- "dfo_white_hake_4t_2024"
candidate_id <- "DFO:Gulf:White Hake - NAFO 4T"
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
  register$candidate_unit_id[candidate_row] != "dfo_sff_2024_gulf_white_hake_nafo_4t" ||
  register$eligibility[candidate_row] != "eligible" ||
  register$match_status[candidate_row] != "new" ||
  register$import_status[candidate_row] != "not_started") {
  stop("The candidate identity or screening status has changed.", call. = FALSE)
}
if (stock_id %in% stocks_existing$stock_id || assessment_id %in% assessments_existing$assessment_id) {
  stop("The canonical white hake records already exist; refusing a duplicate.", call. = FALSE)
}

assessment_exists <- function(path) {
  con <- file(path, open = "rt")
  on.exit(close(con), add = TRUE)
  prefix <- paste0('"', assessment_id, '"')
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
if (any(vapply(c(assumptions_path, inputs_path, outputs_path), assessment_exists, logical(1)))) {
  stop("Canonical child rows already exist for this assessment.", call. = FALSE)
}

empty_rows <- function(template, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = ncol(template)), stringsAsFactors = FALSE)
  names(out) <- names(template)
  out
}
repeat_n <- function(x, n) {
  if (length(x) == 1L) rep(x, n) else if (length(x) == n) x else stop("A row field has an unexpected length.", call. = FALSE)
}
input_block <- function(type, measure, basis, value, unit, source_type,
                        source_reference, year = NA_integer_, age = NA_integer_,
                        fleet = "", survey = "", region = "", season = "",
                        notes = "", transformation = "") {
  n <- length(value)
  out <- empty_rows(inputs_existing, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- repeat_n(fleet, n)
  out$survey <- repeat_n(survey, n)
  out$region <- repeat_n(region, n)
  out$season <- repeat_n(season, n)
  year <- repeat_n(year, n)
  out$year <- ifelse(is.na(year), "", as.character(year))
  out$year_basis <- ifelse(is.na(year), "", "calendar_year")
  age <- repeat_n(age, n)
  out$age <- ifelse(is.na(age), "", as.character(age))
  out$value <- as.character(value)
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- repeat_n(transformation, n)
  out$notes <- repeat_n(notes, n)
  out
}

stock <- empty_rows(stocks_existing, 1L)
stock$stock_id <- stock_id
stock$charbonneau_id <- ""
stock$authority <- "DFO"
stock$authority_stock_id <- "NAFO Division 4T"
stock$scientific_name <- "Urophycis tenuis"
stock$common_name <- "White hake"
stock$area <- "NAFO Division 4T, southern Gulf of St. Lawrence"
stock$region <- "Southern Gulf of St. Lawrence"
stock$ocean <- "Northwest Atlantic"
stock$notes <- paste(
  "The assessed management unit is NAFO Division 4T. The report notes a broader biological stock unit extending into northwest 4Vn, but the population model includes 4T only.",
  "Distinct from the NOAA Gulf of Maine/Georges Bank white hake stock."
)

assessment <- empty_rows(assessments_existing, 1L)
assessment$assessment_id <- assessment_id
assessment$stock_id <- stock_id
assessment$assessment_year <- "2024"
assessment$terminal_year <- "2022"
assessment$estimate_terminal_year <- "2022"
assessment$assessment_type <- "full assessment"
assessment$model_family <- "Statistical catch-at-age"
assessment$model_version <- "AD Model Builder"
assessment$is_current <- "TRUE"
assessment$is_applied <- "TRUE"
assessment$assessment_url <- "https://open-science.canada.ca/server/api/core/bitstreams/28963929-7d4b-47c6-a56d-c0d705be4621/content"
assessment$framework_url <- ""
assessment$data_url <- ""
assessment$model_url <- ""
assessment$repository_url <- ""
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "The 2024 peer-reviewed assessment was fitted through 2022 and documented in Research Document 2025/008.",
  "No native model object or complete model input/output arrays were located."
)

assumption_values <- data.frame(
  component = c(
    "population", "maturity", "recruitment", "natural_mortality",
    "natural_mortality", "natural_mortality", "natural_mortality",
    "selectivity", "selectivity", "survey", "survey", "catchability",
    "likelihood", "likelihood"
  ),
  survey = c(rep("", 9L), "sGSL Research Vessel survey", "Mobile Sentinel survey", "sGSL Research Vessel survey", "", ""),
  setting = c(
    "model_years_and_ages", "maturity_schedule", "recruitment_process",
    "estimated_age_groups", "process", "log_deviation_prior", "initial_state_prior",
    "selectivity_forms", "fishery_time_blocks", "survey_timing", "survey_timing",
    "RV_series_structure", "age_composition_distribution", "objective_components"
  ),
  value = c(
    "1978-2022; ages 2-10+", "Knife-edge: ages 2-3 immature; age 4+ fully mature",
    "Age-2 recruitment uses log average recruitment, annual deviations, and an autocorrelation term",
    "2-3, 4-5, and 6+", "Independent log-scale random walk for each age group",
    "Normal prior on log M deviations", "Normal prior on initial M values",
    "Logistic functions for fishery and survey selectivity",
    "Separate fishery selectivity blocks for 1978-1995 and 1996-2022",
    "September; exact fraction of year not reported", "August; exact fraction of year not reported",
    "One catchability parameter for the continuous RV biomass-index series; survey conversion factors applied",
    "Multivariate logistic distribution for proportions-at-age",
    "Observed-versus-predicted age-aggregated biomass indices and proportions-at-age; normal priors for M and recruitment deviations"
  ),
  source_reference = c(
    rep("DFO Research Document 2025/008, §4.1, pp. 25-26", 9L),
    "DFO Research Document 2025/008, §3.1.1, p. 9",
    "DFO Research Document 2025/008, §3.2, p. 15",
    rep("DFO Research Document 2025/008, §4.1, p. 26", 3L)
  ),
  stringsAsFactors = FALSE
)
assumption_values$notes <- c(
  "Model years and age groups are reported in the population-model description.",
  "Maturity is an assessment assumption, not an observed maturity-at-age sample.",
  "The report describes the age-2 recruitment process; numerical process settings are not tabulated.",
  "M is estimated for these groups rather than supplied as a fixed input.",
  "The report does not provide the complete numerical prior specification.",
  "The report does not provide the complete numerical prior specification.",
  "The report does not provide the complete numerical prior specification.",
  "Form is reported for fishery and survey selectivity.",
  "A single continuous RV series with one q is the assessment model used for advice.",
  "Only survey month is available; no within-year sampling fraction is inferred.",
  "Only survey month is available; no within-year sampling fraction is inferred.",
  "One q is used instead of the split-series/two-q alternatives from prior models.",
  "Effective sample sizes are not specified for this composition likelihood.",
  "The report summarizes likelihood components but not their full numerical implementation."
)
assumptions <- empty_rows(assumptions_existing, nrow(assumption_values))
for (field in names(assumption_values)) assumptions[[field]] <- assumption_values[[field]]
assumptions$assessment_id <- assessment_id

catch_total_rows <- input_block(
  type = "catch", measure = "landings_biomass", basis = "biomass",
  value = catch_total$value, unit = "tonnes", source_type = "official_table",
  source_reference = "DFO Research Document 2025/008, Table A2, pp. 69-70",
  year = catch_total$year, fleet = "NAFO 4T commercial fishery",
  notes = "Nominal landings total across gears. The assessment methods specify total annual fishery catch; no recreational estimate, discard quantity, or 4Vn catch has been added."
)
catch_age_rows <- input_block(
  type = "catch", measure = "numbers_at_age_group", basis = "numbers",
  value = catch_age$value, unit = "thousand fish", source_type = "official_table",
  source_reference = "DFO Research Document 2025/008, Table A4, pp. 72-73",
  year = catch_age$year, age = catch_age$age, fleet = "NAFO 4T commercial fishery",
  notes = paste0(
    "Native printed age bin ", catch_age$age_group,
    "; age stores the lower age. These bins do not align with the fitted 2-10+ model grid.",
    ifelse(is.na(catch_age$value), " A dash in the source table is preserved as missing, not zero.", "")
  )
)
rv_index_rows <- input_block(
  type = "index", measure = "numbers_at_age", basis = "index_scale",
  value = rv_index$value, unit = "fish per tow", source_type = "official_table",
  source_reference = "DFO Research Document 2025/008, Table A5, pp. 74-75",
  year = rv_index$year, age = rv_index$age, survey = "sGSL Research Vessel survey",
  region = "strata 415-439", season = "September",
  notes = paste0(
    "Published stratified mean catch rate by age; table values are rounded to 0.001 fish per tow.",
    " 0.000 may reflect rounding. The assessment likelihood instead uses survey proportions-at-age and an age-aggregated biomass index for ages 2-7; these rows are retained as the reported age-specific series, not substituted for that likelihood."
  )
)
rv_weight_rows <- input_block(
  type = "weight", measure = "weight_at_age", basis = "kg_per_fish",
  value = rv_weight$value, unit = "kg per fish", source_type = "official_table",
  source_reference = "DFO Research Document 2025/008, Table A6, pp. 76-77",
  year = rv_weight$year, age = rv_weight$age, survey = "sGSL Research Vessel survey",
  region = "strata 415-439", season = "September",
  notes = paste0(
    "Printed age labels are retained, including the table's 12-before-11 column order. The report says missing age-year weights were predicted with a Gompertz model and all 2015-2022 weights were predicted; cell-specific observed-versus-predicted status is not tabulated."
  )
)
maturity_ages <- 2L:10L
maturity_values <- c(0, 0, rep(1, length(maturity_ages) - 2L))
maturity_rows <- input_block(
  type = "maturity", measure = "maturity_at_age", basis = "proportion",
  value = maturity_values, unit = "proportion", source_type = "official_document",
  source_reference = "DFO Research Document 2025/008, §4.1, p. 25",
  age = maturity_ages,
  notes = paste0(
    "Knife-edge maturity assumption: age 2-3 immature, age 4+ fully mature.",
    ifelse(maturity_ages == 10L, " Age 10 represents the fitted 10+ group.", "")
  )
)
inputs <- rbind(catch_total_rows, catch_age_rows, rv_index_rows, rv_weight_rows, maturity_rows)

output_values <- data.frame(
  type = c("biomass", "biomass", "biomass", "mortality", "mortality", "mortality", "mortality", "mortality", "mortality", "mortality", "mortality", "mortality", "mortality", "mortality"),
  measure = c("SSB", "SSB", "SSB", rep("natural_mortality_at_age", 8L), rep("fishing_mortality_at_age", 3L)),
  year = c(2000L, 2014L, 2022L, 1978L, 2022L, 1978L, 2004L, 2022L, 1978L, 2005L, 2022L, 1992L, 1992L, 1995L),
  age_group = c("", "", "", "2-3", "2-3", "4-5", "4-5", "4-5", "6+", "6+", "6+", "4-5", "6+", "6+"),
  value = c(6.0, 4.2, 6.1, 0.5, 1.1, 0.36, 2.3, 1.68, 0.31, 1.62, 1.05, 0.12, 0.72, 0.03),
  unit = c("kt", "kt", "kt", rep("per year", 11L)),
  source_reference = c(
    rep("DFO Research Document 2025/008, §4.2, p. 31", 3L),
    rep("DFO Research Document 2025/008, §4.2, p. 32", 11L)
  ),
  stringsAsFactors = FALSE
)
outputs <- empty_rows(outputs_existing, nrow(output_values))
for (field in names(output_values)) outputs[[field]] <- as.character(output_values[[field]])
outputs$assessment_id <- assessment_id
outputs$source_type <- "official_document"
outputs$notes <- paste(
  "Point estimate quoted in report narrative, rounded as printed; no numeric uncertainty accompanies this value in the text.",
  "The report describes median estimates from MCMC samples."
)

update_candidate_line <- function(path, row) {
  new_line <- paste(capture.output(utils::write.table(
    row, file = "", sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = ""
  )), collapse = "")
  text <- rawToChar(readBin(path, what = "raw", n = file.info(path)$size))
  line_match <- gregexpr(
    '(?m)^"DFO:Gulf:White Hake - NAFO 4T",[^\\r\\n]*(?=\\r?$)',
    text, perl = TRUE
  )[[1]]
  if (length(line_match) != 1L || line_match[[1]] < 0L) {
    stop("Could not safely locate the white hake candidate row.", call. = FALSE)
  }
  regmatches(text, list(line_match)) <- list(new_line)
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(text), connection)
}

candidate_update <- register[candidate_row, , drop = FALSE]
candidate_update$matched_stock_id <- stock_id
candidate_update$inventory_assessment_year <- 2024L
candidate_update$import_status <- "partial"
candidate_update$review_date <- "2026-11-02"
candidate_update$catch_age_evidence <- paste(
  "Research Document 2025/008 Table A4 reports grouped commercial catch numbers for 1978-2022 in thousands, with native bins 0-2, 3-12, and 13+.",
  "Table A2 reports annual 4T nominal landings totals."
)
candidate_update$survey_age_evidence <- paste(
  "Table A5 reports RV stratified catch rates at ages 2-14 in fish per tow for 1978-2022.",
  "The assessment uses age proportions and age-aggregated biomass indices for ages 2-7; numerical native index/composition vectors are not tabulated."
)
candidate_update$weights_evidence <- paste(
  "Table A6 reports RV mean weight-at-age in kg for ages 2-14, 1978-2022.",
  "Fishery and Mobile Sentinel numeric weight vectors were not recovered."
)
candidate_update$maturity_evidence <- "The 2024 assessment assumes knife-edge maturity: ages 2-3 immature and age 4+ fully mature."
candidate_update$mortality_evidence <- "The model estimates separate log-scale random-walk M series for ages 2-3, 4-5, and 6+; M is not a fixed input."
candidate_update$timing_evidence <- "The RV survey is conducted in September and Mobile Sentinel in August; exact within-month sampling fractions are not stated."
candidate_update$output_evidence <- paste(
  "The report prose gives rounded SSB estimates for 2000, 2014, and 2022 and selected F/M age-group values.",
  "Complete annual N/F/M surfaces and numerical uncertainty are not tabulated."
)
candidate_update$decision_reason <- paste(
  "The current 2024 assessment to 2022 has been imported as partial.",
  "Canonical records preserve the published grouped catch series, RV age-specific catch rates and weights, knife-edge maturity assumption, and selected reported outputs.",
  "Native aggregate indices, age-composition matrices, fishery/MS weights, and complete annual outputs remain unavailable."
)
candidate_update$notes <- paste(
  "This assessment uses the continuous RV series with one q estimate.",
  "See source_reviews/dfo_white_hake_4t.md for source mapping and remaining gaps."
)

candidate_test_path <- tempfile(fileext = ".csv")
if (!file.copy(register_path, candidate_test_path, overwrite = TRUE)) {
  stop("Could not prepare the candidate-register update check.", call. = FALSE)
}
update_candidate_line(candidate_test_path, candidate_update)
candidate_test <- utils::read.csv(candidate_test_path, stringsAsFactors = FALSE)
if (candidate_test$import_status[candidate_row] != "partial" ||
  candidate_test$matched_stock_id[candidate_row] != stock_id) {
  stop("The candidate-register update did not preserve its target values.", call. = FALSE)
}
unlink(candidate_test_path)

append_rows <- function(rows, path) {
  utils::write.table(
    rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}
if (identical(Sys.getenv("TINYAM_IMPORT_DRY_RUN"), "1")) {
  cat(
    "Dry run validated ", nrow(assumptions), " assumptions, ",
    nrow(inputs), " inputs (", sum(is.na(suppressWarnings(as.numeric(inputs$value)))),
    " missing source cells), and ", nrow(outputs),
    " selected output values; canonical files were not changed.\n", sep = ""
  )
} else {
  append_rows(stock, stocks_path)
  append_rows(assessment, assessments_path)
  append_rows(assumptions, assumptions_path)
  append_rows(inputs, inputs_path)
  append_rows(outputs, outputs_path)
  update_candidate_line(register_path, candidate_update)
  cat(
    "Imported ", stock_id, ": ", nrow(assumptions), " assumptions, ",
    nrow(inputs), " inputs, and ", nrow(outputs),
    " selected output values. Completeness remains partial.\n", sep = ""
  )
}
