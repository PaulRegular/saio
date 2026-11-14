assessment_id <- "mpi_red_gurnard_gur3_2022"
stock_id <- "mpi_red_gurnard_gur3"
candidate_id <- "MPI:GUR3"
report <- file.path("source_cache", "nz_red_gurnard_gur3_2022",
  "FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(report)) stop("The cached GUR 3 assessment report is required.", call. = FALSE)
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached assessment tables.", call. = FALSE)
}
sha256_file <- function(path) {
  if ("sha256sum" %in% getNamespaceExports("tools")) {
    return(unname(tools::sha256sum(path)))
  }
  if (requireNamespace("openssl", quietly = TRUE)) {
    bytes <- readBin(path, "raw", n = file.info(path)$size)
    return(paste0(openssl::sha256(bytes)))
  }
  stop("Install openssl or use R 4.6+ to verify the cached assessment report.", call. = FALSE)
}
if (!identical(toupper(sha256_file(report)),
    "D5626CA8A0C9A6E6989291EBE7BFB0BFD7EB02E232E41CA62A810B2F31FA9DE7")) {
  stop("The cached report does not match the reviewed source.", call. = FALSE)
}

pdf_lines <- unlist(lapply(pdftools::pdf_text(report), function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE)

normalize_numbers <- function(x) {
  gsub("(?<=\\d) (?=\\d{3}(?:\\.|\\s|$))", "", x, perl = TRUE)
}

number_tokens <- function(x) {
  x <- normalize_numbers(x)
  hits <- regmatches(x, gregexpr("[0-9]+(?:\\.[0-9]+)?", x, perl = TRUE))[[1L]]
  if (identical(hits, character(0))) numeric() else as.numeric(hits)
}

section_lines <- function(start, end) {
  a <- grep(start, pdf_lines)
  b <- grep(end, pdf_lines)
  if (length(a) != 1L || length(b) != 1L || b <= a) {
    stop("Could not locate PDF section ", start, call. = FALSE)
  }
  pdf_lines[(a + 1L):(b - 1L)]
}

parse_table_rows <- function(lines, pattern, columns, table_name) {
  selected <- lines[grepl(pattern, lines, perl = TRUE)]
  if (!length(selected)) stop("No rows found in ", table_name, call. = FALSE)
  parsed <- lapply(selected, number_tokens)
  if (any(lengths(parsed) != columns)) {
    stop("Unexpected numeric columns in ", table_name, call. = FALSE)
  }
  do.call(rbind, parsed)
}

parse_catches <- function() {
  lines <- section_lines("^Table A3:", "^Table A4:")
  rows <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  parts <- lapply(rows, function(line) {
    tokens <- number_tokens(line)
    if (!length(tokens) || length(tokens) %% 3L != 0L) {
      stop("Unexpected row shape in Table A3.", call. = FALSE)
    }
    matrix(tokens, ncol = 3L, byrow = TRUE)
  })
  values <- do.call(rbind, parts)
  values <- values[order(values[, 1L]), , drop = FALSE]
  if (nrow(values) != 37L || !identical(as.integer(values[, 1L]), 1985:2021)) {
    stop("Table A3 does not contain the expected 1985-2021 catch series.", call. = FALSE)
  }
  data.frame(
    year = rep(as.integer(values[, 1L]), 2L),
    fleet = rep(c("BT-MIX", "BT-FLA"), each = nrow(values)),
    value = c(values[, 2L], values[, 3L]),
    stringsAsFactors = FALSE
  )
}

parse_survey_biomass <- function() {
  lines <- section_lines("^Table A4:", "^Table A5:")
  rows <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  survey_names <- c(
    winter_core = "Kaharoa ECSI winter trawl survey (30-400 m)",
    summer_core = "Kaharoa ECSI summer trawl survey (30-400 m)",
    winter_full = "Kaharoa ECSI winter trawl survey (10-400 m)",
    winter_shallow = "Kaharoa ECSI winter trawl survey (10-30 m; sensitivity only)"
  )
  result <- list()
  for (line in rows) {
    tokens <- number_tokens(line)
    year <- as.integer(tokens[1L])
    values <- tokens[-1L]
    if (year %in% c(1991:1994, 1996, 2008, 2009)) {
      series <- "winter_core"
    } else if (year %in% 1997:2001) {
      series <- "summer_core"
    } else if (year %in% c(2007, 2012, 2014, 2016, 2018, 2021)) {
      if (length(values) != 6L) stop("Unexpected Table A4 survey groups for ", year, call. = FALSE)
      for (j in seq_len(3L)) {
        result[[length(result) + 1L]] <- data.frame(
          year = year, survey_key = c("winter_core", "winter_full", "winter_shallow")[j],
          survey = unname(survey_names[j]), biomass = values[2L * j - 1L],
          cv = values[2L * j], stringsAsFactors = FALSE
        )
      }
      next
    } else {
      stop("Unrecognized Table A4 survey year: ", year, call. = FALSE)
    }
    if (length(values) != 2L) stop("Unexpected Table A4 columns for ", year, call. = FALSE)
    result[[length(result) + 1L]] <- data.frame(
      year = year, survey_key = series, survey = unname(survey_names[series]),
      biomass = values[1L], cv = values[2L], stringsAsFactors = FALSE
    )
  }
  result <- do.call(rbind, result)
  if (nrow(result) != 30L || sum(result$survey_key == "winter_core") != 13L ||
      sum(result$survey_key == "summer_core") != 5L ||
      sum(result$survey_key == "winter_full") != 6L ||
      sum(result$survey_key == "winter_shallow") != 6L) {
    stop("Table A4 series coverage differs from the assessment tables.", call. = FALSE)
  }
  result
}

parse_age_compositions <- function() {
  lines <- section_lines("^Table A5:", "^Table A6a:")
  values <- parse_table_rows(lines, "^\\s*(10|[1-9])\\s+0\\.", 7L, "Table A5")
  if (nrow(values) != 10L || !identical(as.integer(values[, 1L]), 1:10)) {
    stop("Table A5 does not contain the expected age 1-10+ rows.", call. = FALSE)
  }
  result <- list()
  years <- c(1992L, 1993L, 1994L)
  for (i in seq_len(nrow(values))) {
    for (sex_i in seq_along(c("female", "male"))) {
      sex <- c("female", "male")[sex_i]
      ix <- if (sex == "female") 2:4 else 5:7
      for (j in seq_along(years)) {
        result[[length(result) + 1L]] <- data.frame(
          year = years[j], age = as.integer(values[i, 1L]),
          age_group = if (values[i, 1L] == 10) "10+" else "",
          sex = sex, value = values[i, ix[j]], stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, result)
}

parse_length_table <- function(start, end, female_years, male_years,
                               survey, table_name) {
  lines <- section_lines(start, end)
  n_years <- length(female_years)
  values <- parse_table_rows(lines, "^\\s*(5[0-5]|[1-4][0-9]|[1-9][0-9])\\s+0\\.",
    1L + length(female_years) + length(male_years), table_name)
  if (nrow(values) != 46L || !identical(as.integer(values[, 1L]), 10:55)) {
    stop(table_name, " does not contain the expected 10-55 cm bins.", call. = FALSE)
  }
  result <- list()
  for (sex in c("female", "male")) {
    years <- if (sex == "female") female_years else male_years
    column_offset <- if (sex == "female") 1L else 1L + n_years
    for (j in seq_along(years)) {
      for (i in seq_len(nrow(values))) {
        result[[length(result) + 1L]] <- data.frame(
          year = years[j], sex = sex, length_bin = as.character(as.integer(values[i, 1L])),
          value = values[i, column_offset + j], survey = survey,
          table_name = table_name, stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, result)
}

parse_length_compositions <- function() {
  do.call(rbind, list(
    parse_length_table("^Table A6a:", "^Table A6b:",
      c(1991L, 1996L, 2007L, 2008L, 2009L), c(1991L, 1996L, 2007L, 2008L, 2009L),
      "Kaharoa ECSI winter trawl survey (30-400 m)", "Table A6a"),
    parse_length_table("^Table A6b:", "^Table A7:",
      c(2012L, 2014L, 2016L, 2018L, 2021L), c(2012L, 2014L, 2016L, 2018L, 2021L),
      "Kaharoa ECSI winter trawl survey (30-400 m)", "Table A6b"),
    parse_length_table("^Table A7:", "^Table A8:",
      c(2007L, 2012L, 2014L, 2016L, 2018L, 2021L), c(2007L, 2012L, 2014L, 2016L, 2018L, 2021L),
      "Kaharoa ECSI winter trawl survey (10-400 m)", "Table A7"),
    parse_length_table("^Table A8:", "^Figure A11:",
      1997L:2001L, 1997L:2001L,
      "Kaharoa ECSI summer trawl survey (30-400 m)", "Table A8")
  ))
}

fmt <- function(x) format(x, scientific = FALSE, trim = TRUE, digits = 15)

input_row <- function(type, measure, basis, value, unit, year,
                      fleet = NA_character_, survey = NA_character_,
                      sex = NA_character_, season = NA_character_,
                      age = NA_character_, age_group = "", length_bin = NA_character_,
                      observation_id = NA_character_, notes = "",
                      source_reference, sample_size = NA_character_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = NA_character_,
    season = season, year = as.character(year),
    year_basis = if (is.na(year)) NA_character_ else "model_year",
    age = as.character(age), value = fmt(value), unit = unit,
    sampling_time = NA_character_, source_type = "official_table",
    source_reference = source_reference, transformation = "", notes = notes,
    observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = NA_character_, length_bin_upper = NA_character_,
    sample_size = sample_size, age_error = NA_character_, partition = NA_character_,
    weight_bin = NA_character_, stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch_table <- parse_catches()
survey_table <- parse_survey_biomass()
age_table <- parse_age_compositions()
length_table <- parse_length_compositions()

catch_inputs <- do.call(rbind, lapply(seq_len(nrow(catch_table)), function(i) {
  x <- catch_table[i, ]
  input_row(
    type = "catch", measure = "catch_biomass", basis = "biomass",
    value = x$value, unit = "tonnes", year = x$year, fleet = x$fleet,
    season = "annual", observation_id = paste0("gur3_", x$fleet, "_", x$year),
    notes = paste(
      "Assessment-model catch by fishery, covering the whole GUR 3 QMA.",
      "Table A3 values already include the assessment's 10% under-reporting allowance;",
      "no additional scaling was applied during import."
    ),
    source_reference = "Langley 2022, FAR 2022/21, Table A3, p. 49"
  )
}))

biomass_inputs <- do.call(rbind, lapply(seq_len(nrow(survey_table)), function(i) {
  x <- survey_table[i, ]
  sensitivity <- x$survey_key == "winter_shallow"
  obs_id <- paste0("gur3_", x$survey_key, "_", x$year)
  common_note <- if (sensitivity) {
    paste("Table A4 10-30 m biomass series is used only in the TrawlSurvey10-30m sensitivity,",
      "which replaces the 10-400 m winter series; it is not an additional base-model series.")
  } else {
    paste("Aggregate Kaharoa ECSI survey biomass index in tonnes; index coverage is FMA 3,",
      "whereas model catch covers the whole GUR 3 QMA.")
  }
  rbind(
    input_row(
      type = "index", measure = "total_biomass", basis = "biomass",
      value = x$biomass, unit = "tonnes", year = x$year,
      survey = x$survey, season = if (grepl("summer", x$survey_key)) "summer" else "winter",
      observation_id = obs_id, notes = common_note,
      source_reference = "Langley 2022, FAR 2022/21, Table A4, pp. 49-50"
    ),
    input_row(
      type = "index", measure = "biomass_index_cv", basis = "relative_scale",
      value = x$cv, unit = "ratio", year = x$year,
      survey = x$survey, season = if (grepl("summer", x$survey_key)) "summer" else "winter",
      observation_id = paste0(obs_id, "_CV"),
      notes = paste("Source-reported CV for the corresponding survey biomass observation.", common_note),
      source_reference = "Langley 2022, FAR 2022/21, Table A4, pp. 49-50"
    )
  )
}))

age_inputs <- do.call(rbind, lapply(seq_len(nrow(age_table)), function(i) {
  x <- age_table[i, ]
  input_row(
    type = "index", measure = "proportion_at_age", basis = "proportion_numbers",
    value = x$value, unit = "proportion", year = x$year,
    survey = "Kaharoa ECSI winter trawl survey (30-400 m)", sex = x$sex,
    season = "winter", age = x$age, age_group = x$age_group,
    observation_id = paste0("gur3_winter_30_400_age_", x$year, "_", x$sex),
    notes = paste(
      "Published survey age-composition proportion; values are preserved without renormalization.",
      "Raw age sample counts are not reported; sample_size is left blank.",
      "Effective sample size 20 is recorded as a model assumption. Age 10 is the 10+ plus group."
    ),
    source_reference = "Langley 2022, FAR 2022/21, Table A5, p. 50"
  )
}))

length_inputs <- do.call(rbind, lapply(seq_len(nrow(length_table)), function(i) {
  x <- length_table[i, ]
  input_row(
    type = "index", measure = "proportion_at_length", basis = "proportion_numbers",
    value = x$value, unit = "proportion", year = x$year,
    survey = x$survey, sex = x$sex,
    season = if (grepl("summer", x$survey)) "summer" else "winter",
    length_bin = x$length_bin,
    observation_id = paste0("gur3_", x$table_name, "_", x$year, "_", x$sex),
    notes = paste(
      "Published survey length-composition proportion; values are preserved without renormalization.",
      "Length labels are in cm as printed; the report does not specify bin boundaries or raw sample counts;",
      "sample_size is left blank. Model effective sample size 10 is recorded as an assumption."
    ),
    source_reference = paste0("Langley 2022, FAR 2022/21, ", x$table_name, ", pp. 51-54")
  )
}))

biology_inputs <- rbind(
  do.call(rbind, lapply(c("female", "male"), function(sex) {
    value <- if (sex == "female") 0.29 else 0.35
    do.call(rbind, lapply(1:10, function(age) input_row(
      type = "M", measure = "natural_mortality_at_age", basis = "per_year",
      value = value, unit = "year^-1", year = NA_character_, sex = sex, age = age,
      observation_id = paste0("gur3_M_", sex, "_", age),
      notes = if (age == 10) "Fixed model input; age 10 is the 10+ plus group." else "Fixed model input.",
      source_reference = "Langley 2022, FAR 2022/21, Table 10, p. 20"
    )))
  })),
  do.call(rbind, lapply(1:10, function(age) input_row(
    type = "maturity", measure = "maturity_at_age", basis = "proportion",
    value = if (age == 1) 0 else if (age == 2) 0.5 else 1,
    unit = "proportion", year = NA_character_, age = age,
    observation_id = paste0("gur3_maturity_", age),
    notes = if (age == 10) "Fixed model input; age 10 is the 10+ plus group." else "Fixed model input.",
    source_reference = "Langley 2022, FAR 2022/21, Table 10, p. 20"
  )))
)

inputs <- rbind(catch_inputs, biomass_inputs, age_inputs, length_inputs, biology_inputs)

assumption <- function(component, setting, value, source_reference, notes = "",
                       fleet = NA_character_, survey = NA_character_,
                       sex = NA_character_, season = NA_character_) {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = NA_character_, season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("model", "software_version", "Stock Synthesis 3.30.17", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("population", "model_year_range", "1985-2021; year label denotes the fishing year beginning in that year", "Langley 2022, FAR 2022/21, pp. 20-21"),
  assumption("population", "model_age_range", "Ages 1-9 and 10+; two sexes; one stock area", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("population", "initial_population", "Exploited equilibrium in 1985", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("population", "annual_cycle", "Annual time step with no seasonal structure; spawning and recruitment occur at the start of the year", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("fishery", "catch_timing", "Commercial fisheries operate throughout the year; catches are taken instantaneously at midyear", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("catch", "model_catch_coverage", "BT-MIX and BT-FLA catches cover the whole GUR 3 QMA; survey and CPUE indices cover FMA 3", "Langley 2022, FAR 2022/21, pp. 19-20", "Since 2000 approximately 25% of catch was taken outside FMA 3, principally in FMA 5."),
  assumption("catch", "under_reporting", "Model catch includes 10% allowance for commercial under-reporting", "Langley 2022, FAR 2022/21, p. 19; Table A3, p. 49"),
  assumption("catch", "noncommercial_catch", "Recreational catch (<5 t annually) and customary catch were excluded", "Langley 2022, FAR 2022/21, p. 19", "Customary catch estimates were unavailable."),
  assumption("mortality", "natural_mortality", "Fixed M=0.29 y-1 for females and M=0.35 y-1 for males", "Langley 2022, FAR 2022/21, Table 10, p. 20", "Values are fixed for the base model; lower-M sensitivity uses 0.25 y-1 for both sexes."),
  assumption("biology", "growth", "Von Bertalanffy: female Linf=48.2 cm, k=0.44, length-at-age-1=19.4 cm; male Linf=42.2 cm, k=0.49, length-at-age-1=19.4 cm; CV length-at-age=0.10", "Langley 2022, FAR 2022/21, Table 10, p. 20"),
  assumption("biology", "length_weight", "Mean weight (kg)=5.3e-6 * length(cm)^3.19", "Langley 2022, FAR 2022/21, Table 10, p. 20"),
  assumption("maturity", "maturity_at_age", "0 at age 1, 0.5 at age 2, and 1 at ages 3+", "Langley 2022, FAR 2022/21, Table 10, p. 20"),
  assumption("biology", "sex_ratio", "Females comprise 50% of population numbers and biomass", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness fixed at 0.85; log recruitment-deviation SD (sigmaR)=0.6", "Langley 2022, FAR 2022/21, Table 10, p. 20"),
  assumption("recruitment", "year_class_strengths", "Recruitment deviations estimated for 1985-2020; 2021 recruitment assumed from the mean stock-recruitment relationship", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("observation", "fishery_compositions", "No commercial fishery age or length compositions were available", "Langley 2022, FAR 2022/21, p. 21"),
  assumption("observation", "cpue_index", "BT-MIX CPUE series covers 1990-2021; lognormal likelihood with CV=0.20", "Langley 2022, FAR 2022/21, Table 11 and p. 20", "The report describes 32 observations but does not tabulate their numerical values; they are not imported."),
  assumption("observation", "excluded_flA_cpue", "BT-FLA CPUE was not included in the assessment model", "Langley 2022, FAR 2022/21, p. 20", "The report cites vessel retirement and high variability in the FLA indices."),
  assumption("observation", "survey_biomass_likelihood", "Three survey series use lognormal likelihoods and their native CVs; no additional process error", "Langley 2022, FAR 2022/21, Table 11 and p. 20"),
  assumption("observation", "survey_age_composition", "Winter 30-400 m age compositions for 1992-1994 use multinomial likelihoods with ESS=20 and no ageing error", "Langley 2022, FAR 2022/21, Table 11 and p. 21"),
  assumption("observation", "survey_length_composition", "Winter 30-400 m, winter 10-400 m, and summer 30-400 m length compositions use multinomial likelihoods with ESS=10", "Langley 2022, FAR 2022/21, Table 11, p. 21"),
  assumption("observation", "survey_overlap", "Base model includes both winter 30-400 m and winter 10-400 m biomass series, overlapping in 2007-2021; 10-30 m is used only in the TrawlSurvey10-30m sensitivity", "Langley 2022, FAR 2022/21, pp. 20, 31; Tables A4 and 13"),
  assumption("selectivity", "survey_selectivity", "Separate age-based logistic selectivities for winter 30-400 m, winter 10-400 m, and summer 30-400 m; sex-specific offsets for 30-400 m series", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("selectivity", "commercial_selectivity", "One fixed age-based logistic selectivity shared by BT-MIX and BT-FLA and equivalent for both sexes; set to approximate full selection near 30 cm", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("mortality", "fishing_mortality_method", "Hybrid method uses Pope's approximation to calculate harvest rate and converts it to fishery-specific F", "Langley 2022, FAR 2022/21, p. 20"),
  assumption("estimation", "estimated_parameters", "lnR0 is uninformative uniform; 36 recruitment deviations use sigmaR=0.6; 8 survey-selectivity parameters; 3 trawl-survey log-q parameters; 2 initial-F parameters with Normal(0.4, 0.2) priors", "Langley 2022, FAR 2022/21, Table 12, p. 21"),
  assumption("uncertainty", "mcmc", "Metropolis-Hastings MCMC; 1,000 samples at 1,000 intervals from a 1.1-million chain after 100,000 burn-in", "Langley 2022, FAR 2022/21, p. 21"),
  assumption("observation", "survey_timing", "Winter ECSI surveys were generally conducted in May and summer surveys in December; model has no seasonal structure and does not specify fractional-year sampling times", "Langley 2022, FAR 2022/21, pp. 2, 20-21", "The 2021 survey is noted as occurring in March 2021 (model year 2020/21).")
))

output_row <- function(type, measure, value, unit, source_reference, notes,
                       year = NA_character_, lwr = NA_character_, upr = NA_character_,
                       scenario = "Base") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = as.character(year),
    age = NA_character_, age_group = NA_character_, value = fmt(value),
    se = NA_character_, lwr = as.character(lwr), upr = as.character(upr),
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = scenario, stringsAsFactors = FALSE, check.names = FALSE
  )
}

outputs <- do.call(rbind, list(
  output_row("biomass", "unfished_spawning_biomass", 5579, "tonnes",
    "Langley 2022, FAR 2022/21, Table 14, p. 31", "Base model MPD point estimate of SB0.", scenario = "Base; MPD"),
  output_row("biomass", "SSB_ratio_to_B0", 0.492, "ratio",
    "Langley 2022, FAR 2022/21, Table 14, p. 31", "Base model MPD point estimate of SB2021/SB0.", year = 2021, scenario = "Base; MPD"),
  output_row("mortality", "F_ratio_to_FSB40", 1.408, "ratio",
    "Langley 2022, FAR 2022/21, Table 14, p. 31", "Base model MPD point estimate of F2021/FSB40%.", year = 2021, scenario = "Base; MPD"),
  output_row("catch", "yield_at_FSB40", 1574, "tonnes",
    "Langley 2022, FAR 2022/21, Table 14, p. 31", "Base model MPD current potential yield at FSB40%.", year = 2021, scenario = "Base; MPD"),
  output_row("biomass", "unfished_spawning_biomass", 6307, "tonnes",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "Base model MCMC median; source reports a 95% interval from MCMCs.", lwr = 5552, upr = 7749, scenario = "Base; MCMC median"),
  output_row("biomass", "spawning_biomass", 4061, "tonnes",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "2020/21 spawning biomass (model year 2021); MCMC median and source-reported 95% interval.", year = 2021, lwr = 2500, upr = 6808, scenario = "Base; MCMC median"),
  output_row("biomass", "SSB_ratio_to_B0", 0.644, "ratio",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "SSB2021/SB0; MCMC median and source-reported 95% interval.", year = 2021, lwr = 0.435, upr = 0.924, scenario = "Base; MCMC median"),
  output_row("biomass", "probability_above_35_percent_B0", 0.999, "probability",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "MCMC probability that 2021 spawning biomass exceeds 35% SB0.", year = 2021, scenario = "Base; MCMC"),
  output_row("biomass", "probability_above_20_percent_B0", 1.000, "probability",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "MCMC probability that 2021 spawning biomass exceeds 20% SB0.", year = 2021, scenario = "Base; MCMC"),
  output_row("biomass", "probability_above_10_percent_B0", 1.000, "probability",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "MCMC probability that 2021 spawning biomass exceeds 10% SB0.", year = 2021, scenario = "Base; MCMC"),
  output_row("mortality", "F_reference_at_SB40", 0.2028, "year^-1",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "F reference associated with 40% SB0."),
  output_row("mortality", "F_ratio_to_FSB40", 0.996, "ratio",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "F2021/FSB40%; MCMC median and source-reported 95% interval.", year = 2021, lwr = 0.627, upr = 1.513, scenario = "Base; MCMC median"),
  output_row("mortality", "probability_below_FSB40", 0.506, "probability",
    "Langley 2022, FAR 2022/21, Table 15, p. 32", "MCMC probability that F2021 is below FSB40%.", year = 2021, scenario = "Base; MCMC"),
  output_row("catch", "yield_at_FSB40", 986, "tonnes",
    "Langley 2022, FAR 2022/21, Table 16, p. 33", "Equilibrium yield at FSB40%; MCMC median and source-reported 95% interval.", lwr = 867, upr = 1211, scenario = "Base; equilibrium yield"),
  output_row("catch", "yield_at_FSB40", 1617, "tonnes",
    "Langley 2022, FAR 2022/21, Table 16, p. 33", "Yield at FSB40% applied to 2020/21 biomass; MCMC median and source-reported 95% interval.", year = 2021, lwr = 1411, upr = 1855, scenario = "Base; current-biomass yield"),
  output_row("biomass", "SSB_ratio_to_B0", 0.609, "ratio",
    "Langley 2022, FAR 2022/21, Table 17, p. 33", "Projected SB2026/SB0; MCMC median and source-reported 95% interval.", year = 2026, lwr = 0.337, upr = 0.970, scenario = "Base; projection"),
  output_row("biomass", "probability_above_10_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/21, Table 17, p. 33", "MCMC probability that projected 2026 spawning biomass exceeds 10% SB0.", year = 2026, scenario = "Base; projection"),
  output_row("biomass", "probability_above_20_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/21, Table 17, p. 33", "MCMC probability that projected 2026 spawning biomass exceeds 20% SB0.", year = 2026, scenario = "Base; projection"),
  output_row("biomass", "probability_above_35_percent_B0", 0.97, "probability",
    "Langley 2022, FAR 2022/21, Table 17, p. 33", "MCMC probability that projected 2026 spawning biomass exceeds 35% SB0.", year = 2026, scenario = "Base; projection")
))

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "Fisheries New Zealand", authority_stock_id = "GUR 3",
  scientific_name = "Chelidonichthys kumu", common_name = "Red gurnard",
  area = "GUR 3, east coast South Island",
  region = "East coast South Island; GUR 3 Quota Management Area",
  ocean = "Southwest Pacific",
  notes = "Current Fisheries New Zealand red gurnard management unit. The assessment catch covers the whole GUR 3 QMA; the CPUE and Kaharoa ECSI survey indices cover FMA 3. No Charbonneau-Keith match identified.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2022", terminal_year = "2021", estimate_terminal_year = "2021",
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.17", is_current = "TRUE", is_applied = "TRUE",
  framework_year = NA_character_,
  assessment_url = "https://fs.fish.govt.nz/Doc/25168/FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf.ashx",
  framework_url = NA_character_, data_url = NA_character_, model_url = NA_character_,
  repository_url = NA_character_, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "FAR 2022/21 documents the first full quantitative GUR 3 assessment, fitted through model year 2021.",
    "Canonical inputs preserve published model catches, survey biomass and CVs, age and length compositions,",
    "and fixed assumptions. Numeric BT-MIX CPUE values are described but not tabulated, and the report does",
    "not publish annual numerical N-at-age or F-at-age surfaces; see the source review for unresolved gaps."
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

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
assessments_current <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
stock_exists <- stock_id %in% stocks$stock_id
assessment_exists <- assessment_id %in% assessments_current$assessment_id
if (xor(stock_exists, assessment_exists)) {
  stop("GUR 3 stock and assessment records are inconsistent.", call. = FALSE)
}
if (write_mode && stock_exists) {
  stop("GUR 3 source records are already present.", call. = FALSE)
}

candidate_register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- match(candidate_id, candidate_register$candidate_id)
valid_import_status <- if (write_mode) "not_started" else c("not_started", "partial")
if (is.na(candidate_row) ||
    !candidate_register$import_status[candidate_row] %in% valid_import_status ||
    candidate_register$eligibility[candidate_row] != "eligible") {
  stop("The GUR 3 candidate is missing, ineligible, or already imported.", call. = FALSE)
}
selected <- read.csv("discovery/selected_batch_17_2026.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
selected_row <- match(candidate_id, selected$candidate_id)
if (is.na(selected_row)) stop("GUR 3 is missing from its selected batch.", call. = FALSE)

cat("Prepared ", nrow(inputs), " input rows (", nrow(catch_inputs), " catch biomass; ",
  nrow(biomass_inputs), " survey biomass/CV; ", nrow(age_inputs), " age composition; ",
  nrow(length_inputs), " length composition; ", nrow(biology_inputs), " fixed M/maturity), ", nrow(assumptions),
  " assumptions, and ", nrow(outputs), " output summaries.\n", sep = "")
cat("CPUE index values and annual N/F age surfaces remain unavailable from the report tables.\n")

if (write_mode) {
  append_rows("database/stocks.csv", stock)
  append_rows("database/assessments.csv", assessment)
  append_rows("database/inputs.csv", inputs)
  append_rows("database/assumptions.csv", assumptions)
  append_rows("database/outputs.csv", outputs)

  source("scripts/database/candidate_register_io.R")
  candidate_register$matched_stock_id[candidate_row] <- stock_id
  candidate_register$match_status[candidate_row] <- "matched"
  candidate_register$import_status[candidate_row] <- "partial"
  replace_candidate_register_row(
    "discovery/candidates.csv", candidate_row,
    candidate_register[candidate_row, , drop = FALSE], candidate_id
  )
  selected$curation_status[selected_row] <- "partial_source_import"
  write.csv(selected, "discovery/selected_batch_17_2026.csv",
    row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Imported partial GUR 3 source records and refreshed the discovery summaries.\n")
}
