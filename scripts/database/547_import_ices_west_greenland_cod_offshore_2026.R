root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_greenland_cod_2026")
assessment_id <- "ices_cod_west_greenland_offshore_2026"
stock_id <- "ices_cod_west_greenland_offshore"
candidate_id <- "ICES:cod.21.1.osc"
candidate_unit_id <- "ices_cod_west_greenland_offshore"
report_url <- "https://doi.org/10.17895/ices.pub.32414577"
report_ref <- paste0(
  "ICES NWWG 2026, chapter 13, Table 13.3.1, pp. 176-177; ",
  "cached file nwwg_2026_west_greenland_cod.pdf"
)
run_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NWWG26_WOSC_v1/run/model.RData"
)

if (!dir.exists(cache)) stop("The reviewed Greenland cod source cache is missing.", call. = FALSE)
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify SHA-256 for ", path, call. = FALSE)
  hashes
}

summary_file <- "west_offshore_summary_2026.csv"
summary_path <- file.path(cache, summary_file)
report_file <- "nwwg_2026_west_greenland_cod.pdf"
report_path <- file.path(cache, report_file)
if (!file.exists(summary_path) || !file.exists(report_path)) {
  stop("The cached assessment table or report chapter is missing.", call. = FALSE)
}

manifest_path <- file.path(cache, "sources.csv")
manifest <- utils::read.csv(
  manifest_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
report_row <- match(report_file, manifest$file)
if (is.na(report_row) ||
    as.numeric(manifest$bytes[report_row]) != file.info(report_path)$size ||
    tolower(manifest$sha256[report_row]) != sha256_file(report_path)) {
  stop("The WOSC report chapter does not match its source manifest.", call. = FALSE)
}
summary_row <- data.frame(
  file = summary_file,
  url = report_url,
  retrieved_on = "2026-11-03",
  bytes = file.info(summary_path)$size,
  sha256 = sha256_file(summary_path),
  stringsAsFactors = FALSE
)
summary_manifest_row <- match(summary_file, manifest$file)
if (is.na(summary_manifest_row)) {
  manifest <- rbind(manifest, summary_row)
} else if (
  as.numeric(manifest$bytes[summary_manifest_row]) != as.numeric(summary_row$bytes) ||
    tolower(manifest$sha256[summary_manifest_row]) != tolower(summary_row$sha256)
) {
  stop("The transcribed WOSC table changed after it was recorded.", call. = FALSE)
}
manifest_tmp <- tempfile(fileext = ".csv", tmpdir = cache)
utils::write.csv(manifest, manifest_tmp, row.names = FALSE, na = "")
if (!file.copy(manifest_tmp, manifest_path, overwrite = TRUE)) {
  stop("Could not update the local source manifest.", call. = FALSE)
}
unlink(manifest_tmp)

source_table <- utils::read.csv(
  summary_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
if (!identical(as.integer(source_table$year), 2000:2025) ||
    nrow(source_table) != 26L ||
    sum(is.finite(source_table$total_catch)) != 25L ||
    any(source_table$recruitment_lwr > source_table$recruitment) ||
    any(source_table$recruitment > source_table$recruitment_upr) ||
    any(source_table$ssb_lwr > source_table$ssb) ||
    any(source_table$ssb > source_table$ssb_upr) ||
    any(source_table$fbar_lwr > source_table$fbar) ||
    any(source_table$fbar > source_table$fbar_upr)) {
  stop("The transcribed WOSC table failed coverage or interval checks.", call. = FALSE)
}
if (source_table$recruitment[source_table$year == 2025L] != 7554 ||
    source_table$ssb[source_table$year == 2025L] != 23227 ||
    source_table$fbar[source_table$year == 2025L] != 0.47 ||
    source_table$total_catch[source_table$year == 2025L] != 11215 ||
    is.finite(source_table$total_catch[source_table$year == 2001L])) {
  stop("The 2025 or unsampled 2001 values do not match Table 13.3.1.", call. = FALSE)
}

assessments_existing <- utils::read.csv(
  file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  check.names = FALSE
)
stocks_existing <- utils::read.csv(
  file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  check.names = FALSE
)

output_rows <- function(type, measure, value_column, unit,
                        lower_column = NULL, upper_column = NULL,
                        age = NA_integer_, age_group = "", notes = "") {
  value <- source_table[[value_column]]
  keep <- is.finite(value)
  lower <- if (is.null(lower_column)) rep(NA_real_, nrow(source_table)) else source_table[[lower_column]]
  upper <- if (is.null(upper_column)) rep(NA_real_, nrow(source_table)) else source_table[[upper_column]]
  pacific_database_row(
    "outputs", n = sum(keep),
    assessment_id = assessment_id,
    type = type, measure = measure,
    fleet = "", survey = "", sex = "",
    region = "WOSC (NAFO Divisions 1A-1F)", season = "",
    year = as.integer(source_table$year[keep]), age = age,
    age_group = age_group, value = value[keep],
    se = NA_real_, lwr = lower[keep], upr = upper[keep],
    unit = unit, source_type = "official_table",
    source_reference = report_ref, notes = notes
  )
}

outputs <- do.call(rbind, list(
  output_rows(
    "biomass", "SSB", "ssb", "tonnes", "ssb_lwr", "ssb_upr",
    notes = "Point estimate as reported; lower and upper values are 95% confidence limits. WOSC only."
  ),
  output_rows(
    "recruitment", "recruitment", "recruitment", "thousand fish",
    "recruitment_lwr", "recruitment_upr", age = 2L,
    notes = "Age-2 recruitment; point estimate as reported; lower and upper values are 95% confidence limits. WOSC only."
  ),
  output_rows(
    "mortality", "Fbar", "fbar", "per year", "fbar_lwr", "fbar_upr",
    age_group = "5-8",
    notes = "Mean fishing mortality for ages 5-8; point estimate as reported; lower and upper values are 95% confidence limits. WOSC only."
  ),
  output_rows(
    "catch", "total_catch", "total_catch", "tonnes",
    notes = "Reported total WOSC catch. The report has no catch value for 2001 because there were no commercial fishery samples; no value is imputed."
  )
))

assumption_rows <- function(component, setting, value, source_reference, notes = "", survey = "") {
  pacific_database_row(
    "assumptions",
    assessment_id = assessment_id, component = component,
    fleet = "", survey = survey, sex = "",
    region = "WOSC (NAFO Divisions 1A-1F)", season = "",
    setting = setting, value = value,
    source_reference = source_reference, notes = notes
  )
}
assumptions <- do.call(rbind, list(
  assumption_rows(
    "population", "model_years", "2000-2025",
    "ICES NWWG 2026, chapter 13, sections 13.1 and 13.3",
    "The historical assessment fit ends in 2025. The 2026 forecast values in Table 13.3.1 are not included as fitted outputs."
  ),
  assumption_rows(
    "population", "model_age_range", "unknown", report_ref,
    "The chapter does not give the full model age range; the run input files could not be retrieved."
  ),
  assumption_rows(
    "catch", "catch_at_age_construction", "Calculated yearly from commercial catch",
    "ICES NWWG 2026, chapter 13, section 13.2.1.3",
    "Numerical catch-at-age values are referenced to Buch et al. 2026b (NWWG 2026 WD05) and were not recovered."
  ),
  assumption_rows(
    "population", "genetic_stock_allocation", "Commercial and survey catches split by GAM using genetic samples",
    "ICES NWWG 2026, chapter 13, section 13.2.1.8",
    "The assessment uses stock-specific commercial and survey data after genetic stock allocation."
  ),
  assumption_rows(
    "survey", "gillnet_survey", "Combined WOSC CPUE index from NAFO Divisions 1B and 1D, 2002-2025",
    "ICES NWWG 2026, chapter 13, section 13.2.1.6",
    "The multimesh gillnet survey targets cod ages 2-3 and has operated since 1987. Numeric WOSC index values and model timing were not recovered.",
    survey = "West Greenland inshore multimesh gillnet survey"
  ),
  assumption_rows(
    "survey", "bottom_trawl_age_index", "Relative abundance indices at age estimated with a spatial INLA model",
    "ICES NWWG 2026, chapter 13, section 13.2.1.7",
    "The model uses Greenland Groundfish Survey G2064 (2005-2025) and German Groundfish Survey G4355 (2000-2020). Survey coverage is incomplete or absent in several years; the chapter does not give numerical index values or the exact fitted age range.",
    survey = "Greenland and German bottom-trawl surveys"
  ),
  assumption_rows(
    "catch_weight", "catch_weight_at_age_source", "Commercial catch",
    "ICES NWWG 2026, chapter 13, section 13.2.1.4",
    "Yearly catch mean weight-at-age values are referenced to Buch et al. 2026b and were not recovered."
  ),
  assumption_rows(
    "biology", "stock_weight_at_age_source", "Greenland bottom-trawl survey",
    "ICES NWWG 2026, chapter 13, section 13.2.1.4",
    "Numeric stock weight-at-age values were not recovered."
  ),
  assumption_rows(
    "biology", "maturity_at_age", "Fixed between years",
    "ICES NWWG 2026, chapter 13, section 13.2.1.5",
    "Numeric maturity-at-age values are referenced to Buch et al. 2026b and were not recovered."
  ),
  assumption_rows(
    "M", "natural_mortality", "Fixed M = 0.2 per year for all ages",
    "ICES NWWG 2026, chapter 13, Table 13.7.1, p. 178",
    "M is fixed, not estimated; no age-specific M output is reported."
  ),
  assumption_rows(
    "survey", "sampling_time_fraction_year", "unknown",
    "ICES NWWG 2026, chapter 13, sections 13.2.1.6-13.2.1.7",
    "The report describes summer-autumn surveys and dates but not the fractional-year timing used in SAM; no value is assigned."
  ),
  assumption_rows(
    "assessment_output", "confidence_intervals", "95% confidence intervals for SSB, age-2 recruitment, and Fbar ages 5-8",
    report_ref,
    "Table 13.3.1 identifies its low and high columns as 95% confidence intervals; no standard errors are reported."
  )
))

stock <- pacific_database_row(
  "stocks",
  stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "cod.21.1.osc",
  scientific_name = "Gadus morhua",
  common_name = "Atlantic cod (West Greenland offshore spawning)",
  area = "NAFO Subarea 1 (West Greenland offshore spawning cod)",
  region = "West Greenland offshore (WOSC)",
  ocean = "Northwest Atlantic",
  notes = paste(
    "The offshore spawning stock is a distinct West Greenland cod component from the inshore spawning stock.",
    "The 2026 report and imported outputs refer to WOSC in NAFO Divisions 1A-1F."
  )
)
assessment <- pacific_database_row(
  "assessments",
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2025L,
  assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "NWWG26_WOSC_v1 run reported in the 2026 NWWG assessment",
  is_current = TRUE, is_applied = TRUE, framework_year = 2023L,
  assessment_url = report_url,
  framework_url = "https://doi.org/10.17895/ices.pub.22683151",
  data_url = paste0(
    "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
    "NWWG26_WOSC_v1/data/"
  ),
  model_url = run_url, repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The 2026 NWWG report identifies NWWG26_WOSC_v1 and reports fitted years 2000-2025.",
    "Table 13.3.1 supplies historical summary outputs only; no numerical age-specific inputs were recovered.",
    "A fitfromweb retrieval of the named run failed because the host reset the connection.",
    "ICES SAG key 19562 is the distinct 2025 assessment and was not mixed into this 2026 record."
  )
)

replace_discovery_row <- function(path, row_index, row, key_column, key) {
  if (nrow(row) != 1L) stop("Expected one register row.", call. = FALSE)
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  existing <- utils::read.csv(
    path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE
  )
  if (!key_column %in% names(existing) || row_index < 1L || row_index > nrow(existing) ||
      !identical(as.character(existing[[key_column]][row_index]), key)) {
    stop("Register row identity does not match ", key, ".", call. = FALSE)
  }
  record_index <- as.integer(row_index) + 1L
  if (record_index > length(bounds$start)) stop("Register row index is out of range.", call. = FALSE)

  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
              quote = TRUE, na = "", qmethod = "double", eol = "\r\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  has_cr <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_cr <- TRUE
    next_byte <- next_byte + 1L
  }
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, if (has_cr) as.raw(13L), as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(utils::read.csv(
    path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
  ), error = function(e) NULL)
  valid <- !is.null(updated) && nrow(updated) == nrow(existing) &&
    sum(updated[[key_column]] == key, na.rm = TRUE) == 1L &&
    identical(as.character(updated[[key_column]][row_index]), key)
  if (!valid) {
    writeBin(original, path)
    stop("Updated register failed its row-count or key check.", call. = FALSE)
  }
  invisible(NULL)
}

stock_row_count <- sum(stocks_existing$stock_id == stock_id, na.rm = TRUE)
assessment_row_count <- sum(assessments_existing$assessment_id == assessment_id, na.rm = TRUE)
if (stock_row_count == 0L && assessment_row_count == 0L) {
  append_pacific_case(
    stock, assessment, assumptions,
    inputs = pacific_database_row("inputs", n = 0L), outputs = outputs
  )
} else {
  if (stock_row_count != 1L || assessment_row_count != 1L) {
    stop("The Greenland offshore cod stock or assessment is duplicated or only partly imported.", call. = FALSE)
  }
  inputs_existing <- utils::read.csv(file.path(database, "inputs.csv"), stringsAsFactors = FALSE)
  assumptions_existing <- utils::read.csv(file.path(database, "assumptions.csv"), stringsAsFactors = FALSE)
  outputs_existing <- utils::read.csv(file.path(database, "outputs.csv"), stringsAsFactors = FALSE)
  if (sum(inputs_existing$assessment_id == assessment_id, na.rm = TRUE) != 0L ||
      sum(assumptions_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(assumptions) ||
      sum(outputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(outputs)) {
    stop("Existing Greenland offshore cod rows do not match the verified import; refusing to append duplicates.", call. = FALSE)
  }
  stock_row <- which(stocks_existing$stock_id == stock_id)
  replace_discovery_row(file.path(database, "stocks.csv"), stock_row, stock, "stock_id", stock_id)
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(
  candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected one offshore cod candidate row.", call. = FALSE)
candidates$import_status[candidate_row] <- "partial"
candidates$catch_age_evidence[candidate_row] <- paste(
  "The 2026 report confirms annual catch-at-age calculated from commercial catches,",
  "but values and exact age coverage are in unrecovered NWWG WD05."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "The report describes age-specific INLA indices from Greenland and German bottom-trawl surveys,",
  "plus WOSC gillnet CPUE for 2002-2025; numeric arrays and timing were not recovered."
)
candidates$weights_evidence[candidate_row] <- paste(
  "Catch weights are calculated from commercial catches and stock weights from the Greenland bottom-trawl survey.",
  "Numeric age-specific values were not recovered."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "Maturity-at-age is fixed between years; numeric values were not recovered."
)
candidates$mortality_evidence[candidate_row] <- paste(
  "Natural mortality is fixed at 0.2 per year for all ages (Table 13.7.1)."
)
candidates$timing_evidence[candidate_row] <- paste(
  "The report identifies summer-autumn surveys but no fractional-year timing; none was inferred."
)
candidates$output_evidence[candidate_row] <- paste(
  "Table 13.3.1 reports age-2 recruitment, SSB, total catch, and Fbar ages 5-8 for 2000-2025.",
  "Recruitment, SSB, and Fbar include 95% intervals; catch is absent in 2001."
)
candidates$notes[candidate_row] <- paste(
  "The current 2026 cod.21.1.osc assessment is the distinct West Greenland offshore spawning stock.",
  "The named NWWG26_WOSC_v1 run is documented in the report; only historical summary outputs are imported.",
  "The older 2025 ICES SAG key 19562 was not mixed into the 2026 source record."
)
replace_candidate_register_row(candidate_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id)

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(
  inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
inventory_row <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
if (length(inventory_row) != 1L) stop("Expected one offshore cod inventory row.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"
replace_discovery_row(
  inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
  "unit_key", paste0("candidate:", candidate_unit_id)
)

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(
  selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("Expected one selected offshore cod row.", call. = FALSE)
selected$review_date[selected_row] <- "2026-11-03"
selected$curation_status[selected_row] <- "partial_source_import"
replace_discovery_row(
  selected_path, selected_row, selected[selected_row, , drop = FALSE],
  "candidate_id", candidate_id
)

cat(
  "Imported partial West Greenland offshore cod source records:",
  nrow(assumptions), "assumptions and", nrow(outputs),
  "outputs; no age-specific input arrays were recovered.\n"
)
