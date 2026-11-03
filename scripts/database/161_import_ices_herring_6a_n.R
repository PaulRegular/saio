base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_hawg_harengus_cs_6a_n")
stock_id <- "ck_ices_hawg_harengus_cs_6a_n"
report_2025 <- "https://doi.org/10.17895/ices.pub.28389008.v5"
report_2026 <- "https://doi.org/10.17895/ices.pub.31424315"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size), serialize = FALSE, algo = "sha256") != sha)
    cli::cli_abort("Cached source {file} is missing or differs from its pinned checksum.")
  path
}
verify("../ck_ices_hawg_dubius_ns/2025_san.sa.4/HAWG_2025.pdf", "06967082a29ef54ffb33ce7d2e8f89a4695dd6d1ca70f3e78510c03c6c813097")
verify("../ck_ices_hawg_harengus_cs6_a_s_7b_c/HAWG_2026_full_report.pdf", "0af113dedfea05c1dabc75402ebd5846d4a6ea931e121ca9e9702b0811c9832e")
paths <- list(
  `2025` = list(
    report = verify("HAWG_2025_pages_347_370.txt", "2de6bd9016778d1fee45081af6de45564aaa31926fdfe372d913bec5a4df1c81"),
    xml = verify("SAG_19370_2025.xml", "2b436a5aa506132d14af71fa03cc002b92d4072e890b671a837ab3ff69c0c8f7"),
    advice = verify("ICES_advice_6aN_2025.pdf", "db7cc2c149f9d40e6239dbb7d070f90869ee3ce44f6a5ef6906d1dff28c904ef")
  ),
  `2026` = list(
    report = verify("../ck_ices_hawg_harengus_cs6_a_s_7b_c/HAWG_2026_full_report.txt", "7b2b8995006e738e6868b25c086e255f387bdf060189543ee6a05593cac3c9a3"),
    xml = verify("SAG_21308_2026.xml", "c7f395bd956061adaf54d8aa9fe2b0a64751b4adfcc559ad2e03597e6adc2b59"),
    advice = verify("ICES_advice_6aN_2026.pdf", "4018d15d446a0d27aeb077594cc1f9b4a9b615c388e8073cb2339625351db7d8")
  )
)

# Read the reported age tables without replacing missing cells or source zeros.
table_rows <- function(lines, first, last, ncolumns) {
  from <- grep(paste0("^Table ", first, "\\."), lines)
  to <- grep(paste0("^Table ", last, "\\."), lines)
  if (length(from) != 1L || length(to) != 1L || from >= to) stop("Source table boundaries are ambiguous.")
  lines <- lines[seq.int(from + 1L, to - 1L)]
  lines <- trimws(lines[grepl("^[[:space:]]*(19|20)[0-9]{2}\\**[[:space:]]+[-0-9]", lines)])
  cells <- strsplit(lines, "[[:space:]]+")
  if (!all(lengths(cells) == ncolumns + 1L)) stop("Unexpected source-table columns: ", paste(lines[lengths(cells) != ncolumns + 1L], collapse = " | "))
  year <- as.integer(sub("\\*+$", "", vapply(cells, `[[`, "", 1L)))
  values <- do.call(rbind, lapply(cells, function(z) {
    z <- z[-1L]; z[z == "-"] <- NA_character_
    suppressWarnings(as.numeric(z))
  }))
  if (anyDuplicated(year)) stop("Repeated source-table year.")
  list(year = year, values = values)
}
# The printed survey-biology tables have blank cells. Column masks were
# checked against the rendered PDF; no values are shifted into missing ages.
partial_table <- function(lines, first, last, age_map) {
  from <- grep(paste0("^Table ", first, "\\."), lines)
  to <- grep(paste0("^Table ", last, "\\."), lines)
  if (length(from) != 1L || length(to) != 1L || from >= to) stop("Ambiguous biology table.")
  lines <- lines[seq.int(from + 1L, to - 1L)]
  lines <- trimws(lines[grepl("^[[:space:]]*20[0-9]{2}[[:space:]]+[-0-9]", lines)])
  rows <- lapply(strsplit(lines, "[[:space:]]+"), function(z) {
    age <- age_map[[z[1L]]]
    if (is.null(age) || length(z) - 1L != length(age)) stop("Unexpected survey biology row: ", paste(z, collapse = " "))
    data.frame(year = as.integer(z[1L]), age = age, value = as.numeric(z[-1L]))
  })
  do.call(rbind, rows)
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
  x$survey <- survey; x$sex <- "combined"; x$region <- "ICES Division 6.a North"
  x$season <- season; x$source_type <- "official_table"; x$source_reference <- ref
  x$notes <- notes; x
}
output <- function(id, measure, years, values, unit, ref, notes, type = "index") {
  x <- blank("outputs.csv", id, length(values))
  x$type <- type; x$measure <- measure; x$year <- years; x$value <- values
  x$unit <- unit; x$survey <- "MSHAS 6.aN"; x$sex <- "combined"
  x$region <- "ICES Division 6.a North"; x$season <- "summer"
  x$source_type <- "official_machine_readable"; x$source_reference <- ref
  x$notes <- notes; x
}
assumption <- function(id, component, setting, value, reference, notes = "") {
  x <- blank("assumptions.csv", id); x$component <- component; x$setting <- setting
  x$value <- value; x$source_reference <- reference; x$notes <- notes; x
}
extract <- function(year) {
  id <- paste0("ices_herring_6a_n_", year)
  source <- paths[[as.character(year)]]
  report_url <- if (year == 2025L) report_2025 else report_2026
  advice_url <- if (year == 2025L) "https://doi.org/10.17895/ices.advice.27202632" else "https://doi.org/10.17895/ices.advice.32133586"
  sag_key <- if (year == 2025L) 19370 else 21308
  sag_url <- paste0("https://sag.ices.dk/SAG_API/StockXmlDownload/", sag_key)
  text <- readLines(source$report, encoding = "UTF-8", warn = FALSE)
  catch <- table_rows(text, "4\\.2\\.2", "4\\.2\\.3", 9L)
  weights <- table_rows(text, "4\\.2\\.3", "4\\.3\\.1", 9L)
  survey <- table_rows(text, "4\\.3\\.2", "4\\.4\\.1\\.1", 10L)
  stopifnot(identical(catch$year, 1957:(year - 1L)),
    identical(weights$year, 1957:(year - 1L)),
    identical(survey$year, 2014:(year - 1L)),
    catch$values[catch$year == 2021, 2] == 3188,
    survey$values[survey$year == 2023, 10] == 22.463)
  if (year == 2026L) stopifnot(all(catch$values[catch$year == 2022, ] == 0),
    all(weights$values[weights$year == 2024, ] == 0),
    survey$values[survey$year == 2025, 10] == 1.588)
  if (year == 2025L) stopifnot(all(is.na(catch$values[catch$year == 2022, ])))
  xml <- xml2::read_xml(source$xml)
  stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/StockCode")) == "her.27.6aN",
    as.integer(xml2::xml_text(xml2::xml_find_first(xml, "/Assessment/AssessmentYear"))) == year)
  fish <- xml2::xml_find_all(xml, "/Assessment/Fish_Data")
  readfield <- function(field) suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(fish, field))))
  sag <- data.frame(year = readfield("Year"), catch = readfield("Catches"),
    index = readfield("StockSize"), harvest = readfield("FishingPressure"))
  stopifnot(sag$index[sag$year == 2023] == 23117,
    sag$index[sag$year == 2024] == 12557,
    sag$catch[sag$year == year - 1L] > 0)
  catch_ages <- input(id, "catch", "numbers_at_age", "numbers",
    rep(catch$year, each = 9L), rep(1:9, times = length(catch$year)),
    as.vector(t(catch$values)), "thousand fish", paste(report_url, "Table 4.2.2"),
    "Published catch-at-age for the geographic fishery, ages 1-9+; ancillary to the aggregate chr rule. Catch includes other spawning populations. Missing cells remain missing. In the 2026 report 2022 zeros conflict with positive aggregate catch; retain as printed without inferring zero removal.",
    fleet = "Geographically allocated fishery")
  wvalues <- as.vector(t(weights$values)); ok <- !is.na(wvalues)
  catch_weights <- input(id, "catch_weight", "catch_weight_at_age", "kg_per_fish",
    rep(weights$year, each = 9L)[ok], rep(1:9, times = length(weights$year))[ok],
    wvalues[ok], "kg/fish", paste(report_url, "Table 4.2.3"),
    "Published catch weight for ages 1-9+; ancillary to the chr rule, not population weight. Missing cells are omitted. The 2026 report describes 2022 and 2024 zero-weight rows as no catches despite positive aggregate catch; retain zeros as printed and do not use as evidence of zero removals.",
    fleet = "Geographically allocated fishery")
  index_ages <- input(id, "index", "numbers_at_age", "numbers",
    rep(survey$year, each = 9L), rep(1:9, times = length(survey$year)),
    as.vector(t(survey$values[, 1:9, drop = FALSE])), "million fish",
    paste(report_url, "Table 4.3.2"),
    "Genetically split survey numbers at reported ages 1-9; the annual chr rule uses a biomass indicator, not an independent age-specific likelihood. The 2023 working-group biomass differs from published advice/SAG, so these ages are not asserted to decompose that published index. The terminal age is labelled 9 in this table; plus-group treatment over the full series remains unresolved.",
    survey = "MSHAS 6.aN", season = "summer")
  weight_ages <- list(`2014`=2:9, `2015`=2:9, `2016`=2:9, `2017`=2:9,
    `2018`=1:9, `2019`=c(2:7,9), `2020`=1:7, `2021`=1:9,
    `2022`=1:9, `2023`=1:9, `2024`=1:9, `2025`=c(1:7,9))
  mature_ages <- list(`2014`=2:9, `2015`=2:9, `2016`=2:9, `2017`=2:9,
    `2018`=1:9, `2019`=c(2:7,9), `2020`=1:7, `2021`=1:9,
    `2022`=1:9, `2023`=1:9, `2024`=1:9, `2025`=c(1:7,9))
  w <- partial_table(text, "4\\.4\\.1\\.1", "4\\.4\\.2\\.1", weight_ages)
  m <- partial_table(text, "4\\.4\\.2\\.1", "4\\.4\\.3\\.1", mature_ages)
  stopifnot(w$value[w$year == 2019 & w$age == 9] == .212,
    m$value[m$year == 2018 & m$age == 2] == .37,
    !any(w$year == 2019 & w$age == 8), !any(m$year == 2020 & m$age > 7))
  w_kg <- w[w$year < 2025, ]; w_g <- w[w$year == 2025, ]
  survey_weights <- input(id, "weight", "weight_at_age", "kg_per_fish", w_kg$year,
    w_kg$age, w_kg$value, "kg/fish", paste(report_url, "Table 4.4.1.1"),
    "Mean survey weights, not a complete population-weight surface. Missing source cells omitted; terminal age is printed as 9.", survey = "MSHAS 6.aN", season = "summer")
  if (nrow(w_g)) {
    stopifnot(w_g$value[w_g$age == 1] == 63.66)
    survey_weights <- rbind(survey_weights, input(id, "weight", "weight_at_age", "g_per_fish", w_g$year,
      w_g$age, w_g$value, "g/fish", paste(report_url, "Tables 4.4.1.1 and 4.3.1"),
      "Table 4.4.1.1 is labelled kg, but its 2025 row matches the independently labelled gram values in Table 4.3.1. Preserve printed values in grams; missing age 8 omitted.", survey = "MSHAS 6.aN", season = "summer"))
  }
  survey_maturity <- input(id, "maturity", "maturity_at_age", "proportion", m$year,
    m$age, m$value, "proportion", paste(report_url, "Table 4.4.2.1"),
    "Survey maturity proportions, with missing source cells omitted. In 2025 the age-3 value 0.99 differs from the rounded 1.00 in Table 4.3.1; retain this table's value.", survey = "MSHAS 6.aN", season = "summer")
  idx <- sag[is.finite(sag$index) & sag$year %in% 2014:(year - 1L), ]
  ca <- sag[is.finite(sag$catch) & sag$year <= year - 1L, ]
  pressure <- sag[is.finite(sag$harvest) & sag$year %in% idx$year, ]
  agg <- input(id, "index", "total_biomass", "biomass", idx$year, "", idx$index,
    "tonnes", sag_url,
    "Published genetically split MSHAS spawning-biomass indicator, not an independent population-state estimate. 2023 advice/SAG value 23117 tonnes conflicts with HAWG Table 4.3.2 (22463); cause unresolved. Summer survey, exact date varies and is not assigned a model sampling fraction.", survey = "MSHAS 6.aN", season = "summer")
  ca_obs <- input(id, "catch", "total_biomass", "biomass", ca$year, "", ca$catch,
    "tonnes", sag_url, "ICES estimated total catch geographically allocated to 6.aN; includes other herring populations. Not catch-at-age.",
    fleet = "Geographically allocated fishery")
  inputs <- rbind(catch_ages, catch_weights, index_ages, survey_weights, survey_maturity, agg, ca_obs,
    input(id, "M", "natural_mortality_at_age", "per_year", "", 1:9,
      c(.528,.303,.255,.225,.207,.193,.186,.180,.180), "per year",
      paste(report_url, "Table 4.4.3.1"),
      "External SMS-derived natural-mortality estimates used as life-history context in the chr method, not fitted mortality states from this assessment."))
  working_index <- output(id, "survey_biomass_index_working_group", survey$year,
    survey$values[, 10], "thousand tonnes", paste(report_url, "Table 4.3.2"),
    "Working-group reported survey indicator in original units. This is an alternative source series for the same survey, not an additional independent observation. The 2023 value differs materially from published advice and SAG; source discrepancy unresolved.")
  working_index$source_type <- "official_table"
  outputs <- rbind(
    working_index,
    output(id, "survey_biomass_index", idx$year, idx$index, "tonnes", sag_url,
      "Published acoustic index used as the stock indicator, not a separately estimated population SSB. Same observations also appear in inputs; do not count twice."),
    output(id, "relative_harvest_rate", pressure$year, pressure$harvest, "catch tonnes per index tonne", sag_url,
      "Source catch/index indicator, not instantaneous F. In 2023 this rate matches the 22463-tonne working-group index while the published SAG biomass field is 23117 tonnes; discrepancy unresolved.", type = "mortality"))
  assumptions <- rbind(
    assumption(id, "assessment", "official_method", "ICES category 3 constant harvest-rate rule", advice_url,
      "Survey-biomass trend; no fitted age-structured N, F, M, recruitment or absolute SSB. The source age tables are ancillary, not a fitted age-specific likelihood."),
    assumption(id, "assessment", "advice_status", if (year == 2025L) "2025 ACOM advice published for 2026" else "2026 ACOM advice published; ASD advice record 4063 marked Invalid", advice_url,
      if (year == 2025L) "Adopted published ICES advice, 1501 tonnes for 2026." else "The 2026 ACOM advice identifies this assessment as its basis, but its ASD record is currently marked Invalid. The reason and any management application are unresolved."),
    assumption(id, "assessment", "chr_rule", if (year == 2025L) "0.28 harvest-rate proxy, Itrigger 14711 t, precautionary multiplier 0.5" else "0.14 harvest-rate proxy, Itrigger 14711 t, precautionary multiplier 1", advice_url,
      "Advice uses the genetically split biomass indicator, a biomass safeguard and source-specific multiplier; rounded published components may not reproduce unrounded advice exactly."),
    assumption(id, "index", "survey_definition", "Genetically split Malin Shelf Herring Acoustic Survey, June-July", paste(report_url, "sections 4.3 and 4.6"),
      "Only one aggregate survey index is used by the chr rule. Exact observation time is not supplied as a proportion of year."),
    assumption(id, "catch", "stock_allocation", "Catches apportioned geographically, not genetically", advice_url,
      "Commercial catch includes an unquantified proportion of other spawning populations while the acoustic index is genetically split."),
    assumption(id, "assessment", "source_conflicts", "2023 HAWG index 22463 t; published advice/SAG 23117 t", paste(report_url, "Table 4.3.2;", advice_url),
      "The catch/index series agrees with the 22463 denominator. Cause of discrepancy remains unresolved; retain published series and identify the different working-group value."))
  assessment <- blank("assessments.csv", id); assessment$stock_id <- stock_id
  assessment$assessment_year <- year; assessment$terminal_year <- year - 1L
  assessment$estimate_terminal_year <- year - 1L; assessment$assessment_type <- "annual"
  assessment$model_family <- "ICES category 3 constant harvest-rate rule"
  assessment$model_version <- "chr; source package version unverified"
  assessment$is_current <- if (year == 2026L) "TRUE" else "FALSE"
  assessment$is_applied <- "TRUE"
  assessment$framework_year <- 2022; assessment$assessment_url <- advice_url
  assessment$framework_url <- "https://doi.org/10.17895/ices.pub.21558681"
  assessment$data_url <- sag_url; assessment$assumptions_status <- "partial"
  assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
  assessment$notes <- if (year == 2025L) "Applied 2025 ACOM advice, published in 2025. Previous combined 6.a/7.b-c stock is distinct; this assessment uses the post-benchmark 6.aN autumn-spawner unit. See source review for source disagreements and age-table limitations." else "HAWG 2026 presents a final detailed assessment used as the basis of published 2026 ACOM advice. The associated ASD advice record 4063 is marked Invalid; its reason and any management application are unresolved. is_applied records use for published advice, not its current validity. Source tables conflict; see source review."
  list(assessment = assessment, assumptions = assumptions, inputs = inputs, outputs = outputs)
}
results <- lapply(c(2025L, 2026L), extract)
if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) {
  cat("Source checks passed:", paste(vapply(results, function(x) paste(x$assessment$assessment_id, nrow(x$inputs), "inputs,", nrow(x$outputs), "outputs"), ""), collapse = "; "), "\n")
} else {
  stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
  stock <- stocks[stocks$stock_id == stock_id, ]
  stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-HAWG_harengus_CS 6a (N)")
  stock$authority_stock_id <- "her.27.6aN"; stock$common_name <- "West of Scotland autumn-spawning herring"
  stock$area <- "ICES Division 6.a North"; stock$region <- "Celtic Seas"; stock$ocean <- "Northeast Atlantic"
  stock$notes <- "Charbonneau-Keith catalogue identity verified. The current 6.aN autumn-spawning unit is distinct from the combined 6.a/7.b-c assessment used in 2015-2021. See source_reviews/ck_ices_hawg_harengus_cs_6a_n.md."
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
  cat("Imported 2025 and 2026 6.aN herring source records.\n")
}
