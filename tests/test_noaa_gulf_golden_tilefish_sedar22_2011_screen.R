read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "bytes")
  matches <- system2("rg", c("--color", "never", "--no-heading", "--no-line-number",
    "-F", assessment_id, path), stdout = TRUE, stderr = FALSE)
  status <- attr(matches, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) matches <- character() else if (status != 0L)
    stop("Could not read tilefish assessment rows.")
  matches <- matches[startsWith(matches, paste0('"', assessment_id, '",'))]
  read.csv(text = paste(c(header, matches), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}

candidate_id <- "NOAA:10383"
stock_id <- "noaa_gulf_golden_tilefish"
assessment_id <- paste0(stock_id, "_2011")
register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- stocks[stocks$authority == "NOAA Fisheries" & stocks$authority_stock_id == "10383", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
unit <- units[units$unit_key == paste0("stock:", stock_id), , drop = FALSE]
review <- paste(readLines("discovery/source_reviews/noaa_golden_tilefish_gulf_sedar22_2011.md",
  warn = FALSE), collapse = " ")
screen_code <- paste(readLines("scripts/database/482_screen_noaa_gulf_golden_tilefish_sedar22_2011.R",
  warn = FALSE), collapse = " ")

imported <- nrow(stock) == 1L || nrow(assessment) == 1L || nrow(inputs) > 0L || nrow(outputs) > 0L
if (!imported) {
  old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
  Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
  screen <- new.env(parent = globalenv())
  source("scripts/database/482_screen_noaa_gulf_golden_tilefish_sedar22_2011.R", local = screen)
  if (is.na(old_dry_run)) Sys.unsetenv("TAM_SOURCE_DRY_RUN") else
    Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
  register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == "10383",
  candidate$scientific_name == "Lopholatilus chamaeleonticeps",
  candidate$stock_name == "Tilefish - Gulf of Mexico",
  candidate$inventory_assessment_year == "2011",
  candidate$candidate_unit_id == stock_id,
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  grepl("conditional on 2-cm length bin", candidate$catch_age_evidence, fixed = TRUE),
  grepl("ages 2-30+", candidate$catch_age_evidence, fixed = TRUE),
  grepl("status determinations only", candidate$notes, fixed = TRUE),
  grepl("Table 3.7", candidate$output_evidence, fixed = TRUE),
  grepl("OFL/ABC", candidate$notes, fixed = TRUE),
  grepl("Gulf SSC concluded", review, fixed = TRUE),
  grepl("2026 Gulf data-triage", review, fixed = TRUE),
  grepl("candidate_unit_id <- 'noaa_gulf_golden_tilefish'", screen_code, fixed = TRUE)
)
state_checks <- if (imported) c(
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(stock) == 1L,
  nrow(assessment) == 1L,
  nrow(inputs) == 36719L,
  nrow(outputs) == 322L,
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial"
) else c(
  candidate$match_status == "new",
  candidate$import_status == "not_started",
  nrow(unit) == 1L,
  unit$match_status == "new",
  unit$screening_status == "screened",
  unit$eligibility == "eligible",
  unit$inventory_entries == 1L
)
stopifnot(all(state_checks))

cat("NOAA Gulf golden tilefish stock identity, source screen, advice caveat and selected-unit status passed.\n")
