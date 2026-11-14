assessment_id <- "afma_blue_grenadier_cts_2025"
stock_id <- "afma_blue_grenadier_cts"
candidate_id <- "AFMA:SESSF_CTS_Blue_Grenadier"
summary_url <- "https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf"
serag_url <- "https://www.afma.gov.au/sites/default/files/2026-01/SERAG-1-Meeting-2025-minutes.pdf"
data_meeting_url <- "https://www.afma.gov.au/sites/default/files/2026-02/SESSFRAG-Data-meeting-2025-minutes.pdf"
source_reference <- "AFMA SESSF Blue Grenadier 2025 assessment"

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0, check.names = FALSE))
  rows <- rows[header]
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
              quote = TRUE, na = "", append = TRUE, qmethod = "double")
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

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)

if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id ||
    candidate_id %in% candidates$candidate_id ||
    assessment_rows_exist("database/assumptions.csv", assessment_id) ||
    assessment_rows_exist("database/inputs.csv", assessment_id) ||
    assessment_rows_exist("database/outputs.csv", assessment_id)) {
  stop("The Blue Grenadier 2025 source record is already present; refusing to duplicate it.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "AFMA",
  authority_stock_id = "Commonwealth Trawl Sector (CTS)",
  scientific_name = "Macruronus novaezelandiae",
  common_name = "Blue grenadier",
  area = "Commonwealth Trawl Sector, Southern and Eastern Scalefish and Shark Fishery",
  region = "Southern and eastern Australia",
  ocean = "Southwest Pacific and Southern Ocean",
  notes = "The 2025 assessment is for the Commonwealth Trawl Sector stock. The separate Great Australian Bight Trawl Sector biological stock is not part of this assessment.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2025,
  terminal_year = 2024,
  estimate_terminal_year = 2026,
  assessment_type = "update",
  model_family = "unknown",
  model_version = "",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = "",
  assessment_url = summary_url,
  framework_url = "",
  data_url = "",
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "The 2025 tuned Tier 1 base case was supported for RBC calculations and is identified as the latest assessment in the 2026 AFMA summary. Public current-run material reports selected biomass ratios and data-year coverage but provides no numerical input series or native assessment files. The detailed 2022 assessment is retained only as background and is not used to fill current-run gaps.",
  stringsAsFactors = FALSE
)

assumptions <- data.frame(
  assessment_id = assessment_id,
  component = c("population", "population", "observation_model", "index", "M", "biology", "survey"),
  fleet = "",
  survey = "",
  sex = "",
  region = "",
  season = "",
  setting = c("assessed_stock_structure", "model_family_and_version", "data_year_coverage", "acoustic_base_case_years", "natural_mortality", "weights_and_maturity", "survey_timing"),
  value = c(
    "The current assessment is for the Commonwealth Trawl Sector blue grenadier stock; the stock is assessed with spawning and non-spawning sub-fisheries.",
    "The current source summaries identify a tuned Tier 1 base case but do not state the software family or version. The 2022 detailed predecessor used Stock Synthesis 3.30.19.01; that version is not assigned to the 2025 run.",
    "Catch and age data through 2024; CPUE, discard mass, and length-composition data through 2023.",
    "Historical acoustic biomass estimates from 2003-2010 and modern estimates from 2020-2021 and 2023-2024; 2019 and 2022 are excluded from the base case.",
    "unknown",
    "unknown",
    "unknown"
  ),
  source_reference = c(
    paste(source_reference, "AFMA 2026 SESSF Species Summaries, Blue Grenadier section"),
    paste(source_reference, "AFMA SERAG 1 2025 minutes, Item 5; predecessor version from AFMA 2022 assessment report"),
    paste(source_reference, "AFMA SERAG 1 2025 minutes, Item 5"),
    paste(source_reference, "AFMA SESSFRAG Data Meeting 2025 minutes, Item 5, Recommendation 3"),
    paste(source_reference, "not specified in current-run sources"),
    paste(source_reference, "not specified in current-run sources"),
    paste(source_reference, "not specified in current-run sources")
  ),
  notes = c(
    "The 2023 Australian stock-status report distinguishes the Commonwealth Trawl Sector and Great Australian Bight Trawl Sector biological stocks; the latter is not assessed by this run.",
    "No 2025 technical report or model files were located. The previous model detail is not treated as proof that all settings or software version remained unchanged.",
    "These are source-reported final data years; the current report does not provide the underlying numerical arrays.",
    "The 2019 and 2022 acoustic estimates were judged unreliable because of survey timing and unstable aggregations. The recommendation specifies their exclusion from the 2025 base case.",
    "The available 2025 summary and meeting minutes do not report the current base-case M values or age/sex structure. Values from the 2022 run are not carried forward.",
    "Current-run weight-at-age and maturity inputs were not located; predecessor values are not substituted.",
    "A numeric within-year timing for current observations is not reported in the available 2025 materials."
  ),
  stringsAsFactors = FALSE
)

outputs <- data.frame(
  assessment_id = assessment_id,
  type = "biomass",
  measure = "spawning_biomass_ratio",
  fleet = "",
  survey = "",
  sex = "female",
  region = "Commonwealth Trawl Sector",
  season = "",
  year = c(2022, 2023, 2026),
  age = "",
  age_group = "",
  value = c(107, 112, 99.5),
  se = "",
  lwr = "",
  upr = "",
  unit = "percent of unfished female spawning biomass (B0)",
  source_type = c("official_table", "official_table", "official_document"),
  source_reference = c(
    "AFMA 2026 SESSF Species Summaries, p. 114, Blue Grenadier table",
    "AFMA 2026 SESSF Species Summaries, p. 114, Blue Grenadier table",
    "AFMA SERAG 1 2025 minutes, Item 5"
  ),
  notes = c(
    "Value in the current assessment column for the year after the 2021 assessment year; no uncertainty interval is reported.",
    "Value in the current assessment column for the year after the 2022 assessment year; no uncertainty interval is reported.",
    "Projected 2026 spawning biomass reported as 99.5% of virgin female spawning biomass; the 2026 species summary rounds this to 100%. No uncertainty interval is reported."
  ),
  scenario = "2025 tuned base case",
  stringsAsFactors = FALSE
)

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = "australia_sessf_cts_blue_grenadier",
  organization = "AFMA",
  official_stock_id = "Commonwealth Trawl Sector (CTS)",
  scientific_name = "Macruronus novaezelandiae",
  stock_name = "Blue grenadier - Commonwealth Trawl Sector",
  assessment_area = "Commonwealth Trawl Sector, Southern and Eastern Scalefish and Shark Fishery",
  inventory_assessment_year = 2025,
  inventory_url = summary_url,
  retrieved_on = "2026-11-05",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "partial",
  catch_age_evidence = "The 2025 assessment used catch and age data through 2024, but numerical catch and age inputs were not found in the public current-run sources.",
  survey_age_evidence = "The 2025 base case included acoustic biomass series, but no current numerical acoustic inputs or age-specific survey likelihood were found.",
  weights_evidence = "Current-run weight-at-age inputs were not reported in the available sources.",
  maturity_evidence = "Current-run maturity-at-age or maturity-at-length inputs were not reported in the available sources.",
  mortality_evidence = "Current-run natural-mortality values were not reported in the available sources.",
  timing_evidence = "The current-run sources do not report numeric within-year survey timing.",
  output_evidence = "AFMA reports 2025-run spawning-biomass ratios for 2022 and 2023, and a 2026 projection of 99.5% of virgin female spawning biomass; uncertainty and age-specific outputs are unavailable.",
  detailed_source_url = paste(summary_url, serag_url, data_meeting_url, sep = "; "),
  review_date = "2026-11-05",
  decision_reason = "The latest official 2025 Tier 1 assessment is confirmed and its reported biomass ratios are imported. Source eligibility remains unresolved because the public current-run sources do not contain the numerical input arrays or detailed model outputs needed to determine whether this unit meets the age-input screen.",
  notes = "The assessment covers the Commonwealth Trawl Sector stock, not the separate Great Australian Bight Trawl Sector stock. The prior detailed 2022 assessment is not substituted for missing 2025 data.",
  stringsAsFactors = FALSE
)

append_csv("database/stocks.csv", stock)
append_csv("database/assessments.csv", assessment)
append_csv("database/assumptions.csv", assumptions)
append_csv("database/outputs.csv", outputs)
append_csv("discovery/candidates.csv", candidate)

cat("Imported partial 2025 AFMA Blue Grenadier CTS assessment sources.\n")
