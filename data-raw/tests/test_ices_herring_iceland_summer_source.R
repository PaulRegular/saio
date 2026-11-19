root <- "."
read_db <- function(name) read.csv(
  file.path(root, "database", paste0(name, ".csv")),
  stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)

stock_id <- "ck_ices_nwwg_harengus_ice_summer"
assessment_id <- "ices_herring_iceland_summer_2026"
stock <- read_db("stocks")
assessments <- read_db("assessments")
inputs <- read_db("inputs")
outputs <- read_db("outputs")
assumptions <- read_db("assumptions")
s <- stock[stock$stock_id == stock_id, , drop = FALSE]
a <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
i <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
u <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]

stopifnot(
  nrow(s) == 1L, s$authority_stock_id == "her.27.5a",
  s$common_name == "Icelandic summer-spawning herring",
  s$area == "ICES Division 5.a (Iceland grounds)",
  s$region == "Icelandic Waters", s$ocean == "Northeast Atlantic",
  nrow(a) == 1L, a$assessment_year == 2026L,
  a$terminal_year == 2023L, a$estimate_terminal_year == 2026L,
  isTRUE(a$is_current), isTRUE(a$is_applied),
  all(c(a$inputs_status, a$outputs_status, a$assumptions_status) == "partial"),
  sum(i$type == "catch" & i$measure == "numbers_at_age") == 616L,
  sum(i$type == "index" & i$measure == "numbers_at_age") == 574L,
  sum(i$type == "weight" & i$measure == "weight_at_age") == 630L,
  sum(i$type == "catch_weight" & i$measure == "weight_at_age") == 630L,
  sum(i$type == "maturity" & i$measure == "maturity_at_age") == 616L,
  sum(i$type == "M" & i$measure == "natural_mortality_at_age") == 14L,
  min(i$age, na.rm = TRUE) == 2, max(i$age, na.rm = TRUE) == 15,
  min(i$year[i$type == "catch"], na.rm = TRUE) == 1980,
  max(i$year[i$type == "catch"], na.rm = TRUE) == 2023,
  max(i$year[i$type == "weight"], na.rm = TRUE) == 2024,
  sum(o$measure == "numbers_at_age") == 630L,
  sum(o$measure == "fishing_mortality_at_age") == 630L,
  sum(o$measure == "SSB") == 47L,
  sum(o$measure == "recruitment") == 47L,
  sum(o$measure == "Fbar") == 47L,
  sum(o$measure == "harvest_rate") == 46L,
  all(o$type %in% c("population", "recruitment", "mortality", "biomass")),
  all(o$type[o$measure %in% c("Fbar", "harvest_rate")] == "mortality"),
  max(o$year[o$measure == "numbers_at_age"], na.rm = TRUE) == 2024,
  max(o$year[o$measure == "SSB"], na.rm = TRUE) == 2026,
  all(is.na(o$se)),
  all(u$source_reference != ""),
  !anyDuplicated(paste(i$type, i$measure, i$survey, i$year, i$age, sep = "\034")),
  !anyDuplicated(paste(o$measure, o$year, o$age, sep = "\034"))
)

cat("Icelandic summer herring 2026 source coverage and provenance passed.\n")
