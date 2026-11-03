base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_ices_afwg_mentella_deep_1_2_2026")
assessment_id <- "jrn_redfish_beaked_2026"
stock_id <- "ck_ices_afwg_mentella_deep_1_2"
report_url <- "https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5"
framework_url <- "https://doi.org/10.17895/ices.pub.19291142.v1"
html <- file.path(cache, "JRN-AFWG_2026.html")
if (!file.exists(html) || digest::digest(readBin(html, "raw", n = file.info(html)$size),
  algo = "sha256", serialize = FALSE) != "f5f2370d948e04b77fed8e572c7d555c3fce1a7ff3c085af6b1ac43607af730e") {
  cli::cli_abort("Cache and verify the reviewed JRN-AFWG 2026 report before importing.")
}
doc <- rvest::read_html(html)
tables <- rvest::html_elements(doc, "table")
captions <- vapply(tables, function(x) rvest::html_text2(rvest::html_element(x, "caption")), character(1))
table <- function(number) {
  at <- which(startsWith(captions, paste0("Table ", number, ".")))
  if (length(at) != 1L) cli::cli_abort("Expected one source Table {number}.")
  as.data.frame(rvest::html_table(tables[[at]], header = FALSE, convert = FALSE), stringsAsFactors = FALSE)
}
numeric_cell <- function(x, unavailable = character()) {
  clean <- gsub("[[:space:]\u00a0\u202f]", "", as.character(x), perl = TRUE)
  missing <- is.na(clean) | clean %in% c("", "-", "\u2013", "\u2014", "NA", unavailable)
  value <- suppressWarnings(as.numeric(clean))
  if (any(!missing & !is.finite(value))) cli::cli_abort("Unexpected non-numerical source cell: {x[!missing & !is.finite(value)]}.")
  value[missing] <- NA_real_
  value
}
annual <- function(x, column = 1L) {
  x <- x[grepl("^(19|20)[0-9]{2}[0-9]?$", x[[column]]), , drop = FALSE]
  year <- as.integer(substr(x[[column]], 1L, 4L))
  if (anyDuplicated(year)) cli::cli_abort("Duplicate years in a source table.")
  list(years = year, cells = x)
}
matrix_values <- function(x, ...) matrix(numeric_cell(as.matrix(x), ...), nrow = nrow(x), ncol = ncol(x))
number <- function(x) ifelse(is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
blank <- function(file, n) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
input <- function(type, measure, basis, value, unit, year = NA, age = NA,
                  fleet = "", survey = "", time = NA, year_basis = "calendar_year",
                  reference, notes, source_type = "official_machine_readable") {
  n <- length(value); out <- blank("inputs.csv", n)
  out$type <- type; out$measure <- measure; out$basis <- basis
  out$value <- number(value); out$unit <- unit; out$fleet <- fleet; out$survey <- survey
  out$year <- ifelse(is.na(rep_len(year, n)), "", rep_len(year, n))
  out$year_basis <- ifelse(nzchar(out$year), year_basis, "")
  out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$sampling_time <- number(rep_len(time, n)); out$source_type <- source_type
  out$source_reference <- paste0(report_url, "; Table ", reference)
  out$notes <- notes
  out
}
grid_input <- function(values, years, ages, ...) {
  g <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
  stopifnot(identical(dim(values), c(length(years), length(ages))))
  input(value = as.vector(values), year = g$year, age = g$age, ...)
}
years <- 1992:2025
ages <- 2:19
total <- annual(table("6.8"))
pelagic <- annual(table("6.9"))
stopifnot(identical(total$years, years), identical(pelagic$years, 2006:2025))
total_catch <- matrix_values(total$cells[, 2:15])
pelagic_catch <- matrix_values(pelagic$cells[, 2:14])
overlap_note <- paste("Source total includes the pelagic subset reported separately in Table 6.9.",
  "Age 19 denotes the reported 19+ group.",
  "Do not add the two series. Exact conversion to the two fitted fleet likelihoods remains unresolved.",
  "Printed dashes are retained as missing; source-estimated age compositions are described in the table caption and Section 6.2.2.")
inputs <- rbind(
  grid_input(total_catch, years, 6:19, type = "catch", measure = "numbers_at_age", basis = "numbers",
    unit = "thousand fish", fleet = "All fisheries (source total)", reference = "6.8", notes = overlap_note),
  input("catch", "total_biomass", "biomass", numeric_cell(total$cells[[17L]]), "tonnes",
    years, fleet = "All fisheries (source total)", reference = "6.8", notes = overlap_note),
  grid_input(pelagic_catch, pelagic$years, 7:19, type = "catch", measure = "numbers_at_age", basis = "numbers",
    unit = "thousand fish", fleet = "Pelagic outside EEZ (subset)", reference = "6.9", notes = overlap_note),
  input("catch", "total_biomass", "biomass", numeric_cell(pelagic$cells[[16L]]), "tonnes",
    pelagic$years, fleet = "Pelagic outside EEZ (subset)", reference = "6.9", notes = overlap_note))

weight_table <- table("6.12")
maturity_table <- table("6.14")
weight <- numeric_cell(unlist(weight_table[weight_table[[1L]] == "Modelled", -1L]))
maturity <- numeric_cell(unlist(maturity_table[maturity_table[[1L]] == "Model input", -1L]))
stopifnot(length(weight) == 14L, length(maturity) == 14L,
  all(is.finite(weight)), all(is.finite(maturity)), all(weight > 0),
  all(maturity >= 0 & maturity <= 1))
inputs <- rbind(inputs,
  input("weight", "weight_at_age", "kg_per_fish", weight, "kg per fish", age = 6:19,
    reference = "6.12, Modelled row", notes = "Fixed across model years; annual observed weights elsewhere in the table are not the fitted-model input. Published ages 2-5 are unavailable."),
  input("catch_weight", "weight_at_age", "kg_per_fish", weight, "kg per fish", age = 6:19,
    reference = "6.12, Modelled row; WKREDFISH 2018 WD4 Section 3.1.4", notes = "The source framework uses identical catch and stock weights; the common fixed vector is retained on the published ages only."),
  input("maturity", "maturity_at_age", "proportion", maturity, "proportion", age = 6:19,
    reference = "6.14, Model input row", notes = "Fixed across years since the 2024 assessment; annual observed ogives are not the 2026 model input. The numerical 2026 vector at ages 2-5 is not published."),
  input("M", "natural_mortality_at_age", "per_year", rep(0.05, length(ages)), "per year", age = ages,
    reference = paste0("Section 6.2.5; ", framework_url, "; WD4"), source_type = "official_document",
    notes = "Fixed across ages and years; reported as 0.05, with the exact native scalar configuration unrecovered. Not an estimated M output."))

for (spec in list(list(table = "6.15", survey = "Russian autumn groundfish", ages = 0:11,
                      time = 0.90, basis = "birth_cohort", unit = "fish per hour"),
                  list(table = "6.17", survey = "Ecosystem survey", ages = 2:15,
                      time = 0.75, basis = "calendar_year", unit = "million fish"),
                  list(table = "6.18b", survey = "Winter bottom trawl", ages = 2:15,
                      time = 0.12, basis = "calendar_year", unit = "million fish"))) {
  x <- annual(table(spec$table))
  k <- length(spec$ages)
  cells <- x$cells[, seq.int(2L, k + 1L), drop = FALSE]
  values <- matrix_values(cells, unavailable = c("+", "Noagereading"))
  cell_notes <- ifelse(as.vector(as.matrix(cells)) == "+",
    "The source prints '+' without a numerical value; retained as missing, not zero.",
    ifelse(as.vector(as.matrix(cells)) == "No age reading", "The source reports no age reading; retained as missing.", ""))
  inputs <- rbind(inputs, grid_input(values, x$years, spec$ages,
    type = "index", measure = "numbers_at_age", basis = "numbers", unit = spec$unit,
    survey = spec$survey, time = spec$time, year_basis = spec$basis, reference = spec$table,
    notes = paste("Source table cells retained, including zeros and missing values. Timing is documented in WKREDFISH 2018 WD4 Section 3.2.",
      if (spec$basis == "birth_cohort") "The source labels its first column Yearclass. It is preserved as birth_cohort; do not interpret it as sampling year or fit the reported ages 0-1 as source SCAA observations. Exact production cell selection remains unresolved." else
        "The precise cell set and observation weights consumed by the production run remain unresolved.", cell_notes)))
  if (spec$table == "6.17") inputs <- rbind(inputs,
    input("index", "index_by_age_group", "numbers", numeric_cell(x$cells[[16L]], unavailable = "Noagereading"), "million fish",
      x$years, age = 16, survey = spec$survey, time = spec$time, reference = spec$table,
      notes = "Reported combined age group 16+; not an age-16 observation. Framework age-index fitting uses ages 2-15; inclusion of this extra reported group is unverified."))
}

output <- function(type, measure, value, unit, year = NA, age = NA,
                   group = "", fleet = "", reference, notes,
                   source_type = "official_machine_readable") {
  n <- length(value); out <- blank("outputs.csv", n)
  out$type <- type; out$measure <- measure; out$value <- number(value); out$unit <- unit
  out$year <- ifelse(is.na(rep_len(year, n)), "", rep_len(year, n))
  out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$age_group <- group; out$fleet <- fleet; out$source_type <- source_type
  out$source_reference <- paste0(report_url, "; Table ", reference)
  out$notes <- notes
  out
}
population <- annual(table("6.20a"), column = 3L)
stopifnot(identical(population$years, years))
N <- matrix_values(population$cells[, 4:21])
fy <- matrix_values(population$cells[, 1:2])
pelagic_selectivity <- numeric_cell(unlist(table("6.20b")[2L, -1L]))
demersal <- annual(table("6.20c"))
stopifnot(identical(demersal$years, years))
sd <- matrix_values(demersal$cells[, -1L])
sp <- matrix(rep(pelagic_selectivity, each = length(years)), length(years), length(ages))
F <- sd * fy[, 1L] + sp * fy[, 2L]
summary <- annual(table("6.21"))
s <- matrix_values(summary$cells[, -1L])
stopifnot(identical(summary$years, years), all(is.finite(N)), all(is.finite(F)),
  all(N > 0), all(F >= 0),
  max(abs(N[, 1L] / 1000 - s[, 1L])) <= 0.5,
  max(abs(N[, 5L] / 1000 - s[, 2L])) <= 0.5)
# Three-decimal Fy/selectivity and F summaries imply this worst-case rounding bound.
rounding_bound <- 0.0015 + 0.0005 * max(rowSums(fy)) + 0.0000005
stopifnot(max(abs(rowMeans(F[, match(12:18, ages)]) - s[, 5L])) <= rounding_bound,
  max(abs(F[, 18L] - s[, 6L])) <= rounding_bound)
g <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
outputs <- rbind(
  output("population", "numbers_at_age", as.vector(N), "thousand fish", g$year, g$age,
    group = ifelse(g$age == 19, "19+", ""), reference = "6.20a",
    notes = "Reported population N. The source internally tracks older cohorts in a right-trapezoid matrix; this table aggregates ages 19 and older. No numerical uncertainty is supplied."),
  output("mortality", "fishing_mortality_at_age", as.vector(F), "per year", g$year, g$age,
    group = ifelse(g$age == 19, "19+", ""), reference = "6.20a-c; WKREDFISH 2018 WD4 Section 2.2",
    notes = "Derived total F = demersal Fy * demersal selectivity + pelagic Fy * pelagic selectivity. Source coefficients/selectivities are rounded to three decimals; derived F is approximate. No uncertainty is invented.", source_type = "derived_source_output"),
  output("mortality", "fleet_F_coefficient", as.vector(fy), "per year", rep(years, 2),
    fleet = rep(c("Demersal", "Pelagic"), each = length(years)), reference = "6.20a",
    notes = "Reported separable annual fleet coefficient, not an age-specific total F."),
  output("biology", "fleet_selectivity_at_age", as.vector(sd), "proportion", g$year, g$age,
    fleet = "Demersal", reference = "6.20c", notes = "Reported annual demersal selectivity; source coefficient precision retained."),
  output("biology", "fleet_selectivity_at_age", pelagic_selectivity, "proportion", age = ages,
    fleet = "Pelagic", reference = "6.20b", notes = "Reported time-invariant pelagic selectivity."),
  output("recruitment", "recruitment", s[, 1L], "million fish", years, age = 2,
    reference = "6.21", notes = "Native age-2 recruitment; rounded to whole millions. Point-estimate convention and uncertainty not specified."),
  output("recruitment", "recruitment_age6_reported", s[, 2L], "thousand fish (reported header; inconsistent with N-at-age)", years, age = 6,
    reference = "6.21", notes = "Preserved exactly as labelled. Values agree with Table 6.20a age-6 N divided by 1000, suggesting millions, not the header's thousands. Do not use this ambiguous series as standard recruitment; use same-year age-6 N for an aligned comparison."),
  output("biomass", "total_biomass", s[, 3L], "tonnes", years,
    reference = "6.21", notes = "Native total stock biomass for age 2+; no uncertainty is supplied."),
  output("biomass", "SSB", s[, 4L], "tonnes", years,
    reference = "6.21", notes = "Native spawning-stock biomass. It must not be assumed recoverable from the incomplete published weight vector and the aggregated 19+ N group."),
  output("mortality", "Fbar", s[, 5L], "per year", years, group = "12-18",
    reference = "6.21", notes = "Reported F summary over ages 12-18. Reconstructed arithmetic F from the rounded fleet coefficients/selectivities agrees within their rounding bound."),
  output("mortality", "F_age19plus", s[, 6L], "per year", years, age = 19, group = "19+",
    reference = "6.21", notes = "Native reported F for the terminal group, kept separately from the reconstructed total F surface."),
  output("population", "total_numbers", rowSums(N), "thousand fish", years,
    reference = "6.20a", notes = "Sum of all reported N groups, ages 2-18 and 19+, with no duplicated older cohorts. No joint uncertainty is available.", source_type = "derived_source_output"))

assumption <- function(component, setting, value, notes, reference = "Chapter 6; WKREDFISH 2018 WD4") {
  out <- blank("assumptions.csv", 1)
  out$component <- component; out$setting <- setting; out$value <- value
  out$notes <- notes; out$source_reference <- paste(report_url, reference, framework_url, sep = "; ")
  out
}
assumptions <- rbind(
  assumption("population", "years_and_ages", "1992-2025; reported ages 2-19+", "Native population uses a right-trapezoid matrix with explicit older cohorts; published reporting aggregates 19+."),
  assumption("N", "recruitment_process", "AR(1) on log age-2 recruitment", "Baseline framework, retained in the 53-parameter 2026 SCAA configuration."),
  assumption("N", "survival_process", "Deterministic cohort survival after recruitment", "Framework WD4 equations 1-3; not IID survival process error."),
  assumption("F", "process", "Separate AR(1) annual demersal and pelagic components; AR(1) demersal selectivity parameters", "Fleet mortality is separable; pelagic fleet starts in 2006. No replacement with a SAM model is implied."),
  assumption("M", "natural_mortality", "Fixed 0.05 per year", "Retained after the 2018 benchmark; source sensitivity scenarios are not the production M."),
  assumption("biology", "stock_and_catch_weights", "Fixed modelled weight vector", "Use the Modelled row of Table 6.12, not observed annual weights. Numerical ages 2-5 and detailed older-age weights remain unrecovered."),
  assumption("biology", "maturity", "Fixed model-input maturity vector since 2024", "Use the Model input row of Table 6.14. The 2018 framework treated ages below 6 as immature, but the complete numerical 2026 vector is not published."),
  assumption("catch", "overlapping_source_series", "Source total catch and separate pelagic-outside-EEZ subset", "Do not sum the source total and subset. Exact transformation to two fleet likelihood arrays is unresolved."),
  assumption("catch", "observation_model", "Lognormal catch-at-age and lognormal catch-in-weight components", "Framework WD4 Sections 2.11 and 3.4; exact production variances/weights not tabulated."),
  assumption("index", "survey_inventory", "Russian autumn, ecosystem, winter bottom trawl, deep pelagic ecosystem", "Deep pelagic age compositions are a separate logit-scale likelihood, not an additional absolute age index; numerical compositions are unavailable."),
  assumption("index", "survey_timing", "Winter 0.12; ecosystem 0.75; Russian autumn 0.90; deep pelagic 0.67", "Documented model timing fractions in WKREDFISH 2018 WD4 Section 3.2."),
  assumption("index", "absolute_scale", "Ecosystem survey scaling fixed in the framework", "WD4 gives 1/3500 under its native input convention; the 2026 tables report millions. The current native unit conversion/configuration was not recovered, so no new numerical q is inferred."),
  assumption("index", "Russian_year_basis", "birth_cohort", "Table 6.15 labels its first column Yearclass. Original cohort labels are preserved; production observation selection remains unresolved."),
  assumption("assessment", "implementation", "Stock-specific SCAA in TMB", "Native code and configuration for this production run were not located. This is not stockassessment/SAM."),
  assumption("assessment", "recruitment_unit_conflict", "Table 6.21 age-6 header conflicts with Table 6.20a", "Raw age-6 summary and unit label preserved separately; N-at-age supports the factor-of-1000 discrepancy. No silent rescaling."))

assessment <- blank("assessments.csv", 1)
assessment$stock_id <- stock_id; assessment$assessment_year <- "2026"
assessment$terminal_year <- assessment$estimate_terminal_year <- "2025"
assessment$assessment_type <- "annual"; assessment$model_family <- "SCAA"
assessment$model_version <- "Stock-specific TMB SCAA, 53-parameter 2018 framework; native code revision unavailable"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- "2018"
assessment$assessment_url <- report_url; assessment$framework_url <- framework_url
assessment$data_url <- report_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Latest detailed JRN-AFWG production assessment. Published N, rounded fleet coefficients/selectivities and stock summaries recovered. Young-age biology, numerical deep-pelagic age compositions, exact fleet-input assembly and native configuration remain unavailable. Age-6 recruitment unit conflict is retained explicitly. No tinyAM fit or guessed source inputs are claimed."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
at <- which(stocks$stock_id == stock_id)
stopifnot(length(at) == 1L, stocks$charbonneau_id[at] == "ICES-AFWG_mentella_DEEP 1,2")
stocks$authority[at] <- "JRN-AFWG (IMR/VNIRO)"
stocks$authority_stock_id[at] <- "reb.27.1-2"
stocks$common_name[at] <- "Northeast Arctic beaked redfish"
stocks$area[at] <- "ICES subareas 1 and 2 (Northeast Arctic)"
stocks$region[at] <- "Norwegian Sea and Barents Sea"; stocks$ocean[at] <- "Northeast Atlantic"
stocks$notes[at] <- "Charbonneau-Keith ICES-AFWG_mentella_DEEP 1,2; verified as the JRN-AFWG beaked-redfish SCAA stock. The 2026 detailed record is partial; missing biology/configuration are not inferred from unrelated SAM assessments."

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
    if (length(selected) != nrow(x)) cli::cli_abort("Existing {file} coverage differs; review before replacing.")
    lines[selected] <- paste0(replacement, ifelse(endsWith(lines[selected], "\r"), "\r", ""))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", stocks[at, ], stock_id)
write_rows("assessments.csv", assessment)
write_rows("assumptions.csv", assumptions)
write_rows("inputs.csv", inputs)
write_rows("outputs.csv", outputs)
cat("Imported beaked redfish 2026:", nrow(inputs), "inputs,", nrow(assumptions), "assumptions and", nrow(outputs), "outputs; source statuses remain partial.\n")
