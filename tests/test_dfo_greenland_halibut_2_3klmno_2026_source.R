source("R/read_database.R")

mp <- read_assessment("dfo_greenland_halibut_2_3klmno_2026_mp")
ssm <- read_assessment("dfo_greenland_halibut_2_3klmno_2023_ssm")
mp_indices <- mp$inputs[mp$inputs$measure %in% "relative_biomass_index", ]
landings <- ssm$inputs[ssm$inputs$measure %in% "landings_biomass", ]
catch <- ssm$inputs[ssm$inputs$type %in% "catch" &
  ssm$inputs$measure %in% "numbers_at_age", ]
catch_weight <- ssm$inputs[ssm$inputs$measure %in% "catch_weight_at_age", ]
survey_age <- ssm$inputs[ssm$inputs$measure %in% "numbers_at_age" &
  ssm$inputs$type %in% "index", ]
natural_mortality <- ssm$inputs[ssm$inputs$measure %in% "natural_mortality_at_age", ]
recruitment <- ssm$outputs[ssm$outputs$measure %in% "recruitment", ]
exploitable_biomass <- ssm$outputs[ssm$outputs$measure %in% "exploitable_biomass", ]
fbar <- ssm$outputs[ssm$outputs$measure %in% "Fbar", ]

register <- utils::read.csv(
  "discovery/candidates.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
candidate <- register[register$candidate_id ==
  "DFO:Newfoundland and Labrador:Greenland Halibut (Turbot) - NAFO 2 + 3KLMNO", ]

stopifnot(
  mp$stocks$stock_id == "dfo_greenland_halibut_2_3klmno",
  mp$stocks$ocean == "Northwest Atlantic",
  mp$assessment$assessment_year == 2026L,
  mp$assessment$terminal_year == 2025L,
  mp$assessment$is_current,
  mp$assessment$is_applied,
  ssm$assessment$assessment_year == 2023L,
  ssm$assessment$terminal_year == 2021L,
  !ssm$assessment$is_current,
  !ssm$assessment$is_applied,
  nrow(mp_indices) == 67L,
  identical(sort(unique(mp_indices$year)), 2011:2025),
  setequal(unique(mp_indices$survey), c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "EU-Spain 3L",
    "EU-Spain 3NO", "EU 3M 0-1400m"
  )),
  mp_indices$value[mp_indices$survey == "Canada Autumn 2J3K" &
    mp_indices$year == 2011L] == 26.736,
  mp_indices$value[mp_indices$survey == "Canada Autumn 2J3K" &
    mp_indices$year == 2025L] == 23.718,
  mp_indices$value[mp_indices$survey == "EU 3M 0-1400m" &
    mp_indices$year == 2025L] == 20.650,
  all(mp_indices$unit == "kg per tow"),
  all(is.na(mp_indices$sampling_time)),
  nrow(landings) == 47L,
  identical(sort(unique(landings$year)), 1975:2021),
  landings$value[landings$year == 1975L] == 28.814,
  all(landings$unit == "kilotonnes"),
  nrow(catch) == 470L,
  identical(sort(unique(catch$year)), 1975:2021),
  identical(sort(unique(as.integer(catch$age))), 1:10),
  catch$value[catch$year == 1975L & catch$age == 5L] == 334,
  all(catch$unit == "thousand fish"),
  nrow(catch_weight) == 470L,
  catch_weight$value[catch_weight$year == 2021L & catch_weight$age == 10L] == 2.64,
  all(catch_weight$unit == "kg per fish"),
  nrow(survey_age) == 1232L,
  identical(sort(unique(as.integer(survey_age$age))), 0:10),
  setequal(unique(survey_age$survey), c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
    "EU 3M 0-1400m", "EU-Spain 3NO"
  )),
  survey_age$value[survey_age$survey == "Canada Autumn 2J3K" &
    survey_age$year == 1997L & survey_age$age == 0L] == 2.30,
  nrow(survey_age[survey_age$survey == "Canada Autumn 2J3K" &
    survey_age$year %in% c(2018L, 2019L, 2021L) & survey_age$age >= 8L, ]) == 9L,
  all(is.na(survey_age$value[survey_age$survey == "Canada Autumn 2J3K" &
    survey_age$year %in% c(2018L, 2019L, 2021L) & survey_age$age >= 8L])),
  any(grepl("source table reports 1.03.*excluded", survey_age$notes,
    ignore.case = TRUE)),
  all(survey_age$unit == "mean number per tow"),
  nrow(natural_mortality) == 10L,
  identical(sort(unique(as.integer(natural_mortality$age))), 1:10),
  all(natural_mortality$value == 0.12),
  nrow(recruitment) == 47L,
  recruitment$value[recruitment$year == 1975L] == 63.3,
  all(recruitment$unit == "million fish"),
  nrow(exploitable_biomass) == 47L,
  exploitable_biomass$value[exploitable_biomass$year == 1975L] == 91.7,
  all(exploitable_biomass$age_group == "5-9"),
  nrow(fbar) == 47L,
  fbar$value[fbar$year == 1975L] == 0.2,
  all(fbar$age_group == "5-9"),
  all(is.na(ssm$outputs$se)),
  all(is.na(ssm$outputs$lwr)),
  all(is.na(ssm$outputs$upr)),
  candidate$matched_stock_id == "dfo_greenland_halibut_2_3klmno",
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  file.exists("discovery/source_reviews/dfo_greenland_halibut_2_3klmno_2025.md")
)

cat("DFO/NAFO Greenland halibut source values, event separation, coverage and limitations passed.\n")
