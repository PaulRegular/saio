root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
db_dir <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_ices_wghansa_trachurus_sp9a")
stock_id <- "ck_ices_wghansa_trachurus_sp9a"
id24 <- "ices_horse_mackerel_9a_2024"
id26 <- "ices_horse_mackerel_9a_2026"
abort <- function(...) stop(paste0(...), call. = FALSE)

report_text <- file.path(cache, "WGHANSA_2024v2.txt")
sag_html <- file.path(cache, "ICES_SAG_2026_source.html")
if (!file.exists(report_text) || !file.exists(sag_html)) {
  abort("Cached WGHANSA report text and ICES SAG source table are required.")
}

table_rows <- function(heading, n_value, years) {
  lines <- readLines(report_text, warn = FALSE, encoding = "UTF-8")
  start <- grep(heading, lines, fixed = TRUE)
  if (length(start) != 1L) abort("Expected one table heading: ", heading)
  rows <- list()
  for (line in lines[seq.int(start + 1L, length(lines))]) {
    fields <- regmatches(line, regexec(
      "^\\s*(\\d{4})[[:punct:]]?\\s+(.+?)\\s*$", line, perl = TRUE
    ))[[1L]]
    if (!length(fields)) next
    year <- as.integer(fields[[2L]])
    if (!year %in% years) next
    x <- strsplit(trimws(fields[[3L]]), "\\s+", perl = TRUE)[[1L]]
    x <- x[!x %in% c("*", "^", "†")]
    x <- gsub("[*^†]", "", x)
    if (length(x) != n_value) next
    numeric_x <- suppressWarnings(as.numeric(x))
    if (any(is.na(numeric_x) & toupper(x) != "NA")) {
      abort("Could not parse table row for year ", year, ": ", heading)
    }
    rows[[length(rows) + 1L]] <- c(year, numeric_x)
    if (length(rows) == length(years)) break
  }
  if (length(rows) != length(years)) abort("Incomplete table: ", heading)
  out <- do.call(rbind, rows)
  if (!identical(as.integer(out[, 1L]), as.integer(years))) {
    abort("Unexpected year coverage in table: ", heading)
  }
  out
}

years <- 1992:2023
ages <- 0:11
catch <- table_rows("Table 5.2.4.1. Southern horse mackerel catch-at-age data", 12L, years)
weight <- table_rows("Table 5.2.5.1. Southern horse mackerel mean weight-at-age", 12L, years)
ibts <- table_rows("Table 5.3.1.2. Southern horse mackerel. Stratified mean abundance-at-age", 12L, years)
annual <- table_rows("Table 5.4.1.2 Southern horse mackerel final assessment", 8L, years)

html <- xml2::read_html(sag_html)
label <- function(id) {
  node <- xml2::xml_find_first(html, paste0("//*[@id='", id, "']"))
  if (inherits(node, "xml_missing")) NA_character_ else xml2::xml_text(node)
}
if (!requireNamespace("rvest", quietly = TRUE)) abort("Install rvest to parse the cached ICES SAG table.")
if (!identical(label("lblStockCode"), "hom.27.9a") ||
    !identical(label("lblKey"), "23760") || !identical(label("lblYear"), "2026") ||
    !identical(label("lblStockSizeUnits"), "tonnes") ||
    !identical(label("lblRecruitmentAge"), "0") || !identical(label("lblFAge"), "1-10")) {
  abort("Cached ICES SAG metadata no longer matches the reviewed stock and series.")
}
columns <- c("Year", "Low Recruitment", "Recruitment", "High Recruitment",
  "Low TBiomass", "TBiomass", "High TBiomass", "Low SSB", "SSB",
  "High SSB", "Landings", "Catches", "Low F", "F", "High F")
tables <- rvest::html_table(html, fill = TRUE)
found <- vapply(tables, function(x) all(columns %in% names(x)), logical(1))
if (sum(found) != 1L) abort("Could not identify one ICES SAG source-data table.")
sag <- as.data.frame(tables[[which(found)]], stringsAsFactors = FALSE)
sag$Year <- as.integer(sag$Year)
sag <- sag[order(sag$Year), , drop = FALSE]
if (!identical(sag$Year, 1992:2026)) abort("Unexpected year coverage in ICES SAG table.")

make_input <- function(id, type, measure, basis, value, unit, year = NA_real_,
                       age = NA_real_, fleet = "", survey = "", sex = "",
                       sampling_time = NA_real_, source_reference,
                       transformation = "Copied from the cited official source.", notes = "") {
  n <- length(value)
  rep_n <- function(x) rep_len(x, n)
  year <- rep_n(year)
  data.frame(
    assessment_id = rep_n(id), type = rep_n(type), measure = rep_n(measure),
    basis = rep_n(basis), fleet = rep_n(fleet), survey = rep_n(survey),
    sex = rep_n(sex), region = NA_character_, season = NA_character_, year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"), age = rep_n(age),
    value = as.numeric(value), unit = rep_n(unit), sampling_time = as.numeric(rep_n(sampling_time)),
    source_type = "official_table", source_reference = rep_n(source_reference),
    transformation = rep_n(transformation), notes = rep_n(notes),
    observation_id = NA_character_, length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_character_,
    partition = NA_character_, stringsAsFactors = FALSE, check.names = FALSE
  )
}

make_output <- function(id, type, measure, year, value, unit, age = NA_real_,
                        age_group = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        source_reference, notes = "") {
  n <- length(value)
  rep_n <- function(x) rep_len(x, n)
  data.frame(
    assessment_id = id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = rep_n(year),
    age = rep_n(age), age_group = rep_n(age_group), value = as.numeric(value),
    se = as.numeric(rep_n(se)), lwr = as.numeric(rep_n(lwr)), upr = as.numeric(rep_n(upr)),
    unit = unit, source_type = "official_table", source_reference = rep_n(source_reference),
    notes = rep_n(notes), stringsAsFactors = FALSE, check.names = FALSE
  )
}

make_assumption <- function(component, setting, value, reference) {
  data.frame(
    assessment_id = id24, component = component, fleet = NA_character_,
    survey = NA_character_, sex = NA_character_, region = NA_character_,
    season = NA_character_, setting = setting, value = as.character(value),
    source_reference = reference, notes = "", stringsAsFactors = FALSE
  )
}

age_input <- function(values, type, measure, basis, unit, reference, notes, sex = "") {
  make_input(id24, type, measure, basis, as.vector(t(values[, -1L, drop = FALSE])), unit,
    year = rep(years, each = length(ages)), age = rep(ages, times = length(years)),
    sex = sex, source_reference = reference,
    transformation = "Transcribed from the reported year-by-age table without rescaling.", notes = notes)
}

ibts_years <- ibts[, 1L][rowSums(is.na(ibts[, -1L, drop = FALSE])) == 0L]
ibts_values <- ibts[ibts[, 1L] %in% ibts_years, , drop = FALSE]
ibts_grid <- expand.grid(age = ages, year = ibts_years)
inputs24 <- list(
  age_input(catch, "catch", "numbers_at_age", "numbers", "thousand fish",
    "WGHANSA 2024, Table 5.2.4.1, pp. 221-222", "Combined Spanish and Portuguese catch; age 11 is 11+."),
  age_input(weight, "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "WGHANSA 2024, Table 5.2.5.1, pp. 230-231", "Catch weight-at-age."),
  age_input(weight, "weight", "weight_at_age", "kg_per_fish", "kg per fish",
    "WGHANSA 2024, Table 5.2.5.1 and Table 5.4.1.1, pp. 230-231, 242",
    "The assessment settings state that stock weights equal catch weights."),
  make_input(id24, "index", "numbers_at_age", "numbers",
    as.vector(t(ibts_values[, -1L, drop = FALSE])), "number per hour",
    year = ibts_grid$year, age = ibts_grid$age, survey = "Portuguese-Spanish IBTS",
    sampling_time = 0.8, source_reference = "WGHANSA 2024, Table 5.3.1.2, pp. 236-237",
    transformation = "Transcribed stratified mean abundance-at-age without rescaling.",
    notes = "Table ages 0-11+ are retained; the assessment uses ages 1-11+. Timing 0.8 is the October midpoint approximation. No combined index was estimated in 2012, 2019, or 2020."),
  make_input(id24, "catch", "total_biomass", "biomass", annual[, 9L], "tonnes",
    year = years, fleet = "Combined Spanish and Portuguese catch",
    source_reference = "WGHANSA 2024, Table 5.4.1.2, pp. 242-243",
    notes = "Official input-catch totals retained alongside catch-at-age; not passed as a second catch series in tinyAM."),
  make_input(id24, "index", "total_biomass", "biomass", c(52.91, 148.81, 185.49, 75.26),
    "thousand tonnes", year = c(2013L, 2016L, 2019L, 2022L), survey = "BIOMAN DEPM egg survey",
    source_reference = "WGHANSA 2024, Table 5.3.2.1, p. 239",
    notes = "Triennial DEPM spawning-stock biomass series; 2010 SSB was not estimated."),
  make_input(id24, "index", "relative_standard_error", "relative_scale", c(.371, .426, .482, .380),
    "coefficient of variation", year = c(2013L, 2016L, 2019L, 2022L),
    survey = "BIOMAN DEPM egg survey",
    source_reference = "WGHANSA 2024, Table 5.3.2.1, p. 239",
    transformation = "Converted reported percentage CV to a ratio by dividing by 100.",
    notes = "Observed DEPM estimate CV; the assessment assigns a separate nominal data-weight CV of 0.40."),
  make_input(id24, "M", "natural_mortality_at_age", "per_year",
    c(.62, .45, .35, .29, .25, .22, .20, .18, .17, .16, .15, .14), "per year",
    age = ages, source_reference = "WGHANSA 2024, section 5.3.5, p. 239",
    notes = "Fixed age-specific M derived by the Gislason method at WKBHMB; age 11 is 11+."),
  make_input(id24, "maturity", "maturity_at_age", "proportion",
    c(0, .12, .39, .76, .93, .99, 1, 1, 1, 1, 1, 1), "proportion",
    age = ages, sex = "female", source_reference = "WGHANSA 2024, section 5.3.4, p. 239",
    notes = "Time-invariant female ogive used for the combined-sex assessment; age 11 is 11+.")
)
inputs24 <- do.call(rbind, inputs24)

yr <- as.integer(annual[, 1L])
ssb <- annual[, 2L]; cv_ssb <- annual[, 3L]
rec <- annual[, 4L]; cv_rec <- annual[, 5L]
fbar <- annual[, 6L]; cv_fbar <- annual[, 7L]
fapical <- annual[, 8L]
ref24 <- "WGHANSA 2024, Table 5.4.1.2, pp. 242-243"
se_note <- "SE is estimate multiplied by the reported CV; the source table does not give confidence limits."
outputs24 <- rbind(
  make_output(id24, "biomass", "SSB", yr, ssb, "tonnes", se = ssb * cv_ssb,
    source_reference = ref24, notes = se_note),
  make_output(id24, "recruitment", "recruitment", yr, rec, "thousand fish", age = 0,
    se = rec * cv_rec, source_reference = ref24, notes = paste(se_note, "Recruitment age is 0.")),
  make_output(id24, "mortality", "Fbar", yr, fbar, "per year", age_group = "1-10",
    se = fbar * cv_fbar, source_reference = ref24, notes = se_note),
  make_output(id24, "mortality", "Fapical", yr, fapical, "per year", age_group = "apical",
    source_reference = ref24, notes = "Reported FApical; uncertainty is not given in the source table.")
)

outputs26 <- list()
add_sag <- function(column, low, high, type, measure, unit, age = NA_real_, age_group = "") {
  value <- suppressWarnings(as.numeric(sag[[column]]))
  lwr <- suppressWarnings(as.numeric(sag[[low]]))
  upr <- suppressWarnings(as.numeric(sag[[high]]))
  keep <- is.finite(value)
  outputs26[[length(outputs26) + 1L]] <<- make_output(id26, type, measure, sag$Year[keep],
    value[keep], unit, age = age, age_group = age_group, lwr = lwr[keep], upr = upr[keep],
    source_reference = "ICES Stock Assessment Graphs, source table key 23760",
    notes = "Source-table low/high values retained; interval level is not stated.")
}
add_sag("SSB", "Low SSB", "High SSB", "biomass", "SSB", "tonnes")
add_sag("Recruitment", "Low Recruitment", "High Recruitment", "recruitment", "recruitment", "thousand fish", age = 0)
add_sag("TBiomass", "Low TBiomass", "High TBiomass", "biomass", "total_biomass", "tonnes")
add_sag("F", "Low F", "High F", "mortality", "Fbar", "per year", age_group = label("lblFAge"))
outputs26 <- do.call(rbind, outputs26)
keep_catch <- is.finite(suppressWarnings(as.numeric(sag$Catches)))
inputs26 <- make_input(id26, "catch", "total_biomass", "biomass",
  as.numeric(sag$Catches[keep_catch]), "tonnes", year = sag$Year[keep_catch],
  fleet = "Combined catch", source_reference = "ICES Stock Assessment Graphs, source table key 23760",
  notes = "Aggregate catches only; no age breakdown is available in this summary record.")

assumptions24 <- do.call(rbind, list(
  make_assumption("population", "model_structure", "Annual one-area model, sexes combined; ages 0-10 and 11+; 1992-2023.", "WGHANSA 2024, section 5.4.1, pp. 240-242"),
  make_assumption("recruitment", "stock_recruitment", "Beverton-Holt; sigmaR 0.74; input steepness 0.8.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("N", "initial_population", "Starting equilibrium age structure from an initial equilibrium catch of 30,000 tonnes.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("F", "fishery_selectivity", "Age-based double-normal selectivity; two time-varying parameters.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("index", "IBTS_selectivity", "Fixed dome-shaped age selectivity.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("q", "catchability", "Simple linear q model for IBTS, DEPM, and commercial CPUE.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("observation_error", "data_weights", "Catch CV 0.05; IBTS CV 0.30; DEPM CV 0.40; CPUE CV 0.14.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("age_composition", "likelihood", "Dirichlet-multinomial weighting for catch and IBTS age data; age-reading uncertainty included.", "WGHANSA 2024, Table 5.4.1.1, p. 242"),
  make_assumption("M", "natural_mortality", "Fixed age vector from the Gislason method; estimated at WKBHMB.", "WGHANSA 2024, section 5.3.5, p. 239"),
  make_assumption("biology", "maturity", "Time-invariant female ogive from macroscopic data, applied to the combined-sex population.", "WGHANSA 2024, section 5.3.4, p. 239"),
  make_assumption("biology", "stock_weight", "Stock weight-at-age is the same as catch weight-at-age.", "WGHANSA 2024, sections 5.3.3 and 5.4.1, pp. 239, 242"),
  make_assumption("assessment", "software", "Stock Synthesis 3.30.22.", "WGHANSA 2024, section 5.4.1, p. 240")
))

read_db <- function(file) read.csv(file.path(db_dir, file), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read_db("stocks.csv")
assessments <- read_db("assessments.csv")
assumptions <- read_db("assumptions.csv")
inputs <- read_db("inputs.csv")
outputs <- read_db("outputs.csv")
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) abort("Expected one existing Charbonneau-Keith stock row.")
stocks$authority_stock_id[stock_row] <- "hom.27.9a"
stocks$common_name[stock_row] <- "Horse mackerel"
stocks$area[stock_row] <- "ICES Subarea 9.a (Atlantic Iberian waters)"
stocks$region[stock_row] <- "Atlantic Iberian waters"
stocks$notes[stock_row] <- paste(
  "Southern horse mackerel in ICES Subarea 9.a.",
  "The detailed 2024 WGHANSA assessment is the latest recovered record with model inputs, assumptions, and outputs.",
  "The newer 2026 ICES SAG record is summary-only."
)

new_assessments <- data.frame(
  assessment_id = c(id24, id26), stock_id = stock_id,
  assessment_year = c(2024L, 2026L), terminal_year = c(2023L, 2025L),
  estimate_terminal_year = c(2023L, 2026L),
  assessment_type = c("full_assessment", "assessment_update"),
  model_family = "Stock Synthesis", model_version = c("3.30.22", NA_character_),
  is_current = c(TRUE, FALSE), is_applied = c(TRUE, TRUE), framework_year = 2024L,
  assessment_url = c("https://doi.org/10.17895/ices.pub.26003356.v3", "https://sg.ices.dk/ViewSourceData.aspx?key=23760"),
  framework_url = "https://doi.org/10.17895/ices.pub.25002482.v2",
  data_url = c(NA_character_, "https://sg.ices.dk/ViewSourceData.aspx?key=23760"),
  model_url = NA_character_, repository_url = NA_character_,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = c(
    paste("Detailed 1992-2023 assessment. Catch-at-age, catch/stock weights, combined IBTS abundance-at-age, fixed M and maturity, DEPM SSB observations, settings, and aggregate output series were recovered.",
      "Commercial CPUE values, aggregate IBTS biomass index, fitted age-specific N/F, and native Stock Synthesis files were not recovered."),
    paste("Official ICES SAG source table for the 2026 update; fitted data end in 2025 and 2026 values are forecasts.",
      "Only aggregate catches and summary time series were recovered; detailed inputs, settings, model object, and age-specific outputs are unavailable.")
  ), stringsAsFactors = FALSE, check.names = FALSE
)

ids <- c(id24, id26)
assumptions <- assumptions[!assumptions$assessment_id %in% ids, , drop = FALSE]
inputs <- inputs[!inputs$assessment_id %in% ids, , drop = FALSE]
outputs <- outputs[!outputs$assessment_id %in% ids, , drop = FALSE]
assessments <- assessments[!assessments$assessment_id %in% ids, , drop = FALSE]
assessments <- rbind(assessments, new_assessments[, names(assessments), drop = FALSE])
assumptions <- rbind(assumptions, assumptions24[, names(assumptions), drop = FALSE])
inputs <- rbind(inputs, inputs24[, names(inputs), drop = FALSE], inputs26[, names(inputs), drop = FALSE])
outputs <- rbind(outputs, outputs24[, names(outputs), drop = FALSE], outputs26[, names(outputs), drop = FALSE])

if (anyDuplicated(stocks$stock_id) || anyDuplicated(assessments$assessment_id) ||
    any(!assessments$stock_id %in% stocks$stock_id) ||
    any(!assumptions$assessment_id %in% assessments$assessment_id) ||
    any(!inputs$assessment_id %in% assessments$assessment_id) ||
    any(!outputs$assessment_id %in% assessments$assessment_id) ||
    sum(assessments$is_current & assessments$stock_id == stock_id, na.rm = TRUE) != 1L ||
    !assessments$is_current[assessments$assessment_id == id24]) {
  abort("Database identity, foreign-key, or current-assessment validation failed.")
}

write.csv(stocks, file.path(db_dir, "stocks.csv"), row.names = FALSE, na = "")
write.csv(assessments, file.path(db_dir, "assessments.csv"), row.names = FALSE, na = "")
write.csv(assumptions, file.path(db_dir, "assumptions.csv"), row.names = FALSE, na = "")
write.csv(inputs, file.path(db_dir, "inputs.csv"), row.names = FALSE, na = "")
write.csv(outputs, file.path(db_dir, "outputs.csv"), row.names = FALSE, na = "")
cat("Imported 2024 detailed and 2026 summary-only horse mackerel records.\n")
cat("2024 input/output rows:", nrow(inputs24), nrow(outputs24), "\n")
cat("2026 input/output rows:", nrow(inputs26), nrow(outputs26), "\n")
