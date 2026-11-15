root <- "."
stock_id <- "wcpfc_wcpo_yellowfin"
assessment_id <- "wcpfc_wcpo_yellowfin_2023"
cache_name <- "discovery_noaa_wcpo_yellowfin_2023"
diagnostic_revision <- "54274c0edac84e65fdbd8ef5996038e6a8714641"
grid_revision <- "6b28f0bf4975895beae4df861124b30286ff6fa0"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

cache <- file.path(root, "source_cache", cache_name)
manifest_path <- file.path(root, "provenance", cache_name, "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}
if (!all(c("file", "url", "retrieved_on", "sha256", "bytes", "revision") %in%
    names(manifest)) || anyDuplicated(manifest$file) || nrow(manifest) != 37L) {
  stop("The pinned 2023 yellowfin source manifest is incomplete.", call. = FALSE)
}
for (i in seq_len(nrow(manifest))) {
  path <- file.path(cache, manifest$file[i])
  if (!file.exists(path) || file.info(path)$size != as.numeric(manifest$bytes[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i])) {
    stop("Cached source failed provenance validation: ", manifest$file[i],
      call. = FALSE)
  }
}
if (!any(grepl(diagnostic_revision, manifest$url, fixed = TRUE)) ||
    !any(grepl(grid_revision, manifest$url, fixed = TRUE))) {
  stop("Sources are not pinned to both reviewed SPC revisions.", call. = FALSE)
}
read_source <- function(name) read.csv(file.path(cache, name),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
fishery_data <- read_source("TAF/data/fisheries.csv")
cpue_data <- read_source("TAF/data/cpue.csv")
length_data <- read_source("TAF/data/length_comps.csv")
weight_data <- read_source("TAF/data/weight_comps.csv")
otolith_data <- read_source("TAF/data/otoliths.csv")
release_data <- read_source("TAF/data/tag_releases.csv")
recapture_data <- read_source("TAF/data/tag_recaptures.csv")
n_output <- read_source("TAF/output/natage.csv")
batage_output <- read_source("TAF/output/batage.csv")
f_output <- read_source("TAF/output/f_annual.csv")
biomass_output <- read_source("TAF/output/biomass.csv")
catch_output <- read_source("TAF/output/catch.csv")
cpue_output <- read_source("TAF/output/cpue.csv")
biology_output <- read_source("TAF/output/biology.csv")
summary_output <- read_source("TAF/output/summary.csv")
grid_median <- read_source("notes/median_sb_time_series.csv")
grid_uncertainty <- read_source("notes/estimation_uncertainty.csv")

frq_lines <- readLines(file.path(cache, "MFCL/yft.frq"), warn = FALSE)
flag_header <- which(grepl("Data flags (for records 1", frq_lines, fixed = TRUE))
incident_header <- which(grepl("Datasets / LFIntervals", frq_lines, fixed = TRUE))
data_header <- which(grepl("# fishery data", frq_lines, fixed = TRUE))
if (length(flag_header) != 1L || length(incident_header) != 1L ||
    length(data_header) != 1L) stop("Could not identify yft.frq sections.")
catch_flags <- scan(text = frq_lines[flag_header + 1L], what = integer(), quiet = TRUE)
incident_count <- as.integer(scan(text = frq_lines[incident_header + 1L],
  what = numeric(), quiet = TRUE)[1L])
incident_lines <- frq_lines[(data_header + 1L):length(frq_lines)]
incident_lines <- incident_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]",
  incident_lines)]
incident_fields <- strsplit(trimws(incident_lines), "[[:space:]]+")
if (length(incident_lines) != incident_count || any(lengths(incident_fields) < 7L)) {
  stop("Unexpected fishing-incident count or fields in yft.frq.")
}
frq_data <- as.data.frame(do.call(rbind, lapply(incident_fields,
  function(x) as.numeric(x[1:7]))))
names(frq_data) <- c("year", "month", "week", "fishery", "catch", "effort",
  "cpue_penalty")
frq_data$year <- as.integer(frq_data$year)
frq_data$month <- as.integer(frq_data$month)
frq_data$week <- as.integer(frq_data$week)
frq_data$fishery <- as.integer(frq_data$fishery)
frq_data$season <- as.integer((1 + frq_data$month) / 3)

if (nrow(fishery_data) != 37L || !identical(fishery_data$fishery, 1:37) ||
    length(catch_flags) != 37L || any(!catch_flags %in% c(0L, 1L)) ||
    incident_count != 7988L || nrow(cpue_data) != 1400L ||
    nrow(length_data) != 135090L || nrow(weight_data) != 622800L ||
    nrow(otolith_data) != 1471L || nrow(release_data) != 13300L ||
    nrow(recapture_data) != 5938L || nrow(n_output) != 56000L ||
    nrow(batage_output) != 56000L || nrow(f_output) != 16800L ||
    nrow(biomass_output) != 1400L || nrow(catch_output) != 10360L ||
    nrow(cpue_output) != 1400L || nrow(biology_output) != 40L ||
    nrow(summary_output) != 70L || nrow(grid_median) != 70L ||
    nrow(grid_uncertainty) != 3L) {
  stop("Pinned source row counts differ from reviewed 2023 files.")
}
if (!identical(range(cpue_data$year), c(1952L, 2021L)) ||
    !identical(sort(unique(cpue_data$season)), 1:4) ||
    !identical(range(length_data$year), c(1965L, 2021L)) ||
    !identical(range(weight_data$year), c(1956L, 2021L)) ||
    !identical(range(otolith_data$year), c(2009L, 2018L)) ||
    !identical(range(n_output$year), c(1952L, 2021L)) ||
    !identical(range(n_output$age), c(1L, 40L)) ||
    !identical(range(f_output$age), c(1L, 40L)) ||
    !identical(range(grid_median$Year), c(1952L, 2021L)) ||
    !identical(sort(unique(n_output$season)), 1:4) ||
    length(unique(n_output$area)) != 5L ||
    !all(c("age", "length", "weight", "maturity", "natmort") %in% names(biology_output)) ||
    !identical(range(weight_data$weight), c(1L, 200L)) ||
    !identical(range(length_data$length), c(10L, 198L)) ||
    any(!is.finite(length_data$freq) | length_data$freq < 0) ||
    any(!is.finite(weight_data$freq) | weight_data$freq < 0)) {
  stop("Pinned yellowfin years, classes, or source values failed validation.")
}
region_label <- function(area) ifelse(as.character(area) == "all",
  "All model areas", paste0("MFCL area ", area))
season_label <- function(season) paste0("model quarter ", season)
fishery_lookup <- data.frame(
  fishery = fishery_data$fishery, code = fishery_data$code,
  gear = fishery_data$gear_long, flag = fishery_data$flag,
  region = region_label(fishery_data$area), stringsAsFactors = FALSE
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
index_fisheries <- fishery_data$fishery[fishery_data$flag == "IDX"]
index_frq <- frq_data[frq_data$fishery %in% index_fisheries, , drop = FALSE]
index_key <- paste(index_frq$year, index_frq$season, index_frq$fishery, sep = "_")
cpue_key <- paste(cpue_data$year, cpue_data$season, cpue_data$fishery, sep = "_")
index_match <- match(cpue_key, index_key)
if (nrow(index_frq) != nrow(cpue_data) || anyNA(index_match) ||
    anyDuplicated(index_key) ||
    max(abs(cpue_data$index - index_frq$catch[index_match] /
      index_frq$effort[index_match] / 1e6)) > 1e-10) {
  stop("TAF CPUE values do not match native catch/effort.")
}
input_columns <- c(
  "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age", "value", "unit",
  "sampling_time", "source_type", "source_reference", "transformation", "notes",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin"
)
output_columns <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group", "value", "se", "lwr", "upr", "unit",
  "source_type", "source_reference", "notes", "scenario"
)
assumption_columns <- c(
  "assessment_id", "component", "fleet", "survey", "sex", "region", "season",
  "setting", "value", "source_reference", "notes"
)
new_input <- function(type, measure, basis, value, unit, year,
    year_basis = "calendar_year", age = NA_real_, fleet = NA_character_,
    survey = NA_character_, region = NA_character_, season = NA_character_,
    sampling_time = NA_real_, observation_id = NA_character_,
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_,
    weight_bin = NA_real_, source_reference, transformation = "", notes = "") {
  n <- length(value)
  rep_n <- function(x) rep(x, length.out = n)
  data.frame(
    assessment_id = rep(assessment_id, n), type = rep_n(type),
    measure = rep_n(measure), basis = rep_n(basis), fleet = rep_n(fleet),
    survey = rep_n(survey), sex = NA_character_, region = rep_n(region),
    season = rep_n(season), year = rep_n(year), year_basis = rep_n(year_basis),
    age = rep_n(age), value = value, unit = rep_n(unit),
    sampling_time = rep_n(sampling_time), source_type = "native_model",
    source_reference = rep_n(source_reference),
    transformation = rep_n(transformation), notes = rep_n(notes),
    observation_id = rep_n(observation_id), length_bin = rep_n(length_bin),
    length_bin_lower = rep_n(length_bin_lower),
    length_bin_upper = rep_n(length_bin_upper), sample_size = rep_n(sample_size),
    age_error = NA_real_, partition = NA_real_, weight_bin = rep_n(weight_bin),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
new_output <- function(type, measure, value, unit, year = NA_integer_,
    age = NA_real_, age_group = NA_character_, fleet = NA_character_,
    survey = NA_character_, region = NA_character_, season = NA_character_,
    scenario = NA_character_, source_reference, notes = "",
    source_type = "native_model") {
  n <- length(value)
  rep_n <- function(x) rep(x, length.out = n)
  data.frame(
    assessment_id = rep(assessment_id, n), type = rep_n(type),
    measure = rep_n(measure), fleet = rep_n(fleet), survey = rep_n(survey),
    sex = NA_character_, region = rep_n(region), season = rep_n(season),
    year = rep_n(year), age = rep_n(age), age_group = rep_n(age_group),
    value = value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = rep_n(unit), source_type = rep_n(source_type),
    source_reference = rep_n(source_reference), notes = rep_n(notes),
    scenario = rep_n(scenario), stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch_data <- frq_data[frq_data$fishery %in%
  fishery_data$fishery[fishery_data$flag != "IDX"], , drop = FALSE]
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
  observation_id = paste0("yft23_catch_y", catch_data$year, "_m",
    catch_data$month, "_w", catch_data$week, "_f", catch_data$fishery),
  source_reference = "MFCL/yft.frq, fishery-data catch field",
  transformation = "Preserved source catch and its fishery-specific number/weight flag; mapped month to model quarter.",
  notes = "Catch flag 0 is numbers of fish; flag 1 is biomass in metric tonnes."
)
effort_data <- frq_data[is.finite(frq_data$effort) & frq_data$effort >= 0, ,
  drop = FALSE]
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
  observation_id = paste0("yft23_effort_y", effort_data$year, "_m",
    effort_data$month, "_w", effort_data$week, "_f", effort_data$fishery),
  source_reference = "MFCL/yft.frq, fishery-data effort field",
  transformation = "Preserved non-negative source effort; omitted source -1 missing-value codes.",
  notes = "Effort units vary by fishery; retained on the native scale."
)
cpue_inputs <- new_input(
  type = "index", measure = "relative_abundance_index", basis = "index_scale",
  value = cpue_data$index, unit = "relative CPUE index", year = cpue_data$year,
  survey = fishery_identity(cpue_data$fishery, "code"),
  region = fishery_identity(cpue_data$fishery, "region"),
  season = season_label(cpue_data$season),
  sampling_time = (cpue_data$season - 0.5) / 4,
  observation_id = paste0("yft23_cpue_y", cpue_data$year, "_q",
    cpue_data$season, "_f", cpue_data$fishery),
  source_reference = "TAF/data/cpue.csv; derived from MFCL/yft.frq",
  transformation = "Preserved TAF index; verified as catch divided by effort and 1,000,000.",
  notes = "Five quarterly regional longline indices; sampling_time is the model-quarter midpoint, not an exact survey date."
)
composition_notes <- paste(
  "Preserved native MFCL frequency values without renormalization.",
  "sample_size is left blank because the source exports do not provide unweighted composition sample sizes."
)
length_inputs <- new_input(
  type = fishery_type(length_data$fishery), measure = "frequency_at_length",
  basis = "native_frequency", value = length_data$freq,
  unit = "native MFCL length frequency", year = length_data$year,
  fleet = fishery_dim(length_data$fishery, "fleet"),
  survey = fishery_dim(length_data$fishery, "survey"),
  region = fishery_identity(length_data$fishery, "region"),
  season = season_label(length_data$season),
  observation_id = paste0("yft23_length_y", length_data$year, "_q",
    length_data$season, "_f", length_data$fishery),
  length_bin = length_data$length, length_bin_lower = length_data$length,
  length_bin_upper = length_data$length + 2,
  source_reference = "TAF/data/length_comps.csv; 2 cm bins from the MFCL input",
  transformation = "Preserved source frequency values as supplied.",
  notes = paste(composition_notes,
    "length_bin_lower stores source lower bounds in centimetres; bins end at 198-200 cm.")
)
weight_inputs <- new_input(
  type = fishery_type(weight_data$fishery), measure = "frequency_at_weight",
  basis = "native_frequency", value = weight_data$freq,
  unit = "native MFCL weight frequency", year = weight_data$year,
  fleet = fishery_dim(weight_data$fishery, "fleet"),
  survey = fishery_dim(weight_data$fishery, "survey"),
  region = fishery_identity(weight_data$fishery, "region"),
  season = season_label(weight_data$season),
  observation_id = paste0("yft23_weight_y", weight_data$year, "_q",
    weight_data$season, "_f", weight_data$fishery),
  weight_bin = weight_data$weight,
  source_reference = "TAF/data/weight_comps.csv; 1 kg MFCL weight classes",
  transformation = "Preserved source frequency values and source weight-class codes as supplied.",
  notes = paste(composition_notes,
    "Source weight classes are coded 1-200 for bins 0-1 kg through 199-200 kg.")
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
caal_id <- function(data) paste0("yft23_caal_y", data$year, "_q",
  data$season, "_a", data$area, "_l", data$length)
age_length_inputs <- new_input(
  type = "biology", measure = "conditional_frequency_at_age",
  basis = "native_frequency", value = age_length_counts$count,
  unit = "fish", year = age_length_counts$year, age = age_length_counts$age,
  region = region_label(age_length_counts$area),
  season = season_label(age_length_counts$season),
  observation_id = caal_id(age_length_counts),
  length_bin_lower = age_length_counts$length,
  length_bin_upper = age_length_counts$length + 2,
  sample_size = age_length_counts$sample_size,
  source_reference = "TAF/data/otoliths.csv; grouped from individual age-at-length observations",
  transformation = "Counted source individuals by year, quarter, area, quarterly age class, and length.",
  notes = "Conditional age-at-length growth data, not marginal catch-at-age or an age-specific abundance index; the TAF export has no separate likelihood-weight field."
)
release_id <- paste0("yft23_tag_release_g", release_data$rel.group, "_",
  release_data$program, "_y", release_data$year, "_q",
  release_data$season, "_a", release_data$area)
tag_release_inputs <- new_input(
  type = "tag", measure = "tag_release_frequency_at_length",
  basis = "native_frequency", value = release_data$lendist,
  unit = "native MFCL release-frequency scale", year = release_data$year,
  region = region_label(release_data$area), season = season_label(release_data$season),
  observation_id = release_id, length_bin = release_data$length,
  source_reference = "TAF/data/tag_releases.csv; MFCL/yft.tag",
  transformation = "Preserved source lendist values and release-group dimensions.",
  notes = "The source does not establish lendist as an unweighted tag count; no multiplier is inferred."
)
recapture_id <- paste0("yft23_tag_g", recapture_data$rel.group, "_",
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
  source_reference = "TAF/data/tag_recaptures.csv; MFCL/yft.tag",
  transformation = "Preserved recapture counts and associated release-group keys.",
  notes = "length_bin identifies the release length; fleet, region, and quarter identify recapture."
)
diagnostic_notes <- paste(
  "Single Diagnostic2023 reference fit from the pinned SPC TAF repository; not a 54-model grid summary.",
  "No standard errors or intervals are supplied in these TAF output files."
)
scenario <- "Diagnostic2023 reference fit"
age_group <- "quarterly age class"
catch_keep <- catch_output$fishery %in%
  fishery_data$fishery[fishery_data$flag != "IDX"]
outputs <- rbind(
  new_output("population", "numbers_at_age", n_output$n, "fish",
    year = n_output$year, age = n_output$age, age_group = age_group,
    region = region_label(n_output$area), season = season_label(n_output$season),
    scenario = scenario, source_reference = "TAF/output/natage.csv",
    notes = paste(diagnostic_notes, "Age class 40 is the plus group.")),
  new_output("mortality", "fishing_mortality_at_age", f_output$f, "per year",
    year = f_output$year, age = f_output$age, age_group = age_group,
    region = region_label(f_output$area), scenario = scenario,
    source_reference = "TAF/output/f_annual.csv",
    notes = paste(diagnostic_notes, "F is annualized; regional rows and all-area aggregate are retained.")),
  new_output("biology", "mature_biomass_at_age", batage_output$sb, "metric tonnes",
    year = batage_output$year, age = batage_output$age, age_group = age_group,
    region = region_label(batage_output$area),
    season = season_label(batage_output$season), scenario = scenario,
    source_reference = "TAF/output/batage.csv; source TAF/output_pop.R",
    notes = paste(diagnostic_notes, "Derived as N × weight-at-age / 1,000 × maturity-at-age.")),
  new_output("biology", "growth_length_at_age", biology_output$length, "cm",
    age = biology_output$age, age_group = age_group, scenario = scenario,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived length-at-age; age classes are quarterly."),
  new_output("biology", "weight_at_age", biology_output$weight, "kg per fish",
    age = biology_output$age, age_group = age_group, scenario = scenario,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived weight-at-age; not a direct observation input."),
  new_output("biology", "maturity_at_age", biology_output$maturity, "proportion",
    age = biology_output$age, age_group = age_group, scenario = scenario,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived maturity-at-age; not a direct observation input."),
  new_output("mortality", "natural_mortality_at_age", biology_output$natmort, "per year",
    age = biology_output$age, age_group = age_group, scenario = scenario,
    source_reference = "TAF/output/biology.csv",
    notes = "Model-derived natural mortality at age; no output uncertainty is supplied."),
  new_output("biomass", "spawning_potential_biomass", biomass_output$sb,
    "metric tonnes", year = biomass_output$year,
    region = region_label(biomass_output$area),
    season = season_label(biomass_output$season), scenario = scenario,
    source_reference = "TAF/output/biomass.csv, source field sb",
    notes = paste(diagnostic_notes, "Quarterly and area-specific source outputs.")),
  new_output("catch", "predicted_catch", catch_output$catch[catch_keep],
    ifelse(catch_flags[catch_output$fishery[catch_keep]] == 0L,
      "fish", "metric tonnes"),
    year = catch_output$year[catch_keep],
    fleet = fishery_identity(catch_output$fishery[catch_keep], "code"),
    region = region_label(catch_output$area[catch_keep]),
    season = season_label(catch_output$season[catch_keep]),
    scenario = scenario, source_reference = "TAF/output/catch.csv",
    notes = paste(diagnostic_notes, "Index-fishery pseudo-catch rows are excluded.")),
  new_output("index", "predicted_index", cpue_output$pred,
    "relative CPUE index", year = cpue_output$year,
    survey = fishery_identity(cpue_output$fishery, "code"),
    region = region_label(cpue_output$area),
    season = season_label(cpue_output$season), scenario = scenario,
    source_reference = "TAF/output/cpue.csv, field pred",
    notes = paste(diagnostic_notes, "Fitted predictions on the source relative-CPUE scale.")),
  new_output("recruitment", "recruitment", summary_output$rec, "fish",
    year = summary_output$year, scenario = scenario,
    source_reference = "TAF/output/summary.csv, field rec",
    notes = "Source-defined recruitment retained without reinterpretation of quarterly age-class scaling."),
  new_output("catch", "predicted_catch", summary_output$catch, "metric tonnes",
    year = summary_output$year, scenario = scenario,
    source_reference = "TAF/output/summary.csv, field catch",
    notes = paste(diagnostic_notes, "Annual total catch on the source scale.")),
  new_output("biomass", "total_biomass", summary_output$tb, "metric tonnes",
    year = summary_output$year, scenario = scenario,
    source_reference = "TAF/output/summary.csv, field tb",
    notes = "Source-defined annual total biomass."),
  new_output("biomass", "spawning_potential_biomass", summary_output$sb,
    "metric tonnes", year = summary_output$year, scenario = scenario,
    source_reference = "TAF/output/summary.csv, field sb",
    notes = "Source-defined annual spawning biomass."),
  new_output("biomass", "unfished_spawning_potential_biomass",
    summary_output$sbf0, "metric tonnes", year = summary_output$year,
    scenario = scenario, source_reference = "TAF/output/summary.csv, field sbf0",
    notes = "Source-defined unfished spawning biomass."),
  new_output("biomass", "spawning_output_ratio_to_unfished",
    summary_output$dep, "ratio", year = summary_output$year,
    scenario = scenario, source_reference = "TAF/output/summary.csv, field dep",
    notes = "Preserved the source spawning-biomass ratio to its unfished reference."),
  new_output("mortality", "mean_fishing_mortality", summary_output$f,
    "per year", year = summary_output$year, scenario = scenario,
    source_reference = "TAF/output/summary.csv, field f",
    notes = diagnostic_notes),
  new_output("biomass", "spawning_potential_biomass", grid_median$SB,
    "metric tonnes", year = grid_median$Year, scenario = "54-model grid median",
    source_reference = "notes/median_sb_time_series.csv",
    notes = "Median annual spawning biomass across the 54-model structural grid; the summary does not include annual uncertainty intervals."),
  do.call(rbind, lapply(seq_len(nrow(grid_uncertainty)), function(i) {
    stat_names <- c("Mean", "Median", "Min", "10%ile", "90%ile", "Max")
    stat_labels <- c("mean", "median", "minimum", "10th percentile",
      "90th percentile", "maximum")
    grid_measures <- c(depletion = "SSB_ratio_to_B0",
      ffmsy = "F_ratio_to_Fmsy", sbsbmsy = "SSB_ratio_to_SSBMSY")
    grid_types <- c(depletion = "biomass", ffmsy = "mortality",
      sbsbmsy = "biomass")
    refpt <- grid_uncertainty$Refpt[i]
    if (!refpt %in% names(grid_measures)) {
      stop("Unexpected 2023 reference-point label: ", refpt)
    }
    do.call(rbind, lapply(seq_along(stat_names), function(j) {
      new_output(grid_types[[refpt]], grid_measures[[refpt]],
        as.numeric(grid_uncertainty[[stat_names[j]]][i]), "ratio",
        year = 2021L,
        scenario = paste("54-model grid plus estimation uncertainty:",
          stat_labels[j]),
        source_reference = "notes/estimation_uncertainty.csv",
        notes = paste0("Terminal-year 2021 ", refpt,
          " distribution statistic. The 10th and 90th percentiles are not confidence limits.")
      )
    }))
  }))
)
input_rows <- rbind(
  catch_inputs, effort_inputs, cpue_inputs, length_inputs, weight_inputs,
  age_length_inputs, tag_release_inputs, tag_recapture_inputs
)
new_assumption <- function(component, setting, value, source_reference, notes) {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE)
}
assumptions <- do.call(rbind, list(
  new_assumption("model structure", "temporal_resolution",
    "Quarterly, four model quarters per year",
    "WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 5.2; TAF/output files",
    "The assessment time window is 1952-2021; quarters are retained in input and output rows."),
  new_assumption("model structure", "spatial_regions", "Five MFCL model regions",
    "WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 5.2; TAF/data/fisheries.csv",
    "Areas 1-5 remain MFCL area codes."),
  new_assumption("model structure", "age_classes",
    "40 quarterly age classes; class 40 is a plus group",
    "WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 5.2",
    "The source codes are quarterly classes, not 40 annual ages."),
  new_assumption("assessment design", "structural_uncertainty_grid",
    "54 combinations of tag mixing 1/2 quarters, size divisor 10/20/40, age-data weight 0.50/0.75/1.00, and steepness 0.65/0.80/0.95",
    "WCPFC-SC19-2023/SA-WP-04 Rev. 02, Sections 6.2-6.3; SPC notes/README.md",
    "Reference levels are 2 quarters, divisor 20, age-data weight 0.75, and steepness 0.80. Diagnostic TAF surfaces are not grid means."),
  new_assumption("catch", "catch_units",
    "MFCL catch flag 0 = numbers of fish; flag 1 = metric tonnes",
    "MFCL/yft.frq data flags; WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 4.5",
    "Catch values retain the fishery-specific source flag and native scale."),
  new_assumption("effort", "effort_units", "Fishery-specific native effort units",
    "MFCL/yft.frq; WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 4.5",
    "Non-negative effort is preserved; source -1 values denote missing effort and are not imputed."),
  new_assumption("index", "regional_cpue",
    "Five quarterly standardized longline CPUE series, 1952-2021",
    "TAF/data/cpue.csv; MFCL/yft.frq",
    "Values are verified as native catch / effort / 1,000,000. Quarter midpoint is model time, not exact survey timing."),
  new_assumption("composition", "size_frequencies",
    "Length and weight compositions preserved on native frequency scales",
    "TAF/data/length_comps.csv; TAF/data/weight_comps.csv; WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 4.6",
    "Length bins are 2 cm; weight classes are 1 kg from 0-1 kg through 199-200 kg. Exports lack unweighted sample sizes."),
  new_assumption("growth", "conditional_age_at_length",
    "Conditional age-at-length observations used as growth data",
    "TAF/data/otoliths.csv; WCPFC-SC19-2023/SA-WP-04 Rev. 02, Section 5.5",
    "These are not catch-at-age or age-specific abundance observations; the TAF export has no separate likelihood-weight field."),
  new_assumption("tagging", "tag_data",
    "Tag release-frequency distributions and recapture counts",
    "TAF/data/tag_releases.csv; TAF/data/tag_recaptures.csv; MFCL/yft.tag",
    "Release frequencies remain on the supplied scale; no unreported count conversion is applied."),
  new_assumption("biology", "biological_surfaces",
    "Length, weight, maturity, and natural mortality at age are model-derived outputs",
    "TAF/output/biology.csv; TAF/output_pop.R",
    "No independent observed weight-at-age or maturity-at-age vectors are supplied by this source package."),
  new_assumption("assessment outputs", "uncertainty",
    "One diagnostic fit plus a 54-model grid and grid-plus-estimation reference summaries",
    "Pinned SPC 2023 diagnostic and grid repositories",
    "Diagnostic age-specific outputs have no SE or intervals. The terminal 10th/90th percentiles are distribution summaries, not confidence limits.")
))
stock_path <- file.path(root, "database/stocks.csv")
assessments_path <- file.path(root, "database/assessments.csv")
stock_table <- read.csv(stock_path, stringsAsFactors = FALSE, check.names = FALSE)
if (!stock_id %in% stock_table$stock_id) stop("Expected existing WCPO yellowfin stock.")
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2023L, terminal_year = 2021L,
  estimate_terminal_year = 2021L, assessment_type = "full_assessment",
  model_family = "MULTIFAN-CL",
  model_version = "2023 diagnostic reference fit (MFCL model 11)",
  is_current = "FALSE", is_applied = "TRUE", framework_year = NA_integer_,
  assessment_url = "https://meetings.wcpfc.int/node/19352",
  framework_url = NA_character_,
  data_url = paste0("https://github.com/PacificCommunity/ofp-sam-yft-2023-diagnostic/tree/",
    diagnostic_revision),
  model_url = paste0("https://github.com/PacificCommunity/ofp-sam-yft-2023-diagnostic/tree/",
    diagnostic_revision),
  repository_url = paste0("https://github.com/PacificCommunity/ofp-sam-yft-2023-diagnostic/tree/",
    diagnostic_revision),
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The 2023 assessment, using data through 2021, remains the advice basis identified after WCPFC SC22; the newer 2026 detailed run is separately recorded and its advice review was deferred.",
    "This record preserves one diagnostic reference fit plus explicitly separate 54-model grid summaries, not a fitted ensemble mean.",
    "Input and output completeness remain partial: no direct catch-at-age or age-specific abundance index was recovered, and diagnostic age-specific outputs have no uncertainty estimates."
  ),
  stringsAsFactors = FALSE
)
if (!identical(names(input_rows), input_columns) ||
    !identical(names(outputs), output_columns) ||
    !identical(names(assumptions), assumption_columns) ||
    !identical(names(assessment), names(read.csv(assessments_path, nrows = 0L,
      stringsAsFactors = FALSE, check.names = FALSE))) ||
    nrow(age_length_counts) != 1249L || nrow(age_length_sample) != 944L ||
    nrow(input_rows) != 788074L || nrow(outputs) != 141298L ||
    sum(input_rows$measure == "catch_numbers") +
      sum(input_rows$measure == "catch_biomass") != 6588L ||
    sum(input_rows$measure == "effort") != 1709L ||
    sum(input_rows$measure == "relative_abundance_index") != 1400L ||
    sum(input_rows$measure == "frequency_at_length") != 135090L ||
    sum(input_rows$measure == "frequency_at_weight") != 622800L ||
    sum(input_rows$measure == "conditional_frequency_at_age") != 1249L ||
    sum(input_rows$measure == "tag_release_frequency_at_length") != 13300L ||
    sum(input_rows$measure == "tag_recapture_count") != 5938L ||
    sum(outputs$measure == "numbers_at_age") != 56000L ||
    sum(outputs$measure == "fishing_mortality_at_age") != 16800L ||
    sum(outputs$measure == "mature_biomass_at_age") != 56000L ||
    sum(outputs$measure == "predicted_index") != 1400L ||
    sum(outputs$measure == "predicted_catch") != 9030L) {
  stop("Constructed 2023 yellowfin rows differ from reviewed source coverage.")
}
cat("Prepared 2023 WCPO yellowfin import: ", nrow(assumptions),
  " assumptions, ", nrow(input_rows), " inputs, and ", nrow(outputs),
  " outputs.\n", sep = "")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to append the records.\n")
  quit(save = "no", status = 0L)
}

read_assessment_rows <- function(path, id) {
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "--no-filename", "-F", id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(NULL)
  if (status != 0L) stop("Could not search assessment rows in ", path, ".")
  rows <- rows[startsWith(rows, paste0('"', id, '",'))]
  if (!length(rows)) return(NULL)
  header <- readLines(path, n = 1L, warn = FALSE)
  temporary_csv <- tempfile(fileext = ".csv", tmpdir = "tmp")
  writeLines(c(header, rows), temporary_csv, useBytes = TRUE)
  on.exit(unlink(temporary_csv), add = TRUE)
  read.csv(temporary_csv, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}
row_signature <- function(data) {
  values <- lapply(data, function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  do.call(paste, c(values, sep = "\r"))
}
identical_rows <- function(path, rows) {
  existing <- read_assessment_rows(path, assessment_id)
  if (is.null(existing)) return(FALSE)
  nrow(existing) == nrow(rows) &&
    identical(sort(row_signature(existing)), sort(row_signature(rows)))
}
append_csv_rows <- function(name, rows) {
  path <- file.path(root, "database", name)
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  if (!identical(header, names(rows))) stop("Unexpected database schema in ", name, ".")
  size <- file.info(path)$size
  con <- file(path, open = "rb")
  seek(con, where = max(0, size - 2), origin = "start")
  ending <- readBin(con, what = "raw", n = min(2, size))
  close(con)
  eol <- if (length(ending) == 2L &&
    identical(ending, as.raw(c(13L, 10L)))) "\r\n" else "\n"
  if (!length(ending) || tail(ending, 1L) != as.raw(10L)) {
    append_con <- file(path, open = "ab")
    writeBin(charToRaw(eol), append_con)
    close(append_con)
  }
  write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
    eol = eol, append = TRUE)
}
database_rows <- list(
  "assessments.csv" = assessment,
  "assumptions.csv" = assumptions,
  "inputs.csv" = input_rows,
  "outputs.csv" = outputs
)
all_present <- vapply(names(database_rows), function(name) {
  identical_rows(file.path(root, "database", name), database_rows[[name]])
}, logical(1))
if (all(all_present)) {
  cat("The 2023 assessment import is already present and identical.\n")
  quit(save = "no", status = 0L)
}
if (any(vapply(names(database_rows), function(name) {
  !is.null(read_assessment_rows(file.path(root, "database", name), assessment_id))
}, logical(1)))) {
  stop("A partial or conflicting 2023 assessment import already exists; refusing to append.")
}
for (name in names(database_rows)) append_csv_rows(name, database_rows[[name]])
cat("Appended the 2023 WCPO yellowfin assessment.\n")
