source("scripts/database/pacific_tables.R")
source("scripts/database/pacific_ss.R")
id <- "dfo_pop_bc_2023"
cache <- "source_cache/dfo_pop_bc"
revision <- "16f1d4368ad7d3e854219ca1c2d9d6353252c861"
native <- paste0("https://github.com/pbs-software/pbs-synth/tree/",revision,"/models/input/2023/POP/CST/Base/R21v3/21.01")
report <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282565.pdf"
dat <- r4ss::SS_readdat(file.path(cache,"native/data.21.01.ss"),verbose=FALSE)
ctl <- r4ss::SS_readctl(file.path(cache,"native/control.21.01.ss"),datlist=dat,verbose=FALSE)
wt <- r4ss::SS_readwtatage(file.path(cache,"fixed_biology_evaluation/wtatage.ss_new"))
stopifnot(dat$styr==1935,dat$endyr==2023,dat$Ngenders==2,dat$Nages==60,
  dat$Nfleets==9,all(ctl$size_selex_types$Pattern==0),
  all(ctl$MG_parms$PHASE[grepl("L_at_|VonBert_|CV_|Wtlen_",rownames(ctl$MG_parms))]<0))
areas <- c("5ABC","3CD","5DE")
input <- function(type,measure,basis,value,unit,year=NA_integer_,age=NA_integer_,
                  fleet="",survey="",sex="combined",region="BC coast",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,basis=basis,
    value=value,unit=unit,year=year,age=age,fleet=fleet,survey=survey,sex=sex,region=region,
    year_basis=ifelse(is.na(year),"","calendar_year"),source_type="native_model",source_reference=native,...)
}
c <- dat$catch[dat$catch$year>=1935,]
index <- dat$CPUE[dat$CPUE$index>0,]
inputs <- list(
  input("catch","total_biomass","biomass",c$catch,"t",c$year,fleet=dat$fleetnames[c$fleet],
    region=areas[dat$fleetinfo$area[c$fleet]],
    notes="Original area-specific retained trawl catch. 2023 input repeats 2022 catch provisionally; not a final observed 2023 landing."),
  input("index","total_biomass","biomass",index$obs,"t",index$year,
    survey=dat$fleetnames[index$index],region=areas[dat$fleetinfo$area[index$index]],
    sampling_time=(index$seas-1)/12,notes="Original area-specific survey biomass, not an abundance-at-age observation."),
  input("index","log_index_sd","log_scale",index$se_log,"log SD",index$year,
    survey=dat$fleetnames[index$index],region=areas[dat$fleetinfo$area[index$index]],
    notes="Supplied survey log SD; source CPUEinfo units=1 biomass.")
)
p <- pacific_ss_compositions(dat,"age",id,native,"BC coast")
fleet <- match(ifelse(p$type=="catch",p$fleet,p$survey),dat$fleetnames)
p$region <- areas[dat$fleetinfo$area[fleet]]
inputs[[length(inputs)+1L]] <- p
for(sex in 1:2)for(f in c(0,-1)) {
  z <- wt[wt$Sex==sex & wt$Fleet==f,]
  values <- as.matrix(z[as.character(0:60)])
  stopifnot(max(apply(values,2,function(v)max(v)-min(v)))<1e-10)
  out <- input("weight","weight_at_age","kg_per_fish",values[1,],"kg/fish",age=0:60,
    sex=c("female","male")[sex],season=if(f==0)"begin_year" else "mid_year",
    notes="Reconstructed fixed biological input: original SS3 3.30.20 growth, CV and weight-length relationships evaluated with -maxfn 0. Population weights only; generated N/F/M/SSB are not official estimates and are not imported.")
  out$source_type <- "reconstructed_source_input"
  inputs[[length(inputs)+1L]] <- out
}
mat <- c(rep(0,5),.118685573,.174868158,.247826408,.337837982,.442989478,.558730517,
  .677852837,.791029151,.88791952,.95869125,.995652911,rep(1,45))
stopifnot(length(mat)==61)
inputs[[length(inputs)+1L]] <- input("maturity","maturity_at_age","proportion",mat,
  "proportion",age=0:60,sex="female",notes="Original maturity-option-3 vector. Distinct from configured reproductive output: fecundity option 2 with coefficients 1,0; source First_Mature_Age reads as 9. No silent reinterpretation as weight-times-maturity.")
output <- function(type,measure,value,unit,year,age=NA_integer_,sex="combined",...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,unit=unit,
    year=year,age=age,sex=sex,region="BC coast",source_type="official_table",source_reference=report,...)
}
outputs <- list(output("biomass","SSB",61965,"t",2024,sex="female",lwr=44390,upr=90825,
  notes="Table F.5 published B2024, labelled female spawning biomass in tonnes; posterior median and 90% equal-tail credible limits (5%-95%), not 95%. January 2024 is first projection boundary, not historical 2023. Reproductive-output versus biomass definition unresolved in public native configuration."))
for(area in areas) {
  z <- read.csv(file.path(cache,"reporting",paste0("subarea",area,".csv")),row.names=1)
  out <- output("biomass","SSB",z["50%","Bcurr"],"t",2024,sex="female",
    lwr=z["5%","Bcurr"],upr=z["95%","Bcurr"],
    notes="Native R21v3 subarea posterior median reported spawning biomass and 90% credible limits; same source-definition caution as coastwide SSB. Component medians/limits must not be summed into coastwide quantiles.")
  out$region <- area;out$source_type <- "official_machine_readable"
  out$source_reference <- paste0("https://github.com/pbs-software/pbs-synth/blob/",revision,"/models/sweave/2023/POP/WP/subarea",area,".csv")
  outputs[[length(outputs)+1L]] <- out
}
for(sex in c("female","male")) {
  v <- if(sex=="female")c(.05229,.04365,.06146) else c(.05939,.05050,.06902)
  outputs[[length(outputs)+1L]] <- output("mortality","natural_mortality_at_age",v[1],"per year",
    rep(1935:2023,61),rep(0:60,each=89),sex=sex,lwr=v[2],upr=v[3],
    notes="Table F.4 posterior median estimated sex-specific constant M, shared across areas. Limits are native 90% credible interval (5%-95%); no natural-scale SE or 95% interval inferred. Source normal prior mean .06 SD .018; no fixed-M input.")
}
assume <- function(component,setting,value) pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=paste(native,";",report))
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2023 coastwide R21v3 / 21.01, Research Document 2025/004; SS3.30.20, 2000 retained MCMC draws, one three-area assessment not three cases."),
  assume("population","dimensions","1935-2023 ages 0-60+, female/male, no movement among areas 5ABC,3CD,5DE. Three area catches and six area-specific survey series."),
  assume("N","process","Deterministic cohort survival; early recruitment deviations and spatial recruitment-allocation deviations. Female fraction at recruitment .5; adult sex fractions are estimated states, not fixed .5."),
  assume("recruitment","process","Beverton-Holt steepness estimated with beta prior mean .67 SD .17; recruitment log SD fixed .9 and annual deviations/bias adjustment; recruitment allocated to three nonmixing areas."),
  assume("M","process","Separate constant female and male M estimated, shared across areas; normal prior .06 SD .018, bounds .02-.2. Not fixed .06."),
  assume("F","process","Area-specific annual fishing intensities and age selectivity; double-normal and linked curves, sex-specific differences; all length-selectivity patterns zero."),
  assume("index","observation_model","Area survey biomass plus joint-sex marginal ages; q and survey-specific age selectivity. Native month 6 is fraction 5/12. Supplied log SDs and ageing-error keys retained."),
  assume("catch","observation_model","Retained catch tonnes by area and joint-sex number compositions with supplied N and Francis multipliers 2.7923,3.1274,2.8821,.5744,1.0766,1.2071,.7348,.4874 for fleets1-8. Do not replace N with raw otolith totals."),
  assume("biology","inputs","Original sex-specific von Bertalanffy growth, CV and allometry fixed (negative phases); no supplied empirical weight matrix. Source length variation integrated by matching SS3 to recover fixed population weights. Original female maturity vector retained."),
  assume("biology","reporting_caution","Public control fecundity option2 with coefficients1,0 and First_Mature_Age9.492 reads as9; SS3 reproductive output differs from mature biomass. Report calls B2024 female biomass in tonnes. Final joint posterior output unavailable to resolve this; do not silently equate source reproductive output with tinyAM SSB."),
  assume("source","estimate_convention","Official advice uses posterior medians and 90% credible intervals. Reported January2024 SSB retained as projection-boundary context; historical posterior N/F/recruitment/SSB draws or numerical trajectories not publicly recovered.")
))
stock <- pacific_database_row("stocks",stock_id="dfo_pop_bc",authority="DFO",authority_stock_id="Coastwide Pacific ocean perch",
  scientific_name="Sebastes alutus",common_name="British Columbia Pacific ocean perch",area="5ABC; 3CD; 5DE",
  region="British Columbia",ocean="Northeast Pacific",notes="Canadian-managed catalogue exception, one three-area assessment; no invented Charbonneau identifier.")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2023,terminal_year=2023,estimate_terminal_year=2024,assessment_type="full",
  model_family="Stock Synthesis",model_version="R21v3 / 21.01, SS3.30.20",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,data_url=native,model_url=native,
  repository_url="https://github.com/pbs-software/pbs-synth",assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Detailed 2023 production assessment published 2025. Original three-area/sex observations and fixed biology recovered; native age-error matrices retained in cache but not fully transcribed. Posterior annual N/F/R/SSB unavailable numerically; reported 2024 boundary SSB and estimated sex-specific M retained with native 90% limits. Source biomass/reproductive-output definition unresolved.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
