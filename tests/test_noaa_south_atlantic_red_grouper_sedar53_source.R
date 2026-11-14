stock_id <- "noaa_red_grouper_south_atlantic"
assessment_id <- "noaa_red_grouper_south_atlantic_sedar53_2017"
candidate_id <- "NOAA:10332"
read_rows <- function(path, id) {
  rows <- suppressWarnings(system2("rg", c("--color","never","--no-heading","--no-line-number","-F",id,path), stdout=TRUE, stderr=FALSE))
  status <- attr(rows,"status"); if(is.null(status)) status <- 0L
  if(status==1L) return(data.frame()); if(status!=0L) stop("rg failed for ",path)
  rows <- rows[startsWith(rows,paste0('"',id,'",'))]
  header <- names(read.csv(path,nrows=0,check.names=FALSE))
  read.csv(text=paste(rows,collapse="\n"),header=FALSE,col.names=header,na.strings=c("","NA"),check.names=FALSE)
}
stock <- read.csv("database/stocks.csv",na.strings=c("","NA"),check.names=FALSE)
assessment <- read.csv("database/assessments.csv",na.strings=c("","NA"),check.names=FALSE)
inputs <- read_rows("database/inputs.csv",assessment_id)
outputs <- read_rows("database/outputs.csv",assessment_id)
assumptions <- read_rows("database/assumptions.csv",assessment_id)
candidates <- read.csv("discovery/candidates.csv",na.strings=c("","NA"),check.names=FALSE)
manifest <- read.csv("provenance/noaa_red_grouper_sedar53_2017/manifest.csv",check.names=FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_red_grouper_south_atlantic_2017.md"),collapse="\n")
input_value <- function(measure,year=NA_integer_,age=NA_integer_,fleet=NA_character_,survey=NA_character_,sex=NA_character_,partition=NA_character_,obs=NA_character_) {
  k<-inputs$measure==measure
  if(!is.na(year)) k<-k & inputs$year==as.character(year)
  if(!is.na(age)) k<-k & inputs$age==as.character(age)
  if(!is.na(fleet)) k<-k & inputs$fleet==fleet
  if(!is.na(survey)) k<-k & inputs$survey==survey
  if(!is.na(sex)) k<-k & inputs$sex==sex
  if(!is.na(partition)) k<-k & inputs$partition==partition
  if(!is.na(obs)) k<-k & inputs$observation_id==obs
  as.numeric(inputs$value[k])
}
output_value <- function(measure,year=NA_integer_,age=NA_integer_,scenario=NA_character_) {
  k<-outputs$measure==measure
  if(!is.na(year)) k<-k & outputs$year==as.character(year)
  if(!is.na(age)) k<-k & outputs$age==as.character(age)
  if(!is.na(scenario)) k<-k & outputs$scenario==scenario
  as.numeric(outputs$value[k])
}
input_key <- paste(inputs$type,inputs$measure,inputs$fleet,inputs$survey,inputs$sex,inputs$year,inputs$age,inputs$partition,inputs$observation_id,sep="|")
output_key <- paste(outputs$type,outputs$measure,outputs$year,outputs$age,outputs$age_group,outputs$scenario,sep="|")
stopifnot(
  sum(stock$stock_id==stock_id)==1L,
  stock$authority[stock$stock_id==stock_id]=="NOAA Fisheries",
  stock$authority_stock_id[stock$stock_id==stock_id]=="10332",
  stock$scientific_name[stock$stock_id==stock_id]=="Epinephelus morio",
  stock$ocean[stock$stock_id==stock_id]=="Northwest Atlantic",
  sum(assessment$assessment_id==assessment_id)==1L,
  assessment$terminal_year[assessment$assessment_id==assessment_id]==2015,
  assessment$inputs_status[assessment$assessment_id==assessment_id]=="partial",
  assessment$outputs_status[assessment$assessment_id==assessment_id]=="partial",
  nrow(assumptions)==9L,nrow(inputs)==1150L,nrow(outputs)==2275L,
  all(inputs$source_type=="official_table"),all(outputs$source_type=="official_table"),
  !anyDuplicated(input_key),!anyDuplicated(output_key),
  input_value("landings_biomass",1976,fleet="Commercial lines",partition="landings")==263.68,
  length(input_value("discard_numbers",1976,fleet="General recreational",partition="all_releases"))==0L,
  input_value("relative_abundance_index",1996,fleet=NA,survey="Commercial handline index")==0.57,
  input_value("abundance_index_cv",1996,survey="Commercial handline index")==0.07,
  input_value("composition_sample_count",1997,fleet="Commercial handline",obs="Table4_age_composition")==126,
  input_value("composition_sample_count",1997,fleet="Commercial handline",obs="Table5_age_composition")==33,
  input_value("proportion_at_age",1997,age=3,fleet="Commercial lines (handline and longline)")==0.081,
  input_value("natural_mortality_at_age",age=1)==0.299,
  input_value("weight_at_age",age=1)==0.46,
  input_value("maturity_at_age",age=2,sex="female")==0.35,
  input_value("maturity_at_age",age=1,sex="male")==1,
  output_value("numbers_at_age",1976,1)==508.18,
  output_value("total_numbers",2016,scenario="2016 assessment forecast")==642.01,
  output_value("fishing_mortality_at_age",2015,16)==0.178,
  output_value("apical_F",2015)==0.181,
  output_value("SSB",2015)==911,
  all(is.na(outputs$se)),
  nrow(candidates[candidates$candidate_id==candidate_id,])==1L,
  candidates$matched_stock_id[candidates$candidate_id==candidate_id]==stock_id,
  candidates$import_status[candidates$candidate_id==candidate_id]=="partial",
  nrow(manifest)==3L,
  manifest$bytes[manifest$file=="sedar53_red_grouper_sar_2017.pdf"]==1762231,
  grepl("source discrepancy for 1996",review,fixed=TRUE),
  grepl("Tables 6, 7, 8, and 11",review,fixed=TRUE)
)
cat("NOAA South Atlantic red grouper SEDAR 53 inputs, outputs, units, and provenance passed.\n")
