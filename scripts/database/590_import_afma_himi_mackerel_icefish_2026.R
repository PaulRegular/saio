assessment_id <- "afma_himi_mackerel_icefish_2026"
stock_id <- "afma_himi_mackerel_icefish"
candidate_id <- "AFMA:HIMI_ICEFISH"
assessment_url <- "https://www.afma.gov.au/sites/default/files/2026-11/Mackerel%20Icefish%20stock%20assessment%202026.pdf"
fishery_url <- "https://www.afma.gov.au/fisheries/heard-island-and-mcdonald-islands-fishery"
source_file <- "discovery_afma_himi_2026/himi_mackerel_icefish_2026.pdf"
source_path <- file.path("source_cache", source_file)
source_hash <- "17FF6A46D444A633C4BEE736694C56E524B59899A32AA7498EBA6414591DE955"
manifest_path <- "provenance/afma_himi_mackerel_icefish_2026_sources.csv"

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.")
}
if (!file.exists(source_path)) {
  stop("The cached 2026 AFMA report is required before importing this record.")
}
if (!identical(toupper(unname(tools::sha256sum(source_path))), source_hash)) {
  stop("The cached 2026 AFMA report does not match its recorded SHA-256 checksum.")
}
if (file.exists(manifest_path)) {
  stop("The provenance manifest already exists; review the existing import before rerunning.")
}

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

append_rows <- function(path, rows) {
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    final_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(final_byte, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  rows[] <- lapply(rows, as.character)
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

replace_row <- function(path, key, value, replacement) {
  lines <- readLines(path, warn = FALSE)
  if (!key %in% names(replacement)) {
    stop("The replacement row does not contain key column ", key, ".")
  }
  prefix <- paste0('"', value, '",')
  indices <- which(startsWith(lines, prefix))
  if (!length(indices)) {
    indices <- which(grepl(paste0(',"', value, '",'), lines, fixed = TRUE))
  }
  if (length(indices) != 1L) {
    stop("Could not locate one unique row for ", value, " in ", path, ".")
  }
  temporary <- tempfile()
  write.table(replacement, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "")
  lines[indices] <- readLines(temporary, warn = FALSE)
  unlink(temporary)
  writeLines(lines, path, useBytes = TRUE)
}

stock_table <- read_table("database/stocks.csv")
assessment_table <- read_table("database/assessments.csv")
candidates <- read_table("discovery/candidates.csv")
selected <- read_table("discovery/selected_batch_07_2026.csv")
candidate_rows <- which(candidates$candidate_id == candidate_id)
selected_rows <- which(selected$candidate_id == candidate_id)
stopifnot(
  !stock_id %in% stock_table$stock_id,
  !assessment_id %in% assessment_table$assessment_id,
  length(candidate_rows) == 1L,
  candidates$eligibility[candidate_rows] == "unresolved",
  candidates$import_status[candidate_rows] == "not_started",
  length(selected_rows) == 1L,
  selected$curation_status[selected_rows] == "selected_for_partial_source_curation"
)

source_manifest <- data.frame(
  local_file = source_file,
  source_url = assessment_url,
  retrieved_on = "2026-11-06",
  sha256 = source_hash,
  stringsAsFactors = FALSE
)
write.csv(source_manifest, manifest_path, row.names = FALSE, na = "")

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "AFMA",
  authority_stock_id = "CCAMLR Division 58.5.2 (HIMI mackerel icefish)",
  scientific_name = "Champsocephalus gunnari",
  common_name = "Mackerel icefish at Heard Island and McDonald Islands",
  area = "Heard Island and McDonald Islands (HIMI), CCAMLR Division 58.5.2",
  region = "Heard Island and McDonald Islands",
  ocean = "Southern Indian Ocean",
  notes = paste(
    "Current AFMA-managed HIMI unit for mackerel icefish in CCAMLR Division 58.5.2.",
    "Distinct from HIMI Patagonian toothfish and the Macquarie Island toothfish unit."
  ),
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = "2026",
  terminal_year = "2026",
  estimate_terminal_year = "2026",
  assessment_type = "survey-based yield assessment",
  model_family = "CMIX/Grym",
  model_version = "2026 RSTS assessment; CMIX cohort mixture and Grym yield projection",
  is_current = "TRUE",
  is_applied = "TRUE",
  framework_year = NA_character_,
  assessment_url = assessment_url,
  framework_url = NA_character_,
  data_url = NA_character_,
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "AFMA lists the report as the final assessment with TAC recommendations for 2026/27 and 2027/28;",
    "the report title calls it a preliminary assessment. It uses the March 2026 RSTS, CMIX estimates,",
    "and Grym projections. Imported inputs and outputs are limited to published tables; raw length-density",
    "data, full historical catches, and annual population trajectories were not located."
  ),
  stringsAsFactors = FALSE
)

input_row <- function(type, measure, basis, value, unit, source_reference, notes,
                      year = NA_character_, year_basis = NA_character_,
                      age = NA_character_, fleet = NA_character_,
                      survey = NA_character_, region = NA_character_,
                      season = NA_character_, sampling_time = NA_character_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = NA_character_, region = region,
    season = season, year = year, year_basis = year_basis, age = age,
    value = value, unit = unit, sampling_time = sampling_time,
    source_type = "official_table", source_reference = source_reference,
    transformation = NA_character_, notes = notes, observation_id = NA_character_,
    length_bin = NA_character_, length_bin_lower = NA_character_,
    length_bin_upper = NA_character_, sample_size = NA_character_,
    age_error = NA_character_, partition = NA_character_,
    stringsAsFactors = FALSE
  )
}

output_row <- function(type, measure, value, unit, source_reference, notes,
                       year = "2026", age = NA_character_, age_group = NA_character_,
                       survey = NA_character_, region = NA_character_,
                       season = NA_character_, se = NA_character_,
                       lwr = NA_character_, upr = NA_character_,
                       scenario = NA_character_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = survey, sex = NA_character_, region = region,
    season = season, year = year, age = age, age_group = age_group,
    value = value, se = se, lwr = lwr, upr = upr, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = scenario, stringsAsFactors = FALSE
  )
}

assumption_row <- function(component, setting, value, source_reference, notes,
                            survey = NA_character_, region = NA_character_) {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = NA_character_,
    survey = survey, sex = NA_character_, region = region, season = NA_character_,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}

survey <- "Heard Island and McDonald Islands random stratified trawl survey (RSTS)"
pool <- "Pooled survey area"
cohort_ages <- 1:4
cohort_density <- c(29, 185, 273, 612)
cohort_density_sd <- c(14, 37, 1467, 252)
cohort_weight <- c(0.022, 0.103, 0.218, 0.297)
biomass_share <- c(0.25, 7.30, 22.78, 69.67)
cohort_labels <- paste0(cohort_ages, "+")

input_rows <- c(
  lapply(seq_along(cohort_ages), function(i) {
    input_row(
      type = "index", measure = "numbers_at_age", basis = "numbers",
      value = cohort_density[i], unit = "fish/km2",
      source_reference = "Maschette and Ziegler (2026), Table 1, PDF p. 5",
      notes = paste0(
        "CMIX-estimated density for cohort ", cohort_labels[i],
        "; this estimate is an input to the Grym yield calculation, not a raw age sample. ",
        "Table 1 reports SD = ", cohort_density_sd[i],
        " fish/km2 for this component; that reported SD is not stored as an SE."
      ),
      year = "2026", year_basis = "calendar_year", age = as.character(cohort_ages[i]),
      survey = survey, region = pool, season = "March"
    )
  }),
  list(
    input_row(
      type = "index", measure = "total_numbers", basis = "numbers", value = 1099,
      unit = "fish/km2",
      source_reference = "Maschette and Ziegler (2026), Table 2, PDF p. 5",
      notes = "Observed overall mean RSTS density for 2026, retained as a survey summary; raw haul-level values are not published in this report.",
      year = "2026", year_basis = "calendar_year", survey = survey,
      region = pool, season = "March"
    ),
    input_row(
      type = "catch", measure = "catch_biomass", basis = "biomass", value = 419,
      unit = "t",
      source_reference = "Maschette and Ziegler (2026), Table 6 discussion, PDF p. 8",
      notes = "Total mackerel icefish catch after the March 2026 survey. The report says 210 t from the 1+ to 3+ cohorts was used in the forward projections; age allocation for the full 419 t is not reported.",
      year = "2026", year_basis = "calendar_year", fleet = "HIMI mackerel icefish fishery",
      region = "CCAMLR Division 58.5.2", season = "Post-survey 2026"
    )
  ),
  lapply(seq_along(cohort_ages), function(i) {
    input_row(
      type = "weight", measure = "weight_at_age", basis = "kg_per_fish",
      value = cohort_weight[i], unit = "kg_per_fish",
      source_reference = "Maschette and Ziegler (2026), Table 4, PDF p. 8",
      notes = paste0(
        "Reported mean weight for cohort ", cohort_labels[i],
        "; the 4+ cohort is reported but excluded from forward projections."
      ),
      year = "2026", year_basis = "calendar_year", age = as.character(cohort_ages[i]),
      survey = survey, region = pool, season = "March"
    )
  }),
  lapply(1:3, function(age) {
    input_row(
      type = "maturity", measure = "maturity_at_age", basis = "proportion_numbers",
      value = 1, unit = "proportion",
      source_reference = "Maschette and Ziegler (2026), Maturity section, PDF p. 4",
      notes = "The assessment assumes all fish aged 1 to 3 are mature for the yield calculation; no age-4 maturity value is reported.",
      age = as.character(age), survey = survey, region = pool
    )
  }),
  lapply(1:3, function(age) {
    input_row(
      type = "M", measure = "natural_mortality_at_age", basis = "per_year",
      value = 0.4, unit = "year^-1",
      source_reference = "Maschette and Ziegler (2026), Natural mortality section, PDF p. 4",
      notes = "Fixed natural mortality used for the 1+ to 3+ projection cohorts; this value is not estimated.",
      age = as.character(age), survey = survey, region = pool
    )
  })
)
inputs <- do.call(rbind, input_rows)
assumptions <- do.call(rbind, list(
  assumption_row(
    "assessment", "assessment_method", "CMIX cohort mixture estimates followed by Grym yield projections.",
    "Maschette and Ziegler (2026), Assessment methods and Cohort structure, PDF pp. 3-4",
    "The model is a survey-based cohort and yield assessment, not an integrated annual age-structured population model.",
    survey = survey
  ),
  assumption_row(
    "observation", "survey_timing", "March 2026",
    "Maschette and Ziegler (2026), Abstract and Methods, PDF pp. 1-2",
    "The report does not give an exact sampling day or a within-year timing fraction.",
    survey = survey
  ),
  assumption_row(
    "biology", "weight_length_relationship", "W = 1.002e-9 * L^3.123",
    "Maschette and Ziegler (2026), Table 3, PDF p. 6",
    "2026 survey fit; W is weight in kg and L is length in mm. The report also gives 2025 coefficients, which are not substituted for the current fit.",
    survey = survey
  ),
  assumption_row(
    "biology", "length_at_age_growth_parameters", "Linf = 559.1 mm; K = 0.294 year^-1; t0 = 0.066 years",
    "Maschette and Ziegler (2026), Length-at-age section, PDF p. 4",
    "Von Bertalanffy growth parameters from the 2018-2024 survey period.",
    survey = survey
  ),
  assumption_row(
    "biology", "maturity_at_age", "All fish aged 1 to 3 are assumed mature.",
    "Maschette and Ziegler (2026), Maturity section, PDF p. 4",
    "The assessment does not report an age-4 maturity value."
  ),
  assumption_row(
    "mortality", "natural_mortality", "M = 0.4 year^-1, fixed",
    "Maschette and Ziegler (2026), Natural mortality section, PDF p. 4",
    "Natural mortality is assumed, not estimated."
  ),
  assumption_row(
    "projection", "cohorts_in_projection", "1+ to 3+",
    "Maschette and Ziegler (2026), Table 4 and projection text, PDF p. 8",
    "The assessment excludes the 4+ cohort from its forward projections."
  ),
  assumption_row(
    "projection", "initial_biomass", "987 t",
    "Maschette and Ziegler (2026), Table 6 discussion, PDF p. 8",
    "Calculated by applying the 30.33% biomass share of cohorts 1+ to 3+ to the pooled one-sided 95% biomass lower bound of 3,254 t."
  ),
  assumption_row(
    "projection", "post_survey_catch_in_projection", "210 t from cohorts 1+ to 3+",
    "Maschette and Ziegler (2026), Table 6 discussion, PDF p. 8",
    "The report also states total post-survey catch was 419 t; its full age allocation is not reported."
  ),
  assumption_row(
    "projection", "target_fishing_mortality", "0.1467 year^-1",
    "Maschette and Ziegler (2026), Table 6, PDF p. 8",
    "Target rate used to calculate recommended yields, not an estimated F-at-age output."
  ),
  assumption_row(
    "projection", "decision_rule", "75% escapement over a 2-year projection",
    "Maschette and Ziegler (2026), Assessment methods and Table 6, PDF pp. 3 and 8",
    "The yield calculation uses the CCAMLR decision rule and the 1+ to 3+ cohorts."
  )
))

regions <- c("Gunnari Ridge", "Plateau Southeast", "Plateau West", "Pooled survey area")
means <- c(2808, 945, 1044, 4797)
ses <- c(799, 317, 247, 994)
lowers <- c(1364, 422, 605, 2998)
uppers <- c(4381, 1629, 1517, 6845)
one_sided <- c(1577, 483, 670, 3254)

output_rows <- c(
  lapply(seq_along(cohort_ages), function(i) {
    output_row(
      type = "biomass", measure = "biomass_by_age_group", value = biomass_share[i],
      unit = "percent",
      source_reference = "Maschette and Ziegler (2026), Table 4, PDF p. 8",
      notes = "Reported percentage of survey biomass in this cohort; no uncertainty is reported.",
      age_group = cohort_labels[i], survey = survey, region = pool, season = "March"
    )
  }),
  lapply(seq_along(regions), function(i) {
    output_row(
      type = "index", measure = "total_biomass", value = means[i], unit = "t",
      source_reference = "Maschette and Ziegler (2026), Table 5, PDF p. 8",
      notes = paste0(
        "Bootstrapped RSTS biomass estimate for this stratum. Source lower one-sided 95% bound = ",
        one_sided[i], " t; the pooled bound is used to initialize the projection. This is survey biomass, not SSB."
      ),
      survey = survey, region = regions[i], season = "March", se = ses[i],
      lwr = lowers[i], upr = uppers[i]
    )
  }),
  list(
    output_row(
      type = "index", measure = "total_numbers", value = 1098, unit = "fish/km2",
      source_reference = "Maschette and Ziegler (2026), Table 2, PDF p. 5",
      notes = "CMIX expected overall density as printed in Table 2. Table 1 separately reports a sum of expected cohort densities of 1,099 fish/km2; both source values are retained because the report does not reconcile the 1 fish/km2 difference.",
      survey = survey, region = pool, season = "March"
    ),
    output_row(
      type = "index", measure = "sum_expected_cohort_density", value = 1099, unit = "fish/km2",
      source_reference = "Maschette and Ziegler (2026), Table 1, PDF p. 5",
      notes = "Sum of expected cohort densities as printed in Table 1. Table 2 reports expected overall density of 1,098 fish/km2; both source values are retained because the report does not reconcile the 1 fish/km2 difference.",
      survey = survey, region = pool, season = "March"
    ),
    output_row(
      type = "catch", measure = "catch_advice", value = 130, unit = "t",
      source_reference = "Maschette and Ziegler (2026), Recommendation and Table 6, PDF pp. 1 and 8",
      notes = "Recommended yield for the 2026/27 fishing year under the CCAMLR decision rule; the available report does not confirm final adoption as a TAC.",
      year = "2026", region = "CCAMLR Division 58.5.2", season = "2026/27"
    ),
    output_row(
      type = "catch", measure = "catch_advice", value = 112, unit = "t",
      source_reference = "Maschette and Ziegler (2026), Recommendation and Table 6, PDF pp. 1 and 8",
      notes = "Recommended yield for the 2027/28 fishing year under the CCAMLR decision rule; the available report does not confirm final adoption as a TAC.",
      year = "2027", region = "CCAMLR Division 58.5.2", season = "2027/28"
    )
  )
)
outputs <- do.call(rbind, output_rows)
append_rows("database/stocks.csv", stock)
append_rows("database/assessments.csv", assessment)
append_rows("database/assumptions.csv", assumptions)
append_rows("database/inputs.csv", inputs)
append_rows("database/outputs.csv", outputs)

candidates$import_status[candidate_rows] <- "partial"
candidates$decision_reason[candidate_rows] <- paste(
  "A partial canonical record was imported from the current 2026 assessment.",
  "Published CMIX cohort densities, weights, maturity, fixed M, survey biomass,",
  "and yield recommendations are recorded. tinyAM readiness remains unresolved",
  "because historical catch-at-age, raw survey vectors, and annual population trajectories are unavailable."
)
candidates$notes[candidate_rows] <- paste(
  "The 2026 report is the current source record; 2024 and 2025 survey rows are contextual only.",
  "See discovery/source_reviews/afma_himi_mackerel_icefish_2026.md."
)
replace_row("discovery/candidates.csv", "candidate_id", candidate_id,
  candidates[candidate_rows, , drop = FALSE])

selected$curation_status[selected_rows] <- "source_curated_partial"
replace_row("discovery/selected_batch_07_2026.csv", "candidate_id", candidate_id,
  selected[selected_rows, , drop = FALSE])

source("scripts/database/195_summarize_discovery.R", local = TRUE)
source("scripts/database/196_summarize_inventory_units.R", local = TRUE)

cat("Imported the partial AFMA HIMI mackerel icefish 2026 source record.\n")
cat("Historical catch-at-age and annual N/F population outputs remain unavailable; no tinyAM fit was attempted.\n")