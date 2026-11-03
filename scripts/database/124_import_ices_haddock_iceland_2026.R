root <- "."
cache_dir <- file.path(root, "source_cache", "ices_haddock_iceland_2026")
assessment_id <- "ices_haddock_iceland_2026"
stock_id <- "ices_haddock_iceland"
source_name <- "MFRI 2026 Icelandic haddock assessment tables and technical report"
tables_url <- "https://www.hafogvatn.is/static/extras/images/2_had_2026_1_tables_en.html"
report_url <- "https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html"
framework_url <- "https://doi.org/10.17895/ices.pub.28444499.v1"
html_path <- file.path(cache_dir, "2_had_2026_1_tables_en.html")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The source importer requires the suggested jsonlite package.", call. = FALSE)
}
if (!file.exists(html_path)) stop("Missing cached MFRI 2026 tables.", call. = FALSE)
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")

extract_widget <- function(id) {
  pattern <- paste0(
    '(?s)<div id="', id,
    '" class="section level3">\\s*<h3>([^<]+)</h3>.*?',
    '<script type="application/json" data-for="[^"]+">(.*?)</script>'
  )
  match <- regmatches(html, regexec(pattern, html, perl = TRUE))[[1]]
  if (length(match) != 3L) stop("Could not locate MFRI table: ", id, call. = FALSE)
  widget <- tryCatch(
    jsonlite::fromJSON(match[[3]], simplifyVector = FALSE)$x,
    error = function(error) stop("Could not parse MFRI table ", id, ": ",
      conditionMessage(error), call. = FALSE)
  )
  header_tags <- regmatches(widget$container,
    gregexpr("(?s)<th[^>]*>.*?</th>", widget$container, perl = TRUE))[[1]]
  headers <- trimws(gsub("(?s)<[^>]*>", "", header_tags, perl = TRUE))
  cell_value <- function(value) {
    if (is.null(value) || !length(value)) return(NA_character_)
    value <- unlist(value, recursive = TRUE, use.names = FALSE)
    if (!length(value)) NA_character_ else as.character(value[[1]])
  }
  columns <- lapply(widget$data, function(values) {
    vapply(values, cell_value, character(1))
  })
  if (length(headers) != length(columns)) {
    stop("MFRI table columns do not match its displayed headings: ", id, call. = FALSE)
  }
  out <- as.data.frame(columns, check.names = FALSE, stringsAsFactors = FALSE)
  names(out) <- headers
  out
}

as_number <- function(value) suppressWarnings(as.numeric(trimws(value)))
read_age_table <- function(id) {
  out <- extract_widget(id)
  out$Year <- as.integer(as_number(out$Year))
  age_columns <- as.character(1:12)
  if (!all(age_columns %in% names(out))) stop("Missing age columns in ", id, call. = FALSE)
  for (age in age_columns) out[[age]] <- as_number(out[[age]])
  if (anyNA(out$Year) || anyDuplicated(out$Year) ||
    any(!is.na(out$Species) & out$Species != "Haddock") ||
    any(!is.na(out$`Latin Name`) & out$`Latin Name` != "Melanogrammus aeglefinus")) {
    stop("Unexpected stock identity or years in MFRI table: ", id, call. = FALSE)
  }
  out
}
select_years <- function(table, years, name) {
  index <- match(years, table$Year)
  if (anyNA(index)) stop(name, " does not cover ", min(years), "-", max(years), call. = FALSE)
  table[index, , drop = FALSE]
}
age_matrix <- function(table, name, allow_missing = FALSE) {
  values <- as.matrix(table[as.character(1:12)])
  storage.mode(values) <- "numeric"
  if (!allow_missing && any(!is.finite(values))) {
    stop(name, " has missing or non-finite age values.", call. = FALSE)
  }
  if (any(values < 0, na.rm = TRUE)) stop(name, " has negative values.", call. = FALSE)
  values
}

years <- 1979:2026
input_years <- 1979:2025
ages <- 1:12
summary_table <- extract_widget("assessment-summary")
summary_table$Year <- as.integer(as_number(summary_table$Year))
summary_table <- select_years(summary_table, years, "Assessment summary")
catch_table <- select_years(read_age_table("catch-at-age"), input_years, "Catch-at-age")
catch_weight_table <- select_years(read_age_table("catch-weights"), input_years, "Catch weights")
stock_weight_table <- select_years(read_age_table("stock-weights"), years, "Stock weights")
maturity_table <- select_years(read_age_table("maturity-at-age"), years, "Maturity")
smb_table <- select_years(read_age_table("is-smb-index"), 1985:2026, "IS-SMB")
smh_table <- select_years(read_age_table("is-smh-index"), 1995:2025, "IS-SMH")
n_table <- select_years(read_age_table("stock-in-numbers"), years, "Stock numbers-at-age")
f_table <- select_years(read_age_table("fishing-mortality"), input_years, "Fishing mortality-at-age")

catch <- age_matrix(catch_table, "Catch-at-age")
catch_weight <- age_matrix(catch_weight_table, "Catch weights")
stock_weight <- age_matrix(stock_weight_table, "Stock weights")
maturity <- age_matrix(maturity_table, "Maturity")
smb <- age_matrix(smb_table, "IS-SMB", allow_missing = TRUE)
smh <- age_matrix(smh_table, "IS-SMH", allow_missing = TRUE)
n_at_age <- age_matrix(n_table, "Stock numbers-at-age")
f_at_age <- age_matrix(f_table, "Fishing mortality-at-age")
summary_values <- lapply(c("SSB", "Low SSB", "High SSB", "Ref. Biomass",
  "Low Ref. Biomass", "High Ref. Biomass", "Recruitment", "Low Recruitment",
  "High Recruitment"), function(name) as_number(summary_table[[name]]))
names(summary_values) <- c("ssb", "low_ssb", "high_ssb", "reference_biomass",
  "low_reference_biomass", "high_reference_biomass", "recruitment",
  "low_recruitment", "high_recruitment")
if (any(!vapply(summary_values, function(x) all(is.finite(x)), logical(1))) ||
  any(maturity < 0 | maturity > 1) || any(catch_weight <= 0) ||
  any(stock_weight <= 0) || any(n_at_age <= 0)) {
  stop("MFRI 2026 assessment values failed range checks.", call. = FALSE)
}

source_reference <- function(table) paste(source_name, table, sep = ", ")
input_row <- function(type, measure, basis, survey = "", season = "",
                      year, age, value, unit, reference, notes = "",
                      transformation = "", sampling_time = NA_real_,
                      source_type = "official_table") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = "", survey = survey, sex = "combined", region = "ICES 5.a",
    season = season, year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
    value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = reference,
    transformation = transformation, notes = notes, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = NA_real_, stringsAsFactors = FALSE
  )
}
age_inputs <- function(type, measure, basis, source_years, values, unit,
                       reference, notes = "", transformation = "",
                       survey = "", season = "", sampling_time = NA_real_,
                       allow_missing = FALSE) {
  grid <- expand.grid(year = source_years, age = ages)
  grid$value <- as.vector(values)
  if (!allow_missing && any(!is.finite(grid$value))) {
    stop("Unexpected missing values for ", reference, call. = FALSE)
  }
  grid <- grid[is.finite(grid$value), , drop = FALSE]
  input_row(type, measure, basis, survey = survey, season = season,
    year = grid$year, age = grid$age, value = grid$value, unit = unit,
    reference = reference, notes = notes, transformation = transformation,
    sampling_time = sampling_time)
}
static_m <- input_row(
  "M", "natural_mortality_at_age", "per_year", year = NA_real_, age = ages,
  value = rep(0.2, length(ages)), unit = "per year",
  reference = source_reference("MFRI 2026 technical report, assessment methods"),
  notes = "Natural mortality is fixed at 0.2 per year for ages 1-12 and all years.",
  source_type = "official_document"
)

inputs_add <- rbind(
  age_inputs("catch", "numbers_at_age", "numbers", input_years, catch,
    "thousand fish", source_reference("Catch in numbers at age"),
    notes = "Commercial catch numbers-at-age in thousands; age 12 is the 12+ group."),
  age_inputs("catch_weight", "weight_at_age", "kg_per_fish", input_years, catch_weight,
    "g per fish", source_reference("Catch-weights"),
    notes = "Catch weight-at-age in grams per fish. The source table lists 4,000 g for every age in 2026, while no 2026 catch-at-age is reported. Its role in projections is unspecified, so it is excluded from the fitted catch-weight series.",
    transformation = "Use years 1979-2025; exclude the uniform 2026 4,000-g row because no 2026 catch-at-age is reported and its projection role is unspecified."),
  age_inputs("weight", "weight_at_age", "kg_per_fish", years, stock_weight,
    "g per fish", source_reference("Stock-weights"),
    notes = "Stock weight-at-age in grams per fish. Pre-1985 values use the 1985 age vector."),
  age_inputs("maturity", "maturity_at_age", "proportion", years, maturity,
    "proportion mature", source_reference("Maturity at age"),
    notes = "Proportion mature at age. Pre-1985 values use the 1985 age vector."),
  age_inputs("index", "numbers_at_age", "index_scale", 1985:2026, smb,
    "survey index (unit unresolved)", source_reference("IS-SMB index"),
    notes = "Age-disaggregated March groundfish survey index. The source labels values as numbers but does not specify a physical unit; 0.20 is a month-midpoint approximation.",
    survey = "IS-SMB", season = "spring", sampling_time = 0.20,
    allow_missing = TRUE),
  age_inputs("index", "numbers_at_age", "index_scale", 1995:2025, smh,
    "survey index (unit unresolved)", source_reference("IS-SMH index"),
    notes = "Age-disaggregated October groundfish survey index. The source labels values as numbers but does not specify a physical unit; 0.80 is a month-midpoint approximation.",
    survey = "IS-SMH", season = "autumn", sampling_time = 0.80,
    allow_missing = TRUE),
  static_m
)

output_row <- function(type, measure, year, age = NA_real_, value, unit,
                       reference, notes = "", lwr = NA_real_, upr = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "combined", region = "ICES 5.a", season = "",
    year = year, age = age,
    age_group = ifelse(!is.na(age) & age == 12, "12+", ""),
    value = value, se = NA_real_, lwr = lwr, upr = upr, unit = unit,
    source_type = "official_table", source_reference = reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
age_outputs <- function(measure, source_years, values, unit, reference, notes) {
  grid <- expand.grid(year = source_years, age = ages)
  grid$value <- as.vector(values)
  output_row(if (measure == "numbers_at_age") "population" else "mortality",
    measure, grid$year, grid$age, grid$value, unit, reference, notes)
}
summary_year <- summary_table$Year
outputs_add <- rbind(
  age_outputs("numbers_at_age", years, n_at_age, "thousand fish",
    source_reference("Stock in numbers"),
    "Official abundance-at-age estimates in thousands; age 12 is the 12+ group."),
  age_outputs("fishing_mortality_at_age", input_years, f_at_age, "per year",
    source_reference("Fishing mortality"),
    "Official fishing mortality-at-age; age 12 is the 12+ group."),
  output_row("biomass", "SSB", summary_year,
    value = summary_values$ssb, unit = "tonnes",
    reference = source_reference("Assessment summary"),
    notes = "Published spawning-stock biomass. Low/high values are retained as reported; interval coverage is not specified in the table. The official SSB applies pre-spawning mortality fractions F=0.4 and M=0.3; tinyAM comparisons use a separately labelled common-definition mature biomass.",
    lwr = summary_values$low_ssb, upr = summary_values$high_ssb),
  output_row("biomass", "reference_biomass", summary_year,
    value = summary_values$reference_biomass, unit = "tonnes",
    reference = source_reference("Assessment summary"),
    notes = "Published biomass of fish at least 45 cm; low/high interval coverage is not specified. This length-based quantity is not directly comparable with tinyAM age-based biomass.",
    lwr = summary_values$low_reference_biomass,
    upr = summary_values$high_reference_biomass),
  output_row("recruitment", "recruitment", summary_year, age = 1,
    value = summary_values$recruitment, unit = "thousand fish",
    reference = source_reference("Assessment summary"),
    notes = "Age-1 recruitment in thousands; low/high interval coverage is not specified in the table.",
    lwr = summary_values$low_recruitment, upr = summary_values$high_recruitment)
)

paths <- setNames(file.path(root, "database", paste0(
  c("stocks", "assessments", "assumptions", "inputs", "outputs"), ".csv")),
  c("stocks", "assessments", "assumptions", "inputs", "outputs"))
read_db <- function(name) read.csv(paths[[name]], stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = "")
read_ids <- function(name) {
  n_columns <- ncol(read.csv(paths[[name]], nrows = 0, check.names = FALSE))
  read.csv(paths[[name]], colClasses = c("character", rep("NULL", n_columns - 1L)),
    stringsAsFactors = FALSE, check.names = FALSE)$assessment_id
}
assessments <- read_db("assessments")
assumptions <- read_db("assumptions")
if (sum(assessments$assessment_id == assessment_id) != 1L ||
  length(read_ids("inputs")[read_ids("inputs") == assessment_id]) > 0L ||
  length(read_ids("outputs")[read_ids("outputs") == assessment_id]) > 0L) {
  stop("Expected one registered 2026 assessment with no age-series rows yet.", call. = FALSE)
}
if (!all(c("M", "weight", "catch_weight", "maturity", "index") %in% inputs_add$type) ||
  nrow(inputs_add) < 3000L || nrow(outputs_add) != 1284L ||
  any(!is.finite(inputs_add$value)) || any(!is.finite(outputs_add$value)) ||
  any(inputs_add$value[inputs_add$type == "maturity"] > 1) ||
  any(inputs_add$value[inputs_add$type == "M"] != 0.2)) {
  stop("Icelandic haddock 2026 rows failed coverage or value checks.", call. = FALSE)
}

assessments$is_current[assessments$stock_id == stock_id] <- FALSE
assessments$is_current[assessments$assessment_id == assessment_id] <- TRUE
ix <- which(assessments$assessment_id == assessment_id)
assessments$terminal_year[ix] <- 2026L
assessments$estimate_terminal_year[ix] <- 2026L
assessments$assessment_url[ix] <- report_url
assessments$data_url[ix] <- tables_url
assessments$framework_url[ix] <- framework_url
assessments$assumptions_status[ix] <- "partial"
assessments$inputs_status[ix] <- "partial"
assessments$outputs_status[ix] <- "partial"
assessments$notes[ix] <- paste(
  "Most recent detailed official assessment; numerical 2026 tables provide catch-at-age through 2025, surveys and biological surfaces through 2026, abundance estimates through 2026, and fishing mortality-at-age through 2025. Assumptions and outputs remain partial because SAM process covariance, parameter sharing, age-specific uncertainty, and the summary interval coverage are not fully published. The uniform 2026 catch-weight placeholder row is excluded."
)

ix <- assumptions$assessment_id == assessment_id
assumptions$source_reference[ix] <- paste(
  "MFRI 2026 technical report; assessment tables; ICES WKICEGAD 2025"
)
assumptions$notes[ix] <- paste(
  "Describes the 2026 SAM assessment using the 2025 benchmark framework. The annual report does not provide all process covariance and parameter-sharing details; survey timings in the database remain month-midpoint approximations."
)
assumptions$notes[ix & assumptions$component == "survey_timing" & assumptions$survey == "IS-SMB"] <-
  "The survey is conducted in March; 0.20 is a month-midpoint approximation, not a verified SAM sampling fraction."
assumptions$notes[ix & assumptions$component == "survey_timing" & assumptions$survey == "IS-SMH"] <-
  "The survey is conducted in October; 0.80 is a month-midpoint approximation, not a verified SAM sampling fraction."

append_rows <- function(path, rows) {
  columns <- names(read.csv(path, nrows = 0, check.names = FALSE))
  if (!setequal(names(rows), columns)) stop("Column mismatch: ", basename(path), call. = FALSE)
  utils::write.table(rows[columns], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}
utils::write.csv(assessments, paths[["assessments"]], row.names = FALSE, na = "")
utils::write.csv(assumptions, paths[["assumptions"]], row.names = FALSE, na = "")
append_rows(paths[["inputs"]], inputs_add)
append_rows(paths[["outputs"]], outputs_add)
cat("Updated Icelandic haddock 2026: ", nrow(inputs_add), " inputs, ",
  nrow(outputs_add), " outputs; the 2026 record is now current.\n", sep = "")
