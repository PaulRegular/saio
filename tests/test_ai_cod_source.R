source("R/read_database.R")
x <- read_assessment("afsc_cod_ai_2024")
i<-x$inputs;o<-x$outputs
stopifnot(x$stocks$charbonneau_id=="AFSC_macrocephalus_AL to (AI)",x$stocks$ocean=="Northeast Pacific",
  grepl("Previous Charbonneau identifier retained as alias: AFSC_AI_Gadus_macrocephalus",x$stocks$notes,fixed=TRUE),
  x$assessment$terminal_year==2024,all(i$source_type=="official_table"),all(o$source_type=="official_table"),
  all(o$year>=1991,na.rm=TRUE),all(o$measure[is.na(o$year)]=="q"),
  !any(o$measure=="numbers_at_age"),!any(o$measure=="fishing_mortality_at_age"),
  !any(i$measure %in% c("proportion_at_age","conditional_proportion_at_age","weight_at_age")),
  i$value[i$type=="catch" & i$year==2024]==4676,
  i$value[i$type=="index" & i$measure=="total_biomass" & i$year==2024]==50383,
  all(i$year[i$type=="M"]<=2015),all(i$value[i$type=="M"]==.417),
  all(o$value[o$measure=="natural_mortality_at_age"]==.5703),
  all(o$se[o$measure=="natural_mortality_at_age"]==.0371),
  o$value[o$measure=="total_biomass" & o$year %in% 2024]==74386,
  o$value[o$measure=="SSB" & o$year %in% 2024]==50446,
  o$lwr[o$measure=="SSB" & o$year %in% 2024]==35559,
  o$value[o$measure=="recruitment" & o$year %in% 2024]==76193,
  all(o$age[o$measure=="recruitment"]==0),
  any(grepl("November2024/M24_1_data/run",x$assumptions$value,fixed=TRUE)))
cat("AI cod final run identity, reported units/intervals, full-year catch and fixed-versus-estimated M passed; preliminary states excluded.\n")
