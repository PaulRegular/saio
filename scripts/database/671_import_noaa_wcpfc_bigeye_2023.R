root <- "."
stock_id <- "wcpfc_wcpo_bigeye"
assessment_id <- "wcpfc_wcpo_bigeye_2023"
candidate_id <- "NOAA:11684"
cache_name <- "discovery_noaa_wcpfc_bigeye_2026"
revision <- "81fc412ad1f36416f78f84ef6bd2d5dff68d14c8"
dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")

.libPaths(c(file.path(root, "source_cache/.Rlib"), .libPaths()))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache_options <- c(
  file.path(root, "source_cache", cache_name),
  file.path(dirname(dirname(normalizePath(root))), cache_name)
)
cache_options <- cache_options[dir.exists(cache_options)]
if (!length(cache_options)) stop("Pinned WCPFC bigeye cache is required.", call. = FALSE)
cache <- normalizePath(cache_options[[1L]], winslash = "/")
manifest_path <- file.path(root, "provenance", cache_name, "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")

sha256_file <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) {
    return(tolower(digest::digest(
      object = readBin(path, what = "raw", n = file.info(path)$size),
      algo = "sha256", serialize = FALSE
    )))
  }
  output <- system2("certutil.exe", c("-hashfile",
    shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"),
    stdout = TRUE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    output, value = TRUE)))
  if (length(hash) != 1L) stop("Could not verify a cached source checksum.", call. = FALSE)
  hash
}

required_files <- c(
  "SC19-SA-WP-05_BET_2023_Rev02.pdf", "SC19_Outcomes_2023.pdf",
  "SPC__README.md", "SPC__TAF__data.R", "SPC_MFCL__bet.frq",
  "SPC_MFCL__bet.age_length", "SPC_MFCL__bet.ini", "SPC_MFCL__bet.tag",
  "TAF__data__fisheries.csv", "TAF__data__cpue.csv",
  "TAF__data__length_comps.csv", "TAF__data__weight_comps.csv",
  "TAF__data__otoliths.csv", "TAF__data__tag_releases.csv",
  "TAF__data__tag_recaptures.csv", "TAF__output__biology.csv",
  "TAF__output__biomass.csv", "TAF__output__catch.csv",
  "TAF__output__cpue.csv", "TAF__output__f_annual.csv",
  "TAF__output__natage.csv", "TAF__output__summary.csv"
)
manifest_row <- match(required_files, manifest$file)
if (!all(c("file", "url", "retrieved_on", "bytes", "sha256", "notes") %in% names(manifest)) ||
    anyDuplicated(manifest$file) || anyNA(manifest_row)) {
  stop("The pinned 2023 source manifest is incomplete.", call. = FALSE)
}
for (i in seq_along(required_files)) {
  name <- required_files[i]
  path <- file.path(cache, name)
  row <- manifest_row[i]
  if (!file.exists(path) || file.info(path)$size != as.numeric(manifest$bytes[row]) ||
      sha256_file(path) != tolower(manifest$sha256[row])) {
    stop("Cached WCPFC bigeye source failed provenance validation: ", name,
      call. = FALSE)
  }
}
repo_urls <- manifest$url[grepl(paste0(
  "raw.githubusercontent.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/",
  revision, "/"), manifest$url, fixed = TRUE)]
if (length(repo_urls) != 21L) {
  stop("The diagnostic model files are not pinned to the reviewed repository revision.",
    call. = FALSE)
}

read_source <- function(name) read.csv(file.path(cache, name),
  stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA"))

fishery_data <- read_source("TAF__data__fisheries.csv")
cpue_data <- read_source("TAF__data__cpue.csv")
length_data <- read_source("TAF__data__length_comps.csv")
weight_data <- read_source("TAF__data__weight_comps.csv")
otolith_data <- read_source("TAF__data__otoliths.csv")
release_data <- read_source("TAF__data__tag_releases.csv")
recapture_data <- read_source("TAF__data__tag_recaptures.csv")
biology_data <- read_source("TAF__output__biology.csv")
biomass_data <- read_source("TAF__output__biomass.csv")
catch_output <- read_source("TAF__output__catch.csv")
cpue_output <- read_source("TAF__output__cpue.csv")
f_output <- read_source("TAF__output__f_annual.csv")
n_output <- read_source("TAF__output__natage.csv")
summary_output <- read_source("TAF__output__summary.csv")

frq_lines <- readLines(file.path(cache, "SPC_MFCL__bet.frq"), warn = FALSE)
flag_header <- which(grepl("Data flags (for records 1", frq_lines, fixed = TRUE))
incident_header <- which(grepl("Datasets / LFIntervals", frq_lines, fixed = TRUE))
data_header <- which(grepl("# fishery data", frq_lines, fixed = TRUE))
if (length(flag_header) != 1L || length(incident_header) != 1L ||
    length(data_header) != 1L) {
  stop("Could not identify the required bet.frq sections.", call. = FALSE)
}
catch_flags <- scan(text = frq_lines[flag_header + 1L], what = integer(), quiet = TRUE)
incident_count <- as.integer(scan(text = frq_lines[incident_header + 1L],
  what = numeric(), quiet = TRUE)[1L])
incident_lines <- frq_lines[(data_header + 1L):length(frq_lines)]
incident_lines <- incident_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]",
  incident_lines)]
incident_fields <- strsplit(trimws(incident_lines), "[[:space:]]+")
if (length(incident_lines) != incident_count || any(lengths(incident_fields) < 7L)) {
  stop("Unexpected fishing-incident count or fields in bet.frq.", call. = FALSE)
}
frq_data <- as.data.frame(do.call(rbind, lapply(incident_fields, function(x) {
  as.numeric(x[1:7])
})))
names(frq_data) <- c("year", "month", "week", "fishery", "catch", "effort",
  "cpue_penalty")
frq_data$year <- as.integer(frq_data$year)
frq_data$month <- as.integer(frq_data$month)
frq_data$week <- as.integer(frq_data$week)
frq_data$fishery <- as.integer(frq_data$fishery)
frq_data$season <- as.integer((1 + frq_data$month) / 3)

region_label <- function(region) {
  ifelse(as.character(region) == "all", "All model regions",
    paste0("MFCL region ", region))
}
season_label <- function(season) paste0("model quarter ", season)
fishery_row <- match(frq_data$fishery, fishery_data$fishery)
fishery_code <- fishery_data$code[match(fishery_data$fishery,
  fishery_data$fishery)]
fishery_lookup <- data.frame(
  fishery = fishery_data$fishery,
  code = fishery_data$code,
  gear = fishery_data$gear_long,
  flag = fishery_data$flag,
  region = region_label(fishery_data$area),
  stringsAsFactors = FALSE
)
if (length(catch_flags) != 41L || nrow(fishery_data) != 41L ||
    !identical(fishery_data$fishery, 1:41) ||
    !identical(catch_flags[1:32], as.integer(fishery_data$gear[1:32] != "LL")) ||
    any(fishery_data$flag[33:41] != "IDX") || anyNA(fishery_row) ||
    incident_count != 8855L || any(!frq_data$month %in% c(2L, 5L, 8L, 11L)) ||
    any(!frq_data$fishery %in% 1:41) || any(!is.finite(frq_data$catch)) ||
    any(frq_data$catch < 0)) {
  stop("The pinned fishery structure or catch flags differ from the reviewed model.",
    call. = FALSE)
}

expected_coverage <- list(
  cpue = c(rows = 2520L, years = 70L, fisheries = 9L),
  length = c(rows = 96235L, fisheries = 18L),
  weight = c(rows = 707200L, fisheries = 24L),
  otolith = c(rows = 1010L, years = 14L, regions = 8L),
  release = c(rows = 11210L, groups = 118L),
  recapture = c(rows = 2892L),
  natage = c(rows = 100800L), f = c(rows = 28000L),
  catch = c(rows = 11480L), cpue_output = c(rows = 2520L),
  biomass = c(rows = 2520L), summary = c(rows = 70L), biology = c(rows = 40L)
)
if (nrow(cpue_data) != expected_coverage$cpue["rows"] ||
    length(unique(cpue_data$year)) != expected_coverage$cpue["years"] ||
    length(unique(cpue_data$fishery)) != expected_coverage$cpue["fisheries"] ||
    nrow(length_data) != expected_coverage$length["rows"] ||
    length(unique(length_data$fishery)) != expected_coverage$length["fisheries"] ||
    nrow(weight_data) != expected_coverage$weight["rows"] ||
    length(unique(weight_data$fishery)) != expected_coverage$weight["fisheries"] ||
    nrow(otolith_data) != expected_coverage$otolith["rows"] ||
    length(unique(otolith_data$year)) != expected_coverage$otolith["years"] ||
    length(unique(otolith_data$area)) != expected_coverage$otolith["regions"] ||
    nrow(release_data) != expected_coverage$release["rows"] ||
    length(unique(release_data$rel.group)) != expected_coverage$release["groups"] ||
    nrow(recapture_data) != expected_coverage$recapture["rows"] ||
    nrow(n_output) != expected_coverage$natage["rows"] ||
    nrow(f_output) != expected_coverage$f["rows"] ||
    nrow(catch_output) != expected_coverage$catch["rows"] ||
    nrow(cpue_output) != expected_coverage$cpue_output["rows"] ||
    nrow(biomass_data) != expected_coverage$biomass["rows"] ||
    nrow(summary_output) != expected_coverage$summary["rows"] ||
    nrow(biology_data) != expected_coverage$biology["rows"]) {
  stop("Pinned input or output coverage differs from the reviewed 2023 model.",
    call. = FALSE)
}
if (!identical(range(cpue_data$year), c(1952L, 2021L)) ||
    !identical(range(cpue_data$season), c(1L, 4L)) ||
    !identical(range(length_data$length), c(10L, 198L)) ||
    any(!length_data$length %in% seq.int(10L, 198L, by = 2L)) ||
    !identical(range(weight_data$weight), c(1L, 200L)) ||
    any(!weight_data$weight %in% 1:200) ||
    !identical(range(otolith_data$age), c(1L, 40L)) ||
    !identical(range(otolith_data$season), c(1L, 4L)) ||
    !identical(range(n_output$year), c(1952L, 2021L)) ||
    !identical(range(n_output$age), c(1L, 40L)) ||
    length(unique(n_output$area)) != 9L ||
    !identical(range(f_output$year), c(1952L, 2021L)) ||
    !identical(range(f_output$age), c(1L, 40L)) ||
    any(!is.finite(length_data$freq) | length_data$freq < 0) ||
    any(!is.finite(weight_data$freq) | weight_data$freq < 0) ||
    any(!is.finite(otolith_data$length)) || any(!is.finite(otolith_data$age))) {
  stop("Pinned source years, classes, or native values failed validation.",
    call. = FALSE)
}

index_frq <- frq_data[frq_data$fishery >= 33L, , drop = FALSE]
if (nrow(index_frq) != nrow(cpue_data) || any(index_frq$effort <= 0) ||
    any(index_frq$cpue_penalty <= 0)) {
  stop("Index-fishery records lack matching effort or positive native penalty values.",
    call. = FALSE)
}
index_frq$season <- as.integer((1 + index_frq$month) / 3)
index_key <- paste(index_frq$year, index_frq$season, index_frq$fishery, sep = "_")
cpue_key <- paste(cpue_data$year, cpue_data$season, cpue_data$fishery, sep = "_")
index_match <- match(cpue_key, index_key)
if (anyNA(index_match) || anyDuplicated(index_key) ||
    max(abs(cpue_data$index - index_frq$catch[index_match] /
      index_frq$effort[index_match] / 1e6)) > 1e-10) {
  stop("TAF CPUE values do not match the native catch/effort transformation.",
    call. = FALSE)
}

candidate_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
stocks_path <- file.path(root, "database/stocks.csv")
assessments_path <- file.path(root, "database/assessments.csv")
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
stocks <- read_table(stocks_path)
assessments <- read_table(assessments_path)
candidates <- read_table(candidate_path)
inventory <- read_table(inventory_path)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || stock_id %in% stocks$stock_id ||
    assessment_id %in% assessments$assessment_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started") {
  stop("Expected one eligible, unimported WCPO bigeye candidate.", call. = FALSE)
}
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
if (inventory$import_status[inventory_row] != "not_started") {
  stop("The WCPO bigeye candidate inventory unit has already been imported.",
    call. = FALSE)
}

input_columns <- names(read.csv(file.path(root, "database/inputs.csv"),
  nrows = 0L, check.names = FALSE))
output_columns <- names(read.csv(file.path(root, "database/outputs.csv"),
  nrows = 0L, check.names = FALSE))
assumption_columns <- names(read.csv(file.path(root, "database/assumptions.csv"),
  nrows = 0L, check.names = FALSE))
expected_input_columns <- c(
  "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age", "value", "unit",
  "sampling_time", "source_type", "source_reference", "transformation", "notes",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin"
)
expected_output_columns <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group", "value", "se", "lwr", "upr",
  "unit", "source_type", "source_reference", "notes", "scenario"
)
if (!identical(input_columns, expected_input_columns) ||
    !identical(output_columns, expected_output_columns) ||
    !identical(assumption_columns, c("assessment_id", "component", "fleet",
      "survey", "sex", "region", "season", "setting", "value",
      "source_reference", "notes"))) {
  stop("Unexpected canonical database schema.", call. = FALSE)
}

new_input <- function(type, measure, basis, value, unit, year,
    year_basis = "calendar_year", age = NA_real_, fleet = NA_character_,
    survey = NA_character_, region = NA_character_, season = NA_character_,
    sampling_time = NA_real_, observation_id = NA_character_,
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = NA_real_, partition = NA_real_, weight_bin = NA_real_,
    source_reference, transformation = "", notes = "") {
  n <- length(value)
  rep_n <- function(x) rep(x, length.out = n)
  data.frame(
    assessment_id = rep(assessment_id, n), type = rep_n(type),
    measure = rep_n(measure), basis = rep_n(basis), fleet = rep_n(fleet),
    survey = rep_n(survey), sex = NA_character_, region = rep_n(region),
    season = rep_n(season), year = rep_n(year), year_basis = rep_n(year_basis),
    age = rep_n(age), value = value, unit = rep_n(unit),
    sampling_time = rep_n(sampling_time), source_type = "native_model",
    source_reference = rep_n(source_reference), transformation = rep_n(transformation),
    notes = rep_n(notes), observation_id = rep_n(observation_id),
    length_bin = rep_n(length_bin), length_bin_lower = rep_n(length_bin_lower),
    length_bin_upper = rep_n(length_bin_upper), sample_size = rep_n(sample_size),
    age_error = rep_n(age_error), partition = rep_n(partition),
    weight_bin = rep_n(weight_bin), stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

new_output <- function(type, measure, value, unit, year = NA_integer_,
    age = NA_real_, age_group = NA_character_, fleet = NA_character_,
    survey = NA_character_, region = NA_character_, season = NA_character_,
    scenario = NA_character_, source_reference, notes = "") {
  n <- length(value)
  rep_n <- function(x) rep(x, length.out = n)
  data.frame(
    assessment_id = rep(assessment_id, n), type = rep_n(type),
    measure = rep_n(measure), fleet = rep_n(fleet), survey = rep_n(survey),
    sex = NA_character_, region = rep_n(region), season = rep_n(season),
    year = rep_n(year), age = rep_n(age), age_group = rep_n(age_group),
    value = value, se = NA_real_, lwr = NA_real_,
    upr = NA_real_, unit = rep_n(unit), source_type = "native_model",
    source_reference = rep_n(source_reference), notes = rep_n(notes),
    scenario = rep_n(scenario),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

fishery_identity <- function(fishery, field) {
  fishery_lookup[[field]][match(fishery, fishery_lookup$fishery)]
}
fishery_type <- function(fishery) {
  ifelse(fishery_identity(fishery, "flag") == "IDX", "index", "catch")
}
fishery_dim <- function(fishery, dimension) {
  if (dimension == "fleet") {
    ifelse(fishery_type(fishery) == "catch",
      fishery_identity(fishery, "code"), NA_character_)
  } else {
    ifelse(fishery_type(fishery) == "index",
      fishery_identity(fishery, "code"), NA_character_)
  }
}
fishery_region <- function(fishery) fishery_identity(fishery, "region")

catch_data <- frq_data[frq_data$fishery <= 32L, , drop = FALSE]
catch_flag <- catch_flags[catch_data$fishery]
catch_inputs <- new_input(
  type = "catch",
  measure = ifelse(catch_flag == 0L, "catch_numbers", "catch_biomass"),
  basis = ifelse(catch_flag == 0L, "numbers", "biomass"),
  value = catch_data$catch,
  unit = ifelse(catch_flag == 0L, "fish", "metric tonnes"),
  year = catch_data$year,
  fleet = fishery_dim(catch_data$fishery, "fleet"),
  region = fishery_region(catch_data$fishery),
  season = season_label(catch_data$season),
  observation_id = paste0("bet_catch_y", catch_data$year, "_m",
    catch_data$month, "_w", catch_data$week, "_f", catch_data$fishery),
  source_reference = "MFCL bet.frq, fishery-data fields year-month-week-fishery-catch",
  transformation = "Preserved the source catch scale and applied the fishery-specific number/weight flag.",
  notes = "WCPFC 2023 report Section 4.5 states longline catches are numbers of fish and other extraction catches are metric tonnes."
)

effort_data <- frq_data[is.finite(frq_data$effort) & frq_data$effort >= 0, , drop = FALSE]
effort_gear <- fishery_identity(effort_data$fishery, "gear")
effort_unit <- ifelse(effort_gear == "LL", "hooks per set",
  ifelse(effort_gear %in% c("PS.ASS", "PS.UNA", "PS"),
    "sets (set type is fishery-specific)",
    ifelse(effort_gear == "PL", "vessel fishing days",
      "native effort scale")))
effort_inputs <- new_input(
  type = "covariate", measure = "effort", basis = "native_covariate",
  value = effort_data$effort, unit = effort_unit, year = effort_data$year,
  fleet = fishery_dim(effort_data$fishery, "fleet"),
  survey = fishery_dim(effort_data$fishery, "survey"),
  region = fishery_region(effort_data$fishery),
  season = season_label(effort_data$season),
  observation_id = paste0("bet_effort_y", effort_data$year, "_m",
    effort_data$month, "_w", effort_data$week, "_f", effort_data$fishery),
  source_reference = "MFCL bet.frq, fishery-data effort field",
  transformation = "Preserved non-negative effort values; omitted the source -1 missing-value codes.",
  notes = "Effort units vary by fishery. The assessment uses some effort series for projections; index-fishery effort also supplies the native CPUE calculation."
)

cpue_id <- paste0("bet_cpue_y", cpue_data$year, "_q", cpue_data$season,
  "_f", cpue_data$fishery)
cpue_inputs <- new_input(
  type = "index", measure = "relative_abundance_index", basis = "index_scale",
  value = cpue_data$index, unit = "relative CPUE index",
  year = cpue_data$year,
  survey = fishery_identity(cpue_data$fishery, "code"),
  region = region_label(cpue_data$area), season = season_label(cpue_data$season),
  sampling_time = (cpue_data$season - 0.5) / 4,
  observation_id = cpue_id,
  source_reference = "TAF/data/cpue.csv; derived from bet.frq index catch and effort",
  transformation = "Preserved the source CPUE value, computed as catch / effort / 1e6.",
  notes = "Nine regional standardized longline indices are quarterly relative-abundance observations; sampling_time is the model-quarter midpoint, not an exact survey date."
)
cpue_weight_inputs <- new_input(
  type = "index", measure = "observation_likelihood_weight", basis = "relative_scale",
  value = index_frq$cpue_penalty[index_match], unit = "native MFCL CPUE penalty",
  year = cpue_data$year,
  survey = fishery_identity(cpue_data$fishery, "code"),
  region = region_label(cpue_data$area), season = season_label(cpue_data$season),
  sampling_time = (cpue_data$season - 0.5) / 4,
  observation_id = cpue_id,
  source_reference = "MFCL bet.frq, field 7 (cpue_penalty)",
  transformation = "Preserved the field as supplied without conversion.",
  notes = "The field is named cpue_penalty, but its exact effect is not documented in the report; it is not interpreted here as a CV or standard error."
)

composition_notes <- paste(
  "Native MFCL frequency values are preserved without normalization.",
  "Extraction frequencies are weighted by catch and index-fishery frequencies by standardized CPUE.",
  "sample_size is left blank because the TAF input export does not provide a separate unweighted sample count."
)
composition_rows <- function(data, measure, bin_field, source_reference, bin_unit) {
  fishery <- data$fishery
  bin <- data[[bin_field]]
  common <- list(
    type = fishery_type(fishery), measure = measure, basis = "native_frequency",
    value = data$freq, unit = "native MFCL frequency", year = data$year,
    fleet = fishery_dim(fishery, "fleet"), survey = fishery_dim(fishery, "survey"),
    region = fishery_region(fishery), season = season_label(data$season),
    observation_id = paste0("bet_", if (measure == "frequency_at_length") "lf" else "wf",
      "_y", data$year, "_q", data$season, "_f", fishery),
    sample_size = NA_real_, source_reference = source_reference,
    transformation = "Preserved the preprocessed MFCL frequency values as supplied.",
    notes = paste(composition_notes, bin_unit)
  )
  if (measure == "frequency_at_length") {
    common$length_bin <- bin
  } else {
    common$weight_bin <- bin
  }
  do.call(new_input, common)
}
length_inputs <- composition_rows(length_data, "frequency_at_length", "length",
  "TAF/data/length_comps.csv; 95 two-centimetre classes",
  "Length bins are 10-12 cm through 198-200 cm; length_bin stores the lower bound.")
weight_inputs <- composition_rows(weight_data, "frequency_at_weight", "weight",
  "TAF/data/weight_comps.csv; 200 one-kilogram classes",
  "Weight bins are 0-1 kg through 199-200 kg; weight_bin 1 is 0-1 kg.")

age_length_counts <- aggregate(rep.int(1L, nrow(otolith_data)),
  by = otolith_data[c("year", "season", "area", "age", "length")], FUN = sum)
names(age_length_counts)[names(age_length_counts) == "x"] <- "count"
age_length_sample <- aggregate(count ~ year + season + area + length,
  data = age_length_counts, FUN = sum)
age_length_key <- function(data) paste(data$year, data$season, data$area,
  data$length, sep = "_")
age_length_counts$sample_size <- age_length_sample$count[
  match(age_length_key(age_length_counts), age_length_key(age_length_sample))]
age_length_inputs <- new_input(
  type = "biology", measure = "conditional_frequency_at_age",
  basis = "native_frequency", value = age_length_counts$count, unit = "aged fish",
  year = age_length_counts$year, age = age_length_counts$age,
  region = region_label(age_length_counts$area),
  season = season_label(age_length_counts$season),
  observation_id = paste0("bet_alk_y", age_length_counts$year, "_q",
    age_length_counts$season, "_r", age_length_counts$area),
  length_bin_lower = age_length_counts$length,
  length_bin_upper = age_length_counts$length + 2,
  sample_size = age_length_counts$sample_size,
  source_reference = "TAF/data/otoliths.csv; derived from MFCL bet.age_length",
  transformation = "Aggregated expanded individual observations to native age-by-length counts; did not pool years or regions.",
  notes = "These conditional age-at-length samples inform growth; ages are MFCL quarterly age-class codes 1-40, not a marginal catch or abundance composition."
)

release_id <- paste0("bet_tag_release_g", release_data$rel.group, "_",
  release_data$program, "_y", release_data$year, "_q", release_data$season,
  "_r", release_data$area)
tag_release_inputs <- new_input(
  type = "tag", measure = "tag_release_frequency_at_length",
  basis = "native_frequency", value = release_data$lendist,
  unit = "native MFCL release-frequency scale", year = release_data$year,
  region = region_label(release_data$area), season = season_label(release_data$season),
  observation_id = release_id, length_bin = release_data$length,
  source_reference = "TAF/data/tag_releases.csv; bet.tag release groups",
  transformation = "Preserved source lendist values and release group dimensions.",
  notes = "The TAF export does not identify lendist as an unweighted number of tags; no count or multiplier is inferred."
)
recapture_area <- fishery_identity(recapture_data$rec.fishery, "region")
recapture_id <- paste0("bet_tag_g", recapture_data$rel.group, "_",
  recapture_data$program, "_release_y", recapture_data$rel.year, "_q",
  recapture_data$rel.season, "_r", recapture_data$rel.area, "_l",
  recapture_data$rel.length)
tag_recapture_inputs <- new_input(
  type = "tag", measure = "tag_recapture_count", basis = "numbers",
  value = recapture_data$rec.number, unit = "tag recaptures",
  year = recapture_data$rec.year,
  fleet = fishery_identity(recapture_data$rec.fishery, "code"),
  region = recapture_area, season = season_label(recapture_data$rec.season),
  observation_id = recapture_id, length_bin = recapture_data$rel.length,
  source_reference = "TAF/data/tag_recaptures.csv; bet.tag recapture records",
  transformation = "Preserved reported recapture counts and linked each to its source release group.",
  notes = "The source length code is release length; recapture fleet and area are mapped from the pinned fisheries table."
)

reference <- paste0("WCPFC-SC19-2023/SA-WP-05 and pinned 2023 diagnostic TAF output; ",
  revision)
diagnostic_notes <- paste(
  "Point estimates are from the diagnostic reference fit, not the 54-model advice grid.",
  "The TAF output does not provide standard errors or confidence intervals."
)
age_group <- "quarterly age class"
region_label_for_output <- region_label
outputs <- rbind(
  new_output("population", "numbers_at_age", n_output$n, "fish",
    year = n_output$year, age = n_output$age, age_group = age_group,
    region = region_label_for_output(n_output$area), season = season_label(n_output$season),
    source_reference = "TAF/output/natage.csv", notes = paste(
      diagnostic_notes, "Age values 1-40 are quarterly model age-class codes.")),
  new_output("mortality", "fishing_mortality_at_age", f_output$f, "per year",
    year = f_output$year, age = f_output$age, age_group = age_group,
    region = region_label_for_output(f_output$area),
    source_reference = "TAF/output/f_annual.csv", notes = paste(
      diagnostic_notes, "F is annualized; age values 1-40 are quarterly model age-class codes.")),
  new_output("biology", "growth_length_at_age", biology_data$length, "cm",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived length-at-age surface; no year-specific or uncertainty values are provided."),
  new_output("biology", "weight_at_age", biology_data$weight, "kg per fish",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived weight-at-age surface; no year-specific or uncertainty values are provided."),
  new_output("biology", "maturity_at_age", biology_data$maturity, "proportion",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived maturity surface; the reported spawning biomass definition is retained separately."),
  new_output("mortality", "natural_mortality_at_age", biology_data$natmort, "per year",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived Lorenzen natural-mortality surface; no year-specific or uncertainty values are provided."),
  new_output("biomass", "spawning_potential_biomass", biomass_data$sb, "metric tonnes",
    year = biomass_data$year, region = region_label_for_output(biomass_data$area),
    season = season_label(biomass_data$season),
    source_reference = "TAF/output/biomass.csv, native field sb",
    notes = paste(diagnostic_notes, "Preserved the model's reproductive-weighted SB definition; not assumed to be conventional SSB.")),
  new_output("catch", "predicted_catch",
    catch_output$catch[catch_output$fishery <= 32L], "metric tonnes",
    year = catch_output$year[catch_output$fishery <= 32L],
    fleet = fishery_identity(catch_output$fishery[catch_output$fishery <= 32L], "code"),
    region = region_label_for_output(catch_output$area[catch_output$fishery <= 32L]),
    season = season_label(catch_output$season[catch_output$fishery <= 32L]),
    source_reference = "TAF/output/catch.csv, extraction fisheries 1-32",
    notes = paste(diagnostic_notes, "Index-fishery pseudo-catch rows are excluded.")),
  new_output("index", "predicted_index", cpue_output$pred, "relative CPUE index",
    year = cpue_output$year,
    survey = fishery_identity(cpue_output$fishery, "code"),
    region = region_label_for_output(cpue_output$area),
    season = season_label(cpue_output$season),
    source_reference = "TAF/output/cpue.csv, field pred",
    notes = paste(diagnostic_notes, "Predictions share the source CPUE scale.")),
  new_output("recruitment", "recruitment", summary_output$rec, "fish",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field rec",
    notes = diagnostic_notes),
  new_output("catch", "predicted_catch", summary_output$catch, "metric tonnes",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field catch",
    notes = paste(diagnostic_notes, "Annual aggregate catch across extraction fisheries.")),
  new_output("biomass", "total_biomass", summary_output$tb, "metric tonnes",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field tb",
    notes = diagnostic_notes),
  new_output("biomass", "spawning_potential_biomass", summary_output$sb, "metric tonnes",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field sb",
    notes = paste(diagnostic_notes, "Preserved the model's reproductive-weighted SB definition; not assumed to be conventional SSB.")),
  new_output("biomass", "unfished_spawning_potential_biomass", summary_output$sbf0, "metric tonnes",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field sbf0",
    notes = paste(diagnostic_notes, "SB at F=0, using the source reproductive-potential definition.")),
  new_output("biomass", "spawning_output_ratio_to_unfished", summary_output$dep, "ratio",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field dep",
    notes = paste(diagnostic_notes, "Native SB/SBF=0 ratio.")),
  new_output("mortality", "mean_fishing_mortality", summary_output$f, "per year",
    year = summary_output$year, source_reference = "TAF/output/summary.csv, field f",
    notes = paste(diagnostic_notes, "Native annual mean fishing-mortality summary."))
)

input_rows <- rbind(catch_inputs, effort_inputs, cpue_inputs, cpue_weight_inputs,
  length_inputs, weight_inputs, age_length_inputs, tag_release_inputs,
  tag_recapture_inputs)

new_assumption <- function(component, setting, value, source_reference, notes,
    fleet = NA_character_, survey = NA_character_, region = NA_character_,
    season = NA_character_) {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = NA_character_, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
assumptions <- do.call(rbind, list(
  new_assumption("model structure", "time_step", "quarterly; four model seasons per year",
    "WCPFC-SC19-2023/SA-WP-05, Sections 4.5-4.6; bet.ini",
    "The TAF season code is 1-4 and uses quarter-year model steps."),
  new_assumption("model structure", "age_classes", "40 quarterly age-class codes",
    "WCPFC-SC19-2023/SA-WP-05; bet.ini; TAF/output/natage.csv",
    "Source age codes 1-40 are quarterly classes and are not 40 annual ages."),
  new_assumption("model structure", "spatial_regions", "9 MFCL regions",
    "TAF/data/fisheries.csv; TAF/output/natage.csv",
    "Numeric area codes are preserved as MFCL region labels."),
  new_assumption("fisheries", "fishery_structure", "41 total: 32 extraction and 9 index fisheries",
    "WCPFC-SC19-2023/SA-WP-05, Sections 4.5.1-4.5.3; TAF/data/fisheries.csv",
    "Extraction fleet names and index-fishery identities are retained from the native fisheries table."),
  new_assumption("catch", "catch_units", "Longline catch in fish numbers; other extraction catch in metric tonnes",
    "WCPFC-SC19-2023/SA-WP-05, Section 4.5.1; bet.frq data flags",
    "The fishery-specific native number/weight flags are applied without rescaling."),
  new_assumption("effort", "effort_units", "Fleet-specific: hooks per set, sets, vessel fishing days, or native scale",
    "WCPFC-SC19-2023/SA-WP-05, Sections 4.5.1-4.5.4; bet.frq",
    "Negative -1 missing-value codes are omitted; the remaining source values are not converted."),
  new_assumption("index", "index_definition", "Nine quarterly regional standardized longline relative-abundance indices",
    "WCPFC-SC19-2023/SA-WP-05, Section 4.5.3; TAF/data/cpue.csv",
    "TAF values are catch divided by effort and 1e6; the assessment report describes constant catchability shared across regions."),
  new_assumption("index", "cpue_penalty_field", "Retained as observation_likelihood_weight; exact effect unresolved",
    "MFCL bet.frq, field 7; WCPFC-SC19-2023/SA-WP-05, Section 5.5.1",
    "The native field is named cpue_penalty. It is preserved without interpreting it as a CV or standard error."),
  new_assumption("composition", "size_frequency_weighting", "Extraction frequencies weighted by catch; index frequencies by standardized CPUE",
    "WCPFC-SC19-2023/SA-WP-05, Sections 4.5.3 and 4.6; TAF/data/length_comps.csv; TAF/data/weight_comps.csv",
    "Length classes are 95 two-centimetre bins; weight classes are 200 one-kilogram bins. Sample sizes are not separately available in the TAF exports."),
  new_assumption("composition", "size_likelihood", "Robust-normal size-composition likelihood; effective sample size capped at 1,000 and further down-weighted",
    "WCPFC-SC19-2023/SA-WP-05, Sections 4.6 and 5.5.2",
    "Canonical frequencies are preserved before any additional analysis-specific transformation."),
  new_assumption("age data", "conditional_age_at_length", "1,010 conditional samples from 14 years, four quarters, and eight regions; used for growth",
    "TAF/data/otoliths.csv; bet.age_length; WCPFC-SC19-2023/SA-WP-05",
    "These are not marginal catch-at-age or age-specific abundance observations."),
  new_assumption("tagging", "tag_likelihood", "Tag-recapture data fitted with a negative-binomial likelihood",
    "TAF/data/tag_releases.csv; TAF/data/tag_recaptures.csv; WCPFC-SC19-2023/SA-WP-05, Sections 4.7 and 5.5",
    "Release frequencies and recapture counts are retained in their native representation."),
  new_assumption("natural mortality", "age_pattern", "Lorenzen age-dependent M estimated within the model",
    "WCPFC-SC19-2023/SA-WP-05, Section 5.2.5; TAF/output/biology.csv",
    "The model-derived natural-mortality surface is stored as an output, not an observed input."),
  new_assumption("assessment outputs", "advice_basis", "Official advice used a 54-model grid; imported outputs are from the single diagnostic reference fit",
    "WCPFC-SC19-2023/SA-WP-05; SC19 Outcomes; pinned diagnostic repository",
    "Diagnostic point estimates are not substituted for the grid distribution or its uncertainty.")
))

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "WCPFC / SPC", authority_stock_id = "Western and Central Pacific bigeye tuna",
  scientific_name = "Thunnus obesus", common_name = "WCPO bigeye tuna",
  area = "Western and Central Pacific Ocean", region = "WCPFC Convention Area; 9 MFCL regions",
  ocean = "Western and Central Pacific",
  notes = "NOAA Stock SMART ID 11684 is retained only as a discovery cross-reference; assessment authority is WCPFC with SPC model inputs.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2023L,
  terminal_year = 2021L, estimate_terminal_year = 2021L,
  assessment_type = "full_assessment", model_family = "MULTIFAN-CL",
  model_version = "2023 diagnostic reference fit",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2023L,
  assessment_url = "https://meetings.wcpfc.int/node/19353",
  framework_url = NA_character_, data_url = "https://meetings.wcpfc.int/node/19353",
  model_url = paste0("https://github.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/tree/", revision),
  repository_url = paste0("https://github.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/tree/", revision),
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("The 2023 production assessment through 2021 is the latest accepted advice basis.",
    "The 2026 assessment was not accepted at SC22 because there was no consensus on its uncertainty grid.",
    "This import contains diagnostic-reference point estimates, not the 54-model grid or uncertainty."),
  stringsAsFactors = FALSE
)

schema_rows <- list(
  "stocks.csv" = stock, "assessments.csv" = assessment,
  "assumptions.csv" = assumptions, "inputs.csv" = input_rows,
  "outputs.csv" = outputs
)
for (name in names(schema_rows)) {
  header <- names(read.csv(file.path(root, "database", name), nrows = 0L,
    stringsAsFactors = FALSE, check.names = FALSE))
  if (!identical(header, names(schema_rows[[name]]))) {
    stop("Unexpected columns in database/", name, call. = FALSE)
  }
}
if (sum(input_rows$measure == "catch_numbers") != 3100L ||
    sum(input_rows$measure == "catch_biomass") != 3235L ||
    sum(input_rows$measure == "relative_abundance_index") != 2520L ||
    sum(input_rows$measure == "frequency_at_length") != 96235L ||
    sum(input_rows$measure == "frequency_at_weight") != 707200L ||
    sum(input_rows$measure == "tag_release_frequency_at_length") != 11210L ||
    sum(input_rows$measure == "tag_recapture_count") != 2892L ||
    sum(outputs$measure == "numbers_at_age") != 100800L ||
    sum(outputs$measure == "fishing_mortality_at_age") != 28000L ||
    sum(outputs$measure == "predicted_index") != 2520L ||
    sum(outputs$measure == "spawning_potential_biomass") != 2590L) {
  stop("Constructed data rows differ from the reviewed source coverage.", call. = FALSE)
}
cat("Prepared WCPO bigeye import: ", nrow(assumptions), " assumptions, ",
  nrow(input_rows), " inputs, and ", nrow(outputs), " outputs.\n", sep = "")
if (dry_run) quit(save = "no", status = 0L)

append_csv_rows <- function(name, rows) {
  path <- file.path(root, "database", name)
  if (!file.exists(path) || !nrow(rows)) stop("Missing source table or rows: ", name,
    call. = FALSE)
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  if (!identical(header, names(rows))) stop("Unexpected columns in ", name,
    call. = FALSE)
  size <- file.info(path)$size
  con <- file(path, open = "rb")
  seek(con, where = max(0, size - 2), origin = "start")
  ending <- readBin(con, what = "raw", n = min(2, size))
  close(con)
  eol <- if (length(ending) == 2L && identical(ending, as.raw(c(13L, 10L)))) "\r\n" else "\n"
  if (!length(ending) || tail(ending, 1L) != as.raw(10L)) {
    append_con <- file(path, open = "ab")
    writeBin(charToRaw(eol), append_con)
    close(append_con)
  }
  write.table(rows, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = eol, append = TRUE)
}

append_csv_rows("stocks.csv", stock)
append_csv_rows("assessments.csv", assessment)
append_csv_rows("assumptions.csv", assumptions)
append_csv_rows("inputs.csv", input_rows)
append_csv_rows("outputs.csv", outputs)

candidates$matched_stock_id[candidate_row] <- stock_id
candidates$match_status[candidate_row] <- "matched"
candidates$import_status[candidate_row] <- "partial"
candidates$review_date[candidate_row] <- "2026-11-13"
candidates$catch_age_evidence[candidate_row] <- paste(
  "The native assessment inputs include 6,335 fishery catch records, length/weight frequencies, and 1,010 conditional age-at-length observations.",
  "The age samples inform growth and are not marginal catch-at-age observations; no catch-at-age reconstruction was added."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Nine quarterly regional standardized longline CPUE series are imported as aggregate relative-abundance indices.",
  "No age-specific abundance index is supplied."
)
candidates$weights_evidence[candidate_row] <- paste(
  "Native length/weight frequency likelihood inputs and the model-derived weight-at-age output are preserved.",
  "The output biology surface is not an independent observed weight-at-age input."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "The diagnostic fit provides a model-derived maturity-at-age surface; no independent observed maturity-at-age input was recovered."
)
candidates$mortality_evidence[candidate_row] <- paste(
  "Natural mortality is estimated within the model using an age-dependent Lorenzen form; its diagnostic fitted surface is imported as output."
)
candidates$timing_evidence[candidate_row] <- paste(
  "Catch, CPUE, composition, and tagging records preserve quarterly model seasons.",
  "CPUE sampling_time is the model-quarter midpoint, not an exact survey date."
)
candidates$output_evidence[candidate_row] <- paste(
  "The pinned diagnostic reference fit provides recruitment, total and spawning-potential biomass, N-at-age, F-at-age, fitted M-at-age, predicted catch, and CPUE predictions through 2021.",
  "No standard errors are exported, and these outputs are not the official 54-model advice grid."
)
candidates$notes[candidate_row] <- paste(
  candidates$notes[candidate_row],
  "A partial source import was added under wcpfc_wcpo_bigeye_2023.",
  "See discovery/source_reviews/noaa_wcpfc_bigeye_2023.md for imported coverage and remaining limits."
)
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)

inventory$matched_stock_id[inventory_row] <- stock_id
inventory$match_status[inventory_row] <- "matched"
inventory$import_status[inventory_row] <- "partial"
replace_csv_register_row(inventory_path, inventory_row,
  inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])

cat("Imported partial WCPFC 2023 WCPO bigeye source data.\n")
