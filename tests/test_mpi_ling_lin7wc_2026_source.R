source("R/read_database.R")

assessment_id <- "mpi_ling_lin7wc_2026"
x <- read_assessment(assessment_id)
inputs <- x$inputs
outputs <- x$outputs
assumptions <- x$assumptions
input_values <- function(measure, type = NULL) {
  rows <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.null(type)) rows <- rows[rows$type == type, , drop = FALSE]
  rows
}

catch <- input_values("landings_biomass", "catch")
cpue <- input_values("relative_abundance_index", "index")
cpue_cv <- input_values("abundance_index_cv", "index")
survey <- input_values("relative_biomass_index", "index")
survey_cv <- input_values("biomass_index_cv", "index")
age_numbers <- input_values("numbers_at_age")
age_cv <- input_values("numbers_at_age_cv")
maturity <- input_values("maturity_at_age", "maturity")

stopifnot(
  nrow(x$stocks) == 1L,
  x$stocks$stock_id == "mpi_ling_lin7wc",
  x$stocks$authority_stock_id == "LIN 7WC",
  x$stocks$scientific_name == "Genypterus blacodes",
  x$stocks$ocean == "Southwest Pacific",
  x$assessment$assessment_year == 2026,
  x$assessment$terminal_year == 2025,
  x$assessment$estimate_terminal_year == 2026,
  x$assessment$model_family == "Casal2",
  x$assessment$model_version == "v24.02",
  x$assessment$inputs_status == "partial",
  x$assessment$assumptions_status == "partial",
  x$assessment$outputs_status == "partial",
  nrow(inputs) == 500L,
  nrow(catch) == 162L,
  setequal(unique(catch$fleet), c("Bottom trawl", "Bottom longline", "Potting")),
  identical(sort(unique(as.integer(catch$year))), 1972:2025),
  all(catch$year_basis == "model_year"),
  all(catch$unit == "tonnes"),
  catch$value[catch$fleet == "Bottom trawl" & catch$year == "1972"] == "0",
  catch$value[catch$fleet == "Potting" & catch$year == "2025"] == "581",
  nrow(cpue) == 65L,
  nrow(cpue_cv) == 65L,
  nrow(cpue[cpue$survey == "Bottom longline CPUE", ]) == 36L,
  nrow(cpue[cpue$survey == "Bottom trawl CPUE", ]) == 29L,
  cpue$value[cpue$survey == "Bottom longline CPUE" & cpue$year == "1990"] == "1060",
  cpue$value[cpue$survey == "Bottom trawl CPUE" & cpue$year == "1997"] == "1783",
  cpue$value[cpue$survey == "Bottom longline CPUE" & cpue$year == "2025"] == "432",
  all(cpue$basis == "index_scale"),
  all(cpue$unit == "CPUE index units (not stated)"),
  nrow(survey) == 7L,
  nrow(survey_cv) == 7L,
  setequal(as.integer(survey$year), c(2000, 2012, 2013, 2016, 2018, 2021, 2024)),
  survey$value[survey$year == "2000"] == "1860.9",
  survey$value[survey$year == "2024"] == "611.7",
  abs(as.numeric(survey_cv$value[survey_cv$year == "2000"]) - 0.173) < 1e-12,
  abs(as.numeric(survey_cv$value[survey_cv$year == "2024"]) - 0.16) < 1e-12,
  nrow(age_numbers) == 87L,
  nrow(age_cv) == 87L,
  nrow(age_numbers[age_numbers$type == "catch", ]) == 43L,
  nrow(age_numbers[age_numbers$type == "index", ]) == 44L,
  all(age_numbers$unit[age_numbers$type == "catch"] ==
    "numbers-at-age (unit not stated)"),
  all(age_numbers$unit[age_numbers$type == "index"] ==
    "number (index scale; multiplier not stated)"),
  !any(age_numbers$age == "25"),
  all(age_numbers$sampling_time == "0.5"),
  all(age_cv$unit == "ratio"),
  nrow(maturity) == 20L,
  all(maturity$year == "" | is.na(maturity$year)),
  all(maturity$age %in% as.character(3:12)),
  maturity$value[maturity$sex == "male" & maturity$age == "8"] == "0.94",
  maturity$value[maturity$sex == "female" & maturity$age == "9"] == "0.65",
  assumptions$value[assumptions$setting == "natural_mortality"] ==
    "Fixed M=0.18 y-1, constant at age and equal for both sexes.",
  assumptions$value[assumptions$setting == "observation_fraction_of_Z"] == "0.5",
  nrow(outputs) == 9L
)

mpd <- outputs[outputs$scenario == "Base case; MPD", , drop = FALSE]
mcmc <- outputs[outputs$scenario == "Base case; MCMC posterior median", , drop = FALSE]
b0 <- mcmc[mcmc$measure == "unfished_spawning_biomass", , drop = FALSE]
status <- mcmc[mcmc$measure == "SSB_ratio_to_B0", , drop = FALSE]
stopifnot(
  mpd$value[mpd$measure == "spawning_biomass" & mpd$year == "2026"] == "18621",
  b0$value == "54144",
  b0$lwr == "50096",
  b0$upr == "59413",
  status$value == "0.34",
  status$lwr == "0.289",
  status$upr == "0.401",
  !any(outputs$measure %in% c(
    "numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "recruitment"
  ))
)

candidates <- read.csv("discovery/candidates.csv",
  stringsAsFactors = FALSE, colClasses = "character",
  na.strings = c("", "NA"), check.names = FALSE
)
candidate <- candidates[candidates$candidate_id == "MPI:LIN7WC", , drop = FALSE]
manifest <- read.csv("provenance/mpi_ling_lin7wc_2026_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)
review <- readLines("source_reviews/mpi_ling_lin7wc_2026.md", warn = FALSE)
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_ling_lin7wc",
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 4L,
  setequal(manifest$sha256, c(
    "871202A3970B6554F36D1DC4BD7184A1A8A5F05BECEA21DC16CFE7F97F0CA445",
    "261A653258FAA3221A442766F2998219F00AC29B733EBDE144F35CA1519DDC5A",
    "7250D4DF0A5259B8454D18B620A7D411FADE4CDE68CC9C57B0B620034C1C0FA2",
    "3043F7E6E8C8F3395E8683ED0312C2D8AC93097858D8577B747764C86D8999C9"
  )),
  !any(grepl("tinyAM|translation", review, ignore.case = TRUE))
)

cat("LIN 7WC 2026 source checks passed.\n")
