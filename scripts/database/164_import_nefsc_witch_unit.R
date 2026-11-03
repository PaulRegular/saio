base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_nefsc_garmiii_cynoglossus_5y")
stock_id <- "nefsc_witch_flounder_unit"
ids <- c("nefsc_witch_flounder_unit_2024", "nefsc_witch_flounder_unit_2026_data_update")
url24 <- "https://d23h0vhsm26o6d.cloudfront.net/13d.-2024_WIT_UNIT_RPT_09_02_203738.pdf"
url26 <- "https://d23h0vhsm26o6d.cloudfront.net/1c_data_update_template_v2_1_2b_witch_flounder.pdf.pdf"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  actual <- digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, sha)) stop("Cached source checksum differs: ", file)
  path
}
invisible(verify("witch_flounder_2024_unit_report.pdf", "fb8d1128686e9dede40b6fadfe22030b0c7add8449f8c09148c8543b1e481e95"))
invisible(verify("witch_2026_data_update.pdf", "849de7b32f1686d4753e907155b7ebe41a799ff0c835c4b31148d35be71696ab"))
t24 <- readLines(verify("witch_2024_layout.txt", "644e640e7b353dd8f8ad5c55a57d38e08490e127ff123e8933f613e0f6a212f4"), encoding = "UTF-8", warn = FALSE)
t26 <- readLines(verify("witch_2026_layout.txt", "fbc495fdca2198c1fc72753c4705ee9392fd825ce4d52c61fe2f265e34d0273e"), encoding = "UTF-8", warn = FALSE)
parse_numbers <- function(x) as.numeric(gsub(",", "", strsplit(trimws(x), "[[:space:]]+")[[1]], fixed = TRUE))
row24 <- function(label) {
  line <- t24[grepl(paste0("^[[:space:]]*", label, "[[:space:]]+[0-9]"), t24)]
  stopifnot(length(line) == 1L)
  v <- parse_numbers(sub(paste0("^[[:space:]]*", label, "[[:space:]]+"), "", line))
  stopifnot(length(v) == 11L, all(is.finite(v))); v
}
land24 <- row24("Commercial Landings"); discard24 <- row24("Commercial Discards")
catch24 <- row24("Catch for Assessment"); biomass24 <- row24("Exploitable Biomass")
rate24 <- row24("Exploitation Rate")
stopifnot(catch24[11] == 1013, biomass24[11] == 30093, rate24[11] == .034)
page <- function(n) {
  a <- match(paste0("--- PAGE ", n, " ---"), t26)
  b <- match(paste0("--- PAGE ", n + 1, " ---"), t26)
  stopifnot(!is.na(a)); if (is.na(b)) b <- length(t26) + 1L
  t26[seq.int(a + 1L, b - 1L)]
}
catch_lines <- c(page(6), page(7))
catch_lines <- catch_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9]", catch_lines)]
catches <- do.call(rbind, lapply(catch_lines, parse_numbers))
stopifnot(ncol(catches) == 4L, identical(as.integer(catches[, 1]), 1982:2025),
  all(catches[, 2] + catches[, 3] == catches[, 4]), catches[42, 3] == 89)
survey_lines <- c(page(11), page(12), page(13))
survey_lines <- survey_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}([[:space:]]|$)", survey_lines)]
survey <- do.call(rbind, lapply(survey_lines, function(line) {
  v <- parse_numbers(line); yr <- v[1]
  if (yr %in% c(1963:1967, 2023)) c(yr, v[2], NA, v[3], NA)
  else if (yr == 2026) c(yr, NA, v[2], NA, v[3])
  else if (yr == 2020) c(yr, NA, NA, NA, NA)
  else { stopifnot(length(v) == 5L); v }
}))
stopifnot(ncol(survey) == 5L, identical(as.integer(survey[, 1]), 1963:2026),
  survey[survey[, 1] == 2023, 2] == .8741, is.na(survey[survey[, 1] == 2023, 3]),
  survey[survey[, 1] == 2026, 3] == .4774)

blank <- function(file, n = 1L, id = "") {
  fields <- names(read.csv(file.path(db, file), nrows = 0))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE); names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- id
  x
}
input <- function(id, measure, yr, value, ref, notes, type = "catch", basis = "biomass", unit = "tonnes", fleet = "Commercial fishery", survey = "", season = "annual") {
  x <- blank("inputs.csv", length(value), id)
  x$type <- type; x$measure <- measure; x$basis <- basis; x$fleet <- fleet; x$survey <- survey
  x$region <- "Gulf of Maine-Georges Bank and southward unit"; x$season <- season
  x$year <- yr; x$year_basis <- "calendar_year"; x$value <- value; x$unit <- unit
  x$source_type <- "official_table"; x$source_reference <- ref; x$notes <- notes; x
}
output <- function(measure, yr, value, unit, type, notes) {
  x <- blank("outputs.csv", length(value), ids[1]); x$type <- type; x$measure <- measure
  x$region <- "Gulf of Maine-Georges Bank and southward unit"; x$year <- yr; x$value <- value
  x$unit <- unit; x$source_type <- "official_table"; x$source_reference <- paste(url24, "Table 1")
  x$notes <- notes; x
}
note24 <- "Reported 2024 assessment input, rounded to tonnes; components may not sum exactly because of rounding."
in24 <- rbind(input(ids[1], "landings_biomass", 2013:2023, land24, paste(url24, "Table 1"), note24),
  input(ids[1], "discard_biomass", 2013:2023, discard24, paste(url24, "Table 1"), note24),
  input(ids[1], "total_biomass", 2013:2023, catch24, paste(url24, "Table 1"), note24))
out24 <- rbind(output("exploitable_biomass", 2013:2023, biomass24, "tonnes", "biomass", "Survey-based population biomass multiplied by 0.9. Ordinarily mean of current spring and preceding autumn; missing surveys are not imputed. Not SSB."),
  output("exploitation_rate", 2013:2023, rate24, "catch / exploitable biomass", "mortality", "Annual catch divided by empirical exploitable biomass; not instantaneous fishing mortality."))
biomass2024 <- output("exploitable_biomass", 2024, 35270, "tonnes", "biomass", "Report prose states this 2024 empirical indicator uses fall 2023 and spring 2024; it informed catch advice and is not SSB.")
biomass2024$source_type <- "official_document"; biomass2024$source_reference <- paste(url24, "Projections and special comments")
out24 <- rbind(out24, biomass2024)
note26 <- "2026 data update; not an input from the 2024 assessment. Reported commercial totals are rounded to tonnes."
in26 <- do.call(rbind, lapply(2:4, function(i) input(ids[2], c("landings_biomass", "discard_biomass", "total_biomass")[i-1], catches[, 1], catches[, i], paste(url26, "Table 1"), note26)))
for (i in 1:2) {
  season <- c("fall", "spring")[i]; survey_name <- paste("NEFSC", season, "bottom trawl")
  ok <- is.finite(survey[, i + 1L]); years <- survey[ok, 1]
  in26 <- rbind(in26,
    input(ids[2], "relative_biomass_index", years, survey[ok, i + 1L], paste(url26, "Table 2"), "Raw stratified survey biomass in kg/tow, not the 2024 swept-area and catchability-adjusted population biomass. Missing surveys omitted; exact within-year timing not supplied.", type = "index", basis = "index_scale", unit = "kg/tow", fleet = "", survey = survey_name, season = season),
    input(ids[2], "relative_standard_error", years, survey[ok, i + 3L], paste(url26, "Table 2"), "Reported survey biomass coefficient of variation for the matching index row; 2026 data update.", type = "index", basis = "relative_scale", unit = "CV", fleet = "", survey = survey_name, season = season))
}
assumptions <- blank("assumptions.csv", 5L, ids[1]); assumptions$component <- "assessment"
assumptions$setting <- c("official_method", "biomass_indicator", "survey_catchability", "missing_surveys", "exploitation_rate")
assumptions$value <- c("Empirical swept-area survey biomass assessment", "0.9 times the mean of spring y and fall y-1 population biomass; use available survey when missing", "Seasonal and year-varying", "Spring and fall 2020 and spring 2023 are missing and not imputed in the base approach", "Annual catch divided by exploitable biomass")
assumptions$source_reference <- paste(url24, "Tables 1-2 and report text")
assumptions$notes <- c("ASAP sensitivity was informational and is not the official method.", "Catch advice also uses 2024 spring and 2023 fall; year 2024 is not an annual model state in Table 1.", "2024 report gives approximate ranges 0.21-0.27 spring and 0.24-0.29 fall; yearly coefficients not recovered.", "The 2024 report text's generic 2023 formula conflicts with its missing-survey explanation; the peer review confirms 2023 uses fall 2022 alone.", "This ratio is not instantaneous F.")
assessments <- blank("assessments.csv", 2L); assessments$assessment_id <- ids; assessments$stock_id <- stock_id
assessments$assessment_year <- c(2024, 2026); assessments$terminal_year <- c(2023, 2026)
assessments$estimate_terminal_year <- c(2024, ""); assessments$assessment_type <- c("management_track", "data_update")
assessments$model_family <- c("Empirical swept-area survey assessment", "Data update; no assessment model")
assessments$is_current <- c("TRUE", "FALSE"); assessments$is_applied <- c("TRUE", "FALSE")
assessments$assessment_url <- c(url24, url26)
assessments$assumptions_status <- c("partial", "not_applicable"); assessments$inputs_status <- "partial"
assessments$outputs_status <- c("partial", "not_applicable")
assessments$notes <- c("2024 management-track assessment used for advice. Draft report table is corroborated by the peer-review report; full annual swept-area survey biomass and catchability inputs remain unrecovered.", "2026 monitoring-data update presented to the SSC, not a population assessment; survey indices extend to spring 2026 and catches to 2025. Not substituted for the 2024 source run.")
stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$authority <- "NOAA-NEFSC"
stock$scientific_name <- "Glyptocephalus cynoglossus"; stock$common_name <- "Witch flounder, US unit stock"
stock$area <- "Gulf of Maine-Georges Bank and southward"; stock$region <- "Northeast US shelf"; stock$ocean <- "Northwest Atlantic"
stock$notes <- "Current unit stock includes more than the Charbonneau-Keith 5Y catalogue label. See source_reviews/nefsc_witch_flounder_unit.md; no 5Y-only values are inferred."

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
  cat("Source checks passed:", nrow(in24), "2024 inputs,", nrow(out24), "outputs;", nrow(in26), "2026 data-update inputs.\n")
} else {
  write_rows("stocks.csv", stock, stock_id)
  for (i in 1:2) write_rows("assessments.csv", assessments[i, ], ids[i])
  write_rows("assumptions.csv", assumptions, ids[1]); write_rows("inputs.csv", in24, ids[1])
  write_rows("inputs.csv", in26, ids[2]); write_rows("outputs.csv", out24, ids[1])
  cat("Imported witch flounder unit assessment and separate data update.\n")
}
