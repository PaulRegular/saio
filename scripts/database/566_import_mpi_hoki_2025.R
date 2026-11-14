root <- "."
assessment_id <- "mpi_hoki_hok1_2025"
stock_id <- "mpi_hoki_hok1"
candidate_id <- "MPI:HOK1"
args <- commandArgs(trailingOnly = TRUE)
write_assumptions_only <- "--write-assumptions" %in% args
write_biological_assumptions_only <- "--write-biological-assumptions" %in% args
dry_run <- !("--write" %in% args || write_assumptions_only || write_biological_assumptions_only)
.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))

assessment_pdf <- file.path(root, "source_cache", "mpi_hoki_hok1_2025", "FAR-2026-04-Assessment-of-hoki-in-2025.pdf")
input_pdf <- file.path(root, "source_cache", "mpi_hoki_hok1_2025", "FAR-2025-42-Hoki-input-data.pdf")
manifest <- read.csv(file.path(root, "provenance", "mpi_hoki_hok1_2025_sources.csv"), stringsAsFactors = FALSE)
if (!requireNamespace("pdftools", quietly = TRUE) || !all(file.exists(c(assessment_pdf, input_pdf)))) {
  stop("Install pdftools and cache both verified Hoki reports before importing.", call. = FALSE)
}
expected_hash <- c("938A110A43BF1F509D15CF6680756EF22F28FA6E351CC6BD9AB58D63545A2714", "3C91D1898394B35D7089B51B0C550D9C6EA20D50F4BBF55EF8EA4AADEE000938")
actual_hash <- unname(toupper(tools::sha256sum(c(assessment_pdf, input_pdf))))
if (!identical(actual_hash, expected_hash) || !identical(toupper(manifest$sha256), expected_hash)) {
  stop("Cached Hoki source checksums do not match the reviewed source manifest.", call. = FALSE)
}

assessment_pages <- pdftools::pdf_text(assessment_pdf)
assessment_data <- pdftools::pdf_data(assessment_pdf)
last_page <- function(text, marker) {
  hits <- grep(marker, text, fixed = TRUE)
  if (!length(hits)) stop("Could not find source section: ", marker, call. = FALSE)
  tail(hits, 1L)
}
section_lines <- function(page_ids) {
  out <- character()
  for (page in page_ids) {
    d <- assessment_data[[page]]
    d <- d[d$y > 125 & d$y < 700, , drop = FALSE]
    for (y in sort(unique(d$y))) {
      row <- d[d$y == y, , drop = FALSE]
      row <- row[order(row$x), , drop = FALSE]
      line_number <- which(row$x < 115 & grepl("^[0-9]+$", row$text))
      if (length(line_number)) {
        out <- c(out, paste(row$text[-line_number[1L]], collapse = " "))
      } else if (nrow(row) && length(out)) {
        out[length(out)] <- paste(out[length(out)], paste(row$text, collapse = " "))
      }
    }
  }
  trimws(out)
}
fish_page <- last_page(assessment_pages, "B.1.4")
survey_page <- last_page(assessment_pages, "B.1.5")
population_page <- last_page(assessment_pages, "B.1.6")
end_page <- grep("B\\.2\\s+Single stock model", assessment_pages)
if (length(end_page) != 1L) stop("Could not identify the end of the base two-stock model appendix.", call. = FALSE)
fishery_lines <- section_lines(seq.int(fish_page + 1L, survey_page - 1L))
survey_lines <- section_lines(seq.int(survey_page + 1L, population_page - 1L))
population_lines <- section_lines(seq.int(population_page + 1L, end_page - 1L))

field_value <- function(lines, field) {
  hit <- grep(paste0("^", field, "\\s+"), lines)
  if (!length(hit)) return(NA_character_)
  sub(paste0("^", field, "\\s+"), "", lines[hit[1L]])
}
table_rows <- function(lines, name) {
  hit <- which(lines == paste("table", name))
  if (!length(hit)) stop("Missing table: ", name, call. = FALSE)
  end <- which(seq_along(lines) > hit[1L] & lines == "end_table")[1L]
  if (is.na(end)) stop("Unterminated table: ", name, call. = FALSE)
  raw <- lines[seq.int(hit[1L] + 1L, end - 1L)]
  raw <- raw[grepl("^[0-9]{4}\\s+", raw)]
  lapply(raw, function(line) {
    values <- suppressWarnings(as.numeric(strsplit(trimws(line), "\\s+")[[1L]]))
    if (anyNA(values) || any(!is.finite(values))) stop("Unreadable numeric row in table ", name, ".", call. = FALSE)
    values
  })
}

series <- list(
  FisheryChathamRiseShallowAge = c(kind = "fleet", label = "Chatham Rise shallow trawl", region = "Chatham Rise"),
  FisheryChathamRiseDeepAge = c(kind = "fleet", label = "Chatham Rise deep trawl", region = "Chatham Rise"),
  FisheryCookStraitAge = c(kind = "fleet", label = "Cook Strait fishery", region = "Cook Strait"),
  FisheryECSISpawningAge = c(kind = "fleet", label = "East coast South Island spawning fishery", region = "East coast South Island"),
  FisherySubAntarcticAucklandAge = c(kind = "fleet", label = "Sub-Antarctic Auckland Islands fishery", region = "Sub-Antarctic"),
  FisherySubAntarcticSnaresAge = c(kind = "fleet", label = "Sub-Antarctic Snares Islands fishery", region = "Sub-Antarctic"),
  FisherySubAntarcticSubaAge = c(kind = "fleet", label = "Sub-Antarctic Sub-Antarctic fishery", region = "Sub-Antarctic"),
  FisheryWCSIInsideAge = c(kind = "fleet", label = "West coast South Island inside fishery", region = "West coast South Island"),
  FisheryWCSINorthAge = c(kind = "fleet", label = "West coast South Island north fishery", region = "West coast South Island"),
  FisheryWCSISouthAge = c(kind = "fleet", label = "West coast South Island south fishery", region = "West coast South Island"),
  SubAntarcticAEXAge = c(kind = "survey", label = "Sub-Antarctic AEX trawl survey", region = "Sub-Antarctic"),
  SubAntarcticSHIAge = c(kind = "survey", label = "Sub-Antarctic SHI trawl survey", region = "Sub-Antarctic"),
  ChathamRiseSHIAge = c(kind = "survey", label = "Chatham Rise SHI trawl survey", region = "Chatham Rise"),
  ChathamRiseSummerAge = c(kind = "survey", label = "Chatham Rise summer trawl survey", region = "Chatham Rise"),
  SubAntarcticSummerAge = c(kind = "survey", label = "Sub-Antarctic summer trawl survey", region = "Sub-Antarctic"),
  SubAntarcticAutumnAge = c(kind = "survey", label = "Sub-Antarctic autumn trawl survey", region = "Sub-Antarctic"),
  CookStraitAcousticBiomass = c(kind = "survey", label = "Cook Strait acoustic spawning survey", region = "Cook Strait"),
  ECSIAcousticBiomass = c(kind = "survey", label = "East coast South Island acoustic spawning survey", region = "East coast South Island"),
  WCSIAcousticBiomass = c(kind = "survey", label = "West coast South Island acoustic spawning survey", region = "West coast South Island"),
  ChathamRiseSummerBiomass = c(kind = "survey", label = "Chatham Rise summer trawl survey", region = "Chatham Rise"),
  SubAntarcticSummerBiomass = c(kind = "survey", label = "Sub-Antarctic summer trawl survey", region = "Sub-Antarctic"),
  SubAntarcticAutumnBiomass = c(kind = "survey", label = "Sub-Antarctic autumn trawl survey", region = "Sub-Antarctic")
)
observation_blocks <- function(lines) {
  starts <- grep("^@observation\\s+", lines)
  names <- sub("^@observation\\s+", "", lines[starts])
  blocks <- lapply(seq_along(starts), function(i) {
    last <- if (i < length(starts)) starts[i + 1L] - 1L else length(lines)
    lines[seq.int(starts[i], last)]
  })
  names(blocks) <- names
  blocks
}
model_blocks <- function(lines, directive) {
  starts <- grep(paste0("^@", directive, "(?:\\s+.*)?$"), lines, perl = TRUE)
  names <- sub(paste0("^@", directive, "\\s*"), "", lines[starts])
  boundaries <- grep("^@", lines)
  blocks <- lapply(seq_along(starts), function(i) {
    next_boundary <- boundaries[boundaries > starts[i]][1L]
    last <- if (is.na(next_boundary)) length(lines) else next_boundary - 1L
    lines[seq.int(starts[i], last)]
  })
  names(blocks) <- names
  blocks
}
fish_blocks <- observation_blocks(fishery_lines)
survey_blocks <- observation_blocks(survey_lines)
blocks <- c(fish_blocks, survey_blocks)
if (!identical(sort(names(blocks)), sort(names(series)))) stop("The Hoki source observation blocks changed; review before importing.", call. = FALSE)

step_names <- c("OctNov", "DecMar", "AprJun", "EndJun", "JulSep")
step_lengths <- c(.17, .33, .25, 0, .25)
step_start <- c(0, cumsum(step_lengths)[-length(step_lengths)])
step_time <- function(step, within = NA_real_) {
  index <- match(step, step_names)
  if (is.na(index)) stop("Unknown Casal2 time step: ", step, call. = FALSE)
  fraction <- if (is.na(within)) .5 else as.numeric(within)
  step_start[index] + step_lengths[index] * fraction
}

input_fields <- names(read.csv(file.path(root, "database", "inputs.csv"), nrows = 0L, check.names = FALSE))
assumption_fields <- names(read.csv(file.path(root, "database", "assumptions.csv"), nrows = 0L, check.names = FALSE))
output_fields <- names(read.csv(file.path(root, "database", "outputs.csv"), nrows = 0L, check.names = FALSE))
make_rows <- function(fields, values, n = 1L) {
  result <- lapply(fields, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(result) <- fields
  as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
}
input_rows <- list()
assumption_rows <- list()
model_assumption_rows <- list()
output_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_real_, age = NA_real_,
  fleet = "", survey = "", sex = "", region = "HOK 1", season = "",
  sampling_time = NA_real_, source_reference, notes = "", observation_id = "",
  sample_size = NA_real_, source_type = "native_model") {
  input_rows[[length(input_rows) + 1L]] <<- make_rows(input_fields, list(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = year, year_basis = if (all(is.na(year))) "" else "model_year",
    age = age, value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    notes = notes, observation_id = observation_id, sample_size = sample_size
  ), length(value))
}
add_assumption <- function(component, setting, value, source_reference,
  notes = "", fleet = "", survey = "", region = "HOK 1", sex = "", season = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(assumption_fields, list(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference, notes = notes
  ))
}
add_model_assumption <- function(component, setting, value, source_reference,
  notes = "", region = "", sex = "", season = "") {
  row <- make_rows(assumption_fields, list(
    assessment_id = assessment_id, component = component, region = region,
    sex = sex, season = season, setting = setting, value = value,
    source_reference = source_reference, notes = notes
  ))
  assumption_rows[[length(assumption_rows) + 1L]] <<- row
  model_assumption_rows[[length(model_assumption_rows) + 1L]] <<- row
}
add_output <- function(measure, value, year = NA_real_, region = "HOK 1",
  season = "", lwr = NA_real_, upr = NA_real_, notes = "") {
  output_rows[[length(output_rows) + 1L]] <<- make_rows(output_fields, list(
    assessment_id = assessment_id, type = "biomass", measure = measure,
    region = region, season = season, year = year, value = value,
    lwr = lwr, upr = upr, unit = "1000 tonnes", source_type = "official_table",
    source_reference = "Fisheries New Zealand FAR 2026/04, Table 10, p. 23",
    notes = notes
  ), length(value))
}

fishery_names <- names(series)[vapply(series, `[[`, character(1), "kind") == "fleet"]
catch_rows <- table_rows(population_lines, "catches")
catch_start <- which(population_lines == "table catches")[1L]
first_catch <- which(grepl("^1972\\s+", population_lines))[1L]
catch_header <- strsplit(paste(population_lines[seq.int(catch_start + 1L, first_catch - 1L)], collapse = " "), "\\s+")[[1L]]
catch_fishery_names <- paste0(catch_header[-1L], "Age")
catch_fishery_names[catch_fishery_names == "FisheryCookStraitSpawningAge"] <- "FisheryCookStraitAge"
if (!setequal(catch_fishery_names, fishery_names) || length(catch_rows) != 54L ||
  any(lengths(catch_rows) != length(fishery_names) + 1L) ||
  !identical(vapply(catch_rows, `[[`, numeric(1), 1L), as.numeric(1972:2025))) {
  stop("Hoki population catch table dimensions, columns, or years changed.", call. = FALSE)
}
for (j in seq_along(catch_fishery_names)) {
  meta <- series[[catch_fishery_names[j]]]
  for (i in seq_along(catch_rows)) add_input(
    "catch", "total_biomass", "biomass", catch_rows[[i]][j + 1L], "tonnes",
    year = catch_rows[[i]][1L], fleet = meta[["label"]], region = meta[["region"]],
    source_reference = "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model population input, table catches",
    notes = "Casal2 assumed catch biomass; model year runs October to September and is labelled by ending year. 2025 catch repeats 2024 as the assessment projection assumption."
  )
}


for (name in names(blocks)) {
  block <- blocks[[name]]
  meta <- series[[name]]
  dimension <- meta[["kind"]]
  region <- meta[["region"]]
  fleet <- if (dimension == "fleet") meta[["label"]] else ""
  survey <- if (dimension == "survey") meta[["label"]] else ""
  source_section <- if (name %in% names(fish_blocks)) "B.1.4" else "B.1.5"
  source_ref <- paste0("Fisheries New Zealand FAR 2026/04, Appendix ", source_section,
    ", base model input, ", name)
  time_step <- field_value(block, "time_step")
  time_prop <- suppressWarnings(as.numeric(field_value(block, "time_step_proportion")))
  sampling_time <- step_time(time_step, time_prop)
  setting_names <- c("type", "time_step", "time_step_proportion", "min_age", "max_age",
    "plus_group", "ageing_error", "likelihood", "process_errors", "process_error",
    "error_value_multiplier", "likelihood_multiplier", "catchability", "selectivities", "categories")
  for (setting in setting_names) {
    value <- field_value(block, setting)
    if (!is.na(value)) add_assumption(
      if (dimension == "fleet") "catch" else "index", paste(name, setting, sep = ":"), value,
      source_ref, fleet = fleet, survey = survey, region = region,
      season = if (setting == "time_step") time_step else ""
    )
  }
  rows <- table_rows(block, "obs")
  obs_years <- vapply(rows, `[[`, numeric(1), 1L)
  declared_years <- as.numeric(strsplit(field_value(block, "years"), "\\s+")[[1L]])
  if (anyDuplicated(obs_years) || !setequal(obs_years, declared_years)) stop("Observation year listing mismatch for ", name, call. = FALSE)
  rows <- rows[match(declared_years, obs_years)]
  obs_years <- declared_years
  if (grepl("Age$", name)) {
    min_age <- as.integer(field_value(block, "min_age"))
    max_age <- as.integer(field_value(block, "max_age"))
    ages <- seq.int(min_age, max_age)
    if (any(lengths(rows) != 1L + 2L * length(ages))) stop("Unexpected sex-age composition dimensions for ", name, ".", call. = FALSE)
    errors <- table_rows(block, "error_values")
    error_years <- vapply(errors, `[[`, numeric(1), 1L)
    if (anyDuplicated(error_years) || !setequal(error_years, obs_years)) stop("Composition sample-size years do not match observations for ", name, ".", call. = FALSE)
    errors <- errors[match(obs_years, error_years)]
    raw_sizes <- vapply(errors, `[[`, numeric(1), 2L)
    categories <- field_value(block, "categories")
    sex_order <- c("M", "F")
    first_sex <- regmatches(categories, regexpr("\\.[MF]", categories))
    if (identical(first_sex, ".F")) sex_order <- rev(sex_order)
    composition_note <- paste(
      "Native multinomial proportions across both sexes and ages; source vector is ordered by sex blocks, then ascending age.",
      "Values sum to one over sex and age; max age is the source plus group where plus_group is TRUE. These are not catch numbers-at-age.",
      "sample_size is the raw Casal2 error_values entry; error_value_multiplier is stored separately as an assumption."
    )
    for (i in seq_along(rows)) {
      proportions <- rows[[i]][-1L]
      if (abs(sum(proportions) - 1) > 1e-4 || any(proportions < 0 | proportions > 1)) stop("Invalid source proportions for ", name, " in ", obs_years[i], ".", call. = FALSE)
      for (s in seq_along(sex_order)) for (a in seq_along(ages)) add_input(
        "index", "proportion_at_age", "proportion_numbers", proportions[(s - 1L) * length(ages) + a], "proportion",
        year = obs_years[i], age = ages[a], fleet = fleet, survey = survey,
        sex = sex_order[s], region = region, season = time_step,
        sampling_time = sampling_time, source_reference = source_ref,
        notes = composition_note,
        observation_id = paste0("hoki_", name, "_", obs_years[i]), sample_size = raw_sizes[i]
      )
    }
  } else {
    if (any(lengths(rows) != 3L)) stop("Unexpected biomass index dimensions for ", name, ".", call. = FALSE)
    for (row in rows) {
      add_input("index", "total_biomass", "biomass", row[2L], "tonnes",
        year = row[1L], survey = survey, region = region, season = time_step,
        sampling_time = sampling_time, source_reference = source_ref,
        notes = "Casal2 aggregate biomass index; the third source table column is its CV.")
      add_input("index", "biomass_index_cv", "relative_scale", row[3L], "ratio",
        year = row[1L], survey = survey, region = region, season = time_step,
        sampling_time = sampling_time, source_reference = source_ref,
        notes = "Source CV paired with the aggregate biomass index; Casal2 likelihood is lognormal.")
    }
  }
}

mortality_start <- grep("^@process Mortality$", population_lines)[1L]
mortality_end <- which(seq_along(population_lines) > mortality_start & grepl("^@process ", population_lines))[1L]
if (is.na(mortality_end)) mortality_end <- length(population_lines) + 1L
mortality_lines <- population_lines[seq.int(mortality_start, mortality_end - 1L)]
fixed_m <- field_value(mortality_lines, "m")
add_assumption("mortality", "fixed_instantaneous_M_by_category", fixed_m,
  "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model mortality process",
  notes = "Native fixed M vector retained in Casal2 category order. The category order is recorded separately; this is not an age-specific M-at-age surface.")
add_assumption("mortality", "relative_M_by_age", field_value(mortality_lines, "relative_m_by_age"),
  "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model mortality process",
  notes = "Native age-selectivity references for fixed natural mortality.")
add_assumption("population", "time_steps", paste(step_names, collapse = ", "),
  "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model population process",
  notes = "Annual model year runs October through September; labels use ending year.")
add_assumption("population", "time_step_proportions", paste(step_lengths, collapse = ", "),
  "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model mortality process",
  notes = "Native proportions for the four intervals; EndJun is an instantaneous state between intervals.")

category_block <- model_blocks(population_lines, "categories")[[1L]]
category_names <- strsplit(field_value(category_block, "names"), "\\s+")[[1L]]
category_age_lengths <- strsplit(field_value(category_block, "age_lengths"), "\\s+")[[1L]]
if (length(category_names) != 16L || length(category_age_lengths) != length(category_names) ||
  length(strsplit(fixed_m, "\\s+")[[1L]]) != length(category_names)) {
  stop("The base-model category, age-length mapping, or M-vector dimensions changed.", call. = FALSE)
}
category_map <- paste(sprintf("%02d:%s=%s", seq_along(category_names), category_names,
  category_age_lengths), collapse = "; ")
add_model_assumption("population", "base_model_category_order", paste(category_names, collapse = " "),
  "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model categories",
  notes = "Native category order used by the fixed natural-mortality vector.")
add_model_assumption("population", "category_age_length_mapping", category_map,
  "Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model categories",
  notes = "Ordered category-to-age-length object mapping from the model input.")

for (name in c("EastMaturation", "WestMaturation")) {
  block <- model_blocks(population_lines, "process")[[name]]
  if (is.null(block)) stop("Missing base-model maturation process: ", name, call. = FALSE)
  region <- sub("Maturation$", "", name)
  for (setting in c("type", "from", "to", "selectivities", "proportions")) {
    value <- field_value(block, setting)
    if (is.na(value)) stop("Missing ", setting, " in ", name, ".", call. = FALSE)
    add_model_assumption("maturity", paste(name, setting, sep = ":"), value,
      paste0("Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model process ", name),
      notes = "Native Casal2 transition-category process; it describes seasonal maturation transitions, not a static maturity-at-age vector.",
      region = region, season = "AprJun")
  }
}

for (name in names(model_blocks(population_lines, "selectivity"))) {
  if (!grepl("^Selectivity(East|West)Maturation(M|F)$", name)) next
  block <- model_blocks(population_lines, "selectivity")[[name]]
  region <- sub("Maturation[MF]$", "", sub("^Selectivity", "", name))
  sex <- sub("^Selectivity(East|West)Maturation", "", name)
  for (setting in c("type", "a50", "ato95", "alpha")) {
    value <- field_value(block, setting)
    if (is.na(value)) stop("Missing ", setting, " in maturation selectivity ", name, ".", call. = FALSE)
    add_model_assumption("maturity", paste(name, setting, sep = ":"), value,
      paste0("Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model selectivity ", name),
      notes = "Native Casal2 age-based selectivity controlling the seasonal category transition; not an exported maturity-at-age surface.",
      region = region, sex = sex, season = "AprJun")
  }
}

for (name in names(model_blocks(population_lines, "age_length"))) {
  block <- model_blocks(population_lines, "age_length")[[name]]
  region <- sub("M$|F$", "", sub("^AgeLength", "", name))
  sex <- sub("^AgeLength(East|West)", "", name)
  for (setting in c("type", "length_weight", "k", "t0", "Linf", "cv_first", "cv_last",
    "time_step_proportions", "by_length", "distribution", "compatibility_option")) {
    value <- field_value(block, setting)
    if (is.na(value)) next
    add_model_assumption("growth", paste(name, setting, sep = ":"), value,
      paste0("Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model age-length object ", name),
      notes = "Native Casal2 age-length function parameter; length is in centimetres and the object is sex- and stock-specific.",
      region = region, sex = sex)
  }
}

for (name in names(model_blocks(population_lines, "length_weight"))) {
  block <- model_blocks(population_lines, "length_weight")[[name]]
  region <- sub("[MF]$", "", sub("^LengthWeight", "", name))
  sex <- sub("^LengthWeight(East|West)", "", name)
  for (setting in c("type", "units", "a", "b")) {
    value <- field_value(block, setting)
    if (is.na(value)) next
    add_model_assumption("growth", paste(name, setting, sep = ":"), value,
      paste0("Fisheries New Zealand FAR 2026/04, Appendix B.1.6, base model length-weight object ", name),
      notes = "Native length-weight function parameter; no direct weight-at-age vector is inferred.",
      region = region, sex = sex)
  }
}

if (length(model_assumption_rows) != 88L) {
  stop("Expected 88 base-model biological and category assumptions, found ",
    length(model_assumption_rows), ".", call. = FALSE)
}

add_output("unfished_spawning_biomass", c(727, 1176, 1903), region = c("East", "West", "Total"),
  lwr = c(676, 1131, 1807), upr = c(785, 1223, 2008),
  notes = "Median of marginal posterior; 95% interval. Table reports B0 in thousand tonnes for the base two-stock model.")
add_output("SSB", c(396, 456, 855), year = 2025, region = c("East", "West", "Total"),
  season = "mid-season", lwr = c(284, 356, 719), upr = c(540, 572, 1020),
  notes = "Median of marginal posterior; 95% interval. Table reports mid-season 2025 spawning biomass in thousand tonnes for the base two-stock model.")
inputs <- do.call(rbind, input_rows)
assumptions <- do.call(rbind, assumption_rows)
model_assumptions <- do.call(rbind, model_assumption_rows)
outputs <- do.call(rbind, output_rows)
expected_composition_observations <- sum(vapply(blocks[grepl("Age$", names(blocks))], function(block) length(table_rows(block, "obs")), integer(1)))
if (nrow(inputs) != 10348L || nrow(outputs) != 6L || length(unique(inputs$observation_id[nzchar(inputs$observation_id)])) != expected_composition_observations ||
  nrow(model_assumptions) != 88L) {
  stop("Unexpected Hoki import row counts: ", nrow(inputs), " inputs, ", expected_composition_observations, " composition observations, ", length(unique(inputs$observation_id[nzchar(inputs$observation_id)])), " IDs, and ", nrow(outputs), " outputs.", call. = FALSE)
}

new_stock <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "HOK 1", scientific_name = "Macruronus novaezelandiae", common_name = "Hoki",
  area = "HOK 1, New Zealand EEZ", region = "New Zealand waters",
  ocean = "Southwest Pacific", notes = "One New Zealand management area with East and West biological stocks in the 2025 base model.", stringsAsFactors = FALSE)
new_assessment <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2025L,
  assessment_type = "full_assessment", model_family = "Casal2",
  model_version = "v23.04; base two-stock model", is_current = TRUE, is_applied = TRUE,
  framework_year = NA_integer_, assessment_url = "https://fs.fish.govt.nz/Doc/26195/FAR-2026-04-Assessment-of-hoki-in-2025.pdf.ashx",
  framework_url = "", data_url = "https://fs.fish.govt.nz/Doc/26136/FAR-2025-42-Catches-size-and-age-structure-2023-24-hoki-fishery-and-input-data-for-2025-stock-assessment.pdf.ashx",
  model_url = "", repository_url = "", assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed production assessment is the 2025 run, published in 2026, with fitted data through 2024 and a 2025 estimate. Catch observations are aggregate biomass with age-composition proportions; this import does not invent numbers-at-age. Only tabulated B0 and mid-season 2025 SSB outputs are imported; annual age-specific posterior arrays are not available in numeric report tables.", stringsAsFactors = FALSE)

stream_has_id <- function(path, id) {
  con <- file(path, open = "r")
  on.exit(close(con))
  prefix <- paste0('"', id, '"')
  repeat {
    chunk <- readLines(con, n = 20000L, warn = FALSE)
    if (!length(chunk)) return(FALSE)
    if (any(startsWith(chunk, prefix))) return(TRUE)
  }
}
if (write_biological_assumptions_only) {
  path <- file.path(root, "database", "assumptions.csv")
  existing <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  key_fields <- c("assessment_id", "component", "region", "sex", "season", "setting")
  make_key <- function(x) do.call(paste, c(lapply(x[key_fields], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- ""
    value
  }), sep = "\r"))
  if (any(make_key(model_assumptions) %in% make_key(existing))) {
    stop("One or more Hoki biological/category assumptions already exist; refusing to duplicate them.", call. = FALSE)
  }
  write.table(model_assumptions, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidate_lines <- readLines(candidate_path, warn = FALSE)
  candidates <- read.csv(candidate_path,
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  selected <- which(candidates$candidate_id == candidate_id)
  if (length(selected) != 1L) stop("Expected exactly one Hoki discovery candidate.", call. = FALSE)
  candidates$weights_evidence[selected] <- "The 2025 base model's sex- and stock-specific von Bertalanffy age-length functions and shared length-weight function have been imported as assumptions from Appendix B.1.6. No direct weight-at-age surface is published or derived."
  candidates$maturity_evidence[selected] <- "The 2025 base model's seasonal immature-to-mature category transitions and their stock- and sex-specific logistic age selectivities have been imported as assumptions from Appendix B.1.6. These settings are not a static maturity-at-age surface."
  candidate_row <- candidates[selected, , drop = FALSE]
  candidate_row[] <- lapply(candidate_row, function(value) {
    value <- as.character(value)
    value[is.na(value)] <- ""
    value
  })
  row_path <- tempfile()
  write.table(candidate_row, row_path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, qmethod = "double", na = "")
  replacement <- readLines(row_path, warn = FALSE)
  unlink(row_path)
  row_line <- which(startsWith(candidate_lines, paste0('"', candidate_id, '",')))
  if (length(replacement) != 1L || length(row_line) != 1L) {
    stop("Could not safely update the Hoki discovery candidate row.", call. = FALSE)
  }
  candidate_lines[row_line] <- replacement
  writeLines(candidate_lines, candidate_path, useBytes = TRUE)
} else if (write_assumptions_only) {
  path <- file.path(root, "database", "assumptions.csv")
  if (stream_has_id(path, assessment_id)) stop("Hoki assumptions already exist; refusing to duplicate them.", call. = FALSE)
  write.table(assumptions, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double")
} else if (!dry_run) {
  db <- file.path(root, "database")
  for (name in c("stocks.csv", "assessments.csv", "inputs.csv", "assumptions.csv", "outputs.csv")) {
    if (stream_has_id(file.path(db, name), if (name == "stocks.csv") stock_id else assessment_id)) stop("Refusing to duplicate ", assessment_id, " in ", name, ".", call. = FALSE)
  }
  stocks <- read.csv(file.path(db, "stocks.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  assessments_db <- read.csv(file.path(db, "assessments.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  append_csv(new_stock, file.path(db, "stocks.csv"))
  append_csv(new_assessment, file.path(db, "assessments.csv"))
  append_csv(assumptions, file.path(db, "assumptions.csv"))
  append_csv(outputs, file.path(db, "outputs.csv"))
  append_csv(inputs, file.path(db, "inputs.csv"))
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  selected <- which(candidates$candidate_id == candidate_id)
  if (length(selected) != 1L) stop("Expected exactly one Hoki discovery candidate.", call. = FALSE)
  candidates$matched_stock_id[selected] <- stock_id
  candidates$import_status[selected] <- "partial"
  candidates$catch_age_evidence[selected] <- "The base model has catch biomass by fishery and multinomial proportions-at-age with sample sizes, not fishery numbers-at-age. Source quantities are preserved in their native forms; conversion to age-specific catch numbers is not included."
  candidates$survey_age_evidence[selected] <- "Six trawl survey age-composition series are retained as sex-age proportions with sample sizes; aggregate acoustic and trawl biomass-index series are separate records with source CVs."
  candidates$output_evidence[selected] <- "Table 10 supplies posterior B0 and mid-season 2025 SSB medians and 95% intervals for East, West and Total. Annual age-specific N/F/M arrays are not tabulated numerically in the report and remain unavailable."
  candidates$weights_evidence[selected] <- "The base model represents growth through sex-specific length-at-age and length-weight functions; no direct stock weight-at-age matrix was imported."
  candidates$maturity_evidence[selected] <- "The base model uses stock and sex-specific maturity settings. The source parameters are retained as model assumptions rather than converted to a maturity-at-age surface."
  candidates$mortality_evidence[selected] <- "Natural mortality is fixed in the model as a category-level instantaneous-M vector with relative age selectivity; it is not a time-varying M-at-age series."
  write.csv(candidates, candidate_path, row.names = FALSE, na = "")
  selection_path <- file.path(root, "discovery", "selected_batch_02_2026.csv")
  selection <- read.csv(selection_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  selection$curation_status[selection$candidate_id == candidate_id] <- "source_curated_partial"
  write.csv(selection, selection_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"), local = TRUE)
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"), local = TRUE)
}
cat("Hoki source import ", if (write_biological_assumptions_only) "biological assumptions written" else if (write_assumptions_only) "assumptions written" else if (dry_run) "validated (dry run)" else "written", ": ",
  nrow(inputs), " input rows, ", nrow(assumptions), " assumption rows, ",
  nrow(outputs), " output rows; ", nrow(model_assumptions), " additional model-category, growth, length-weight, and maturation assumptions.\n", sep = "")




