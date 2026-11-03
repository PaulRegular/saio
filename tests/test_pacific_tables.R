source("scripts/database/pacific_tables.R")
for(table in c("stocks","assessments","assumptions","inputs","outputs")) {
  expected <- names(read.csv(file.path("database",paste0(table,".csv")),nrows=0,check.names=FALSE))
  z <- pacific_database_row(table,n=2)
  stopifnot(identical(names(z),expected),nrow(z)==2,all(is.na(z)))
}
z <- pacific_database_row("inputs",assessment_id="example",value=1:3,age=5:7)
stopifnot(identical(z$value,1:3),all(z$assessment_id=="example"),identical(z$age,5:7))
bad <- tryCatch(pacific_database_row("inputs",unknown_field=1),error=identity)
stopifnot(inherits(bad,"error"),grepl("Unknown inputs column",conditionMessage(bad)))
cat("Pacific row construction preserves every database header and vector field without scanning full CSVs.\n")
