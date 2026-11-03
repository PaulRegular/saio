root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_golden_redfish_561214_2026")
assessment_id <- "ices_golden_redfish_561214_2026"
stock_id <- "ices_golden_redfish_561214"
candidate_id <- "ICES:reg.27.561214"

if (!dir.exists(cache)) stop("The verified source cache is missing.", call. = FALSE)

expected_sources <- c(
  "ICES_2026_advice.html",
  "ICES_2026_source_data.html",
  "MFRI_2026_tables.html",
  "MFRI_2026_technical_report.html"
)
manifest <- utils::read.csv(file.path(cache, "sources.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE
)
source_rows <- match(expected_sources, manifest$file)
if (anyNA(source_rows)) stop("The source manifest is incomplete.", call. = FALSE)
manifest <- manifest[source_rows, , drop = FALSE]
source_paths <- file.path(cache, manifest$file)
if (any(!file.exists(source_paths)) ||
  !identical(as.numeric(manifest$bytes), as.numeric(file.info(source_paths)$size))) {
  stop("Cached source sizes do not match the manifest.", call. = FALSE)
}
sha256_file <- function(path) {
  result <- system2("certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256"),
    stdout = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify source checksum: ", path, call. = FALSE)
  hashes
}
source_hashes <- vapply(source_paths, sha256_file, character(1))
if (!identical(tolower(manifest$sha256), unname(tolower(source_hashes)))) {
  stop("Cached source checksums do not match the manifest.", call. = FALSE)
}

read_widget_table <- function(heading) {
  path <- file.path(cache, "MFRI_2026_tables.html")
  doc <- xml2::read_html(path)
  headings <- xml2::xml_find_all(doc, "//h3")
  at <- which(xml2::xml_text(headings) == heading)
  if (length(at) != 1L) stop("Expected one MFRI table heading: ", heading, call. = FALSE)
  script <- xml2::xml_find_first(headings[[at]], "following-sibling::script[@type='application/json'][1]")
  if (inherits(script, "xml_missing")) stop("Missing MFRI table data: ", heading, call. = FALSE)
  payload <- jsonlite::fromJSON(xml2::xml_text(script), simplifyVector = FALSE)$x
  headers <- xml2::xml_text(xml2::xml_find_all(
    xml2::read_html(payload$container), "//thead//th"
  ))
  columns <- lapply(payload$data, function(column) {
    vapply(column, function(value) {
      if (is.null(value)) NA_character_ else as.character(value)
    }, character(1))
  })
  if (length(headers) != length(columns) ||
    length(unique(lengths(columns))) != 1L) {
    stop("The MFRI table structure changed: ", heading, call. = FALSE)
  }
  out <- as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
  names(out) <- headers
  out
}

number <- function(x) suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))

wide_age_rows <- function(table, first_year, last_year) {
  age_columns <- grep("^\\d+\\+?$", names(table), value = TRUE)
  ages <- as.integer(sub("\\+$", "", age_columns))
  years <- as.integer(table$Year)
  keep_year <- !is.na(years) & years >= first_year & years <= last_year
  table <- table[keep_year, , drop = FALSE]
  years <- years[keep_year]
  values <- as.matrix(data.frame(lapply(table[age_columns], number),
    check.names = FALSE
  ))
  grid <- expand.grid(
    row = seq_len(nrow(table)),
    age_index = seq_along(age_columns),
    KEEP.OUT.ATTRS = FALSE
  )
  grid$year <- years[grid$row]
  grid$age <- ages[grid$age_index]
  grid$value <- values[cbind(grid$row, grid$age_index)]
  grid <- grid[is.finite(grid$value), c("year", "age", "value"), drop = FALSE]
  grid$year <- as.integer(grid$year)
  grid$age <- as.integer(grid$age)
  grid
}

table_landings <- read_widget_table("Landings")
table_summary <- read_widget_table("Assessment summary")
table_catch <- read_widget_table("Catch at age")
table_catch_weight <- read_widget_table("Catch-weights")
table_stock_weight <- read_widget_table("Stock-weights")
table_maturity <- read_widget_table("Maturity at age")
table_autumn_index <- read_widget_table("IS-SMH index")
table_stock_numbers <- read_widget_table("Stock in numbers")
table_fishing_mortality <- read_widget_table("Fishing mortality")

landings_year <- as.integer(table_landings$Year)
landings_value <- number(table_landings$Landings)
landings_valid <- is.finite(landings_year) & is.finite(landings_value)
landings_sum <- aggregate(
  landings_value[landings_valid],
  list(year = landings_year[landings_valid]),
  sum
)
names(landings_sum)[2] <- "value"
landings_sum <- landings_sum[landings_sum$year >= 1966 & landings_sum$year <= 2025, ]
summary_year <- as.integer(table_summary$Year)
summary_landing <- number(table_summary$Landings)
expected_years <- 1966:2025
landings_sum <- landings_sum[match(expected_years, landings_sum$year), ]
summary_landing <- summary_landing[match(expected_years, summary_year)]
if (!identical(as.integer(landings_sum$year), expected_years) ||
  !isTRUE(all.equal(landings_sum$value, summary_landing, tolerance = 0))) {
  stop("Country-area landings do not reconcile to the official annual summary.", call. = FALSE)
}

sag_tables <- rvest::html_table(
  xml2::read_html(file.path(cache, "ICES_2026_source_data.html")),
  fill = TRUE,
  convert = FALSE
)
sag_match <- which(vapply(sag_tables, function(x) {
  all(c("Year", "SSB", "F", "Recruitment", "Catches") %in% names(x))
}, logical(1)))
if (length(sag_match) != 1L) {
  stop("Could not identify the ICES annual source-data table.", call. = FALSE)
}
sag <- as.data.frame(sag_tables[[sag_match]], stringsAsFactors = FALSE)
sag$Year <- as.integer(sag$Year)
for (column in setdiff(names(sag), c("Year"))) sag[[column]] <- number(sag[[column]])
if (!all(expected_years %in% sag$Year) || !(2026L %in% sag$Year)) {
  stop("The ICES source data do not cover the reviewed assessment period.", call. = FALSE)
}
summary_match <- match(sag$Year, summary_year)
for (column in c("SSB", "Recruitment", "F", "Landings")) {
  if (!column %in% names(table_summary)) next
  source_value <- number(table_summary[[column]])[summary_match]
  graph_value <- sag[[column]]
  valid <- is.finite(source_value) & is.finite(graph_value)
  if (!isTRUE(all.equal(source_value[valid], graph_value[valid], tolerance = 0))) {
    stop("MFRI and ICES source tables disagree for ", column, ".", call. = FALSE)
  }
}

report_text <- rvest::html_text2(xml2::read_html(
  file.path(cache, "MFRI_2026_technical_report.html")
))
required_report_text <- c(
  "The simulation period is from 1966 to 2026",
  "Recruitment was set at age 6",
  "Natural mortality (M) was set to 0.05",
  "Two survey indices for the whole area used",
  "only those from 1995 on-wards are used"
)
if (!all(vapply(required_report_text, grepl, logical(1),
  x = report_text, fixed = TRUE
))) {
  stop("The cached production report no longer matches the screened assessment.", call. = FALSE)
}

input_rows <- function(data, type, measure, basis, unit,
                       fleet = NA_character_, survey = NA_character_,
                       region = NA_character_, season = NA_character_,
                       source_reference, transformation = "",
                       notes = "", source_type = "official_table") {
  out <- as.data.frame(matrix(NA_character_, nrow(data),
    length(names(utils::read.csv(file.path(database, "inputs.csv"),
      nrows = 0, check.names = FALSE
    )))
  ), stringsAsFactors = FALSE
  )
  names(out) <- names(utils::read.csv(file.path(database, "inputs.csv"),
    nrows = 0, check.names = FALSE
  ))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- fleet
  out$survey <- survey
  out$region <- region
  out$season <- season
  out$year <- as.integer(data$year)
  out$year_basis <- "calendar_year"
  out$age <- as.integer(data$age)
  out$value <- as.numeric(data$value)
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- rep(notes, length.out = nrow(data))
  out
}

output_rows <- function(data, type, measure, unit, source_type,
                        source_reference, age = NA_integer_,
                        age_group = NA_character_, fleet = NA_character_,
                        notes = "") {
  out <- as.data.frame(matrix(NA_character_, nrow(data),
    length(names(utils::read.csv(file.path(database, "outputs.csv"),
      nrows = 0, check.names = FALSE
    )))
  ), stringsAsFactors = FALSE
  )
  names(out) <- names(utils::read.csv(file.path(database, "outputs.csv"),
    nrows = 0, check.names = FALSE
  ))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$fleet <- fleet
  out$year <- as.integer(data$year)
  if (length(age) == 1L && is.na(age) && "age" %in% names(data)) {
    out$age <- as.integer(data$age)
  } else {
    out$age <- rep(age, length.out = nrow(data))
  }
  out$age_group <- age_group
  out$value <- as.numeric(data$value)
  if ("lwr" %in% names(data)) out$lwr <- as.numeric(data$lwr)
  if ("upr" %in% names(data)) out$upr <- as.numeric(data$upr)
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- rep(notes, length.out = nrow(data))
  out
}

age_numbers <- wide_age_rows(table_catch, 1995, 2025)
age_index <- wide_age_rows(table_autumn_index, 1996, 2025)
catch_weights <- wide_age_rows(table_catch_weight, 1966, 2025)
stock_weights <- wide_age_rows(table_stock_weight, 1966, 2025)
maturity <- wide_age_rows(table_maturity, 1986, 2025)
numbers_at_age <- wide_age_rows(table_stock_numbers, 1966, 2026)
fishing_mortality_at_age <- wide_age_rows(table_fishing_mortality, 1966, 2025)

ages_expected <- 6:25
for (x in list(age_numbers, age_index, catch_weights, stock_weights,
  maturity, numbers_at_age, fishing_mortality_at_age)) {
  if (!all(x$age %in% ages_expected)) stop("Unexpected age in an MFRI age table.", call. = FALSE)
}
if (!identical(sort(unique(age_numbers$year)), 1995:2025) ||
  !identical(sort(unique(age_index$year)), 1996:2025) ||
  !identical(sort(unique(catch_weights$year)), 1966:2025) ||
  !identical(sort(unique(stock_weights$year)), 1966:2025) ||
  !identical(sort(unique(maturity$year)), 1986:2025) ||
  !identical(sort(unique(numbers_at_age$year)), 1966:2026) ||
  !identical(sort(unique(fishing_mortality_at_age$year)), 1966:2025)) {
  stop("Published MFRI age-series coverage changed from the source review.", call. = FALSE)
}

region <- "ICES subareas 5, 6, 12, and 14"
source_tables_url <- manifest$url[match("MFRI_2026_tables.html", manifest$file)]
technical_report_url <- manifest$url[match("MFRI_2026_technical_report.html", manifest$file)]
ices_source_data_url <- manifest$url[match("ICES_2026_source_data.html", manifest$file)]
ices_advice_url <- manifest$url[match("ICES_2026_advice.html", manifest$file)]
stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "ICES",
  authority_stock_id = "reg.27.561214",
  scientific_name = "Sebastes norvegicus",
  common_name = "Golden redfish",
  area = "ICES subareas 5, 6, 12, and 14",
  region = "Iceland, Faroes, East Greenland and adjacent North Atlantic areas",
  ocean = "Northeast Atlantic",
  notes = paste(
    "Current ICES management unit reg.27.561214.",
    "Distinct from the Northeast Arctic golden redfish unit reg.27.1-2.",
    "The database basin label follows the ICES regional classification; the full extent is retained in area and region."
  ),
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2025L,
  estimate_terminal_year = 2026L,
  assessment_type = "annual_update",
  model_family = "SAM",
  model_version = "MFRI 2026 production assessment; 2023 benchmark framework",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2023L,
  assessment_url = technical_report_url,
  framework_url = "https://doi.org/10.17895/ices.pub.22304638",
  data_url = source_tables_url,
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Latest detailed official production assessment for the current stock unit; input data end in 2025.",
    "The 2026 state/forecast rows are retained where reported.",
    "The native fitted SAM object and exact survey sampling fractions were not recovered."
  ),
  stringsAsFactors = FALSE
)

landings_input <- data.frame(year = landings_sum$year, age = NA_integer_,
  value = landings_sum$value)
landings_input$age <- NA_integer_
input_landings <- input_rows(
  landings_input, "catch", "total_biomass", "biomass", "tonnes",
  fleet = "Combined commercial landings",
  region = region,
  source_reference = paste("MFRI 2026 landings table; annual values summed across reporting countries and areas.", source_tables_url),
  transformation = "Summed country-area landings within each calendar year; annual totals exactly match the MFRI assessment-summary Landings column.",
  notes = "Source landings are the annual total used to scale catch-at-age across the stock sectors. This is the observed landings input, not the model-estimated total catch.",
  source_type = "reconstructed_source_input"
)

input_catch <- input_rows(
  age_numbers, "catch", "numbers_at_age", "numbers", "thousand fish",
  fleet = "Combined catch-at-age across stock sectors",
  region = region,
  source_reference = paste("MFRI 2026 tables, 'Catch at age'.", source_tables_url),
  transformation = "Source table values transcribed without unit conversion.",
  notes = "Age 25 represents the 25+ group. The production model uses catch-at-age from 1995 onward; earlier catch-age values in the source table are not included here."
)
input_catch_weight <- input_rows(
  catch_weights, "catch_weight", "weight_at_age", "g_per_fish", "g/fish",
  fleet = "Combined commercial catch",
  region = region,
  source_reference = paste("MFRI 2026 tables, 'Catch-weights'.", source_tables_url),
  transformation = "Source table values transcribed in grams without conversion.",
  notes = "Age 25 represents the 25+ group; source table values are shown for 1966-2025."
)
input_stock_weight <- input_rows(
  stock_weights, "weight", "weight_at_age", "g_per_fish", "g/fish",
  region = region,
  source_reference = paste("MFRI 2026 tables, 'Stock-weights'.", source_tables_url),
  transformation = "Source table values transcribed in grams without conversion.",
  notes = "Age 25 represents the 25+ group. The report states that missing age weights are supplemented from an alternative source and stock weights are smoothed using a two-year moving average; the values here are the published final table."
)
input_maturity <- input_rows(
  maturity, "maturity", "maturity_at_age", "proportion", "proportion",
  region = region,
  source_reference = paste("MFRI 2026 tables, 'Maturity at age'.", source_tables_url),
  transformation = "Source proportions transcribed without conversion.",
  notes = "Age 25 represents the 25+ group. No sex-specific vector is identified in the published table."
)
input_autumn_index <- input_rows(
  age_index, "index", "numbers_at_age", "numbers", "index numbers (source scale)",
  survey = "Icelandic autumn groundfish survey (IS-SMH)",
  region = "ICES Division 5.a",
  season = "autumn",
  source_reference = paste("MFRI 2026 tables, 'IS-SMH index'.", source_tables_url),
  transformation = "Source table values transcribed without conversion.",
  notes = ifelse(
    age_index$year == 2011L,
    paste(
      "The production report says no October survey was conducted in 2011 and reports an imputed missing-year index based on 2010 and 2012.",
      "The published age-specific 2011 values are retained exactly; the report does not specify an age-by-age imputation formula, so they are not described as direct survey observations."
    ),
    "Age 25 represents the 25+ group. The table gives age-disaggregated index values in numbers; a physical scale/unit beyond the source index numbers is not stated."
  )
)

aggregate_output <- function(value_col, low_col = NULL, high_col = NULL,
                             type, measure, unit, age = NA_integer_,
                             age_group = NA_character_, notes = "") {
  value <- sag[[value_col]]
  keep <- is.finite(sag$Year) & is.finite(value)
  dat <- data.frame(year = sag$Year[keep], value = value[keep])
  if (!is.null(low_col)) dat$lwr <- sag[[low_col]][keep]
  if (!is.null(high_col)) dat$upr <- sag[[high_col]][keep]
  output_rows(
    dat, type, measure, unit, "official_machine_readable",
    paste("ICES Stock Assessment Graphs, 2026 source data, assessment key 22441.", ices_source_data_url),
    age = age, age_group = age_group,
    notes = paste(
      notes,
      "Reported low/high bounds are retained as published; no standard error or interval level is inferred."
    )
  )
}
output_ssb <- aggregate_output(
  "SSB", "Low SSB", "High SSB", "biomass", "SSB", "tonnes",
  notes = "Annual spawning stock biomass."
)
output_total_biomass <- aggregate_output(
  "TBiomass", "Low TBiomass", "High TBiomass",
  "biomass", "total_biomass", "tonnes",
  notes = "Annual total biomass."
)
output_recruitment <- aggregate_output(
  "Recruitment", "Low Recruitment", "High Recruitment",
  "recruitment", "recruitment", "thousand fish",
  age = 6L, notes = "Recruitment is reported at age 6."
)
output_fbar <- aggregate_output(
  "F", "Low F", "High F",
  "mortality", "Fbar", "yr-1",
  age_group = "9–19", notes = "Fishing mortality averaged over ages 9-19."
)
output_catches <- aggregate_output(
  "Catches", type = "catch", measure = "total_biomass", unit = "tonnes",
  notes = "Model-reported total catches; kept separate from observed landings."
)
output_discards <- aggregate_output(
  "Discards", type = "catch", measure = "total_biomass", unit = "tonnes",
  notes = "Model-reported discards; retained as a separate reported catch quantity."
)
output_catches$fleet <- "Model-reported total catches"
output_discards$fleet <- "Model-reported discards"

output_numbers <- output_rows(
  numbers_at_age, "population", "numbers_at_age", "thousand fish",
  "official_table",
  paste("MFRI 2026 tables, 'Stock in numbers'.", source_tables_url),
  notes = ifelse(numbers_at_age$year == 2026L,
    "Age 25 is the 25+ group. This 2026 state/forecast is beyond the 2025 terminal input year.",
    "Age 25 is the 25+ group."
  )
)
output_fishing_mortality <- output_rows(
  fishing_mortality_at_age, "mortality", "fishing_mortality_at_age", "yr-1",
  "official_table",
  paste("MFRI 2026 tables, 'Fishing mortality'.", source_tables_url),
  notes = "Age 25 is the 25+ group."
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = assessment_id,
    component = component,
    fleet = NA_character_,
    survey = NA_character_,
    sex = NA_character_,
    region = NA_character_,
    season = NA_character_,
    setting = setting,
    value = value,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}
report_ref <- paste("MFRI 2026 production technical report.", technical_report_url)
assumptions <- do.call(rbind, list(
  assumption("assessment", "model_family", "SAM", report_ref),
  assumption("assessment", "benchmark_framework", "2023", report_ref,
    "The annual 2026 production run uses the model structure established at the 2023 benchmark."),
  assumption("population", "simulation_period", "1966-2026", report_ref,
    "The data terminal year is 2025; 2026 rows are the report's state/forecast."),
  assumption("population", "age_range", "6-25+", report_ref,
    "Age 25 is the plus group."),
  assumption("recruitment", "recruitment_age", "6", report_ref),
  assumption("catch", "catch_age_period", "1995-2025", report_ref,
    "The published age table includes earlier years, but the report says only catch-at-age from 1995 onward is used."),
  assumption("catch", "catch_age_scaling", "Age allocation derived from Icelandic commercial length data and scaled to total landings across countries and areas", report_ref,
    "Total catch-at-age across sectors is used in the tuning."),
  assumption("catch", "landings_series", "Annual total landings from all reporting countries and areas", paste("MFRI 2026 tables, 'Landings' and 'Assessment summary'.", source_tables_url),
    "The imported annual sums exactly match the report's assessment-summary landings column for 1966-2025."),
  assumption("survey", "survey_structure", "Two survey indices are used for the whole stock area; spring and autumn indices combine regional survey information", report_ref,
    "The report describes Icelandic and Faroese spring data, and Icelandic, Faroese summer and German East Greenland autumn data."),
  assumption("survey", "spring_index_input", "Single total biomass series; numerical fitted series not recovered", report_ref,
    "The published IS-SMB table is age-disaggregated supporting data; it is not substituted for the model's single total biomass observation series."),
  assumption("survey", "autumn_age_index", "Icelandic IS-SMH age-disaggregated index, 1996-2025", paste("MFRI 2026 tables, 'IS-SMH index'.", source_tables_url),
    "The source table's measurement scale is not stated beyond index numbers. The report says the 2011 missing-year index is imputed; its age-level reconstruction is not documented."),
  assumption("survey", "survey_timing", "Icelandic spring survey in March; Icelandic autumn survey in October; exact within-year fractions unknown", report_ref,
    "No numerical year-by-survey sampling-time series was found in the reviewed current-run sources."),
  assumption("weight", "catch_weight_at_age", "Published age-specific weights in grams per fish", paste("MFRI 2026 tables, 'Catch-weights'.", source_tables_url)),
  assumption("weight", "stock_weight_at_age", "Published age-specific stock weights in grams per fish; smoothed and supplemented where needed", paste("MFRI 2026 tables, 'Stock-weights'.", source_tables_url),
    "The importer retains the final reported table values and applies no additional smoothing."),
  assumption("maturity", "maturity_at_age", "Proportion mature at age in the stock", paste("MFRI 2026 tables, 'Maturity at age'.", source_tables_url),
    "No sex-specific vector is identified in the published table."),
  assumption("M", "natural_mortality", "Fixed M=0.05 for ages 6-24 and M=0.10 for age 25+", report_ref,
    "Natural mortality is an assumption, not an estimated output."),
  assumption("mortality", "Fbar_ages", "9-19", paste("ICES 2026 advice record 5102; ICES source data key 22441.", ices_advice_url)),
  assumption("uncertainty", "aggregate_output_bounds", "Low and high values reported for SSB, total biomass, recruitment and Fbar", ices_source_data_url,
    "The point and low/high values are retained; the machine-readable page does not identify a confidence level. No SE is calculated."),
  assumption("assessment", "native_fit", "Not recovered", report_ref,
    "Published tables provide the imported values, but the fitted SAM object and complete annual configuration were not found.")
))

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
register_path <- file.path(root, "discovery", "candidates.csv")
stocks_existing <- utils::read.csv(stocks_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
assessments_existing <- utils::read.csv(assessments_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
register <- utils::read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
  register$candidate_unit_id[candidate_row] != stock_id ||
  register$official_stock_id[candidate_row] != "reg.27.561214" ||
  register$eligibility[candidate_row] != "eligible" ||
  register$match_status[candidate_row] != "new") {
  stop("Candidate-register identity or screening no longer matches this import.", call. = FALSE)
}
if (stock_id %in% stocks_existing$stock_id ||
  "reg.27.561214" %in% stocks_existing$authority_stock_id ||
  assessment_id %in% assessments_existing$assessment_id) {
  stop("Golden-redfish canonical records already exist; refusing a duplicate import.", call. = FALSE)
}
assessment_exists <- function(path) {
  connection <- file(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  prefix <- paste0('"', assessment_id, '"')
  repeat {
    lines <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
if (assessment_exists(inputs_path) || assessment_exists(outputs_path) ||
  assessment_exists(assumptions_path)) {
  stop("An assessment row already exists in a canonical child table.", call. = FALSE)
}

if (nrow(age_numbers) == 0L || nrow(age_index) == 0L ||
  nrow(catch_weights) == 0L || nrow(stock_weights) == 0L ||
  nrow(maturity) == 0L || nrow(numbers_at_age) == 0L ||
  nrow(fishing_mortality_at_age) == 0L) {
  stop("A required source series is empty.", call. = FALSE)
}

inputs <- rbind(
  input_landings, input_catch, input_catch_weight,
  input_stock_weight, input_maturity, input_autumn_index
)
outputs <- rbind(
  output_ssb, output_total_biomass, output_recruitment, output_fbar,
  output_catches, output_discards, output_numbers, output_fishing_mortality
)

if (!all(c("type", "measure", "year", "value", "unit", "source_reference") %in% names(inputs)) ||
  any(!is.finite(inputs$value)) ||
  any(!is.finite(outputs$value)) ||
  anyDuplicated(paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey,
    inputs$year, inputs$age, sep = "|")) ||
  anyDuplicated(paste(outputs$type, outputs$measure, outputs$fleet,
    outputs$year, outputs$age, outputs$age_group, sep = "|"))) {
  stop("The candidate rows contain missing values or duplicate series keys.", call. = FALSE)
}

append_rows <- function(rows, path) {
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}
if (identical(Sys.getenv("TINYAM_IMPORT_DRY_RUN"), "1")) {
  cat(
    "Dry run validated ", nrow(inputs), " input rows, ",
    nrow(outputs), " output rows and ", nrow(assumptions),
    " assumption rows; canonical files were not changed.\n",
    sep = ""
  )
} else {
  append_rows(stock, stocks_path)
  append_rows(assessment, assessments_path)
  append_rows(assumptions, assumptions_path)
  append_rows(inputs, inputs_path)
  append_rows(outputs, outputs_path)

  register$matched_stock_id[candidate_row] <- stock_id
  register$import_status[candidate_row] <- "partial"
  register$review_date[candidate_row] <- "2026-11-02"
  register$notes[candidate_row] <- paste(
    register$notes[candidate_row],
    paste(
      "The 2026 current-unit assessment was imported as a partial canonical record.",
      "See source_reviews/ices_golden_redfish_561214_2026.md."
    )
  )
  utils::write.csv(register, register_path, row.names = FALSE, na = "",
    fileEncoding = "UTF-8"
  )

  cat(
    "Imported ", stock_id, ": ", nrow(inputs), " input rows, ",
    nrow(outputs), " output rows and ", nrow(assumptions),
    " assumption rows. Input/output statuses remain partial.\n",
    sep = ""
  )
}
