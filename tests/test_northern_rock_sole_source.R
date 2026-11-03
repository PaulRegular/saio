source("R/read_database.R")
x <- read_assessment("afsc_northern_rock_sole_ebs_2024")
i <- x$inputs
o <- x$outputs
m <- x$assumptions[x$assumptions$component=="M" & x$assumptions$setting=="process",]
stopifnot(nrow(m)==1L,grepl("female penalty corroborated",m$value,fixed=TRUE),
  grepl("male penalty activation unresolved",m$value,fixed=TRUE),
  grepl("9709548fafc7d69a2e3f88f80f60c74b7d3cfb0e",m$source_reference,fixed=TRUE))
stopifnot(identical(x$stocks$ocean,"Northeast Pacific"),
  identical(x$assessment$model_version,"Model 24.2"),
  identical(i$value[i$type=="catch" & i$measure=="total_biomass" & i$year==2024],27.339),
  identical(o$value[o$measure=="SSB" & o$year==2024],271.988),
  identical(o$value[o$measure=="total_biomass" & o$year==2024],1051.04),
  !any(i$type=="M"),!any(i$type=="covariate"),
  all(i$unit[i$type %in% c("weight","catch_weight")]=="kg/fish"),
  all(o$se[o$measure=="SSB"]>0),
  all(o$sex[o$measure=="SSB"]=="female"))
p <- i[i$measure=="proportion_at_age",]
stopifnot(all(abs(tapply(p$value,p$observation_id,sum)-1)<1e-10),
  !any(p$type=="catch" & p$year %in% 1995:1997),
  length(unique(p$year[p$type=="catch"]))==42,
  all(i$sampling_time[i$type=="index" & i$measure=="total_biomass"]==.5))
for(sex in c("female","male")) {
  n <- o[o$measure=="numbers_at_age" & o$sex==sex,]
  f <- o[o$measure=="fishing_mortality_at_age" & o$sex==sex,]
  m <- o[o$measure=="natural_mortality_at_age" & o$sex==sex,]
  stopifnot(nrow(n)==50*20,nrow(f)==50*20,nrow(m)==50*20,
    all(is.na(f$se)),all(f$source_type=="derived_source_output"),
    all(m$value==if(sex=="female").192 else .226))
  nn <- matrix(n$value,50,20)
  ff <- matrix(f$value,50,20)
  err <- nn[-1,2:19]-nn[-50,1:18]*exp(-unique(m$value)-ff[-50,1:18])
  stopifnot(max(abs(err))<1.8)
}
w <- i[i$type=="weight" & is.na(i$survey),]
n <- o[o$measure=="numbers_at_age",]
for(year in 1975:2024) {
  z <- n[n$year==year,];ww <- w[w$year==year,]
  weights <- ww$value[match(paste(z$sex,z$age),paste(ww$sex,ww$age))]
  b <- sum(z$value*weights)
  native <- o$value[o$measure=="total_biomass" & o$year==year]
  stopifnot(abs(b-native)<=sum(.5*weights)+.01)
}
cat("Northern rock sole units, production columns, sex-specific M, source F equations and rounded N identities passed.\n")
