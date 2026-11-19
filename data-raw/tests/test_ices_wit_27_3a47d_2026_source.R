e <- new.env(parent = globalenv())
sys.source("data-raw/scripts/ices_wit_27_3a47d/695_import_ices_witch_northsea_2026.R", envir = e)
i <- e$inputs_new
o <- e$outputs_new
num <- function(x) suppressWarnings(as.numeric(x))

catch <- i[i$type == "catch" & i$measure == "numbers_at_age", ]
landings <- i[i$measure == "landings_biomass", ]
indices <- i[i$type == "index", ]
m <- i[i$type == "M", ]
mat <- i[i$type == "maturity", ]
ssb <- o[o$measure == "SSB", ]
tsb <- o[o$measure == "total_biomass", ]
fbar <- o[o$measure == "Fbar", ]

stopifnot(
  nrow(i) == 813L, nrow(o) == 1824L, nrow(e$assumptions_new) == 13L,
  all(i$assessment_id == "ices_wit_27_3a47d_2026"),
  all(o$assessment_id == "ices_wit_27_3a47d_2026"),
  nrow(catch) == 170L,
  num(catch$value[catch$year == 2009 & catch$age == 1]) == 1880573,
  num(catch$value[catch$year == 2025 & catch$age == 10]) == 163405,
  grepl("multiplier not stated", catch$unit[1L]),
  nrow(landings) == 59L, num(landings$value[landings$year == 1950]) == 2379,
  num(landings$value[landings$year == 2008]) == 1953,
  nrow(indices) == 44L, num(indices$value[indices$survey == "IBTS Q1" & indices$year == 1983]) == .26,
  num(indices$value[indices$survey == "Combined IBTS-BTS Q3" & indices$year == 1991]) == .25,
  all(is.na(indices$sampling_time)),
  nrow(m) == 10L, all(num(m$value) == .2),
  nrow(mat) == 10L, num(mat$value[mat$age == 10]) == .851,
  num(ssb$value[ssb$year == 2025]) == 4650,
  num(ssb$lwr[ssb$year == 2025]) == 3407, num(ssb$upr[ssb$year == 2025]) == 6346,
  num(tsb$value[tsb$year == 2025]) == 17783,
  num(fbar$value[fbar$year == 2025]) == .151,
  grepl("numerical age-specific matrices were not found",
    paste(readLines("data-raw/source_reviews/ices_wit_27_3a47d.md"), collapse = " "))
)

cat("ICES North Sea witch source test passed.\n")
