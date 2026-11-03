assessment_id <- "ices_saithe_iceland_2026"
stock_id <- "ck_ices_nwwg_virens_fa5a"
root <- "."
database_dir <- file.path(root, "database")
cache_dir <- file.path(root, "source_cache", "ices_saithe_iceland_2026")
tables_path <- file.path(cache_dir, "mfri_2026_tables.html")
sag_path <- file.path(cache_dir, "ices_sag_2026_stockdata.xml")

if (!requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("xml2", quietly = TRUE) ||
    !file.exists(tables_path) || !file.exists(sag_path)) {
  stop("Cached MFRI tables, ICES SAG data, jsonlite, and xml2 are required.", call. = FALSE)
}

read_table <- function(path) {
  utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
    na.strings = c("", "NA"))
}
write_table <- function(x, path) {
  utils::write.csv(x, path, row.names = FALSE, na = "")
}
align_columns <- function(x, template) {
  for (name in setdiff(names(template), names(x))) x[[name]] <- NA
  x[names(template)]
}

html <- paste(readLines(tables_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n")
blocks <- regmatches(html, gregexpr(
  '(?is)<script[^>]+type="application/json"[^>]*data-for="[^"]+"[^>]*>.*?</script>',
  html, perl = TRUE
))[[1]]
if (length(blocks) != 15L) {
  stop("The cached MFRI table page no longer has the expected 15 table widgets.", call. = FALSE)
}

widgets <- lapply(blocks, function(block) {
  json <- sub("(?is)^.*?>(.*)</script>$", "\\1", block, perl = TRUE)
  jsonlite::fromJSON(json, simplifyVector = FALSE)$x
})
read_widget <- function(i) {
  widget <- widgets[[i]]
  container <- xml2::read_html(widget$container)
  headers <- xml2::xml_text(xml2::xml_find_all(container, ".//th"))
  columns <- lapply(widget$data, function(column) {
    vapply(column, function(cell) {
      if (is.null(cell) || length(cell) == 0L) NA_character_ else as.character(cell[[1]])
    }, character(1))
  })
  result <- as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
  if (length(headers) != ncol(result)) {
    stop("A cached MFRI table has a header/data column mismatch.", call. = FALSE)
  }
  names(result) <- headers
  result
}
as_number <- function(x) suppressWarnings(as.numeric(as.character(x)))
long_age_table <- function(wide, ages, drop_missing = TRUE) {
  rows <- lapply(ages, function(age) {
    data.frame(
      year = as.integer(wide$Year),
      age = as.integer(age),
      value = as_number(wide[[as.character(age)]]),
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)
  if (drop_missing) result <- result[!is.na(result$value), , drop = FALSE]
  result
}
check_saithe_table <- function(x, years, ages, label) {
  if (!all(x$Species == "Saithe") ||
      !identical(sort(unique(as.integer(x$Year))), years) ||
      !setequal(as.integer(names(x)[-(1:3)]), ages)) {
    stop(label, " failed stock identity, year, or age checks.", call. = FALSE)
  }
  invisible(x)
}

catch_wide <- read_widget(5L)
stock_weight_wide <- read_widget(8L)
maturity_wide <- read_widget(9L)
index_wide <- read_widget(10L)
numbers_wide <- read_widget(14L)
fishing_mortality_wide <- read_widget(15L)
summary_wide <- read_widget(2L)
ages <- 3:14
check_saithe_table(catch_wide, 1980:2025, ages, "Catch-at-age table")
check_saithe_table(stock_weight_wide, 1980:2026, ages, "Stock-weight table")
check_saithe_table(maturity_wide, 1980:2026, ages, "Maturity table")
check_saithe_table(index_wide, 1985:2026, ages, "Spring-index table")
check_saithe_table(numbers_wide, 1980:2026, ages, "Numbers-at-age output table")
check_saithe_table(fishing_mortality_wide, 1980:2025, ages, "F-at-age output table")

sag <- xml2::read_xml(sag_path)
sag_value <- function(name) {
  value <- xml2::xml_text(xml2::xml_find_first(sag, paste0("./", name)))
  if (!length(value) || !nzchar(trimws(value))) NA_character_ else trimws(value)
}
if (sag_value("StockCode") != "pok.27.5a" ||
    as.integer(sag_value("AssessmentYear")) != 2026L ||
    as.integer(sag_value("RecruitmentAge")) != 3L ||
    sag_value("ConfidenceIntervalDefinition") != "95%") {
  stop("The cached ICES SAG XML is not the 2026 pok.27.5a source.", call. = FALSE)
}
if (!identical(sag_value("CustomSeriesName1"), "B_{4+}") ||
    !identical(sag_value("CustomSeriesName4"), "Fbar")) {
  stop("The cached ICES SAG XML custom-series definitions changed.", call. = FALSE)
}
fish_data <- xml2::xml_find_all(sag, "./Fish_Data")
xml_rows <- do.call(rbind, lapply(fish_data, function(node) {
  value <- function(name) {
    x <- xml2::xml_text(xml2::xml_find_first(node, paste0("./", name)))
    if (!length(x) || !nzchar(trimws(x))) NA_real_ else as_number(x)
  }
  data.frame(
    year = as.integer(value("Year")),
    recruitment = value("Recruitment"),
    recruitment_lwr = value("Low_Recruitment"),
    recruitment_upr = value("High_Recruitment"),
    ssb = value("StockSize"),
    ssb_lwr = value("Low_StockSize"),
    ssb_upr = value("High_StockSize"),
    b4 = value("CustomSeries1"),
    b4_lwr = value("CustomSeries2"),
    b4_upr = value("CustomSeries3"),
    fbar = value("FishingPressure"),
    fbar_lwr = value("Low_FishingPressure"),
    fbar_upr = value("High_FishingPressure"),
    stringsAsFactors = FALSE
  )
}))
xml_rows <- xml_rows[order(xml_rows$year), , drop = FALSE]
if (!identical(xml_rows$year, 1980:2026)) {
  stop("The ICES SAG XML output series failed year coverage checks.", call. = FALSE)
}

if (any(!is.finite(xml_rows$ssb)) || any(!is.finite(xml_rows$recruitment)) ||
    any(!is.finite(xml_rows$b4)) ||
    any(xml_rows$ssb_lwr > xml_rows$ssb | xml_rows$ssb > xml_rows$ssb_upr, na.rm = TRUE) ||
    any(xml_rows$recruitment_lwr > xml_rows$recruitment |
      xml_rows$recruitment > xml_rows$recruitment_upr, na.rm = TRUE) ||
    any(xml_rows$b4_lwr > xml_rows$b4 | xml_rows$b4 > xml_rows$b4_upr, na.rm = TRUE)) {
  stop("The ICES SAG annual values or 95% interval bounds failed range checks.", call. = FALSE)
}

summary_year <- as.integer(summary_wide$Year)
summary_row <- function(year) summary_wide[summary_year == year, , drop = FALSE]
for (year in 1980:2026) {
  sag_row <- xml_rows[xml_rows$year == year, , drop = FALSE]
  tab <- summary_row(year)
  for (pair in list(c("SSB", "ssb"), c("Recruitment", "recruitment"),
                    c("Ref. Biomass", "b4"))) {
    if (nrow(tab) != 1L ||
        round(as_number(tab[[pair[[1]]]])) != round(sag_row[[pair[[2]]]])) {
      stop("MFRI and ICES SAG annual values do not agree for year ", year, ".", call. = FALSE)
    }
  }
  if (year <= 2025 &&
      round(as_number(tab[["HR"]]), 3) != round(xml_rows$fbar[xml_rows$year == year], 3)) {
    stop("MFRI and ICES SAG fishing-pressure values do not agree for year ", year, ".", call. = FALSE)
  }
}

source_notes <- paste(
  "Source age 14 is the 14+ group. The official report uses the combined",
  "Icelandic commercial catch and spring survey series."
)
make_input <- function(x, type, measure, basis, unit, source_reference,
                       notes, survey = NA_character_, season = NA_character_,
                       sampling_time = NA_real_, source_type = "official_table",
                       transformation = NA_character_) {
  x$assessment_id <- assessment_id
  x$type <- type
  x$measure <- measure
  x$basis <- basis
  x$fleet <- NA_character_
  x$survey <- survey
  x$sex <- "combined"
  x$region <- "ICES 5.a"
  x$season <- season
  x$year_basis <- ifelse(is.na(x$year), NA_character_, "calendar_year")
  x$unit <- unit
  x$sampling_time <- sampling_time
  x$source_type <- source_type
  x$source_reference <- source_reference
  x$transformation <- transformation
  x$notes <- notes
  x[c(
    "assessment_id", "type", "measure", "basis", "fleet", "survey",
    "sex", "region", "season", "year", "year_basis", "age", "value",
    "unit", "sampling_time", "source_type", "source_reference",
    "transformation", "notes"
  )]
}

input_rows <- rbind(
  make_input(
    long_age_table(catch_wide, ages), "catch", "numbers_at_age", "numbers",
    "thousand fish", "MFRI 2026 assessment tables, Table 5 (catch numbers at age)",
    paste(source_notes, "Catch-at-age is in thousands of fish.")
  ),
  make_input(
    long_age_table(stock_weight_wide, ages), "weight", "weight_at_age",
    "g_per_fish", "g per fish",
    "MFRI 2026 assessment tables, Table 8 (stock weight at age)",
    paste(source_notes, "Stock weights are reported in grams per fish.")
  ),
  make_input(
    long_age_table(maturity_wide, ages), "maturity", "maturity_at_age",
    "proportion", "proportion mature",
    "MFRI 2026 assessment tables, Table 9 (maturity at age)",
    paste(source_notes, "Maturity is a proportion.")
  ),
  make_input(
    long_age_table(index_wide, ages, drop_missing = FALSE), "index", "numbers_at_age",
    "index_scale", "survey index (unit unresolved)",
    "MFRI 2026 assessment tables, Table 10 (IS-SMB spring survey index)",
    paste(source_notes,
      "The report does not state an absolute scale multiplier; values remain on the published index scale."
    ),
    survey = "IS-SMB", season = "spring"
  ),
  make_input(
    data.frame(year = NA_integer_, age = ages, value = 0.2),
    "M", "natural_mortality_at_age", "per_year", "per year",
    "MFRI 2026 technical report; ICES WKICEGAD 2025, section 5",
    "Natural mortality is fixed at 0.2 per year for all assessment ages.",
    source_type = "official_document"
  )
)
if (any(input_rows$value < 0, na.rm = TRUE) ||
    any(!input_rows$age %in% ages) ||
    anyDuplicated(input_rows[c("assessment_id", "type", "measure", "survey", "year", "age")])) {
  stop("The candidate input rows failed non-negative, age, or uniqueness checks.", call. = FALSE)
}

make_output <- function(year, value, type, measure, unit, source_type,
                        source_reference, age = NA_integer_,
                        age_group = NA_character_, lwr = NA_real_,
                        upr = NA_real_, notes = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = "combined",
    region = "ICES 5.a", season = NA_character_, year = as.integer(year),
    age = as.integer(age), age_group = age_group, value = as.numeric(value),
    se = NA_real_, lwr = as.numeric(lwr), upr = as.numeric(upr),
    unit = unit, source_type = source_type, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
output_rows <- list()
for (name in names(list(
  numbers_at_age = numbers_wide,
  fishing_mortality_at_age = fishing_mortality_wide
))) {
  wide <- if (name == "numbers_at_age") numbers_wide else fishing_mortality_wide
  long <- long_age_table(wide, ages)
  for (i in seq_len(nrow(long))) {
    is_n <- name == "numbers_at_age"
    output_rows[[length(output_rows) + 1L]] <- make_output(
      long$year[[i]], long$value[[i]],
      if (is_n) "population" else "mortality", name,
      if (is_n) "thousand fish" else "yr-1", "official_table",
      if (is_n) {
        "MFRI 2026 assessment tables, Table 14 (stock numbers at age)"
      } else {
        "MFRI 2026 assessment tables, Table 15 (fishing mortality at age)"
      },
      age = long$age[[i]],
      age_group = if (long$age[[i]] == 14L) "14+" else NA_character_,
      notes = paste(
        "Age 14 is the 14+ group.",
        if (is_n) "Point estimate; age-specific uncertainty is not reported."
        else "Point estimate; age-specific uncertainty is not reported."
      )
    )
  }
}

for (i in seq_len(nrow(xml_rows))) {
  x <- xml_rows[i, , drop = FALSE]
  y <- x$year[[1]]
  output_rows[[length(output_rows) + 1L]] <- make_output(
    y, x$ssb, "biomass", "SSB", "tonnes", "official_machine_readable",
    "ICES SAG 2026 source data, key 22624; XML series StockSize",
    lwr = x$ssb_lwr, upr = x$ssb_upr,
    notes = paste(
      "Reported point estimate; ICES SAG defines the intervals as 95%.",
      "The exact point-estimate convention and within-year SSB timing are not stated."
    )
  )
  output_rows[[length(output_rows) + 1L]] <- make_output(
    y, x$recruitment, "recruitment", "recruitment", "thousand fish",
    "official_machine_readable",
    "ICES SAG 2026 source data, key 22624; XML series Recruitment",
    age = 3L, lwr = x$recruitment_lwr, upr = x$recruitment_upr,
    notes = "Recruitment is at age 3; ICES SAG defines the intervals as 95%."
  )
  output_rows[[length(output_rows) + 1L]] <- make_output(
    y, x$b4, "biomass", "biomass_by_age_group", "tonnes",
    "official_machine_readable",
    "ICES SAG 2026 source data, key 22624; XML custom series B4+",
    age_group = "4+", lwr = x$b4_lwr, upr = x$b4_upr,
    notes = "Reference biomass for ages 4+ uses stock weights; 95% intervals."
  )
  if (is.finite(x$fbar[[1]])) {
    output_rows[[length(output_rows) + 1L]] <- make_output(
      y, x$fbar, "mortality", "Fbar", "Frel", "official_machine_readable",
      "ICES SAG 2026 source data, key 22624; XML series FishingPressure",
      age_group = "4-9", lwr = x$fbar_lwr, upr = x$fbar_upr,
      notes = "ICES SAG reports FishingPressure and agrees to rounding with MFRI Table 2 HR through 2025; Table 2 F is a distinct, undefined summary. MFRI identifies ages 4-9 as the F range. 95% intervals."
    )
  }
}

outputs_new <- do.call(rbind, output_rows)
if (any(outputs_new$value < 0, na.rm = TRUE) ||
    any(outputs_new$lwr > outputs_new$value | outputs_new$value > outputs_new$upr, na.rm = TRUE)) {
  stop("The candidate outputs failed range checks.", call. = FALSE)
}

assessment_url <- "https://www.hafogvatn.is/static/extras/images/3_pol_2026_1_techreport_en.html"
framework_url <- "https://doi.org/10.17895/ices.pub.28444499"
data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22624"
assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2025L,
  estimate_terminal_year = 2026L,
  assessment_type = "annual_assessment",
  model_family = "SAM",
  model_version = "MFRI 2026 production assessment; native fit object not recovered",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2025L,
  assessment_url = assessment_url,
  framework_url = framework_url,
  data_url = data_url,
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "complete",
  outputs_status = "partial",
  notes = paste(
    "Catch and age-specific F are available through 2025; the spring survey,",
    "population estimates, and aggregate SSB/recruitment are available through 2026.",
    "The exact 2026 production configuration is not fully published."
  ),
  stringsAsFactors = FALSE
)

assumption_source <- paste(
  "MFRI 2026 technical report, model setup and data tables;",
  "ICES WKICEGAD 2025, section 5; ICES SAG 2026 key 22624"
)
make_assumption <- function(component, setting, value, notes,
                             fleet = NA_character_, survey = NA_character_,
                             season = NA_character_) {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = fleet, survey = survey, sex = "combined",
    region = "ICES 5.a", season = season, setting = setting,
    value = value, source_reference = assumption_source, notes = notes,
    stringsAsFactors = FALSE
  )
}
assumptions_new <- do.call(rbind, list(
  make_assumption("assessment", "model_family",
    "SAM statistical catch-at-age state-space model",
    "2026 MFRI report describes the applied production assessment."),
  make_assumption("population", "model_ages",
    "Ages 3-14; age 14 is the plus group",
    "The 2026 report gives catch and survey ages 3-14+; output tables list age 14."),
  make_assumption("population", "model_start_year",
    "1979 in the 2026 MFRI report; 1980 in the 2025 benchmark",
    "The 2026 report and 2025 framework differ. The translated fit starts in 1980 because the current report tables provide complete catch and biology from 1980."),
  make_assumption("recruitment", "recruitment_age",
    "Age 3",
    "Confirmed in the 2026 ICES SAG machine-readable source data."),
  make_assumption("recruitment", "production_recruitment_model",
    "The 2026 MFRI report says recruitment is a moving average of previous years",
    "The 2025 benchmark describes a piecewise-constant stock-recruitment model with no breakpoints. The exact 2026 production configuration was not recovered."),
  make_assumption("recruitment", "benchmark_recruitment_model",
    "Piecewise-constant stock-recruitment function, no breakpoints",
    "ICES WKICEGAD 2025 benchmark configuration; not confirmed as the exact 2026 production setting."),
  make_assumption("F", "F_age_range",
    "4-9",
    "Age range given in the 2026 MFRI model setup; ICES SAG describes the aggregate F series as Frel."),
  make_assumption("F", "process",
    "Time-varying fishing mortality; 2025 benchmark uses a random-walk F process with AR(1) across ages",
    "Exact 2026 process covariance and age parameter sharing were not recovered."),
  make_assumption("M", "natural_mortality",
    "Fixed at 0.2 per year for all assessment ages",
    "2026 MFRI report and 2025 ICES benchmark."),
  make_assumption("catch", "catch_series",
    "Commercial catch numbers-at-age, 1980-2025",
    "Source table contains the combined catch-at-age series; no gear split is used by this SAM model."),
  make_assumption("index", "survey_series",
    "IS-SMB spring bottom-trawl survey, 1985-2026",
    "The 2025 benchmark selected the spring survey as the preferred index; 2026 report uses SMB."),
  make_assumption("index", "index_scale",
    "Published survey index values retained without a scale multiplier",
    "No physical unit multiplier is stated in the 2026 report; raw source values are preserved."),
  make_assumption("index", "sampling_time",
    "Unknown",
    "The source documents a March spring survey but does not give the SAM sampling fraction; 0.20 is a month-midpoint approximation.",
    survey = "IS-SMB", season = "spring"),
  make_assumption("index", "observation_covariance",
    "Default data weighting is reported; exact 2026 observation covariance is unavailable",
    "The 2025 benchmark evaluates age-correlated observation residuals, but the production 2026 configuration is not available."),
  make_assumption("weight", "weight_at_age",
    "Stock weight-at-age from the March spring survey",
    "The 2026 assessment uses stock weights; report values are preserved in grams per fish."),
  make_assumption("maturity", "maturity_at_age",
    "Maturity-at-age from the March spring survey; a three-year running average is used",
    "The 2026 MFRI report describes this smoothing."),
  make_assumption("biomass", "B4+",
    "Reference biomass of age 4+ using stock weights",
    "The management reference biomass is distinct from SSB and is reported in tonnes.")
))

stocks_file <- file.path(database_dir, "stocks.csv")
assessments_file <- file.path(database_dir, "assessments.csv")
assumptions_file <- file.path(database_dir, "assumptions.csv")
inputs_file <- file.path(database_dir, "inputs.csv")
outputs_file <- file.path(database_dir, "outputs.csv")
stocks <- read_table(stocks_file)
assessments <- read_table(assessments_file)
assumptions <- read_table(assumptions_file)
inputs <- read_table(inputs_file)
outputs <- read_table(outputs_file)

stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) {
  stop("Expected one existing Charbonneau stock row for Icelandic saithe.", call. = FALSE)
}
if (any(assessments$assessment_id == assessment_id, na.rm = TRUE) ||
    any(assumptions$assessment_id == assessment_id, na.rm = TRUE) ||
    any(inputs$assessment_id == assessment_id, na.rm = TRUE) ||
    any(outputs$assessment_id == assessment_id, na.rm = TRUE)) {
  stop("Icelandic saithe 2026 is already present in one or more assessment tables.", call. = FALSE)
}

stocks$authority_stock_id[stock_row] <- "pok.27.5a"
stocks$common_name[stock_row] <- "Icelandic saithe"
stocks$area[stock_row] <- "Division 5.a (Iceland grounds)"
stocks$region[stock_row] <- "Icelandic waters"
stocks$ocean[stock_row] <- "Northeast Atlantic"
stocks$notes[stock_row] <- paste(
  "Charbonneau-Keith identity retained (ICES-NWWG_virens_FA5a).",
  "Official ICES stock pok.27.5a is saithe in Division 5.a (Iceland grounds),",
  "distinct from the Northeast Arctic, North Sea, and Faroe stocks.",
  "Source review: source_reviews/ices_saithe_iceland_2026.md."
)

assessments <- rbind(assessments, align_columns(assessment, assessments))
assumptions <- rbind(assumptions, align_columns(assumptions_new, assumptions))
inputs <- rbind(inputs, align_columns(input_rows, inputs))
outputs <- rbind(outputs, align_columns(outputs_new, outputs))

write_table(stocks, stocks_file)
write_table(assessments, assessments_file)
write_table(assumptions, assumptions_file)
write_table(inputs, inputs_file)
write_table(outputs, outputs_file)

cat(
  "Imported Icelandic saithe 2026: ",
  nrow(input_rows), " inputs, ", nrow(assumptions_new),
  " assumptions, ", nrow(outputs_new), " outputs.
", sep = ""
)
