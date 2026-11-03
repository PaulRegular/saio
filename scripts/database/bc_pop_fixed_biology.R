# Run separately from curation and fitting; evaluate fixed source biology only.
source("scripts/database/pacific_sources.R")
cache <- "source_cache/dfo_pop_bc"
url <- "https://github.com/nmfs-ost/ss3-source-code/releases/download/v3.30.20/ss_win.exe"
exe <- cache_pacific_source("dfo_pop_bc",url,"framework/ss3_3.30.20.exe","v3.30.20")
directory <- file.path(cache,"fixed_biology_evaluation")
dir.create(directory,recursive=TRUE,showWarnings=FALSE)
file.copy(file.path(cache,"native",c("data.21.01.ss","control.21.01.ss","starter.ss","forecast.ss")),
  directory,overwrite=TRUE)
exe <- normalizePath(exe,winslash="/")
old <- setwd(directory)
tryCatch(system2(exe,c("-maxfn","0","-nohess","-nox"),stdout="evaluation.log",stderr="evaluation-errors.log"),
  finally=setwd(old))
stopifnot(file.info(file.path(directory,"wtatage.ss_new"))$size>0)
manifest_file <- file.path(cache,"manifest.csv")
manifest <- read.csv(manifest_file,stringsAsFactors=FALSE)
for(i in which(tolower(tools::file_ext(manifest$file))=="pdf")) {
  file <- file.path(cache,manifest$file[i])
  if(file.exists(file) && !identical(readBin(file,"raw",n=5),charToRaw("%PDF-"))) {
    manifest$status[i] <- "invalid PDF signature; not used as assessment evidence"
  }
}
files <- paste0("fixed_biology_evaluation/",c("wtatage.ss_new","evaluation.log","ss.par"))
manifest <- rbind(manifest[!manifest$file %in% files,],data.frame(
  file=files,url=url,retrieved=format(Sys.Date(),"%Y-%m-%d"),
  md5=unname(tools::md5sum(file.path(cache,files))),revision="v3.30.20; original R21v3 inputs; -maxfn 0 -nohess -nox",
  status="generated fixed-biology evaluation; not an official fitted output"))
utils::write.csv(manifest,manifest_file,row.names=FALSE,na="")
