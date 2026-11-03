base <- "."; db <- file.path(base, "database")
id <- "nefsc_yellowtail_georges_bank_2025"
url <- "https://raw.githubusercontent.com/NOAA-EDAB/stocksmart/664c4237e26520b260a090e1821a2cee5d1cdf07/data/stock_assessment_data.rda"
file <- file.path(base,"source_cache/ck_dfo_nefsc_ferruginea_gb/stock_assessment_data_664c4237.rda")
stopifnot(digest::digest(readBin(file,"raw",n=file.info(file)$size),algo="sha256",serialize=FALSE)=="141db3599cbf37af3e019bd53d2323d829a719b273e8ab0226b73f6ad18620b0")
e <- new.env(parent=emptyenv()); load(file,envir=e)
x <- e$stock_assessment_data; x <- x[x$stock_name=="Yellowtail flounder - Georges Bank" & x$assessment_year==2025,]
stopifnot(nrow(x)==246,all(x$stock_id==10033),all(x$assessment_id==14076),!anyDuplicated(x[c("metric","year")]))
get <- function(metric, years) { z<-x[x$metric==metric,]; z<-z[order(z$year),]; stopifnot(identical(as.integer(z$year),years),all(is.finite(z$value))); z }
catch<-get("Catch",1935:2024); f<-get("Fmort",1973:2024); rec<-get("Recruitment",1973:2024); ssb<-get("Abundance",1973:2024)
stopifnot(all(catch$units=="Metric Tons"),all(ssb$description=="Spawning Stock Biomass"),all(rec$description=="Recruits - Age 1"))
i0 <- data.table::fread(file.path(db,"inputs.csv"),na.strings=c("","NA"),blank.lines.skip=TRUE,data.table=FALSE)
o0 <- data.table::fread(file.path(db,"outputs.csv"),na.strings=c("","NA"),blank.lines.skip=TRUE,data.table=FALSE)
i0<-i0[i0$assessment_id==id & i0$source_type=="official_table",]; o0<-o0[o0$assessment_id==id & o0$source_type=="official_table",]
match_table <- function(z,measure,tolerance) { y<-o0[o0$measure==measure & !is.na(o0$year) & o0$year %in% 2015:2024,]; y<-y[order(y$year),]; z<-z[z$year %in% 2015:2024,]; stopifnot(nrow(y)==10,all(abs(y$value-z$value)<tolerance)) }
match_table(ssb,"SSB",1e-4); match_table(rec,"recruitment",1e-4); match_table(f,"Ffull",1e-6)
i0<-i0[order(i0$year),]; stopifnot(nrow(i0)==10,all(abs(i0$value-catch$value[catch$year>=2015])<=.501))
blank<-function(file,n){names0<-names(read.csv(file.path(db,file),nrows=0)); z<-as.data.frame(matrix("",n,length(names0)),stringsAsFactors=FALSE); names(z)<-names0;z$assessment_id<-id;z}
c<-catch[catch$year<2015,]; inputs<-blank("inputs.csv",nrow(c)); inputs$type<-"catch";inputs$measure<-"total_biomass";inputs$basis<-"biomass";inputs$fleet<-"Combined catch";inputs$year<-c$year;inputs$year_basis<-"calendar_year";inputs$value<-round(c$value,3);inputs$unit<-"tonnes";inputs$source_type<-"official_machine_readable";inputs$source_reference<-url;inputs$notes<-ifelse(c$year<1973,"Historical catch context before the 1973 model start; not a fitted observation.","Total assessment catch. Do not count it again with component catches.")
out<-function(z,type,measure,unit,age="",group="") {z<-z[z$year<2015,];q<-blank("outputs.csv",nrow(z));q$type<-type;q$measure<-measure;q$year<-z$year;q$value<-if(measure=="Ffull") round(z$value,3) else z$value;q$unit<-unit;q$age<-age;q$age_group<-group;q$source_type<-"official_machine_readable";q$source_reference<-url;q$notes<-"2025 production assessment Stock SMART series, checked against all 2015-2024 published report values. No uncertainty reported; F rounded to three decimals to remove binary storage noise.";q}
outputs<-rbind(out(ssb,"biomass","SSB","tonnes"),out(f,"mortality","Ffull","per year",group="4-6"),out(rec,"recruitment","recruitment","thousand fish",age=1))
append_selected<-function(file,z){p<-file.path(db,file);raw<-rawToChar(readBin(p,"raw",n=file.info(p)$size)); l<-strsplit(raw,"\n",fixed=TRUE)[[1]]; l<-l[!(startsWith(l,paste0('"',id,'",')) & grepl(url,l,fixed=TRUE))]; tmp<-tempfile(tmpdir=db);on.exit(unlink(tmp),add=TRUE);write.table(z,tmp,sep=",",quote=TRUE,row.names=FALSE,col.names=FALSE,na="",fileEncoding="UTF-8"); repl<-readLines(tmp,encoding="UTF-8",warn=FALSE); bytes<-charToRaw(paste0(paste(c(l,repl),collapse="\n"),if(endsWith(raw,"\n"))"\n" else ""));writeBin(bytes,tmp);if(!file.copy(tmp,p,overwrite=TRUE))stop("write failed")}
if(identical(Sys.getenv("TAM_SOURCE_DRY_RUN"),"1")) cat("Source validated:",nrow(inputs),"catch and",nrow(outputs),"historical model outputs.\n") else {append_selected("inputs.csv",inputs);append_selected("outputs.csv",outputs);cat("Added verified 2025 historical trajectories.\n")}
