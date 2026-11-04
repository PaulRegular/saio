root <- "."
assessment_id <- "nafo_cod_3no_2021"
stock_id <- "nafo_cod_3no"

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
  "assessment_id", "type", "measure", "basis", "year", "age", "value",
  "unit", "sampling_time", "source_type", "source_reference", "transformation",
  "notes", "fleet", "survey", "region", "season"))
outputs <- read_selected(file.path(root, "database", "outputs.csv"), c(
  "assessment_id", "type", "measure", "year", "age", "age_group", "survey", "value",
  "se", "lwr", "upr", "unit", "source_type", "source_reference", "notes"))
assumptions <- read_selected(file.path(root, "database", "assumptions.csv"), c(
  "assessment_id", "component", "setting", "value", "source_reference", "notes"))

i <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
a <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NAFO:cod.3NO", , drop = FALSE]

input <- function(type, measure, year = NA_integer_, age = NA_real_,
  survey = NULL, season = NULL) {
  selected <- i$type == type & i$measure == measure
  if (!is.na(year)) selected <- selected & as.integer(i$year) == year
  if (!is.na(age)) selected <- selected & as.numeric(i$age) == age
  if (!is.null(survey)) selected <- selected & i$survey == survey
  if (!is.null(season)) selected <- selected & i$season == season
  i[selected, , drop = FALSE]
}

output <- function(type, measure, year = NA_integer_, age = NA_real_,
  age_group = NULL, survey = NULL) {
  selected <- o$type == type & o$measure == measure
  if (!is.na(year)) selected <- selected & as.integer(o$year) == year
  if (!is.na(age)) selected <- selected & as.numeric(o$age) == age
  if (!is.null(age_group)) selected <- selected & o$age_group == age_group
  if (!is.null(survey)) selected <- selected & o$survey == survey
  o[selected, , drop = FALSE]
}

value <- function(x) {
  if (nrow(x) != 1L) stop("Expected exactly one source value.")
  as.numeric(x$value[[1L]])
}

catch_age <- input("catch", "numbers_at_age")
catch_weight <- input("catch_weight", "catch_weight_at_age")
spring <- input("index", "numbers_at_age", survey = "Canadian spring RV bottom-trawl survey")
autumn <- input("index", "numbers_at_age", survey = "Canadian autumn RV bottom-trawl survey")
juvenile <- input("index", "numbers_at_age", survey = "Canadian juvenile survey")
stock_weight <- input("weight", "weight_at_age")
maturity <- input("maturity", "maturity_at_age")
natural_mortality <- input("M", "natural_mortality_at_age")
n_age <- output("population", "numbers_at_age")
n_total <- output("population", "total_numbers")
f_age <- output("mortality", "fishing_mortality_at_age")
fbar <- output("mortality", "Fbar")
biomass_age <- output("biomass", "biomass_at_age")
biomass_total <- output("biomass", "total_biomass")
mature_biomass <- output("biomass", "mature_biomass_at_age")
ssb <- output("biomass", "SSB")
table20_survivors <- output("population", "survivors_at_age")
table20_q <- output("catchability", "q")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NAFO",
  stock$authority_stock_id == "cod.3NO",
  stock$scientific_name == "Gadus morhua",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2019L,
  assessment$estimate_terminal_year == 2020L,
  assessment$model_family == "ADAPT",
  assessment$is_current,
  assessment$is_applied,
  assessment$inputs_status == "complete",
  assessment$outputs_status == "partial",
  candidate$import_status == "partial",
  nrow(a) == 17L,
  nrow(i) == 3224L,
  nrow(o) == 3026L,
  nrow(catch_age) == 671L,
  all(as.numeric(catch_age$age) %in% 2:12),
  all(as.integer(catch_age$year) %in% 1959:2019),
  all(catch_age$unit == "thousand fish"),
  all(catch_age$source_type == "digitized"),
  value(input("catch", "numbers_at_age", 1959L, 2L)) == 0,
  value(input("catch", "numbers_at_age", 1959L, 3L)) == 1711,
  value(input("catch", "numbers_at_age", 2019L, 12L)) == 4,
  nrow(catch_weight) == 610L,
  all(as.numeric(catch_weight$age) %in% 3:12),
  all(catch_weight$unit == "kg/fish"),
  value(input("catch_weight", "catch_weight_at_age", 1959L, 3L)) == 0.42,
  value(input("catch_weight", "catch_weight_at_age", 2019L, 12L)) == 6.41,
  nrow(spring) == 315L,
  nrow(autumn) == 261L,
  nrow(juvenile) == 54L,
  all(spring$season == "spring"),
  all(autumn$season == "autumn"),
  all(juvenile$season == "August-September"),
  all(c(spring$unit, autumn$unit, juvenile$unit) == "fish per tow"),
  all(is.na(c(spring$sampling_time, autumn$sampling_time, juvenile$sampling_time))),
  !any(as.integer(spring$year) == 2006L),
  !any(as.integer(autumn$year) == 2014L),
  value(input("index", "numbers_at_age", 2019L, 2L,
    "Canadian spring RV bottom-trawl survey")) == 2.06,
  value(input("index", "numbers_at_age", 2019L, 2L,
    "Canadian autumn RV bottom-trawl survey")) == 2.46,
  value(input("index", "numbers_at_age", 1989L, 2L,
    "Canadian juvenile survey")) == 14.16,
  nrow(stock_weight) == 620L,
  all(stock_weight$unit == "kg/fish"),
  value(input("weight", "weight_at_age", 2020L, 12L)) == 5.377,
  nrow(maturity) == 682L,
  all(maturity$unit == "proportion"),
  nrow(natural_mortality) == 11L,
  all(as.numeric(natural_mortality$value) == 0.2),
  all(natural_mortality$unit == "year^-1"),
  nrow(n_age) == 682L,
  nrow(n_total) == 62L,
  value(output("population", "numbers_at_age", 1959L, 2L)) == 63623,
  value(output("population", "total_numbers", 1959L)) == 270633,
  nrow(f_age) == 671L,
  nrow(fbar) == 122L,
  value(output("mortality", "fishing_mortality_at_age", 1959L, 6L)) == 0.511,
  value(output("mortality", "Fbar", 2019L, age_group = "6-9")) == 0.076,
  value(output("mortality", "Fbar", 2019L, age_group = "4-6")) == 0.066,
  nrow(biomass_age) == 620L,
  nrow(biomass_total) == 124L,
  value(output("biomass", "total_biomass", 1959L, age_group = "3+")) == 206498,
  value(output("biomass", "total_biomass", 2020L, age_group = "6+")) == 7299,
  nrow(mature_biomass) == 620L,
  nrow(ssb) == 62L,
  value(output("biomass", "mature_biomass_at_age", 1959L, 3L)) == 126,
  value(output("biomass", "mature_biomass_at_age", 1959L, 12L)) == 1846,
  value(output("biomass", "SSB", 1959L)) == 72220,
  value(output("biomass", "SSB", 2020L)) == 7273,
  nrow(table20_survivors) == 36L,
  nrow(table20_q) == 27L,
  value(output("population", "survivors_at_age", 2020L, 3L)) == 1820,
  table20_survivors$se[as.integer(table20_survivors$year) == 2020L &
    as.numeric(table20_survivors$age) == 3L] == 1040,
  value(output("catchability", "q", age = 2L,
    survey = "Canadian spring RV bottom-trawl survey")) == 0.001112,
  table20_q$se[table20_q$survey == "Canadian spring RV bottom-trawl survey" &
    as.numeric(table20_q$age) == 2L] == 0.000161,
  all(table20_q$unit == "reported linear scale"),
  all(is.na(o$lwr) & is.na(o$upr)),
  all(is.na(o$se[!o$measure %in% c("survivors_at_age", "q")])),
  all(!is.na(i$source_reference) & nzchar(i$source_reference)),
  all(!is.na(o$source_reference) & nzchar(o$source_reference))
)

for (year in 1959:2020) {
  numbers <- as.numeric(n_age$value[as.integer(n_age$year) == year])
  total_numbers <- value(output("population", "total_numbers", year))
  if (abs(sum(numbers) - total_numbers) > 6) stop("N total rounding check failed in ", year)
  mature <- as.numeric(mature_biomass$value[as.integer(mature_biomass$year) == year])
  reported_ssb <- value(output("biomass", "SSB", year))
  if (abs(sum(mature) - reported_ssb) > 6) stop("SSB component check failed in ", year)
}

manifest <- read.csv(file.path(root, "provenance", "nafo_cod_3no_2021", "manifest.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(
  nrow(manifest) == 3L,
  all(manifest$assessment_id == assessment_id),
  all(grepl("^[0-9A-F]{64}$", manifest$sha256)),
  all(grepl("^https://", manifest$source_url)),
  file.exists(file.path(root, "source_reviews", "nafo_cod_3no_2021.md"))
)

message("NAFO cod 3NO source records validated.")