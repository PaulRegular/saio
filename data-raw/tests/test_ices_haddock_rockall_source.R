root <- "."
read_db <- function(name) read.csv(
  file.path(root, "database", paste0(name, ".csv")),
  stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)
id <- "ices_haddock_rockall_2026"
stock_id <- "ck_ices_wgcse_aeglefinus_rock6b"
stock <- read_db("stocks")
assessment <- read_db("assessments")
inputs <- read_db("inputs")
outputs <- read_db("outputs")
assumptions <- read_db("assumptions")
a <- assessment[assessment$assessment_id == id, , drop = FALSE]
i <- inputs[inputs$assessment_id == id, , drop = FALSE]
o <- outputs[outputs$assessment_id == id, , drop = FALSE]
s <- stock[stock$stock_id == stock_id, , drop = FALSE]
weight_match <- merge(
  i[i$type == "weight" & i$measure == "weight_at_age", c("year", "age", "value")],
  i[i$type == "catch_weight" & i$measure == "weight_at_age", c("year", "age", "value")],
  by = c("year", "age"), suffixes = c("_stock", "_catch"), sort = TRUE
)

stopifnot(
  nrow(a) == 1L, a$assessment_year == 2026, a$terminal_year == 2025,
  a$estimate_terminal_year == 2025, a$is_current == "TRUE",
  a$is_applied == "TRUE", all(c(a$inputs_status, a$outputs_status,
    a$assumptions_status) == "partial"),
  nrow(s) == 1L, s$authority_stock_id == "had.27.6b",
  s$area == "ICES Division 6.b (Rockall)",
  sum(i$type == "catch" & i$measure == "numbers_at_age") == 280L,
  sum(i$measure == "landings_fraction_at_age") == 280L,
  sum(i$type == "catch_weight") == 280L,
  sum(i$type == "weight" & i$measure == "weight_at_age") == 280L,
  sum(!is.na(i$survey) & i$survey == "Rockall pt1" & i$measure == "numbers_at_age") == 55L,
  sum(!is.na(i$survey) & i$survey == "Modelled Q3" & i$measure == "numbers_at_age") == 192L,
  sum(!is.na(i$survey) & i$survey == "Modelled Q3" & i$measure == "relative_standard_error") == 192L,
  sum(i$type == "M" & i$measure == "natural_mortality_at_age") == 8L,
  sum(i$type == "maturity") == 8L,
  sum(o$measure == "numbers_at_age") == 280L,
  sum(o$measure == "fishing_mortality_at_age") == 280L,
  sum(o$measure == "SSB") == 35L,
  sum(o$measure == "recruitment") == 35L,
  sum(o$measure == "Fbar") == 35L,
  sum(o$measure == "total_biomass") == 35L,
  max(i$year, na.rm = TRUE) == 2025,
  max(o$year, na.rm = TRUE) == 2025,
  nrow(weight_match) == 280L,
  identical(weight_match$value_stock, weight_match$value_catch),
  all(i$source_type[i$type == "weight" & i$measure == "weight_at_age"] ==
    "reconstructed_source_input"),
  all(grepl("2b768d6e2563d38a172918390e8fe964596b1325",
    i$source_reference[i$type == "weight" & i$measure == "weight_at_age"])),
  all(grepl("sw.dat", i$transformation[i$type == "weight" &
    i$measure == "weight_at_age"])),
  !anyDuplicated(paste(i$type, i$measure, i$fleet, i$survey, i$year, i$age, sep = "\034")),
  !anyDuplicated(paste(o$measure, o$year, o$age, sep = "\034")),
  all(is.na(o$se)),
  grepl("2026_had.27.6b/tree/2b768d6e2563d38a172918390e8fe964596b1325",
    a$repository_url),
  is.na(a$model_url) || !nzchar(a$model_url),
  identical(as.numeric(i$value[i$type == "M"]),
    c(0.3559, 0.2998, 0.2755, 0.2574, 0.2386, 0.2280, 0.2114, 0.2)),
  i$value[i$measure == "numbers_at_age" & i$year == 1991 & i$age == 1 &
    i$type == "catch"] == 21186,
  o$value[o$measure == "numbers_at_age" & o$year == 1991 & o$age == 1] == 144047.46,
  o$value[o$measure == "SSB" & o$year == 1991] == 36243,
  !any(assumptions$assessment_id == id & assumptions$setting == "stock_weight_surface")
)

stock_weight_assumption <- assumptions[
  assumptions$assessment_id == id & assumptions$setting == "stock_weight", , drop = FALSE
]
precision_assumption <- assumptions[
  assumptions$assessment_id == id & assumptions$setting == "observation_precision" &
    assumptions$survey == "Modelled Q3", , drop = FALSE
]
stopifnot(
  nrow(stock_weight_assumption) == 1L,
  grepl("copied unchanged", stock_weight_assumption$value),
  grepl("data_stockweights.R", stock_weight_assumption$source_reference),
  nrow(precision_assumption) == 1L,
  grepl("age-series maxima", precision_assumption$value),
  grepl("exact unrounded adjusted values are absent", precision_assumption$notes),
  grepl("data.R", precision_assumption$source_reference)
)

cv <- i[i$measure == "relative_standard_error", ]
stopifnot(
  all(cv$value > 0 & cv$value < 1),
  all(cv$unit == "coefficient of variation"),
  all(cv$source_reference == "ICES WGCSE 2026, Haddock in Division 6.b, doi:10.17895/ices.pub.32625759 Table 8.13, pp. 296-298"),
  all(cv$sampling_time == 0.75)
)
cat("Rockall haddock 2026 source coverage, units, provenance and reported values passed.\n")
