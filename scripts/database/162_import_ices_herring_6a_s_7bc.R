base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_hawg_harengus_cs6_a_s_7b_c")
stock_id <- "ck_ices_hawg_harengus_cs6_a_s_7b_c"
report_2025 <- "https://doi.org/10.17895/ices.pub.28389008.v5"
report_2026 <- "https://doi.org/10.17895/ices.pub.31424315"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size), serialize = FALSE, algo = "sha256") != sha)
    cli::cli_abort("Cached source {file} is missing or differs from its pinned checksum.")
  path
}
invisible(verify("../ck_ices_hawg_dubius_ns/2025_san.sa.4/HAWG_2025.pdf", "06967082a29ef54ffb33ce7d2e8f89a4695dd6d1ca70f3e78510c03c6c813097"))
invisible(verify("HAWG_2026_full_report.pdf", "0af113dedfea05c1dabc75402ebd5846d4a6ea931e121ca9e9702b0811c9832e"))
paths <- list(
  `2025` = list(
    report = verify("HAWG_2025_pages_374_410.txt", "b6316977e7141078d481f0a3ae76c3e2f2246fdcc8a6c1cb5a8272871085de4f"),
    xml = verify("SAG_2025_key_19342.xml", "b013dc62e8de881a51bab685392252c1bc969c3461a65b4cc17c4d9bf318d736"),
    advice = verify("ICES_advice_6aS_2025.pdf", "c86d7d8fdfde5823e2ff9b7f96589fb17a1a3857ab5e9ca320a967a813bd6951")
  ),
  `2026` = list(
    report = verify("HAWG_2026_full_report.txt", "7b2b8995006e738e6868b25c086e255f387bdf060189543ee6a05593cac3c9a3"),
    xml = verify("SAG_2026_key_21289.xml", "5536634ff642910fbfbb7bc0a0c67ffb75a246984a1c794c2132ff8b066862fa"),
    advice = verify("ICES_advice_6aS_2026.pdf", "8d9256a6408ac20b825ee3482cd24973731a50ad51cdf8078a5b4a88bfa64e27")
  )
)

section <- function(lines, first, last) {
  a <- grep(paste0("^Table ", first, "\\."), lines)
  b <- grep(paste0("^Table ", last, "\\."), lines)
  if (length(a) != 1L) stop("Ambiguous source table start: ", first)
  b <- b[b > a]
  if (length(b) != 1L) stop("Ambiguous source table end: ", last)
  lines[seq.int(a + 1L, b - 1L)]
}
age_table <- function(lines, first, last, fix_catch = FALSE) {
  x <- section(lines, first, last)
  if (fix_catch) {
    i <- grep("^1991 675 34437 27810 12420 10044[[:space:]]*$", x)
    if (length(i) != 1L || trimws(x[i + 1L]) != "4" || trimws(x[i + 2L]) != "17921 14865 11311 7660")
      stop("The 1991 age-5 wrapped source cell is not as expected.")
    x[i] <- paste0(trimws(x[i]), "4 ", trimws(x[i + 2L]))
    x <- x[-c(i + 1L, i + 2L)]
  }
  x <- trimws(x[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[-0-9]", x)])
  cells <- strsplit(x, "[[:space:]]+")
  if (!all(lengths(cells) == 10L)) stop("Unexpected age-table columns: ", paste(x[lengths(cells) != 10L], collapse = " | "))
  years <- as.integer(vapply(cells, `[[`, "", 1L))
  values <- do.call(rbind, lapply(cells, function(z) suppressWarnings(as.numeric(z[-1L]))))
  if (anyDuplicated(years)) stop("Duplicate age-table year.")
  list(year = years, value = values)
}
# The PDF leaves some age columns blank and wraps early survey rows across lines.
# Age masks follow the printed columns on the rendered source pages.
survey_table <- function(lines, first, last, masks, extra = 0L) {
  x <- trimws(section(lines, first, last))
  starts <- grep("^20[0-9]{2}[[:space:]]+her-", x)
  if (!length(starts)) stop("Survey table has no identifiable rows.")
  result <- lapply(seq_along(starts), function(i) {
    start <- starts[i]; end <- if (i < length(starts)) starts[i + 1L] - 1L else length(x)
    yr <- substr(x[start], 1, 4); mask <- masks[[yr]]
    if (is.null(mask)) stop("Unexpected survey year: ", yr)
    first_part <- sub("^20[0-9]{2}[[:space:]]+her-[^[:space:]]+[[:space:]]*", "", x[start])
    rest <- if (end > start) x[(start + 1L):end] else character()
    rest <- rest[grepl("^[0-9.]+([[:space:]]+[0-9.]+)*[[:space:]]*$", rest)]
    cells <- strsplit(trimws(paste(c(first_part, rest), collapse = " ")), "[[:space:]]+")[[1L]]
    if (length(cells) != length(mask) + extra) stop("Unexpected survey cells in ", yr, ": ", paste(cells, collapse = " "))
    list(year = as.integer(yr), age = mask, age_values = as.numeric(cells[seq_along(mask)]),
      extra = if (extra) as.numeric(tail(cells, extra)) else numeric())
  })
  if (anyDuplicated(vapply(result, `[[`, integer(1), "year"))) stop("Duplicate survey year.")
  result
}

blank <- function(file, id, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- id
  x
}
input <- function(id, type, measure, basis, year, age, value, unit, ref, notes,
                  fleet = "", survey = "", season = "annual") {
  x <- blank("inputs.csv", id, length(value))
  x$type <- type; x$measure <- measure; x$basis <- basis; x$year <- year
  x$year_basis <- ifelse(nzchar(as.character(year)), "calendar_year", "")
  x$age <- age; x$value <- value; x$unit <- unit; x$fleet <- fleet
  x$survey <- survey; x$sex <- "combined"; x$region <- "ICES divisions 6.a South and 7.b-c"
  x$season <- season; x$source_type <- "official_table"; x$source_reference <- ref
  x$notes <- notes; x
}
output <- function(id, measure, years, values, unit, ref, notes, type = "index") {
  x <- blank("outputs.csv", id, length(values))
  x$type <- type; x$measure <- measure; x$year <- years; x$value <- values
  x$unit <- unit; x$survey <- "MSHAS 6.aS 7.b-c"; x$sex <- "combined"
  x$region <- "ICES divisions 6.a South and 7.b-c"; x$season <- "summer"
  x$source_type <- "official_machine_readable"; x$source_reference <- ref
  x$notes <- notes; x
}
assumption <- function(id, component, setting, value, reference, notes = "") {
  x <- blank("assumptions.csv", id); x$component <- component; x$setting <- setting
  x$value <- value; x$source_reference <- reference; x$notes <- notes; x
}
extract <- function(year) {
  id <- paste0("ices_herring_6a_s_7bc_", year)
  source <- paths[[as.character(year)]]
  report_url <- if (year == 2025L) report_2025 else report_2026
  advice_url <- if (year == 2025L) "https://doi.org/10.17895/ices.advice.27202635" else "https://doi.org/10.17895/ices.advice.32133673"
  key <- if (year == 2025L) 19342 else 21289
  sag_url <- paste0("https://sag.ices.dk/SAG_API/StockXmlDownload/", key)
  text <- readLines(source$report, encoding = "UTF-8", warn = FALSE)
  catch <- age_table(text, "5\\.2\\.1\\.1", "5\\.2\\.1\\.2", fix_catch = TRUE)
  cw <- age_table(text, "5\\.4\\.1\\.1", "5\\.4\\.1\\.2")
  sw <- age_table(text, "5\\.4\\.1\\.2", "5\\.3\\.1\\.1")
  years <- 1970:(year - 1L)
  stopifnot(identical(catch$year, years), identical(cw$year, years), identical(sw$year, years),
    catch$value[catch$year == 1991, 5] == 100444,
    catch$value[catch$year == 2024, 3] == 7621)
  num_age <- list(`2014`=2:9, `2015`=2:8, `2016`=2:9, `2017`=2:9,
    `2018`=1:9, `2019`=1:9, `2020`=1:9, `2021`=1:9, `2022`=1:9,
    `2023`=1:9, `2024`=1:9, `2025`=1:9)
  weight_age <- num_age; weight_age[["2025"]] <- 1:8
  maturity_age <- num_age; maturity_age[["2014"]] <- 1:9
  maturity_age[["2015"]] <- 1:8; maturity_age[["2016"]] <- 1:9
  maturity_age[["2017"]] <- 1:9; maturity_age[["2025"]] <- 1:8
  survey <- survey_table(text, "5\\.3\\.1\\.1", "5\\.3\\.1\\.2", num_age, 2L)
  swt <- survey_table(text, "5\\.3\\.1\\.2", "5\\.3\\.1\\.3", weight_age)
  mat <- survey_table(text, "5\\.3\\.1\\.3", "5\\.3\\.2\\.1", maturity_age)
  sy <- vapply(survey, `[[`, integer(1), "year")
  stopifnot(identical(sy, 2014:(year - 1L)), survey[[1]]$age[1] == 2,
    survey[[which(sy == 2024)]]$extra[2] == 54657)
  flatten <- function(x) data.frame(year = rep(vapply(x, `[[`, integer(1), "year"), lengths(lapply(x, `[[`, "age"))),
    age = unlist(lapply(x, `[[`, "age")), value = unlist(lapply(x, `[[`, "age_values")))
  survey_age <- flatten(survey); survey_weight <- flatten(swt); maturity <- flatten(mat)
  length_rows <- section(text, "5\\.6\\.2\\.5a", "5\\.6\\.2\\.5b")
  length_rows <- trimws(length_rows[grepl("^[[:space:]]*20[0-9]{2}[[:space:]]+[0-9]", length_rows)])
  cells <- strsplit(length_rows, "[[:space:]]+")
  if (!all(lengths(cells) == 8L)) stop("Unexpected length-indicator table columns.")
  lengths_table <- do.call(rbind, lapply(cells, function(x) as.numeric(gsub(",", "", x, fixed = TRUE))))
  stopifnot(identical(as.integer(lengths_table[, 1]), sy),
    all(lengths_table[, 2] == vapply(survey, function(row) row$extra[2], numeric(1))), lengths_table[lengths_table[, 1] == 2024, 6] == 25.4)
  xml <- xml2::read_xml(source$xml)
  stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockCode")) == "her.27.6aS7bc",
    as.integer(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/AssessmentYear"))) == year)
  fish <- xml2::xml_find_all(xml, "/Assessment/Fish_Data")
  readfield <- function(field) suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(fish, field))))
  sag <- data.frame(year = readfield("Year"), catch = readfield("Catches"),
    index = readfield("StockSize"), harvest = readfield("FishingPressure"))
  idx <- sag[is.finite(sag$index) & sag$year %in% sy, ]
  cv <- vapply(survey, function(row) row$extra[1], numeric(1))
  reported_index <- vapply(survey, function(row) row$extra[2], numeric(1))
  stopifnot(identical(as.integer(idx$year), sy), all(idx$index == reported_index),
    idx$index[idx$year == 2024] == 54657)
  if (year == 2026L) stopifnot(idx$index[idx$year == 2025] == 7774,
    !any(survey_weight$year == 2025 & survey_weight$age == 9))
  ca <- sag[is.finite(sag$catch) & sag$year <= year - 1L, ]
  pressure <- sag[is.finite(sag$harvest) & sag$year %in% sy, ]
  age_input <- function(table, type, measure, basis, unit, reference, notes) {
    v <- as.vector(t(table$value)); yy <- rep(table$year, each = 9L)
    aa <- rep(1:9, times = length(table$year)); keep <- !is.na(v)
    input(id, type, measure, basis, yy[keep], aa[keep], v[keep], unit,
      reference, notes, fleet = if (type %in% c("catch", "catch_weight")) "Combined fishery" else "")
  }
  catch_input <- age_input(catch, "catch", "numbers_at_age", "numbers", "thousand fish",
    paste(report_url, "Table 5.2.1.1"),
    "Reported age-specific geographic catch, ancillary to the aggregate chr rule; source table labels age 9 while percentage table labels 9+. Commercial catch may include other herring populations.")
  cell <- catch_input$year == 1991 & catch_input$age == 5
  stopifnot(sum(cell) == 1L, catch_input$value[cell] == 100444)
  catch_input$source_type[cell] <- "reconstructed_source_input"
  catch_input$transformation[cell] <- "Joined the final digit wrapped within the 1991 age-5 printed cell."
  catch_input$notes[cell] <- paste(catch_input$notes[cell],
    "Rendered HAWG page shows 10044 and a final 4 within the same cell; older ICES report search index gives 100444. The old PDF could not be downloaded locally.")
  catch_weights <- age_input(cw, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg/fish",
    paste(report_url, "Table 5.4.1.1"), "Reported catch weights by age 1-9+, ancillary to the chr rule; blank cells are omitted.")
  stock_weights <- age_input(sw, "weight", "spawning_weight_at_age", "kg_per_fish", "kg/fish",
    paste(report_url, "Table 5.4.1.2"), "Reported stock weights at spawning, not survey weights or a fitted population state. Age 9 is 9+; blank cells are omitted.")
  obs <- input(id, "index", "total_biomass", "biomass", idx$year, "", idx$index, "tonnes", sag_url,
    "Published genetically split MSHAS spawning-biomass indicator, not an independently estimated population SSB state. June-July survey; no exact within-year sampling fraction assigned.", survey = "MSHAS 6.aS 7.b-c", season = "summer")
  obs$source_type <- "official_machine_readable"
  catch_total <- input(id, "catch", "total_biomass", "biomass", ca$year, "", ca$catch, "tonnes", sag_url,
    "ICES estimated catch geographically allocated to 6.aS and 7.b-c, not catch-at-age or genetically split catch.", fleet = "Combined fishery")
  catch_total$source_type <- "official_machine_readable"
  inputs <- rbind(catch_input, catch_weights, stock_weights, obs, catch_total,
    input(id, "index", "numbers_at_age", "numbers", survey_age$year, survey_age$age, survey_age$value,
      "million fish", paste(report_url, "Table 5.3.1.1"),
      "Reported genetically split survey numbers by age 1-9+. Missing source ages omitted. This is not an independent age-specific likelihood in the chr rule.", survey = "MSHAS 6.aS 7.b-c", season = "summer"),
    input(id, "index", "relative_standard_error", "relative_scale", sy, "", cv, "CV",
      paste(report_url, "Table 5.3.1.1"), "Reported CV alongside the survey biomass; the source does not explicitly identify the precise target of this CV. Retain as survey context, not an assumed biomass likelihood weight.", survey = "MSHAS 6.aS 7.b-c", season = "summer"),
    input(id, "weight", "weight_at_age", "g_per_fish", survey_weight$year, survey_weight$age, survey_weight$value,
      "g/fish", paste(report_url, "Table 5.3.1.2"), "Survey mean weights, not the stock spawning-weight surface. Source blanks omitted; age 9 is 9+.", survey = "MSHAS 6.aS 7.b-c", season = "summer"),
    input(id, "maturity", "maturity_at_age", "proportion", maturity$year, maturity$age, maturity$value,
      "proportion", paste(report_url, "Table 5.3.1.3"), "Survey maturity proportions; source blanks omitted. This is not an age-structured fitted-population maturity surface.", survey = "MSHAS 6.aS 7.b-c", season = "summer"),
    input(id, "M", "natural_mortality_at_age", "per_year", "", 1:9,
      c(.528,.303,.255,.225,.207,.193,.186,.180,.180), "per year",
      paste(report_url, "section 5.4.3 and Table 5.6.2.5b"),
      "External SMS-derived mortality estimates used as life-history context and in length-proxy calculations; not fitted M states from the chr assessment."),
    input(id, "biology", "length_at_first_capture", "native_covariate", sy, "", lengths_table[, 5],
      "cm", paste(report_url, "Table 5.6.2.5a"), "Length of first capture used in the historical length indicator; the current harvest-rate proxy is simulation-based."),
    input(id, "biology", "mean_catch_length", "native_covariate", sy, "", lengths_table[, 6],
      "cm", paste(report_url, "Table 5.6.2.5a"), "Mean length of catch above length at first capture; not the unconditional mean length. The historical length indicator is not the current harvest-rate proxy."),
    input(id, "biology", "MSY_proxy_length", "native_covariate", sy, "", lengths_table[, 7],
      "cm", paste(report_url, "Table 5.6.2.5a"), "Target reference length used for the historical length indicator, reported fixed from the benchmark; not a fitted length-at-age surface."))
  outputs <- rbind(
    output(id, "survey_biomass_index", idx$year, idx$index, "tonnes", sag_url,
      "Source acoustic biomass indicator, not a separately estimated population SSB. Same series is retained among inputs; do not count twice."),
    output(id, "relative_harvest_rate", pressure$year, pressure$harvest, "catch tonnes per index tonne", sag_url,
      "Source catch/index indicator; not instantaneous F or F-at-age.", type = "mortality"))
  assumptions <- rbind(
    assumption(id, "assessment", "official_method", "ICES category 3 constant harvest-rate rule", advice_url,
      "Survey-biomass trend. The reported age tables are ancillary; no age-specific N/F/M population model or recruitment output is fitted by this rule."),
    assumption(id, "assessment", "advice_status", if (year == 2025L) "2025 ACOM advice published for 2026" else "2026 ACOM advice published; ASD advice record 4061 marked Invalid", advice_url,
      if (year == 2025L) "The 2025 advice record 3843 is Active." else "The reason for invalidity and any management application are unresolved. is_applied records use as the basis for published ACOM advice, not current advice validity."),
    assumption(id, "assessment", "chr_rule", if (year == 2025L) "Harvest-rate proxy 0.26, Itrigger 51390 t, precautionary multiplier 0.5, stability clause applied" else "Harvest-rate proxy 0.13, Itrigger 51390 t, precautionary multiplier 1, stability clause not applied", advice_url,
      if (year == 2025L) "The assessment uses genetically split biomass, a biomass safeguard and the version-specific source rule; reported components are rounded." else "The assessment uses genetically split biomass, a biomass safeguard and the version-specific source rule; reported components are rounded. Published advice has b=0.151 and Itrigger=51390 t; HAWG summary prints b=1 and a narrative prints Itrigger=51340 t, both inconsistent with the published rule."),
    assumption(id, "index", "survey_definition", "Genetically split Malin Shelf Herring Acoustic Survey, June-July", paste(report_url, "section 5.3"),
      "The aggregate survey index, not a separate age-specific likelihood, is used in the chr rule. Exact within-year sampling fraction is not supplied."),
    assumption(id, "catch", "stock_allocation", "Catches apportioned geographically", advice_url,
      "Genetic mixing can occur between northern and southern stocks; catch and the genetically split survey index need not have identical stock composition."),
    assumption(id, "assessment", "1991_catch_cell", "Age-5 catch cell prints 10044 and a wrapped 4 below", paste(report_url, "Table 5.2.1.1"),
      "Joined as 100444 after visual inspection of the original cell; historical ICES 1994 report search-index text independently gives 100444. The historical PDF download failed."))
  assessment <- blank("assessments.csv", id); assessment$stock_id <- stock_id
  assessment$assessment_year <- year; assessment$terminal_year <- year - 1L
  assessment$estimate_terminal_year <- year - 1L; assessment$assessment_type <- "annual"
  assessment$model_family <- "ICES category 3 constant harvest-rate rule"; assessment$model_version <- "chr; source package version unverified"
  assessment$is_current <- if (year == 2026L) "TRUE" else "FALSE"; assessment$is_applied <- "TRUE"
  assessment$framework_year <- 2022; assessment$assessment_url <- advice_url
  assessment$framework_url <- "https://doi.org/10.17895/ices.pub.21558681"; assessment$data_url <- sag_url
  assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
  assessment$notes <- if (year == 2025L) "2025 ACOM advice uses the genetically split southern stock. The 2015-2021 combined stock is distinct. Native rule inputs and complete length data remain unrecovered." else "HAWG 2026 assessment is the basis of published ACOM advice; ASD advice record 4061 is marked Invalid. is_applied records use in published advice, not current validity or management application. Native rule inputs and complete length data remain unrecovered."
  list(assessment = assessment, assumptions = assumptions, inputs = inputs, outputs = outputs)
}
results <- lapply(c(2025L, 2026L), extract)
if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) {
  cat("Source checks passed:", paste(vapply(results, function(x) paste(x$assessment$assessment_id, nrow(x$inputs), "inputs,", nrow(x$outputs), "outputs"), ""), collapse = "; "), "\n")
} else {
  stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
  stock <- stocks[stocks$stock_id == stock_id, ]
  stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-HAWG_harengus_CS6.a (S), 7b-c")
  stock$authority_stock_id <- "her.27.6aS7bc"; stock$common_name <- "West of Ireland and southern 6.a herring"
  stock$area <- "ICES divisions 6.a South and 7.b-c"; stock$region <- "Celtic Seas"; stock$ocean <- "Northeast Atlantic"
  stock$notes <- "Verified Charbonneau-Keith identity. The current genetically split southern stock is distinct from the combined 6.a/7.b-c assessment used in 2015-2021. See source_reviews/ck_ices_hawg_harengus_cs6_a_s_7b_c.md."
  write_rows <- function(file, x, id) {
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
    if (!identical(bytes, charToRaw(contents))) {
      writeBin(bytes, tmp)
      if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
    }
  }
  write_rows("stocks.csv", stock, stock_id)
  for (x in results) for (name in c("assessment", "assumptions", "inputs", "outputs")) {
    file <- if (name == "assessment") "assessments" else name
    write_rows(paste0(file, ".csv"), x[[name]], x$assessment$assessment_id)
  }
  cat("Imported 2025 and 2026 southern 6.a/7.b-c herring source records.\n")
}
