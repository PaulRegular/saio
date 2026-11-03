base <- "."
db <- file.path(base, "database")
cache <- file.path(base, "source_cache/ices_cod_western_baltic_2026")
id <- "ices_cod_western_baltic_2026"
old_id <- "ices_cod_western_baltic_2025"
source_url <- "https://literatur.thuenen.de/digbib_extern/dn071152.pdf"
pdf <- file.path(cache, "wgbfas_2026_report.pdf")
pdf_raw <- readBin(pdf, what = "raw", n = file.info(pdf)[["size"]])
stopifnot(tolower(digest::digest(pdf_raw, algo = "sha256", serialize = FALSE)) ==
  "7e8a6ac51f72abf7d1f026e0997f764267f07690cb2b78e32e073e13fd658732")
text <- readLines(file.path(cache, "wgbfas_2026_report.txt"), warn = FALSE, encoding = "UTF-8")
section <- function(start, end) {
  a <- grep(start, text, fixed = TRUE); b <- grep(end, text, fixed = TRUE)
  a <- a[a > 3000][1]; b <- b[b > a][1]
  stopifnot(!is.na(a), !is.na(b)); text[seq.int(a + 1L, b - 1L)]
}
rows <- function(lines, ncol) {
  lines <- trimws(lines[grepl("^\\s*(19[0-9]{2}|20[0-9]{2})\\s+", lines)])
  x <- strsplit(lines, "[[:space:]]+")
  stopifnot(all(lengths(x) == ncol), !anyDuplicated(vapply(x, `[`, "", 1)))
  do.call(rbind, lapply(x, function(z) as.numeric(z)))
}
catch <- rows(section("Table 2.3.15.", "Table 2.3.16."), 8L)
land_lines <- section("Table 2.3.16.", "Table. 2.3.17."); land_lines <- sub("^(\\s*2025.*)$", "\\1 NA", land_lines); land_weight <- rows(land_lines, 8L)
discard_weight <- rows(section("Table. 2.3.17.", "Table 2.3.18."), 6L)
catch_weight_lines <- section("Table 2.3.18.", "Table 2.3.19."); catch_weight_lines <- sub("^(\\s*202[45].*)$", "\\1 NA", catch_weight_lines); catch_weight <- rows(catch_weight_lines, 8L)
stock_weight_lines <- section("Table 2.3.19.", "Table 2.3.20."); stock_weight_lines <- sub("^(\\s*202[45].*)$", "\\1 NA", stock_weight_lines); stock_weight <- rows(stock_weight_lines, 9L)
q1 <- rows(section("Table 2.3.22b.", "Table 2.3.22c."), 5L)
q4 <- rows(section("Table 2.3.22c.", "Table 2.3.23."), 6L)
fej <- rows(section("Table 2.3.22a.", "Table 2.3.22b."), 2L)
summary <- rows(section("Table 2.3.23.", "Table 2.3.24."), 13L)
nlines <- section("Table 2.3.24.", "Table 2.3.25.")
# The final year has no published age-0 value; retain it as missing.
nlines <- sub("^(\\s*2026)\\s+", "\\1 NA ", nlines)
n <- rows(nlines, 9L)
z <- rows(section("Table 2.3.25.", "Table 2.3.26."), 6L)
harvest_start <- grep('Table 2.3.26.', text, fixed=TRUE); harvest_start <- harvest_start[harvest_start > 3000][1]
harvest_lines <- text[seq.int(harvest_start + 1L, length(text))]
harvest <- rows(head(harvest_lines[grepl('^\\s*(19[0-9]{2}|20[0-9]{2})\\s+', harvest_lines)], 41L), 2L)

stopifnot(identical(as.integer(catch[,1]),1985:2025),
  identical(as.integer(summary[,1]),1985:2026), identical(as.integer(n[,1]),1985:2026),
  identical(as.integer(z[,1]),1985:2025), catch[41,2] == 46,
  identical(as.integer(land_weight[,1]),1985:2025), identical(as.integer(discard_weight[,1]),2015:2025),
  identical(as.integer(catch_weight[,1]),1985:2025), identical(as.integer(stock_weight[,1]),1985:2025),
  summary[42,2] == 1678, summary[42,5] == 2287, is.na(n[42,2]), n[42,3] == 1678,
  q1[nrow(q1),1] == 2026, q1[nrow(q1),2] == 352,
  q4[nrow(q4),1] == 2025, q4[nrow(q4),2] == 398, identical(as.integer(harvest[,1]),1985:2025), tail(harvest[,2],1) == 0.028)
blank <- function(file, n) {
  cols <- names(read.csv(text = readLines(file.path(db, file), n = 1, warn = FALSE), check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(cols)), stringsAsFactors = FALSE)
  names(x) <- cols; x$assessment_id <- id; x
}
matrix_rows <- function(x, ages, file, type, measure, unit, table, basis = "", label = "") {
  grid <- expand.grid(row = seq_len(nrow(x)), col = seq_along(ages))
  values <- x[cbind(grid$row, grid$col + 1L)]
  keep <- is.finite(values); grid <- grid[keep,,drop=FALSE]; values <- values[keep]
  out <- blank(file, length(values)); out$type <- type; out$measure <- measure
  out$year <- x[grid$row,1]; out$age <- ages[grid$col]; out$value <- values; out$unit <- unit
  out$source_type <- "official_table"; out$source_reference <- paste0(source_url, "; Table ", table)
  if (file == "inputs.csv") {
    out$basis <- basis; out$year_basis <- "calendar_year"; out$transformation <- "Reshaped the published table from wide to long; values are rounded."
    if (type == "catch" || type == "catch_weight") out$fleet <- label
    if (type == "index") out$survey <- label
    out$notes <- "Published rounded values, including zeros; native model data and observation treatment have not been verified."
  } else out$notes <- "Reported rounded estimate; no age-specific uncertainty supplied."
  out
}
inputs <- rbind(matrix_rows(catch,1:7,"inputs.csv","catch","numbers_at_age","thousand fish","2.3.15","numbers","Total catch"),
  matrix_rows(q1,1:4,"inputs.csv","index","numbers_at_age","native survey-index units","2.3.22b","index_scale","BITS Q1"),
  matrix_rows(q4,0:4,"inputs.csv","index","numbers_at_age","native survey-index units","2.3.22c","index_scale","BITS Q4"),
  matrix_rows(fej,0,"inputs.csv","index","numbers_at_age","native survey-index units","2.3.22a","index_scale","FEJUCS"),
  matrix_rows(land_weight,1:7,"inputs.csv","catch_weight","landings_weight_at_age","kg per fish","2.3.16","kg_per_fish","Commercial landings"),
  matrix_rows(discard_weight,3:7,"inputs.csv","catch_weight","discard_weight_at_age","kg per fish","2.3.17","kg_per_fish","Discards"),
  matrix_rows(catch_weight,1:7,"inputs.csv","catch_weight","weight_at_age","kg per fish","2.3.18","kg_per_fish","Combined catch"),
  matrix_rows(stock_weight,0:7,"inputs.csv","weight","weight_at_age","kg per fish","2.3.19","kg_per_fish"))
m <- blank("inputs.csv", 8); m$type <- "M"; m$measure <- "natural_mortality_at_age"
m$basis <- "per_year"; m$age <- 0:7; m$value <- c(1.318,0.598,0.411,0.324,0.274,0.241,0.218,0.201)
m$unit <- "per year"; m$source_type <- "official_table"; m$source_reference <- paste0(source_url, "; Table 2.3.21")
m$transformation <- "Copied the constant age vector; no annual replication."
m$notes <- "Table labels this vector 1985-2025; the 2026 input configuration has not been verified."
inputs <- rbind(inputs, m)
maturity <- blank("inputs.csv", 7); maturity$type <- "maturity"; maturity$measure <- "maturity_at_age"
maturity$basis <- "proportion"; maturity$age <- 1:7; maturity$value <- c(.06,.60,.84,.86,.90,.94,1)
maturity$unit <- "proportion"; maturity$source_type <- "official_table"; maturity$source_reference <- paste0(source_url, "; Table 2.3.20")
maturity$transformation <- "Stored the fixed maturity vector once without annual replication."
maturity$notes <- "The report specifies this fixed vector for 1998-2025; native model setting and earlier treatment remain unverified."
inputs <- rbind(inputs, maturity)
inputs$notes[inputs$type == "index" & inputs$survey == "BITS Q1"] <- "Published rounded values; assessment uses years 2001-2026. The age-4 row is the pooled 4+ group per report; native SAM inputs and observation treatment were not retrieved."
inputs$notes[inputs$type == "index" & inputs$survey == "BITS Q4"] <- "Published rounded values; assessment uses years 2001-2025. The age-4 row is the pooled 4+ group per report; native SAM inputs and observation treatment were not retrieved."
inputs$notes[inputs$measure == "discard_weight_at_age" & inputs$year == 2024] <- "Age-6 and age-7+ entries are marked as three-year averages in the source table."
inputs$notes[inputs$measure == "landings_weight_at_age"] <- "Rounded source values; age-7+ weight is unreported in 2025."
inputs$notes[inputs$measure == "weight_at_age"] <- "Rounded source values; stock and combined-catch age-7+ weights are unreported in 2024 and 2025."
outputs <- matrix_rows(n,0:7,"outputs.csv","population","numbers_at_age","thousand fish","2.3.24")
outputs$age_group[outputs$age == 7] <- "7+"
zout <- matrix_rows(z,1:5,"outputs.csv","mortality","total_mortality_at_age","per year","2.3.25")
zout$age_group[zout$age == 5] <- "5-7"
zout$notes <- "Total mortality by age; the final column represents the shared ages 5-7 state, not age 5 alone."
outputs <- rbind(outputs, zout)
aggregate <- function(cols, type, measure, unit, age = "") {
  o <- blank("outputs.csv", nrow(summary)); o$type <- type; o$measure <- measure; o$year <- summary[,1]
  o$age <- age; o$value <- summary[,cols[1]]; o$lwr <- summary[,cols[2]]; o$upr <- summary[,cols[3]]
  o$unit <- unit; o$source_type <- "official_table"; o$source_reference <- paste0(source_url,"; Table 2.3.23")
  o$notes <- "Reported low and high bounds; interval level not specified in table. Values are rounded. ICES advises relative trends due to mortality uncertainty."; o
}
zbar <- aggregate(8:10,"mortality","total_mortality","per year")
zbar$age_group <- "3-5"
zbar$notes <- "The table header reads Fbar(3-5), but caption and report text call the quantity Zbar(3-5); recorded as total mortality with that source conflict noted."
outputs <- rbind(outputs, aggregate(2:4,"recruitment","recruitment","thousand fish",1),
  aggregate(5:7,"biomass","SSB","tonnes"), aggregate(11:13,"biomass","total_biomass","tonnes"), zbar)
hout <- blank("outputs.csv", nrow(harvest)); hout$type <- "mortality"; hout$measure <- "harvest_rate"; hout$year <- harvest[,1]; hout$value <- harvest[,2]; hout$unit <- "proportion"; hout$source_type <- "official_table"; hout$source_reference <- paste0(source_url, "; Table 2.3.26"); hout$notes <- "Reported C/SSB harvest rate; ICES uses this instead of F because mortality estimates are unreliable. No uncertainty supplied."
outputs <- rbind(outputs, hout)
# The 2026 age-0 N state is not reported; it is not inferred from adjacent years.
a <- blank("assumptions.csv", 6); a$component <- rep("assessment",6)
a$setting <- c("model_family","assessment_interpretation","commercial_data_weighting","survey_sampling_time","F_summary_label","native_likelihood_settings")
a$value <- c("SAM WBCod2026", "Category 3; relative SSB and recruitment trends and harvest rate due to uncertain mortality", "Commercial data reliability downscaled to 1/10 relative to surveys; exact likelihood encoding unknown", "unknown", "Table 2.3.23 caption/prose say Zbar; column heading says Fbar", "unknown")
a$source_reference <- paste0(source_url,"; section 2.3.5"); a$notes <- "Reported by WGBFAS 2026; native model object and configuration not retrieved."
assessment <- blank("assessments.csv",1); assessment$stock_id <- "ck_ices_wgbfas_morhua_bs"
assessment$assessment_year <- 2026; assessment$terminal_year <- 2025; assessment$estimate_terminal_year <- 2026
assessment$assessment_type <- "assessment_update"; assessment$model_family <- "SAM"; assessment$model_version <- "WBCod2026"
assessment$is_current <- TRUE; assessment$is_applied <- FALSE; assessment$framework_year <- 2019
assessment$assessment_url <- source_url; assessment$framework_url <- "https://doi.org/10.17895/ices.pub.4984"
assessment$model_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/WBCod2026/"
assessment$assumptions_status <- "partial"; assessment$inputs_status <- "partial"; assessment$outputs_status <- "partial"
assessment$notes <- "2026 WGBFAS SAM update, category 3 and relative trends only due to uncertain mortality. Table-derived catch, survey, N, SSB, recruitment and total biomass are rounded. The fitted object and exact native likelihood configuration remain unrecovered. Advice application is not established."
if (Sys.getenv("TAM_SOURCE_DRY_RUN") == "1") {
  cat("Verified",nrow(inputs),"input and",nrow(outputs),"output rows.\n")
} else {
  rewrite <- function(file, new_rows, ids) {
    path <- file.path(db,file)
    lines <- readLines(path,warn=FALSE,encoding="UTF-8")
    remove <- Reduce(`|`,lapply(ids,function(key) startsWith(lines,paste0('"',key,'","'))))
    lines <- lines[!remove & nzchar(lines)]
    tmp <- tempfile(tmpdir=db); on.exit(unlink(tmp),add=TRUE)
    write.table(new_rows,tmp,sep=",",row.names=FALSE,col.names=FALSE,na="",qmethod="double",fileEncoding="UTF-8")
    added <- readLines(tmp,warn=FALSE,encoding="UTF-8")
    writeLines(c(lines,added),path,useBytes=TRUE)
  }
  assessments <- read.csv(file.path(db,"assessments.csv"),colClasses="character",check.names=FALSE)
  stopifnot(any(assessments$assessment_id==old_id))
  assessments$is_current[assessments$assessment_id==old_id] <- "FALSE"
  assessment$is_current <- "TRUE"
  assessment <- rbind(assessments[assessments$assessment_id %in% c(id,old_id),,drop=FALSE],assessment)
  assessment <- assessment[!duplicated(assessment$assessment_id,fromLast=TRUE),,drop=FALSE]
  rewrite("assessments.csv",assessment,c(id,old_id))
  rewrite("assumptions.csv",a,id)
  rewrite("inputs.csv",inputs,id)
  rewrite("outputs.csv",outputs,id)
  cat("Imported",nrow(inputs),"inputs and",nrow(outputs),"outputs.\n")
}
