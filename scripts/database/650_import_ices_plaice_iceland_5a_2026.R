root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_iceland_plaice_2026")
manifest_path <- file.path(root, "provenance", "ices_plaice_iceland_5a_2026", "sources.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_34_2026.csv")

assessment_id <- "ices_plaice_iceland_5a_2026"
stock_id <- "ices_plaice_iceland_5a"
candidate_id <- "ICES:ple.27.5a"
report_url <- "https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_techreport_en.html"
advice_url <- "https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_advice_en.html"
sag_url <- "https://standardgraphs.ices.dk/ViewCharts.aspx?key=22531"
sag_source_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22531"
annex_url <- "https://doi.org/10.17895/ices.pub.20132660.v1"
framework_url <- "https://doi.org/10.17895/ices.pub.19663971"
dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")

source_hash <- function(path) {
  path <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil.exe"))) {
    output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", output, value = TRUE)))
  } else if (nzchar(Sys.which("sha256sum"))) {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE)
    hashes <- tolower(sub("[[:space:]].*$", "", output))
  } else {
    stop("A SHA-256 utility is required to verify the cached source files.", call. = FALSE)
  }
  if (length(hashes) != 1L || !grepl("^[[:xdigit:]]{64}$", hashes)) {
    stop("Could not calculate SHA-256 for ", basename(path), call. = FALSE)
  }
  hashes
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
source_files <- c(
  "plaice_5a_techreport_2026.html",
  "plaice_5a_advice_2026.html",
  "ices_stock_graphs_22531_2026.html",
  "ices_source_data_22531_2026.html",
  "plaice_5a_stock_annex_2022.pdf",
  "wkicemp_2022_framework.pdf"
)
if (!all(source_files %in% manifest$file)) {
  stop("The provenance manifest is missing a source used by this import.", call. = FALSE)
}
manifest <- manifest[match(source_files, manifest$file), , drop = FALSE]
source_paths <- file.path(cache, source_files)
if (any(!file.exists(source_paths)) ||
    any(file.info(source_paths)$size != manifest$bytes)) {
  stop("Cached Icelandic plaice sources do not match the provenance sizes.", call. = FALSE)
}
actual_hashes <- vapply(source_paths, source_hash, character(1L))
if (!identical(tolower(manifest$sha256), unname(actual_hashes))) {
  stop("Cached Icelandic plaice sources do not match the provenance checksums.", call. = FALSE)
}

html_text <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
strip_html <- function(x) {
  x <- gsub("(?is)<[^>]*>", "", x, perl = TRUE)
  x <- gsub("&nbsp;|&#160;|&#xA0;", " ", x, ignore.case = TRUE)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  trimws(x)
}
table_rows <- function(table) {
  matches <- regmatches(table, gregexpr("(?is)<tr\\b[^>]*>.*?</tr>", table, perl = TRUE))[[1L]]
  if (length(matches) == 1L && matches[1L] == "") character() else matches
}
row_cells <- function(row) {
  matches <- regmatches(row, gregexpr("(?is)<t[hd]\\b[^>]*>.*?</t[hd]>", row, perl = TRUE))[[1L]]
  if (length(matches) == 1L && matches[1L] == "") return(character())
  vapply(matches, strip_html, character(1L))
}
extract_table <- function(html, id) {
  pattern <- paste0("(?is)<table\\b[^>]*id=\"", id, "\"[^>]*>.*?</table>")
  match <- regexpr(pattern, html, perl = TRUE)
  if (match[1L] < 0L) stop("Could not locate table ", id, ".", call. = FALSE)
  regmatches(html, match)
}
parse_number <- function(x) {
  x <- gsub("[^0-9.-]", "", x)
  suppressWarnings(as.numeric(x))
}

graph_html <- html_text(file.path(cache, "ices_source_data_22531_2026.html"))
graph_table <- extract_table(graph_html, "gvFishData")
graph_rows <- table_rows(graph_table)
graph_cells <- lapply(graph_rows, row_cells)
header_index <- which(vapply(graph_cells, function(x) "Year" %in% x, logical(1L)))[1L]
if (is.na(header_index)) stop("The ICES source table has no year header.", call. = FALSE)
headers <- graph_cells[[header_index]]
records <- graph_cells[(header_index + 1L):length(graph_cells)]
records <- records[vapply(records, length, integer(1L)) == length(headers)]
annual <- as.data.frame(do.call(rbind, records), stringsAsFactors = FALSE)
names(annual) <- headers
annual[] <- lapply(annual, parse_number)
annual$Year <- as.integer(annual$Year)
if (!identical(sort(annual$Year), 1980:2026) || anyDuplicated(annual$Year)) {
  stop("Unexpected year coverage in ICES source data key 22531.", call. = FALSE)
}
historical <- annual[annual$Year <= 2025, , drop = FALSE]
if (nrow(historical) != 46L || any(!is.finite(historical$Recruitment)) ||
    any(!is.finite(historical$SSB)) || any(!is.finite(historical$F)) ||
    any(!is.finite(historical$`Low Recruitment`)) ||
    any(!is.finite(historical$`High Recruitment`)) ||
    any(!is.finite(historical$`Low SSB`)) ||
    any(!is.finite(historical$`High SSB`)) ||
    any(!is.finite(historical$`Low F`)) || any(!is.finite(historical$`High F`))) {
  stop("Missing historical point estimates or reported bounds in ICES source data.", call. = FALSE)
}
if (historical$Recruitment[historical$Year == 1980] != 26307 ||
    historical$SSB[historical$Year == 1980] != 9659 ||
    historical$F[historical$Year == 1980] != 0.338 ||
    historical$Recruitment[historical$Year == 2025] != 15626 ||
    historical$SSB[historical$Year == 2025] != 21537 ||
    historical$F[historical$Year == 2025] != 0.234) {
  stop("ICES source values do not match the 2026 MFRI assessment table.", call. = FALSE)
}

report_lines <- readLines(file.path(cache, "plaice_5a_techreport_2026.html"),
  warn = FALSE, encoding = "UTF-8")
interval_caption <- grep("Figure.{0,3}28: Plaice in 5a", report_lines, value = TRUE, perl = TRUE)
if (length(interval_caption) != 1L ||
    !grepl("90% confidence intervals", interval_caption, fixed = TRUE)) {
  stop("The MFRI report does not verify the reported 90% intervals.", call. = FALSE)
}
report_html <- paste(report_lines, collapse = "\n")
catch_anchor <- regexpr("id=\"tbl-numboatstab\"", report_html, fixed = TRUE)[1L]
if (catch_anchor < 0L) stop("Could not locate MFRI Table 2.", call. = FALSE)
report_tail <- substring(report_html, catch_anchor)
catch_match <- regexpr("(?is)<table\\b[^>]*>.*?</table>", report_tail, perl = TRUE)
if (catch_match[1L] < 0L) stop("Could not parse MFRI Table 2.", call. = FALSE)
catch_table <- regmatches(report_tail, catch_match)
catch_rows <- table_rows(catch_table)
catch_cells <- lapply(catch_rows, row_cells)
catch_header_index <- which(vapply(catch_cells, function(x) "Year" %in% x, logical(1L)))[1L]
if (is.na(catch_header_index)) stop("MFRI Table 2 has no year header.", call. = FALSE)
catch_headers <- catch_cells[[catch_header_index]]
required_catch_headers <- c("Year", "Demersal seine", "Bottom trawl", "Other", "Total catch")
if (!all(required_catch_headers %in% catch_headers)) {
  stop("MFRI Table 2 gear headings differ from the reviewed source.", call. = FALSE)
}
catch_records <- catch_cells[(catch_header_index + 1L):length(catch_cells)]
catch_records <- catch_records[vapply(catch_records, length, integer(1L)) == length(catch_headers)]
catch_data <- as.data.frame(do.call(rbind, catch_records), stringsAsFactors = FALSE)
names(catch_data) <- catch_headers
catch_data[] <- lapply(catch_data, parse_number)
catch_data$Year <- as.integer(catch_data$Year)
catch_data <- catch_data[catch_data$Year %in% 2000:2025, , drop = FALSE]
if (!identical(sort(catch_data$Year), 2000:2025) || anyDuplicated(catch_data$Year) ||
    any(!is.finite(catch_data$`Total catch`)) ||
    any(rowSums(catch_data[, c("Demersal seine", "Bottom trawl", "Other")]) != catch_data$`Total catch`)) {
  stop("MFRI Table 2 catch coverage or gear totals do not reconcile.", call. = FALSE)
}
if (catch_data$`Total catch`[catch_data$Year == 2000] != 5259 ||
    catch_data$`Total catch`[catch_data$Year == 2025] != 6737) {
  stop("MFRI Table 2 values differ from the reviewed report endpoints.", call. = FALSE)
}

prognosis_start <- regexpr("id=\"tbl-progntab\"", report_html, fixed = TRUE)[1L]
if (prognosis_start < 0L) stop("Could not locate MFRI Table 5.", call. = FALSE)
prognosis_tail <- substring(report_html, prognosis_start)
prognosis_match <- regexpr("(?is)<table\\b[^>]*>.*?</table>", prognosis_tail, perl = TRUE)
if (prognosis_match[1L] < 0L) stop("Could not parse MFRI Table 5.", call. = FALSE)
prognosis_table <- regmatches(prognosis_tail, prognosis_match)
prognosis_rows <- table_rows(prognosis_table)
prognosis_cells <- lapply(prognosis_rows, row_cells)
prognosis_header_index <- which(vapply(prognosis_cells, function(x) "Year" %in% x, logical(1L)))[1L]
if (is.na(prognosis_header_index)) stop("MFRI Table 5 has no year header.", call. = FALSE)
prognosis_headers <- prognosis_cells[[prognosis_header_index]]
required_prognosis_headers <- c("Year", "F(5-10)", "Recruitment", "SSB", "Catch")
if (!all(required_prognosis_headers %in% prognosis_headers)) {
  stop("MFRI Table 5 headings differ from the reviewed source.", call. = FALSE)
}
prognosis_records <- prognosis_cells[(prognosis_header_index + 1L):length(prognosis_cells)]
prognosis_records <- prognosis_records[
  vapply(prognosis_records, length, integer(1L)) == length(prognosis_headers)
]
prognosis <- as.data.frame(do.call(rbind, prognosis_records), stringsAsFactors = FALSE)
names(prognosis) <- prognosis_headers
prognosis[] <- lapply(prognosis, parse_number)
prognosis$Year <- as.integer(prognosis$Year)
prognosis <- prognosis[prognosis$Year %in% 2026:2028, , drop = FALSE]
if (!identical(sort(prognosis$Year), 2026:2028) || anyDuplicated(prognosis$Year) ||
    !identical(as.numeric(prognosis$`F(5-10)`), c(0.261, 0.3, 0.3)) ||
    !identical(as.numeric(prognosis$Recruitment), c(16589, 16856, 16856)) ||
    !identical(as.numeric(prognosis$SSB), c(21478, 20566, 19535)) ||
    !identical(as.numeric(prognosis$Catch), c(7002, 7933, 7508))) {
  stop("MFRI Table 5 forecast coverage or values differ from the reviewed report.", call. = FALSE)
}

read_table_header <- function(file) {
  path <- file.path(database, file)
  names(read.csv(text = readLines(path, n = 1L, warn = FALSE), nrows = 0L,
    check.names = FALSE, stringsAsFactors = FALSE))
}
stock_header <- read_table_header("stocks.csv")
assessment_header <- read_table_header("assessments.csv")
input_header <- read_table_header("inputs.csv")
output_header <- read_table_header("outputs.csv")
assumption_header <- read_table_header("assumptions.csv")

stocks_table <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments_table <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock_matches <- which(stocks_table$stock_id == stock_id)
assessment_matches <- which(assessments_table$assessment_id == assessment_id)
if (!dry_run && (length(stock_matches) || length(assessment_matches))) {
  stop("Canonical Icelandic plaice records already exist.", call. = FALSE)
}
if (length(stock_matches) > 1L || length(assessment_matches) > 1L ||
    (length(stock_matches) == 1L && stocks_table$authority_stock_id[stock_matches] != "ple.27.5a") ||
    (length(assessment_matches) == 1L && assessments_table$stock_id[assessment_matches] != stock_id)) {
  stop("Existing Icelandic plaice records conflict with the current stock unit.", call. = FALSE)
}

stock <- as.data.frame(matrix(NA_character_, nrow = 1L, ncol = length(stock_header)),
  stringsAsFactors = FALSE)
names(stock) <- stock_header
stock$stock_id <- stock_id
stock$authority <- "ICES"
stock$authority_stock_id <- "ple.27.5a"
stock$scientific_name <- "Pleuronectes platessa"
stock$common_name <- "Icelandic plaice"
stock$area <- "ICES Division 5.a (Iceland grounds)"
stock$region <- "Icelandic Waters"
stock$ocean <- "Northeast Atlantic"
stock$notes <- paste(
  "New current Icelandic plaice stock unit, distinct from the existing North Sea and Baltic plaice records.",
  "No verified Charbonneau-Keith catalogue match."
)

assessment <- as.data.frame(matrix(NA_character_, nrow = 1L, ncol = length(assessment_header)),
  stringsAsFactors = FALSE)
names(assessment) <- assessment_header
assessment$assessment_id <- assessment_id
assessment$stock_id <- stock_id
assessment$assessment_year <- "2026"
assessment$terminal_year <- "2025"
assessment$estimate_terminal_year <- "2028"
assessment$assessment_type <- "annual_assessment"
assessment$model_family <- "SAM"
assessment$model_version <- NA_character_
assessment$is_current <- "TRUE"
assessment$is_applied <- "TRUE"
assessment$framework_year <- "2022"
assessment$assessment_url <- report_url
assessment$framework_url <- framework_url
assessment$data_url <- sag_source_url
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "The official 2026 MFRI production report uses data through 2025.",
  "Recovered inputs are aggregate landed catch by gear for 2000-2025; full catch-at-age, age-specific spring-survey indices, weights-at-age and maturity-at-age are shown graphically and remain unextracted.",
  "ICES source data provide historical recruitment, SSB, total biomass and Fbar through 2025; recruitment, SSB and Fbar bounds are 90% intervals.",
  "MFRI Table 5 short-term forecast values for 2026-2028 are stored with a separate forecast scenario and no uncertainty bounds."
)

input_rows <- function(fleet, years, values, measure = "landings_biomass") {
  n <- length(values)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(input_header)),
    stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- "catch"
  out$measure <- measure
  out$basis <- "biomass"
  out$fleet <- fleet
  out$year <- as.character(years)
  out$year_basis <- "calendar_year"
  out$value <- as.character(values)
  out$unit <- "tonnes"
  out$source_type <- "official_table"
  out$source_reference <- paste0(report_url, "#tbl-numboatstab; MFRI 2026 Table 2")
  out$transformation <- "Transcribed landed catch by gear in tonnes; no conversion applied."
  out$notes <- paste(
    "Aggregate landings are reported for Icelandic fleets.",
    "These values are not the age-specific catch numbers used in the SAM likelihood and do not replace the unavailable catch-at-age matrix."
  )
  out
}
inputs <- rbind(
  input_rows("Demersal seine", catch_data$Year, catch_data$`Demersal seine`),
  input_rows("Bottom trawl", catch_data$Year, catch_data$`Bottom trawl`),
  input_rows("Other gears", catch_data$Year, catch_data$Other)
)

output_rows <- function(type, measure, value, year, unit, age = NA_integer_,
                        age_group = NA_character_, lwr = NA_real_, upr = NA_real_,
                        notes = "", scenario = NA_character_) {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(output_header)),
    stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(year)
  out$age <- as.character(rep_len(age, n))
  out$age_group <- as.character(rep_len(age_group, n))
  out$value <- as.character(value)
  out$lwr <- as.character(rep_len(lwr, n))
  out$upr <- as.character(rep_len(upr, n))
  out$unit <- unit
  out$source_type <- "official_machine_readable"
  out$source_reference <- paste0(sag_source_url, "; MFRI 2026 Table 7 and Figure 28")
  out$notes <- notes
  out$scenario <- rep_len(scenario, n)
  out
}
interval_note <- paste(
  "ICES Standard Graphs assessment key 22531; the MFRI report identifies these low/high bounds as 90% confidence intervals.",
  "Bounds are retained on their reported scale; no standard errors are derived."
)
outputs <- rbind(
  output_rows("recruitment", "recruitment", historical$Recruitment, historical$Year,
    "thousand fish", age = 3L, lwr = historical$`Low Recruitment`,
    upr = historical$`High Recruitment`, notes = interval_note),
  output_rows("biomass", "SSB", historical$SSB, historical$Year, "tonnes",
    lwr = historical$`Low SSB`, upr = historical$`High SSB`, notes = interval_note),
  output_rows("biomass", "total_biomass", historical$TBiomass, historical$Year,
    "tonnes", notes = "Point estimates copied from ICES Standard Graphs; total-biomass uncertainty is not included."),
  output_rows("mortality", "Fbar", historical$F, historical$Year, "per year",
    age_group = "5-10", lwr = historical$`Low F`, upr = historical$`High F`,
    notes = paste(interval_note, "F is the weighted mean for ages 5-10.")),
  output_rows("recruitment", "recruitment", prognosis$Recruitment, prognosis$Year,
    "thousand fish", age = 3L,
    notes = "MFRI Table 5 short-term forecast; no uncertainty interval is reported.",
    scenario = "short_term_forecast"),
  output_rows("biomass", "SSB", prognosis$SSB, prognosis$Year, "tonnes",
    notes = "MFRI Table 5 short-term forecast; no uncertainty interval is reported.",
    scenario = "short_term_forecast"),
  output_rows("mortality", "Fbar", prognosis$`F(5-10)`, prognosis$Year, "per year",
    age_group = "5-10",
    notes = "MFRI Table 5 short-term forecast; no uncertainty interval is reported.",
    scenario = "short_term_forecast"),
  output_rows("catch", "expected_catch_biomass", prognosis$Catch, prognosis$Year, "tonnes",
    notes = "MFRI Table 5 short-term forecast; no uncertainty interval is reported.",
    scenario = "short_term_forecast")
)

assumption_rows <- function(component, setting, value, source_reference, notes = "") {
  out <- as.data.frame(matrix(NA_character_, nrow = 1L, ncol = length(assumption_header)),
    stringsAsFactors = FALSE)
  names(out) <- assumption_header
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}
assumptions <- do.call(rbind, list(
  assumption_rows("assessment", "assessment_model", "SAM", report_url,
    "The public report describes the 2026 production assessment; no run-matched fitted object or package version was recovered."),
  assumption_rows("population", "model_years", "1979-2025", paste0(report_url, "; assessment data section")),
  assumption_rows("population", "model_ages", "3-12+", paste0(report_url, "; assessment data section"),
    "Age 12 is the plus group."),
  assumption_rows("recruitment", "recruitment_age", "3", paste0(report_url, "; Table 7")),
  assumption_rows("M", "natural_mortality", "0.15 per year", annex_url,
    "Fixed for all ages; not estimated."),
  assumption_rows("index", "survey", "Icelandic spring groundfish survey (IS-SMB)", report_url,
    "The fitted age-specific survey index starts in 1985; numerical year-age values are not reported in a table or model archive."),
  assumption_rows("index", "sampling_time", "unknown", paste0(report_url, "; survey methods"),
    "The survey is conducted in March. An exact within-year model fraction was not recovered."),
  assumption_rows("biology", "stock_weights_at_age", "Spring-survey weights-at-age", report_url,
    "Ages 9+ are smoothed using a three-year running average; pre-1985 values use 1985. Numerical annual values are only shown graphically and are not imported."),
  assumption_rows("biology", "maturity_at_age", "Annual female maturity-at-age", report_url,
    "Derived from annual maturity-at-length ogives and length distributions, smoothed with a three-year running average; pre-1985 values use 1985. Numerical values are only shown graphically and are not imported."),
  assumption_rows("outputs", "interval_definition", "90% confidence intervals", paste0(report_url, "; Figure 28"),
    "Applies to recruitment, SSB and F. The report's figure caption defines the displayed ribbon as a 90% confidence interval."),
  assumption_rows("inputs", "unavailable_age_specific_inputs", "Catch-at-age; age-specific IS-SMB indices; stock weights-at-age; maturity-at-age", report_url,
    "The report describes these inputs but provides them graphically rather than as numerical matrices. No values were digitized or inferred."),
  assumption_rows("outputs", "unavailable_age_specific_outputs", "N-at-age; F-at-age", sag_url,
    "The public report and ICES source data provide aggregate outputs, not fitted age-specific surfaces.")
))

candidate_register_io <- file.path(root, "scripts", "database", "candidate_register_io.R")
source(candidate_register_io)
register <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    register$candidate_unit_id[candidate_row] != stock_id ||
    register$official_stock_id[candidate_row] != "ple.27.5a" ||
    register$eligibility[candidate_row] != "eligible" ||
    !register$import_status[candidate_row] %in% c("not_started", "partial")) {
  stop("The Icelandic plaice candidate does not uniquely match the selected import.", call. = FALSE)
}
register$matched_stock_id[candidate_row] <- stock_id
register$match_status[candidate_row] <- "matched"
register$import_status[candidate_row] <- "partial"
register$review_date[candidate_row] <- "2026-11-12"
register$notes[candidate_row] <- paste(
  "Partial source import completed from the current 2026 MFRI report and ICES SAG key 22531.",
  "Aggregate landings by gear and aggregate historical outputs are imported; age-specific input matrices remain unavailable as numerical data.",
  "See discovery/source_reviews/ices_plaice_iceland_2026.md."
)

inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
inventory_original_unit_key <- inventory$unit_key[inventory_row]
inventory$matched_stock_id[inventory_row] <- stock_id
inventory$match_status[inventory_row] <- "matched"
inventory$import_status[inventory_row] <- "partial"

selected <- read.csv(selected_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L ||
    !selected$curation_status[selected_row] %in% c(
      "selected_for_source_curation", "partial_source_import"
    )) {
  stop("The Icelandic plaice selection record is missing or already imported.", call. = FALSE)
}
selected$curation_status[selected_row] <- "partial_source_import"
selected$selection_basis[selected_row] <- paste(
  "Imported aggregate landings by gear and aggregate outputs from current official sources.",
  "Age-specific catch, survey indices, weights and maturity remain available only as figures and are not numerically imported."
)

append_rows <- function(file, rows) {
  path <- file.path(database, file)
  header <- read.csv(text = readLines(path, n = 1L, warn = FALSE), nrows = 0L,
    check.names = FALSE, stringsAsFactors = FALSE)
  if (!identical(names(header), names(rows))) {
    stop("Unexpected columns in ", file, call. = FALSE)
  }
  con <- file(path, open = "rb")
  seek(con, where = -1L, origin = "end")
  last <- readBin(con, "raw", n = 1L)
  close(con)
  if (!identical(last, as.raw(10L))) cat("\n", file = path, append = TRUE)
  write.table(rows, file = path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", append = TRUE, qmethod = "double", eol = "\n")
}

if (dry_run) {
  cat("Validated partial ICES Icelandic plaice import:", nrow(inputs), "input rows,",
    nrow(assumptions), "assumptions, and", nrow(outputs), "output rows.\n")
} else {
  append_rows("stocks.csv", stock)
  append_rows("assessments.csv", assessment)
  append_rows("inputs.csv", inputs)
  append_rows("assumptions.csv", assumptions)
  append_rows("outputs.csv", outputs)
  replace_candidate_register_row(candidate_path, candidate_row,
    register[candidate_row, , drop = FALSE], candidate_id)
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory_original_unit_key)
  replace_csv_register_row(selected_path, selected_row,
    selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)
  cat("Imported partial ICES plaice in Division 5.a (Iceland grounds).\n")
}
