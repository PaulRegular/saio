# Import the detailed 2024 HYBRID assessment for NAFO Subdivision 3Ps cod.
# Run from the SAIO repository root after caching the official report.

root <- "."
db <- file.path(root, "database")
source_dir <- file.path(root, "source_cache", "ck_dfo_morhua_3ps", "assessment_2024")
source_file <- file.path(source_dir, "Fs70-5-2026-051-eng.pdf")
assessment_id <- "dfo_cod_3ps_2024"
abort <- function(...) stop(paste0(...), call. = FALSE)
assessment_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-051-eng.pdf"
framework_url <- "https://waves-vagues.dfo-mpo.gc.ca/Library/4105829x.pdf"
summary_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290355.pdf"

if (!file.exists(source_file)) {
  abort("The cached 2024 3Ps assessment report is missing: ", source_file)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  abort("Install pdftools to extract the published input tables.")
}

text <- pdftools::pdf_text(source_file)

read_table <- function(pages, heading, next_heading = NULL, n_values, dot_thousands = FALSE) {
  lines <- trimws(unlist(strsplit(text[pages], "\\n", fixed = FALSE)))
  start <- grep(heading, lines, ignore.case = TRUE)
  if (!length(start)) abort("Could not find ", heading, " in the cached report.")
  start <- start[[1]]
  end <- length(lines)
  if (!is.null(next_heading)) {
    next_match <- grep(next_heading, lines, ignore.case = TRUE)
    next_match <- next_match[next_match > start]
    if (!length(next_match)) abort("Could not find ", next_heading, " after ", heading, ".")
    end <- next_match[[1]] - 1L
  }
  rows <- lines[seq.int(start + 1L, end)]
  rows <- rows[grepl("^(19|20)[0-9]{2}[[:space:]]+", rows)]
  parse_number <- function(x) {
    if (x %in% c("-", "–", "—")) return(NA_real_)
    x <- gsub(",", "", x, fixed = TRUE)
    if (dot_thousands && grepl("^[0-9]{1,3}\\.[0-9]{3}$", x)) x <- gsub("\\.", "", x)
    suppressWarnings(as.numeric(x))
  }
  parsed <- lapply(rows, function(line) {
    fields <- strsplit(trimws(line), "[[:space:]]+")[[1]]
    if (length(fields) != n_values + 1L) {
      abort("Unexpected number of values in ", heading, " row: ", line)
    }
    c(as.numeric(fields[[1]]), vapply(fields[-1], parse_number, numeric(1)))
  })
  out <- as.data.frame(do.call(rbind, parsed), check.names = FALSE)
  names(out) <- c("year", paste0("v", seq_len(n_values)))
  if (anyDuplicated(out$year)) abort("Duplicate years in ", heading, ".")
  out
}

landings <- read_table(99:100, "Table A-1:", n_values = 3, dot_thousands = TRUE)
catch <- read_table(101:102, "Table A-2:", n_values = 13)
m_condition <- read_table(103:104, "Table A-3:", n_values = 1)
rv <- read_table(105, "Table A-4:", n_values = 13)
erhaps <- read_table(106, "Table A-5:", "Table A-6:", n_values = 13)
geac <- read_table(106, "Table A-6:", n_values = 13)
sentinel_gn <- read_table(107, "Table A-7:", n_values = 7)
sentinel_lt <- read_table(108, "Table A-8:", n_values = 8)
maturity <- read_table(109:110, "Table A-9:", n_values = 13)
stock_weight <- read_table(111:112, "Table A-10:", n_values = 13)
catch_weight <- read_table(113:114, "Table A-11:", n_values = 13)

expected_years <- list(
  landings = 1959:2024, catch = 1959:2023, m_condition = 1959:2024,
  rv = c(1983:2005, 2007:2019, 2021:2022, 2024), erhaps = 1978:1991, geac = 1998:2005,
  sentinel_gn = 1995:2023, sentinel_lt = 1995:2023,
  maturity = 1959:2024, stock_weight = 1959:2024,
  catch_weight = 1959:2024
)
tables <- list(
  landings = landings, catch = catch, m_condition = m_condition, rv = rv,
  erhaps = erhaps, geac = geac, sentinel_gn = sentinel_gn,
  sentinel_lt = sentinel_lt, maturity = maturity,
  stock_weight = stock_weight, catch_weight = catch_weight
)
for (nm in names(tables)) {
  if (!identical(tables[[nm]]$year, as.numeric(expected_years[[nm]]))) {
    abort("Unexpected year coverage in Table ", nm, ": ", paste(tables[[nm]]$year, collapse = ","), ". Expected ", paste(expected_years[[nm]], collapse = ","), ".")
  }
}

empty_inputs <- function(n) {
  data.frame(
    assessment_id = rep(assessment_id, n), type = "", measure = "", basis = "",
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = NA_real_, year_basis = "calendar_year", age = NA_real_, value = NA_real_,
    unit = "", sampling_time = NA_real_, source_type = "official_table",
    source_reference = "", transformation = "", notes = "",
    observation_id = "", length_bin = "", length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = "",
    partition = "", stringsAsFactors = FALSE
  )
}

add_age_table <- function(x, ages, type, measure, basis, unit, source_table,
                          fleet = "", survey = "", season = "", notes = "", transformation = "") {
  idx <- expand.grid(year_row = seq_len(nrow(x)), age_col = seq_along(ages))
  idx <- idx[order(idx$year_row, idx$age_col), ]
  out <- empty_inputs(nrow(idx))
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- fleet
  out$survey <- survey
  out$season <- season
  out$year <- x$year[idx$year_row]
  out$age <- ages[idx$age_col]
  out$value <- as.vector(t(as.matrix(x[, paste0("v", seq_along(ages)), drop = FALSE])))
  out$unit <- unit
  out$source_reference <- paste0("DFO Research Document 2026/051, ", source_table)
  out$transformation <- transformation
  out$notes <- notes
  out
}

inputs <- list(
  add_age_table(
    catch, 2:14, "catch", "numbers_at_age", "numbers",
    "thousand fish", "Table A-2",
    fleet = "Commercial fishery",
    notes = "Age 14 is the source 14+ group. The assessment fits catch composition with continuation-ratio logits.",
    transformation = "Unit scale cross-checked against the same age-3+ catch series reported as numbers-at-age (000s) in DFO Research Documents 2023/025 Table 6 and 2024/002 Table 6; prior-report values are used only to confirm the unit convention; 2026/051 values are retained."
  ),
  add_age_table(
    rv, 2:14, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)", "Table A-4",
    survey = "DFO RV Spring", season = "spring",
    notes = "Age 14 is 14+. Zero observations are retained; HYBRID uses a censored survey likelihood."
  ),
  add_age_table(
    erhaps, 2:14, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)", "Table A-5",
    survey = "ERHAPS", season = "winter",
    notes = "Age 14 is 14+. Zero observations are retained; HYBRID uses a censored survey likelihood."
  ),
  add_age_table(
    geac, 2:14, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)", "Table A-6",
    survey = "GEAC", season = "fall",
    notes = "Age 14 is 14+. Zero observations are retained; HYBRID uses a censored survey likelihood."
  ),
  add_age_table(
    sentinel_gn, 4:10, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)", "Table A-7",
    survey = "Sentinel Gillnet", season = "sentinel",
    notes = "Table covers ages 4-10. Zero observations are retained; HYBRID uses a censored survey likelihood."
  ),
  add_age_table(
    sentinel_lt, 3:10, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)", "Table A-8",
    survey = "Sentinel Line-trawl", season = "sentinel",
    notes = "Table covers ages 3-10. Zero observations are retained; HYBRID uses a censored survey likelihood."
  ),
  add_age_table(
    maturity, 2:14, "maturity", "maturity_at_age", "proportion",
    "proportion mature", "Table A-9",
    notes = "Age 14 is 14+."
  ),
  add_age_table(
    stock_weight, 2:14, "weight", "weight_at_age", "kg_per_fish",
    "kg/fish", "Table A-10",
    notes = "Age 14 is 14+. Weights are the model's stock-weight surface."
  ),
  add_age_table(
    catch_weight, 2:14, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg/fish", "Table A-11",
    notes = "The source table labels its final group age 14 without a plus sign; preserve as reported and review mapping to model age 14+."
  )
)
inputs <- do.call(rbind, inputs)

long_scalar <- function(x, type, measure, basis, unit, source_table, notes = "") {
  out <- empty_inputs(nrow(x))
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$year <- x$year
  out$value <- x$v1
  out$unit <- unit
  out$source_reference <- paste0("DFO Research Document 2026/051, ", source_table)
  out$notes <- notes
  out
}

landing_rows <- lapply(seq_len(3), function(j) {
  measure <- c("total_biomass", "landings_lower_bound", "landings_upper_bound")[[j]]
  out <- long_scalar(
    data.frame(year = landings$year, v1 = landings[[paste0("v", j)]]),
    "catch", measure, "biomass", "t", "Table A-1",
    "Landings observation and interval bound for the censored landings likelihood. Table reports 2024 landings as the 2024/25 TAC."
  )
  out
})
condition_rows <- long_scalar(
  data.frame(year = m_condition$year, v1 = m_condition$v1),
  "covariate", "condition_index_for_mortality", "native_covariate", "standardized condition-index scale",
  "Table A-3", "One annual fish-condition index used to inform M across modeled ages; the 1959-1977 values use the average of 1978-1982."
)
inputs <- rbind(inputs, do.call(rbind, landing_rows), condition_rows)
inputs <- inputs[is.finite(inputs$value), , drop = FALSE]

new_assessment <- data.frame(
  assessment_id = assessment_id, stock_id = "ck_dfo_morhua_3ps",
  assessment_year = 2024, terminal_year = 2024, estimate_terminal_year = 2025,
  assessment_type = "full_assessment", model_family = "HYBRID",
  model_version = "HYBRID under the 2019 framework; detailed report published as DFO Research Document 2026/051",
  is_current = TRUE, is_applied = TRUE, framework_year = 2019,
  assessment_url = assessment_url, framework_url = framework_url,
  data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The 2024 assessment under the 2019 HYBRID framework is the latest annual assessment represented here.",
    "Detailed applied-model report 2026/051 was published in August 2026.",
    "The associated 2025/007 Science Advisory Report provides annual aggregate SSB, recruitment, and grouped F/M for 2020-2024.",
    "The 2025 catch/survey update (2026/047) is not mixed into this assessment.",
    "Published appendix tables provide the principal inputs, but executable HYBRID files, full model controls, complete numerical fitted trajectories, and N/F/M age surfaces were not located."
  ), stringsAsFactors = FALSE
)

assumption_rows <- data.frame(
  assessment_id = assessment_id, component = "", fleet = "", survey = "", sex = "",
  region = "", season = "", setting = "", value = "",
  source_reference = "DFO Research Document 2026/051", notes = "",
  stringsAsFactors = FALSE
)
add_assumption <- function(component, setting, value, source, notes = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "", survey = "",
    sex = "", region = "", season = "", setting = setting, value = value,
    source_reference = source, notes = notes, stringsAsFactors = FALSE
  )
}
assumption_rows <- do.call(rbind, list(
  add_assumption("population", "model_years", "1959-2024; projected SSB reported for 2025", "pp. 9-11; Figure 56"),
  add_assumption("population", "modeled_ages", "2-14+", "p. 10; Table A-2"),
  add_assumption("recruitment", "process", "Age-2 recruitment follows a random walk", "p. 10"),
  add_assumption("F", "process", "Multivariate-normal random walk; age 2 is separate from the correlated age 3+ process", "p. 10"),
  add_assumption("F", "process_break", "A discontinuity is included at the 1993 moratorium", "p. 10"),
  add_assumption("catch", "landings_likelihood", "Censored likelihood using annual lower and upper landings bounds", "p. 10; Table A-1"),
  add_assumption("catch", "age_composition_likelihood", "Continuation-ratio logits for catch-at-age", "p. 10; Table A-2"),
  add_assumption("M", "time_varying_mortality", "M is a function of the scaled fish-condition mortality index", "p. 10; Table A-3"),
  add_assumption("M", "condition_index_early_years", "Average of 1978-1982 index used for 1959-1977", "p. 10; Table A-3"),
  add_assumption("index", "survey_series", "DFO RV Spring 1983-2024; ERHAPS 1978-1991; GEAC 1998-2005; Sentinel Gillnet and Line-trawl 1995-2023", "pp. 10-11; Tables A-4-A-8"),
  add_assumption("index", "zero_observations", "Censored survey likelihood retains zero catches as information on low abundance", "p. 10; Tables A-4-A-8"),
  add_assumption("index", "rv_catchability", "Ages 2-7 have separate offshore and inshore-offshore catchabilities; ages 8+ use an inshore-offshore offset", "p. 10"),
  add_assumption("index", "timing", "Exact annual survey timing fractions used by HYBRID were not recoverable from the published report", "pp. 9-10", "The report provides seasonal descriptions only; do not treat downstream timing approximations as source inputs."),
  add_assumption("biology", "maturity", "Annual maturity-at-age from RV sampling", "Table A-9"),
  add_assumption("biology", "stock_weight", "Beginning-of-year stock weights estimated from bias-corrected RV weights", "pp. 9-10; Table A-10"),
  add_assumption("biology", "catch_weight", "Catch weights-at-age from commercial sampling", "p. 10; Table A-11"),
  add_assumption("model_availability", "native_run", "unknown", "Source search through 2026-10-19", "No public applied HYBRID executable, parameter file, or full machine-readable fit object was found; figures and selected summary statistics are available."),
  add_assumption("model_availability", "estimated_output_coverage", "partial", "DFO Science Advisory Report 2025/007, Table 1; DFO Research Document 2026/051, pp. 11-12", "Annual aggregate SSB, age-2 recruitment, and mean F/M for ages 5-8 are available for 2020-2024. The 2024 intervals and 2025 SSB projection are reported in 2026/051. Full numerical N/F/M age-by-year trajectories and uncertainty are not tabulated.")
))

summary_years <- 2020:2024
summary_outputs <- function(type, measure, values, lower = rep(NA_real_, 5),
                            upper = rep(NA_real_, 5), age = NA_real_,
                            age_group = "", unit, notes) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = summary_years, age = age, age_group = age_group,
    value = values, se = NA_real_, lwr = lower, upr = upper, unit = unit,
    source_type = "official_document",
    source_reference = paste0("DFO Science Advisory Report 2025/007, Table 1; ", summary_url),
    notes = notes, stringsAsFactors = FALSE
  )
}
output_rows <- rbind(
  summary_outputs(
    "biomass", "SSB", c(27.6, 26.7, 27.4, 27.7, 29.9),
    c(22.7, 22.6, 23.2, 23.1, 24.0), c(33.5, 31.6, 32.4, 33.3, 37.3),
    unit = "kt", notes = "Annual SSB estimate and reported 95% confidence interval. 2024 also reported in Research Document 2026/051, p. 11."
  ),
  summary_outputs(
    "population", "recruitment", c(17.4, 20.0, 34.3, 36.8, 36.6),
    c(10.9, 12.3, 19.4, 17.0, 14.3), c(27.9, 32.4, 60.6, 79.8, 93.3),
    age = 2, unit = "million fish",
    notes = "Age-2 recruitment estimate and reported 95% confidence interval. 2024 also reported in Research Document 2026/051, p. 11."
  ),
  summary_outputs(
    "mortality", "Fbar", c(0.04, 0.02, 0.03, 0.03, 0.04),
    lower = c(NA, NA, NA, NA, 0.03), upper = c(NA, NA, NA, NA, 0.06),
    unit = "per year", age_group = "5-8",
    notes = "Reported average F for ages 5-8; not age-specific. The 2024 estimate and 95% confidence interval are reported in Research Document 2026/051, p. 11."
  ),
  summary_outputs(
    "mortality", "Mbar", c(0.37, 0.35, 0.35, 0.35, 0.32),
    lower = c(NA, NA, NA, NA, 0.31), upper = c(NA, NA, NA, NA, 0.34),
    unit = "per year", age_group = "5-8",
    notes = "Reported population-weighted average M for ages 5-8; not age-specific. The 2024 estimate and 95% confidence interval are reported in Research Document 2026/051, p. 11."
  ),
  data.frame(
    assessment_id = assessment_id, type = "biomass", measure = "SSB",
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = 2025, age = NA_real_, age_group = "", value = 33.2, se = NA_real_,
    lwr = 26.4, upr = 41.8, unit = "kt", source_type = "official_document",
    source_reference = "DFO Research Document 2026/051, p. 11",
    notes = "Beginning-of-year 2025 projected SSB under the stated 1,550 t catch; reported 95% confidence interval.",
    stringsAsFactors = FALSE
  )
)
output_rows$lwr[output_rows$year < 2024 & output_rows$measure %in% c("Fbar", "Mbar")] <- NA_real_
output_rows$upr[output_rows$year < 2024 & output_rows$measure %in% c("Fbar", "Mbar")] <- NA_real_

read_csv <- function(name) read.csv(file.path(db, name), stringsAsFactors = FALSE, check.names = FALSE)
write_csv <- function(x, name) {
  path <- file.path(db, name)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (name == "stocks.csv") {
    id <- "ck_dfo_morhua_3ps"
    row <- x[x$stock_id == id, , drop = FALSE]
    if (nrow(row) != 1L) abort("Expected one stock row for ", id, ".")
    pattern <- paste0('^"?', id, '"?,')
    index <- grep(pattern, lines)
    if (length(index) != 1L) abort("Expected one existing stock row for ", id, ".")
    temp <- tempfile(fileext = ".csv")
    on.exit(unlink(temp), add = TRUE)
    write.csv(row, temp, row.names = FALSE, na = "")
    lines[[index]] <- readLines(temp, warn = FALSE, encoding = "UTF-8")[[2L]]
  } else {
    rows <- x[x$assessment_id == assessment_id, , drop = FALSE]
    if (!nrow(rows)) abort("No rows to write for ", assessment_id, " in ", name, ".")
    pattern <- paste0('^"?', assessment_id, '"?,')
    lines <- c(lines[1L], lines[-1L][!grepl(pattern, lines[-1L])])
    temp <- tempfile(fileext = ".csv")
    on.exit(unlink(temp), add = TRUE)
    write.csv(rows, temp, row.names = FALSE, na = "")
    lines <- c(lines, readLines(temp, warn = FALSE, encoding = "UTF-8")[-1L])
  }
  writeLines(lines, path, useBytes = TRUE)
}

stocks <- read_csv("stocks.csv")
stock_index <- which(stocks$stock_id == "ck_dfo_morhua_3ps")
if (length(stock_index) != 1L) abort("Expected exactly one Charbonneau–Keith 3Ps cod stock row.")
stocks$authority_stock_id[stock_index] <- "3Ps"
stocks$common_name[stock_index] <- "Atlantic cod"
stocks$notes[stock_index] <- paste(
  "DFO NAFO Subdivision 3Ps Atlantic cod. Assessment identity verified against DFO Research Document 2026/051.",
  "Charbonneau-Keith Master.csv identifier DFO_morhua_3PS retained."
)

assessments <- read_csv("assessments.csv")
assumptions <- read_csv("assumptions.csv")
inputs_old <- read_csv("inputs.csv")
outputs <- read_csv("outputs.csv")
assessments <- assessments[assessments$assessment_id != assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id != assessment_id, , drop = FALSE]
inputs_old <- inputs_old[inputs_old$assessment_id != assessment_id, , drop = FALSE]
outputs <- outputs[outputs$assessment_id != assessment_id, , drop = FALSE]

assessments <- rbind(assessments, new_assessment)
assumptions <- rbind(assumptions, assumption_rows)
inputs <- rbind(inputs_old, inputs)
outputs <- rbind(outputs, output_rows)
write_csv(stocks, "stocks.csv")
write_csv(assessments, "assessments.csv")
write_csv(assumptions, "assumptions.csv")
write_csv(inputs, "inputs.csv")
write_csv(outputs, "outputs.csv")

cat("Imported ", nrow(inputs) - nrow(inputs_old), " input rows for ", assessment_id, "\n", sep = "")














