base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_hawg_dubius_ns/2026_san.sa.3r")
assessment_id <- "ices_sandeel_area_3r_2026"
stock_id <- "ices_sandeel_area_3r"
catalogue_id <- "ck_ices_hawg_dubius_ns"
report_url <- "https://doi.org/10.17895/ices.pub.31424315"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21282"
repo_url <- "https://github.com/ices-advice/2026_san.sa.3r"
revision <- "93847fb928ebf02f995c503e67f52bc2dd1398cc"
software_revision <- "a097011f2fff959c9a263e5f6acb49795b9a53ad"
verify <- function(file, expected) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256") != expected) cli::cli_abort("Cache and verify {file} before importing this assessment.")
  path
}
pages <- pdftools::pdf_text(verify("../../ices_sandeel_area_1r_2026/HAWG_2026.pdf", "50c5b7c68fbdb8951c9f9d7055016d1f2158181fd2a13a34b427cdedb45b8f45"))
settings <- readLines(verify("data.R", "2dffa76e4082396177dae4a3b068989183a75620d6ad3128952c2838a5979848"))
software <- readLines(verify("../../ices_sandeel_area_1r_2026/get_tmb_parameters.R", "1dcd5b4699418b755fc163a2647e1d576f31496ecfa13a95f7959ced47b09205"))
sag_path <- verify("SAG_21282.html", "43437d9e17938846a28fe4fd37611947a3202720fa9c83b7acf8ce5939e2ea37")
stopifnot(any(grepl("startYear = 1987", settings, fixed = TRUE)),
  any(grepl("CminageSeason = c(1,1)", settings, fixed = TRUE)),
  any(grepl("blocks = FALSE", settings, fixed = TRUE)),
  any(grepl("propM <- array(0", software, fixed = TRUE)),
  any(grepl("propF <- array(0", software, fixed = TRUE)))
years <- 1987:2025
annual <- function(text, columns, first_only = FALSE, missing_years = integer()) {
  lines <- strsplit(paste(text, collapse = "\n"), "\n")[[1L]]
  lines <- trimws(lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]", lines)])
  cells <- strsplit(lines, "[[:space:]]+")
  at <- as.integer(vapply(cells, `[[`, character(1), 1L)) %in% years
  cells <- cells[at]
  if (first_only) {
    cells <- lapply(cells, function(z) z[c(1, 4)])
    columns <- 1L
  }
  expected_years <- setdiff(years, missing_years)
  if (length(cells) != length(expected_years) || any(lengths(cells) != columns + 1L)) {
    found <- as.integer(vapply(cells, `[[`, character(1), 1L))
    missing <- paste(setdiff(expected_years, found), collapse = ", ")
    cli::cli_abort("Unexpected source table dimensions: {length(cells)} rows, expected {length(expected_years)}. Missing years: {missing}.")
  }
  x <- do.call(rbind, lapply(cells, function(z) suppressWarnings(as.numeric(z))))
  stopifnot(identical(as.integer(x[, 1]), expected_years))
  x[, -1, drop = FALSE]
}
after <- function(text, label) {
  at <- regexpr(label, text, fixed = TRUE)[1L]
  stopifnot(at > 0); substring(text, at)
}
C <- annual(pages[553:554], 10L)
W <- annual(pages[555:556], 9L)
mat <- annual(pages[557:558], 9L)
M <- annual(pages[565:566], 9L)
F <- annual(pages[561:562], 6L)
Fs <- annual(pages[563:564], 8L)
N <- annual(pages[567:568], 5L)
summary <- annual(c(pages[569], strsplit(pages[570], "Table 9.4.11", fixed = TRUE)[[1L]][1L]), 5L)
effort <- matrix(NA_real_, length(years), 3L)
effort[, 1] <- annual(c(after(pages[508], "Table 9.1.6"), pages[509]), 1L, first_only = TRUE)[, 1L]
effort[!years %in% c(2007L, 2022L), 2] <- annual(c(after(pages[510], "Table 9.1.7"), pages[511]), 1L,
  first_only = TRUE, missing_years = c(2007L, 2022L))[, 1L]
effort[, 3] <- annual(c(after(pages[506], "Table 9.1.5"), pages[507]), 1L, first_only = TRUE)[, 1L]
tables <- rvest::html_table(rvest::read_html(sag_path), fill = TRUE)
sag <- Filter(function(x) all(c("Year", "Recruitment", "SSB", "Low F") %in% names(x)), tables)
stopifnot(length(sag) == 1L)
sag <- as.data.frame(sag[[1L]]); historical <- sag[sag$Year %in% years, ]
stopifnot(identical(historical$Year, years),
  all(is.finite(c(C, W, mat, M, F, Fs, N, summary, effort[!is.na(effort)]))),
  sum(is.na(effort)) == 2L, all(is.na(effort[years %in% c(2007L, 2022L), 2])),
  identical(as.numeric(historical$Recruitment), N[, 1]),
  identical(as.numeric(historical$SSB), summary[, 3]),
  max(abs(historical$F - F[, 6])) <= .005 + 1e-12,
  max(abs(F[, 2:5] - Fs[, 1:4] - Fs[, 5:8])) <= .0010001,
  max(abs(log(N[-length(years), 2:3] / N[-1, 3:4]) - F[-length(years), 2:3] - M[-length(years), 1:2] - M[-length(years), 6:7])) < .010001,
  sum(C[, c(2:5, 7:10)] > 0) == 240L)
biomass_error <- rowSums(N[, 2:5] * .005 + .5 * W[, 1:4] + .5 * .005) / 1000 + .5
ssb_error <- rowSums(N[, 2:5] * (.005 * mat[, 1:4] + .005 * W[, 1:4] + .005^2) +
  .5 * (W[, 1:4] + .005) * (mat[, 1:4] + .005)) / 1000 + .5
stopifnot(all(abs(rowSums(N[, 2:5] * W[, 1:4]) / 1000 - summary[, 2]) <= biomass_error),
  all(abs(rowSums(N[, 2:5] * W[, 1:4] * mat[, 1:4]) / 1000 - summary[, 3]) <= ssb_error))

blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
number <- function(x) ifelse(is.na(x), "", format(x, digits = 15, trim = TRUE, scientific = FALSE))
input <- function(type, measure, basis, values, ages, seasons, unit, table, notes, survey = "") {
  n <- length(values); x <- blank("inputs.csv", n)
  x$type <- type; x$measure <- measure; x$basis <- basis
  x$year <- rep(years, length.out = n); x$year_basis <- "calendar_year"
  x$age <- number(rep(ages, each = length(years), length.out = n))
  x$season <- rep(seasons, each = length(years), length.out = n)
  x$value <- number(as.vector(values)); x$unit <- unit; x$sex <- "combined"
  x$region <- "Sandeel Area 3r"; x$fleet <- if (type %in% c("catch", "catch_weight", "covariate")) "Combined commercial fishery" else ""
  x$survey <- survey; x$source_type <- "official_table"
  x$source_reference <- paste(report_url, table, sep = "; "); x$notes <- notes; x
}
age_season <- c(1:4, 0:4); seasons <- c(rep("1", 4), rep("2", 5))
inputs <- rbind(
  input("catch", "numbers_at_age", "numbers", C, rep(0:4, 2), rep(c("1", "2"), each = 5), "million fish", "Table 9.4.1, printed pp. 546-547",
    "Reported catch numbers by half-year, retaining zeros and age-0 values. The production model excludes age 0 in both seasons. The table has 240 positive cells at ages 1-4+, whereas Table 9.4.5 reports 244 catch likelihood observations; exact omitted cells or precision differences are unresolved. Do not alter source values to force the count to agree."),
  input("weight", "weight_at_age", "g_per_fish", W, age_season, seasons, "g per fish", "Table 9.4.2, printed pp. 548-549",
    "Source gives the same weight in catch and stock, by half-year. Age 4 is 4+. No first-half age-0 weight is supplied; no value is invented."),
  input("catch_weight", "weight_at_age", "g_per_fish", W, age_season, seasons, "g per fish", "Table 9.4.2, printed pp. 548-549",
    "Same published catch/stock weights, retaining the catch-weight role. No annual mean or source-fitted weighting is substituted."),
  input("maturity", "maturity_at_age", "proportion", mat, age_season, seasons, "proportion", "Table 9.4.3, printed pp. 550-551",
    "Seasonal supplied maturity; age 4 denotes 4+. Source SSB uses January abundance and first-half weights/maturity, with propM=propF=0 in the pinned native configuration."),
  input("M", "natural_mortality_at_age", "per_season", M, age_season, seasons, "per half-year", "Table 9.4.8, printed pp. 558-559; pinned smsR source Nsave recursion",
    "Externally supplied multispecies M, printed to two decimals, entering survival as exp(-F_season-M_season). These are integrated half-year hazards, not annual rates repeated twice. Annual cohort mortality is the sum of the two seasonal values at the same age; annualization belongs in the translation."),
  input("covariate", "effort", "native_covariate", effort, NA, c("1", "2", "annual"), "fishing days (standard 200 GT vessel)", "Tables 9.1.5-9.1.7, printed pp. 499-504",
    "Native annual and half-year fishing effort. Do not add annual totals to seasonal components. Constant age/season coefficients relate F to standardized effort, without technical creep. The 2007 and 2022 second-half rows are absent; no values are invented. Annual 2025 effort is zero, consistent with the closure and zero catch/F."))
inputs <- inputs[!(inputs$type == "covariate" & inputs$year %in% c(2007L, 2022L) & inputs$season == "2"), ]
survey_text <- paste(c(pages[559], strsplit(pages[560], "Table 9.4.5", fixed = TRUE)[[1L]][1L]), collapse = "\n")
for (survey in c("Dredge", "Acoustic")) {
  lines <- strsplit(survey_text, "\n")[[1L]]
  lines <- trimws(lines[grepl(paste0("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", survey, "[[:space:]]"), lines)])
  cells <- strsplit(lines, "[[:space:]]+")
  survey_years <- as.integer(vapply(cells, `[[`, character(1), 1L))
  ages <- if (survey == "Dredge") 0:1 else 1:4
  values <- do.call(rbind, lapply(cells, function(z) as.numeric(z[if (survey == "Dredge") 3:4 else 4:7])))
  stopifnot(identical(survey_years, if (survey == "Dredge") 2006:2025 else 2009:2025))
  x <- blank("inputs.csv", length(values))
  x$type <- "index"; x$measure <- "numbers_at_age"; x$basis <- "index_scale"
  x$year <- rep(survey_years, length(ages)); x$year_basis <- "calendar_year"
  x$age <- rep(ages, each = length(survey_years)); x$value <- number(as.vector(values))
  x$survey <- survey; x$sex <- "combined"; x$region <- "Sandeel Area 3r"; x$season <- if (survey == "Dredge") "2" else "1"
  x$unit <- "number index (scaled; multiplier not stated)"
  x$source_type <- "official_table"; x$source_reference <- paste(report_url, "Table 9.4.4, pp. 552-553; pinned data.R survey configuration")
  x$notes <- if (survey == "Dredge") "Native scaled Dredge index, ages 0-1, not absolute abundance. Prediction averages fractions 0.75-1 of season 2 (annual interval 0.875-1); no exact single sampling_time. Age 0 is July recruitment." else "Native scaled acoustic index with separate observations at ages 1-4+, not a pooled age-3+ observation. Configured prediction averages fractions 0.5-0.7 of season 1 (annual interval 0.25-0.35); no exact single sampling_time. Catchability is shared at ages 3 and 4+, with one SD shared over ages 1-4+."
  inputs <- rbind(inputs, x)
}

x <- blank("inputs.csv", length(years)); x$type <- "catch"; x$measure <- "total_biomass"; x$basis <- "biomass"
x$year <- years; x$year_basis <- "calendar_year"; x$value <- number(historical$Catches)
x$unit <- "tonnes"; x$fleet <- "Combined commercial fishery"; x$sex <- "combined"; x$region <- "Sandeel Area 3r"
x$source_type <- "official_machine_readable"; x$source_reference <- sag_url
x$notes <- "Reported all-age catches from SAG; not the model-predicted Yield in Table 9.4.10 and not an additional total-catch likelihood. Includes age-0 removals excluded from the fitted age-specific likelihood; retain separately without rescaling age counts."
inputs <- rbind(inputs, x)
output <- function(measure, values, ages = NA, seasons = "", unit, table, type, source_type = "official_table", notes) {
  n <- length(values); x <- blank("outputs.csv", n)
  x$type <- type; x$measure <- measure; x$year <- rep(years, length.out = n)
  x$age <- number(rep(ages, each = length(years), length.out = n))
  x$season <- rep(seasons, each = length(years), length.out = n)
  x$age_group <- ifelse(x$age == "4", "4+", "")
  x$value <- number(as.vector(values)); x$unit <- unit; x$sex <- "combined"; x$region <- "Sandeel Area 3r"
  x$source_type <- source_type; x$source_reference <- paste(report_url, table, sep = "; "); x$notes <- notes; x
}
outputs <- rbind(
  output("numbers_at_age", N, 0:4, c("2", rep("1", 4)), "thousand fish", "Table 9.4.9, pp. 560-561", "population",
    notes = "Age 0 is July recruitment; ages 1-4+ are January states. These are not one simultaneous five-age surface. Do not sum the July recruits with January adult numbers."),
  output("fishing_mortality_at_age", F[, 1:5], 0:4, "annual", "per year", "Table 9.4.6, pp. 554-555", "mortality",
    notes = "Annual cumulative F, equal to the sum of seasonal F to their reported precision. Age-0 F is zero in the fitted model; ages 3 and 4+ share selectivity."),
  output("fishing_mortality_at_age", Fs, rep(1:4, 2), rep(c("1", "2"), each = 4), "per half-year", "Table 9.4.7, pp. 556-557", "mortality",
    notes = "Integrated seasonal F, not an annualized rate. Annual and seasonal F are alternative reporting surfaces, not additive across representations."),
  output("total_biomass", summary[, 2], seasons = "1", unit = "tonnes", table = "Table 9.4.10, pp. 562-563", type = "biomass", notes = "January total biomass; excludes the later July recruits."),
  output("predicted_catch", summary[, 4], seasons = "annual", unit = "tonnes", table = "Table 9.4.10, pp. 562-563, Yield column", type = "catch", notes = "Native conditional predicted Catchtot, summed only where source observed and predicted catch cells are positive (declared smsR.cpp catch-likelihood loop). This is not unrestricted all-age predicted yield or observed SAG catch. Age-0 F is zero. Printed zeros and unresolved native selection/count differences prevent recovering the exact positive-cell mask; reported values are retained unchanged."),
  output("total_abundance", rowSums(N[, 2:5]), seasons = "1", unit = "thousand fish", table = "Sum of Table 9.4.9 January ages 1-4+", type = "population", source_type = "derived_source_output",
    notes = "January abundance summed over ages 1-4+, without adding the July age-0 state. Derived from reported N, with no joint uncertainty available."))
for (measure in c("SSB", "recruitment", "Fbar")) {
  point <- switch(measure, SSB = summary[, 3], recruitment = N[, 1], Fbar = F[, 6])
  columns <- switch(measure, SSB = c("Low SSB", "High SSB"), recruitment = c("Low Recruitment", "High Recruitment"), Fbar = c("Low F", "High F"))
  x <- output(measure, point, if (measure == "recruitment") 0 else NA,
    if (measure == "recruitment") "2" else if (measure == "SSB") "1" else "annual",
    switch(measure, SSB = "tonnes", recruitment = "thousand fish", Fbar = "per year"),
    "Tables 9.4.6, 9.4.9-9.4.10; SAG 21282 published bounds", switch(measure, SSB = "biomass", recruitment = "recruitment", Fbar = "mortality"),
    notes = "Point estimate from the matching report table, with published SAG limits retained. SAG labels lower/upper limits without specifying their level/construction on the data page; no SE inferred. Fbar uses arithmetic ages 1-2, SSB is January, and recruitment is age 0 in July. No cohort-year shift is applied.")
  x$lwr <- number(historical[[columns[1]]]); x$upr <- number(historical[[columns[2]]])
  x$source_reference <- paste(x$source_reference, sag_url, sep = "; ")
  if (measure == "Fbar") x$age_group <- "1-2"
  outputs <- rbind(outputs, x)
}
assumption <- function(component, setting, value, reference, notes = "") {
  x <- blank("assumptions.csv"); x$component <- component; x$setting <- setting
  x$value <- value; x$source_reference <- reference; x$notes <- notes; x
}
native <- paste0(repo_url, "/blob/", revision, "/2026_san.sa.3r_assessment/data.R")
assumptions <- rbind(
  assumption("assessment", "official_run", "2026 HAWG Area 3r SMS-effort assessment through 2025", paste(report_url, "section 10.4 and Tables 9.4.1-9.4.10;", sag_url), "SAG R and SSB match all 39 historical report values. The broad Charbonneau North Sea row is not a one-to-one identity for this regional stock."),
  assumption("population", "dimensions", "1987-2025; ages 0-4+; two half-years; one area, combined sexes and fishery", native, "The outer loader requests 1986-2025, but startYear=1987 and the published state tables establish the fitted window. No 1986 observation is invented."),
  assumption("population", "recruitment_and_aging", "Recruitment enters July at age 0; ages advance at January boundary", paste(native, "recseason=2; pinned smsR.cpp Nsave recursion"), "January ages 1-4+ and July age 0 are reported together but refer to different dates."),
  assumption("population", "initial_state", "Four freely estimated log initial January abundance states at ages 1-4+", paste("smsR", software_revision, "R/getParms.R logNinit; src/smsR.cpp")),
  assumption("N", "process", "Deterministic older-cohort survival with seasonal F+M", paste("smsR", software_revision, "src/smsR.cpp Nsave recursion")),
  assumption("recruitment", "model", "Hockey-stick expected July recruitment; fixed breakpoint 72713 t; SR likelihood weight 0.05", native, "Annual July recruitments are estimated; the SR contribution is downweighted. Exact production raw arrays and fitted object are unavailable."),
  assumption("F", "effort_and_blocks", "F proportional to seasonal standardized effort with constant age/season coefficients, no time blocks or technical creep; ages 3-4+ share selectivity", native, "isFseason=c(1,0) is a normalization rather than an instruction to turn off all second-half fishing."),
  assumption("F", "effort_gap", "Second-half 2007 and 2022 effort rows are absent; direct annual effort is reported", paste(report_url, "Tables 9.1.5-9.1.7"), "No seasonal value is reconstructed or replaced by zero. Annual totals and first-half values remain separate native records."),
  assumption("F", "known_zero_year", "Effort, catch and F are zero in 2025 under a zero TAC", paste(report_url, "section 10.4.5.1 and Tables 9.1.5, 9.4.1, 9.4.6-9.4.7"), "A log-F surface constrained to finite parameters cannot represent this exact structural zero. Preserve the zero source values; do not add pseudo-effort or positive catches."),
  assumption("catch", "likelihood", "Lognormal positive numbers-at-age, ages 1-4+ in both half-years; SD groups ages 1-2 and 3-4+ within season", paste(native, "; Table 9.4.5"), "Published rounded C has 240 positive eligible cells; model reports 244. Native zero-catch flags and exact selected cells were not recovered; no source value is changed to reconcile them."),
  assumption("catch", "data_role", "SAG all-age observed catches and tabled model-predicted yield are different quantities", paste(sag_url, "; Table 9.4.10"), "Age-0 catches are retained in the source record but excluded from the production likelihood. Native Catchtot is conditional on positive observed/predicted cells, not unrestricted predicted yield; the exact mask is unresolved where rounded source counts disagree with native observation counts."),
  assumption("M", "model", "Fixed supplied, time-varying age/season-specific multispecies M; annual hazards sum both seasons", paste(report_url, "10.4.4, Table 9.4.8; pinned smsR.cpp"), "These are supplied annual/seasonal matrices, not estimated M states in this assessment. Do not multiply integrated half-year hazards by one-half again."),
  assumption("biology", "weights_and_maturity", "Reported half-year catch and stock weights in grams; seasonal maturity; source propM=propF=0", paste(report_url, "Tables 9.4.2-9.4.3;", native, "; pinned get_tmb_parameters.R defaults")),
  assumption("index", "Dredge_sampling_interval", "Average abundance over fractions 0.75-1 of season 2, equivalent to annual interval 0.875-1", paste(native, "; pinned smsR.cpp survey equation"), "Survey age 0-1. A point-time midpoint would approximate the source's integrated prediction."),
  assumption("index", "Acoustic_sampling_interval", "Average abundance over fractions 0.5-0.7 of season 1, equivalent to annual interval 0.25-0.35", native, "Acoustic ages 1-4+ are separate observations. Sharing q for ages 3-4+ does not pool their observed index values."),
  assumption("index", "q_and_SD_sharing", "Dredge q and SD separate at ages 0 and 1; Acoustic q separate at ages 1, 2 and shared 3-4+, with one SD shared over ages 1-4+", native),
  assumption("assessment", "remaining_sources", "Native folder 3r, zero-catch flags and fitted sas.rds are not in the public pinned repository", paste(repo_url, "/tree/", revision, "; boot/DATA.bib source=folder"), "Tables preserve substantial rounded arrays but do not certify a complete native likelihood reconstruction. The older smsR package example is not substituted for 2026 inputs. Published data.R uses surveySD/catchSD/estSD, whereas the declared pinned builder accepts surveyCV/catchCV/estCV without these aliases. Exact production builder revision remains unverified."),
  assumption("forecast", "recruitment_averaging_windows", "Summary uses geometric mean 1987-2025, 75267201 thousand; configured forecast uses 1987-2024, 79171378 thousand", paste(report_url, "Tables 9.4.10-9.4.11;", sag_url, "; pinned report.R, getSummary and getForecastTable"), "Different averaging windows explain the future values. The narrative names 1987-2022 instead, so configuration and numerical values are retained with that discrepancy documented. SSB in 2026 is 35045 tonnes. Future assumptions are not historical observations."))
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2026; assessment$terminal_year <- 2025; assessment$estimate_terminal_year <- 2026
assessment$assessment_type <- "annual"; assessment$model_family <- "SMS-effort (smsR)"
assessment$model_version <- paste("Declared smsR 0.0.0.9000", software_revision)
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2023
assessment$assessment_url <- report_url; assessment$framework_url <- "https://doi.org/10.17895/ices.pub.21581151.v2"
assessment$data_url <- sag_url; assessment$model_url <- assessment$repository_url <- repo_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Verified regional 3r production assessment, distinct from the ambiguous broad North Sea catalogue entry and other sandeel areas. Published half-year input arrays and historical N/F/SSB/R are recovered; exact native data folder, selected catch cells, zero-catch flags and fitted object are missing. January adults and July recruits are not one simultaneous population vector. Zero effort/catch/F in 2025 are preserved. Forecast recruitment uses a separately documented averaging window; the exact production builder revision is unverified."
stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$authority <- "ICES"; stock$authority_stock_id <- "san.sa.3r"
stock$scientific_name <- "Ammodytes spp."; stock$common_name <- "Sandeel, Area 3r"
stock$area <- "Sandeel Area 3r, ICES divisions 4.a-b and Subdivision 20"; stock$region <- "Skagerrak, northern and central North Sea"; stock$ocean <- "Northeast Atlantic"
stock$notes <- "Current regional production unit within the broad North Sea sandeel catalogue frame ICES-HAWG_dubius_NS. That legacy identifier does not establish a one-to-one match to Area 3r and is not assigned to this regional stock. Official taxonomy is Ammodytes spp.; the catalogue's Ammodytes dubius label is not silently carried into production records. Other sandeel areas require separate assessments."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
parent <- stocks[stocks$stock_id == catalogue_id, ]; stopifnot(nrow(parent) == 1L)
link <- "Additional verified regional record: ices_sandeel_area_3r (san.sa.3r). This broad legacy North Sea entry does not establish a one-to-one regional match; regional observations are not silently pooled here."
if (!grepl(link, parent$notes, fixed = TRUE)) parent$notes <- paste(parent$notes, link)
write_rows <- function(file, x, id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size)); lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', id, '",')))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  tmp <- tempfile(tmpdir = database); on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    if (!identical(selected, seq.int(min(selected), max(selected)))) cli::cli_abort("Existing rows for {id} in {file} are not contiguous.")
    replacement <- paste0(replacement, if (endsWith(lines[selected[1L]], "\r")) "\r" else "")
    lines <- c(head(lines, min(selected) - 1L), replacement, tail(lines, length(lines) - max(selected)))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", parent, catalogue_id); write_rows("stocks.csv", stock, stock_id)
for (file in c("assessments", "assumptions", "inputs", "outputs")) {
  write_rows(paste0(file, ".csv"), if (file == "assessments") assessment else get(file), assessment_id)
}
cat("Imported Area 3r 2026:", nrow(inputs), "inputs,", nrow(assumptions), "assumptions,", nrow(outputs), "outputs; all statuses partial.\n")
