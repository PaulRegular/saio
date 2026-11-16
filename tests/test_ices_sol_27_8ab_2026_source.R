e <- new.env(parent = globalenv())
sys.source("scripts/ices_sol_27_8ab/693_import_ices_sole_8ab_2026.R", envir = e)
i <- e$inputs_new
o <- e$outputs_new
num <- function(x) suppressWarnings(as.numeric(x))

catch <- i[i$type == "catch" & i$measure == "numbers_at_age", ]
bts <- i[!is.na(i$survey) & i$survey == "FR-BTS-VIII (B1706)", ]
trawler <- i[!is.na(i$survey) & i$survey == "FR-TRAWLER", ]
ssb <- o[o$measure == "SSB", ]
fbar <- o[o$measure == "Fbar", ]
n_age <- o[o$measure == "numbers_at_age", ]

stopifnot(
  nrow(i) == 1019L, nrow(o) == 714L, nrow(e$assumptions_new) == 13L,
  all(i$assessment_id == "ices_sol_27_8ab_2026"),
  all(o$assessment_id == "ices_sol_27_8ab_2026"),
  nrow(catch) == 294L, num(catch$value[catch$year == 1984 & catch$age == 2]) == 6522,
  num(catch$value[catch$year == 2025 & catch$age == 8]) == 1413,
  nrow(bts) == 114L, num(bts$value[bts$year == 2007 & bts$age == 2]) == 10164744,
  num(bts$value[bts$year == 2025 & bts$age == 7]) == 431180.53,
  nrow(trawler) == 16L, num(trawler$value[trawler$year == 2025]) == 17.55664,
  all(is.na(c(bts$sampling_time, trawler$sampling_time))),
  num(ssb$value[ssb$year == 2025]) == 9917,
  num(fbar$value[fbar$year == 2025]) == .31,
  num(fbar$lwr[fbar$year == 2025]) < .31, num(fbar$upr[fbar$year == 2025]) > .31,
  num(n_age$value[n_age$year == 2025 & n_age$age == 8]) == 5278,
  all(grepl("does not state the multiplier", catch$notes)),
  grepl("production M vector", paste(readLines("source_reviews/ices_sol_27_8ab.md"), collapse = " "))
)

cat("ICES Bay of Biscay sole source test passed.\n")
