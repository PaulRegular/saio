root <- "."
stock_id <- "ices_greater_silver_smelt_5a14"
assessment_id <- paste0(stock_id, "_2026")
cache <- file.path(root, "source_cache", "discovery_ices_gss_2026")
manifest_path <- file.path(root, "provenance", assessment_id, "manifest.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hash <- toupper(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
    )))
  } else {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hash <- toupper(strsplit(result, "[[:space:]]+")[[1L]][1L])
  }
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}

verify_source <- function(name) {
  row <- manifest[manifest$source == name, , drop = FALSE]
  path <- file.path(cache, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      file.info(path)$size != as.numeric(row$bytes) ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached ICES/MFRI source differs from its provenance manifest: ",
      name, call. = FALSE)
  }
  path
}

report_path <- verify_source("19_arg_2026_1_techreport_en.html")
invisible(verify_source("19_arg_2026_1_advice_en.html"))
graphs_path <- verify_source("ices_standardgraphs_22476.html")
source_data_path <- verify_source("ices_standardgraphs_source_22476.html")
invisible(verify_source("WKBDEEP_2025_Report.pdf"))

html_cell_text <- function(x) {
  x <- gsub("(?is)<[^>]*>", " ", x, perl = TRUE)
  x <- gsub("&nbsp;|&#160;|&#xA0;", "", x, ignore.case = TRUE, perl = TRUE)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&lt;", "<", x, fixed = TRUE)
  x <- gsub("&gt;", ">", x, fixed = TRUE)
  x <- gsub("&ndash;|&#8211;|&#x2013;", "-", x, ignore.case = TRUE, perl = TRUE)
  x <- gsub("[[:space:]\u00a0]+", " ", x, perl = TRUE)
  trimws(x)
}

read_html_tables <- function(path) {
  html <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  tables <- regmatches(html, gregexpr("(?is)<table\\b.*?</table>",
    html, perl = TRUE))[[1L]]
  if (!length(tables) || identical(tables, "")) {
    stop("No HTML tables were found in ", path, call. = FALSE)
  }
  lapply(seq_along(tables), function(table_index) {
    table <- tables[[table_index]]
    rows <- regmatches(table, gregexpr("(?is)<tr\\b.*?</tr>",
      table, perl = TRUE))[[1L]]
    cells <- lapply(rows, function(row) {
      row_content <- sub("(?is)^.*?<tr\\b[^>]*>", "", row, perl = TRUE)
      parts <- strsplit(row_content, "(?is)</t[dh]>", perl = TRUE)[[1L]]
      parts <- parts[grepl("(?is)<t[dh]\\b", parts, perl = TRUE)]
      vapply(parts, function(part) {
        content <- sub("(?is)^.*?<t[dh]\\b[^>]*>", "", part, perl = TRUE)
        html_cell_text(content)
      }, character(1L), USE.NAMES = FALSE)
    })
    keep <- lengths(cells) >= 2L & vapply(cells, function(x) {
      any(nzchar(x))
    }, logical(1L))
    cells <- cells[keep]
    if (!length(cells)) return(data.frame())
    width <- max(lengths(cells))
    if (!is.finite(width) || width < 2L) {
      return(data.frame())
    }
    matrix_cells <- t(vapply(cells, function(x) {
      c(x, rep("", width - length(x)))
    }, character(width)))
    out <- as.data.frame(matrix_cells, stringsAsFactors = FALSE,
      check.names = FALSE)
    headers <- as.character(unlist(out[1L, , drop = FALSE], use.names = FALSE))
    if (any(!nzchar(headers)) || anyDuplicated(headers)) {
      return(data.frame())
    }
    names(out) <- headers
    out <- out[-1L, , drop = FALSE]
    rownames(out) <- NULL
    out
  })
}

numeric_value <- function(x) {
  x <- gsub("[[:space:]\u00a0]", "", x, perl = TRUE)
  x <- gsub(",", "", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

report_tables <- read_html_tables(report_path)
graphs_tables <- read_html_tables(source_data_path)
if (length(report_tables) != 7L || length(graphs_tables) != 8L) {
  stop("The pinned report or ICES source-data table structure has changed.",
    call. = FALSE)
}

landings_table <- report_tables[[3L]]
if (!identical(names(landings_table),
    c("Year", "Section 5.a", "Section 14.b", "Total")) ||
    nrow(landings_table) != 38L) {
  stop("MFRI 2026 Table 3 no longer has the expected landings structure.",
    call. = FALSE)
}
landings <- data.frame(
  year = as.integer(numeric_value(landings_table$Year)),
  section_5a = numeric_value(landings_table[["Section 5.a"]]),
  section_14b = numeric_value(landings_table[["Section 14.b"]]),
  total = numeric_value(landings_table$Total),
  stringsAsFactors = FALSE
)
if (!identical(landings$year, 1988:2025) ||
    any(!is.finite(as.matrix(landings[-1L]))) ||
    any(landings$section_5a < 0 | landings$section_14b < 0) ||
    any(landings$total != landings$section_5a + landings$section_14b)) {
  stop("MFRI Table 3 years or landings values differ from the published source.",
    call. = FALSE)
}

graph_table <- graphs_tables[[4L]]
expected_graph_columns <- c(
  "Year", "Low Recruitment", "Recruitment", "High Recruitment",
  "Low TBiomass", "TBiomass", "High TBiomass",
  "Low SSB", "SSB", "High SSB", "Landings", "Catches", "Discards",
  "Low F", "F", "High F"
)
if (!identical(names(graph_table), expected_graph_columns) ||
    nrow(graph_table) != 27L) {
  stop("ICES Standard Graphs source table has changed from its pinned layout.",
    call. = FALSE)
}
graphs <- graph_table
for (column in names(graphs)) graphs[[column]] <- numeric_value(graphs[[column]])
graphs$Year <- as.integer(graphs$Year)
if (!identical(graphs$Year, 2000:2026)) {
  stop("ICES Standard Graphs year coverage differs from 2000-2026.", call. = FALSE)
}
fitted_graphs <- graphs[graphs$Year <= 2025, , drop = FALSE]
if (any(!is.finite(as.matrix(fitted_graphs[c(
  "Low Recruitment", "Recruitment", "High Recruitment", "Low TBiomass",
  "TBiomass", "High TBiomass", "Low SSB", "SSB", "High SSB",
  "Low F", "F", "High F"
)])))) {
  stop("ICES fitted-output table contains missing point or interval values.",
    call. = FALSE)
}
if (any(fitted_graphs[["Low Recruitment"]] > fitted_graphs$Recruitment |
    fitted_graphs$Recruitment > fitted_graphs[["High Recruitment"]]) ||
    any(fitted_graphs[["Low TBiomass"]] > fitted_graphs$TBiomass |
      fitted_graphs$TBiomass > fitted_graphs[["High TBiomass"]]) ||
    any(fitted_graphs[["Low SSB"]] > fitted_graphs$SSB |
      fitted_graphs$SSB > fitted_graphs[["High SSB"]]) ||
    any(fitted_graphs[["Low F"]] > fitted_graphs$F |
      fitted_graphs$F > fitted_graphs[["High F"]])) {
  stop("ICES lower/point/upper output values are inconsistent.", call. = FALSE)
}

landings_5a <- landings[landings$year %in% 2000:2025, , drop = FALSE]
catch_comparison <- data.frame(
  year = fitted_graphs$Year,
  ices_catch = fitted_graphs$Catches,
  mfri_section_5a = landings_5a$section_5a
)
catch_discrepancies <- catch_comparison[
  catch_comparison$ices_catch != catch_comparison$mfri_section_5a, , drop = FALSE
]
if (!identical(catch_discrepancies$year, c(2015L, 2019L, 2020L)) ||
    !identical(catch_discrepancies$ices_catch -
      catch_discrepancies$mfri_section_5a, c(10, 2, 5))) {
  stop("ICES and MFRI catch-source differences changed from the reviewed values.",
    call. = FALSE)
}

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "aru.27.5a14", scientific_name = "Argentina silus",
  common_name = "Greater silver smelt",
  area = "ICES Subarea 14 and Division 5.a",
  region = "Iceland and East Greenland", ocean = "Northeast Atlantic",
  notes = "ICES assessment unit aru.27.5a14. The 2026 fitted assessment is based on age-structured SAM and reports data through 2025.",
  stringsAsFactors = FALSE
)

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
  assessment_type = "full_assessment", model_family = "SAM",
  model_version = NA_character_, is_current = TRUE, is_applied = TRUE,
  framework_year = 2025L,
  assessment_url = "https://www.hafogvatn.is/static/extras/images/19_arg_2026_1_techreport_en.html",
  framework_url = "https://doi.org/10.17895/ices.pub.28882295",
  data_url = "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22476",
  model_url = NA_character_, repository_url = NA_character_,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2026 assessment used for 2026/2027 advice; fitted data end in 2025. Numeric age-specific input matrices and N-at-age/F-at-age outputs were not found. ICES Standard Graphs includes a 2026 forecast row, excluded from the fitted annual series.",
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = "", survey = "", sex = "", region = "", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}

assumptions_new <- do.call(rbind, list(
  assumption("model", "assessment_method", "Statistical catch-at-age model (SAM).",
    "MFRI 2026 advice; MFRI 2026 technical report, Stock assessment section"),
  assumption("mortality", "natural_mortality", "0.1 per year, fixed for all ages.",
    "ICES WKBDEEP 2025, Section 1.9, printed page 40",
    "The benchmark tested fixed-M values and selected 0.1 for the current assessment method."),
  assumption("recruitment", "recruitment_age", "5",
    "MFRI 2026 technical report, Figure 20 and Table 7; ICES Standard Graphs"),
  assumption("mortality", "fbar_age_range", "6-14",
    "MFRI 2026 technical report, Figure 20; ICES Standard Graphs"),
  assumption("index", "survey_series", "IS-SMB spring groundfish survey and IS-SMH autumn groundfish survey.",
    "MFRI 2026 advice and technical report",
    "Age-specific survey series are shown in figures; numeric fitted input series were not recovered."),
  assumption("model", "assessment_year_basis", "Annual calendar-year SAM assessment.",
    "MFRI 2026 technical report, Section 1.10",
    "Advice is for a September-August fishing year and uses a separate within-year short-term projection adjustment."),
  assumption("management", "reference_points", "FMSY = 0.093 per year; Bpa/MSY Btrigger = 49,481 tonnes; Blim = 40,531 tonnes.",
    "MFRI 2026 technical report, Table 5; ICES WKBDEEP 2025",
    "Management reference points, not annual fitted population outputs.")
))

input_notes <- paste(
  "Imported from the ICES Standard Graphs Catches column, an official assessment source-data series.",
  "MFRI 2026 Table 3 separately reports Section 5.a, Section 14.b, and combined landings; its current Section 5.a values differ from the ICES series in 2015 (+10 tonnes in ICES), 2019 (+2 tonnes), and 2020 (+5 tonnes).",
  "No native SAM input file was located, so the current MFRI landings are retained as a documented cross-check rather than substituted for the ICES assessment catch series. The assessment catch before 2000 remains unavailable."
)
inputs_new <- data.frame(
  assessment_id = assessment_id, type = "catch", measure = "catch_biomass",
  basis = "biomass", fleet = "", survey = "", sex = "", region = "",
  season = "annual", year = as.integer(fitted_graphs$Year),
  year_basis = "calendar_year", age = NA_real_,
  value = as.numeric(fitted_graphs$Catches), unit = "tonnes",
  sampling_time = NA_real_, source_type = "official_table",
  source_reference = "ICES Standard Graphs source data, Assessment Key 22476, Catches",
  transformation = "No transformation; source-reported assessment catch in tonnes.",
  notes = input_notes,
  observation_id = paste0("GSS_CATCH_", fitted_graphs$Year),
  length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = "", weight_bin = NA_real_,
  stringsAsFactors = FALSE
)

output_notes <- paste(
  "ICES Standard Graphs source data for assessment key 22476.",
  "The lower and upper values are the source's 2.5th and 97.5th percentile bounds; no SE is reported.",
  "The 2026 row is a projection/advice value and is excluded from the fitted annual series, which ends in 2025."
)
output_rows <- function(measure, type, value, lower, upper, unit,
                        age = NA_real_, age_group = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = as.integer(fitted_graphs$Year), age = age, age_group = age_group,
    value = as.numeric(fitted_graphs[[value]]), se = NA_real_,
    lwr = as.numeric(fitted_graphs[[lower]]),
    upr = as.numeric(fitted_graphs[[upper]]), unit = unit,
    source_type = "official_table",
    source_reference = "ICES Standard Graphs source data, Assessment Key 22476, Fish data",
    notes = output_notes, scenario = "",
    stringsAsFactors = FALSE
  )
}
outputs_new <- do.call(rbind, list(
  output_rows("recruitment", "recruitment", "Recruitment",
    "Low Recruitment", "High Recruitment", "thousand fish", age = 5),
  output_rows("total_biomass", "biomass", "TBiomass",
    "Low TBiomass", "High TBiomass", "tonnes"),
  output_rows("SSB", "biomass", "SSB", "Low SSB", "High SSB", "tonnes"),
  output_rows("Fbar", "mortality", "F", "Low F", "High F",
    "per year", age_group = "6-14")
))

input_key_columns <- c("assessment_id", "type", "measure", "basis", "fleet",
  "survey", "sex", "region", "season", "year", "year_basis", "age",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin")
output_key_columns <- c("assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "scenario")
if (nrow(inputs_new) != 26L || nrow(outputs_new) != 104L ||
    nrow(assumptions_new) != 7L ||
    anyDuplicated(inputs_new[input_key_columns]) ||
    anyDuplicated(outputs_new[output_key_columns])) {
  stop("Greater silver smelt source records have unexpected dimensions or duplicates.",
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
  if (!nzchar(rg)) stop("rg is required to check existing assessment rows.", call. = FALSE)
  found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(found, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not scan ", path, call. = FALSE)
  prefix <- paste0('"', id, '",')
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
    stop("Existing ", label, " rows do not match the verified source import.",
      call. = FALSE)
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
assumptions <- read_matching_rows(assumptions_path, assessment_id)
inputs_existing <- read_matching_rows(inputs_path, assessment_id)
outputs_existing <- read_matching_rows(outputs_path, assessment_id)

stock_existing <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment_existing <- assessments[
  assessments$assessment_id == assessment_id, , drop = FALSE
]
if (nrow(stock_existing) > 1L || nrow(assessment_existing) > 1L) {
  stop("Greater silver smelt stock or assessment identifiers are duplicated.",
    call. = FALSE)
}
if (nrow(stock_existing) &&
    !setequal(row_signature(stock_existing), row_signature(stock_row))) {
  stop("Existing greater silver smelt stock row differs from reviewed identity.",
    call. = FALSE)
}
if (nrow(assessment_existing) &&
    !setequal(row_signature(assessment_existing), row_signature(assessment_row))) {
  stop("Existing greater silver smelt assessment row differs from the reviewed run.",
    call. = FALSE)
}
assert_rows_match_or_absent(assumptions, assumptions_new, "assumption")
assert_rows_match_or_absent(inputs_existing, inputs_new, "input")
assert_rows_match_or_absent(outputs_existing, outputs_new, "output")

cat("Verified ICES greater silver smelt 2026 source import.\n")
cat("Inputs:", nrow(inputs_new), "ICES assessment catch rows (2000-2025).\n")
cat("Outputs:", nrow(outputs_new), "annual SAM results (2000-2025), with 2.5/97.5 percentile bounds.\n")
cat("Unresolved:", "numeric catch-at-age, survey-at-age, weight-at-age and maturity-at-age matrices.\n")

if (write_mode) {
  if (!nrow(stock_existing)) append_csv(stock_row, stocks_path)
  if (!nrow(assessment_existing)) append_csv(assessment_row, assessments_path)
  if (!nrow(assumptions)) append_csv(assumptions_new, assumptions_path)
  if (!nrow(inputs_existing)) append_csv(inputs_new, inputs_path)
  if (!nrow(outputs_existing)) append_csv(outputs_new, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"),
    local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_unit_id == stock_id &
    candidates$official_stock_id == "aru.27.5a14")
  if (length(ci) != 1L) {
    stop("Expected one screened ICES aru.27.5a14 candidate.", call. = FALSE)
  }
  candidate_id <- candidates$candidate_id[ci]
  if (candidates$eligibility[ci] != "eligible" ||
      candidates$screening_status[ci] != "screened") {
    stop("The ICES candidate no longer has eligible screened status.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$catch_age_evidence[ci] <- paste(
    "ICES Standard Graphs provides assessment catch biomass for 2000-2025; MFRI 2026 Table 3 reports Section 5.a and 14.b landings for 1988-2025.",
    "The series differ in 2015, 2019, and 2020; no native SAM input file or numeric catch-at-age matrix was recovered."
  )
  candidates$survey_age_evidence[ci] <- paste(
    "The current report documents age-specific IS-SMB spring and IS-SMH autumn survey indices in figures, but no numeric fitted index-at-age matrix was recovered."
  )
  candidates$weights_evidence[ci] <- paste(
    "Stock weights-at-age are shown in a figure; numeric values were not tabulated in the current assessment report."
  )
  candidates$maturity_evidence[ci] <- paste(
    "Age-specific maturity is shown in a figure; numeric values were not tabulated in the current assessment report."
  )
  candidates$mortality_evidence[ci] <- paste(
    "Natural mortality is fixed at 0.1 per year for all ages, following the 2025 WKBDEEP benchmark."
  )
  candidates$timing_evidence[ci] <- paste(
    "The SAM assessment is annual and calendar-year based; spring/autumn survey timing fractions were not reported numerically."
  )
  candidates$output_evidence[ci] <- paste(
    "ICES Standard Graphs provides annual total biomass, SSB, age-5 recruitment and Fbar ages 6-14 for 2000-2025, with 2.5th/97.5th percentile bounds.",
    "Numeric N-at-age and F-at-age surfaces were not found; the 2026 row is a forecast and is excluded from fitted outputs."
  )
  candidates$notes[ci] <- paste(
    "Imported the ICES assessment catch series and annual official SAM summary outputs; current MFRI regional landings are documented as a cross-check and were not substituted for the assessment series.",
    "Age-specific input matrices and N/F-at-age outputs remain unavailable. See source_reviews/ices_greater_silver_smelt_5a14_2026.md."
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

  source(file.path(root, "scripts", "database", "002_validate_database.R"),
    local = TRUE)
  cat("Import written and database validation passed.\n")
}
