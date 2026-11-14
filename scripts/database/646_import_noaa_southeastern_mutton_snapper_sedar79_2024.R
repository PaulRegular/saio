root <- "."
assessment_id <- "noaa_southeastern_us_mutton_snapper_sedar79_2024"
stock_id <- "noaa_southeastern_us_mutton_snapper"
candidate_id <- "NOAA:11342"
report_url <- "https://sedarweb.org/documents/sedar-79-southeastern-us-mutton-snapper-final-stock-assessment-report/"
project_url <- "https://sedarweb.org/assessments/sedar-79/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
test_mode <- identical(Sys.getenv("TAM_SOURCE_TEST_MODE"), "1")
if (write_mode && test_mode) stop("Source test mode cannot write.", call. = FALSE)
.libPaths(c(file.path(root, "tmp/Rlib"), file.path(root, "source_cache/r-lib"),
  file.path(root, "source_cache/R-library"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache_name <- "discovery_noaa_mutton_snapper_sedar79_2024"
cache <- file.path(root, "source_cache", cache_name)
manifest <- read.csv(file.path(root, "provenance", cache_name, "sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
expected <- c(
  SEDAR79_DW03_size_age.pdf = "843b200db484723946866325018e92ccee13ec31c2c06764bba1153d1d4502ec",
  SEDAR79_DW12_reproduction.pdf = "7cd48111d84c977c23b809a493c1d5982ef440f6d8380a0d18e0e00143abc6e7",
  SEDAR79_DW22_age_growth_mortality.pdf = "6067337943b4d3a747b3d2917c5cbff61a8157120ba950dc207edba9d21d5fa2",
  SEDAR79_final_SAR.pdf = "a7587c458500b203a7140d5bfdab8524d3017f2a8951d3442130db8b081ee357",
  SEDAR79_project_page.html = "e8e4a923fc6cb75cb143bff00c965d5a8a65eb4346515b89af3bb2fc1d22628e",
  SEDAR79_SSC_review.pdf = "b592fc1d9d6460e5f84d92bf15e98c4cb7e2006b1f618778c1f85127629b00e2"
)
sha256_file <- function(path) {
  x <- system2("certutil.exe", c("-hashfile",
    shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  x <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    x, value = TRUE)))
  if (length(x) != 1L) stop("Could not hash ", path, call. = FALSE)
  x
}
if (!setequal(manifest$file, names(expected)) || anyDuplicated(manifest$file)) {
  stop("SEDAR 79 provenance manifest is incomplete.", call. = FALSE)
}
for (f in names(expected)) {
  m <- manifest[manifest$file == f, , drop = FALSE]
  p <- file.path(cache, f)
  if (nrow(m) != 1L || !file.exists(p) || m$retrieved_on != "2026-10-31" ||
      as.numeric(m$bytes) != file.info(p)$size ||
      tolower(m$sha256) != expected[[f]] || sha256_file(p) != expected[[f]]) {
    stop("Cached SEDAR 79 source differs from the pinned manifest: ", f, call. = FALSE)
  }
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached SEDAR 79 report.", call. = FALSE)
}
pdf <- file.path(cache, "SEDAR79_final_SAR.pdf")
pages <- pdftools::pdf_text(pdf)
layout <- pdftools::pdf_data(pdf)
number <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x), fixed = TRUE)))

annual_rows <- function(page_ids, years, n_values, start = NULL, stop = NULL) {
  rows <- list()
  for (page_id in page_ids) {
    lines <- strsplit(pages[[page_id]], "\n", fixed = TRUE)[[1L]]
    if (!is.null(start) && page_id == page_ids[[1L]]) {
      at <- grep(start, lines, fixed = TRUE)
      if (length(at) != 1L) stop("Missing table heading: ", start, call. = FALSE)
      lines <- lines[(at[[1L]] + 1L):length(lines)]
    }
    if (!is.null(stop)) {
      at <- grep(stop, lines, fixed = TRUE)
      if (length(at)) lines <- lines[seq_len(at[[1L]] - 1L)]
    }
    for (line in lines) {
      m <- regmatches(line, regexec("^[[:space:]]*([0-9]{4})[[:space:]]+(.*)$",
        line, perl = TRUE))[[1L]]
      if (!length(m)) next
      year <- as.integer(m[[2L]])
      if (!year %in% years) next
      value <- number(strsplit(trimws(m[[3L]]), "[[:space:]]+")[[1L]])
      if (length(value) != n_values || any(!is.finite(value))) {
        stop("Bad annual row for ", year, " in table starting ", start, ".", call. = FALSE)
      }
      rows[[length(rows) + 1L]] <- c(year = year, value)
    }
  }
  if (!length(rows)) stop("No annual table rows parsed for ", start, ".", call. = FALSE)
  x <- as.data.frame(do.call(rbind, rows))
  names(x) <- c("year", paste0("v", seq_len(n_values)))
  x <- x[order(x$year), , drop = FALSE]
  if (anyDuplicated(x$year) || !identical(as.integer(x$year), years)) {
    stop("Annual table years are incomplete or duplicated for ", start, ".", call. = FALSE)
  }
  rownames(x) <- NULL
  x
}

# Table 2 spans two pages; Table 3 starts after the Table 2 rows on page 291.
lines290 <- strsplit(pages[[290L]], "\n", fixed = TRUE)[[1L]]
at <- grep("Table 2.", lines290, fixed = TRUE)
if (length(at) != 1L) stop("SEDAR 79 Table 2 heading not found.", call. = FALSE)
lines290 <- lines290[(at[[1L]] + 1L):length(lines290)]
lines291 <- strsplit(pages[[291L]], "\n", fixed = TRUE)[[1L]]
at <- grep("Table 3.", lines291, fixed = TRUE)
if (length(at) != 1L) stop("SEDAR 79 Table 3 boundary not found.", call. = FALSE)
lines291 <- lines291[seq_len(at[[1L]] - 1L)]
rows2 <- list()
for (line in c(lines290, lines291)) {
  m <- regmatches(line, regexec("^[[:space:]]*([0-9]{4})[[:space:]]+(.*)$",
    line, perl = TRUE))[[1L]]
  if (!length(m)) next
  year <- as.integer(m[[2L]])
  if (!year %in% 1981:2023) next
  vals <- number(strsplit(trimws(m[[3L]]), "[[:space:]]+")[[1L]])
  expected_count <- if (year < 1993L) 4L else 6L
  if (length(vals) != expected_count || any(!is.finite(vals))) {
    stop("Bad Table 2 values for ", year, ".", call. = FALSE)
  }
  row <- rep(NA_real_, 6L)
  row[seq_along(vals)] <- vals
  rows2[[length(rows2) + 1L]] <- c(year = year, row)
}
table2 <- as.data.frame(do.call(rbind, rows2))
names(table2) <- c("year", "ll_landings", "ll_log_sd", "other_landings",
  "other_log_sd", "other_releases", "other_release_se")
table2 <- table2[order(table2$year), , drop = FALSE]
if (anyDuplicated(table2$year) || !identical(as.integer(table2$year), 1981:2023)) {
  stop("SEDAR 79 Table 2 is incomplete or duplicated.", call. = FALSE)
}
rownames(table2) <- NULL

layout_table <- function(page_id, years, year_x, value_x,
                         year_tolerance = 18, value_tolerance = 22) {
  p <- as.data.frame(layout[[page_id]])
  p <- p[is.finite(p$x) & is.finite(p$y), , drop = FALSE]
  year <- suppressWarnings(as.integer(as.character(p$text)))
  iy <- which(!is.na(year) & year %in% years & abs(p$x - year_x) <= year_tolerance)
  rows <- lapply(iy, function(i) {
    line <- p[abs(p$y - p$y[[i]]) < 0.8, , drop = FALSE]
    val <- vapply(value_x, function(x) {
      ok <- grepl("^[0-9][0-9,]*(\\.[0-9]+)?\\*?$", line$text) &
        abs(line$x - x) <= value_tolerance
      j <- which(ok)
      if (!length(j)) return(NA_real_)
      number(line$text[j[[which.min(abs(line$x[j] - x))]]])
    }, numeric(1L))
    c(year = year[[i]], val)
  })
  if (!length(rows)) stop("No year rows in PDF page ", page_id, ".", call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows))
  names(out) <- c("year", paste0("v", seq_along(value_x)))
  if (anyDuplicated(out$year)) stop("Duplicate year labels on page ", page_id, ".", call. = FALSE)
  out[order(out$year), , drop = FALSE]
}
table8 <- rbind(
  layout_table(298L, 1981:2008, 84, c(130, 189, 230, 289, 356, 409, 470, 529)),
  layout_table(299L, 2009:2023, 84, c(130, 189, 230, 289, 356, 409, 470, 529))
)
names(table8) <- c("year", "east_landings", "east_landings_log_sd",
  "east_releases", "east_releases_log_sd", "west_landings",
  "west_landings_log_sd", "west_releases", "west_releases_log_sd")
table8 <- table8[order(table8$year), , drop = FALSE]
if (anyDuplicated(table8$year) || !identical(as.integer(table8$year), 1981:2023)) {
  stop("SEDAR 79 Table 8 is incomplete or duplicated.", call. = FALSE)
}
for (x in c("east_landings", "east_releases", "west_landings", "west_releases")) {
  if (any(is.na(table8[[x]]) != is.na(table8[[paste0(x, "_log_sd")]]))) {
    stop("Table 8 value and log-SE cells do not align for ", x, ".", call. = FALSE)
  }
}

specs <- list(
  list(page=300L, name="Commercial Longline CPUE", year=80, n=120, index=192, cv=229, rec=FALSE),
  list(page=300L, name="GOM Combined Stereo Video", year=80, n=270, index=338, cv=373, rec=FALSE),
  list(page=300L, name="RVC Dry Tortugas", year=80, n=412, index=485, cv=520, rec=FALSE),
  list(page=301L, name="RVC Florida Keys", year=80, n=120, index=193, cv=228, rec=FALSE),
  list(page=301L, name="RVC Southeast Florida", year=80, n=266, index=342, cv=377, rec=FALSE),
  list(page=301L, name="Indian River YOY", year=80, n=421, index=491, cv=526, rec=TRUE),
  list(page=302L, name="SERFS Video", year=199, n=249, index=341, cv=392, rec=FALSE)
)
index_data <- lapply(specs, function(s) {
  x <- layout_table(s$page, 1993:2023, s$year, c(s$n, s$index, s$cv))
  names(x) <- c("year", "sample_size", "index", "cv")
  x <- x[!is.na(x$index), , drop=FALSE]
  x$survey <- s$name
  x$recruitment <- s$rec
  if (!nrow(x) || any(!is.finite(x$sample_size)) || any(x$sample_size < 0) ||
      any(!is.finite(x$cv)) || any(x$cv <= 0)) {
    stop("Table 9 index/CV/sample-size fields do not align for ", s$name, ".", call. = FALSE)
  }
  x
})
index_data <- do.call(rbind, index_data)
if (length(unique(index_data$survey)) != 7L ||
    anyDuplicated(paste(index_data$survey, index_data$year, sep="\r"))) {
  stop("SEDAR 79 Table 9 did not produce seven unique series.", call. = FALSE)
}
rownames(index_data) <- NULL

rows11 <- list()
for (page_id in 304:305) {
  for (line in strsplit(pages[[page_id]], "\n", fixed=TRUE)[[1L]]) {
    token <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (length(token) != 8L) next
    vals <- number(token)
    if (any(!is.finite(vals)) || vals[[1L]] != as.integer(vals[[1L]]) ||
        !vals[[1L]] %in% 1:40) next
    rows11[[length(rows11)+1L]] <- vals
  }
}
table11 <- as.data.frame(do.call(rbind, rows11))
names(table11) <- c("age","max_tl","M","maturity","dw_max_tl","dw_M",
  "dw_M_using_ss_growth","dw_maturity")
table11$age <- as.integer(table11$age)
table11 <- table11[order(table11$age), , drop=FALSE]
if (!identical(table11$age, 1:40) || anyDuplicated(table11$age)) {
  stop("SEDAR 79 Table 11 must contain ages 1-40 once each.", call. = FALSE)
}
table15 <- annual_rows(312:313, 1981:2023, 5L, start="Table 15.")
names(table15) <- c("year","commercial_longline","commercial_other",
  "recreational_west","recreational_east","age3_total_F")
table16 <- annual_rows(314:315, 1981:2023, 7L, start="Table 16.")
names(table16) <- c("year","total_biomass_mt","total_biomass_lb","ssb_mt",
  "ssb_lb","total_numbers","recruitment_age1","ssb_ratio")

stocks <- read.csv(file.path(root,"database/stocks.csv"), stringsAsFactors=FALSE,
  na.strings=c("","NA"))
assessments <- read.csv(file.path(root,"database/assessments.csv"), stringsAsFactors=FALSE,
  na.strings=c("","NA"))
if (any(stocks$stock_id==stock_id,na.rm=TRUE) ||
    any(tolower(stocks$authority_stock_id)=="11342",na.rm=TRUE) ||
    any(assessments$assessment_id==assessment_id,na.rm=TRUE)) {
  stop("Mutton Snapper stock or assessment already exists.",call.=FALSE)
}
blank_row <- function(fields, values) {
  row <- as.list(rep("",length(fields))); names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row,check.names=FALSE,stringsAsFactors=FALSE)
}
stock <- blank_row(names(read.csv(file.path(root,"database/stocks.csv"),nrows=0L,
  check.names=FALSE)),list(
  stock_id=stock_id,authority="NOAA Fisheries",authority_stock_id="11342",
  scientific_name="Lutjanus analis",common_name="Southeastern U.S. Mutton Snapper",
  area="South Atlantic and Gulf of Mexico council jurisdictions",
  region="Southeastern United States",ocean="Northwest Atlantic",
  notes="One combined assessment unit spanning Gulf of Mexico and South Atlantic council jurisdictions; the Caribbean is a separate population boundary."
))
assessment <- blank_row(names(read.csv(file.path(root,"database/assessments.csv"),
  nrows=0L,check.names=FALSE)),list(
  assessment_id=assessment_id,stock_id=stock_id,assessment_year=2024L,
  terminal_year=2023L,estimate_terminal_year=2023L,
  assessment_type="full_assessment",model_family="Stock Synthesis",
  model_version="3.30.22.1",is_current=TRUE,is_applied=TRUE,framework_year=2024L,
  assessment_url=report_url,data_url=project_url,
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="SEDAR 79 final base model with observations through 2023. Recovered annual catches/releases, aggregate indices, model biology surfaces, apical F and population outputs. Numeric fleet-year length and conditional age-at-length arrays and age-specific abundance indices were not recovered; no catch-at-age observations are represented."
))
candidate_path <- file.path(root,"discovery/candidates.csv")
inventory_path <- file.path(root,"discovery/inventory_units.csv")
candidates <- read.csv(candidate_path,stringsAsFactors=FALSE,na.strings=c("","NA"),
  colClasses="character",check.names=FALSE)
inventory <- read.csv(inventory_path,stringsAsFactors=FALSE,na.strings=c("","NA"),
  colClasses="character",check.names=FALSE)
ci <- which(candidates$candidate_id==candidate_id)
ii <- candidate_inventory_row(inventory,candidate_id,stock_id)
matched_stock <- candidates$matched_stock_id[ci]
matched_conflict <- length(matched_stock)==1L && !is.na(matched_stock) &&
  nzchar(matched_stock) && matched_stock!=stock_id
if (length(ci)!=1L || candidates$eligibility[ci]!="eligible" ||
    !candidates$import_status[ci] %in% c("not_started","partial") ||
    matched_conflict) {
  stop("NOAA:11342 candidate status or identity changed.",call.=FALSE)
}

in_rows <- list(); out_rows <- list(); assumption_rows <- list()
add_input <- function(...) {
  x<-list(...); x$assessment_id<-assessment_id
  if(is.null(x$region)) x$region<-"Southeastern United States"
  if(is.null(x$source_type)) x$source_type<-"official_table"
  in_rows[[length(in_rows)+1L]]<<-do.call(pacific_database_row,c(list(table="inputs"),x))
}
add_output <- function(...) {
  x<-list(...); x$assessment_id<-assessment_id
  if(is.null(x$region)) x$region<-"Southeastern United States"
  if(is.null(x$source_type)) x$source_type<-"official_table"
  out_rows[[length(out_rows)+1L]]<<-do.call(pacific_database_row,c(list(table="outputs"),x))
}
add_assumption <- function(component,setting,value,source_reference,notes="") {
  assumption_rows[[length(assumption_rows)+1L]]<<-pacific_database_row(
    "assumptions",assessment_id=assessment_id,component=component,
    region="Southeastern United States",setting=setting,value=value,
    source_reference=source_reference,notes=notes)
}
catch_row <- function(year,value,fleet,measure,basis,unit,ref,notes,partition) {
  add_input(type="catch",measure=measure,basis=basis,fleet=fleet,year=year,
    year_basis="calendar_year",season="annual",value=value,unit=unit,
    partition=partition,source_reference=ref,notes=notes)
}
catch_sd <- function(year,value,fleet,ref,notes,partition) {
  add_input(type="catch",measure="log_catch_sd",basis="log_scale",fleet=fleet,
    year=year,year_basis="calendar_year",season="annual",value=value,
    partition=partition,unit="log-scale standard error",source_reference=ref,notes=notes)
}
for (fleet in c("Commercial Longline","Commercial Other")) {
  val<-if(fleet=="Commercial Longline") table2$ll_landings else table2$other_landings
  sd<-if(fleet=="Commercial Longline") table2$ll_log_sd else table2$other_log_sd
  catch_row(table2$year,val,fleet,"landings_biomass","biomass",
    "metric tons whole weight","SEDAR79_final_SAR.pdf, Section III, Table 2",
    "Annual commercial landings by fleet in metric tons whole weight.",partition="landings")
  catch_sd(table2$year,sd,fleet,"SEDAR79_final_SAR.pdf, Section III, Table 2",
    "Source log-scale standard error for commercial landings.",partition="landings")
}
rel<-table2[!is.na(table2$other_releases),,drop=FALSE]
catch_row(rel$year,rel$other_releases,"Commercial Other","discard_numbers",
  "numbers","thousand fish","SEDAR79_final_SAR.pdf, Section III, Table 2",
  "Commercial Other releases in thousands of fish; not reported before 1993.",partition="releases")
add_input(type="catch",measure="catch_se",basis="native_scale",
  fleet="Commercial Other",season="annual",year=rel$year,year_basis="calendar_year",
  value=rel$other_release_se,unit="thousand fish",partition="releases",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 2",
  notes="Absolute standard error for Commercial Other release numbers, on the source scale.")
for (area in c("East","West")) {
  for (kind in c("landings","releases")) {
    name<-paste0(tolower(area),"_",kind); sd_name<-paste0(name,"_log_sd")
    x<-table8[!is.na(table8[[name]]),,drop=FALSE]; fleet<-paste("Recreational",area)
    catch_row(x$year,x[[name]],fleet,if(kind=="landings") "landings_numbers" else
      "discard_numbers","numbers","thousand fish",
      "SEDAR79_final_SAR.pdf, Section III, Table 8",
      paste("Annual recreational",kind,"for",area,"in thousands of fish; log-SE is retained separately."),partition=kind)
    catch_sd(x$year,x[[sd_name]],fleet,"SEDAR79_final_SAR.pdf, Section III, Table 8",
      paste("Source log-scale standard error for recreational",kind,"in",area,"."),partition=kind)
  }
}
for (s in specs) {
  x<-index_data[index_data$survey==s$name,,drop=FALSE]
  measure<-if(s$rec) "recruitment_index" else "relative_abundance_index"
  cv_measure<-if(s$rec) "recruitment_index_cv" else "abundance_index_cv"
  add_input(type="index",measure=measure,basis="index_scale",survey=s$name,
    season="annual",year=x$year,year_basis="calendar_year",
    age=if(s$rec) 0L else NA_integer_,value=x$index,
    unit=if(s$rec) "mean-scaled age-0 relative abundance index" else
      "mean-scaled relative abundance index",sample_size=x$sample_size,
    source_reference="SEDAR79_final_SAR.pdf, Section III, Table 9",
    notes=if(s$rec) "Age-0 YOY recruitment index; Table 9 scales this series to a mean of one. The report advances YOY observations to age 1 at the next January 1; reported age-0 values are retained." else
      "Aggregate index scaled to a mean of one; Table 9 reports CV and sample size. No age-specific survey index is supplied.")
  add_input(type="index",measure=cv_measure,basis="relative_scale",
    survey=s$name,season="annual",year=x$year,year_basis="calendar_year",
    value=x$cv,unit="ratio (SE/mean)",
    source_reference="SEDAR79_final_SAR.pdf, Section III, Table 9",
    notes="Coefficient of variation reported as standard error divided by mean.")
}
for (col in c("commercial_longline","commercial_other","recreational_west","recreational_east")) {
  fleet<-switch(col,commercial_longline="Commercial Longline",
    commercial_other="Commercial Other",recreational_west="Recreational West",
    recreational_east="Recreational East")
  add_output(type="mortality",measure="apical_F",fleet=fleet,season="annual",
    year=table15$year,value=table15[[col]],unit="year^-1",
    source_reference="SEDAR79_final_SAR.pdf, Section III, Table 15",
    notes="Official fleet-specific apical F rounded to two decimals; uncertainty is not tabulated.")
}
add_output(type="mortality",measure="fishing_mortality_at_age",age=3L,
  season="annual",year=table15$year,value=table15$age3_total_F,unit="year^-1",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 15",
  notes="Total instantaneous F at age 3, combined across fleets; rounded to two decimals.")
add_output(type="biomass",measure="total_biomass",season="annual",
  year=table16$year,value=table16$total_biomass_mt,unit="metric tons",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 16",
  notes="Official predicted total biomass; pounds are also reported. No annual uncertainty is tabulated.")
add_output(type="biomass",measure="SSB",season="annual",year=table16$year,
  value=table16$ssb_mt,unit="metric tons",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 16",
  notes="Official predicted SSB; pounds are also reported. No annual uncertainty is tabulated.")
add_output(type="population",measure="total_numbers",season="annual",
  year=table16$year,value=table16$total_numbers,unit="thousand fish",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 16",
  notes="Official predicted abundance of all modeled ages; uncertainty is not tabulated.")
add_output(type="recruitment",measure="recruitment",season="annual",year=table16$year,
  age=1L,value=table16$recruitment_age1,unit="thousand fish",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 16",
  notes="Official predicted age-1 recruitment; uncertainty is not tabulated.")
add_output(type="population",measure="SSB_ratio_to_SSB0",season="annual",
  year=table16$year,value=table16$ssb_ratio,unit="ratio",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 16",
  notes="Official SSB/SSB0 depletion ratio; uncertainty is not tabulated.")
add_output(type="biology",measure="growth_length_at_age",age=table11$age,
  value=table11$max_tl,unit="cm maximum total length",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 11",
  notes="Model-output maximum total length at age, not a catch/survey mean length.")
add_output(type="mortality",measure="natural_mortality_at_age",age=table11$age,
  value=table11$M,unit="year^-1",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 11",
  notes="Model-calculated static age-specific M from fixed reference M and growth.")
add_output(type="biology",measure="maturity_at_age",age=table11$age,
  value=table11$maturity,unit="proportion",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Table 11",
  notes="Model-calculated maturity-at-age from fixed parameters in Table 10.")
add_output(type="biology",measure="weight_at_age",age=table11$age,
  value=6.63e-06*table11$max_tl^3.1601,unit="kg per fish",
  source_type="derived_source_output",
  source_reference="SEDAR79_final_SAR.pdf, Section III, Tables 10-11",
  notes="Derived as 6.63e-06*MaxTL^3.1601 (kg, cm) from fixed Table 10 relation and Table 11 model length; not separately tabulated.")

add_assumption("assessment","run_identity",
  "SEDAR 79 final base model, completed in 2024 with data through 2023; Stock Synthesis 3.30.22.1.",
  "SEDAR79_final_SAR.pdf, cover and Sections III-IV",
  "Joint Gulf and South Atlantic SSC review in March 2025 found the assessment consistent with best scientific information.")
add_assumption("model","model_structure",
  "One combined Southeastern U.S. population, ages 1-40, sexes combined, one area and one annual season.",
  "SEDAR79_final_SAR.pdf, Section III, Tables 10-12",
  "Gulf and South Atlantic council areas form one assessment unit; the Caribbean is separate.")
add_assumption("catch","annual_catch_inputs",
  "Commercial Longline and Commercial Other landings biomass; Commercial Other releases; recreational East/West landings and releases.",
  "SEDAR79_final_SAR.pdf, Section III, Tables 2 and 8",
  "Landings biomass is metric tons whole weight; numbers are thousands of fish. These are aggregate observations, not catch-at-age.")
add_assumption("composition","age_and_length_observations",
  "The production model uses catch-weighted length compositions and conditional age-at-length by fleet and year.",
  "SEDAR79_final_SAR.pdf, Section III, Figures 9-12 and 17; SEDAR79_DW03_size_age.pdf",
  "Numeric matrices and run-matched Stock Synthesis data/control files were not recovered; figure values are not digitized.")
add_assumption("index","accepted_index_series",
  paste(vapply(specs,function(x) x$name,character(1L)),collapse="; "),
  "SEDAR79_final_SAR.pdf, Section III, Table 9",
  "Seven mean-scaled series with CV/sample size: six aggregate abundance indices and one age-0 recruitment index. No age-specific abundance index is supplied.")
add_assumption("timing","spawning_and_recruitment",
  "Spawning peaks in June; settlement is assigned to January.",
  "SEDAR79_final_SAR.pdf, Section III, Tables 10-11",
  "Table 9 does not establish one common sampling fraction; sampling_time is left blank.")
add_assumption("biology","growth_and_weight",
  "Estimated growth uses Lmin=27.65 cm, Linf=82.26 cm, Amin=0 years and k=0.195; fixed whole-weight relation ww=6.63e-06*MaxTL^3.1601 (kg, cm).",
  "SEDAR79_final_SAR.pdf, Section III, Table 10",
  "Table 11 model-output maximum length supports the separately labeled derived weight-at-age surface.")
add_assumption("biology","maturity",
  "Fixed maturity parameters A50=3.48 years, alpha=-2.535, beta=-13.021; fixed female fraction=0.5.",
  "SEDAR79_final_SAR.pdf, Section III, Table 10",
  "Table 12 rounds A50 to 3.500; Table 10 gives the fixed input value 3.48. Table 11 reports model-calculated maturity.")
add_assumption("mortality","natural_mortality",
  "Fixed reference M=0.129 year^-1, calculated as 5.4/tmax and scaled by age through the growth relationship.",
  "SEDAR79_final_SAR.pdf, Section III, Tables 10-11",
  "Table 11 reports the model-calculated static M-at-age surface.")
add_assumption("output","reported_outputs_and_uncertainty",
  "Table 16 reports biomass, SSB, total abundance, age-1 recruitment and SSB/SSB0 for 1981-2023; Table 15 reports four fleet apical-F series and F at age 3; Table 11 reports age-specific length, M and maturity.",
  "SEDAR79_final_SAR.pdf, Section III, Tables 11, 15 and 16",
  "Tables provide rounded point estimates but no annual or age-specific uncertainty. Derived weight-at-age has no uncertainty.")
add_assumption("data_limitations","unavailable_model_arrays",
  "Numeric conditional age-at-length and length-composition arrays, annual age-specific survey indices, and age-specific N-at-age/F-at-age tables were not recovered.",
  "SEDAR79_final_SAR.pdf, Section III, Figures 9-17 and Tables 9, 15-16",
  "Figures are not digitized; missing inputs and uncertainty are not invented.")

inputs_new<-do.call(rbind,in_rows); outputs_new<-do.call(rbind,out_rows)
assumptions_new<-do.call(rbind,assumption_rows)
if(any(!is.finite(inputs_new$value)) || any(!is.finite(outputs_new$value)) ||
   any(!nzchar(inputs_new$source_reference)) || any(!nzchar(outputs_new$source_reference))) {
  stop("Non-finite value or missing provenance in mutton snapper import.",call.=FALSE)
}
cat("Prepared ",nrow(inputs_new)," inputs, ",nrow(assumptions_new),
  " assumptions, and ",nrow(outputs_new)," outputs.\n",sep="")
cat("No catch-at-age or numeric CAAL/length-composition arrays were reconstructed.\n")
if(write_mode) {
  append_pacific_case(stock,assessment,assumptions_new,inputs_new,outputs_new)
  update<-candidates[ci,,drop=FALSE]
  update$matched_stock_id<-stock_id; update$match_status<-"new"; update$import_status<-"partial"
  update$catch_age_evidence<-"SEDAR 79 fits catch-weighted length compositions and conditional age-at-length, not marginal catch-at-age. Tables 2 and 8 provide annual catches/releases; exact fleet-year composition arrays were not recovered."
  update$survey_age_evidence<-"Table 9 includes six aggregate abundance indices and one age-0 recruitment index, with CV and sample size. No annual age-specific abundance index was recovered."
  update$weights_evidence<-"Table 10 provides a fixed weight-length relationship; Table 11 maximum total length supports a separately labeled derived weight-at-age surface."
  update$maturity_evidence<-"Table 10 provides fixed maturity parameters and female fraction; Table 11 reports model-calculated maturity-at-age."
  update$mortality_evidence<-"M reference rate 0.129 year^-1 is fixed and age-scaled through growth; model-calculated age-specific M is reported in Table 11."
  update$timing_evidence<-"Spawning peaks in June and settlement is assigned to January. Index timing fractions are not established in Table 9."
  update$output_evidence<-"Imported Table 16 annual biomass, SSB, total numbers, age-1 recruitment and depletion; Table 15 fleet apical F/F-at-age-3; Table 11 age-specific length, M and maturity. No uncertainty is tabulated."
  update$detailed_source_url<-paste(project_url,report_url,
    "https://sedarweb.org/documents/sedar-79-dw-03-size-and-age-information-for-mutton-snapper-lutjanus-analis-collected-in-association-with-fishery-dependent-monitoring-along-floridas-coast/",
    "https://sedarweb.org/documents/sedar-79-dw-12-mutton-snapper-reproduction/",
    "https://sedarweb.org/documents/sedar-79-dw-22-descriptions-of-age-growth-and-natural-mortality-of-mutton-snapper-lutjanus-analis-collected-from-fisheries-independent-and-dependent-sources-in-the-southeastern-united-states-fro/",
    "https://sedarweb.org/documents/gulf-and-sa-ssc-review-of-sedar-79-southeastern-u-s-mutton-snapper/",sep="; ")
  update$review_date<-"2026-11-12"
  update$decision_reason<-"Partial source import completed from the latest detailed SEDAR production report. Numeric age-at-length/length-composition matrices remain unavailable."
  update$notes<-"Canonical records preserve reported units and distinguish official tables from derived weight-at-age. No catch-at-age, age-specific index or digitized figure values were invented."
  inv_update<-inventory[ii,,drop=FALSE]
  inv_update$matched_stock_id<-stock_id; inv_update$match_status<-"new"; inv_update$import_status<-"partial"
  replace_candidate_register_row(candidate_path,ci,update,candidate_id)
  replace_csv_register_row(inventory_path,ii,inv_update,"unit_key",inventory$unit_key[ii])
  source(file.path(root,"scripts/database/002_validate_database.R"),
    local=new.env(parent=globalenv()))
  cat("Mutton Snapper records appended and full database validation passed.\n")
}
