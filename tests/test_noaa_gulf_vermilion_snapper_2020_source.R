assessment_id <- "noaa_vermilion_snapper_gulf_sedar67_2020"

read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE)
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  stopifnot(status == 0L, length(rows) > 0L)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

inputs <- read_assessment_rows("inputs")
assumptions <- read_assessment_rows("assumptions")
assessments <- read_assessment_rows("assessments")
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumption <- function(setting) {
  assumptions[assumptions$setting == setting, , drop = FALSE]
}

catch_totals <- inputs[inputs$type == "catch" &
  inputs$measure %in% c("catch_biomass", "catch_numbers"), , drop = FALSE]
catch_se <- inputs[inputs$type == "catch" & inputs$measure == "catch_se", , drop = FALSE]
indices <- inputs[inputs$type == "index" & inputs$measure %in% c(
  "relative_abundance_index", "relative_biomass_index",
  "relative_fishing_mortality_index", "larval_abundance_index"
), , drop = FALSE]
index_sds <- inputs[inputs$type == "index" & inputs$measure == "log_index_sd", , drop = FALSE]
discards <- inputs[inputs$measure %in% c("discard_biomass", "discard_numbers"), , drop = FALSE]
age_compositions <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
length_compositions <- inputs[inputs$measure == "proportion_at_length", , drop = FALSE]
mortality <- inputs[inputs$type == "M" & inputs$measure == "natural_mortality_at_age", , drop = FALSE]
stopifnot(
  nrow(assessment) == 1L,
  assessment$inputs_status == "partial",
  grepl("Appendix A DAT source inputs are imported", assessment$notes, fixed = TRUE),
  nrow(inputs) == 2494L,
  nrow(catch_totals) == 272L,
  nrow(catch_se[catch_se$partition == "catch", ]) == 272L,
  nrow(indices) == 243L,
  nrow(index_sds) == 243L,
  setequal(unique(indices$fleet[!is.na(indices$fleet)]),
    c("CM_E", "CM_W", "REC", "SMP_BYC")),
  setequal(unique(indices$survey[!is.na(indices$survey)]),
    c("East Gulf headboat CPUE", "West Gulf headboat CPUE",
      "SEAMAP larval survey", "Video survey",
      "SEAMAP summer groundfish survey")),
  nrow(discards[discards$type == "catch", , drop = FALSE]) == 132L,
  nrow(catch_se[catch_se$partition == "discard", ]) == 132L,
  nrow(age_compositions) == 64L * 14L,
  length(unique(age_compositions$observation_id)) == 64L,
  setequal(as.numeric(unique(age_compositions$age)), 1:14),
  all(age_compositions$age_error == 1),
  all(age_compositions$partition == 2),
  all(age_compositions$sample_size > 0),
  nrow(length_compositions) == 24L * 12L,
  length(unique(length_compositions$observation_id)) == 24L,
  setequal(as.numeric(unique(length_compositions$length_bin)),
    c(1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55)),
  all(length_compositions$sample_size > 0),
  nrow(mortality) == 16L,
  setequal(as.numeric(mortality$age), 0:15),
  mortality$value[mortality$age == 0] == 0.234,
  mortality$value[mortality$age == 15] == 0.204,
  all(mortality$source_type == "official_table"),
  all(is.finite(as.numeric(inputs$value))),
  !any(inputs$measure %in% c("numbers_at_age", "index_catch_numbers_at_age")),
  nrow(assumption("ss3_index_unit_codes")) == 1L,
  nrow(assumption("survey_timing_code")) == 1L,
  nrow(assumption("fixed_biological_parameters")) == 1L,
  grepl("not age-specific abundance indices or catch numbers at age",
    assumption("age_composition_input")$notes, fixed = TRUE)
)

age_sums <- aggregate(as.numeric(age_compositions$value),
  list(age_compositions$observation_id), sum)
length_sums <- aggregate(as.numeric(length_compositions$value),
  list(length_compositions$observation_id), sum)
stopifnot(
  all(abs(age_sums$x - 1) < 0.0001),
  all(abs(length_sums$x - 1) <= 0.0021)
)

placeholder <- catch_totals[catch_totals$fleet == "SMP_BYC", , drop = FALSE]
stopifnot(
  nrow(placeholder) == 68L,
  all(as.numeric(placeholder$value) == 0.001),
  all(grepl("placeholder", placeholder$notes, fixed = TRUE)),
  all(is.na(indices$sampling_time)),
  sum(indices$measure == "relative_fishing_mortality_index") > 0L,
  all(grepl("SEDAR 67 final report", inputs$source_reference, fixed = TRUE))
)
