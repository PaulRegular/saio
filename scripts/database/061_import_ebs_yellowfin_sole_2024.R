source("scripts/database/pacific_tables.R")
id <- "afsc_yellowfin_sole_ebs_2024"
cache <- "source_cache/afsc_yellowfin_sole_ebs"
revision <- jsonlite::fromJSON(file.path(cache,"repository_revision.json"))$sha
repository <- "https://github.com/afsc-assessments/BSAI_YFS"
reference <- paste0(repository,"/tree/",revision,"/m23_0_2024")
report <- "https://files.npfmc.org/SAFE/2024/BSAIyfin.pdf"
lines <- readLines(file.path(cache,"native/fm.rep"),warn=FALSE)
labels <- grep("^[A-Za-z#]",lines)
block <- function(label) {
  at <- which(trimws(lines)==label)[1]
  if (is.na(at)) cli::cli_abort("Missing production-report label: {label}.")
  end <- min(c(labels[labels>at]-1L,length(lines)))
  scan(text=paste(lines[seq.int(at+1L,end)],collapse="\n"),quiet=TRUE)
}
raw <- readLines(file.path(cache,"native/yfs_2024_EBSNBS_VAST.dat"),warn=FALSE)
after <- function(pattern,n) {
  at <- grep(pattern,raw)
  stopifnot(length(at)==1)
  scan(text=paste(raw[seq.int(at+1L,length(raw))],collapse="\n"),
    nmax=n,comment.char="#",quiet=TRUE)
}
years <- 1954:2024
ages <- 1:20
matrix_block <- function(label) matrix(block(label),length(years),20,byrow=TRUE,
  dimnames=list(years,ages))
ssb <- matrix(block("SSB"),ncol=5,byrow=TRUE)
biomass <- matrix(block("TotBiom"),ncol=5,byrow=TRUE)
recruitment <- matrix(block("R"),ncol=5,byrow=TRUE)
stopifnot(identical(block("Yr"),as.numeric(years)),tail(ssb[,2],1)==751.023,
  tail(biomass[,2],1)==2412.52,block("natmort_f")==.12,
  block("natmort_m")==.127699)
input <- function(type,measure,basis,value,unit,year=NA_integer_,age=NA_integer_,
                  sex="combined",fleet="",survey="",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,
    basis=basis,value=value,unit=unit,year=year,age=age,sex=sex,fleet=fleet,survey=survey,
    region="EBS",year_basis=ifelse(is.na(year),"","calendar_year"),
    source_type="native_model",source_reference=reference,...)
}
inputs <- list(input("catch","total_biomass","biomass",
  after("^#obs_catch",71),"thousand t",years,fleet="Fishery"),
  input("index","total_biomass","biomass",after("^#[[:space:]]*obs_srv[[:space:]]",42),
    "thousand t",block("yrs_srv"),survey="EBS_NBS_VAST",sampling_time=.5),
  input("index","index_sd","index_scale",after("^#[[:space:]]*obs_se_srv[[:space:]]",42),
    "thousand t",block("yrs_srv"),survey="EBS_NBS_VAST",
    notes="Supplied natural-scale SD; model log SD is sqrt(log(1+(SD/observation)^2))."),
  input("M","natural_mortality_at_age","per_year",.12,"per year",age=ages,sex="female",
    notes="Female M fixed, phase -6; male M is estimated and belongs in outputs.")
)
composition <- function(label,year_label,type,size,sexed) {
  yy <- block(year_label)
  p <- matrix(block(label),length(yy),if(sexed)40 else 20,byrow=TRUE)
  stopifnot(max(abs(rowSums(p)-1)) < 1e-5)
  out <- input(type,"proportion_at_age","proportion_numbers",as.vector(p),"proportion",
    rep(yy,ncol(p)),rep(rep(ages,if(sexed)2 else 1),each=length(yy)),
    sex=if(sexed) rep(c("female","male"),each=length(yy)*20) else "combined",
    fleet=if(type=="catch")"Fishery" else "",survey=if(type=="index")"EBS_NBS_VAST" else "",
    observation_id=paste(label,rep(yy,ncol(p)),sep=":"),sample_size=rep(size,ncol(p)),
    sampling_time=if(type=="index")0 else NA_real_,
    notes="Actual normalized likelihood input recovered from the production fm.rep echo because the published data file has malformed decimal tokens. Joint sexes sum together to one. Survey composition prediction uses begin-year N, whereas survey biomass uses mid-year survival. Native sample sizes retained, not estimated effective sizes.")
  out$source_type <- "reconstructed_source_input"
  out$transformation <- "Recover the actual normalized observed oac input from the production report echo; no eac predictions or guessed decimal corrections."
  out
}
inputs[[length(inputs)+1]] <- composition("oac_fsh_c","yrs_fsh_age_c","catch",
  after("^#nsmpl_fsh_age",11),FALSE)
inputs[[length(inputs)+1]] <- composition("oac_fsh_s","yrs_fsh_age_s","catch",block("nsmpl_fsh_s"),TRUE)
inputs[[length(inputs)+1]] <- composition("oac_srv_s","yrs_srv_age_s","index",block("nsmpl_srv_s"),TRUE)
for (s in c("f","m")) {
  sex <- if(s=="f")"female" else "male"
  for (spec in list(c("weight","wt_pop_"),c("catch_weight","wt_fsh_"),c("survey_weight","wt_srv_"))) {
    label <- if(spec[1]=="catch_weight")paste0("wt_fsh_",s,"_in") else paste0(spec[2],s)
    z <- pacific_matrix_long(matrix_block(label))
    if(spec[1]=="weight") {
      original <- after(paste0("^#[[:space:]]*wt_pop[_ ]",sex,"s?"),1420)
      stopifnot(max(abs(original-block(label)))<1e-8)
    }
    original <- if(spec[1]=="catch_weight") {
      raw_weights <- matrix(after("^#wt_fsh_in",71*40),71,40,byrow=TRUE)
      raw_weights[,if(s=="f")1:20 else 21:40]
    } else {
      pattern <- if(spec[1]=="weight")paste0("^#[[:space:]]*wt_pop[_ ]",sex,"s?") else
        paste0("^#[[:space:]]*wt_srv_",if(s=="f")"Females" else "Males")
      matrix(after(pattern,71*20),71,20,byrow=TRUE)
    }
    stopifnot(max(abs(original-matrix_block(label)))<.01)
    z$value <- as.vector(original)
    inputs[[length(inputs)+1]] <- input(if(spec[1]=="survey_weight")"weight" else spec[1],
      "weight_at_age","kg_per_fish",z$value,"g/fish",z$year,z$age,sex=sex,
      fleet=if(spec[1]=="catch_weight")"Fishery" else "",
      survey=if(spec[1]=="survey_weight")"EBS_NBS_VAST" else "",
      notes="Original empirical weight surface, Growth_Option=1. Source zeros retained; no growth estimates or positive replacements substituted.")
  }
}
z <- pacific_matrix_long(matrix_block("maturity"))
inputs[[length(inputs)+1]] <- input("maturity","maturity_at_age","proportion",z$value,
  "proportion",z$year,z$age,sex="female",notes="Supplied female maturity; May 1 spawning, fraction 4/12. No half-sex multiplier inside the female SSB definition.")
for (spec in c(temperature="^#Temperature",start_date="^#startdatedev",interaction="^#Interaction")) {
  name <- names(c(temperature="^#Temperature",start_date="^#startdatedev",interaction="^#Interaction"))[match(spec,c("^#Temperature","^#startdatedev","^#Interaction"))]
  inputs[[length(inputs)+1]] <- input("covariate","environmental_covariate","native_covariate",
    after(spec,42),"native covariate",block("yrs_srv"),survey="EBS_NBS_VAST",
    observation_id=name,notes=paste(name,"covariate supplied to log q; source centers each supplied column over index years. Interaction retained as supplied, not recomputed."))
}
output <- function(type,measure,value,unit,year=NA_integer_,age=NA_integer_,sex="combined",se=NA_real_,...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,
    unit=unit,year=year,age=age,sex=sex,se=se,region="EBS",source_type="native_model",
    source_reference=reference,...)
}
outputs <- list()
for(s in c("f","m")) for(spec in list(c("natage_","population","numbers_at_age","billion fish"),
    c("F_","mortality","fishing_mortality_at_age","per year"))) {
  z <- pacific_matrix_long(matrix_block(paste0(spec[1],s)))
  outputs[[length(outputs)+1]] <- output(spec[2],spec[3],z$value,spec[4],z$year,z$age,
    if(s=="f")"female" else "male",age_group=ifelse(z$age==20,"20+",""),
    notes="Begin-year sex-specific MPD state; no marginal state uncertainty reported.")
}
for(spec in list(c("SSB","biomass","SSB"),c("TotBiom","biomass","total_biomass"),c("R","recruitment","recruitment"))) {
  z <- matrix(block(spec[1]),ncol=5,byrow=TRUE)
  outputs[[length(outputs)+1]] <- output(spec[2],spec[3],z[,2],
    if(spec[1]=="R")"billion fish" else "thousand t",z[,1],
    age=if(spec[1]=="R")1 else NA_integer_,sex=if(spec[1]=="SSB")"female" else "combined",
    se=z[,3],lwr=z[,4],upr=z[,5],notes=paste("MPD; natural-scale marginal SE and approximate 95% lognormal limits using +/-2 log SD from native code, not 1.96.",
      if(spec[1]=="SSB")"May 1 female spawning biomass." else if(spec[1]=="TotBiom")"Code sums N times population weight over all modeled ages; report calls this age-2+ biomass." else "Combined-sex age-1 recruitment."))
}
std <- read.table(file.path(cache,"native/fm.std"),header=TRUE)
outputs[[length(outputs)+1]] <- output("mortality","natural_mortality_at_age",block("natmort_m"),
  "per year",rep(years,20),rep(ages,each=71),"male",se=std$std.dev[std$name=="natmort_m"],
  notes="One estimated male M, phase 7, prior mean .12 and log-scale width .8. Repeated to show its constant state surface; female fixed M remains an input.")
q <- matrix(block("q"),ncol=5,byrow=TRUE)
outputs[[length(outputs)+1]] <- output("catchability","q",q[,2],"index multiplier",block("yrs_srv"),
  survey="EBS_NBS_VAST",se=q[,3],lwr=q[,4],upr=q[,5],
  notes="Annual scalar q from estimated temperature, start-date and interaction effects; not the age-selectivity curve. Report first column indexes survey observations, mapped to yrs_srv.")
assume <- function(component,setting,value,notes="") pacific_database_row("assumptions",
  assessment_id=id,component=component,setting=setting,value=value,source_reference=reference,notes=notes)
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2024 Model 23.0, ADMB fm, m23_0_2024; matches final SAFE SSB 751023 t and biomass 2412520 t"),
  assume("population","dimensions","1954-2024, ages 1-20+, female/male, one fishery and one EBS+NBS VAST biomass survey"),
  assume("N","process","Deterministic sex-specific survival; equal recruitment sex ratio; free initial abundance parameters activated"),
  assume("recruitment","process","Ricker estimated alpha/beta, recruitment lag 1; relationship penalty 1978-2018; fixed log SD .6; other years have IID recruitment deviations around a mean"),
  assume("F","process","Annual intensity and ascending logistic fishery age selectivity with time deviations; male offsets fixed negative phase; ages 17+ share selectivity"),
  assume("M","process","Female fixed .12; male estimated .127699 under lognormal prior mean .12, log width .8"),
  assume("q","process","log q = alpha + three centered supplied covariates times estimated beta; temperature, survey start-date anomaly and their supplied interaction; log alpha parameter phase 4, betas phase 5"),
  assume("index","observation_model","Biomass lognormal with supplied natural-scale SE converted to log SD; biomass prediction at time .5; joint-sex age composition prediction at time 0"),
  assume("catch","observation_model","Annual biomass sum-of-squares on log scale, lambda 300; separate multinomial age compositions, supplied fishery split-sex N=21.5"),
  assume("observation","composition_weights","Survey supplied Francis-weighted haul counts; fishery N=21.5; 0.001 offsets in multinomial terms; do not use fitted effective N as inputs"),
  assume("biology","weights","Growth_Option 1: original empirical catch, survey and population weights in grams; growth phases inactive; source zero weights retained"),
  assume("biology","SSB_definition","Female N times population weight times female maturity, survival to May 1 (4/12); model-year age-1 recruitment"),
  assume("source","recovery","Published native data have malformed composition decimal tokens; normalized production-report oac echoes recover the actual consumed composition, not predicted eac values")
))
stock <- pacific_database_row("stocks",stock_id="afsc_yellowfin_sole_ebs",
  charbonneau_id="AFSC_EEBSAI_Limanda_aspera",authority="NOAA-AFSC",authority_stock_id="BSAI yellowfin sole",
  scientific_name="Limanda aspera",common_name="Eastern Bering Sea yellowfin sole",
  area="Eastern and northern Bering Sea assessment area",region="Alaska",ocean="Northeast Pacific")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2024,terminal_year=2024,estimate_terminal_year=2024,assessment_type="full",
  model_family="ADMB",model_version="Model 23.0",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,data_url=reference,model_url=reference,repository_url=repository,
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Official m23_0_2024. Original sex, composition, biological and covariate dimensions retained. Full ageing-error/control detail and state covariance remain unexported; malformed raw compositions recovered from normalized production input echoes.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
