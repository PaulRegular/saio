base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_wgsce_solea_is7jk_2026")
stock_id <- "ices_sole_celtic_south_7hk"
id <- "ices_sole_celtic_south_7hk_2026"
sag_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/23719"
report_url <- "https://doi.org/10.17895/ices.pub.32625759"
advice_url <- "https://doi.org/10.17895/ices.advice.30932420"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  actual <- digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, sha)) stop("Cached source checksum differs: ", file)
  path
}
invisible(verify("wgcse_2026_sole_7h-k.pdf", "cf5f831c106cc49b3c9b520be5904bbb2e92752a37fb6e648378f0a9329f9d3a"))
xml <- xml2::read_xml(verify("ices_sag_2026_23719.xml", "6bd47d1b337eade34393d4e2dae59235e8a6bf7cc018cfcef6d8deaa0404c4d1"))
stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockCode")) == "sol.27.7h-k",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/AssessmentYear")) == "2026")
fish <- xml2::xml_find_all(xml, "/Assessment/Fish_Data")
field <- function(x) suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(fish, x))))
year <- field("Year"); landings <- field("Landings"); discards <- field("Discards")
stopifnot(identical(as.integer(year), 1951:2025), all(is.finite(landings)),
  sum(is.finite(discards)) == 22L, landings[year == 1995] == 915,
  landings[year == 1996] == 443, landings[year == 2025] == 205,
  discards[year == 2025] == .26)
blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(db, file), nrows = 0))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE); names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- id
  x
}
input <- function(measure, years, values, notes) {
  x <- blank("inputs.csv", length(values)); x$type <- "catch"; x$measure <- measure; x$basis <- "biomass"
  x$fleet <- "Combined fishery"; x$region <- "ICES divisions 7.h-k"; x$season <- "annual"
  x$year <- years; x$year_basis <- "calendar_year"; x$value <- values; x$unit <- "tonnes"
  x$source_type <- "official_machine_readable"; x$source_reference <- sag_url; x$notes <- notes; x
}
land <- input("landings_biomass", year, landings, "Source catch history provided as context for category-5 advice; not an age-specific model likelihood. The value is official reported landings through 1995 and ICES estimated landings from 1996 onward, per WGCSE Table 23.2. Area misreporting is an unresolved concern.")
ok <- is.finite(discards)
disc <- input("discard_biomass", year[ok], discards[ok], "ICES estimated discards, not a separate model likelihood. Missing years are omitted; zero values are source-reported. Discards are considered negligible for the current advice.")
inputs <- rbind(land, disc)
assumptions <- blank("assumptions.csv", 4L); assumptions$component <- "assessment"
assumptions$setting <- c("official_method", "advice_rule", "stock_identity", "catch_data")
assumptions$value <- c("ICES category 5 precautionary advice; no assessment", "Previous 170-tonne catch advice multiplied by 0.8; 136 tonnes annually for 2027-2029", "ICES divisions 7.h-k; biological stock structure uncertain", "Discarding is considered negligible; area misreporting is unquantified")
assumptions$source_reference <- c(advice_url, advice_url, report_url, report_url)
assumptions$notes <- c("No fitted abundance, recruitment, SSB or F population model is reported.", "Advice calculation uses previous advice, not a catch-at-age likelihood.", "Potential 7.j distinct population and connectivity with adjacent 7.e-7.g are under investigation; current ICES boundaries remain in force.", "Reported landings mix official totals and ICES estimates across historical years; do not treat them as independent observations.")
advice_year <- 2027:2029
advice_outputs <- blank("outputs.csv", length(advice_year))
advice_outputs$type <- "catch"
advice_outputs$measure <- "catch_advice"
advice_outputs$year <- advice_year
advice_outputs$value <- 136
advice_outputs$unit <- "tonnes"
advice_outputs$source_type <- "official_document"
advice_outputs$source_reference <- advice_url
advice_outputs$notes <- paste(
  "ICES advises catches of no more than 136 tonnes in each year.",
  "This category-5 advice applies a 0.8 buffer to the preceding 170-tonne",
  "advice; it is not a population-model output."
)
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2026; assessment$terminal_year <- 2025
assessment$assessment_type <- "advice"; assessment$model_family <- "ICES category 5 precautionary advice"
assessment$is_current <- "TRUE"; assessment$is_applied <- "TRUE"
assessment$framework_year <- 2020; assessment$assessment_url <- report_url
assessment$framework_url <- "https://doi.org/10.17895/ices.pub.5976"; assessment$data_url <- sag_url
assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
assessment$notes <- "2026 advice uses the previous advice and a precautionary buffer; the 136-tonne annual catch advice for 2027-2029 is recorded as catch_advice. There is no population assessment or population-state output. Terminal year is the latest reported landings year, not a fitted model year. The 2019 XSA was used for trends but was replaced after the 2020 benchmark; its source data remain under review."
stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$authority <- "ICES"
stock$authority_stock_id <- "sol.27.7h-k"; stock$scientific_name <- "Solea solea"
stock$common_name <- "Southern Celtic Sea and southwest Ireland sole"
stock$area <- "ICES divisions 7.h-k"; stock$region <- "Celtic Seas"; stock$ocean <- "Northeast Atlantic"
stock$notes <- "Current ICES unit includes 7.h and 7.i as well as the Charbonneau-Keith catalogue label 7.j-k. Boundaries and the relationship of the two labels remain uncertain; no 7.j-k-only identity is inferred. See source review."
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
  cat("Source checks passed:", nrow(land), "landings and", nrow(disc), "discard rows.\n")
} else {
  write_rows("stocks.csv", stock, stock_id); write_rows("assessments.csv", assessment, id)
  write_rows("assumptions.csv", assumptions, id); write_rows("inputs.csv", inputs, id)
  write_rows("outputs.csv", advice_outputs, id)
  cat("Imported current southern Celtic Sea sole advice context.\n")
}
