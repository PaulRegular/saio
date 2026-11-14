root <- "."
assessment_id <- "ices_bay_biscay_anchovy_2025"
stock_id <- "ices_bay_biscay_anchovy_8"

read_assessment <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', id, '"')
  selected <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE, encoding = "bytes")
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, prefix)])
  }
  utils::read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

stocks <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_assessment(file.path(root, "database/inputs.csv"), assessment_id)
outputs <- read_assessment(file.path(root, "database/outputs.csv"), assessment_id)
candidate_register <- read.csv(file.path(root, "discovery/candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
selected <- read.csv(file.path(root, "discovery/selected_batch_19_2026.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
source_review <- paste(readLines(file.path(root,
  "discovery/source_reviews/ices_bay_biscay_anchovy_2025.md")), collapse = "\n")

catch_age <- inputs[inputs$type %in% "catch" & inputs$measure %in% "numbers_at_age", , drop = FALSE]
catch_weight <- inputs[inputs$type %in% "catch_weight" & inputs$measure %in% "catch_weight_at_age", , drop = FALSE]
bioman_n <- inputs[inputs$survey %in% "BIOMAN" & inputs$measure %in% "numbers_at_age" & inputs$year %in% 2025L, , drop = FALSE]
bioman_n_cv <- inputs[inputs$survey %in% "BIOMAN" & inputs$measure %in% "numbers_at_age_cv" & inputs$year %in% 2025L, , drop = FALSE]
juvena <- inputs[inputs$survey %in% "JUVENA" & inputs$measure %in% "recruitment_index", , drop = FALSE]
fixed_m <- inputs[inputs$type %in% "M" & inputs$measure %in% "natural_mortality_at_age", , drop = FALSE]
ssb <- outputs[outputs$measure %in% "SSB", , drop = FALSE]
recruitment <- outputs[outputs$measure %in% "recruitment", , drop = FALSE]
f_apical <- outputs[outputs$measure %in% "F_apical", , drop = FALSE]
n_age <- outputs[outputs$measure %in% "numbers_at_age", , drop = FALSE]
total_n <- outputs[outputs$measure %in% "total_numbers", , drop = FALSE]
parameters <- outputs[outputs$type %in% "parameter", , drop = FALSE]
r0 <- parameters[parameters$measure %in% "ss_parameter_sr_ln_r0", , drop = FALSE]
pelgas_q <- parameters[parameters$measure %in% "ss_parameter_lnq_base_pelgas_survey_3", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "ane.27.8",
  stock$ocean == "Northeast Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025L,
  assessment$model_version == "3.30.22.beta",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 1000L,
  nrow(outputs) == 625L,
  identical(sort(unique(as.integer(catch_age$year))), 1987:2024),
  setequal(unique(as.integer(catch_age$age)), 0:5),
  catch_age$value[catch_age$year == 1987 & catch_age$age == 1 & catch_age$season == "semester_1"] == 218670,
  catch_age$value[catch_age$year == 1987 & catch_age$age == 1 & catch_age$season == "semester_2"] == 120098,
  identical(sort(unique(as.integer(catch_weight$year))), setdiff(1987:2024, 2007:2009)),
  all(!catch_weight$year %in% 2007:2009),
  nrow(bioman_n) == 3L,
  identical(as.numeric(bioman_n$value[order(as.integer(bioman_n$age))]), c(4951, 3430, 266)),
  all(bioman_n$unit == "million fish"),
  identical(as.numeric(bioman_n_cv$value[order(as.integer(bioman_n_cv$age))]), c(0.2133, 0.1172, 0.1798)),
  sum(as.numeric(bioman_n$value)) == 8647,
  nrow(juvena) == 23L,
  juvena$value[juvena$year == 2025] == 386953330,
  grepl("table unit not stated", juvena$unit[juvena$year == 2025], fixed = TRUE),
  identical(as.numeric(fixed_m$value[order(as.integer(fixed_m$age))]), c(2.17, 0.80, 1.20, 2.26)),
  nrow(ssb) == 39L,
  nrow(recruitment) == 39L,
  nrow(f_apical) == 37L,
  !any(f_apical$year %in% 2008:2009),
  ssb$value[ssb$year == 2025] == 119768,
  ssb$lwr[ssb$year == 2025] == 58798,
  ssb$upr[ssb$year == 2025] == 180738,
  recruitment$value[recruitment$year == 2025] == 31134900,
  f_apical$value[f_apical$year == 2025] == 0.27,
  nrow(n_age) == 152L,
  nrow(total_n) == 38L,
  total_n$value[total_n$year == 1987] == 2190937,
  nrow(parameters) == 16L,
  nrow(r0) == 1L,
  r0$value == 16.84,
  r0$se == 0.11,
  nrow(pelgas_q) == 1L,
  pelgas_q$value == 0.53,
  pelgas_q$se == 0.16,
  pelgas_q$unit == "natural-log q",
  all(outputs$source_type[outputs$measure != "total_numbers"] == "official_table"),
  all(total_n$source_type == "derived_source_output"),
  !any(outputs$measure == "natural_mortality_at_age"),
  candidate_register$import_status[candidate_register$candidate_id == "ICES:ane.27.8"] == "partial",
  selected$curation_status[selected$candidate_id == "ICES:ane.27.8"] == "partial_source_import",
  grepl("2007-2009", source_review, fixed = TRUE),
  grepl("unit mapping remains unresolved", source_review, fixed = TRUE),
  grepl("Total abundance is derived", source_review, fixed = TRUE)
)

cat("ICES Bay of Biscay anchovy source import checks passed.\n")
