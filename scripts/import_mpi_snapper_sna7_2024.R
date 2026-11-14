.libPaths(c(file.path("source_cache", "r-lib"), .libPaths()))

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached Fisheries New Zealand assessment PDF.")
}

assessment_id <- "mpi_snapper_sna7_2024"
stock_id <- "mpi_snapper_sna7"
assessment_pdf <- file.path(
  "source_cache", "mpi_snapper_sna7_2024", "FAR-2024-48-SNA7-assessment.pdf"
)

pdf_words <- pdftools::pdf_data(assessment_pdf)
pdf_text <- pdftools::pdf_text(assessment_pdf)

cell_text <- function(data, y, lower, upper) {
  cells <- data[
    abs(data$y - y) < 1.6 &
      data$x >= lower & data$x < upper &
      grepl("^[0-9]+$", data$text),
    , drop = FALSE
  ]
  if (!nrow(cells)) return(NA_character_)
  paste0(cells$text[order(cells$x)], collapse = "")
}

cell_number <- function(data, y, anchor, tolerance = 7) {
  cells <- data[
    abs(data$y - y) < 1.6 &
      abs(data$x - anchor) <= tolerance &
      grepl("^[0-9]+\\.?[0-9]*$", data$text),
    , drop = FALSE
  ]
  if (!nrow(cells)) return(NA_real_)
  cells <- cells[which.min(abs(cells$x - anchor)), , drop = FALSE]
  as.numeric(cells$text[[1]])
}

table_ages <- function(page, anchors, source_table, years, ess = NULL,
                       fleets = NULL, surveys = NULL, region = "SNA 7") {
  data <- pdf_words[[page]]
  age_label <- grepl("^[0-9]+$", data$text)
  age_number <- rep(NA_integer_, nrow(data))
  age_number[age_label] <- as.integer(data$text[age_label])
  age_cells <- data[
    data$x < 105 & data$y > 145 &
      age_number %in% 1:30,
    , drop = FALSE
  ]
  age_y <- age_cells$y[match(as.character(1:30), age_cells$text)]
  if (anyNA(age_y)) stop(source_table, " is missing one or more age labels.")

  values <- vapply(seq_along(anchors), function(column) {
    vapply(seq_along(age_y), function(age_index) {
      cell_number(data, age_y[[age_index]], anchors[[column]], tolerance = 8)
    }, numeric(1))
  }, numeric(length(age_y)))
  rownames(values) <- as.character(1:30)
  colnames(values) <- as.character(years)

  list(
    years = years,
    values = values,
    ess = ess,
    fleets = fleets,
    surveys = surveys,
    source_table = source_table,
    region = region
  )
}

tables_age <- list(
  table_ages(
    95, c(128, 176, 224, 271, 319), "Table A6, p. 93",
    c(1974, 1978, 1979, 1980, 1983),
    ess = rep(17, 5), fleets = rep("BPT", 5)
  ),
  table_ages(
    96, c(119, 159, 199, 238, 278, 318, 360, 400, 440, 479, 519),
    "Table A7, p. 94",
    c(1992, 1997, 1998, 1999, 2000, 2003, 2006, 2013, 2016, 2019, 2022),
    fleets = rep("BT1", 11)
  ),
  table_ages(
    97, c(129, 175, 221, 267, 313), "Table A8, p. 95",
    c(2006, 2013, 2016, 2019, 2022),
    fleets = rep("BT2", 5)
  ),
  table_ages(
    98, c(130, 188, 245, 302, 391, 448, 505), "Table A9, p. 96",
    c(2016, 2018, 2020, 2022, 2018, 2020, 2022),
    ess = c(50, 50, 10, 50, 50, 10, 50),
    surveys = c(
      rep("Kaharoa trawl survey, core strata", 4),
      rep("Kaharoa trawl survey, core plus 10-20 m TBGB", 3)
    ),
    region = "WCSI, Tasman Bay and Golden Bay"
  )
)

table_cpue <- function(page, fleet, years_used, season) {
  data <- pdf_words[[page]]
  year_cells <- data[
    data$x >= 110 & data$x <= 145 & data$y > 145 &
      grepl("^[0-9]{4}$", data$text),
    , drop = FALSE
  ]
  if (nrow(year_cells) != 34L) {
    stop("Expected 34 annual CPUE rows for ", fleet, ".")
  }
  rows <- lapply(seq_len(nrow(year_cells)), function(i) {
    y <- year_cells$y[[i]]
    data.frame(
      year = as.integer(year_cells$text[[i]]),
      index = cell_number(data, y, 158, 8),
      lwr = cell_number(data, y, 199, 8),
      upr = cell_number(data, y, 241, 8)
    )
  })
  result <- do.call(rbind, rows)
  result <- result[result$year %in% years_used, , drop = FALSE]
  result$fleet <- fleet
  result$season <- season
  result
}

cpue <- rbind(
  table_cpue(89, "BT1", 1989:2009, "October-December"),
  table_cpue(90, "BT2", 1989:2022, "January-April")
)

catch_table <- function() {
  data <- pdf_words[[94]]
  years <- data[
    data$y > 180 & data$x < 330 & grepl("^[0-9]{4}$", data$text),
    , drop = FALSE
  ]
  left_columns <- list(c(120, 165), c(165, 197), c(197, 240), c(240, 280))
  right_columns <- list(c(340, 385), c(385, 415), c(415, 460), c(460, 495))
  fleets <- c("BT1", "BT2", "BPT", "Recreational")
  seasons <- c("October-December", "January-April", "Pair trawl", "Annual")
  records <- list()
  for (i in seq_len(nrow(years))) {
    year <- years[i, ]
    left <- year$x[[1]] < 200
    columns <- if (left) left_columns else right_columns
    for (j in seq_along(fleets)) {
      value <- cell_text(data, year$y[[1]], columns[[j]][[1]], columns[[j]][[2]])
      if (is.na(value)) stop("Missing catch value for model year ", year$text[[1]], ".")
      records[[length(records) + 1L]] <- list(
        year = as.integer(year$text[[1]]),
        fleet = fleets[[j]],
        season = seasons[[j]],
        value = as.numeric(value)
      )
    }
  }
  result <- do.call(rbind, lapply(records, as.data.frame))
  result[order(result$year, result$fleet), , drop = FALSE]
}

catch <- catch_table()

length_table <- function(page, left_anchors, right_anchors, values_are_counts) {
  data <- pdf_words[[page]]
  labels <- data[
    data$y > 145 & data$y < 750 & grepl("^[0-9]+$", data$text) &
      ((data$x < 105) | (data$x >= 315 & data$x <= 350)),
    , drop = FALSE
  ]
  labels$length <- as.integer(labels$text)
  labels <- labels[labels$length >= 10 & labels$length <= 150, , drop = FALSE]
  years <- if (values_are_counts) {
    c(2005, 2011, 2015:2021)
  } else {
    c(2008, 2010, 2012, 2014)
  }
  rows <- list()
  for (i in seq_len(nrow(labels))) {
    label <- labels[i, ]
    right_block <- label$x[[1]] >= 315
    anchors <- if (right_block) right_anchors else left_anchors
    for (j in seq_along(years)) {
      value <- cell_number(data, label$y[[1]], anchors[[j]], tolerance = 8)
      rows[[length(rows) + 1L]] <- list(
        year = years[[j]],
        length = label$length[[1]],
        value = value
      )
    }
  }
  result <- do.call(rbind, lapply(rows, as.data.frame))
  result[order(result$year, result$length), , drop = FALSE]
}

survey_length <- length_table(
  99, c(122, 165, 207, 250), c(377, 420, 462, 505), FALSE
)
recreational_length <- length_table(
  100, c(112, 135, 158, 180, 203, 226, 248, 271, 294),
  c(359, 382, 405, 428, 450, 472, 495, 518, 541), TRUE
)

survey_index_year <- c(1991, 1993, 1994, 1996, 1999, 2002, 2004, 2006,
                       2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022)
survey_biomass <- c(71, 15, 22, 115, 21, 10, 10, 56, 81, 66, 277, 837,
                    674, 972, 883, 3633)
survey_cv <- c(0.32, 0.56, 0.47, 0.48, 0.59, 0.934, 0.70, 0.70, 0.58,
               0.31, 0.56, 0.32, 0.20, 0.14, 0.20, 0.21)

age_samples <- data.frame(
  year = c(1978, 1979, 1980, 1983, 1992, 1997, 1998, 1999, 2000, 2003,
           2006, 2013, 2016, 2019, 2022),
  n = c(295, 84, 348, 265, 364, 1439, 913, 1004, 1035, 1007, 1007, 848,
        1440, 1500, 897),
  fleet = c(rep("BPT", 4), "BT1", "BT1", "BT1", "BT1", "BT1", "BT1",
            rep("BT1/BT2 pooled", 5)),
  stringsAsFactors = FALSE
)

new_input <- function(type, measure, basis, value, unit, source_type,
                      source_reference, notes, year = "", year_basis = "",
                      age = "", age_group = "", fleet = "", survey = "",
                      region = "SNA 7", season = "", sampling_time = "",
                      transformation = "", observation_id = "",
                      length_bin = "", sample_size = "", sex = "",
                      partition = "") {
  list(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = sex, region = region,
    season = season, year = year, year_basis = year_basis, age = age,
    age_group = age_group, value = value, unit = unit,
    sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    sample_size = sample_size, partition = partition
  )
}

input_rows <- list()

for (i in seq_len(nrow(catch))) {
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "catch", "total_biomass", "biomass", catch$value[[i]], "tonnes",
    "official_table", "FAR 2024/48, Table A5, p. 92",
    "Catch biomass as used by the assessment; the table includes commercial under-reporting allowances.",
    year = catch$year[[i]], year_basis = "model_year",
    fleet = catch$fleet[[i]], season = catch$season[[i]]
  )
}

for (i in seq_len(nrow(cpue))) {
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "index", "relative_biomass_index", "index_scale", cpue$index[[i]],
    "relative CPUE index", "official_table",
    if (cpue$fleet[[i]] == "BT1") "FAR 2024/48, Table A3, p. 87" else
      "FAR 2024/48, Table A4, p. 88",
    "Combined annual CPUE index. BT1 observations after 2009 are excluded from the fitted series.",
    year = cpue$year[[i]], year_basis = "model_year",
    fleet = cpue$fleet[[i]], season = cpue$season[[i]]
  )
}

survey_name <- "Kaharoa trawl survey, core strata"
survey_url <- "https://www.mpi.govt.nz/dmsdocument/61021/direct"
for (i in seq_along(survey_index_year)) {
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "index", "relative_biomass_index", "index_scale", survey_biomass[[i]],
    "tonnes", "official_table",
    paste0("FAR 2024/06, Table 7, SNA core-strata row; ", survey_url),
    "Core-strata relative biomass estimate. The survey calendar year is one greater than the model year.",
    year = survey_index_year[[i]], year_basis = "model_year", survey = survey_name,
    region = "WCSI, Tasman Bay and Golden Bay",
    transformation = "Survey calendar year from KAH survey identifier minus one, following the model-year convention in FAR 2024/48, Table A9."
  )
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "index", "biomass_index_cv", "relative_scale", survey_cv[[i]], "ratio",
    "official_table",
    paste0("FAR 2024/06, Table 7, SNA core-strata row; ", survey_url),
    "Reported survey biomass coefficient of variation; this is observation error, separate from the model's additional process error.",
    year = survey_index_year[[i]], year_basis = "model_year", survey = survey_name,
    region = "WCSI, Tasman Bay and Golden Bay",
    transformation = "Survey calendar year from KAH survey identifier minus one, following the model-year convention in FAR 2024/48, Table A9."
  )
}

input_rows[[length(input_rows) + 1L]] <- new_input(
  "index", "total_biomass", "biomass", 1549, "tonnes", "official_document",
  "FAR 2024/48, section 6.3, p. 41",
  "1987/88 Petersen tag-release estimate, represented in the assessment as a 1987 biomass observation. The report notes that the estimate is imprecise and may be biased low.",
  year = 1987, year_basis = "model_year",
  survey = "1986-1987 Petersen tag-release biomass estimate"
)
input_rows[[length(input_rows) + 1L]] <- new_input(
  "index", "biomass_index_cv", "relative_scale", 0.30, "ratio",
  "official_document", "FAR 2024/48, section 6.3, p. 41",
  "Coefficient of variation applied to the 1987 tag biomass observation."
  , year = 1987, year_basis = "model_year",
  survey = "1986-1987 Petersen tag-release biomass estimate"
)

age_source_rows <- list()
for (table in tables_age) {
  for (j in seq_along(table$years)) {
    year <- table$years[[j]]
    if (identical(table$source_table, "Table A6, p. 93") && year == 1974) next
    observation_id <- paste0("sna7_", gsub("[^a-z0-9]+", "_",
      tolower(table$source_table)), "_", year, "_", j)
    fleet <- if (is.null(table$fleets)) "" else table$fleets[[j]]
    survey <- if (is.null(table$surveys)) "" else table$surveys[[j]]
    is_survey <- nzchar(survey)
    is_bpt <- identical(fleet, "BPT")
    ess <- if (is.null(table$ess)) "" else table$ess[[j]]
    for (age in 1:30) {
      input_rows[[length(input_rows) + 1L]] <- new_input(
        if (is_survey) "index" else "catch",
        "proportion_at_age", "proportion_numbers",
        table$values[as.character(age), j],
        "proportion", "official_table", paste0("FAR 2024/48, ", table$source_table),
        if (age == 30) "Age 30 is the 30+ plus group." else
          "Proportion transcribed from the published composition; blank source cells remain missing.",
        year = year, year_basis = "model_year", age = age,
        age_group = if (age == 30) "30+" else "",
        fleet = fleet, survey = survey, region = table$region,
        season = if (fleet == "BT1") "October-December" else
          if (fleet == "BT2") "January-April" else "",
        observation_id = observation_id, sample_size = ess
      )
    }
  }
}

for (i in seq_len(nrow(age_samples))) {
  sample <- age_samples[i, ]
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "biology", "composition_sample_count", "numbers", sample$n[[1]],
    "fish", "official_table", "FAR 2024/48, Table 3, p. 29",
    if (grepl("pooled", sample$fleet[[1]], fixed = TRUE)) {
      "Raw otolith count for source samples assigned to BT1/BT2; the report does not split counts by seasonal fleet."
    } else {
      "Raw otolith count for the age-composition sample; distinct from the model's effective sample size."
    },
    year = sample$year[[1]], year_basis = "model_year",
    fleet = sample$fleet[[1]], region = "Tasman Bay and Golden Bay",
    observation_id = paste0("sna7_commercial_age_sample_", sample$year[[1]])
  )
}

for (i in seq_len(nrow(survey_length))) {
  value <- survey_length$value[[i]]
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "index", "proportion_at_length", "proportion_numbers", value, "proportion",
    "official_table", "FAR 2024/48, Table A10, p. 97",
    "Core-area survey length composition; likelihood ESS is 10 for each year.",
    year = survey_length$year[[i]], year_basis = "model_year",
    survey = survey_name, region = "WCSI, Tasman Bay and Golden Bay",
    observation_id = paste0("sna7_core_survey_length_", survey_length$year[[i]]),
    length_bin = survey_length$length[[i]], sample_size = 10
  )
}

for (i in seq_len(nrow(recreational_length))) {
  input_rows[[length(input_rows) + 1L]] <- new_input(
    "catch", "frequency_at_length", "native_frequency",
    recreational_length$value[[i]], "source frequency", "official_table",
    "FAR 2024/48, Table A11, p. 98",
    "Native recreational length-frequency count; model likelihood ESS is 1 for each year.",
    year = recreational_length$year[[i]], year_basis = "model_year",
    fleet = "Recreational", region = "Tasman Bay and Golden Bay",
    observation_id = paste0("sna7_recreational_length_", recreational_length$year[[i]]),
    length_bin = recreational_length$length[[i]], sample_size = 1
  )
}

assumption_rows <- list(
  list(component = "model", setting = "model_structure",
       value = "One-sex annual age-structured Stock Synthesis model; ages 1-30+.",
       source_reference = "FAR 2024/48, sections 2 and 6; Table 4, pp. 9, 49-50",
       notes = "The terminal age is a plus group."),
  list(component = "model", setting = "model_year_range", value = "1931-2023",
       source_reference = "FAR 2024/48, Table A5, p. 92",
       notes = "Model years are labelled by the first year of the fishing year."),
  list(component = "catch", setting = "catch_series",
       value = "BT1, BT2, BPT and recreational catch biomass in tonnes",
       source_reference = "FAR 2024/48, Table A5, p. 92",
       notes = "Commercial catches include the report's under-reporting allowances."),
  list(component = "catch", setting = "population_area",
       value = "SNA 7 includes Tasman Bay/Golden Bay and west coast South Island.",
       source_reference = "FAR 2024/48, sections 1 and 2",
       notes = "Marlborough Sounds catches are included although the report describes that area as biologically distinct."),
  list(component = "M", setting = "natural_mortality", value = "0.075 per year; fixed",
       source_reference = "FAR 2024/48, Table 4, p. 50",
       notes = "M is fixed, not estimated."),
  list(component = "biology", setting = "growth",
       value = "VB growth: L1=13.1, Lmax=69.6; k1=0.098 before 1990, k2=0.122 in 1990-2009, k3=0.103 after 2009.",
       source_reference = "FAR 2024/48, Table 4, p. 50",
       notes = "The reported age-specific growth is time-varying across three periods."),
  list(component = "biology", setting = "cv_length_at_age", value = "0.075; fixed",
       source_reference = "FAR 2024/48, Table 4, p. 50",
       notes = ""),
  list(component = "biology", setting = "length_weight",
       value = "a=3.61e-5, b=2.8644",
       source_reference = "FAR 2024/48, Table 4, p. 50",
       notes = "The report table does not explicitly state the output weight unit."),
  list(component = "biology", setting = "maturity_at_length",
       value = "Fixed logistic maturity; L50=35 cm, L5=26 cm, L95=44 cm.",
       source_reference = "FAR 2024/48, Table 4, p. 50",
       notes = "The assessment reports maturity-at-length rather than a numeric maturity-at-age vector."),
  list(component = "recruitment", setting = "stock_recruitment",
       value = "Beverton-Holt; steepness 0.95 fixed; sigmaR=1.5 fixed; LnR0 estimated.",
       source_reference = "FAR 2024/48, Table 4, p. 50",
       notes = ""),
  list(component = "index", fleet = "BT1", setting = "included_years",
       value = "1989-2009",
       source_reference = "FAR 2024/48, section 6.4 and Table 5, pp. 41, 51",
       notes = "2010-2022 BT1 indices are excluded because of concerns about increased avoidance."),
  list(component = "index", fleet = "BT2", setting = "included_years",
       value = "1989-2022",
       source_reference = "FAR 2024/48, sections 6.4 and Table 5, pp. 41, 51",
       notes = "January-April bottom-trawl CPUE is a primary abundance index."),
  list(component = "index", fleet = "BT1", setting = "observation_error_cv_range",
       value = "0.09-0.16", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "The report gives a range only; no year-specific CVs are assigned. Table A3 confidence limits are not converted because that calculation does not reproduce this reported range."),
  list(component = "index", fleet = "BT2", setting = "observation_error_cv_range",
       value = "0.14-0.20", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "The report gives a range only; no year-specific CVs are assigned. Table A4 confidence limits are not converted because that calculation does not reproduce this reported range."),
  list(component = "index", fleet = "BT1", setting = "process_error_cv",
       value = "0.3", source_reference = "FAR 2024/48, Table 5, p. 51", notes = ""),
  list(component = "index", fleet = "BT2", setting = "process_error_cv",
       value = "0.2", source_reference = "FAR 2024/48, Table 5, p. 51", notes = ""),
  list(component = "index", survey = survey_name, setting = "process_error_cv",
       value = "0.2", source_reference = "FAR 2024/48, Table 5, p. 51", notes = ""),
  list(component = "index", survey = survey_name, setting = "survey_timing",
       value = "The survey takes place in March-April; model fractional timing is unknown.",
       source_reference = "FAR 2024/06, executive summary; FAR 2024/48, Table 5",
       notes = "The official assessment report does not document the numeric within-year timing."),
  list(component = "index", survey = "1986-1987 Petersen tag-release biomass estimate",
       setting = "observation_error_cv", value = "0.30",
       source_reference = "FAR 2024/48, section 6.3, p. 41",
       notes = "The report notes concerns about precision and possible low bias."),
  list(component = "catch", fleet = "BPT", setting = "age_composition_ess",
       value = "17", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "Applies to each of the four fitted BPT age-composition years."),
  list(component = "catch", fleet = "BT1", setting = "age_composition_ess",
       value = "10-25", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "The report gives a range, not year-specific ESS values."),
  list(component = "catch", fleet = "BT2", setting = "age_composition_ess",
       value = "6-12", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "The report gives a range, not year-specific ESS values."),
  list(component = "index", survey = survey_name, setting = "age_composition_ess",
       value = "2016=50; 2018=50; 2020=10; 2022=50",
       source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "ESS values are supplied in Table 5."),
  list(component = "index", survey = "Kaharoa trawl survey, core plus 10-20 m TBGB",
       setting = "age_composition_ess",
       value = "2018=50; 2020=10; 2022=50",
       source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "ESS values are supplied in Table 5."),
  list(component = "index", survey = survey_name, setting = "length_composition_ess",
       value = "10", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "Applies to the 2008, 2010, 2012 and 2014 core survey length compositions."),
  list(component = "catch", fleet = "Recreational", setting = "length_composition_ess",
       value = "1", source_reference = "FAR 2024/48, Table 5, p. 51",
       notes = "Applies to each of the nine recreational length-composition years.")
)
assumption_rows <- lapply(assumption_rows, function(row) {
  c(list(assessment_id = assessment_id), row)
})

output_rows <- list(
  list(type = "biomass", measure = "spawning_biomass", value = 13816,
       lwr = 9810, upr = 18530, unit = "tonnes",
       notes = "2023-24 estimate; median and 95% MCMC interval."),
  list(type = "mortality", measure = "target_fishing_mortality", value = 0.051,
       unit = "per year", notes = "FSB40% target."),
  list(type = "mortality", measure = "fishing_mortality_ratio_to_target",
       value = 0.376, lwr = 0.278, upr = 0.532, unit = "ratio",
       notes = "F2023/FSB40%; median and 95% MCMC interval."),
  list(type = "probability", measure = "probability_below_target_fishing_mortality",
       value = 1, unit = "probability",
       notes = "Pr(F2023 < FSB40%)."),
  list(type = "biomass", measure = "yield_at_target_fishing_mortality",
       value = 1872, lwr = 1313, upr = 2537, unit = "tonnes",
       notes = "Yield at FSB40%; 95% MCMC interval."),
  list(type = "biomass", measure = "vulnerable_biomass", value = 32963,
       unit = "tonnes", notes = "MPD estimate.")
)

output_rows <- lapply(output_rows, function(row) {
  c(list(
    assessment_id = assessment_id, fleet = "", survey = "", sex = "combined",
    region = "SNA 7", season = "", year = 2023, age = "", age_group = "",
    se = "", source_type = "official_table",
    source_reference = "FAR 2024/48, Table 7, p. 73",
    scenario = "Base_RecCatch"
  ), row)
})

database_path <- function(name) file.path("database", name)

columns_for <- function(path) {
  names(read.csv(path, nrows = 0, stringsAsFactors = FALSE, check.names = FALSE))
}

rows_as_table <- function(rows, path) {
  columns <- columns_for(path)
  values <- matrix("", nrow = length(rows), ncol = length(columns),
                   dimnames = list(NULL, columns))
  for (i in seq_along(rows)) {
    for (column in intersect(names(rows[[i]]), columns)) {
      value <- rows[[i]][[column]]
      if (length(value) == 1L && !is.na(value)) {
        values[i, column] <- as.character(value)
      }
    }
  }
  as.data.frame(values, stringsAsFactors = FALSE, check.names = FALSE)
}

csv_has_record <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection))
  readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  repeat {
    lines <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}

append_table <- function(rows, filename) {
  path <- database_path(filename)
  table <- rows_as_table(rows, path)
  write.table(
    table, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = ""
  )
}

stock_rows <- list(list(
  stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "SNA 7", scientific_name = "Chrysophrys auratus",
  common_name = "Snapper", area = "SNA 7",
  region = "Tasman Bay/Golden Bay and west coast South Island",
  ocean = "Southwest Pacific",
  notes = "The 2024 assessment treats SNA 7 as the stock unit. Marlborough Sounds catches are included although the report describes that area as biologically distinct."
))

assessment_rows <- list(list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2024,
  terminal_year = 2023, estimate_terminal_year = 2023,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.22", is_current = TRUE, is_applied = TRUE,
  framework_year = "", assessment_url =
    "https://fs.fish.govt.nz/Doc/25776/FAR-2024-48-A-stock-assessment-of-snapper-in-SNA7-2024.pdf.ashx",
  framework_url = "",
  data_url = "https://fs.fish.govt.nz/Doc/25876/FAR-2025-22-Catch-at-age-of-snapper-in-SNA-7-in-the-2022-23-and-2023-24-fishing-years.pdf.ashx",
  model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "Latest detailed official production assessment verified against the 2025 Fisheries Assessment Plenary; the next full SNA 7 assessment is scheduled for 2027. The report tables provide catch, CPUE, age/length compositions and selected current-year outputs. Exact year-specific BT1/BT2 age-composition ESS and numeric within-year survey timing are not reported; age-specific population-output arrays and a native fitted object were not located. The separate 2025/22 catch-at-age study is not mixed into the 2024 model inputs."
))

candidate_rows <- list(list(
  candidate_id = "MPI:SNA7", candidate_unit_id = "mpi_snapper_sna7",
  organization = "Fisheries New Zealand", official_stock_id = "SNA 7",
  scientific_name = "Chrysophrys auratus", stock_name = "Snapper",
  assessment_area = "Tasman Bay, Golden Bay and west coast South Island",
  inventory_assessment_year = 2024,
  inventory_url = "https://fs.fish.govt.nz/Page.aspx?dk=26112&pk=113",
  retrieved_on = "2026-11-05", matched_stock_id = "",
  match_status = "new", screening_status = "screened",
  eligibility = "eligible", import_status = "partial",
  catch_age_evidence = "The 2024 model uses fleet catch biomass and published age-composition vectors for BPT, BT1 and BT2; catch-at-age can be reconstructed only with documented weights-at-age.",
  survey_age_evidence = "Core and core-plus-shallow trawl-survey age compositions are tabulated for model years 2016-2022; core survey biomass indices are also available.",
  weights_evidence = "Fixed time-varying von Bertalanffy growth and a length-weight relation are reported; the fitted age-specific weight surface is not tabulated.",
  maturity_evidence = "A fixed logistic maturity-at-length is reported; no numeric maturity-at-age vector is tabulated.",
  mortality_evidence = "Natural mortality is fixed at 0.075 per year.",
  timing_evidence = "The KAH trawl survey occurs in March-April; an exact fractional timing used by the assessment is unresolved.",
  output_evidence = "The 2024 report tabulates terminal spawning biomass and F-target metrics with MCMC intervals; annual N/F-at-age arrays are not tabulated.",
  detailed_source_url = "https://fs.fish.govt.nz/Doc/25776/FAR-2024-48-A-stock-assessment-of-snapper-in-SNA7-2024.pdf.ashx",
  review_date = "2026-11-05",
  decision_reason = "Eligible for source curation: the accepted age-structured model's catch, age-composition, survey and biology source quantities are available. Import is partial because selected fitted inputs and outputs remain unresolved.",
  notes = "FAR 2025/22 provides newer catch-at-age estimates for 2022/23 and 2023/24, but these are not mixed into the accepted 2024 assessment's likelihood inputs."
))

manifest_rows <- list(
  list(local_file = "source_cache/mpi_snapper_sna7_2024/FAR-2024-48-SNA7-assessment.pdf",
       source_url = "https://fs.fish.govt.nz/Doc/25776/FAR-2024-48-A-stock-assessment-of-snapper-in-SNA7-2024.pdf.ashx",
       retrieved_on = "2026-11-05",
       sha256 = "F8C027B54D89E6059994BAD2E1745FD38E2D479568B6321502739DD6BF8475DE"),
  list(local_file = "source_cache/mpi_snapper_sna7_2024/FAR-2025-22-SNA7-catch-at-age.pdf",
       source_url = "https://fs.fish.govt.nz/Doc/25876/FAR-2025-22-Catch-at-age-of-snapper-in-SNA-7-in-the-2022-23-and-2023-24-fishing-years.pdf.ashx",
       retrieved_on = "2026-11-05",
       sha256 = "2665749D61C1C5F99E90D287D9DC34B9F378CC6325F630F632D050B22E465382"),
  list(local_file = "source_cache/mpi_snapper_sna7_2024/Fisheries-Assessment-Plenary-2025-SNA7.pdf",
       source_url = "https://fs.fish.govt.nz/Doc/26112/snapper-sna-7-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx",
       retrieved_on = "2026-11-05",
       sha256 = "C3FAF58710EA02E84B592F26C16D9DF68BDFDAB1E07190653031C9F771A82BDC")
)

stopifnot(
  identical(sort(unique(catch$year)), 1931:2023),
  nrow(catch) == 93L * 4L,
  nrow(cpue[cpue$fleet == "BT1", ]) == 21L,
  nrow(cpue[cpue$fleet == "BT2", ]) == 34L,
  identical(survey_index_year, c(1991, 1993, 1994, 1996, 1999, 2002, 2004, 2006,
                                 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022)),
  nrow(survey_length) == 4L * 71L,
  nrow(recreational_length) == 9L * 71L,
  all(vapply(tables_age, function(table) {
    all(vapply(seq_along(table$years), function(j) {
      sum(table$values[, j], na.rm = TRUE) > 0.99 &&
        sum(table$values[, j], na.rm = TRUE) < 1.01
    }, logical(1)))
  }, logical(1)))
)

if (any(vapply(manifest_rows, function(row) {
  !file.exists(row$local_file) ||
    unname(tools::md5sum(row$local_file)) == ""
}, logical(1)))) {
  stop("A cached source listed in the manifest is missing.")
}

cat(
  "Prepared", length(input_rows), "source input rows,",
  length(assumption_rows), "assumptions and", length(output_rows),
  "output rows for", assessment_id, ".\n"
)
cat("Input rows by family:\n")
print(table(vapply(input_rows, function(row) row$type, character(1))))

if ("--apply" %in% commandArgs(trailingOnly = TRUE)) {
  files <- c("stocks.csv", "assessments.csv", "assumptions.csv",
             "inputs.csv", "outputs.csv")
  if (any(vapply(files, function(name) csv_has_record(database_path(name), assessment_id),
                 logical(1)))) {
    stop("Assessment rows already exist; refusing to append duplicates.")
  }
  if (csv_has_record(database_path("stocks.csv"), stock_id) ||
      csv_has_record(file.path("discovery", "candidates.csv"), "MPI:SNA7")) {
    stop("The stock or candidate already exists; inspect before importing.")
  }

  append_table(stock_rows, "stocks.csv")
  append_table(assessment_rows, "assessments.csv")
  append_table(assumption_rows, "assumptions.csv")
  append_table(input_rows, "inputs.csv")
  append_table(output_rows, "outputs.csv")
  append_table(candidate_rows, file.path("..", "discovery", "candidates.csv"))
  manifest_path <- file.path("provenance", "mpi_snapper_sna7_2024_sources.csv")
  new_manifest <- do.call(rbind, lapply(manifest_rows, as.data.frame))
  if (file.exists(manifest_path)) {
    old_manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
    new_manifest <- unique(rbind(old_manifest, new_manifest))
  }
  write.csv(new_manifest, manifest_path, row.names = FALSE, na = "")
}
