root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database_dir <- file.path(root, "database")
read_table <- function(name) read.csv(
  file.path(database_dir, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)

assessments <- read_table("assessments.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
assumptions <- read_table("assumptions.csv")
assessment_id <- "ices_sole_20_24_2026_summary"
report_url <- "https://doi.org/10.17895/ices.pub.32455056.v3"
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
source_inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
source_outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
source_assumptions <- assumptions[
  assumptions$assessment_id == assessment_id, , drop = FALSE
]

catch <- source_inputs[
  source_inputs$type == "catch" & source_inputs$measure == "numbers_at_age",
  , drop = FALSE
]
weights <- source_inputs[
  source_inputs$type == "weight" & source_inputs$measure == "weight_at_age",
  , drop = FALSE
]
indices <- source_inputs[
  source_inputs$type == "index" & source_inputs$measure == "numbers_at_age",
  , drop = FALSE
]
q4 <- indices[indices$survey == "Q4Solesurvey1-9+", , drop = FALSE]
gillnet <- indices[indices$survey == "Gillnet", , drop = FALSE]
trawl <- indices[indices$survey == "Trawl", , drop = FALSE]

n_at_age <- source_outputs[
  source_outputs$measure == "numbers_at_age", , drop = FALSE
]
f_at_age <- source_outputs[
  source_outputs$measure == "fishing_mortality_at_age", , drop = FALSE
]
total_numbers <- source_outputs[
  source_outputs$measure == "total_numbers", , drop = FALSE
]
table_outputs <- source_outputs[
  source_outputs$source_type == "official_table", , drop = FALSE
]
machine_outputs <- source_outputs[
  source_outputs$source_type == "official_machine_readable", , drop = FALSE
]
total_biomass <- table_outputs[
  table_outputs$measure == "total_biomass", , drop = FALSE
]
reported_fbar <- machine_outputs[
  machine_outputs$measure == "Fbar", , drop = FALSE
]
reported_recruitment <- machine_outputs[
  machine_outputs$measure == "recruitment", , drop = FALSE
]
reported_ssb <- machine_outputs[
  machine_outputs$measure == "SSB", , drop = FALSE
]

sum_n <- stats::aggregate(as.numeric(n_at_age$value),
  list(year = n_at_age$year), sum
)
total_index <- match(sum_n$year, total_numbers$year)
f_by_year <- split(f_at_age, f_at_age$year)
age9_f_equal <- vapply(f_by_year, function(x) {
  all(as.numeric(x$value[x$age %in% 6:9]) ==
    as.numeric(x$value[x$age == 6][rep(1L, 4L)]))
}, logical(1))

stopifnot(
  nrow(assessment) == 1L,
  assessment$is_current,
  assessment$assessment_year == 2026,
  assessment$terminal_year == 2025,
  assessment$assessment_type == "annual_assessment",
  assessment$model_family == "SAM",
  assessment$assessment_url == report_url,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(catch) == 336L,
  setequal(unique(catch$year), 1984:2025),
  setequal(unique(catch$age), 2:9),
  all(catch$unit == "thousand fish"),
  catch$value[catch$year == 2025 & catch$age == 2] == 67,
  nrow(weights) == 336L,
  setequal(unique(weights$year), 1984:2025),
  setequal(unique(weights$age), 2:9),
  all(weights$unit == "kg per fish"),
  weights$value[weights$year == 2024 & weights$age == 2] == 0.249,
  weights$value[weights$year == 2025 & weights$age == 2] == 0.115,
  nrow(q4) == 171L,
  setequal(unique(q4$year), c(2004:2011, 2014:2024)),
  setequal(unique(q4$age), 1:9),
  all(q4$unit == "native survey-index units"),
  all(is.na(q4$sampling_time)),
  nrow(gillnet) == 112L,
  setequal(unique(gillnet$year), 1994:2007),
  setequal(unique(gillnet$age), 2:9),
  nrow(trawl) == 110L,
  setequal(unique(trawl$year), 1987:2008),
  setequal(unique(trawl$age), 2:6),
  all(indices$source_type == "official_table"),
  all(grepl(report_url, indices$source_reference, fixed = TRUE)),
  nrow(n_at_age) == 378L,
  setequal(unique(n_at_age$year), 1984:2025),
  setequal(unique(n_at_age$age), 1:9),
  all(n_at_age$unit == "thousand fish"),
  nrow(f_at_age) == 378L,
  setequal(unique(f_at_age$year), 1984:2025),
  setequal(unique(f_at_age$age), 1:9),
  all(age9_f_equal),
  nrow(total_numbers) == 42L,
  !anyNA(total_index),
  max(abs(as.numeric(total_numbers$value[total_index]) - sum_n$x)) < 1e-7,
  nrow(total_biomass) == 42L,
  all(total_biomass$unit == "tonnes"),
  all(total_biomass$lwr < total_biomass$value),
  all(total_biomass$value < total_biomass$upr),
  nrow(reported_fbar) == 42L,
  nrow(reported_recruitment) == 43L,
  nrow(reported_ssb) == 43L,
  all(source_assumptions$source_reference != ""),
  source_assumptions$value[
    source_assumptions$setting == "natural_mortality"
  ] == "Fixed M = 0.1 per year at all ages and years",
  source_assumptions$value[
    source_assumptions$setting == "maturity_at_age"
  ] == "Knife-edge maturity at age 3"
)

cat("ICES sole 20–24 2026 source records passed.\n")
