root <- "."
cache <- file.path(root, "source_cache", "discovery_noaa_bluefish_2025")
manifest_path <- file.path(root, "provenance", "discovery_noaa_bluefish_2025", "sources.csv")
stock_id <- "noaa_bluefish_atlantic_coast"
assessment_id <- "noaa_bluefish_atlantic_2025"
candidate_id <- "NOAA:10388"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) stop("pdftools is required.", call. = FALSE)
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))
read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
  na.strings = c("", "NA"), check.names = FALSE)
manifest <- read_csv(manifest_path)
sha256_file <- function(path) tolower(unname(tools::sha256sum(path)))
verify_source <- function(name) {
  i <- which(manifest$file == name)
  path <- file.path(cache, name)
  if (length(i) != 1L || !file.exists(path) ||
      sha256_file(path) != tolower(manifest$sha256[i]) ||
      as.numeric(file.info(path)$size) != as.numeric(manifest$bytes[i])) {
    stop("Missing or changed NOAA bluefish source: ", name, call. = FALSE)
  }
  path
}

report_path <- verify_source("2025_BLF_UNIT_RPT_Atlantic_Bluefish_Update_2025_06_10_082854.125567.pdf")
input_path <- verify_source("2025_BLF_UNIT_FIG_input_data.pdf")
table_path <- verify_source("2025_BLF_UNIT_TAB_wham_par_tables.pdf")
peer_path <- verify_source("2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf")
for (name in setdiff(manifest$file, c(
  "2025_BLF_UNIT_RPT_Atlantic_Bluefish_Update_2025_06_10_082854.125567.pdf",
  "2025_BLF_UNIT_FIG_input_data.pdf",
  "2025_BLF_UNIT_TAB_wham_par_tables.pdf",
  "2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf"
))) invisible(verify_source(name))

report_pages <- pdftools::pdf_text(report_path)
input_pages <- pdftools::pdf_text(input_path)
table_pages <- pdftools::pdf_text(table_path)
peer_pages <- pdftools::pdf_text(peer_path)
peer_text <- gsub("[[:space:]]+", " ", paste(peer_pages, collapse = " "))
if (!any(grepl("Catch and status table for Atlantic Bluefish", report_pages, fixed = TRUE)) ||
    length(input_pages) != 25L || length(table_pages) != 12L ||
    !grepl("2025 Management Track Assessment for Atlantic Bluefish met all the Terms of Reference",
      peer_text, fixed = TRUE)) stop("Cached files do not match the reviewed assessment.", call. = FALSE)

number_tokens <- function(line) {
  suppressWarnings(as.numeric(gsub(",", "", strsplit(trimws(line),
    "[[:space:]]+")[[1L]], fixed = TRUE)))
}
parse_age_table <- function(title, next_title = NULL) {
  text <- paste(table_pages, collapse = "\n")
  match <- regexpr(title, text, fixed = TRUE)
  if (match[1L] < 1L) stop("Missing table: ", title, call. = FALSE)
  after <- match[1L] + attr(match, "match.length")
  end <- if (is.null(next_title)) nchar(text) + 1L else {
    next_match <- regexpr(next_title, substring(text, after), fixed = TRUE)
    if (next_match[1L] < 1L) stop("Missing next table after ", title, call. = FALSE)
    after + next_match[1L] - 1L
  }
  lines <- strsplit(substring(text, match[1L], end - 1L), "\n", fixed = TRUE)[[1L]]
  lines <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines)]
  rows <- lapply(lines, function(line) {
    x <- number_tokens(line)
    if (length(x) != 8L || any(!is.finite(x))) stop("Unexpected source row: ", trimws(line), call. = FALSE)
    x
  })
  x <- as.data.frame(do.call(rbind, rows))
  names(x) <- c("year", paste0("age", 0:5), "age6plus")
  x$year <- as.integer(x$year)
  if (!identical(x$year, 1985:2024)) stop("Unexpected year coverage in ", title, call. = FALSE)
  x
}
n_age <- parse_age_table("Table 2. Abundance at age", "Table 3. Total fishing mortality")
f_total <- parse_age_table("Table 3. Total fishing mortality at age in region 1",
  "Table 4. Total fishing mortality at age in Comm.")
f_comm <- parse_age_table("Table 4. Total fishing mortality at age in Comm.",
  "Table 5. Total fishing mortality at age in Rec.")
f_rec <- parse_age_table("Table 5. Total fishing mortality at age in Rec.")

summary_lines <- unlist(strsplit(report_pages[[2L]], "\n", fixed = TRUE), use.names = FALSE)
parse_summary <- function(label, pattern = NULL) {
  if (is.null(pattern)) pattern <- paste0("^[[:space:]]*", label, "[[:space:]]+")
  line <- summary_lines[grepl(pattern, summary_lines, perl = TRUE)]
  if (length(line) != 1L) stop("Missing summary row: ", label, call. = FALSE)
  line <- sub(pattern, "", line, perl = TRUE)
  x <- number_tokens(line)
  if (length(x) != 10L || any(!is.finite(x))) stop("Unexpected summary values: ", label, call. = FALSE)
  x
}
summary <- list(
  rec_landings = parse_summary("Recreational landings"),
  rec_discards = parse_summary("Recreational discards"),
  comm_landings = parse_summary("Commercial landings"),
  comm_discards = parse_summary("Commercial discards"),
  catch_total = parse_summary("Catch for Assessment"),
  ssb = parse_summary("Spawning Stock Biomass"),
  ffull = parse_summary("Ffull"),
  recruitment = parse_summary("Recruits (age 0)", "^[[:space:]]*Recruits[[:space:]]*\\(age 0\\)[[:space:]]+")
)
summary_years <- 2015:2024
if (any(abs(summary$rec_landings + summary$rec_discards + summary$comm_landings +
    summary$comm_discards - summary$catch_total) > 1) ||
    any(abs(n_age[n_age$year %in% summary_years, "age0"] - summary$recruitment) > 1e-8)) {
  stop("Table 1 catch components or recruitment do not reconcile with source tables.", call. = FALSE)
}

catch_reference <- paste0(basename(report_path), ", Table 1, PDF p. 2")
catch_series <- list(
  "Recreational landings" = summary$rec_landings,
  "Recreational discards" = summary$rec_discards,
  "Commercial landings" = summary$comm_landings,
  "Commercial discards" = summary$comm_discards
)
input_rows <- do.call(rbind, lapply(names(catch_series), function(fleet_name) {
  pacific_database_row("inputs", n = 10L, assessment_id = assessment_id,
    type = "catch", measure = "catch_biomass", basis = "biomass",
    fleet = fleet_name, region = "Atlantic Coast", year = summary_years,
    year_basis = "calendar_year", value = catch_series[[fleet_name]],
    unit = "metric tonnes", source_type = "official_table",
    source_reference = catch_reference,
    notes = "Source-reported 2015-2024 catch component. The four components agree with the printed total within 1 tonne due to rounding. Not catch-at-age; numeric age-composition cells and sample sizes are unavailable in the bundle.")
}))
ages <- c(0:5, 6L)
age_groups <- c(rep(NA_character_, 6L), "6+")
make_age_output <- function(x, measure, type, unit, source_reference, fleet = NA_character_) {
  values <- cbind(as.matrix(x[paste0("age", 0:5)]), x$age6plus)
  n <- length(values)
  pacific_database_row("outputs", n = n, assessment_id = assessment_id,
    type = type, measure = measure, fleet = fleet, region = "Region 1",
    year = rep(x$year, each = length(ages)), age = rep(ages, times = nrow(x)),
    age_group = rep(age_groups, times = nrow(x)), value = as.vector(t(values)),
    unit = unit, source_type = "official_table", source_reference = source_reference,
    scenario = "Base-run estimate",
    notes = paste0("Age 6 is the 6+ group; annual age-specific uncertainty is not tabulated. Source: ", source_reference, "."))
}
outputs <- do.call(rbind, list(
  make_age_output(n_age, "numbers_at_age", "population", "1,000 fish",
    "2025_BLF_UNIT_TAB_wham_par_tables.pdf, Table 2, PDF pp. 7-8"),
  make_age_output(f_total, "fishing_mortality_at_age", "mortality", "year-1",
    "2025_BLF_UNIT_TAB_wham_par_tables.pdf, Table 3, PDF pp. 8-9"),
  make_age_output(f_comm, "fishing_mortality_at_age", "mortality", "year-1",
    "2025_BLF_UNIT_TAB_wham_par_tables.pdf, Table 4, PDF pp. 10-11", "Commercial"),
  make_age_output(f_rec, "fishing_mortality_at_age", "mortality", "year-1",
    "2025_BLF_UNIT_TAB_wham_par_tables.pdf, Table 5, PDF pp. 11-12", "Recreational"),
  pacific_database_row("outputs", n = 10L, assessment_id = assessment_id,
    type = "biomass", measure = "SSB", region = "Atlantic Coast",
    year = summary_years, value = summary$ssb, unit = "metric tonnes",
    source_type = "official_table", source_reference = catch_reference,
    scenario = "Base-run estimate",
    notes = "Source-reported 2015-2024 summary estimates; annual intervals are not tabulated."),
  pacific_database_row("outputs", n = 10L, assessment_id = assessment_id,
    type = "mortality", measure = "fully_selected_fishing_mortality",
    region = "Atlantic Coast", year = summary_years, value = summary$ffull,
    unit = "year-1", source_type = "official_table", source_reference = catch_reference,
    scenario = "Base-run estimate"),
  pacific_database_row("outputs", n = 10L, assessment_id = assessment_id,
    type = "recruitment", measure = "recruitment", region = "Atlantic Coast",
    year = summary_years, age = 0L, value = summary$recruitment,
    unit = "1,000 fish", source_type = "official_table",
    source_reference = catch_reference, scenario = "Base-run estimate",
    notes = "Age-0 recruitment; values reconcile with Table 2 age-0 abundance.")
))

assumption_rows <- do.call(rbind, list(
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "model",
    setting = "assessment_run", value = "2025 management-track update; WHAM; data through 2024",
    source_reference = "2025_BLF_UNIT_RPT_Atlantic_Bluefish_Update_2025_06_10_082854.125567.pdf, Table 1; 2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf",
    notes = "The panel concluded the assessment met its terms of reference and represented best scientific information available."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "model",
    setting = "age_groups", value = "0-5 and 6+", source_reference = "SASINF Tables 2-5",
    notes = "Single model region (Region 1)."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "catch",
    setting = "catch_components", value = "Commercial and recreational landings and discards",
    source_reference = catch_reference,
    notes = "Only the 2015-2024 summary values are numeric in the retrieved current-run report; component sums match the printed total within 1 tonne due to rounding; full catch-at-age is unavailable."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "composition",
    setting = "age_compositions", value = "Fishery and age-sampled survey compositions shown in bubble plots",
    source_reference = "2025_BLF_UNIT_FIG_input_data.pdf, PDF pp. 2-12",
    notes = "Numeric composition cells and sample sizes are not provided; no plotted values were digitized."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "survey",
    setting = "abundance_indices", value = "Nine aggregate indices shown in rescaled plots",
    source_reference = "2025_BLF_UNIT_FIG_input_data.pdf, PDF p. 4",
    notes = "Numeric index values, scaling and exact sampling times are not available in the bundle."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "biology",
    setting = "weights_and_maturity", value = "Annual weight-at-age and maturity-at-age shown in figures",
    source_reference = "2025_BLF_UNIT_FIG_input_data.pdf, PDF pp. 13-25",
    notes = "Numeric current-run biological arrays are not tabulated and were not digitized."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "M",
    setting = "natural_mortality", value = "2022 research-track work describes age-varying Lorenzen weight-based M",
    source_reference = "2022 Bluefish Research Track WP 06; 2025 report projection description",
    notes = "The 2025 report uses five-year average M for projections but does not publish its current-run fitted M-at-age vector or model code."),
  pacific_database_row("assumptions", assessment_id = assessment_id, component = "outputs",
    setting = "reported_uncertainty", value = "No annual uncertainty for age-specific N/F or Table 1 SSB/recruitment",
    source_reference = "SASINF Tables 2-5 and 2025 report Table 1",
    notes = "Selected reference-point and projected SSB intervals are not annual fitted-series uncertainty.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id, authority = "NOAA-NEFSC",
  authority_stock_id = "10388", scientific_name = "Pomatomus saltatrix",
  common_name = "Atlantic bluefish", area = "U.S. Atlantic Coast",
  region = "Atlantic Coast", ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART assessment unit Bluefish - Atlantic Coast; one Atlantic Coast stock unit.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2025L, terminal_year = 2024L,
  estimate_terminal_year = 2024L, assessment_type = "management_track",
  model_family = "WHAM", model_version = "2025 management-track update",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = manifest$url[match("2025_BLF_UNIT.zip", manifest$file)],
  framework_url = manifest$url[match("2022_BLF_UNIT_1.zip", manifest$file)],
  data_url = manifest$url[match("2025_BLF_UNIT.zip", manifest$file)],
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Accepted 2025 update. Exact age-specific N/F tables and selected summary outputs are reported; numeric composition/index inputs, current-run biological arrays and a fitted WHAM object are unavailable.")

if (nrow(input_rows) != 40L || nrow(outputs) != 1150L || nrow(assumption_rows) != 8L ||
    any(!is.finite(input_rows$value)) || any(!is.finite(outputs$value))) {
  stop("Bluefish source rows failed dimensions or finite-value checks.", call. = FALSE)
}
cat("NOAA Atlantic bluefish 2025 source extraction\n")
cat("  inputs: ", nrow(input_rows), " catch-component rows (2015-2024)\n", sep = "")
cat("  assumptions: ", nrow(assumption_rows), "\n", sep = "")
cat("  outputs: ", nrow(outputs), "; age-specific N/F covers 1985-2024 and ages 0-5, 6+\n", sep = "")
cat("  numeric compositions, indices and current-run biology remain unavailable; status is partial.\n")

if (!write_mode) {
  cat("Dry run only. Add --write to import the verified source rows.\n")
} else {
  stocks <- read_csv("database/stocks.csv")
  assessments <- read_csv("database/assessments.csv")
  candidates <- read_csv("discovery/candidates.csv")
  i <- which(candidates$candidate_id == candidate_id)
  if (length(i) != 1L || candidates$import_status[i] != "not_started" ||
      candidates$match_status[i] != "new" || stock_id %in% stocks$stock_id ||
      assessment_id %in% assessments$assessment_id) {
    stop("NOAA Bluefish is not in the expected pre-import state.", call. = FALSE)
  }
  append_pacific_case(stock, assessment, assumption_rows, input_rows, outputs)
  candidates$matched_stock_id[i] <- stock_id
  candidates$match_status[i] <- "matched"
  candidates$import_status[i] <- "partial"
  candidates$review_date[i] <- "2026-11-10"
  candidates$catch_age_evidence[i] <- "Imported Table 1 commercial/recreational landings and discards for 2015-2024. Full catch-at-age is unavailable; numeric age-composition values and sample sizes are not in the 2025 bundle."
  candidates$survey_age_evidence[i] <- "The input report plots age compositions and rescaled indices; numeric index observations, age-composition cells and sampling times are unavailable."
  candidates$weights_evidence[i] <- "Annual stock-, fleet- and survey-specific weight-at-age is plotted but not tabulated; no values were digitized."
  candidates$maturity_evidence[i] <- "Maturity-at-age is plotted but no numeric current-run vector is supplied."
  candidates$mortality_evidence[i] <- "2022 research-track work documents age-varying Lorenzen M; the exact 2025 fitted M-at-age vector is unavailable."
  candidates$output_evidence[i] <- "Imported exact 1985-2024 N-at-age, total and fleet F-at-age from Tables 2-5, plus 2015-2024 SSB, fully selected F and age-0 recruitment from Table 1; annual uncertainty is not tabulated."
  candidates$decision_reason[i] <- "Partial import completed from the accepted 2025 assessment. Numeric outputs and recent catch summaries are available; numeric current-run composition/index inputs and biological arrays remain unavailable."
  candidates$notes[i] <- paste(candidates$notes[i],
    "Source import preserved only published numeric rows; plotted inputs were not digitized, catch-at-age was not reconstructed, and 2022 inputs were not substituted for the 2025 run.")
  replace_candidate_register_row("discovery/candidates.csv", i,
    candidates[i, , drop = FALSE], candidate_id)
  inventory <- read_csv("discovery/inventory_units.csv")
  inventory_index <- candidate_inventory_row(inventory, candidate_id, stock_id)
  if (inventory$import_status[inventory_index] != "not_started") {
    stop("NOAA Bluefish inventory status changed before import completion.", call. = FALSE)
  }
  inventory$unit_key[inventory_index] <- paste0("stock:", stock_id)
  inventory$matched_stock_id[inventory_index] <- stock_id
  inventory$candidate_unit_id[inventory_index] <- ""
  inventory$match_status[inventory_index] <- "matched"
  inventory$import_status[inventory_index] <- "partial"
  inventory <- inventory[order(inventory$unit_key), , drop = FALSE]
  write.csv(inventory, "discovery/inventory_units.csv", row.names = FALSE, na = "")
  cat("Imported partial NOAA Atlantic bluefish 2025 source data.\n")
}
