source("R/read_database.R")
x <- read_assessment("dfo_pop_bc_2023")
i <- x$inputs;o <- x$outputs
stopifnot(is.na(x$stocks$charbonneau_id),x$stocks$ocean=="Northeast Pacific",
  x$assessment$assessment_year==2023,x$assessment$estimate_terminal_year==2024,
  setequal(i$region[i$measure=="total_biomass"],c("5ABC","3CD","5DE")),
  length(unique(i$fleet[!is.na(i$fleet)]))==3,length(unique(i$survey[!is.na(i$survey)]))==6,
  setequal(i$sex[i$measure=="proportion_at_age"],c("female","male")),
  all(i$age_error[i$measure=="proportion_at_age"]>=0),
  all(abs(i$sampling_time[i$type=="index" & i$measure=="total_biomass"]-5/12)<1e-12),
  !any(i$type=="M"),!any(o$measure=="numbers_at_age"),!any(o$measure=="fishing_mortality_at_age"))
w <- i[i$type=="weight",]
stopifnot(nrow(w)==4*61,all(is.na(w$year)),all(w$value>0),
  all(w$source_type=="reconstructed_source_input"),setequal(w$season,c("begin_year","mid_year")),
  w$value[w$sex=="female" & w$season=="begin_year" & w$age==10]==.692217,
  w$value[w$sex=="male" & w$season=="mid_year" & w$age==60]==.976575)
ssb <- o[o$measure=="SSB",]
stopifnot(nrow(ssb)==4,all(ssb$year==2024),all(is.na(ssb$se)),
  ssb$value[ssb$region=="BC coast"]==61965,
  ssb$lwr[ssb$region=="BC coast"]==44390,ssb$upr[ssb$region=="BC coast"]==90825,
  all(grepl("90%",ssb$notes,fixed=TRUE)))
m <- o[o$measure=="natural_mortality_at_age",]
stopifnot(nrow(m)==2*89*61,all(m$value[m$sex=="female"]==.05229),
  all(m$value[m$sex=="male"]==.05939),all(m$lwr[m$sex=="female"]==.04365),
  all(grepl("90%",m$notes,fixed=TRUE)),
  any(grepl("fixed .9",x$assumptions$value,fixed=TRUE)))
cat("BC POP three-area/sex inputs, exact fixed-weight recovery, estimated M and native 90% projection-boundary summaries passed.\n")
