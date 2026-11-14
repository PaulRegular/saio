assessment_id <- "afma_deepwater_flathead_gab_2023"
stock_id <- "afma_gab_deepwater_flathead"
candidate_id <- "AFMA:SESSF_GABTF_Deepwater_Flathead"
candidate_unit_id <- "afma_sessf_gab_deepwater_flathead"
report_url <- "https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-deepwater-flathead-2023.pdf"
summary_url <- "https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf"
report_path <- "source_cache/australia_afma_deepwater_flathead_2023/stock-assessment-for-deepwater-flathead-2023.pdf"
summary_path <- "source_cache/australia_afma_deepwater_flathead_2023/SESSF-Species-Summaries-2026.pdf"
source_paths <- c(report_path, summary_path)
source_urls <- c(report_url, summary_url)
source_hashes <- c(
  "B942DDCBE47F023337F6715435E5B795F6E13CD70A1AF792D16B15AB7C8C9A2C",
  "17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3"
)
retrieved_on <- "2026-11-06"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
region <- "Great Australian Bight"

if (!all(file.exists(source_paths))) {
  stop("Cache the reviewed AFMA report and current species summary first.", call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_paths)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached Deepwater Flathead source differs from the reviewed version.", call. = FALSE)
}

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0, check.names = FALSE))
  missing <- setdiff(header, names(rows))
  if (length(missing)) stop("Import rows lack columns: ", paste(missing, collapse = ", "), call. = FALSE)
  write.table(rows[header], path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", append = TRUE, qmethod = "double", eol = "\n")
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
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

if (stock_id %in% stocks$stock_id ||
    assessment_id %in% assessments$assessment_id ||
    candidate_id %in% candidates$candidate_id ||
    candidate_unit_id %in% candidates$candidate_unit_id ||
    assessment_rows_exist("database/assumptions.csv", assessment_id) ||
    assessment_rows_exist("database/inputs.csv", assessment_id) ||
    assessment_rows_exist("database/outputs.csv", assessment_id)) {
  stop("The Deepwater Flathead 2023 record is already present; refusing to duplicate it.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "AFMA",
  authority_stock_id = "Great Australian Bight (GAB) stock",
  scientific_name = "Neoplatycephalus conatus",
  common_name = "Deepwater flathead",
  area = "Great Australian Bight Trawl Sector, Southern and Eastern Scalefish and Shark Fishery",
  region = "Great Australian Bight, Australia",
  ocean = "Southern Ocean",
  notes = paste(
    "AFMA reports the assessment as a single stock in the Great Australian Bight.",
    "The Australian Hydrographic Office places the Great Australian Bight within",
    "the Southern Ocean:",
    "https://www.hydro.gov.au/factsheets/FS_Hydrographic_Surveying-Limits_of_oceans_and_seas_around_Aus.pdf"
  ),
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2023L,
  terminal_year = 2023L,
  estimate_terminal_year = 2024L,
  assessment_type = "full_assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.21.00",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = "",
  assessment_url = report_url,
  framework_url = "",
  data_url = report_url,
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "AFMA's 2026 SESSF species summary identifies this as a single-stock Tier 1",
    "assessment last assessed by GABRAG in November 2023. The detailed report",
    "describes a suggested/preliminary base case; GABRAG agreed to include Danish",
    "seine as a separate fleet for RBC advice. The 2023/24 catch repeated in the",
    "report is a projection assumption and is not imported as an observed catch."
  ),
  stringsAsFactors = FALSE
)

assumption_data <- data.frame(
  component = c(
    "population", "population", "population", "fleet", "index", "M", "recruitment",
    "recruitment", "biology", "biology", "biology", "ageing", "survey", "data"
  ),
  setting = c(
    "stock_structure", "model_structure", "model_years", "fleets",
    "abundance_indices", "natural_mortality", "steepness", "recruitment_variation",
    "sex_ratio", "maturity", "age_range", "age_reader_mapping",
    "observation_timing", "composition_data"
  ),
  value = c(
    "One stock across the Great Australian Bight.",
    "Two-sex age- and size-structured Stock Synthesis model; age 29 is the plus group; the stock was assumed unexploited before 1988/89.",
    "Annual financial years are labelled by their first year; model years run from 1988/89 through 2022/23.",
    "Trawl and Danish seine are separate fleets in the 2023 base case.",
    "Standardized trawl CPUE and GAB Fishery Independent Survey relative-biomass observations.",
    "M is estimated, constant over age and time, and equivalent for males and females; the base-case point estimate is 0.24 per year.",
    "Base-case steepness is fixed at 0.75.",
    "Recruitment variation sigma_R is fixed at 0.7; recruitment deviations were estimated for 1980–2016.",
    "Sex ratio is fixed at 0.5.",
    "Female maturity is logistic with 50% maturity at 40 cm total length; a numeric maturity-at-age vector is not reported.",
    "Ages 0–29, with age 29 as a plus group.",
    "Reader 2 is assigned to age samples from 2000 and 2002–2007; all other age-sampling years use Reader 1.",
    "The source describes annual financial years but does not report fractional within-year observation times.",
    "The model uses length compositions and conditional age-at-length data; their numeric vectors are not tabulated in the public report."
  ),
  source_reference = c(
    "AFMA 2026 SESSF Species Summaries, pp. 23–24; AFMA 2023 assessment, pp. 7–9",
    "AFMA 2023 assessment, pp. 7–9",
    "AFMA 2023 assessment, pp. 9, 11–12",
    "AFMA 2026 SESSF Species Summaries, p. 24; AFMA 2023 assessment, p. 7",
    "AFMA 2023 assessment, pp. 9, 11–13",
    "AFMA 2023 assessment, pp. 9, 34",
    "AFMA 2023 assessment, p. 9",
    "AFMA 2023 assessment, p. 9",
    "AFMA 2023 assessment, p. 9",
    "AFMA 2023 assessment, p. 8",
    "AFMA 2023 assessment, p. 9",
    "AFMA 2023 assessment, p. 13",
    "AFMA 2023 assessment, pp. 9, 11–15",
    "AFMA 2023 assessment, pp. 9–15"
  ),
  notes = c(
    "AFMA's current 2026 summary states the model treats the GAB unit as a single stock.",
    "Stock Synthesis 3.30.21.00. The public report does not include the native model files.",
    "Table year labels denote the first year of the financial year. The 2023/24 catch is repeated from 2022/23 only for projection and RBC calculations.",
    "Danish seine catch and associated composition samples were included separately from 2010 onward.",
    "The survey values are reported in tonnes as relative abundance estimates; they are not absolute population biomass.",
    "The point estimate 0.24 is shown in the base-case scenario label in Table 11; no uncertainty is provided.",
    "Steepness is an assumption, not an estimated output.",
    "The report does not provide annual numerical recruitment estimates.",
    "Both sexes share biological parameters except growth and length-weight relationships.",
    "Length-based maturity is not converted into an age schedule.",
    "The report's age range includes age 29+.",
    "Table 5 supplies Reader 1 and Reader 2 age-reading SD vectors. The year assignment is stated in the report prose.",
    "No fractional sampling time is inferred.",
    "Sample counts do not replace the missing composition vectors."
  ),
  stringsAsFactors = FALSE
)
assumptions <- data.frame(
  assessment_id = assessment_id,
  component = assumption_data$component,
  fleet = "",
  survey = "",
  sex = "",
  region = region,
  season = "",
  setting = assumption_data$setting,
  value = assumption_data$value,
  source_reference = assumption_data$source_reference,
  notes = assumption_data$notes,
  stringsAsFactors = FALSE
)

input_row <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = "", survey = "", year = NA_integer_, year_basis = "",
                      age = NA_real_, sex = "", observation_id = "", age_error = "",
                      sample_size = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = "",
    year = year, year_basis = if (is.na(year)) "" else year_basis, age = age,
    value = value, unit = unit, sampling_time = NA_real_, source_type = "official_table",
    source_reference = source_reference, transformation = "", notes = notes,
    observation_id = observation_id, length_bin = "", length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = sample_size, age_error = age_error,
    partition = "", stringsAsFactors = FALSE
  )
}

financial_years <- 1988:2022
trawl_catch <- c(
  312, 395, 420, 608, 508, 585, 1255, 1552, 1459, 1010, 681, 545, 777,
  964, 1866, 2482, 2264, 1546, 1030, 1025, 800, 851, 963, 849, 931, 800,
  537, 524, 643, 470, 431, 594, 559, 536, 565
)
danish_seine_catch <- c(rep(NA_real_, 22), 5, 125, 97, 87, 58, 92, 89, 68, 86, 99, 78, 143, 111)
trawl_cpue <- c(
  1.0354, 1.0428, 1.0228, 0.9856, 1.26, 1.7066, 2.0984, 2.013, 1.3392,
  0.9295, 0.7141, 0.849, 0.9252, 1.1124, 1.5347, 1.5293, 1.2076, 0.7694,
  0.7114, 0.7819, 0.9312, 0.8238, 1.0445, 0.8324, 0.8306, 0.7264, 0.6729,
  0.7501, 0.7942, 0.5974, 0.6124, 0.7452, 0.8289, 0.8501, 0.9248
)
stopifnot(length(financial_years) == length(trawl_catch),
  length(financial_years) == length(danish_seine_catch),
  length(financial_years) == length(trawl_cpue))

input_rows <- list()
for (i in seq_along(financial_years)) {
  yr <- financial_years[i]
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "catch", "landings_biomass", "biomass", trawl_catch[i], "tonnes",
    "AFMA 2023 assessment, Table 3, p. 12",
    "Annual financial-year trawl landings; year is the first year of the financial year. Discards are described as negligible. The repeated 2023/24 projection value is excluded.",
    fleet = "Trawl", year = yr, year_basis = "model_year",
    observation_id = paste0("TRAWL_CATCH_", yr)
  )
  if (!is.na(danish_seine_catch[i])) {
    input_rows[[length(input_rows) + 1L]] <- input_row(
      "catch", "landings_biomass", "biomass", danish_seine_catch[i], "tonnes",
      "AFMA 2023 assessment, Table 3, p. 12",
      "Annual financial-year Danish seine landings; year is the first year of the financial year. Discards are described as negligible.",
      fleet = "Danish seine", year = yr, year_basis = "model_year",
      observation_id = paste0("DANISH_SEINE_CATCH_", yr)
    )
  }
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "index", "relative_biomass_index", "index_scale", trawl_cpue[i],
    "source index units (not stated)",
    "AFMA 2023 assessment, Table 3, p. 12",
    "Standardized trawl CPUE. The report does not state the index unit; values are preserved on the reported scale.",
    fleet = "Trawl", year = yr, year_basis = "model_year",
    observation_id = paste0("TRAWL_CPUE_", yr)
  )
}

survey_years <- c(2004L, 2005L, 2006L, 2007L, 2008L, 2010L, 2014L, 2017L, 2020L)
survey_values <- c(12152, 8415, 8540, 7725, 9942, 9227, 5065, 3396, 5225)
survey_cv <- c(0.05, 0.06, 0.05, 0.06, 0.05, 0.05, 0.09, 0.06, 0.08)
survey_name <- "GAB Fishery Independent Survey (GABFIS)"
for (i in seq_along(survey_years)) {
  yr <- survey_years[i]
  obs_id <- paste0("GABFIS_BIOMASS_", yr)
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "index", "relative_biomass_index", "index_scale", survey_values[i], "tonnes",
    "AFMA 2023 assessment, Table 4, p. 13",
    "Relative abundance estimate reported in tonnes. This is a relative index, not an absolute biomass observation.",
    survey = survey_name, year = yr, year_basis = "model_year",
    observation_id = obs_id
  )
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "index", "biomass_index_cv", "relative_scale", survey_cv[i], "ratio",
    "AFMA 2023 assessment, Table 4, p. 13",
    "The report labels these as original CVs and says they were re-estimated during model tuning; the values here are not asserted to be final fitted likelihood CVs.",
    survey = survey_name, year = yr, year_basis = "model_year",
    observation_id = obs_id
  )
}

reader1 <- c(
  0.229109, 0.229109, 0.260154, 0.290482, 0.320111, 0.349057, 0.377335, 0.404961, 0.43195, 0.458316,
  0.484074, 0.509238, 0.533822, 0.557839, 0.581301, 0.604223, 0.626616, 0.648492, 0.669864, 0.690743,
  0.71114, 0.731067, 0.750535, 0.769553, 0.788133, 0.806284, 0.824016, 0.84134, 0.858264, 0.874797
)
reader2 <- c(
  0.237189, 0.237189, 0.280433, 0.32021, 0.356797, 0.390449, 0.421403, 0.449875, 0.476064, 0.500152,
  0.522309, 0.542689, 0.561434, 0.578676, 0.594536, 0.609124, 0.622542, 0.634884, 0.646236, 0.656678,
  0.666282, 0.675116, 0.683242, 0.690716, 0.697591, 0.703914, 0.709731, 0.715081, 0.720002, 0.724528
)
for (reader in c("Reader 1", "Reader 2")) {
  values <- if (reader == "Reader 1") reader1 else reader2
  for (i in seq_along(values)) {
    input_rows[[length(input_rows) + 1L]] <- input_row(
      "biology", "ageing_error_sd", "age_error_sd", values[i], "years",
      "AFMA 2023 assessment, Table 5, p. 13",
      "Standard deviation of age-reading error; this vector is not a complete true-age-to-observed-age transition matrix.",
      age = i - 1L, age_error = reader,
      observation_id = paste0("AGE_ERROR_", gsub(" ", "_", reader))
    )
  }
}

sample_years <- 1987:2022
trawl_samples <- c(61, 290, 214, 146, NA, 50, 358, 178, 430, 287, 972, 1163,
  NA, 600, NA, 642, NA, 565, 326, 484, 650, 329, 465, 290, 367, 787, 528,
  519, 666, 879, 293, 775, 407, 789, 423, 774)
ds_samples <- rep(NA_real_, length(sample_years))
ds_samples[match(c(2016L, 2017L, 2022L), sample_years)] <- c(250, 439, 280)
fis_samples <- rep(NA_real_, length(sample_years))
fis_samples[match(c(2005L, 2008L, 2010L, 2014L), sample_years)] <- c(229, 225, 262, 225)
stopifnot(length(trawl_samples) == length(sample_years))

for (fleet_data in list(
  list(name = "Trawl", code = "TRAWL", values = trawl_samples),
  list(name = "Danish seine", code = "DS", values = ds_samples),
  list(name = "GAB Fishery Independent Survey (GABFIS)", code = "FIS", values = fis_samples)
)) {
  for (i in which(!is.na(fleet_data$values))) {
    yr <- sample_years[i]
    input_rows[[length(input_rows) + 1L]] <- input_row(
      "biology", "composition_sample_count", "numbers", fleet_data$values[i], "fish",
      "AFMA 2023 assessment, Table 6, p. 14",
      "Raw age-length otolith sample count. It is not an age-composition vector or an effective likelihood sample size.",
      fleet = fleet_data$name, year = yr, year_basis = "model_year",
      observation_id = paste0("AGE_LENGTH_SAMPLE_", fleet_data$code, "_", yr)
    )
  }
}
inputs <- do.call(rbind, input_rows)

output_row <- function(type, measure, value, unit, source_reference, notes,
                       year = NA_integer_, sex = "", scenario = "2023 base case") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = sex, region = region, season = "", year = year,
    age = "", age_group = "", value = value, se = NA_real_, lwr = NA_real_,
    upr = NA_real_, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario,
    stringsAsFactors = FALSE
  )
}
outputs <- rbind(
  output_row("biomass", "unfished_spawning_biomass", 9918, "tonnes",
    "AFMA 2023 assessment, Table 11, p. 34",
    "Base-case unfished female spawning biomass (SSB0). No uncertainty interval is reported.",
    sex = "female"),
  output_row("biomass", "spawning_biomass", 4413, "tonnes",
    "AFMA 2023 assessment, Table 11, p. 34",
    "Projected female spawning biomass at the start of 2024/25, assuming 2022/23 catch in 2023/24. No uncertainty interval is reported.",
    year = 2024L, sex = "female"),
  output_row("biomass", "SSB_ratio_to_B0", 0.44, "ratio",
    "AFMA 2023 assessment, Table 11, p. 34",
    "Projected SSB2024/SSB0, reported rounded to 0.44. No uncertainty interval is reported.",
    year = 2024L, sex = "female"),
  output_row("mortality", "natural_mortality_average_parameter", 0.24, "per year",
    "AFMA 2023 assessment, Table 11, p. 34",
    "Estimated base-case M shown in the scenario label. It is constant over age and time and is a male/female-equivalent parameter; no uncertainty is reported."),
  output_row("catch", "catch_advice", c(1220, 1211, 1204, 1200), "tonnes",
    "AFMA 2023 assessment, Table 9, p. 23",
    "Projected Recommended Biological Catch under the 20:35:43 harvest control rule; this is advice, not observed catch.",
    year = 2024:2027)
)

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "AFMA",
  official_stock_id = "Great Australian Bight (GAB) stock",
  scientific_name = "Neoplatycephalus conatus",
  stock_name = "Deepwater flathead - Great Australian Bight",
  assessment_area = "Great Australian Bight Trawl Sector, Southern and Eastern Scalefish and Shark Fishery",
  inventory_assessment_year = 2023L,
  inventory_url = summary_url,
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "partial",
  catch_age_evidence = paste(
    "The latest detailed report supplies annual catch biomass and describes age-at-length data",
    "used in the model, but it does not publish catch numbers-at-age or numerical age-at-length",
    "composition vectors. Raw sample counts alone are insufficient to reconstruct them."
  ),
  survey_age_evidence = paste(
    "The model uses GABFIS relative-biomass observations and age-at-length samples;",
    "the report tabulates index values, original CVs, and sample counts, but not the",
    "age-composition vectors."
  ),
  weights_evidence = paste(
    "Length-weight coefficients are reported, but no age-specific weight surface or",
    "numeric growth-at-age table is available in the reviewed source."
  ),
  maturity_evidence = paste(
    "A female length-based logistic maturity ogive with 50% maturity at 40 cm TL is",
    "reported; no age-specific maturity vector is supplied."
  ),
  mortality_evidence = "The base case estimates age- and time-invariant M; the reported point estimate is 0.24 per year, without uncertainty.",
  timing_evidence = "Financial-year labels are available, but a fractional within-year timing for CPUE, GABFIS, or compositions is not reported.",
  output_evidence = paste(
    "The report provides SSB0, projected 2024/25 SSB, depletion, annual RBCs, and a",
    "base-case M point estimate. Annual numerical N/F/M/recruitment surfaces and",
    "their uncertainty were not found."
  ),
  detailed_source_url = paste(report_url, summary_url, sep = "; "),
  review_date = retrieved_on,
  decision_reason = paste(
    "The latest detailed production assessment located is the 2023 GABRAG model; AFMA's",
    "2026 summary identifies the stock as last assessed in November 2023. Import the",
    "recoverable source tables, but retain eligibility as unresolved because age-at-length",
    "composition vectors and age-specific biology are not publicly tabulated."
  ),
  notes = "Source review: source_reviews/afma_deepwater_flathead_gab_2023.md. Treat the assessment as one GAB stock; the model's trawl and Danish-seine fleets are not separate stocks.",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
candidate <- candidate[names(candidates)]

cat("Deepwater Flathead source record:", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions,", nrow(outputs), "outputs.\n")
cat("Eligibility: unresolved; import status: partial.\n")

if (write_mode) {
  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/assumptions.csv", assumptions)
  append_csv("database/inputs.csv", inputs)
  append_csv("database/outputs.csv", outputs)
  append_csv("discovery/candidates.csv", candidate)
  dir.create("provenance/afma_deepwater_flathead_gab_2023", recursive = TRUE, showWarnings = FALSE)
  manifest <- data.frame(
    local_file = sub("^source_cache/", "", source_paths),
    source_url = source_urls,
    retrieved_on = retrieved_on,
    sha256 = source_hashes,
    stringsAsFactors = FALSE
  )
  write.csv(manifest, "provenance/afma_deepwater_flathead_gab_2023/manifest.csv",
    row.names = FALSE, na = "")
  cat("Wrote the partial AFMA Deepwater Flathead source record and provenance manifest.\n")
} else {
  cat("Dry run only. Re-run with --write to update the database and candidate register.\n")
}
