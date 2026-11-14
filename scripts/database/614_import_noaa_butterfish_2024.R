root <- "."
stock_id <- "noaa_butterfish_gom_cape_hatteras"
assessment_id <- "noaa_butterfish_gom_cape_hatteras_2024"
candidate_id <- "NOAA:10187"
cache <- "source_cache/discovery_noaa_butterfish_2024"
manifest_path <- "provenance/discovery_noaa_butterfish_2024/sources.csv"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached NOAA assessment tables.", call. = FALSE)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
verify_source <- function(file) {
  path <- file.path(cache, file)
  row <- which(manifest$file == file)
  if (length(row) != 1L || !file.exists(path) ||
      tolower(unname(tools::sha256sum(path))) != tolower(manifest$sha256[row])) {
    stop("Cached NOAA source is missing or differs from its provenance record: ",
      file, call. = FALSE)
  }
  invisible(path)
}

table_path <- verify_source("2024_BUT_UNIT_TAB_ALL.pdf")
verify_source("2024_BUT_UNIT_RPT.pdf")
verify_source("2024_BUT_UNIT_PRESENTATION.pdf")
verify_source("2024_management_track_peer_review.pdf")
pages <- pdftools::pdf_text(table_path)
if (length(pages) != 12L) stop("Expected the 12-page 2024 support-table PDF.", call. = FALSE)

number_tokens <- function(line) {
  pattern <- "(?<![[:alnum:]])(?:NA|-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?)(?![[:alnum:]])"
  tokens <- regmatches(line, gregexpr(pattern, line, perl = TRUE))[[1L]]
  if (length(tokens) == 1L && tokens == "") return(numeric())
  values <- suppressWarnings(as.numeric(gsub(",", "", tokens, fixed = TRUE)))
  values[toupper(tokens) == "NA"] <- NA_real_
  values
}

year_lines <- function(page) {
  lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines, perl = TRUE)]
}

parse_annual <- function(page, years, n_values, label) {
  lines <- year_lines(page)
  rows <- lapply(lines, function(line) {
    values <- number_tokens(line)
    if (length(values) != n_values + 1L) {
      stop(label, " has an unexpected row: ", trimws(line), call. = FALSE)
    }
    values
  })
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", paste0("value", seq_len(n_values)))
  out$year <- as.integer(out$year)
  if (anyDuplicated(out$year) || !identical(out$year, as.integer(years))) {
    stop(label, " year coverage differs from the published table.", call. = FALSE)
  }
  out
}

parse_catch_components <- function() {
  lines <- unlist(strsplit(pages[1:2], "\n", fixed = TRUE), use.names = FALSE)
  headers <- grep("Year.*Landings.*Historic Discards.*Foreign Catch.*Total Catch",
    lines, value = TRUE, perl = TRUE)
  if (length(headers) != 2L) stop("Catch table headers changed.", call. = FALSE)
  starts_for_header <- function(header) {
    positions <- c(
      regexpr("Year", header, fixed = TRUE)[1L],
      regexpr("Landings", header, fixed = TRUE)[1L],
      regexpr("Historic Discards", header, fixed = TRUE)[1L],
      tail(gregexpr("Discards", header, fixed = TRUE)[[1L]], 1L),
      regexpr("Foreign Catch", header, fixed = TRUE)[1L],
      regexpr("Total Catch", header, fixed = TRUE)[1L]
    )
    if (any(positions < 1L) || any(diff(positions) <= 0L)) {
      stop("Could not locate the catch-table columns.", call. = FALSE)
    }
    positions
  }
  parse_page <- function(page) {
    page_lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
    header_line <- grep("Year.*Landings.*Historic Discards.*Foreign Catch.*Total Catch",
      page_lines, perl = TRUE)
    if (length(header_line) != 1L) stop("Catch table page header changed.", call. = FALSE)
    body <- page_lines[seq.int(header_line + 1L, length(page_lines))]
    body <- body[grepl("^\\s*(19|20)[0-9]{2}\\s+", body, perl = TRUE)]
    starts <- starts_for_header(page_lines[header_line])
    parsed <- lapply(body, function(line) {
      cells <- vapply(seq_along(starts), function(i) {
        left <- starts[i]
        right <- if (i < length(starts)) starts[i + 1L] - 1L else nchar(line)
        value <- trimws(substr(line, left, right))
        if (!nzchar(value)) return(NA_real_)
        suppressWarnings(as.numeric(gsub(",", "", value, fixed = TRUE)))
      }, numeric(1L))
      cells
    })
    do.call(rbind, parsed)
  }
  all_rows <- list(parse_page(1L), parse_page(2L))
  for (page_rows in all_rows) {
    if (is.null(dim(page_rows))) stop("Could not parse a catch-table page.", call. = FALSE)
  }
  out <- as.data.frame(do.call(rbind, all_rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "landings", "historic_discards", "discards",
    "foreign_catch", "total_catch")
  out$year <- as.integer(out$year)
  out <- out[order(out$year), , drop = FALSE]
  rownames(out) <- NULL
  if (anyDuplicated(out$year) || !identical(out$year, 1965:2023) ||
      anyNA(out$landings) || anyNA(out$discards) || anyNA(out$total_catch)) {
    stop("Catch component coverage differs from Table 1.", call. = FALSE)
  }
  out
}

catch_components <- parse_catch_components()
discard_and_catch <- year_lines(3L)
discard_and_catch <- lapply(discard_and_catch, number_tokens)
if (length(discard_and_catch) != 35L || any(lengths(discard_and_catch) != 6L)) {
  stop("Table 2 does not contain 35 paired discard and total-catch rows.", call. = FALSE)
}
table2 <- as.data.frame(do.call(rbind, discard_and_catch), stringsAsFactors = FALSE)
names(table2) <- c("discard_year", "discards", "discard_cv", "catch_year", "catch", "catch_cv")
if (any(table2$discard_year != table2$catch_year) ||
    !identical(as.integer(table2$catch_year), 1989:2023)) {
  stop("Table 2 catch and discard years do not align.", call. = FALSE)
}
table2$year <- as.integer(table2$catch_year)

catch_weight <- parse_annual(4L, 1989:2023, 5L, "Table 3 catch weights")
catch_proportion <- parse_annual(5L, 1989:2023, 5L, "Table 4 catch proportions")
nefsc_total <- parse_annual(6L, 1989:2023, 4L, "Table 5 NEFSC aggregate indices")
nefsc_spring_age <- parse_annual(7L, 1989:2023, 5L, "Table 6 NEFSC spring age indices")
nefsc_fall_age <- parse_annual(8L, 1989:2023, 5L, "Table 7 NEFSC fall age indices")

neamap_total_lines <- year_lines(9L)
neamap_total_rows <- lapply(neamap_total_lines, function(line) {
  values <- number_tokens(line)
  year <- values[1L]
  if (year == 2007L && length(values) == 3L) {
    return(c(year, NA_real_, NA_real_, values[2:3]))
  }
  if (length(values) != 5L) stop("Unexpected Table 8 row: ", trimws(line), call. = FALSE)
  values
})
neamap_total <- as.data.frame(do.call(rbind, neamap_total_rows), stringsAsFactors = FALSE)
names(neamap_total) <- c("year", "spring", "spring_cv", "fall", "fall_cv")
neamap_total$year <- as.integer(neamap_total$year)
if (!identical(neamap_total$year, 2007:2023)) stop("Table 8 years changed.", call. = FALSE)
neamap_spring_age <- parse_annual(10L, 2008:2023, 5L, "Table 9 NEAMAP spring age indices")
neamap_fall_age <- parse_annual(11L, 2007:2023, 5L, "Table 10 NEAMAP fall age indices")
population_outputs <- parse_annual(12L, 1989:2023, 6L, "Table 11 population outputs")

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
    age = NA_integer_, fleet = "", survey = "", region = "", season = "",
    year_basis = "", sampling_time = NA_real_, source_reference, notes = "",
    observation_id = "", sample_size = NA_real_, partition = "",
    transformation = "") {
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = region, season = season,
    year = as.integer(year), year_basis = year_basis, age = as.integer(age),
    value = as.numeric(value), unit = unit, sampling_time = as.numeric(sampling_time),
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = observation_id, length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = as.numeric(sample_size), age_error = "", partition = partition,
    weight_bin = "", stringsAsFactors = FALSE)
}

fit_year_note <- "The assessment model covers 1989-2023; earlier catch years are retained as source history and were outside the fitted years."
for (i in seq_len(nrow(catch_components))) {
  x <- catch_components[i, ]
  if (x$year < 1989L) {
    add_input("catch", "catch_biomass", "biomass", x$total_catch, "mt",
      year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
      source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 1, pp. 1-2",
      notes = paste("Reported total catch.", fit_year_note))
  }
  add_input("catch", "landings_biomass", "biomass", x$landings, "mt",
    year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
    partition = "landings",
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 1, pp. 1-2",
    notes = if (x$year < 1989L) fit_year_note else
      "Reported catch component; the model uses one combined fishery catch series, not separate landings and discard fleets.")
  if (is.finite(x$historic_discards)) {
    add_input("catch", "discard_biomass", "biomass", x$historic_discards, "mt",
      year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
      partition = "historic_discards",
      source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 1, pp. 1-2",
      notes = "Source-reported historic discard component; it is not a separate fitted fleet.")
  }
  if (x$year < 1989L) {
    add_input("catch", "discard_biomass", "biomass", x$discards, "mt",
      year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
      partition = "estimated_discards",
      source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 1, pp. 1-2",
      notes = fit_year_note)
  }
  if (is.finite(x$foreign_catch)) {
    add_input("catch", "catch_biomass", "biomass", x$foreign_catch, "mt",
      year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
      partition = "foreign_catch",
      source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 1, pp. 1-2",
      notes = "Source-reported foreign catch component; it is not a separate fitted fleet.")
  }
}

for (i in seq_len(nrow(table2))) {
  x <- table2[i, ]
  add_input("catch", "catch_biomass", "biomass", x$catch, "mt",
    year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 2, p. 3",
    notes = "Reported assessment total-catch series; Table 2 values are used for 1989-2023 rather than repeating Table 1 totals rounded from components.")
  add_input("catch", "discard_biomass", "biomass", x$discards, "mt",
    year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
    partition = "estimated_discards",
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 2, p. 3",
    notes = "Reported estimated discard series; same component as Table 1, with the Table 2 assessment-period values retained here.")
  add_input("catch", "catch_cv", "relative_scale", x$catch_cv, "ratio",
    year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 2, p. 3",
    notes = "Source-reported coefficient of variation for total catch; not an absolute standard error or a likelihood weight.")
  add_input("catch", "catch_cv", "relative_scale", x$discard_cv, "ratio",
    year = x$year, year_basis = "calendar_year", fleet = "Butterfish fishery",
    partition = "estimated_discards",
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 2, p. 3",
    notes = "Source-reported coefficient of variation for estimated discards; not an absolute standard error or a likelihood weight.")
}

for (i in seq_len(nrow(catch_weight))) {
  for (age in 0:4) {
    interpolation <- if (age == 4L && catch_weight$year[i] %in% 1996:1997) {
      "Source-reported interpolation: previous-year age-3 weight plus the time-series average age-3 to age-4+ change."
    } else if (age == 0L && catch_weight$year[i] == 2017L) {
      "Source-reported interpolation: 2018 age-1 weight minus the time-series average age-0 to age-1 change."
    } else ""
    add_input("catch_weight", "catch_weight_at_age", "kg_per_fish",
      catch_weight[i, paste0("value", age + 1L)], "kg/fish",
      year = catch_weight$year[i], age = age, year_basis = "calendar_year",
      fleet = "Butterfish fishery",
      source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 3, p. 4",
      notes = paste(c("Total-catch mean weight at age; age 4 denotes 4+.", interpolation), collapse = " "),
      transformation = if (nzchar(interpolation)) "Source-reported interpolation" else "")
    composition_id <- paste0("butterfish_catch_weight_prop_", catch_proportion$year[i])
    add_input("catch", "proportion_at_age", "proportion_biomass",
      catch_proportion[i, paste0("value", age + 1L)], "proportion",
      year = catch_proportion$year[i], age = age, year_basis = "calendar_year",
      fleet = "Butterfish fishery", observation_id = composition_id,
      source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 4, p. 5",
      notes = "Total-catch age proportions on the biomass/weight basis as printed. sample_size is left blank because the support table provides no raw sample counts or fitted effective N; age 4 denotes 4+. Rounded source values are preserved without renormalization.")
  }
}

add_survey <- function(survey, season, total_data, total_column, cv_column,
    age_data, age_start, age_end, total_reference, age_reference,
    note_missing = "") {
  total_rows <- total_data[total_data$year >= age_start & total_data$year <= age_end, , drop = FALSE]
  age_rows <- age_data[age_data$year >= age_start & age_data$year <= age_end, , drop = FALSE]
  if (!identical(total_rows$year, age_rows$year)) {
    stop("Aggregate and age-specific years do not match for ", survey, ".", call. = FALSE)
  }
  for (i in seq_len(nrow(total_rows))) {
    value <- total_rows[i, total_column]
    cv <- total_rows[i, cv_column]
    missing_note <- if (is.na(value)) paste("Published as NA.", note_missing) else
      "Aggregate total from the same survey/year as the age-specific series; the total and age rows are linked representations, not independent indices."
    add_input("index", "total_numbers", "numbers", value, "number per tow",
      year = total_rows$year[i], year_basis = "calendar_year", survey = survey,
      season = season, source_reference = total_reference, notes = missing_note)
    if (!is.na(value) && !is.na(cv)) {
      add_input("index", "abundance_index_cv", "relative_scale", cv, "ratio",
        year = total_rows$year[i], year_basis = "calendar_year", survey = survey,
        season = season, source_reference = total_reference,
        notes = "Source-reported coefficient of variation for the aggregate mean number per tow; not an age-specific CV.")
    }
  }
  for (i in seq_len(nrow(age_rows))) {
    for (age in 0:4) {
      value <- age_rows[i, paste0("value", age + 1L)]
      age_note <- if (is.na(value)) paste("Published as NA.", note_missing) else
        "Source-reported age-specific mean number per tow; age 4 denotes 4+. The corresponding aggregate total is stored separately as a linked summary."
      add_input("index", "numbers_at_age", "numbers", value, "number per tow",
        year = age_rows$year[i], year_basis = "calendar_year", survey = survey,
        season = season, age = age, source_reference = age_reference, notes = age_note)
    }
  }
}

add_survey("NEFSC fall Albatross", "fall", nefsc_total, "value3", "value4",
  nefsc_fall_age, 1989L, 2008L,
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 5, p. 6",
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 7, p. 8")
add_survey("NEFSC fall Bigelow", "fall", nefsc_total, "value3", "value4",
  nefsc_fall_age, 2009L, 2023L,
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 5, p. 6",
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 7, p. 8",
  "The 2017 survey sampled only 29 of 77 strata; the 2020 survey was not conducted.")
add_survey("NEFSC spring Bigelow", "spring", nefsc_total, "value1", "value2",
  nefsc_spring_age, 2009L, 2022L,
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 5, p. 6",
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 6, p. 7",
  "The 2020 survey was cut short; the 2023 survey covered only Georges Bank and is outside the model's listed 2009-2022 spring Bigelow series.")
add_survey("NEAMAP spring", "spring", neamap_total, "spring", "spring_cv",
  neamap_spring_age, 2008L, 2023L,
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 8, p. 9",
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 9, p. 10",
  "The 2017 survey sampled only 63 of 150 stations; no spring survey was conducted in 2020.")
add_survey("NEAMAP fall", "fall", neamap_total, "fall", "fall_cv",
  neamap_fall_age, 2007L, 2023L,
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 8, p. 9",
  "2024_BUT_UNIT_TAB_ALL.pdf, Table 10, p. 11")

input_rows <- do.call(rbind, input_rows)
if (anyNA(input_rows$assessment_id) ||
    any(!is.finite(input_rows$value) & !is.na(input_rows$value)) ||
    nrow(input_rows) != 1198L) {
  stop("NOAA Butterfish input extraction failed its row-count or value checks: ",
    nrow(input_rows), " rows.", call. = FALSE)
}

proportion_sums <- vapply(split(
  input_rows$value[input_rows$measure == "proportion_at_age"],
  input_rows$observation_id[input_rows$measure == "proportion_at_age"]),
  sum, numeric(1L), na.rm = TRUE)
if (length(proportion_sums) != 35L || any(abs(proportion_sums - 1) > 0.02)) {
  stop("Table 4 compositions changed beyond source rounding.", call. = FALSE)
}
catch_cv_rows <- input_rows[input_rows$measure == "catch_cv", , drop = FALSE]
if (nrow(catch_cv_rows) != 70L || any(catch_cv_rows$value < 0)) {
  stop("Table 2 catch CV coverage is incomplete.", call. = FALSE)
}
survey_age_rows <- input_rows[input_rows$type == "index" & input_rows$measure == "numbers_at_age", , drop = FALSE]
if (nrow(survey_age_rows) != 410L) stop("Survey age-index extraction is incomplete.", call. = FALSE)
survey_age_totals <- aggregate(value ~ survey + year,
  survey_age_rows[!is.na(survey_age_rows$value), ], sum)
survey_total_rows <- input_rows[input_rows$type == "index" &
  input_rows$measure == "total_numbers" & !is.na(input_rows$value),
  c("survey", "year", "value")]
survey_check <- merge(survey_age_totals, survey_total_rows,
  by = c("survey", "year"), suffixes = c("_age_sum", "_total"))
if (!nrow(survey_check) || any(abs(survey_check$value_age_sum -
    survey_check$value_total) > 0.15)) {
  stop("Age-specific survey indices do not sum to the published aggregate indices.",
    call. = FALSE)
}

assumption_rows <- data.frame(
  assessment_id = assessment_id,
  component = c("model", "population", "population", "population", "catch",
    "catch", "M", "biology", "biology", "survey", "q", "survey", "survey",
    "survey", "survey", "survey", "survey", "survey", "survey", "composition",
    "recruitment"),
  fleet = rep("", 21L),
  survey = c(rep("", 10L), "NEFSC fall Albatross", "NEFSC spring Albatross",
    "NEFSC spring Bigelow", "NEFSC fall Albatross", "NEFSC fall Bigelow",
    "NEAMAP spring", "NEAMAP fall", "Young-of-the-year index", "", "", ""),
  sex = "", region = "", season = "",
  setting = c("method", "model_years", "modeled_ages", "N_process", "fleet_structure",
    "selectivity", "natural_mortality", "maturity", "spawning_fraction",
    "survey_inventory", "fall_Albatross_q", "spring_Albatross_usage", "spring_Bigelow_years",
    "fall_Albatross_years", "fall_Bigelow_years", "NEAMAP_spring_years",
    "NEAMAP_fall_years", "YOY_index", "survey_timing", "age_composition_likelihood",
    "reference_point_recruitment_stanza"),
  value = c("WHAM age-structured state-space assessment",
    "1989-2023", "ages 0-4+", "All numbers-at-age are random effects with AR(1) correlation over years and independent processes across ages.",
    "One fishery; one combined catch series.",
    "Two time blocks: 1989-2013 and 2014-2023; selectivity fixed at 1 for age 3.",
    "1.278 per year, carried forward from the 2020 ASAP4 management-track model.",
    "Annual maturity ogives are used; numerical values for the 2024 WHAM run are unavailable.",
    "0.5 of the year.",
    "NEFSC fall Albatross, NEFSC fall Bigelow, NEAMAP fall, NEFSC spring Bigelow, NEAMAP spring, and a young-of-the-year index.",
    "0.2",
    "Not included in the 2024 model; the model inventory lists only spring Bigelow from 2009.",
    "2009-2022", "1989-2008", "2009-2023", "2008-2023", "2007-2023",
    "Used in 2003-2023; numeric annual values were not recovered from the public 2024 support archive.",
    "unknown", "Logistic-normal age-composition likelihood; run-specific composition weights/effective sample sizes are not published in the archive.",
    "2010 start for reference-point calculations; it does not alter fitted annual recruitment or the default time-series recruitment projection."),
  source_reference = c(rep("2024_BUT_UNIT_PRESENTATION.pdf, pp. 19-21", 6L),
    "2024_BUT_UNIT_RPT.pdf, p. 3, Special Comments",
    "2024_BUT_UNIT_PRESENTATION.pdf, p. 19",
    "2024_BUT_UNIT_PRESENTATION.pdf, p. 19",
    "2024_BUT_UNIT_PRESENTATION.pdf, p. 20",
    "2024_BUT_UNIT_RPT.pdf, p. 3, Special Comments",
    rep("2024_BUT_UNIT_PRESENTATION.pdf, p. 20", 7L),
    "2024_BUT_UNIT_PRESENTATION.pdf, p. 20",
    "2024_BUT_UNIT_PRESENTATION.pdf, p. 21",
    "2024_BUT_UNIT_RPT.pdf, p. 3, Special Comments"),
  notes = c("The peer-review panel concluded that the 2024 assessment met its terms of reference and represented the best scientific information available.",
    "Assessment and support tables cover data through 2023.",
    "Age 4 is the 4+ group.",
    "Process description is from the 2024 presentation; the fitted WHAM object is not available for independent inspection.",
    "Catch landings and discard components are retained as source partitions, not separate fitted fleets.",
    "The presentation identifies age 3 as the fixed full-selectivity age.",
    "The 2024 short report states the scalar M value is carried forward from the 2020 model; it does not publish a current fitted object.",
    "The current assessment reports annual maturity ogives but does not provide the numerical 2020-2023 values in the cached support material. Do not substitute the 2021 research-track values.",
    "The numerical spawning fraction is stated in the current model presentation.",
    "Five survey series are also represented by aggregate totals and age-specific mean numbers per tow; the sixth, YOY series remains a numeric data gap.",
    "The short report states that q = 0.2 is needed to scale the population based on survey availability, but it does not say whether q was fixed or estimated.",
    "The 2024 current-model inventory excludes spring Albatross, even though older tables include its data.",
    "The model presentation identifies spring Bigelow for 2009-2022.",
    "The model presentation identifies fall Albatross for 1989-2008.",
    "2017 and 2020 are treated as missing in the current update; 2017 sampled 29/77 strata and 2020 was not conducted.",
    "2017 and 2020 are treated as missing; 2017 sampled 63/150 stations and no spring survey was conducted in 2020.",
    "The 2024 model includes this index, but numerical values and weights are absent from its support tables.",
    "The current archive lists seasons but no run-matched fractional survey times; older model settings are not substituted.",
    "The archive gives the likelihood family but not the likelihood weights; no sample size is inferred from the index tables.",
    "Table 4 age proportions are retained on the published weight basis; the fit-specific transformation to the model's age-composition input is not inferred.",
    "The current update moved the reference-point recruitment stanza start from 2011 to 2010 after adding two years of condition data; the source says this affects reference points, not fitted recruitment."),
  stringsAsFactors = FALSE)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, age = NA_integer_, cv,
    source_reference, notes) {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = as.integer(year),
    age = as.integer(age), age_group = "", value = as.numeric(value), se = NA_real_,
    lwr = NA_real_, upr = NA_real_, unit = unit, source_type = "official_table",
    source_reference = source_reference,
    notes = paste0(notes, " Source-reported CV = ", format(cv, nsmall = 2L),
      "; CV is not stored as an SE, and no absolute SE or interval is published here."),
    scenario = "2024 Management Track", stringsAsFactors = FALSE)
}
for (i in seq_len(nrow(population_outputs))) {
  x <- population_outputs[i, ]
  add_output("biomass", "SSB", x$value1, "mt", x$year, cv = x$value2,
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 11, p. 12",
    notes = "Official spawning stock biomass estimate.")
  add_output("mortality", "fishing_mortality_at_age", x$value3, "year-1",
    x$year, age = 3L, cv = x$value4,
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 11, p. 12",
    notes = "Official fully selected fishing mortality, reported at age 3; not a complete F-at-age surface.")
  add_output("recruitment", "recruitment", x$value5, "million fish", x$year,
    age = 0L, cv = x$value6,
    source_reference = "2024_BUT_UNIT_TAB_ALL.pdf, Table 11, p. 12",
    notes = "Official age-0 recruitment estimate.")
}
output_rows <- do.call(rbind, output_rows)
if (nrow(output_rows) != 105L || any(!is.finite(output_rows$value))) {
  stop("Table 11 output extraction is incomplete.", call. = FALSE)
}

stock <- data.frame(stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NEFSC", authority_stock_id = "10187",
  scientific_name = "Peprilus triacanthus", common_name = "Butterfish",
  area = "Gulf of Maine to Cape Hatteras",
  region = "Northeast U.S. Atlantic coast", ocean = "Northwest Atlantic",
  notes = "Single NOAA management unit; assessment model uses one combined fishery and an age range of 0-4+.",
  stringsAsFactors = FALSE)
assessment <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2023L, estimate_terminal_year = 2023L,
  assessment_type = "management_track", model_family = "WHAM",
  model_version = "2024 Management Track Update", is_current = TRUE,
  is_applied = TRUE, framework_year = 2021L,
  assessment_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=16&stock_id=6&review_type_id=2&filename=2024_BUT_UNIT.zip",
  framework_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=16&stock_id=6&review_type_id=5&info_type_id=5&map_type_id=&filename=Butterfish_2021_Assessment_Report.pdf",
  data_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=16&stock_id=6&review_type_id=2&filename=2024_BUT_UNIT.zip",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "The 2024 Management Track is the latest production assessment identified; the June 2024 peer-review panel endorsed it as the best scientific information available and the June 2026 MAFMC stock-status summary still cites it. The public archive provides catch, weight/composition, five survey series and SSB/Ffull/recruitment outputs, but not the numeric YOY index, run-specific survey timing and composition weights, numeric 2024 maturity ogives, or a fitted WHAM object. Annual N-at-age and F-at-age outputs were not found.",
  stringsAsFactors = FALSE)

cat("NOAA Butterfish 2024 source extraction\n")
cat("  inputs: ", nrow(input_rows), " rows\n", sep = "")
cat("  assumptions: ", nrow(assumption_rows), " rows\n", sep = "")
cat("  outputs: ", nrow(output_rows), " rows\n", sep = "")
cat("  model years/ages: 1989-2023; 0-4+\n")
cat("  catch composition rows retain the reported biomass-proportion basis; no catch-at-age conversion is made.\n")
cat("  age-specific survey rows: ", nrow(survey_age_rows),
  " (including explicitly blank published NA cells)\n", sep = "")

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
  replace_register_row <- function(path, key, id, values) {
    x <- read_csv(path)
    hit <- which(x[[key]] == id)
    if (length(hit) != 1L) stop("Expected one register row for ", id, ".", call. = FALSE)
    for (name in names(values)) x[[name]][hit] <- values[[name]]
    write.csv(x, path, row.names = FALSE, na = "")
  }

  existing_stocks <- read_csv("database/stocks.csv")
  existing_assessments <- read_csv("database/assessments.csv")
  if (stock_id %in% existing_stocks$stock_id || assessment_id %in% existing_assessments$assessment_id ||
      any(vapply(c("database/inputs.csv", "database/assumptions.csv", "database/outputs.csv"),
        stream_has_id, logical(1L), id = assessment_id))) {
    stop("NOAA Butterfish rows are already present in the canonical database.", call. = FALSE)
  }
  candidates <- read_csv("discovery/candidates.csv")
  selected <- read_csv("discovery/selected_batch_22_2026.csv")
  candidate_row <- which(candidates$candidate_id == candidate_id)
  selected_row <- which(selected$candidate_id == candidate_id)
  if (length(candidate_row) != 1L || length(selected_row) != 1L ||
      candidates$import_status[candidate_row] != "not_started" ||
      selected$curation_status[selected_row] != "selected_for_source_curation") {
    stop("NOAA Butterfish discovery records are not in the expected pre-import state.", call. = FALSE)
  }

  for (name in c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
    path <- file.path("database", name)
    expected <- switch(name, "stocks.csv" = names(read_csv(path)),
      "assessments.csv" = names(read_csv(path)), "assumptions.csv" = names(read_csv(path)),
      "inputs.csv" = names(read.csv(path, nrows = 0L, check.names = FALSE)),
      "outputs.csv" = names(read.csv(path, nrows = 0L, check.names = FALSE)))
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
  replace_register_row("discovery/candidates.csv", "candidate_id", candidate_id,
    list(matched_stock_id = stock_id, match_status = "matched", import_status = "partial",
      catch_age_evidence = "Imported 1989-2023 total-catch biomass, the reported total-catch weight proportions by age, and catch weights at age. The support archive does not give raw catch-at-age numbers or likelihood weights; no conversion was placed in the canonical database.",
      survey_age_evidence = "Imported aggregate index totals/CVs and age-specific mean numbers per tow for the five survey series listed in the 2024 model. The young-of-the-year index is included in the model but its numerical time series was not recovered.",
      weights_evidence = "Imported Table 3 total-catch mean weights at ages 0-4+ in kg/fish, including the source-identified interpolations for age 4+ in 1996-1997 and age 0 in 2017.",
      maturity_evidence = "The current model uses annual maturity ogives, but numerical values for the 2024 WHAM run are not in the public support archive; older-run values were not substituted.",
      output_evidence = "Imported 1989-2023 SSB, fully selected F at age 3, and age-0 recruitment with source-reported CVs. Numeric N-at-age/F-at-age arrays were not found.",
      notes = "The 2024 Level 2 assessment has been partially imported from the official support tables. The catch age proportions are weight-based; the source does not provide the effective sample size or conversion used in the fitted likelihood."))
  replace_register_row("discovery/selected_batch_22_2026.csv", "candidate_id", candidate_id,
    list(curation_status = "source_curated_partial",
      selection_basis = "The 2024 Management Track remains the current production assessment. Imported 1,198 source input rows, 21 assumptions and 105 output rows; unresolved current-run survey timing/weights, YOY values, maturity values and age-specific population outputs keep the record partial."))

  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported partial NOAA Butterfish 2024 source data.\n")
}
