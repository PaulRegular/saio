source("R/read_database.R")
x <- read_assessment("afsc_yellowfin_sole_ebs_2024")
i <- x$inputs
o <- x$outputs
stopifnot(identical(x$stocks$ocean,"Northeast Pacific"),
  identical(x$assessment$model_version,"Model 23.0"),
  identical(i$value[i$type=="catch" & i$measure=="total_biomass" & i$year==2024],74.289),
  identical(o$value[o$measure=="SSB" & o$year==2024],751.023),
  identical(o$value[o$measure=="total_biomass" & o$year==2024],2412.52),
  all(i$sex[i$type=="M"]=="female"),all(i$value[i$type=="M"]==.12),
  all(o$sex[o$measure=="natural_mortality_at_age"]=="male"),
  all(o$value[o$measure=="natural_mortality_at_age"]==.127699),
  all(o$se[o$measure=="natural_mortality_at_age"]==.0037386),
  sum(i$type=="covariate")==3*42,
  all(i$sampling_time[i$type=="index" & i$measure=="total_biomass"]==.5))
p <- i[i$measure=="proportion_at_age",]
stopifnot(all(abs(tapply(p$value,p$observation_id,sum)-1)<1e-5),
  identical(sort(unique(p$year[p$type=="catch" & p$sex=="female"])),1975:2023),
  all(p$sample_size[p$type=="catch" & p$sex=="female"]==21.5))
n <- o[o$measure=="numbers_at_age",]
w <- i[i$type=="weight" & is.na(i$survey),]
stopifnot(nrow(n)==71*20*2,all(n$unit=="billion fish"),
  all(o$se[o$measure=="SSB"]>0),all(o$sex[o$measure=="SSB"]=="female"),
  any(i$value[i$type=="catch_weight"]==0))
for(year in 1954:2024) {
  z <- n[n$year==year,]
  ww <- w[w$year==year,]
  b <- sum(z$value*ww$value[match(paste(z$sex,z$age),paste(ww$sex,ww$age))])
  stopifnot(abs(b-o$value[o$measure=="total_biomass" & o$year==year])<.05)
  r <- sum(z$value[z$age==1])
  stopifnot(abs(r-o$value[o$measure=="recruitment" & o$year==year])<1e-4)
}
cat("Yellowfin sole production identity, units, sex roles, biology and uncertainty passed.\n")
