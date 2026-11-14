root <- "."
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
register <- read_table("discovery/candidates.csv")
components <- register[register$candidate_id %in% c("NOAA:15338", "NOAA:15339"), , drop = FALSE]
units <- read_table("discovery/inventory_units.csv")
unit <- units[units$unit_key == "candidate:noaa_vermilion_rockfish_or_wa", , drop = FALSE]
stocks <- read_table("database/stocks.csv")
stock <- stocks[stocks$stock_id == "noaa_vermilion_rockfish_or_wa", , drop = FALSE]
assessments <- read_table("database/assessments.csv")
assessments <- assessments[assessments$stock_id == "noaa_vermilion_rockfish_or_wa", , drop = FALSE]
review <- paste(readLines("discovery/source_reviews/noaa_vermilion_rockfish_washington_2021.md",
  warn = FALSE), collapse = " ")

stopifnot(
  nrow(components) == 2L,
  all(components$candidate_unit_id == "noaa_vermilion_rockfish_or_wa"),
  all(components$match_status == "matched"),
  all(components$screening_status == "screened"),
  all(components$eligibility == "eligible"),
  all(components$import_status == "partial"),
  all(components$scientific_name == "Sebastes miniatus"),
  components$assessment_area[components$candidate_id == "NOAA:15338"] == "Oregon",
  components$assessment_area[components$candidate_id == "NOAA:15339"] == "Washington",
  nrow(unit) == 1L,
  unit$inventory_entries == 2L,
  unit$matched_stock_id == "noaa_vermilion_rockfish_or_wa",
  unit$import_status == "partial",
  grepl("conditional age-at-length", components$catch_age_evidence[components$candidate_id == "NOAA:15339"],
    fixed = TRUE),
  grepl("no abundance index", components$survey_age_evidence[components$candidate_id == "NOAA:15339"],
    fixed = TRUE),
  grepl("N-at-age", components$output_evidence[components$candidate_id == "NOAA:15339"],
    fixed = TRUE),
  nrow(stock) == 1L,
  stock$authority_stock_id == "15338; 15339",
  nrow(assessments) == 2L,
  setequal(assessments$assessment_id, c(
    "noaa_vermilion_rockfish_or_wa_2021_oregon",
    "noaa_vermilion_rockfish_or_wa_2021_washington")),
  grepl("separate from Washington", review, fixed = TRUE)
)
cat("NOAA Vermilion OR/WA candidate and component-registration checks passed.\n")

