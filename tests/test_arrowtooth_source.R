source("R/read_database.R")
x <- read_assessment("afsc_arrowtooth_flounder_bsai_2022")
i<-x$inputs;o<-x$outputs
stopifnot(x$stocks$charbonneau_id=="AFSC_BSAI_Atheresthes_stomais",
  x$stocks$scientific_name=="Atheresthes stomias",x$stocks$ocean=="Northeast Pacific",
  x$assessment$assessment_year==2022,x$assessment$terminal_year==2022,
  all(i$value[i$type=="M" & i$sex=="female"]==.2),all(i$value[i$type=="M" & i$sex=="male"]==.35),
  max(i$year[i$type=="catch"])==2021,
  i$value[i$type=="catch" & i$year %in% 1991]==17559,
  all(is.na(i$sampling_time)),!any(i$measure %in% c("proportion_at_age","proportion_at_length","conditional_proportion_at_age")))
surveys <- i[i$type=="index" & i$measure=="total_biomass" & grepl("^Active",i$notes),]
stopifnot(identical(as.integer(range(surveys$year[surveys$survey=="EBS_shelf"])),c(1992L,2022L)),
  identical(as.integer(range(surveys$year[surveys$survey=="EBS_slope"])),c(2002L,2016L)),
  identical(as.integer(range(surveys$year[surveys$survey=="Aleutian_Islands"])),c(1991L,2022L)),
  surveys$value[surveys$year==2022 & surveys$survey=="EBS_shelf"]==521615)
n<-o[o$measure=="numbers_at_age",];b<-o[o$measure=="biomass_at_age",]
stopifnot(nrow(n)==2*47*21,nrow(b)==nrow(n),all(n$unit=="thousand fish"),all(b$unit=="t"),
  all(is.na(n$se)),all(is.na(b$lwr)),all(is.na(b$upr)),
  o$value[o$measure=="total_biomass" & o$year==2022]==933466,
  o$value[o$measure=="SSB" & o$year==2022]==507275)
total <- aggregate(value~year,b,sum)
reported <- o[o$measure=="total_biomass",]
weight <- i[i$type=="weight",]
stopifnot(all(abs(total$value-reported$value[match(total$year,reported$year)])<.5*sum(weight$value)+.5))
f<-o[o$measure=="fishing_mortality_at_age",]
stopifnot(all(f$value>0),all(f$year<=2021),all(is.na(f$se)),
  all(f$source_type=="derived_source_output"))
key<-function(z)paste(z$sex,z$year,z$age)
z<-f[f$age<=19,]
next_state<-transform(z,year=year+1,age=age+1)
expected<-n$value[match(key(z),key(n))]*exp(-z$value-ifelse(z$sex=="female",.2,.35))
stopifnot(max(abs(expected-n$value[match(key(next_state),key(n))]))<1e-8)
cat("Arrowtooth source identity, survey activation, fixed sex biology, N/biomass/recruitment scales and cohort-F recovery passed.\n")
