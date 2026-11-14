root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_yellowtail_2025")
native <- file.path(cache, "native", "5.09_no_extra_SE")
assessment_id <- "noaa_yellowtail_rockfish_north_2025"
stock_id <- "noaa_yellowtail_rockfish_north"
candidate_id <- "NOAA:10393"
candidate_unit_id <- "noaa_stocksmart_10393"
report_file <- "assessment_2025.pdf"
archive_file <- "model_files_2025.zip"
data_file <- file.path(native, "YTRK.North.data.ss")
control_file <- file.path(native, "YTRK.North.control.ss")
report_output <- file.path(native, "Report.sso")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
read_csv <- function(path) utils::read.csv(path, stringsAsFactors=FALSE,
  check.names=FALSE, na.strings=c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows=0L,
  check.names=FALSE))
make_rows <- function(fields, values, n) {
  z <- lapply(fields, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value); value[is.na(value)] <- ""; rep_len(value,n)
  })
  names(z) <- fields
  as.data.frame(z, stringsAsFactors=FALSE, check.names=FALSE)
}
input_fields <- read_fields(file.path(database,"inputs.csv"))
output_fields <- read_fields(file.path(database,"outputs.csv"))
assumption_fields <- read_fields(file.path(database,"assumptions.csv"))
make_input <- function(n,type,measure,basis,value,unit,year=NA_real_,
  age=NA_real_,fleet="",survey="",sex="",season="",sampling_time=NA_real_,
  source_reference,transformation="",notes="",observation_id="",
  length_bin=NA_real_,length_bin_lower=NA_real_,length_bin_upper=NA_real_,
  sample_size=NA_real_,age_error=NA_real_,partition=NA_real_) {
  make_rows(input_fields,list(assessment_id=assessment_id,type=type,
    measure=measure,basis=basis,value=value,unit=unit,year=year,
    year_basis=if(all(is.na(year))) "" else "calendar_year",age=age,
    fleet=fleet,survey=survey,sex=sex,region="Northern Pacific Coast",
    season=season,sampling_time=sampling_time,source_type="native_model",
    source_reference=source_reference,transformation=transformation,notes=notes,
    observation_id=observation_id,length_bin=length_bin,
    length_bin_lower=length_bin_lower,length_bin_upper=length_bin_upper,
    sample_size=sample_size,age_error=age_error,partition=partition),n)
}
make_output <- function(n,type,measure,value,unit,year=NA_real_,age=NA_real_,
  fleet="",sex="combined",se=NA_real_,lwr=NA_real_,upr=NA_real_,
  source_type="native_model",source_reference,notes="") {
  make_rows(output_fields,list(assessment_id=assessment_id,type=type,
    measure=measure,value=value,unit=unit,year=year,age=age,fleet=fleet,
    sex=sex,region="Northern Pacific Coast",season="",se=se,lwr=lwr,upr=upr,
    source_type=source_type,source_reference=source_reference,notes=notes),n)
}
make_assumption <- function(component,setting,value,source_reference,notes="",
  fleet="",survey="",sex="") {
  make_rows(assumption_fields,list(assessment_id=assessment_id,
    component=component,setting=setting,value=value,source_reference=source_reference,
    notes=notes,fleet=fleet,survey=survey,sex=sex,region="Northern Pacific Coast"),1L)
}
sha256_file <- function(path) {
  result <- system2("certutil.exe",c("-hashfile",shQuote(path),"SHA256"),
    stdout=TRUE,stderr=FALSE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result,value=TRUE)))
  if(length(hash)!=1L) stop("Could not calculate SHA-256: ",path,call.=FALSE)
  hash
}
manifest <- read_csv(file.path(cache,"sources.csv"))
verify_cached <- function(file,path) {
  row <- manifest[manifest$source==file,,drop=FALSE]
  if(nrow(row)!=1L||!file.exists(path)||
     tolower(row$sha256)!=sha256_file(path)||
     as.numeric(row$bytes)!=file.info(path)$size)
    stop("Cached source differs from provenance manifest: ",file,call.=FALSE)
  path
}
verify_cached(report_file,file.path(cache,report_file))
verify_cached(archive_file,file.path(cache,archive_file))
for(path in c(data_file,control_file,report_output,
  file.path(native,"forecast.ss"),file.path(native,"ss3.par")))
  if(!file.exists(path)) stop("Missing cached official model file: ",
    basename(path),call.=FALSE)

read_numeric_block <- function(lines,pattern,nfields) {
  h <- grep(pattern,trimws(lines),perl=TRUE)
  if(length(h)!=1L) stop("Expected one native block: ",pattern,call.=FALSE)
  rows <- list()
  for(i in seq.int(h+1L,length(lines))) {
    s <- trimws(sub("#.*$","",lines[i])); if(!nzchar(s)) next
    f <- strsplit(s,"[[:space:]]+")[[1L]]
    if(f[1L]=="-9999") break
    v <- suppressWarnings(as.numeric(f))
    if(length(v)!=nfields||anyNA(v)) stop("Malformed block at line ",i,call.=FALSE)
    rows[[length(rows)+1L]]<-v
  }
  if(!length(rows)) stop("No values in native block: ",pattern,call.=FALSE)
  as.data.frame(do.call(rbind,rows),stringsAsFactors=FALSE)
}
read_vector <- function(lines,pattern) {
  h<-grep(pattern,trimws(lines),perl=TRUE)
  if(length(h)!=1L) stop("Expected one vector: ",pattern,call.=FALSE)
  for(i in seq.int(h+1L,length(lines))) {
    s<-trimws(sub("#.*$","",lines[i]));if(!nzchar(s))next
    v<-suppressWarnings(as.numeric(strsplit(s,"[[:space:]]+")[[1L]]))
    if(!length(v)||anyNA(v)) stop("Malformed vector after ",pattern,call.=FALSE)
    return(v)
  }
  stop("Missing vector after ",pattern,call.=FALSE)
}
read_fleets <- function(lines) {
  a<-which(trimws(lines)=="#_fleetinfo");b<-which(trimws(lines)=="#_Catch data")
  if(length(a)!=1L||length(b)!=1L||b<=a) stop("Missing fleet table.",call.=FALSE)
  z<-lines[seq.int(a+2L,b-1L)]
  z<-z[grepl("^[[:space:]]*[0-9]+[[:space:]]",z)]
  rows<-lapply(z,function(s) strsplit(trimws(sub("#.*$","",s)),"[[:space:]]+")[[1L]])
  d<-as.data.frame(do.call(rbind,lapply(rows,function(x)x[1:6])),stringsAsFactors=FALSE)
  names(d)<-c("type","timing","area","units","catch_mult","name")
  for(nm in names(d)[1:5]) d[[nm]]<-as.numeric(d[[nm]])
  d$name<-trimws(d$name);d
}
read_index_info <- function(lines) {
  a<-which(trimws(lines)=="#_CPUE_and_surveyabundance_observations")
  b<-which(trimws(lines)=="#_CPUE_data")
  if(length(a)!=1L||length(b)!=1L||b<=a) stop("Missing index configuration.",call.=FALSE)
  z<-lines[seq.int(a+4L,b-1L)]
  z<-z[grepl("^[[:space:]]*[0-9]+[[:space:]]",z)]
  d<-as.data.frame(do.call(rbind,lapply(z,function(s)
    as.numeric(strsplit(trimws(sub("#.*$","",s)),"[[:space:]]+")[[1L]]))),
    stringsAsFactors=FALSE)
  names(d)<-c("fleet","units","error","sd_report");d
}
data_lines<-readLines(data_file,warn=FALSE)
fleets<-read_fleets(data_lines);fleet_names<-setNames(fleets$name,seq_len(nrow(fleets)))
index_info<-read_index_info(data_lines)
catch<-read_numeric_block(data_lines,
  "^#_year[[:space:]]+season[[:space:]]+fleet[[:space:]]+catch[[:space:]]+catch_se$",5L)
names(catch)<-c("year","season","fleet","value","catch_se")
catch<-catch[catch$year!=-999,,drop=FALSE]
index<-read_numeric_block(data_lines,
  "^#_year[[:space:]]+month[[:space:]]+index[[:space:]]+obs[[:space:]]+se_log$",5L)
names(index)<-c("year","month","fleet","value","se_log")
length_comp<-read_numeric_block(data_lines,
  "^#_year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+Nsamp",44L)
age_comp<-read_numeric_block(data_lines,
  "^#_year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+ageerr",69L)
length_bins<-read_vector(data_lines,"^#_lbin_vector$")
age_bins<-read_vector(data_lines,"^#_agebin_vector$")
names(length_comp)<-c("year","month","fleet","sex_code","partition","sample_size",
  paste0("female_",seq_along(length_bins)),paste0("male_",seq_along(length_bins)))
names(age_comp)<-c("year","month","fleet","sex_code","partition","age_error",
  "length_lower","length_upper","sample_size",paste0("female_",seq_along(age_bins)),
  paste0("male_",seq_along(age_bins)))
if(length(fleets$name)!=7L||
 !identical(fleets$name,c("Commercial","At-Sea-Hake","Recreational",
   "H&L_survey","Triennial","WCGBTS","SMURF"))||
 !identical(as.integer(length_bins),seq.int(20L,56L,by=2L))||
 !identical(as.integer(age_bins),1:30)||
 !identical(nrow(catch),408L)||!identical(nrow(index),54L)||
 !identical(nrow(length_comp),178L)||!identical(nrow(age_comp),855L)||
 !identical(as.integer(index_info$units[match(4:7,index_info$fleet)]),c(0L,1L,1L,33L)))
 stop("Native input structure differs from the reviewed assessment.",call.=FALSE)
if(any(catch$value<0)||any(index$value<=0|index$se_log<=0)||
 any(length_comp$sample_size<=0)||any(age_comp$sample_size<=0)||
 any(as.matrix(length_comp[,c(paste0("female_",seq_along(length_bins)),
   paste0("male_",seq_along(length_bins)))])<0)||
 any(as.matrix(age_comp[,c(paste0("female_",seq_along(age_bins)),
   paste0("male_",seq_along(age_bins)))])<0))
 stop("Native input range check failed.",call.=FALSE)

input_rows<-list();add_input<-function(x)input_rows[[length(input_rows)+1L]]<<-x
for(i in seq_len(nrow(catch))) {
 fleet<-unname(fleet_names[as.character(as.integer(catch$fleet[i]))])
 add_input(make_input(1L,"catch","catch_biomass","biomass",catch$value[i],
  "metric tonnes",year=catch$year[i],fleet=fleet,season="annual season 1",
  source_reference="YTRK.North.data.ss; Catch data",
  transformation="Native catch copied without rescaling.",
  notes="Total annual fleet catch biomass, not observed catch-at-age. The three year=-999 placeholders are excluded."))
 add_input(make_input(1L,"catch","catch_se","native_scale",catch$catch_se[i],
  "native catch_se",year=catch$year[i],fleet=fleet,season="annual season 1",
  source_reference="YTRK.North.data.ss; Catch data catch_se",
  notes="Native catch_se field copied without interpreting its likelihood role."))
}
for(i in seq_len(nrow(index))) {
 f<-as.integer(index$fleet[i]);u<-index_info$units[match(f,index_info$fleet)]
 survey<-unname(fleet_names[as.character(f)])
 measure<-switch(as.character(u),"0"="relative_abundance_index",
   "1"="relative_biomass_index","33"="recruitment_index")
 unit<-switch(as.character(u),"0"="native number-index units (SS3 code 0)",
   "1"="native biomass-index units (SS3 code 1)",
   "33"="native recruitment-index units (SS3 code 33)")
 time<-(index$month[i]-1)/12;season<-paste0("month ",as.integer(index$month[i]))
 add_input(make_input(1L,"index",measure,"index_scale",index$value[i],unit,
  year=index$year[i],survey=survey,season=season,sampling_time=time,
  source_reference="YTRK.North.data.ss; CPUE_data",
  transformation="Native observation copied without rescaling.",
  notes="Aggregate survey index, not age-specific. sampling_time follows the month-start convention (month - 1)/12."))
 add_input(make_input(1L,"index","log_index_sd","log_scale",index$se_log[i],
  "log-scale SD",year=index$year[i],survey=survey,season=season,
  sampling_time=time,source_reference="YTRK.North.data.ss; CPUE_data se_log",
  notes="Native se_log value retained; error configuration is defined by the control file."))
}
add_comps<-function(x,bins,is_age=FALSE) {
 fc<-paste0("female_",seq_along(bins));mc<-paste0("male_",seq_along(bins));out<-list()
 add<-function(v)out[[length(out)+1L]]<<-v
 for(i in seq_len(nrow(x))) {
  sc<-as.integer(x$sex_code[i])
  vals<-switch(as.character(sc),
   "0"=list(combined=as.numeric(x[i,fc,drop=TRUE])),
   "1"=list(female=as.numeric(x[i,fc,drop=TRUE])),
   "2"=list(male=as.numeric(x[i,mc,drop=TRUE])),
   "3"=list(female=as.numeric(x[i,fc,drop=TRUE]),male=as.numeric(x[i,mc,drop=TRUE])),
   stop("Unexpected composition sex code.",call.=FALSE))
  signed<-as.integer(x$fleet[i]);f<-abs(signed)
  fleet<-unname(fleet_names[as.character(f)])
  if(is.na(fleet))stop("Composition fleet missing from fleetinfo.",call.=FALSE)
  fishery<-fleets$type[f]==1L;month<-as.integer(x$month[i]);year<-abs(x$year[i])
  id<-paste0(if(is_age)"age-" else "length-",sprintf("%04d",i))
  note<-if(is_age) {
   if(x$length_lower[i]>=0||x$length_upper[i]>=0)
    "Native age-at-length frequencies; original length bounds retained in cm."
   else "Native marginal age frequencies; original marginal length sentinels retained."
  } else "Native length frequencies indexed by the source length-bin vector."
  note<-paste(note,"Frequencies copied without normalization; sample size, sex code and partition retained.")
  if(sc==0L)note<-paste(note,"Sex code 0 is combined-sex data stored in the female vector.")
  if(sc==3L)note<-paste(note,"Sex code 3 is one sample with separate female and male vectors; do not sum repeated sample sizes.")
  if(signed<0L)note<-paste(note,"Original negative fleet code",signed,
    "is retained here; Stock Synthesis excludes negative-fleet rows from the likelihood.")
  if(x$year[i]<0)note<-paste(note,"Original negative year",x$year[i],
    "is retained here; Stock Synthesis excludes negative-year rows from the likelihood.")
  for(sex in names(vals))for(j in seq_along(bins)) {
   fields<-list(year=year,age=if(is_age)bins[j] else NA_real_,
    length_bin=if(is_age)NA_real_ else bins[j],
    length_bin_lower=if(is_age)x$length_lower[i] else NA_real_,
    length_bin_upper=if(is_age)x$length_upper[i] else NA_real_,sex=sex,
    fleet=if(fishery)fleet else "",survey=if(fishery)"" else fleet,
    season=paste0("month ",month),sampling_time=(month-1)/12,
    source_reference=paste0("YTRK.North.data.ss; ",if(is_age)"age_info" else "lencomp"),
    transformation="Native frequency copied without normalization.",notes=note,
    observation_id=id,sample_size=x$sample_size[i],
    age_error=if(is_age)x$age_error[i] else NA_real_,partition=x$partition[i])
   add(do.call(make_input,c(list(n=1L,type=if(fishery)"catch" else "index",
    measure=if(is_age)"frequency_at_age" else "frequency_at_length",
    basis="native_frequency",value=vals[[sex]][j],unit="source frequency"),fields)))
  }
 }
 do.call(rbind,out)
}
length_input<-add_comps(length_comp,length_bins,FALSE)
age_input<-add_comps(age_comp,age_bins,TRUE)
input_data<-do.call(rbind,c(input_rows,list(length_input,age_input)))

read_report <- function(lines,name,pattern) {
 m<-grep(paste0("^",name," report:"),trimws(lines))
 h<-grep(pattern,lines,perl=TRUE)
 if(length(m)!=1L)stop("Expected report section ",name,call.=FALSE)
 h<-h[h>m][1L];if(length(h)!=1L||is.na(h))stop("Missing report table ",name,call.=FALSE)
 cols<-strsplit(trimws(lines[h]),"[[:space:]]+")[[1L]];rows<-list()
 for(i in seq.int(h+1L,length(lines))) {
  s<-trimws(lines[i]);if(!nzchar(s)||startsWith(s,"#")||grepl(" report:",s,fixed=TRUE))break
  f<-strsplit(s,"[[:space:]]+")[[1L]];if(length(f)!=length(cols))break
  rows[[length(rows)+1L]]<-f
 }
 if(!length(rows))stop("Empty report table ",name,call.=FALSE)
 d<-as.data.frame(do.call(rbind,rows),stringsAsFactors=FALSE,check.names=FALSE)
 names(d)<-cols
 for(j in seq_along(d)){v<-suppressWarnings(as.numeric(d[[j]]));if(sum(!is.na(v))==sum(!is.na(d[[j]])))d[[j]]<-v}
 d
}
num<-function(x,nm)suppressWarnings(as.numeric(as.character(x[[nm]])))
report_lines<-readLines(report_output,warn=FALSE)
annual<-read_report(report_lines,"ANNUAL_TIME_SERIES","^year Era")
n_age<-read_report(report_lines,"NUMBERS_AT_AGE","^Area Bio_Pattern Sex")
b_age<-read_report(report_lines,"BIOMASS_AT_AGE","^Area Bio_Pattern Sex")
f_age<-read_report(report_lines,"F_AT_AGE","^Area Fleet Sex")
c_age<-read_report(report_lines,"CATCH_AT_AGE","^Area Fleet Sex")
m_age<-read_report(report_lines,"Natural_Mortality","^Area Bio_Pattern Sex")
wt_age<-read_report(report_lines,"MEAN_BODY_WT\\(Begin\\)","^Morph Yr Seas")
biology<-read_report(report_lines,"Biology_at_age_in_endyr",
 "^Seas Morph Bio_Pattern Sex Settlement Platoon int_Age")
years<-1889:2036
annual<-annual[num(annual,"year")%in%years&annual$Era%in%c("TIME","FORE"),,drop=FALSE]
pop_filter<-function(x)num(x,"Area")==1&num(x,"Bio_Pattern")==1&
 num(x,"Sex")%in%1:2&num(x,"Morph")==num(x,"Sex")&
 num(x,"BirthSeas")==1&num(x,"Settlement")==1&num(x,"Platoon")==1&
 num(x,"Seas")==1&x[["Beg/Mid"]]=="B"&num(x,"Yr")%in%years&
 x$Era%in%c("TIME","FORE")
n_age<-n_age[pop_filter(n_age),,drop=FALSE]
b_age<-b_age[pop_filter(b_age),,drop=FALSE]
m_age<-m_age[num(m_age,"Area")==1&num(m_age,"Bio_Pattern")==1&
 num(m_age,"Sex")%in%1:2&num(m_age,"Morph")==num(m_age,"Sex")&
 num(m_age,"Settlement")==1&num(m_age,"Platoon")==1&num(m_age,"Seas")==1&
 num(m_age,"Yr")%in%years&m_age$Era%in%c("TIME","FORE"),,drop=FALSE]
f_age<-f_age[num(f_age,"Area")==1&num(f_age,"Fleet")%in%1:3&
 num(f_age,"Sex")%in%1:2&num(f_age,"Morph")==num(f_age,"Sex")&
 num(f_age,"Seas")==1&num(f_age,"Yr")%in%years&f_age$Era%in%c("TIME","FORE"),,drop=FALSE]
c_age<-c_age[num(c_age,"Area")==1&num(c_age,"Fleet")%in%1:3&
 num(c_age,"Sex")%in%1:2&num(c_age,"Morph")==num(c_age,"Sex")&
 c_age$Type=="dead"&num(c_age,"Seas")==1&num(c_age,"Yr")%in%years&
 c_age$Era%in%c("TIME","FORE"),,drop=FALSE]
wt_age<-wt_age[num(wt_age,"Morph")%in%1:2&num(wt_age,"Yr")%in%years&
 num(wt_age,"Seas")==1,,drop=FALSE]
biology<-biology[num(biology,"Seas")==1&num(biology,"Morph")%in%1:2&
 num(biology,"Bio_Pattern")==1&num(biology,"Settlement")==1&
 num(biology,"Platoon")==1&num(biology,"int_Age")%in%0:40&
 num(biology,"Sex")%in%1:2&num(biology,"Morph")==num(biology,"Sex"),,drop=FALSE]
expected<-c(annual=148L,numbers=296L,biomass=296L,mortality=296L,
 fishing_mortality=888L,catch_at_age=888L,weight_at_age=296L,maturity_at_age=82L)
actual<-c(annual=nrow(annual),numbers=nrow(n_age),biomass=nrow(b_age),
 mortality=nrow(m_age),fishing_mortality=nrow(f_age),catch_at_age=nrow(c_age),
 weight_at_age=nrow(wt_age),maturity_at_age=nrow(biology))
if(any(actual!=expected)||!setequal(as.integer(unique(num(annual,"year"))),years))
 stop("Report output dimensions differ from pinned run: ",
  paste(names(actual),actual,sep="=",collapse=", "),call.=FALSE)
ages<-as.character(0:40)
long<-function(x){v<-as.matrix(x[,ages,drop=FALSE]);list(row=rep(seq_len(nrow(x)),each=41L),
 age=rep(0:40,times=nrow(x)),value=as.vector(t(v)))}
n_long<-long(n_age);b_long<-long(b_age);m_long<-long(m_age)
f_long<-long(f_age);c_long<-long(c_age);wt_long<-long(wt_age)
key<-function(x,r,year,sex,age)paste(num(x,year)[r],num(x,sex)[r],age,sep="|")
wmatch<-match(key(n_age,n_long$row,"Yr","Sex",n_long$age),
 key(wt_age,wt_long$row,"Yr","Morph",wt_long$age))
bmatch<-match(key(n_age,n_long$row,"Yr","Sex",n_long$age),
 key(b_age,b_long$row,"Yr","Sex",b_long$age))
if(anyNA(wmatch)||anyNA(bmatch)||
 max(abs(n_long$value*wt_long$value[wmatch]-b_long$value[bmatch])/
 pmax(1,b_long$value[bmatch]))>.02)stop("N, weight and biomass surfaces fail reconciliation.",call.=FALSE)
if(any(!is.finite(c(n_long$value,b_long$value,m_long$value,f_long$value,
 c_long$value,wt_long$value)))||any(m_long$value<=0)||any(f_long$value<0)||
 any(c_long$value<0)||any(wt_long$value<=0))stop("Invalid fitted output values.",call.=FALSE)

spawn_ci<-data.frame(year=2015:2025,value=c(10.12,10.08,10.19,10.13,10.02,9.86,9.68,9.59,9.46,9.27,9.13),
 lwr=c(7.51,7.48,7.57,7.48,7.32,7.12,6.90,6.77,6.61,6.39,6.23),
 upr=c(12.73,12.69,12.81,12.79,12.72,12.61,12.46,12.41,12.31,12.15,12.03),
 fraction=c(.693,.691,.698,.694,.687,.676,.663,.657,.648,.635,.626),
 fraction_lwr=c(.559,.560,.569,.565,.557,.545,.531,.524,.514,.499,.489),
 fraction_upr=c(.828,.822,.827,.823,.816,.807,.795,.790,.782,.771,.763))
rec_ci<-data.frame(year=2015:2024,value=c(22756,32993,22327,20164,33162,27174,46846,30012,56453,33341),
 lwr=c(12148,18713,11696,10034,16661,11506,21338,12899,24658,15127),
 upr=c(42629,58169,42621,40521,66003,64179,102848,69827,129243,73488))
ay<-num(annual,"year");ssb<-num(annual,"SSB");recruits<-num(annual,"recruits")
si<-match(spawn_ci$year,ay);ri<-match(rec_ci$year,ay)
if(anyNA(si)||anyNA(ri)||any(abs(ssb[si]-spawn_ci$value)>.02)||
 any(abs(recruits[ri]-rec_ci$value)>1.01))
 stop("Annual output estimates do not match published confidence tables.",call.=FALSE)

outputs<-list();put<-function(x)outputs[[length(outputs)+1L]]<<-x
interval<-function(years,tab,column){z<-rep(NA_real_,length(years));m<-match(years,tab$year);use<-!is.na(m);z[use]<-tab[[column]][m[use]];z}
ynote<-function(y)ifelse(y>2024,"Stock Synthesis forecast after the terminal historical data year 2024.","Fitted historical output through 2024.")
annual_out<-function(measure,value,unit,type,section,tab=NULL,extra=""){
 y<-ay;lwr<-upr<-rep(NA_real_,length(y));if(!is.null(tab)){lwr<-interval(y,tab,"lwr");upr<-interval(y,tab,"upr")}
 put(make_output(length(y),type,measure,value,unit,year=y,lwr=lwr,upr=upr,
  source_reference=paste0("Report.sso; ",section),notes=paste(extra,ynote(y))))
}
annual_out("total_biomass",num(annual,"Bio_all_an"),"metric tonnes","biomass","ANNUAL_TIME_SERIES report:61")
annual_out("summary_biomass_age4plus",num(annual,"Bio_Smry_an"),"metric tonnes","biomass","ANNUAL_TIME_SERIES report:61",
 extra="Official model summary biomass for ages 4+.")
annual_out("spawning_output",ssb,"trillion eggs","biomass","ANNUAL_TIME_SERIES report:61",
 spawn_ci,"Published rounded 95% bounds available in Table ii for 2015-2025.")
annual_out("recruitment",recruits,"thousand fish","recruitment","ANNUAL_TIME_SERIES report:61",
 rec_ci,"Age-0 recruitment; published rounded 95% bounds available in Table iii for 2015-2024.")
put(make_output(nrow(spawn_ci),"biomass","fraction_unfished_spawning_output",
 spawn_ci$fraction,"proportion",year=spawn_ci$year,lwr=spawn_ci$fraction_lwr,
 upr=spawn_ci$fraction_upr,source_type="official_table",
 source_reference="2025 assessment report; Table ii",
 notes="Spawning output relative to unfished level, with published rounded 95% intervals."))
surface_out<-function(x,z,type,measure,unit,section,sexcol="Sex",fleetcol=NULL,note=""){
 y<-num(x,"Yr")[z$row];sex<-c("1"="female","2"="male")[as.character(num(x,sexcol)[z$row])]
 fl<-if(is.null(fleetcol))"" else unname(fleet_names[as.character(as.integer(num(x,fleetcol)[z$row]))])
 put(make_output(length(z$value),type,measure,z$value,unit,year=y,age=z$age,
  fleet=fl,sex=sex,source_reference=paste0("Report.sso; ",section),
  notes=if(nzchar(note))note else ynote(y)))
}
surface_out(n_age,n_long,"population","numbers_at_age","thousand fish","NUMBERS_AT_AGE report:35")
surface_out(b_age,b_long,"biomass","biomass_at_age","metric tonnes","BIOMASS_AT_AGE report:36")
surface_out(m_age,m_long,"mortality","natural_mortality_at_age","per year","Natural_Mortality report:43",
 note="Model-generated sex-specific M-at-age surface; no age-specific uncertainty reported.")
surface_out(f_age,f_long,"mortality","fishing_mortality_at_age","per year","F_AT_AGE report:39",fleetcol="Fleet")
surface_out(c_age,c_long,"catch","numbers_at_age","thousand fish","CATCH_AT_AGE report:40",
 fleetcol="Fleet",note="Model-estimated dead catch numbers-at-age, not observed catch-at-age input.")
surface_out(wt_age,wt_long,"biology","weight_at_age","kg per fish","MEAN_BODY_WT(Begin) report:48",
 sexcol="Morph",note="Beginning-of-year model-generated stock weight-at-age, not an observed input.")
put(make_output(nrow(biology),"biology","proportion_mature_at_age",num(biology,"Age_Mat"),
 "proportion",year=2024,age=num(biology,"int_Age"),
 sex=c("1"="female","2"="male")[as.character(num(biology,"Sex"))],
 source_reference="Report.sso; Biology_at_age_in_endyr report:47",
 notes="Terminal-year model-generated maturity-at-age for 2024; no uncertainty reported."))
tot<-aggregate(n_long$value,list(year=num(n_age,"Yr")[n_long$row]),sum)
put(make_output(nrow(tot),"population","total_numbers",tot$x,"thousand fish",
 year=tot$year,source_type="derived_source_output",
 source_reference="Report.sso; NUMBERS_AT_AGE report:35",
 notes="Derived by summing reported numbers-at-age over ages 0-40 and both sexes; no uncertainty available."))
output_data<-do.call(rbind,outputs)
assumptions<-list();add_a<-function(...)assumptions[[length(assumptions)+1L]]<<-make_assumption(...)
add_a("assessment","model_structure","One area; two sexes; ages 0-40; one annual season; three fishery fleets and four survey/index fleets.",
 "YTRK.North.data.ss; dimensions and fleetinfo")
add_a("assessment","assessment_years","Fitted data through 2024; Report.sso provides forecast output through 2036.",
 "YTRK.North.data.ss; _styr and _endyr; Report.sso ANNUAL_TIME_SERIES report:61",
 "FORE rows are projections, not fitted historical estimates.")
add_a("catch","catch_inputs","Annual catch biomass is input by commercial, at-sea hake and recreational fleets in metric tonnes.",
 "YTRK.North.data.ss; Catch data and fleetinfo",
 "Aggregate catch likelihood; no direct observed catch-at-age series.")
add_a("survey","index_units_and_timing","Four aggregate indices use SS3 unit codes 0 (numbers), 1 (biomass), and 33 (special recruitment index); all have errtype 0 (lognormal), and observations are recorded in month 7.",
 "YTRK.North.data.ss; CPUE configuration and CPUE_data",
 "Indices are not age-specific. sampling_time=0.5 uses the month-start convention.")
add_a("composition","age_and_length_data","Length frequencies and age frequencies, including conditional age-at-length samples, are fitted; source age bins are 1-30 and length-bin values 20-56 cm.",
 "YTRK.North.data.ss; lencomp, age_info, lbin_vector and agebin_vector",
 "Native frequencies, sample sizes, partitions, sex codes, age-error codes, conditional length bounds, and signed year/fleet exclusions are retained without normalization.")
add_a("mortality","natural_mortality","Natural mortality is a constant base rate by sex, estimated with a maximum-age-based lognormal prior; age 43 is the 99.9th percentile of PacFIN ages, with male M parameterized as an offset from female M.",
 "YTRK.North.control.ss; natural mortality settings; 2025 assessment report; methods")
add_a("biology","growth_and_maturity","Growth is modeled by sex with von Bertalanffy curves; age-based maturity and fecundity are specified in the biological model.",
 "YTRK.North.control.ss; growth, maturity and fecundity sections; Report.sso Biology_at_age_in_endyr report:47",
 "Weight-at-age and maturity-at-age outputs are model-generated, not observed input series.")
add_a("recruitment","stock_recruitment_and_deviations","Standardized Beverton-Holt; steepness fixed at 0.718 and sigma-R fixed at 0.5; early deviations start in 1932 and main deviations span 1962-2018.",
 "YTRK.North.control.ss; spawner-recruitment and recruitment-deviation sections")
add_a("q","survey_catchability","Catchability is estimated for the four survey/index fleets.",
 "YTRK.North.control.ss; Q parameter section",
 "Native indices are not rescaled using fitted q values.")
add_a("uncertainty","reported_intervals","Asymptotic 95% intervals are published for spawning output through 2025 and recruitment through 2024; age-specific intervals are not reported.",
 "2025 assessment report; Tables ii and iii",
 "Only the rounded published bounds are stored.")
assumption_data<-do.call(rbind,assumptions)
if(any(!nzchar(input_data$source_reference))||any(!nzchar(output_data$source_reference)))
 stop("Missing input/output provenance.",call.=FALSE)
a_key<-do.call(paste,c(lapply(assumption_data[c("assessment_id","component","fleet","survey","sex","region","season","setting")],function(x)ifelse(is.na(x),"",x)),sep="\r"))
if(anyDuplicated(a_key))stop("Duplicate assumptions generated.",call.=FALSE)

candidate_path<-file.path(root,"discovery","candidates.csv")
inventory_path<-file.path(root,"discovery","inventory_units.csv")
selected_path<-file.path(root,"discovery","selected_batch_10_2026.csv")
stocks_path<-file.path(database,"stocks.csv");assessments_path<-file.path(database,"assessments.csv")
stocks<-read_csv(stocks_path);assessments<-read_csv(assessments_path)
candidate<-read_csv(candidate_path);inventory<-read_csv(inventory_path);selected<-read_csv(selected_path)
ci<-which(candidate$candidate_id==candidate_id)
ii<-which(inventory$unit_key==paste0("candidate:",candidate_unit_id))
si<-which(selected$candidate_unit_id==candidate_unit_id)
if(length(ci)!=1L||length(ii)!=1L||length(si)!=1L||
 candidate$eligibility[ci]!="eligible"||(!dry_run&&candidate$import_status[ci]!="not_started")||
 (!dry_run&&!inventory$import_status[ii]%in%c("not_started",""))||
 any(stocks$stock_id==stock_id)||any(assessments$assessment_id==assessment_id))
 stop("Candidate or canonical record state is unexpected.",call.=FALSE)
first_column<-function(path){f<-read_fields(path);utils::read.csv(path,stringsAsFactors=FALSE,
 check.names=FALSE,colClasses=c("character",rep("NULL",length(f)-1L)))[[1L]]}
for(path in c(file.path(database,"inputs.csv"),file.path(database,"outputs.csv")))
 if(!dry_run&&assessment_id%in%first_column(path))stop("Assessment rows already exist.",call.=FALSE)
blank<-function(fields,values){z<-as.list(rep("",length(fields)));names(z)<-fields
 for(nm in names(values))z[[nm]]<-as.character(values[[nm]])
 as.data.frame(z,stringsAsFactors=FALSE,check.names=FALSE)}
stock<-blank(names(stocks),list(stock_id=stock_id,charbonneau_id="",
 authority="NOAA-NWFSC",authority_stock_id="10393",scientific_name="Sebastes flavidus",
 common_name="Yellowtail rockfish - Northern Pacific Coast",
 area="U.S. Pacific Coast north of 40°10′ N",region="Northern Pacific Coast",
 ocean="Northeast Pacific",
 notes="NOAA Stock SMART ID 10393. This 2025 U.S. northern stock unit is distinct from the Canadian coastwide DFO unit."))
report_url<-manifest$url[match(report_file,manifest$source)]
model_url<-manifest$url[match(archive_file,manifest$source)]
assessment<-blank(names(assessments),list(assessment_id=assessment_id,stock_id=stock_id,
 assessment_year=2025L,terminal_year=2024L,estimate_terminal_year=2036L,
 assessment_type="full_benchmark",model_family="Stock Synthesis",
 model_version="3.30.23.1",is_current=TRUE,is_applied=TRUE,framework_year="",
 assessment_url=report_url,data_url=model_url,model_url=model_url,repository_url=model_url,
 assumptions_status="partial",inputs_status="partial",outputs_status="partial",
 notes="Official 2025 benchmark assessment fitted through 2024. Native inputs include aggregate catch, survey indices, and age/length compositions; observed catch-at-age and age-specific survey indices are not direct inputs. Report.sso includes fitted history and forecast rows through 2036."))
cr<-candidate[ci,,drop=FALSE];cr$matched_stock_id<-stock_id;cr$match_status<-"matched";cr$import_status<-"partial"
cr$catch_age_evidence<-"The model uses annual catch biomass and fishery age compositions; observed catch-at-age is not a direct native input."
cr$survey_age_evidence<-"Four aggregate survey indices use number, biomass or special recruitment-index scales; age compositions support only downstream reconstruction."
cr$weights_evidence<-"Weight-at-age is generated by sex-specific growth and weight-length relationships; no observed weight-at-age series is supplied."
cr$maturity_evidence<-"Age-based maturity is specified in the biological model; no maturity-at-age likelihood series is present in the native data file."
cr$mortality_evidence<-"Natural mortality is estimated with a maximum-age-based lognormal prior; age 43 is the 99.9th percentile of PacFIN ages."
cr$timing_evidence<-"Survey-index and composition observations use month 7; the model spawning month is January. Month 7 maps to sampling_time 0.5 using month-start convention."
cr$output_evidence<-"Report.sso provides annual N, biomass, catch-at-age, F-at-age and M-at-age through 2036; published 95% intervals cover spawning output through 2025 and recruitment through 2024."
cr$review_date<-"2026-11-07"
cr$decision_reason<-"Partial source import of the current U.S. northern unit 2025 benchmark; source likelihood inputs and fitted outputs remain distinct."
cr$notes<-"See source_reviews/noaa_yellowtail_rockfish_north_2025.md. Model-generated biology and mortality surfaces are outputs, not observed input series."
ir<-inventory[ii,,drop=FALSE];ir$matched_stock_id<-stock_id;ir$import_status<-"partial"
sr<-selected[si,,drop=FALSE];sr$curation_status<-"partial_source_import"
files<-c(report_file,archive_file,"native/5.09_no_extra_SE/YTRK.North.data.ss",
 "native/5.09_no_extra_SE/YTRK.North.control.ss","native/5.09_no_extra_SE/Report.sso",
 "native/5.09_no_extra_SE/CompReport.sso","native/5.09_no_extra_SE/forecast.ss",
 "native/5.09_no_extra_SE/ss3.par")
paths<-file.path(cache,files)
cache_manifest<-data.frame(local_file=file.path("discovery_noaa_yellowtail_2025",files),
 source_url=c(report_url,model_url,rep(model_url,length(files)-2L)),
 retrieved_on=rep("2026-10-29",length(files)),sha256=vapply(paths,sha256_file,character(1)),
 bytes=file.info(paths)$size,stringsAsFactors=FALSE)
replace_csv_row<-function(path,key_column,key_value,row_index,row) {
 bytes<-readBin(path,"raw",n=file.info(path)$size);bounds<-csv_record_bounds(bytes)
 current<-read_csv(path)
 if(row_index>nrow(current)||as.character(current[[key_column]][row_index])!=key_value)
  stop("CSV row identity differs in ",basename(path),call.=FALSE)
 tmp<-tempfile(fileext=".csv");on.exit(unlink(tmp),add=TRUE)
 utils::write.table(row,tmp,sep=",",row.names=FALSE,col.names=FALSE,quote=TRUE,
  na="",qmethod="double",eol="\n")
 replacement<-readBin(tmp,"raw",n=file.info(tmp)$size)
 if(length(replacement)&&tail(replacement,1L)==as.raw(10L))replacement<-replacement[-length(replacement)]
 rec<-as.integer(row_index)+1L;first<-bounds$start[rec];last<-bounds$end[rec];nextb<-last+1L
 while(nextb<=length(bytes)&&bytes[nextb]==as.raw(13L))nextb<-nextb+1L
 if(nextb<=length(bytes)&&bytes[nextb]==as.raw(10L)){replacement<-c(replacement,as.raw(10L));last<-nextb}
 before<-if(first>1L)bytes[seq_len(first-1L)]else raw(0L)
 after<-if(last<length(bytes))bytes[(last+1L):length(bytes)]else raw(0L)
 writeBin(c(before,replacement,after),path)
 updated<-read_csv(path)
 if(nrow(updated)!=nrow(current)||sum(as.character(updated[[key_column]])==key_value)!=1L)
  stop("CSV replacement failed identity check: ",basename(path),call.=FALSE)
}
append_rows<-function(path,rows)if(nrow(rows))utils::write.table(rows,file=path,
 sep=",",row.names=FALSE,col.names=FALSE,quote=TRUE,qmethod="double",na="",
 append=TRUE,eol="\n")
if(!dry_run) {
 append_rows(file.path(database,"stocks.csv"),stock)
 append_rows(file.path(database,"assessments.csv"),assessment)
 append_rows(file.path(database,"inputs.csv"),input_data)
 append_rows(file.path(database,"outputs.csv"),output_data)
 append_rows(file.path(database,"assumptions.csv"),assumption_data)
 replace_candidate_register_row(candidate_path,ci,cr,candidate_id)
 replace_csv_row(inventory_path,"unit_key",paste0("candidate:",candidate_unit_id),ii,ir)
 replace_csv_row(selected_path,"candidate_unit_id",candidate_unit_id,si,sr)
 utils::write.csv(cache_manifest,file.path(root,"provenance",
  "noaa_yellowtail_rockfish_north_2025_sources.csv"),row.names=FALSE,na="",fileEncoding="UTF-8")
}
cat(if(dry_run)"Dry run parsed " else "Imported ",nrow(input_data),
 " native inputs and ",nrow(output_data)," official output rows; status remains partial.\n")
