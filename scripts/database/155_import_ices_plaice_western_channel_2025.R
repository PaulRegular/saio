base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_wgcse_platessa_is7e")
assessment_id <- "ices_plaice_western_channel_7e_2025"
stock_id <- "ck_ices_wgcse_platessa_is7e"
advice_url <- "https://doi.org/10.17895/ices.advice.29412776.v3"
report_url <- "https://doi.org/10.17895/ices.pub.29401877.v3"
framework_url <- "https://doi.org/10.17895/ices.pub.28400255"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19546"
revision <- "31e51a7bfd2f7ab89ff1cba2fa799d248c94893a"
repo_url <- "https://github.com/ices-advice/2025_ple.27.7e"
verify <- function(file, expected) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256") != expected) cli::cli_abort("Cache and verify {file} before importing.")
  path
}
report <- pdftools::pdf_text(verify("WGCSE_2025_plaice_7e.pdf",
  "ff81c07fc10a7dedb7a8237e45e40643f604687cf2b0a3188446943ee3bcee70"))
advice <- pdftools::pdf_text(verify("ICES_advice_2025_plaice_7e.pdf",
  "770c73f813e7a88bc94a85aaa6dca69747c41271b2956bb123150487dc453eae"))
verify("WKBPLAICE_2024_published_2025.pdf", "7802fdfcd791cb289a3deab1466a67a30ec46af13bff35c8bafa9655ca613aac")
verify("data.R", "3700cd9421ea1c12d73a08be6460aa4d32089ba35401fb09935d7d063b8da893")
verify("method.R", "b1b7831a11cd70fb0bed0fa7985bc1be97170b9f9d83e6e486bc44e0116aa210")
tables <- rvest::html_table(rvest::read_html(verify("SAG_19546.html",
  "544dd6fa19c0169ca30083f9e9edac3c3ccfb389d36ea4ce7bc0a1fc35f904b2")), fill = TRUE, convert = FALSE)
raw_sag <- Filter(function(x) all(c("Year", "SSB", "Landings", "Discards", "F") %in% names(x)), tables)
stopifnot(length(raw_sag) == 1L)
raw_sag <- as.data.frame(raw_sag[[1L]])
sag <- as.data.frame(lapply(raw_sag, function(x) suppressWarnings(as.numeric(x))))
stopifnot(identical(sag$Year, as.numeric(1980:2024)), all(is.finite(sag$Landings)),
  all(is.na(sag$Discards[sag$Year < 2002])), all(is.finite(sag$Discards[sag$Year >= 2002])),
  all(is.na(sag$SSB[sag$Year < 2003])), all(is.finite(sag$SSB[sag$Year >= 2003])))
year_rows <- function(page) {
  lines <- strsplit(page, "\n")[[1L]]
  cells <- strsplit(trimws(lines[grepl("^\\s*20[0-9]{2}\\s+", lines)]), "[[:space:]]+")
  stopifnot(length(cells) == 22L, all(lengths(cells) == 7L))
  x <- do.call(rbind, lapply(cells, as.numeric))
  stopifnot(identical(as.integer(x[, 1]), 2003:2024))
  x
}
summary <- year_rows(report[17])
stopifnot(identical(summary, year_rows(advice[7])))
z <- sag[sag$Year >= 2003, ]
raw_z <- raw_sag[sag$Year >= 2003, ]
half_unit <- function(x) ifelse(grepl(".", x, fixed = TRUE), .5 * 10^-nchar(sub(".*\\.", "", x)), .5)
l_tol <- half_unit(raw_z$Landings); d_tol <- half_unit(raw_z$Discards); i_tol <- half_unit(raw_z$SSB)
stopifnot(all(abs(z$Landings - summary[, 2]) <= .5 + 1e-8),
  all(abs(z$Discards - summary[, 3]) <= .5 + 1e-8),
  all(abs(z$Landings + z$Discards - summary[, 4]) <= .5 + l_tol + d_tol + 1e-8),
  all(abs(z$Landings + .5 * z$Discards - summary[, 5]) <= .5 + l_tol + .5 * d_tol + 1e-8),
  all(abs(z$SSB - summary[, 6]) <= c(rep(.005, 11), .05, rep(.005, 10)) + 1e-8),
  identical(z$F, summary[, 7]))
hr_lower <- (z$Landings - l_tol + .5 * (z$Discards - d_tol)) / (z$SSB + i_tol)
hr_upper <- (z$Landings + l_tol + .5 * (z$Discards + d_tol)) / (z$SSB - i_tol)
stopifnot(all(z$F + .5 >= hr_lower), all(z$F - .5 <= hr_upper),
  abs(mean(head((z$Landings + .5 * z$Discards) / z$SSB, 21)) * .66 / 1.0668263407026402 - 1424) < .5,
  abs(mean(tail(z$SSB, 2)) - .7252319) < .00005)

blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
input <- function(type, measure, basis, values, years, unit, reference, notes, fleet = "", survey = "") {
  x <- blank("inputs.csv", length(values)); x$type <- type; x$measure <- measure; x$basis <- basis
  x$value <- values; x$year <- years; x$year_basis <- "calendar_year"; x$unit <- unit
  x$sex <- "combined"; x$region <- "Division 7.e stock, including migration catches in 7.d"
  x$season <- "annual"; x$fleet <- fleet; x$survey <- survey
  x$source_type <- "official_machine_readable"; x$source_reference <- reference; x$notes <- notes; x
}
inputs <- rbind(
  input("catch", "landings_biomass", "biomass", sag$Landings, 1980:2024, "tonnes", sag_url,
    "Stock-level landings, including the source migration correction for fish of the 7.e stock caught in 7.d. Not area-7.e-only landings or catch-at-age. Landings, discards and total catch are components of one fishery, not independent fleets.", "Combined commercial fishery"),
  input("catch", "discard_biomass", "biomass", sag$Discards, 1980:2024, "tonnes", sag_url,
    "Stock-level discards including migration correction. Cells before 2002 are unavailable, not zero. Total discards include surviving fish; the rule assumes 50% survival. No source observations are changed here.", "Combined commercial fishery"),
  input("catch", "total_biomass", "biomass", summary[, 4], 2003:2024, "tonnes", paste(advice_url, "Table 9;", report_url, "Table 15.3"),
    "Published total catch of the stock, including surviving discards and the migration correction. Rounded independently of its landings/discard components; not another independent observation or dead-removal series.", "Combined commercial fishery"),
  input("index", "relative_biomass_index", "index_scale", z$SSB, 2003:2024, "kg per hour per metre beam", sag_url,
    "FSP-Q3 B4381 biomass index summed over ages 2-8, as specified by native data.R. Not absolute biomass or SSB, and not a single-age number index. Q3 is retained as the survey season; no exact population-observation fraction is inferred.", survey = "UK-FSP-Q3 (B4381)"))
inputs$source_type[inputs$measure == "total_biomass"] <- "official_table"
inputs$region[inputs$type == "index"] <- "Division 7.e survey area"
inputs$season[inputs$type == "index"] <- "Q3"
output <- function(measure, values, unit, notes, type, reference) {
  x <- blank("outputs.csv", 22L); x$type <- type; x$measure <- measure; x$value <- values
  x$year <- 2003:2024; x$unit <- unit; x$sex <- "combined"; x$season <- "annual"
  x$region <- "Division 7.e stock, including migration catches in 7.d"
  x$source_type <- "official_machine_readable"; x$source_reference <- reference
  x$notes <- paste(notes, "No uncertainty is reported; no SE or interval is invented."); x
}
outputs <- rbind(
  output("survey_biomass_index", z$SSB, "kg per hour per metre beam", "Reported observed biomass indicator, not fitted SSB. Same series as the index inputs, not another dataset.", "index", sag_url),
  output("relative_harvest_rate", z$F, "tonnes per (kg per hour per metre beam)", "Assumed dead catch divided by the biomass index; a relative harvest-rate indicator, not instantaneous F or Fbar. Source values are rounded; exact identities need unrounded inputs.", "mortality", sag_url),
  output("assumed_dead_catch", summary[, 5], "tonnes", "Published landings plus the assumed dead half of discards, including migration. This is an observed-catch summary under a survival assumption, not predicted catch or a new likelihood observation.", "catch", paste(advice_url, "Table 9;", report_url, "Table 15.3")))
outputs$survey[outputs$measure == "survey_biomass_index"] <- "UK-FSP-Q3 (B4381)"
outputs$region[outputs$measure == "survey_biomass_index"] <- "Division 7.e survey area"
outputs$source_type[outputs$measure == "assumed_dead_catch"] <- "official_table"
assumption <- function(component, setting, value, reference, notes = "") {
  x <- blank("assumptions.csv"); x$component <- component; x$setting <- setting
  x$value <- value; x$source_reference <- reference; x$notes <- notes; x
}
native <- paste0(repo_url, "/tree/", revision)
assumptions <- rbind(
  assumption("assessment", "official_method", "Category 3 chr rule, method 2.2; 2025 advice for 2026-2027", paste(advice_url, "Tables 1 and 5"), "The rule was tuned in a stock-specific MSE at WKBPLAICE in 2024, published in 2025. Trial analytical models and MSE operating-model states are not the annual production assessment."),
  assumption("catch", "stock_area_mapping", "Stock-level landings/discards include migrating 7.e fish caught in 7.d", paste(report_url, "sections 15.6.3 and 15.8"), "The historical migration correction adds 15% of the mature Q1 catch from 7.d. The advice discusses a revised forecast allocation from the 2025 eastern Channel benchmark. Do not apply a new correction to already corrected stock totals."),
  assumption("catch", "discard_survival", "50%; dead catch = landings + 0.5 * discards", paste(advice_url, "p. 3; Table 9"), "Total catch includes surviving discards. Native relative harvest rate uses dead catch; total advice adds back surviving discards using 1-discard_rate*survival in the denominator."),
  assumption("index", "input_definition", "UK-FSP-Q3 B4381 biomass index, sum of ages 2-8, kg per hour per metre beam", paste(native, "/data.R;", report_url, "15.5.7 and 15.6.1"), "The Q1SWBeam survey is not used. Age-specific source WAAge2-WAAge8 cells are not publicly archived in this production tree; no age-specific index is manufactured from the total."),
  assumption("index", "sampling_time", "Q3; no exact population-observation fraction used by the chr rule", paste(report_url, "15.5.7.1"), "sampling_time remains blank. A seasonal label is not an exact sampling date."),
  assumption("assessment", "rule_parameters", "I is the latest two-year mean; HR target is 2003-2023 mean harvest rate times 0.66/1.0668263407026402; Itrigger=3.7*I2007; b=min(1,I/Itrigger); m=1", paste(native, "/method.R;", report_url, "15.6.2"), "Target HR is about 1424 tonnes per index unit; Itrigger about 1.037248. Declared v=2 is not passed as an active parameter in method.R; no extra safeguard exponent is inferred."),
  assumption("assessment", "catch_advice", "872 t total stock catch in each of 2026/2027; assumed dead catch about 722 t", paste(advice_url, "Table 1"), "Discard rate averages annual ratios over 2012-2024, about 34.35034%. This is not the ratio of pooled discards to pooled total catch. Stability clause is not applied because the index is below Itrigger."),
  assumption("assessment", "area_advice", "819 t catch in area 7.e; stock advice 872 t includes catch in 7.d", paste(advice_url, "Table 2 and p. 3"), "The forecast migration catch is rounded as 54 t in Table 2 and 53 t in the narrative. Unrounded calculations underlie rounded table entries; do not repair them by forcing rounded sums."),
  assumption("assessment", "data_revisions", "2021-2023 UK catch, 2022-2023 FSP index and migration corrections revised before the 2025 advice", paste(advice_url, "p. 3;", report_url, "15.3"), "The index revision also affects earlier standardized values. Historical benchmark/example arrays and the 2026 monitoring update are not spliced into this vintage."),
  assumption("assessment", "software", "Declared cat3advice 0.1.1 at fca97de; icesTAF 4.2.0", paste(native, "/boot/SOFTWARE.bib"), "The exact fitted advice.rds is not in the public tree. The declared software/configuration is preserved without claiming a verified executed production object."),
  assumption("assessment", "remaining_native_inputs", "Four local source CSVs and method/advice.rds are absent from the public tree", paste(native, "/boot/DATA.bib"), "Missing files: FSP_biomass.csv, advice_history.csv, ple7d_STF_removals_from_7e_2024.csv and idxB_percentiles.csv. Aggregate input values are recovered from tables, but complete native dimensions, unrounded migration components and MSE exception-range inputs remain incomplete."),
  assumption("assessment", "2026_monitoring", "WGCSE 2026 updates data through 2025 but explicitly gives no new advice", "https://doi.org/10.17895/ices.pub.32625759; chapter 15", "The 2025 assessment remains the production advice event. Later monitoring data are cached separately and do not extend this event's observed years."),
  assumption("population", "reported_states", "No annual fitted N/F/M-at-age, recruitment or absolute SSB from this production rule", paste(advice_url, "Quality of the assessment; Table 9"), "The survey biomass and relative harvest-rate indicators are not SSB or F estimates. Historical assessment trials and MSE operating-model states are not substituted."))
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2025; assessment$terminal_year <- assessment$estimate_terminal_year <- 2024
assessment$assessment_type <- "biennial_after_benchmark"; assessment$model_family <- "ICES category 3 chr rule"
assessment$model_version <- "Declared cat3advice 0.1.1 (fca97de), icesTAF 4.2.0"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2024
assessment$assessment_url <- advice_url; assessment$framework_url <- framework_url
assessment$data_url <- sag_url; assessment$repository_url <- repo_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Latest production advice is the 2025 MSE-tuned chr rule using data through 2024. WGCSE 2026 monitoring does not issue new advice and is not mixed into this event. Stock catches include migration; total catch and assumed dead catch differ because discard survival is 50%. Aggregate observations and indicators recovered; native source CSVs and executed advice object remain missing. No current age-structured population states are implied."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, ]
stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-WGCSE_platessa_IS7e", stock$scientific_name == "Pleuronectes platessa")
stock$authority_stock_id <- "ple.27.7e"; stock$common_name <- "Western English Channel plaice"
stock$area <- "ICES Division 7.e stock, including its spawning-migration catch in Division 7.d"
stock$region <- "Western English Channel"; stock$ocean <- "Northeast Atlantic"
stock$notes <- "Verified identity of Charbonneau-Keith ICES-WGCSE_platessa_IS7e; stable stock_id retained. Official Division 7.e is the western English Channel, despite the catalogue's IS prefix. Current production advice is an MSE-tuned chr rule, not a historical analytical model. Source review: source_reviews/ices_plaice_western_channel_7e.md."
write_rows <- function(file, x, id = assessment_id) {
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
write_rows("stocks.csv", stock, stock_id)
for (file in c("assessments", "assumptions", "inputs", "outputs")) {
  write_rows(paste0(file, ".csv"), if (file == "assessments") assessment else get(file))
}
cat("Imported western English Channel plaice 2025:", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions,", nrow(outputs), "indicator/assumed-catch outputs; source statuses partial.\n")
