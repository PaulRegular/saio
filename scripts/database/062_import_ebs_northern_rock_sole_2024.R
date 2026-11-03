source("scripts/database/pacific_tables.R")
source("scripts/database/nrs_report_tables.R")
id <- "afsc_northern_rock_sole_ebs_2024"
cache <- "source_cache/afsc_northern_rock_sole_ebs"
revision <- jsonlite::fromJSON(file.path(cache,"repository_revision.json"))$sha
repository <- "https://github.com/noaa-afsc/BSAI_NRS"
reference <- paste0(repository,"/tree/",revision,"/2024/model_runs/model_24.2")
report <- "https://files.npfmc.org/SAFE/2024/BSAIrocksole.pdf"
x <- nrs_report_tables(file.path(cache,"assessment_2024.pdf"))
raw <- readLines(file.path(cache,"native/c3.dat"),warn=FALSE)
after <- function(pattern,n) {
  at <- grep(pattern,raw)
  stopifnot(length(at)==1)
  scan(text=paste(raw[seq.int(at+1L,length(raw))],collapse="\n"),
    nmax=n,comment.char="#",quiet=TRUE)
}
years <- 1975:2024
ages <- 1:20
stopifnot(tail(x$ssb[,2],1)==271.988,tail(x$biomass[,2],1)==1051.04)
input <- function(type,measure,basis,value,unit,year=NA_integer_,age=NA_integer_,
                  sex="combined",fleet="",survey="",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,
    basis=basis,value=value,unit=unit,year=year,age=age,sex=sex,fleet=fleet,survey=survey,
    region="EBS",year_basis=ifelse(is.na(year),"","calendar_year"),
    source_type="native_model",source_reference=reference,...)
}
survey_years <- after("^#[[:space:]]*yrs_srv[[:space:]]",42)
inputs <- list(
  input("catch","total_biomass","biomass",after("^#catch_bio",50),"thousand t",years,fleet="Fishery"),
  input("index","total_biomass","biomass",after("^#[[:space:]]*obs_srv[[:space:]]",42),
    "thousand t",survey_years,survey="EBS_bottom_trawl",sampling_time=.5),
  input("index","index_sd","index_scale",after("^#[[:space:]]*obs_se_srv[[:space:]]",42),
    "thousand t",survey_years,survey="EBS_bottom_trawl",
    notes="Supplied natural-scale survey SE; log SD is sqrt(log(1+(SE/observation)^2)).")
)
for(type in c("catch","index")) {
  yy <- after(if(type=="catch")"^#[[:space:]]*yrs_fsh_age_split" else "^#[[:space:]]*yrs_srv_age[[:space:]]",if(type=="catch")42 else 44)
  p <- matrix(after(if(type=="catch")"^#[[:space:]]*Year[[:space:]]+Sex[[:space:]]+oac_fsh" else "^#[[:space:]]*_oac_srv",length(yy)*40),length(yy),40,byrow=TRUE)
  size <- after(if(type=="catch")"^#[[:space:]]*nsmpl_fsh_age" else "^#[[:space:]]*nsmpl_srv[[:space:]]",length(yy))
  stopifnot(max(abs(rowSums(p)-1))<.002)
  p <- p/rowSums(p)
  inputs[[length(inputs)+1]] <- input(type,"proportion_at_age","proportion_numbers",
    as.vector(p),"proportion",rep(yy,40),rep(rep(ages,2),each=length(yy)),
    sex=rep(c("female","male"),each=length(yy)*20),
    fleet=if(type=="catch")"Fishery" else "",survey=if(type=="index")"EBS_bottom_trawl" else "",
    observation_id=paste(type,rep(yy,40),sep=":"),sample_size=rep(size,40),
    sampling_time=if(type=="index")0 else NA_real_,
    transformation="Native code normalizes each joint-sex input row to one; supplied rounded cells normalized jointly, never within each sex.",
    notes="Original joint-sex age sample, not abundance. Supplied likelihood sample_size retained; source composition weights differ from raw fish/haul counts. Biomass index uses mid-year N, but source age proportions use begin-year N.")
}
catch_weights <- matrix(after("^#[[:space:]]*wt_fsh[[:space:]]",50*40),50,40,byrow=TRUE)
for(s in 1:2) {
  sex <- c("female","male")[s]
  for(type in c("weight","survey_weight","catch_weight")) {
    value <- if(type=="catch_weight") catch_weights[,if(s==1)1:20 else 21:40] else {
      pattern <- if(type=="weight")paste0("^#[[:space:]]*wt_pop_",sex,"s") else
        if(s==1)"^#[[:space:]]*wt_srv[[:space:]]+females" else "^#[[:space:]]*wt_srv_Males"
      matrix(after(pattern,50*20),50,20,byrow=TRUE)
    }
    dimnames(value) <- list(years,ages)
    z <- pacific_matrix_long(value)
    inputs[[length(inputs)+1]] <- input(if(type=="survey_weight")"weight" else type,
      "weight_at_age","kg_per_fish",z$value,"kg/fish",z$year,z$age,sex,
      fleet=if(type=="catch_weight")"Fishery" else "",
      survey=if(type=="survey_weight")"EBS_bottom_trawl" else "",
      notes="Original empirical weight surface in kg, Growth_Option=1; original zeros and terminal repeated weights retained.")
  }
}
mat <- after("^#[[:space:]]*maturity[[:space:]]",50*20)
inputs[[length(inputs)+1]] <- input("maturity","maturity_at_age","proportion",as.vector(t(matrix(mat,50,20,byrow=TRUE))),
  "proportion",rep(years,each=20),rep(ages,50),"female",
  notes="Original female maturity; spawning month 2, fraction 1/12; no second female-fraction multiplier.")
output <- function(type,measure,value,unit,year=NA_integer_,age=NA_integer_,
                   sex="combined",se=NA_real_,...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,
    unit=unit,year=year,age=age,sex=sex,se=se,region="EBS",source_type="official_table",
    source_reference=paste0(report,"; Tables 8.14 and 8.17-8.24, Model 24.2 columns"),...)
}
outputs <- list()
for(s in 1:2) {
  sex <- c("female","male")[s]
  n <- pacific_matrix_long(x$n[[s]])
  f <- pacific_matrix_long(x$f[[s]])
  outputs[[length(outputs)+1]] <- output("population","numbers_at_age",n$value,"million fish",n$year,n$age,sex,
    age_group=ifelse(n$age==20,"20+",""),notes="Sex-specific begin-year MPD; printed in whole millions. Zero cells are report rounding, not evidence of a zero latent state.")
  z <- output("mortality","fishing_mortality_at_age",f$value,"per year",f$year,f$age,sex,
    age_group=ifelse(f$age==20,"20+",""),
    notes="Derived from rounded reported parameters: F=exp(-2.348+annual F deviation)*logistic{mean slope*exp(slope deviation)*(min(age,17)-mean a50*exp(a50 deviation))}; male F additionally times exp(-.110). No joint covariance, so no derived SE.")
  z$source_type <- "derived_source_output"
  outputs[[length(outputs)+1]] <- z
  outputs[[length(outputs)+1]] <- output("mortality","natural_mortality_at_age",c(.192,.226)[s],
    "per year",rep(years,20),rep(ages,each=50),sex,se=c(.003,.004)[s],
    notes="Estimated constant sex-specific M, Table 8.14 Model 24.2. Natural-scale marginal SE, rounded. Prior mean .15 and log width .2; both sexes active.")
}
for(name in c("ssb","biomass","recruitment")) {
  z <- x[[name]]
  outputs[[length(outputs)+1]] <- output(if(name=="recruitment")"recruitment" else "biomass",
    c(ssb="SSB",biomass="total_biomass",recruitment="recruitment")[[name]],z[,2],
    if(name=="recruitment")"million fish" else "thousand t",z[,1],
    age=if(name=="recruitment")1 else NA_integer_,sex=if(name=="ssb")"female" else "combined",se=z[,3],
    notes=paste("Model 24.2 MPD and natural-scale asymptotic SE; no intervals invented.",
      if(name=="ssb")"February 1 female spawning biomass." else if(name=="recruitment")"Combined-sex age-1 recruitment." else "All-age combined-sex biomass."))
}
outputs[[length(outputs)+1]] <- output("catchability","q",1.633,"index multiplier",survey="EBS_bottom_trawl",se=.050,
  notes="Estimated scalar survey q with prior mean 1.5 and log width .2; age selectivity remains separate.")
assume <- function(component,setting,value,ref=reference) pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=ref)
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2024 SSC-selected Model 24.2, ADMB flatfish model; both female and male M estimated"),
  assume("population","dimensions","1975-2024, ages 1-20+, female/male; one fishery and one EBS shelf bottom-trawl biomass index"),
  assume("N","process","Deterministic sex-specific survival; equal recruitment sex ratio and independent initial-age parameters"),
  assume("recruitment","process","Estimated Ricker relationship, lag 1, 1978-2018; fixed recruitment log SD .6; additional IID log deviations"),
  assume("F","process","Annual intensity times sex-specific logistic selectivity; annual log deviations in slope and a50; ages 17+ shared; estimated male multiplicative offset"),
  assume("M","process","Female and male constants estimated in phases 5 and 6; report describes lognormal M prior mean .15, log width .2; female penalty corroborated in pinned framework; male penalty activation unresolved",
    paste(reference,"https://github.com/noaa-afsc/flatfish_assessment_code/blob/9709548fafc7d69a2e3f88f80f60c74b7d3cfb0e/src/fm.tpl",sep="; ")),
  assume("q","process","Estimated scalar with lognormal prior mean 1.5, log width .2; sex-specific logistic age selectivity; temperature q effects inactive (negative phases)"),
  assume("index","observation_model","Lognormal biomass at .5 with supplied SE; joint-sex multinomial age proportions use begin-year N; Francis weights from supplied native sample sizes"),
  assume("catch","observation_model","Annual log-biomass residual sum of squares with lambda 300; separate joint-sex age multinomial and supplied input sample sizes"),
  assume("biology","weights","Growth_Option 1: original empirical kg/fish surfaces; growth and temperature growth phases inactive; source zero weights retained"),
  assume("biology","SSB_definition","Female N times supplied female maturity and population weight with survival to February 1, time 1/12"),
  assume("source","framework_verification","Pinned flatfish_assessment_code/src/fm.tpl confirms mortality, sex-specific logistic selectivity and SSB equations; report Tables 8.14 and 8.17-8.24 supply current parameters and outputs")
))
stock <- pacific_database_row("stocks",stock_id="afsc_northern_rock_sole_ebs",
  charbonneau_id="AFSC_EEBSAI_Lepidopsetta_polyxystra",authority="NOAA-AFSC",authority_stock_id="BSAI northern rock sole",
  scientific_name="Lepidopsetta polyxystra",common_name="Eastern Bering Sea northern rock sole",
  area="Eastern Bering Sea assessment area",region="Alaska",ocean="Northeast Pacific")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2024,terminal_year=2024,estimate_terminal_year=2024,assessment_type="full",
  model_family="ADMB",model_version="Model 24.2",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,data_url=reference,model_url=reference,repository_url=repository,
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Current production inputs and final SAFE Model 24.2 outputs; both sexes retained. F derived from reported rounded parameters and native equations, not inferred from rounded N. Full covariance, ageing error and inactive auxiliary input arrays remain unexported.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
