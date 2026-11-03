assessment_id <- "ices_sole_celtic_7fg_2026"
stock_id <- "ck_ices_wgsce_solea_cs7f_7g"
report_ref <- "https://doi.org/10.17895/ices.pub.32625759"
database <- file.path("database")
pdf_file <- file.path("source_cache", "ices_sole_7fg_2026",
  "22 - Sole in 7fg.pdf"
)

if (!file.exists(pdf_file)) {
  cli::cli_abort("Cache the pinned ICES WGCSE 2026 sole in 7fg chapter before importing.")
}

read_table <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE
  )
}

format_value <- function(x) {
  ifelse(is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
}

pdf_lines <- unlist(strsplit(pdftools::pdf_text(pdf_file), "\n", fixed = TRUE),
  use.names = FALSE
)
table_marks <- grep("^\\s*Table 22\\.[0-9]+[a-z]?\\.", pdf_lines, perl = TRUE)
table_block <- function(number) {
  target <- grep(paste0("^\\s*Table 22\\.", number, "\\."), pdf_lines, perl = TRUE)
  if (length(target) != 1L) cli::cli_abort("Could not locate Table 22.{number} exactly once.")
  following <- table_marks[table_marks > target]
  last <- if (length(following)) following[[1L]] - 1L else length(pdf_lines)
  pdf_lines[seq.int(target, last)]
}

numeric_cells <- function(x) {
  x[x == "-"] <- NA_character_
  out <- suppressWarnings(as.numeric(x))
  if (any(is.na(out) & !is.na(x))) cli::cli_abort("Non-numeric cell in the pinned ICES table.")
  out
}

parse_age_table <- function(number) {
  block <- table_block(number)
  years <- NULL
  rows <- list()
  for (line in block) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) > 1L && tolower(cells[[1L]]) == "age") {
      parsed_years <- suppressWarnings(as.integer(cells[-1L]))
      if (length(parsed_years) && all(!is.na(parsed_years) & parsed_years >= 1900L)) years <- parsed_years
      next
    }
    if (is.null(years) || length(cells) != length(years) + 1L ||
      !grepl("^[0-9]+\\+?$", cells[[1L]])) next
    age <- as.integer(sub("\\+$", "", cells[[1L]]))
    rows[[length(rows) + 1L]] <- data.frame(
      year = years, age = age, value = numeric_cells(cells[-1L])
    )
  }
  if (!length(rows)) cli::cli_abort("No age rows were parsed from Table 22.{number}.")
  do.call(rbind, rows)
}

parse_index_table <- function() {
  block <- table_block("7")
  ages <- NULL
  rows <- list()
  for (line in block) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) > 1L && tolower(cells[[1L]]) %in% c("year/age", "year")) {
      parsed_ages <- suppressWarnings(as.integer(sub("\\+$", "", cells[-1L])))
      if (length(parsed_ages) && all(!is.na(parsed_ages))) ages <- parsed_ages
      next
    }
    if (is.null(ages) || length(cells) != length(ages) + 1L ||
      !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    rows[[length(rows) + 1L]] <- data.frame(
      year = as.integer(cells[[1L]]), age = ages,
      value = numeric_cells(cells[-1L])
    )
  }
  if (!length(rows)) cli::cli_abort("No year rows were parsed from Table 22.7.")
  do.call(rbind, rows)
}

parse_summary_table <- function() {
  block <- table_block("15")
  rows <- list()
  for (line in block) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) != 16L || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    rows[[length(rows) + 1L]] <- c(year = as.integer(cells[[1L]]), numeric_cells(cells[-1L]))
  }
  if (!length(rows)) cli::cli_abort("No annual rows were parsed from Table 22.15.")
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "recruitment_lwr", "recruitment", "recruitment_upr",
    "total_biomass_lwr", "total_biomass", "total_biomass_upr",
    "SSB_lwr", "SSB", "SSB_upr", "catch_lwr", "catch", "catch_upr",
    "Fbar_lwr", "Fbar", "Fbar_upr")
  out$year <- as.integer(out$year)
  out
}

parse_biomass_index <- function(series) {
  block <- table_block("10")
  header <- grep(paste0("^\\s*", gsub("([().+])", "\\\\\\1", series),
    "\\s+"), block, perl = TRUE)
  if (length(header) != 1L) cli::cli_abort("Could not uniquely locate tuning series {.val {series}}.")
  years_line <- strsplit(trimws(gsub("\\s+", " ", block[header + 1L])), " ", fixed = TRUE)[[1L]]
  years <- suppressWarnings(as.integer(years_line))
  if (length(years) != 2L || anyNA(years) || years[[1L]] > years[[2L]]) {
    cli::cli_abort("Unexpected year span for tuning series {.val {series}}.")
  }
  sentinel <- grep("^\\s*1\\s+-1\\s*$", block[(header + 2L):length(block)], perl = TRUE)
  if (!length(sentinel)) cli::cli_abort("Could not locate values for tuning series {.val {series}}.")
  start <- header + 2L + sentinel[[1L]]
  values <- numeric()
  for (line in block[seq.int(start, length(block))]) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) >= 2L && cells[[1L]] == "1" &&
      grepl("^-?[0-9]+(\\.[0-9]+)?$", cells[[2L]])) {
      values <- c(values, as.numeric(cells[[2L]]))
      if (length(values) == diff(years) + 1L) break
    }
  }
  if (length(values) != diff(years) + 1L) {
    cli::cli_abort("Tuning series {.val {series}} has {length(values)} values for {diff(years) + 1L} years.")
  }
  data.frame(year = seq.int(years[[1L]], years[[2L]]), value = values)
}

years <- 1971:2025
ages <- 1:10
catch <- parse_age_table("2")
catch_weight <- parse_age_table("3")
stock_weight <- parse_age_table("5")
f_at_age <- parse_age_table("13")
n_at_age <- parse_age_table("14")
survey_index <- parse_index_table()
summary <- parse_summary_table()
commercial_series <- c(
  "BE-CBT_1971-1983", "BE-CBT_1984-1996", "BE-CBT3-2006-2025",
  "UK(E&W)-CBT_1984-2005", "UK(E&W)-CBT_2006-2025"
)
commercial_indices <- do.call(rbind, lapply(commercial_series, function(series) {
  out <- parse_biomass_index(series)
  out$survey <- series
  out
}))

check_age_table <- function(x, label, allow_zero = FALSE) {
  if (nrow(x) != length(years) * length(ages) ||
    !setequal(unique(x$year), years) || !setequal(unique(x$age), ages) ||
    anyDuplicated(x[c("year", "age")]) || any(!is.finite(x$value)) ||
    any(if (allow_zero) x$value < 0 else x$value <= 0)) {
    cli::cli_abort("Unexpected coverage or values in {label}.")
  }
}
check_age_table(catch, "Table 22.2", allow_zero = TRUE)
check_age_table(catch_weight, "Table 22.3")
check_age_table(stock_weight, "Table 22.5")
check_age_table(f_at_age, "Table 22.13")
check_age_table(n_at_age, "Table 22.14")
if (nrow(survey_index) != 38L * 10L || !setequal(unique(survey_index$year), 1988:2025) ||
  !setequal(unique(survey_index$age), 0:9) || anyDuplicated(survey_index[c("year", "age")]) ||
  any(!is.finite(survey_index$value)) || any(survey_index$value < 0)) {
  cli::cli_abort("Unexpected coverage or values in Table 22.7.")
}
if (nrow(summary) != length(years) || !identical(summary$year, years) ||
  any(!is.finite(as.matrix(summary[-1L])))) {
  cli::cli_abort("Unexpected year coverage or missing values in Table 22.15.")
}
if (nrow(commercial_indices) != 88L || any(!is.finite(commercial_indices$value)) ||
  any(commercial_indices$value < 0)) {
  cli::cli_abort("Unexpected coverage or missing values in Table 22.10.")
}

stock_rows <- read_table("stocks.csv")
stock_index <- match(stock_id, stock_rows$stock_id)
assessment_rows <- read_table("assessments.csv")
if (is.na(stock_index) || any(assessment_rows$assessment_id == assessment_id, na.rm = TRUE)) {
  cli::cli_abort("Expected the metadata-only stock and no existing assessment rows.")
}

input_header <- names(read_table("inputs.csv"))
input_rows <- function(type, measure, basis, year, age, value, unit,
                       survey = "", fleet = "", sex = "", source_type = "official_table",
                       transformation = "Transcribed from the cited ICES WGCSE 2026 table.",
                       notes = "", source_reference = report_ref, season = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(input_header)), stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$sex <- rep_len(sex, n)
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

long_age <- function(x) {
  x$age <- as.integer(x$age)
  x$year <- as.integer(x$year)
  x
}
catch <- long_age(catch)
catch_weight <- long_age(catch_weight)
stock_weight <- long_age(stock_weight)
f_at_age <- long_age(f_at_age)
n_at_age <- long_age(n_at_age)
survey_index$year <- as.integer(survey_index$year)
commercial_indices$year <- as.integer(commercial_indices$year)
commercial_indices$age <- NA_integer_

maturity_values <- c(0, 0.67, 0.91, 0.98, 0.99, 0.99, rep(1, 9))
if (length(maturity_values) != 15L || any(maturity_values < 0 | maturity_values > 1)) {
  cli::cli_abort("Unexpected maturity vector.")
}
inputs <- rbind(
  input_rows("catch", "numbers_at_age", "numbers", catch$year, catch$age, catch$value,
    "thousand fish", transformation = "Table 22.2 values copied without rescaling.",
    notes = "Age 10 is the 10+ group. The model configuration excludes catch at ages 1 and 2 before 2004; source values remain recorded.",
    source_reference = paste(report_ref, "Table 22.2")),
  input_rows("catch_weight", "weight_at_age", "kg_per_fish", catch_weight$year, catch_weight$age,
    catch_weight$value, "kg per fish", transformation = "Table 22.3 values copied without rescaling.",
    notes = "Age 10 is the 10+ group.", source_reference = paste(report_ref, "Table 22.3")),
  input_rows("weight", "weight_at_age", "kg_per_fish", stock_weight$year, stock_weight$age,
    stock_weight$value, "kg per fish", transformation = "Table 22.5 values copied without rescaling.",
    notes = "Age 10 is the 10+ group.", source_reference = paste(report_ref, "Table 22.5")),
  input_rows("index", "numbers_at_age", "numbers", survey_index$year, survey_index$age,
    survey_index$value, "numbers per 100 km", survey = "UK(E&W)-BTS-Q3", season = "Q3",
    transformation = "Table 22.7 values copied without rescaling.",
    notes = "The official model uses ages 1-5; ages 0 and 6-9 are retained as source values. No zero observations occur at ages 1-5.",
    source_reference = paste(report_ref, "Table 22.7")),
  input_rows("index", "relative_biomass_index", "index_scale", commercial_indices$year,
    commercial_indices$age, commercial_indices$value, "relative biomass index (native scale)",
    survey = commercial_indices$survey, transformation = "Table 22.10 tuning-series values copied without rescaling.",
    notes = "Commercial beam-trawl biomass indices used by the official model. Physical units are not stated in the report.",
    source_reference = paste(report_ref, "Table 22.10")),
  input_rows("maturity", "maturity_at_age", "proportion", NA_integer_, 1:15,
    maturity_values, "proportion", transformation = "Copied from the maturity vector reported in the WGCSE 2026 assessment configuration.",
    notes = "Maturity is age-specific and applies to the assessment stock. The fitted assessment models ages 1-10+, with age 10 as the plus group.",
    source_reference = paste(report_ref, "Table 22.11")),
  input_rows("M", "natural_mortality_at_age", "per_year", NA_integer_, ages,
    rep(0.1, length(ages)), "per year", transformation = "Recorded from the assessment statement that M is fixed at 0.1 for all ages and years.",
    notes = "Fixed natural mortality; not an estimated output.", source_type = "official_document",
    source_reference = paste(report_ref, "Table 22.11"))
)

output_header <- names(read_table("outputs.csv"))
output_rows <- function(type, measure, year, age, age_group, value, unit,
                        lwr = NA_real_, upr = NA_real_, notes = "",
                        source_reference = report_ref) {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_header)), stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(rep_len(year, n))
  out$age <- ifelse(is.na(age), "", as.character(rep_len(age, n)))
  out$age_group <- rep_len(age_group, n)
  out$value <- format_value(rep_len(value, n))
  out$lwr <- format_value(rep_len(lwr, n))
  out$upr <- format_value(rep_len(upr, n))
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

outputs <- rbind(
  output_rows("population", "numbers_at_age", n_at_age$year, n_at_age$age, "",
    n_at_age$value, "thousand fish", notes = "Start-of-year stock numbers. Age 10 is the 10+ group.",
    source_reference = paste(report_ref, "Table 22.14")),
  output_rows("mortality", "fishing_mortality_at_age", f_at_age$year, f_at_age$age, "",
    f_at_age$value, "per year", notes = "Age 10 is the 10+ group.",
    source_reference = paste(report_ref, "Table 22.13")),
  output_rows("recruitment", "recruitment", summary$year, 1L, "",
    summary$recruitment, "thousand fish", summary$recruitment_lwr, summary$recruitment_upr,
    "Recruitment is age-1 abundance. Low/high bounds are as printed; their interval level is not stated in the table.",
    source_reference = paste(report_ref, "Table 22.15")),
  output_rows("biomass", "total_biomass", summary$year, NA_integer_, "",
    summary$total_biomass, "tonnes", summary$total_biomass_lwr, summary$total_biomass_upr,
    "Low/high bounds are as printed; their interval level is not stated in the table.",
    source_reference = paste(report_ref, "Table 22.15")),
  output_rows("biomass", "SSB", summary$year, NA_integer_, "",
    summary$SSB, "tonnes", summary$SSB_lwr, summary$SSB_upr,
    "Low/high bounds are as printed; their interval level is not stated in the table.",
    source_reference = paste(report_ref, "Table 22.15")),
  output_rows("catch", "predicted_catch", summary$year, NA_integer_, "",
    summary$catch, "tonnes", summary$catch_lwr, summary$catch_upr,
    "Model-estimated catch. Low/high bounds are as printed; their interval level is not stated in the table.",
    source_reference = paste(report_ref, "Table 22.15")),
  output_rows("mortality", "Fbar", summary$year, NA_integer_, "3-8",
    summary$Fbar, "per year", summary$Fbar_lwr, summary$Fbar_upr,
    "Fbar ages 3-8. Low/high bounds are as printed; their interval level is not stated in the table.",
    source_reference = paste(report_ref, "Table 22.15"))
)

assumption_header <- names(read_table("assumptions.csv"))
assumptions <- as.data.frame(matrix("", nrow = 10L, ncol = length(assumption_header)), stringsAsFactors = FALSE)
names(assumptions) <- assumption_header
assumptions$assessment_id <- assessment_id
assumptions$component <- "assessment"
assumptions$setting <- c("model_family", "model_age_range", "plus_group", "natural_mortality",
  "maturity_at_age", "fbar_ages", "recruitment_process", "f_process", "catch_observations",
  "survey_likelihood")
assumptions$value <- c("SAM", "1-10", "Age 10 is 10+", "Fixed at 0.1 for all ages and years",
  paste0("Ages 1-15: ", paste(maturity_values, collapse = ", ")),
  "3-8", "Plain random walk on log N at age 1", "AR(1) structure for log-F states",
  "Catch at ages 1 and 2 excluded before 2004", "UK(E&W)-BTS-Q3 abundance index; ages 1-5 used")
assumptions$source_reference <- report_ref
assumptions$notes <- c(
  "WGCSE 2026 assessment report, assessment configuration and results tables.",
  "The assessment reports ages 1-10, with age 10 as the plus group.",
  "Catch, weight, and population tables use age 10 as the plus group.",
  "M is fixed, not estimated.",
  "The source configuration reports an age-specific maturity vector.",
  "Fbar is the unweighted reported age range in the assessment configuration.",
  "Recruitment is represented as a plain random walk on log N at age 1.",
  "The report identifies an AR(1) F-state correlation structure.",
  "Source catch values are retained in the database; the fitted model omits these cells.",
  "The age-specific BTS observations are abundance indices, not age-composition sample counts.")

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2026", terminal_year = "2025", estimate_terminal_year = "2025",
  assessment_type = "annual", model_family = "SAM", model_version = "WGCSE 2026; sol.27.7fg",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "2020",
  assessment_url = report_ref, framework_url = "", data_url = "", model_url = "",
  repository_url = "", assumptions_status = "partial", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste("Official age-structured SAM assessment. Inputs and point estimates are transcribed from the detailed WGCSE 2026 report. No native fitted SAM object or full uncertainty surfaces for N/F-at-age were located. Commercial biomass tuning series are retained on their reported native scales; their physical units are not stated."),
  stringsAsFactors = FALSE
)

stock_rows$authority_stock_id[[stock_index]] <- "sol.27.7fg"
stock_rows$common_name[[stock_index]] <- "Celtic Sea common sole"
stock_rows$notes[[stock_index]] <- paste(
  stock_rows$notes[[stock_index]],
  "Official ICES WGCSE 2026 assessment added as ices_sole_celtic_7fg_2026; assessment area 7.f-g.",
  sep = " "
)

utils::write.table(stock_rows, file.path(database, "stocks.csv"), sep = ",", quote = TRUE,
  row.names = FALSE, na = "")
for (name in c("assessments", "assumptions", "inputs", "outputs")) {
  path <- file.path(database, paste0(name, ".csv"))
  rows <- switch(name, assessments = assessment_row, assumptions = assumptions,
    inputs = inputs, outputs = outputs)
  utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "")
}

cat("Imported", nrow(inputs), "inputs,", nrow(assumptions), "assumptions, and",
  nrow(outputs), "outputs for", assessment_id, "\n")
