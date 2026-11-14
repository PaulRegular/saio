root <- "."
stock_id <- "mpi_ling_lin56_lin6b"
assessment_id <- "mpi_ling_lin56_lin6b_2024"
candidate_id <- "MPI:LIN56+LIN6B"
write_data <- "--write" %in% commandArgs(trailingOnly = TRUE)

## Read reviewed sources ----

manifest <- read.csv(file.path(root, "provenance", "mpi_ling_lin56_2024_sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
verified_sources <- c(
  "mpi_ling_lin56_2024/FAR-2024-82-inputs.pdf" =
    "18FB09E7D1E9BBFE54F4AF56AA80DF52731208298A1CEE5E250101B2DCD299F9",
  "mpi_ling_lin56_2024/FAR-2024-83-stock-hypotheses.pdf" =
    "32EB23E40CF054CF51F8091D6ACEF31B3FD718477B0C92B46FE8B605077946AC",
  "mpi_ling_lin56_2024/FAR-2024-84-assessment.pdf" =
    "75717DA9A39D96FA74D61AA13386D8939792DF8AF86E28880C8001E17B4CBC3D",
  "mpi_ling_lin56_2024/Fisheries-Assessment-Plenary-2025-Volume-2.pdf" =
    "5C09739BE5378E339B565F1A8BF54B9673AFD9364BBEAF3D1B8D8A63A92471A5",
  "mpi_ling_lin56_2024/FAR-2024-74-catch-at-age.pdf" =
    "794577DE059EE28A9BBDE2F3B0E2AD5CCDCCD27FE141CC2132B3D76354D23058",
  "mpi_ling_lin56_2024/FAR-2024-85-observer-coverage.pdf" =
    "749387467306E31C1F8A94185006F64A44E6906BA1E364152D62A64783C5D61F"
)
source_rows <- match(names(verified_sources), manifest$local_file)
source_files <- file.path(root, "source_cache", names(verified_sources))
if (nrow(manifest) != length(verified_sources) || anyNA(source_rows) ||
    !all(file.exists(source_files))) {
  stop("Reviewed Sub-Antarctic ling PDFs or provenance entries are missing.", call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, unname(verified_sources)) ||
    !identical(toupper(manifest$sha256[source_rows]), unname(verified_sources))) {
  stop("A cached Sub-Antarctic ling source differs from its verified checksum.", call. = FALSE)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Package pdftools is required to read the reviewed source tables.", call. = FALSE)
}

inputs_pages <- pdftools::pdf_text(source_files[1L])
assessment_pages <- pdftools::pdf_text(source_files[3L])

catch_page <- which(vapply(inputs_pages, function(page) {
  grepl("Table E.1:", page, fixed = TRUE)
}, logical(1L)))
if (length(catch_page) != 1L) stop("Could not uniquely identify FAR 2024/82 Table E.1.", call. = FALSE)
catch_lines <- strsplit(inputs_pages[[catch_page]], "\n", fixed = TRUE)[[1L]]
catch_lines <- trimws(catch_lines[grepl("^\\s*(?:19|20)[0-9]{2}\\s+", catch_lines, perl = TRUE)])
catch_fields <- lapply(catch_lines, function(line) {
  strsplit(line, "\\s{2,}", perl = TRUE)[[1L]]
})
if (length(catch_fields) != 52L || any(lengths(catch_fields) != 4L)) {
  stop("FAR 2024/82 Table E.1 did not parse as 52 years and three fisheries.", call. = FALSE)
}
catch_table <- do.call(rbind, lapply(catch_fields, function(fields) {
  as.numeric(gsub("\\s+", "", fields, perl = TRUE))
}))
colnames(catch_table) <- c("year", "lin56_trawl", "lin56_longline", "lin6b_longline")
if (!identical(as.integer(catch_table[, "year"]), 1972:2023) ||
    anyNA(catch_table) || any(catch_table[, -1L] < 0)) {
  stop("FAR 2024/82 Table E.1 has unexpected years or catch values.", call. = FALSE)
}

maturity_page <- which(vapply(assessment_pages, function(page) {
  grepl("Maturity-at-age used in the Sub-Antarctic ling stock models", page, fixed = TRUE)
}, logical(1L)))
if (length(maturity_page) != 1L) stop("Could not uniquely identify FAR 2024/84 Table 4.", call. = FALSE)
maturity_lines <- strsplit(assessment_pages[[maturity_page]], "\n", fixed = TRUE)[[1L]]
maturity_lines <- grep("^\\s*(Male|Female)\\s+", maturity_lines,
  value = TRUE, perl = TRUE)
maturity_rows <- lapply(maturity_lines, function(line) {
  fields <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
  if (length(fields) != 12L) return(NULL)
  data.frame(sex = tolower(fields[1L]), age = 3:13,
    value = as.numeric(fields[-1L]), stringsAsFactors = FALSE)
})
if (length(maturity_rows) != 2L || any(vapply(maturity_rows, is.null, logical(1L)))) {
  stop("FAR 2024/84 Table 4 did not parse for both sexes at ages 3-13.", call. = FALSE)
}
maturity <- do.call(rbind, maturity_rows)
if (!identical(unique(maturity$sex), c("male", "female")) ||
    anyNA(maturity$value) || any(maturity$value < 0 | maturity$value > 1)) {
  stop("FAR 2024/84 Table 4 has unexpected sex or maturity values.", call. = FALSE)
}

## Build source records ----

input_header <- names(read.csv(file.path(root, "database", "inputs.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assumption_header <- names(read.csv(file.path(root, "database", "assumptions.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
output_header <- names(read.csv(file.path(root, "database", "outputs.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
stock_header <- names(read.csv(file.path(root, "database", "stocks.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assessment_header <- names(read.csv(file.path(root, "database", "assessments.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))

make_records <- function(header, data) {
  out <- as.data.frame(matrix("", nrow = nrow(data), ncol = length(header)),
    stringsAsFactors = FALSE)
  names(out) <- header
  for (name in intersect(names(data), header)) {
    value <- as.character(data[[name]])
    value[is.na(value)] <- ""
    out[[name]] <- value
  }
  out
}

catch_fleets <- c("LIN 5&6 bottom trawl", "LIN 5&6 bottom longline", "LIN 6B bottom longline")
catch_columns <- c("lin56_trawl", "lin56_longline", "lin6b_longline")
catch_data <- do.call(rbind, lapply(seq_len(nrow(catch_table)), function(i) {
  data.frame(
    assessment_id = assessment_id, type = "catch", measure = "catch_biomass",
    basis = "biomass", fleet = catch_fleets, sex = "", region = "Sub-Antarctic",
    year = catch_table[i, "year"], year_basis = "model_year",
    value = as.numeric(catch_table[i, catch_columns]), unit = "tonnes",
    source_type = "official_table",
    source_reference = "FAR 2024/82, Appendix E, Table E.1, printed p. 93.",
    transformation = "Copied from the annual scaled-up catch table without rescaling.",
    notes = paste(
      "Annual model-year catch biomass used in the 2024 assessment, not catch-at-age.",
      "Bottom longline includes potting; bottom trawl includes other catches."
    ), stringsAsFactors = FALSE
  )
}))

M_data <- expand.grid(sex = c("male", "female"), age = 1:28,
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
M_data$assessment_id <- assessment_id
M_data$type <- "M"
M_data$measure <- "natural_mortality_at_age"
M_data$basis <- "per_year"
M_data$region <- "Sub-Antarctic"
M_data$value <- 0.18
M_data$unit <- "per year"
M_data$source_type <- "official_table"
M_data$source_reference <- "FAR 2024/84, Table 3, printed p. 4; Section 2.3, printed p. 4."
M_data$notes <- "Fixed instantaneous natural mortality; 0.18 per year for both sexes, constant at age."

maturity$assessment_id <- assessment_id
maturity$type <- "maturity"
maturity$measure <- "maturity_at_age"
maturity$basis <- "proportion_numbers"
maturity$region <- "Sub-Antarctic"
maturity$unit <- "proportion"
maturity$source_type <- "official_table"
maturity$source_reference <- "FAR 2024/84, Table 4, printed p. 4."
maturity$notes <- "Reported maturity proportions at ages 3-13 only; no values outside the source range are added."

inputs <- rbind(
  make_records(input_header, catch_data),
  make_records(input_header, M_data),
  make_records(input_header, maturity)
)

make_assumption <- function(component, setting, value, source_reference, notes = "",
    fleet = "", survey = "", sex = "", region = "", season = "") {
  make_records(assumption_header, data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  ))
}

assumptions <- do.call(rbind, list(
  make_assumption("model", "assessment_model",
    "Two-sex age-based statistical catch-at-age model implemented in Casal2 v24.02.",
    "FAR 2024/84, Section 2.1, printed p. 3.", "Casal2 version dated 2024-02-21."),
  make_assumption("model", "model_year_and_period",
    "Calendar-year model; model starts in 1970 and the assessment period is 1973-2023.",
    "FAR 2024/84, Sections 2.1 and 3.4, Figures 4 and 9.",
    "The source catch table begins in 1972; no earlier catches are filled."),
  make_assumption("population", "stock_structure",
    "LIN 5&6 and LIN 6B are represented as one biological population; LIN 6B is a separate fishery sharing biological parameters and recruitment.",
    "FAR 2024/84, Section 2.1, printed p. 3.",
    "Statistical Area 032 was moved from LIN 5&6 to LIN 7WC."),
  make_assumption("population", "age_range_and_plus_group",
    "Ages 1-28; age 28 is the plus group.",
    "FAR 2024/84, Section 2.1, printed p. 3."),
  make_assumption("timing", "model_time_steps",
    "Two annual steps: January-August and September-December.",
    "FAR 2024/84, Table 1, printed p. 3.",
    "The table distributes M, recruitment, fishing, age advancement, and observations by step; see observation_timing."),
  make_assumption("timing", "observation_timing",
    "Autumn survey is in step 1; longline CPUE, commercial age compositions, and summer survey are in step 2; observations are positioned at 50% of step Z.",
    "FAR 2024/84, Table 1, printed p. 3.",
    "No single fractional-year sampling time is assigned because the model uses two seasonal steps."),
  make_assumption("catch", "catch_input_definition",
    "Annual scaled-up catch biomass by three fisheries; bottom longline includes potting and bottom trawl includes other catches.",
    "FAR 2024/82, Appendix E, Table E.1, printed p. 93.",
    "Catch is reported in tonnes and is not catch-at-age or a landings/discards split."),
  make_assumption("composition", "survey_age_composition_coverage",
    "Summer survey ages 3-21 (21+); autumn survey ages 3-21 (21+).",
    "FAR 2024/84, Table 2, printed p. 4.",
    "Survey composition years are tabulated in Table 2, but numerical fitted vectors and effective sample sizes were not published in the reviewed run-specific sources."),
  make_assumption("composition", "commercial_age_composition_coverage",
    "LIN 5&6 commercial longline ages 3-28 (28+) and trawl ages 3-28 (28+).",
    "FAR 2024/84, Tables 2 and 4, printed p. 4.",
    "LIN 6B age compositions were excluded. Numerical fitted composition vectors and effective sample sizes were not published in the reviewed sources."),
  make_assumption("index", "survey_index_coverage",
    "Tangaroa summer biomass: 1991-1993, 2000-2009, 2011-2012, 2014, 2018, 2020, 2022; autumn biomass: 1992-1993, 1996, 1998.",
    "FAR 2024/84, Table 2, printed p. 4.",
    "Numerical survey values and CVs were not tabulated in the reviewed run-specific sources."),
  make_assumption("index", "base_case_indices",
    "The base model uses summer and autumn Tangaroa survey biomass indices; bottom-longline CPUE is excluded.",
    "FAR 2024/84, Sections 2.2 and 3.4, printed pp. 4 and 9.",
    "Non-spatial and spatial CPUE series are used in sensitivity runs, not the base case."),
  make_assumption("recruitment", "stock_recruitment_relationship",
    "Beverton-Holt with steepness 0.84.",
    "FAR 2024/84, Table 3, printed p. 4."),
  make_assumption("recruitment", "recruitment_variability",
    "Year-class strengths are recruitment multipliers with a lognormal distribution and sigma-R 0.7; annual multipliers use a simplex constraint with mean one.",
    "FAR 2024/84, Table 3 and Section 2.3, printed pp. 4-5."),
  make_assumption("biology", "ageing_error_cv",
    "Ageing-error CV 0.06.",
    "FAR 2024/84, Table 3, printed p. 4."),
  make_assumption("biology", "proportion_male_at_birth",
    "0.5.", "FAR 2024/84, Table 3, printed p. 4."),
  make_assumption("biology", "proportion_mature_fish_spawning",
    "1.0.", "FAR 2024/84, Table 3, printed p. 4."),
  make_assumption("biology", "male_growth_parameters",
    "Von Bertalanffy t0=-1.16 y, k=0.19 y-1, L-infinity=91.2 cm, CV=0.08.",
    "FAR 2024/84, Table 3, printed p. 4.", "Growth parameters are reported, but no annual weight-at-age matrix is tabulated.", sex = "male"),
  make_assumption("biology", "female_growth_parameters",
    "Von Bertalanffy t0=-1.53 y, k=0.13 y-1, L-infinity=110.6 cm, CV=0.08.",
    "FAR 2024/84, Table 3, printed p. 4.", "Growth parameters are reported, but no annual weight-at-age matrix is tabulated.", sex = "female"),
  make_assumption("biology", "male_length_weight_parameters",
    "Weight = 2.13e-9 * length^3.293; length in cm, weight in grams.",
    "FAR 2024/84, Table 3, printed p. 4.", sex = "male"),
  make_assumption("biology", "female_length_weight_parameters",
    "Weight = 1.32e-9 * length^3.293; length in cm, weight in grams.",
    "FAR 2024/84, Table 3, printed p. 4.", sex = "female"),
  make_assumption("M", "natural_mortality",
    "Fixed instantaneous M=0.18 per year for both sexes, constant at age.",
    "FAR 2024/84, Table 3 and Section 2.3, printed pp. 4-5.",
    "The attempt to estimate M in the 2021 assessment was uncertain and biased; length-based M is a sensitivity only."),
  make_assumption("F", "selectivity",
    "Selectivity is constant over time within fisheries and survey; longline and survey selectivity are logistic; trawl selectivity is double normal with right-hand limb fixed at 100; potting uses longline selectivity.",
    "FAR 2024/84, Section 2.3, printed p. 5.",
    "A logistic trawl-selectivity sensitivity had little effect."),
  make_assumption("q", "catchability_and_process_error",
    "Survey q is estimated as a free parameter with a uniform prior; the base table gives q starting value 0.12 and bounds 0.02-4. Survey process-error prior is uniform-log with bounds 0.001-2. CPUE q and process error occur only in sensitivity runs.",
    "FAR 2024/84, Table 5 and Section 2.3, printed p. 5.",
    "The 2024 survey-q prior was changed from the informative prior used in 2021 because of undue influence."),
  make_assumption("output", "table_11_probability_label",
    "Table 11 heading reports pLIN5 < U40, while its caption says the probability of being over U40; the surrounding text describes probability below U40.",
    "FAR 2024/84, Table 11 and Section 3.5, printed pp. 16-17.",
    "The imported measure follows the table heading and surrounding text; the source wording discrepancy is retained.")
))

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, year = "",
    lwr = "", upr = "", scenario = "", notes = "") {
  output_rows[[length(output_rows) + 1L]] <<- make_records(output_header, data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    year = year, value = value, lwr = lwr, upr = upr, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = scenario, stringsAsFactors = FALSE
  ))
}

table8 <- data.frame(
  run = c("R2.0a", "R3.0", "R7.0", "R7.1", "R7.3"),
  description = c("Non-spatial CPUE only", "Non-spatial and spatial CPUE", "No CPUE",
    "CPUE 1% learning rate", "CPUE 0.5% learning rate"),
  B0 = c(182244, 200908, 205459, 199207, 189985),
  B0_lwr = c(158594, 172508, 171639, 170151, 163654),
  B0_upr = c(219454, 246076, 262863, 246659, 230473),
  status = c(57.6, 67.9, 67.5, 64.1, 60.7),
  status_lwr = c(51.0, 61.3, 58.4, 56.9, 53.9),
  status_upr = c(65.2, 75.3, 77.7, 71.8, 68.4),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(table8))) {
  note <- paste("Table 8 CPUE sensitivity:", table8$description[i],
    "Posterior median and 95% credible interval.")
  add_output("biomass", "unfished_spawning_biomass", table8$B0[i], "tonnes",
    "FAR 2024/84, Table 8, printed p. 7.", lwr = table8$B0_lwr[i],
    upr = table8$B0_upr[i], scenario = paste("Table 8", table8$run[i]), notes = note)
  add_output("biomass", "SSB_ratio_to_B0", table8$status[i], "percent of B0",
    "FAR 2024/84, Table 8, printed p. 7.", year = 2024L,
    lwr = table8$status_lwr[i], upr = table8$status_upr[i],
    scenario = paste("Table 8", table8$run[i]), notes = note)
}

table9 <- data.frame(
  run = c("Base model", "Base + CPUE", "Base - BLL AF", "M=0.16", "M=0.20", "length-based M", "Additional catch"),
  B0 = c(204628, 180575, 212692, 158380, 304797, 205664, 208772),
  B0_lwr = c(171734, 157476, 175995, 142888, 226047, 174120, 175345),
  B0_upr = c(258458, 215386, 275733, 179277, 419980, 262784, 262784),
  status = c(66.3, 54.3, 69.3, 52.1, 76.7, 64.5, 66.3),
  status_lwr = c(55.3, 45.5, 57.6, 42.3, 65.1, 53.9, 55.3),
  status_upr = c(78.3, 64.0, 82.1, 62.3, 88.3, 75.7, 78.4),
  p40 = c(1.000, 0.999, 1.000, 0.993, 1.000, 1.000, 1.000),
  p20 = rep(0, 7L), stringsAsFactors = FALSE
)
for (i in seq_len(nrow(table9))) {
  scenario <- paste("Table 9", table9$run[i])
  note <- "Posterior median and 95% credible intervals; status is B2024 as percent of B0."
  add_output("biomass", "unfished_spawning_biomass", table9$B0[i], "tonnes",
    "FAR 2024/84, Table 9, printed p. 11.", lwr = table9$B0_lwr[i],
    upr = table9$B0_upr[i], scenario = scenario, notes = note)
  add_output("biomass", "SSB_ratio_to_B0", table9$status[i], "percent of B0",
    "FAR 2024/84, Table 9, printed p. 11.", year = 2024L,
    lwr = table9$status_lwr[i], upr = table9$status_upr[i], scenario = scenario, notes = note)
  add_output("probability", "probability_above_40_percent_B0", table9$p40[i], "probability",
    "FAR 2024/84, Table 9, printed p. 11.", year = 2024L,
    scenario = scenario, notes = "Posterior probability that B2024 is above 40% of B0.")
  add_output("probability", "probability_below_20_percent_B0", table9$p20[i], "probability",
    "FAR 2024/84, Table 9, printed p. 11.", year = 2024L,
    scenario = scenario, notes = "Posterior probability that B2024 is below 20% of B0.")
}

table10 <- data.frame(
  recruitment = c("1973-2017", "2008-2017", "1973-2017", "2008-2017", "2008-2017", "2008-2017", "2008-2017"),
  catch = c("2020-23", "2020-23", "TACC", "TACC", "LIN5+10", "LIN5+20", "LIN5+30"),
  B2029 = c(133874, 132208, 119754, 118044, 130530, 128852, 127174),
  B2029_lwr = c(95594, 93368, 81531, 79315, 91691, 90005, 88327),
  B2029_upr = c(194403, 194186, 180217, 179991, 192494, 190803, 189116),
  B2029_B2024 = c(98.4, 97.2, 88.0, 86.8, 95.9, 94.7, 93.4),
  B2029_B2024_lwr = c(91.9, 91.4, 80.5, 79.4, 90.0, 88.7, 87.4),
  B2029_B2024_upr = c(106.4, 104.1, 96.1, 94.5, 102.9, 101.6, 100.5),
  B2029_B0 = c(65.3, 64.5, 58.4, 57.6, 63.6, 62.8, 62.0),
  B2029_B0_lwr = c(54.3, 53.2, 46.5, 45.3, 52.2, 51.3, 50.3),
  B2029_B0_upr = c(77.4, 77.3, 71.4, 71.5, 76.6, 75.9, 75.2),
  p40 = c(1.000, 1.000, 0.999, 0.998, 1.000, 1.000, 1.000),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(table10))) {
  scenario <- paste("Table 10", table10$recruitment[i], "YCS;", table10$catch[i], "catch")
  notes <- paste("Projection scenario with recruitment resampled from",
    table10$recruitment[i], "and future catch option", table10$catch[i],
    "as reported in Table 10.")
  add_output("biomass", "SSB", table10$B2029[i], "tonnes",
    "FAR 2024/84, Table 10, printed p. 15.", year = 2029L,
    lwr = table10$B2029_lwr[i], upr = table10$B2029_upr[i], scenario = scenario,
    notes = paste("Table reports B2029; corresponding figures identify the projected quantity as spawning biomass.", notes))
  add_output("biomass", "SSB_ratio_to_terminal_biomass", table10$B2029_B2024[i], "percent",
    "FAR 2024/84, Table 10, printed p. 15.", year = 2029L,
    lwr = table10$B2029_B2024_lwr[i], upr = table10$B2029_B2024_upr[i], scenario = scenario,
    notes = paste("Reported B2029/B2024, retained on the percent scale.", notes))
  add_output("biomass", "SSB_ratio_to_B0", table10$B2029_B0[i], "percent of B0",
    "FAR 2024/84, Table 10, printed p. 15.", year = 2029L,
    lwr = table10$B2029_B0_lwr[i], upr = table10$B2029_B0_upr[i], scenario = scenario,
    notes = paste("Reported B2029/B0, retained on the percent scale.", notes))
  add_output("probability", "probability_above_40_percent_B0", table10$p40[i], "probability",
    "FAR 2024/84, Table 10, printed p. 15.", year = 2029L,
    scenario = scenario, notes = paste("Posterior probability B2029 is above 40% of B0.", notes))
}

table11 <- data.frame(
  recruitment = table10$recruitment,
  catch = table10$catch,
  p30 = c(0.96, 0.95, 0.17, 0.16, 0.84, 0.68, 0.48),
  p25 = c(0.76, 0.73, 0.04, 0.03, 0.51, 0.30, 0.16),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(table11))) {
  base_scenario <- paste("Table 11", table11$recruitment[i], "YCS;", table11$catch[i], "catch")
  for (share in c("30", "25")) {
    value <- if (share == "30") table11$p30[i] else table11$p25[i]
    add_output("probability", "probability_lin5_exploitation_below_u40", value, "probability",
      "FAR 2024/84, Table 11, printed p. 16.", year = 2029L,
      scenario = paste(base_scenario, paste0("LIN5 assumed ", share, "% of total SSB")),
      notes = paste(
        "Follows the table heading and surrounding text, which identify the probability LIN 5 exploitation is below U40.",
        "The table caption instead says over U40; the source wording discrepancy is documented in the assessment assumptions."
      ))
  }
}
outputs <- do.call(rbind, output_rows)

assumption_rows <- assumptions
stock_header <- names(read.csv(file.path(root, "database", "stocks.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assessment_header <- names(read.csv(file.path(root, "database", "assessments.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
stock <- make_records(stock_header, data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "LIN 5&6 and LIN 6B", scientific_name = "Genypterus blacodes",
  common_name = "Sub-Antarctic ling", area = "LIN 5&6 and LIN 6B",
  region = "New Zealand sub-Antarctic", ocean = "Southwest Pacific",
  notes = paste(
    "One biological population assessed with LIN 5&6 and LIN 6B represented as separate fisheries.",
    "Statistical Area 032 is assigned to LIN 7WC in the current stock definition."
  ), stringsAsFactors = FALSE
))
assessment <- make_records(assessment_header, data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2024L,
  terminal_year = 2023L, estimate_terminal_year = 2029L,
  assessment_type = "full_assessment", model_family = "Casal2",
  model_version = "Casal2 v24.02", is_current = TRUE, is_applied = TRUE,
  framework_year = "", assessment_url = "https://fs.fish.govt.nz/Doc/25828/FAR-2024-84-2024-stock-assessment-of-ling-in-the-Sub-Antarctic.pdf.ashx",
  framework_url = "https://fs.fish.govt.nz/Doc/25827/FAR-2024-83-Stock-hypothesis-for-ling-in-the-Sub-Antarctic.pdf.ashx",
  data_url = "https://fs.fish.govt.nz/Doc/25826/FAR-2024-82-Descriptive-analysis-of-ling-in-the-Sub-Antarctic-up-to-2023-and-inputs-for-the-2024-stock-assessment.pdf.ashx",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Latest detailed assessment located and identified as current for advice by the May 2025 Fisheries Assessment Plenary.",
    "Annual catch biomass, fixed M, reported maturity ages 3-13, model assumptions, and aggregate posterior tables are recorded.",
    "Numerical survey indices and fitted age-composition vectors are not published in the reviewed run-specific sources; no annual numerical population-at-age outputs were located."
  ), stringsAsFactors = FALSE
))

if (nrow(catch_data) != 156L || nrow(M_data) != 56L || nrow(maturity) != 22L ||
    nrow(inputs) != 234L || nrow(assumption_rows) != 24L || nrow(outputs) != 80L ||
    sum(outputs$measure == "unfished_spawning_biomass" & grepl("Table 8", outputs$scenario, fixed = TRUE)) != 5L ||
    sum(grepl("Table 9", outputs$scenario, fixed = TRUE)) != 28L ||
    sum(grepl("Table 10", outputs$scenario, fixed = TRUE)) != 28L ||
    sum(grepl("Table 11", outputs$scenario, fixed = TRUE)) != 14L) {
  stop("Unexpected Sub-Antarctic ling source-record counts.", call. = FALSE)
}
if (any(inputs$type == "index") || any(inputs$measure %in% c("numbers_at_age", "proportion_at_age")) ||
    !identical(sort(unique(as.integer(catch_data$year))), 1972:2023) ||
    any(inputs$source_reference == "") || any(outputs$source_reference == "")) {
  stop("Unexpected inferred likelihood data or missing source references.", call. = FALSE)
}

## Validate and optionally append ----

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
read_assessment_ids <- function(path) {
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  classes <- rep("NULL", length(header)); names(classes) <- header
  classes[["assessment_id"]] <- "character"
  read.csv(path, colClasses = classes, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)$assessment_id
}
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- read.csv(assessments_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments_existing$assessment_id) {
  stop("Sub-Antarctic ling source records already exist; inspect before reimporting.", call. = FALSE)
}
for (table in c("assumptions", "inputs", "outputs")) {
  path <- file.path(root, "database", paste0(table, ".csv"))
  if (assessment_id %in% read_assessment_ids(path)) {
    stop(assessment_id, " already appears in ", path, ".", call. = FALSE)
  }
}

register_path <- file.path(root, "discovery", "candidates.csv")
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
selection_path <- file.path(root, "discovery", "selected_batch_06_2026.csv")
selection <- read.csv(selection_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selection_row <- which(selection$candidate_id == candidate_id)
if (length(candidate_row) != 1L || length(selection_row) != 1L ||
    register$import_status[candidate_row] != "not_started" ||
    selection$curation_status[selection_row] != "selected") {
  stop("Expected one selected, not-started Sub-Antarctic ling candidate.", call. = FALSE)
}
records <- list(stocks = stock, assessments = assessment,
  assumptions = assumptions, inputs = inputs, outputs = outputs)
for (table in names(records)) {
  path <- file.path(root, "database", paste0(table, ".csv"))
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  if (!identical(names(records[[table]]), header)) stop("Column mismatch for ", path, ".", call. = FALSE)
}

cat("Sub-Antarctic ling import prepared: 1 stock, 1 assessment, ",
  nrow(assumptions), " assumptions, ", nrow(inputs), " inputs, and ",
  nrow(outputs), " outputs.\n", sep = "")
cat("The input rows are 156 annual catch-biomass values, 56 fixed M-at-age values, and 22 reported maturity-at-age values.\n")
cat("Numerical survey indices and fitted age compositions are unavailable; no likelihood series is reconstructed.\n")

if (!write_data) {
  cat("Dry run only. Re-run with --write to append the source records.\n")
} else {
  append_rows <- function(path, rows) {
    write.table(rows, file = path, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", quote = TRUE, qmethod = "double")
  }
  append_rows(stocks_path, stock)
  append_rows(assessments_path, assessment)
  append_rows(file.path(root, "database", "assumptions.csv"), assumptions)
  append_rows(file.path(root, "database", "inputs.csv"), inputs)
  append_rows(file.path(root, "database", "outputs.csv"), outputs)

  register$matched_stock_id[candidate_row] <- stock_id
  register$match_status[candidate_row] <- "matched"
  register$import_status[candidate_row] <- "partial"
  register$decision_reason[candidate_row] <- paste(
    "The current LIN 5&6 and LIN 6B unit now has a partial source import from the 2024 assessment.",
    "Verified catch biomass, fixed M, reported maturity, model assumptions, and posterior summary tables are recorded.",
    "Run-specific survey indices and fitted age-composition vectors remain unavailable, so eligibility is unresolved."
  )
  register$notes[candidate_row] <- paste(
    "See source_reviews/mpi_ling_lin56_lin6b_2024.md.",
    "FAR 2024/74 catch-at-age estimates for 2023 are not mixed into the 2024 assessment inputs."
  )
  source(file.path(root, "scripts", "database", "candidate_register_io.R"))
  replace_candidate_register_row(register_path, candidate_row,
    register[candidate_row, , drop = FALSE], candidate_id)

  selection$curation_status[selection_row] <- "source_curated_partial"
  write.csv(selection, selection_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported partial Sub-Antarctic ling source records and updated the candidate summaries.\n")
}
