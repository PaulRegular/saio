env <- new.env(parent = globalenv())
source("scripts/database/639_import_noaa_goa_dusky_rockfish_2024.R", local = env)

inputs <- env$new_inputs
outputs <- env$new_outputs
assessment_id <- "noaa_goa_dusky_rockfish_2024"

stopifnot(
  nrow(inputs) == 916L,
  nrow(env$new_assumptions) == 9L,
  nrow(outputs) == 384L,
  sum(inputs$measure == "catch_biomass") == 47L,
  !1987L %in% inputs$year[inputs$measure == "catch_biomass"],
  inputs$value[inputs$measure == "catch_biomass" & inputs$year == 2024L] == 2176,
  sum(inputs$measure == "proportion_at_age" & inputs$type == "catch") == 405L,
  sum(inputs$measure == "proportion_at_age" & inputs$type == "index") == 432L
)

composition <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
fishery <- composition[composition$type == "catch", , drop = FALSE]
survey <- composition[composition$type == "index", , drop = FALSE]
fishery_sums <- aggregate(value ~ year, fishery, sum)
survey_sums <- aggregate(value ~ year, survey, sum)
stopifnot(
  max(abs(fishery_sums$value - 1)) <= 0.01,
  max(abs(survey_sums$value - 1)) <= 0.01,
  fishery$value[fishery$year == 2000L & fishery$age == 12L] == 0.141,
  survey$value[survey$year == 1990L & survey$age == 4L] == 0.007,
  all(fishery$sample_size[fishery$year == 2000L] == 411),
  any(grepl("age 30 denotes the 30+ group", composition$notes, fixed = TRUE))
)

index <- inputs[inputs$measure == "total_biomass" & inputs$type == "index", , drop = FALSE]
index_se <- inputs[inputs$measure == "index_sd", , drop = FALSE]
index_2023 <- index[index$year == 2023L, , drop = FALSE]
index_se_2023 <- index_se[index_se$year == 2023L, , drop = FALSE]
stopifnot(
  nrow(index) == 16L,
  nrow(index_se) == 16L,
  index_2023$value == 58538,
  index_se_2023$value == 10558,
  grepl("confidence level", index_2023$notes, fixed = TRUE),
  is.na(index_2023$sampling_time)
)

mle_2024 <- outputs[outputs$scenario == "m22.5a MLE" & outputs$year == 2024L, , drop = FALSE]
mcmc_2024 <- outputs[outputs$scenario == "m22.5a MCMC" & outputs$year == 2024L, , drop = FALSE]
stopifnot(
  nrow(mle_2024) == 4L,
  mle_2024$value[mle_2024$measure == "SSB"] == 37407,
  mle_2024$value[mle_2024$measure == "total_biomass"] == 88136,
  mle_2024$value[mle_2024$measure == "recruitment"] == 2.84,
  mle_2024$unit[mle_2024$measure == "recruitment"] == "million fish",
  mcmc_2024$value[mcmc_2024$measure == "recruitment"] == 3800,
  mcmc_2024$lwr[mcmc_2024$measure == "recruitment"] == 429,
  mcmc_2024$upr[mcmc_2024$measure == "recruitment"] == 14871,
  mcmc_2024$unit[mcmc_2024$measure == "recruitment"] == "thousand fish",
  all(is.na(outputs$se)),
  !any(outputs$year > 2024L)
)

read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- suppressWarnings(system2(Sys.which("rg"), c("--color", "never",
    "--no-heading", "--no-line-number", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character() else if (status != 0L) stop("Could not read ", path)
  rows <- rows[startsWith(rows, paste0("\"", assessment_id, "\","))]
  if (!length(rows)) return(read.csv(text = paste(header, collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

db_inputs <- read_assessment_rows("inputs")
db_outputs <- read_assessment_rows("outputs")
db_assessments <- read_assessment_rows("assessments")
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
candidate <- candidate[candidate$candidate_id == "NOAA:10559", , drop = FALSE]
batch <- read.csv("discovery/selected_batch_27_2026.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
batch <- batch[batch$candidate_id == "NOAA:10559", , drop = FALSE]
stock <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
stock <- stock[stock$stock_id == "noaa_goa_dusky_rockfish", , drop = FALSE]

stopifnot(
  nrow(db_inputs) == 916L,
  nrow(db_outputs) == 384L,
  nrow(db_assessments) == 1L,
  db_assessments$terminal_year == 2024L,
  db_assessments$is_applied,
  db_assessments$inputs_status == "partial",
  db_assessments$outputs_status == "partial",
  nrow(stock) == 1L,
  stock$ocean == "Northeast Pacific",
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "noaa_goa_dusky_rockfish",
  candidate$import_status == "partial",
  nrow(batch) == 1L,
  batch$curation_status == "imported_partial"
)

cat("NOAA GOA dusky rockfish 2024 source checks passed.\n")
