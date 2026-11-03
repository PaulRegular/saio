root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_irish_sea_herring_2026")
shared_cache <- file.path(root, "source_cache", "discovery_ices_celtic_sea_herring_2026")
candidate_id <- "ICES:her.27.nirs"
candidate_unit_id <- "ices_her_27_nirs"
stock_id <- candidate_unit_id
assessment_id <- "ices_her_27_nirs_2026"
report_url <- "https://doi.org/10.17895/ices.pub.31424315"
source_data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21319"
report_reference <- paste(
  "ICES HAWG 2026, section 8; Tables 8.2.1.2, 8.3.1-8.3.2,",
  "8.5.1-8.5.4, and 8.7.1.1"
)

source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify SHA-256 for ", path, call. = FALSE)
  hashes
}

report_path <- file.path(shared_cache, "ices_hawg_2026_full_report.pdf")
tables_path <- file.path(cache, "hawg_2026_irish_sea_tables.txt")
sag_path <- file.path(cache, "ices_sag_source_data_2026_her_27_nirs.html")
manifest <- utils::read.csv(file.path(cache, "sources.csv"), stringsAsFactors = FALSE)
report_manifest <- utils::read.csv(file.path(shared_cache, "sources.csv"), stringsAsFactors = FALSE)
expected_hashes <- c(
  report = "a0c3928fde2693cbbcc176abfb7450e7f426e47898d2020529e1fb563542bb66",
  tables = "de7738dee94eb4da1dd73877345035fc3aaeeccb43d88f44e9fb01b7ebc7eada",
  sag = "a26f71caa8becf6bc07252f1aed2a6395ff56bbac7030d632c054a265b494078"
)
report_row <- report_manifest[report_manifest$file == basename(report_path), , drop = FALSE]
sag_row <- manifest[manifest$file == basename(sag_path), , drop = FALSE]
if (nrow(report_row) != 1L || nrow(sag_row) != 1L ||
    tolower(report_row$sha256) != expected_hashes[["report"]] ||
    tolower(sag_row$sha256) != expected_hashes[["sag"]] ||
    report_row$retrieved_on != "2026-10-29" || sag_row$retrieved_on != "2026-10-29" ||
    sha256_file(report_path) != expected_hashes[["report"]] ||
    sha256_file(tables_path) != expected_hashes[["tables"]] ||
    sha256_file(sag_path) != expected_hashes[["sag"]]) {
  stop("The cached Irish Sea herring sources differ from their reviewed versions.", call. = FALSE)
}

table_text <- readLines(tables_path, warn = FALSE, encoding = "UTF-8")
page_text <- function(page_number) {
  marker <- paste0("===== PDF PAGE ", page_number, " =====")
  start <- match(marker, trimws(table_text))
  if (is.na(start)) stop("Missing extracted HAWG page ", page_number, call. = FALSE)
  next_page <- grep("^===== PDF PAGE ", trimws(table_text))
  end <- next_page[next_page > start][1L]
  if (is.na(end)) end <- length(table_text) + 1L
  table_text[seq.int(start + 1L, end - 1L)]
}

parse_number_tokens <- function(tokens, expected, max_value = Inf) {
  solutions <- list()
  visit <- function(position, values) {
    remaining_values <- expected - length(values)
    remaining_tokens <- length(tokens) - position + 1L
    if (remaining_values == 0L) {
      if (remaining_tokens == 0L) solutions[[length(solutions) + 1L]] <<- values
      return(invisible(NULL))
    }
    if (remaining_tokens < remaining_values) return(invisible(NULL))
    token <- tokens[position]
    numeric_token <- token == "-" || grepl("^[0-9]+([.][0-9]+)?$", token)
    if (!numeric_token) return(invisible(NULL))
    visit(position + 1L, c(values, token))
    if (position < length(tokens) &&
        grepl("^[0-9]{1,3}$", token) && grepl("^[0-9]{3}$", tokens[position + 1L])) {
      visit(position + 2L, c(values, paste0(token, tokens[position + 1L])))
    }
    invisible(NULL)
  }
  visit(1L, character())
  valid <- vapply(solutions, function(values) {
    values[values == "-"] <- NA_character_
    numeric_values <- suppressWarnings(as.numeric(values))
    all(is.na(numeric_values) | numeric_values <= max_value)
  }, logical(1L))
  solutions <- solutions[valid]
  if (length(solutions) != 1L) {
    stop("A HAWG age table row has zero or ambiguous numeric reconstructions: ",
      paste(tokens, collapse = " "), " (expected ", expected, " values).", call. = FALSE)
  }
  value <- solutions[[1L]]
  value[value == "-"] <- NA_character_
  suppressWarnings(as.numeric(value))
}

parse_age_table <- function(page_number, ages = c(1:7, 8L), max_value = Inf,
                            expected_years = 1980:2025) {
  lines <- trimws(page_text(page_number))
  header_rows <- grep("^Age[[:space:]]", lines)
  if (!length(header_rows)) stop("No age/year headers found on HAWG page ", page_number, call. = FALSE)
  blocks <- list()
  for (i in seq_along(header_rows)) {
    header <- lines[header_rows[i]]
    year_tokens <- regmatches(header, gregexpr("[0-9]{2}", header, perl = TRUE))[[1L]]
    short_years <- as.integer(year_tokens)
    years <- ifelse(short_years >= 80L, 1900L + short_years, 2000L + short_years)
    stop_at <- if (i < length(header_rows)) header_rows[i + 1L] - 1L else length(lines)
    data_lines <- lines[seq.int(header_rows[i] + 1L, stop_at)]
    age_lines <- data_lines[grepl("^(8[+]|[1-7])[[:space:]]+", data_lines)]
    if (length(years) == 0L || length(age_lines) != length(ages)) {
      stop("Unexpected age-table block on HAWG page ", page_number, call. = FALSE)
    }
    block <- matrix(NA_real_, nrow = length(ages), ncol = length(years),
      dimnames = list(as.character(ages), as.character(years))
    )
    seen_ages <- integer()
    for (line in age_lines) {
      match <- regexec("^(8[+]|[1-7])[[:space:]]+(.+)$", line)
      pieces <- regmatches(line, match)[[1L]]
      age <- if (pieces[2L] == "8+") 8L else as.integer(pieces[2L])
      if (age %in% seen_ages) stop("Duplicate age row on HAWG page ", page_number, call. = FALSE)
      seen_ages <- c(seen_ages, age)
      tokens <- strsplit(trimws(pieces[3L]), "[[:space:]]+")[[1L]]
      age_max <- if (length(max_value) > 1L) max_value[as.character(age)] else max_value
      block[as.character(age), ] <- parse_number_tokens(tokens, length(years), age_max)
    }
    if (!identical(seen_ages, ages)) stop("Age rows are incomplete on HAWG page ", page_number, call. = FALSE)
    blocks[[i]] <- block
  }
  out <- do.call(cbind, blocks)
  if (anyDuplicated(colnames(out)) ||
      !identical(as.integer(colnames(out)), as.integer(expected_years))) {
    stop("Unexpected year coverage on HAWG page ", page_number, call. = FALSE)
  }
  out
}

age_long <- function(x) {
  data <- data.frame(
    year = rep(as.integer(colnames(x)), times = nrow(x)),
    age = rep(as.integer(rownames(x)), each = ncol(x)),
    value = as.vector(t(x))
  )
  data[is.finite(data$value), , drop = FALSE]
}

# Text extraction omits cell boundaries; source-verified age-specific limits resolve grouped thousands.
catch_max <- c("1" = 100000, "2" = 100000, "3" = 50000, "4" = 25000,
               "5" = 10000, "6" = 10000, "7" = 10000, "8" = 10000)
catch_table <- parse_age_table(437L, max_value = catch_max)
isas_table <- parse_age_table(441L, expected_years = 1994:2025)
catch_weight_table <- parse_age_table(443L)
stock_weight_table <- parse_age_table(444L)
maturity_table <- parse_age_table(445L)
m_table <- parse_age_table(446L)
if (!all(is.na(catch_table[, "2009"])) || any(!is.finite(catch_table[, -which(colnames(catch_table) == "2009")]))) {
  stop("The catch-at-age table does not match its documented 2009 gap.", call. = FALSE)
}
if (!all(apply(m_table, 1L, function(x) length(unique(x)) == 1L))) {
  stop("The published M-at-age series is not constant over years.", call. = FALSE)
}

parse_index_table <- function() {
  lines <- trimws(page_text(442L))
  start <- grep("^Table 8[.]3[.]2[.]", lines)
  if (length(start) != 1L) stop("Could not isolate HAWG Table 8.3.2.", call. = FALSE)
  data_lines <- lines[seq.int(start + 1L, length(lines))]
  data_lines <- data_lines[grepl("^20[0-9]{2}[[:space:]]+", data_lines)]
  result <- list()
  for (line in data_lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    position <- 1L
    while (position <= length(tokens)) {
      year <- as.integer(tokens[position])
      position <- position + 1L
      if (position > length(tokens)) stop("Incomplete SSB index row.", call. = FALSE)
      first <- tokens[position]
      if (position < length(tokens) && grepl("^[0-9]{1,3}$", first) &&
          grepl("^[0-9]{3}$", tokens[position + 1L])) {
        value <- as.numeric(paste0(first, tokens[position + 1L]))
        position <- position + 2L
      } else {
        value <- as.numeric(first)
        position <- position + 1L
      }
      result[[length(result) + 1L]] <- data.frame(year = year, age = NA_integer_, value = value)
    }
  }
  out <- do.call(rbind, result)
  if (anyDuplicated(out$year) || !identical(sort(out$year), 2007:2025)) {
    stop("Unexpected year coverage in HAWG Table 8.3.2.", call. = FALSE)
  }
  out
}
isss_index <- parse_index_table()

parse_sag_outputs <- function(path) {
  html <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  rows <- regmatches(html, gregexpr("(?is)<tr\\b[^>]*>.*?</tr>", html, perl = TRUE))[[1L]]
  if (!length(rows)) stop("No rows found in the cached ICES SAG page.", call. = FALSE)
  parse_cells <- function(row) {
    cells <- regmatches(row, gregexpr("(?is)<td\\b[^>]*>.*?</td>", row, perl = TRUE))[[1L]]
    cells <- gsub("(?is)<[^>]*>", "", cells, perl = TRUE)
    cells <- gsub("&nbsp;", " ", cells, fixed = TRUE)
    trimws(cells)
  }
  parsed <- lapply(rows, parse_cells)
  parsed <- parsed[vapply(parsed, function(x) length(x) == 15L && grepl("^[0-9]{4}$", x[1L]), logical(1L))]
  if (length(parsed) != 47L) stop("ICES SAG output table does not contain 1980-2026.", call. = FALSE)
  data <- as.data.frame(do.call(rbind, parsed), stringsAsFactors = FALSE)
  names(data) <- c(
    "year", "recruit_low", "recruitment", "recruit_high",
    "biomass_low", "total_biomass", "biomass_high",
    "ssb_low", "SSB", "ssb_high", "landings", "catches",
    "F_low", "Fbar", "F_high"
  )
  for (name in names(data)) data[[name]] <- as.numeric(data[[name]])
  data <- data[data$year %in% 1980:2025, , drop = FALSE]
  if (!identical(data$year, as.numeric(1980:2025)) ||
      any(!is.finite(as.matrix(data[, -1L, drop = FALSE])))) {
    stop("ICES SAG output table has missing or misordered assessment years.", call. = FALSE)
  }
  data
}
sag <- parse_sag_outputs(sag_path)
latest <- sag[sag$year == 2025, , drop = FALSE]
if (latest$recruitment != 157581 || latest$SSB != 11298 ||
    latest$Fbar != 0.342 || latest$catches != 5359) {
  stop("2025 SAG outputs do not match HAWG Table 8.7.1.1.", call. = FALSE)
}

assessment_years <- 1980:2025
ages <- 1:8
isas_survey <- "Irish Sea Acoustic Survey (ISAS; AC(7.aN))"
isss_survey <- "Irish Sea Commercial Acoustic Survey (ISSS; AC(7.aSpawn))"
age_notes <- "Age 8 represents the reported 8+ winter-ring group."
source_type <- "official_table"

input_rows <- function(data, type, measure, basis, unit, source_reference,
                       survey = "", season = "", transformation = "", notes = "") {
  pacific_database_row(
    "inputs", n = nrow(data), assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = "", survey = survey, sex = "", region = "Irish Sea", season = season,
    year = data$year, year_basis = ifelse(is.na(data$year), "", "model_year"),
    age = data$age, value = data$value, unit = unit, sampling_time = NA_real_,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes
  )
}

catch_long <- age_long(catch_table)
isas_long <- age_long(isas_table)
catch_weight_long <- age_long(catch_weight_table)
stock_weight_long <- age_long(stock_weight_table)
maturity_long <- age_long(maturity_table)
m_values <- data.frame(
  year = NA_integer_, age = ages,
  value = as.numeric(m_table[, "1980"])
)

inputs <- do.call(rbind, list(
  input_rows(
    catch_long, "catch", "numbers_at_age", "numbers", "thousand fish",
    "ICES HAWG 2026, Table 8.2.1.2, p. 428",
    transformation = "Transcribed as reported; the 2009 row is not estimated and is omitted.",
    notes = paste(age_notes, "One combined assessment catch-at-age series; fleet allocation is not published.")
  ),
  input_rows(
    isas_long, "index", "numbers_at_age", "numbers", "thousand fish",
    "ICES HAWG 2026, Table 8.3.1, p. 432",
    survey = isas_survey, season = "late summer/early autumn",
    transformation = "Transcribed as reported; no additional scaling applied.",
    notes = paste(age_notes, "Age-specific acoustic abundance; ISAS estimates may differ from WGIPS after re-estimation with ageing data.")
  ),
  input_rows(
    isss_index, "index", "relative_biomass_index", "index_scale",
    "SSB index; unit not stated",
    "ICES HAWG 2026, Table 8.3.2, p. 433",
    survey = isss_survey, season = "autumn",
    transformation = "Transcribed as reported; no unit or multiplier is inferred.",
    notes = "Aggregate SSB index; it is a separate series from the age-specific ISAS abundance estimates."
  ),
  input_rows(
    catch_weight_long, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg per fish",
    "ICES HAWG 2026, Table 8.5.1, p. 434",
    transformation = "Transcribed as reported; 2009 values are the published mean of 2008 and 2010 at age.",
    notes = paste(age_notes, "Catch weights use all catch seasons.")
  ),
  input_rows(
    stock_weight_long, "weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "ICES HAWG 2026, Table 8.5.2, p. 435",
    transformation = "Transcribed as reported; 2009 values are the published mean of 2008 and 2010 at age.",
    notes = paste(age_notes, "Stock weights are based on Q3 catch biology.")
  ),
  input_rows(
    maturity_long, "maturity", "maturity_at_age", "proportion", "proportion",
    "ICES HAWG 2026, Table 8.5.3, p. 436",
    transformation = "Transcribed as reported; 2009 values are the published mean of 2008 and 2010 at age.",
    notes = paste(age_notes, "Time-varying maturity ogive from Q3 catch samples.")
  ),
  input_rows(
    m_values, "M", "natural_mortality_at_age", "per_year", "per year",
    "ICES HAWG 2026, Table 8.5.4, p. 437",
    transformation = "The table repeats identical age-specific values across years; stored once as time-invariant M.",
    notes = paste(age_notes, "Fixed values borrowed from North Sea herring; not estimated for the Irish Sea stock.")
  )
))

output_rows <- function(type, measure, value, year, unit, lower = NA_real_, upper = NA_real_,
                        age = NA_integer_, age_group = "", notes = "") {
  n <- length(value)
  pacific_database_row(
    "outputs", n = n, assessment_id = assessment_id,
    type = type, measure = measure, fleet = "", survey = "", sex = "",
    region = "Irish Sea", season = "", year = as.integer(year),
    age = age, age_group = age_group, value = value, se = NA_real_,
    lwr = lower, upr = upper, unit = unit,
    source_type = "official_machine_readable",
    source_reference = "ICES Stock Assessment Graphs, key 21319, Fish data table",
    notes = if (nzchar(notes)) notes else if (is.na(lower[1L])) {
      "Point estimate only; no interval is reported for this series."
    } else {
      "Low and high values are the reported 95% confidence interval."
    }
  )
}

output_years <- as.integer(sag$year)
outputs <- do.call(rbind, list(
  output_rows("recruitment", "recruitment", sag$recruitment, output_years,
    "thousand fish", sag$recruit_low, sag$recruit_high, age = 1L),
  output_rows("biomass", "total_biomass", sag$total_biomass, output_years,
    "tonnes", sag$biomass_low, sag$biomass_high),
  output_rows("biomass", "SSB", sag$SSB, output_years,
    "tonnes", sag$ssb_low, sag$ssb_high),
  output_rows("catch", "landings", sag$landings, output_years, "tonnes"),
  output_rows("catch", "total_catch", sag$catches, output_years, "tonnes",
    notes = paste(
      "Point estimate only; HAWG Table 8.7.1.1 independently reports this total catch series.",
      "The SAG Catches and Landings values are identical in the published source table."
    )),
  output_rows("mortality", "Fbar", sag$Fbar, output_years,
    "ratio", sag$F_low, sag$F_high, age_group = "2-4")
))

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                            survey = "") {
  pacific_database_row(
    "assumptions", assessment_id = assessment_id, component = component,
    fleet = "", survey = survey, sex = "", region = "Irish Sea", season = "",
    setting = setting, value = value,
    source_reference = source_reference, notes = notes
  )
}

assumptions <- do.call(rbind, list(
  assumption_rows("population", "model_years", "1980-2025", report_reference,
    "The annual assessment/model year runs 1 April through 31 March."),
  assumption_rows("population", "model_age_range", "1-8+ winter rings", report_reference,
    "Age 8 is the reported plus group."),
  assumption_rows("recruitment", "recruitment_age", "1 winter ring",
    "ICES HAWG 2026, Table 8.7.1.1, pp. 441-442"),
  assumption_rows("catch", "catch_at_age", "Combined commercial catch-at-age",
    "ICES HAWG 2026, Table 8.2.1.2, p. 428",
    "The table does not publish fleet-specific rows; 2009 has no estimate."),
  assumption_rows("survey", "age_specific_index", "ISAS ages 1-8+, 1994-2025",
    "ICES HAWG 2026, Table 8.3.1, p. 432",
    "Values are numbers-at-age in thousands; no additional multiplier is applied.", survey = isas_survey),
  assumption_rows("survey", "aggregate_index", "ISSS SSB index, 2007-2025",
    "ICES HAWG 2026, Table 8.3.2, p. 433",
    "The report does not state a unit or scale multiplier; values are retained as printed.", survey = isss_survey),
  assumption_rows("survey", "survey_timing", "ISAS late August-September; ISSS late September/early October",
    "ICES HAWG 2026, section 8.3",
    "Exact annual sampling-time fractions used by the 2026 assessment were not recovered; input sampling_time is blank.", survey = "Irish Sea acoustic surveys"),
  assumption_rows("biology", "catch_weight_basis", "All catch seasons",
    "ICES HAWG 2026, Table 8.5.1, p. 434"),
  assumption_rows("biology", "stock_weight_basis", "Q3 catches",
    "ICES HAWG 2026, Table 8.5.2, p. 435"),
  assumption_rows("biology", "maturity_basis", "Q3 catch samples; time-varying by year and age",
    "ICES HAWG 2026, Table 8.5.3, p. 436"),
  assumption_rows("biology", "missing_2009_biology", "Published values are means of 2008 and 2010 at age",
    "ICES HAWG 2026, Tables 8.5.1-8.5.3, pp. 434-436",
    "Retained as presented; no separate recomputation from rounded values."),
  assumption_rows("M", "natural_mortality", paste("Fixed age-specific M:",
      paste(format(as.numeric(m_table[, "1980"]), nsmall = 3), collapse = ", ")),
    "ICES HAWG 2026, Table 8.5.4, p. 437",
    "Values are borrowed from North Sea herring and are not estimated for this stock."),
  assumption_rows("mortality", "Fbar_ages", "2-4 winter rings",
    "ICES HAWG 2026, Table 8.7.1.1, pp. 441-442"),
  assumption_rows("biomass", "SSB_timing", "September spawning time",
    "ICES HAWG 2026, Table 8.7.1.1 footnote, p. 442",
    "The assessment notes January-to-spawning fisheries affect autumn SSB."),
  assumption_rows("model", "software", "SAM; HAWG 2026 production assessment",
    "ICES HAWG 2026, section 8",
    "The public source set does not include the applied 2026 fitted object or exact software build."),
  assumption_rows("model", "observation_error_weights", "unknown",
    "ICES HAWG 2026, section 8 and cached public source files",
    "The raw model data/run bundle needed to verify the exact fitted likelihood weights was not recovered."),
  assumption_rows("assessment_output", "confidence_intervals", "95% confidence intervals",
    "ICES HAWG 2026, Table 8.7.1.1 and ICES SAG key 21319",
    "Intervals are available for recruitment, total biomass, SSB and Fbar; not for catch or landings."),
  assumption_rows("stock_identity", "stock_mixing", "Manx and Mourne spawning groups; mixing with Celtic Sea herring is unresolved",
    "ICES HAWG 2026, section 8.1",
    "The report identifies mixed-stock concerns but does not quantify the contribution by age.")
))

stock <- pacific_database_row(
  "stocks", stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "her.27.nirs", scientific_name = "Clupea harengus",
  common_name = "Herring - Irish Sea north of 52°30'N",
  area = "ICES Division 7.a north of 52°30'N",
  region = "Irish Sea", ocean = "Northeast Atlantic",
  notes = "The stock complex comprises Manx and Mourne spawning groups; HAWG documents unquantified mixing with Celtic Sea herring."
)
assessment <- pacific_database_row(
  "assessments", assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = "2026 HAWG applied production run; exact build unavailable",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = report_url,
  data_url = source_data_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The 2026 HAWG assessment is the current applied SAM run with terminal year 2025.",
    "Report and ICES SAG data provide detailed age-specific inputs and aggregate outputs.",
    "The public sources do not provide the applied fitted object, exact observation-error weights,",
    "or fitted N-at-age and F-at-age arrays; survey timing and ISSS index scale remain unresolved."
  )
)

existing_stocks <- utils::read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
existing_assessments <- utils::read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (!stock_id %in% existing_stocks$stock_id && !assessment_id %in% existing_assessments$assessment_id) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
} else {
  if (sum(existing_stocks$stock_id == stock_id, na.rm = TRUE) != 1L ||
      sum(existing_assessments$assessment_id == assessment_id, na.rm = TRUE) != 1L) {
    stop("The Irish Sea herring stock and assessment are duplicated or only partly imported.", call. = FALSE)
  }
  inputs_existing <- utils::read.csv(file.path(database, "inputs.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  assumptions_existing <- utils::read.csv(file.path(database, "assumptions.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  outputs_existing <- utils::read.csv(file.path(database, "outputs.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (sum(inputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(inputs) ||
      sum(assumptions_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(assumptions) ||
      sum(outputs_existing$assessment_id == assessment_id, na.rm = TRUE) != nrow(outputs)) {
    stop("Existing Irish Sea herring rows differ from the verified source import.", call. = FALSE)
  }
}

replace_discovery_row <- function(path, row_index, row, key_column, key) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  existing <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  if (nrow(row) != 1L || !key_column %in% names(existing) ||
      !identical(as.character(existing[[key_column]][row_index]), key)) {
    stop("Discovery register row identity does not match ", key, call. = FALSE)
  }
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  record <- row_index + 1L
  first <- bounds$start[record]
  last <- bounds$end[record]
  next_byte <- last + 1L
  has_carriage_return <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_carriage_return <- TRUE
    next_byte <- next_byte + 1L
  }
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    line_ending <- c(if (has_carriage_return) as.raw(13L) else raw(0L), as.raw(10L))
    replacement <- c(replacement, line_ending)
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE),
    error = function(e) NULL)
  if (is.null(updated) || nrow(updated) != nrow(existing) ||
      sum(updated[[key_column]] == key, na.rm = TRUE) != 1L) {
    writeBin(original, path)
    stop("Discovery register update failed its identity or row-count check.", call. = FALSE)
  }
}

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected one Irish Sea herring candidate row.", call. = FALSE)
candidates$import_status[candidate_row] <- "partial"
candidates$review_date[candidate_row] <- "2026-11-03"
candidates$output_evidence[candidate_row] <- paste(
  "HAWG Table 8.7.1.1 and ICES SAG key 21319 provide annual recruitment, SSB, Fbar ages 2-4,",
  "total catch and 95% intervals through 2025. SAG additionally reports total biomass and landings.",
  "Fitted N-at-age and F-at-age arrays were not recovered."
)
if (!grepl("Imported report tables and ICES SAG outputs", candidates$notes[candidate_row], fixed = TRUE)) {
  candidates$notes[candidate_row] <- paste(
    candidates$notes[candidate_row],
    "Imported report tables and ICES SAG outputs; exact sampling-time fractions, ISSS index scale,",
    "native likelihood weights and age-specific fitted outputs remain unavailable."
  )
}
replace_candidate_register_row(candidate_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id)

inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
if (length(inventory_row) != 1L) stop("Expected one Irish Sea herring inventory row.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"
  replace_discovery_row(inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
    "unit_key", paste0("candidate:", candidate_unit_id))

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("Expected one selected Irish Sea herring row.", call. = FALSE)
selected$review_date[selected_row] <- "2026-11-03"
selected$curation_status[selected_row] <- "partial_source_import"
replace_discovery_row(selected_path, selected_row, selected[selected_row, , drop = FALSE],
  "candidate_id", candidate_id)

cat("Imported partial Irish Sea herring source records:", nrow(inputs), "inputs,",
    nrow(assumptions), "assumptions, and", nrow(outputs), "outputs.\n")
