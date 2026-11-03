root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- file.path(root, "analysis", "comp_assessments", "database")
read_db <- function(name) read.csv(file.path(database, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

assessment_id <- "ices_sardine_bay_biscay_8abd_2025_summary"
stock_id <- "ck_ices_wghansa_pilchardus_sp8abd"
stocks <- read_db("stocks.csv")
assessments <- read_db("assessments.csv")
inputs <- read_db("inputs.csv")
outputs <- read_db("outputs.csv")
assessment <- assessments[assessments$assessment_id == assessment_id, ]
catch <- inputs[inputs$assessment_id == assessment_id, ]
reported <- outputs[outputs$assessment_id == assessment_id, ]

stopifnot(
  sum(stocks$stock_id == stock_id) == 1L,
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  !assessment$is_current,
  assessment$is_applied,
  assessment$assessment_year == 2025L,
  assessment$terminal_year == 2024L,
  assessment$estimate_terminal_year == 2025L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(catch) == 26L,
  all(catch$type == "catch" & catch$measure == "total_biomass"),
  all(catch$basis == "biomass" & catch$unit == "tonnes"),
  all(catch$fleet == "Commercial_vessels"),
  identical(sort(as.integer(catch$year)), 2000:2025),
  all(is.na(catch$age)),
  nrow(reported) == 78L,
  all(reported$source_type == "official_machine_readable"),
  all(reported$source_reference == "ICES SAG 2025 source data, assessment key 21258; values cross-checked against WGHANSA 2025 Table 6.3.2.1"),
  reported$value[reported$measure == "recruitment" & reported$year == 2000L] == 4239.21,
  reported$value[reported$measure == "recruitment" & reported$year == 2024L] == 7869.85,
  reported$value[reported$measure == "recruitment" & reported$year == 2025L] == 4493,
  reported$value[reported$measure == "SSB" & reported$year == 2000L] == 134547,
  reported$value[reported$measure == "Fbar" & reported$year == 2000L] == 0.154296,
  all(grepl("95%", reported$notes[!is.na(reported$lwr) | !is.na(reported$upr)])),
  !any(reported$measure == "recruitment" & reported$year == 2025L &
    (!is.na(reported$lwr) | !is.na(reported$upr))),
  !any(reported$measure == "Fbar" & reported$year == 2025L &
    (!is.na(reported$lwr) | !is.na(reported$upr)))
)

cat("ICES Bay of Biscay sardine summary-source checks passed.\n")
