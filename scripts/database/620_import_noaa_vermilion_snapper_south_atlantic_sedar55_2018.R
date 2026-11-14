root <- "."
stock_id <- "noaa_vermilion_snapper_south_atlantic"
assessment_id <- "noaa_vermilion_snapper_south_atlantic_sedar55_2018"
candidate_id <- "NOAA:10257"
report_url <- "https://sedarweb.org/documents/sedar-55-stock-assessment-report-south-atlantic-vermilion-snapper/"
model_url <- "https://raw.githubusercontent.com/nmfs-ost/stockplotr/1bd3ec5dfbb544c19d319f7fd24d2628c57c7721/inst/extdata/VermilionSnapper.rdat"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache_dir <- file.path("source_cache", "discovery_noaa_south_atlantic_vermilion_snapper_2018")
manifest_path <- file.path("provenance", "discovery_noaa_south_atlantic_vermilion_snapper_2018", "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE,
  colClasses = "character")

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result, value = TRUE)))
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(cache_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.numeric(row$bytes) != file.info(path)$size ||
      !identical(sha256_file(path), tolower(row$sha256))) {
    stop("Cached source differs from pinned provenance: ", name, call. = FALSE)
  }
  path
}

model_path <- verify_source("VermilionSnapper.rdat")
report_path <- verify_source("SEDAR55_SAR.pdf")
wp03_path <- verify_source("SEDAR55_WP03_life_history.pdf")
wp06_path <- verify_source("SEDAR55_WP06_commercial_compositions.pdf")
model <- dget(model_path)

if (!identical(model$info$title, "SEDAR 55 Assessment") ||
    !identical(model$info$species, "SA Vermilion Snapper") ||
    model$parms$styr != 1946 || model$parms$endyr != 2016 ||
    !identical(model$info$base.run, "VSX.tpl") ||
    !identical(dim(model$N.age), c(72L, 12L)) ||
    !identical(dim(model$B.age), c(72L, 12L)) ||
    !identical(dim(model$F.age), c(71L, 12L)) ||
    !identical(rownames(model$N.age), as.character(1946:2017)) ||
    !identical(rownames(model$F.age), as.character(1946:2016)) ||
    !identical(colnames(model$N.age), as.character(1:12)) ||
    !all(as.integer(model$a.series$age) == 1:12)) {
  stop("The pinned BAM artifact does not match the screened SEDAR 55 run structure.", call. = FALSE)
}

model_reference <- paste0(
  "NOAA NMFS OST stockplotr commit 1bd3ec5dfbb544c19d319f7fd24d2628c57c7721; ",
  "inst/extdata/VermilionSnapper.rdat"
)
report_reference <- "SEDAR 55 final SAR, Section II"

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
                      year_basis = "", age = NA_integer_, fleet = "", survey = "",
                      sex = "", sample_size = NA_real_, observation_id = "",
                      length_bin = NA_real_, age_error = NA_integer_,
                      source_reference = model_reference, notes = "") {
  n <- length(value)
  if (!n) return(invisible(NULL))
  out <- pacific_database_row("inputs", n = n)
  out$assessment_id <- assessment_id
  out$type <- rep_len(type, n)
  out$measure <- rep_len(measure, n)
  out$basis <- rep_len(basis, n)
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$sex <- rep_len(sex, n)
  out$year <- rep_len(year, n)
  out$year_basis <- rep_len(year_basis, n)
  out$age <- rep_len(age, n)
  out$value <- as.numeric(value)
  out$unit <- rep_len(unit, n)
  out$sampling_time <- NA_real_
  out$source_type <- "official_machine_readable"
  out$source_reference <- rep_len(source_reference, n)
  out$transformation <- ""
  out$notes <- rep_len(notes, n)
  out$observation_id <- rep_len(observation_id, n)
  out$length_bin <- rep_len(length_bin, n)
  out$sample_size <- rep_len(sample_size, n)
  out$age_error <- rep_len(age_error, n)
  input_rows[[length(input_rows) + 1L]] <<- out
  invisible(out)
}

annual_inputs <- list(
  list(field = "L.cHL.ob", fleet = "Commercial handline", measure = "landings_biomass",
       basis = "biomass", unit = "1000 lb whole weight"),
  list(field = "L.cTW.ob", fleet = "Commercial historic trawl", measure = "landings_biomass",
       basis = "biomass", unit = "1000 lb whole weight"),
  list(field = "L.cOT.ob", fleet = "Commercial other", measure = "landings_biomass",
       basis = "biomass", unit = "1000 lb whole weight"),
  list(field = "L.rHB.ob", fleet = "Recreational headboat", measure = "landings_numbers",
       basis = "numbers", unit = "1000 fish"),
  list(field = "L.rGN.ob", fleet = "General recreational", measure = "landings_numbers",
       basis = "numbers", unit = "1000 fish"),
  list(field = "D.cHL.ob", fleet = "Commercial handline", measure = "discard_numbers",
       basis = "numbers", unit = "1000 fish"),
  list(field = "D.rHB.ob", fleet = "Recreational headboat", measure = "discard_numbers",
       basis = "numbers", unit = "1000 fish"),
  list(field = "D.rGN.ob", fleet = "General recreational", measure = "discard_numbers",
       basis = "numbers", unit = "1000 fish")
)
years <- as.integer(model$t.series$year)
for (spec in annual_inputs) {
  values <- as.numeric(model$t.series[[spec$field]])
  keep <- is.finite(values) & values >= 0 & values != -99999
  add_input("catch", spec$measure, spec$basis, values[keep], spec$unit,
    year = years[keep], year_basis = "calendar_year", fleet = spec$fleet,
    source_reference = paste0(model_reference, "; t.series$", spec$field,
      "; cross-check SEDAR 55 SAR Table 2"),
    notes = if (startsWith(spec$field, "D."))
      "Source discard series are reported before the fleet-specific discard mortality is applied; all released fish are counted in 1000 fish." else
      "Official assessment landings series; commercial fleets are whole-weight biomass and recreational fleets are numbers of fish, as in SEDAR 55 SAR Table 2.")
}

index_specs <- list(
  list(code = "cHL", field = "U.cHL.ob", cv = "cv.U.cHL", fleet = "Commercial handline",
       survey = "Commercial handline CPUE"),
  list(code = "rHB", field = "U.rHB.ob", cv = "cv.U.rHB", fleet = "Recreational headboat",
       survey = "Headboat CPUE"),
  list(code = "rGN", field = "U.rGN.ob", cv = "cv.U.rGN", fleet = "General recreational",
       survey = "General recreational CPUE"),
  list(code = "sTV", field = "U.sTV.ob", cv = "cv.U.sTV", fleet = "",
       survey = "SERFS chevron trap/video (CVID)"),
  list(code = "sFT", field = "U.sFT.ob", cv = "cv.U.sFT", fleet = "",
       survey = "MARMAP Florida snapper trap")
)
for (spec in index_specs) {
  values <- as.numeric(model$t.series[[spec$field]])
  cv <- as.numeric(model$t.series[[spec$cv]])
  keep <- is.finite(values) & values >= 0 & values != -99999
  series_note <- paste0("Aggregate relative index in the official model's reported scale; no physical abundance multiplier is specified. Source CV is preserved separately. Within-year sampling time was not reported as a single fraction.")
  add_input("index", "relative_abundance_index", "index_scale", values[keep],
    "relative index", year = years[keep], year_basis = "calendar_year",
    fleet = spec$fleet, survey = spec$survey,
    source_reference = paste0(model_reference, "; t.series$", spec$field,
      "; cross-check SEDAR 55 SAR Table 3"), notes = series_note)
  keep_cv <- keep & is.finite(cv) & cv >= 0 & cv != -99999
  add_input("index", "abundance_index_cv", "relative_scale", cv[keep_cv], "ratio",
    year = years[keep_cv], year_basis = "calendar_year", fleet = spec$fleet,
    survey = spec$survey,
    source_reference = paste0(model_reference, "; t.series$", spec$cv,
      "; SEDAR 55 SAR Table 3"),
    notes = "Source-reported coefficient of variation for the matching aggregate relative index.")
}

composition_mats <- model$comp.mats
for (name in names(composition_mats)) {
  if (!endsWith(name, ".ob")) next
  mat <- composition_mats[[name]]
  parts <- strsplit(name, ".", fixed = TRUE)[[1L]]
  family <- parts[1L]
  code <- paste(parts[2:(length(parts) - 1L)], collapse = ".")
  if (!family %in% c("acomp", "lcomp") || any(!is.finite(mat))) {
    stop("Unexpected or incomplete observed composition matrix: ", name, call. = FALSE)
  }
  comp_years <- as.integer(rownames(mat))
  ts_rows <- match(comp_years, years)
  if (anyNA(ts_rows)) stop("Composition years do not match t.series: ", name, call. = FALSE)
  ts_prefix <- paste(family, code, sep = ".")
  raw_count <- as.numeric(model$t.series[[paste0(ts_prefix, ".nfish")]][ts_rows])
  effective_n <- as.numeric(model$t.series[[paste0(ts_prefix, ".neff")]][ts_rows])
  if (length(raw_count) != nrow(mat)) raw_count <- rep(NA_real_, nrow(mat))
  if (length(effective_n) != nrow(mat)) effective_n <- rep(NA_real_, nrow(mat))
  raw_count[!is.finite(raw_count) | raw_count <= 0 | raw_count == -99999] <- NA_real_
  effective_n[!is.finite(effective_n) | effective_n <= 0 | effective_n == -99999 | effective_n == -49999] <- NA_real_
  observation_id <- paste0(name, "_", comp_years)
  is_age <- family == "acomp"
  is_survey <- code == "sTV" || code == "sFT"
  fleet <- if (is_survey) "" else switch(code,
    cHL = "Commercial handline", cOT = "Commercial other",
    cHL.D = "Commercial handline discards", rHB.D = "Recreational headboat discards",
    rHB = "Recreational headboat", rGN = "General recreational", "")
  survey <- if (code == "sTV") "SERFS chevron trap/video" else if (code == "sFT")
    "MARMAP Florida snapper trap" else ""
  type <- if (is_survey) "index" else "catch"
  measure <- if (is_age) "proportion_at_age" else "proportion_at_length"
  bins <- suppressWarnings(as.numeric(colnames(mat)))
  if (anyNA(bins)) stop("Could not parse composition bins in ", name, call. = FALSE)
  values <- as.vector(t(mat))
  if (any(values < 0 | values > 1)) stop("Composition proportions fall outside [0,1]: ", name, call. = FALSE)
  bin_notes <- if (is_age)
    "Model-ready age composition; age 12 is the 12+ group. sample_size is the effective sample size used by the assessment; raw aged-fish counts are recorded separately when present." else
    "Model-ready length composition; numeric bins are retained as supplied in millimetres. sample_size is the effective sample size used by the assessment when reported."
  missing_sample <- is.na(rep(effective_n, each = ncol(mat)))
  if (any(missing_sample)) bin_notes <- paste(bin_notes,
    "sample_size is left blank because a positive effective sample size is not reported for this composition.")
  add_input(type, measure, "proportion_numbers", values, "proportion",
    year = rep(comp_years, each = ncol(mat)), year_basis = "calendar_year",
    age = if (is_age) rep(bins, times = nrow(mat)) else NA_integer_,
    fleet = fleet, survey = survey,
    sample_size = rep(effective_n, each = ncol(mat)),
    observation_id = rep(observation_id, each = ncol(mat)),
    length_bin = if (is_age) NA_real_ else rep(bins, times = nrow(mat)),
    source_reference = paste0(model_reference, "; comp.mats$", name,
      "; model-ready fitted input; source papers SEDAR55-WP06 and WP09"),
    notes = bin_notes)
  if (any(!is.na(raw_count))) {
    count_keep <- !is.na(raw_count)
    add_input("biology", "composition_sample_count", "numbers", raw_count[count_keep],
      "fish", year = comp_years[count_keep], year_basis = "calendar_year",
      fleet = fleet, survey = survey, observation_id = observation_id[count_keep],
      source_reference = paste0(model_reference, "; t.series$", ts_prefix,
        ".nfish"),
      notes = "Raw number of fish represented by the composition; kept separate from the model effective sample size stored on composition rows.")
  }
}

age_error <- model$age.error$error.mat
if (!is.matrix(age_error) || !identical(dim(age_error), c(12L, 12L)) ||
    any(!is.finite(age_error)) || any(age_error < 0 | age_error > 1) ||
    any(abs(colSums(age_error) - 1) > 1e-6)) {
  stop("The age-error matrix does not have a valid column-normalized 12-age structure.", call. = FALSE)
}
add_input("biology", "age_error_probability", "proportion",
  as.vector(age_error), "probability",
  age = rep(as.integer(colnames(age_error)), each = nrow(age_error)),
  age_error = rep(as.integer(rownames(age_error)), times = ncol(age_error)),
  source_reference = paste0(model_reference, "; age.error$error.mat"),
  notes = "Columns are true ages; age_error identifies observed ages in matrix rows. Probabilities are not rounded or renormalized.")

biology <- model$a.series
add_input("biology", "growth_length_at_age", "native_covariate", biology$length,
  "mm fork length", age = biology$age,
  source_reference = paste0(model_reference, "; a.series$length; SEDAR 55 SAR Table 1"),
  notes = "Mean mid-year total length at age; age 12 is the 12+ group.")
add_input("weight", "weight_at_age", "weight_per_fish", biology$weight,
  "lb whole weight per fish", age = biology$age,
  source_reference = paste0(model_reference, "; a.series$weight; SEDAR 55 SAR Table 1"),
  notes = "Mean whole weight at age; the machine-readable values retain more precision than the rounded report table.")
add_input("maturity", "maturity_at_age", "proportion", biology$mat.female,
  "proportion", age = biology$age, sex = "female",
  source_reference = paste0(model_reference, "; a.series$mat.female; SEDAR 55 SAR Table 1"),
  notes = "Annual female maturity-at-age used in the egg-production calculation.")
add_input("biology", "proportion_female_at_age", "proportion", biology$prop.female,
  "proportion", age = biology$age,
  source_reference = paste0(model_reference, "; a.series$prop.female"),
  notes = "Female fraction used in the assessment's reproductive weighting.")
add_input("biology", "maturity_fecundity_at_age", "egg_count", biology$reprod,
  "1e12 eggs per fish at mid-year", age = biology$age,
  source_reference = paste0(model_reference, "; a.series$reprod"),
  notes = "Combined reproductive potential by age. Multiplying mid-year abundance by this vector reproduces the reported egg-production SSB to model rounding; this is not a weight-at-age surface.")
add_input("M", "natural_mortality_at_age", "per_year", biology$M,
  "per year", age = biology$age,
  source_reference = paste0(model_reference, "; a.series$M; SEDAR 55 SAR Table 1"),
  notes = "Fixed age-specific natural mortality; M is not estimated as a time-varying process. Age 12 is the 12+ group.")

inputs <- do.call(rbind, input_rows)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, age = NA_integer_,
                       source_reference = model_reference, notes = "") {
  n <- length(value)
  if (!n) return(invisible(NULL))
  out <- pacific_database_row("outputs", n = n)
  out$assessment_id <- assessment_id
  out$type <- rep_len(type, n)
  out$measure <- rep_len(measure, n)
  out$year <- rep_len(year, n)
  out$age <- rep_len(age, n)
  out$value <- as.numeric(value)
  out$unit <- rep_len(unit, n)
  out$source_type <- "official_machine_readable"
  out$source_reference <- rep_len(source_reference, n)
  out$notes <- rep_len(notes, n)
  output_rows[[length(output_rows) + 1L]] <<- out
  invisible(out)
}

matrix_output <- function(mat, type, measure, unit, note, table_ref) {
  long <- pacific_matrix_long(mat)
  age_group <- ifelse(long$age == 12L, "12+", "")
  add_output(type, measure, long$value, unit, long$year, long$age,
    source_reference = paste0(model_reference, "; ", table_ref),
    notes = paste(note, "Age 12 is the 12+ group. No age-specific uncertainty is present in this artifact."))
  invisible(age_group)
}
matrix_output(model$N.age, "population", "numbers_at_age", "fish",
  "Abundance at start of year; cross-checked against SEDAR 55 SAR Table 6 after dividing published values by 1000.",
  "N.age; cross-check SEDAR 55 SAR Table 6")
matrix_output(model$B.age, "biomass", "biomass_at_age", "metric tons",
  "Biomass at start of year in the model artifact; cross-checked against SEDAR 55 SAR Table 7 after converting metric tons to 1000 lb.",
  "B.age; cross-check SEDAR 55 SAR Table 7")
matrix_output(model$F.age, "mortality", "fishing_mortality_at_age", "per year",
  "Instantaneous fishing mortality at age; cross-checked against SEDAR 55 SAR Table 11.",
  "F.age; cross-check SEDAR 55 SAR Table 11")

annual <- model$t.series
year <- as.integer(annual$year)
keep <- function(x) is.finite(as.numeric(x)) & as.numeric(x) != -99999
add_output("population", "total_numbers", annual$N[keep(annual$N)], "fish",
  year[keep(annual$N)], notes = "Estimated total abundance at start of year from t.series$N.")
add_output("recruitment", "recruitment", annual$recruits[keep(annual$recruits)], "fish",
  year[keep(annual$recruits)], age = 1L,
  notes = "Estimated age-1 recruitment; the assessment recruitment process begins in 1976.")
add_output("biomass", "total_biomass", annual$B[keep(annual$B)], "metric tons",
  year[keep(annual$B)], notes = "Estimated total biomass at start of year from t.series$B.")
add_output("biomass", "SSB", annual$SSB[keep(annual$SSB)], "1e12 eggs",
  year[keep(annual$SSB)], notes = "Egg-production spawning stock at mid-year; this is not conventional spawning biomass in tonnes.")
add_output("mortality", "apical_F", annual$F.full[keep(annual$F.full)], "per year",
  year[keep(annual$F.full)], notes = "Annual apical instantaneous fishing mortality from t.series$F.full.")
outputs <- do.call(rbind, output_rows)

assumption <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "run_identity", "SEDAR 55 South Atlantic vermilion snapper full assessment; data through 2016.",
    paste(report_reference, "; NOAA Stock SMART assessment 8220")),
  assumption("model", "model_family", "Beaufort Assessment Model statistical catch-at-age (BAM)",
    paste0(model_reference, "; info and parms; base run VSX.tpl"),
    "The machine-readable BAM artifact identifies a SEDAR 55 base run and is dated 2023-02-27."),
  assumption("population", "years_ages_and_sexes", "1946-2016 fitted observations; estimates through 2017; ages 1-12+; both-sex abundance.",
    paste(report_reference, "Tables 6-8 and 11"),
    "Age 12 is the accumulation plus group; recruitment begins at age 1 and its deviation process begins in 1976."),
  assumption("catch", "fleet_structure", "Commercial handline, commercial historic trawl, commercial other, recreational headboat, and general recreational landings; discards for handline, headboat, and general recreational fleets.",
    paste(report_reference, "Table 2"),
    "Commercial landings are 1000 lb whole weight; recreational landings and all discard series are 1000 fish. Discard mortality is applied after the reported live-and-dead release series."),
  assumption("composition", "age_length_compositions", "Observed age compositions for commercial handline, recreational headboat, general recreational, and SERFS trap/video; length compositions retained for the supplied fleets and survey.",
    paste0(model_reference, "; comp.mats; SEDAR55-WP06 and WP09"),
    "The working-paper addenda show final compositions as figures; exact model-ready values are available in the pinned BAM artifact. Effective sample sizes are retained in sample_size; raw fish counts are separate when available. Some length-composition sample sizes are absent from the artifact and remain blank."),
  assumption("index", "abundance_series", "Five aggregate relative indices with source CVs: commercial handline, headboat, general recreational, SERFS CVID, and MARMAP Florida snapper trap.",
    paste(report_reference, "Table 3; SEDAR55-WP02 and WP07"),
    "The SERFS survey also has an age composition, but no age-specific abundance index is reported. Within-year index timing is not specified as a single annual fraction."),
  assumption("biology", "age_specific_inputs", "Fixed length, whole weight, female maturity, female proportion, and combined reproductive potential at ages 1-12+.",
    paste0(model_reference, "; a.series; SEDAR 55 SAR Table 1"),
    "The combined reproductive potential is stored separately from weight-at-age. The model computes egg-production SSB using mid-year abundance."),
  assumption("M", "natural_mortality", "Fixed age-specific M declines from 0.341 at age 1 to 0.194 per year at age 12+.",
    paste0(model_reference, "; a.series$M; SEDAR 55 SAR Table 1"),
    "M is an input, not a fitted or annual output surface."),
  assumption("biology", "ageing_error", "A fixed 12 by 12 age-error probability matrix is supplied.",
    paste0(model_reference, "; age.error$error.mat"),
    "Columns represent true ages and rows represent observed ages; source probabilities are retained without rounding."),
  assumption("timing", "spawning_and_index_timing", "BAM applies spawning at mid-year (spawn.time = 0.5).",
    paste0(model_reference, "; parms$spawn.time; SEDAR 55 SAR Table 1"),
    "The reviewed sources do not define one within-year fraction for all aggregate survey/index observations."),
  assumption("output", "spawning_stock_definition", "SSB is egg production, reported in 1e12 eggs at mid-year.",
    paste0(model_reference, "; info$units.ssb and t.series$SSB"),
    "Do not interpret this output as mature biomass in metric tons."),
  assumption("uncertainty", "reported_output_uncertainty", "Point estimates are available in the BAM artifact; age-specific standard errors and intervals are not included.",
    paste(report_reference, "Tables 6-8 and 11; machine-readable BAM artifact"),
    "Uncertainty is therefore not fabricated or copied across ages; output completeness remains partial."),
  assumption("source", "machine_readable_model_artifact", "NOAA NMFS OST stockplotr repository; commit 1bd3ec5dfbb544c19d319f7fd24d2628c57c7721; artifact metadata identifies SEDAR 55, VSX.tpl, and 2023-02-27.",
    model_url,
    "The artifact is an ADMB2R machine-readable fit object, not the original model source code or raw TIP sampling records.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA Fisheries", authority_stock_id = "10257",
  scientific_name = "Rhomboplites aurorubens", common_name = "South Atlantic vermilion snapper",
  area = "South Atlantic U.S. EEZ", region = "United States South Atlantic",
  ocean = "Northwest Atlantic",
  notes = "NOAA stock unit 10257; distinct from Gulf of Mexico vermilion snapper (NOAA:10256).")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2018L, terminal_year = 2016L,
  estimate_terminal_year = 2017L, assessment_type = "full_assessment",
  model_family = "Beaufort Assessment Model (BAM)",
  model_version = "SEDAR 55 accepted full assessment; VSX.tpl base run",
  is_current = "TRUE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = report_url,
  framework_url = "https://sedarweb.org/assessments/sedar-55/",
  data_url = "https://sedarweb.org/assessments/sedar-55/",
  model_url = model_url,
  repository_url = "https://github.com/nmfs-ost/stockplotr/tree/1bd3ec5dfbb544c19d319f7fd24d2628c57c7721/inst/extdata",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Latest accepted full assessment located for this current stock unit; fitted data end in 2016 and estimates extend through 2017.",
    "A later interim analysis did not replace SEDAR 55 for advice; a future update was scheduled after this assessment.",
    "The pinned machine-readable artifact supplies the final model-ready compositions and point estimates, but not the original code, some composition sample sizes, or output uncertainty."))

existing_stocks <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
existing_assessments <- read.csv(file.path(root, "database/assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidates_path <- file.path(root, "discovery/candidates.csv")
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || candidates$candidate_unit_id[candidate_row] != stock_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    any(existing_stocks$stock_id == stock_id) ||
    any(existing_assessments$assessment_id == assessment_id)) {
  stop("South Atlantic vermilion identity conflicts with the candidate register or canonical database.", call. = FALSE)
}

source_values <- do.call(rbind, input_rows)
age_compositions <- source_values[source_values$measure == "proportion_at_age", , drop = FALSE]
length_compositions <- source_values[source_values$measure == "proportion_at_length", , drop = FALSE]
age_error_rows <- source_values[source_values$measure == "age_error_probability", , drop = FALSE]
ssb_surface <- model$N.age.mdyr %*% model$a.series$reprod
ssb_model <- model$t.series$SSB[match(as.integer(rownames(model$N.age.mdyr)), years)]
if (nrow(stock) != 1L || nrow(assessment) != 1L ||
    nrow(age_compositions) != 936L || nrow(age_error_rows) != 144L ||
    nrow(outputs[outputs$measure == "numbers_at_age", ]) != 864L ||
    nrow(outputs[outputs$measure == "biomass_at_age", ]) != 864L ||
    nrow(outputs[outputs$measure == "fishing_mortality_at_age", ]) != 852L ||
    any(!is.finite(inputs$value)) || any(!is.finite(outputs$value)) ||
    any(abs(ssb_surface[, 1L] - ssb_model) > 0.02, na.rm = TRUE) ||
    anyDuplicated(paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey,
      inputs$year, inputs$age, inputs$observation_id, inputs$length_bin,
      inputs$age_error, sep = "|")) ||
    anyDuplicated(paste(outputs$type, outputs$measure, outputs$year, outputs$age, sep = "|"))) {
  stop("South Atlantic vermilion source rows failed structure, value, SSB, or uniqueness checks.", call. = FALSE)
}

inventory_path <- file.path(root, "discovery/inventory_units.csv")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  candidates$catch_age_evidence[candidate_row] <- paste(
    "The SEDAR 55 model artifact contains annual landings and weighted age compositions for",
    "commercial handline, headboat, general recreational, and SERFS trap/video observations.",
    "These are aggregate landings plus age proportions, not direct catch numbers-at-age.")
  candidates$survey_age_evidence[candidate_row] <- paste(
    "Five aggregate relative index series and their CVs are retained; SERFS trap/video also",
    "has an age composition. No age-specific abundance index is reported.")
  candidates$weights_evidence[candidate_row] <- paste(
    "Age-specific mean length and whole weight were recovered from a pinned machine-readable",
    "BAM artifact and cross-checked against SEDAR 55 SAR Table 1.")
  candidates$maturity_evidence[candidate_row] <- paste(
    "Female maturity and female proportion at age are captured. The fitted SSB series is",
    "egg production in 1e12 eggs, not mature biomass in metric tons.")
  candidates$mortality_evidence[candidate_row] <- paste(
    "Natural mortality is a fixed age-specific input; it is not estimated as a time-varying",
    "M process. A 12 by 12 age-error probability matrix is also available.")
  candidates$output_evidence[candidate_row] <- paste(
    "The machine-readable model artifact provides N-at-age, biomass-at-age, F-at-age, total",
    "abundance, total biomass, age-1 recruitment, apical F, and egg-production SSB through",
    "2017 where estimated. Output uncertainty is not included in the artifact.")
  candidates$decision_reason[candidate_row] <- paste(
    "Imported the verified 2018 SEDAR 55 full assessment for the current NOAA:10257 unit.",
    "The source record remains partial because some length-composition sample sizes and output",
    "uncertainty were unavailable, and the original model code/raw sampling files were not located.")
  candidates$notes[candidate_row] <- paste(
    "The NOAA NMFS OST stockplotr data file is pinned to commit 1bd3ec5dfbb544c19d319f7fd24d2628c57c7721.",
    "It identifies the assessment as SEDAR 55, base run VSX.tpl, dated 2023-02-27.",
    "The assessment remains distinct from Gulf vermilion snapper NOAA:10256.")
  replace_candidate_register_row(candidates_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$match_status[inventory_row] <- "matched"
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
} else {
  message("Dry run: ", nrow(stock), " stock, ", nrow(assessment), " assessment, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs, and ",
    nrow(outputs), " outputs. Age composition rows: ", nrow(age_compositions),
    "; length composition rows: ", nrow(length_compositions),
    "; age-error probabilities: ", nrow(age_error_rows),
    ". Use --write to append these source records.")
}
