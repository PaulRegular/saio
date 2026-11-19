stock_id <- "noaa_butterfish_gom_cape_hatteras"
assessment_id <- paste0(stock_id, "_2024")

read_assessment_rows <- function(path, id) {
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  connection <- file(path, open = "r")
  on.exit(close(connection))
  readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  found <- list()
  repeat {
    lines <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(lines)) break
    matching <- lines[startsWith(lines, prefix)]
    if (length(matching)) {
      found[[length(found) + 1L]] <- read.csv(text = paste(matching, collapse = "\n"),
        header = FALSE, col.names = header, stringsAsFactors = FALSE,
        colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
    }
  }
  if (!length(found)) return(data.frame())
  do.call(rbind, found)
}

blank <- function(x) is.na(x) | !nzchar(x)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)

catch_total <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass" &
  inputs$fleet == "Butterfish fishery" & blank(inputs$partition), , drop = FALSE]
catch_cv <- inputs[inputs$measure == "catch_cv", , drop = FALSE]
catch_weight <- inputs[inputs$measure == "catch_weight_at_age", , drop = FALSE]
catch_composition <- inputs[inputs$type == "catch" &
  inputs$measure == "proportion_at_age", , drop = FALSE]
survey_total <- inputs[inputs$type == "index" & inputs$measure == "total_numbers", , drop = FALSE]
survey_cv <- inputs[inputs$type == "index" & inputs$measure == "abundance_index_cv", , drop = FALSE]
survey_age <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", , drop = FALSE]

sum_by_observation <- tapply(as.numeric(catch_composition$value),
  catch_composition$observation_id, sum)
output_key <- paste(outputs$type, outputs$measure, outputs$year, sep = "|")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA-NEFSC",
  stock$authority_stock_id == "10187",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024,
  assessment$terminal_year == 2023,
  assessment$model_family == "WHAM",
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 21L,
  assumptions$value[assumptions$setting == "natural_mortality"] ==
    "1.278 per year, carried forward from the 2020 ASAP4 management-track model.",
  assumptions$value[assumptions$setting == "fall_Albatross_q"] == "0.2",
  nrow(catch_total) == 59L,
  min(as.integer(catch_total$year)) == 1965L,
  max(as.integer(catch_total$year)) == 2023L,
  catch_total$value[catch_total$year == "1991"] == "4496",
  catch_total$value[catch_total$year == "2023"] == "4110",
  nrow(catch_cv) == 70L,
  nrow(catch_weight) == 175L,
  catch_weight$value[catch_weight$year == "1996" & catch_weight$age == "4"] == "0.17",
  nrow(catch_composition) == 175L,
  all(catch_composition$basis == "proportion_biomass"),
  all(is.na(catch_composition$sample_size)),
  all(grepl("sample_size is left blank", catch_composition$notes, fixed = TRUE)),
  length(sum_by_observation) == 35L,
  max(abs(sum_by_observation - 1)) <= 0.010001,
  nrow(survey_total) == 82L,
  nrow(survey_cv) == 77L,
  nrow(survey_age) == 410L,
  all(survey_age$unit == "number per tow"),
  all(survey_age$age %in% as.character(0:4)),
  nrow(survey_total[survey_total$survey == "NEFSC fall Bigelow" &
    survey_total$year == "2017" & is.na(survey_total$value), ]) == 1L,
  nrow(survey_total[survey_total$survey == "NEFSC spring Bigelow" &
    survey_total$year == "2020" & is.na(survey_total$value), ]) == 1L,
  !any(survey_total$survey == "NEFSC spring Bigelow" & survey_total$year == "2023"),
  !any(survey_total$survey == "NEAMAP spring" & survey_total$year == "2007"),
  nrow(outputs) == 105L,
  all(table(output_key) == 1L),
  nrow(outputs[outputs$measure == "SSB", ]) == 35L,
  nrow(outputs[outputs$measure == "fishing_mortality_at_age" & outputs$age == "3", ]) == 35L,
  nrow(outputs[outputs$measure == "recruitment" & outputs$age == "0", ]) == 35L,
  outputs$value[outputs$measure == "SSB" & outputs$year == "2023"] == "83004",
  outputs$value[outputs$measure == "fishing_mortality_at_age" & outputs$year == "2023"] == "0.143",
  outputs$value[outputs$measure == "recruitment" & outputs$year == "2023"] == "6636",
  all(is.na(outputs$se)),
  all(grepl("Source-reported CV =", outputs$notes, fixed = TRUE)),
  all(!is.na(inputs$source_reference) & nzchar(inputs$source_reference)),
  all(!is.na(outputs$source_reference) & nzchar(outputs$source_reference))
)

cat("NOAA butterfish 2024 source records passed.\n")
