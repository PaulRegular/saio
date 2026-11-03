base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_wgsce_labrax_is6a_7b_7j")
stock_id <- "ck_ices_wgsce_labrax_is6a_7b_7j"
id <- "ices_seabass_6a_7bj_2026"
sag_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22635"
report_url <- "https://doi.org/10.17895/ices.pub.32625759"
advice_url <- "https://doi.org/10.17895/ices.advice.30931976"

verify <- function(file, sha) {
  path <- file.path(cache, file)
  actual <- digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, sha)) stop("Cached source checksum differs: ", file)
  path
}
xml <- xml2::read_xml(verify("ices_sag_2026_bss_27_6a7bj.xml", "22be8449406f9f1eaa9aa24455b28dc5e2d4e2b669aff3e9b8793cadda8ce897"))
invisible(verify("WGCSE_2026_seabass_6a7bj.pdf", "e410ae5badc76d766885a058e0119a932053b334e46bf74484cb554f17f0dc61"))
stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockCode")) == "bss.27.6a7bj",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/AssessmentYear")) == "2026")
fish <- xml2::xml_find_all(xml, "/Assessment/Fish_Data")
year <- as.integer(xml2::xml_text(xml2::xml_find_first(fish, "Year")))
landings <- suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(fish, "Landings"))))
keep <- !is.na(year) & is.finite(landings) & year <= 2025L
year <- year[keep]; landings <- landings[keep]
stopifnot(identical(year, 2000:2025), landings[year == 2023] == 5.297,
  landings[year == 2024] == 6.5, landings[year == 2025] == 2.37)

blank <- function(file, n = 1L) {
  x <- as.data.frame(matrix("", n, length(names(read.csv(file.path(db, file), nrows = 0)))))
  names(x) <- names(read.csv(file.path(db, file), nrows = 0))
  if ("assessment_id" %in% names(x)) x$assessment_id <- id
  x
}
inputs <- blank("inputs.csv", length(year))
inputs$type <- "catch"; inputs$measure <- "landings_biomass"; inputs$basis <- "biomass"
inputs$fleet <- "All commercial fleets"; inputs$region <- "ICES divisions 6.a, 7.b and 7.j"
inputs$season <- "annual"; inputs$year <- year; inputs$year_basis <- "calendar_year"
inputs$value <- landings; inputs$unit <- "tonnes"
inputs$source_type <- "official_machine_readable"; inputs$source_reference <- sag_url
inputs$notes <- "Official commercial landings, not total catches or age-specific catches. Provided to WGCSE as context; advice uses the previous landings advice and a precautionary buffer. Report table 4.2 rounds values and marks 2024 and 2025 preliminary."
early <- inputs[1:3, ]
early$year <- c(1996L, 1997L, 1999L); early$value <- 0
early$source_type <- "official_table"; early$source_reference <- paste(report_url, "Table 4.2")
early$notes <- "Source table displays 0 tonnes with whole-tonne rounding; this is a rounded reported value, not proof that no landings occurred. The censored 1995 and 1998 entries are not represented as point values."
inputs <- rbind(early, inputs)
assumptions <- blank("assumptions.csv", 4L)
assumptions$component <- "assessment"
assumptions$setting <- c("official_method", "advice_rule", "available_data", "stock_structure")
assumptions$value <- c("ICES category 6 precautionary advice", "Previous advice 2 tonnes multiplied by 0.8, yielding 1.6 tonnes commercial landings in each of 2027-2029", "Commercial landings only; no survey index, numbers at age or discard estimates", "Stock structure is pragmatic and requires further evaluation")
assumptions$source_reference <- c(advice_url, advice_url, report_url, report_url)
assumptions$notes <- c("No fitted population model or population-state outputs are reported.", "The published advice specifies commercial landings; total catches cannot be quantified. WGCSE text also uses the word catches, but its rule table specifies landings.", "The landings time series is source context, not an abundance index or catch-at-age likelihood.", "The report identifies unresolved mixing with adjacent stocks.")
advice_year <- 2027:2029
advice_outputs <- blank("outputs.csv", length(advice_year))
advice_outputs$type <- "catch"
advice_outputs$measure <- "catch_advice"
advice_outputs$year <- advice_year
advice_outputs$value <- 1.6
advice_outputs$unit <- "tonnes"
advice_outputs$source_type <- "official_document"
advice_outputs$source_reference <- advice_url
advice_outputs$notes <- paste(
  "ICES advises commercial landings of no more than 1.6 tonnes in each year.",
  "This is management advice, not a model-predicted catch; total catches are",
  "not quantified."
)
assessment <- blank("assessments.csv")
assessment$stock_id <- stock_id; assessment$assessment_year <- 2026
assessment$terminal_year <- 2025; assessment$assessment_type <- "advice"
assessment$model_family <- "ICES category 6 precautionary advice"; assessment$is_current <- "TRUE"; assessment$is_applied <- "TRUE"
assessment$assessment_url <- report_url; assessment$data_url <- sag_url
assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
assessment$notes <- "Published 2026 advice for 2027-2029 is based on previous advice and a precautionary buffer; the 1.6-tonne annual commercial-landings advice is recorded as catch_advice. No population model or population-state outputs are available. Terminal year is the latest reported landings year, not a model fitting year. Recreational catches and discards remain unquantified for this area; age data and an abundance index were unavailable."

stocks <- read.csv(file.path(db, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, ]
stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-WGSCE_labrax_IS6a,7b,7j")
stock$authority_stock_id <- "bss.27.6a7bj"; stock$common_name <- "West of Scotland and Ireland seabass"
stock$area <- "ICES divisions 6.a, 7.b and 7.j"; stock$region <- "Celtic Seas"
stock$notes <- "Charbonneau-Keith catalogue identity matches the current ICES advice unit; stock structure and mixing with neighbouring stocks remain uncertain. See the stock source review."

write_rows <- function(file, x, key) {
  path <- file.path(db, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', key, '",')))
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
  if (!identical(bytes, charToRaw(contents))) {
    writeBin(bytes, tmp)
    if (!file.copy(tmp, path, overwrite = TRUE)) stop("Could not write ", file)
  }
}
if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) {
  cat("Source checks passed:", length(year), "annual landings rows.\n")
} else {
  write_rows("stocks.csv", stock, stock_id)
  write_rows("assessments.csv", assessment, id)
  write_rows("assumptions.csv", assumptions, id)
  write_rows("inputs.csv", inputs, id)
  write_rows("outputs.csv", advice_outputs, id)
  cat("Imported 2026 seabass advice context and landings.\n")
}
