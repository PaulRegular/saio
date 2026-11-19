root <- if (file.exists("database/outputs.csv")) {
  "."
} else if (file.exists("../database/outputs.csv")) {
  ".."
} else {
  stop("Cannot locate the assessment database.")
}

assessment_id <- "ices_cod_eastern_baltic_2024"
assessment <- utils::read.csv(
  file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE,
  skipNul = TRUE
)
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
all_outputs <- utils::read.csv(
  file.path(root, "database", "outputs.csv"),
  skipNul = TRUE,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
outputs <- all_outputs[all_outputs$assessment_id == assessment_id, , drop = FALSE]

input_connection <- file(file.path(root, "database", "inputs.csv"), open = "rt")
has_assessment_inputs <- FALSE
repeat {
  lines <- readLines(input_connection, n = 50000L, warn = FALSE)
  if (!length(lines)) break
  if (any(startsWith(lines, paste0('"', assessment_id, '"')))) {
    has_assessment_inputs <- TRUE
    break
  }
}
close(input_connection)

n_at_age <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
f_at_age <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
relative_recruitment <- outputs[outputs$measure == "relative_recruitment", , drop = FALSE]
relative_ssb <- outputs[outputs$measure == "relative_SSB", , drop = FALSE]
relative_fbar <- outputs[outputs$measure == "relative_Fbar", , drop = FALSE]

testthat::test_that("Eastern Baltic cod 2024 outputs match the published tables", {
  testthat::expect_equal(nrow(assessment), 1L)
  testthat::expect_equal(assessment$stock_id, "ck_ices_wgbfas_morhua_bs_25_32")
  testthat::expect_equal(as.integer(assessment$assessment_year), 2024L)
  testthat::expect_equal(as.integer(assessment$terminal_year), 2024L)
  testthat::expect_false(assessment$is_current)
  testthat::expect_true(assessment$is_applied)
  testthat::expect_equal(assessment$inputs_status, "partial")
  testthat::expect_equal(assessment$outputs_status, "partial")
  testthat::expect_true(has_assessment_inputs)

  testthat::expect_equal(nrow(n_at_age), 79L * 8L)
  testthat::expect_setequal(unique(n_at_age$year), 1946:2024)
  testthat::expect_setequal(unique(n_at_age$age), 1:8)
  testthat::expect_true(all(n_at_age$unit == "thousand fish"))
  testthat::expect_true(all(n_at_age$type == "population"))
  testthat::expect_true(all(is.na(n_at_age$se) & is.na(n_at_age$lwr) & is.na(n_at_age$upr)))
  testthat::expect_true(all(grepl("beginning of the year", n_at_age$notes, fixed = TRUE)))
  testthat::expect_true(all(grepl("age 8 is not identified as a plus group", n_at_age$notes, fixed = TRUE)))

  testthat::expect_equal(nrow(f_at_age), 78L * 14L)
  testthat::expect_setequal(unique(f_at_age$year), 1946:2023)
  testthat::expect_setequal(unique(f_at_age$age), 1:14)
  testthat::expect_true(all(f_at_age$unit == "per year"))
  testthat::expect_true(all(f_at_age$type == "mortality"))
  testthat::expect_equal(f_at_age$value[f_at_age$year == 2023L & f_at_age$age == 11L], 0.4)
  testthat::expect_true(all(grepl("retained as printed", f_at_age$notes, fixed = TRUE)))

  testthat::expect_equal(nrow(relative_recruitment), 79L)
  testthat::expect_setequal(unique(relative_recruitment$year), 1946:2024)
  testthat::expect_equal(nrow(relative_ssb), 78L)
  testthat::expect_setequal(unique(relative_ssb$year), 1946:2023)
  testthat::expect_equal(nrow(relative_fbar), 78L)
  testthat::expect_setequal(unique(relative_fbar$year), 1946:2023)
  testthat::expect_true(all(relative_recruitment$unit == "ratio to time-series average"))
  testthat::expect_true(all(relative_ssb$unit == "ratio to time-series average"))
  testthat::expect_true(all(relative_fbar$unit == "ratio to time-series average"))
  testthat::expect_true(all(relative_fbar$age_group == "4-6"))
  testthat::expect_true(all(is.na(relative_recruitment$se)))
  testthat::expect_true(all(is.na(relative_ssb$se)))
  testthat::expect_true(all(is.na(relative_fbar$se)))
  testthat::expect_true(any(grepl("**", relative_recruitment$notes, fixed = TRUE)))
  testthat::expect_true(all(grepl("ICES WGBFAS 2024", outputs$source_reference, fixed = TRUE)))
  testthat::expect_false(any(grepl("[[:cntrl:]]", outputs$notes)))
})