source("R/read_database.R")

database <- read_database()
source_data <- read_assessment("ices_cod_western_baltic_2026", database)
old <- read_assessment("ices_cod_western_baltic_2025", database)
inputs <- source_data$inputs
outputs <- source_data$outputs
rows <- function(x, type, measure) x[x$type == type & x$measure == measure,,drop=FALSE]
catch <- rows(inputs,"catch","numbers_at_age")
q1 <- inputs[!is.na(inputs$survey) & inputs$survey == "BITS Q1",,drop=FALSE]
q4 <- inputs[!is.na(inputs$survey) & inputs$survey == "BITS Q4",,drop=FALSE]
fej <- inputs[!is.na(inputs$survey) & inputs$survey == "FEJUCS",,drop=FALSE]
n <- rows(outputs,"population","numbers_at_age")
ssb <- rows(outputs,"biomass","SSB")
r <- rows(outputs,"recruitment","recruitment")
z <- rows(outputs,"mortality","total_mortality_at_age")
zbar <- rows(outputs,"mortality","total_mortality")
harvest <- rows(outputs,"mortality","harvest_rate")
m <- rows(inputs,"M","natural_mortality_at_age")

stopifnot(
  source_data$assessment$assessment_year == 2026L,
  source_data$assessment$terminal_year == 2025L,
  source_data$assessment$estimate_terminal_year == 2026L,
  isTRUE(source_data$assessment$is_current),
  identical(old$assessment$is_current,FALSE),
  source_data$assessment$inputs_status == "partial",
  source_data$assessment$outputs_status == "partial",
  nrow(catch) == 287L,
  identical(sort(unique(catch$year)),1985:2025),
  identical(sort(unique(catch$age)),1:7),
  nrow(q1) == 124L, identical(sort(unique(q1$year)),1996:2026),
  all(grepl("assessment uses years 2001-2026",q1$notes)),
  all(grepl("pooled 4\\+ group",q1$notes)),
  nrow(q4) == 135L, identical(sort(unique(q4$year)),1999:2025),
  all(grepl("assessment uses years 2001-2025",q4$notes)),
  all(grepl("pooled 4\\+ group",q4$notes)),
  nrow(fej) == 14L, !any(fej$year == 2012),
  nrow(m) == 8L, is.na(m$year),
  nrow(rows(inputs,"weight","weight_at_age")) == 326L,
  nrow(rows(inputs,"maturity","maturity_at_age")) == 7L,
  nrow(n) == 335L, !any(n$year == 2026 & n$age == 0),
  nrow(ssb) == 42L, nrow(r) == 42L,
  nrow(z) == 205L, nrow(zbar) == 42L, nrow(harvest) == 41L,
  all(is.na(c(ssb$se,r$se,n$se,z$se,harvest$se))),
  abs(ssb$value[ssb$year == 2026] - 2287) < 1e-10,
  abs(r$value[r$year == 2026] - 1678) < 1e-10,
  abs(harvest$value[harvest$year == 2025] - 0.028) < 1e-12,
  !any(outputs$measure == "Fbar"), identical(unique(zbar$age_group),"3-5"), grepl("Zbar(3-5)",zbar$notes[1],fixed=TRUE),
  !anyDuplicated(paste(inputs$type,inputs$measure,inputs$survey,inputs$fleet,inputs$year,inputs$age)),
  !anyDuplicated(paste(outputs$type,outputs$measure,outputs$year,outputs$age))
)

cat("Western Baltic cod 2026 report tables, coverage, missing cells, status, units, and uniqueness passed.\n")
