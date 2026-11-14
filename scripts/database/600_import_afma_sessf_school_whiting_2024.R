root <- "."
retrieved_on <- "2026-11-07"
candidate_id <- "AFMA:SESSF_Eastern_School_Whiting"
stock_id <- "afma_sessf_eastern_school_whiting"
assessment_id <- "afma_sessf_eastern_school_whiting_2024"
summary_url <- "https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf"
summary_path <- file.path(root, "source_cache/afma_school_whiting/afma_sessf_species_summaries_2026.pdf")
expected_hash <- "17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3"
minutes_path <- file.path(root, "source_cache/afma_school_whiting/serag_meeting_2_2024_minutes.pdf")
minutes_hash <- "EB9C933DAF8FED12BF7EB17820F3B9B72590F70AE1B94B60FEA3AE3F86C1D26C"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(summary_path) ||
    toupper(unname(tools::sha256sum(summary_path))) != expected_hash) {
  stop("The cached AFMA 2026 summary differs from the reviewed source.", call. = FALSE)
}
if (!file.exists(minutes_path) ||
    toupper(unname(tools::sha256sum(minutes_path))) != minutes_hash) {
  stop("The cached AFMA SERAG 2024 minutes differ from the reviewed source.", call. = FALSE)
}

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))

read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))

source(file.path(root, "scripts/database/candidate_register_io.R"), local = TRUE)

blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in intersect(names(values), fields)) {
    value <- values[[name]]
    row[[name]] <- if (length(value) == 0L || is.na(value[1L])) "" else as.character(value[1L])
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}

append_csv <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  fields <- read_fields(path)
  missing <- setdiff(fields, names(rows))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  utils::write.table(rows[fields], path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "\n")
}

assessment_rows_exist <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  prefix <- paste0('"', id, '"')
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}

database <- file.path(root, "database")
stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
candidates_path <- file.path(root, "discovery/candidates.csv")

stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates <- read_csv(candidates_path)
candidate_row <- which(candidates$candidate_id == candidate_id)

if (length(candidate_row) != 1L ||
    candidates$scientific_name[candidate_row] != "Sillago flindersi" ||
    candidates$screening_status[candidate_row] != "screened" ||
    candidates$eligibility[candidate_row] != "unresolved" ||
    candidates$import_status[candidate_row] != "not_started" ||
    any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id) ||
    any(stocks$scientific_name == "Sillago flindersi") ||
    any(vapply(c(assumptions_path, inputs_path, outputs_path), assessment_rows_exist,
      logical(1), id = assessment_id))) {
  stop("The candidate or canonical record state differs from this reviewed import.", call. = FALSE)
}

region <- "Southeastern Australia"
stock <- blank_row(read_fields(stocks_path), list(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "AFMA",
  authority_stock_id = "SESSF School Whiting (WHS)",
  scientific_name = "Sillago flindersi",
  common_name = "Eastern school whiting",
  area = "SESSF zones 10-60 and 91; western Victoria around Tasmania to southern Queensland",
  region = region,
  ocean = "Southwest Pacific and Southern Ocean",
  notes = "AFMA reports one eastern school whiting stock shared across Commonwealth and NSW waters. The summary notes some evidence of east-coast Tasmanian separation but low catches in zone 30."
))

assessment <- blank_row(read_fields(assessments_path), list(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2024L,
  terminal_year = 2023L,
  estimate_terminal_year = 2025L,
  assessment_type = "Tier 1 full assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.22.01",
  is_current = TRUE,
  is_applied = TRUE,
  assessment_url = summary_url,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "AFMA's 2026 species summary identifies the 2024 combined assessment as the current Tier 1 run, with data through 2023. The November 2024 SERAG minutes provide exact combined-model SSB0 and projected SSB2025 estimates. The detailed 2024 technical report and numerical input arrays were not located. This partial record preserves verified source-reported assumptions and outputs only."
))

assumption_fields <- read_fields(assumptions_path)
assumption <- function(component, setting, value, source_reference, notes = "", fleet = "") {
  blank_row(assumption_fields, list(
    assessment_id = assessment_id, component = component, fleet = fleet,
    region = region, setting = setting, value = value,
    source_reference = source_reference, notes = notes
  ))
}

assumptions <- do.call(rbind, list(
  assumption("assessment", "assessment_period", "2024 production assessment; observations through 2023", "AFMA 2026 SESSF Species Summaries, School Whiting, pp. 101, 103"),
  assumption("assessment", "model_family_and_version", "Age- and size-structured Stock Synthesis 3.30.22.01", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("population", "stock_structure", "One eastern school whiting stock across SESSF zones 10-60 and 91, from western Victoria around Tasmania to southern Queensland", "AFMA 2026 SESSF Species Summaries, School Whiting, pp. 101, 103-104", "The summary notes evidence of possible separation around eastern Tasmania but low zone-30 catches."),
  assumption("population", "initial_population_state", "Assumed unexploited at the start of 1942", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("population", "plus_group_age", "9 years", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("recruitment", "stock_recruitment_relationship", "Beverton-Holt", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("recruitment", "steepness", "0.75 (pre-specified)", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("recruitment", "annual_recruitment_process_error", "sigma_R = 0.7", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", "The summary does not specify a separate scale or prior."),
  assumption("growth", "growth_model", "von Bertalanffy; estimated within the assessment", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", "The summary's wording about sex treatment is ambiguous; no sex-specific growth values are inferred."),
  assumption("M", "natural_mortality", "0.6 per year (pre-specified)", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("biology", "maximum_modelled_length", "30 cm in the 2024 assessment; increased from 25 cm in the 2020 assessment", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103"),
  assumption("discard", "time_blocked_discarding", "Commonwealth vessels; 2017-2019", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 104", "The summary attributes the block to increased observed discarding."),
  assumption("fleet", "modelled_years", "1947-2023", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", fleet = "Victorian Danish seine"),
  assumption("fleet", "modelled_years", "1947-2023", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", fleet = "Commonwealth trawl"),
  assumption("fleet", "modelled_years", "1942-1994 and 2010-2023", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", fleet = "NSW Danish seine"),
  assumption("fleet", "modelled_years", "1942-2023", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", fleet = "NSW northern trawl"),
  assumption("fleet", "modelled_years", "1942-2023", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", fleet = "NSW prawn trawl"),
  assumption("fleet", "modelled_years", "1942-2023", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 103", fleet = "NSW southern trawl"),
  assumption("reference_point", "target_spawning_biomass", "48% of B0", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 101"),
  assumption("reference_point", "limit_spawning_biomass", "20% of B0", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 101"),
  assumption("index", "standardised_CPUE", "Separate standardised CPUE series for assessment fleets; regional trends could not all be fitted simultaneously", "AFMA 2026 SESSF Species Summaries, School Whiting, pp. 101, 104-105", "Numerical CPUE observations and their within-year timing were not published in the summary.")
))

output_fields <- read_fields(outputs_path)
output <- function(type, measure, value, unit, year, scenario, source_reference, notes) {
  blank_row(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    region = region, year = year, value = value, unit = unit,
    source_type = "official_document", source_reference = source_reference,
    scenario = scenario, notes = notes
  ))
}

outputs <- do.call(rbind, list(
  output("biomass", "unfished_spawning_biomass", 13207, "tonnes", NA_integer_,
    "2024 combined Tier 1 base case", "AFMA SERAG Meeting 2, November 2024, agenda item 3, p. 7",
    "The final combined assessment estimates SSB0 at 13,207 tonnes. The minutes report no uncertainty interval."),
  output("biomass", "SSB", 7110, "tonnes", 2025L,
    "2024 combined Tier 1 base case", "AFMA SERAG Meeting 2, November 2024, agenda item 3, p. 7",
    "Projected beginning-of-2025 spawning biomass, assuming 2024 catches equal 2023 catches. The minutes report no uncertainty interval."),
  output("biomass", "SSB_ratio_to_B0", 54, "percent", 2025L,
    "2024 combined Tier 1 base case", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 101",
    "AFMA reports 54% of B0 in year +1 for the 2024 assessment; year is recorded as 2025. No uncertainty is reported."),
  output("catch", "recommended_biological_catch", 3086, "tonnes", 2025L,
    "2025-26 season", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 105",
    "Recommended biological catch produced by the 2024 combined assessment; this is advice, not observed catch."),
  output("catch", "recommended_biological_catch", 2961, "tonnes", 2026L,
    "2026-27 season", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 105",
    "Recommended biological catch produced by the 2024 combined assessment; this is advice, not observed catch."),
  output("catch", "recommended_biological_catch", 3024, "tonnes", NA_integer_,
    "2025-26 and 2026-27 two-year average", "AFMA 2026 SESSF Species Summaries, School Whiting, p. 105",
    "Two-year average recommended biological catch from the 2024 combined assessment; no uncertainty is reported.")
))

candidate <- candidates[candidate_row, , drop = FALSE]
candidate$candidate_unit_id <- stock_id
candidate$import_status <- "partial"
candidate$catch_age_evidence <- paste(
  "The 2024 age- and size-structured assessment fitted aggregate length and conditional age-at-length data, but the numerical likelihood arrays were not located.",
  "The public 2020 assessment is a separate run and does not supply the 2024 inputs."
)
candidate$output_evidence <- paste(
  "AFMA's SERAG minutes report SSB0 = 13,207 t and projected SSB2025 = 7,110 t (53.8% of SSB0) for the 2024 combined assessment; the later AFMA summary rounds the ratio to 54%. No uncertainty is reported.",
  "The same summary reports recommended biological catches of 3,086 t for 2025-26 and 2,961 t for 2026-27 (two-year average 3,024 t)."
)
candidate$decision_reason <- paste(
  "A partial current-run source record is supported by AFMA's 2026 summary, which identifies the 2024 production model and reports its stock-status ratio, catch advice, and selected assumptions.",
  "Age-input eligibility remains unresolved because numerical catch, CPUE, composition, and biological input arrays were not located."
)
candidate$notes <- paste(
  "AFMA and NSW fisheries manage a shared eastern school whiting stock. The current partial record preserves only verified summary facts and outputs; it does not use the separate 2020 assessment to fill gaps.",
  "See source_reviews/afma_school_whiting_sessf.md."
)

cat("AFMA eastern school whiting: ", nrow(assumptions), " assumptions, ",
  nrow(outputs), " outputs; no numerical model-input arrays imported.\n", sep = "")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to update canonical data and the candidate register.\n")
} else {
  append_csv(stocks_path, stock)
  append_csv(assessments_path, assessment)
  append_csv(assumptions_path, assumptions)
  append_csv(outputs_path, outputs)
  replace_candidate_register_row(candidates_path, candidate_row, candidate, candidate_id)
  cat("Wrote the partial AFMA eastern school whiting source record.\n")
}
