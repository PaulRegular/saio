assessment_id <- "noaa_gulf_red_snapper_2026"
source_dir <- "source_cache/discovery_noaa_gom_red_snapper_2026"
manifest <- read.csv("provenance/discovery_noaa_gom_red_snapper_2026/sources.csv",
  stringsAsFactors=FALSE, check.names=FALSE, colClasses="character")
write_mode <- "--write" %in% commandArgs(trailingOnly=TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source("scripts/database/candidate_register_io.R")
sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    x <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout=TRUE, stderr=FALSE)
    x <- toupper(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", x, value=TRUE)))
  } else {
    x <- system2("sha256sum", shQuote(path), stdout=TRUE, stderr=FALSE)
    x <- toupper(strsplit(x, "[[:space:]]+")[[1L]][1L])
  }
  if (length(x) != 1L) stop("Could not hash source file: ", path)
  x
}
verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop=FALSE]
  path <- file.path(source_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256)))
    stop("Cached source differs from manifest: ", name)
  path
}
sar_path <- verify_source("SEDAR98_SAR.pdf")
verify_source("SEDAR98_DW13.pdf")
text_path <- paste0(sar_path, ".txt")
if (!file.exists(text_path)) {
  if (!requireNamespace("pdftools", quietly=TRUE))
    stop("Create a text extraction beside SEDAR98_SAR.pdf before importing.")
  writeLines(pdftools::pdf_text(sar_path), text_path, useBytes=TRUE)
}
lines <- readLines(text_path, warn=FALSE, encoding="UTF-8")
trimmed <- trimws(lines)
heading <- grep("^Table [0-9]+[.]", trimmed)
heading_num <- rep(NA_integer_, length(lines))
heading_num[heading] <- as.integer(sub("[.].*$", "", sub("^Table ", "", trimmed[heading])))
parse_table <- function(n, token_count) {
  starts <- which(heading_num == n)
  if (!length(starts)) stop("Missing SEDAR 98 Table ", n)
  later <- which(seq_along(lines) > starts[1] & !is.na(heading_num) & heading_num != n)
  end <- if (length(later)) min(later)-1L else length(lines)
  section <- lines[starts[1]:end]
  dat <- section[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+[0-9]", section)]
  if (!length(dat)) stop("No numeric rows in SEDAR 98 Table ", n)
  vals <- lapply(dat, function(line) {
    x <- suppressWarnings(as.numeric(gsub(",", "", strsplit(trimws(line), "[[:space:]]+")[[1]], fixed=TRUE)))
    if (length(x) != token_count || any(!is.finite(x))) stop("Bad row in Table ", n, ": ", line)
    x
  })
  out <- do.call(rbind, vals)
  if (anyDuplicated(out[,1])) {
    repeated <- unique(out[duplicated(out[,1]),1])
    for (yr in repeated) {
      rows <- out[out[,1] == yr,,drop=FALSE]
      if (nrow(unique(as.data.frame(rows))) > 1L) stop("Conflicting repeated year in Table ", n)
    }
    out <- out[!duplicated(out[,1]),,drop=FALSE]
  }
  out
}
input_columns <- c("assessment_id","type","measure","basis","fleet","survey","sex",
  "region","season","year","year_basis","age","value","unit","sampling_time",
  "source_type","source_reference","transformation","notes","observation_id",
  "length_bin","length_bin_lower","length_bin_upper","sample_size","age_error",
  "partition","weight_bin")
output_columns <- c("assessment_id","type","measure","fleet","survey","sex","region",
  "season","year","age","age_group","value","se","lwr","upr","unit",
  "source_type","source_reference","notes","scenario")
fmt <- function(x) {
  if (is.null(x) || !length(x) || is.na(x) || !nzchar(as.character(x))) return("")
  if (is.numeric(x)) return(format(x, scientific=FALSE, trim=TRUE, digits=15))
  as.character(x)
}
make_row <- function(cols, values) {
  row <- as.list(rep("", length(cols))); names(row) <- cols
  for (nm in names(values)) row[[nm]] <- fmt(values[[nm]])
  as.data.frame(row, stringsAsFactors=FALSE, check.names=FALSE)
}
input_row <- function(type, measure, basis, value, unit, ref, notes, year,
                      fleet="", survey="", region="", partition="") {
  make_row(input_columns, list(assessment_id=assessment_id, type=type,
    measure=measure, basis=basis, fleet=fleet, survey=survey, region=region,
    year=as.integer(year), year_basis="calendar_year", value=value, unit=unit,
    source_type="official_table", source_reference=ref, notes=notes,
    partition=partition))
}
output_row <- function(type, measure, value, unit, ref, notes, year,
                       fleet="", survey="", region="", season="") {
  make_row(output_columns, list(assessment_id=assessment_id, type=type,
    measure=measure, value=value, unit=unit, source_type="official_table",
    source_reference=ref, notes=notes, year=as.integer(year), fleet=fleet,
    survey=survey, region=region, season=season))
}
in_rows <- list(); out_rows <- list()
add_in <- function(...) in_rows[[length(in_rows)+1L]] <<- input_row(...)
add_out <- function(...) out_rows[[length(out_rows)+1L]] <<- output_row(...)
landings_map <- data.frame(
  table=23:37,
  fleet=c(rep("Commercial Handline",3), rep("Commercial Longline",3),
    rep("Recreational Private",3), rep("Recreational Charter",3),
    rep("Recreational Headboat",3)),
  region=rep(c("West","Central","East"),5),
  expected=c(74L,74L,74L,44L,36L,33L,74L,74L,74L,74L,74L,28L,74L,74L,74L),
  stringsAsFactors=FALSE
)
for (i in seq_len(nrow(landings_map))) {
  tab <- landings_map$table[i]; fleet <- landings_map$fleet[i]
  region <- landings_map$region[i]; x <- parse_table(tab,6L)
  if (nrow(x) != landings_map$expected[i]) stop("Unexpected Table ",tab," coverage.")
  ref <- paste0("SEDAR98_SAR.pdf, Table ",tab)
  for (j in seq_len(nrow(x))) {
    yr <- x[j,1]
    base_note <- "Final assessment model-scale input, distinct from source-native catch rows."
    if (tab <= 28L) {
      add_in("catch","landings_biomass","biomass",x[j,3],"million pounds whole weight",ref,
        paste(base_note,"The table reports its log-scale standard error."),yr,fleet=fleet,region=region,partition="landings")
      add_in("catch","log_catch_sd","log_scale",x[j,2],"log scale SD",ref,
        "Log-scale standard error paired with the final assessment landings input.",yr,fleet=fleet,region=region,partition="landings")
      add_out("catch","expected_landings_biomass",x[j,4],"million pounds whole weight",ref,
        "Expected landings biomass reported by the fitted assessment.",yr,fleet=fleet,region=region)
      add_out("catch","expected_landings_numbers",x[j,5],"thousand fish",ref,
        "Expected landings numbers reported by the fitted assessment.",yr,fleet=fleet,region=region)
    } else {
      add_in("catch","landings_numbers","numbers",x[j,3],"thousand fish",ref,
        paste(base_note,"The table reports its log-scale standard error."),yr,fleet=fleet,region=region,partition="landings")
      add_in("catch","log_catch_sd","log_scale",x[j,2],"log scale SD",ref,
        "Log-scale standard error paired with the final assessment landings input.",yr,fleet=fleet,region=region,partition="landings")
      add_out("catch","expected_landings_numbers",x[j,4],"thousand fish",ref,
        "Expected landings numbers reported by the fitted assessment.",yr,fleet=fleet,region=region)
      add_out("catch","expected_landings_biomass",x[j,5],"million pounds whole weight",ref,
        "Expected landings biomass reported by the fitted assessment.",yr,fleet=fleet,region=region)
    }
    add_out("biology","mean_landings_weight",x[j,6],"pounds per fish",ref,
      "Mean body weight reported by the assessment; defined as expected biomass divided by expected numbers.",
      yr,fleet=fleet,region=region)
  }
}

discard_map <- data.frame(
  table=38:58,
  fleet=c(rep("Commercial Handline",3),rep("Commercial Longline",3),
    rep("Commercial Handline",3),rep("Recreational Charter",3),
    rep("Recreational Headboat",3),rep("Recreational Private",6)),
  region=rep(c("West","Central","East"),7),
  partition=c(rep("",6),rep("federal_closed",3),rep("",9),rep("federal_closed",3)),
  expected=c(28L,28L,28L,28L,28L,28L,11L,11L,11L,40L,42L,29L,40L,42L,33L,
    40L,42L,40L,26L,27L,21L),
  stringsAsFactors=FALSE
)
for (i in seq_len(nrow(discard_map))) {
  tab <- discard_map$table[i]; fleet <- discard_map$fleet[i]
  region <- discard_map$region[i]; part <- discard_map$partition[i]
  x <- parse_table(tab,8L)
  if (nrow(x) != discard_map$expected[i]) stop("Unexpected Table ",tab," coverage.")
  ref <- paste0("SEDAR98_SAR.pdf, Table ",tab)
  for (j in seq_len(nrow(x))) {
    yr <- x[j,1]; season <- if(nzchar(part)) "closed_season" else ""; discard_partition <- if(nzchar(part)) part else "discards"
    add_in("catch","discard_numbers","numbers",x[j,3],"thousand fish",ref,
      "Final assessment model-scale discard input; the report separates expected dead discards after mortality.",
      yr,fleet=fleet,region=region,partition=discard_partition)
    add_in("catch","log_catch_sd","log_scale",x[j,2],"log scale SD",ref,
      "Log-scale standard error paired with the final assessment discard input.",
      yr,fleet=fleet,region=region,partition=discard_partition)
    add_out("catch","expected_discard_numbers",x[j,4],"thousand fish",ref,
      "Expected total discard numbers before applying assessment discard mortality.",
      yr,fleet=fleet,region=region,season=season)
    add_out("catch","expected_dead_discard_numbers",x[j,5],"thousand fish",ref,
      "Expected dead discard numbers after applying assessment discard mortality.",
      yr,fleet=fleet,region=region,season=season)
    add_out("catch","expected_discard_biomass",x[j,6],"thousand pounds whole weight",ref,
      "Expected discard biomass reported by the fitted assessment.",yr,fleet=fleet,region=region,season=season)
    add_out("catch","expected_dead_discard_biomass",x[j,7],"thousand pounds whole weight",ref,
      "Expected dead discard biomass after applying assessment discard mortality.",yr,fleet=fleet,region=region,season=season)
    add_out("biology","mean_discard_weight",x[j,8],"pounds per fish",ref,
      "Mean discard weight reported by the fitted assessment.",yr,fleet=fleet,region=region,season=season)
  }
}
index_map <- data.frame(
  table=59:75,
  survey=c("SEAMAP Fall Trawl Pre-2007","SEAMAP Fall Trawl Post-2007",
    "SEAMAP Fall Trawl Post-2007","SEAMAP Fall Trawl Post-2007",
    "SEAMAP Summer Trawl Pre-2007","SEAMAP Summer Trawl Post-2007",
    "SEAMAP Summer Trawl Post-2007","SEAMAP Summer Trawl Post-2007",
    "SEAMAP Larval Survey","SEAMAP Larval Survey",
    "SEFSC Bottom Longline","SEFSC Bottom Longline","SEFSC Bottom Longline",
    "G-FISHER Video Survey","G-FISHER Video Survey","G-FISHER Video Survey",
    "Commercial Handline CPUE"),
  fleet=c(rep("",16),"Commercial Handline"),
  region=c("West","West","Central","East","West","West","Central","East",
    "West","Central","West","Central","East","Central","West","East","East"),
  expected=c(20L,16L,16L,15L,23L,14L,14L,14L,23L,23L,20L,20L,20L,23L,23L,14L,17L),
  stringsAsFactors=FALSE
)
for (i in seq_len(nrow(index_map))) {
  tab <- index_map$table[i]; survey <- paste0("SEDAR 98 final model: ",index_map$survey[i])
  fleet <- index_map$fleet[i]; region <- index_map$region[i]
  x <- parse_table(tab,4L)
  if (nrow(x) != index_map$expected[i]) stop("Unexpected Table ",tab," coverage.")
  ref <- paste0("SEDAR98_SAR.pdf, Table ",tab)
  for (j in seq_len(nrow(x))) {
    yr <- x[j,1]
    add_in("index","relative_abundance_index","index_scale",x[j,2],
      "relative index (time-series mean = 1)",ref,
      "Observed index from the final assessment series, retained on its reported scale.",
      yr,fleet=fleet,survey=survey,region=region)
    add_in("index","log_index_sd","log_scale",x[j,4],"log scale SD",ref,
      "Lognormal standard error reported for the final assessment index input.",
      yr,fleet=fleet,survey=survey,region=region)
    add_out("index","expected_relative_abundance_index",x[j,3],
      "relative index (time-series mean = 1)",ref,
      "Expected index value reported by the fitted assessment.",
      yr,fleet=fleet,survey=survey,region=region)
  }
}

shrimp <- parse_table(99L,4L)
if (nrow(shrimp) != 41L || !identical(as.integer(shrimp[,1]),1983:2023))
  stop("Unexpected year coverage in SEDAR 98 Table 99.")
for (i in seq_len(nrow(shrimp))) for (j in 2:4) {
  region <- c("West","Central","East")[j-1L]
  add_in("catch","catch_numbers","numbers",shrimp[i,j],"thousand fish",
    "SEDAR98_SAR.pdf, Table 99",
    "Reported shrimp-trawl bycatch input by model area; not split into landings/discards or ages.",
    shrimp[i,1],fleet="Shrimp Trawl",region=region)
}
new_inputs <- do.call(rbind,in_rows)
new_outputs <- do.call(rbind,out_rows)
if (nrow(new_inputs) != 3909L || nrow(new_outputs) != 6295L)
  stop("Unexpected parsed row totals: ",nrow(new_inputs)," inputs; ",nrow(new_outputs)," outputs.")

read_assessment_rows <- function(path) {
  prefix <- paste0('"',assessment_id,'",')
  x <- suppressWarnings(system2("rg",c("--color","never","--no-heading",
    "--no-line-number","-F",assessment_id,path),stdout=TRUE,stderr=FALSE))
  status <- attr(x,"status"); if (is.null(status)) status <- 0L
  if (status == 1L) x <- character()
  else if (status != 0L) stop("Could not read rows from ",path)
  x <- x[startsWith(x,prefix)]
  if (!length(x)) return(read.csv(path,nrows=0L,stringsAsFactors=FALSE,check.names=FALSE))
  header <- readLines(path,n=1L,warn=FALSE)
  read.csv(text=paste(c(header,x),collapse="\n"),stringsAsFactors=FALSE,
    na.strings=c("","NA"),check.names=FALSE,colClasses="character")
}
unique_rows <- function(new, old, keys, label) {
  norm <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; x }
  key <- function(x) do.call(paste,c(lapply(x[keys],norm),sep="\r"))
  new_key <- key(new)
  if (anyDuplicated(new_key)) stop("Duplicate parsed ",label," rows.")
  if (!nrow(old)) return(new)
  old_key <- key(old); hit <- match(new_key,old_key)
  for (i in which(!is.na(hit))) {
    a <- norm(new[i,names(new),drop=FALSE])
    b <- norm(old[hit[i],names(new),drop=FALSE])
    if (!identical(as.character(a),as.character(b)))
      stop("Existing ",label," row differs from SEDAR 98 table for key ",new_key[i])
  }
  new[is.na(hit),,drop=FALSE]
}
inputs_path <- "database/inputs.csv"; outputs_path <- "database/outputs.csv"
existing_inputs <- read_assessment_rows(inputs_path)
existing_outputs <- read_assessment_rows(outputs_path)
input_keys <- c("assessment_id","type","measure","basis","fleet","survey","sex",
  "region","season","year","year_basis","age","observation_id","length_bin",
  "length_bin_lower","length_bin_upper","sample_size","age_error","partition","weight_bin")
output_keys <- c("assessment_id","type","measure","fleet","survey","sex","region",
  "season","year","age","age_group","scenario")
missing_inputs <- unique_rows(new_inputs,existing_inputs,input_keys,"input")
missing_outputs <- unique_rows(new_outputs,existing_outputs,output_keys,"output")
if (!write_mode) {
  cat("Dry run: ",nrow(missing_inputs)," new model input rows; ",
    nrow(missing_outputs)," new fitted output rows; ",
    nrow(new_inputs)-nrow(missing_inputs)," existing input rows matched.\n",sep="")
} else {
  if (nrow(missing_inputs)) write.table(missing_inputs,inputs_path,sep=",",
    row.names=FALSE,col.names=FALSE,append=TRUE,na="",qmethod="double")
  if (nrow(missing_outputs)) write.table(missing_outputs,outputs_path,sep=",",
    row.names=FALSE,col.names=FALSE,append=TRUE,na="",qmethod="double")
  cat("Imported ",nrow(missing_inputs)," model input rows and ",
    nrow(missing_outputs)," fitted output rows.\n",sep="")
}
