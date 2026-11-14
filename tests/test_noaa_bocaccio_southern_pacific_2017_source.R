assessment_id <- "noaa_bocaccio_southern_pacific_2017"
candidate_id <- "NOAA:10413"
stock_id <- "noaa_bocaccio_southern_pacific_coast"
candidate_unit_id <- "noaa_bocaccio_southern_pacific_coast"

read_matching_rows <- function(path, id) {
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required for this source test.")
  lines <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(lines, "status")
  if (is.null(status)) status <- 0L
  if (status != 0L) stop("Could not locate imported rows in ", path, ".")
  prefix <- paste0('"', id, '",')
  lines <- lines[startsWith(lines, prefix)]
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, lines), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stocks <- read.csv("database/stocks.csv", colClasses = "character", check.names = FALSE)
assessments <- read.csv("database/assessments.csv", colClasses = "character", check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", colClasses = "character", check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", colClasses = "character", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
unit <- inventory[inventory$candidate_unit_id == candidate_unit_id, , drop = FALSE]
inputs <- read_matching_rows("database/inputs.csv", assessment_id)
outputs <- read_matching_rows("database/outputs.csv", assessment_id)
assumptions <- read_matching_rows("database/assumptions.csv", assessment_id)

stopifnot(
  nrow(stock) == 1L, stock$authority_stock_id == "10413",
  stock$scientific_name == "Sebastes paucispinis", stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$assessment_year == "2017",
  assessment$terminal_year == "2016", assessment$estimate_terminal_year == "2017",
  assessment$model_version == "3.24U", assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$import_status == "partial",
  candidate$matched_stock_id == stock_id, candidate$match_status == "matched",
  nrow(unit) == 1L, unit$import_status == "partial",
  unit$matched_stock_id == stock_id, unit$match_status == "matched",
  nrow(inputs) == 54326L, nrow(assumptions) == 10L, nrow(outputs) == 879L,
  sum(inputs$type == "catch" & inputs$measure == "catch_biomass") == 750L,
  sum(inputs$type == "index" & inputs$measure %in%
    c("relative_abundance_index", "relative_biomass_index")) == 232L,
  sum(inputs$measure == "log_index_sd") == 232L,
  sum(inputs$measure == "conditional_frequency_at_age") == 37928L,
  all(inputs$type[inputs$measure == "conditional_frequency_at_age"] == "biology"),
  sum(inputs$measure == "frequency_at_length") == 15096L,
  sum(inputs$measure == "age_error_mean_age") == 44L,
  sum(inputs$measure == "ageing_error_sd") == 44L,
  all(inputs$source_type == "native_model"),
  !any(inputs$measure == "numbers_at_age"),
  !any(inputs$measure == "index_by_age_group"),
  setequal(unique(inputs$age[inputs$measure == "conditional_frequency_at_age"]), 0:21),
  setequal(unique(inputs$length_bin[inputs$measure == "frequency_at_length"]), seq(10, 76, 2)),
  all(is.na(outputs$se[outputs$measure %in% c("spawning_output", "recruitment")])),
  sum(!is.na(outputs$lwr[outputs$measure == "spawning_output"])) == 11L,
  sum(!is.na(outputs$lwr[outputs$measure == "recruitment"])) == 11L,
  sum(!is.na(outputs$lwr[outputs$measure == "SSB_ratio_to_B0"])) == 11L,
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age")),
  all(outputs$source_type %in% c("official_table", "derived_source_output"))
)

spawn_2017 <- outputs[outputs$measure == "spawning_output" & outputs$year == 2017, , drop = FALSE]
recruit_2017 <- outputs[outputs$measure == "recruitment" & outputs$year == 2017, , drop = FALSE]
depletion_2017 <- outputs[outputs$measure == "SSB_ratio_to_B0" & outputs$year == 2017, , drop = FALSE]
stopifnot(
  nrow(spawn_2017) == 1L, spawn_2017$value == 3603,
  spawn_2017$lwr == 2066, spawn_2017$upr == 5139,
  spawn_2017$unit == "million larvae",
  nrow(recruit_2017) == 1L, recruit_2017$value == 6220,
  recruit_2017$lwr == 1194, recruit_2017$upr == 32412,
  nrow(depletion_2017) == 1L, depletion_2017$value == 0.486,
  depletion_2017$lwr == 0.331, depletion_2017$upr == 0.641
)

manifest <- read.csv("provenance/discovery_noaa_bocaccio_southern_pacific_2017/sources.csv",
  colClasses = "character", check.names = FALSE)
source_dir <- normalizePath("../../discovery_noaa_bocaccio_southern_pacific_2017")
for (i in seq_len(nrow(manifest))) {
  path <- file.path(source_dir, manifest$file[i])
  stopifnot(file.exists(path),
    identical(toupper(unname(tools::sha256sum(path))), toupper(manifest$sha256[i])))
}

cat("NOAA Southern Pacific Coast Bocaccio source coverage, published outputs, partial status, and provenance checks passed.\n")




