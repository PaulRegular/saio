source("scripts/database/pacific_tables.R")
id <- "afsc_cod_ai_2024"
cache <- "source_cache/afsc_cod_ai"
report <- "https://files.npfmc.org/SAFE/2024/AIpcod.pdf"
lines <- unlist(strsplit(paste(pdftools::pdf_text(file.path(cache,"assessment_2024.pdf")),collapse="\n"),"\n"))
table_lines <- function(number) {
  first <- grep(paste0("^\\s*Table\\s*2A\\.\\s*",number,":"),lines)[1]
  last <- grep(paste0("^\\s*Table\\s*2A\\.\\s*",number+1,":"),lines)[1]
  z <- lines[seq.int(first+1,last-1)]
  z[grepl("^\\s*(19[89][0-9]|20[012][0-9])\\s+[0-9]",z)]
}
numeric_table <- function(number) do.call(rbind,lapply(table_lines(number),function(line)
  scan(text=gsub(",","",line),quiet=TRUE)))
input <- function(type,measure,basis,value,unit,year,age=NA_integer_,...) {
  pacific_database_row("inputs",assessment_id=id,type=type,measure=measure,basis=basis,value=value,
    unit=unit,year=year,age=age,sex="combined",region="Aleutian Islands",
    year_basis="calendar_year",source_type="official_table",source_reference=report,...)
}
c <- numeric_table(6)
stopifnot(nrow(c)==34,ncol(c)==6,c[34,1]==2024,c[34,5]==3570)
inputs <- list(input("catch","total_biomass","biomass",c[1:33,5],"t",c[1:33,1],
  fleet="Combined_fishery",notes="Table 2A.6 original rounded catch including state fishery; historical complete years only. 2024 partial 3570 t is not a full-year model catch."),
  input("catch","total_biomass","biomass",4676,"t",2024,fleet="Combined_fishery",
    notes="Table 2A.24 common 2024 catch across all projections, corroborated in native data_echo. Not partial reported landings of 3570 t."),
  input("M","natural_mortality_at_age","per_year",.417,"per year",rep(1991:2015,14),rep(0:13,each=25),
    notes="Documented fixed pre-2016 baseline only. M from 2016 onward is estimated and is not entered as a fixed input."))
# Columns are unambiguous when a trawl biomass is present; longline-only rows are not trawl data.
z <- table_lines(14)
trawl_years <- c(1991,1994,1997,2000,2002,2004,2006,2010,2012,2014,2016,2018,2022,2024)
rows <- lapply(z,function(line)strsplit(trimws(gsub(",","",line)),"[[:space:]]+")[[1]])
rows <- rows[vapply(rows,function(v)as.numeric(v[1]) %in% trawl_years,logical(1))]
yy <- vapply(rows,function(v)as.numeric(v[1]),numeric(1))
bio <- vapply(rows,function(v)as.numeric(v[2]),numeric(1))
relative_se <- vapply(rows,function(v)as.numeric(v[3]),numeric(1))
stopifnot(identical(yy,as.numeric(trawl_years)),bio[length(bio)]==50383)
inputs[[length(inputs)+1L]] <- input("index","total_biomass","biomass",bio,"t",yy,
  survey="AI_bottom_trawl",sampling_time=.5,
  notes="Table 2A.14 trawl biomass series explicitly used in model; 2022 value 51539 differs slightly from Table 2A.12 area sum 51543. Midyear timing corroborated by native survey month 7; no age allocation invented.")
inputs[[length(inputs)+1L]] <- input("index","index_sd","relative_scale",relative_se,"reported relative SE",yy,
  survey="AI_bottom_trawl",notes="Table 2A.14 S.E. column retained on reported fractional scale. Do not mistake .161 for 0.161 tonnes or silently infer a log SD.")
output <- function(type,measure,value,unit,year,age=NA_integer_,se=NA_real_,...) {
  pacific_database_row("outputs",assessment_id=id,type=type,measure=measure,value=value,unit=unit,
    year=year,age=age,se=se,sex="combined",region="Aleutian Islands",source_type="official_table",source_reference=report,...)
}
outputs <- list()
for(spec in list(c(18,"biomass","total_biomass","t"),c(19,"biomass","SSB","t"),
                 c(20,"recruitment","recruitment","thousand fish"))) {
  z <- numeric_table(as.numeric(spec[1]));z <- z[z[,1]>=1991,]
  stopifnot(nrow(z)==34,identical(as.integer(z[,1]),1991:2024))
  outputs[[length(outputs)+1L]] <- output(spec[2],spec[3],z[,2],spec[4],z[,1],
    age=if(spec[2]=="recruitment")0 else NA_integer_,
    lwr=if(ncol(z)==10)z[,3] else NA_real_,upr=if(ncol(z)==10)z[,4] else NA_real_,
    notes=paste("Table 2A.",spec[1],"Model 24.1 column only. Pre-start rows labelled 1989/1990 are equilibrium/initial summaries, not extra historical years; excluded.",
      if(spec[3]=="SSB")"As printed, caption calls this female SSB; single-sex reproductive-output versus female-biomass scaling remains unresolved. Do not silently halve values or intervals." else if(spec[3]=="recruitment")"Age-0 recruitment in thousands, original reported 95% limits retained; no SE inferred." else "Original all-age biomass; no age distribution or SE recovered."))
  if(spec[3]=="SSB")outputs[[length(outputs)]]$sex <- "female"
}
outputs[[length(outputs)+1L]] <- output("mortality","natural_mortality_at_age",.5703,"per year",
  rep(2016:2024,14),rep(0:13,each=9),se=.0371,
  notes="Table 2A.21 final Model 24.1 estimated M replacement block from 2016 onward, natural-scale SD. Earlier M fixed .417. No source M made a fixed post-2015 input.")
outputs[[length(outputs)+1L]] <- output("catchability","q",.87,"index multiplier",NA_integer_,survey="AI_bottom_trawl",
  notes="Rounded analytically estimated trawl q, Table2A.3 and methods. No SE recovered; not fixed q or an age-specific coefficient.")
assume <- function(component,setting,value) pacific_database_row("assumptions",assessment_id=id,
  component=component,setting=setting,value=value,source_reference=report)
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2024 SSC-selected age-structured Tier3 Model24.1, SS3; historical 1991-2024 ages0-13+, one combined-sex population. Historical catalogue Tier5 label does not determine present eligibility."),
  assume("N","process","Deterministic survival with early initial-age/recruitment deviations."),
  assume("recruitment","process","Constant mean with lognormal deviations 1991-2021; 2022 onward fixed at mean1991-2021, early initial-age estimates. Recruitment SD tuned before Francis reweighting; numerical final SD not verified."),
  assume("F","process","Annual F with logistic fishery/survey selectivity constant over time, as described in selected-model methods. Final original length data and fully matching configuration remain unverified."),
  assume("q","process","Trawl survey q estimated analytically, final rounded .87; no explicit q parameter/prior substituted from another run."),
  assume("M","process","Fixed .417 before2016, estimated replacement block from2016 (final .5703 SD .0371). Public September native run estimates .571771, not the final report value."),
  assume("catch","observation_model","Total catch and fishery length compositions, no active fishery age likelihood. Fishery catch2024 model input4676 t differs from partial September landings3570 t."),
  assume("index","observation_model","Midyear trawl biomass and conditional survey age-at-length, not an independent age-specific abundance index. Longline relative-population series also tabulated but not substituted for the selected model's trawl likelihood."),
  assume("biology","inputs","Estimated Richards growth; fixed kg=5.40706e-6*cm^3.19601; updated maturity at length A=-8.589 B=.155 in final report. Original final population weights not recovered; Table2A.17 age maturity is a converted summary, not a supplied empirical matrix."),
  assume("source","run_identity","Public M24_1 data_echo/Report timestamp September26. Final November Rmd loads local November2024/M24_1_data/run not published in repository. L1 final14.0937 versus public14.1037 and M final.5703 versus.571771. Native final N/F/weight surfaces not verified, so preliminary fitted outputs are not imported."),
  assume("source","reporting_caution","Table2A.19 labels SSB female but values exceed half total biomass; projection female SSB uses a different apparent single-sex scaling. Retain values/limits exactly as printed; comparison requires final source output to resolve convention.")
))
stock <- pacific_database_row("stocks",stock_id="afsc_cod_ai",charbonneau_id="AFSC_AI_Gadus_macrocephalus",
  authority="NOAA-AFSC",authority_stock_id="Aleutian Islands Pacific cod",scientific_name="Gadus macrocephalus",
  common_name="Aleutian Islands Pacific cod",area="Aleutian Islands",region="Aleutian Islands",ocean="Northeast Pacific")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id=stock$stock_id,
  assessment_year=2024,terminal_year=2024,estimate_terminal_year=2024,assessment_type="full",
  model_family="Stock Synthesis",model_version="2024 Model24.1",is_current=TRUE,is_applied=TRUE,
  assessment_url=report,framework_url=report,repository_url="https://github.com/afsc-assessments/AI_PCOD",
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Final official PDF aggregate outputs and recoverable inputs retained. Public native M24_1 fit predates and differs from final November production run; not mixed with final results. Verified final length/conditional-age inputs, stock weights and N/F states unavailable; translation blocked pending matching native source.")
append_pacific_case(stock,assessment,assumptions,do.call(rbind,inputs),do.call(rbind,outputs))
