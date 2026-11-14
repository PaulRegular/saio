root <- "."
stock_id <- "noaa_goa_rex_sole"
assessment_id <- paste0(stock_id, "_2026")
candidate_ids <- c("NOAA:10058", "NOAA:15410", "NOAA:15411")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached NOAA assessment tables.", call. = FALSE)
}

cache_candidates <- c(
  file.path(root, "source_cache", "discovery_noaa_goa_rex_2026"),
  file.path(root, "..", "..", "discovery_noaa_goa_rex_2026")
)
cache <- cache_candidates[dir.exists(cache_candidates)][1L]
if (is.na(cache)) stop("The gitignored GOA rex sole source cache is missing.", call. = FALSE)
manifest_path <- file.path(root, "provenance", "discovery_noaa_goa_rex_2026", "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)

verify_source <- function(file) {
  path <- file.path(cache, file)
  row <- which(manifest$cached_file == file)
  if (length(row) != 1L || !file.exists(path) ||
      tolower(unname(tools::sha256sum(path))) != tolower(manifest$sha256[row])) {
    stop("Cached NOAA source differs from its provenance record: ", file,
      call. = FALSE)
  }
  path
}

report_path <- verify_source("goa_rex_assessment_2026.pdf")
appendix_f_path <- verify_source("goa_rex_appendix_f_numbers_at_age.pdf")
report <- pdftools::pdf_text(report_path)
appendix_f <- pdftools::pdf_text(appendix_f_path)
if (length(report) != 168L || length(appendix_f) != 6L) {
  stop("The cached report or Appendix F page count changed.", call. = FALSE)
}

number_tokens <- function(line) {
  pattern <- "(?<![[:alnum:]])(?:--|NA|-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?)(?![[:alnum:]])"
  tokens <- regmatches(line, gregexpr(pattern, line, perl = TRUE))[[1L]]
  if (length(tokens) == 1L && tokens == "") return(numeric())
  values <- suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
  values[tokens == "--" | toupper(tokens) == "NA"] <- NA_real_
  values
}

year_lines <- function(page) {
  lines <- strsplit(page, "\n", fixed = TRUE)[[1L]]
  lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines, perl = TRUE)]
}

catch_lines <- year_lines(report[[24L]])
catch_parts <- lapply(catch_lines, number_tokens)
if (any(lengths(catch_parts) %% 2L != 0L)) {
  stop("Table 9 has an unexpected catch row.", call. = FALSE)
}
catch_rows <- do.call(rbind, lapply(catch_parts, function(x) {
  matrix(x, ncol = 2L, byrow = TRUE)
}))
catch <- data.frame(year = as.integer(catch_rows[, 1L]),
  catch = as.numeric(catch_rows[, 2L]))
catch <- catch[order(catch$year), , drop = FALSE]
rownames(catch) <- NULL
if (anyDuplicated(catch$year) || !identical(catch$year, 1982:2026) ||
    anyNA(catch$catch) || any(catch$catch < 0)) {
  stop("Table 9 catch coverage is incomplete.", call. = FALSE)
}

survey_lines <- year_lines(report[[28L]])
survey_parts <- lapply(survey_lines, number_tokens)
survey_rows <- lapply(survey_parts, function(x) {
  if (length(x) == 3L) return(c(x, NA_real_, NA_real_))
  if (length(x) != 5L) stop("Table 14 has an unexpected row.", call. = FALSE)
  x
})
survey_table <- as.data.frame(do.call(rbind, survey_rows), stringsAsFactors = FALSE)
names(survey_table) <- c("year", "wc_biomass", "wc_log_se", "east_biomass", "east_log_se")
survey_table$year <- as.integer(survey_table$year)
if (!identical(survey_table$year,
    c(1990L, 1993L, 1996L, 1999L, seq.int(2001L, 2025L, by = 2L))) ||
    sum(is.na(survey_table$east_biomass)) != 1L ||
    survey_table$year[is.na(survey_table$east_biomass)] != 2001L) {
  stop("Table 14 survey coverage or its 2001 Eastern GOA blank changed.", call. = FALSE)
}

biomass_parts <- lapply(year_lines(report[[39L]]), number_tokens)
biomass_parts <- Filter(function(x) {
  length(x) %in% c(4L, 7L) && !is.na(x[1L]) && x[1L] %in% 1982:2026
}, biomass_parts)
if (length(biomass_parts) != length(1982:2026)) {
  stop("Table 31 does not have exactly one row per assessment year.", call. = FALSE)
}
biomass <- lapply(biomass_parts, function(x) {
  if (length(x) == 7L) return(c(x[1L], x[5L:7L]))
  if (length(x) == 4L) return(x)
  stop("Table 31 has an unexpected biomass row.", call. = FALSE)
})
biomass <- as.data.frame(do.call(rbind, biomass), stringsAsFactors = FALSE)
names(biomass) <- c("year", "total_biomass", "ssb", "ssb_sd")
biomass$year <- as.integer(biomass$year)
if (!identical(biomass$year, 1982:2026) || anyNA(biomass[, -1L])) {
  stop("Table 31 current-assessment values are incomplete.", call. = FALSE)
}

recruitment_parts <- lapply(year_lines(report[[38L]]), number_tokens)
recruitment_parts <- Filter(function(x) {
  length(x) %in% c(3L, 4L, 6L, 7L) && !is.na(x[1L]) && x[1L] %in% 1982:2026
}, recruitment_parts)
recruitment_rows <- lapply(recruitment_parts, function(x) {
  current <- tail(x, min(3L, length(x) - 1L))
  if (length(current) == 2L) current <- c(current, NA_real_)
  c(year = x[1L], age3 = current[1L], age0 = current[2L],
    age0_sd = current[3L])
})
recruitment <- as.data.frame(do.call(rbind, recruitment_rows),
  stringsAsFactors = FALSE)
recruitment$year <- as.integer(recruitment$year)
if (!identical(recruitment$year, 1982:2026) ||
    anyNA(recruitment[, c("age3", "age0")]) ||
    !identical(which(is.na(recruitment$age0_sd)), 45L)) {
  stop("Table 30 recruitment coverage or missing SD changed.", call. = FALSE)
}

numbers_lines <- unlist(lapply(appendix_f, year_lines), use.names = FALSE)
numbers_rows <- lapply(numbers_lines, function(line) {
  prefix <- regexec("^\\s*((19|20)[0-9]{2})\\s+(WC|E)\\s+([fm])\\s+", line,
    perl = TRUE)
  match <- regmatches(line, prefix)[[1L]]
  if (!length(match)) stop("Appendix F has an unexpected population row.", call. = FALSE)
  remainder <- sub("^\\s*(19|20)[0-9]{2}\\s+(WC|E)\\s+[fm]\\s+", "", line,
    perl = TRUE)
  values <- number_tokens(remainder)
  if (length(values) != 21L || anyNA(values) || any(values < 0)) {
    stop("Appendix F age coverage or values changed.", call. = FALSE)
  }
  data.frame(year = as.integer(match[2L]), area = match[4L], sex = match[5L],
    age = 0:20, value = values, stringsAsFactors = FALSE)
})
numbers <- do.call(rbind, numbers_rows)
year_coverage <- unique(numbers[c("year", "area", "sex")])
if (nrow(numbers) != 3780L ||
    anyDuplicated(numbers[c("year", "area", "sex", "age")]) ||
    !all(vapply(split(year_coverage$year,
      interaction(year_coverage$area, year_coverage$sex)),
      function(x) identical(unname(sort(x)), 1982:2026), logical(1L)))) {
  stop("Appendix F must contain 45 years by age, area, and sex.", call. = FALSE)
}

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year, survey = "",
    fleet = "", sex = "", region = "", season = "", age = NA_integer_,
    sampling_time = NA_real_, source_reference, notes) {
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = as.integer(year), year_basis = "calendar_year", age = as.integer(age),
    value = as.numeric(value), unit = unit, sampling_time = as.numeric(sampling_time),
    source_type = "official_table", source_reference = source_reference,
    transformation = "", notes = notes, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "", weight_bin = "",
    stringsAsFactors = FALSE)
}

catch_ref <- "2026 GOA Rex Sole SAFE chapter, Table 9, p. 24"
for (i in seq_len(nrow(catch))) {
  partial_note <- if (catch$year[i] == 2026L) paste(
    "Table 9 labels this partial catch through August 22, 2026; Table 7 and",
    "the assessment text describe the cutoff as August 29, 2026. Preserve",
    "the table value and its stated date; do not annualize it.") else ""
  add_input("catch", "catch_biomass", "biomass", catch$catch[i], "t",
    catch$year[i], fleet = "GOA trawl fishery", region = "Western-Central GOA",
    source_reference = catch_ref,
    notes = paste("Official report catch in tonnes. The fishery operates in the",
      "Western-Central GOA; source coverage is retained as reported.", partial_note))
}

survey_ref <- "2026 GOA Rex Sole SAFE chapter, Table 14, p. 28"
for (i in seq_len(nrow(survey_table))) {
  x <- survey_table[i, ]
  for (area in c("Western-Central GOA", "Eastern GOA")) {
    value <- if (area == "Western-Central GOA") x$wc_biomass else x$east_biomass
    log_se <- if (area == "Western-Central GOA") x$wc_log_se else x$east_log_se
    missing_note <- if (x$year == 2001L && area == "Eastern GOA") {
      "The report explicitly states that no Eastern GOA samples were taken in 2001."
    } else ""
    table_note <- if (x$year == 2025L) paste(
      "Table 14 reports this survey value for 2025; the narrative on p. 11",
      "labels the summed 112,824 t value as 2026. The table year is retained.") else ""
    note <- paste("Absolute survey biomass reported in tonnes.",
      "Native survey month is July; sampling_time=0.5 uses the database's",
      "month-start convention (month 7 minus 1, divided by 12).",
      missing_note, table_note)
    add_input("index", "total_biomass", "biomass", value, "t", x$year,
      survey = "NMFS RACE bottom-trawl survey", region = area, season = "July",
      sampling_time = 0.5, source_reference = survey_ref, notes = note)
    if (!is.na(log_se)) {
      add_input("index", "log_index_sd", "log_scale", log_se, "log scale", x$year,
        survey = "NMFS RACE bottom-trawl survey", region = area, season = "July",
        sampling_time = 0.5, source_reference = survey_ref,
        notes = "Table column is labelled Log Standard Error; preserved on the log scale and not converted to a natural-scale SE or CV.")
    }
  }
}
input_rows <- do.call(rbind, input_rows)
if (nrow(input_rows) != 112L) stop("Unexpected input row count.", call. = FALSE)

assumption_rows <- list()
add_assumption <- function(component, setting, value, fleet = "", survey = "",
    sex = "", region = "", season = "", source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}

report_ref <- "2026 GOA Rex Sole SAFE chapter, pp. 11-16"
add_assumption("model", "model_version", "Stock Synthesis 3.3.25.1; Model 25.1",
  source_reference = report_ref,
  notes = "Model 25.1 is identical to Model 25.0 except for the ageing-error matrix.")
add_assumption("model", "model_years", "1982-2026", source_reference = report_ref)
add_assumption("population", "model_areas", "Eastern GOA; Western-Central GOA",
  source_reference = report_ref, notes = "One Gulf-wide stock with two modeled areas.")
add_assumption("population", "sex_structure", "Female and male modeled separately",
  source_reference = report_ref)
add_assumption("population", "age_range", "Age 0-20; age 20 is the plus group",
  source_reference = report_ref)
add_assumption("population", "recruitment_age", "Age 3 for projections and management quantities",
  source_reference = report_ref,
  notes = "The assessment population model includes ages 0-20; age 3 is used for projections and management calculations.")
add_assumption("population", "area_recruitment_allocation", "Fixed proportion by area",
  source_reference = report_ref)
add_assumption("recruitment", "recruitment_deviation_schedule",
  "Estimated for 1965-1981 and 1982-2023 with sigma_R = 0.6; set to mean recruitment for 2024-2026",
  source_reference = "2026 GOA Rex Sole SAFE chapter, p. 13",
  notes = "The model report says recruitment cannot be estimated reliably for 2024-2026 because little information exists on ages 0-1.")
add_assumption("biology", "growth_model",
  "Von Bertalanffy growth estimated separately by sex and area",
  source_reference = "2026 GOA Rex Sole SAFE chapter, pp. 11-14")
add_assumption("biology", "weight_at_age_relationship",
  "Calculated from the fixed weight-length relationship and estimated growth curve",
  source_reference = "2026 GOA Rex Sole SAFE chapter, p. 13",
  notes = "Reported weight-length form is wL = alpha * L^beta. Female alpha = 1.35E-06 and beta = 3.44963; male alpha = 2.18E-06 and beta = 3.30571. The report does not state parameter units in this passage.")
add_assumption("biology", "female_maturity_relationship",
  "Logistic maturity at length; 50% maturity at 351.7 mm with slope 0.0392 mm-1",
  sex = "female", source_reference = "2026 GOA Rex Sole SAFE chapter, p. 13",
  notes = "Using the survey mean length-at-age relationship, the report gives age at 50% maturity as 5.7 years and slope -1.113.")
add_assumption("M", "natural_mortality", "0.17 per year, fixed for both sexes",
  source_reference = "2026 GOA Rex Sole SAFE chapter, Table 1, p. 3")
add_assumption("index", "survey_month", "July (month 7)",
  survey = "NMFS RACE bottom-trawl survey",
  source_reference = "2026 GOA Rex Sole SAFE chapter, Appendix B, p. 81",
  notes = "Annual timing in the input rows uses the month-start convention: (7 - 1) / 12 = 0.5.")
add_assumption("index", "survey_catchability", "Estimated with a prior",
  survey = "NMFS RACE bottom-trawl survey", source_reference = report_ref)
add_assumption("index", "survey_age_likelihood",
  "Conditional age-at-length; marginal age compositions are not included in the objective function",
  survey = "NMFS RACE bottom-trawl survey", source_reference = report_ref)
add_assumption("fishery", "fishery_area", "Western-Central GOA",
  fleet = "GOA trawl fishery", source_reference = report_ref,
  notes = "The report states the fishery does not operate in Eastern GOA.")

weight_ref <- "2026 GOA Rex Sole SAFE chapter, Table 16, p. 30"
relative_weights <- data.frame(
  component = c("Fishery length composition", "Western-Central survey length composition",
    "Eastern survey length composition", "Fishery age composition",
    "Western-Central survey age composition", "Eastern survey age composition"),
  value = c(0.06, 0.51, 0.46, 0.55, 0.08, 0.12),
  stringsAsFactors = FALSE)
for (i in seq_len(nrow(relative_weights))) {
  add_assumption("likelihood", paste("Francis relative weight -", relative_weights$component[i]),
    as.character(relative_weights$value[i]), source_reference = weight_ref,
    notes = "Source-reported relative data-source weight under the Francis (2011) method; not a sample size or CV.")
}
assumption_rows <- do.call(rbind, assumption_rows)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, sex = "", region = "",
    age = NA_integer_, age_group = "", source_reference, notes) {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = sex, region = region, season = "", year = as.integer(year),
    age = as.integer(age), age_group = age_group, value = as.numeric(value),
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = "Model 25.1", stringsAsFactors = FALSE)
}

recruitment_ref <- "2026 GOA Rex Sole SAFE chapter, Table 30, p. 38"
for (i in seq_len(nrow(recruitment))) {
  x <- recruitment[i, ]
  for (age in c(3L, 0L)) {
    value <- if (age == 3L) x$age3 else x$age0
    add_output("recruitment", "recruitment", value,
      "source table units (scale not stated)", x$year, age = age,
      source_reference = recruitment_ref,
      notes = paste("Official Model 25.1 recruitment at age", age,
        "summed across sexes and areas. The report does not state the number scale."))
  }
  if (!is.na(x$age0_sd)) {
    add_output("recruitment", "recruitment_standard_deviation", x$age0_sd,
      "source table units (scale not stated)", x$year, age = 0L,
      source_reference = recruitment_ref,
      notes = "Source-reported standard deviation for age 0 recruits; it is not an SE, and the number scale is not stated.")
  }
}

table31_ref <- "2026 GOA Rex Sole SAFE chapter, Table 31, p. 39"
for (i in seq_len(nrow(biomass))) {
  x <- biomass[i, ]
  add_output("biomass", "total_biomass", x$total_biomass, "t", x$year,
    age_group = "3+", source_reference = table31_ref,
    notes = "Official Model 25.1 total biomass for ages 3+, summed across the two modeled areas and sexes.")
  add_output("biomass", "SSB", x$ssb, "t", x$year, sex = "female",
    source_reference = table31_ref,
    notes = "Official Model 25.1 female spawning biomass, summed across the two modeled areas.")
  add_output("biomass", "SSB_standard_deviation", x$ssb_sd, "t", x$year,
    sex = "female", source_reference = table31_ref,
    notes = "Source-reported Std_Dev_SPB on the natural biomass scale. Preserved as a standard deviation, not an SE or interval.")
}

for (i in seq_len(nrow(numbers))) {
  x <- numbers[i, ]
  region <- if (x$area == "WC") "Western-Central GOA" else "Eastern GOA"
  sex <- if (x$sex == "f") "female" else "male"
  add_output("population", "numbers_at_age", x$value,
    "source table units (scale not stated)", x$year, sex = sex, region = region,
    age = x$age, source_reference = "2026 GOA Rex Sole SAFE chapter, Appendix F, pp. 163-168",
    notes = "Printed Model 25.1 number-at-age value is preserved without scaling. Appendix F does not state whether values are raw numbers or a multiplier; age 20 is the plus group.")
}
output_rows <- do.call(rbind, output_rows)
if (nrow(output_rows) != 4049L || any(!is.finite(output_rows$value))) {
  stop("Table 30, Table 31, or Appendix F output extraction is incomplete.", call. = FALSE)
}

stock <- data.frame(stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-AFSC", authority_stock_id = "10058",
  scientific_name = "Glyptocephalus zachirus", common_name = "Rex sole",
  area = "Gulf of Alaska", region = "Alaska", ocean = "Northeast Pacific",
  notes = "One Gulf of Alaska management unit modeled as Eastern and Western-Central areas. NOAA IDs 15410 and 15411 are area entries for this same assessment; they are not separate stocks. The fishery operates in Western-Central GOA.",
  stringsAsFactors = FALSE)
assessment <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2026L, estimate_terminal_year = 2026L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis 3",
  model_version = "3.3.25.1; Model 25.1", is_current = TRUE, is_applied = TRUE,
  framework_year = NA_integer_,
  assessment_url = "https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=6.+GOA+Rex+Sole.pdf&p=44a13dd4-61ed-4ab1-9eb8-69094d5e517b.pdf",
  framework_url = "", data_url = "", model_url = "",
  repository_url = "https://github.com/noaa-afsc/goa_rex/tree/453e1166e1bf83b9062fe228b93f2225b1cbe1aa",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("The September 2026 SAFE chapter is the latest full assessment located; Model 25.1 was recommended for harvest specifications and supported by the October 2026 SSC. Verified tables imported: catch (Table 9), survey biomass and log standard errors (Table 14), recruitment at ages 0 and 3 and age-0 recruitment standard deviations (Table 30), total biomass and female SSB with SSB standard deviations (Table 31), and numbers-at-age (Appendix F). Table 30 and Appendix F do not state the number scale. Appendix E is labelled draft and was not used; the public AFSC repository contains prior proposed runs, not final 2026 run-matched files. Table 9 and the assessment narrative disagree on the 2026 catch cutoff date; Table 14 and the narrative disagree on whether the 112,824 t survey value is for 2025 or 2026."),
  stringsAsFactors = FALSE)

cat("NOAA GOA rex sole 2026 source extraction\n")
cat("  inputs: ", nrow(input_rows), " rows (catch, survey biomass, log-scale survey SE)\n", sep = "")
cat("  assumptions: ", nrow(assumption_rows), " rows\n", sep = "")
cat("  outputs: ", nrow(output_rows), " rows (Table 30 recruitment, Table 31 biomass, Appendix F numbers-at-age)\n", sep = "")
cat("  years: catch 1982-2026; survey table 1990-2025; outputs 1982-2026\n")
cat("  Appendix E draft age compositions and earlier repository inputs are not imported.\n")
if (!write_mode) {
  cat("Dry run only. Add --write to import the verified source rows.\n")
} else {
  read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  stream_has_id <- function(path, id) {
    con <- file(path, open = "r")
    on.exit(close(con))
    prefix <- paste0('"', id, '",')
    repeat {
      chunk <- readLines(con, n = 100000L, warn = FALSE)
      if (!length(chunk)) return(FALSE)
      if (any(startsWith(chunk, prefix))) return(TRUE)
    }
  }
  append_csv <- function(path, x) write.table(x, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  replace_register_rows <- function(path, key, ids, values) {
    lines <- readLines(path, warn = FALSE)
    x <- read_csv(path)
    hit <- match(ids, x[[key]])
    if (anyNA(hit)) stop("Expected all selected register rows for ",
      paste(ids, collapse = ", "), ".", call. = FALSE)
    for (name in names(values)) x[[name]][hit] <- as.character(values[[name]])
    for (i in seq_along(hit)) {
      lines[hit[i] + 1L] <- paste(capture.output(write.table(
        x[hit[i], , drop = FALSE], sep = ",", quote = TRUE,
        row.names = FALSE, col.names = FALSE, na = "", qmethod = "double"
      )), collapse = "")
    }
    writeLines(lines, path, useBytes = TRUE)
  }

  existing_stocks <- read_csv("database/stocks.csv")
  existing_assessments <- read_csv("database/assessments.csv")
  if (stock_id %in% existing_stocks$stock_id || assessment_id %in% existing_assessments$assessment_id ||
      any(vapply(c("database/inputs.csv", "database/assumptions.csv", "database/outputs.csv"),
        stream_has_id, logical(1L), id = assessment_id))) {
    stop("NOAA GOA rex sole rows are already present in the canonical database.", call. = FALSE)
  }
  candidates <- read_csv("discovery/candidates.csv")
  selected <- read_csv("discovery/selected_unworked_2026.csv")
  candidate_rows <- which(candidates$candidate_id %in% candidate_ids)
  selected_row <- which(selected$candidate_id == "NOAA:10058")
  if (length(candidate_rows) != 3L || length(selected_row) != 1L ||
      any(candidates$import_status[candidate_rows] != "not_started") ||
      selected$curation_status[selected_row] != "selected_for_source_curation") {
    stop("GOA rex sole candidate records are not in the expected selected state.", call. = FALSE)
  }

  for (name in c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
    path <- file.path("database", name)
    expected <- if (name %in% c("inputs.csv", "outputs.csv")) {
      names(read.csv(path, nrows = 0L, check.names = FALSE))
    } else names(read_csv(path))
    rows <- switch(name, "stocks.csv" = stock, "assessments.csv" = assessment,
      "assumptions.csv" = assumption_rows, "inputs.csv" = input_rows,
      "outputs.csv" = output_rows)
    if (!identical(names(rows), expected)) stop("Column order differs for ", name, ".", call. = FALSE)
  }

  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/assumptions.csv", assumption_rows)
  append_csv("database/inputs.csv", input_rows)
  append_csv("database/outputs.csv", output_rows)
  replace_register_rows("discovery/candidates.csv", "candidate_id", candidate_ids,
    list(matched_stock_id = stock_id, match_status = "matched", import_status = "partial",
      review_date = "2026-11-09",
      catch_age_evidence = "The 2026 report's Table 9 catch series (1982-2026) is imported in tonnes. The 2026 value is partial; Table 9 says August 22 while Table 7 and narrative text say August 29. The report-linked Appendix E age-composition tables are labelled draft and were not imported.",
      survey_age_evidence = "Table 14 survey biomass and log standard errors are imported by Eastern and Western-Central GOA for 1990-2025; no Eastern samples were taken in 2001. Table 7 also reports 1984 and 1987 survey biomass, but Table 14 does not publish those values. The report's narrative mislabels the 112,824 t Table 14 value for 2025 as 2026.",
      weights_evidence = "The final report describes estimated sex/area growth and weight-at-length but provides no verified run-matched numeric weight-at-age table in the imported sources. Appendix E is labelled draft and was not used.",
      maturity_evidence = "Female maturity is modeled from a logistic length-at-maturity relationship and survey length-at-age; a verified run-matched numeric maturity-at-age series was not imported.",
      mortality_evidence = "Natural mortality M = 0.17 per year is fixed for both sexes, as reported in Table 1.",
      timing_evidence = "The final 2026 model specifies July for all survey data components; survey input rows use the package's month-start fraction (7-1)/12 = 0.5 and retain July in season/notes.",
      output_evidence = "Table 30 recruitment at ages 0 and 3 and age-0 recruitment standard deviations, Table 31 total biomass age 3+, female SSB and source-reported SSB standard deviation, and Appendix F numbers-at-age are imported for 1982-2026. Recruitment and Appendix F number scales are not stated, so values are not rescaled. Table 30 omits age-0 recruitment SD for 2026. The report does not tabulate an F-at-age surface.",
      decision_reason = "The September 2026 final SAFE chapter documents the latest full assessment for the current Gulf of Alaska unit. Model 25.1 was recommended by the Plan Team and supported by the October 2026 SSC. Verified report-table data and official Appendix F outputs support partial source curation; unverified draft compositions and unspecified N scaling remain explicit gaps.",
      notes = "NOAA IDs 10058, 15410 and 15411 are one Gulf of Alaska management unit; 15410 and 15411 are area entries, not separate stocks. Imported verified Table 9, Table 14, Table 31 and Appendix F values. Appendix E is labelled draft and the cached AFSC repository has earlier proposed runs, not final 2026 model files. See the source review and source-cache manifest."))
  replace_register_rows("discovery/selected_unworked_2026.csv", "candidate_id", "NOAA:10058",
    list(curation_status = "source_curated_partial",
      selection_basis = "The 2026 final SAFE report and its official table attachments provide verified catch, survey biomass/log standard errors, recruitment, total/spawning biomass and age-specific population outputs. Imported Table 9, Table 14, Table 30, Table 31 and Appendix F values; retained unresolved cutoff, survey-year and population-scale details and left Appendix E draft composition data unused."))

  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported partial NOAA GOA rex sole 2026 source data.\n")
}
