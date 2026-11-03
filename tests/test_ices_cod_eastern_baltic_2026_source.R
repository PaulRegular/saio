db <- "database"
read_db <- function(f) data.table::fread(file.path(db,f),na.strings=c("","NA"),blank.lines.skip=TRUE,data.table=FALSE)
id <- "ices_cod_eastern_baltic_2026"
a<-subset(read_db("assessments.csv"),stock_id=="ck_ices_wgbfas_morhua_bs_25_32"); i<-subset(read_db("inputs.csv"),assessment_id==id); o<-subset(read_db("outputs.csv"),assessment_id==id)
stopifnot(sum(a$is_current)==1, a$is_current[a$assessment_id==id], !a$is_current[a$assessment_id=="ices_cod_eastern_baltic_2024"],nrow(i)==175,nrow(o)==35,all(o$year==1991:2025),all(o$unit=="kg/hour"),o$value[o$year==2025]==19.027, i$value[i$measure=="landings_biomass" & i$year==2025]==481,!any(o$measure=="SSB"))
cat("Eastern Baltic 2026 source coverage and units passed.\n")
