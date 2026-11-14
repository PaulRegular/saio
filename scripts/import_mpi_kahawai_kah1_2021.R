source("R/read_database.R")
.libPaths(c(file.path("source_cache", "rlib"), .libPaths()))

assessment_id <- "mpi_kahawai_kah1_2021"
stock_id <- "mpi_kahawai_kah1"
candidate_id <- "MPI:KAH1"
report <- file.path("source_cache", "mpi_kahawai_kah1_2021", "FAR2022-54.pdf")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(report)) stop("The cached FAR 2022/54 report is required.")
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached assessment appendix.")
}
if (!identical(
  toupper(unname(tools::sha256sum(report))),
  "D3A6DC8BB710AC13CD520BB7D188A15850302C9EB334DA3AC59C0F575EE02DEA"
)) stop("The cached report does not match the reviewed source.")

pdf_pages <- pdftools::pdf_data(report)
pdf_text <- pdftools::pdf_text(report)
lines <- trimws(unlist(lapply(pdf_text, function(x) {
  strsplit(x, "\n", fixed = TRUE)[[1]]
}), use.names = FALSE))

parse_catches <- function() {
  markers <- do.call(rbind, lapply(seq_along(pdf_pages), function(page) {
    d <- pdf_pages[[page]]
    at <- which(d$text == "@fishery")
    if (!length(at)) return(NULL)
    data.frame(page = page, y = d$y[at], fleet = d$text[at + 1L])
  }))
  if (nrow(markers) != 9L) stop("Expected nine CASAL catch fleets.")
  rows <- list()
  for (i in seq_len(nrow(markers))) {
    marker <- markers[i, ]
    values <- numeric()
    started <- FALSE
    ended <- FALSE
    for (page in marker$page:length(pdf_pages)) {
      d <- pdf_pages[[page]]
      d <- d[order(d$y, d$x), ]
      if (!started) {
        at <- which(d$text == "catches" & d$y >= marker$y)
        if (!length(at)) next
        y_start <- d$y[at[1L]]
        started <- TRUE
      } else {
        y_start <- -Inf
      }
      at <- which(d$text == "selectivity" & d$y >= y_start)
      y_end <- if (length(at)) d$y[at[1L]] else 760
      selected <- d[
        d$y >= y_start & d$y < y_end &
          grepl("^-?[0-9]+([.][0-9]+)?$", d$text),
        , drop = FALSE
      ]
      values <- c(values, as.numeric(selected$text[order(selected$y, selected$x)]))
      if (length(at)) {
        ended <- TRUE
        break
      }
    }
    if (!started || !ended || length(values) != 91L || any(values < 0)) {
      stop("Catch vector failed for fleet ", marker$fleet, ".")
    }
    rows[[i]] <- data.frame(
      fleet = marker$fleet, year = 1930:2020, value = values,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

field_value <- function(block, field) {
  hit <- grep(paste0("^", field, "[[:space:]]+"), block, value = TRUE)
  if (!length(hit)) stop("Missing appendix field: ", field)
  sub(paste0("^", field, "[[:space:]]+"), "", hit[1L])
}

parse_compositions <- function() {
  starts <- grep("^@catch_at[[:space:]]+", lines)
  ends <- grep("^@catch_limit_penalty\\b", lines)
  if (length(starts) != 7L || !length(ends)) {
    stop("Expected seven CASAL age-composition blocks.")
  }
  result <- list()
  for (i in seq_along(starts)) {
    end <- if (i < length(starts)) starts[i + 1L] - 1L else min(ends) - 1L
    block <- lines[starts[i]:end]
    name <- sub("^@catch_at[[:space:]]+", "", block[1L])
    fleet <- field_value(block, "fishery")
    min_age <- as.integer(field_value(block, "min_class"))
    max_age <- as.integer(field_value(block, "max_class"))
    plus_group <- tolower(field_value(block, "plus_group")) == "true"
    r_line <- grep("^r[[:space:]]+", block)
    sample_lines <- grep("^N_[0-9]{4}[[:space:]]+", block)
    if (length(r_line) != 1L || !length(sample_lines)) {
      stop("Age-composition block is incomplete: ", name)
    }
    body_end <- sample_lines[1L] - 1L
    body <- block[(r_line + 1L):body_end]
    samples <- list()
    current_year <- NA_integer_
    current_values <- numeric()
    store <- function() {
      if (is.na(current_year)) return()
      expected <- max_age - min_age + 1L
      if (length(current_values) != expected) {
        stop(name, " ", current_year, " has an invalid age count.")
      }
      samples[[as.character(current_year)]] <<- current_values
    }
    for (line in body) {
      parts <- strsplit(line, "[[:space:]]+")[[1]]
      if (!length(parts)) next
      if (grepl("^(19|20)[0-9]{2}$", parts[1L])) {
        store()
        current_year <- as.integer(parts[1L])
        current_values <- if (length(parts) > 1L) as.numeric(parts[-1L]) else numeric()
      } else if (!is.na(current_year) &&
        all(grepl("^-?([0-9]+([.][0-9]*)?|[.][0-9]+)$", parts))) {
        current_values <- c(current_values, as.numeric(parts))
      }
    }
    store()
    sample_years <- as.integer(sub("^N_([0-9]{4}).*$", "\\1", block[sample_lines]))
    sample_sizes <- as.numeric(sub("^N_[0-9]{4}[[:space:]]+", "", block[sample_lines]))
    if (!setequal(names(samples), as.character(sample_years)) ||
      anyDuplicated(sample_years) || any(sample_sizes <= 0)) {
      stop("Composition years and effective sample sizes do not align: ", name)
    }
    sums <- vapply(samples, sum, numeric(1))
    if (any(abs(sums - 1) > 0.05)) {
      stop("Composition proportions do not sum to one: ", name)
    }
    result[[name]] <- list(
      fleet = fleet, min_age = min_age, max_age = max_age,
      plus_group = plus_group, years = sample_years,
      values = samples,
      sample_sizes = setNames(sample_sizes, as.character(sample_years))
    )
  }
  result
}

parse_indices <- function() {
  starts <- grep("^@relative_abundance[[:space:]]+", lines)
  if (length(starts) != 4L) stop("Expected four aggregate index series.")
  result <- list()
  for (i in seq_along(starts)) {
    next_blocks <- grep("^@", lines)
    end <- next_blocks[next_blocks > starts[i]][1L] - 1L
    if (is.na(end)) end <- length(lines)
    block <- lines[starts[i]:end]
    name <- sub("^@relative_abundance[[:space:]]+", "", block[1L])
    biomass <- tolower(field_value(block, "biomass")) == "true"
    timing <- as.numeric(field_value(block, "proportion_mortality"))
    distribution <- field_value(block, "dist")
    q <- field_value(block, "q")
    cv <- as.numeric(field_value(block, "cv"))
    data_lines <- grep("^(19|20)[0-9]{2}[[:space:]]+[-+]?[0-9]*\\.?[0-9]+$", block, value = TRUE)
    values <- do.call(rbind, lapply(data_lines, function(line) {
      parts <- strsplit(line, "[[:space:]]+")[[1]]
      data.frame(year = as.integer(parts[1L]), value = as.numeric(parts[2L]))
    }))
    if (anyDuplicated(values$year) || any(values$value < 0) ||
      timing != 0.5 || distribution != "lognormal" || cv <= 0) {
      stop("Index series failed validation: ", name)
    }
    result[[name]] <- list(
      name = name, biomass = biomass, timing = timing,
      distribution = distribution, q = q, cv = cv, values = values
    )
  }
  result
}

catches <- parse_catches()
compositions <- parse_compositions()
indices <- parse_indices()

input_row <- function(type, measure, basis, value, unit, year,
                      fleet = NA_character_, survey = NA_character_,
                      age = NA_character_, sampling_time = NA_character_,
                      observation_id = NA_character_,
                      sample_size = NA_character_, notes = "",
                      source_reference = "") {
  data.frame(
    assessment_id = assessment_id,
    type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = NA_character_, region = "K1",
    season = "annual", year = as.character(year), year_basis = "model_year",
    age = as.character(age), value = as.character(value), unit = unit,
    sampling_time = as.character(sampling_time), source_type = "native_model",
    source_reference = source_reference, transformation = "",
    notes = notes, observation_id = observation_id,
    sample_size = as.character(sample_size),
    stringsAsFactors = FALSE
  )
}

catch_inputs <- do.call(rbind, lapply(seq_len(nrow(catches)), function(i) {
  z <- catches[i, ]
  input_row(
    "catch", "landings_biomass", "biomass", z$value, "tonnes", z$year,
    fleet = z$fleet, observation_id = paste(z$fleet, z$year, sep = "_"),
    notes = paste(
      "CASAL catch-biomass input, preserving the original model-year label.",
      "The report describes the fitted data period as fishing years 1930-31 to 2019-20."
    ),
    source_reference = "FAR 2022/54, Appendix 4, pp. 53-56"
  )
}))

composition_inputs <- do.call(rbind, lapply(names(compositions), function(name) {
  z <- compositions[[name]]
  do.call(rbind, lapply(z$years, function(year) {
    values <- z$values[[as.character(year)]]
    do.call(rbind, lapply(seq_along(values), function(j) {
      input_row(
        "catch", "proportion_at_age", "proportion_numbers",
        values[j], "proportion", year, fleet = z$fleet,
        age = z$min_age + j - 1L,
        observation_id = paste(z$fleet, year, "age", sep = "_"),
        sample_size = z$sample_sizes[[as.character(year)]],
        notes = paste0(
          "Sampled catch age composition; not catch numbers-at-age. ",
          "Effective sample size is the down-weighted CASAL value. Reported proportions are rounded and are not renormalized. ",
          name, " plus_group=", z$plus_group, "."
        ),
        source_reference = "FAR 2022/54, Appendix 4, pp. 61-63"
      )
    }))
  }))
}))

index_inputs <- do.call(rbind, lapply(names(indices), function(name) {
  z <- indices[[name]]
  measure <- if (z$biomass) "relative_biomass_index" else "relative_abundance_index"
  cv_measure <- if (z$biomass) "biomass_index_cv" else "abundance_index_cv"
  do.call(rbind, lapply(seq_len(nrow(z$values)), function(i) {
    value <- z$values[i, ]
    common <- list(
      survey = name, year = value$year, sampling_time = z$timing,
      source_reference = "FAR 2022/54, Appendix 4, pp. 59-60"
    )
    observation <- do.call(input_row, c(list(
      type = "index", measure = measure, basis = "index_scale",
      value = value$value, unit = "relative index scale",
      observation_id = paste(name, value$year, sep = "_"),
      notes = paste0(
        "Aggregate ", if (z$biomass) "biomass" else "abundance",
        " index on its native CASAL scale; no absolute multiplier is reported. ",
        "q field ", z$q, "; lognormal likelihood; proportion_mortality=",
        z$timing, "."
      )
    ), common))
    precision <- do.call(input_row, c(list(
      type = "index", measure = cv_measure, basis = "relative_scale",
      value = z$cv, unit = "ratio",
      observation_id = paste(name, value$year, sep = "_CV_"),
      notes = paste(
        "Constant series-level coefficient of variation from the CASAL input;",
        "repeated by year to match the corresponding index observations."
      )
    ), common))
    rbind(observation, precision)
  }))
}))

inputs <- rbind(catch_inputs, composition_inputs, index_inputs)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = "K1", season = NA_character_, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("population", "model_age_range", "Ages 1-20; age 20 is a plus group; one sex partition, one area, one stock", "FAR 2022/54, Appendix 4, p. 52"),
  assumption("population", "model_year_range", "Model years 1930-2020; initial=1930, current=2020, final=2025", "FAR 2022/54, Appendix 4, p. 52", "The report describes observed data through fishing year 2019-20; model year labels are retained without conversion."),
  assumption("population", "fleets_as_areas", "Nine fleets represented as areas in one stock", "FAR 2022/54, Appendix 4, p. 52", "Fleet-area structure accommodates persistent regional age-composition differences."),
  assumption("population", "annual_cycle", "One annual step; spawning, ageing, recruitment and fisheries at step 1; spawning proportion mortality=0.5", "FAR 2022/54, Appendix 4, p. 52"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness=0.75; sigma_r=0.6", "FAR 2022/54, Appendix 4, p. 52"),
  assumption("recruitment", "year_class_strengths", "Standardised year-class strengths estimated for 1994-2014; lognormal prior with mean=1 and CV=1", "FAR 2022/54, Appendix 4, p. 52"),
  assumption("mortality", "natural_mortality", "Fixed M=0.22 per year in the base model; sensitivity models use 0.20 and 0.24", "FAR 2022/54, pp. 8, 13; Appendix 4, p. 52"),
  assumption("biology", "growth", "Von Bertalanffy length-at-age: k=0.35, t0=0.13, Linf=54.6, CV=0.1; lognormal size-at-age distribution", "FAR 2022/54, Appendix 4, p. 53"),
  assumption("biology", "length_weight", "Appendix 4: a=2.36e-08, b=2.89; report prose: a=0.0236, b=2.89", "FAR 2022/54, p. 13; Appendix 4, p. 53", "The report presents different numerical a coefficients in prose and CASAL input. Their unit conversion is not explicitly documented here; both source forms are preserved without conversion."),
  assumption("maturity", "maturity_at_age", "Fixed knife-edge maturity at age 4", "FAR 2022/54, p. 13; Appendix 4, p. 53"),
  assumption("observation", "catch_likelihood", "Annual catch biomass supplied to nine CASAL fleets; catch observations are in tonnes", "FAR 2022/54, Appendix 4, pp. 53-56"),
  assumption("observation", "age_composition_likelihood", "Multinomial sampled age compositions; effective sample sizes supplied by year and fleet after down-weighting", "FAR 2022/54, Appendix 4, pp. 61-63", "Composition vectors are not numbers-at-age; source max-age and plus-group settings are retained in input notes."),
  assumption("observation", "index_likelihood", "Four aggregate relative indices use lognormal likelihoods and proportion_mortality=0.5; q is a separate nuisance parameter for each series", "FAR 2022/54, Appendix 4, pp. 59-60"),
  assumption("selectivity", "Sel_REC_EN", "Logistic, parameters 3 and 0.25", "FAR 2022/54, Appendix 4, p. 57"),
  assumption("selectivity", "Sel_REC_HG_early", "Double normal, parameters 5, 3 and 10", "FAR 2022/54, Appendix 4, p. 57"),
  assumption("selectivity", "Sel_REC_HG_late", "Logistic, parameters 8 and 0.25", "FAR 2022/54, Appendix 4, p. 57"),
  assumption("selectivity", "Sel_REC_BP", "Logistic, parameters 3 and 0.25", "FAR 2022/54, Appendix 4, p. 57"),
  assumption("selectivity", "Sel_PS", "Logistic, parameters 4 and 0.25", "FAR 2022/54, Appendix 4, p. 57"),
  assumption("selectivity", "Sel_ST", "Double normal, parameters 10, 8 and 8", "FAR 2022/54, Appendix 4, p. 57"),
  assumption("selectivity", "Sel_SN", "Fixed double normal, parameters 3.450150, 0.596666 and 1.095420", "FAR 2022/54, Appendix 4, p. 57", "Appendix notes values fixed from a 3, 0.4 run."),
  assumption("selectivity", "Sel_all", "Fixed size-based knife-edge selectivity at age 1", "FAR 2022/54, Appendix 4, p. 57")
))

output <- function(measure, value, unit, lwr, upr, scenario, year = NA_character_,
                   notes = "") {
  data.frame(
    assessment_id = assessment_id, type = "biomass", measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = "K1", season = NA_character_, year = as.character(year),
    age = NA_character_, age_group = NA_character_, value = as.character(value),
    se = NA_character_, lwr = as.character(lwr), upr = as.character(upr),
    unit = unit, source_type = "official_table",
    source_reference = "FAR 2022/54, Table 9, p. 38",
    notes = notes, scenario = scenario, stringsAsFactors = FALSE
  )
}

scenario_values <- list(
  "fixed M=0.20" = list(
    b0 = c(37665, 34873, 41824), ssb = c(18975, 15533, 23661),
    target = c(19586, 18134, 21748), ratio_b0 = c(0.504, 0.445, 0.566),
    ratio_target = c(0.969, 0.857, 1.088)
  ),
  "base; fixed M=0.22" = list(
    b0 = c(37549, 34151, 43205), ssb = c(20880, 17050, 26796),
    target = c(19524, 17759, 22467), ratio_b0 = c(0.556, 0.499, 0.620),
    ratio_target = c(1.069, 0.960, 1.193)
  ),
  "fixed M=0.24" = list(
    b0 = c(37131, 33583, 43599), ssb = c(22299, 18115, 29016),
    target = c(19319, 17463, 22671), ratio_b0 = c(0.600, 0.534, 0.666),
    ratio_target = c(1.154, 1.037, 1.278)
  )
)

outputs <- do.call(rbind, lapply(names(scenario_values), function(scenario) {
  x <- scenario_values[[scenario]]
  rbind(
    output("unfished_spawning_biomass", x$b0[1], "tonnes", x$b0[2], x$b0[3],
      scenario, notes = "SSB0; MCMC median and 95% credible interval."),
    output("spawning_biomass", x$ssb[1], "tonnes", x$ssb[2], x$ssb[3],
      scenario, year = 2020, notes = "2020 spawning biomass; MCMC median and 95% credible interval."),
    output("target_spawning_biomass", x$target[1], "tonnes", x$target[2], x$target[3],
      scenario, notes = "52% of unfished spawning biomass target; MCMC median and 95% credible interval."),
    output("SSB_ratio_to_B0", x$ratio_b0[1], "ratio", x$ratio_b0[2], x$ratio_b0[3],
      scenario, year = 2020, notes = "SSB2020/SSB0; MCMC median and 95% credible interval."),
    output("SSB_ratio_to_target", x$ratio_target[1], "ratio", x$ratio_target[2], x$ratio_target[3],
      scenario, year = 2020, notes = "SSB2020/52% SSB target; MCMC median and 95% credible interval.")
  )
}))

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("KAH 1 source records are already present.")
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "Fisheries New Zealand", authority_stock_id = "KAH 1",
  scientific_name = "Arripis trutta", common_name = "Kahawai",
  area = "KAH 1, off the northeast North Island",
  region = "New Zealand east coast, northeast North Island",
  ocean = "Southwest Pacific",
  notes = "One KAH 1 stock unit; no Charbonneau-Keith catalogue match identified.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2021", terminal_year = "2020",
  estimate_terminal_year = "2020", assessment_type = "full_assessment",
  model_family = "CASAL", model_version = "Version not reported",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_character_,
  assessment_url = "https://www.mpi.govt.nz/dmsdocument/54118/direct",
  framework_url = NA_character_, data_url = NA_character_, model_url = NA_character_,
  repository_url = NA_character_, assumptions_status = "partial",
  inputs_status = "complete", outputs_status = "partial",
  notes = paste(
    "FAR 2022/54 documents the 2021 production assessment using data through",
    "the 2019-20 fishing year and publishes its CASAL input appendix.",
    "Canonical inputs preserve the appendix's catch biomass, aggregate indices,",
    "sampled age-composition likelihoods and effective sample sizes. Table 9",
    "provides scalar MCMC summaries only; annual numerical population surfaces",
    "were not tabulated. The source's prose and CASAL length-weight coefficients",
    "use different a values whose conversion is not documented."
  ),
  stringsAsFactors = FALSE
)

bind_schema <- function(rows, path) {
  schema <- names(read.csv(path, nrows = 0, check.names = FALSE))
  for (name in setdiff(schema, names(rows))) rows[[name]] <- NA_character_
  rows <- rows[schema]
  rows[] <- lapply(rows, as.character)
  rows
}

append_rows <- function(path, rows) {
  rows <- bind_schema(rows, path)
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    last <- readBin(con, "raw", n = 1L)
    close(con)
    if (!identical(last, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

cat(
  "Prepared ", nrow(inputs), " input rows: ",
  nrow(catch_inputs), " catches, ", nrow(composition_inputs),
  " composition values, and ", nrow(index_inputs), " index and CV rows; ",
  nrow(assumptions), " assumptions; ", nrow(outputs), " output rows.\n",
  sep = ""
)

if (write_mode) {
  append_rows("database/stocks.csv", stock)
  append_rows("database/assessments.csv", assessment)
  append_rows("database/inputs.csv", inputs)
  append_rows("database/assumptions.csv", assumptions)
  append_rows("database/outputs.csv", outputs)

  source("scripts/database/candidate_register_io.R")
  candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  candidate_row <- match(candidate_id, candidates$candidate_id)
  if (is.na(candidate_row) || candidates$import_status[candidate_row] != "not_started") {
    stop("The KAH 1 candidate is missing or has already been imported.")
  }
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  replace_candidate_register_row(
    "discovery/candidates.csv", candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id
  )

  selected <- read.csv("discovery/selected_batch_04_2026.csv",
    stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
  selected_row <- match(candidate_id, selected$candidate_id)
  if (is.na(selected_row)) stop("KAH 1 is missing from the selected batch.")
  selected$curation_status[selected_row] <- "partial"
  write.csv(selected, "discovery/selected_batch_04_2026.csv",
    row.names = FALSE, na = "")

  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("KAH 1 records and discovery summaries were written.\n")
}
