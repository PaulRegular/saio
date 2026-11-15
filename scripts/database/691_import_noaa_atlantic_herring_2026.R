root <- normalizePath(".", winslash = "/")
database <- Sys.getenv("SAIO_DATABASE_DIR", "database")
if (!grepl("^(?:[A-Za-z]:|/)", database)) database <- file.path(root, database)
database <- normalizePath(database, winslash = "/", mustWork = TRUE)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
stock_id <- "noaa_atlantic_herring_gom_georges_bank"
assessment_id <- paste0(stock_id, "_2026")
candidate_id <- "NOAA:10572"
zip_url <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=21&stock_id=6&review_type_id=6&filename=2026_HER_UNIT.zip"
run_report <- paste0(zip_url, "#archive/Atlantic_Herring_MT2026.pdf")
parameter_report <- paste0(zip_url, "#archive/wham_par_tables.pdf")
fixed_source <- paste0(zip_url, "#archive/FixedCAA_Proportions_Table.csv")
mobile_source <- paste0(zip_url, "#archive/MobileCAA_Proportions_Table.csv")
cache <- file.path(root, "source_cache/clupea_harengus/noaa_atlantic_herring_gom_georges_bank_2026")
provenance <- file.path(root, "provenance", assessment_id, "sources.csv")
manifest <- read.csv(provenance, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)

sha256 <- function(path) {
  stream <- file(path, "rb")
  on.exit(close(stream))
  tolower(unclass(as.character(openssl::sha256(stream))))
}
source_paths <- file.path(cache, manifest$file)
if (any(!file.exists(source_paths)) ||
    any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
    !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256, character(1)))) ||
    any(!manifest$file %in% c(
      "2026_HER_UNIT.zip", "archive/Atlantic_Herring_MT2026.pdf",
      "archive/wham_par_tables.pdf", "archive/FixedCAA_Proportions_Table.csv",
      "archive/MobileCAA_Proportions_Table.csv", "archive/All_inputdata.pdf",
      "archive/NEFSC 2025 Herring RT Report.pdf",
      "June_2026_Management_Track_Peer_Review.pdf", "ASMFC_Atlantic_Herring.html"
    ))) {
  stop("Cached NOAA herring sources do not match the reviewed provenance manifest.", call. = FALSE)
}

read_composition <- function(path, fleet) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  header <- grep("^Year,", lines)[1L]
  if (is.na(header)) stop("Could not find the age-composition header in ", path, call. = FALSE)
  x <- read.csv(path, skip = header - 1L, check.names = FALSE,
    stringsAsFactors = FALSE, na.strings = c("", "NA"))
  if (!identical(names(x), c("Year", as.character(1:8))) ||
      !identical(as.integer(x$Year), 1987:2025)) {
    stop("The ", fleet, " age-composition file differs from the reviewed 1987-2025 ages 1-8 table.", call. = FALSE)
  }
  values <- as.matrix(x[-1L])
  storage.mode(values) <- "double"
  if (any(!is.finite(values)) || any(values < 0) ||
      any(abs(rowSums(values) - 1) > 5e-8)) {
    stop("The ", fleet, " age proportions are invalid or do not sum to one.", call. = FALSE)
  }
  grid <- expand.grid(age = 1:8, year = as.integer(x$Year))
  list(fleet = fleet, grid = grid, value = as.vector(t(values)))
}

composition <- list(
  read_composition(file.path(cache, "archive/FixedCAA_Proportions_Table.csv"), "Fixed"),
  read_composition(file.path(cache, "archive/MobileCAA_Proportions_Table.csv"), "Mobile")
)
make_rows <- function(table, n, ...) {
  header <- readLines(file.path(database, paste0(table, ".csv")), n = 1L)
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  values <- list(...)
  unknown <- setdiff(names(values), columns)
  if (length(unknown)) stop("Unknown ", table, " column: ", paste(unknown, collapse = ", "), call. = FALSE)
  out <- as.data.frame(lapply(columns, function(x) rep(NA_character_, n)), check.names = FALSE)
  names(out) <- columns
  for (name in names(values)) out[[name]] <- rep_len(as.character(values[[name]]), n)
  out
}
stock_row <- make_rows("stocks", 1L,
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "NOAA-NEFSC",
  authority_stock_id = "10572", scientific_name = "Clupea harengus",
  common_name = "Atlantic herring", area = "U.S. Gulf of Maine and Georges Bank stock complex",
  region = "Gulf of Maine and Georges Bank", ocean = "Northwest Atlantic",
  notes = "The assessment includes Canadian catches. Keep distinct from the DFO 4VWX unit; no common assessment boundary is established.")
assessment_row <- make_rows("assessments", 1L,
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026L,
  terminal_year = 2025L, estimate_terminal_year = 2025L, assessment_type = "management track",
  model_family = "WHAM", model_version = "2026 Management Track",
  is_current = TRUE, is_applied = TRUE, framework_year = 2025L,
  assessment_url = run_report,
  framework_url = "https://doi.org/10.25923/7k68-hr32",
  data_url = zip_url, model_url = parameter_report,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "The 2026 Management Track WHAM run uses data through 2025 and was accepted at peer review as the best available assessment for advice. The public archive contains the report, two fleet age-composition series, and WHAM parameter/output tables. Numerical survey indices, full biological inputs, numerical M and fleet catch totals for the full model period were not recovered.")

input_parts <- lapply(composition, function(z) {
  n <- nrow(z$grid)
  make_rows("inputs", n,
    assessment_id = assessment_id, type = "catch", measure = "proportion_at_age",
    basis = "proportion_numbers", fleet = z$fleet,
    region = "Gulf of Maine and Georges Bank", year = z$grid$year,
    year_basis = "calendar_year", age = z$grid$age, value = z$value,
    unit = "proportion", source_type = "native_model", source_reference = if (z$fleet == "Fixed") fixed_source else mobile_source,
    notes = paste0("Run-specific WHAM input age proportions for the ", z$fleet,
      " fishery. The plus group is age 8+. The source CSV supplies proportions only; sample_size is left blank because no matching numeric effective sample size is provided in this file."),
    observation_id = paste(z$fleet, z$grid$year, sep = ":"))
})
inputs_new <- do.call(rbind, input_parts)

parameter_pdf <- file.path(cache, "archive/wham_par_tables.pdf")
parameter_pages <- pdftools::pdf_text(parameter_pdf)
parameter_lines <- trimws(unlist(strsplit(parameter_pages[2:5], "\\n")))
parameter_lines <- parameter_lines[grepl("\\S.{2,}\\S", parameter_lines)]
parse_parameter <- function(line) {
  fields <- strsplit(trimws(line), "[[:space:]]{2,}", perl = TRUE)[[1L]]
  if (length(fields) != 5L) return(NULL)
  clean_value <- function(x) {
    x <- gsub(intToUtf8(0x00D7), "", x, fixed = TRUE)
    x <- gsub(paste0("10", intToUtf8(0x2212)), "e-", x, fixed = TRUE)
    x <- gsub(" ", "", x, fixed = TRUE)
    if (grepl(paste0(intToUtf8(0x2013), "|", intToUtf8(0x2014)), x, perl = TRUE)) return(NA_real_)
    suppressWarnings(as.numeric(x))
  }
  values <- vapply(fields[2:5], clean_value, numeric(1L))
  if (is.na(values[1L]) || any(is.finite(values[c(2L, 3L, 4L)]) &
      values[c(2L, 3L, 4L)] < 0)) return(NULL)
  data.frame(label = fields[1L], estimate = values[1L], se = values[2L],
    lower = values[3L], upper = values[4L], stringsAsFactors = FALSE)
}
parameter_rows <- Filter(Negate(is.null), lapply(parameter_lines, parse_parameter))
parameters <- do.call(rbind, parameter_rows)
if (nrow(parameters) < 40L ||
    !all(c("stock 1 Mean Recruitment", "Shrimp fully selected q",
      "Acoust fully selected q") %in% parameters$label) ||
    !any(grepl("FallBig age comp", parameters$label))) {
  stop("Could not recover the reviewed WHAM parameter table from the source PDF.", call. = FALSE)
}
q_row <- grepl(" fully selected q$", parameters$label)
survey_names <- sub(" fully selected q$", "", parameters$label[q_row])
q_outputs <- make_rows("outputs", sum(q_row),
  assessment_id = assessment_id, type = "catchability", measure = "q",
  survey = survey_names, region = "Gulf of Maine and Georges Bank",
  value = parameters$estimate[q_row], se = parameters$se[q_row],
  lwr = parameters$lower[q_row], upr = parameters$upper[q_row],
  unit = "index multiplier", source_type = "official_document",
  source_reference = parameter_report,
  notes = paste0("Fully selected survey catchability as reported in WHAM Table 1 (95% confidence interval). Source label: ", survey_names, ". The numerical index scale is specific to the source series."))
other_parameters <- parameters[!q_row, , drop = FALSE]
parameter_outputs <- make_rows("outputs", nrow(other_parameters),
  assessment_id = assessment_id, type = "parameter", measure = other_parameters$label,
  value = other_parameters$estimate, se = other_parameters$se,
  lwr = other_parameters$lower, upr = other_parameters$upper,
  unit = ifelse(grepl("Mean Recruitment", other_parameters$label), "thousands of fish",
    ifelse(grepl("Selectivity", other_parameters$label), "proportion", "native parameter scale")),
  source_type = "official_document", source_reference = parameter_report,
  notes = "WHAM Table 1 parameter estimate. Reported standard error and 95% confidence bounds are retained when supplied; blank uncertainty fields are left blank as in the table.")

parse_wham_surface <- function(table_number, expected_name) {
  pages <- pdftools::pdf_text(file.path(cache, "archive/wham_par_tables.pdf"))
  lines <- trimws(unlist(strsplit(pages, "\\n")))
  headings <- grep("^Table [0-9]+\\.", lines)
  target <- headings[grepl(paste0("^Table ", table_number, "\\."), lines[headings])][1L]
  if (is.na(target)) stop("Missing WHAM Table ", table_number, ".", call. = FALSE)
  later <- headings[headings > target & !grepl(paste0("^Table ", table_number, "\\."), lines[headings])]
  end <- if (length(later)) later[1L] - 1L else length(lines)
  table_lines <- lines[seq.int(target, end)]
  rows <- table_lines[grepl("^[0-9]{4} +", table_lines)]
  values <- lapply(rows, function(line) suppressWarnings(as.numeric(strsplit(trimws(line), " +")[[1L]])))
  valid <- lengths(values) == 9L
  values <- values[valid]
  out <- do.call(rbind, values)
  if (is.null(out) || nrow(out) != 39L || !identical(as.integer(out[, 1L]), 1987:2025)) {
    stop("WHAM Table ", table_number, " did not yield one row for each year 1987-2025.", call. = FALSE)
  }
  colnames(out) <- c("year", as.character(1:8))
  out
}
N <- parse_wham_surface(2L, "Abundance at age")
F_total <- parse_wham_surface(3L, "Total fishing mortality at age in region 1")
F_mobile <- parse_wham_surface(4L, "Total fishing mortality at age in Mobile")
F_fixed <- parse_wham_surface(5L, "Total fishing mortality at age in Fixed")
if (any(!is.finite(N)) || any(N < 0) || any(!is.finite(F_total)) ||
    any(F_total < 0) || any(!is.finite(F_mobile)) || any(F_mobile < 0) ||
    any(!is.finite(F_fixed)) || any(F_fixed < 0) ||
    max(abs(F_total[, -1L] - F_mobile[, -1L] - F_fixed[, -1L])) > 0.002) {
  stop("WHAM N or F surfaces failed range or total-by-fleet checks.", call. = FALSE)
}

surface_outputs <- function(x, measure, unit, fleet = "", source_reference = parameter_report) {
  grid <- expand.grid(age = 1:8, year = as.integer(x[, 1L]))
  make_rows("outputs", nrow(grid), assessment_id = assessment_id,
    type = if (measure == "numbers_at_age") "population" else "mortality",
    measure = measure, fleet = fleet,
    region = "region 1", year = grid$year, age = grid$age,
    value = as.vector(t(x[, -1L])), unit = unit,
    source_type = "official_document", source_reference = source_reference,
    notes = if (measure == "numbers_at_age") "WHAM Table 2 abundance at age; values are rounded to the nearest thousand fish and the 8+ plus group is retained." else paste0("WHAM Table ", if (fleet == "") "3" else if (fleet == "Mobile") "4" else "5", " estimated instantaneous fishing mortality at age; values are rounded to 0.001 per year. The 8+ plus group is retained."))
}
N_outputs <- surface_outputs(N, "numbers_at_age", "thousands of fish")
F_outputs <- rbind(
  surface_outputs(F_total, "fishing_mortality_at_age", "per year"),
  surface_outputs(F_mobile, "fishing_mortality_at_age", "per year", "Mobile"),
  surface_outputs(F_fixed, "fishing_mortality_at_age", "per year", "Fixed")
)

summary_years <- 2018:2025
summary_table <- data.frame(
  year = summary_years,
  SSB = c(21075, 56484, 36912, 36983, 85973, 79843, 47877, 35258),
  F_mobile_7_8 = c(1.656, .400, .445, .199, .109, .222, .315, .121),
  recruitment = c(559391, 4457469, 2278256, 799145, 706515, 743734, 456155, 1966904)
)
if (!identical(as.numeric(N[match(summary_years, N[, 1L]), "1"]), summary_table$recruitment) ||
    any(abs(rowMeans(F_mobile[match(summary_years, F_mobile[, 1L]), c("7", "8")]) - summary_table$F_mobile_7_8) > 0.0011)) {
  stop("WHAM at-age outputs do not match the 2026 report's recruitment and mobile F summaries.", call. = FALSE)
}
summary_outputs <- rbind(
  make_rows("outputs", nrow(summary_table), assessment_id = assessment_id,
    type = "biomass", measure = "SSB", year = summary_table$year,
    value = summary_table$SSB, unit = "mt", source_type = "official_document",
    source_reference = run_report,
    notes = "Spawning stock biomass from Table 1 of the 2026 Management Track report. Annual 90% intervals are shown only as a figure and are not digitized."),
  make_rows("outputs", nrow(N), assessment_id = assessment_id,
    type = "recruitment", measure = "recruitment", year = as.integer(N[, 1L]),
    value = N[, "1"], unit = "thousands of fish", source_type = "derived_source_output",
    source_reference = parameter_report,
    notes = "Age-1 abundance from WHAM Table 2 is the recruitment definition used in Table 1. It is checked against report values for 2018-2025."),
  make_rows("outputs", nrow(F_mobile), assessment_id = assessment_id,
    type = "mortality", measure = "Fbar", fleet = "Mobile", age_group = "7-8",
    year = as.integer(F_mobile[, 1L]),
    value = rowMeans(F_mobile[, c("7", "8")]), unit = "per year",
    source_type = "derived_source_output", source_reference = parameter_report,
    notes = "Arithmetic mean of WHAM Table 4 Mobile F-at-age for ages 7 and 8. It reproduces the Table 1 Fbar 7-8 values to three-decimal rounding for 2018-2025.")
)
outputs_new <- rbind(N_outputs, F_outputs, summary_outputs, q_outputs, parameter_outputs)
assumptions_new <- make_rows("assumptions", 8L,
  assessment_id = assessment_id,
  component = c("population", "population", "catch", "catch", "survey", "survey", "biology", "natural_mortality"),
  fleet = c("", "", "Fixed", "Mobile", "", "", "", ""),
  survey = c("", "", "", "", "NEFSC bottom trawl, shrimp, and acoustic surveys", "All surveys", "All", "All"),
  region = "Gulf of Maine and Georges Bank",
  setting = c("model years", "age structure", "catch age composition", "catch age composition", "survey streams", "survey timing", "biology", "M structure"),
  value = c("1987-2025", "ages 1-8+; age 8 is the plus group", "proportions at age", "proportions at age",
    "four NEFSC trawl series, a shrimp survey and an acoustic series", "Exact within-year timing not recovered",
    "The report notes updated life-history inputs and corrected spawning-stock weights, but numerical age surfaces are unavailable in the archive.",
    "The report describes natural mortality as constant across ages and years; the numeric value was not recovered."),
  source_reference = c(parameter_report, parameter_report, fixed_source, mobile_source,
    run_report, run_report, run_report, run_report),
  notes = c("Model period represented in WHAM Tables 2-5.", "Source age labels 1-8+, retained without collapsing ages.",
    "The archive supplies proportions only; total catch numbers by fitted fleet were not recovered for the full time series.",
    "The archive supplies proportions only; total catch numbers by fitted fleet were not recovered for the full time series.",
    "Spring/fall bottom-trawl, summer shrimp, and acoustic observations are described; numeric series are absent.",
    "Unknown. No midpoint or assumed timing is substituted.",
    "Age-specific numerical weights and maturity are not supplied as data tables.",
    "Do not substitute a value from the separate 2025 Research Track."))

append_csv <- function(x, path) {
  write.table(x, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", qmethod = "double")
}
if (write_mode) {
  stocks_path <- file.path(database, "stocks.csv")
  assessments_path <- file.path(database, "assessments.csv")
  stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  if (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id)) {
    stop("The NOAA herring stock or assessment is already present; refusing to append it twice.", call. = FALSE)
  }
  append_csv(stock_row, stocks_path)
  append_csv(assessment_row, assessments_path)
  append_csv(assumptions_new, file.path(database, "assumptions.csv"))
  append_csv(inputs_new, file.path(database, "inputs.csv"))
  append_csv(outputs_new, file.path(database, "outputs.csv"))

  source(file.path(root, "scripts/discovery/candidate_register_io.R"), local = TRUE)
  candidates_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$screening_status[ci] != "screened") {
    stop("Expected one screened NOAA herring candidate.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$eligibility[ci] <- "unresolved"
  candidates$import_status[ci] <- "partial"
  candidates$catch_age_evidence[ci] <- "The official 2026 run archive provides fixed- and mobile-fleet catch proportions at ages 1-8+ for 1987-2025. Matching fleet catch totals by age or annual totals for the full period were not recovered."
  candidates$survey_age_evidence[ci] <- "The run archive describes four bottom-trawl, shrimp and acoustic surveys, but numerical survey-index and age-composition arrays remain unavailable."
  candidates$weights_evidence[ci] <- "Numeric spawning-stock and fleet weight-at-age arrays were not included in the 2026 archive."
  candidates$maturity_evidence[ci] <- "Numeric maturity-at-age is not included in the 2026 archive."
  candidates$mortality_evidence[ci] <- "The report describes natural mortality as constant by age and year, but the 2026 numeric value was not recovered."
  candidates$timing_evidence[ci] <- "Within-year survey timing was not recovered."
  candidates$output_evidence[ci] <- "WHAM parameter tables report annual N-at-age and total, Mobile and Fixed F-at-age for 1987-2025. The 2026 report gives SSB, recruitment and Mobile Fbar 7-8 for 2018-2025."
  candidates$decision_reason[ci] <- "A partial source import is supported by exact run-specific fleet catch proportions, annual N/F surfaces and selected reported summaries. Full age-data eligibility remains unresolved because total catch scaling, numeric survey series, weights, maturity, M value and timing are incomplete."
  candidates$notes[ci] <- paste(candidates$notes[ci], "Partial source data imported as noaa_atlantic_herring_gom_georges_bank_2026; the 2025 Research Track is not substituted for missing 2026 inputs.")
  replace_candidate_register_row(candidates_path, ci, candidates[ci, , drop = FALSE], candidate_id)

}

cat("Verified NOAA Atlantic herring 2026 source import.\n")
cat("Inputs:", nrow(inputs_new), "age-proportion rows, 1987-2025, Fixed and Mobile.\n")
cat("Outputs:", nrow(outputs_new), "including N/F-at-age, SSB, recruitment, Fbar and parameter estimates.\n")
cat("Eligibility remains unresolved because important source input families are missing.\n")
if (write_mode) cat("Import written to", database, "\n")
