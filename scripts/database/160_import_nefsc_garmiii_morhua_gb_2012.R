base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_nefsc_garmiii_morhua_gb_2012")
stock_id <- "ck_nefsc_garmiii_morhua_gb"
assessment_id <- "nefsc_garmiii_gb_cod_2012"
report_url <- "https://repository.library.noaa.gov/view/noaa/4432/noaa_4432_DS1.pdf"
summary_url <- "https://repository.library.noaa.gov/view/noaa/4330/noaa_4330_DS1.pdf"
report_path <- file.path(cache, "SAW55_report_2013.pdf")
report_sha <- "549582645c201d844aa9a1ec5b9c3ec561c9d53132fb7f29f03b939758534824"

assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

assert(file.exists(report_path), "Cache the SAW55 assessment report before importing.")
assert(requireNamespace("digest", quietly = TRUE), "Package `digest` is required.")
assert(requireNamespace("pdftools", quietly = TRUE), "Package `pdftools` is required.")
report_checksum <- digest::digest(readBin(report_path, "raw", n = file.info(report_path)$size),
  algo = "sha256", serialize = FALSE)
assert(identical(tolower(report_checksum), report_sha),
  "The cached SAW55 report checksum does not match the verified source.")

report <- pdftools::pdf_text(report_path)
assert(length(report) == 849L, "Unexpected page count in the cached SAW55 report.")

## Source tables ----

years <- 1978:2011
ages <- 1:10
dfo_years <- c(1986:1992, 1995:2004, 2006:2011)

as_number <- function(x) {
  x[x %in% c("", "-", "–", "—")] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

year_rows <- function(page, years, n_values) {
  lines <- strsplit(report[[page]], "\n", fixed = TRUE)[[1L]]
  lines <- lines[grepl("^\\s*\\*{0,2}(19|20)[0-9]{2}\\s+", lines)]
  rows <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(line), "\\s+")[[1L]]
    year <- as.integer(sub("^\\*+", "", tokens[[1L]]))
    if (!year %in% years) return(NULL)
    values <- as_number(tokens[-1L])
    assert(length(values) == n_values,
      paste0("Unexpected table width on PDF page ", page, ", year ", year, "."))
    c(year, values)
  })
  rows <- Filter(Negate(is.null), rows)
  found <- as.integer(vapply(rows, `[[`, numeric(1), 1L))
  assert(identical(found, as.integer(years)),
    paste0("Incomplete source year coverage on PDF page ", page, "."))
  out <- do.call(rbind, rows)
  colnames(out) <- c("year", paste0("v", seq_len(n_values)))
  out
}

age_surface <- function(page, start, end = NULL) {
  lines <- strsplit(report[[page]], "\n", fixed = TRUE)[[1L]]
  first <- grep(start, lines, fixed = TRUE)[1L]
  last <- if (is.null(end)) length(lines) else grep(end, lines, fixed = TRUE)[1L] - 1L
  assert(!is.na(first) && last > first,
    paste0("Could not locate age surface on PDF page ", page, "."))
  current_years <- NULL
  ages_out <- list()
  totals_out <- list()
  for (line in lines[first:last]) {
    tokens <- strsplit(trimws(line), "\\s+")[[1L]]
    if (!length(tokens)) next
    if (length(tokens) > 1L && all(grepl("^(19|20)[0-9]{2}$", tokens))) {
      current_years <- as.integer(tokens)
      next
    }
    if (is.null(current_years)) next
    values <- as_number(tokens[-1L])
    if (length(values) != length(current_years)) next
    if (tokens[[1L]] == "Total") {
      totals_out[[length(totals_out) + 1L]] <- data.frame(
        year = current_years, value = values
      )
      next
    }
    if (!grepl("^(10\\+|[0-9]+)$", tokens[[1L]])) next
    age <- if (tokens[[1L]] == "10+") 10L else as.integer(tokens[[1L]])
    ages_out[[length(ages_out) + 1L]] <- data.frame(
      year = current_years, age = age, value = values
    )
  }
  list(age = do.call(rbind, ages_out), total = do.call(rbind, totals_out))
}

catch_numbers <- year_rows(726L, years, 11L)
catch_biomass <- year_rows(727L, years, 11L)
catch_weight <- year_rows(728L, years, 11L)
survey_summary <- year_rows(731L, 1977:2011, 8L)
spring_at_age <- year_rows(732L, years, 12L)
autumn_at_age <- year_rows(733L, 1977:2011, 12L)
dfo_at_age <- year_rows(734L, dfo_years, 12L)
maturity <- year_rows(735L, years, 11L)
stock_weight <- year_rows(736L, years, 10L)
summary_outputs <- year_rows(744L, years, 4L)
n_surface <- age_surface(745L, "Stock Numbers", "Fishing Mortality")
f_surface <- age_surface(745L, "Fishing Mortality")
n_at_age <- n_surface$age
f_at_age <- f_surface$age

assert(nrow(n_at_age) == length(years) * length(ages) &&
  nrow(f_at_age) == length(years) * length(ages), "Incomplete N/F-at-age tables.")
assert(nrow(n_surface$total) == length(years), "Incomplete total-abundance table.")
assert(all(abs(vapply(years, function(y)
  sum(n_at_age$value[n_at_age$year == y]), numeric(1)) - n_surface$total$value) <= 3),
  "N-at-age sums do not match the printed total row within rounding.")
assert(all(summary_outputs[, 5L] == n_at_age$value[n_at_age$age == 1L]),
  "Recruitment does not match age-1 abundance in the source table.")
assert(all(abs(rowSums(catch_numbers[, 2:11, drop = FALSE]) - catch_numbers[, 12L]) <= 2),
  "Catch numbers-at-age do not match published totals within rounding.")
assert(all(abs(rowSums(catch_biomass[, 2:11, drop = FALSE]) - catch_biomass[, 12L]) <= 2),
  "Catch biomass-at-age does not match published totals within rounding.")

## Database records ----

read_table <- function(file) {
  read.csv(file.path(database, file), stringsAsFactors = FALSE, check.names = FALSE)
}

blank_rows <- function(template, n) template[rep(NA_integer_, n), , drop = FALSE]
reference <- function(table, printed_page) {
  paste0(report_url, "; Table ", table, ", printed page ", printed_page)
}

assessments <- read_table("assessments.csv")
assumptions_existing <- read_table("assumptions.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
assert(!assessment_id %in% assessments$assessment_id,
  paste0("Assessment ", assessment_id, " already exists; refusing to duplicate it."))
assert(stock_id %in% read_table("stocks.csv")$stock_id,
  paste0("Blank stock record ", stock_id, " is not in stocks.csv."))
assert(!any(inputs$assessment_id %in% assessments$assessment_id[assessments$stock_id == stock_id]) &&
  !any(outputs$assessment_id %in% assessments$assessment_id[assessments$stock_id == stock_id]),
  "This stock already has source inputs or outputs; refusing to overwrite prior work.")

region <- "Georges Bank and South (NAFO 5Z and Subarea 6)"
catch_fleet <- "Combined USA and Canadian fishery"
spring_41 <- "NEFSC spring bottom trawl (Yankee 41)"
spring_36 <- "NEFSC spring bottom trawl (Yankee 36)"
autumn_survey <- "NEFSC autumn bottom trawl"
dfo_survey <- "DFO February bottom trawl"

make_input <- function(n, type, measure, basis, unit, source_type, source_reference,
  year = NA_integer_, age = NA_integer_, fleet = "", survey = "", sex = "combined",
  season = "annual", value = NA_real_, sample_size = NA_real_, sampling_time = NA_real_,
  transformation = "", notes = "") {
  x <- blank_rows(inputs, n)
  x$assessment_id <- assessment_id; x$type <- type; x$measure <- measure
  x$basis <- basis; x$fleet <- fleet; x$survey <- survey; x$sex <- sex
  x$region <- region; x$season <- season; x$year <- year
  x$year_basis <- ifelse(is.na(year), "", "calendar_year")
  x$age <- age; x$value <- value; x$unit <- unit
  x$sampling_time <- sampling_time; x$source_type <- source_type
  x$source_reference <- source_reference; x$transformation <- transformation
  x$notes <- notes; x$sample_size <- sample_size
  x
}

expand_age <- function(tab, value_cols, age_values, type, measure, basis, unit,
  source_type, source_ref, sex = "combined", fleet = "", survey = "",
  season = "annual", timing = NA_real_, ess = NA_real_, notes = "", transformation = "") {
  years <- if (is.data.frame(tab)) tab$year else tab[, 1L]
  values <- as.matrix(tab[, value_cols, drop = FALSE])
  make_input(length(years) * length(age_values), type, measure, basis, unit,
    source_type, source_ref, year = rep(years, each = length(age_values)),
    age = rep(age_values, times = length(years)), sex = sex, fleet = fleet,
    survey = survey, season = season, value = as.vector(t(values)),
    sample_size = ess, sampling_time = timing, notes = notes,
    transformation = transformation)
}

input_rows <- list(
  expand_age(catch_numbers, 2:11, ages, "catch", "numbers_at_age", "numbers",
    "thousand fish", "official_table", reference("B12", 724), fleet = catch_fleet,
    ess = 64, notes = "Final Base ASAP catch-at-age for the combined USA/Canadian commercial and USA recreational fleet. Includes landings and discards; age 10 is the 10+ group."),
  make_input(34L, "catch", "total_biomass", "biomass", "tonnes", "official_table",
    reference("B12", 725), year = years, fleet = catch_fleet, value = catch_biomass[, 12L],
    notes = "Annual total catch biomass in metric tonnes."),
  make_input(34L, "catch", "relative_standard_error", "relative_scale", "ratio",
    "official_document", paste0(report_url, "; printed page 676"), year = years,
    fleet = catch_fleet, value = rep(0.05, length(years)),
    notes = "Assessment-assumed CV for total catch; not an empirical estimate."),
  expand_age(catch_weight, 2:11, ages, "catch_weight", "catch_weight_at_age",
    "kg_per_fish", "kg per fish", "official_table", reference("B12", 726),
    fleet = catch_fleet, notes = "Reported mean catch weight at age; age 10 is the 10+ group."),
  expand_age(stock_weight, 2:11, ages, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "official_table", reference("B17a", 734),
    notes = "January 1 stock weight at age; age 10 is the 10+ group."),
  expand_age(maturity, 2:11, ages, "maturity", "maturity_at_age", "proportion",
    "proportion", "official_table", reference("B16", 733), sex = "female",
    notes = "Female maturity ogive from a centered 5-year moving window; age 10 is the 10+ group."),
  make_input(10L, "M", "natural_mortality_at_age", "per_year", "year^-1",
    "official_document", paste0(report_url, "; printed pages 670-672"), age = ages,
    value = rep(0.2, length(ages)),
    notes = "Fixed M=0.2 year^-1 for every year and age. The age-varying Lorenzen alternative was not selected; age 10 is the 10+ group.")
)

spring_age_values <- spring_at_age[, 3:12, drop = FALSE]
spring_tab <- data.frame(year = spring_at_age[, 1L], spring_age_values)
names(spring_tab) <- c("year", paste0("age", ages))
spring_survey <- ifelse(spring_tab$year <= 1981, spring_41, spring_36)
spring_ess <- ifelse(spring_tab$year <= 1981, 40, 37)
for (survey_name in c(spring_41, spring_36)) {
  idx <- which(spring_survey == survey_name)
  input_rows[[length(input_rows) + 1L]] <- expand_age(
    spring_tab[idx, , drop = FALSE], 2:11, ages, "index", "numbers_at_age",
    "numbers", "fish per tow", "official_table", reference("B15a", 730),
    survey = survey_name, season = "spring", timing = 0.25,
    ess = unique(spring_ess[idx]),
    notes = "Standardized NEFSC spring age-specific abundance index. Source age 0 is excluded; age 10 is the 10+ group. The series is split at the Yankee 41/36 gear change."
  )
}

autumn_age_values <- autumn_at_age[, 2:7, drop = FALSE]
input_rows[[length(input_rows) + 1L]] <- expand_age(
  data.frame(year = autumn_at_age[, 1L], autumn_age_values), 2:7, 0:5,
  "index", "numbers_at_age", "numbers", "fish per tow", "official_table",
  reference("B15b", 731), survey = autumn_survey, season = "autumn", timing = 0.75,
  ess = 14,
  notes = "Standardized NEFSC autumn index retained at the observed year and age. In the source model, ages 0-5 are advanced one age and one year to align cohorts with January population states."
)

dfo_age_values <- dfo_at_age[, 2:11, drop = FALSE]
input_rows[[length(input_rows) + 1L]] <- expand_age(
  data.frame(year = dfo_at_age[, 1L], dfo_age_values), 2:11, ages,
  "index", "numbers_at_age", "numbers", "fish per tow", "official_table",
  reference("B15c", 732), survey = dfo_survey, season = "February", timing = 0.16,
  ess = 9,
  notes = "DFO February survey. 1993, 1994 and 2012 were not used because the full Georges Bank area was not surveyed; the 2005 R/V Teleost series is excluded because the R/V Needler index was unavailable. Source dashes remain missing; age 10 is the 10+ group."
)

make_index_summary <- function(year, total, raw_cv, survey, season, timing,
  cv_scale, add_cv, source_ref) {
  use <- which(is.finite(total) & is.finite(raw_cv))
  raw_cv <- raw_cv[use] * cv_scale
  total_rows <- make_input(length(use), "index", "total_numbers", "numbers",
    "fish per tow", "official_table", source_ref, year = year[use], survey = survey,
    season = season, value = total[use], sampling_time = timing,
    notes = "Reported aggregate survey abundance index, retained alongside the age-specific index data.")
  cv_rows <- make_input(length(use), "index", "abundance_index_cv", "relative_scale",
    "ratio", "reconstructed_source_input", source_ref, year = year[use],
    survey = survey, season = season, value = raw_cv + add_cv,
    sampling_time = timing,
    transformation = paste0("reported CV", if (cv_scale == 0.01) " (%) / 100" else " (ratio)",
      " + ", add_cv),
    notes = paste0("Reported CV before the model adjustment: ",
      format(100 * raw_cv, trim = TRUE), "%; the assessment adds ", add_cv,
      " to the annual CV vector."))
  list(total = total_rows, cv = cv_rows)
}

spring_summary <- data.frame(year = survey_summary[, 1L],
  total = survey_summary[, 2L], cv = survey_summary[, 3L])
autumn_summary <- data.frame(year = survey_summary[, 1L],
  total = survey_summary[, 6L], cv = survey_summary[, 7L])
for (survey_name in c(spring_41, spring_36)) {
  selected_years <- if (survey_name == spring_41) 1978:1981 else 1982:2011
  block <- spring_summary[spring_summary$year %in% selected_years, , drop = FALSE]
  rows <- make_index_summary(block$year, block$total, block$cv, survey_name,
    "spring", 0.25, 0.01, 0.2, reference("B14", 729))
  input_rows[[length(input_rows) + 1L]] <- rows$total
  input_rows[[length(input_rows) + 1L]] <- rows$cv
}
rows <- make_index_summary(autumn_summary$year, autumn_summary$total,
  autumn_summary$cv, autumn_survey, "autumn", 0.75, 0.01, 0.2,
  reference("B14", 729))
input_rows[[length(input_rows) + 1L]] <- rows$total
input_rows[[length(input_rows) + 1L]] <- rows$cv

dfo_summary <- data.frame(year = dfo_at_age[, 1L], total = dfo_at_age[, 12L],
  cv = dfo_at_age[, 13L])
rows <- make_index_summary(dfo_summary$year, dfo_summary$total,
  dfo_summary$cv, dfo_survey, "February", 0.16, 1, 0.1,
  reference("B15c", 732))
input_rows[[length(input_rows) + 1L]] <- rows$total
input_rows[[length(input_rows) + 1L]] <- rows$cv

new_inputs <- do.call(rbind, input_rows)

make_output <- function(n, type, measure, values, unit, source_type, source_ref,
  year, age = NA_integer_, age_group = "", lwr = NA_real_, upr = NA_real_, notes = "") {
  x <- blank_rows(outputs, n)
  x$assessment_id <- assessment_id; x$type <- type; x$measure <- measure
  x$year <- year; x$age <- age; x$age_group <- age_group; x$value <- values
  x$sex <- "combined"; x$region <- region; x$season <- "annual"
  x$unit <- unit; x$source_type <- source_type; x$source_reference <- source_ref
  x$lwr <- lwr; x$upr <- upr; x$notes <- notes
  x
}

make_surface_output <- function(surface, type, measure, unit, source_ref, notes) {
  make_output(nrow(surface), type, measure, surface$value, unit, "official_table",
    source_ref, surface$year, surface$age,
    age_group = ifelse(surface$age == 10L, "10+", ""), notes = notes)
}

output_rows <- list(
  make_surface_output(n_at_age, "population", "numbers_at_age", "thousand fish",
    reference("B23b", 743), "January 1 abundance; age 10 is the 10+ group."),
  make_surface_output(f_at_age, "mortality", "fishing_mortality_at_age", "year^-1",
    reference("B23b", 743), "Instantaneous fishing mortality; age 10 is the 10+ group."),
  make_output(length(years), "population", "total_abundance", n_surface$total$value,
    "thousand fish", "official_table", reference("B23b", 743), years,
    notes = "Reported total row from Table B23b. The printed total may differ by up to three thousand fish from the sum of separately rounded age-specific values."),
  make_output(length(years), "biomass", "january_1_biomass", summary_outputs[, 2L],
    "tonnes", "official_table", reference("B23a", 742), years,
    notes = "Reported January 1 total biomass."),
  make_output(length(years), "biomass", "SSB", summary_outputs[, 3L], "tonnes",
    "official_table", reference("B23a", 742), years,
    notes = "Reported unadjusted spawning stock biomass."),
  make_output(length(years), "mortality", "Fbar", summary_outputs[, 4L], "year^-1",
    "official_table", reference("B23a", 742), years, age_group = "ages 5-8",
    notes = "Reported unweighted average F. Table B23a labels ages 5-8; elsewhere the report describes fully recruited F as ages 5+."),
  make_output(length(years), "recruitment", "recruitment", summary_outputs[, 5L],
    "thousand fish", "official_table", reference("B23a", 742), years, age = 1L,
    notes = "Reported age-1 recruitment, not adjusted for retrospective bias.")
)

output_rows[[length(output_rows) + 1L]] <- make_output(1L, "biomass",
  "SSB_rho_adjusted", 13216, "tonnes", "official_document",
  paste0(report_url, "; printed page 678"), 2011,
  notes = "2011 terminal status after the seven-year retrospective adjustment; distinct from the unadjusted annual series. No adjusted-estimate interval was reported.")
output_rows[[length(output_rows) + 1L]] <- make_output(1L, "mortality",
  "Ffull_rho_adjusted", 0.43, "year^-1", "official_document",
  paste0(report_url, "; printed page 678"), 2011, age_group = "ages 5+",
  notes = "2011 fully recruited F after the seven-year retrospective adjustment; distinct from the unadjusted annual series. No adjusted-estimate interval was reported.")
output_rows[[length(output_rows) + 1L]] <- make_output(1L, "recruitment",
  "recruitment_rho_adjusted", 5131, "thousand fish", "official_document",
  paste0(report_url, "; printed page 678"), 2011, age = 1L,
  notes = "2011 age-1 recruitment after the retrospective adjustment (the 2010 year class), reported as 5.131 million fish.")

new_outputs <- do.call(rbind, output_rows)
ssb_2011 <- new_outputs$measure == "SSB" & new_outputs$year == 2011L
fbar_2011 <- new_outputs$measure == "Fbar" & new_outputs$year == 2011L
new_outputs$lwr[ssb_2011] <- 15809; new_outputs$upr[ssb_2011] <- 31993
new_outputs$lwr[fbar_2011] <- 0.15; new_outputs$upr[fbar_2011] <- 0.34
new_outputs$notes[ssb_2011 | fbar_2011] <- paste(
  new_outputs$notes[ssb_2011 | fbar_2011],
  "Published 90% MCMC probability interval; no SE is reconstructed.")

assessment <- blank_rows(assessments, 1L)
assessment$assessment_id <- assessment_id; assessment$stock_id <- stock_id
assessment$assessment_year <- 2012L; assessment$terminal_year <- 2011L
assessment$estimate_terminal_year <- 2011L; assessment$assessment_type <- "benchmark"
assessment$model_family <- "ASAP"; assessment$model_version <- "SAW55 Base ASAP v3.0.6"
assessment$is_current <- TRUE; assessment$is_applied <- TRUE
assessment$framework_year <- 2012L; assessment$assessment_url <- report_url
assessment$framework_url <- report_url; assessment$assumptions_status <- "partial"
assessment$inputs_status <- "complete"; assessment$outputs_status <- "partial"
assessment$notes <- paste0("Published in 2013. The selected SAW55 Base ASAP benchmark covers the historical Georges Bank and South unit (NAFO 5Z and Subarea 6), not the revised 2023 Georges Bank stock definition represented by nefsc_cod_georges_bank. The 2015 operational update is not mixed into this record.")

make_assumption <- function(component, setting, value, source_reference, notes = "",
  survey = "", fleet = "", sex = "combined", season = "") {
  x <- blank_rows(assumptions_existing, 1L)
  x$assessment_id <- assessment_id; x$component <- component; x$fleet <- fleet
  x$survey <- survey; x$sex <- sex; x$region <- region; x$season <- season
  x$setting <- setting; x$value <- value; x$source_reference <- source_reference
  x$notes <- notes
  x
}

assumptions <- do.call(rbind, list(
  make_assumption("population", "model_period", "1978-2011; ages 1-10+", report_url,
    "The reported age-10 group is 10+; terminal estimate year is 2011."),
  make_assumption("population", "stock_definition", "Georges Bank and South; NAFO 5Z and Subarea 6", reference("B12", 724),
    "The historical wider unit is retained. Do not copy data from the revised 2023 Georges Bank stock."),
  make_assumption("assessment", "official_model", "SAW55 selected Base ASAP benchmark", report_url,
    "The report identifies the Base ASAP configuration as the final selected model."),
  make_assumption("catch", "catch_structure", "One combined fishery; USA and Canadian landings and discards, plus USA recreational landings and discards", reference("B12", 724),
    "The published final catch series includes recreational equivalents and discard-mortality adjustments."),
  make_assumption("catch", "total_catch_cv", "0.05", paste0(report_url, "; printed page 676"),
    "Assumed annual CV for total catch biomass."),
  make_assumption("catch", "catch_age_likelihood", "Multinomial; ESS 64", paste0(report_url, "; printed pages 675-676")),
  make_assumption("catch", "fishery_selectivity", "Two time blocks: 1978-1993 and 1994-2011", paste0(report_url, "; printed page 676"),
    "The two-block formulation was selected as more parsimonious than four blocks."),
  make_assumption("index", "survey_likelihood", "Lognormal total index and multinomial age composition", paste0(report_url, "; printed pages 674-679")),
  make_assumption("index", "survey_cv_adjustments", "NEFSC spring +0.20; NEFSC autumn +0.20; DFO +0.10", paste0(report_url, "; printed page 677"),
    "Imported annual CVs are reconstructed from reported CVs plus the assessment adjustments."),
  make_assumption("index", "survey_effective_sample_sizes", "DFO=9; NEFSC autumn=14; NEFSC spring Yankee 41=40; NEFSC spring Yankee 36=37", paste0(report_url, "; printed page 677")),
  make_assumption("index", "spring_survey_series", "Yankee 41: 1978-1981; Yankee 36: 1982-2011", paste0(report_url, "; printed pages 673 and 675"), survey = "NEFSC spring"),
  make_assumption("index", "autumn_cohort_alignment", "Advance observed age and year by one", paste0(report_url, "; printed page 675"),
    "The canonical input table preserves observed years 1977-2011 and ages 0-5; the source model shifts them to the following January population state.", survey = autumn_survey),
  make_assumption("index", "survey_selectivity", "Spring and DFO logistic; autumn age-specific with age 3 fixed at 1", paste0(report_url, "; printed pages 675-676"),
    "Full parameter phases are not available from the report."),
  make_assumption("index", "sampling_time", "0.25", paste0(report_url, "; printed page 668"), survey = spring_41, season = "spring"),
  make_assumption("index", "sampling_time", "0.25", paste0(report_url, "; printed page 668"), survey = spring_36, season = "spring"),
  make_assumption("index", "sampling_time", "0.75", paste0(report_url, "; printed page 668"), survey = autumn_survey, season = "autumn"),
  make_assumption("index", "sampling_time", "0.16", paste0(report_url, "; printed page 668"), survey = dfo_survey, season = "February"),
  make_assumption("biology", "natural_mortality", "Fixed M=0.2 year^-1 across ages and years", paste0(report_url, "; printed pages 670-672"),
    "The age-varying Lorenzen M option was not selected."),
  make_assumption("biology", "maturity", "Female ogives; centered 5-year moving window", reference("B16", 733)),
  make_assumption("biology", "stock_weight", "January 1 stock weight at age", reference("B17a", 734)),
  make_assumption("population", "recruitment_process", "Lognormal recruitment deviations constrained to sum to zero; lambda=0", paste0(report_url, "; printed page 676"),
    "The deviations do not contribute to the objective function."),
  make_assumption("assessment", "retrospective_adjustment", "Seven-year average rho applied to terminal SSB, F and recruitment", paste0(report_url, "; printed page 678"),
    "Adjusted terminal status values are stored separately from the annual unadjusted estimates."),
  make_assumption("assessment", "later_assessment_context", "2015 operational update not used in this record", "https://repository.library.noaa.gov/view/noaa/5293/noaa_5293_DS1.pdf",
    "The 2015 peer-review discussion is contextual; its later results are not assigned to this historical 2012 benchmark."),
  make_assumption("assessment", "configuration_limit", "Exact q parameters, optimizer phases and full uncertainty arrays unavailable", report_url,
    "The published tables support source inputs and selected output surfaces, but not a complete model configuration or all parameter uncertainty.")
))

## Validate and write ----

assert(nrow(new_inputs) == 2402L, "Unexpected number of reconstructed input rows.")
assert(nrow(new_outputs) == 853L, "Unexpected number of extracted output rows.")
input_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "partition")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "age_group")
assert(!anyDuplicated(new_inputs[input_key]), "Duplicate input keys in extracted tables.")
assert(!anyDuplicated(new_outputs[output_key]), "Duplicate output keys in extracted tables.")
assert(all(is.finite(new_outputs$value)), "A non-finite assessment output was extracted.")
assert(sum(is.na(new_inputs$value)) == 5L, "Unexpected missing-value pattern in source observations.")

write.csv(rbind(assessments, assessment), file.path(database, "assessments.csv"), row.names = FALSE, na = "")
write.csv(rbind(assumptions_existing, assumptions), file.path(database, "assumptions.csv"), row.names = FALSE, na = "")
write.csv(rbind(inputs, new_inputs), file.path(database, "inputs.csv"), row.names = FALSE, na = "")
write.csv(rbind(outputs, new_outputs), file.path(database, "outputs.csv"), row.names = FALSE, na = "")
