source("R/read_database.R")
x <- read_assessment("nefsc_pollock_5yz_2024")
i <- x$inputs
o <- x$outputs

catch <- i[i$measure == "landings_numbers_at_age", , drop = FALSE]
discards <- i[i$measure == "discard_numbers_at_age", , drop = FALSE]
indices <- i[i$type == "index" & i$measure == "biomass_at_age", , drop = FALSE]
aggregates <- i[i$type == "index" & i$measure == "relative_biomass_index", , drop = FALSE]
index_cv <- i[i$type == "index" & i$measure == "relative_standard_error", , drop = FALSE]
catch_cv <- i[i$type == "catch" & i$measure == "relative_standard_error", , drop = FALSE]
m <- i[i$type == "M" & i$measure == "natural_mortality_at_age", , drop = FALSE]
maturity <- i[i$type == "maturity" & i$measure == "maturity_at_age", , drop = FALSE]
n <- o[o$measure == "numbers_at_age", , drop = FALSE]
f <- o[o$measure == "fishing_mortality_at_age", , drop = FALSE]

stopifnot(
  x$stocks$common_name == "Atlantic pollock",
  x$stocks$authority_stock_id == "5YZ",
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$terminal_year == 2023,
  x$assessment$inputs_status == "complete",
  x$assessment$outputs_status == "partial",
  identical(sort(unique(as.integer(catch$year))), 1970:2023),
  identical(sort(unique(as.integer(catch$age))), 1:9),
  nrow(catch) == 54L * 9L,
  identical(sort(unique(as.integer(discards$year))), 1981:2023),
  nrow(discards) == 43L * 9L,
  all(catch$unit == "thousand fish"),
  all(discards$unit == "thousand fish"),
  all(catch$sample_size == 26),
  all(discards$sample_size == 14),
  nrow(catch_cv[catch_cv$partition == "landings", ]) == 54L,
  nrow(catch_cv[catch_cv$partition == "dead_discards", ]) == 43L,
  all(is.na(catch_cv$age)),
  all(catch_cv$unit == "coefficient of variation"),
  setequal(unique(indices$survey), c(
    "NEFSC Albatross spring trawl survey",
    "NEFSC Bigelow spring trawl survey",
    "NEFSC Albatross fall trawl survey",
    "NEFSC Bigelow fall trawl survey"
  )),
  !any(grepl("summer", indices$survey, ignore.case = TRUE)),
  all(indices$unit == "kg per tow"),
  all(aggregates$unit == "kg per tow"),
  all(index_cv$unit == "coefficient of variation"),
  setequal(unique(as.numeric(indices$sampling_time)), c(.25, .75)),
  nrow(m) == 9L,
  all(as.numeric(m$value) == .2),
  nrow(maturity) == 9L,
  identical(as.numeric(maturity$value), c(.088, .293, .640, .884, .970, .993, .998, 1, 1)),
  nrow(n) == 54L * 9L,
  nrow(f) == 54L * 9L,
  nrow(o[o$measure == "total_abundance", ]) == 54L,
  nrow(o[o$measure == "recruitment", ]) == 54L,
  nrow(o[o$measure == "natural_mortality_at_age", ]) == 0L,
  all(is.na(o$se)),
  abs(mean(f$value[f$year == 2023 & f$age %in% 5:7]) -
    o$value[o$measure == "Fbar" & o$year == 2023]) < 1e-7
)

review <- readLines("source_reviews/nefsc_atlantic_pollock_5yz.md", warn = FALSE)
stock_bytes <- readBin("database/stocks.csv", "raw",
  n = as.integer(file.info("database/stocks.csv")[["size"]])
)
stopifnot(
  any(grepl("2026 SASI item is a data/projection update", review)),
  !any(stock_bytes == as.raw(0))
)

cat("Atlantic pollock source coverage, fixed biology, survey timing, outputs and provenance passed.\n")
