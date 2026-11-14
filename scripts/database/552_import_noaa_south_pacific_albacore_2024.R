root <- "."
stock_id <- "wcpfc_south_pacific_albacore"
assessment_id <- "wcpfc_south_pacific_albacore_2024"
candidate_id <- "NOAA:11688"
revision <- "e9640087a9831dece824062a338c21bf81414044"

cache_name <- "discovery_noaa_south_pacific_albacore_2024"
cache_options <- c(file.path(root, "source_cache", cache_name),
  file.path(dirname(dirname(normalizePath(root))), cache_name))
cache_options <- cache_options[dir.exists(cache_options)]
if (!length(cache_options)) stop("Pinned South Pacific albacore cache is required.", call. = FALSE)
cache <- normalizePath(cache_options[[1L]], winslash = "/")

required_files <- c(
  "alb.frq", "alb.age_length", "alb.ini", "taf_input_cpue.csv",
  "taf_input_fisheries.csv", "taf_input_length_comps.csv",
  "taf_input_otoliths.csv", "taf_output_biology.csv",
  "taf_output_biomass.csv", "taf_output_catch.csv",
  "taf_output_f_annual.csv", "taf_output_natage.csv",
  "taf_output_selectivity.csv", "taf_output_summary.csv"
)
manifest <- read.csv(file.path("provenance", cache_name, "sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
manifest_row <- match(required_files, manifest$file)
if (anyNA(manifest_row) || any(!file.exists(file.path(cache, required_files))) ||
    any(!grepl("^[[:xdigit:]]{64}$", manifest$sha256[manifest_row]))) {
  stop("Required source files or SHA-256 provenance are missing.", call. = FALSE)
}
read_source <- function(name) read.csv(file.path(cache, name),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

fishery_data <- read_source("taf_input_fisheries.csv")
cpue_data <- read_source("taf_input_cpue.csv")
length_data <- read_source("taf_input_length_comps.csv")
otolith_data <- read_source("taf_input_otoliths.csv")
biology_data <- read_source("taf_output_biology.csv")
biomass_data <- read_source("taf_output_biomass.csv")
catch_output <- read_source("taf_output_catch.csv")
f_output <- read_source("taf_output_f_annual.csv")
n_output <- read_source("taf_output_natage.csv")
selectivity_data <- read_source("taf_output_selectivity.csv")
summary_data <- read_source("taf_output_summary.csv")

region_names <- c("1" = "WCPFC Convention Area", "2" = "Eastern Pacific Ocean",
  "all" = "All model regions")
region_name <- function(area) unname(region_names[as.character(area)])
fishery_lookup <- data.frame(
  fishery = fishery_data$fishery, code = fishery_data$code,
  region = region_name(fishery_data$area), stringsAsFactors = FALSE
)
length_bins <- seq.int(30L, 128L, by = 2L)

frq_lines <- readLines(file.path(cache, "alb.frq"), warn = FALSE)
flag_line <- which(grepl("Data flags (for records 1", frq_lines, fixed = TRUE))
incident_header <- which(grepl("Datasets / LFIntervals", frq_lines, fixed = TRUE))
data_header <- which(grepl("# fishery data", frq_lines, fixed = TRUE))
if (length(flag_line) != 1L || length(incident_header) != 1L || length(data_header) != 1L) {
  stop("Could not identify the required sections of alb.frq.", call. = FALSE)
}
catch_flags <- scan(text = frq_lines[flag_line + 1L], what = integer(), quiet = TRUE)
incident_count <- scan(text = frq_lines[incident_header + 1L], what = numeric(), quiet = TRUE)[1L]
incident_lines <- frq_lines[(data_header + 1L):length(frq_lines)]
incident_lines <- incident_lines[grepl("^\\s*(19|20)[0-9]{2}\\s", incident_lines)]
incident_fields <- strsplit(trimws(incident_lines), "[[:space:]]+")
if (length(incident_lines) != incident_count || any(lengths(incident_fields) < 7L)) {
  stop("Unexpected fishing-incident count or fields in alb.frq.", call. = FALSE)
}
frq_data <- as.data.frame(do.call(rbind, lapply(incident_fields, function(x) as.numeric(x[1:7]))))
names(frq_data) <- c("year", "month", "week", "fishery", "catch", "effort", "cpue_penalty")
frq_data$year <- as.integer(frq_data$year)
frq_data$fishery <- as.integer(frq_data$fishery)
expected_flags <- c(rep(0L, 10L), 1L, 1L, 1L, 0L, 0L, 0L, 1L, 0L, 0L, 0L)
if (incident_count != 3457L || nrow(fishery_data) != 20L ||
    !identical(catch_flags, expected_flags)) {
  stop("Unexpected incident count, fishery count, or catch-unit flags.", call. = FALSE)
}

age_lines <- readLines(file.path(cache, "alb.age_length"), warn = FALSE)
age_count_header <- which(grepl("num age length records", age_lines, fixed = TRUE))
age_ess_header <- which(grepl("effective sample size", age_lines, fixed = TRUE))
age_data_headers <- which(grepl("# Year   Month     Fishery", age_lines, fixed = TRUE))
if (length(age_count_header) != 1L || length(age_ess_header) != 1L) {
  stop("Could not identify alb.age_length records.", call. = FALSE)
}
n_age_records <- as.integer(scan(text = age_lines[age_count_header + 1L], what = numeric(), quiet = TRUE)[1L])
age_ess <- scan(text = age_lines[age_ess_header + 1L], what = numeric(), quiet = TRUE)
if (n_age_records != 33L || length(age_ess) != n_age_records ||
    length(age_data_headers) != n_age_records) {
  stop("Unexpected conditional age-at-length record count.", call. = FALSE)
}
read_numbers <- function(x) scan(text = x, what = numeric(), quiet = TRUE)
cursor <- age_data_headers[[1L]] + 1L
age_records <- vector("list", n_age_records)
for (i in seq_len(n_age_records)) {
  while (cursor <= length(age_lines) &&
      (!nzchar(trimws(age_lines[cursor])) || startsWith(trimws(age_lines[cursor]), "#"))) {
    cursor <- cursor + 1L
  }
  meta <- read_numbers(age_lines[cursor])
  if (length(meta) != 4L) stop("Unexpected age-length stratum header.", call. = FALSE)
  cursor <- cursor + 1L
  rows <- lapply(age_lines[seq.int(cursor, length.out = 50L)], read_numbers)
  if (any(lengths(rows) != 12L)) stop("Unexpected age-length matrix dimensions.", call. = FALSE)
  age_records[[i]] <- list(year = as.integer(meta[1]), month = as.integer(meta[2]),
    fishery = as.integer(meta[3]), species = as.integer(meta[4]),
    count = do.call(rbind, rows))
  cursor <- cursor + 50L
}
age_sample_total <- sum(vapply(age_records, function(x) sum(x$count), numeric(1L)))

length_id <- with(length_data, paste(year, season, month, fishery, sep = "_"))
if (nrow(length_data) != 63500L || length(unique(length_id)) != 1270L ||
    any(table(length_id) != 50L) ||
    !identical(sort(unique(as.integer(length_data$length))), length_bins) ||
    any(!is.finite(length_data$freq) | length_data$freq < 0)) {
  stop("Unexpected length-composition strata, bins, or values.", call. = FALSE)
}
if (nrow(cpue_data) != 169L || !setequal(unique(cpue_data$fishery), 18:20) ||
    anyDuplicated(cpue_data[c("year", "fishery")])) {
  stop("Unexpected aggregate CPUE series coverage.", call. = FALSE)
}
if (age_sample_total != 654L || nrow(otolith_data) != 654L ||
    !identical(range(otolith_data$age), c(1L, 10L))) {
  stop("Unexpected conditional age-at-length sample coverage.", call. = FALSE)
}
if (nrow(biology_data) != 12L || !identical(as.integer(biology_data$age), 1:12) ||
    !identical(range(n_output$year), c(1954L, 2022L)) ||
    !identical(range(f_output$year), c(1954L, 2022L)) ||
    !identical(range(n_output$age), c(1L, 12L)) ||
    !identical(range(f_output$age), c(1L, 12L)) ||
    !setequal(as.character(unique(n_output$area)), c("1", "2")) ||
    !setequal(as.character(unique(f_output$area)), c("1", "2", "all"))) {
  stop("Unexpected diagnostic output coverage.", call. = FALSE)
}
area_biomass <- aggregate(biomass_data[c("tb", "sb")],
  list(year = biomass_data$year), sum)
summary_row <- match(area_biomass$year, summary_data$year)
if (anyNA(summary_row) || any(area_biomass$tb != summary_data$tb[summary_row]) ||
    any(area_biomass$sb != summary_data$sb[summary_row])) {
  stop("Regional biomass does not match the model summary.", call. = FALSE)
}
catch_sum <- aggregate(catch ~ year, catch_output[catch_output$fishery <= 17L, ], sum)
summary_row <- match(catch_sum$year, summary_data$year)
if (anyNA(summary_row) || any(abs(catch_sum$catch - summary_data$catch[summary_row]) > 1)) {
  stop("Extraction-fishery catches do not match the model summary.", call. = FALSE)
}

new_input <- function(type, measure, basis, value, unit, year = NA_integer_,
                      age = NA_integer_, fleet = NA_character_, survey = NA_character_,
                      region = NA_character_, season = NA_character_, sampling_time = NA_real_,
                      observation_id = NA_character_, length_bin = NA_real_,
                      length_bin_lower = NA_real_, length_bin_upper = NA_real_,
                      sample_size = NA_real_, source_reference, transformation, notes = "") {
  n <- length(value)
  rep_n <- function(x) rep(x, length.out = n)
  year <- rep_n(year)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = rep_n(basis),
    fleet = rep_n(fleet), survey = rep_n(survey), sex = NA_character_,
    region = rep_n(region), season = rep_n(season), year = year,
    year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = rep_n(age), value = value, unit = rep_n(unit),
    sampling_time = rep_n(sampling_time), source_type = "native_model",
    source_reference = rep_n(source_reference), transformation = rep_n(transformation),
    notes = rep_n(notes), observation_id = rep_n(observation_id),
    length_bin = rep_n(length_bin), length_bin_lower = rep_n(length_bin_lower),
    length_bin_upper = rep_n(length_bin_upper), sample_size = rep_n(sample_size),
    age_error = NA_character_, partition = NA_character_, weight_bin = NA_real_,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
new_assumption <- function(component, setting, value, source_reference, notes = "",
                           fleet = NA_character_, survey = NA_character_,
                           region = NA_character_, season = NA_character_) {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = NA_character_, region = region, season = season,
    setting = setting, value = as.character(value), source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
new_output <- function(type, measure, value, unit, year = NA_integer_, age = NA_integer_,
                       age_group = NA_character_, region = NA_character_,
                       fleet = NA_character_, season = NA_character_,
                       source_reference, notes = "") {
  n <- length(value)
  rep_n <- function(x) rep(x, length.out = n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = rep_n(fleet), survey = NA_character_, sex = NA_character_,
    region = rep_n(region), season = rep_n(season), year = rep_n(year),
    age = rep_n(age), age_group = rep_n(age_group),
    value = value, se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "native_model", source_reference = rep_n(source_reference),
    notes = rep_n(notes), scenario = NA_character_,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch_data <- frq_data[frq_data$fishery <= 17L, , drop = FALSE]
catch_name <- fishery_lookup$code[match(catch_data$fishery, fishery_lookup$fishery)]
catch_region <- fishery_lookup$region[match(catch_data$fishery, fishery_lookup$fishery)]
catch_weight <- catch_flags[catch_data$fishery] == 1L
catch_inputs <- new_input(
  type = "catch", measure = ifelse(catch_weight, "catch_biomass", "catch_numbers"),
  basis = ifelse(catch_weight, "biomass", "numbers"), value = catch_data$catch,
  unit = ifelse(catch_weight, "metric tonnes", "fish"), year = catch_data$year,
  fleet = catch_name, region = catch_region,
  season = paste0("month ", catch_data$month, ", week ", catch_data$week),
  observation_id = paste0("alb_frq_", catch_data$year, "_", catch_data$month, "_",
    catch_data$week, "_f", catch_data$fishery),
  source_reference = "alb.frq, fishery data records 1-7",
  transformation = "Read catch without scaling; applied the fishery-specific number/weight flag.",
  notes = "Native catch-conditioned input without age composition. Number-flagged catches are fish; weight-flagged catches are metric tonnes."
)

effort_data <- frq_data[frq_data$fishery <= 17L & is.finite(frq_data$effort) &
  frq_data$effort >= 0, , drop = FALSE]
effort_name <- fishery_lookup$code[match(effort_data$fishery, fishery_lookup$fishery)]
effort_inputs <- new_input(
  type = "covariate", measure = "effort", basis = "native_covariate",
  value = effort_data$effort, unit = "native effort scale", year = effort_data$year,
  fleet = effort_name, region = fishery_lookup$region[match(effort_data$fishery, fishery_lookup$fishery)],
  season = paste0("month ", effort_data$month, ", week ", effort_data$week),
  observation_id = paste0("alb_effort_", effort_data$year, "_", effort_data$month, "_",
    effort_data$week, "_f", effort_data$fishery),
  source_reference = "alb.frq, fishery data effort field",
  transformation = "Read non-missing effort without scaling.",
  notes = "The model guide defines effort as arbitrary within a fishery and internally rescales it. These native values are not a separate abundance index; the source does not give a common physical unit."
)

length_fishery <- length_data$fishery
length_inputs <- new_input(
  type = ifelse(length_fishery <= 17L, "catch", "index"),
  measure = "frequency_at_length", basis = "native_frequency",
  value = length_data$freq, unit = "source frequency", year = length_data$year,
  fleet = ifelse(length_fishery <= 17L,
    fishery_lookup$code[match(length_fishery, fishery_lookup$fishery)], NA_character_),
  survey = ifelse(length_fishery >= 18L,
    fishery_lookup$code[match(length_fishery, fishery_lookup$fishery)], NA_character_),
  region = fishery_lookup$region[match(length_fishery, fishery_lookup$fishery)],
  season = paste0("model season ", length_data$season, ", month ", length_data$month),
  observation_id = paste0("alb_lf_", length_id), length_bin = length_data$length,
  source_reference = "TAF/data/length_comps.csv; 50 2-cm classes",
  transformation = "Preserved the reweighted frequencies; no normalization or sample-size scaling.",
  notes = "Extraction compositions were reweighted by catch and index compositions by relative abundance. The export has no separate raw sample-size field; sample_size is left blank."
)

cpue_time <- (as.numeric(cpue_data$season) - 0.5) / 4
cpue_name <- fishery_lookup$code[match(cpue_data$fishery, fishery_lookup$fishery)]
cpue_region <- region_name(cpue_data$area)
cpue_key <- paste(cpue_data$year, cpue_data$fishery)
frq_index <- frq_data[frq_data$fishery %in% 18:20, , drop = FALSE]
cpue_penalty <- frq_index$cpue_penalty[match(cpue_key, paste(frq_index$year, frq_index$fishery))]
if (anyNA(cpue_penalty) || any(!is.finite(cpue_penalty) | cpue_penalty <= 0) ||
    any(!cpue_data$season %in% 1:4)) {
  stop("Could not match the time-varying CPUE precision to each index observation.", call. = FALSE)
}
cpue_id <- paste0("alb_cpue_", cpue_data$year, "_f", cpue_data$fishery)
cpue_inputs <- new_input(
  type = "index", measure = "relative_abundance_index", basis = "index_scale",
  value = cpue_data$index, unit = "relative CPUE index", year = cpue_data$year,
  survey = cpue_name, region = cpue_region,
  season = paste0("model season ", cpue_data$season), sampling_time = cpue_time,
  observation_id = cpue_id,
  source_reference = "TAF/data/cpue.csv; annual index observations",
  transformation = "Preserved standardized CPUE on its source relative scale.",
  notes = "Annual lognormal relative abundance index. sampling_time is the model-quarter midpoint, not an exact survey date; no absolute multiplier is reported."
)
cpue_weight_inputs <- new_input(
  type = "index", measure = "relative_precision_weight", basis = "relative_precision",
  value = cpue_penalty, unit = "ratio", year = cpue_data$year, survey = cpue_name,
  region = cpue_region, season = paste0("model season ", cpue_data$season),
  sampling_time = cpue_time, observation_id = cpue_id,
  source_reference = "alb.frq, column 7; 2024 assessment Section 4.5",
  transformation = "Matched the native time-varying CPUE precision multiplier by year and index fishery; no conversion to CV.",
  notes = "Fish flag 66 activates this time-varying column. It scales precision; the reported CV also depends on the generic fishery component. This multiplier is not itself a CV or standard error."
)

age_length_inputs <- do.call(rbind, lapply(seq_along(age_records), function(i) {
  record <- age_records[[i]]
  if (!record$fishery %in% fishery_lookup$fishery || record$species != 1L) {
    stop("Unexpected fishery or species in an age-length stratum.", call. = FALSE)
  }
  cells <- expand.grid(length_index = seq_along(length_bins), age = 1:12)
  size <- rep(rowSums(record$count), each = 12L)
  fishery_row <- match(record$fishery, fishery_lookup$fishery)
  new_input(
    type = "biology", measure = "conditional_frequency_at_age", basis = "native_frequency",
    value = as.vector(t(record$count)), unit = "fish", year = record$year, age = cells$age,
    fleet = fishery_lookup$code[fishery_row], region = fishery_lookup$region[fishery_row],
    season = paste0("month ", record$month),
    observation_id = paste0("alb_caal_", i, "_y", record$year, "_m", record$month,
      "_f", record$fishery),
    length_bin_lower = length_bins[cells$length_index],
    length_bin_upper = length_bins[cells$length_index] + 2L,
    sample_size = size, source_reference = paste0("alb.age_length, stratum ", i),
    transformation = "Read native 50-by-12 age-length count matrix without converting or scaling counts.",
    notes = paste(
      "Native age-at-length counts, not a marginal age composition.",
      "Age 12 is the plus group; raw observed sample size is retained by length bin.",
      "The diagnostic model applies an effective sample size multiplier of 0.75; raw counts are not scaled."
    )
  )
}))

ini_lines <- readLines(file.path(cache, "alb.ini"), warn = FALSE)
maturity_header <- which(grepl("# maturity at length", ini_lines, fixed = TRUE))
if (length(maturity_header) != 1L) stop("Missing alb.ini maturity-at-length section.", call. = FALSE)
reproductive_potential <- scan(text = ini_lines[maturity_header + 1L], what = numeric(), quiet = TRUE)
if (length(reproductive_potential) != 50L ||
    any(!is.finite(reproductive_potential) | reproductive_potential < 0 | reproductive_potential > 1)) {
  stop("Unexpected length reproductive-potential vector.", call. = FALSE)
}
reproductive_potential_input <- new_input(
  type = "biology", measure = "reproductive_potential_at_length", basis = "proportion",
  value = reproductive_potential, unit = "relative reproductive potential",
  length_bin = length_bins, source_reference = "alb.ini, maturity at length vector",
  transformation = "Read the supplied vector without scaling.",
  notes = "The 2024 report defines the active curve as sex ratio multiplied by maturity-at-length and rescaled to one; it is reproductive potential, not maturity alone. The model converts it to age using estimated growth."
)

assumptions <- rbind(
  new_assumption("population", "model_regions", "2",
    "2024 assessment Section 5.1; TAF outputs area 1 and area 2",
    "Region 1 is WCPFC Convention Area; region 2 is the eastern Pacific model region."),
  new_assumption("population", "age_classes", "1-12+",
    "2024 assessment Section 5.1; alb.ini",
    "Twelve annual age classes; age 12 is the plus group."),
  new_assumption("population", "temporal_structure", "Annual population states with seasonal catch removals",
    "2024 assessment Section 5.2.1",
    "Within-year catch timing and natural mortality are applied at specified quarters or months."),
  new_assumption("recruitment", "age_and_timing", "Age 1; annual recruitment in October",
    "2024 assessment Section 5.2.2; alb.frq header",
    "Annual, not quarterly, recruitment in the final model."),
  new_assumption("mortality", "natural_mortality_structure", "Lorenzen M-at-age inversely proportional to mean length-at-age",
    "2024 assessment Section 5.2.7",
    "The TAF diagnostic output supplies the resulting M-at-age surface."),
  new_assumption("mortality", "mean_M_mature_ages", "0.36 per year for ages 4-12+",
    "2024 assessment Section 5.2.7",
    "Amax method with Amax = 15 years; the assessment ensemble varies average M."),
  new_assumption("mortality", "Amax", "15 years",
    "2024 assessment Section 5.2.7",
    "Assumption used to set expected average natural mortality."),
  new_assumption("biology", "length_weight_equation", "W = 1.708e-05 * L^3.04830",
    "alb.ini, length-weight parameters",
    "Coefficients are preserved on their native scale; model-derived weight-at-age is stored separately."),
  new_assumption("biology", "spawning_biomass_ogive", "Length-based reproductive potential converted to age using estimated growth",
    "alb.ini; 2024 assessment Section 5.2.8",
    "The source curve combines sex ratio and maturity-at-length and is rescaled to one."),
  new_assumption("composition", "length_frequency_weighting", "Francis method; extraction samples weighted by catch and index samples by relative abundance",
    "2024 assessment Sections 4.7 and 5.4.1",
    "Source TAF frequencies are preserved; no sample size is inferred from weighted values."),
  new_assumption("composition", "conditional_age_at_length_ESS_multiplier", "0.75",
    "alb.age_length; 2024 assessment Section 5.4.2",
    "Effective sample size is observed sample size multiplied by 0.75; matrix counts remain raw."),
  new_assumption("index", "CPUE_likelihood", "Annual lognormal index with time-varying and generic CV components",
    "2024 assessment Section 5.4.3; alb.frq",
    "Time-varying precision multipliers are retained by year; source report specifies generic CV 0.20 for each index.")
)
for (fishery in sort(unique(cpue_data$fishery))) {
  fishery_row <- match(fishery, fishery_lookup$fishery)
  assumptions <- rbind(assumptions, new_assumption(
    "index", "generic_CV", "0.20", "2024 assessment Section 5.4.3",
    if (fishery == 19L) {
      "The generic CV for the New Zealand troll index was set to 0.20 because its CPUE-standardization estimate was considered too small."
    } else {
      "Generic CV specified for the standardized longline index; the model also uses its time-varying component."
    },
    survey = fishery_lookup$code[fishery_row],
    region = fishery_lookup$region[fishery_row]
  ))
}

age_group <- function(age) ifelse(age == 12L, "12+", NA_character_)
f_notes <- ifelse(as.character(f_output$area) == "all",
  "The TAF area='all' F-at-age series is retained as reported; its aggregation formula is not documented in the export. No uncertainty is available.",
  "Regional diagnostic model annual F-at-age; no uncertainty is available in this export.")
outputs <- rbind(
  new_output("population", "numbers_at_age", n_output$n, "fish",
    year = n_output$year, age = n_output$age, age_group = age_group(n_output$age),
    region = region_name(n_output$area), source_reference = "TAF/output/natage.csv",
    notes = "Diagnostic model annual numbers-at-age; age 12 is the plus group; no uncertainty is available in this export."),
  new_output("mortality", "fishing_mortality_at_age", f_output$f, "per year",
    year = f_output$year, age = f_output$age, age_group = age_group(f_output$age),
    region = region_name(f_output$area), source_reference = "TAF/output/f_annual.csv",
    notes = f_notes),
  new_output("biology", "growth_length_at_age", biology_data$length, "cm",
    age = biology_data$age, age_group = age_group(biology_data$age),
    source_reference = "TAF/output/biology.csv, length",
    notes = "Model-estimated mean length-at-age."),
  new_output("biology", "weight_at_age", biology_data$weight, "kg per fish",
    age = biology_data$age, age_group = age_group(biology_data$age),
    source_reference = "TAF/output/biology.csv, weight",
    notes = "Model-derived weight-at-age from estimated growth and the length-weight relationship."),
  new_output("biology", "reproductive_potential_at_age", biology_data$maturity, "proportion",
    age = biology_data$age, age_group = age_group(biology_data$age),
    source_reference = "TAF/output/biology.csv, maturity",
    notes = "Model-derived reproductive potential converted from the sex-ratio-by-maturity length curve; not a conventional maturity ogive."),
  new_output("mortality", "natural_mortality_at_age", biology_data$natmort, "per year",
    age = biology_data$age, age_group = age_group(biology_data$age),
    source_reference = "TAF/output/biology.csv, natmort",
    notes = "Diagnostic Lorenzen M-at-age; no uncertainty is available in this export."),
  new_output("biology", "fleet_selectivity_at_age", selectivity_data$sel, "proportion",
    age = selectivity_data$age, age_group = age_group(selectivity_data$age),
    fleet = fishery_lookup$code[match(selectivity_data$fishery, fishery_lookup$fishery)],
    region = fishery_lookup$region[match(selectivity_data$fishery, fishery_lookup$fishery)],
    season = paste0("model season ", selectivity_data$season),
    source_reference = "TAF/output/selectivity.csv",
    notes = "Diagnostic fishery selectivity; seasonal where reported."),
  new_output("catch", "modelled_catch_biomass",
    catch_output$catch[catch_output$fishery <= 17L], "metric tonnes",
    year = catch_output$year[catch_output$fishery <= 17L],
    fleet = fishery_lookup$code[match(catch_output$fishery[catch_output$fishery <= 17L], fishery_lookup$fishery)],
    region = region_name(catch_output$area[catch_output$fishery <= 17L]),
    source_reference = "TAF/output/catch.csv; extraction fisheries 1-17",
    notes = "Diagnostic model catch output in biomass units. Index-fishery predictions are excluded because those fisheries use arbitrary catch placeholders for the dedicated CPUE likelihood."),
  new_output("biomass", "total_biomass", biomass_data$tb, "metric tonnes",
    year = biomass_data$year, region = region_name(biomass_data$area),
    source_reference = "TAF/output/biomass.csv, tb",
    notes = "Diagnostic total biomass by model region."),
  new_output("biomass", "SSB", biomass_data$sb, "metric tonnes",
    year = biomass_data$year, region = region_name(biomass_data$area),
    source_reference = "TAF/output/biomass.csv, sb",
    notes = "Diagnostic spawning biomass by model region."),
  new_output("catch", "total_catch_biomass", summary_data$catch, "metric tonnes",
    year = summary_data$year, source_reference = "TAF/output/summary.csv, catch",
    notes = "Diagnostic total catch biomass across extraction fisheries."),
  new_output("biomass", "total_biomass", summary_data$tb, "metric tonnes",
    year = summary_data$year, source_reference = "TAF/output/summary.csv, tb",
    notes = "Diagnostic total biomass across both model regions."),
  new_output("biomass", "SSB", summary_data$sb, "metric tonnes",
    year = summary_data$year, source_reference = "TAF/output/summary.csv, sb",
    notes = "Diagnostic spawning biomass across both model regions."),
  new_output("biomass", "SSB_F0", summary_data$sbf0, "metric tonnes",
    year = summary_data$year, source_reference = "TAF/output/summary.csv, sbf0",
    notes = "Annual spawning biomass under the source no-fishing reference; not a static unfished B0 estimate."),
  new_output("biomass", "dynamic_depletion", summary_data$dep, "proportion",
    year = summary_data$year, source_reference = "TAF/output/summary.csv, dep",
    notes = "Annual SB divided by the corresponding source no-fishing spawning-biomass trajectory."),
  new_output("recruitment", "recruitment", summary_data$rec, "fish",
    year = summary_data$year, age = 1L,
    source_reference = "TAF/output/summary.csv, rec",
    notes = "Annual age-1 recruitment for the diagnostic model.")
)
natage_total <- aggregate(n ~ year + area, n_output, sum)
natage_all <- aggregate(n ~ year, n_output, sum)
outputs <- rbind(outputs,
  new_output("population", "total_numbers", natage_total$n, "fish",
    year = natage_total$year, region = region_name(natage_total$area),
    source_reference = "Derived from TAF/output/natage.csv",
    notes = "Derived by summing reported numbers-at-age over all 12 age classes within each model region; no uncertainty available."),
  new_output("population", "total_numbers", natage_all$n, "fish",
    year = natage_all$year, source_reference = "Derived from TAF/output/natage.csv",
    notes = "Derived by summing reported numbers-at-age over all ages and both model regions; no uncertainty available.")
)

inputs <- do.call(rbind, list(catch_inputs, effort_inputs, length_inputs,
  cpue_inputs, cpue_weight_inputs, age_length_inputs, reproductive_potential_input))
if (nrow(inputs) != 89720L || nrow(outputs) != 6762L || nrow(assumptions) != 15L) {
  stop("Unexpected source row totals; inspect dimensions before writing.", call. = FALSE)
}
cat("Parsed South Pacific albacore source rows: ", nrow(inputs), " inputs, ",
  nrow(assumptions), " assumptions, and ", nrow(outputs), " outputs.\n", sep = "")

read_table <- function(name) read.csv(file.path(root, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
candidates <- read_table("discovery/candidates.csv")
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || stock_id %in% stocks$stock_id ||
    assessment_id %in% assessments$assessment_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$import_status[candidate_row] != "not_started") {
  stop("Expected one eligible, unimported candidate and no canonical albacore records.", call. = FALSE)
}
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
inventory <- read_table("discovery/inventory_units.csv")
source(file.path(root, "scripts", "database", "candidate_register_io.R"))
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
if (inventory$import_status[inventory_row] != "not_started") {
  stop("The albacore inventory unit has already been imported.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_,
  authority = "WCPFC / SPC / IATTC", authority_stock_id = "South Pacific albacore",
  scientific_name = "Thunnus alalunga", common_name = "South Pacific albacore",
  area = "WCPFC Convention Area and eastern Pacific model region",
  region = "South Pacific", ocean = "South Pacific",
  notes = "Joint SPC/IATTC assessment. NOAA Stock SMART ID 11688 is retained as a discovery alias, not the assessment authority identifier.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2024L,
  terminal_year = 2022L, estimate_terminal_year = 2022L,
  assessment_type = "full_assessment", model_family = "MULTIFAN-CL",
  model_version = "2.2.7.0 diagnostic reference model",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2024L,
  assessment_url = "https://meetings.wcpfc.int/node/23119",
  framework_url = NA_character_, data_url = "https://meetings.wcpfc.int/node/23128",
  model_url = paste0("https://github.com/PacificCommunity/ofp-sam-alb-2024-diagnostic/tree/", revision),
  repository_url = paste0("https://github.com/PacificCommunity/ofp-sam-alb-2024-diagnostic/tree/", revision),
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Latest full assessment located is the 2024 production assessment through 2022.",
    "Canonical fitted outputs are from its single diagnostic reference model; management advice uses a 100-model ensemble.",
    "Native observations and diagnostic point estimates are captured, but ensemble uncertainty and some likelihood details are unavailable in the TAF export."
  ), stringsAsFactors = FALSE
)

schema_rows <- setNames(list(stock, assessment, assumptions, inputs, outputs),
  c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv"))
for (name in names(schema_rows)) {
  header <- names(read.csv(file.path(root, "database", name), nrows = 0L,
    stringsAsFactors = FALSE, check.names = FALSE))
  if (!identical(header, names(schema_rows[[name]]))) {
    stop("Unexpected columns in database/", name, call. = FALSE)
  }
}
if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) quit(save = "no", status = 0L)

append_csv_rows <- function(name, rows) {
  path <- file.path(root, "database", name)
  if (!file.exists(path) || !nrow(rows)) stop("Missing source table or rows: ", name, call. = FALSE)
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  if (!identical(header, names(rows))) stop("Unexpected columns in ", name, call. = FALSE)
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

replace_discovery_row <- function(path, row_index, row, key_column, key) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  existing <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (nrow(row) != 1L || !key_column %in% names(existing) ||
      !identical(as.character(existing[[key_column]][row_index]), key)) {
    stop("Discovery register row identity does not match ", key, call. = FALSE)
  }
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  record <- row_index + 1L
  first <- bounds$start[record]
  last <- bounds$end[record]
  next_byte <- last + 1L
  has_cr <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_cr <- TRUE
    next_byte <- next_byte + 1L
  }
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, if (has_cr) as.raw(13L) else raw(0L), as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE), error = function(e) NULL)
  if (is.null(updated) || nrow(updated) != nrow(existing) ||
      sum(updated[[key_column]] == key, na.rm = TRUE) != 1L) {
    writeBin(original, path)
    stop("Discovery register update failed its identity or row-count check.", call. = FALSE)
  }
}

stock_row <- stock
assessment_row <- assessment
append_csv_rows("stocks.csv", stock_row)
append_csv_rows("assessments.csv", assessment_row)
append_csv_rows("assumptions.csv", assumptions)
append_csv_rows("inputs.csv", inputs)
append_csv_rows("outputs.csv", outputs)

candidates$matched_stock_id[candidate_row] <- stock_id
candidates$match_status[candidate_row] <- "matched"
candidates$import_status[candidate_row] <- "partial"
candidates$review_date[candidate_row] <- "2026-11-09"
candidates$catch_age_evidence[candidate_row] <- paste(
  "Canonical inputs preserve fishery catches, reweighted length compositions, and conditional age-at-length matrices.",
  "The official assessment does not fit observed catch-at-age; no catch-at-age reconstruction was added."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Three annual aggregate CPUE indices are imported with relative scale and time-varying precision multipliers.",
  "No age-specific abundance index is supplied."
)
candidates$weights_evidence[candidate_row] <- paste(
  "The native length-weight equation is recorded as an assumption; the model-derived weight-at-age surface is preserved in outputs.",
  "No observed weight-at-age input is reported."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "The source length curve is sex ratio multiplied by maturity-at-length and rescaled to one.",
  "It is preserved as reproductive potential and converted to age by the assessment."
)
candidates$timing_evidence[candidate_row] <- paste(
  "Indices are assigned to model seasons 1 or 3; sampling_time uses the quarterly model-season midpoint.",
  "This is not an exact survey date."
)
candidates$output_evidence[candidate_row] <- paste(
  "The diagnostic TAF export provides annual recruitment, biomass/SSB, N-at-age, F-at-age, natural M-at-age, selectivity, and biological surfaces through 2022.",
  "The export has no uncertainty estimates; management advice uses a separate 100-model ensemble."
)
candidates$notes[candidate_row] <- paste(
  candidates$notes[candidate_row],
  "A partial canonical source import was added under wcpfc_south_pacific_albacore_2024.",
  "No synthetic catch-at-age or age-specific index was added.",
  "See discovery/source_reviews/noaa_south_pacific_albacore_2024.md."
)
replace_candidate_register_row(file.path(root, "discovery", "candidates.csv"),
  candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id)

inventory$matched_stock_id[inventory_row] <- stock_id
inventory$match_status[inventory_row] <- "matched"
inventory$import_status[inventory_row] <- "partial"
replace_discovery_row(inventory_path, inventory_row,
  inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])

cat("Imported partial South Pacific albacore 2024 source records.\n")

