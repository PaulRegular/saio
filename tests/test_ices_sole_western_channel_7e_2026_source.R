source("R/read_database.R")

database <- read_database()
assessment_id <- "ices_sole_western_channel_7e_2026"
assessment <- read_assessment(assessment_id, database)
inputs <- assessment$inputs
outputs <- assessment$outputs
input_value <- function(type, measure, year = NA_integer_, age = NA_integer_, survey = NA_character_) {
  rows <- inputs[inputs$type == type & inputs$measure == measure, , drop = FALSE]
  if (!is.na(year)) rows <- rows[as.integer(rows$year) == year, , drop = FALSE]
  if (!is.na(age)) rows <- rows[as.integer(rows$age) == age, , drop = FALSE]
  if (!is.na(survey)) rows <- rows[rows$survey == survey, , drop = FALSE]
  rows$value
}
output_value <- function(measure, year, age = NA_integer_) {
  rows <- outputs[outputs$measure == measure & as.integer(outputs$year) == year, , drop = FALSE]
  if (!is.na(age)) rows <- rows[as.integer(rows$age) == age, , drop = FALSE]
  rows$value
}

stopifnot(
  identical(assessment$stocks$authority_stock_id, "sol.27.7e"),
  identical(assessment$stocks$common_name, "Western English Channel common sole"),
  identical(assessment$stocks$ocean, "Northeast Atlantic"),
  as.integer(assessment$assessment$terminal_year) == 2025L,
  as.integer(assessment$assessment$estimate_terminal_year) == 2026L,
  identical(assessment$assessment$model_family, "XSA"),
  sum(inputs$type == "catch" & inputs$measure == "numbers_at_age") == 57L * 11L,
  sum(inputs$type == "catch_weight" & inputs$measure == "weight_at_age") == 57L * 11L,
  sum(inputs$type == "weight" & inputs$measure == "weight_at_age") == 57L * 11L,
  sum(inputs$type == "maturity" & inputs$measure == "maturity_at_age") == 11L,
  sum(inputs$type == "M" & inputs$measure == "natural_mortality_at_age") == 11L,
  all(inputs$value[inputs$type == "M"] == 0.1),
  sum(inputs$measure == "numbers_at_age" & inputs$type == "index") == 1738L,
  sum(inputs$measure == "index_catch_numbers_at_age") == 1738L,
  sum(inputs$measure == "effort") == 95L,
  sum(is.na(inputs$value[inputs$measure == "numbers_at_age" & inputs$type == "index"])) == 9L,
  isTRUE(all.equal(input_value("index", "numbers_at_age", 2003L, 3L, "UK-CBT-late"), 130.7 / 10.59557)),
  isTRUE(all.equal(input_value("index", "index_catch_numbers_at_age", 2003L, 3L, "UK-CBT-late"), 130.7)),
  isTRUE(all.equal(input_value("covariate", "effort", 2003L, survey = "UK-CBT-late"), 10.59557)),
  isTRUE(all.equal(input_value("catch", "numbers_at_age", 2025L, 2L), 155)),
  isTRUE(all.equal(input_value("weight", "weight_at_age", 2025L, 2L), 0.196)),
  isTRUE(all.equal(input_value("maturity", "maturity_at_age", age = 2L), 0.14)),
  sum(outputs$measure == "numbers_at_age") == 57L * 11L,
  sum(outputs$measure == "fishing_mortality_at_age") == 57L * 11L,
  sum(outputs$measure == "total_numbers") == 57L,
  sum(outputs$measure == "recruitment") == 58L,
  sum(outputs$measure == "SSB") == 58L,
  sum(outputs$measure == "total_biomass") == 57L,
  sum(outputs$measure == "Fbar") == 57L,
  all(outputs$source_type[outputs$measure == "total_numbers"] == "official_table"),
  isTRUE(all.equal(output_value("recruitment", 2025L), 2387.970407298)),
  isTRUE(all.equal(output_value("SSB", 2025L), 3857.276606186)),
  isTRUE(all.equal(output_value("fishing_mortality_at_age", 2025L, 2L), 0.07)),
  isTRUE(all.equal(output_value("total_numbers", 2025L), 16871)),
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  all(grepl("official_table|reconstructed_source_input|official_document", inputs$source_type))
)
cat("ICES Western Channel sole source validation passed.")
