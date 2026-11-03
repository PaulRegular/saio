assessment_id <- "ices_sole_north_sea_2025"
summary_id <- "ices_sole_north_sea_2026_summary"
stock_id <- "ck_ices_wgnssk_solea_ns_4"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ices_sole_north_sea_2025")
report_file <- file.path(cache, "wgnssk_2025_sole_4.txt")
report_url <- "https://doi.org/10.17895/ices.pub.29085995.v4"
framework_url <- "https://doi.org/10.17895/ices.pub.25471987.v1"
sag_2025_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21217"
sag_2026_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23777"

if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("Install xml2 to import the official ICES SAG series.", call. = FALSE)
}
if (!file.exists(report_file) || any(!file.exists(file.path(cache, c(
  "ices_sag_2025_stock.xml", "ices_sag_2026_stock.xml"
))))) {
  stop("The cached ICES reports and SAG XML files are required.", call. = FALSE)
}

report <- readLines(report_file, warn = FALSE)
table_captions <- grep("^\\s*Table\\s+16\\.[0-9]+[a-z]?\\.", report, perl = TRUE)

read_report_table <- function(table, years, ages) {
  pattern <- paste0(
    "^\\s*Table\\s+", gsub(".", "[.]", table, fixed = TRUE), "\\."
  )
  start <- grep(pattern, report, perl = TRUE)
  if (length(start) != 1L) {
    stop("Expected one caption for Table ", table, ".", call. = FALSE)
  }
  end <- min(table_captions[table_captions > start], length(report) + 1L)
  block <- report[start:(end - 1L)]
  lines <- block[grepl("^\\s*(19|20)[0-9]{2}", block, perl = TRUE)]
  parsed <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1]]
    year <- as.integer(gsub("[^0-9].*$", "", tokens[[1]]))
    values <- suppressWarnings(as.numeric(gsub("[*†‡]$", "", tokens[-1])))
    if (length(values) != length(ages) || anyNA(values)) {
      stop("Unexpected values in Table ", table, ": ", line, call. = FALSE)
    }
    c(year = year, values)
  })
  values <- do.call(rbind, parsed)
  if (!identical(as.integer(values[, "year"]), as.integer(years))) {
    stop("Unexpected year coverage in Table ", table, ".", call. = FALSE)
  }
  if (anyDuplicated(values[, "year"])) {
    stop("Duplicate years in Table ", table, ".", call. = FALSE)
  }
  result <- data.frame(year = as.integer(values[, "year"]), values[, -1L, drop = FALSE],
    check.names = FALSE, row.names = NULL
  )
  names(result)[-1L] <- ifelse(is.na(ages), "total", as.character(ages))
  result
}

read_biology_table <- function() {
  start <- grep("^\\s*Table\\s+16\\.7\\.", report, perl = TRUE)
  if (length(start) != 1L) stop("Expected one Table 16.7 caption.", call. = FALSE)
  end <- min(table_captions[table_captions > start], length(report) + 1L)
  lines <- report[start:(end - 1L)]
  lines <- lines[grepl("^\\s*[0-9]+\\+?\\s+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1]]
    age <- as.integer(gsub("[^0-9].*$", "", tokens[[1]]))
    values <- suppressWarnings(as.numeric(tokens[-1]))
    if (length(values) != 2L || anyNA(values)) {
      stop("Unexpected values in Table 16.7: ", line, call. = FALSE)
    }
    c(age = age, maturity = values[[1]], M = values[[2]])
  })
  values <- do.call(rbind, rows)
  if (!identical(as.integer(values[, "age"]), 0:10)) {
    stop("Table 16.7 must cover ages 0 through 10+.", call. = FALSE)
  }
  as.data.frame(values, row.names = NULL)
}

as_long <- function(table, ages) {
  if (length(ages) != ncol(table) - 1L) stop("Age labels do not match table columns.")
  data.frame(
    year = rep(table$year, times = length(ages)),
    age = rep(ages, each = nrow(table)),
    value = as.vector(as.matrix(table[ifelse(is.na(ages), "total", as.character(ages))])),
    stringsAsFactors = FALSE
  )
}

landings <- read_report_table("16.2", 1957:2024, 1:10)
discards <- read_report_table("16.3", 2002:2024, 1:10)
landings_weight <- read_report_table("16.4", 1957:2024, 1:10)
discard_weight <- read_report_table("16.5", 1957:2024, 0:10)
stock_weight <- read_report_table("16.6", 1957:2024, 0:10)
bts_age <- read_report_table("16.8a", 1990:2024, 0:10)
bts_total <- read_report_table("16.8b", 1990:2024, NA_integer_)
coast_age <- read_report_table("16.9a", 1990:2024, 0:5)
coast_total <- read_report_table("16.9b", 1990:2024, NA_integer_)
numbers <- read_report_table("16.10", 1957:2024, 0:10)
fishing_mortality <- read_report_table("16.11", 1957:2024, 1:10)
biology <- read_biology_table()

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", season = "",
                       sampling_time = NA_real_, source_reference,
                       transformation = "Copied from the official report.", notes = "") {
  n <- length(value)
  recycle <- function(x) rep_len(x, n)
  years <- recycle(year)
  data.frame(
    assessment_id = assessment_id, type = recycle(type), measure = recycle(measure),
    basis = recycle(basis), fleet = recycle(fleet), survey = recycle(survey),
    sex = "", region = "", season = recycle(season), year = years,
    year_basis = ifelse(is.na(years), "", "calendar_year"), age = recycle(age),
    value = as.numeric(value), unit = recycle(unit),
    sampling_time = recycle(sampling_time), source_type = "official_table",
    source_reference = recycle(source_reference), transformation = recycle(transformation),
    notes = recycle(notes), observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = "", partition = "", stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch_rows <- rbind(
  within(as_long(landings, 1:10), {
    fleet <- "Landings"
    notes <- "Landings numbers in thousands; age 10 is the 10+ group. Age 0 is not reported."
  }),
  within(as_long(discards, 1:10), {
    fleet <- "Discards"
    notes <- "Discard numbers in thousands; age 10 is the 10+ group. Age 0 is not reported."
  })
)

catch_inputs <- do.call(rbind, list(
  input_rows(
    "catch", "numbers_at_age", "numbers", catch_rows$year, catch_rows$age,
    catch_rows$value, "thousand fish", fleet = catch_rows$fleet,
    source_reference = paste0(report_url, "; Tables 16.2 and 16.3"),
    notes = catch_rows$notes
  )
))

landings_weight_long <- as_long(landings_weight, 1:10)
landings_weight_long <- rbind(
  data.frame(year = 1957:2024, age = 0L, value = 0.01),
  landings_weight_long
)
inputs <- list(
  catch_inputs,
  input_rows(
    "catch_weight", "landings_weight_at_age", "kg_per_fish",
    landings_weight_long$year, landings_weight_long$age, landings_weight_long$value,
    "kg per fish", fleet = "Landings",
    source_reference = paste0(report_url, "; Table 16.4"),
    transformation = "Copied the report's age 1-10+ values; age 0 was set to the explicitly reported constant 0.01 kg for all years.",
    notes = "Age 10 is the 10+ group."
  ),
  input_rows(
    "catch_weight", "discard_weight_at_age", "kg_per_fish",
    as_long(discard_weight, 0:10)$year, as_long(discard_weight, 0:10)$age,
    as_long(discard_weight, 0:10)$value, "kg per fish", fleet = "Discards",
    source_reference = paste0(report_url, "; Table 16.5"),
    notes = "Age 10 is the 10+ group."
  ),
  input_rows(
    "weight", "weight_at_age", "kg_per_fish",
    as_long(stock_weight, 0:10)$year, as_long(stock_weight, 0:10)$age,
    as_long(stock_weight, 0:10)$value, "kg per fish",
    source_reference = paste0(report_url, "; Table 16.6"),
    notes = "Mid-year stock weights used by SS3 at the beginning and end of the spawning season; age 10 is the 10+ group."
  ),
  input_rows(
    "maturity", "maturity_at_age", "proportion", NA_integer_, biology$age,
    biology$maturity, "proportion",
    source_reference = paste0(report_url, "; Table 16.7"),
    notes = "Time-invariant knife-edge maturity: ages 0-2 immature and age 3+ mature."
  ),
  input_rows(
    "M", "natural_mortality_at_age", "per_year", NA_integer_, biology$age,
    biology$M, "per year",
    source_reference = paste0(report_url, "; Table 16.7; ", framework_url),
    notes = "Fixed in SS3; age-specific values follow the size-based Lorenzen formulation and are not estimated as a time series."
  )
)

survey_age_rows <- function(table, ages, survey, table_id, note) {
  values <- as_long(table, ages)
  input_rows(
    "index", "numbers_at_age", "index_scale", values$year, values$age,
    values$value, "source relative-index units (multiplier not stated)",
    survey = survey, season = "Q3", sampling_time = 0.625,
    source_reference = paste0(report_url, "; Table ", table_id),
    transformation = "Copied the standardized age-specific index values without rescaling.",
    notes = paste(note, "Age 10 is the 10+ group where present.")
  )
}

survey_total_rows <- function(table, survey, table_id, note) {
  values <- as_long(table, NA_integer_)
  input_rows(
    "index", "relative_biomass_index", "index_scale", values$year, NA_integer_,
    values$value, "source relative-index units (multiplier not stated)",
    survey = survey, season = "Q3", sampling_time = 0.625,
    source_reference = paste0(report_url, "; Table ", table_id),
    transformation = "Copied the reported aggregate survey index without rescaling.",
    notes = note
  )
}

inputs[[length(inputs) + 1L]] <- survey_age_rows(
  bts_age, 0:10, "BTS Q3", "16.8a",
  "Delta-lognormal GAM-standardized relative abundance at age from the international BTS survey."
)
inputs[[length(inputs) + 1L]] <- survey_total_rows(
  bts_total, "BTS Q3", "16.8b",
  "The assessment report also identifies aggregate survey biomass indices as model inputs. These aggregate values closely match the rounded sums of the at-age index table; preserve them as a separate source series, but do not fit both series in tinyAM without resolving their dependence."
)
inputs[[length(inputs) + 1L]] <- survey_age_rows(
  coast_age, 0:5, "COAST (SNS + DYFS)", "16.9a",
  "Delta-lognormal GAM-standardized relative abundance at ages 0-5 from combined SNS and DYFS samples."
)
inputs[[length(inputs) + 1L]] <- survey_total_rows(
  coast_total, "COAST (SNS + DYFS)", "16.9b",
  "The assessment report also identifies aggregate survey biomass indices as model inputs. These aggregate values closely match the rounded sums of the at-age index table; preserve them as a separate source series, but do not fit both series in tinyAM without resolving their dependence."
)

inputs <- do.call(rbind, inputs)

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                             fleet = "", survey = "", season = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = "", region = "", season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}
assumptions <- do.call(rbind, list(
  assumption_rows("assessment", "model_family", "Stock Synthesis 3", report_url, "Reference model introduced at the 2024 WKBFLATFISH benchmark and updated in the 2025 WGNSSK assessment."),
  assumption_rows("population", "model_structure", "Single area; single sex; ages 0-10+", report_url, "Age 10 is the plus group; recruitment enters at age 0 at the beginning of the year."),
  assumption_rows("population", "terminal_year", "2024; 2025 forecast", report_url, "The 2025 assessment uses data through 2024 and reports a 2025 forecast in the ICES SAG series."),
  assumption_rows("population", "stock_recruitment", "Beverton-Holt; fixed steepness h=0.6646", report_url, "Steepness was taken from FishLife correlations for Solea solea; it was not estimated in the production assessment."),
  assumption_rows("population", "spawning_stock_biomass_timing", "Start of year", report_url, "Fecundity is assumed proportional to individual weight."),
  assumption_rows("F", "fleets", "Landings and discards", report_url, "Two fleets are represented in the SS3 model."),
  assumption_rows("F", "selectivity", "Landings time-varying random walk; discards time-invariant; both constant from age 5", report_url, "The tinyAM translation approximates the landings selectivity process through its available F process settings."),
  assumption_rows("index", "surveys", "BTS Q3 and COAST (SNS + DYFS) Q3", report_url, "BTS ages 0-10+; COAST ages 0-5. SNS and DYFS are combined into the COAST index."),
  assumption_rows("index", "age_specific_index_model", "Delta-lognormal GAM-standardized indices", report_url, "The report describes age-specific abundance indices and aggregate survey-biomass indices as model inputs. Aggregate series are retained separately; their dependence on age-specific indices is unresolved."),
  assumption_rows("index", "survey_timing", "Q3 represented as 0.625", report_url, "Both indices are labelled Q3 in the assessment documentation; 0.625 is the quarter midpoint used by tinyAM."),
  assumption_rows("index", "catchability_age_groups", "Survey q constant from age 5", report_url, "The source model sets survey catchability constant for ages 5 and older."),
  assumption_rows("biology", "age_reading_error", "Time-invariant 2016 exchange matrix", report_url, "The 2025 assessment retains the 2016 age-reading error matrix. The numerical matrix was not recoverable from the cached source tables."),
  assumption_rows("M", "natural_mortality", "Fixed age-specific Lorenzen formulation; not estimated", paste0(report_url, "; ", framework_url), "M_a follows W_a^-0.288 and is scaled using the maximum validated age of 26; annual rates are in inputs.csv."),
  assumption_rows("F", "Fbar_ages", "2-6", report_url, "The annual ICES SAG fishing-pressure output is the mean F over ages 2-6."),
  assumption_rows("assessment", "native_model_files", "not recovered", "ICES TAF/GitHub searches; WGNSSK 2025 report", "The canonical import uses the detailed official report tables and ICES SAG XML. No matching public 2025 SS3 input/output archive was identified in the checked ICES repositories.")
))

read_sag_outputs <- function(path, assessment_id, assessment_year, terminal_year, source_url) {
  document <- xml2::read_xml(path)
  root <- xml2::xml_find_first(document, "/Assessment")
  text_at <- function(node, name) {
    value <- xml2::xml_text(xml2::xml_find_first(node, paste0("./", name)))
    if (!length(value) || !nzchar(value)) NA_character_ else value
  }
  numeric_at <- function(node, name) {
    value <- text_at(node, name)
    if (is.na(value)) NA_real_ else suppressWarnings(as.numeric(value))
  }
  if (text_at(root, "StockCode") != "sol.27.4" ||
    as.integer(text_at(root, "AssessmentYear")) != assessment_year ||
    text_at(root, "ConfidenceIntervalDefinition") != "2*sd") {
    stop("The cached ICES SAG XML is not the expected assessment.", call. = FALSE)
  }
  fish_data <- xml2::xml_find_all(root, "./Fish_Data")
  specs <- list(
    list(type = "recruitment", measure = "recruitment", field = "Recruitment",
      low = "Low_Recruitment", high = "High_Recruitment", unit = "thousand fish"),
    list(type = "biomass", measure = "SSB", field = "StockSize",
      low = "Low_StockSize", high = "High_StockSize", unit = "tonnes"),
    list(type = "mortality", measure = "Fbar", field = "FishingPressure",
      low = "Low_FishingPressure", high = "High_FishingPressure", unit = "per year")
  )
  rows <- list()
  for (node in fish_data) {
    year <- as.integer(text_at(node, "Year"))
    for (spec in specs) {
      estimate <- numeric_at(node, spec$field)
      if (!is.finite(estimate)) next
      low <- numeric_at(node, spec$low)
      high <- numeric_at(node, spec$high)
      note <- paste0(
        "ICES Stock Assessment Graphs assessment year ", assessment_year,
        "; confidence bounds are reported as mean +/- 2 SD."
      )
      if (year > terminal_year) note <- paste(note, "Forecast year.")
      rows[[length(rows) + 1L]] <- data.frame(
        assessment_id = assessment_id, type = spec$type, measure = spec$measure,
        fleet = "", survey = "", sex = "", region = "", season = "",
        year = year, age = NA_integer_, age_group = if (spec$measure == "Fbar") "2-6" else "", value = estimate,
        se = NA_real_, lwr = low, upr = high, unit = spec$unit,
        source_type = "official_machine_readable",
        source_reference = paste0(source_url, "; ICES SAG XML assessment key ",
          if (assessment_year == 2025) "21217" else "23777"),
        notes = note, stringsAsFactors = FALSE, check.names = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

summary_2025 <- read_sag_outputs(
  file.path(cache, "ices_sag_2025_stock.xml"), assessment_id, 2025L, 2024L,
  sag_2025_url
)
summary_2026 <- read_sag_outputs(
  file.path(cache, "ices_sag_2026_stock.xml"), summary_id, 2026L, 2025L,
  sag_2026_url
)

age_outputs <- function(table, ages, measure, type, unit, source_reference, notes) {
  values <- as_long(table, ages)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = values$year, age = values$age,
    age_group = ifelse(values$age == max(ages), paste0(max(ages), "+"), ""),
    value = values$value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

outputs <- rbind(
  age_outputs(numbers, 0:10, "numbers_at_age", "population", "thousand fish",
    paste0(report_url, "; Table 16.10"), "SS3 stock numbers at age; age 10 is the 10+ group. The report gives point estimates only."),
  age_outputs(fishing_mortality, 1:10, "fishing_mortality_at_age", "mortality", "per year",
    paste0(report_url, "; Table 16.11"), "SS3 annual fishing mortality at age; age 10 is the 10+ group. The report gives point estimates only."),
  summary_2025, summary_2026
)

stocks_file <- file.path(database, "stocks.csv")
assessments_file <- file.path(database, "assessments.csv")
assumptions_file <- file.path(database, "assumptions.csv")
inputs_file <- file.path(database, "inputs.csv")
outputs_file <- file.path(database, "outputs.csv")
stocks <- read.csv(stocks_file, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- read.csv(assessments_file, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assumptions_existing <- read.csv(assumptions_file, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
inputs_existing <- read.csv(inputs_file, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
outputs_existing <- read.csv(outputs_file, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L || any(c(assessment_id, summary_id) %in% assessments_existing$assessment_id)) {
  stop("Expected one catalogue stock and no existing North Sea sole assessment records.", call. = FALSE)
}
stocks$common_name[stock_row] <- "North Sea sole"
stocks$authority_stock_id[stock_row] <- "sol.27.4"
stocks$area[stock_row] <- "ICES Subarea 4"
stocks$region[stock_row] <- "North Sea"
stocks$notes[stock_row] <- paste(
  "Charbonneau-Keith catalogue stock matched to ICES stock sol.27.4.",
  "Detailed 2025 WGNSSK production assessment and separate 2026 summary-only advice outputs are recorded; see source review for scope and limitations."
)

assessment_rows <- data.frame(
  assessment_id = c(assessment_id, summary_id), stock_id = stock_id,
  assessment_year = c(2025L, 2026L), terminal_year = c(2024L, 2025L),
  estimate_terminal_year = c(2025L, 2026L),
  assessment_type = c("annual_assessment", "summary_update"),
  model_family = c("Stock Synthesis", ""),
  model_version = c("Stock Synthesis 3 reference model", ""),
  is_current = c(TRUE, FALSE), is_applied = c(TRUE, TRUE),
  framework_year = c(2024L, NA_integer_),
  assessment_url = c(report_url, "https://standardgraphs.ices.dk/ViewCharts.aspx?key=23777"),
  framework_url = c(framework_url, ""),
  data_url = c(sag_2025_url, sag_2026_url),
  model_url = c("", ""), repository_url = c("", ""),
  assumptions_status = c("partial", "not_started"),
  inputs_status = c("partial", "not_started"),
  outputs_status = c("partial", "partial"),
  notes = c(
    "The 2025 production assessment uses data through 2024 and reports a 2025 forecast. Inputs and age-specific outputs are transcribed from the official WGNSSK report; aggregate annual summaries and intervals are from ICES SAG. Some native likelihood weights, numeric age-reading-error inputs, and native SS3 files were not recovered.",
    "ICES SAG lists official 2026 advice and annual aggregate summaries through 2026. No detailed 2026 inputs or model configuration were recovered; 2025 remains the latest detailed assessment. The 2026 forecast row reports recruitment and SSB but no F."
  ), stringsAsFactors = FALSE, check.names = FALSE
)

if (anyDuplicated(paste(inputs$assessment_id, inputs$type, inputs$measure,
  inputs$fleet, inputs$survey, inputs$year, inputs$age, sep = "\r"))) {
  stop("The import contains duplicate assessment input keys.", call. = FALSE)
}
if (anyDuplicated(paste(outputs$assessment_id, outputs$type, outputs$measure,
  outputs$year, outputs$age, sep = "\r"))) {
  stop("The import contains duplicate assessment output keys.", call. = FALSE)
}
if (any(!is.finite(inputs$value)) || any(inputs$value < 0) || any(!is.finite(outputs$value))) {
  stop("Imported observations and estimates must be finite and non-negative.", call. = FALSE)
}

assessments <- rbind(assessments_existing, assessment_rows)
assumptions <- rbind(assumptions_existing, assumptions)
inputs <- rbind(inputs_existing, inputs)
outputs <- rbind(outputs_existing, outputs)

write_stock_row <- function(path, row, stock_id) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  line_starts <- c(1L, line_feeds + 1L)
  line_ends <- c(line_feeds - 1L, length(bytes))
  line_starts <- line_starts[line_starts <= length(bytes)]
  line_ends <- line_ends[seq_along(line_starts)]
  content_ends <- line_ends
  carriage_returns <- content_ends > 0L & bytes[content_ends] == as.raw(13L)
  content_ends[carriage_returns] <- content_ends[carriage_returns] - 1L
  prefix <- charToRaw(paste0("\"", stock_id, "\""))
  row_index <- which(vapply(seq_along(line_starts), function(i) {
    end <- line_starts[i] + length(prefix) - 1L
    end <= content_ends[i] && identical(bytes[line_starts[i]:end], prefix)
  }, logical(1)))
  if (length(row_index) != 1L) stop("Expected one raw stock row.", call. = FALSE)
  temp <- tempfile(fileext = ".csv")
  on.exit(unlink(temp), add = TRUE)
  write.csv(row, temp, row.names = FALSE, na = "")
  serialized <- readLines(temp, warn = FALSE)
  if (length(serialized) != 2L) stop("The revised stock row is not a single CSV line.", call. = FALSE)
  before <- if (line_starts[row_index] > 1L) bytes[seq_len(line_starts[row_index] - 1L)] else raw()
  after_start <- content_ends[row_index] + 1L
  after <- if (after_start <= length(bytes)) bytes[after_start:length(bytes)] else raw()
  writeBin(c(before, charToRaw(serialized[[2L]]), after), path)
}

write_stock_row(stocks_file, stocks[stock_row, , drop = FALSE], stock_id)
write.csv(assessments, assessments_file, row.names = FALSE, na = "")
write.csv(assumptions, assumptions_file, row.names = FALSE, na = "")
write.csv(inputs, inputs_file, row.names = FALSE, na = "")
write.csv(outputs, outputs_file, row.names = FALSE, na = "")

cat("Imported North Sea sole 2025 detailed assessment and 2026 summary outputs.\n")
cat("Inputs:", nrow(inputs) - nrow(inputs_existing), "Outputs:", nrow(outputs) - nrow(outputs_existing), "Assumptions:", nrow(assumptions) - nrow(assumptions_existing), "\n")