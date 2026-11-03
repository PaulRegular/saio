base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_wghansa_mordax_sp9a")
assessment_id <- "ices_anchovy_gulf_cadiz_2025"
stock_id <- "ices_anchovy_gulf_cadiz"
legacy_id <- "ck_ices_wghansa_mordax_sp9a"
report_url <- "https://doi.org/10.17895/ices.pub.29335520.v3"
annex_url <- "https://doi.org/10.17895/ices.pub.28053362"
advice_url <- "https://doi.org/10.17895/ices.advice.27202494"
sag_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/21266"
repo_url <- "https://github.com/ices-advice/2025_ane.27.9aS"
revision <- "075ed16570d08be9378848ddabe15c3b64feb07b"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(file = path, algo = "sha256") != sha) {
    cli::cli_abort("Cache and verify {file} before importing.")
  }
  path
}
report <- pdftools::pdf_text(verify("WGHANSA - 2025 Report.pdf",
  "91a780f00878529c9cee208137a9f9ede22f49ad1a83c5840d1d72395103c6d9"))
verify("ane.27.9aS_SA.pdf", "3a93ae77352d4d710f4f518d09c7b6969388e2a711ff0efb0ea15923d69d115a")
verify("ICES_advice_2025_ane_9aS.pdf", "b43ab317812e18232170224fb4afac6b666d4bbe861a1ed0e65491b50e5491e5")
xml <- xml2::read_xml(verify("ICES_SAG_2025_key_21266.xml",
  "4bf8c6eba95f7e3acca98a1958a317ea73cb6dbc334c5cc961b560e86c63a808"))
stopifnot(xml2::xml_text(xml2::xml_find_first(xml, "./StockCode")) == "ane.27.9aS",
  xml2::xml_text(xml2::xml_find_first(xml, "./AssessmentYear")) == "2025",
  xml2::xml_text(xml2::xml_find_first(xml, "./ConfidenceIntervalDefinition")) == "95%")
numeric_cell <- function(x) suppressWarnings(as.numeric(gsub("[[:space:]]", "", chartr(",", ".", x))))
year_rows <- function(pages, width, split = "[[:space:]]+") {
  lines <- unlist(strsplit(paste(pages, collapse = "\n"), "\n"))
  cells <- strsplit(trimws(lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines)]), split)
  stopifnot(all(lengths(cells) == width))
  do.call(rbind, lapply(cells, numeric_cell))
}
summary <- year_rows(report[184:185], 8L, "\\s{2,}")
spanish <- year_rows(c(sub(".*Table 4.3.5.2.2\\.", "Table 4.3.5.2.2.", report[167]),
  sub("Table 4.3.6.1\\..*", "", report[168])), 5L)
stopifnot(identical(as.integer(summary[, 1]), 1989:2025),
  identical(as.integer(spanish[, 1]), 1995:2024))
records <- xml2::xml_find_all(xml, ".//Fish_Data")
field <- function(name) numeric_cell(xml2::xml_text(xml2::xml_find_first(records, name)))
stopifnot(identical(as.integer(field("Year")), 1989:2025),
  identical(field("StockSize")[field("Year") != 2012], summary[summary[, 1] != 2012, 2]),
  field("StockSize")[field("Year") == 2012] == 10584, summary[summary[, 1] == 2012, 2] == 10585,
  identical(field("Recruitment"), summary[, 4]),
  max(abs(field("FishingPressure") - summary[, 6])) <= 0.005 + 1e-12)

blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
input <- function(type, measure, values, years, ages = NA_integer_, unit, table,
                  notes, season = "annual", fleet = "", survey = "", basis = "numbers") {
  x <- blank("inputs.csv", length(values))
  x$type <- type; x$measure <- measure; x$basis <- basis; x$value <- values
  x$year <- years; x$age <- ages; x$unit <- unit; x$season <- season
  x$year_basis <- ifelse(is.na(x$year), "", "calendar_year")
  x$fleet <- fleet; x$survey <- survey; x$sex <- "combined"
  x$region <- "Southern Division 9.a (Gulf of Cadiz and southern Portugal)"
  x$source_type <- "official_table"; x$source_reference <- paste(report_url, table)
  x$notes <- notes; x
}
inputs <- rbind(
  input("catch", "total_biomass", summary[, 8], 1989:2025, unit = "tonnes",
    table = "Table 4.6.1.2", basis = "biomass", fleet = "Whole fishery",
    notes = "Annual sums of the quarterly SS3 input catches, not an additional fleet or annual catch likelihood. 2025 includes assumed interim catch; no 2025 catch ages or catch weights were used. Earlier rounded table totals may not exactly equal rounded quarterly sums."),
  input("catch", "numbers_at_age", as.vector(t(spanish[, -1])), rep(1995:2024, each = 4),
    rep(0:3, 30), "thousand fish", "Table 4.3.5.2.2",
    "Spanish annual fishery age counts only. Not the whole-stock quarterly composition likelihood; Portuguese catches must not be assigned these counts silently. Ages for 2025 are unavailable, not zero.", fleet = "Spanish fishery"),
  input("M", "natural_mortality_at_age", c(2.97, 1.6, 2.48, 2.48), NA_integer_, 0:3,
    "year^-1", "section 4.5.3 and Table 4.6.1.1",
    "Fixed benchmark M adopted in the current run, not estimated M outputs.", basis = "per_year"),
  input("maturity", "maturity_at_age", c(0, 1, 1, 1), NA_integer_, 0:3,
    "proportion", "section 4.5.2 and Table 4.6.1.1",
    "All age-1 and older fish mature; spawning on 1 April. Time-invariant supplied assumption.", basis = "proportion")
)

# Preserve the single available whole-fishery quarterly catch table.
quarter_catch <- rbind(c(0, 0, 81845, 12646), c(134474, 302545, 143018, 9815),
  c(8055, 10258, 10565, 627), c(0, 0, 0, 0))
catch_weight <- rbind(c(0, 0, 7.8, 9.4), c(9.1, 12.1, 15, 15),
  c(14.6, 20.6, 16.1, 18.2), c(0, 0, 0, 0))
stopifnot(identical(as.numeric(rowSums(quarter_catch)), c(94491, 589852, 29505, 0)),
  max(abs(colSums(quarter_catch) - c(142529, 312802, 235429, 23088))) <= 1)
for (q in 1:4) {
  inputs <- rbind(inputs,
    input("catch", "numbers_at_age", quarter_catch[, q], 2024, 0:3, "thousand fish",
      "Table 4.3.5.2.1", "Whole-fishery quarterly reported counts. Rounded independently; not an additional annual observation. No age structure is inferred for 2025.",
      season = paste0("Q", q), fleet = "Whole fishery"),
    input("catch_weight", "weight_at_age", catch_weight[, q], 2024, 0:3, "g",
      "Table 4.3.6.2", "Reported raw catch weights, including source zeros for absent ages. These are not the mixed-model empirical stock/catch weights used in SS3, and cannot complete wtatage.ss.",
      season = paste0("Q", q), fleet = "Spanish fishery", basis = "g_per_fish"))
}

# The spring biomass table covers both stocks: select S (Total), not TOTAL.
survey_biomass <- function(text, from_right) {
  lines <- unlist(strsplit(paste(text, collapse = "\n"), "\n"))
  result <- list(); year <- NA_integer_
  for (line in lines) {
    if (grepl("^\\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\.\\s*[0-9]{2}", line)) {
      year <- 2000L + as.integer(sub("^\\s*[A-Za-z]+\\.\\s*([0-9]{2}).*", "\\1", line))
      if (year > 2025) year <- year - 100L
    }
    if (grepl("^\\s*B\\s+", line) && !is.na(year)) {
      cells <- strsplit(trimws(gsub("[+*]", "", line)), "[[:space:]]+")[[1L]]
      result[[length(result) + 1L]] <- c(year, numeric_cell(cells[length(cells) - from_right]))
    }
  }
  do.call(rbind, result)
}
pelago <- survey_biomass(c(report[172:173], sub("Table 4.4.2.2\\..*", "", report[174])), 1L)
eco <- survey_biomass(c(sub(".*Table 4.4.2.2\\.", "Table 4.4.2.2.", report[174]), report[175]), 0L)
stopifnot(identical(as.integer(pelago[, 1]), 1999:2025),
  identical(as.integer(eco[, 1]), 2004:2023), pelago[27, 2] == 60838, eco[20, 2] == 9714)
inputs <- rbind(inputs,
  input("index", "total_biomass", pelago[, 2], pelago[, 1], unit = "tonnes",
    table = "Table 4.4.2.1", basis = "biomass", survey = "PELAGO",
    season = "spring", notes = "Southern-stock S (Total) column only, not the total for both western and southern stocks. Exact current SS3 observation dates and log-SD inputs are unavailable. 2011 zero is retained as reported survey context but excluded from the model's input years in Table 4.6.1.1; 2000/2004/2012 are missing. March/April/May field dates vary."),
  input("index", "total_biomass", eco[, 2], eco[, 1], unit = "tonnes",
    table = "Table 4.4.2.2", basis = "biomass", survey = "ECOCADIZ", season = "summer",
    notes = "Whole southern survey total. 2010 is Spanish-only partial coverage; 2004 may omit shallow water. Missing years retained as NA. Series ends in 2023. Exact current model timing/weights are not inferred from the older MSE object."),
  input("index", "total_biomass", c(14673,31527,32757,31569,12392,81466,15138),
    c(2005,2008,2011,2014,2017,2020,2023), unit = "tonnes", basis = "biomass",
    table = "Table 4.4.1.1", survey = "BOCADEVA", season = "summer",
    notes = "DEPM mature-stock biomass, not an age-specific abundance index or fitted SSB. 2020/2023 estimates use average spawning fractions; 2023 remains provisional. Series ceased after 2023."),
  input("index", "total_biomass", c(5131,29219,15969,NA,3834,36405,21060,12063,10797,4723,15842,20758),
    2014:2025, ages = 0, unit = "tonnes", basis = "biomass", survey = "ECOCADIZ-RECLUTAS",
    table = "Table 4.4.3.2", season = "autumn",
    notes = "Recruitment index is age-0 BIOMASS in parentheses, not all-age biomass or fish numbers. 2017 incomplete coverage is excluded from the source likelihood; no whole-stock value invented. Rounded regional parts need not sum to the reported total.")
)

# Published design-based age abundances are distinct from composition sample sizes.
pelago_age <- year_rows(c(report[176], strsplit(report[177], "N (%)", fixed = TRUE)[[1L]][1]), 7L)
eco_text <- substring(report[178], regexpr("Table 4.4.2.3.", report[178], fixed = TRUE)[1])
eco_age <- year_rows(eco_text, 7L)
stopifnot(identical(as.integer(pelago_age[, 1]), 1999:2025),
  identical(as.integer(eco_age[, 1]), 2004:2023),
  identical(pelago_age[27, 2:6], c(0,5978,623,0,0)))
for (survey in c("PELAGO", "ECOCADIZ")) {
  z <- if (survey == "PELAGO") pelago_age else eco_age
  inputs <- rbind(inputs, input("index", "numbers_at_age", as.vector(t(z[, 2:6])),
    rep(z[, 1], each = 5), rep(0:4, nrow(z)), "million fish", "Table 4.4.2.3",
    "Reported design-based survey abundance, not biological sample counts. Underlying the same biomass/composition information, not an additional independent likelihood. Source age totals disagree with Table 4.4.2.1/2 in several years (e.g. PELAGO 2014); retained without rescaling. Raw ages 0-4 are retained; SS3 population bins end at age 3. These are not fitted N states or verified native composition arrays/sample sizes.",
    survey = survey, season = if (survey == "PELAGO") "spring" else "summer"))
}

output <- function(measure, value, lwr, upr, unit, cv, age = NA_integer_, season = "annual") {
  x <- blank("outputs.csv", 37L); x$measure <- measure; x$value <- value
  x$lwr <- lwr; x$upr <- upr; x$unit <- unit; x$year <- 1989:2025
  x$age <- age; x$sex <- "combined"; x$region <- "Southern Division 9.a"
  x$season <- season; x$type <- switch(measure, SSB = "biomass",
    recruitment = "recruitment", fishing_mortality_at_age = "mortality")
  x$source_type <- "official_machine_readable"; x$source_reference <- sag_url
  x$notes <- paste0("2025 assessment, SAG key 21266; source 95% limits retained without inventing SEs. Reported rounded CV in Table 4.6.1.2 = ", cv,
    ". 2025 includes assumed interim catch; it is part of this assessment, not the 2026 forecast. ",
    switch(measure, SSB = "Spawning biomass on 1 April (Q2).",
      recruitment = "Age-0 settlement on 1 July (Q3), not January recruitment.",
      fishing_mortality_at_age = "Annual F at age 3, also the reported apical F; not population-weighted Fbar. Other ages are unavailable."))
  x
}
outputs <- rbind(
  output("SSB", field("StockSize"), field("Low_StockSize"), field("High_StockSize"), "tonnes", summary[, 3], season = "Q2"),
  output("recruitment", field("Recruitment"), field("Low_Recruitment"), field("High_Recruitment"), "thousand fish", summary[, 5], age = 0, season = "Q3"),
  output("fishing_mortality_at_age", field("FishingPressure"), field("Low_FishingPressure"), field("High_FishingPressure"), "year^-1", summary[, 7], age = 3))
at <- outputs$measure == "SSB" & outputs$year == 2012
outputs$notes[at] <- paste(outputs$notes[at], "SAG reports 10584 t; the rounded report table prints 10585 t. SAG point and its own interval are retained together; this one-tonne difference remains explicit.")
assumption <- function(component, setting, value, notes = "", reference = paste(report_url, "section 4 and Table 4.6.1.1")) {
  x <- blank("assumptions.csv"); x$component <- component; x$setting <- setting
  x$value <- value; x$notes <- notes; x$source_reference <- reference; x
}
assumptions <- rbind(
  assumption("assessment", "official_run", "2025 SS3 assessment, 1989-2025; southern 9.a stock following 2024 split", "Published 2025 report version 3 includes November 2025 assessment. The 2026 May WGHANSA meeting did not update this stock; its next assessment is scheduled for November 2026."),
  assumption("population", "structure", "One area, one combined gender, ages 0-3, four three-month seasons", "Four quarterly fishing fleets; seasonal recruitment cannot silently be treated as January recruitment."),
  assumption("population", "spawning_time", "1 April, fraction 0.25 of the calendar year"),
  assumption("recruitment", "settlement_time", "1 July, fraction 0.5 of the calendar year, age 0"),
  assumption("recruitment", "process", "Beverton-Holt; R0 estimated; h fixed 0.8; sigmaR fixed 0.33; main deviations 1991-2025", "The report labels 1962.8 as the early-deviation start, but the public preparation script uses 1962.8 as a bias-adjustment ramp boundary. Exact early-deviation controls require the missing production control file; do not interpret a fractional ramp parameter as a calendar start year."),
  assumption("population", "initialization", "Equilibrium recruitment/selectivity and quarterly equilibrium catches 1208,2033,683,223 t, adjusted by early recruitment deviations"),
  assumption("F", "model", "Hybrid F with separate time-invariant logistic age selectivity for quarterly fleets", reference = paste(annex_url, "section 4.1;", report_url, "section 4.6")),
  assumption("M", "model", "Fixed annual M: age 0=2.97, age 1=1.6, ages 2/3=2.48", "Fixed values selected by benchmark methods/profiles, not free M in this assessment."),
  assumption("biology", "weight", "Empirical quarter/year/age mixed-model weight surface, 1989-2025", "Numerical production wtatage.ss remains missing. Raw 2024 catch weights are not this surface. The older MSE reference has different population estimates and is not substituted."),
  assumption("biology", "maturity", "Age 0=0; ages 1-3=1; SSB on 1 April"),
  assumption("index", "likelihood", "PELAGO/ECOCADIZ total biomass plus age proportions; BOCADEVA mature biomass; ECOCADIZ-RECLUTAS age-0 biomass", "PELAGO composition years 2014-2025; ECOCADIZ compositions 2004-2023 with missing years. Numerical native compositions and Francis sample sizes remain incomplete. Published design-based age totals disagree with other survey tables in several years; they are not rescaled into verified native likelihood inputs."),
  assumption("index", "catchability", "Linear q by survey; logistic PELAGO/ECOCADIZ selectivity; ECOCADIZ blocks 2004-2014 and 2015-2023", "BOCADEVA selects mature ages only; ECOCADIZ-RECLUTAS selects age 0 only. Exact current parameter phases/sharing are unavailable without native controls."),
  assumption("observation", "weights", "Reported catch CV 0.05 and survey CV 0.30; age sample sizes adjusted by five Francis iterations", "The report says CV, whereas SS3 consumes log-SD inputs. No exact current per-observation SD or sample size is inferred without the native files."),
  assumption("catch", "2025_missing_ages", "2025 total catch includes assumed interim values; no 2025 age compositions or catch weights used", "Current script uses NewYear_v3 and agecomp_fleet_v2/watage_2025_v2. Do not fill 2025 ages from previous years.", paste(repo_url, "/tree/", revision)),
  assumption("assessment", "advice_method", "Category-3 1-over-2 rule applied to SS3 SSB, because Fcap has not been defined", "An age-based assessment exists even though the advice category is 3.3. Current MSE trial outputs are not the production assessment."),
  assumption("assessment", "remaining_inputs", "Current TAF source tree contains processing scripts but omits LastYear and update2025 input folders", "No release assets recover those folders. The public MSE reference spans 1989-2024 and differs from the 2025 official summaries. No states/biology are spliced across those runs."))
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- assessment$terminal_year <- assessment$estimate_terminal_year <- 2025
assessment$assessment_type <- "annual_update"; assessment$model_family <- "Stock Synthesis"
assessment$model_version <- "SS3; exact 2025 production executable version unresolved"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2024
assessment$assessment_url <- advice_url; assessment$framework_url <- annex_url
assessment$data_url <- sag_url; assessment$repository_url <- repo_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Current southern stock following 2024 split of former Division 9.a unit. Verified 2025 report/SAG values only; 2025 includes assumed interim catch and omits fishery age compositions/weights. Missing native seasonal compositions/weights prevent a defensible tinyAM fit. Older MSE object kept separately, not imported. See source_reviews/ices_anchovy_gulf_cadiz.md."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$charbonneau_id <- NA_character_
stock$authority <- "ICES"; stock$authority_stock_id <- "ane.27.9aS"
stock$scientific_name <- "Engraulis encrasicolus"; stock$common_name <- "Gulf of Cadiz anchovy"
stock$area <- "Southern Division 9.a (Gulf of Cadiz and southern coast of Portugal)"
stock$region <- "Southern Iberian Atlantic"; stock$ocean <- "Northeast Atlantic"
stock$notes <- paste("Southern successor to the historical combined Division 9.a catalogue entry", legacy_id,
  "(ICES-WGHANSA_mordax_SP9a). The Master species mordax is erroneous for this European stock. The original Master ID is retained on the historical row; neither successor inherits it as a one-to-one identity.")
legacy <- stocks[stocks$stock_id == legacy_id, ]
stopifnot(nrow(legacy) == 1L, legacy$charbonneau_id == "ICES-WGHANSA_mordax_SP9a", legacy$area == "SP9a")
legacy$scientific_name <- "Engraulis encrasicolus"
legacy$common_name <- "Iberian anchovy (historical combined unit)"
legacy$notes <- paste("Historical combined Division 9.a catalogue entry ICES-WGHANSA_mordax_SP9a; stable ID/area retained.",
  "Master.csv names Engraulis mordax, but the cited Iberian assessment concerns Engraulis encrasicolus (official stock annex and WGHANSA 2025 section 4.2).",
  "The stock was split into western ane.27.9aW and southern ane.27.9aS in 2024. Related current southern stock_id=ices_anchovy_gulf_cadiz; no southern data are copied to this historical combined row.",
  "Source: https://doi.org/10.17895/ices.pub.29335520.v3; section 4.2. Master revision 7e4daca3cbfc14ce7fa0b28ed824eebe7113249b.")
legacy$notes <- paste(
  "Metadata-only entry from Charbonneau-Keith Master.csv, revision 7e4daca3cbfc14ce7fa0b28ed824eebe7113249b; not a verified current official assessment.",
  "Assessor_ID=ICES-WGHANSA; Master PDF.file label=WGHANSAreport 2017.pft; area retained from unique_ID; regional basin assigned from assessor family.",
  "Reviewed identity (2026-10-26):", legacy$notes)

write_rows <- function(file, x, id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  at <- which(startsWith(lines, paste0('"', id, '",')))
  tmp <- tempfile(tmpdir = database); on.exit(unlink(tmp), add = TRUE)
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(at)) {
    stopifnot(identical(at, seq.int(min(at), max(at))))
    replacement <- paste0(replacement, if (endsWith(lines[at[1]], "\r")) "\r" else "")
    lines <- c(head(lines, min(at)-1L), replacement, tail(lines, length(lines)-max(at)))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", legacy, legacy_id)
write_rows("stocks.csv", stock, stock_id)
for (table in c("assessments", "assumptions", "inputs", "outputs")) {
  write_rows(paste0(table, ".csv"), if (table == "assessments") assessment else get(table), assessment_id)
}
cat("Imported Gulf of Cadiz anchovy 2025:", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions and", nrow(outputs), "outputs; native input gaps remain.\n")
