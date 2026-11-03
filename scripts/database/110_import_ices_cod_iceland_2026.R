assessment_id <- "ices_cod_iceland_2026"
stock_id <- "ck_ices_nwwg_morhua_ice5a"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ices_cod_iceland_2026")

if (!requireNamespace("xml2", quietly = TRUE) ||
  !requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install xml2 and jsonlite to import the cached MFRI tables.", call. = FALSE)
}

report_url <- "https://www.hafogvatn.is/static/extras/images/1_cod_2026_1_techreport_en.html"
tables_url <- "https://www.hafogvatn.is/static/extras/images/1_cod_2026_1_tables_en.html"
framework_url <- "https://doi.org/10.17895/ices.pub.18622199"
hcr_url <- "https://www.hafogvatn.is/static/extras/images/technicalreporthcr_cod_2021.pdf"
repo_url <- "https://github.com/Hafro/Muppet_HCR/tree/2a4ed80b6b12050ff7b152e748b96c3f5bc5b961"

required <- file.path(cache, c(
  "MFRI_COD_2026_tables.html", "MFRI_COD_2026_techreport.html",
  "MFRI_2021_Icelandic_cod_HCR_evaluation.pdf", "Muppet_HCR_master.zip",
  "manifest.csv"
))
if (any(!file.exists(required))) stop("Cached Icelandic cod sources are incomplete.", call. = FALSE)
if (assessment_id %in% read.csv(file.path(database, "assessments.csv"),
  colClasses = "character", stringsAsFactors = FALSE)$assessment_id) {
  stop("The assessment already exists; review it before re-importing.", call. = FALSE)
}

html <- xml2::read_html(file.path(cache, "MFRI_COD_2026_tables.html"))
scripts <- xml2::xml_find_all(html, "//script[@type='application/json']")
headings <- xml2::xml_text(xml2::xml_find_all(html, "//h3"))
read_table <- function(title) {
  i <- match(title, headings)
  if (is.na(i)) stop("Missing MFRI table: ", title, call. = FALSE)
  payload <- jsonlite::fromJSON(xml2::xml_text(scripts[[i]]), simplifyVector = TRUE)
  headers <- xml2::xml_text(xml2::xml_find_all(
    xml2::read_html(payload$x$container), "//th"
  ))
  data <- as.data.frame(t(payload$x$data), stringsAsFactors = FALSE)
  if (ncol(data) != length(headers)) stop("Header mismatch for ", title, call. = FALSE)
  names(data) <- headers
  data
}
num <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x), fixed = TRUE)))

catch <- read_table("Catch at age")
catch_weights <- read_table("Catch-weights")
spawning_weights <- read_table("SSB-weights")
stock_weights <- read_table("Stock-weights")
maturity <- read_table("Maturity at age")
spring <- read_table("IS-SMB index")
autumn <- read_table("IS-SMH index")
stock_numbers <- read_table("Stock in numbers")
fishing_mortality <- read_table("Fishing mortality")
summary <- read_table("Assessment summary")

age_columns <- function(x, min_age, max_age) {
  ages <- suppressWarnings(as.integer(names(x)))
  keep <- which(!is.na(ages) & ages >= min_age & ages <= max_age)
  if (!identical(ages[keep], seq.int(min_age, max_age))) {
    stop("Unexpected age columns.", call. = FALSE)
  }
  names(x)[keep]
}
table_rows <- function(x, type, measure, basis, unit, min_age, max_age,
                       fleet = "", survey = "", source_name,
                       note = "", transformation = "Copied from the published MFRI table.") {
  cols <- age_columns(x, min_age, max_age)
  values <- as.matrix(data.frame(lapply(x[cols], num), check.names = FALSE))
  grid <- expand.grid(
    year = num(x$Year), age = as.integer(cols),
    KEEP.OUT.ATTRS = FALSE
  )
  grid$value <- as.vector(values)
  grid <- grid[is.finite(grid$value), , drop = FALSE]
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = "", season = "",
    year = as.integer(grid$year), year_basis = "calendar_year", age = grid$age,
    value = grid$value, unit = unit, sampling_time = NA_real_,
    source_type = "official_machine_readable",
    source_reference = paste0(tables_url, "; table ", source_name),
    transformation = transformation, notes = note,
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

inputs <- rbind(
  table_rows(catch, "catch", "numbers_at_age", "numbers", "thousand fish", 3, 14,
    fleet = "Aggregated commercial catch", source_name = "Catch at age",
    note = "Official catch-at-age input aggregated across 20 métiers: two areas, two seasons, and five gear classes."),
  table_rows(spring, "index", "numbers_at_age", "index_scale", "native survey index units", 1, 14,
    survey = "IS-SMB", source_name = "IS-SMB index",
    note = "March groundfish survey; timing is not specified in the 2026 production tables. The 2021 MUPPET configuration uses 0.2."),
  table_rows(autumn, "index", "numbers_at_age", "index_scale", "native survey index units", 1, 14,
    survey = "IS-SMH", source_name = "IS-SMH index",
    note = "October groundfish survey; the source model uses ages 3-13. Canonical values outside those ages are retained. The 2021 MUPPET configuration uses 0.8."),
  table_rows(catch_weights, "catch_weight", "weight_at_age", "g_per_fish", "g per fish", 1, 14,
    fleet = "Aggregated commercial catch", source_name = "Catch-weights",
    note = "Official catch weights; 2026 values are short-term projection values and are not fitted catch observations."),
  table_rows(spawning_weights, "weight", "spawning_weight_at_age", "g_per_fish", "g per fish", 1, 14,
    source_name = "SSB-weights", note = "Reported spawning-stock weight-at-age surface; not substituted for the separate stock-weight surface."),
  table_rows(stock_weights, "weight", "weight_at_age", "g_per_fish", "g per fish", 1, 14,
    source_name = "Stock-weights", note = "Reported stock weight-at-age. The 2026 report says pre-1985 values were held at 1985, while the published table shows varying values; table values are preserved pending clarification."),
  table_rows(maturity, "maturity", "maturity_at_age", "proportion", "proportion", 1, 14,
    source_name = "Maturity at age", note = "Reported proportion mature at age. The 2026 report describes pre-1985 values as held at 1985, but the table gives varying historical values; no values are altered."),
  data.frame(
    assessment_id = assessment_id, type = "M", measure = "natural_mortality_at_age",
    basis = "per_year", fleet = "", survey = "", sex = "", region = "", season = "",
    year = NA_integer_, year_basis = "", age = 1:14, value = rep(0.2, 14),
    unit = "per year", sampling_time = NA_real_, source_type = "official_document",
    source_reference = paste0(report_url, "; section on assessment assumptions"),
    transformation = "Copied from the stated fixed natural mortality assumption.",
    notes = "M=0.2 per year at all ages and years; time-invariant source vector.",
    observation_id = "", length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
)

summary_output <- function(measure, type, value, unit, lower = NULL, upper = NULL,
                           age = NA_integer_, age_group = "", source_name,
                           notes = "") {
  value <- num(value)
  keep <- is.finite(value)
  n <- sum(keep)
  lower_value <- if (is.null(lower)) rep(NA_real_, length(value)) else num(lower)
  upper_value <- if (is.null(upper)) rep(NA_real_, length(value)) else num(upper)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "",
    year = as.integer(num(summary$Year)[keep]), age = rep_len(age, n),
    age_group = rep_len(age_group, n), value = value[keep], se = NA_real_,
    lwr = lower_value[keep], upr = upper_value[keep], unit = unit,
    source_type = "official_machine_readable",
    source_reference = paste0(tables_url, "; table Assessment summary; ", source_name),
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}
output_rows <- function(x, type, measure, unit, min_age, max_age, source_name,
                        note = "Reported point estimates; uncertainty is not available in this table.") {
  cols <- age_columns(x, min_age, max_age)
  values <- as.matrix(data.frame(lapply(x[cols], num), check.names = FALSE))
  grid <- expand.grid(year = num(x$Year), age = as.integer(cols), KEEP.OUT.ATTRS = FALSE)
  grid$value <- as.vector(values)
  grid <- grid[is.finite(grid$value), , drop = FALSE]
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = as.integer(grid$year),
    age = grid$age, age_group = "", value = grid$value, se = NA_real_, lwr = NA_real_,
    upr = NA_real_, unit = unit, source_type = "official_machine_readable",
    source_reference = paste0(tables_url, "; table ", source_name), notes = note,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

outputs <- rbind(
  output_rows(stock_numbers, "population", "numbers_at_age", "thousand fish", 1, 14, "Stock in numbers"),
  output_rows(fishing_mortality, "mortality", "fishing_mortality_at_age", "per year", 1, 14, "Fishing mortality"),
  summary_output("SSB", "biomass", summary$SSB, "tonnes", summary$`Low SSB`, summary$`High SSB`,
    source_name = "SSB (tonnes)", notes = "The 2026 report narrative gives 371,000 t, while the machine-readable table gives 377,277 t; the table value is retained. Reported bounds are preserved without assigning a confidence level."),
  summary_output("reference_biomass", "biomass", summary$`Ref. Biomass`, "tonnes",
    summary$`Low Ref. Biomass`, summary$`High Ref. Biomass`, age_group = "4+",
    source_name = "Reference biomass B4+ (tonnes)", notes = "B4+ is estimated from beginning-of-year abundance at ages 4+ and catch weights. Reported bounds are preserved without assigning a confidence level."),
  summary_output("Fbar", "mortality", summary$F, "per year", age_group = "5-10",
    source_name = "Fbar (ages 5-10)", notes = "Annual mean fishing mortality over ages 5-10; no 2026 Fbar estimate is reported."),
  summary_output("recruitment", "recruitment", summary$Recruitment, "thousand fish",
    summary$`Low Recruitment`, summary$`High Recruitment`, age = 3L,
    source_name = "Recruitment (age 3, thousands)", notes = "Age-3 recruitment. Bounds are preserved without assigning a confidence level."),
  summary_output("harvest_rate", "mortality", summary$HR, "proportion",
    source_name = "Harvest rate", notes = "Reported harvest-rate series; not treated as a tinyAM mortality estimate.")
)

N <- outputs[outputs$type == "population" & outputs$measure == "numbers_at_age", , drop = FALSE]
derive_total_N <- function(min_age, max_age, measure, note) {
  selected <- N[N$age >= min_age & N$age <= max_age, , drop = FALSE]
  totals <- aggregate(value ~ year, selected, sum)
  data.frame(
    assessment_id = assessment_id, type = "population", measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "", year = totals$year,
    age = NA_integer_, age_group = "", value = totals$value, se = NA_real_, lwr = NA_real_,
    upr = NA_real_, unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(tables_url, "; table Stock in numbers"), notes = note,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
derived_N <- rbind(
  derive_total_N(3, 14, "total_numbers", "Derived by summing N-at-age over ages 3-14, matching the tinyAM age grid; uncertainty is unavailable."),
  derive_total_N(1, 14, "total_numbers_all_ages", "Derived by summing N-at-age over all reported ages 1-14; uncertainty is unavailable and this definition differs from the translated age range.")
)
outputs <- rbind(outputs, derived_N)
if (nrow(inputs) != 5895L || nrow(outputs) != 2504L) {
  stop("The MFRI table coverage differs from the reviewed source inventory.", call. = FALSE)
}

assumption <- function(component, setting, value, source_reference, notes = "", survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "", survey = survey,
    sex = "", region = "", season = "", setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "model_family", "MUPPET", report_url, "MFRI reports a separable statistical catch-at-age model; the exact fitted 2026 model object was not recovered."),
  assumption("population", "model_years_and_ages", "1955-2026; ages 1-14", tables_url, "Catch is available through 2025; the March survey and population estimates extend through 2026."),
  assumption("population", "recruitment_age", "3", report_url, "Recruitment is reported at age 3."),
  assumption("F", "temporal_process", "Random walk", report_url, "The report describes gradual annual F change; exact production-run process configuration is not available."),
  assumption("F", "selectivity_periods", "1955-1974; 1975-1993; 1994-2006; 2007 onward", paste0(repo_url, "; TestCases/iCod/Files/catchparameters.dat"), "Four historical selectivity periods are corroborated by the cached MUPPET source snapshot, not the exact 2026 fitted run."),
  assumption("M", "process", "Fixed", report_url, "No direct information on natural mortality; 0.2 per year is assumed for all ages."),
  assumption("M", "natural_mortality", "0.2 per year, all ages", report_url, "Constant across ages and years."),
  assumption("catch", "data_stream", "Aggregated catch-at-age", report_url, "Source catch-at-age combines 20 métiers: two areas, two seasons, and five gear classes."),
  assumption("index", "observation_model", "Log-scale residuals with correlated survey-year errors", report_url, "The report describes estimated residual correlation for survey indices; exact covariance and likelihood weights are unavailable."),
  assumption("index", "timing", "0.2", paste0(repo_url, "; TestCases/iCod/Files/marchsurveypar.dat"), "Historical MUPPET configuration for March survey; current 2026 production timing was not independently confirmed.", survey = "IS-SMB"),
  assumption("index", "timing", "0.8", paste0(repo_url, "; TestCases/iCod/Files/octsurveypar.dat"), "Historical MUPPET configuration for October survey; current 2026 production timing was not independently confirmed.", survey = "IS-SMH"),
  assumption("index", "survey_ages", "IS-SMB: 1-14; IS-SMH: 3-13", report_url, "The official assessment uses March ages 1-14 and October ages 3-13."),
  assumption("biology", "pre_1985_weight_maturity", "unknown", paste0(report_url, "; text and published tables"), "The report says pre-1985 stock weight and maturity were held at 1985 values, but the published machine-readable tables show varying pre-1985 values. Canonical table values are retained pending clarification."),
  assumption("assessment", "native_production_run", "unknown", repo_url, "The public MUPPET repository is an HCR/framework snapshot, not the exact fitted 2026 assessment run.")
))

stock_path <- file.path(database, "stocks.csv")
stock_connection <- file(stock_path, open = "rb")
stock_raw <- readBin(stock_connection, "raw", n = as.integer(file.info(stock_path)$size))
close(stock_connection)
pattern <- charToRaw(paste0("\"", stock_id, "\","))
candidates <- which(stock_raw == pattern[[1L]])
match_start <- candidates[vapply(candidates, function(i) {
  end <- i + length(pattern) - 1L
  end <= length(stock_raw) && identical(stock_raw[i:end], pattern)
}, logical(1))]
if (length(match_start) != 1L) stop("Expected one Charbonneau stock metadata row.", call. = FALSE)
line_feeds <- which(stock_raw == as.raw(10L))
line_start <- max(c(1L, line_feeds[line_feeds < match_start] + 1L))
line_feed <- min(line_feeds[line_feeds >= match_start])
crlf <- stock_raw[[line_feed - 1L]] == as.raw(13L)
suffix_start <- if (crlf) line_feed - 1L else line_feed
prefix <- if (line_start > 1L) stock_raw[seq_len(line_start - 1L)] else raw()
suffix <- stock_raw[suffix_start:length(stock_raw)]
stock_fields <- c(
  stock_id, "ICES-NWWG_morhua_ICE5a", "ICES", "cod.27.5a", "Gadus morhua",
  "Icelandic cod", "ICES Division 5.a (Iceland grounds)",
  "Northeast Atlantic", "Northeast Atlantic",
  paste("Charbonneau-Keith Master metadata reconciled to ICES stock cod.27.5a.",
    "Current detailed assessment represented here is the MFRI 2026 production assessment; see source review for unresolved source discrepancies.")
)
quote_field <- function(x) paste0("\"", gsub("\"", "\"\"", x, fixed = TRUE), "\"")
new_stock_line <- charToRaw(paste(vapply(stock_fields, quote_field, character(1)), collapse = ","))
stock_bytes <- c(prefix, new_stock_line, suffix)
stock_connection <- file(stock_path, open = "wb")
writeBin(stock_bytes, stock_connection)
close(stock_connection)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026,
  terminal_year = 2026, estimate_terminal_year = 2026,
  assessment_type = "annual assessment", model_family = "MUPPET",
  model_version = "2026 production assessment; no fitted run object recovered",
  is_current = TRUE, is_applied = TRUE, framework_year = 2021,
  assessment_url = report_url, framework_url = framework_url, data_url = tables_url,
  model_url = "", repository_url = repo_url,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "MFRI 2026 assessment tables are machine-readable but rounded and are not the native fitted input/output object.",
    "2026 SSB differs between report narrative (371,000 t) and table (377,277 t); the table value is retained.",
    "Report text and historical biology tables disagree on pre-1985 carry-back; preserved table values remain unresolved.",
    "The linked MUPPET HCR repository is historical and does not reproduce the 2026 production run."
  ), stringsAsFactors = FALSE, check.names = FALSE
)
append_csv <- function(x, path) {
  write.table(x, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8")
}
append_csv(assessment, file.path(database, "assessments.csv"))
append_csv(assumptions, file.path(database, "assumptions.csv"))
append_csv(inputs, file.path(database, "inputs.csv"))
append_csv(outputs, file.path(database, "outputs.csv"))

cat("Imported", assessment_id, "with", nrow(inputs), "input rows and", nrow(outputs), "output rows.\n")
