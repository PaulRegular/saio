read_table <- function(name) read.csv(file.path("database", name),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
read_assessment_rows <- function(name, id) {
  source_con <- file(file.path("database", name), open = "r")
  on.exit(close(source_con))
  header <- readLines(source_con, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  rows <- character()
  repeat {
    chunk <- readLines(source_con, n = 25000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  text <- paste(c(header, rows), collapse = "\n")
  text_con <- textConnection(text)
  on.exit(close(text_con), add = TRUE)
  read.csv(text_con, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessment_id <- "mpi_ling_lin34_2025"
stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
assumptions <- read_assessment_rows("assumptions.csv", assessment_id)
inputs <- read_assessment_rows("inputs.csv", assessment_id)
outputs <- read_assessment_rows("outputs.csv", assessment_id)
candidates <- read.csv(file.path("discovery", "candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock <- stocks[stocks$stock_id == "mpi_ling_lin34", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "MPI:LIN34", , drop = FALSE]
stopifnot(nrow(stock) == 1L, stock$authority_stock_id == "LIN 3&4",
  stock$scientific_name == "Genypterus blacodes", stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L, assessment$assessment_year == 2025L,
  assessment$terminal_year == 2024L, assessment$estimate_terminal_year == 2030L,
  assessment$assumptions_status == "complete", assessment$inputs_status == "complete",
  assessment$outputs_status == "partial", candidate$matched_stock_id == stock$stock_id,
  candidate$import_status == "partial")

catch <- inputs[inputs$type == "catch" & inputs$measure == "total_biomass", ]
composition <- inputs[inputs$measure == "proportion_at_age", ]
survey <- inputs[inputs$type == "index" & inputs$measure == "total_biomass", ]
survey_cv <- inputs[inputs$measure == "biomass_index_cv", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
stopifnot(nrow(catch) == 162L, length(unique(catch$fleet)) == 3L,
  setequal(unique(catch$fleet), c("Commercial trawl", "Commercial longline", "Commercial pot")),
  identical(sort(unique(as.integer(catch$year))), 1972:2025),
  all(catch$unit == "tonnes"),
  all(grepl("2025 entry is the average of 2022–2024", catch$notes, fixed = TRUE)),
  nrow(composition) == 2296L, length(unique(composition$observation_id)) == 76L,
  identical(sort(unique(as.integer(composition$age))), 3:25),
  all(composition$basis == "proportion_numbers"), all(composition$unit == "proportion"),
  all(as.numeric(composition$sample_size) > 0),
  all(grepl("not catch numbers-at-age", composition$notes, fixed = TRUE)),
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"))
composition_sums <- tapply(as.numeric(composition$value), composition$observation_id, sum)
composition_sizes <- tapply(as.numeric(composition$sample_size), composition$observation_id,
  function(x) length(unique(x)))
stopifnot(length(composition_sums) == 76L, max(abs(composition_sums - 1)) <= 0.001,
  all(composition_sizes == 1L))

stopifnot(nrow(survey) == 28L, nrow(survey_cv) == 28L,
  setequal(survey$year, survey_cv$year), all(survey$unit == "tonnes"),
  all(survey_cv$basis == "relative_scale"), all(survey_cv$unit == "ratio"),
  all(as.numeric(survey$sampling_time) == 0.2),
  all(as.numeric(survey_cv$value) > 0))
stopifnot(nrow(maturity) == 26L,
  identical(sort(unique(as.integer(maturity$age))), 3:15),
  identical(sort(unique(maturity$sex)), c("F", "M")),
  all(as.numeric(maturity$value) >= 0 & as.numeric(maturity$value) <= 1),
  all(grepl("Horn (2005)", maturity$notes, fixed = TRUE)))

timing <- assumptions[assumptions$setting == "commercial_age_observation_timing_review", ]
mavg <- outputs[outputs$measure == "natural_mortality_average_parameter", ]
mdiff <- outputs[outputs$measure == "natural_mortality_sex_difference_parameter", ]
b0 <- outputs[outputs$measure == "unfished_spawning_biomass", ]
ssb <- outputs[outputs$measure == "SSB" & outputs$year == 2025, ]
projection <- outputs[outputs$measure == "SSB" & !is.na(outputs$year) & outputs$year == 2030, ]
scenario_outputs <- outputs[!is.na(outputs$year) & outputs$year == 2030, ]
assumption_key_fields <- c("assessment_id", "component", "fleet", "survey", "sex", "region", "season", "setting")
assumption_key <- do.call(paste, c(lapply(assumptions[assumption_key_fields], function(x) {
  x[is.na(x)] <- ""
  as.character(x)
}), sep = "\r"))
stopifnot(nrow(assumptions) == 225L, !anyDuplicated(assumption_key), nrow(timing) == 1L,
  grepl("S1", timing$value, fixed = TRUE), grepl("step 2", timing$value, fixed = TRUE),
  nrow(outputs) == 27L, nrow(mavg) == 1L, as.numeric(mavg$value) == 0.150,
  nrow(mdiff) == 1L, as.numeric(mdiff$value) == -0.007,
  nrow(b0) == 1L, as.numeric(b0$value) == 114384,
  nrow(ssb) == 1L, as.numeric(ssb$value) == 66638,
  nrow(projection) == 4L, all(is.na(projection$se)),
  nrow(scenario_outputs) == 20L, length(unique(scenario_outputs$scenario)) == 4L,
  all(!is.na(scenario_outputs$scenario) & nzchar(scenario_outputs$scenario)))

cat("LIN 3&4 2025 source inputs, assumptions, outputs, units, and coverage passed.\n")
