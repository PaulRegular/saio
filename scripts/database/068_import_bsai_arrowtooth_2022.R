source("scripts/database/pacific_tables.R")
id <- "afsc_arrowtooth_flounder_bsai_2022"
cache <- "source_cache/afsc_arrowtooth_flounder_bsai"
report <- "https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/BSAIatf.pdf"
pages <- pdftools::pdf_text(file.path(cache,"assessment_2022.pdf"))
lines <- unlist(strsplit(paste(pages,collapse="\n"),"\n"))
year_rows <- function(text)text[grepl("^\\s*(19[789][0-9]|20[012][0-9])\\s+[0-9]",text)]
numbers <- function(line)scan(text=gsub(",","",line),quiet=TRUE)
table_rows <- function(number,next_number) {
  first <- grep(paste0("^\\s*Table 6\\.",number,"\\."),lines)[1]
  last <- grep(paste0("^\\s*Table 6\\.",next_number,"\\."),lines)[1]
  year_rows(lines[seq.int(first+1,last-1)])
}
input <- function(type,measure,basis,value,unit,year=NA_integer_,age=NA_integer_,sex="combined",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,basis=basis,value=value,
    unit=unit,year=year,age=age,sex=sex,region="Bering Sea and Aleutian Islands",
    year_basis=ifelse(is.na(year),"","calendar_year"),source_type="official_table",source_reference=report,...)
}
inputs <- list()
# The final numeric column is the source's arrowtooth-only estimate, not the combined species catch.
for(page in c(36,37)) {
  z <- year_rows(strsplit(pages[page],"\n")[[1]])
  if(page==36) {
    values <- lapply(z,numbers)
    year <- vapply(values,`[`,numeric(1),1)
    catch <- vapply(values,function(v)tail(v,1),numeric(1))
  } else {
    values <- lapply(z,function(line)as.numeric(strsplit(trimws(gsub(",","",line)),"[[:space:]]+")[[1]][1:4]))
    year <- vapply(values,`[`,numeric(1),1);catch <- vapply(values,`[`,numeric(1),4)
  }
  keep <- year>=1976 & year<=2021
  inputs[[length(inputs)+1L]] <- input("catch","total_biomass","biomass",catch[keep],"t",year[keep],
    fleet="Arrowtooth_fishery",notes="Tables6.2a/b ATF-only catch, source species-allocation already applied. Do not substitute combined arrowtooth/Kamchatka catch. Partial2022 catch excluded because full-year model input was not verified.")
}
bio <- strsplit(pages[44],"\n")[[1]]
bio <- bio[seq.int(grep("^\\s*Table 6\\.10\\.",bio)[1]+1,length(bio))]
bio <- bio[grepl("^\\s*[0-9]+\\+?\\s+[0-9]",bio)]
bio <- do.call(rbind,lapply(bio,function(line)numbers(gsub("+","",line,fixed=TRUE))))
stopifnot(nrow(bio)==21,ncol(bio)==4,identical(as.integer(bio[,1]),1:21))
for(sex in 1:2) {
  inputs[[length(inputs)+1L]] <- input("weight","weight_at_age","kg_per_fish",bio[,sex+1],"kg/fish",
    age=1:21,sex=c("female","male")[sex],notes="Original fixed Table6.10 sex-specific weights, kg; source 2018 age-length conversion, used unchanged through2022; age21 is plus group. Rounded to .01kg.")
  inputs[[length(inputs)+1L]] <- input("M","natural_mortality_at_age","per_year",c(.2,.35)[sex],"per year",
    age=1:21,sex=c("female","male")[sex],notes="Fixed assessment M, female .2 and male .35; not source-estimated annual M.")
}
inputs[[length(inputs)+1L]] <- input("maturity","maturity_at_age","proportion",bio[,4],"proportion",
  age=1:21,sex="female",notes="Original Table6.10 female maturity (Stark2011), source-rounded; age21 plus group.")
data <- pdftools::pdf_data(file.path(cache,"assessment_2022.pdf"))[[41]]
rows <- data[data$x<125 & data$y>180 & grepl("^(19[789][0-9]|20[012][0-9])$",data$text),]
for(g in 1:3) {
  years <- values <- cvs <- numeric()
  for(j in seq_len(nrow(rows))) {
    z <- data[data$y==rows$y[j] & data$x>=c(130,250,355)[g] & data$x<c(250,355,500)[g],]
    z <- z[order(z$x),]
    if(!nrow(z))next
    stopifnot(nrow(z)==2)
    years <- c(years,as.numeric(rows$text[j]));values<-c(values,as.numeric(gsub(",","",z$text[1])))
    cvs <- c(cvs,as.numeric(z$text[2]))
  }
  survey <- c("EBS_shelf","EBS_slope","Aleutian_Islands")[g]
  active <- years>=c(1992,2002,1991)[g]
  notes <- ifelse(active,"Active underlined survey input, Table6.6.","Inactive earlier survey estimate retained as source context, Table6.6.")
  inputs[[length(inputs)+1L]] <- input("index","total_biomass","biomass",values,"t",years,
    survey=survey,notes=paste(notes,"Native within-year sampling fraction not verified; left missing, not assumed .5."))
  inputs[[length(inputs)+1L]] <- input("index","index_sd","relative_scale",cvs,"CV",years,
    survey=survey,notes=paste(notes,"Original CV, not log SD."))
}
surface <- function(page) {
  z <- do.call(rbind,lapply(year_rows(strsplit(pages[page],"\n")[[1]]),numbers))
  stopifnot(nrow(z)==47,identical(as.integer(z[,1]),1976:2022));z[,-1]
}
n <- list(female=cbind(surface(50),surface(51)),male=cbind(surface(52),surface(53)))
for(sex in names(n))dimnames(n[[sex]])<-list(1976:2022,1:21)
output <- function(type,measure,value,unit,year,age=NA_integer_,sex="combined",...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,unit=unit,
    year=year,age=age,sex=sex,region="Bering Sea and Aleutian Islands",
    source_type="official_table",source_reference=report,...)
}
outputs <- list()
for(sex in names(n)) {
  z <- pacific_matrix_long(n[[sex]])
  outputs[[length(outputs)+1L]] <- output("population","numbers_at_age",z$value,"thousand fish",z$year,z$age,sex,
    age_group=ifelse(z$age==21,"21+",""),notes="Table6.16 beginning-year N by sex; rounded to1000 fish. Point-estimate posterior/mode convention not explicitly established; no marginal CI invented.")
  out <- output("biomass","biomass_at_age",z$value*bio[z$age,if(sex=="female")2 else 3],"t",z$year,z$age,sex,
    age_group=ifelse(z$age==21,"21+",""),notes="Derived from original reported N in thousand fish times fixed source kg weights, yielding tonnes. No marginal or aggregate CI reconstructed; sums reproduce reported point biomass to source rounding.")
  out$source_type <- "derived_source_output";outputs[[length(outputs)+1L]]<-out
  a <- n[[sex]][1:46,1:19];b<-n[[sex]][2:47,2:20]
  m <- if(sex=="female").2 else .35
  f <- log(a/b)-m
  upper <- log((a+.5)/(b-.5))-m
  stopifnot(all(upper[f<=0]>=0))
  tail_a <- rowSums(n[[sex]][1:46,20:21]);tail_b<-n[[sex]][2:47,21]
  tail_f <- log(tail_a/tail_b)-m
  stopifnot(all(tail_f>0))
  f <- cbind(f,tail_f,tail_f);dimnames(f)<-list(1976:2021,1:21)
  z <- pacific_matrix_long(f);z<-z[z$value>0,]
  out <- output("mortality","fishing_mortality_at_age",z$value,"per year",z$year,z$age,sex,
    age_group=ifelse(z$age==21,"21+",""),notes="Derived from rounded N cohort survival: log(N[y,a]/N[y+1,a+1])-fixed sex M. For20/21+, use log((N20+N21)/nextN21)-M because source selectivity is shared. Unresolved nonpositive cells omitted, consistent with source rounding; 2022F not inferred without2023N. No SE reconstructed.")
  out$source_type <- "derived_source_output";outputs[[length(outputs)+1L]]<-out
}
b <- lapply(table_rows(13,14),function(line)tail(numbers(line),6))
b <- do.call(rbind,b);stopifnot(nrow(b)==47)
for(spec in list(c("total_biomass",1,"combined"),c("SSB",4,"female"))) {
  j<-as.numeric(spec[2]);outputs[[length(outputs)+1L]]<-output("biomass",spec[1],b[,j],"t",1976:2022,sex=spec[3],
    lwr=b[,j+1],upr=b[,j+2],notes="Table6.13 final2022 model column, historical years only. Native95% limits from MCMC, retained as printed; point convention not independently resolved, not relabelled posterior median.")
}
r <- do.call(rbind,lapply(table_rows(14,15),function(line)tail(numbers(line),3)))
stopifnot(nrow(r)==46,max(abs(r[,1]-n$female[1:46,1]-n$male[1:46,1]))<=1)
outputs[[length(outputs)+1L]]<-output("recruitment","recruitment",r[,1],"thousand fish",1976:2021,age=1,
  lwr=r[,2],upr=r[,3],notes="Table6.14 final2022 model age1 recruitment with original95% credible limits. No2022 interval reported.")
out<-output("recruitment","recruitment",n$female[47,1]+n$male[47,1],"thousand fish",2022,age=1,
  notes="Derived from reported2022 female+male beginning-year age1 N; no CI reconstructed.")
out$source_type<-"derived_source_output";outputs[[length(outputs)+1L]]<-out
out<-output("population","total_abundance",rowSums(n$female+n$male),"thousand fish",1976:2022,
  notes="Sum of reported sex/age N, ages1-21+; no total uncertainty derived from marginal rounded states.")
out$source_type<-"derived_source_output";outputs[[length(outputs)+1L]]<-out
f <- do.call(rbind,lapply(table_rows(15,16),numbers))
stopifnot(nrow(f)==47,ncol(f)==3)
outputs[[length(outputs)+1L]]<-output("mortality","fishing_mortality_intensity",f[,2],"per year",f[,1],
  notes="Table6.15 full-selection F, not an N-weighted Fbar. Rounded selectivity table is not used to invent final-year age-specific F.")
assume <- function(component,setting,value)pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=report)
assumptions<-do.call(rbind,list(
  assume("assessment","official_model","2022 Model18.9, same2018 generalized ADMB age-structured method, SSC-selectedTier3a; 2024 explicitly off-cycle catch/projection update without refitting parameters."),
  assume("population","dimensions","1976-2022, female/male ages1-21+, one BSAI population and three regional surveys. Distinguish arrowtooth from Kamchatka flounder."),
  assume("N","process","Deterministic sex-specific cohort survival and plus group; constant mean log recruitment with annual deviations, final recruitment set at mean; no source stochastic survival process."),
  assume("F","process","Annual intensity and sex-specific nonparametric age selectivity through10, older ages shared. Reported full-selection F is not population-weighted Fbar."),
  assume("M","process","Fixed femaleM=.2 and maleM=.35, not estimated annually; original weights/maturity Table6.10 used unchanged2018-2022."),
  assume("q","process","Regional biomass shares externally derived from random-effects survey biomass: shelf .825, slope .08, AI .095, sum1. Shelf q also covaries with bottom temperature. Do not silently treat these as unconstrained assessment q coefficients; full activation/covariance unresolved."),
  assume("index","observation_model","Active biomass: EBS shelf1992-2022, slope2002-2016, AI1991-2022. Survey ages used when available, otherwise lengths. Numeric composition arrays and within-year sampling fractions not recovered; earlier un-underlined biomass estimates inactive."),
  assume("catch","observation_model","Arrowtooth-only catch tonnes after source species allocation; fishery length compositions after data cleaning, no accepted fishery age likelihood. Otolith/ALK information incomplete; fitted N is not an observational age key."),
  assume("source","estimate_convention","Reported states retained at table precision; 4000thinned MCMC draws underpin95% intervals, but point mean/median/mode convention not fully established. Original N allows derived abundance/cohort F, not reconstructed observations."),
  assume("source","blocker","Production native files not found in AFSC/author public repositories or cited portals. No verified numerical fishery length compositions/ALK or survey age compositions; cannot produce defensible catch/index-at-age without inventing inputs.")
))
stock<-pacific_database_row("stocks",stock_id="afsc_arrowtooth_flounder_bsai",charbonneau_id="AFSC_BSAI_Atheresthes_stomais",
  authority="NOAA-AFSC",authority_stock_id="BSAI arrowtooth flounder",scientific_name="Atheresthes stomias",
  common_name="Bering Sea and Aleutian Islands arrowtooth flounder",area="Bering Sea and Aleutian Islands",
  region="Bering Sea and Aleutian Islands",ocean="Northeast Pacific",notes="Catalogue identifier retains source spelling stomais; species is stomias. Not Kamchatka flounder or CEATTLE multispecies sensitivity.")
assessment<-pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2022,terminal_year=2022,estimate_terminal_year=2022,assessment_type="full",
  model_family="ADMB statistical catch at age",model_version="Model18.9 (2022)",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Most recent recoverable detailed production fit; 2024 only projection update. Original biology, sex-specific N and aggregate outputs recovered; derived cohort F only through2021. Numerical likelihood compositions/ALK and survey timing unavailable; source-blocked translation, no fabricated age inputs.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
