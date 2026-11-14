root <- "."
assessment_id <- "noaa_south_atlantic_spanish_mackerel_2022"
candidate_id <- "NOAA:10174"
stock_id <- "noaa_south_atlantic_spanish_mackerel"
report_path <- file.path(root, "source_cache/noaa_south_atlantic_spanish_mackerel_2022/sedar78_assessment_revised_july_2022.pdf")
manifest_path <- file.path(root, "provenance/noaa_south_atlantic_spanish_mackerel_2022_sources.csv")
candidate_path <- file.path(root, "discovery/candidates.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("The pdftools package is required to read the cached assessment tables.", call. = FALSE)
}
if (!file.exists(report_path) || !file.exists(manifest_path)) {
  stop("The cached SEDAR 78 report and provenance manifest are required.", call. = FALSE)
}

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == "windows") "\\" else "/", mustWork = TRUE)
  if (.Platform$OS.type == "windows") {
    output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    hashes <- trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", output, value = TRUE))
  } else {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE)
    hashes <- sub("[[:space:]].*$", "", output[1L])
  }
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for the cached report.", call. = FALSE)
  tolower(hashes)
}

manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
report_manifest <- manifest[manifest$file == basename(report_path), , drop = FALSE]
if (nrow(report_manifest) != 1L ||
    as.numeric(report_manifest$size_bytes) != file.info(report_path)$size ||
    tolower(report_manifest$sha256) != sha256_file(report_path)) {
  stop("The cached SEDAR 78 report does not match its tracked provenance.", call. = FALSE)
}

make_row <- function(fields, values) {
  row <- as.list(stats::setNames(rep("", length(fields)), fields))
  for (nm in intersect(names(values), fields)) {
    value <- values[[nm]]
    row[[nm]] <- if (!length(value) || is.na(value[1L])) "" else as.character(value[1L])
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}
make_rows <- function(fields, rows) {
  if (!length(rows)) {
    return(as.data.frame(stats::setNames(replicate(length(fields), character(), simplify = FALSE), fields),
      check.names = FALSE))
  }
  do.call(rbind, rows)
}
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
append_csv <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  fields <- read_fields(path)
  if (length(setdiff(fields, names(rows)))) stop("Proposed rows do not match ", path, ".", call. = FALSE)
  utils::write.table(rows[fields], path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "
")
}
read_rows_csv <- function(records) {
  connection <- textConnection(records)
  on.exit(close(connection))
  utils::read.csv(connection, stringsAsFactors = FALSE, colClasses = "character",
    check.names = FALSE, na.strings = c("", "NA"))
}
read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  lines <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    lines <- c(lines, chunk[startsWith(chunk, prefix)])
  }
  if (!length(lines)) return(read_rows_csv(header))
  read_rows_csv(c(header, lines))
}
normalize_rows <- function(rows) {
  rows[] <- lapply(rows, function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  rows
}
row_keys <- function(rows, fields) {
  do.call(paste, c(lapply(rows[fields], function(x) ifelse(is.na(x), "", as.character(x))), sep = "
"))
}
rows_to_add <- function(existing, proposed, key_fields, table_name) {
  existing <- normalize_rows(existing)
  proposed <- normalize_rows(proposed)
  old_keys <- row_keys(existing, key_fields)
  new_keys <- row_keys(proposed, key_fields)
  if (anyDuplicated(new_keys)) stop("Proposed ", table_name, " rows contain duplicate source keys.", call. = FALSE)
  for (i in which(new_keys %in% old_keys)) {
    j <- match(new_keys[i], old_keys)
    if (!identical(unlist(existing[j, names(proposed), drop = FALSE], use.names = FALSE),
        unlist(proposed[i, , drop = FALSE], use.names = FALSE))) {
      stop("An existing ", table_name, " key has a different value.", call. = FALSE)
    }
  }
  proposed[!new_keys %in% old_keys, , drop = FALSE]
}
ensure_append <- function(path, proposed, id_field, append_missing = FALSE) {
  existing <- read_csv(path)
  found <- which(existing[[id_field]] == proposed[[id_field]][1L])
  if (!length(found)) {
    if (append_missing) append_csv(path, proposed)
  } else if (length(found) != 1L ||
      !identical(unlist(normalize_rows(existing[found, names(proposed), drop = FALSE]), use.names = FALSE),
        unlist(normalize_rows(proposed), use.names = FALSE))) {
    stop("Existing ", id_field, " does not match the reviewed SEDAR 78 record.", call. = FALSE)
  }
}
stock_fields <- read_fields("database/stocks.csv")
assessment_fields <- read_fields("database/assessments.csv")
assumption_fields <- read_fields("database/assumptions.csv")
input_fields <- read_fields("database/inputs.csv")
output_fields <- read_fields("database/outputs.csv")

assumption_row <- function(component, setting, value, source_reference, notes = "",
    fleet = "", survey = "", sex = "", region = "", season = "") {
  make_row(assumption_fields, list(
    assessment_id = assessment_id, component = component, fleet = fleet, survey = survey,
    sex = sex, region = region, season = season, setting = setting, value = value,
    source_reference = source_reference, notes = notes
  ))
}
input_row <- function(type, measure, basis, value, unit, source_reference, notes = "",
    fleet = "", survey = "", sex = "", region = "", season = "", year = "", year_basis = "",
    age = "", sampling_time = "", transformation = "", observation_id = "",
    sample_size = "", partition = "") {
  make_row(input_fields, list(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = year, year_basis = year_basis, age = age, value = value, unit = unit,
    sampling_time = sampling_time, source_type = "official_table",
    source_reference = source_reference, transformation = transformation, notes = notes,
    observation_id = observation_id, sample_size = sample_size, partition = partition
  ))
}
output_row <- function(type, measure, value, unit, source_reference, notes = "",
    fleet = "", survey = "", sex = "", region = "", season = "", year = "", age = "",
    age_group = "", scenario = "", se = "", lwr = "", upr = "") {
  make_row(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season, year = year,
    age = age, age_group = age_group, scenario = scenario, value = value, se = se,
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes
  ))
}

pdf_pages <- pdftools::pdf_text(report_path)[90:109]
get_table_lines <- function(number, kind = "year") {
  current <- NA_integer_
  result <- character()
  pattern <- if (kind == "year") "^\\s*(19|20)[0-9]{2}\\b" else "^\\s*(10|[0-9])\\s+"
  for (page in pdf_pages) {
    for (line in strsplit(page, "\\n", fixed = FALSE)[[1L]]) {
      match <- regmatches(line, regexec("Table\\s+([0-9]+)\\.", line, perl = TRUE))[[1L]]
      if (length(match) == 2L) current <- as.integer(match[2L])
      if (!is.na(current) && current == number && grepl(pattern, line, perl = TRUE)) {
        result <- c(result, line)
      }
    }
  }
  result
}
numeric_tokens <- function(line) {
  token <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
  token <- gsub(",", "", token, fixed = TRUE)
  token <- gsub("\\u2212", "-", token, fixed = TRUE)
  token[token %in% c(".", "·", "–", "—")] <- NA_character_
  suppressWarnings(as.numeric(token))
}
parse_table <- function(number, width, expected_rows, kind = "year") {
  lines <- get_table_lines(number, kind)
  if (length(lines) != expected_rows) {
    stop("Table ", number, " expected ", expected_rows, " rows; found ", length(lines), ".", call. = FALSE)
  }
  values <- lapply(lines, numeric_tokens)
  if (any(lengths(values) != width)) {
    stop("Table ", number, " contains a row with an unexpected number of values.", call. = FALSE)
  }
  result <- as.data.frame(do.call(rbind, values), check.names = FALSE)
  names(result) <- c(if (kind == "year") "year" else "age",
    paste0("v", seq_len(width - 1L)))
  result
}
table_ref <- function(table, page) paste0("SEDAR 78 SAR, Table ", table, ", printed p. ", page)
age_note <- "Age 10 is the 10+ plus group as defined in the assessment."

T1 <- parse_table(1, 9, 11, "age")
T2 <- parse_table(2, 8, 35, "year")
T3 <- parse_table(3, 7, 35, "year")
T4 <- parse_table(4, 14, 1, "year")
T5 <- parse_table(5, 14, 28, "year")
T6 <- parse_table(6, 14, 19, "year")
T7 <- parse_table(7, 14, 1, "year")
T8 <- parse_table(8, 14, 26, "year")
T9 <- parse_table(9, 13, 36, "year")
T10 <- parse_table(10, 13, 36, "year")
T11 <- parse_table(11, 9, 36, "year")
T12 <- parse_table(12, 12, 11, "age")
T13 <- parse_table(13, 9, 35, "year")
T14 <- parse_table(14, 12, 35, "year")
T15 <- parse_table(15, 12, 35, "year")
T16 <- parse_table(16, 12, 35, "year")
T17 <- parse_table(17, 12, 35, "year")
T18 <- parse_table(18, 10, 35, "year")
T19 <- parse_table(19, 10, 35, "year")
T20 <- parse_table(20, 12, 35, "year")
T21 <- parse_table(21, 12, 35, "year")

stock_row <- make_row(stock_fields, list(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA Fisheries",
  authority_stock_id = "Spanish mackerel - Southern Atlantic Coast (NOAA Stock SMART 10174)",
  scientific_name = "Scomberomorus maculatus", common_name = "Spanish mackerel",
  area = "South Atlantic Coast, New York/Rhode Island boundary to Miami-Dade/Monroe County boundary",
  region = "United States South Atlantic", ocean = "Northwest Atlantic",
  notes = "Distinct South Atlantic management unit from the Gulf of Mexico Spanish mackerel unit."
))
assessment_row <- make_row(assessment_fields, list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2022L,
  terminal_year = 2020L, estimate_terminal_year = 2021L, assessment_type = "full_assessment",
  model_family = "BAM", model_version = "SEDAR 78 base-run Beaufort Assessment Model",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "",
  assessment_url = "https://sedarweb.org/documents/sedar-78-stock-assessment-report-south-atlantic-spanish-mackerel-revised-july-2022/",
  framework_url = "", data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Production assessment completed in 2022 and applied for 2023 catch advice. The fitted period ends in 2020; Tables 9-11 also print selected 2021 interim estimates. The final report provides numerical tables but no native fitted model files were located."
))

assumptions <- list(
  assumption_row("population", "model_structure", "Beaufort Assessment Model (BAM), catch-age population model", "SEDAR 78 SAR, Sections 3.4 and 3.19", "The assessment describes age-structured population dynamics and a penalized-likelihood fit."),
  assumption_row("population", "modeled_ages", "0-10+", "SEDAR 78 SAR, Section 3.4", "The age-10 class is a plus group."),
  assumption_row("population", "sex_ratio", "50:50", "SEDAR 78 SAR, Section 3.4", "The assessment uses female and male population components with an assumed equal sex ratio."),
  assumption_row("population", "initial_abundance", "Stable age structure based on expected recruitment and initial age-specific total mortality; 1986 recruitment estimated", "SEDAR 78 SAR, Section 3.5", "The initial fishing rate used a starting value of 0.5 and no prior in the official model; this records the assessment setup, not a tinyAM starting-value recommendation."),
  assumption_row("recruitment", "stock_recruitment_steepness", "0.75 fixed", "SEDAR 78 SAR, stock-recruitment model specification", "Steepness is fixed in the production model."),
  assumption_row("natural_mortality", "time_variation", "Constant over time; age-specific Lorenzen schedule", "SEDAR 78 SAR, Section 3.6 and Table 1, printed p. 36", "Table 1 values are also stored as age-specific input records."),
  assumption_row("natural_mortality", "reference_scaling", "Lorenzen M schedule scaled to match survival under constant M=0.35 per year from age 2 to the oldest age", "SEDAR 78 SAR, Table 1, printed p. 36", "The age-specific Table 1 schedule is preserved without rescaling."),
  assumption_row("catch", "commercial_discard_treatment", "Commercial discard estimates combined with corresponding landings", "SEDAR 78 SAR, removals input specification; SEDAR 78-WP11", "The reported Table 2 commercial series are retained as supplied."),
  assumption_row("catch", "general_recreational_discard_mortality", "0.2", "SEDAR 78 SAR, removals input specification", "Applied to released general-recreational fish; Table 2 reports all discards, live or dead."),
  assumption_row("catch", "shrimp_bycatch_mortality", "1.0", "SEDAR 78 SAR, shrimp-bycatch input specification; SEDAR 78-WP04", "Shrimp-trawl bycatch is assumed fully dead."),
  assumption_row("observation", "composition_likelihood", "Dirichlet-multinomial", "SEDAR 78 SAR, Section 3.19", "Composition data are fitted only when fish count >10 and trip count >=10. Source vectors remain proportions with their reported sample counts."),
  assumption_row("observation", "removals_and_index_likelihood", "Lognormal", "SEDAR 78 SAR, Section 3.19", "The report states that observed removals and abundance indices are fit with lognormal likelihoods."),
  assumption_row("index", "fishery_dependent_index_timing", "Midyear (0.5)", "SEDAR 78 SAR, Section 3.16", "The model predicts fishery-dependent indices from midyear abundance; the handline index is related to biomass."),
  assumption_row("index", "SEAMAP_survey_timing", "unknown", "SEDAR 78-WP01 and SEDAR 78-WP02", "The survey samples in spring, summer, and fall; the sources do not support a single within-year fraction."),
  assumption_row("biology", "SSB_timing", "unknown due source inconsistency", "SEDAR 78 SAR, Table 11, printed p. 44; spawning timing discussion", "Table 11 states end of July, while the methods text describes peak spawning as June 1.")
)

input_rows <- list()
add_input <- function(...) input_rows[[length(input_rows) + 1L]] <<- input_row(...)

# Inputs: catches, indices, compositions, and biology
catch_specs <- list(
  list(col = "v1", fleet = "Commercial handline", measure = "landings_biomass", basis = "biomass", unit = "1000 lb whole weight"),
  list(col = "v2", fleet = "Commercial gillnet", measure = "landings_biomass", basis = "biomass", unit = "1000 lb whole weight"),
  list(col = "v3", fleet = "Commercial pound net", measure = "landings_biomass", basis = "biomass", unit = "1000 lb whole weight"),
  list(col = "v4", fleet = "Commercial cast net", measure = "landings_biomass", basis = "biomass", unit = "1000 lb whole weight"),
  list(col = "v5", fleet = "General recreational", measure = "landings_numbers", basis = "numbers", unit = "1000 fish"),
  list(col = "v6", fleet = "Shrimp-trawl bycatch", measure = "discard_numbers", basis = "numbers", unit = "1000 fish"),
  list(col = "v7", fleet = "General recreational", measure = "discard_numbers", basis = "numbers", unit = "1000 fish")
)
for (i in seq_len(nrow(T2))) {
  for (spec in catch_specs) {
    value <- T2[[spec$col]][i]
    if (is.finite(value)) {
      detail <- if (spec$col == "v6") "Assumed fully dead in the assessment." else
        if (spec$col == "v7") "All releases, live or dead; the source model applies 0.2 discard mortality." else
          "Reported assessment removal series; see the source discard-treatment assumptions."
      add_input(type = "catch", measure = spec$measure, basis = spec$basis,
        value = value, unit = spec$unit, fleet = spec$fleet, year = T2$year[i],
        year_basis = "calendar_year", source_reference = table_ref(2, 37),
        notes = paste("Source series.", detail))
    }
  }
}

index_specs <- list(
  list(value = "v1", cv = "v2", fleet = "Commercial handline", survey = "",
    measure = "relative_biomass_index", cv_measure = "biomass_index_cv",
    unit = "relative index (source scale)", timing = "0.5",
    notes = "Florida commercial handline trip-ticket index, modeled against midyear biomass."),
  list(value = "v3", cv = "v4", fleet = "General recreational", survey = "",
    measure = "relative_abundance_index", cv_measure = "abundance_index_cv",
    unit = "relative index (source scale)", timing = "0.5",
    notes = "MRIP general-recreational index, modeled against midyear abundance."),
  list(value = "v5", cv = "v6", fleet = "", survey = "SEAMAP-SA coastal trawl YOY",
    measure = "recruitment_index", cv_measure = "recruitment_index_cv",
    unit = "YOY index (source scale)", timing = "",
    notes = "Age-0 recruitment index. Sampling occurs across spring, summer, and fall; no single sampling-time fraction is documented.")
)
for (i in seq_len(nrow(T3))) {
  for (spec in index_specs) {
    value <- T3[[spec$value]][i]
    cv <- T3[[spec$cv]][i]
    if (is.finite(value)) {
      add_input(type = "index", measure = spec$measure, basis = "index_scale",
        value = value, unit = spec$unit, fleet = spec$fleet, survey = spec$survey,
        year = T3$year[i], year_basis = "calendar_year", sampling_time = spec$timing,
        source_reference = table_ref(3, 38), notes = spec$notes)
      if (is.finite(cv)) {
        add_input(type = "index", measure = spec$cv_measure, basis = "relative_scale",
          value = cv, unit = "ratio", fleet = spec$fleet, survey = spec$survey,
          year = T3$year[i], year_basis = "calendar_year",
          source_reference = table_ref(3, 38), notes = "Source-reported coefficient of variation.")
      }
    }
  }
}

composition_specs <- list(
  list(table = 4, data = T4, fleet = "Commercial handline", code = "cH",
    midpoint = 2007L, composition = "Pooled across all years; nominal composition."),
  list(table = 5, data = T5, fleet = "Commercial gillnet", code = "cG",
    midpoint = NA_integer_, composition = "Annual composition; weighted using length composition."),
  list(table = 6, data = T6, fleet = "Commercial pound net", code = "cP",
    midpoint = NA_integer_, composition = "Annual nominal composition."),
  list(table = 7, data = T7, fleet = "Commercial cast net", code = "cC",
    midpoint = 2010L, composition = "Pooled across all years; nominal composition."),
  list(table = 8, data = T8, fleet = "General recreational", code = "GR",
    midpoint = NA_integer_, composition = "Annual nominal composition.")
)
composition_pages <- stats::setNames(c(39, 39, 40, 41, 41), as.character(4:8))
for (spec in composition_specs) {
  dat <- spec$data
  for (i in seq_len(nrow(dat))) {
    pooled <- is.finite(spec$midpoint)
    year <- if (pooled) "" else as.character(dat$year[i])
    midpoint_note <- if (pooled) paste0(" Printed midpoint year ", spec$midpoint, " is not a single sample year.") else ""
    observation_id <- if (pooled) {
      paste0("SEDAR78_Table", spec$table, "_", spec$code, "_pooled_midpoint_", spec$midpoint)
    } else paste0("SEDAR78_Table", spec$table, "_", spec$code, "_", dat$year[i])
    fish <- dat$v2[i]
    trips <- dat$v1[i]
    notes <- paste(age_note, spec$composition, paste0("Source reports ", trips,
      " trips and ", fish, " fish."), midpoint_note)
    for (age in 0:10) {
      value <- dat[[paste0("v", age + 3L)]][i]
      if (!is.finite(value)) stop("Missing composition value in Table ", spec$table, ".", call. = FALSE)
      add_input(type = "catch", measure = "proportion_at_age", basis = "proportion_numbers",
        value = value, unit = "proportion", fleet = spec$fleet, year = year,
        year_basis = if (pooled) "" else "calendar_year", age = age,
        source_reference = table_ref(spec$table, composition_pages[as.character(spec$table)]),
        notes = notes, observation_id = observation_id, sample_size = fish)
    }
    add_input(type = "catch", measure = "composition_sample_count", basis = "native_frequency",
      value = trips, unit = "trips", fleet = spec$fleet, year = year,
      year_basis = if (pooled) "" else "calendar_year",
      source_reference = table_ref(spec$table, composition_pages[as.character(spec$table)]),
      notes = paste0("Trip count for the associated composition; fish count is retained in sample_size. ", notes),
      observation_id = paste0(observation_id, "_trips"))
  }
}

for (i in seq_len(nrow(T1))) {
  age <- T1$age[i]
  add_input(type = "biology", measure = "growth_length_at_age", basis = "native_covariate",
    value = T1$v1[i], unit = "inches fork length", age = age,
    source_reference = table_ref(1, 36), notes = paste(age_note, "Population length-at-age."))
  add_input(type = "weight", measure = "weight_at_age", basis = "weight_per_fish",
    value = T1$v2[i], unit = "lb whole weight per fish", age = age,
    source_reference = table_ref(1, 36), notes = paste(age_note, "Population mean weight-at-age."))
  add_input(type = "biology", measure = "growth_length_at_age", basis = "native_covariate",
    value = T1$v3[i], unit = "inches fork length", age = age, sex = "female",
    source_reference = table_ref(1, 36), notes = paste(age_note, "Female population length-at-age."))
  add_input(type = "weight", measure = "weight_at_age", basis = "weight_per_fish",
    value = T1$v4[i], unit = "lb whole weight per fish", age = age, sex = "female",
    source_reference = table_ref(1, 36), notes = paste(age_note, "Female population mean weight-at-age."))
  add_input(type = "biology", measure = "growth_length_at_age", basis = "native_covariate",
    value = T1$v5[i], unit = "inches fork length", age = age, fleet = "Fishery-dependent population",
    source_reference = table_ref(1, 36), notes = paste(age_note, "Fishery-dependent population length-at-age."))
  add_input(type = "weight", measure = "weight_at_age", basis = "weight_per_fish",
    value = T1$v6[i], unit = "lb whole weight per fish", age = age, fleet = "Fishery-dependent population",
    source_reference = table_ref(1, 36), notes = paste(age_note, "Fishery-dependent population mean weight-at-age."))
  add_input(type = "maturity", measure = "maturity_at_age", basis = "proportion",
    value = T1$v7[i], unit = "proportion mature", age = age, sex = "female",
    source_reference = table_ref(1, 36), notes = paste(age_note, "Female maturity-at-age."))
  add_input(type = "M", measure = "natural_mortality_at_age", basis = "per_year",
    value = T1$v8[i], unit = "per year", age = age,
    source_reference = table_ref(1, 36), notes = paste(age_note, "Fixed Lorenzen natural mortality schedule."))
}


output_rows <- list()
add_output <- function(...) output_rows[[length(output_rows) + 1L]] <<- output_row(...)

# Outputs: annual population, biomass, mortality, selectivity, and catch estimates
add_age_output_table <- function(dat, type, measure, unit, table, page, notes = age_note) {
  for (i in seq_len(nrow(dat))) {
    year <- dat$year[i]
    scenario <- if (year == 2021L) "Interim 2021" else ""
    for (age in 0:10) {
      value <- dat[[paste0("v", age + 1L)]][i]
      if (is.finite(value)) {
        add_output(type = type, measure = measure, value = value, unit = unit,
          year = year, age = age, scenario = scenario, source_reference = table_ref(table, page),
          notes = paste(notes, if (scenario != "") "Outside fitted assessment period; source labels these as interim 2021 estimates." else ""))
      }
    }
  }
}
add_age_output_table(T9, "population", "numbers_at_age", "1000 fish", 9, 42)
add_age_output_table(T10, "biomass", "biomass_at_age", "1000 lb whole weight", 10, 43)

for (i in seq_len(nrow(T9))) {
  scenario <- if (T9$year[i] == 2021L) "Interim 2021" else ""
  add_output(type = "population", measure = "total_numbers", value = T9$v12[i],
    unit = "1000 fish", year = T9$year[i], scenario = scenario,
    source_reference = table_ref(9, 42),
    notes = paste("Source-reported total abundance at start of year.", age_note))
  add_output(type = "biomass", measure = "total_biomass_from_age_surface", value = T10$v12[i],
    unit = "1000 lb whole weight", year = T10$year[i], scenario = scenario,
    source_reference = table_ref(10, 43),
    notes = "Source-reported total of the age-specific biomass surface at start of year; native table units retained.")
}

table11_specs <- list(
  list(col = "v1", type = "mortality", measure = "apical_F", unit = "per year", note = "Full F, including discard mortalities."),
  list(col = "v2", type = "mortality", measure = "F_ratio_to_Fmsy", unit = "ratio", note = "Full F divided by FMSY."),
  list(col = "v3", type = "biomass", measure = "total_biomass", unit = "metric tons", note = "Total biomass at start of year."),
  list(col = "v4", type = "biomass", measure = "total_biomass_ratio_to_unfished", unit = "ratio", note = "Total biomass relative to unfished biomass."),
  list(col = "v5", type = "biomass", measure = "SSB", unit = "metric tons", note = "Total mature female biomass; Table 11 labels timing as end of July."),
  list(col = "v6", type = "biomass", measure = "SSB_ratio_to_SSBMSY", unit = "ratio", note = "Spawning biomass divided by SSBMSY."),
  list(col = "v7", type = "biomass", measure = "SSB_ratio_to_MSST", unit = "ratio", note = "Spawning biomass divided by MSST."),
  list(col = "v8", type = "population", measure = "current_spawning_potential_ratio", unit = "ratio", note = "Static spawning potential ratio.")
)
for (i in seq_len(nrow(T11))) {
  for (spec in table11_specs) {
    value <- T11[[spec$col]][i]
    if (is.finite(value)) {
      year <- T11$year[i]
      scenario <- if (year == 2021L) "Interim 2021" else ""
      add_output(type = spec$type, measure = spec$measure, value = value,
        unit = spec$unit, year = year, scenario = scenario, source_reference = table_ref(11, 44),
        notes = paste(spec$note, if (scenario != "") "Outside fitted assessment period; source reports this as interim." else ""))
    }
  }
}

selectivity_fleets <- c("Commercial handline", "Commercial pound net", "Commercial gillnet",
  "Commercial cast net", "General recreational", "General recreational discards",
  "Shrimp-bycatch discards", "Average landings", "Average discards", "Average catches")
for (i in seq_len(nrow(T12))) {
  age <- T12$age[i]
  add_output(type = "biology", measure = "growth_length_at_age", value = T12$v1[i],
    unit = "mm fork length", age = age, source_reference = table_ref(12, 45),
    notes = paste(age_note, "Length-at-age printed alongside the end-of-assessment selectivity summary."))
  for (j in seq_along(selectivity_fleets)) {
    add_output(type = "biology", measure = "fleet_selectivity_at_age", value = T12[[paste0("v", j + 1L)]][i],
      unit = "relative selectivity", fleet = selectivity_fleets[j], age = age,
      source_reference = table_ref(12, 45),
      notes = paste(age_note, "End-of-assessment relative selectivity; the last three series are across-fleet averages."))
  }
}

table13_fleets <- c("Commercial handline", "Commercial pound net", "Commercial gillnet",
  "Commercial cast net", "General recreational", "General recreational discards", "Shrimp-bycatch discards")
for (i in seq_len(nrow(T13))) {
  for (j in seq_along(table13_fleets)) {
    add_output(type = "mortality", measure = "fishing_mortality_summary", value = T13[[paste0("v", j)]][i],
      unit = "per year", fleet = table13_fleets[j], year = T13$year[i],
      source_reference = table_ref(13, 46),
      notes = "Fully selected fishing-mortality summary for this fleet, including source discard treatment.")
  }
}
add_age_output_table(T14, "mortality", "fishing_mortality_at_age", "per year", 14, 47)
add_age_output_table(T15, "mortality", "total_mortality_at_age", "per year", 15, 48)
add_age_output_table(T16, "catch", "landings_numbers_at_age", "1000 fish", 16, 49,
  notes = "Model-estimated total landings-at-age across fleets; not observed catch-at-age. Age 10 is the 10+ plus group.")
add_age_output_table(T17, "catch", "landings_weight_at_age", "1000 lb whole weight", 17, 50,
  notes = "Model-estimated total landings weight-at-age across fleets. Age 10 is the 10+ plus group.")
add_age_output_table(T20, "catch", "discard_numbers_at_age", "1000 fish", 20, 53,
  notes = "Model-estimated total dead discards-at-age across discard sources; not observed catch-at-age. Age 10 is the 10+ plus group.")
add_age_output_table(T21, "catch", "discard_weight_at_age", "1000 lb whole weight", 21, 54,
  notes = "Model-estimated total dead discard weight-at-age across discard sources. Age 10 is the 10+ plus group.")

fleet_cols <- c("Commercial handline", "Commercial pound net", "Commercial gillnet",
  "Commercial cast net", "General recreational", "General recreational discards",
  "Shrimp-bycatch discards", "TOTAL_LANDINGS", "TOTAL_DISCARDS")
for (table_info in list(list(data = T18, table = 18, page = 51, unit = "1000 fish"),
                        list(data = T19, table = 19, page = 52, unit = "1000 lb whole weight"))) {
  dat <- table_info$data
  for (i in seq_len(nrow(dat))) {
    for (j in seq_along(fleet_cols)) {
      value <- dat[[paste0("v", j)]][i]
      if (!is.finite(value)) next
      landings <- j <= 5L || j == 8L
      total <- j >= 8L
      fleet <- if (total) "" else fleet_cols[j]
      measure <- if (landings) {
        if (grepl("fish$", table_info$unit)) "landings_numbers" else "landings_biomass"
      } else {
        if (grepl("fish$", table_info$unit)) "discard_numbers" else "discard_biomass"
      }
      add_output(type = "catch", measure = measure, value = value, unit = table_info$unit,
        fleet = fleet, year = dat$year[i], source_reference = table_ref(table_info$table, table_info$page),
        notes = if (total) "Source-reported total across fleets; retained as a summary, not an independent fleet observation." else "Model-estimated annual fleet removal output.")
    }
  }
}

table22 <- data.frame(
  measure = c("Fmsy", "F75_percent_Fmsy", "F30_percent", "F40_percent", "Bmsy", "SSBMSY",
    "MSST", "msy", "RMSY", "landings_at_85_percent_Fmsy", "landings_at_75_percent_Fmsy",
    "landings_at_65_percent_Fmsy", "mean_fishing_mortality", "F_ratio_to_Fmsy",
    "SSB_ratio_to_MSST", "SSB_ratio_to_SSBMSY"),
  type = c("mortality", "mortality", "mortality", "mortality", "biomass", "biomass",
    "biomass", "catch", "recruitment", "catch", "catch", "catch", "mortality",
    "mortality", "biomass", "biomass"),
  value_unit = c("per year", "per year", "per year", "per year", "metric tons", "metric tons",
    "metric tons", "1000 lb whole weight", "1000 recruits", "1000 lb whole weight",
    "1000 lb whole weight", "1000 lb whole weight", "per year", "ratio", "ratio", "ratio"),
  estimate = c(.516, .387, .608, .410, 19588, 6406, 4804, 8210, 22792, 8149, 8024, 7807, .40, .77, 1.40, 1.05),
  median = c(.523, .392, .615, .414, 19821, 6410, 4808, 8351, 23392, 8287, 8158, 7932, .39, .74, 1.42, 1.07),
  se = c(.111, .083, .059, .038, 2232, 1122, 842, 411, 3015, 410, 408, 407, .05, .21, .34, .25),
  stringsAsFactors = FALSE
)
table22_notes <- c(
  "Base-run FMSY benchmark.", "75 percent of FMSY.", "F at 30 percent spawning-potential ratio.",
  "F at 40 percent spawning-potential ratio.", "Total biomass at MSY.", "Spawning stock biomass at MSY.",
  "Minimum stock size threshold, defined as 75 percent of SSBMSY.",
  "Maximum sustainable yield in 1000 lb whole weight.",
  "Recruitment at MSY; the source labels units as thousands.",
  "Yield at 85 percent FMSY.", "Yield at 75 percent FMSY.", "Yield at 65 percent FMSY.",
  "Mean F over 2018-2020.", "Mean F/FMSY over 2018-2020.",
  "SSB2020 divided by MSST.", "SSB2020 divided by SSBMSY."
)
for (i in seq_len(nrow(table22))) {
  scenario_base <- if (i >= 13L) "2018-2020 summary: base-run estimate" else "Base-run estimate"
  scenario_median <- if (i >= 13L) "2018-2020 summary: MCBE median" else "MCBE median"
  add_output(type = table22$type[i], measure = table22$measure[i], value = table22$estimate[i],
    unit = table22$value_unit[i], scenario = scenario_base, source_reference = table_ref(22, 55),
    notes = paste(table22_notes[i], "Source Table 22 Estimate column; no SE reported for this column."))
  add_output(type = table22$type[i], measure = table22$measure[i], value = table22$median[i],
    unit = table22$value_unit[i], scenario = scenario_median, se = table22$se[i],
    source_reference = table_ref(22, 55),
    notes = paste(table22_notes[i], "Source Table 22 Median and SE from the Monte Carlo/bootstrap ensemble (MCBE)."))
}

# Candidate and canonical-record checks
candidates <- read_csv(candidate_path)
candidate_index <- which(candidates$candidate_id == candidate_id)
if (length(candidate_index) != 1L) stop("Expected one NOAA:10174 candidate record.", call. = FALSE)
candidate <- candidates[candidate_index, , drop = FALSE]
if (candidate$scientific_name != "Scomberomorus maculatus" ||
    candidate$stock_name != "Spanish mackerel - Southern Atlantic Coast" ||
    candidate$assessment_area != "Southern Atlantic Coast" ||
    candidate$eligibility != "eligible" ||
    !candidate$screening_status %in% "screened" ||
    !candidate$import_status %in% c("not_started", "partial")) {
  stop("Candidate details no longer match the reviewed NOAA stock unit.", call. = FALSE)
}
stocks <- read_csv("database/stocks.csv")
assessments <- read_csv("database/assessments.csv")
ensure_append("database/stocks.csv", stock_row, "stock_id")
ensure_append("database/assessments.csv", assessment_row, "assessment_id")
authority_matches <- which(!is.na(stocks$authority_stock_id) &
  stocks$authority_stock_id == "Spanish mackerel - Southern Atlantic Coast (NOAA Stock SMART 10174)")
if (any(stocks$stock_id[authority_matches] != stock_id)) {
  stop("The NOAA Stock SMART identifier is already assigned to another stock.", call. = FALSE)
}

assumption_rows <- make_rows(assumption_fields, assumptions)
input_rows <- make_rows(input_fields, input_rows)
output_rows <- make_rows(output_fields, output_rows)
existing_assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
existing_inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
existing_outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumption_key <- c("assessment_id", "component", "fleet", "survey", "sex", "region", "season", "setting")
input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex", "region",
  "season", "year", "year_basis", "age", "observation_id", "length_bin", "length_bin_lower",
  "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season",
  "year", "age", "age_group", "scenario")
assumptions_to_add <- rows_to_add(existing_assumptions, assumption_rows, assumption_key, "assumption")
inputs_to_add <- rows_to_add(existing_inputs, input_rows, input_key, "input")
outputs_to_add <- rows_to_add(existing_outputs, output_rows, output_key, "output")

candidate_update <- candidate
candidate_update$matched_stock_id <- stock_id
candidate_update$match_status <- "matched"
candidate_update$import_status <- "partial"
candidate_update$catch_age_evidence <- "Canonical records now include aggregate catches/removals and observed age-composition inputs. Tables 16-21 are separately stored as model-estimated catch outputs, not observed catch-at-age."
candidate_update$survey_age_evidence <- "Imported Florida commercial handline and MRIP aggregate indices with source CVs, and the SEAMAP-SA age-0 recruitment index with CVs through 2019. No full age-specific abundance-index surface is reported."
candidate_update$weights_evidence <- "Imported Table 1 population, female, and fishery-dependent length- and weight-at-age for ages 0-10."
candidate_update$maturity_evidence <- "Imported Table 1 female maturity-at-age for ages 0-10; equal sex ratio is recorded as an assumption."
candidate_update$mortality_evidence <- "Imported the fixed age-specific Lorenzen M schedule for ages 0-10; its time constancy and scaling are recorded as assumptions."
candidate_update$timing_evidence <- "Fishery-dependent index timing is represented as midyear (0.5); SEAMAP samples spring, summer, and fall, so a single fraction is unavailable. Table 11 SSB timing conflicts with the peak-spawning description."
candidate_update$output_evidence <- "Imported annual N and biomass-at-age (1986-2021, with 2021 labeled interim), SSB and other status indicators, F and Z at age, selectivities, landings and dead-discard outputs, and Table 22 benchmarks with MCBE standard errors where reported."
candidate_update$decision_reason <- "Partially imported the latest detailed production assessment. The report tables provide extensive numerical inputs and outputs, but native fitted model files and annual age-surface uncertainty were not located; unresolved SSB and survey timing details remain documented."
candidate_update$notes <- "Partial numerical records were imported from the revised SEDAR 78 report tables. Age-specific landings/discard values are model estimates and remain distinct from observed catch/removal and composition likelihood inputs."

cat("NOAA South Atlantic Spanish mackerel (SEDAR 78) source import dry run\n")
cat("  stock: ", stock_id, "\n", sep = "")
cat("  assessment: ", assessment_id, " (1986-2020 fitted; selected 2021 values labeled interim)\n", sep = "")
cat("  assumptions: ", nrow(assumptions_to_add), " new of ", nrow(assumption_rows), "\n", sep = "")
cat("  inputs: ", nrow(inputs_to_add), " new of ", nrow(input_rows), "\n", sep = "")
cat("  outputs: ", nrow(outputs_to_add), " new of ", nrow(output_rows), "\n", sep = "")
cat("  inputs cover Tables 1-8; outputs cover Tables 9-22.\n")
if (!write_mode) {
  cat("Dry run only. Add --write to append the verified source records.\n")
} else {
  source(file.path(root, "scripts/database/candidate_register_io.R"), local = TRUE)
  ensure_append("database/stocks.csv", stock_row, "stock_id", append_missing = TRUE)
  ensure_append("database/assessments.csv", assessment_row, "assessment_id", append_missing = TRUE)
  append_csv("database/assumptions.csv", assumptions_to_add)
  append_csv("database/inputs.csv", inputs_to_add)
  append_csv("database/outputs.csv", outputs_to_add)
  replace_candidate_register_row(candidate_path, candidate_index, candidate_update, candidate_id)
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts/database/196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Appended the partial source record and updated discovery crosswalk summaries.\n")
}
