read_assessment_rows <- function(path, assessment_id) {
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to scan the large canonical database.", call. = FALSE)
  prefix <- paste0('"', assessment_id, '",')
  rows <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character()
  else if (status != 0L) stop("Could not scan ", path, call. = FALSE)
  rows <- rows[startsWith(rows, prefix)]
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessment_id <- "noaa_northern_rockfish_goa_2024"
stock_id <- "noaa_northern_rockfish_goa"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stock <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stock <- stock[stock$stock_id == stock_id, ]
assessment <- assessment[assessment$assessment_id == assessment_id, ]
candidate <- candidate[candidate$candidate_id == "NOAA:10417", ]

catch <- inputs[inputs$measure == "catch_biomass", ]
fish_age <- inputs[inputs$type == "catch" & inputs$measure == "proportion_at_age", ]
survey_age <- inputs[inputs$type == "index" & inputs$measure == "proportion_at_age", ]
fish_length <- inputs[inputs$measure == "proportion_at_length", ]
survey_biomass <- inputs[inputs$type == "index" & inputs$measure == "total_biomass", ]
survey_sd <- inputs[inputs$type == "index" & inputs$measure == "index_sd", ]
survey_weight <- inputs[inputs$type == "index" & inputs$measure == "relative_precision_weight", ]
weight <- inputs[inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA", stock$authority_stock_id == "10417",
  stock$scientific_name == "Sebastes polyspinis",
  stock$area == "Western / Central Gulf of Alaska",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L, assessment$terminal_year == 2024L,
  assessment$model_version == "m24 preferred model",
  all(assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  nrow(inputs) == 2196L, nrow(outputs) == 304L, nrow(assumptions) == 26L
)

stopifnot(
  nrow(catch) == 64L, identical(sort(catch$year), 1961:2024),
  catch$value[catch$year == 2024L] == 1129,
  nrow(fish_age) == 704L, nrow(survey_age) == 704L,
  nrow(fish_length) == 527L,
  identical(sort(unique(fish_age$age)), 2:45),
  identical(sort(unique(survey_age$age)), 2:45),
  identical(sort(unique(fish_length$length_bin)), 15:45),
  nrow(survey_biomass) == 16L, nrow(survey_sd) == 16L,
  nrow(survey_weight) == 16L,
  setequal(survey_biomass$year, survey_sd$year),
  setequal(survey_biomass$observation_id, survey_sd$observation_id),
  all(survey_sd$value > 0), all(survey_weight$value == 0.25),
  !any(inputs$survey == "GOA bottom-trawl survey" &
    inputs$measure == "design_based_biomass"),
  nrow(weight) == 50L, nrow(maturity) == 50L,
  identical(sort(weight$age), 2:51), identical(sort(maturity$age), 2:51),
  all(maturity$value >= 0 & maturity$value <= 1),
  !any(inputs$measure == "catch_likelihood_weight"),
  any(assumptions$setting == "likelihood_weight" &
    grepl("5 for 1961-1977; 50 for 1978-2024", assumptions$value, fixed = TRUE))
)

sum_by_year <- function(x) tapply(x$value, x$year, sum)
stopifnot(
  all(abs(sum_by_year(fish_age) - 1) <= 0.006),
  all(abs(sum_by_year(survey_age) - 1) <= 0.006),
  all(abs(sum_by_year(fish_length) - 1) <= 0.006)
)

recruitment <- outputs[outputs$measure == "recruitment", ]
biomass <- outputs[outputs$measure == "total_biomass", ]
ssb <- outputs[outputs$measure == "SSB", ]
n_at_age <- outputs[outputs$measure == "numbers_at_age", ]
total_n <- outputs[outputs$measure == "total_abundance", ]
selectivity <- outputs[outputs$measure == "fleet_selectivity_at_age", ]
parameters <- outputs[outputs$measure %in% c(
  "F40_percent", "natural_mortality_average_parameter", "q"), ]
parameter_means <- parameters[parameters$scenario == "MCMC mean", ]

expected_n <- read.csv(
  "provenance/noaa_northern_rockfish_goa_2024/transcriptions/terminal_biology_and_population.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
expected_ts <- read.csv(
  "provenance/noaa_northern_rockfish_goa_2024/transcriptions/time_series.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

stopifnot(
  nrow(recruitment) == 48L, nrow(biomass) == 48L, nrow(ssb) == 48L,
  identical(sort(recruitment$year), 1977:2024),
  identical(sort(biomass$year), 1977:2024),
  identical(sort(ssb$year), 1977:2024),
  ssb$value[ssb$year == 2024L] == expected_ts$ssb_mean_t[expected_ts$year == 2024L],
  nrow(n_at_age) == 50L, identical(sort(n_at_age$age), 2:51),
  n_at_age$year == 2024L,
  abs(sum(n_at_age$value) - total_n$value) < 1e-8,
  total_n$age_group == "2-51", nrow(total_n) == 1L,
  nrow(selectivity) == 100L,
  nrow(parameters) == 9L,
  all(is.na(parameter_means$se)),
  all(grepl("not stored as a standard error", parameter_means$notes, fixed = TRUE)),
  max(abs(n_at_age$value - expected_n$abundance_thousand)) < 1e-8,
  all(!is.na(ssb$lwr) & !is.na(ssb$upr)),
  all(ssb$lwr <= ssb$value & ssb$value <= ssb$upr)
)

manifest <- read.csv(
  "provenance/noaa_northern_rockfish_goa_2024/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines(
  "discovery/source_reviews/noaa_northern_rockfish_goa.md", warn = FALSE),
  collapse = "\n")
stopifnot(
  any(grepl("dcf94241c58ad5ccd0056bc7c50c4db338ba61d8", manifest$repository_revision, fixed = TRUE)),
  grepl("caption says", review, fixed = TRUE),
  grepl("fractional within-year survey timing", review, fixed = TRUE),
  grepl("age-error and length-age matrices are not present", review, fixed = TRUE),
  grepl("draft", review, fixed = TRUE)
)
