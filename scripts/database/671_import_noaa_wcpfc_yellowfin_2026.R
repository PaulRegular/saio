root <- "."
stock_id <- "wcpfc_wcpo_yellowfin"
assessment_id <- "wcpfc_wcpo_yellowfin_2026"
candidate_id <- "NOAA:11694"
cache_name <- "discovery_noaa_wcpo_yellowfin_2026"
revision <- "b00a02f3537ef54520b219488f899188ea6eff3f"
dry_run <- identical(Sys.getenv("SAIO_SOURCE_DRY_RUN"), "1")

.libPaths(c(file.path(root, "source_cache/.Rlib"), .libPaths()))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache_options <- c(
  file.path(root, "source_cache", cache_name),
  file.path(dirname(dirname(normalizePath(root))), cache_name)
)
cache_options <- cache_options[dir.exists(cache_options)]
if (!length(cache_options)) stop("Pinned WCPO yellowfin cache is required.", call. = FALSE)
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
  "WCPFC-SC22-2026-SA-WP05_Rev01_YFT_2026.pdf",
  "WCPFC-SC22-2026-SA-IP03_Rev01_BET_YFT_inputs.pdf",
  "SPC_README.md", "TAF_data.R", "MFCL_12.par", "MFCL_yft.age_length",
  "MFCL_yft.frq", "MFCL_yft.ini", "MFCL_yft.reg_scaling", "MFCL_yft.tag",
  "TAF_data_cpue.csv", "TAF_data_fisheries.csv", "TAF_data_length_comps.csv",
  "TAF_data_otoliths.csv", "TAF_data_reg_scale.csv", "TAF_data_tag_recaptures.csv",
  "TAF_data_tag_releases.csv", "TAF_output_batage.csv", "TAF_output_biology.csv",
  "TAF_output_biomass.csv", "TAF_output_catch.csv", "TAF_output_cpue.csv",
  "TAF_output_f_annual.csv", "TAF_output_natage.csv", "TAF_output_summary.csv"
)
manifest_row <- match(required_files, manifest$file)
if (!all(c("file", "url", "retrieved_on", "bytes", "sha256", "revision") %in% names(manifest)) ||
    anyDuplicated(manifest$file) || anyNA(manifest_row)) {
  stop("The pinned 2026 source manifest is incomplete.", call. = FALSE)
}
for (i in seq_along(required_files)) {
  name <- required_files[i]
  path <- file.path(cache, name)
  row <- manifest_row[i]
  if (!file.exists(path) || file.info(path)$size != as.numeric(manifest$bytes[row]) ||
      sha256_file(path) != tolower(manifest$sha256[row])) {
    stop("Cached WCPO yellowfin source failed provenance validation: ", name,
      call. = FALSE)
  }
}
repo_urls <- manifest$url[grepl(paste0(
  "raw.githubusercontent.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/",
  revision, "/"), manifest$url, fixed = TRUE)]
if (length(repo_urls) != 27L) {
  stop("The diagnostic model files are not pinned to the reviewed repository revision.",
    call. = FALSE)
}

read_source <- function(name) read.csv(file.path(cache, name),
  stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA"))

fishery_data <- read_source("TAF_data_fisheries.csv")
cpue_data <- read_source("TAF_data_cpue.csv")
length_data <- read_source("TAF_data_length_comps.csv")
otolith_data <- read_source("TAF_data_otoliths.csv")
reg_scale_data <- read_source("TAF_data_reg_scale.csv")
release_data <- read_source("TAF_data_tag_releases.csv")
recapture_data <- read_source("TAF_data_tag_recaptures.csv")
biology_data <- read_source("TAF_output_biology.csv")
biomass_data <- read_source("TAF_output_biomass.csv")
catch_output <- read_source("TAF_output_catch.csv")
cpue_output <- read_source("TAF_output_cpue.csv")
f_output <- read_source("TAF_output_f_annual.csv")
n_output <- read_source("TAF_output_natage.csv")
summary_output <- read_source("TAF_output_summary.csv")
batage_output <- read_source("TAF_output_batage.csv")

frq_lines <- readLines(file.path(cache, "MFCL_yft.frq"), warn = FALSE)
flag_header <- which(grepl("Data flags (for records 1", frq_lines, fixed = TRUE))
incident_header <- which(grepl("Datasets / LFIntervals", frq_lines, fixed = TRUE))
data_header <- which(grepl("# fishery data", frq_lines, fixed = TRUE))
if (length(flag_header) != 1L || length(incident_header) != 1L ||
    length(data_header) != 1L) {
  stop("Could not identify the required yft.frq sections.", call. = FALSE)
}
catch_flags <- scan(text = frq_lines[flag_header + 1L], what = integer(), quiet = TRUE)
incident_count <- as.integer(scan(text = frq_lines[incident_header + 1L],
  what = numeric(), quiet = TRUE)[1L])
incident_lines <- frq_lines[(data_header + 1L):length(frq_lines)]
incident_lines <- incident_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]",
  incident_lines)]
incident_fields <- strsplit(trimws(incident_lines), "[[:space:]]+")
if (length(incident_lines) != incident_count || any(lengths(incident_fields) < 7L)) {
  stop("Unexpected fishing-incident count or fields in yft.frq.", call. = FALSE)
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

region_label <- function(area) ifelse(as.character(area) == "all",
  "All model areas", paste0("MFCL area ", area))
season_label <- function(season) paste0("model quarter ", season)

if (length(catch_flags) != 36L || nrow(fishery_data) != 36L ||
    !identical(fishery_data$fishery, 1:36) ||
    !identical(catch_flags[1:11], rep.int(0L, 11L)) ||
    !identical(catch_flags[12:31], rep.int(1L, 20L)) ||
    !identical(catch_flags[32:36], rep.int(0L, 5L)) ||
    !all(fishery_data$flag[32:36] == "IDX") ||
    any(fishery_data$flag[1:31] == "IDX") ||
    incident_count != 8225L || any(!frq_data$month %in% c(2L, 5L, 8L, 11L)) ||
    any(!frq_data$fishery %in% 1:36) || any(!is.finite(frq_data$catch)) ||
    any(frq_data$catch < 0)) {
  stop("The pinned yellowfin fishery structure or catch flags differ from the reviewed model.",
    call. = FALSE)
}
if (nrow(cpue_data) != 1452L || length(unique(cpue_data$fishery)) != 5L ||
    !identical(range(cpue_data$year), c(1952L, 2024L)) ||
    !identical(sort(unique(cpue_data$season)), 1:4) ||
    nrow(length_data) != 297920L ||
    !identical(range(length_data$year), c(1956L, 2024L)) ||
    length(unique(length_data$fishery)) != 36L ||
    !identical(range(length_data$length), c(10L, 198L)) ||
    any(!length_data$length %in% seq.int(10L, 198L, by = 2L)) ||
    any(!is.finite(length_data$freq) | length_data$freq < 0) ||
    nrow(otolith_data) != 1873L ||
    length(unique(otolith_data$year)) != 17L ||
    !identical(range(otolith_data$year), c(2006L, 2024L)) ||
    !identical(range(otolith_data$age), c(1L, 40L)) ||
    !identical(range(otolith_data$length), c(14L, 174L)) ||
    length(unique(otolith_data$area)) != 5L ||
    !identical(sort(unique(otolith_data$season)), 1:4) ||
    nrow(reg_scale_data) != 1420L ||
    !identical(range(reg_scale_data$year), c(1954L, 2024L)) ||
    length(unique(reg_scale_data$area)) != 5L ||
    !identical(sort(unique(reg_scale_data$season)), 1:4) ||
    any(!is.finite(reg_scale_data$value) | reg_scale_data$value <= 0) ||
    nrow(release_data) != 13585L || nrow(recapture_data) != 6331L ||
    nrow(n_output) != 58400L ||
    nrow(batage_output) != 58400L ||
    nrow(f_output) != 17520L ||
    nrow(catch_output) != 10512L ||
    nrow(cpue_output) != 1460L || sum(is.na(cpue_output$pred)) != 8L ||
    any(!is.finite(cpue_output$pred[!is.na(cpue_output$pred)])) ||
    nrow(biomass_data) != 1460L ||
    nrow(biology_data) != 40L ||
    nrow(summary_output) != 73L) {
  stop("Pinned yellowfin source row counts or temporal/age coverage differ from the reviewed assessment.",
    call. = FALSE)
}
if (!identical(range(n_output$year), c(1952L, 2024L)) ||
    !identical(range(n_output$age), c(1L, 40L)) ||
    !identical(range(batage_output$year), c(1952L, 2024L)) ||
    !identical(range(batage_output$age), c(1L, 40L)) ||
    !identical(range(f_output$year), c(1952L, 2024L)) ||
    !identical(range(f_output$age), c(1L, 40L)) ||
    !identical(sort(unique(n_output$season)), 1:4) ||
    !identical(sort(unique(cpue_data$season)), 1:4) ||
    !identical(sort(unique(cpue_output$season)), 1:4) ||
    length(unique(n_output$area)) != 5L ||
    length(unique(batage_output$area)) != 5L ||
    length(unique(cpue_output$area)) != 5L ||
    !all(c("age", "length", "weight", "maturity", "natmort") %in% names(biology_data)) ||
    !identical(range(biology_data$age), c(1L, 40L)) ||
    any(!is.finite(otolith_data$length) | !is.finite(otolith_data$age)) ||
    any(!is.finite(reg_scale_data$value)) ||
    any(!is.finite(release_data$lendist) | release_data$lendist < 0) ||
    any(!is.finite(recapture_data$rec.number) | recapture_data$rec.number < 0)) {
  stop("Pinned yellowfin years, classes, or native values failed validation.", call. = FALSE)
}

index_fisheries <- fishery_data$fishery[fishery_data$flag == "IDX"]
index_frq <- frq_data[frq_data$fishery %in% index_fisheries, , drop = FALSE]
index_frq$season <- as.integer((1 + index_frq$month) / 3)
index_key <- paste(index_frq$year, index_frq$season, index_frq$fishery, sep = "_")
cpue_key <- paste(cpue_data$year, cpue_data$season, cpue_data$fishery, sep = "_")
index_match <- match(cpue_key, index_key)
if (nrow(index_frq) != nrow(cpue_data) || anyNA(index_match) ||
    anyDuplicated(index_key) ||
    max(abs(cpue_data$index - index_frq$catch[index_match] /
      index_frq$effort[index_match] / 1e6)) > 1e-10) {
  stop("TAF CPUE values do not match the native catch/effort transformation.",
    call. = FALSE)
}

fishery_lookup <- data.frame(
  fishery = fishery_data$fishery,
  code = fishery_data$code,
  gear = fishery_data$gear_long,
  flag = fishery_data$flag,
  region = region_label(fishery_data$area),
  stringsAsFactors = FALSE
)
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
  stop("Expected one eligible, unimported WCPO yellowfin candidate.", call. = FALSE)
}
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
if (inventory$import_status[inventory_row] != "not_started") {
  stop("The WCPO yellowfin inventory unit has already been imported.", call. = FALSE)
}

input_columns <- names(read.csv(file.path(root, "database/inputs.csv"), nrows = 0L,
  check.names = FALSE))
output_columns <- names(read.csv(file.path(root, "database/outputs.csv"), nrows = 0L,
  check.names = FALSE))
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
    value = value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = rep_n(unit), source_type = "native_model",
    source_reference = rep_n(source_reference), notes = rep_n(notes),
    scenario = rep_n(scenario), stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch_data <- frq_data[frq_data$fishery %in% fishery_data$fishery[
  fishery_data$flag != "IDX"], , drop = FALSE]
catch_flag <- catch_flags[catch_data$fishery]
catch_inputs <- new_input(
  type = "catch",
  measure = ifelse(catch_flag == 0L, "catch_numbers", "catch_biomass"),
  basis = ifelse(catch_flag == 0L, "numbers", "biomass"),
  value = catch_data$catch,
  unit = ifelse(catch_flag == 0L, "fish", "metric tonnes"),
  year = catch_data$year,
  fleet = fishery_dim(catch_data$fishery, "fleet"),
  region = fishery_identity(catch_data$fishery, "region"),
  season = season_label(catch_data$season),
  observation_id = paste0("yft_catch_y", catch_data$year, "_m",
    catch_data$month, "_w", catch_data$week, "_f", catch_data$fishery),
  source_reference = "MFCL_yft.frq, fishery-data fields year-month-week-fishery-catch",
  transformation = "Preserved native catches and applied the fishery-specific number/weight flag.",
  notes = "The 2026 report states longline catches are numbers of fish and all other fishery catches are tonnes."
)

effort_data <- frq_data[is.finite(frq_data$effort) & frq_data$effort >= 0, , drop = FALSE]
effort_gear <- fishery_identity(effort_data$fishery, "gear")
effort_unit <- ifelse(effort_gear == "LL", "hooks per set",
  ifelse(effort_gear %in% c("PS.ASS", "PS.UNA", "PS"),
    "sets (association type is fishery-specific)",
    ifelse(effort_gear == "PL", "vessel fishing days", "native effort scale")))
effort_inputs <- new_input(
  type = "covariate", measure = "effort", basis = "native_covariate",
  value = effort_data$effort, unit = effort_unit, year = effort_data$year,
  fleet = fishery_dim(effort_data$fishery, "fleet"),
  survey = fishery_dim(effort_data$fishery, "survey"),
  region = fishery_identity(effort_data$fishery, "region"),
  season = season_label(effort_data$season),
  observation_id = paste0("yft_effort_y", effort_data$year, "_m",
    effort_data$month, "_w", effort_data$week, "_f", effort_data$fishery),
  source_reference = "MFCL_yft.frq, fishery-data effort field",
  transformation = "Preserved non-negative effort; omitted source -1 missing-value codes.",
  notes = "Effort units vary by fishery. The report identifies longline effort as hooks per set, purse-seine effort as sets, and Japanese pole-and-line effort as vessel fishing days."
)

cpue_id <- paste0("yft_cpue_y", cpue_data$year, "_q", cpue_data$season,
  "_f", cpue_data$fishery)
cpue_inputs <- new_input(
  type = "index", measure = "relative_abundance_index", basis = "index_scale",
  value = cpue_data$index, unit = "relative CPUE index",
  year = cpue_data$year,
  survey = fishery_identity(cpue_data$fishery, "code"),
  region = fishery_identity(cpue_data$fishery, "region"),
  season = season_label(cpue_data$season),
  sampling_time = (cpue_data$season - 0.5) / 4,
  observation_id = cpue_id,
  source_reference = "TAF_data_cpue.csv; derived from MFCL_yft.frq catch and effort",
  transformation = "Preserved TAF index values; verified as catch / effort / 1e6.",
  notes = "Five regional standardized longline indices are quarterly relative-abundance observations; sampling_time is the model-quarter midpoint, not an exact survey date."
)

composition_notes <- paste(
  "Preserved preprocessed MFCL frequency values without renormalization.",
  "Extraction-fishery frequencies are catch-weighted and index-fishery frequencies CPUE-weighted.",
  "sample_size is blank because the TAF export does not contain the unweighted fish count for each composition after preprocessing."
)
length_observation_id <- paste0("yft_length_y", length_data$year, "_q",
  length_data$season, "_f", length_data$fishery)
length_inputs <- new_input(
  type = fishery_type(length_data$fishery),
  measure = "frequency_at_length", basis = "native_frequency",
  value = length_data$freq, unit = "native MFCL length frequency",
  year = length_data$year,
  fleet = fishery_dim(length_data$fishery, "fleet"),
  survey = fishery_dim(length_data$fishery, "survey"),
  region = fishery_identity(length_data$fishery, "region"),
  season = season_label(length_data$season),
  observation_id = length_observation_id,
  length_bin = length_data$length,
  sample_size = NA_real_,
  source_reference = "TAF_data_length_comps.csv; 95 two-centimetre length classes",
  transformation = "Preserved the reweighted MFCL length-frequency values as supplied.",
  notes = paste(composition_notes,
    "length_bin stores the lower bound; source bins are 10–12 cm through 198–200 cm.")
)

age_length_counts <- aggregate(rep.int(1L, nrow(otolith_data)),
  by = otolith_data[c("year", "season", "area", "age", "length")], FUN = sum)
names(age_length_counts)[names(age_length_counts) == "x"] <- "count"
age_length_sample <- aggregate(count ~ year + season + area + length,
  data = age_length_counts, FUN = sum)
age_length_key <- function(data) paste(data$year, data$season, data$area,
  data$length, sep = "_")
age_length_counts$sample_size <- age_length_sample$count[
  match(age_length_key(age_length_counts), age_length_key(age_length_sample))]
caal_id <- function(data) paste0("yft_caal_y", data$year, "_q",
  data$season, "_a", data$area, "_l", data$length)
age_length_inputs <- new_input(
  type = "biology", measure = "conditional_frequency_at_age",
  basis = "native_frequency", value = age_length_counts$count, unit = "aged fish",
  year = age_length_counts$year, age = age_length_counts$age,
  region = region_label(age_length_counts$area),
  season = season_label(age_length_counts$season),
  observation_id = caal_id(age_length_counts),
  length_bin_lower = age_length_counts$length,
  length_bin_upper = age_length_counts$length + 2,
  sample_size = age_length_counts$sample_size,
  source_reference = "TAF_data_otoliths.csv; aggregated from expanded individual MFCL conditional age-at-length observations",
  transformation = "Aggregated individual fish to native age-by-length counts within source year, quarter, and model area.",
  notes = "These are conditional age-at-length observations used to estimate growth, not marginal catch-at-age or age-specific abundance indices. The model's age values 1–40 are quarterly age classes."
)
age_length_weight <- unique(otolith_data[c("year", "season", "area", "length", "ess")])
age_length_weight$observation_id <- caal_id(age_length_weight)
if (anyDuplicated(age_length_weight$observation_id) ||
    anyNA(age_length_weight$ess) || any(age_length_weight$ess <= 0)) {
  stop("CAAL source weights are not unique and positive by observation.", call. = FALSE)
}
caal_weight_inputs <- new_input(
  type = "biology", measure = "observation_likelihood_weight",
  basis = "relative_scale", value = age_length_weight$ess,
  unit = "native MFCL CAAL regional weight",
  year = age_length_weight$year,
  region = region_label(age_length_weight$area),
  season = season_label(age_length_weight$season),
  observation_id = age_length_weight$observation_id,
  source_reference = "TAF_data_otoliths.csv, field ess; MFCL_yft.age_length regional weighting",
  transformation = "Preserved the supplied source field without adjustment.",
  notes = "The report describes region-specific CAAL scalars that adjust effective sample sizes. The source field is named ess; its values are kept as supplied."
)

reg_scale_inputs <- new_input(
  type = "covariate", measure = "regional_scaling_value",
  basis = "native_covariate", value = reg_scale_data$value,
  unit = "native MFCL regional-scaling value",
  year = reg_scale_data$year,
  region = region_label(reg_scale_data$area),
  season = season_label(reg_scale_data$season),
  observation_id = paste0("yft_region_scale_y", reg_scale_data$year,
    "_q", reg_scale_data$season, "_a", reg_scale_data$area),
  source_reference = "TAF_data_reg_scale.csv; MFCL_yft.reg_scaling",
  transformation = "Preserved the native regional-scaling values without conversion.",
  notes = "These values feed the MFCL regional-scaling penalty informed by the global sdmTMB CPUE analysis; they are not direct abundance observations and no physical unit conversion is inferred."
)

release_id <- paste0("yft_tag_release_g", release_data$rel.group, "_",
  release_data$program, "_y", release_data$year, "_q", release_data$season,
  "_a", release_data$area)
tag_release_inputs <- new_input(
  type = "tag", measure = "tag_release_frequency_at_length",
  basis = "native_frequency", value = release_data$lendist,
  unit = "native MFCL release-frequency scale", year = release_data$year,
  region = region_label(release_data$area),
  season = season_label(release_data$season),
  observation_id = release_id, length_bin = release_data$length,
  source_reference = "TAF_data_tag_releases.csv; MFCL_yft.tag release groups",
  transformation = "Preserved source lendist values and release-group dimensions.",
  notes = "The TAF export does not identify lendist as an unweighted number of tags; no count or multiplier is inferred."
)
recapture_id <- paste0("yft_tag_g", recapture_data$rel.group, "_",
  recapture_data$program, "_release_y", recapture_data$rel.year, "_q",
  recapture_data$rel.season, "_a", recapture_data$rel.area, "_l",
  recapture_data$rel.length)
tag_recapture_inputs <- new_input(
  type = "tag", measure = "tag_recapture_count", basis = "numbers",
  value = recapture_data$rec.number, unit = "tag recaptures",
  year = recapture_data$rec.year,
  fleet = fishery_identity(recapture_data$rec.fishery, "code"),
  region = fishery_identity(recapture_data$rec.fishery, "region"),
  season = season_label(recapture_data$rec.season),
  observation_id = recapture_id, length_bin = recapture_data$rel.length,
  source_reference = "TAF_data_tag_recaptures.csv; MFCL_yft.tag recapture records",
  transformation = "Preserved reported recapture counts and linked each to its source release group.",
  notes = "length_bin identifies the source release length; recapture fleet and model area are preserved."
)

diagnostic_notes <- paste(
  "Outputs are from MFCL Model 16 (Diagnostic2026), not the 48-model uncertainty ensemble.",
  "No standard errors or confidence intervals are supplied in the pinned TAF exports."
)
age_group <- "quarterly age class"
cpue_prediction_notes <- ifelse(is.na(cpue_output$pred),
  paste(diagnostic_notes, "Source predicted index is missing; the source blank is retained."),
  paste(diagnostic_notes, "Predictions are on the source regional index scale."))
catch_keep <- catch_output$fishery %in% fishery_data$fishery[
  fishery_data$flag != "IDX"]
outputs <- rbind(
  new_output("population", "numbers_at_age", n_output$n, "fish",
    year = n_output$year, age = n_output$age, age_group = age_group,
    region = region_label(n_output$area), season = season_label(n_output$season),
    source_reference = "TAF_output_natage.csv",
    notes = paste(diagnostic_notes, "Age codes 1–40 are quarterly MFCL classes; class 40 is the plus group.")),
  new_output("mortality", "fishing_mortality_at_age", f_output$f, "per year",
    year = f_output$year, age = f_output$age, age_group = age_group,
    region = region_label(f_output$area),
    source_reference = "TAF_output_f_annual.csv",
    notes = paste(diagnostic_notes, "F is annualized; regional rows and the all-area aggregate are both preserved.")),
  new_output("biology", "mature_biomass_at_age", batage_output$sb, "metric tonnes",
    year = batage_output$year, age = batage_output$age, age_group = age_group,
    region = region_label(batage_output$area), season = season_label(batage_output$season),
    source_reference = "TAF_output_batage.csv; N × weight-at-age × maturity-at-age",
    notes = paste(diagnostic_notes, "The source derives this surface as abundance × weight × maturity; it is not a separately observed biological input.")),
  new_output("biology", "growth_length_at_age", biology_data$length, "cm",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF_output_biology.csv",
    notes = "Model-derived length-at-age surface; age codes 1–40 are quarterly classes."),
  new_output("biology", "weight_at_age", biology_data$weight, "kg per fish",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF_output_biology.csv",
    notes = "Model-derived weight-at-age surface; growth and weights are invariant by region and year."),
  new_output("biology", "maturity_at_age", biology_data$maturity, "proportion",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF_output_biology.csv",
    notes = "Model-derived maturity-at-age surface; the source's spawning-biomass definition is preserved separately."),
  new_output("mortality", "natural_mortality_at_age", biology_data$natmort, "per year",
    age = biology_data$age, age_group = age_group,
    source_reference = "TAF_output_biology.csv",
    notes = "Model-derived Lorenzen natural-mortality surface; no uncertainty values are supplied."),
  new_output("biomass", "spawning_potential_biomass", biomass_data$sb, "metric tonnes",
    year = biomass_data$year, region = region_label(biomass_data$area),
    season = season_label(biomass_data$season),
    source_reference = "TAF_output_biomass.csv, source field sb",
    notes = paste(diagnostic_notes, "Source spawning-biomass definition is retained; no conventional Fbar or alternative weight definition is inferred.")),
  new_output("catch", "predicted_catch", catch_output$catch[catch_keep],
    ifelse(catch_flags[catch_output$fishery[catch_keep]] == 0L,
      "fish", "metric tonnes"),
    year = catch_output$year[catch_keep],
    fleet = fishery_identity(catch_output$fishery[catch_keep], "code"),
    region = region_label(catch_output$area[catch_keep]),
    season = season_label(catch_output$season[catch_keep]),
    source_reference = "TAF_output_catch.csv; extraction fisheries only",
    notes = paste(diagnostic_notes, "Index-fishery pseudo-catch records are excluded.")),
  new_output("index", "predicted_index", cpue_output$pred, "relative CPUE index",
    year = cpue_output$year,
    survey = fishery_identity(cpue_output$fishery, "code"),
    region = region_label(cpue_output$area),
    season = season_label(cpue_output$season),
    source_reference = "TAF_output_cpue.csv, field pred",
    notes = cpue_prediction_notes),
  new_output("recruitment", "recruitment", summary_output$rec, "fish",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field rec",
    notes = paste(diagnostic_notes, "The source summary defines recruitment as total abundance in quarterly age class 1.")),
  new_output("catch", "predicted_catch", summary_output$catch, "metric tonnes",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field catch",
    notes = paste(diagnostic_notes, "Annual aggregate catch output; source units are retained.")),
  new_output("biomass", "total_biomass", summary_output$tb, "metric tonnes",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field tb",
    notes = diagnostic_notes),
  new_output("biomass", "spawning_potential_biomass", summary_output$sb, "metric tonnes",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field sb",
    notes = paste(diagnostic_notes, "Source spawning-biomass definition.")),
  new_output("biomass", "unfished_spawning_potential_biomass", summary_output$sbf0, "metric tonnes",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field sbf0",
    notes = paste(diagnostic_notes, "Source spawning potential at F=0.")),
  new_output("biomass", "spawning_output_ratio_to_unfished", summary_output$dep, "ratio",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field dep",
    notes = paste(diagnostic_notes, "Preserved the source SB/SBF0 ratio.")),
  new_output("mortality", "mean_fishing_mortality", summary_output$f, "per year",
    year = summary_output$year,
    source_reference = "TAF_output_summary.csv, field f",
    notes = diagnostic_notes)
)

input_rows <- rbind(catch_inputs, effort_inputs, cpue_inputs, length_inputs,
  age_length_inputs, caal_weight_inputs, reg_scale_inputs, tag_release_inputs,
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
  new_assumption("model structure", "temporal_resolution", "Quarterly; four model seasons per year",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 4.2–4.3; MFCL_yft.ini",
    "Source season codes 1–4 are preserved on fishery, index, composition, tag, and population records."),
  new_assumption("model structure", "spatial_regions", "Five MFCL model regions",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 4.2; TAF_data_fisheries.csv",
    "Source areas 1–5 are represented as MFCL area codes."),
  new_assumption("model structure", "age_classes", "40 quarterly age classes; age class 40 is a plus group",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.2.2",
    "Values 1–40 are MFCL quarterly age-class codes, not 40 annual ages."),
  new_assumption("catch", "catch_units", "Longline catch in numbers of fish; all other extraction catches in tonnes",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 4.5.1; MFCL_yft.frq data flags",
    "Native fishery flags were checked against the report. The database values retain their original scale."),
  new_assumption("catch", "discard_treatment", "Discarded catches estimated to be minor and excluded",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 4.5.1",
    "No discard series was added."),
  new_assumption("effort", "effort_units", "Fishery-specific native units",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 4.5.1–4.5.4; MFCL_yft.frq",
    "Preserved reported effort; omitted -1 missing-value codes. Longline uses hooks per set, purse-seine sets, and Japanese pole-and-line vessel fishing days."),
  new_assumption("index", "regional_cpue", "Five quarterly standardized longline CPUE indices; 1952–2024",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 4.5.3 and 5.5.1; TAF_data_cpue.csv",
    "TAF values were verified as MFCL index-fishery catch / effort / 1e6."),
  new_assumption("index", "cpue_likelihood", "Lognormal with time-varying regional CVs and generic scaled CVs",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.5.1",
    "The pinned TAF input export does not contain the CV time series, so no values are inferred or added."),
  new_assumption("regional scaling", "regional_scaling_source", "Global sdmTMB CPUE model supplies a regional-scaling penalty in MFCL",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 4.5.3 and 6.1; TAF_data_reg_scale.csv",
    "Native values are retained in inputs.csv. Their physical units are not defined in the source export and no conversion is applied."),
  new_assumption("composition", "length_composition", "Length frequency; 95 classes from 10–12 cm through 198–200 cm",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 4.6 and 5.5.2",
    "Extraction-fishery frequencies are weighted by catch and index-fishery frequencies by standardized CPUE. TAF exports contain preprocessed frequencies but not separate unweighted counts or the final effective sample sizes."),
  new_assumption("composition", "composition_likelihood", "Robust-normal likelihood with source sample-size divisors and maximum effective sample size 1,000",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.5.2",
    "The diagnostic model settings are not fully reconstructed here. Canonical rows preserve source frequencies without analysis-specific scaling."),
  new_assumption("growth", "conditional_age_at_length", "Multinomial conditional age-at-length data used to estimate growth",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.5.4; TAF_data_otoliths.csv",
    "The source field ess is preserved as a linked likelihood-weight input. The report notes age-measurement error was not modeled."),
  new_assumption("growth", "conditional_age_weighting", "Diagnostic CAAL downweight 0.75 plus region-specific scaling factors",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.5.4; TAF_data_otoliths.csv",
    "The table retains observed counts and the native ess values separately; the 0.75 factor is recorded as an assumption rather than multiplying source counts."),
  new_assumption("growth", "growth_and_weight_surface", "Length-at-age is regionally and temporally invariant; weight-at-age is derived from length-at-age and a weight-length relation",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.2.3; TAF_output_biology.csv",
    "The fitted surfaces are stored as model outputs, not independent input observations."),
  new_assumption("natural mortality", "mortality_model", "Age-dependent Lorenzen mortality; diagnostic natural-mortality prior median 0.107 with 5th–95th percentiles 0.077–0.149",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 5.2.5 and 6.2.2",
    "The model-derived M-at-age is preserved as a fitted output."),
  new_assumption("tagging", "tag_likelihood", "Negative-binomial tag-recapture likelihood with fixed tau = 2 in Diagnostic2026",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 5.5.3, 6.1.1 and 7.2.3",
    "Native release frequencies, release groups, recapture counts, fleets, areas, and seasons are retained."),
  new_assumption("tagging", "tag_mixing", "Diagnostic model assumes a two-quarter tag-mixing period",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Section 5.4.2",
    "Alternative one- and three-quarter periods appear in the uncertainty ensemble."),
  new_assumption("assessment outputs", "run_status", "MFCL Model 16 (Diagnostic2026), data through 2024; SC22 deferred management-advice review to SC23",
    "WCPFC-SC22-2026-SA-WP05_Rev01, front matter and Sections 6–7; WCPFC SC22 outcome notice",
    "is_current is TRUE for the latest detailed run; is_applied is FALSE. Outputs are not yet the adopted advice basis."),
  new_assumption("assessment outputs", "uncertainty", "2026 report describes a 48-model uncertainty ensemble",
    "WCPFC-SC22-2026-SA-WP05_Rev01, Sections 6.2 and 7.7",
    "The pinned TAF outputs are single-run point estimates and contain no standard errors or confidence intervals.")
))

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "WCPFC / SPC", authority_stock_id = "Western and Central Pacific yellowfin tuna",
  scientific_name = "Thunnus albacares", common_name = "WCPO yellowfin tuna",
  area = "Western and Central Pacific Ocean; five MFCL model regions",
  region = "WCPFC Convention Area; five MFCL model regions",
  ocean = "Western and Central Pacific",
  notes = "NOAA Stock SMART ID 11694 is retained as a discovery cross-reference. Assessment authority is WCPFC, with SPC model inputs. The 2026 detailed assessment was not reviewed at SC22 for management advice.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026L,
  terminal_year = 2024L, estimate_terminal_year = 2024L,
  assessment_type = "full_assessment", model_family = "MULTIFAN-CL",
  model_version = "Diagnostic2026 (MFCL Model 16)",
  is_current = "TRUE", is_applied = "FALSE", framework_year = 2026L,
  assessment_url = "https://meetings.wcpfc.int/node/32678",
  framework_url = "https://meetings.wcpfc.int/file/21826/download",
  data_url = "https://meetings.wcpfc.int/file/21826/download",
  model_url = paste0("https://github.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/tree/", revision),
  repository_url = paste0("https://github.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/tree/", revision),
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The 2026 report states the assessment was not reviewed at SC22 for management advice and review was deferred to SC23; a revised assessment may change results.",
    "This record preserves the latest detailed model run located, not an adopted advice result.",
    "Inputs and outputs are partial: the TAF export omits CPUE CV values and final effective sample sizes; eight regional CPUE prediction cells in 1952–1953 are missing in the source; and outputs contain no uncertainty estimates."
  ),
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
if (sum(input_rows$measure == "relative_abundance_index") != 1452L ||
    sum(input_rows$measure == "frequency_at_length") != 297920L ||
    sum(input_rows$measure == "conditional_frequency_at_age") != 1631L ||
    sum(input_rows$measure == "observation_likelihood_weight") != 1229L ||
    sum(input_rows$measure == "regional_scaling_value") != 1420L ||
    sum(input_rows$measure == "tag_release_frequency_at_length") != 13585L ||
    sum(input_rows$measure == "tag_recapture_count") != 6331L ||
    sum(age_length_inputs$value) != 1873 ||
    sum(outputs$measure == "numbers_at_age") != 58400L ||
    sum(outputs$measure == "fishing_mortality_at_age") != 17520L ||
    sum(outputs$measure == "mature_biomass_at_age") != 58400L ||
    sum(outputs$measure == "predicted_index") != 1460L ||
    sum(outputs$measure == "predicted_catch") != 9125L ||
    sum(outputs$measure == "spawning_potential_biomass") != 1533L) {
  stop("Constructed data rows differ from reviewed yellowfin source coverage.", call. = FALSE)
}
cat("Prepared WCPO yellowfin import: ", nrow(assumptions), " assumptions, ",
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
  "The native MFCL inputs provide catch by fishery and quarter plus 297,920 preprocessed length-frequency records.",
  "The 1,873 age-at-length observations are conditional growth data, not catch-at-age; no catch-at-age was reconstructed."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Five quarterly regional standardized longline CPUE series are imported as aggregate relative-abundance indices.",
  "The assessment does not provide an age-specific abundance index in the pinned TAF export."
)
candidates$weights_evidence[candidate_row] <- paste(
  "Native length-frequency and conditional age-at-length inputs are preserved; fitted weight-at-age is imported as a model-derived output."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "Fitted maturity-at-age is preserved as a model-derived output; no independent observed maturity-at-age input was recovered."
)
candidates$mortality_evidence[candidate_row] <- paste(
  "The assessment estimates an age-dependent Lorenzen mortality form; fitted natural mortality at age is imported as an output."
)
candidates$timing_evidence[candidate_row] <- paste(
  "Catch, CPUE, composition, and tagging rows preserve the quarterly model season.",
  "CPUE sampling_time is the quarter midpoint, not an exact survey date."
)
candidates$output_evidence[candidate_row] <- paste(
  "Pinned TAF exports provide N-at-age, annual F-at-age, mature biomass-at-age, regional biomass and CPUE predictions, catches, recruitment, and summary biomass through 2024.",
  "These are single-run Diagnostic2026 point estimates without uncertainty; SC22 deferred advice review to SC23. Eight area-5 CPUE prediction values for 1952–1953 are blank in the source and remain missing."
)
candidates$notes[candidate_row] <- paste(
  "NOAA Stock SMART ID 11694 maps to the WCPFC Western and Central Pacific yellowfin unit and is distinct from Eastern Pacific and Indian Ocean yellowfin.",
  "The pinned 2026 SPC diagnostic files and source limitations are documented in discovery/source_reviews/noaa_wcpfc_yellowfin_2026.md.",
  "SC22 deferred advice review to SC23; the 2026 diagnostic is the latest detailed source package located, not an adopted advice result."
)
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], candidate_id)

inventory$matched_stock_id[inventory_row] <- stock_id
inventory$match_status[inventory_row] <- "matched"
inventory$import_status[inventory_row] <- "partial"
replace_csv_register_row(inventory_path, inventory_row,
  inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])

cat("Imported partial WCPO yellowfin source data.\n")