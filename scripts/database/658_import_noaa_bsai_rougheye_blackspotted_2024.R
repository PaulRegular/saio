import_noaa_bsai_rougheye_blackspotted_2024 <- function(root = ".", write = FALSE) {
  assessment_id <- "noaa_bsai_rougheye_blackspotted_2024"
  stock_id <- "noaa_bsai_rougheye_blackspotted"
  candidate_id <- "NOAA:11382"
  cache <- file.path(root, "source_cache/discovery_noaa_bsai_rougheye_2024")
  manifest_path <- file.path(cache, "sources.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
    check.names = FALSE)
  sha256_file <- function(path) {
    out <- system2("certutil.exe", c("-hashfile", shQuote(normalizePath(path,
      winslash = "\\", mustWork = TRUE)), "SHA256"), stdout = TRUE)
    tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
      out, value = TRUE)))
  }
  report_name <- "BSAIrougheye_2024.pdf"
  report <- file.path(cache, report_name)
  source_record <- manifest[manifest$file == report_name, , drop = FALSE]
  if (nrow(source_record) != 1L || !file.exists(report) ||
      as.numeric(source_record$bytes) != file.info(report)$size ||
      !identical(sha256_file(report), tolower(source_record$sha256))) {
    stop("Cached BSAI rougheye source failed its provenance check.",
      call. = FALSE)
  }
  text_path <- paste0(report, ".txt")
  if (!file.exists(text_path)) {
    lib <- file.path(root, "source_cache/.Rlib")
    if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
    if (!requireNamespace("pdftools", quietly = TRUE)) {
      stop("pdftools is needed to extract the cached BSAI assessment report.",
        call. = FALSE)
    }
    writeLines(pdftools::pdf_text(report), text_path, useBytes = TRUE)
  }
  lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")
  .libPaths(c(file.path(root, "source_cache/.Rlib"), .libPaths()))
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("pdftools is needed to read the report's tabular values.",
      call. = FALSE)
  }
  pdf_pages <- pdftools::pdf_text(report)
  pdf_data <- pdftools::pdf_data(report)
  page_for <- function(pattern) {
    page <- which(grepl(pattern, pdf_pages, fixed = TRUE))
    if (length(page) != 1L) {
      stop("Could not uniquely locate PDF table: ", pattern, call. = FALSE)
    }
    page
  }
  words_for <- function(pattern) {
    as.data.frame(pdf_data[[page_for(pattern)]], stringsAsFactors = FALSE)
  }
  ref <- function(table, page) paste0(
    "2024 BSAI Blackspotted and Rougheye SAFE, Table ", table,
    ", PDF p. ", page)
  table_section <- function(pattern) {
    start <- grep(pattern, lines, perl = TRUE)
    if (length(start) != 1L) stop("Could not locate report section: ",
      pattern, call. = FALSE)
    later_tables <- grep("^\\s*Table 14\\.[0-9]+\\.",
      lines[seq.int(start + 1L, length(lines))], perl = TRUE)
    end <- if (length(later_tables)) start + later_tables[1L] - 1L else
      length(lines)
    lines[seq.int(start, end)]
  }
  number_tokens <- function(x) {
    token <- regmatches(x, gregexpr(
      "(?<![[:alnum:]])-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?",
      x, perl = TRUE))[[1L]]
    as.numeric(gsub(",", "", token, fixed = TRUE))
  }
  row_token <- function(x, pattern) {
    match <- regexec(pattern, x, perl = TRUE)
    part <- regmatches(x, match)[[1L]]
    if (!length(part)) return(NULL)
    part
  }

  input_path <- file.path(root, "database/inputs.csv")
  output_path <- file.path(root, "database/outputs.csv")
  assumption_path <- file.path(root, "database/assumptions.csv")
  input_fields <- names(read.csv(text = readLines(input_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  output_fields <- names(read.csv(text = readLines(output_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  assumption_fields <- names(read.csv(text = readLines(assumption_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  make_rows <- function(fields, values, n = NULL) {
    if (is.null(n)) n <- max(c(1L, lengths(values)))
    out <- lapply(fields, function(field) {
      value <- values[[field]]
      if (is.null(value)) return(rep("", n))
      if (length(value) == 1L) return(rep(value, n))
      if (length(value) != n) stop("Wrong row count for ", field, ".",
        call. = FALSE)
      value
    })
    names(out) <- fields
    as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
  }
  input_rows <- list()
  output_rows <- list()
  assumption_rows <- list()
  add_input <- function(values, n = NULL) {
    input_rows[[length(input_rows) + 1L]] <<- make_rows(input_fields,
      values, n)
  }
  add_output <- function(values, n = NULL) {
    output_rows[[length(output_rows) + 1L]] <<- make_rows(output_fields,
      values, n)
  }
  add_assumption <- function(component, setting, value, source_reference,
    notes = "", fleet = "", survey = "", region = "Aleutian Islands") {
    assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(
      assumption_fields, list(assessment_id = assessment_id,
        component = component, setting = setting, value = value,
        source_reference = source_reference, notes = notes, fleet = fleet,
        survey = survey, region = region), 1L)
  }
  input_base <- function(type, measure, basis, value, unit, year = NA_real_,
    age = NA_real_, fleet = "", survey = "", sex = "combined",
    region = "Aleutian Islands", sampling_time = NA_real_,
    observation_id = "", length_bin = NA_real_, sample_size = NA_real_,
    notes = "", source_reference = "", source_type = "official_table") {
    list(assessment_id = assessment_id, type = type, measure = measure,
      basis = basis, value = value, unit = unit, year = year,
      year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
      fleet = fleet, survey = survey, sex = sex, region = region,
      sampling_time = sampling_time, source_type = source_type,
      source_reference = source_reference, notes = notes,
      observation_id = observation_id, length_bin = length_bin,
      length_bin_lower = NA_real_, length_bin_upper = NA_real_,
      sample_size = sample_size, age_error = NA_real_, partition = "",
      weight_bin = "")
  }
  output_base <- function(type, measure, value, unit, year = NA_real_,
    age = NA_real_, age_group = "", scenario = "", se = NA_real_,
    notes = "", source_reference = "", region = "Aleutian Islands",
    sex = "combined", source_type = "official_table", fleet = "",
    survey = "") {
    list(assessment_id = assessment_id, type = type, measure = measure,
      fleet = fleet, survey = survey, value = value, unit = unit,
      year = year, age = age,
      age_group = age_group, scenario = scenario, se = se, lwr = NA_real_,
      upr = NA_real_, region = region, sex = sex, source_type = source_type,
      source_reference = source_reference, notes = notes)
  }
  bind_rows <- function(x) {
    if (!length(x)) return(data.frame())
    out <- do.call(rbind, x)
    rownames(out) <- NULL
    out
  }

  catch_words <- words_for(
    "Table 14.3. Catch of blackspotted and rougheye rockfish")
  catch_columns <- list(
    list(name = "Eastern Bering Sea", fleet = "Foreign", lower = 110, upper = 160),
    list(name = "Eastern Bering Sea", fleet = "Joint venture", lower = 160, upper = 190),
    list(name = "Eastern Bering Sea", fleet = "Domestic", lower = 190, upper = 265),
    list(name = "Aleutian Islands", fleet = "Foreign", lower = 265, upper = 315),
    list(name = "Aleutian Islands", fleet = "Joint venture", lower = 315, upper = 340),
    list(name = "Aleutian Islands", fleet = "Domestic", lower = 340, upper = 405),
    list(name = "Bering Sea / Aleutian Islands", fleet = "BSAI total", lower = 405, upper = 480)
  )
  catch_y <- sort(unique(catch_words$y[catch_words$y > 125 & catch_words$y < 680]))
  catch_years <- integer()
  for (y in catch_y) {
    row <- catch_words[catch_words$y == y, , drop = FALSE]
    yi <- which(row$x < 110 & grepl("^(19|20)[0-9]{2}$", row$text))
    if (length(yi) != 1L) next
    year <- as.integer(row$text[yi])
    catch_years <- c(catch_years, year)
    for (column in catch_columns) {
      cell <- row[row$x >= column$lower & row$x < column$upper, , drop = FALSE]
      value_i <- which(grepl("^[0-9][0-9,]*$", cell$text))
      if (!length(value_i)) next
      value <- as.numeric(gsub(",", "", cell$text[value_i[1L]], fixed = TRUE))
      add_input(input_base("catch", "catch_biomass", "biomass", value,
        "metric tons", year = year, fleet = column$fleet,
        region = column$name,
        source_reference = ref("14.3", "37"),
        observation_id = paste("catch", year, column$name, column$fleet,
          sep = "_"),
        notes = "Annual species-group catch reported in metric tons. The 2024 value is an estimate through October 5, 2024. Table 14.3 preserves distinct EBS/AI reporting sectors and the BSAI total; total and component rows are not additive observations."), 1L)
    }
  }
  if (!identical(sort(unique(catch_years)), 1977:2024)) {
    stop("Table 14.3 did not yield all 1977-2024 catch years.", call. = FALSE)
  }

  area_section <- table_section("^\\s*Table 14\\.4\\. Area-specific catches")
  area_rows <- list()
  for (line in area_section) {
    hit <- row_token(line, "^\\s*((?:19|20)[0-9]{2})\\*?\\s+(.*)$")
    if (is.null(hit)) next
    values <- number_tokens(hit[3L])
    if (length(values) != 5L) stop("Unexpected Table 14.4 row.",
      call. = FALSE)
    area_rows[[length(area_rows) + 1L]] <- data.frame(
      year = as.integer(hit[2L]), value = values[1:4],
      region = c("Western Aleutian Islands", "Central Aleutian Islands",
        "Eastern Aleutian Islands", "Eastern Bering Sea"),
      stringsAsFactors = FALSE)
  }
  area_catches <- do.call(rbind, area_rows)
  if (nrow(area_catches) != 31L * 4L ||
      !identical(sort(unique(area_catches$year)), 1994:2024)) {
    stop("Unexpected Table 14.4 subarea catch coverage.", call. = FALSE)
  }
  for (i in seq_len(nrow(area_catches))) {
    x <- area_catches[i, ]
    add_input(input_base("catch", "catch_biomass", "biomass", x$value,
      "metric tons", year = x$year, fleet = "Observer Program area catch",
      region = x$region, observation_id = paste("area_catch", x$year,
        gsub(" ", "_", x$region), sep = "_"),
      source_reference = ref("14.4", "39"),
      notes = "Area-specific observer-program catch supporting spatial catch reporting; these four area records and the Table 14.4 BSAI total are not separate age-model catch likelihoods. The 2024 values are estimates through October 5, 2024."), 1L)
  }

  matrix_table <- function(table_number, title, row_label) {
    block <- table_section(paste0("^\\s*Table 14\\.", table_number,
      "\\. ", title))
    header_i <- which(grepl("(?i)^\\s*(Age|Length)", block, perl = TRUE) &
      grepl("(19|20)[0-9]{2}", block))
    if (length(header_i) != 1L) stop("Could not find matrix years in Table 14.",
      table_number, ".", call. = FALSE)
    years <- as.integer(regmatches(block[header_i], gregexpr(
      "(19|20)[0-9]{2}", block[header_i], perl = TRUE))[[1L]])
    rows <- list()
    for (line in block[seq.int(header_i + 1L, length(block))]) {
      hit <- row_token(line, "^\\s*(\\d+\\+?)\\s+(.*)$")
      if (is.null(hit)) next
      value <- number_tokens(hit[3L])
      if (length(value) != length(years)) {
        stop("Table 14.", table_number, " row ", hit[2L],
          " has an unexpected number of cells.", call. = FALSE)
      }
      rows[[length(rows) + 1L]] <- data.frame(
        label = hit[2L], value = value, year = years,
        stringsAsFactors = FALSE)
    }
    result <- do.call(rbind, rows)
    expected_rows <- if (row_label == "age") 43L else 39L
    if (length(rows) != expected_rows) stop("Unexpected number of rows in Table 14.",
      table_number, ": found ", length(rows), ".", call. = FALSE)
    result$bin <- as.numeric(sub("\\+$", "", result$label))
    result$plus_group <- grepl("\\+$", result$label)
    result
  }
  composition_specs <- list(
    list(table = 12L, title = "Fishery length compositions used in the model,",
      bin = "length", type = "catch", measure = "proportion_at_length",
      fleet = "BSAI fishery observer samples", survey = "",
      region = "Bering Sea / Aleutian Islands",
      reference = ref("14.12", "47"),
      note = "Rounded source proportions from NORPAC foreign and domestic observer length samples; values are not renormalized.",
      sample = c(`1979`=225, `1990`=49, `1992`=68, `1993`=41, `2003`=118,
        `2010`=421, `2012`=212, `2014`=306, `2016`=187, `2018`=365,
        `2022`=880)),
    list(table = 13L, title = "Fishery age compositions used in the model,",
      bin = "age", type = "catch", measure = "proportion_at_age",
      fleet = "BSAI fishery observer samples", survey = "",
      region = "Bering Sea / Aleutian Islands",
      reference = ref("14.13", "48"),
      note = "Rounded source proportions from NORPAC domestic observer age samples; age 45 represents the source 45+ group. Haul counts are the first-stage sample sizes described by the report; proportions are not renormalized.",
      sample = c(`2004`=101, `2005`=88, `2007`=93, `2008`=87,
        `2009`=96, `2011`=97, `2013`=193, `2015`=173, `2017`=168,
        `2019`=385, `2020`=291, `2021`=495, `2023`=577)),
    list(table = 17L, title = "AI survey age compositions used in the model.",
      bin = "age", type = "index", measure = "proportion_at_age",
      fleet = "", survey = "Aleutian Islands trawl survey",
      region = "Aleutian Islands",
      reference = ref("14.17", "52"),
      note = "Rounded source proportions from AI survey otolith samples; age 45 represents the source 45+ group. Haul counts are the first-stage sample sizes described by the report; proportions are not renormalized.",
      sample = c(`1991`=29, `1994`=68, `1997`=92, `2000`=87,
        `2002`=81, `2004`=97, `2006`=89, `2010`=76, `2012`=99,
        `2014`=82, `2016`=97, `2018`=96, `2022`=133))
  )
  for (spec in composition_specs) {
    matrix <- matrix_table(spec$table, spec$title, spec$bin)
    if (!setequal(unique(matrix$year), as.integer(names(spec$sample)))) {
      stop("Composition years do not match the documented haul counts for Table 14.",
        spec$table, ".", call. = FALSE)
    }
    sums <- tapply(matrix$value, matrix$year, sum)
    if (any(abs(sums - 1) > 0.01)) stop("Rounded composition does not sum near one in Table 14.",
      spec$table, ".", call. = FALSE)
    for (i in seq_len(nrow(matrix))) {
      x <- matrix[i, ]
      sample_size <- unname(spec$sample[as.character(x$year)])
      plus_note <- if (x$plus_group) " The final category is a plus group." else ""
      add_input(input_base(spec$type, spec$measure, "proportion_numbers",
        x$value, "proportion", year = x$year,
        age = if (spec$bin == "age") x$bin else NA_real_,
        length_bin = if (spec$bin == "length") x$bin else NA_real_,
        fleet = spec$fleet, survey = spec$survey, region = spec$region,
        sample_size = sample_size,
        observation_id = paste0("table14_", spec$table, "_", x$year),
        source_reference = spec$reference,
        notes = paste0(spec$note, plus_note)), 1L)
    }
  }

  survey_length <- c(0, 0, 0, .001, 0, 0, .002, .005, .005, .003,
    .006, .008, .018, .014, .023, .030, .033, .029, .036, .029, .036,
    .040, .042, .064, .074, .082, .055, .068, .088, .066, .048, .027,
    .026, .010, .008, .007, .005, .003, .008)
  if (length(survey_length) != 39L || abs(sum(survey_length) - 1) > 0.01) {
    stop("Unexpected Table 14.18 survey length composition.", call. = FALSE)
  }
  for (i in seq_along(survey_length)) {
    bin <- if (i == 39L) 50 else i + 11L
    plus_note <- if (i == 39L) " The source 50+ length group is stored at its lower bound." else ""
    add_input(input_base("index", "proportion_at_length", "proportion_numbers",
      survey_length[i], "proportion", year = 2024,
      length_bin = bin, survey = "Aleutian Islands trawl survey",
      region = "Aleutian Islands",
      observation_id = "table14_18_2024",
      source_reference = ref("14.18", "53"),
      notes = paste0("Transcribed from the raster-only table in the official PDF. Rounded source proportions are not renormalized; the report does not specify a composition likelihood sample size, so sample_size is left blank.", plus_note)), 1L)
  }

  survey_words <- words_for(
    "Table 14.14. Estimated biomass (t) of blackspotted/rougheye rockfish")
  survey_regions <- list(
    list(name = "Western Aleutian Islands", lower = 110, upper = 180,
      survey = "Aleutian Islands trawl survey"),
    list(name = "Central Aleutian Islands", lower = 180, upper = 240,
      survey = "Aleutian Islands trawl survey"),
    list(name = "Eastern Aleutian Islands", lower = 240, upper = 300,
      survey = "Aleutian Islands trawl survey"),
    list(name = "Southern Bering Sea", lower = 300, upper = 360,
      survey = "Aleutian Islands trawl survey"),
    list(name = "Aleutian Islands total", lower = 360, upper = 480,
      survey = "Aleutian Islands trawl survey"),
    list(name = "Eastern Bering Sea slope", lower = 480, upper = 560,
      survey = "Eastern Bering Sea slope trawl survey")
  )
  survey_records <- list()
  survey_y <- sort(unique(survey_words$y[survey_words$y > 145 &
    survey_words$y < 450]))
  for (y in survey_y) {
    row <- survey_words[survey_words$y == y, , drop = FALSE]
    yi <- which(row$x < 110 & grepl("^(19|20)[0-9]{2}$", row$text))
    if (length(yi) != 1L) next
    year <- as.integer(row$text[yi])
    for (region in survey_regions) {
      cell <- row[row$x >= region$lower & row$x < region$upper, , drop = FALSE]
      vi <- which(grepl("^[0-9][0-9,]*$", cell$text))
      ci <- which(grepl("^\\(0?\\.[0-9]+\\)$", cell$text))
      if (!length(vi)) next
      value <- as.numeric(gsub(",", "", cell$text[vi[1L]], fixed = TRUE))
      cv <- if (length(ci)) as.numeric(gsub("[()]", "",
        cell$text[ci[1L]])) else NA_real_
      survey_records[[length(survey_records) + 1L]] <- data.frame(
        year = year, region = region$name, survey = region$survey,
        value = value, cv = cv, stringsAsFactors = FALSE)
    }
  }
  survey_index <- do.call(rbind, survey_records)
  ai_total_years <- c(1991, 1994, 1997, 2000, 2002, 2004, 2006,
    2010, 2012, 2014, 2016, 2018, 2022, 2024)
  if (sum(survey_index$region == "Aleutian Islands total") != 14L ||
      !setequal(survey_index$year[survey_index$region == "Aleutian Islands total"],
        ai_total_years) ||
      !all(is.finite(survey_index$cv))) {
    stop("Unexpected Table 14.14 survey biomass coverage: ", nrow(survey_index),
      " rows; AI total years ", paste(survey_index$year[
        survey_index$region == "Aleutian Islands total"], collapse = ","),
      "; missing CVs ", sum(!is.finite(survey_index$cv)), ".", call. = FALSE)
  }
  for (i in seq_len(nrow(survey_index))) {
    x <- survey_index[i, ]
    survey_id <- paste0("survey_biomass_", x$year, "_",
      gsub("[^A-Za-z0-9]+", "_", x$region))
    notes <- "Source-reported trawl-survey biomass estimate and CV; the index is not an absolute population biomass estimate. Aleutian subareas are components of the total survey estimate, not independent total-index series."
    if (x$region == "Aleutian Islands total" && x$year == 2016) {
      notes <- paste(notes, "Table 14.14 reports 2016, while the report's data-summary list omits it; likelihood inclusion is unresolved.")
    }
    if (x$region == "Eastern Bering Sea slope") {
      notes <- paste(notes, "This EBS series belongs to the separate Tier 5 random-effects component, not the Aleutian Islands age-structured model.")
    }
    add_input(input_base("index", "relative_biomass_index", "index_scale",
      x$value, "metric tons (survey biomass scale)", year = x$year,
      survey = x$survey, region = x$region, observation_id = survey_id,
      source_reference = ref("14.14", "49"), notes = notes), 1L)
    add_input(input_base("index", "biomass_index_cv", "relative_scale",
      x$cv, "ratio", year = x$year, survey = x$survey,
      region = x$region, observation_id = survey_id,
      source_reference = ref("14.14", "49"),
      notes = "Coefficient of variation reported in parentheses in Table 14.14; retained separately from the biomass index."), 1L)
  }

  biological <- table_section("^\\s*Table 14\\.19\\. Predicted weight")
  biological_rows <- list()
  for (line in biological) {
    hit <- row_token(line, "^\\s*(\\d+\\+?)\\s+(.*)$")
    if (is.null(hit)) next
    values <- number_tokens(hit[3L])
    if (length(values) != 2L) next
    biological_rows[[length(biological_rows) + 1L]] <- data.frame(
      label = hit[2L], age = as.numeric(sub("\\+$", "", hit[2L])),
      plus_group = grepl("\\+$", hit[2L]), weight_g = values[1L],
      maturity = values[2L], stringsAsFactors = FALSE)
  }
  biological <- do.call(rbind, biological_rows)
  if (nrow(biological) != 43L ||
      !identical(as.integer(biological$age), 3:45) ||
      any(biological$maturity < 0 | biological$maturity > 1)) {
    stop("Unexpected Table 14.19 biological surface.", call. = FALSE)
  }
  for (i in seq_len(nrow(biological))) {
    x <- biological[i, ]
    note <- if (x$plus_group) "The source category is 45+; age stores its lower bound." else ""
    add_input(input_base("weight", "weight_at_age", "g_per_fish",
      x$weight_g, "g per fish", age = x$age,
      source_reference = ref("14.19", "54"),
      notes = paste("Population weight-at-age estimated outside the population model from AI survey growth and length-weight relationships; source values are retained in grams.", note)), 1L)
    add_output(output_base("biology", "maturity_at_age", x$maturity,
      "proportion", age = x$age,
      age_group = if (x$plus_group) "45+" else "",
      source_reference = ref("14.19", "54"),
      notes = paste("Predicted maturity-at-age from the assessment's estimated curve; not an external maturity input.", note)), 1L)
  }

  numbers_from_panel <- function(start_pattern, end_pattern, ages) {
    start <- grep(start_pattern, lines, perl = TRUE)
    end <- grep(end_pattern, lines, perl = TRUE)
    if (length(start) != 1L || length(end) != 1L || start >= end) {
      stop("Could not locate Table 14.26 panel.", call. = FALSE)
    }
    block <- lines[seq.int(start + 1L, end - 1L)]
    rows <- list()
    for (line in block) {
      hit <- row_token(line, "^\\s*((?:19|20)[0-9]{2})\\s+(.*)$")
      if (is.null(hit)) next
      values <- number_tokens(hit[3L])
      if (length(values) != length(ages)) {
        stop("Unexpected Table 14.26 row for year ", hit[2L], ".",
          call. = FALSE)
      }
      rows[[length(rows) + 1L]] <- data.frame(year = as.integer(hit[2L]),
        age = ages, value = values, stringsAsFactors = FALSE)
    }
    result <- do.call(rbind, rows)
    if (nrow(result) != 48L * length(ages) ||
        !identical(sort(unique(result$year)), 1977:2024)) {
      stop("Unexpected Table 14.26 year coverage.", call. = FALSE)
    }
    result
  }
  n_age_early <- numbers_from_panel(
    "^\\s*Table 14\\.26\\. Estimated numbers at age",
    "^\\s*Table 14\\.26 \\(continued\\)", 3:22)
  n_age_late <- numbers_from_panel(
    "^\\s*Table 14\\.26 \\(continued\\)",
    "^\\s*Table 14\\.27\\.", c(23:44, 45))
  numbers_at_age <- rbind(n_age_early, n_age_late)
  if (nrow(numbers_at_age) != 48L * 43L ||
      any(numbers_at_age$value < 0)) {
    stop("Unexpected Table 14.26 numbers-at-age surface.", call. = FALSE)
  }
  for (i in seq_len(nrow(numbers_at_age))) {
    x <- numbers_at_age[i, ]
    add_output(output_base("population", "numbers_at_age", x$value,
      "millions of fish", year = x$year, age = x$age,
      age_group = if (x$age == 45) "45+" else "",
      source_reference = ref("14.26", if (x$age <= 22) "62" else "63"),
      notes = if (x$age == 45) "The 45+ value is the plus-group accumulator." else "Point estimate; Table 14.26 does not report age-specific uncertainty."), 1L)
  }
  total_numbers <- aggregate(value ~ year, numbers_at_age, sum)
  for (i in seq_len(nrow(total_numbers))) {
    x <- total_numbers[i, ]
    add_output(output_base("population", "total_numbers", x$value,
      "millions of fish", year = x$year,
      source_type = "derived_source_output",
      source_reference = ref("14.26", "62-63"),
      notes = "Derived as the sum of reported AI numbers-at-age for ages 3-44 and the 45+ accumulator. No joint uncertainty is published."), 1L)
  }

  biomass_words <- words_for(
    "Table 14.25. Estimated time series of AI blackspotted/rougheye total biomass")
  biomass_y <- sort(unique(biomass_words$y[biomass_words$y > 150 &
    biomass_words$y < 700]))
  biomass_records <- list()
  for (y in biomass_y) {
    row <- biomass_words[biomass_words$y == y, , drop = FALSE]
    yi <- which(row$x < 110 & grepl("^(19|20)[0-9]{2}$", row$text))
    if (length(yi) != 1L) next
    year <- as.integer(row$text[yi])
    if (!year %in% 1977:2025) next
    cells <- list(
      total_biomass = c(120, 155, 155, 185),
      SSB = c(265, 300, 300, 330),
      recruitment = c(420, 450, 450, 480)
    )
    record <- list(year = year)
    for (metric in names(cells)) {
      bounds <- cells[[metric]]
      value_token <- row$text[row$x >= bounds[1L] & row$x < bounds[2L] &
        grepl("^[0-9][0-9,]*$", row$text)]
      cv_token <- row$text[row$x >= bounds[3L] & row$x < bounds[4L] &
        grepl("^0\\.[0-9]+$", row$text)]
      record[[paste0(metric, "_value")]] <- if (length(value_token))
        as.numeric(gsub(",", "", value_token[1L], fixed = TRUE)) else NA_real_
      record[[paste0(metric, "_cv")]] <- if (length(cv_token))
        as.numeric(cv_token[1L]) else NA_real_
    }
    biomass_records[[length(biomass_records) + 1L]] <-
      as.data.frame(record, stringsAsFactors = FALSE)
  }
  biomass_series <- do.call(rbind, biomass_records)
  if (nrow(biomass_series) != 49L ||
      !identical(sort(biomass_series$year), 1977:2025) ||
      !isTRUE(all.equal(biomass_series$total_biomass_value[biomass_series$year == 2024], 27665)) ||
      !isTRUE(all.equal(biomass_series$SSB_value[biomass_series$year == 2024], 3554))) {
    stop("Unexpected Table 14.25 model-output series.", call. = FALSE)
  }
  for (metric in c("total_biomass", "SSB", "recruitment")) {
    for (i in seq_len(nrow(biomass_series))) {
      x <- biomass_series[i, ]
      value <- x[[paste0(metric, "_value")]]
      if (is.na(value)) next
      cv <- x[[paste0(metric, "_cv")]]
      se <- if (is.na(cv)) NA_real_ else value * cv
      unit <- if (metric == "recruitment") "thousand fish" else "metric tons"
      age <- if (metric == "recruitment") 3 else NA_real_
      scenario <- if (x$year > 2024) "forecast" else ""
      note <- if (is.na(cv)) {
        "Official 2025 forecast point estimate; Table 14.25 does not report a CV for this row."
      } else {
        paste0("Hessian-approximation CV reported by source: ", format(cv,
          trim = TRUE), ". Natural-scale SE is calculated as estimate x CV.")
      }
      add_output(output_base(if (metric == "SSB") "biomass" else
        if (metric == "recruitment") "recruitment" else "biomass",
        metric, value, unit, year = x$year, age = age, scenario = scenario,
        se = se, source_reference = ref("14.25", "61"), notes = note), 1L)
    }
  }

  parameter_lines <- table_section(
    "^\\s*Table 14\\.23\\. Estimated parameter values")
  m_line <- grep("^\\s*M\\s+", parameter_lines, value = TRUE, perl = TRUE)
  q_line <- grep("q_ai_srv", parameter_lines, value = TRUE, fixed = TRUE)
  if (length(m_line) != 1L || length(q_line) != 1L) {
    stop("Could not read M and survey q from Table 14.23.", call. = FALSE)
  }
  m_values <- number_tokens(sub("^\\s*M\\s+", "", m_line, perl = TRUE))
  q_values <- number_tokens(sub("^.*q_ai_srv\\s+", "", q_line, perl = TRUE))
  if (length(m_values) < 2L || length(q_values) < 2L) {
    stop("Could not read M and survey q estimates from Table 14.23.",
      call. = FALSE)
  }
  add_output(output_base("mortality", "natural_mortality_average_parameter",
    m_values[1L], "per year", se = NA_real_, source_reference = ref("14.23", "59"),
    notes = "Scalar M estimate. The source standard deviation is rounded to 0.00; no zero uncertainty is inferred."), 1L)
  add_output(output_base("catchability", "q", q_values[1L], "dimensionless",
    se = q_values[2L], survey = "Aleutian Islands trawl survey",
    source_reference = ref("14.23", "59"),
    notes = "Estimated AI trawl-survey catchability and source-reported standard deviation on the parameter scale."), 1L)
  for (parameter in c("mat_beta1", "mat_beta2")) {
    parameter_line <- grep(parameter, parameter_lines, value = TRUE, fixed = TRUE)
    if (length(parameter_line) != 1L) {
      stop("Could not read ", parameter, " from Table 14.23.", call. = FALSE)
    }
    parameter_values <- number_tokens(sub(paste0("^.*", parameter, "[[:space:]]+"),
      "", parameter_line))
    if (length(parameter_values) < 2L) {
      stop("Could not parse ", parameter, " from Table 14.23.", call. = FALSE)
    }
    add_output(output_base("biology", parameter, parameter_values[1L],
      "native model scale", se = parameter_values[2L],
      source_reference = ref("14.23", "59"),
      notes = "Source maturity-curve parameter and standard deviation are retained on the named model scale; no back-transformation is applied."), 1L)
  }

  add_assumption("population", "age_structure",
    "Aleutian Islands age-structured component, ages 3-45+; recruitment age 3; model years 1977-2024.",
    ref("14.20", "55"),
    "Age 45 is the accumulator plus group. The eastern Bering Sea component is assessed separately with a Tier 5 random-effects survey-biomass model.")
  add_assumption("population", "biomass_definitions",
    "Total biomass is ages 3+; SSB is mature female biomass ages 3+; recruitment is age-3 numbers.",
    "2024 BSAI SAFE, Table 14.25 and time-series definitions",
    "The age-structured model does not report sex-specific numbers-at-age.")
  add_assumption("population", "spawning_fraction",
    "0.17 of the year", ref("14.20", "55"),
    "Source spawning month expressed as a fraction of year.")
  add_assumption("recruitment", "recruitment_variability", "0.75",
    ref("14.20", "55"), "Specified recruitment variability parameter.")
  add_assumption("M", "natural_mortality_prior",
    "Lognormal prior with mean 0.045 per year and log-scale SD 0.05.",
    ref("14.20", "56"),
    "M is a scalar parameter, estimated in the assessment; Table 14.23 reports 0.05 with SD rounded to 0.00.")
  add_assumption("index", "survey_catchability_prior",
    "AI trawl survey q prior mean 1.0 and log-scale SD 0.05.",
    ref("14.20", "56"),
    "The report also describes the prior CV as 0.05; values are retained as stated.",
    survey = "Aleutian Islands trawl survey")
  add_assumption("likelihood", "likelihood_weights",
    "Catch 50; survey biomass index 1; fishing-mortality deviations 0.1.",
    ref("14.20", "56"),
    "Second-stage composition weights use McAllister-Ianelli weighting and are not reported as fixed constants.")
  add_assumption("likelihood", "composition_sample_sizes",
    "First-stage sample sizes are numbers of hauls for fishery length, fishery age and AI survey age compositions.",
    ref("14.20", "56"),
    "Haul counts from Tables 14.10, 14.11 and 14.16 are attached to the published composition rows; no effective sample size is inferred.")
  add_assumption("biology", "weight_at_age",
    "Population weight-at-age derived from AI survey growth and length-weight relationship.",
    "2024 BSAI SAFE, section 'Parameters Estimated Outside the Assessment Model' and Table 14.19",
    "Growth estimates: Linf=51.43 cm, K=0.06 per year, t0=-3.30 years. Length-weight relationship W=6.46e-6*L^3.24. Table 14.19 weights are reported in grams; the fishery weight vector is not separately tabulated.")
  add_assumption("biology", "maturity_at_age",
    "Maturity-at-age estimated within the age-structured model.",
    ref("14.23", "59"),
    "Table 14.19 reports the predicted maturity curve; its raw biological observations are not included in this import.")
  add_assumption("biology", "ageing_error",
    "Age-reading CV 0.121, estimated from 2,341 double readings collected during 1986-2017.",
    "2024 BSAI SAFE, section 'Parameters Estimated Outside the Assessment Model'",
    "The numerical age-error matrix is not published in the reviewed report.")
  add_assumption("biology", "age_length_conversion",
    "Age-length conversion matrix estimated from AI survey data.",
    "2024 BSAI SAFE, section 'Parameters Estimated Outside the Assessment Model'",
    "The numerical matrix is not tabulated; the source describes length-at-age CV declining from 0.19 at age 3 to 0.10 at age 45.")
  add_assumption("index", "survey_timing",
    "Fractional within-year timing not reported.", ref("14.14", "49"),
    "The report identifies survey year and index series but does not state an annual sampling-time fraction.")
  add_assumption("index", "2024_survey_length_sample",
    "2,280 fish lengths from 112 AI survey hauls.", ref("14.15", "50"),
    "These are source-reported sampling counts. Table 14.20 does not identify a corresponding likelihood sample-size field for the AI survey length composition, so no sample_size is assigned to its composition cells.",
    survey = "Aleutian Islands trawl survey")
  add_assumption("index", "survey_series_scope",
    "The age-structured model uses the Aleutian Islands survey biomass series; EBS slope biomass belongs to the separate Tier 5 component.",
    ref("14.14", "49"),
    "Table 14.14 includes area components and a total. The report's data summary omits the table's 2016 AI total row; its likelihood use remains unresolved.")

  inputs <- bind_rows(input_rows)
  outputs <- bind_rows(output_rows)
  assumptions <- bind_rows(assumption_rows)
  stocks_path <- file.path(root, "database/stocks.csv")
  assessments_path <- file.path(root, "database/assessments.csv")
  stocks <- read.csv(stocks_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv(assessments_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (any(stocks$stock_id == stock_id) ||
      any(stocks$authority_stock_id == "11382", na.rm = TRUE) ||
      any(assessments$assessment_id == assessment_id)) {
    stop("BSAI rougheye/blackspotted stock or assessment already exists; inspect before reimporting.",
      call. = FALSE)
  }
  stock_fields <- names(read.csv(text = readLines(stocks_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  assessment_fields <- names(read.csv(text = readLines(assessments_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  stock <- make_rows(stock_fields, list(stock_id = stock_id,
    charbonneau_id = "", authority = "NOAA Fisheries",
    authority_stock_id = "11382",
    scientific_name = "Sebastes aleutianus; Sebastes melanostictus",
    common_name = "Blackspotted and rougheye rockfish complex",
    area = "Bering Sea / Aleutian Islands", region = "BSAI",
    ocean = "Northeast Pacific",
    notes = "NOAA Stock SMART 11382. The 2024 SAFE's age-structured model covers the Aleutian Islands component; the eastern Bering Sea component uses a separate Tier 5 random-effects method."), 1L)
  assessment <- make_rows(assessment_fields, list(
    assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2024, terminal_year = 2024,
    estimate_terminal_year = 2025, assessment_type = "update",
    model_family = "AD Model Builder age-structured model",
    model_version = "2024 update using the accepted 2022 model structure",
    is_current = TRUE, is_applied = TRUE,
    assessment_url = source_record$url,
    assumptions_status = "partial", inputs_status = "partial",
    outputs_status = "partial",
    notes = paste("The December 2024 SAFE updates the accepted AI age-structured model with data through 2024 and reports a 2025 forecast. The EBS component is a separate Tier 5 random-effects assessment. Catch, rounded compositions, survey indices, population weight-at-age, maturity curve, M/q and biomass/SSB/N-at-age outputs are transcribed from report tables; recruitment is reported through 2018. Direct catch-at-age, fishery weight-at-age, numerical age-error and age-length matrices, and F-at-age are not published in the reviewed source. See discovery/source_reviews/noaa_bsai_blackspotted_rougheye_2024.md.")), 1L)

  cat("NOAA BSAI blackspotted/rougheye 2024 source extraction\n")
  cat("Inputs:", nrow(inputs), "rows (catches, survey indices, compositions and population weight-at-age).\n")
  cat("Outputs:", nrow(outputs), "rows (AI numbers-at-age, derived total abundance, biomass, SSB, recruitment, maturity and selected parameters).\n")
  cat("Direct catch-at-age and fitted F-at-age are not reported and are not fabricated.\n")
  if (!write) {
    cat("Dry run only. Add --write to append the reviewed source records.\n")
    return(list(stock = stock, assessment = assessment, assumptions = assumptions,
      inputs = inputs, outputs = outputs))
  }

  for (name in c("stocks", "assessments", "assumptions", "inputs", "outputs")) {
    path <- file.path(root, "database", paste0(name, ".csv"))
    expected <- names(read.csv(text = readLines(path, n = 1L, warn = FALSE),
      nrows = 0L, check.names = FALSE))
    rows <- switch(name, stocks = stock, assessments = assessment,
      assumptions = assumptions, inputs = inputs, outputs = outputs)
    if (!identical(names(rows), expected)) {
      stop("Import rows do not match database columns for ", name, ".",
        call. = FALSE)
    }
  }
  append_csv <- function(rows, path) {
    write.table(rows, file = path, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", quote = TRUE,
      qmethod = "double", eol = "\n")
  }
  append_csv(stock, stocks_path)
  append_csv(assessment, assessments_path)
  append_csv(assumptions, assumption_path)
  append_csv(inputs, input_path)
  append_csv(outputs, output_path)

  source(file.path(root, "scripts/database/candidate_register_io.R"),
    local = TRUE)
  candidate_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$eligibility[ci] != "eligible") {
    stop("Expected one eligible NOAA:11382 candidate.", call. = FALSE)
  }
  candidates$candidate_unit_id[ci] <- stock_id
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$detailed_source_url[ci] <- source_record$url
  candidates$review_date[ci] <- "2026-11-12"
  candidates$catch_age_evidence[ci] <- paste("Imported annual catch biomass by reporting area and fishery sector, plus rounded age compositions.", "The report does not provide catch-at-age numbers or fishery weight-at-age, so catch-at-age is not constructed.")
  candidates$survey_age_evidence[ci] <- paste("Imported AI survey age compositions, biomass estimates and CVs, including table-reported area components.", "EBS slope indices belong to the separate Tier 5 component; AI 2016 index inclusion in the model likelihood is unresolved.")
  candidates$weights_evidence[ci] <- paste("Imported the Table 14.19 population weight-at-age vector in grams.", "It is derived from AI survey growth; the distinct year-specific fishery weight vector is not published.")
  candidates$maturity_evidence[ci] <- paste("Imported the predicted maturity-at-age curve and reported maturity parameters.", "Raw biological samples and the full age-specific uncertainty surface are unavailable.")
  candidates$mortality_evidence[ci] <- "M is estimated as a scalar with a lognormal prior mean of 0.045 per year and log-scale SD 0.05; the reported estimate is 0.05 with its SD rounded to 0.00."
  candidates$timing_evidence[ci] <- "Spawning fraction is 0.17 of the year. Fractional within-year timing for survey observations is not specified."
  candidates$output_evidence[ci] <- paste("Imported AI numbers-at-age for ages 3-44 and 45+ for 1977-2024; Table 14.25 total biomass and SSB through 2024, 2025 total biomass/SSB forecasts, and age-3 recruitment through 2018.", "Aggregate Hessian CVs are converted to natural-scale SEs with estimate x CV and documented; numbers-at-age uncertainty and F-at-age are unavailable.")
  candidates$decision_reason[ci] <- paste("The December 2024 SAFE is the latest accepted production update located for NOAA:11382.", "It retains the accepted 2022 AI age-structured model with data updates; the EBS component remains Tier 5 and is not represented by an age-specific surface.")
  candidates$notes[ci] <- paste("Partial source import from the 2024 SAFE. Rounded composition proportions are retained as printed; source first-stage haul counts are recorded where the assessment identifies them.", "The raster-only 2024 AI survey length composition was visually transcribed. See discovery/source_reviews/noaa_bsai_blackspotted_rougheye_2024.md.")
  replace_candidate_register_row(candidate_path, ci,
    candidates[ci, , drop = FALSE], candidate_id)

  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ir <- candidate_inventory_row(inventory, candidate_id, stock_id)
  inventory$unit_key[ir] <- paste0("stock:", stock_id)
  inventory$candidate_unit_id[ir] <- stock_id
  inventory$matched_stock_id[ir] <- stock_id
  inventory$match_status[ir] <- "matched"
  inventory$import_status[ir] <- "partial"
  replace_csv_register_row(inventory_path, ir,
    inventory[ir, , drop = FALSE], "candidate_ids", inventory$candidate_ids[ir])

  batch_path <- file.path(root, "discovery/selected_batch_40_2026.csv")
  batch <- read.csv(batch_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  bi <- which(batch$candidate_id == candidate_id)
  if (length(bi) != 1L) stop("NOAA:11382 is not in the selected batch.",
    call. = FALSE)
  batch$curation_status[bi] <- "partial_source_import"
  replace_candidate_register_row(batch_path, bi,
    batch[bi, , drop = FALSE], candidate_id)

  provenance_dir <- file.path(root,
    "provenance/discovery_noaa_bsai_rougheye_2024")
  dir.create(provenance_dir, recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(manifest_path, file.path(provenance_dir, "sources.csv"),
      overwrite = TRUE)) stop("Could not write tracked source provenance.",
        call. = FALSE)
  cat("BSAI blackspotted/rougheye records appended; candidate status set to partial.\n")
  invisible(list(stock = stock, assessment = assessment,
    assumptions = assumptions, inputs = inputs, outputs = outputs))
}

if (!interactive() && sys.nframe() == 0L) {
  import_noaa_bsai_rougheye_blackspotted_2024(write =
    "--write" %in% commandArgs(trailingOnly = TRUE))
}
