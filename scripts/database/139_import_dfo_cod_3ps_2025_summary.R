# Import available 2025 3Ps cod inputs and published summary outputs.
# Run from the SAIO repository root after caching the official DFO reports.

root <- "."
db <- file.path(root, "database")
source_dir <- file.path(root, "source_cache", "ck_dfo_morhua_3ps")
summary_file <- file.path(source_dir, "assessment_2025", "Fs70-6-2026-004-eng.pdf")
inputs_file <- file.path(source_dir, "assessment_2024", "Fs70-5-2026-047-eng.pdf")
assessment_id <- "dfo_cod_3ps_2025"
assessment_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41315832.pdf"
data_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-047-eng.pdf"
summary_reference <- paste0("DFO Science Advisory Report 2026/004, Table 1; ", assessment_url)
input_reference <- paste0("DFO Research Document 2026/047, Tables 6-7; ", data_url)
abort <- function(...) stop(paste0(...), call. = FALSE)

check_pdf <- function(path) {
  if (!file.exists(path)) abort("A cached source report is missing: ", path)
  con <- file(path, open = "rb")
  signature <- rawToChar(readBin(con, what = "raw", n = 5L))
  close(con)
  if (!identical(signature, "%PDF-")) abort("A cached assessment source is not a PDF: ", path)
}
check_pdf(summary_file)
check_pdf(inputs_file)

assessments_path <- file.path(db, "assessments.csv")
assumptions_path <- file.path(db, "assumptions.csv")
inputs_path <- file.path(db, "inputs.csv")
outputs_path <- file.path(db, "outputs.csv")
assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, check.names = FALSE)
if (assessment_id %in% assessments$assessment_id) abort(assessment_id, " is already in assessments.csv.")
if (!any(assessments$assessment_id == "dfo_cod_3ps_2024" & assessments$is_current)) {
  abort("The 2024 detailed 3Ps assessment must remain the current detailed record.")
}
for (path in c(assumptions_path, inputs_path, outputs_path)) {
  existing <- readLines(path, warn = FALSE)
  if (any(grepl(paste0('^"', assessment_id, '"'), existing))) {
    abort(assessment_id, " already has rows in ", basename(path), ".")
  }
}

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = "ck_dfo_morhua_3ps",
  assessment_year = "2025",
  terminal_year = "2025",
  estimate_terminal_year = "2026",
  assessment_type = "annual",
  model_family = "HYBRID",
  model_version = "HYBRID under the 2019 framework; complementary SAM fit examined",
  is_current = "FALSE",
  is_applied = "TRUE",
  framework_year = "2019",
  assessment_url = assessment_url,
  framework_url = "https://waves-vagues.dfo-mpo.gc.ca/Library/4105829x.pdf",
  data_url = data_url,
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "Newer annual assessment, but the complete annual input matrices, model controls, and numerical age-specific fitted surfaces were not recovered. Its partial recent catch-at-age inputs and aggregate outputs are stored separately; the 2024 record remains the current detailed assessment.",
  stringsAsFactors = FALSE
)

assumption_row <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "", survey = "",
    sex = "", region = "", season = "", setting = setting, value = value,
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE
  )
}
assumptions <- rbind(
  assumption_row("population", "assessment_model", "State-space age-based HYBRID; SAM also examined as a consistency check", "DFO Science Advisory Report 2026/004, p. 2"),
  assumption_row("biology", "stock_weight_revision", "Stock weights revised to include both inshore and offshore strata; estimates changed from the early 1990s and reduced estimated size-at-age and SSB", "DFO Science Advisory Report 2026/004, p. 4"),
  assumption_row("catch", "catch_at_age_2023_revision", "2023 catch-at-age re-estimated after a correction in how catches were summed", "DFO Science Advisory Report 2026/004, p. 4"),
  assumption_row("index", "sentinel_standardization", "Sentinel index standardization expanded to include additional data", "DFO Science Advisory Report 2026/004, p. 4"),
  assumption_row("M", "condition_index", "Cod condition informs time-varying natural mortality", "DFO Science Advisory Report 2026/004, p. 2")
)

catch_ages <- 1:20
catch_2023 <- c(0, 1007, 20802, 34838, 60096, 76027, 89983, 59970, 20642, 15235,
  6596, 10199, 2653, 1, 229, 784, 235, 0, 0, 0)
catch_2024 <- c(0, 122, 7812, 26368, 42793, 52668, 60166, 52489, 26818, 20350,
  12547, 5062, 3389, 1733, 300, 59, 0, 0, 0, 0)

catch_rows <- function(year, values, table_name) {
  data.frame(
    assessment_id = assessment_id,
    type = "catch",
    measure = "numbers_at_age",
    basis = "numbers",
    fleet = "Commercial fishery",
    survey = "",
    sex = "",
    region = "",
    season = "",
    year = as.character(year),
    year_basis = "calendar_year",
    age = as.character(catch_ages),
    value = as.character(values),
    unit = "fish",
    sampling_time = "",
    source_type = "official_table",
    source_reference = paste0("DFO Research Document 2026/047, Table ", table_name, "; ", data_url),
    transformation = "None; source table reports total catch numbers at exact ages 1-20.",
    notes = "Canadian and French landings; recreational catch excluded. The 2023 series is the corrected estimate.",
    observation_id = "",
    length_bin = "",
    length_bin_lower = "",
    length_bin_upper = "",
    sample_size = "",
    age_error = "",
    partition = "",
    stringsAsFactors = FALSE
  )
}
inputs <- rbind(catch_rows(2023, catch_2023, 6), catch_rows(2024, catch_2024, 7))

output_row <- function(type, measure, year, value, unit, age = "", age_group = "",
                       lwr = "", upr = "", notes = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = as.character(year), age = as.character(age), age_group = age_group,
    value = as.character(value), se = "", lwr = as.character(lwr),
    upr = as.character(upr), unit = unit, source_type = "official_table",
    source_reference = summary_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

ssb_years <- 2021:2025
ssb <- c(20.7, 20.2, 19.4, 19.3, 22.0)
ssb_lwr <- c(17.5, 17.2, 16.4, 16.3, 17.5)
ssb_upr <- c(24.5, 23.8, 22.9, 22.9, 27.5)
recruitment <- c(17.9, 29.3, 30.0, 30.5, 29.7)
recruitment_lwr <- c(11.4, 18.1, 17.4, 15.2, 12.2)
recruitment_upr <- c(28.3, 47.4, 51.5, 61.2, 71.9)
mbar <- c(0.35, 0.35, 0.35, 0.33, 0.31)
fbar <- c(0.02, 0.03, 0.03, 0.02, 0.03)

outputs <- do.call(rbind, c(
  lapply(seq_along(ssb_years), function(i) output_row(
    "biomass", "SSB", ssb_years[i], ssb[i], "kt",
    lwr = ssb_lwr[i], upr = ssb_upr[i],
    notes = "Annual HYBRID median and 95% CI; source reports 000 tonnes, equivalent to kt."
  )),
  list(output_row(
    "biomass", "SSB", 2026, 26.7, "kt", lwr = 20.7, upr = 34.3,
    notes = "Projected 2026 SSB (not a fitted terminal-year estimate); based on current selectivity and an assumed 2025 catch of 1.251 kt."
  )),
  lapply(seq_along(ssb_years), function(i) output_row(
    "population", "recruitment", ssb_years[i], recruitment[i], "million fish",
    age = 2, lwr = recruitment_lwr[i], upr = recruitment_upr[i],
    notes = "Annual HYBRID median age-2 recruitment and 95% CI."
  )),
  lapply(seq_along(ssb_years), function(i) output_row(
    "mortality", "Mbar", ssb_years[i], mbar[i], "per year", age_group = "5-8",
    lwr = if (ssb_years[i] == 2025) 0.31 else "",
    upr = if (ssb_years[i] == 2025) 0.32 else "",
    notes = "Reported average M for ages 5-8; 2025 CI is given in the report text, earlier CIs are not tabulated."
  )),
  lapply(seq_along(ssb_years), function(i) output_row(
    "mortality", "Fbar", ssb_years[i], fbar[i], "per year", age_group = "5-8",
    notes = "Reported average F for ages 5-8; no uncertainty interval is reported in Table 1."
  ))
))

if (nrow(inputs) != 40L || nrow(outputs) != 21L ||
    anyDuplicated(inputs[c("assessment_id", "measure", "year", "age")]) ||
    anyDuplicated(outputs[c("assessment_id", "measure", "year")])) {
  abort("Unexpected input/output table size or duplicate rows.")
}

append_csv <- function(x, path) {
  info <- file.info(path)
  if (is.na(info$size)) abort("Cannot read existing database file: ", path)
  con <- file(path, open = "rb")
  seek(con, where = info$size - 1, origin = "start")
  last_byte <- readBin(con, what = "raw", n = 1L)
  close(con)
  if (length(last_byte) && !identical(last_byte, as.raw(10L))) cat("\n", file = path, append = TRUE)
  write.table(x, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, append = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8")
}

append_csv(assessment, assessments_path)
append_csv(assumptions, assumptions_path)
append_csv(inputs, inputs_path)
append_csv(outputs, outputs_path)

cat("Imported the 2025 3Ps assessment record, 40 recent catch-at-age input rows, and 21 aggregate output rows. Completeness statuses remain partial.\n")