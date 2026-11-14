root <- "."
assessment_id <- "mpi_tarakihi_western_2026"
stock_id <- "mpi_tarakihi_western"
candidate_id <- "MPI:TAR:WESTERN"
retrieved_on <- "2026-11-05"
source_file <- file.path(root, "source_cache/mpi_tarakihi_western_2026/FAR-2026-23-western-tarakihi-2026.pdf")
source_url <- "https://fs.fish.govt.nz/Doc/26247/FAR-2026-23-Stock-assessment-of-western-tarakihi-for-2026.pdf.ashx"
expected_hash <- "9B7DCD75AF96DF146D1F12C838752D9904A331623C6609BED3B8B042BDD85698"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(source_file)) stop("Cache the reviewed FAR 2026/23 PDF before importing.", call. = FALSE)
actual_hash <- toupper(unname(tools::sha256sum(source_file)))
if (!identical(actual_hash, expected_hash)) stop("The cached report differs from the reviewed source.", call. = FALSE)

text_file <- file.path(root, "source_cache/mpi_tarakihi_western_2026/FAR-2026-23-text.txt")
if (file.exists(text_file)) {
  lines <- readLines(text_file, warn = FALSE, encoding = "UTF-8")
} else if (requireNamespace("pdftools", quietly = TRUE)) {
  lines <- unlist(strsplit(pdftools::pdf_text(source_file), "\n", fixed = TRUE), use.names = FALSE)
} else {
  stop("Extract the cached report text to FAR-2026-23-text.txt or install pdftools.", call. = FALSE)
}

section_lines <- function(start, end = NULL) {
  first <- which(grepl(start, lines, fixed = TRUE))[1L]
  if (is.na(first)) stop("Source table not found: ", start, call. = FALSE)
  last <- length(lines) + 1L
  if (!is.null(end)) {
    later <- which(seq_along(lines) > first & grepl(end, lines, fixed = TRUE))
    if (!length(later)) stop("End of source table not found: ", end, call. = FALSE)
    last <- later[1L]
  }
  lines[seq.int(first, last - 1L)]
}

number_tokens <- function(text) {
  tokens <- strsplit(trimws(text), "[[:space:]]+")[[1L]]
  if (!length(tokens) || identical(tokens, "")) return(numeric())
  values <- numeric()
  i <- 1L
  while (i <= length(tokens)) {
    if (grepl("^[0-9]{1,3}$", tokens[i]) && i < length(tokens) &&
        grepl("^[0-9]{3}(?:\\.[0-9]+)?$", tokens[i + 1L])) {
      values <- c(values, as.numeric(paste0(tokens[i], tokens[i + 1L])))
      i <- i + 2L
    } else {
      values <- c(values, suppressWarnings(as.numeric(gsub(",", "", tokens[i], fixed = TRUE))))
      i <- i + 1L
    }
  }
  values[is.finite(values)]
}

parse_catches <- function() {
  table <- section_lines("Table A16:", "Table A17:")
  rows <- list()
  for (line in table) {
    if (!grepl("^[[:space:]]*(?:19|20)[0-9]{2}([[:space:]]|$)", line, perl = TRUE)) next
    years_match <- gregexpr("(?:19|20)[0-9]{2}", line, perl = TRUE)[[1L]]
    if (identical(years_match, -1L)) next
    lengths <- attr(years_match, "match.length")
    years <- as.integer(mapply(function(at, n) substr(line, at, at + n - 1L), years_match, lengths))
    if (!any(years %in% 1932:2025)) next
    for (j in seq_along(years)) {
      if (!years[j] %in% 1932:2025) next
      first <- years_match[j] + lengths[j]
      last <- if (j < length(years)) years_match[j + 1L] - 1L else nchar(line)
      values <- number_tokens(substr(line, first, last))
      if (length(values) != 4L) stop("Expected four fishery catch values for model year ", years[j], "; got ", paste(values, collapse = ","), " from: ", line, call. = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(year = years[j], WCSI = values[1L],
        TBGB = values[2L], TAR8 = values[3L], WCNI = values[4L])
    }
  }
  out <- do.call(rbind, rows)
  out <- out[order(out$year), , drop = FALSE]
  if (!identical(out$year, 1932:2025) || nrow(out) != 94L) {
    stop("Catch-table year coverage does not match 1932-2025.", call. = FALSE)
  }
  out
}

parse_age_table <- function(start, end = NULL) {
  table <- section_lines(start, end)
  age_rows <- grep("^[[:space:]]*(30\\+|[1-9]|[12][0-9])[[:space:]]+", table, perl = TRUE)
  if (!length(age_rows)) stop("No age rows found in ", start, ".", call. = FALSE)
  header <- table[seq_len(age_rows[1L] - 1L)]
  year_matches <- unlist(lapply(header, function(line) {
    z <- gregexpr("(?:19|20)[0-9]{2}", line, perl = TRUE)
    regmatches(line, z)[[1L]]
  }), use.names = FALSE)
  years <- unique(as.integer(year_matches))
  if (!length(years)) stop("No model years found in ", start, ".", call. = FALSE)
  has_female <- any(grepl("\\bfemales\\b", header, ignore.case = TRUE))
  has_male <- any(grepl("\\bmales\\b", header, ignore.case = TRUE))
  sexes <- if (has_female && has_male) c("female", "male") else if (has_female) "female" else if (has_male) "male" else stop("Sex labels missing in ", start, ".", call. = FALSE)
  rows <- list()
  for (line in table[age_rows]) {
    match <- regmatches(line, regexec("^[[:space:]]*(30\\+|[1-9]|[12][0-9])[[:space:]]+(.+?)[[:space:]]*$", line, perl = TRUE))[[1L]]
    if (!length(match)) next
    age <- if (match[2L] == "30+") 30L else as.integer(match[2L])
    values <- suppressWarnings(as.numeric(strsplit(trimws(match[3L]), "[[:space:]]+")[[1L]]))
    expected <- length(years) * length(sexes)
    if (length(values) != expected || any(!is.finite(values))) {
      stop("Age row does not match the table headings in ", start, ": ", line, call. = FALSE)
    }
    for (s in seq_along(sexes)) for (y in seq_along(years)) {
      rows[[length(rows) + 1L]] <- data.frame(age = age, year = years[y], sex = sexes[s],
        value = values[(s - 1L) * length(years) + y], stringsAsFactors = FALSE)
    }
  }
  out <- do.call(rbind, rows)
  if (!identical(sort(unique(out$age)), 1:30) ||
      anyDuplicated(out[c("age", "year", "sex")])) {
    stop("Age-table coverage or row keys are invalid in ", start, ".", call. = FALSE)
  }
  out
}

parse_index_cells <- function(line) {
  matches <- gregexpr("[0-9]+(?:[[:space:]]+[0-9]{3})*(?:\\.[0-9]+)?[[:space:]]*\\((?:[0-9]+(?:\\.[0-9]+)?|-)\\)",
    line, perl = TRUE)[[1L]]
  if (identical(matches, -1L)) return(data.frame(value = numeric(), cv = numeric()))
  cells <- regmatches(line, list(matches))[[1L]]
  do.call(rbind, lapply(cells, function(cell) {
    m <- regmatches(cell, regexec("^([0-9]+(?:[[:space:]]+[0-9]{3})*(?:\\.[0-9]+)?)[[:space:]]*\\(([^)]+)\\)$", cell, perl = TRUE))[[1L]]
    data.frame(value = as.numeric(gsub("[[:space:],]", "", m[2L])),
      cv = if (m[3L] == "-") NA_real_ else as.numeric(m[3L]) / 100)
  }))
}

parse_survey_indices <- function() {
  survey_table <- section_lines("Table 8:", "Figure 29:")
  survey_rows <- list()
  for (line in survey_table) {
    match <- regmatches(line, regexec("^[[:space:]]*(KAH[0-9]{4})[[:space:]]+((?:19|20)[0-9]{2})", line, perl = TRUE))[[1L]]
    if (!length(match)) next
    cells <- parse_index_cells(line)
    if (nrow(cells) != 5L) stop("Expected five survey-index cells: ", line, call. = FALSE)
    series <- c("WCSI biomass", "TBGB biomass", "TBGB age 1", "TBGB age 2", "WCSI age 2")
    survey_rows[[length(survey_rows) + 1L]] <- data.frame(
      code = match[2L], year = as.integer(match[3L]), series = series,
      value = cells$value, cv = cells$cv, stringsAsFactors = FALSE
    )
  }
  survey <- do.call(rbind, survey_rows)
  wcni_table <- section_lines("Table 9:", "Figure 33:")
  wcni_rows <- list()
  for (line in wcni_table) {
    match <- regmatches(line, regexec("^[[:space:]]*(KAH[0-9]{4})[[:space:]]+((?:19|20)[0-9]{2})[[:space:]]+((?:19|20)[0-9]{2})[[:space:]]+(.+)$", line, perl = TRUE))[[1L]]
    if (!length(match)) next
    values <- number_tokens(match[5L])
    if (length(values) != 2L) stop("Expected WCNI survey biomass and CV: ", line, call. = FALSE)
    wcni_rows[[length(wcni_rows) + 1L]] <- data.frame(
      code = match[2L], year = as.integer(match[4L]), series = "WCNI biomass",
      value = values[1L], cv = values[2L] / 100, stringsAsFactors = FALSE
    )
  }
  list(wide = survey, wcni = do.call(rbind, wcni_rows))
}

parse_cpue <- function() {
  table <- section_lines("Table A5:", "Figure A6:")
  rows <- list()
  for (line in table) {
    year <- regmatches(line, regexec("^[[:space:]]*((?:19|20)[0-9]{2})[^0-9]+", line, perl = TRUE))[[1L]]
    if (!length(year)) next
    values <- number_tokens(sub("^[[:space:]]*[^[:space:]]+[[:space:]]+", "", line, perl = TRUE))
    if (length(values) != 9L) stop("Expected nine CPUE index and interval values: ", line, call. = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(year = as.integer(year[2L]) + 1L,
      index = values[1L], lwr = values[2L], upr = values[3L])
  }
  out <- do.call(rbind, rows)
  if (!identical(out$year, 1994:2025)) stop("WCNI CPUE model years do not match 1994-2025.", call. = FALSE)
  out
}

western_import <- local({
  catch <- parse_catches()
  compositions <- list(
    list(data = parse_age_table("Table A17:", "Table A18:"), table = "Table A17, p. 88",
      name = "WCSI commercial", type = "catch", fleet = "WCSI commercial trawl fishery", survey = "", region = "WCSI"),
    list(data = parse_age_table("Table A18:", "Table A19:"), table = "Table A18, pp. 89-90",
      name = "TAR8 commercial", type = "catch", fleet = "TAR 8 commercial trawl fishery", survey = "", region = "TAR 8"),
    list(data = parse_age_table("Table A19:", "Table A20:"), table = "Table A19, p. 91",
      name = "WCNI commercial", type = "catch", fleet = "WCNI commercial trawl fishery", survey = "", region = "WCNI"),
    list(data = parse_age_table("Table A20:", "Table A21:"), table = "Table A20, pp. 91-92",
      name = "WCNI survey", type = "index", fleet = "", survey = "Kaharoa WCNI trawl survey", region = "WCNI"),
    list(data = parse_age_table("Table A21:", "Table A22:"), table = "Table A21, pp. 92-93",
      name = "WCSI survey female", type = "index", fleet = "", survey = "Kaharoa WCSI trawl survey", region = "WCSI"),
    list(data = parse_age_table("Table A22:"), table = "Table A22, pp. 93-94",
      name = "WCSI survey male", type = "index", fleet = "", survey = "Kaharoa WCSI trawl survey", region = "WCSI")
  )
  if (any(vapply(compositions, function(spec) {
    any(!is.finite(spec$data$value) | spec$data$value < 0 | spec$data$value > 1)
  }, logical(1)))) stop("Age-composition values must be proportions in [0, 1].", call. = FALSE)
  indices <- parse_survey_indices()
  cpue <- parse_cpue()
  inputs <- list()
  add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
      year_basis = "", age = NA_real_, fleet = "", survey = "", sex = "",
      region = "", season = "", sampling_time = NA_real_, source_type = "official_table",
      source_reference, transformation = "", notes = "", observation_id = "",
      sample_size = NA_real_) {
    inputs[[length(inputs) + 1L]] <<- data.frame(
      assessment_id, type, measure, basis, fleet, survey, sex, region, season,
      year = as.integer(year), year_basis, age = as.numeric(age), value = as.numeric(value),
      unit, sampling_time, source_type, source_reference, transformation, notes,
      observation_id, length_bin = NA_real_, length_bin_lower = NA_real_,
      length_bin_upper = NA_real_, sample_size = as.numeric(sample_size),
      age_error = NA_real_, partition = NA_character_, stringsAsFactors = FALSE
    )
  }

  catch_fleets <- c("WCSI" = "WCSI", "TBGB" = "TBGB", "TAR8" = "TAR 8", "WCNI" = "WCNI")
  for (i in seq_len(nrow(catch))) for (fleet in names(catch_fleets)) {
    catch_note <- "Published catch biomass, including the report's unreported-catch allowance: 20% before QMS introduction in 1986-87 and 10% thereafter. Model year 2025 is 2024-25."
    if (fleet == "TBGB" && catch$year[i] < 1985L) {
      catch_note <- paste(catch_note,
        "Pre-1985 TBGB catch is assigned by port of landing; the report considers it likely that much of this catch came from WCSI and was landed in Nelson. The model assumes TBGB selectivity equivalent to WCSI.")
    }
    add_input("catch", "total_biomass", "biomass", catch[[fleet]][i], "tonnes",
      year = catch$year[i], year_basis = "model_year", fleet = paste(catch_fleets[fleet], "fishery"),
      region = catch_fleets[fleet], source_reference = "Fisheries New Zealand FAR 2026/23, Table A16, p. 88",
      notes = catch_note,
      observation_id = paste0("catch_", fleet, "_", catch$year[i]))
  }

  for (spec in compositions) for (i in seq_len(nrow(spec$data))) {
    z <- spec$data[i, ]
    older_t8 <- spec$name == "TAR8 commercial" && z$year <= 2020L
    fleet <- if (older_t8) "TAR 8 survey-like commercial age samples" else spec$fleet
    survey <- spec$survey
    sample_size <- if (spec$name == "WCSI survey female" || spec$name == "WCSI survey male") NA_real_ else 20
    source_type <- "official_table"
    add_input(spec$type, "proportion_at_age", "proportion_numbers", z$value, "proportion",
      year = z$year, year_basis = "model_year", age = z$age, fleet = fleet,
      survey = survey, sex = z$sex, region = spec$region, sample_size = sample_size,
      source_reference = paste("Fisheries New Zealand FAR 2026/23", spec$table),
      notes = paste(
        "Source-reported sex-and-age composition cell; age 30 represents 30+. Female and male values share one observation ID and are retained without normalization; the report does not explain totals below one.",
        if (older_t8) "The 2019-2020 TAR 8 compositions are the report's survey-like commercial samples, modelled with a distinct selectivity group." else "",
        if (!is.na(sample_size)) "The source reports effective sample size 20; this is the model likelihood ESS, not the number of fish aged." else "The report gives only a range (ESS 9-16.2) for WCSI survey compositions; observation-specific ESS values were not published and are left blank."
      ),
      observation_id = paste(
        if (spec$name %in% c("WCSI survey female", "WCSI survey male")) "WCSI survey" else spec$name,
        z$year, sep = "_")
    )
  }

  maturity <- c(0, 0.03, 0.06, 0.14, 0.27, 0.47, 0.68, 0.84, 0.92, 1)
  for (age in seq_along(maturity)) {
    add_input("maturity", "maturity_at_age", "proportion_numbers", maturity[age], "proportion",
      age = age, sex = "female", source_reference = "Fisheries New Zealand FAR 2026/23, Table 11, p. 43",
      notes = if (age == 10L) "Age 10 represents 10+; female maturity is 1.0 for this plus group." else "Female age-specific maturity used in the base model.")
  }

  add_survey_index <- function(series, survey, region, value, cv, year, measure, unit,
      age = NA_real_, source_reference, note) {
    obs_id <- paste(gsub("[^A-Za-z0-9]+", "_", series), year, sep = "_")
    add_input("index", measure, if (measure == "total_biomass") "biomass" else "numbers",
      value, unit, year = year, year_basis = "model_year", age = age, survey = survey,
      region = region, source_reference = source_reference,
      notes = note, observation_id = obs_id)
    if (is.finite(cv)) {
      cv_measure <- if (measure == "total_biomass") "biomass_index_cv" else if (is.na(age)) "abundance_index_cv" else "numbers_at_age_cv"
      add_input("index", cv_measure, "relative_scale", cv, "ratio", year = year,
        year_basis = "model_year", age = age, survey = survey, region = region,
        source_reference = source_reference,
        transformation = "Source CV reported as percent; divided by 100 to store a ratio.",
        notes = "Coefficient of variation for the matching survey index.", observation_id = obs_id)
    }
  }
  selected_wide <- indices$wide[indices$wide$series %in% c("WCSI biomass", "TBGB age 1"), ]
  for (i in seq_len(nrow(selected_wide))) {
    z <- selected_wide[i, ]
    if (z$series == "WCSI biomass") {
      add_survey_index(z$series, "Kaharoa WCSI trawl survey", "WCSI", z$value, z$cv,
        z$year, "total_biomass", "tonnes", source_reference = "Fisheries New Zealand FAR 2026/23, Table 8, p. 35",
        note = "Survey biomass index used in the 2026 base model.")
    } else {
      add_survey_index(z$series, "Kaharoa TBGB trawl survey age-1 index", "TBGB", z$value, z$cv,
        z$year, "numbers_at_age", "thousand fish", age = 1,
        source_reference = "Fisheries New Zealand FAR 2026/23, Table 8, p. 35",
        note = "Age-1 recruitment abundance index used in the 2026 base model; table values are thousands of fish.")
    }
  }
  for (i in seq_len(nrow(indices$wcni))) {
    z <- indices$wcni[i, ]
    add_survey_index("WCNI biomass", "Kaharoa WCNI trawl survey", "WCNI", z$value, z$cv,
      z$year, "total_biomass", "tonnes", source_reference = "Fisheries New Zealand FAR 2026/23, Table 9, p. 38",
      note = "Survey biomass index used in the 2026 base model.")
  }

  for (i in seq_len(nrow(cpue))) {
    z <- cpue[i, ]
    sigma_log <- (log(z$upr) - log(z$lwr)) / (2 * 1.96)
    cv <- sqrt(exp(sigma_log^2) - 1)
    obs_id <- paste0("wcni_cpue_", z$year)
    add_input("index", "relative_abundance_index", "index_scale", z$index,
      "relative index units", year = z$year, year_basis = "model_year",
      fleet = "WCNI commercial trawl fishery", region = "WCNI",
      source_reference = "Fisheries New Zealand FAR 2026/23, Table A5, pp. 70-71",
      notes = paste0("Combined standardized CPUE index used in the 2026 base model. Source 95% interval: ",
        z$lwr, " to ", z$upr, ". Fishing year is mapped to its ending model year."),
      observation_id = obs_id)
    add_input("index", "abundance_index_cv", "relative_scale", cv, "ratio",
      year = z$year, year_basis = "model_year", fleet = "WCNI commercial trawl fishery",
      region = "WCNI", source_type = "reconstructed_source_input",
      source_reference = "Fisheries New Zealand FAR 2026/23, Table A5, pp. 70-71",
      transformation = "Derived lognormal CV from the published 95% confidence limits: sigma_log=(ln(UCI)-ln(LCI))/(2*1.96); CV=sqrt(exp(sigma_log^2)-1).",
      notes = paste0("Approximate relative standard error derived from the reported combined-index interval ", z$lwr,
        " to ", z$upr, "; the report's Table 12 summarizes the base-model CV range as 0.16-0.24, plus 0.1 process error."),
      observation_id = obs_id)
  }

  inputs <- do.call(rbind, inputs)
  comp <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
  if (nrow(catch) != 94L || nrow(comp) != 1980L || sum(inputs$measure == "maturity_at_age") != 10L || nrow(indices$wide) != 85L ||
      nrow(indices$wcni) != 7L || nrow(cpue) != 32L ||
      any(!is.finite(comp$value) | comp$value < 0 | comp$value > 1)) {
    stop("Parsed western tarakihi coverage does not match the published tables.", call. = FALSE)
  }

  assumption_rows <- list()
  add_assumption <- function(component, setting, value, source_reference, notes = "", sex = "", region = "") {
    assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
      assessment_id, component, fleet = "", survey = "", sex, region, season = "",
      setting, value = as.character(value), source_reference, notes,
      stringsAsFactors = FALSE
    )
  }
  bio_ref <- "Fisheries New Zealand FAR 2026/23, Table 11, p. 43"
  add_assumption("mortality", "natural mortality", "0.10 per year, fixed for both sexes", bio_ref,
    "Based on age structure from a lightly exploited WCSI population sampled in 1971-1972.")
  growth <- data.frame(sex = c("male", "male", "male", "male", "female", "female", "female", "female"),
    parameter = rep(c("L1", "L40", "k", "b"), 2L),
    value = c(12.57, 42.94, 0.162, 1.88, 12.63, 45.85, 0.142, 1.87),
    unit = c("cm", "cm", "per year", "", "cm", "cm", "per year", ""), stringsAsFactors = FALSE)
  for (i in seq_len(nrow(growth))) add_assumption("growth", paste("Schnute", growth$parameter[i]),
    paste(growth$value[i], growth$unit[i]), bio_ref,
    "Sex-specific growth parameter reported for the western tarakihi base model.", sex = growth$sex[i])
  add_assumption("length_weight", "length-weight relationship", "W = 1.432e-05 * L^3.068",
    bio_ref, "Report gives one length-weight relationship; length in cm and weight in kg.")
  add_assumption("maturity", "female proportion mature at age",
    "ages 1-10+: 0, 0.03, 0.06, 0.14, 0.27, 0.47, 0.68, 0.84, 0.92, 1.0",
    bio_ref, "Age-based female maturity schedule; age 10+ is the plus group.")
  add_assumption("recruitment", "stock-recruitment relationship", "Beverton-Holt; steepness fixed at 0.8",
    bio_ref, "Recruitment deviations are estimated for 1985-2024.")
  add_assumption("recruitment", "recruitment standard deviation", "sigmaR = 0.6",
    bio_ref, "The model uses independent recruitment deviations with no averaging constraint.")
  structure_ref <- "Fisheries New Zealand FAR 2026/23, section 7.2, pp. 43-45"
  add_assumption("population", "model structure", "One region; two sexes; 40 age classes with age 40+ as a plus group",
    structure_ref, "The region covers the WCSI, TBGB, TAR 8, and WCNI fisheries.")
  add_assumption("population", "initial population", "Equilibrium, unexploited population in 1932",
    structure_ref, "The model data period ends in model year 2025 (the 2024-25 fishing year).")
  add_assumption("recruitment", "estimated deviations", "1985-2024; independent deviations without an averaging constraint",
    structure_ref, "Recruitment deviations are estimated relative to the Beverton-Holt relationship.")
  add_assumption("selectivity", "main commercial fisheries", "Logistic age selectivity for WCSI, TAR 8, and WCNI; oldest ages assumed fully vulnerable",
    structure_ref, "TBGB fishery selectivity is assumed equivalent to WCSI.")
  add_assumption("selectivity", "TAR 8 2019-2020 age samples", "Separate survey-like composition with double-normal selectivity",
    structure_ref, "These samples were treated separately from the 2024-2025 TAR 8 fishery compositions.")
  add_assumption("selectivity", "trawl surveys", "Separate logistic WCNI selectivity; sex-specific WCSI selectivity",
    structure_ref, "WCSI female selectivity is double-normal with oldest ages constrained fully selected; male selectivity is estimated relative to females.")
  add_assumption("selectivity", "WCNI commercial CPUE", "Shares selectivity with the WCNI fishery",
    structure_ref, "The WCSI CPUE series was not included in the base model because the WCSI trawl survey was considered more reliable.")
  add_assumption("catchability", "TBGB age-1 index", "Estimated catchability; selectivity applies to age 1 only",
    structure_ref, "An additional power parameter was investigated but excluded from the base model because the data were not informative enough to estimate both parameters.")
  add_assumption("likelihood", "abundance indices", "Lognormal likelihood",
    "Fisheries New Zealand FAR 2026/23, Table 13, p. 45",
    "Applies to WCSI and WCNI biomass indices, WCNI CPUE, and the trawl-survey age-1 abundance index.")
  add_assumption("likelihood", "age compositions", "Multinomial likelihood",
    "Fisheries New Zealand FAR 2026/23, Table 13, p. 45",
    "The report lists commercial and trawl-survey age-composition observations and their effective sample sizes.")
  add_assumption("likelihood", "recruitment deviations and parameter priors", "Recruitment-deviation likelihood and parameter-prior components included",
    "Fisheries New Zealand FAR 2026/23, Table 13, p. 45",
    "The report does not provide the complete native model files or all individual parameter-prior values.")
  add_assumption("time", "annual time step", "October-September; periods October-March and April-September",
    "Fisheries New Zealand FAR 2026/23, section 7.2, pp. 43-44",
    "Spawning is assumed at the start of the second period.")
  add_assumption("data_weighting", "commercial age-composition ESS", "20 for each observation",
    "Fisheries New Zealand FAR 2026/23, Table 13, p. 45",
    "Effective sample size, not raw number of fish aged.")
  add_assumption("data_weighting", "WCNI survey age-composition ESS", "20 for each observation",
    "Fisheries New Zealand FAR 2026/23, Table 13, p. 45",
    "Effective sample size, not raw number of fish aged.")
  add_assumption("data_weighting", "WCSI survey age-composition ESS", "final values range 9-16.2",
    "Fisheries New Zealand FAR 2026/23, Table 13, p. 45",
    "Individual ESS values are not tabulated; initial values were derived from MWCV and reweighted using Francis TA1.8.")
  add_assumption("data_weighting", "WCNI CPUE process error", "0.1 added to the CV",
    "Fisheries New Zealand FAR 2026/23, Table 12, p. 44",
    "Base-model CPUE CVs are reported as 0.16-0.24 before this additional process error.")
  assumptions <- do.call(rbind, assumption_rows)

  output_values <- data.frame(
    type = c("biomass", "biomass", "biomass", "biomass", "biomass", "biomass", "mortality", "mortality", "mortality", "catch"),
    measure = c("unfished_spawning_biomass", "SSB", "SSB_ratio_to_B0", "probability_above_40_percent_B0",
      "probability_above_20_percent_B0", "probability_above_10_percent_B0", "F_reference_at_SB40",
      "F_ratio_to_FSB40", "probability_below_FSB40", "yield_at_FSB40"),
    year = c(NA_integer_, 2025L, 2025L, 2025L, 2025L, 2025L, NA_integer_, 2025L, 2025L, 2025L),
    value = c(15284, 4419, 0.290, 0.009, 0.996, 1.000, 0.064, 1.599, 0.001, 714),
    lwr = c(13257, 3170, 0.218, NA, NA, NA, NA, 1.228, NA, 518),
    upr = c(17658, 5986, 0.377, NA, NA, NA, NA, 2.116, NA, 967),
    unit = c("tonnes", "tonnes", "ratio", "probability", "probability", "probability", "per year", "ratio", "probability", "tonnes"),
    stringsAsFactors = FALSE
  )
  outputs <- do.call(rbind, lapply(seq_len(nrow(output_values)), function(i) data.frame(
    assessment_id, type = output_values$type[i], measure = output_values$measure[i],
    fleet = "", survey = "", sex = if (output_values$type[i] == "biomass") "female" else "",
    region = "", season = "", year = output_values$year[i], age = NA_real_, age_group = "",
    value = output_values$value[i], se = NA_real_, lwr = output_values$lwr[i], upr = output_values$upr[i],
    unit = output_values$unit[i], source_type = "official_table",
    source_reference = if (i <= 6L) "Fisheries New Zealand FAR 2026/23, Table 15, p. 58" else "Fisheries New Zealand FAR 2026/23, Table 16, p. 59",
    notes = paste("Base-case MCMC median or probability. The report gives 95% MCMC intervals where available.",
      if (output_values$measure[i] == "yield_at_FSB40") "Yield at the FSB40% reference; this is a reference yield, not current catch." else ""),
    scenario = "", stringsAsFactors = FALSE
  )))

  stocks <- data.frame(
    stock_id, charbonneau_id = "", authority = "Fisheries New Zealand", authority_stock_id = "TAR 8 and western portions of TAR 1 and TAR 7",
    scientific_name = "Nemadactylus macropterus", common_name = "Western tarakihi",
    area = "Western biological stock: TAR 8 and western portions of TAR 1 and TAR 7",
    region = "New Zealand waters", ocean = "Southwest Pacific",
    notes = "Distinct western biological stock, separate from the eastern tarakihi unit. The assessment model represents one region.",
    stringsAsFactors = FALSE
  )
  assessments <- data.frame(
    assessment_id, stock_id, assessment_year = 2026L, terminal_year = 2025L,
    estimate_terminal_year = 2025L, assessment_type = "full_assessment",
    model_family = "Stock Synthesis", model_version = "3.30.23.1; 2026 base case",
    is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_, assessment_url = source_url,
    framework_url = "", data_url = source_url, model_url = "", repository_url = "",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = paste(
      "Latest detailed production assessment located for the western tarakihi biological stock; model years 1932-2025, with 2025 representing the 2024-25 fishing year.",
      "The base case uses WCSI and WCNI survey biomass, TBGB age-1 abundance, WCNI commercial CPUE, and commercial and survey age compositions. The TAR 8 CPUE index was excluded from the base case because its trend conflicted with other abundance information.",
      "Model ages are 1-39 plus 40+, while the published age-composition tables use bins 1-29 plus 30+. Female and male cells are retained as reported without normalization; the report does not explain why some table totals are below one.",
      "The report does not tabulate annual numeric population-at-age, fishing-mortality-at-age, natural-mortality-at-age or recruitment arrays. Individual WCSI survey composition ESS values are also unavailable."
    ),
    stringsAsFactors = FALSE
  )
  manifest <- data.frame(local_file = sub("^\\./?", "", source_file), source_url = source_url,
    retrieved_on = retrieved_on, sha256 = expected_hash, stringsAsFactors = FALSE)
  list(stocks = stocks, assessments = assessments, inputs = inputs,
    assumptions = assumptions, outputs = outputs, manifest = manifest,
    catch = catch, compositions = compositions, survey_indices = indices, cpue = cpue)
})

cat("Western tarakihi parsed: ", nrow(western_import$inputs), " inputs (",
  sum(western_import$inputs$measure == "total_biomass" & western_import$inputs$type == "catch"),
  " catches, ", sum(western_import$inputs$measure == "proportion_at_age"),
  " age-composition cells), ", nrow(western_import$assumptions), " assumptions, and ",
  nrow(western_import$outputs), " outputs.\n", sep = "")

if (write_mode) {
  id_exists <- function(path, id) {
    con <- file(path, open = "r")
    on.exit(close(con))
    repeat {
      chunk <- readLines(con, n = 20000L, warn = FALSE)
      if (!length(chunk)) return(FALSE)
      if (any(startsWith(chunk, paste0('"', id, '"')))) return(TRUE)
    }
  }
  database_dir <- file.path(root, "database")
  if (id_exists(file.path(database_dir, "stocks.csv"), stock_id) ||
      id_exists(file.path(database_dir, "assessments.csv"), assessment_id)) {
    stop("Refusing to duplicate the western tarakihi stock or assessment.", call. = FALSE)
  }
  append_csv <- function(data, path) write.table(data, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  append_csv(western_import$stocks, file.path(database_dir, "stocks.csv"))
  append_csv(western_import$assessments, file.path(database_dir, "assessments.csv"))
  append_csv(western_import$inputs, file.path(database_dir, "inputs.csv"))
  append_csv(western_import$assumptions, file.path(database_dir, "assumptions.csv"))
  append_csv(western_import$outputs, file.path(database_dir, "outputs.csv"))
  write.csv(western_import$manifest, "provenance/mpi_tarakihi_western_2026_sources.csv", row.names = FALSE, na = "")

  source("scripts/database/candidate_register_io.R")
  register_path <- file.path(root, "discovery", "candidates.csv")
  register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  position <- match(candidate_id, register$candidate_id)
  if (is.na(position)) stop("Western tarakihi candidate is missing from the register.", call. = FALSE)
  candidate <- register[position, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "Imported published catch biomass for 1932-2025 and 1,980 reported sex-age composition cells for three commercial fisheries. These proportions are not catch numbers-at-age; the report does not explain why some joint table totals are below one, and values are retained without normalization."
  candidate$survey_age_evidence <- "Imported WCSI and WCNI survey biomass indices, the TBGB age-1 abundance index with its CV, WCNI combined CPUE and survey age compositions. TAR 8 CPUE was excluded from the base assessment."
  candidate$weights_evidence <- "Growth and length-weight parameters were imported as assumptions; the report does not provide a direct weight-at-age matrix."
  candidate$maturity_evidence <- "Imported the report's numerical female maturity-at-age schedule for ages 1-10+, with age 10 representing the plus group."
  candidate$mortality_evidence <- "Imported fixed natural mortality of 0.10 per year for both sexes."
  candidate$timing_evidence <- "Model year is October-September, split into October-March and April-September. No numeric within-year fraction for individual indices is reported."
  candidate$output_evidence <- "Imported Table 15-16 MCMC medians, available 95% intervals, status probabilities, and reference yield. Annual numeric N/F/M-at-age and recruitment arrays were not tabulated."
  candidate$decision_reason <- "Partial source import completed from the latest detailed 2026 western tarakihi assessment. Catch biomass, composition vectors, base-case indices, biological assumptions, and terminal status outputs are represented. Direct age weights, individual WCSI survey ESS, and annual fitted state arrays remain unavailable."
  candidate$notes <- "One western biological stock distinct from eastern tarakihi; model uses one region. TAR 8 CPUE is not part of the accepted base-case likelihood."
  replace_candidate_register_row(register_path, position, candidate, candidate_id)
  sys.source("scripts/database/195_summarize_discovery.R", envir = new.env(parent = globalenv()))
  sys.source("scripts/database/196_summarize_inventory_units.R", envir = new.env(parent = globalenv()))
}
