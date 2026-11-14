source_id <- "siofa_orange_roughy_wsr_2025"
stock_id <- "siofa_orange_roughy_wsr"
candidate_id <- "SIOFA:ORY-2024-01:WSR"

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.")
}

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

append_rows <- function(path, rows) {
  file_size <- file.info(path)$size
  if (file_size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = file_size - 1, origin = "start")
    last_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(last_byte, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  rows[] <- lapply(rows, as.character)
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
stock_exists <- stock_id %in% stocks$stock_id
assessment_exists <- source_id %in% assessments$assessment_id
if (xor(stock_exists, assessment_exists)) {
  stop("The SIOFA WSR stock and assessment records are inconsistent.")
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "SIOFA",
  authority_stock_id = "WSR (assessment area)",
  scientific_name = "Hoplostethus atlanticus",
  common_name = "Orange roughy (Walter Shoal Ridge)",
  area = "Walter Shoal Ridge (WSR), SIOFA Statistical Area 2",
  region = "Southern Indian Ocean, SIOFA Statistical Area 2",
  ocean = "Southern Indian Ocean",
  notes = paste(
    "WSR is an assessment area, not a verified biological stock boundary.",
    "The 2025 project also assessed LWSR (including WSR) and SWIOR; those",
    "overlapping area models are not counted as additional stock units."
  ),
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = source_id,
  stock_id = stock_id,
  assessment_year = "2025",
  terminal_year = "2023",
  estimate_terminal_year = "2023",
  assessment_type = "assessment update",
  model_family = "Casal2 Bayesian age- and sex-based model",
  model_version = "R1.4 base-case MCMC",
  is_current = "TRUE",
  is_applied = "FALSE",
  framework_year = NA_character_,
  assessment_url = "https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-2-WSR-stock-assessment.pdf",
  framework_url = NA_character_,
  data_url = "https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-1-Biological-parameters-model-inputs.pdf",
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Uses data through 2023. Exact numerical model input arrays are not fully",
    "available in the public reports. The R1.4 scalar outputs are medians unless",
    "otherwise stated. Interim catch limit is based on mean 2015-2020 catch;",
    "public sources do not show that R1.4 was directly applied for management advice."
  ),
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = source_id,
    component = component,
    fleet = NA_character_,
    survey = NA_character_,
    sex = NA_character_,
    region = "WSR",
    season = NA_character_,
    setting = setting,
    value = value,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("population", "assessment_area", "Walter Shoal Ridge, SIOFA Statistical Area 2", "Report 2, Section 1 and Figure 1"),
  assumption("population", "model_age_range", "Ages 1-120 by sex; age 120 is a plus group", "Report 2, Table 3"),
  assumption("population", "model_year_range", "1885-2023", "Report 2, Table 3"),
  assumption("population", "time_steps", "Three annual steps: recruitment, fishing, ageing", "Report 2, Section 2.2"),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness h=0.57", "Report 2, Table 3"),
  assumption("mortality", "natural_mortality", "Estimated for males and females combined; R1.4 prior Normal(mean=0.045 per year, CV=0.1)", "Report 2, Table 4; Table 6"),
  assumption("catchability", "acoustic_catchability", "Free q per acoustic series with uniform prior 0.0001-0.8; R1.4 sum(q) prior Normal(mean=0.8, CV=0.1)", "Report 2, Table 4"),
  assumption("maturity", "maturity_selectivity", "Estimated logistic age curve; maturity equals selectivity and is shared by sexes", "Report 2, Section 2.2; Table 4"),
  assumption("observation", "age_frequency_data", "Unsexed distributions in 2017, 2019 and 2020; effective sample sizes; Francis reweighting", "Report 2, Sections 2.1-2.2; Table 2", "Raw 2017 age data were unavailable; 2019 and 2020 distributions were recalculated from available data."),
  assumption("observation", "acoustic_series_years", "Sleeping Beauty: 2007, 2009, 2010, 2015, 2018, 2022, 2023; Bounty: 2004, 2007, 2009, 2010, 2015, 2018; Hollows: 2009, 2011; OK Coral: 2015; Porky's: 2015, 2018", "Report 2, Table 2"),
  assumption("observation", "cpue_series_years", "Early: 2002-2006, 2009-2012 and 2014; late: 2019-2022", "Report 2, Table 2", "Two CPUE series are used because the fleets do not overlap across the 2015 change."),
  assumption("observation", "extra_process_error", "20% additional process error for acoustic and CPUE series", "Report 2, Section 2.2"),
  assumption("biology", "male_growth", "von Bertalanffy t0=-4.97 y; k=0.045 y-1; Linf=50.56 cm; CV=0.10", "Report 2, Table 3"),
  assumption("biology", "female_growth", "von Bertalanffy t0=-0.67 y; k=0.041 y-1; Linf=55.71 cm; CV=0.10", "Report 2, Table 3"),
  assumption("biology", "male_length_weight", "a=0.86e-9; b=2.73", "Report 2, Table 3", "No unit conversion applied; Table 3 notation is retained."),
  assumption("biology", "female_length_weight", "a=0.49e-9; b=2.90", "Report 2, Table 3", "No unit conversion applied; Table 3 notation is retained."),
  assumption("biology", "age_at_recruitment", "1 year", "Report 2, Table 3"),
  assumption("biology", "proportion_male_at_birth", "0.5", "Report 2, Table 3"),
  assumption("biology", "ageing_error_cv", "0.1", "Report 2, Table 3"),
  assumption("population", "maximum_exploitation_rate", "0.6", "Report 2, Table 3")
))

output <- function(type, measure, value, unit, year = NA_character_, survey = NA_character_,
                   lwr = NA_character_, upr = NA_character_, scenario = "R1.4 base-case MCMC",
                   notes = "") {
  data.frame(
    assessment_id = source_id,
    type = type,
    measure = measure,
    fleet = NA_character_,
    survey = survey,
    sex = NA_character_,
    region = "WSR",
    season = NA_character_,
    year = year,
    age = NA_character_,
    age_group = NA_character_,
    value = as.character(value),
    se = NA_character_,
    lwr = lwr,
    upr = upr,
    unit = unit,
    source_type = "official_table",
    source_reference = "ORY-2024-01 Report 2, Table 6, R1.4",
    notes = notes,
    scenario = scenario,
    stringsAsFactors = FALSE
  )
}

outputs <- do.call(rbind, list(
  output("biomass", "unfished_spawning_biomass", 25627, "tonnes", lwr = 22409, upr = 30034,
    notes = "B0; MCMC median and reported 95% credible interval."),
  output("biomass", "SSB_ratio_to_B0", 59.3, "percent", year = "2023", lwr = 52.4, upr = 66.1,
    notes = "2023 spawning biomass as percent of B0; MCMC median and reported 95% credible interval."),
  output("mortality", "natural_mortality_average_parameter", 0.043, "per_year",
    notes = "Combined-sex MCMC median; R1.4 prior mean is 0.045 per year."),
  output("catchability", "q", 0.28, "ratio", survey = "Sleeping Beauty",
    notes = "Acoustic catchability for the Sleeping Beauty series; MCMC median."),
  output("mortality", "F_reference_at_SB40", 0.033, "per_year",
    notes = "Long-term instantaneous fishing mortality reference at 40% of B0; MCMC median."),
  output("biomass", "Bmsy", 30.8, "percent of B0",
    notes = "Biomass at maximum sustainable yield, reported as percent of B0; MCMC median."),
  output("mortality", "Fmsy", 0.045, "per_year",
    notes = "Long-term instantaneous fishing mortality at MSY; MCMC median."),
  output("catch", "catch_advice", 513, "tonnes", year = "2024", scenario = "F40",
    notes = "2024 TAC associated with F40; MCMC median."),
  output("catch", "catch_advice", 685, "tonnes", year = "2024", scenario = "FMSY",
    notes = "2024 TAC associated with FMSY; MCMC median.")
))

stopifnot(!anyDuplicated(assumptions$setting),
  all(assumptions$assessment_id == source_id),
  all(outputs$assessment_id == source_id),
  all(file.exists(c(
    "source_cache/siofa_orange_roughy_2025/Report-2-WSR-stock-assessment.pdf",
    "provenance/siofa_orange_roughy_2025_sources.csv"
  ))))

if (!stock_exists) {
  append_rows("database/stocks.csv", stock)
  append_rows("database/assessments.csv", assessment)
  append_rows("database/assumptions.csv", assumptions)
}

existing_outputs <- read_table("database/outputs.csv")
if (any(existing_outputs$assessment_id == source_id)) {
  stop("SIOFA WSR outputs are already imported.")
}
append_rows("database/outputs.csv", outputs)

candidate_path <- "discovery/candidates.csv"
source("scripts/database/candidate_register_io.R")
candidates <- read_table(candidate_path)
candidate_row <- match(candidate_id, candidates$candidate_id)
stopifnot(!is.na(candidate_row), candidates$import_status[candidate_row] == "not_started")
candidates$import_status[candidate_row] <- "partial"
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)
