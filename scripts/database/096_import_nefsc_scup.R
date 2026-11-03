root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache")
stock_id <- "ck_nefsc_saw_chrysops_usatl"
assessment_2015 <- "nefsc_scup_2015"
assessment_2025 <- "nefsc_scup_2025"

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

blank_row <- function(fields, values = list()) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, stringsAsFactors = FALSE, optional = TRUE)
}

rows_from <- function(fields, rows) {
  if (!length(rows)) return(blank_row(fields)[FALSE, , drop = FALSE])
  do.call(rbind, lapply(rows, function(row) blank_row(fields, row)))
}

number_tokens <- function(line) {
  matches <- gregexpr(
    "(?<![0-9])(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?",
    line, perl = TRUE
  )
  tokens <- regmatches(line, matches)[[1L]]
  as.numeric(gsub(",", "", tokens, fixed = TRUE))
}

extract_table <- function(lines, number, columns) {
  headings <- grep("^ *Table A[0-9]+(?:\\.| +)", lines, perl = TRUE)
  heading_numbers <- as.integer(sub("^ *Table A([0-9]+)(?:\\.| +).*$", "\\1", lines[headings], perl = TRUE))
  start <- headings[heading_numbers == number]
  if (!length(start)) stop("Missing Table A", number, " heading.", call. = FALSE)
  start <- min(start)
  later <- which(headings > start)
  different <- later[heading_numbers[later] != number]
  end <- if (length(different)) headings[different[[1L]]] - 1L else length(lines)
  candidates <- lines[seq.int(start + 1L, end)]
  candidates <- candidates[grepl("^ *(19|20)[0-9]{2} +", candidates, perl = TRUE)]
  parsed <- lapply(candidates, number_tokens)
  parsed <- parsed[lengths(parsed) == columns]
  if (!length(parsed)) stop("No complete rows found in Table A", number, ".", call. = FALSE)
  as.data.frame(do.call(rbind, parsed), stringsAsFactors = FALSE)
}

add_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  write.table(rows, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "", append = TRUE,
    eol = "\n", fileEncoding = "UTF-8")
}

stocks <- read_table(file.path(database, "stocks.csv"))
assessments <- read_table(file.path(database, "assessments.csv"))
assumptions <- read_table(file.path(database, "assumptions.csv"))
inputs <- read_table(file.path(database, "inputs.csv"))
outputs <- read_table(file.path(database, "outputs.csv"))
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

if (!dry_run && any(assessments$assessment_id %in% c(assessment_2015, assessment_2025))) {
  stop("Scup assessments are already imported; review existing records before importing.", call. = FALSE)
}
if (sum(stocks$stock_id == stock_id) != 1L) stop("Expected one scup stock record.", call. = FALSE)

report_file <- file.path(cache, "nefsc_scup_2015", "NEFSC_15-08_60th_SAW_Assessment_Report.txt")
update_file <- file.path(cache, "nefsc_scup_2025", "2025_SCP_UNIT", "2025_SCUP_UNIT_REPORT_2025-06-20.txt")
a32_file <- file.path(cache, "nefsc_scup_2015", "NEFSC_15-08_Table_A32_fall_numbers_at_age.csv")
if (!all(file.exists(c(report_file, update_file, a32_file)))) {
  stop("Scup source-cache files are missing; see the local source manifest.", call. = FALSE)
}
report <- readLines(report_file, encoding = "UTF-8", warn = FALSE)
update <- paste(readLines(update_file, encoding = "UTF-8", warn = FALSE), collapse = "\n")
if (!grepl("Table 1: Catch and status table for scup", update, fixed = TRUE)) {
  stop("The 2025 report does not contain the expected catch and status table.", call. = FALSE)
}

input_fields <- names(inputs)
output_fields <- names(outputs)
assumption_fields <- names(assumptions)
new_inputs <- list()
add_input <- function(...) {
  new_inputs[[length(new_inputs) + 1L]] <<- blank_row(input_fields, list(...))
}

catch_tables <- list(
  list(number = 13L, fleet = "Commercial landings", page = 100L),
  list(number = 16L, fleet = "Commercial discards", page = 103L),
  list(number = 18L, fleet = "Recreational landings", page = 105L),
  list(number = 20L, fleet = "Recreational discards", page = 107L)
)
for (table in catch_tables) {
  values <- extract_table(report, table$number, 12L)
  values <- values[values[[1L]] %in% 1984:2014, , drop = FALSE]
  if (!identical(as.integer(values[[1L]]), 1984:2014)) {
    stop("Unexpected year coverage in Table A", table$number, ": ",
      paste(as.integer(values[[1L]]), collapse = ", "), call. = FALSE)
  }
  for (i in seq_len(nrow(values))) for (age in 0:10) {
    add_input(assessment_id = assessment_2015, type = "catch", measure = "numbers_at_age",
      basis = "numbers", fleet = table$fleet, year = values[[1L]][i],
      year_basis = "calendar_year", age = age, value = values[[age + 2L]][i],
      unit = "thousand fish", source_type = "official_table",
      source_reference = paste0("NEFSC Reference Document 15-08, Table A", table$number,
        ", p. ", table$page),
      notes = paste0("Reported ages 0-10 are retained. The final ASAP model uses ages 0-7+; ",
        ""))
  }
}

weight_table <- extract_table(report, 24L, 12L)
weight_table <- weight_table[weight_table[[1L]] %in% 1984:2014, , drop = FALSE]
if (!identical(as.integer(weight_table[[1L]]), 1984:2014)) stop("Unexpected Table A24 years.", call. = FALSE)
for (i in seq_len(nrow(weight_table))) for (age in 0:10) {
  add_input(assessment_id = assessment_2015, type = "weight", measure = "weight_at_age",
    basis = "kg_per_fish", year = weight_table[[1L]][i], year_basis = "calendar_year",
    age = age, value = weight_table[[age + 2L]][i], unit = "kg per fish",
    source_type = "official_table", source_reference = "NEFSC Reference Document 15-08, Table A24, p. 111",
    notes = paste0("Annual total-fishery catch-number-weighted weight; translation must aggregate ",
      "source ages 7-10 explicitly for the model's 7+ group."))
}

mat3 <- which(trimws(report) == "MAT3 0 1 2 3 4 5 6 7+")
if (length(mat3) != 1L) stop("The report's MAT3 maturity table is missing.", call. = FALSE)
maturity_rows <- list()
for (line in report[seq.int(mat3 + 1L, length(report))]) {
  if (!grepl("^ *(19|20)[0-9]{2} +", line, perl = TRUE)) {
    if (length(maturity_rows)) break
    next
  }
  values <- number_tokens(line)
  if (length(values) == 9L && values[[1L]] >= 1981 && values[[1L]] <= 2014) {
    maturity_rows[[length(maturity_rows) + 1L]] <- values
  }
}
maturity_rows <- do.call(rbind, maturity_rows)
if (!identical(as.integer(maturity_rows[, 1L]), 1981:2014)) stop("Unexpected MAT3 years.", call. = FALSE)
for (year in 1963:1980) for (age in 0:7) {
  value <- if (age < 2L) 0 else if (age == 2L) 0.83 else 1
  add_input(assessment_id = assessment_2015, type = "maturity", measure = "maturity_at_age",
    basis = "proportion", year = year, year_basis = "calendar_year", age = age,
    value = value, unit = "proportion", source_type = "reconstructed_source_input",
    source_reference = "NEFSC Reference Document 15-08, p. 27",
    transformation = "Applied the fixed pre-1981 maturity schedule stated in the report.",
    notes = "Before 1981: ages 0-1=0, age 2=0.83, and ages 3+=1.00; age 7 is the 7+ group.")
}
for (i in seq_len(nrow(maturity_rows))) for (age in 0:7) {
  add_input(assessment_id = assessment_2015, type = "maturity", measure = "maturity_at_age",
    basis = "proportion", year = maturity_rows[i, 1L], year_basis = "calendar_year",
    age = age, value = maturity_rows[i, age + 2L], unit = "proportion",
    source_type = "official_table", source_reference = "NEFSC Reference Document 15-08, p. 27, MAT3 table",
    notes = "Annual sex-combined three-year moving-window schedule; age 7 is the 7+ group.")
}

fall_index <- read_table(a32_file)
names(fall_index) <- c("year", "age", "value", "reported_total", "source_reference")
fall_index$year <- as.integer(fall_index$year)
fall_index$age <- as.integer(fall_index$age)
fall_index$value <- as.numeric(fall_index$value)
fall_index$reported_total <- as.numeric(fall_index$reported_total)
if (nrow(fall_index) != 31L * 9L || anyDuplicated(fall_index[c("year", "age")]) ||
  !identical(sort(unique(fall_index$year)), 1984:2014) ||
  !identical(sort(unique(fall_index$age)), 0:8) || anyNA(fall_index$value) || any(fall_index$value < 0)) {
  stop("Table A32 extraction has unexpected coverage or values.", call. = FALSE)
}
age_totals <- aggregate(value ~ year, fall_index, sum)
reported_totals <- unique(fall_index[c("year", "reported_total")])
if (any(abs(age_totals$value - reported_totals$reported_total) > 0.05)) {
  stop("Table A32 age values do not match reported annual totals within rounding.", call. = FALSE)
}
for (i in seq_len(nrow(fall_index))) {
  add_input(assessment_id = assessment_2015, type = "index", measure = "numbers_at_age",
    basis = "numbers", survey = "NEFSC fall trawl survey", year = fall_index$year[i],
    year_basis = "calendar_year", age = fall_index$age[i], value = fall_index$value[i],
    unit = "fish per tow", source_type = "official_table",
    source_reference = fall_index$source_reference[i],
    notes = "Stratified mean fish per tow. Published blank cells are represented as zero. HBB values from 2009 onward are calibrated to ALB equivalents.")
}
for (age in 0:7) add_input(assessment_id = assessment_2015, type = "M",
  measure = "natural_mortality_at_age", basis = "per_year", age = age,
  value = 0.20, unit = "yr-1", source_type = "official_document",
  source_reference = "NEFSC Reference Document 15-08, pp. 17, 54",
  notes = "Fixed natural mortality; age 7 is the 7+ group.")

catch_totals <- list()
for (table_number in c(22L, 25L)) {
  table <- extract_table(report, table_number, 6L)
  selected_years <- if (table_number == 22L) 1981:2014 else 1963:1980
  table <- table[table[[1L]] %in% selected_years, , drop = FALSE]
  if (!identical(as.integer(table[[1L]]), selected_years)) stop("Unexpected catch-total years in Table A", table_number, ".", call. = FALSE)
  fleets <- if (table_number == 22L) {
    c("Commercial landings", "Commercial discards", "Recreational landings", "Recreational discards")
  } else {
    c("Commercial landings", "Commercial discards", "Distant-water fleet landings", "Recreational catch (combined)")
  }
  for (i in seq_len(nrow(table))) for (j in seq_along(fleets)) {
    catch_totals[[length(catch_totals) + 1L]] <- list(
      year = table[[1L]][i], fleet = fleets[j], value = table[[j + 1L]][i], table = table_number)
  }
}
for (row in catch_totals) add_input(assessment_id = assessment_2015, type = "catch",
  measure = "total_biomass", basis = "biomass", fleet = row$fleet, year = row$year,
  year_basis = "calendar_year", value = row$value, unit = "metric tons",
  source_type = "official_table", source_reference = paste0("NEFSC Reference Document 15-08, Table A", row$table),
  notes = if (row$table == 25L) "Historical 1963-1980 fleet totals; distant-water landings and combined recreational catch remain separately identified." else "Four fleet catch totals for 1981-2014; overlapping historical table rows are not duplicated.")

update_years <- 2015:2024
update_catch <- list(
  "Commercial landings" = c(7725,7147,7006,6064,6252,6213,5965,5518,5906,6567),
  "Commercial discards" = c(1718,2778,4733,3293,2779,2642,1932,2299,3148,4700),
  "Recreational landings" = c(5527,4536,6143,5887,6403,5863,7540,7875,5403,4989),
  "Recreational discards" = c(581,862,1079,644,560,541,653,762,609,741)
)
for (fleet in names(update_catch)) for (i in seq_along(update_years)) {
  add_input(assessment_id = assessment_2025, type = "catch", measure = "total_biomass",
    basis = "biomass", fleet = fleet, year = update_years[i], year_basis = "calendar_year",
    value = update_catch[[fleet]][i], unit = "metric tons", source_type = "official_table",
    source_reference = "2025 Scup Management Track Assessment Report, Table 1, p. 1",
    notes = "Catch component reported for the 2025 update; the summed removals row is not duplicated.")
}

new_outputs <- list()
add_output <- function(...) {
  new_outputs[[length(new_outputs) + 1L]] <<- blank_row(output_fields, list(...))
}
years_2015 <- 1984:2014
table_a55 <- extract_table(report, 55L, 4L)
table_a56 <- extract_table(report, 56L, 9L)
table_a57 <- extract_table(report, 57L, 9L)
for (table in list(table_a55, table_a56, table_a57)) {
  if (!identical(as.integer(table[[1L]]), years_2015)) stop("Unexpected 2015 output table years.", call. = FALSE)
}
for (i in seq_along(years_2015)) {
  year <- years_2015[i]
  ssb_interval <- if (year == 2014) c(153000, 222000) else c("", "")
  f_interval <- if (year == 2014) c(0.093, 0.149) else c("", "")
  add_output(assessment_id = assessment_2015, type = "biomass", measure = "SSB", year = year,
    value = table_a55[i, 2L], lwr = ssb_interval[1L], upr = ssb_interval[2L], unit = "metric tons",
    source_type = "official_table", source_reference = "NEFSC Reference Document 15-08, Table A55, p. 156",
    notes = if (year == 2014) "Point estimate; 90% MCMC probability interval from assessment text, p. 68." else "Point estimate; year-specific uncertainty is not tabulated.")
  add_output(assessment_id = assessment_2015, type = "recruitment", measure = "recruitment",
    year = year, age = 0, value = table_a55[i, 3L], unit = "million fish",
    source_type = "official_table", source_reference = "NEFSC Reference Document 15-08, Table A55, p. 156",
    notes = "Recruitment at age 0.")
  for (age in 0:7) {
    age_group <- if (age == 7) "7+" else ""
    age_value <- if (age == 7) "" else age
    add_output(assessment_id = assessment_2015, type = "population", measure = "numbers_at_age",
      year = year, age = age_value, age_group = age_group, value = table_a56[i, age + 2L],
      unit = "thousand fish at January 1", source_type = "official_table",
      source_reference = "NEFSC Reference Document 15-08, Table A56, p. 157",
      notes = if (age == 7) "Official model plus group 7+." else "January 1 population number.")
    add_output(assessment_id = assessment_2015, type = "mortality", measure = "fishing_mortality_at_age",
      year = year, age = age_value, age_group = age_group, value = table_a57[i, age + 2L],
      lwr = if (year == 2014 && age == 3) f_interval[1L] else "",
      upr = if (year == 2014 && age == 3) f_interval[2L] else "", unit = "yr-1",
      source_type = "official_table", source_reference = "NEFSC Reference Document 15-08, Table A57, p. 158",
      notes = if (year == 2014 && age == 3) "Point estimate; 90% MCMC probability interval for peak-selection age 3 from assessment text, p. 68." else if (age == 7) "Official model plus group 7+." else "Instantaneous fishing mortality.")
  }
}

ssb_2025 <- c(214560,244240,274140,279800,270040,263630,232970,206800,194270,163470)
f_2025 <- c(0.101,0.079,0.082,0.065,0.070,0.070,0.092,0.117,0.127,0.167)
recruitment_2025 <- c(695850,318640,159600,173970,88210,127430,152810,141810,40055,15827)
for (i in seq_along(update_years)) {
  year <- update_years[i]
  terminal <- year == 2024
  add_output(assessment_id = assessment_2025, type = "biomass", measure = "SSB", year = year,
    value = ssb_2025[i], lwr = if (terminal) 142932 else "", upr = if (terminal) 194496 else "",
    unit = "metric tons", source_type = "official_table",
    source_reference = "2025 Scup Management Track Assessment Report, Table 1, p. 1",
    notes = if (terminal) "Unadjusted model estimate; approximate 90% interval from assessment text. Table 1 is not retrospectively adjusted." else "Unadjusted model estimate; Table 1 is not retrospectively adjusted.")
  add_output(assessment_id = assessment_2025, type = "mortality", measure = "Fbar", year = year,
    age_group = "age 4 (Ffull)", value = sprintf("%.15g", f_2025[i]),
    lwr = if (terminal) 0.125 else "", upr = if (terminal) 0.226 else "", unit = "yr-1",
    source_type = "official_table", source_reference = "2025 Scup Management Track Assessment Report, Table 1, p. 1",
    notes = if (terminal) "Unadjusted Ffull at source age 4; approximate 90% interval. Retrospective-adjusted Ffull is separate." else "Unadjusted Ffull at source age 4.")
  add_output(assessment_id = assessment_2025, type = "recruitment", measure = "recruitment",
    year = year, age = 0, value = recruitment_2025[i], unit = "thousand fish",
    source_type = "official_table", source_reference = "2025 Scup Management Track Assessment Report, Table 1, p. 1",
    notes = "Recruitment at age 0.")
}
add_output(assessment_id = assessment_2025, type = "biomass", measure = "published_terminal_SSB",
  year = 2024, value = 235613, unit = "metric tons", source_type = "official_document",
  source_reference = "2025 Scup Management Track Assessment Report, p. 1",
  notes = "Retrospective-adjusted 2024 SSB used for status determination; distinct from unadjusted Table 1 estimate.")
add_output(assessment_id = assessment_2025, type = "mortality", measure = "Fbar", year = 2024,
  age_group = "age 4 (retrospective-adjusted Ffull)", value = 0.098, unit = "yr-1",
  source_type = "official_document", source_reference = "2025 Scup Management Track Assessment Report, p. 1",
  notes = "Retrospective-adjusted 2024 Ffull used for status determination; distinct from unadjusted Table 1 estimate.")

new_assessments <- list(
  blank_row(names(assessments), list(assessment_id = assessment_2015, stock_id = stock_id,
    assessment_year = 2015, terminal_year = 2014, estimate_terminal_year = 2014,
    assessment_type = "full_assessment", model_family = "ASAP", model_version = "S60_BASE_18 (2015 SAW 60)",
    is_current = "TRUE", is_applied = "TRUE", framework_year = 2015,
    assessment_url = "https://repository.library.noaa.gov/view/noaa/4975",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "SARC-selected final ASAP3 run. Catch, annual catch totals, annual weights, MAT3, fixed M, active NEFSC fall age indices and N/F/SSB/recruitment tables are imported. Other active index settings and complete model controls remain incomplete; no native S60_BASE_18 input archive was recovered. See source_reviews/ck_nefsc_saw_chrysops_usatl.md.")),
  blank_row(names(assessments), list(assessment_id = assessment_2025, stock_id = stock_id,
    assessment_year = 2025, terminal_year = 2024, estimate_terminal_year = 2024,
    assessment_type = "assessment_update", model_family = "ASAP", model_version = "run26 (2025 Management Track)",
    is_current = "FALSE", is_applied = "TRUE", framework_year = 2015,
    assessment_url = "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=28&stock_id=6&review_type_id=2&info_type_id=-1&map_type_id=&filename=2025_SCUP_UNIT_REPORT_2025-06-20.pdf",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "Latest official management-track update. Table values are unadjusted for retrospective bias; rho-adjusted terminal SSB and F are separate. Detailed inputs and age-specific outputs are not public in the downloaded bundle. See source_reviews/ck_nefsc_saw_chrysops_usatl.md."))
)

assumption_values <- list(
  list(assessment_id=assessment_2015, component="population", setting="modeled_years", value="1963-2014", source_reference="NEFSC Reference Document 15-08, Table A49, p. 139", notes="S60_BASE_18 final run; age-specific output tables cover 1984-2014."),
  list(assessment_id=assessment_2015, component="population", setting="modeled_ages", value="true ages 0-7+ (8 groups)", source_reference="NEFSC Reference Document 15-08, Tables A49, A56-A57, pp. 139, 157-158", notes="Catch and index tables retain finer ages; the model uses a 7+ group."),
  list(assessment_id=assessment_2015, component="recruitment", setting="recruitment_age", value="0", source_reference="NEFSC Reference Document 15-08, Table A55, p. 156", notes="Recruitment is reported at true age 0."),
  list(assessment_id=assessment_2015, component="M", setting="treatment", value="Fixed M = 0.20 for all ages and years", source_reference="NEFSC Reference Document 15-08, pp. 17, 54", notes="M is assumed, not estimated; the 2015 likelihood profile favored lower values but the prior value was retained."),
  list(assessment_id=assessment_2015, component="biology", setting="weight_at_age", value="Annual total-fishery catch-number-weighted weights at age, ages 0-10, 1984-2014", source_reference="NEFSC Reference Document 15-08, Table A24, p. 111", notes="The same matrix supports mid-year catch and extrapolated SSB calculations; source-reported zeroes are retained."),
  list(assessment_id=assessment_2015, component="biology", setting="maturity_at_age", value="Annual sex-combined MAT3 schedule, 1981-2014; fixed schedule before 1981", source_reference="NEFSC Reference Document 15-08, p. 27", notes="MAT3 is a three-year moving-window maturity schedule. Before 1981 the report states ages 0-1=0, age 2=0.83, ages 3+=1.00."),
  list(assessment_id=assessment_2015, component="catch", setting="fleets", value="Commercial landings; commercial discards; recreational landings; recreational discards", source_reference="NEFSC Reference Document 15-08, p. 56", notes="Commercial discards have 100% mortality; recreational discards have 15% mortality."),
  list(assessment_id=assessment_2015, component="index", setting="NEFSC_fall_index", value="Stratified mean numbers per tow at ages 0-8, 1984-2014; HBB calibrated to ALB-equivalent lengths from 2009", source_reference="NEFSC Reference Document 15-08, Table A32, pp. 121-122", notes="The translation approximates the source multinomial age-composition plus aggregate-index treatment with age-specific lognormal indices."),
  list(assessment_id=assessment_2015, component="index", setting="run_18_omissions", value="NEFSC spring; MADMF spring; RIDFW spring; RIDFW fall; VIMS ChesMMAP", source_reference="NEFSC Reference Document 15-08, pp. 65-66", notes="These indices were omitted from S60_BASE_18; other retained survey series remain to be inventoried."),
  list(assessment_id=assessment_2025, component="model", setting="retrospective_adjustment", value="7-year Mohn's rho: SSB -0.31; F 0.70", source_reference="2025 Scup Management Track Assessment Report, p. 2", notes="Rho-adjusted terminal SSB and F are stored separately from the annual series."),
  list(assessment_id=assessment_2025, component="model", setting="report_table_adjustment", value="Table 1 SSB and F are unadjusted for retrospective bias", source_reference="2025 Scup Management Track Assessment Report, Table 1, p. 1", notes="Do not substitute rho-adjusted terminal values into the unadjusted annual series.")
)
new_assumptions <- rows_from(assumption_fields, assumption_values)
new_inputs <- do.call(rbind, lapply(new_inputs, identity))
new_outputs <- do.call(rbind, lapply(new_outputs, identity))

cat("Scup import prepared:", nrow(new_inputs), "inputs,", nrow(new_outputs),
  "outputs,", nrow(new_assumptions), "assumptions, and", nrow(new_assessments), "assessments.\n")
if (!dry_run) {
  updated_stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
  updated_stock$common_name <- "Scup"
  if (!grepl("Common name Scup verified", updated_stock$notes, fixed = TRUE)) {
    updated_stock$notes <- paste(trimws(updated_stock$notes),
      "Common name Scup verified in NOAA assessment sources.")
  }
  stocks[stocks$stock_id == stock_id, ] <- updated_stock
  temp_stock <- tempfile(tmpdir = database, fileext = ".csv")
  write.csv(stocks, temp_stock, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  if (!file.rename(temp_stock, file.path(database, "stocks.csv"))) stop("Could not replace stocks.csv.", call. = FALSE)
  add_rows(file.path(database, "assessments.csv"), do.call(rbind, new_assessments))
  add_rows(file.path(database, "assumptions.csv"), new_assumptions)
  add_rows(file.path(database, "inputs.csv"), new_inputs)
  add_rows(file.path(database, "outputs.csv"), new_outputs)
  source(file.path(root, "scripts", "database", "002_validate_database.R"))
}
