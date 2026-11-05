root <- "."
assessment_id <- "mpi_ling_lin34_2025"
stock_id <- "mpi_ling_lin34"
candidate_id <- "MPI:LIN34"
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args
.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))

assessment_pdf <- file.path(root, "source_cache", "mpi_ling_lin34_2025", "FAR-2025-48-LIN3-4-assessment.pdf")
support_pdf <- file.path(root, "source_cache", "mpi_ling_lin34_2025", "FAR-2025-47-LIN3-4-inputs.pdf")
plenary_pdf <- file.path(root, "source_cache", "mpi_ling_lin34_2025", "Fisheries-Assessment-Plenary-2025-volume-2-ling.pdf")
manifest_path <- file.path(root, "provenance", "mpi_ling_lin34_2025_sources.csv")
source_files <- c(assessment_pdf, support_pdf, plenary_pdf)
expected_hash <- c(
  "5C8F67CE8A81FFB6DF5E6192BC71F5034C8302F43B10FD5C9C1BC25CFA2B6790",
  "81C547A3996EB770458C23A0FCA5EEEE98A22097DEDCB7DDF128DF706CE009CC",
  "5C09739BE5378E339B565F1A8BF54B9673AFD9364BBEAF3D1B8D8A63A92471A5"
)
if (!requireNamespace("pdftools", quietly = TRUE) || !all(file.exists(source_files))) {
  stop("Install pdftools and cache the three verified Fisheries New Zealand reports before importing.", call. = FALSE)
}
actual_hash <- unname(toupper(tools::sha256sum(source_files)))
if (!identical(actual_hash, expected_hash)) stop("A cached LIN 3&4 source file does not match its reviewed checksum.", call. = FALSE)

manifest <- data.frame(
  local_file = basename(source_files),
  source_url = c(
    "https://fs.fish.govt.nz/Doc/26148/FAR-2025-48-Stock-assessment-of-Chatham-Rise-ling-2025.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26147/FAR-2025-47-Descriptive-analysis-LIN34-to-2023-24-and-inputs-for-2025-stock-assessment.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26063/ling-fisheries-assessment-plenary-may-2025-volume-2.pdf.ashx"
  ),
  retrieved_on = "2026-11-05",
  sha256 = expected_hash,
  represented_source = c(
    "FAR 2025/48, the 2025 Chatham Rise ling production assessment and embedded Casal2 base-case inputs",
    "FAR 2025/47, detailed catch, age, and fishery data supporting the 2025 LIN 3&4 assessment",
    "Fisheries Assessment Plenary 2025, volume 2, official cross-check of LIN 3&4 inputs, assumptions, and outputs"
  ),
  stringsAsFactors = FALSE
)
if (file.exists(manifest_path)) {
  existing_manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!identical(toupper(existing_manifest$sha256), expected_hash) ||
    !identical(existing_manifest$source_url, manifest$source_url)) {
    stop("The LIN 3&4 provenance manifest differs from the pinned sources.", call. = FALSE)
  }
}

pages <- pdftools::pdf_text(assessment_pdf)
appendix_page <- tail(which(grepl("APPENDIX A: INPUT FILES", pages, fixed = TRUE)), 1L)
if (!length(appendix_page)) stop("Could not find the embedded Casal2 input appendix.", call. = FALSE)
appendix_lines <- trimws(unlist(strsplit(paste(pages[appendix_page:length(pages)], collapse = "\n"), "\n", fixed = TRUE)))

strip_code_comments <- function(x) {
  result <- character()
  in_block <- FALSE
  for (line in x) {
    if (in_block) {
      if (grepl("\\*/", line)) in_block <- FALSE
      next
    }
    if (grepl("/\\*", line)) {
      if (!grepl("\\*/", line)) in_block <- TRUE
      next
    }
    line <- sub("#.*$", "", line)
    if (grepl("^Fisheries New Zealand\\s+", line) || grepl("^[0-9]+\\s*•", line)) next
    result <- c(result, trimws(line))
  }
  result[nzchar(result)]
}
appendix_lines <- strip_code_comments(appendix_lines)
population_start <- grep("^A\\.1 Population\\.csl2$", appendix_lines)[1L]
observation_start <- grep("^A\\.2 Observation\\.csl2$", appendix_lines)[1L]
estimation_start <- grep("^A\\.3 Estimation\\.csl2$", appendix_lines)[1L]
if (anyNA(c(population_start, observation_start, estimation_start))) {
  stop("The Casal2 input appendix section boundaries changed; review before importing.", call. = FALSE)
}
population_lines <- appendix_lines[seq.int(population_start + 1L, observation_start - 1L)]
observation_lines <- appendix_lines[seq.int(observation_start + 1L, estimation_start - 1L)]
estimation_lines <- appendix_lines[seq.int(estimation_start + 1L, length(appendix_lines))]

field_value <- function(block, field, default = NA_character_) {
  hit <- grep(paste0("^", field, "\\s+"), block)
  if (!length(hit)) return(default)
  sub(paste0("^", field, "\\s+"), "", block[hit[1L]])
}
declared_years <- function(block) {
  hit <- grep("^years\\s+", block)[1L]
  if (is.na(hit)) return(numeric())
  years <- suppressWarnings(as.numeric(strsplit(sub("^years\\s+", "", block[hit]), "\\s+")[[1L]]))
  i <- hit + 1L
  while (i <= length(block) && !grepl("^table\\s", block[i])) {
    tokens <- strsplit(trimws(block[i]), "\\s+")[[1L]]
    values <- suppressWarnings(as.numeric(tokens))
    if (!length(values) || anyNA(values) || any(values < 1900 | values > 2100 | values != as.integer(values))) break
    years <- c(years, values)
    i <- i + 1L
  }
  years
}
table_rows <- function(block, name, years) {
  start <- which(block == paste("table", name))
  if (length(start) != 1L) stop("Expected one table ", name, " in a source block.", call. = FALSE)
  end <- which(seq_along(block) > start & block == "end_table")[1L]
  if (is.na(end)) stop("Unterminated source table: ", name, call. = FALSE)
  rows <- list()
  current <- numeric()
  flush <- function() if (length(current)) rows[[length(rows) + 1L]] <<- current
  for (line in block[seq.int(start + 1L, end - 1L)]) {
    tokens <- strsplit(trimws(line), "\\s+")[[1L]]
    if (!length(tokens) || !nzchar(tokens[1L])) next
    values <- suppressWarnings(as.numeric(tokens))
    if (!length(values) || is.na(values[1L])) next
    if (values[1L] %in% years && values[1L] == as.integer(values[1L])) {
      flush()
      current <- values
    } else if (length(current) && all(is.finite(values))) {
      current <- c(current, values)
    }
  }
  flush()
  rows
}
source_blocks <- function(code) {
  starts <- grep("^@[^[:space:]]+\\s+", code)
  lapply(seq_along(starts), function(i) {
    header <- strsplit(sub("^@", "", code[starts[i]]), "\\s+")[[1L]]
    end <- if (i < length(starts)) starts[i + 1L] - 1L else length(code)
    list(type = header[1L], name = paste(header[-1L], collapse = " "),
      lines = code[seq.int(starts[i] + 1L, end)])
  })
}
population_blocks <- source_blocks(population_lines)
observation_blocks <- source_blocks(observation_lines)
estimation_blocks <- source_blocks(estimation_lines)
observations <- observation_blocks[vapply(observation_blocks, `[[`, character(1), "type") == "observation"]
names(observations) <- vapply(observations, `[[`, character(1), "name")
expected_observations <- c("Tangaroa_bio", "Tangaroa_propn_at_age_Jan", "trawl_propn_at_age", "longline_propn_at_age")
if (!setequal(names(observations), expected_observations)) stop("The base-case observation blocks changed.", call. = FALSE)

parse_settings <- function(block) {
  lines <- block$lines
  values <- list()
  in_table <- FALSE
  i <- 1L
  while (i <= length(lines)) {
    line <- lines[i]
    if (grepl("^table\\s+", line)) { in_table <- TRUE; i <- i + 1L; next }
    if (line == "end_table") { in_table <- FALSE; i <- i + 1L; next }
    if (!in_table) {
      match <- regmatches(line, regexec("^([[:alnum:]_.-]+)\\s+(.+)$", line))[[1L]]
      if (length(match)) {
        key <- match[2L]
        value <- match[3L]
        if (key == "years") {
          year_block <- lines[i:length(lines)]
          years <- declared_years(year_block)
          if (length(years)) value <- paste(years, collapse = " ")
        }
        values[[key]] <- value
      }
    }
    i <- i + 1L
  }
  values
}

series <- list(
  Tangaroa_bio = list(kind = "index", survey = "Tangaroa summer trawl survey", region = "Chatham Rise"),
  Tangaroa_propn_at_age_Jan = list(kind = "index", survey = "Tangaroa summer trawl survey", region = "Chatham Rise"),
  trawl_propn_at_age = list(kind = "catch", fleet = "Commercial trawl", region = "Chatham Rise"),
  longline_propn_at_age = list(kind = "catch", fleet = "Commercial longline", region = "Chatham Rise")
)

input_fields <- names(read.csv(file.path(root, "database", "inputs.csv"), nrows = 0L, check.names = FALSE))
assumption_fields <- names(read.csv(file.path(root, "database", "assumptions.csv"), nrows = 0L, check.names = FALSE))
output_fields <- names(read.csv(file.path(root, "database", "outputs.csv"), nrows = 0L, check.names = FALSE))
make_rows <- function(fields, values, n = 1L) {
  result <- lapply(fields, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(result) <- fields
  as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
}
input_rows <- list()
assumption_rows <- list()
output_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_real_, age = NA_real_,
  fleet = "", survey = "", sex = "", region = "Chatham Rise", season = "",
  sampling_time = NA_real_, source_reference, notes = "", observation_id = "",
  sample_size = NA_real_, source_type = "native_model") {
  input_rows[[length(input_rows) + 1L]] <<- make_rows(input_fields, list(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = year, year_basis = if (all(is.na(year))) "" else "calendar_year",
    age = age, value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    notes = notes, observation_id = observation_id, sample_size = sample_size
  ), length(value))
}
add_assumption <- function(component, setting, value, source_reference, notes = "",
  fleet = "", survey = "", sex = "", region = "Chatham Rise", season = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(assumption_fields, list(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference, notes = notes
  ))
}
add_output <- function(type, measure, value, unit, year = NA_real_, sex = "", season = "",
  lwr = NA_real_, upr = NA_real_, scenario = "", source_reference, notes = "", source_type = "official_table") {
  output_rows[[length(output_rows) + 1L]] <<- make_rows(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    sex = sex, region = "Chatham Rise", season = season, year = year, scenario = scenario,
    value = value, lwr = lwr, upr = upr, unit = unit,
    source_type = source_type, source_reference = source_reference, notes = notes
  ), length(value))
}

catch_rows <- table_rows(population_lines, "catches", 1972:2025)
if (length(catch_rows) != 54L || any(lengths(catch_rows) != 4L) ||
  !identical(vapply(catch_rows, `[[`, numeric(1), 1L), as.numeric(1972:2025))) {
  stop("Unexpected LIN 3&4 catch table dimensions or years.", call. = FALSE)
}
catch_fleets <- c(trawl = "Commercial trawl", line = "Commercial longline", pot = "Commercial pot")
for (j in seq_along(catch_fleets)) for (row in catch_rows) {
  first_year <- c(trawl = 1973, line = 1975, pot = 2000)[j]
  note <- paste(
    "Casal2 catch biomass from the base-case population input, in tonnes.",
    "The source table contains zeroes before the fishery catch series begins; the 2025 entry is the average of 2022–2024 catches, not an observed catch."
  )
  add_input("catch", "total_biomass", "biomass", row[j + 1L], "tonnes",
    year = row[1L], fleet = catch_fleets[j], region = "Chatham Rise",
    source_reference = "Fisheries New Zealand FAR 2025/48, Appendix A.1 Population.csl2, table catches (printed pp. 28–29)",
    notes = note)
}

for (name in names(observations)) {
  block <- observations[[name]]
  meta <- series[[name]]
  settings <- parse_settings(block)
  years <- declared_years(block$lines)
  rows <- table_rows(block$lines, "obs", years)
  obs_years <- vapply(rows, `[[`, numeric(1), 1L)
  if (!length(years) || anyDuplicated(obs_years) || !setequal(obs_years, years)) {
    stop("Observation years do not match the declared years for ", name, ".", call. = FALSE)
  }
  rows <- rows[match(years, obs_years)]
  source_ref <- paste0("Fisheries New Zealand FAR 2025/48, Appendix A.2 Observation.csl2, @observation ", name)
  time_step <- settings$time_step
  time_prop <- suppressWarnings(as.numeric(settings$time_step_proportion))
  sampling_time <- if (length(time_prop) && is.finite(time_prop)) time_prop else NA_real_
  meta_note <- paste("Native Casal2 setting:", name, "uses time_step", time_step,
    if (is.finite(sampling_time)) paste("and time_step_proportion", sampling_time) else "with no within-step sampling proportion specified.")
  for (setting in names(settings)) {
    component <- if (meta$kind == "catch") "catch" else "index"
    add_assumption(component, paste0("observation[", name, "].", setting), settings[[setting]],
      source_ref, notes = if (setting == "error_value_multiplier")
        "Likelihood multiplier retained separately from raw sample_size values on age-composition cells." else meta_note,
      fleet = if (is.null(meta$fleet)) "" else meta$fleet,
      survey = if (is.null(meta$survey)) "" else meta$survey,
      region = meta$region, season = if (setting == "time_step") time_step else "")
  }

  if (name == "Tangaroa_bio") {
    if (any(lengths(rows) != 3L)) stop("Unexpected Tangaroa biomass observation dimensions.", call. = FALSE)
    for (row in rows) {
      add_input("index", "total_biomass", "biomass", row[2L], "tonnes",
        year = row[1L], survey = meta$survey, region = meta$region,
        season = time_step, sampling_time = sampling_time,
        source_reference = paste(source_ref, "table obs"),
        notes = "Aggregate January Tangaroa summer-trawl biomass index; the third source column is its CV.")
      add_input("index", "biomass_index_cv", "relative_scale", row[3L], "ratio",
        year = row[1L], survey = meta$survey, region = meta$region,
        season = time_step, sampling_time = sampling_time,
        source_reference = paste(source_ref, "table obs"),
        notes = "Source biomass-index CV paired with the aggregate biomass observation; likelihood is lognormal.")
    }
  } else {
    ages <- seq.int(as.integer(settings$min_age), as.integer(settings$max_age))
    categories <- settings$categories
    separate_sexes <- identical(categories, "male female")
    combined_sexes <- identical(categories, "male+female")
    if (!separate_sexes && !combined_sexes) stop("Unrecognized sex categories for ", name, ".", call. = FALSE)
    sex_order <- if (separate_sexes) c("M", "F") else ""
    expected_cells <- length(ages) * length(sex_order)
    if (!expected_cells) expected_cells <- length(ages)
    if (any(lengths(rows) != expected_cells + 1L)) stop("Unexpected age-composition dimensions for ", name, ".", call. = FALSE)
    errors <- table_rows(block$lines, "error_values", years)
    error_years <- vapply(errors, `[[`, numeric(1), 1L)
    if (anyDuplicated(error_years) || !setequal(error_years, years) || any(lengths(errors) != 2L)) {
      stop("Raw sample-size rows do not match the age-composition years for ", name, ".", call. = FALSE)
    }
    raw_sizes <- vapply(errors[match(years, error_years)], `[[`, numeric(1), 2L)
    composition_note <- paste(
      "Native Casal2 multinomial composition, not catch numbers-at-age or an abundance index.",
      if (separate_sexes) "Cells are ordered male ages, then female ages." else "The likelihood combines sexes; the composition has no sex-specific age cells.",
      "sample_size is the raw Casal2 error_values entry; error_value_multiplier is recorded separately as an assumption.",
      if (settings$plus_group == "T") paste0("Age ", max(ages), " is the source plus group.") else ""
    )
    sums <- vapply(rows, function(row) sum(row[-1L]), numeric(1))
    if (any(abs(sums - 1) > 0.001)) stop("A source age-composition vector does not sum to one within report rounding for ", name, ".", call. = FALSE)
    for (i in seq_along(rows)) {
      values <- rows[[i]][-1L]
      for (s in seq_along(sex_order)) for (a in seq_along(ages)) {
        cell <- if (separate_sexes) values[(s - 1L) * length(ages) + a] else values[a]
        add_input(meta$kind, "proportion_at_age", "proportion_numbers", cell, "proportion",
          year = years[i], age = ages[a], fleet = if (is.null(meta$fleet)) "" else meta$fleet,
          survey = if (is.null(meta$survey)) "" else meta$survey,
          sex = sex_order[s], region = meta$region, season = time_step,
          sampling_time = sampling_time, source_reference = paste(source_ref, "table obs"),
          notes = composition_note,
          observation_id = paste0("lin34_", name, "_", years[i]), sample_size = raw_sizes[i])
      }
    }
  }
}

population_named_blocks <- population_blocks
names(population_named_blocks) <- vapply(population_named_blocks, `[[`, character(1), "name")
maturity_inputs <- 0L
for (sex_name in c("male", "female")) {
  selectivity_name <- paste0("MaturationSel_", sex_name)
  block <- population_named_blocks[[selectivity_name]]
  if (is.null(block)) stop("Missing maturity selectivity: ", selectivity_name, call. = FALSE)
  values <- suppressWarnings(as.numeric(strsplit(field_value(block$lines, "v"), "\\s+")[[1L]]))
  ages <- 3:15
  if (length(values) != length(ages) || anyNA(values) || any(values < 0 | values > 1)) {
    stop("Unexpected base maturity ogive dimensions for ", sex_name, ".", call. = FALSE)
  }
  add_input("maturity", "maturity_at_age", "proportion", values, "proportion",
    age = ages, sex = if (sex_name == "male") "M" else "F", region = "Chatham Rise",
    source_reference = paste("Fisheries New Zealand FAR 2025/48, Table 3 and Appendix A.1 Population.csl2,", selectivity_name),
    notes = "Base-case maturity ogive from Horn (2005); age 15 is the 15+ plus group.")
  maturity_inputs <- maturity_inputs + length(values)
}

component_for <- function(type, name) {
  if (type == "model" || type %in% c("categories", "initialisation_phase", "time_step", "derived_quantity")) return("population")
  if (type == "process" && name == "Recruitment") return("recruitment")
  if (type == "process" && name == "Fishing") return("mortality")
  if (type == "observation") return(if (grepl("propn_at_age", name)) if (grepl("^Tangaroa", name)) "index" else "catch" else "index")
  if (type %in% c("selectivity", "age_length", "length_weight", "ageing_error")) return("biology")
  if (type == "catchability") return("catchability")
  if (type %in% c("estimate", "mcmc", "minimiser", "parameter_transformation")) return("estimation")
  type
}
other_observation_blocks <- observation_blocks[vapply(observation_blocks, `[[`, character(1), "type") != "observation"]
all_blocks <- c(population_blocks, other_observation_blocks, estimation_blocks)
for (block in all_blocks) {
  settings <- parse_settings(block)
  if (!length(settings)) next
  component <- component_for(block$type, block$name)
  source_part <- if (block$type == "observation") "Appendix A.2 Observation.csl2" else if (block$type %in% c("estimate", "mcmc", "minimiser", "parameter_transformation")) "Appendix A.3 Estimation.csl2" else "Appendix A.1 Population.csl2"
  source_ref <- paste("Fisheries New Zealand FAR 2025/48,", source_part, paste0("@", block$type, " ", block$name))
  fleet <- switch(block$name,
    trawl_propn_at_age = "Commercial trawl",
    longline_propn_at_age = "Commercial longline",
    "")
  survey <- if (grepl("^Tangaroa", block$name)) "Tangaroa summer trawl survey" else ""
  sex <- if (grepl("_male$", block$name)) "M" else if (grepl("_female$", block$name)) "F" else ""
  for (setting in names(settings)) {
    note <- if (block$type == "process" && block$name == "Fishing" && setting == "m") {
      "Initial values for the estimated sex-specific M parameters; M is not fixed at these values."
    } else if (block$type == "selectivity" && block$name == "M_all") {
      "Constant relative M-at-age selectivity; natural mortality is estimated sex-specific and constant at age."
    } else "Native Casal2 model setting, parameter, or prior retained in its source order."
    add_assumption(component, paste0(block$type, "[", block$name, "].", setting), settings[[setting]],
      source_ref, notes = note, fleet = fleet, survey = survey, sex = sex,
      region = "Chatham Rise", season = if (setting == "time_step") settings[[setting]] else "")
  }
}
add_assumption("population", "commercial_age_composition_sex_handling",
  "Commercial trawl and longline age compositions are combined across sexes; survey age compositions are sex-specific.",
  "Fisheries New Zealand FAR 2025/48, section 3.1.3 and Appendix A.2",
  notes = "The selected base model uses combined-sex commercial age-frequency observations and separate-sex survey age frequencies.")
add_assumption("population", "pot_selectivity",
  "Pot fishery uses the longline selectivity ogives.",
  "Fisheries New Zealand FAR 2025/48, Appendix A.1 Population.csl2, table method",
  notes = "No pot age data were available; the report attributes this assumption to the single observed potting trip.", fleet = "Commercial pot")
add_assumption("population", "excluded_CPUE_series",
  "Bottom longline and scampi-target trawl CPUE were not used in the 2025 base model.",
  "Fisheries New Zealand FAR 2025/48, section 3.1.3 and FAR 2025/47 summary",
  notes = "The assessment describes the longline CPUE trend as inconsistent with the research trawl survey series.")
add_assumption("recruitment", "estimated_year_class_strengths",
  "Year-class strengths were estimated for cohorts spawning in 1975–2016 and fixed at 1 for 2021–2025 during model estimation; projection recruitment resampled year-class strengths.",
  "Fisheries New Zealand FAR 2025/48, section 2.1 and Appendix A.1 Population.csl2",
  notes = "The report describes recruitment as Beverton–Holt with steepness 0.84 and recruitment variability sigma_R 0.6.")
add_assumption("timing", "commercial_age_observation_timing_review",
  "The embedded Casal2 commercial trawl and longline age-composition blocks specify time_step S1; the report's annual-cycle table places commercial catch-at-age observations in step 2 (July–December).",
  "Fisheries New Zealand FAR 2025/48, Table 1 and Appendix A.2 Observation.csl2",
  notes = "No within-year sampling fraction is specified for the commercial compositions. The source discrepancy is retained unresolved; no sampling_time was inferred.")

outputs <- list()
add_output("biomass", "unfished_spawning_biomass", 114384, "tonnes",
  lwr = 103473, upr = 138315,
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 9 (printed p. 18)",
  notes = "Bayesian median of the marginal posterior and 95% credible interval for the selected base model.")
add_output("biomass", "SSB", 66638, "tonnes", year = 2025,
  lwr = 50671, upr = 94693,
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 9 (printed p. 18)",
  notes = "Bayesian median of current 2025 spawning biomass and 95% credible interval for the selected base model.")
add_output("biomass", "SSB_ratio_to_B0", 58.3, "percent", year = 2025,
  lwr = 48.8, upr = 68.9,
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 9 (printed p. 18)",
  notes = "Reported Bayesian median and 95% credible interval for B2025/B0; values are percentages.")
add_output("biomass", "probability_above_40_percent_B0", 1, "probability", year = 2025,
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 9 (printed p. 18)",
  notes = "Reported posterior probability that B2025 exceeds 40% of B0.")
add_output("biomass", "probability_below_20_percent_B0", 0, "probability", year = 2025,
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 9 (printed p. 18)",
  notes = "Reported posterior probability that B2025 is below 20% of B0.")
add_output("mortality", "natural_mortality_average_parameter", 0.150, "yr-1",
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 8 (printed p. 13), selected base-model row",
  notes = "MPD estimate of Mavg for the selected base model. M is sex-specific and constant at age; the report does not provide uncertainty for this parameter in Table 8.")
add_output("mortality", "natural_mortality_sex_difference_parameter", -0.007, "yr-1",
  source_reference = "Fisheries New Zealand FAR 2025/48, Table 8 (printed p. 13), selected base-model row",
  notes = "MPD estimate of Mdiff for the selected base model, reported as the male–female difference parameter. The parameter is retained as reported and is not expanded into an M-at-age surface.")

projection_scenarios <- data.frame(
  label = c("All year-class strengths; 2022–2024 catch mix", "2007–2016 year-class strengths; 2022–2024 catch mix",
    "All year-class strengths; TACC catches", "2007–2016 year-class strengths; TACC catches"),
  biomass = c(63477, 60292, 51895, 48663),
  biomass_lwr = c(46612, 43818, 34749, 31954),
  biomass_upr = c(91951, 87496, 80784, 76220),
  percent_b0 = c(55, 53, 45, 42),
  percent_b0_lwr = c(44, 42, 33, 30),
  percent_b0_upr = c(69, 65, 60, 56),
  percent_b2025 = c(95, 92, 81, 77),
  percent_b2025_lwr = c(86, 83, 69, 65),
  percent_b2025_upr = c(110, 101, 96, 88),
  probability_40 = c(1, 0.99, 0.79, 0.65),
  probability_20 = c(0, 0, 0, 0),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(projection_scenarios))) {
  scenario_note <- paste("Projection scenario:", projection_scenarios$label[i],
    if (grepl("TACC", projection_scenarios$label[i], fixed = TRUE))
      "Future catch totals were 2,191 t trawl, 2,387 t longline, and 1,682 t pot." else
      "Future catch totals used the 2022–2024 fishery mix: 1,248 t trawl, 1,359 t longline, and 958 t pot.")
  add_output("biomass", "SSB", projection_scenarios$biomass[i], "tonnes", year = 2030,
    lwr = projection_scenarios$biomass_lwr[i], upr = projection_scenarios$biomass_upr[i],
    scenario = projection_scenarios$label[i],
    source_reference = "Fisheries New Zealand FAR 2025/48, Table 10 (printed p. 22)",
    notes = paste("Bayesian median and 95% credible interval.", scenario_note))
  add_output("biomass", "SSB_ratio_to_B0", projection_scenarios$percent_b0[i], "percent", year = 2030,
    lwr = projection_scenarios$percent_b0_lwr[i], upr = projection_scenarios$percent_b0_upr[i],
    scenario = projection_scenarios$label[i],
    source_reference = "Fisheries New Zealand FAR 2025/48, Table 10 (printed p. 22)",
    notes = paste("Reported median and 95% credible interval; values are percentages.", scenario_note))
  add_output("biomass", "SSB_ratio_to_terminal_biomass", projection_scenarios$percent_b2025[i], "percent", year = 2030,
    lwr = projection_scenarios$percent_b2025_lwr[i], upr = projection_scenarios$percent_b2025_upr[i],
    scenario = projection_scenarios$label[i],
    source_reference = "Fisheries New Zealand FAR 2025/48, Table 10 (printed p. 22)",
    notes = paste("Reported B2030/B2025 median and 95% credible interval; values are percentages.", scenario_note))
  add_output("biomass", "probability_above_40_percent_B0", projection_scenarios$probability_40[i], "probability", year = 2030,
    scenario = projection_scenarios$label[i],
    source_reference = "Fisheries New Zealand FAR 2025/48, Table 10 (printed p. 22)", notes = scenario_note)
  add_output("biomass", "probability_below_20_percent_B0", projection_scenarios$probability_20[i], "probability", year = 2030,
    scenario = projection_scenarios$label[i],
    source_reference = "Fisheries New Zealand FAR 2025/48, Table 10 (printed p. 22)", notes = scenario_note)
}

inputs <- do.call(rbind, input_rows)
assumptions <- do.call(rbind, assumption_rows)
outputs <- do.call(rbind, output_rows)
if (nrow(inputs) != 2540L || nrow(assumptions) != 225L || nrow(outputs) != 27L || maturity_inputs != 26L) {
  stop("Unexpected LIN 3&4 import dimensions: ", nrow(inputs), " inputs, ", nrow(assumptions),
    " assumptions, ", nrow(outputs), " outputs, and ", maturity_inputs, " maturity values.", call. = FALSE)
}
composition <- inputs[inputs$measure == "proportion_at_age", ]
composition_sums <- tapply(as.numeric(composition$value), composition$observation_id, sum)
if (length(composition_sums) != 76L || max(abs(composition_sums - 1)) > 0.001) {
  stop("Unexpected composition coverage or report-rounding range.", call. = FALSE)
}

new_stock <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "LIN 3&4", scientific_name = "Genypterus blacodes", common_name = "Chatham Rise ling",
  area = "Chatham Rise (Fishstocks LIN 3 and LIN 4)", region = "New Zealand waters",
  ocean = "Southwest Pacific", notes = "LIN 3&4 is the Chatham Rise management unit; it is distinct from other New Zealand ling stocks.",
  stringsAsFactors = FALSE)
new_assessment <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2030L,
  assessment_type = "full_assessment", model_family = "Casal2", model_version = "2025 base case; Casal2 version not stated",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://fs.fish.govt.nz/Doc/26148/FAR-2025-48-Stock-assessment-of-Chatham-Rise-ling-2025.pdf.ashx",
  framework_url = "", data_url = "https://fs.fish.govt.nz/Doc/26147/FAR-2025-47-Descriptive-analysis-LIN34-to-2023-24-and-inputs-for-2025-stock-assessment.pdf.ashx",
  model_url = "", repository_url = "", assumptions_status = "complete", inputs_status = "complete", outputs_status = "partial",
  notes = paste("The 2025 production assessment was used for advice and includes the Casal2 base-case input files.",
    "Observed data end in 2024; the model includes an assumed 2025 catch equal to the 2022–2024 average and reports projections through 2030.",
    "Numerical annual N-at-age and F-at-age arrays are not tabulated in the detailed report."), stringsAsFactors = FALSE)

stream_has_id <- function(path, id) {
  con <- file(path, open = "r")
  on.exit(close(con))
  prefix <- paste0('"', id, '"')
  repeat {
    chunk <- readLines(con, n = 20000L, warn = FALSE)
    if (!length(chunk)) return(FALSE)
    if (any(startsWith(chunk, prefix))) return(TRUE)
  }
}
append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
replace_register_row <- function(path, id_field, id, update) {
  register <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  selected <- which(register[[id_field]] == id)
  if (length(selected) != 1L) stop("Expected one register record for ", id, ".", call. = FALSE)
  for (field in names(update)) register[[field]][selected] <- update[[field]]
  write.csv(register, path, row.names = FALSE, na = "")
}

if (write_mode) {
  db <- file.path(root, "database")
  for (file_name in c("stocks.csv", "assessments.csv", "inputs.csv", "assumptions.csv", "outputs.csv")) {
    id <- if (file_name == "stocks.csv") stock_id else assessment_id
    if (stream_has_id(file.path(db, file_name), id)) stop("Refusing to duplicate ", id, " in ", file_name, ".", call. = FALSE)
  }
  stocks <- read.csv(file.path(db, "stocks.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  if (any(stocks$authority == new_stock$authority & stocks$authority_stock_id == new_stock$authority_stock_id)) {
    stop("LIN 3&4 already has a canonical stock record; review identity before importing.", call. = FALSE)
  }
  append_csv(new_stock, file.path(db, "stocks.csv"))
  append_csv(new_assessment, file.path(db, "assessments.csv"))
  append_csv(assumptions, file.path(db, "assumptions.csv"))
  append_csv(outputs, file.path(db, "outputs.csv"))
  append_csv(inputs, file.path(db, "inputs.csv"))
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  replace_register_row(file.path(root, "discovery", "candidates.csv"), "candidate_id", candidate_id, list(
    matched_stock_id = stock_id,
    import_status = "partial",
    catch_age_evidence = "Imported the native fishery catch-biomass series and separate sexed/combined-sex composition observations. The model does not use direct catch numbers-at-age; no reconstructed numbers were added to the canonical inputs.",
    survey_age_evidence = "Imported the aggregate Tangaroa January biomass index and CV plus sex-specific survey age compositions for 1992–2014, 2016, 2018, 2020, 2022, and 2024.",
    weights_evidence = "No direct weight-at-age input table was found. The assessment supplies sex-specific von Bertalanffy growth and length-weight functions, retained as model assumptions.",
    maturity_evidence = "Imported the base Horn (2005) male and female maturity-at-age vectors, including the 15+ group. The separate age-7 maturity sensitivity was not mixed into the base run.",
    mortality_evidence = "Natural mortality is estimated as sex-specific and constant at age; Table 8 reports MPD Mavg 0.150 and Mdiff -0.007. Annual numerical M-at-age arrays are not tabulated.",
    timing_evidence = "Calendar-year model; Tangaroa summer survey sampling time is 0.2. The commercial age-composition time_step differs between the embedded input blocks and Table 1; no fraction was inferred.",
    output_evidence = "Imported posterior B0 and B2025 with 95% credible intervals, B2025/B0, Table 8 M parameter estimates, and Table 10 B2030 projection summaries. Annual numerical N-at-age and F-at-age arrays are not tabulated."
  ))
  replace_register_row(file.path(root, "discovery", "selected_batch_02_2026.csv"), "candidate_id", candidate_id,
    list(curation_status = "partial_source_import"))
}

cat("LIN 3&4 source import ", if (write_mode) "written" else "validated (dry run)", ": ",
  nrow(inputs), " inputs, ", nrow(assumptions), " assumptions, ", nrow(outputs),
  " outputs; 162 catch records, 2,296 age-composition cells, 56 survey biomass/CV records, and 26 maturity values.\n", sep = "")
