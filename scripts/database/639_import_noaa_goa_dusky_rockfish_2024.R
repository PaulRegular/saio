root <- "."
.libPaths(c(file.path(root, "source_cache/R-library"), .libPaths()))
stock_id <- "noaa_goa_dusky_rockfish"
assessment_id <- "noaa_goa_dusky_rockfish_2024"
candidate_id <- "NOAA:10559"
report_url <- "https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAdusky.pdf"
source_dir <- file.path(root, "source_cache/discovery_noaa_dusky_rockfish_2024")
manifest_path <- file.path(root, "provenance/discovery_noaa_dusky_rockfish_2024/sources.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached GOA dusky rockfish SAFE tables.", call. = FALSE)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
sha256_file <- function(path) toupper(unname(tools::sha256sum(path)))
verify_source <- function(file) {
  row <- manifest[manifest$file == file, , drop = FALSE]
  path <- file.path(source_dir, row$cache_file)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.character(file.info(path)$size) != row$bytes ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from the pinned provenance record: ", file,
      call. = FALSE)
  }
  path
}

safe_path <- verify_source("GOA_Dusky_Rockfish_2024_final_SAFE.pdf")
projection_path <- verify_source("GOA_Dusky_Rockfish_2026_projection.pdf")
pages <- pdftools::pdf_text(safe_path)
page_one <- function(pattern) {
  hit <- which(grepl(pattern, pages, fixed = TRUE))
  if (length(hit) != 1L) stop("Expected one SAFE page for: ", pattern, call. = FALSE)
  hit
}
tokens <- function(line) strsplit(trimws(line), "[[:space:]]+")[[1L]]
numbers <- function(x) suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))

catch_page <- pages[[page_one("Table 12-2. Commercial catch")]]
catch_lines <- grep("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9,]+",
  strsplit(catch_page, "\n", fixed = TRUE)[[1L]], value = TRUE, perl = TRUE)
catch_values <- lapply(catch_lines, function(line) numbers(tokens(line)))
if (any(lengths(catch_values) < 2L)) stop("Could not parse the SAFE catch table.", call. = FALSE)
catch <- data.frame(
  year = as.integer(vapply(catch_values, `[`, numeric(1), 1L)),
  value = vapply(catch_values, `[`, numeric(1), 2L)
)
expected_catch_years <- c(1977:1986, 1988:2024)
if (!identical(catch$year, expected_catch_years) || anyDuplicated(catch$year) ||
    catch$value[catch$year == 2024L] != 2176) {
  stop("SAFE Table 12-2 catch coverage or check value changed.", call. = FALSE)
}

parse_composition <- function(page_number, expected_years, reference) {
  lines <- strsplit(pages[[page_number]], "\n", fixed = TRUE)[[1L]]
  header <- grep("^[[:space:]]*Ages[[:space:]]+", lines, value = TRUE, perl = TRUE)
  if (length(header) != 1L) stop("Could not identify composition table years.", call. = FALSE)
  years <- as.integer(tokens(header)[-1L])
  if (!identical(years, as.integer(expected_years))) stop("Composition-table years changed: ",
    paste(years, collapse = ","), " versus ", paste(expected_years, collapse = ","), call. = FALSE)
  age_labels <- c(as.character(4:29), "30+")
  sample_labels <- c("n_iss", "n_h", "n_ess")
  find_row <- function(label) {
    hit <- which(vapply(lines, function(line) {
      z <- tokens(line)
      length(z) > 1L && identical(z[[1L]], label)
    }, logical(1L)))
    if (length(hit) != 1L) stop("Expected one row for ", label, " in ", reference, ".", call. = FALSE)
    values <- numbers(tokens(lines[hit])[-1L])
    if (length(values) != length(years) || any(!is.finite(values))) {
      stop("Invalid ", label, " row in ", reference, ".", call. = FALSE)
    }
    values
  }
  composition <- vapply(age_labels, find_row, numeric(length(years)))
  rownames(composition) <- as.character(years)
  sample_info <- vapply(sample_labels, find_row, numeric(length(years)))
  if (any(abs(rowSums(composition) - 1) > 0.01)) {
    stop("Reported age proportions do not sum to approximately one in ", reference, ".", call. = FALSE)
  }
  data.frame(
    year = rep(years, each = length(age_labels)),
    age = rep(c(4:29, 30L), times = length(years)),
    value = as.vector(t(composition)),
    sample_size = rep(sample_info[, "n_iss"], each = length(age_labels)),
    notes = rep(vapply(seq_along(years), function(i) paste0(
      "Source-reported proportions rounded to three decimals; age 30 denotes the 30+ group. ",
      "Table sample details: n_iss=", sample_info[i, "n_iss"],
      ", n_h=", sample_info[i, "n_h"], ", n_ess=", sample_info[i, "n_ess"],
      ". The SAFE data summary gives different fishery age-composition years; these table values are preserved as printed and are not asserted to be the exact final likelihood arrays."
    ), character(1L)), each = length(age_labels)),
    stringsAsFactors = FALSE
  )
}

fishery_years <- c(2000:2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022)
survey_years <- c(1990, 1993, 1996, 1999, 2001, 2003, 2005, 2007, 2009,
  2011, 2013, 2015, 2017, 2019, 2021, 2023)
fishery_comp <- parse_composition(page_one("Table 12-7. Fishery age compositions"),
  fishery_years, "Table 12-7")
survey_comp <- parse_composition(page_one("Table 12-10. NMFS trawl survey age compositions"),
  survey_years, "Table 12-10")

index_page <- pages[[page_one("Table 12-9. GOA dusky rockfish biomass estimates")]]
index_lines <- grep("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9,]+",
  strsplit(index_page, "\n", fixed = TRUE)[[1L]], value = TRUE, perl = TRUE)
index_values <- lapply(index_lines, function(line) numbers(tokens(line)))
if (any(lengths(index_values) != 5L)) stop("Could not parse SAFE Table 12-9.", call. = FALSE)
survey_index <- as.data.frame(do.call(rbind, index_values))
names(survey_index) <- c("year", "biomass", "se", "lwr", "upr")
survey_index$year <- as.integer(survey_index$year)
survey_index <- survey_index[order(survey_index$year), , drop = FALSE]
if (!identical(survey_index$year, as.integer(survey_years)) ||
    survey_index$biomass[survey_index$year == 2023L] != 58538 ||
    survey_index$se[survey_index$year == 2023L] != 10558) {
  stop("SAFE Table 12-9 coverage or check values changed.", call. = FALSE)
}

parse_mle <- function(page_number) {
  lines <- strsplit(pages[[page_number]], "\n", fixed = TRUE)[[1L]]
  rows <- grep("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines, value = TRUE, perl = TRUE)
  rows <- rows[vapply(rows, function(line) {
    year <- suppressWarnings(as.integer(tokens(line)[1L]))
    !is.na(year) && year >= 1977L && year <= 2024L
  }, logical(1L))]
  out <- lapply(rows, function(line) {
    x <- numbers(tokens(line))
    year <- as.integer(x[1L])
    if ((year <= 2022L && length(x) != 9L) || (year >= 2023L && length(x) != 5L)) {
      stop("Unexpected row shape in SAFE Table 12-12 for year ", year, ".", call. = FALSE)
    }
    selected <- if (year <= 2022L) x[c(1L, 3L, 5L, 7L, 9L)] else x
    data.frame(year = as.integer(selected[1L]), ssb = selected[2L],
      biomass = selected[3L], f = selected[4L], recruitment = selected[5L])
  })
  result <- do.call(rbind, out)
  if (!identical(result$year, 1977:2024) || any(!is.finite(as.matrix(result[-1L]))) ||
      result$ssb[result$year == 2024L] != 37407 ||
      result$biomass[result$year == 2024L] != 88136 ||
      result$recruitment[result$year == 2024L] != 2.84) {
    stop("SAFE Table 12-12 coverage or check values changed.", call. = FALSE)
  }
  result
}
mle <- parse_mle(page_one("Table 12-12. Comparison of 2024"))

parse_mcmc <- function(page_number) {
  lines <- strsplit(pages[[page_number]], "\n", fixed = TRUE)[[1L]]
  rows <- grep("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines, value = TRUE, perl = TRUE)
  rows <- rows[vapply(rows, function(line) {
    year <- suppressWarnings(as.integer(tokens(line)[1L]))
    !is.na(year) && year >= 1977L && year <= 2024L
  }, logical(1L))]
  values <- lapply(rows, function(line) {
    x <- numbers(tokens(line))
    if (length(x) != 13L) stop("Unexpected row shape in SAFE Table 12-14.", call. = FALSE)
    x
  })
  result <- as.data.frame(do.call(rbind, values))
  names(result) <- c("year", "f_mean", "f_lwr", "f_upr", "rec_mean", "rec_lwr",
    "rec_upr", "biomass_mean", "biomass_lwr", "biomass_upr", "ssb_mean",
    "ssb_lwr", "ssb_upr")
  result$year <- as.integer(result$year)
  if (!identical(result$year, 1977:2024) || any(!is.finite(as.matrix(result[-1L]))) ||
      result$ssb_mean[result$year == 2024L] != 37960 ||
      result$rec_mean[result$year == 2024L] != 3800 ||
      result$rec_lwr[result$year == 2024L] != 429 ||
      result$rec_upr[result$year == 2024L] != 14871) {
    stop("SAFE Table 12-14 coverage or check values changed.", call. = FALSE)
  }
  result
}
mcmc <- parse_mcmc(page_one("Table 12-14. Estimated time series"))

input_rows <- list()
add_input <- function(...) input_rows[[length(input_rows) + 1L]] <<-
  pacific_database_row("inputs", assessment_id = assessment_id,
    source_type = "official_table", ...)
add_input(type = "catch", measure = "catch_biomass", basis = "biomass",
  fleet = "Commercial fishery", region = "Gulf of Alaska", season = "annual",
  year = catch$year, year_basis = "calendar_year", value = catch$value,
  unit = "metric tons", source_reference = "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-2 (printed p. 34)",
  notes = "Table reports commercial catch biomass in metric tons. The report describes sources as foreign observer data, joint venture catch data and NMFS Regional Office CAS; 1987 is absent from the table and is not imputed as zero.")

add_composition <- function(data, type, fleet, survey, reference) {
  add_input(type = type, measure = "proportion_at_age", basis = "proportion_numbers",
    fleet = fleet, survey = survey, region = "Gulf of Alaska", year = data$year,
    year_basis = "calendar_year", age = data$age, value = data$value,
    unit = "proportion", sample_size = data$sample_size,
    observation_id = paste0(if (type == "catch") "fishery_agecomp_" else "survey_agecomp_", data$year),
    source_reference = reference, notes = data$notes)
}
add_composition(fishery_comp, "catch", "GOA commercial fishery", "",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-7 (printed p. 39)")
add_composition(survey_comp, "index", "", "NMFS GOA bottom-trawl survey",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-10 (printed p. 42)")

index_ref <- "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-9 (printed p. 41)"
index_notes <- paste0("VAST bottom-trawl survey biomass estimate in metric tons. Source-reported natural-scale SE is ",
  survey_index$se, "; source labels lower/upper CI as ", survey_index$lwr, "/", survey_index$upr,
  " metric tons. The table does not state the confidence level; CI values are retained here because inputs.csv has no interval columns.")
add_input(type = "index", measure = "total_biomass", basis = "biomass",
  survey = "NMFS GOA bottom-trawl survey (VAST)", region = "Gulf of Alaska",
  year = survey_index$year, year_basis = "calendar_year", value = survey_index$biomass,
  unit = "metric tons", source_reference = index_ref,
  notes = index_notes)
add_input(type = "index", measure = "index_sd", basis = "biomass",
  survey = "NMFS GOA bottom-trawl survey (VAST)", region = "Gulf of Alaska",
  year = survey_index$year, year_basis = "calendar_year", value = survey_index$se,
  unit = "metric tons", source_reference = index_ref,
  notes = "Source-reported natural-scale standard error of the matching VAST biomass estimate; this is not a log-scale SD. CI bounds are retained on the paired total_biomass row notes because inputs.csv has no lower/upper columns.")
new_inputs <- do.call(rbind, input_rows)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, sex = "", age = NA_integer_,
                       age_group = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
                       source_reference, notes, scenario) {
  output_rows[[length(output_rows) + 1L]] <<- pacific_database_row("outputs",
    assessment_id = assessment_id, type = type, measure = measure, value = value,
    unit = unit, year = year, sex = sex, age = age, age_group = age_group,
    se = se, lwr = lwr, upr = upr, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario)
}
add_output_set <- function(data, source_reference, scenario, mcmc = FALSE) {
  interval_note <- if (mcmc) "MCMC mean and source-reported 2.5th/97.5th percentile bounds (the table calls them 95% confidence bounds); no standard error is supplied." else "Maximum-likelihood point estimate; no standard error or interval is supplied."
  fields <- if (mcmc) list(
    list("mortality", "fully_selected_fishing_mortality", "f_mean", "f_lwr", "f_upr", "per_year", NA_integer_, ""),
    list("recruitment", "recruitment", "rec_mean", "rec_lwr", "rec_upr", "thousand fish", 4L, "4+"),
    list("biomass", "total_biomass", "biomass_mean", "biomass_lwr", "biomass_upr", "metric tons", NA_integer_, ""),
    list("biomass", "SSB", "ssb_mean", "ssb_lwr", "ssb_upr", "metric tons", NA_integer_, "")
  ) else list(
    list("mortality", "fully_selected_fishing_mortality", "f", NULL, NULL, "per_year", NA_integer_, ""),
    list("recruitment", "recruitment", "recruitment", NULL, NULL, "million fish", 4L, "4+"),
    list("biomass", "total_biomass", "biomass", NULL, NULL, "metric tons", NA_integer_, ""),
    list("biomass", "SSB", "ssb", NULL, NULL, "metric tons", NA_integer_, "")
  )
  for (field in fields) {
    metric <- field[[2L]]
    sex <- if (metric == "SSB") "female" else ""
    value <- data[[field[[3L]]]]
    lwr <- if (is.null(field[[4L]])) rep(NA_real_, nrow(data)) else data[[field[[4L]]]]
    upr <- if (is.null(field[[5L]])) rep(NA_real_, nrow(data)) else data[[field[[5L]]]]
    add_output(type = field[[1L]], measure = metric, value = value,
      unit = field[[6L]], year = data$year, sex = sex, age = field[[7L]],
      age_group = field[[8L]], lwr = lwr, upr = upr,
      source_reference = source_reference,
      notes = paste(interval_note, if (metric == "SSB") "Female spawning biomass." else ""),
      scenario = scenario)
  }
}
add_output_set(mle, "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-12 (printed p. 44)",
  "m22.5a MLE")
add_output_set(mcmc, "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-14 (printed p. 46)",
  "m22.5a MCMC", mcmc = TRUE)
new_outputs <- do.call(rbind, output_rows)

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA", authority_stock_id = "10559",
  scientific_name = "Sebastes variabilis", common_name = "Dusky rockfish - Gulf of Alaska",
  area = "Gulf of Alaska", region = "Gulf of Alaska", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10559 is the Gulf of Alaska unit. It is distinct from other dusky rockfish units; the 2024 SAFE is the latest full assessment located for this unit.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2024L, terminal_year = 2024L,
  estimate_terminal_year = 2024L, assessment_type = "full_assessment",
  model_family = "Age-structured assessment model", model_version = "m22.5a",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url,
  framework_url = "https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+PT+Report.pdf&p=7edd1c8f-f0ce-4936-9fd9-cc1353fe8d0e.pdf",
  data_url = report_url, model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("The November 2024 SAFE m22.5a assessment uses data through 2024 and was agreed by the GOA Plan Team and used for 2025 harvest specifications.",
    "The September 2026 SAFE chapter is a harvest projection from this assessment, with no refit; it is cached for context and excluded from the imported time series."))

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes)
}
add_assumption("model", "author_recommended_model", "m22.5a",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Summary of Results; NPFMC GOA Plan Team report, December 2024",
  "The GOA Plan Team agreed with m22.5a for the 2025 assessment cycle.")
add_assumption("population", "assessment_years", "1977-2024",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Tables 12-2 and 12-12",
  "Catch and reported population estimates span these years; catch is absent for 1987.")
add_assumption("catch", "observation_scale", "Commercial catch biomass, metric tons",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-2",
  "The table describes catch sources as foreign observer, joint venture and NMFS Regional Office Catch Accounting System data.")
add_assumption("mortality", "natural_mortality", "M = 0.07 per year, fixed",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-1 and assessment text (printed pp. 2, 14)",
  "Natural mortality is fixed, not estimated from this assessment.")
add_assumption("biology", "weight_at_age_equation",
  "W_a = W_inf * (1 - exp(-kappa * (a - t0)))^b; W_inf=1928 g, kappa=0.190, t0=0.607, b=3.0",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, assessment text (printed p. 14)",
  "The report says weight-at-age was constructed outside the model from combined-sex survey age/length data. No numeric weight-at-age vector is transcribed here.")
add_assumption("biology", "maturity_at_age_model", "Female maturity-at-age estimated conditionally with a logistic function and binomial likelihood",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, assessment text (printed pp. 11, 15)",
  "The report combines observations from Lunsford (1997, personal communication) and Chilton (2010), estimates two logistic parameters, and reports age at 50% maturity as 10.1. Raw observations and the full coefficient pair are not tabulated.")
add_assumption("index", "survey_index", "NMFS bottom-trawl survey biomass from VAST with lognormal error",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Table 12-9 and assessment summary",
  "Biomass, natural-scale SE and confidence limits are reported for 1990-2023. Table 12-9 does not state the confidence level.")
add_assumption("index", "survey_timing", "Not reported as a within-year fraction",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, assessment data summary",
  "No sampling_time is assigned to the survey index or age-composition inputs.")
add_assumption("composition", "age_composition_coverage",
  "Fishery Table 12-7: ages 4-29 and 30+ for 2000-2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020 and 2022; survey Table 12-10: ages 4-29 and 30+ for 1990-2023 survey years",
  "GOA_Dusky_Rockfish_2024_final_SAFE.pdf, Tables 12-7 and 12-10",
  "Tables report proportions and n_iss, n_h and n_ess. The fishery table years do not exactly match the main-text model data summary; table values are preserved but not certified as the exact final likelihood inputs.")
new_assumptions <- do.call(rbind, assumption_rows)

if (nrow(new_inputs) != 916L || nrow(new_assumptions) != 9L ||
    nrow(new_outputs) != 384L || any(!is.finite(as.numeric(new_inputs$value))) ||
    any(!is.finite(as.numeric(new_outputs$value)))) {
  stop("Unexpected GOA dusky source rows: inputs=", nrow(new_inputs),
    ", assumptions=", nrow(new_assumptions), ", outputs=", nrow(new_outputs), call. = FALSE)
}
if (!file.exists(projection_path)) stop("Expected the cached 2026 projection for context.", call. = FALSE)

if (write_mode) {
  append_pacific_case(stock, assessment, new_assumptions, new_inputs, new_outputs)
  candidates_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
    colClasses = "character", check.names = FALSE)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L) stop("Expected one NOAA:10559 candidate row.", call. = FALSE)
  candidate <- candidates[candidate_row, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "Table 12-2 supplies catch biomass, not native catch-at-age. Table 12-7 reports fishery proportions for ages 4-29 and 30+; its year coverage differs from the main-text model data summary, so the table is retained as source data without claiming it is the final likelihood array."
  candidate$survey_age_evidence <- "Table 12-9 supplies VAST survey biomass with SE and confidence limits for 1990-2023; Table 12-10 supplies survey age proportions for ages 4-29 and 30+ with n_iss, n_h and n_ess. No age-specific biomass index is tabulated."
  candidate$maturity_evidence <- "Female maturity is conditionally fitted with a logistic/binomial model using combined observations cited to Lunsford (1997) and Chilton (2010); the report gives age at 50% maturity as 10.1 but not raw observations or the full coefficient pair."
  candidate$timing_evidence <- "Annual bottom-trawl survey timing is not reported as a within-year fraction; the timing remains unresolved."
  candidate$output_evidence <- "Tables 12-12 and 12-14 report annual female SSB, total biomass, fully selected F and age-4+ recruitment through 2024. Table 12-14 gives MCMC means and 2.5/97.5 percentiles. Numerical N-at-age and F-at-age surfaces are not provided."
  candidate$notes <- "Partial source import committed for the latest full 2024 m22.5a assessment of the current GOA unit. Catch biomass, both published age-composition tables, VAST index and uncertainty, eight model/biology assumptions, and MLE/MCMC aggregate outputs are recorded. Maturity raw observations, the exact final fishery composition likelihood arrays, survey timing, weight-at-age values, N-at-age and F-at-age remain unavailable or unresolved."
  replace_candidate_register_row(candidates_path, candidate_row, candidate, candidate_id)
  batch_path <- file.path(root, "discovery/selected_batch_27_2026.csv")
  batch <- read.csv(batch_path, stringsAsFactors = FALSE, check.names = FALSE)
  batch_row <- which(batch$candidate_id == candidate_id)
  if (length(batch_row) != 1L) stop("Expected one selected-batch row for NOAA:10559.", call. = FALSE)
  batch$curation_status[batch_row] <- "imported_partial"
  write.csv(batch, batch_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat("Imported ", nrow(new_inputs), " inputs, ", nrow(new_assumptions),
    " assumptions, and ", nrow(new_outputs), " outputs for ", assessment_id, ".\n", sep = "")
} else {
  cat("Prepared ", nrow(new_inputs), " inputs, ", nrow(new_assumptions),
    " assumptions, and ", nrow(new_outputs), " outputs for ", assessment_id, ".\n", sep = "")
  cat("Catch years: ", min(catch$year), "-", max(catch$year), " (1987 absent); fishery composition rows: ",
    nrow(fishery_comp), "; survey composition rows: ", nrow(survey_comp),
    "; VAST index years: ", min(survey_index$year), "-", max(survey_index$year),
    "; reported outputs through 2024 only.\n", sep = "")
}
