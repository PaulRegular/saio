# Run separately from fitting. Evaluate fixed biology; do not optimize or import states.
source("scripts/database/pacific_sources.R")
cache <- "source_cache/dfo_canary_bc"
url <- "https://github.com/nmfs-ost/ss3-source-code/releases/download/v3.30.18/ss_win.exe"
exe <- cache_pacific_source("dfo_canary_bc", url, "framework/ss3_3.30.18.exe", "v3.30.18")
directory <- file.path(cache, "fixed_biology_evaluation")
dir.create(directory, recursive = TRUE, showWarnings = FALSE)
file.copy(file.path(cache, "native", c("data.24.01.ss", "control.24.01.ss", "starter.ss", "forecast.ss")),
          directory, overwrite = TRUE)
exe <- normalizePath(exe, winslash = "/")
old <- setwd(directory)
status <- tryCatch(system2(exe, c("-maxfn", "0", "-nohess", "-nox"),
  stdout = "evaluation.log", stderr = "evaluation-errors.log"), finally = setwd(old))
stopifnot(status == 0L, file.info(file.path(directory, "wtatage.ss_new"))$size > 0)
manifest_file <- file.path(cache, "manifest.csv")
manifest <- read.csv(manifest_file)
files <- paste0("fixed_biology_evaluation/", c("wtatage.ss_new", "evaluation.log", "ss.par"))
manifest <- rbind(manifest[!manifest$file %in% files, ], data.frame(
  file = files, url = url, retrieved = format(Sys.Date(), "%Y-%m-%d"),
  md5 = unname(tools::md5sum(file.path(cache, files))),
  revision = "v3.30.18; original Run24/24.01 fixed biology; -maxfn 0 -nohess -nox",
  status = "generated fixed-biology evaluation only; not official fitted output"))
write.csv(manifest, manifest_file, row.names = FALSE, na = "")
