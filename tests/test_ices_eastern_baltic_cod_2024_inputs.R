root <- if (file.exists("database/inputs.csv")) {
  "."
} else if (file.exists("../database/inputs.csv")) {
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

connection <- file(file.path(root, "database", "inputs.csv"), open = "rt")
header <- readLines(connection, n = 1L, warn = FALSE)
rows <- character()
repeat {
  lines <- readLines(connection, n = 50000L, warn = FALSE)
  if (!length(lines)) break
  rows <- c(rows, lines[startsWith(lines, paste0('"', assessment_id, '"'))])
}
close(connection)
inputs <- utils::read.csv(
  text = paste(c(header, rows), collapse = "\n"),
  stringsAsFactors = FALSE,
  check.names = FALSE,
  skipNul = TRUE
)
landings <- inputs[inputs$measure == "landings_biomass", , drop = FALSE]
discards <- inputs[inputs$measure == "discard_biomass", , drop = FALSE]
assumed_2024 <- inputs[inputs$measure == "total_biomass", , drop = FALSE]

testthat::test_that("Eastern Baltic cod 2024 aggregate catches are preserved with limits", {
  testthat::expect_equal(nrow(assessment), 1L)
  testthat::expect_equal(assessment$inputs_status, "partial")
  testthat::expect_equal(nrow(inputs), 137L)
  testthat::expect_equal(nrow(landings), 78L)
  testthat::expect_setequal(as.integer(landings$year), 1946:2023)
  testthat::expect_equal(landings$value[landings$year == 1946L], 40985)
  testthat::expect_equal(landings$value[landings$year == 2023L], 1008)
  testthat::expect_true(all(landings$unit == "tonnes"))
  testthat::expect_true(all(landings$basis == "biomass"))
  testthat::expect_true(all(landings$year_basis == "calendar_year"))
  testthat::expect_true(all(landings$source_type == "official_table"))
  testthat::expect_true(all(grepl("footnote", landings$notes, ignore.case = TRUE)))

  testthat::expect_equal(nrow(discards), 58L)
  testthat::expect_setequal(as.integer(discards$year), 1966:2023)
  testthat::expect_equal(discards$value[discards$year == 2023L], 57)
  testthat::expect_false(any(discards$year < 1966L))
  testthat::expect_true(all(discards$unit == "tonnes"))
  testthat::expect_true(all(discards$source_type == "official_table"))

  testthat::expect_equal(nrow(assumed_2024), 1L)
  testthat::expect_equal(as.integer(assumed_2024$year), 2024L)
  testthat::expect_equal(assumed_2024$value, 1065)
  testthat::expect_equal(assumed_2024$source_type, "official_document")
  testthat::expect_true(grepl("not split into components", assumed_2024$transformation, fixed = TRUE))
  testthat::expect_true(grepl("2023 total catch", assumed_2024$notes, fixed = TRUE))

  testthat::expect_true(all(is.na(inputs$age) | !nzchar(inputs$age)))
  testthat::expect_true(all(inputs$season == "annual"))
  testthat::expect_true(all(grepl("ICES WGBFAS 2024", inputs$source_reference, fixed = TRUE)))
})
