base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/nefsc_summer_flounder_2025")
id <- "nefsc_summer_flounder_2025"
report_url <- "https://asmfc.org/wp-content/uploads/2025/08/SF_Management_Track_Assessment_2025.pdf"
archive_url <- "https://raw.githubusercontent.com/NOAA-EDAB/stocksmart/664c4237e26520b260a090e1821a2cee5d1cdf07/data/stock_assessment_data.rda"
review_url <- "https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf"
verify <- function(file, hash) {
  path <- file.path(cache, file)
  actual <- digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, hash)) stop("Cached source checksum differs: ", file)
  path
}
report <- pdftools::pdf_text(verify("SF_Management_Track_Assessment_2025.pdf", "6423d73924d765ca5742ac5b97c178799a4d8f699ea923203693b294a8fde652"))
review <- pdftools::pdf_text(verify("peer_review_2025.pdf", "7f91a0074c88516db6fc97b57f6bff8baa4a40887bbfedee975c9b994a55d1ae"))
review_text <- gsub("[[:space:]]+", " ", paste(review, collapse = " "))
stopifnot(grepl("2025 Management Track Assessment for Summer Flounder met all the TORs", review_text, fixed = TRUE))
archive <- new.env(parent = emptyenv())
load(verify("stock_assessment_data.rda", "141db3599cbf37af3e019bd53d2323d829a719b273e8ab0226b73f6ad18620b0"), envir = archive)
x <- archive$stock_assessment_data
x <- x[x$stock_name == "Summer flounder - Mid-Atlantic Coast" & x$assessment_year == 2025, ]
stopifnot(nrow(x) == 172L, all(x$stock_id == 10191), all(x$assessment_id == 13936),
  all(x$year %in% 1982:2024), !anyDuplicated(x[c("metric", "year")]))
series <- function(metric) {
  z <- x[x$metric == metric, ]; z <- z[order(z$year), ]
  stopifnot(identical(as.integer(z$year), 1982:2024), all(is.finite(z$value))); z$value
}
catch <- series("Catch"); ssb <- series("Abundance"); f <- series("Fmort"); rec <- series("Recruitment")
stopifnot(unique(x$units[x$metric == "Catch"]) == "Metric Tons",
  unique(x$description[x$metric == "Abundance"]) == "Spawning Stock Biomass",
  unique(x$description[x$metric == "Recruitment"]) == "Number of Recruits - Age 0",
  unique(x$description[x$metric == "Fmort"]) == "F Rate for Fully Selected Fish")
lines <- strsplit(report[2], "\n")[[1L]]
row <- function(label) {
  i <- which(startsWith(trimws(lines), label)); stopifnot(length(i) == 1L)
  val <- trimws(sub(label, "", trimws(lines[i]), fixed = TRUE))
  val <- as.numeric(strsplit(gsub(",", "", val, fixed = TRUE), "[[:space:]]+")[[1]])
  stopifnot(length(val) == 11L, all(is.finite(val))); val
}
com_land <- row("Commercial landings"); com_disc <- row("Commercial discards")
rec_land <- row("Recreational landings"); rec_disc <- row("Recreational discards")
total <- row("Removals for Assessment"); report_ssb <- row("Spawning Stock Biomass")
report_f <- row("FF ull"); report_rec <- row("Recruits (age 0)")
i <- match(2014:2024, 1982:2024)
stopifnot(all(total == catch[i]), all(report_ssb == ssb[i]), all(abs(report_f - f[i]) < 1e-6),
  all(report_rec == rec[i]), all(abs(com_land + com_disc + rec_land + rec_disc - total) <= 1),
  tail(ssb, 1) == 40516, abs(tail(f, 1) - .35) < 1e-6, tail(rec, 1) == 49649)
stopifnot(all(abs(f - round(f, 3)) < 1e-6)); f <- round(f, 3)
blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(db, file), nrows = 0, check.names = FALSE))
  z <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE); names(z) <- fields
  if ("assessment_id" %in% fields) z$assessment_id <- id
  z
}
input <- function(measure, years, values, fleet, ref, notes, source = "official_table") {
  z <- blank("inputs.csv", length(values)); z$type <- "catch"; z$measure <- measure; z$basis <- "biomass"
  z$fleet <- fleet; z$region <- "US Atlantic coast, Maine to North Carolina"; z$season <- "annual"
  z$year <- years; z$year_basis <- "calendar_year"; z$value <- values; z$unit <- "tonnes"
  z$source_type <- source; z$source_reference <- ref; z$notes <- notes; z
}
inputs <- rbind(
  input("total_biomass", 1982:2024, catch, "All removals", archive_url, "Stock SMART total catch in metric tonnes for assessment 13936. It overlaps the four Table 1 components and is not a fifth independent fleet. Values for 2014-2024 match Table 1.", "official_machine_readable"),
  input("landings_biomass", 2014:2024, com_land, "Commercial landings", paste(report_url, "Table 1"), "Published catch component, not age composition or numbers at age."),
  input("discard_biomass", 2014:2024, com_disc, "Commercial discards", paste(report_url, "Table 1"), "Published catch component, not age composition or numbers at age."),
  input("landings_biomass", 2014:2024, rec_land, "Recreational landings", paste(report_url, "Table 1"), "Published catch component, not age composition or numbers at age."),
  input("discard_biomass", 2014:2024, rec_disc, "Recreational discards", paste(report_url, "Table 1"), "Published catch component, not age composition or numbers at age."))
output <- function(type, measure, values, unit, notes, age = "", group = "") {
  z <- blank("outputs.csv", length(values)); z$type <- type; z$measure <- measure
  z$region <- "US Atlantic coast, Maine to North Carolina"; z$year <- 1982:2024
  z$age <- age; z$age_group <- group; z$value <- values; z$unit <- unit
  z$source_type <- "official_machine_readable"; z$source_reference <- archive_url; z$notes <- notes; z
}
outputs <- rbind(
  output("biomass", "SSB", ssb, "tonnes", "2025 ASAP SSB; Stock SMART assessment 13936. Values for 2014-2024 match Table 1. The report plots approximate 90% lognormal intervals but does not tabulate their values."),
  output("mortality", "Ffull", f, "per year", "2025 ASAP fully selected F, at age 4 per Table 1; not an Fbar. Values for 2014-2024 match Table 1; rounded to three decimals to remove Stock SMART binary storage noise. No uncertainty inferred.", group = "age 4"),
  output("recruitment", "recruitment", rec, "thousand fish", "2025 ASAP recruitment at true age 0. Values for 2014-2024 match Table 1; no uncertainty inferred.", age = 0))
a <- blank("assumptions.csv", 4L); a$component <- "assessment"
a$setting <- c("official_method", "catch_fleets", "assessment_changes", "source_limitations")
a$value <- c("ASAP statistical catch-at-age, 1982-2024; ages 0-7+", "Commercial and recreational landings and discards", "Updates to data and some historical weights and surveys; no major model change", "Only aggregate 1982-2024 trajectories and 2014-2024 component catch totals recovered")
a$source_reference <- c(report_url, report_url, review_url, report_url)
a$notes <- c("2025 management-track update, reviewed as best scientific information available. Full age-specific inputs and fitted age surfaces not recovered.", "Four source fleet components overlap total removals; no age data in this table.", "Panel noted historical weight and two survey updates, and removal of likelihood constants.", "Do not mix 2018 age-specific values into 2025 run or infer unreported confidence intervals.")
assessments <- read.csv(file.path(db, "assessments.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
assessment <- assessments[assessments$assessment_id == id, ]; stopifnot(nrow(assessment) == 1L, assessment$stock_id == "nefsc_summer_flounder")
assessment$data_url <- archive_url
assessment$notes <- "2025 management-track update through 2024, peer reviewed and used for advice. NOAA Stock SMART assessment 13936 supplies annual aggregate removals, SSB, Ffull and age-0 recruitment 1982-2024; report Table 1 supplies 2014-2024 fleet totals. Age-specific inputs and fitted surfaces are not recovered. 2018 remains the separately selected detailed assessment."
write_rows <- function(file, z, key) {
  path <- file.path(db, file); contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]; selected <- which(startsWith(lines, paste0('"', key, '",')))
  stopifnot(identical(names(z), names(read.csv(path, nrows = 0))))
  tmp <- tempfile(tmpdir = db); on.exit(unlink(tmp), add = TRUE)
  write.table(z, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
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
  cat("Summer flounder 2025 source checks passed:", nrow(inputs), "inputs and", nrow(outputs), "outputs.\n")
} else {
  write_rows("assessments.csv", assessment, id); write_rows("assumptions.csv", a, id)
  write_rows("inputs.csv", inputs, id); write_rows("outputs.csv", outputs, id)
  cat("Imported 2025 summer flounder aggregate catch and assessment trajectories.\n")
}
