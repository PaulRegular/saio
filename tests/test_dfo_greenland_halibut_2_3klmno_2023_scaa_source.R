source("R/read_database.R")

database <- read_database()
scaa <- read_assessment("dfo_greenland_halibut_2_3klmno_2023_scaa", database)
inputs <- scaa$inputs

landings <- inputs[inputs$measure == "landings_biomass", ]
catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
catch_weight <- inputs[inputs$type == "catch_weight" & inputs$measure == "catch_weight_at_age", ]
survey_biomass <- inputs[inputs$measure == "relative_biomass_index", ]
survey_age <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", ]
maturity <- inputs[inputs$type == "maturity" & inputs$measure == "maturity_at_age", ]
natural_mortality <- scaa$assumptions[scaa$assumptions$setting == "natural mortality M", ]
steepness <- scaa$assumptions[scaa$assumptions$setting == "steepness h", ]
ssb <- scaa$outputs[scaa$outputs$measure == "SSB", ]
exploitable <- scaa$outputs[scaa$outputs$measure == "exploitable_biomass", ]

ssm_survey_age <- database$inputs[
  database$inputs$assessment_id == "dfo_greenland_halibut_2_3klmno_2023_ssm" &
    database$inputs$type == "index" & database$inputs$measure == "numbers_at_age", ]
excluded_ssm <- ssm_survey_age$survey == "Canada Autumn 2J3K" &
  ssm_survey_age$year %in% c(2018L, 2019L, 2021L) & as.integer(ssm_survey_age$age) >= 8L

register <- utils::read.csv(
  "discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), encoding = "UTF-8"
)
candidate <- register[register$candidate_id ==
  "DFO:Newfoundland and Labrador:Greenland Halibut (Turbot) - NAFO 2 + 3KLMNO", ]

stopifnot(
  scaa$assessment$assessment_year == 2023L,
  scaa$assessment$terminal_year == 2021L,
  scaa$assessment$model_family == "Statistical catch-at-age model",
  !scaa$assessment$is_current,
  !scaa$assessment$is_applied,
  scaa$assessment$assumptions_status == "partial",
  scaa$assessment$inputs_status == "partial",
  scaa$assessment$outputs_status == "partial",
  nrow(landings) == 62L,
  identical(sort(unique(landings$year)), 1960:2021),
  landings$value[landings$year == 1960L] == 0.9,
  landings$value[landings$year == 2021L] == 15.039,
  nrow(catch) == 47L * 11L,
  identical(sort(unique(catch$year)), 1975:2021),
  identical(sort(unique(as.integer(catch$age))), 0:10),
  catch$value[catch$year == 2021L & catch$age == 0L] == 0,
  catch$value[catch$year == 2021L & catch$age == 2L] == 7,
  catch$value[catch$year == 2021L & catch$age == 10L] == 983,
  all(catch$unit == "thousand fish"),
  nrow(catch_weight) == 47L * 11L,
  catch_weight$value[catch_weight$year == 2021L & catch_weight$age == 10L] == 2.64,
  all(catch_weight$unit == "kg per fish"),
  setequal(unique(survey_biomass$survey), c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
    "EU 3M 0-700m", "EU 3M 0-1400m", "EU-Spain 3NO"
  )),
  survey_biomass$value[survey_biomass$survey == "Canada Autumn 2J3K" &
    survey_biomass$year == 2021L] == 21.15,
  survey_biomass$value[survey_biomass$survey == "EU 3M 0-1400m" &
    survey_biomass$year == 2021L] == 16.31,
  survey_biomass$value[survey_biomass$survey == "EU-Spain 3NO" &
    survey_biomass$year == 2021L] == 8.09,
  all(survey_biomass$unit == "kg per tow"),
  identical(sort(unique(as.integer(survey_age$age))), 0:10),
  setequal(unique(survey_age$survey), unique(survey_biomass$survey)),
  survey_age$value[survey_age$survey == "Canada Autumn 2J3K" &
    survey_age$year == 2021L & survey_age$age == 0L] == 10.95,
  identical(survey_age$value[survey_age$survey == "Canada Autumn 2J3K" &
    survey_age$year == 2021L & survey_age$age >= 8L], c(0.88, 0.35, 0.22)),
  all(survey_age$unit == "mean number per tow"),
  sum(excluded_ssm) == 9L,
  all(is.na(ssm_survey_age$value[excluded_ssm])),
  identical(sort(unique(as.integer(maturity$age))), 1:14),
  all(maturity$value[maturity$age <= 9L] == 0),
  all(maturity$value[maturity$age >= 10L] == 1),
  natural_mortality$value == "0.12 per year (fixed)",
  steepness$value == "0.80 (fixed)",
  nrow(ssb) == 3L,
  ssb$value[ssb$year == 2021L] == 91,
  all(is.na(ssb$se)) && all(is.na(ssb$lwr)) && all(is.na(ssb$upr)),
  grepl("CV reported as 0.19", ssb$notes[ssb$year == 2021L]),
  nrow(exploitable) == 3L,
  exploitable$value[exploitable$year == 2021L] == 62,
  all(exploitable$age_group == "5-9"),
  all(is.na(exploitable$se)) && all(is.na(exploitable$lwr)) && all(is.na(exploitable$upr)),
  !any(scaa$outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "recruitment")),
  candidate$matched_stock_id == "dfo_greenland_halibut_2_3klmno",
  candidate$import_status == "partial",
  file.exists("source_reviews/dfo_greenland_halibut_2_3klmno.md")
)

cat("DFO/NAFO Greenland halibut SCAA inputs, selected outputs, and separation from SSM passed.\n")
