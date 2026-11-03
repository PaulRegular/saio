source("R/read_database.R")
x <- read_assessment("nefsc_gom_cod_2021_m02")
i <- x$inputs
o <- x$outputs
key <- function(z) paste(z$year, z$age)
grid <- expand.grid(year = 1982:2019, age = 1:9)

stopifnot(
  x$assessment$stock_id == "ck_nefsc_saw_morhua_gom",
  !x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$terminal_year == 2019,
  x$assessment$inputs_status == "partial",
  x$assessment$outputs_status == "partial",
  nrow(i) == 1728L,
  sum(i$type == "catch") == 38L * 9L,
  sum(i$type == "index" & i$survey == "NEFSC spring") == 38L * 9L,
  sum(i$type == "index" & i$survey == "NEFSC fall") == 38L * 9L,
  sum(i$type == "catch_weight") == 38L * 9L,
  sum(i$type == "weight") == 38L * 9L,
  all(vapply(split(i[i$type %in% c("catch", "index", "catch_weight", "weight"), ],
    interaction(i$type[i$type %in% c("catch", "index", "catch_weight", "weight")],
      i$survey[i$type %in% c("catch", "index", "catch_weight", "weight")], drop = TRUE)),
    function(z) nrow(z) == 38L * 9L, logical(1))),
  setequal(key(i[i$type == "catch", ]), key(grid)),
  setequal(key(i[i$type == "index" & i$survey == "NEFSC spring", ]), key(grid)),
  setequal(key(i[i$type == "index" & i$survey == "NEFSC fall", ]), key(grid)),
  all(i$unit[i$type == "catch"] == "fish"),
  all(i$unit[i$type == "index"] == "thousand fish"),
  all(i$unit[i$type %in% c("weight", "catch_weight")] == "kg"),
  all(i$value[i$type == "M"] == 0.2),
  all(is.na(i$year[i$type %in% c("M", "maturity")])),
  all(i$source_type[i$type == "maturity"] == "reconstructed_source_input"),
  all(grepl("digitized", i$notes[i$type == "maturity"], ignore.case = TRUE)),
  nrow(o) == 24L,
  setequal(unique(o$measure), c("SSB", "recruitment", "fishing_mortality_at_age")),
  setequal(unique(o$year), 2012:2019),
  all(is.na(o$se)),
  o$value[o$measure == "SSB" & o$year == 2019] == 3083,
  o$value[o$measure == "recruitment" & o$year == 2019] == 1298,
  o$value[o$measure == "fishing_mortality_at_age" & o$year == 2019] == 0.16,
  grepl("historical", x$stocks$common_name, ignore.case = TRUE),
  grepl("pre-2023", x$stocks$area, fixed = TRUE),
  grepl("not assigned to any successor stock", x$stocks$notes, fixed = TRUE)
)

cat("NEFSC 2021 Gulf of Maine cod source coverage, units, provenance, legacy boundary, and reported outputs passed.\n")


