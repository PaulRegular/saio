root <- "."
.libPaths(c(file.path(root, "source_cache", "r-library"), .libPaths()))
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_ling_5a_2026")
assessment_id <- "ices_ling_5a_2026"
candidate_id <- "ICES:lin.27.5a"
unit_id <- "ices_ling_5a"

supplement_url <- "https://www.hafogvatn.is/static/extras/images/6_lin_2026_1_tables_en.html"
report_url <- "https://www.hafogvatn.is/static/extras/images/6_lin_2026_1_techreport_en.html"
supplement_ref <- "MFRI 2026 ling supplementary tables"
source_file <- "MFRI_ling_2026_supplementary_tables.html"
source_hash <- "084aef47d10cb0c6a44e3fea6a568fe3ed5e4cc210eef209061ce040dd4f46a5"
source_bytes <- 4700509

if (!dir.exists(cache)) stop("The reviewed Icelandic ling source cache is missing.", call. = FALSE)
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(normalizePath(path)), "SHA256"),
    stdout = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

manifest_path <- file.path(root, "provenance", "discovery_ices_ling_5a_2026", "supplementary_sources.csv")
manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
source_path <- file.path(cache, source_file)
if (nrow(manifest) != 1L || manifest$file != source_file ||
    manifest$url != supplement_url || manifest$retrieved_on != "2026-11-14" ||
    manifest$sha256 != source_hash || as.numeric(manifest$bytes) != source_bytes ||
    !file.exists(source_path) || file.info(source_path)$size != source_bytes ||
    sha256_file(source_path) != source_hash) {
  stop("Cached MFRI supplementary tables differ from the reviewed source manifest.", call. = FALSE)
}

html <- paste(readLines(source_path, warn = FALSE), collapse = "\n")
expected_headings <- c(
  "Landings", "Assessment summary", "Advice history", "TAC History",
  "Catch at age", "Catch-weights", "SSB-weights", "Stock-weights",
  "Maturity at age", "IS-SMB index", "IS-SMH index", "IS-SMN index",
  "Acoustic survey index", "Stock in numbers", "Fishing mortality"
)
headings <- regmatches(html, gregexpr("(?is)<h3\\b[^>]*>.*?</h3>", html, perl = TRUE))[[1L]]
headings <- gsub("[[:space:]]+", " ", trimws(gsub("<[^>]*>", " ", headings, perl = TRUE)))
headings <- headings[nzchar(headings)]
script_tags <- regmatches(html, gregexpr(
  "(?is)<script type=\"application/json\" data-for=\"[^\"]+\">.*?</script>",
  html, perl = TRUE
))[[1L]]
if (!identical(headings, expected_headings) || length(script_tags) != length(expected_headings)) {
  stop("The MFRI supplementary page no longer matches its reviewed table structure.", call. = FALSE)
}

table_data <- lapply(script_tags, function(tag) {
  json <- sub("(?is)^.*?>", "", tag, perl = TRUE)
  json <- sub("(?is)</script>.*$", "", json, perl = TRUE)
  jsonlite::fromJSON(json, simplifyVector = FALSE)$x$data
})
parse_number <- function(x) {
  x <- gsub("&nbsp;|&#160;", "", x, ignore.case = TRUE)
  x <- gsub("[[:space:],]", "", x)
  x[x %in% c("", "-", "—", "–", "NA", "null")] <- NA_character_
  suppressWarnings(as.numeric(x))
}
column_values <- function(x) {
  vapply(x, function(value) {
    if (is.null(value)) NA_character_ else as.character(value)
  }, character(1L))
}
age_table <- function(index, years, ages) {
  columns <- table_data[[index]]
  if (length(columns) != 3L + length(ages) ||
      length(columns[[1L]]) != length(years) ||
      !identical(as.integer(parse_number(column_values(columns[[1L]]))), as.integer(years))) {
    stop("Unexpected year or age columns in MFRI table: ", expected_headings[index], call. = FALSE)
  }
  if (any(column_values(columns[[2L]]) != "Ling", na.rm = TRUE) ||
      any(column_values(columns[[3L]]) != "Molva molva", na.rm = TRUE)) {
    stop("The supplementary table contains an unexpected stock identity.", call. = FALSE)
  }
  values <- do.call(cbind, lapply(columns[seq.int(4L, length(columns))], function(column) {
    parse_number(column_values(column))
  }))
  storage.mode(values) <- "numeric"
  data.frame(
    year = rep(as.integer(years), times = length(ages)),
    age = rep(as.integer(ages), each = length(years)),
    value = as.vector(values)
  )
}

catch_age <- age_table(5L, 1979:2025, 3:12)
catch_weight <- age_table(6L, 1979:2025, 2:12)
stock_weight <- age_table(8L, 1979:2025, 2:12)
maturity <- age_table(9L, 1979:2025, 2:12)
spring_index <- age_table(10L, 1985:2025, 2:12)
autumn_index <- age_table(11L, 2000:2025, 2:12)
gillnet_index <- age_table(12L, 2002:2025, 2:12)
stock_numbers <- age_table(14L, 1979:2026, 2:12)
fishing_mortality <- age_table(15L, 1979:2025, 2:12)

if (nrow(catch_age) != 470L || any(!is.finite(catch_age$value)) ||
    nrow(catch_weight) != 517L || any(!is.finite(catch_weight$value)) ||
    nrow(stock_weight) != 517L || any(!is.finite(stock_weight$value)) ||
    nrow(maturity) != 517L || any(!is.finite(maturity$value)) ||
    nrow(spring_index) != 451L || sum(is.finite(spring_index$value)) != 451L ||
    nrow(autumn_index) != 286L || sum(is.finite(autumn_index$value)) != 280L ||
    nrow(gillnet_index) != 264L || sum(is.finite(gillnet_index$value)) != 256L ||
    nrow(stock_numbers) != 528L || any(!is.finite(stock_numbers$value)) ||
    nrow(fishing_mortality) != 517L || any(!is.finite(fishing_mortality$value)) ||
    any(maturity$value < 0 | maturity$value > 1)) {
  stop("The MFRI age tables have unexpected coverage, missing cells, or values.", call. = FALSE)
}

input_rows <- function(x, type, measure, basis, unit, source_reference,
                       notes, fleet = "", survey = "", season = "") {
  x <- x[is.finite(x$value), , drop = FALSE]
  pacific_database_row(
    "inputs", n = nrow(x), assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = "Iceland grounds",
    season = season, year = x$year, year_basis = "calendar_year",
    age = x$age, value = x$value, unit = unit, sampling_time = NA_real_,
    source_type = "official_machine_readable", source_reference = source_reference,
    transformation = "Reshaped from the official supplementary table; no rescaling, interpolation, or imputation.",
    notes = notes
  )
}
table_ref <- function(n, heading) paste0(supplement_url, " (Table ", n, ": ", heading, ")")
age_notes <- "Age 12 is the plus group. The source table contains one combined series and does not split the values by sex or fleet."
inputs <- do.call(rbind, list(
  input_rows(catch_age, "catch", "numbers_at_age", "numbers", "thousand fish",
    table_ref(5L, "Catch at age"), paste(
      "Catch in numbers at age, reported in thousands. Age 2 is not tabulated and is not added.", age_notes
    )),
  input_rows(catch_weight, "catch_weight", "catch_weight_at_age", "g_per_fish", "g/fish",
    table_ref(6L, "Catch-weights"), "Weight at age from commercial catches, reported in grams per fish. Age 12 is the plus group."),
  input_rows(stock_weight, "weight", "weight_at_age", "g_per_fish", "g/fish",
    table_ref(8L, "Stock-weights"), paste(
      "Weight at age in the stock, reported in grams per fish. The separate SSB-weights table is empty; these values are not relabelled as spawning-stock weights.",
      "Age 12 is the plus group."
    )),
  input_rows(maturity, "maturity", "maturity_at_age", "proportion", "proportion",
    table_ref(9L, "Maturity at age"), "Proportion mature at age in the stock. Age 12 is the plus group."),
  input_rows(spring_index, "index", "numbers_at_age", "index_scale", "reported index units",
    table_ref(10L, "IS-SMB index"), paste(
      "Age-disaggregated March groundfish survey index. The source caption says 'in numbers' but gives no multiplier or absolute count unit; values remain on the reported index scale.",
      "Exact within-year timing is not reported. Age 12 is the plus group."
    ), survey = "IS-SMB groundfish survey", season = "spring"),
  input_rows(autumn_index, "index", "numbers_at_age", "index_scale", "reported index units",
    table_ref(11L, "IS-SMH index"), paste(
      "Age-disaggregated October groundfish survey index. The source caption says 'in numbers' but gives no multiplier or absolute count unit; values remain on the reported index scale. Six blank cells are omitted, not imputed.",
      "The report does not state exact within-year timing. Age 12 is the plus group."
    ), survey = "IS-SMH groundfish survey", season = "autumn"),
  input_rows(gillnet_index, "index", "numbers_at_age", "index_scale", "reported index units",
    table_ref(12L, "IS-SMN index"), paste(
      "Age-disaggregated gillnet survey index. The source caption says 'in numbers' but gives no multiplier or absolute count unit; values remain on the reported index scale. Eight blank cells are omitted, not imputed.",
      "The report identifies an early-April survey but not the exact within-year timing. Age 12 is the plus group."
    ), survey = "IS-SMN gillnet survey", season = "spring")
))

output_rows <- function(x, type, measure, unit, source_reference, notes, scenario = "") {
  x <- x[is.finite(x$value), , drop = FALSE]
  pacific_database_row(
    "outputs", n = nrow(x), assessment_id = assessment_id,
    type = type, measure = measure, fleet = "", survey = "", sex = "",
    region = "Iceland grounds", season = "", year = x$year, age = x$age,
    age_group = "", value = x$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_machine_readable",
    source_reference = source_reference, notes = notes,
    scenario = scenario
  )
}
stock_numbers$scenario <- ifelse(stock_numbers$year == 2026L, "2026 advice projection", "")
outputs <- rbind(
  output_rows(stock_numbers, "population", "numbers_at_age", "thousand fish",
    table_ref(14L, "Stock in numbers"), paste(
      "Official stock numbers at age. Age 12 is the plus group; the 2026 row is an advice projection.",
      "Age-specific uncertainty is not reported in this table."
    ), scenario = stock_numbers$scenario),
  output_rows(fishing_mortality, "mortality", "fishing_mortality_at_age", "per year",
    table_ref(15L, "Fishing mortality"), paste(
      "Official fishing mortality at age through the terminal fitted year 2025. Age 12 is the plus group; age-specific uncertainty is not reported in this table."
    ))
)

if (nrow(inputs) != 3008L || nrow(outputs) != 1045L ||
    any(!is.finite(inputs$value)) || any(!is.finite(outputs$value)) ||
    sum(inputs$measure == "numbers_at_age" & inputs$type == "index") != 987L ||
    sum(inputs$measure == "numbers_at_age" & inputs$type == "catch") != 470L) {
  stop("Constructed Icelandic ling supplementary rows failed source checks.", call. = FALSE)
}

source_counts <- function(path, expected) {
  found <- setNames(integer(length(expected)), names(expected))
  patterns <- names(expected)
  pattern_lengths <- nchar(patterns, type = "bytes")
  overlap <- max(pattern_lengths) - 1L
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  carry <- raw()
  repeat {
    chunk <- readBin(connection, what = "raw", n = 16L * 1024L * 1024L)
    if (!length(chunk)) break
    carry_length <- length(carry)
    searchable <- c(carry, chunk)
    for (reference in names(expected)) {
      reference_length <- pattern_lengths[match(reference, patterns)]
      offset <- if (carry_length) max(1L, carry_length - reference_length + 2L) else 1L
      found[reference] <- found[reference] + length(grepRaw(
        reference, searchable, all = TRUE, fixed = TRUE, offset = offset
      ))
    }
    if (overlap) carry <- tail(searchable, min(overlap, length(searchable)))
  }
  if (any(found != 0L & found != expected)) {
    stop("A partial or unexpected Icelandic ling supplementary import already exists.", call. = FALSE)
  }
  if (all(found == 0L)) return(names(expected))
  if (all(found == expected)) return(character())
  stop("Icelandic ling supplementary import is in an inconsistent state.", call. = FALSE)
}
input_expected <- table(inputs$source_reference)
output_expected <- table(outputs$source_reference)
dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")
if (dry_run) {
  input_to_add <- inputs
  output_to_add <- outputs
} else {
  input_refs_to_add <- source_counts(file.path(database, "inputs.csv"), input_expected)
  output_refs_to_add <- source_counts(file.path(database, "outputs.csv"), output_expected)
  input_to_add <- inputs[inputs$source_reference %in% input_refs_to_add, , drop = FALSE]
  output_to_add <- outputs[outputs$source_reference %in% output_refs_to_add, , drop = FALSE]
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || candidates$official_stock_id[candidate_row] != "lin.27.5a") {
  stop("Icelandic ling candidate identity does not match the register.", call. = FALSE)
}
candidate_updated <- candidates[candidate_row, , drop = FALSE]
candidate_updated$matched_stock_id <- unit_id
candidate_updated$match_status <- "matched"
candidate_updated$import_status <- "partial"
candidate_updated$catch_age_evidence <- paste(
  "MFRI 2026 supplementary Table 5 provides catch numbers-at-age for ages 3-12+ in 1979-2025, in thousands of fish.",
  "Age 2 is not tabulated; aggregate catch, landings and discards remain imported from ICES source data."
)
candidate_updated$survey_age_evidence <- paste(
  "MFRI 2026 supplementary Tables 10-12 provide three age-specific index series: IS-SMB 1985-2025, IS-SMH 2000-2025, and IS-SMN 2002-2025.",
  "14 blank cells remain absent. Captions say 'in numbers', but multiplier and exact sampling fractions are unresolved."
)
candidate_updated$weights_evidence <- paste(
  "Tables 6 and 8 provide catch and stock weights-at-age in g/fish for ages 2-12+ during 1979-2025.",
  "The separate SSB-weights table is empty; stock weights are not relabelled as spawning-stock weights."
)
candidate_updated$maturity_evidence <- "Table 9 provides maturity-at-age proportions for ages 2-12+ during 1979-2025."
candidate_updated$mortality_evidence <- paste(
  "The 2023 ICES Stock Annex states fixed natural mortality M = 0.15 per year for ages 2-12+.",
  "This vector is already imported."
)
candidate_updated$timing_evidence <- paste(
  "The report identifies IS-SMB in March, IS-SMH in October, and IS-SMN in early April.",
  "The exact fractional-year sampling times used in the model remain unavailable."
)
candidate_updated$output_evidence <- paste(
  "Tables 14-15 provide age-specific stock numbers for ages 2-12+ in 1979-2026 and fishing mortality in 1979-2025.",
  "The 2026 N-at-age is an advice projection; age-specific uncertainty is not tabulated. Aggregate ICES outputs retain their reported intervals."
)
candidate_updated$detailed_source_url <- paste(candidate_updated$detailed_source_url, supplement_url, sep = "; ")
candidate_updated$review_date <- "2026-11-14"
candidate_updated$decision_reason <- paste(
  "Latest current-unit 2026 production assessment remains eligible and is now source-curated with age-specific inputs and point outputs.",
  "Input completeness remains partial because survey scaling/timing and SSB-weight details are unresolved."
)
candidate_updated$notes <- paste(
  "Current 2026 production assessment; historical fit ends in 2025 and selected 2026 aggregate and N-at-age outputs are advice projections.",
  "Supplementary age tables are cached and checksummed in provenance/discovery_ices_ling_5a_2026/supplementary_sources.csv."
)

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- which(inventory$unit_key == paste0("candidate:", unit_id))
if (length(inventory_row) != 1L || inventory$candidate_ids[inventory_row] != candidate_id) {
  stop("Icelandic ling inventory row is missing or does not match the candidate.", call. = FALSE)
}
inventory_updated <- inventory[inventory_row, , drop = FALSE]
inventory_updated$matched_stock_id <- unit_id
inventory_updated$match_status <- "matched"
inventory_updated$import_status <- "partial"

assessment_path <- file.path(database, "assessments.csv")
assessments <- utils::read.csv(assessment_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L || assessments$inputs_status[assessment_row] != "partial") {
  stop("Expected one partial Icelandic ling assessment record.", call. = FALSE)
}
assessment_updated <- assessments[assessment_row, , drop = FALSE]
assessment_updated$outputs_status <- "complete"
assessment_updated$notes <- paste(
  "The latest 2026 production assessment used for advice is represented.",
  "The fitted historical series ends in 2025; selected 2026 values are advice projections.",
  "Aggregate ICES outputs and age-specific N/F point surfaces are imported; the age-specific surfaces do not include uncertainty. Inputs remain partial because survey multipliers/timing and SSB-weight details are unresolved."
)

if (!dry_run) {
  append_rows <- function(path, rows) {
    if (!nrow(rows)) return(invisible(NULL))
    connection <- file(path, open = "rb")
    on.exit(try(close(connection), silent = TRUE), add = TRUE)
    seek(connection, where = file.info(path)$size - 1, origin = "start")
    last_byte <- readBin(connection, what = "raw", n = 1L)
    close(connection)
    if (!identical(last_byte, as.raw(10L))) {
      connection <- file(path, open = "ab")
      writeBin(charToRaw("\r\n"), connection)
      close(connection)
    }
    utils::write.table(rows, path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = "", eol = "\r\n")
  }
  append_rows(file.path(database, "inputs.csv"), input_to_add)
  append_rows(file.path(database, "outputs.csv"), output_to_add)
  replace_csv_register_row(
    assessment_path, assessment_row, assessment_updated, "assessment_id", assessment_id
  )
  replace_candidate_register_row(candidate_path, candidate_row, candidate_updated, candidate_id)
  replace_csv_register_row(
    inventory_path, inventory_row, inventory_updated, "unit_key", paste0("candidate:", unit_id)
  )
}
cat("Icelandic ling supplementary tables: ", nrow(inputs), " inputs and ", nrow(outputs),
  " outputs prepared; ", nrow(input_to_add), " inputs and ", nrow(output_to_add),
  " outputs to append.\n", sep = "")
