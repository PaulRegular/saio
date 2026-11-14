root <- "."
.libPaths(c(file.path(root, "source_cache/R-library"), .libPaths()))
stock_id <- "noaa_gulf_gray_triggerfish"
assessment_id <- "noaa_gulf_gray_triggerfish_sedar100_2026"
candidate_id <- "NOAA:10062"
assessment_url <- "https://sedarweb.org/assessments/sedar-100-gulf-triggerfish/"
report_url <- "https://sedarweb.org/documents/sedar-100-gulf-gray-triggerfish-final-stock-assessment-report/"
cache_dir <- file.path(root, "source_cache/noaa_gray_triggerfish_gulf_sedar100_20261111")
manifest_path <- file.path(root, "provenance/discovery_noaa_gulf_gray_triggerfish_2026/sources.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached SEDAR 100 tables.", call. = FALSE)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
sha256_file <- function(path) toupper(unname(tools::sha256sum(path)))
verify_source <- function(file) {
  row <- manifest[manifest$file == file, , drop = FALSE]
  path <- file.path(root, "source_cache", row$cache_folder, row$cache_file)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.character(file.info(path)$size) != row$bytes ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from the pinned provenance record: ", file,
      call. = FALSE)
  }
  path
}

sar_path <- verify_source("sedar-100-gulf-gray-triggerfish-final-stock-assessment-report.pdf")
invisible(verify_source("sedar-100-dw-04-recreational-length-age-compositions.pdf"))
invisible(verify_source("sedar-100-dw-05-commercial-landings.pdf"))
invisible(verify_source("sedar-100-dw-06-commercial-discards.pdf"))
invisible(verify_source("sedar-100-dw-07-commercial-length-age-compositions.pdf"))
invisible(verify_source("sedar-100-dw-13-fishery-dependent-age-data.pdf"))
invisible(verify_source("sedar-100-dw-14-age-length-data.pdf"))
invisible(verify_source("sedar-100-dw-16-seamap-index-age-compositions.pdf"))
invisible(verify_source("sedar-100-dw-19-seamap-plankton-indices.pdf"))
invisible(verify_source("sedar-100-cie-review-report-fisch.pdf"))

pages <- pdftools::pdf_text(sar_path)
page_data <- pdftools::pdf_data(sar_path)
page_one <- function(pattern, fixed = TRUE) {
  hit <- which(grepl(pattern, pages, fixed = fixed))
  if (length(hit) != 1L) stop("Expected one report page for: ", pattern, call. = FALSE)
  hit
}
parse_number <- function(x) {
  value <- suppressWarnings(as.numeric(gsub(",", "", trimws(x), fixed = TRUE)))
  if (length(value) != 1L || !is.finite(value)) NA_real_ else value
}

land_start <- page_one("Table 3.9.1.")
land_pages <- seq.int(land_start, land_start + 1L)
land_years <- integer()
land_rows <- list()
land_columns <- c("East handline+", "East longline", "East trap",
  "West handline+", "West longline", "West trap")
for (page in land_pages) {
  z <- page_data[[page]]
  year_words <- z[z$x >= 100 & z$x < 130 & z$y > 50 & z$y < 725 &
    grepl("^(19|20)[0-9]{2}$", z$text), , drop = FALSE]
  for (j in seq_len(nrow(year_words))) {
    year <- as.integer(year_words$text[j])
    if (!year %in% 1949:2024) next
    y <- year_words$y[j]
    cells <- z[z$y == y & z$x >= 150 & z$x < 540, , drop = FALSE]
    column <- findInterval(cells$x, c(150, 220, 285, 345, 405, 471, 540))
    values <- rep(NA_real_, 6L)
    for (k in seq_len(6L)) {
      cell <- cells[column == k, , drop = FALSE]
      if (nrow(cell) > 1L) stop("Multiple landings cells for ", year, ".", call. = FALSE)
      if (nrow(cell) == 1L && cell$text != "*") values[k] <- parse_number(cell$text)
    }
    land_years <- c(land_years, year)
    land_rows[[length(land_rows) + 1L]] <- values
  }
}
if (!identical(sort(land_years), 1949:2024) || anyDuplicated(land_years)) {
  stop("SEDAR 100 Table 3.9.1 must cover each year 1949-2024 exactly once.", call. = FALSE)
}
landings <- as.data.frame(do.call(rbind, land_rows), check.names = FALSE)
names(landings) <- land_columns
landings$year <- land_years
landings <- landings[order(landings$year), c("year", land_columns)]
if (landings$`East handline+`[landings$year == 1949L] != 14300 ||
    landings$`East handline+`[landings$year == 2024L] != 41875 ||
    landings$`West handline+`[landings$year == 2024L] != 1465) {
  stop("SEDAR 100 Table 3.9.1 check values changed.", call. = FALSE)
}

parse_seven_column_table <- function(page) {
  lines <- strsplit(page, "\n", fixed = TRUE)[[1L]]
  rows <- grep("^[[:space:]]*20[0-9]{2}[[:space:]]+", lines, value = TRUE, perl = TRUE)
  values <- lapply(rows, function(line) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    numbers <- suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
    if (length(numbers) != 7L || any(!is.finite(numbers))) {
      stop("Could not parse seven values from a SEDAR 100 table row: ", line,
        call. = FALSE)
    }
    numbers
  })
  if (!length(values)) stop("No annual values found in a SEDAR 100 table.", call. = FALSE)
  out <- as.data.frame(do.call(rbind, values))
  names(out) <- c("year", "east_n", "west_n", "gulf_n",
    "east_lb", "west_lb", "gulf_lb")
  out$year <- as.integer(out$year)
  out
}
discard_page <- page_one("Table 3.9.2. Commercial discard estimates")
discard_se_page <- page_one("Table 3.9.2 continued")
discards <- parse_seven_column_table(pages[discard_page])
discard_se <- parse_seven_column_table(pages[discard_se_page])
if (!identical(discards$year, 2000:2024) ||
    !identical(discard_se$year, 2000:2024) ||
    !identical(discards$year, discard_se$year)) {
  stop("SEDAR 100 Table 3.9.2 and its SE table must cover 2000-2024.", call. = FALSE)
}

index_page <- page_one("Table 5.8.2.")
z_index <- page_data[[index_page]]
index_year_words <- z_index[z_index$x < 100 & z_index$y > 180 & z_index$y < 700 &
  grepl("^(19|20)[0-9]{2}$", z_index$text), , drop = FALSE]
index_cell <- function(y, lower, upper) {
  cells <- z_index[z_index$y == y & z_index$x >= lower & z_index$x < upper, , drop = FALSE]
  if (!nrow(cells)) return(NA_real_)
  if (nrow(cells) != 1L) stop("Multiple Table 5.8.2 cells in one index column.", call. = FALSE)
  parse_number(cells$text)
}
index_table <- data.frame(year = as.integer(index_year_words$text))
index_table$old_index <- vapply(index_year_words$y, index_cell, numeric(1), lower = 105, upper = 165)
index_table$old_cv <- vapply(index_year_words$y, index_cell, numeric(1), lower = 165, upper = 220)
index_table$new_index <- vapply(index_year_words$y, index_cell, numeric(1), lower = 220, upper = 280)
index_table$new_cv <- vapply(index_year_words$y, index_cell, numeric(1), lower = 280, upper = 340)
index_table$video_index <- vapply(index_year_words$y, index_cell, numeric(1), lower = 340, upper = 405)
index_table$video_cv <- vapply(index_year_words$y, index_cell, numeric(1), lower = 405, upper = 460)
index_series <- list(
  list(name = "SEAMAP Summer and Fall Groundfish - Old", value = "old_index",
    cv = "old_cv", season = "summer+fall"),
  list(name = "SEAMAP Summer and Fall Groundfish - New", value = "new_index",
    cv = "new_cv", season = "summer+fall"),
  list(name = "SEAMAP / G-FISHER Video", value = "video_index",
    cv = "video_cv", season = "")
)
for (s in index_series) {
  observed <- index_table[is.finite(index_table[[s$value]]), , drop = FALSE]
  cv <- index_table[is.finite(index_table[[s$cv]]), , drop = FALSE]
  if (!nrow(observed) || !identical(observed$year, cv$year) ||
      any(!is.finite(observed[[s$cv]]))) {
    stop("Index values and CVs do not align for ", s$name, ".", call. = FALSE)
  }
}

rw18_pages <- which(grepl("Table RW18", pages, fixed = TRUE))
if (length(rw18_pages) != 2L) stop("Expected the two Table RW18 pages.", call. = FALSE)
rw18_rows <- list()
for (page in pages[rw18_pages]) {
  lines <- strsplit(page, "\n", fixed = TRUE)[[1L]]
  rows <- grep("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines, value = TRUE, perl = TRUE)
  for (line in rows) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    values <- suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
    if (length(values) != 4L || any(!is.finite(values))) {
      stop("Could not parse two year-rate pairs from Table RW18: ", line, call. = FALSE)
    }
    rw18_rows[[length(rw18_rows) + 1L]] <- data.frame(
      year = c(as.integer(values[1L]), as.integer(values[3L])),
      value = c(values[2L], values[4L]))
  }
}
rw18 <- do.call(rbind, rw18_rows)
rw18 <- rw18[order(rw18$year), , drop = FALSE]
if (!identical(rw18$year, 1945:2024) || anyDuplicated(rw18$year) ||
    rw18$value[rw18$year == 1945L] != 0.0001 ||
    rw18$value[rw18$year == 2024L] != 0.2685) {
  stop("SEDAR 100 Table RW18 checks failed.", call. = FALSE)
}

rw20_pages <- c(page_one("Table RW20. Expected biomass"),
  which(grepl("Table RW20 Continued", pages, fixed = TRUE)))
if (length(rw20_pages) != 3L) stop("Expected the three Table RW20 pages.", call. = FALSE)
rw20_rows <- list()
for (page in rw20_pages) {
  z <- page_data[[page]]
  year_words <- z[z$x < 100 & z$y > 150 & z$y < 700 &
    grepl("^(19|20)[0-9]{2}$", z$text), , drop = FALSE]
  for (j in seq_len(nrow(year_words))) {
    year <- as.integer(year_words$text[j])
    if (!year %in% 1945:2024) next
    y <- year_words$y[j]
    get_cell <- function(lower, upper, at_y = y) {
      cell <- z[abs(z$y - at_y) <= 1 & z$x >= lower & z$x < upper, , drop = FALSE]
      if (!nrow(cell)) return(NA_real_)
      if (nrow(cell) != 1L) stop("Multiple Table RW20 values in one column for ", year, ".", call. = FALSE)
      parse_number(cell$text)
    }
    recruits_first <- get_cell(415, 444)
    recruits_tail <- z$text[z$x >= 444 & z$x < 480 & z$y > y & z$y <= y + 16]
    if (length(recruits_tail) > 1L) stop("Multiple wrapped recruitment digits for ", year, ".", call. = FALSE)
    recruits <- if (is.finite(recruits_first)) {
      token <- z$text[abs(z$y - y) <= 1 & z$x >= 415 & z$x < 444]
      if (length(recruits_tail)) parse_number(paste0(gsub(",", "", token), gsub(",", "", recruits_tail))) else recruits_first
    } else NA_real_
    rw20_rows[[length(rw20_rows) + 1L]] <- data.frame(
      year = year,
      biomass_all = get_cell(125, 200),
      biomass_exploited = get_cell(200, 275),
      ssb = get_cell(275, 345),
      abundance_exploited = get_cell(345, 415),
      recruits = recruits,
      ssb_ratio = get_cell(490, 535))
  }
}
rw20 <- do.call(rbind, rw20_rows)
rw20 <- rw20[order(rw20$year), , drop = FALSE]
if (!identical(rw20$year, 1945:2024) || anyDuplicated(rw20$year) ||
    any(!is.finite(as.matrix(rw20[, -1L]))) ||
    rw20$biomass_all[rw20$year == 1945L] != 22514 ||
    rw20$recruits[rw20$year == 1945L] != 217029000 ||
    rw20$ssb[rw20$year == 2024L] != 3644.39 ||
    rw20$recruits[rw20$year == 2024L] != 81839600) {
  stop("SEDAR 100 Table RW20 year, parsing, or check-value validation failed.", call. = FALSE)
}

input_rows <- list()
add_input <- function(...) input_rows[[length(input_rows) + 1L]] <<-
  pacific_database_row("inputs", assessment_id = assessment_id,
    source_type = "official_table", ...)
landings_ref <- "SEDAR100_final_assessment.pdf, Table 3.9.1 (printed pp. 51-52)"
for (column in land_columns) {
  value <- landings[[column]]
  keep <- is.finite(value)
  if (!any(keep)) next
  region <- if (startsWith(column, "East ")) "East" else "West"
  fleet <- sub("^(East|West) ", "Commercial ", column)
  add_input(type = "catch", measure = "landings_biomass", basis = "biomass",
    fleet = fleet, region = region, season = "annual", year = landings$year[keep],
    year_basis = "calendar_year", value = value[keep], unit = "pounds whole weight",
    source_reference = landings_ref,
    transformation = "Direct transcription; source units and subregion/gear dimensions retained.",
    notes = "Annual calculated landings by gear group. Source asterisks mark confidential values; blank cells and withheld values are not treated as zero.")
}

regions <- c("East", "West", "Gulf-wide")
for (i in seq_len(nrow(discards))) for (j in seq_along(regions)) {
  region <- regions[j]
  n_column <- c("east_n", "west_n", "gulf_n")[j]
  lb_column <- c("east_lb", "west_lb", "gulf_lb")[j]
  se_n <- discard_se[[n_column]][i]
  se_lb <- discard_se[[lb_column]][i]
  common_note <- paste("SEDAR 100 Table 3.9.2 reports East, West and Gulf-wide estimates separately.",
    "These published estimates are not additive and should not be treated as independent likelihood rows.")
  add_input(type = "catch", measure = "discard_numbers", basis = "numbers",
    fleet = "Commercial vertical line", region = region, season = "annual",
    year = discards$year[i], year_basis = "calendar_year",
    value = discards[[n_column]][i], unit = "fish",
    source_reference = "SEDAR100_final_assessment.pdf, Table 3.9.2 (printed p. 53)",
    notes = common_note)
  add_input(type = "catch", measure = "catch_se", basis = "numbers",
    fleet = "Commercial vertical line", region = region, season = "annual",
    year = discards$year[i], year_basis = "calendar_year", value = se_n,
    unit = "fish standard error",
    source_reference = "SEDAR100_final_assessment.pdf, Table 3.9.2 continued (printed p. 54)",
    notes = "Source-reported natural-scale standard error for the discard_numbers observation; pair using the same fleet, region and year; retain without transformation.")
  add_input(type = "catch", measure = "discard_biomass", basis = "biomass",
    fleet = "Commercial vertical line", region = region, season = "annual",
    year = discards$year[i], year_basis = "calendar_year",
    value = discards[[lb_column]][i], unit = "pounds whole weight",
    source_reference = "SEDAR100_final_assessment.pdf, Table 3.9.2 (printed p. 53)",
    notes = common_note)
  add_input(type = "catch", measure = "catch_se", basis = "biomass",
    fleet = "Commercial vertical line", region = region, season = "annual",
    year = discards$year[i], year_basis = "calendar_year", value = se_lb,
    unit = "pounds standard error",
    source_reference = "SEDAR100_final_assessment.pdf, Table 3.9.2 continued (printed p. 54)",
    notes = "Source-reported natural-scale standard error for the discard_biomass observation; pair using the same fleet, region and year; retain without transformation.")
}
for (s in index_series) {
  selected <- index_table[is.finite(index_table[[s$value]]), , drop = FALSE]
  add_input(type = "index", measure = "relative_abundance_index", basis = "index_scale",
    survey = s$name, region = "Northern Gulf of Mexico", season = s$season,
    year = selected$year, year_basis = "calendar_year", value = selected[[s$value]],
    unit = "relative index (series mean = 1)",
    source_reference = "SEDAR100_final_assessment.pdf, Table 5.8.2 (printed p. 148)",
    transformation = "Direct transcription; source index scaling retained.",
    notes = "The Review Panel model includes this series (confirmed by Table RW29). Source CV is retained in separate abundance_index_cv rows; no likelihood SD is inferred here.")
  add_input(type = "index", measure = "abundance_index_cv", basis = "relative_scale",
    survey = s$name, region = "Northern Gulf of Mexico", season = s$season,
    year = selected$year, year_basis = "calendar_year", value = selected[[s$cv]],
    unit = "ratio",
    source_reference = "SEDAR100_final_assessment.pdf, Table 5.8.2 (printed p. 148)",
    notes = "Source-reported coefficient of variation of the mean. The separately estimated extra SD used by the Review Panel is not combined with this input CV.")
}
new_inputs <- do.call(rbind, input_rows)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, age = NA_integer_,
                       age_group = "", source_reference, notes,
                       source_type = "official_table", scenario = "review_panel_revised_base") {
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs",
    assessment_id = assessment_id, type = type, measure = measure, value = value,
    unit = unit, year = year, age = age, age_group = age_group,
    source_type = source_type, source_reference = source_reference,
    notes = notes, scenario = scenario)
}
output_note <- "Review Panel revised-base expected estimate as printed; no standard errors or intervals are tabulated."
add_output("biomass", "total_biomass", rw20$biomass_all, "metric tons", rw20$year,
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = paste(output_note, "All modeled ages."))
add_output("biomass", "biomass_by_age_group", rw20$biomass_exploited,
  "metric tons", rw20$year, age_group = "1+",
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = paste(output_note, "Exploited biomass for ages 1+; not total biomass."))
add_output("biomass", "SSB", rw20$ssb, "metric tons", rw20$year,
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = paste(output_note, "Spawning stock biomass."))
add_output("population", "total_numbers", rw20$abundance_exploited, "fish", rw20$year,
  age_group = "1+",
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = paste(output_note, "Exploited abundance for ages 1+; not total abundance."))
add_output("recruitment", "recruitment", rw20$recruits, "fish", rw20$year,
  age = 0L,
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = paste(output_note, "Recruitment is age 0."))
add_output("biomass", "SSB_ratio_to_B0", rw20$ssb_ratio, "proportion", rw20$year,
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = paste(output_note, "Source denominator SSB0 = 19,799 metric tons."))
add_output("population", "total_numbers", rw20$abundance_exploited + rw20$recruits,
  "fish", rw20$year, age_group = "0+",
  source_type = "derived_source_output",
  source_reference = "SEDAR100_final_assessment.pdf, Table RW20 (printed pp. 86-88)",
  notes = "Derived as reported age-1+ abundance plus reported age-0 recruitment. Both source values are rounded; joint uncertainty is unavailable.")
add_output("mortality", "exploitation_rate", rw18$value, "proportion", rw18$year,
  source_reference = "SEDAR100_final_assessment.pdf, Table RW18 (printed pp. 81-82)",
  notes = "Source-defined annual exploitation rate: biomass killed at all ages divided by age-1+ biomass; reported as a proxy for F. This is not instantaneous fishing mortality or F-at-age.")
new_outputs <- do.call(rbind, output_rows)

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA", authority_stock_id = "10062",
  scientific_name = "Balistes capriscus", common_name = "Gulf of Mexico gray triggerfish",
  area = "Gulf of Mexico", region = "United States Gulf of Mexico",
  ocean = "Northwest Atlantic",
  notes = "Current Gulf-wide unit (sexes combined), separate from the Southern Atlantic Coast unit. NOAA Stock SMART's 2020 assessment year is superseded by SEDAR 100 (data through 2024). Formal adoption of the SEDAR 100 Review Panel revised-base model was not confirmed in reviewed sources.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2026L, terminal_year = 2024L,
  estimate_terminal_year = 2024L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.21.00; SEDAR 100 Review Panel revised-base model",
  is_current = TRUE, is_applied = FALSE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = "", data_url = assessment_url,
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed SEDAR 100 report located, completed in 2026 with data through 2024. Imported annual outputs are explicitly from the Review Panel revised-base model. NOAA peer-review dissemination date and formal management adoption were not confirmed; is_applied=FALSE records no verified evidence that this revised-base run was applied, not evidence of rejection.")

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes)
}
assumption_ref <- "SEDAR100_final_assessment.pdf, SEDAR 100 model description and cited tables"
add_assumption("model", "model_family", "Stock Synthesis 3.30.21.00", assumption_ref)
add_assumption("population", "modeled_years", "1945-2024", assumption_ref)
add_assumption("population", "modeled_ages", "0-15", assumption_ref)
add_assumption("population", "sex_structure", "Sexes combined", assumption_ref)
add_assumption("population", "composition_age_bins", "0-10+", assumption_ref,
  "The assessment models ages through 15; composition bins combine ages 10 and older.")
add_assumption("population", "fishing_timing", "Continuous fishing", assumption_ref)
add_assumption("population", "recruitment_timing", "July 1 settlement", assumption_ref)
add_assumption("mortality", "review_panel_base_M", "0.36 per year for fully selected ages, scaled by age with Lorenzen (2000)",
  "SEDAR100_final_assessment.pdf, Table RW43 (printed p. 114)",
  "This is the Review Panel revised-base specification; the numerical final age-specific M surface is not tabulated.")
m_age <- c(1.374, 0.775, 0.589, 0.500, 0.450, 0.419, 0.398, 0.384,
  0.375, 0.368, 0.363, 0.359, 0.356, 0.354, 0.353, 0.352)
add_assumption("mortality", "assessment_process_recommended_M_at_age",
  paste(paste0("age ", 0:15, "=", format(m_age, nsmall = 3)), collapse = "; "),
  "SEDAR100_final_assessment.pdf, Table 2.13.4 (printed p. 26)",
  "These recommended values belong to the Assessment Process model. They are recorded for provenance and are not represented as the Review Panel revised-base model's final M-at-age surface.")
add_assumption("index", "survey_timing", "Not reported as a within-year fraction",
  "SEDAR100_final_assessment.pdf, Table 5.8.2 and SEDAR 100 survey descriptions",
  "No sampling_time value is assigned to the index rows.")
add_assumption("index", "review_panel_index_series", "SEAMAP Summer and Fall Groundfish old and new series; SEAMAP/G-FISHER video",
  "SEDAR100_final_assessment.pdf, Tables 5.8.2 and RW29",
  "The Headboat series in Table 5.8.2 is not included in the Review Panel revised-base model and is not imported as a fitted index.")
new_assumptions <- do.call(rbind, assumption_rows)

if (any(!is.finite(as.numeric(new_inputs$value))) ||
    any(!is.finite(as.numeric(new_outputs$value))) ||
    nrow(new_inputs) < 200L || nrow(new_outputs) != 640L ||
    nrow(new_assumptions) != 11L) {
  stop("Unexpected SEDAR 100 row totals or non-finite values: inputs=", nrow(new_inputs), ", assumptions=", nrow(new_assumptions), ", outputs=", nrow(new_outputs), ", nonfinite input=", sum(!is.finite(as.numeric(new_inputs$value))), ", nonfinite output=", sum(!is.finite(as.numeric(new_outputs$value))), call. = FALSE)
}
if (write_mode) {
  append_pacific_case(stock, assessment, new_assumptions, new_inputs, new_outputs)
  candidates_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
    colClasses = "character", check.names = FALSE)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L) stop("Expected one NOAA:10062 candidate row.", call. = FALSE)
  candidate <- candidates[candidate_row, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$notes <- "Partial SEDAR 100 source records imported: landings, commercial discards, selected aggregate indices, Review Panel revised-base annual aggregate outputs, and documented M assumptions. Native catch-at-age, annual N/F-at-age, weight-at-age and maturity-at-age remain unavailable."
  replace_candidate_register_row(candidates_path, candidate_row, candidate, candidate_id)
  batch_path <- file.path(root, "discovery/selected_batch_23_2026.csv")
  batch <- read.csv(batch_path, stringsAsFactors = FALSE, check.names = FALSE)
  batch_row <- which(batch$candidate_id == candidate_id)
  if (length(batch_row) != 1L) stop("Expected one selected-batch row for NOAA:10062.", call. = FALSE)
  batch$curation_status[batch_row] <- "imported_partial"
  write.csv(batch, batch_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat("Imported ", nrow(new_inputs), " input rows, ", nrow(new_assumptions),
    " assumptions, and ", nrow(new_outputs), " output rows for ", assessment_id, ".\n", sep = "")
} else {
  cat("Prepared ", nrow(new_inputs), " input rows, ", nrow(new_assumptions),
    " assumptions, and ", nrow(new_outputs), " output rows for ", assessment_id, ".\n", sep = "")
  cat("Landings values: ", sum(is.finite(as.matrix(landings[, -1L]))),
    "; index rows: ", sum(new_inputs$measure == "relative_abundance_index"),
    "; discard rows: ", sum(new_inputs$measure %in% c("discard_numbers", "discard_biomass")),
    "; output years: 1945-2024.\n", sep = "")
}
