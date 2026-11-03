db<-"database"; read_db<-function(f)data.table::fread(file.path(db,f),na.strings=c("","NA"),blank.lines.skip=TRUE,data.table=FALSE)
id<-"nefsc_winter_flounder_gb_2025_wham"; i<-subset(read_db("inputs.csv"),assessment_id==id & source_type=="official_machine_readable");o<-subset(read_db("outputs.csv"),assessment_id==id & source_type=="official_machine_readable")
stopifnot(nrow(i)==33,nrow(o)==99,identical(sort(i$year),1982:2014),all(table(o$measure)==33),all(o$year>=1982 & o$year<=2014),all(o$age[o$measure=="recruitment"]==1),all(o$age_group[o$measure=="Fbar"]=="4-7"),all(is.na(o$se)),all(is.na(o$lwr)),all(is.na(o$upr)),all(i$unit=="tonnes"))
cat("Georges Bank winter flounder 2025 historical source coverage passed.\n")
