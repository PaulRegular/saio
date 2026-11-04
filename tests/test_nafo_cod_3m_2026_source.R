root <- "."
assessment_id <- "nafo_cod_3m_2026"
stock_id <- "nafo_cod_3m"

read_selected <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}

stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidates <- read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
inputs <- read_selected(file.path(root, "database", "inputs.csv"), c(
  "assessment_id", "type", "measure", "basis", "year", "year_basis", "age",
  "value", "unit", "sampling_time", "source_type", "source_reference",
  "transformation", "notes", "fleet", "survey", "region", "season"))
outputs <- read_selected(file.path(root, "database", "outputs.csv"), c(
  "assessment_id", "type", "measure", "year", "age", "age_group", "value",
  "se", "lwr", "upr", "unit", "source_type", "source_reference", "notes"))
assumptions <- read_selected(file.path(root, "database", "assumptions.csv"), c(
  "assessment_id", "component", "setting", "value", "source_reference", "notes"))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NAFO:cod.3M", , drop = FALSE]
i <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
a <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]

input <- function(type, measure, year = NA_integer_, age = NA_real_) {
  selected <- i$type == type & i$measure == measure
  if (!is.na(year)) selected <- selected & as.integer(i$year) == year
  if (!is.na(age)) selected <- selected & as.numeric(i$age) == age
  i[selected, , drop = FALSE]
}
output <- function(type, measure, year = NA_integer_, age = NA_real_) {
  selected <- o$type == type & o$measure == measure
  if (!is.na(year)) selected <- selected & as.integer(o$year) == year
  if (!is.na(age)) selected <- selected & as.numeric(o$age) == age
  o[selected, , drop = FALSE]
}
get_value <- function(x, year = NA_integer_, age = NA_real_) {
  selected <- rep(TRUE, nrow(x))
  if (!is.na(year)) selected <- selected & as.integer(x$year) == year
  if (!is.na(age)) selected <- selected & as.numeric(x$age) == age
  values <- as.numeric(x$value[selected])
  if (length(values) != 1L) stop("Expected one extracted value.")
  values[[1]]
}

catch_total <- input("catch", "total_biomass")
catch_age <- input("catch", "numbers_at_age")
survey_source <- input("index", "numbers_at_age")
survey_model <- input("index", "index_by_age_group")
catch_weight <- input("catch_weight", "catch_weight_at_age")
stock_weight <- input("weight", "weight_at_age")
maturity <- input("maturity", "maturity_at_age")
m_prior <- input("M", "natural_mortality_at_age")
biomass <- output("biomass", "total_biomass")
ssb <- output("biomass", "SSB")
recruitment <- output("recruitment", "recruitment")
fbar <- output("mortality", "Fbar")
f_age <- output("mortality", "fishing_mortality_at_age")
n_age <- output("population", "numbers_at_age")
n_total <- output("population", "total_numbers")
mature_n <- output("population", "mature_numbers")
m_posterior <- output("mortality", "natural_mortality_at_age")
a50 <- output("biology", "age_at_maturity_50_percent")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NAFO",
  stock$authority_stock_id == "cod.3M",
  stock$scientific_name == "Gadus morhua",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026L,
  assessment$terminal_year == 2025L,
  assessment$framework_year == 2018L,
  assessment$is_current,
  assessment$is_applied,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  candidate$import_status == "partial",
  nrow(catch_total) == 38L,
  get_value(catch_total, 1988L) == 28899,
  get_value(catch_total, 2025L) == 12485,
  all(catch_total$unit == "tonnes"),
  nrow(catch_age) == 272L,
  get_value(catch_age, 1988L, 2L) == 3500,
  get_value(catch_age, 2025L, 8L) == 864,
  all(as.numeric(catch_age$value[as.numeric(catch_age$age) == 1]) == 0),
  !any(as.integer(catch_age$year) %in% 2002:2005),
  all(catch_age$unit == "thousand fish"),
  nrow(survey_source) == 722L,
  sum(is.na(survey_source$value)) == 2L,
  get_value(survey_source, 2025L, 1L) == 1786,
  nrow(survey_model) == 304L,
  get_value(survey_model, 2025L, 8L) == 1965,
  is.na(get_value(survey_model, 2005L, 7L)),
  is.na(get_value(survey_model, 2018L, 8L)),
  get_value(survey_model, 1988L, 8L) == 72,
  all(is.na(survey_model$sampling_time)),
  nrow(catch_weight) == 304L,
  nrow(stock_weight) == 304L,
  nrow(maturity) == 304L,
  nrow(m_prior) == 8L,
  get_value(m_prior, age = 1L) == 1.26,
  nrow(biomass) == 38L,
  nrow(ssb) == 38L,
  nrow(recruitment) == 38L,
  nrow(fbar) == 38L,
  get_value(biomass, 2025L) == 70872,
  get_value(ssb, 2025L) == 39216,
  get_value(recruitment, 2025L) == 31134,
  get_value(fbar, 2025L) == 0.115,
  fbar$age_group[as.integer(fbar$year) == 2025L] == "3-5",
  get_value(f_age, 2025L, 8L) == 0.331,
  nrow(n_age) == 304L,
  nrow(n_total) == 38L,
  get_value(n_total, 2025L) == 82174,
  get_value(output("population", "numbers_at_age"), 2025L, 1L) ==
    get_value(recruitment, 2025L),
  abs(sum(as.numeric(n_age$value[as.integer(n_age$year) == 2025L])) - 82174) < 1e-8,
  nrow(mature_n) == 38L,
  get_value(mature_n, 2025L) == 18618,
  nrow(m_posterior) == 8L,
  get_value(m_posterior, age = 8L) == 0.34,
  nrow(a50) == 38L,
  get_value(a50, 2025L) == 4.96,
  all(is.na(o$se)),
  all(biomass$lwr[as.integer(biomass$year) == 2025L] == 65002),
  all(biomass$upr[as.integer(biomass$year) == 2025L] == 77634),
  all(grepl("central 80%", o$notes[!is.na(o$lwr)])),
  all(!is.na(o$source_reference) & nzchar(o$source_reference)),
  nrow(a) == 22L,
  any(a$setting == "survey_timing_alpha" & grepl("0.50", a$value, fixed = TRUE)),
  any(a$setting == "survey_timing_beta" & grepl("0.58", a$value, fixed = TRUE)),
  any(a$setting == "M_prior_cv" & grepl("0.15", a$value, fixed = TRUE)),
  grepl("2018", assessment$notes, fixed = TRUE),
  file.exists(file.path(root, "source_reviews", "nafo_cod_3m_2026.md"))
)

manifest <- read.csv(file.path(root, "provenance", "nafo_cod_3m_2026", "manifest.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
survey_report <- manifest[manifest$cached_file == "nafo_scr26_003_flemish_cap_survey_2025.pdf", , drop = FALSE]
stopifnot(
  nrow(survey_report) == 1L,
  survey_report$sha256 == "8790F7C15B2B68013E321E6BC23CE355CFE2F67FBE47E78607C6C7A36F5516D7"
)

message("NAFO 3M cod source records validated.")
