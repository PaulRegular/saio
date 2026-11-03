base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_hawg_dubius_ns/2025_san.sa.4")
assessment_id <- "ices_sandeel_area_4_2025"
stock_id <- "ices_sandeel_area_4"
catalogue_id <- "ck_ices_hawg_dubius_ns"
report_url <- "https://doi.org/10.17895/ices.pub.28389008.v5"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19335"
repo_url <- "https://github.com/ices-advice/2025_san.sa.4"
revision <- "5ccb6abb2595153a88c9c47ad628ad17f3ea3e06"
software_revision <- "a097011f2fff959c9a263e5f6acb49795b9a53ad"
verify <- function(file, expected) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256") != expected) cli::cli_abort("Cache and verify {file} before importing this assessment.")
  path
}
pages <- pdftools::pdf_text(verify("HAWG_2025.pdf", "06967082a29ef54ffb33ce7d2e8f89a4695dd6d1ca70f3e78510c03c6c813097"))
settings <- readLines(verify("data.R", "680bdc6e76af4341905d23cf4411f08456edafe2eebb15ffe5e717c2188125be"))
software <- readLines(verify("../../ices_sandeel_area_1r_2026/get_tmb_parameters.R", "1dcd5b4699418b755fc163a2647e1d576f31496ecfa13a95f7959ced47b09205"))
sag_path <- verify("SAG_19335.html", "43550ab06121ae14a096a6ca1949a74b72764989fba2d8c46c2a5b104ace13ee")
stopifnot(any(grepl("years <- 1993:2024", settings, fixed = TRUE)),
  any(grepl("CminageSeason = c(1, 1)", settings, fixed = TRUE)),
  any(grepl("estCV = c(0, 2, 0)", settings, fixed = TRUE)),
  any(grepl("propM <- array(0", software, fixed = TRUE)),
  any(grepl("propF <- array(0", software, fixed = TRUE)))

years <- 1993:2024
annual <- function(text, columns, effort_column = NULL, missing_years = integer()) {
  lines <- strsplit(paste(text, collapse = "\n"), "\n")[[1L]]
  lines <- trimws(lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]", lines)])
  cells <- strsplit(lines, "[[:space:]]+")
  at <- as.integer(vapply(cells, `[[`, character(1), 1L)) %in% years
  cells <- cells[at]
  if (!is.null(effort_column)) {
    cells <- lapply(cells, function(z) z[c(1, effort_column)])
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
C <- annual(pages[618:619], 10L)
W <- annual(pages[620:621], 9L)
mat <- annual(pages[622:623], 9L)
M <- annual(pages[630:631], 9L)
F <- annual(pages[626:627], 6L)
Fs <- annual(pages[628:629], 8L)
N <- annual(pages[632:633], 5L)
summary <- annual(pages[634:635], 5L)
effort <- matrix(NA_real_, length(years), 3L)
effort[, 1] <- annual(pages[557:558], 1L, effort_column = 5L)[, 1L]
has_second <- !years %in% c(2007L, 2022L)
# Table 9.1.7 reverses the Area 4/5r headers: verify both independent totals.
effort[has_second, 2] <- annual(pages[559:560], 1L, effort_column = 6L,
  missing_years = c(2007L, 2022L))[, 1L]
effort[, 3] <- annual(pages[555:556], 1L, effort_column = 5L)[, 1L]
area5_annual <- annual(pages[555:556], 1L, effort_column = 6L)[, 1L]
area5_first <- annual(pages[557:558], 1L, effort_column = 6L)[, 1L]
area5_second <- annual(pages[559:560], 1L, effort_column = 5L,
  missing_years = c(2007L, 2022L))[, 1L]
stopifnot(max(abs(effort[has_second, 3] - effort[has_second, 1] - effort[has_second, 2])) <= 1,
  max(abs(area5_annual[has_second] - area5_first[has_second] - area5_second)) <= 1)

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
  sum(C[, c(2:5, 7:10)] > 0) == 132L)
biomass_error <- rowSums(N[, 2:5] * .005 + .5 * W[, 1:4] + .5 * .005) / 1000 + .5
ssb_error <- rowSums(N[, 2:5] * (.005 * mat[, 1:4] + .005 * W[, 1:4] + .005^2) +
  .5 * (W[, 1:4] + .005) * (mat[, 1:4] + .005)) / 1000 + .5
stopifnot(all(abs(rowSums(N[, 2:5] * W[, 1:4]) / 1000 - summary[, 2]) <= biomass_error),
  all(abs(rowSums(N[, 2:5] * W[, 1:4] * mat[, 1:4]) / 1000 - summary[, 3]) <= ssb_error))
fraction <- function(f, m) f / (f + m) * (-expm1(-f - m))
f1 <- Fs[, 1:4]; f2 <- Fs[, 5:8]; m1 <- M[, 1:4]; m2 <- M[, 6:9]
c1 <- C[, 2:5] > 0; c2 <- C[, 7:10] > 0
yield_lower <- rowSums((N[, 2:5] - .5) * (
  fraction(pmax(0, f1 - .0005), m1 + .005) * (W[, 1:4] - .005) * c1 +
  exp(-f1 - .0005 - m1 - .005) * fraction(pmax(0, f2 - .0005), m2 + .005) * (W[, 6:9] - .005) * c2)) / 1000
yield_upper <- rowSums((N[, 2:5] + .5) * (
  fraction(f1 + .0005, m1 - .005) * (W[, 1:4] + .005) * c1 +
  exp(-pmax(0, f1 - .0005) - m1 + .005) * fraction(f2 + .0005, m2 - .005) * (W[, 6:9] + .005) * c2)) / 1000
stopifnot(all(summary[, 4] + .5 >= yield_lower), all(summary[, 4] - .5 <= yield_upper),
  abs(exp(mean(log(N[, 1]))) - 49075026) < 1,
  abs(exp(mean(log(N[years %in% 2014:2023, 1]))) - 53694268) < 1)

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
  x$region <- "Sandeel Area 4"; x$fleet <- if (type %in% c("catch", "catch_weight", "covariate")) "Combined commercial fishery" else ""
  x$survey <- survey; x$source_type <- "official_table"
  x$source_reference <- paste(report_url, table, sep = "; "); x$notes <- notes; x
}
age_season <- c(1:4, 0:4); seasons <- c(rep("1", 4), rep("2", 5))
inputs <- rbind(
  input("catch", "numbers_at_age", "numbers", C, rep(0:4, 2), rep(c("1", "2"), each = 5), "million fish", "Table 9.5.1, printed pp. 596-597",
    "Reported catch numbers by half-year, retaining zeros and age-0 values. The production model excludes age 0 in both seasons. All 132 positive cells at ages 1-4+ match the likelihood count. Zero-coded age counts can coexist with positive SAG total catches and positive F; do not interpret them as proof of zero landings or replace them with reconstructed age counts. Native zero-catch flags are unavailable."),
  input("weight", "weight_at_age", "g_per_fish", W, age_season, seasons, "g per fish", "Table 9.5.2, printed pp. 598-599",
    "Source gives the same weight in catch and stock, by half-year. Age 4 is 4+. No first-half age-0 weight is supplied; no value is invented."),
  input("catch_weight", "weight_at_age", "g_per_fish", W, age_season, seasons, "g per fish", "Table 9.5.2, printed pp. 598-599",
    "Same published catch/stock weights, retaining the catch-weight role. No annual mean or source-fitted weighting is substituted."),
  input("maturity", "maturity_at_age", "proportion", mat, age_season, seasons, "proportion", "Table 9.5.3, printed pp. 600-601",
    "Seasonal supplied maturity; age 4 denotes 4+. Source SSB uses January abundance and first-half weights/maturity, with propM=propF=0 in the pinned native configuration."),
  input("M", "natural_mortality_at_age", "per_season", M, age_season, seasons, "per half-year", "Table 9.5.8, printed pp. 608-609; pinned smsR source Nsave recursion",
    "Externally supplied long-term-average multispecies M, constant over historical years and printed to two decimals, entering survival as exp(-F_season-M_season). These are integrated half-year hazards, not annual rates repeated twice. Annual cohort mortality is the sum of the two seasonal values at the same age; annualization belongs in the translation."),
  input("covariate", "effort", "native_covariate", effort, NA, c("1", "2", "annual"), "fishing days (standard 200 GT vessel)", "Tables 9.1.5-9.1.7, printed pp. 533-538",
    "Native annual and half-year fishing effort. Constant age/season coefficients relate F to effort, without technical creep. Annual and first-half columns are directly labelled Area 4. Table 9.1.7 Area 4/5r headers are reversed: the column labelled Area 5r is assigned here after verifying both areas against annual-minus-first-half totals to one rounded day. Exact native effort files remain unavailable. Second-half rows for 2007/2022 are absent, not zero."))
inputs <- inputs[!(inputs$type == "covariate" & inputs$year %in% c(2007L, 2022L) & inputs$season == "2"), ]
corrected <- inputs$type == "covariate" & inputs$season == "2"
inputs$source_type[corrected] <- "reconstructed_source_input"
inputs$transformation[corrected] <- "Reassign the printed Table 9.1.7 Area-5r numerical column to Area 4. The reversed pair restores both independent annual = first + second identities within rounding; numerical values are unchanged."

survey_text <- pages[624]
for (survey in c("Dredge", "Dredge2")) {
  lines <- strsplit(survey_text, "\n")[[1L]]
  lines <- trimws(lines[grepl(paste0("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", survey, "[[:space:]]"), lines)])
  cells <- strsplit(lines, "[[:space:]]+")
  survey_years <- as.integer(vapply(cells, `[[`, character(1), 1L))
  values <- do.call(rbind, lapply(cells, function(z) suppressWarnings(as.numeric(z[3:4]))))
  stopifnot(identical(survey_years, if (survey == "Dredge") 1999:2003 else 2008:2024))
  x <- blank("inputs.csv", length(values))
  x$type <- "index"; x$measure <- "numbers_at_age"; x$basis <- "index_scale"
  x$year <- rep(survey_years, 2L); x$year_basis <- "calendar_year"
  x$age <- rep(0:1, each = length(survey_years)); x$value <- number(as.vector(values))
  x$survey <- survey; x$sex <- "combined"; x$region <- "Sandeel Area 4"; x$season <- "2"
  x$unit <- "number index (scaled; multiplier not stated)"
  x$source_type <- "official_table"; x$source_reference <- paste(report_url, "Table 9.5.4, p. 602; pinned data.R")
  x$notes <- "Native scaled Dredge index, ages 0-1, separate q and log-observation SD by age and era. Predictions average fractions 0.75-1 of season 2 (annual interval 0.875-1), not one exact sampling_time. Age 0 is July recruitment. The source dash at Dredge age 1 in 2003 is missing, not zero."
  inputs <- rbind(inputs, x)
}
stopifnot(sum(inputs$type == "index" & inputs$value == "") == 1L)

x <- blank("inputs.csv", length(years)); x$type <- "catch"; x$measure <- "total_biomass"; x$basis <- "biomass"
x$year <- years; x$year_basis <- "calendar_year"; x$value <- number(historical$Catches)
x$unit <- "tonnes"; x$fleet <- "Combined commercial fishery"; x$sex <- "combined"; x$region <- "Sandeel Area 4"
x$source_type <- "official_machine_readable"; x$source_reference <- sag_url
x$notes <- "Reported all-age catches from SAG; not the model-predicted Yield in Table 9.5.10 and not an additional total-catch likelihood. Includes age-0 removals excluded from the fitted age-specific likelihood; retain separately without rescaling age counts."
inputs <- rbind(inputs, x)
output <- function(measure, values, ages = NA, seasons = "", unit, table, type, source_type = "official_table", notes) {
  n <- length(values); x <- blank("outputs.csv", n)
  x$type <- type; x$measure <- measure; x$year <- rep(years, length.out = n)
  x$age <- number(rep(ages, each = length(years), length.out = n))
  x$season <- rep(seasons, each = length(years), length.out = n)
  x$age_group <- ifelse(x$age == "4", "4+", "")
  x$value <- number(as.vector(values)); x$unit <- unit; x$sex <- "combined"; x$region <- "Sandeel Area 4"
  x$source_type <- source_type; x$source_reference <- paste(report_url, table, sep = "; "); x$notes <- notes; x
}
outputs <- rbind(
  output("numbers_at_age", N, 0:4, c("2", rep("1", 4)), "thousand fish", "Table 9.5.9, pp. 610-611", "population",
    notes = "Age 0 is July recruitment; ages 1-4+ are January states. These are not one simultaneous five-age surface. Do not sum the July recruits with January adult numbers."),
  output("fishing_mortality_at_age", F[, 1:5], 0:4, "annual", "per year", "Table 9.5.6, pp. 604-605", "mortality",
    notes = "Annual cumulative F, equal to the sum of seasonal F to their reported precision. Age-0 F is zero in the fitted model; ages 3 and 4+ share selectivity."),
  output("fishing_mortality_at_age", Fs, rep(1:4, 2), rep(c("1", "2"), each = 4), "per half-year", "Table 9.5.7, pp. 606-607", "mortality",
    notes = "Integrated seasonal F, not an annualized rate. Annual and seasonal F are alternative reporting surfaces, not additive across representations."),
  output("total_biomass", summary[, 2], seasons = "1", unit = "tonnes", table = "Table 9.5.10, pp. 612-613", type = "biomass", notes = "January total biomass; excludes the later July recruits."),
  output("predicted_catch", summary[, 4], seasons = "annual", unit = "tonnes", table = "Table 9.5.10, pp. 612-613, Yield column", type = "catch", notes = "Native model-predicted Catchtot sums only cells with positive catch observations and positive predictions (smsR.cpp catch-likelihood loop). It is not unrestricted all-age predicted yield or observed SAG catch. The conditional seasonal Baranov equation matches all 32 table values within rounding, including zero reported yield in years with some positive F."),
  output("total_abundance", rowSums(N[, 2:5]), seasons = "1", unit = "thousand fish", table = "Sum of Table 9.5.9 January ages 1-4+", type = "population", source_type = "derived_source_output",
    notes = "January abundance summed over ages 1-4+, without adding the July age-0 state. Derived from reported N, with no joint uncertainty available."))
for (measure in c("SSB", "recruitment", "Fbar")) {
  point <- switch(measure, SSB = summary[, 3], recruitment = N[, 1], Fbar = F[, 6])
  columns <- switch(measure, SSB = c("Low SSB", "High SSB"), recruitment = c("Low Recruitment", "High Recruitment"), Fbar = c("Low F", "High F"))
  x <- output(measure, point, if (measure == "recruitment") 0 else NA,
    if (measure == "recruitment") "2" else if (measure == "SSB") "1" else "annual",
    switch(measure, SSB = "tonnes", recruitment = "thousand fish", Fbar = "per year"),
    "Tables 9.5.6, 9.5.9-9.5.10; SAG 19335 published bounds", switch(measure, SSB = "biomass", recruitment = "recruitment", Fbar = "mortality"),
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
native <- paste0(repo_url, "/blob/", revision, "/2025_san.sa.4_assessment/data.R")
assumptions <- rbind(
  assumption("assessment", "official_run", "2025 HAWG Area 4 SMS-effort assessment through 2024", paste(report_url, "section 10.5, Tables 9.5.1-9.5.10;", sag_url), "All 32 historical R and SSB values match SAG. Report version 5 was published in March 2026; that is not a 2026 age-based assessment."),
  assumption("population", "dimensions", "1993-2024; ages 0-4+; two half-years; one combined-sex regional population and fishery", native),
  assumption("population", "recruitment_and_aging", "July age-0 recruitment; January aging of older cohorts", paste(native, "; pinned smsR.cpp Nsave recursion"), "January adults and July recruits are different-date states, not one simultaneous abundance surface."),
  assumption("population", "initial_state", "Four free log initial January abundance states at ages 1-4+", paste("smsR", software_revision, "R/getParms.R logNinit; src/smsR.cpp")),
  assumption("N", "process", "Deterministic older-cohort survival under seasonal F+M", paste("smsR", software_revision, "src/smsR.cpp")),
  assumption("recruitment", "model", "Hockey-stick expected July recruitment; fixed SSB breakpoint 44716 t; SR likelihood weight 0.05", native, "The breakpoint is not the recruitment plateau. Annual July states and recruitment log SD are estimated."),
  assumption("F", "effort_and_blocks", "F proportional to seasonal standardized effort; constant age/season coefficients, no technical creep or blocks; ages 3-4+ shared", native, "isFseason=c(1,0) is a normalization, not a general switch disabling second-half fishing."),
  assumption("F", "effort_header_correction", "Table 9.1.7 reverses the numerical Area-4/Area-5r columns", paste(report_url, "Tables 9.1.5-9.1.7"), "Reassigning the pair restores both areas annual-minus-first-half totals within one rounded day in all 30 available historical rows. For Area 4 in 1996 this gives 966 second-half days, also consistent with positive seasonal F; the column printed Area 4 gives zero. This is an explicitly labelled source reconstruction, not a fitted-data adjustment."),
  assumption("F", "effort_gap", "Second-half effort rows for 2007 and 2022 are absent", paste(report_url, "Table 9.1.7"), "No missing row is replaced by zero or a residual total."),
  assumption("F", "known_zero_years", "Annual F is zero in 2009 and 2024; zero-coded age counts occur in additional years with small positive F and positive SAG landings", paste(report_url, "Tables 9.5.1, 9.5.6-9.5.7;", sag_url), "Preserve source zeros without equating absent/zero-coded age data to zero total landings. A finite log-F surface cannot reproduce structural zero F."),
  assumption("catch", "likelihood", "Lognormal positive numbers at ages 1-4+ in each half-year; SD groups ages 1-2 and 3-4+ per season; catch weight 1", paste(native, "; Table 9.5.5; pinned smsR.cpp"), "All 132 positive cells agree with the diagnostic count. estCV=c(0,2,0) profiles catch log-SDs internally from residuals; they are not extra free SD parameters. The 50-parameter production diagnostic is retained without inventing a fitted object."),
  assumption("catch", "yield_reporting_mask", "Reported Catchtot is predicted catch summed only over positive-observation cells", paste(report_url, "Table 9.5.10; pinned smsR.cpp lines 973-979"), "Unmasked Baranov yield and observed C times W both differ. The positive-observation mask reconciles all 32 table values within source rounding. It explains the large apparent 1996 discrepancy and zero reported yield in some positive-F years."),
  assumption("M", "model", "Fixed supplied long-term-average multispecies M, constant through time at each age and season", paste(report_url, "10.5.4 and Table 9.5.8"), "WGSAM 2023 key run; integrated half-year hazards sum for annual survival. M is not estimated by this stock model."),
  assumption("biology", "weights_and_maturity", "Common catch/stock weights in grams by half-year; constant seasonal maturity; January SSB with propM=propF=0", paste(report_url, "Tables 9.5.2-9.5.3;", native, "; declared builder defaults")),
  assumption("index", "sampling_interval", "Both Dredge eras average abundance over fractions 0.75-1 of season 2, annual interval 0.875-1", native, "A point-time midpoint approximates the integrated prediction; source sampling_time is left blank."),
  assumption("index", "q_and_SD_sharing", "Separate q and estimated log-observation SD at ages 0 and 1 in each of two Dredge eras; survey weight 1", native, "There are 43 numerical observations in 44 reported cells. Dredge age 1 in 2003 is missing."),
  assumption("index", "SD_lower_bound", "Survey log-SDs estimated with a 0.3 lower-bound penalty; catch log-SDs profiled internally", paste(native, "; pinned get_tmb_parameters.R minSDsurvey; smsR.cpp SDS and catch SD equations"), "The three survey values printed 0.3 are boundary estimates, not fixed supplied SDs. Dredge2 age 1 is 0.8923429. Table CV labels approximate log-scale SDs; do not relabel them as exact natural-scale CVs."),
  assumption("assessment", "remaining_sources", "Native folder 4, exact zero-catch flags, unrounded arrays and fitted sas.rds absent from the public tree", paste(repo_url, "/tree/", revision), "The declared builder CV argument names are compatible with this configuration, unlike the 2026 regional SD-name snapshots. The actual fitted object/revision remains unverified; older package examples are not substituted."),
  assumption("forecast", "recruitment_averaging_windows", "Summary 2025 recruitment uses geometric mean 1993-2024, 49075026 thousand; configured forecast uses 2014-2023, 53694267-53694268 thousand", paste(report_url, "Tables 9.5.10-9.5.11;", sag_url, "; pinned report.R"), "The two reported values have different windows; future assumptions are not historical observations. Narrative forecast text also contains stale year/value references, so numerical tables and configuration are retained."),
  assumption("assessment", "newer_advice", "Separate 2026 category-5 advice exists, SAG 21271", "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21271", "The 2025 run remains the latest detailed age-based assessment recovered. Do not mix the later survey scaling/vintage or catch update into this run."))

assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2025; assessment$terminal_year <- 2024; assessment$estimate_terminal_year <- 2025
assessment$assessment_type <- "annual"; assessment$model_family <- "SMS-effort (smsR)"
assessment$model_version <- paste("Declared smsR 0.0.0.9000", software_revision)
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2023
assessment$assessment_url <- report_url; assessment$framework_url <- "https://doi.org/10.17895/ices.pub.21581151.v2"
assessment$data_url <- sag_url; assessment$model_url <- assessment$repository_url <- repo_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Latest recovered detailed age-based assessment through 2024, with January adults and July recruitment kept distinct. The 2025 report v5 was published in March 2026. Newer 2026 category-5 advice is a separate summary event. Source arrays, conditional predicted-yield reporting and the second-half effort header correction are verified; exact native files/flags and fitted object remain missing."

summary_id <- "ices_sandeel_area_4_2026_summary"
summary_assessment <- blank("assessments.csv")
summary_assessment$assessment_id <- summary_id; summary_assessment$stock_id <- stock_id
summary_assessment$assessment_year <- 2026; summary_assessment$terminal_year <- 2025
summary_assessment$assessment_type <- "summary_update"
summary_assessment$model_family <- "ICES category 5 advice"
summary_assessment$is_current <- "FALSE"; summary_assessment$is_applied <- "TRUE"
summary_assessment$assessment_url <- summary_assessment$data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21271"
summary_assessment$assumptions_status <- "partial"
summary_assessment$inputs_status <- summary_assessment$outputs_status <- "not_started"
summary_assessment$notes <- "Separate 2026 category-5 advice, with catch totals and age-0/1 Dredge custom index fields on a different numerical scale/vintage. Their exact scaling and input role are not yet audited, so no values are mixed into the 2025 age-based run. No 2026 N/F/SSB assessment surfaces are reported by this SAG entry."
summary_assumptions <- assumption("assessment", "separate_advice_vintage", "2026 category-5 advice is distinct from the 2025 age-based assessment", summary_assessment$data_url,
  "The source is cached separately. Do not use its revised catch/index values to fill gaps in the earlier run; custom index scaling/likelihood role remains unresolved.")
summary_assumptions$assessment_id <- summary_id

stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$authority <- "ICES"; stock$authority_stock_id <- "san.sa.4"
stock$scientific_name <- "Ammodytes spp."; stock$common_name <- "Sandeel, Area 4"
stock$area <- "Sandeel Area 4, ICES divisions 4.a-b"; stock$region <- "Northern and central North Sea"; stock$ocean <- "Northeast Atlantic"
stock$notes <- "Current regional production unit within the broad North Sea sandeel catalogue frame ICES-HAWG_dubius_NS. That legacy identifier does not establish a one-to-one match to Area 4 and is not assigned to this regional stock. Official taxonomy is Ammodytes spp.; the catalogue's Ammodytes dubius label is not silently carried into production records. Other sandeel areas require separate assessments."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
parent <- stocks[stocks$stock_id == catalogue_id, ]; stopifnot(nrow(parent) == 1L)
link <- "Additional verified regional record: ices_sandeel_area_4 (san.sa.4). This broad legacy North Sea entry does not establish a one-to-one regional match; regional observations are not silently pooled here."
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
write_rows("assessments.csv", summary_assessment, summary_id)
write_rows("assumptions.csv", summary_assumptions, summary_id)
cat("Imported Area 4 2025:", nrow(inputs), "inputs,", nrow(assumptions), "assumptions,", nrow(outputs), "outputs; all statuses partial.\n")
