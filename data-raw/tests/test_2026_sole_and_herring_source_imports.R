source("data-raw/scripts/shared/read_curation_database.R")
db <- read_database()

sole <- read_assessment("ices_sol_27_7a_2026", db)
herring <- read_assessment("noaa_atlantic_herring_gom_georges_bank_2026", db)

sole_inputs <- sole$inputs
sole_outputs <- sole$outputs
sole_catch <- sole_inputs[sole_inputs$type == "catch" &
  sole_inputs$measure == "numbers_at_age", ]
sole_catch_weights <- sole_inputs[sole_inputs$type == "catch_weight", ]
sole_stock_weights <- sole_inputs[sole_inputs$type == "weight", ]
sole_M <- sole_inputs[sole_inputs$type == "M", ]
sole_uk <- sole_inputs[!is.na(sole_inputs$survey) & sole_inputs$survey == "UK(E&W)-BTS-Q3", ]
sole_be <- sole_inputs[!is.na(sole_inputs$survey) & sole_inputs$survey == "BE-CBT", ]
sole_N <- sole_outputs[sole_outputs$measure == "numbers_at_age", ]
sole_F <- sole_outputs[sole_outputs$measure == "fishing_mortality_at_age", ]
sole_ssb <- sole_outputs[sole_outputs$measure == "SSB", ]
sole_tsb <- sole_outputs[sole_outputs$measure == "total_biomass", ]
sole_recruitment <- sole_outputs[sole_outputs$measure == "recruitment", ]
sole_q <- sole_outputs[sole_outputs$measure == "log_q", ]

stopifnot(
  sole$stocks$authority_stock_id == "sol.27.7a",
  sole$assessment$assessment_year == 2026L,
  sole$assessment$terminal_year == 2025L,
  sole$assessment$inputs_status == "partial",
  sole$assessment$outputs_status == "partial",
  nrow(sole_catch) == 56L * 10L,
  setequal(unique(sole_catch$year), 1970:2025),
  setequal(unique(sole_catch$age), 1:10),
  all(is.na(sole_catch$value[sole_catch$age == 1 & sole_catch$year < 2003])),
  nrow(sole_catch_weights) == 56L * 10L,
  nrow(sole_stock_weights) == 56L * 10L,
  nrow(sole_M) == 10L,
  all(sole_M$unit == "per year"),
  nrow(sole_uk) == 38L * 7L,
  all(is.na(sole_uk$value[sole_uk$year == 2020L])),
  nrow(sole_be) == 22L,
  all(is.na(sole_be$value[sole_be$year %in% 2017:2018])),
  nrow(sole_N) == 56L * 10L,
  nrow(sole_F) == 56L * 10L,
  nrow(sole_ssb) == 56L,
  nrow(sole_tsb) == 56L,
  nrow(sole_recruitment) == 56L,
  sole_ssb$value[sole_ssb$year == 2025L] == 3845,
  sole_tsb$value[sole_tsb$year == 2025L] == 5107,
  sole_recruitment$value[sole_recruitment$year == 2025L] == 20093,
  all(sole_F$value[sole_F$age == 9] == sole_F$value[sole_F$age == 10]),
  sole_q$value[!is.na(sole_q$age) & sole_q$age == 6] ==
    sole_q$value[!is.na(sole_q$age) & sole_q$age == 7]
)

herring_inputs <- herring$inputs
herring_outputs <- herring$outputs
herring_composition <- herring_inputs[herring_inputs$measure == "proportion_at_age", ]
herring_N <- herring_outputs[herring_outputs$measure == "numbers_at_age", ]
herring_F <- herring_outputs[herring_outputs$measure == "fishing_mortality_at_age", ]
herring_ssb <- herring_outputs[herring_outputs$measure == "SSB", ]
herring_recruitment <- herring_outputs[herring_outputs$measure == "recruitment", ]
herring_Fbar <- herring_outputs[herring_outputs$measure == "Fbar", ]

composition_sums <- aggregate(value ~ observation_id, herring_composition, sum)
herring_F$fleet[is.na(herring_F$fleet)] <- "Total"
f_by_fleet <- aggregate(value ~ fleet + year + age, herring_F, sum)
f_by_fleet <- reshape(f_by_fleet, idvar = c("year", "age"), timevar = "fleet", direction = "wide")

stopifnot(
  herring$stocks$authority_stock_id == "10572",
  herring$assessment$assessment_year == 2026L,
  herring$assessment$terminal_year == 2025L,
  herring$assessment$inputs_status == "partial",
  herring$assessment$outputs_status == "partial",
  nrow(herring_composition) == 2L * 39L * 8L,
  setequal(unique(herring_composition$fleet), c("Fixed", "Mobile")),
  setequal(unique(herring_composition$year), 1987:2025),
  setequal(unique(herring_composition$age), 1:8),
  all(abs(composition_sums$value - 1) < 5e-8),
  all(is.na(herring_composition$sample_size)),
  all(grepl("sample_size is left blank", herring_composition$notes, fixed = TRUE)),
  nrow(herring_N) == 39L * 8L,
  nrow(herring_F) == 3L * 39L * 8L,
  max(abs(f_by_fleet$value.Total - f_by_fleet$value.Mobile - f_by_fleet$value.Fixed)) <= 0.002,
  nrow(herring_ssb) == 8L,
  nrow(herring_recruitment) == 39L,
  nrow(herring_Fbar) == 39L,
  herring_ssb$value[herring_ssb$year == 2025L] == 35258,
  herring_Fbar$value[herring_Fbar$year == 2025L] == 0.121,
  all(herring_recruitment$value == herring_N$value[herring_N$age == 1][order(herring_N$year[herring_N$age == 1])])
)

sole_review <- paste(readLines("data-raw/source_reviews/ices_sol_27_7a.md", warn = FALSE), collapse = " ")
herring_review <- paste(readLines("data-raw/source_reviews/noaa_atlantic_herring_gom_georges_bank.md", warn = FALSE), collapse = " ")
stopifnot(
  grepl("3,845 tonnes", sole_review, fixed = TRUE),
  grepl("5,107 tonnes", sole_review, fixed = TRUE),
  grepl("35,258 mt", herring_review, fixed = TRUE),
  grepl("35,528 mt", herring_review, fixed = TRUE),
  grepl("numerical revised maturity", sole_review, fixed = TRUE),
  grepl("Matching fleet catch totals", herring_review, fixed = TRUE)
)

cat("Irish Sea sole and NOAA Atlantic herring source imports passed.\n")
