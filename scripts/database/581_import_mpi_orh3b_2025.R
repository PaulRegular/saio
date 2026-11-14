.libPaths(c(file.path("source_cache", "mpi_orh3b_2025", "Rlib"), .libPaths()))

assessment_id <- "mpi_orh3b_2025"
stock_id <- "mpi_orh3b_chatham_rise"
candidate_id <- "MPI:ORH3B"
source_dir <- file.path("source_cache", "mpi_orh3b_2025")
report <- file.path(
  source_dir,
  "FAR-2025-46-Stock-assessment-of-Chatham-Rise-orange-roughy-in-2025.pdf"
)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
report_hash <- "E0F81AF259FEDF4E3C35F84500CC32D83B76C499DCF21E90BE722AFA3E88D458"

if (!file.exists(report)) stop("The reviewed FAR 2025/46 report is required.", call. = FALSE)
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached assessment appendices.", call. = FALSE)
}
if (!identical(toupper(unname(tools::sha256sum(report))), report_hash)) {
  stop("The cached assessment report does not match the reviewed source.", call. = FALSE)
}

pdf_pages <- pdftools::pdf_text(report)
lines <- trimws(unlist(lapply(pdf_pages, function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1]]
}), use.names = FALSE))

numeric_tokens <- function(line) {
  tokens <- strsplit(trimws(line), "[[:space:]]+")[[1]]
  number <- "^-?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$"
  if (!length(tokens) || any(!grepl(number, tokens))) return(numeric())
  as.numeric(tokens)
}

parse_catches <- function() {
  starts <- grep("^table catches$", lines, ignore.case = TRUE)
  expected <- list(
    list(years = 1979:2025, fleets = c("boxflat", "hills", "andes", "south", "crack", "rekohu")),
    list(years = 1980:2025, fleets = "nwcr")
  )
  if (length(starts) != length(expected)) stop("Expected ESCR and NWCR catch tables.", call. = FALSE)

  result <- lapply(seq_along(starts), function(i) {
    start <- starts[[i]]
    end <- which(seq_along(lines) > start & lines == "end_table")[[1]]
    header <- strsplit(lines[[start + 1L]], "[[:space:]]+")[[1]]
    if (!identical(header[-1L], expected[[i]]$fleets)) {
      stop("Unexpected modeled catch-area columns.", call. = FALSE)
    }
    rows <- lapply(lines[(start + 2L):(end - 1L)], function(line) {
      if (!grepl("^(19|20)[0-9]{2}[[:space:]]+", line)) return(NULL)
      values <- numeric_tokens(line)
      if (length(values) != length(header)) return(NULL)
      values
    })
    rows <- Filter(Negate(is.null), rows)
    values <- do.call(rbind, rows)
    if (!identical(as.integer(values[, 1]), expected[[i]]$years) ||
        any(!is.finite(values)) || any(values[, -1, drop = FALSE] < 0)) {
      stop("A catch table has missing years or invalid biomass values.", call. = FALSE)
    }
    data.frame(
      region = if (i == 1L) "ESCR" else "NWCR",
      year = rep(expected[[i]]$years, each = length(expected[[i]]$fleets)),
      fleet = rep(expected[[i]]$fleets, times = length(expected[[i]]$years)),
      value = as.vector(t(values[, -1, drop = FALSE])),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, result)
}

observation_blocks <- function() {
  starts <- grep("^@observation[[:space:]]+", lines)
  all_at <- grep("^@", lines)
  lapply(seq_along(starts), function(i) {
    start <- starts[[i]]
    next_at <- all_at[all_at > start][1L]
    end <- if (is.na(next_at)) length(lines) else next_at - 1L
    lines[start:end]
  }) |> setNames(vapply(starts, function(i) {
    sub("^@observation[[:space:]]+", "", lines[[i]])
  }, character(1)))
}

field_value <- function(block, field) {
  hit <- grep(paste0("^", field, "[[:space:]]+"), block, value = TRUE)
  if (!length(hit)) stop("Missing observation field: ", field, call. = FALSE)
  sub(paste0("^", field, "[[:space:]]+"), "", hit[[1L]])
}

table_lines <- function(block, table_name) {
  start <- grep(paste0("^table ", table_name, "$"), block, ignore.case = TRUE)
  if (length(start) != 1L) stop("Expected one table ", table_name, ".", call. = FALSE)
  end <- which(seq_along(block) > start & block == "end_table")[[1L]]
  block[(start + 1L):(end - 1L)]
}

parse_index <- function(block, name) {
  years <- as.integer(strsplit(field_value(block, "years"), "[[:space:]]+")[[1]])
  data <- lapply(table_lines(block, "obs"), function(line) {
    values <- numeric_tokens(line)
    if (length(values) == 3L && values[[1L]] %in% years) values else NULL
  })
  data <- Filter(Negate(is.null), data)
  values <- do.call(rbind, data)
  if (nrow(values) != length(years) || !identical(as.integer(values[, 1]), years) ||
      any(values[, 2:3, drop = FALSE] <= 0)) {
    stop("Invalid acoustic biomass table: ", name, call. = FALSE)
  }
  list(
    years = years, biomass = values[, 2], cv = values[, 3],
    process_error = as.numeric(field_value(block, "process_error")),
    timing = as.numeric(field_value(block, "time_step_proportion")),
    region = if (grepl("^aco_", name)) "NWCR" else "ESCR",
    survey = switch(name,
      osp38 = "ESCR Old Spawning Plume acoustic 38 kHz",
      combined38 = "ESCR combined acoustic 38 kHz",
      combined120 = "ESCR combined acoustic 120 kHz",
      aco_38 = "NWCR acoustic 38 kHz",
      aco_120 = "NWCR acoustic 120 kHz",
      stop("Unexpected acoustic observation: ", name, call. = FALSE)
    ),
    name = name
  )
}

parse_composition <- function(block, name) {
  years <- as.integer(strsplit(field_value(block, "years"), "[[:space:]]+")[[1]])
  min_age <- as.integer(field_value(block, "min_age"))
  max_age <- as.integer(field_value(block, "max_age"))
  plus_group <- tolower(field_value(block, "plus_group")) == "true"
  timing <- as.numeric(field_value(block, "time_step_proportion"))
  raw <- table_lines(block, "obs")
  values_by_year <- list()
  current_year <- NA_integer_
  current_values <- numeric()
  store <- function() {
    if (is.na(current_year)) return()
    values_by_year[[as.character(current_year)]] <<- current_values
  }
  for (line in raw) {
    values <- numeric_tokens(line)
    if (!length(values)) next
    year_token <- as.integer(values[[1L]])
    if (length(values) > 1L && year_token %in% years) {
      store()
      current_year <- year_token
      current_values <- values[-1L]
    } else if (!is.na(current_year)) {
      current_values <- c(current_values, values)
    }
  }
  store()

  error_lines <- table_lines(block, "error_values")
  error_values <- lapply(error_lines, numeric_tokens)
  error_values <- Filter(function(x) length(x) == 2L, error_values)
  sample_sizes <- setNames(
    vapply(error_values, `[[`, numeric(1), 2L),
    vapply(error_values, function(x) as.character(as.integer(x[[1L]])), character(1))
  )
  ages <- seq.int(min_age, max_age)
  if (!plus_group || !setequal(names(values_by_year), as.character(years)) ||
      !setequal(names(sample_sizes), as.character(years)) ||
      any(vapply(values_by_year, length, integer(1)) != length(ages)) ||
      any(!is.finite(unlist(values_by_year))) || any(unlist(values_by_year) < 0) ||
      any(sample_sizes <= 0) ||
      any(abs(vapply(values_by_year, sum, numeric(1)) - 1) > 0.05)) {
    stop("Age-composition values failed validation: ", name, call. = FALSE)
  }
  list(
    years = years, ages = ages, plus_group = plus_group, timing = timing,
    sample_sizes = sample_sizes, values = values_by_year,
    region = "ESCR", name = name,
    fleet = switch(name,
      AFplumes84_24 = "AFplumes84_24",
      AFrekohu12_24 = "AFrekohu12_24",
      AFcrack13_24 = "AFcrack13_24",
      stop("Unexpected age-composition observation: ", name, call. = FALSE)
    )
  )
}

catches <- parse_catches()
blocks <- observation_blocks()
index_names <- c("osp38", "combined38", "combined120", "aco_38", "aco_120")
composition_names <- c("AFplumes84_24", "AFrekohu12_24", "AFcrack13_24")
if (!all(c(index_names, composition_names) %in% names(blocks))) {
  stop("The report is missing an expected final-run observation block.", call. = FALSE)
}
indices <- lapply(index_names, function(name) parse_index(blocks[[name]], name))
compositions <- lapply(composition_names, function(name) {
  parse_composition(blocks[[name]], name)
})

input_row <- function(type, measure, basis, value, unit, year,
                      fleet = NA_character_, survey = NA_character_,
                      region, age = NA_character_, season = "annual",
                      sampling_time = NA_character_, observation_id = NA_character_,
                      sample_size = NA_character_, notes, source_reference) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = NA_character_, region = region,
    season = season, year = as.character(year), year_basis = "model_year",
    age = as.character(age), value = as.character(value), unit = unit,
    sampling_time = as.character(sampling_time), source_type = "native_model",
    source_reference = source_reference, transformation = "", notes = notes,
    observation_id = observation_id, sample_size = as.character(sample_size),
    stringsAsFactors = FALSE
  )
}

catch_inputs <- do.call(rbind, lapply(seq_len(nrow(catches)), function(i) {
  z <- catches[i, ]
  carried_forward <- z$year == 2025L
  input_row(
    type = "catch", measure = "total_biomass", basis = "biomass",
    value = z$value, unit = "tonnes", year = z$year,
    fleet = z$fleet, region = z$region,
    observation_id = paste(z$region, z$fleet, z$year, sep = "_"),
    notes = if (carried_forward) {
      "The report describes observed catches through fishing year 2023-24. The CASAL2 input repeats 2024 catch biomass for model year 2025; retained as the model's assumed current-year catch, not an observed 2025 catch."
    } else {
      "Annual catch biomass in the CASAL2 model input. Year labels are fishing years ending; catch values are tonnes. ESCR categories are modeled fishing areas, not separate stock units."
    },
    source_reference = if (z$region == "ESCR") {
      "FAR 2025/46, Appendix 3, pp. 47-48"
    } else {
      "FAR 2025/46, Appendix 4, pp. 55-56"
    }
  )
}))

composition_inputs <- do.call(rbind, lapply(compositions, function(z) {
  do.call(rbind, lapply(z$years, function(year) {
    values <- z$values[[as.character(year)]]
    do.call(rbind, lapply(seq_along(values), function(i) {
      input_row(
        type = "catch", measure = "proportion_at_age", basis = "proportion_numbers",
        value = values[[i]], unit = "proportion", year = year,
        fleet = z$fleet, region = z$region, age = z$ages[[i]], season = "spawning",
        sampling_time = z$timing,
        observation_id = paste(z$name, year, sep = "_"),
        sample_size = z$sample_sizes[[as.character(year)]],
        notes = paste0(
          "Sampled fishery age-frequency proportions from target fishing at spawning areas; not catch numbers-at-age or a survey age index. Effective sample size is the CASAL2 error value. Age 100 is a plus group; source proportions are preserved without renormalization."
        ),
        source_reference = "FAR 2025/46, Appendix 3, pp. 49-52"
      )
    }))
  }))
}))

index_inputs <- do.call(rbind, lapply(indices, function(z) {
  do.call(rbind, lapply(seq_along(z$years), function(i) {
    year <- z$years[[i]]
    common <- list(
      survey = z$survey, region = z$region, season = "spawning",
      year = year, sampling_time = z$timing,
      source_reference = if (z$region == "ESCR") {
        "FAR 2025/46, Appendix 3, pp. 48-49"
      } else {
        "FAR 2025/46, Appendix 4, pp. 56-57"
      }
    )
    index <- do.call(input_row, c(list(
      type = "index", measure = "total_biomass", basis = "biomass",
      value = z$biomass[[i]], unit = "tonnes",
      observation_id = paste(z$name, year, sep = "_"),
      notes = paste(
        "Acoustic spawning-biomass estimate on the source tonne scale; the model fits an estimated catchability parameter.",
        "The source treats the 38 kHz and 120 kHz series as alternative indices where applicable."
      )
    ), common))
    cv <- do.call(input_row, c(list(
      type = "index", measure = "biomass_index_cv", basis = "relative_scale",
      value = z$cv[[i]], unit = "ratio",
      observation_id = paste(z$name, year, "CV", sep = "_"),
      notes = "Reported acoustic observation CV; the assessment adds a separate series-level process error."
    ), common))
    rbind(index, cv)
  }))
}))

inputs <- rbind(catch_inputs, composition_inputs, index_inputs)

assumption <- function(component, setting, value, region = NA_character_,
                       source_reference, notes = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = NA_character_,
    survey = NA_character_, sex = NA_character_, region = region,
    season = NA_character_, setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("population", "model_structure", "CASAL2; one sex; ages 1-100 with age 100 as a plus group; one annual time step", source_reference = "FAR 2025/46, Appendix 3, p. 46; Appendix 4, p. 54"),
  assumption("population", "model_year_range", "1911-2025; observed catch, acoustic and age-composition data through 2024; 2025 is the estimate terminal year", source_reference = "FAR 2025/46, Appendix 3, p. 46; Appendix 4, p. 54"),
  assumption("population", "assessment_components", "East & South Chatham Rise (ESCR) and Northwest Chatham Rise (NWCR)", source_reference = "FAR 2025/46, pp. 1, 4-5", notes = "These are modeled regions within one ORH 3B management unit; they are not separate stock records."),
  assumption("observation", "catch_data", "Annual catch biomass in tonnes by modeled fishing area; model catch categories are retained as fleet labels", "ESCR", "FAR 2025/46, Appendix 3, pp. 47-48", "Observed catch data are described through fishing year 2023-24. The CASAL2 input repeats 2024 catch in model year 2025."),
  assumption("observation", "catch_data", "Annual catch biomass in tonnes for the NWCR model area", "NWCR", "FAR 2025/46, Appendix 4, pp. 55-56", "Observed catch data are described through fishing year 2023-24. The CASAL2 input repeats 2024 catch in model year 2025."),
  assumption("observation", "catch_likelihood", "CatchMustBeTaken process penalty; maximum exploitation parameter u_max=0.8 for each ESCR fishing area", "ESCR", "FAR 2025/46, Appendix 3, p. 48"),
  assumption("observation", "catch_likelihood", "CatchMustBeTaken process penalty; maximum exploitation parameter u_max=0.67 for the NWCR fishing area", "NWCR", "FAR 2025/46, Appendix 4, p. 56"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness fixed at 1; recruitment level changes at 1980", "ESCR", "FAR 2025/46, Appendix 3, p. 46; pp. 19-20", "The final ESCR runs estimate pre-1980 R0 and post-1980 R1 recruitment levels."),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness fixed at 0.75", "NWCR", "FAR 2025/46, Appendix 4, p. 54"),
  assumption("mortality", "natural_mortality", "Fixed M=0.045 per year for immature and mature categories", "ESCR", "FAR 2025/46, Appendix 3, p. 47"),
  assumption("mortality", "natural_mortality", "M estimated jointly for immature and mature categories with a normal prior: mean 0.045 per year, CV 0.333", "NWCR", "FAR 2025/46, Appendix 4, p. 58"),
  assumption("biology", "growth", "Von Bertalanffy age-length: k=0.059, t0=-0.491, Linf=37.78, CV first=0.088 and CV last=0.044", source_reference = "FAR 2025/46, Appendix 3, pp. 46-47; Appendix 4, pp. 54-55", notes = "The report does not explicitly label the model length unit; native values are transcribed without conversion."),
  assumption("biology", "length_weight", "W=8.0e-8 x length^2.75; output units tonnes", source_reference = "FAR 2025/46, Appendix 3, p. 47; Appendix 4, p. 55", notes = "The model appendix does not explicitly label the length unit. No weight-at-age table is published; weights are generated from the model's growth and length-weight equations."),
  assumption("maturity", "maturity_ogive", "Logistic maturity transition, A50=28.51 and Ato95=4.56", source_reference = "FAR 2025/46, Appendix 3, p. 48; Appendix 4, p. 57", notes = "For some ESCR age-frequency runs, maturity and fishery selectivity assumptions are varied by sampled spawning area; the reported SSB uses the corresponding model definition."),
  assumption("observation", "acoustic_observation", "Acoustic biomass observations use a lognormal likelihood, represent spawning biomass, and are assigned sampling time 0.75", "ESCR", "FAR 2025/46, Appendix 3, pp. 48-49", "The 2011-2024 38 kHz and 2013-2024 120 kHz series are treated as alternatives. Recent acoustic estimates are assumed to represent 80% of spawning biomass."),
  assumption("observation", "acoustic_process_error", "OSP 38 kHz process error=0.2; combined 38 kHz=0.1; combined 120 kHz=0.25", "ESCR", "FAR 2025/46, Appendix 3, pp. 48-49"),
  assumption("catchability", "acoustic_q_prior", "OSP 38 kHz q uniform on 0.01-5; combined 38 and 120 kHz share q with lognormal prior mean=0.8 and CV=0.19", "ESCR", "FAR 2025/46, Appendix 3, pp. 53-54", "The appendix uses one combined catchability parameter for the alternative recent 38 and 120 kHz series."),
  assumption("observation", "acoustic_observation", "Acoustic biomass observations use a lognormal likelihood and sampling time 0.75", "NWCR", "FAR 2025/46, Appendix 4, pp. 56-57"),
  assumption("observation", "acoustic_process_error", "Process error=0.2 for both the 38 kHz and 120 kHz series", "NWCR", "FAR 2025/46, Appendix 4, pp. 56-57"),
  assumption("catchability", "acoustic_q_prior", "38 kHz q normal prior mean=0.8, CV=0.19; 120 kHz q normal prior mean=0.3, CV=0.19", "NWCR", "FAR 2025/46, Appendix 4, pp. 58-59"),
  assumption("observation", "age_composition_likelihood", "ESCR sampled fishery age-frequency proportions use a multinomial likelihood; ages 18-100+ for OSP and 20-100+ for Rekohu and Mt Muck/Crack", "ESCR", "FAR 2025/46, Appendix 3, pp. 49-52", "Effective sample sizes are 10 except OSP 2003, which is 2. These inputs are not catch numbers-at-age or survey age indices; the assessment also includes acoustic-only alternatives."),
  assumption("observation", "ageing_error", "Normal ageing error with CV=0.1", "ESCR", "FAR 2025/46, Appendix 3, p. 53"),
  assumption("output", "reported_uncertainty", "MCMC medians and 95% credible intervals are reported for scalar recruitment, B0, 2025 SSB, and stock status", source_reference = "FAR 2025/46, Tables 4, 7 and 10, pp. 21, 25 and 32", notes = "Annual numeric N-at-age, F-at-age, M-at-age, and SSB trajectories were not tabulated in the reviewed report."),
  assumption("output", "censored_probability", "The ESCR Acoustic 38 and AF run reports probability below 10% B0 as <1%", source_reference = "FAR 2025/46, Table 7, p. 25", notes = "The inequality is retained in this note; no numeric point value is entered in outputs.csv.")
))

output_row <- function(type, measure, value, unit, region, source_reference,
                       notes, year = NA_character_, lwr = NA_real_,
                       upr = NA_real_, scenario) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = region, season = NA_character_, year = as.character(year),
    age = NA_character_, age_group = NA_character_, value = as.character(value),
    se = NA_character_, lwr = as.character(lwr), upr = as.character(upr),
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = scenario, stringsAsFactors = FALSE
  )
}

outputs <- list()
add_output <- function(...) outputs[[length(outputs) + 1L]] <<- output_row(...)
summary_note <- "MCMC median and reported 95% credible interval; the source does not report standard errors."
escr_ref <- "FAR 2025/46, Tables 4 and 7, pp. 21 and 25"
escr <- data.frame(
  scenario = c("ESCR Acoustic 38", "ESCR Acoustic 120", "ESCR Acoustic 38 + AF", "ESCR Acoustic 120 + AF"),
  B0 = c(349.2, 368.6, 441.8, 423.9), B0_lwr = c(326.5, 336.7, 411.6, 398.0), B0_upr = c(392.3, 424.2, 483.0, 460.6),
  SSB2025 = c(52.0, 29.3, 81.5, 53.7), SSB_lwr = c(36.1, 19.4, 56.2, 32.7), SSB_upr = c(81.9, 45.5, 117.5, 84.0),
  status = c(16, 8, 18, 13), status_lwr = c(11, 6, 13, 8), status_upr = c(22, 11, 25, 19),
  p_lt_20 = c(94, 100, 72, 99), p_lt_10 = c(1, 91, NA, 14),
  R0 = c(39.5, 41.7, 49.9, 48.0), R0_lwr = c(36.9, 38.1, 46.5, 45.0), R0_upr = c(44.4, 48.0, 54.6, 52.1),
  R1 = c(15.8, 7.9, 11.1, 6.5), R1_lwr = c(11.7, 2.4, 6.7, 3.7), R1_upr = c(20.7, 11.5, 17.1, 11.1),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(escr))) {
  z <- escr[i, ]
  add_output("biomass", "unfished_spawning_biomass", z$B0, "thousand tonnes", "ESCR", "FAR 2025/46, Table 7, p. 25", summary_note, scenario = z$scenario)
  add_output("biomass", "spawning_biomass", z$SSB2025, "thousand tonnes", "ESCR", "FAR 2025/46, Table 7, p. 25", summary_note, year = 2025, lwr = z$SSB_lwr, upr = z$SSB_upr, scenario = z$scenario)
  add_output("biomass", "SSB_ratio_to_B0", z$status, "percent of B0", "ESCR", "FAR 2025/46, Table 7, p. 25", summary_note, year = 2025, lwr = z$status_lwr, upr = z$status_upr, scenario = z$scenario)
  add_output("probability", "probability_below_20_percent_B0", z$p_lt_20 / 100, "probability", "ESCR", "FAR 2025/46, Table 7, p. 25", "Source percentage converted to probability by dividing by 100; posterior probability for 2025 SSB below 20% of B0.", year = 2025, scenario = z$scenario)
  if (!is.na(z$p_lt_10)) {
    add_output("probability", "probability_below_10_percent_B0", z$p_lt_10 / 100, "probability", "ESCR", "FAR 2025/46, Table 7, p. 25", "Source percentage converted to probability by dividing by 100; posterior probability for 2025 SSB below 10% of B0.", year = 2025, scenario = z$scenario)
  }
  for (period in c("R0", "R1")) {
    suffix <- if (period == "R0") "1911-1979" else "1980-2025"
    add_output("recruitment", "mean_recruitment", z[[period]], "million age-1 fish per year", "ESCR", "FAR 2025/46, Table 4, p. 21", paste(summary_note, period, "recruitment level for model years", suffix, "is reported as a period-level parameter, not an annual recruitment trajectory."), lwr = z[[paste0(period, "_lwr")]], upr = z[[paste0(period, "_upr")]], scenario = paste(z$scenario, period, suffix))
  }
}

nwcr <- data.frame(
  scenario = c("NWCR Acoustic 38", "NWCR Acoustic 120"),
  B0 = c(59.2, 59.9), B0_lwr = c(47.3, 46.9), B0_upr = c(76.7, 78.3),
  SSB2025 = c(21.1, 19.5), SSB_lwr = c(16.8, 15.0), SSB_upr = c(29.0, 28.9),
  status = c(36, 34), status_lwr = c(25, 21), status_upr = c(49, 49),
  p_gt_30 = c(85, 73), stringsAsFactors = FALSE
)
for (i in seq_len(nrow(nwcr))) {
  z <- nwcr[i, ]
  add_output("biomass", "unfished_spawning_biomass", z$B0, "thousand tonnes", "NWCR", "FAR 2025/46, Table 10, p. 32", summary_note, scenario = z$scenario)
  add_output("biomass", "spawning_biomass", z$SSB2025, "thousand tonnes", "NWCR", "FAR 2025/46, Table 10, p. 32", summary_note, year = 2025, lwr = z$SSB_lwr, upr = z$SSB_upr, scenario = z$scenario)
  add_output("biomass", "SSB_ratio_to_B0", z$status, "percent of B0", "NWCR", "FAR 2025/46, Table 10, p. 32", summary_note, year = 2025, lwr = z$status_lwr, upr = z$status_upr, scenario = z$scenario)
  add_output("probability", "probability_above_30_percent_B0", z$p_gt_30 / 100, "probability", "NWCR", "FAR 2025/46, p. 32", "Source percentage converted to probability by dividing by 100; posterior probability for 2025 SSB above 30% of B0.", year = 2025, scenario = z$scenario)
}
outputs <- do.call(rbind, outputs)

if (nrow(catch_inputs) != 328L || nrow(composition_inputs) != 1310L ||
    nrow(index_inputs) != 52L || nrow(inputs) != 1690L || nrow(outputs) != 35L) {
  stop("Unexpected ORH 3B row counts: ", nrow(catch_inputs), " catches, ",
    nrow(composition_inputs), " composition rows, ", nrow(index_inputs),
    " acoustic and CV rows, and ", nrow(outputs), " outputs.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "Fisheries New Zealand", authority_stock_id = "ORH 3B",
  scientific_name = "Hoplostethus atlanticus", common_name = "Orange roughy",
  area = "ORH 3B, East & South and Northwest Chatham Rise components",
  region = "Chatham Rise", ocean = "Southwest Pacific",
  notes = "The 2025 assessment models East & South Chatham Rise (ESCR) and Northwest Chatham Rise (NWCR) as regions within one ORH 3B management unit; it does not cover all biological sub-stocks in the wider ORH 3B area.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L,
  estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "CASAL2", model_version = "Version not reported",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://fs.fish.govt.nz/Doc/26145/FAR-2025-46-Stock-assessment-of-Chatham-Rise-orange-roughy-in-2025.pdf.ashx",
  framework_url = "", data_url = "https://fs.fish.govt.nz/Doc/25881/FAR-2025-23-Acoustic-biomass-surveys-ORH3B-NWCR-and-ORH3B-ESCR-June-July-2022.pdf.ashx",
  model_url = "https://fs.fish.govt.nz/Doc/26145/FAR-2025-46-Stock-assessment-of-Chatham-Rise-orange-roughy-in-2025.pdf.ashx",
  repository_url = "", assumptions_status = "partial",
  inputs_status = "complete", outputs_status = "partial",
  notes = paste(
    "Latest detailed production assessment located. Native CASAL2 appendix inputs are captured for both modeled regions, including catches, acoustic biomass/CVs, and the ESCR sampled fishery age-frequency series used in alternative runs.",
    "Catch biomass in model year 2025 is repeated from 2024 in the source input and is retained as an assumed current-year model input, not an observed catch.",
    "Scalar MCMC summaries are available, but annual numeric population surfaces are not tabulated; outputs are therefore partial. Model assumptions remain partial because the report does not publish a stand-alone weight-at-age/maturity-at-age surface or a versioned native model object."
  ),
  stringsAsFactors = FALSE
)

bind_schema <- function(rows, path) {
  schema <- names(read.csv(path, nrows = 0L, check.names = FALSE))
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
  "Prepared ", nrow(catch_inputs), " catch rows, ", nrow(composition_inputs),
  " age-composition values, ", nrow(index_inputs), " acoustic and CV rows, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " scalar output rows.\n",
  sep = ""
)

if (write_mode) {
  stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  candidate_row <- match(candidate_id, candidates$candidate_id)
  if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id ||
      is.na(candidate_row) || candidates$import_status[candidate_row] != "not_started") {
    stop("ORH 3B is already imported or its candidate row is not ready.", call. = FALSE)
  }

  append_rows("database/stocks.csv", stock)
  append_rows("database/assessments.csv", assessment)
  append_rows("database/assumptions.csv", assumptions)
  append_rows("database/inputs.csv", inputs)
  append_rows("database/outputs.csv", outputs)

  source("scripts/database/candidate_register_io.R")
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  replace_candidate_register_row(
    "discovery/candidates.csv", candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id
  )
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("ORH 3B source records and discovery summaries were written.\n")
}
