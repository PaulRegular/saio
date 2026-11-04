root <- "."
assessment_id <- "nafo_cod_3no_2021"
stock_id <- "nafo_cod_3no"
dry_run <- identical(Sys.getenv("SAIO_NAFO_IMPORT_DRY_RUN"), "1")
cache_dir <- file.path(root, "source_cache", assessment_id)
report_path <- file.path(cache_dir, "nafo_scr21_031_cod3no_2021.pdf")

required_packages <- c("pdftools", "png", "tesseract")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Install required extraction packages: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}
if (!file.exists(report_path)) {
  stop("Download the assessment PDF listed in provenance/nafo_cod_3no_2021/manifest.csv.", call. = FALSE)
}

pdf_pages <- pdftools::pdf_text(report_path)
raster_pages <- c(11L, 12L, 23L, 24L, 32L)
image_paths <- file.path(cache_dir, sprintf("page%d_300.png", raster_pages))
if (any(!file.exists(image_paths))) {
  stop("Render report pages 11, 12, 23, 24, and 32 at 300 dpi into source_cache/nafo_cod_3no_2021.", call. = FALSE)
}
images <- lapply(image_paths, png::readPNG)
names(images) <- as.character(raster_pages)
ocr_engines <- lapply(c(7L, 8L, 13L), function(mode) {
  tesseract::tesseract("eng", options = list(
    tessedit_pageseg_mode = mode,
    tessedit_char_whitelist = "0123456789."
  ))
})

read_text_table <- function(page, years, expected_values) {
  lines <- strsplit(pdf_pages[[page]], "\n", fixed = TRUE)[[1]]
  values <- lapply(years, function(year) {
    pattern <- paste0("^\\s*", year, "\\s+")
    matches <- grep(pattern, lines, perl = TRUE)
    if (length(matches) != 1L) {
      stop("Expected one row for ", year, " on PDF page ", page, "; found ", length(matches), call. = FALSE)
    }
    tokens <- strsplit(trimws(lines[[matches]]), "\\s+")[[1]]
    row <- suppressWarnings(as.numeric(tokens[-1L]))
    if (length(row) != expected_values || anyNA(row) || any(!is.finite(row))) {
      stop("Could not parse the expected values for ", year, " on PDF page ", page, call. = FALSE)
    }
    row
  })
  names(values) <- as.character(years)
  values
}

text_tables <- list(
  juvenile = read_text_table(25L, 1989:1994, 16L),
  maturity = read_text_table(26L, 1959:2020, 14L),
  numbers = read_text_table(28L, 1959:2020, 12L),
  fishing_mortality = read_text_table(29L, 1959:2019, 13L),
  stock_weights = read_text_table(30L, 1959:2020, 10L),
  biomass = read_text_table(31L, 1959:2020, 12L)
)

png_raw <- function(image) {
  connection <- rawConnection(raw(), "wb")
  png::writePNG(image, connection)
  value <- rawConnectionValue(connection)
  close(connection)
  value
}

ocr_text <- function(page, x1, x2, year, first_year, first_y, row_step,
  extra_height = 35L) {
  y1 <- as.integer(round(first_y + (year - first_year) * row_step))
  image <- images[[as.character(page)]]
  crop <- image[y1:(y1 + extra_height), x1:x2, , drop = FALSE]
  image_data <- png_raw(crop)
  for (engine in ocr_engines) {
    value <- trimws(tesseract::ocr(image_data, engine = engine))
    if (nzchar(value)) return(value)
  }
  ""
}

parse_integer <- function(text, page, year, age) {
  if (!grepl("^[0-9]+$", text)) {
    stop("Unreadable integer at PDF page ", page, ", year ", year, ", age ", age,
      ": '", text, "'.", call. = FALSE)
  }
  as.numeric(text)
}

parse_two_decimals <- function(text, page, year, age) {
  if (grepl("^[0-9]+\\.[0-9]{2}$", text)) return(as.numeric(text))
  if (grepl("^[0-9]+$", text)) return(as.numeric(text) / 100)
  stop("Unreadable two-decimal value at PDF page ", page, ", year ", year, ", age ", age,
    ": '", text, "'.", call. = FALSE)
}

cell_bounds <- function(page, age) {
  if (page == 11L) {
    bounds <- c(437, 597, 775, 952, 1129, 1306, 1483, 1627, 1787, 1947, 2107, 2250)
    i <- age - 2L + 1L
    right <- bounds[[i + 1L]]
    return(c(right - 85L, right - 5L))
  }
  if (page == 12L) {
    bounds <- c(633, 775, 918, 1061, 1204, 1346, 1489, 1632, 1775, 1918, 2060)
    i <- age - 3L + 1L
    right <- bounds[[i + 1L]]
    return(c(right - 90L, right - 5L))
  }
  if (page == 23L) {
    left <- 670 + 120 * (age - 2L) + 4L
    return(c(left, left + 115L))
  }
  if (page == 24L) {
    left <- 730 + 113 * (age - 2L)
    return(c(left, left + 110L))
  }
  if (page == 32L && age %in% 3:12) {
    bounds <- c(568, 714, 861, 1008, 1155, 1302, 1449, 1597, 1744, 1891, 2044)
    i <- age - 3L + 1L
    right <- bounds[[i + 1L]]
    return(c(right - 84L, right))
  }
  if (page == 32L && age == -1L) return(c(2085L, 2185L))
  stop("Unsupported source page/age cell.", call. = FALSE)
}

raster_value <- function(page, year, age, first_year, first_y, row_step,
  decimal = FALSE, extra_height = 35L) {
  bounds <- cell_bounds(page, age)
  text <- ocr_text(page, bounds[[1]], bounds[[2]], year,
    first_year, first_y, row_step, extra_height)
  if (decimal) parse_two_decimals(text, page, year, age)
  else parse_integer(text, page, year, age)
}

table25_column_rights <- c(714, 861, 1008, 1155, 1302, 1449,
  1597, 1744, 1891, 2044, 2185)

table25_ocr_data <- function(mode) {
  engine <- tesseract::tesseract("eng", options = list(tessedit_pageseg_mode = mode))
  data <- tesseract::ocr_data(image_paths[[which(raster_pages == 32L)]], engine = engine)
  bounds <- do.call(rbind, strsplit(data$bbox, ",", fixed = TRUE))
  data$left <- as.numeric(bounds[, 1L])
  data$top <- as.numeric(bounds[, 2L])
  data$right <- as.numeric(bounds[, 3L])
  data
}

table25_row <- function(data, year) {
  labels <- data[data$word == as.character(year) & data$left < 600 & data$top > 400, ]
  if (nrow(labels) != 1L) {
    stop("Expected one year label for Table 25 in ", year, call. = FALSE)
  }
  row <- data[data$top >= labels$top[[1L]] - 5 &
    data$top <= labels$top[[1L]] + 15 & data$left > 620 &
    data$right < 2220 & grepl("^[0-9]+$", data$word), ]
  values <- rep(NA_real_, 11L)
  names(values) <- c(as.character(3:12), "ssb")
  for (i in seq_len(nrow(row))) {
    column <- which.min(abs(row$right[[i]] - table25_column_rights))
    if (!is.na(values[[column]])) {
      stop("Duplicate Table 25 cell detected in ", year, call. = FALSE)
    }
    values[[column]] <- as.numeric(row$word[[i]])
  }
  for (column in which(is.na(values))) {
    age <- if (column <= 10L) as.integer(names(values)[[column]]) else -1L
    values[[column]] <- raster_value(32L, year, age, 1959L, 470,
      2465 / 61, decimal = FALSE, extra_height = 45L)
  }
  values
}

table25_primary <- table25_ocr_data(3L)
table25_secondary <- table25_ocr_data(6L)
table25_values <- do.call(rbind, lapply(1959:2020, function(year) {
  values <- table25_row(table25_primary, year)
  if (abs(sum(values[1:10]) - values[[11L]]) > 6) {
    values <- table25_row(table25_secondary, year)
  }
  if (abs(sum(values[1:10]) - values[[11L]]) > 6) {
    stop("Table 25 age-specific mature biomass does not match SSB within rounding in ",
      year, call. = FALSE)
  }
  values
}))
rownames(table25_values) <- as.character(1959:2020)

input_rows <- list()
output_rows <- list()

add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
  age = NA_real_, fleet = "", survey = "", region = "", season = "",
  source_type = "official_table", source_reference, transformation = "",
  notes = "") {
  has_year <- !is.na(year)
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    basis = basis,
    fleet = fleet,
    survey = survey,
    sex = "",
    region = region,
    season = season,
    year = if (has_year) as.integer(year) else NA_integer_,
    year_basis = if (has_year) "calendar_year" else "",
    age = age,
    value = value,
    unit = unit,
    sampling_time = NA_real_,
    source_type = source_type,
    source_reference = source_reference,
    transformation = transformation,
    notes = notes,
    observation_id = NA_character_,
    length_bin = NA_character_,
    length_bin_lower = NA_real_,
    length_bin_upper = NA_real_,
    sample_size = NA_real_,
    age_error = NA_character_,
    partition = NA_character_,
    stringsAsFactors = FALSE
  )
}

add_output <- function(type, measure, value, unit, year = NA_integer_,
  age = NA_real_, age_group = "", se = NA_real_, lwr = NA_real_,
  upr = NA_real_, survey = "", source_type = "official_table", source_reference,
  notes = "") {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    fleet = "",
    survey = survey,
    sex = "",
    region = "",
    season = "",
    year = if (!is.na(year)) as.integer(year) else NA_integer_,
    age = age,
    age_group = age_group,
    value = value,
    se = se,
    lwr = lwr,
    upr = upr,
    unit = unit,
    source_type = source_type,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

division <- "NAFO Divisions 3NO"
spring_survey <- "Canadian spring RV bottom-trawl survey"
autumn_survey <- "Canadian autumn RV bottom-trawl survey"
juvenile_survey <- "Canadian juvenile survey"

for (year in 1959:2019) {
  for (age in 2:12) {
    value <- raster_value(11L, year, age, 1959L, 470, 37.4,
      decimal = FALSE, extra_height = 38L)
    add_input(
      type = "catch", measure = "numbers_at_age", basis = "numbers",
      year = year, age = age, value = value, unit = "thousand fish",
      fleet = "Commercial catch", region = division,
      source_type = "digitized",
      source_reference = "NAFO SCR Doc. 21/031, Table 4, p. 11",
      transformation = "Cell-by-cell OCR transcription of the scanned table; values are preserved as printed.",
      notes = "Catch numbers-at-age used in the ADAPT assessment."
    )
  }
}

for (year in 1959:2019) {
  for (age in 3:12) {
    value <- raster_value(12L, year, age, 1959L, 470, 2355 / 60,
      decimal = TRUE)
    add_input(
      type = "catch_weight", measure = "catch_weight_at_age",
      basis = "kg_per_fish", year = year, age = age,
      value = value, unit = "kg/fish", fleet = "Commercial catch",
      region = division, source_type = "digitized",
      source_reference = "NAFO SCR Doc. 21/031, Table 5, p. 12",
      transformation = "Cell-by-cell OCR transcription of the scanned table; values are printed to two decimal places.",
      notes = "Catch weight-at-age series reported as used in the assessment; kept separate from the beginning-of-year stock weights used in biomass calculations."
    )
  }
}

for (year in c(1984:2005, 2007:2019)) {
  for (age in 2:10) {
    value <- raster_value(23L, year, age, 1984L, 525, 44,
      decimal = TRUE)
    add_input(
      type = "index", measure = "numbers_at_age", basis = "numbers",
      year = year, age = age, value = value, unit = "fish per tow",
      survey = spring_survey, region = division, season = "spring",
      source_type = "digitized",
      source_reference = "NAFO SCR Doc. 21/031, Table 16, p. 23",
      transformation = "Cell-by-cell OCR transcription of the scanned table; values are printed to two decimal places.",
      notes = "Mean number per tow at age. The source describes Engel-to-Campelen conversion for 1984-1995 and actual Campelen surveys from 1996; no single annual sampling_time is assigned."
    )
  }
}

for (year in c(1990:2013, 2015:2019)) {
  for (age in 2:10) {
    value <- raster_value(24L, year, age, 1990L, 465, 1205 / 29,
      decimal = TRUE, extra_height = 38L)
    add_input(
      type = "index", measure = "numbers_at_age", basis = "numbers",
      year = year, age = age, value = value, unit = "fish per tow",
      survey = autumn_survey, region = division, season = "autumn",
      source_type = "digitized",
      source_reference = "NAFO SCR Doc. 21/031, Table 17, p. 24",
      transformation = "Cell-by-cell OCR transcription of the scanned table; values are printed to two decimal places.",
      notes = "Mean number per tow at age. The source describes Engel-to-Campelen conversion for 1984-1994 and Campelen survey values thereafter; no single annual sampling_time is assigned."
    )
  }
}

for (year in 1989:1994) {
  row <- text_tables$juvenile[[as.character(year)]]
  for (age in 2:10) {
    value <- row[[age + 1L]]
    add_input(
      type = "index", measure = "numbers_at_age", basis = "numbers",
      year = year, age = age, value = value, unit = "fish per tow",
      survey = juvenile_survey, region = division,
      season = "August-September", source_type = "official_table",
      source_reference = "NAFO SCR Doc. 21/031, Table 18, p. 25",
      notes = "Mean number per tow at age from the Canadian juvenile survey."
    )
  }
}

for (year in 1959:2020) {
  stock_weight <- text_tables$stock_weights[[as.character(year)]]
  maturity <- text_tables$maturity[[as.character(year)]]
  for (age in 3:12) {
    add_input(
      type = "weight", measure = "weight_at_age", basis = "kg_per_fish",
      year = year, age = age, value = stock_weight[[age - 2L]],
      unit = "kg/fish", region = division,
      source_reference = "NAFO SCR Doc. 21/031, Table 23, p. 30",
      notes = "Beginning-of-year mean stock weight-at-age calculated from commercial catches and used in biomass calculations."
    )
  }
  for (age in 2:12) {
    add_input(
      type = "maturity", measure = "maturity_at_age", basis = "proportion",
      year = year, age = age, value = maturity[[age]],
      unit = "proportion", region = division,
      source_reference = "NAFO SCR Doc. 21/031, Table 19, p. 26",
      notes = "Annual estimated female maturity ogive from a cohort probit model. The source describes forward/backward extrapolation and averaging for cohorts where the model did not fit."
    )
  }
}

for (age in 2:12) {
  add_input(
    type = "M", measure = "natural_mortality_at_age", basis = "per_year",
    age = age, value = 0.2, unit = "year^-1",
    source_reference = "NAFO SCR Doc. 21/031, p. 5",
    notes = "Natural mortality is fixed at 0.2 per year for the modeled ages."
  )
}

for (year in 1959:2020) {
  n <- text_tables$numbers[[as.character(year)]]
  biomass <- text_tables$biomass[[as.character(year)]]
  stock_weight <- text_tables$stock_weights[[as.character(year)]]
  for (age in 2:12) {
    add_output(
      type = "population", measure = "numbers_at_age", year = year,
      age = age, value = n[[age - 1L]], unit = "thousand fish",
      source_reference = "NAFO SCR Doc. 21/031, Table 21, p. 28",
      notes = "ADAPT bias-adjusted analytical estimate. The report does not tabulate uncertainty for this series."
    )
  }
  add_output(
    type = "population", measure = "total_numbers", year = year,
    value = n[[12L]], unit = "thousand fish",
    source_reference = "NAFO SCR Doc. 21/031, Table 21, p. 28",
    notes = "Reported total across modeled ages 2-12; bias-adjusted analytical estimate. No interval is tabulated."
  )
  if (year <= 2019L) {
    f <- text_tables$fishing_mortality[[as.character(year)]]
    for (age in 2:12) {
      add_output(
        type = "mortality", measure = "fishing_mortality_at_age",
        year = year, age = age, value = f[[age - 1L]], unit = "year^-1",
        source_reference = "NAFO SCR Doc. 21/031, Table 22, p. 29",
        notes = "Bias-adjusted analytical fishing mortality estimate. No interval is tabulated."
      )
    }
    add_output(
      type = "mortality", measure = "Fbar", year = year,
      age_group = "6-9", value = f[[12L]], unit = "year^-1",
      source_reference = "NAFO SCR Doc. 21/031, Table 22, p. 29",
      notes = "Reported Fbar for ages 6-9. No interval is tabulated."
    )
    add_output(
      type = "mortality", measure = "Fbar", year = year,
      age_group = "4-6", value = f[[13L]], unit = "year^-1",
      source_reference = "NAFO SCR Doc. 21/031, Table 22, p. 29",
      notes = "Reported Fbar for ages 4-6. No interval is tabulated."
    )
  }
  for (age in 3:12) {
    add_output(
      type = "biomass", measure = "biomass_at_age", year = year,
      age = age, value = biomass[[age - 2L]], unit = "tonnes",
      source_reference = "NAFO SCR Doc. 21/031, Table 24, p. 31",
      notes = "Reported biomass-at-age based on bias-adjusted population numbers and beginning-of-year weights."
    )
    add_output(
      type = "biomass", measure = "mature_biomass_at_age", year = year,
      age = age,
      value = table25_values[as.character(year), as.character(age)],
      unit = "tonnes", source_type = "digitized",
      source_reference = "NAFO SCR Doc. 21/031, Table 25, p. 32",
      notes = "Reported spawner biomass-at-age from the scanned table, using annual maturity ogives, beginning-of-year weights and bias-adjusted population numbers. OCR row sums were checked against reported SSB."
    )
  }
  add_output(
    type = "biomass", measure = "total_biomass", year = year,
    age_group = "3+", value = biomass[[11L]], unit = "tonnes",
    source_reference = "NAFO SCR Doc. 21/031, Table 24, p. 31",
    notes = "Reported biomass of ages 3+; no uncertainty is tabulated."
  )
  add_output(
    type = "biomass", measure = "total_biomass", year = year,
    age_group = "6+", value = biomass[[12L]], unit = "tonnes",
    source_reference = "NAFO SCR Doc. 21/031, Table 24, p. 31",
    notes = "Reported biomass of ages 6+; no uncertainty is tabulated."
  )
  add_output(
    type = "biomass", measure = "SSB", year = year,
    value = table25_values[as.character(year), "ssb"],
    unit = "tonnes", source_type = "digitized",
    source_reference = "NAFO SCR Doc. 21/031, Table 25, p. 32",
    notes = "Reported spawner biomass; based on annual maturity ogives, beginning-of-year weights and bias-adjusted population numbers. No uncertainty is tabulated."
  )
}

table20_lines <- strsplit(pdf_pages[[27L]], "\n", fixed = TRUE)[[1L]]
survivor_lines <- grep("^\\s*(199[4-9]|20[0-2][0-9])\\s+\\d+\\s+",
  table20_lines, perl = TRUE, value = TRUE)
catchability_lines <- grep("^\\s*(RV\\s+Spr|RV_Fall|RV_Juvenile)\\s+\\d+\\s+",
  table20_lines, perl = TRUE, value = TRUE)

parse_table20_numbers <- function(line, start, count) {
  tokens <- strsplit(trimws(line), "\\s+")[[1L]]
  values <- suppressWarnings(as.numeric(tokens[start:(start + count - 1L)]))
  if (length(values) != count || anyNA(values) || any(!is.finite(values))) {
    stop("Could not parse a Table 20 value row: ", line, call. = FALSE)
  }
  values
}

survivors <- do.call(rbind, lapply(survivor_lines, function(line) {
  values <- parse_table20_numbers(line, 1L, 5L)
  data.frame(year = as.integer(values[[1L]]), age = as.integer(values[[2L]]),
    estimate = values[[3L]], se = values[[4L]], relative_error = values[[5L]])
}))
if (nrow(survivors) != 36L) stop("Unexpected Table 20 survivor rows.", call. = FALSE)
for (i in seq_len(nrow(survivors))) {
  add_output(
    type = "population", measure = "survivors_at_age",
    year = survivors$year[[i]], age = survivors$age[[i]],
    value = survivors$estimate[[i]], se = survivors$se[[i]],
    unit = "thousand fish",
    source_reference = "NAFO SCR Doc. 21/031, Table 20, p. 27",
    notes = paste0("ADAPT survivor parameter estimate before bias adjustment; Table 20 relative error = ",
      format(survivors$relative_error[[i]], trim = TRUE), ".")
  )
}

parse_catchability_row <- function(line) {
  tokens <- strsplit(trimws(line), "\\s+")[[1L]]
  if (tokens[[1L]] == "RV") {
    survey_label <- paste(tokens[1:2], collapse = " ")
    age_position <- 3L
  } else {
    survey_label <- tokens[[1L]]
    age_position <- 2L
  }
  values <- parse_table20_numbers(line,
    start = age_position, count = 6L)
  survey <- switch(survey_label,
    "RV Spr" = spring_survey,
    "RV_Fall" = autumn_survey,
    "RV_Juvenile" = juvenile_survey,
    stop("Unknown Table 20 survey label: ", survey_label, call. = FALSE))
  data.frame(survey = survey, age = as.integer(values[[1L]]),
    estimate = values[[2L]], se = values[[3L]], relative_error = values[[4L]])
}

catchabilities <- do.call(rbind, lapply(catchability_lines, parse_catchability_row))
if (nrow(catchabilities) != 27L || any(table(catchabilities$survey) != 9L)) {
  stop("Unexpected Table 20 catchability rows.", call. = FALSE)
}
for (i in seq_len(nrow(catchabilities))) {
  add_output(
    type = "catchability", measure = "q",
    age = catchabilities$age[[i]], survey = catchabilities$survey[[i]],
    value = catchabilities$estimate[[i]], se = catchabilities$se[[i]],
    unit = "reported linear scale",
    source_reference = "NAFO SCR Doc. 21/031, Table 20, p. 27",
    notes = paste0("Age-specific survey catchability and standard error in linear scale; Table 20 relative error = ",
      format(catchabilities$relative_error[[i]], trim = TRUE), ".")
  )
}

inputs_new <- do.call(rbind, input_rows)
outputs_new <- do.call(rbind, output_rows)

input_value <- function(type, measure, year = NA_integer_, age = NA_real_, survey = NULL) {
  selected <- inputs_new$type == type & inputs_new$measure == measure
  if (!is.na(year)) selected <- selected & inputs_new$year == year
  if (!is.na(age)) selected <- selected & inputs_new$age == age
  if (!is.null(survey)) selected <- selected & inputs_new$survey == survey
  values <- inputs_new$value[selected]
  if (length(values) != 1L) stop("Expected one input value: ", measure, call. = FALSE)
  as.numeric(values[[1]])
}
output_value <- function(type, measure, year = NA_integer_, age = NA_real_,
  age_group = NULL) {
  selected <- outputs_new$type == type & outputs_new$measure == measure
  if (!is.na(year)) selected <- selected & outputs_new$year == year
  if (!is.na(age)) selected <- selected & outputs_new$age == age
  if (!is.null(age_group)) selected <- selected & outputs_new$age_group == age_group
  values <- outputs_new$value[selected]
  if (length(values) != 1L) stop("Expected one output value: ", measure, call. = FALSE)
  as.numeric(values[[1]])
}

stopifnot(
  input_value("catch", "numbers_at_age", 1959L, 2) == 0,
  input_value("catch", "numbers_at_age", 1959L, 3) == 1711,
  input_value("catch", "numbers_at_age", 2019L, 12) == 4,
  input_value("catch_weight", "catch_weight_at_age", 1959L, 3) == 0.42,
  input_value("catch_weight", "catch_weight_at_age", 2019L, 12) == 6.41,
  input_value("index", "numbers_at_age", 1984L, 2) == 53.39,
  input_value("index", "numbers_at_age", 2019L, 2, spring_survey) == 2.06,
  input_value("index", "numbers_at_age", 1990L, 2, autumn_survey) == 6.15,
  input_value("index", "numbers_at_age", 1991L, 2, autumn_survey) == 129.66,
  input_value("index", "numbers_at_age", 1989L, 2, juvenile_survey) == 14.16,
  input_value("weight", "weight_at_age", 2020L, 12) == 5.377,
  input_value("maturity", "maturity_at_age", 1959L, 2) == text_tables$maturity[["1959"]][[2L]],
  output_value("population", "numbers_at_age", 1959L, 2) == 63623,
  output_value("population", "total_numbers", 1959L) == 270633,
  output_value("mortality", "fishing_mortality_at_age", 1959L, 6) == 0.511,
  output_value("mortality", "Fbar", 2019L, age_group = "6-9") == 0.076,
  output_value("mortality", "Fbar", 2019L, age_group = "4-6") == 0.066,
  output_value("biomass", "total_biomass", 1959L, age_group = "3+") == 206498,
  output_value("biomass", "total_biomass", 2020L, age_group = "6+") == 7299,
  output_value("biomass", "SSB", 1959L) == 72220,
  output_value("biomass", "SSB", 2020L) == 7273
)

if (nrow(inputs_new) != 3224L || nrow(outputs_new) != 3026L) {
  stop("Unexpected extracted row counts; no canonical files were changed.", call. = FALSE)
}
if (any(!is.finite(inputs_new$value)) || any(!is.finite(outputs_new$value))) {
  stop("Non-finite values found in extracted records.", call. = FALSE)
}
for (year in 1959:2020) {
  n <- text_tables$numbers[[as.character(year)]]
  if (abs(sum(n[1:11]) - n[[12L]]) > 6) stop("Population total differs from age sum beyond rounding in ", year, call. = FALSE)
  b <- text_tables$biomass[[as.character(year)]]
  if (abs(sum(b[1:10]) - b[[11L]]) > 6) {
    stop("Biomass 3+ total differs from age sum beyond rounding in ", year, call. = FALSE)
  }
  if (abs(sum(b[4:10]) - b[[12L]]) > 4) {
    stop("Biomass 6+ total differs from age sum beyond rounding in ", year, call. = FALSE)
  }
  mature_age <- outputs_new$value[
    outputs_new$type == "biomass" & outputs_new$measure == "mature_biomass_at_age" &
      outputs_new$year == year
  ]
  ssb <- output_value("biomass", "SSB", year)
  if (abs(sum(mature_age) - ssb) > 6) stop("Spawner biomass-at-age does not sum to SSB in ", year, call. = FALSE)
}

assumptions_new <- data.frame(
  assessment_id = assessment_id,
  component = c("population", "population", "population", "population",
    "survey", "mortality", "mortality", "population", "catch",
    "survey", "survey", "survey", "survey", "biology", "biology",
    "population", "assessment"),
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c("model_structure", "assessment_years", "modeled_ages",
    "estimated_survivor_parameters", "age_specific_catchability",
    "natural_mortality", "oldest_age_fishing_mortality", "plus_group",
    "catch_at_age_error", "survey_objective", "survey_ages_and_years",
    "survey_representation", "survey_timing", "maturity_method",
    "stock_weight_basis", "terminal_population_year", "native_fit_files"),
  value = c(
    "ADAPT sequential population analysis calibrated with Canadian research vessel surveys.",
    "Catch-at-age and survey inputs through 2019; population estimates through 2020.",
    "Ages 2-12; no plus group.",
    "Survivors at ages 3-12 in 2020 and age 12 in 1994-2019 were estimated as model parameters.",
    "Separate linear-scale q estimates for each of three surveys and ages 2-10 (27 parameters).",
    "M was fixed at 0.2 per year.",
    "F at age 12 was set equal to average F for ages 6-9 in 1959-1993.",
    "No plus age class was modeled.",
    "Catch numbers-at-age were treated as exact observations, with no observation error.",
    "The objective is the sum of squared log residuals between each survey index and q times abundance; all indices are equally weighted.",
    "Spring RV: ages 2-10, 1984-2005 and 2007-2019; autumn RV: ages 2-10, 1990-2013 and 2015-2019; juvenile survey: ages 2-10, 1989-1994.",
    "Pre-Campelen observations use the source's Engel-to-Campelen conversion; post-transition observations are Campelen survey results.",
    "The report gives seasonal surveys and date ranges; no single fraction-of-year timing value is assigned.",
    "Annual female maturity ogives were estimated with a cohort probit model. The report describes extrapolation and adjacent-year averaging when a cohort model did not fit.",
    "Beginning-of-year stock weights used for biomass calculations are distinct from catch weights-at-age.",
    "The input catch-at-age matrix ends in 2019; reported population estimates extend through 2020.",
    "No public fitted object or production ADAPT code was located. The 2022 state-space paper is exploratory and is not substituted for the official ADAPT run."
  ),
  source_reference = c(
    rep("NAFO SCR Doc. 21/031, pp. 4-6", 4),
    "NAFO SCR Doc. 21/031, Table 20, p. 27",
    "NAFO SCR Doc. 21/031, p. 5",
    "NAFO SCR Doc. 21/031, p. 5",
    "NAFO SCR Doc. 21/031, p. 5",
    "NAFO SCR Doc. 21/031, p. 5",
    "NAFO SCR Doc. 21/031, p. 5",
    "NAFO SCR Doc. 21/031, Tables 16-18, pp. 23-25",
    "NAFO SCR Doc. 21/031, Tables 16-18, pp. 23-25",
    "NAFO SCR Doc. 21/031, Tables 7-8 and survey dates, pp. 13-15",
    "NAFO SCR Doc. 21/031, Table 19, p. 26",
    "NAFO SCR Doc. 21/031, Table 23, p. 30",
    "NAFO SCR Doc. 21/031, Table 21, p. 28",
    "NAFO SCR Doc. 21/031, pp. 4-5; NAFO SCR Doc. 22/039, exploratory"
  ),
  notes = c(
    rep("", 3),
    "Table 20 reports standard errors for the survivor parameters. These are not standard errors for the separately reported bias-adjusted population numbers.",
    "Table 20 reports catchability estimates and standard errors in linear scale.",
    "Fixed value, not an estimated output.",
    "The age-12 F constraint applies for 1959-1993 as described in the report.",
    "No age-13 plus group is included.",
    "Catch errors were not estimated in the reported formulation.",
    "Survey residuals are evaluated on the log scale with equal weighting.",
    "These are the age/year cells used by the published ADAPT formulation; the source tables report additional ages and/or years.",
    "Survey means are reported as numbers per tow; preserve the separate survey series.",
    "Do not collapse seasonal survey date ranges to a common scalar.",
    "The source describes maturity processing and imputations; the imported yearly ogives are the source table values.",
    "Table 5 catch weights and Table 23 beginning-of-year stock weights are stored separately.",
    "The 2020 population estimates are not based on a 2020 catch-at-age input.",
    "The exploratory 2022 model and 2025 monitoring report are cached separately and are not mixed into the 2021 production assessment."
  ),
  stringsAsFactors = FALSE
)
stock_new <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "NAFO",
  authority_stock_id = "cod.3NO",
  scientific_name = "Gadus morhua",
  common_name = "Cod in Divisions 3NO",
  area = "NAFO Divisions 3N and 3O",
  region = "Grand Bank",
  ocean = "Northwest Atlantic",
  notes = "Distinct NAFO Atlantic cod assessment unit in Divisions 3NO; no duplicate DFO record was identified.",
  stringsAsFactors = FALSE
)

assessment_new <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2021L,
  terminal_year = 2019L,
  estimate_terminal_year = 2020L,
  assessment_type = "full_assessment",
  model_family = "ADAPT",
  model_version = "ADAPT (software version not reported)",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = NA_integer_,
  assessment_url = "https://www.nafo.int/Portals/0/PDFs/sc/2021/scr21-031.pdf",
  framework_url = "",
  data_url = "https://www.nafo.int/Portals/0/PDFs/sc/2021/scr21-031.pdf",
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "complete",
  outputs_status = "partial",
  notes = "Latest detailed full production ADAPT assessment located; inputs end in 2019 and population estimates extend through 2020. The 2022 state-space assessment paper was exploratory, and later monitoring/advice does not provide a replacement full production assessment. Raster tables were digitized cell by cell. No native fitted object or production code was located."
)

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
  qmethod = "double")

replace_status_bytes <- function(path, candidate_id, old_status, new_status) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  line_starts <- c(1L, which(bytes == as.raw(10)) + 1L)
  line_ends <- c(which(bytes == as.raw(10)) - 1L, length(bytes))
  prefix <- charToRaw(paste0("\"", candidate_id, "\",\""))
  target <- which(vapply(seq_along(line_starts), function(i) {
    start <- line_starts[[i]]
    end <- line_ends[[i]]
    end - start + 1L >= length(prefix) &&
      identical(bytes[start:(start + length(prefix) - 1L)], prefix)
  }, logical(1)))
  if (length(target) != 1L) stop("Could not uniquely locate candidate row.", call. = FALSE)
  start <- line_starts[[target]]
  end <- line_ends[[target]]
  if (bytes[[end]] == as.raw(13)) end <- end - 1L
  line <- bytes[start:end]
  old <- charToRaw(paste0(",\"", old_status, "\",\""))
  first_byte <- which(line == old[[1L]])
  matches <- first_byte[vapply(first_byte, function(i) {
    i + length(old) - 1L <= length(line) &&
      identical(line[i:(i + length(old) - 1L)], old)
  }, logical(1))]
  if (length(matches) != 1L) stop("Could not uniquely locate candidate import status.", call. = FALSE)
  i <- matches[[1L]]
  new <- charToRaw(paste0(",\"", new_status, "\",\""))
  updated_line <- c(line[seq_len(i - 1L)], new,
    if (i + length(old) <= length(line)) line[(i + length(old)):length(line)] else raw())
  suffix_start <- if (bytes[[line_ends[[target]]]] == as.raw(13)) {
    line_ends[[target]]
  } else {
    line_ends[[target]] + 1L
  }
  updated <- c(bytes[seq_len(start - 1L)], updated_line,
    bytes[seq.int(suffix_start, length(bytes))])
  temp <- tempfile(pattern = "saio_candidate_status_")
  on.exit(unlink(temp), add = TRUE)
  connection <- file(temp, open = "wb")
  writeBin(updated, connection)
  close(connection)
  if (!file.copy(temp, path, overwrite = TRUE)) stop("Could not update candidate status.", call. = FALSE)
}

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates <- read_csv(candidate_path)

if (!dry_run && (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id)) {
  stop("Stock or assessment already exists; inspect canonical records before importing.", call. = FALSE)
}
candidate_row <- which(candidates$candidate_id == "NAFO:cod.3NO")
if (length(candidate_row) != 1L ||
  candidates$candidate_unit_id[candidate_row] != stock_id ||
  (!dry_run && candidates$import_status[candidate_row] != "not_started")) {
  stop("Expected one unworked NAFO 3NO cod candidate row.", call. = FALSE)
}
if (nrow(assumptions_new) != 17L || nrow(inputs_new) != 3224L ||
  nrow(outputs_new) != 3026L) {
  stop("Unexpected extraction row counts; no canonical files were changed.", call. = FALSE)
}

if (dry_run) {
  message("Dry run only: ", nrow(inputs_new), " inputs, ",
    nrow(assumptions_new), " assumptions, and ", nrow(outputs_new), " outputs.")
  message("Digitized input rows: ", sum(inputs_new$source_type == "digitized"))
  message("Digitized output rows: ", sum(outputs_new$source_type == "digitized"))
  message("Table 20 survivor and catchability estimates: ", nrow(survivors) + nrow(catchabilities))
  quit(save = "no", status = 0L)
}

has_assessment <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection), add = TRUE)
  prefix <- paste0("\"", id, "\",\"")
  repeat {
    lines <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
if (has_assessment(inputs_path, assessment_id) || has_assessment(outputs_path, assessment_id)) {
  stop("Assessment rows already exist; inspect before importing.", call. = FALSE)
}

append_csv(stock_new, stocks_path)
append_csv(assessment_new, assessments_path)
append_csv(assumptions_new, assumptions_path)
append_csv(inputs_new, inputs_path)
append_csv(outputs_new, outputs_path)
replace_status_bytes(candidate_path, "NAFO:cod.3NO", "not_started", "partial")

message("Imported ", assessment_id, ": ", nrow(inputs_new), " inputs, ",
  nrow(assumptions_new), " assumptions, and ", nrow(outputs_new), " outputs.")
