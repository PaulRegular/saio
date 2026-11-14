stock_id <- "noaa_goa_rex_sole"
assessment_id <- paste0(stock_id, "_2026")

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
      found[[length(found) + 1L]] <- read.csv(text = paste(matching, collapse = "
"),
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
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- read.csv("discovery/selected_unworked_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
catch <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", , drop = FALSE]
survey <- inputs[inputs$type == "index" & inputs$measure == "total_biomass", , drop = FALSE]
log_se <- inputs[inputs$type == "index" & inputs$measure == "log_index_sd", , drop = FALSE]
recruitment <- outputs[outputs$measure == "recruitment", , drop = FALSE]
recruitment_sd <- outputs[outputs$measure == "recruitment_standard_deviation", , drop = FALSE]
biomass <- outputs[outputs$measure %in% c("total_biomass", "SSB",
  "SSB_standard_deviation"), , drop = FALSE]
numbers <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
rex_candidates <- candidates[!is.na(candidates$candidate_unit_id) &
  candidates$candidate_unit_id == stock_id, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA-AFSC",
  stock$authority_stock_id == "10058",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_type == "full_assessment",
  assessment$model_version == "3.3.25.1; Model 25.1",
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 22L,
  assumptions$value[assumptions$setting == "natural_mortality"] ==
    "0.17 per year, fixed for both sexes",
  any(assumptions$setting == "female_maturity_relationship"),
  any(assumptions$setting == "weight_at_age_relationship"),
  nrow(catch) == 45L,
  identical(sort(as.integer(catch$year)), 1982:2026),
  catch$value[catch$year == "2026"] == "1071",
  all(catch$unit == "t"),
  nrow(survey) == 34L,
  nrow(log_se) == 33L,
  identical(sort(unique(as.integer(survey$year))), c(1990L, 1993L, 1996L,
    1999L, seq.int(2001L, 2025L, by = 2L))),
  is.na(survey$value[survey$year == "2001" & survey$region == "Eastern GOA"]),
  survey$value[survey$year == "2025" & survey$region == "Western-Central GOA"] == "78988",
  survey$value[survey$year == "2025" & survey$region == "Eastern GOA"] == "33836",
  all(survey$unit[!is.na(survey$value)] == "t"),
  all(survey$sampling_time == "0.5"),
  all(survey$season == "July"),
  all(log_se$unit == "log scale"),
  !any(log_se$year == "2001" & log_se$region == "Eastern GOA"),
  nrow(recruitment) == 90L,
  nrow(recruitment[recruitment$age == "0", ]) == 45L,
  nrow(recruitment[recruitment$age == "3", ]) == 45L,
  recruitment$value[recruitment$year == "2026" & recruitment$age == "0"] == "87736",
  recruitment$value[recruitment$year == "2026" & recruitment$age == "3"] == "52685",
  recruitment$value[recruitment$year == "2014" & recruitment$age == "0"] == "74440",
  recruitment$value[recruitment$year == "2014" & recruitment$age == "3"] == "36739",

  all(recruitment$unit == "source table units (scale not stated)"),
  nrow(recruitment_sd) == 44L,
  recruitment_sd$value[recruitment_sd$year == "2025"] == "7001",
  !any(recruitment_sd$year == "2026"),
  nrow(biomass) == 135L,
  biomass$value[biomass$measure == "total_biomass" & biomass$year == "2026"] == "100667",
  biomass$value[biomass$measure == "SSB" & biomass$year == "2026"] == "50879",
  biomass$value[biomass$measure == "SSB_standard_deviation" & biomass$year == "2026"] == "5086",
  all(is.na(biomass$se) & is.na(biomass$lwr) & is.na(biomass$upr)),
  nrow(numbers) == 3780L,
  setequal(unique(as.integer(numbers$age)), 0:20),
  setequal(unique(numbers$region), c("Eastern GOA", "Western-Central GOA")),
  setequal(unique(numbers$sex), c("female", "male")),
  numbers$value[numbers$year == "1982" & numbers$age == "0" &
    numbers$region == "Western-Central GOA" & numbers$sex == "female"] == "33242",
  numbers$value[numbers$year == "2026" & numbers$age == "20" &
    numbers$region == "Eastern GOA" & numbers$sex == "male"] == "3197",
  all(numbers$unit == "source table units (scale not stated)"),
  all(!is.na(catch$source_reference) & nzchar(catch$source_reference)),
  all(!is.na(outputs$source_reference) & nzchar(outputs$source_reference)),
  nrow(outputs) == 4049L,
  all(is.finite(as.numeric(outputs$value))),
  !any(inputs$measure == "proportion_at_age"),
  nrow(rex_candidates) == 3L,
  all(rex_candidates$matched_stock_id == stock_id),
  all(rex_candidates$match_status == "matched"),
  all(rex_candidates$import_status == "partial"),
  selected$curation_status[selected$candidate_id == "NOAA:10058"] ==
    "source_curated_partial",
  file.exists("discovery/source_reviews/noaa_goa_rex_sole_2026.md")
)

cat("NOAA GOA rex sole 2026 source records passed.
")