source("R/read_database.R")
x <- read_assessment("joint_hake_coastal_2025")
i <- x$inputs
o <- x$outputs
stopifnot(identical(x$stocks$ocean,"Northeast Pacific"),
  is.na(x$stocks$charbonneau_id),identical(x$assessment$terminal_year,2024L),
  identical(o$value[o$measure=="SSB" & o$year==2024],1189495),
  identical(o$lwr[o$measure=="SSB" & o$year==2024],530000),
  identical(o$upr[o$measure=="SSB" & o$year==2024],2900000),
  all(is.na(o$se[o$measure=="SSB"])),!any(i$type=="M"),
  all(o$value[o$measure=="natural_mortality_at_age"]==.233454),
  all(o$source_type[o$measure=="natural_mortality_at_age"]=="official_machine_readable"),
  all(grepl("pacific_hake.RDS",o$source_reference[o$measure=="natural_mortality_at_age"],fixed=TRUE)),
  !any(o$measure=="fishing_mortality_at_age"))
p <- i[i$measure=="frequency_at_age",]
stopifnot(nrow(p)==65*15,all(p$unit=="percent"),
  all(p$basis=="native_frequency"),
  max(abs(tapply(p$value,p$observation_id,sum)-100))<.021,
  length(unique(p$year[p$type=="catch"]))==50,
  length(unique(p$year[p$type=="index"]))==15,
  all(i$sampling_time[i$type=="index" & i$measure=="total_biomass"]==.5))
n <- o[o$measure=="numbers_at_age",]
b <- o[o$measure=="biomass_at_age",]
w <- i[i$type=="weight" & is.na(i$survey),]
stopifnot(nrow(n)==59*21,all(n$unit=="million fish"),
  any(is.na(w$year)),all(i$unit[i$measure=="maturity_fecundity_at_age"]=="kg/fish"),
  !any(i$type=="maturity"))
for(year in 1966:2024) {
  z <- n[n$year==year,]
  ww <- if(year<1975)w[is.na(w$year),] else w[!is.na(w$year)&w$year==year,]
  weight <- ww$value[match(z$age,ww$age)]
  bb <- b$value[match(paste(z$year,z$age),paste(b$year,b$age))]
  stopifnot(all(abs(z$value*weight-bb)<=.5*weight+.501))
}
cat("Coastal hake production medians, credible-interval units, native percentages and biomass-at-age identity passed.\n")
