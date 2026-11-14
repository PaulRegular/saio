assessment_id <- "noaa_yellowtail_rockfish_north_2025"
stock_id <- "noaa_yellowtail_rockfish_north"
read_table <- function(name) read.csv(file.path("database",name),stringsAsFactors=FALSE,
  na.strings=c("","NA"),check.names=FALSE)
read_assessment_rows <- function(path,id) {
  con <- base::file(path,open="r");on.exit(close(con))
  header <- readLines(con,n=1L,warn=FALSE);prefix <- paste0('"',id,'"');rows <- character()
  repeat { chunk<-readLines(con,n=50000L,warn=FALSE);if(!length(chunk))break
    rows<-c(rows,chunk[startsWith(chunk,prefix)]) }
  read.csv(text=paste(c(header,rows),collapse="\n"),stringsAsFactors=FALSE,
    na.strings=c("","NA"),check.names=FALSE)
}
stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
stock <- stocks[stocks$stock_id==stock_id,,drop=FALSE]
event <- assessments[assessments$assessment_id==assessment_id,,drop=FALSE]
stopifnot(nrow(stock)==1L,stock$authority=="NOAA-NWFSC",
  stock$authority_stock_id=="10393",stock$scientific_name=="Sebastes flavidus",
  stock$ocean=="Northeast Pacific",nrow(event)==1L,
  event$assessment_year==2025,event$terminal_year==2024,
  event$estimate_terminal_year==2036,event$is_current,event$is_applied,
  event$assessment_url=="https://www.pcouncil.org/documents/2026/01/status-of-the-yellowtail-rockfish-stock-off-the-u-s-west-coast-north-of-40-10-in-2025.pdf/",
  event$model_url=="https://www.pcouncil.org/documents/yellowtail-rockfish-2025-model-files-zip-file/",
  event$inputs_status=="partial",event$outputs_status=="partial")
inputs <- read_assessment_rows("database/inputs.csv",assessment_id)
stopifnot(nrow(inputs)==35293L,
  sum(inputs$measure=="catch_biomass")==408L,
  sum(inputs$measure=="catch_se")==408L,
  sum(inputs$measure %in% c("relative_abundance_index","relative_biomass_index","recruitment_index"))==54L,
  sum(inputs$measure=="recruitment_index" & inputs$survey=="SMURF")==10L,
  sum(inputs$measure=="log_index_sd")==54L,
  sum(inputs$measure=="frequency_at_length")==5719L,
  sum(inputs$measure=="frequency_at_age")==28650L,
  length(unique(inputs$observation_id[inputs$measure=="frequency_at_length"]))==178L,
  length(unique(inputs$observation_id[inputs$measure=="frequency_at_age"]))==855L,
  all(inputs$year[inputs$measure=="catch_biomass"] %in% 1889:2024),
  all(inputs$year[inputs$type=="index"] %in% 1980:2024),
  all(inputs$season[inputs$type=="index"]=="month 7"),
  all(inputs$sampling_time[inputs$type=="index"]==0.5),
  all(inputs$age[inputs$measure=="frequency_at_age"] %in% 1:30),
  all(inputs$length_bin[inputs$measure=="frequency_at_length"] %in% seq(20,56,2)),
  all(inputs$unit[inputs$measure=="catch_biomass"]=="metric tonnes"),
  any(inputs$value[inputs$measure=="catch_biomass" & inputs$year==2024 & inputs$fleet=="Commercial"]==2663.91),
  any(inputs$value[inputs$measure=="relative_abundance_index" & inputs$year==2010 & inputs$survey=="H&L_survey"]==0.00477947),
  any(grepl("negative fleet code",inputs$notes)),
  !any(inputs$measure %in% c("numbers_at_age","weight_at_age","maturity_at_age","natural_mortality_at_age")))
outputs <- read_assessment_rows("database/outputs.csv",assessment_id)
stopifnot(nrow(outputs)==122193L,
  sum(outputs$measure=="total_biomass")==148L,
  sum(outputs$measure=="summary_biomass_age4plus")==148L,
  sum(outputs$measure=="spawning_output")==148L,
  sum(outputs$measure=="recruitment")==148L,
  sum(outputs$measure=="fraction_unfished_spawning_output")==11L,
  sum(outputs$type=="population" & outputs$measure=="numbers_at_age")==12136L,
  sum(outputs$measure=="biomass_at_age")==12136L,
  sum(outputs$measure=="natural_mortality_at_age")==12136L,
  sum(outputs$measure=="fishing_mortality_at_age")==36408L,
  sum(outputs$type=="catch" & outputs$measure=="numbers_at_age")==36408L,
  sum(outputs$measure=="weight_at_age")==12136L,
  sum(outputs$measure=="proportion_mature_at_age")==82L,
  sum(outputs$measure=="total_numbers")==148L,
  all(outputs$year[outputs$measure=="spawning_output"] %in% 1889:2036),
  all(outputs$age[outputs$measure=="numbers_at_age"] %in% 0:40),
  all(is.na(outputs$se[outputs$measure %in% c("numbers_at_age","fishing_mortality_at_age","natural_mortality_at_age","weight_at_age","proportion_mature_at_age")])))
spawn <- outputs[outputs$measure=="spawning_output" & outputs$year==2025,]
rec <- outputs[outputs$measure=="recruitment" & outputs$year==2024,]
stopifnot(nrow(spawn)==1L,spawn$value==9.13025,spawn$lwr==6.23,spawn$upr==12.03,
  nrow(rec)==1L,rec$value==33341,rec$lwr==15127,rec$upr==73488,
  all(outputs$unit[outputs$measure=="spawning_output"]=="trillion eggs"))
n <- outputs[outputs$type=="population" & outputs$measure=="numbers_at_age",c("year","age","sex","value")]
w <- outputs[outputs$measure=="weight_at_age",c("year","age","sex","value")]
b <- outputs[outputs$measure=="biomass_at_age",c("year","age","sex","value")]
nw <- merge(merge(n,w,by=c("year","age","sex"),suffixes=c("_n","_w")),b,
  by=c("year","age","sex"))
stopifnot(nrow(nw)==12136L,max(abs(nw$value_n*nw$value_w-nw$value)/pmax(1,nw$value))<0.02)
total <- aggregate(value~year,n,sum)
stored <- outputs[outputs$measure=="total_numbers",c("year","value")]
stopifnot(isTRUE(all.equal(total[order(total$year),]$value,
  stored[order(stored$year),]$value,tolerance=1e-10)))
assumptions <- read_assessment_rows("database/assumptions.csv",assessment_id)
stopifnot(nrow(assumptions)==10L,any(assumptions$setting=="natural_mortality"),
  any(assumptions$setting=="stock_recruitment_and_deviations"),
  any(assumptions$setting=="reported_intervals"))
candidate <- read.csv("discovery/candidates.csv",stringsAsFactors=FALSE,
  na.strings=c("","NA"),check.names=FALSE)
candidate <- candidate[candidate$candidate_id=="NOAA:10393",]
inventory <- read.csv("discovery/inventory_units.csv",stringsAsFactors=FALSE,
  na.strings=c("","NA"),check.names=FALSE)
inventory <- inventory[inventory$unit_key=="candidate:noaa_stocksmart_10393",]
selected <- read.csv("discovery/selected_batch_10_2026.csv",stringsAsFactors=FALSE,
  na.strings=c("","NA"),check.names=FALSE)
stopifnot(nrow(candidate)==1L,candidate$match_status=="matched",
  candidate$matched_stock_id==stock_id,candidate$import_status=="partial",
  nrow(inventory)==1L,inventory$import_status=="partial",
  nrow(selected)==1L,selected$curation_status=="partial_source_import")
manifest <- read.csv("provenance/noaa_yellowtail_rockfish_north_2025_sources.csv",
  stringsAsFactors=FALSE,check.names=FALSE)
stopifnot(nrow(manifest)==8L,all(nzchar(manifest$source_url)),
  manifest$source_url[1L]=="https://www.pcouncil.org/documents/2026/01/status-of-the-yellowtail-rockfish-stock-off-the-u-s-west-coast-north-of-40-10-in-2025.pdf/",
  manifest$source_url[2L]=="https://www.pcouncil.org/documents/yellowtail-rockfish-2025-model-files-zip-file/")
for(j in seq_len(nrow(manifest))) {
  path <- file.path("source_cache",manifest$local_file[j])
  hash <- system2("certutil.exe",c("-hashfile",shQuote(path),"SHA256"),stdout=TRUE,stderr=FALSE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",hash,value=TRUE)))
  stopifnot(file.exists(path),file.info(path)$size==manifest$bytes[j],
    length(hash)==1L,identical(hash,manifest$sha256[j]))
}
cat("NOAA northern Yellowtail source, database, output, and provenance checks passed.\n")
