base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
id <- "ices_cod_norwegian_coastal_combined_2020"
s <- subset(read_table("stocks.csv"), stock_id == "ck_ices_afwg_morhua_coastnor_1_2")
a <- subset(read_table("assessments.csv"), assessment_id == id)
z <- subset(read_table("inputs.csv"), assessment_id == id)
o <- subset(read_table("outputs.csv"), assessment_id == id)
stopifnot(nrow(s) == 1L, s$authority_stock_id == "cod.27.1-2coast", nrow(a) == 1L,
  a$is_current, a$is_applied, a$assessment_year == 2020, a$terminal_year == 2019,
  a$model_family == "SVPA", a$inputs_status == "partial", a$outputs_status == "partial",
  nrow(z) == 1269L, nrow(o) == 97L,
  sum(z$measure == "landings_numbers_at_age") == 324L,
  sum(z$type == "index") == 225L,
  identical(sort(unique(z$age[z$type == "index"])), as.integer(2:10)),
  identical(sort(unique(z$year[z$type == "index"])), as.integer(1995:2019)),
  all(z$unit[z$type == "index"] == "thousand fish"),
  all(is.na(z$sampling_time[z$type == "index"])),
  all(z$season[z$type == "index"] == "fall"),
  sum(o$measure == "spawning_biomass_index") == 25L,
  !any(o$measure %in% c("SSB", "numbers_at_age", "fishing_mortality_at_age")),
  all(grepl("13720", o$source_reference)))
get <- function(type, year, age) {
  x <- z[z$type == type & !is.na(z$year) & z$year == year & !is.na(z$age) & z$age == age, ]
  stopifnot(nrow(x) == 1L); x$value
}
stopifnot(get("catch", 2019, 2) == 70, get("catch", 1984, 10) == 175,
  get("index", 1995, 2) == 20191, get("index", 2019, 8) == 875,
  get("weight", 2019, 2) == .354, get("catch_weight", 2019, 10) == 8.978,
  o$value[o$measure == "recruitment" & o$year == 2019] == 22606,
  o$value[o$measure == "Fbar" & o$year == 2019] == .2002,
  o$value[o$measure == "spawning_biomass_index" & o$year == 2019] == 34311)
cat("Historical combined coastal cod source, coverage and units passed.\n")
