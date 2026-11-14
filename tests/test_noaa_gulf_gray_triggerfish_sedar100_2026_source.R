assessment_id <- "noaa_gulf_gray_triggerfish_sedar100_2026"
source("scripts/database/638_import_noaa_gulf_gray_triggerfish_sedar100_2026.R", local = TRUE)

stopifnot(
  nrow(new_inputs) == 645L,
  nrow(new_assumptions) == 11L,
  nrow(new_outputs) == 640L,
  sum(new_inputs$measure == "landings_biomass") == 217L,
  setequal(new_inputs$year[new_inputs$measure == "landings_biomass"], 1949:2024),
  sum(new_inputs$measure == "discard_numbers") == 75L,
  sum(new_inputs$measure == "discard_biomass") == 75L,
  sum(new_inputs$measure == "catch_se") == 150L,
  setequal(new_inputs$year[new_inputs$measure == "discard_numbers"], 2000:2024),
  sum(new_inputs$measure == "relative_abundance_index") == 64L,
  sum(new_inputs$measure == "abundance_index_cv") == 64L,
  !any(new_inputs$measure %in% c("numbers_at_age", "proportion_at_age",
    "frequency_at_age", "conditional_frequency_at_age"))
)

index <- new_inputs[new_inputs$measure == "relative_abundance_index", , drop = FALSE]
index_cv <- new_inputs[new_inputs$measure == "abundance_index_cv", , drop = FALSE]
series_years <- split(index$year, index$survey)
stopifnot(
  setequal(series_years[["SEAMAP Summer and Fall Groundfish - Old"]], 1987:2008),
  setequal(series_years[["SEAMAP Summer and Fall Groundfish - New"]], 2009:2024),
  setequal(series_years[["SEAMAP / G-FISHER Video"]], c(1993:1997, 2002, 2004:2023)),
  setequal(paste(index$survey, index$year), paste(index_cv$survey, index_cv$year)),
  all(index$unit == "relative index (series mean = 1)"),
  all(index_cv$unit == "ratio"),
  all(is.na(index$sampling_time)),
  all(new_inputs$value[new_inputs$measure == "catch_se"] >= 0),
  all(new_inputs$basis[new_inputs$measure == "catch_se" & new_inputs$unit == "fish standard error"] == "numbers"),
  all(new_inputs$basis[new_inputs$measure == "catch_se" & new_inputs$unit == "pounds standard error"] == "biomass")
)

m_assumption <- new_assumptions[new_assumptions$setting ==
  "assessment_process_recommended_M_at_age", , drop = FALSE]
stopifnot(nrow(m_assumption) == 1L,
  grepl("age 0=1.374", m_assumption$value, fixed = TRUE),
  grepl("not represented as the Review Panel", m_assumption$notes, fixed = TRUE))

biomass <- new_outputs[new_outputs$measure == "total_biomass", , drop = FALSE]
exploited_biomass <- new_outputs[new_outputs$measure == "biomass_by_age_group", , drop = FALSE]
ssb <- new_outputs[new_outputs$measure == "SSB", , drop = FALSE]
exploited_n <- new_outputs[new_outputs$measure == "total_numbers" &
  new_outputs$age_group == "1+", , drop = FALSE]
recruitment <- new_outputs[new_outputs$measure == "recruitment", , drop = FALSE]
ssb_ratio <- new_outputs[new_outputs$measure == "SSB_ratio_to_B0", , drop = FALSE]
total_n <- new_outputs[new_outputs$measure == "total_numbers" &
  new_outputs$age_group == "0+", , drop = FALSE]
exploitation <- new_outputs[new_outputs$measure == "exploitation_rate", , drop = FALSE]
stopifnot(
  all(vapply(list(biomass, exploited_biomass, ssb, exploited_n,
    recruitment, ssb_ratio, total_n, exploitation), nrow, integer(1)) == 80L),
  setequal(biomass$year, 1945:2024),
  biomass$value[biomass$year == 1945L] == 22514,
  ssb$value[ssb$year == 2024L] == 3644.39,
  recruitment$value[recruitment$year == 2024L] == 81839600,
  exploited_n$value[exploited_n$year == 2024L] == 20552700,
  total_n$value[total_n$year == 2024L] == 102392300,
  exploitation$value[exploitation$year == 2024L] == 0.2685,
  all(is.na(new_outputs$se) & is.na(new_outputs$lwr) & is.na(new_outputs$upr)),
  !any(new_outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age"))
)

read_imported_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  lines <- suppressWarnings(system2(Sys.which("rg"), c("--color", "never",
    "--no-heading", "--no-line-number", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(lines, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) lines <- character() else if (status != 0L) stop("Could not read ", path)
  lines <- lines[startsWith(lines, paste0("\"", assessment_id, "\","))]
  if (!length(lines)) return(read.csv(text = paste(header, collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE))
  read.csv(text = paste(c(header, lines), collapse = "\n"),
    stringsAsFactors = FALSE, colClasses = "character", na.strings = c("", "NA"),
    check.names = FALSE)
}

db_inputs <- read_imported_rows("inputs")
db_outputs <- read_imported_rows("outputs")
db_assumptions <- read_imported_rows("assumptions")
stopifnot(nrow(db_inputs) == 974L, nrow(db_outputs) == 640L,
  nrow(db_assumptions) == 11L,
  sum(db_inputs$measure == "composition_sample_count") == 329L,
  sum(db_inputs$measure == "catch_se") == 150L,
  db_inputs$value[db_inputs$measure == "landings_biomass" &
    db_inputs$year == "1949" & db_inputs$region == "East" &
    db_inputs$fleet == "Commercial handline+"] == "14300",
  db_inputs$value[db_inputs$measure == "catch_se" &
    db_inputs$year == "2000" & db_inputs$region == "East" &
    db_inputs$unit == "fish standard error"] == "150",
  db_outputs$value[db_outputs$measure == "SSB" & db_outputs$year == "2024"] == "3644.39",
  db_outputs$value[db_outputs$measure == "total_numbers" &
    db_outputs$age_group == "0+" & db_outputs$year == "2024"] == "102392300")

stock <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
batch <- read.csv("discovery/selected_batch_23_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- stock[stock$stock_id == "noaa_gulf_gray_triggerfish", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10062", , drop = FALSE]
selected <- batch[batch$candidate_id == "NOAA:10062", , drop = FALSE]
stopifnot(nrow(stock) == 1L, stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L, assessment$terminal_year == 2024L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  assessment$is_applied == FALSE,
  nrow(candidate) == 1L, candidate$matched_stock_id == stock$stock_id,
  candidate$import_status == "partial",
  nrow(selected) == 1L, selected$curation_status == "imported_partial")

cat("NOAA Gulf gray triggerfish SEDAR 100 source checks passed.\n")
