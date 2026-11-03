source("R/read_database.R")
x <- read_assessment("dfo_herring_sog_2025")
i <- x$inputs;o <- x$outputs
stopifnot(is.na(x$stocks$charbonneau_id),x$stocks$ocean=="Northeast Pacific",
  x$assessment$assessment_year==2025,x$assessment$terminal_year==2023,
  all(i$year_basis[!is.na(i$year)]=="model_year"),
  setequal(i$fleet[!is.na(i$fleet)],c("reduction","seineRoe","gillnet")),
  all(i$unit[i$measure=="total_biomass"]=="thousand t"),
  all(i$sampling_time[i$type=="index"]==.79),
  !any(i$type=="index" & i$measure %in% c("numbers_at_age","proportion_at_age","composition_sample_count")),
  all(i$value[i$measure=="composition_sample_count"]>=0),
  !any(i$type=="M"),!any(o$measure=="numbers_at_age"),
  !any(o$measure=="fishing_mortality_at_age"),
  all(is.na(o$season)),sum(grepl("^OM[1-5]_mpd_numbers_at_age$",o$measure))==5*73*10,
  all(o$year<=2023),!anyNA(o$value),
  o$value[o$measure=="published_terminal_SSB"]==84.33375,
  round(o$value[o$measure=="SSB" & o$year==2023],2)==84.33,
  abs(o$value[o$measure=="SSB" & o$year==2023]-84.33375)<.002,
  all(is.finite(o$lwr[o$measure %in% c("SSB","recruitment","natural_mortality_at_age")])),
  all(o$lwr<=o$upr,na.rm=TRUE),all(is.na(o$se)),
  identical(i$value[i$type=="maturity"],c(0,.24974,.9,rep(1,7))))
for(year in 1951:2023) {
  m <- o[o$measure=="natural_mortality_at_age" & o$year==year,]
  stopifnot(length(unique(m$value[m$age>=2]))==1,length(unique(m$value))==2)
}
cat("SoG herring DDM identity, native model years/fleets, missing survey ages, both-sex SSB, ensemble uncertainty and separate component modes passed.\n")
