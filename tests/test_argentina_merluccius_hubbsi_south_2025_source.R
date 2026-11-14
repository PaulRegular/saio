read_source_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

stock_id <- "argentina_merluccius_hubbsi_south_41s"
assessment_id <- paste0(stock_id, "_2025")
stock <- read_source_table("database/stocks.csv")
stock <- stock[stock$stock_id == stock_id, , drop = FALSE]
assessment <- read_source_table("database/assessments.csv")
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_source_table("database/inputs.csv")
inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
outputs <- read_source_table("database/outputs.csv")
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- read_source_table("database/assumptions.csv")
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- read_source_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == "INIDEP:MERLUCCIUS_HUBBSI_SUR41", , drop = FALSE]
selection <- read_source_table("discovery/selected_batch_12_2026.csv")
selection <- selection[selection$candidate_id == "INIDEP:MERLUCCIUS_HUBBSI_SUR41", , drop = FALSE]

catch_age <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
survey_age <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", ]
catch_biomass <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", ]
weights <- inputs[inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
natural_mortality <- inputs[inputs$measure == "natural_mortality_at_age", ]
age2_index <- inputs[inputs$measure == "recruitment_index", ]
summer_biomass_index <- inputs[!is.na(inputs$survey) &
  inputs$survey == "Summer reproductive survey", ]
cpue <- inputs[!is.na(inputs$observation_id) & inputs$observation_id != "", ]
model_n <- outputs[outputs$measure == "numbers_at_age", ]
total_n <- outputs[outputs$measure == "total_abundance", ]
cv <- outputs[grepl("_cv$", outputs$measure), ]
scalar_f_cv <- cv[cv$measure == "fishing_mortality_scalar_cv", ]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Merluccius hubbsi",
  stock$ocean == "Southwest Atlantic",
  stock$authority == "INIDEP",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2024,
  assessment$is_current,
  assessment$is_applied,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 15L,
  nrow(inputs) == 508L,
  nrow(outputs) == 624L,
  nrow(catch_age) == 273L,
  all(sort(unique(catch_age$year)) == 1986:2024),
  nrow(survey_age) == 98L,
  all(sort(unique(survey_age$year)) ==
    c(1996, 1998:2003, 2005, 2007, 2011:2013, 2016, 2024)),
  nrow(catch_biomass) == 39L,
  nrow(weights) == 14L,
  nrow(maturity) == 7L,
  nrow(natural_mortality) == 7L,
  all(natural_mortality$value == 0.3),
  nrow(age2_index) == 18L,
  nrow(summer_biomass_index) == 16L,
  all(age2_index$unit == "fish per trawl-hour"),
  all(summer_biomass_index$unit == "kg per trawl-hour"),
  nrow(cpue) == 36L,
  nrow(model_n) == 273L,
  all(model_n$unit == "thousand individuals"),
  all(sort(unique(model_n$year)) == 1986:2024),
  nrow(total_n) == 39L,
  nrow(cv) == 156L,
  all(cv$unit == "ratio"),
  all(is.finite(cv$value)),
  nrow(scalar_f_cv) == 39L,
  scalar_f_cv$value[scalar_f_cv$year == 1986] == 0.22,
  scalar_f_cv$value[scalar_f_cv$year == 2024] == 0.22,
  all(is.na(outputs$se)),
  all(model_n$age_group[model_n$age == 7] == "7+"),
  !any(outputs$measure == "fishing_mortality_at_age"),
  catch_age$value[catch_age$year == 1986 & catch_age$age == 1] == 220220,
  catch_biomass$value[catch_biomass$year == 1986] == 266038,
  age2_index$value[age2_index$year == 1995] == 2228,
  model_n$value[model_n$year == 2009 & model_n$age == 2] == 1470380,
  outputs$value[outputs$measure == "spawning_biomass" & outputs$year == 2024] == 777260,
  all(total_n$value == vapply(1986:2024, function(year) {
    sum(model_n$value[model_n$year == year])
  }, numeric(1))),
  grepl("Table 11 omits the unit; thousand individuals is inferred",
    outputs$notes[outputs$measure == "recruitment"][1],
    ignore.case = TRUE),
  candidate$import_status == "partial",
  selection$curation_status == "partial_source_import"
)

cat("INIDEP southern hake source import and coverage passed.\n")
