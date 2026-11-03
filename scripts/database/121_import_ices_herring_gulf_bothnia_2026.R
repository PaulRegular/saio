assessment_id <- "ices_herring_gulf_bothnia_2026"
stock_id <- "ices_herring_gulf_bothnia"
database_dir <- file.path("database")
source_dir <- file.path("source_cache",
  "ices_herring_gulf_bothnia_2026"
)
report_file <- file.path(source_dir, "WGBFAS_2026_report.pdf")
report_text_file <- file.path(source_dir, "WGBFAS_2026_report.txt")
sag_file <- file.path(source_dir, "ICES_SAG_2026_key_22377.xml")
acoustic_file <- file.path(source_dir, "acoustic_index_transcription.csv")
report_url <- "https://literatur.thuenen.de/digbib_extern/dn071152.pdf"
benchmark_url <- "https://pub.epsilon.slu.se/22760/1/cardinale_m_et_al_210311.pdf"
benchmark_cache_url <- "https://ndownloader.figshare.com/files/33482687"
benchmark_doi <- "https://doi.org/10.17895/ices.pub.5989"
benchmark_file <- file.path(source_dir, "WKCLuB_2021.pdf")
sag_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22377"
sag_source_url <- "https://sg.ices.dk/ViewSourceData.aspx?key=22377"
framework_year <- 2021L
years <- 1963:2025
composition_years <- 1980:2025
ages <- 1:15

if (!requireNamespace("digest", quietly = TRUE)) {
  cli::cli_abort("Install digest before importing this ICES assessment.")
}
if (!all(file.exists(c(report_file, report_text_file, sag_file, acoustic_file, benchmark_file)))) {
  cli::cli_abort("Cache the WGBFAS and WKCLuB reports, ICES SAG XML, and acoustic-table transcription before importing.")
}
stopifnot(digest::digest(file = benchmark_file, algo = "sha256") ==
  "c82d342198a182c4b93980a85e2805b1572ec1b8f334fa26bff583144f583ceb")

read_table <- function(name, nrows = Inf) {
  utils::read.csv(
    file.path(database_dir, name), nrows = nrows,
    colClasses = "character", na.strings = "", check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

format_value <- function(x) {
  out <- rep("", length(x))
  ok <- is.finite(x)
  out[ok] <- format(x[ok], digits = 15, scientific = FALSE, trim = TRUE)
  out
}

numeric_cells <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  x <- gsub("\\*+$", "", x)
  x[x %in% c("-", "/", "NA", "N/A")] <- NA_character_
  suppressWarnings(as.numeric(x))
}

report_lines <- readLines(report_text_file, warn = FALSE, encoding = "UTF-8")
table_start <- function(pattern) {
  i <- grep(pattern, report_lines, perl = TRUE)
  if (length(i) != 1L) cli::cli_abort("Could not uniquely locate {pattern} in the WGBFAS report text.")
  i
}
table_block <- function(start_pattern, end_pattern) {
  first <- table_start(start_pattern)
  following <- grep(end_pattern, report_lines, perl = TRUE)
  following <- following[following > first]
  last <- if (length(following)) following[[1L]] - 1L else length(report_lines)
  report_lines[seq.int(first, last)]
}
split_cells <- function(line) {
  strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
}

parse_age_table <- function(start_pattern, end_pattern, expected_years, expected_ages) {
  rows <- list()
  for (line in table_block(start_pattern, end_pattern)) {
    cells <- split_cells(line)
    if (!length(cells) || !grepl("^(19|20)[0-9]{2}$", cells[[1L]])) next
    year <- as.integer(cells[[1L]])
    values <- numeric_cells(cells[-1L])
    if (year %in% expected_years && length(values) == length(expected_ages) &&
      all(is.finite(values))) {
      rows[[length(rows) + 1L]] <- data.frame(
        year = year, age = expected_ages, value = values
      )
    }
  }
  if (!length(rows)) cli::cli_abort("No data rows parsed for {start_pattern}.")
  out <- do.call(rbind, rows)
  expected <- expand.grid(year = expected_years, age = expected_ages)
  if (anyDuplicated(paste(out$year, out$age)) ||
    !setequal(paste(out$year, out$age), paste(expected$year, expected$age))) {
    cli::cli_abort("{start_pattern} does not contain the complete expected year-age grid.")
  }
  out <- out[order(out$year, out$age), , drop = FALSE]
  rownames(out) <- NULL
  out
}

catch_numbers <- parse_age_table(
  "^Table 4\\.3\\.3\\.", "^Table 4\\.3\\.4\\.",
  composition_years, 1:15
)
catch_weights <- parse_age_table(
  "^Table 4\\.3\\.4\\.", "^Table 4\\.3\\.5", years, 0:17
)
maturity <- parse_age_table(
  "^Table 4\\.3\\.5", "^Table 4\\.3\\.6", composition_years, 1:17
)
acoustic_wide <- utils::read.csv(acoustic_file, check.names = FALSE)
if (!identical(acoustic_wide$year, 2007:2025) ||
  !all(c("area_corr_factor", paste0("age", 0:14), "age15_plus") %in% names(acoustic_wide))) {
  cli::cli_abort("The acoustic transcription must cover 2007-2025 and ages 0-15+.")
}
acoustic_values <- cbind(
  as.matrix(acoustic_wide[paste0("age", 0:14)]),
  age15_plus = acoustic_wide$age15_plus
)
acoustic <- data.frame(
  year = rep(acoustic_wide$year, each = 16L),
  age = rep(0:15, times = nrow(acoustic_wide)),
  value = as.numeric(t(acoustic_values))
)
if (any(!is.finite(acoustic$value)) || any(acoustic$value < 0)) {
  cli::cli_abort("Acoustic index values must be finite and non-negative.")
}

parse_sag <- function() {
  xml <- paste(readLines(sag_file, warn = FALSE, encoding = "UTF-8"), collapse = "")
  blocks <- regmatches(xml, gregexpr("<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
  if (!length(blocks)) cli::cli_abort("No annual assessment records found in the ICES SAG XML.")
  get_value <- function(block, tag) {
    match <- regexec(paste0("<", tag, ">(.*?)</", tag, ">"), block, perl = TRUE)
    value <- regmatches(block, match)[[1L]]
    if (length(value) < 2L || !nzchar(value[[2L]])) return(NA_real_)
    suppressWarnings(as.numeric(value[[2L]]))
  }
  fields <- c(
    "Year", "Recruitment", "Low_Recruitment", "High_Recruitment",
    "StockSize", "Low_StockSize", "High_StockSize", "Catches",
    "FishingPressure", "Low_FishingPressure", "High_FishingPressure"
  )
  rows <- lapply(blocks, function(block) {
    values <- vapply(fields, function(field) get_value(block, field), numeric(1))
    as.data.frame(as.list(values), check.names = FALSE)
  })
  out <- do.call(rbind, rows)
  names(out) <- tolower(fields)
  out <- out[out$year %in% years, , drop = FALSE]
  if (!identical(as.integer(out$year), years) ||
    any(!is.finite(as.matrix(out[, setdiff(names(out), "year")]))) ||
    anyDuplicated(out$year)) {
    cli::cli_abort("SAG XML must have complete finite 1963-2025 historical values.")
  }
  out
}
sag <- parse_sag()

break_age <- c(0.5, 1.5, 3.5, 5.5, 8.5, 15.5)
break_M <- c(0.563, 0.472, 0.332, 0.290, 0.267, 0.257)
M <- data.frame(
  age = 0:20,
  value = stats::approx(break_age, break_M, xout = (0:20) + 0.5, rule = 2)$y
)

write_source_table <- function(x, name) {
  utils::write.csv(x, file.path(source_dir, name), row.names = FALSE, na = "")
}
write_source_table(catch_numbers, "catch_at_age_table.csv")
write_source_table(catch_weights, "catch_weight_table.csv")
write_source_table(maturity, "maturity_table.csv")
trapnet_index <- data.frame(
  year = 1990:2006,
  value = c(
    0.24, 0.29, 0.42, 0.32, 0.39, 0.28, 0.30, 0.24, 0.21,
    0.18, 0.21, 0.27, 0.26, 0.22, 0.25, 0.41, 0.29
  )
)
write_source_table(trapnet_index, "trapnet_index_digitization.csv")

stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  cli::cli_abort("The Gulf of Bothnia herring stock or assessment is already present; review before rerunning this importer.")
}

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "ICES",
  authority_stock_id = "her.27.3031", scientific_name = "Clupea harengus",
  common_name = "Gulf of Bothnia herring",
  area = "ICES subdivisions 30 and 31", region = "Gulf of Bothnia",
  ocean = "Northeast Atlantic",
  notes = paste(
    "Current combined ICES stock her.27.3031; historical Charbonneau-Keith metadata rows for subdivisions 30 and 31 are not repurposed as this combined assessment."
  ), stringsAsFactors = FALSE
)

input_header <- names(read_table("inputs.csv", nrows = 0L))
input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sex = "", region = "",
                       season = "", sampling_time = NA_real_,
                       source_type = "official_table", source_reference,
                       transformation = "", notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(input_header)), stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$sex <- rep_len(sex, n)
  out$region <- rep_len(region, n)
  out$season <- rep_len(season, n)
  out$year <- ifelse(is.na(year), "", as.character(rep_len(year, n)))
  out$year_basis <- ifelse(is.na(year), "", "calendar_year")
  out$age <- ifelse(is.na(age), "", as.character(rep_len(age, n)))
  out$value <- format_value(rep_len(value, n))
  out$unit <- unit
  out$sampling_time <- format_value(rep_len(sampling_time, n))
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out
}

catch_numbers$proportion <- ave(catch_numbers$value, catch_numbers$year, FUN = function(x) x / sum(x))
input_data <- list(
  input_rows(
    "catch", "total_biomass", "biomass", sag$year, NA_integer_, sag$catches,
    "tonnes", fleet = "Commercial catch", region = "Subdivisions 30 and 31",
    source_type = "official_machine_readable", source_reference = sag_source_url,
    transformation = "None; ICES SAG annual total catches in tonnes, 1963-2025.",
    notes = "Total catch biomass used with age-composition proportions in the SS3 assessment."
  ),
  input_rows(
    "catch", "numbers_at_age", "numbers", catch_numbers$year, catch_numbers$age,
    catch_numbers$value, "thousand fish", fleet = "Commercial catch",
    region = "Subdivisions 30 and 31", source_reference = paste(report_url, "Table 4.3.3"),
    transformation = "Transcribed without rescaling from the official catch-at-age table.",
    notes = "Published age-specific catch numbers; these raw quantities are retained as provenance for the proportions used by SS3 and are not a separate tinyAM likelihood when total catch and proportions are selected. Age 15 represents 15+."
  ),
  input_rows(
    "catch", "proportion_at_age", "proportion_numbers", catch_numbers$year,
    catch_numbers$age, catch_numbers$proportion, "proportion",
    fleet = "Commercial catch", region = "Subdivisions 30 and 31",
    source_type = "reconstructed_source_input",
    source_reference = paste(report_url, "Table 4.3.3"),
    transformation = "Within each year, divide each published catch number-at-age by the sum across ages 1-15+; no sample size or extra scaling is inferred.",
    notes = "SS3 uses catch data from 1963 and age-composition data from 1980. The report does not provide effective sample sizes or age-composition likelihood weights. Age 15 is the 15+ group."
  ),
  input_rows(
    "catch_weight", "weight_at_age", "kg_per_fish", catch_weights$year,
    catch_weights$age, catch_weights$value, "kg per fish",
    fleet = "Commercial catch", region = "Subdivisions 30 and 31",
    source_reference = paste(report_url, "Table 4.3.4"),
    transformation = "Transcribed as reported; age 17 represents 17+.",
    notes = "The report identifies these as weights in catches. The stock-weight surface used in the tinyAM translation is approximated from this series because a distinct fitted stock-weight surface was not recovered."
  ),
  input_rows(
    "maturity", "maturity_at_age", "proportion", maturity$year,
    maturity$age, maturity$value, "proportion mature",
    region = "Subdivisions 30 and 31", source_reference = paste(report_url, "Table 4.3.5"),
    transformation = "Transcribed as reported; age 17 represents 17+.",
    notes = "Maturity ogives for 1980-2025; values for 1980-1982 are constant as stated in the report."
  ),
  input_rows(
    "M", "natural_mortality_at_age", "per_year", NA_integer_, M$age,
    M$value, "per year", region = "Subdivisions 30 and 31",
    source_type = "reconstructed_source_input", source_reference = benchmark_url,
    transformation = "Linearly interpolate the benchmark M values at ages 0.5, 1.5, 3.5, 5.5, 8.5, and 15.5 to age midpoints 0.5-20.5; extend the terminal value above age 15.5.",
    notes = "Time-invariant age-specific M from the 2021 SS3 benchmark. Age 20 is the terminal modeled age. This is a benchmark assumption, not an estimated 2026 M surface."
  ),
  input_rows(
    "index", "numbers_at_age", "numbers", acoustic$year, acoustic$age,
    acoustic$value, "million fish", survey = "BIAS acoustic survey",
    region = "Subdivisions 30 acoustic survey area", season = "autumn",
    source_reference = paste(report_url, "Table 4.3.6"),
    transformation = "Visually transcribed from the area-corrected abundance table; values are stored as published and are not multiplied by AREA_CORR_FACTOR again.",
    notes = "Acoustic abundance index in millions of fish, 2007-2025, ages 0-15+. The survey covers most of subdivision 30 but does not survey subdivision 31; coverage was reduced in 2021-2025."
  ),
  input_rows(
    "index", "relative_abundance_index", "index_scale",
    trapnet_index$year, NA_integer_, trapnet_index$value,
    "relative index units", survey = "Commercial trapnet CPUE",
    region = "Bothnian Sea", source_type = "digitized",
    source_reference = paste(benchmark_doi, "Figure 6, printed p. 14"),
    transformation = paste(
      "Digitized the annual observed trapnet-index points from Figure 6 and",
      "rounded to the nearest 0.01 index units."
    ),
    notes = paste(
      "Aggregate index for ages 3-9. The 2026 report confirms a trapnet CPUE",
      "series for 1990-2006 but does not publish its numeric values in a table.",
      "This approximate digitization is from the 2021 benchmark and is not",
      "verified against the final 2026 production input array; digitization",
      "error and likelihood weights are unavailable."
    )
  )
)
inputs <- do.call(rbind, input_data)

assumption_header <- names(read_table("assumptions.csv", nrows = 0L))
assumption_values <- data.frame(
  component = c(
    "assessment", "population", "population", "recruitment", "F", "F",
    "catch", "catch", "catch", "M", "index", "index", "index", "index",
    "index", "biology", "biology", "outputs", "outputs"
  ),
  setting = c(
    "assessment_run", "model_start", "initial_population", "recruitment_age",
    "method", "Fbar_ages", "catch_years", "composition_years",
    "composition_likelihood", "natural_mortality", "survey_id",
    "survey_years", "survey_ages", "survey_timing", "area_correction",
    "weight_source", "maturity_source", "confidence_interval", "available_outputs"
  ),
  value = c(
    "Official 2026 ICES Stock Synthesis assessment",
    "Catch data start in 1963; age-composition data start in 1980",
    "Initial population assumed to be in an exploited state; initial catches assumed to equal the 1963-1965 average",
    "Age 0", "Hybrid F", "3-7; unweighted arithmetic mean",
    "1963-2025", "1980-2025, ages 1-15+",
    "Unknown; source report does not give effective sample sizes or the age-composition likelihood weights",
    "Fixed age-varying vector from the 2021 benchmark, constant over time",
    "BIAS (ICES code A1588)", "2007-2025", "1-15+ in assessment",
    "Late September to early October; tinyAM uses 0.75 as an approximate within-year time",
    "Table 4.3.6 values are already area-corrected; do not apply AREA_CORR_FACTOR again",
    "Annual catch weights are available; a distinct stock-weight surface was not recovered",
    "Annual maturity ogives from 1980; source observations are sampled before spawning",
    "90% central intervals in ICES SAG; lower and upper endpoints retained as reported",
    "Annual recruitment, SSB, and Fbar; age-specific population and mortality surfaces are not available in the published outputs"
  ),
  source_reference = c(
    report_url, paste(report_url, "Section 4.3.4.1"), paste(report_url, "Section 4.3.4.1"),
    sag_source_url, paste(report_url, "Section 4.3.4.1"), sag_source_url,
    sag_source_url, paste(report_url, "Section 4.3.4.1"), report_url,
    benchmark_url, paste(report_url, "Section 4.3.3.3"),
    paste(report_url, "Table 4.3.6"), paste(report_url, "Section 4.3.4.1"),
    paste(report_url, "Section 4.3.3.3"), paste(report_url, "Table 4.3.6"),
    paste(report_url, "Table 4.3.4"), paste(report_url, "Table 4.3.5"),
    sag_file, sag_url
  ),
  notes = c(
    "Assessment key 22377; stock code her.27.3031; assessment year 2026; terminal fitted year 2025.",
    "The tinyAM fit is limited to 1980-2025 because age compositions are not reported before 1980.",
    "The age-specific initial population configuration is not fully available in the public report.",
    "Recruitment age is shown as 0 in the ICES SAG source metadata.",
    "The report identifies hybrid F and SS3 version 3.30.22.1.",
    "TinyAM Fbar is population-weighted and is not directly equivalent to the unweighted source Fbar.",
    "SAG catches are in tonnes and are retained separately from catch composition.",
    "Age-specific raw values are retained in inputs; proportions are reconstructed for the SS3 composition structure.",
    "The numerical catch-composition sample sizes and weighting are unresolved.",
    "Values are linearly interpolated at age midpoints from the benchmark's six breakpoints.",
    "The survey is the joint Finnish-Swedish hydroacoustic survey coordinated within BIAS.",
    "Years 2021-2025 have reduced spatial coverage compared with 2016-2020.",
    "The canonical table also retains the age-0 index; tinyAM uses ages 1-15+.",
    "The source gives a survey season but no exact model fraction; 0.75 is a translation midpoint assumption.",
    "Annual area correction factors are preserved in the ignored local transcription cache and not applied twice.",
    "TinyAM uses catch weights as the closest available proxy; this differs from a directly verified source stock-weight definition.",
    "The report says 1980-1982 maturity values are constant; reported values are retained without further smoothing.",
    "The source XML gives ConfidenceIntervalDefinition = 90%; no SE is reported.",
    "The assessment summary contains no fitted N-at-age, F-at-age, or estimated M-at-age time series."
  ), stringsAsFactors = FALSE
)
assumption_values <- rbind(
  assumption_values,
  data.frame(
    component = "index", setting = "trapnet_index",
    value = paste(
      "1990-2006; aggregate index for ages 3-9; approximate digitization",
      "from 2021 benchmark Figure 6; exact 2026 production series unresolved"
    ),
    source_reference = paste(benchmark_doi, "Figure 6, printed p. 14"),
    notes = paste(
      "Annual points rounded to 0.01 index units. The report confirms the",
      "years and age range but does not publish the exact production values;",
      "no digitization error or likelihood weights were inferred."
    ),
    stringsAsFactors = FALSE
  )
)
assumptions <- as.data.frame(matrix("", nrow = nrow(assumption_values), ncol = length(assumption_header)), stringsAsFactors = FALSE)
names(assumptions) <- assumption_header
assumptions$assessment_id <- assessment_id
assumptions$component <- assumption_values$component
assumptions$setting <- assumption_values$setting
assumptions$value <- assumption_values$value
assumptions$source_reference <- assumption_values$source_reference
assumptions$notes <- assumption_values$notes

output_header <- names(read_table("outputs.csv", nrows = 0L))
output_rows <- function(type, measure, year, age, age_group, value, unit,
                        lwr = NA_real_, upr = NA_real_,
                        source_type = "official_machine_readable",
                        source_reference = sag_source_url, notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_header)), stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(rep_len(year, n))
  out$age <- ifelse(is.na(age), "", as.character(rep_len(age, n)))
  if ("age_group" %in% names(out)) out$age_group <- rep_len(age_group, n)
  out$value <- format_value(rep_len(value, n))
  out$lwr <- format_value(rep_len(lwr, n))
  out$upr <- format_value(rep_len(upr, n))
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- notes
  out
}
outputs <- rbind(
  output_rows(
    "recruitment", "recruitment", sag$year, 0L, "",
    sag$recruitment, "thousand fish", sag$low_recruitment, sag$high_recruitment,
    notes = "Native age-0 recruitment estimates; lower and upper endpoints are the ICES SAG 90% central interval."
  ),
  output_rows(
    "biomass", "SSB", sag$year, NA_integer_, "",
    sag$stocksize, "tonnes", sag$low_stocksize, sag$high_stocksize,
    notes = "Native spawning stock biomass; lower and upper endpoints are the ICES SAG 90% central interval."
  ),
  output_rows(
    "mortality", "Fbar", sag$year, NA_integer_, "3-7",
    sag$fishingpressure, "per year", sag$low_fishingpressure, sag$high_fishingpressure,
    notes = "Source Fbar is the unweighted arithmetic mean over ages 3-7; lower and upper endpoints are the ICES SAG 90% central interval."
  )
)

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2026", terminal_year = "2025", estimate_terminal_year = "2025",
  assessment_type = "annual_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.22.1", is_current = "TRUE", is_applied = "TRUE",
  framework_year = as.character(framework_year), assessment_url = report_url,
  framework_url = benchmark_url, data_url = sag_source_url,
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Official 2026 ICES assessment for combined subdivisions 30 and 31; fitted catch data end in 2025.",
    "The 2026 forecast row is excluded from historical inputs and outputs.",
    "Catch biomass and age compositions, annual catch weights and maturity, benchmark-fixed M, and the acoustic index are recorded with source transformations.",
    "A 1990-2006 aggregate trapnet index for ages 3-9 is approximately digitized from the 2021 benchmark Figure 6; its exact identity with the 2026 production input array, digitization error, and likelihood weights are unresolved. Composition likelihood weights, the source fitted model object, and age-specific N/F/M outputs were not recovered.",
    "See source_reviews/ices_herring_gulf_bothnia_2026.md."
  ), stringsAsFactors = FALSE
)

manifest <- data.frame(
  assessment_id = character(), cached_file = character(), original_filename = character(),
  source_url = character(), retrieval_date = character(), verified_date = character(),
  sha256 = character(), note = character(), stringsAsFactors = FALSE
)
today <- as.character(Sys.Date())
url_for <- c(
  "WGBFAS_2026_report.pdf" = report_url,
  "WGBFAS_2026_report.txt" = report_url,
  "ICES_SAG_2026_key_22377.xml" = sag_url,
  "acoustic_index_transcription.csv" = report_url,
  "catch_at_age_table.csv" = report_url,
  "catch_weight_table.csv" = report_url,
  "maturity_table.csv" = report_url,
  "trapnet_index_digitization.csv" = benchmark_doi,
  "page_329.png" = report_url,
  "table_left.png" = report_url,
  "table_right.png" = report_url
)
for (filename in names(url_for)) {
  path <- file.path(source_dir, filename)
  if (!file.exists(path)) next
  manifest <- rbind(manifest, data.frame(
    assessment_id = assessment_id, cached_file = filename,
    original_filename = filename, source_url = unname(url_for[[filename]]),
    retrieval_date = if (filename == "trapnet_index_digitization.csv") {
      today
    } else {
      "pre-existing; original retrieval date not recorded"
    },
    verified_date = today,
    sha256 = digest::digest(
      readBin(path, "raw", n = as.integer(file.info(path)$size)),
      algo = "sha256", serialize = FALSE
    ),
    note = if (filename == "acoustic_index_transcription.csv") {
      "Manual transcription of Table 4.3.6; area-corrected values copied as published, including AREA_CORR_FACTOR for audit."
    } else if (filename == "WGBFAS_2026_report.txt") {
      "Text extracted from the cached official PDF for local table parsing."
    } else if (filename %in% c("catch_at_age_table.csv", "catch_weight_table.csv", "maturity_table.csv")) {
      "Tidy transcription from the specified official report table; the source PDF is also cached."
    } else if (filename == "trapnet_index_digitization.csv") {
      "Approximate digitization from Figure 6 of the 2021 WKCLuB benchmark; rounded to 0.01, not independently verified against the 2026 production array."
    } else if (grepl("\\.png$", filename)) {
      "Page image or crop used to inspect the source table."
    } else {
      "Official source file cached locally."
    }, stringsAsFactors = FALSE
  ))
}
manifest <- rbind(manifest, data.frame(
  assessment_id = assessment_id, cached_file = basename(benchmark_file),
  original_filename = "WKCLuB_2020_2021_final.pdf",
  source_url = benchmark_cache_url, retrieval_date = "2026-10-26",
  verified_date = today, sha256 = digest::digest(file = benchmark_file, algo = "sha256"),
  note = "Official publisher PDF; DOI 10.17895/ices.pub.5989 resolves to Figshare article 18619238. Final settings table and working-document age coordinates give the same reconstructed M vector.",
  stringsAsFactors = FALSE
))
utils::write.csv(manifest, file.path(source_dir, "manifest.csv"), row.names = FALSE, na = "")

utils::write.table(stock_row, file.path(database_dir, "stocks.csv"), sep = ",",
  quote = TRUE, row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
for (name in c("assessments", "assumptions", "inputs", "outputs")) {
  rows <- switch(name, assessments = assessment_row, assumptions = assumptions,
    inputs = inputs, outputs = outputs)
  utils::write.table(rows, file.path(database_dir, paste0(name, ".csv")),
    sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "")
}

cat(
  "Imported", nrow(inputs), "inputs,", nrow(assumptions), "assumptions, and",
  nrow(outputs), "outputs for", assessment_id, "\n"
)
