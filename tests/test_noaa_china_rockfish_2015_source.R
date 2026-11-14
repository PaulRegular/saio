root <- "."
old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
import_env <- new.env(parent = globalenv())
sys.source(file.path(root, "scripts/database/670_import_noaa_china_rockfish_2015.R"), envir = import_env)
if (is.na(old_dry_run)) Sys.unsetenv("TAM_SOURCE_DRY_RUN") else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

ids <- c("noaa_china_rockfish_northern_pacific_coast", "noaa_china_rockfish_central_pacific_coast",
  "noaa_china_rockfish_southern_pacific_coast")
assessments <- import_env$assessments
inputs <- import_env$inputs
outputs <- import_env$outputs
assumptions <- import_env$assumptions
review <- paste(readLines(file.path(root, "discovery/source_reviews/noaa_china_rockfish_us_pacific_2015.md"),
  warn = FALSE), collapse = " ")
stock_table <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment_table <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
imported <- ids %in% stock_table$stock_id
assessment_ids <- paste0(ids, "_2015")
assessment_imported <- assessment_ids %in% assessment_table$assessment_id

stopifnot(
  nrow(import_env$stocks) == 3L,
  identical(import_env$stocks$stock_id, ids),
  all(import_env$stocks$scientific_name == "Sebastes nebulosus"),
  all(import_env$stocks$ocean == "Northeast Pacific"),
  all(assessments$assessment_year == 2015L),
  all(assessments$terminal_year == 2014L),
  all(assessments$estimate_terminal_year == 2015L),
  all(assessments$model_version == "3.24u"),
  all(assessments$assumptions_status == "partial" & assessments$inputs_status == "partial" & assessments$outputs_status == "partial"),
  nrow(assumptions) == 24L,
  all(assumptions$value[assumptions$setting == "natural_mortality"] == "0.07 per year, fixed"),
  nrow(inputs) == 2185L,
  setequal(as.character(table(inputs$assessment_id)), c("345", "575", "1265")),
  all(inputs$measure == "catch_biomass" & inputs$unit == "metric tons"),
  all(inputs$year %in% 1900:2014),
  !any(inputs$measure %in% c("catch_numbers_at_age", "catch_numbers")),
  nrow(outputs) == 2430L,
  all(table(outputs$assessment_id) == 810L),
  all(outputs$scenario[outputs$year == 2015] == "forecast"),
  all(is.na(outputs$se)),
  all(is.finite(inputs$value)),
  all(is.finite(outputs$value)),
  !anyNA(outputs$source_reference) && all(nzchar(outputs$source_reference)),
  outputs$value[outputs$assessment_id == assessment_ids[1] & outputs$measure == "total_biomass" & outputs$year == 2015] == 207.26,
  outputs$value[outputs$assessment_id == assessment_ids[2] & outputs$measure == "total_biomass" & outputs$year == 2015] == 496.73,
  outputs$value[outputs$assessment_id == assessment_ids[3] & outputs$measure == "total_biomass" & outputs$year == 2015] == 446.54,
  outputs$value[outputs$measure == "depletion" & outputs$year == 2015 & outputs$assessment_id == assessment_ids[1]] == 0.7344,
  outputs$lwr[outputs$measure == "depletion" & outputs$year == 2015 & outputs$assessment_id == assessment_ids[1]] == 0.6369,
  outputs$upr[outputs$measure == "depletion" & outputs$year == 2015 & outputs$assessment_id == assessment_ids[3]] == 0.3469,
  outputs$unit[outputs$measure == "spawning_output"] == "billion eggs",
  outputs$lwr[outputs$measure == "spawning_output" & outputs$assessment_id == assessment_ids[1]] == 8.8,
  all(imported == assessment_imported),
  all(import_env$candidate_updates$import_status == "partial"),
  all(import_env$candidate_updates$match_status == "matched"),
  all(import_env$inventory_updates$import_status == "partial"),
  grepl("latest full assessment", review, fixed = TRUE),
  grepl("do not provide annual N-at-age", review, fixed = TRUE)
)
if (all(imported)) {
  stopifnot(all(assessment_table$inputs_status[match(assessment_ids, assessment_table$assessment_id)] == "partial"))
} else {
  stopifnot(!any(imported), !any(assessment_imported))
}

cat("NOAA China rockfish 2015 source tables passed.\n")
