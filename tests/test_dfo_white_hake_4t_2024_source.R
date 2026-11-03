source("R/read_database.R")

x <- read_assessment("dfo_white_hake_4t_2024")
inputs <- x$inputs
outputs <- x$outputs

landings <- inputs[inputs$measure == "landings_biomass", ]
catch_groups <- inputs[inputs$measure == "numbers_at_age_group", ]
rv_index <- inputs[inputs$survey == "sGSL Research Vessel survey" & inputs$measure == "numbers_at_age", ]
rv_weight <- inputs[inputs$survey == "sGSL Research Vessel survey" & inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
ssb <- outputs[outputs$measure == "SSB", ]
m_values <- outputs[outputs$measure == "natural_mortality_at_age", ]
f_values <- outputs[outputs$measure == "fishing_mortality_at_age", ]

register <- utils::read.csv(
  "discovery/candidates.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
candidate <- register[register$candidate_id == "DFO:Gulf:White Hake - NAFO 4T", ]

stopifnot(
  x$stocks$stock_id == "dfo_white_hake_4t",
  x$stocks$authority_stock_id == "NAFO Division 4T",
  x$stocks$ocean == "Northwest Atlantic",
  x$assessment$assessment_year == 2024L,
  x$assessment$terminal_year == 2022L,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(landings) == 45L,
  landings$value[landings$year == 1978L] == 4825,
  landings$value[landings$year == 2022L] == 17,
  all(landings$unit == "tonnes"),
  nrow(catch_groups) == 540L,
  sum(is.na(catch_groups$value)) == 93L,
  setequal(unique(catch_groups$age), c(0L, 3L:13L)),
  catch_groups$value[catch_groups$year == 1978L & catch_groups$age == 3L] == 79,
  is.na(catch_groups$value[catch_groups$year == 1978L & catch_groups$age == 0L]),
  catch_groups$value[catch_groups$year == 1983L & catch_groups$age == 0L] == 13.01,
  catch_groups$value[catch_groups$year == 2022L & catch_groups$age == 13L] == 0.03,
  all(grepl("Native printed age bin", catch_groups$notes)),
  nrow(rv_index) == 585L,
  identical(sort(unique(rv_index$year)), 1978:2022),
  identical(sort(unique(rv_index$age)), 2:14),
  rv_index$value[rv_index$year == 1978L & rv_index$age == 2L] == 1.762,
  all(rv_index$unit == "fish per tow"),
  all(rv_index$basis == "index_scale"),
  nrow(rv_weight) == 331L,
  rv_weight$value[rv_weight$year == 1979L & rv_weight$age == 12L] == 2.617,
  rv_weight$value[rv_weight$year == 1979L & rv_weight$age == 11L] == 5.1,
  rv_weight$value[rv_weight$year == 2022L & rv_weight$age == 6L] == 1.562,
  all(rv_weight$unit == "kg per fish"),
  nrow(maturity) == 9L,
  identical(sort(unique(maturity$age)), 2:10),
  identical(maturity$value[match(2:10, maturity$age)], c(0, 0, rep(1, 7))),
  nrow(ssb) == 3L,
  ssb$value[ssb$year == 2022L] == 6.1,
  nrow(m_values) == 8L,
  m_values$value[m_values$year == 2022L & m_values$age_group == "2-3"] == 1.1,
  m_values$value[m_values$year == 2022L & m_values$age_group == "4-5"] == 1.68,
  m_values$value[m_values$year == 2022L & m_values$age_group == "6+"] == 1.05,
  nrow(f_values) == 3L,
  f_values$value[f_values$year == 1992L & f_values$age_group == "6+"] == 0.72,
  all(is.na(outputs$se)),
  candidate$matched_stock_id == "dfo_white_hake_4t",
  candidate$import_status == "partial",
  file.exists("source_reviews/dfo_white_hake_4t.md")
)

cat("DFO NAFO 4T white hake source tables, units, gaps, and reported outputs passed.\n")
