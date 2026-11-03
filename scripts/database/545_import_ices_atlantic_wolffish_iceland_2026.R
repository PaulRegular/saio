root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_iceland_wolffish_2026")
assessment_id <- "ices_atlantic_wolffish_iceland_2026"
stock_id <- "ices_atlantic_wolffish_iceland_5a"
candidate_id <- "ICES:caa.27.5a"
candidate_unit_id <- "ices_atlantic_wolffish_iceland_5a"

if (!dir.exists(cache)) stop("The reviewed wolffish source cache is missing.", call. = FALSE)
source(file.path(root, "scripts", "database", "pacific_tables.R"))

sha256_file <- function(path) {
  result <- system2(
    "certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256"),
    stdout = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify SHA-256 for ", path, call. = FALSE)
  hashes
}

source_map <- data.frame(
  file = c(
    "wolffish_5a_tables_2026.html",
    "catch_numbers_at_age_2026.csv",
    "catch_weight_at_age_2026.csv",
    "stock_weight_at_age_2026.csv",
    "maturity_at_age_2026.csv",
    "spring_survey_index_at_age_2026.csv",
    "autumn_survey_index_at_age_2026.csv",
    "stock_numbers_at_age_2026.csv",
    "fishing_mortality_at_age_2026.csv",
    "assessment_summary_2026.csv",
    "landings_2026.csv",
    "ices_source_data_22633_2026.csv"
  ),
  url = c(
    rep("https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_tables_en.html", 11L),
    "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22633"
  ),
  revision = c(
    "MFRI 2026 tables page, retrieved 2026-11-03",
    "MFRI 2026 table export: Catch at age",
    "MFRI 2026 table export: Catch-weights",
    "MFRI 2026 table export: Stock-weights",
    "MFRI 2026 table export: Maturity at age",
    "MFRI 2026 table export: IS-SMB index",
    "MFRI 2026 table export: IS-SMH index",
    "MFRI 2026 table export: Stock in numbers",
    "MFRI 2026 table export: Fishing mortality",
    "MFRI 2026 table export: Assessment summary",
    "MFRI 2026 table export: Landings",
    "ICES assessment key 22633 source-data table, retrieved 2026-11-03"
  ),
  status = c("cached", rep("derived_local", 11L)),
  notes = c(
    "Official MFRI table page for the assessment year 2026.",
    "Locally extracted table; values are in thousands of fish.",
    "Locally extracted table; values are in grams per fish.",
    "Locally extracted table; values are in grams per fish.",
    "Locally extracted table; values are proportions.",
    "Locally extracted table; age-specific index values reported as numbers.",
    "Locally extracted table; age-specific index values reported as numbers.",
    "Locally extracted table; values are in thousands of fish.",
    "Locally extracted table; fishing mortality by age.",
    "Locally extracted table; aggregate output and uncertainty values.",
    "Locally extracted landings by year, country, area, and gear.",
    "Locally extracted ICES annual source-data table."
  ),
  stringsAsFactors = FALSE
)
manifest_path <- file.path(cache, "sources.csv")
manifest <- utils::read.csv(
  manifest_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
for (i in seq_len(nrow(source_map))) {
  path <- file.path(cache, source_map$file[i])
  if (!file.exists(path)) stop("Missing cached source: ", path, call. = FALSE)
  row <- data.frame(
    url = source_map$url[i],
    retrieved_on = "2026-11-03",
    revision = source_map$revision[i],
    bytes = file.info(path)$size,
    sha256 = sha256_file(path),
    status = source_map$status[i],
    notes = source_map$notes[i],
    file = source_map$file[i],
    stringsAsFactors = FALSE
  )
  at <- match(source_map$file[i], manifest$file)
  if (is.na(at)) {
    manifest <- rbind(manifest, row)
  } else if (
    as.numeric(manifest$bytes[at]) != as.numeric(row$bytes) ||
      tolower(manifest$sha256[at]) != tolower(row$sha256)
  ) {
    stop("Cached source changed since it was recorded: ", source_map$file[i], call. = FALSE)
  }
}
manifest_tmp <- tempfile(fileext = ".csv", tmpdir = cache)
utils::write.csv(manifest, manifest_tmp, row.names = FALSE, na = "")
if (!file.copy(manifest_tmp, manifest_path, overwrite = TRUE)) {
  stop("Could not update the local source manifest.", call. = FALSE)
}
unlink(manifest_tmp)

required_sources <- c(
  "wolffish_5a_techreport_2026.html",
  "wolffish_5a_advice_2026.html",
  "ices_source_data_22633_2026.html",
  "wolffish_5a_tables_2026.html"
)
required_rows <- match(required_sources, manifest$file)
if (anyNA(required_rows)) stop("The source manifest is missing a report or data page.", call. = FALSE)
required_paths <- file.path(cache, manifest$file[required_rows])
if (any(!file.exists(required_paths)) ||
  any(as.numeric(manifest$bytes[required_rows]) != file.info(required_paths)$size) ||
  !identical(
    tolower(manifest$sha256[required_rows]),
    unname(tolower(vapply(required_paths, sha256_file, character(1))))
  )) {
  stop("Cached report/data pages do not match the source manifest.", call. = FALSE)
}

read_source_table <- function(file) {
  utils::read.csv(
    file.path(cache, file), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE
  )
}
number <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x), fixed = TRUE)))

wide_age_rows <- function(table, first_year, last_year, years = NULL) {
  age_columns <- grep("^\\d+\\+?$", names(table), value = TRUE)
  ages <- as.integer(sub("\\+$", "", age_columns))
  year_values <- as.integer(table$Year)
  keep <- !is.na(year_values) & year_values >= first_year & year_values <= last_year
  if (!is.null(years)) keep <- keep & year_values %in% years
  table <- table[keep, , drop = FALSE]
  year_values <- year_values[keep]
  values <- as.matrix(data.frame(lapply(table[age_columns], number), check.names = FALSE))
  grid <- expand.grid(
    row = seq_len(nrow(table)),
    age_index = seq_along(age_columns),
    KEEP.OUT.ATTRS = FALSE
  )
  out <- data.frame(
    year = year_values[grid$row],
    age = ages[grid$age_index],
    value = values[cbind(grid$row, grid$age_index)]
  )
  out <- out[is.finite(out$value), , drop = FALSE]
  out$year <- as.integer(out$year)
  out$age <- as.integer(out$age)
  out
}

expected_ages <- 4:16
expected_years <- 1979:2025
catch_table <- read_source_table("catch_numbers_at_age_2026.csv")
catch_weight_table <- read_source_table("catch_weight_at_age_2026.csv")
stock_weight_table <- read_source_table("stock_weight_at_age_2026.csv")
maturity_table <- read_source_table("maturity_at_age_2026.csv")
spring_table <- read_source_table("spring_survey_index_at_age_2026.csv")
autumn_table <- read_source_table("autumn_survey_index_at_age_2026.csv")
stock_numbers_table <- read_source_table("stock_numbers_at_age_2026.csv")
fishing_mortality_table <- read_source_table("fishing_mortality_at_age_2026.csv")
summary_table <- read_source_table("assessment_summary_2026.csv")
ices_table <- read_source_table("ices_source_data_22633_2026.csv")
landings_table <- read_source_table("landings_2026.csv")

required_age_columns <- as.character(expected_ages)
for (table in list(
  catch_table, catch_weight_table, stock_weight_table, maturity_table,
  spring_table, autumn_table, stock_numbers_table, fishing_mortality_table
)) {
  if (!all(c("Year", required_age_columns) %in% names(table))) {
    stop("An age table has an unexpected year/age schema.", call. = FALSE)
  }
  values <- as.matrix(data.frame(lapply(table[required_age_columns], number)))
  if (any(!is.finite(values))) stop("An age table contains missing/non-finite values.", call. = FALSE)
}
if (!identical(as.integer(catch_table$Year), expected_years) ||
  !identical(as.integer(catch_weight_table$Year), expected_years) ||
  !identical(as.integer(stock_weight_table$Year), expected_years) ||
  !identical(as.integer(maturity_table$Year), expected_years) ||
  !identical(as.integer(spring_table$Year), 1985:2025) ||
  !identical(as.integer(autumn_table$Year), 2000:2025) ||
  !identical(as.integer(stock_numbers_table$Year), 1979:2026) ||
  !identical(as.integer(fishing_mortality_table$Year), expected_years)) {
  stop("An age table has unexpected year coverage.", call. = FALSE)
}
if (!identical(as.integer(stock_numbers_table$Year), as.integer(ices_table$Year)) ||
  !identical(as.integer(summary_table$Year), as.integer(ices_table$Year))) {
  stop("The ICES, MFRI summary, and abundance tables do not align by year.", call. = FALSE)
}

catch_numbers <- wide_age_rows(
  catch_table, 1979L, 2025L, c(1979L, 1980L, 1998L:2025L)
)
catch_weights <- wide_age_rows(catch_weight_table, 1979L, 2025L)
stock_weights <- wide_age_rows(stock_weight_table, 1979L, 2025L)
maturity <- wide_age_rows(maturity_table, 1979L, 2025L)
spring_index <- wide_age_rows(spring_table, 1985L, 2025L)
autumn_index <- wide_age_rows(autumn_table, 2000L, 2025L)
stock_numbers <- wide_age_rows(stock_numbers_table, 1979L, 2026L)
fishing_mortality <- wide_age_rows(fishing_mortality_table, 1979L, 2025L)

if (nrow(catch_numbers) != 390L || nrow(catch_weights) != 611L ||
  nrow(stock_weights) != 611L || nrow(maturity) != 611L ||
  nrow(spring_index) != 533L || nrow(autumn_index) != 338L ||
  nrow(stock_numbers) != 624L || nrow(fishing_mortality) != 611L ||
  !identical(sort(unique(catch_numbers$year)), c(1979L, 1980L, 1998L:2025L)) ||
  !identical(sort(unique(catch_numbers$age)), expected_ages)) {
  stop("An age table failed its expected observation-count or age-range check.", call. = FALSE)
}
if (any(maturity$value < 0 | maturity$value > 1) ||
  any(catch_numbers$value < 0) || any(catch_weights$value <= 0) ||
  any(stock_weights$value <= 0) || any(spring_index$value < 0) ||
  any(autumn_index$value < 0) || any(stock_numbers$value < 0) ||
  any(fishing_mortality$value < 0)) {
  stop("An age table contains values outside its expected range.", call. = FALSE)
}

landings_keep <- landings_table[[
  "Latin Name"
]] == "Anarhichas lupus" & landings_table[["Area"]] == "5a"
landings_year <- as.integer(landings_table$Year[landings_keep])
landings_value <- number(landings_table$Landings[landings_keep])
landings_by_year <- aggregate(
  landings_value,
  list(year = landings_year),
  sum
)
names(landings_by_year)[2L] <- "value"
landings_by_year <- landings_by_year[order(landings_by_year$year), ]
if (!identical(as.integer(landings_by_year$year), expected_years)) {
  stop("The official Icelandic-area landings table does not cover 1979-2025.", call. = FALSE)
}
ices_landings <- number(ices_table$Landings[match(landings_by_year$year, as.integer(ices_table$Year))])
landings_difference <- max(abs(landings_by_year$value - ices_landings))
if (!is.finite(landings_difference) || landings_difference > 8) {
  stop("Raw landings do not reconcile to ICES source data within the observed 8-tonne difference.", call. = FALSE)
}
landings_input <- landings_by_year[
  landings_by_year$year %in% 1981:1997, , drop = FALSE
]
if (nrow(landings_input) != 17L) stop("Landings-only years are incomplete.", call. = FALSE)

summary_match <- match(as.integer(summary_table$Year), as.integer(ices_table$Year))
for (pair in list(c("SSB", "SSB"), c("Recruitment", "Recruitment"), c("F", "F"))) {
  summary_values <- number(summary_table[[pair[1L]]])
  ices_values <- number(ices_table[[pair[2L]]])[summary_match]
  use <- is.finite(summary_values) & is.finite(ices_values)
  if (!all(summary_values[use] == ices_values[use])) {
    stop("The MFRI assessment summary and ICES data disagree for ", pair[1L], ".", call. = FALSE)
  }
}
recruitment_match <- match(as.integer(stock_numbers_table$Year), as.integer(ices_table$Year))
if (!all(number(stock_numbers_table[["4"]]) == number(ices_table$Recruitment[recruitment_match]))) {
  stop("Age-4 population numbers do not match the reported recruitment series.", call. = FALSE)
}

assessment_ids <- utils::read.csv(
  file.path(database, "assessments.csv"), stringsAsFactors = FALSE
)$assessment_id
stocks_existing <- utils::read.csv(
  file.path(database, "stocks.csv"), stringsAsFactors = FALSE
)
if (assessment_id %in% assessment_ids || stock_id %in% stocks_existing$stock_id ||
  "caa.27.5a" %in% stocks_existing$authority_stock_id) {
  stop("The Icelandic wolffish stock or assessment already exists.", call. = FALSE)
}

report_url <- "https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_techreport_en.html"
advice_url <- "https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_advice_en.html"
tables_url <- "https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_tables_en.html"
stock_annex_url <- "https://doi.org/10.17895/ices.pub.22819988"
ices_source_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22633"
catch_ref <- paste0(tables_url, "; Catch at age")
catch_weight_ref <- paste0(tables_url, "; Catch-weights")
stock_weight_ref <- paste0(tables_url, "; Stock-weights")
maturity_ref <- paste0(tables_url, "; Maturity at age")
spring_ref <- paste0(tables_url, "; IS-SMB index")
autumn_ref <- paste0(tables_url, "; IS-SMH index")
stock_numbers_ref <- paste0(tables_url, "; Stock in numbers")
fishing_mortality_ref <- paste0(tables_url, "; Fishing mortality")
landings_ref <- paste0(tables_url, "; Landings")
ices_ref <- paste0(ices_source_url, "; assessment key 22633")
report_ref <- paste0(report_url, "; Data used by the assessment and model settings")

input_rows <- function(data, type, measure, basis, unit, source_reference,
                       year = data$year, age = data$age,
                       fleet = "", survey = "", sex = "",
                       region = "Icelandic Waters", season = "",
                       sampling_time = NA_real_,
                       source_type = "official_table",
                       transformation = "", notes = "") {
  n <- nrow(data)
  has_year <- !is.na(year) & nzchar(as.character(year))
  pacific_database_row(
    "inputs", n = n,
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = year, year_basis = ifelse(has_year, "calendar_year", ""),
    age = age, value = as.numeric(data$value), unit = unit,
    sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes
  )
}
output_rows <- function(data, type, measure, unit, source_reference,
                        age = data$age, age_group = "",
                        source_type = "official_table", notes = "") {
  pacific_database_row(
    "outputs", n = nrow(data),
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "Icelandic Waters", season = "",
    year = as.integer(data$year), age = age, age_group = age_group,
    value = as.numeric(data$value),
    se = NA_real_,
    lwr = if ("lwr" %in% names(data)) as.numeric(data$lwr) else NA_real_,
    upr = if ("upr" %in% names(data)) as.numeric(data$upr) else NA_real_,
    unit = unit, source_type = source_type,
    source_reference = source_reference, notes = notes
  )
}

landing_rows <- data.frame(
  year = as.integer(landings_input$year),
  age = NA_integer_,
  value = as.numeric(landings_input$value)
)
catch_age_notes <- "Age 16 is the 16+ plus group. The public numeric catch table contains other years, but the 2026 report says age-disaggregated catch was unavailable in 1981-1997; those rows are therefore excluded from catch-at-age."
biology_notes <- "Age 16 is the 16+ plus group. Values are the published annual table."
autumn_notes <- ifelse(
  autumn_index$year == 2011L,
  "The published 2011 row is retained; whether it represents a direct autumn survey observation or a substituted series is unresolved.",
  "Age 16 is the 16+ plus group. The table describes index values as numbers; the scale multiplier is not stated, so the native index scale is preserved."
)
spring_index$notes <- "Age 16 is the 16+ plus group. The table describes index values as numbers; the scale multiplier is not stated, so the native index scale is preserved."
autumn_index$notes <- autumn_notes

inputs <- do.call(rbind, list(
  input_rows(
    catch_numbers, "catch", "numbers_at_age", "numbers", "thousand fish",
    catch_ref, fleet = "Commercial fishery (Icelandic waters)",
    notes = catch_age_notes
  ),
  input_rows(
    landing_rows, "catch", "landings_biomass", "biomass", "tonnes",
    landings_ref, fleet = "Commercial fishery (Icelandic waters)",
    source_type = "reconstructed_source_input",
    transformation = "Sum the official landings table across country and gear entries for Area 5a and the assessed species; retain totals only for 1981-1997, when the report says age-disaggregated catches were unavailable.",
    notes = paste(
      "The raw aggregate agrees with ICES source-data landings within 8 tonnes across 1979-2025.",
      "The separate MFRI assessment-summary landings field does not reconcile directly; its relation/scale is unresolved, so this aggregate is a documented partial reconstruction."
    )
  ),
  input_rows(
    catch_weights, "catch_weight", "weight_at_age", "g_per_fish", "g/fish",
    catch_weight_ref, fleet = "Commercial fishery (Icelandic waters)",
    notes = biology_notes
  ),
  input_rows(
    stock_weights, "weight", "weight_at_age", "g_per_fish", "g/fish",
    stock_weight_ref,
    notes = paste(biology_notes, "This is the stock weight series, not a separately reported SSB-weight series.")
  ),
  input_rows(
    maturity, "maturity", "maturity_at_age", "proportion", "proportion",
    maturity_ref, sex = "female",
    notes = paste(
      biology_notes,
      "The technical report says maturity is based on females; the downloaded table is not otherwise sex-stratified."
    )
  ),
  input_rows(
    spring_index, "index", "numbers_at_age", "index_scale",
    "native survey index units (reported as numbers)", spring_ref,
    survey = "Icelandic spring groundfish survey (IS-SMB)",
    season = "Spring", sampling_time = 0.17,
    notes = paste(spring_index$notes, "Sampling time 0.17 is an approximate March timing.")
  ),
  input_rows(
    autumn_index, "index", "numbers_at_age", "index_scale",
    "native survey index units (reported as numbers)", autumn_ref,
    survey = "Icelandic autumn groundfish survey (IS-SMH)",
    season = "Autumn", sampling_time = 0.83,
    notes = paste(autumn_index$notes, "Sampling time 0.83 is an approximate October timing.")
  ),
  input_rows(
    data.frame(age = expected_ages, value = rep(0.15, length(expected_ages))),
    "M", "natural_mortality_at_age", "per_year", "per year",
    paste0(report_url, "; Data used by the assessment and model settings"),
    year = NA_integer_, age = expected_ages,
    source_type = "official_document",
    notes = "Fixed M=0.15 per year for all model ages; age 16 is the 16+ plus group."
  )
))

number_rows <- stock_numbers
fishing_rows <- fishing_mortality
ices_year <- as.integer(ices_table$Year)
aggregate_output <- function(year, value, lower, upper) {
  data.frame(
    year = as.integer(year),
    age = NA_integer_,
    value = as.numeric(value),
    lwr = as.numeric(lower),
    upr = as.numeric(upper)
  )
}
ssb <- aggregate_output(
  ices_year, number(ices_table$SSB),
  number(ices_table[["Low SSB"]]), number(ices_table[["High SSB"]])
)
ssb <- ssb[is.finite(ssb$value), , drop = FALSE]
recruitment <- aggregate_output(
  ices_year, number(ices_table$Recruitment),
  number(ices_table[["Low Recruitment"]]),
  number(ices_table[["High Recruitment"]])
)
recruitment <- recruitment[is.finite(recruitment$value), , drop = FALSE]
recruitment$age <- 4L
fbar <- aggregate_output(
  ices_year, number(ices_table$F),
  number(ices_table[["Low F"]]), number(ices_table[["High F"]])
)
fbar <- fbar[is.finite(fbar$value) & fbar$year <= 2025L, , drop = FALSE]

outputs <- do.call(rbind, list(
  output_rows(
    number_rows, "population", "numbers_at_age", "thousand fish",
    stock_numbers_ref,
    notes = "Age 16 is the 16+ plus group. 2026 is the assessment-year forecast; fitted catch data end in 2025."
  ),
  output_rows(
    fishing_rows, "mortality", "fishing_mortality_at_age", "per year",
    fishing_mortality_ref,
    notes = "Age 16 is the 16+ plus group. No age-specific uncertainty was published in this table."
  ),
  output_rows(
    ssb, "biomass", "SSB", "tonnes", ices_ref,
    source_type = "official_machine_readable",
    notes = "95% confidence limits are reported. The 2026 value is a forecast; fitted data end in 2025."
  ),
  output_rows(
    recruitment, "recruitment", "recruitment", "thousand fish", ices_ref,
    age = 4L, source_type = "official_machine_readable",
    notes = "Recruitment is age 4. 95% confidence limits are reported. The 2026 value is a forecast."
  ),
  output_rows(
    fbar, "mortality", "Fbar", "per year", ices_ref,
    age = NA_integer_, age_group = "10-15",
    source_type = "official_machine_readable",
    notes = "Mean fishing mortality for ages 10-15; 95% confidence limits are reported."
  )
))

assumption_rows <- function(component, setting, value, source_reference,
                            survey = "", sex = "", notes = "") {
  pacific_database_row(
    "assumptions", n = length(value),
    assessment_id = assessment_id, component = component,
    fleet = "", survey = survey, sex = sex,
    region = "Icelandic Waters", season = "",
    setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes
  )
}
assumptions <- do.call(rbind, list(
  assumption_rows(
    "population", "model_ages", "Ages 4-16; age 16 is the plus group",
    report_ref
  ),
  assumption_rows(
    "recruitment", "recruitment_age", "4",
    paste0(advice_url, "; Assessment summary")
  ),
  assumption_rows(
    "M", "natural_mortality", "Fixed M=0.15 per year for all age groups",
    report_ref, notes = "M is not estimated."
  ),
  assumption_rows(
    "catch", "catch_data_regime",
    "Catch at age in 1979-1980 and 1998-2025; total landings in 1981-1997",
    report_ref,
    notes = "The public catch-at-age table includes values for 1981-1997, but the report states those age-disaggregated catches were unavailable."
  ),
  assumption_rows(
    "survey", "sampling_time_fraction_year", "Approximately 0.17 (March)",
    spring_ref, survey = "Icelandic spring groundfish survey (IS-SMB)",
    notes = "Calendar timing approximation; exact model fraction was not located."
  ),
  assumption_rows(
    "survey", "sampling_time_fraction_year", "Approximately 0.83 (mostly October)",
    autumn_ref, survey = "Icelandic autumn groundfish survey (IS-SMH)",
    notes = "Calendar timing approximation; exact model fraction was not located."
  ),
  assumption_rows(
    "biology", "SSB_definition", "Mature female biomass",
    report_ref,
    notes = "Maturity is published from female samples. The separate SSB-weight table is empty in the cached download; no SSB weights were imputed from stock weights."
  ),
  assumption_rows(
    "observation", "likelihood_and_observation_weights", "unknown",
    report_ref,
    notes = "The public report does not expose all effective sample sizes, likelihood weights, or the full residual-correlation specification."
  ),
  assumption_rows(
    "assessment_output", "confidence_intervals", "95% for SSB, age-4 recruitment, and F ages 10-15",
    paste0(advice_url, "; assessment summary"),
    notes = "No uncertainty was available for the age-specific N and F tables."
  ),
  assumption_rows(
    "survey", "autumn_2011_index_status", "unresolved",
    autumn_ref, survey = "Icelandic autumn groundfish survey (IS-SMH)",
    notes = "The published 2011 age-index row is retained, but the source does not resolve whether it is a direct October observation or a substituted series."
  )
))

stock <- pacific_database_row(
  "stocks",
  stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "caa.27.5a",
  scientific_name = "Anarhichas lupus",
  common_name = "Atlantic wolffish",
  area = "ICES Division 5.a (Iceland grounds)",
  region = "Icelandic Waters",
  ocean = "Northeast Atlantic",
  notes = "Current Icelandic Atlantic wolffish assessment unit. Distinct from the U.S. Gulf of Maine/Georges Bank Atlantic wolffish unit."
)
assessment <- pacific_database_row(
  "assessments",
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L,
  assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "MFRI production assessment; ICES key 22633",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022L,
  assessment_url = report_url, framework_url = stock_annex_url,
  data_url = tables_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "2026 production assessment data through 2025; 2026 population and aggregate estimates are forecasts.",
    "ICES key 22633 supplies aggregate SSB, recruitment and F uncertainty.",
    "Age-specific tables are numerical, but the exact production model files, several likelihood settings, and full age-specific uncertainty are unavailable.",
    "MFRI advice page:", advice_url
  )
)

source_manifest_ids <- utils::read.csv(
  manifest_path, stringsAsFactors = FALSE, check.names = FALSE
)$file
if (!all(source_map$file %in% source_manifest_ids)) {
  stop("The local source manifest update failed.", call. = FALSE)
}
append_pacific_case(stock, assessment, assumptions, inputs, outputs)
source(file.path(root, "scripts", "database", "candidate_register_io.R"))
candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- utils::read.csv(
  candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Expected one wolffish discovery candidate.", call. = FALSE)
candidates$import_status[candidate_row] <- "partial"
candidates$catch_age_evidence[candidate_row] <- paste(
  "The numeric MFRI 2026 table covers ages 4-16+ for 1979-2025.",
  "The technical report states age-disaggregated catches were unavailable in 1981-1997; those years are recorded as total landings only.",
  "The raw landings table was summed over Area 5a country/gear rows and cross-checked to ICES source data."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Numeric IS-SMB age-index values are available for 1985-2025 and IS-SMH values for 2000-2025, ages 4-16+.",
  "The table calls these indices numbers but does not state the scaling multiplier; 2011 autumn-row provenance remains unresolved."
)
candidates$weights_evidence[candidate_row] <- paste(
  "Numeric catch weights-at-age and stock weights-at-age are available in grams per fish for 1979-2025, ages 4-16+.",
  "The separately listed SSB-weight table has no numeric rows."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "Numeric maturity proportions are available for ages 4-16+ in 1979-2025.",
  "The report describes female maturity samples; exact SSB weight-at-age values are not in the downloaded tables."
)
candidates$output_evidence[candidate_row] <- paste(
  "MFRI/ICES sources provide N-at-age through 2026, F-at-age through 2025, and SSB, age-4 recruitment, and F ages 10-15 with 95% intervals.",
  "Age-specific N/F uncertainty and an estimated M surface are unavailable; M is fixed."
)
candidates$review_date[candidate_row] <- "2026-11-03"
candidates$decision_reason[candidate_row] <- paste(
  "The latest 2026 production assessment has numeric age-specific catch, survey, weight, maturity, N, and F tables, plus ICES aggregate outputs with 95% intervals.",
  "Import as partial because the exact likelihood settings, index scaling, 2011 autumn-series provenance, and complete uncertainty are unresolved."
)
candidates$notes[candidate_row] <- paste(
  "The source cache stores the 2026 MFRI report/advice/tables, ICES key 22633 data pages, and table exports under source_cache/discovery_ices_iceland_wolffish_2026/.",
  "The run uses data through 2025 and publishes a 2026 forecast.",
  "The MFRI assessment-summary landings field does not reconcile directly with the raw landings table and ICES series; this is documented in the stock source review.",
  "No current native SAM object was located in this execution environment; stockassessment is not installed here."
)
replace_candidate_register_row(
  candidate_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id
)

replace_discovery_row <- function(path, row_index, row, key_column, key) {
  if (nrow(row) != 1L) stop("Expected one discovery row.", call. = FALSE)
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  if (record_index < 2L || record_index > length(bounds$start)) {
    stop("Discovery row index is out of range.", call. = FALSE)
  }
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(
    row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n"
  )
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) {
    replacement <- replacement[-length(replacement)]
  }
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) {
    replacement <- replacement[-length(replacement)]
  }
  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  has_carriage_return <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_carriage_return <- TRUE
    next_byte <- next_byte + 1L
  }
  line_ending <- raw(0L)
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    line_ending <- c(if (has_carriage_return) as.raw(13L) else raw(0L), as.raw(10L))
    last <- next_byte
    replacement <- c(replacement, line_ending)
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
      check.names = FALSE),
    error = function(e) NULL
  )
  valid <- !is.null(updated) &&
    nrow(updated) == length(bounds$start) - 1L &&
    sum(updated[[key_column]] == key, na.rm = TRUE) == 1L &&
    identical(as.character(updated[[key_column]][as.integer(row_index)]), key)
  if (!valid) {
    writeBin(original, path)
    stop("Discovery CSV failed its row-count or key check.", call. = FALSE)
  }
  invisible(NULL)
}
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- utils::read.csv(
  inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
inventory_row <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
if (length(inventory_row) != 1L) stop("Expected one wolffish inventory-unit row.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"
replace_discovery_row(
  inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
  "unit_key", paste0("candidate:", candidate_unit_id)
)

selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
selected <- utils::read.csv(
  selected_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("Expected one wolffish selected-batch row.", call. = FALSE)
selected$review_date[selected_row] <- "2026-11-03"
selected$curation_status[selected_row] <- "partial_source_import"
replace_discovery_row(
  selected_path, selected_row, selected[selected_row, , drop = FALSE],
  "candidate_id", candidate_id
)

cat(
  "Imported partial Icelandic Atlantic wolffish 2026 source records:",
  nrow(inputs), "inputs,", nrow(assumptions), "assumptions,",
  nrow(outputs), "outputs.\n"
)