root <- "."
cache <- "source_cache/noaa_red_grouper_sedar53_2017"
assessment_id <- "noaa_red_grouper_south_atlantic_sedar53_2017"
stock_id <- "noaa_red_grouper_south_atlantic"
candidate_id <- "NOAA:10332"
write_mode <- "--write" %in% commandArgs(trailingOnly=TRUE) || identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")
source("scripts/database/pacific_tables.R"); source("scripts/database/candidate_register_io.R")
manifest <- read.csv("provenance/noaa_red_grouper_sedar53_2017/manifest.csv", colClasses="character", check.names=FALSE)
sha256 <- function(path) {
  x <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout=TRUE)
  h <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", x, value=TRUE)))
  if(length(h)!=1L) stop("Could not calculate source SHA-256.")
  h
}
verify <- function(name) {
  r <- manifest[basename(manifest$file)==name,,drop=FALSE]; p <- file.path(cache,name)
  if(nrow(r)!=1L || !file.exists(p) || as.numeric(r$bytes)!=file.info(p)$size || !identical(sha256(p),tolower(r$sha256))) stop("Source/provenance mismatch: ",name)
  p
}
pdf <- verify("sedar53_red_grouper_sar_2017.pdf"); wp05 <- verify("sedar53_wp05_commercial_age_composition_2016.pdf"); verify("sedar53_wp08_recreational_age_composition_2016.pdf")
if(!requireNamespace("pdftools",quietly=TRUE)) stop("Install pdftools to extract SEDAR 53.")
rp <- pdftools::pdf_text(pdf); wp <- pdftools::pdf_text(wp05)
num <- function(x) { x[x=="."]<-NA_character_; suppressWarnings(as.numeric(gsub(",","",x,fixed=TRUE))) }
parse_year <- function(pages,page,years,n) {
  out<-list(); lines<-strsplit(pages[[page]],"\n",fixed=TRUE)[[1L]]
  for(line in lines) { x<-strsplit(trimws(line),"[[:space:]]+")[[1L]]; pos<-which(x%in%as.character(years)); if(!length(pos)) next; pos<-pos[1L]; y<-as.integer(x[pos]); if(length(x)-pos!=n) next; if(as.character(y)%in%names(out)) stop("Duplicate year ",y," on page ",page); out[[as.character(y)]]<-num(x[seq.int(pos+1L,length(x))]) }
  if(!setequal(names(out),as.character(years))) stop("Unexpected year coverage on page ",page)
  z<-do.call(rbind,out[as.character(years)]); rownames(z)<-as.character(years); z
}
parse_age <- function(pages,page,ages,n) {
  out<-list(); lines<-strsplit(pages[[page]],"\n",fixed=TRUE)[[1L]]
  for(line in lines) { x<-strsplit(trimws(line),"[[:space:]]+")[[1L]]; if(!length(x)||!x[1L]%in%as.character(ages)||length(x)!=n+1L) next; out[[x[1L]]]<-num(x[-1L]) }
  if(!setequal(names(out),as.character(ages))) stop("Unexpected ages on page ",page)
  z<-do.call(rbind,out[as.character(ages)]); rownames(z)<-as.character(ages); z
}
years<-1976:2015; oy<-1976:2016; ages<-1:16
bio<-parse_age(rp,64L,ages,8L); catch<-parse_year(rp,65L,years,7L); idx<-parse_year(rp,66L,1980:2015,6L)
nf<-parse_year(rp,67L,years,10L); nt<-parse_year(rp,68L,years,10L)
nage<-parse_year(rp,69L,oy,17L); bage<-parse_year(rp,70L,oy,17L); status<-parse_year(rp,71L,oy,8L); fatage<-parse_year(rp,74L,years,16L)
comp<-parse_year(wp,7L,1996:2015,18L)
if(any(abs(rowSums(comp[,3:18,drop=FALSE],na.rm=TRUE)-1)>.003)) stop("WP05 age proportions fail sum check.")
ins<-list(); outs<-list()
add_i<-function(type,measure,basis,value,unit,ref,notes,fleet=NA,survey=NA,sex=NA,year=NA,age=NA,part=NA,obs=NA,trans=NA) {
 n<-length(value); ins[[length(ins)+1L]]<<-pacific_database_row("inputs",n=n,assessment_id=assessment_id,type=type,measure=measure,basis=basis,fleet=fleet,survey=survey,sex=sex,year=year,year_basis=ifelse(is.na(year),NA,"calendar_year"),age=age,value=value,unit=unit,source_type="official_table",source_reference=ref,notes=notes,partition=part,observation_id=obs,transformation=trans)
}
add_o<-function(type,measure,value,unit,ref,notes,year=NA,age=NA,group=NA,scenario=NA) {
 n<-length(value); outs[[length(outs)+1L]]<<-pacific_database_row("outputs",n=n,assessment_id=assessment_id,type=type,measure=measure,year=year,age=age,age_group=group,scenario=scenario,value=value,unit=unit,se=NA_real_,source_type="official_table",source_reference=ref,notes=notes)
}
for(j in seq_along(ages)) {
 a<-ages[j]; add_i("biology","growth_length_at_age","native_covariate",bio[j,1],"mm","SEDAR 53 SAR, Table 1","Fixed mid-year length; age 16 is 16+.",age=a)
 add_i("weight","weight_at_age","kg_per_fish",bio[j,4],"kg/fish","SEDAR 53 SAR, Table 1","Fixed mid-year whole weight; age 16 is 16+.",age=a)
 add_i("maturity","maturity_at_age","proportion",bio[j,6],"proportion","SEDAR 53 SAR, Table 1","Fixed female maturity.",sex="female",age=a)
 add_i("biology","proportion_female_at_age","proportion",bio[j,7],"proportion","SEDAR 53 SAR, Table 1","Fixed proportion female.",age=a)
 add_i("maturity","maturity_at_age","proportion",1,"proportion","SEDAR 53 SAR, Section 3.3","The report states that all males are mature.",sex="male",age=a,trans="Encoded report statement as 1.")
 add_i("M","natural_mortality_at_age","per_year",bio[j,8],"per_year","SEDAR 53 SAR, Table 1","Fixed age-varying M; not an estimated process.",age=a)
}
catch_specs<-list(list(1,"Commercial lines","landings_biomass","biomass","1,000 lb whole weight","landings"),list(2,"Commercial other","landings_biomass","biomass","1,000 lb whole weight","landings"),list(3,"Headboat","landings_numbers","numbers","1,000 fish","landings"),list(4,"General recreational","landings_numbers","numbers","1,000 fish","landings"),list(5,"Commercial lines","discard_numbers","numbers","1,000 fish","all_releases"),list(6,"Headboat","discard_numbers","numbers","1,000 fish","all_releases"),list(7,"General recreational","discard_numbers","numbers","1,000 fish","all_releases"))
for(s in catch_specs) { v<-catch[,s[[1]]]; k<-is.finite(v); add_i("catch",s[[3]],s[[4]],v[k],s[[5]],"SEDAR 53 SAR, Table 2","Observed aggregate catch, not catch-at-age. Releases include live and dead fish.",fleet=s[[2]],year=years[k],part=s[[6]]) }
for(s in list(list(1,2,"Commercial handline index"),list(3,4,"Headboat index"),list(5,6,"SERFS chevron trap/video index"))) {
 v<-idx[,s[[1]]]; k<-is.finite(v); add_i("index","relative_abundance_index","index_scale",v[k],"relative index units","SEDAR 53 SAR, Table 3","Observed aggregate abundance index.",survey=s[[3]],year=(1980:2015)[k])
 v<-idx[,s[[2]]]; k<-is.finite(v); add_i("index","abundance_index_cv","relative_scale",v[k],"ratio","SEDAR 53 SAR, Table 3","Source-reported index CV.",survey=s[[3]],year=(1980:2015)[k])
}
cs<-list(list(1,"Commercial handline","length"),list(2,"Commercial other","length"),list(3,"Headboat","length"),list(4,"General recreational","length"),list(5,"Headboat discards","length"),list(6,"SERFS chevron trap/video","length"),list(7,"Commercial handline","age"),list(8,"Headboat","age"),list(9,"General recreational","age"),list(10,"SERFS chevron trap/video","age"))
for(t in 4:5) for(s in cs) { x<-if(t==4)nf else nt; v<-x[,s[[1]]]; k<-is.finite(v); if(any(k)) add_i("biology","composition_sample_count","numbers",v[k],if(t==4)"fish" else "trips",paste0("SEDAR 53 SAR, Table ",t),paste("Sample size for",s[[3]],"composition; not proportions."),fleet=s[[2]],year=years[k],obs=paste0("Table",t,"_",s[[3]],"_composition")) }
for(j in seq_along(ages)) add_i("biology","proportion_at_age","proportion",comp[,2+j],"proportion","SEDAR 53-WP05, Table 3","Weighted commercial handline/longline proportions; ages 17-25 pooled into 16+. The source has a 1996 row although SAR Table 4 lists no commercial age sample that year.",fleet="Commercial lines (handline and longline)",year=1996:2015,age=ages[j],obs="SEDAR53_WP05_Table3_age_composition",trans="Stored as printed without rescaling.")
fc<-ifelse(oy==2016,"2016 assessment forecast",NA_character_)
for(j in seq_along(ages)) { g<-if(ages[j]==16)"16+" else NA_character_; add_o("population","numbers_at_age",nage[,j],"1,000 fish","SEDAR 53 SAR, Table 6","Estimated start-of-year abundance; age 16 is 16+; 2016 is forecast.",oy,ages[j],g,fc); add_o("biomass","biomass_at_age",bage[,j],"1,000 lb whole weight","SEDAR 53 SAR, Table 7","Estimated start-of-year biomass; age 16 is 16+; 2016 is forecast.",oy,ages[j],g,fc); add_o("mortality","fishing_mortality_at_age",fatage[,j],"per_year","SEDAR 53 SAR, Table 11","Estimated instantaneous fishing mortality at age; age 16 is the 16+ group.",years,ages[j],g) }
add_o("population","total_numbers",nage[,17],"1,000 fish","SEDAR 53 SAR, Table 6","Reported table total, not recomputed from rounded age rows.",oy,scenario=fc)

ss<-list(list(1,"mortality","apical_F","per_year"),list(2,"mortality","F_ratio_to_Fmsy","ratio"),list(3,"biomass","total_biomass","metric tons"),list(4,"biomass","total_biomass_ratio_to_unfished","ratio"),list(5,"biomass","SSB","metric tons"),list(6,"biomass","SSB_ratio_to_SSBMSY","ratio"),list(7,"biomass","SSB_ratio_to_MSST","ratio"))
for(s in ss) { v<-status[,s[[1]]]; k<-is.finite(v); add_o(s[[2]],s[[3]],v[k],s[[4]],"SEDAR 53 SAR, Table 8","Annual estimate; B is start-of-year and SSB is peak-spawning biomass.",oy[k],scenario=fc[k]) }
inputs<-do.call(rbind,ins); outputs<-do.call(rbind,outs)
assumptions<-do.call(rbind,list(
 pacific_database_row("assumptions",assessment_id=assessment_id,component="assessment",setting="run_identity",value="SEDAR 53 South Atlantic red grouper; 2017; data through 2015.",source_reference="SEDAR 53 SAR, cover and executive summary",notes="Latest completed detailed assessment located for NOAA unit 10332."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="model",setting="model_family",value="Beaufort Assessment Model statistical catch-age assessment; ages 1-16+.",source_reference="SEDAR 53 SAR, Section 3.3 and Tables 1-8",notes="Age 16 is the accumulator; 2016 is forecast."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="catch",setting="catch_units",value="Commercial landings in 1,000 lb whole weight; recreational landings and all releases in 1,000 fish.",source_reference="SEDAR 53 SAR, Table 2",notes="Table 2 values are aggregate, not catch-at-age; releases include live and dead fish."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="composition",setting="age_length_compositions",value="Age and length compositions are fitted for commercial, recreational and SERFS sources.",source_reference="SEDAR 53 SAR Tables 4-5; SEDAR 53-WP05 Table 3",notes="Sample sizes and WP05 commercial age proportions imported. SAR Table 4 omits a 1996 commercial age sample although WP05 includes it; other numeric composition proportions were not recovered."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="index",setting="abundance_indices",value="Three aggregate indices: commercial handline, headboat, SERFS chevron trap/video.",source_reference="SEDAR 53 SAR, Table 3",notes="Index values and CVs imported; none are age-specific."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="M",setting="natural_mortality",value="Fixed, age-varying Lorenzen M rescaled to survival equivalent to constant M=0.14 through age 26.",source_reference="SEDAR 53 SAR, Section 3.3 and Table 1",notes="Source M-at-age values are fixed inputs, not an estimated process."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="biology",setting="age_biology",value="Fixed length, weight, female maturity, proportion female, and age-varying M; all males mature.",source_reference="SEDAR 53 SAR, Section 3.3 and Table 1",notes="Male maturity is encoded as 1 from the report statement. SSB is both-sex mature biomass at peak spawning."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="timing",setting="survey_timing",value="No common within-year fraction is reported for the annual indices.",source_reference="SEDAR 53 SAR, Sections 3.3-3.4 and Table 3",notes="Any single fraction would be an approximation."),
 pacific_database_row("assumptions",assessment_id=assessment_id,component="uncertainty",setting="annual_output_uncertainty",value="Tables 6-8 and 11 provide point estimates without annual intervals.",source_reference="SEDAR 53 SAR, Tables 6-8 and 11",notes="No age-specific standard errors or intervals inferred.")))
stock<-pacific_database_row("stocks",stock_id=stock_id,charbonneau_id="",authority="NOAA Fisheries",authority_stock_id="10332",scientific_name="Epinephelus morio",common_name="Red grouper - South Atlantic Coast",area="South Atlantic Coast",region="United States South Atlantic Coast",ocean="Northwest Atlantic",notes="NOAA Stock SMART unit 10332; distinct from Gulf unit 10331.")
assessment<-pacific_database_row("assessments",assessment_id=assessment_id,stock_id=stock_id,assessment_year=2017L,terminal_year=2015L,estimate_terminal_year=2015L,assessment_type="benchmark_assessment",model_family="Beaufort Assessment Model",model_version="SEDAR 53 benchmark assessment, February 2017",is_current="TRUE",is_applied="TRUE",assessment_url="https://sedarweb.org/documents/sedar-53-stock-assessment-report-south-atlantic-red-grouper/",framework_url="https://sedarweb.org/assessments/sedar-53/",data_url="https://sedarweb.org/assessments/sedar-53/",assumptions_status="partial",inputs_status="partial",outputs_status="partial",notes="Latest completed detailed assessment located for unit 10332; data through 2015 with 2016 forecast. Numeric compositions and annual output uncertainty remain incomplete.")
cp<-"discovery/candidates.csv"; c<-read.csv(cp,colClasses="character",na.strings=c("","NA"),check.names=FALSE); cr<-which(c$candidate_id==candidate_id)
st<-read.csv("database/stocks.csv",na.strings=c("","NA"),check.names=FALSE); ad<-read.csv("database/assessments.csv",na.strings=c("","NA"),check.names=FALSE)
if(length(cr)!=1L||c$candidate_unit_id[cr]!=stock_id||c$eligibility[cr]!="eligible"||c$import_status[cr]!="not_started"||any(st$stock_id==stock_id)||any(st$authority=="NOAA Fisheries"&st$authority_stock_id=="10332")||any(ad$assessment_id==assessment_id)) stop("Candidate/database identity conflict.")
ip<-"discovery/inventory_units.csv"; inv<-read.csv(ip,colClasses="character",na.strings=c("","NA"),check.names=FALSE); ir<-candidate_inventory_row(inv,candidate_id,stock_id)
ik<-paste(inputs$type,inputs$measure,inputs$fleet,inputs$survey,inputs$sex,inputs$year,inputs$age,inputs$partition,inputs$observation_id,sep="|"); ok<-paste(outputs$type,outputs$measure,outputs$year,outputs$age,outputs$age_group,outputs$scenario,sep="|")
if(nrow(inputs)<700||nrow(outputs)<2100||any(!is.finite(inputs$value))||any(!is.finite(outputs$value))||anyDuplicated(ik)||anyDuplicated(ok)) stop("SEDAR 53 coverage/uniqueness check failed.")
if(write_mode) { append_pacific_case(stock,assessment,assumptions,inputs,outputs); c$matched_stock_id[cr]<-stock_id;c$match_status[cr]<-"matched";c$import_status[cr]<-"partial";c$review_date[cr]<-as.character(Sys.Date());c$output_evidence[cr]<-paste(c$output_evidence[cr],"Imported aggregate catch, index/CV, sample sizes, biology, WP05 commercial age compositions and SEDAR 53 Tables 6-8 and 11 outputs; other compositions and annual uncertainty unavailable.");replace_candidate_register_row(cp,cr,c[cr,,drop=FALSE],candidate_id);inv$matched_stock_id[ir]<-stock_id;inv$match_status[ir]<-"matched";inv$import_status[ir]<-"partial";replace_csv_register_row(ip,ir,inv[ir,,drop=FALSE],"unit_key",inv$unit_key[ir]) } else message("Dry run: ",nrow(stock)," stock, ",nrow(assessment)," assessment, ",nrow(assumptions)," assumptions, ",nrow(inputs)," inputs, and ",nrow(outputs)," outputs from SEDAR 53 and WP05.")