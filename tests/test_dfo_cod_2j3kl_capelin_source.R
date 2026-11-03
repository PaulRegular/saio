testthat::test_that("Northern cod Capelin covariate uses reported values when available", {
  root <- normalizePath(getwd())
  while (!file.exists(file.path(root, "analysis", "comp_assessments", "database", "inputs.csv"))) {
    parent <- dirname(root)
    if (identical(parent, root)) stop("Could not locate the assessment database.")
    root <- parent
  }
  inputs <- read.csv(
    file.path(root, "analysis", "comp_assessments", "database", "inputs.csv"),
    stringsAsFactors = FALSE, na.strings = "", check.names = FALSE
  )
  capelin <- inputs[
    inputs$assessment_id == "dfo_cod_2j3kl_2025" &
      inputs$measure == "capelin_biomass_index", , drop = FALSE
  ]
  years <- c(1985:1992, 1996, 1999:2005, 2007:2015, 2017:2019, 2022:2024)
  log_biomass_kt <- c(
    8.13, 8.20, 7.83, 8.34, 8.20, 8.65, 4.92, 4.92, 3.85,
    5.22, 4.45, 4.80, 4.33, 4.66, 4.71, 4.54,
    5.50, 5.52, 5.50, 3.08, 5.29, 5.15, 6.48, 6.64, 5.90,
    4.87, 5.64, 5.62, 5.55, 5.81, 6.46
  )
  exact_values <- c("2013" = 668, "2014" = 779, "2024" = 647)
  expected_values <- exp(log_biomass_kt)
  exact_rows <- as.character(years) %in% names(exact_values)
  expected_values[exact_rows] <- unname(exact_values[as.character(years[exact_rows])])

  testthat::expect_equal(nrow(capelin), length(years))
  testthat::expect_equal(as.integer(capelin$year), years)
  testthat::expect_true(all(is.finite(capelin$value) & capelin$value > 0))
  testthat::expect_equal(capelin$value, expected_values, tolerance = 1e-8)
  testthat::expect_true(all(capelin$type == "covariate"))
  testthat::expect_true(all(capelin$basis == "native_covariate"))
  testthat::expect_true(all(capelin$survey == "3L spring acoustic survey"))
  testthat::expect_true(all(capelin$region == "NAFO Division 3L"))
  testthat::expect_true(all(capelin$season == "spring"))
  testthat::expect_true(all(capelin$unit == "kt"))
  testthat::expect_true(all(capelin$source_type[!exact_rows] == "digitized"))
  testthat::expect_true(all(capelin$source_type[exact_rows] == "official_document"))
  testthat::expect_true(all(grepl("Figure 32", capelin$source_reference[!exact_rows])))
  testthat::expect_true(all(grepl("round the plotted log value to 0.01", capelin$transformation[!exact_rows])))
  testthat::expect_true(all(grepl("not the original", capelin$notes[!exact_rows])))
  testthat::expect_true(all(grepl("p. 8", capelin$source_reference[exact_rows])))
  testthat::expect_equal(
    capelin$value[match(as.integer(names(exact_values)), as.integer(capelin$year))],
    unname(exact_values)
  )
})
