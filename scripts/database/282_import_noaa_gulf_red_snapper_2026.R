root <- "."
stock_id <- "noaa_gulf_red_snapper"
assessment_id <- "noaa_gulf_red_snapper_2026"
candidate_id <- "NOAA:10230"
report_url <- "https://sedarweb.org/documents/sedar-98-gulf-red-snapper-final-stock-assessment-report/"
source_dir <- file.path(root, "source_cache/discovery_noaa_gom_red_snapper_2026")
manifest_path <- file.path(root, "provenance/discovery_noaa_gom_red_snapper_2026/sources.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hash <- toupper(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
    )))
  } else {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hash <- toupper(strsplit(result, "[[:space:]]+")[[1L]][1L])
  }
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}
read_assessment_rows <- function(path, id) {
  prefix <- paste0('"', id, '",')
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(NULL)
  if (status != 0L) stop("Could not read assessment rows from ", path, ".", call. = FALSE)
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(NULL)
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}
row_signature <- function(data) {
  columns <- c("assessment_id", "type", "measure", "basis", "fleet", "survey",
    "sex", "region", "season", "year", "year_basis", "age", "value", "unit",
    "sampling_time", "source_type", "source_reference", "transformation", "notes")
  values <- lapply(data[columns], function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  do.call(paste, c(values, sep = "\r"))
}
verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from the pinned provenance manifest: ", name,
      call. = FALSE)
  }
  path
}

sar_pdf <- verify_source("SEDAR98_SAR.pdf")
sar_text <- paste0(sar_pdf, ".txt")
if (!file.exists(sar_text)) {
  stop("Create the local plain-text extraction beside SEDAR98_SAR.pdf before importing.",
    call. = FALSE)
}
report_lines <- readLines(sar_text, warn = FALSE, encoding = "UTF-8")

read_population_table <- function(table_number, next_table, region) {
  start <- grep(paste0("^Table ", table_number, "\\. Expected biomass"), report_lines)
  end <- grep(paste0("^Table ", next_table, "\\."), report_lines)
  end <- end[end > start]
  if (length(start) != 1L || length(end) < 1L) {
    stop("Could not locate SEDAR 98 population table ", table_number, ".",
      call. = FALSE)
  }
  section <- report_lines[seq.int(start, end[1L] - 1L)]
  data_lines <- section[grepl(
    "^[[:space:]]*(19[0-9]{2}|20[0-9]{2})[[:space:]]+[0-9,]+", section
  )]
  values <- lapply(data_lines, function(line) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    as.numeric(gsub(",", "", tokens, fixed = TRUE))
  })
  if (length(values) != 74L || any(lengths(values) != 7L)) {
    stop("SEDAR 98 Table ", table_number,
      " did not parse as 74 rows with seven columns.", call. = FALSE)
  }
  values <- do.call(rbind, values)
  if (!identical(as.integer(values[, 1L]), 1950:2023) ||
      any(!is.finite(values))) {
    stop("SEDAR 98 Table ", table_number,
      " has unexpected years or non-finite values.", call. = FALSE)
  }
  data.frame(
    table = table_number,
    region = region,
    year = as.integer(values[, 1L]),
    total_biomass = values[, 2L],
    exploitable_biomass = values[, 3L],
    SSB = values[, 4L],
    abundance_1plus = values[, 5L],
    recruitment_age0 = values[, 6L],
    SSB_ratio = values[, 7L],
    stringsAsFactors = FALSE
  )
}

pop <- do.call(rbind, list(
  read_population_table(20L, 21L, "West"),
  read_population_table(21L, 22L, "Central"),
  read_population_table(22L, 23L, "East")
))
if (nrow(pop) != 222L || anyDuplicated(pop[c("region", "year")])) {
  stop("Expected one SEDAR 98 population row per year and assessment area.",
    call. = FALSE)
}

read_exploitation_table <- function(table_number, region, fleets) {
  start <- grep(paste0("^Table ", table_number,
    "\\. Estimates of annual exploitation rate"), report_lines)
  table_starts <- grep("^Table [0-9]+\\.", report_lines)
  end <- table_starts[table_starts > start]
  if (length(start) != 1L || !length(end)) {
    stop("Could not locate SEDAR 98 exploitation-rate Table ", table_number, ".",
      call. = FALSE)
  }
  section <- report_lines[seq.int(start, end[1L] - 1L)]
  data_lines <- section[grepl(
    "^[[:space:]]*(19[0-9]{2}|20[0-9]{2})[[:space:]]+", section
  )]
  values <- lapply(data_lines, function(line) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
  })
  if (length(values) != 74L || any(lengths(values) != length(fleets) + 1L)) {
    stop("SEDAR 98 exploitation-rate Table ", table_number,
      " did not parse as 74 rows with the expected fleet columns.", call. = FALSE)
  }
  values <- do.call(rbind, values)
  if (!identical(as.integer(values[, 1L]), 1950:2023) ||
      any(!is.finite(values)) || any(values[, -1L, drop = FALSE] < 0)) {
    stop("SEDAR 98 exploitation-rate Table ", table_number,
      " has unexpected years or invalid rates.", call. = FALSE)
  }
  regions <- rep(region, length.out = length(fleets))
  data.frame(
    table = table_number,
    region = rep(regions, each = nrow(values)),
    fleet = rep(fleets, each = nrow(values)),
    year = rep(as.integer(values[, 1L]), times = length(fleets)),
    value = as.vector(values[, -1L, drop = FALSE]),
    stringsAsFactors = FALSE
  )
}

exploitation_data <- do.call(rbind, list(
  read_exploitation_table(12L, "", "All fleets"),
  read_exploitation_table(13L, "West", c("Commercial Handline", "Commercial Longline",
    "Commercial Handline Closed Season Discards")),
  read_exploitation_table(14L, "Central", c("Commercial Handline", "Commercial Longline",
    "Commercial Handline Closed Season Discards")),
  read_exploitation_table(15L, "East", c("Commercial Handline", "Commercial Longline",
    "Commercial Handline Closed Season Discards")),
  read_exploitation_table(16L, "West", c("Recreational Charter", "Recreational Headboat",
    "Recreational Headboat Closed Season Discards", "Recreational Private",
    "Recreational Private Closed Season Discards")),
  read_exploitation_table(17L, "Central", c("Recreational Charter", "Recreational Headboat",
    "Recreational Headboat Closed Season Discards", "Recreational Private",
    "Recreational Private Closed Season Discards")),
  read_exploitation_table(18L, "East", c("Recreational Charter", "Recreational Headboat",
    "Recreational Headboat Closed Season Discards", "Recreational Private",
    "Recreational Private Closed Season Discards")),
  read_exploitation_table(19L, c("Central", "East", "West"),
    rep("Shrimp Trawl Bycatch", 3L))
))
if (nrow(exploitation_data) != 2072L ||
    anyDuplicated(exploitation_data[c("table", "region", "fleet", "year")])) {
  stop("Expected 2,072 unique SEDAR 98 exploitation-rate output rows.",
    call. = FALSE)
}

output <- function(type, measure, value, unit, year = pop$year,
                   region = pop$region, fleet = NA_character_,
                   age = NA_integer_, age_group = "",
                   source_type = "official_table", source_reference = "",
                   notes = "") {
  pacific_database_row("outputs", assessment_id = assessment_id,
    type = type, measure = measure, value = value, unit = unit,
    year = year, fleet = fleet, age = age, age_group = age_group, region = region,
    source_type = source_type, source_reference = source_reference,
    notes = notes)
}
reported_metrics <- list(
  list("biomass", "total_biomass", "total_biomass", "metric tons",
    "SEDAR98_SAR.pdf, Tables 20-22",
    "Reported expected biomass for all ages in each model area."),
  list("biomass", "exploitable_biomass", "exploitable_biomass", "metric tons",
    "SEDAR98_SAR.pdf, Tables 20-22",
    "Reported expected biomass for ages 1+ in each model area."),
  list("biomass", "SSB", "SSB", "metric tons",
    "SEDAR98_SAR.pdf, Tables 20-22",
    "Reported expected spawning stock biomass in each model area."),
  list("population", "numbers_at_age", "abundance_1plus", "thousand fish",
    "SEDAR98_SAR.pdf, Tables 20-22",
    "Reported expected exploited abundance for ages 1+; this is an aggregate, not N-at-age."),
  list("recruitment", "recruitment", "recruitment_age0", "thousand fish",
    "SEDAR98_SAR.pdf, Tables 20-22",
    "Reported expected age-0 recruitment; values are rounded to the nearest thousand fish."),
  list("biomass", "SSB_ratio", "SSB_ratio", "proportion",
    "SEDAR98_SAR.pdf, Tables 20-22",
    paste("Source-reported ratio retained verbatim. The caption gives Gulf SSB0 = 392,218.6 mt,",
      "but the area-specific table ratios do not equal area SSB divided by that value;",
      "the denominator convention remains unresolved."))
)
outputs <- lapply(reported_metrics, function(x) output(
  type = x[[1L]], measure = x[[2L]], value = pop[[x[[3L]]]], unit = x[[4L]],
  age = if (x[[2L]] == "recruitment") 0L else NA_integer_,
  age_group = if (x[[2L]] == "numbers_at_age") "1+" else "",
  source_reference = x[[5L]], notes = x[[6L]]
))
outputs[[length(outputs) + 1L]] <- output(
  type = "population", measure = "total_abundance",
  value = pop$abundance_1plus + pop$recruitment_age0, unit = "thousand fish",
  age_group = "0+", source_type = "derived_source_output",
  source_reference = "SEDAR98_SAR.pdf, Tables 20-22",
  notes = paste("Derived by adding the reported age-1+ exploited abundance and age-0 recruitment",
    "for the same area and year. Both source values are rounded to the nearest thousand fish;",
    "the derived total therefore inherits source rounding. Joint uncertainty is unavailable.")
)
outputs <- do.call(rbind, outputs)
exploitation_outputs <- do.call(rbind, lapply(seq_len(nrow(exploitation_data)), function(i) {
  d <- exploitation_data[i, ]
  table_note <- if (d$table == 12L) {
    "Combined across all fleets; the report uses this biomass exploitation rate as a proxy for annual fishing mortality. It is not instantaneous F."
  } else if (d$table == 19L) {
    "Shrimp-trawl bycatch exploitation rate, described by the report as primarily age zero. It is a biomass exploitation ratio, not instantaneous F."
  } else {
    "Area- and fleet-specific biomass exploitation rate for ages 1+; it is not instantaneous F."
  }
  output(type = "mortality", measure = "exploitation_rate", value = d$value,
    unit = "ratio", year = d$year, region = d$region, fleet = d$fleet,
    source_reference = paste0("SEDAR98_SAR.pdf, Table ", d$table),
    notes = table_note)
}))
outputs <- rbind(outputs, exploitation_outputs)
output_keys <- c("type", "measure", "fleet", "survey", "sex", "region", "season",
  "year", "age", "age_group", "scenario")
output_key <- function(data) do.call(paste, c(lapply(data[output_keys], function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}), sep = "\r"))
input_keys <- c("type", "measure", "basis", "fleet", "survey", "sex", "region",
  "season", "year", "year_basis", "age", "partition")
input_key <- function(data) do.call(paste, c(lapply(data[input_keys], function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}), sep = "\r"))
row_signature_all <- function(data, columns) {
  values <- lapply(data[columns], function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  do.call(paste, c(values, sep = "\r"))
}
if (anyDuplicated(output_key(outputs))) {
  stop("SEDAR 98 output tables contain duplicate output keys.", call. = FALSE)
}

read_index_table <- function(marker, region, series, table_number) {
  line_index <- grep(marker, report_lines, fixed = TRUE)
  if (length(line_index) != 1L) {
    stop("Could not locate one SEDAR 98 index table for ", marker, ".",
      call. = FALSE)
  }
  table_text <- strsplit(report_lines[line_index], "\\n", fixed = TRUE)[[1L]][1L]
  table_text <- strsplit(table_text, "5.9 FIGURES", fixed = TRUE)[[1L]][1L]
  year_matches <- gregexpr(
    "(?<![0-9.])(19|20)[0-9]{2}(?![0-9.])", table_text, perl = TRUE
  )[[1L]]
  years <- regmatches(table_text, list(year_matches))[[1L]]
  keep <- which(as.integer(years) >= 1982L & as.integer(years) <= 2023L)
  if (!length(keep)) stop("No assessment years found in ", marker, ".", call. = FALSE)
  year_matches <- year_matches[keep]
  years <- as.integer(years[keep])

  rows <- list()
  for (i in seq_along(years)) {
    row_start <- year_matches[i]
    row_end <- if (i < length(years)) year_matches[i + 1L] - 1L else nchar(table_text)
    row_text <- substring(table_text, row_start, row_end)
    value_matches <- gregexpr("[0-9]+[.][0-9]+", row_text, perl = TRUE)[[1L]]
    values <- regmatches(row_text, list(value_matches))[[1L]]
    if (!length(values)) next
    if (length(values) %% 2L != 0L) {
      stop("Index and CV values are not paired in ", marker, " for ", years[i], ".",
        call. = FALSE)
    }
    pair_starts <- value_matches[seq.int(1L, length(values), by = 2L)]
    first_gap <- pair_starts[1L] - 5L
    column <- 1L + round((first_gap - 1L) / 3L)
    columns <- column
    if (length(pair_starts) > 1L) {
      for (j in 2:length(pair_starts)) {
        previous_cv <- 2L * j - 2L
        gap <- pair_starts[j] -
          (value_matches[previous_cv] + nchar(values[previous_cv]))
        column <- column + round((gap - 2L) / 3L) + 1L
        columns <- c(columns, column)
      }
    }
    if (any(columns < 1L | columns > length(series))) {
      stop("Could not map index columns for ", marker, " in ", years[i], ".",
        call. = FALSE)
    }
    rows[[length(rows) + 1L]] <- data.frame(
      region = region,
      survey = series[columns],
      year = years[i],
      index = as.numeric(values[seq.int(1L, length(values), by = 2L)]),
      cv = as.numeric(values[seq.int(2L, length(values), by = 2L)]),
      table = table_number,
      stringsAsFactors = FALSE
    )
  }
  if (!length(rows)) stop("No index observations parsed from ", marker, ".", call. = FALSE)
  do.call(rbind, rows)
}

index_specs <- list(
  list("5.8.1. Relative abundance", "West", c(
    "SEAMAP Fall Plankton", "SEAMAP Groundfish Summer - Old",
    "SEAMAP Groundfish Summer - New", "SEAMAP Groundfish Fall - Old"
  ), "5.8.1"),
  list("5.8.1.(continued)", "West", c(
    "SEAMAP Groundfish Fall - New", "G-FISHER Reef Fish Video",
    "SEFSC Bottom Longline"
  ), "5.8.1"),
  list("5.8.2. Relative abundance", "Central", c(
    "SEAMAP Fall Plankton", "SEAMAP Groundfish Summer - New",
    "SEAMAP Groundfish Fall - New", "G-FISHER Reef Fish Video"
  ), "5.8.2"),
  list("5.8.2.(continued)", "Central", c("SEFSC Bottom Longline"), "5.8.2"),
  list("5.8.3. Relative abundance", "East", c(
    "SEFSC Bottom Longline", "SEAMAP Groundfish Summer - New",
    "SEAMAP Groundfish Fall - New", "G-FISHER Reef Fish Video"
  ), "5.8.3"),
  list("5.8.3.(continued)", "East", c("Observer Post-IFQ Commercial Vertical Line"), "5.8.3")
)
index_data <- do.call(rbind, lapply(index_specs, function(spec) {
  read_index_table(spec[[1L]], spec[[2L]], spec[[3L]], spec[[4L]])
}))
if (any(!is.finite(index_data$index) | index_data$index <= 0 |
    !is.finite(index_data$cv) | index_data$cv < 0) ||
    anyDuplicated(index_data[c("region", "survey", "year")])) {
  stop("SEDAR 98 Table 5.8 contains invalid or duplicate index observations.",
    call. = FALSE)
}
expected_starts <- c(
  "SEAMAP Fall Plankton" = 1986L,
  "SEAMAP Groundfish Summer - Old" = 1984L,
  "SEAMAP Groundfish Summer - New" = 2009L,
  "SEAMAP Groundfish Fall - Old" = 1988L,
  "SEAMAP Groundfish Fall - New" = 2008L,
  "G-FISHER Reef Fish Video" = 1993L,
  "SEFSC Bottom Longline" = 2001L,
  "Observer Post-IFQ Commercial Vertical Line" = 2007L
)
for (survey_name in unique(index_data$survey)) {
  observed_years <- index_data$year[index_data$survey == survey_name]
  if (min(observed_years) < expected_starts[survey_name]) {
    stop("Unexpected early year for index series ", survey_name, ".", call. = FALSE)
  }
}

index_inputs <- do.call(rbind, lapply(seq_len(nrow(index_data)), function(i) {
  d <- index_data[i, ]
  source_reference <- paste0("SEDAR98_SAR.pdf, Section II, Table ", d$table,
    "; Section I abundance-index list")
  notes <- paste(
    "Source-reported annual relative-abundance index scaled to a mean of one for its time series.",
    "The paired source CV is standard error divided by the mean.",
    "The report lists this survey series in the assessment data set; its native model input file was not located."
  )
  rbind(
    pacific_database_row("inputs", assessment_id = assessment_id,
      type = "index", measure = "relative_abundance_index", basis = "index_scale",
      survey = d$survey, region = d$region, year = d$year,
      year_basis = "calendar_year", value = d$index,
      unit = "relative index (time-series mean = 1)", source_type = "official_table",
      source_reference = source_reference, notes = notes),
    pacific_database_row("inputs", assessment_id = assessment_id,
      type = "index", measure = "abundance_index_cv", basis = "relative_scale",
      survey = d$survey, region = d$region, year = d$year,
      year_basis = "calendar_year", value = d$cv, unit = "ratio",
      source_type = "official_table", source_reference = source_reference,
      notes = "Source-reported CV; the table defines this as standard error divided by the mean.")
  )
}))

assume <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assume("assessment", "run_identity", "SEDAR 98 final Gulf red snapper assessment; terminal data year 2023.",
    "SEDAR98_SAR.pdf, cover and assessment summary"),
  assume("assessment", "certification_status", "SSC certification and application for advice were pending in the final report.",
    "SEDAR98_SAR.pdf, assessment summary",
    "The database record is current but is_applied=FALSE; this does not assert later status."),
  assume("model", "model_version", "Stock Synthesis 3.30.20",
    "SEDAR98_SAR.pdf, model description"),
  assume("population", "dimensions", "1950-2023; areas West, Central, East; age 0-20+.",
    "SEDAR98_SAR.pdf, model description and Tables 20-22",
    "The three areas are components of one Gulf management unit."),
  assume("M", "natural_mortality", "Fixed age-specific Lorenzen vector; M(age 0)=2.0 and M(age 1)=1.2 per year; older ages scaled from M=0.104 per year.",
    "SEDAR98_SAR.pdf, natural mortality description",
    "Numerical values for the full age vector have not yet been imported."),
  assume("biology", "maturity", "Fixed, time-invariant area-specific logistic age curves; Central and East use the East-area estimates.",
    "SEDAR98_SAR.pdf, maturity description",
    "Numerical coefficients or age vectors have not yet been imported."),
  assume("biology", "weight_at_age", "Weights at age are calculated from fixed externally estimated growth and length-weight relationships.",
    "SEDAR98_SAR.pdf, biology description; SEDAR 74 life-history sources",
    "The source curves and resulting age-specific weights have not yet been imported."),
  assume("observation", "population_outputs", "Tables 20-22 report area-specific expected biomass, exploitable biomass, SSB, age-1+ abundance, age-0 recruitment and SSB ratio; Tables 12-19 report Gulf-wide and area-by-fleet exploitation rates.",
    "SEDAR98_SAR.pdf, Tables 12-22",
    "No standard errors or intervals are reported. Exploitation rates are not instantaneous F.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA Fisheries", authority_stock_id = "10230",
  scientific_name = "Lutjanus campechanus",
  common_name = "Gulf of Mexico red snapper", area = "Gulf of Mexico",
  region = "United States Gulf of Mexico", ocean = "Northwest Atlantic",
  notes = paste("NOAA Stock SMART unit 10230. West, Central and East are assessment areas",
    "within one Gulf management unit, not separate stocks. No Charbonneau-Keith Master",
    "identifier is assigned; no verified match was found."))
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2026L, terminal_year = 2023L,
  estimate_terminal_year = 2023L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.20",
  is_current = TRUE, is_applied = FALSE, framework_year = NA_integer_,
  assessment_url = report_url,
  framework_url = "",
  data_url = "https://sedarweb.org/assessments/sedar-98-gulf-of-mexico-red-snapper/",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste("Latest detailed run located for NOAA:10230; final report released in October 2026.",
    "The final report states SSC review was pending, so the assessment is not marked applied for advice.",
    "Area-specific summary outputs from Tables 20-22 and exploitation rates from Tables 12-19 have been imported; age-specific N/F and numeric",
    "inputs remain incomplete. See discovery/source_reviews/noaa_gulf_red_snapper_2026.md."))

inputs <- index_inputs
if (anyDuplicated(input_key(inputs))) {
  stop("SEDAR 98 index inputs contain duplicate input keys.", call. = FALSE)
}
if (!write_mode) {
  cat("Dry run:", nrow(assumptions), "assumptions;", nrow(outputs),
    "reported/derived outputs (including", nrow(exploitation_outputs),
    "exploitation-rate rows);", nrow(inputs), "index input rows across",
    length(unique(index_data$survey)), "survey series;", length(unique(pop$region)), "areas;",
    min(pop$year), "-", max(pop$year), "\n")
} else {
  existing_assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE)$assessment_id
  if (!assessment_id %in% existing_assessments) {
    append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  } else {
    existing_inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
    if (is.null(existing_inputs)) {
      missing_inputs <- inputs
    } else {
      if (!all(input_keys %in% names(existing_inputs))) {
        stop("Existing assessment inputs do not have the expected key columns.",
          call. = FALSE)
      }
      existing_keys <- input_key(existing_inputs)
      incoming_keys <- input_key(inputs)
      if (anyDuplicated(existing_keys[existing_keys %in% incoming_keys])) {
        stop("Existing Gulf red snapper inputs contain duplicate input keys.",
          call. = FALSE)
      }
      overlap <- match(incoming_keys, existing_keys)
      columns <- names(inputs)
      if (!all(columns %in% names(existing_inputs))) {
        stop("Existing assessment inputs do not have the expected columns.",
          call. = FALSE)
      }
      existing_signature <- row_signature_all(existing_inputs, columns)
      incoming_signature <- row_signature_all(inputs, columns)
      matched <- which(!is.na(overlap))
      if (any(existing_signature[overlap[matched]] != incoming_signature[matched])) {
        stop("Existing Gulf red snapper index rows differ from the source import.",
          call. = FALSE)
      }
      missing_inputs <- inputs[is.na(overlap), , drop = FALSE]
    }
    if (nrow(missing_inputs)) {
      utils::write.table(missing_inputs, "database/inputs.csv", sep = ",",
        row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
    }
    existing_outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
    if (is.null(existing_outputs)) {
      missing_outputs <- outputs
    } else {
      if (!all(names(outputs) %in% names(existing_outputs))) {
        stop("Existing assessment outputs do not have the expected columns.",
          call. = FALSE)
      }
      existing_keys <- output_key(existing_outputs)
      incoming_keys <- output_key(outputs)
      if (anyDuplicated(existing_keys)) {
        stop("Existing Gulf red snapper outputs contain duplicate output keys.",
          call. = FALSE)
      }
      overlap <- match(incoming_keys, existing_keys)
      existing_signature <- row_signature_all(existing_outputs, names(outputs))
      incoming_signature <- row_signature_all(outputs, names(outputs))
      matched <- which(!is.na(overlap))
      if (any(existing_signature[overlap[matched]] != incoming_signature[matched])) {
        stop("Existing Gulf red snapper output rows differ from the source import.",
          call. = FALSE)
      }
      missing_outputs <- outputs[is.na(overlap), , drop = FALSE]
    }
    if (nrow(missing_outputs)) {
      utils::write.table(missing_outputs, "database/outputs.csv", sep = ",",
        row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
    }
  }
  candidate_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$output_evidence[candidate_row] <- paste(
    "Imported 1950-2023 area-specific expected biomass, exploitable biomass, SSB,",
    "age-1+ abundance, age-0 recruitment and the source-reported SSB ratio from",
    "SEDAR 98 Tables 20-22, and exploitation rates from Tables 12-19. The exploitation",
    "rates are preserved as ratios and are not relabeled as instantaneous F. Derived 0+ total abundance by summing reported age-1+",
    "abundance and age-0 recruitment; values inherit table rounding. No age-specific",
    "N-at-age or instantaneous F surfaces or output uncertainty are published in these tables."
  )
  candidates$survey_age_evidence[candidate_row] <- paste(
    "Aggregate mean-one-scaled abundance indices and paired source CVs from SEDAR 98 Tables 5.8.1-5.8.3 are imported.",
    "The report separately describes survey age compositions, which may be derived from age-length keys, but numerical likelihood arrays were unavailable and remain unimported."
  )
  candidates$notes[candidate_row] <- paste(
    "The official final report and supporting data papers are cached under",
    "source_cache/discovery_noaa_gom_red_snapper_2026/ with provenance and SHA-256 hashes.",
    "Report-derived population outputs from Tables 12-22 and aggregate survey indices are imported; catch, age",
    "compositions and numeric biological inputs remain under source review."
  )
  assessment_path <- file.path(root, "database/assessments.csv")
  assessment_rows <- read.csv(assessment_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  assessment_row <- which(assessment_rows$assessment_id == assessment_id)
  if (length(assessment_row) != 1L) stop("Assessment ID is not unique.", call. = FALSE)
  assessment_rows$notes[assessment_row] <- assessment$notes
  replace_csv_register_row(assessment_path, assessment_row,
    assessment_rows[assessment_row, , drop = FALSE], "assessment_id", assessment_id)
  source("scripts/database/candidate_register_io.R")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  selected_path <- file.path(root, "discovery/selected_batch_24_2026.csv")
  selected <- read.csv(selected_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  selected_row <- which(selected$candidate_id == candidate_id)
  if (length(selected_row) != 1L) stop("Selected candidate is not unique.", call. = FALSE)
  selected$curation_status[selected_row] <- "partial_source_import"
  new_urls <- c(
    "https://sedarweb.org/documents/sedar-98-dw-05-general-recreational-survey-data-for-red-snapper-in-the-gulf-of-mexico/",
    "https://sedarweb.org/documents/sedar-98-dw-19-red-snapper-lutjanus-campechanus-larval-indices-of-relative-abundance-from-seamap-fall-plankton-surveys-1986-to-2022/",
    "https://sedarweb.org/documents/sedar-98-dw-24-post-ifq-commercial-vertical-line-abundance-index-for-eastern-gulf-red-snapper-using-reef-fish-observer-data/",
    "https://sedarweb.org/documents/sedar-98-dw-26-red-snapper-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/"
  )
  existing_urls <- strsplit(as.character(selected$detailed_source_url[selected_row]),
    "; ", fixed = TRUE)[[1L]]
  selected$detailed_source_url[selected_row] <- paste(
    unique(c(existing_urls, new_urls)), collapse = "; "
  )
  write.csv(selected, selected_path, row.names = FALSE, na = "")
  cat("Imported", assessment_id, ":", nrow(inputs), "index input rows;",
    nrow(outputs), "reported/derived outputs.\n")
}
