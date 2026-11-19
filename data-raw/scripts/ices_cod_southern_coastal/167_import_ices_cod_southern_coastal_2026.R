base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_afwg_morhua_coastnor_1_2/assessment_2026")
stock_id <- "ices_cod_southern_coastal"
id <- "ices_cod_southern_coastal_2026"
report_url <- "https://doi.org/10.17895/ices.pub.32134696.v1"
sag_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/23775"
advice_url <- "https://doi.org/10.17895/ices.advice.30932009"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  actual <- digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
  if (!identical(actual, sha)) stop("Cached source checksum differs: ", file)
  path
}
invisible(verify("AFWG 2026 Report.pdf", "35db72d64947ea001e16ab358fd48f4f55caae958c80a861348e5a4b778d77b1"))
lines <- readLines(verify("report-pages.txt", "e0bfb410807fded94c7d314e844acffa2001ac761d4235651a4394faab4485d9"), encoding = "UTF-8", warn = FALSE)
xml <- xml2::read_xml(verify("SAG_2026_southern_key_23775.xml", "16d46a9ec304564e900312ae98b781f099871a23bea8a0530a5ef08aa99719ea"))
stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockCode")) == "cod.27.2.coastS",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/AssessmentYear")) == "2026",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/CustomSeriesName1")) == "Recreational",
  xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/CustomSeriesName2")) == "Commercial")
table <- function(first, last, years, fields) {
  a <- grep(paste0("^[[:space:]]*Table 2\\.3\\.", first, "\\."), lines)
  b <- grep(paste0("^[[:space:]]*Table 2\\.3\\.", last, "\\."), lines)
  stopifnot(length(a) == 1L, length(b) == 1L, b > a)
  x <- lines[seq.int(a + 1L, b - 1L)]
  x <- trimws(x[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9]", x)])
  tokens <- strsplit(x, "[[:space:]]+")
  stopifnot(all(lengths(tokens) == fields))
  m <- do.call(rbind, lapply(tokens, as.numeric))
  stopifnot(identical(as.integer(m[, 1]), years), all(is.finite(m))); m
}
commercial <- table(1, 2, 1994:2025, 11L)
total_age <- table(2, 3, 1994:2025, 12L)
weights <- table(4, 5, 1994:2025, 10L)
trawl <- table(5, 6, 2003:2025, 5L)
net <- table(6, 7, 2013:2025, 5L)
relative <- table(7, 8, 1977:2025, 7L)
stopifnot(commercial[32, 11] == 2181, total_age[32, 11] == 6976,
  total_age[32, 12] == 4795, trawl[23, 3] == 7890, net[13, 3] == 359,
  relative[49, 3] == .42, relative[49, 6] == 1.55)
fish <- xml2::xml_find_all(xml, "/Assessment/Fish_Data")
field <- function(n) suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(fish, n))))
all_years <- field("Year")
for (pair in list(c("Low_StockSize", 2), c("StockSize", 3), c("High_StockSize", 4),
                  c("Low_FishingPressure", 5), c("FishingPressure", 6), c("High_FishingPressure", 7))) {
  values <- field(pair[1])[match(relative[, 1], all_years)]
  stopifnot(all(values == relative[, as.integer(pair[2])]))
}
year <- all_years; rec <- field("CustomSeries1"); comm <- field("CustomSeries2")
keep <- year %in% 1977:2025 & is.finite(rec) & is.finite(comm)
year <- year[keep]; rec <- rec[keep]; comm <- comm[keep]
stopifnot(identical(as.integer(year), 1977:2025), rec[49] == 4795, comm[49] == 2181,
  all(abs((rec + comm)[match(total_age[, 1], year)] - total_age[, 11]) <= 1),
  all(comm[match(commercial[, 1], year)] == commercial[, 11]))
blank <- function(file, count = 1L) {
  fields <- names(read.csv(file.path(db, file), nrows = 0))
  x <- as.data.frame(matrix("", count, length(fields)), stringsAsFactors = FALSE); names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- id
  x
}
input <- function(type, measure, basis, years, ages, values, unit, ref, notes, fleet = "", survey = "", season = "annual", source = "official_table") {
  x <- blank("inputs.csv", length(values)); x$type <- type; x$measure <- measure; x$basis <- basis
  x$fleet <- fleet; x$survey <- survey; x$region <- "Norwegian coast 62-67 N"; x$season <- season
  x$year <- years; x$year_basis <- ifelse(nzchar(as.character(years)), "calendar_year", "")
  x$age <- ages; x$value <- values; x$unit <- unit; x$source_type <- source
  x$source_reference <- ref; x$notes <- notes; x
}
age_input <- function(data, type, measure, basis, unit, table_no, note, fleet) {
  input(type, measure, basis, rep(data[, 1], each = 9L), rep(2:10, times = nrow(data)),
    as.vector(t(data[, 2:10])), unit, paste(report_url, paste0("Table 2.3.", table_no)), note, fleet = fleet)
}
total <- input("catch", "total_biomass", "biomass", year, "", rec + comm, "tonnes", sag_url,
  "Commercial plus recreational catch used by SPiCT. Reconstructed as the sum of SAG commercial and recreational series, and checked against AFWG Table 2.3.2 from 1994. Recreational catch is highly uncertain; component and age rows are not independent likelihoods.", fleet = "Total catch", source = "reconstructed_source_input")
total$transformation <- "Commercial plus recreational catch in the same year."
published <- match(total$year, total_age[, 1]); use_table <- !is.na(published)
total$value[use_table] <- total_age[published[use_table], 11]
total$source_type[use_table] <- "official_table"
total$source_reference[use_table] <- paste(report_url, "Table 2.3.2")
total$transformation[use_table] <- ""
total$notes[use_table] <- "Reported total catch used by SPiCT. Recreational catch is highly uncertain; commercial and recreational components and age rows are not independent likelihoods. Rounded source total may differ from the sum of separately rounded components."
inputs <- rbind(total,
  input("catch", "landings_biomass", "biomass", year, "", comm, "tonnes", sag_url,
    "Commercial catch component; it is included in total SPiCT catch and not an independent likelihood.", fleet = "Commercial catch", source = "official_machine_readable"),
  input("catch", "total_biomass", "biomass", year, "", rec, "tonnes", sag_url,
    "Estimated recreational catch component, included in total SPiCT catch; assumptions and uncertainty are substantial. This is not an independent likelihood.", fleet = "Recreational catch", source = "official_machine_readable"),
  age_input(commercial, "catch", "landings_numbers_at_age", "numbers", "thousand fish", 1,
    "Commercial landings-at-age, source rounded to thousands; age 10 is 10+. Ancillary to the aggregate-biomass SPiCT likelihood.", "Commercial catch"),
  age_input(total_age, "catch", "numbers_at_age", "numbers", "thousand fish", 2,
    "Estimated total catch-at-age including recreation, with recreational age proportions assumed equal to commercial. Age 10 is 10+; ancillary to the aggregate SPiCT likelihood, not a separate observation.", "Total catch"),
  age_input(weights, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg/fish", 4,
    "Commercial catch weight-at-age; age 10 is 10+. Figure 2.3.7 labels weights in kg. Not an input to the aggregate SPiCT likelihood.", "Commercial catch"))
survey_input <- function(data, name, table_no, season, notes) {
  ref <- paste(report_url, paste0("Table 2.3.", table_no))
  yr <- data[, 1]; interval <- paste0(notes, " Reported 95% interval: ", data[, 2], " to ", data[, 4], " kg.")
  rbind(input("index", "relative_biomass_index", "index_scale", yr, "", data[, 3], "kg", ref, interval, survey = name, season = season),
    input("index", "log_index_sd", "log_scale", yr, "", data[, 5], "log-scale SE", ref,
      "Reported annual SE of the log index, not a natural-scale SE. The source model uses priors on index observation error; do not assume these annual SEs are directly fixed likelihood weights.", survey = name, season = season))
}
inputs <- rbind(inputs,
  survey_input(trawl, "Coastal acoustic-trawl survey A6335, trawl index", 5, "fall", "Spatiotemporal index of coastal cod biomass at least 50 cm from trawl data. This is not the acoustic index, which was removed from the 2026 assessment. The survey is Q4; exact within-year timing is not supplied."),
  survey_input(net, "Shallow net survey N5624", 6, "annual", "Spatiotemporal index of coastal cod biomass at least 50 cm. Exact within-year timing is not supplied."))
output <- function(measure, values, lower, upper, type) {
  x <- blank("outputs.csv", length(values)); x$type <- type; x$measure <- measure; x$year <- relative[, 1]
  x$region <- "Norwegian coast 62-67 N"; x$value <- values; x$lwr <- lower; x$upr <- upper
  x$unit <- "ratio"; x$source_type <- "official_table"; x$source_reference <- paste(report_url, "Table 2.3.7")
  x$notes <- "SPiCT relative stock state; 95% confidence limits. This is not absolute SSB or instantaneous F; 2026 forecast is excluded."; x
}
outputs <- rbind(output("B_over_Bmsy", relative[, 3], relative[, 2], relative[, 4], "biomass"),
  output("F_over_Fmsy", relative[, 6], relative[, 5], relative[, 7], "mortality"))
msy <- blank("outputs.csv"); msy$type <- "catch"; msy$measure <- "msy"; msy$value <- 10664
msy$lwr <- 8974; msy$upr <- 12672; msy$unit <- "tonnes"; msy$region <- "Norwegian coast 62-67 N"
msy$source_type <- "official_document"; msy$source_reference <- paste(report_url, "section 2.3.1")
msy$notes <- "SPiCT-estimated MSY with reported 95% confidence interval; not an absolute B or F reference point."
outputs <- rbind(outputs, msy)
assumptions <- blank("assumptions.csv", 6L); assumptions$component <- "assessment"
assumptions$setting <- c("official_method", "catch_input", "index_inputs", "index_uncertainty", "production_priors", "advice_rule")
assumptions$value <- c("SPiCT surplus production model", "Total commercial and recreational catch, 1977-2025", "Coastal trawl index 2003-2025 and shallow net index 2013-2025, 50+ cm biomass", "Prior for shallow-net observation error uses mean annual log index SE 0.12", "Several priors are required; exact full settings remain unresolved", "Hockey-stick MSY rule with 15th percentile of predicted catch")
assumptions$source_reference <- paste(report_url, "sections 2.3.3-2.3.7")
assumptions$notes <- c("2024 SPiCT benchmark; age tables are supporting observations, not age-structured likelihoods.", "Recreational estimates have substantial uncertainty; commercial and recreational components should not be added again to total catch.", "Acoustic index was removed in 2026. Neither retained index is age specific.", "Report warns the mean SE may be artificially low due to temporal smoothing; annual table SEs are not asserted to be fixed observation-error SDs.", "The production run and complete stock annex were not recovered; do not infer exact prior parameters or activation.", "Source advice for 2027 is 3472 tonnes; 2025 advice for 2026 was revised for comparison due to corrected harvest control rule.")
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id; assessment$assessment_year <- 2026
assessment$terminal_year <- 2025; assessment$estimate_terminal_year <- 2025; assessment$assessment_type <- "annual"
assessment$model_family <- "SPiCT"; assessment$model_version <- "2026 AFWG production run; exact package version not recovered"
assessment$is_current <- "TRUE"; assessment$is_applied <- "TRUE"; assessment$framework_year <- 2024
assessment$assessment_url <- report_url; assessment$framework_url <- "https://doi.org/10.17895/ices.pub.24998858"
assessment$data_url <- sag_url; assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
assessment$notes <- "Official 2026 SPiCT assessment, with 2025 terminal data. Annual catch and two 50+ cm indices are recovered; exact native run and full prior/observation-error configuration remain unavailable. Catch-at-age is ancillary and recreational age composition is assumed. SPiCT reports relative states, not age-specific N, F, SSB or recruitment."
stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$authority <- "ICES"; stock$authority_stock_id <- "cod.27.2.coastS"
stock$scientific_name <- "Gadus morhua"; stock$common_name <- "Southern Norwegian coastal cod"
stock$area <- "ICES subarea 2 between 62 and 67 degrees N"; stock$region <- "Norwegian Sea"; stock$ocean <- "Northeast Atlantic"
stock$notes <- "Southern component of the former Charbonneau-Keith COASTNOR 1,2 unit, separated in the 2021 benchmark. Northern and historical composite units remain separate; see source review."
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
  cat("Southern coastal cod source checks passed:", nrow(inputs), "inputs and", nrow(outputs), "outputs.\n")
} else {
  write_rows("stocks.csv", stock, stock_id); write_rows("assessments.csv", assessment, id)
  write_rows("assumptions.csv", assumptions, id); write_rows("inputs.csv", inputs, id); write_rows("outputs.csv", outputs, id)
  cat("Imported southern coastal cod 2026 assessment.\n")
}
