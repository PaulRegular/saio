source("scripts/database/pacific_tables.R")
id <- "dfo_herring_sog_2025"
cache <- "source_cache/dfo_herring_sog"
revision <- "806896bf596b7f5799fd3d723b2fa631a3b210a5"
reference <- paste0("https://github.com/pbs-assess/herringfsar/tree/",revision,"/data/SOG_DDM_omGrid")
report <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41320013.pdf"
files <- c("fit_parBatSOG_OMgrid_h.70_3","fit_parBatSOG_OMgrid_h.70_2",
  "fit_parBatSOG_OMgrid_h.70_4","fit_parBatSOG_MbhGrid_h.71","fit_parBatSOG_OMgrid_h.70_5")
fits <- lapply(files,function(name)readRDS(file.path(cache,"native",paste0(name,".rds"))))
weights <- c(.34,rep(.165,4))
x <- fits[[1]];d <- x$data;yy <- 1951:2023;aa <- 1:10
stopifnot(x$fYear==1951,x$lYear==2023,identical(dim(d$A_apgt),c(10L,1L,5L,73L)),
  all(d$A_apgt[,,4:5,]==-1),all(d$I_pgt==-1),all(d$ageCompWeight_g[4:5]==0),
  d$densityDepM==1,d$spawnTiming==.79,
  all(vapply(fits,function(z)isTRUE(all.equal(z$data,d)),logical(1))))
input <- function(type,measure,basis,value,unit,year,age=NA_integer_,fleet="",survey="",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,basis=basis,
    value=value,unit=unit,year=year,age=age,fleet=fleet,survey=survey,sex="combined",region="Strait of Georgia",
    year_basis=ifelse(is.na(year),"","model_year"),source_type="native_model",source_reference=reference,...)
}
inputs <- list(input("index","total_biomass","biomass",as.numeric(d$combI_pt),"thousand t",yy,
  survey="Combined_spawn_survey",sampling_time=.79,
  notes="Original combined surface/dive spawn index supplied to DDM ensemble. Total mature biomass index, not age-specific abundance. Herring assessment year ends June; time .79 is within that year. No age allocation supplied."))
for(g in 1:3) {
  fleet <- x$gearLabs[g]
  inputs[[length(inputs)+1L]] <- input("catch","total_biomass","biomass",as.numeric(d$C_pgt[1,g,]),
    "thousand t",yy,fleet=fleet,sampling_time=d$fleetTiming_g[g],notes="Original retained catch; distinct fishery timing retained.")
  a <- d$A_apgt[,1,g,];present <- a>=0
  grid <- expand.grid(age=aa,year=yy)
  inputs[[length(inputs)+1L]] <- input("catch","composition_sample_count","native_frequency",as.vector(a)[present],
    "fish",grid$year[present],grid$age[present],fleet=fleet,
    observation_id=paste(fleet,grid$year[present],sep=":"),
    sampling_time=d$fleetTiming_g[g],
    notes="Original fishery biological age sample counts; -1 is missing, not a zero sample. Source likelihood pools rare age categories and uses correlated composition errors. Not an abundance index.")
  inputs[[length(inputs)+1L]] <- input("catch_weight","weight_at_age","kg_per_fish",as.vector(d$W_apgt[,1,g,]),
    "kg/fish",rep(yy,each=10),rep(aa,73),fleet=fleet,notes="Original empirical weight-at-age; age 10 is plus group.")
}
inputs[[length(inputs)+1L]] <- input("weight","weight_at_age","kg_per_fish",as.vector(d$W_apt[,1,]),
  "kg/fish",rep(yy,each=10),rep(aa,73),notes="Original empirical stock weight-at-age, not fitted biology.")
stopifnot(identical(as.numeric(x$pars$mat_a),c(0,.24974,.9,rep(1,7))))
inputs[[length(inputs)+1L]] <- input("maturity","maturity_at_age","proportion",x$pars$mat_a,
  "proportion",NA_integer_,aa,notes="Fixed original matVec in production control; SB uses both-sex mature biomass without a female-fraction multiplier. Female .5 occurs only in egg conversion.")
output <- function(type,measure,value,unit,year,age=NA_integer_,...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,unit=unit,
    year=year,age=age,sex="combined",region="Strait of Georgia",source_type="derived_source_output",
    source_reference=reference,...)
}
ensemble_mean <- function(name) Reduce(`+`,Map(function(z,w)apply(z$posts[[name]],seq.int(2,length(dim(z$posts[[name]]))),mean)*w,fits,weights))
ensemble_interval <- function(name) {
  draws <- do.call(rbind,lapply(fits,function(z)matrix(z$posts[[name]],nrow=dim(z$posts[[name]])[1])))
  probability <- unlist(Map(function(z,w)rep(w/dim(z$posts[[name]])[1],dim(z$posts[[name]])[1]),fits,weights))
  t(apply(draws,2,function(v) {
    j <- order(v);cdf <- cumsum(probability[j])
    v[j[vapply(c(.025,.975),function(p)which(cdf>=p)[1],integer(1))]]
  }))
}
outputs <- list()
for(spec in list(c("SB_ipt","biomass","SSB","thousand t"),
                 c("R_ipt","recruitment","recruitment","million fish"))) {
  z <- as.numeric(ensemble_mean(spec[1]))[seq_along(yy)]
  ci <- ensemble_interval(spec[1])[seq_along(yy),,drop=FALSE]
  outputs[[length(outputs)+1L]] <- output(spec[2],spec[3],z,spec[4],yy,
    age=if(spec[2]=="recruitment")1 else NA_integer_,
    lwr=ci[,1],upr=ci[,2],
    notes="Reconstructed weighted mean of five component posterior means; weights .34,.165,.165,.165,.165 in published scenario order. Equal-tail 95% credible limits from weighted empirical posterior mixture, not averaged component limits. 2024 projection excluded. Published terminal summary retained separately; small source-summary discrepancy unresolved.")
}
m <- ensemble_mean("M_iapt")[,1,seq_along(yy)]
ci <- ensemble_interval("M_iapt")[seq_len(length(m)),,drop=FALSE]
outputs[[length(outputs)+1L]] <- output("mortality","natural_mortality_at_age",as.vector(m),"per year",
  rep(yy,each=10),rep(aa,73),
  lwr=ci[,1],upr=ci[,2],
  notes="Weighted posterior mean estimated density-dependent/time-varying M with weighted-mixture 95% credible limits. Juvenile age 1 differs from ages 2+. Not a fixed baseline; no source M made an input.")
# Preserve component modes without presenting them as posterior ensemble states.
for(j in seq_along(fits)) {
  z <- fits[[j]]$repOpt$N_apt[,1,seq_along(yy)]
  o <- output("population",paste0("OM",j,"_mpd_numbers_at_age"),as.vector(z),"million fish",
    rep(yy,each=10),rep(aa,73),
    notes=paste("Component",files[j],"MPD N; not an ensemble posterior mean or median. Native posterior files omit N draws; these modes are not substituted for them."))
  o$age_group <- ifelse(o$age==10,"10+","")
  outputs[[length(outputs)+1L]] <- o
}
terminal <- outputs[[1]]$value[outputs[[1]]$year==2023]
stopifnot(round(terminal,2)==84.33)
published <- read.csv(file.path(cache,"native/ensOM_meanPars.csv"))$BT
outputs[[length(outputs)+1L]] <- output("biomass","published_terminal_SSB",published,"thousand t",2023,
  notes="Native ensOM_meanPars.csv BT, reproduced as 84.33 kt in 2025 Table 1. Historical weighted component means differ by about .0013 kt at the terminal year; no rescaling or draw substitution applied.")
outputs[[length(outputs)]]$source_type <- "official_machine_readable"
outputs[[length(outputs)]]$source_reference <- paste0("https://github.com/pbs-assess/herringfsar/blob/",revision,"/data/ensOM_meanPars.csv")
assume <- function(component,setting,value) pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=paste(report,";",reference))
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2025 full MSE uses five SISCAH DDM operating models fitted to 1951-2023. Weights .34 central Mb .562 h .70; .165 each h .65/.75 and Mb .532/.584. One case, not five stocks."),
  assume("assessment","newer_advice","The same update also describes interim 2025 DIM estimation through 2025. It is a different model/data period. Public fit_maxTHR0.14 object ends 2024, so neither it nor DDM states are labelled the 2025 interim fit."),
  assume("population","dimensions","Ages 1-10+, combined sex; herring assessment year July-June; original fleet timings reduction .54, seineRoe .766, gillnet .774, spawn/surveys .79."),
  assume("N","process","Deterministic annual survival with discrete fishery removals at distinct times, free initial-age deviations, age-1 recruitment."),
  assume("M","process","Density-dependent baseline M_b+exp(-m1*B/B0), stochastic annual M deviations and distinct juvenile M; scenario productivity parameters fixed across ensemble hypotheses."),
  assume("recruitment","process","Beverton-Holt recruitment with stochastic annual deviations; fixed steepness differs by hypothesis. Posterior age-1 R available; not a constant-mean recruitment model."),
  assume("catch","observation_model","Three retained-catch fleets with separate times, selectivity and empirical weights; biological fishery ages are counts, correlated logistic-normal composition errors and rare-age pooling."),
  assume("index","observation_model","Combined original surface/dive total spawning-biomass index; survey age observations all missing (-1), age-likelihood weights zero. Source blends era-specific q in combined-index prediction, not a separate abundance-at-age survey."),
  assume("biology","inputs","Original empirical stock/fleet kg weights and fixed maturity vector 0,.24974,.9,1,...; source SSB is both-sex mature biomass. SB code has no .5; eggs alone multiply by .5."),
  assume("source","estimate_convention","Published terminal ensemble summary 84.33375 kt retained separately. Reconstructed weighted component mean rounds to the same 84.33 kt but differs by about .0013 kt. Randomly resampled wtPosts mean also differs; no undocumented adjustment. Component MPD N is not ensemble posterior N. Derived intervals use weighted posterior mixture, not averaged limits.")
))
stock <- pacific_database_row("stocks",stock_id="dfo_herring_sog",authority="DFO",
  authority_stock_id="Strait of Georgia Pacific herring",scientific_name="Clupea pallasii",
  common_name="Strait of Georgia Pacific herring",area="Strait of Georgia",region="British Columbia",
  ocean="Northeast Pacific",notes="Canadian-managed catalogue exception; no invented Charbonneau identifier.")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2025,terminal_year=2023,estimate_terminal_year=2023,assessment_type="full",
  model_family="SISCAH",model_version="Five-model DDM ensemble",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,data_url=reference,model_url=reference,
  repository_url="https://github.com/pbs-assess/herringfsar",
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Detailed public operating-model ensemble underpinning 2025 full MSE; 1951-2023 historical states. Interim DIM through 2025 reported separately, not mixed. No original survey age compositions or posterior ensemble N/F draws.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
