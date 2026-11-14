import_noaa_gulf_cobia_sedar28 <- function(root = ".", write = FALSE) {
  assessment_id <- "noaa_cobia_gulf_mexico_2020_sedar28_update"
  stock_id <- "noaa_cobia_gulf_mexico_2020"
  candidate_id <- "NOAA:10390"
  report_file <- "sedar28_gulf_cobia_update_2020.pdf"
  source_dir <- file.path(root, "source_cache/discovery_noaa_gom_cobia_2020")
  manifest <- read.csv(file.path(root, "provenance/discovery_noaa_gom_cobia_2020/sources.csv"),
    stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")

  sha256_file <- function(path) {
    path <- normalizePath(path, winslash = if (.Platform$OS.type == "windows") "\\" else "/",
      mustWork = TRUE)
    if (.Platform$OS.type == "windows") {
      out <- system2("certutil.exe", c("-hashfile", path, "SHA256"), stdout = TRUE)
      hash <- trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", out, value = TRUE))
    } else {
      out <- system2("sha256sum", shQuote(path), stdout = TRUE)
      hash <- sub("[[:space:]].*$", "", out[1L])
    }
    if (length(hash) != 1L) stop("Could not hash source: ", path)
    tolower(hash)
  }
  source_paths <- file.path(source_dir, manifest$file)
  report_row <- match(report_file, manifest$file)
  if (anyDuplicated(manifest$file) || any(!grepl("^[[:xdigit:]]{64}$", manifest$sha256)) ||
      any(!file.exists(source_paths)) ||
      !identical(as.numeric(file.info(source_paths)$size), as.numeric(manifest$bytes)) ||
      is.na(report_row) || sha256_file(source_paths[report_row]) !=
        tolower(manifest$sha256[report_row])) {
    stop("The cached Gulf cobia sources differ from their provenance manifest.")
  }
  text_path <- paste0(file.path(source_dir, report_file), ".txt")
  if (!file.exists(text_path)) {
    if (!requireNamespace("pdftools", quietly = TRUE))
      stop("Install pdftools or provide the extracted report text beside the PDF.")
    writeLines(pdftools::pdf_text(file.path(source_dir, report_file)), text_path, useBytes = TRUE)
  }
  lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")

  table_section <- function(number) {
    at <- grep("^Table [0-9]+( Continued)?\\.", lines, perl = TRUE)
    ids <- as.integer(sub("^Table ([0-9]+).*", "\\1", lines[at]))
    hits <- which(ids == number)
    if (!length(hits)) stop("SEDAR 28 report table ", number, " is absent.")
    first <- at[hits[1L]]
    next_table <- which(ids != number & at > first)
    last <- if (length(next_table)) at[min(next_table)] - 1L else length(lines)
    lines[first:last]
  }
  token_parts <- function(line) {
    positions <- gregexpr("\\S+", line, perl = TRUE)[[1L]]
    if (positions[1L] == -1L) return(list(start = integer(), token = character(), value = numeric()))
    tokens <- regmatches(line, list(positions))[[1L]]
    numeric <- suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
    list(start = as.integer(positions) - 1L, token = tokens, value = numeric)
  }
  fixed_cells <- function(line, anchors, label) {
    part <- token_parts(line)
    result <- rep(NA_real_, length(anchors))
    for (i in seq_along(part$value)) {
      if (!is.finite(part$value[i])) next
      column <- which.min(abs(anchors - part$start[i]))
      if (abs(anchors[column] - part$start[i]) > 11L)
        stop("Unexpected column position in ", label, ": ", line)
      if (is.finite(result[column]))
        stop("Duplicate column value in ", label, ": ", line)
      result[column] <- part$value[i]
    }
    result
  }
  fixed_table <- function(number, anchors, first, last, repeated = FALSE) {
    section <- table_section(number)
    selected <- section[grepl("^[[:space:]]*[0-9]{4}[[:space:]]+", section, perl = TRUE)]
    rows <- lapply(selected, fixed_cells, anchors = anchors,
      label = paste0("SEDAR 28 Table ", number))
    rows <- Filter(function(x) is.finite(x[1L]) && x[1L] >= first && x[1L] <= last, rows)
    if (!length(rows)) stop("No year rows found in SEDAR 28 Table ", number, ".")
    x <- do.call(rbind, rows)
    rownames(x) <- as.character(as.integer(x[, 1L]))
    if (repeated) {
      for (year in unique(rownames(x)[duplicated(rownames(x))])) {
        duplicate <- x[rownames(x) == year, , drop = FALSE]
        if (!all(vapply(seq_len(nrow(duplicate))[-1L], function(i)
          isTRUE(all.equal(unname(duplicate[1L, ]), unname(duplicate[i, ]))),
          logical(1L)))) stop("Repeated year differs in SEDAR 28 Table ", number, ": ", year)
      }
      x <- x[!duplicated(rownames(x)), , drop = FALSE]
    }
    if (!identical(as.integer(rownames(x)), seq.int(first, last)))
      stop("Unexpected year coverage in SEDAR 28 Table ", number, ".")
    x
  }
  value_table <- function(number, first, last, n_values) {
    section <- table_section(number)
    selected <- section[grepl("^[[:space:]]*[0-9]{4}[[:space:]]+", section, perl = TRUE)]
    rows <- list()
    for (line in selected) {
      values <- token_parts(line)$value
      values <- values[is.finite(values)]
      if (!length(values)) next
      year <- as.integer(values[1L])
      if (year < first || year > last) next
      if (length(values) < n_values + 1L)
        stop("Unexpected row in SEDAR 28 Table ", number, ": ", line)
      rows[[as.character(year)]] <- values[2L:(n_values + 1L)]
    }
    if (!identical(as.integer(names(rows)), seq.int(first, last)))
      stop("Unexpected year coverage in SEDAR 28 Table ", number, ".")
    x <- do.call(rbind, rows)
    rownames(x) <- names(rows)
    x
  }
  report_ref <- function(x) paste0("SEDAR 28 Gulf of Mexico Cobia Update report, ", x)

  commercial <- fixed_table(4L, c(13, 21, 39, 56, 71), 1927L, 2018L)
  recreational <- fixed_table(5L, c(12, 19, 33, 47, 58, 74, 82), 1950L, 2018L)
  commercial_discards <- fixed_table(6L, c(19, 28, 41, 58), 1993L, 2018L)
  recreational_discards <- fixed_table(7L, c(28, 37, 56, 64), 1981L, 2018L)
  shrimp_bycatch <- fixed_table(8L, c(29, 47), 1972L, 2017L)
  composition_counts <- fixed_table(9L, c(4, 9, 35, 62, 77), 1981L, 2018L, repeated = TRUE)
  shrimp_effort <- fixed_table(10L, c(25, 45, 66), 1945L, 2018L)
  indices <- fixed_table(11L, c(12, 26, 45, 62, 78), 1981L, 2018L)
  apical_f <- value_table(14L, 1925L, 2018L, 3L)
  population <- value_table(15L, 1925L, 2018L, 5L)

  exploitation_lines <- table_section(13L)
  exploitation_lines <- exploitation_lines[grepl("^[[:space:]]*[0-9]{4}[[:space:]]+",
    exploitation_lines, perl = TRUE)]
  exploitation <- list()
  for (line in exploitation_lines) {
    value <- token_parts(line)$value
    value <- value[is.finite(value)]
    if (!length(value)) next
    year <- as.integer(value[1L])
    if (year < 1927L || year > 2018L) next
    if (length(value) < 2L) stop("Unexpected row in SEDAR 28 Table 13.")
    exploitation[[as.character(year)]] <- value[2L]
  }
  if (!identical(as.integer(names(exploitation)), 1927:2018))
    stop("Unexpected year coverage in SEDAR 28 Table 13.")

  m_lines <- table_section(2L)
  m_lines <- m_lines[grepl("^[[:space:]]*[0-9]{1,2}[[:space:]]+", m_lines, perl = TRUE)]
  m_table <- do.call(rbind, lapply(m_lines, function(line) {
    values <- token_parts(line)$value
    values <- values[is.finite(values)]
    if (length(values) != 4L) stop("Unexpected SEDAR 28 Table 2 row: ", line)
    values
  }))
  if (!identical(as.integer(m_table[, 1L]), 0:11)) stop("Unexpected age coverage in Table 2.")

  growth_lines <- table_section(3L)
  growth_lines <- growth_lines[grepl("^[[:space:]]*(L|K|t0)", growth_lines, perl = TRUE)]
  growth_names <- c("growth_linf", "growth_k", "growth_t0")
  if (length(growth_lines) != 3L) stop("Unexpected growth parameters in Table 3.")
  growth <- do.call(rbind, lapply(growth_lines, function(line) {
    values <- token_parts(line)$value
    values <- values[is.finite(values)]
    if (length(values) != 3L) stop("Unexpected SEDAR 28 Table 3 row: ", line)
    values
  }))
  rownames(growth) <- growth_names
  weight_line <- grep("^ Comb\\.", table_section(1L), value = TRUE)
  weight_line <- weight_line[grepl("Comb\\.[[:space:]]+Ln\\(Wt\\)", weight_line)]
  if (length(weight_line) != 1L) stop("Could not recover the combined weight-length coefficients.")
  weight_values <- token_parts(weight_line)$value
  weight_values <- weight_values[is.finite(weight_values)]
  if (length(weight_values) != 7L) stop("Unexpected combined weight-length row in Table 1.")

  input_columns <- names(read.csv(file.path(root, "database/inputs.csv"), nrows = 0L, check.names = FALSE))
  output_columns <- names(read.csv(file.path(root, "database/outputs.csv"), nrows = 0L, check.names = FALSE))
  assumption_columns <- names(read.csv(file.path(root, "database/assumptions.csv"), nrows = 0L, check.names = FALSE))
  make_record <- function(columns, values) {
    row <- as.data.frame(setNames(lapply(columns, function(x) ""), columns),
      stringsAsFactors = FALSE, check.names = FALSE)
    for (name in intersect(names(values), columns)) {
      value <- values[[name]]
      if (!length(value) || is.na(value)) value <- ""
      if (is.numeric(value)) value <- format(value, scientific = FALSE, trim = TRUE, digits = 15)
      row[[name]] <- as.character(value)
    }
    row
  }
  input_rows <- output_rows <- assumption_rows <- list()
  add_input <- function(type, measure, basis, value, unit, source_reference, notes,
      year = NA_integer_, age = NA_real_, fleet = "", survey = "", sex = "",
      transformation = "", observation_id = "", partition = "", source = "official_table") {
    input_rows[[length(input_rows) + 1L]] <<- make_record(input_columns, list(
      assessment_id = assessment_id, type = type, measure = measure, basis = basis,
      fleet = fleet, survey = survey, sex = sex, year = year,
      year_basis = if (is.na(year)) "" else "calendar_year", age = age,
      value = value, unit = unit, source_type = source, source_reference = source_reference,
      transformation = transformation, notes = notes, observation_id = observation_id,
      partition = partition
    ))
  }
  add_output <- function(type, measure, value, unit, source_reference, notes,
      year, age = NA_integer_, fleet = "") {
    output_rows[[length(output_rows) + 1L]] <<- make_record(output_columns, list(
      assessment_id = assessment_id, type = type, measure = measure, fleet = fleet,
      region = "Gulf of Mexico", year = year, age = age, value = value, se = NA_real_,
      lwr = NA_real_, upr = NA_real_, unit = unit, source_type = "official_table",
      source_reference = source_reference, notes = notes
    ))
  }
  add_assumption <- function(component, setting, value, source_reference, notes) {
    assumption_rows[[length(assumption_rows) + 1L]] <<- make_record(assumption_columns, list(
      assessment_id = assessment_id, component = component, setting = setting,
      value = value, source_reference = source_reference, notes = notes
    ))
  }

  for (i in seq_len(nrow(m_table))) add_input("M", "natural_mortality_at_age",
    "per_year", m_table[i, 2L], "per year", report_ref("Table 2"),
    "Base-model fixed Lorenzen M vector. Low/high columns are sensitivity runs, not base inputs.",
    age = m_table[i, 1L])
  for (age in 2:10) add_input("maturity", "maturity_at_age", "proportion",
    if (age == 2L) 0.5 else 1, "proportion", report_ref("section 3.2.2"),
    "Fixed maturity: age 2 is 50% mature and ages 3+ are fully mature.",
    age = age, sex = "female", source = "official_document")
  for (age in 0:10) add_input("biology", "proportion_female_at_age",
    "proportion", 0.6, "proportion", report_ref("section 3.2.2"),
    "The assessment assumes a 60% female fraction at all ages.",
    age = age, sex = "female", source = "official_document")

  for (i in seq_len(nrow(commercial))) {
    year <- commercial[i, 1L]
    gears <- c("Commercial Handline", "Commercial Longline", "Commercial Other")
    for (j in 1:3) if (is.finite(commercial[i, j + 1L])) {
      add_input("catch", "landings_biomass", "biomass", commercial[i, j + 1L],
        "pounds whole weight", report_ref("Table 4"),
        "Source-reported commercial landings component, retained by gear.",
        year = year, fleet = gears[j], observation_id = paste0("cobia_commercial_landings_",
          c("handline", "longline", "other")[j]))
    }
    add_input("catch", "landings_biomass", "biomass", commercial[i, 5L],
      "metric tons whole weight", report_ref("Table 4"),
      "Reported aggregate commercial landings used by the assessment.",
      year = year, fleet = "Commercial",
      transformation = "Use the Table 4 reported total; source gear components remain separate.",
      observation_id = "cobia_commercial_landings_total_1927_2018")
  }

  source_names <- c("Historical", "FHWAR", "MRIP", "SRHS Headboat", "TPWD", "LA Creel")
  source_ids <- c("historical", "fhwar", "mrip", "srhs_headboat", "tpwd", "la_creel")
  for (i in seq_len(nrow(recreational))) {
    year <- recreational[i, 1L]
    values <- recreational[i, 2:7]
    if (!any(is.finite(values))) stop("No recreational landings reported for ", year, ".")
    for (j in seq_along(values)) if (is.finite(values[j])) {
      add_input("catch", "landings_numbers", "numbers", values[j], "fish",
        report_ref("Table 5"), paste0("Source-reported recreational landings from ", source_names[j], "."),
        year = year, fleet = "Recreational",
        observation_id = paste0("cobia_recreational_landings_", source_ids[j]))
    }
    add_input("catch", "landings_numbers", "numbers",
      sum(values[is.finite(values)]) / 1000, "1000 fish", report_ref("Table 5"),
      "Reconstructed annual model input: sum reported source series across modes and regions, divided by 1000.",
      year = year, fleet = "Recreational",
      transformation = "Sum non-missing Historical/FHWAR/MRIP/SRHS/TPWD/LA values; divide fish by 1000.",
      observation_id = "cobia_recreational_landings_aggregate_1950_2018",
      source = "reconstructed_source_input")
  }
  for (i in seq_len(nrow(commercial_discards))) for (j in 2:4)
    add_input("catch", "discard_numbers", "numbers", commercial_discards[i, j],
      "fish", report_ref("Table 6"), "Source-reported commercial discard count by gear.",
      year = commercial_discards[i, 1L],
      fleet = c("Commercial Longline", "Commercial Vertical Line",
        "Commercial Florida Vertical Line")[j - 1L],
      observation_id = paste0("cobia_commercial_discards_",
        c("longline", "vertical_line", "fl_vertical_line")[j - 1L]))
  for (i in seq_len(nrow(recreational_discards))) for (j in 2:4)
    add_input("catch", "discard_numbers", "numbers", recreational_discards[i, j],
      "fish", report_ref("Table 7"), "Source-reported recreational discard count by source.",
      year = recreational_discards[i, 1L], fleet = "Recreational",
      observation_id = paste0("cobia_recreational_discards_",
        c("mrip", "srhs_headboat", "tpwd")[j - 1L]))
  for (i in seq_len(nrow(shrimp_bycatch))) add_input("catch", "catch_numbers",
    "numbers", shrimp_bycatch[i, 2L], "fish", report_ref("Table 8"),
    "Annual source estimate; the assessment fits a shrimp-bycatch super-period, not this annual series independently.",
    year = shrimp_bycatch[i, 1L], fleet = "Shrimp Bycatch",
    partition = "annual source estimates; super-period likelihood",
    observation_id = "cobia_shrimp_bycatch_1972_2017")

  composition_names <- c("commercial_length", "discarded_commercial_length",
    "recreational_length", "recreational_age")
  composition_fleets <- c("Commercial", "Commercial", "Recreational", "Recreational")
  for (i in seq_len(nrow(composition_counts))) for (j in 2:5) {
    value <- composition_counts[i, j]
    if (!is.finite(value)) next
    add_input("biology", "composition_sample_count", "numbers", value, "fish",
      report_ref("Table 9"),
      "Annual sample count only; the report does not tabulate composition cells.",
      year = composition_counts[i, 1L], fleet = composition_fleets[j - 1L],
      partition = composition_names[j - 1L],
      observation_id = paste0("cobia_", composition_names[j - 1L], "_samples"))
  }
  for (i in seq_len(nrow(shrimp_effort))) {
    year <- shrimp_effort[i, 1L]
    for (j in 2:3) add_input("index", if (j == 2L) "effort" else "log_index_sd",
      if (j == 2L) "index_scale" else "log_scale", shrimp_effort[i, j],
      if (j == 2L) "relative index" else "log scale SD", report_ref("Table 10"),
      "Mean-normalized shrimp-fishery effort used to scale shrimp-fleet fishing mortality; not an abundance index.",
      year = year, fleet = "Shrimp Bycatch", survey = "Shrimp fishery effort",
      observation_id = "cobia_shrimp_effort_1945_2018")
  }
  for (i in seq_len(nrow(indices))) for (j in c(2L, 4L)) {
    if (!is.finite(indices[i, j])) next
    headboat <- j == 2L
    survey <- if (headboat) "SRHS Headboat" else "MRIP"
    observation_id <- if (headboat) "cobia_srhs_headboat_cpue_1986_2018" else
      "cobia_mrip_cpue_1981_2018"
    add_input("index", "relative_abundance_index", "index_scale", indices[i, j],
      "relative index (mean near 1)", report_ref("Table 11"),
      "Fishery-dependent aggregate abundance index; there is no age-specific survey index.",
      year = indices[i, 1L], fleet = "Recreational", survey = survey,
      observation_id = observation_id)
    add_input("index", "log_index_sd", "log_scale", indices[i, j + 1L],
      "log scale SD", report_ref("Table 11"),
      "Source-reported log-scale standard error.",
      year = indices[i, 1L], fleet = "Recreational", survey = survey,
      observation_id = observation_id)
  }

  out_measures <- c("total_biomass", "SSB", "total_abundance", "recruitment", "depletion")
  out_types <- c("biomass", "biomass", "population", "recruitment", "population")
  out_units <- c("metric tons", "metric tons", "1000 fish", "1000 fish", "ratio")
  for (i in seq_len(nrow(population))) for (j in seq_along(out_measures))
    add_output(out_types[j], out_measures[j], population[i, j], out_units[j],
      report_ref("Table 15"), "Official annual point estimate; uncertainty is not tabulated.",
      year = as.integer(rownames(population)[i]),
      age = if (out_measures[j] == "recruitment") 0L else NA_integer_)
  for (i in seq_len(nrow(apical_f))) for (j in 1:3)
    add_output("mortality", "apical_fishing_mortality", apical_f[i, j],
      "per year", report_ref("Table 14"),
      "Annual apical F by fleet; the report does not tabulate age-specific F.",
      year = as.integer(rownames(apical_f)[i]),
      fleet = c("Commercial", "Recreational", "Shrimp Bycatch")[j])
  for (year in names(exploitation)) add_output("mortality", "exploitation_rate",
    exploitation[[year]], "ratio", report_ref("Table 13"),
    "Biomass killed divided by total biomass; the assessment uses this as a proxy for F, not age-specific instantaneous F.",
    year = as.integer(year))

  assumption_data <- list(
    c("assessment", "run_identity", "SEDAR 28 Gulf Cobia Update, June 2020; data through 2018; central Stock Synthesis run.", "title and section 2", "Latest detailed Gulf-unit assessment located; NOAA continued to cite it in 2024."),
    c("assessment", "management_use", "Used for status determinations; not quantitative OFL/ABC advice.", "section 2 and SEDAR review", "Preserve the model's limited management use."),
    c("model", "model_version", "Stock Synthesis 3.24", "section 4", "Model version as reported."),
    c("population", "age_structure", "Annual age-structured population, ages 0-10; age 10 is a plus group.", "section 4.1", "No seasonal structure."),
    c("stock", "stock_boundary", "Gulf of Mexico unit; Florida-Georgia state line separates Gulf and South Atlantic cobia.", "section 3.1", "Keep Gulf cobia separate from Atlantic cobia."),
    c("catch", "commercial_landings", "Annual total, 1927-2018, metric tons whole weight.", "Table 4", "Gear-specific source values are retained; the assessment uses aggregate commercial landings."),
    c("catch", "recreational_landings", "Annual aggregate, 1950-2018, 1000 fish.", "Table 5 and section 3.3.1", "Aggregated across modes and regions from Historical/FHWAR/MRIP/SRHS/TPWD/LA sources."),
    c("catch", "discard_data", "Commercial by gear, 1993-2018; recreational MRIP/SRHS/TPWD, 1981-2018.", "Tables 6-7", "Source series retained separately."),
    c("catch", "shrimp_bycatch", "Annual source estimates, 1972-2017, used to form a super-period likelihood.", "Table 8 and section 4.1.10", "Annual values are not fitted independently."),
    c("index", "abundance_indices", "MRIP 1981-2018 and SRHS Headboat 1986-2018; aggregate fishery-dependent indices.", "Table 11 and sections 3.3.4, 4.1.11", "No age-specific abundance index."),
    c("index", "shrimp_effort", "Mean-normalized index, 1945-2018; log-scale SD 0.2.", "Table 10 and section 4.1.10", "Informs shrimp-fleet F, not abundance."),
    c("observation", "composition_data", "Commercial/recreational length and recreational conditional age-at-length compositions.", "sections 3.3.3-3.3.5 and Figures 4-6", "Composition values are plotted, not tabulated in the reviewed sources."),
    c("observation", "composition_sample_sizes", "Table 9 annual sample counts; later adjusted using Francis weighting.", "Table 9 and section 3.3.3", "Raw sample counts are imported; likelihood cells and effective sample sizes are not available."),
    c("biology", "weight_length_coefficients", paste0("Fixed sex-combined relationship ln(weight_kg) = ", weight_values[2L], " + ", weight_values[4L], " * ln(fork_length_mm)."), "Table 1", "The coefficients are retained as assessment assumptions, not annual biological observations."),
    c("biology", "growth_parameters", paste0("All L-infinity/K/t0: ", paste(growth[, 1L], collapse = "/"), "; female: ", paste(growth[, 2L], collapse = "/"), "; male: ", paste(growth[, 3L], collapse = "/"), ". Units are mm, per year, and years."), "Table 3", "Recommended fixed growth inputs are retained without expanding them into an age-specific weight surface."),
    c("biology", "maturity_and_sex_ratio", "Age 2 is 50% mature, ages 3+ fully mature; female fraction 0.60 at all ages.", "section 3.2.2", "Fecundity is proportional to female weight."),
    c("M", "natural_mortality", "Fixed Lorenzen age-specific M; scaled using M=0.38 per year for ages 3-11.", "Table 2 and section 3.2.3", "M is not estimated."),
    c("survey", "sampling_time", "Annual continuous model; no fractional within-year timing is specified.", "section 4.1", "No sampling-time value is imputed."),
    c("output", "uncertainty", "Tables 13-15 report point estimates without annual uncertainty columns.", "Tables 13-15", "No SEs or confidence limits are added.")
  )
  for (row in assumption_data) add_assumption(row[1L], row[2L], row[3L],
    report_ref(row[4L]), row[5L])
  inputs <- do.call(rbind, input_rows)
  outputs <- do.call(rbind, output_rows)
  assumptions <- do.call(rbind, assumption_rows)
  input_key <- paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey, inputs$sex,
    inputs$year, inputs$age, inputs$observation_id, inputs$partition, sep = "|")
  output_key <- paste(outputs$type, outputs$measure, outputs$fleet,
    outputs$year, outputs$age, sep = "|")
  if (any(!is.finite(as.numeric(inputs$value))) || any(!is.finite(as.numeric(outputs$value))) ||
      anyDuplicated(input_key) || anyDuplicated(output_key)) {
    bad_input <- which(duplicated(input_key))[1L]
    bad_output <- which(duplicated(output_key))[1L]
    stop("Invalid/duplicate rows: bad input value=", any(!is.finite(as.numeric(inputs$value))),
      "; bad output value=", any(!is.finite(as.numeric(outputs$value))),
      "; duplicate input=", if (is.na(bad_input)) "none" else input_key[bad_input],
      "; duplicate output=", if (is.na(bad_output)) "none" else output_key[bad_output])
  }

  database <- file.path(root, "database")
  existing_stocks <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  existing_assessments <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  if (any(existing_stocks$authority == "NOAA Fisheries" &
      existing_stocks$authority_stock_id == "10390" &
      existing_stocks$stock_id != stock_id, na.rm = TRUE))
    stop("NOAA stock ID 10390 is already assigned to a different canonical stock.")

  stock <- make_record(names(existing_stocks), list(stock_id = stock_id, charbonneau_id = "",
    authority = "NOAA Fisheries", authority_stock_id = "10390",
    scientific_name = "Rachycentron canadum", common_name = "Gulf of Mexico cobia",
    area = "Gulf of Mexico", region = "United States Gulf of Mexico",
    ocean = "Northwest Atlantic",
    notes = "NOAA Stock SMART ID 10390; distinct from Southern Atlantic cobia, separated at the Florida-Georgia state line."))
  report_url <- manifest$url[match(report_file, manifest$file)]
  assessment <- make_record(names(existing_assessments), list(
    assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2020,
    terminal_year = 2018, estimate_terminal_year = 2018,
    assessment_type = "update_assessment", model_family = "Stock Synthesis",
    model_version = "3.24", is_current = TRUE, is_applied = TRUE,
    assessment_url = report_url, data_url = paste(manifest$url[manifest$file != report_file], collapse = "; "),
    model_url = report_url, assumptions_status = "partial", inputs_status = "partial",
    outputs_status = "partial",
    notes = "Latest detailed Gulf-unit assessment located. NOAA continued to cite it in 2024; management use is limited to status determinations, not quantitative OFL/ABC advice."))

  read_rows <- function(path) {
    matches <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
      "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
    status <- attr(matches, "status"); if (is.null(status)) status <- 0L
    if (status == 1L) matches <- character() else if (status != 0L)
      stop("Could not inspect existing rows in ", path)
    matches <- matches[startsWith(matches, paste0('"', assessment_id, '",'))]
    header <- readLines(path, n = 1L, warn = FALSE)
    if (!length(matches)) return(read.csv(text = header, nrows = 0L,
      stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"))
    read.csv(text = paste(c(header, matches), collapse = "\n"),
      stringsAsFactors = FALSE, na.strings = c("", "NA"),
      check.names = FALSE, colClasses = "character")
  }
  same_rows <- function(existing, expected, label) {
    normalize <- function(x) {
      y <- as.data.frame(lapply(x, function(z) {z <- as.character(z); z[is.na(z)] <- ""; z}),
        stringsAsFactors = FALSE, check.names = FALSE)
      apply(y, 1L, paste, collapse = "\r")
    }
    if (nrow(existing) != nrow(expected) || !identical(names(existing), names(expected)) ||
        !identical(sort(normalize(existing)), sort(normalize(expected))))
      stop("Existing Gulf cobia ", label, " rows conflict with the source extraction.")
    TRUE
  }
  already_imported <- FALSE
  if (write) {
    old_stock <- existing_stocks[existing_stocks$stock_id == stock_id, , drop = FALSE]
    old_assessment <- existing_assessments[
      existing_assessments$assessment_id == assessment_id, , drop = FALSE]
    old_assumptions <- read_rows(file.path(database, "assumptions.csv"))
    old_inputs <- read_rows(file.path(database, "inputs.csv"))
    old_outputs <- read_rows(file.path(database, "outputs.csv"))
    has_rows <- nrow(old_stock) + nrow(old_assessment) + nrow(old_assumptions) +
      nrow(old_inputs) + nrow(old_outputs) > 0L
    if (has_rows) {
      already_imported <- nrow(old_stock) == 1L && nrow(old_assessment) == 1L &&
        same_rows(old_stock, stock, "stock") &&
        same_rows(old_assessment, assessment, "assessment") &&
        same_rows(old_assumptions, assumptions, "assumption") &&
        same_rows(old_inputs, inputs, "input") && same_rows(old_outputs, outputs, "output")
      if (!already_imported) stop("A conflicting partial Gulf cobia import already exists.")
    }
  }

  candidates_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  candidate_row <- match(candidate_id, candidates$candidate_id)
  if (is.na(candidate_row) || candidates$candidate_unit_id[candidate_row] != stock_id ||
      candidates$official_stock_id[candidate_row] != "10390" ||
      candidates$scientific_name[candidate_row] != "Rachycentron canadum" ||
      candidates$eligibility[candidate_row] != "eligible" ||
      !candidates$import_status[candidate_row] %in% c("not_started", "partial"))
    stop("Gulf cobia candidate identity or status changed.")
  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  source(file.path(root, "scripts/database/candidate_register_io.R"))
  inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
  selected_path <- file.path(root, "discovery/selected_batch_39_2026.csv")
  selected <- read.csv(selected_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  selected_row <- match(candidate_id, selected$candidate_id)
  if (is.na(selected_row) ||
      !selected$curation_status[selected_row] %in% c("selected_for_source_curation", "partial_source_import"))
    stop("Gulf cobia is absent from the selected source batch.")

  updates <- list(
    matched_stock_id = stock_id, match_status = "matched", import_status = "partial",
    catch_age_evidence = paste("Imported annual commercial/recreational removals, discards and shrimp-bycatch source estimates.",
      "Conditional recreational age-at-length and length-composition cells are plotted, not tabulated; no numerical catch-at-age is available."),
    survey_age_evidence = paste("Imported aggregate MRIP (1981-2018) and SRHS Headboat (1986-2018) indices with log-scale SDs.",
      "They are fishery-dependent; no age-specific survey index exists."),
    weights_evidence = paste("Imported fixed sex-combined length-weight coefficients and recommended sex-specific growth parameters.",
      "Age-specific weights can be derived; no direct annual weight-at-age table is reported."),
    maturity_evidence = paste("Fixed maturity: age 2 is 50% mature and ages 3+ are fully mature; female fraction is 0.60 at all ages."),
    mortality_evidence = paste("Imported the fixed age-specific Lorenzen M vector for ages 0-11, scaled using M=0.38 per year over ages 3-11; M is not estimated."),
    timing_evidence = paste("Annual model assumes continuous fishing and spawning; no fractional within-year index timing is specified."),
    output_evidence = paste("Imported Tables 13-15: exploitation-rate proxy, apical F by fleet, biomass, SSB, total abundance, age-0 recruitment and depletion.",
      "These are point estimates; numeric N-at-age and age-specific F are unavailable."),
    review_date = as.character(Sys.Date()),
    decision_reason = paste("Partial import from the latest detailed Gulf-unit assessment. Numerically reported inputs and outputs are retained.",
      "Composition cells and age-specific output surfaces remain unavailable; none were imputed or digitized."),
    notes = paste("SEDAR 28 Gulf Cobia Update, NOAA Stock SMART 10390, data through 2018.",
      "NOAA's 2024 amendment continues to cite it; management use is limited to status determinations, not quantitative OFL/ABC advice.")
  )
  for (name in names(updates)) candidates[[name]][candidate_row] <- updates[[name]]
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  selected$curation_status[selected_row] <- "partial_source_import"

  if (write && !already_imported) {
    append_rows <- function(name, rows) {
      write.table(rows, file.path(database, paste0(name, ".csv")), sep = ",",
        row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
        qmethod = "double", eol = "\n")
    }
    append_rows("stocks", stock)
    append_rows("assessments", assessment)
    append_rows("assumptions", assumptions)
    append_rows("inputs", inputs)
    append_rows("outputs", outputs)
    replace_candidate_register_row(candidates_path, candidate_row,
      candidates[candidate_row, , drop = FALSE], candidate_id)
    replace_csv_register_row(inventory_path, inventory_row,
      inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
    replace_candidate_register_row(selected_path, selected_row,
      selected[selected_row, , drop = FALSE], candidate_id)
  }
  list(stock = stock, assessment = assessment, assumptions = assumptions,
    inputs = inputs, outputs = outputs, already_imported = already_imported)
}

if (!interactive() && sys.nframe() == 0L) {
  result <- import_noaa_gulf_cobia_sedar28(write = "--write" %in% commandArgs(trailingOnly = TRUE))
  cat("NOAA Gulf cobia SEDAR 28 update: ", nrow(result$inputs), " inputs, ",
    nrow(result$outputs), " outputs; already imported = ", result$already_imported, ".\n", sep = "")
}
