db<-"database"; read_db<-function(f)data.table::fread(file.path(db,f),na.strings=c("","NA"),blank.lines.skip=TRUE,data.table=FALSE)
id<-"nefsc_scup_2025";i<-subset(read_db("inputs.csv"),assessment_id==id & source_type=="official_machine_readable");o<-subset(read_db("outputs.csv"),assessment_id==id & source_type=="official_machine_readable")
stopifnot(nrow(i)==31,nrow(o)==93,identical(sort(i$year),1984:2014),all(table(o$measure)==31),all(o$year>=1984 & o$year<=2014),all(o$age[o$measure=="recruitment"]==0),all(o$age_group[o$measure=="stocksmart_reported_Ffull"]=="age 4"),all(is.na(o$se)),all(is.na(o$lwr)),all(is.na(o$upr)),all(grepl("convention is unresolved",o$notes[o$measure!="recruitment"],fixed=TRUE)))
cat("Scup 2025 archive source coverage and scale labeling passed.\n")
