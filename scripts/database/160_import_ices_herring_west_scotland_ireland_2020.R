base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_ices_hawg_harengus_cs_6a_7b_7c")
stock_id <- "ck_ices_hawg_harengus_cs_6a_7b_7c"
assessment_id <- "ices_herring_west_scotland_ireland_2020"
report_url <- "https://doi.org/10.17895/ices.pub.6105"
prior_report_url <- "https://doi.org/10.17895/ices.pub.5460"
framework_url <- "https://doi.org/10.17895/ices.pub.5261"
taf_url <- "https://taf.ices.dk/app/stock#!/"
dry_run <- identical(tolower(Sys.getenv("SAIO_IMPORT_DRY_RUN")), "true")

verify <- function(file, expected) {
  path <- file.path(cache, file)
  if (!file.exists(path)) stop("Missing cached source file: ", file, call. = FALSE)
  actual <- digest::digest(
    readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256"
  )
  if (!identical(actual, expected)) stop("Cached source checksum failed: ", file,
    " (actual ", actual, "; expected ", expected, ")", call. = FALSE)
  path
}

report_path <- verify(
  "HAWG_2020.pdf",
  "9b2afcd445161a77c9b8c7f0b75a9853e49856559ca3455da820c197432b864e"
)
invisible(verify("HAWG_2019.pdf", "55b44709708898ab0732c7f457bac9ac31403f313f03dc6074369b1d01561d6b"))
pages <- pdftools::pdf_data(report_path)
text_pages <- pdftools::pdf_text(report_path)
tables <- c(
  "4.6.1a", "4.6.1b", "4.6.2a", "4.6.2b", "4.6.3", "4.6.4",
  "4.6.5", "4.6.6", "4.6.7", "4.6.8", "4.6.14"
)
number_text <- function(x) grepl("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([Ee][+-]?[0-9]+)?$", x)
extracted <- list()
n <- 0L
active <- ""
area <- ""
survey <- ""
header <- NULL

for (page in 487:515) {
  page_data <- pages[[page]]
  for (y in sort(unique(page_data$y))) {
    row <- page_data[page_data$y == y, , drop = FALSE]
    row <- row[order(row$x), , drop = FALSE]
    line <- paste(row$text, collapse = " ")
    match <- regmatches(line, regexec("Table[[:space:]]+(4[.]6[.][0-9]+[a-z]?)", line, ignore.case = TRUE))[[1L]]
    if (length(match) == 2L && tolower(match[[2L]]) != active) {
      active <- tolower(match[[2L]])
      header <- NULL
      area <- ""
      survey <- ""
    }
    if (grepl("area = 6[.]aN", line, ignore.case = TRUE)) area <- "6aN"
    if (grepl("area = 6aS/?7[.]bc|area = 6aS7bc", line, ignore.case = TRUE)) area <- "6aS7bc"
    if (grepl("MS_HERAS|WOS_MSHAS", line, ignore.case = TRUE)) survey <- "MS_HERAS"
    if (grepl("IBTS_Q1", line, fixed = TRUE)) survey <- "IBTS_Q1"
    if (grepl("IBTS_Q4", line, fixed = TRUE)) survey <- "IBTS_Q4"
    if (!active %in% tables) next

    years <- suppressWarnings(as.integer(row$text[grepl("^(19|20)[0-9]{2}$", row$text)]))
    if (any(tolower(row$text) == "age") && length(years)) {
      year_rows <- row[grepl("^(19|20)[0-9]{2}$", row$text), , drop = FALSE]
      header <- list(
        centers = year_rows$x + year_rows$width / 2,
        years = years,
        table = active,
        area = area,
        survey = survey
      )
      next
    }

    age_row <- which(row$x < 110 & row$text %in% as.character(1:9))
    if (!length(age_row) || is.null(header)) next
    age_i <- age_row[[1L]]
    values <- row[row$x > row$x[[age_i]] + row$width[[age_i]], , drop = FALSE]
    values <- values[number_text(values$text), , drop = FALSE]
    for (i in seq_len(nrow(values))) {
      center <- values$x[[i]] + values$width[[i]] / 2
      j <- which.min(abs(header$centers - center))
      if (abs(header$centers[[j]] - center) > 20) next
      value <- as.numeric(values$text[[i]])
      if (active == "4.6.8" && value == -1) value <- NA_real_
      n <- n + 1L
      extracted[[n]] <- data.frame(
        table = active, area = area, survey = survey,
        year = header$years[[j]], age = as.integer(row$text[[age_i]]),
        value = value
      )
    }
  }
}
series <- do.call(rbind, extracted)
f_table <- list()
f_n <- 0L
f_area <- ""
f_years <- NULL
reading_f <- FALSE
for (page in text_pages[508:512]) {
  for (line in trimws(strsplit(page, "\n")[[1L]])) {
    if (grepl("Table[[:space:]]+4[.]6[.]13", line, ignore.case = TRUE)) reading_f <- TRUE
    if (grepl("Table[[:space:]]+4[.]6[.]14", line, ignore.case = TRUE)) reading_f <- FALSE
    if (!reading_f) next
    if (grepl("area[[:space:]]*=[[:space:]]*6[.]aN", line, ignore.case = TRUE)) f_area <- "6aN"
    if (grepl("area[[:space:]]*=[[:space:]]*6aS/?7[.]?bc", line, ignore.case = TRUE)) f_area <- "6aS7bc"
    years_in_line <- regmatches(line, gregexpr("(?<![0-9])(?:19|20)[0-9]{2}(?![0-9])", line, perl = TRUE))[[1L]]
    if (length(years_in_line) && nzchar(f_area)) {
      f_years <- as.integer(years_in_line)
      next
    }
    cells <- strsplit(line, "[[:space:]]+")[[1L]]
    if (!nzchar(f_area) || is.null(f_years) || !length(cells) ||
      !cells[[1L]] %in% as.character(1:9)) next
    values <- cells[-1L]
    if (length(values) != length(f_years) || !all(number_text(values))) next
    for (j in seq_along(values)) {
      f_n <- f_n + 1L
      f_table[[f_n]] <- data.frame(
        table = "4.6.13", area = f_area, survey = "", year = f_years[[j]],
        age = as.integer(cells[[1L]]), value = as.numeric(values[[j]])
      )
    }
  }
}
f_series <- do.call(rbind, f_table)
series <- rbind(series, f_series)
series_key <- paste(series$table, series$area, series$survey, series$year, series$age, sep = "\034")
stopifnot(!anyDuplicated(series_key))

surface <- function(table, area_value = NULL, survey_value = "") {
  keep <- series$table == table & series$survey == survey_value
  if (!is.null(area_value)) keep <- keep & series$area == area_value
  out <- series[keep, , drop = FALSE]
  stopifnot(nrow(out) > 0L)
  out
}

expected_surface <- function(x, years, ages) {
  grid <- expand.grid(year = years, age = ages)
  key <- paste(grid$year, grid$age, sep = "\034")
  source_key <- paste(x$year, x$age, sep = "\034")
  value <- x$value[match(key, source_key)]
  data.frame(year = grid$year, age = grid$age, value = value)
}

years <- 1957:2019
ages <- 1:9
catch_n <- surface("4.6.1a")
catch_s <- surface("4.6.1b")
stopifnot(identical(sort(unique(catch_n$year)), years),
  identical(sort(unique(catch_s$year)), years),
  nrow(catch_n) == length(years) * length(ages),
  nrow(catch_s) == length(years) * length(ages))
for (table in c("4.6.2a", "4.6.2b", "4.6.3", "4.6.4", "4.6.5", "4.6.6", "4.6.7")) {
  stopifnot(nrow(surface(table)) == length(years) * length(ages))
}
survey_counts <- table(series$survey[series$table == "4.6.8"])
stopifnot(identical(as.integer(survey_counts[c("MS_HERAS", "IBTS_Q1", "IBTS_Q4")]),
  c(261L, 208L, 192L)))

input_header <- names(utils::read.csv(file.path(database, "inputs.csv"), nrows = 0, check.names = FALSE))
output_header <- names(utils::read.csv(file.path(database, "outputs.csv"), nrows = 0, check.names = FALSE))
blank <- function(header, n) {
  out <- as.data.frame(lapply(header, function(x) rep("", n)), stringsAsFactors = FALSE)
  names(out) <- header
  out
}
number_string <- function(x) ifelse(is.na(x), "", format(x, digits = 15, scientific = FALSE, trim = TRUE))

input_rows <- function(x, type, measure, basis, unit, source_table, fleet = "", survey = "",
                       region = "", sampling_time = "", notes = "", transformation = "") {
  out <- blank(input_header, nrow(x))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$value <- number_string(x$value)
  out$year <- number_string(x$year)
  out$year_basis <- "calendar_year"
  out$age <- number_string(x$age)
  out$unit <- unit
  out$fleet <- fleet
  out$survey <- survey
  out$sex <- "combined"
  out$region <- region
  out$season <- if (nzchar(survey)) {
    c(MS_HERAS = "June-July", IBTS_Q1 = "Q1", IBTS_Q4 = "Q4")[[survey]]
  } else "annual"
  out$sampling_time <- sampling_time
  out$source_type <- "official_table"
  out$source_reference <- paste(report_url, "Table", source_table)
  out$transformation <- transformation
  out$notes <- notes
  out
}

table_input <- function(table, type, measure, basis, unit, source_table,
                        area_value = NULL, fleet = "", survey_value = "",
                        region = "", sampling_time = "", notes = "", transformation = "") {
  x <- surface(table, area_value, survey_value)
  if (table %in% c("4.6.1a", "4.6.1b", "4.6.2a", "4.6.2b", "4.6.3", "4.6.4", "4.6.5", "4.6.6", "4.6.7")) {
    x <- expected_surface(x, years, ages)
  }
  input_rows(x, type, measure, basis, unit, source_table, fleet, survey_value,
    region, sampling_time, notes, transformation)
}

input_region <- "ICES divisions 6.a, 7.b-c (combined assessment unit)"
input_notes <- paste(
  "Transcribed from the 2020 HAWG report's official SAM assessment tables.",
  "The 9 group is the model plus group. Reported cells are unchanged."
)
catch_unit <- "thousand fish (inferred; source table unit not stated)"
inputs <- do.call(rbind, list(
  table_input("4.6.1a", "catch", "numbers_at_age", "numbers", catch_unit, "4.6.1a",
    fleet = "Catch 6aN", region = "ICES Division 6.a North",
    notes = paste(input_notes, "The table omits an explicit unit. Values remain on the printed scale; thousand fish is an interpretation, not a stated unit.")),
  table_input("4.6.1b", "catch", "numbers_at_age", "numbers", catch_unit, "4.6.1b",
    fleet = "Catch 6aS/7bc", region = "ICES divisions 6.a South, 7.b-c",
    notes = paste(input_notes, "The table omits an explicit unit. Values remain on the printed scale; thousand fish is an interpretation, not a stated unit.")),
  table_input("4.6.2a", "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "4.6.2a",
    area_value = "6aN", fleet = "Catch 6aN", region = "ICES Division 6.a North", notes = input_notes),
  table_input("4.6.2b", "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "4.6.2b",
    fleet = "Catch 6aS/7bc", region = "ICES divisions 6.a South, 7.b-c", notes = input_notes),
  table_input("4.6.3", "weight", "weight_at_age", "kg_per_fish", "kg per fish", "4.6.3",
    region = input_region, notes = input_notes),
  table_input("4.6.4", "M", "natural_mortality_at_age", "per_year", "per year", "4.6.4",
    region = input_region, notes = paste(input_notes, "Fixed age-specific natural mortality used by the assessment; not estimated.")),
  table_input("4.6.5", "maturity", "maturity_at_age", "proportion", "proportion", "4.6.5",
    region = input_region, notes = input_notes),
  table_input("4.6.6", "biology", "fraction_F_before_spawning", "proportion", "proportion", "4.6.6",
    region = input_region, notes = paste(input_notes, "Fraction of annual fishing mortality occurring before spawning.")),
  table_input("4.6.7", "biology", "fraction_M_before_spawning", "proportion", "proportion", "4.6.7",
    region = input_region, notes = paste(input_notes, "Fraction of annual natural mortality occurring before spawning.")),
  table_input("4.6.8", "index", "numbers_at_age", "index_scale", "native survey index units (unit unresolved)", "4.6.8",
    survey_value = "MS_HERAS", region = "Malin Shelf acoustic survey", sampling_time = "0.545",
    notes = paste(input_notes, "The report labels units NA. Values are retained on their native scale; -1 sentinels are recorded as unavailable."),
    transformation = "Converted source -1 missing-value sentinels to blank unavailable cells; no index scaling applied."),
  table_input("4.6.8", "index", "numbers_at_age", "index_scale", "native survey index units (unit unresolved)", "4.6.8",
    survey_value = "IBTS_Q1", region = "ICES Q1 bottom-trawl survey", sampling_time = "0.125",
    notes = paste(input_notes, "The report labels units NA. Values are retained on their native scale; no index scaling applied.")),
  table_input("4.6.8", "index", "numbers_at_age", "index_scale", "native survey index units (unit unresolved)", "4.6.8",
    survey_value = "IBTS_Q4", region = "ICES Q4 bottom-trawl survey", sampling_time = "0.875",
    notes = paste(input_notes, "The report labels units NA. Values are retained on their native scale; -1 sentinels are recorded as unavailable."),
    transformation = "Converted source -1 missing-value sentinels to blank unavailable cells; no index scaling applied.")
))

summary_pages <- text_pages[507:508]
summary_lines <- unlist(strsplit(summary_pages, "\n"))
summary_lines <- trimws(summary_lines[grepl("^(19[0-9]{2}|20[0-9]{2})[[:space:]]+", trimws(summary_lines))])
summary_values <- lapply(summary_lines, function(line) suppressWarnings(as.numeric(strsplit(line, "[[:space:]]+")[[1L]])))
summary_values <- summary_values[lengths(summary_values) == 7L]
summary <- as.data.frame(do.call(rbind, summary_values))
names(summary) <- c("year", "recruitment", "total_biomass", "SSB", "landings", "Fbar", "landings_sop")
stopifnot(identical(as.integer(summary$year), years))
catch_weight_n <- expected_surface(surface("4.6.2a", "6aN"), years, ages)
catch_weight_s <- expected_surface(surface("4.6.2b"), years, ages)
catch_biomass_rows <- do.call(rbind, lapply(list(
  list(catch_n, catch_weight_n), list(catch_s, catch_weight_s)
), function(x) {
  paired <- merge(x[[1L]][, c("year", "age", "value")],
    x[[2L]][, c("year", "age", "value")], by = c("year", "age"),
    suffixes = c("_numbers", "_weight"))
  data.frame(year = paired$year,
    tonnes = paired$value_numbers * paired$value_weight)
}))
catch_biomass <- stats::aggregate(tonnes ~ year, catch_biomass_rows, sum)
landings_check <- merge(summary[, c("year", "landings")], catch_biomass, by = "year")
landings_ratio <- landings_check$tonnes / landings_check$landings
material_landings <- landings_check$landings > 100
stopifnot(all(is.finite(landings_ratio[material_landings])),
  min(landings_ratio[material_landings]) > 0.5,
  max(landings_ratio[material_landings]) < 2,
  summary$landings[summary$year == 2019] == 3611,
  summary$Fbar[summary$year == 2019] == 0.0814)

output_rows <- function(type, measure, year, age = NA_integer_, value, unit,
                        region = "", source_table, source_type = "official_table", notes = "") {
  n <- length(value)
  out <- blank(output_header, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- number_string(rep_len(year, n))
  out$age <- number_string(rep_len(age, n))
  out$age_group <- ifelse(!is.na(rep_len(age, n)) & rep_len(age, n) == 9, "9+", "")
  out$value <- number_string(value)
  out$unit <- unit
  out$sex <- "combined"
  out$region <- region
  out$season <- "annual"
  out$source_type <- source_type
  out$source_reference <- paste(report_url, "Table", source_table)
  out$notes <- notes
  out
}

n_at_age <- expected_surface(surface("4.6.14"), years, ages)
f_n <- expected_surface(surface("4.6.13", "6aN"), years, ages)
f_s <- expected_surface(surface("4.6.13", "6aS7bc"), years, ages)
stopifnot(nrow(f_n) == length(years) * length(ages), nrow(f_s) == length(years) * length(ages),
  nrow(n_at_age) == length(years) * length(ages),
  all(is.finite(n_at_age$value)), all(is.finite(f_n$value)), all(is.finite(f_s$value)))
recruitment_check <- merge(summary[c("year", "recruitment")],
  n_at_age[n_at_age$age == 1L, c("year", "value")], by = "year")
stopifnot(identical(as.integer(recruitment_check$year), years),
  all(abs(recruitment_check$recruitment - recruitment_check$value) <= 1))

summary_outputs <- do.call(rbind, list(
  output_rows("recruitment", "recruitment", summary$year, value = summary$recruitment,
    unit = "thousand fish", source_table = "4.6.12", notes = "Reported age-1 recruitment; no uncertainty values are tabulated."),
  output_rows("biomass", "total_biomass", summary$year, value = summary$total_biomass,
    unit = "tonnes", source_table = "4.6.12", notes = "Reported total stock biomass; no uncertainty values are tabulated."),
  output_rows("biomass", "SSB", summary$year, value = summary$SSB,
    unit = "tonnes", source_table = "4.6.12", notes = "Reported spawning-stock biomass; no uncertainty values are tabulated."),
  output_rows("mortality", "Fbar", summary$year, value = summary$Fbar,
    unit = "per year", source_table = "4.6.12", notes = "Reported Fbar for ages 3-6; no uncertainty values are tabulated.")
))
summary_outputs$age_group[summary_outputs$measure == "Fbar"] <- "3-6"
n_outputs <- output_rows("population", "numbers_at_age", n_at_age$year,
  n_at_age$age, n_at_age$value, "thousand fish (inferred; Table 4.6.14 labels units NA)", source_table = "4.6.14",
  notes = "Reported population numbers-at-age; age 9 is the plus group. The report labels units NA; scale is interpreted as thousand fish using the age-0 recruitment scale. No uncertainty values are tabulated.")
f_outputs <- rbind(
  output_rows("mortality", "fishing_mortality_at_age", f_n$year, f_n$age, f_n$value,
    "per year", "ICES Division 6.a North", "4.6.13",
    notes = "Reported area-specific instantaneous fishing mortality; retained separately by area. Age 9 is the plus group."),
  output_rows("mortality", "fishing_mortality_at_age", f_s$year, f_s$age, f_s$value,
    "per year", "ICES divisions 6.a South, 7.b-c", "4.6.13",
    notes = "Reported area-specific instantaneous fishing mortality; retained separately by area. Age 9 is the plus group.")
)
total_numbers <- stats::aggregate(value ~ year, n_at_age, sum)
total_number_output <- output_rows("population", "total_numbers", total_numbers$year,
  value = total_numbers$value, unit = "thousand fish (inferred; Table 4.6.14 labels units NA)", source_table = "4.6.14",
  source_type = "derived_source_output",
  notes = "Derived by summing reported N-at-age over ages 1-9. The report does not tabulate total abundance or its uncertainty; no uncertainty is inferred.")
outputs <- rbind(summary_outputs, n_outputs, f_outputs, total_number_output)

assumption <- function(component, setting, value, source_reference, notes = "") {
  header <- names(utils::read.csv(file.path(database, "assumptions.csv"), nrows = 0, check.names = FALSE))
  out <- blank(header, 1L)
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "official_run", "HAWG 2020 final combined 6.a and 7.b-c assessment; terminal data year 2019", report_url,
    "The report identifies a final multi-fleet SAM assessment following the 2019 interbenchmark. The combined unit was later split at the 2022 benchmark; successor-stock values are not mixed into this record."),
  assumption("assessment", "model_configuration", "FLSAM 2.1.0; FLCore 2.6.10; R 3.6.0; SAM config Table 4.6.10", paste(report_url, "Table 4.6.10-4.6.11")),
  assumption("population", "age_range", "Ages 1-9; age 9 is a plus group; modeled years 1957-2019", paste(report_url, "Tables 4.6.9-4.6.10")),
  assumption("population", "recruitment", "No stock-recruitment relationship (srr=0); recruitment process variance is separate from the shared age-2+ survival-process variance", paste(report_url, "Table 4.6.10"),
    "SAM configuration logN.vars is 0 for age 1 and 1 for ages 2-9."),
  assumption("mortality", "fishing_mortality", "Multi-fleet SAM with separate catch N and catch S/7bc F states; cor.F=2", paste(report_url, "Table 4.6.10"),
    "The configuration uses age-specific F states and several variance groups. F output remains split by area in outputs.csv."),
  assumption("mortality", "natural_mortality", "Fixed age-specific M from the 2011 SMS key run, averaged over 1974-2010 and applied as the age pattern", paste(report_url, "Table 4.6.4; section 4.4.3"),
    "M-at-age is an input, not an estimated SAM output."),
  assumption("index", "catchability_sharing", "Age-specific q within each survey; ages 8 and 9 share q; no q for absent survey-age cells", paste(report_url, "Table 4.6.10")),
  assumption("index", "observation_error", "Lognormal likelihood; MS_HERAS age-specific SD groups and Q1/Q4 age groups; AR(1) residual correlation for the three survey fleets", paste(report_url, "Table 4.6.10"),
    ""),
  assumption("biology", "spawning", "F and M fractions before spawning are each 0.67 at every modeled age and year", paste(report_url, "Tables 4.6.5-4.6.7"),
    "The translation uses spawn_time=0.67, consistent with both source fractions."),
  assumption("index", "survey_timing", "MS_HERAS 0.52-0.57; IBTS_Q1 0.00-0.25; IBTS_Q4 0.75-1.00", paste(report_url, "Table 4.6.8"),
    "Stored sampling times are interval midpoints 0.545, 0.125 and 0.875, not exact haul dates."),
  assumption("assessment", "native_run_access", "HAWG 2020 reports that the assessment scripts are hosted through TAF; no public native fitted object or executable run was recovered", paste(report_url, "section 1.9; Table 4.6.10"),
    paste("The current TAF portal is", taf_url, "and requires authorized access to its stock repositories.")),
  assumption("assessment", "data_precision", "Report tables provide point estimates and source inputs, but no numerical uncertainty table was recovered", report_url,
    "Uncertainty is shown in figures only; standard errors and intervals are left blank."),
  assumption("assessment", "historical_unit", "Combined 6.a North and 6.a South/7.b-c unit used through the 2020 assessment; divided into successor units following the 2022 benchmark", "https://ices-library.figshare.com/articles/report/Herring_Assessment_Working_Group_for_the_Area_South_of_62_N_HAWG_/19249010",
    "The 2022 stock split is not treated as a revision to this combined-unit assessment."),
  assumption("assessment", "earlier_detailed_run", "The previous detailed assessment was HAWG 2019 with terminal year 2018", prior_report_url,
    "The 2020 assessment updates the combined-unit model through 2019 and is used for the current detailed record.")
))

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2020,
  terminal_year = 2019,
  estimate_terminal_year = 2019,
  assessment_type = "ICES annual analytical assessment update",
  model_family = "SAM (FLSAM)",
  model_version = "FLSAM 2.1.0; FLCore 2.6.10; R 3.6.0",
  is_current = "TRUE",
  is_applied = "TRUE",
  framework_year = 2019,
  assessment_url = report_url,
  framework_url = framework_url,
  data_url = report_url,
  model_url = "",
  repository_url = taf_url,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Latest detailed assessment of the combined her.27.6a7bc unit; terminal year 2019.",
    "Inputs and main fitted trajectories are transcribed from the official HAWG report.",
    "No native executed run or numerical uncertainty tables were recovered.",
    "Both 6.aN and 6.aS/7.b-c catch-at-age tables include 2019."
  ),
  stringsAsFactors = FALSE
)

stocks <- utils::read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-HAWG_harengus_CS 6a,7b,7c",
  stock$scientific_name == "Clupea harengus")
stock$authority_stock_id <- "her.27.6a7bc"
stock$common_name <- "West of Scotland and West of Ireland herring"
stock$area <- "ICES divisions 6.a and 7.b-c (combined historical assessment unit)"
stock$region <- "West of Scotland and West of Ireland"
stock$ocean <- "Northeast Atlantic"
stock$notes <- paste(
  "Verified ICES stock her.27.6a7bc; the Charbonneau-Keith stock_id and identifier are retained.",
  "The combined 6.a North and 6.a South/7.b-c unit was assessed together through 2020; successor units were assessed separately after the 2022 benchmark.",
  "Source review: source_reviews/ices_herring_west_scotland_ireland.md."
)

write_stock_row <- function(path, row, id) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  newlines <- which(bytes == as.raw(10L))
  starts <- c(1L, head(newlines, -1L) + 1L)
  ends <- c(newlines - 1L, length(bytes))
  prefix <- charToRaw(paste0('"', id, '",'))
  matches <- vapply(seq_along(starts), function(i) {
    start <- starts[[i]]
    end <- ends[[i]]
    end >= start + length(prefix) - 1L &&
      identical(bytes[start:(start + length(prefix) - 1L)], prefix)
  }, logical(1))
  if (sum(matches) != 1L) stop("Expected exactly one existing stock row for ", id, call. = FALSE)
  i <- which(matches)
  start <- starts[[i]]
  lf <- if (i <= length(newlines)) newlines[[i]] else NA_integer_
  has_cr <- !is.na(lf) && lf > 1L && bytes[[lf - 1L]] == as.raw(13L)
  terminator <- if (is.na(lf)) raw() else if (has_cr) as.raw(c(13L, 10L)) else as.raw(10L)
  row_file <- tempfile(fileext = ".csv")
  on.exit(unlink(row_file), add = TRUE)
  utils::write.table(row, row_file, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readBin(row_file, "raw", n = file.info(row_file)$size)
  while (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- head(replacement, -1L)
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- head(replacement, -1L)
  before <- if (start > 1L) bytes[seq_len(start - 1L)] else raw()
  after_start <- if (is.na(lf)) length(bytes) + 1L else lf + 1L
  after <- if (after_start <= length(bytes)) bytes[after_start:length(bytes)] else raw()
  updated <- c(before, replacement, terminator, after)
  updated_file <- tempfile(tmpdir = dirname(path))
  on.exit(unlink(updated_file), add = TRUE)
  writeBin(updated, updated_file)
  if (!file.copy(updated_file, path, overwrite = TRUE)) stop("Could not update stocks.csv.", call. = FALSE)
}

write_rows <- function(file, rows, id = assessment_id) {
  path <- file.path(database, file)
  expected <- names(utils::read.csv(path, nrows = 0, check.names = FALSE))
  stopifnot(identical(names(rows), expected))
  if ("assessment_id" %in% names(rows) && any(rows$assessment_id != id)) stop("Unexpected assessment identifier in ", file, call. = FALSE)
  if (file %in% c("inputs.csv", "outputs.csv")) {
    utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", fileEncoding = "UTF-8")
  } else {
    utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", fileEncoding = "UTF-8")
  }
}

existing_assessments <- utils::read.csv(file.path(database, "assessments.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stopifnot(!assessment_id %in% existing_assessments$assessment_id,
  !any(inputs$assessment_id %in% existing_assessments$assessment_id))
existing_inputs_id <- any(grepl(paste0('^"', assessment_id, '"[,]'), readLines(file.path(database, "inputs.csv"), warn = FALSE), perl = TRUE))
existing_outputs_id <- any(grepl(paste0('^"', assessment_id, '"[,]'), readLines(file.path(database, "outputs.csv"), warn = FALSE), perl = TRUE))
if (existing_inputs_id || existing_outputs_id) stop("Assessment inputs or outputs already exist; refusing duplicate import.", call. = FALSE)

if (dry_run) {
  cat("Dry run passed:", nrow(inputs), "input rows;", nrow(assumptions),
    "assumptions;", nrow(outputs), "output rows.\n")
  cat("Survey rows:", paste(names(survey_counts), as.integer(survey_counts), collapse = "; "),
    "with", sum(is.na(series$value[series$table == "4.6.8"])), "unavailable sentinel cells.\n")
  cat("Catch N years:", min(catch_n$year), "-", max(catch_n$year),
    "; catch S years:", min(catch_s$year), "-", max(catch_s$year),
    "; max recruitment/N-age-1 rounding difference:",
    max(abs(recruitment_check$recruitment - recruitment_check$value)), "\n")
  cat("Catch-number × catch-weight / landings ratio across years with >100 t landings:",
    paste(range(landings_ratio[material_landings]), collapse = " - "), "\n")
  quit(save = "no", status = 0L)
}

stock_path <- file.path(database, "stocks.csv")
write_stock_row(stock_path, stock, stock_id)
write_rows("assessments.csv", assessment)
write_rows("assumptions.csv", assumptions)
write_rows("inputs.csv", inputs)
write_rows("outputs.csv", outputs)

cat("Imported", assessment_id, "with", nrow(inputs), "input rows,", nrow(assumptions),
  "assumptions, and", nrow(outputs), "output rows.\n")
