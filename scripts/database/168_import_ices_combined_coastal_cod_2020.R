base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_afwg_morhua_coastnor_1_2/assessment_2020")
stock_id <- "ck_ices_afwg_morhua_coastnor_1_2"
id <- "ices_cod_norwegian_coastal_combined_2020"
report <- "https://doi.org/10.17895/ices.pub.6050"
sag <- "https://sag.ices.dk/SAG_API/StockXmlDownload/13720"
verify <- function(file, sha) {
  p <- file.path(cache, file)
  actual <- digest::digest(readBin(p, "raw", n = file.info(p)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, sha)) stop("Source checksum differs: ", file)
  p
}
invisible(verify("AFWG_2020.pdf", "fb5ee340332d0e077cdd273c7fe19a912ec23707d68fbaa09ef6486bbc8c2339"))
lines <- readLines(verify("tables_layout.txt", "0ec205a925a18e31e2907a3c0857ec360f14aac58265cf2248b2ab7f319df477"), encoding = "UTF-8", warn = FALSE)
xml <- xml2::read_xml(verify("SAG_2020_key_13720.xml", "9b5e12d02e48abef0fa090d946e535c2b587b7e04c5ab604018239bf3dfc2025"))
stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockCode")) == "cod.27.1-2coast",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/AssessmentYear")) == "2020",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockSizeDescription")) == "B_index")
page <- function(n) {
  a <- match(paste0("=== PDF PAGE ", n, " ==="), lines)
  b <- grep("^=== PDF PAGE", lines); b <- b[b > a][1]
  if (is.na(b)) b <- length(lines) + 1L
  stopifnot(!is.na(a)); lines[seq.int(a + 1L, b - 1L)]
}
rows <- function(x, years, n) {
  x <- trimws(x[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9]", x)])
  values <- lapply(strsplit(x, "[[:space:]]+"), function(y) suppressWarnings(as.numeric(y)))
  values <- values[lengths(values) == n & vapply(values, function(y) all(is.finite(y)), logical(1))]
  m <- do.call(rbind, values)
  stopifnot(ncol(m) == n, identical(as.integer(m[, 1]), years)); m
}
land <- rows(c(page(39), page(40)), 1984:2019, 11L)
s <- page(46); s <- s[seq.int(grep("Table 2.6.", s, fixed = TRUE), length(s))]
survey <- rows(c(s, page(47)), 1995:2019, 12L)
s <- page(57); k <- grep("Table 2.14", s, fixed = TRUE)
weight <- rows(c(page(56), s[seq_len(k - 1L)]), 1984:2019, 10L)
cweight <- rows(c(s[seq.int(k, length(s))], page(58)), 1984:2019, 10L)
stopifnot(land[36, 2] == 70, land[36, 11] == 40107,
  survey[25, 3] == 3470, survey[25, 9] == 875,
  weight[36, 2] == .354, cweight[36, 10] == 8.978)
fish <- xml2::xml_find_all(xml, "/Assessment/Fish_Data")
field <- function(n) suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(fish, n))))
year <- field("Year"); rec <- field("Recruitment"); fbar <- field("FishingPressure"); biomass <- field("StockSize")
keep <- year %in% 1984:2019 & is.finite(rec) & is.finite(fbar)
year <- year[keep]; rec <- rec[keep]; fbar <- fbar[keep]; biomass <- biomass[keep]
stopifnot(identical(as.integer(year), 1984:2019), rec[36] == 22606, fbar[36] == .2002, biomass[36] == 34311)
blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(db, file), nrows = 0))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE); names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- id
  x
}
input <- function(type, measure, basis, years, ages, values, unit, ref, notes, fleet = "", survey = "") {
  x <- blank("inputs.csv", length(values)); x$type <- type; x$measure <- measure; x$basis <- basis
  x$fleet <- fleet; x$survey <- survey; x$region <- "Norwegian coast north of 62 N"; x$season <- "annual"
  x$year <- years; x$year_basis <- ifelse(nzchar(as.character(years)), "calendar_year", "")
  x$age <- ages; x$value <- values; x$unit <- unit; x$source_type <- "official_table"
  x$source_reference <- paste(report, ref); x$notes <- notes; x
}
age_input <- function(m, type, measure, basis, unit, ref, notes, fleet = "") {
  input(type, measure, basis, rep(m[,1], each = 9L), rep(2:10, times = nrow(m)),
    as.vector(t(m[,2:10])), unit, ref, notes, fleet = fleet)
}
inputs <- rbind(
  age_input(land, "catch", "landings_numbers_at_age", "numbers", "thousand fish", "Table 2.1a", "ECA estimated commercial catch-at-age used in commercial-catch VPA. Age 10 is 10+. Values in later years are rounded in source.", "Commercial catch"),
  input("catch", "landings_biomass", "biomass", land[,1], "", land[,11], "tonnes", "Table 2.1a", "Commercial landings total; overlaps age-specific catch, not an independent observation.", "Commercial catch"),
  age_input(weight, "weight", "weight_at_age", "kg_per_fish", "kg/fish", "Table 2.13", "Stock weight-at-age in VPA; age 10 is 10+. Survey weights are from autumn and may overestimate start-of-year weight."),
  age_input(cweight, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg/fish", "Table 2.14", "Commercial catch weight-at-age in VPA; age 10 is 10+.", "Commercial catch"),
  input("maturity", "maturity_at_age", "proportion", "", 2:10, c(0,.02,.16,.46,.69,.87,.91,.96,1), "proportion", "Table 2.15", "Constant maturity ogive; 1995-2009 survey average used throughout the assessment; age 10 is 10+."),
  input("M", "natural_mortality_at_age", "per_year", "", 2:10, rep(.2, 9), "per year", "section 2.4.3", "Fixed natural mortality 0.2 for all ages and years; age 10 is 10+."),
  input("biology", "fraction_F_before_spawning", "proportion", "", 2:10, rep(0, 9), "proportion", "Table 2.13", "Fraction of F before spawning is zero for all years and ages; age 10 is 10+."),
  input("biology", "fraction_M_before_spawning", "proportion", "", 2:10, rep(0, 9), "proportion", "Table 2.13", "Fraction of M before spawning is zero for all years and ages; age 10 is 10+."),
  input("index", "numbers_at_age", "index_scale", rep(survey[,1], each = 9L), rep(2:10, times = nrow(survey)), as.vector(t(survey[,3:11])), "thousand fish", "Table 2.6", "Acoustic indices at ages 2-8 used in trial XSA; survey mortality also uses age 9. Age 10 is 10+ and is retained as a source observation, not an additional XSA input. Q4: September until 2002, October-November from 2003; exact within-year timing unknown. Area 07 fjords were not covered in 2013.", survey = "NOcoast-Aco-Q4"))
inputs$season[inputs$type == "index"] <- "fall"
output <- function(type, measure, values, unit, notes, age = "", age_group = "") {
  ok <- is.finite(values); x <- blank("outputs.csv", sum(ok)); x$type <- type; x$measure <- measure
  x$region <- "Norwegian coast north of 62 N"; x$year <- year[ok]; x$age <- age; x$age_group <- age_group
  x$value <- values[ok]; x$unit <- unit; x$source_type <- "official_machine_readable"; x$source_reference <- sag; x$notes <- notes; x
}
outputs <- rbind(
  output("recruitment", "recruitment", rec, "thousand fish", "ICES SAG recruitment at age 2; also appears in AFWG Table 2.19. Table 2.19 has conflicting catch and stock-summary details; run attribution should be checked against native files.", age = 2),
  output("mortality", "Fbar", fbar, "per year", "ICES SAG F ages 4-7; Table 2.19 agrees with SAG, but its catch and stock-summary details conflict with the narrative. Terminal F 0.2002 matches the commercial-catch survey-based terminal F.", age_group = "4-7"),
  output("index", "spawning_biomass_index", biomass, "tonnes", "ICES SAG stock size is an acoustic spawning-biomass index, not VPA SSB. Survey index uses fixed mean maturity and begins in 1995."))
a <- blank("assumptions.csv", 5); a$component <- "assessment"
a$setting <- c("official_method", "modeled_ages", "terminal_F", "natural_mortality", "survey")
a$value <- c("SVPA (user-defined VPA) with survey-derived terminal F; trial XSA used for calibration", "1984-2019; ages 2-10+", "F(4-7) from survey mortality regressed against trial XSA F in 1996-2007", "Fixed M=0.2 per year", "Norwegian coastal acoustic survey, ages 2-8, 1995-2019")
a$source_reference <- paste(report, "sections 2.3-2.5"); a$notes <- c("Report discusses commercial-catch and total-catch runs; outputs require careful run identification.", "Final age-specific population and F outputs have not been recovered.", "Terminal F 0.2002 for commercial catch; 0.2862 for all catch, per Table 2.18.", "No process model for M.", "Moved from September to October-November in 2003; an acoustic index rather than absolute abundance.")
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id; assessment$assessment_year <- 2020
assessment$terminal_year <- 2019; assessment$estimate_terminal_year <- 2019; assessment$assessment_type <- "annual"
assessment$model_family <- "SVPA"; assessment$model_version <- "Lowestoft VPA95 user-defined VPA; trial XSA calibration"
assessment$is_current <- "TRUE"; assessment$is_applied <- "TRUE"; assessment$framework_year <- 2015
assessment$assessment_url <- report; assessment$data_url <- sag
assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
assessment$notes <- "Final assessment before 2021 stock split; historical combined unit only. Table 2.19 appears inconsistent with the narrative and commercial catch total; VPA SSB and biomass withheld pending resolution. SAG stock size is survey biomass index, not SSB. No native run recovered."
stock <- read.csv(file.path(db, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stock[stock$stock_id == stock_id, ]; stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-AFWG_morhua_COASTNOR 1,2")
stock$authority_stock_id <- "cod.27.1-2coast"; stock$common_name <- "Norwegian coastal cod, former combined unit"
stock$area <- "ICES subareas 1 and 2, Norwegian coastal waters north of 62 N"; stock$region <- "Norwegian Sea and Barents Sea"
stock$notes <- "Historical combined unit from Charbonneau-Keith Master identifier ICES-AFWG_morhua_COASTNOR 1,2; split at 67 N in 2021. Current northern and southern units are stored separately; see source review."
write_rows <- function(file, x, key) {
  path <- file.path(db, file); contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]; selected <- which(startsWith(lines, paste0('"', key, '",')))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  tmp <- tempfile(tmpdir = db); on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    stopifnot(identical(selected, seq.int(min(selected), max(selected))))
    replacement <- paste0(replacement, if (endsWith(lines[selected[1L]], "\r")) "\r" else "")
    lines <- c(head(lines, min(selected) - 1L), replacement, tail(lines, length(lines) - max(selected)))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (!identical(bytes, charToRaw(contents))) { writeBin(bytes, tmp); if (!file.copy(tmp, path, overwrite = TRUE)) stop("Write failed: ", file) }
}
if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) {
  cat("Combined coastal cod source checks passed:", nrow(inputs), "inputs and", nrow(outputs), "outputs.\n")
} else {
  write_rows("stocks.csv", stock, stock_id); write_rows("assessments.csv", assessment, id)
  write_rows("assumptions.csv", a, id); write_rows("inputs.csv", inputs, id); write_rows("outputs.csv", outputs, id)
  cat("Imported historical combined coastal cod 2020 assessment.\n")
}
