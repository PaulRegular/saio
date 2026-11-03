source("scripts/database/pacific_tables.R")
id <- "joint_hake_coastal_2025"
cache <- "source_cache/joint_hake_coastal"
report <- "https://repository.library.noaa.gov/view/noaa/67186/noaa_67186_DS1.pdf"
native <- "https://www.pcouncil.org/documents/2026/08/hake-2025-model-files-zip-file.zip/"
revision <- jsonlite::fromJSON(file.path(cache,"fims_revision.json"))$sha
reference <- paste0("https://github.com/NOAA-FIMS/case-studies/blob/",revision,
  "/content/data_files/pacific_hake.RDS")
dat <- r4ss::SS_readdat(file.path(cache,"native_2025/hake_data.ss"),verbose=FALSE)
wt <- r4ss::SS_readwtatage(file.path(cache,"native_2025/wtatage.ss"))
fit <- readRDS(file.path(cache,"fims_reference/pacific_hake.RDS"))
stopifnot(dat$styr==1966,dat$endyr==2024,dat$Ngenders==-1,dat$Nages==20,
  dat$Nfleets==2,dat$spawn_month==1,
  fit$spawning_biomass["2024"]==1189495,fit$spawning_biomass["2025"]==1223070,
  fit$mcmc["NatM_uniform_Fem_GP_1"]==.233454)
text <- pdftools::pdf_text(file.path(cache,"assessment_2025.pdf"))
lines <- unlist(strsplit(paste(text,collapse="\n"),"\n"))
table_rows <- function(label,end) {
  first <- grep(label,lines)[1]
  last <- grep(end,lines)
  last <- min(last[last>first])
  z <- lines[seq.int(first+1L,last-1L)]
  z[grepl("^\\s*(19[6-9][0-9]|20[012][0-9])\\s+[0-9]",z)]
}
surface <- function(label,end) {
  z <- do.call(rbind,lapply(table_rows(label,end),function(x)
    scan(text=gsub(",","",x),quiet=TRUE)))
  z <- z[z[,1]<=2024, ]
  stopifnot(nrow(z)==59,ncol(z)==22,identical(as.integer(z[,1]),1966:2024))
  m <- z[,-1];dimnames(m)<-list(z[,1],0:20);m
}
n <- surface("^Table 17\\. Estimated numbers","^Table 18\\.")
b <- surface("^Table 18\\. Estimated total biomass","^Table 19\\.")
u <- surface("^Table 19\\. Estimated exploitation","^Table 20\\.")
summary_rows <- table_rows("^Table 23\\. Time series","^Table 24\\.")
summary_rows <- summary_rows[!startsWith(trimws(summary_rows),"2025")]
summary <- do.call(rbind,lapply(summary_rows,function(x)scan(text=gsub(",","",x),quiet=TRUE)))
stopifnot(nrow(summary)==59,ncol(summary)==8)
interval_rows <- table_rows("^Table 24\\. Time-series","^Table 25\\.")
interval_rows <- interval_rows[!startsWith(trimws(interval_rows),"2025")]
intervals <- lapply(interval_rows,function(x)strsplit(trimws(gsub(",","",x)),"[[:space:]]+")[[1]])
stopifnot(length(intervals)==59,all(lengths(intervals)==8))
bounds <- function(column) t(vapply(intervals,function(x)as.numeric(strsplit(x[column],"-",fixed=TRUE)[[1]]),numeric(2)))
input <- function(type,measure,basis,value,unit,year=NA_integer_,age=NA_integer_,fleet="",survey="",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,basis=basis,value=value,
    unit=unit,year=year,age=age,fleet=fleet,survey=survey,sex="combined",region="US-Canada coastal stock",
    year_basis=ifelse(is.na(year),"","calendar_year"),source_type="native_model",source_reference=native,...)
}
catch <- dat$catch[dat$catch$year>=1966, ]
index <- dat$CPUE[dat$CPUE$index==2, ]
inputs <- list(
  input("catch","total_biomass","biomass",catch$catch,"t",catch$year,fleet="Fishery",
    notes="Combined U.S. and Canadian removals; fixed log catch SD .01."),
  input("index","total_biomass","biomass",index$obs,"t",index$year,survey="Acoustic_Survey",
    sampling_time=(index$seas-1)/12,notes="Active age-2+ acoustic biomass. Negative-index placeholder rows are not observations."),
  input("index","log_index_sd","log_scale",index$se_log,"log SD",index$year,survey="Acoustic_Survey",
    notes="Supplied sampling log SD, before estimated additional SD combined in quadrature.")
)
for(i in seq_len(nrow(dat$agecomp))) {
  z <- dat$agecomp[i, ];fishery <- z$FltSvy==1
  inputs[[length(inputs)+1]] <- input(if(fishery)"catch" else "index","frequency_at_age",
    "native_frequency",as.numeric(z[10:24]),"percent",z$Yr,dat$agebin_vector,
    fleet=if(fishery)"Fishery" else "",survey=if(fishery)"" else "Acoustic_Survey",
    observation_id=paste("age",i,sep=":"),sample_size=z$Nsamp,age_error=z$Ageerr,partition=z$Part,
    sampling_time=if(fishery)NA_real_ else (z$Seas-1)/12,
    notes="Native number composition percentages (row totals 99.98-100.02), not abundance. SS normalizes each row. Age 15 is the observation plus group; age-error key and supplied sample size retained. Dirichlet-multinomial likelihood.")
}
for(spec in list(c("weight","weight_at_age",0),c("catch_weight","weight_at_age",1),
                 c("survey_weight","weight_at_age",2),c("biology","maturity_fecundity_at_age",-2))) {
  z <- wt[wt$Fleet==as.numeric(spec[3]), ]
  value <- as.matrix(z[as.character(0:20)])
  inputs[[length(inputs)+1]] <- input(if(spec[1]=="survey_weight")"weight" else spec[1],spec[2],
    "kg_per_fish",as.vector(value),"kg/fish",rep(ifelse(z$Yr<0,NA_integer_,z$Yr),21),rep(0:20,each=nrow(z)),
    fleet=if(spec[1]=="catch_weight")"Fishery" else "",
    survey=if(spec[1]=="survey_weight")"Acoustic_Survey" else "",
    notes=if(spec[1]=="biology")
      "Original supplied maturity-times-fecundity weight, not a maturity proportion. Female fraction .5 and first mature age 2 are separate source controls." else
      "Original supplied empirical weight. Blank year preserves native -1940 fill directive for years before 1975; later and forecast rows retain explicit years. Population beginning/mid-year weights are identical.")
}
output <- function(type,measure,value,unit,year,age=NA_integer_,sex="combined",se=NA_real_,...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,unit=unit,
    year=year,age=age,sex=sex,se=se,region="US-Canada coastal stock",source_type="official_table",
    source_reference=report,...)
}
outputs <- list()
for(spec in list(list(n,"population","numbers_at_age","million fish","Table 17"),
                 list(b,"biomass","biomass_at_age","thousand t","Table 18"),
                 list(u,"mortality","exploitation_fraction_at_age","percent","Table 19"))) {
  z <- pacific_matrix_long(spec[[1]])
  outputs[[length(outputs)+1]] <- output(spec[[2]],spec[[3]],z$value,spec[[4]],z$year,z$age,
    age_group=ifelse(z$age==20,"20+",""),notes=paste(spec[[5]],"historical marginal posterior medians. No marginal age-state intervals reported; summed medians need not be the median of a sum. Exploitation fractions are not instantaneous F."))
}
yy <- 1966:2024
ssb_ci <- bounds(2)*1000
r_ci <- bounds(6)*1000
for(spec in list(list("biomass","SSB",fit$spawning_biomass[as.character(yy)],"t",ssb_ci,"female"),
                 list("recruitment","recruitment",fit$recruitment[as.character(yy)],"thousand fish",r_ci,"combined"))) {
  z <- output(spec[[1]],spec[[2]],as.numeric(spec[[3]]),spec[[4]],yy,
    age=if(spec[[2]]=="recruitment")0 else NA_integer_,sex=spec[[6]],lwr=spec[[5]][,1],upr=spec[[5]][,2],
    notes="Official 2025 base-model posterior medians retained at NOAA extraction precision, corroborated against the assessment. Rounded equal-tail 95% credible limits from Table 24 converted to these units; SE unavailable. Historical years only.")
  z$source_type <- "official_machine_readable"
  z$source_reference <- paste(reference,";",report,"Table 24")
  outputs[[length(outputs)+1]] <- z
}
bio_ci <- bounds(4)
outputs[[length(outputs)+1]] <- output("biomass","total_biomass",summary[,4],"thousand t",yy,
  lwr=bio_ci[,1],upr=bio_ci[,2],notes="Table 23 posterior median all-age combined-sex biomass; Table 24 equal-tail 95% credible interval. Rounded, not a sum of marginal age medians.")
m <- output("mortality","natural_mortality_at_age",fit$mcmc["NatM_uniform_Fem_GP_1"],
  "per year",rep(yy,21),rep(0:20,each=59),notes="One estimated constant M; posterior median from official-model extraction, confirmed rounded .233 in Table 25. No posterior SE or interval recovered.")
m$source_type <- "official_machine_readable"
m$source_reference <- paste(reference,";",report,"Table 25")
outputs[[length(outputs)+1]] <- m
f <- output("mortality","fishing_mortality_intensity",exp(fit$log_Fmort[as.character(yy)]),
  "per year",yy,notes="Back-transformed marginal log-median annual F intensity. Monotone back-transformation targets the distribution median; finite-sample averaging of the two middle draws can differ. Not Fbar or F-at-age; joint posterior age-selectivity draws unavailable.")
f$source_type <- "derived_source_output"
f$source_reference <- reference
outputs[[length(outputs)+1]] <- f
outputs[[length(outputs)+1]] <- output("catchability","q",.894,"index multiplier",NA_integer_,survey="Acoustic_Survey",
  notes="Table 25 posterior median analytically profiled biomass q. Q_setup float=1 overrides the inactive LnQ parameter: q is not fixed to one. Not age-specific q.")
assume <- function(component,setting,value) pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=paste(native,";",report))
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","Joint U.S.-Canada 2025 base model, SS 3.30.23.1; Bayesian inference from 8000 adnuts posterior draws"),
  assume("population","dimensions","1966-2024 historical years, modeled ages 0-20+, observed age bins 1-15+, combined sex, fixed female fraction .5, one fishery and acoustic survey"),
  assume("N","process","Deterministic survival; early recruitment deviations from 1946 inform initial ages; stochastic recruitment, no stochastic cohort-survival process"),
  assume("recruitment","process","Beverton-Holt R0 and steepness estimated (beta prior mean .777 SD .113); fixed recruitment log SD 1.4; main deviations 1970-2022; 2023+ recruitment follows mean stock-recruit relationship; source bias-adjustment ramp"),
  assume("F","process","Annual F intensity times nonparametric age selectivity; time-varying deviations at ages 2-6 from 1991 with fixed SD 1.4, autocorrelation fixed zero; older ages share the terminal selectivity increment"),
  assume("M","process","One estimated constant, bounded .05-.4 with lognormal prior log median -1.60944 and log SD .1; no externally supplied M input"),
  assume("q","process","Analytically profiled q (Q_setup float=1); estimated additional survey SD; nonparametric survey age selectivity estimated at ages 3-6, older increments fixed zero. Inactive LnQ phase does not fix q."),
  assume("index","observation_model","Age-2+ acoustic biomass at time .5; lognormal with sampling log SD plus estimated additional SD in quadrature; separate Dirichlet-multinomial age composition; age-1 index excluded"),
  assume("catch","observation_model","Total combined national catch in tonnes with fixed log SD .01, plus joint annual number composition percentages under a Dirichlet-multinomial likelihood"),
  assume("biology","inputs","Original empirical annual weights and temperature-dependent maturity-times-fecundity weights supplied in wtatage.ss; first mature age 2, female fraction .5, spawning month 1"),
  assume("source","estimate_convention","Posterior medians; state sums require posterior draws for median/interval of aggregate. Native N, biomass-at-age and exploitation medians retained; uncertainty is not reconstructed from marginal medians."),
  assume("assessment","newer_advice","2026 report is a catch-only/projection update retaining the 2025 fitted model after survey disruption; documented separately in source review, not mixed into this 2025 base fit.")
))
stock <- pacific_database_row("stocks",stock_id="joint_hake_coastal",authority="NOAA-DFO",
  authority_stock_id="Joint coastal Pacific hake",scientific_name="Merluccius productus",
  common_name="Joint U.S.-Canada coastal Pacific hake",area="U.S. West Coast and British Columbia coastal stock",
  region="U.S.-Canada Pacific coast",ocean="Northeast Pacific",
  notes="Agreed Charbonneau-Keith catalogue exception; no invented catalogue identifier. Offshore/coastal treaty stock, not Strait of Georgia or Puget Sound resident hake.")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2025,terminal_year=2024,estimate_terminal_year=2024,assessment_type="full",
  model_family="Stock Synthesis",model_version="3.30.23.1, 2025 base",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,data_url=native,model_url=native,
  repository_url="https://github.com/pacific-hake/hake-assessment",
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Most recent full fitted assessment with detailed original inputs and historical age outputs. Newer 2026 catch-only projections kept separate. Original percent compositions and maturity-fecundity products retained. Joint posterior N/F draws and complete ageing-error inventory unavailable.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
