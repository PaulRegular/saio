Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
e <- new.env(parent = globalenv())
sys.source("scripts/database/558_import_ices_whiting_7b_ce_k_2026.R", envir = e)
i <- e$inputs
o <- e$outputs
num <- function(x) suppressWarnings(as.numeric(x))
catch <- i[i$measure == "numbers_at_age", ]
catch_w <- i[i$measure == "catch_weight_at_age", ]
stock_w <- i[i$measure == "weight_at_age", ]
survey <- i[i$type == "index" & i$measure == "numbers_at_age", ]
cpue <- i[i$measure == "relative_biomass_index", ]
components <- i[i$measure %in% c("landings_biomass", "discard_biomass"), ]
m <- i[i$measure == "natural_mortality_at_age", ]
mat <- i[i$measure == "maturity_at_age", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
n <- o[o$measure == "numbers_at_age", ]
rec <- o[o$measure == "recruitment", ]
ssb <- o[o$measure == "SSB", ]
fbar <- o[o$measure == "Fbar", ]
stopifnot(nrow(i) == 813L, nrow(e$assumptions) == 16L, nrow(o) == 515L,
  any(e$assumptions$setting == "survey_catchability_sharing"),
  length(unique(catch$year)) == 27L, length(unique(catch$age)) == 8L,
  num(catch$value[catch$year == 1999 & catch$age == 0]) == 5370,
  num(catch$value[catch$year == 2025 & catch$age == 7]) == 39.2,
  nrow(catch_w) == 216L, num(catch_w$value[catch_w$year == 1999 & catch_w$age == 0]) == 0.0271,
  all(catch_w$unit == "kg/fish"), all(nzchar(catch_w$transformation)),
  nrow(stock_w) == 216L, num(stock_w$value[stock_w$year == 1999 & stock_w$age == 0]) == 0.0167,
  nrow(survey) == 69L, num(survey$value[survey$year == 2003 & survey$age == 0]) == 38410,
  num(survey$value[survey$year == 2025 & survey$age == 2]) == 1129, all(survey$season == "Q4"),
  nrow(cpue) == 26L, num(cpue$value[cpue$year == 2000]) == 38.1036,
  nrow(components) == 54L, sum(components$measure == "landings_biomass") == 27L,
  sum(components$measure == "discard_biomass") == 27L,
  length(unique(m$value)) > 1L, length(unique(mat$value)) > 1L,
  nrow(f) == 216L, num(f$value[f$year == 2025 & f$age == 0]) == 0.004,
  nrow(n) == 216L, num(n$value[n$year == 2025 & n$age == 0]) == 223357,
  nrow(rec) == 28L, num(rec$value[rec$year == 2026]) == 108661,
  num(rec$lwr[rec$year == 2026]) == 94655, num(rec$upr[rec$year == 2026]) == 223357,
  nrow(ssb) == 28L, num(ssb$value[ssb$year == 2026]) == 15223,
  nrow(fbar) == 27L, num(fbar$value[fbar$year == 2025]) == 0.242,
  all(e$assumptions$assessment_id == e$assessment$assessment_id),
  e$assessment$inputs_status == "partial", e$assessment$outputs_status == "partial",
  e$register$import_status[e$candidate_row] == "partial",
  e$selected$curation_status[e$selected_row] == "partial_source_import")


source("R/read_database.R")
db <- read_assessment("ices_whg_27_7b_ce_k_2026")
extra <- db$assumptions[db$assumptions$setting == "survey_catchability_sharing", ]
stopifnot(nrow(db$inputs) == 813L, nrow(db$outputs) == 515L,
  sum(db$inputs$measure == "landings_biomass") == 27L,
  sum(db$inputs$measure == "discard_biomass") == 27L,
  all(db$inputs$unit[db$inputs$measure == "weight_at_age"] == "kg/fish"),
  db$assessment$inputs_status == "partial", db$assessment$outputs_status == "partial", nrow(extra) == 1L)
cat("ICES whiting import source test passed.\n")
