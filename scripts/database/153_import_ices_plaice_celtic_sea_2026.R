base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_wgsce_platessa_cs7f_g")
assessment_id <- "ices_plaice_celtic_sea_7fg_2026"
stock_id <- "ck_ices_wgsce_platessa_cs7f_g"
advice_url <- "https://doi.org/10.17895/ices.advice.30932282"
report_url <- "https://doi.org/10.17895/ices.pub.32625759.v1"
repo_url <- "https://github.com/ices-advice/2026_ple.27.7fg"
revision <- "83dec5135007b7c6443d78cea8fe4c1a6a72c9fd"
verify <- function(file, expected) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256") != expected) cli::cli_abort("Cache and verify {file} before importing.")
  path
}
advice <- pdftools::pdf_text(verify("ICES_advice_2026_plaice_7fg.pdf",
  "e331df5f022cb1654950066b9b2d60bac5c4774225454002271f5150e745e070"))
report <- pdftools::pdf_text(verify("WGCSE_2026_plaice_7fg.pdf",
  "66cfe96b087c8c4e2a6e43294d282b22fc076ad6f420003fc5ef9fdac868307f"))
verify("model.R", "eeefcbbf5b8efd6806c56f9cf4b2734d1212b81adc41dea6f15a16712052fe20")
verify("report_sg.R", "f5877d83941f42b21d2a7b306d898acd8f5e06e7cead8b56fd524c937406c952")

year_rows <- function(text, years, widths) {
  lines <- strsplit(paste(text, collapse = "\n"), "\n", fixed = TRUE)[[1L]]
  lines <- trimws(lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]", lines)])
  cells <- strsplit(lines, "[[:space:]]+")
  at <- as.integer(vapply(cells, `[[`, character(1), 1L)) %in% years
  cells <- cells[at]
  stopifnot(identical(as.integer(vapply(cells, `[[`, character(1), 1L)), years),
    all(lengths(cells) == widths))
  lapply(cells, as.numeric)
}
summary <- year_rows(advice[6], 1988:2025, c(rep(3L, 16), rep(4L, 14), rep(5L, 8)))
biomass <- vapply(summary, `[[`, numeric(1), 2L)
landings <- vapply(summary, function(x) x[if (x[1] >= 2018) 4L else 3L], numeric(1))
discards <- vapply(summary, function(x) if (x[1] < 2004) NA_real_ else tail(x, 1L), numeric(1))
pressure <- vapply(tail(summary, 8L), `[[`, numeric(1), 3L)
uk <- do.call(rbind, year_rows(report[20:21], 1993:2025, rep(13L, 33)))
irish <- do.call(rbind, year_rows(report[19], 2003:2025, rep(9L, 23)))
length_rows <- year_rows(report[18], 2018:2025, c(rep(7L, 6), 4L, 4L))
length_summary <- do.call(rbind, lapply(length_rows, tail, 3L))
stopifnot(all(abs(rowSums(uk[, 2:12]) - uk[, 13]) <= 6),
  tail(biomass, 1) == 44, tail(pressure, 1) == 1.08,
  tail(landings, 1) == 107, tail(discards, 1) == 180,
  any(grepl("77 tonnes", advice[1], fixed = TRUE)),
  any(grepl("kg/100 km towed", advice[6], fixed = TRUE)),
  all(abs(length_summary[, 3] / length_summary[, 1] - pressure) < .006))

blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
input <- function(type, measure, basis, years, values, unit, reference, notes,
                  ages = "", survey = "", region = "Divisions 7.f-g", fleet = "", season = "annual") {
  x <- blank("inputs.csv", length(values))
  x$type <- type; x$measure <- measure; x$basis <- basis
  x$year <- years; x$year_basis <- "calendar_year"; x$age <- ages
  x$value <- values; x$unit <- unit; x$source_type <- "official_table"
  x$source_reference <- reference; x$notes <- notes; x$sex <- "combined"
  x$survey <- survey; x$region <- region; x$fleet <- fleet; x$season <- season
  x
}
inputs <- rbind(
  input("catch", "total_biomass", "biomass", 1988:2025, landings, "tonnes",
    paste(advice_url, "Table 8"), "Reported ICES landings, not total removals or catch-at-age. Landings and discards are separate components; no age allocation is inferred.", fleet = "Combined landings"),
  input("catch", "total_biomass", "biomass", 1988:2025, discards, "tonnes",
    paste(advice_url, "Table 8"), "Reported ICES discards. Before 2004 these table cells are blank, not zero. Earlier reconstructed discards described in the advice are not recovered here. No discard-survival adjustment is applied.", fleet = "Combined discards"),
  input("index", "relative_biomass_index", "index_scale", 1988:2025, biomass, "kg per 100 km towed",
    paste(advice_url, "Table 8; Table 4 UK [E&W]-BTS-Q3 [B6596]"),
    "Rounded UK beam-trawl biomass index used by the rfb rule, not fitted SSB. Published advice and pinned model units agree on kg/100 km; SAG's generic SSB field and kg/km2 label are not used to redefine this quantity. Timing is Q3; no model sampling fraction is inferred.", survey = "UK(E&W)-BTS-Q3", region = "Division 7.f", season = "Q3"),
  input("index", "numbers_at_age", "numbers", rep(1993:2025, 11), as.vector(uk[, 2:12]), "fish per 100 km towed",
    paste(report_url, "Table 16.7, printed pp. 520-521"),
    "Ancillary age-specific survey indices, not independent additional likelihood observations in the official biomass/length rule. Source ages 0-10+, with age 10 the plus group. Keep source zeros; do not treat the rounded total as another index. No biomass-to-numbers conversion or q adjustment.",
    ages = rep(0:10, each = 33), survey = "UK(E&W)-BTS-Q3", region = "Division 7.f", season = "Q3"),
  input("index", "numbers_at_age", "index_scale", rep(2003:2025, 7), as.vector(irish[, 3:9]), "source age index (normalization unresolved)",
    paste(report_url, "Table 16.6, printed p. 519"),
    "Ancillary Irish survey table, not used by the official rfb rule. The caption says ages 1-8+ but only columns 1-7 are printed. Preserve those labels without inventing age 8 or a plus group. Fished minutes are separate; whether cells are raw counts or effort-standardized indices remains unresolved, so no division by effort is applied.",
    ages = rep(1:7, each = 23), survey = "IGFS-WIBTS-Q4", region = "Division 7.g", season = "Q4"),
  input("covariate", "effort", "native_covariate", 2003:2025, irish[, 2], "fished minutes",
    paste(report_url, "Table 16.6, printed p. 519"),
    "Reported Irish survey fished minutes, not commercial fishing effort or an abundance observation. Retained without assuming a normalization for the adjacent age cells.", survey = "IGFS-WIBTS-Q4", region = "Division 7.g", season = "Q4"))
for (j in 1:3) {
  inputs <- rbind(inputs, input("biology",
    c("mean_catch_length", "length_at_first_capture", "MSY_proxy_length")[j],
    "native_covariate", 2018:2025, length_summary[, j], "cm",
    paste(report_url, "Table 16.5, corrected columns"),
    "Reported corrected length summary, not an age composition or reconstructed raw length-frequency series. Annual Lc is descriptive; the pinned script uses a fixed 23.5-cm cutoff for the mean-length calculation. Exact 2026 production data files remain absent."))
}

output <- function(measure, years, values, unit, notes, survey = "", type = "index") {
  x <- blank("outputs.csv", length(values))
  x$type <- type; x$measure <- measure; x$year <- years; x$value <- values
  x$unit <- unit; x$survey <- survey; x$sex <- "combined"; x$region <- "Divisions 7.f-g"
  x$season <- "annual"; x$source_type <- "official_table"
  x$source_reference <- paste(advice_url, "Table 8"); x$notes <- notes
  x
}
outputs <- rbind(
  output("survey_biomass_index", 1988:2025, biomass, "kg per 100 km towed",
    "Reported assessment indicator, not fitted SSB, absolute stock biomass or biomass-at-age. Rounded published values, without reported uncertainty. The same observed index is retained among inputs; it is not a second dataset.", "UK(E&W)-BTS-Q3"),
  output("length_based_fishing_pressure_proxy", 2018:2025, pressure, "ratio",
    "Published LF=M/Lmean indicator, not instantaneous F, Fbar or mortality-at-age. Use the final advice table; the SAG Custom1 series has discrepant values and is not substituted. No uncertainty is reported.", type = "mortality"))
assumption <- function(component, setting, value, reference, notes = "") {
  x <- blank("assumptions.csv"); x$component <- component; x$setting <- setting
  x$value <- value; x$source_reference <- reference; x$notes <- notes; x
}
native <- paste0(repo_url, "/tree/", revision)
assumptions <- rbind(
  assumption("assessment", "official_method", "ICES category 3 rfb rule, method 2.1; 2026 advice for 2027-2028", paste(advice_url, "Tables 1 and 4"), "This is not a current age-structured population fit. Advice is 77 t in each year; short-term age-structured projections are not established."),
  assumption("assessment", "framework", "Benchmark held in 2022, published in 2023; current advice invokes 2025 category-2/3 guidance", "https://doi.org/10.17895/ices.pub.21558681; https://doi.org/10.17895/ices.pub.28506179; 2026 advice references", "Historical AP, SPiCT and trial SAM outputs are not the current production assessment and are not substituted."),
  assumption("index", "stock_indicator", "UK(E&W)-BTS-Q3 biomass index in kg per 100 km towed", paste(advice_url, "Tables 4 and 8"), "Irish IGFS-WIBTS-Q4 is a supporting indicator; the age-specific tables are ancillary, not separate fitted age-index likelihoods in the official rule."),
  assumption("index", "sampling_time", "Q3 UK beam trawl; Q4 Irish survey; no numerical population-observation time in the rfb rule", paste(report_url, "section 16.3.4"), "Canonical sampling_time stays missing. Quarter labels are not exact model sampling fractions."),
  assumption("index", "irish_age_table_ambiguity", "Table 16.6 caption says ages 1-8+; header/data have seven ages 1-7", paste(report_url, "Table 16.6"), "Normalization relative to fished minutes is unresolved. No age 8, 7+ interpretation or effort division is invented."),
  assumption("catch", "inputs", "Landings and raised discards; length frequencies of the entire catch", paste(advice_url, "Table 4"), "Before 2004 discards were reconstructed from mean ratio in 2004-2010. This import preserves only reported Table-8 landings/discard cells; complete original catch-length and catch-at-age inputs are unavailable."),
  assumption("catch", "discard_survival", "Not explicitly incorporated", paste(advice_url, "p. 3"), "The cited approximate 40% survival is contextual, not a source adjustment to apply to removals."),
  assumption("assessment", "rfb_components", "Ay=114 t; two-year/three-year biomass ratio; length multiplier; biomass safeguard; life-history multiplier; conditional stability clause", paste(advice_url, "Table 1"), "Final advice has r=1.0, f=0.92, b=0.77, m=0.95, Itrigger=57 kg/100 km, Lmean2025=27.7 cm, LF=M=30.0 cm and mean 2023-2025 discard rate 50%. Rounded factors do not exactly reproduce calculations from unrounded inputs."),
  assumption("assessment", "source_conflicts", "Use final published advice over conflicting WGCSE narrative and SAG fields", paste(advice_url, "Tables 1 and 8;", report_url, "section 16.4 and Table 16.1; SAG 22650"), "WGCSE prints r=0.55 and a stale 114-t conclusion, while final advice gives r=1.0 and 77 t. SAG labels the survey index as SSB in kg/km2, has different length-proxy values, and reports 2012 discards 1115 rather than final Table-8 1123. These are not silently blended or treated as rounding differences."),
  assumption("assessment", "native_archive", "Public TAF scripts only; source CSVs and fitted rule object absent", native, "DATA.bib names PLE LPUE.csv, advice_history.csv and IC_combined.csv as local files without downloads. report_sg.R still sets ass_yr=2024. The 2026-named tree does not prove a reproducible 2026 production run; scripts were inspected, not executed."),
  assumption("population", "reported_states", "No current fitted N/F/M-at-age, recruitment or absolute SSB outputs in the recovered production assessment", paste(advice_url, "Tables 4 and 8"), "Earlier benchmark sensitivities are not official 2026 states."))

assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2026; assessment$terminal_year <- assessment$estimate_terminal_year <- 2025
assessment$assessment_type <- "biennial"; assessment$model_family <- "ICES category 3 rfb rule"
assessment$model_version <- "Method 2.1; exact production cat3advice version unverified"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2022
assessment$assessment_url <- advice_url; assessment$framework_url <- "https://doi.org/10.17895/ices.pub.21558681"
assessment$data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22650"
assessment$repository_url <- repo_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Detailed 2026 production rule and published indicators recovered through 2025, not a summary-only replacement for an unrecovered age-based fit. Published advice controls conflicts with WGCSE and SAG. Source CSVs, exact package version and fitted rule object remain missing. No current fitted age-structured population states are invented."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, ]
stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-WGSCE_platessa_CS7f-g")
stock$authority_stock_id <- "ple.27.7fg"; stock$common_name <- "Celtic Sea and Bristol Channel plaice"
stock$area <- "ICES divisions 7.f and 7.g (Bristol Channel, Celtic Sea)"
stock$region <- "Celtic Seas"; stock$ocean <- "Northeast Atlantic"
stock$notes <- "Verified identity for Charbonneau-Keith ICES-WGSCE_platessa_CS7f-g. Stable catalogue stock_id retained. Current advice uses biomass/length indicators, not the historical age-structured model label. Source review: source_reviews/ices_plaice_celtic_sea_7fg.md."

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
cat("Imported Celtic Sea plaice 2026:", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions,", nrow(outputs), "indicator outputs; source statuses partial.\n")
