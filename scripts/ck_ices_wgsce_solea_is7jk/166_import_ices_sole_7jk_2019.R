base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_wgsce_solea_is7jk_2026")
stock_id <- "ck_ices_wgsce_solea_is7jk"
id <- "ices_sole_7jk_2019_xsa"
report_url <- "https://doi.org/10.17895/ices.pub.4982"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  actual <- digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, sha)) stop("Cached source checksum differs: ", file)
  path
}
invisible(verify("WGCSE_2019.pdf", "fe996eff5cd44ad841d5fdf406f0d909d9b22c3c9f21a0fa061591027d35ff2b"))
text <- readLines(verify("WGCSE_2019_sole_pages_761_779_plain.txt", "d06c9149e4963da08eea1f6df4f9f8bc10413a97224ac1101a10e868c165c1fe"), encoding = "UTF-8", warn = FALSE)
page <- function(n) {
  a <- match(paste0("--- PAGE ", n, " ---"), text); b <- match(paste0("--- PAGE ", n + 1, " ---"), text)
  stopifnot(!is.na(a)); if (is.na(b)) b <- length(text) + 1L
  text[seq.int(a + 1L, b - 1L)]
}
numbers <- function(line) as.numeric(strsplit(trimws(line), "[[:space:]]+")[[1]])
year_rows <- function(lines, years, n) {
  lines <- trimws(lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9]", lines)])
  v <- lapply(lines, numbers); v <- v[lengths(v) == n + 1L]
  out <- do.call(rbind, v)
  stopifnot(ncol(out) == n + 1L, identical(as.integer(out[, 1]), years)); out
}
land <- year_rows(c(page(770), page(771)), 1993:2018, 15L)
weights <- year_rows(c(page(772), page(773)), 1993:2018, 15L)
summary <- year_rows(page(779), 1993:2018, 4L)
stopifnot(land[1, 2] == 32.8, land[26, 3] == .8, weights[1, 2] == .154,
  summary[26, 4] == .111, summary[26, 5] == 536)
reconstructed_tonnes <- rowSums(land[, -1] * weights[, -1])
stopifnot(abs(reconstructed_tonnes[1] - summary[1, 2]) < 1,
  abs(reconstructed_tonnes[7] - summary[7, 2]) > 90)
tuning_lines <- page(774); tuning_lines <- trimws(tuning_lines[grepl("#[[:space:]]*20[0-9]{2}[[:space:]]*$", tuning_lines)])
tuning <- do.call(rbind, lapply(tuning_lines, function(line) {
  yr <- as.integer(sub("^.*#([0-9]{4})[[:space:]]*$", "\\1", line))
  v <- numbers(sub("[[:space:]]*#[0-9]{4}[[:space:]]*$", "", line))
  stopifnot(length(v) == 16L, v[1] == 1); c(yr, v[-1])
}))
stopifnot(identical(as.integer(tuning[, 1]), 2006:2018), tuning[13, 3] == 15)
flines <- c(page(775), page(776)); start <- grep("Fishing mortalities", flines, fixed = TRUE)
end <- grep("XSA population number", flines, fixed = TRUE)
flines <- trimws(flines[seq.int(start + 1L, end - 1L)])
flines <- flines[grepl("^(10|[2-9])[[:space:]]+0\\.", flines)]
f <- do.call(rbind, lapply(flines, numbers))
stopifnot(identical(as.integer(f[, 1]), 2:10), ncol(f) == 11L, f[2, 11] == .051)
nlines <- page(776); start <- grep("XSA population number", nlines, fixed = TRUE)
end <- grep("Estimated population abundance", nlines, fixed = TRUE)
n <- year_rows(nlines[seq.int(start + 1L, end - 1L)], 2009:2018, 9L)
stopifnot(n[10, 3] == 17, n[10, 10] == 287)

blank <- function(file, count = 1L) {
  fields <- names(read.csv(file.path(db, file), nrows = 0))
  x <- as.data.frame(matrix("", count, length(fields)), stringsAsFactors = FALSE); names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- id
  x
}
input <- function(type, measure, basis, years, ages, values, unit, ref, notes, fleet = "", survey = "") {
  x <- blank("inputs.csv", length(values)); x$type <- type; x$measure <- measure; x$basis <- basis
  x$fleet <- fleet; x$survey <- survey; x$region <- "ICES divisions 7.j-k"; x$season <- "annual"
  x$year <- years; x$year_basis <- ifelse(nzchar(as.character(years)), "calendar_year", "")
  x$age <- ages; x$value <- values; x$unit <- unit; x$source_type <- "official_table"
  x$source_reference <- paste(report_url, ref); x$notes <- notes; x
}
age_input <- function(data, type, measure, basis, unit, ref, notes, fleet = "") {
  input(type, measure, basis, rep(data[, 1], each = 15L), rep(2:16, times = nrow(data)),
    as.vector(t(data[, -1])), unit, ref, notes, fleet = fleet)
}
land_note <- "Source table reports age 16+; XSA combines ages 10+ for fitting. The table does not label the number scale. Multiplication by reported kg weights is consistent with thousands of fish in some years, but differs substantially from reported totals in other years; no scaling is assumed."
weight_note <- "The report identifies catch and stock weights as the same; Figure 33.5 labels kg. Source age 16+; XSA fitted ages 10+ as a plus group. Reported zero weight for age 2 in 2018 is preserved, not interpreted as a valid biological weight."
inputs <- rbind(
  age_input(land, "catch", "landings_numbers_at_age", "numbers", "number (source scale not stated)", "Table 33.2", land_note, "7.j-k landings"),
  age_input(weights, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg/fish", "Table 7.14.3 and Figure 33.5", weight_note, "7.j-k landings"),
  age_input(weights, "weight", "weight_at_age", "kg_per_fish", "kg/fish", "Table 7.14.3 and Figure 33.5", weight_note),
  input("catch", "landings_biomass", "biomass", summary[, 1], "", summary[, 2], "tonnes", "Table 33.6", "Published 7.j-k landings total; not a separate likelihood from age-specific landings.", fleet = "7.j-k landings"),
  input("M", "natural_mortality_at_age", "per_year", "", 2:16, rep(.1, 15), "per year", "section 37.2.3", "Constant M=0.1 assumed for all ages; source age 16+; fitted terminal age is 10+."),
  input("maturity", "maturity_at_age", "proportion", "", 2:16, c(.14, .45, .88, .98, rep(1, 11)), "proportion", "section 37.2.3", "Fixed maturity ogive: ages 2, 3, 4, 5, and 6+; source sex convention not stated."))
inputs$source_type[inputs$type %in% c("M", "maturity")] <- "official_document"
tune_values <- tuning[, 3:9, drop = FALSE]
inputs <- rbind(inputs, input("index", "numbers_at_age", "index_scale", rep(tuning[, 1], each = 7L), rep(3:9, times = nrow(tuning)),
  as.vector(t(tune_values)), "numbers per 1000 hours", "Table 39.4", "Irish VMS commercial LPUE age index, not a survey; only the ages 3-9 and years 2006-2018 specified in the XSA are retained. Timing within year not stated.", survey = "Irish VMS commercial tuning index"))
output <- function(type, measure, years, ages, values, unit, notes, age_group = "") {
  x <- blank("outputs.csv", length(values)); x$type <- type; x$measure <- measure
  x$region <- "ICES divisions 7.j-k"; x$year <- years; x$age <- ages; x$age_group <- age_group
  x$value <- values; x$unit <- unit; x$source_type <- "official_table"
  x$source_reference <- paste(report_url, "Tables 7.14.5 and 33.6"); x$notes <- notes; x
}
outputs <- rbind(
  output("population", "numbers_at_age", rep(n[, 1], each = 9), rep(2:10, times = nrow(n)), as.vector(t(n[, -1])), "thousand fish", "XSA diagnostics report 2009-2018 only, rounded to thousands; age 10 is 10+. These historical values were later judged unsuitable for the current assessment."),
  output("mortality", "fishing_mortality_at_age", rep(2009:2018, each = 9), rep(2:10, times = 10), as.vector(f[, -1]), "per year", "XSA diagnostics report 2009-2018 only; age 10 is 10+, rounded to 0.001. The historical model was replaced after benchmark."),
  output("biomass", "SSB", summary[, 1], "", summary[, 5], "tonnes", "Source Table 33.6 reports absolute intermediate XSA estimates for 7.j-k; official advice used the model for relative trends only."),
  output("recruitment", "recruitment", summary[, 1], 3, summary[, 3], "thousand fish", "Age-3 XSA recruitment for 7.j-k; reported as a relative trend for the 7.h-k advice."),
  output("mortality", "Fbar", summary[, 1], "", summary[, 4], "per year", "Report summary Fbar for 7.j-k; 2019 SAG charts label ages 3-6. Official advice used relative trends only.", "3-6"))
assumptions <- blank("assumptions.csv", 5L); assumptions$component <- "assessment"
assumptions$setting <- c("official_method", "modeled_ages", "tuning_index", "natural_mortality", "historical_status")
assumptions$value <- c("Extended survivors analysis for 7.j-k, used for relative trends in 7.h-k advice", "Catch ages 2-10+, years 1993-2018; recruitment age 3", "Irish VMS commercial index, ages 3-9 and years 2006-2018; q plateau age 7", "M=0.1 for all ages", "Replaced after 2020 benchmark due to inadequate spatial coverage and model fits")
assumptions$source_reference <- paste(report_url, "sections 38 and 37")
assumptions$notes <- c("The historical assessment did not cover 7.h directly.", "Source catch and weight tables show ages 2-16+ before the fitted 10+ aggregation.", "No independent survey index was used; F shrinkage SE 1.5, 5 years and 5 ages, fleet SE threshold 0.2.", "Fixed input, not an estimated M process.", "Do not portray this historical model as the current stock assessment.")
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id; assessment$assessment_year <- 2019
assessment$terminal_year <- 2018; assessment$estimate_terminal_year <- 2018; assessment$assessment_type <- "annual"
assessment$model_family <- "XSA"; assessment$model_version <- "FLXSA 2.6.2"
assessment$is_current <- "TRUE"; assessment$is_applied <- "TRUE"; assessment$assessment_url <- report_url
assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
assessment$notes <- "2019 XSA fitted 7.j-k only; selected detailed historical assessment for this catalogue record. Used as a relative trend for broader 7.h-k advice, not a current production assessment. The later 2020 benchmark (https://doi.org/10.17895/ices.pub.5976) replaced it. Population and F-at-age outputs are available only for 2009-2018. Table 33.6 and 2019 SAG XML disagree for terminal 2019 recruitment; 2019 projection values are omitted."
stocks <- read.csv(file.path(db, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, ]; stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-WGSCE_solea_IS7jk")
stock$common_name <- "Southwest Ireland sole, 7.j-k historical XSA"; stock$area <- "ICES divisions 7.j-k"
stock$region <- "Celtic Seas"
stock$notes <- paste("Charbonneau-Keith Master identifier ICES-WGSCE_solea_IS7jk, revision 7e4daca3cbfc14ce7fa0b28ed824eebe7113249b; assessor ICES-WGSCE, catalogue source label WGSCE report 2017.pdf.", "Historical XSA fit to 7.j-k landings, used for trends in broader 7.h-k advice before 2020. The current 7.h-k unit is recorded separately as ices_sole_celtic_south_7hk.")
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
  cat("2019 source checks passed:", nrow(inputs), "inputs,", nrow(outputs), "outputs.\n")
} else {
  write_rows("stocks.csv", stock, stock_id); write_rows("assessments.csv", assessment, id)
  write_rows("assumptions.csv", assumptions, id); write_rows("inputs.csv", inputs, id); write_rows("outputs.csv", outputs, id)
  cat("Imported historical 7.j-k sole XSA source records.\n")
}
