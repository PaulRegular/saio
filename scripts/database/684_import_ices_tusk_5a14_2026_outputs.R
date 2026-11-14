root <- "."
stock_id <- "ices_tusk_5a14"
assessment_id <- paste0(stock_id, "_2026")
candidate_id <- "ICES:usk.27.5a14"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

cache_options <- c(
  file.path(root, "source_cache", "discovery_ices_tusk_5a14_2026"),
  file.path(root, "..", "..", "discovery_ices_tusk_5a14_2026")
)
cache <- cache_options[dir.exists(cache_options)][1L]
if (is.na(cache)) stop("Could not find the ignored ICES tusk source cache.", call. = FALSE)

provenance_path <- file.path(root, "provenance", assessment_id, "sources.csv")
source_names <- c(
  "MFRI_tusk_2026_technical_report.html",
  "ICES_source_data_2026_key_22530.html",
  "ICES_advice_2026_record_7219.html"
)
manifest <- read.csv(provenance_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
if (!all(source_names %in% manifest$file)) {
  stop("Tusk provenance manifest is missing a source used by the import.", call. = FALSE)
}
manifest <- manifest[match(source_names, manifest$file), , drop = FALSE]

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil.exe"))) {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hashes <- tolower(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
    )))
  } else if (nzchar(Sys.which("sha256sum"))) {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hashes <- tolower(sub("[[:space:]].*$", "", result))
  } else {
    stop("A SHA-256 utility is required to verify cached tusk sources.", call. = FALSE)
  }
  if (length(hashes) != 1L) stop("Could not hash source: ", path, call. = FALSE)
  hashes
}

source_paths <- file.path(cache, source_names)
if (any(!file.exists(source_paths)) ||
    any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
    !identical(tolower(manifest$sha256),
      unname(vapply(source_paths, sha256_file, character(1L))))) {
  stop("Cached ICES tusk sources do not match their provenance manifest.", call. = FALSE)
}

html <- paste(readLines(source_paths[2L], warn = FALSE, encoding = "UTF-8"),
  collapse = "\n")
table_match <- regexpr("(?is)<table\\b[^>]*id=[\"']gvFishData[\"'][^>]*>.*?</table>",
  html, perl = TRUE)
if (table_match[1L] < 0L) stop("Could not locate ICES Standard Graphs fish-data table.", call. = FALSE)
table_html <- regmatches(html, table_match)
table_rows <- regmatches(table_html,
  gregexpr("(?is)<tr\\b[^>]*>.*?</tr>", table_html, perl = TRUE))[[1L]]
cell_text <- function(x) {
  x <- gsub("(?is)<[^>]*>", " ", x, perl = TRUE)
  x <- gsub("&nbsp;|&#160;|&#xA0;", " ", x, ignore.case = TRUE, perl = TRUE)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  trimws(gsub("[[:space:]\u00a0]+", " ", x, perl = TRUE))
}
cells <- lapply(table_rows, function(row) {
  values <- regmatches(row, gregexpr("(?is)<t[hd]\\b[^>]*>.*?</t[hd]>",
    row, perl = TRUE))[[1L]]
  vapply(values, cell_text, character(1L), USE.NAMES = FALSE)
})
header_index <- which(vapply(cells, function(x) "Year" %in% x, logical(1L)))[1L]
if (is.na(header_index)) stop("ICES source table has no Year header.", call. = FALSE)
headers <- cells[[header_index]]
records <- cells[seq.int(header_index + 1L, length(cells))]
records <- records[lengths(records) == length(headers)]
table <- as.data.frame(do.call(rbind, records), stringsAsFactors = FALSE,
  check.names = FALSE)
names(table) <- headers
expected_columns <- c(
  "Year", "Low Recruitment", "Recruitment", "High Recruitment",
  "Low TBiomass", "TBiomass", "High TBiomass", "Low SSB", "SSB",
  "High SSB", "Landings", "Catches", "Discards", "Low F", "F", "High F"
)
if (!identical(names(table), expected_columns) || nrow(table) != 48L) {
  stop("ICES Standard Graphs source data layout differs from the reviewed 2026 table.",
    call. = FALSE)
}
numeric_value <- function(x) {
  x <- gsub("[[:space:]\u00a0,]", "", x, perl = TRUE)
  suppressWarnings(as.numeric(x))
}
table[] <- lapply(table, numeric_value)
table$Year <- as.integer(table$Year)
if (!identical(table$Year, 1979:2026)) {
  stop("ICES tusk output years differ from the verified 1979-2026 coverage.", call. = FALSE)
}
historical <- table[table$Year <= 2025L, , drop = FALSE]
forecast <- table[table$Year == 2026L, , drop = FALSE]
historical_fields <- c(
  "Low Recruitment", "Recruitment", "High Recruitment",
  "Low TBiomass", "TBiomass", "High TBiomass",
  "Low SSB", "SSB", "High SSB", "Low F", "F", "High F"
)
if (nrow(historical) != 47L || any(!is.finite(as.matrix(historical[historical_fields]))) ||
    any(historical[["Low Recruitment"]] > historical$Recruitment |
      historical$Recruitment > historical[["High Recruitment"]]) ||
    any(historical[["Low TBiomass"]] > historical$TBiomass |
      historical$TBiomass > historical[["High TBiomass"]]) ||
    any(historical[["Low SSB"]] > historical$SSB |
      historical$SSB > historical[["High SSB"]]) ||
    any(historical[["Low F"]] > historical$F |
      historical$F > historical[["High F"]])) {
  stop("Historical ICES tusk points or lower/upper bounds are invalid.", call. = FALSE)
}
if (nrow(forecast) != 1L ||
    any(!is.finite(as.numeric(forecast[1L, c(
      "Low Recruitment", "Recruitment", "High Recruitment",
      "Low TBiomass", "TBiomass", "High TBiomass",
      "Low SSB", "SSB", "High SSB"
    )]))) || any(is.finite(as.numeric(forecast[1L, c("Low F", "F", "High F")])))) {
  stop("The 2026 forecast row no longer has the reviewed available fields.", call. = FALSE)
}
if (historical$Recruitment[1L] != 11987 || historical$SSB[1L] != 16244 ||
    historical$F[1L] != 0.089 || historical$Recruitment[nrow(historical)] != 72454 ||
    historical$SSB[nrow(historical)] != 11270 || historical$F[nrow(historical)] != 0.107 ||
    forecast$Recruitment != 76551 || forecast$SSB != 13829) {
  stop("ICES tusk values do not match pinned Standard Graphs key 22530.", call. = FALSE)
}

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "usk.27.5a14", scientific_name = "Brosme brosme",
  common_name = "Tusk", area = "ICES Division 5.a and Subarea 14",
  region = "Iceland and East Greenland", ocean = "Northeast Atlantic",
  notes = paste(
    "Current ICES unit covers Icelandic Division 5.a and East Greenland Subarea 14.",
    "The 2026 assessment reports aggregate outputs for this unit, but the public",
    "sources reviewed do not establish a complete age-specific input set across both areas."
  ), stringsAsFactors = FALSE
)
assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2026L,
  assessment_type = "full_assessment", model_family = "SAM",
  model_version = NA_character_, is_current = TRUE, is_applied = TRUE,
  framework_year = 2022L,
  assessment_url = "https://www.hafogvatn.is/static/extras/images/08_usk_2026_1_techreport_en.html",
  framework_url = "https://doi.org/10.17895/ices.pub.19663971.v1",
  data_url = "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22530",
  model_url = NA_character_, repository_url = NA_character_,
  assumptions_status = "partial", inputs_status = "not_started", outputs_status = "partial",
  notes = paste(
    "The 2026 ICES assessment used SAM and fitted data through 2025.",
    "The 2026 Standard Graphs row is retained separately as a forecast.",
    "This output-only import does not establish age-input eligibility for the full 5.a+14 unit."
  ), stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = "", survey = "", sex = "", region = "", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
assumptions_new <- do.call(rbind, list(
  assumption("model", "assessment_method", "Statistical catch-at-age model (SAM).",
    "MFRI 2026 technical report, Analytical assessment using SAM"),
  assumption("recruitment", "recruitment_age", "1",
    "ICES Standard Graphs source data, Assessment Key 22530, age metadata"),
  assumption("mortality", "fbar_age_range", "7-10",
    "ICES Standard Graphs source data, Assessment Key 22530, age metadata"),
  assumption("management", "reference_points",
    "MSY Btrigger = 4,800 tonnes; FMSY = 0.23 per year; Blim = 3,400 tonnes; Bpa = 4,800 tonnes; Flim = 0.44 per year; Fpa = 0.23 per year.",
    "MFRI 2026 technical report, Table 6",
    "Management reference points adopted from the 2022 benchmark; not fitted annual estimates.")
))

historical_note <- paste(
  "ICES Standard Graphs reports Low, point, and High values.",
  "The reviewed report and source page do not state the interval coverage level;",
  "lwr/upr preserve the source bounds and are not converted to SEs."
)
forecast_note <- paste(
  "2026 is a forecast, while the model's fitted data end in 2025.",
  "Only recruitment, total biomass, and SSB have forecast values in the source table.",
  "The interval coverage level is not stated; lwr/upr preserve the source bounds."
)
make_output <- function(measure, type, value, lower, upper, unit,
                        age = NA_real_, age_group = "", rows = historical,
                        scenario = "", notes = historical_note) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = as.integer(rows$Year), age = age, age_group = age_group,
    value = as.numeric(rows[[value]]), se = NA_real_,
    lwr = as.numeric(rows[[lower]]), upr = as.numeric(rows[[upper]]),
    unit = unit, source_type = "official_table",
    source_reference = "ICES Standard Graphs source data, Assessment Key 22530, Fish data",
    notes = notes, scenario = scenario, stringsAsFactors = FALSE
  )
}
outputs_new <- do.call(rbind, list(
  make_output("recruitment", "recruitment", "Recruitment", "Low Recruitment",
    "High Recruitment", "thousand fish", age = 1L),
  make_output("total_biomass", "biomass", "TBiomass", "Low TBiomass",
    "High TBiomass", "tonnes"),
  make_output("SSB", "biomass", "SSB", "Low SSB", "High SSB", "tonnes"),
  make_output("Fbar", "mortality", "F", "Low F", "High F", "per year",
    age_group = "7-10"),
  make_output("recruitment", "recruitment", "Recruitment", "Low Recruitment",
    "High Recruitment", "thousand fish", age = 1L, rows = forecast,
    scenario = "forecast", notes = forecast_note),
  make_output("total_biomass", "biomass", "TBiomass", "Low TBiomass",
    "High TBiomass", "tonnes", rows = forecast,
    scenario = "forecast", notes = forecast_note),
  make_output("SSB", "biomass", "SSB", "Low SSB", "High SSB", "tonnes",
    rows = forecast, scenario = "forecast", notes = forecast_note)
))

output_key_columns <- c("assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "scenario")
if (nrow(outputs_new) != 191L || anyDuplicated(outputs_new[output_key_columns]) ||
    any(!is.na(outputs_new$se)) || any(!is.finite(outputs_new$value)) ||
    any(!is.finite(outputs_new$lwr)) || any(!is.finite(outputs_new$upr))) {
  stop("Tusk output rows have unexpected dimensions, duplicates, or missing bounds.",
    call. = FALSE)
}

row_signature <- function(data, columns = names(data)) {
  values <- lapply(data[columns], function(x) {
    if (is.numeric(x)) {
      out <- format(x, scientific = FALSE, trim = TRUE, digits = 15)
      out[is.na(x)] <- ""
    } else {
      out <- as.character(x)
      out[is.na(x)] <- ""
    }
    out
  })
  do.call(paste, c(values, sep = "\r"))
}
read_matching_rows <- function(path, id) {
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to scan database rows by assessment.", call. = FALSE)
  found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(found, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not scan ", path, call. = FALSE)
  prefix <- paste0("\"", id, "\",")
  found <- found[startsWith(found, prefix)]
  if (!length(found)) return(data.frame())
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, found), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}
assert_rows_match_or_absent <- function(existing, expected, label) {
  if (!nrow(existing)) return(invisible(FALSE))
  if (nrow(existing) != nrow(expected) ||
      !setequal(row_signature(existing), row_signature(expected))) {
    stop("Existing ", label, " rows differ from the pinned ICES import.", call. = FALSE)
  }
  invisible(TRUE)
}
append_csv <- function(x, path) {
  write.table(x, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double",
    fileEncoding = "UTF-8")
}

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(assessments_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock_existing <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment_existing <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions_existing <- read_matching_rows(assumptions_path, assessment_id)
inputs_existing <- read_matching_rows(inputs_path, assessment_id)
outputs_existing <- read_matching_rows(outputs_path, assessment_id)
if (nrow(stock_existing) > 1L || nrow(assessment_existing) > 1L || nrow(inputs_existing)) {
  stop("Duplicate identity or unexpected input rows found for the output-only Tusk import.",
    call. = FALSE)
}
if (nrow(stock_existing) &&
    !setequal(row_signature(stock_existing), row_signature(stock_row))) {
  stop("Existing Tusk stock row differs from the reviewed unit.", call. = FALSE)
}
if (nrow(assessment_existing) &&
    !setequal(row_signature(assessment_existing), row_signature(assessment_row))) {
  stop("Existing Tusk assessment row differs from the reviewed 2026 run.", call. = FALSE)
}
assert_rows_match_or_absent(assumptions_existing, assumptions_new, "assumption")
assert_rows_match_or_absent(outputs_existing, outputs_new, "output")

cat("Verified ICES tusk 2026 source import.\n")
cat("Outputs:", nrow(outputs_new), "aggregate annual estimates; 1979-2025 fitted and 2026 forecast.\n")
cat("Inputs: 0 numeric model-input rows; age-input eligibility remains unresolved for the full 5.a+14 unit.\n")

if (write_mode) {
  if (!nrow(stock_existing)) append_csv(stock_row, stocks_path)
  if (!nrow(assessment_existing)) append_csv(assessment_row, assessments_path)
  if (!nrow(assumptions_existing)) append_csv(assumptions_new, assumptions_path)
  if (!nrow(outputs_existing)) append_csv(outputs_new, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"), local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$eligibility[ci] != "unresolved") {
    stop("Expected one unresolved ICES tusk candidate.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$output_evidence[ci] <- paste(
    "ICES Standard Graphs key 22530 provides 1979-2025 aggregate total biomass, SSB, age-1 recruitment, and Fbar ages 7-10, with source Low/High bounds; it also has a 2026 forecast for total biomass, SSB, and recruitment.",
    "No numerical N-at-age or F-at-age surfaces were recovered. The interval coverage level is not stated."
  )
  candidates$decision_reason[ci] <- paste(
    "Eligibility remains unresolved for the current combined 2026 ICES unit. Official aggregate outputs are now preserved in the canonical database, but the public sources reviewed do not establish complete age-specific inputs for both 5.a and 14. Do not infer full-unit age-data eligibility from Iceland-only figures."
  )
  candidates$notes[ci] <- paste(
    candidates$notes[ci],
    "A partial output-only record was added for the 2026 current unit: aggregate historical outputs through 2025 and the reported 2026 forecast. Age-specific input and N/F-at-age gaps remain unresolved; no translation eligibility is implied."
  )
  replace_candidate_register_row(candidate_path, ci,
    candidates[ci, , drop = FALSE], candidate_id)

  inventory_path <- file.path(root, "discovery", "inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ui <- candidate_inventory_row(inventory, candidate_id, stock_id)
  inventory$matched_stock_id[ui] <- stock_id
  inventory$match_status[ui] <- "matched"
  inventory$import_status[ui] <- "partial"
  replace_csv_register_row(inventory_path, ui, inventory[ui, , drop = FALSE],
    "unit_key", paste0("candidate:", stock_id))

  source(file.path(root, "scripts", "database", "002_validate_database.R"), local = TRUE)
  cat("Import written and database validation passed.\n")
}
