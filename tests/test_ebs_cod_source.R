source("R/read_database.R")
x <- read_assessment("afsc_cod_ebs_2024")
i <- x$inputs; o <- x$outputs
active <- i$measure=="proportion_at_age" & grepl("^Active",i$notes)
stopifnot(x$stocks$charbonneau_id=="AFSC_ macrocephalus_BSAI",
  x$stocks$ocean=="Northeast Pacific",
  grepl("Previous Charbonneau identifier retained as alias: AFSC_BSAI_Gadus_macrocephalus",x$stocks$notes,fixed=TRUE),x$assessment$terminal_year==2024,
  identical(as.integer(sort(unique(i$year[active]))),setdiff(2000:2023,2020)),
  all(i$type[active]=="index"),sum(active)==23*13,
  all(i$value[i$type=="M"]==.3866),!any(i$type=="weight"),!any(i$type=="maturity"),
  any(i$measure=="conditional_proportion_at_age" & i$type=="catch"),
  all(grepl("Inactive",i$notes[i$measure=="conditional_proportion_at_age" & i$type=="catch"])),
  all(i$unit[i$measure=="total_numbers"]=="thousand fish"),
  all(i$sampling_time[i$measure=="total_numbers"]==.5),
  o$value[o$measure=="SSB" & o$year==2024]==223289,
  o$se[o$measure=="SSB" & o$year==2024]==35481,
  o$value[o$measure=="combined_mature_biomass" & o$year==2024]==446577,
  o$se[o$measure=="combined_mature_biomass" & o$year==2024]==50177.3,
  o$value[o$measure=="recruitment" & o$year==2024]==621430)
n <- o[o$measure=="numbers_at_age",]
mid <- o[o$measure=="numbers_at_age_midyear",]
f <- o[o$measure=="fishing_mortality_at_age",]
key <- function(z)paste(z$year,z$age)
expected <- -2*log(mid$value[match(key(f),key(mid))]/n$value[match(key(f),key(n))])-.3866
stopifnot(nrow(n)==48*21,all(abs(f$value-expected)<1e-12),
  all(f$value>0),all(is.na(f$se)),
  sum(f$year %in% 2000:2023 & f$age %in% 1:20)==24*20)
cat("EBS cod activation, fixed M, number-index units, distinct female/native SSB and midyear survival identity passed.\n")
