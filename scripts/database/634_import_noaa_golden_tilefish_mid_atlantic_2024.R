root <- "."
stock_id <- "noaa_golden_tilefish_mid_atlantic"
assessment_id <- paste0(stock_id, "_2024")
candidate_id <- "NOAA:10385"
cache <- file.path(root, "source_cache", "discovery_noaa_golden_tilefish_2024")
manifest_path <- file.path(root, "provenance", assessment_id, "manifest.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached NOAA assessment report.", call. = FALSE)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)

verify_source <- function(name) {
  row <- manifest[manifest$source == name, , drop = FALSE]
  path <- file.path(cache, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      file.info(path)$size != as.numeric(row$bytes) ||
      !identical(toupper(unname(tools::sha256sum(path))), toupper(row$sha256))) {
    stop("Cached NOAA source differs from its provenance manifest: ", name,
      call. = FALSE)
  }
  path
}

report_path <- verify_source("assessment_report_2024.pdf")
invisible(verify_source("management_track_peer_review_2024.pdf"))
input_figure_path <- verify_source("final_input_data.pdf")
results_figure_path <- verify_source("final_results.pdf")
invisible(verify_source("2024_GT_UNIT.zip"))

report_pages <- pdftools::pdf_text(report_path)
input_pages <- pdftools::pdf_text(input_figure_path)
result_pages <- pdftools::pdf_text(results_figure_path)
if (length(report_pages) != 9L || length(input_pages) != 11L ||
    length(result_pages) != 18L ||
    !grepl("Table 1: Catch and status table for Golden Tilefish", report_pages[2L],
      fixed = TRUE) ||
    !grepl("draft working paper for peer review only", report_pages[1L],
      fixed = TRUE) ||
    !grepl("Age Comps for Catch for Fleet 1", paste(input_pages, collapse = "\n"),
      fixed = TRUE)) {
  stop("The pinned NOAA assessment report or support graphics changed structure.",
    call. = FALSE)
}

number_tokens <- function(line) {
  pattern <- "(?<![[:alnum:]])-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?(?![[:alnum:]])"
  tokens <- regmatches(line, gregexpr(pattern, line, perl = TRUE))[[1L]]
  if (length(tokens) == 1L && !nzchar(tokens)) return(numeric())
  as.numeric(gsub(",", "", tokens, fixed = TRUE))
}

report_lines <- strsplit(report_pages[2L], "\n", fixed = TRUE)[[1L]]
year_header <- grep(
  "^\\s*2014\\s+2015\\s+2016\\s+2017\\s+2018\\s+2019\\s+2020\\s+2021\\s+2022\\s+2023\\s*$",
  report_lines, value = TRUE, perl = TRUE
)
if (length(year_header) != 1L ||
    !identical(as.integer(number_tokens(year_header)), 2014:2023)) {
  stop("The Golden Tilefish Table 1 year header changed.", call. = FALSE)
}

parse_table_row <- function(label_pattern, label) {
  matches <- grep(label_pattern, report_lines, value = TRUE,
    perl = TRUE, ignore.case = TRUE)
  if (length(matches) != 1L) {
    stop("Expected one Table 1 row for ", label, ".", call. = FALSE)
  }
  values <- number_tokens(sub(label_pattern, "", matches, perl = TRUE,
    ignore.case = TRUE))
  if (length(values) != 10L || any(!is.finite(values))) {
    stop("Unexpected numeric values in Table 1 row ", label, ".", call. = FALSE)
  }
  values
}

years <- 2014:2023
commercial_landings <- parse_table_row(
  "^\\s*Commercial landings\\s+", "commercial landings")
commercial_discards <- parse_table_row(
  "^\\s*Commercial discards\\s+", "commercial discards")
recreational_landings <- parse_table_row(
  "^\\s*Recreational landings\\s+", "recreational landings")
assessment_catch <- parse_table_row(
  "^\\s*Catch for Assessment\\s+", "catch for assessment")
ssb <- parse_table_row(
  "^\\s*Spawning Stock Biomass\\s+", "spawning stock biomass")
f_at_age_6 <- parse_table_row(
  "^\\s*F+\\s*ull\\s+", "fully selected fishing mortality")
recruitment_age_1 <- parse_table_row(
  "^\\s*Recruits\\s*\\(age 1\\)\\s+", "age-1 recruitment")

component_difference <- assessment_catch - commercial_landings -
  commercial_discards - recreational_landings
if (any(abs(component_difference) > 1) || any(ssb <= 0) || any(f_at_age_6 <= 0) ||
    any(recruitment_age_1 <= 0)) {
  stop("Golden Tilefish Table 1 values or catch components do not reconcile.",
    call. = FALSE)
}

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "NOAA",
  authority_stock_id = "10385", scientific_name = "Lopholatilus chamaeleonticeps",
  common_name = "Golden tilefish", area = "Mid-Atlantic Coast",
  region = "United States Mid-Atlantic Coast", ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART unit 10385. This Mid-Atlantic stock is separate from the Gulf of Mexico and South Atlantic golden tilefish units.",
  stringsAsFactors = FALSE
)

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2023L, estimate_terminal_year = 2023L,
  assessment_type = "management_track_assessment", model_family = "WHAM",
  model_version = NA_character_, is_current = TRUE, is_applied = TRUE,
  framework_year = 2024L,
  assessment_url = manifest$url[match("assessment_report_2024.pdf", manifest$source)],
  framework_url = "https://repository.library.noaa.gov/view/noaa/77451",
  data_url = manifest$url[match("final_input_data.pdf", manifest$source)],
  model_url = NA_character_,
  repository_url = manifest$url[match("2024_GT_UNIT.zip", manifest$source)],
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "The 2024 management-track WHAM run uses data through 2023. The assessment report remains watermarked as a draft working paper for peer review; the NOAA management-track panel review and applied advice identify this as the production run. Numeric age-composition, commercial LPUE, biological input arrays, and most age-specific outputs remain unavailable in the cached materials.",
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = "", survey = "", sex = "", region = "", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}

report_table <- "2024 Management Track Assessment Report, Table 1, printed page 1"
assumptions_new <- do.call(rbind, list(
  assumption("model", "model_family", "Woods Hole Assessment Model (WHAM)",
    report_table, "2024 management-track update based on the 2024 WHAM research-track model."),
  assumption("abundance", "N_at_age_process", "IID random effects on N-at-age",
    report_table, "The Table 1 caption describes the reported estimates as using iid random effects on NAA."),
  assumption("F", "selectivity", "Full selection at ages 5 and 6 in the second selectivity block",
    report_table),
  assumption("F", "fully_selected_age", "6", report_table),
  assumption("recruitment", "recruitment_age", "1", report_table),
  assumption("index", "abundance_indices", "Three commercial LPUE indices; no fishery-independent index",
    "2024 Management Track Assessment Report and final input-data graphics",
    "The annual series are plotted in the support material; numeric index values were not recovered."),
  assumption("management", "FMSY_proxy", "0.211 per year",
    "2024 Management Track Assessment Report, Table 2, printed page 1",
    "The report gives a 95% interval of 0.181-0.247 per year."),
  assumption("management", "SSBMSY_proxy", "7,537 mt",
    "2024 Management Track Assessment Report, Table 2, printed page 1",
    "The report gives a 95% interval of 5,805-9,787 mt.")
))

input_notes <- paste(
  "Source-reported Catch for Assessment values from the 2024 management-track Table 1, in metric tonnes.",
  "The same table lists commercial landings, commercial discards, and recreational landings separately. Their displayed sum differs from Catch for Assessment by 1 mt in 2016, 2018 and 2022; the source-reported assessment total is retained unchanged.",
  "The report only tabulates 2014-2023 catch totals. Catch-at-age compositions and older catch history are shown in figures or remain unavailable as numeric arrays."
)
inputs_new <- data.frame(
  assessment_id = assessment_id, type = "catch", measure = "catch_biomass",
  basis = "biomass", fleet = "", survey = "", sex = "", region = "",
  season = "annual", year = years, year_basis = "calendar_year", age = NA_real_,
  value = assessment_catch, unit = "mt", sampling_time = NA_real_,
  source_type = "official_table", source_reference = report_table,
  transformation = "No transformation; source-reported Catch for Assessment total.",
  notes = input_notes, observation_id = paste0("GTF_CATCH_", years),
  length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = "", weight_bin = NA_real_,
  stringsAsFactors = FALSE
)

output_notes <- paste(
  "Point estimates from the 2024 management-track Table 1; the table does not report annual uncertainty.",
  "Recruitment is age 1; fully selected fishing mortality is reported for age 6 only and is not a complete F-at-age surface."
)
output_rows <- function(measure, type, values, unit, age = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = years, age = age, age_group = "", value = values, se = NA_real_,
    lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "official_table", source_reference = report_table,
    notes = output_notes, scenario = "", stringsAsFactors = FALSE
  )
}
outputs_new <- do.call(rbind, list(
  output_rows("SSB", "biomass", ssb, "mt"),
  output_rows("fishing_mortality_at_age", "mortality", f_at_age_6,
    "per year", age = 6),
  output_rows("recruitment", "recruitment", recruitment_age_1,
    "thousand fish", age = 1)
))

input_key_columns <- c("assessment_id", "type", "measure", "basis", "fleet",
  "survey", "sex", "region", "season", "year", "year_basis", "age",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin")
output_key_columns <- c("assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "scenario")
if (nrow(assumptions_new) != 8L || nrow(inputs_new) != 10L ||
    nrow(outputs_new) != 30L || anyDuplicated(inputs_new[input_key_columns]) ||
    anyDuplicated(outputs_new[output_key_columns])) {
  stop("Golden Tilefish source records have unexpected dimensions or duplicates.",
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
    stop("Existing Golden Tilefish ", label,
      " rows differ from the reviewed source records.", call. = FALSE)
  }
  invisible(TRUE)
}

append_csv <- function(x, path) {
  write.table(x, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double", eol = "\n")
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
assumptions_existing <- read_matching_rows(assumptions_path, assessment_id)
inputs_existing <- read_matching_rows(inputs_path, assessment_id)
outputs_existing <- read_matching_rows(outputs_path, assessment_id)
stock_existing <- stocks[!is.na(stocks$stock_id) & stocks$stock_id == stock_id,
  , drop = FALSE]
assessment_existing <- assessments[
  !is.na(assessments$assessment_id) & assessments$assessment_id == assessment_id,
  , drop = FALSE
]
if (nrow(stock_existing) > 1L || nrow(assessment_existing) > 1L) {
  stop("Golden Tilefish stock or assessment identifiers are duplicated.", call. = FALSE)
}
if (nrow(stock_existing) &&
    !setequal(row_signature(stock_existing), row_signature(stock_row))) {
  stop("Existing Mid-Atlantic Golden Tilefish stock row differs from reviewed identity.",
    call. = FALSE)
}
if (nrow(assessment_existing) &&
    !setequal(row_signature(assessment_existing), row_signature(assessment_row))) {
  stop("Existing Mid-Atlantic Golden Tilefish assessment row differs from the reviewed run.",
    call. = FALSE)
}
assert_rows_match_or_absent(assumptions_existing, assumptions_new, "assumption")
assert_rows_match_or_absent(inputs_existing, inputs_new, "input")
assert_rows_match_or_absent(outputs_existing, outputs_new, "output")

cat("Verified NOAA Mid-Atlantic Golden Tilefish 2024 source import.\n")
cat("Inputs:", nrow(inputs_new), "assessment catch totals (2014-2023).\n")
cat("Outputs:", nrow(outputs_new), "annual SSB, age-6 F, and age-1 recruitment estimates.\n")
cat("Unresolved:", "numeric age compositions, commercial LPUE, age-specific biology, and full N/F surfaces.\n")

if (write_mode) {
  if (!nrow(stock_existing)) append_csv(stock_row, stocks_path)
  if (!nrow(assessment_existing)) append_csv(assessment_row, assessments_path)
  if (!nrow(assumptions_existing)) append_csv(assumptions_new, assumptions_path)
  if (!nrow(inputs_existing)) append_csv(inputs_new, inputs_path)
  if (!nrow(outputs_existing)) append_csv(outputs_new, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"),
    local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  candidate_rows <- which(!is.na(candidates$candidate_id) &
    candidates$candidate_id == candidate_id &
    candidates$official_stock_id == "10385")
  if (length(candidate_rows) != 1L ||
      candidates$eligibility[candidate_rows] != "eligible" ||
      candidates$screening_status[candidate_rows] != "screened") {
    stop("Expected one screened eligible NOAA:10385 candidate.", call. = FALSE)
  }
  ci <- candidate_rows
  existing_match <- candidates$matched_stock_id[ci]
  if (!is.na(existing_match) && nzchar(existing_match) &&
      existing_match != stock_id) {
    stop("NOAA:10385 is already matched to a different stock.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$catch_age_evidence[ci] <- paste(
    "The official 2024 report tabulates assessment catch biomass for 2014-2023 and lists its commercial landings, discards and recreational landings components.",
    "Catch-at-age compositions are plotted; no numeric age-composition array was recovered."
  )
  candidates$survey_age_evidence[ci] <- paste(
    "Three commercial LPUE series are shown in the final input graphics, but numerical annual values were not tabulated.",
    "No fishery-independent abundance index is included."
  )
  candidates$weights_evidence[ci] <- "Age-specific SSB, January 1 biomass and catch weights are plotted in the final input graphics; numeric values remain unavailable."
  candidates$maturity_evidence[ci] <- "Maturity-at-age is plotted in the final input graphics; the numeric schedule remains unavailable."
  candidates$mortality_evidence[ci] <- "The report tabulates fully selected F at age 6 for 2014-2023. A full F-at-age surface and numeric natural-mortality inputs were not recovered."
  candidates$timing_evidence[ci] <- "The annual assessment uses commercial CPUE series; no fractional within-year index timing was reported."
  candidates$output_evidence[ci] <- paste(
    "Table 1 reports SSB, fully selected F at age 6 and age-1 recruitment for 2014-2023.",
    "The support archive plots N-at-age and broader F-at-age trajectories but contains no numeric output tables or uncertainty estimates for these annual values."
  )
  candidates$review_date[ci] <- "2026-11-11"
  candidates$notes[ci] <- paste(
    "Imported Table 1 assessment catch, SSB, age-6 fishing mortality and age-1 recruitment values for 2014-2023.",
    "The NOAA support archive contains graphics and diagnostics, not a native WHAM fit object or numeric input arrays; see source_reviews/noaa_golden_tilefish_mid_atlantic_2024.md."
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
  replace_csv_register_row(inventory_path, ui,
    inventory[ui, , drop = FALSE], "unit_key", paste0("candidate:", stock_id))

  source(file.path(root, "scripts", "database", "002_validate_database.R"),
    local = TRUE)
  cat("Import written and database validation passed.\n")
}
