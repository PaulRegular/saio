root <- "."
import_env <- new.env(parent = globalenv())
source(file.path(root, "scripts", "database", "549_import_ices_irish_sea_herring_2026.R"),
  local = import_env
)

x <- import_env$inputs
y <- import_env$outputs
a <- import_env$assumptions
assessment_id <- "ices_her_27_nirs_2026"
stock_id <- "ices_her_27_nirs"

stopifnot(
  nrow(import_env$stock) == 1L,
  import_env$stock$authority_stock_id == "her.27.nirs",
  import_env$stock$ocean == "Northeast Atlantic",
  import_env$assessment$assessment_year == 2026L,
  import_env$assessment$terminal_year == 2025L,
  import_env$assessment$is_current,
  import_env$assessment$is_applied,
  all(c(import_env$assessment$assumptions_status,
    import_env$assessment$inputs_status, import_env$assessment$outputs_status) == "partial"),
  nrow(x) == 1747L,
  nrow(a) == 18L,
  nrow(y) == 276L
)

input <- function(type, measure, survey = NULL) {
  out <- x[x$type == type & x$measure == measure, , drop = FALSE]
  if (!is.null(survey)) out <- out[out$survey == survey, , drop = FALSE]
  out
}
output <- function(measure) y[y$measure == measure, , drop = FALSE]
cell <- function(data, year, age) {
  rows <- data$year == year
  if (is.na(age)) rows <- rows & is.na(data$age) else rows <- rows & data$age == age
  data$value[rows]
}

catch <- input("catch", "numbers_at_age")
isas <- input("index", "numbers_at_age", "Irish Sea Acoustic Survey (ISAS; AC(7.aN))")
isss <- input("index", "relative_biomass_index", "Irish Sea Commercial Acoustic Survey (ISSS; AC(7.aSpawn))")
catch_weight <- input("catch_weight", "catch_weight_at_age")
stock_weight <- input("weight", "weight_at_age")
maturity <- input("maturity", "maturity_at_age")
mortality <- input("M", "natural_mortality_at_age")

stopifnot(
  nrow(catch) == 360L,
  identical(sort(unique(catch$year)), setdiff(1980:2025, 2009)),
  identical(sort(unique(catch$age)), 1:8),
  all(catch$unit == "thousand fish"),
  all(grepl("Age 8 represents the reported 8+", catch$notes, fixed = TRUE)),
  cell(catch, 1980, 1) == 5840,
  cell(catch, 1992, 1) == 12145,
  cell(catch, 1993, 1) == 646,
  cell(catch, 1990, 7) == 1042,
  cell(catch, 1991, 7) == 719,
  cell(catch, 1992, 7) == 1036,
  nrow(isas) == 256L,
  identical(sort(unique(isas$year)), 1994:2025),
  identical(sort(unique(isas$age)), 1:8),
  all(is.na(isas$sampling_time)),
  cell(isas, 1994, 1) == 66.8,
  cell(isas, 2025, 8) == 3.7,
  nrow(isss) == 19L,
  identical(sort(unique(isss$year)), 2007:2025),
  all(isss$unit == "SSB index; unit not stated"),
  cell(isss, 2007, NA_integer_) == 47583,
  cell(isss, 2025, NA_integer_) == 31147,
  nrow(catch_weight) == 368L,
  nrow(stock_weight) == 368L,
  nrow(maturity) == 368L,
  identical(sort(unique(catch_weight$year)), 1980:2025),
  identical(sort(unique(stock_weight$year)), 1980:2025),
  identical(sort(unique(maturity$year)), 1980:2025),
  cell(catch_weight, 2009, 1) == 0.066,
  cell(stock_weight, 2009, 1) == 0.066,
  cell(maturity, 2009, 1) == 0.13,
  nrow(mortality) == 8L,
  all(is.na(mortality$year)),
  identical(sort(mortality$age), 1:8),
  identical(mortality$value[match(1:8, mortality$age)],
    c(0.787, 0.380, 0.353, 0.335, 0.315, 0.311, 0.304, 0.304)),
  all(is.na(x$sampling_time)),
  all(x$year_basis[!is.na(x$year)] == "model_year")
)

recruitment <- output("recruitment")
biomass <- output("total_biomass")
ssb <- output("SSB")
landings <- output("landings")
total_catch <- output("total_catch")
fbar <- output("Fbar")
stopifnot(
  nrow(recruitment) == 46L,
  nrow(biomass) == 46L,
  nrow(ssb) == 46L,
  nrow(landings) == 46L,
  nrow(total_catch) == 46L,
  nrow(fbar) == 46L,
  recruitment$value[recruitment$year == 2025] == 157581,
  recruitment$lwr[recruitment$year == 2025] == 74788,
  recruitment$upr[recruitment$year == 2025] == 332030,
  ssb$value[ssb$year == 2025] == 11298,
  ssb$lwr[ssb$year == 2025] == 6024,
  ssb$upr[ssb$year == 2025] == 21190,
  biomass$value[biomass$year == 2025] == 28932.34,
  fbar$value[fbar$year == 2025] == 0.342,
  fbar$age_group[fbar$year == 2025] == "2-4",
  total_catch$value[total_catch$year == 2025] == 5359,
  landings$value[landings$year == 2025] == 5359,
  all(is.na(total_catch$lwr)),
  all(is.na(landings$lwr)),
  all(recruitment$lwr < recruitment$value & recruitment$value < recruitment$upr),
  all(ssb$lwr < ssb$value & ssb$value < ssb$upr),
  all(biomass$lwr < biomass$value & biomass$value < biomass$upr),
  all(fbar$lwr < fbar$value & fbar$value < fbar$upr)
)

database <- file.path(root, "database")
stocks <- utils::read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- utils::read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- utils::read.csv(file.path(root, "discovery", "candidates.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- utils::read.csv(file.path(root, "discovery", "selected_batch_01_2026.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- utils::read.csv(file.path(root, "discovery", "inventory_units.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines(file.path(root, "discovery", "source_reviews", "ices_irish_sea_herring_2026.md"),
  warn = FALSE), collapse = "\n")
stopifnot(
  sum(stocks$stock_id == stock_id, na.rm = TRUE) == 1L,
  sum(assessments$assessment_id == assessment_id, na.rm = TRUE) == 1L,
  candidates$import_status[candidates$candidate_id == "ICES:her.27.nirs"] == "partial",
  selected$curation_status[selected$candidate_id == "ICES:her.27.nirs"] == "partial_source_import",
  inventory$import_status[inventory$unit_key == paste0("candidate:", stock_id)] == "partial",
  grepl("1,747 input rows, 18 assumption records and 276 output rows", review, fixed = TRUE),
  grepl("Fitted N-at-age and F-at-age are unavailable", review, fixed = TRUE)
)

cat("ICES 2026 Irish Sea herring source import, coverage, units, and official-output checks passed.\n")
