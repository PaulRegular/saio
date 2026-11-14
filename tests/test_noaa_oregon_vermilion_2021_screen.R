root <- "."
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
register <- read_table("discovery/candidates.csv")
candidate <- register[register$candidate_id == "NOAA:15338", , drop = FALSE]
unit <- read_table("discovery/inventory_units.csv")
unit <- unit[unit$unit_key == "candidate:noaa_vermilion_rockfish_or_wa", , drop = FALSE]
stocks <- read_table("database/stocks.csv")
stock <- stocks[stocks$stock_id == "noaa_vermilion_rockfish_or_wa", , drop = FALSE]
assessments <- read_table("database/assessments.csv")
assessments <- assessments[assessments$stock_id == "noaa_vermilion_rockfish_or_wa", , drop = FALSE]
review <- paste(readLines("discovery/source_reviews/noaa_vermilion_rockfish_oregon_2021.md",
  warn = FALSE), collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "noaa_vermilion_rockfish_or_wa",
  candidate$official_stock_id == "15338",
  candidate$scientific_name == "Sebastes miniatus",
  candidate$assessment_area == "Oregon",
  candidate$inventory_assessment_year == "2021",
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  grepl("conditional age-at-length", candidate$catch_age_evidence, fixed = TRUE),
  grepl("aggregate ORBS CPUE", candidate$survey_age_evidence, fixed = TRUE),
  grepl("May-September", candidate$timing_evidence, fixed = TRUE),
  grepl("Report.sso", candidate$output_evidence, fixed = TRUE),
  grepl("incomplete age-sample coverage", review, fixed = TRUE),
  grepl("fractional-year time", review, fixed = TRUE),
  nrow(stock) == 1L,
  stock$authority_stock_id == "15338; 15339",
  nrow(assessments) == 2L,
  "noaa_vermilion_rockfish_or_wa_2021_oregon" %in% assessments$assessment_id,
  nrow(unit) == 1L,
  unit$import_status == "partial"
)
cat("NOAA Oregon vermilion source-registration checks passed.\n")

