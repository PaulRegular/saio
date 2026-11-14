assessment_id <- "fra_northern_sea_japan_pollock_2026"
candidate_id <- "FRA:FRA-SA2026-SC01-01"

read_assessment_rows <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  header <- readLines(con, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  rows <- character()
  repeat {
    chunk <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) return(utils::read.csv(text = header,
    stringsAsFactors = FALSE, colClasses = "character",
    check.names = FALSE, na.strings = c("", "NA")))
  x <- utils::read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, colClasses = "character",
    check.names = FALSE, na.strings = c("", "NA"))
  x[] <- lapply(x, function(value) {
    value[is.na(value)] <- ""
    value
  })
  x
}

one_row <- function(x, criteria) {
  for (field in names(criteria)) x <- x[x[[field]] == criteria[[field]], , drop = FALSE]
  if (nrow(x) != 1L) stop("Expected one matching row; found ", nrow(x), ".")
  x
}

input <- read_assessment_rows("database/inputs.csv", assessment_id)
output <- read_assessment_rows("database/outputs.csv", assessment_id)
stocks <- utils::read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- utils::read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- utils::read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
manifest <- utils::read.csv(
  "provenance/fra_northern_sea_japan_pollock_2026/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

stock <- subset(stocks, stock_id == "fra_wpollock_northern_sea_japan")
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Gadus chalcogrammus",
  stock$ocean == "Northwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026L,
  assessment$terminal_year == 2025L,
  assessment$inputs_status == "complete",
  assessment$assumptions_status == "partial",
  assessment$outputs_status == "partial",
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "fra_wpollock_northern_sea_japan",
  candidate$match_status == "matched",
  candidate$import_status == "imported",
  grepl("2024", candidate$survey_age_evidence, fixed = TRUE),
  nrow(manifest) == 1L,
  manifest$sha256 == "5A7687624933147E2F4CDA62F25639EAFD468024C88402A7AFB1ADE7CF7269B4",
  manifest$source_url == "https://www.fra.go.jp/shigen/fisheries_resources/meeting/stock_assessment_meeting/2026/files/sa2026-sc01/fra-sa2026-sc01-01.pdf",
  nrow(input) == 585L,
  nrow(output) == 2254L
)

catch <- subset(input, type == "catch" & measure == "numbers_at_age")
october <- subset(input, survey == "October spawning-stock distribution survey" &
  measure == "total_biomass")
recruit_survey <- subset(input,
  survey == "New-recruitment larval/juvenile distribution survey")
juvenile <- subset(input,
  survey == "Juvenile distribution survey (Musashi Bank)")
weights <- subset(input, type == "weight")
maturity <- subset(input, type == "maturity")
mortality <- subset(input, type == "M")

stopifnot(
  nrow(catch) == 414L,
  nrow(october) == 28L,
  nrow(recruit_survey) == 22L,
  nrow(juvenile) == 56L,
  nrow(weights) == 18L,
  nrow(maturity) == 36L,
  nrow(mortality) == 11L,
  setequal(unique(catch$year), as.character(1980:2025)),
  setequal(unique(catch$age), as.character(2:10)),
  one_row(catch, list(year = "1980", age = "2"))$value == "9625",
  one_row(october, list(year = "1998"))$value == "243745",
  one_row(october, list(year = "2025"))$value == "130544",
  grepl("excluded from tuning", one_row(october, list(year = "2002"))$notes, fixed = TRUE),
  grepl("excluded from tuning", one_row(october, list(year = "2012"))$notes, fixed = TRUE),
  one_row(recruit_survey, list(year = "2005"))$value == "61",
  one_row(recruit_survey, list(year = "2026"))$value == "798",
  one_row(juvenile, list(year = "2005", age = "1"))$value == "20",
  one_row(juvenile, list(year = "2024", age = "0"))$value == "430.4",
  nrow(subset(juvenile, year == "2005" & age == "0")) == 0L,
  nrow(subset(juvenile, year == "2023" & age == "2")) == 0L,
  one_row(weights, list(year = "2005", age = "2"))$value == "113",
  one_row(weights, list(year = "2006", age = "2"))$value == "78",
  one_row(maturity, list(year = "2005", age = "2", sex = "female"))$value == "0",
  one_row(maturity, list(year = "2006", age = "2", sex = "female"))$value == "0.04",
  one_row(maturity, list(year = "2005", age = "2", sex = "combined"))$value == "0.09",
  one_row(mortality, list(age = "0"))$value == "0.3",
  one_row(mortality, list(age = "1"))$value == "0.3",
  one_row(mortality, list(age = "2"))$value == "0.3",
  one_row(mortality, list(age = "3"))$value == "0.25",
  one_row(mortality, list(age = "10"))$value == "0.25"
)

age_outputs <- subset(output, measure %in% c(
  "catch_biomass_at_age", "fishing_mortality_at_age", "numbers_at_age",
  "biomass_at_age", "mature_biomass_at_age"
))
stopifnot(
  nrow(age_outputs) == 2070L,
  nrow(subset(output, measure == "total_numbers")) == 46L,
  nrow(subset(output, measure == "total_biomass")) == 46L,
  nrow(subset(output, measure == "SSB")) == 46L,
  nrow(subset(output, measure == "recruitment")) == 46L,
  all(output$se == "" & output$lwr == "" & output$upr == ""),
  one_row(output, list(measure = "numbers_at_age", year = "1980", age = "2"))$value == "684226",
  one_row(output, list(measure = "total_numbers", year = "1980"))$value == "2275398",
  one_row(output, list(measure = "total_biomass", year = "1980"))$value == "543836",
  one_row(output, list(measure = "SSB", year = "1980"))$value == "247124",
  one_row(output, list(measure = "recruitment", year = "1980"))$value == "684226",
  one_row(output, list(measure = "fishing_mortality_at_age",
    year = "1980", age = "10"))$age_group == "10+"
)

for (measure in c("numbers_at_age", "biomass_at_age", "mature_biomass_at_age")) {
  total_measure <- switch(measure,
    numbers_at_age = "total_numbers",
    biomass_at_age = "total_biomass",
    mature_biomass_at_age = "SSB")
  age_data <- output[output$measure == measure, , drop = FALSE]
  total_data <- subset(output, measure == total_measure)
  for (year in as.character(1980:2025)) {
    age_sum <- sum(as.numeric(age_data$value[age_data$year == year]))
    reported_total <- as.numeric(total_data$value[total_data$year == year])
    stopifnot(length(reported_total) == 1L, abs(age_sum - reported_total) <= 2)
  }
}
for (year in as.character(1980:2025)) {
  n_age2 <- as.numeric(one_row(output, list(
    measure = "numbers_at_age", year = year, age = "2"))$value)
  recruitment <- as.numeric(one_row(output, list(
    measure = "recruitment", year = year))$value)
  stopifnot(n_age2 == recruitment)
}

cat("FRA Northern Sea of Japan pollock source records passed.\n")
