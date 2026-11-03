root <- "."
read_db <- function(name) read.csv(
  file.path(root, "database", paste0(name, ".csv")),
  stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)

id <- "ices_sandeel_area_4_2026_summary"
a <- read_db("assessments")
a <- a[a$assessment_id == id, , drop = FALSE]
all_inputs <- read_db("inputs")
i <- all_inputs[all_inputs$assessment_id == id, , drop = FALSE]
o <- read_db("outputs")
o <- o[o$assessment_id == id, , drop = FALSE]
assumptions <- read_db("assumptions")
assumptions <- assumptions[
  assumptions$assessment_id == id &
    assumptions$setting == "separate_advice_vintage", , drop = FALSE
]

catch <- i[i$type == "catch" & i$measure == "total_biomass", , drop = FALSE]
index <- i[i$type == "index" & i$measure == "numbers_at_age", , drop = FALSE]

stopifnot(
  nrow(a) == 1L,
  a$assessment_year == 2026,
  a$terminal_year == 2025,
  a$assessment_type == "summary_update",
  a$is_current == "FALSE",
  a$inputs_status == "partial",
  a$outputs_status == "not_applicable",
  nrow(o) == 0L,
  nrow(catch) == 33L,
  identical(sort(catch$year), 1993:2025),
  all(catch$basis == "biomass"),
  all(catch$unit == "tonnes"),
  all(catch$source_type == "official_table"),
  catch$value[catch$year == 1993] == 133135.9932551,
  catch$value[catch$year == 2025] == 0,
  nrow(index) == 36L,
  identical(sort(unique(index$year)), 2008:2025),
  identical(unname(as.integer(table(index$age))), c(18L, 18L)),
  all(index$basis == "index_scale"),
  all(index$unit == "number (index scale; multiplier not stated)"),
  all(index$survey == "Dredge survey"),
  all(index$source_type == "official_table"),
  all(is.na(index$sampling_time)),
  index$value[index$year == 2008 & index$age == 0] == 785.222882817648,
  index$value[index$year == 2025 & index$age == 1] == 828.33280350619,
  all(grepl("unit, multiplier, sampling time, or likelihood role",
    index$notes)),
  nrow(assumptions) == 1L,
  grepl("category-5", assumptions$value),
  grepl("Custom-series units and scaling are absent", assumptions$notes),
  sum(all_inputs$assessment_id == "ices_sandeel_area_4_2025") == 1642L
)

cat("Area 4 2026 category-5 source rows and separation from the age-based run passed.\n")
