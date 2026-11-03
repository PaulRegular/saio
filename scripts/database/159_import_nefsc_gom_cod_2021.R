base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_nefsc_saw_morhua_gom_2021")
archive <- file.path(cache, "2021_COD_GM.zip")
assessment_id <- "nefsc_gom_cod_2021_m02"
stock_id <- "ck_nefsc_saw_morhua_gom"

assessment_url <- paste0(
  "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?",
  "year=2021&species_id=4&stock_id=2&review_type_id=3&filename=2021_COD_GM.zip"
)
framework_url <- "https://repository.library.noaa.gov/view/noaa/39403/noaa_39403_DS1.pdf"
data_pdf <- file.path(cache, "archive_extract", "2021_COD_GOM_DATA_SUPPLEMENT.pdf")
model_pdf <- file.path(cache, "archive_extract", "2021_COD_GOM_M02MODEL_SUPPLEMENT.pdf")
report_pdf <- file.path(cache, "archive_extract", "2021_COD_GOM_ASSESSMENT_v3.pdf")

manifest <- read.csv(file.path(cache, "manifest.csv"), stringsAsFactors = FALSE)
if (!file.exists(archive) || !any(manifest$file == basename(archive) &
  manifest$sha256 == "A086D2D348E3A993A2645439910DB775B63F35CEDAC28DABF423567D8C96AE96")) {
  cli::cli_abort("Cache the verified NOAA 2021 Gulf of Maine cod archive before importing.")
}
if (!file.exists(data_pdf) || !file.exists(model_pdf) || !file.exists(report_pdf)) {
  dir.create(dirname(data_pdf), recursive = TRUE, showWarnings = FALSE)
  utils::unzip(archive, exdir = dirname(data_pdf))
}

data_text <- pdftools::pdf_text(data_pdf)
model_text <- pdftools::pdf_text(model_pdf)
report_text <- pdftools::pdf_text(report_pdf)
stopifnot(length(model_text) >= 1L, length(report_text) >= 2L)
stopifnot(grepl("Maturity-at-age (1982-2019 time series average)", model_text[1], fixed = TRUE))

parse_age_table <- function(pages, requested_years) {
  lines <- unlist(lapply(data_text[pages], function(page) strsplit(page, "\n")[[1L]]))
  lines <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines)]
  parsed <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    year <- suppressWarnings(as.integer(tokens[[1L]]))
    values <- suppressWarnings(as.numeric(tokens[-1L]))
    if (length(values) != 10L) return(NULL)
    data.frame(year = year, age = 0:9, value = values, stringsAsFactors = FALSE)
  })
  parsed <- Filter(Negate(is.null), parsed)
  out <- do.call(rbind, parsed)
  out[out$year %in% requested_years, , drop = FALSE]
}

years <- 1982:2019
ages <- 1:9
catch <- parse_age_table(126:127, years)
catch <- catch[catch$age %in% ages, , drop = FALSE]
survey_spring <- parse_age_table(25:26, years)
survey_fall <- parse_age_table(27:28, years)
survey_spring <- survey_spring[survey_spring$age %in% ages, , drop = FALSE]
survey_fall <- survey_fall[survey_fall$age %in% ages, , drop = FALSE]
catch_weight <- parse_age_table(128:129, years)
stock_weight <- parse_age_table(130:131, years)
catch_weight <- catch_weight[catch_weight$age %in% ages, , drop = FALSE]
stock_weight <- stock_weight[stock_weight$age %in% ages, , drop = FALSE]

validate_grid <- function(x, label) {
  expected <- length(years) * length(ages)
  keys <- paste(x$year, x$age)
  if (nrow(x) != expected || anyDuplicated(keys) || any(!is.finite(x$value))) {
    cli::cli_abort("{label} did not produce a complete 1982-2019 by age 1-9+ table.")
  }
  invisible(x)
}
for (item in list(
  catch = catch, spring = survey_spring, fall = survey_fall,
  catch_weight = catch_weight, stock_weight = stock_weight
)) validate_grid(item, names(item))

source_prefix <- paste0(assessment_url, "; NOAA 2021_COD_GM.zip")
source_rows <- function(x, type, measure, basis, unit, reference, notes,
                        survey = "", fleet = "", sex = "combined",
                        source_type = "official_table", transformation = "") {
  out <- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = "Gulf of Maine legacy unit",
    season = "annual", year = x$year,
    year_basis = ifelse(is.na(x$year), "", "calendar_year"), age = x$age,
    value = x$value, unit = unit, sampling_time = "",
    source_type = source_type, source_reference = reference,
    transformation = transformation, notes = notes,
    observation_id = "", length_bin = "", length_bin_lower = "",
    length_bin_upper = "", sample_size = "", age_error = "", partition = "",
    stringsAsFactors = FALSE
  )
  out
}

inputs <- rbind(
  source_rows(catch, "catch", "numbers_at_age", "numbers", "fish",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Table 8.1"),
    "Official total catch-at-age after the assessment's gear-specific commercial discard mortality and 15% recreational release mortality. Age 0 is excluded because the M=0.2 model uses ages 1-9+."),
  source_rows(survey_spring, "index", "numbers_at_age", "numbers", "thousand fish",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Table 2.6"),
    "NEFSC spring swept-area-expanded abundance-at-age. Values are reported in thousands and retain the source's Albatross-equivalent calibration.",
    survey = "NEFSC spring", source_type = "official_table"),
  source_rows(survey_fall, "index", "numbers_at_age", "numbers", "thousand fish",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Table 2.7"),
    "NEFSC fall swept-area-expanded abundance-at-age. Values are reported in thousands and retain the source's Albatross-equivalent calibration.",
    survey = "NEFSC fall", source_type = "official_table"),
  source_rows(catch_weight, "catch_weight", "catch_weight_at_age", "biomass", "kg",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Table 8.2"),
    "Reported mean weights-at-age of total catch."),
  source_rows(stock_weight, "weight", "weight_at_age", "biomass", "kg",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Table 8.3"),
    "Reported mean January 1/spawning-stock weights-at-age, derived by the assessment using the Rivard method."),
  source_rows(data.frame(year = NA_integer_, age = ages, value = rep(0.2, length(ages))),
    "M", "natural_mortality_at_age", "per_year", "year^-1",
    paste(source_prefix, "2021_COD_GOM_M02MODEL_SUPPLEMENT.pdf, p. 1"),
    "Fixed natural mortality in the selected M=0.2 model; it is not an estimated M series.",
    sex = "combined", source_type = "official_document"),
  source_rows(data.frame(year = NA_integer_, age = ages,
    value = c(0.09, 0.30, 0.70, 0.92, 0.99, 1, 1, 1, 1)),
    "maturity", "maturity_at_age", "proportion", "proportion",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Fig. 1.9"),
    "Female age ogive digitized from the 2021 figure and rounded to two decimals; the source model uses the 1982-2019 time-series-average maturity-at-age. Numeric model inputs are not published, so these reconstructed values are approximate, not exact model inputs.",
    sex = "female", source_type = "reconstructed_source_input",
    transformation = "Digitized the female age-based maturity ogive in Fig. 1.9 at integer ages and rounded to two decimals; retained ages 1-9+ used by the model.")
)

summary_page <- report_text[2]
summary_lines <- strsplit(summary_page, "\n")[[1L]]
read_row <- function(pattern, expected_n) {
  lines <- trimws(summary_lines)
  lines <- lines[startsWith(tolower(lines), tolower(pattern))]
  if (!length(lines)) cli::cli_abort("Could not identify the report row for {pattern}.")
  line <- lines[[1L]]
  values <- suppressWarnings(as.numeric(regmatches(line, gregexpr("[0-9]+(?:\\.[0-9]+)?", line, perl = TRUE))[[1L]]))
  values <- tail(values, expected_n)
  if (length(values) != expected_n || any(!is.finite(values))) {
    cli::cli_abort("Could not parse {pattern} from the report's Table 1.")
  }
  values
}
reported_years <- 2012:2019
ssb <- read_row("Spawning Stock Biomass", 8L)
f_full <- read_row("FF ull", 8L)
recruitment <- read_row("Recruits age1", 8L)
stopifnot(tail(ssb, 1L) == 3083, tail(f_full, 1L) == 0.16,
  tail(recruitment, 1L) == 1298)

blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0,
    check.names = FALSE, stringsAsFactors = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
output_rows <- function(measure, type, value, unit, age = NA_integer_, age_group = "", note = "") {
  out <- blank("outputs.csv", length(value))
  out$type <- type; out$measure <- measure; out$year <- reported_years
  out$age <- age; out$age_group <- age_group; out$value <- value; out$unit <- unit
  out$sex <- "combined"; out$region <- "Gulf of Maine legacy unit"; out$season <- "annual"
  out$source_type <- "official_table"
  out$source_reference <- paste(source_prefix, "2021_COD_GOM_ASSESSMENT_v3.pdf, Table 1")
  out$notes <- note
  out
}
outputs <- rbind(
  output_rows("SSB", "biomass", ssb, "tonnes",
    note = "M=0.2 model results as printed; Table 1 explicitly states terminal-year SSB is not retro-adjusted. The separate retro-adjusted terminal 2019 value is 1,969 tonnes and is not substituted here."),
  output_rows("recruitment", "recruitment", recruitment, "thousand fish", age = 1L,
    note = "Native age-1 recruitment, reported in thousands."),
  output_rows("fishing_mortality_at_age", "mortality", f_full, "year^-1",
    age_group = "Fully selected",
    note = "Native fully selected fishing mortality. The numeric fully selected age range is not specified in Table 1, so no single-age F values are inferred.")
)

assumption <- function(component, setting, value, source_reference = paste(source_prefix,
    "2021_COD_GOM_M02MODEL_SUPPLEMENT.pdf, p. 1"), notes = "") {
  out <- blank("assumptions.csv")
  out$component <- component; out$setting <- setting; out$value <- value
  out$source_reference <- source_reference; out$notes <- notes
  out
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "selected_model", "M=0.2 model (M02)",
    paste(source_prefix, "2021_COD_GOM_M02MODEL_SUPPLEMENT.pdf, p. 1"),
    "The 2021 assessment also accepted an M-ramp scenario; this database record represents only the fixed-M M02 variant."),
  assumption("assessment", "assessment_status", "Official 2021 management-track update; peer review concluded technically sufficient for status and advice",
    "https://repository.library.noaa.gov/view/noaa/39403/noaa_39403_DS1.pdf",
    "The report's draft watermark is retained as provenance; the peer-review report confirms technical sufficiency."),
  assumption("population", "model_years", "1982-2019"),
  assumption("population", "ages", "1-9+; recruitment at age 1"),
  assumption("population", "stock_boundary", "Legacy combined Gulf of Maine management unit",
    "https://www.nefmc.org/library/2023-atlantic-cod-research-track-assessment",
    "The 2023 research track superseded this management unit with four cod stocks; no values are transferred to those successor units."),
  assumption("catch", "fleet_structure", "One modeled fishery combining commercial and recreational catch"),
  assumption("catch", "discard_mortality", "Commercial discard mortality varies by gear; recreational release mortality is 15%"),
  assumption("catch", "observation_cv", "0.05"),
  assumption("F", "selectivity_blocks", "1982-1988; 1989-2004; 2005-2019"),
  assumption("M", "natural_mortality", "Fixed at 0.2 per year for ages 1-9+"),
  assumption("index", "source_surveys", "NEFSC spring and fall (ages 1-9+); MADMF spring (ages 1-6)"),
  assumption("index", "recovered_survey_coverage", "NEFSC spring and fall only",
    paste(source_prefix, "2021_COD_GOM_M02MODEL_SUPPLEMENT.pdf, p. 1"),
    "MADMF spring is omitted because its age-specific numerical series is not in the recovered archive."),
  assumption("index", "survey_cv_reweighting", "NEFSC spring +0.2; NEFSC fall +0.1; MADMF spring +0.3"),
  assumption("index", "catchability", "Time-constant by survey"),
  assumption("biology", "maturity", "Female age-based maturity; 1982-2019 time-series average"),
  assumption("biology", "maturity_numeric_values", "Digitized approximation from Fig. 1.9",
    paste(source_prefix, "2021_COD_GOM_DATA_SUPPLEMENT.pdf, Fig. 1.9"),
    "The exact numeric ogive supplied to the M02 model was not published; the reconstructed values remain approximate."),
  assumption("recruitment", "model", "Age-1 recruitment deviations from a mean"),
  assumption("outputs", "available_states", "No numeric fitted N-at-age or F-at-age table recovered",
    paste(source_prefix, "2021_COD_GOM_ASSESSMENT_v3.pdf, Table 1"),
    "The report gives SSB, age-1 recruitment and fully selected F for 2012-2019 only; other fitted states are shown in figures and are not digitized."),
  assumption("outputs", "retrospective_adjustment", "Table 1 terminal M02 SSB and F are not retro-adjusted",
    paste(source_prefix, "2021_COD_GOM_ASSESSMENT_v3.pdf, p. 1"),
    "The assessment separately reports retro-adjusted terminal 2019 M02 SSB=1,969 t and F=0.249; table values are preserved without mixing adjustment conventions.")
))

assessment <- blank("assessments.csv")
assessment$stock_id <- stock_id; assessment$assessment_year <- 2021
assessment$terminal_year <- 2019; assessment$estimate_terminal_year <- 2019
assessment$assessment_type <- "management_track"; assessment$model_family <- "ASAP"
assessment$model_version <- "2021 update; M=0.2 (M02) variant"
assessment$is_current <- "FALSE"; assessment$is_applied <- "TRUE"
assessment$framework_year <- 2013; assessment$assessment_url <- assessment_url
assessment$framework_url <- framework_url; assessment$data_url <- assessment_url
assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "Historical production run for the pre-2023 combined Gulf of Maine cod unit.",
  "The 2021 M02 variant is the latest detailed accepted assessment recovered for this legacy boundary, but is not current for the four successor stock units.",
  "Maturity values are reconstructed from an official figure; MADMF age-specific indices and numeric fitted N/F surfaces remain unavailable.",
  "See source_reviews/nefsc_gom_cod_2021.md."
)

stocks <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
stock_rows <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
stopifnot(nrow(stock_rows) == 1L,
  stock_rows$charbonneau_id == "NEFSC-SAW_morhua_GOM",
  stock_rows$scientific_name == "Gadus morhua")
stock_rows$authority_stock_id <- "Legacy Gulf of Maine cod management unit"
stock_rows$common_name <- "Gulf of Maine Atlantic cod (historical management unit)"
stock_rows$area <- "Gulf of Maine (pre-2023 management unit)"
stock_rows$region <- "New England"
stock_rows$notes <- paste(
  "Historical Charbonneau-Keith stock identity; assessed as the combined Gulf of Maine cod unit through 2019.",
  "The 2023 research track replaced this management unit with EGOM, WGOM, Georges Bank, and Southern New England stocks.",
  "The 2021 assessment is not assigned to any successor stock. See source_reviews/nefsc_gom_cod_2021.md."
)

write_rows <- function(file, x, id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  at <- which(startsWith(lines, paste0("\"", id, "\",")))
  tmp <- tempfile(tmpdir = database)
  on.exit(unlink(tmp), add = TRUE)
  expected <- names(read.csv(path, nrows = 0, check.names = FALSE))
  if (!identical(names(x), expected)) cli::cli_abort("Schema mismatch while writing {file}.")
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  crlf <- grepl("\r\n", contents, fixed = TRUE)
  if (crlf) replacement <- paste0(replacement, "\r")
  if (length(at)) {
    if (!identical(at, seq.int(min(at), max(at)))) cli::cli_abort("Non-contiguous rows for {id} in {file}.")
    lines <- c(head(lines, min(at) - 1L), replacement, tail(lines, length(lines) - max(at)))
  } else {
    lines <- c(lines, replacement)
  }
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"),
    if (endsWith(contents, "\n")) "\n" else ""))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}

write_rows("stocks.csv", stock_rows, stock_id)
write_rows("assessments.csv", assessment, assessment_id)
write_rows("assumptions.csv", assumptions, assessment_id)
write_rows("inputs.csv", inputs, assessment_id)
write_rows("outputs.csv", outputs, assessment_id)
cat("Imported", assessment_id, "with", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions and", nrow(outputs), "reported outputs.\n")

