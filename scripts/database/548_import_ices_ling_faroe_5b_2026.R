root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_ling_5b_2026")
candidate_id <- "ICES:lin.27.5b"
candidate_unit_id <- "ices_ling_faroe_5b"
stock_id <- candidate_unit_id
assessment_id <- "ices_ling_faroe_5b_2026"
report_url <- "https://doi.org/10.17895/ices.pub.32051352.v1"
framework_url <- "https://doi.org/10.17895/ices.pub.7920"
run_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "lin.27.5b_wgdeep2026_final/run/model.RData"
)
report_ref <- paste(
  "ICES WGDEEP 2026, section 3.2.14, tables 3.2.7-3.2.13;",
  "cached WGDEEP_2026_ling_5b_section.txt"
)

if (!dir.exists(cache)) stop("The reviewed Faroes ling source cache is missing.", call. = FALSE)
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

manifest <- utils::read.csv(
  file.path(cache, "sources.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
source_files <- c(
  WGDEEP_2026_v1.pdf = "4dece836b45b56c03a34d2ddf7ee1dd88eda7cdf2ba8d6717f86949888da89cd",
  WGDEEP_2026_ling_5b_section.txt = "f5f68201da8f1874c901e73ba591dec0cf6bca4fe4ac167c26a9d749f7cc0e89",
  WKBARFAR_2021_report.pdf = "94a98c08f64ca05ea6a5d3db32bba4d29a0cc2e863580619cefd8b181d3b7949",
  ICES_advice_7205.html = "dd4fc9f818ef445a311e196aa81e6a220efc2727fdf3f0ef89cdcca3b59b6187",
  ICES_standard_graphs_source_23735.html = "c00314737346f7ca637ccec1bc29375158e08c0544bddb5966b1758882bff6c1",
  ICES_SAG_23735.xml = "992bdf680900755292bf527f5615848947e7c8e71887d42590fdfb917073a5dc"
)
if (nrow(manifest) != length(source_files) ||
    anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(source_files))) {
  stop("The Faroes ling source manifest is incomplete.", call. = FALSE)
}
for (file in names(source_files)) {
  i <- match(file, manifest$file)
  path <- normalizePath(file.path(cache, manifest$local_path[i]),
    winslash = "/", mustWork = TRUE
  )
  if (manifest$retrieved_on[i] != "2026-10-31" ||
      as.numeric(manifest$bytes[i]) != file.info(path)$size ||
      tolower(manifest$sha256[i]) != source_files[[file]] ||
      sha256_file(path) != source_files[[file]]) {
    stop("Cached Faroes ling source differs from its manifest: ", file, call. = FALSE)
  }
}

report <- readLines(file.path(cache, "WGDEEP_2026_ling_5b_section.txt"), warn = FALSE)
parse_table <- function(start_title, end_title, columns, years = 1996:2025) {
  start <- which(startsWith(report, start_title))
  end <- which(startsWith(report, end_title))
  if (length(start) != 1L || length(end) != 1L || end <= start) {
    stop("Could not isolate report table ", start_title, call. = FALSE)
  }
  lines <- trimws(report[seq.int(start + 1L, end - 1L)])
  year <- suppressWarnings(as.integer(substr(lines, 1L, 4L)))
  lines <- lines[!is.na(year) & year %in% years]
  values <- lapply(lines, function(line) scan(text = line, what = numeric(), quiet = TRUE))
  parsed_years <- vapply(values, function(x) x[1L], numeric(1L))
  if (length(values) != length(years) ||
      any(lengths(values) != columns) ||
      !identical(parsed_years, as.numeric(years))) {
    stop("Unexpected row count, year coverage, or width in ", start_title, call. = FALSE)
  }
  do.call(rbind, values)
}

catch_table <- parse_table("Table 3.2.7.", "Table 3.2.8.", 11L)
weight_table <- parse_table("Table 3.2.8.", "Table 3.2.9.", 11L)
spring_table <- parse_table("Table 3.2.9.", "Table 3.2.10.", 10L, 1998:2025)
summer_table <- parse_table("Table 3.2.10.", "Table 3.2.11.", 11L)
aggregate_table <- parse_table("Table 3.2.11.", "Table 3.2.12.", 13L)
f_table <- parse_table("Table 3.2.12.", "Table 3.2.13.", 11L)
n_table <- parse_table("Table 3.2.13.", "Table 3.2.14.", 11L)
ages <- 3:12
age_long <- function(table, first_value_column, selected_ages) {
  values <- table[, first_value_column:ncol(table), drop = FALSE]
  data.frame(
    year = rep(as.integer(table[, 1L]), times = length(selected_ages)),
    age = rep(as.integer(selected_ages), each = nrow(table)),
    value = as.vector(values)
  )
}

catch_long <- age_long(catch_table, 2L, ages)
weight_long <- age_long(weight_table, 2L, ages)
f_long <- age_long(f_table, 2L, ages)
n_long <- age_long(n_table, 2L, ages)
spring_ages <- 4:11
summer_ages <- 3:11
spring_long <- age_long(spring_table, 3L, spring_ages)
summer_long <- age_long(summer_table, 3L, summer_ages)
maturity_values <- c(0, 0.04, 0.19, 0.50, 0.79, 0.93, 0.98, 1, 1, 1)

recruitment <- aggregate_table[, 2L]
ssb <- aggregate_table[, 5L]
fbar <- aggregate_table[, 8L]
total_biomass <- aggregate_table[, 11L]
computed_ssb <- rowSums(sweep(
  n_table[, -1L, drop = FALSE] * weight_table[, -1L, drop = FALSE],
  2L, maturity_values, "*"
))
computed_total_biomass <- rowSums(
  n_table[, -1L, drop = FALSE] * weight_table[, -1L, drop = FALSE]
)
computed_fbar <- rowMeans(f_table[, 5:9, drop = FALSE])
if (max(abs(100 * (computed_ssb - ssb) / ssb)) > 0.1 ||
    max(abs(100 * (computed_total_biomass - total_biomass) / total_biomass)) > 0.1 ||
    any(n_table[, 2L] != recruitment) ||
    max(abs(computed_fbar - fbar)) > 0.001) {
  stop("The age-specific tables do not reconcile with the reported aggregate outputs.", call. = FALSE)
}

age_input_rows <- function(long, type, measure, basis, unit, table, survey = "",
                           season = "", transformation = "", notes = "") {
  pacific_database_row(
    "inputs", n = nrow(long),
    assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = "", survey = survey, sex = "",
    region = "Faroes", season = season,
    year = long$year, year_basis = "calendar_year",
    age = long$age,
    value = long$value, unit = unit,
    sampling_time = NA_real_, source_type = "official_table",
    source_reference = paste("ICES WGDEEP 2026, section 3.2.14,", table),
    transformation = transformation, notes = notes
  )
}
effort_rows <- function(table, survey, season, table_number) {
  pacific_database_row(
    "inputs", n = nrow(table),
    assessment_id = assessment_id,
    type = "covariate", measure = "effort", basis = "native_covariate",
    fleet = "", survey = survey, sex = "",
    region = "Faroes", season = season,
    year = as.integer(table[, 1L]), year_basis = "calendar_year",
    age = NA_integer_, value = table[, 2L],
    unit = "Reported effort; unit and definition not specified",
    sampling_time = NA_real_, source_type = "official_table",
    source_reference = paste("ICES WGDEEP 2026, section 3.2.14,", table_number),
    transformation = "Transcribed as printed; not used as an age-specific abundance index.",
    notes = "The table gives an Effort column but does not define its unit or model role."
  )
}
constant_age_rows <- function(type, measure, basis, value, unit, source_reference,
                              transformation = "", notes = "") {
  pacific_database_row(
    "inputs", n = length(ages),
    assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = "", survey = "", sex = "",
    region = "Faroes", season = "",
    year = NA_integer_, year_basis = "",
    age = ages, value = rep(value, length(ages)),
    unit = unit, sampling_time = NA_real_, source_type = "official_table",
    source_reference = source_reference,
    transformation = transformation, notes = notes
  )
}
spring_survey <- "Faroe Plateau spring groundfish survey (G1264)"
summer_survey <- "Faroe Plateau summer groundfish survey (G3284)"
weight_unit_note <- paste(
  "The table does not state a unit. Interpreted as kg per fish because",
  "numbers-at-age in thousand fish multiplied by these weights reproduces",
  "the reported SSB and total biomass within 0.1% in every year; this is",
  "a source-based consistency inference, not a numeric rescaling."
)
index_rows <- function(long, survey, season, table_number) {
  age_input_rows(
    long, "index", "relative_abundance_index", "index_scale",
    "Source table index; unit and scale not specified", table_number,
    survey = survey, season = season,
    transformation = "Transcribed as printed; no scale adjustment or likelihood weight applied.",
    notes = "WGDEEP reports gear-change downweighting for specified years, but numeric weights were not published."
  )
}

inputs <- do.call(rbind, list(
  age_input_rows(
    catch_long, "catch", "numbers_at_age", "numbers", "thousand fish",
    "Table 3.2.7",
    transformation = "Transcribed as printed; age 12 is the reported 12+ group.",
    notes = "The report presents one combined catch-at-age series; fleet-specific rows are not published."
  ),
  age_input_rows(
    weight_long, "weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "Table 3.2.8",
    transformation = weight_unit_note,
    notes = "Catch-derived weights are used as stock weights, following the WKBARFAR 2021 benchmark decision."
  ),
  index_rows(spring_long, spring_survey, "spring", "Table 3.2.9"),
  effort_rows(spring_table, spring_survey, "spring", "Table 3.2.9"),
  index_rows(summer_long, summer_survey, "summer", "Table 3.2.10"),
  effort_rows(summer_table, summer_survey, "summer", "Table 3.2.10"),
  constant_age_rows(
    "maturity", "maturity_at_age", "proportion", maturity_values, "proportion",
    "ICES WGDEEP 2026, section 3.2.5.5",
    notes = "Fixed, time-invariant Faroese-survey maturity; sexes combined."
  ),
  constant_age_rows(
    "M", "natural_mortality_at_age", "per_year", 0.15, "per year",
    "ICES WGDEEP 2026, section 3.2.5.5",
    notes = "Natural mortality fixed at 0.15 for every modeled age and year."
  )
))

output_rows <- function(type, measure, value, year, unit,
                        lower = NA_real_, upper = NA_real_,
                        age = NA_integer_, age_group = "", notes = "") {
  pacific_database_row(
    "outputs", n = length(value),
    assessment_id = assessment_id,
    type = type, measure = measure,
    fleet = "", survey = "", sex = "",
    region = "Faroes", season = "",
    year = as.integer(year), age = age, age_group = age_group,
    value = value, se = NA_real_, lwr = lower, upr = upper,
    unit = unit, source_type = "official_table",
    source_reference = report_ref, notes = notes
  )
}
output_years <- as.integer(aggregate_table[, 1L])
outputs <- do.call(rbind, list(
  output_rows(
    "recruitment", "recruitment", aggregate_table[, 2L], output_years,
    "thousand fish", aggregate_table[, 3L], aggregate_table[, 4L], age = 3L,
    notes = "Recruitment at age 3; limits are the published 95% confidence interval."
  ),
  output_rows(
    "biomass", "SSB", aggregate_table[, 5L], output_years,
    "tonnes", aggregate_table[, 6L], aggregate_table[, 7L],
    notes = "Limits are the published 95% confidence interval."
  ),
  output_rows(
    "mortality", "Fbar", aggregate_table[, 8L], output_years,
    "per year", aggregate_table[, 9L], aggregate_table[, 10L],
    age_group = "6-10",
    notes = "Arithmetic mean over ages 6-10; limits are the published 95% confidence interval."
  ),
  output_rows(
    "biomass", "total_biomass", aggregate_table[, 11L], output_years,
    "tonnes", aggregate_table[, 12L], aggregate_table[, 13L],
    notes = "Total stock biomass; limits are the published 95% confidence interval."
  ),
  output_rows(
    "mortality", "fishing_mortality_at_age", f_long$value, f_long$year,
    "per year", age = f_long$age,
    age_group = ifelse(f_long$age == 12L, "12+", ""),
    notes = "Point estimates only; age 12 corresponds to the modeled 12+ group."
  ),
  output_rows(
    "population", "numbers_at_age", n_long$value, n_long$year,
    "thousand fish", age = n_long$age,
    age_group = ifelse(n_long$age == 12L, "12+", ""),
    notes = "Point estimates only; age 12 corresponds to the modeled 12+ group."
  )
))

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                            survey = "") {
  pacific_database_row(
    "assumptions",
    assessment_id = assessment_id, component = component,
    fleet = "", survey = survey, sex = "",
    region = "Faroes", season = "",
    setting = setting, value = value,
    source_reference = source_reference, notes = notes
  )
}
assumptions <- do.call(rbind, list(
  assumption_rows(
    "population", "model_years", "1996-2025",
    "ICES WGDEEP 2026, section 3.2.14, Tables 3.2.7-3.2.13"
  ),
  assumption_rows(
    "population", "model_age_range", "3-12+",
    "ICES WGDEEP 2026, section 3.2.14, Tables 3.2.7-3.2.13",
    "The plus group is stored at age 12 with age_group 12+."
  ),
  assumption_rows(
    "recruitment", "recruitment_age", "3",
    "ICES WGDEEP 2026, Table 3.2.11",
    "Reported age-3 recruitment matches the age-3 stock-number estimate in Table 3.2.13."
  ),
  assumption_rows(
    "catch", "catch_at_age_source", "Combined commercial catch-at-age",
    "ICES WGDEEP 2026, section 3.2.5.3 and Table 3.2.7",
    "The assessment table provides one series and does not publish separate fleet rows."
  ),
  assumption_rows(
    "biology", "stock_weight_at_age", "Catch weights-at-age",
    framework_url,
    "WKBARFAR 2021 selected catch weights over spring-survey weights for stock weights; the 2026 table values reproduce SSB and total biomass within 0.1% when interpreted as kg per fish."
  ),
  assumption_rows(
    "biology", "weight_unit", "kg per fish, inferred from source consistency",
    "ICES WGDEEP 2026, Tables 3.2.8, 3.2.11, and 3.2.13",
    weight_unit_note
  ),
  assumption_rows(
    "biology", "maturity_at_age",
    "Fixed: 0, 0.04, 0.19, 0.50, 0.79, 0.93, 0.98, 1, 1, 1",
    "ICES WGDEEP 2026, section 3.2.5.5",
    "Faroese-survey maturity proportions for ages 3-12+; sexes combined."
  ),
  assumption_rows(
    "M", "natural_mortality", "Fixed M = 0.15 per year",
    "ICES WGDEEP 2026, section 3.2.5.5",
    "Applied to every modeled age and year."
  ),
  assumption_rows(
    "survey", "age_index", "Spring survey, ages 4-11, 1998-2025",
    "ICES WGDEEP 2026, section 3.2.5.6 and Table 3.2.9",
    "G1264; table values and effort are imported as reported. Index scale and effort units are not specified.",
    survey = spring_survey
  ),
  assumption_rows(
    "survey", "age_index", "Summer survey, ages 3-11, 1996-2025",
    "ICES WGDEEP 2026, section 3.2.5.6 and Table 3.2.10",
    "G3284; table values and effort are imported as reported. Index scale and effort units are not specified.",
    survey = summer_survey
  ),
  assumption_rows(
    "survey", "gear_change_downweighting", "Summer 2021-2023; spring 2022-2024",
    "ICES WGDEEP 2026, section 3.2.5.6",
    "The report says these periods were downweighted for the rockhopper-gear change; numeric weights and implementation are unavailable, so none are added to inputs.",
    survey = "Faroe Plateau groundfish surveys"
  ),
  assumption_rows(
    "survey", "sampling_time_fraction_year", "unknown",
    "ICES WGDEEP 2026, section 3.2.5.6",
    "The report gives spring February/March and summer August but not the fractions used in SAM; input sampling_time is left blank.",
    survey = "Faroe Plateau groundfish surveys"
  ),
  assumption_rows(
    "assessment_output", "confidence_intervals",
    "95% confidence intervals for recruitment, SSB, Fbar, and total biomass",
    "ICES WGDEEP 2026, Tables 3.2.11-3.2.13",
    "Age-specific N and F are published as point estimates without age-specific intervals."
  )
))

stock <- pacific_database_row(
  "stocks",
  stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "lin.27.5b",
  scientific_name = "Molva molva",
  common_name = "Ling - Faroes",
  area = "ICES Division 5.b (Faroese grounds)",
  region = "Faroes",
  ocean = "Northeast Atlantic",
  notes = "A distinct management unit from ling in Division 5.a (Iceland grounds)."
)
assessment <- pacific_database_row(
  "assessments",
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2025L,
  assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "lin.27.5b_wgdeep2026_final",
  is_current = TRUE, is_applied = TRUE, framework_year = 2021L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = sub("/run/model.RData$", "/data/", run_url),
  model_url = run_url, repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The 2026 WGDEEP report identifies the final applied SAM run and reports fitted years 1996-2025.",
    "Published input tables and outputs are imported; exact survey index scale, effort definition,",
    "survey timing, numeric downweighting factors, and the native fitted object remain unavailable."
  )
)

replace_discovery_row <- function(path, row_index, row, key_column, key) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  existing <- utils::read.csv(
    path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE
  )
  if (!key_column %in% names(existing) ||
      !identical(as.character(existing[[key_column]][row_index]), key)) {
    stop("Register row identity does not match ", key, ".", call. = FALSE)
  }
  record <- as.integer(row_index) + 1L
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L))
    replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L))
    replacement <- replacement[-length(replacement)]
  first <- bounds$start[record]
  last <- bounds$end[record]
  next_byte <- last + 1L
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) next_byte <- next_byte + 1L
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, bytes[(last + 1L):next_byte])
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(utils::read.csv(
    path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
  ), error = function(e) NULL)
  if (is.null(updated) || nrow(updated) != nrow(existing) ||
      sum(updated[[key_column]] == key, na.rm = TRUE) != 1L ||
      !identical(as.character(updated[[key_column]][row_index]), key)) {
    writeBin(original, path)
    stop("Register update failed its row-count or identity check.", call. = FALSE)
  }
}

stocks_existing <- utils::read.csv(file.path(database, "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- utils::read.csv(file.path(database, "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
if (sum(stocks_existing$stock_id == stock_id, na.rm = TRUE) == 0L &&
    sum(assessments_existing$assessment_id == assessment_id, na.rm = TRUE) == 0L) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
} else {
  if (sum(stocks_existing$stock_id == stock_id, na.rm = TRUE) != 1L ||
      sum(assessments_existing$assessment_id == assessment_id, na.rm = TRUE) != 1L) {
    stop("The Faroes ling stock or assessment is duplicated or only partly imported.", call. = FALSE)
  }
  inputs_existing <- utils::read.csv(file.path(database, "inputs.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  assumptions_existing <- utils::read.csv(file.path(database, "assumptions.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  outputs_existing <- utils::read.csv(file.path(database, "outputs.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  if (sum(inputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(inputs) ||
      sum(assumptions_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(assumptions) ||
      sum(outputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(outputs)) {
    stop("Existing Faroes ling rows differ from the verified source import.", call. = FALSE)
  }
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(
  candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE
)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected one Faroes ling candidate row.", call. = FALSE)
candidates$import_status[candidate_row] <- "partial"
candidates$catch_age_evidence[candidate_row] <- paste(
  "WGDEEP 2026 Table 3.2.7 supplies catch numbers-at-age for ages 3-12+ in 1996-2025,",
  "in thousands of fish. The table provides one combined series."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Tables 3.2.9-3.2.10 supply spring indices for ages 4-11 (1998-2025) and summer indices",
  "for ages 3-11 (1996-2025), plus effort columns. Index scale, effort definition, timing,",
  "and numeric gear-change downweights remain unresolved."
)
candidates$weights_evidence[candidate_row] <- paste(
  "Table 3.2.8 supplies catch-derived weights-at-age for ages 3-12+ in 1996-2025.",
  "The table omits units; interpreting values as kg per fish reproduces reported SSB and total biomass within 0.1%."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "The report supplies fixed Faroese-survey maturity proportions at ages 3-12+:",
  "0, 0.04, 0.19, 0.50, 0.79, 0.93, 0.98, 1, 1, 1."
)
candidates$mortality_evidence[candidate_row] <- "Natural mortality is fixed at M = 0.15 per year for all modeled ages."
candidates$timing_evidence[candidate_row] <- paste(
  "Spring survey occurs in February/March and summer survey in August;",
  "the fractional-year times used by SAM are not reported."
)
candidates$output_evidence[candidate_row] <- paste(
  "Tables 3.2.11-3.2.13 report recruitment at age 3, SSB, Fbar ages 6-10, total biomass,",
  "N-at-age and F-at-age for 1996-2025; only aggregate series have reported 95% intervals."
)
candidates$notes[candidate_row] <- paste(
  "The 2026 report identifies applied SAM run lin.27.5b_wgdeep2026_final.",
  "Published tables are imported; direct model-object downloads reset the connection.",
  "The Faroes unit is distinct from Icelandic ling lin.27.5a."
)
replace_candidate_register_row(
  candidate_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id
)

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(
  inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE
)
inventory_row <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
if (length(inventory_row) != 1L) stop("Expected one Faroes ling inventory row.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"
replace_discovery_row(
  inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
  "unit_key", paste0("candidate:", candidate_unit_id)
)

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(
  selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE
)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("Expected one selected Faroes ling row.", call. = FALSE)
selected$review_date[selected_row] <- "2026-11-03"
selected$curation_status[selected_row] <- "partial_source_import"
replace_discovery_row(
  selected_path, selected_row, selected[selected_row, , drop = FALSE],
  "candidate_id", candidate_id
)

cat(
  "Imported partial Faroes ling assessment source records:",
  nrow(inputs), "inputs,", nrow(assumptions), "assumptions, and",
  nrow(outputs), "outputs.\n"
)
