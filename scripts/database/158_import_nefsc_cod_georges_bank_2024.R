base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_nefsc_garmiii_morhua_gb_2024")
stock_id <- "nefsc_cod_georges_bank"
legacy_id <- "ck_nefsc_garmiii_morhua_gb"
assessment_id <- "nefsc_cod_georges_bank_2024"
portal <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php"
report_url <- paste0("https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?",
  "year=2024&species_id=4&stock_id=1&review_type_id=3&info_type_id=-1&filename=2024_COD_GB_Report.pdf")
background_url <- sub("info_type_id=-1&filename=2024_COD_GB_Report.pdf",
  "info_type_id=5&filename=2024_COD_GB_Background.pdf", report_url, fixed = TRUE)
framework_url <- "https://www.fisheries.noaa.gov/s3/2023-08/PanelSummaryReportoftheAtlanticCodRTPeerReviewAugust172023-mlt-508-8-23-23ajd-508gw.pdf"
review_url <- "https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf"
verify <- function(file, sha) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(file = path, algo = "sha256") != sha) {
    cli::cli_abort("Cache and verify {file} before importing.")
  }
  path
}
report <- pdftools::pdf_text(verify("2024_COD_GB_Report.pdf",
  "9dd14ac204955f885969c392b3d471523987fa1fa5d7fa21b8dd74bd383f54c1"))
verify("2024_COD_GB_Background.pdf", "ddcc0d461250ce4bfdcfb80d1dc09cdf762fc2432e06b40292069064815b6061")
verify("2024_COD_GB_Presentation.pdf", "2f24aac3350f3ad7793295031650c9244c199211f21dd10a3212197863cfafd8")
verify("2024_June_peer_review.pdf", "22f498b0da30599b12d98ed9d0875d9c0bdd6a1e929cbecf8a1d6e7a569daccb")
verify("2023_cod_research_track_peer_review.pdf", "44845e54ab76e8cc6f02aaff0727e07d64697b40b7e4b742ea69f897cf242755")
table_page <- which(grepl("Table 1: Catch and status", report, fixed = TRUE))
stopifnot(length(table_page) == 1L)
lines <- strsplit(report[table_page], "\n")[[1L]]
table_row <- function(pattern) {
  row <- grep(pattern, lines, value = TRUE)
  stopifnot(length(row) == 1L)
  values <- suppressWarnings(as.numeric(gsub(",", "", tail(strsplit(trimws(row), "[[:space:]]+")[[1L]], 10))))
  stopifnot(length(values) == 10L, all(is.finite(values)))
  values
}
catch <- table_row("^\\s*Combined total catch")
ssb <- table_row("^\\s*Spawning Stock Biomass")
f_full <- table_row("^\\s*F.*0\\.3.*0\\.28")
recruitment <- table_row("^\\s*Recruits\\s")
stopifnot(tail(catch, 1) == 417, tail(ssb, 1) == 2668,
  tail(f_full, 1) == .13, tail(recruitment, 1) == 605)
blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
inputs <- blank("inputs.csv", 19L)
inputs$sex <- "combined"; inputs$region <- "Georges Bank, 2023 revised stock definition"
inputs$season <- "annual"; inputs$source_type <- "official_table"
inputs$type <- c(rep("catch", 10), rep("M", 9))
inputs$measure <- c(rep("total_biomass", 10), rep("natural_mortality_at_age", 9))
inputs$basis <- c(rep("biomass", 10), rep("per_year", 9))
inputs$source_type[11:19] <- "official_document"
inputs$year <- c(2014:2023, rep(NA_integer_, 9))
inputs$year_basis <- c(rep("calendar_year", 10), rep("", 9))
inputs$age <- c(rep(NA_integer_, 10), 1:9)
inputs$value <- c(catch, rep(.29, 9))
inputs$unit <- c(rep("tonnes", 10), rep("year^-1", 9))
inputs$fleet[1:10] <- "Combined US and Canadian fishery"
inputs$source_reference[1:10] <- paste(report_url, "Table 1")
inputs$source_reference[11:19] <- paste(sub("info_type_id=-1&filename=2024_COD_GB_Report.pdf",
  "info_type_id=6&filename=2024_COD_GB_Presentation.pdf", report_url, fixed = TRUE), "slide 3;", framework_url, "pp. 13 and 19")
inputs$notes[1:10] <- "Reported combined US/Canadian landings and dead discards, not landings alone or separate gear fleets. Rounded totals are retained rather than recomputed from rounded components. No catch-at-age is inferred from fitted states; 2024 assumed projection catch is excluded."
inputs$notes[11:19] <- "Fixed M assumption 0.29 per year, explicitly retained from RT to MT in presentation slide 3. Age 9 denotes the terminal 9+ group; no M estimate or uncertainty is implied. The older catalogue value is not substituted."
output <- function(measure, type, values, unit, age = NA_integer_, group = "", definition) {
  x <- blank("outputs.csv", 10L); x$type <- type; x$measure <- measure
  x$year <- 2014:2023; x$value <- values; x$age <- age; x$age_group <- group
  x$sex <- "combined"; x$region <- "Georges Bank, 2023 revised stock definition"; x$season <- "annual"
  x$unit <- unit; x$source_type <- "official_table"; x$source_reference <- paste(report_url, "Table 1")
  x$notes <- paste("Official 2024 MT run 4. Reported rounded point estimates; marginal SEs/CIs unavailable in this table.", definition)
  x
}
outputs <- rbind(output("SSB", "biomass", ssb, "tonnes", definition = "Native spawning-biomass definition; no common-definition calculation without source N and biological surfaces."),
  output("recruitment", "recruitment", recruitment, "thousand fish", age = 1,
    definition = "Native age-1 recruitment. Earlier model years are not reconstructed from figures."),
  output("fishing_mortality_at_age", "mortality", f_full, "year^-1", age = 9, group = "9+",
    definition = "Fully selected F on reported ages 9+, not population-weighted Fbar or estimates for younger ages."))
at <- outputs$year == 2023 & outputs$measure %in% c("SSB", "fishing_mortality_at_age")
outputs$notes[at] <- paste(outputs$notes[at],
  "Report p. 2 gives an approximate 90% JOINT SSB/F confidence region with SSB axis bounds 1528-4660 t and F axis bounds 0.073-0.233/year. These are retained as source context here, not marginal 95% CIs or reconstructed SEs. No rho adjustment was applied.")
assumption <- function(component, setting, value, notes = "", reference = background_url) {
  x <- blank("assumptions.csv"); x$component <- component; x$setting <- setting
  x$value <- value; x$notes <- notes; x$source_reference <- reference; x
}
assumptions <- rbind(
  assumption("assessment", "official_run", "2024 WHAM management-track run 4, data 1978-2023", "The report retains a draft watermark; the final June panel found all ToRs met and results suitable for management. Not the older rejected analytical assessment, empirical PlanBsmooth advice, or Canadian Eastern GB assessment.", review_url),
  assumption("population", "stock_boundary", "2023 revised GB unit excludes statistical areas 521 and 526; SNE is separate", "The historic combined CK row remains distinct and does not inherit these values.", paste(framework_url, "p. 12;", review_url, "p. 25")),
  assumption("population", "age_range", "Ages 1-9+, recruitment at age 1", reference = paste(framework_url, "pp. 13-14;", report_url, "Tables 1-2")),
  assumption("catch", "structure", "One combined US/Canadian commercial fishery", "Includes US landings/discards and Canadian landings/scallop/groundfish discards. Not five independent fitted fleets."),
  assumption("catch", "age_composition_gaps", "Only Canadian catch ages used in 2022-2023; US ages unavailable", "No invented US catch composition; numerical original Canadian and earlier combined age arrays remain unrecovered."),
  assumption("index", "structure", "DFO spring, NEFSC spring and NEFSC fall surveys", "DFO 2022 excluded after vessel change; NEFSC spring 2023 excluded after interrupted/nighttime sampling. Exact observation dates, q sharing and per-observation SD inputs remain unresolved."),
  assumption("index", "calibration", "NEFSC spring/fall recalibrated for Yankee gear and Albatross-to-Bigelow vessel change", "Revised whole series/CVs are required; older uncorrected arrays must not be substituted."),
  assumption("biology", "weight", "Revised numbers-weighted combined-fishery weights; Canadian counts converted to fish before pooling", "RT mixed fish and thousand-fish units. Current WAA recalculates after Canadian landings-age revisions and uses Canadian WAA in terminal gaps instead of a five-year average. Numeric current matrices remain missing."),
  assumption("biology", "maturity", "State-space maturity model, updated through 2023", "Native numerical ogives and spawning-time fractions were not recovered; source figures are not treated as original tables."),
  assumption("M", "model", "Fixed M=0.29 per year at all modeled ages; unchanged in MT", reference = inputs$source_reference[11]),
  assumption("N", "process", "Decoupled 2DAR1 NAA random effects, with recruitment correlation bug corrected", "This supersedes the RT IID specification. Exact current SD sharing/correlation parameters remain unavailable without native configuration."),
  assumption("N", "initialization", "Initial N-at-age estimated independently rather than an equilibrium age distribution"),
  assumption("index", "fall_selectivity", "NEFSC fall selectivity fixed at 1 for ages 1-3 for convergence", "This unusual selection of young ages was noted by the final panel for future investigation. It is not a monotone-increasing curve or fitted relative abundance.", paste(background_url, "section 4.0.2;", review_url, "p. 5")),
  assumption("observation", "age_likelihood", "Dirichlet-multinomial age composition, retained from RT to MT", reference = inputs$source_reference[11]),
  assumption("assessment", "lognormal_adjustment", "Default WHAM lognormal adjustments switched off in final MT run 4", "Do not use MT 2.4 or RT estimates as the final run. The report describes changes to both process/observation adjustments; exact equations/phases require matching native code."),
  assumption("assessment", "retrospective_adjustment", "No rho adjustment to stock status or projections", "Mohn rho: recruitment -0.0718, SSB 0.1900, F -0.1336; stock-status point values are the unadjusted estimates."),
  assumption("assessment", "remaining_inputs", "Current SASINF listing has report, background, discard tracker and presentation PDFs; no native model files listed", "Searched current portal and public code repositories. Catch/survey age arrays, numerical biology, timing and fitted N/full F states remain unrecovered. This is a source gap, not proof those objects do not exist."))
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2024; assessment$terminal_year <- assessment$estimate_terminal_year <- 2023
assessment$assessment_type <- "management_track"; assessment$model_family <- "WHAM"
assessment$model_version <- "MT run 4; exact production code revision not recovered"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2023
assessment$assessment_url <- report_url; assessment$framework_url <- framework_url; assessment$data_url <- portal
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "2024 US WHAM assessment for the 2023-redefined GB stock. Numeric recent catch/status table and fixed M recovered; original age/biology inputs and fitted state surfaces missing. Not the Canadian Eastern Georges Bank assessment. Forecast years 2024-2027 excluded. Next cod management review scheduled for 2027. See source_reviews/nefsc_cod_georges_bank.md."
stocks <- read.csv(file.path(database,"stocks.csv"),colClasses="character",na.strings="",check.names=FALSE)
stock <- blank("stocks.csv"); stock$stock_id <- stock_id; stock$charbonneau_id <- NA_character_
stock$authority <- "NOAA-NEFSC"; stock$authority_stock_id <- "Georges Bank"
stock$scientific_name <- "Gadus morhua"; stock$common_name <- "Georges Bank cod (US assessment)"
stock$area <- "Georges Bank, revised 2023 unit excluding statistical areas 521 and 526"
stock$region <- "Georges Bank"; stock$ocean <- "Northwest Atlantic"
stock$notes <- paste("Related historical catalogue row",legacy_id,"(NEFSC-GARMIII_morhua_GB) uses the older, wider stock definition. Current US assessment combines US/Canadian catches but is not the separate Canadian Eastern GB assessment. Master ID remains on the historical row.")
legacy <- stocks[stocks$stock_id==legacy_id,]
stopifnot(nrow(legacy)==1L,legacy$charbonneau_id=="NEFSC-GARMIII_morhua_GB",legacy$scientific_name=="Gadus morhua",legacy$area=="GB")
note <- "Reviewed stock-boundary relationship (2026-10-26): the 2023 research track redefined the GB stock, excluding statistical areas 521 and 526 and separating SNE. Related current stock_id=nefsc_cod_georges_bank. Original catalogue identifier/area retained; current data are not copied to this historical unit. Source: 2023 cod research-track peer review, p. 12; source_reviews/nefsc_cod_georges_bank.md."
if(!grepl(note,legacy$notes,fixed=TRUE)) legacy$notes<-paste(legacy$notes,note)
legacy$common_name <- "Georges Bank cod (historical wider unit)"
write_rows <- function(file, x, id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  at <- which(startsWith(lines, paste0('"', id, '",')))
  tmp <- tempfile(tmpdir = database)
  on.exit(unlink(tmp), add = TRUE)
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(at)) {
    stopifnot(identical(at, seq.int(min(at), max(at))))
    replacement <- paste0(replacement, if (endsWith(lines[at[1]], "\r")) "\r" else "")
    lines <- c(head(lines, min(at) - 1L), replacement, tail(lines, length(lines) - max(at)))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv",legacy,legacy_id);write_rows("stocks.csv",stock,stock_id)
for(table in c("assessments","assumptions","inputs","outputs"))write_rows(paste0(table,".csv"),if(table=="assessments")assessment else get(table),assessment_id)
cat("Imported 2024 Georges Bank cod:",nrow(inputs),"inputs,",nrow(assumptions),"assumptions and",nrow(outputs),"outputs; original likelihood/biology gaps remain.\n")
