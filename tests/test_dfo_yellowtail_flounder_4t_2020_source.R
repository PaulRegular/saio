root <- "."
read_table <- function(name) utils::read.csv(file.path(root,"database",paste0(name,".csv")),
  stringsAsFactors=FALSE,check.names=FALSE,na.strings=c("","NA"))
id <- "dfo_yellowtail_flounder_4t_2020"
stock <- subset(read_table("stocks"),stock_id=="dfo_yellowtail_flounder_4t")
assessments <- read_table("assessments")
historical <- subset(assessments,assessment_id==id)
current <- subset(assessments,assessment_id=="dfo_yellowtail_flounder_4t_2025")
inputs <- subset(read_table("inputs"),assessment_id==id)
outputs <- subset(read_table("outputs"),assessment_id==id)
assumptions <- subset(read_table("assumptions"),assessment_id==id)
provenance <- read.csv(file.path(root,"provenance","discovery_dfo_gulf_yellowtail_2026","sources.csv"),
  stringsAsFactors=FALSE,check.names=FALSE,na.strings=c("","NA"))
source <- subset(provenance,file=="Status_Yellowtail_4T_to_2020.pdf")
review <- paste(readLines(file.path(root,"source_reviews","dfo_yellowtail_flounder_4t_2020.md"),
  warn=FALSE),collapse="\n")
land <- subset(inputs,type=="catch" & measure=="landings_biomass")
index <- subset(inputs,type=="index" & measure=="total_biomass")
N <- subset(outputs,type=="population" & measure=="numbers_at_age")
biomass <- subset(outputs,measure=="biomass_length_group")
refs <- subset(outputs,measure %in% c("Bmsy","USR","LRP"))
ratio <- subset(outputs,measure=="biomass_ratio_to_LRP")
stopifnot(
  nrow(stock)==1L,nrow(historical)==1L,historical$stock_id==stock$stock_id,
  historical$assessment_year==2021L,historical$terminal_year==2020L,!historical$is_current,
  historical$is_applied,historical$inputs_status=="partial",historical$outputs_status=="partial",
  nrow(current)==1L,current$is_current,current$terminal_year==2025L,
  nrow(land)==36L,identical(sort(land$year),1985:2020),
  land$value[land$year==1985L]==215,land$value[land$year==2020L]==136.2,
  all(land$unit=="t"),
  all(land$source_reference==paste0("https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41063533.pdf; Table 2, printed p. 18")),
  nrow(index)==72L,identical(sort(unique(index$year)),1985:2020),
  setequal(unique(index$length_bin),c("<25 cm",">=25 cm")),all(index$unit=="kg/tow"),
  index$value[index$year==1985L & index$length_bin=="<25 cm"]==0.174,
  index$value[index$year==2020L & index$length_bin==">=25 cm"]==0.32,
  all(index$season=="September"),nrow(inputs)==108L,
  !any(inputs$measure %in% c("proportion_at_length","weight_at_age","maturity_at_age")),
  nrow(N)==4L,N$value[N$age_group=="1-3"]==520,sum(N$age_group=="4-5")==2L,
  all(N$value[N$age_group=="4-5"]==95),N$value[N$age_group=="6+"]==3,
  nrow(biomass)==1L,biomass$value==2230,nrow(ratio)==1L,ratio$year==2020L,
  nrow(refs)==3L,all(is.na(refs$year)),
  all(!is.na(refs$lwr) & !is.na(refs$upr)),all(is.na(N$lwr)&is.na(N$upr)),
  !any(outputs$measure %in% c("SSB","recruitment","fishing_mortality_at_age","natural_mortality_at_age")),
  nrow(assumptions)==17L,nrow(source)==1L,
  source$sha256=="E73496C2339ED25046C96013D30DAAAD03BE8D70EE1D103EC61DCC5FE50C4894",
  as.numeric(source$bytes)==13672734,
  grepl("no annual SSB is entered",review,fixed=TRUE),
  grepl("No age compositions, weights or maturity observations are reconstructed or inferred.",review,fixed=TRUE)
)
cat("DFO 4T yellowtail flounder 2021/2020 source import checks passed.\n")
