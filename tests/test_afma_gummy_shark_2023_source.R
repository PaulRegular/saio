read_assessment_rows <- function(path, assessment_id) {
  connection <- file(path, open = "rb")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0("\"", assessment_id, "\",")
  matching <- character()
  repeat {
    lines <- readLines(connection, n = 5000L, warn = FALSE)
    if (!length(lines)) break
    matching <- c(matching, lines[startsWith(lines, prefix)])
  }
  if (!length(matching)) return(utils::read.csv(text = header, stringsAsFactors = FALSE))
  utils::read.csv(text = paste(c(header, matching), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"),
    fileEncoding = "latin1")
}

assessment_id <- "afma_gummy_shark_sessf_2023"
stock_id <- "afma_gummy_shark_sessf"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
candidate <- candidate[candidate$candidate_id == "AFMA:SESSF_GUMMY_SHARK_2023", , drop = FALSE]

stopifnot(
  nrow(inputs) == 2016L,
  all(inputs$type == "catch"),
  all(inputs$measure == "catch_biomass"),
  all(inputs$basis == "biomass"),
  all(inputs$unit == "tonnes"),
  all(inputs$source_type == "official_table"),
  setequal(inputs$region, c("Bass Strait", "South Australia", "Tasmania")),
  length(unique(inputs$fleet)) == 7L,
  !any(grepl("Danish", inputs$fleet, ignore.case = TRUE)),
  all(inputs$year_basis == "model_year"),
  identical(sort(unique(inputs$year)), 1927:2022),
  all(is.finite(inputs$value) & inputs$value >= 0),
  any(inputs$value == 0),
  inputs$value[inputs$region == "Bass Strait" & inputs$year == 1927 & inputs$fleet == "Shallow line"] == 2.1,
  inputs$value[inputs$region == "South Australia" & inputs$year == 1938 & inputs$fleet == "Shallow line"] == 2.1,
  inputs$value[inputs$region == "Tasmania" & inputs$year == 1942 & inputs$fleet == "Shallow line"] == 15.8,
  nrow(outputs) == 23L,
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  any(outputs$measure == "natural_mortality_average_parameter" & outputs$value == 0.18 & outputs$unit == "yr-1"),
  any(outputs$measure == "unfished_biomass" & outputs$unit == "not stated"),
  any(outputs$measure == "maximum_sustainable_yield_rate" & outputs$value == 0.23 & outputs$region == "South Australia"),
  any(outputs$measure == "pup_production_depletion" & outputs$year == 2022 & outputs$value == 63 & outputs$region == "South Australia"),
  any(outputs$measure == "effort_saturation_parameter" & outputs$unit == "not stated"),
  any(outputs$type == "diagnostic" & outputs$measure == "negative_log_likelihood" & outputs$value == 1757),
  nrow(assumptions) == 13L,
  any(assumptions$setting == "spawning_biomass_proxy"),
  any(stocks$stock_id == stock_id & stocks$ocean == "Southwest Pacific and Southern Ocean"),
  any(assessments$assessment_id == assessment_id & assessments$terminal_year == 2022 & assessments$inputs_status == "partial"),
  nrow(candidate) == 1L,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial"
)

cat("AFMA Gummy Shark catch inputs, reported outputs, units, coverage, and unresolved gaps passed.\n")
