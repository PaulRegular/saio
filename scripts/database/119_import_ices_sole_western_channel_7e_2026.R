assessment_id <- "ices_sole_western_channel_7e_2026"
stock_id <- "ck_ices_wgsce_solea_is7e"
report_ref <- "https://doi.org/10.17895/ices.pub.32625759"
sag_ref <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22656"
repository_ref <- "https://github.com/ices-advice/2026_sol.27.7e/tree/56b5e2aa66388e3e6709e4e4e84efacbad3324e9"
database <- file.path("database")
source_dir <- file.path("source_cache", "ices_sole_7e_2026")
pdf_file <- file.path(source_dir, "21 - Sole in 7e.pdf")
xml_file <- file.path(source_dir, "ICES_SAG_StockXml_22656.xml")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  cli::cli_abort("Install pdftools in the local source-review library before importing.")
}
if (!all(file.exists(c(pdf_file, xml_file)))) {
  cli::cli_abort("Cache the pinned ICES report chapter and SAG XML before importing.")
}

read_table <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE
  )
}
format_value <- function(x) {
  out <- rep("", length(x))
  ok <- is.finite(x)
  out[ok] <- format(x[ok], digits = 15, scientific = FALSE, trim = TRUE)
  out
}
numeric_cells <- function(x) {
  x[x == "-"] <- NA_character_
  out <- suppressWarnings(as.numeric(x))
  if (any(is.na(out) & !is.na(x))) cli::cli_abort("Non-numeric cell in the pinned ICES table.")
  out
}

pdf_lines <- unlist(strsplit(pdftools::pdf_text(pdf_file), "\n", fixed = TRUE), use.names = FALSE)
table_marks <- grep("^\\s*Table 21\\.[0-9]+[a-z]?\\.", pdf_lines, perl = TRUE)
table_block <- function(number) {
  target <- grep(paste0("^\\s*Table 21\\.", number, "\\."), pdf_lines, perl = TRUE)
  if (length(target) != 1L) cli::cli_abort("Could not locate Table 21.{number} exactly once.")
  following <- table_marks[table_marks > target]
  last <- if (length(following)) following[[1L]] - 1L else length(pdf_lines)
  pdf_lines[seq.int(target, last)]
}

parse_age_table <- function(number, n_columns) {
  rows <- list()
  for (line in table_block(number)) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) != n_columns || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    rows[[length(rows) + 1L]] <- numeric_cells(cells)
  }
  if (!length(rows)) cli::cli_abort("No year rows parsed from Table 21.{number}.")
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", paste0("v", seq_len(n_columns - 1L)))
  out$year <- as.integer(out$year)
  out
}

parse_summary_table <- function() {
  rows <- list()
  for (line in table_block(10)) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) != 7L || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    rows[[length(rows) + 1L]] <- numeric_cells(cells)
  }
  if (!length(rows)) cli::cli_abort("No annual data parsed from Table 21.10.")
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "recruitment", "total_biomass", "SSB", "landings", "yield_ssb", "Fbar")
  out$year <- as.integer(out$year)
  out
}

series_names <- c(
  "UK-CBT-late", "UK-COT", "Q1SWBeam-nonoffset", "FSP-UK",
  "UK-CBT-early", "UK-WEC-BTS"
)
parse_tuning_series <- function(series) {
  lines <- table_block(6)
  normalized <- trimws(lines)
  starts <- which(normalized == series)
  if (length(starts) != 1L) cli::cli_abort("Could not uniquely locate tuning series {.val {series}}.")
  other_starts <- which(normalized %in% series_names & seq_along(lines) > starts)
  end <- if (length(other_starts)) other_starts[[1L]] - 1L else length(lines)
  part <- lines[seq.int(starts + 1L, end)]
  pair_lines <- which(vapply(part, function(line) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    length(cells) == 2L && all(grepl("^[0-9]+$", cells))
  }, logical(1)))
  year_line <- pair_lines[which(vapply(part[pair_lines], function(line) {
    vals <- as.integer(strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]])
    length(vals) == 2L && all(vals >= 1900L)
  }, logical(1)))[1L]]
  if (!length(year_line) || is.na(year_line)) cli::cli_abort("Could not parse years for tuning series {.val {series}}.")
  year_bounds <- as.integer(strsplit(trimws(gsub("\\s+", " ", part[[year_line]])), " ", fixed = TRUE)[[1L]])
  years <- seq.int(year_bounds[[1L]], year_bounds[[2L]])
  age_lines <- pair_lines[pair_lines > year_line]
  age_line <- age_lines[[1L]]
  age_range <- as.integer(strsplit(trimws(gsub("\\s+", " ", part[[age_line]])), " ", fixed = TRUE)[[1L]])
  ages <- seq.int(age_range[[1L]], age_range[[2L]])
  numeric_line <- function(line) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    length(cells) > 0L && all(grepl("^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$", cells, perl = TRUE))
  }
  data_lines <- part[seq.int(age_line + 1L, length(part))]
  data_lines <- data_lines[vapply(data_lines, numeric_line, logical(1))]
  values <- as.numeric(unlist(strsplit(trimws(gsub("\\s+", " ", data_lines)), " ", fixed = TRUE), use.names = FALSE))
  expected <- length(years) * (length(ages) + 1L)
  if (length(values) != expected) {
    cli::cli_abort("Tuning series {.val {series}} contains {length(values)} numeric cells; expected {expected}.")
  }
  matrix_values <- matrix(values, nrow = length(years), byrow = TRUE)
  do.call(rbind, lapply(seq_along(years), function(i) {
    data.frame(
      year = years[[i]], effort = matrix_values[i, 1L], age = ages,
      catch_numbers = matrix_values[i, -1L],
      index = if (matrix_values[i, 1L] > 0) matrix_values[i, -1L] / matrix_values[i, 1L] else NA_real_
    )
  }))
}

parse_maturity <- function() {
  rows <- list()
  for (line in table_block(11)) {
    cells <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
    if (length(cells) != 11L || !grepl("^[0-9]+$", cells[[1L]])) next
    age <- as.integer(cells[[1L]])
    if (age %in% 2:12) rows[[length(rows) + 1L]] <- c(age = age, maturity = as.numeric(cells[[6L]]))
  }
  out <- as.data.frame(do.call(rbind, rows))
  if (!identical(as.integer(out$age), 2:12) || any(!is.finite(out$maturity)) || any(out$maturity < 0 | out$maturity > 1)) {
    cli::cli_abort("Unexpected maturity rows in Table 21.11.")
  }
  out$age <- as.integer(out$age)
  out
}

expand_age_table <- function(x, ages, values, plus = FALSE) {
  do.call(rbind, lapply(seq_len(nrow(x)), function(i) {
    data.frame(year = x$year[[i]], age = ages, value = as.numeric(x[i, values, drop = TRUE]))
  }))
}
parse_sag <- function() {
  xml <- paste(readLines(xml_file, warn = FALSE, encoding = "UTF-8"), collapse = "")
  blocks <- regmatches(xml, gregexpr("<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
  get_value <- function(block, tag) {
    pattern <- paste0("<", tag, ">(.*?)</", tag, ">")
    value <- regmatches(block, regexpr(pattern, block, perl = TRUE))
    if (!length(value) || !nzchar(value)) return(NA_real_)
    value <- sub(pattern, "\\1", value, perl = TRUE)
    if (!nzchar(value)) NA_real_ else as.numeric(value)
  }
  rows <- lapply(blocks, function(block) c(
    year = get_value(block, "Year"),
    recruitment = get_value(block, "Recruitment"),
    total_biomass = get_value(block, "TBiomass"),
    SSB = get_value(block, "StockSize"),
    Fbar = get_value(block, "FishingPressure")
  ))
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  out$year <- as.integer(out$year)
  out
}

years <- 1969:2025
ages <- 2:12
catch_wide <- parse_age_table(2, 13L)
catch_weight_wide <- parse_age_table(3, 12L)
stock_weight_wide <- parse_age_table(4, 12L)
n_wide <- parse_age_table(8, 13L)
f_wide <- parse_age_table(9, 13L)
summary <- parse_summary_table()
maturity <- parse_maturity()
series <- lapply(series_names[1:4], parse_tuning_series)
names(series) <- series_names[1:4]
sag <- parse_sag()

validate_annual_age <- function(x, table, value_columns, positive = FALSE) {
  if (nrow(x) != length(years) || !identical(x$year, years) ||
      any(!is.finite(as.matrix(x[value_columns]))) ||
      (positive && any(as.matrix(x[value_columns]) <= 0))) {
    cli::cli_abort("Unexpected year coverage or values in Table 21.{table}.")
  }
}
validate_annual_age(catch_wide, 2, names(catch_wide)[-1L], positive = FALSE)
validate_annual_age(catch_weight_wide, 3, names(catch_weight_wide)[-1L], positive = TRUE)
validate_annual_age(stock_weight_wide, 4, names(stock_weight_wide)[-1L], positive = TRUE)
validate_annual_age(n_wide, 8, names(n_wide)[-c(1L, 13L)], positive = TRUE)
validate_annual_age(f_wide, 9, names(f_wide)[-c(1L, 13L)], positive = FALSE)
if (!identical(summary$year, years) || any(!is.finite(as.matrix(summary[-1L])))) {
  cli::cli_abort("Unexpected coverage in Table 21.10.")
}
if (!identical(sag$year, 1969:2026) || any(!is.finite(as.matrix(sag[sag$year <= 2025L, -1L]))) || nrow(sag) != 58L) {
  cli::cli_abort("Unexpected coverage in the ICES SAG XML.")
}
for (i in seq_along(series)) {
  if (any(!is.finite(series[[i]]$effort)) || any(series[[i]]$effort < 0) ||
      any(is.finite(series[[i]]$index) & series[[i]]$index < 0)) {
    cli::cli_abort("Invalid tuning data in {.val {names(series)[[i]]}}.")
  }
}

n_long <- expand_age_table(n_wide, ages, names(n_wide)[-c(1L, 13L)])
f_long <- expand_age_table(f_wide, ages, names(f_wide)[-c(1L, 13L)])
catch_long <- expand_age_table(catch_wide, ages, names(catch_wide)[-c(1L, 13L)])
catch_weight_long <- expand_age_table(catch_weight_wide, ages, names(catch_weight_wide)[-1L])
stock_weight_long <- expand_age_table(stock_weight_wide, ages, names(stock_weight_wide)[-1L])

n_matrix <- matrix(n_long$value, nrow = length(years), byrow = TRUE)
stock_weight_matrix <- matrix(stock_weight_long$value, nrow = length(years), byrow = TRUE)
maturity_values <- maturity$maturity[match(ages, maturity$age)]
calc_tsb <- rowSums(n_matrix * stock_weight_matrix)
calc_ssb <- rowSums(n_matrix * stock_weight_matrix * rep(maturity_values, each = length(years)))
if (max(abs(calc_tsb - summary$total_biomass) / summary$total_biomass) > 0.001 ||
    max(abs(calc_ssb - summary$SSB) / summary$SSB) > 0.001) {
  cli::cli_abort("N × stock weight or N × stock weight × maturity does not reproduce Table 21.10 at rounding precision.")
}
sag_historical <- sag[match(years, sag$year), , drop = FALSE]
if (any(round(sag_historical$recruitment) != round(summary$recruitment)) ||
    any(round(sag_historical$total_biomass) != round(summary$total_biomass)) ||
    any(round(sag_historical$SSB) != round(summary$SSB)) ||
    any(round(sag_historical$Fbar, 3) != round(summary$Fbar, 3))) {
  cli::cli_abort("ICES SAG aggregate series do not agree with the 2026 assessment table.")
}

stock_rows <- read_table("stocks.csv")
stock_index <- match(stock_id, stock_rows$stock_id)
assessment_rows <- read_table("assessments.csv")
if (is.na(stock_index) || any(assessment_rows$assessment_id == assessment_id, na.rm = TRUE)) {
  cli::cli_abort("Expected the metadata-only stock and no existing assessment record.")
}
input_header <- names(read_table("inputs.csv"))
input_rows <- function(type, measure, basis, year, age, value, unit,
                       survey = "", fleet = "", sex = "", source_type = "official_table",
                       transformation = "Copied from the cited ICES WGCSE 2026 source table.",
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
output_header <- names(read_table("outputs.csv"))
output_rows <- function(type, measure, year, age, age_group, value, unit,
                        source_type = "official_table", notes = "", source_reference = report_ref) {
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
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

catch_rows <- input_rows("catch", "numbers_at_age", "numbers", catch_long$year, catch_long$age,
  catch_long$value, "thousand fish", fleet = "Landings", transformation = "Table 21.2 values copied without rescaling.",
  notes = "Landings numbers-at-age; the official XSA is landings-only. Age 12 is the 12+ group.",
  source_reference = paste(report_ref, "Table 21.2"))
catch_weight_rows <- input_rows("catch_weight", "weight_at_age", "kg_per_fish",
  catch_weight_long$year, catch_weight_long$age, catch_weight_long$value, "kg per fish",
  fleet = "Landings", transformation = "Table 21.3 values copied without rescaling.",
  notes = "Landings weight-at-age; age 12 is the 12+ group.", source_reference = paste(report_ref, "Table 21.3"))
stock_weight_rows <- input_rows("weight", "weight_at_age", "kg_per_fish",
  stock_weight_long$year, stock_weight_long$age, stock_weight_long$value, "kg per fish",
  transformation = "Table 21.4 values copied without rescaling.",
  notes = "Stock weight-at-age; age 12 is the 12+ group.", source_reference = paste(report_ref, "Table 21.4"))
maturity_rows <- input_rows("maturity", "maturity_at_age", "proportion", NA_integer_, maturity$age,
  maturity$maturity, "proportion", transformation = "Transcribed from Table 21.11 forecast inputs.",
  notes = "Time-invariant maturity at age; age 12 is the plus group.", source_reference = paste(report_ref, "Table 21.11"))
m_rows <- input_rows("M", "natural_mortality_at_age", "per_year", NA_integer_, ages,
  rep(0.1, length(ages)), "per year", source_type = "official_document",
  transformation = "Recorded from Table 21.11, which specifies M=0.1 at each age.",
  notes = "Fixed input, not estimated. Age 12 is the plus group.", source_reference = paste(report_ref, "Table 21.11"))
index_rows <- do.call(rbind, lapply(seq_along(series), function(i) {
  x <- series[[i]]
  input_rows("index", "numbers_at_age", "index_scale", x$year, x$age, x$index,
    "source index scale per effort unit (scale multiplier not stated)", survey = names(series)[[i]],
    source_type = "reconstructed_source_input",
    transformation = "Reconstructed as the reported VPA tuning-table catch-at-age divided by effort, following FLCore::readIndicesVPA input semantics.",
    notes = "The report tuning file preserves the underlying numerator and effort in separate rows. Zero effort gives an unavailable index. The 2026 model uses only its configured year and age range.",
    source_reference = paste(report_ref, "Table 21.6"))
}))
index_numerator_rows <- do.call(rbind, lapply(seq_along(series), function(i) {
  x <- series[[i]]
  input_rows("index", "index_catch_numbers_at_age", "numbers", x$year, x$age, x$catch_numbers,
    "source count scale (unit multiplier not stated)", survey = names(series)[[i]],
    transformation = "Transcribed from the per-age numerator in the Table 21.6 XSA tuning file.",
    notes = "Underlying catch-at-age used to reconstruct the per-effort index; not a separate catch observation.",
    source_reference = paste(report_ref, "Table 21.6"))
}))
effort_rows <- do.call(rbind, lapply(seq_along(series), function(i) {
  x <- unique(series[[i]][c("year", "effort")])
  input_rows("covariate", "effort", "native_covariate", x$year, NA_integer_, x$effort,
    "source effort units (scale not stated)", survey = names(series)[[i]],
    transformation = "Transcribed from the first numerical column of the Table 21.6 XSA tuning file.",
    notes = "Effort is the denominator used to construct the per-effort index; zero indicates no index observation.",
    source_reference = paste(report_ref, "Table 21.6"))
}))
inputs <- rbind(catch_rows, catch_weight_rows, stock_weight_rows, maturity_rows, m_rows,
  index_rows, index_numerator_rows, effort_rows)

n_long$age <- ages[rep(seq_along(ages), times = length(years))]
f_long$age <- ages[rep(seq_along(ages), times = length(years))]
outputs <- rbind(
  output_rows("population", "numbers_at_age", n_long$year, n_long$age, "",
    n_long$value, "thousand fish", notes = "Start-of-year stock numbers; age 12 is the 12+ group.",
    source_reference = paste(report_ref, "Table 21.8")),
  output_rows("mortality", "fishing_mortality_at_age", f_long$year, f_long$age, "",
    f_long$value, "per year", notes = "Estimated fishing mortality; age 12 is the 12+ group.",
    source_reference = paste(report_ref, "Table 21.9")),
  output_rows("population", "total_numbers", n_wide$year, NA_integer_, "2-12+",
    n_wide$v12, "thousand fish", source_type = "official_table",
    notes = "Reported total stock numbers from Table 21.8; rounded age-specific values may not sum exactly to the reported total.",
    source_reference = paste(report_ref, "Table 21.8")),
  output_rows("recruitment", "recruitment", sag$year, 2L, "",
    sag$recruitment, "thousand fish", source_type = "official_machine_readable",
    notes = "Recruitment is age 2. The 2026 value is the short-term forecast; earlier values are historical estimates.",
    source_reference = sag_ref),
  output_rows("biomass", "total_biomass", sag$year[is.finite(sag$total_biomass)], NA_integer_, "",
    sag$total_biomass[is.finite(sag$total_biomass)], "tonnes", source_type = "official_machine_readable",
    notes = "The 2026 value is the short-term forecast; earlier values are historical estimates.", source_reference = sag_ref),
  output_rows("biomass", "SSB", sag$year, NA_integer_, "",
    sag$SSB, "tonnes", source_type = "official_machine_readable",
    notes = "The 2026 value is the short-term forecast; earlier values are historical estimates.", source_reference = sag_ref),
  output_rows("mortality", "Fbar", sag$year[is.finite(sag$Fbar)], NA_integer_, "3-9",
    sag$Fbar[is.finite(sag$Fbar)], "per year", source_type = "official_machine_readable",
    notes = "Fbar ages 3-9. The 2026 value is a forecast; earlier values are historical estimates.", source_reference = sag_ref)
)

assumption_header <- names(read_table("assumptions.csv"))
assumptions <- as.data.frame(matrix("", nrow = 13L, ncol = length(assumption_header)), stringsAsFactors = FALSE)
names(assumptions) <- assumption_header
assumptions$assessment_id <- assessment_id
assumptions$component <- c(rep("assessment", 8L), rep("index", 4L), "biology")
assumptions$setting <- c("model_family", "model_age_range", "plus_group", "Fbar_ages",
  "assessment_method", "time_taper", "taper_power", "taper_range_years",
  "tuning_age_range", "q_plateau_age", "fleet_timing_window", "index_weighting",
  "natural_mortality")
assumptions$value <- c("XSA", "2-12+", "Age 12 is 12+", "3-9", "Extended Survivors Analysis (FLR-FLXSA)",
  "Tricubic time taper", "3", "15", "3-11", "7",
  "UK-CBT-late and UK-COT: alpha=0, beta=1; Q1SWBeam-nonoffset: alpha=0.1, beta=0.25; FSP-UK: alpha=0.7, beta=0.75",
  "Lognormal abundance indices with fleet-specific observation variance; exact likelihood weights are not fully stated",
  "Fixed at 0.1 per year")
assumptions$source_reference <- c(rep(report_ref, 11L), report_ref, paste(report_ref, "Table 21.11"))
assumptions$fleet[11L] <- "UK-CBT-late; UK-COT; Q1SWBeam-nonoffset; FSP-UK"
assumptions$notes <- c(
  "WGCSE 2026 Chapter 21 reports the production XSA assessment.",
  "Source catch, weight, N and F tables cover ages 2-12+.",
  "The terminal age is a plus group.",
  "Fbar is the arithmetic F average for ages 3-9.",
  "Uses the framework described by IBPWCFlat2 2015; the exact Stock Annex file was not recovered.",
  "The official XSA downweights older tuning observations.",
  "Tricubic power 3.",
  "Index observations older than 15 years are excluded/downweighted by the XSA taper.",
  "The report's 2026 settings table configures all four fleets on ages 3-11; specific year ranges differ by fleet.",
  "XSA catchability is constrained to a plateau from age 7.",
  "Stored alpha/beta timing windows are not exact single sampling times.",
  "The assessment specifies lognormal index fits.",
  "Natural mortality is fixed at 0.1 for all modeled ages and years; not estimated.")

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2026", terminal_year = "2025", estimate_terminal_year = "2026",
  assessment_type = "annual_assessment", model_family = "XSA", model_version = "FLR-FLXSA; WGCSE 2026",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "2015",
  assessment_url = report_ref, framework_url = "", data_url = "", model_url = "",
  repository_url = repository_ref, assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste("Official age-structured XSA assessment fitted through 2025; aggregate 2026 values are forecasts. The detailed chapter supplies catch, index, biology, N-at-age and F-at-age tables; SAG supplies machine-readable aggregate outputs. The TAF data repository is private and no native fitted object was recovered. Source scales and some likelihood details remain undocumented; see the source review."),
  stringsAsFactors = FALSE
)

stock_rows$authority_stock_id[[stock_index]] <- "sol.27.7e"
stock_rows$common_name[[stock_index]] <- "Western English Channel common sole"
stock_rows$notes[[stock_index]] <- paste(stock_rows$notes[[stock_index]],
  "Official ICES WGCSE 2026 assessment added as ices_sole_western_channel_7e_2026; source stock code sol.27.7e.")
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
