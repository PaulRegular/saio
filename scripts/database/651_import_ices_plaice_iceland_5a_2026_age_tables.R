# The import rewrites UTF-8 CSVs. R can damage existing text when it writes
# those tables in a non-UTF-8 locale.
if (!isTRUE(l10n_info()[["UTF-8"]])) {
  utf8_locale <- if (.Platform$OS.type == "windows") ".UTF-8" else "C.UTF-8"
  suppressWarnings(Sys.setlocale("LC_CTYPE", utf8_locale))
  if (!isTRUE(l10n_info()[["UTF-8"]])) {
    stop("Run the Icelandic plaice importer in a UTF-8 locale.", call. = FALSE)
  }
}

root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_iceland_plaice_2026")
manifest_path <- file.path(root, "provenance", "ices_plaice_iceland_5a_2026", "sources.csv")
assessment_id <- "ices_plaice_iceland_5a_2026"
stock_id <- "ices_plaice_iceland_5a"
candidate_id <- "ICES:ple.27.5a"
tables_url <- "https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_tables_en.html"
report_url <- "https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_techreport_en.html"
dry_run <- identical(Sys.getenv("SAIO_SOURCE_DRY_RUN"), "1")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required to read the official MFRI tables page.", call. = FALSE)
}

source_hash <- function(path) {
  path <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil.exe"))) {
    output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", output, value = TRUE)))
  } else if (nzchar(Sys.which("sha256sum"))) {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE)
    hashes <- tolower(sub("[[:space:]].*$", "", output))
  } else {
    stop("A SHA-256 utility is required to verify the cached MFRI tables page.", call. = FALSE)
  }
  if (length(hashes) != 1L || !grepl("^[[:xdigit:]]{64}$", hashes)) {
    stop("Could not calculate SHA-256 for the MFRI tables page.", call. = FALSE)
  }
  hashes
}

source_file <- "plaice_5a_tables_2026.html"
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
manifest_row <- manifest[manifest$file == source_file, , drop = FALSE]
source_path <- file.path(cache, source_file)
if (nrow(manifest_row) != 1L || !file.exists(source_path) ||
    as.numeric(file.info(source_path)$size) != as.numeric(manifest_row$bytes) ||
    !identical(tolower(source_hash(source_path)), tolower(manifest_row$sha256))) {
  stop("The cached MFRI tables page does not match its provenance record.", call. = FALSE)
}

html <- paste(readLines(source_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
script_matches <- gregexpr("(?is)<script[^>]*application/json[^>]*>.*?</script>",
  html, perl = TRUE)[[1L]]
if (length(script_matches) != 15L || script_matches[1L] < 0L) {
  stop("The MFRI tables page does not contain the reviewed 15 table widgets.", call. = FALSE)
}
scripts <- regmatches(html, list(script_matches))[[1L]]
widgets <- lapply(scripts, function(script) {
  body <- sub("(?is)^.*?>", "", script, perl = TRUE)
  body <- sub("(?is)</script>.*$", "", body, perl = TRUE)
  jsonlite::fromJSON(body, simplifyVector = FALSE)$x
})

strip_html <- function(x) {
  x <- gsub("(?is)<[^>]*>", "", x, perl = TRUE)
  x <- gsub("&nbsp;|&#160;|&#xA0;", " ", x, ignore.case = TRUE)
  trimws(x)
}
widget_table <- function(index) {
  widget <- widgets[[index]]
  header_matches <- regmatches(widget$container,
    gregexpr("(?is)<th\\b[^>]*>.*?</th>", widget$container, perl = TRUE))[[1L]]
  headers <- unname(vapply(header_matches, strip_html, character(1L)))
  columns <- lapply(widget$data, function(column) vapply(column, function(value) {
    if (is.null(value) || !length(value)) NA_character_ else as.character(value)
  }, character(1L)))
  if (!length(headers) || length(headers) != length(columns)) {
    stop("Unexpected MFRI table layout in widget ", index, ".", call. = FALSE)
  }
  lengths <- lengths(columns)
  if (length(unique(lengths)) != 1L) {
    stop("MFRI table columns have unequal lengths in widget ", index, ".", call. = FALSE)
  }
  if (!lengths[1L]) return(as.data.frame(setNames(replicate(length(headers), character(),
    simplify = FALSE), headers), check.names = FALSE, stringsAsFactors = FALSE))
  out <- as.data.frame(setNames(columns, headers), check.names = FALSE,
    stringsAsFactors = FALSE)
  if (!identical(names(out), headers)) stop("Could not preserve MFRI table headers.", call. = FALSE)
  out
}
parse_numeric <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% c("", "-", "NA", "NaN")] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}
age_columns <- as.character(3:12)
age_table <- function(index, years, label) {
  tab <- widget_table(index)
  required <- c("Year", "Species", "Latin Name", age_columns)
  if (!identical(names(tab), required) || nrow(tab) != length(years) ||
      !identical(as.integer(tab$Year), years) ||
      any(tab$Species != "Plaice") || any(tab$`Latin Name` != "Pleuronectes platessa")) {
    stop("Unexpected year, species, age, or column coverage in MFRI ", label, " table.", call. = FALSE)
  }
  tab[age_columns] <- lapply(tab[age_columns], parse_numeric)
  tab
}

catch_age <- age_table(5L, 1980:2025, "catch-at-age")
catch_weight <- age_table(6L, 1980:2025, "catch weight-at-age")
stock_weight <- age_table(8L, 1980:2025, "stock weight-at-age")
maturity <- age_table(9L, 1980:2025, "maturity-at-age")
spring_index <- age_table(10L, 1985:2025, "IS-SMB age index")
stock_numbers <- age_table(14L, 1980:2026, "stock numbers-at-age")
fishing_mortality <- age_table(15L, 1980:2025, "fishing mortality-at-age")

if (nrow(widget_table(7L)) != 0L || nrow(widget_table(11L)) != 0L ||
    nrow(widget_table(12L)) != 0L || nrow(widget_table(13L)) != 0L) {
  stop("The empty SSB-weight and unused survey-index tables differ from the reviewed source.", call. = FALSE)
}
if (any(!is.finite(unlist(catch_age[age_columns]))) ||
    any(!is.finite(unlist(catch_weight[age_columns]))) ||
    any(!is.finite(unlist(stock_weight[age_columns]))) ||
    any(!is.finite(unlist(maturity[age_columns]))) ||
    any(!is.finite(unlist(fishing_mortality[age_columns]))) ||
    any(!is.finite(unlist(stock_numbers[age_columns]))) ||
    any(unlist(maturity[age_columns]) < 0 | unlist(maturity[age_columns]) > 1)) {
  stop("A required MFRI age table contains missing or invalid values.", call. = FALSE)
}
missing_index_cells <- sum(!is.finite(unlist(spring_index[age_columns])))
if (missing_index_cells != 5L || any(unlist(spring_index[age_columns]) < 0, na.rm = TRUE)) {
  stop("The MFRI IS-SMB table's missing-cell count or values differ from the reviewed source.", call. = FALSE)
}

long_table <- function(tab, keep_missing = FALSE) {
  values <- as.vector(t(as.matrix(tab[age_columns])))
  out <- data.frame(year = rep(as.integer(tab$Year), each = length(age_columns)),
    age = rep(3:12, times = nrow(tab)), value = values, stringsAsFactors = FALSE)
  if (!keep_missing) out <- out[is.finite(out$value), , drop = FALSE]
  out
}
input_header <- names(read.csv(file.path(database, "inputs.csv"), nrows = 0L,
  check.names = FALSE, stringsAsFactors = FALSE))
output_header <- names(read.csv(file.path(database, "outputs.csv"), nrows = 0L,
  check.names = FALSE, stringsAsFactors = FALSE))
assessment_header <- names(read.csv(file.path(database, "assessments.csv"), nrows = 0L,
  check.names = FALSE, stringsAsFactors = FALSE))
input_rows <- function(data, type, measure, basis, unit, source_table,
                       fleet = NA_character_, survey = NA_character_,
                       sex = NA_character_, year_basis = "calendar_year",
                       season = NA_character_, sampling_time = NA_character_,
                       notes = "", year_included = TRUE) {
  out <- as.data.frame(matrix(NA_character_, nrow = nrow(data), ncol = length(input_header)),
    stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- fleet
  out$survey <- survey
  out$sex <- sex
  if (year_included) {
    out$year <- as.character(data$year)
    out$year_basis <- year_basis
  }
  out$season <- season
  out$age <- as.character(data$age)
  out$value <- as.character(data$value)
  out$unit <- unit
  out$sampling_time <- sampling_time
  out$source_type <- "official_table"
  out$source_reference <- paste0(tables_url, "; ", source_table)
  out$notes <- notes
  out
}

catch_long <- long_table(catch_age)
catch_weight_long <- long_table(catch_weight)
stock_weight_long <- long_table(stock_weight)
maturity_long <- long_table(maturity)
index_long <- long_table(spring_index)
M_input <- data.frame(year = rep(NA_integer_, 10L), age = 3:12,
  value = rep(0.15, 10L), stringsAsFactors = FALSE)
plus_group_note <- "Age 12 is the plus group. Values are transcribed as published; no age or year values were inferred."
inputs <- rbind(
  input_rows(catch_long, "catch", "numbers_at_age", "numbers", "thousand_fish",
    "Catch at age", fleet = "Commercial fishery",
    notes = paste("Catch-at-age in thousands; the published table provides one catch series without gear separation.", plus_group_note)),
  input_rows(catch_weight_long, "catch_weight", "catch_weight_at_age", "g_per_fish", "g",
    "Catch-weights", fleet = "Commercial fishery",
    notes = paste("Weight at age from commercial catches, in grams per fish.", plus_group_note)),
  input_rows(stock_weight_long, "weight", "weight_at_age", "g_per_fish", "g",
    "Stock-weights", survey = "Icelandic spring groundfish survey (IS-SMB)",
    notes = paste("Spring-survey stock weight at age, in grams per fish. Ages 9+ use a three-year running average and pre-1985 values use the 1985 level.", plus_group_note)),
  input_rows(maturity_long, "maturity", "maturity_at_age", "proportion", "proportion",
    "Maturity at age", survey = "Icelandic spring groundfish survey (IS-SMB)", sex = "female",
    notes = paste("Maturity proportions for mature females from the spring survey; annual values use smoothed maturity-at-length estimates. Pre-1985 values use the 1985 level.", plus_group_note)),
  input_rows(index_long, "index", "numbers_at_age", "index_scale",
    "number (index scale; multiplier not stated)", "IS-SMB index",
    survey = "Icelandic spring groundfish survey (IS-SMB)", season = "March",
    notes = paste("Age-disaggregated spring-survey index reported as numbers. The source does not state the scale multiplier; values are preserved without rescaling. Five age-year cells are blank in the source.", plus_group_note)),
  input_rows(M_input, "M", "natural_mortality_at_age", "per_year", "per_year",
    "2022 Stock Annex and 2026 production report", year_included = FALSE,
    notes = paste("Natural mortality is fixed at 0.15 per year for all modeled ages; it is not an estimated output.", plus_group_note))
)

historical_numbers <- long_table(stock_numbers[as.integer(stock_numbers$Year) <= 2025, , drop = FALSE])
forecast_numbers <- long_table(stock_numbers[as.integer(stock_numbers$Year) == 2026, , drop = FALSE])
fishing_long <- long_table(fishing_mortality)
output_rows <- function(data, type, measure, unit, source_table, notes,
                        scenario = NA_character_) {
  out <- as.data.frame(matrix(NA_character_, nrow = nrow(data), ncol = length(output_header)),
    stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(data$year)
  out$age <- as.character(data$age)
  out$age_group[data$age == 12L] <- "12+"
  out$value <- as.character(data$value)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- paste0(tables_url, "; ", source_table)
  out$notes <- notes
  out$scenario <- scenario
  out
}
output_plus_group <- "Age 12 is the plus group. Age-specific uncertainty is not reported in the table."
outputs <- rbind(
  output_rows(historical_numbers, "population", "numbers_at_age", "thousand_fish",
    "Stock in numbers", paste("Historical estimated stock numbers at age in thousands.", output_plus_group)),
  output_rows(forecast_numbers, "population", "numbers_at_age", "thousand_fish",
    "Stock in numbers", paste("2026 short-term forecast of stock numbers at age in thousands; kept separate from historical fitted years.", output_plus_group),
    scenario = "short_term_forecast"),
  output_rows(fishing_long, "mortality", "fishing_mortality_at_age", "per_year",
    "Fishing mortality", paste("Estimated fishing mortality at age per year.", output_plus_group))
)

read_assessment_rows <- function(path) {
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "bytes")
  matches <- system2("rg", c("--color", "never", "--no-heading", "--no-line-number",
    "-F", assessment_id, path), stdout = TRUE, stderr = FALSE)
  status <- attr(matches, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(read.csv(text = header, nrows = 0L,
    check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character"))
  if (status != 0L) stop("Could not read assessment rows from ", path, ".", call. = FALSE)
  matches <- matches[startsWith(matches, paste0('"', assessment_id, '",'))]
  if (!length(matches)) return(read.csv(text = header, nrows = 0L,
    check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character"))
  read.csv(text = paste(c(header, matches), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character",
    na.strings = c("", "NA"))
}
normalise_blank <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
matching_key <- function(data, columns) {
  if (!nrow(data)) return(character())
  do.call(paste, c(lapply(data[columns], normalise_blank), sep = "\r"))
}
check_append <- function(existing, add, key_fields, file) {
  key <- matching_key(add, key_fields)
  if (anyDuplicated(key)) stop("New rows contain duplicate keys for ", file, ".", call. = FALSE)
  old_key <- matching_key(existing, key_fields)
  match_index <- match(key, old_key)
  if (any(!is.na(match_index))) {
    value_field <- "value"
    same <- normalise_blank(existing[[value_field]][match_index[!is.na(match_index)]]) ==
      normalise_blank(add[[value_field]][!is.na(match_index)])
    if (any(!same)) stop("Conflicting values already exist for ", file, ".", call. = FALSE)
  }
  add[is.na(match_index), , drop = FALSE]
}
input_keys <- setdiff(names(inputs), c("value", "unit", "source_type", "source_reference", "transformation", "notes"))
output_keys <- setdiff(names(outputs), c("value", "se", "lwr", "upr", "unit", "source_type", "source_reference", "notes"))
existing_inputs <- read_assessment_rows(file.path(database, "inputs.csv"))
existing_outputs <- read_assessment_rows(file.path(database, "outputs.csv"))
append_inputs <- check_append(existing_inputs, inputs, input_keys, "inputs.csv")
append_outputs <- check_append(existing_outputs, outputs, output_keys, "outputs.csv")

assessments <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character", na.strings = c("", "NA"))
assessment_rows <- which(assessments$assessment_id == assessment_id & assessments$stock_id == stock_id)
if (length(assessment_rows) != 1L) stop("Expected one existing Icelandic plaice 2026 assessment.", call. = FALSE)
assessment <- assessments[assessment_rows, , drop = FALSE]
if (assessment$terminal_year != "2025" || assessment$assessment_year != "2026") {
  stop("The existing Icelandic plaice assessment identity does not match the reviewed MFRI run.", call. = FALSE)
}
assessment$outputs_status <- "complete"
assessment$notes <- paste(
  "Official 2026 MFRI production assessment uses data through 2025.",
  "Supplementary MFRI numerical tables provide catch-at-age, catch weights, stock weights, maturity, spring IS-SMB indices, historical N-at-age and F-at-age.",
  "Inputs remain partial because catch-at-age starts in 1980 in the published table although the report describes use from 1979, the SSB-weight table is empty, and the IS-SMB index scale multiplier is not stated.",
  "The five blank IS-SMB age-year cells remain missing. The 2026 stock-number values are stored separately as a short-term forecast.",
  "ICES Standard Graphs provides aggregate historical outputs with reported 90% confidence bounds for recruitment, SSB and Fbar; age-specific N/F uncertainty is not reported."
)

assumptions <- read.csv(file.path(database, "assumptions.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character", na.strings = c("", "NA"))
assessment_assumptions <- which(assumptions$assessment_id == assessment_id)
update_assumption <- function(setting, value = NULL, notes = NULL, new_setting = NULL) {
  rows <- assessment_assumptions[assumptions$setting[assessment_assumptions] == setting]
  if (!length(rows) && !is.null(new_setting)) {
    rows <- assessment_assumptions[assumptions$setting[assessment_assumptions] == new_setting]
  }
  if (length(rows) != 1L) stop("Expected one existing assumption row for ", setting, ".", call. = FALSE)
  if (!is.null(value)) assumptions$value[rows] <<- value
  if (!is.null(notes)) assumptions$notes[rows] <<- notes
  if (!is.null(new_setting)) assumptions$setting[rows] <<- new_setting
  assumptions$source_reference[rows] <<- paste0(tables_url, "; MFRI 2026 production report")
}
update_assumption("survey", notes = paste(
  "The model uses the age-disaggregated IS-SMB series tabulated for 1985-2025.",
  "The published table has five blank age-year cells; these remain missing."))
update_assumption("stock_weights_at_age", notes = paste(
  "Numerical annual values are recovered from the MFRI Stock-weights table for 1980-2025.",
  "Ages 9+ are smoothed with a three-year running average and pre-1985 values use 1985."))
update_assumption("maturity_at_age", notes = paste(
  "Numerical annual female maturity-at-age values are recovered from the MFRI table for 1980-2025.",
  "The report describes estimates from annual maturity-at-length ogives, smoothed with a three-year running average; pre-1985 values use 1985."))
update_assumption("unavailable_age_specific_inputs",
  value = "1979 catch-at-age; spawning-stock weights-at-age",
  notes = paste("The report describes catch-at-age from 1979, but the published catch table starts in 1980.",
    "The separate SSB-weight table is empty. The IS-SMB index values are available, but the scale multiplier is not stated."))
update_assumption("unavailable_age_specific_outputs",
  value = "Age-specific N-at-age and F-at-age uncertainty",
  notes = "Historical point estimates for N-at-age and F-at-age are recovered from MFRI tables. Their age-specific uncertainty is not reported.",
  new_setting = "unavailable_age_specific_output_uncertainty")
if (!any(assumptions$assessment_id == assessment_id & assumptions$setting == "survey_index_scale")) {
  new_assumption <- as.data.frame(matrix(NA_character_, nrow = 1L, ncol = ncol(assumptions)),
    stringsAsFactors = FALSE)
  names(new_assumption) <- names(assumptions)
  new_assumption$assessment_id <- assessment_id
  new_assumption$component <- "index"
  new_assumption$setting <- "survey_index_scale"
  new_assumption$value <- "Scale multiplier not stated"
  new_assumption$source_reference <- paste0(tables_url, "; IS-SMB index")
  new_assumption$notes <- "Values are retained in the published number-index scale with no conversion or rescaling."
  assumptions <- rbind(assumptions, new_assumption)
}

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_34_2026.csv")
register <- read.csv(candidate_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L || register$matched_stock_id[candidate_row] != stock_id ||
    register$eligibility[candidate_row] != "eligible") {
  stop("The candidate register does not uniquely match the Icelandic plaice assessment.", call. = FALSE)
}
register$import_status[candidate_row] <- "partial"
register$review_date[candidate_row] <- "2026-11-14"
register$catch_age_evidence[candidate_row] <- paste(
  "MFRI supplementary Catch at age table provides numerical catches in thousands for ages 3-12 (age 12+), 1980-2025.",
  "The report describes model catch-at-age from 1979, which is absent from the table.")
register$survey_age_evidence[candidate_row] <- paste(
  "MFRI supplementary IS-SMB table provides age-disaggregated indices for ages 3-12 in 1985-2025.",
  "Five cells are blank and the scale multiplier is not stated; no rescaling was applied.")
register$weights_evidence[candidate_row] <- paste(
  "Numerical catch weights and spring-survey stock weights at ages 3-12 are available for 1980-2025, in grams per fish.",
  "The separate spawning-stock weight table is empty.")
register$maturity_evidence[candidate_row] <- paste(
  "Female maturity proportions at ages 3-12 are available for 1980-2025.",
  "The report describes maturity-at-length estimation and three-year smoothing.")
register$output_evidence[candidate_row] <- paste(
  "MFRI tables provide historical N-at-age and F-at-age for 1980-2025, with 2026 N-at-age forecast values.",
  "Age-specific uncertainty is not published; ICES SAG aggregate outputs and 90% intervals remain imported.")
register$notes[candidate_row] <- paste(
  "Partial source import includes the MFRI supplementary age tables and ICES SAG aggregate outputs.",
  "Inputs remain partial because 1979 catch-at-age is not tabulated, the spawning-stock weight table is empty, and the survey index multiplier is unstated.",
  "See discovery/source_reviews/ices_plaice_iceland_2026.md.")

inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
inventory$import_status[inventory_row] <- "partial"
selected <- read.csv(selected_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("The Icelandic plaice selected-batch row is missing.", call. = FALSE)
selected$curation_status[selected_row] <- "partial_source_import"
selected$selection_basis[selected_row] <- paste(
  "Imported the official MFRI supplementary age tables and ICES SAG outputs.",
  "Inputs remain partial due to missing 1979 catch-at-age, an empty SSB-weight table, and an unstated survey index multiplier.")

append_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  con <- file(path, open = "rb")
  seek(con, where = -1L, origin = "end")
  last <- readBin(con, "raw", n = 1L)
  close(con)
  if (!identical(last, as.raw(10L))) cat("\n", file = path, append = TRUE)
  write.table(rows, file = path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", append = TRUE, qmethod = "double", eol = "\n")
}
write_csv <- function(data, path) write.csv(data, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")

if (dry_run) {
  cat("Validated MFRI Icelandic plaice age-table import:", nrow(append_inputs), "new input rows and",
    nrow(append_outputs), "new output rows;", missing_index_cells, "IS-SMB cells remain missing.\n")
} else {
  append_rows(file.path(database, "inputs.csv"), append_inputs)
  append_rows(file.path(database, "outputs.csv"), append_outputs)
  assessments[assessment_rows, ] <- assessment
  write_csv(assessments, file.path(database, "assessments.csv"))
  write_csv(assumptions, file.path(database, "assumptions.csv"))
  replace_candidate_register_row(candidate_path, candidate_row,
    register[candidate_row, , drop = FALSE], candidate_id)
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
  replace_csv_register_row(selected_path, selected_row,
    selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)
  cat("Imported MFRI Icelandic plaice age tables and updated the 2026 source record.\n")
}
