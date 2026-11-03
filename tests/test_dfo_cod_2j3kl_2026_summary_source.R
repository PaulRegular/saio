testthat::test_that("Northern cod 2026 summary data stay separate from the detailed run", {
  root <- normalizePath(getwd())
  while (!file.exists(file.path(root, "analysis", "comp_assessments", "database", "assessments.csv"))) {
    parent <- dirname(root)
    if (identical(parent, root)) testthat::fail("Could not locate the assessment database.")
    root <- parent
  }
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(root)
  source("R/read_database.R")
  db <- read_database()
  id <- "dfo_cod_2j3kl_2026_summary"
  summary <- db$assessments[db$assessments$assessment_id == id, , drop = FALSE]
  detailed <- db$assessments[db$assessments$assessment_id == "dfo_cod_2j3kl_2025", , drop = FALSE]

  testthat::expect_equal(nrow(summary), 1L)
  testthat::expect_false(summary$is_current)
  testthat::expect_true(summary$is_applied)
  testthat::expect_equal(summary$assessment_year, 2026L)
  testthat::expect_equal(summary$terminal_year, 2025L)
  testthat::expect_equal(summary$estimate_terminal_year, 2026L)
  testthat::expect_true(detailed$is_current)

  catch <- db$inputs[db$inputs$assessment_id == id, , drop = FALSE]
  testthat::expect_equal(nrow(catch), 30L)
  testthat::expect_true(all(catch$type == "catch" & catch$measure == "total_biomass"))
  testthat::expect_equal(sort(unique(catch$year)), 2016:2025)
  testthat::expect_setequal(catch$region, paste("NAFO Division", c("2J", "3K", "3L")))
  catch <- catch[order(match(catch$region, paste("NAFO Division", c("2J", "3K", "3L"))), catch$year), ]
  testthat::expect_equal(as.numeric(catch$value), c(
    216,313,281,444,1129,1314,1836,2481,2960,5437,
    5273,6335,4436,4819,3767,4387,5527,5611,6297,13370,
    4618,6232,4744,5241,5364,5276,5112,4990,6448,9438
  ))
  testthat::expect_true(all(catch$unit == "t"))
  testthat::expect_true(all(grepl("provisional", catch$notes[catch$year == 2025])))
  testthat::expect_true(all(grepl("Table 2, p. 6", catch$source_reference)))

  out <- db$outputs[db$outputs$assessment_id == id, , drop = FALSE]
  ssb <- out[out$measure == "SSB", , drop = FALSE]
  recruits <- out[out$measure == "recruitment", , drop = FALSE]
  mbar <- out[out$measure == "Mbar", , drop = FALSE]
  fbar <- out[out$measure == "Fbar", , drop = FALSE]
  testthat::expect_equal(nrow(out), 18L)
  testthat::expect_equal(as.numeric(ssb$value), c(284,291,338,449,542))
  testthat::expect_equal(as.numeric(ssb$lwr), c(198,217,268,363,423))
  testthat::expect_equal(as.numeric(ssb$upr), c(410,389,426,554,696))
  testthat::expect_equal(as.numeric(recruits$value), c(.83,1,1.02,1.15,1.23))
  testthat::expect_true(all(recruits$age == 0 & recruits$unit == "billion fish"))
  testthat::expect_equal(as.numeric(mbar$value), c(.39,.31,.22,.26))
  testthat::expect_equal(as.numeric(fbar$value), c(.03,.03,.03,.04))
  testthat::expect_true(all(mbar$age_group == "5+" & fbar$age_group == "5+"))
  testthat::expect_false(any(out$year == 2026 & out$measure %in% c("Mbar", "Fbar")))
  testthat::expect_false(any(out$measure %in% c(
    "numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age"
  )))
  testthat::expect_true(all(is.na(out$se)))
  testthat::expect_true(all(grepl("Table 1, p. 5", out$source_reference)))
})
