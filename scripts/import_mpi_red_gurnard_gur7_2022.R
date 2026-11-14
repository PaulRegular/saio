assessment_id <- "mpi_red_gurnard_gur7_2022"
stock_id <- "mpi_red_gurnard_gur7"
candidate_id <- "MPI:GUR7"
report <- file.path("source_cache", "nz_red_gurnard_gur7_2022",
  "FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(report)) stop("The cached GUR 7 assessment report is required.", call. = FALSE)
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
  "C6AFAA340A1EDBDC44E8B6B0AB9DCDD17262558E098859F0DC57DB11E4E1CD84")) {
  stop("The cached GUR 7 report does not match the reviewed source.", call. = FALSE)
}

pdf_lines <- unlist(lapply(pdftools::pdf_text(report), function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE)

section_lines <- function(start, end) {
  a <- grep(start, pdf_lines)
  b <- grep(end, pdf_lines)
  if (length(a) != 1L || length(b) != 1L || b <= a) {
    stop("Could not locate a unique GUR 7 source-table section: ", start, call. = FALSE)
  }
  pdf_lines[(a + 1L):(b - 1L)]
}

number_tokens <- function(x) {
  hits <- regmatches(x, gregexpr("[0-9]+(?:\\.[0-9]+)?", x, perl = TRUE))[[1L]]
  if (identical(hits, character(0))) numeric() else as.numeric(hits)
}

parse_catches <- function() {
  lines <- section_lines("^Table A1:", "^Table A2:")
  lines <- lines[grepl("^\\s*(?:(?:19|20)[0-9]{2}\\s|2\\s+004\\b)",
    lines, perl = TRUE)]
  result <- list()
  for (line in lines) {
    line <- sub("^\\s*2\\s+004(?=\\s)", "2004", line, perl = TRUE)
    matches <- gregexpr("(?<!\\d)(?:19|20)[0-9]{2}(?!\\d)", line, perl = TRUE)[[1L]]
    if (matches[1L] < 0L) next
    years <- regmatches(line, list(matches))[[1L]]
    lengths_year <- attr(matches, "match.length")
    starts <- matches + lengths_year
    values <- vapply(seq_along(years), function(i) {
      end <- if (i < length(years)) matches[i + 1L] - 1L else nchar(line)
      text <- trimws(substr(line, starts[i], end))
      digits <- gsub("\\s+", "", text)
      value <- suppressWarnings(as.numeric(digits))
      if (length(value) != 1L || is.na(value)) {
        stop("Could not parse the catch following year ", years[i], ".", call. = FALSE)
      }
      value
    }, numeric(1))
    result[[length(result) + 1L]] <- data.frame(
      year = as.integer(years), value = values, stringsAsFactors = FALSE
    )
  }
  x <- do.call(rbind, result)
  x <- x[order(x$year), , drop = FALSE]
  if (nrow(x) != 35L || !identical(x$year, 1987:2021)) {
    stop("Table A1 does not contain the expected 1987-2021 catch series.", call. = FALSE)
  }
  if (!identical(x$value[match(c(1987L, 2004L, 2021L), x$year)], c(421, 717, 1073))) {
    stop("Table A1 catch anchors do not match the source report.", call. = FALSE)
  }
  x
}

parse_survey_biomass <- function() {
  lines <- section_lines("^Table 1:", "^Figure 2:")
  lines <- lines[grepl("^\\s*(?:19|20)[0-9]{2}/(?:19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+")[[1L]]
    year <- as.integer(strsplit(fields[1L], "/", fixed = TRUE)[[1L]][2L])
    i <- 2L
    biomass_text <- fields[i]
    if (i + 1L <= length(fields) && nchar(fields[i]) == 1L &&
        nchar(fields[i + 1L]) == 3L && grepl("^[0-9]+$", fields[i + 1L])) {
      biomass_text <- paste0(fields[i], fields[i + 1L])
      i <- i + 1L
    }
    biomass <- as.numeric(biomass_text)
    cv_percent <- as.numeric(fields[i + 1L])
    data.frame(year = year, biomass = biomass, cv = cv_percent / 100,
      stringsAsFactors = FALSE)
  })
  x <- do.call(rbind, rows)
  expected_years <- c(1992L, 1994L, 1995L, 1997L, 2000L, 2003L, 2005L,
    2007L, 2009L, 2011L, 2013L, 2015L, 2017L, 2019L, 2021L)
  if (nrow(x) != 15L || !identical(x$year, expected_years) ||
      any(!is.finite(x$biomass)) || any(!is.finite(x$cv))) {
    stop("Table 1 does not contain the expected survey biomass and CV rows.", call. = FALSE)
  }
  if (!identical(x$biomass[match(c(1992L, 2011L, 2021L), x$year)], c(572, 1070, 2019)) ||
      !identical(x$cv[match(c(1992L, 2011L, 2021L), x$year)], c(0.15, 0.17, 0.18))) {
    stop("Table 1 survey anchors do not match the source report.", call. = FALSE)
  }
  x
}

parse_age_compositions <- function() {
  lines <- section_lines("^Table A2:", "^Table A3a:")
  lines <- lines[grepl("^\\s*(?:10|[1-9])\\s+0\\.", lines, perl = TRUE)]
  rows <- lapply(lines, number_tokens)
  if (length(rows) != 10L || any(lengths(rows) != 11L)) {
    stop("Table A2 must contain ten ages and ten proportions per age.", call. = FALSE)
  }
  values <- do.call(rbind, rows)
  if (!identical(as.integer(values[, 1L]), 1:10) ||
      any(!is.finite(values[, -1L])) || any(values[, -1L] < 0 | values[, -1L] > 1)) {
    stop("Table A2 contains unexpected age values or proportions.", call. = FALSE)
  }
  years <- c(1994L, 1995L, 2003L, 2005L, 2007L)
  result <- list()
  for (sex in c("female", "male")) {
    columns <- if (sex == "female") 2:6 else 7:11
    for (j in seq_along(years)) {
      result[[length(result) + 1L]] <- data.frame(
        year = years[j], age = as.integer(values[, 1L]), sex = sex,
        value = values[, columns[j]], stringsAsFactors = FALSE
      )
    }
  }
  x <- do.call(rbind, result)
  totals <- vapply(years, function(year) sum(x$value[x$year == year]), numeric(1))
  if (any(abs(totals - 1) > 0.001)) {
    stop("Table A2 female and male age proportions do not sum to one by year.", call. = FALSE)
  }
  x
}

parse_length_table <- function(start, end, years, table_name) {
  lines <- section_lines(start, end)
  lines <- lines[grepl("^\\s*(?:1[0-9]|[2-4][0-9]|5[0-5])\\s+0\\.",
    lines, perl = TRUE)]
  rows <- lapply(lines, number_tokens)
  if (length(rows) != 46L || any(lengths(rows) != 11L)) {
    stop(table_name, " must contain 46 lengths and ten proportions per row.", call. = FALSE)
  }
  values <- do.call(rbind, rows)
  if (!identical(as.integer(values[, 1L]), 10:55) ||
      any(!is.finite(values[, -1L])) || any(values[, -1L] < 0 | values[, -1L] > 1)) {
    stop(table_name, " contains unexpected length bins or proportions.", call. = FALSE)
  }
  result <- list()
  for (sex in c("female", "male")) {
    columns <- if (sex == "female") 2:6 else 7:11
    for (j in seq_along(years)) {
      result[[length(result) + 1L]] <- data.frame(
        year = years[j], sex = sex, length_bin = as.character(as.integer(values[, 1L])),
        value = values[, columns[j]], table_name = table_name,
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, result)
}

parse_length_compositions <- function() {
  x <- rbind(
    parse_length_table("^Table A3a:", "^Table A3b:",
      c(1992L, 1997L, 2000L, 2009L, 2011L), "Table A3a"),
    parse_length_table("^Table A3b:", "^Figure A1:",
      c(2013L, 2015L, 2017L, 2019L, 2021L), "Table A3b")
  )
  totals <- vapply(sort(unique(x$year)), function(year) sum(x$value[x$year == year]), numeric(1))
  if (any(abs(totals - 1) > 0.002)) {
    stop("Table A3a/A3b female and male length proportions do not sum to one by year.", call. = FALSE)
  }
  x
}

fmt <- function(x) format(x, scientific = FALSE, trim = TRUE, digits = 15)

input_row <- function(type, measure, basis, value, unit, year,
                      fleet = NA_character_, survey = NA_character_,
                      sex = NA_character_, season = NA_character_, region = NA_character_,
                      age = NA_character_, age_group = "", length_bin = NA_character_,
                      observation_id = NA_character_, notes = "", transformation = "",
                      source_reference, sample_size = NA_character_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = as.character(year),
    year_basis = if (is.na(year)) NA_character_ else "model_year",
    age = as.character(age), value = fmt(value), unit = unit,
    sampling_time = NA_character_, source_type = "official_table",
    source_reference = source_reference, transformation = transformation, notes = notes,
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
    value = x$value, unit = "tonnes", year = x$year,
    fleet = "GUR 7 commercial trawl fishery", region = "GUR 7",
    season = "annual", observation_id = paste0("gur7_catch_", x$year),
    notes = paste(
      "Annual model catch in tonnes; year denotes the fishing year beginning in that year.",
      "The source states that no under-reporting adjustment was applied."
    ),
    source_reference = "Langley 2022, FAR 2022/22, Table A1, pp. 28-29"
  )
}))

biomass_inputs <- do.call(rbind, lapply(seq_len(nrow(survey_table)), function(i) {
  x <- survey_table[i, ]
  observation_id <- paste0("gur7_wcsisurvey_biomass_", x$year)
  rbind(
    input_row(
      type = "index", measure = "total_biomass", basis = "biomass",
      value = x$biomass, unit = "tonnes", year = x$year,
      survey = "Kaharoa WCSI trawl survey", observation_id = observation_id,
      notes = "Aggregate survey biomass index as reported.",
      source_reference = "Langley 2022, FAR 2022/22, Table 1, p. 3"
    ),
    input_row(
      type = "index", measure = "biomass_index_cv", basis = "relative_scale",
      value = x$cv, unit = "ratio", year = x$year,
      survey = "Kaharoa WCSI trawl survey", observation_id = paste0(observation_id, "_CV"),
      transformation = "Source CV percent divided by 100 to store the ratio.",
      notes = "Source reports CV as a percent; stored here as a ratio for the corresponding biomass observation.",
      source_reference = "Langley 2022, FAR 2022/22, Table 1, p. 3"
    )
  )
}))

age_inputs <- do.call(rbind, lapply(seq_len(nrow(age_table)), function(i) {
  x <- age_table[i, ]
  input_row(
    type = "index", measure = "proportion_at_age", basis = "proportion_numbers",
    value = x$value, unit = "proportion", year = x$year,
    survey = "Kaharoa WCSI trawl survey", sex = x$sex,
    age = x$age, age_group = if (x$age == 10L) "10+" else "",
    observation_id = paste0("gur7_survey_age_", x$year),
    notes = paste(
      "Published age-composition components are preserved without renormalization; female and male values together form one survey composition.",
      "Raw age sample counts are not reported; sample_size is left blank. Age 10 represents the 10+ plus group."
    ),
    source_reference = "Langley 2022, FAR 2022/22, Table A2, p. 28"
  )
}))

length_inputs <- do.call(rbind, lapply(seq_len(nrow(length_table)), function(i) {
  x <- length_table[i, ]
  input_row(
    type = "index", measure = "proportion_at_length", basis = "proportion_numbers",
    value = x$value, unit = "proportion", year = x$year,
    survey = "Kaharoa WCSI trawl survey", sex = x$sex,
    length_bin = x$length_bin,
    observation_id = paste0("gur7_survey_length_", x$year),
    notes = paste(
      "Published length-composition components are preserved without renormalization; female and male values together form one survey composition.",
      "Length labels are in cm as printed; the report does not provide bin boundaries or raw sample counts; sample_size is left blank."
    ),
    source_reference = paste0("Langley 2022, FAR 2022/22, ", x$table_name, ", pp. 29-30")
  )
}))

biology_inputs <- rbind(
  do.call(rbind, lapply(c("female", "male"), function(sex) {
    do.call(rbind, lapply(1:10, function(age) input_row(
      type = "M", measure = "natural_mortality_at_age", basis = "per_year",
      value = 0.31, unit = "year^-1", year = NA_character_, sex = sex,
      age = age, age_group = if (age == 10L) "10+" else "",
      observation_id = paste0("gur7_M_", sex, "_", age),
      notes = if (age == 10L) "Fixed base-model input; age 10 is the 10+ plus group." else "Fixed base-model input.",
      source_reference = "Langley 2022, FAR 2022/22, Table 2, p. 7"
    )))
  })),
  do.call(rbind, lapply(1:10, function(age) input_row(
    type = "maturity", measure = "maturity_at_age", basis = "proportion",
    value = if (age == 1L) 0 else if (age == 2L) 0.5 else 1,
    unit = "proportion", year = NA_character_, sex = "female", age = age,
    age_group = if (age == 10L) "10+" else "",
    observation_id = paste0("gur7_maturity_female_", age),
    notes = if (age == 10L) "Fixed base-model spawning maturity; age 10 is the 10+ plus group." else "Fixed base-model spawning maturity for female fish.",
    source_reference = "Langley 2022, FAR 2022/22, Table 2, p. 7"
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
  assumption("model", "software_version", "Stock Synthesis 3.30.17", "Langley 2022, FAR 2022/22, p. 6"),
  assumption("population", "model_year_range", "1987-2021; model year denotes the fishing year beginning in that year", "Langley 2022, FAR 2022/22, pp. 6-7"),
  assumption("population", "model_age_range", "Ages 1-9 and 10+; two sexes; one stock area", "Langley 2022, FAR 2022/22, p. 6"),
  assumption("population", "initial_population", "Population initialized in an exploited equilibrium state in 1987", "Langley 2022, FAR 2022/22, p. 6"),
  assumption("population", "annual_cycle", "Annual time step with no seasonal structure; spawning and recruitment occur instantaneously at the start of the model year", "Langley 2022, FAR 2022/22, p. 6"),
  assumption("fishery", "catch_timing", "One commercial trawl fishery operates through the fishing year; catch is taken instantaneously at midyear", "Langley 2022, FAR 2022/22, p. 6"),
  assumption("catch", "model_catch_coverage", "Commercial trawl catch for the GUR 7 management unit", "Langley 2022, FAR 2022/22, pp. 5-6"),
  assumption("catch", "under_reporting", "No allowance for under-reporting was applied to commercial model catch", "Langley 2022, FAR 2022/22, p. 5"),
  assumption("catch", "excluded_catches", "Recreational catches estimated at 11-38 t annually and customary catches were excluded", "Langley 2022, FAR 2022/22, p. 6", "The report states no customary catch estimates were available."),
  assumption("mortality", "natural_mortality", "Base-model M fixed at 0.31 y-1 for female and male fish", "Langley 2022, FAR 2022/22, Table 2, p. 7", "The value was informed by an earlier study using the 1994 and 1995 survey age compositions; the base model fixes it."),
  assumption("biology", "growth", "Von Bertalanffy growth: female Linf=45.7 cm, k=0.40, length-at-age-1=19.4 cm; male Linf=40.3 cm, k=0.37, length-at-age-1=19.4 cm; CV length-at-age=0.10", "Langley 2022, FAR 2022/22, Table 2, p. 7"),
  assumption("biology", "length_weight", "Mean weight (kg)=5.3e-6 * length(cm)^3.19", "Langley 2022, FAR 2022/22, Table 2, p. 7"),
  assumption("maturity", "maturity_at_age", "0 at age 1, 0.5 at age 2, and 1 at ages 3+", "Langley 2022, FAR 2022/22, Table 2, p. 7"),
  assumption("biology", "sex_ratio", "Female fish assumed to comprise 50% of population numbers and biomass", "Langley 2022, FAR 2022/22, p. 6"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt relationship with a Beta prior on steepness; prior mode h=0.85", "Langley 2022, FAR 2022/22, Table 4, p. 8"),
  assumption("recruitment", "year_class_strengths", "Recruitment deviations estimated for 1987-2020 with log-scale sigmaR=0.6; 2021 recruitment comes from the stock-recruitment relationship", "Langley 2022, FAR 2022/22, pp. 6-7; Table 2"),
  assumption("observation", "fishery_compositions", "No commercial fishery age or length compositions were available", "Langley 2022, FAR 2022/22, p. 5"),
  assumption("observation", "cpue_index", "Commercial trawl CPUE indices were not included in the assessment", "Langley 2022, FAR 2022/22, p. 5", "The report says CPUE trends differed from Kaharoa WCSI survey biomass trends and were considered less reliable."),
  assumption("observation", "survey_biomass_likelihood", "Kaharoa WCSI biomass indices use a lognormal likelihood with the native survey CVs and no additional process error", "Langley 2022, FAR 2022/22, pp. 7-8; Table 3"),
  assumption("observation", "survey_age_composition", "Five survey age compositions (1994, 1995, 2003, 2005, 2007) use a multinomial likelihood with ESS=50 and no ageing error", "Langley 2022, FAR 2022/22, pp. 7-8; Tables 2-3"),
  assumption("observation", "survey_length_composition", "Ten survey length compositions (1992, 1997, 2000, 2009, 2011, 2013, 2015, 2017, 2019, 2021) use a multinomial likelihood with ESS=50", "Langley 2022, FAR 2022/22, pp. 7-8; Table 3"),
  assumption("selectivity", "survey_selectivity", "Age-based logistic survey selectivity; younger-fish selectivity is allowed to vary for females", "Langley 2022, FAR 2022/22, p. 7; Table 4"),
  assumption("selectivity", "fishery_selectivity", "Age-based logistic selectivity with two parameters informed by priors approximating full selection near 30 cm", "Langley 2022, FAR 2022/22, p. 7; Table 4"),
  assumption("catchability", "survey_q", "One trawl-survey log-q parameter with an uninformative prior", "Langley 2022, FAR 2022/22, p. 7; Table 4"),
  assumption("mortality", "fishing_mortality_method", "Hybrid method uses Pope's approximation to calculate harvest rate and converts it to fishery-specific F", "Langley 2022, FAR 2022/22, p. 7"),
  assumption("estimation", "estimated_parameters", "Base model estimates lnR0; steepness with Beta(0.80, 0.125) prior; 34 recruitment deviations; 3 survey-selectivity parameters; 1 survey ln-q; 2 fishery-selectivity parameters; and 1 initial-F parameter with Normal(0.4, 0.2) prior", "Langley 2022, FAR 2022/22, Table 4, p. 8"),
  assumption("uncertainty", "mcmc", "Metropolis-Hastings MCMC; 1,000 samples at 1,000 intervals from a chain of 1.1 million after 100,000 burn-in", "Langley 2022, FAR 2022/22, p. 8"),
  assumption("observation", "survey_timing", "Annual model has no seasonal structure and the report does not provide fractional within-year sampling times", "Langley 2022, FAR 2022/22, pp. 6-8", "Table 3 notes that model year 2021 includes a trawl survey conducted in March 2021."),
  assumption("projection", "projection_period", "Base-model projections cover 2022-2026; commercial catch is held at the current TACC of 1,298 t and future recruitment is resampled from the 2011-2020 average with variation using sigmaR", "Langley 2022, FAR 2022/22, pp. 18-19; Table 9")
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
  output_row("biomass", "unfished_spawning_biomass", 4500, "tonnes",
    "Langley 2022, FAR 2022/22, Table 6, p. 16", "Base-model MPD point estimate of SB0.", scenario = "Base; MPD"),
  output_row("biomass", "SSB_ratio_to_B0", 1.126, "ratio",
    "Langley 2022, FAR 2022/22, Table 6, p. 16", "Base-model MPD estimate of SB2021/SB0.", year = 2021, scenario = "Base; MPD"),
  output_row("mortality", "F_ratio_to_FSB40", 0.474, "ratio",
    "Langley 2022, FAR 2022/22, Table 6, p. 16", "Base-model MPD estimate of F2021/FSB40%.", year = 2021, scenario = "Base; MPD"),
  output_row("catch", "yield_at_FSB40", 2496, "tonnes",
    "Langley 2022, FAR 2022/22, Table 6, p. 16", "Current potential yield from applying FSB40% to current biomass; base-model MPD estimate.", year = 2021, scenario = "Base; MPD"),
  output_row("biomass", "unfished_spawning_biomass", 4990, "tonnes",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "Base-model MCMC median; the source reports a 95% interval from MCMC samples.", lwr = 4226, upr = 6247, scenario = "Base; MCMC median"),
  output_row("biomass", "spawning_biomass", 5528, "tonnes",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "2020/21 spawning biomass (model year 2021); MCMC median and source-reported 95% interval.", year = 2021, lwr = 3779, upr = 7919, scenario = "Base; MCMC median"),
  output_row("biomass", "SSB_ratio_to_B0", 1.108, "ratio",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "SSB2021/SB0; MCMC median and source-reported 95% interval.", year = 2021, lwr = 0.799, upr = 1.44, scenario = "Base; MCMC median"),
  output_row("biomass", "probability_above_35_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "MCMC probability that 2021 spawning biomass exceeds 35% SB0.", year = 2021, scenario = "Base; MCMC"),
  output_row("biomass", "probability_above_20_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "MCMC probability that 2021 spawning biomass exceeds 20% SB0.", year = 2021, scenario = "Base; MCMC"),
  output_row("biomass", "probability_above_10_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "MCMC probability that 2021 spawning biomass exceeds 10% SB0.", year = 2021, scenario = "Base; MCMC"),
  output_row("mortality", "F_reference_at_SB40", 0.2248, "year^-1",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "Base-model MCMC median reference F associated with 40% SB0."),
  output_row("mortality", "F_ratio_to_FSB40", 0.44, "ratio",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "F2021/FSB40%; MCMC median and source-reported 95% interval.", year = 2021, lwr = 0.296, upr = 0.686, scenario = "Base; MCMC median"),
  output_row("mortality", "probability_below_FSB40", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 7, p. 17", "MCMC probability that 2021 F is below FSB40%.", year = 2021, scenario = "Base; MCMC"),
  output_row("catch", "yield_at_FSB40", 953, "tonnes",
    "Langley 2022, FAR 2022/22, Table 8, p. 18", "Equilibrium yield at FSB40%; base-model MCMC median and source-reported 95% interval.", lwr = 811, upr = 1149, scenario = "Base; MCMC median equilibrium yield"),
  output_row("catch", "yield_at_FSB40", 2748, "tonnes",
    "Langley 2022, FAR 2022/22, Table 8, p. 18", "Yield at FSB40% applied to 2020/21 biomass; base-model MCMC median and source-reported 95% interval.", year = 2021, lwr = 1609, upr = 4681, scenario = "Base; MCMC median current-biomass yield"),
  output_row("biomass", "SSB_ratio_to_B0", 0.969, "ratio",
    "Langley 2022, FAR 2022/22, Table 9, p. 18", "Projected SB2026/SB0; base-model MCMC median and source-reported 95% interval.", year = 2026, lwr = 0.667, upr = 1.376, scenario = "Base; projection"),
  output_row("biomass", "probability_above_35_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 9, p. 18", "MCMC probability that projected 2026 spawning biomass exceeds 35% SB0.", year = 2026, scenario = "Base; projection"),
  output_row("biomass", "probability_above_20_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 9, p. 18", "MCMC probability that projected 2026 spawning biomass exceeds 20% SB0.", year = 2026, scenario = "Base; projection"),
  output_row("biomass", "probability_above_10_percent_B0", 1.00, "probability",
    "Langley 2022, FAR 2022/22, Table 9, p. 18", "MCMC probability that projected 2026 spawning biomass exceeds 10% SB0.", year = 2026, scenario = "Base; projection")
))

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "Fisheries New Zealand", authority_stock_id = "GUR 7",
  scientific_name = "Chelidonichthys kumu", common_name = "Red gurnard",
  area = "GUR 7, Challenger",
  region = "Challenger; GUR 7 Quota Management Area",
  ocean = "Southwest Pacific",
  notes = "Current Fisheries New Zealand red gurnard management unit. The 2022 assessment covers the GUR 7 commercial trawl fishery and Kaharoa West Coast South Island survey. No Charbonneau-Keith match was identified.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = "2022", terminal_year = "2021", estimate_terminal_year = "2021",
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.17", is_current = "TRUE", is_applied = "TRUE",
  framework_year = NA_character_,
  assessment_url = "https://fs.fish.govt.nz/Doc/25169/FAR-2022-22-Red-Gurnard-Stock-Assessment-GUR7-2022-4295.pdf.ashx",
  framework_url = NA_character_, data_url = NA_character_, model_url = NA_character_,
  repository_url = NA_character_, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "FAR 2022/22 documents the current GUR 7 quantitative assessment, fitted through model year 2021.",
    "Canonical records preserve reported catch biomass, survey biomass and CVs, survey age and length compositions, fixed mortality and maturity inputs, and aggregate model outputs.",
    "Commercial catch-at-age and numerical annual N-at-age/F-at-age surfaces are not published."
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
  stop("GUR 7 stock and assessment records are inconsistent.", call. = FALSE)
}
if (write_mode && stock_exists) {
  stop("GUR 7 source records are already present.", call. = FALSE)
}

candidate_register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- match(candidate_id, candidate_register$candidate_id)
selected <- read.csv("discovery/selected_batch_18_2026.csv", stringsAsFactors = FALSE,
  colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
selected_row <- match(candidate_id, selected$candidate_id)
if (is.na(candidate_row) || is.na(selected_row) ||
    candidate_register$import_status[candidate_row] != "not_started" ||
    candidate_register$screening_status[candidate_row] != "screened" ||
    selected$curation_status[selected_row] != "selected_for_partial_source_import") {
  stop("GUR 7 is missing from the selected partial-source batch or was already imported.", call. = FALSE)
}

cat("Prepared ", nrow(inputs), " input rows (", nrow(catch_inputs), " catch biomass; ",
  nrow(biomass_inputs), " survey biomass/CV; ", nrow(age_inputs), " age composition; ",
  nrow(length_inputs), " length composition; ", nrow(biology_inputs), " fixed M/maturity), ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " output summaries.\n", sep = "")
cat("Commercial catch-at-age, CPUE values, and annual N/F-at-age surfaces are not available in the report.\n")

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
  write.csv(selected, "discovery/selected_batch_18_2026.csv",
    row.names = FALSE, na = "")
  source("scripts/database/195_summarize_discovery.R", local = TRUE)
  source("scripts/database/196_summarize_inventory_units.R", local = TRUE)
  cat("Imported partial GUR 7 source records and refreshed the discovery summaries.\n")
}
