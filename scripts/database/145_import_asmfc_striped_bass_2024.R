base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_nefsc_garmiii_saxatilis_gom_chatt")
assessment_id <- "asmfc_striped_bass_atlantic_2024"
stock_id <- "ck_nefsc_garmiii_saxatilis_gom_chatt"
report_url <- "https://asmfc.org/wp-content/uploads/2025/01/2024_AtlStripedBassAssessmentUpdate.pdf"
appendix_url <- "https://asmfc.org/wp-content/uploads/2025/01/2024_AtlStripedBassAssessmentUpdate_Appendices2-4.pdf"
framework_url <- "https://doi.org/10.25923/nhqe-jd35"
read_pdf <- function(file, hash) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256") != hash) cli::cli_abort("Cache and verify the reviewed source {file} before importing.")
  pdftools::pdf_text(path)
}
report <- read_pdf("official_2024_update.pdf", "a54ef7380b1bca85391f2a2ba19ab33cfdac88923016fde76e14e4a625ce4e15")
appendix <- read_pdf("official_2024_appendices.pdf", "a2eb16b77e0629a359d08b38c149c03913a25cdcb0541641560bca58537e3701")
stopifnot(grepl("Base Run", appendix[8], fixed = TRUE),
  grepl("no separate 2023 block", appendix[8], fixed = TRUE))
years <- 1982:2023; ages <- 1:15
annual <- function(text, columns) {
  lines <- strsplit(text, "\n")[[1L]]
  lines <- trimws(lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)])
  cells <- strsplit(gsub(",", "", lines, fixed = TRUE), "[[:space:]]+")
  if (!length(cells) || any(lengths(cells) != columns + 1L)) cli::cli_abort("Unexpected source table width.")
  x <- do.call(rbind, lapply(cells, as.numeric))
  stopifnot(all(is.finite(x)), identical(as.integer(x[, 1]), years))
  x[, -1, drop = FALSE]
}
catch <- annual(report[15], 3L)
N <- annual(appendix[54], 17L)
F <- lapply(51:53, function(i) annual(appendix[i], 15L))
mature_biomass <- annual(appendix[55], 16L)
ssb <- annual(appendix[56], 3L)
full_F <- annual(appendix[49], 9L)
summary <- annual(report[19], 5L)
biology_lines <- strsplit(report[18], "\n")[[1L]]
biology_lines <- trimws(biology_lines[grepl("^\\s*[0-9]{1,2}\\+?\\s+", biology_lines, perl = TRUE)])
biology <- do.call(rbind, lapply(strsplit(gsub("+", "", biology_lines, fixed = TRUE), "[[:space:]]+"), as.numeric))
stopifnot(identical(dim(biology), c(15L, 4L)), identical(as.integer(biology[, 1]), ages),
  max(abs(catch[, 1] + catch[, 2] - catch[, 3])) <= 1,
  max(abs(F[[1]] + F[[2]] - F[[3]])) <= .00015 + 1e-12,
  identical(years[ssb[, 1] != summary[, 3]], c(2006L, 2021L)),
  identical(as.numeric((ssb[, 1] - summary[, 3])[ssb[, 1] != summary[, 3]]), c(-1, 1)),
  max(abs(ssb[, 1] - mature_biomass[, 16])) <= 1,
  max(abs(N[, 16] / 1e6 - summary[, 4])) <= .05,
  max(abs(N[, 1] / 1e6 - summary[, 2])) <= .05,
  max(abs(N[, 17] / 1e6 - summary[, 5])) <= .05,
  max(abs(full_F[, 7] - summary[, 1])) <= .005 + 1e-12)
# N components have six significant digits; published totals retain more precision.
n_rounding <- .5 * 10^(floor(log10(N[, 1:15])) - 5)
stopifnot(all(abs(rowSums(N[, 1:15]) - N[, 16]) <= rowSums(n_rounding) + .5),
  all(abs(rowSums(N[, 8:15]) - N[, 17]) <= rowSums(n_rounding[, 8:15]) + .5),
  all(abs(rowSums(mature_biomass[, 1:15]) - mature_biomass[, 16]) <= 15 * .5 + .05),
  all(abs(ssb[, 2] / ssb[, 1] - ssb[, 3]) <= .0006))
blank <- function(file, n) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  out <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(out) <- fields; out$assessment_id <- assessment_id
  out
}
number <- function(x) format(x, digits = 15, trim = TRUE, scientific = FALSE)
input <- function(type, measure, basis, value, unit, year = NA, age = NA,
                  fleet = "", sex = "", reference, notes) {
  n <- length(value); out <- blank("inputs.csv", n)
  out$type <- type; out$measure <- measure; out$basis <- basis
  out$value <- number(value); out$unit <- unit
  out$year <- ifelse(is.na(rep_len(year, n)), "", rep_len(year, n))
  out$year_basis <- ifelse(nzchar(out$year), "calendar_year", "")
  out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$fleet <- fleet; out$sex <- sex; out$source_type <- "official_table"
  out$source_reference <- paste(report_url, reference, sep = "; "); out$notes <- notes
  out
}
inputs <- rbind(
  input("catch", "total_numbers", "numbers", as.vector(catch[, 1:2]), "fish",
    rep(years, 2), fleet = rep(c("Chesapeake Bay", "Ocean"), each = length(years)),
    reference = "Table 1, printed p. 10", notes = "Native fleet total removals, including harvest and dead discards/releases. Source fits totals plus number compositions. No age proportions or catch-at-age are reconstructed from fitted outputs. The separately printed combined total is not another fleet; component sums differ from it by at most one fish due to rounding."),
  input("maturity", "maturity_at_age", "proportion", biology[, 2], "proportion", age = ages,
    sex = "female", reference = "Table 4, printed p. 13", notes = "Fixed female maturity vector; age 15 denotes 15+. Female fraction is recorded separately and must be included when calculating female SSB from both-sex N."),
  input("biology", "proportion_female_at_age", "proportion", biology[, 3], "proportion", age = ages,
    reference = "Table 4, printed p. 13", notes = "Fixed female fraction of the both-sex population, separate from female maturity; age 15 denotes 15+."),
  input("M", "natural_mortality_at_age", "per_year", biology[, 4], "per year", age = ages,
    reference = "Table 4, printed p. 13", notes = "Fixed age-specific M as printed to two decimals; age 15 denotes 15+. Not an estimated M output."))
output <- function(type, measure, value, unit, year = years, age = NA, group = "",
                   fleet = "", sex = "", se = NA, source_type = "official_table", reference, notes) {
  n <- length(value); out <- blank("outputs.csv", n)
  out$type <- type; out$measure <- measure; out$value <- number(value); out$unit <- unit
  out$year <- rep_len(year, n); out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$age_group <- group; out$fleet <- fleet; out$sex <- sex
  out$se <- ifelse(is.na(rep_len(se, n)), "", number(rep_len(se, n)))
  out$source_type <- source_type; out$source_reference <- paste(appendix_url, reference, sep = "; ")
  out$notes <- notes
  out
}
g <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
terminal_group <- ifelse(g$age == 15, "15+", "")
outputs <- output("population", "numbers_at_age", as.vector(N[, 1:15]), "fish", g$year, g$age,
  group = terminal_group, reference = "Appendix 3 base run, Table X6, PDF p. 54",
  notes = "Beginning-of-year, both-sex N; printed at about six significant digits. The terminal age is 15+. No uncertainty supplied. Sensitivity-run Table X6 on PDF p. 115 is excluded.")
for (i in 1:3) outputs <- rbind(outputs,
  output("mortality", "fishing_mortality_at_age", as.vector(F[[i]]), "per year", g$year, g$age,
    group = terminal_group, fleet = c("Chesapeake Bay", "Ocean", "")[i],
    reference = paste0("Appendix 3 base run, Table X5, PDF p. ", 50 + i),
    notes = "Reported instantaneous F, rounded to four decimals. Fleet components and their total are separate overlapping outputs, not additive across all three series. Caption says 1982-2021, but the published rows extend through 2023. No uncertainty supplied."))
outputs <- rbind(outputs,
  output("biomass", "mature_biomass_at_age", as.vector(mature_biomass[, 1:15]), "tonnes", g$year, g$age,
    group = terminal_group, sex = "female", reference = "Appendix 3 base run, Table X7, PDF p. 55",
    notes = "Native female spawning-biomass contribution by age, not a biological weight input. Age cells are rounded to whole tonnes; the separately reported total has greater precision. No age-specific uncertainty supplied."),
  output("biomass", "SSB", ssb[, 1], "tonnes", sex = "female", se = ssb[, 2],
    reference = "Appendix 3 base run, Table X8, PDF p. 56", notes = paste0("Native female SSB. Natural-scale SE in tonnes, not CV; reported CV = ", ssb[, 3], ". No confidence bounds tabulated. The point estimate is rounded to whole tonnes.")),
  output("biomass", "SSB_age_table_total", mature_biomass[, 16], "tonnes", sex = "female",
    reference = "Appendix 3 base run, Table X7, Total column, PDF p. 55",
    notes = "Native female SSB total printed to 0.1 tonnes in the age table. Retained separately from the whole-tonne Table X8 point estimate and its SE; published values differ by up to 0.6 tonnes. No SE is moved between definitions."),
  output("population", "total_numbers", N[, 16], "fish", reference = "Appendix 3 base run, Table X6, Total column, PDF p. 54",
    notes = "Reported beginning-of-year total over ages 1-14 and 15+, both sexes. Original total retained; sums of rounded age cells can differ. No joint uncertainty supplied."),
  output("population", "total_numbers_age8plus", N[, 17], "fish", group = "8+",
    reference = "Appendix 3 base run, Table X6, 8+ column, PDF p. 54", notes = "Native total of ages 8 and older; not an age-8-only estimate. No uncertainty supplied."),
  output("recruitment", "recruitment", N[, 1], "fish", age = 1,
    reference = "Appendix 3 base run, Table X6, age-1 column, PDF p. 54", notes = "Reported same-year age-1 abundance, retaining greater precision than the main report's rounded million-fish summary. No recruitment SE supplied."))
for (i in 1:3) outputs <- rbind(outputs,
  output("mortality", "Ffull", full_F[, (i - 1) * 3 + 1], "per year", fleet = c("Chesapeake Bay", "Ocean", "")[i],
    se = full_F[, (i - 1) * 3 + 2], reference = "Appendix 3 base run, Table X4, PDF p. 49",
    notes = paste0("Reported fully-recruited F, not an age-averaged Fbar. Natural-scale standard error (column SD; table title identifies standard errors); reported CV = ",
      full_F[, (i - 1) * 3 + 3], ". Fully selected ages vary with fleet/time block. No intervals tabulated.")))
assumption <- function(component, setting, value, notes, reference = "Main report Tables 2-4; Appendix 2") {
  out <- blank("assumptions.csv", 1)
  out$component <- component; out$setting <- setting; out$value <- value
  out$source_reference <- paste(report_url, appendix_url, reference, sep = "; ")
  out$notes <- notes
  out
}
assumptions <- rbind(
  assumption("population", "years_ages_and_sexes", "1982-2023; ages 1-15+; both-sex abundance, female SSB", "Native source initial abundance follows an exponential/cohort construction, with a terminal plus group."),
  assumption("N", "recruitment_process", "IID normal log recruitment deviations, constrained to sum zero", "Appendix 2 also describes a bias constraint and a first-recruit penalty."),
  assumption("N", "survival_process", "Deterministic cohort survival after recruitment", "No independent older-cohort process variance is identified in the published model equations."),
  assumption("F", "fleet_structure", "Separate Chesapeake Bay and Ocean F and selectivity", "Bay: 1982-1984, 1985-1989, 1990-1995, 1996-2019, 2020-2023. Ocean: 1982-1984, 1985-1989, 1990-1996, 1997-2019, 2020-2023. The separate-2023-block sensitivity is excluded."),
  assumption("M", "fixed_age_specific_M", "Fixed vector from main Table 4", "Natural mortality is a source biological input, not an estimated output."),
  assumption("catch", "observation_model", "Fleet totals with concentrated lognormal likelihood; multinomial number compositions", "Annual fleet CVs, CV weights and Francis-adjusted effective sample sizes enter separately. Numerical compositions and annual CV inputs are unrecovered."),
  assumption("index", "survey_inventory", "Six young-fish indices and eight indices with age composition", "Main Table 2 includes seven fishery-independent age-1+ surveys and MRIP CPUE. MD and VA YOY are combined for the Chesapeake Bay composite. Exact native observation arrays, annual CVs and current timing arrays are unrecovered."),
  assumption("index", "framework_timing_and_age_links", "NYOHS 0.75 (2-13+); NJ Trawl 0.25 (2-15+); MDSSN 0.25 (2-15+); DESSN 0.25 (2-13+); MRIP 0.50 (1-15+); CT Trawl 0.33 (1-15+); DE30FT 0.90 (1-15+); ChesMMAP 0.50 (1-15+)", "Framework Appendix B10 Table 3, PDF p. 1103. The 2024 report retains the framework parameterization; native current arrays are unavailable. These are source-model mortality fractions, not inferred season midpoints. Grouped 13+ observations must not be treated as single-age-13 data.", framework_url),
  assumption("index", "young_index_alignment", "Framework links YOY indices to January-1 age 1 and age-1 indices to January-1 age 2", "Framework Table 3 labels VA Age 1 where its diagnostics and the current report name NY Age 1. Exact current series identity and calendar-year/cohort mapping require native files; no observation-year shift is invented.", framework_url),
  assumption("biology", "female_SSB_definition", "January-1 N times female fraction, female maturity and year-age weights, divided by 1000 for tonnes", "Framework Appendix B10 Table 1 contains no additional survival-to-spawning multiplier. Fixed female fraction and maturity are separate inputs. Annual weights remain unrecovered; fitted SSB-at-age is not substituted as a weight input.", framework_url),
  assumption("assessment", "source_limits", "Native 2024 inputs/configuration unavailable; reported model equation needs implementation verification", "The printed catch equation appears to mix fleet and total F in its denominator and survival term. Do not infer a corrected implementation without the production code. The public 30-year SE-model-performance simulation is not this 42-year production assessment."))
assessment <- blank("assessments.csv", 1)
assessment$stock_id <- stock_id; assessment$assessment_year <- 2024
assessment$terminal_year <- assessment$estimate_terminal_year <- 2023
assessment$assessment_type <- "update"; assessment$model_family <- "Statistical catch-at-age"
assessment$model_version <- "2018 single-stock benchmark; official 2024 base update, no separate 2023 selectivity block"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2018
assessment$assessment_url <- report_url; assessment$framework_url <- framework_url
assessment$data_url <- appendix_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Official base outputs and fixed biology recovered. Raw catch/survey compositions, annual weights, observation CV arrays and native configuration remain unavailable. Current model is coastwide with Bay/Ocean fleets; newer projection updates are not new fitted historical assessments. No fit is claimed and simulation-study files are not used as production observations."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
at <- which(stocks$stock_id == stock_id)
stopifnot(length(at) == 1L, stocks$charbonneau_id[at] == "NEFSC-GARMIII_saxatilis_GOM, CHATT")
stocks$authority[at] <- "ASMFC"; stocks$authority_stock_id[at] <- "Atlantic coastwide striped bass"
stocks$common_name[at] <- "Atlantic striped bass"; stocks$scientific_name[at] <- "Morone saxatilis"
stocks$area[at] <- "U.S. Atlantic coast, including Chesapeake Bay and Ocean modeled fleets"
stocks$region[at] <- "U.S. Atlantic coast"; stocks$ocean[at] <- "Northwest Atlantic"
stocks$notes[at] <- "Charbonneau-Keith NEFSC-GARMIII_saxatilis_GOM, CHATT; historical GOM/CHATT label retained in the identifier. Verified production assessment is the ASMFC coastwide single-stock model with Bay/Ocean fleets, not a Gulf-of-Maine-only population or a simulation study. Raw production age observations and weights remain missing."
write_rows <- function(file, x, id = assessment_id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', id, '",')))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  tmp <- tempfile(tmpdir = database); on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    if (!identical(selected, seq.int(min(selected), max(selected)))) cli::cli_abort("Existing {file} rows are not contiguous; review before replacing.")
    replacement <- paste0(replacement, if (endsWith(lines[selected[1L]], "\r")) "\r" else "")
    lines <- c(head(lines, min(selected) - 1L), replacement, tail(lines, length(lines) - max(selected)))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", stocks[at, ], stock_id)
write_rows("assessments.csv", assessment)
write_rows("assumptions.csv", assumptions)
write_rows("inputs.csv", inputs)
write_rows("outputs.csv", outputs)
cat("Imported ASMFC striped bass 2024:", nrow(inputs), "inputs,", nrow(assumptions), "assumptions and", nrow(outputs), "outputs; statuses remain partial.\n")
