source("scripts/database/pacific_tables.R")
id <- "afsc_cod_ebs_2024"
cache <- "source_cache/afsc_cod_ebs"
revision <- jsonlite::fromJSON(file.path(cache,"repository_revision.json"))$sha
native <- paste0("https://github.com/afsc-assessments/EBS_PCOD/blob/",revision,
  "/2024_ASSESSMENT/NOVEMBER_MODELS/APPENDIX_2.3_2024_MODELS.zip")
workbook <- "https://afsc-assessments.github.io/EBS_PCOD/2024_ASSESSMENT/NOVEMBER_MODELS/APPENDICES/Appendix_2.4_Data_and_results.xlsx"
report <- "https://files.npfmc.org/SAFE/2024/EBSpcod.pdf"
dat <- r4ss::SS_readdat(file.path(cache,"native/model_files/Model_24.1/BSPcod24_OCT_5cm_NB.dat"),verbose=FALSE)
sheet <- function(name) as.data.frame(readxl::read_excel(file.path(cache,"Appendix_2.4_Data_and_results.xlsx"),sheet=paste0("M24.1_",name)))
n <- sheet("NAGE"); w <- sheet("WTATAGE"); results <- sheet("RESULTS")
stopifnot(dat$styr==1977,dat$endyr==2024,dat$Ngenders==1,dat$Nages==20,
  dat$spawn_month==1,identical(dat$agebin_vector,as.numeric(0:12)))
input <- function(type,measure,basis,value,unit,year=NA_integer_,age=NA_integer_,fleet="",survey="",...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,basis=basis,value=value,
    unit=unit,year=year,age=age,fleet=fleet,survey=survey,sex="combined",region="Eastern Bering Sea",
    year_basis=ifelse(is.na(year),"","calendar_year"),source_type="native_model",source_reference=native,...)
}
catch <- dat$catch[dat$catch$year>=1977,]
index <- dat$CPUE[dat$CPUE$index==2,]
inputs <- list(
  input("catch","total_biomass","biomass",catch$catch,"t",catch$year,fleet="Fishery",
    notes="Native annual catch biomass, fixed log catch SD .001."),
  input("index","total_numbers","numbers",index$obs,"thousand fish",index$year,survey="VAST_survey",
    sampling_time=(index$seas-1)/12,notes="VAST abundance index in thousands of fish, not biomass; CPUEinfo Units=0."),
  input("index","log_index_sd","log_scale",index$se_log,"log SD",index$year,survey="VAST_survey",
    notes="Supplied log index SD before estimated extra SD."),
  input("M","natural_mortality_at_age","per_year",.3866,"per year",age=0:20,
    notes="Fixed native M, phase -2; not an estimated parameter.")
)
for(component in c("length","age")) {
  x <- if(component=="length")dat$lencomp else dat$agecomp
  bins <- if(component=="length")dat$lbin_vector else dat$agebin_vector
  begin <- if(component=="length")7L else 10L
  fishery <- abs(x$FltSvy)==1
  conditional <- if(component=="age")x$Lbin_lo==x$Lbin_hi else rep(FALSE,nrow(x))
  values <- as.vector(as.matrix(x[begin:(begin+length(bins)-1L)]))
  inputs[[length(inputs)+1L]] <- input(ifelse(fishery,"catch","index"),
    if(component=="length")"proportion_at_length" else ifelse(conditional,"conditional_proportion_at_age","proportion_at_age"),
    "proportion_numbers",values,"proportion",rep(x$Yr,length(bins)),
    age=if(component=="age")rep(bins,each=nrow(x)) else NA_integer_,
    fleet=ifelse(fishery,"Fishery",""),survey=ifelse(fishery,"","VAST_survey"),
    observation_id=paste(component,seq_len(nrow(x)),sep=":"),sample_size=x$Nsamp,partition=x$Part,
    age_error=if(component=="age")x$Ageerr else NA_integer_,
    length_bin=if(component=="length")rep(bins,each=nrow(x)) else NA_real_,
    length_bin_lower=if(component=="age")x$Lbin_lo else NA_real_,
    length_bin_upper=if(component=="age")x$Lbin_hi else NA_real_,
    sampling_time=ifelse(fishery,NA_real_,(x$Seas-1)/12),
    notes=paste(ifelse(x$FltSvy<0,"Inactive source likelihood row.","Active source likelihood row."),
      ifelse(conditional,"Biological conditional age samples; not an abundance index.","Native number proportions."),
      "Age 12 is the observation plus group; length labels are lower bin edges in cm. Supplied N retained before control weighting."))
}
output <- function(type,measure,value,unit,year,age=NA_integer_,se=NA_real_,...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,unit=unit,
    year=year,age=age,se=se,sex="combined",region="Eastern Bering Sea",
    source_type="official_machine_readable",source_reference=workbook,...)
}
yy <- 1977:2024
surface <- function(x) {
  m <- as.matrix(x[match(yy,x$Yr),as.character(0:20)])
  dimnames(m)<-list(yy,0:20); m
}
nb <- surface(n[n$`Beg/Mid`=="B",]); nm <- surface(n[n$`Beg/Mid`=="M",]); ww <- surface(w)
outputs <- list()
for(spec in list(list(nb,"population","numbers_at_age","thousand fish","Beginning-of-year N, worksheet NAGE B rows."),
                 list(nm,"population","numbers_at_age_midyear","thousand fish","Midyear N, worksheet NAGE M rows."),
                 list(ww,"biology","weight_at_age","kg/fish","Estimated population weights from WTATAGE, not supplied empirical biological inputs."))) {
  z <- pacific_matrix_long(spec[[1]])
  outputs[[length(outputs)+1L]] <- output(spec[[2]],spec[[3]],z$value,spec[[4]],z$year,z$age,
    age_group=ifelse(z$age==20,"20+",""),notes=spec[[5]])
}
# One continuous-mortality season: N(midyear) = N(January 1) exp(-Z/2).
f <- -2*log(nm/nb)-.3866
z <- pacific_matrix_long(f); z <- z[z$value>0,]
ff <- output("mortality","fishing_mortality_at_age",z$value,"per year",z$year,z$age,
  age_group=ifelse(z$age==20,"20+",""),
  notes="Derived as -2 log(N_mid/N_begin)-fixed M .3866 from rounded worksheet N. Nonpositive unresolved young-age estimates omitted, never clipped to zero. No SE reconstructed.")
ff$source_type <- "derived_source_output"
outputs[[length(outputs)+1L]] <- ff
for(prefix in c("SSB","Recr")) {
  z <- results[match(paste0(prefix,"_",yy),results$LABEL),]
  stopifnot(!anyNA(z$MEAN))
  outputs[[length(outputs)+1L]] <- output(if(prefix=="SSB")"biomass" else "recruitment",
    if(prefix=="SSB")"combined_mature_biomass" else "recruitment",z$MEAN,
    if(prefix=="SSB")"t" else "thousand fish",yy,age=if(prefix=="SSB")NA_integer_ else 0,se=z$SD,
    notes=if(prefix=="SSB")"Native single-sex SS worksheet SSB, before report conversion to female biomass. Twice the female point estimate; native SD retained on its own reported scale, not transformed into report uncertainty." else "Age-0 recruitment and natural-scale SD from official RESULTS worksheet; historical years only.")
}
text <- unlist(strsplit(paste(pdftools::pdf_text(file.path(cache,"assessment_2024.pdf")),collapse="\n"),"\n"))
first <- grep("^Table 2\\.26\\.",trimws(text))[1]; last <- grep("^Table 2\\.27\\.",trimws(text))[1]
rows <- text[seq.int(first+1,last-1)]
rows <- rows[grepl("^\\s*19[78-9][0-9]\\s+[0-9]",rows) | grepl("^\\s*200[0-2]\\s+[0-9]",rows)]
points <- list()
for(line in rows) {
  v <- scan(text=gsub(",","",line),quiet=TRUE)
  points[[length(points)+1L]] <- c(v[1],v[3],v[4])
  if(length(v)==12 && v[7]<=2024) points[[length(points)+1L]] <- c(v[7],v[9],v[10])
}
female <- do.call(rbind,points);female <- female[order(female[,1]),]
stopifnot(nrow(female)==47,identical(as.integer(female[,1]),1978:2024),female[47,2]==223289,
  max(abs(female[,2]-.5*results$MEAN[match(paste0("SSB_",female[,1]),results$LABEL)]))<=.5)
ssb <- output("biomass","SSB",female[,2],"t",female[,1],se=female[,3],
  notes="Female spawning biomass and reported SD, SAFE Table 2.26 Model 24.1. Report points are half native single-sex SS worksheet SSB. Report SDs are retained as printed; no undocumented SD conversion or CI inferred.")
ssb$sex <- "female";ssb$source_type <- "official_table";ssb$source_reference <- paste(report,"Table 2.26")
outputs[[length(outputs)+1L]] <- ssb
assume <- function(component,setting,value) pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=paste(native,";",workbook,";",report))
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2024 SSC-selected Model 24.1, Stock Synthesis 3.30.21; historical 1977-2024, ages 0-20+, one combined-sex population. Catalogue AFSC_BSAI_Gadus_macrocephalus."),
  assume("N","process","Deterministic survival; initial population informed by early recruitment deviations."),
  assume("recruitment","process","Beverton-Holt steepness fixed 1 (no stock-recruit dependence); estimated mean recruitment, fixed log SD .6908; early regime block and bias adjustments."),
  assume("F","process","Annual intensity with time-varying length selectivity; catch-at-length and survey marginal ages, no active fishery age-composition likelihood."),
  assume("M","process","M fixed .3866 at all years/ages, phase -2."),
  assume("q","process","Survey abundance q explicitly estimated (float=0, LnQ phase 6, bounds -.5 to .5), estimated extra survey SD; length selectivity and ageing error. Not fixed q."),
  assume("index","observation_model","VAST numbers in thousand fish at July 1, time .5. Active marginal survey ages only 2000-2023 excluding 2020 (23 rows). Other negative-fleet ages and conditional keys are inactive, not additional abundance observations."),
  assume("catch","observation_model","Annual catch tonnes with fixed log SD .001; length number compositions with supplied Nsamp. Conditional fishery age samples retained in native file but excluded from likelihood."),
  assume("biology","inputs","Estimated Richards growth with annual L1 and K deviations 2000-2024; no supplied weight-at-age. Fixed kg=5.40706e-6 * length_cm^3.19601; length maturity plogis(.132*(length-58)), first mature age 1; fixed female fraction .5; January spawning."),
  assume("source","estimate_convention","Maximum-likelihood points and natural-scale SDs. Worksheet SSB is combined mature biomass; report female SSB and SDs retained separately as printed. N and weights are rounded model outputs, not source observations.")
))
stock <- pacific_database_row("stocks",stock_id="afsc_cod_ebs",charbonneau_id="AFSC_BSAI_Gadus_macrocephalus",
  authority="NOAA-AFSC",authority_stock_id="EBS Pacific cod",scientific_name="Gadus macrocephalus",
  common_name="Eastern Bering Sea Pacific cod",area="Eastern Bering Sea",region="Bering Sea",ocean="Northeast Pacific")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2024,terminal_year=2024,estimate_terminal_year=2024,assessment_type="full",
  model_family="Stock Synthesis",model_version="24.1 / SS 3.30.21",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,data_url=workbook,model_url=native,
  repository_url="https://github.com/afsc-assessments/EBS_PCOD",
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Selected production model verified against December 2024 SSC. Native length/conditional-age inputs and activation retained. Original full ageing-error inventory and full fitted selectivity surfaces not transcribed; F recovered from rounded beginning/midyear N. No supplied stock weights; computed weights remain outputs.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
