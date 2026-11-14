root <- "."
assessment_id <- "mpi_bluenose_nz_2021"
stock_id <- "mpi_bluenose_nz"
candidate_id <- "MPI:BNS_NZ"
report_url <- "https://fs.fish.govt.nz/Doc/25020/FAR-2021-82-New-Zealand-Bluenose-Stock-Assessment-2021.pdf.ashx"
plenary_url <- "https://fs.fish.govt.nz/Doc/26241/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf.ashx"
source_manifest_path <- "provenance/mpi_bluenose_nz_2021_sources.csv"
report_path <- "source_cache/mpi_bluenose_nz_2021/FAR-2021-82-bluenose.pdf"
plenary_path <- "source_cache/mpi_bluenose_nz_2021/Fisheries-Assessment-Plenary-May-2026-Volume-1.pdf"
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args
.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached assessment appendix.", call. = FALSE)
}

manifest <- read.csv(source_manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
source_paths <- file.path("source_cache", manifest$local_file)
if (!all(file.exists(source_paths)) ||
  !identical(toupper(unname(tools::sha256sum(source_paths))), toupper(manifest$sha256))) {
  stop("Cached source files do not match the bluenose provenance manifest.", call. = FALSE)
}

pages <- pdftools::pdf_text(report_path)
appendix_start <- which(grepl("@model", pages, fixed = TRUE))[1L]
appendix_end <- which(seq_along(pages) > appendix_start &
  grepl("11. APPENDIX E: MCMC results", pages, fixed = TRUE))[1L]
if (is.na(appendix_start) || is.na(appendix_end) || appendix_end <= appendix_start) {
  stop("Could not isolate the Casal2 input appendix in FAR 2021/82.", call. = FALSE)
}
lines <- unlist(lapply(pages[seq.int(appendix_start, appendix_end - 1L)], function(page) {
  strsplit(page, "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE)
lines <- trimws(gsub("\r", "", lines, fixed = TRUE))

numeric_tokens <- function(line) {
  line <- trimws(sub("#.*$", "", line))
  if (!nzchar(line)) return(numeric())
  tokens <- strsplit(line, "\\s+")[[1L]]
  values <- suppressWarnings(as.numeric(tokens))
  if (!length(values) || anyNA(values) || any(!is.finite(values))) return(numeric())
  values
}

table_lines <- function(block, table_name) {
  start <- which(trimws(block) == paste("table", table_name))
  if (length(start) != 1L) stop("Expected one table ", table_name, ".", call. = FALSE)
  end <- which(seq_along(block) > start & trimws(block) == "end_table")[1L]
  if (is.na(end)) stop("Unterminated table ", table_name, ".", call. = FALSE)
  block[seq.int(start + 1L, end - 1L)]
}

top_level_blocks <- function(text_lines, marker) {
  starts <- grep(marker, text_lines, perl = TRUE)
  if (!length(starts)) return(list())
  names <- sub("^@\\S+\\s+", "", text_lines[starts])
  ends <- c(starts[-1L] - 1L, length(text_lines))
  blocks <- lapply(seq_along(starts), function(i) text_lines[seq.int(starts[i], ends[i])])
  names(blocks) <- names
  blocks
}

field_value <- function(block, field, required = TRUE) {
  hit <- grep(paste0("^", field, "\\s+"), block)
  if (!length(hit)) {
    if (required) stop("Missing Casal2 field ", field, ".", call. = FALSE)
    return(NA_character_)
  }
  trimws(sub(paste0("^", field, "\\s+"), "", block[hit[1L]]))
}

field_numbers <- function(block, field, continued = field %in% c(
  "years", "length_bins", "length_bins_n", "weight_bins"
)) {
  hit <- grep(paste0("^", field, "\\s+"), block)
  if (length(hit) != 1L) stop("Expected one Casal2 array ", field, ".", call. = FALSE)
  first <- trimws(sub(paste0("^", field, "\\s+"), "", block[hit]))
  values <- numeric_tokens(first)
  if (!continued) {
    if (length(values) != 1L) stop("Casal2 field ", field, " must be scalar.", call. = FALSE)
    return(values)
  }
  for (i in seq.int(hit + 1L, length(block))) {
    line <- trimws(block[i])
    if (!nzchar(line)) next
    if (grepl("^(table\\s+|end_table|@)", line)) break
    if (grepl("Fisheries New Zealand|bluenose 2021 stock assessment", line)) next
    if (grepl("^[A-Za-z][A-Za-z0-9_.]*\\s+", line)) break
    next_values <- numeric_tokens(line)
    if (length(next_values)) values <- c(values, next_values)
  }
  if (!length(values)) stop("Casal2 array ", field, " has no values.", call. = FALSE)
  values
}

year_matrix <- function(block, table_name, years, n_bins, label = table_name) {
  rows <- table_lines(block, table_name)
  out <- list()
  current_year <- NA_integer_
  current_values <- numeric()
  finish <- function() {
    if (is.na(current_year)) return(NULL)
    if (length(current_values) != n_bins) {
      stop(label, " table ", table_name, " year ", current_year, " has ", length(current_values),
        " values; expected ", n_bins, ".", call. = FALSE)
    }
    data.frame(year = current_year, value = I(list(current_values)))
  }
  for (line in rows) {
    values <- numeric_tokens(line)
    if (!length(values)) next
    first_year <- values[1L]
    if (first_year == as.integer(first_year) && first_year %in% years) {
      previous <- finish()
      if (!is.null(previous)) out[[length(out) + 1L]] <- previous
      current_year <- as.integer(first_year)
      current_values <- values[-1L]
    } else if (!is.na(current_year)) {
      current_values <- c(current_values, values)
    }
  }
  previous <- finish()
  if (!is.null(previous)) out[[length(out) + 1L]] <- previous
  result <- do.call(rbind, out)
  if (is.null(result) || !setequal(result$year, as.integer(years))) {
    stop(table_name, " years do not match the Casal2 year list.", call. = FALSE)
  }
  result <- result[match(as.integer(years), result$year), , drop = FALSE]
  matrix_values <- do.call(rbind, result$value)
  colnames(matrix_values) <- NULL
  rownames(matrix_values) <- as.character(result$year)
  matrix_values
}

year_value_table <- function(block, table_name, years, label = table_name,
    allow_missing = FALSE) {
  rows <- table_lines(block, table_name)
  out <- list()
  for (line in rows) {
    values <- numeric_tokens(line)
    if (length(values) >= 2L && values[1L] == as.integer(values[1L]) &&
      values[1L] %in% years) {
      out[[length(out) + 1L]] <- c(year = as.integer(values[1L]), value = values[2L])
    }
  }
  if (!length(out)) stop("No values in Casal2 table ", table_name, " for ", label, ".", call. = FALSE)
  result <- as.data.frame(do.call(rbind, out), stringsAsFactors = FALSE)
  result$year <- as.integer(result$year)
  result$value <- as.numeric(result$value)
  if (anyDuplicated(result$year) || any(!result$year %in% years) ||
    (!allow_missing && !setequal(result$year, as.integer(years)))) {
    stop("Casal2 table ", table_name, " for ", label, " does not cover its year list; found ",
      paste(result$year, collapse = ","), " expected ", paste(years, collapse = ","), ".", call. = FALSE)
  }
  out <- data.frame(year = as.integer(years), value = NA_real_)
  out$value[match(result$year, out$year)] <- result$value
  out
}

categories_region <- function(block) {
  categories <- strsplit(field_value(block, "categories"), "\\+")[[1L]]
  regions <- unique(sub("^[^.]+\\.", "", categories))
  if (length(regions) != 1L) stop("Unexpected Casal2 category areas.", call. = FALSE)
  regions
}

categories_sex <- function(block) {
  categories <- strsplit(field_value(block, "categories"), "\\+")[[1L]]
  sexes <- unique(sub("\\..*$", "", categories))
  if (length(sexes) == 1L) sexes else "combined"
}

population_start <- which(trimws(lines) == "@model")[1L]
observation_start <- grep("^10\\.2\\s+Casal2 observation file", trimws(lines))[1L]
estimation_start <- grep("^@minimiser\\s+", trimws(lines))[1L]
if (is.na(population_start) || is.na(observation_start) || is.na(estimation_start)) {
  stop("Casal2 population or observation section is missing.", call. = FALSE)
}
population_lines <- lines[seq.int(population_start, observation_start - 1L)]
observation_lines <- lines[seq.int(observation_start + 1L, estimation_start - 1L)]
estimation_lines <- lines[seq.int(estimation_start, length(lines))]

model_start <- field_numbers(population_lines, "start_year")
model_end <- field_numbers(population_lines, "final_year")
min_age <- field_numbers(population_lines, "min_age")
max_age <- field_numbers(population_lines, "max_age")
if (length(model_start) != 1L || length(model_end) != 1L ||
  length(min_age) != 1L || length(max_age) != 1L) stop("Unexpected population dimensions.", call. = FALSE)

catch_table <- table_lines(population_lines, "catches")
header_index <- which(grepl("^year\\s+", trimws(catch_table)))[1L]
if (is.na(header_index)) stop("Could not find the fleet header in table catches.", call. = FALSE)
fleets <- strsplit(trimws(catch_table[header_index]), "\\s+")[[1L]][-1L]
catch_data <- list()
for (line in catch_table[seq.int(header_index + 1L, length(catch_table))]) {
  values <- numeric_tokens(line)
  if (length(values) == length(fleets) + 1L && values[1L] == as.integer(values[1L])) {
    catch_data[[length(catch_data) + 1L]] <- values
  }
}
catch_data <- as.data.frame(do.call(rbind, catch_data))
names(catch_data) <- c("year", fleets)
catch_data$year <- as.integer(catch_data$year)
if (nrow(catch_data) != model_end - 1936L + 1L || min(catch_data$year) != 1936L ||
  max(catch_data$year) != model_end) stop("Unexpected catch table coverage.", call. = FALSE)

method_lines <- table_lines(population_lines, "method")
method_rows <- list()
for (line in method_lines) {
  fields <- strsplit(trimws(line), "\\s+")[[1L]]
  if (length(fields) >= 6L && fields[1L] %in% fleets &&
    grepl("^(male|female)\\.", fields[2L])) {
    method_rows[[length(method_rows) + 1L]] <- data.frame(
      fleet = fields[1L], category = fields[2L], selectivity = fields[3L],
      u_max = as.numeric(fields[4L]), penalty = fields[6L], stringsAsFactors = FALSE
    )
  }
}
methods <- do.call(rbind, method_rows)
fleet_region <- vapply(fleets, function(fleet) {
  regions <- unique(sub("^[^.]+\\.", "", methods$category[methods$fleet == fleet]))
  if (length(regions) != 1L) stop("Fleet ", fleet, " has no unique population area.", call. = FALSE)
  regions
}, character(1))

observation_blocks <- top_level_blocks(observation_lines, "^@observation\\s+")
cpue_blocks <- observation_blocks[grepl("^CPUE_", names(observation_blocks))]
age_blocks <- observation_blocks[vapply(observation_blocks, function(x) {
  identical(field_value(x, "type", required = FALSE), "process_removals_by_age")
}, logical(1))]
length_blocks <- observation_blocks[vapply(observation_blocks, function(x) {
  identical(field_value(x, "type", required = FALSE), "process_removals_by_length")
}, logical(1))]
weight_blocks <- observation_blocks[vapply(observation_blocks, function(x) {
  identical(field_value(x, "type", required = FALSE), "process_removals_by_weight")
}, logical(1))]
if (!identical(c(length(cpue_blocks), length(age_blocks), length(length_blocks),
  length(weight_blocks)), c(12L, 2L, 2L, 4L))) {
  stop("Unexpected Casal2 observations: CPUE=", length(cpue_blocks),
    ", age=", length(age_blocks), ", length=", length(length_blocks),
    ", weight=", length(weight_blocks), ". Found: ",
    paste(names(observation_blocks), collapse = ", "), call. = FALSE)
}

input_header <- names(read.csv("database/inputs.csv", nrows = 0L, check.names = FALSE))
if (!"weight_bin" %in% input_header) input_header <- c(input_header, "weight_bin")
assumption_header <- names(read.csv("database/assumptions.csv", nrows = 0L, check.names = FALSE))
output_header <- names(read.csv("database/outputs.csv", nrows = 0L, check.names = FALSE))

make_rows <- function(header, values, n = 1L) {
  result <- lapply(header, function(field) {
    value <- values[[field]]
    if (is.null(value) || !length(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(result) <- header
  as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
}

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_integer_, age = NA_real_,
    fleet = "", survey = "", sex = "", region = "", observation_id = "",
    sample_size = NA_real_, length_bin = NA_real_, weight_bin = NA_real_, age_error = NA_real_,
    sampling_time = NA_real_, year_basis = "model_year", source_type = "official_document",
    source_reference, transformation = "", notes = "", length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, partition = "") {
  n <- max(length(value), length(year), length(age), length(sample_size), length(length_bin),
    length(weight_bin), length(age_error), length(sampling_time), 1L)
  input_rows[[length(input_rows) + 1L]] <<- make_rows(input_header, list(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    value = value, unit = unit, year = year, year_basis = year_basis, age = age,
    fleet = fleet, survey = survey, sex = sex, region = region,
    observation_id = observation_id, sample_size = sample_size,
    length_bin = length_bin, weight_bin = weight_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    age_error = age_error, partition = partition, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes
  ), n)
}

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "",
    fleet = "", survey = "", sex = "", region = "", season = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(assumption_header, list(
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season
  ))
}

population_reference <- "FAR 2021/82, Appendix D, Casal2 population file"
observation_reference <- "FAR 2021/82, Appendix D, Casal2 observation file"
table_reference <- "FAR 2021/82, Table 5, printed p. 16"
estimation_reference <- "FAR 2021/82, Appendix D, Casal2 estimation file"

estimation_blocks <- top_level_blocks(estimation_lines, "^@estimate(\\s|$)")
for (block in estimation_blocks) {
  parameters <- sub("^parameter\\s+", "", grep("^parameter\\s+", block, value = TRUE))
  settings <- grep("^(type|lower_bound|upper_bound|mu|cv|sd|sigma|alpha|beta|mean|shape|rate|median)\\s+",
    trimws(block), value = TRUE)
  if (!length(parameters)) next
  setting_value <- paste(sub("\\s+", "=", trimws(settings)), collapse = "; ")
  for (parameter in parameters) {
    add_assumption("parameter", paste0("estimated_parameter_prior_and_bounds:", parameter),
      setting_value, estimation_reference,
      notes = paste("Active base-model parameter:", parameter,
        "Table 5 point estimate is recorded separately."))
  }
}

for (block in top_level_blocks(estimation_lines, "^@minimiser\\s+")) {
  settings <- grep("^(type|active|iterations|evaluations|tolerance|covariance)\\s+",
    trimws(block), value = TRUE)
  add_assumption("estimation", "minimiser_settings",
    paste(sub("\\s+", "=", trimws(settings)), collapse = "; "),
    estimation_reference)
}
for (block in top_level_blocks(estimation_lines, "^@mcmc\\s+")) {
  settings <- grep("^(start|length|keep|step_size|adapt_stepsize_at|proposal_distribution|adapt_stepsize_method|max_correlation)\\s+",
    trimws(block), value = TRUE)
  add_assumption("uncertainty", "MCMC_settings",
    paste(sub("\\s+", "=", trimws(settings)), collapse = "; "),
    estimation_reference,
    notes = "The report describes MCMC distributions in figures but does not tabulate numeric uncertainty for the reported MPD quantities.")
}

for (fleet in fleets) {
  add_input("catch", "catch_biomass", "biomass", catch_data[[fleet]], "tonnes",
    year = catch_data$year, fleet = fleet, region = fleet_region[[fleet]],
    source_reference = paste(population_reference, "table catches", sep = "; "),
    notes = "Native Casal2 catch biomass by fleet. Years are fishing years labelled by ending year (October-September); the 2021 value repeats 2020 as specified in the model input.")
}

q_blocks <- top_level_blocks(observation_lines, "^@catchability\\s+")
for (name in names(cpue_blocks)) {
  block <- cpue_blocks[[name]]
  years <- field_numbers(block, "years")
  obs <- year_matrix(block, "obs", years, 2L, name)
  survey_region <- categories_region(block)
  process_error <- as.numeric(field_value(block, "process_error"))
  q_name <- field_value(block, "catchability")
  q_block <- q_blocks[[q_name]]
  if (is.null(q_block)) stop("No catchability block for ", name, ".", call. = FALSE)
  lower <- field_value(q_block, "lower_bound")
  upper <- field_value(q_block, "upper_bound")
  add_input("index", "relative_biomass_index", "index_scale", obs[, 1L],
    "standardized CPUE index", year = years, survey = name, region = survey_region,
    sampling_time = 0.5,
    source_reference = paste(observation_reference, paste0("@observation ", name), "table obs", sep = "; "),
    notes = "Standardized commercial CPUE input fitted as a relative biomass index. Year is the fishing year ending in the labelled year; Casal2 evaluates the index at 0.5 of the annual model step.")
  add_input("index", "biomass_index_cv", "relative_scale", obs[, 2L], "ratio",
    year = years, survey = name, region = survey_region, sampling_time = 0.5,
    source_reference = paste(observation_reference, paste0("@observation ", name), "table obs, second value", sep = "; "),
    notes = "Source-supplied annual coefficient of variation paired with the CPUE index; distinct from the fixed Casal2 process_error value.")
  add_assumption("index", "observation_likelihood", "Lognormal; CPUE index with annual CV; q estimated as nuisance parameter",
    paste(observation_reference, paste0("@observation ", name), sep = "; "),
    notes = paste0("Fixed process_error = ", process_error, ". Catchability ", q_name,
      " has bounds ", lower, " to ", upper, "."), survey = name, region = survey_region)
  add_assumption("catchability", "nuisance_parameter_bounds", paste(lower, upper, sep = " to "),
    paste(observation_reference, paste0("@catchability ", q_name), sep = "; "),
    notes = "Series-specific nuisance catchability bounds; the Table 5 output does not report fitted q estimates.", survey = name, region = survey_region)
}

for (name in names(age_blocks)) {
  block <- age_blocks[[name]]
  years <- field_numbers(block, "years")
  ages <- seq.int(as.integer(field_value(block, "min_age")), as.integer(field_value(block, "max_age")))
  values <- year_matrix(block, "obs", years, length(ages), name)
  sizes <- year_value_table(block, "error_values", years, name)
  fleet <- field_value(block, "method_of_removal")
  region <- categories_region(block)
  age_notes <- paste0("Native Casal2 multinomial age composition, not catch numbers-at-age. Likelihood sizes are source error_values; age ",
    max(ages), " is the 61+ plus group. Year labels are fishing years ending in the labelled year.")
  for (i in seq_along(years)) {
    add_input("catch", "proportion_at_age", "proportion_numbers", values[i, ], "proportion",
      year = years[i], age = ages, fleet = fleet, region = region, sex = "combined",
      observation_id = paste(name, years[i], sep = "_"), sample_size = sizes$value[i],
      age_error = 1, source_reference = paste(observation_reference, paste0("@observation ", name), "table obs and error_values", sep = "; "),
      notes = age_notes)
  }
  add_assumption("composition", "ageing_error", "Normal_ageing; normal age error with CV 0.10",
    paste(observation_reference, "@ageing_error Normal_ageing", sep = "; "),
    notes = "Composition cells use age_error code 1 to identify this source error definition.",
    fleet = fleet, region = region)
}

for (name in names(length_blocks)) {
  block <- length_blocks[[name]]
  years <- field_numbers(block, "years")
  bins <- field_numbers(block, "length_bins")
  has_plus_group <- identical(field_value(block, "length_plus"), "T")
  n_observed_bins <- length(bins) - as.integer(!has_plus_group)
  observation_bins <- bins[seq_len(n_observed_bins)]
  values <- year_matrix(block, "obs", years, n_observed_bins, name)
  sizes <- year_value_table(block, "error_values", years, name)
  fleet <- field_value(block, "method_of_removal")
  region <- categories_region(block)
  sex <- categories_sex(block)
  for (i in seq_along(years)) {
    add_input("catch", "proportion_at_length", "proportion_numbers", values[i, ], "proportion",
      year = years[i], fleet = fleet, region = region, sex = sex,
      observation_id = paste(name, years[i], sep = "_"), sample_size = sizes$value[i],
      length_bin = observation_bins, source_reference = paste(observation_reference, paste0("@observation ", name), "table obs and error_values", sep = "; "),
      notes = paste0("Native trawl catch length composition; sample sizes preserve Casal2 error_values. The source uses length_plus = ",
        field_value(block, "length_plus"), "; with no plus group, Casal2 reports n-1 proportions for n successive length boundaries. length_bin stores each reported interval's lower boundary in cm."))
  }
}

for (name in names(weight_blocks)) {
  block <- weight_blocks[[name]]
  years <- field_numbers(block, "years")
  bins <- field_numbers(block, "weight_bins")
  values <- year_matrix(block, "obs", years, length(bins), name)
  sizes <- year_value_table(block, "error_values", years, name, allow_missing = TRUE)
  fleet <- field_value(block, "method_of_removal")
  region <- categories_region(block)
  for (i in seq_along(years)) {
    size_note <- if (is.na(sizes$value[i])) paste0(
      " No Casal2 error_values entry is printed for ", years[i],
      "; sample_size is left blank rather than inferred.") else ""
    add_input("catch_weight", "proportion_at_weight", "proportion_numbers", values[i, ], "proportion",
      year = years[i], fleet = fleet, region = region, sex = "combined",
      observation_id = paste(name, years[i], sep = "_"), sample_size = sizes$value[i],
      weight_bin = bins, source_reference = paste(observation_reference, paste0("@observation ", name), "table obs and error_values", sep = "; "),
      notes = paste0("Packing-data weight composition used in the multinomial likelihood. Bins are mean fish weights per box-part, in kg, rounded to 0.1 kg. sample_size preserves the supplied Casal2 effective likelihood size, which may be fractional; it is not a raw number of fish.", size_note))
  }
  add_assumption("composition", "weight_composition_model", paste(
    "Multinomial; lognormal length-weight variation; bins are mean fish weights per box-part",
    "and may be averaged within 12 kg fishboxes"
  ), paste(observation_reference, paste0("@observation ", name), sep = "; "),
  notes = paste0("length_weight_cv = ", field_value(block, "length_weight_cv"),
    "; fishbox_weight = ", field_value(block, "fishbox_weight"), " kg; delta = ",
    field_value(block, "delta"), ". Casal2 length_bins = ",
    paste(field_numbers(block, "length_bins"), collapse = ","),
    "; length_bins_n = ", paste(field_numbers(block, "length_bins_n"), collapse = ","),
    ". These supporting vectors are model settings, not separate observed length compositions."),
    fleet = fleet, region = region)
}

age_length_blocks <- top_level_blocks(population_lines, "^@age_length\\s+")
length_weight_blocks <- top_level_blocks(population_lines, "^@length_weight\\s+")
length_age <- list()
sex_from_label <- function(label) if (grepl("female", label, fixed = TRUE)) "female" else "male"
for (name in names(age_length_blocks)) {
  block <- age_length_blocks[[name]]
  sex <- sex_from_label(name)
  age_values <- year_matrix(block, "data", 2021L, as.integer(max_age - min_age + 1L))
  length_age[[sex]] <- age_values[1L, ]
  add_input("biology", "growth_length_at_age", "native_covariate", age_values[1L, ], "cm",
    year = 2021L, age = seq.int(min_age, max_age), sex = sex,
    source_reference = paste(population_reference, paste0("@age_length ", name), "table data", sep = "; "),
    notes = "Empirical length-at-age surface supplied to Casal2 and held fixed; age 61 is the plus group.")
}

length_weight_parameters <- list()
for (name in names(length_weight_blocks)) {
  block <- length_weight_blocks[[name]]
  sex <- sex_from_label(name)
  length_weight_parameters[[sex]] <- c(
    a = as.numeric(field_value(block, "a")),
    b = as.numeric(field_value(block, "b"))
  )
}
for (sex in names(length_age)) {
  p <- length_weight_parameters[[sex]]
  weight <- p[["a"]] * length_age[[sex]]^p[["b"]]
  add_input("weight", "weight_at_age", "tonnes_per_fish", weight, "tonnes/fish",
    year = 2021L, age = seq.int(min_age, max_age), sex = sex,
    source_type = "reconstructed_source_input",
    source_reference = paste(population_reference, "@age_length and @length_weight", sep = "; "),
    transformation = paste0("weight (tonnes/fish) = ", format(p[["a"]], scientific = TRUE),
      " * length_at_age_cm^", p[["b"]]),
    notes = "Reconstructed stock weight-at-age from the fixed empirical length-at-age and Casal2 length-weight relationship; no direct weight-at-age vector is supplied. Age 61 is the plus group.")
}

maturity_blocks <- top_level_blocks(population_lines, "^@selectivity\\s+Maturation_")
for (name in names(maturity_blocks)) {
  block <- maturity_blocks[[name]]
  sex <- sub("^Maturation_", "", name)
  a50 <- as.numeric(field_value(block, "a50"))
  ato95 <- as.numeric(field_value(block, "ato95"))
  maturity <- 1 / (1 + exp(-log(19) / ato95 * (seq.int(min_age, max_age) - a50)))
  add_input("maturity", "maturity_at_age", "proportion", maturity, "proportion",
    year = 2021L, age = seq.int(min_age, max_age), sex = sex,
    source_type = "reconstructed_source_input",
    source_reference = paste(population_reference, paste0("@selectivity ", name), sep = "; "),
    transformation = paste0("logistic maturity at age = 1 / (1 + exp(-log(19)/", ato95,
      " * (age - ", a50, ")))."),
    notes = "Reconstructed age-specific maturity from the fixed Casal2 logistic curve; age 61 is the plus group.")
}

selectivity_blocks <- top_level_blocks(population_lines, "^@selectivity\\s+")
for (name in names(selectivity_blocks)) {
  block <- selectivity_blocks[[name]]
  shape <- field_value(block, "type")
  parameters <- block[grepl("^(a50|ato95|mu|sigma_l|sigma_r|c)\\s+", block)]
  add_assumption("selectivity", paste0("functional_form_and_initial_values:", name),
    paste(c(shape, sub("\\s+", "=", trimws(parameters))), collapse = "; "),
    paste(population_reference, paste0("@selectivity ", name), sep = "; "),
    notes = "Casal2 input settings; Table 5 reports fitted base-model estimates separately in outputs.csv.")
}

add_assumption("population", "model_period_and_ages", "1910-2021; ages 1-61+",
  population_reference, notes = "Projection period ends in 2126. The maximum age 61 is a plus group.")
add_assumption("population", "categories", "male.features, female.features, male.background, female.background",
  population_reference, notes = "Two sexes and two model areas; the assessment is one New Zealand-wide stock, not separate QMA models.")
add_assumption("population", "time_steps", "movement followed by fishery; ageing, recruitment, and instantaneous mortality in fishery step",
  population_reference)
add_assumption("population", "initialisation", "Derived equilibrium initialisation",
  population_reference, notes = "Casal2 @initialisation_phase Equilibrium_phase.")
add_assumption("movement", "background_to_features", "Constant transition proportion; initial value 0.029 for both sexes",
  population_reference, notes = "Same age-independent background-to-features process for male and female categories; Table 5 fitted estimate is retained separately.")
add_assumption("recruitment", "process", "Deterministic Beverton-Holt; age 1; steepness h = 0.84; year-class strengths fixed at 1",
  population_reference, notes = "B0 was estimated; standardised year-class strengths span 1909-2019. No stochastic recruitment deviations are fitted in the base model.")
add_assumption("M", "natural_mortality", "Fixed M = 0.08 per year for all ages, sexes, and areas",
  population_reference, notes = "M sensitivity runs are separate scenarios and are not mixed with the base assessment.")
add_assumption("biology", "growth_variability", "Empirical length-at-age; normal length-at-age variation with CV = 0.07",
  paste(population_reference, "@age_length vb_male and vb_female", sep = "; "),
  notes = "Internal missing ages were filled by the Casal2 mean setting. Length-weight variation is described in the source weight-composition settings.")
add_assumption("biology", "length_weight_relationship", "W (tonnes) = 9.63e-9 * length_cm^3.173; fixed for both sexes",
  paste(population_reference, "@length_weight wgt_male and wgt_female", sep = "; "),
  notes = "Casal2 base weight units are tonnes; the same a and b apply to male and female.")
add_assumption("biology", "maturity", "Fixed sex-specific logistic curves: male a50=15.1, ato95=5; female a50=16.7, ato95=10",
  population_reference, notes = "The age-specific maturity surfaces in inputs.csv are reconstructed from these fixed Casal2 selectivity parameters.")
add_assumption("observation", "catch_year_convention", "Fishing years run October-September and are labelled by ending year",
  population_reference, notes = "The 2021 catch value repeats 2020 as specified in the Casal2 population file.")
add_assumption("observation", "age_composition", "Three trawl and twelve bottom-longline multinomial age compositions; age samples assumed random and scaled by catch",
  paste(report_url, "section 2.2, printed p. 13", sep = "; "),
  notes = "Published age compositions are proportions with supplied Casal2 error_values, not catch numbers-at-age or age-specific abundance indices.")
add_assumption("observation", "weight_composition", "Four bottom-longline packing-data weight-frequency series; multinomial likelihood",
  paste(report_url, "sections 2.2 and 2.3, printed pp. 13-14; Appendix A", sep = "; "),
  notes = "Composition likelihood sizes were scaled from observed sample sizes and reduced to give CPUE primacy. Original source values are preserved without renormalization; raw per-year fish counts are not supplied as numeric tables.")
add_assumption("observation", "composition_weighting", "All composition likelihoods are multinomial; effective sample sizes scaled from source observations and reduced, with age compositions given higher weight than length and weight compositions",
  paste(report_url, "section 2.3, printed p. 14", sep = "; "))

output_rows <- list()
add_output <- function(type, measure, value, unit, year = NA_integer_, source_type = "official_table",
    source_reference = table_reference, notes = "", sex = "", region = "", fleet = "",
    survey = "", season = "") {
  output_rows[[length(output_rows) + 1L]] <<- make_rows(output_header, list(
    assessment_id = assessment_id, type = type, measure = measure, value = value,
    unit = unit, year = year, source_type = source_type, source_reference = source_reference,
    notes = notes, sex = sex, region = region, fleet = fleet, survey = survey,
    season = season
  ))
}

base_parameters <- data.frame(
  measure = c("process[Recruitment].b0", "selectivity[sel_trawl].a50",
    "selectivity[sel_trawl].ato95", "selectivity[migrate].c",
    "selectivity[features].a50", "selectivity[features].ato95",
    "selectivity[features2].mu", "selectivity[features2].sigma_l",
    "selectivity[features2].sigma_r", "selectivity[sel_bns7].a50",
    "selectivity[sel_bns7].ato95"),
  value = c(39076, 17.40, 10.78, 0.027, 6.71, 4.58, 9.02, 0.76, 6.09, 13.46, 5.25),
  unit = c("tonnes", "age", "years", "proportion", "age", "years", "age", "years", "years", "age", "years"),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(base_parameters))) {
  add_output("parameter", base_parameters$measure[i], base_parameters$value[i],
    base_parameters$unit[i], notes = "Base-model MPD estimate from Table 5; no standard error or interval is tabulated.")
}
add_output("biomass", "SSB_ratio_to_B0", 25.3, "percent of B0", year = 2021L,
  notes = "Table 5 reports 2021 spawning biomass as 25.3% of B0, rounded to one decimal place; no uncertainty is tabulated.")
add_output("biomass", "SSB", 39076 * 0.253, "tonnes", year = 2021L,
  source_type = "derived_source_output",
  source_reference = paste(table_reference, "B0 and %B0 rows", sep = "; "),
  notes = "Derived as 39,076 tonnes × 25.3%. Approximate because both reported inputs are rounded; no standard error is available.")

input_rows <- do.call(rbind, input_rows)
assumption_rows <- do.call(rbind, assumption_rows)
output_rows <- do.call(rbind, output_rows)
estimated_parameters <- assumption_rows[
  grepl("Active base-model parameter:", assumption_rows$notes, fixed = TRUE), , drop = FALSE
]
expected_counts <- c(catch_biomass = 860L, relative_biomass_index = 98L,
  biomass_index_cv = 98L,
  proportion_at_age = 879L, proportion_at_length = 117L,
  proportion_at_weight = sum(vapply(weight_blocks, function(block) {
    length(field_numbers(block, "years")) * length(field_numbers(block, "weight_bins"))
  }, integer(1))), growth_length_at_age = 122L,
  weight_at_age = 122L, maturity_at_age = 122L)
observed_counts <- vapply(names(expected_counts), function(measure) {
  sum(input_rows$measure == measure)
}, integer(1))
if (nrow(catch_data) != 86L || length(fleets) != 10L ||
  !identical(observed_counts, expected_counts) || nrow(output_rows) != 13L ||
  nrow(estimated_parameters) != nrow(base_parameters)) {
  stop("Unexpected parsed row counts: ", paste(names(observed_counts),
    observed_counts, sep = "=", collapse = ", "), "; expected ",
    paste(names(expected_counts), expected_counts, sep = "=", collapse = ", "),
    "; catch years=", nrow(catch_data), "; fleets=", length(fleets),
    "; outputs=", nrow(output_rows), "; estimated parameter assumptions=",
    nrow(estimated_parameters), " expected=", nrow(base_parameters),
    "; parameters=", paste(estimated_parameters$notes, collapse = " | "), call. = FALSE)
}
composition_rows <- input_rows$measure %in% c(
  "proportion_at_age", "proportion_at_length", "proportion_at_weight"
)
composition_values <- suppressWarnings(as.numeric(input_rows$value[composition_rows]))
composition_sums <- vapply(split(composition_values,
  input_rows$observation_id[composition_rows]), sum, numeric(1))
if (any(!is.finite(composition_values) | composition_values < 0) ||
  any(abs(composition_sums - 1) > 0.01)) {
  stop("A source composition has invalid values or does not sum to one.", call. = FALSE)
}
weight_rows <- input_rows$measure == "proportion_at_weight"
weight_sample_size <- suppressWarnings(as.numeric(input_rows$sample_size[weight_rows]))
missing_weight_sample_size <- is.na(weight_sample_size)
if (any(weight_sample_size[!missing_weight_sample_size] <= 0) ||
  any(missing_weight_sample_size &
    !grepl("sample_size is left blank", input_rows$notes[weight_rows], fixed = TRUE))) {
  stop("Weight composition sample sizes must be positive or documented as absent.", call. = FALSE)
}

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  missing <- setdiff(header, names(rows))
  if (length(missing)) stop("Import rows lack columns: ", paste(missing, collapse = ", "), call. = FALSE)
  size <- file.info(path)$size
  if (size > 0) {
    connection <- file(path, open = "rb")
    seek(connection, where = size - 1, origin = "start")
    last_byte <- readBin(connection, "raw", n = 1L)
    close(connection)
    if (!identical(last_byte, as.raw(10L))) {
      connection <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), connection)
      close(connection)
    }
  }
  rows <- rows[header]
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "\n")
}

rows_exist <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  prefix <- paste0("\"", id, "\",")
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) return(FALSE)
    if (any(startsWith(chunk, prefix))) return(TRUE)
  }
}

replace_csv_row <- function(path, id, row) {
  existing <- readLines(path, warn = FALSE)
  index <- which(startsWith(existing, paste0("\"", id, "\",")))
  if (length(index) != 1L) stop("Could not identify one row for ", id, " in ", path, call. = FALSE)
  temporary <- tempfile(tmpdir = dirname(path))
  write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "")
  existing[index] <- readLines(temporary, warn = FALSE)
  unlink(temporary)
  writeLines(existing, path, useBytes = TRUE)
}

ensure_weight_bin_field <- function(path) {
  line_feed <- as.raw(10L)
  carriage_return <- as.raw(13L)
  quote <- as.raw(34L)
  comma <- as.raw(44L)
  connection <- file(path, open = "rb")
  first_bytes <- readBin(connection, "raw", n = 65536L)
  first_lf <- which(first_bytes == line_feed)[1L]
  if (is.na(first_lf)) {
    close(connection)
    stop("inputs.csv has no header line ending.", call. = FALSE)
  }
  header_line <- first_bytes[seq_len(first_lf - 1L)]
  line_ending <- if (length(header_line) && tail(header_line, 1L) == carriage_return) {
    header_line <- head(header_line, -1L)
    c(carriage_return, line_feed)
  } else line_feed
  if (length(header_line) >= 3L && identical(header_line[1:3], as.raw(c(239L, 187L, 191L)))) {
    header_line <- header_line[-(1:3)]
  }
  header_text <- rawToChar(header_line)
  fields <- names(read.csv(text = header_text, nrows = 0L, check.names = FALSE))
  if ("weight_bin" %in% fields) {
    close(connection)
    return(invisible(NA_character_))
  }
  temporary <- tempfile(pattern = "inputs-weight-bin-", tmpdir = dirname(path))
  output <- file(temporary, open = "wb")
  on.exit({
    try(close(connection), silent = TRUE)
    try(close(output), silent = TRUE)
    if (file.exists(temporary)) unlink(temporary)
  }, add = TRUE)
  writeBin(c(header_line, comma, charToRaw("\"weight_bin\""), line_ending), output)

  write_records <- function(bytes, line_ends) {
    line_starts <- c(1L, head(line_ends, -1L) + 1L)
    content_ends <- line_ends - 1L
    previous <- which(line_ends > 1L)
    crlf <- rep(FALSE, length(line_ends))
    if (length(previous)) crlf[previous] <- bytes[line_ends[previous] - 1L] == carriage_return
    content_ends[crlf] <- content_ends[crlf] - 1L
    line_ends <- line_ends[content_ends >= line_starts]
    if (!length(line_ends)) {
      writeBin(bytes, output)
      return(invisible(NULL))
    }
    insert_positions <- line_ends
    previous <- which(line_ends > 1L)
    crlf <- rep(FALSE, length(line_ends))
    if (length(previous)) crlf[previous] <- bytes[line_ends[previous] - 1L] == carriage_return
    insert_positions[crlf] <- line_ends[crlf] - 1L
    input_positions <- seq_along(bytes)
    expanded <- raw(length(bytes) + length(insert_positions))
    expanded[input_positions + findInterval(input_positions, insert_positions)] <- bytes
    comma_positions <- insert_positions + findInterval(insert_positions - 1L, insert_positions)
    expanded[comma_positions] <- comma
    writeBin(expanded, output)
  }

  pending <- if (first_lf < length(first_bytes)) {
    first_bytes[seq.int(first_lf + 1L, length(first_bytes))]
  } else raw()
  repeat {
    chunk <- readBin(connection, "raw", n = 4L * 1024L * 1024L)
    bytes <- c(pending, chunk)
    line_ends <- which(bytes == line_feed)
    if (length(line_ends)) {
      quote_counts <- cumsum(bytes == quote)
      record_ends <- line_ends[quote_counts[line_ends] %% 2L == 0L]
    } else record_ends <- integer()
    if (length(record_ends)) {
      last_end <- tail(record_ends, 1L)
      complete <- bytes[seq_len(last_end)]
      write_records(complete, record_ends)
      pending <- if (last_end < length(bytes)) bytes[seq.int(last_end + 1L, length(bytes))] else raw()
    } else pending <- bytes
    if (!length(chunk)) {
      if (length(pending)) {
        if (sum(pending == quote) %% 2L != 0L) {
          stop("inputs.csv ends in an unterminated quoted record; weight_bin migration stopped safely.", call. = FALSE)
        }
        if (tail(pending, 1L) == carriage_return) {
          pending <- c(head(pending, -1L), comma, carriage_return)
        } else pending <- c(pending, comma)
        writeBin(pending, output)
      }
      break
    }
  }
  close(connection)
  close(output)
  backup <- paste0(path, ".weight-bin-backup")
  if (file.exists(backup) || !file.rename(path, backup)) {
    stop("Could not safely prepare inputs.csv for the weight_bin field.", call. = FALSE)
  }
  if (!file.rename(temporary, path)) {
    file.rename(backup, path)
    stop("Could not install the weight_bin schema; the original inputs.csv was restored.", call. = FALSE)
  }
  invisible(backup)
}

if ("--migrate-input-schema" %in% args) {
  backup <- ensure_weight_bin_field("database/inputs.csv")
  if (is.na(backup)) {
    cat("inputs.csv already has weight_bin.\n")
  } else {
    cat("Added weight_bin to inputs.csv; preserved the original at ", backup, ".\n", sep = "")
  }
  quit(save = "no", status = 0L)
}

if ("--replace-assumptions" %in% args) {
  path <- "database/assumptions.csv"
  existing <- readLines(path, warn = FALSE)
  keep <- !startsWith(existing, paste0("\"", assessment_id, "\","))
  temporary <- tempfile(tmpdir = dirname(path))
  write.table(assumption_rows, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "")
  existing <- c(existing[keep], readLines(temporary, warn = FALSE))
  unlink(temporary)
  writeLines(existing, path, useBytes = TRUE)
  cat("Replaced the bluenose assumption rows with keyed source settings.\n")
  quit(save = "no", status = 0L)
}

if (!write_mode) {
  missing_weight_observations <- unique(input_rows$observation_id[weight_rows][missing_weight_sample_size])
  cat("Parsed bluenose inputs: ", nrow(input_rows), " rows; ", nrow(assumption_rows),
    " assumptions; ", nrow(output_rows), " outputs; ",
    sum(missing_weight_sample_size), " weight-bin rows lack a printed error_values entry for ",
    paste(missing_weight_observations, collapse = ", "),
    ". Use --write to import.\n", sep = "")
} else {
  stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  selected <- read.csv("discovery/selected_batch_09_2026.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id ||
    rows_exist("database/inputs.csv", assessment_id) ||
    rows_exist("database/outputs.csv", assessment_id) ||
    rows_exist("database/assumptions.csv", assessment_id)) {
    stop("Bluenose is already present in the canonical database.", call. = FALSE)
  }
  candidate_index <- which(candidates$candidate_id == candidate_id)
  selected_index <- which(selected$candidate_id == candidate_id)
  unit_index <- which(units$candidate_unit_id == stock_id)
  if (length(candidate_index) != 1L || length(selected_index) != 1L || length(unit_index) != 1L ||
    candidates$import_status[candidate_index] != "not_started" ||
    selected$curation_status[selected_index] != "selected_for_source_curation") {
    stop("Bluenose discovery records are not in the expected pre-import state.", call. = FALSE)
  }

  stock <- data.frame(stock_id = stock_id, charbonneau_id = "",
    authority = "Fisheries New Zealand", authority_stock_id = "BNS",
    scientific_name = "Hyperoglyphe antarctica", common_name = "Bluenose",
    area = "New Zealand-wide; model partition background and features",
    region = "New Zealand", ocean = "Southwest Pacific",
    notes = "The 2021 Casal2 assessment models one New Zealand-wide biological stock across management QMAs BNS 1, 2, 3, 7, 8, and 10; these are not six separate assessment units.",
    stringsAsFactors = FALSE)
  assessment <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2021L, terminal_year = 2021L, estimate_terminal_year = 2021L,
    assessment_type = "Full production assessment", model_family = "Casal2",
    model_version = "1.0.0", is_current = TRUE, is_applied = TRUE, framework_year = "",
    assessment_url = report_url, framework_url = "", data_url = report_url,
    model_url = "", repository_url = "", assumptions_status = "partial",
    inputs_status = "complete", outputs_status = "partial",
    notes = "The latest detailed assessment run identified in the May 2026 Plenary is the official 2021 Casal2 assessment. Appendix D reproduces the base-run model inputs; no separate fitted object or numerical annual N-at-age/F-at-age outputs were located. The 2021 catch value repeats 2020 as specified in the source model.",
    stringsAsFactors = FALSE)

  ensure_weight_bin_field("database/inputs.csv")
  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/assumptions.csv", assumption_rows)
  append_csv("database/inputs.csv", input_rows)
  append_csv("database/outputs.csv", output_rows)

  candidates$import_status[candidate_index] <- "partial"
  candidates$output_evidence[candidate_index] <- paste(
    "Table 5 reports MPD B0, 2021 %B0, and fitted selectivity/movement parameters.",
    "Approximate SSB is derived from rounded B0 and %B0; annual numerical N-at-age, F-at-age, and recruitment remain unavailable."
  )
  candidates$decision_reason[candidate_index] <- paste(
    "The official 2021 assessment is the latest completed run identified in the May 2026 Plenary.",
    "Appendix D supplies the model observations and biological inputs; Table 5 supplies base-run biomass and fitted parameter outputs."
  )
  candidates$notes[candidate_index] <- paste(
    "Input observations and fixed biology are imported from the report appendix.",
    "Source review records the rounded derived SSB and remaining numerical output gaps."
  )
  replace_csv_row("discovery/candidates.csv", candidate_id, candidates[candidate_index, ])
  selected$curation_status[selected_index] <- "source_curated_partial"
  selected$selection_basis[selected_index] <- paste(
    "The May 2026 Plenary identifies the 2021 official Casal2 assessment as the latest run.",
    "FAR 2021/82 contains detailed model inputs and base-run summary outputs."
  )
  replace_csv_row("discovery/selected_batch_09_2026.csv",
    selected$priority[selected_index], selected[selected_index, ])
  units$import_status[unit_index] <- "partial"
  replace_csv_row("discovery/inventory_units.csv", paste0("candidate:", stock_id), units[unit_index, ])
  cat("Imported New Zealand bluenose 2021 source data:", nrow(input_rows), "inputs,",
    nrow(assumption_rows), "assumptions, and", nrow(output_rows), "outputs.\n")
}
