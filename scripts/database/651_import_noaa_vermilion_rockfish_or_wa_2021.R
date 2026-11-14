root <- "."
database <- file.path(root, "database")
manifest_path <- file.path(root, "provenance", "noaa_vermilion_rockfish_or_wa_2021", "sources.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_35_2026.csv")
stock_id <- "noaa_vermilion_rockfish_or_wa"
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)
if (!requireNamespace("r4ss", quietly = TRUE)) stop("Install r4ss to parse the cached official Stock Synthesis files.", call. = FALSE)

specs <- list(
  list(code="oregon", candidate_id="NOAA:15338", assessment_id=paste0(stock_id,"_2021_oregon"),
    region="Oregon", report="oregon_vermilion_assessment_2021.pdf",
    archive="oregon_vermilion_model_files_2021.zip",
    report_url="https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-oregon-coast-in-2021.pdf/",
    archive_url="https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-or-zip-file/",
    cache=file.path(root,"source_cache","discovery_noaa_oregon_vermilion_2021"),
    model=file.path(root,"source_cache","discovery_noaa_oregon_vermilion_2021","Vermilion_OR_2021_Model_For_DeVore"),
    start=1892L,end=2020L,catch_n=258L,cpue_n=20L,len_n=72L,age_n=661L,spawn21=21.35,recruit21=15.77),
  list(code="washington", candidate_id="NOAA:15339", assessment_id=paste0(stock_id,"_2021_washington"),
    region="Washington", report="washington_vermilion_assessment_2021.pdf",
    archive="washington_vermilion_model_files_2021.zip",
    report_url="https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-washington-state-coast-in-2021.pdf/",
    archive_url="https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-wa-zip-file/",
    cache=file.path(root,"source_cache","discovery_noaa_vermilion_rockfish_washington_2021"),
    model=file.path(root,"source_cache","discovery_noaa_vermilion_rockfish_washington_2021","model_files","Vermilion_WA_2021_Model_For_DeVore"),
    start=1949L,end=2020L,catch_n=72L,cpue_n=0L,len_n=24L,age_n=324L,spawn21=1.55,recruit21=2.33)
)

read_table <- function(path) utils::read.csv(path, stringsAsFactors=FALSE, check.names=FALSE, na.strings=c("","NA"))
read_fields <- function(path) names(utils::read.csv(path,nrows=0L,check.names=FALSE))
sha256_file <- function(path) {
  if (.Platform$OS.type=="windows" && nzchar(Sys.which("certutil.exe"))) {
    z <- system2("certutil.exe",c("-hashfile",shQuote(path),"SHA256"),stdout=TRUE,stderr=TRUE)
    h <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",z,value=TRUE)))
  } else if (nzchar(Sys.which("sha256sum"))) {
    z <- system2("sha256sum",shQuote(path),stdout=TRUE,stderr=TRUE)
    h <- tolower(sub("[[:space:]].*$","",z))
  } else stop("A SHA-256 utility is required.",call.=FALSE)
  if(length(h)!=1L) stop("Could not calculate SHA-256 for ",path,call.=FALSE)
  h
}
manifest <- read_table(manifest_path)
for (s in specs) {
  loc <- if(s$code=="oregon") "Oregon" else "Washington"
  f <- c(s$report,s$archive,"data.ss_new","control.ss_new","Report.sso","wtatage.ss_new")
  p <- c(file.path(s$cache,f[1:2]),file.path(s$model,f[3:6]))
  m <- match(paste0(loc,"/",f),manifest$file)
  if(anyNA(m)||any(!file.exists(p))||any(file.info(p)$size!=as.numeric(manifest$bytes[m]))||
     !identical(tolower(manifest$sha256[m]),unname(vapply(p,sha256_file,character(1L))))) {
    stop(s$region," cached sources differ from the provenance manifest.",call.=FALSE)
  }
}

make_frame <- function(fields, values, n=1L) {
  z <- lapply(fields,function(f) {
    x <- values[[f]]
    if(is.null(x)) return(rep("",n))
    x <- as.character(x); x[is.na(x)] <- ""; rep_len(x,n)
  })
  names(z) <- fields
  as.data.frame(z,stringsAsFactors=FALSE,optional=TRUE,check.names=FALSE)
}
stock_fields <- read_fields(file.path(database,"stocks.csv"))
assessment_fields <- read_fields(file.path(database,"assessments.csv"))
input_fields <- read_fields(file.path(database,"inputs.csv"))
output_fields <- read_fields(file.path(database,"outputs.csv"))
assumption_fields <- read_fields(file.path(database,"assumptions.csv"))

models <- list()
for(s in specs) {
  d <- r4ss::SS_readdat(file.path(s$model,"data.ss_new"),verbose=FALSE)
  o <- r4ss::SS_output(s$model,verbose=FALSE)
  model_version <- sub(";.*$", "", o$SS_version)
  if(d$styr!=s$start||d$endyr!=s$end||d$Nsexes!=2L||d$nseas!=1L||
     !identical(model_version,"3.30.16.00"))
    stop(s$region," model structure/version differs from the reviewed assessment.",call.=FALSE)
  catch <- d$catch[d$catch$year>=s$start&d$catch$year<=s$end,,drop=FALSE]
  cpue <- d$CPUE[d$CPUE$year>=s$start&d$CPUE$year<=s$end,,drop=FALSE]
  len <- d$lencomp[d$lencomp$year>=s$start&d$lencomp$year<=s$end,,drop=FALSE]
  age <- d$agecomp[d$agecomp$year>=s$start&d$agecomp$year<=s$end,,drop=FALSE]
  if(nrow(catch)!=s$catch_n||nrow(cpue)!=s$cpue_n||nrow(len)!=s$len_n||nrow(age)!=s$age_n)
    stop(s$region," source input coverage differs from the reviewed archive.",call.=FALSE)
  annual <- o$timeseries[o$timeseries$Area==1&o$timeseries$Yr>=s$start&
    o$timeseries$Era%in%c("TIME","FORE"),,drop=FALSE]
  y <- annual[annual$Yr==2021L,,drop=FALSE]
  if(nrow(y)!=1L||abs(y$SpawnBio-s$spawn21)>max(.03,s$spawn21*.02)||
     abs(y$Recruit_0-s$recruit21)>max(.05,s$recruit21*.02))
    stop(s$region," 2021 output does not match the reviewed assessment.",call.=FALSE)
  models[[s$code]] <- list(spec=s,dat=d,out=o,version=model_version,
    catch=catch,cpue=cpue,len=len,age=age,annual=annual)
}

inputs <- list(); outputs <- list(); assumptions <- list()
add_i <- function(x) inputs[[length(inputs)+1L]] <<- x
add_o <- function(x) outputs[[length(outputs)+1L]] <<- x
add_a <- function(x) assumptions[[length(assumptions)+1L]] <<- x
input_row <- function(s,type,measure,basis,value,unit,year=NA_real_,age=NA_real_,
  fleet="",survey="",sex="",season="",sampling_time=NA_real_,source_type="native_model",
  source_reference,notes="",observation_id="",length_bin=NA_real_,
  length_bin_lower=NA_real_,length_bin_upper=NA_real_,sample_size=NA_real_,
  age_error=NA_real_,partition=NA_real_) {
  make_frame(input_fields,list(assessment_id=s$assessment_id,type=type,measure=measure,basis=basis,
    fleet=fleet,survey=survey,sex=sex,region=s$region,season=season,year=year,
    year_basis="calendar_year",age=age,value=value,unit=unit,sampling_time=sampling_time,
    source_type=source_type,source_reference=source_reference,notes=notes,
    observation_id=observation_id,length_bin=length_bin,length_bin_lower=length_bin_lower,
    length_bin_upper=length_bin_upper,sample_size=sample_size,age_error=age_error,
    partition=partition),length(value))
}
output_row <- function(s,type,measure,value,unit,year=NA_real_,age=NA_real_,age_group="",
  fleet="",sex="",lwr=NA_real_,upr=NA_real_,source_type="native_model",source_reference,notes="") {
  make_frame(output_fields,list(assessment_id=s$assessment_id,type=type,measure=measure,
    fleet=fleet,sex=sex,region=s$region,year=year,age=age,age_group=age_group,
    value=value,se=NA_real_,lwr=lwr,upr=upr,unit=unit,source_type=source_type,
    source_reference=source_reference,notes=notes),length(value))
}
assumption_row <- function(s,component,setting,value,fleet="",survey="",sex="",
  source_reference,notes="") make_frame(assumption_fields,list(
    assessment_id=s$assessment_id,component=component,fleet=fleet,survey=survey,
    sex=sex,region=s$region,setting=setting,value=value,source_reference=source_reference,
    notes=notes))
sex_name <- function(x) switch(as.character(as.integer(x)),"0"="combined","1"="female","2"="male",
  stop("Unexpected sex code: ",x,call.=FALSE))
age_columns <- function(x) {
  z <- intersect(as.character(0:100),names(x))
  z[vapply(z,function(f)any(is.finite(as.numeric(x[[f]]))),logical(1L))]
}
long_age <- function(x,fields) {
  if(!nrow(x)) return(data.frame(row=integer(),age=integer(),value=numeric()))
  z <- data.frame(row=rep(seq_len(nrow(x)),each=length(fields)),
    age=rep(as.integer(fields),times=nrow(x)),
    value=as.vector(t(as.matrix(x[,fields,drop=FALSE]))))
  z[is.finite(z$value),,drop=FALSE]
}
age_group <- function(age,maximum) ifelse(age==maximum,paste0(maximum,"+"),"")

for(model in models) {
  s <- model$spec; d <- model$dat; o <- model$out
  fn <- setNames(as.character(d$fleetnames),seq_along(d$fleetnames))
  fu <- setNames(d$fleetinfo$units,seq_len(nrow(d$fleetinfo)))
  data_ref <- paste0(s$archive_url,", data.ss_new")
  for(i in seq_len(nrow(model$catch))) {
    code <- as.integer(model$catch$fleet[i]); units <- as.integer(fu[as.character(code)])
    if(!units%in%c(1L,2L)) stop("Unexpected catch unit code in ",s$region,".",call.=FALSE)
    biomass <- units==1L
    add_i(input_row(s,"catch",if(biomass)"total_biomass" else "total_numbers",
      if(biomass)"biomass" else "numbers",model$catch$catch[i],
      if(biomass)"metric tonnes" else "thousand fish",year=model$catch$year[i],
      fleet=unname(fn[as.character(code)]),season="annual",
      source_reference=paste0(data_ref,", catch data"),observation_id=paste0("catch-",i),
      notes=paste0("Native annual catch on the original scale. SS3 units code ",units,
        "; catch_se is recorded separately as a model setting.")))
  }
  if(nrow(model$cpue)) for(i in seq_len(nrow(model$cpue))) {
    survey <- "Oregon Recreational Boat Survey (ORBS)"
    add_i(input_row(s,"index","total_numbers","index_scale",model$cpue$obs[i],
      "fish per angler-hour",year=model$cpue$year[i],survey=survey,season="summer",
      source_reference=paste0(data_ref,", CPUE data"),observation_id=paste0("cpue-",i),
      notes=paste0("Aggregate standardized ORBS CPUE. Native SS3 month code ",
        model$cpue$month[i]," is preserved; fractional-year time is unresolved.")))
    add_i(input_row(s,"index","log_index_sd","log_scale",model$cpue$se_log[i],
      "log-scale standard error",year=model$cpue$year[i],survey=survey,season="summer",
      source_reference=paste0(data_ref,", CPUE se_log field"),observation_id=paste0("cpue-",i),
      notes="Native se_log retained without transformation."))
  }
  for(component in c("length","age")) {
    x <- if(component=="length") model$len else model$age
    is_age <- component=="age"
    bins <- if(is_age) 0:as.integer(d$Nages) else sort(unique(as.integer(
      sub("^[fm]","",grep("^f[0-9]+$",names(x),value=TRUE)))))
    for(j in seq_len(nrow(x))) {
      sx <- as.integer(x$sex[j])
      composition_fields <- paste0(if(sx==2L)"m" else "f",bins)
      if(length(setdiff(composition_fields,names(x))))
        stop(s$region," ",component," composition is missing bins: ",
          paste(setdiff(composition_fields,names(x)),collapse=", "),call.=FALSE)
      v <- as.numeric(unlist(x[j,composition_fields,drop=FALSE],use.names=FALSE))
      fleet <- unname(fn[as.character(abs(as.integer(x$fleet[j])))])
      if(is.na(fleet)) stop("Unmapped composition fleet in ",s$region,".",call.=FALSE)
      lower <- if(is_age) as.numeric(x$Lbin_lo[j]) else bins
      upper <- if(is_age) as.numeric(x$Lbin_hi[j]) else ifelse(bins==max(bins),NA_real_,bins+2L)
      if(is_age) { lower[lower<0] <- NA_real_; upper[upper<0] <- NA_real_ }
      add_i(input_row(s,"catch",if(is_age)"frequency_at_age" else "frequency_at_length",
        "native_frequency",v,"source frequency weight",year=x$year[j],fleet=fleet,
        sex=sex_name(sx),season=month.name[as.integer(x$month[j])],
        age=if(is_age)bins else NA_real_,length_bin=if(is_age)NA_real_ else bins,
        length_bin_lower=lower,length_bin_upper=upper,
        source_reference=paste0(s$archive_url,", data.ss_new, ",component," composition"),
        notes=if(is_age) paste("Native conditional age-at-length frequencies, not annual catch-at-age.",
          "Values are unnormalized; sex, age-error, length interval, sample size, month and partition are preserved.",
          "Negative source length bounds denote unconditioned data; age bins follow the source model.")
          else "Native unnormalized length frequencies; sex, sample size, month and partition are preserved. Final bin is open-ended.",
        observation_id=paste0(component,"-",j),sample_size=x$Nsamp[j],
        age_error=if(is_age)x$ageerr[j] else NA_real_,partition=x$part[j]))
    }
  }
  add_a(assumption_row(s,"model","software_version",model$version,source_reference=paste0(s$archive_url,", Report.sso")))
  add_a(assumption_row(s,"model","fitted_years",paste0(s$start,"-",s$end),source_reference=data_ref))
  add_a(assumption_row(s,"model","reported_output_years",paste0(min(model$annual$Yr),"-",max(model$annual$Yr)),
    source_reference=paste0(s$archive_url,", Report.sso TIME_SERIES"),
    notes="Cached machine-readable outputs include the historical series and short forecast; the assessment document discusses a longer management forecast."))
  add_a(assumption_row(s,"model","structure","One area; annual; two sexes; age-structured",
    source_reference=paste0(s$archive_url,", data.ss_new and control.ss_new")))
  add_a(assumption_row(s,"model","age_bins",paste0("0-",d$Nages," in native composition files"),
    source_reference=paste0(s$archive_url,", data.ss_new and Report.sso")))
  for(k in seq_len(nrow(d$fleetinfo))) {
    fleet <- unname(fn[as.character(k)])
    add_a(assumption_row(s,"catch","source_units",paste0("SS3 units code ",d$fleetinfo$units[k],
      if(d$fleetinfo$units[k]==1)"; biomass in metric tonnes" else "; numbers in thousand fish"),
      fleet=fleet,source_reference=paste0(s$archive_url,", data.ss_new fleet table")))
    z <- model$catch[model$catch$fleet==k,,drop=FALSE]
    if(nrow(z)) add_a(assumption_row(s,"catch","catch_se",paste(sort(unique(z$catch_se)),collapse=", "),
      fleet=fleet,source_reference=paste0(data_ref,", catch_se field"),
      notes="Native catch_se value retained as a model setting."))
  }
  if(nrow(model$cpue)) {
    survey <- "Oregon Recreational Boat Survey (ORBS)"
    add_a(assumption_row(s,"index","timing","Summer; fractional-year unresolved",survey=survey,
      source_reference=s$report_url,notes="Report describes May-September trips; archive encodes month code 7."))
    add_a(assumption_row(s,"index","error_model","Lognormal; native se_log supplied",survey=survey,
      source_reference=paste0(data_ref,", CPUE fields")))
  } else add_a(assumption_row(s,"index","abundance_index","No index observations used",
    source_reference=s$report_url,notes="The report says the Washington nearshore survey was not used because methods were unreviewed and data were not sufficiently robust."))
  add_a(assumption_row(s,"mortality","natural_mortality","Estimated by sex; age-constant surface",
    source_reference=paste0(s$archive_url,", Report.sso Natural_Mortality"),
    notes="Fitted M-at-age output is imported without age-specific uncertainty."))

  years <- model$annual$Yr; era <- model$annual$Era
  for(measure in c("total_biomass","spawning_output","recruitment")) {
    value <- switch(measure,total_biomass=model$annual$Bio_all,
      spawning_output=model$annual$SpawnBio,recruitment=model$annual$Recruit_0)
    unit <- switch(measure,total_biomass="metric tonnes",spawning_output="million eggs",recruitment="thousand fish")
    type <- if(measure=="recruitment")"recruitment" else "biomass"
    bounds <- NULL
    if(measure=="spawning_output") bounds <- if(s$code=="oregon") {
      data.frame(year=2011:2021,lwr=c(14.59,14.33,13.82,13.42,13.23,12.97,12.69,11.85,11.05,10.34,10.06),
        upr=c(40.23,39.75,39.02,38.32,37.70,36.92,36.07,34.67,33.45,32.60,32.65))
    } else data.frame(year=2011:2021,lwr=rep(NA_real_,11),
      upr=c(3.89,3.94,3.98,4.02,4.06,4.08,4.13,4.15,4.14,3.99,4.00))
    if(measure=="recruitment") bounds <- if(s$code=="oregon") {
      data.frame(year=2011:2021,lwr=c(3.07,12.48,4.34,15.11,36.66,3.82,4.59,4.53,4.51,4.48,4.89),
        upr=c(14.55,43.01,21.42,65.28,167.13,35.39,49.17,48.24,48.02,47.84,50.88))
    } else data.frame(year=2011:2021,lwr=c(.72,.42,.38,.42,.45,.50,.53,.52,.52,.51,.51),
      upr=c(12.36,7.56,6.93,7.77,8.47,9.95,10.53,10.56,10.56,10.55,10.55))
    lower <- upper <- rep(NA_real_,length(value))
    source_type <- rep("native_model",length(value))
    source_ref <- rep(paste0(s$archive_url,", Report.sso TIME_SERIES"),length(value))
    idx <- match(years,bounds$year); ok <- !is.na(idx)
    lower[ok] <- bounds$lwr[idx[ok]]; upper[ok] <- bounds$upr[idx[ok]]
    source_type[ok] <- "official_document"
    source_ref[ok] <- paste0(s$report_url," Table ",if(measure=="spawning_output")"II" else "III",
      "; point estimate from Report.sso TIME_SERIES")
    note <- switch(measure,
      total_biomass="Report.sso Bio_all; model biomass in metric tonnes from native catch and weight scales.",
      spawning_output="Report.sso SpawnBio; egg-based spawning output in millions of eggs, not spawning biomass.",
      recruitment="Report.sso Recruit_0; age-0 recruitment in thousands of fish.")
    if(measure=="spawning_output"&&s$code=="washington")
      note <- paste(note,"Report lower limits are <0.01 and remain unavailable as numeric lower bounds.")
    else note <- paste(note,"Reported intervals are retained without converting them to standard errors.")
    add_o(output_row(s,type,measure,value,unit,year=years,lwr=lower,upr=upper,
      source_type=source_type,source_reference=source_ref,notes=note))
  }

  ages <- as.character(0:as.integer(d$Nages))
  for(def in list(
    list(data=o$natage,type="population",measure="numbers_at_age",unit="thousand fish"),
    list(data=o$batage,type="biomass",measure="biomass_at_age",unit="metric tonnes"))) {
    x <- def$data
    x <- x[x$Area==1&x$Bio_Pattern==1&x$Sex%in%1:2&x$Morph==x$Sex&
      x$BirthSeas==1&x$Settlement==1&x$Platoon==1&x$Seas==1&
      x[["Beg/Mid"]]=="B"&x$Era%in%c("TIME","FORE")&x$Yr>=s$start,,drop=FALSE]
    z <- long_age(x,age_columns(x))
    add_o(output_row(s,def$type,def$measure,z$value,def$unit,
      year=x$Yr[z$row],age=z$age,age_group=age_group(z$age,d$Nages),
      sex=ifelse(x$Sex[z$row]==1,"female","male"),
      source_type="native_model",
      source_reference=paste0(s$archive_url,", Report.sso ",
        if(def$measure=="numbers_at_age")"NUMBERS_AT_AGE" else "BIOMASS_AT_AGE"),
      notes="Fitted beginning-of-year age surface, not an observed input. Age-specific uncertainty is unavailable."))
  }
  x <- o$fatage
  x <- x[x$Area==1&x$Fleet%in%seq_len(nrow(d$fleetinfo))&x$Sex%in%1:2&
    x$Morph==x$Sex&x$Seas==1&x$Era%in%c("TIME","FORE")&x$Yr>=s$start,,drop=FALSE]
  z <- long_age(x,age_columns(x))
  add_o(output_row(s,"mortality","fishing_mortality_at_age",z$value,"per year",
    year=x$Yr[z$row],age=z$age,age_group=age_group(z$age,d$Nages),
    fleet=unname(fn[as.character(x$Fleet[z$row])]),sex=ifelse(x$Sex[z$row]==1,"female","male"),
    source_type="native_model",
    source_reference=paste0(s$archive_url,", Report.sso F_AT_AGE"),
    notes="Fitted F-at-age by source fleet and sex; forecast rows retain source Era; uncertainty is unavailable."))
  x <- o$M_at_age
  x <- x[x$Bio_Pattern==1&x$Sex%in%1:2&x$Yr>=s$start&x$Yr<=s$end,,drop=FALSE]
  z <- long_age(x,age_columns(x))
  add_o(output_row(s,"mortality","natural_mortality_at_age",z$value,"per year",
    year=x$Yr[z$row],age=z$age,sex=ifelse(x$Sex[z$row]==1,"female","male"),
    source_reference=paste0(s$archive_url,", Report.sso Natural_Mortality"),
    notes="Fitted sex-specific natural-mortality output; no age-specific uncertainty was recovered."))

  pop <- o$natage
  pop <- pop[pop$Area==1&pop$Bio_Pattern==1&pop$Sex%in%1:2&pop$Morph==pop$Sex&
    pop$BirthSeas==1&pop$Settlement==1&pop$Platoon==1&pop$Seas==1&
    pop[["Beg/Mid"]]=="B"&pop$Era%in%c("TIME","FORE")&pop$Yr>=s$start,,drop=FALSE]
  total_n <- aggregate(rowSums(pop[,ages,drop=FALSE],na.rm=TRUE),list(year=pop$Yr),sum)
  names(total_n)[2] <- "value"
  add_o(output_row(s,"population","total_numbers",total_n$value,"thousand fish",
    year=total_n$year,source_type="derived_source_output",
    source_reference=paste0(s$archive_url,", Report.sso NUMBERS_AT_AGE"),
    notes="Derived by summing beginning-of-year N-at-age over sexes and source age bins; no uncertainty was calculated."))

  w <- o$wtatage
  w <- w[w$year>=s$start&w$year<=max(model$annual$Yr)&w$seas==1&
    w$sex%in%1:2&w$bio_pattern==1&w$birthseas==1,,drop=FALSE]
  for(code in sort(unique(w$fleet))) {
    x <- w[w$fleet==code,,drop=FALSE]; z <- long_age(x,age_columns(x))
    if(code==-2) {
      measure<-"maturity_fecundity_at_age"; fleet<-"maturity*fecundity"
      unit<-"native SS3 maturity-fecundity scale"; note<-"Generated maturity*fecundity, not maturity proportion or observed input."
    } else if(code==-1) {
      measure<-"weight_at_age"; fleet<-"mid-season population"
      unit<-"kg per fish"; note<-"Generated mid-season population weight-at-age."
    } else if(code==0) {
      measure<-"start_weight_at_age"; fleet<-"beginning-season population"
      unit<-"kg per fish"; note<-"Generated beginning-of-year population weight-at-age."
    } else {
      measure<-"catch_weight_at_age"; fleet<-unname(fn[as.character(code)])
      unit<-"kg per fish"; note<-"Generated fishery-specific weight-at-age."
    }
    add_o(output_row(s,"biology",measure,z$value,unit,year=x$year[z$row],
      age=z$age,age_group=age_group(z$age,d$Nages),fleet=fleet,
      sex=ifelse(x$sex[z$row]==1,"female","male"),
      source_reference=paste0(s$archive_url,", wtatage.ss_new, fleet code ",code),
      notes=paste(note,"Fitted model output, not an observed annual input series.")))
  }
}

inputs <- do.call(rbind,inputs); outputs <- do.call(rbind,outputs); assumptions <- do.call(rbind,assumptions)
key <- paste(inputs$assessment_id,inputs$type,inputs$measure,inputs$fleet,inputs$survey,
  inputs$sex,inputs$year,inputs$age,inputs$length_bin,inputs$observation_id,sep="|")
if(anyDuplicated(key)) stop("Proposed inputs contain duplicate source-record keys.",call.=FALSE)
stocks <- read_table(file.path(database,"stocks.csv"))
assessments <- read_table(file.path(database,"assessments.csv"))
candidates <- read_table(candidate_path); inventory <- read_table(inventory_path); selected <- read_table(selected_path)
candidate_ids <- vapply(specs,function(x)x$candidate_id,character(1L))
assessment_ids <- vapply(specs,function(x)x$assessment_id,character(1L))
cr <- which(candidates$candidate_id%in%candidate_ids)
ir <- which(inventory$unit_key==paste0("candidate:",stock_id))
sr <- which(selected$candidate_unit_id==stock_id)
if(length(cr)!=2L||length(ir)!=1L||length(sr)!=1L||
  any(candidates$eligibility[cr]!="eligible")||
  any(!candidates$import_status[cr]%in%c("not_started","partial"))||
  any(candidates$match_status[cr]!="new"))
  stop("Selected OR/WA candidate or batch state is missing or changed.",call.=FALSE)
if(any(stocks$stock_id==stock_id)||any(assessments$assessment_id%in%assessment_ids))
  stop("OR/WA source records already exist; inspect before import.",call.=FALSE)
read_assessment_rows <- function(path,ids) {
  con<-file(path,"rt"); on.exit(close(con)); header<-readLines(con,n=1L,warn=FALSE)
  prefixes<-paste0('"',ids,'",'); selected<-character()
  repeat {
    block<-readLines(con,n=100000L,warn=FALSE); if(!length(block)) break
    keep<-vapply(block,function(line)any(startsWith(line,prefixes)),logical(1L))
    if(any(keep)) selected<-c(selected,block[keep])
  }
  if(!length(selected)) return(read.csv(text=header,stringsAsFactors=FALSE,check.names=FALSE,na.strings=c("","NA")))
  read.csv(text=paste(c(header,selected),collapse="\n"),stringsAsFactors=FALSE,check.names=FALSE,na.strings=c("","NA"))
}
if(!dry_run) for(path in c(file.path(database,"inputs.csv"),file.path(database,"outputs.csv")))
  if(nrow(read_assessment_rows(path,assessment_ids))>0L)
    stop("OR/WA component rows already exist in ",basename(path),".",call.=FALSE)

stock <- make_frame(stock_fields,list(stock_id=stock_id,charbonneau_id="",authority="NOAA-NWFSC",
  authority_stock_id="15338; 15339",scientific_name="Sebastes miniatus",
  common_name="Vermilion rockfish (OR/WA)",area="Oregon and Washington",
  region="Oregon and Washington",ocean="Northeast Pacific",
  notes="Current OR/WA managed stock. NOAA Stock SMART IDs 15338 (Oregon) and 15339 (Washington) identify separate 2021 component assessments; their estimates are not pooled."))
assessment_rows <- do.call(rbind,lapply(models,function(m) {
  s<-m$spec
  make_frame(assessment_fields,list(assessment_id=s$assessment_id,stock_id=stock_id,
    assessment_year=2021L,terminal_year=2020L,estimate_terminal_year=max(m$annual$Yr),
    assessment_type="full_assessment",model_family="Stock Synthesis",
    model_version=m$version,is_current=TRUE,is_applied=TRUE,framework_year=2021L,
    assessment_url=s$report_url,
    framework_url="https://www.pcouncil.org/documents/2021/10/vermilion-and-sunset-rockfishes-stock-assessment-review-star-panel-report.pdf/",
    data_url=s$archive_url,model_url=s$archive_url,
    repository_url="https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
    assumptions_status="partial",inputs_status="partial",outputs_status="partial",
    notes=paste0("Official 2021 ",s$region," production model fitted through 2020, kept separate under one current OR/WA stock. Report.sso trajectories extend through ",max(m$annual$Yr),"; age-specific uncertainty is unavailable. Raw compositions are not converted to annual observed catch-at-age or index-at-age.")))
}))
append_rows <- function(path,rows) {
  fields<-read_fields(path)
  if(length(setdiff(fields,names(rows)))) stop("Rows do not match ",basename(path),".",call.=FALSE)
  if(nrow(rows)) utils::write.table(rows[fields],path,sep=",",row.names=FALSE,col.names=FALSE,
    quote=TRUE,qmethod="double",na="",append=TRUE,eol="\n")
}
write_table <- function(path,x) {
  temp<-tempfile(fileext=".csv"); on.exit(unlink(temp),add=TRUE)
  utils::write.table(x,temp,sep=",",row.names=FALSE,col.names=TRUE,quote=TRUE,
    qmethod="double",na="",eol="\n")
  if(!file.copy(temp,path,overwrite=TRUE)) stop("Could not update ",basename(path),".",call.=FALSE)
}
for(i in cr) {
  s<-specs[[match(candidates$candidate_id[i],candidate_ids)]]
  candidates$matched_stock_id[i]<-stock_id; candidates$match_status[i]<-"matched"; candidates$import_status[i]<-"partial"
  candidates$catch_age_evidence[i]<-paste0("The 2021 ",s$region," archive catch, length and conditional age-at-length inputs are imported. Catch-at-age is not a direct annual input.")
  candidates$survey_age_evidence[i]<-if(s$code=="oregon")
    "Oregon uses aggregate ORBS CPUE (2001-2020); age-specific index observations are unavailable. Washington has no index."
    else "Washington has no abundance index; the nearshore survey was not used. Oregon CPUE remains a separate aggregate component."
  candidates$weights_evidence[i]<-"Sex-specific weight-at-length assumptions and generated weight-at-age outputs are separate; fitted surfaces are not observed inputs."
  candidates$maturity_evidence[i]<-"Maturity is specified at length; generated maturity-fecundity output is not a maturity proportion."
  candidates$mortality_evidence[i]<-"Natural mortality is estimated by sex; fitted M-at-age outputs are imported where finite, without age-specific uncertainty."
  candidates$timing_evidence[i]<-if(s$code=="oregon")
    "ORBS is summer (May-September); source month code 7 is preserved, but fractional-year timing is unresolved."
    else "Annual model; no abundance index. Fishery composition month codes are preserved."
  candidates$output_evidence[i]<-"Report.sso includes N-at-age, biomass-at-age, F-at-age, M-at-age and annual biomass, recruitment and egg-based spawning output through 2022; reports provide selected aggregate intervals."
  candidates$review_date[i]<-"2026-11-12"
  candidates$decision_reason[i]<-"Current OR/WA stock source-curated from separate official 2021 Oregon and Washington assessments and model archives."
  candidates$notes[i]<-"Partial import completed. Keep component assessments separate; raw catch/composition rows are inputs and fitted age-specific values are outputs only."
}
inventory$matched_stock_id[ir]<-stock_id; inventory$import_status[ir]<-"partial"
selected$curation_status[sr]<-"partial_source_import"
if(!dry_run) {
  append_rows(file.path(database,"stocks.csv"),stock)
  append_rows(file.path(database,"assessments.csv"),assessment_rows)
  append_rows(file.path(database,"inputs.csv"),inputs)
  append_rows(file.path(database,"outputs.csv"),outputs)
  append_rows(file.path(database,"assumptions.csv"),assumptions)
  write_table(candidate_path,candidates); write_table(inventory_path,inventory); write_table(selected_path,selected)
}
cat(if(dry_run)"Dry run: " else "Imported ","one OR/WA stock, two component assessments; ",
  nrow(inputs)," inputs, ",nrow(assumptions)," assumptions, ",nrow(outputs)," outputs.\n",sep="")
for(m in models) {
  id<-m$spec$assessment_id
  cat("  ",m$spec$region,": ",sum(inputs$assessment_id==id)," inputs, ",
    sum(outputs$assessment_id==id)," outputs\n",sep="")
}
cat("No fitted catch-at-age or age-specific index was stored as observed input.\n")

