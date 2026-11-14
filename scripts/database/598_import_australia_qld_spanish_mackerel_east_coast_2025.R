root <- "."
cache <- file.path(root, "source_cache/australia_qld_spanish_mackerel_2025")
report_file <- file.path(cache, "east_coast_assessment_2025.pdf")
expected_hash <- "740DD3DEFB074560A9F406ACF1E029170294494D3975642261DE96A284CF458E"
report_url <- "https://era.dpi.qld.gov.au/id/eprint/14912/1/2025%20East%20coast%20Spanish%20mackerel%20stock%20assessment%20report%20Final%208.5.25.pdf"
retrieved_on <- "2026-11-07"
stock_id <- "australia_qld_spanish_mackerel_east_coast"
assessment_id <- "australia_qld_spanish_mackerel_east_coast_2025"
candidate_id <- "QLD:EAST_COAST_SPANISH_MACKEREL"
candidate_unit_id <- "australia_qld_spanish_mackerel_east_coast"
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- toupper(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result, value = TRUE)))
  if (length(hash) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hash
}
if (!file.exists(report_file) || !identical(sha256_file(report_file), expected_hash)) {
  stop("The cached official report differs from the reviewed source.", call. = FALSE)
}

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
make_rows <- function(fields, values, n) {
  z <- lapply(fields, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(z) <- fields
  as.data.frame(z, stringsAsFactors = FALSE, check.names = FALSE)
}
blank_row <- function(fields, values) make_rows(fields, values, 1L)
append_rows <- function(path, rows) {
  if (nrow(rows)) utils::write.table(rows, path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "\n")
}
first_column <- function(path) {
  fields <- read_fields(path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = c("character", rep("NULL", length(fields) - 1L)))[[1L]]
}

database <- file.path(root, "database")
stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates_path <- file.path(root, "discovery/candidates.csv")
selected_path <- file.path(root, "discovery/selected_batch_11_2026.csv")
candidates <- read_csv(candidates_path)
selected <- read_csv(selected_path)
ci <- which(candidates$candidate_id == candidate_id)
si <- which(selected$candidate_id == candidate_id)
if (length(ci) != 1L || length(si) != 1L ||
    candidates$candidate_unit_id[ci] != candidate_unit_id ||
    candidates$eligibility[ci] != "unresolved" ||
    any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id) ||
    any(stocks$scientific_name == "Scomberomorus commerson" &
      grepl("east coast|Queensland|New South Wales", paste(stocks$area, stocks$region), ignore.case = TRUE))) {
  stop("Candidate or canonical record state differs from the reviewed selection.", call. = FALSE)
}
if (!dry_run && (candidates$import_status[ci] != "not_started" ||
    selected$curation_status[si] != "selected_for_source_curation")) {
  stop("The candidate has already been imported or its selection state changed.", call. = FALSE)
}

input_fields <- read_fields(inputs_path)
output_fields <- read_fields(outputs_path)
assumption_fields <- read_fields(assumptions_path)
input <- function(type, measure, basis, value, unit, year, fleet, source_reference,
                  notes, region = "East Coast", transformation = "") {
  blank_row(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = "model_year", fleet = fleet, region = region,
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes))
}
output <- function(type, measure, value, unit, year = 2025L, scenario = "",
                   lwr = NA_real_, upr = NA_real_, source_reference, notes) {
  blank_row(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year,
    region = "East Coast", scenario = scenario, lwr = lwr, upr = upr,
    source_type = "official_table", source_reference = source_reference, notes = notes))
}
assumption <- function(component, setting, value, source_reference, notes = "") {
  blank_row(assumption_fields, list(assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    region = "East Coast", source_reference = source_reference, notes = notes))
}

catch_years <- c(1970L, 1980L, 1990L, 2000L, 2004:2024)
catch_values <- rbind(
  c(500, 132, 18, 28), c(678, 175, 24, 37), c(554, 234, 28, 50), c(452, 330, 9, 71),
  c(367, 240, 7, 50), c(276, 245, 13, 50), c(230, 271, 4, 56), c(269, 290, 6, 61),
  c(244, 311, 3, 66), c(353, 285, 5, 60), c(449, 314, 32, 61), c(323, 353, 18, 69),
  c(284, 360, 10, 70), c(301, 341, 11, 66), c(341, 308, 40, 57), c(342, 317, 41, 59),
  c(317, 375, 33, 70), c(321, 401, 10, 71), c(335, 419, 14, 73), c(303, 377, 13, 64),
  c(314, 318, 9, 53), c(320, 438, 10, 74), c(283, 381, 7, 61), c(280, 454, 8, 61),
  c(147, 261, 10, 39)
)
colnames(catch_values) <- c("Qld Commercial", "Qld RecCharter", "NSW Commercial", "NSW RecCharter")
if (nrow(catch_values) != length(catch_years) || any(!is.finite(catch_values)) ||
    any(catch_values < 0)) stop("The reported catch subset is malformed.", call. = FALSE)
catch_rows <- do.call(rbind, lapply(seq_along(catch_years), function(i) {
  do.call(rbind, lapply(seq_len(ncol(catch_values)), function(j) {
    notes <- paste("Published sector catch subset, rounded to the nearest tonne.",
      "Years are financial-year labels; for example, 2024 means July 2023-June 2024.",
      "These sector totals are not the complete annual fleet catch histories or catch-at-age inputs.")
    if (catch_years[i] == 2024L) notes <- paste(notes,
      "The rounded sector values sum to 457 t, while report prose gives total catch as 459 t; retain the reported values without reconciliation.")
    input("catch", "catch_biomass", "biomass", catch_values[i, j], "tonnes",
      catch_years[i], colnames(catch_values)[j],
      "2025 East Coast Spanish mackerel assessment report, Table 3.1, p. 35",
      notes)
  }))
}))

outputs <- list(
  output("biomass", "SSB_relative_to_unfished", 0.34, "ratio", 2025L,
    "final_MCMC_ensemble", 0.17, 0.62,
    "2025 assessment report, Table 3.3, p. 67",
    "Beginning-2025 spawning biomass relative to unfished biomass; ensemble median and 95% credible interval."),
  output("biomass", "SSB_relative_to_unfished", 0.25, "ratio", 2025L,
    "mean_MLE_scenarios", source_reference = "2025 assessment report, Table 3.3, p. 67",
    notes = "Mean of six scenario MLE biomass ratios at the beginning of 2025; no uncertainty is reported for this mean."),
  output("probability", "probability_SSB_ratio_below_0.20", 0.08, "probability", 2025L,
    "final_MCMC_ensemble", source_reference = "2025 assessment report, Table 3.3, p. 67",
    notes = "Probability that beginning-2025 spawning biomass is below 20% of unfished biomass."),
  output("probability", "probability_SSB_ratio_0.20_to_0.40", 0.61, "probability", 2025L,
    "final_MCMC_ensemble", source_reference = "2025 assessment report, Table 3.3, p. 67",
    notes = "Probability that beginning-2025 spawning biomass is between 20% and 40% of unfished biomass."),
  output("probability", "probability_SSB_ratio_0.40_to_0.60", 0.28, "probability", 2025L,
    "final_MCMC_ensemble", source_reference = "2025 assessment report, Table 3.3, p. 67",
    notes = "Probability that beginning-2025 spawning biomass is between 40% and 60% of unfished biomass."),
  output("probability", "probability_SSB_ratio_above_0.60", 0.03, "probability", 2025L,
    "final_MCMC_ensemble", source_reference = "2025 assessment report, Table 3.3, p. 67",
    notes = "Probability that beginning-2025 spawning biomass is above 60% of unfished biomass."),
  output("mortality", "natural_mortality_average_parameter", 0.2, "per year", NA_integer_,
    "final_MCMC_ensemble", 0.2, 0.3,
    "2025 assessment report, Table 3.2, p. 55",
    "Pooled MCMC median and 95% credible interval as rounded in the report; values are coarse and do not replace unrounded scenario estimates.")
)
mle <- data.frame(value = c(.28, .25, .22, .29, .25, .22),
  lwr = c(.10, .08, .08, .12, .10, .08), upr = c(.46, .41, .36, .47, .40, .35))
mcmc <- data.frame(value = c(.43, .29, .32, .40, .35, .26),
  lwr = c(.25, .18, .16, .23, .17, .14), upr = c(.66, .42, .58, .63, .63, .54))
for (i in 1:6) {
  outputs[[length(outputs) + 1L]] <- output("biomass", "SSB_relative_to_unfished",
    mle$value[i], "ratio", 2025L, paste0("scenario_", i, "_MLE"), mle$lwr[i], mle$upr[i],
    "2025 assessment report, Table 3.4, p. 68",
    "Beginning-2025 biomass ratio relative to unfished; 95% confidence interval for the scenario MLE.")
  outputs[[length(outputs) + 1L]] <- output("biomass", "SSB_relative_to_unfished",
    mcmc$value[i], "ratio", 2025L, paste0("scenario_", i, "_MCMC"), mcmc$lwr[i], mcmc$upr[i],
    "2025 assessment report, Table 3.4, p. 68",
    "Beginning-2025 biomass ratio relative to unfished; 95% credible interval for the MCMC scenario.")
}
output_rows <- do.call(rbind, outputs)

assumptions <- do.call(rbind, list(
  assumption("assessment", "run_and_time_period", "2025 full assessment; model data 1911-2024; beginning-2025 status", "2025 assessment report, sections 2.1 and 3.2.5",
    "Input and output years use Australian financial years; 2024 denotes July 2023-June 2024."),
  assumption("assessment", "model", "Stock Synthesis 3.30.22.1; annual time step; two sexes", "2025 assessment report, sections 2.8.1-2.8.2, pp. 24-25"),
  assumption("fleet", "spatial_and_sector_structure", "Fleets-as-areas structure; Queensland fisheries split by sector, latitude, and season; NSW sectors represented separately; standardised CPUE is a survey fleet", "2025 assessment report, section 2.8.2 and Table 2.2, pp. 24-26",
    "Quadrant 4 catch was allocated to quadrant 1. The report's fleet structure is not recoverable as a complete native input bundle from this PDF."),
  assumption("catch", "catch_history", "Retained catch reconstructed for 1911-2024; 1997-2004 Queensland commercial catch scaled by 0.61; 1982-1988 interpolated; 1911-1937 hindcast", "2025 assessment report, section 2.2.1, pp. 10-13",
    "Only the rounded selected-year sector catch values in Table 3.1 are imported as numerical inputs; do not infer missing years or fleet splits."),
  assumption("index", "standardised_cpue", "Annual commercial CPUE index standardised with a GAM using data from 2006-2023", "2025 assessment report, section 2.4, pp. 18-19",
    "Aggregate index only; numerical annual index values and model observation timing were not located in the public report."),
  assumption("composition", "age_and_length_observations", "Length and sex-specific conditional age-at-length compositions from 2005-2023; length bins are 2 cm; 2000-2004 and 2024 samples excluded", "2025 assessment report, sections 2.6.3-2.6.4 and 3.1.5, pp. 22-23, 42-43",
    "Only conditional age-at-length likelihood data inform age structure; numerical input arrays and sample sizes are not published as tables."),
  assumption("likelihood", "relative_composition_weights", "Final ensemble includes scenarios with length-composition effective sample size at 50% and 25% of conditional age-at-length ESS", "2025 assessment report, section 2.6.4 and Table 2.4, pp. 22-23, 30-31"),
  assumption("biology", "maturity", "Length-based maturity = exp(-10.349 + 0.0128 FL) / (1 + exp(-10.349 + 0.0128 FL)); first mature age 2", "2025 assessment report, section 2.5.2, p. 19",
    "FL is fork length in mm; age-specific maturity is calculated internally from the growth and age-length transition model."),
  assumption("biology", "weight_and_fecundity", "Whole-fish weight (kg) = 3.40e-9 * FL^3.12 for fork length FL in mm; female fecundity = 5.290168e-09 * FL^3.945 for FL in cm", "2025 assessment report, sections 2.5.3-2.5.4, pp. 19-20",
    "Growth is sex-specific and estimated; direct numerical weight-at-age and maturity-at-age inputs are not published."),
  assumption("M", "natural_mortality", "M is constant across ages, sexes, and years; estimated in the final ensemble with a Hamel-Cope lognormal prior (median 5.4/25 = 0.216 per year; log-scale SD 0.31)", "2025 assessment report, section 2.8.4, pp. 27-28",
    "Table 3.2 reports a pooled rounded MCMC median of 0.2 (95% credible interval 0.2-0.3); the rounded limits are not precise scenario estimates."),
  assumption("recruitment", "stock_recruitment_and_recruitment_deviations", "Beverton-Holt; steepness fixed at 0.54, 0.69, or 0.808 across scenarios; sigma-R fixed at 0.6", "2025 assessment report, Table 2.3 and section 2.8.4, pp. 27-28",
    "Table 2.3 lists deviations for 1985-2022, while the accompanying text says the final estimated deviations span 1992-2022; the report is internally inconsistent on the start year."),
  assumption("assessment", "final_scenario_ensemble", "Six final MCMC scenarios combine three steepness values and two length-versus-age composition weights", "2025 assessment report, section 2.8.5 and Table 2.4, pp. 29-31",
    "The official summary combines scenario uncertainty; scenario outputs are retained separately where Table 3.4 reports them."),
  assumption("source", "unavailable_numerical_series", "Full annual fleet catch histories, annual CPUE, raw length and age-at-length composition arrays, age-specific biological surfaces, and annual N/F/recruitment outputs", "2025 assessment report, sections 2-3",
    "The public detailed report contains descriptions, figures, and selected summary tables, but not the native inputs and full annual output arrays.")
))

if (nrow(catch_rows) != 100L || nrow(output_rows) != 19L || nrow(assumptions) != 13L ||
    any(!nzchar(catch_rows$source_reference)) || any(!nzchar(output_rows$source_reference)) ||
    any(catch_rows$source_type != "official_table") || any(output_rows$source_type != "official_table") ||
    !identical(sort(unique(as.integer(catch_rows$year))), sort(catch_years)) ||
    !identical(sort(unique(as.character(catch_rows$fleet))), sort(colnames(catch_values)))) {
  stop("Prepared source rows failed structural or provenance checks.", call. = FALSE)
}

stock <- blank_row(read_fields(stocks_path), list(stock_id = stock_id, charbonneau_id = "",
  authority = "Queensland DPI", authority_stock_id = "East Coast biological stock",
  scientific_name = "Scomberomorus commerson", common_name = "Australian east coast Spanish mackerel",
  area = "Cape York Peninsula to Newcastle, New South Wales", region = "Queensland and New South Wales east coast",
  ocean = "Southwest Pacific",
  notes = "The 2025 report treats east coast Spanish mackerel as one stock. Gulf of Carpentaria and Torres Strait units are separate; no formal code was assigned in the reviewed report."))
assessment <- blank_row(read_fields(assessments_path), list(assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2025L, terminal_year = 2024L,
  estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.22.1", is_current = TRUE,
  is_applied = TRUE, assessment_url = report_url, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed official assessment located for the current east coast stock unit. Numerical inputs are limited to the selected rounded sector catch table; outputs are limited to reported biomass-ratio summaries and pooled M. Full annual inputs and population arrays were not available from the reviewed public report."))

if (dry_run) {
  cat("Dry run passed: 100 reported catch rows, 19 reported output rows, and 13 assumptions prepared.\n")
} else {
  for (path in c(inputs_path, outputs_path)) {
    if (assessment_id %in% first_column(path)) stop("Assessment rows already exist in ", basename(path), call. = FALSE)
  }
  source(file.path(root, "scripts/database/candidate_register_io.R"))
  candidate <- candidates[ci, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$review_date <- retrieved_on
  candidate$notes <- "See discovery/source_reviews/australia_qld_spanish_mackerel_east_coast_2025.md. Canonical record contains only the selected rounded catch table and published summary outputs; raw likelihood inputs remain unavailable."
  selected_row <- selected[si, , drop = FALSE]
  selected_row$curation_status <- "partial_source_import"
  append_rows(stocks_path, stock)
  append_rows(assessments_path, assessment)
  append_rows(inputs_path, catch_rows)
  append_rows(outputs_path, output_rows)
  append_rows(assumptions_path, assumptions)
  replace_candidate_register_row(candidates_path, ci, candidate, candidate_id)
  selected[si, ] <- selected_row
  utils::write.csv(selected, selected_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts/database/195_summarize_discovery.R"), local = new.env(parent = globalenv()))
  source(file.path(root, "scripts/database/196_summarize_inventory_units.R"), local = new.env(parent = globalenv()))
  cat("Imported a partial, source-reported 2025 assessment record for Australian east coast Spanish mackerel.\n")
}
