root <- "."
read_table <- function(file) {
  read.csv(file.path(root, "database", file), na.strings = c("", "NA"),
    stringsAsFactors = FALSE, check.names = FALSE)
}

id <- "nefsc_garmiii_gb_cod_2012"
stock_id <- "ck_nefsc_garmiii_morhua_gb"
stock <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
assumptions <- read_table("assumptions.csv")
a <- assessments[assessments$assessment_id == id, , drop = FALSE]
i <- inputs[inputs$assessment_id == id, , drop = FALSE]
o <- outputs[outputs$assessment_id == id, , drop = FALSE]
u <- assumptions[assumptions$assessment_id == id, , drop = FALSE]

input <- function(measure, year = NA_integer_, age = NA_integer_, survey = "", type = "") {
  x <- i[i$measure == measure, , drop = FALSE]
  if (nzchar(type)) x <- x[x$type == type, , drop = FALSE]
  if (!is.na(year)) x <- x[x$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  if (nzchar(survey)) x <- x[x$survey == survey, , drop = FALSE]
  x
}
output <- function(measure, year = NA_integer_, age = NA_integer_) {
  x <- o[o$measure == measure, , drop = FALSE]
  if (!is.na(year)) x <- x[x$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  x
}

stopifnot(
  sum(stock$stock_id == stock_id) == 1L,
  grepl(paste0("assessment_id ", id), stock$notes[stock$stock_id == stock_id], fixed = TRUE),
  !grepl("Metadata-only entry", stock$notes[stock$stock_id == stock_id], fixed = TRUE),
  nrow(a) == 1L,
  a$assessment_year == 2012L,
  a$terminal_year == 2011L,
  a$model_family == "ASAP",
  a$model_version == "SAW55 Base ASAP v3.0.6",
  a$inputs_status == "complete",
  a$assumptions_status == "partial",
  a$outputs_status == "partial",
  nrow(i) == 2402L,
  nrow(o) == 853L,
  nrow(u) == 24L,
  sum(i$type == "catch" & i$measure == "numbers_at_age") == 340L,
  sum(i$type == "catch" & i$measure == "total_biomass") == 34L,
  sum(i$type == "catch" & i$measure == "relative_standard_error") == 34L,
  sum(i$type == "catch_weight" & i$measure == "catch_weight_at_age") == 340L,
  sum(i$type == "weight" & i$measure == "weight_at_age") == 340L,
  sum(i$type == "maturity" & i$measure == "maturity_at_age") == 340L,
  sum(i$type == "M" & i$measure == "natural_mortality_at_age") == 10L,
  sum(i$type == "index" & i$measure == "numbers_at_age") == 780L,
  sum(i$type == "index" & i$measure == "total_numbers") == 92L,
  sum(i$type == "index" & i$measure == "abundance_index_cv") == 92L,
  sum(is.na(i$value)) == 5L,
  all(i$source_type[i$measure == "abundance_index_cv"] == "reconstructed_source_input"),
  all(i$unit[i$measure == "numbers_at_age" & i$type == "catch"] == "thousand fish"),
  input("numbers_at_age", 1978L, 1L, type = "catch")$value == 324,
  input("total_biomass", 1978L)$value == 40702,
  input("catch_weight_at_age", 1978L, 1L)$value == 0.502,
  input("numbers_at_age", 1978L, 1L, "NEFSC spring bottom trawl (Yankee 41)", "index")$value == 0.37,
  input("total_numbers", 1977L, survey = "NEFSC autumn bottom trawl")$value == 5.4,
  input("abundance_index_cv", 1978L, survey = "NEFSC spring bottom trawl (Yankee 41)")$value == 0.374,
  input("abundance_index_cv", 1986L, survey = "DFO February bottom trawl")$value == 0.45,
  all(i$unit[i$measure == "natural_mortality_at_age"] == "year^-1"),
  all(i$value[i$measure == "natural_mortality_at_age"] == 0.2),
  output("numbers_at_age", 1978L, 1L)$value == 29399,
  output("total_abundance", 1978L)$value == 78290,
  output("january_1_biomass", 1978L)$value == 118945,
  output("SSB", 2011L)$value == 22217,
  output("SSB", 2011L)$lwr == 15809,
  output("SSB", 2011L)$upr == 31993,
  output("Fbar", 2011L)$value == 0.23,
  output("Fbar", 2011L)$lwr == 0.15,
  output("Fbar", 2011L)$upr == 0.34,
  output("SSB_rho_adjusted", 2011L)$value == 13216,
  output("Ffull_rho_adjusted", 2011L)$value == 0.43,
  output("recruitment_rho_adjusted", 2011L)$value == 5131,
  all(is.na(o$se)),
  sum(!is.na(o$lwr)) == 2L,
  all(grepl("NAFO 5Z and Subarea 6", a$notes, fixed = TRUE)),
  any(u$setting == "autumn_cohort_alignment"),
  any(u$setting == "survey_cv_adjustments"),
  any(u$setting == "natural_mortality")
)

cat("SAW55 Georges Bank/South blank-stock import and source-value checks passed.\n")
