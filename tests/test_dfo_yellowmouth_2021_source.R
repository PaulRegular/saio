root <- "."
read_table <- function(name) {
  utils::read.csv(file.path(root, "database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

stock <- subset(read_table("stocks"), stock_id == "dfo_yellowmouth_bc")
assessment <- subset(read_table("assessments"),
  assessment_id == "dfo_yellowmouth_2021")
inputs <- subset(read_table("inputs"),
  assessment_id == "dfo_yellowmouth_2021")
assumptions <- subset(read_table("assumptions"),
  assessment_id == "dfo_yellowmouth_2021")
outputs <- subset(read_table("outputs"),
  assessment_id == "dfo_yellowmouth_2021")
candidates <- utils::read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
candidate <- subset(candidates,
  candidate_unit_id == "dfo_yellowmouth_bc")
units <- utils::read.csv(file.path(root, "discovery", "inventory_units.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
unit <- subset(units, candidate_unit_id == "dfo_yellowmouth_bc")
batch <- utils::read.csv(file.path(root, "discovery", "selected_batch_01_2026.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
selected <- subset(batch, candidate_unit_id == "dfo_yellowmouth_bc")
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "dfo_yellowmouth_2021.md"), warn = FALSE), collapse = " ")

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
survey_index <- subset(inputs, type == "index" & measure == "total_biomass")
survey_cv <- subset(inputs, type == "index" & measure == "biomass_index_cv")
cpue <- subset(inputs, type == "index" & measure == "relative_abundance_index")
cpue_se <- subset(inputs, type == "index" & measure == "index_sd")
maturity <- subset(inputs, type == "maturity" & measure == "maturity_at_age")
fixed_m <- subset(assumptions, setting %in% paste0("fixed_M_", c("R77", "R71", "R75", "R72", "R76")))
biology <- subset(assumptions, component == "biology")

expected_survey_years <- list(
  "Goose Island Gully historical trawl survey" = c(1967, 1969, 1971, 1973, 1976, 1977, 1984, 1994),
  "Queen Charlotte Sound synoptic trawl survey" = c(2003, 2004, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019),
  "West Coast Vancouver Island synoptic trawl survey" = c(2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018),
  "West Coast Haida Gwaii synoptic trawl survey" = c(2006, 2007, 2008, 2010, 2012, 2016, 2018, 2020)
)

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Sebastes reedi",
  stock$area == "PMFC areas 3CD and 5ABCDE; excludes 4B",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$is_current,
  assessment$is_applied,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2021L,
  assessment$estimate_terminal_year == 2022L,
  assessment$model_version == "3.30.17.01; composite base case",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(catch) == 87L,
  identical(sort(as.integer(catch$year)), 1935:2021),
  catch$value[catch$year == 1935] == 2.68,
  catch$value[catch$year == 2020] == 1057,
  catch$value[catch$year == 2021] == 1057,
  catch$source_type[catch$year == 2021] == "reconstructed_source_input",
  !any(catch$value == 298),
  nrow(survey_index) == 34L,
  nrow(survey_cv) == 34L,
  nrow(cpue) == 25L,
  nrow(cpue_se) == 25L,
  nrow(maturity) == 60L,
  identical(sort(as.integer(maturity$age)), 1:60),
  all(maturity$value[maturity$age <= 4] == 0),
  identical(as.numeric(maturity$value[maturity$age %in% 5:16]), c(
    .0549, .0880, .1352, .1994, .2819, .3822,
    .4970, .6198, .7414, .8505, .9357, .9873
  )),
  all(maturity$value[maturity$age >= 17] == 1),
  all(maturity$sex == "female"),
  all(survey_index$sampling_time == .5),
  all(cpue$sampling_time == .5),
  all(vapply(names(expected_survey_years), function(survey) {
    identical(sort(as.integer(survey_index$year[survey_index$survey == survey])),
      as.integer(expected_survey_years[[survey]]))
  }, logical(1))),
  !1997 %in% survey_index$year[survey_index$survey ==
    "West Coast Haida Gwaii synoptic trawl survey"],
  cpue$value[cpue$year == 1996] == 1.553,
  cpue$value[cpue$year == 2020] == 1.113,
  abs(exp(mean(log(cpue$value))) - 1) < .002,
  cpue_se$value[cpue_se$year == 1996] == .0903,
  cpue_se$value[cpue_se$year == 2020] == .0785,
  nrow(fixed_m) == 5L,
  identical(fixed_m$setting, paste0("fixed_M_", c("R77", "R71", "R75", "R72", "R76"))),
  identical(as.numeric(fixed_m$value), c(.04, .045, .05, .055, .06)),
  all(fixed_m$sex == "both"),
  all(c("length_weight_log_a", "length_weight_exponent_b",
    "growth_Linf_cm", "growth_rate_per_year", "growth_t0_years") %in%
      biology$setting),
  nrow(outputs) == 13L,
  outputs$value[outputs$measure == "spawning_biomass" &
      outputs$year == 2022] == 18001,
  outputs$lwr[outputs$measure == "spawning_biomass" &
      outputs$year == 2022] == 10070,
  outputs$upr[outputs$measure == "spawning_biomass" &
      outputs$year == 2022] == 42533,
  is.na(outputs$se[outputs$measure == "spawning_biomass" &
      outputs$year == 2022]),
  outputs$value[outputs$measure == "Bmsy"] == 7656,
  all(grepl("central 90%", outputs$notes)),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age")),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "dfo_yellowmouth_bc",
  candidate$import_status == "partial",
  candidate$review_date == "2026-11-03",
  nrow(unit) == 1L,
  unit$matched_stock_id == "dfo_yellowmouth_bc",
  unit$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import",
  grepl("midyear timing", review, fixed = TRUE),
  grepl("which CV series was supplied", review, fixed = TRUE),
  grepl("treating the survey compositions as age-specific abundance indices", review, fixed = TRUE),
  grepl("N-at-age and instantaneous F-at-age", review, fixed = TRUE)
)

cat("DFO Yellowmouth Rockfish 2021 source import checks passed.\n")
